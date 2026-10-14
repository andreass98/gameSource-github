AnimalScreenDealerFarm = {}
local AnimalScreenDealerFarm_mt = Class(AnimalScreenDealerFarm, AnimalScreenBase)
function AnimalScreenDealerFarm.new(husbandry, customMt)
    -- upvalues: (copy) AnimalScreenDealerFarm_mt
    local self = AnimalScreenBase.new(customMt or AnimalScreenDealerFarm_mt)
    self.husbandry = husbandry
    self.sourceActionText = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUY)
    self.targetActionText = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.SELL)
    self.sourceTitle = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.DEALER)
    return self
end
function AnimalScreenDealerFarm:initSourceItems()
    self.sourceItems = {}
    local animalTypeIndex = self.husbandry:getAnimalTypeIndex()
    local animalType = g_currentMission.animalSystem:getTypeByIndex(animalTypeIndex)
    if animalType ~= nil then
        for _, subTypeIndex in ipairs(animalType.subTypes) do
            local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
            for _, visual in ipairs(subType.visuals) do
                if visual.store.canBeBought then
                    local item = AnimalItemNew.new(subType.subTypeIndex, visual.minAge)
                    if self.sourceItems[animalTypeIndex] == nil then
                        self.sourceItems[animalTypeIndex] = {}
                    end
                    table.insert(self.sourceItems[animalTypeIndex], item)
                end
            end
        end
    end
end
function AnimalScreenDealerFarm:getSourceAnimalTypes()
    local animalTypeIndex = self.husbandry:getAnimalTypeIndex()
    return { g_currentMission.animalSystem:getTypeByIndex(animalTypeIndex) }
end
function AnimalScreenDealerFarm:getSourceItems(animalTypeIndex, isBuyMode)
    return isBuyMode and (self.sourceItems[animalTypeIndex] or {}) or {}
end
function AnimalScreenDealerFarm:initTargetItems()
    self.targetItems = {}
    local clusters = self.husbandry:getClusters()
    if clusters ~= nil then
        for _, cluster in ipairs(clusters) do
            local item = AnimalItemStock.new(cluster)
            table.insert(self.targetItems, item)
        end
    end
end
function AnimalScreenDealerFarm:getTargetName()
    local name = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.FARM)
    local used = self.husbandry:getNumOfAnimals()
    local total = self.husbandry:getMaxNumOfAnimals()
    return string.format("%s (%d / %d)", name, used, total)
end
function AnimalScreenDealerFarm:applySource(animalTypeIndex, itemIndex, numItems)
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    local subTypeIndex = item:getSubTypeIndex()
    local age = item:getAge()
    local singlePrice = -item:getPrice()
    local transportFee = -item:getTranportationFee(numItems)
    local buyPrice = singlePrice * numItems
    local errorCode = AnimalBuyEvent.validate(self.husbandry, subTypeIndex, age, numItems, buyPrice, transportFee, self.husbandry:getOwnerFarmId())
    if errorCode ~= nil then
        self.errorCallback(g_i18n:getText(AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[errorCode].text))
        return false
    end
    local data = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, data)
    g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
    g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(self.husbandry, subTypeIndex, age, numItems, buyPrice, transportFee))
    return true
end
function AnimalScreenDealerFarm:onAnimalBought(errorCode)
    g_messageCenter:unsubscribe(AnimalBuyEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local data = AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[errorCode]
    self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))
end
function AnimalScreenDealerFarm:applyTarget(_, itemIndex, numItems)
    local item = self.targetItems[itemIndex]
    local singlePrice = item:getPrice()
    local feePrice = -item:getTranportationFee(numItems)
    local sellPrice = singlePrice * numItems
    local clusterId = item:getClusterId()
    local errorCode = AnimalSellEvent.validate(self.husbandry, clusterId, numItems, sellPrice, feePrice)
    if errorCode ~= nil then
        self.errorCallback(g_i18n:getText(AnimalScreenDealerFarm.SELL_ERROR_CODE_MAPPING[errorCode].text))
        return false
    end
    local data = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.SELLING)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, data)
    g_messageCenter:subscribe(AnimalSellEvent, self.onAnimalSold, self)
    g_client:getServerConnection():sendEvent(AnimalSellEvent.new(self.husbandry, clusterId, numItems, sellPrice, feePrice))
    return true
end
function AnimalScreenDealerFarm:onAnimalSold(errorCode)
    g_messageCenter:unsubscribe(AnimalSellEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local data = AnimalScreenDealerFarm.SELL_ERROR_CODE_MAPPING[errorCode]
    self.targetActionFinished(data.isWarning, g_i18n:getText(data.text))
end
function AnimalScreenDealerFarm:getSourcePrice(animalTypeIndex, itemIndex, numItems)
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    local singlePrice = item:getPrice()
    local transportFee = item:getTranportationFee(numItems)
    local buyPrice = singlePrice * numItems
    return true, buyPrice, transportFee, buyPrice + transportFee
end
function AnimalScreenDealerFarm:getTargetPrice(_, itemIndex, numItems)
    local item = self.targetItems[itemIndex]
    local singlePrice = item:getPrice()
    local transportFee = -item:getTranportationFee(numItems)
    local sellPrice = singlePrice * numItems
    return true, sellPrice, transportFee, sellPrice + transportFee
end
function AnimalScreenDealerFarm:getApplySourceConfirmationText(animalTypeIndex, itemIndex, numItems)
    local _, _, _, totalPrice = self:getSourcePrice(animalTypeIndex, itemIndex, numItems)
    local text = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.CONFIRM_BUY)
    if numItems == 1 then
        text = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.CONFIRM_BUY_SINGULAR)
    end
    local price = g_i18n:formatMoney(math.abs(totalPrice), 0, true, true)
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    return string.namedFormat(text, "numAnimals", numItems, "animalType", item:getTitle() .. ", " .. item:getName(), "price", price)
end
function AnimalScreenDealerFarm:getApplyTargetConfirmationText(animalTypeIndex, itemIndex, numItems)
    local _, _, _, totalPrice = self:getTargetPrice(animalTypeIndex, itemIndex, numItems)
    local text = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.CONFIRM_SELL)
    if numItems == 1 then
        text = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.CONFIRM_SELL_SINGULAR)
    end
    local price = g_i18n:formatMoney(math.abs(totalPrice), 0, true, true)
    local item = self.targetItems[itemIndex]
    return string.namedFormat(text, "numAnimals", numItems, "animalType", item:getTitle() .. ", " .. item:getName(), "price", price)
end
function AnimalScreenDealerFarm:getSourceMaxNumAnimals(_)
    local maxNumAnimals = self:getMaxNumAnimals()
    return math.min(maxNumAnimals, self.husbandry:getNumOfFreeAnimalSlots())
end
function AnimalScreenDealerFarm:getTargetMaxNumAnimals(itemIndex)
    return self.targetItems[itemIndex]:getNumAnimals()
end
function AnimalScreenDealerFarm:getSourceData(_)
    return { self.husbandry }, g_i18n:getText("ui_animalTransport")
end
function AnimalScreenDealerFarm:getTargetData()
    return { #self.targetItems > 0 and self.husbandry or nil }, g_i18n:getText("ui_husbandryInformation")
end
function AnimalScreenDealerFarm:onAnimalsChanged(husbandry, _)
    if husbandry == self.husbandry then
        self:initItems()
        self.animalsChangedCallback()
    end
end
function AnimalScreenDealerFarm.onAnimalBuyError(_, errorCode)
    local data = AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[errorCode]
    if data ~= nil then
        InfoDialog.show(g_i18n:getText(data.text))
    end
end
AnimalScreenDealerFarm.L10N_SYMBOL = {
    ["DEALER"] = "animals_dealer",
    ["FARM"] = "ui_farm",
    ["CONFIRM_BUY"] = "shop_doYouWantToBuyAnimals",
    ["CONFIRM_SELL"] = "shop_doYouWantToSellAnimals",
    ["CONFIRM_BUY_SINGULAR"] = "shop_doYouWantToBuyAnimalsSingular",
    ["CONFIRM_SELL_SINGULAR"] = "shop_doYouWantToSellAnimalsSingular",
    ["BUYING"] = "shop_messageBuyingAnimals",
    ["SELLING"] = "shop_messageSellingAnimals",
    ["BUY"] = "button_buy",
    ["SELL"] = "button_sell"
}
AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING = {
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
        ["text"] = "shop_messageNotEnoughSpaceAnimals"
    },
    [AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED] = {
        ["warning"] = true,
        ["text"] = "shop_messageAnimalTypeNotSupported"
    },
    [AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED] = {
        ["warning"] = true,
        ["text"] = "shop_messageAnimalGlobalLimitReached"
    },
    [AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST] = {
        ["warning"] = true,
        ["text"] = "shop_messageHusbandryDoesNotExist"
    },
    [AnimalBuyEvent.BUY_ERROR_NO_BARN_AVAILABLE] = {
        ["warning"] = true,
        ["text"] = "shop_messageHusbandryBuyBarnFirst"
    }
}
AnimalScreenDealerFarm.SELL_ERROR_CODE_MAPPING = {
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
        ["text"] = "shop_messageHusbandryDoesNotExist"
    }
}