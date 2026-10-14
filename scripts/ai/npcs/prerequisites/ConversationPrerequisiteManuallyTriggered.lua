ConversationPrerequisiteManuallyTriggered = {}
ConversationPrerequisiteManuallyTriggered.NAME = "manuallyTriggered"
local ConversationPrerequisiteManuallyTriggered_mt = Class(ConversationPrerequisiteManuallyTriggered)
function ConversationPrerequisiteManuallyTriggered.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath, "The conversation is manually triggered", nil, false)
end
function ConversationPrerequisiteManuallyTriggered.new(customMt)
    -- upvalues: (copy) ConversationPrerequisiteManuallyTriggered_mt
    return setmetatable({}, customMt or ConversationPrerequisiteManuallyTriggered_mt)
end
function ConversationPrerequisiteManuallyTriggered:getIsValid(player, userData)
    return false
end
function ConversationPrerequisiteManuallyTriggered.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
    return ConversationPrerequisiteManuallyTriggered.new()
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteManuallyTriggered.NAME, ConversationPrerequisiteManuallyTriggered)