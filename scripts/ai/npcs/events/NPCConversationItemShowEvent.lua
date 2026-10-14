NPCConversationItemShowEvent = {}
local NPCConversationItemShowEvent_mt = Class(NPCConversationItemShowEvent, Event)
InitStaticEventClass(NPCConversationItemShowEvent, "NPCConversationItemShowEvent")
function NPCConversationItemShowEvent.emptyNew()
    -- upvalues: (copy) NPCConversationItemShowEvent_mt
    return Event.new(NPCConversationItemShowEvent_mt)
end
function NPCConversationItemShowEvent.new(npc, conversationItemIndex, disabledOptionIndices)
    local self = NPCConversationItemShowEvent.emptyNew()
    self.npc = npc
    self.conversationItemIndex = conversationItemIndex
    self.disabledOptionIndices = disabledOptionIndices
    return self
end
function NPCConversationItemShowEvent:writeStream(streamId, connection)
    if not connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.npc)
        streamWriteUIntN(streamId, self.conversationItemIndex, NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS)
        streamWriteUIntN(streamId, #self.disabledOptionIndices, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
        for _, index in ipairs(self.disabledOptionIndices) do
            streamWriteUIntN(streamId, index, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
        end
    end
end
function NPCConversationItemShowEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.npc = NetworkUtil.readNodeObject(streamId)
        self.conversationItemIndex = streamReadUIntN(streamId, NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS)
        self.disabledOptionIndices = {}
        local numIndices = streamReadUIntN(streamId, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
        for i = 1, numIndices do
            local index = streamReadUIntN(streamId, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
            table.insert(self.disabledOptionIndices, index)
        end
    end
    self:run(connection)
end
function NPCConversationItemShowEvent:run(connection)
    if connection:getIsServer() and self.npc ~= nil then
        self.npc:onConversationShowItem(self.conversationItemIndex, self.disabledOptionIndices)
    end
end