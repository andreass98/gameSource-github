NPCConversationFinishedEvent = {}
local NPCConversationFinishedEvent_mt = Class(NPCConversationFinishedEvent, Event)
InitStaticEventClass(NPCConversationFinishedEvent, "NPCConversationFinishedEvent")
function NPCConversationFinishedEvent.emptyNew()
    -- upvalues: (copy) NPCConversationFinishedEvent_mt
    return Event.new(NPCConversationFinishedEvent_mt)
end
function NPCConversationFinishedEvent.new(npc, hasFollowUpConversation)
    local self = NPCConversationFinishedEvent.emptyNew()
    self.npc = npc
    self.hasFollowUpConversation = hasFollowUpConversation
    return self
end
function NPCConversationFinishedEvent:writeStream(streamId, connection)
    if not connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.npc)
        streamWriteBool(streamId, self.hasFollowUpConversation)
    end
end
function NPCConversationFinishedEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.npc = NetworkUtil.readNodeObject(streamId)
        self.hasFollowUpConversation = streamReadBool(streamId)
    end
    self:run(connection)
end
function NPCConversationFinishedEvent:run(connection)
    if self.npc ~= nil and connection:getIsServer() then
        self.npc:onFinishedConversation(self.hasFollowUpConversation)
    end
end