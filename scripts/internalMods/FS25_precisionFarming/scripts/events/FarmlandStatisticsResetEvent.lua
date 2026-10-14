FarmlandStatisticsResetEvent = {}
local FarmlandStatisticsResetEvent_mt = Class(FarmlandStatisticsResetEvent, Event)
InitEventClass(FarmlandStatisticsResetEvent, "FarmlandStatisticsResetEvent")
function FarmlandStatisticsResetEvent.emptyNew()
    -- upvalues: (copy) FarmlandStatisticsResetEvent_mt
    return Event.new(FarmlandStatisticsResetEvent_mt)
end
function FarmlandStatisticsResetEvent.new(farmlandId)
    local self = FarmlandStatisticsResetEvent.emptyNew()
    self.farmlandId = farmlandId
    return self
end
function FarmlandStatisticsResetEvent:readStream(streamId, _)
    self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
    local pfModule = g_precisionFarming
    if pfModule ~= nil and pfModule.farmlandStatistics ~= nil then
        pfModule.farmlandStatistics:resetStatistic(self.farmlandId)
    end
end
function FarmlandStatisticsResetEvent:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
end