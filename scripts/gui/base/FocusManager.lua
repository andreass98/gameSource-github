FocusManager = {
    ["TOP"] = "top",
    ["BOTTOM"] = "bottom",
    ["LEFT"] = "left",
    ["RIGHT"] = "right",
    ["EPSILON"] = 0.00001,
    ["INITIAL_DELAY_TIME"] = 350,
    ["SCROLL_DELAY_TIME"] = 70
}
FocusManager.guiFocusData = {}
FocusManager.currentFocusData = {}
FocusManager.currentFocusData.focusElement = nil
FocusManager.currentFocusData.highlightElement = nil
FocusManager.currentFocusData.initialFocusElement = nil
FocusManager.isFocusLocked = false
FocusManager.lastInput = {}
FocusManager.lockUntil = {}
FocusManager.autoIDcount = 0
FocusManager.OPPOSING_DIRECTIONS = {
    [FocusManager.TOP] = FocusManager.BOTTOM,
    [FocusManager.BOTTOM] = FocusManager.TOP,
    [FocusManager.LEFT] = FocusManager.RIGHT,
    [FocusManager.RIGHT] = FocusManager.LEFT
}
FocusManager.DIRECTION_VECTORS = {
    [FocusManager.TOP] = { 0, 1 },
    [FocusManager.BOTTOM] = { 0, -1 },
    [FocusManager.LEFT] = { -1, 0 },
    [FocusManager.RIGHT] = { 1, 0 }
}
FocusManager.DEBUG = false
FocusManager.allElements = setmetatable({}, {
    ["__mode"] = "k"
})
function FocusManager:setGui(gui)
    if self.currentFocusData then
        local focusElement = self.currentFocusData.focusElement
        if focusElement then
            self:unsetFocus(focusElement)
        end
        local highlightElement = self.currentFocusData.highlightElement
        if highlightElement then
            self:unsetHighlight(highlightElement)
        end
    end
    self.currentGui = gui
    self.currentFocusData = self.guiFocusData[gui]
    if self.currentFocusData then
        local focusElement = self.currentFocusData.initialFocusElement or self.currentFocusData.focusElement
        if focusElement ~= nil then
            focusElement.soundDisabled = true
            self:setFocus(focusElement)
            focusElement.soundDisabled = focusElement.soundDisabled
        end
    else
        self.guiFocusData[gui] = {}
        self.guiFocusData[gui].idToElementMapping = {}
        self.currentFocusData = self.guiFocusData[gui]
    end
    self:resetFocusInputLocks()
end
function FocusManager:setSoundPlayer(guiSoundPlayer)
    self.soundPlayer = guiSoundPlayer
end
function FocusManager:getElementById(id)
    return self.currentFocusData.idToElementMapping[id]
end
function FocusManager:getFocusedElement()
    return self.currentFocusData.focusElement
end
function FocusManager.serveAutoFocusId()
    local focusId = string.format("focusAuto_%d", FocusManager.autoIDcount)
    FocusManager.autoIDcount = FocusManager.autoIDcount + 1
    return focusId
end
function FocusManager:loadElementFromXML(xmlFile, xmlBaseNode, element)
    local focusId = getXMLString(xmlFile, xmlBaseNode .. "#focusId") or FocusManager.serveAutoFocusId()
    element.focusId = focusId
    element.focusChangeData = {}
    if not element.focusChangeData[FocusManager.TOP] then
        element.focusChangeData[FocusManager.TOP] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeTop")
    end
    if not element.focusChangeData[FocusManager.BOTTOM] then
        element.focusChangeData[FocusManager.BOTTOM] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeBottom")
    end
    if not element.focusChangeData[FocusManager.LEFT] then
        element.focusChangeData[FocusManager.LEFT] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeLeft")
    end
    if not element.focusChangeData[FocusManager.RIGHT] then
        element.focusChangeData[FocusManager.RIGHT] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeRight")
    end
    local isAlwaysFocusedOnOpen = getXMLString(xmlFile, xmlBaseNode .. "#focusInit") ~= nil
    element.focused = isAlwaysFocusedOnOpen
    local isAlwaysFocusedOnOpen = getXMLString(xmlFile, xmlBaseNode .. "#focusInit") == "onOpen"
    element.isAlwaysFocusedOnOpen = isAlwaysFocusedOnOpen
    local focusChangeOverride = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeOverride")
    if focusChangeOverride then
        if element.target and element.target.focusChangeOverride then
            element.focusChangeOverride = element.target[focusChangeOverride]
        else
            self.focusChangeOverride = ClassUtil.getFunction(focusChangeOverride)
        end
    end
    if FocusManager.allElements[element] == nil then
        FocusManager.allElements[element] = {}
    end
    table.insert(FocusManager.allElements[element], self.currentGui)
    self.currentFocusData.idToElementMapping[focusId] = element
    if isAlwaysFocusedOnOpen then
        self.currentFocusData.initialFocusElement = element
        element.soundDisabled = true
        self:setFocus(element)
        element.soundDisabled = element.soundDisabled
    elseif not self.currentFocusData.focusElement then
        self.currentFocusData.focusElement = element
    end
end
function FocusManager:loadElementFromCustomValues(element, focusId, focusChangeData, focusActive, isAlwaysFocusedOnOpen)
    if focusId and self.currentFocusData.idToElementMapping[focusId] then
        return false
    end
    if not element.focusId then
        element.focusId = focusId or FocusManager.serveAutoFocusId()
    end
    element.focusChangeData = element.focusChangeData or (focusChangeData or {})
    element.isAlwaysFocusedOnOpen = isAlwaysFocusedOnOpen
    if FocusManager.allElements[element] == nil then
        FocusManager.allElements[element] = {}
    end
    table.insert(FocusManager.allElements[element], self.currentGui)
    self.currentFocusData.idToElementMapping[element.focusId] = element
    if isAlwaysFocusedOnOpen then
        self.currentFocusData.initialFocusElement = element
    end
    if focusActive then
        self:setFocus(element)
    end
    local success = true
    for _, child in pairs(element.elements) do
        if success then
            success = self:loadElementFromCustomValues(child, child.focusId, child.focusChangeData, child.focusActive, child.isAlwaysFocusedOnOpen)
        end
    end
    return success
end
function FocusManager:removeElement(element)
    if element.focusId then
        for _, child in pairs(element.elements) do
            self:removeElement(child)
        end
        if element:getIsFocused() then
            element:onFocusLeave()
            FocusManager:unsetFocus(element)
        end
        if FocusManager.allElements[element] ~= nil then
            for _, child in ipairs(FocusManager.allElements[element]) do
                local data = self.guiFocusData[child]
                data.idToElementMapping[element.focusId] = nil
                if data.focusElement == element then
                    data.focusElement = nil
                end
            end
            FocusManager.allElements[element] = nil
        end
        self.currentFocusData.idToElementMapping[element.focusId] = nil
        element.focusId = nil
        element.focusChangeData = {}
        if self.currentFocusData.focusElement == element then
            self.currentFocusData.focusElement = nil
        end
    end
end
function FocusManager.linkElements(_, sourceElement, direction, targetElement)
    if targetElement == nil then
        sourceElement.focusChangeData[direction] = "nil"
    else
        sourceElement.focusChangeData[direction] = targetElement.focusId
    end
end
function FocusManager:inputEvent(action, value, eventUsed)
    local element = self.currentFocusData.focusElement
    local pressedAccept = false
    local direction = nil
    if action == InputAction.MENU_AXIS_UP_DOWN and g_analogStickVTolerance < value then
        direction = FocusManager.TOP
    elseif action == InputAction.MENU_AXIS_UP_DOWN and value < -g_analogStickVTolerance then
        direction = FocusManager.BOTTOM
    elseif action == InputAction.MENU_AXIS_LEFT_RIGHT and value < -g_analogStickHTolerance then
        direction = FocusManager.LEFT
    elseif action == InputAction.MENU_AXIS_LEFT_RIGHT and g_analogStickHTolerance < value then
        direction = FocusManager.RIGHT
    end
    if direction ~= nil then
        self:updateFocus(element, direction, eventUsed)
    end
    if not eventUsed and (element ~= nil and not element.needExternalClick) then
        if action == InputAction.MENU_ACCEPT and (not self:isFocusInputLocked(action) and (element:getIsFocused() and element:getIsVisible())) then
            self.focusSystemMadeChanges = true
            element:onFocusActivate()
            self.focusSystemMadeChanges = false
        end
    end
    if eventUsed then
        pressedAccept = eventUsed
    elseif direction ~= nil then
        pressedAccept = true
    end
    return pressedAccept
end
function FocusManager.getDirectionForAxisValue(inputAction, value)
    if value == nil then
        return nil
    end
    local direction = nil
    if inputAction == InputAction.MENU_AXIS_UP_DOWN then
        if value < 0 then
            return FocusManager.BOTTOM
        end
        if value > 0 then
            return FocusManager.TOP
        end
    elseif inputAction == InputAction.MENU_AXIS_LEFT_RIGHT then
        if value < 0 then
            return FocusManager.LEFT
        end
        if value > 0 then
            direction = FocusManager.RIGHT
        end
    end
    return direction
end
function FocusManager:isFocusInputLocked(inputAxis, value)
    local key = FocusManager.getDirectionForAxisValue(inputAxis, value)
    if key == nil and inputAxis ~= InputAction.MENU_AXIS_UP_DOWN then
        if inputAxis == InputAction.MENU_AXIS_LEFT_RIGHT then
            inputAxis = key
        end
    else
        inputAxis = key
    end
    return self.lastInput[inputAxis] and self.lockUntil[inputAxis] > g_time and true or false
end
function FocusManager:lockFocusInput(axisAction, delay, value)
    local key = FocusManager.getDirectionForAxisValue(axisAction, value)
    if key or axisAction == InputAction.MENU_AXIS_UP_DOWN then
        axisAction = key
    elseif axisAction == InputAction.MENU_AXIS_LEFT_RIGHT then
        axisAction = key
    end
    self.lastInput[axisAction] = g_time
    self.lockUntil[axisAction] = g_time + delay
end
function FocusManager:releaseMovementFocusInput(action)
    if action == InputAction.MENU_AXIS_LEFT_RIGHT then
        self.lastInput[FocusManager.LEFT] = nil
        self.lockUntil[FocusManager.LEFT] = nil
        self.lastInput[FocusManager.RIGHT] = nil
        self.lockUntil[FocusManager.RIGHT] = nil
    elseif action == InputAction.MENU_AXIS_UP_DOWN then
        self.lastInput[FocusManager.TOP] = nil
        self.lockUntil[FocusManager.TOP] = nil
        self.lastInput[FocusManager.BOTTOM] = nil
        self.lockUntil[FocusManager.BOTTOM] = nil
    end
end
function FocusManager:resetFocusInputLocks()
    for k, _ in pairs(self.lastInput) do
        self.lastInput[k] = nil
    end
    for k, _ in pairs(self.lockUntil) do
        self.lockUntil[k] = 0
    end
end
function FocusManager.getClosestPointOnBoundingBox(x, y, boxMinX, boxMinY, boxMaxX, boxMaxY)
    if x < boxMinX then
        boxMaxX = boxMinX
    elseif boxMaxX >= x then
        boxMaxX = x
    end
    if y < boxMinY then
        return boxMaxX, boxMinY
    end
    if boxMaxY >= y then
        boxMaxY = y
    end
    return boxMaxX, boxMaxY
end
function FocusManager.getShortestBoundingBoxVector(minX, minY, maxX, maxY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY, otherCenterX, otherCenterY)
    local ePointX, ePointY = FocusManager.getClosestPointOnBoundingBox(otherCenterX, otherCenterY, minX, minY, maxX, maxY)
    local oPointX, oPointY = FocusManager.getClosestPointOnBoundingBox(ePointX, ePointY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY)
    return oPointX - ePointX, oPointY - ePointY
end
function FocusManager.checkElementDistance(curElement, other, dirX, dirY, curElementOffsetY, closestOther, closestDistanceSq)
    local minX, minY, maxX, maxY = curElement:getBorders()
    local minY = minY + curElementOffsetY
    local maxY = maxY + curElementOffsetY
    local centerX, centerY = curElement:getCenter()
    local centerY = centerY + curElementOffsetY
    local boxDistanceSq
    if other == curElement or (other.disabled or (not other:getIsVisible() or (not other:canReceiveFocus() or (other:isChildOf(curElement) or curElement:isChildOf(other))))) then
        boxDistanceSq = closestDistanceSq
        other = closestOther
    else
        local otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY = other:getBorders()
        local otherCenterX, otherCenterY = other:getCenter()
        local elementDirX, elementDirY = FocusManager.getShortestBoundingBoxVector(minX, minY, maxX, maxY, otherBoxMinX, otherBoxMinY, otherBoxMaxX, otherBoxMaxY, otherCenterX, otherCenterY)
        boxDistanceSq = MathUtil.vector2LengthSq(elementDirX, elementDirY)
        local dot = MathUtil.dotProduct(elementDirX, elementDirY, 0, dirX, dirY, 0)
        if boxDistanceSq < FocusManager.EPSILON then
            dot = MathUtil.dotProduct(otherCenterX - centerX, otherCenterY - centerY, 0, dirX, dirY, 0)
        end
        if dot > 0 then
            local useOther = false
            if closestOther then
                local closestBoxMinY = closestDistanceSq - boxDistanceSq
                if math.abs(closestBoxMinY) < FocusManager.EPSILON then
                    local closestBoxMinX, closestBoxMinY, closestBoxMaxX, closestBoxMaxY = closestOther:getBorders()
                    local closestCenterX, closestCenterY = closestOther:getCenter()
                    local toClosestX, toClosestY = FocusManager.getShortestBoundingBoxVector(minX, minY, maxX, maxY, closestBoxMinX, closestBoxMinY, closestBoxMaxX, closestBoxMaxY, closestCenterX, closestCenterY)
                    local closestDot = MathUtil.dotProduct(toClosestX, toClosestY, 0, dirX, dirY, 0)
                    if math.abs(closestDot - dot) < FocusManager.EPSILON then
                        if dirY > 0 then
                            useOther = other.absPosition[1] > closestOther.absPosition[1]
                        elseif dirY < 0 then
                            useOther = other.absPosition[1] < closestOther.absPosition[1]
                        elseif dirX > 0 then
                            useOther = other.absPosition[2] > closestOther.absPosition[2]
                        elseif dirX < 0 then
                            useOther = other.absPosition[2] < closestOther.absPosition[2]
                        end
                    end
                    ::l21::
                    if not useOther then
                        boxDistanceSq = closestDistanceSq
                        other = closestOther
                    end
                    goto l2
                end
            end
            useOther = boxDistanceSq < closestDistanceSq and true or useOther
            goto l21
        end
        boxDistanceSq = closestDistanceSq
        other = closestOther
    end
    ::l2::
    return other, boxDistanceSq
end
function FocusManager:getNextFocusElement(element, direction)
    local nextFocusId = element.focusChangeData[direction]
    if nextFocusId then
        return self.currentFocusData.idToElementMapping[nextFocusId], direction
    end
    local dirY = FocusManager.DIRECTION_VECTORS[direction]
    local dirX, dirY = unpack(dirY)
    local closestOther = nil
    local closestDistance = math.huge
    for _, other in pairs(self.currentFocusData.idToElementMapping) do
        closestOther, closestDistance = FocusManager.checkElementDistance(element, other, dirX, dirY, 0, closestOther, closestDistance)
    end
    if closestOther == nil then
        if direction == FocusManager.LEFT then
            closestOther, direction = self:getNextFocusElement(element, FocusManager.TOP)
        elseif direction == FocusManager.RIGHT then
            closestOther, direction = self:getNextFocusElement(element, FocusManager.BOTTOM)
        else
            local validWrapElements = self.currentFocusData.idToElementMapping
            if element.parent and element.parent.wrapAround then
                validWrapElements = element.parent.elements
            end
            local wrapOffsetY = 0
            if direction == FocusManager.TOP then
                wrapOffsetY = -1.2 - element.size[2]
            elseif direction == FocusManager.BOTTOM then
                wrapOffsetY = 1.2 + element.size[2]
            end
            for _, other in pairs(validWrapElements) do
                closestOther, closestDistance = FocusManager.checkElementDistance(element, other, dirX, dirY, wrapOffsetY, closestOther, closestDistance)
            end
        end
    end
    return closestOther, direction
end
function FocusManager.getNestedFocusTarget(element, direction)
    local prevTarget = nil
    while element and prevTarget ~= element do
        local target = element:getFocusTarget(FocusManager.OPPOSING_DIRECTIONS[direction], direction)
        prevTarget = element
        element = target
    end
    return element
end
function FocusManager:updateFocus(element, direction, updateOnly)
    if element == nil then
        return
    end
    if self.lastInput[direction] then
        if self.lockUntil[direction] > g_time then
            return
        end
        self.lockUntil[direction] = g_time + self.SCROLL_DELAY_TIME
    else
        self.lockUntil[direction] = g_time + self.INITIAL_DELAY_TIME
    end
    if updateOnly then
        return
    end
    self.lastInput[direction] = g_time
    if self.currentFocusData.focusElement ~= element then
        return
    end
    if element:shouldFocusChange(direction) then
        local nextElement = nil
        local nextElementIsSet = nil
        if element.focusChangeOverride then
            if element.target then
                nextElementIsSet, nextElement = element.focusChangeOverride(element.target, direction)
            else
                nextElementIsSet, nextElement = element:focusChangeOverride(direction)
            end
        end
        local maxSteps
        if nextElementIsSet then
            maxSteps = direction
        else
            nextElement, maxSteps = self:getNextFocusElement(element, direction)
        end
        if nextElement and nextElement:canReceiveFocus() then
            self:setFocus(nextElement, maxSteps)
            return
        end
        if not (element.focusChangeOverride and element:focusChangeOverride(direction)) then
            local maxSteps = 30
            while true do
                if maxSteps <= 0 or element == nil then
                    break
                end
                element, maxSteps = self:getNextFocusElement(element, direction)
                if element ~= nil and element:canReceiveFocus() then
                    break
                end
                maxSteps = maxSteps - 1
            end
        end
        self:setFocus(element, maxSteps)
    end
end
function FocusManager:setHighlight(element)
    if (not self.currentFocusData.highlightElement or self.currentFocusData.highlightElement ~= element) and element.handleFocus then
        self:unsetHighlight(self.currentFocusData.highlightElement)
        if not element.disallowFocusedHighlight or (not self.currentFocusData.focusElement or self.currentFocusData.focusElement ~= element) then
            self.currentFocusData.highlightElement = element
            element:onHighlight()
            if not element:getSoundSuppressed() and (element:getIsVisible() and (element.playHoverSoundOnFocus ~= false and not element.soundDisabled)) then
                self.soundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
            end
        end
    end
end
function FocusManager:unsetHighlight(element)
    if self.currentFocusData.highlightElement and self.currentFocusData.highlightElement == element then
        self.currentFocusData.highlightElement = nil
        element:onHighlightRemove()
    end
end
function FocusManager:setFocus(element, direction, ...)
    if FocusManager.isFocusLocked or (element == nil or not element:canReceiveFocus()) then
        return false
    end
    local targetElement = FocusManager.getNestedFocusTarget(element, direction)
    if targetElement.target == nil or targetElement.target.name ~= self.currentGui then
        return false
    end
    if self.currentFocusData.focusElement and (self.currentFocusData.focusElement == targetElement and self.currentFocusData.focusElement:getIsFocused()) then
        return false
    end
    if self.currentFocusData.focusElement ~= nil then
        self:unsetFocus(self.currentFocusData.focusElement)
        self:unsetHighlight(self.currentFocusData.highlightElement)
    end
    targetElement:setFocused(true)
    self.currentFocusData.focusElement = targetElement
    targetElement:onFocusEnter(...)
    if FocusManager.DEBUG then
        log("focus changed to element", targetElement, "; ID:", targetElement.id, "; profile:", targetElement.profile, "; type:", targetElement.typeName)
    end
    if not element:getSoundSuppressed() and (element:getIsVisible() and (element.playHoverSoundOnFocus ~= false or targetElement.customFocusSample ~= nil)) and not element.soundDisabled then
        self.soundPlayer:playSample(targetElement.customFocusSample or GuiSoundPlayer.SOUND_SAMPLES.HOVER)
    end
    return true
end
function FocusManager:unsetFocus(element, ...)
    local prevFocusElement = self.currentFocusData.focusElement
    if prevFocusElement == element and prevFocusElement ~= nil then
        if element:getIsFocused() then
            prevFocusElement:onFocusLeave(...)
        end
    else
        return
    end
end
function FocusManager:requireLock()
    FocusManager.isFocusLocked = true
end
function FocusManager:releaseLock()
    FocusManager.isFocusLocked = false
end
function FocusManager:isLocked()
    return FocusManager.isFocusLocked
end
function FocusManager:isDirectionLocked(direction)
    return self.lastInput[direction] ~= nil
end
function FocusManager:hasFocus(element)
    return self.currentFocusData.focusElement == element and element:getIsFocused()
end
function FocusManager:getFocusOverrideFunction(forDirections, substitute, useSubstituteForFocus)
    return (forDirections == nil or #forDirections < 1) and function(elementSelf, dir)
        return false, nil
    end or function(_, dir)
        -- upvalues: (copy) forDirections, (copy) useSubstituteForFocus, (copy) self, (copy) substitute
        for _, overrideDirection in pairs(forDirections) do
            if dir == overrideDirection then
                if not useSubstituteForFocus then
                    return true, substitute
                end
                local next = self:getNextFocusElement(substitute, dir)
                if next then
                    return true, next
                end
            end
        end
        return false, nil
    end
end
function FocusManager:deleteGuiFocusData(guiName)
    self.guiFocusData[guiName] = nil
end
function FocusManager:drawDebug()
    if self.currentFocusData.focusElement ~= nil then
        local element = self.currentFocusData.focusElement
        if element:getIsFocused() then
            drawFilledRect(element.absPosition[1], element.absPosition[2], element.size[1], element.size[2], 1, 0, 0, 0.5, nil, nil, nil, nil)
        end
    end
end