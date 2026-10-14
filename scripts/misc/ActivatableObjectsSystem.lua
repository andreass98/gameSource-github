ActivatableObjectsSystem = {}
local ActivatableObjectsSystem_mt = Class(ActivatableObjectsSystem)
function ActivatableObjectsSystem.new(mission, customMt)
    -- upvalues: (copy) ActivatableObjectsSystem_mt
    local self = setmetatable({}, customMt or ActivatableObjectsSystem_mt)
    self.mission = mission
    self.objects = {}
    self.currentActivatableObject = nil
    self.inputContext = nil
    self.actionEventId = nil
    return self
end
function ActivatableObjectsSystem:activate(context)
    self.inputContext = context
    self.isActive = true
    self:updateObjects()
end
function ActivatableObjectsSystem:deactivate(context)
    self:removeInput(context)
    if self.currentActivatableObject ~= nil and self.currentActivatableObject.deactivate ~= nil then
        self.currentActivatableObject:deactivate()
    end
    self.currentActivatableObject = nil
    self.isActive = false
end
function ActivatableObjectsSystem:setPosition(x, y, z)
    self.posX = x
    self.posY = y
    self.posZ = z
end
function ActivatableObjectsSystem:setDirection(dirX, dirY, dirZ)
    self.dirX = dirX
    self.dirY = dirY
    self.dirZ = dirZ
end
function ActivatableObjectsSystem:update(dt)
    if self.isActive then
        self:updateObjects(dt)
    end
end
function ActivatableObjectsSystem:draw()
    setTextBold(false)
    renderText(0.02, 0.6, 0.015, "ActivatableObjectsSystem")
    renderText(0.02, 0.58, 0.015, string.format(" isActive: %s", self.isActive))
    renderText(0.02, 0.56, 0.015, string.format(" pos: %.2f %.2f %.2f", self.posX, self.posY, self.posZ))
    renderText(0.02, 0.54, 0.015, string.format(" dir: %.2f %.2f %.2f", self.dirX, self.dirY, self.dirZ))
    local index = 0
    for _, object in pairs(self.objects) do
        local isActivatable = true
        if object.getIsActivatable ~= nil then
            isActivatable = object:getIsActivatable(self.dirX, self.dirY, self.dirZ)
        end
        local hasAccess = true
        if object.getHasAccess ~= nil then
            hasAccess = object:getHasAccess(g_currentMission:getFarmId())
        end
        local distance = object.getDistance ~= nil and self.posX ~= nil and object:getDistance(self.posX, self.posY, self.posZ) or math.huge
        local text = object.activateText
        if string.isNilOrWhitespace(text) and object.animatedObject then
            text = string.format("%s \'%s\'|\'%s\'", object.animatedObject.saveId, object.animatedObject.controls.posActionText, object.animatedObject.controls.negActionText)
        end
        local isActive = self.currentActivatableObject == object
        if isActive then
            setTextColor(0, 0.5, 0, 1)
        end
        renderText(0.02, 0.52 - index * 0.02, 0.015, string.format("    Object: %s (isActivatable: %s, hasAccess: %s, distance: %.2fm, farmId: %s)%s", text, isActivatable, hasAccess, distance, object.animatedObject and object.animatedObject.ownerFarmId or "?", isActive and " Active" or ""))
        setTextColor(1, 1, 1, 1)
        index = index + 1
    end
end
function ActivatableObjectsSystem:updateObjects(dt)
    local nearestObject = nil
    local nearestDistance = math.huge
    local farmId = g_currentMission:getFarmId()
    for _, object in pairs(self.objects) do
        if (object.getIsActivatable == nil or object:getIsActivatable(self.dirX, self.dirY, self.dirZ)) and (object.getHasAccess == nil or object:getHasAccess(farmId)) then
            local distance = math.huge
            if object.getDistance ~= nil and self.posX ~= nil then
                distance = object:getDistance(self.posX, self.posY, self.posZ)
            end
            if nearestObject == nil or distance < nearestDistance then
                nearestDistance = distance
                nearestObject = object
            end
        end
    end
    if nearestObject ~= self.currentActivatableObject then
        self:removeInput(self.inputContext)
        if self.currentActivatableObject ~= nil and self.currentActivatableObject.deactivate ~= nil then
            self.currentActivatableObject:deactivate()
        end
        self.currentActivatableObject = nearestObject
        if nearestObject ~= nil then
            if nearestObject.activate ~= nil then
                nearestObject:activate()
            end
            self:registerInput(self.inputContext)
        end
    end
    if nearestObject ~= nil then
        if self.actionEventId ~= nil then
            g_inputBinding:setActionEventText(self.actionEventId, nearestObject.activateText)
        end
        if nearestObject.update ~= nil then
            nearestObject:update(dt)
        end
    end
end
function ActivatableObjectsSystem:removeInput(inputContext)
    if inputContext ~= nil then
        g_inputBinding:beginActionEventsModification(inputContext)
    end
    if self.currentActivatableObject ~= nil and self.currentActivatableObject.removeCustomInput ~= nil then
        self.currentActivatableObject:removeCustomInput()
    end
    if self.actionEventId ~= nil then
        g_inputBinding:removeActionEvent(self.actionEventId)
        self.actionEventId = nil
    end
    if inputContext ~= nil then
        g_inputBinding:endActionEventsModification()
    end
end
function ActivatableObjectsSystem:registerInput(inputContext)
    local currentObject = self.currentActivatableObject
    if currentObject ~= nil then
        if inputContext ~= nil then
            g_inputBinding:beginActionEventsModification(inputContext)
        end
        if currentObject.registerCustomInput == nil or Platform.isMobile then
            local _, actionEventId = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_OBJECT, self, self.onActivateObjectInput, false, true, false, true, nil, true, false)
            g_inputBinding:setActionEventText(actionEventId, currentObject.activateText)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            g_inputBinding:setActionEventTextVisibility(actionEventId, true)
            self.actionEventId = actionEventId
        else
            currentObject:registerCustomInput(inputContext)
        end
        if inputContext ~= nil then
            g_inputBinding:endActionEventsModification()
        end
    end
end
function ActivatableObjectsSystem:getActivatable()
    return self.currentActivatableObject
end
function ActivatableObjectsSystem:addActivatable(object)
    if object.activateText == nil then
        Logging.error("Given activatable object has no activateText")
        printCallstack()
    elseif self.objects[object] == nil then
        self.objects[object] = object
    end
end
function ActivatableObjectsSystem:removeActivatable(object)
    if object ~= nil then
        self.objects[object] = nil
        if object == self.currentActivatableObject then
            if object.deactivate ~= nil then
                object:deactivate()
            end
            self:removeInput(self.inputContext)
            self.currentActivatableObject = nil
        end
    end
end
function ActivatableObjectsSystem:onActivateObjectInput(_, _, _, _)
    if self.currentActivatableObject ~= nil then
        self.currentActivatableObject:run()
    end
end
function ActivatableObjectsSystem.consoleCommandDebugState()
    if g_currentMission:getHasDrawable(g_currentMission.activatableObjectsSystem) then
        g_currentMission:removeDrawable(g_currentMission.activatableObjectsSystem)
        Logging.info("ActivatableObjectsSystem Debug Disabled")
    else
        g_currentMission:addDrawable(g_currentMission.activatableObjectsSystem)
        Logging.info("ActivatableObjectsSystem Debug Enabled")
    end
end
addConsoleCommand("gsActivatableObjectsSystemToggleDebug", "Toggle ActivatableObjectsSystem Debug", "consoleCommandDebugState", ActivatableObjectsSystem)