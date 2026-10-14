AnimalMoveEvent = {}
AnimalMoveEvent.MOVE_SUCCESS = 0
AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION = 1
AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST = 2
AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST = 3
AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER = 4
AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED = 5
AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE = 6
AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS = 7
AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_MONEY = 2
local AnimalMoveEvent_mt = Class(AnimalMoveEvent, Event)
InitStaticEventClass(AnimalMoveEvent, "AnimalMoveEvent")
function AnimalMoveEvent.emptyNew()
    -- upvalues: (copy) AnimalMoveEvent_mt
    return Event.new(AnimalMoveEvent_mt)
end
function AnimalMoveEvent.new(sourceObject, targetObject, clusterId, numAnimals)
    local self = AnimalMoveEvent.emptyNew()
    self.sourceObject = sourceObject
    self.targetObject = targetObject
    self.clusterId = clusterId
    self.numAnimals = numAnimals
    return self
end
function AnimalMoveEvent.newServerToClient(errorCode)
    local self = AnimalMoveEvent.emptyNew()
    self.errorCode = errorCode
    return self
end
function AnimalMoveEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, 3)
    else
        self.sourceObject = NetworkUtil.readNodeObject(streamId)
        self.targetObject = NetworkUtil.readNodeObject(streamId)
        self.clusterId = streamReadInt32(streamId)
        self.numAnimals = streamReadUInt8(streamId)
    end
    self:run(connection)
end
function AnimalMoveEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.sourceObject)
        NetworkUtil.writeNodeObject(streamId, self.targetObject)
        streamWriteInt32(streamId, self.clusterId)
        streamWriteUInt8(streamId, self.numAnimals)
    else
        streamWriteUIntN(streamId, self.errorCode, 3)
    end
end
function AnimalMoveEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(AnimalMoveEvent, self.errorCode)
        return
    else
        local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
        local farmId = g_farmManager:getFarmForUniqueUserId(uniqueUserId).farmId
        local errorCode = AnimalMoveEvent.validate(self.sourceObject, self.targetObject, self.clusterId, self.numAnimals, farmId)
        if errorCode == nil then
            local cluster = self.sourceObject:getClusterById(self.clusterId)
            local newCluster = cluster:clone()
            newCluster:changeNumAnimals(self.numAnimals)
            self.targetObject:addCluster(newCluster)
            local clusterSystem = self.sourceObject:getClusterSystem()
            cluster:changeNumAnimals(-self.numAnimals)
            clusterSystem:updateNow()
            connection:sendEvent(AnimalMoveEvent.newServerToClient(AnimalMoveEvent.MOVE_SUCCESS))
        else
            connection:sendEvent(AnimalMoveEvent.newServerToClient(errorCode))
        end
    end
end
function AnimalMoveEvent.validate(sourceObject, targetObject, clusterId, numAnimals, farmId)
    if sourceObject == nil then
        return AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST
    elseif targetObject == nil then
        return AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST
    elseif g_currentMission.accessHandler:canFarmAccess(farmId, sourceObject) then
        if g_currentMission.accessHandler:canFarmAccess(farmId, targetObject) then
            local cluster = sourceObject:getClusterById(clusterId)
            if cluster == nil then
                return AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER
            elseif cluster:getNumAnimals() < numAnimals then
                return AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS
            elseif targetObject:getSupportsAnimalSubType(cluster:getSubTypeIndex()) then
                if targetObject:getNumOfFreeAnimalSlots(cluster:getSubTypeIndex()) < numAnimals then
                    return AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE
                else
                    return nil
                end
            else
                return AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED
            end
        else
            return AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION
        end
    else
        return AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION
    end
end