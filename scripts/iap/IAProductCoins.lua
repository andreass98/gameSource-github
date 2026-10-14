IAProductCoins = {}
local IAProductCoins_mt = Class(IAProductCoins, IAProduct)
function IAProductCoins.new(productId, isConsumable)
    -- upvalues: (copy) IAProductCoins_mt
    return IAProduct.new(productId, isConsumable, IAProductCoins_mt)
end
function IAProductCoins:loadFromXMLFile(xmlFile, key)
    if not IAProductCoins:superClass().loadFromXMLFile(self, xmlFile, key) then
        return false
    end
    self.coins = xmlFile:getInt(key .. "#coins")
    if self.coins ~= nil then
        return true
    end
    Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Missing coins definition. (%s)", key)
    return false
end
function IAProductCoins:getDisplayItem(_, _, _, _, _, _, _, _, _, _)
    local storeItem = {
        ["name"] = self:getId(),
        ["isInAppPurchase"] = true,
        ["isInAppPurchaseConsumable"] = true,
        ["priceText"] = self:getPriceText(),
        ["title"] = self:getTitle(),
        ["imageFilename"] = self:getImageFilename(),
        ["product"] = self,
        ["canBeRecovered"] = g_inAppPurchaseController:getHasPendingPurchase(self)
    }
    return ShopDisplayItem.new(storeItem, nil, nil, nil, nil, g_i18n:getText("function_coins"), self.productId)
end
function IAProductCoins:onProductBought(callback)
    local mission = g_currentMission
    if mission ~= nil then
        mission:addPurchasedMoney(self.coins)
        mission:saveSavegame()
    end
    IAProductCoins:superClass().onProductBought(self, callback)
end