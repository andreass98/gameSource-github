ConversationPrerequisiteIngameDaysPlayed = {}
ConversationPrerequisiteIngameDaysPlayed.NAME = "ingameDaysPlayed"
local ConversationPrerequisiteIngameDaysPlayed_mt = Class(ConversationPrerequisiteIngameDaysPlayed)
function ConversationPrerequisiteIngameDaysPlayed.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#min", "Min number of ingame days played", 0, false)
    schema:register(XMLValueType.INT, basePath .. "#max", "Max number of ingame days played", 9999999999, false)
end
function ConversationPrerequisiteIngameDaysPlayed.new(minIngamePlayedDays, maxIngamePlayedDays, customMt)
    -- upvalues: (copy) ConversationPrerequisiteIngameDaysPlayed_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteIngameDaysPlayed_mt)
    self.minIngamePlayedDays = minIngamePlayedDays
    self.maxIngamePlayedDays = maxIngamePlayedDays
    return self
end
function ConversationPrerequisiteIngameDaysPlayed:getIsValid(_, _)
    local daysPlayed = g_currentMission.environment:getDaysPlayed()
    return not MathUtil.getIsOutOfBounds(daysPlayed, self.minIngamePlayedDays, self.maxIngamePlayedDays)
end
function ConversationPrerequisiteIngameDaysPlayed.createFromXML(xmlFile, key, _, _, _)
    local minIngamePlayedDays = xmlFile:getValue(key .. "#min", 0)
    local maxIngamePlayedDays = xmlFile:getValue(key .. "#max", math.huge)
    return ConversationPrerequisiteIngameDaysPlayed.new(minIngamePlayedDays, maxIngamePlayedDays)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteIngameDaysPlayed.NAME, ConversationPrerequisiteIngameDaysPlayed)