local wasActive = false
local oldUIScale = nil
if IntroductionHelpHUDUtil ~= nil then
    IntroductionHelpHUDUtil.delete()
    oldUIScale = IntroductionHelpHUDUtil.uiScale
    wasActive = true
end
IntroductionHelpHUDUtil = {}
IntroductionHelpHUDUtil.ARROW_POSITION_TOP = 1
IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM = 2
IntroductionHelpHUDUtil.ARROW_POSITION_LEFT = 3
IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT = 4
function IntroductionHelpHUDUtil.init()
    local self = IntroductionHelpHUDUtil
    local arrowLeft = g_overlayManager:createOverlay("gui.tourdialogue_side", 0, 0, 0, 0)
    arrowLeft:setColor(0.8148, 0.1779, 0.0052, 1)
    local arrowRight = g_overlayManager:createOverlay("gui.tourdialogue_side", 0, 0, 0, 0)
    arrowRight:setColor(0.8148, 0.1779, 0.0052, 1)
    local arrowTop = g_overlayManager:createOverlay("gui.tourdialogue_top", 0, 0, 0, 0)
    arrowTop:setColor(0.8148, 0.1779, 0.0052, 1)
    local arrowBottom = g_overlayManager:createOverlay("gui.tourdialogue_top", 0, 0, 0, 0)
    arrowBottom:setColor(0.8148, 0.1779, 0.0052, 1)
    self.arrows = {}
    self.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_LEFT] = arrowLeft
    self.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT] = arrowRight
    self.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_TOP] = arrowTop
    self.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM] = arrowBottom
    local arrowSmallLeft = g_overlayManager:createOverlay("gui.tourdialogue_arrow", 0, 0, 0, 0)
    local arrowSmallRight = g_overlayManager:createOverlay("gui.tourdialogue_arrow", 0, 0, 0, 0)
    local arrowSmallTop = g_overlayManager:createOverlay("gui.tourdialogue_arrow", 0, 0, 0, 0)
    local arrowSmallBottom = g_overlayManager:createOverlay("gui.tourdialogue_arrow", 0, 0, 0, 0)
    self.smallArrows = {}
    self.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_LEFT] = arrowSmallLeft
    self.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT] = arrowSmallRight
    self.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_TOP] = arrowSmallTop
    self.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM] = arrowSmallBottom
    self.bgScale = g_overlayManager:createOverlay("gui.tourdialogue_boxMiddle", 0, 0, 0, 0)
    self.bgScale:setColor(0.8148, 0.1779, 0.0052, 1)
    self.bgLeft = g_overlayManager:createOverlay("gui.tourdialogue_boxLeft", 0, 0, 0, 0)
    self.bgLeft:setColor(0.8148, 0.1779, 0.0052, 1)
    self.bgRight = g_overlayManager:createOverlay("gui.tourdialogue_boxRight", 0, 0, 0, 0)
    self.bgRight:setColor(0.8148, 0.1779, 0.0052, 1)
    self.continueText = g_i18n:getText("introduction_continueText")
    self.continueTextGamepad = g_i18n:getText("introduction_continueTextGamepad") .. " "
    self.glyphElement = InputGlyphElement.new(g_inputDisplayManager, 0, 0)
    self.glyphElement:setAction(InputAction.INTRODUCTION_HELP_SKIP)
    self.glyphElement:setButtonGlyphColor({
        0.22323,
        0.40724,
        0.00368,
        1
    })
    return self
end
function IntroductionHelpHUDUtil.delete()
    local self = IntroductionHelpHUDUtil
    for _, arrow in pairs(self.arrows) do
        arrow:delete()
    end
    for _, arrow in pairs(self.smallArrows) do
        arrow:delete()
    end
    self.bgScale:delete()
    self.bgLeft:delete()
    self.bgRight:delete()
    self.glyphElement:delete()
end
function IntroductionHelpHUDUtil.setScale(uiScale)
    local self = IntroductionHelpHUDUtil
    self.uiScale = uiScale
    local bgLeftWidth, bgHeight = getNormalizedScreenValues(10, 37)
    local bgRightWidth, _ = getNormalizedScreenValues(10, 0)
    self.bgLeft:setDimension(bgLeftWidth * uiScale, bgHeight * uiScale)
    self.bgScale:setDimension(0, bgHeight * uiScale)
    self.bgRight:setDimension(bgRightWidth * uiScale, bgHeight * uiScale)
    local arrowSideWidth, arrowSideHeight = getNormalizedScreenValues(5, 29)
    self.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_LEFT]:setDimension(arrowSideWidth * uiScale, arrowSideHeight * uiScale)
    local rightArrow = self.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT]
    rightArrow:setDimension(arrowSideWidth * uiScale, arrowSideHeight * uiScale)
    rightArrow:setRotation(3.141592653589793, rightArrow.width * 0.5, rightArrow.height * 0.5)
    local arrowTopWidth, arrowTopHeight = getNormalizedScreenValues(46, 7)
    self.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_TOP]:setDimension(arrowTopWidth * uiScale, arrowTopHeight * uiScale)
    local bottomArrow = self.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM]
    bottomArrow:setDimension(arrowTopWidth * uiScale, arrowTopHeight * uiScale)
    bottomArrow:setRotation(3.141592653589793, bottomArrow.width * 0.5, bottomArrow.height * 0.5)
    local arrowSmallWidth, arrowSmallHeight = getNormalizedScreenValues(6, 6)
    for _, arrow in pairs(self.smallArrows) do
        arrow:setDimension(arrowSmallWidth * uiScale, arrowSmallHeight * uiScale)
    end
    local bottomSmallArrow = self.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM]
    bottomSmallArrow:setRotation(3.141592653589793, bottomSmallArrow.width * 0.5, bottomSmallArrow.height * 0.5)
    local leftSmallArrow = self.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_LEFT]
    leftSmallArrow:setRotation(1.5707963267948966, leftSmallArrow.width * 0.5, leftSmallArrow.height * 0.5)
    local rightSmallArrow = self.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT]
    rightSmallArrow:setRotation(-1.5707963267948966, rightSmallArrow.width * 0.5, rightSmallArrow.height * 0.5)
    self.smallArrowsOffset = {}
    self.smallArrowsOffset[IntroductionHelpHUDUtil.ARROW_POSITION_TOP] = { getNormalizedScreenValues(20, -5) }
    self.smallArrowsOffset[IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM] = { getNormalizedScreenValues(20, 5) }
    self.smallArrowsOffset[IntroductionHelpHUDUtil.ARROW_POSITION_LEFT] = { getNormalizedScreenValues(6, 12) }
    self.smallArrowsOffset[IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT] = { getNormalizedScreenValues(-6, 12) }
    local _, arrow = getNormalizedScreenValues(0, 14)
    self.textSize = arrow * uiScale
    local textOffsetX, textOffsetY = getNormalizedScreenValues(15, 13)
    self.textOffsetX = textOffsetX * uiScale
    self.textOffsetY = textOffsetY * uiScale
    local _, messageTextSize = getNormalizedScreenValues(20, 0)
    self.borderX = _
    self.borderY = messageTextSize
    local _, messageTextSize = getNormalizedScreenValues(0, 14)
    self.messageTextSize = messageTextSize * uiScale
    local messageTextPaddingX, messageTextPaddingY = getNormalizedScreenValues(15, 15)
    self.messageTextPaddingX = messageTextPaddingX * uiScale
    self.messageTextPaddingY = messageTextPaddingY * uiScale
    local messageTextOffsetX, messageTextOffsetY = getNormalizedScreenValues(0, 2)
    self.messageTextOffsetX = messageTextOffsetX * uiScale
    self.messageTextOffsetY = messageTextOffsetY * uiScale
    local boxMaxWidth, _ = getNormalizedScreenValues(800, 0)
    self.messageBoxMaxWidth = boxMaxWidth * uiScale
    local _, messageTextToTextOffsetY = getNormalizedScreenValues(0, 25)
    self.messageTextToTextOffsetY = messageTextToTextOffsetY * uiScale
    local glyphOffsetX, _ = getNormalizedScreenValues(10, 0)
    self.glyphOffsetX = glyphOffsetX * uiScale
    local glyphWidth, glyphHeight = getNormalizedScreenValues(35, 35)
    self.glyphElement:setBaseSize(glyphWidth, glyphHeight)
end
function IntroductionHelpHUDUtil.drawHelp(x, y, text, arrowPosition)
    if not g_gui:getIsGuiVisible() then
        local self = IntroductionHelpHUDUtil
        local arrow = self.arrows[arrowPosition]
        local smallArrow = self.smallArrows[arrowPosition]
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(true)
        local textSize = utf8ToUpper(text)
        local textSize = self.textSize
        local bgWidth = getTextWidth(textSize, textSize) + 2 * self.textOffsetX
        local arrowX = nil
        local arrowY = nil
        local bgPosY
        if arrowPosition == IntroductionHelpHUDUtil.ARROW_POSITION_TOP then
            arrowX = math.clamp(x - arrow.width * 0.5, g_hudAnchorLeft, g_hudAnchorRight - arrow.width)
            y = y - arrow.height
            x = math.clamp(x - bgWidth * 0.5, minX, maxX - bgWidth)
            bgPosY = y - self.bgLeft.height
        elseif arrowPosition == IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM then
            arrowX = math.clamp(x - arrow.width * 0.5, minX, maxX - arrow.width)
            x = math.clamp(x - bgWidth * 0.5, minX, maxX - bgWidth)
            bgPosY = y + arrow.height
        elseif arrowPosition == IntroductionHelpHUDUtil.ARROW_POSITION_LEFT then
            arrowX = math.clamp(x, minX, maxX - bgWidth - arrow.width)
            bgPosY = y - bgHeight * 0.5
            y = y - arrow.height * 0.5
        elseif arrowPosition == IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT then
            arrowX = math.clamp(x, minX + bgWidth, maxX - arrow.width)
            bgPosY = y - bgHeight * 0.5
            y = y - arrow.height * 0.5
        else
            bgPosY = y
        end
        self.bgLeft:setPosition(x, bgPosY)
        self.bgLeft:render()
        self.bgScale:setDimension(bgWidth - self.bgLeft.width - self.bgRight.width, nil)
        self.bgScale:setPosition(self.bgLeft.x + self.bgLeft.width, self.bgLeft.y)
        self.bgScale:render()
        self.bgRight:setPosition(self.bgScale.x + self.bgScale.width, self.bgScale.y)
        self.bgRight:render()
        arrow:setPosition(arrowX, y)
        arrow:render()
        local offset = self.smallArrowsOffset[arrowPosition]
        smallArrow:setPosition(arrowX + offset[1], y + offset[2])
        smallArrow:render()
        setTextColor(1, 1, 1, 1)
        renderText(self.bgLeft.x + self.textOffsetX, self.bgScale.y + self.textOffsetY, textSize, textSize)
        setTextColor(1, 1, 1, 1)
        setTextBold(false)
    end
end
function IntroductionHelpHUDUtil.drawMessage(text, glyphElement)
    if not g_gui:getIsGuiVisible() then
        local self = IntroductionHelpHUDUtil
        local messageTextPaddingX = self.messageTextPaddingX
        local messageTextPaddingY = self.messageTextPaddingY
        local glyphWidth = 0
        local glyphOffsetX = self.glyphOffsetX
        if glyphElement ~= nil then
            glyphWidth = glyphElement:getWidth()
        end
        local textSize = self.messageTextSize
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
        setTextColor(1, 1, 1, 1)
        setTextBold(false)
        setTextWrapWidth(self.messageBoxMaxWidth - 2 * messageTextPaddingX - glyphWidth)
        local height, _ = getTextHeight(textSize, text)
        local width = getTextWidth(textSize, text)
        local boxPosY = 0.9 - messageTextPaddingY - height * 0.5
        local boxHeight = height + 2 * messageTextPaddingY
        local color = HUD.COLOR.BACKGROUND_DARK
        drawFilledRectRound(0.5 - messageTextPaddingX - width * 0.5 - glyphWidth * 0.5 - glyphOffsetX * 0.5, boxPosY, width + 2 * messageTextPaddingX + glyphWidth + glyphOffsetX, boxHeight, 0.5, color[1], color[2], color[3], color[4])
        renderText(0.5 - glyphWidth * 0.5, 0.9 + self.messageTextOffsetY, textSize, text)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
        setTextWrapWidth(0)
        if glyphElement ~= nil then
            glyphElement:setPosition(0.5 + width * 0.5 - glyphWidth * 0.5 + glyphOffsetX, boxPosY + (boxHeight - glyphElement:getHeight()) * 0.5)
            glyphElement:draw()
        end
    end
end
function IntroductionHelpHUDUtil.drawSkipMessage(text)
    if not g_gui:getIsGuiVisible() then
        local self = IntroductionHelpHUDUtil
        local skipText = self.continueText
        local messageTextPaddingX = self.messageTextPaddingX
        local messageTextPaddingY = self.messageTextPaddingY
        local messageTextSize = self.messageTextSize
        local glyphElement = nil
        local glyphWidth = 0
        if g_inputBinding:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD then
            skipText = self.continueTextGamepad
            glyphElement = self.glyphElement
        end
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
        setTextColor(1, 1, 1, 1)
        setTextBold(true)
        setTextWrapWidth(self.messageBoxMaxWidth - 2 * messageTextPaddingX)
        local textHeight = 0
        local skipTextWidth = getTextWidth(messageTextSize, skipText)
        local skipTextHeight, _ = getTextHeight(messageTextSize, skipText)
        local boxWidth
        if glyphElement == nil then
            boxWidth = skipTextWidth
        else
            glyphWidth = glyphElement:getWidth()
            boxWidth = skipTextWidth + glyphWidth + self.glyphOffsetX
        end
        local boxHeight
        if text == nil then
            boxHeight = skipTextHeight
        else
            local textWidth = getTextWidth(messageTextSize, text)
            local color
            textHeight, color = getTextHeight(messageTextSize, text)
            boxWidth = math.max(boxWidth, textWidth)
            boxHeight = skipTextHeight + textHeight + self.messageTextToTextOffsetY
        end
        local boxWidth = boxWidth + 2 * messageTextPaddingX
        local boxHeight = boxHeight + 2 * messageTextPaddingY
        local textWidth = 0.5 - boxWidth * 0.5
        local boxPosY = 0.55 - boxHeight * 0.5
        local color = HUD.COLOR.BACKGROUND_DARK
        drawFilledRectRound(textWidth, boxPosY, boxWidth, boxHeight, 0.5, color[1], color[2], color[3], color[4])
        if text ~= nil then
            renderText(0.5, boxPosY + boxHeight - messageTextPaddingY - textHeight * 0.5, messageTextSize, text)
        end
        setTextBold(false)
        local textPosY = 0.5 - glyphWidth * 0.5
        renderText(textPosY, boxPosY + messageTextPaddingY + skipTextHeight * 0.5 + self.messageTextOffsetY, messageTextSize, skipText)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
        setTextWrapWidth(0)
        if glyphElement ~= nil then
            glyphElement:setPosition(textPosY + skipTextWidth * 0.5, boxPosY + (boxHeight - glyphElement:getHeight()) * 0.5)
            glyphElement:draw()
        end
    end
end
if wasActive then
    IntroductionHelpHUDUtil.init()
    IntroductionHelpHUDUtil.setScale(oldUIScale)
    log("Reloaded IntroductionHelpHUDUtil")
end