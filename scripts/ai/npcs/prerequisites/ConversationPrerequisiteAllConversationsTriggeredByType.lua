ConversationPrerequisiteAllConversationsTriggeredByType = {}
ConversationPrerequisiteAllConversationsTriggeredByType.NAME = "conversationAllTriggeredByType"
local ConversationPrerequisiteAllConversationsTriggeredByType_mt = Class(ConversationPrerequisiteAllConversationsTriggeredByType)
function ConversationPrerequisiteAllConversationsTriggeredByType.registerXMLPaths(schema, basePath)
    NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end
function ConversationPrerequisiteAllConversationsTriggeredByType.new(conversation, typeId, customMt)
    -- upvalues: (copy) ConversationPrerequisiteAllConversationsTriggeredByType_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteAllConversationsTriggeredByType_mt)
    self.conversation = conversation
    self.typeId = typeId
    return self
end
function ConversationPrerequisiteAllConversationsTriggeredByType:getIsValid(player, _)
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationPrerequisiteAllConversationsTriggeredByType.run: No NPC set!")
        return false
    else
        return npc:getRandomConversation(player, self.typeId) ~= nil
    end
end
function ConversationPrerequisiteAllConversationsTriggeredByType.createFromXML(xmlFile, key, conversation, _, _)
    local typeId = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
    if typeId ~= nil then
        return ConversationPrerequisiteAllConversationsTriggeredByType.new(conversation, typeId)
    end
    Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteAllConversationsTriggeredByType.NAME, ConversationPrerequisiteAllConversationsTriggeredByType)