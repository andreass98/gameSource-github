HUDPopupMessageMobile = {}
local HUDPopupMessageMobile_mt = Class(HUDPopupMessageMobile, HUDDisplayElement)
HUDPopupMessageMobile.INPUT_CONTEXT_NAME = "POPUP_MESSAGE"
HUDPopupMessageMobile.MAX_PENDING_MESSAGE_COUNT = 8
HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT = 8
HUDPopupMessageMobile.MIN_DURATION = 1000
HUDPopupMessageMobile.DURATION_PER_CHARACTER = 80
HUDPopupMessageMobile.MAX_DURATION = 300000
function HUDPopupMessageMobile.new(hudAtlasPath, ingameMap)
    -- upvalues: (copy) HUDPopupMessageMobile_mt
    local backgroundOverlay = HUDPopupMessageMobile.createBackground(hudAtlasPath)
    local self = HUDPopupMessageMobile:superClass().new(backgroundOverlay, nil, HUDPopupMessageMobile_mt)
    self.ingameMap = ingameMap
    self.pendingMessages = {}
    self.isCustomInputActive = false
    self.lastInputMode = g_inputBinding:getInputHelpMode()
    self.inputRows = {}
    self.inputGlyphs = {}
    self.continueGlyph = nil
    self.time = 0
    self.isGamePaused = false
    self.continueText = g_i18n:getText("introduction_continueTextTouch")
    self:storeScaledValues()
    self:createComponents(hudAtlasPath)
    return self
end
function HUDPopupMessageMobile:delete()
    if self.blurAreaActive then
        g_depthOfFieldManager:popArea()
        self.blurAreaActive = false
    end
    HUDPopupMessageMobile:superClass().delete(self)
end
function HUDPopupMessageMobile:showMessage(title, text, duration, controls, callback, target)
    if duration == 0 then
        duration = HUDPopupMessageMobile.MIN_DURATION + string.len(text) * HUDPopupMessageMobile.DURATION_PER_CHARACTER
    elseif duration < 0 then
        duration = HUDPopupMessageMobile.MAX_DURATION
    end
    while #self.pendingMessages > HUDPopupMessageMobile.MAX_PENDING_MESSAGE_COUNT do
        table.remove(self.pendingMessages, 1)
    end
    local message = {
        ["isDialog"] = false,
        ["title"] = title,
        ["message"] = text,
        ["duration"] = duration,
        ["controls"] = Utils.getNoNil(controls, {}),
        ["callback"] = callback,
        ["target"] = target
    }
    if #message.controls > HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT then
        local i = #message.controls
        for i = i, HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT + 1, -1 do
            table.remove(message.controls, i)
        end
    end
    table.insert(self.pendingMessages, message)
end
function HUDPopupMessageMobile:setPaused(isPaused)
    self.isGamePaused = isPaused
end
function HUDPopupMessageMobile:getVisible()
    return HUDPopupMessageMobile:superClass().getVisible(self) and self.currentMessage ~= nil
end
function HUDPopupMessageMobile:getHidingTranslation()
    return 0, -self:getHeight() - g_safeFrameOffsetY - 0.01
end
function HUDPopupMessageMobile:assignCurrentMessage(message)
    self.time = 0
    self.currentMessage = message
    if g_touchHandler ~= nil then
        g_touchHandler:setCustomContext("guidedTour", true)
        g_touchHandler:registerTouchArea(0, 0, 1, 1, 0, 0, TouchHandler.TRIGGER_UP, self.onConfirmMessage, self)
    end
    local isTouch = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_TOUCH
    self.continueGlyph:setVisible(not isTouch)
    self:setCurrentMessageHeight()
    self:updateButtonGlyphs()
end
function HUDPopupMessageMobile:setCurrentMessageHeight()
    local reqHeight = self:getTitleHeight() + self:getTextHeight() + self:getInputRowsHeight() + self.borderPaddingY * 2 + self.textOffsetY + self.titleTextSize + self.textSize
    if #self.currentMessage.controls > 0 then
    end
    local reqHeight = reqHeight + self.continueButtonHeight
    self:setDimension(self:getWidth(), (math.max(self.minHeight, reqHeight)))
end
function HUDPopupMessageMobile:getTitleHeight()
    local height = 0
    if self.currentMessage ~= nil then
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(false)
        setTextWrapWidth(self:getWidth() - 2 * self.borderPaddingX)
        local title = utf8ToUpper(self.currentMessage.title)
        local lineHeight, numTitleRows = getTextHeight(self.titleTextSize, title)
        height = numTitleRows * lineHeight
        setTextWrapWidth(0)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
    return height
end
function HUDPopupMessageMobile:getTextHeight()
    local height = 0
    if self.currentMessage ~= nil then
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
        setTextWrapWidth(self:getWidth() - 2 * self.borderPaddingX)
        setTextLineHeightScale(HUDPopupMessageMobile.TEXT_LINE_HEIGHT_SCALE)
        height = getTextHeight(self.textSize, self.currentMessage.message)
        setTextWrapWidth(0)
        setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
    end
    return height
end
function HUDPopupMessageMobile:getInputRowsHeight()
    local height = 0
    if self.currentMessage ~= nil then
        height = (#self.currentMessage.controls + 1) * self.inputRowHeight
    end
    return height
end
function HUDPopupMessageMobile:animateHide()
    HUDPopupMessageMobile:superClass().animateHide(self)
    g_depthOfFieldManager:popArea()
    self.blurAreaActive = false
    self.animation:addCallback(self.finishMessage)
end
function HUDPopupMessageMobile:startMessage()
    self.ingameMap:setAllowToggle(false)
    self.ingameMap:turnSmall()
    self:assignCurrentMessage(self.pendingMessages[1])
    table.remove(self.pendingMessages, 1)
end
function HUDPopupMessageMobile:finishMessage()
    self.ingameMap:setAllowToggle(true)
    if self.currentMessage ~= nil and self.currentMessage.callback ~= nil then
        if self.currentMessage.target == nil then
            self.currentMessage.callback(self)
        else
            self.currentMessage.callback(self.currentMessage.target)
        end
    end
    self.currentMessage = nil
end
function HUDPopupMessageMobile:update(dt)
    if not g_gui:getIsMenuVisible() then
        HUDPopupMessageMobile:superClass().update(self, dt)
        if not (self.isGamePaused or g_sleepManager:getIsSleeping()) then
            self.time = self.time + dt
            self:updateCurrentMessage()
        end
        if self:getVisible() then
            local inputMode = g_inputBinding:getInputHelpMode()
            if inputMode ~= self.lastInputMode then
                self.lastInputMode = inputMode
                self:updateButtonGlyphs()
                self.continueGlyph:setVisible(not (inputMode == GS_INPUT_HELP_MODE_TOUCH))
            end
        end
    end
end
function HUDPopupMessageMobile:updateCurrentMessage()
    if self.currentMessage == nil then
        if #self.pendingMessages > 0 then
            self:startMessage()
            self:setVisible(true, true)
            self.animation:addCallback(function()
                -- upvalues: (copy) self
                local x, y = self:getPosition()
                g_depthOfFieldManager:pushArea(x, y, self:getWidth(), self:getHeight())
                self.blurAreaActive = true
            end)
        end
    elseif self.time > self.currentMessage.duration then
        self.time = -math.huge
        self:setVisible(false, true)
        return
    end
end
function HUDPopupMessageMobile:updateButtonGlyphs()
    if self.continueGlyph ~= nil then
        self.continueGlyph:setAction(InputAction.SKIP_MESSAGE_BOX, g_i18n:getText(HUDPopupMessageMobile.L10N_SYMBOL.BUTTON_OK), self.continueTextSize, true, false)
    end
    if self.currentMessage ~= nil then
        local controlIndex = 1
        local i = 1
        for i = i, HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT do
            local inputRowVisible = HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT - i + 1 <= #self.currentMessage.controls
            self.inputRows[i]:setVisible(inputRowVisible)
            if inputRowVisible then
                self.inputGlyphs[i]:setActions(self.currentMessage.controls[controlIndex]:getActionNames(), "", self.textSize, false, false)
                self.inputGlyphs[i]:setKeyboardGlyphColor(HUDPopupMessageMobile.COLOR.INPUT_GLYPH)
                controlIndex = controlIndex + 1
            end
        end
    end
end
function HUDPopupMessageMobile:setInputActive(isActive)
    if self.isCustomInputActive or not isActive then
        if self.isCustomInputActive and not isActive then
            g_inputBinding:removeActionEventsByTarget(self)
            inputBinding:revertContext(true)
            self.isCustomInputActive = false
        end
    else
        inputBinding:setContext(HUDPopupMessageMobile.INPUT_CONTEXT_NAME, true, false)
        local _, eventId = inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onConfirmMessage, false, true, false, true)
        inputBinding:setActionEventTextVisibility(eventId, false)
        local _, eventId = inputBinding:registerActionEvent(InputAction.SKIP_MESSAGE_BOX, self, self.onConfirmMessage, false, true, false, true)
        inputBinding:setActionEventTextVisibility(eventId, false)
        self.isCustomInputActive = true
    end
end
function HUDPopupMessageMobile:onConfirmMessage(_, _)
    if self.animation:getFinished() then
        if g_touchHandler ~= nil then
            g_touchHandler:revertCustomContext()
        end
        self:setVisible(false, true)
    end
end
function HUDPopupMessageMobile:setVisible(isVisible, animate)
    self:setInputActive(isVisible)
    HUDPopupMessageMobile:superClass().setVisible(self, isVisible, animate)
end
function HUDPopupMessageMobile:draw()
    if not g_gui:getIsMenuVisible() and (self:getVisible() and self.currentMessage ~= nil) then
        HUDPopupMessageMobile:superClass().draw(self)
        local baseX, baseY = self:getPosition()
        local textPosY = self:getWidth()
        local height = self:getHeight()
        local textPosY = setTextColor
        local posY = HUDPopupMessageMobile.COLOR.TITLE
        textPosY(unpack(posY))
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextWrapWidth(textPosY - 2 * self.borderPaddingX)
        local textPosY = baseY + height - self.borderPaddingY
        if self.currentMessage.title ~= "" then
            local title = utf8ToUpper(self.currentMessage.title)
            textPosY = textPosY - self.titleTextSize
            renderText(baseX + textPosY * 0.5, textPosY, self.titleTextSize, title)
        end
        setTextBold(false)
        local title = setTextColor
        local continueX = HUDPopupMessageMobile.COLOR.TEXT
        title(unpack(continueX))
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextLineHeightScale(HUDPopupMessageMobile.TEXT_LINE_HEIGHT_SCALE)
        local textPosY = textPosY - self.textSize + self.textOffsetY
        renderText(baseX + self.borderPaddingX, textPosY, self.textSize, self.currentMessage.message)
        local textPosY = textPosY - getTextHeight(self.textSize, self.currentMessage.message)
        local title = setTextColor
        local continueX = HUDPopupMessageMobile.COLOR.CONTINUE_TEXT
        title(unpack(continueX))
        setTextAlignment(RenderText.ALIGN_RIGHT)
        local title = baseX + textPosY - self.borderPaddingX
        local posY = textPosY + self.inputRowsOffsetY - self.inputRowHeight - self.textSize
        local i = 1
        local continueX = #self.currentMessage.controls
        local continueY = 1
        for i = i, continueX, continueY do
            renderText(title + self.inputRowTextX, posY + self.inputRowTextY, self.textSize, self.currentMessage.controls[i].text)
            posY = posY - self.inputRowHeight
        end
        setTextAlignment(RenderText.ALIGN_CENTER)
        if g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_TOUCH then
            local continueX, continueY = self.continueGlyph:getPosition()
            renderText(continueX + self.continueGlyph.baseWidth / 2, continueY + self.continueTextSize / 2, self.continueTextSize, self.continueText)
        end
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextWrapWidth(0)
        setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
    end
end
function HUDPopupMessageMobile.getBackgroundPosition(uiScale)
    local offX, offY = getNormalizedScreenValues(unpack(HUDPopupMessageMobile.POSITION.SELF))
    return 0.5 + offX * uiScale, g_safeFrameOffsetY + offY * uiScale
end
function HUDPopupMessageMobile:setScale(uiScale)
    HUDPopupMessageMobile:superClass().setScale(self, uiScale)
    self:storeScaledValues()
    local posX, posY = HUDPopupMessageMobile.getBackgroundPosition(uiScale)
    self:setPosition(posX - self:getWidth() * 0.5, posY)
end
function HUDPopupMessageMobile:setDimension(width, height)
    HUDPopupMessageMobile:superClass().setDimension(self, width, height)
end
function HUDPopupMessageMobile:storeScaledValues()
    self.minWidth, self.minHeight = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.SELF)
    self.textOffsetX, self.textOffsetY = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.MESSAGE_TEXT)
    self.inputRowsOffsetX, self.inputRowsOffsetY = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.INPUT_ROWS)
    self.continueButtonOffsetX, self.continueButtonOffsetY = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.CONTINUE_BUTTON)
    self.continueButtonWidth, self.continueButtonHeight = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.CONTINUE_BUTTON)
    self.inputRowWidth, self.inputRowHeight = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.INPUT_ROW)
    self.borderPaddingX, self.borderPaddingY = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.BORDER_PADDING)
    self.inputRowTextX, self.inputRowTextY = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.INPUT_TEXT)
    self.titleTextSize = self:scalePixelToScreenHeight(HUDPopupMessageMobile.TEXT_SIZE.TITLE)
    self.textSize = self:scalePixelToScreenHeight(HUDPopupMessageMobile.TEXT_SIZE.TEXT)
    self.continueTextSize = self:scalePixelToScreenHeight(HUDPopupMessageMobile.TEXT_SIZE.CONTINUE_TEXT)
end
function HUDPopupMessageMobile.createBackground(hudAtlasPath)
    local posX, posY = HUDPopupMessageMobile.getBackgroundPosition(1)
    local width, height = getNormalizedScreenValues(unpack(HUDPopupMessageMobile.SIZE.SELF))
    Overlay.new(hudAtlasPath, posX - width * 0.5, posY, width, height):setUVs(GuiUtils.getUVs(HUDPopupMessageMobile.UV.BACKGROUND))
    overlay:setColor(unpack(HUDPopupMessageMobile.COLOR.BACKGROUND))
    return overlay
end
function HUDPopupMessageMobile:createComponents(hudAtlasPath)
    local basePosX, basePosY = self:getPosition()
    local baseWidth = self:getWidth()
    local _, inputRowHeight = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.INPUT_ROW)
    local posY = basePosY + inputRowHeight
    local i = 1
    for i = i, HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT do
        local rowIndex, inputGlyph
        rowIndex, inputGlyph, posY = self:createInputRow(hudAtlasPath, basePosX, posY)
        local rowIndex = HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT - i + 1
        self.inputRows[rowIndex] = rowIndex
        self.inputGlyphs[rowIndex] = inputGlyph
        self:addChild(rowIndex)
    end
    local offX, offY = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.CONTINUE_BUTTON)
    local i, buttonRow = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.INPUT_GLYPH)
    local inputGlyph = InputGlyphElement.new(g_inputDisplayManager, i, buttonRow)
    inputGlyph:setPosition(basePosX + (baseWidth - i) * 0.5 + offX, basePosY - offY)
    inputGlyph:setAction(InputAction.SKIP_MESSAGE_BOX, g_i18n:getText(HUDPopupMessageMobile.L10N_SYMBOL.BUTTON_OK), self.continueTextSize, true, false)
    self.continueGlyph = inputGlyph
    self:addChild(inputGlyph)
end
function HUDPopupMessageMobile:createInputRow(hudAtlasPath, posX, posY)
    local overlay = Overlay.new(hudAtlasPath, posX, posY, self.inputRowWidth, self.inputRowHeight)
    overlay:setUVs(GuiUtils.getUVs(HUDPopupMessageMobile.UV.BACKGROUND))
    overlay:setColor(unpack(HUDPopupMessageMobile.COLOR.INPUT_ROW))
    local buttonPanel = HUDElement.new(overlay)
    local rowHeight = buttonPanel:getHeight()
    local glyphWidth, glyphHeight = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.INPUT_GLYPH)
    local inputGlyph = InputGlyphElement.new(g_inputDisplayManager, glyphWidth, glyphHeight)
    local offX, offY = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.INPUT_GLYPH)
    inputGlyph:setPosition(posX + self.borderPaddingX + offX, posY + (rowHeight - glyphHeight) * 0.5 + offY)
    buttonPanel:addChild(inputGlyph)
    local width, height = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.SEPARATOR)
    local separator = math.max(height, HUDPopupMessageMobile.SIZE.SEPARATOR[2] / g_screenHeight)
    local separator, offY = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.SEPARATOR)
    local separator = Overlay.new(hudAtlasPath, posX + separator, posY + offY, width, separator)
    separator:setUVs(GuiUtils.getUVs(GameInfoDisplay.UV.SEPARATOR))
    separator:setColor(unpack(GameInfoDisplay.COLOR.SEPARATOR))
    buttonPanel:addChild((HUDElement.new(separator)))
    return buttonPanel, inputGlyph, posY + rowHeight
end
HUDPopupMessageMobile.UV = {
    ["BACKGROUND"] = {
        8,
        8,
        2,
        2
    }
}
HUDPopupMessageMobile.SIZE = {
    ["SELF"] = { 1100, 200 },
    ["INPUT_ROW"] = { 1100, 80 },
    ["CONTINUE_BUTTON"] = { 60, 60 },
    ["BORDER_PADDING"] = { 60, 45 },
    ["INPUT_GLYPH"] = { 60, 60 },
    ["SEPARATOR"] = { 1100, 1 }
}
HUDPopupMessageMobile.POSITION = {
    ["SELF"] = { 0, 200 },
    ["MESSAGE_TEXT"] = { 0, -25 },
    ["INPUT_ROWS"] = { 0, -20 },
    ["CONTINUE_BUTTON"] = { 0, -12 },
    ["INPUT_GLYPH"] = { 0, 0 },
    ["INPUT_TEXT"] = { 0, 3 },
    ["SEPARATOR"] = { 0, 0 }
}
HUDPopupMessageMobile.TEXT_LINE_HEIGHT_SCALE = 1.5
HUDPopupMessageMobile.TEXT_SIZE = {
    ["TITLE"] = 40,
    ["TEXT"] = 32,
    ["CONTINUE_TEXT"] = 35
}
HUDPopupMessageMobile.COLOR = {
    ["BACKGROUND"] = {
        0,
        0,
        0,
        0.54
    },
    ["INPUT_ROW"] = {
        0.0075,
        0.0075,
        0.0075,
        0
    },
    ["SEPARATOR"] = {
        0.0382,
        0.0382,
        0.0382,
        1
    },
    ["TITLE"] = {
        1,
        1,
        1,
        1
    },
    ["TEXT"] = {
        0.9,
        0.9,
        0.9,
        1
    },
    ["CONTINUE_TEXT"] = {
        1,
        1,
        1,
        1
    },
    ["INPUT_GLYPH"] = {
        1,
        1,
        1,
        1
    }
}
HUDPopupMessageMobile.L10N_SYMBOL = {
    ["BUTTON_OK"] = "button_ok"
}