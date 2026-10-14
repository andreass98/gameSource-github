ConversationPrerequisiteRetriggerDelayIngameDays = {}
ConversationPrerequisiteRetriggerDelayIngameDays.NAME = "retriggerDelayIngameDays"
local ConversationPrerequisiteRetriggerDelayIngameDays_mt = Class(ConversationPrerequisiteRetriggerDelayIngameDays)
function ConversationPrerequisiteRetriggerDelayIngameDays.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#minDays", "Min number of ingame days since last occurrence", 0, false)
end
function ConversationPrerequisiteRetriggerDelayIngameDays.new(minIngameDays, customMt)
    -- upvalues: (copy) ConversationPrerequisiteRetriggerDelayIngameDays_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteRetriggerDelayIngameDays_mt)
    self.minIngameDays = minIngameDays
    return self
end
function ConversationPrerequisiteRetriggerDelayIngameDays:getIsValid(_, userData)
    if userData ~= nil and userData.lastTriggedMonotonicDay ~= nil then
        local lastMonotonicDay = userData.lastTriggedMonotonicDay
        if lastMonotonicDay ~= nil then
            return g_currentMission.environment.currentMonotonicDay - lastMonotonicDay > self.minIngameDays
        end
    end
    return true
end
function ConversationPrerequisiteRetriggerDelayIngameDays.createFromXML(xmlFile, key, _, _, _)
    local minIngameDays = xmlFile:getValue(key .. "#minDays", 0)
    if minIngameDays >= 0 then
        return ConversationPrerequisiteRetriggerDelayIngameDays.new(minIngameDays)
    end
    Logging.xmlWarning(xmlFile, "Min number of ingame days may not be smaller than 0 for \'%s\'", key)
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRetriggerDelayIngameDays.NAME, ConversationPrerequisiteRetriggerDelayIngameDays)