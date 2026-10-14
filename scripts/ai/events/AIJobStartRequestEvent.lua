AIJobStartRequestEvent = {}
local AIJobStartRequestEvent_mt = Class(AIJobStartRequestEvent, Event)
InitStaticEventClass(AIJobStartRequestEvent, "AIJobStartRequestEvent")
function AIJobStartRequestEvent.emptyNew()
    -- upvalues: (copy) AIJobStartRequestEvent_mt
    return Event.new(AIJobStartRequestEvent_mt)
end
function AIJobStartRequestEvent.new(job, startFarmId)
    local self = AIJobStartRequestEvent.emptyNew()
    self.job = job
    self.startFarmId = startFarmId
    return self
end
function AIJobStartRequestEvent.newServerToClient(state, jobTypeIndex)
    local self = AIJobStartRequestEvent.emptyNew()
    self.state = state
    self.jobTypeIndex = jobTypeIndex
    return self
end
function AIJobStartRequestEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.state = streamReadUInt8(streamId)
        self.jobTypeIndex = streamReadUInt16(streamId)
    else
        self.startFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
        local jobTypeIndex = streamReadUInt16(streamId)
        self.job = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)
        self.job:readStream(streamId, connection)
    end
    self:run(connection)
end
function AIJobStartRequestEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        streamWriteUIntN(streamId, self.startFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
        local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
        streamWriteUInt16(streamId, jobTypeIndex)
        self.job:writeStream(streamId, connection)
    else
        streamWriteUInt8(streamId, self.state)
        streamWriteUInt16(streamId, self.jobTypeIndex)
    end
end
function AIJobStartRequestEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(AIJobStartRequestEvent, self.state, self.jobTypeIndex)
        return
    else
        local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
        local startable, state = self.job:getIsStartable(connection)
        if startable then
            connection:sendEvent(AIJobStartRequestEvent.newServerToClient(0, jobTypeIndex))
            g_currentMission.aiSystem:startJob(self.job, self.startFarmId)
        else
            connection:sendEvent(AIJobStartRequestEvent.newServerToClient(state, jobTypeIndex))
        end
    end
end