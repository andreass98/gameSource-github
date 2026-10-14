local data = nil
if ContextActionDisplay ~= nil then
    local old = g_currentMission.hud.contextActionDisplay
    data = {
        ["uiScale"] = old.uiScale,
        ["isVisible"] = old:getVisible()
    }
    old:delete()
end
ContextActionDisplay = {}
ContextActionDisplay.CONTEXT_ICON = {
    ["ATTACH"] = "attach",
    ["FUEL"] = "fuel",
    ["TIP"] = "tip",
    ["FILL_BOWL"] = "fillBowl"
}
ContextActionDisplay.MIN_DISPLAY_DURATION = 100
local old = Class(ContextActionDisplay, HUDDisplay)
function ContextActionDisplay.new(customMt)
    -- upvalues: (copy) old
    local self = ContextActionDisplay:superClass().new(old)
    self.slicesIds = {}
    self.slicesIds[ContextActionDisplay.CONTEXT_ICON.ATTACH] = "gui.contextAction_icon_connect"
    self.slicesIds[ContextActionDisplay.CONTEXT_ICON.FUEL] = "gui.contextAction_icon_fuel"
    self.slicesIds[ContextActionDisplay.CONTEXT_ICON.TIP] = "gui.contextAction_icon_dump"
    self.slicesIds[ContextActionDisplay.CONTEXT_ICON.FILL_BOWL] = "gui.contextAction_icon_animalFood"
    self.glyphButtonOverlay = GlyphButtonOverlay.new()
    self.glyphButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.8)
    self.keyButtonOverlay = ButtonOverlay.new()
    self.keyButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.8)
    local r, g, b, a = unpack(HUD.COLOR.ACTIVE)
    self.lastSliceId = self.slicesIds[ContextActionDisplay.CONTEXT_ICON.ATTACH]
    self.iconOverlay = g_overlayManager:createOverlay(self.lastSliceId, 0, 0, 0, 0)
    self.iconOverlay:setColor(r, g, b, a)
    self.controls = nil
    self.contextPriority = -math.huge
    self.text = nil
    self.displayTime = 0
    return self
end
function ContextActionDisplay:delete()
    self.glyphButtonOverlay:delete()
    self.keyButtonOverlay:delete()
    self.iconOverlay:delete()
end
function ContextActionDisplay:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, 0)
    self:setPosition(0.5 + offsetX, g_hudAnchorBottom + offsetY)
    local iconWidth, iconHeight = self:scalePixelValuesToScreenVector(64, 48)
    self.iconOverlay:setDimension(iconWidth, iconHeight)
    self.iconOffsetX, self.iconOffsetY = self:scalePixelValuesToScreenVector(5, -4)
    self.titleTextSize = self:scalePixelToScreenHeight(15)
    self.titleTextOffsetY = self:scalePixelToScreenHeight(5)
    self.textSize = self:scalePixelToScreenHeight(26)
    self.textOffsetX, self.textOffsetY = self:scalePixelValuesToScreenVector(10, 1)
    self.textMaxWidth = self:scalePixelToScreenWidth(500)
    self.buttonOffsetY = self:scalePixelToScreenHeight(8)
    self.buttonHeight = self:scalePixelToScreenHeight(25)
    self.keyButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
    self.glyphButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
end
function ContextActionDisplay:updateControls()
    if self.contextAction ~= nil then
        self.controls = g_inputDisplayManager:getControllerSymbolOverlays(self.contextAction, "", "", false)
    end
end
function ContextActionDisplay:update(dt)
    ContextActionDisplay:superClass().update(self, dt)
    if self:getVisible() then
        self.displayTime = self.displayTime - dt
        if self.displayTime < 0 then
            self:setVisible(false)
            self:resetContext()
        end
    end
end
function ContextActionDisplay:draw()
    if not g_currentMission.hud.ingameMessage:getVisible() then
        local controls = self.controls
        if controls ~= nil then
            local buttons = controls.buttons
            local width = self.iconOverlay.width + self.iconOffsetX + self.textOffsetX
            local text = self.text
            local totalButtonWidth = 0
            if #buttons > 0 then
                totalButtonWidth = self.glyphButtonOverlay:getButtonWidth(buttons, controls.isComboButtonMapping, false, self.buttonHeight)
            elseif #controls.keys > 0 then
                local i = #keys
                for i = i, 1, -1 do
                    local totalWidth = self.keyButtonOverlay:getButtonWidth(keys[i], self.buttonHeight) + g_pixelSizeX
                end
            end
            setTextWrapWidth(self.textMaxWidth)
            local width = width + getTextWidth(self.textSize, text)
            local textHeight = getTextHeight(self.textSize, text)
            local totalHeight = textHeight + self.titleTextOffsetY + self.titleTextSize
            local i, key = self:getPosition()
            local keyWidth = i - width * 0.5
            local totalWidth = key + (totalHeight - self.buttonHeight) * 0.5
            if #buttons > 0 then
                self.glyphButtonOverlay:renderButton(buttons, isComboButtonMapping, false, keyWidth, totalWidth, self.buttonHeight)
            else
                local i = #keys
                for i = i, 1, -1 do
                    self.keyButtonOverlay:renderButton(keys[i], keyWidth, totalWidth, self.buttonHeight, true)
                end
            end
            local keyWidth = keyWidth + totalButtonWidth
            local iconPosY = key + (totalHeight - self.iconOverlay.height) * 0.5
            self.iconOverlay:setPosition(keyWidth + self.iconOffsetX, iconPosY)
            self.iconOverlay:render()
            local keyWidth = self.iconOverlay.x + self.iconOverlay.width
            local activeColor = HUD.COLOR.ACTIVE
            setTextColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
            setTextBold(true)
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(keyWidth + self.textOffsetX, key + textHeight + self.titleTextOffsetY, self.titleTextSize, self.actionText)
            setTextColor(1, 1, 1, 1)
            setTextBold(false)
            setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
            renderText(keyWidth + self.textOffsetX, key + self.textOffsetY, self.textSize, text)
            setTextWrapWidth(0)
            setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
        end
    end
end
function ContextActionDisplay:setContext(contextAction, contextIconName, text, priority, actionText)
    priority = priority == nil and 0 or priority
    local newSliceId = self.slicesIds[contextIconName]
    if self.contextPriority <= priority and newSliceId ~= nil then
        self.contextAction = contextAction
        self.text = utf8ToUpper(text)
        self.actionText = utf8ToUpper(actionText)
        self.contextPriority = priority
        if newSliceId ~= self.lastSliceId then
            self.iconOverlay:setSliceId(newSliceId)
            self.lastSliceId = newSliceId
        end
        self:updateControls()
        self:setVisible(true)
        self.displayTime = ContextActionDisplay.MIN_DISPLAY_DURATION
    elseif contextAction == self.contextAction then
        self.displayTime = ContextActionDisplay.MIN_DISPLAY_DURATION
    end
end
function ContextActionDisplay:resetContext()
    self.controls = nil
    self.contextPriority = -math.huge
    self.text = nil
end
if data ~= nil then
    local contextActionDisplay = ContextActionDisplay.new()
    contextActionDisplay:setScale(data.uiScale)
    contextActionDisplay:setVisible(data.isVisible)
    g_currentMission.hud.contextActionDisplay = contextActionDisplay
    g_currentMission.hud.displayComponents.contextActionDisplay = contextActionDisplay
    Logging.info("Reloaded ContextActionDisplay")
end