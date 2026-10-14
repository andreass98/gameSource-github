ConversationPrerequisiteNumOwnedFarmlands = {}
ConversationPrerequisiteNumOwnedFarmlands.NAME = "numOwnedFarmlands"
local ConversationPrerequisiteNumOwnedFarmlands_mt = Class(ConversationPrerequisiteNumOwnedFarmlands)
function ConversationPrerequisiteNumOwnedFarmlands.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#min", "Min number of owned farmlands", 0, false)
    schema:register(XMLValueType.INT, basePath .. "#max", "Max number of owned farmlands", 9999999999, false)
end
function ConversationPrerequisiteNumOwnedFarmlands.new(minNumOwnedFarmlands, maxNumOwnedFarmlands, customMt)
    -- upvalues: (copy) ConversationPrerequisiteNumOwnedFarmlands_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteNumOwnedFarmlands_mt)
    self.minNumOwnedFarmlands = minNumOwnedFarmlands
    self.maxNumOwnedFarmlands = maxNumOwnedFarmlands
    return self
end
function ConversationPrerequisiteNumOwnedFarmlands:getIsValid(player, _)
    if player == nil then
        return false
    end
    local farm = g_farmManager:getFarmByUserId(player.userId)
    if farm == nil then
        return false
    end
    local numFields = g_farmlandManager:getNumOwnedFarmlandIdsByFarmId(farm.farmId)
    return not MathUtil.getIsOutOfBounds(numFields, self.minNumOwnedFarmlands, self.maxNumOwnedFarmlands)
end
function ConversationPrerequisiteNumOwnedFarmlands.createFromXML(xmlFile, key, _, _, _)
    local minNumOwnedFarmlands = xmlFile:getValue(key .. "#min", 0)
    local maxNumOwnedFarmlands = xmlFile:getValue(key .. "#max", math.huge)
    return ConversationPrerequisiteNumOwnedFarmlands.new(minNumOwnedFarmlands, maxNumOwnedFarmlands)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumOwnedFarmlands.NAME, ConversationPrerequisiteNumOwnedFarmlands)