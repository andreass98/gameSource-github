ClientStartMissionEvent = {}
local ClientStartMissionEvent_mt = Class(ClientStartMissionEvent, Event)
InitStaticEventClass(ClientStartMissionEvent, "ClientStartMissionEvent")
function ClientStartMissionEvent.emptyNew()
    -- upvalues: (copy) ClientStartMissionEvent_mt
    return Event.new(ClientStartMissionEvent_mt)
end
function ClientStartMissionEvent.new(userId)
    return ClientStartMissionEvent.emptyNew()
end
function ClientStartMissionEvent:writeStream(streamId, connection) end
function ClientStartMissionEvent:readStream(_, connection)
    self:run(connection)
end
function ClientStartMissionEvent.run(_, connection)
    assert(not connection:getIsServer(), "ClientStartMissionEvent is a client to server event only!")
    local user = g_currentMission.userManager:getUserByConnection(connection)
    user:setState(FSBaseMission.USER_STATE_INGAME)
    g_messageCenter:publish(MessageType.ON_CLIENT_START_MISSION, user)
end