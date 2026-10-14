ActionShowProgress = {}
ActionShowProgress.NAME = "showProgress"
local ActionShowProgress_mt = Class(ActionShowProgress)
function ActionShowProgress.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#isVisible", "If the progress bar is visible", nil, false)
end
function ActionShowProgress.new(isVisible, customMt)
    -- upvalues: (copy) ActionShowProgress_mt
    local self = setmetatable({}, customMt or ActionShowProgress_mt)
    self.isVisible = isVisible
    return self
end
function ActionShowProgress:run(tour, _)
    tour:setShowProgress(self.isVisible)
    return true
end
function ActionShowProgress.createFromXML(xmlFile, key, _, _)
    local isVisible = xmlFile:getValue(key .. "#isVisible")
    if isVisible == nil then
        return nil
    else
        return ActionShowProgress.new(isVisible)
    end
end
g_guidedTourManager:registerActionClass(ActionShowProgress.NAME, ActionShowProgress)