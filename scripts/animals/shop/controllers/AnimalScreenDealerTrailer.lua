AnimalScreenDealerTrailer = {}
local AnimalScreenDealerTrailer_mt = Class(AnimalScreenDealerTrailer, AnimalScreenBase)
function AnimalScreenDealerTrailer.new(trailer, customMt)
    -- upvalues: (copy) AnimalScreenDealerTrailer_mt
    local self = AnimalScreenBase.new(customMt or AnimalScreenDealerTrailer_mt)
    self.trailer = trailer
    self.sourceActionText = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.BUY)
    self.targetActionText = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.SELL)
    self.sourceTitle = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.DEALER)
    return self
end
function AnimalScreenDealerTrailer:initSourceItems()
    self.sourceItems = {}
    local currentAnimalType = self.trailer:getCurrentAnimalType()
    local animalTypes = g_currentMission.animalSystem:getTypes()
    for _, animalType in ipairs(animalTypes) do
        if (currentAnimalType == nil or animalType == currentAnimalType) and self.trailer:getSupportsAnimalType(animalType.typeIndex) then
            for _, subTypeIndex in ipairs(animalType.subTypes) do
                local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
                for _, visual in ipairs(subType.visuals) do
                    if visual.store.canBeBought then
                        local item = AnimalItemNew.new(subType.subTypeIndex, visual.minAge)
                        if self.sourceItems[animalType.typeIndex] == nil then
                            self.sourceItems[animalType.typeIndex] = {}
                        end
                        table.insert(self.sourceItems[animalType.typeIndex], item)
                    end
                end
            end
        end
    end
end
function AnimalScreenDealerTrailer:getSourceAnimalTypes()
    local currentAnimalType = self.trailer:getCurrentAnimalType()
    if currentAnimalType ~= nil then
        return { currentAnimalType }
    end
    local supportedAnimalTypes = {}
    local animalTypes = g_currentMission.animalSystem:getTypes()
    for _, animalType in ipairs(animalTypes) do
        if self.trailer:getSupportsAnimalType(animalType.typeIndex) then
            table.insert(supportedAnimalTypes, animalType)
        end
    end
    return supportedAnimalTypes
end
function AnimalScreenDealerTrailer:initTargetItems()
    self.targetItems = {}
    local clusters = self.trailer:getClusters()
    if clusters ~= nil then
        for _, cluster in ipairs(clusters) do
            local item = AnimalItemStock.new(cluster)
            table.insert(self.targetItems, item)
        end
    end
end
function AnimalScreenDealerTrailer:getTargetName()
    local name = self.trailer:getName()
    local currentAnimalType = self.trailer:getCurrentAnimalType()
    if currentAnimalType == nil then
        return name
    end
    local used = self.trailer:getNumOfAnimals()
    local total = self.trailer:getMaxNumOfAnimals(currentAnimalType)
    return string.format("%s (%d / %d)", name, used, total)
end
function AnimalScreenDealerTrailer:getSourcePrice(animalTypeIndex, itemIndex, numItems)
    local buyPrice = self.sourceItems[animalTypeIndex][itemIndex]:getPrice() * numItems
    return true, buyPrice, 0, buyPrice
end
function AnimalScreenDealerTrailer:getTargetPrice(_, itemIndex, numItems)
    local sellPrice = self.targetItems[itemIndex]:getPrice() * numItems
    return true, sellPrice, 0, sellPrice
end
function AnimalScreenDealerTrailer:getSourceMaxNumAnimals(animalTypeIndex, itemIndex)
    local animalSystem = g_currentMission.animalSystem
    local animalType = animalSystem:getTypeByIndex(animalSystem:getSubTypeByIndex(self.sourceItems[animalTypeIndex][itemIndex]:getSubTypeIndex()).typeIndex)
    local used = self.trailer:getNumOfAnimals()
    local free = self.trailer:getMaxNumOfAnimals(animalType) - used
    local maxNumAnimals = self:getMaxNumAnimals()
    return math.min(maxNumAnimals, free)
end
function AnimalScreenDealerTrailer:getTargetMaxNumAnimals(itemIndex)
    local item = self.targetItems[itemIndex]
    return item == nil and 0 or item:getNumAnimals()
end
function AnimalScreenDealerTrailer:getSourceData(_)
    return { self.trailer }, g_i18n:getText("ui_animalLoadOnto")
end
function AnimalScreenDealerTrailer:getTargetData()
    return { self.trailer }, g_i18n:getText("ui_animalSellFrom")
end
function AnimalScreenDealerTrailer:getApplySourceConfirmationText(animalTypeIndex, itemIndex, numItems)
    local _, _, _, totalPrice = self:getSourcePrice(animalTypeIndex, itemIndex, numItems)
    local text = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.CONFIRM_BUY)
    if numItems == 1 then
        text = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.CONFIRM_BUY_SINGULAR)
    end
    local price = g_i18n:formatMoney(math.abs(totalPrice), 0, true, true)
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    return string.namedFormat(text, "numAnimals", numItems, "animalType", item:getTitle() .. ", " .. item:getName(), "price", price)
end
function AnimalScreenDealerTrailer:getApplyTargetConfirmationText(animalTypeIndex, itemIndex, numItems)
    local _, _, _, totalPrice = self:getTargetPrice(animalTypeIndex, itemIndex, numItems)
    local text = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.CONFIRM_SELL)
    if numItems == 1 then
        text = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.CONFIRM_SELL_SINGULAR)
    end
    local price = g_i18n:formatMoney(math.abs(totalPrice), 0, true, true)
    local item = self.targetItems[itemIndex]
    return string.namedFormat(text, "numAnimals", numItems, "animalType", item:getTitle() .. ", " .. item:getName(), "price", price)
end
function AnimalScreenDealerTrailer:applySource(animalTypeIndex, itemIndex, numItems)
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    local subTypeIndex = item:getSubTypeIndex()
    local age = item:getAge()
    local buyPrice = -item:getPrice() * numItems
    local errorCode = AnimalBuyEvent.validate(self.trailer, subTypeIndex, age, numItems, buyPrice, 0, self.trailer:getOwnerFarmId())
    if errorCode ~= nil then
        self.errorCallback(g_i18n:getText(AnimalScreenDealerTrailer.BUY_ERROR_CODE_MAPPING[errorCode].text))
        return false
    end
    local data = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.BUYING)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, data)
    g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
    g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(self.trailer, subTypeIndex, age, numItems, buyPrice, 0))
    return true
end
function AnimalScreenDealerTrailer:onAnimalBought(errorCode)
    g_messageCenter:unsubscribe(AnimalBuyEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local data = AnimalScreenDealerTrailer.BUY_ERROR_CODE_MAPPING[errorCode]
    self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))
end
function AnimalScreenDealerTrailer:applyTarget(_, itemIndex, numItems)
    local item = self.targetItems[itemIndex]
    local sellPrice = item:getPrice() * numItems
    local clusterId = item:getClusterId()
    local errorCode = AnimalSellEvent.validate(self.trailer, clusterId, numItems, sellPrice, 0)
    if errorCode ~= nil then
        self.errorCallback(g_i18n:getText(AnimalScreenDealerTrailer.SELL_ERROR_CODE_MAPPING[errorCode].text))
        return false
    end
    local data = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.SELLING)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, data)
    g_messageCenter:subscribe(AnimalSellEvent, self.onAnimalSold, self)
    g_client:getServerConnection():sendEvent(AnimalSellEvent.new(self.trailer, clusterId, numItems, sellPrice, 0))
    return true
end
function AnimalScreenDealerTrailer:onAnimalSold(errorCode)
    g_messageCenter:unsubscribe(AnimalSellEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local data = AnimalScreenDealerTrailer.SELL_ERROR_CODE_MAPPING[errorCode]
    self.targetActionFinished(data.isWarning, g_i18n:getText(data.text))
end
function AnimalScreenDealerTrailer:onAnimalsChanged(trailer, _)
    if trailer == self.trailer then
        self:initItems()
        self.animalsChangedCallback()
    end
end
function AnimalScreenDealerTrailer.onAnimalBuyError(_, errorCode)
    local data = AnimalScreenDealerTrailer.BUY_ERROR_CODE_MAPPING[errorCode]
    if data ~= nil then
        InfoDialog.show(g_i18n:getText(data.text))
    end
end
AnimalScreenDealerTrailer.L10N_SYMBOL = {
    ["DEALER"] = "animals_dealer",
    ["BUY"] = "button_buy",
    ["SELL"] = "button_sell",
    ["CONFIRM_BUY"] = "shop_doYouWantToBuyAnimals",
    ["CONFIRM_SELL"] = "shop_doYouWantToSellAnimals",
    ["CONFIRM_BUY_SINGULAR"] = "shop_doYouWantToBuyAnimalsSingular",
    ["CONFIRM_SELL_SINGULAR"] = "shop_doYouWantToSellAnimalsSingular",
    ["BUYING"] = "shop_messageBuyingAnimals",
    ["SELLING"] = "shop_messageSellingAnimals"
}
AnimalScreenDealerTrailer.BUY_ERROR_CODE_MAPPING = {
    [AnimalBuyEvent.BUY_SUCCESS] = {
        ["warning"] = false,
        ["text"] = "shop_messageBoughtAnimals"
    },
    [AnimalBuyEvent.BUY_ERROR_NO_PERMISSION] = {
        ["warning"] = true,
        ["text"] = "shop_messageNoPermissionToTradeAnimals"
    },
    [AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughMoneyToBuy"
    },
    [AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_SPACE] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughSpaceAnimalsTrailer"
    },
    [AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED] = {
        ["warning"] = true,
        ["text"] = "shop_messageAnimalTypeNotSupportedByTrailer"
    },
    [AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED] = {
        ["warning"] = true,
        ["text"] = "shop_messageAnimalGlobalLimitReached"
    },
    [AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST] = {
        ["warning"] = true,
        ["text"] = "shop_messageTrailerDoesNotExist"
    },
    [AnimalBuyEvent.BUY_ERROR_NO_BARN_AVAILABLE] = {
        ["warning"] = true,
        ["text"] = "shop_messageHusbandryBuyBarnFirst"
    }
}
AnimalScreenDealerTrailer.SELL_ERROR_CODE_MAPPING = {
    [AnimalSellEvent.SELL_SUCCESS] = {
        ["warning"] = false,
        ["text"] = "shop_messageSoldAnimals"
    },
    [AnimalSellEvent.SELL_ERROR_NO_PERMISSION] = {
        ["warning"] = true,
        ["text"] = "shop_messageNoPermissionToTradeAnimals"
    },
    [AnimalSellEvent.SELL_ERROR_INVALID_CLUSTER] = {
        ["warning"] = true,
        ["text"] = "shop_messageInvalidCluster"
    },
    [AnimalSellEvent.SELL_ERROR_NOT_ENOUGH_ANIMALS] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughAnimals"
    },
    [AnimalSellEvent.SELL_ERROR_CANNOT_BE_SOLD] = {
        ["warning"] = true,
        ["text"] = "shop_messageCannotSellAnimal"
    },
    [AnimalSellEvent.SELL_ERROR_OBJECT_DOES_NOT_EXIST] = {
        ["warning"] = true,
        ["text"] = "shop_messageTrailerDoesNotExist"
    }
}