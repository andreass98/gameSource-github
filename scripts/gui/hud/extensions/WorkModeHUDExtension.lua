WorkModeHUDExtension = {}
local WorkModeHUDExtension_mt = Class(WorkModeHUDExtension)
function WorkModeHUDExtension.new(vehicle, customMt)
    -- upvalues: (copy) WorkModeHUDExtension_mt
    local self = setmetatable({}, customMt or WorkModeHUDExtension_mt)
    self.priority = GS_PRIO_HIGH
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.background = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
    self.background:setColor(r, g, b, a)
    self.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.separatorHorizontal:setColor(1, 1, 1, 0.25)
    self.workModeText = g_i18n:getText("action_workModeSelected")
    self.vehicle = vehicle
    self:storeScaledValues()
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
    return self
end
function WorkModeHUDExtension:delete()
    self.background:delete()
    self.separatorHorizontal:delete()
    g_messageCenter:unsubscribeAll(self)
end
function WorkModeHUDExtension:storeScaledValues()
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local width, height = getNormalizedScreenValues(330 * uiScale, 50 * uiScale)
    self.background:setDimension(width, height)
    self.separatorHorizontal:setDimension(width, g_pixelSizeY)
    _, self.inputHeight = getNormalizedScreenValues(0, 25 * uiScale)
end
function WorkModeHUDExtension:setEventHelpElements(inputHelpDisplay, eventHelpElements)
    inputHelpDisplay:addSkipAction(InputAction.TOGGLE_WORKMODE)
    self.toggleElement = nil
    if eventHelpElements ~= nil then
        for k, helpElement in ipairs(eventHelpElements) do
            if helpElement.actionName == InputAction.TOGGLE_WORKMODE then
                self.toggleElement = helpElement
            end
        end
    end
end
function WorkModeHUDExtension:draw(inputHelpDisplay, posX, posY)
    local toggleElement = self.toggleElement
    if toggleElement == nil then
        return posY
    end
    posY = posY - self.background.height
    self.background:setPosition(posX, posY)
    self.background:render()
    local textOffsetX = inputHelpDisplay.textOffsetX
    local textOffsetY = inputHelpDisplay.textOffsetY
    local textSize = inputHelpDisplay.textSize
    local togglePosY = posY + self.inputHeight
    local textPosX = posX + textOffsetX
    local workMode = self.vehicle:getWorkMode()
    local toggleWidth = inputHelpDisplay:drawInput(posX + self.background.width, togglePosY, self.inputHeight, toggleElement)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    local toggleText = utf8ToUpper(toggleElement.text)
    local modeText = Utils.limitTextToWidth(toggleText, textSize, self.background.width - toggleWidth - 2 * textOffsetX, false, "...")
    renderText(textPosX, togglePosY + textOffsetY, textSize, modeText)
    local modeText = utf8ToUpper(string.format(self.workModeText, workMode.name))
    local modeText = Utils.limitTextToWidth(modeText, textSize, self.background.width - 2 * textOffsetX, false, "...")
    renderText(textPosX, posY + textOffsetY, textSize, modeText)
    setTextBold(false)
    self.separatorHorizontal:renderCustom(posX, posY + self.background.height * 0.5)
    return posY
end
function WorkModeHUDExtension:getHeight()
    return self.background.height
end