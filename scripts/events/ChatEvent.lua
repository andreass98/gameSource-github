ChatEvent = {}
local ChatEvent_mt = Class(ChatEvent, Event)
InitStaticEventClass(ChatEvent, "ChatEvent")
function ChatEvent.emptyNew()
    -- upvalues: (copy) ChatEvent_mt
    return Event.new(ChatEvent_mt, NetworkNode.CHANNEL_CHAT)
end
function ChatEvent.new(msg, sender, farmId, userId)
    local self = ChatEvent.emptyNew()
    assert(msg ~= nil and sender ~= nil, "ChatEvent msg and sender not valid")
    self.msg = filterText(msg, false, false)
    self.sender = sender
    self.farmId = farmId
    self.userId = userId
    return self
end
function ChatEvent:readStream(streamId, connection)
    self.msg = streamReadString(streamId)
    self.sender = streamReadString(streamId)
    self.userId = User.streamReadUserId(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self:run(connection)
end
function ChatEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.msg)
    streamWriteString(streamId, self.sender)
    User.streamWriteUserId(streamId, self.userId)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end
function ChatEvent:run(connection)
    g_currentMission:addChatMessage(self.sender, self.msg, self.farmId, self.userId)
    if not connection:getIsServer() then
        local fromUser = g_currentMission.userManager:getUserByUserId(self.userId)
        for _, toUser in ipairs(g_currentMission.userManager:getUsers()) do
            if connection ~= toUser:getConnection() and not (toUser:getIsBlockedBy(fromUser) or toUser:getConnection():getIsLocal()) then
                toUser:getConnection():sendEvent(self, false)
            end
        end
    end
end