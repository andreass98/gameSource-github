NPCConversationStartFailedEvent = {}
local NPCConversationStartFailedEvent_mt = Class(NPCConversationStartFailedEvent, Event)
InitStaticEventClass(NPCConversationStartFailedEvent, "NPCConversationStartFailedEvent")
function NPCConversationStartFailedEvent.emptyNew()
    -- upvalues: (copy) NPCConversationStartFailedEvent_mt
    return Event.new(NPCConversationStartFailedEvent_mt)
end
function NPCConversationStartFailedEvent.new(npc, failedState)
    local self = NPCConversationStartFailedEvent.emptyNew()
    self.npc = npc
    self.failedState = failedState
    return self
end
function NPCConversationStartFailedEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.npc)
    NPCConversationFailedState.writeStream(streamId, self.failedState)
end
function NPCConversationStartFailedEvent:readStream(streamId, connection)
    self.npc = NetworkUtil.readNodeObject(streamId)
    self.failedState = NPCConversationFailedState.readStream(streamId)
    self:run(connection)
end
function NPCConversationStartFailedEvent:run(connection)
    if connection:getIsServer() and self.npc ~= nil then
        self.npc:onFailedToStartConversation(self.failedState)
    end
end