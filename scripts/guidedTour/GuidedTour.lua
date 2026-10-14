GuidedTour = {}
g_xmlManager:addCreateSchemaFunction(function()
    GuidedTour.xmlSchema = XMLSchema.new("guidedTour")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = GuidedTour.xmlSchema
    schema:register(XMLValueType.STRING, "guidedTour.class", "Class name of the guided tour controller", "GuidedTour", false)
    schema:register(XMLValueType.L10N_STRING, "guidedTour.title", "Title of the guided tour", "Tour", false)
    schema:register(XMLValueType.STRING, "guidedTour.steps.step(?).class", "Controller class of the step", "GuidedTourStep", false)
    GuidedTourStep.registerXMLPaths(schema, "guidedTour.steps.step(?)")
    local actionClasses = g_guidedTourManager:getAllActionClasses()
    for name, actionClass in pairs(actionClasses) do
        actionClass.registerXMLPaths(schema, string.format("guidedTour.finish.actions.%s(?)", name))
    end
end)
local GuidedTour_mt = Class(GuidedTour)
function GuidedTour.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".player#vehicleUniqueId", "Unique id of the controlled vehicle")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".player#position", "World position of the player")
    schema:register(XMLValueType.INT, basePath .. ".step#index", "Current guided tour step")
    schema:register(XMLValueType.BOOL, basePath .. "#showProgress", "If current progress is shown")
    GuidedTourStep.registerSavegameXMLPaths(schema, basePath .. ".step")
end
function GuidedTour.new(customMt)
    -- upvalues: (copy) GuidedTour_mt
    local self = setmetatable({}, customMt or GuidedTour_mt)
    self.baseDirectory = nil
    self.pendingStartStepIndex = nil
    self.steps = {}
    self.currentStepIndex = 0
    self.showProgress = false
    return self
end
function GuidedTour:load(xmlFilename)
    local xmlFile = XMLFile.load("guidedTour", xmlFilename, GuidedTour.xmlSchema)
    if xmlFile == nil then
        return nil
    end
    local _, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFile:getFilename())
    local customEnvironment = g_currentMission.loadingMapModName
    self.title = xmlFile:getValue("guidedTour.title", "Tour", customEnvironment)
    if not self:loadSteps(xmlFile, baseDirectory, customEnvironment) then
        Logging.xmlWarning(xmlFile, "Could not load steps")
        xmlFile:delete()
        return false
    end
    self.finishActions = GuidedTourUtil.loadActionsFromXMLFile(xmlFile, "guidedTour.finish", baseDirectory, customEnvironment, 999999)
    self.mainProgressBar = g_currentMission.hud:addSideNotificationProgressBar(self.title, nil, 0)
    xmlFile:delete()
    return true
end
function GuidedTour:loadSteps(xmlFile, baseDirectory, customEnvironment)
    for stepIndex, stepKey in xmlFile:iterator("guidedTour.steps.step") do
        local className = xmlFile:getString(stepKey .. ".class", "GuidedTourStep")
        local class = ClassUtil.getClassObject(className)
        if class == nil then
            Logging.xmlWarning(xmlFile, "GuidedTourStep controller class \'%s\' not found!", className)
            return false
        end
        local step = class.new()
        if not step:load(xmlFile, stepKey, baseDirectory, customEnvironment, stepIndex) then
            step:delete()
            Logging.xmlWarning(xmlFile, "Could not load guidedTour step \'%s\'", stepKey)
            return false
        end
        table.insert(self.steps, step)
    end
    if #self.steps ~= 0 then
        return true
    end
    Logging.xmlWarning(xmlFile, "No steps defined for guided tour")
    return false
end
function GuidedTour:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. ".step#index", self.currentStepIndex)
    xmlFile:setValue(key .. "#showProgress", self.showProgress)
end
function GuidedTour:loadFromXMLFile(xmlFile, key)
    self.showProgress = xmlFile:getValue(key .. "#showProgress", false)
    local stepIndex = xmlFile:getValue(key .. ".step#index")
    local step = self.steps[stepIndex]
    if step == nil then
        return false
    end
    if not step:loadFromXMLFile(xmlFile, key .. ".step") then
        return false
    end
    self.pendingStartStepIndex = stepIndex
    return true
end
function GuidedTour:delete()
    for _, step in ipairs(self.steps) do
        step:delete()
    end
end
function GuidedTour:update(dt)
    if self.nextStepIndex ~= nil then
        local step = self.steps[self.nextStepIndex]
        if step == nil then
            self:finish()
        else
            self:startStep(step)
        end
        self.nextStepIndex = nil
    end
    if self.currentStep ~= nil and self.currentStep.update ~= nil then
        self.currentStep:update(dt)
    end
end
function GuidedTour:setShowProgress(showProgress)
    self.showProgress = showProgress
end
function GuidedTour:draw()
    if self.currentStep ~= nil and self.currentStep.draw ~= nil then
        self.currentStep:draw()
    end
    if self.showProgress then
        g_currentMission.hud:markSideNotificationProgressBarForDrawing(self.mainProgressBar)
    end
end
function GuidedTour:start(finishCallback)
    g_messageCenter:publish(MessageType.GUIDED_TOUR_STARTED)
    g_currentMission:setTimeScaleMultiplier(0.1)
    self.finishCallback = finishCallback
    self.nextStepIndex = self.pendingStartStepIndex or 1
end
function GuidedTour:finish()
    g_messageCenter:publish(MessageType.GUIDED_TOUR_FINISHED)
    self:cleanup()
    self.finishCallback(true)
end
function GuidedTour:cancel()
    self:cleanup()
    if self.finishCallback ~= nil then
        self.finishCallback(false)
    end
end
function GuidedTour:cleanup()
    g_currentMission:setTimeScaleMultiplier(1)
    g_currentMission.introductionHelpSystem:hideAll()
    if self.currentStep ~= nil then
        self.currentStep:finish()
    end
    if self.finishActions ~= nil then
        for _, action in ipairs(self.finishActions) do
            action:run(self, nil)
        end
    end
    if self.npcSpots ~= nil then
        for _, action in pairs(self.npcSpots) do
            g_npcManager:removeSpot(action)
        end
        self.npcSpots = nil
    end
    self.currentStep = nil
    self.currentStepIndex = nil
    g_currentMission.hud:removeSideNotificationProgressBar(self.mainProgressBar)
end
function GuidedTour:startStep(step)
    self.currentStep = step
    self.currentStepIndex = step.index
    step:start(self, function()
        -- upvalues: (copy) self, (copy) step
        self.currentStep = nil
        self.nextStepIndex = step.index + 1
    end)
    self.mainProgressBar.progress = self.currentStepIndex / #self.steps
    if self.currentStep ~= nil then
        self.mainProgressBar.text = self.currentStep.taskDescription
    end
    g_messageCenter:publish(MessageType.GUIDED_TOUR_CHANGED)
end
function GuidedTour:getCanAbort()
    return true
end
function GuidedTour:getPassedStepsInfo()
    local stepInfos = {}
    local i = 1
    for i = i, self.currentStepIndex do
        local stepInfo = self.steps[i]:getInfo()
        if stepInfo ~= nil then
            table.insert(stepInfos, stepInfo)
        end
    end
    return stepInfos
end
function GuidedTour:getNPCSpot(npcName)
    local npc = g_npcManager:getNPCByName(npcName)
    if npc == nil then
        return nil
    end
    if self.npcSpots == nil then
        self.npcSpots = {}
    end
    local spot = self.npcSpots[npcName]
    if spot ~= nil then
        return spot
    end
    local spotName = string.format("GuidedTourSpot_%s", npcName)
    local spot = g_npcManager:getSpotByUniqueId(spotName)
    if spot == nil then
        spot = NPCSpot.create(spotName, npc, 0, 0, 0, 0, 0, 0, true)
    end
    self.npcSpots[npcName] = spot
    g_npcManager:addSpot(spot)
    return spot
end