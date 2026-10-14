AnimalLoadEvent = {}
AnimalLoadEvent.LOAD_SUCCESS = 0
AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION = 1
AnimalLoadEvent.LOAD_ERROR_RIDEABLE_DOES_NOT_EXIST = 2
AnimalLoadEvent.LOAD_ERROR_TRAILER_DOES_NOT_EXIST = 3
AnimalLoadEvent.LOAD_ERROR_INVALID_CLUSTER = 4
AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_ANIMALS = 5
AnimalLoadEvent.LOAD_ERROR_ANIMAL_NOT_SUPPORTED = 6
AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_SPACE = 7
local AnimalLoadEvent_mt = Class(AnimalLoadEvent, Event)
InitStaticEventClass(AnimalLoadEvent, "AnimalLoadEvent")
function AnimalLoadEvent.emptyNew()
    -- upvalues: (copy) AnimalLoadEvent_mt
    return Event.new(AnimalLoadEvent_mt)
end
function AnimalLoadEvent.new(trailer, rideable)
    local self = AnimalLoadEvent.emptyNew()
    self.trailer = trailer
    self.rideable = rideable
    return self
end
function AnimalLoadEvent.newServerToClient(errorCode)
    local self = AnimalLoadEvent.emptyNew()
    self.errorCode = errorCode
    return self
end
function AnimalLoadEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, 3)
    else
        self.trailer = NetworkUtil.readNodeObject(streamId)
        self.rideable = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function AnimalLoadEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.trailer)
        NetworkUtil.writeNodeObject(streamId, self.rideable)
    else
        streamWriteUIntN(streamId, self.errorCode, 3)
    end
end
function AnimalLoadEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(AnimalLoadEvent, self.errorCode)
        return
    else
        local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
        local farmId = g_farmManager:getFarmForUniqueUserId(uniqueUserId).farmId
        local errorCode = AnimalLoadEvent.validate(self.trailer, self.rideable, farmId)
        if errorCode == nil then
            local cluster = self.rideable:getCluster()
            self.trailer:addCluster(cluster)
            self.rideable:delete()
            connection:sendEvent(AnimalLoadEvent.newServerToClient(AnimalLoadEvent.LOAD_SUCCESS))
        else
            connection:sendEvent(AnimalLoadEvent.newServerToClient(errorCode))
        end
    end
end
function AnimalLoadEvent.validate(trailer, rideable, farmId)
    if trailer == nil then
        return AnimalLoadEvent.LOAD_ERROR_TRAILER_DOES_NOT_EXIST
    elseif rideable == nil then
        return AnimalLoadEvent.LOAD_ERROR_RIDEABLE_DOES_NOT_EXIST
    elseif g_currentMission.accessHandler:canFarmAccess(farmId, trailer) then
        if g_currentMission.accessHandler:canFarmAccess(farmId, rideable) then
            local cluster = rideable:getCluster()
            if cluster == nil then
                return AnimalLoadEvent.LOAD_ERROR_INVALID_CLUSTER
            elseif cluster:getNumAnimals() == 0 then
                return AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_ANIMALS
            elseif trailer:getSupportsAnimalSubType(cluster:getSubTypeIndex()) then
                if trailer:getNumOfFreeAnimalSlots(cluster:getSubTypeIndex()) == 0 then
                    return AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_SPACE
                else
                    return nil
                end
            else
                return AnimalLoadEvent.LOAD_ERROR_ANIMAL_NOT_SUPPORTED
            end
        else
            return AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION
        end
    else
        return AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION
    end
end