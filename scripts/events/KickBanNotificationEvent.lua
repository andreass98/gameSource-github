KickBanNotificationEvent = {}
local KickBanNotificationEvent_mt = Class(KickBanNotificationEvent, Event)
InitStaticEventClass(KickBanNotificationEvent, "KickBanNotificationEvent")
function KickBanNotificationEvent.emptyNew()
    -- upvalues: (copy) KickBanNotificationEvent_mt
    return Event.new(KickBanNotificationEvent_mt, 1)
end
function KickBanNotificationEvent.new(doKick)
    local self = KickBanNotificationEvent.emptyNew()
    self.doKick = doKick
    return self
end
function KickBanNotificationEvent.readStream(_, streamId, connection)
    assert(connection:getIsServer(), "KickBanNotificationEvent is a server to client only event")
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            g_currentMission:setConnectionLostState(FSBaseMission.CONNECTION_LOST_KICKED)
            return
        end
        g_currentMission:setConnectionLostState(FSBaseMission.CONNECTION_LOST_BANNED)
    end
end
function KickBanNotificationEvent:writeStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteBool(streamId, self.doKick)
    end
end