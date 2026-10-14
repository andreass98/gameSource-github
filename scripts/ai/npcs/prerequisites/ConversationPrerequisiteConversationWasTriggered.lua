ConversationPrerequisiteConversationWasTriggered = {}
ConversationPrerequisiteConversationWasTriggered.NAME = "conversationWasTriggered"
local ConversationPrerequisiteConversationWasTriggered_mt = Class(ConversationPrerequisiteConversationWasTriggered)
function ConversationPrerequisiteConversationWasTriggered.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#uniqueId", "Unique id of the conversation that has to be triggered before", nil, true)
end
function ConversationPrerequisiteConversationWasTriggered.new(conversation, uniqueId, customMt)
    -- upvalues: (copy) ConversationPrerequisiteConversationWasTriggered_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteConversationWasTriggered_mt)
    self.conversation = conversation
    self.uniqueId = uniqueId
    return self
end
function ConversationPrerequisiteConversationWasTriggered:getIsValid(player, _)
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationPrerequisiteConversationWasTriggered.run: No NPC set!")
        return false
    end
    if npc:getConversationById(self.uniqueId) ~= nil then
        return npc:getWasConversationTriggered(player, self.uniqueId)
    end
    Logging.error("ConversationPrerequisiteConversationWasTriggered.run: No conversation with unique id \'%s\' defined for npc \'%s\'!", self.uniqueId, npc:getName())
    return false
end
function ConversationPrerequisiteConversationWasTriggered.createFromXML(xmlFile, key, conversation, _, _)
    local uniqueId = xmlFile:getValue(key .. "#uniqueId")
    if uniqueId ~= nil then
        return ConversationPrerequisiteConversationWasTriggered.new(conversation, uniqueId)
    end
    Logging.xmlWarning(xmlFile, "Missing \'uniqueId\' for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteConversationWasTriggered.NAME, ConversationPrerequisiteConversationWasTriggered)