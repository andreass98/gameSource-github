PricingHistoryEvent = {}
local PricingHistoryEvent_mt = Class(PricingHistoryEvent, Event)
InitStaticEventClass(PricingHistoryEvent, "PricingHistoryEvent")
function PricingHistoryEvent.emptyNew()
    -- upvalues: (copy) PricingHistoryEvent_mt
    return Event.new(PricingHistoryEvent_mt)
end
function PricingHistoryEvent.new(period)
    local self = PricingHistoryEvent.emptyNew()
    self.period = period
    return self
end
function PricingHistoryEvent:readStream(streamId, _)
    self.period = SeasonPeriod.readStream(streamId)
    local fillTypes = g_fillTypeManager:getFillTypes()
    for _, fillType in ipairs(fillTypes) do
        if fillType.economy.sychronizeData then
            fillType.economy.history[self.period] = streamReadInt32(streamId) / 1000
        end
    end
end
function PricingHistoryEvent:writeStream(streamId, _)
    SeasonPeriod.writeStream(streamId, self.period)
    local fillTypes = g_fillTypeManager:getFillTypes()
    for _, fillType in ipairs(fillTypes) do
        if fillType.economy.sychronizeData then
            streamWriteInt32(streamId, fillType.economy.history[self.period] * 1000)
        end
    end
end
function PricingHistoryEvent:run(connection) end