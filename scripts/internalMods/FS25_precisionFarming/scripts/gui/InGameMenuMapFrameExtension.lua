InGameMenuMapFrameExtension = {}
InGameMenuMapFrameExtension.MOD_NAME = g_currentModName
InGameMenuMapFrameExtension.MOD_DIR = g_currentModDirectory
local InGameMenuMapFrameExtension_mt = Class(InGameMenuMapFrameExtension)
function InGameMenuMapFrameExtension.new(precisionFarming, customMt)
    -- upvalues: (copy) InGameMenuMapFrameExtension_mt
    local self = setmetatable({}, customMt or InGameMenuMapFrameExtension_mt)
    self.precisionFarming = precisionFarming
    self.valueMapToSelectorIndex = {}
    self.selectorIndexToValueMap = {}
    self.displayPrecisionFarmingData = {}
    self.activeValueMapIndex = 1
    self.overlayUpdateTimer = 0
    self.overlayUpdateInterval = 1000
    return self
end
function InGameMenuMapFrameExtension:initialize(_)
    self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
end
function InGameMenuMapFrameExtension:unloadMapData()
    g_messageCenter:unsubscribeAll(self)
end
function InGameMenuMapFrameExtension:delete()
    if self.soilStateOverlay ~= nil then
        delete(self.soilStateOverlay)
    end
    if self.coverStateOverlays ~= nil then
        local i = 1
        for i = i, #self.coverStateOverlays do
            delete(self.coverStateOverlays[i].overlay)
        end
    end
end
function InGameMenuMapFrameExtension:update(dt) end
function InGameMenuMapFrameExtension:onPrecisionFarmingSelectorChanged(state)
    self.activeValueMapIndex = state
    local valueMap = self.precisionFarming:getValueMaps()[state]
    local displayValues = valueMap:getDisplayValues()
    local valueFilter, valueFilterEnabled = valueMap:getValueFilter()
    self.inGameMenuMapFrame.dataTables[self.inGameMenuMapFrame.precisionFarmingPageIndex] = displayValues
    self.inGameMenuMapFrame.filterStates[self.inGameMenuMapFrame.precisionFarmingPageIndex] = valueFilter
    self.valueFilterEnabled = valueFilterEnabled
    local numSelectedFilters = 0
    local i = 1
    for i = i, #valueFilter do
        if valueFilter[i] then
        end
    end
    self.inGameMenuMapFrame.numSelectedFilters[self.inGameMenuMapFrame.precisionFarmingPageIndex] = numSelectedFilters
    if numSelectedFilters == 0 then
        self.inGameMenuMapFrame.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
    else
        self.inGameMenuMapFrame.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
    end
    self.inGameMenuMapFrame.filterList:reloadData()
    self:updateSoilStateMapOverlay()
end
function InGameMenuMapFrameExtension:updatePrecisionFarmingOverlays()
    self:updateSoilStateMapOverlay()
end
function InGameMenuMapFrameExtension:updateSoilStateMapOverlay()
    if self.soilStateOverlay ~= nil then
        local valueMap = self.precisionFarming:getValueMaps()[self.activeValueMapIndex]
        if valueMap ~= nil then
            local valueFilter, _ = valueMap:getValueFilter()
            valueMap:buildOverlay(self.soilStateOverlay, valueFilter, self.isColorBlindMode)
            generateDensityMapVisualizationOverlay(self.soilStateOverlay)
            self.soilStateOverlayReady = false
        end
        local valueFilter = self.precisionFarming.coverMap
        if valueFilter ~= nil then
            local i = 1
            for i = i, #self.coverStateOverlays do
                local coverStateOverlay = self.coverStateOverlays[i]
                valueFilter:buildCoverStateOverlay(coverStateOverlay.overlay, i)
                generateDensityMapVisualizationOverlay(coverStateOverlay.overlay)
                coverStateOverlay.overlayReady = false
            end
        end
    end
end
function InGameMenuMapFrameExtension:onLoadMapFinished()
    self.soilStateOverlay = createDensityMapVisualizationOverlay("soilState", 1024, 1024)
    self.soilStateOverlayReady = false
    local coverMap = self.precisionFarming.coverMap
    if coverMap ~= nil then
        self.coverStateOverlays = {}
        local i = 1
        local coverStateOverlay = coverMap:getNumCoverOverlays()
        for i = i, coverStateOverlay do
            local coverStateOverlay = {
                ["overlay"] = createDensityMapVisualizationOverlay("coverState" .. i, 1024, 1024),
                ["overlayReady"] = false
            }
            table.insert(self.coverStateOverlays, coverStateOverlay)
        end
    end
    self.precisionFarming:registerVisualizationOverlay(self.soilStateOverlay)
    local i = 1
    for i = i, #self.coverStateOverlays do
        self.precisionFarming:registerVisualizationOverlay(self.coverStateOverlays[i].overlay)
    end
end
function InGameMenuMapFrameExtension:onDrawStateOverlays(x, y, width, height)
    if not self.soilStateOverlayReady and getIsDensityMapVisualizationOverlayReady(self.soilStateOverlay) then
        self.soilStateOverlayReady = true
    end
    if self.soilStateOverlay ~= 0 and self.soilStateOverlayReady then
        setOverlayUVs(self.soilStateOverlay, 0, 0, 0, 1, 1, 0, 1, 1)
        renderOverlay(self.soilStateOverlay, x, y, width, height)
    end
    local allowCoverage = false
    local valueMap = self.precisionFarming:getValueMaps()[self.activeValueMapIndex]
    if valueMap ~= nil then
        allowCoverage = valueMap:getAllowCoverage()
    end
    if allowCoverage and self.precisionFarming.coverMap ~= nil then
        local i = 1
        for i = i, #self.coverStateOverlays do
            local coverStateOverlay = self.coverStateOverlays[i]
            if not coverStateOverlay.overlayReady and getIsDensityMapVisualizationOverlayReady(coverStateOverlay.overlay) then
                coverStateOverlay.overlayReady = true
            end
            if coverStateOverlay.overlay ~= 0 then
                setOverlayUVs(coverStateOverlay.overlay, 0, 0, 0, 1, 1, 0, 1, 1)
                renderOverlay(coverStateOverlay.overlay, x, y, width, height)
            end
        end
    end
end
function InGameMenuMapFrameExtension:setColorBlindMode()
    self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE)
end
function InGameMenuMapFrameExtension:overwriteGameFunctions(pfModule)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "onLoadMapFinished", function(superFunc, _self)
        -- upvalues: (copy) pfModule, (copy) self
        superFunc(_self)
        pfModule.inGameMenuMapFrameExtension.inGameMenuMapFrame = _self
        function _self.mapOverviewSelector.onClickCallback(_, state)
            -- upvalues: (copy) _self
            _self:onClickMapOverviewSelector(state)
        end
        function _self.onClickButtonResetStats()
            -- upvalues: (ref) self
            if self.precisionFarming.farmlandStatistics ~= nil then
                self.precisionFarming.farmlandStatistics:onClickButtonResetStats()
            end
        end
        function _self.onClickButtonSwitchValues()
            -- upvalues: (ref) self
            if self.precisionFarming.farmlandStatistics ~= nil then
                self.precisionFarming.farmlandStatistics:onClickButtonSwitchValues()
            end
        end
        local farmlandHotspotActions = {}
        self.precisionFarming:collectFarmlandHotspotActions(farmlandHotspotActions)
        self.precisionFarmingHotspotActionIndices = {}
        for _, action in ipairs(farmlandHotspotActions) do
            local action
            table.insert(_self.contextActions, {
                ["title"] = action.title,
                ["callback"] = function()
                    -- upvalues: (copy) _self, (copy) action
                    if _self.selectedFarmland ~= nil then
                        action.callback(action.callbackTarget, _self.selectedFarmland.id)
                    end
                    return true
                end,
                ["isActive"] = false
            })
            table.insert(self.precisionFarmingHotspotActionIndices, #_self.contextActions)
        end
        self:onLoadMapFinished()
        self.precisionFarmingEnvScoreContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/MapFrameExtensionEnvironmentalScore.xml", _self, _self.elements[1])
        self.precisionFarmingFieldBuyContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/MapFrameExtensionFieldBuyInfo.xml", _self, _self.contextBoxFarmland)
        self.precisionFarmingLaboratoryContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/MapFrameExtensionLaboratory.xml", _self, _self.elements[1])
        _self.deadzoneElements = {}
        table.insert(_self.deadzoneElements, _self.fieldBuyInfoWindow)
        table.insert(_self.deadzoneElements, _self.laboratoryWindow)
        table.insert(_self.deadzoneElements, _self.envScoreWindow)
        _self.precisionFarmingOnlyElements = {}
        table.insert(_self.precisionFarmingOnlyElements, _self.laboratoryWindow)
        table.insert(_self.precisionFarmingOnlyElements, _self.envScoreWindow)
        pfModule:setMapFrame(_self)
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "setupMapOverview", function(superFunc, _self)
        -- upvalues: (copy) self
        superFunc(_self)
        local yOffset = g_i18n
        table.insert(_, yOffset:getText("ui_header"))
        _self.precisionFarmingPageIndex = #_self.mapSelectorTexts
        _self.mapOverviewSelector:setTexts(_self.mapSelectorTexts)
        _self.dataTables[_self.precisionFarmingPageIndex] = {}
        _self.filterStates[_self.precisionFarmingPageIndex] = {}
        _self.numSelectedFilters[_self.precisionFarmingPageIndex] = 0
        _self.subCategoryDotBox:addElement(_self.subCategoryDotBox.elements[1]:clone(_self.subCategoryDotBox))
        _self.subCategoryDotBox:invalidateLayout()
        for index, dot in pairs(_self.subCategoryDotBox.elements) do
            local index
            function dot.getIsSelected()
                -- upvalues: (copy) _self, (copy) index
                return _self.mapOverviewSelector:getState() == index
            end
        end
        self.precisionFarmingSelector = _self.mapOverviewSelector:clone(_self.filterBox)
        self.precisionFarmingSelectorTexts = {}
        local valueMaps = self.precisionFarming:getValueMaps()
        local index = 1
        local yOffset = 1
        for index = index, _self.mapSelectorTexts, yOffset do
            local dot = valueMaps[index]
            if dot:getShowInMenu() then
                table.insert(self.precisionFarmingSelectorTexts, dot:getOverviewLabel())
            end
        end
        self.precisionFarmingSelector:setTexts(self.precisionFarmingSelectorTexts)
        local _, yOffset = getNormalizedScreenValues(0, 80)
        self.precisionFarmingSelector:setPosition(nil, self.precisionFarmingSelector.position[2] - yOffset)
        function self.precisionFarmingSelector.onClickCallback(_, state)
            -- upvalues: (ref) self
            self:onPrecisionFarmingSelectorChanged(state)
        end
        self.precisionFarmingSelector.defaultProfileText = "pf_subCategorySelectorTextSmall"
        self.precisionFarmingSelector:addDefaultElements()
        self.precisionFarmingSelector.textElement:applyProfile("pf_subCategorySelectorTextSmall")
        self.precisionFarmingDotBox = _self.subCategoryDotBox:clone(_self.filterBox)
        local index, dot = getNormalizedScreenValues(0, 75)
        self.precisionFarmingDotBox:setPosition(nil, self.precisionFarmingDotBox.position[2] - dot)
        local numShownValueMaps = #self.precisionFarmingSelectorTexts
        local numDots = #self.precisionFarmingDotBox.elements
        if numDots < numShownValueMaps then
            for i = 1, numShownValueMaps - numDots do
                self.precisionFarmingDotBox:addElement(self.precisionFarmingDotBox.elements[1]:clone(self.precisionFarmingDotBox))
            end
        elseif numShownValueMaps < numDots then
            for i = 1, numDots - numShownValueMaps do
                self.precisionFarmingDotBox.elements[#self.precisionFarmingDotBox.elements]:delete()
            end
        end
        for index, dot in pairs(self.precisionFarmingDotBox.elements) do
            local index
            function dot.getIsSelected()
                -- upvalues: (ref) self, (copy) index
                return self.precisionFarmingSelector:getState() == index
            end
        end
        self.precisionFarmingDotBox:invalidateLayout()
        self.helpButtonContainer = _self.buttonDeselectAllContainer:clone(_self.filterListContainer)
        _self.filterListContainer:addElement(self.helpButtonContainer)
        local _, yOffset = getNormalizedScreenValues(0, 16)
        self.buttonPositionDeselectAllDefault = _self.buttonDeselectAllContainer.position[2]
        self.buttonPositionDeselectAll = _self.buttonDeselectAllContainer.position[2] + yOffset
        self.helpButtonContainer:setPosition(nil, _self.buttonDeselectAllContainer.position[2] - yOffset)
        self.helpButtonContainer.elements[2]:setText(g_i18n:getText("ui_help"))
        self.helpButtonContainer.elements[3]:setInputAction("MENU_EXTRA_1")
        self.helpButtonContainer.elements[3].onClickCallback = function()
            -- upvalues: (ref) self
            local valueMap = self.precisionFarming:getValueMaps()[self.activeValueMapIndex]
            if valueMap == nil then
                self.precisionFarming.helplineExtension:openHelpMenu(0)
            else
                self.precisionFarming.helplineExtension:openHelpMenu(valueMap:getHelpLinePage())
            end
        end
        self.filterListContainerPositionY = _self.filterListContainer.position[2]
        self.filterListContainerSizeY = _self.filterListContainer.size[2]
        self.filterListSizeY = _self.filterList.size[2]
        self.filterListSliderSizeY = _self.filterListSlider.size[2]
        self.filterListSliderElementSizeY = _self.filterListSlider.elements[1].size[2]
        _self.ingameMap.onDrawPostIngameMapCallback = InGameMenuMapFrame.onDrawPostIngameMap
        _self.ingameMap.onDrawPostIngameMapHotspotsCallback = InGameMenuMapFrame.onDrawPostIngameMapHotspots
        _self.ingameMap.onClickMapCallback = InGameMenuMapFrame.onClickMap
        _self.filterList:reloadData()
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "onClickMapOverviewSelector", function(superFunc, _self, state)
        -- upvalues: (copy) self, (copy) pfModule
        superFunc(_self, state)
        if state == _self.precisionFarmingPageIndex then
            self.precisionFarmingSelector:setVisible(true)
            self.precisionFarmingDotBox:setVisible(true)
            self.helpButtonContainer:setVisible(true)
            _self.filterListContainer:setVisible(true)
            _self.buttonDeselectAllContainer:setVisible(true)
            local _, yOffset = getNormalizedScreenValues(0, 60)
            _self.filterListContainer:setPosition(nil, self.filterListContainerPositionY - yOffset)
            _self.filterListContainer:setSize(nil, self.filterListContainerSizeY - yOffset, true)
            _self.filterList:setSize(nil, self.filterListSizeY - yOffset, true)
            _self.filterListSlider:setSize(nil, self.filterListSliderSizeY - yOffset, true)
            _self.filterListSlider.elements[1]:setSize(nil, self.filterListSliderElementSizeY - yOffset, true)
            _self.buttonDeselectAllContainer:setPosition(nil, self.buttonPositionDeselectAll)
            self:onPrecisionFarmingSelectorChanged(self.precisionFarmingSelector:getState())
            pfModule:onMapFrameOpen(_self)
        else
            self.precisionFarmingSelector:setVisible(false)
            self.precisionFarmingDotBox:setVisible(false)
            self.helpButtonContainer:setVisible(false)
            _self.filterListContainer:setPosition(nil, self.filterListContainerPositionY)
            _self.filterListContainer:setSize(nil, self.filterListContainerSizeY, true)
            _self.filterList:setSize(nil, self.filterListSizeY, true)
            _self.filterListSlider:setSize(nil, self.filterListSliderSizeY, true)
            _self.filterListSlider.elements[1]:setSize(nil, self.filterListSliderElementSizeY, true)
            _self.buttonDeselectAllContainer:setPosition(nil, self.buttonPositionDeselectAllDefault)
        end
        if _self.precisionFarmingOnlyElements ~= nil then
            for _, element in ipairs(_self.precisionFarmingOnlyElements) do
                element:setVisible(state == _self.precisionFarmingPageIndex)
            end
        end
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "populateCellForItemInSection", function(superFunc, _self, list, section, index, cell)
        -- upvalues: (copy) self
        superFunc(_self, list, section, index, cell)
        if list == _self.contextButtonList or list ~= _self.contextButtonListFarmland then
            return
        elseif _self.mapOverviewSelector:getState() == _self.precisionFarmingPageIndex then
            if self.valueFilterEnabled == nil then
                cell.allowSelected = true
            else
                cell.allowSelected = self.valueFilterEnabled[index]
            end
        else
            cell.allowSelected = true
            return
        end
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "getHasChangeableFilterList", function(superFunc, _self, ...)
        return superFunc(_self, ...) or _self.mapOverviewSelector:getState() == _self.precisionFarmingPageIndex
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "updateInputGlyphs", function(superFunc, _self, ...)
        -- upvalues: (copy) self
        superFunc(_self, ...)
        if self.precisionFarming.environmentalScore ~= nil then
            self.precisionFarming.environmentalScore:updateInputGlyphs()
        end
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "onDrawPostIngameMap", function(superFunc, _self, element, ingameMap, ...)
        -- upvalues: (copy) self
        if _self.mapOverviewSelector:getState() == _self.precisionFarmingPageIndex then
            _self.hideContentOverlay = true
            superFunc(_self, element, ingameMap, ...)
            _self.hideContentOverlay = _self.hideContentOverlay
            local width, height = _self.ingameMapBase.fullScreenLayout:getMapSize()
            local x, y = _self.ingameMapBase.fullScreenLayout:getMapPosition()
            self:onDrawStateOverlays(x + width * 0.25, y + height * 0.25, width * 0.5, height * 0.5)
            if self.activeValueMapIndex == 1 and self.precisionFarming.environmentalScore ~= nil then
                self.precisionFarming.environmentalScore:onDraw(element, ingameMap)
                return
            end
        else
            superFunc(_self, element, ingameMap, ...)
        end
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "onClickSwitchMapMode", function(superFunc, _self)
        -- upvalues: (copy) pfModule
        if pfModule.additionalFieldBuyInfo ~= nil then
            pfModule.additionalFieldBuyInfo:onFarmlandSelectionChanged()
            _self:resetUIDeadzones()
        end
        superFunc(_self)
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "onFrameClose", function(superFunc, _self)
        -- upvalues: (copy) pfModule
        superFunc(_self)
        if pfModule.additionalFieldBuyInfo ~= nil then
            pfModule.additionalFieldBuyInfo:onFarmlandSelectionChanged()
            _self:resetUIDeadzones()
        end
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "update", function(superFunc, _self, dt)
        -- upvalues: (copy) self
        superFunc(_self, dt)
        if _self.mapOverviewSelector:getState() == _self.precisionFarmingPageIndex then
            self.overlayUpdateTimer = self.overlayUpdateTimer + dt
            if self.overlayUpdateTimer > self.overlayUpdateInterval then
                self:updateSoilStateMapOverlay()
                self.overlayUpdateTimer = 0
            end
        end
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "generateOverviewOverlay", function(superFunc, _self, ...)
        -- upvalues: (copy) self
        superFunc(_self, ...)
        self:updateSoilStateMapOverlay()
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "setMapSelectionItem", function(superFunc, _self, hotspot, ...)
        -- upvalues: (copy) self, (copy) pfModule
        superFunc(_self, hotspot, ...)
        function _self.updatePrecisionFarmingContextActions(reloadList)
            -- upvalues: (ref) self, (copy) _self, (copy) hotspot
            local isActive = false
            if self.precisionFarmingHotspotActionIndices ~= nil and (_self.mapOverviewSelector:getState() == _self.precisionFarmingPageIndex and (hotspot ~= nil and hotspot:isa(FarmlandHotspot))) then
                local farmland = hotspot:getFarmland()
                isActive = g_farmlandManager:getFarmlandOwner(farmland.id) == g_currentMission:getFarmId() and farmland.totalFieldArea ~= nil and true or isActive
            end
            if isActive then
                for _, contextAction in pairs(_self.contextActions) do
                    contextAction.isActive = false
                end
            end
            if self.precisionFarmingHotspotActionIndices ~= nil then
                for _, contextAction in ipairs(self.precisionFarmingHotspotActionIndices) do
                    _self.contextActions[contextAction].isActive = isActive
                end
            end
            if reloadList then
                _self.contextButtonList:reloadData()
            end
        end
        _self.updatePrecisionFarmingContextActions()
        if _self.selectedFarmland ~= _self.selectedFarmland and pfModule.additionalFieldBuyInfo ~= nil then
            pfModule.additionalFieldBuyInfo:onFarmlandSelectionChanged(_self.selectedFarmland)
            _self:resetUIDeadzones()
        end
    end)
    pfModule:overwriteGameFunction(InGameMenuMapUtil, "showContextBox", function(superFunc, contextBox, hotspot, description, imageFilename, uvs, farmId, playerName, isPlaceable, isVehicle, isFarmland, ...)
        -- upvalues: (copy) pfModule
        superFunc(contextBox, hotspot, description, imageFilename, uvs, farmId, playerName, isPlaceable, isVehicle, isFarmland, ...)
        local farmland = nil
        if contextBox ~= nil and isFarmland then
            farmland = hotspot:getFarmland()
        end
        if farmland == nil then
            if pfModule.additionalFieldBuyInfo ~= nil then
                pfModule.additionalFieldBuyInfo:onShowContextBox(nil, nil)
            end
        elseif pfModule.additionalFieldBuyInfo ~= nil then
            pfModule.additionalFieldBuyInfo:onShowContextBox(farmland, contextBox)
            return
        end
    end)
    pfModule:overwriteGameFunction(InGameMenuMapFrame, "resetUIDeadzones", function(superFunc, _self)
        superFunc(_self)
        if _self.deadzoneElements ~= nil then
            for _, element in ipairs(_self.deadzoneElements) do
                if element:getIsVisible() then
                    _self.ingameMap:addCursorDeadzone(element.absPosition[1], element.absPosition[2], element.size[1], element.size[2])
                end
            end
        end
    end)
    pfModule:overwriteGameFunction(MapOverlayGenerator, "getDisplaySoilStates", function(superFunc, _self)
        local displayValues = superFunc(_self)
        displayValues[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED] = nil
        displayValues[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME] = nil
        return displayValues
    end)
end