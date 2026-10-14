ConversationActionResetTriggeredByType = {}
ConversationActionResetTriggeredByType.NAME = "resetNumTriggeredByType"
local ConversationActionResetTriggeredByType_mt = Class(ConversationActionResetTriggeredByType)
function ConversationActionResetTriggeredByType.registerXMLPaths(schema, basePath)
    NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end
function ConversationActionResetTriggeredByType.new(conversation, typeId, customMt)
    -- upvalues: (copy) ConversationActionResetTriggeredByType_mt
    local self = setmetatable({}, customMt or ConversationActionResetTriggeredByType_mt)
    self.conversation = conversation
    self.typeId = typeId
    return self
end
function ConversationActionResetTriggeredByType:run()
    if g_server == nil then
        return true
    else
        local npc = self.conversation:getNPC()
        if npc == nil then
            Logging.error("ConversationActionResetTriggeredByType.run: No NPC set!")
            return false
        else
            npc:resetConversationNumTriggeredByType(npc:getInteractingPlayer(), self.typeId)
            return true
        end
    end
end
function ConversationActionResetTriggeredByType.createFromXML(xmlFile, key, conversation, _, _)
    local typeId = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
    if typeId ~= nil then
        return ConversationActionResetTriggeredByType.new(conversation, typeId)
    end
    Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationActionClass(ConversationActionResetTriggeredByType.NAME, ConversationActionResetTriggeredByType)