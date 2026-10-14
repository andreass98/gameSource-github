ConversationPrerequisiteNumTriggered = {}
ConversationPrerequisiteNumTriggered.NAME = "numTriggered"
local ConversationPrerequisiteNumTriggered_mt = Class(ConversationPrerequisiteNumTriggered)
function ConversationPrerequisiteNumTriggered.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#max", "Max number of triggers", 1, false)
end
function ConversationPrerequisiteNumTriggered.new(conversation, maxNumTriggers, customMt)
    -- upvalues: (copy) ConversationPrerequisiteNumTriggered_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteNumTriggered_mt)
    self.conversation = conversation
    self.maxNumTriggers = maxNumTriggers
    return self
end
function ConversationPrerequisiteNumTriggered:getIsValid(player, _)
    local npc = self.conversation:getNPC()
    if npc == nil then
        Logging.error("ConversationPrerequisiteNumTriggered.run: No NPC set!")
        return false
    else
        local numTriggered = npc:getConversationNumTriggered(player, self.conversation:getUniqueId())
        return numTriggered == nil or numTriggered < self.maxNumTriggers
    end
end
function ConversationPrerequisiteNumTriggered.createFromXML(xmlFile, key, conversation, _, _)
    local max = xmlFile:getValue(key .. "#max", 1)
    if max >= 0 then
        return ConversationPrerequisiteNumTriggered.new(conversation, max)
    end
    Logging.xmlWarning(xmlFile, "\'max\' may not be negative for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumTriggered.NAME, ConversationPrerequisiteNumTriggered)