InfoDisplayKeyValueBoxMobile = {}
local InfoDisplayKeyValueBoxMobile_mt = Class(InfoDisplayKeyValueBoxMobile, InfoDisplayBox)
function InfoDisplayKeyValueBoxMobile.new(infoDisplay, uiScale)
    -- upvalues: (copy) InfoDisplayKeyValueBoxMobile_mt
    local self = InfoDisplayBox.new(infoDisplay, uiScale, InfoDisplayKeyValueBoxMobile_mt)
    self.displayComponents = {}
    self.cachedLines = {}
    self.activeLines = {}
    self.posYOffset = 160 * g_pixelSizeY * (g_screenHeight / g_referenceScreenHeight)
    return self
end
function InfoDisplayKeyValueBoxMobile:canDraw()
    return self.doShowNextFrame
end
function InfoDisplayKeyValueBoxMobile:getDisplayHeight()
    return 2 * self.listMarginHeight + #self.activeLines * self.rowHeight + self.labelTextOffsetY
end
function InfoDisplayKeyValueBoxMobile:draw(posX, posY)
    local _, rightInset = getSafeFrameInsets()
    posX = posX - rightInset
    local leftX = posX - self.boxWidth
    local y = posY + self.posYOffset
    drawFilledRectRound(leftX, y, self.boxWidth, 2 * self.listMarginHeight + #self.activeLines * self.rowHeight, self.uiScale, 0, 0, 0, 0.75)
    local y = y + self.listMarginHeight
    local leftX = leftX + self.leftTextOffsetX + self.listMarginWidth
    local i = #self.activeLines
    for i = i, 1, -1 do
        local line = self.activeLines[i]
        setTextBold(true)
        if line.accentuate then
            setTextColor(unpack(line.accentuateColor or InfoDisplayKeyValueBoxMobile.COLOR.TEXT_HIGHLIGHT))
        else
            setTextColor(1, 1, 1, 1)
        end
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(leftX, y + self.leftTextOffsetY, self.rowTextSize, line.key)
        setTextAlignment(RenderText.ALIGN_RIGHT)
        local maxWidth = self.boxWidth - self.leftTextOffsetX - self.listMarginWidth - self.rightTextOffsetX - self.listMarginWidth - 0.025 * self.boxWidth - getTextWidth(self.rowTextSize, line.key)
        setTextBold(false)
        local text = Utils.limitTextToWidth(line.value, self.rowTextSize, maxWidth, false, "...")
        renderText(posX - self.rightTextOffsetX - self.listMarginWidth, y + self.rightTextOffsetY, self.rowTextSize, text)
        if line.accentuate then
            setTextColor(unpack(InfoDisplayKeyValueBoxMobile.COLOR.TEXT_DEFAULT))
        end
        y = y + self.rowHeight
    end
    setTextAlignment(RenderText.ALIGN_LEFT)
    self.doShowNextFrame = false
end
function InfoDisplayKeyValueBoxMobile:clear()
    local i = #self.activeLines
    for i = i, 1, -1 do
        self.cachedLines[#self.cachedLines + 1] = self.activeLines[i]
        self.activeLines[i] = nil
    end
end
function InfoDisplayKeyValueBoxMobile:setTitle(title) end
function InfoDisplayKeyValueBoxMobile.textSizeToFit(_, baseSize, text, maxWidth, minSize)
    if minSize == nil then
        minSize = baseSize / 2
    end
    setTextWrapWidth(maxWidth)
    local lengthWithNoLineLimit = getTextLength(baseSize, text, 99999)
    while getTextLength(baseSize, text, 1) < lengthWithNoLineLimit do
        baseSize = baseSize - baseSize * 0.05
        if baseSize <= minSize then
            baseSize = baseSize + baseSize * 0.05
            break
        end
    end
    setTextWrapWidth(0)
    return baseSize
end
function InfoDisplayKeyValueBoxMobile:addLine(key, value, accentuate, accentuateColor)
    local numCached = #self.cachedLines
    local line
    if numCached > 0 then
        line = self.cachedLines[numCached]
        self.cachedLines[numCached] = nil
    else
        line = {}
    end
    line.key = key
    line.value = value or ""
    line.accentuate = accentuate
    line.accentuateColor = accentuateColor
    self.activeLines[#self.activeLines + 1] = line
end
function InfoDisplayKeyValueBoxMobile:showNextFrame()
    self.doShowNextFrame = true
end
function InfoDisplayKeyValueBoxMobile:setScale(uiScale)
    self.uiScale = uiScale
    self:storeScaledValues()
end
function InfoDisplayKeyValueBoxMobile:storeScaledValues()
    local scale = self.uiScale
    self.boxWidth = 500 * scale * g_aspectScaleX / g_referenceScreenWidth
    self.rowTextSize = HUDElement.TEXT_SIZE.DEFAULT_TEXT_MOBILE * scale * g_aspectScaleY / g_referenceScreenHeight
    self.labelTextOffsetX = 0 * scale * g_aspectScaleX / g_referenceScreenWidth
    self.labelTextOffsetY = 3 * scale * g_aspectScaleY / g_referenceScreenHeight
    self.leftTextOffsetX = 0 * scale * g_aspectScaleX / g_referenceScreenWidth
    self.leftTextOffsetY = 6 * scale * g_aspectScaleY / g_referenceScreenHeight
    self.rightTextOffsetX = 0 * scale * g_aspectScaleX / g_referenceScreenWidth
    self.rightTextOffsetY = 6 * scale * g_aspectScaleY / g_referenceScreenHeight
    self.rowWidth = 450 * scale * g_aspectScaleX / g_referenceScreenWidth
    self.rowHeight = 40 * scale * g_aspectScaleY / g_referenceScreenHeight
    self.listMarginWidth = 25 * scale * g_aspectScaleX / g_referenceScreenWidth
    self.listMarginHeight = 15 * scale * g_aspectScaleY / g_referenceScreenHeight
end
InfoDisplayKeyValueBoxMobile.COLOR = {
    ["TEXT_DEFAULT"] = {
        1,
        1,
        1,
        1
    },
    ["TEXT_HIGHLIGHT"] = {
        0.0003,
        0.5647,
        0.9822,
        1
    },
    ["SEPARATOR"] = {
        1,
        1,
        1,
        0.2
    }
}