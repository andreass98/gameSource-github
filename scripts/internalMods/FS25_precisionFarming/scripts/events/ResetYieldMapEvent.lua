ResetYieldMapEvent = {}
local ResetYieldMapEvent_mt = Class(ResetYieldMapEvent, Event)
InitEventClass(ResetYieldMapEvent, "ResetYieldMapEvent")
function ResetYieldMapEvent.emptyNew()
    -- upvalues: (copy) ResetYieldMapEvent_mt
    return Event.new(ResetYieldMapEvent_mt)
end
function ResetYieldMapEvent.new(farmlandId)
    local self = ResetYieldMapEvent.emptyNew()
    self.farmlandId = farmlandId
    return self
end
function ResetYieldMapEvent:readStream(streamId, connection)
    self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
    self:run(connection)
end
function ResetYieldMapEvent:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
end
function ResetYieldMapEvent:run(connection)
    if not connection:getIsServer() and (g_precisionFarming ~= nil and g_precisionFarming.yieldMap ~= nil) then
        g_precisionFarming.yieldMap:resetFarmlandYieldArea(self.farmlandId)
        g_precisionFarming:updatePrecisionFarmingOverlays()
    end
end