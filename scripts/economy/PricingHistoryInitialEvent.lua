PricingHistoryInitialEvent = {}
local PricingHistoryInitialEvent_mt = Class(PricingHistoryInitialEvent, Event)
InitStaticEventClass(PricingHistoryInitialEvent, "PricingHistoryInitialEvent")
function PricingHistoryInitialEvent.emptyNew()
    -- upvalues: (copy) PricingHistoryInitialEvent_mt
    return Event.new(PricingHistoryInitialEvent_mt)
end
function PricingHistoryInitialEvent.new()
    return PricingHistoryInitialEvent.emptyNew()
end
function PricingHistoryInitialEvent.readStream(_, streamId, _)
    local fillTypes = g_fillTypeManager:getFillTypes()
    for _, fillType in ipairs(fillTypes) do
        if fillType.economy.sychronizeData then
            local period = 1
            for period = period, 12 do
                fillType.economy.history[period] = streamReadInt32(streamId) / 1000
            end
        end
    end
end
function PricingHistoryInitialEvent.writeStream(_, streamId, _)
    local fillTypes = g_fillTypeManager:getFillTypes()
    for _, fillType in ipairs(fillTypes) do
        if fillType.economy.sychronizeData then
            local period = 1
            for period = period, 12 do
                streamWriteInt32(streamId, fillType.economy.history[period] * 1000)
            end
        end
    end
end
function PricingHistoryInitialEvent:run(connection) end