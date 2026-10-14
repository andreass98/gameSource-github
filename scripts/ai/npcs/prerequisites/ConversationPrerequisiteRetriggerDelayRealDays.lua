ConversationPrerequisiteRetriggerDelayRealDays = {}
ConversationPrerequisiteRetriggerDelayRealDays.NAME = "retriggerDelayRealDays"
local ConversationPrerequisiteRetriggerDelayRealDays_mt = Class(ConversationPrerequisiteRetriggerDelayRealDays)
function ConversationPrerequisiteRetriggerDelayRealDays.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#minDays", "Min number of real days since last occurrence", 0, false)
end
function ConversationPrerequisiteRetriggerDelayRealDays.new(minRealDays, customMt)
    -- upvalues: (copy) ConversationPrerequisiteRetriggerDelayRealDays_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteRetriggerDelayRealDays_mt)
    self.minRealDaysSeconds = minRealDays * 24 * 60 * 60
    return self
end
function ConversationPrerequisiteRetriggerDelayRealDays:getIsValid(_, userData)
    if userData ~= nil and userData.lastTriggedDate ~= nil then
        local yearCur, monthCur, dayCur = string.match(getDate("%Y/%m/%d"), "(%d+)/(%d+)/(%d+)")
        local year = tonumber(yearCur)
        local year = tonumber(monthCur)
        local year = tonumber(dayCur)
        local year, month, day = string.match(userData.lastTriggedDate, "(%d+)/(%d+)/(%d+)")
        local diffSeconds = tonumber(year)
        local diffSeconds = tonumber(month)
        local diffSeconds = tonumber(day)
        if diffSeconds then
            if math.abs((getDateDiffSeconds(diffSeconds, diffSeconds, diffSeconds, 0, 0, 0, year, year, year, 0, 0, 0))) < self.minRealDaysSeconds then
                return false
            end
        end
    end
    return true
end
function ConversationPrerequisiteRetriggerDelayRealDays.createFromXML(xmlFile, key, _, _, _)
    local minRealDays = xmlFile:getValue(key .. "#minDays", 0)
    if minRealDays >= 0 then
        return ConversationPrerequisiteRetriggerDelayRealDays.new(minRealDays)
    end
    Logging.xmlWarning(xmlFile, "Min number of real days may not be smaller than 0 for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRetriggerDelayRealDays.NAME, ConversationPrerequisiteRetriggerDelayRealDays)