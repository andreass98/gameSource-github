TwisterDestructionNotificationEvent = {}
local TwisterDestructionNotificationEvent_mt = Class(TwisterDestructionNotificationEvent, Event)
InitStaticEventClass(TwisterDestructionNotificationEvent, "TwisterDestructionNotificationEvent")
function TwisterDestructionNotificationEvent.emptyNew()
    -- upvalues: (copy) TwisterDestructionNotificationEvent_mt
    return Event.new(TwisterDestructionNotificationEvent_mt)
end
function TwisterDestructionNotificationEvent.new()
    return TwisterDestructionNotificationEvent.emptyNew()
end
function TwisterDestructionNotificationEvent:readStream(_, connection)
    self:run(connection)
end
function TwisterDestructionNotificationEvent:writeStream(streamId, connection) end
function TwisterDestructionNotificationEvent:run(connection)
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("twister_destroyedNotification"))
end