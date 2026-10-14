BinaryOptionElement = {}
BinaryOptionElement.STATE_LEFT = 1
BinaryOptionElement.STATE_RIGHT = 2
BinaryOptionElement.STRING_ON = "ui_on"
BinaryOptionElement.STRING_OFF = "ui_off"
BinaryOptionElement.STRING_YES = "ui_yes"
BinaryOptionElement.STRING_NO = "ui_no"
BinaryOptionElement.NUM_SLIDER_STATES = 6
local BinaryOptionElement_mt = Class(BinaryOptionElement, MultiTextOptionElement)
Gui.registerGuiElement("BinaryOption", BinaryOptionElement)
Gui.registerGuiElementProcFunction("BinaryOption", Gui.assignPlaySampleCallback)
function BinaryOptionElement.new(target, custom_mt)
    -- upvalues: (copy) BinaryOptionElement_mt
    local self = MultiTextOptionElement.new(target, custom_mt or BinaryOptionElement_mt)
    self.sliderElement = nil
    self.isSliderMoving = false
    self.sliderState = 0
    self.sliderMovingDirection = 0
    self.useYesNoTexts = false
    return self
end
function BinaryOptionElement:loadFromXML(xmlFile, key)
    BinaryOptionElement:superClass().loadFromXML(self, xmlFile, key)
    self.useYesNoTexts = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useYesNoTexts"), self.useYesNoTexts)
end
function BinaryOptionElement:loadProfile(profile, applyProfile)
    BinaryOptionElement:superClass().loadProfile(self, profile, applyProfile)
    self.useYesNoTexts = profile:getBool("useYesNoTexts", self.useYesNoTexts)
    self.sliderOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("sliderOffset"), self.sliderOffset)
    self.defaultProfileSlider = profile:getValue("defaultProfileSlider", self.defaultProfileSlider)
    self.defaultProfileSliderRound = profile:getValue("defaultProfileSliderRound", self.defaultProfileSliderRound)
    self.defaultProfileSliderThreePart = profile:getValue("defaultProfileSliderThreePart", self.defaultProfileSliderThreePart)
end
function BinaryOptionElement:copyAttributes(src)
    BinaryOptionElement:superClass().copyAttributes(self, src)
    self.useYesNoTexts = src.useYesNoTexts
    self.defaultProfileSlider = src.defaultProfileSlider
    self.defaultProfileSliderRound = src.defaultProfileSliderRound
    self.defaultProfileSliderThreePart = src.defaultProfileSliderThreePart
end
function BinaryOptionElement:setElementsByName()
    BinaryOptionElement:superClass().setElementsByName(self)
    for _, element in pairs(self.elements) do
        if element.name == "slider" then
            self.sliderElement = element
            element.target = self
            element:updateAbsolutePosition()
        end
    end
    if self.sliderElement == nil then
        Logging.warning("BinaryOptionElement: could not find a slider element for element with profile " .. self.profile)
    end
    self.leftButtonElement:setSelected(true)
    function self.leftButtonElement.getIsSelected()
        -- upvalues: (copy) self
        return self.state == BinaryOptionElement.STATE_LEFT
    end
    function self.leftButtonElement.getIsScrollingAllowed()
        -- upvalues: (copy) self
        return self:getIsFocused() or self:getIsHighlighted()
    end
    function self.rightButtonElement.getIsSelected()
        -- upvalues: (copy) self
        return self.state == BinaryOptionElement.STATE_RIGHT
    end
    function self.rightButtonElement.getIsScrollingAllowed()
        -- upvalues: (copy) self
        return self:getIsFocused() or self:getIsHighlighted()
    end
    self.sliderDelta = (self.absSize[1] - self.sliderElement.absSize[1]) / BinaryOptionElement.NUM_SLIDER_STATES
end
function BinaryOptionElement:addDefaultElements()
    BinaryOptionElement:superClass().addDefaultElements(self)
    if self.autoAddDefaultElements and self:getDescendantByName("slider") == nil then
        if self.defaultProfileSliderRound ~= nil then
            local baseElement = RoundCornerElement.new(self)
            baseElement.name = "slider"
            self:addElement(baseElement)
            baseElement:applyProfile(self.defaultProfileSliderRound)
            return
        end
        if self.defaultProfileSliderThreePart ~= nil then
            local baseElement = ThreePartBitmapElement.new(self)
            baseElement.name = "slider"
            self:addElement(baseElement)
            baseElement:applyProfile(self.defaultProfileSliderThreePart)
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
function BinaryOptionElement:onGuiSetupFinished()
    BinaryOptionElement:superClass().onGuiSetupFinished(self)
    if self.useYesNoTexts then
        self:setTexts({ g_i18n:getText(BinaryOptionElement.STRING_NO), g_i18n:getText(BinaryOptionElement.STRING_YES) })
    else
        self:setTexts({ g_i18n:getText(BinaryOptionElement.STRING_OFF), g_i18n:getText(BinaryOptionElement.STRING_ON) })
    end
    self.textElement:setVisible(false)
end
function BinaryOptionElement:getIsChecked()
    return self.state == BinaryOptionElement.STATE_RIGHT
end
function BinaryOptionElement:setIsChecked(isChecked, skipAnimation, forceEvent)
    if isChecked then
        self:setState(BinaryOptionElement.STATE_RIGHT, forceEvent)
    else
        self:setState(BinaryOptionElement.STATE_LEFT, forceEvent)
    end
    self.skipAnimation = skipAnimation
end
function BinaryOptionElement:getIsActiveNonRec()
    return self:getIsVisibleNonRec()
end
function BinaryOptionElement:setTexts(texts)
    if #texts ~= 2 then
        Logging.warning("BinaryOption: called setTexts() with invalid number of texts, binary option requires exactly 2 texts")
        printCallstack()
    end
    BinaryOptionElement:superClass().setTexts(self, texts)
    self.leftButtonElement:setText(texts[1])
    self.rightButtonElement:setText(texts[2])
end
function BinaryOptionElement:update(dt)
    BinaryOptionElement:superClass().update(self, dt)
    if self.sliderMovingDirection ~= 0 then
        if self.skipAnimation then
            self.sliderState = self.sliderMovingDirection > 0 and BinaryOptionElement.NUM_SLIDER_STATES or 0
        else
            self.sliderState = self.sliderState + self.sliderMovingDirection
        end
        if self.sliderState <= 0 or self.sliderState >= BinaryOptionElement.NUM_SLIDER_STATES then
            self.sliderMovingDirection = 0
        end
        self.sliderElement:setPosition(self.sliderDelta * self.sliderState)
    end
    self.skipAnimation = false
end
function BinaryOptionElement:inputLeft()
    if self.sliderMovingDirection ~= 0 or not (self:getIsFocused() or self.leftButtonElement:getIsPressed()) then
        return false
    end
    self:onLeftButtonClicked()
    return true
end
function BinaryOptionElement:inputRight()
    if self.sliderMovingDirection ~= 0 or not (self:getIsFocused() or self.rightButtonElement:getIsPressed()) then
        return false
    end
    self:onRightButtonClicked()
    return true
end
function BinaryOptionElement:setState(state, forceEvent, skipAnimation)
    if state == BinaryOptionElement.STATE_LEFT or state == BinaryOptionElement.STATE_RIGHT then
        if state == self.state then
            if forceEvent then
                self:raiseClickCallback(true)
            end
        else
            state = math.clamp(state, BinaryOptionElement.STATE_LEFT, BinaryOptionElement.STATE_RIGHT)
            BinaryOptionElement:superClass().setState(self, state, forceEvent)
            self:updateSelection()
            self.skipAnimation = skipAnimation
        end
    else
        Logging.warning("BinaryOption: invalid state input " .. state .. ", only 1 and 2 allowed")
        return
    end
end
function BinaryOptionElement:onRightButtonClicked()
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self)
    self:setSoundSuppressed(false)
    if self:getCanChangeState() and self.state ~= BinaryOptionElement.STATE_RIGHT then
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
        self:setState(BinaryOptionElement.STATE_RIGHT)
        self:updateContentElement()
        self:raiseClickCallback(false)
        self:notifyIndexChange(self.state, #self.texts)
    end
end
function BinaryOptionElement:onLeftButtonClicked()
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self)
    self:setSoundSuppressed(false)
    if self:getCanChangeState() and self.state ~= BinaryOptionElement.STATE_LEFT then
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
        self:setState(BinaryOptionElement.STATE_LEFT)
        self:updateContentElement()
        self:raiseClickCallback(true)
        self:notifyIndexChange(self.state, #self.texts)
    end
end
function BinaryOptionElement:updateSelection()
    self.leftButtonElement:setSelected(self.state == BinaryOptionElement.STATE_LEFT)
    self.rightButtonElement:setSelected(self.state == BinaryOptionElement.STATE_RIGHT)
    self.sliderMovingDirection = self.state == BinaryOptionElement.STATE_RIGHT and 1 or -1
end