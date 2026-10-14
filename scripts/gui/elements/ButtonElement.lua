ButtonElement = {}
local ButtonElement_mt = Class(ButtonElement, TextElement)
Gui.registerGuiElement("Button", ButtonElement)
Gui.registerGuiElementProcFunction("Button", Gui.assignPlaySampleCallback)
function ButtonElement.new(target, custom_mt)
    -- upvalues: (copy) ButtonElement_mt
    local self = TextElement.new(target, custom_mt or ButtonElement_mt)
    self:include(PlaySampleMixin)
    self.inputDown = false
    self.forceFocus = false
    self.overlay = {}
    self.icon = {}
    self.touchIcon = {}
    self.iconSize = { 0, 0 }
    self.touchIconSize = { 0, 0 }
    self.gamepadIconSize = { getNormalizedScreenValues(60, 60) }
    self.iconTextOffset = { 0, 0 }
    self.focusedTextOffset = { 0, 0 }
    self.needExternalClick = false
    self.clickSoundName = GuiSoundPlayer.SOUND_SAMPLES.CLICK
    self.fitToContent = false
    self.fitExtraWidth = 0
    self.hideKeyboardGlyph = false
    self.isTouchButton = false
    self.isTouchButtonWithBg = false
    self.gamepadUsesTouchButton = false
    self.addTouchArea = true
    self.isTriggerableByGlobalAction = true
    self.ignorePressedOverlayState = false
    self.pressed = false
    self.sendActionOnRelease = true
    self.textAlignment = RenderText.ALIGN_CENTER
    self.textSeparator = nil
    self.inputActionName = nil
    self.hasLoadedInputGlyph = false
    self.isKeyboardMode = false
    self.keyDisplayText = nil
    self.keyOverlay = nil
    self.keyGlyphOffsetX = 0
    self.keyGlyphSize = { 0, 0 }
    self.iconColors = {
        ["color"] = {
            1,
            1,
            1,
            1
        }
    }
    self.iconImageSize = { 2048, 2048 }
    self.drawChildrenLast = false
    return self
end
function ButtonElement:delete()
    GuiOverlay.deleteOverlay(self.touchIcon)
    GuiOverlay.deleteOverlay(self.overlay)
    GuiOverlay.deleteOverlay(self.icon)
    ButtonElement:superClass().delete(self)
end
function ButtonElement:loadFromXML(xmlFile, key)
    ButtonElement:superClass().loadFromXML(self, xmlFile, key)
    self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
    self:addCallback(xmlFile, key .. "#onFocus", "onFocusCallback")
    self:addCallback(xmlFile, key .. "#onLeave", "onLeaveCallback")
    self:addCallback(xmlFile, key .. "#onHighlight", "onHighlightCallback")
    self:addCallback(xmlFile, key .. "#onHighlightRemove", "onHighlightRemoveCallback")
    self:addCallback(xmlFile, key .. "#onSizeChanged", "onSizeChangedCallback")
    GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, nil, xmlFile, key)
    self.iconSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#iconSize"), self.iconSize)
    self.touchIconSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#touchIconSize"), self.touchIconSize)
    self.gamepadIconSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#gamepadIconSize"), self.gamepadIconSize)
    self.iconTextOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#iconTextOffset"), self.iconTextOffset)
    self.forceFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#forceFocus"), self.forceFocus)
    self.needExternalClick = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needExternalClick"), self.needExternalClick)
    self.fitToContent = Utils.getNoNil(getXMLBool(xmlFile, key .. "#fitToContent"), self.fitToContent)
    self.fitExtraWidth = GuiUtils.getNormalizedXValue(getXMLString(xmlFile, key .. "#fitExtraWidth"), self.fitExtraWidth)
    self.hideKeyboardGlyph = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideKeyboardGlyph"), self.hideKeyboardGlyph)
    self.isTouchButton = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTouchButton"), self.isTouchButton)
    self.isTouchButtonWithBg = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTouchButtonWithBg"), self.isTouchButtonWithBg)
    self.gamepadUsesTouchButton = Utils.getNoNil(getXMLBool(xmlFile, key .. "#gamepadUsesTouchButton"), self.gamepadUsesTouchButton)
    self.addTouchArea = Utils.getNoNil(getXMLBool(xmlFile, key .. "#addTouchArea"), self.addTouchArea)
    self.touchAreaColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#touchAreaColor"), self.touchAreaColor)
    self.isTriggerableByGlobalAction = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTriggerableByGlobalAction"), self.isTriggerableByGlobalAction)
    self.ignorePressedOverlayState = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignorePressedOverlayState"), self.ignorePressedOverlayState)
    self.sendActionOnRelease = Utils.getNoNil(getXMLBool(xmlFile, key .. "#sendActionOnRelease"), self.sendActionOnRelease)
    self.textSeparator = Utils.getNoNil(getXMLString(xmlFile, key .. "#textSeparator"), self.textSeparator)
    self.drawChildrenLast = Utils.getNoNil(getXMLBool(xmlFile, key .. "#drawChildrenLast"), self.drawChildrenLast)
    local inputActionName = getXMLString(xmlFile, key .. "#inputAction")
    if inputActionName == nil or InputAction[inputActionName] == nil then
        self.iconImageSize = string.getVector(getXMLString(xmlFile, key .. "#iconImageSize"), 2) or self.iconImageSize
        GuiOverlay.loadOverlay(self, self.icon, "icon", self.iconImageSize, nil, xmlFile, key)
        GuiOverlay.createOverlay(self.icon)
    else
        self.inputActionName = inputActionName
        self:loadInputGlyphColors(nil, xmlFile, key)
    end
    if (self.isTouchButton or (self.isTouchButtonWithBg or self.gamepadUsesTouchButton)) and Platform.isMobile then
        GuiOverlay.loadOverlay(self, self.touchIcon, "touchIcon", self.imageSize, nil, xmlFile, key)
        GuiOverlay.createOverlay(self.touchIcon)
    end
    local sampleName = getXMLString(xmlFile, key .. "#clickSound") or self.clickSoundName
    self.clickSoundName = GuiSoundPlayer.SOUND_SAMPLES[sampleName] or self.clickSoundName
    GuiOverlay.createOverlay(self.overlay)
    self:updateSize()
end
function ButtonElement:loadProfile(profile, applyProfile)
    ButtonElement:superClass().loadProfile(self, profile, applyProfile)
    GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, profile, nil, nil)
    local inputActionName = profile:getValue("inputAction", self.inputActionName)
    if inputActionName == nil or InputAction[inputActionName] == nil then
        local iconImageSizeStr = profile:getValue("iconImageSize")
        if not string.isNilOrWhitespace(iconImageSizeStr) then
            self.iconImageSize = string.getVector(iconImageSizeStr, 2)
        end
        GuiOverlay.loadOverlay(self, self.icon, "icon", self.iconImageSize, profile, nil, nil)
        GuiOverlay.createOverlay(self.icon)
    else
        self.inputActionName = inputActionName
        self:loadInputGlyphColors(profile, nil, nil)
    end
    if (self.isTouchButton or (self.isTouchButtonWithBg or self.gamepadUsesTouchButton)) and Platform.isMobile then
        GuiOverlay.loadOverlay(self, self.touchIcon, "touchIcon", self.imageSize, profile, nil, nil)
        GuiOverlay.createOverlay(self.touchIcon)
    end
    self.iconSize = GuiUtils.getNormalizedScreenValues(profile:getValue("iconSize"), self.iconSize)
    self.touchIconSize = GuiUtils.getNormalizedScreenValues(profile:getValue("touchIconSize"), self.touchIconSize)
    self.gamepadIconSize = GuiUtils.getNormalizedScreenValues(profile:getValue("gamepadIconSize"), self.gamepadIconSize)
    self.iconTextOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("iconTextOffset"), self.iconTextOffset)
    self.forceFocus = profile:getBool("forceFocus", self.forceFocus)
    self.needExternalClick = profile:getBool("needExternalClick", self.needExternalClick)
    self.fitToContent = profile:getBool("fitToContent", self.fitToContent)
    self.fitExtraWidth = GuiUtils.getNormalizedXValue(profile:getValue("fitExtraWidth"), self.fitExtraWidth)
    self.hideKeyboardGlyph = profile:getBool("hideKeyboardGlyph", self.hideKeyboardGlyph)
    self.isTouchButton = profile:getBool("isTouchButton", self.isTouchButton)
    self.isTouchButtonWithBg = profile:getBool("isTouchButtonWithBg", self.isTouchButtonWithBg)
    self.gamepadUsesTouchButton = profile:getBool("gamepadUsesTouchButton", self.gamepadUsesTouchButton)
    self.addTouchArea = profile:getBool("addTouchArea", self.addTouchArea)
    self.touchAreaColor = GuiUtils.getColorArray(profile:getValue("touchAreaColor"))
    self.isTriggerableByGlobalAction = profile:getBool("isTriggerableByGlobalAction", self.isTriggerableByGlobalAction)
    self.ignorePressedOverlayState = profile:getBool("ignorePressedOverlayState", self.ignorePressedOverlayState)
    self.sendActionOnRelease = profile:getBool("sendActionOnRelease", self.sendActionOnRelease)
    self.textSeparator = profile:getValue("textSeparator", self.textSeparator)
    self.drawChildrenLast = profile:getBool("drawChildrenLast", self.drawChildrenLast)
    local iconImageSizeStr = profile:getValue("clickSound", self.clickSoundName)
    self.clickSoundName = GuiSoundPlayer.SOUND_SAMPLES[iconImageSizeStr] or self.clickSoundName
    GuiOverlay.createOverlay(self.overlay)
    if applyProfile then
        self:updateSize()
    end
end
function ButtonElement:copyAttributes(src)
    ButtonElement:superClass().copyAttributes(self, src)
    GuiOverlay.copyOverlay(self.overlay, src.overlay)
    GuiOverlay.copyOverlay(self.icon, src.icon)
    if (src.isTouchButton or (src.isTouchButtonWithBg or self.gamepadUsesTouchButton)) and Platform.isMobile then
        GuiOverlay.copyOverlay(self.touchIcon, src.touchIcon)
        self.touchIconSize = table.clone(src.touchIconSize)
        self.gamepadIconSize = table.clone(src.gamepadIconSize)
    end
    self.iconSize = table.clone(src.iconSize)
    self.iconTextOffset = table.clone(src.iconTextOffset)
    self.forceFocus = src.forceFocus
    self.needExternalClick = src.needExternalClick
    self.inputActionName = src.inputActionName
    self.clickSoundName = src.clickSoundName
    self.hideKeyboardGlyph = src.hideKeyboardGlyph
    self.fitExtraWidth = src.fitExtraWidth
    self.fitToContent = src.fitToContent
    self.isTouchButton = src.isTouchButton
    self.isTouchButtonWithBg = src.isTouchButtonWithBg
    self.gamepadUsesTouchButton = src.gamepadUsesTouchButton
    self.addTouchArea = src.addTouchArea
    self.touchAreaColor = src.touchAreaColor
    self.isTriggerableByGlobalAction = src.isTriggerableByGlobalAction
    self.ignorePressedOverlayState = src.ignorePressedOverlayState
    self.sendActionOnRelease = src.sendActionOnRelease
    self.textSeparator = src.textSeparator
    self.drawChildrenLast = src.drawChildrenLast
    self.iconColors = src.iconColors
    self.pressed = src.pressed
    self.onClickCallback = src.onClickCallback
    self.onLeaveCallback = src.onLeaveCallback
    self.onFocusCallback = src.onFocusCallback
    self.onHighlightCallback = src.onHighlightCallback
    self.onHighlightRemoveCallback = src.onHighlightRemoveCallback
    self.onSizeChangedCallback = src.onSizeChangedCallback
    GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end
function ButtonElement:loadInputGlyphColors(profile, xmlFile, key)
    if xmlFile == nil then
        if profile ~= nil then
            GuiOverlay.loadProfileColors(profile, self.icon, "icon")
            GuiOverlay.loadProfileColors(profile, self.iconColors, "iconBg")
        end
    else
        GuiOverlay.loadXMLColors(xmlFile, key, self.icon, "icon")
        GuiOverlay.loadXMLColors(xmlFile, key, self.iconColors, "iconBg")
    end
end
function ButtonElement:loadInputGlyph(force)
    if not self.icon.filename or force then
        local overlay = g_inputDisplayManager:getGamepadInputActionOverlay(self.inputActionName, Binding.AXIS_COMPONENT.POSITIVE)
        if overlay ~= nil then
            GuiOverlay.copyColors(overlay, self.icon)
            GuiOverlay.deleteOverlay(self.icon)
            self.icon = overlay
            self.hasLoadedInputGlyph = true
        end
    end
    if not (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) then
        local overlay = g_inputDisplayManager:getKeyboardInputActionKey(self.inputActionName, Binding.AXIS_COMPONENT.POSITIVE)
        if overlay ~= nil then
            self.keyDisplayText = overlay
            self.keyOverlay = g_inputDisplayManager:getKeyboardKeyOverlay()
            local newWidth = self.keyOverlay:getButtonWidth(overlay, self.iconSize[2])
            self.keyGlyphSize = { newWidth, self.iconSize[2] }
            self.keyGlyphOffsetX = newWidth - self.iconSize[1]
        end
    end
end
function ButtonElement:setInputMode(isKeyboardMode, isTouchMode, isGamepadMode)
    local didChange = false
    if self.isKeyboardMode ~= isKeyboardMode then
        self.isKeyboardMode = isKeyboardMode
        didChange = true
        if not self.hasLoadedInputGlyph then
            self:loadInputGlyph()
        end
    end
    if self.isGamepadMode ~= isGamepadMode then
        self.isGamepadMode = isGamepadMode
        didChange = true
        if not self.hasLoadedInputGlyph then
            self:loadInputGlyph()
        end
    end
    if self.isTouchMode ~= isTouchMode and (self.isTouchButton or self.isTouchButtonWithBg) then
        self.isTouchMode = isTouchMode
        didChange = true
    end
    if didChange then
        self:updateSize()
    end
end
function ButtonElement:setAlpha(alpha)
    ButtonElement:superClass().setAlpha(self, alpha)
    if self.overlay ~= nil then
        self.overlay.alpha = self.alpha
    end
    if self.icon ~= nil then
        self.icon.alpha = self.alpha
    end
end
function ButtonElement:setDisabled(disabled)
    ButtonElement:superClass().setDisabled(self, disabled)
    if disabled then
        FocusManager:unsetFocus(self)
        self.inputEntered = false
        self:raiseCallback("onLeaveCallback", self)
        self.inputDown = false
    end
end
function ButtonElement:setInputAction(inputActionName)
    if inputActionName ~= nil and InputAction[inputActionName] ~= nil then
        self.inputActionName = inputActionName
        self:loadInputGlyph(true)
    end
end
function ButtonElement:onOpen()
    ButtonElement:superClass().onOpen(self)
    if self.inputActionName ~= nil then
        self.hasLoadedInputGlyph = false
        self:loadInputGlyph(true)
    end
end
function ButtonElement:onClose()
    ButtonElement:superClass().onClose(self)
    self:reset()
end
function ButtonElement:reset()
    ButtonElement:superClass().reset(self)
    self:setPressed(false)
    self:setFocused(false)
    self:setHighlighted(false)
    self.inputDown = false
end
function ButtonElement:setImageFilename(filename, iconFilename)
    if filename ~= nil then
        self.overlay = GuiOverlay.createOverlay(self.overlay, filename)
    end
    if iconFilename ~= nil then
        self.icon = GuiOverlay.createOverlay(self.icon, iconFilename)
    end
end
function ButtonElement:setImageUVs(backgroundUVs, iconUVs)
    if backgroundUVs ~= nil then
        self.overlay.uvs = backgroundUVs
    end
    if iconUVs ~= nil then
        self.icon.uvs = iconUVs
    end
end
function ButtonElement:setImageSlice(backgroundSliceId, iconSliceId)
    local backgroundSlice = g_overlayManager:getSliceInfoById(backgroundSliceId)
    local iconSlice = g_overlayManager:getSliceInfoById(iconSliceId)
    self:setImageUVs(backgroundSlice ~= nil and backgroundSlice.uvs or nil, iconSlice ~= nil and iconSlice.uvs or nil)
    self:setImageFilename(backgroundSlice ~= nil and backgroundSlice.filename or nil, iconSlice ~= nil and iconSlice.filename or nil)
end
function ButtonElement:getIsActive()
    local baseActive = ButtonElement:superClass().getIsActive(self)
    if baseActive then
        baseActive = self.onClickCallback ~= nil
    end
    return baseActive
end
function ButtonElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsActive() then
        eventUsed = eventUsed or ButtonElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
        local clickInElement = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], self.hotspot)
        if clickInElement then
            if not self.inputEntered then
                if self.handleFocus and not self:getIsHighlighted() then
                    FocusManager:setHighlight(self)
                end
                self.inputEntered = true
            end
        else
            self.inputDown = false
            self.inputEntered = false
            if self:getIsHighlighted() and (self.parent == nil or not self.parent:getIsHighlighted()) then
                FocusManager:unsetHighlight(self)
            end
        end
        if not eventUsed and (clickInElement and not FocusManager:isLocked()) then
            if isDown and button == Input.MOUSE_BUTTON_LEFT then
                if self.handleFocus and not self.forceFocus then
                    FocusManager:setFocus(self)
                    eventUsed = true
                    if not self.sendActionOnRelease then
                        self:sendAction()
                    end
                end
                self.inputDown = true
            end
            if isUp and (button == Input.MOUSE_BUTTON_LEFT and self.inputDown) then
                if self.sendActionOnRelease then
                    self:sendAction()
                end
                eventUsed = true
            end
            if self.inputDown then
                self:setPressed(true)
            end
        end
    end
    if isUp then
        self.inputDown = false
        self:setPressed(false)
    end
    return eventUsed
end
function ButtonElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
    if self:getIsActive() then
        eventUsed = eventUsed or ButtonElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed)
        local clickInElement = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], self.hotspot)
        if clickInElement then
            if not self.inputEntered then
                if self.handleFocus and not self:getIsHighlighted() then
                    FocusManager:setHighlight(self)
                end
                self.inputEntered = true
            end
        else
            self.inputDown = false
            self.inputEntered = false
            if self:getIsHighlighted() and (self.parent == nil or not self.parent:getIsHighlighted()) then
                FocusManager:unsetHighlight(self)
            end
        end
        if not eventUsed and (clickInElement and not FocusManager:isLocked()) then
            if isDown then
                if self.handleFocus and not self.forceFocus then
                    FocusManager:setFocus(self)
                    eventUsed = true
                    if not self.sendActionOnRelease then
                        self:sendAction()
                    end
                end
                self.inputDown = true
            end
            if isUp and self.inputDown then
                if self.sendActionOnRelease then
                    self:sendAction()
                end
                eventUsed = true
            end
            if self.inputDown then
                self:setPressed(true)
            end
        end
    end
    if isUp then
        self.inputDown = false
        self:setPressed(false)
    end
    return eventUsed
end
function ButtonElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
    if self:getIsActive() then
        return ButtonElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed)
    else
        return false
    end
end
function ButtonElement:getIconOffset(textWidth, textHeight)
    local iconSizeX, iconSizeY = self:getIconSize()
    local xOffset = self.iconTextOffset[1]
    local yOffset = self.iconTextOffset[2]
    if self.textAlignment == RenderText.ALIGN_LEFT then
    elseif self.textAlignment == RenderText.ALIGN_CENTER then
    elseif self.textAlignment == RenderText.ALIGN_RIGHT then
    end
    if self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.TOP then
        return xOffset, yOffset - textHeight
    end
    if self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.MIDDLE then
    end
    return xOffset, yOffset
end
function ButtonElement:draw(clipX1, clipY1, clipX2, clipY2)
    if not self.drawChildrenLast then
        ButtonElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
    end
    local overlayState = self:getOverlayState()
    local lastInputMode = g_inputBinding:getInputHelpMode()
    local textOffsetX = false
    if self.keyDisplayText ~= nil then
        textOffsetX = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_KEYBOARD
    end
    if self.isTouchButton then
        textOffsetY = true
        if lastInputMode == GS_INPUT_HELP_MODE_TOUCH then
            ::l9::
            local xOffset = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD
            self:setInputMode(textOffsetX, textOffsetY, xOffset)
            GuiOverlay.renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], overlayState, clipX1, clipY1, clipX2, clipY2)
            local xPos, yPos = self:getTextPosition(self.text)
            local textOffsetX, textOffsetY = self:getTextOffset()
            local xOffset, yOffset = self:getIconOffset(self:getTextWidth(), getTextHeight(self.textSize, self.text))
            local iconXPos = xPos + textOffsetX + xOffset
            local iconSizeX, iconSizeY = self:getIconSize()
            if self.keyDisplayText == nil or not self.isKeyboardMode then
                if self.isTouchMode then
                    if self.addTouchArea then
                        local textColor = 1
                        local bgColor = 1
                        local r = 1
                        local g = 1
                        if self.touchAreaColor ~= nil then
                            textColor = self.touchAreaColor[1]
                            bgColor = self.touchAreaColor[2]
                            r = self.touchAreaColor[3]
                            g = self.touchAreaColor[4]
                        end
                        drawTouchButton(self.absPosition[1], self.absPosition[2] + self.absSize[2] / 2, self.absSize[1], overlayState == GuiOverlay.STATE_PRESSED, self.isTouchButtonWithBg, textColor, bgColor, r, g, clipX1, clipY1, clipX2, clipY2)
                    end
                    local textColor = self.touchIcon
                    local bgColor = self.touchIconSize
                    if self.isGamepadMode then
                        textColor = self.icon
                        bgColor = self.gamepadIconSize
                    end
                    if textColor ~= nil then
                        GuiOverlay.renderOverlay(textColor, iconXPos, self.absPosition[2] + self.absSize[2] / 2 - bgColor[2] / 2, bgColor[1], bgColor[2], overlayState, clipX1, clipY1, clipX2, clipY2)
                    end
                else
                    GuiOverlay.renderOverlay(self.icon, iconXPos, yPos + textOffsetY + yOffset, iconSizeX, iconSizeY, overlayState, clipX1, clipY1, clipX2, clipY2)
                end
            elseif not self.hideKeyboardGlyph then
                local textColor = GuiOverlay.getOverlayColor(self.icon, overlayState)
                local bgColor = GuiOverlay.getOverlayColor(self.iconColors, overlayState)
                local r, g, b, a = unpack(textColor)
                local r2, g2, b2, a2 = unpack(bgColor)
                self.keyOverlay:setColor(r, g, b, a, r2, g2, b2, a2)
                self.keyOverlay:renderButton(self.keyDisplayText, iconXPos, iconYPos, iconSizeY, true, clipX1, clipY1, clipX2, clipY2)
            end
            if self.debugEnabled or g_uiDebugEnabled then
                local textColor = self.absPosition[1]
                local bgColor = self.absPosition[1] + self.size[1] - g_pixelSizeX
                local r = self.absPosition[2]
                local g = self.absPosition[2] + self.size[2] - g_pixelSizeY
                drawFilledRect(textColor, r, bgColor - textColor, g_pixelSizeY, 0, 1, 0, 0.7)
                drawFilledRect(textColor, g, bgColor - textColor, g_pixelSizeY, 0, 1, 0, 0.7)
                drawFilledRect(textColor, r, g_pixelSizeX, g - r, 0, 1, 0, 0.7)
                drawFilledRect(textColor + bgColor - textColor, r, g_pixelSizeX, g - r, 0, 1, 0, 0.7)
            end
            if self.drawChildrenLast then
                ButtonElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
            end
            return
        end
    end
    local textOffsetY = self.gamepadUsesTouchButton
    if textOffsetY then
        textOffsetY = false
        if lastInputMode == GS_INPUT_HELP_MODE_GAMEPAD then
            textOffsetY = Platform.isMobile
        end
    end
    goto l9
end
function ButtonElement:getIconModifiedTextOffset(textOffsetX, textOffsetY)
    local iconWidth, _ = self:getIconSize()
    if self.textAlignment == RenderText.ALIGN_LEFT then
        return textOffsetX - self.iconTextOffset[1] + iconWidth, textOffsetY
    end
    if self.textAlignment == RenderText.ALIGN_CENTER then
    end
    return textOffsetX, textOffsetY
end
function ButtonElement:getTextOffset()
    local xOffset, yOffset = ButtonElement:superClass().getTextOffset(self)
    if self.isTouchMode and self.addTouchArea then
    end
    return self:getIconModifiedTextOffset(xOffset, yOffset)
end
function ButtonElement:getText2Offset()
    local xOffset, yOffset = ButtonElement:superClass().getText2Offset(self)
    return self:getIconModifiedTextOffset(xOffset, yOffset)
end
function ButtonElement:getIconSize()
    if self.isKeyboardMode then
        return self.keyGlyphSize[1], self.keyGlyphSize[2]
    else
        return self.iconSize[1], self.iconSize[2]
    end
end
function ButtonElement:setIconSize(x, y)
    self.iconSize[1] = Utils.getNoNil(x, self.iconSize[1])
    self.iconSize[2] = Utils.getNoNil(y, self.iconSize[2])
    self:updateSize()
end
function ButtonElement:canReceiveFocus()
    return (not self.disabled and self:getIsVisible() and true or false) and self:getHandleFocus()
end
function ButtonElement:onFocusLeave()
    ButtonElement:superClass().onFocusLeave(self)
    self:raiseCallback("onLeaveCallback", self)
end
function ButtonElement:onFocusEnter()
    ButtonElement:superClass().onFocusEnter(self)
    self:raiseCallback("onFocusCallback", self)
end
function ButtonElement:onHighlight()
    ButtonElement:superClass().onHighlight(self)
    self:raiseCallback("onHighlightCallback", self)
end
function ButtonElement:onHighlightRemove()
    ButtonElement:superClass().onHighlightRemove(self)
    self:raiseCallback("onHighlightRemoveCallback", self)
end
function ButtonElement:onFocusActivate()
    if self:getIsActive() then
        self:sendAction()
    end
end
function ButtonElement:setPressed(pressed)
    self.pressed = pressed
    if self.updateChildrenState then
        for _, child in pairs(self.elements) do
            if child.setPressed ~= nil then
                child:setPressed(pressed)
            end
        end
    end
end
function ButtonElement:getIsPressed()
    return self.pressed
end
function ButtonElement:getOverlayState()
    if self:getIsDisabled() then
        return GuiOverlay.STATE_DISABLED
    elseif self:getIsPressed() and not self.ignorePressedOverlayState then
        return GuiOverlay.STATE_PRESSED
    elseif self:getIsSelected() then
        return GuiOverlay.STATE_SELECTED
    elseif self:getIsFocused() then
        return GuiOverlay.STATE_FOCUSED
    elseif self:getIsHighlighted() then
        return GuiOverlay.STATE_HIGHLIGHTED
    else
        return GuiOverlay.STATE_NORMAL
    end
end
function ButtonElement:updateSize(forceTextSize)
    local width = nil
    local height = nil
    local needsCallbackRaised = false
    local textHeight, _ = self:getTextHeight()
    local iconWidth, iconHeight = self:getIconSize()
    if (self.fitToContent or self.textAutoWidth) and not forceTextSize then
        setTextBold(self.textBold)
        local textWidth = getTextWidth(self.textSize, self.sourceText) + 0.001
        setTextBold(false)
        width = iconWidth + textWidth + self.fitExtraWidth
        if (self.isTouchButton or (self.isTouchButtonWithBg or self.gamepadUsesTouchButton)) and (self.isTouchMode and self.addTouchArea) then
            height = 0.09375
            if self.originalHeight ~= nil then
                self.originalHeight = self.size[2]
            end
            needsCallbackRaised = true
        else
            height = self.originalHeight
            self.originalHeight = nil
        end
    end
    if (self.fitToContent or self.textAutoHeight) and not forceTextSize then
        height = math.max(textHeight, iconHeight)
    end
    if width ~= nil and not MathUtil.equalEpsilon(width, self.absSize[1]) or height ~= nil and not MathUtil.equalEpsilon(height, self.absSize[2]) then
        self:setSize(width, height)
        if needsCallbackRaised then
            self:raiseCallback("onSizeChangedCallback", self)
        end
        if self.parent ~= nil and (self.parent.invalidateLayout ~= nil and self.parent.autoValidateLayout) then
            self.parent:invalidateLayout()
        end
    end
end
function ButtonElement:setText(text, forceTextSize, isInitializing, forceScrollingParameterUpdate)
    if self.textSeparator ~= nil then
    end
    ButtonElement:superClass().setText(self, text, forceTextSize, isInitializing, forceScrollingParameterUpdate)
    self:updateSize()
end
function ButtonElement:setTextSize(size)
    ButtonElement:superClass().setTextSize(self, size)
    self:updateSize()
end
function ButtonElement:setClickSound(soundName)
    self.clickSoundName = soundName
end
function ButtonElement:sendAction()
    local eventUsed = not self:raiseCallback("onClickCallback", self)
    if not self.soundDisabled and eventUsed then
        self:playSample(self.clickSoundName)
    end
end