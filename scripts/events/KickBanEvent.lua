KickBanEvent = {}
local KickBanEvent_mt = Class(KickBanEvent, Event)
InitStaticEventClass(KickBanEvent, "KickBanEvent")
function KickBanEvent.emptyNew()
    -- upvalues: (copy) KickBanEvent_mt
    return Event.new(KickBanEvent_mt)
end
function KickBanEvent.new(doKick, userId)
    local self = KickBanEvent.emptyNew()
    self.doKick = doKick
    self.userId = userId
    return self
end
function KickBanEvent:readStream(streamId, connection)
    assert(g_currentMission:getIsServer(), "KickBanEvent is a client to server only event")
    self.doKick = streamReadBool(streamId)
    self.userId = User.streamReadUserId(streamId)
    self:run(connection)
end
function KickBanEvent:writeStream(streamId, _)
    streamWriteBool(streamId, self.doKick)
    User.streamWriteUserId(streamId, self.userId)
end
function KickBanEvent:run(connection)
    if connection:getIsServer() then
        printError("Error: KickBanEvent is a client to server only event")
        return
    elseif self.userId == g_currentMission:getServerUserId() then
        print("The server cannot be kicked or banned")
        return
    elseif g_currentMission.userManager:getIsConnectionMasterUser(connection) then
        local user = g_currentMission.userManager:getUserByUserId(self.userId)
        if user == nil then
            print("User(" .. tostring(self.userId) .. ") not found")
            return
        elseif self.doKick then
            g_currentMission:kickUser(user)
        else
            g_currentMission:banUser(user)
        end
    else
        print("Connection is not a master user")
        return
    end
end