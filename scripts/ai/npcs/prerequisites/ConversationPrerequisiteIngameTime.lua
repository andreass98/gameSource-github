ConversationPrerequisiteIngameTime = {}
ConversationPrerequisiteIngameTime.NAME = "ingameTime"
local ConversationPrerequisiteIngameTime_mt = Class(ConversationPrerequisiteIngameTime)
function ConversationPrerequisiteIngameTime.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#minHour", "Ingame time min hour", 0, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#maxHour", "Ingame time max hour", 24, false)
end
function ConversationPrerequisiteIngameTime.new(minHour, maxHour, customMt)
    -- upvalues: (copy) ConversationPrerequisiteIngameTime_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteIngameTime_mt)
    self.minHourMs = MathUtil.hoursToMs(minHour)
    self.maxHourMs = MathUtil.hoursToMs(maxHour)
    return self
end
function ConversationPrerequisiteIngameTime:getIsValid(_, _)
    return not MathUtil.getIsOutOfBounds(g_currentMission.environment.dayTime, self.minHourMs, self.maxHourMs)
end
function ConversationPrerequisiteIngameTime.createFromXML(xmlFile, key, _, _, _)
    local minHour = xmlFile:getValue(key .. "#minHour", 0)
    if minHour < 0 or minHour > 24 then
        Logging.xmlWarning(xmlFile, "minHour \'%.2f\' is out of range (0-24) for \'%s\'", minHour, key .. "#minHour")
        return nil
    end
    local maxHour = xmlFile:getValue(key .. "#maxHour", 24)
    if maxHour >= 0 and maxHour <= 24 then
        return ConversationPrerequisiteIngameTime.new(minHour, maxHour)
    end
    Logging.xmlWarning(xmlFile, "maxHour \'%.2f\' is out of range (0-24) for \'%s\'", maxHour, key .. "#maxHour")
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteIngameTime.NAME, ConversationPrerequisiteIngameTime)