TreeTransportMissionTreeCutEvent = {}
local TreeTransportMissionTreeCutEvent_mt = Class(TreeTransportMissionTreeCutEvent, Event)
InitStaticEventClass(TreeTransportMissionTreeCutEvent, "TreeTransportMissionTreeCutEvent")
function TreeTransportMissionTreeCutEvent.emptyNew()
    -- upvalues: (copy) TreeTransportMissionTreeCutEvent_mt
    return Event.new(TreeTransportMissionTreeCutEvent_mt)
end
function TreeTransportMissionTreeCutEvent.new()
    return TreeTransportMissionTreeCutEvent.emptyNew()
end
function TreeTransportMissionTreeCutEvent:readStream(_, connection)
    self:run(connection)
end
function TreeTransportMissionTreeCutEvent:writeStream(streamId, connection) end
function TreeTransportMissionTreeCutEvent:run(connection)
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("ingameNotification_treeTransportCutWarning"))
end