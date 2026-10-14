InfoDisplayKeyValueBox = {}
local InfoDisplayKeyValueBox_mt = Class(InfoDisplayKeyValueBox, InfoDisplayBox)
function InfoDisplayKeyValueBox.new(infoDisplay, uiScale, customMt)
    -- upvalues: (copy) InfoDisplayKeyValueBox_mt
    local self = InfoDisplayBox.new(infoDisplay, uiScale, customMt or InfoDisplayKeyValueBox_mt)
    self.lines = {}
    self.title = "Unknown Title"
    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.fieldInfo_middle", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgBottom = g_overlayManager:createOverlay("gui.fieldInfo_bottom", 0, 0, 0, 0)
    self.bgBottom:setColor(r, g, b, a)
    self.bgTop = g_overlayManager:createOverlay("gui.fieldInfo_top", 0, 0, 0, 0)
    self.bgTop:setColor(r, g, b, a)
    local r, g, b, a = unpack(HUD.COLOR.ACTIVE)
    self.warningIcon = g_overlayManager:createOverlay("gui.fieldInfo_warning", 0, 0, 0, 0)
    self.warningIcon:setColor(r, g, b, a)
    return self
end
function InfoDisplayKeyValueBox:delete()
    self.bgScale:delete()
    self.bgBottom:delete()
    self.bgTop:delete()
    self.warningIcon:delete()
end
function InfoDisplayKeyValueBox:storeScaledValues()
    local infoDisplay = self.infoDisplay
    local bgWidth, bgBottomHeight = infoDisplay:scalePixelValuesToScreenVector(340, 6)
    local bgTopHeight = infoDisplay:scalePixelToScreenHeight(6)
    self.bgBottom:setDimension(bgWidth, bgBottomHeight)
    self.bgTop:setDimension(bgWidth, bgTopHeight)
    self.bgScale:setDimension(bgWidth, 0)
    self.boxWidth = infoDisplay:scalePixelToScreenWidth(340)
    self.keyTextSize = infoDisplay:scalePixelToScreenHeight(14)
    self.valueTextSize = infoDisplay:scalePixelToScreenHeight(14)
    self.titleTextSize = infoDisplay:scalePixelToScreenHeight(15)
    self.titleToLineOffsetY = infoDisplay:scalePixelToScreenHeight(-24)
    self.lineToLineOffsetY = infoDisplay:scalePixelToScreenHeight(-21)
    self.lineHeight = infoDisplay:scalePixelToScreenHeight(21)
    self.titleAndBoxHeight = infoDisplay:scalePixelToScreenHeight(45)
    self.dashedLineHeight = g_pixelSizeY
    self.dashWidth = infoDisplay:scalePixelToScreenWidth(6)
    self.dashGapWidth = infoDisplay:scalePixelToScreenWidth(3)
    self.keyOffsetX = infoDisplay:scalePixelToScreenWidth(30)
    local iconWidth, iconHeight = infoDisplay:scalePixelValuesToScreenVector(30, -3)
    self.warningOffsetX = iconWidth
    self.warningOffsetY = iconHeight
    self.valueOffsetX = infoDisplay:scalePixelToScreenWidth(-14)
    local iconWidth, iconHeight = infoDisplay:scalePixelValuesToScreenVector(14, -27)
    self.titleOffsetX = iconWidth
    self.titleOffsetY = iconHeight
    self.titleMaxWidth = infoDisplay:scalePixelToScreenWidth(312)
    local iconWidth, iconHeight = infoDisplay:scalePixelValuesToScreenVector(20, 20)
    self.warningIcon:setDimension(iconWidth, iconHeight)
    self.warningIconOffsetX, self.warningIconOffsetY = infoDisplay:scalePixelValuesToScreenVector(10, -4)
end
function InfoDisplayKeyValueBox:draw(rightX, posY)
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
    for _, line in ipairs(self.lines) do
        if (leftX + self.warningIconOffsetX).isActive then
            local value = line.value
            local valueWidth
            if line.isWarning then
                setTextAlignment(RenderText.ALIGN_LEFT)
                setTextColor(HUD.COLOR.ACTIVE[1], HUD.COLOR.ACTIVE[2], HUD.COLOR.ACTIVE[3], HUD.COLOR.ACTIVE[4])
                setTextBold(true)
                linePosY = linePosY + self.warningOffsetY
                renderText(leftX + self.warningOffsetX, linePosY, self.keyTextSize, line.key)
                valueWidth = getTextWidth(self.keyTextSize, key)
                setTextBold(false)
                self.warningIcon:setPosition(line, linePosY + self.warningIconOffsetY)
                self.warningIcon:render()
            else
                setTextColor(1, 1, 1, 1)
                setTextAlignment(RenderText.ALIGN_LEFT)
                renderText(leftX + self.keyOffsetX, linePosY, self.keyTextSize, key)
                valueWidth = getTextWidth(self.keyTextSize, key)
            end
            if value ~= nil and value ~= "" then
                setTextColor(1, 1, 1, 1)
                setTextAlignment(RenderText.ALIGN_RIGHT)
                renderText(rightX + self.valueOffsetX, linePosY, self.valueTextSize, value)
                local valueWidth = getTextWidth(self.valueTextSize, value)
                local dashedLineStartX = keyPosX + valueWidth + 3 * g_pixelSizeX
                drawDashedLine(dashedLineStartX, linePosY, valuePosX - valueWidth - dashedLineStartX - 3 * g_pixelSizeX, self.dashedLineHeight, self.dashWidth, self.dashGapWidth, HUD.COLOR.INACTIVE[1], HUD.COLOR.INACTIVE[2], HUD.COLOR.INACTIVE[3], HUD.COLOR.INACTIVE[4], true)
            end
            linePosY = linePosY + self.lineToLineOffsetY
        end
    end
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    self.doShowNextFrame = false
    return rightX, self.bgTop.y + self.bgTop.height
end
function InfoDisplayKeyValueBox:canDraw()
    return self.doShowNextFrame
end
function InfoDisplayKeyValueBox:showNextFrame()
    self.doShowNextFrame = true
end
function InfoDisplayKeyValueBox:clear()
    for _, line in ipairs(self.lines) do
        line.isActive = false
    end
    self.currentLineIndex = 0
end
function InfoDisplayKeyValueBox:addLine(key, value, isWarning)
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
    line.isActive = true
end
function InfoDisplayKeyValueBox:setTitle(title)
    title = utf8ToUpper(title)
    if title ~= self.title then
        self.title = Utils.limitTextToWidth(title, self.titleTextSize, self.titleMaxWidth, false, "...")
    end
end