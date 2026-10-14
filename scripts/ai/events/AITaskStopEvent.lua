AITaskStopEvent = {}
local AITaskStopEvent_mt = Class(AITaskStopEvent, Event)
InitStaticEventClass(AITaskStopEvent, "AITaskStopEvent")
function AITaskStopEvent.emptyNew()
    -- upvalues: (copy) AITaskStopEvent_mt
    return Event.new(AITaskStopEvent_mt)
end
function AITaskStopEvent.new(job, task, wasJobStopped)
    local self = AITaskStopEvent.emptyNew()
    self.job = job
    self.wasJobStopped = wasJobStopped
    self.task = task
    return self
end
function AITaskStopEvent:readStream(streamId, connection)
    local jobId = streamReadInt32(streamId)
    local taskId = streamReadUInt8(streamId)
    local wasJobStopped = streamReadBool(streamId)
    self.job = g_currentMission.aiSystem:getJobById(jobId)
    if self.job ~= nil then
        self.task = self.job:getTaskByIndex(taskId)
    end
    self.wasJobStopped = wasJobStopped
    self:run(connection)
end
function AITaskStopEvent:writeStream(streamId, _)
    streamWriteInt32(streamId, self.job.jobId)
    streamWriteUInt8(streamId, self.task.taskIndex)
    streamWriteBool(streamId, self.wasJobStopped)
end
function AITaskStopEvent:run(_)
    if self.job == nil then
        Logging.devWarning("AITaskStopEvent: Job not defined")
    else
        self.job:stopTask(self.task, self.wasJobStopped)
    end
end