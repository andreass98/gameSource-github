AITaskStartEvent = {}
local AITaskStartEvent_mt = Class(AITaskStartEvent, Event)
InitStaticEventClass(AITaskStartEvent, "AITaskStartEvent")
function AITaskStartEvent.emptyNew()
    -- upvalues: (copy) AITaskStartEvent_mt
    return Event.new(AITaskStartEvent_mt)
end
function AITaskStartEvent.new(job, task)
    local self = AITaskStartEvent.emptyNew()
    self.job = job
    self.task = task
    return self
end
function AITaskStartEvent:readStream(streamId, connection)
    local jobId = streamReadInt32(streamId)
    local taskId = streamReadUInt8(streamId)
    self.job = g_currentMission.aiSystem:getJobById(jobId)
    if self.job ~= nil then
        self.task = self.job:getTaskByIndex(taskId)
    end
    self:run(connection)
end
function AITaskStartEvent:writeStream(streamId, _)
    streamWriteInt32(streamId, self.job.jobId)
    streamWriteUInt8(streamId, self.task.taskIndex)
end
function AITaskStartEvent:run(_)
    if self.job == nil then
        Logging.devWarning("AITaskStartEvent: Job not defined")
    else
        self.job:startTask(self.task)
    end
end