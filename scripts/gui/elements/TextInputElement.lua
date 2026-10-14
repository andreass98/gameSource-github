TextInputElement = {}
local TextInputElement_mt = Class(TextInputElement, ButtonElement)
Gui.registerGuiElement("TextInput", TextInputElement)
TextInputElement.INPUT_CONTEXT_NAME = "TEXT_INPUT"
TextInputElement.inputContextActive = false
TextInputElement.INITIAL_REPEAT_DELAY = 250
TextInputElement.MIN_REPEAT_DELAY = 50
local localGetClipboard = getClipboard or function()
    return ""
end
function TextInputElement.new(target, custom_mt)
    -- upvalues: (copy) TextInputElement_mt
    local self = ButtonElement.new(target, custom_mt or TextInputElement_mt)
    self.textInputMouseDown = false
    self.forcePressed = false
    self.isPassword = false
    self.displayText = ""
    self.cursor = {}
    self.cursorBlinkTime = 0
    self.cursorBlinkInterval = 400
    self.cursorOffset = { 0, 0 }
    self.cursorSize = { 0.0016, 0.018 }
    self.cursorNeededSize = { self.cursorOffset[1] + self.cursorSize[1], self.cursorOffset[2] + self.cursorSize[2] }
    self.cursorPosition = 1
    self.firstVisibleCharacterPosition = 1
    self.lastVisibleCharacterPosition = 1
    self.maxCharacters = nil
    self.maxInputTextWidth = nil
    self.frontDotsText = "..."
    self.backDotsText = "..."
    self.text = ""
    self.useIme = imeIsSupported()
    self.preImeText = ""
    self.imeActive = false
    self.blockTime = 0
    self.isReturnDown = false
    self.isEscDown = false
    self.isCapturingInput = false
    self.hadFocusOnCapture = false
    self.enterWhenClickOutside = true
    self.applyProfanityFilter = nil
    self.disallowFocusedHighlight = true
    self.imeKeyboardType = "normal"
    self.forceFocus = true
    self.customFocusSample = GuiSoundPlayer.SOUND_SAMPLES.TEXTBOX
    return self
end
function TextInputElement:delete()
    self:abortIme()
    GuiOverlay.deleteOverlay(self.cursor)
    TextInputElement:superClass().delete(self)
end
function TextInputElement.translate(_, str)
    if str then
        str = g_i18n:convertText(str)
    end
    return str
end
function TextInputElement:loadFromXML(xmlFile, key)
    TextInputElement:superClass().loadFromXML(self, xmlFile, key)
    self:addCallback(xmlFile, key .. "#onEnter", "onEnterCallback")
    self:addCallback(xmlFile, key .. "#onTextChanged", "onTextChangedCallback")
    self:addCallback(xmlFile, key .. "#onEnterPressed", "onEnterPressedCallback")
    self:addCallback(xmlFile, key .. "#onEscPressed", "onEscPressedCallback")
    self:addCallback(xmlFile, key .. "#onIsUnicodeAllowed", "onIsUnicodeAllowedCallback")
    self.imeKeyboardType = getXMLString(xmlFile, key .. "#imeKeyboardType") or self.imeKeyboardType
    self.imeTitle = self:translate(getXMLString(xmlFile, key .. "#imeTitle"))
    self.imeDescription = self:translate(getXMLString(xmlFile, key .. "#imeDescription"))
    self.imePlaceholder = self:translate(getXMLString(xmlFile, key .. "#imePlaceholder"))
    self.maxCharacters = getXMLInt(xmlFile, key .. "#maxCharacters") or self.maxCharacters
    self.maxInputTextWidth = GuiUtils.getNormalizedXValue(getXMLString(xmlFile, key .. "#maxInputTextWidth"), self.maxInputTextWidth)
    self.cursorOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#cursorOffset"), self.cursorOffset)
    self.cursorSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#cursorSize"), self.cursorSize)
    if g_screenWidth > 1 then
        self.cursorSize[1] = math.max(self.cursorSize[1], g_pixelSizeX)
    end
    self.enterWhenClickOutside = Utils.getNoNil(getXMLBool(xmlFile, key .. "#enterWhenClickOutside"), self.enterWhenClickOutside)
    self.applyProfanityFilter = Utils.getNoNil(getXMLBool(xmlFile, key .. "#applyProfanityFilter"), self.applyProfanityFilter)
    GuiOverlay.loadOverlay(self, self.cursor, "cursor", self.imageSize, nil, xmlFile, key)
    GuiOverlay.createOverlay(self.cursor)
    self.isPassword = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isPassword"), self.isPassword)
    self:finalize()
end
function TextInputElement:loadProfile(profile, applyProfile)
    TextInputElement:superClass().loadProfile(self, profile, applyProfile)
    self.maxCharacters = profile:getNumber("maxCharacters", self.maxCharacters)
    self.maxInputTextWidth = GuiUtils.getNormalizedXValue(profile:getValue("maxInputTextWidth"), self.maxInputTextWidth)
    self.cursorOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("cursorOffset"), self.cursorOffset)
    self.cursorSize = GuiUtils.getNormalizedScreenValues(profile:getValue("cursorSize"), self.cursorSize)
    self.isPassword = profile:getBool("isPassword", self.isPassword)
    self.cursorImageSize = GuiUtils.getNormalizedValues(profile:getValue("cursorImageSize"), self.outputSize, self.imageSize)
    self.applyProfanityFilter = profile:getBool("applyProfanityFilter", self.applyProfanityFilter)
    GuiOverlay.loadOverlay(self, self.cursor, "cursor", self.cursorImageSize, profile, nil, nil)
    if g_screenWidth > 1 then
        self.cursorSize[1] = math.max(self.cursorSize[1], g_pixelSizeX)
    end
    self:finalize()
end
function TextInputElement:copyAttributes(src)
    TextInputElement:superClass().copyAttributes(self, src)
    self.imeKeyboardType = src.imeKeyboardType
    self.imeTitle = src.imeTitle
    self.imeDescription = src.imeDescription
    self.imePlaceholder = src.imePlaceholder
    self.maxCharacters = src.maxCharacters
    self.maxInputTextWidth = src.maxInputTextWidth
    GuiOverlay.copyOverlay(self.cursor, src.cursor)
    self.cursorOffset = table.clone(src.cursorOffset)
    self.cursorSize = table.clone(src.cursorSize)
    self.isPassword = src.isPassword
    self.onEnterCallback = src.onEnterCallback
    self.onTextChangedCallback = src.onTextChangedCallback
    self.onEnterPressedCallback = src.onEnterPressedCallback
    self.onEscPressedCallback = src.onEscPressedCallback
    self.onIsUnicodeAllowedCallback = src.onIsUnicodeAllowedCallback
    self.enterWhenClickOutside = src.enterWhenClickOutside
    self.applyProfanityFilter = src.applyProfanityFilter
    self:finalize()
end
function TextInputElement:finalize()
    self.cursorNeededSize = { self.cursorOffset[1] + self.cursorSize[1], self.cursorOffset[2] + self.cursorSize[2] }
    if not self.maxInputTextWidth and (self.textAlignment == RenderText.ALIGN_CENTER or self.textAlignment == RenderText.ALIGN_RIGHT) then
        Logging.error("TextInputElement loading using \"center\" or \"right\" alignment requires specification of \"maxInputTextWidth\"")
    end
    if self.maxInputTextWidth and self.maxInputTextWidth <= getTextWidth(self.textSize, self.frontDotsText) + self.cursorNeededSize[1] + getTextWidth(self.textSize, self.backDotsText) then
        Logging.warning("TextInputElement loading specified \"maxInputTextWidth\" is too small (%.4f) to display needed data", self.maxInputTextWidth)
    end
end
function TextInputElement:getIsActive()
    return GuiElement.getIsActive(self)
end
function TextInputElement:setCaptureInput(isCapturing)
    self.blockTime = 200
    if self.isCapturingInput or not isCapturing then
        if self.isCapturingInput and not isCapturing then
            if TextInputElement.inputContextActive then
                g_inputBinding:revertContext(true)
                TextInputElement.inputContextActive = false
            end
            self.target:disableInputForDuration(200)
            self.isCapturingInput = false
            if not self.isPassword and self.applyProfanityFilter ~= false then
                local baseText = self.text
                local filteredText = filterText(baseText, true, true)
                if baseText ~= "" and baseText ~= filteredText then
                    self:setText(filteredText)
                end
            end
        end
    else
        self.isReturnDown = false
        self.isEscDown = false
        self.target:disableInputForDuration(0)
        if TextInputElement.inputContextActive then
            g_inputBinding:revertContext(true)
        end
        g_inputBinding:setContext(TextInputElement.INPUT_CONTEXT_NAME, true, false)
        TextInputElement.inputContextActive = true
        if not GS_IS_CONSOLE_VERSION then
            g_inputBinding:registerActionEvent(InputAction.MENU_BACK, self, self.inputEvent, false, true, false, true)
            g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.inputEvent, false, true, false, true)
        end
        self.isCapturingInput = true
    end
end
function TextInputElement:setAlpha(alpha)
    TextInputElement:superClass().setAlpha(self, alpha)
    if self.cursor ~= nil then
        self.cursor.alpha = self.alpha
    end
end
function TextInputElement:getDoRenderText()
    return false
end
function TextInputElement:reset()
    TextInputElement:superClass().reset(self)
    if self.isRepeatingSpecialKeyDown then
        self:stopSpecialKeyRepeating()
    end
end
function TextInputElement:setText(text)
    local textLength = utf8Strlen(text)
    if self.maxCharacters and self.maxCharacters < textLength then
        text = utf8Substr(text, 0, self.maxCharacters)
        textLength = utf8Strlen(text)
    end
    TextInputElement:superClass().setText(self, text)
    self.cursorPosition = textLength + 1
    self:updateVisibleTextElements()
end
function TextInputElement:setForcePressed(force)
    if force then
        self.hadFocusOnCapture = self:getIsFocused()
        self:setCaptureInput(true)
    else
        self:setCaptureInput(false)
    end
    self.forcePressed = force
    if self.forcePressed then
        FocusManager:setFocus(self)
    else
        if self.hadFocusOnCapture then
            FocusManager:setFocus(self)
            TextInputElement:superClass().onFocusEnter(self)
        else
            self:setFocused(false)
            TextInputElement:superClass().onFocusLeave(self)
        end
        self.hadFocusOnCapture = false
    end
    if self.isRepeatingSpecialKeyDown then
        self:stopSpecialKeyRepeating()
    end
    self:updateVisibleTextElements()
end
function TextInputElement:getIsUnicodeAllowed(unicode)
    if unicode == 13 or unicode == 10 then
        return false
    elseif getCanRenderUnicode(unicode) then
        return Utils.getNoNil(self:raiseCallback("onIsUnicodeAllowedCallback", unicode), true)
    else
        return false
    end
end
function TextInputElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsActive() then
        local isCursorInside = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
        if self.forcePressed then
            if not isCursorInside and (isUp and button == Input.MOUSE_BUTTON_LEFT) then
                self:setForcePressed(false)
                if self.enterWhenClickOutside then
                    self:abortIme()
                    self:raiseCallback("onEnterPressedCallback", self, true)
                end
            end
        elseif eventUsed or (not isCursorInside or FocusManager:isLocked()) then
            if isDown and button == Input.MOUSE_BUTTON_LEFT or (self.textInputMouseDown or not self.forcePressed) then
                FocusManager:unsetHighlight(self)
            end
            self.textInputMouseDown = false
        else
            FocusManager:setHighlight(self)
            eventUsed = true
            if isDown and button == Input.MOUSE_BUTTON_LEFT then
                self.textInputMouseDown = true
                if not self.useIme then
                    self:setForcePressed(true)
                end
            end
            if isUp and (button == Input.MOUSE_BUTTON_LEFT and self.textInputMouseDown) then
                self.textInputMouseDown = false
                self:setForcePressed(true)
                if self.useIme then
                    self:openIme()
                end
            end
        end
        eventUsed = eventUsed or TextInputElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
    end
    return eventUsed
end
function TextInputElement:moveCursorLeft(isLeftCtrlPressed)
    if isLeftCtrlPressed then
        local textBeforeCursor = utf8Substr(self:getText(), 0, self.cursorPosition - 1)
        local lastSpacePos = string.rtrim(textBeforeCursor)
        local lastSpacePos = string.findLast(lastSpacePos, " ")
        if lastSpacePos == nil then
            self:setCursorPosition(1)
        else
            self:setCursorPosition(lastSpacePos + 1)
        end
    else
        self:setCursorPosition(self.cursorPosition - 1)
        return
    end
end
function TextInputElement:moveCursorRight(isLeftCtrlPressed)
    if isLeftCtrlPressed then
        local nextSpacePos = string.find(self:getText(), " ", self.cursorPosition)
        local nextNonSpacePos = nextSpacePos ~= nil and string.find(self:getText(), "%w", nextSpacePos) or math.huge
        if nextNonSpacePos ~= nil then
            self:setCursorPosition(nextNonSpacePos)
            return
        end
    end
    self:setCursorPosition(self.cursorPosition + 1)
end
function TextInputElement:setCursorPosition(position)
    self.cursorPosition = math.max(1, (math.min(utf8Strlen(self.text) + 1, position)))
end
function TextInputElement:deleteText(deleteRightCharacterFromCursor)
    local textLength = utf8Strlen(self.text)
    if textLength > 0 then
        local canDelete = false
        local deleteOffset = nil
        if deleteRightCharacterFromCursor then
            if self.cursorPosition <= textLength then
                canDelete = true
                deleteOffset = 0
            end
        elseif self.cursorPosition > 1 then
            canDelete = true
            deleteOffset = -1
        end
        if canDelete then
            self.text = (self.cursorPosition + deleteOffset > 1 and utf8Substr(self.text, 0, self.cursorPosition + deleteOffset - 1) or "") .. (self.cursorPosition + deleteOffset < textLength and utf8Substr(self.text, self.cursorPosition + deleteOffset, -1) or "")
            self.cursorPosition = self.cursorPosition + deleteOffset
            self:raiseCallback("onTextChangedCallback", self, self.text)
        end
    end
end
function TextInputElement:stopSpecialKeyRepeating()
    self.isRepeatingSpecialKeyDown = false
    self.repeatingSpecialKeySym = nil
    self.repeatingSpecialKeyDelayTime = nil
    self.repeatingSpecialKeyRemainingDelayTime = nil
end
function TextInputElement:onPauseChanged(isPaused)
    if isPaused then
        self:abortIme()
    end
end
function TextInputElement:openIme()
    if not (self.useIme and imeOpen(self.text, self.imeTitle or "", self.imeDescription or "", self.imePlaceholder or "", self.imeKeyboardType or "normal", Utils.getNoNil(self.maxCharacters, 512), self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])) then
        return false
    end
    self.imeActive = true
    self.preImeText = self.text
    g_messageCenter:subscribe(MessageType.PAUSE, self.onPauseChanged, self)
    return true
end
function TextInputElement:abortIme()
    if self.useIme and self.imeActive then
        self.imeActive = false
        self.preImeText = ""
        imeAbort()
        g_messageCenter:unsubscribe(MessageType.PAUSE, self)
    end
end
function TextInputElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
    -- upvalues: (copy) localGetClipboard
    eventUsed = TextInputElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed) and true or eventUsed
    if self.isRepeatingSpecialKeyDown and (not isDown and self.repeatingSpecialKeySym == sym) then
        self:stopSpecialKeyRepeating()
    end
    if self.blockTime <= 0 and (self:getIsActive() and self.forcePressed) then
        local wasSpecialKey = false
        if isDown then
            local lctrlModifier = Input.MOD_LCTRL
            if GS_PLATFORM_ID == PlatformId.MAC then
                lctrlModifier = Input.MOD_LMETA
            end
            local startSpecialKeyRepeating = false
            if sym == Input.KEY_left then
                local text = bit32.band(modifier, lctrlModifier) > 0
                self:moveCursorLeft(text)
                startSpecialKeyRepeating = true
                wasSpecialKey = true
            elseif sym == Input.KEY_right then
                local text = bit32.band(modifier, lctrlModifier) > 0
                self:moveCursorRight(text)
                startSpecialKeyRepeating = true
                wasSpecialKey = true
            elseif sym == Input.KEY_home then
                self.cursorPosition = 1
                wasSpecialKey = true
            elseif sym == Input.KEY_end then
                self.cursorPosition = utf8Strlen(self.text) + 1
                wasSpecialKey = true
            elseif sym == Input.KEY_delete then
                self:deleteText(true)
                startSpecialKeyRepeating = true
                wasSpecialKey = true
            elseif sym == Input.KEY_backspace then
                if bit32.band(modifier, lctrlModifier) > 0 then
                    if self.isPassword then
                        self:setText("")
                    else
                        local textLeftOfCursor = utf8Substr(self:getText(), 0, self.cursorPosition - 1) or ""
                        local textRightOfCursor = utf8Substr(self:getText(), self.cursorPosition - 1) or ""
                        local text = string.rtrim(textLeftOfCursor)
                        local lastSpacePos = string.findLast(text, " ")
                        local newText = utf8Substr(text, 0, lastSpacePos)
                        self:setText(newText .. textRightOfCursor)
                        self.cursorPosition = self.cursorPosition - (utf8Strlen(textLeftOfCursor) - utf8Strlen(newText))
                        self:raiseCallback("onTextChangedCallback", self, self.text)
                    end
                else
                    self:deleteText(false)
                end
                startSpecialKeyRepeating = true
                wasSpecialKey = true
            elseif sym == Input.KEY_esc then
                self.isEscDown = true
                wasSpecialKey = true
            elseif sym == Input.KEY_return or sym == Input.KEY_KP_enter then
                self.isReturnDown = true
                wasSpecialKey = true
            elseif sym == Input.KEY_v and bit32.band(modifier, lctrlModifier) > 0 then
                local textLeftOfCursor = localGetClipboard()
                self:setText(self:getText() .. textLeftOfCursor)
                wasSpecialKey = true
            end
            if startSpecialKeyRepeating then
                self.isRepeatingSpecialKeyDown = true
                self.repeatingSpecialKeySym = sym
                self.repeatingSpecialKeyDelayTime = TextInputElement.INITIAL_REPEAT_DELAY
                self.repeatingSpecialKeyRemainingDelayTime = self.repeatingSpecialKeyDelayTime
            end
            if not wasSpecialKey and self:getIsUnicodeAllowed(unicode) then
                local textLeftOfCursor = utf8Strlen(self.text)
                if self.maxCharacters == nil or textLeftOfCursor < self.maxCharacters then
                    self.text = (self.cursorPosition > 1 and utf8Substr(self.text, 0, self.cursorPosition - 1) or "") .. unicodeToUtf8(unicode) .. (self.cursorPosition <= textLeftOfCursor and utf8Substr(self.text, self.cursorPosition - 1) or "")
                    self.cursorPosition = self.cursorPosition + 1
                    self:raiseCallback("onTextChangedCallback", self, self.text)
                end
            end
            self:updateVisibleTextElements()
            eventUsed = true
        else
            if (sym == Input.KEY_return or sym == Input.KEY_KP_enter) and self.isReturnDown then
                self.isReturnDown = false
                self:setForcePressed(not self.forcePressed)
                self:raiseCallback("onEnterPressedCallback", self)
                return eventUsed
            end
            if sym == Input.KEY_esc then
                self.isEscDown = false
                self:setForcePressed(not self.forcePressed)
                self:raiseCallback("onEscPressedCallback", self)
                return eventUsed
            end
        end
    end
    return eventUsed
end
function TextInputElement:inputEvent(action, _, eventUsed)
    if self.blockTime <= 0 and (not self.imeActive and (self:getIsActive() and self.forcePressed)) then
        if action == InputAction.MENU_ACCEPT then
            if self.forcePressed then
                self:setForcePressed(false)
            else
                self:setForcePressed(true)
            end
            self:raiseCallback("onEnterPressedCallback", self)
            return true
        end
        if action == InputAction.MENU_CANCEL or action == InputAction.MENU_BACK then
            if self.forcePressed then
                self:setForcePressed(false)
            else
                self:setForcePressed(true)
            end
            self:raiseCallback("onEscPressedCallback", self)
            eventUsed = true
        end
    end
    return eventUsed
end
function TextInputElement:update(dt)
    TextInputElement:superClass().update(self, dt)
    self.cursorBlinkTime = self.cursorBlinkTime + dt
    while self.cursorBlinkTime > 2 * self.cursorBlinkInterval do
        self.cursorBlinkTime = self.cursorBlinkTime - 2 * self.cursorBlinkInterval
    end
    if self.isRepeatingSpecialKeyDown then
        self.repeatingSpecialKeyRemainingDelayTime = self.repeatingSpecialKeyRemainingDelayTime - dt
        if self.repeatingSpecialKeyRemainingDelayTime <= 0 then
            if self.repeatingSpecialKeySym == Input.KEY_left then
                self:moveCursorLeft()
            elseif self.repeatingSpecialKeySym == Input.KEY_right then
                self:moveCursorRight()
            elseif self.repeatingSpecialKeySym == Input.KEY_delete then
                self:deleteText(true)
            elseif self.repeatingSpecialKeySym == Input.KEY_backspace then
                self:deleteText(false)
            end
            self:updateVisibleTextElements()
            self.repeatingSpecialKeyDelayTime = math.max(TextInputElement.MIN_REPEAT_DELAY, (self.repeatingSpecialKeyDelayTime or TextInputElement.INITIAL_REPEAT_DELAY) * 0.1 ^ (dt / 100))
            self.repeatingSpecialKeyRemainingDelayTime = self.repeatingSpecialKeyDelayTime
        end
    end
    if self.useIme and self.imeActive then
        local done, cancel = imeIsComplete()
        if done then
            self.imeActive = false
            self:setForcePressed(false)
            if cancel then
                self:setText(self.preImeText)
                self.preImeText = ""
                self:raiseCallback("onEscPressedCallback", self)
            else
                self:setText(imeGetLastString())
                self:raiseCallback("onEnterPressedCallback", self)
            end
        else
            self:setText(imeGetLastString())
            self:setCursorPosition(imeGetCursorPos() + 1)
            self:updateVisibleTextElements()
        end
    end
    if self.blockTime > 0 then
        self.blockTime = self.blockTime - dt
    end
end
function TextInputElement:draw(clipX1, clipY1, clipX2, clipY2)
    self.text = ""
    TextInputElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
    self.text = self.text
    setTextAlignment(self.textAlignment)
    local neededWidth = self:getNeededTextWidth()
    local textXPos = self.absPosition[1] + self.textOffset[1]
    if self.textAlignment == RenderText.ALIGN_CENTER then
    elseif self.textAlignment == RenderText.ALIGN_RIGHT then
    end
    local textXPos = textXPos + (self.size[1] - self.maxInputTextWidth) / 2
    local _, yOffset = self:getTextOffset()
    local _, yPos = self:getTextPosition(self.text)
    if clipX1 ~= nil then
        setTextClipArea(clipX1, clipY1, clipX2, clipY2)
    end
    local displacementX = 0
    if self.areFrontDotsVisible then
        displacementX = displacementX + self:drawTextPart(self.frontDotsText, textXPos, displacementX, yPos + yOffset)
    end
    if self.isVisibleTextPart1Visible then
        displacementX = displacementX + self:drawTextPart(self.visibleTextPart1, textXPos, displacementX, textYPos)
    end
    if self.isCursorVisible then
        displacementX = displacementX + self:drawCursor(textXPos, displacementX, textYPos)
    end
    if self.isVisibleTextPart2Visible then
        displacementX = displacementX + self:drawTextPart(self.visibleTextPart2, textXPos, displacementX, textYPos)
    end
    if self.areBackDotsVisible then
        self:drawTextPart(self.backDotsText, textXPos, displacementX, textYPos)
    end
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    if clipX1 ~= nil then
        setTextClipArea(0, 0, 1, 1)
    end
end
function TextInputElement:shouldFocusChange(_)
    return not self.forcePressed
end
function TextInputElement:onFocusLeave()
    self:abortIme()
    self:setForcePressed(false)
    TextInputElement:superClass().onFocusLeave(self)
end
function TextInputElement:onFocusActivate()
    if self.blockTime <= 0 then
        TextInputElement:superClass().onFocusActivate(self)
        self:raiseCallback("onEnterCallback", self)
        if self.forcePressed then
            self:abortIme()
            self:setForcePressed(false)
            self:raiseCallback("onEnterPressedCallback", self)
            return
        end
        self:openIme()
        self:setForcePressed(true)
    end
end
function TextInputElement:onClose()
    TextInputElement:superClass().onClose(self)
    self:abortIme()
    self:setForcePressed(false)
end
function TextInputElement:drawTextPart(text, textXPos, displacementX, textYPos)
    local textWidth = 0
    if text ~= "" then
        setTextBold(self.textBold)
        textWidth = getTextWidth(self.textSize, text)
        local alignmentDisplacement = 0
        if self.textAlignment == RenderText.ALIGN_CENTER then
            alignmentDisplacement = textWidth * 0.5
        elseif self.textAlignment == RenderText.ALIGN_RIGHT then
            alignmentDisplacement = textWidth
        end
        if self.text2Size > 0 then
            setTextBold(self.text2Bold)
            setTextColor(unpack(self:getText2Color()))
            renderText(textXPos + alignmentDisplacement + displacementX + (self.text2Offset[1] - self.textOffset[1]), textYPos + (self.text2Offset[2] - self.textOffset[2]), self.text2Size, text)
        end
        setTextBold(self.textBold)
        setTextColor(unpack(self:getTextColor()))
        renderText(textXPos + alignmentDisplacement + displacementX, textYPos, self.textSize, text)
    end
    return textWidth
end
function TextInputElement:drawCursor(textXPos, displacementX, textYPos)
    if self.cursorBlinkTime < self.cursorBlinkInterval then
        local x = math.floor((textXPos + displacementX + self.cursorOffset[1]) / g_pixelSizeX) * g_pixelSizeX
        GuiOverlay.renderOverlay(self.cursor, x, textYPos + self.cursorOffset[2], self.cursorSize[1], self.cursorSize[2])
    end
    return self.cursorNeededSize[1]
end
function TextInputElement:updateVisibleTextElements()
    self.isCursorVisible = false
    self.isVisibleTextPart1Visible = false
    self.visibleTextPart1 = ""
    self.isVisibleTextPart2Visible = false
    self.visibleTextPart2 = ""
    self.areFrontDotsVisible = false
    self.areBackDotsVisible = false
    self.firstVisibleCharacterPosition = 1
    setTextBold(self.textBold)
    local displayText = self.text
    if self.isPassword then
        displayText = string.rep("*", utf8Strlen(self.text))
    end
    local textLength = utf8Strlen(displayText)
    local availableTextWidth = self:getAvailableTextWidth()
    if self:getIsActive() and self.forcePressed then
        self.isCursorVisible = true
        if self.cursorPosition < self.firstVisibleCharacterPosition then
            self.firstVisibleCharacterPosition = self.cursorPosition
        end
        if self.firstVisibleCharacterPosition > 1 then
            self.areFrontDotsVisible = true
        end
        local textInvisibleFrontTrimmed = utf8Substr(displayText, self.firstVisibleCharacterPosition - 1)
        local textWidthInvisibleFrontTrimmed = getTextWidth(self.textSize, textInvisibleFrontTrimmed)
        local visibleText = self:getAvailableTextWidth()
        if visibleText and (visibleText < textWidthInvisibleFrontTrimmed and self.cursorPosition <= textLength) then
            self.areBackDotsVisible = true
            visibleText = self:getAvailableTextWidth()
        end
        local visibleText = TextInputElement.limitTextToAvailableWidth(textInvisibleFrontTrimmed, self.textSize, visibleText)
        local visibleTextWidth = getTextWidth(self.textSize, visibleText)
        local visibleTextLength = utf8Strlen(visibleText)
        if visibleText and self.cursorPosition > self.firstVisibleCharacterPosition + visibleTextLength then
            self.areFrontDotsVisible = true
            visibleText = self:getAvailableTextWidth()
            local textTrimmedAtCursor = utf8Substr(textInvisibleFrontTrimmed, 0, self.cursorPosition - self.firstVisibleCharacterPosition)
            visibleText = TextInputElement.limitTextToAvailableWidth(textTrimmedAtCursor, self.textSize, visibleText, true)
            visibleTextWidth = getTextWidth(self.textSize, visibleText)
            visibleTextLength = utf8Strlen(visibleText)
            self.firstVisibleCharacterPosition = self.cursorPosition - visibleTextLength
        end
        if visibleText and (not self.areBackDotsVisible and self.firstVisibleCharacterPosition > 1) then
            local nextCharacter = utf8Substr(displayText, self.firstVisibleCharacterPosition - 1, 1) or ""
            local additionalCharacterWidth = getTextWidth(self.textSize, nextCharacter)
            if visibleTextWidth + additionalCharacterWidth <= visibleText and self.firstVisibleCharacterPosition > 1 then
                while visibleTextWidth + additionalCharacterWidth <= visibleText and self.firstVisibleCharacterPosition > 1 do
                    self.firstVisibleCharacterPosition = self.firstVisibleCharacterPosition - 1
                    visibleTextWidth = visibleTextWidth + additionalCharacterWidth
                    local nextCharacter = utf8Substr(displayText, self.firstVisibleCharacterPosition - 1, 1) or ""
                    additionalCharacterWidth = getTextWidth(self.textSize, nextCharacter)
                end
                if self.firstVisibleCharacterPosition > 1 then
                    self.areFrontDotsVisible = false
                    local availableWidthWithoutFrontDots = self:getAvailableTextWidth()
                    self.areFrontDotsVisible = true
                    if getTextWidth(self.textSize, displayText) <= availableWidthWithoutFrontDots then
                        self.areFrontDotsVisible = false
                        self.firstVisibleCharacterPosition = 1
                    end
                else
                    self.areFrontDotsVisible = false
                end
                visibleText = utf8Substr(displayText, self.firstVisibleCharacterPosition - 1, visibleTextLength + self.firstVisibleCharacterPosition)
            end
        end
        self.isVisibleTextPart1Visible = true
        self.visibleTextPart1 = utf8Substr(visibleText, 0, self.cursorPosition - self.firstVisibleCharacterPosition)
        if self.cursorPosition - self.firstVisibleCharacterPosition < visibleTextLength then
            self.isVisibleTextPart2Visible = true
            self.visibleTextPart2 = utf8Substr(visibleText, self.cursorPosition - self.firstVisibleCharacterPosition)
        end
    else
        local textInvisibleFrontTrimmed = getTextWidth(self.textSize, displayText)
        if availableTextWidth and availableTextWidth < textInvisibleFrontTrimmed then
            self.areBackDotsVisible = true
            availableTextWidth = self:getAvailableTextWidth()
        end
        if availableTextWidth and availableTextWidth < textInvisibleFrontTrimmed then
            self.visibleTextPart1 = TextInputElement.limitTextToAvailableWidth(displayText, self.textSize, availableTextWidth)
            self.isVisibleTextPart1Visible = true
        else
            self.visibleTextPart1 = displayText
            self.isVisibleTextPart1Visible = true
        end
    end
    setTextBold(false)
end
function TextInputElement.limitTextToAvailableWidth(text, textSize, availableWidth, trimFront)
    local indexOfFirstCharacter = 0
    local indexOfLastCharacter = utf8Strlen(text)
    if availableWidth then
        if trimFront then
            while availableWidth < getTextWidth(textSize, text) do
                text = utf8Substr(text, 1)
            end
        else
            local textLength = utf8Strlen(text)
            while availableWidth < getTextWidth(textSize, text) do
                textLength = textLength - 1
                text = utf8Substr(text, 0, textLength)
            end
        end
    end
    return text, indexOfFirstCharacter, indexOfLastCharacter
end
function TextInputElement:getAvailableTextWidth()
    if not self.maxInputTextWidth then
        return nil
    end
    local availableTextWidth = self.maxInputTextWidth
    if self.areFrontDotsVisible then
        availableTextWidth = availableTextWidth - getTextWidth(self.textSize, self.frontDotsText)
    end
    if self.isCursorVisible then
    end
    if self.areBackDotsVisible then
        availableTextWidth = availableTextWidth - getTextWidth(self.textSize, self.backDotsText)
    end
    return availableTextWidth
end
function TextInputElement:getNeededTextWidth()
    local neededWidth = 0
    if self.areFrontDotsVisible then
        neededWidth = neededWidth + getTextWidth(self.textSize, self.frontDotsText)
    end
    if self.isVisibleTextPart1Visible then
        neededWidth = neededWidth + getTextWidth(self.textSize, self.visibleTextPart1)
    end
    if self.isCursorVisible then
    end
    if self.isVisibleTextPart2Visible then
        neededWidth = neededWidth + getTextWidth(self.textSize, self.visibleTextPart2)
    end
    if self.areBackDotsVisible then
        neededWidth = neededWidth + getTextWidth(self.textSize, self.backDotsText)
    end
    return neededWidth
end
function TextInputElement:getText()
    return self.text
end
function TextInputElement:updateAbsolutePosition()
    self.sourceText = self.text
    TextInputElement:superClass().updateAbsolutePosition(self)
end