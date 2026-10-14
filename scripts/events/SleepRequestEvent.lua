SleepRequestEvent = {}
local SleepRequestEvent_mt = Class(SleepRequestEvent, Event)
InitStaticEventClass(SleepRequestEvent, "SleepRequestEvent")
function SleepRequestEvent.emptyNew()
    -- upvalues: (copy) SleepRequestEvent_mt
    return Event.new(SleepRequestEvent_mt)
end
function SleepRequestEvent.new(userId, targetTime)
    local self = SleepRequestEvent.emptyNew()
    self.userId = userId
    self.targetTime = targetTime
    return self
end
function SleepRequestEvent:readStream(streamId, connection)
    self.userId = User.streamReadUserId(streamId)
    self.targetTime = streamReadInt32(streamId)
    self:run(connection)
end
function SleepRequestEvent:writeStream(streamId, _)
    User.streamWriteUserId(streamId, self.userId)
    streamWriteInt32(streamId, self.targetTime)
end
function SleepRequestEvent:run(connection)
    if g_sleepManager ~= nil then
        if connection:getIsServer() then
            g_sleepManager:onSleepRequest(self.userId, self.targetTime)
            return
        end
        g_sleepManager:startSleepRequest(self.userId, self.targetTime)
    end
end