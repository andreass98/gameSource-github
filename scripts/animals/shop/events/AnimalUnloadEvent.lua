AnimalUnloadEvent = {}
AnimalUnloadEvent.UNLOAD_SUCCESS = 0
AnimalUnloadEvent.UNLOAD_ERROR_NO_PERMISSION = 1
AnimalUnloadEvent.UNLOAD_ERROR_INVALID_CLUSTER = 2
AnimalUnloadEvent.UNLOAD_ERROR_NOT_ENOUGH_ANIMALS = 3
AnimalUnloadEvent.UNLOAD_ERROR_DOES_NOT_SUPPORT_UNLOADING = 4
AnimalUnloadEvent.UNLOAD_ERROR_TRAILER_DOES_NOT_EXIST = 5
AnimalUnloadEvent.UNLOAD_ERROR_NO_SPACE = 6
AnimalUnloadEvent.UNLOAD_ERROR_COULD_NOT_BE_LOADED = 7
AnimalUnloadEvent.UNLOAD_ERROR_RIDEABLE_LIMIT_REACHED = 8
AnimalUnloadEvent.SEND_NUM_BITS = 4
local AnimalUnloadEvent_mt = Class(AnimalUnloadEvent, Event)
InitStaticEventClass(AnimalUnloadEvent, "AnimalUnloadEvent")
function AnimalUnloadEvent.emptyNew()
    -- upvalues: (copy) AnimalUnloadEvent_mt
    return Event.new(AnimalUnloadEvent_mt)
end
function AnimalUnloadEvent.new(trailer, clusterId)
    local self = AnimalUnloadEvent.emptyNew()
    self.trailer = trailer
    self.clusterId = clusterId
    return self
end
function AnimalUnloadEvent.newServerToClient(errorCode)
    local self = AnimalUnloadEvent.emptyNew()
    self.errorCode = errorCode
    return self
end
function AnimalUnloadEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, AnimalUnloadEvent.SEND_NUM_BITS)
    else
        self.trailer = NetworkUtil.readNodeObject(streamId)
        self.clusterId = streamReadInt32(streamId)
    end
    self:run(connection)
end
function AnimalUnloadEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.trailer)
        streamWriteInt32(streamId, self.clusterId)
    else
        streamWriteUIntN(streamId, self.errorCode, AnimalUnloadEvent.SEND_NUM_BITS)
    end
end
function AnimalUnloadEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(AnimalUnloadEvent, self.errorCode)
        return
    else
        local errorCode = AnimalUnloadEvent.validate(self.trailer, self.clusterId)
        if errorCode == nil then
            local cluster = self.trailer:getClusterById(self.clusterId)
            local filename = cluster:getRidableFilename()
            local size = StoreItemUtil.getSizeValues(filename, "vehicle", 0, {})
            local x, y, z, place, _, _ = PlacementUtil.getPlace(self.trailer:getAnimalUnloadPlaces(), size, {}, true, true, true, true)
            if x == nil then
                connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_ERROR_NO_SPACE))
            else
                local farmId = self.trailer:getOwnerFarmId()
                local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
                local y = math.max(terrainHeight, y) + 0.5
                local data = VehicleLoadingData.new()
                data:setFilename(filename)
                data:setPosition(x, y, z)
                data:setRotation(0, place.rotY, 0)
                data:setPropertyState(VehiclePropertyState.OWNED)
                data:setOwnerFarmId(farmId)
                data:load(self.onLoadedRideable, self, {
                    ["cluster"] = cluster,
                    ["connection"] = connection,
                    ["trailer"] = self.trailer
                })
            end
        else
            connection:sendEvent(AnimalUnloadEvent.newServerToClient(errorCode))
            return
        end
    end
end
function AnimalUnloadEvent.onLoadedRideable(_, vehicles, vehicleLoadState, arguments)
    if vehicleLoadState == VehicleLoadingState.OK and #vehicles ~= 0 then
        local newCluster = arguments.cluster:clone()
        newCluster:changeNumAnimals(1)
        vehicles[1]:setCluster(newCluster)
        local clusterSystem = arguments.trailer:getClusterSystem()
        cluster:changeNumAnimals(-1)
        clusterSystem:updateNow()
        arguments.connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_SUCCESS))
    else
        connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_ERROR_COULD_NOT_BE_LOADED))
    end
end
function AnimalUnloadEvent.validate(trailer, clusterId)
    if trailer == nil then
        return AnimalUnloadEvent.UNLOAD_ERROR_TRAILER_DOES_NOT_EXIST
    else
        local cluster = trailer:getClusterById(clusterId)
        if cluster == nil then
            return AnimalUnloadEvent.UNLOAD_ERROR_INVALID_CLUSTER
        elseif cluster:getNumAnimals() == 0 then
            return AnimalUnloadEvent.UNLOAD_ERROR_NOT_ENOUGH_ANIMALS
        elseif cluster:getRidableFilename() == nil then
            return AnimalUnloadEvent.UNLOAD_ERROR_DOES_NOT_SUPPORT_UNLOADING
        else
            local farmId = trailer:getOwnerFarmId()
            if g_currentMission.husbandrySystem:getCanAddRideable(farmId) then
                return nil
            else
                return AnimalUnloadEvent.UNLOAD_ERROR_RIDEABLE_LIMIT_REACHED
            end
        end
    end
end