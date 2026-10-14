AnimalScreenTrailerFarm = {}
local AnimalScreenTrailerFarm_mt = Class(AnimalScreenTrailerFarm, AnimalScreenBase)
function AnimalScreenTrailerFarm.new(husbandry, trailer, customMt)
    -- upvalues: (copy) AnimalScreenTrailerFarm_mt
    local self = AnimalScreenBase.new(customMt or AnimalScreenTrailerFarm_mt)
    self.husbandry = husbandry
    self.trailer = trailer
    return self
end
function AnimalScreenTrailerFarm:initSourceItems()
    self.sourceItems = {}
    local animalTypeIndex = self.trailer:getCurrentAnimalType()
    if animalTypeIndex ~= nil then
        local animalTypeIndex = animalTypeIndex.typeIndex
        local clusters = self.trailer:getClusters()
        if clusters ~= nil then
            for _, cluster in ipairs(clusters) do
                local item = AnimalItemStock.new(cluster)
                if self.sourceItems[animalTypeIndex] == nil then
                    self.sourceItems[animalTypeIndex] = {}
                end
                table.insert(self.sourceItems[animalTypeIndex], item)
            end
        end
    end
end
function AnimalScreenTrailerFarm:getSourceAnimalTypes()
    local animalTypeIndex = self.husbandry:getAnimalTypeIndex()
    return { g_currentMission.animalSystem:getTypeByIndex(animalTypeIndex) }
end
function AnimalScreenTrailerFarm:initTargetItems()
    self.targetItems = {}
    local clusters = self.husbandry:getClusters()
    if clusters ~= nil then
        for _, cluster in ipairs(clusters) do
            local item = AnimalItemStock.new(cluster)
            table.insert(self.targetItems, item)
        end
    end
end
function AnimalScreenTrailerFarm:getSourceName()
    local name = self.trailer:getName()
    local currentAnimalType = self.trailer:getCurrentAnimalType()
    if currentAnimalType == nil then
        return name
    end
    local used = self.trailer:getNumOfAnimals()
    local total = self.trailer:getMaxNumOfAnimals(currentAnimalType)
    return string.format("%s (%d / %d)", name, used, total)
end
function AnimalScreenTrailerFarm:getTargetName()
    local name = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.FARM)
    local used = self.husbandry:getNumOfAnimals()
    local total = self.husbandry:getMaxNumOfAnimals()
    return string.format("%s (%d / %d)", name, used, total)
end
function AnimalScreenTrailerFarm:getSourceActionText()
    return g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_FARM)
end
function AnimalScreenTrailerFarm:getTargetActionText()
    return g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_TRAILER)
end
function AnimalScreenTrailerFarm:getApplySourceConfirmationText(animalTypeIndex, itemIndex, numItems)
    local text = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.CONFIRM_MOVE_TO_FARM)
    if numItems == 1 then
        text = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.CONFIRM_MOVE_TO_FARM_SINGULAR)
    end
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    return string.namedFormat(text, "numAnimals", numItems, "animalType", item:getTitle() .. ", " .. item:getName())
end
function AnimalScreenTrailerFarm:getApplyTargetConfirmationText(_, itemIndex, numItems)
    local text = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER)
    if numItems == 1 then
        text = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER_SINGULAR)
    end
    local item = self.targetItems[itemIndex]
    return string.namedFormat(text, "numAnimals", numItems, "animalType", item:getTitle() .. ", " .. item:getName())
end
function AnimalScreenTrailerFarm:getSourcePrice(animalTypeIndex, itemIndex, numItems)
    return false, 0, 0, 0
end
function AnimalScreenTrailerFarm:getTargetPrice(animalTypeIndex, itemIndex, numItems)
    return false, 0, 0, 0
end
function AnimalScreenTrailerFarm:getSourceMaxNumAnimals(animalTypeIndex, itemIndex)
    if self.sourceItems[animalTypeIndex] == nil then
        return 0
    end
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    if item == nil then
        return 0
    end
    local maxNumAnimals = self:getMaxNumAnimals()
    return math.min(maxNumAnimals, item:getNumAnimals(), self.husbandry:getNumOfFreeAnimalSlots())
end
function AnimalScreenTrailerFarm:getTargetMaxNumAnimals(itemIndex)
    local item = self.targetItems[itemIndex]
    if item == nil then
        return 0
    end
    local animalSystem = g_currentMission.animalSystem
    local animalType = animalSystem:getTypeByIndex(animalSystem:getSubTypeByIndex(item:getSubTypeIndex()).typeIndex)
    local used = self.trailer:getNumOfAnimals()
    local free = self.trailer:getMaxNumOfAnimals(animalType) - used
    local maxNumAnimals = self:getMaxNumAnimals()
    return math.min(maxNumAnimals, free, item:getNumAnimals())
end
function AnimalScreenTrailerFarm:getSourceData(_)
    return { self.trailer }, g_i18n:getText("ui_animalUnloadFrom")
end
function AnimalScreenTrailerFarm:getTargetData()
    return { self.husbandry }, g_i18n:getText("ui_husbandryInformation")
end
function AnimalScreenTrailerFarm:applySource(animalTypeIndex, itemIndex, numItems)
    local clusterId = self.sourceItems[animalTypeIndex][itemIndex]:getClusterId()
    local errorCode = AnimalMoveEvent.validate(self.trailer, self.husbandry, clusterId, numItems, self.trailer:getOwnerFarmId())
    if errorCode ~= nil then
        self.errorCallback(g_i18n:getText(AnimalScreenTrailerFarm.MOVE_TO_FARM_ERROR_CODE_MAPPING[errorCode].text))
        return false
    end
    local data = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_FARM)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, data)
    g_messageCenter:subscribe(AnimalMoveEvent, self.onAnimalMovedToFarm, self)
    g_client:getServerConnection():sendEvent(AnimalMoveEvent.new(self.trailer, self.husbandry, clusterId, numItems))
    return true
end
function AnimalScreenTrailerFarm:onAnimalMovedToFarm(errorCode)
    g_messageCenter:unsubscribe(AnimalMoveEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local data = AnimalScreenTrailerFarm.MOVE_TO_FARM_ERROR_CODE_MAPPING[errorCode]
    self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))
end
function AnimalScreenTrailerFarm:applyTarget(_, itemIndex, numItems)
    local clusterId = self.targetItems[itemIndex]:getClusterId()
    local errorCode = AnimalMoveEvent.validate(self.husbandry, self.trailer, clusterId, numItems, self.trailer:getOwnerFarmId())
    if errorCode ~= nil then
        self.errorCallback(g_i18n:getText(AnimalScreenTrailerFarm.MOVE_TO_TRAILER_ERROR_CODE_MAPPING[errorCode].text))
        return false
    end
    local data = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_TRAILER)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, data)
    g_messageCenter:subscribe(AnimalMoveEvent, self.onAnimalMovedToTrailer, self)
    g_client:getServerConnection():sendEvent(AnimalMoveEvent.new(self.husbandry, self.trailer, clusterId, numItems))
    return true
end
function AnimalScreenTrailerFarm:onAnimalMovedToTrailer(errorCode)
    g_messageCenter:unsubscribe(AnimalMoveEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local data = AnimalScreenTrailerFarm.MOVE_TO_TRAILER_ERROR_CODE_MAPPING[errorCode]
    self.targetActionFinished(data.isWarning, g_i18n:getText(data.text))
end
function AnimalScreenTrailerFarm:onAnimalsChanged(obj, _)
    if obj == self.trailer or obj == self.husbandry then
        self:initItems()
        self.animalsChangedCallback()
    end
end
AnimalScreenTrailerFarm.L10N_SYMBOL = {
    ["FARM"] = "ui_farm",
    ["MOVE_TO_FARM"] = "shop_moveToFarm",
    ["MOVE_TO_TRAILER"] = "shop_moveToTrailer",
    ["CONFIRM_MOVE_TO_FARM"] = "shop_doYouWantToMoveAnimalsToFarm",
    ["CONFIRM_MOVE_TO_TRAILER"] = "shop_doYouWantToMoveAnimalsToTrailer",
    ["CONFIRM_MOVE_TO_FARM_SINGULAR"] = "shop_doYouWantToMoveAnimalsToFarmSingular",
    ["CONFIRM_MOVE_TO_TRAILER_SINGULAR"] = "shop_doYouWantToMoveAnimalsToTrailerSingular"
}
AnimalScreenTrailerFarm.MOVE_TO_TRAILER_ERROR_CODE_MAPPING = {
    [AnimalMoveEvent.MOVE_SUCCESS] = {
        ["warning"] = false,
        ["text"] = "shop_movedToTrailer"
    },
    [AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION] = {
        ["warning"] = true,
        ["text"] = "shop_messageNoPermissionToTradeAnimals"
    },
    [AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST] = {
        ["warning"] = true,
        ["text"] = "shop_messageHusbandryDoesNotExist"
    },
    [AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST] = {
        ["warning"] = true,
        ["text"] = "shop_messageTrailerDoesNotExist"
    },
    [AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER] = {
        ["warning"] = true,
        ["text"] = "shop_messageInvalidCluster"
    },
    [AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED] = {
        ["warning"] = true,
        ["text"] = "shop_messageAnimalTypeNotSupportedByTrailer"
    },
    [AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughSpaceAnimalsTrailer"
    },
    [AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughAnimals"
    }
}
AnimalScreenTrailerFarm.MOVE_TO_FARM_ERROR_CODE_MAPPING = {
    [AnimalMoveEvent.MOVE_SUCCESS] = {
        ["warning"] = false,
        ["text"] = "shop_movedToFarm"
    },
    [AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION] = {
        ["warning"] = true,
        ["text"] = "shop_messageNoPermissionToTradeAnimals"
    },
    [AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST] = {
        ["warning"] = true,
        ["text"] = "shop_messageTrailerDoesNotExist"
    },
    [AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST] = {
        ["warning"] = true,
        ["text"] = "shop_messageHusbandryDoesNotExist"
    },
    [AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER] = {
        ["warning"] = true,
        ["text"] = "shop_messageInvalidCluster"
    },
    [AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED] = {
        ["warning"] = true,
        ["text"] = "shop_messageAnimalTypeNotSupported"
    },
    [AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughSpaceAnimals"
    },
    [AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughAnimals"
    }
}