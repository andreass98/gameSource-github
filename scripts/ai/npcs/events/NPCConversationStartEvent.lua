NPCConversationStartEvent = {}
local NPCConversationStartEvent_mt = Class(NPCConversationStartEvent, Event)
InitStaticEventClass(NPCConversationStartEvent, "NPCConversationStartEvent")
function NPCConversationStartEvent.emptyNew()
    -- upvalues: (copy) NPCConversationStartEvent_mt
    return Event.new(NPCConversationStartEvent_mt)
end
function NPCConversationStartEvent.new(npc, player, conversationIndex, conversationItemIndex, disabledOptionIndices, useFacialAnimation, isPhoneConversation)
    local self = NPCConversationStartEvent.emptyNew()
    self.npc = npc
    self.player = player
    self.playerNetworkId = NetworkUtil.getObjectId(player)
    self.conversationIndex = conversationIndex
    self.conversationItemIndex = conversationItemIndex
    self.disabledOptionIndices = disabledOptionIndices
    self.useFacialAnimation = useFacialAnimation
    self.isPhoneConversation = isPhoneConversation
    return self
end
function NPCConversationStartEvent:writeStream(streamId, connection)
    if not connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.npc)
        NetworkUtil.writeNodeObject(streamId, self.player)
        streamWriteUIntN(streamId, self.conversationIndex, NPC.CONVERSATION_INDEX_SEND_NUM_BITS)
        streamWriteUIntN(streamId, self.conversationItemIndex, NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS)
        streamWriteUIntN(streamId, #self.disabledOptionIndices, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
        for _, index in ipairs(self.disabledOptionIndices) do
            streamWriteUIntN(streamId, index, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
        end
        streamWriteBool(streamId, self.useFacialAnimation)
        streamWriteBool(streamId, self.isPhoneConversation)
    end
end
function NPCConversationStartEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.npc = NetworkUtil.readNodeObject(streamId)
        self.playerNetworkId = NetworkUtil.readNodeObjectId(streamId)
        self.conversationIndex = streamReadUIntN(streamId, NPC.CONVERSATION_INDEX_SEND_NUM_BITS)
        self.conversationItemIndex = streamReadUIntN(streamId, NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS)
        self.disabledOptionIndices = {}
        local numIndices = streamReadUIntN(streamId, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
        for i = 1, numIndices do
            local index = streamReadUIntN(streamId, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
            table.insert(self.disabledOptionIndices, index)
        end
        self.useFacialAnimation = streamReadBool(streamId)
        self.isPhoneConversation = streamReadBool(streamId)
    end
    self:run(connection)
end
function NPCConversationStartEvent:run(connection)
    if self.npc ~= nil and connection:getIsServer() then
        self.npc:onConversationStarted(self.playerNetworkId, self.conversationIndex, self.useFacialAnimation, self.isPhoneConversation)
        self.npc:onConversationShowItem(self.conversationItemIndex, self.disabledOptionIndices)
    end
end