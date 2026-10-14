ConversationPrerequisiteSeasonPeriod = {}
ConversationPrerequisiteSeasonPeriod.NAME = "seasonPeriod"
local ConversationPrerequisiteSeasonPeriod_mt = Class(ConversationPrerequisiteSeasonPeriod)
function ConversationPrerequisiteSeasonPeriod.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#min", "Name of the min season period", "EARLY_SPRING", false)
    schema:register(XMLValueType.STRING, basePath .. "#max", "Name of the max season period", "LATE_WINTER", false)
end
function ConversationPrerequisiteSeasonPeriod.new(minSeasonPeriod, maxSeasonPeriod, customMt)
    -- upvalues: (copy) ConversationPrerequisiteSeasonPeriod_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteSeasonPeriod_mt)
    self.minSeasonPeriod = minSeasonPeriod
    self.maxSeasonPeriod = maxSeasonPeriod
    return self
end
function ConversationPrerequisiteSeasonPeriod:getIsValid(_, _)
    return not MathUtil.getIsOutOfBounds(g_currentMission.environment.currentPeriod, self.minSeasonPeriod, self.maxSeasonPeriod)
end
function ConversationPrerequisiteSeasonPeriod.createFromXML(xmlFile, key, _, _, _)
    local minSeasonPeriodStr = xmlFile:getValue(key .. "#min", "EARLY_SPRING")
    local minSeasonPeriod = SeasonPeriod.getByName(minSeasonPeriodStr)
    if minSeasonPeriod == nil then
        Logging.xmlWarning(xmlFile, "SeasonPeriod min-value \'%s\' is not defined for \'%s\'. Set to EARLY_SPRING.", minSeasonPeriodStr, key .. "#min")
        return nil
    end
    local maxSeasonPeriodStr = xmlFile:getValue(key .. "#max", "LATE_WINTER")
    local maxSeasonPeriod = SeasonPeriod.getByName(maxSeasonPeriodStr)
    if maxSeasonPeriod ~= nil then
        return ConversationPrerequisiteSeasonPeriod.new(minSeasonPeriod, maxSeasonPeriod)
    end
    Logging.xmlWarning(xmlFile, "SeasonPeriod max-value \'%s\' is not defined for \'%s\'. Set to LATE_WINTER.", maxSeasonPeriodStr, key .. "#max")
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteSeasonPeriod.NAME, ConversationPrerequisiteSeasonPeriod)