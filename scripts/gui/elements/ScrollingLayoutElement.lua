ScrollingLayoutElement = {}
local ScrollingLayoutElement_mt = Class(ScrollingLayoutElement, BoxLayoutElement)
Gui.registerGuiElement("ScrollingLayout", ScrollingLayoutElement)
function ScrollingLayoutElement.new(target, custom_mt)
    -- upvalues: (copy) ScrollingLayoutElement_mt
    local self = BoxLayoutElement.new(target, custom_mt or ScrollingLayoutElement_mt)
    self.clipping = true
    self.wrapAround = true
    self.scrollDirection = self.flowDirection
    self.sliderElement = nil
    self.contentOffsetX = 0
    self.contentOffsetY = 0
    self.targetContentOffsetX = 0
    self.targetContentOffsetY = 0
    self.contentSize = 1
    self.lastTouchPos = nil
    self.usedTouchId = nil
    self.currentTouchDelta = 0
    self.scrollSpeed = 0
    self.initialScrollSpeed = 0
    self.supportsTouchScrolling = Platform.hasTouchInput
    self.totalTouchMoveDistance = 0
    self.touchMoveDistanceThreshold = 30
    return self
end
function ScrollingLayoutElement:loadFromXML(xmlFile, key)
    ScrollingLayoutElement:superClass().loadFromXML(self, xmlFile, key)
    self.topClipperElementName = getXMLString(xmlFile, key .. "#topClipperElementName")
    self.bottomClipperElementName = getXMLString(xmlFile, key .. "#bottomClipperElementName")
    self.supportsTouchScrolling = Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsTouchScrolling"), self.supportsTouchScrolling)
end
function ScrollingLayoutElement:loadProfile(profile, applyProfile)
    ScrollingLayoutElement:superClass().loadProfile(self, profile, applyProfile)
    self.supportsTouchScrolling = profile:getBool("supportsTouchScrolling", self.supportsTouchScrolling)
end
function ScrollingLayoutElement:copyAttributes(src)
    ScrollingLayoutElement:superClass().copyAttributes(self, src)
    self.topClipperElementName = src.topClipperElementName
    self.bottomClipperElementName = src.bottomClipperElementName
    self.supportsTouchScrolling = src.supportsTouchScrolling
end
function ScrollingLayoutElement:onGuiSetupFinished()
    ScrollingLayoutElement:superClass().onGuiSetupFinished(self)
    if self.topClipperElementName ~= nil then
        self.topClipperElement = self.parent:getDescendantByName(self.topClipperElementName)
    end
    if self.bottomClipperElementName ~= nil then
        self.bottomClipperElement = self.parent:getDescendantByName(self.bottomClipperElementName)
    end
    for _, e in pairs(self.elements) do
        self:addFocusListener(e)
    end
    if self.flowDirection == "vertical" and self.numFlows == 1 or self.flowDirection == "horizontal" and self.numFlows ~= 1 then
        self.scrollDirection = "vertical"
    else
        self.scrollDirection = "horizontal"
    end
    if self.scrollDirection == "horizontal" then
        self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeX
    else
        self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeY
    end
end
function ScrollingLayoutElement:updateLayoutCells(ignoreVisibility)
    ScrollingLayoutElement:superClass().updateLayoutCells(self, ignoreVisibility, true)
    for _, e in pairs(self.elements) do
        self:addFocusListener(e)
    end
end
function ScrollingLayoutElement:invalidateLayout(ignoreVisibility, blockLayoutUpdate)
    local needsUpdate = not blockLayoutUpdate
    if needsUpdate then
        self:updateLayoutCells(ignoreVisibility)
    end
    self:applyCellPositions(self.contentOffsetX, self.contentOffsetY)
    if self.handleFocus and (self.focusDirection ~= BoxLayoutElement.FLOW_NONE and needsUpdate) then
        self:focusLinkCells(self.cells)
    end
    if needsUpdate then
        self:updateContentSize()
    end
    self:updateScrollClippers()
    return self.maxFlowSize
end
function ScrollingLayoutElement:updateScrollClippers(_)
    if self.scrollDirection == "vertical" then
        if self.topClipperElement ~= nil then
            self.topClipperElement:setVisible(self.contentOffsetY > 0.01)
        end
        if self.bottomClipperElement ~= nil then
            self.bottomClipperElement:setVisible(self.contentOffsetY - (self.contentSize - self.absSize[2]) < -0.01)
            return
        end
    else
        if self.topClipperElement ~= nil then
            self.topClipperElement:setVisible(self.contentOffsetX > 0.01)
        end
        if self.bottomClipperElement ~= nil then
            self.bottomClipperElement:setVisible(self.contentOffsetX - (self.contentSize - self.absSize[1]) < -0.01)
        end
    end
end
function ScrollingLayoutElement:onSliderValueChanged(slider, newValue)
    if self.scrollDirection == "vertical" then
        local newStartY = 0
        if slider.minValue ~= slider.maxValue then
            newStartY = (self.contentSize - self.absSize[2]) / (slider.maxValue - slider.minValue) * (newValue - slider.minValue)
        end
        self:scrollTo(newStartY, false)
    else
        local newStartY = 0
        if slider.minValue ~= slider.maxValue then
            newStartY = (self.contentSize - self.absSize[1]) / (slider.maxValue - slider.minValue) * (-newValue + slider.minValue)
        end
        self:scrollTo(newStartY, false)
    end
end
function ScrollingLayoutElement:scrollTo(startPos, updateSlider, noUpdateTarget)
    if self.scrollDirection == "vertical" then
        self.contentOffsetY = startPos
        if not noUpdateTarget then
            self.targetContentOffsetY = startPos
            self.isMovingToTarget = false
        end
        self:invalidateLayout(false, true)
        if (updateSlider == nil or updateSlider) and self.sliderElement ~= nil then
            self.sliderElement:setValue(startPos / ((self.contentSize - self.absSize[2]) / self.sliderElement.maxValue), true)
        end
    else
        self.contentOffsetX = startPos
        if not noUpdateTarget then
            self.targetContentOffsetX = startPos
            self.isMovingToTarget = false
        end
        self:invalidateLayout(false, true)
        if (updateSlider == nil or updateSlider) and self.sliderElement ~= nil then
            self.sliderElement:setValue(startPos / (((-self.contentSize + self.absSize[1]) / self.sliderElement.maxValue == 0 or not ((-self.contentSize + self.absSize[1]) / self.sliderElement.maxValue)) and 1 or (-self.contentSize + self.absSize[1]) / self.sliderElement.maxValue), true)
        end
    end
    self:raiseCallback("onScrollCallback")
end
function ScrollingLayoutElement:scrollToEnd()
    if self.scrollDirection == "vertical" then
        self:scrollTo(math.max(self.contentSize - self.absSize[2], 0), true)
    else
        self:scrollTo(-math.max(self.contentSize - self.absSize[1], 0), true)
    end
end
function ScrollingLayoutElement:smoothScrollTo(offset)
    if self.scrollDirection == "vertical" then
        self.targetContentOffsetY = math.max(math.min(offset, self.contentSize - self.absSize[2]), 0)
        self.isMovingToTarget = true
    else
        self.targetContentOffsetX = math.min(math.min(offset, self.contentSize - self.absSize[1]), 0)
        self.isMovingToTarget = true
    end
end
function ScrollingLayoutElement:updateContentSize()
    if self.numFlows == 1 then
        self.contentSize = self.maxFlowSize
    elseif self.numFlows == 0 then
        self.contentSize = self.totalLateralSize
    else
        self.contentSize = self.numFlows * self.lateralFlowSize
    end
    if self.scrollDirection == "vertical" then
        self.contentOffsetY = math.max(math.min(self.contentOffsetY, self.contentSize), 0)
        self.targetContentOffsetY = math.max(math.min(self.targetContentOffsetY, self.contentSize), 0)
    else
        self.contentOffsetX = math.min(math.min(self.contentOffsetX, self.contentSize), 0)
        self.targetContentOffsetX = math.min(math.min(self.targetContentOffsetX, self.contentSize), 0)
    end
    self:raiseSliderUpdateEvent()
end
function ScrollingLayoutElement:getNeedsScrolling()
    if self.scrollDirection == "vertical" then
        return self.contentSize > self.absSize[2]
    else
        return self.contentSize > self.absSize[1]
    end
end
function ScrollingLayoutElement:raiseSliderUpdateEvent()
    if self.sliderElement ~= nil then
        self.sliderElement:onBindUpdate(self)
    end
end
function ScrollingLayoutElement:getViewOffsetPercentage()
    if self.scrollDirection == "vertical" then
        local size = self.contentSize - self.absSize[2]
        if size ~= 0 then
            return self.contentOffsetY / size
        end
    else
        local size = self.contentSize - self.absSize[1]
        if size ~= 0 then
            return self.contentOffsetX / size
        end
    end
    return 1
end
function ScrollingLayoutElement:addFocusListener(element)
    element = element:findFirstFocusable(true)
    if element.scrollingFocusEnter_orig == nil then
        element.scrollingFocusEnter_orig = element.onFocusEnter
    end
    function element.onFocusEnter(e)
        -- upvalues: (copy) self
        e.scrollingFocusEnter_orig(e)
        self:scrollToMakeElementVisible(e)
    end
end
function ScrollingLayoutElement:removeElement(element)
    ScrollingLayoutElement:superClass().removeElement(self, element)
    if element.scrollingFocusEnter_orig == nil then
        element.onFocusEnter = element.scrollingFocusEnter_orig
    end
end
function ScrollingLayoutElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsActive() then
        local hasOverlap = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2])
        eventUsed = hasOverlap and ScrollingLayoutElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed
        if not GS_IS_CONSOLE_VERSION then
            self.useMouse = true
        end
        if not eventUsed and hasOverlap then
            local deltaIndex = 0
            local deltaIndex = Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) and -1 or (Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) and 1 or deltaIndex)
            if deltaIndex ~= 0 then
                self:smoothScrollTo(self.targetContentOffsetY + deltaIndex * self.contentSize * 0.05)
            end
            eventUsed = true
        end
    end
    return eventUsed
end
function ScrollingLayoutElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
    if self:getIsActive() and not self.isMovingToTarget then
        eventUsed = Platform.isMobile and (self.supportsTouchScrolling and (isUp and self.totalTouchMoveDistance >= self.touchMoveDistanceThreshold)) and true or eventUsed
        eventUsed = ScrollingLayoutElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed) and true or eventUsed
        if Platform.isMobile and (self.supportsTouchScrolling and self.totalTouchMoveDistance < self.touchMoveDistanceThreshold) then
            eventUsed = false
        end
        if self.supportsTouchScrolling then
            if eventUsed or self.usedTouchId ~= nil then
                if self.usedTouchId == touchId then
                    if isUp then
                        self.usedTouchId = nil
                        self.initialScrollSpeed = self.scrollSpeed
                        self.totalTouchMoveDistance = 0
                        return eventUsed
                    end
                    local delta, distancePixels
                    if self.scrollDirection == "horizontal" then
                        delta = posX - (self.lastTouchPos or posX)
                        distancePixels = (self.lastTouchPos - posX) * g_screenWidth
                        self.lastTouchPos = posX
                    else
                        delta = posY - (self.lastTouchPos or posY)
                        distancePixels = (self.lastTouchPos - posY) * g_screenHeight
                        self.lastTouchPos = posY
                    end
                    self.currentTouchDelta = (self.currentTouchDelta or 0) + delta
                    self.totalTouchMoveDistance = self.totalTouchMoveDistance + math.abs(distancePixels)
                end
            elseif isDown and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) then
                self.currentTouchDelta = 0
                if self.scrollDirection == "horizontal" then
                    self.lastTouchPos = posX
                else
                    self.lastTouchPos = posY
                end
                self.usedTouchId = touchId
                self.totalTouchMoveDistance = 0
                return true
            end
        end
    end
    return eventUsed
end
function ScrollingLayoutElement:scrollToMakeElementVisible(element)
    if self.scrollDirection == "vertical" then
        local min = self.absPosition[2]
        if element.forceFocusScrollToTop then
            self:smoothScrollTo(0, true)
            return
        end
        local alreadyInView = false
        if min <= element.absPosition[2] then
            alreadyInView = element.absPosition[2] <= self.absPosition[2] + self.absSize[2] - element.absSize[2]
        end
        if not alreadyInView then
            local newY
            if element.absPosition[2] < self.absPosition[2] + self.absSize[2] / 2 then
                newY = self.contentOffsetY + (min - element.absPosition[2]) + 0.01
            else
                newY = self.contentOffsetY + (max - element.absPosition[2]) - 0.01
            end
            self:smoothScrollTo(math.clamp(newY, 0, self.contentSize - self.absSize[2]), true)
            return
        end
    else
        local min = self.absPosition[1]
        if element.forceFocusScrollToTop then
            self:smoothScrollTo(0, true)
            return
        end
        local alreadyInView = false
        if min <= element.absPosition[1] then
            alreadyInView = element.absPosition[1] <= self.absPosition[1] + self.absSize[1] - element.absSize[1]
        end
        if not alreadyInView then
            local newY
            if element.absPosition[1] < self.absPosition[1] + self.absSize[1] / 2 then
                newY = self.contentOffsetX + (min - element.absPosition[1]) + 0.01
            else
                newY = self.contentOffsetX + (max - element.absPosition[1]) - 0.01
            end
            self:smoothScrollTo(math.clamp(newY, 0, self.contentSize - self.absSize[1]), true)
        end
    end
end
function ScrollingLayoutElement:registerActionEvents()
    g_inputBinding:registerActionEvent(InputAction.MENU_AXIS_UP_DOWN_SECONDARY, self, self.onVerticalCursorInput, false, false, true, true)
end
function ScrollingLayoutElement:removeActionEvents()
    g_inputBinding:removeActionEventsByTarget(self)
end
function ScrollingLayoutElement:onVerticalCursorInput(_, inputValue)
    if not self.useMouse then
        self.sliderElement:setValue(self.sliderElement.currentValue + self.sliderElement.stepSize * inputValue)
    end
    self.useMouse = false
end
function ScrollingLayoutElement:update(dt)
    ScrollingLayoutElement:superClass().update(self, dt)
    if self.isMovingToTarget then
        local offset
        if self:getIsVisible() then
            if math.abs(self.targetContentOffsetY - (self.contentOffsetY + (self.targetContentOffsetY - self.contentOffsetY) * 0.01 * dt)) < 0.0005 then
                self.isMovingToTarget = false
            end
        else
            offset = self.targetContentOffsetY
            self.isMovingToTarget = false
        end
        self:scrollTo(offset, nil, true)
    end
    if self.supportsTouchScrolling then
        local offset = self.usedTouchId ~= nil
        local delta = self.scrollSpeed
        local scrollSpeedAbs = math.abs(delta)
        if offset or scrollSpeedAbs > 0.0001 then
            local offset
            if self.scrollDirection == "vertical" then
                offset = self.contentOffsetY + (self.targetContentOffsetY - self.contentOffsetY) * 0.01 * dt
            else
                offset = self.contentOffsetX + (self.targetContentOffsetX - self.contentOffsetX) * 0.01 * dt
            end
            local delta
            if offset then
                self.scrollSpeed = self.currentTouchDelta / dt
                delta = self.currentTouchDelta
            else
                local dir = math.sign(self.scrollSpeed)
                self.scrollSpeed = math.max(scrollSpeedAbs - dt * self.scrollSpeedInterval, 0) * dir
                delta = self.scrollSpeed * (self.scrollSpeed / self.initialScrollSpeed) ^ 3 * dt
            end
            if delta == 0 or self.scrollDirection ~= "vertical" then
                if delta ~= 0 then
                    self:scrollTo((math.min(math.max(-self.contentSize + self.absSize[1], offset + delta), 0)))
                end
            else
                self:scrollTo((math.max(math.min(self.contentSize - self.absSize[2], offset + delta), 0)))
            end
            self.currentTouchDelta = 0
        end
    end
end