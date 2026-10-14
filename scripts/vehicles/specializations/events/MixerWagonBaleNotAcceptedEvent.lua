MixerWagonBaleNotAcceptedEvent = {}
local MixerWagonBaleNotAcceptedEvent_mt = Class(MixerWagonBaleNotAcceptedEvent, Event)
InitStaticEventClass(MixerWagonBaleNotAcceptedEvent, "MixerWagonBaleNotAcceptedEvent")
function MixerWagonBaleNotAcceptedEvent.emptyNew()
    -- upvalues: (copy) MixerWagonBaleNotAcceptedEvent_mt
    return Event.new(MixerWagonBaleNotAcceptedEvent_mt)
end
function MixerWagonBaleNotAcceptedEvent.new()
    return MixerWagonBaleNotAcceptedEvent.emptyNew()
end
function MixerWagonBaleNotAcceptedEvent:readStream(_, connection)
    self:run(connection)
end
function MixerWagonBaleNotAcceptedEvent:writeStream(streamId, connection) end
function MixerWagonBaleNotAcceptedEvent:run(connection)
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("warning_baleNotSupported"))
end