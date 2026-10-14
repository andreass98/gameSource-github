SleepResponseEvent = {}
local SleepResponseEvent_mt = Class(SleepResponseEvent, Event)
InitStaticEventClass(SleepResponseEvent, "SleepResponseEvent")
function SleepResponseEvent.emptyNew()
    -- upvalues: (copy) SleepResponseEvent_mt
    return Event.new(SleepResponseEvent_mt)
end
function SleepResponseEvent.new(answer)
    local self = SleepResponseEvent.emptyNew()
    self.answer = answer
    return self
end
function SleepResponseEvent:readStream(streamId, connection)
    assert(not connection:getIsServer(), "SleepResponseEvent is a client to server only event")
    self.answer = streamReadBool(streamId)
    self:run(connection)
end
function SleepResponseEvent:writeStream(streamId, _)
    streamWriteBool(streamId, self.answer)
end
function SleepResponseEvent:run(connection)
    if g_sleepManager ~= nil then
        g_sleepManager:onSleepResponse(connection, self.answer)
    end
end