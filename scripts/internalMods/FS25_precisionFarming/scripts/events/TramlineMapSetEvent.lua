TramlineMapSetEvent = {}
local TramlineMapSetEvent_mt = Class(TramlineMapSetEvent, Event)
InitEventClass(TramlineMapSetEvent, "TramlineMapSetEvent")
function TramlineMapSetEvent.emptyNew()
    -- upvalues: (copy) TramlineMapSetEvent_mt
    return Event.new(TramlineMapSetEvent_mt)
end
function TramlineMapSetEvent.new(farmlandId, workingWidth, workDirection, spacing, enabled, clearFruit)
    local self = TramlineMapSetEvent.emptyNew()
    self.farmlandId = farmlandId
    self.workingWidth = workingWidth
    self.workDirection = workDirection
    self.spacing = spacing
    self.enabled = enabled
    self.clearFruit = clearFruit
    return self
end
function TramlineMapSetEvent:readStream(streamId, connection)
    self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
    self.workingWidth = streamReadFloat32(streamId)
    self.workDirection = streamReadFloat32(streamId)
    self.spacing = streamReadFloat32(streamId)
    self.enabled = streamReadBool(streamId)
    self.clearFruit = streamReadBool(streamId)
    self:run(connection)
end
function TramlineMapSetEvent:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
    streamWriteFloat32(streamId, self.workingWidth)
    streamWriteFloat32(streamId, self.workDirection)
    streamWriteFloat32(streamId, self.spacing)
    streamWriteBool(streamId, self.enabled)
    streamWriteBool(streamId, self.clearFruit)
end
function TramlineMapSetEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, nil)
    end
    if g_precisionFarming ~= nil and g_precisionFarming.tramlineMap ~= nil then
        g_precisionFarming.tramlineMap:setFarmlandTramlines(self.farmlandId, self.workingWidth, self.workDirection, self.spacing, self.enabled, self.clearFruit, true)
    end
end
function TramlineMapSetEvent.sendEvent(farmlandId, workingWidth, workDirection, spacing, enabled, clearFruit, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TramlineMapSetEvent.new(farmlandId, workingWidth, workDirection, spacing, enabled, clearFruit), nil, nil, nil)
            return
        end
        g_client:getServerConnection():sendEvent(TramlineMapSetEvent.new(farmlandId, workingWidth, workDirection, spacing, enabled, clearFruit))
    end
end