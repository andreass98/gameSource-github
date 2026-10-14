IAProduct = {}
local IAProduct_mt = Class(IAProduct)
function IAProduct.new(productId, isConsumable, customMt)
    -- upvalues: (copy) IAProduct_mt
    local self = setmetatable({}, customMt or IAProduct_mt)
    self.productId = productId
    self.isConsumable = isConsumable
    return self
end
function IAProduct:loadFromXMLFile(xmlFile, key)
    self.imageFilename = xmlFile:getString(key .. "#imageFilename")
    return true
end
function IAProduct:getId()
    return self.productId
end
function IAProduct:getPriceText()
    return g_inAppPurchaseController:getIsAvailable() and (inAppGetProductPrice(self.productId) or "Unknown") or g_i18n:getText("ui_modUnavailable")
end
function IAProduct:getTitle()
    return inAppGetProductDescription(self.productId) or "Unknown"
end
function IAProduct:getImageFilename()
    return self.imageFilename
end
function IAProduct:getHasBeenBought()
    if self.isConsumable then
        return false
    end
    return inAppGetProductPurchaseState(self.productId) == InAppPurchasePurchaseState.PURCHASED
end
function IAProduct:getDisplayItem()
    return nil
end
function IAProduct.onProductBought(_, callback)
    callback(true)
end