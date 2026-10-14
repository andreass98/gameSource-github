NPCConversationAnswerEvent = {}
local NPCConversationAnswerEvent_mt = Class(NPCConversationAnswerEvent, Event)
InitStaticEventClass(NPCConversationAnswerEvent, "NPCConversationAnswerEvent")
function NPCConversationAnswerEvent.emptyNew()
    -- upvalues: (copy) NPCConversationAnswerEvent_mt
    return Event.new(NPCConversationAnswerEvent_mt)
end
function NPCConversationAnswerEvent.new(npc, conversationItemIndex, optionIndex)
    local self = NPCConversationAnswerEvent.emptyNew()
    self.npc = npc
    self.conversationItemIndex = conversationItemIndex
    self.optionIndex = optionIndex
    return self
end
function NPCConversationAnswerEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.npc)
        streamWriteUIntN(streamId, self.conversationItemIndex, NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS)
        if streamWriteBool(streamId, self.optionIndex ~= nil) then
            streamWriteUIntN(streamId, self.optionIndex, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
        end
    end
end
function NPCConversationAnswerEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.npc = NetworkUtil.readNodeObject(streamId)
        self.conversationItemIndex = streamReadUIntN(streamId, NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS)
        if streamReadBool(streamId) then
            self.optionIndex = streamReadUIntN(streamId, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
        end
    end
    self:run(connection)
end
function NPCConversationAnswerEvent:run(connection)
    if not connection:getIsServer() and self.npc ~= nil then
        self.npc:processAnswer(connection, self.conversationItemIndex, self.optionIndex)
    end
end