AnimalScreenTrailer = {}
local AnimalScreenTrailer_mt = Class(AnimalScreenTrailer, AnimalScreenBase)
function AnimalScreenTrailer.new(trailer, customMt)
    -- upvalues: (copy) AnimalScreenTrailer_mt
    local self = AnimalScreenBase.new(customMt or AnimalScreenTrailer_mt)
    self.trailer = trailer
    self.trailer:setAnimalScreenController(self)
    return self
end
function AnimalScreenTrailer:reset()
    self.trailer:setAnimalScreenController(nil)
    AnimalScreenTrailer:superClass().reset(self)
end
function AnimalScreenTrailer:initSourceItems()
    self.sourceItems = {}
    self.clusterToVehicle = {}
    local rideables = self.trailer:getRideablesInTrigger()
    if rideables ~= nil then
        for _, rideable in ipairs(rideables) do
            local cluster = rideable:getCluster()
            local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(cluster.subTypeIndex)
            local item = AnimalItemStock.new(cluster)
            if self.sourceItems[animalTypeIndex] == nil then
                self.sourceItems[animalTypeIndex] = {}
            end
            table.insert(self.sourceItems[animalTypeIndex], item)
            self.clusterToVehicle[cluster] = rideable
        end
    end
end
function AnimalScreenTrailer:getSourceAnimalTypes()
    local supportedAnimalTypes = {}
    local animalTypes = g_currentMission.animalSystem:getTypes()
    for _, animalType in ipairs(animalTypes) do
        if self.trailer:getSupportsAnimalType(animalType.typeIndex) then
            table.insert(supportedAnimalTypes, animalType)
        end
    end
    return supportedAnimalTypes
end
function AnimalScreenTrailer:initTargetItems()
    self.targetItems = {}
    local clusters = self.trailer:getClusters()
    if clusters ~= nil then
        for _, cluster in ipairs(clusters) do
            local item = AnimalItemStock.new(cluster)
            table.insert(self.targetItems, item)
        end
    end
end
function AnimalScreenTrailer:getSourceName()
    local name = self.trailer:getName()
    local currentAnimalType = self.trailer:getCurrentAnimalType()
    if currentAnimalType == nil then
        return name
    end
    local used = self.trailer:getNumOfAnimals()
    local total = self.trailer:getMaxNumOfAnimals(currentAnimalType)
    return string.format("%s (%d / %d)", name, used, total)
end
function AnimalScreenTrailer:getTargetName()
    return ""
end
function AnimalScreenTrailer:getSourceActionText()
    return g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_TRAILER)
end
function AnimalScreenTrailer:getTargetActionText()
    return g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_SPAWN_PLACE)
end
function AnimalScreenTrailer:getApplySourceConfirmationText(animalTypeIndex, itemIndex, numItems)
    local text = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER)
    if numItems == 1 then
        text = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER_SINGULAR)
    end
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    return string.namedFormat(text, "numAnimals", numItems, "animalType", item:getTitle() .. ", " .. item:getName())
end
function AnimalScreenTrailer:getApplyTargetConfirmationText(_, itemIndex, numItems)
    local text = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_SPAWN_PLACE)
    if numItems == 1 then
        text = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_SPAWN_PLACE_SINGULAR)
    end
    local item = self.targetItems[itemIndex]
    return string.format(text, item:getTitle() .. ", " .. item:getName())
end
function AnimalScreenTrailer:getSourcePrice(animalTypeIndex, itemIndex, numItems)
    return false, 0, 0, 0
end
function AnimalScreenTrailer:getTargetPrice(animalTypeIndex, itemIndex, numItems)
    return false, 0, 0, 0
end
function AnimalScreenTrailer:getSourceMaxNumAnimals(itemIndex)
    return 1
end
function AnimalScreenTrailer:getTargetMaxNumAnimals(itemIndex)
    return 1
end
function AnimalScreenTrailer:getSourceData(_)
    return { self.trailer }, g_i18n:getText("ui_animalLoadOnto")
end
function AnimalScreenTrailer:getTargetData()
    return { self.trailer }, g_i18n:getText("ui_animalUnloadFrom")
end
function AnimalScreenTrailer:applySource(animalTypeIndex, itemIndex, _)
    local cluster = self.sourceItems[animalTypeIndex][itemIndex]:getCluster()
    local rideable = self.clusterToVehicle[cluster]
    local errorCode = AnimalLoadEvent.validate(self.trailer, rideable, self.trailer:getOwnerFarmId())
    if errorCode ~= nil then
        self.errorCallback(g_i18n:getText(AnimalScreenTrailer.LOAD_ERROR_CODE_MAPPING[errorCode].text))
        return false
    end
    local data = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_TRAILER)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, data)
    g_messageCenter:subscribe(AnimalLoadEvent, self.onAnimalLoadedToTrailer, self)
    g_client:getServerConnection():sendEvent(AnimalLoadEvent.new(self.trailer, rideable))
    return true
end
function AnimalScreenTrailer:onAnimalMovedToSpawnPlace(errorCode)
    g_messageCenter:unsubscribe(AnimalUnloadEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local data = AnimalScreenTrailer.UNLOAD_ERROR_CODE_MAPPING[errorCode]
    self.sourceActionFinished(data.isWarning, g_i18n:getText(data.text))
end
function AnimalScreenTrailer:applyTarget(_, itemIndex, _)
    local clusterId = self.targetItems[itemIndex]:getClusterId()
    local errorCode = AnimalUnloadEvent.validate(self.trailer, clusterId)
    if errorCode ~= nil then
        self.errorCallback(g_i18n:getText(AnimalScreenTrailer.UNLOAD_ERROR_CODE_MAPPING[errorCode].text))
        return false
    end
    local data = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_SPAWN_PLACE)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, data)
    g_messageCenter:subscribe(AnimalUnloadEvent, self.onAnimalMovedToSpawnPlace, self)
    g_client:getServerConnection():sendEvent(AnimalUnloadEvent.new(self.trailer, clusterId))
    return true
end
function AnimalScreenTrailer:onAnimalLoadedToTrailer(errorCode)
    g_messageCenter:unsubscribe(AnimalLoadEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local data = AnimalScreenTrailer.LOAD_ERROR_CODE_MAPPING[errorCode]
    self.targetActionFinished(data.isWarning, g_i18n:getText(data.text))
end
function AnimalScreenTrailer:onAnimalsChanged(obj, _)
    if obj == self.trailer then
        self:initItems()
        self.animalsChangedCallback()
    end
end
AnimalScreenTrailer.L10N_SYMBOL = {
    ["MOVE_TO_SPAWN_PLACE"] = "shop_moveToSpawnPlace",
    ["MOVE_TO_TRAILER"] = "shop_moveToTrailer",
    ["CONFIRM_MOVE_TO_SPAWN_PLACE"] = "shop_doYouWantToMoveAnimalsToSpawnPlace",
    ["CONFIRM_MOVE_TO_TRAILER"] = "shop_doYouWantToMoveAnimalsToTrailer",
    ["CONFIRM_MOVE_TO_SPAWN_PLACE_SINGULAR"] = "shop_doYouWantToMoveAnimalsToSpawnPlaceSingular",
    ["CONFIRM_MOVE_TO_TRAILER_SINGULAR"] = "shop_doYouWantToMoveAnimalsToTrailerSingular"
}
AnimalScreenTrailer.LOAD_ERROR_CODE_MAPPING = {
    [AnimalLoadEvent.LOAD_SUCCESS] = {
        ["warning"] = false,
        ["text"] = "shop_movedToTrailer"
    },
    [AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION] = {
        ["warning"] = true,
        ["text"] = "shop_messageNoPermissionToTradeAnimals"
    },
    [AnimalLoadEvent.LOAD_ERROR_TRAILER_DOES_NOT_EXIST] = {
        ["warning"] = true,
        ["text"] = "shop_messageTrailerDoesNotExist"
    },
    [AnimalLoadEvent.LOAD_ERROR_RIDEABLE_DOES_NOT_EXIST] = {
        ["warning"] = true,
        ["text"] = "shop_messageRideableDoesNotExist"
    },
    [AnimalLoadEvent.LOAD_ERROR_INVALID_CLUSTER] = {
        ["warning"] = true,
        ["text"] = "shop_messageInvalidCluster"
    },
    [AnimalLoadEvent.LOAD_ERROR_ANIMAL_NOT_SUPPORTED] = {
        ["warning"] = true,
        ["text"] = "shop_messageAnimalTypeNotSupportedByTrailer"
    },
    [AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_ANIMALS] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughAnimals"
    },
    [AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_SPACE] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughSpaceAnimalsTrailer"
    }
}
AnimalScreenTrailer.UNLOAD_ERROR_CODE_MAPPING = {
    [AnimalUnloadEvent.UNLOAD_SUCCESS] = {
        ["warning"] = false,
        ["text"] = "shop_movedToSpawnPlace"
    },
    [AnimalUnloadEvent.UNLOAD_ERROR_NO_PERMISSION] = {
        ["warning"] = true,
        ["text"] = "shop_messageNoPermissionToTradeAnimals"
    },
    [AnimalUnloadEvent.UNLOAD_ERROR_INVALID_CLUSTER] = {
        ["warning"] = true,
        ["text"] = "shop_messageInvalidCluster"
    },
    [AnimalUnloadEvent.UNLOAD_ERROR_COULD_NOT_BE_LOADED] = {
        ["warning"] = true,
        ["text"] = "shop_messageAnimalCouldNotBeUnloaded"
    },
    [AnimalUnloadEvent.UNLOAD_ERROR_DOES_NOT_SUPPORT_UNLOADING] = {
        ["warning"] = true,
        ["text"] = "shop_messageAnimalDoesNotSupportUnloading"
    },
    [AnimalUnloadEvent.UNLOAD_ERROR_NO_SPACE] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughSpaceAnimalsArea"
    },
    [AnimalUnloadEvent.UNLOAD_ERROR_NOT_ENOUGH_ANIMALS] = {
        ["warning"] = true,
        ["text"] = "shop_messageNotEnoughAnimals"
    },
    [AnimalUnloadEvent.UNLOAD_ERROR_RIDEABLE_LIMIT_REACHED] = {
        ["warning"] = true,
        ["text"] = "shop_messageAnimalRideableLimitReached"
    }
}