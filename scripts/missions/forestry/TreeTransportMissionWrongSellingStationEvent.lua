TreeTransportMissionWrongSellingStationEvent = {}
local TreeTransportMissionWrongSellingStationEvent_mt = Class(TreeTransportMissionWrongSellingStationEvent, Event)
InitStaticEventClass(TreeTransportMissionWrongSellingStationEvent, "TreeTransportMissionWrongSellingStationEvent")
function TreeTransportMissionWrongSellingStationEvent.emptyNew()
    -- upvalues: (copy) TreeTransportMissionWrongSellingStationEvent_mt
    return Event.new(TreeTransportMissionWrongSellingStationEvent_mt)
end
function TreeTransportMissionWrongSellingStationEvent.new()
    return TreeTransportMissionWrongSellingStationEvent.emptyNew()
end
function TreeTransportMissionWrongSellingStationEvent:readStream(_, connection)
    self:run(connection)
end
function TreeTransportMissionWrongSellingStationEvent:writeStream(streamId, connection) end
function TreeTransportMissionWrongSellingStationEvent:run(connection)
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("ingameNotification_treeTransportWrongSellingStationWarning"))
end