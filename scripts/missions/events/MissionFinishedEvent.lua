MissionFinishedEvent = {}
local MissionFinishedEvent_mt = Class(MissionFinishedEvent, Event)
InitStaticEventClass(MissionFinishedEvent, "MissionFinishedEvent")
function MissionFinishedEvent.emptyNew()
    -- upvalues: (copy) MissionFinishedEvent_mt
    return Event.new(MissionFinishedEvent_mt)
end
function MissionFinishedEvent.new(mission, finishState, stealingCost)
    local self = MissionFinishedEvent.emptyNew()
    self.mission = mission
    self.finishState = finishState
    self.stealingCost = stealingCost
    return self
end
function MissionFinishedEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.mission)
    MissionFinishState.writeStream(streamId, self.finishState)
    streamWriteFloat32(streamId, self.stealingCost)
end
function MissionFinishedEvent:readStream(streamId, connection)
    self.mission = NetworkUtil.readNodeObject(streamId)
    self.finishState = MissionFinishState.readStream(streamId)
    self.stealingCost = streamReadFloat32(streamId)
    self:run(connection)
end
function MissionFinishedEvent:run(connection)
    if connection:getIsServer() then
        self.mission.stealingCost = self.stealingCost
        self.mission:finish(self.finishState)
    end
end