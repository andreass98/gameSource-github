OptionSliderElement = {}
local OptionSliderElement_mt = Class(OptionSliderElement, MultiTextOptionElement)
Gui.registerGuiElement("OptionSlider", OptionSliderElement)
Gui.registerGuiElementProcFunction("OptionSlider", Gui.assignPlaySampleCallback)
function OptionSliderElement.new(target, custom_mt)
    -- upvalues: (copy) OptionSliderElement_mt
    local self = MultiTextOptionElement.new(target, custom_mt or OptionSliderElement_mt)
    self.sliderElement = nil
    self.sliderOffset = nil
    self.defaultProfileSlider = nil
    self.defaultProfileSliderRound = nil
    self.useFillingBar = false
    self.fillingBarElement = nil
    self.defaultProfileFillingBar = nil
    self.defaultProfileFillingBarThreePart = nil
    self.updateTextPosition = true
    return self
end
function OptionSliderElement:loadFromXML(xmlFile, key)
    OptionSliderElement:superClass().loadFromXML(self, xmlFile, key)
    self.sliderOffset = GuiUtils.getNormalizedXValue(getXMLInt(xmlFile, key .. "#sliderOffset"), self.sliderOffset)
    self.useFillingBar = getXMLBool(xmlFile, key .. "#useFillingBar") or self.useFillingBar
    self.updateTextPosition = getXMLBool(xmlFile, key .. "#updateTextPosition") or self.updateTextPosition
end
function OptionSliderElement:loadProfile(profile, applyProfile)
    OptionSliderElement:superClass().loadProfile(self, profile, applyProfile)
    self.sliderOffset = GuiUtils.getNormalizedXValue(profile:getValue("sliderOffset"), self.sliderOffset)
    self.useFillingBar = profile:getBool("useFillingBar", self.useFillingBar)
    self.updateTextPosition = profile:getBool("updateTextPosition", self.updateTextPosition)
    self.defaultProfileSlider = profile:getValue("defaultProfileSlider", self.defaultProfileSlider)
    self.defaultProfileSliderRound = profile:getValue("defaultProfileSliderRound", self.defaultProfileSliderRound)
    self.defaultProfileFillingBar = profile:getValue("defaultProfileFillingBar", self.defaultProfileFillingBar)
    self.defaultProfileFillingBarThreePart = profile:getValue("defaultProfileFillingBarThreePart", self.defaultProfileFillingBarThreePart)
end
function OptionSliderElement:copyAttributes(src)
    OptionSliderElement:superClass().copyAttributes(self, src)
    self.sliderOffset = src.sliderOffset
    self.useFillingBar = src.useFillingBar
    self.updateTextPosition = src.updateTextPosition
    self.defaultProfileSlider = src.defaultProfileSlider
    self.defaultProfileSliderRound = src.defaultProfileSliderRound
    self.defaultProfileFillingBar = src.defaultProfileFillingBar
    self.defaultProfileFillingBarThreePart = src.defaultProfileFillingBarThreePart
end
function OptionSliderElement:setElementsByName()
    OptionSliderElement:superClass().setElementsByName(self)
    for _, element in pairs(self.elements) do
        if element.name == "slider" then
            self.sliderElement = element
            element.target = self
        end
        if element.name == "fillingBar" then
            self.fillingBarElement = element
            element.target = self
        end
    end
    if self.fillingBarElement == nil then
        self.useFillingBar = false
    end
    if self.sliderElement == nil then
        Logging.warning("OptionSliderElement: could not find a slider element for element with profile " .. self.profile)
    elseif self.leftButtonElement ~= nil and self.sliderElement.absSize[1] + self.leftButtonElement.absSize[1] * 2 >= self.absSize[1] then
        self.sliderOffset = self.absSize[1] / 2
        Logging.warning("OptionSliderElement: not enough space for slider movement with current settings in profile " .. self.profile)
    end
end
function OptionSliderElement:addDefaultElements()
    OptionSliderElement:superClass().addDefaultElements(self)
    if self.autoAddDefaultElements then
        if self:getDescendantByName("fillingBar") == nil then
            if self.defaultProfileFillingBar == nil then
                if self.defaultProfileFillingBarThreePart ~= nil then
                    local baseElement = ThreePartBitmapElement.new(self)
                    baseElement.name = "fillingBar"
                    self:addElement(baseElement)
                    baseElement:applyProfile(self.defaultProfileFillingBarThreePart)
                end
            else
                local baseElement = BitmapElement.new(self)
                baseElement.name = "fillingBar"
                self:addElement(baseElement)
                baseElement:applyProfile(self.defaultProfileFillingBar)
            end
        end
        if self:getDescendantByName("slider") == nil then
            if self.defaultProfileSliderRound ~= nil then
                local baseElement = RoundCornerElement.new(self)
                baseElement.name = "slider"
                self:addElement(baseElement)
                baseElement:applyProfile(self.defaultProfileSliderRound)
                return
            end
            if self.defaultProfileSlider ~= nil then
                local baseElement = BitmapElement.new(self)
                baseElement.name = "slider"
                self:addElement(baseElement)
                baseElement:applyProfile(self.defaultProfileSlider)
            end
        end
    end
end
function OptionSliderElement:onOpen()
    OptionSliderElement:superClass().onOpen(self)
    self:updateSlider()
end
function OptionSliderElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsActive() then
        eventUsed = self.wasContinuousTrigger and isUp and true or (MultiTextOptionElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed)
        if isDown then
            local rightButton = not self.hideLeftRightButtons
            if rightButton then
                rightButton = GuiUtils.checkOverlayOverlap(posX, posY, self.leftButtonElement.absPosition[1], self.leftButtonElement.absPosition[2], self.leftButtonElement.absSize[1], self.leftButtonElement.absSize[2], self.leftButtonElement.hotspot)
            end
            self.isLeftButtonPressed = rightButton
            local rightButton = self.rightButtonElement
            local slider = not self.hideLeftRightButtons
            if slider then
                slider = GuiUtils.checkOverlayOverlap(posX, posY, rightButton.absPosition[1], rightButton.absPosition[2], rightButton.absSize[1], rightButton.absSize[2], rightButton.hotspot)
            end
            self.isRightButtonPressed = slider
            local slider = self.sliderElement
            local mouseMoveDistance = false
            if slider ~= nil then
                mouseMoveDistance = GuiUtils.checkOverlayOverlap(posX, posY, slider.absPosition[1], slider.absPosition[2], slider.absSize[1], slider.absSize[2], slider.hotspot)
            end
            self.isSliderPressed = mouseMoveDistance
            self.isSliderAreaPressed = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1] + self.sliderOffset, self.absPosition[2], self.absSize[1] - 2 * self.sliderOffset, self.absSize[2])
            if self.sliderMousePosX == nil then
                self.sliderMousePosX = posX
            end
            self.delayTime = g_time
        elseif isUp then
            self.delayTime = math.huge
            self.scrollDelayDuration = MultiTextOptionElement.FIRST_INPUT_DELAY
            self.wasContinuousTrigger = false
            self.continuousTriggerTime = 0
            self.isLeftButtonPressed = false
            self.leftDelayTime = 0
            self.isRightButtonPressed = false
            self.rightDelayTime = 0
            self.isSliderPressed = false
            self.isSliderAreaPressed = false
            self.sliderMousePosX = nil
            self.hasWrapped = false
        end
        if eventUsed or not GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], nil) then
            if self.inputEntered and not self.focusActive then
                FocusManager:unsetHighlight(self)
                self.inputEntered = false
            end
        else
            if not (self.inputEntered or self:getIsFocused()) then
                FocusManager:setHighlight(self)
                self.inputEntered = true
            end
            if #self.texts > 1 and self.isSliderAreaPressed then
                if not self:getIsFocused() then
                    FocusManager:setFocus(self)
                end
                local leftButton = self.sliderElement
                local rightButton = leftButton.absSize[1]
                local slider = (self.absSize[1] - 2 * self.sliderOffset - rightButton) / (#self.texts - 1)
                local sliderLocalPosX = posX - self.absPosition[1] - self.sliderOffset - leftButton.absSize[1] * 0.5
                if self.isSliderPressed then
                    sliderLocalPosX = leftButton.absPosition[1] - self.absPosition[1] - self.sliderOffset
                end
                local sliderPosX = MathUtil.snapValue(sliderLocalPosX + (posX - self.sliderMousePosX), slider)
                local state = math.clamp(sliderPosX, 0, self.absSize[1] - rightButton - 2 * self.sliderOffset)
                local state = MathUtil.round(state / slider) + 1
                if state ~= self.state then
                    if self.isSliderPressed then
                        self.sliderMousePosX = self.sliderMousePosX + slider * (state - self.state)
                    end
                    self.isSliderPressed = true
                    self:setState(state, true)
                end
                leftButton:setAbsolutePosition(self.absPosition[1] + state + self.sliderOffset, leftButton.absPosition[2])
                if self.updateTextPosition then
                    self.textElement:setAbsolutePosition(leftButton.absPosition[1] - (self.textElement.absSize[1] - leftButton.absSize[1]) * 0.5, self.textElement.absPosition[2])
                end
                if self.useFillingBar then
                    self.fillingBarElement:setSize((self.state - 1) / (#self.texts - 1) * (self.absSize[1] - self.sliderOffset * 2) + self.sliderOffset, nil)
                    return eventUsed
                end
            end
        end
    end
    return eventUsed
end
function OptionSliderElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
    if self:getIsActive() then
        eventUsed = self.wasContinuousTrigger and isUp and true or (MultiTextOptionElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed) and true or eventUsed)
        if isDown then
            local rightButton = not self.hideLeftRightButtons
            if rightButton then
                rightButton = GuiUtils.checkOverlayOverlap(posX, posY, self.leftButtonElement.absPosition[1], self.leftButtonElement.absPosition[2], self.leftButtonElement.absSize[1], self.leftButtonElement.absSize[2], self.leftButtonElement.hotspot)
            end
            self.isLeftButtonPressed = rightButton
            local rightButton = self.rightButtonElement
            local slider = not self.hideLeftRightButtons
            if slider then
                slider = GuiUtils.checkOverlayOverlap(posX, posY, rightButton.absPosition[1], rightButton.absPosition[2], rightButton.absSize[1], rightButton.absSize[2], rightButton.hotspot)
            end
            self.isRightButtonPressed = slider
            local slider = self.sliderElement
            local mouseMoveDistance = false
            if slider ~= nil then
                mouseMoveDistance = GuiUtils.checkOverlayOverlap(posX, posY, slider.absPosition[1], slider.absPosition[2], slider.absSize[1], slider.absSize[2], slider.hotspot)
            end
            self.isSliderPressed = mouseMoveDistance
            if self.sliderMousePosX == nil then
                self.sliderMousePosX = posX
            end
            self.delayTime = g_time
        elseif isUp then
            self.delayTime = math.huge
            self.scrollDelayDuration = MultiTextOptionElement.FIRST_INPUT_DELAY
            self.wasContinuousTrigger = false
            self.continuousTriggerTime = 0
            self.isLeftButtonPressed = false
            self.leftDelayTime = 0
            self.isRightButtonPressed = false
            self.rightDelayTime = 0
            self.isSliderPressed = false
            self.sliderMousePosX = nil
            self.hasWrapped = false
        end
        if eventUsed or not GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], nil) then
            if self.inputEntered and not self:getIsFocused() then
                FocusManager:unsetHighlight(self)
                self.inputEntered = false
            end
        else
            if not (self.inputEntered or self:getIsFocused()) then
                FocusManager:setHighlight(self)
                self.inputEntered = true
            end
            if self.isSliderPressed and #self.texts > 1 then
                if not self:getIsFocused() then
                    FocusManager:setFocus(self)
                end
                local leftButton = self.sliderElement
                local rightButton = leftButton.absSize[1]
                local slider = (self.absSize[1] - 2 * self.sliderOffset - rightButton) / (#self.texts - 1)
                local sliderPosX = MathUtil.snapValue(leftButton.absPosition[1] - self.absPosition[1] - self.sliderOffset + (posX - self.sliderMousePosX), slider)
                local state = math.clamp(sliderPosX, 0, self.absSize[1] - rightButton - 2 * self.sliderOffset)
                local state = MathUtil.round(state / slider) + 1
                if state ~= self.state then
                    self.sliderMousePosX = self.sliderMousePosX + slider * (state - self.state)
                    self:setState(state, true)
                end
                leftButton:setAbsolutePosition(self.absPosition[1] + state + self.sliderOffset, leftButton.absPosition[2])
                if self.updateTextPosition then
                    self.textElement:setAbsolutePosition(leftButton.absPosition[1] - (self.textElement.absSize[1] - leftButton.absSize[1]) * 0.5, self.textElement.absPosition[2])
                end
                if self.useFillingBar then
                    self.fillingBarElement:setSize((self.state - 1) / (#self.texts - 1) * (self.absSize[1] - self.sliderOffset * 2) + self.sliderOffset, nil)
                    return eventUsed
                end
            end
        end
    end
    return eventUsed
end
function OptionSliderElement:updateSlider()
    if self.sliderElement ~= nil then
        if self.sliderOffset == nil then
            self.sliderOffset = self.leftButtonElement.absSize[1]
        end
        local slider = self.sliderElement
        local maxVal = self.absPosition[1] + self.absSize[1] - slider.absSize[1] - self.sliderOffset
        if #self.texts > 1 then
        end
        slider:setAbsolutePosition(maxVal, slider.absPosition[2])
        if self.updateTextPosition then
            self.textElement:setAbsolutePosition(maxVal - (self.textElement.absSize[1] - slider.absSize[1]) * 0.5, self.textElement.absPosition[2])
        end
        if self.useFillingBar then
            local fillingBarSize = self.absSize[1] - self.sliderOffset
            if #self.texts > 1 then
                fillingBarSize = (self.state - 1) / (#self.texts - 1) * (self.absSize[1] - self.sliderOffset * 2) + self.sliderOffset
            end
            self.fillingBarElement:setSize(fillingBarSize, nil)
        end
    end
end
function OptionSliderElement:updateAbsolutePosition()
    OptionSliderElement:superClass().updateAbsolutePosition(self)
    self:updateSlider()
end
function OptionSliderElement:updateContentElement()
    OptionSliderElement:superClass().updateContentElement(self)
    self:updateSlider()
end