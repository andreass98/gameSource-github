SleepRequestTimeoutEvent = {}
local SleepRequestTimeoutEvent_mt = Class(SleepRequestTimeoutEvent, Event)
InitStaticEventClass(SleepRequestTimeoutEvent, "SleepRequestTimeoutEvent")
function SleepRequestTimeoutEvent.emptyNew()
    -- upvalues: (copy) SleepRequestTimeoutEvent_mt
    return Event.new(SleepRequestTimeoutEvent_mt)
end
function SleepRequestTimeoutEvent.new()
    return SleepRequestTimeoutEvent.emptyNew()
end
function SleepRequestTimeoutEvent:readStream(_, connection)
    assert(connection:getIsServer(), "SleepRequestTimeoutEvent is a server to client only event")
    self:run(connection)
end
function SleepRequestTimeoutEvent:writeStream(streamId, connection) end
function SleepRequestTimeoutEvent:run(connection)
    if g_sleepManager ~= nil then
        g_sleepManager:onSleepRequestTimeout()
    end
end