Progress = {}
local Progress_mt = Class(Progress)
function Progress.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.L10N_STRING, basePath .. "#title", "Title of the progress", nil, false)
    schema:register(XMLValueType.L10N_STRING, basePath .. "#description", "Desciption of the progress", nil, false)
end
function Progress.new(title, description, customMt)
    -- upvalues: (copy) Progress_mt
    local self = setmetatable({}, customMt or Progress_mt)
    self.title = title
    self.description = description
    return self
end
function Progress:update(_)
    self.progressBar.progress = self:getProgress() or 0
    g_currentMission.hud:markSideNotificationProgressBarForDrawing(self.progressBar)
end
function Progress:activate(_, _)
    self.progressBar = g_currentMission.hud:addSideNotificationProgressBar(self.title, self.description, 0)
end
function Progress:deactivate()
    g_currentMission.hud:removeSideNotificationProgressBar(self.progressBar)
end
function Progress:getProgress()
    return nil
end