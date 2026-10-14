ConversationActionStartByType = {}
ConversationActionStartByType.NAME = "startConversationByType"
local ConversationActionStartByType_mt = Class(ConversationActionStartByType)
function ConversationActionStartByType.registerXMLPaths(schema, basePath)
    NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end
function ConversationActionStartByType.new(conversation, typeId, customMt)
    -- upvalues: (copy) ConversationActionStartByType_mt
    local self = setmetatable({}, customMt or ConversationActionStartByType_mt)
    self.conversation = conversation
    self.typeId = typeId
    return self
end
function ConversationActionStartByType:run()
    if g_server == nil then
        return true
    end
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationActionStartByType.run: No NPC set!")
        return false
    end
    local player = npc:getInteractingPlayer()
    if player == nil then
        Logging.error("ConversationActionStartByType.run: No player set!")
        return false
    end
    local conversation = npc:getRandomConversation(player, self.typeId)
    if conversation == nil then
        return false
    end
    npc:setFollowUpConversation(conversation)
    return true
end
function ConversationActionStartByType.createFromXML(xmlFile, key, conversation, _, _)
    local typeId = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
    if typeId ~= nil then
        return ConversationActionStartByType.new(conversation, typeId)
    end
    Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationActionClass(ConversationActionStartByType.NAME, ConversationActionStartByType)