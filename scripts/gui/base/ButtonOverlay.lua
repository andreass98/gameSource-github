ButtonOverlay = {}
local ButtonOverlay_mt = Class(ButtonOverlay)
function ButtonOverlay.new(customMt)
    -- upvalues: (copy) ButtonOverlay_mt
    local self = setmetatable({}, customMt or ButtonOverlay_mt)
    self.textSizeFactor = 0.55
    self.textYOffsetFactor = 0.17
    self.buttonScaleOverlay = g_overlayManager:createOverlay("gui.button_middle", 0, 0, 0, 0)
    self.buttonLeftOverlay = g_overlayManager:createOverlay("gui.button_left", 0, 0, 0, 0)
    self.buttonRightOverlay = g_overlayManager:createOverlay("gui.button_right", 0, 0, 0, 0)
    self.buttonLeftWidthToHeightRatio = 0.24
    self.leftRightPaddingHeightRatio = 0.48
    self:setColor(1, 1, 1, 1)
    self.minWidth = nil
    self.debugEnabled = nil
    return self
end
function ButtonOverlay:delete()
    if self.buttonScaleOverlay ~= nil then
        self.buttonScaleOverlay:delete()
        self.buttonScaleOverlay = nil
    end
    if self.buttonLeftOverlay ~= nil then
        self.buttonLeftOverlay:delete()
        self.buttonLeftOverlay = nil
    end
    if self.buttonRightOverlay ~= nil then
        self.buttonRightOverlay:delete()
        self.buttonRightOverlay = nil
    end
end
function ButtonOverlay:setColor(r, g, b, a, r2, g2, b2, a2)
    self.r = r or self.r
    self.g = g or self.g
    self.b = b or self.b
    self.a = a or self.a
    self.r2 = r2 or (self.r2 or r)
    self.g2 = g2 or (self.g2 or g)
    self.b2 = b2 or (self.b2 or b)
    self.a2 = a2 or (self.a2 or a)
    if self.buttonScaleOverlay ~= nil then
        self.buttonScaleOverlay:setColor(self.r2, self.g2, self.b2, self.a2)
    end
    if self.buttonLeftOverlay ~= nil then
        self.buttonLeftOverlay:setColor(self.r2, self.g2, self.b2, self.a2)
    end
    if self.buttonRightOverlay ~= nil then
        self.buttonRightOverlay:setColor(self.r2, self.g2, self.b2, self.a2)
    end
end
function ButtonOverlay:renderBackground(posX, posY, width, height, clipX1, clipY1, clipX2, clipY2)
    local leftRightWidth = height * self.buttonLeftWidthToHeightRatio / g_screenAspectRatio
    self.buttonLeftOverlay:setDimension(leftRightWidth, height)
    self.buttonScaleOverlay:setDimension(width - 2 * leftRightWidth, height)
    self.buttonRightOverlay:setDimension(leftRightWidth, height)
    self.buttonLeftOverlay:setPosition(posX, posY)
    self.buttonScaleOverlay:setPosition(self.buttonLeftOverlay.x + self.buttonLeftOverlay.width, posY)
    self.buttonRightOverlay:setPosition(self.buttonScaleOverlay.x + self.buttonScaleOverlay.width, posY)
    self.buttonLeftOverlay:render(clipX1, clipY1, clipX2, clipY2)
    self.buttonScaleOverlay:render(clipX1, clipY1, clipX2, clipY2)
    self.buttonRightOverlay:render(clipX1, clipY1, clipX2, clipY2)
end
function ButtonOverlay:renderButton(buttonText, posX, posY, height, colorText, clipX1, clipY1, clipX2, clipY2, customOffsetLeft, customButtonInputText)
    local width = utf8ToUpper((tostring(buttonText)))
    local width, widthNoOffset = self:getButtonWidth(width, height, customOffsetLeft or 0, customButtonInputText)
    self:renderBackground(posX, posY, width, height, clipX1, clipY1, clipX2, clipY2)
    local textSize = height * self.textSizeFactor
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
    if clipX1 ~= nil then
        setTextClipArea(clipX1, clipY1, clipX2, clipY2)
    end
    if colorText then
        setTextColor(self.r, self.g, self.b, self.a)
    else
        setTextColor(1, 1, 1, self.a)
    end
    local textPosY = posY + height * 0.5 + textSize * self.textYOffsetFactor
    renderText(self.buttonRightOverlay.x + self.buttonRightOverlay.width - widthNoOffset * 0.5, textPosY, textSize, width)
    setTextAlignment(RenderText.ALIGN_LEFT)
    if customButtonInputText ~= nil then
        setTextColor(0.5, 0.5, 0.5, 1)
        renderText(self.buttonScaleOverlay.x, textPosY, textSize, customButtonInputText)
    end
    if clipX1 ~= nil then
        setTextClipArea(0, 0, 1, 1)
    end
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    local totalWidth = self.buttonRightOverlay.x + self.buttonRightOverlay.width - self.buttonLeftOverlay.x
    if self.debugEnabled or g_uiDebugEnabled then
        setOverlayColor(GuiElement.debugOverlay, 1, 0, 1, 0.5)
        renderOverlay(GuiElement.debugOverlay, posX - g_pixelSizeX, posY - g_pixelSizeY, totalWidth + 2 * g_pixelSizeX, g_pixelSizeY)
        renderOverlay(GuiElement.debugOverlay, posX - g_pixelSizeX, posY + height, totalWidth + 2 * g_pixelSizeX, g_pixelSizeY)
        renderOverlay(GuiElement.debugOverlay, posX - g_pixelSizeX, posY, g_pixelSizeX, height)
        renderOverlay(GuiElement.debugOverlay, posX + totalWidth, posY, g_pixelSizeX, height)
    end
    return totalWidth
end
function ButtonOverlay:getButtonWidth(buttonText, height, customOffsetLeft, customButtonInputText)
    local textSize = height * self.textSizeFactor
    setTextBold(true)
    local textWidth = utf8ToUpper((tostring(buttonText)))
    local textWidth = getTextWidth(textSize, textWidth)
    local textWidthCustom = 0
    if customButtonInputText ~= nil then
        textWidthCustom = getTextWidth(textSize, customButtonInputText)
    end
    setTextBold(false)
    local widthNoOffset = textWidth + 2 * (height * self.leftRightPaddingHeightRatio / g_screenAspectRatio)
    local width = widthNoOffset + (customOffsetLeft or 0) + textWidthCustom
    if self.minWidth ~= nil then
        width = math.max(width, self.minWidth)
        widthNoOffset = math.max(widthNoOffset, self.minWidth)
    end
    return width, widthNoOffset
end
function ButtonOverlay:setMinWidth(width)
    self.minWidth = width
end