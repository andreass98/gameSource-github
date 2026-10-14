GlyphButtonOverlay = {}
local GlyphButtonOverlay_mt = Class(GlyphButtonOverlay, ButtonOverlay)
function GlyphButtonOverlay.new(customMt)
    -- upvalues: (copy) GlyphButtonOverlay_mt
    return ButtonOverlay.new(GlyphButtonOverlay_mt)
end
function GlyphButtonOverlay:renderButton(glyphButtons, isComboButton, ignoreComboButtons, posX, posY, height, _, clipX1, clipY1, clipX2, clipY2, customOffsetLeft, customButtonInputText)
    local width, widthNoOffset = self:getButtonWidth(glyphButtons, isComboButton, ignoreComboButtons, height, customOffsetLeft or 0, customButtonInputText)
    self:renderBackground(posX, posY, width, height, clipX1, clipY1, clipX2, clipY2)
    local buttonPosX = posX + width - widthNoOffset + height * self.leftRightPaddingHeightRatio / g_screenAspectRatio * 0.5
    for k, button in ipairs(glyphButtons) do
        if not ignoreComboButtons or isComboButton[k] == false then
            local buttonWidth = button.width * (height / button.height)
            button:renderCustom(buttonPosX, posY, buttonWidth, height, self.r, self.g, self.b, self.a)
            buttonPosX = buttonPosX + buttonWidth + g_pixelSizeX * 3
        end
    end
    if customButtonInputText ~= nil then
        setTextBold(true)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
        setTextAlignment(RenderText.ALIGN_LEFT)
        if clipX1 ~= nil then
            setTextClipArea(clipX1, clipY1, clipX2, clipY2)
        end
        setTextColor(0.5, 0.5, 0.5, 1)
        local textSize = height * self.textSizeFactor
        renderText(self.buttonScaleOverlay.x, posY + height * 0.5 + textSize * self.textYOffsetFactor, textSize, customButtonInputText)
        if clipX1 ~= nil then
            setTextClipArea(0, 0, 1, 1)
        end
        setTextBold(false)
        setTextColor(1, 1, 1, 1)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    end
    return self.buttonRightOverlay.x + self.buttonRightOverlay.width - self.buttonLeftOverlay.x
end
function GlyphButtonOverlay:getButtonWidth(glyphButtons, isComboButton, ignoreComboButtons, height, customOffsetLeft, customButtonInputText)
    local width = 0
    for k, button in ipairs(glyphButtons) do
        if not ignoreComboButtons or isComboButton[k] == false then
        end
    end
    local customOffset = customOffsetLeft or 0
    if customButtonInputText ~= nil then
        setTextBold(true)
        local totalWidthNoOffset = utf8ToUpper((tostring(customButtonInputText)))
        customOffset = customOffset + getTextWidth(height * self.textSizeFactor, totalWidthNoOffset)
        setTextBold(false)
    end
    local totalWidthNoOffset = width + height * self.leftRightPaddingHeightRatio / g_screenAspectRatio
    local k = totalWidthNoOffset + customOffset
    if self.minWidth ~= nil then
        totalWidthNoOffset = math.max(totalWidthNoOffset, self.minWidth)
        k = math.max(k, self.minWidth)
    end
    return k, totalWidthNoOffset
end