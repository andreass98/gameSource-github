SleepRequestPendingEvent = {}
local SleepRequestPendingEvent_mt = Class(SleepRequestPendingEvent, Event)
InitStaticEventClass(SleepRequestPendingEvent, "SleepRequestPendingEvent")
function SleepRequestPendingEvent.emptyNew()
    -- upvalues: (copy) SleepRequestPendingEvent_mt
    return Event.new(SleepRequestPendingEvent_mt)
end
function SleepRequestPendingEvent.new()
    return SleepRequestPendingEvent.emptyNew()
end
function SleepRequestPendingEvent:readStream(_, connection)
    assert(connection:getIsServer(), "SleepRequestPendingEvent is a server to client only event")
    self:run(connection)
end
function SleepRequestPendingEvent:writeStream(streamId, connection) end
function SleepRequestPendingEvent:run(connection)
    if g_sleepManager ~= nil then
        g_sleepManager:onSleepRequestPending()
    end
end