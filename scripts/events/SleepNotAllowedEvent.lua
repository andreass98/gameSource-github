SleepNotAllowedEvent = {}
local SleepNotAllowedEvent_mt = Class(SleepNotAllowedEvent, Event)
InitStaticEventClass(SleepNotAllowedEvent, "SleepNotAllowedEvent")
function SleepNotAllowedEvent.emptyNew()
    -- upvalues: (copy) SleepNotAllowedEvent_mt
    return Event.new(SleepNotAllowedEvent_mt)
end
function SleepNotAllowedEvent.new()
    return SleepNotAllowedEvent.emptyNew()
end
function SleepNotAllowedEvent:readStream(_, connection)
    assert(connection:getIsServer(), "SleepNotAllowedEvent is a server to client only event")
    self:run(connection)
end
function SleepNotAllowedEvent:writeStream(streamId, connection) end
function SleepNotAllowedEvent:run(connection)
    if g_sleepManager ~= nil then
        g_sleepManager:onSleepNotAllowed()
    end
end