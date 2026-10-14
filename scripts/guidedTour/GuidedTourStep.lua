GuidedTourStep = {}
local GuidedTourStep_mt = Class(GuidedTourStep)
function GuidedTourStep.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.L10N_STRING, basePath .. ".taskDescription#text", "The description text of the current task", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#showProgress", "Hide or show the current tour progress bar", nil, false)
    schema:register(XMLValueType.L10N_STRING, basePath .. ".info#text", "The info text of the current task", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".info.input(?)#name", "Name of the input action", nil, false)
    schema:register(XMLValueType.STRING, basePath .. ".info.input(?)#name2", "Name of the second input action", nil, false)
    schema:register(XMLValueType.L10N_STRING, basePath .. ".info.input(?)#text", "Text of the action", nil, false)
    local actionClasses = g_guidedTourManager:getAllActionClasses()
    for name, actionClass in pairs(actionClasses) do
        actionClass.registerXMLPaths(schema, string.format("%s.actions.%s(?)", basePath, name))
    end
    local goalClasses = g_guidedTourManager:getAllGoalClasses()
    for actionClass, goalClass in pairs(goalClasses) do
        goalClass.registerXMLPaths(schema, string.format("%s.goals.%s(?)", basePath, actionClass))
    end
    local progressClasses = g_guidedTourManager:getAllProgressClasses()
    for goalClass, progressClass in pairs(progressClasses) do
        progressClass.registerXMLPaths(schema, string.format("%s.progresses.%s(?)", basePath, goalClass))
    end
end
function GuidedTourStep.registerSavegameXMLPaths(schema, basePath)
    local actionClasses = g_guidedTourManager:getAllActionClasses()
    for name, actionClass in pairs(actionClasses) do
        if actionClass.registerSavegameXMLPaths ~= nil then
            actionClass.registerSavegameXMLPaths(schema, string.format("%s.actions.%s(?)", basePath, name))
        end
    end
    local goalClasses = g_guidedTourManager:getAllGoalClasses()
    for actionClass, goalClass in pairs(goalClasses) do
        if goalClass.registerSavegameXMLPaths ~= nil then
            goalClass.registerSavegameXMLPaths(schema, string.format("%s.goals.%s(?)", basePath, actionClass))
        end
    end
    local progressClasses = g_guidedTourManager:getAllProgressClasses()
    for goalClass, progressClass in pairs(progressClasses) do
        if progressClass.registerSavegameXMLPaths ~= nil then
            progressClass.registerXMLPaths(schema, string.format("%s.progresses.%s(?)", basePath, goalClass))
        end
    end
end
function GuidedTourStep.new(customMt)
    -- upvalues: (copy) GuidedTourStep_mt
    local self = setmetatable({}, customMt or GuidedTourStep_mt)
    self.loadedFromSavegame = nil
    self.taskDescription = nil
    self.info = nil
    return self
end
function GuidedTourStep:load(xmlFile, key, baseDirectory, customEnvironment, stepIndex)
    self.index = stepIndex
    self.showProgress = xmlFile:getValue(key .. "#showProgress", true)
    self.taskDescription = xmlFile:getValue(key .. ".taskDescription#text", nil, customEnvironment, false)
    self.actions = GuidedTourUtil.loadActionsFromXMLFile(xmlFile, key, baseDirectory, customEnvironment, stepIndex)
    self.goals = GuidedTourUtil.loadGoalsFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
    self.progresses = GuidedTourUtil.loadProgressesFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
    local infoKey = key .. ".info"
    if xmlFile:hasProperty(infoKey) then
        self.info = {}
        self.info.text = xmlFile:getValue(infoKey .. "#text")
        for _, inputKey in xmlFile:iterator(infoKey .. ".input") do
            if self.info.inputs == nil then
                self.info.inputs = {}
            end
            local actionName = xmlFile:getValue(inputKey .. "#name")
            if actionName ~= nil then
                local input = {
                    ["actionName"] = actionName,
                    ["actionName2"] = xmlFile:getValue(inputKey .. "#name2"),
                    ["text"] = xmlFile:getValue(inputKey .. "#text", nil, customEnvironment, false)
                }
                table.insert(self.info.inputs, input)
            end
        end
    end
    return true
end
function GuidedTourStep:saveToXMLFile(xmlFile, key)
    if self.actions ~= nil then
        for _, action in ipairs(self.actions) do
            if action.saveToXMLFile ~= nil then
                action:saveToXMLFile(xmlFile, string.format("%s.actions.%s", key, action.NAME))
            end
        end
    end
    if self.progresses ~= nil then
        for _, action in ipairs(self.progresses) do
            if action.saveToXMLFile ~= nil then
                action:saveToXMLFile(xmlFile, string.format("%s.progresses.%s", key, action.NAME))
            end
        end
    end
    if self.goals ~= nil then
        for _, action in ipairs(self.goals) do
            if action.saveToXMLFile ~= nil then
                action:saveToXMLFile(xmlFile, string.format("%s.goals.%s", key, action.NAME))
            end
        end
    end
end
function GuidedTourStep:loadFromXMLFile(xmlFile, key)
    if self.actions ~= nil then
        for _, action in ipairs(self.actions) do
            if action.loadFromXMLFile ~= nil and not action:loadFromXMLFile(xmlFile, string.format("%s.actions.%s", key, action.NAME)) then
                return false
            end
        end
    end
    if self.progresses ~= nil then
        for _, action in ipairs(self.progresses) do
            if action.loadFromXMLFile ~= nil and not action:loadFromXMLFile(xmlFile, string.format("%s.progresses.%s", key, action.NAME)) then
                return false
            end
        end
    end
    if self.goals ~= nil then
        for _, action in ipairs(self.goals) do
            if action.loadFromXMLFile ~= nil and not action:loadFromXMLFile(xmlFile, string.format("%s.goals.%s", key, action.NAME)) then
                return false
            end
        end
    end
    self.loadedFromSavegame = true
    return true
end
function GuidedTourStep:delete()
    if self.actions ~= nil then
        for _, action in ipairs(self.actions) do
            if action.delete ~= nil then
                action:delete()
            end
        end
    end
    if self.progresses ~= nil then
        for _, action in ipairs(self.progresses) do
            if action.delete ~= nil then
                action:delete()
            end
        end
    end
    if self.goals ~= nil then
        for _, action in ipairs(self.goals) do
            if action.delete ~= nil then
                action:delete()
            end
        end
    end
end
function GuidedTourStep:update(dt)
    if self.actions ~= nil then
        for _, action in ipairs(self.actions) do
            if action.update ~= nil then
                action:update(dt)
            end
        end
    end
    if self.progresses ~= nil then
        for _, action in ipairs(self.progresses) do
            if action.update ~= nil then
                action:update(dt)
            end
        end
    end
    if self.goals ~= nil then
        for _, action in ipairs(self.goals) do
            if action.update ~= nil then
                action:update(dt)
            end
        end
    end
    self:checkIfDone()
end
function GuidedTourStep:draw() end
function GuidedTourStep:start(tour, callback)
    self.isRunning = true
    self.callback = callback
    if self.actions ~= nil then
        for _, action in ipairs(self.actions) do
            action:run(tour, self)
        end
    end
    if self.progresses ~= nil then
        local hud = g_currentMission.hud
        for action, progress in ipairs(self.progresses) do
            if progress.activate ~= nil then
                progress:activate(tour, self)
            end
        end
    end
    if self.goals ~= nil then
        for _, action in ipairs(self.goals) do
            if action.activate ~= nil then
                action:activate(tour, self)
            end
        end
    end
end
function GuidedTourStep:finish()
    self.isRunning = false
    if self.progresses ~= nil then
        for _, progress in ipairs(self.progresses) do
            if progress.deactivate ~= nil then
                progress:deactivate()
            end
        end
    end
    if self.goals ~= nil then
        for _, progress in ipairs(self.goals) do
            if progress.deactivate ~= nil then
                progress:deactivate()
            end
        end
    end
end
function GuidedTourStep:checkIfDone()
    if self.goals ~= nil then
        for _, goal in ipairs(self.goals) do
            if not goal:isAchieved() then
                return
            end
        end
    end
    self:finish()
    self.callback()
end
function GuidedTourStep:getProgressByIndex(progressIndex)
    if self.progresses == nil then
        return nil
    else
        return self.progresses[progressIndex]
    end
end
function GuidedTourStep:getInfo()
    return self.info
end