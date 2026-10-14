DeadwoodMissionWrongTreeEvent = {}
local DeadwoodMissionWrongTreeEvent_mt = Class(DeadwoodMissionWrongTreeEvent, Event)
InitStaticEventClass(DeadwoodMissionWrongTreeEvent, "DeadwoodMissionWrongTreeEvent")
function DeadwoodMissionWrongTreeEvent.emptyNew()
    -- upvalues: (copy) DeadwoodMissionWrongTreeEvent_mt
    return Event.new(DeadwoodMissionWrongTreeEvent_mt)
end
function DeadwoodMissionWrongTreeEvent.new()
    return DeadwoodMissionWrongTreeEvent.emptyNew()
end
function DeadwoodMissionWrongTreeEvent:readStream(_, connection)
    self:run(connection)
end
function DeadwoodMissionWrongTreeEvent:writeStream(streamId, connection) end
function DeadwoodMissionWrongTreeEvent:run(connection)
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("ingameNotification_wrongMissionTreeCutDown"))
end