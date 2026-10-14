ConversationPrerequisiteOwnedAllFarmlands = {}
ConversationPrerequisiteOwnedAllFarmlands.NAME = "ownedAllFarmlands"
local ConversationPrerequisiteOwnedAllFarmlands_mt = Class(ConversationPrerequisiteOwnedAllFarmlands)
function ConversationPrerequisiteOwnedAllFarmlands.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath, "If should be played if all farmlands are owned", nil, false)
end
function ConversationPrerequisiteOwnedAllFarmlands.new(customMt)
    -- upvalues: (copy) ConversationPrerequisiteOwnedAllFarmlands_mt
    return setmetatable({}, customMt or ConversationPrerequisiteOwnedAllFarmlands_mt)
end
function ConversationPrerequisiteOwnedAllFarmlands.getIsValid(_, player, _)
    if player == nil then
        return false
    end
    local farm = g_farmManager:getFarmByUserId(player.userId)
    if farm == nil then
        return false
    end
    return g_farmlandManager:getNumOwnedFarmlandIdsByFarmId(farm.farmid) == #g_farmlandManager:getFarmlands()
end
function ConversationPrerequisiteOwnedAllFarmlands.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
    return ConversationPrerequisiteOwnedAllFarmlands.new()
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteOwnedAllFarmlands.NAME, ConversationPrerequisiteOwnedAllFarmlands)