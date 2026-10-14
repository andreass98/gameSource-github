StartSleepStateEvent = {}
local StartSleepStateEvent_mt = Class(StartSleepStateEvent, Event)
InitStaticEventClass(StartSleepStateEvent, "StartSleepStateEvent")
function StartSleepStateEvent.emptyNew()
    -- upvalues: (copy) StartSleepStateEvent_mt
    return Event.new(StartSleepStateEvent_mt)
end
function StartSleepStateEvent.new(targetTime)
    local self = StartSleepStateEvent.emptyNew()
    self.targetTime = targetTime
    return self
end
function StartSleepStateEvent:readStream(streamId, connection)
    assert(connection:getIsServer(), "StartSleepStateEvent is a server to client only event")
    self.targetTime = streamReadInt32(streamId)
    self:run(connection)
end
function StartSleepStateEvent:writeStream(streamId, _)
    streamWriteInt32(streamId, self.targetTime)
end
function StartSleepStateEvent:run(_)
    if g_sleepManager ~= nil then
        g_sleepManager:startSleep(self.targetTime)
    end
end