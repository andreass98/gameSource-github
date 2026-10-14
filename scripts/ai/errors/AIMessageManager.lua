AIMessageManager = {}
AIMessageType = {}
AIMessageType.OK = 1
AIMessageType.INFO = 2
AIMessageType.ERROR = 3
source("dataS/scripts/ai/errors/AIMessage.lua")
source("dataS/scripts/ai/errors/AIMessageErrorBlockedByObject.lua")
source("dataS/scripts/ai/errors/AIMessageErrorCouldNotPrepare.lua")
source("dataS/scripts/ai/errors/AIMessageErrorFieldNotOwned.lua")
source("dataS/scripts/ai/errors/AIMessageErrorFieldNotReady.lua")
source("dataS/scripts/ai/errors/AIMessageErrorGraintankIsFull.lua")
source("dataS/scripts/ai/errors/AIMessageErrorImplementWrongWay.lua")
source("dataS/scripts/ai/errors/AIMessageErrorLoadingStationDeleted.lua")
source("dataS/scripts/ai/errors/AIMessageErrorNoFieldFound.lua")
source("dataS/scripts/ai/errors/AIMessageErrorNoPalletsLoaded.lua")
source("dataS/scripts/ai/errors/AIMessageErrorNoValidFillTypeLoaded.lua")
source("dataS/scripts/ai/errors/AIMessageErrorNoVineFound.lua")
source("dataS/scripts/ai/errors/AIMessageErrorNotReachable.lua")
source("dataS/scripts/ai/errors/AIMessageErrorOutOfFill.lua")
source("dataS/scripts/ai/errors/AIMessageErrorOutOfFuel.lua")
source("dataS/scripts/ai/errors/AIMessageErrorOutOfMoney.lua")
source("dataS/scripts/ai/errors/AIMessageErrorPalletsFull.lua")
source("dataS/scripts/ai/errors/AIMessageErrorThreshingNotAllowed.lua")
source("dataS/scripts/ai/errors/AIMessageErrorUnknown.lua")
source("dataS/scripts/ai/errors/AIMessageErrorUnloadingStationDeleted.lua")
source("dataS/scripts/ai/errors/AIMessageErrorUnloadingStationFull.lua")
source("dataS/scripts/ai/errors/AIMessageErrorWrongSeason.lua")
source("dataS/scripts/ai/errors/AIMessageErrorVehicleBroken.lua")
source("dataS/scripts/ai/errors/AIMessageErrorVehicleDeleted.lua")
source("dataS/scripts/ai/errors/AIMessageErrorVineyardNotSupported.lua")
source("dataS/scripts/ai/errors/AIMessageSuccessFinishedJob.lua")
source("dataS/scripts/ai/errors/AIMessageSuccessSiloEmpty.lua")
source("dataS/scripts/ai/errors/AIMessageSuccessStoppedByUser.lua")
local AIMessageManager_mt = Class(AIMessageManager)
function AIMessageManager.new(customMt)
    -- upvalues: (copy) AIMessageManager_mt
    return setmetatable({}, customMt or AIMessageManager_mt)
end
function AIMessageManager:loadMapData(_, _, _)
    self.messages = {}
    self.nameToIndex = {}
    self.classObjectToIndex = {}
    self:registerMessage("ERROR_BLOCKED_BY_OBJECT", AIMessageErrorBlockedByObject)
    self:registerMessage("ERROR_COULD_NOT_PREPARE", AIMessageErrorCouldNotPrepare)
    self:registerMessage("ERROR_FIELD_NOT_OWNED", AIMessageErrorFieldNotOwned)
    self:registerMessage("ERROR_FIELD_NOT_READY", AIMessageErrorFieldNotReady)
    self:registerMessage("ERROR_GRAINTANK_IS_FULL", AIMessageErrorGraintankIsFull)
    self:registerMessage("ERROR_IMPLEMENT_WRONG_WAY", AIMessageErrorImplementWrongWay)
    self:registerMessage("ERROR_LOADING_STATION_DELETED", AIMessageErrorLoadingStationDeleted)
    self:registerMessage("ERROR_NO_FIELD_FOUND", AIMessageErrorNoFieldFound)
    self:registerMessage("ERROR_NO_PALLETS_LOADED", AIMessageErrorNoPalletsLoaded)
    self:registerMessage("ERROR_NO_VALID_FILLTYPE_LOADED", AIMessageErrorNoValidFillTypeLoaded)
    self:registerMessage("ERROR_NO_VINE_FOUND", AIMessageErrorNoVineFound)
    self:registerMessage("ERROR_NOT_REACHABLE", AIMessageErrorNotReachable)
    self:registerMessage("ERROR_OUT_OF_FILL", AIMessageErrorOutOfFill)
    self:registerMessage("ERROR_OUT_OF_FUEL", AIMessageErrorOutOfFuel)
    self:registerMessage("ERROR_OUT_OF_MONEY", AIMessageErrorOutOfMoney)
    self:registerMessage("ERROR_PALLETS_FULL", AIMessageErrorPalletsFull)
    self:registerMessage("ERROR_THRESHING_NOT_ALLOWED", AIMessageErrorThreshingNotAllowed)
    self:registerMessage("ERROR_UNKNOWN", AIMessageErrorUnknown)
    self:registerMessage("ERROR_UNLOADING_STATION_DELETED", AIMessageErrorUnloadingStationDeleted)
    self:registerMessage("ERROR_UNLOADINGSTATION_FULL", AIMessageErrorUnloadingStationFull)
    self:registerMessage("ERROR_WRONG_SEASON", AIMessageErrorWrongSeason)
    self:registerMessage("ERROR_VEHICLE_BROKEN", AIMessageErrorVehicleBroken)
    self:registerMessage("ERROR_VEHICLE_DELETED", AIMessageErrorVehicleDeleted)
    self:registerMessage("ERROR_VINEYARD_NOT_SUPPORTED", AIMessageErrorVineyardNotSupported)
    self:registerMessage("SUCCESS_FINISHED_JOB", AIMessageSuccessFinishedJob)
    self:registerMessage("SUCCESS_SILO_EMPTY", AIMessageSuccessSiloEmpty)
    self:registerMessage("SUCCESS_STOPPED_BY_USER", AIMessageSuccessStoppedByUser)
end
function AIMessageManager:delete()
    self.messages = {}
    self.nameToIndex = {}
    self.classObjectToIndex = {}
end
function AIMessageManager:registerMessage(name, classObject)
    if not ClassUtil.getIsValidIndexName(name) then
        Logging.warning("\'%s\' is not a valid name for a ai message!", (tostring(name)))
        return nil
    end
    local aiMessage = string.upper(name)
    if self.nameToIndex[aiMessage] ~= nil then
        Logging.warning("AI message \'%s\' already exists!", (tostring(aiMessage)))
        return nil
    end
    if classObject == nil then
        Logging.warning("AI message \'%s\' class not defined!", (tostring(aiMessage)))
        return nil
    end
    local aiMessage = {
        ["name"] = aiMessage,
        ["classObject"] = classObject
    }
    table.insert(self.messages, aiMessage)
    self.nameToIndex[aiMessage] = #self.messages
    self.classObjectToIndex[classObject] = #self.messages
    return aiMessage
end
function AIMessageManager:getMessageIndex(messageObject)
    local classObject = ClassUtil.getClassObjectByObject(messageObject)
    if classObject == nil then
        return nil
    else
        return self.classObjectToIndex[classObject]
    end
end
function AIMessageManager:createMessage(messageIndex)
    if messageIndex == nil then
        return nil
    else
        local aiMessage = self.messages[messageIndex]
        if aiMessage == nil then
            return nil
        else
            return aiMessage.classObject.new()
        end
    end
end