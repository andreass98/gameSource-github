AIJobSkipTaskEvent = {}
local AIJobSkipTaskEvent_mt = Class(AIJobSkipTaskEvent, Event)
InitStaticEventClass(AIJobSkipTaskEvent, "AIJobSkipTaskEvent")
function AIJobSkipTaskEvent.emptyNew()
    -- upvalues: (copy) AIJobSkipTaskEvent_mt
    return Event.new(AIJobSkipTaskEvent_mt)
end
function AIJobSkipTaskEvent.new(job)
    local self = AIJobSkipTaskEvent.emptyNew()
    self.job = job
    return self
end
function AIJobSkipTaskEvent:readStream(streamId, connection)
    local jobId = streamReadInt32(streamId)
    self.job = g_currentMission.aiSystem:getJobById(jobId)
    self:run(connection)
end
function AIJobSkipTaskEvent:writeStream(streamId, _)
    streamWriteInt32(streamId, self.job.jobId)
end
function AIJobSkipTaskEvent:run(connection)
    assert(not connection:getIsServer(), "AIJobSkipTaskEvent is client to server only")
    g_currentMission.aiSystem:skipCurrentTaskInternal(self.job)
    if Platform.isMobile then
        g_messageCenter:publish(MessageType.AI_TASK_SKIPPED)
    end
end