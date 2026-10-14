FarmlandStatisticsEvent = {}
local FarmlandStatisticsEvent_mt = Class(FarmlandStatisticsEvent, Event)
InitEventClass(FarmlandStatisticsEvent, "FarmlandStatisticsEvent")
function FarmlandStatisticsEvent.emptyNew()
    -- upvalues: (copy) FarmlandStatisticsEvent_mt
    return Event.new(FarmlandStatisticsEvent_mt)
end
function FarmlandStatisticsEvent.new(farmlandId)
    local self = FarmlandStatisticsEvent.emptyNew()
    self.farmlandId = farmlandId
    return self
end
function FarmlandStatisticsEvent:readStream(streamId, connection)
    self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
    local pfModule = g_precisionFarming
    if pfModule ~= nil and pfModule.farmlandStatistics ~= nil then
        pfModule.farmlandStatistics:readStatisticFromStream(self.farmlandId, streamId, connection)
    end
end
function FarmlandStatisticsEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
    local pfModule = g_precisionFarming
    if pfModule ~= nil and pfModule.farmlandStatistics ~= nil then
        pfModule.farmlandStatistics:writeStatisticToStream(self.farmlandId, streamId, connection)
    end
end