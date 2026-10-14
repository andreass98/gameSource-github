ConversationPrerequisiteAvailableByType = {}
ConversationPrerequisiteAvailableByType.NAME = "conversationAvailableByType"
local ConversationPrerequisiteAvailableByType_mt = Class(ConversationPrerequisiteAvailableByType)
function ConversationPrerequisiteAvailableByType.registerXMLPaths(schema, basePath)
    NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end
function ConversationPrerequisiteAvailableByType.new(conversation, typeId, customMt)
    -- upvalues: (copy) ConversationPrerequisiteAvailableByType_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteAvailableByType_mt)
    self.conversation = conversation
    self.typeId = typeId
    return self
end
function ConversationPrerequisiteAvailableByType:getIsValid(player, _)
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationPrerequisiteAvailableByType.run: No NPC set!")
        return false
    else
        return npc:getRandomConversation(player, self.typeId) ~= nil
    end
end
function ConversationPrerequisiteAvailableByType.createFromXML(xmlFile, key, conversation, _, _)
    local typeId = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
    if typeId ~= nil then
        return ConversationPrerequisiteAvailableByType.new(conversation, typeId)
    end
    Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteAvailableByType.NAME, ConversationPrerequisiteAvailableByType)