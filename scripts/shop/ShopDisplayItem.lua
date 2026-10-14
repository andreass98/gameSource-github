ShopDisplayItem = {}
local ShopDisplayItem_mt = Class(ShopDisplayItem)
ShopDisplayItem.NO_CONCRETE_ITEM = {}
function ShopDisplayItem.new(storeItem, concreteItem, attributeIconProfiles, attributeValues, iconFilenames, functionText, orderValue, numOwned, numLeased, saleItem)
    -- upvalues: (copy) ShopDisplayItem_mt
    local self = setmetatable({}, ShopDisplayItem_mt)
    self.storeItem = storeItem
    self.concreteItem = concreteItem or ShopDisplayItem.NO_CONCRETE_ITEM
    self.attributeIconProfiles = attributeIconProfiles or {}
    self.attributeValues = attributeValues or {}
    if iconFilenames ~= nil then
        self.fillTypeIconFilenames = iconFilenames.fillTypeIconFilenames or {}
        self.seedTypeIconFilenames = iconFilenames.seedTypeIconFilenames or {}
        self.foodFillTypeIconFilenames = iconFilenames.foodFillTypeIconFilenames or {}
        self.prodPointInputFillTypeIconFilenames = iconFilenames.prodPointInputFillTypeIconFilenames or {}
        self.prodPointOutputFillTypeIconFilenames = iconFilenames.prodPointOutputFillTypeIconFilenames or {}
        self.sellingStationFillTypesIconFilenames = iconFilenames.sellingStationFillTypesIconFilenames or {}
        self.buyingStationFillTypesIconFilenames = iconFilenames.buyingStationFillTypesIconFilenames or {}
        self.objectStorageFillTypesIconFilenames = iconFilenames.objectStorageFillTypesIconFilenames or {}
    end
    self.functionText = functionText
    self.orderValue = orderValue
    self.numOwned = numOwned
    self.numLeased = numLeased
    self.saleItem = saleItem
    return self
end
function ShopDisplayItem:getSellPrice()
    if self.saleItem == nil then
        if self.concreteItem == ShopDisplayItem.NO_CONCRETE_ITEM then
            return self.storeItem.price
        else
            return self.concreteItem:getSellPrice()
        end
    else
        return self.saleItem.price
    end
end
function ShopDisplayItem:getSortId()
    if self.concreteItem == ShopDisplayItem.NO_CONCRETE_ITEM then
        return self.storeItem.xmlFilename
    else
        return self.concreteItem.id
    end
end
function ShopDisplayItem:hasCombinationInfo()
    if self.saleItem ~= nil then
        return false
    end
    if self.storeItem.specs == nil or self.storeItem.specs.combinations == nil then
        return false
    end
    return #self.storeItem.specs.combinations > 0
end