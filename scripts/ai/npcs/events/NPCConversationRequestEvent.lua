NPCConversationRequestEvent = {}
local NPCConversationRequestEvent_mt = Class(NPCConversationRequestEvent, Event)
InitStaticEventClass(NPCConversationRequestEvent, "NPCConversationRequestEvent")
function NPCConversationRequestEvent.emptyNew()
    -- upvalues: (copy) NPCConversationRequestEvent_mt
    return Event.new(NPCConversationRequestEvent_mt)
end
function NPCConversationRequestEvent.new(npc, player)
    local self = NPCConversationRequestEvent.emptyNew()
    self.npc = npc
    self.player = player
    return self
end
function NPCConversationRequestEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.npc)
        NetworkUtil.writeNodeObject(streamId, self.player)
    end
end
function NPCConversationRequestEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.npc = NetworkUtil.readNodeObject(streamId)
        self.player = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function NPCConversationRequestEvent:run(connection)
    if not connection:getIsServer() and (self.npc ~= nil and self.player ~= nil) then
        self.npc:requestConversation(self.player, connection)
    end
end