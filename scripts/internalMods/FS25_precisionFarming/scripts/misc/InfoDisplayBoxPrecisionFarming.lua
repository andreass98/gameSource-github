InfoDisplayBoxPrecisionFarming = {}
local InfoDisplayBoxPrecisionFarming_mt = Class(InfoDisplayBoxPrecisionFarming, InfoDisplayKeyValueBox)
function InfoDisplayBoxPrecisionFarming.new(infoDisplay, uiScale)
    -- upvalues: (copy) InfoDisplayBoxPrecisionFarming_mt
    return InfoDisplayKeyValueBox.new(infoDisplay, uiScale, InfoDisplayBoxPrecisionFarming_mt)
end
function InfoDisplayBoxPrecisionFarming:draw(rightX, posY)
    local leftX = rightX - self.boxWidth
    local height = self.titleAndBoxHeight
    for _, line in ipairs(self.lines) do
        if line.isActive then
            height = height + self.lineHeight
            if line.isWarning then
                height = height + math.abs(self.warningOffsetY)
            end
        end
    end
    self.bgScale:setDimension(nil, height - self.bgBottom.height - self.bgTop.height)
    self.bgBottom:setPosition(leftX, posY)
    self.bgBottom:render()
    self.bgScale:setPosition(leftX, self.bgBottom.y + self.bgBottom.height)
    self.bgScale:render()
    self.bgTop:setPosition(leftX, self.bgScale.y + self.bgScale.height)
    self.bgTop:render()
    local textPosY = self.bgTop.y + self.bgTop.height + self.titleOffsetY
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(leftX + self.titleOffsetX, textPosY, self.titleTextSize, self.title)
    setTextBold(false)
    local linePosY = textPosY + self.titleToLineOffsetY
    local activeColor = HUD.COLOR.ACTIVE
    for _, line in ipairs(self.lines) do
        if (rightX + self.valueOffsetX).isActive then
            local key = line.key
            local value = line.value
            local isWarning = line.isWarning
            local customColor = line.customColor
            local r = 1
            local g = 1
            local b = 1
            local a = 1
            if isWarning then
                r = activeColor[1]
                g = activeColor[2]
                b = activeColor[3]
                a = activeColor[4]
            end
            if customColor ~= nil then
                r = customColor[1]
                g = customColor[2]
                b = customColor[3]
            end
            if isWarning then
                self.warningIcon:setPosition(leftX + self.warningIconOffsetX, linePosY + self.warningIconOffsetY)
                self.warningIcon:setColor(r, g, b)
                self.warningIcon:render()
            end
            setTextColor(r, g, b, a)
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(leftX + self.keyOffsetX, linePosY, self.keyTextSize, key)
            local keyWidth = getTextWidth(self.keyTextSize, key)
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText(line, linePosY, self.valueTextSize, value)
            local valueWidth = getTextWidth(self.valueTextSize, value)
            local dashedLineStartX = keyPosX + keyWidth + 3 * g_pixelSizeX
            drawDashedLine(dashedLineStartX, linePosY, line - valueWidth - dashedLineStartX - 3 * g_pixelSizeX, self.dashedLineHeight, self.dashWidth, self.dashGapWidth, HUD.COLOR.INACTIVE[1], HUD.COLOR.INACTIVE[2], HUD.COLOR.INACTIVE[3], HUD.COLOR.INACTIVE[4], true)
            linePosY = linePosY + self.lineToLineOffsetY
        end
    end
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    self.doShowNextFrame = false
    return rightX, self.bgTop.y + self.bgTop.height
end
function InfoDisplayBoxPrecisionFarming:addLine(key, value, isWarning, customColor)
    self.currentLineIndex = self.currentLineIndex + 1
    local line = self.lines[self.currentLineIndex]
    if line == nil then
        table.addElement(self.lines, {
            ["key"] = "",
            ["value"] = "",
            ["isWarning"] = false
        })
    end
    line.key = key
    line.value = value or ""
    line.isWarning = isWarning
    line.customColor = customColor
    line.isActive = true
end