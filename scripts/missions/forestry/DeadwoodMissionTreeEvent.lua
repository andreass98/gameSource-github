DeadwoodMissionTreeEvent = {}
local DeadwoodMissionTreeEvent_mt = Class(DeadwoodMissionTreeEvent, Event)
InitStaticEventClass(DeadwoodMissionTreeEvent, "DeadwoodMissionTreeEvent")
function DeadwoodMissionTreeEvent.emptyNew()
    -- upvalues: (copy) DeadwoodMissionTreeEvent_mt
    return Event.new(DeadwoodMissionTreeEvent_mt)
end
function DeadwoodMissionTreeEvent.new(mission)
    local self = DeadwoodMissionTreeEvent.emptyNew()
    self.mission = mission
    return self
end
function DeadwoodMissionTreeEvent:readStream(streamId, _)
    self.mission = NetworkUtil.readNodeObject(streamId)
    self.mission:readDeadTreesStream(streamId)
    self.mission:raiseActive()
end
function DeadwoodMissionTreeEvent:writeStream(streamId, connection)
    assert(not connection:getIsServer(), "DeadwoodMissionTreeEvent is a server to client event")
    NetworkUtil.writeNodeObject(streamId, self.mission)
    self.mission:writeDeadTreesStream(streamId)
end