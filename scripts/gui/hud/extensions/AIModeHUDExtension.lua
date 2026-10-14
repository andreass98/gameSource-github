AIModeHUDExtension = {}
local AIModeHUDExtension_mt = Class(AIModeHUDExtension)
function AIModeHUDExtension.new(vehicle, customMt)
    -- upvalues: (copy) AIModeHUDExtension_mt
    local self = setmetatable({}, customMt or AIModeHUDExtension_mt)
    self.priority = GS_PRIO_VERY_HIGH
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.background = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
    self.background:setColor(r, g, b, a)
    self.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.separatorHorizontal:setColor(1, 1, 1, 0.25)
    self.aiModeText = g_i18n:getText("action_aiModeSelected")
    self.aiModeHoldText = utf8ToUpper(g_i18n:getText("input_holdButton"))
    self.vehicle = vehicle
    self.spec = vehicle.spec_aiModeSelection
    self.specDrivable = vehicle.spec_aiDrivable
    self.textWorkerDeactivate = g_i18n:getText("ai_modeWorker_deactivate")
    self.textWorkerActivate = g_i18n:getText("ai_modeWorker_activate")
    self.textSteeringAssistDeactivate = g_i18n:getText("ai_modeSteeringAssist_deactivate")
    self.textSteeringAssistActivate = g_i18n:getText("ai_modeSteeringAssist_activate")
    self.textSteeringAssistDisabled = g_i18n:getText("ai_modeSteeringAssist_noLane")
    self.textAIState = g_i18n:getText("ai_state")
    self.textAIStateDriving = g_i18n:getText("ai_stateDriving")
    self.textAIStatePlanning = g_i18n:getText("ai_statePlanning")
    self.textAIStateBlocked = g_i18n:getText("ai_stateBlocked")
    self.textAIStateTargetReached = g_i18n:getText("ai_stateTargetReached")
    self.textAIStateNotReachable = g_i18n:getText("ai_stateNotReachable")
    self.aiElement = nil
    self:storeScaledValues()
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
    return self
end
function AIModeHUDExtension:delete()
    self.background:delete()
    self.separatorHorizontal:delete()
    g_messageCenter:unsubscribeAll(self)
end
function AIModeHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local width, height = getNormalizedScreenValues(330 * uiScale, 50 * uiScale)
    self.background:setDimension(width, height)
    self.separatorHorizontal:setDimension(width, g_pixelSizeY)
    _, self.inputHeight = getNormalizedScreenValues(0, 25 * uiScale)
    self.holdIconButtonOffset = getNormalizedScreenValues(5 * uiScale, 0)
end
function AIModeHUDExtension:setEventHelpElements(inputHelpDisplay, eventHelpElements)
    inputHelpDisplay:addSkipAction(InputAction.TOGGLE_AI)
    inputHelpDisplay:addSkipAction(InputAction.TOGGLE_AI_STEERING)
    self.aiElement = nil
    self.aiSteeringElement = nil
    if eventHelpElements ~= nil then
        for k, helpElement in ipairs(eventHelpElements) do
            local actionName = helpElement.actionName
            if actionName == InputAction.TOGGLE_AI then
                self.aiElement = helpElement
            elseif actionName == InputAction.TOGGLE_AI_STEERING then
                self.aiSteeringElement = helpElement
            end
        end
    end
end
function AIModeHUDExtension:draw(inputHelpDisplay, posX, posY)
    local aiElement = self.aiElement
    if aiElement ~= nil then
        posY = posY - self.background.height
        self.background:setPosition(posX, posY)
        self.background:render()
        local textOffsetX = inputHelpDisplay.textOffsetX
        local textOffsetY = inputHelpDisplay.textOffsetY
        local textSize = inputHelpDisplay.textSize
        local togglePosY = posY + self.inputHeight
        local textPosX = posX + textOffsetX
        local specDrivable = self.specDrivable
        local drawToggleButton = true
        local drawModeSwitch = true
        if specDrivable ~= nil and specDrivable.isRunning then
            drawModeSwitch = false
        end
        local currentMode = self.spec.currentMode
        local state
        if currentMode == AIModeSelection.MODE.WORKER then
            state = self.vehicle:getIsAIActive() and self.textWorkerDeactivate or self.textWorkerActivate
        else
            local state = self.vehicle:getAIAutomaticSteeringState()
            if state == AIAutomaticSteering.STATE.ACTIVE then
                state = self.textSteeringAssistDeactivate
            elseif state == AIAutomaticSteering.STATE.AVAILABLE then
                state = self.textSteeringAssistActivate
            else
                state = self.textSteeringAssistDisabled
                drawToggleButton = false
            end
        end
        local state = 0
        local changeWidth = 0
        if drawToggleButton then
            state = inputHelpDisplay:drawInput(posX + self.background.width, togglePosY, self.inputHeight, self.aiSteeringElement or aiElement)
        end
        if drawModeSwitch then
            changeWidth = inputHelpDisplay:drawInput(startPosX, posY, self.inputHeight, aiElement, self.holdIconButtonOffset, self.aiModeHoldText)
        end
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextColor(1, 1, 1, 1)
        local toggleText = utf8ToUpper(state)
        local modeText = Utils.limitTextToWidth(toggleText, textSize, self.background.width - state - 2 * textOffsetX, false, "...")
        renderText(textPosX, togglePosY + textOffsetY, textSize, modeText)
        if drawModeSwitch then
            local modeText = utf8ToUpper(string.format(self.aiModeText, g_i18n:getText(AIModeSelection.MODE_TEXTS[currentMode])))
            local stateText = Utils.limitTextToWidth(modeText, textSize, self.background.width - changeWidth - 2 * textOffsetX, false, "...")
            renderText(textPosX, posY + textOffsetY, textSize, stateText)
        else
            local modeText = specDrivable.lastState
            local stateText = nil
            if modeText == AgentState.DRIVING then
                stateText = self.textAIStateDriving
            elseif modeText == AgentState.PLANNING then
                stateText = self.textAIStatePlanning
            elseif modeText == AgentState.BLOCKED then
                stateText = self.textAIStateBlocked
            elseif modeText == AgentState.TARGET_REACHED then
                stateText = self.textAIStateTargetReached
            elseif modeText == AgentState.NOT_REACHABLE then
                stateText = self.textAIStateNotReachable
            end
            if stateText ~= nil then
                local infoText = string.namedFormat(self.textAIState, "aiState", stateText)
                renderText(textPosX, posY + textOffsetY, textSize, utf8ToUpper(infoText))
            end
        end
        setTextBold(false)
        self.separatorHorizontal:renderCustom(posX, posY + self.background.height * 0.5)
    end
    return posY
end
function AIModeHUDExtension:getHeight()
    return self.aiElement == nil and 0 or self.background.height
end