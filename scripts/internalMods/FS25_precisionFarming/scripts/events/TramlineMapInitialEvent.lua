TramlineMapInitialEvent = {}
local TramlineMapInitialEvent_mt = Class(TramlineMapInitialEvent, Event)
InitEventClass(TramlineMapInitialEvent, "TramlineMapInitialEvent")
function TramlineMapInitialEvent.emptyNew()
    -- upvalues: (copy) TramlineMapInitialEvent_mt
    return Event.new(TramlineMapInitialEvent_mt)
end
function TramlineMapInitialEvent.new(farmlandTramlineStates)
    local self = TramlineMapInitialEvent.emptyNew()
    self.farmlandTramlineStates = farmlandTramlineStates
    return self
end
function TramlineMapInitialEvent:readStream(streamId, connection)
    self.farmlandTramlineStates = {}
    local numFarmlandsToReceive = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
    for i = 1, numFarmlandsToReceive do
        local farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
        local state = {
            ["workingWidth"] = streamReadFloat32(streamId),
            ["workDirection"] = streamReadFloat32(streamId),
            ["spacing"] = streamReadFloat32(streamId)
        }
        self.farmlandTramlineStates[farmlandId] = state
    end
    self:run(connection)
end
function TramlineMapInitialEvent:writeStream(streamId, _)
    local numFarmlandsToSend = table.size(self.farmlandTramlineStates)
    streamWriteUIntN(streamId, numFarmlandsToSend, g_farmlandManager.numberOfBits)
    for farmlandId, state in pairs(self.farmlandTramlineStates) do
        streamWriteUIntN(streamId, farmlandId, g_farmlandManager.numberOfBits)
        streamWriteFloat32(streamId, state.workingWidth)
        streamWriteFloat32(streamId, state.workDirection)
        streamWriteFloat32(streamId, state.spacing)
    end
end
function TramlineMapInitialEvent:run(_)
    if g_precisionFarming ~= nil and g_precisionFarming.tramlineMap ~= nil then
        g_precisionFarming.tramlineMap.farmlandTramlineStates = self.farmlandTramlineStates
    end
end