ConversationPrerequisiteRealDate = {}
ConversationPrerequisiteRealDate.NAME = "realDate"
local ConversationPrerequisiteRealDate_mt = Class(ConversationPrerequisiteRealDate)
function ConversationPrerequisiteRealDate.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#year", "Real date year", 0, false)
    schema:register(XMLValueType.INT, basePath .. "#month", "Real date month", 0, false)
    schema:register(XMLValueType.INT, basePath .. "#day", "Real date day", 0, false)
end
function ConversationPrerequisiteRealDate.new(year, month, day, customMt)
    -- upvalues: (copy) ConversationPrerequisiteRealDate_mt
    local self = setmetatable({}, customMt or ConversationPrerequisiteRealDate_mt)
    self.year = year
    self.month = month
    self.day = day
    return self
end
function ConversationPrerequisiteRealDate:getIsValid(_, _)
    local yearCur, monthCur, dayCur = string.match(getDate("%Y/%m/%d"), "(%d+)/(%d+)/(%d+)")
    local yearCur = tonumber(yearCur)
    local monthCur = tonumber(monthCur)
    local dayCur = tonumber(dayCur)
    if self.year > 0 and self.year ~= yearCur then
        return false
    elseif self.month > 0 and self.month ~= monthCur then
        return false
    else
        return self.day <= 0 or self.day == dayCur
    end
end
function ConversationPrerequisiteRealDate.createFromXML(xmlFile, key, _, _, _)
    local year = xmlFile:getValue(key .. "#year", 0)
    if year < 0 then
        Logging.xmlWarning(xmlFile, "\'year\' out of range [0: every year, 2024-XXXX] for \'%s\'", year)
        return nil
    end
    local month = xmlFile:getValue(key .. "#month", 0)
    if month < 0 or month > 12 then
        Logging.xmlWarning(xmlFile, "\'month\' out of range [0: every month, 1-12] for \'%s\'", month)
        return nil
    end
    local day = xmlFile:getValue(key .. "#day", 0)
    if day >= 0 and day <= 31 then
        return ConversationPrerequisiteRealDate.new(year, month, day)
    end
    Logging.xmlWarning(xmlFile, "\'day\' out of range [0: every day, 1-31] for \'%s\'", month)
    return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRealDate.NAME, ConversationPrerequisiteRealDate)