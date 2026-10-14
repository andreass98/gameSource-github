IAProductStoreItem = {}
local IAProductStoreItem_mt = Class(IAProductStoreItem, IAProduct)
IAProductStoreItem.ADDITIONAL_SPECS = {}
IAProductStoreItem.ADDITIONAL_SPECS.workingWidth = true
IAProductStoreItem.COMBINED_SPECS = {}
IAProductStoreItem.COMBINED_SPECS.slots = true
function IAProductStoreItem.new(productId, isConsumable)
    -- upvalues: (copy) IAProductStoreItem_mt
    local self = IAProduct.new(productId, isConsumable, IAProductStoreItem_mt)
    self.items = {}
    self.pendingStoreItemPurchases = {}
    return self
end
function IAProductStoreItem:loadFromXMLFile(xmlFile, key)
    if not IAProductStoreItem:superClass().loadFromXMLFile(self, xmlFile, key) then
        return false
    end
    self.title = xmlFile:getString(key .. "#title")
    self.imageFilename = xmlFile:getString(key .. "#imageFilename")
    xmlFile:iterate(key .. ".item", function(_, itemKey)
        -- upvalues: (copy) xmlFile, (copy) self
        local xmlFilename = xmlFile:getString(itemKey .. "#xmlFilename")
        if xmlFilename ~= nil then
            table.insert(self.items, xmlFilename)
        end
    end)
    if #self.items ~= 0 then
        return true
    end
    Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Missing xmlFilename definition. (%s)", key)
    return false
end
function IAProductStoreItem:onVehicleBuyEvent(errorCode)
    if errorCode == BuyVehicleEvent.STATE_SUCCESS then
        if #self.pendingStoreItemPurchases > 0 then
            g_client:getServerConnection():sendEvent(BuyVehicleEvent.new(self.pendingStoreItemPurchases[1], false, {}, false, g_currentMission:getFarmId(), nil, nil, 0))
            table.remove(self.pendingStoreItemPurchases, 1)
        else
            g_messageCenter:unsubscribe(BuyVehicleEvent, self)
            self:onProductBoughtFinished(true)
        end
    else
        self.pendingStoreItemPurchases = {}
        local text = nil
        if errorCode == BuyVehicleEvent.STATE_NO_SPACE then
            text = g_i18n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE)
        end
        g_messageCenter:unsubscribe(BuyVehicleEvent, self)
        self:onProductBoughtFinished(false, text)
        return
    end
end
function IAProductStoreItem:getIsStoreItemOfProduct(storeItem)
    local i = 1
    for i = i, #self.items do
        if storeItem.xmlFilename == self.items[i] then
            return true
        end
    end
    return false
end
function IAProductStoreItem:getDisplayItem(oldStoreItem, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
    if oldStoreItem.xmlFilename ~= self.items[1] then
        return nil
    end
    local title = oldStoreItem.name
    if self.title ~= nil then
        local names = {}
        local i = 1
        for i = i, #self.items do
            local storeItem = g_storeManager:getItemByXMLFilename(self.items[i])
            if storeItem ~= nil then
                table.insert(names, storeItem.name)
            end
        end
        title = string.format(self.title, unpack(names))
    end
    local names = {
        ["name"] = self:getId(),
        ["isInAppPurchase"] = true,
        ["isInAppPurchaseConsumable"] = false,
        ["priceText"] = self:getPriceText(),
        ["title"] = title,
        ["brandIndex"] = oldStoreItem.brandIndex,
        ["imageFilename"] = self.imageFilename or oldStoreItem.imageFilename,
        ["xmlFilename"] = oldStoreItem.xmlFilename,
        ["product"] = self,
        ["canBeRecovered"] = g_inAppPurchaseController:getHasPendingPurchase(self)
    }
    if #self.items > 0 then
        local i = 2
        for i = i, #self.items do
            local storeItem = g_storeManager:getItemByXMLFilename(self.items[i])
            local otherDisplayItem = g_shopController:makeDisplayItem(storeItem, nil, nil, nil, true)
            if otherDisplayItem ~= nil then
                local profileIndex = 1
                for profileIndex = profileIndex, #otherDisplayItem.attributeIconProfiles do
                    local specType = g_storeManager:getSpecTypeByProfile(otherDisplayItem.attributeIconProfiles[profileIndex])
                    if IAProductStoreItem.ADDITIONAL_SPECS[specType.name] then
                        table.insert(attributeIconProfiles, otherDisplayItem.attributeIconProfiles[profileIndex])
                        table.insert(attributeValues, otherDisplayItem.attributeValues[profileIndex])
                    end
                    if IAProductStoreItem.COMBINED_SPECS[specType.name] then
                        local profileIndex2 = 1
                        for profileIndex2 = profileIndex2, #attributeIconProfiles do
                            if attributeIconProfiles[profileIndex2] == specType.profile then
                                attributeValues[profileIndex2] = tostring(tonumber(attributeValues[profileIndex2]) + tonumber(otherDisplayItem.attributeValues[profileIndex]))
                            end
                        end
                    end
                end
            end
        end
    end
    return ShopDisplayItem.new(names, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
end
function IAProductStoreItem:onProductBought(callback)
    if g_currentMission ~= nil then
        local i = 1
        for i = i, #self.items do
            if g_storeManager:getItemByXMLFilename(self.items[i]) == nil then
                Logging.error("Unable to buy IAP store item \'%s", self.items[i])
            else
                table.insert(self.pendingStoreItemPurchases, self.items[i])
            end
        end
        if #self.pendingStoreItemPurchases > 0 then
            self.boughtCallback = callback
            g_messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBuyEvent, self)
            g_client:getServerConnection():sendEvent(BuyVehicleEvent.new(self.pendingStoreItemPurchases[1], false, {}, false, g_currentMission:getFarmId(), nil, nil, 0))
            table.remove(self.pendingStoreItemPurchases, 1)
            return
        end
    end
    callback(false)
end
function IAProductStoreItem:onProductBoughtFinished(success, warningText)
    local mission = g_currentMission
    if mission ~= nil then
        mission:saveSavegame()
    end
    self.boughtCallback(success, warningText)
    self.boughtCallback = nil
end