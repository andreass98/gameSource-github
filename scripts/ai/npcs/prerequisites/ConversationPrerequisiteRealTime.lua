ConversationPrerequisiteRealTime = {}
ConversationPrerequisiteRealTime.NAME = "realTime"
local ConversationPrerequisiteRealTime_mt = Class(ConversationPrerequisiteRealTime)
function ConversationPrerequisiteRealTime.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#minHour", "Real time min hour", 0, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#maxHour", "Real time max hour", 24, false)
end
function ConversationPrerequisiteRealTime.new(minHour, maxHour, customMt)
    -- upvalues: (copy) ConversationPrerequisiteRealTime_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteRealTime_mt)
    self.minHourMinutes = minHour * 60
    self.maxHourMinutes = maxHour * 60
    return self
end
function ConversationPrerequisiteRealTime:getIsValid(_, _)
    local hours = tonumber(getDate("%H"))
    return not MathUtil.getIsOutOfBounds(hours * 60 + tonumber(getDate("%M")), self.minHourMinutes, self.maxHourMinutes)
end
function ConversationPrerequisiteRealTime.createFromXML(xmlFile, key, _, _, _)
    local minHour = xmlFile:getValue(key .. "#minHour", 0)
    if minHour < 0 or minHour > 24 then
        Logging.xmlWarning(xmlFile, "minHour \'%.2f\' is out of range (0-24) for \'%s\'", minHour, key .. "#minHour")
        return nil
    end
    local maxHour = xmlFile:getValue(key .. "#maxHour", 24)
    if maxHour >= 0 and maxHour <= 24 then
        return ConversationPrerequisiteRealTime.new(minHour, maxHour)
    end
    Logging.xmlWarning(xmlFile, "maxHour \'%.2f\' is out of range (0-24) for \'%s\'", maxHour, key .. "#maxHour")
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRealTime.NAME, ConversationPrerequisiteRealTime)