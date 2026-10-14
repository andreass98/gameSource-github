BoxLayoutElement = {}
local BoxLayoutElement_mt = Class(BoxLayoutElement, BitmapElement)
Gui.registerGuiElement("BoxLayout", BoxLayoutElement)
BoxLayoutElement.ALIGN_LEFT = 0
BoxLayoutElement.ALIGN_CENTER = 0.5
BoxLayoutElement.ALIGN_RIGHT = 1
BoxLayoutElement.ALIGN_TOP = 1
BoxLayoutElement.ALIGN_MIDDLE = 0.5
BoxLayoutElement.ALIGN_BOTTOM = 0
BoxLayoutElement.FLOW_VERTICAL = "vertical"
BoxLayoutElement.FLOW_HORIZONTAL = "horizontal"
BoxLayoutElement.FLOW_NONE = "none"
BoxLayoutElement.FILL_DIRECTION_LEFT_TO_RIGHT = 1
BoxLayoutElement.FILL_DIRECTION_RIGHT_TO_LEFT = -1
BoxLayoutElement.FILL_DIRECTION_BOTTOM_TO_TOP = 1
BoxLayoutElement.FILL_DIRECTION_TOP_TO_BOTTOM = -1
BoxLayoutElement.LAYOUT_TOLERANCE = 0.1
BoxLayoutElement.FLOW_INDICES = {
    [BoxLayoutElement.FLOW_VERTICAL] = {
        ["FLOW_MARGIN_LOWER"] = GuiElement.MARGIN_LEFT,
        ["FLOW_MARGIN_UPPER"] = GuiElement.MARGIN_RIGHT,
        ["ELEMENT_SIZE"] = 2,
        ["ELEMENT_MARGIN_LOWER"] = GuiElement.MARGIN_TOP,
        ["ELEMENT_MARGIN_UPPER"] = GuiElement.MARGIN_BOTTOM,
        ["LAYOUT_FLOW_SIZE"] = 2
    },
    [BoxLayoutElement.FLOW_HORIZONTAL] = {
        ["FLOW_MARGIN_LOWER"] = GuiElement.MARGIN_TOP,
        ["FLOW_MARGIN_UPPER"] = GuiElement.MARGIN_BOTTOM,
        ["ELEMENT_SIZE"] = 1,
        ["ELEMENT_MARGIN_LOWER"] = GuiElement.MARGIN_LEFT,
        ["ELEMENT_MARGIN_UPPER"] = GuiElement.MARGIN_RIGHT,
        ["LAYOUT_FLOW_SIZE"] = 1
    }
}
BoxLayoutElement.FLOW_LATERAL_TABLE = {
    [BoxLayoutElement.FLOW_VERTICAL] = BoxLayoutElement.FLOW_HORIZONTAL,
    [BoxLayoutElement.FLOW_HORIZONTAL] = BoxLayoutElement.FLOW_VERTICAL
}
function BoxLayoutElement.new(target, custom_mt)
    -- upvalues: (copy) BoxLayoutElement_mt
    if custom_mt == nil then
        custom_mt = BoxLayoutElement_mt
    end
    local self = BitmapElement.new(target, custom_mt)
    self.autoValidateLayout = false
    self.useFullVisibility = true
    self.wrapAround = false
    self.alignment = { BoxLayoutElement.ALIGN_LEFT, BoxLayoutElement.ALIGN_TOP }
    self.flowDirection = BoxLayoutElement.FLOW_HORIZONTAL
    self.fillDirections = { BoxLayoutElement.FILL_DIRECTION_LEFT_TO_RIGHT, BoxLayoutElement.FILL_DIRECTION_TOP_TO_BOTTOM }
    self.numFlows = 1
    self.lateralFlowSize = 0
    self.fitFlowToElements = true
    self.layoutToleranceX = 0
    self.layoutToleranceY = 0
    self.rememberLastFocus = false
    self.lastFocusElement = nil
    self.incomingFocusTargets = {}
    self.defaultFocusTarget = nil
    self.cells = {}
    self.flowSizes = {}
    self.lateralFlowSizes = {}
    self.totalLateralSize = 0
    self.maxFlowSize = 0
    self.elementSpacing = 0
    return self
end
function BoxLayoutElement:loadFromXML(xmlFile, key)
    BoxLayoutElement:superClass().loadFromXML(self, xmlFile, key)
    local alignmentX = getXMLString(xmlFile, key .. "#alignmentX")
    if alignmentX ~= nil then
        local alignmentY = string.lower(alignmentX)
        if alignmentY == "right" then
            self.alignment[1] = BoxLayoutElement.ALIGN_RIGHT
        elseif alignmentY == "center" then
            self.alignment[1] = BoxLayoutElement.ALIGN_CENTER
        else
            self.alignment[1] = BoxLayoutElement.ALIGN_LEFT
        end
    end
    local alignmentY = getXMLString(xmlFile, key .. "#alignmentY")
    if alignmentY ~= nil then
        local fillDirectionX = string.lower(alignmentY)
        if fillDirectionX == "bottom" then
            self.alignment[2] = BoxLayoutElement.ALIGN_BOTTOM
        elseif fillDirectionX == "middle" then
            self.alignment[2] = BoxLayoutElement.ALIGN_MIDDLE
        else
            self.alignment[2] = BoxLayoutElement.ALIGN_TOP
        end
    end
    local fillDirectionX = getXMLString(xmlFile, key .. "#fillDirectionX")
    if fillDirectionX ~= nil then
        if fillDirectionX == "leftToRight" then
            self.fillDirections[1] = BoxLayoutElement.FILL_DIRECTION_LEFT_TO_RIGHT
        elseif fillDirectionX == "rightToLeft" then
            self.fillDirections[1] = BoxLayoutElement.FILL_DIRECTION_RIGHT_TO_LEFT
        end
    end
    local fillDirectionY = getXMLString(xmlFile, key .. "#fillDirectionY")
    if fillDirectionY ~= nil then
        if fillDirectionY == "topToBottom" then
            self.fillDirections[2] = BoxLayoutElement.FILL_DIRECTION_TOP_TO_BOTTOM
        elseif fillDirectionY == "bottomToTop" then
            self.fillDirections[2] = BoxLayoutElement.FILL_DIRECTION_BOTTOM_TO_TOP
        end
    end
    self.flowDirection = getXMLString(xmlFile, key .. "#flowDirection") or self.flowDirection
    self.focusDirection = getXMLString(xmlFile, key .. "#focusDirection") or self.flowDirection
    self.numFlows = getXMLInt(xmlFile, key .. "#numFlows") or self.numFlows
    local isXValue = self.flowDirection == BoxLayoutElement.FLOW_HORIZONTAL
    self.elementSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key .. "#elementSpacing"), isXValue) or self.elementSpacing
    self.lateralFlowSize = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key .. "#lateralFlowSize"), not isXValue) or self.lateralFlowSize
    self.fitFlowToElements = Utils.getNoNil(getXMLBool(xmlFile, key .. "#fitFlowToElements"), self.lateralFlowSize == 0)
    self.autoValidateLayout = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoValidateLayout"), self.autoValidateLayout)
    self.useFullVisibility = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useFullVisibility"), self.useFullVisibility)
    self.wrapAround = Utils.getNoNil(getXMLBool(xmlFile, key .. "#wrapAround"), self.wrapAround)
    self.rememberLastFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#rememberLastFocus"), self.rememberLastFocus)
end
function BoxLayoutElement:loadProfile(profile, applyProfile)
    BoxLayoutElement:superClass().loadProfile(self, profile, applyProfile)
    local alignmentX = profile:getValue("alignmentX")
    if alignmentX ~= nil then
        local alignmentY = string.lower(alignmentX)
        if alignmentY == "right" then
            self.alignment[1] = BoxLayoutElement.ALIGN_RIGHT
        elseif alignmentY == "center" then
            self.alignment[1] = BoxLayoutElement.ALIGN_CENTER
        else
            self.alignment[1] = BoxLayoutElement.ALIGN_LEFT
        end
    end
    local alignmentY = profile:getValue("alignmentY")
    if alignmentY ~= nil then
        local fillDirectionX = string.lower(alignmentY)
        if fillDirectionX == "bottom" then
            self.alignment[2] = BoxLayoutElement.ALIGN_BOTTOM
        elseif fillDirectionX == "middle" then
            self.alignment[2] = BoxLayoutElement.ALIGN_MIDDLE
        else
            self.alignment[2] = BoxLayoutElement.ALIGN_TOP
        end
    end
    local fillDirectionX = profile:getValue("fillDirectionX")
    if fillDirectionX ~= nil then
        if fillDirectionX == "leftToRight" then
            self.fillDirections[1] = BoxLayoutElement.FILL_DIRECTION_LEFT_TO_RIGHT
        elseif fillDirectionX == "rightToLeft" then
            self.fillDirections[1] = BoxLayoutElement.FILL_DIRECTION_RIGHT_TO_LEFT
        end
    end
    local fillDirectionY = profile:getValue("fillDirectionY")
    if fillDirectionY ~= nil then
        if fillDirectionY == "topToBottom" then
            self.fillDirections[2] = BoxLayoutElement.FILL_DIRECTION_TOP_TO_BOTTOM
        elseif fillDirectionY == "bottomToTop" then
            self.fillDirections[2] = BoxLayoutElement.FILL_DIRECTION_BOTTOM_TO_TOP
        end
    end
    self.autoValidateLayout = profile:getBool("autoValidateLayout", self.autoValidateLayout)
    self.useFullVisibility = profile:getBool("useFullVisibility", self.useFullVisibility)
    self.flowDirection = profile:getValue("flowDirection") or self.flowDirection
    self.focusDirection = profile:getValue("focusDirection", self.flowDirection)
    self.numFlows = profile:getNumber("numFlows", self.numFlows)
    local isXValue = self.flowDirection == BoxLayoutElement.FLOW_HORIZONTAL
    self.elementSpacing = GuiUtils.getNormalizedValue(profile:getValue("elementSpacing", self.elementSpacing), isXValue)
    self.lateralFlowSize = GuiUtils.getNormalizedValue(profile:getValue("lateralFlowSize", self.lateralFlowSize), not isXValue)
    self.fitFlowToElements = profile:getBool("fitFlowToElements", self.lateralFlowSize == 0)
    self.wrapAround = profile:getBool("wrapAround", self.wrapAround)
    self.rememberLastFocus = profile:getBool("rememberLastFocus", self.rememberLastFocus)
end
function BoxLayoutElement:copyAttributes(src)
    BoxLayoutElement:superClass().copyAttributes(self, src)
    self.alignment = table.clone(src.alignment)
    self.fillDirections = table.clone(src.fillDirections)
    self.autoValidateLayout = src.autoValidateLayout
    self.useFullVisibility = src.useFullVisibility
    self.layoutToleranceX = src.layoutToleranceX
    self.layoutToleranceY = src.layoutToleranceY
    self.flowDirection = src.flowDirection
    self.focusDirection = src.focusDirection
    self.numFlows = src.numFlows
    self.lateralFlowSize = src.lateralFlowSize
    self.fitFlowToElements = src.fitFlowToElements
    self.elementSpacing = src.elementSpacing
    self.wrapAround = src.wrapAround
    self.rememberLastFocus = src.rememberLastFocus
end
function BoxLayoutElement:onGuiSetupFinished()
    BoxLayoutElement:superClass().onGuiSetupFinished(self)
    self.layoutToleranceX = BoxLayoutElement.LAYOUT_TOLERANCE * g_pixelSizeX
    self.layoutToleranceY = BoxLayoutElement.LAYOUT_TOLERANCE * g_pixelSizeY
    self:invalidateLayout()
end
function BoxLayoutElement:addElement(element)
    BoxLayoutElement:superClass().addElement(self, element)
    element:setAnchor(0, 0)
    element:setPivot(0, 0)
    if self.autoValidateLayout then
        self:invalidateLayout()
    end
end
function BoxLayoutElement:removeElement(element)
    BoxLayoutElement:superClass().removeElement(self, element)
    if self.autoValidateLayout then
        self:invalidateLayout()
    end
end
function BoxLayoutElement:getIsElementIncluded(element, ignoreVisibility)
    return ((element.ignoreLayout or not ignoreVisibility) and not (element:getIsVisibleNonRec() and self.useFullVisibility) and true or false) and element.visible and not self.useFullVisibility
end
function BoxLayoutElement:updateLayoutCells(ignoreVisibility)
    self.cells = {
        {}
    }
    local flowTolerance = self.layoutToleranceX
    if self.flowDirection == BoxLayoutElement.FLOW_VERTICAL then
        flowTolerance = self.layoutToleranceY
    end
    local currentFlowSize = 0
    local maxLateralSize = 0
    local currentFlow = 1
    local count = 1
    self.flowSizes = {}
    self.lateralFlowSizes = {}
    self.maxFlowSize = 0
    self.totalLateralSize = 0
    for i, element in ipairs(self.elements) do
        if self:getIsElementIncluded(element, ignoreVisibility) then
            local elementFlowSize = element.absSize[BoxLayoutElement.FLOW_INDICES[self.flowDirection].ELEMENT_SIZE] + element.margin[BoxLayoutElement.FLOW_INDICES[self.flowDirection].ELEMENT_MARGIN_LOWER] + element.margin[BoxLayoutElement.FLOW_INDICES[self.flowDirection].ELEMENT_MARGIN_UPPER]
            local elementLateralSize = element.absSize[BoxLayoutElement.FLOW_INDICES[BoxLayoutElement.FLOW_LATERAL_TABLE[self.flowDirection]].ELEMENT_SIZE] + element.margin[BoxLayoutElement.FLOW_INDICES[BoxLayoutElement.FLOW_LATERAL_TABLE[self.flowDirection]].ELEMENT_MARGIN_LOWER] + element.margin[BoxLayoutElement.FLOW_INDICES[BoxLayoutElement.FLOW_LATERAL_TABLE[self.flowDirection]].ELEMENT_MARGIN_UPPER]
            if currentFlowSize + elementFlowSize + self.elementSpacing - flowTolerance > self.absSize[indices.LAYOUT_FLOW_SIZE] and (self.numFlows == 0 or currentFlow < self.numFlows) then
                currentFlowSize = 0
                maxLateralSize = 0
                count = 1
                table.insert(self.cells, {})
            end
            self.cells[currentFlow][count] = element
            local currentFlowSize = currentFlowSize + elementFlowSize
            self.flowSizes[currentFlow] = currentFlowSize
            currentFlowSize = currentFlowSize + self.elementSpacing
            self.maxFlowSize = math.max(self.maxFlowSize, currentFlowSize)
            maxLateralSize = math.max(maxLateralSize, self.fitFlowToElements and elementLateralSize and elementLateralSize or self.lateralFlowSize)
            self.lateralFlowSizes[currentFlow] = maxLateralSize
            count = count + 1
        end
    end
    for i, element in pairs(self.lateralFlowSizes) do
        self.totalLateralSize = self.totalLateralSize + element
    end
end
function BoxLayoutElement:applyCellPositions(offsetX, offsetY)
    local offsets = { offsetX or 0, offsetY or 0 }
    local lateralDirection = self.flowDirection == BoxLayoutElement.FLOW_VERTICAL and 1 or 2
    local flowOffset = self.alignment[lateralDirection] * (self.absSize[lateralDirection] - self.totalLateralSize) + offsets[lateralDirection]
    local flowIndexStart = 1
    local flowIndexEnd = #self.cells
    local flowDir = self.fillDirections[lateralDirection]
    if flowDir ~= -1 then
    end
    for flowIndexEnd = flowIndexEnd, flowIndexStart, flowDir do
        local flow = self.cells[flowIndexEnd]
        if flow == nil or #flow == 0 then
            break
        end
        local cellIndexStart = 1
        local cellIndexEnd = #flow
        local cellDir = self.fillDirections[self.flowDirection == BoxLayoutElement.FLOW_VERTICAL and 2 or 1]
        if cellDir ~= -1 then
        end
        local cellOffset = self.alignment[flowDirection] * (self.absSize[flowDirection] - self.flowSizes[flowIndexEnd]) + offsets[flowDirection]
        for cellIndexEnd = cellIndexEnd, cellIndexStart, cellDir do
            local cell = flow[cellIndexEnd]
            if cell == nil then
                break
            end
            cell:setAnchor(0, 0)
            cell:setPivot(0, 0)
            local cellLateralOffset
            if self.fitFlowToElements then
                cellLateralOffset = flowOffset + self.alignment[lateralDirection] * (self.lateralFlowSizes[flowIndexEnd] - (cell.absSize[lateralDirection] + cell.margin[lateralDirection] + cell.margin[lateralDirection + 2]))
            else
                cellLateralOffset = flowOffset
            end
            local cellLateralSize = { cellOffset, cellLateralOffset }
            cell:setPosition(cellLateralSize[flowDirection] + cell.margin[1], cellLateralSize[lateralDirection] + cell.margin[4])
            cellOffset = cellOffset + cell.absSize[flowDirection] + self.elementSpacing + cell.margin[flowDirection] + cell.margin[flowDirection + 2]
        end
        flowOffset = flowOffset + self.lateralFlowSizes[flowIndexEnd]
    end
end
function BoxLayoutElement:focusLinkCells()
    local prevElement = nil
    local firstElement = nil
    local lastElement = nil
    self.defaultFocusTarget = nil
    for _, flow in pairs(self.cells) do
        for _, cell in pairs(flow) do
            if firstElement then
                lastElement = cell:findFirstFocusable(true)
            else
                firstElement = cell:findFirstFocusable(true)
                if firstElement:canReceiveFocus() then
                    self.defaultFocusTarget = firstElement
                else
                    firstElement = nil
                end
            end
        end
    end
    self.incomingFocusTargets = {}
    for _, flow in pairs(self.cells) do
        for _, cell in pairs(flow) do
            local element = cell:findFirstFocusable(true)
            if element:canReceiveFocus() then
                self:focusLinkChildElement(element, prevElement, firstElement, lastElement)
            end
        end
    end
end
function BoxLayoutElement:focusLinkChildElement(element, previousElement, firstElement, lastElement)
    local previousDirection = FocusManager.TOP
    local nextDirection = FocusManager.BOTTOM
    if self.focusDirection == BoxLayoutElement.FLOW_HORIZONTAL then
        previousDirection = FocusManager.LEFT
        nextDirection = FocusManager.RIGHT
    end
    if previousElement then
        FocusManager:linkElements(previousElement, nextDirection, element)
        FocusManager:linkElements(element, previousDirection, previousElement)
    end
    if element == firstElement then
        self.incomingFocusTargets[previousDirection] = element
        if not self.wrapAround then
            element.focusChangeOverride = FocusManager:getFocusOverrideFunction({ previousDirection }, self, true)
        end
    end
    if element == lastElement then
        self.incomingFocusTargets[nextDirection] = element
        if self.wrapAround then
            FocusManager:linkElements(element, nextDirection, firstElement)
            FocusManager:linkElements(firstElement, previousDirection, element)
        else
            element.focusChangeOverride = FocusManager:getFocusOverrideFunction({ nextDirection }, self, true)
        end
    else
        if element ~= firstElement then
            element.focusChangeOverride = nil
        end
        return
    end
end
function BoxLayoutElement:invalidateLayout(ignoreVisibility, blockLayoutUpdate)
    local needsUpdate = not blockLayoutUpdate
    if needsUpdate then
        self:updateLayoutCells(ignoreVisibility)
    end
    self:applyCellPositions()
    if self.handleFocus and (self.focusDirection ~= BoxLayoutElement.FLOW_NONE and needsUpdate) then
        self:focusLinkCells(self.cells)
    end
    return self.maxFlowSize
end
function BoxLayoutElement:canReceiveFocus()
    if self.handleFocus then
        for _, v in ipairs(self.elements) do
            if v:canReceiveFocus() then
                return true
            end
        end
    end
    return false
end
function BoxLayoutElement:getFocusTarget(incomingDirection, moveDirection)
    local focus = self.firstDefaultFocusTarget
    if not (focus and focus:canReceiveFocus()) then
        for _, element in ipairs(self.elements) do
            if element:canReceiveFocus() then
                focus = element
                break
            end
        end
    end
    if focus then
        if not focus:canReceiveFocus() then
            focus = self
        end
    else
        focus = self
    end
    if self.rememberLastFocus and (self.lastFocusElement ~= nil and self.lastFocusElement:canReceiveFocus()) then
        return self.lastFocusElement
    end
    local focusTarget = self.incomingFocusTargets[incomingDirection]
    local checkCount = 0
    while focusTarget ~= nil and (not focusTarget:canReceiveFocus() and checkCount < #self.elements) do
        focusTarget = FocusManager:getElementById(focusTarget.focusChangeData[moveDirection])
        checkCount = checkCount + 1
    end
    return focusTarget or focus
end
function BoxLayoutElement:onFocusLeave()
    BoxLayoutElement:superClass().onFocusLeave(self)
    if self.rememberLastFocus then
        local lastFocus = FocusManager:getFocusedElement()
        if lastFocus:isChildOf(self) then
            self.lastFocusElement = lastFocus
        end
    end
end
function BoxLayoutElement:updateAbsolutePosition()
    BoxLayoutElement:superClass().updateAbsolutePosition(self)
    self:applyCellPositions()
end