WrongRockDestroyedEvent = {}
local WrongRockDestroyedEvent_mt = Class(WrongRockDestroyedEvent, Event)
InitStaticEventClass(WrongRockDestroyedEvent, "WrongRockDestroyedEvent")
function WrongRockDestroyedEvent.emptyNew()
    -- upvalues: (copy) WrongRockDestroyedEvent_mt
    return Event.new(WrongRockDestroyedEvent_mt)
end
function WrongRockDestroyedEvent.new()
    return WrongRockDestroyedEvent.emptyNew()
end
function WrongRockDestroyedEvent:readStream(_, connection)
    self:run(connection)
end
function WrongRockDestroyedEvent:writeStream(streamId, connection) end
function WrongRockDestroyedEvent:run(connection)
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("ingameNotification_wrongMissionRockDestroyed"))
end