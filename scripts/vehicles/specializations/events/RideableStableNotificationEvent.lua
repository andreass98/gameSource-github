RideableStableNotificationEvent = {}
local RideableStableNotificationEvent_mt = Class(RideableStableNotificationEvent, Event)
InitStaticEventClass(RideableStableNotificationEvent, "RideableStableNotificationEvent")
function RideableStableNotificationEvent.emptyNew()
    -- upvalues: (copy) RideableStableNotificationEvent_mt
    return Event.new(RideableStableNotificationEvent_mt)
end
function RideableStableNotificationEvent.new(isInStable, name)
    local self = RideableStableNotificationEvent.emptyNew()
    self.isInStable = isInStable
    self.name = name
    return self
end
function RideableStableNotificationEvent:readStream(streamId, connection)
    self.isInStable = streamReadBool(streamId)
    self.name = streamReadString(streamId)
    self:run(connection)
end
function RideableStableNotificationEvent:writeStream(streamId, _)
    streamWriteBool(streamId, self.isInStable)
    streamWriteString(streamId, self.name)
end
function RideableStableNotificationEvent:run(_)
    if self.isInStable then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("ingameNotification_horseInStable"), self.name))
    else
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("ingameNotification_horseNotInStable"), self.name))
    end
end