ConversationPrerequisiteFirstContact = {}
ConversationPrerequisiteFirstContact.NAME = "firstContact"
local ConversationPrerequisiteFirstContact_mt = Class(ConversationPrerequisiteFirstContact)
function ConversationPrerequisiteFirstContact.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath, "If should be played on first contact only", nil, false)
end
function ConversationPrerequisiteFirstContact.new(conversation, customMt)
    -- upvalues: (copy) ConversationPrerequisiteFirstContact_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteFirstContact_mt)
    self.conversation = conversation
    return self
end
function ConversationPrerequisiteFirstContact:getIsValid(player, _)
    local npc = self.conversation:getNPC()
    if npc ~= nil then
        return npc:getIsFirstContact(player)
    end
    Logging.error("ConversationPrerequisiteFirstContact.run: No NPC set!")
    return false
end
function ConversationPrerequisiteFirstContact.createFromXML(_, _, conversation, _, _)
    return ConversationPrerequisiteFirstContact.new(conversation)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteFirstContact.NAME, ConversationPrerequisiteFirstContact)