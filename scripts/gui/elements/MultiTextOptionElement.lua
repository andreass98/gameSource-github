MultiTextOptionElement = {}
MultiTextOptionElement.ELEMENT_BG = 1
MultiTextOptionElement.ELEMENT_LEFT = 2
MultiTextOptionElement.ELEMENT_RIGHT = 3
MultiTextOptionElement.ELEMENT_TEXT = 4
MultiTextOptionElement.FIRST_INPUT_DELAY = 400
MultiTextOptionElement.INPUT_DELAY = 200
MultiTextOptionElement.FAST_SCROLL_DELAY = 1800
local MultiTextOptionElement_mt = Class(MultiTextOptionElement, GuiElement)
Gui.registerGuiElement("MultiTextOption", MultiTextOptionElement)
Gui.registerGuiElementProcFunction("MultiTextOption", Gui.assignPlaySampleCallback)
function MultiTextOptionElement.new(target, custom_mt)
    -- upvalues: (copy) MultiTextOptionElement_mt
    local self = GuiElement.new(target, custom_mt or MultiTextOptionElement_mt)
    self:include(IndexChangeSubjectMixin)
    self:include(PlaySampleMixin)
    self.isChecked = false
    self.inputEntered = false
    self.buttonLRChange = false
    self.canChangeState = true
    self.state = 1
    self.wrap = true
    self.hideLeftRightButtons = false
    self.hideButtonOnLimitReached = false
    self.disableButtonsOnSingleText = false
    self.texts = {}
    self.registerContinuousInput = true
    self.continuousInputStep = nil
    self.useDynamicInputSteps = nil
    self.dynamicInputStep = nil
    self.continuousTriggerTime = 0
    self.isLeftButtonPressed = false
    self.isRightButtonPressed = false
    self.wasContinuousTrigger = false
    self.scrollDelayDuration = MultiTextOptionElement.FIRST_INPUT_DELAY
    self.baseScrollDelayDuration = MultiTextOptionElement.INPUT_DELAY
    self.leftDelayTime = 0
    self.rightDelayTime = 0
    self.delayTime = 0
    self.leftButtonElement = nil
    self.rightButtonElement = nil
    self.textElement = nil
    self.labelElement = nil
    self.iconElement = nil
    self.bgElement = nil
    self.defaultProfileButtonLeft = nil
    self.defaultProfileButtonRight = nil
    self.defaultProfileText = nil
    self.defaultProfileBg = nil
    self.defaultProfileBgRound = nil
    self.defaultProfileBgThreePart = nil
    self.autoAddDefaultElements = false
    self.gradientElements = {}
    return self
end
function MultiTextOptionElement:loadFromXML(xmlFile, key)
    local xmlFilename = getXMLFilename(xmlFile)
    local modName, _ = Utils.getModNameAndBaseDirectory(xmlFilename)
    if modName ~= nil then
        self.customEnvironment = modName
    end
    MultiTextOptionElement:superClass().loadFromXML(self, xmlFile, key)
    self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
    self:addCallback(xmlFile, key .. "#onFocus", "onFocusCallback")
    self:addCallback(xmlFile, key .. "#onLeave", "onLeaveCallback")
    self.wrap = Utils.getNoNil(getXMLBool(xmlFile, key .. "#wrap"), self.wrap)
    self.hideLeftRightButtons = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideLeftRightButtons"), self.hideLeftRightButtons)
    self.hideButtonOnLimitReached = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideButtonOnLimitReached"), self.hideButtonOnLimitReached)
    self.disableButtonsOnSingleText = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disableButtonsOnSingleText"), self.disableButtonsOnSingleText)
    self.buttonLRChange = Utils.getNoNil(getXMLBool(xmlFile, key .. "#buttonLRChange"), self.buttonLRChange)
    self.baseScrollDelayDuration = getXMLInt(xmlFile, key .. "#scrollDelayDuration") or self.baseScrollDelayDuration
    self.continuousInputStep = getXMLInt(xmlFile, key .. "#continuousInputStep") or self.continuousInputStep
    self.useDynamicInputSteps = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useDynamicInputSteps"), self.useDynamicInputSteps)
    self.registerContinuousInput = Utils.getNoNil(getXMLBool(xmlFile, key .. "#registerContinuousInput"), self.registerContinuousInput)
    local text = getXMLString(xmlFile, key .. "#texts")
    if text ~= nil then
        local texts = text:split("|")
        for _, textPart in pairs(texts) do
            if textPart:sub(1, 6) == "$l10n_" then
                local textPart = g_i18n:getText(textPart:sub(7), self.customEnvironment)
            end
            table.insert(self.texts, textPart)
        end
    end
    self.xmlFile = xmlFile
    self.xmlKey = key
end
function MultiTextOptionElement:loadProfile(profile, applyProfile)
    MultiTextOptionElement:superClass().loadProfile(self, profile, applyProfile)
    self.wrap = profile:getBool("wrap", self.wrap)
    self.hideLeftRightButtons = profile:getBool("hideLeftRightButtons", self.hideLeftRightButtons)
    self.hideButtonOnLimitReached = profile:getBool("hideButtonOnLimitReached", self.hideButtonOnLimitReached)
    self.disableButtonsOnSingleText = profile:getBool("disableButtonsOnSingleText", self.disableButtonsOnSingleText)
    self.buttonLRChange = profile:getBool("buttonLRChange", self.buttonLRChange)
    self.baseScrollDelayDuration = profile:getNumber("scrollDelayDuration", self.baseScrollDelayDuration)
    self.continuousInputStep = profile:getNumber("continuousInputStep", self.continuousInputStep)
    self.useDynamicInputSteps = profile:getBool("useDynamicInputSteps", self.useDynamicInputSteps)
    self.registerContinuousInput = profile:getBool("registerContinuousInput", self.registerContinuousInput)
    self.defaultProfileButtonLeft = profile:getValue("defaultProfileButtonLeft", self.defaultProfileButtonLeft)
    self.defaultProfileButtonRight = profile:getValue("defaultProfileButtonRight", self.defaultProfileButtonRight)
    self.defaultProfileText = profile:getValue("defaultProfileText", self.defaultProfileText)
    self.defaultProfileBg = profile:getValue("defaultProfileBg", self.defaultProfileBg)
    self.defaultProfileBgRound = profile:getValue("defaultProfileBgRound", self.defaultProfileBgRound)
    self.defaultProfileBgThreePart = profile:getValue("defaultProfileBgThreePart", self.defaultProfileBgThreePart)
    self.autoAddDefaultElements = profile:getBool("autoAddDefaultElements", self.autoAddDefaultElements)
    local text = profile:getValue("texts")
    if text ~= nil then
        local texts = text:split("|")
        for _, textPart in pairs(texts) do
            if textPart:sub(1, 6) == "$l10n_" then
                local textPart = g_i18n:getText(textPart:sub(7))
            end
            table.insert(self.texts, textPart)
        end
    end
end
function MultiTextOptionElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
    local ret = MultiTextOptionElement:superClass().clone(self, parent, includeId, suppressOnCreate, blockFocusHandlingReload)
    ret:addDefaultElements()
    ret:setElementsByName()
    return ret
end
function MultiTextOptionElement:copyAttributes(src)
    MultiTextOptionElement:superClass().copyAttributes(self, src)
    self.isChecked = src.isChecked
    self.buttonLRChange = src.buttonLRChange
    self.state = src.state
    self.wrap = src.wrap
    self.hideLeftRightButtons = src.hideLeftRightButtons
    self.hideButtonOnLimitReached = src.hideButtonOnLimitReached
    self.disableButtonsOnSingleText = src.disableButtonsOnSingleText
    self.baseScrollDelayDuration = src.baseScrollDelayDuration
    self.continuousInputStep = src.continuousInputStep
    self.useDynamicInputSteps = src.useDynamicInputSteps
    self.registerContinuousInput = src.registerContinuousInput
    self.canChangeState = src.canChangeState
    self.defaultProfileButtonLeft = src.defaultProfileButtonLeft
    self.defaultProfileButtonRight = src.defaultProfileButtonRight
    self.defaultProfileText = src.defaultProfileText
    self.defaultProfileBg = src.defaultProfileBg
    self.defaultProfileBgRound = src.defaultProfileBgRound
    self.defaultProfileBgThreePart = src.defaultProfileBgThreePart
    self.autoAddDefaultElements = src.autoAddDefaultElements
    self.onClickCallback = src.onClickCallback
    self.onLeaveCallback = src.onLeaveCallback
    self.onFocusCallback = src.onFocusCallback
    for _, text in pairs(src.texts) do
        self:addText(text)
    end
    GuiMixin.cloneMixin(IndexChangeSubjectMixin, src, self)
    GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end
function MultiTextOptionElement:onGuiSetupFinished()
    self:addDefaultElements()
    self:setElementsByName()
    self:updateAbsolutePosition()
    if self.leftButtonElement ~= nil then
        self.leftButtonElement.soundDisabled = true
    end
    if self.rightButtonElement ~= nil then
        self.rightButtonElement.soundDisabled = true
    end
end
function MultiTextOptionElement:setElementsByName()
    for _, element in pairs(self.elements) do
        if element.name == nil then
            Logging.warning("MultiTextOptionElement: Could not find a name for element with profile name \'%s\', using default element", element.profile)
            return
        end
        if element.name == "left" then
            if self.leftButtonElement ~= nil and self.leftButtonElement ~= element then
                self.leftButtonElement:delete()
            end
            self.leftButtonElement = element
            element.target = self
            element:setHandleFocus(false)
            element:setCallback("onClickCallback", "onLeftButtonClicked")
            element:setDisabled(self.disabled)
            element:setVisible(not self.hideLeftRightButtons)
        elseif element.name == "right" then
            if self.rightButtonElement ~= nil and self.rightButtonElement ~= element then
                self.rightButtonElement:delete()
            end
            self.rightButtonElement = element
            element.target = self
            element:setHandleFocus(false)
            element:setCallback("onClickCallback", "onRightButtonClicked")
            element:setDisabled(self.disabled)
            element:setVisible(not self.hideLeftRightButtons)
        elseif element.name == "label" then
            self.labelElement = element
        elseif element.name == "text" then
            if element:isa(TextElement) then
                if self.textElement ~= nil and self.textElement ~= element then
                    self.textElement:delete()
                end
                self.textElement = element
                self:updateContentElement()
            end
        elseif element.name == "icon" then
            self.iconElement = element
            self:updateContentElement()
        elseif element.name == "gradient" then
            if element:isa(BitmapElement) then
                table.insert(self.gradientElements, element)
            end
        elseif element.name == "background" then
            if self.bgElement ~= nil and self.bgElement ~= element then
                self.bgElement:delete()
            end
            self.bgElement = element
            element:setSize(self.size[1])
        end
    end
end
function MultiTextOptionElement:addDefaultElements()
    if self.autoAddDefaultElements then
        if self:getDescendantByName("background") == nil then
            if self.defaultProfileBgRound == nil or self.defaultProfileBgRound == "" then
                if self.defaultProfileBgThreePart == nil or self.defaultProfileBgThreePart == "" then
                    if self.defaultProfileBg ~= nil then
                        local baseElement = BitmapElement.new(self)
                        baseElement.name = "background"
                        self:addElement(baseElement)
                        baseElement:applyProfile(self.defaultProfileBg)
                    end
                else
                    local baseElement = ThreePartBitmapElement.new(self)
                    baseElement.name = "background"
                    self:addElement(baseElement)
                    baseElement:applyProfile(self.defaultProfileBgThreePart)
                end
            else
                local baseElement = RoundCornerElement.new(self)
                baseElement.name = "background"
                self:addElement(baseElement)
                baseElement:applyProfile(self.defaultProfileBgRound)
            end
        end
        if self:getDescendantByName("left") == nil then
            local baseElement = ButtonElement.new(self)
            baseElement.name = "left"
            self:addElement(baseElement)
            baseElement:applyProfile(self.defaultProfileButtonLeft)
        end
        if self:getDescendantByName("right") == nil then
            local baseElement = ButtonElement.new(self)
            baseElement.name = "right"
            self:addElement(baseElement)
            baseElement:applyProfile(self.defaultProfileButtonRight)
        end
        if self:getDescendantByName("text") == nil then
            local baseElement = TextElement.new(self)
            baseElement.name = "text"
            self:addElement(baseElement)
            baseElement:applyProfile(self.defaultProfileText)
        end
    end
end
function MultiTextOptionElement:setState(state, forceEvent)
    local numTexts = #self.texts
    self.state = math.max(math.min(state, numTexts), 1)
    self:updateContentElement()
    if forceEvent then
        self:raiseClickCallback(true)
    end
    self:notifyIndexChange(self.state, numTexts)
end
function MultiTextOptionElement:getState()
    return self.state
end
function MultiTextOptionElement:disableButtonSounds()
    if self.leftButtonElement ~= nil then
        self.leftButtonElement:disablePlaySample()
    end
    if self.rightButtonElement ~= nil then
        self.rightButtonElement:disablePlaySample()
    end
end
function MultiTextOptionElement:addText(text, i)
    if i == nil then
        table.insert(self.texts, text)
    else
        table.insert(self.texts, i, text)
    end
    self:updateContentElement()
    if self.useDynamicInputSteps ~= false then
        self.dynamicInputStep = math.min(math.floor(#self.texts / 5), 10)
    end
    self:notifyIndexChange(self.state, #self.texts)
end
function MultiTextOptionElement:setTexts(texts)
    if texts == nil then
        self.texts = {}
    else
        self.texts = texts
    end
    self.isImageMode = nil
    self.state = math.min(self.state, #self.texts)
    self:updateContentElement()
    if self.useDynamicInputSteps ~= false then
        self.dynamicInputStep = math.min(math.floor(#self.texts / 5), 10)
    end
    self:notifyIndexChange(self.state, #self.texts)
end
function MultiTextOptionElement:setIcons(icons)
    if icons == nil then
        self.texts = {}
    else
        self.texts = icons
    end
    self.isImageMode = true
    self.state = math.min(self.state, #self.texts)
    self:updateContentElement()
    self:notifyIndexChange(self.state, #self.texts)
end
function MultiTextOptionElement:setLabel(labelString)
    if self.labelElement ~= nil then
        self.labelElement:setText(labelString)
    end
end
function MultiTextOptionElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsActive() then
        eventUsed = (MultiTextOptionElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed or self.wasContinuousTrigger and isUp) or self.wasContinuousTrigger and isUp) and true or eventUsed
        local isInElement = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], nil)
        if isInElement and isDown then
            local rightButton = not self.hideLeftRightButtons
            if rightButton then
                rightButton = GuiUtils.checkOverlayOverlap(posX, posY, self.leftButtonElement.absPosition[1], self.leftButtonElement.absPosition[2], self.leftButtonElement.size[1], self.leftButtonElement.size[2], self.leftButtonElement.hotspot)
            end
            self.isLeftButtonPressed = rightButton
            local rightButton = self.rightButtonElement
            self.isRightButtonPressed = not self.hideLeftRightButtons and GuiUtils.checkOverlayOverlap(posX, posY, rightButton.absPosition[1], rightButton.absPosition[2], rightButton.size[1], rightButton.size[2], rightButton.hotspot)
            self.delayTime = g_time
        elseif (self.leftButtonElement == nil or not self.leftButtonElement:getIsPressed()) and (self.rightButtonElement == nil or not self.rightButtonElement:getIsPressed()) then
            self.delayTime = math.huge
            self.isLeftButtonPressed = false
            self.isRightButtonPressed = false
            self:releaseInput()
        end
        if eventUsed or not isInElement then
            if self.inputEntered and not self:getIsFocused() then
                FocusManager:unsetHighlight(self)
                self.inputEntered = false
            end
        elseif not (self.inputEntered or self:getIsFocused()) then
            FocusManager:setHighlight(self)
            self.inputEntered = true
            return eventUsed
        end
    end
    return eventUsed
end
function MultiTextOptionElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
    if self:getIsActive() then
        eventUsed = (MultiTextOptionElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed or self.wasContinuousTrigger and isUp) or self.wasContinuousTrigger and isUp) and true or eventUsed
        local isInElement = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.hotspot)
        if isInElement and isDown then
            local rightButton = not self.hideLeftRightButtons
            if rightButton then
                rightButton = GuiUtils.checkOverlayOverlap(posX, posY, self.leftButtonElement.absPosition[1], self.leftButtonElement.absPosition[2], self.leftButtonElement.size[1], self.leftButtonElement.size[2], self.leftButtonElement.hotspot)
            end
            self.isLeftButtonPressed = rightButton
            local rightButton = self.rightButtonElement
            self.isRightButtonPressed = not self.hideLeftRightButtons and GuiUtils.checkOverlayOverlap(posX, posY, rightButton.absPosition[1], rightButton.absPosition[2], rightButton.size[1], rightButton.size[2], rightButton.hotspot)
            self.delayTime = g_time
        elseif (self.leftButtonElement == nil or not self.leftButtonElement:getIsPressed()) and (self.rightButtonElement == nil or not self.rightButtonElement:getIsPressed()) then
            self.delayTime = math.huge
            self.isLeftButtonPressed = false
            self.isRightButtonPressed = false
            self:releaseInput()
        end
        if eventUsed or not isInElement then
            if self.inputEntered and not self:getIsFocused() then
                FocusManager:unsetHighlight(self)
                self.inputEntered = false
            end
        elseif not (self.inputEntered or self:getIsFocused()) then
            FocusManager:setHighlight(self)
            self.inputEntered = true
            return eventUsed
        end
    end
    return eventUsed
end
function MultiTextOptionElement:inputEvent(action, value, eventUsed)
    eventUsed = MultiTextOptionElement:superClass().inputEvent(self, action, value, eventUsed)
    if not eventUsed then
        self.registeredInputEventThisFrame = true
        if action == InputAction.MENU_AXIS_LEFT_RIGHT then
            if value < -g_analogStickHTolerance then
                self:inputLeft(false)
                self.leftButtonElement:setPressed(true)
                return true
            end
            if g_analogStickHTolerance < value then
                self:inputRight(false)
                self.rightButtonElement:setPressed(true)
                return true
            end
        else
            if action == InputAction.MENU_PAGE_PREV then
                self:inputLeft(true)
                self.leftButtonElement:setPressed(true)
                return true
            end
            if action == InputAction.MENU_PAGE_NEXT then
                eventUsed = true
                self:inputRight(true)
                self.rightButtonElement:setPressed(true)
            end
        end
    end
    return eventUsed
end
function MultiTextOptionElement:update(dt)
    MultiTextOptionElement:superClass().update(self, dt)
    if self.registerContinuousInput and (self.isLeftButtonPressed or self.isRightButtonPressed) and self.delayTime <= g_time then
        if self.isLeftButtonPressed then
            self:inputLeft(false)
            self.leftButtonElement:setPressed(true)
        else
            self.leftButtonElement:setPressed(false)
        end
        if self.isRightButtonPressed then
            self:inputRight(false)
            self.rightButtonElement:setPressed(true)
        else
            self.rightButtonElement:setPressed(false)
        end
        self.wasContinuousTrigger = true
        self.delayTime = g_time + self.scrollDelayDuration
    end
    if self.registerContinuousInput and self.wasContinuousTrigger then
        self.continuousTriggerTime = self.continuousTriggerTime + dt
    end
    if self.registeredInputEventThisFrame then
        self.registeredInputEventLastFrame = true
        self.registeredInputEventThisFrame = false
    elseif self.registeredInputEventLastFrame then
        self.registeredInputEventLastFrame = false
        self.leftButtonElement:setPressed(false)
        self.rightButtonElement:setPressed(false)
        self:releaseInput()
    end
end
function MultiTextOptionElement:releaseInput(_)
    self.leftDelayTime = 0
    self.rightDelayTime = 0
    self.hasWrapped = false
    self.wasContinuousTrigger = false
    self.continuousTriggerTime = 0
    self.scrollDelayDuration = MultiTextOptionElement.FIRST_INPUT_DELAY
end
function MultiTextOptionElement:inputLeft(isShoulderButton, forceEvent, blockContinuousInput)
    local usedShoulderButton = isShoulderButton and self:getIsVisible()
    if usedShoulderButton then
        usedShoulderButton = self.buttonLRChange
    end
    local isFocusedWithoutButtons = self.hideLeftRightButtons
    if isFocusedWithoutButtons then
        isFocusedWithoutButtons = self:getIsFocused()
    end
    local isLeftButtonFocusedOrPressed = false
    if self.leftButtonElement ~= nil then
        isLeftButtonFocusedOrPressed = self.leftButtonElement:getIsFocused() or self.leftButtonElement:getIsPressed()
    end
    if not (self.leftDelayTime <= g_time and (not self.hasWrapped and (forceEvent or (usedShoulderButton or (isFocusedWithoutButtons or isLeftButtonFocusedOrPressed))))) then
        return false
    end
    if self.leftDelayTime > 0 and not blockContinuousInput then
        self.wasContinuousTrigger = true
    end
    self:onLeftButtonClicked()
    self.leftDelayTime = g_time + self.scrollDelayDuration
    self.scrollDelayDuration = self.baseScrollDelayDuration
    self.rightDelayTime = 0
    return true
end
function MultiTextOptionElement:inputRight(isShoulderButton, forceEvent, blockContinuousInput)
    local usedShoulderButton = isShoulderButton and self:getIsVisible()
    if usedShoulderButton then
        usedShoulderButton = self.buttonLRChange
    end
    local isFocusedWithoutButtons = self.hideLeftRightButtons
    if isFocusedWithoutButtons then
        isFocusedWithoutButtons = self:getIsFocused()
    end
    local isRightButtonFocusedOrPressed = false
    if self.rightButtonElement ~= nil then
        isRightButtonFocusedOrPressed = self.rightButtonElement:getIsFocused() or self.rightButtonElement:getIsPressed()
    end
    if not (self.rightDelayTime <= g_time and (not self.hasWrapped and (forceEvent or (usedShoulderButton or (isFocusedWithoutButtons or isRightButtonFocusedOrPressed))))) then
        return false
    end
    if self.rightDelayTime > 0 and not blockContinuousInput then
        self.wasContinuousTrigger = true
    end
    self:onRightButtonClicked()
    self.rightDelayTime = g_time + self.scrollDelayDuration
    self.scrollDelayDuration = self.baseScrollDelayDuration
    self.leftDelayTime = 0
    return true
end
function MultiTextOptionElement:raiseClickCallback(isLeftButtonEvent)
    self:raiseCallback("onClickCallback", self.state, self, isLeftButtonEvent)
end
function MultiTextOptionElement:onRightButtonClicked(steps, noFocus)
    if self:getCanChangeState() then
        local defaultSteps = 1
        if self.continuousTriggerTime >= MultiTextOptionElement.FAST_SCROLL_DELAY then
        end
        steps = steps or defaultSteps
        steps = steps ~= nil and type(steps) ~= "number" and 1 or steps
        for _ = 1, steps do
            if self.wrap then
                self.state = self.state + 1
                if self.state > #self.texts then
                    if self.wasContinuousTrigger then
                        self.hasWrapped = true
                        self.state = self.state - 1
                    else
                        self.state = 1
                    end
                end
            else
                self.state = math.min(self.state + 1, #self.texts)
            end
        end
        if not self.hasWrapped and self.state ~= self.state then
            self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
        end
        if noFocus == nil or not noFocus then
            self:setSoundSuppressed(true)
            FocusManager:setFocus(self)
            self:setSoundSuppressed(false)
            if self.leftButtonElement ~= nil then
                self.leftButtonElement:onFocusEnter()
            end
            if self.rightButtonElement ~= nil then
                self.rightButtonElement:onFocusEnter()
            end
        end
        self:updateContentElement()
        self:raiseClickCallback(false)
        self:notifyIndexChange(self.state, #self.texts)
    end
end
function MultiTextOptionElement:onLeftButtonClicked(steps, noFocus)
    if self:getCanChangeState() then
        local defaultSteps = 1
        if self.continuousTriggerTime >= MultiTextOptionElement.FAST_SCROLL_DELAY then
        end
        steps = steps or defaultSteps
        steps = steps ~= nil and type(steps) ~= "number" and 1 or steps
        for _ = 1, steps do
            if self.wrap then
                self.state = self.state - 1
                if self.state < 1 then
                    if self.wasContinuousTrigger then
                        self.hasWrapped = true
                        self.state = self.state + 1
                    else
                        self.state = #self.texts
                    end
                end
            else
                self.state = math.max(self.state - 1, 1)
            end
        end
        if not self.hasWrapped and self.state ~= self.state then
            self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
        end
        if noFocus == nil or not noFocus then
            self:setSoundSuppressed(true)
            FocusManager:setFocus(self)
            self:setSoundSuppressed(false)
            if self.leftButtonElement ~= nil then
                self.leftButtonElement:onFocusEnter()
            end
            if self.rightButtonElement ~= nil then
                self.rightButtonElement:onFocusEnter()
            end
        end
        self:updateContentElement()
        self:raiseClickCallback(true)
        self:notifyIndexChange(self.state, #self.texts)
    end
end
function MultiTextOptionElement:getCanChangeState()
    return self.canChangeState
end
function MultiTextOptionElement:setCanChangeState(canChangeState)
    self.canChangeState = canChangeState
end
function MultiTextOptionElement:canReceiveFocus(_, _)
    return (self.disabled or not self:getIsVisible() or not (self.handleFocus and self.disableButtonsOnSingleText)) and true or false or #self.texts > 1
end
function MultiTextOptionElement:onFocusLeave()
    MultiTextOptionElement:superClass().onFocusLeave(self)
    self:raiseCallback("onLeaveCallback", self)
end
function MultiTextOptionElement:onFocusEnter()
    MultiTextOptionElement:superClass().onFocusEnter(self)
    self:raiseCallback("onFocusCallback", self)
end
function MultiTextOptionElement:updateContentElement()
    local value = self.texts[self.state]
    local isFilename = false
    if self.isImageMode and (value ~= nil and string.find(value, ".", nil, true) ~= nil) then
        isFilename = textureFileExists(value)
    end
    local useIcon = false
    if self.iconElement ~= nil then
        if value ~= nil and isFilename then
            self.iconElement:setImageFilename(value)
            self.iconElement:setVisible(true)
            local i = 1
            for i = i, #self.gradientElements do
                self.gradientElements[i]:setVisible(false)
            end
            useIcon = true
        end
        if not useIcon then
            self.iconElement:setVisible(false)
            local i = 1
            for i = i, #self.gradientElements do
                self.gradientElements[i]:setVisible(true)
            end
        end
    end
    if self.textElement ~= nil then
        if useIcon or (value == nil or isFilename) then
            self.textElement:setText("")
        else
            self.textElement:setText(value)
        end
    end
    if self.disableButtonsOnSingleText then
        self:setDisabled(#self.texts <= 1)
    end
    if self.hideButtonOnLimitReached and not self.wrap then
        if self.leftButtonElement ~= nil then
            self.leftButtonElement:setVisible(self.state ~= 1)
        end
        if self.rightButtonElement ~= nil then
            self.rightButtonElement:setVisible(self.state ~= #self.texts)
        end
    end
end