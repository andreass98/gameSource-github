VehicleActionController = {}
local VehicleActionController_mt = Class(VehicleActionController)
source("dataS/scripts/vehicles/VehicleActionControllerAction.lua")
function VehicleActionController.new(vehicle, customMt)
    -- upvalues: (copy) VehicleActionController_mt
    local self = setmetatable({}, customMt or VehicleActionController_mt)
    self.vehicle = vehicle
    self.actions = {}
    self.actionsByPrio = {}
    self.sortedActions = {}
    self.sortedActionsRev = {}
    self.currentSequenceActions = {}
    self.actionEvents = {}
    self.lastDirection = -1
    self.pendingControllerReactivation = false
    self.loadedNumActions = 0
    return self
end
function VehicleActionController:saveToXMLFile(xmlFile, key, _)
    if #self.actions > 0 then
        xmlFile:setValue(key .. "#lastDirection", self.lastDirection)
        xmlFile:setValue(key .. "#numActions", #self.actions)
        local i = 0
        for _, action in ipairs(self.actions) do
            if action:getIsSaved() then
                local actionKey = string.format("%s.action(%d)", key, i)
                xmlFile:setValue(actionKey .. "#name", action.name)
                xmlFile:setValue(actionKey .. "#identifier", action.identifier)
                xmlFile:setValue(actionKey .. "#lastDirection", action:getLastDirection())
                i = i + 1
            end
        end
    end
end
function VehicleActionController:load(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        self.lastDirection = savegame.xmlFile:getValue(savegame.key .. ".actionController#lastDirection", self.lastDirection)
        self.loadedNumActions = savegame.xmlFile:getValue(savegame.key .. ".actionController#numActions", 0)
        self.loadTime = g_time
        local needsToApply = false
        self.loadedActions = {}
        local i = 0
        while true do
            local baseKey = string.format("%s.actionController.action(%d)", savegame.key, i)
            if not savegame.xmlFile:hasProperty(baseKey) then
                break
            end
            local action = {
                ["name"] = savegame.xmlFile:getValue(baseKey .. "#name"),
                ["identifier"] = savegame.xmlFile:getValue(baseKey .. "#identifier"),
                ["lastDirection"] = savegame.xmlFile:getValue(baseKey .. "#lastDirection")
            }
            table.insert(self.loadedActions, action)
            i = i + 1
        end
        if not needsToApply then
            self.loadedNumActions = 0
            self.loadedActions = {}
        end
    end
end
function VehicleActionController:registerAction(name, inputAction, prio)
    local action = VehicleActionControllerAction.new(self, name, inputAction, prio)
    self:addAction(action)
    return action
end
function VehicleActionController:addAction(action)
    table.insert(self.actions, action)
    self:updateSortedActions()
    self.actionsDirty = true
    self.vehicle:requestActionEventUpdate()
end
function VehicleActionController:removeAction(action)
    if Platform.gameplay.automaticVehicleControl and (action:getLastDirection() == 1 and action:getDoResetOnDeactivation()) then
        action:doAction()
    end
    for i, v in ipairs(self.actions) do
        if v == action then
            table.remove(self.actions, i)
            break
        end
    end
    if #self.actions == 0 then
        self.lastDirection = -1
    end
    self:updateSortedActions()
end
function VehicleActionController:updateSortedActions()
    self.actionsByPrio = {}
    for _, action in ipairs(self.actions) do
        if ({})[action.priority] == nil then
            local prioTable = { action }
            table.insert(self.actionsByPrio, prioTable)
            prioToActionTable[action.priority] = prioTable
        else
            table.insert(prioToActionTable[action.priority], action)
        end
    end
    self.sortedActions = table.clone(self.actionsByPrio)
    table.sort(self.sortedActions, function(a, b)
        return a[1].priority > b[1].priority
    end)
    self.sortedActionsRev = table.clone(self.actionsByPrio)
    table.sort(self.sortedActionsRev, function(a, b)
        return a[1].priority < b[1].priority
    end)
end
function VehicleActionController:activate()
    if self.pendingControllerReactivation then
        if self.vehicle == self.vehicle.rootVehicle then
            self.lastDirection = -self.lastDirection
            self:startActionSequence(true)
        end
        self.pendingControllerReactivation = false
    end
end
function VehicleActionController:deactivate()
    if self.vehicle == self.vehicle.rootVehicle and self.lastDirection > 0 then
        self.pendingControllerReactivation = true
    end
end
function VehicleActionController:registerActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if #self.actions > 0 and self.vehicle.rootVehicle == self.vehicle then
        self.vehicle:clearActionEventsTable(self.actionEvents)
        for _, action in ipairs(self.actions) do
            action:registerActionEvents(self, self.vehicle, self.actionEvents, isActiveForInput, isActiveForInputIgnoreSelection)
        end
        if self.actionEventId ~= nil then
            g_inputBinding:removeActionEvent(self.actionEventId)
        end
        local _, actionEventId, _ = g_inputBinding:registerActionEvent(InputAction.VEHICLE_ACTION_CONTROL, self, VehicleActionController.actionSequenceEvent, false, true, false, true)
        self.actionEventId = actionEventId
    end
end
function VehicleActionController:actionEvent(_, _, actionIndex, _)
    self:doAction(actionIndex)
end
function VehicleActionController:doAction(actionIndex, customTable, direction)
    local actions = self:getActionsByIndex(actionIndex, customTable)
    if actions == nil then
        return false
    end
    local retValue = false
    for _, action in ipairs(actions) do
        retValue = retValue or action:doAction(direction)
    end
    return retValue
end
function VehicleActionController:actionSequenceEvent()
    if self.loadedNumActions == 0 then
        if self.vehicle.getAreControlledActionsAccessible == nil or self.vehicle:getAreControlledActionsAccessible() then
            if self.vehicle.getAreControlledActionsAvailable ~= nil then
                if not self.vehicle:getAreControlledActionsAvailable() then
                    return
                end
                local allowed, warning = self.vehicle:getAreControlledActionsAllowed()
                if not allowed then
                    if warning ~= nil then
                        g_currentMission:showBlinkingWarning(warning, 2500)
                    end
                    return
                end
            end
            self:startActionSequence()
        end
    else
        return
    end
end
function VehicleActionController:startActionSequence(force)
    local direction = -self.lastDirection
    self.currentSequenceActions = self.sortedActionsRev
    if direction > 0 then
        self.currentSequenceActions = self.sortedActions
    end
    if not force then
        local alreadyFinished = true
        for _, actions in ipairs(self.currentSequenceActions) do
            for _, action in ipairs(actions) do

            end
        end
        if alreadyFinished then
            self.lastDirection = direction
            self:startActionSequence(true)
            return
        end
    end
    if self.currentSequenceIndex == nil then
        self.currentSequenceIndex = 1
        self.currentMaxSequenceIndex = #self.currentSequenceActions
    else
        self.currentSequenceIndex = self.currentMaxSequenceIndex - (self.currentSequenceIndex - 1)
    end
    self.lastDirection = direction
    if not self:doAction(self.currentSequenceIndex, self.currentSequenceActions, self.lastDirection) then
        if self.currentMaxSequenceIndex == 1 then
            self.lastDirection = -direction
            self:stopActionSequence()
            return
        end
        self:continueActionSequence()
    end
end
function VehicleActionController:continueActionSequence()
    self.currentSequenceIndex = self.currentSequenceIndex + 1
    local success = self:doAction(self.currentSequenceIndex, self.currentSequenceActions, self.lastDirection)
    if self.currentSequenceIndex >= self.currentMaxSequenceIndex then
        self:stopActionSequence()
    elseif not success then
        self:continueActionSequence()
    end
end
function VehicleActionController:stopActionSequence()
    self.currentSequenceActions = nil
    self.currentSequenceIndex = nil
    self.currentMaxSequenceIndex = nil
end
function VehicleActionController:getActionsByIndex(actionIndex, customTable)
    if customTable == nil then
        return self.actionsByPrio[actionIndex]
    else
        return customTable[actionIndex]
    end
end
function VehicleActionController:getAreControlledActionsAvailable()
    local i = 1
    for i = i, #self.actions do
        if not self.actions[i]:isAvailable() then
            return false
        end
    end
    return #self.actions > 0
end
function VehicleActionController:getAreControlledActionsAccessible()
    local i = 1
    for i = i, #self.actions do
        if not self.actions[i]:isAccessible() then
            return false
        end
    end
    return #self.actions > 0
end
function VehicleActionController:getControlledActionIcons()
    local i = 1
    for i = i, #self.actions do
        local iconPos, iconNeg, changeColor = self.actions[i]:getControlledActionIcons()
        if iconPos ~= nil then
            return iconPos, iconNeg, changeColor
        end
    end
    return nil
end
function VehicleActionController:playControlledActions()
    if self.loadedNumActions == 0 then
        self:startActionSequence()
    end
end
function VehicleActionController:resetCurrentState()
    self.lastDirection = -1
end
function VehicleActionController:getActionControllerDirection()
    return -self.lastDirection
end
function VehicleActionController:update(dt)
    if self.currentSequenceIndex ~= nil and self.currentSequenceIndex <= self.currentMaxSequenceIndex then
        local actions = self:getActionsByIndex(self.currentSequenceIndex, self.currentSequenceActions)
        if actions ~= nil then
            local allFinished = true
            for _, action in ipairs(actions) do
                if not action:getIsFinished(self.lastDirection) then
                    allFinished = false
                    break
                end
            end
            if allFinished then
                if self.currentSequenceIndex < self.currentMaxSequenceIndex then
                    self:continueActionSequence()
                else
                    self:stopActionSequence()
                end
            end
        end
    end
    for _, action in ipairs(self.actions) do
        action:update(dt)
    end
    if self.loadedNumActions ~= 0 and (self.loadedNumActions == #self.actions and self.loadTime + 500 < g_time) then
        local actions = true
        if self.vehicle.getIsMotorStarted ~= nil then
            actions = self.vehicle:getIsMotorStarted()
        end
        if actions then
            for action, _ in ipairs(self.loadedActions) do
                for _, actionToCheck in ipairs(self.actions) do
                    if actionToCheck.name == _.name and (actionToCheck.identifier == _.identifier and actionToCheck:getLastDirection() ~= _.lastDirection) then
                        actionToCheck:doAction()
                    end
                end
            end
            self.loadedNumActions = 0
            self.actionsDirty = false
        end
    end
    if self.actionsDirty and self.loadedNumActions == 0 then
        for _, action in ipairs(self.actions) do
            if action:getLastDirection() ~= self.lastDirection then
                action:doAction()
            end
        end
        self.actionsDirty = nil
    end
end
function VehicleActionController:updateForAI(dt)
    for _, action in ipairs(self.actions) do
        action:updateForAI(dt)
    end
end
function VehicleActionController:onAIEvent(sourceVehicle, eventName)
    for _, action in ipairs(self.actions) do
        if action:getSourceVehicle() == sourceVehicle then
            action:onAIEvent(eventName)
        end
    end
end
function VehicleActionController:drawDebugRendering()
    local function renderTextVAC(x, y, height, text, color)
        setTextColor(0, 0, 0, 0.75)
        renderText(x, y - 0.0015, height, text)
        setTextColor(unpack(color or {
            1,
            1,
            1,
            1
        }))
        renderText(x, y, height, text)
    end
    local function drawActions(name, sequenceActions, highlightIndex, posX, posY)
        -- upvalues: (copy) renderTextVAC
        if sequenceActions ~= nil and #sequenceActions > 0 then
            setTextBold(false)
            setTextAlignment(RenderText.ALIGN_CENTER)
            local currentHeight = 0
            local i = #sequenceActions
            for i = i, 1, -1 do
                local color = setTextBold
                color(highlightIndex == i)
                local color = nil
                local color = i < highlightIndex and {
                    0,
                    1,
                    0,
                    1
                } or (i == highlightIndex and {
                    1,
                    0.5,
                    0,
                    1
                } or color)
                for _, action in ipairs(sequenceActions[i]) do
                    renderTextVAC(posX, posY + currentHeight, 0.012, action:getDebugText(), color)
                    currentHeight = currentHeight + 0.014
                end
                renderTextVAC(posX, posY + currentHeight + 0.007, 0.012, "__________________________")
                currentHeight = currentHeight + 0.014
            end
            renderTextVAC(posX, posY + currentHeight + 0.007, 0.018000000000000002, name)
            setTextBold(false)
            setTextAlignment(RenderText.ALIGN_LEFT)
        end
    end
    drawActions(string.format("Controlled Actions (%s)", self.lastDirection == 1 and "On" or "Off"), self.sortedActions, -1, 0.2, 0.3)
    drawActions(string.format("Current Action Sequence (%s)", self.lastDirection == 1 and "TurnOn" or "TurnOff"), self.currentSequenceActions, self.currentSequenceIndex, 0.4, 0.3)
end
function VehicleActionController.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#lastDirection", "Last action controller direction")
    schema:register(XMLValueType.INT, basePath .. "#numActions", "Action controller actions")
    schema:register(XMLValueType.STRING, basePath .. ".action(?)#name", "Action name")
    schema:register(XMLValueType.STRING, basePath .. ".action(?)#identifier", "Action identifier")
    schema:register(XMLValueType.INT, basePath .. ".action(?)#lastDirection", "Last action direction")
end