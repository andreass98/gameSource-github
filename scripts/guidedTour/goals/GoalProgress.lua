GoalProgress = {}
GoalProgress.NAME = "progress"
local GoalProgress_mt = Class(GoalProgress)
function GoalProgress.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#progressIndex", "Id of the progress", nil, true)
    schema:register(XMLValueType.FLOAT, basePath .. "#minProgress", "Min progress (0-1)", 0.2, false)
end
function GoalProgress.new(progressIndex, minProgress, customMt)
    -- upvalues: (copy) GoalProgress_mt
    local self = setmetatable({}, customMt or GoalProgress_mt)
    self.progressIndex = progressIndex
    self.minProgress = minProgress
    return self
end
function GoalProgress:activate(_, step)
    self.progress = step:getProgressByIndex(self.progressIndex)
    if self.progress == nil then
        Logging.warning("GoalProgress.activate: Progress \'%d\' not defined!", self.progressIndex)
    end
end
function GoalProgress:deactivate()
    self.progress = nil
end
function GoalProgress:isAchieved()
    if self.progress == nil then
        return true
    end
    local progress = self.progress:getProgress()
    if progress == nil then
        return true
    end
    return self.minProgress <= progress
end
function GoalProgress.createFromXML(xmlFile, key, _, _)
    local progressIndex = xmlFile:getValue(key .. "#progressIndex")
    if progressIndex == nil then
        Logging.xmlWarning(xmlFile, "Missing \'progressIndex\' for \'%s\'", key)
        return nil
    else
        local minProgress = xmlFile:getValue(key .. "#minProgress", 0.2)
        return GoalProgress.new(progressIndex, minProgress)
    end
end
g_guidedTourManager:registerGoalClass(GoalProgress.NAME, GoalProgress)