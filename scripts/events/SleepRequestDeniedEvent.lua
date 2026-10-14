SleepRequestDeniedEvent = {}
local SleepRequestDeniedEvent_mt = Class(SleepRequestDeniedEvent, Event)
InitStaticEventClass(SleepRequestDeniedEvent, "SleepRequestDeniedEvent")
function SleepRequestDeniedEvent.emptyNew()
    -- upvalues: (copy) SleepRequestDeniedEvent_mt
    return Event.new(SleepRequestDeniedEvent_mt)
end
function SleepRequestDeniedEvent.new(userId)
    local self = SleepRequestDeniedEvent.emptyNew()
    self.userId = userId or 0
    return self
end
function SleepRequestDeniedEvent:readStream(streamId, connection)
    assert(connection:getIsServer(), "SleepRequestDeniedEvent is a server to client only event")
    self.userId = User.streamReadUserId(streamId)
    self:run(connection)
end
function SleepRequestDeniedEvent:writeStream(streamId, _)
    User.streamWriteUserId(streamId, self.userId)
end
function SleepRequestDeniedEvent:run(_)
    if g_sleepManager ~= nil then
        g_sleepManager:onSleepRequestDenied(self.userId)
    end
end