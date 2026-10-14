SmoothListElement = {}
local SmoothListElement_mt = Class(SmoothListElement, GuiElement)
Gui.registerGuiElement("SmoothList", SmoothListElement)
Gui.registerGuiElementProcFunction("SmoothList", Gui.assignPlaySampleCallback)
SmoothListElement.CHECK_OFFSET_EPSILON = 0.0002
SmoothListElement.GAMEPAD_PAGE_START_END_TIME = 1000
SmoothListElement.ALIGN_START = 0
SmoothListElement.ALIGN_MIDDLE = 0.5
SmoothListElement.ALIGN_END = 1
function SmoothListElement.new(target, custom_mt)
    -- upvalues: (copy) SmoothListElement_mt
    local self = SmoothListElement:superClass().new(target, custom_mt or SmoothListElement_mt)
    self:include(IndexChangeSubjectMixin)
    self:include(PlaySampleMixin)
    self.dataSource = nil
    self.delegate = nil
    self.cellCache = {}
    self.sections = {}
    self.clipping = true
    self.isLoaded = false
    self.updateChildrenState = false
    self.sectionHeaderCellName = nil
    self.isHorizontalList = false
    self.useLateralFilling = false
    self.numLateralItems = 1
    self.listSectionSpacing = 0
    self.listItemSpacing = 0
    self.listItemLateralSpacing = 0
    self.listItemAlignment = SmoothListElement.ALIGN_START
    self.listItemAlignmentOffset = 0
    self.lengthAxis = 2
    self.widthAxis = 1
    self.viewOffset = 0
    self.targetViewOffset = 0
    self.contentSize = 0
    self.totalItemCount = 0
    self.scrollViewOffsetDelta = 0
    self.selectedIndex = 1
    self.selectedSectionIndex = 1
    self.supportsMouseScrolling = true
    self.doubleClickInterval = 400
    self.selectOnClick = false
    self.ignoreMouse = false
    self.showHighlights = false
    self.selectOnScroll = false
    self.itemizedScrollDelta = 0
    self.listSmoothingDisabled = false
    self.listSnappingEnabled = false
    self.selectedWithoutFocus = true
    self.selectionMarginItems = 0
    self.ignoreFocusActivate = false
    self.fillRowsWithEmptyItems = true
    self.canReceiveFocusWhileEmpty = false
    self.wrapAround = false
    self.lastTouchPosX = nil
    self.lastTouchPosY = nil
    self.usedTouchId = nil
    self.currentTouchDelta = 0
    self.scrollSpeed = 0
    self.initialScrollSpeed = 0
    if self.isHorizontalList then
        self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeX
    else
        self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeY
    end
    self.supportsTouchScrolling = Platform.hasTouchInput
    self.lastScrollDirection = 0
    self.emptyIndicatorElement = nil
    self.emptyIndicatorElementId = nil
    self.totalTouchMoveDistance = 0
    self.touchMoveDistanceThreshold = 30
    self.gamepadPageStartTime = nil
    self.gamepadPageStartTriggered = false
    self.gamepadPageEndTime = nil
    self.gamepadPageEndTriggered = false
    return self
end
function SmoothListElement:loadFromXML(xmlFile, key)
    SmoothListElement:superClass().loadFromXML(self, xmlFile, key)
    self:addCallback(xmlFile, key .. "#onScroll", "onScrollCallback")
    self:addCallback(xmlFile, key .. "#onDoubleClick", "onDoubleClickCallback")
    self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
    self:addCallback(xmlFile, key .. "#onPressed", "onPressedCallback")
    self.isHorizontalList = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isHorizontalList"), self.isHorizontalList)
    local alignment = self.isHorizontalList and 1 or 2
    self.lengthAxis = alignment
    local alignment = self.isHorizontalList and 2 or 1
    self.widthAxis = alignment
    self.numLateralItems = getXMLInt(xmlFile, key .. "#numLateralItems") or self.numLateralItems
    self.listSectionSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key .. "#listSectionSpacing"), self.isHorizontalList, self.listSectionSpacing)
    self.listItemSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key .. "#listItemSpacing"), self.isHorizontalList, self.listItemSpacing)
    self.listItemLateralSpacing = GuiUtils.getNormalizedValue(getXMLString(xmlFile, key .. "#listItemLateralSpacing"), not self.isHorizontalList, self.listItemLateralSpacing)
    self.useLateralFilling = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useLateralFilling"), self.useLateralFilling)
    local alignment = getXMLString(xmlFile, key .. "#listItemAlignment")
    if alignment ~= nil then
        local delegateName = string.lower(alignment)
        if delegateName == "end" then
            self.listItemAlignment = SmoothListElement.ALIGN_END
        elseif delegateName == "middle" then
            self.listItemAlignment = SmoothListElement.ALIGN_MIDDLE
        else
            self.listItemAlignment = SmoothListElement.ALIGN_START
        end
    end
    self.supportsMouseScrolling = Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsMouseScrolling"), self.supportsMouseScrolling)
    self.supportsTouchScrolling = Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsTouchScrolling"), self.supportsTouchScrolling)
    self.doubleClickInterval = getXMLInt(xmlFile, key .. "#doubleClickInterval") or self.doubleClickInterval
    self.selectOnClick = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectOnClick"), self.selectOnClick)
    self.ignoreMouse = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignoreMouse"), self.ignoreMouse)
    self.showHighlights = Utils.getNoNil(getXMLBool(xmlFile, key .. "#showHighlights"), self.showHighlights)
    self.selectOnScroll = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectOnScroll"), self.selectOnScroll)
    self.itemizedScrollDelta = getXMLInt(xmlFile, key .. "#itemizedScrollDelta") or self.itemizedScrollDelta
    self.listSmoothingDisabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#listSmoothingDisabled"), self.listSmoothingDisabled)
    self.selectedWithoutFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectedWithoutFocus"), self.selectedWithoutFocus)
    self.selectionMarginItems = getXMLInt(xmlFile, key .. "#selectionMarginItems") or self.selectionMarginItems
    self.listSnappingEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#listSnappingEnabled"), self.listSnappingEnabled)
    self.ignoreFocusActivate = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignoreFocusActivate"), self.ignoreFocusActivate)
    self.fillRowsWithEmptyItems = Utils.getNoNil(getXMLBool(xmlFile, key .. "#fillRowsWithEmptyItems"), self.fillRowsWithEmptyItems)
    self.canReceiveFocusWhileEmpty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#canReceiveFocusWhileEmpty"), self.canReceiveFocusWhileEmpty)
    self.wrapAround = Utils.getNoNil(getXMLBool(xmlFile, key .. "#wrapAround"), self.wrapAround)
    self.emptyIndicatorElementId = getXMLString(xmlFile, key .. "#emptyIndicatorId") or self.emptyIndicatorElementId
    local delegateName = getXMLString(xmlFile, key .. "#listDelegate")
    if delegateName == nil or delegateName == "self" then
        self.delegate = self.target
    elseif delegateName ~= "nil" then
        self.delegate = self.target[delegateName]
    end
    local dataSourceName = getXMLString(xmlFile, key .. "#listDataSource")
    if dataSourceName == nil or dataSourceName == "self" then
        self.dataSource = self.target
    elseif delegateName ~= "nil" then
        self.dataSource = self.target[dataSourceName]
    end
    self.sectionHeaderCellName = getXMLString(xmlFile, key .. "#listSectionHeader")
    self.startClipperElementName = getXMLString(xmlFile, key .. "#startClipperElementName")
    self.endClipperElementName = getXMLString(xmlFile, key .. "#endClipperElementName")
end
function SmoothListElement:loadProfile(profile, applyProfile)
    SmoothListElement:superClass().loadProfile(self, profile, applyProfile)
    self.isHorizontalList = profile:getBool("isHorizontalList", self.isHorizontalList)
    local alignment = self.isHorizontalList and 1 or 2
    self.lengthAxis = alignment
    local alignment = self.isHorizontalList and 2 or 1
    self.widthAxis = alignment
    self.numLateralItems = profile:getNumber("numLateralItems", self.numLateralItems)
    self.listSectionSpacing = GuiUtils.getNormalizedValue(profile:getValue("listSectionSpacing"), self.isHorizontalList, self.listSectionSpacing)
    self.listItemSpacing = GuiUtils.getNormalizedValue(profile:getValue("listItemSpacing"), self.isHorizontalList, self.listItemSpacing)
    self.listItemLateralSpacing = GuiUtils.getNormalizedValue(profile:getValue("listItemLateralSpacing"), not self.isHorizontalList, self.listItemLateralSpacing)
    self.useLateralFilling = profile:getBool("useLateralFilling", self.useLateralFilling)
    local alignment = profile:getValue("listItemAlignment")
    if alignment ~= nil then
        local alignment = string.lower(alignment)
        if alignment == "end" then
            self.listItemAlignment = SmoothListElement.ALIGN_END
        elseif alignment == "middle" then
            self.listItemAlignment = SmoothListElement.ALIGN_MIDDLE
        else
            self.listItemAlignment = SmoothListElement.ALIGN_START
        end
    end
    self.supportsMouseScrolling = profile:getBool("supportsMouseScrolling", self.supportsMouseScrolling)
    self.doubleClickInterval = profile:getNumber("doubleClickInterval", self.doubleClickInterval)
    self.selectOnClick = profile:getBool("selectOnClick", self.selectOnClick)
    self.ignoreMouse = profile:getBool("ignoreMouse", self.ignoreMouse)
    self.showHighlights = profile:getBool("showHighlights", self.showHighlights)
    self.selectOnScroll = profile:getBool("selectOnScroll", self.selectOnScroll)
    self.itemizedScrollDelta = profile:getNumber("itemizedScrollDelta", self.itemizedScrollDelta)
    self.listSmoothingDisabled = profile:getBool("listSmoothingDisabled", self.listSmoothingDisabled)
    self.selectedWithoutFocus = profile:getBool("selectedWithoutFocus", self.selectedWithoutFocus)
    self.selectionMarginItems = profile:getNumber("selectionMarginItems", self.selectionMarginItems)
    self.supportsTouchScrolling = profile:getBool("supportsTouchScrolling", self.supportsTouchScrolling)
    self.listSnappingEnabled = profile:getBool("listSnappingEnabled", self.listSnappingEnabled)
    self.emptyIndicatorElementId = profile:getValue("emptyIndicatorId", self.emptyIndicatorElementId)
    self.fillRowsWithEmptyItems = profile:getBool("fillRowsWithEmptyItems", self.fillRowsWithEmptyItems)
    self.canReceiveFocusWhileEmpty = profile:getBool("canReceiveFocusWhileEmpty", self.canReceiveFocusWhileEmpty)
    self.wrapAround = profile:getBool("wrapAround", self.wrapAround)
end
function SmoothListElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
    local cloned = SmoothListElement:superClass().clone(self, parent, includeId, suppressOnCreate, blockFocusHandlingReload)
    cloned.cellDatabase = {}
    for name, cell in pairs(self.cellDatabase) do
        cloned.cellDatabase[name] = cell:clone(nil, nil, true)
    end
    for name, cell in pairs(self.cellCache) do
        cloned.cellCache[name] = {}
    end
    return cloned
end
function SmoothListElement:copyAttributes(src)
    SmoothListElement:superClass().copyAttributes(self, src)
    self.dataSource = src.dataSource
    self.delegate = src.delegate
    self.singularCellName = src.singularCellName
    self.sectionHeaderCellName = src.sectionHeaderCellName
    self.startClipperElementName = src.startClipperElementName
    self.endClipperElementName = src.endClipperElementName
    self.emptyIndicatorElementId = src.emptyIndicatorElementId
    self.isHorizontalList = src.isHorizontalList
    self.numLateralItems = src.numLateralItems
    self.listSectionSpacing = src.listSectionSpacing
    self.listItemSpacing = src.listItemSpacing
    self.listItemLateralSpacing = src.listItemLateralSpacing
    self.listItemAlignment = src.listItemAlignment
    self.useLateralFilling = src.useLateralFilling
    self.supportsMouseScrolling = src.supportsMouseScrolling
    self.doubleClickInterval = src.doubleClickInterval
    self.selectOnClick = src.selectOnClick
    self.ignoreMouse = src.ignoreMouse
    self.showHighlights = src.showHighlights
    self.itemizedScrollDelta = src.itemizedScrollDelta
    self.selectOnScroll = src.selectOnScroll
    self.listSmoothingDisabled = src.listSmoothingDisabled
    self.selectedWithoutFocus = src.selectedWithoutFocus
    self.selectionMarginItems = src.selectionMarginItems
    self.listSnappingEnabled = src.listSnappingEnabled
    self.fillRowsWithEmptyItems = src.fillRowsWithEmptyItems
    self.canReceiveFocusWhileEmpty = src.canReceiveFocusWhileEmpty
    self.wrapAround = src.wrapAround
    self.lengthAxis = src.lengthAxis
    self.widthAxis = src.widthAxis
    self.onScrollCallback = src.onScrollCallback
    self.onDoubleClickCallback = src.onDoubleClickCallback
    self.onClickCallback = src.onClickCallback
    self.onPressedCallback = src.onPressedCallback
    self.supportsTouchScrolling = src.supportsTouchScrolling
    self.isLoaded = src.isLoaded
    GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end
function SmoothListElement:onGuiSetupFinished()
    SmoothListElement:superClass().onGuiSetupFinished(self)
    if self.startClipperElementName ~= nil then
        self.startClipperElement = self.parent:getDescendantByName(self.startClipperElementName)
    end
    if self.endClipperElementName ~= nil then
        self.endClipperElement = self.parent:getDescendantByName(self.endClipperElementName)
    end
    if self.emptyIndicatorElementId ~= nil and self.target ~= nil then
        self.emptyIndicatorElement = self.target:getDescendantById(self.emptyIndicatorElementId)
        if self.emptyIndicatorElement ~= nil then
            self.emptyIndicatorElement:setVisible(true)
        end
    end
    if not self.isLoaded then
        self:buildCellDatabase()
        self.isLoaded = true
    end
end
function SmoothListElement:buildCellDatabase()
    self.cellDatabase = {}
    local numCellsInDatabase = 0
    local i = #self.elements
    for i = i, 1, -1 do
        local element = self.elements[i]
        local name = element.name
        if element:isa(ListItemElement) then
            if name == nil then
                element.name = "autoCell" .. i
                name = element.name
            end
            self.cellDatabase[name] = element
            self.cellCache[name] = {}
        end
        element:unlinkElement()
        FocusManager:removeElement(element)
    end
    if self.sectionHeaderCellName ~= nil and self.cellDatabase[self.sectionHeaderCellName] == nil then
        Logging.warning("List section header with name \'%s\' does not exist on \'%s\'", self.sectionHeaderCellName, self.profile)
        self.sectionHeaderCellName = nil
    end
    if self.sectionHeaderCellName ~= nil then
    end
    if self.dataSource.getEmptyCellType ~= nil and self.cellDatabase[self.dataSource:getEmptyCellType(self)] ~= nil or self.cellDatabase.empty then
    end
    if numCellsInDatabase == 1 then
        for element, name in pairs(self.cellDatabase) do
            if element ~= self.sectionHeaderCellName then
                self.singularCellName = element
                return
            end
        end
    end
end
function SmoothListElement:iterateOverDatabase(lambda)
    if self.cellDatabase ~= nil then
        for _, cell in pairs(self.cellDatabase) do
            lambda(cell)
        end
    end
    if self.cellCache ~= nil then
        for _, cell in pairs(self.cellCache) do
            local i = 1
            for i = i, #cell do
                lambda(cell[i])
            end
        end
    end
end
function SmoothListElement:delete()
    for name, elements in pairs(self.cellCache) do
        for _, element in ipairs(elements) do
            element:delete()
        end
    end
    for name, elements in pairs(self.cellDatabase) do
        elements:delete()
    end
    SmoothListElement:superClass().delete(self)
end
function SmoothListElement:onOpen()
    if self.setNextOpenIndex ~= nil then
        self:setSoundSuppressed(true)
        self:setSelectedItem(self.setNextOpenSectionIndex, self.setNextOpenIndex, true, true)
        self.setNextOpenIndex = nil
        self.setNextOpenSectionIndex = nil
        self:setSoundSuppressed(false)
    end
end
function SmoothListElement:onClose()
    if self.isMovingToTarget then
        self:scrollTo(self.targetViewOffset)
    end
end
function SmoothListElement:setDataSource(dataSource)
    self.dataSource = dataSource
    if self.delegate == nil then
        self.delegate = dataSource
    end
end
function SmoothListElement:setDelegate(delegate)
    self.delegate = delegate
    if self.dataSource == nil then
        self.dataSource = delegate
    end
end
function SmoothListElement:dequeueReusableCell(name)
    if self.cellDatabase[name] == nil then
        return nil
    end
    local cache = self.cellCache[name]
    local cell
    if #cache > 0 then
        cache[#cache] = nil
        self:addElement(cache[#cache])
    else
        cell = self.cellDatabase[name]:clone(self)
        cell.reusableName = name
    end
    FocusManager:loadElementFromCustomValues(cell)
    return cell
end
function SmoothListElement:queueReusableCell(cell)
    if self.sections[cell.sectionIndex] ~= nil then
        self.sections[cell.sectionIndex].cells[cell.indexInSection] = nil
    end
    cell.sectionIndex = nil
    cell.indexInSection = nil
    local cache = self.cellCache[cell.reusableName]
    cache[#cache + 1] = cell
    cell:unlinkElement()
    FocusManager:removeElement(cell)
end
function SmoothListElement:setTarget(target, originalTarget, callOnCreate)
    SmoothListElement:superClass().setTarget(self, target, originalTarget, callOnCreate)
    if self.delegate == originalTarget then
        self.delegate = target
    end
    if self.dataSource == originalTarget then
        self.dataSource = target
    end
    self:iterateOverDatabase(function(e)
        -- upvalues: (copy) target, (copy) originalTarget, (copy) callOnCreate
        e:setTarget(target, originalTarget, callOnCreate)
    end)
end
function SmoothListElement:reloadData(forceCellTypeUpdate)
    if self.dataSource ~= nil then
        self:setSoundSuppressed(true)
        if forceCellTypeUpdate then
            for _, section in pairs(self.sections) do
                local i = #section.cells
                for i = i, 1, -1 do
                    local cell = section.cells[i]
                    if cell ~= nil then
                        self:queueReusableCell(cell)
                    end
                end
            end
        end
        self:buildSectionInfo()
        self:updateView(nil, true)
        self:setSoundSuppressed(false)
    end
end
function SmoothListElement:reloadSection(_)
    self:reloadData()
end
function SmoothListElement:buildSectionInfo()
    local total = 0
    local numberOfSections = self.dataSource.getNumberOfSections == nil and 1 or self.dataSource:getNumberOfSections(self)
    local itemWidth = self:getWidthOfItemFast(1, 1) + self.listItemLateralSpacing
    if self.useLateralFilling and itemWidth > 0 then
        local currentLengthOffset = math.floor((self.absSize[self.widthAxis] + self.listItemLateralSpacing) / itemWidth)
        self.numLateralItems = math.max(currentLengthOffset, 1)
    else
        itemWidth = (self.absSize[self.widthAxis] - (self.numLateralItems - 1) * self.listItemLateralSpacing) / self.numLateralItems + self.listItemLateralSpacing
    end
    local totalRows = 0
    local currentLengthOffset = 0
    local s = 1
    local selectedIndex = 1
    for s = s, numberOfSections, selectedIndex do
        if self.sections[s] == nil then
            self.sections[s] = {
                ["cells"] = {}
            }
        end
        local section = self.sections[s]
        section.itemOffsets = {}
        section.itemLateralOffsets = {}
        local hasHeader = self.sectionHeaderCellName ~= nil
        if self.dataSource.getTitleForSectionHeader ~= nil and self.dataSource:getTitleForSectionHeader(self, s) == nil then
            hasHeader = false
        end
        section.startOffset = currentLengthOffset
        if hasHeader then
            section.startOffset = currentLengthOffset + (s > 1 and self.listSectionSpacing or 0)
            section.itemOffsets[0] = section.startOffset
            currentLengthOffset = currentLengthOffset + self.cellDatabase[self.sectionHeaderCellName].size[self.lengthAxis] + self.listItemSpacing + sectionOffset
        end
        section.numItems = self.dataSource:getNumberOfItemsInSection(self, s)
        local lastRow = 1
        local rowMaxLength = 0
        local i = 1
        for i = i, section.numItems do
            local itemLength = self:getLengthOfItemFast(s, i)
            local row = math.floor((i - 1) / self.numLateralItems) + 1
            local column = (i - 1) % self.numLateralItems + 1
            if row < section.numItems / self.numLateralItems or s < numberOfSections then
            end
            if row == lastRow then
                rowMaxLength = math.max(rowMaxLength, itemLength)
            else
                lastRow = row
            end
            section.itemOffsets[i] = currentLengthOffset
            section.itemLateralOffsets[i] = itemWidth * (column - 1)
            local emptyCellName = self.dataSource.getEmptyCellType ~= nil and self.dataSource:getEmptyCellType(self) or "empty"
            if self.numLateralItems > 1 and (i == section.numItems and (self.fillRowsWithEmptyItems and self.cellDatabase[emptyCellName] ~= nil)) then
                local emptyIndex = i + 1
                while emptyIndex % self.numLateralItems ~= 1 do
                    section.itemOffsets[emptyIndex] = currentLengthOffset
                    section.itemLateralOffsets[emptyIndex] = itemWidth * ((emptyIndex - 1) % self.numLateralItems + 1 - 1)
                    emptyIndex = emptyIndex + 1
                end
            end
        end
        currentLengthOffset = currentLengthOffset + rowMaxLength
        totalRows = totalRows + 1
        section.endOffset = currentLengthOffset
        self.sections[s] = section
    end
    local s = #self.sections
    local selectedSection = numberOfSections + 1
    local selectedIndex = -1
    for s = s, selectedSection, selectedIndex do
        self.sections[s] = nil
    end
    local selectedSection = self.selectedSectionIndex
    local selectedIndex = self.selectedIndex
    if #self.sections > 0 then
        local sectionOffset = #self.sections
        local s = math.clamp(selectedSection, 1, sectionOffset)
        if self.sections[s].numItems == 0 then
            for sectionOffset, lastRow in ipairs(self.sections) do
                if lastRow.numItems > 0 then
                    selectedIndex = math.clamp(selectedIndex, 1, lastRow.numItems)
                    s = sectionOffset
                    break
                end
            end
        else
            selectedIndex = math.clamp(selectedIndex, 1, self.sections[s].numItems)
        end
        if selectedIndex == 0 then
            self.selectedSectionIndex = 0
            self.selectedIndex = 0
        elseif self:getIsVisible() then
            self:setSelectedItem(s, selectedIndex, true)
        else
            self.setNextOpenIndex = selectedIndex
            self.setNextOpenSectionIndex = s
        end
    end
    if totalRows > 0 then
        if self.itemizedScrollDelta == nil or (self.itemizedScrollDelta <= 0 or (#self.sections ~= 1 or self.singularCellName == nil)) then
            self.scrollViewOffsetDelta = math.max(currentLengthOffset / totalRows * 0.4, self.absSize[self.lengthAxis] / 5)
        else
            self.scrollViewOffsetDelta = (currentLengthOffset + self.listItemSpacing) / totalRows * self.itemizedScrollDelta
        end
    else
        self.scrollViewOffsetDelta = 0
    end
    self.contentSize = currentLengthOffset
    local s = self.absSize[self.lengthAxis] - currentLengthOffset
    if s > 0 then
        self.listItemAlignmentOffset = s * self.listItemAlignment
        if self.isHorizontalList then
            self.listItemAlignmentOffset = self.listItemAlignmentOffset * -1
        end
    end
    local section = self.totalItemCount
    self.totalItemCount = total
    if self.emptyIndicatorElement == nil or (section ~= 0 or self.totalItemCount <= 0) then
        if self.emptyIndicatorElement ~= nil and (self.totalItemCount == 0 and section > 0) then
            self.emptyIndicatorElement:setVisible(true)
        end
    else
        self.emptyIndicatorElement:setVisible(false)
    end
    local lastRow = self.viewOffset
    local rowMaxLength = self.contentSize - self.absSize[self.lengthAxis]
    local sectionOffset = math.min(lastRow, rowMaxLength)
    self.viewOffset = math.max(sectionOffset, 0)
    local lastRow = self.targetViewOffset
    local rowMaxLength = self.contentSize - self.absSize[self.lengthAxis]
    local sectionOffset = math.min(lastRow, rowMaxLength)
    self.targetViewOffset = math.max(sectionOffset, 0)
    self:updateScrollClippers()
end
function SmoothListElement:getLengthOfItemFast(section, index)
    local cellName = self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, section, index)
    return self.cellDatabase[cellName].size[self.lengthAxis]
end
function SmoothListElement:getWidthOfItemFast(section, index)
    local cellName = self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, section, index)
    return self.cellDatabase[cellName].size[self.widthAxis]
end
function SmoothListElement:updateView(updateSlider, repopulate)
    local firstSection = 0
    local firstIndex = 0
    local s = 1
    local lastSection = #self.sections
    local lastIndex = 1
    for s = s, lastSection, lastIndex do
        local section = self.sections[s]
        if self.viewOffset < section.endOffset then
            local i = 0
            local s = section.numItems
            local section = 1
            firstSection = s
            for i = i, s, section do
                local offset = section.itemOffsets[i]
                local itemLength = self:getLengthOfItemFast(s, i) or 0
                if offset ~= nil then
                    itemLength = offset + itemLength or itemLength
                end
                if offset ~= nil and (itemLength ~= nil and self.viewOffset + SmoothListElement.CHECK_OFFSET_EPSILON < itemLength) then
                    firstIndex = i
                    break
                end
            end
            if firstIndex == nil then
                firstIndex = section.numItems
            end
        end
    end
    local lastSection = 0
    local lastIndex = 1
    local s = #self.sections
    local section = math.max(firstSection, 1)
    local section = -1
    for s = s, section, section do
        local section = self.sections[s]
        if section.startOffset < self.viewOffset + self.absSize[self.lengthAxis] then
            local itemLength = section.numItems - 1
            for itemLength = itemLength, 0, -1 do
                local endOffset = section.itemOffsets[itemLength + 1]
                if endOffset ~= nil and endOffset < viewEndOffset then
                    lastIndex = itemLength + 1
                    break
                end
            end
            if lastIndex == nil then
                lastIndex = section.numItems
                lastSection = s
            else
                lastSection = s
            end
        end
    end
    local s = #self.elements
    local s = 1
    local section = -1
    for s = s, s, section do
        local section = self.elements[s]
        if section.sectionIndex < firstSection or (lastSection < section.sectionIndex or section.sectionIndex == firstSection and section.indexInSection < firstIndex) or (not section.isEmptyCell and (section.sectionIndex == lastSection and lastIndex < section.indexInSection) or (not section.isEmptyCell and self.sections[section.sectionIndex].numItems < section.indexInSection or section.isEmptyCell)) then
            self:queueReusableCell(section)
        end
    end
    if firstSection == 0 or lastSection == 0 then
        if updateSlider ~= false then
            self:raiseSliderUpdateEvent()
        end
        return
    end
    local s = self.sections[firstSection].itemOffsets[firstIndex]
    while s - self.viewOffset < self.absSize[self.lengthAxis] do
        local section = self.sections[firstSection]
        if firstIndex < section.numItems and (section.cells[firstIndex] ~= nil and section.cells[firstIndex].isEmptyCell) then
            self:queueReusableCell(section.cells[firstIndex])
            section.cells[firstIndex] = nil
        end
        if section.cells[firstIndex] == nil then
            local i = nil
            if firstIndex == 0 then
                if self.sectionHeaderCellName ~= nil then
                    i = self:dequeueReusableCell(self.sectionHeaderCellName)
                    i.isHeader = true
                    local offset = i:getAttribute("title")
                    if offset == nil or self.dataSource.getTitleForSectionHeader == nil then
                        if self.dataSource.populateSectionHeader ~= nil then
                            self.dataSource:populateSectionHeader(self, firstSection, i)
                        end
                    else
                        offset:setText(self.dataSource:getTitleForSectionHeader(self, firstSection))
                    end
                end
            else
                i = self:dequeueReusableCell(self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, firstSection, firstIndex))
                self.dataSource:populateCellForItemInSection(self, firstSection, firstIndex, i)
                i:setAlternating(firstIndex % 2 == 0)
            end
            i.sectionIndex = firstSection
            i.indexInSection = firstIndex
            section.cells[firstIndex] = i
            local endOffset = firstSection ~= self.selectedSectionIndex or (firstIndex ~= self.selectedIndex or self.selectedWithoutFocus)
            if not endOffset then
                endOffset = FocusManager:getFocusedElement() == self
            end
            i:setSelected(endOffset)
        elseif repopulate then
            if firstIndex == 0 then
                local offset = section.cells[firstIndex]:getAttribute("title")
                if offset == nil or self.dataSource.getTitleForSectionHeader == nil then
                    if self.dataSource.populateSectionHeader ~= nil then
                        self.dataSource:populateSectionHeader(self, firstSection, i)
                    end
                else
                    offset:setText(self.dataSource:getTitleForSectionHeader(self, firstSection))
                end
            elseif firstIndex <= section.numItems then
                self.dataSource:populateCellForItemInSection(self, firstSection, firstIndex, i)
                local endOffset = firstIndex % 2 == 0
                i:setAlternating(endOffset)
                local endOffset = firstSection ~= self.selectedSectionIndex or (firstIndex ~= self.selectedIndex or self.selectedWithoutFocus)
                if not endOffset then
                    endOffset = FocusManager:getFocusedElement() == self
                end
                i:setSelected(endOffset)
            end
        end
        firstIndex = firstIndex + 1
        local i = self.dataSource.getEmptyCellType ~= nil and self.dataSource:getEmptyCellType(self) or "empty"
        if self.fillRowsWithEmptyItems and (self.cellDatabase[i] ~= nil and (section.numItems < firstIndex and self.numLateralItems > 1)) then
            local section = firstIndex
            while firstIndex % self.numLateralItems ~= 1 do
                local itemLength = self:dequeueReusableCell(i)
                itemLength.sectionIndex = firstSection
                itemLength.indexInSection = firstIndex
                itemLength.isEmptyCell = true
                itemLength.playHoverSoundOnFocus = false
                section.cells[firstIndex] = itemLength
                firstIndex = firstIndex + 1
            end
            firstIndex = section
        end
        if firstSection == lastSection and lastIndex < firstIndex then
            break
        end
        if section.numItems < firstIndex then
            local section = 0
            firstSection = firstSection + 1
            if lastSection < firstSection then
                break
            end
            firstIndex = self.sections[firstSection].itemOffsets[section] == nil and 1 or section
            s = self.sections[firstSection].startOffset
        else
            s = section.itemOffsets[firstIndex]
        end
    end
    self.numVisibleItems = #self.elements
    for itemLength, endOffset in pairs(self.elements) do
        self:updateCellPosition(endOffset)
    end
    if updateSlider ~= false then
        self:raiseSliderUpdateEvent()
    end
    self:updateScrollClippers()
end
function SmoothListElement:updateCellPosition(element)
    local offset, lateralOffset
    if element.indexInSection == 0 then
        offset = self.sections[element.sectionIndex].startOffset
        lateralOffset = 0
    else
        offset = section.itemOffsets[element.indexInSection]
        lateralOffset = section.itemLateralOffsets[element.indexInSection]
    end
    if self.lengthAxis == 1 then
        local x, y = GuiUtils.alignToScreenPixels(offset - self.viewOffset - self.listItemAlignmentOffset, -lateralOffset)
        element:setPosition(x, y)
    else
        local x, y = GuiUtils.alignToScreenPixels(lateralOffset, self.viewOffset - offset - self.listItemAlignmentOffset)
        element:setPosition(x, y)
    end
end
function SmoothListElement:scrollTo(offset, updateSlider)
    offset = math.max(math.min(offset, self.contentSize - self.absSize[self.lengthAxis]), 0)
    if offset ~= self.viewOffset then
        self.viewOffset = offset
        self.targetViewOffset = offset
        self.isMovingToTarget = false
        self:updateView(updateSlider)
    end
end
function SmoothListElement:scrollToStartGamepad()
    if self.gamepadPageStartTime == nil then
        self.gamepadPageStartTime = g_time + SmoothListElement.GAMEPAD_PAGE_START_END_TIME
    end
    self.gamepadPageStartTriggered = true
    if g_time >= self.gamepadPageStartTime then
        self:scrollToStart()
        self.gamepadPageStartTime = math.huge
    end
end
function SmoothListElement:scrollToEndGamepad()
    if self.gamepadPageEndTime == nil then
        self.gamepadPageEndTime = g_time + SmoothListElement.GAMEPAD_PAGE_START_END_TIME
    end
    self.gamepadPageEndTriggered = true
    if g_time >= self.gamepadPageEndTime then
        self:scrollToEnd()
        self.gamepadPageEndTime = math.huge
    end
end
function SmoothListElement:scrollToStart()
    if #self.sections == 1 or (Input.isKeyPressed(Input.KEY_lctrl) or g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_KEYBOARD) then
        self:setSelectedItem(1, 1)
    else
        self:setSelectedItem(self.selectedSectionIndex, 1)
    end
end
function SmoothListElement:scrollToEnd()
    local numSections = #self.sections
    local lastCellIndex = self.sections[numSections].numItems
    if numSections == 1 or (Input.isKeyPressed(Input.KEY_lctrl) or g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_KEYBOARD) then
        self:setSelectedItem(numSections, lastCellIndex)
    else
        self:setSelectedItem(self.selectedSectionIndex, self.sections[self.selectedSectionIndex].numItems)
    end
end
function SmoothListElement:scrollToPrevPage()
    local spacing = self.isHorizontalList and self.listItemLateralSpacing or self.listItemSpacing
    if #self.sections ~= 1 and not Input.isKeyPressed(Input.KEY_lctrl) then
        self:setSelectedItem(self.selectedSectionIndex - 1, 1)
        return
    end
    local targetOffset = nil
    local foundTargetOffset = false
    for sectionIndex, section in pairs(self.sections) do
        if self.viewOffset - spacing < section.endOffset or MathUtil.equalEpsilon(section.endOffset, self.viewOffset, SmoothListElement.CHECK_OFFSET_EPSILON) then
            for cellIndex, cellOffset in pairs(section.itemOffsets) do
                targetOffset = cellOffset + self:getLengthOfItemFast(sectionIndex, cellIndex) + spacing
                if viewEndOffset + SmoothListElement.CHECK_OFFSET_EPSILON < targetOffset then
                    targetOffset = math.max(math.min(targetOffset - self.absSize[self.lengthAxis] - spacing, self.contentSize - self.absSize[self.lengthAxis]), 0)
                    foundTargetOffset = true
                    break
                end
            end
            if foundTargetOffset then
                break
            end
        end
    end
    for sectionIndex, section in pairs(self.sections) do
        if targetOffset < section.endOffset or MathUtil.equalEpsilon(section.endOffset, targetOffset, SmoothListElement.CHECK_OFFSET_EPSILON) then
            for cellIndex, cellOffset in pairs(section.itemOffsets) do
                if targetOffset < cellOffset or MathUtil.equalEpsilon(cellOffset, targetOffset, SmoothListElement.CHECK_OFFSET_EPSILON) then
                    self:setSelectedItem(sectionIndex, cellIndex)
                    return
                end
            end
        end
    end
end
function SmoothListElement:scrollToNextPage()
    if #self.sections == 1 or Input.isKeyPressed(Input.KEY_lctrl) then
        local spacing = self.isHorizontalList and self.listItemLateralSpacing or self.listItemSpacing
        for sectionIndex, section in pairs(self.sections) do
            if self.viewOffset + self.absSize[self.lengthAxis] + spacing < section.endOffset or MathUtil.equalEpsilon(section.endOffset, self.viewOffset + self.absSize[self.lengthAxis] + spacing, SmoothListElement.CHECK_OFFSET_EPSILON) then
                for cellIndex, cellOffset in pairs(section.itemOffsets) do
                    if cellOffset + self:getLengthOfItemFast(sectionIndex, cellIndex) + spacing > viewEndOffset + SmoothListElement.CHECK_OFFSET_EPSILON then
                        if cellIndex - self.numLateralItems <= 0 and section.itemOffsets[0] ~= nil then
                            local cellOffset = section.itemOffsets[0]
                        end
                        self:setSelectedItem(sectionIndex, cellIndex)
                        self:smoothScrollTo(cellOffset)
                        return
                    end
                end
            elseif sectionIndex == #self.sections then
                self:setSelectedItem(sectionIndex, self.sections[sectionIndex].numItems)
            end
        end
    else
        self:setSelectedItem(self.selectedSectionIndex + 1, 1)
        self:smoothScrollTo(self.sections[self.selectedSectionIndex].itemOffsets[self.sections[self.selectedSectionIndex].itemOffsets[0] == nil and 1 or 0])
    end
end
function SmoothListElement:smoothScrollTo(offset)
    if self.listSmoothingDisabled then
        self:scrollTo(offset)
    end
    self.targetViewOffset = math.max(math.min(offset, self.contentSize - self.absSize[self.lengthAxis]), 0)
    self.isMovingToTarget = true
end
function SmoothListElement:setSelectedIndex(index, forceChangeEvent, fast)
    self:setSelectedItem(1, index, forceChangeEvent, fast)
end
function SmoothListElement:setSelectedItem(section, index, forceChangeEvent, fast)
    if index == nil or section == nil then
        return
    elseif #self.sections < section or section < 1 then
        return
    elseif self.sections[section].numItems < index then
        return
    else
        local element = self:getElementAtSectionIndex(section, index)
        if element == nil or element.allowSelected ~= false then
            local hasChanged = true
            if self.selectedIndex == index then
                hasChanged = self.selectedSectionIndex ~= section
            end
            self.lastScrollDirection = math.sign(index - self.selectedIndex)
            self.selectedSectionIndex = section
            self.selectedIndex = index
            if hasChanged then
                self:makeCellVisible(self.selectedSectionIndex, self.selectedIndex, fast)
            end
            if not self.soundDisabled and (hasChanged and (g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_TOUCH or not (self.inputDown or self.isMovingToTarget))) then
                self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
            end
            if (hasChanged or forceChangeEvent) and self.isLoaded then
                self:notifyIndexChange(index, self.sections[1].numItems)
                if self.delegate.onListSelectionChanged ~= nil then
                    self.delegate:onListSelectionChanged(self, section, index)
                end
            end
            self:applyElementSelection()
        end
    end
end
function SmoothListElement:setHighlightedItem(element)
    if self.showHighlights then
        if self.highlightedElement ~= element then
            if self.highlightedElement ~= nil then
                FocusManager:unsetHighlight(self.highlightedElement)
            end
            self.highlightedElement = element
            if element ~= nil then
                FocusManager:setHighlight(element)
            end
            if self.delegate.onListHighlightChanged ~= nil then
                local section = nil
                local index = nil
                if element ~= nil then
                    section = element.sectionIndex
                    index = element.indexInSection
                end
                self.delegate:onListHighlightChanged(self, section, index)
            end
        end
    end
end
function SmoothListElement:applyElementSelection()
    local focusAllowed = self.selectedWithoutFocus
    if not focusAllowed then
        focusAllowed = FocusManager:getFocusedElement() == self
    end
    for _, element in pairs(self.elements) do
        element:setSelected(focusAllowed and (element.sectionIndex == self.selectedSectionIndex and element.indexInSection == self.selectedIndex))
    end
end
function SmoothListElement:clearElementSelection()
    local i = 1
    for i = i, #self.elements do
        local element = self.elements[i]
        if element.setSelected ~= nil then
            element:setSelected(false)
        end
    end
end
function SmoothListElement:makeCellVisible(section, index, fast)
    local sectionInfo = self.sections[section]
    if sectionInfo == nil then
        return
    else
        local showSectionHeader = false
        if index <= self.numLateralItems then
            showSectionHeader = sectionInfo.itemOffsets[0] ~= nil
        end
        local cellStartOffset = sectionInfo.itemOffsets[index]
        if cellStartOffset ~= nil then
            local cellEndOffset = (index - 1) / self.numLateralItems
            local firstOfNextRow = (math.floor(cellEndOffset) + 1) * self.numLateralItems + 1
            local cellEndOffset = sectionInfo.itemOffsets[firstOfNextRow]
            if cellEndOffset == nil then
                cellEndOffset = sectionInfo.endOffset
            elseif section < #self.sections or index < sectionInfo.numItems then
            end
            local newOffset = self.viewOffset
            local marginItemSize = self.selectionMarginItems * (cellEndOffset - cellStartOffset)
            local newOffset
            if cellStartOffset - marginItemSize < self.viewOffset then
                if showSectionHeader then
                    newOffset = sectionInfo.itemOffsets[0]
                else
                    newOffset = cellStartOffset - marginItemSize
                end
            else
                if cellEndOffset + marginItemSize <= self.viewOffset + self.absSize[self.lengthAxis] then
                    return
                end
                newOffset = cellEndOffset - viewSize + marginItemSize
            end
            if not self.isMovingToTarget or self.targetViewOffset ~= newOffset then
                if fast then
                    self:scrollTo(newOffset)
                    return
                end
                self:smoothScrollTo(newOffset)
            end
        end
    end
end
function SmoothListElement:makeSelectedCellVisible()
    self:makeCellVisible(self.selectedSectionIndex, self.selectedIndex)
end
function SmoothListElement:updateScrollClippers(_)
    if self.startClipperElement ~= nil then
        local visible = self.visible
        if visible then
            visible = false
            if self.contentSize > 0 then
                visible = self.viewOffset > 0.01
            end
        end
        self.startClipperElement:setVisible(visible)
    end
    if self.endClipperElement ~= nil then
        local visible = self.visible
        if visible then
            visible = false
            if self.contentSize > 0 then
                visible = self.viewOffset - (self.contentSize - self.absSize[self.lengthAxis]) < -0.01
            end
        end
        self.endClipperElement:setVisible(visible)
    end
end
function SmoothListElement:update(dt)
    SmoothListElement:superClass().update(self, dt)
    if self.isMovingToTarget then
        if self:getIsVisible() then
            self.viewOffset = self.viewOffset + (self.targetViewOffset - self.viewOffset) * 0.01 * dt
        else
            self.viewOffset = self.targetViewOffset
        end
        if math.abs(self.targetViewOffset - self.viewOffset) < 0.0005 then
            self.viewOffset = self.targetViewOffset
            self.isMovingToTarget = false
        end
        self:updateView(true)
    end
    if self.supportsTouchScrolling then
        local isTouchActionActive = self.usedTouchId ~= nil
        local delta = self.scrollSpeed
        local scrollSpeedAbs = math.abs(delta)
        if isTouchActionActive or scrollSpeedAbs > 0.0001 then
            local delta = 0
            if isTouchActionActive then
                self.scrollSpeed = self.currentTouchDelta / dt
                delta = self.currentTouchDelta
                if self.isHorizontalList then
                end
            elseif self.listSnappingEnabled then
                self.scrollSpeed = 0
            else
                local dir = math.sign(self.scrollSpeed)
                if self.isHorizontalList then
                end
                self.scrollSpeed = math.max(scrollSpeedAbs - dt * self.scrollSpeedInterval, 0) * dir
                delta = self.scrollSpeed * (self.scrollSpeed / self.initialScrollSpeed) ^ 3 * dt
            end
            if delta ~= 0 then
                self:scrollTo(self.viewOffset + delta)
            end
            self.currentTouchDelta = 0
        end
    end
    if self.inputDown then
        self.inputDownTimer = self.inputDownTimer + dt
        self:raiseCallback("onPressedCallback", self, self.inputDownTimer)
    end
    if self.gamepadPageStartTime ~= nil and not self.gamepadPageStartTriggered then
        self.gamepadPageStartTime = nil
    end
    if self.gamepadPageEndTime ~= nil and not self.gamepadPageEndTriggered then
        self.gamepadPageEndTime = nil
    end
    self.gamepadPageStartTriggered = false
    self.gamepadPageEndTriggered = false
end
function SmoothListElement:getSelectedElement()
    return self:getElementAtSectionIndex(self.selectedSectionIndex, self.selectedIndex)
end
function SmoothListElement:getItemCount()
    return self.totalItemCount
end
function SmoothListElement:getSelectedIndexInSection()
    return self.selectedIndex
end
function SmoothListElement:getSelectedSection()
    return self.selectedSectionIndex
end
function SmoothListElement:getSelectedPath()
    return self.selectedSectionIndex, self.selectedIndex
end
function SmoothListElement:getElementAtSectionIndex(section, index)
    if self.sections[section] == nil then
        return nil
    else
        return self.sections[section].cells[index]
    end
end
function SmoothListElement:raiseSliderUpdateEvent()
    if self.sliderElement ~= nil then
        self.sliderElement:onBindUpdate(self)
    end
end
function SmoothListElement:onSliderValueChanged(slider, newValue, immediateMode)
    if self.sections == nil then
        return
    else
        local newOffset = 0
        local sliderDiff = slider.maxValue - slider.minValue
        if sliderDiff ~= 0 then
            newOffset = (self.contentSize - self.absSize[self.lengthAxis]) / sliderDiff * (newValue - slider.minValue)
        end
        if immediateMode then
            self:scrollTo(newOffset, false)
        else
            self:smoothScrollTo(newOffset)
        end
    end
end
function SmoothListElement:getViewOffsetPercentage()
    local size = self.contentSize - self.absSize[self.lengthAxis]
    return size == 0 and 1 or self.viewOffset / size
end
function SmoothListElement:activateInput()
    if self.inputOverElement == nil then
        self.lastClickTime = nil
    else
        local clickedSection, notified
        if self.listSnappingEnabled then
            clickedSection = self.inputOverElement.sectionIndex
            notified = MathUtil.round(self.selectedIndex + 0.3 * self.lastScrollDirection, 0)
        else
            clickedSection = self.inputOverElement.sectionIndex
            notified = self.inputOverElement.indexInSection
        end
        local notified = false
        if self.lastClickTime == nil or self.lastClickTime <= self.target.time - self.doubleClickInterval then
            self.lastClickTime = self.target.time
        else
            if clickedSection == self.selectedSectionIndex and notified == previousIndex then
                self:notifyDoubleClick(clickedSection, notified, self.inputOverElement)
                self.usedTouchId = nil
            end
            self.lastClickTime = nil
        end
        local wasScrolling = self.totalTouchMoveDistance > self.touchMoveDistanceThreshold
        self.wasScrolling = wasScrolling
        if not wasScrolling or self.selectOnScroll then
            self:setSelectedItem(clickedSection, notified)
        end
        if not (self.selectOnClick or (notified or wasScrolling)) then
            self:notifyClick(clickedSection, notified, self.inputOverElement, self.selectedIndex == notified)
            return
        end
    end
end
function SmoothListElement:onInputDown()
    self.inputDown = true
    self.inputDownTimer = 0
    FocusManager:setFocus(self)
end
function SmoothListElement:onInputUp()
    self.inputDown = false
    self.totalTouchMoveDistance = 0
end
function SmoothListElement:resetInput()
    self.lastClickTime = nil
    self.inputDown = false
    self.lastClickTime = nil
end
function SmoothListElement:notifyDoubleClick(section, index, element)
    self:raiseCallback("onDoubleClickCallback", self, section, index, element, true)
end
function SmoothListElement:notifyClick(section, index, element, wasAlreadySelected)
    self:raiseCallback("onClickCallback", self, section, index, element, wasAlreadySelected)
end
function SmoothListElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self:getIsActive() and not self.ignoreMouse then
        eventUsed = SmoothListElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed
        if eventUsed or not GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) then
            if self.inputOverElement ~= nil then
                self.inputOverElement = nil
                self:setHighlightedItem(nil)
            end
        else
            local inputOverElement = self:getElementAtScreenPosition(posX, posY)
            if inputOverElement ~= nil and (inputOverElement.indexInSection == 0 or inputOverElement.isEmptyCell) then
                inputOverElement = nil
            end
            if self.inputOverElement ~= inputOverElement then
                self:setHighlightedItem(inputOverElement)
                self.inputOverElement = inputOverElement
            end
            if isDown then
                if button == Input.MOUSE_BUTTON_LEFT then
                    self:onInputDown()
                    self:activateInput()
                    eventUsed = self.inputOverElement ~= nil
                end
                if self.supportsMouseScrolling then
                    local deltaIndex = 0
                    local deltaIndex = Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) and -1 or (Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) and 1 or deltaIndex)
                    if deltaIndex ~= 0 then
                        if self.selectOnScroll then
                            if #self.sections == 1 then
                                self:setSelectedItem(1, (math.max(1, (math.min(self.sections[1].numItems, self.selectedIndex + deltaIndex)))))
                            end
                        else
                            self:smoothScrollTo(self.targetViewOffset + deltaIndex * self.scrollViewOffsetDelta)
                        end
                        eventUsed = true
                    end
                end
            end
            if isUp and (button == Input.MOUSE_BUTTON_LEFT and self.inputDown) then
                self:onInputUp()
                return self.inputOverElement ~= nil
            end
        end
    end
    return eventUsed
end
function SmoothListElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
    if self:getIsActive() then
        eventUsed = SmoothListElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed) and true or eventUsed
        if not eventUsed and (self.usedTouchId == touchId or GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.hotspot)) then
            local inputOverElement = self:getElementAtScreenPosition(posX, posY)
            if inputOverElement ~= nil and (inputOverElement.indexInSection == 0 or inputOverElement.isEmptyCell) then
                inputOverElement = nil
            end
            if self.inputOverElement ~= inputOverElement then
                self:setHighlightedItem(inputOverElement)
                self.inputOverElement = inputOverElement
            end
            local wasScrolling = self.totalTouchMoveDistance > self.touchMoveDistanceThreshold
            self.wasScrolling = wasScrolling
            if self.supportsTouchScrolling then
                if self.usedTouchId == nil then
                    if not eventUsed and isDown then
                        self.currentTouchDelta = 0
                        self.lastTouchPosX = posX
                        self.lastTouchPosY = posY
                        self.usedTouchId = touchId
                        eventUsed = true
                    end
                elseif self.usedTouchId == touchId then
                    if isUp then
                        self.usedTouchId = nil
                        self.initialScrollSpeed = self.scrollSpeed
                    else
                        local lastTouchPosX = self.lastTouchPosX or posX
                        local lastTouchPosY = self.lastTouchPosY or posY
                        local delta
                        if self.isHorizontalList then
                            delta = posX - lastTouchPosX
                        else
                            delta = posY - lastTouchPosY
                        end
                        self.currentTouchDelta = (self.currentTouchDelta or 0) + delta
                        local distancePixels = MathUtil.vector2Length((lastTouchPosX - posX) * g_screenWidth, (lastTouchPosY - posY) * g_screenHeight)
                        self.totalTouchMoveDistance = self.totalTouchMoveDistance + distancePixels
                        self.lastTouchPosX = posX
                        self.lastTouchPosY = posY
                    end
                end
            end
            if isDown then
                self:onInputDown()
                eventUsed = true
            end
            if isUp and self.inputDown then
                if not wasScrolling then
                    self:activateInput()
                end
                self:onInputUp()
                eventUsed = true
            end
        end
    end
    return eventUsed
end
function SmoothListElement:getElementAtScreenPosition(x, y)
    local i = #self.elements
    for i = i, 1, -1 do
        local v = self.elements[i]
        if GuiUtils.checkOverlayOverlap(x, y, v.absPosition[1], v.absPosition[2], v.absSize[1], v.absSize[2], v.hotspot) then
            return v, v.sectionIndex, v.indexInSection
        end
    end
    return nil
end
function SmoothListElement:shouldFocusChange(direction)
    if self.totalItemCount == 0 then
        return true
    end
    local sectionIndex = self.selectedSectionIndex
    local column = #self.sections
    local section = math.clamp(sectionIndex, 1, column)
    local section = self.sections[section]
    local index = self.selectedIndex
    local targetSection = (index - 1) / self.numLateralItems
    local row = math.floor(targetSection) + 1
    local column = (index - 1) % self.numLateralItems + 1
    if self.isHorizontalList then
        if direction == FocusManager.TOP then
            direction = FocusManager.LEFT
        elseif direction == FocusManager.BOTTOM then
            direction = FocusManager.RIGHT
        elseif direction == FocusManager.LEFT then
            direction = FocusManager.TOP
        elseif direction == FocusManager.RIGHT then
            direction = FocusManager.BOTTOM
        end
    end
    local targetIndex, targetSection
    if direction == FocusManager.TOP then
        targetIndex = index - self.numLateralItems
        if targetIndex < 1 then
            if section > 1 then
                while true do
                    targetSection = section - 1
                    if targetSection == 0 then
                        return true
                    end
                    local s = self.sections[targetSection]
                    local lastColumn = (s.numItems - 1) / self.numLateralItems
                    local nRows = math.floor(lastColumn)
                    local lastColumn = s.numItems % self.numLateralItems
                    if lastColumn == 0 then
                        lastColumn = math.min(s.numItems, self.numLateralItems)
                    end
                    targetIndex = nRows * self.numLateralItems + math.min(lastColumn, column)
                    if targetIndex > 0 then
                        break
                    end
                end
            elseif self.wrapAround then
                targetSection = #self.sections
                targetIndex = self.sections[targetSection] ~= nil and self.sections[targetSection].numItems or 0
            elseif index == 1 and self.sections[section].itemOffsets[1] > 0 then
                targetIndex = 0
                targetSection = section
            else
                targetIndex = index
                targetSection = section
            end
        else
            targetSection = section
        end
    elseif direction == FocusManager.BOTTOM then
        targetIndex = index + self.numLateralItems
        if section.numItems < targetIndex then
            local lastColumn = (section.numItems - 1) / self.numLateralItems
            local s = math.floor(lastColumn) + 1
            if section.numItems % self.numLateralItems == 0 or row >= s then
                if section < #self.sections then
                    while true do
                        targetSection = section + 1
                        if #self.sections < targetSection then
                            return true
                        end
                        targetIndex = math.min(self.sections[targetSection].numItems, column)
                        if targetIndex ~= 0 then
                            break
                        end
                    end
                elseif self.wrapAround then
                    targetSection = math.min(#self.sections, 1)
                    targetIndex = self.sections[targetSection] == nil and 0 or 1
                else
                    targetIndex = index
                    targetSection = section
                end
            else
                targetIndex = section.numItems
                targetSection = section
            end
        else
            targetSection = section
        end
    elseif direction == FocusManager.LEFT then
        if column > 1 then
            targetIndex = index - 1
            targetSection = section
        else
            targetIndex = index
            targetSection = section
        end
    elseif direction == FocusManager.RIGHT then
        local lastColumn = section.numItems / self.numLateralItems
        local nRows = math.floor(lastColumn)
        local lastColumn = section.numItems % self.numLateralItems
        if lastColumn > 0 then
        else
            lastColumn = self.numLateralItems
        end
        if row ~= nRows then
            lastColumn = self.numLateralItems
        end
        if column < lastColumn then
            targetIndex = index + 1
            targetSection = section
        else
            targetIndex = index
            targetSection = section
        end
    else
        targetIndex = index
        targetSection = section
    end
    if targetSection == section and targetIndex == index then
        return true
    elseif targetIndex == 0 then
        self:makeCellVisible(targetSection, 0)
        return true
    else
        self:setSelectedItem(targetSection, targetIndex)
        return false
    end
end
function SmoothListElement:canReceiveFocus()
    return not (self:getIsVisible() and self.handleFocus) or (self.disabled and true or false or self.canReceiveFocusWhileEmpty) or self.totalItemCount > 0
end
function SmoothListElement:onFocusActivate()
    if self.totalItemCount == 0 then
        return
    elseif self.ignoreFocusActivate then
        return
    elseif self.onClickCallback == nil then
        if self.onDoubleClickCallback ~= nil then
            self:notifyDoubleClick(self.selectedSectionIndex, self.selectedIndex, nil)
        end
    else
        self:notifyClick(self.selectedSectionIndex, self.selectedIndex, self:getElementAtSectionIndex(self.selectedSectionIndex, self.selectedIndex))
        return
    end
end
function SmoothListElement:onFocusEnter()
    self:applyElementSelection()
    if self.delegate.onListSelectionChanged ~= nil then
        self.delegate:onListSelectionChanged(self, self.selectedSectionIndex, self.selectedIndex)
    end
end
function SmoothListElement:onFocusLeave()
    if not self.selectedWithoutFocus then
        self:clearElementSelection()
    end
    SmoothListElement:superClass().onFocusLeave(self)
end