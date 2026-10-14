local data = nil
if WarningDisplay ~= nil then
    local old = g_currentMission.hud.warningDisplay
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible()
    }
    old:delete()
end
WarningDisplay = {}
WarningDisplay.MAX_NOTIFICATIONS = 5
local old = Class(WarningDisplay, HUDDisplay)
function WarningDisplay.new(customMt)
    -- upvalues: (copy) old
    local self = WarningDisplay:superClass().new(old)
    self.warnings = {}
    self.icon = g_overlayManager:createOverlay("gui.storeAttribute_info", 0, 0, 0, 0)
    self.icon:setColor(0.8, 0.8, 0.8, 0.7)
    return self
end
function WarningDisplay:delete()
    self.icon:delete()
end
function WarningDisplay:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, 0)
    self:setPosition(0.5 + offsetX, 0.45 + offsetY)
    self.maxTextWidth = self:scalePixelToScreenWidth(600)
    self.textSize = self:scalePixelToScreenHeight(16)
    local iconWidth, iconHeight = self:scalePixelValuesToScreenVector(20, 10)
    self.boxPaddingX = iconWidth
    self.boxPaddingY = iconHeight
    self.textOffsetY = self:scalePixelToScreenHeight(2)
    self.boxOffsetY = self:scalePixelToScreenHeight(6)
    self.iconTextOffsetX = self:scalePixelToScreenHeight(10)
    local iconWidth, iconHeight = self:scalePixelValuesToScreenVector(36, 36)
    self.icon:setDimension(iconWidth, iconHeight)
end
function WarningDisplay:update(dt)
    local i = #self.warnings
    for i = i, 1, -1 do
        local warning = self.warnings[i]
        warning.duration = warning.duration - dt
        if warning.duration < 0 then
            table.remove(self.warnings, i)
        end
    end
end
function WarningDisplay:draw()
    WarningDisplay:superClass().draw(self)
    if #self.warnings ~= 0 then
        setTextWrapWidth(self.maxTextWidth)
        local posX, posY = self:getPosition()
        local totalHeight = 0
        for _, warning in ipairs(self.warnings) do
            totalHeight = totalHeight + getTextHeight(self.textSize, warning.text) + 2 * self.boxPaddingY + self.boxOffsetY
        end
        local posY = posY + (totalHeight - self.boxOffsetY) * 0.5
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
        setTextColor(0.7796, 0.0578, 0.0612, 0.4 + 0.6 * IngameMap.alpha)
        for warning, text in ipairs(self.warnings) do
            local textHeight = text.text
            local textWidth = getTextWidth(textSize, textHeight)
            local textHeight = getTextHeight(textSize, textHeight)
            local boxWidth = textWidth + self.iconTextOffsetX + self.icon.width + 2 * self.boxPaddingX
            local boxHeight = math.max(textHeight + 2 * self.boxPaddingY, self.icon.height + 2 * self.boxPaddingY)
            drawFilledRectRound(posX - boxWidth * 0.5, posY - boxHeight * 0.5, boxWidth, boxHeight, 0.35, 0, 0, 0, 0.8)
            self.icon:setPosition(boxX + self.boxPaddingX, boxY + boxHeight * 0.5 - self.icon.height * 0.5)
            self.icon:render()
            renderText(self.icon.x + self.icon.width + self.iconTextOffsetX, boxY + boxHeight * 0.5 + self.textOffsetY, self.textSize, textHeight)
        end
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
        setTextColor(1, 1, 1, 1)
        setTextBold(false)
    end
end
function WarningDisplay:addWarning(text, duration, customIdentifier)
    duration = duration or 200
    local found = false
    for _, warning in ipairs(self.warnings) do
        if warning.text == text or customIdentifier ~= nil and warning.customIdentifier == customIdentifier then
            warning.text = text
            warning.duration = duration
            found = true
        end
    end
    if not found then
        table.insert(self.warnings, {
            ["text"] = text,
            ["duration"] = duration,
            ["customIdentifier"] = customIdentifier
        })
    end
end
if data ~= nil then
    local warningDisplay = WarningDisplay.new()
    warningDisplay:setScale(data.uiScale)
    warningDisplay:setVisible(data.isVisible)
    g_currentMission.hud.warningDisplay = warningDisplay
    g_currentMission.hud.displayComponents.warningDisplay = warningDisplay
    Logging.info("Reloaded WarningDisplay")
end