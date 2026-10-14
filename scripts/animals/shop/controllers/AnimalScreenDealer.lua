AnimalScreenDealer = {}
local AnimalScreenDealer_mt = Class(AnimalScreenDealer, AnimalScreenBase)
function AnimalScreenDealer.new(customMt)
    -- upvalues: (copy) AnimalScreenDealer_mt
    local self = AnimalScreenBase.new(customMt or AnimalScreenDealer_mt)
    self.husbandries = {}
    self.targetHusbandries = {}
    self.husbandry = nil
    self.sourceAnimalTypes = {}
    self.targetAnimalTypes = {}
    self.sourceActionText = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.BUY)
    self.targetActionText = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.SELL)
    self.sourceTitle = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.DEALER)
    return self
end
function AnimalScreenDealer:initItems()
    AnimalScreenDealer:superClass().initItems(self)
    self.husbandries = {}
    self.targetHusbandries = {}
    self.targetAnimalTypes = {}
    local husbandries = g_currentMission.husbandrySystem:getPlaceablesByFarm()
    for _, husbandry in pairs(husbandries) do
        local animalTypeIndex = husbandry:getAnimalTypeIndex()
        if self.husbandries[animalTypeIndex] == nil then
            self.husbandries[animalTypeIndex] = {}
        end
        if husbandry:getNumOfAnimals() > 0 then
            table.insert(self.targetAnimalTypes, g_currentMission.animalSystem:getTypeByIndex(animalTypeIndex))
            table.insert(self.targetHusbandries, husbandry)
        end
        table.insert(self.husbandries[animalTypeIndex], husbandry)
    end
    table.sort(self.targetAnimalTypes, function(a, b)
        return a.typeIndex < b.typeIndex
    end)
    table.sort(self.targetHusbandries, function(a, b)
        return a:getAnimalTypeIndex() < b:getAnimalTypeIndex()
    end)
end
function AnimalScreenDealer:initSourceItems()
    self.sourceItems = {}
    self.sourceAnimalTypes = g_currentMission.animalSystem:getTypes()
    for animalTypeIndex, animalType in pairs(self.sourceAnimalTypes) do
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
function AnimalScreenDealer:getSourceAnimalTypes(isBuying)
    if isBuying then
        return self.sourceAnimalTypes
    else
        return self.targetAnimalTypes
    end
end
function AnimalScreenDealer:initTargetItems()
    self.targetItems = {}
    if self.husbandry ~= nil then
        local clusters = self.husbandry:getClusters()
        if clusters ~= nil then
            for _, cluster in ipairs(clusters) do
                local item = AnimalItemStock.new(cluster)
                table.insert(self.targetItems, item)
            end
        end
    end
end
function AnimalScreenDealer:getTargetName()
    local name = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.FARM)
    local used = self.husbandry:getNumOfAnimals()
    local total = self.husbandry:getMaxNumOfAnimals()
    return string.format("%s (%d / %d)", name, used, total)
end
function AnimalScreenDealer:applySource(animalTypeIndex, itemIndex, numItems)
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    local subTypeIndex = item:getSubTypeIndex()
    local age = item:getAge()
    local singlePrice = -item:getPrice()
    local transportFee = -item:getTranportationFee(numItems)
    local buyPrice = singlePrice * numItems
    local errorCode = AnimalBuyEvent.validate(self.husbandry, subTypeIndex, age, numItems, buyPrice, transportFee, self.husbandry:getOwnerFarmId())
    if errorCode ~= nil then
        self.errorCallback(g_i18n:getText(AnimalScreenDealer.BUY_ERROR_CODE_MAPPING[errorCode].text))
        return false
    end
    local data = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.BUYING)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, data)
    g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
    g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(self.husbandry, subTypeIndex, age, numItems, buyPrice, transportFee))
    return true
end
function AnimalScreenDealer:onAnimalBought(errorCode)
    g_messageCenter:unsubscribe(AnimalBuyEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local data = AnimalScreenDealer.BUY_ERROR_CODE_MAPPING[errorCode]
    self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))
end
function AnimalScreenDealer:applyTarget(_, itemIndex, numItems)
    local item = self.targetItems[itemIndex]
    local singlePrice = item:getPrice()
    local feePrice = -item:getTranportationFee(numItems)
    local sellPrice = singlePrice * numItems
    local clusterId = item:getClusterId()
    local errorCode = AnimalSellEvent.validate(self.husbandry, clusterId, numItems, sellPrice, feePrice)
    if errorCode ~= nil then
        self.errorCallback(g_i18n:getText(AnimalScreenDealer.SELL_ERROR_CODE_MAPPING[errorCode].text))
        return false
    end
    local data = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.SELLING)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, data)
    g_messageCenter:subscribe(AnimalSellEvent, self.onAnimalSold, self)
    g_client:getServerConnection():sendEvent(AnimalSellEvent.new(self.husbandry, clusterId, numItems, sellPrice, feePrice))
    return true
end
function AnimalScreenDealer:onAnimalSold(errorCode)
    g_messageCenter:unsubscribe(AnimalSellEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local data = AnimalScreenDealer.SELL_ERROR_CODE_MAPPING[errorCode]
    self.targetActionFinished(data.isWarning, g_i18n:getText(data.text))
end
function AnimalScreenDealer:getSourcePrice(animalTypeIndex, itemIndex, numItems)
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    local singlePrice = item:getPrice()
    local transportFee = item:getTranportationFee(numItems)
    local buyPrice = singlePrice * numItems
    return true, buyPrice, transportFee, buyPrice + transportFee
end
function AnimalScreenDealer:getTargetPrice(_, itemIndex, numItems)
    local item = self.targetItems[itemIndex]
    local singlePrice = item:getPrice()
    local transportFee = -item:getTranportationFee(numItems)
    local sellPrice = singlePrice * numItems
    return true, sellPrice, transportFee, sellPrice + transportFee
end
function AnimalScreenDealer:getApplySourceConfirmationText(animalTypeIndex, itemIndex, numItems)
    local _, _, _, totalPrice = self:getSourcePrice(animalTypeIndex, itemIndex, numItems)
    local text = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.CONFIRM_BUY)
    if numItems == 1 then
        text = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.CONFIRM_BUY_SINGULAR)
    end
    local price = g_i18n:formatMoney(math.abs(totalPrice), 0, true, true)
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    return string.namedFormat(text, "numAnimals", numItems, "animalType", item:getTitle() .. ", " .. item:getName(), "price", price)
end
function AnimalScreenDealer:getApplyTargetConfirmationText(animalTypeIndex, itemIndex, numItems)
    local _, _, _, totalPrice = self:getTargetPrice(animalTypeIndex, itemIndex, numItems)
    local text = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.CONFIRM_SELL)
    if numItems == 1 then
        text = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.CONFIRM_SELL_SINGULAR)
    end
    local price = g_i18n:formatMoney(math.abs(totalPrice), 0, true, true)
    local item = self.targetItems[itemIndex]
    return string.namedFormat(text, "numAnimals", numItems, "animalType", item:getTitle() .. ", " .. item:getName(), "price", price)
end
function AnimalScreenDealer:getSourceMaxNumAnimals(_)
    local maxNumAnimals = self:getMaxNumAnimals()
    local husbandryMaxSlots = self.husbandry ~= nil and self.husbandry:getNumOfFreeAnimalSlots() or 0
    return math.min(maxNumAnimals, husbandryMaxSlots)
end
function AnimalScreenDealer:getTargetMaxNumAnimals(itemIndex)
    return self.targetItems[itemIndex]:getNumAnimals()
end
function AnimalScreenDealer:getSourceData(id)
    return self.husbandries[id] or {}, g_i18n:getText("ui_animalTransport")
end
function AnimalScreenDealer:getTargetData(id)
    return { self.targetHusbandries[id] }, g_i18n:getText("ui_husbandryInformation")
end
function AnimalScreenDealer:onAnimalsChanged(husbandry, _)
    if husbandry == self.husbandry then
        self:initItems()
        self.animalsChangedCallback()
    end
end
function AnimalScreenDealer.onAnimalBuyError(_, errorCode)
    local data = AnimalScreenDealer.BUY_ERROR_CODE_MAPPING[errorCode]
    if data ~= nil then
        InfoDialog.show(g_i18n:getText(data.text))
    end
end
function AnimalScreenDealer:setCurrentHusbandry(animalTypeIndex, husbandryIndex, isBuyMode)
    if isBuyMode then
        local husbandries = self.husbandries[animalTypeIndex]
        self.husbandry = husbandries ~= nil and husbandries[husbandryIndex] or nil
    else
        self.husbandry = self.targetHusbandries[husbandryIndex]
    end
    self:initTargetItems()
end
AnimalScreenDealer.L10N_SYMBOL = {
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
AnimalScreenDealer.BUY_ERROR_CODE_MAPPING = {
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
AnimalScreenDealer.SELL_ERROR_CODE_MAPPING = {
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