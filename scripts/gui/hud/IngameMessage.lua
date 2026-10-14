local data = nil
if IngameMessage ~= nil then
    local old = g_currentMission.hud.ingameMessage
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible(),
        ["pendingMessages"] = old.pendingMessages
    }
    if old.currentMessage ~= nil then
        old:stopMessage()
    end
    old:delete()
end
IngameMessage = {}
IngameMessage.MIN_DURATION = 1000
IngameMessage.DURATION_PER_CHARACTER = 80
IngameMessage.MAX_DURATION = 300000
IngameMessage.INPUT_CONTEXT_NAME = "IngameMessage"
local old = Class(IngameMessage, HUDDisplay)
function IngameMessage.new(customMt)
    -- upvalues: (copy) old
    local self = IngameMessage:superClass().new(old)
    self.pendingMessages = {}
    self.isCustomInputActive = false
    self.lastInputMode = g_inputBinding:getInputHelpMode()
    self.glyphButtonOverlay = GlyphButtonOverlay.new()
    self.glyphButtonOverlay:setColor(0.22323, 0.40724, 0.0036, 1, 0, 0, 0, 0.8)
    self.keyButtonOverlay = ButtonOverlay.new()
    self.keyButtonOverlay:setColor(0.22323, 0.40724, 0.00368, 1, 0, 0, 0, 0.8)
    self.skipText = g_i18n:getText("button_ok")
    self.skipControl = nil
    self.isGamePaused = false
    self.nextMessageTimer = -1
    return self
end
function IngameMessage:delete()
    self.glyphButtonOverlay:delete()
    self.keyButtonOverlay:delete()
end
function IngameMessage:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, 0)
    self:setPosition(0.5 + offsetX, g_hudAnchorBottom + offsetY)
    self.width = self:scalePixelToScreenWidth(640)
    self.skipTextSize = self:scalePixelToScreenHeight(17)
    self.skipTextOffsetX, self.skipTextOffsetY = self:scalePixelValuesToScreenVector(5, 22)
    self.skipButtonOffsetY = self:scalePixelToScreenHeight(12)
    self.skipHeight = self:scalePixelToScreenHeight(30)
    self.titleTextSize = self:scalePixelToScreenHeight(19)
    self.titleToTextOffsetY = self:scalePixelToScreenHeight(10)
    self.titleOffsetY = self:scalePixelToScreenHeight(20)
    self.textSize = self:scalePixelToScreenHeight(17)
    self.textOffsetY = self:scalePixelToScreenHeight(18)
    self.textOffsetX, self.textOffsetY = self:scalePixelValuesToScreenVector(20, 20)
    self.maxTextWidth = self.width - 2 * self.textOffsetX
    self.controlTextSize = self:scalePixelToScreenHeight(17)
    self.controlTextOffsetX, self.controlTextOffsetY = self:scalePixelValuesToScreenVector(10, 15)
    self.textControlsOffsetY = self:scalePixelToScreenHeight(15)
    self.controlsHeight = self:scalePixelToScreenHeight(42)
    self.keyButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
    self.glyphButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
    self.buttonHeight = self:scalePixelToScreenHeight(30)
    self:updateControls()
end
function IngameMessage:updateControls()
    if self.currentMessage ~= nil then
        self.skipControl = g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SKIP_MESSAGE_BOX, "", "", false)
        local controls = self.currentMessage.controls
        if controls ~= nil then
            for _, control in ipairs(controls) do
                local helpElement = g_inputDisplayManager:getControllerSymbolOverlays(control.actionName, control.actionName2, "", false)
                control.buttons = helpElement.buttons
                control.isComboButtonMapping = helpElement.isComboButtonMapping
                control.keys = helpElement.keys
            end
        end
    end
end
function IngameMessage:update(dt)
    if not (g_gui:getIsMenuVisible() or (self.isGamePaused or g_sleepManager:getIsSleeping())) then
        if self.currentMessage == nil then
            if self.nextMessageTimer > 0 then
                self.nextMessageTimer = self.nextMessageTimer - dt
            elseif #self.pendingMessages > 0 then
                self:startMessage()
            end
        else
            self.currentMessage.timeLeft = self.currentMessage.timeLeft - dt
            if self.currentMessage.timeLeft <= 0 then
                self:stopMessage()
            end
        end
        if self.currentMessage ~= nil then
            local inputMode = g_inputBinding:getInputHelpMode()
            if inputMode ~= self.lastInputMode then
                self.lastInputMode = inputMode
                self:updateControls()
            end
        end
    end
end
function IngameMessage:setPaused(isPaused)
    self.isGamePaused = isPaused
end
function IngameMessage:setVisible(isVisible)
    self:setInputActive(isVisible)
    IngameMessage:superClass().setVisible(self, isVisible)
end
function IngameMessage:setInputActive(isActive)
    if self.isCustomInputActive or not isActive then
        if self.isCustomInputActive and not isActive then
            g_inputBinding:removeActionEventsByTarget(self)
            g_inputBinding:revertContext(true)
            self.isCustomInputActive = false
        end
    else
        g_inputBinding:setContext(IngameMessage.INPUT_CONTEXT_NAME, true, false)
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.stopMessage, false, true, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.SKIP_MESSAGE_BOX, self, self.stopMessage, false, true, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        self.isCustomInputActive = true
    end
end
function IngameMessage:startMessage()
    local ingameMap = g_currentMission.hud.ingameMap
    ingameMap:setAllowToggle(false)
    ingameMap:turnSmall()
    local pendingMessage = table.remove(self.pendingMessages, 1)
    if pendingMessage ~= nil then
        self.currentMessage = pendingMessage
        self:updateControls()
        self:setVisible(true)
    end
end
function IngameMessage:stopMessage()
    if self.currentMessage ~= nil then
        g_currentMission.hud.ingameMap:setAllowToggle(true)
        if self.currentMessage ~= nil and self.currentMessage.callback ~= nil then
            if self.currentMessage.target == nil then
                self.currentMessage.callback(self)
            else
                self.currentMessage.callback(self.currentMessage.target)
            end
        end
        self:setVisible(false)
        self.currentMessage = nil
        self.nextMessageTimer = 500
    end
end
function IngameMessage:showMessage(title, text, duration, controls, callback, target)
    duration = duration or -1
    if duration == 0 then
        duration = IngameMessage.MIN_DURATION + utf8Strlen(text) * IngameMessage.DURATION_PER_CHARACTER
    elseif duration < 0 then
        duration = IngameMessage.MAX_DURATION
    end
    if title ~= nil then
        title = utf8ToUpper(title)
    end
    table.insert(self.pendingMessages, {
        ["isDialog"] = false,
        ["title"] = title,
        ["text"] = text,
        ["timeLeft"] = duration,
        ["controls"] = controls,
        ["callback"] = callback,
        ["target"] = target
    })
end
function IngameMessage:draw()
    IngameMessage:superClass().draw(self)
    if self:getVisible() then
        if not g_gui:getIsGuiVisible() then
            local message = self.currentMessage
            if message ~= nil then
                local title = message.title
                local text = message.text
                local controls = message.controls
                local posX, posY = self:getPosition()
                local posX = posX - self.width * 0.5
                local height = 2 * self.textOffsetY + self.skipHeight
                setTextColor(1, 1, 1, 1)
                setTextAlignment(RenderText.ALIGN_LEFT)
                setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
                setTextWrapWidth(self.maxTextWidth)
                local titleHeight = 0
                if title ~= nil then
                    setTextBold(true)
                    titleHeight = getTextHeight(self.titleTextSize, title)
                end
                local textHeight = 0
                if text ~= nil then
                    setTextBold(false)
                    textHeight = getTextHeight(self.textSize, text)
                end
                if controls ~= nil then
                    local numControls = #controls
                end
                if title ~= nil or text ~= nil then
                end
                local numControls = HUD.COLOR.BACKGROUND_DARK
                drawFilledRectRound(posX, posY, self.width, height, 0.5, numControls[1], numControls[2], numControls[3], numControls[4])
                local currentPosY = posY + height - self.textOffsetY
                if title ~= nil then
                    setTextBold(true)
                    renderText(posX + self.textOffsetX, currentPosY, self.titleTextSize, title)
                    currentPosY = currentPosY - self.titleToTextOffsetY - titleHeight
                end
                if text ~= nil then
                    setTextBold(false)
                    renderText(textPosX, currentPosY, self.textSize, text)
                    currentPosY = currentPosY - textHeight
                end
                setTextWrapWidth(0)
                setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
                if title ~= nil or text ~= nil then
                    currentPosY = currentPosY - self.textControlsOffsetY
                    local lineStart = posX + self.textOffsetX
                    drawLine2D(lineStart, currentPosY, lineStart + self.maxTextWidth, currentPosY, g_pixelSizeY, 1, 1, 1, 0.2)
                end
                if controls ~= nil then
                    local lineStart = posX + self.textOffsetX
                    for _, control in ipairs(controls) do
                        currentPosY = currentPosY - self.controlsHeight
                        local width = self:drawControl(control, lineStart + self.maxTextWidth, currentPosY + (self.controlsHeight - self.buttonHeight) * 0.5)
                        local controlText = Utils.limitTextToWidth(control.text, self.controlTextSize, self.maxTextWidth - width - self.controlTextOffsetX, false, "...")
                        setTextBold(true)
                        renderText(textPosX, currentPosY + self.controlTextOffsetY, self.controlTextSize, controlText)
                        drawLine2D(lineStart, currentPosY, lineEnd, currentPosY, g_pixelSizeY, 1, 1, 1, 0.2)
                    end
                    local numControls = #controls
                end
                setTextBold(true)
                setTextAlignment(RenderText.ALIGN_RIGHT)
                local lineStart = getTextWidth(self.skipTextSize, self.skipText)
                local lineEnd = posX + self.textOffsetX + self.maxTextWidth * 0.5 + lineStart
                local offsetY = posY + self.skipTextOffsetY
                renderText(lineEnd, offsetY, self.skipTextSize, self.skipText)
                local numControls = lineEnd - self.skipTextOffsetX - lineStart
                local skipPosY = posY + self.skipButtonOffsetY
                self:drawControl(self.skipControl, numControls, skipPosY)
                setTextColor(1, 1, 1, 1)
                setTextAlignment(RenderText.ALIGN_LEFT)
            end
        end
    else
        return
    end
end
function IngameMessage:drawControl(control, posX, posY)
    local buttons = control.buttons
    local isComboButtonMapping = control.isComboButtonMapping
    local width = 0
    if #buttons <= 0 then
        if #control.keys > 0 then
            local i = #keys
            for i = i, 1, -1 do
                local key = keys[i]
                local totalWidth = self.keyButtonOverlay:getButtonWidth(key, self.buttonHeight) + g_pixelSizeX
                posX = posX - totalWidth
                self.keyButtonOverlay:renderButton(key, posX, posY, self.buttonHeight, true)
            end
        end
        return width
    end
    local totalWidth = self.glyphButtonOverlay:getButtonWidth(buttons, isComboButtonMapping, false, self.buttonHeight)
    local startPosX = posX - totalWidth
    self.glyphButtonOverlay:renderButton(buttons, isComboButtonMapping, false, startPosX, posY, self.buttonHeight)
    return width + totalWidth
end
if data ~= nil then
    local ingameMessage = IngameMessage.new()
    ingameMessage:setScale(data.uiScale)
    ingameMessage:setVisible(data.isVisible)
    for _, m in ipairs(data.pendingMessages) do
        ingameMessage:showMessage(m.title, m.text, m.duration, m.controls, m.callback, m.target)
    end
    g_currentMission.hud.ingameMessage = ingameMessage
    g_currentMission.hud.displayComponents.ingameMessage = ingameMessage
    Logging.info("Reloaded IngameMessage")
end