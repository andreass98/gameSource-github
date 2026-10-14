InAppPurchaseController = {}
local InAppPurchaseController_mt = Class(InAppPurchaseController)
InAppPurchaseController.PENDING_DELAY = 1000
function InAppPurchaseController.new()
    -- upvalues: (copy) InAppPurchaseController_mt
    local self = setmetatable({}, InAppPurchaseController_mt)
    self.isLoaded = false
    self.isInitialized = false
    self.callbacks = {}
    self.pendingTimer = InAppPurchaseController.PENDING_DELAY
    self.lastNumOfPendingPurchases = 0
    self.ignoreNextPendingPurchaseChange = false
    self.pendingProductsToRestore = {}
    self.xmlPath = "dataS/inAppProducts.xml"
    return self
end
function InAppPurchaseController:load()
    if not self.isLoaded then
        self:loadProductsFromXML()
        if inAppInit ~= nil then
            inAppInit(self.xmlPath)
        end
        self.isLoaded = true
    end
end
function InAppPurchaseController:loadProductsFromXML()
    self.products = {}
    self.productIdToProduct = {}
    local xmlFile = XMLFile.load("products", self.xmlPath)
    if xmlFile ~= nil then
        xmlFile:iterate("inAppPurchases.inAppPurchase", function(_, key)
            -- upvalues: (copy) xmlFile, (copy) self
            local productId = xmlFile:getInt(key .. "#productId")
            if productId == nil then
                Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Missing productId. (%s)", key)
                return
            else
                local isConsumable = xmlFile:getBool(key .. "#isConsumable", true)
                local className = xmlFile:getString(key .. ".product#className")
                if className == nil or className == "" then
                    Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Missing product #className (%s)", key)
                    return
                else
                    local class = ClassUtil.getClassObject(className)
                    if class == nil then
                        Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Unknown class \'%s\'. (%s)", className, key)
                    else
                        local product = class.new(productId, isConsumable)
                        if product ~= nil and product:loadFromXMLFile(xmlFile, key .. ".product") then
                            table.insert(self.products, product)
                            self.productIdToProduct[productId] = product
                        end
                    end
                end
            end
        end)
        xmlFile:delete()
    end
end
function InAppPurchaseController:setMission(mission)
    self.mission = mission
end
function InAppPurchaseController:getIsAvailable()
    if self.isInitialized then
        return true
    end
    if inAppIsLoaded == nil or not inAppIsLoaded() then
        return false
    end
    self.isInitialized = true
    return true
end
function InAppPurchaseController:getProducts()
    return self.products
end
function InAppPurchaseController:getProductById(id)
    local i = 1
    for i = i, #self.products do
        local product = self.products[i]
        if product:getId() == id then
            return product
        end
    end
    return nil
end
function InAppPurchaseController:purchase(product, callback)
    assert(product ~= nil and callback ~= nil)
    if self.mission ~= nil then
        self.callbacks[product] = callback
        inAppStartPurchase(product:getId(), "onPurchaseEnd", self)
    end
end
function InAppPurchaseController:onPurchaseEnd(errorCode, productId)
    local product = self.productIdToProduct[productId]
    if errorCode == InAppPurchase.ERROR_OK then
        if self.mission ~= nil then
            product:onProductBought(function(success, _)
                -- upvalues: (copy) productId, (copy) self, (copy) product, (copy) errorCode
                if success then
                    inAppFinishPurchase(productId)
                    self.callbacks[product](true, false, errorCode)
                    self:onPendingPurchasesChanged(0)
                else
                    self.callbacks[product](false, true, InAppPurchase.ERROR_FAILED)
                    self.ignoreNextPendingPurchaseChange = true
                end
            end)
            return
        end
    else
        self.callbacks[product](false, errorCode == InAppPurchase.ERROR_CANCELLED, errorCode)
    end
end
function InAppPurchaseController.getHasPendingPurchase(_, product)
    local numRecoverablePurchases = inAppGetNumPendingPurchases()
    local productId = product:getId()
    local i = 0
    for i = i, numRecoverablePurchases - 1 do
        if inAppGetPendingPurchaseProductId(i) == productId then
            return true
        end
    end
    return false
end
function InAppPurchaseController:getHasAnyPendingPurchases()
    return inAppGetNumPendingPurchases() > 0
end
function InAppPurchaseController:checkPendingPurchasesChanged()
    self.pendingTimer = InAppPurchaseController.PENDING_DELAY
    local num = inAppGetNumPendingPurchases()
    if num ~= self.lastNumOfPendingPurchases then
        if self.ignoreNextPendingPurchaseChange then
            self.ignoreNextPendingPurchaseChange = false
        else
            self:onPendingPurchasesChanged(num - self.lastNumOfPendingPurchases)
        end
        self.lastNumOfPendingPurchases = num
    end
end
function InAppPurchaseController:onPendingPurchasesChanged(changeAmount)
    if self.pendingPurchaseCallback ~= nil then
        self.pendingPurchaseCallback()
    end
    if changeAmount > 0 then
        local numPendingPurchases = inAppGetNumPendingPurchases()
        if numPendingPurchases > 0 then
            self.pendingProductsToRestore = {}
            local i = numPendingPurchases - changeAmount
            local restoreNextProduct = numPendingPurchases - 1
            for i = i, restoreNextProduct do
                local product = self:getProductById((inAppGetPendingPurchaseProductId(i)))
                if product ~= nil then
                    table.insert(self.pendingProductsToRestore, product)
                end
            end
            local function restoreNextProduct()
                -- upvalues: (copy) self, (copy) restoreNextProduct
                if #self.pendingProductsToRestore > 0 then
                    local product = self.pendingProductsToRestore[1]
                    local text = string.format(g_i18n:getText("ui_iap_pendingPurchaseFound"), product:getTitle())
                    YesNoDialog.show(function(_, yes)
                        -- upvalues: (ref) self, (copy) product, (ref) restoreNextProduct
                        if yes then
                            self:tryPerformPendingPurchase(product, function(success, warningText)
                                -- upvalues: (ref) restoreNextProduct
                                local text = g_i18n
                                local text = text:getText(success and "ui_iap_purchaseComplete" or "ui_iap_errorFailed")
                                if warningText ~= nil then
                                end
                                InfoDialog.show(text, function()
                                    -- upvalues: (ref) restoreNextProduct
                                    restoreNextProduct()
                                end)
                            end)
                        else
                            restoreNextProduct()
                        end
                    end, self, text)
                    table.remove(self.pendingProductsToRestore, 1)
                end
            end
            restoreNextProduct()
        end
    end
end
function InAppPurchaseController:setPendingPurchaseCallback(callback)
    self.pendingPurchaseCallback = callback
end
function InAppPurchaseController.tryPerformPendingPurchase(_, product, callback)
    local productId = false
    if product ~= nil then
        productId = callback ~= nil
    end
    assert(productId)
    local numRecoverablePurchases = inAppGetNumPendingPurchases()
    local productId = product:getId()
    local i = 0
    for i = i, numRecoverablePurchases - 1 do
        if inAppGetPendingPurchaseProductId(i) == productId then
            product:onProductBought(function(success, warningText)
                -- upvalues: (copy) callback, (copy) i
                callback(success, warningText)
                if success then
                    inAppFinishPendingPurchase(i)
                end
            end)
            return true
        end
    end
    return false
end
function InAppPurchaseController:getHasPurchasesToRestore()
    return inAppHasRestorePurchases == nil or inAppHasRestorePurchases()
end
function InAppPurchaseController:restorePurchases()
    inAppRestorePurchases("onPurchasesRestored", self)
end
function InAppPurchaseController:onPurchasesRestored(errorCode)
    if errorCode == InAppPurchaseResponse.OK then
        InfoDialog.show(g_i18n:getText("ui_iap_purchaseRestoreCompleted"), nil, nil, DialogElement.TYPE_INFO)
    elseif errorCode == InAppPurchaseResponse.PURCHASE_IN_PROGRESS then
        InfoDialog.show(g_i18n:getText("ui_iap_purchaseInProgress"), nil, nil, DialogElement.TYPE_INFO)
    else
        InfoDialog.show(g_i18n:getText("ui_iap_purchaseRestoreFailed"), nil, nil, DialogElement.TYPE_WARNING)
    end
    for k, v in pairs(InAppPurchaseResponse) do
        if v == errorCode then
            Logging.devInfo("Restored In-app purchases (%s):", k)
        end
    end
    local i = 1
    for i = i, #self.products do
        local k = self.products[i]
        Logging.devInfo("Product %d (%s) has been bought: %s", k:getId(), k:getTitle(), k:getHasBeenBought() and "Yes" or "No")
    end
end
function InAppPurchaseController:update(dt)
    if self.isLoaded and self.isInitialized then
        self.pendingTimer = self.pendingTimer - dt
        if self.pendingTimer < 0 then
            self:checkPendingPurchasesChanged()
        end
    end
end