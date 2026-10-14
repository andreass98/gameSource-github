UserBlockEvent = {}
local UserBlockEvent_mt = Class(UserBlockEvent, Event)
InitStaticEventClass(UserBlockEvent, "UserBlockEvent")
function UserBlockEvent.emptyNew()
    -- upvalues: (copy) UserBlockEvent_mt
    return Event.new(UserBlockEvent_mt)
end
function UserBlockEvent.new(userId, isBlocked)
    local self = UserBlockEvent.emptyNew()
    self.userId = userId
    self.isBlocked = isBlocked
    return self
end
function UserBlockEvent:readStream(streamId, connection)
    self.userId = User.streamReadUserId(streamId)
    self.isBlocked = streamReadBool(streamId)
    self:run(connection)
end
function UserBlockEvent:writeStream(streamId, _)
    User.streamWriteUserId(streamId, self.userId)
    streamWriteBool(streamId, self.isBlocked)
end
function UserBlockEvent:run(connection)
    if not connection:getIsServer() then
        local fromUser = g_currentMission.userManager:getUserByConnection(connection)
        local toUser = g_currentMission.userManager:getUserByUserId(self.userId)
        if toUser ~= nil then
            toUser:setIsBlockedBy(fromUser, self.isBlocked)
        end
    end
end
function UserBlockEvent.sendEvent(userId, isBlocked, noEventSend)
    if (noEventSend == nil or noEventSend == false) and g_server == nil then
        g_client:getServerConnection():sendEvent(UserBlockEvent.new(userId, isBlocked))
    end
end