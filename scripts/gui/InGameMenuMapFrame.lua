InGameMenuMapFrame = {}
local InGameMenuMapFrame_mt = Class(InGameMenuMapFrame, TabbedMenuFrameElement)
InGameMenuMapFrame.MAP_FRUIT_TYPE = 1
InGameMenuMapFrame.MAP_GROWTH = 2
InGameMenuMapFrame.MAP_SOIL = 3
InGameMenuMapFrame.MAP_HOTSPOTS = 4
InGameMenuMapFrame.MAP_FARMLANDS = 5
InGameMenuMapFrame.AI_CREATE_JOB = 6
InGameMenuMapFrame.AI_WORKER_LIST = 7
InGameMenuMapFrame.AI_MODE_OVERVIEW = 1
InGameMenuMapFrame.AI_MODE_CREATE = 2
InGameMenuMapFrame.AI_MODE_WORKER_LIST = 3
InGameMenuMapFrame.BUTTON_FRAME_SIDE = GuiElement.FRAME_RIGHT
InGameMenuMapFrame.FIELD_INFO_DELAY = 1500
InGameMenuMapFrame.FIELD_INFO_LAYOUT_BASE_SIZE = 125
local function NO_CALLBACK() end
function InGameMenuMapFrame.register()
    local inGameMenuMapFrame = InGameMenuMapFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuMapFrame.xml", "MapFrame", inGameMenuMapFrame, true)
end
function InGameMenuMapFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuMapFrame_mt, (copy) NO_CALLBACK
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMapFrame_mt)
    self.onClickBackCallback = NO_CALLBACK
    self.client = nil
    self.playerFarm = nil
    self.contextActions = {}
    self.contextActionMapping = {}
    self.fruitTypeFilter = {}
    self.growthStateFilter = {}
    self.soilStateFilter = {}
    self.hotspotStateFilter = {
        {},
        {}
    }
    self.filterStates = {
        self.fruitTypeFilter,
        self.growthStateFilter,
        self.soilStateFilter,
        self.hotspotStateFilter
    }
    self.numSelectedFilters = {
        0,
        0,
        0,
        0
    }
    self.hasFullScreenMap = true
    self.dataTables = {}
    self.farmlandItems = {}
    self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
    self.isMapOverviewInitialized = false
    self.lastInputHelpMode = 0
    self.isInputContextActive = false
    self.nextMoneyUpdateTime = 0
    self.foliageStateOverlay = nil
    self.foliageStateOverlayIsReady = false
    self.farmlandStateOverlay = nil
    self.farmlandStateOverlayIsReady = false
    function self.overviewOverlayFinishedCallback(overlayId)
        -- upvalues: (copy) self
        self:onOverviewOverlayFinished(overlayId)
    end
    function self.farmlandOverlayFinishedCallback(overlayId)
        -- upvalues: (copy) self
        self:onFarmlandOverlayFinished(overlayId)
    end
    self.hotspotModeActive = false
    self.currentHotspot = nil
    self.ingameMapBase = nil
    self.staticUIDeadzone = {
        0,
        0,
        0,
        0
    }
    self.needsSolidBackground = Platform.ingameMap.needsSolidBackground
    self.selectedFarmland = nil
    self.selectedVehicle = nil
    self.previousSubCategoryState = 1
    self.showIntroductionHud = false
    self.showIntroHudIfNotSaving = false
    self.goToMainOverview = false
    self.jobTypeInstances = {}
    self.statusMessages = {}
    self.playerFarmActiveJobs = {}
    self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
    self.lastMousePosX = 0
    self.lastMousePosY = 0
    self.updateTime = 0
    self.aiTargetMapHotspot = AITargetHotspot.new()
    self.aiLoadingMarkerHotspot = AIPlaceableMarkerHotspot.new()
    self.aiUnloadingMarkerHotspot = AIPlaceableMarkerHotspot.new()
    self.lastInputTime = 0
    return self
end
function InGameMenuMapFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuMapFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    g_messageCenter:unsubscribeAll(newGui)
    return newGui
end
function InGameMenuMapFrame:copyAttributes(src)
    -- upvalues: (copy) NO_CALLBACK
    InGameMenuMapFrame:superClass().copyAttributes(self, src)
    self.onClickBackCallback = src.onClickBackCallback or NO_CALLBACK
end
function InGameMenuMapFrame:delete()
    g_messageCenter:unsubscribeAll(self)
    self.createMultiOptionTemplate:delete()
    self.createTextTemplate:delete()
    self.createTitleTemplate:delete()
    self.createPositionTemplate:delete()
    self.createPositionRotationTemplate:delete()
    self.fieldInfoKeyValueTemplate:delete()
    self.fieldInfoWarningTemplate:delete()
    if self.aiTargetMapHotspot ~= nil then
        self.aiTargetMapHotspot:delete()
        self.aiTargetMapHotspot = nil
    end
    if self.aiLoadingMarkerHotspot ~= nil then
        self.aiLoadingMarkerHotspot:delete()
        self.aiLoadingMarkerHotspot = nil
    end
    if self.aiUnloadingMarkerHotspot ~= nil then
        self.aiUnloadingMarkerHotspot:delete()
        self.aiUnloadingMarkerHotspot = nil
    end
    InGameMenuMapFrame:superClass().delete(self)
end
function InGameMenuMapFrame:initialize(onClickBackCallback)
    -- upvalues: (copy) NO_CALLBACK
    self:updateInputGlyphs()
    self.onClickBackCallback = onClickBackCallback or NO_CALLBACK
    for index, dot in pairs(self.subCategoryDotBox.elements) do
        local index
        function dot.getIsSelected()
            -- upvalues: (copy) self, (copy) index
            return self.mapOverviewSelector:getState() == index
        end
    end
    local filterList = self.filterList
    function filterList.mouseEvent(list, posX, posY, isDown, isUp, button, eventUsed)
        -- upvalues: (copy) filterList, (copy) self
        SmoothListElement.mouseEvent(list, posX, posY, isDown, isUp, button, eventUsed)
        if isDown and (button == Input.MOUSE_BUTTON_RIGHT and GuiUtils.checkOverlayOverlap(posX, posY, filterList.absPosition[1], filterList.absPosition[2], filterList.absSize[1], filterList.absSize[2])) then
            local _, section, index = filterList:getElementAtScreenPosition(posX, posY)
            self:onClickDeselectAll(section, index)
            filterList:setSelectedItem(section, index)
        end
    end
    self:initializeContextActions()
    self.zoomText = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_ZOOM_MAP)
    self.moveCursorText = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_MOVE_CURSOR)
    self.panMapText = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_PAN_MAP)
    function self.buttonDeselectAllText.getIsFocused()
        -- upvalues: (copy) self
        return self.buttonDeselectAll:getIsFocused()
    end
    function self.buttonDeselectAllText.getIsHighlighted()
        -- upvalues: (copy) self
        return self.buttonDeselectAll:getIsHighlighted()
    end
    function self.buttonStartJobText.getIsFocused()
        -- upvalues: (copy) self
        return self.buttonStartJob:getIsFocused()
    end
    function self.buttonStartJobText.getIsHighlighted()
        -- upvalues: (copy) self
        return self.buttonStartJob:getIsHighlighted()
    end
    self.createMultiOptionTemplate:unlinkElement()
    FocusManager:removeElement(self.createMultiOptionTemplate)
    self.createTextTemplate:unlinkElement()
    FocusManager:removeElement(self.createTextTemplate)
    self.createTitleTemplate:unlinkElement()
    FocusManager:removeElement(self.createTitleTemplate)
    self.createPositionTemplate:unlinkElement()
    FocusManager:removeElement(self.createPositionTemplate)
    self.createPositionRotationTemplate:unlinkElement()
    FocusManager:removeElement(self.createPositionRotationTemplate)
    self.fieldInfoKeyValueTemplate:unlinkElement()
    FocusManager:removeElement(self.fieldInfoKeyValueTemplate)
    self.fieldInfoWarningTemplate:unlinkElement()
    FocusManager:removeElement(self.fieldInfoWarningTemplate)
    self.fieldInfoLayout:invalidateLayout()
    self.currentContextBox = self.contextBox
end
function InGameMenuMapFrame:initializeContextActions()
    self.contextActions = {
        [InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE] = {
            ["text"] = "button_enterVehicle",
            ["callback"] = self.onClickEnterVehicle,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.RESET_VEHICLE] = {
            ["text"] = "button_reset",
            ["callback"] = self.onClickResetVehicle,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.SELL_VEHICLE] = {
            ["text"] = "button_sell",
            ["callback"] = self.onClickSellVehicle,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.BUY] = {
            ["text"] = "button_buy",
            ["callback"] = self.onClickBuy,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.SELL] = {
            ["text"] = "button_sell",
            ["callback"] = self.onClickSell,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.VISIT_PLACE] = {
            ["text"] = "action_visit",
            ["callback"] = self.onClickVisitPlace,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.SET_MARKER] = {
            ["text"] = "action_tag",
            ["callback"] = self.onClickTagPlace,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.REMOVE_MARKER] = {
            ["text"] = "action_untag",
            ["callback"] = self.onClickTagPlace,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.MANAGE] = {
            ["text"] = "action_manage",
            ["callback"] = self.onClickManage,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.GOTO_JOB] = {
            ["text"] = "button_gotoJob",
            ["callback"] = self.onStartGoToJob,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.CREATE_JOB] = {
            ["text"] = "button_createJob",
            ["callback"] = self.onCreateJob,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.START_JOB] = {
            ["text"] = "button_startJob",
            ["callback"] = self.onStartCancelJob,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.CANCEL_JOB] = {
            ["text"] = "button_cancelJob",
            ["callback"] = self.onStartCancelJob,
            ["isActive"] = false
        },
        [InGameMenuMapFrame.ACTIONS.SKIP_TASK] = {
            ["text"] = "button_skipTask",
            ["callback"] = self.onSkipJobTask,
            ["isActive"] = false
        }
    }
    FocusManager:linkElements(self.contextButtonList, FocusManager.TOP, nil)
    FocusManager:linkElements(self.contextButtonList, FocusManager.BOTTOM, nil)
    FocusManager:linkElements(self.contextButtonList, FocusManager.LEFT, nil)
    FocusManager:linkElements(self.contextButtonList, FocusManager.RIGHT, nil)
    FocusManager:linkElements(self.contextButtonListFarmland, FocusManager.TOP, nil)
    FocusManager:linkElements(self.contextButtonListFarmland, FocusManager.BOTTOM, nil)
    FocusManager:linkElements(self.contextButtonListFarmland, FocusManager.LEFT, nil)
    FocusManager:linkElements(self.contextButtonListFarmland, FocusManager.RIGHT, nil)
    FocusManager:linkElements(self.filterList, FocusManager.LEFT, nil)
    FocusManager:linkElements(self.filterList, FocusManager.RIGHT, nil)
    FocusManager:linkElements(self.filterList, FocusManager.BOTTOM, nil)
end
function InGameMenuMapFrame:onFrameOpen()
    InGameMenuMapFrame:superClass().onFrameOpen(self)
    self:loadFilters()
    self:setColorBlindMode(Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false))
    self:toggleMapInput(true)
    self.ingameMap:onOpen()
    self.ingameMap:registerActionEvents()
    self.ingameMapBase:restoreDefaultFilter()
    if self.visible and not self.isMapOverviewInitialized then
        self:setupMapOverview()
        self.filterList:reloadData()
        self.mapOverviewSelector:setState(1, true)
    end
    self:setMapSelectionItem(nil)
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self.mapOverviewSelector)
    self:setSoundSuppressed(false)
    self:updateInputGlyphs()
    self.ingameMap:setCursorCenter(self.filterBox.absSize[1] * 0.5, self.buttonBox.absSize[2] * 0.5)
    if g_localPlayer ~= nil then
        local x, _, z = g_localPlayer:getPosition()
        self.ingameMap:setCenterToWorldPosition(x, z)
    end
    self:generateJobTypes()
    self:setJobMenuVisible(false)
    self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
    self.playerFarmActiveJobs = {}
    local x = 1
    if g_localPlayer ~= nil then
        x = g_localPlayer.farmId
    end
    for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
        if job.startedFarmId == x then
            table.insert(self.playerFarmActiveJobs, job.jobId)
        end
    end
    self.activeWorkerList:reloadData()
    self:onMoneyChange()
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChange, self)
    g_messageCenter:subscribe(MessageType.AI_VEHICLE_STATE_CHANGE, self.onAIVehicleStateChanged, self)
    g_messageCenter:subscribe(MessageType.AI_JOB_STARTED, self.onAIJobStarted, self)
    g_messageCenter:subscribe(MessageType.AI_JOB_STOPPED, self.onAIJobStopped, self)
    g_messageCenter:subscribe(MessageType.AI_JOB_REMOVED, self.onAIJobRemoved, self)
    g_messageCenter:subscribe(MessageType.AI_TASK_SKIPPED, self.onAITaskSkipped, self)
    g_messageCenter:subscribe(MessageType.PAUSE, self.onPauseChanged, self)
    g_messageCenter:subscribe(MessageType.VEHICLE_PLAYER_ENTERED, self.onVehicleEntered, self)
    g_messageCenter:subscribe(MessageType.VEHICLE_PLAYER_LEFT, self.onVehicleLeft, self)
    self:onClickMapOverviewSelector(self.mapOverviewSelector:getState())
    local z = self.mapOverviewSelector:getState() ~= InGameMenuMapFrame.AI_WORKER_LIST
    self.blockListSelectionUpdates = z
    self.lastInputTime = g_time
end
function InGameMenuMapFrame:onFrameClose()
    g_messageCenter:unsubscribeAll(self)
    if self.previousSubCategoryState == InGameMenuMapFrame.AI_CREATE_JOB then
        for _, hotspot in pairs(self.ingameMap.ingameMap.hotspots) do
            if hotspot:isa(VehicleHotspot) or hotspot:isa(AIHotspot) then
                hotspot:setVisible(hotspot.oldVisibility)
            end
        end
    end
    self.isResetPending = false
    self.startJobPending = false
    if self:getIsPicking() then
        self:executePickingCallback(false)
        self:refreshContextInput()
    end
    if self.hotspotModeActive then
        self:setHotspotModeActive(false)
    end
    local mission = g_currentMission
    mission:removeMapHotspot(self.aiTargetMapHotspot)
    mission:removeMapHotspot(self.aiLoadingMarkerHotspot)
    mission:removeMapHotspot(self.aiUnloadingMarkerHotspot)
    self.statusMessages = {}
    self:updateStatusMessages()
    InGameMenuMapFrame:superClass().onFrameClose(self)
    self.ingameMap:onClose()
    self:toggleMapInput(false)
    self.ingameMapBase:restoreDefaultFilter()
end
function InGameMenuMapFrame:saveFilters()
    local fruitValue = ""
    for fruitId, state in pairs(self.fruitTypeFilter) do
        if not state then
            local name = g_fruitTypeManager:getFillTypeNameByFruitTypeIndex(fruitId)
            if fruitValue == "" then
                fruitValue = name
            end
        end
    end
    local growthValue = 0
    for state, name in ipairs(self.growthStateFilter) do
        if name then
            growthValue = Utils.setBit(growthValue, state)
        end
    end
    local soilValue = 0
    for name, state in ipairs(self.soilStateFilter) do
        if state then
            soilValue = Utils.setBit(soilValue, name)
        end
    end
    local hotspotValue = 0
    for state, state in ipairs(self.hotspotStateFilter[1]) do
        if state then
            hotspotValue = Utils.setBit(hotspotValue, state)
        end
    end
    for state, state in ipairs(self.hotspotStateFilter[2]) do
        if state then
            hotspotValue = Utils.setBit(hotspotValue, state + #self.hotspotStateFilter[1])
        end
    end
    g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER, fruitValue, false)
    g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER, growthValue, false)
    g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER, soilValue, true)
    g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER, hotspotValue, true)
end
function InGameMenuMapFrame:loadFilters()
    local numInactiveFilters = 0
    local fruitValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER)
    for _, fruitName in ipairs(fruitValue:split(";")) do
        local fruitDesc = g_fruitTypeManager:getFruitTypeByName(fruitName)
        if fruitDesc ~= nil then
            self.fruitTypeFilter[fruitDesc.index] = false
        end
    end
    for _, fruitName in pairs(self.displayCropTypes) do
        if self.fruitTypeFilter[fruitName.fruitTypeIndex] == nil then
            self.fruitTypeFilter[fruitName.fruitTypeIndex] = true
        end
    end
    local growthValue = self.numSelectedFilters
    local soilValue = #self.displayCropTypes - numInactiveFilters
    growthValue[1] = math.max(soilValue, 0)
    if self.numSelectedFilters[1] == 0 then
        self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
    end
    local growthValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER)
    for fruitName, fruitDesc in pairs(self.displayGrowthStates) do
        local isBitSet = Utils.isBitSet(growthValue, fruitName)
        self.growthStateFilter[fruitName] = isBitSet
        if isBitSet then
            self.numSelectedFilters[2] = self.numSelectedFilters[2] + 1
        end
    end
    local lastSoilFilter = 1
    local soilValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER)
    for isBitSet, state in pairs(self.displaySoilStateMapping) do
        lastSoilFilter = state.soilStateIndex
        local isBitSet = Utils.isBitSet(soilValue, lastSoilFilter)
        self.soilStateFilter[lastSoilFilter] = isBitSet
        if isBitSet then
            self.numSelectedFilters[3] = self.numSelectedFilters[3] + 1
        end
    end
    local fruitDesc = 1
    local fruitName = 1
    for fruitDesc = fruitDesc, lastSoilFilter, fruitName do
        if self.displaySoilStates[fruitDesc] == nil then
            self.soilStateFilter[fruitDesc] = false
        end
    end
    local _ = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER)
    for state, index in pairs(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[1]) do
        local isBitSet = Utils.isBitSet(_, state)
        self.hotspotStateFilter[1][state] = isBitSet
        self.ingameMapBase:setDefaultFilterValue(index.id, isBitSet)
        if isBitSet then
            self.numSelectedFilters[4] = self.numSelectedFilters[4] + 1
        end
    end
    for state, index in pairs(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[2]) do
        local isBitSet = Utils.isBitSet(_, state + #self.hotspotStateFilter[1])
        self.hotspotStateFilter[2][state] = isBitSet
        self.ingameMapBase:setDefaultFilterValue(index.id, isBitSet)
        if isBitSet then
            self.numSelectedFilters[4] = self.numSelectedFilters[4] + 1
        end
    end
end
function InGameMenuMapFrame:onLoadMapFinished()
    local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
    self.displaySoilStateMapping = {}
    if mapOverlayGenerator ~= nil then
        self.displayCropTypes = mapOverlayGenerator:getDisplayCropTypes()
        self.displayGrowthStates = mapOverlayGenerator:getDisplayGrowthStates()
        self.displaySoilStates = mapOverlayGenerator:getDisplaySoilStates()
        for index, state in pairs(self.displaySoilStates) do
            if state.isActive then
                state.soilStateIndex = index
                table.insert(self.displaySoilStateMapping, state)
            end
        end
    end
    self.dataTables[InGameMenuMapFrame.MAP_SOIL] = self.displaySoilStateMapping or {}
    self.dataTables[InGameMenuMapFrame.MAP_FRUIT_TYPE] = self.displayCropTypes or {}
    self.dataTables[InGameMenuMapFrame.MAP_GROWTH] = self.displayGrowthStates or {}
    self.dataTables[InGameMenuMapFrame.MAP_HOTSPOTS] = InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES or {}
    self.dataTables[InGameMenuMapFrame.MAP_FARMLANDS] = self.farmlandItems or {}
    g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER, 4294967295, true)
    if g_terrainNode ~= nil then
        self.filterList:reloadData()
    end
end
function InGameMenuMapFrame:onSoilSettingChanged()
    local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
    self.displaySoilStateMapping = {}
    if mapOverlayGenerator ~= nil then
        mapOverlayGenerator:updateStates()
        self.displaySoilStates = mapOverlayGenerator:getDisplaySoilStates()
        for index, state in pairs(self.displaySoilStates) do
            if state.isActive then
                state.soilStateIndex = index
                table.insert(self.displaySoilStateMapping, state)
            end
        end
    end
    self.dataTables[InGameMenuMapFrame.MAP_SOIL] = self.displaySoilStateMapping
    self.filterList:reloadData()
end
function InGameMenuMapFrame:toggleMapInput(isActive)
    if self.isInputContextActive ~= isActive then
        self.isInputContextActive = isActive
        self:toggleCustomInputContext(isActive, InGameMenuMapFrame.INPUT_CONTEXT_NAME)
        if isActive then
            self:registerInput()
            return
        end
        self:unregisterInput(true)
    end
end
function InGameMenuMapFrame:reset()
    InGameMenuMapFrame:superClass().reset(self)
    self.foliageStateOverlayIsReady = false
    self.farmlandStateOverlayIsReady = false
    self.isMapOverviewInitialized = false
    self.isInputContextActive = false
    self:setMapSelectionItem(nil)
end
function InGameMenuMapFrame:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if self.isPickingRotation then
        local localX, localY = self.ingameMap:getLocalPosition(posX, posY)
        local worldX, worldZ = self.ingameMap:localToWorldPos(localX, localY)
        local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2]) + 3.141592653589793
        if self.pickingRotationSnapAngle > 0 then
            angle = MathUtil.round(angle / self.pickingRotationSnapAngle, 0) * self.pickingRotationSnapAngle
        end
        self.aiTargetMapHotspot:setWorldRotation(angle)
    end
    self.lastMousePosX = posX
    self.lastMousePoxY = posY
    if self.isPickingLocation then
        local localX, localY = self.ingameMap:getLocalPosition(self.lastMousePosX, self.lastMousePoxY)
        if self.filterBox.absPosition[1] + self.filterBox.absSize[1] < posX and self.buttonBox.absPosition[2] + self.buttonBox.absSize[2] < posY then
            self:setTargetPointHotspotPosition(localX, localY)
        end
    end
    self.lastInputTime = g_time
    return InGameMenuMapFrame:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
end
function InGameMenuMapFrame:inputEvent(action, value, eventUsed)
    self.lastInputTime = g_time
    return InGameMenuMapFrame:superClass().inputEvent(self, action, value, eventUsed)
end
function InGameMenuMapFrame:update(dt)
    InGameMenuMapFrame:superClass().update(self, dt)
    if self.elementToFocus ~= nil and (not g_gui:getIsDialogVisible() and FocusManager:setFocus(self.elementToFocus)) then
        self.elementToFocus = nil
    end
    local currentInputHelpMode = g_inputBinding:getInputHelpMode()
    if currentInputHelpMode ~= self.lastInputHelpMode then
        self.lastInputHelpMode = currentInputHelpMode
        self.buttonSelectIngame:setVisible(currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD)
        self:updateContextInputBarVisibility()
        g_inputBinding:setShowMouseCursor(currentInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD)
        self:updateInputGlyphs()
        self.contextButtonList:reloadData()
    end
    if self.needsOverlayUpdate then
        self:generateFarmlandOverlay(self.selectedFarmland)
        self.needsOverlayUpdate = false
    end
    if self.showIntroHudIfNotSaving then
        if g_savegameController:getIsSaving() then
            self.showIntroductionHud = true
            self.showIntroHudIfNotSaving = false
        else
            local mission = g_currentMission
            if mission.introductionHelpSystem:getIsActive() then
                mission.introductionHelpSystem:showHelp("helpZoomMap")
                mission.introductionHelpSystem:showHelp("helpPanMap")
            end
            self.showIntroHudIfNotSaving = false
        end
    end
    if self.showIntroductionHud and not g_savegameController:getIsSaving() then
        self.showIntroductionHud = false
        self.showIntroHudIfNotSaving = true
    end
    if currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
        local mission, localY = self.ingameMap:getLocalPointerTarget()
        if self.isPickingLocation then
            self:setTargetPointHotspotPosition(mission, localY)
        elseif self.isPickingRotation then
            local worldX, worldZ = self.ingameMap:localToWorldPos(mission, localY)
            local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2]) + 3.141592653589793
            if self.pickingRotationSnapAngle > 0 then
                angle = MathUtil.round(angle / self.pickingRotationSnapAngle, 0) * self.pickingRotationSnapAngle
            end
            self.aiTargetMapHotspot:setWorldRotation(angle)
        end
    end
    if self.updateTime < g_time then
        local angle = 1
        local numSteps = self.activeWorkerList:getItemCount()
        for angle = angle, numSteps do
            local numSteps = self.activeWorkerList:getElementAtSectionIndex(1, angle)
            if numSteps ~= nil then
                local job = g_currentMission.aiSystem:getJobById(self.playerFarmActiveJobs[angle])
                local textElement = numSteps:getAttribute("text")
                if job ~= nil and textElement:getText() ~= job:getDescription() then
                    textElement:setText(job:getDescription())
                end
            end
        end
        self.updateTime = g_time + 1000
    end
    local mission = false
    local worldZ = 1
    local localY = #self.statusMessages
    local worldX = 1
    for worldZ = worldZ, localY, worldX do
        if self.statusMessages[1].removeTime < g_time then
            table.remove(self.statusMessages, 1)
            mission = true
        end
    end
    if mission then
        self:updateStatusMessages()
    end
    self.blockListSelectionUpdates = false
    if g_gui:getIsDialogVisible() then
        self.lastInputTime = g_time
    end
    if g_time - self.lastInputTime > InGameMenuMapFrame.FIELD_INFO_DELAY then
        local localY = self.fieldInfoBox
        if self.currentHotspot == nil and not localY:getIsVisible() then
            local angle, numSteps
            if currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
                angle, numSteps = self.mapCursor:getCenter()
            else
                angle = g_lastMousePosX
                numSteps = g_lastMousePosY
            end
            self:clearFieldInfoBox()
            if self:updateFieldInfoBox(angle, numSteps) then
                localY:setVisible(true)
                local angle = localY:getDescendantByName("backgroundTop")
                local numSteps = localY:getDescendantByName("backgroundBottom")
                local job = localY:getDescendantByName("layout")
                job:invalidateLayout()
                localY:setSize(nil, angle.absSize[2] - angle.position[2] + numSteps.absSize[2] + numSteps.position[2] + math.max(job.maxFlowSize - InGameMenuMapFrame.FIELD_INFO_LAYOUT_BASE_SIZE * g_pixelSizeScaledY, 0))
                InGameMenuMapUtil.updateFieldInfoBoxPosition(self.fieldInfoBox, angle, numSteps)
                return
            end
        end
    else
        self.fieldInfoBox:setVisible(false)
    end
end
function InGameMenuMapFrame:clearFieldInfoBox()
    local layout = self.fieldInfoBox:getDescendantByName("layout")
    local i = #layout.elements
    for i = i, 1, -1 do
        layout.elements[i]:delete()
        layout.elements[i] = nil
    end
end
function InGameMenuMapFrame:addFieldInfoKeyValue(key, value)
    local layout = self.fieldInfoBox:getDescendantByName("layout")
    local clonedElement = self.fieldInfoKeyValueTemplate:clone(layout)
    local title = clonedElement:getDescendantByName("title")
    local text = clonedElement:getDescendantByName("text")
    title:setText(key)
    text:setText(value)
end
function InGameMenuMapFrame:addFieldInfoWarning(text)
    local layout = self.fieldInfoBox:getDescendantByName("layout")
    self.fieldInfoWarningTemplate:clone(layout):getDescendantByName("warning"):setText(text)
end
function InGameMenuMapFrame:updateFieldInfoBox(screenX, screenY)
    local localX, localY = self.ingameMap:getLocalPosition(screenX, screenY)
    local worldX, worldZ = self.ingameMap:localToWorldPos(localX, localY)
    if self.fieldInfo == nil then
        self.fieldInfo = FieldState.new()
    end
    local fieldInfo = self.fieldInfo
    fieldInfo:update(worldX, worldZ)
    if fieldInfo.groundType == FieldGroundType.NONE then
        return false
    end
    local ownedByYou = false
    local ownerFarmId = fieldInfo.ownerFarmId
    local isGrowing
    if ownerFarmId == g_currentMission:getFarmId() and ownerFarmId ~= FarmManager.SPECTATOR_FARM_ID then
        isGrowing = g_i18n:getText("fieldInfo_ownerYou")
        ownedByYou = true
    elseif ownerFarmId == AccessHandler.EVERYONE or ownerFarmId == AccessHandler.NOBODY then
        local farmland = g_farmlandManager:getFarmlandById(fieldInfo.farmlandId)
        if farmland == nil then
            isGrowing = g_i18n:getText("fieldInfo_ownerNobody")
        else
            local npc = farmland:getNPC()
            isGrowing = npc ~= nil and npc.title or "Unknown"
        end
    else
        local farmland = g_farmManager:getFarmById(ownerFarmId)
        isGrowing = farmland == nil and "Unknown" or farmland.name
    end
    local isGrowing = g_i18n:getText("fieldInfo_farmland")
    local text = fieldInfo.farmlandId
    self:addFieldInfoKeyValue(isGrowing, (tostring(text)))
    if Platform.playerInfo.showNPCNames then
        self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), isGrowing)
    elseif ownedByYou then
        self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_owned"))
    else
        self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_notOwned"))
    end
    local farmland = fieldInfo.fruitTypeIndex
    local npc = fieldInfo.growthState
    local isGrowing = false
    if farmland ~= FruitType.UNKNOWN then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(farmland)
        self:addFieldInfoKeyValue(g_i18n:getText("statistic_fillType"), fruitTypeDesc.fillType.title)
        local text = nil
        if fruitTypeDesc:getIsCut(npc) then
            text = g_i18n:getText("ui_growthMapCut")
        elseif fruitTypeDesc:getIsWithered(npc) then
            text = g_i18n:getText("ui_growthMapWithered")
        elseif fruitTypeDesc:getIsGrowing(npc) then
            text = g_i18n:getText("ui_growthMapGrowing")
            isGrowing = true
        elseif fruitTypeDesc:getIsPreparable(npc) then
            text = g_i18n:getText("ui_growthMapReadyToPrepareForHarvest")
            isGrowing = true
        elseif fruitTypeDesc:getIsHarvestable(npc) then
            text = g_i18n:getText("ui_growthMapReadyToHarvest")
            isGrowing = true
        end
        if text ~= nil then
            self:addFieldInfoKeyValue(g_i18n:getText("ui_mapOverviewGrowth"), text)
        end
    end
    local fruitTypeDesc = g_currentMission.fieldGroundSystem
    if isGrowing then
        local text = fieldInfo:getHarvestScaleMultiplier() - 1
        local sprayFactor = MathUtil.round(text * 100)
        self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_yieldBonus"), string.format("+ %d %%", sprayFactor))
    end
    if fieldInfo.sprayLevel >= 0 then
        local text = fruitTypeDesc:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
        self:addFieldInfoKeyValue(g_i18n:getText("ui_growthMapFertilized"), string.format("%d %%", fieldInfo.sprayLevel / text * 100))
    end
    local text = g_currentMission.missionInfo
    if Platform.gameplay.useLimeCounter and (text.limeRequired and fieldInfo.limeLevel == 0) then
        self:addFieldInfoWarning(g_i18n:getText("ui_growthMapNeedsLime"))
    end
    if fieldInfo.plowLevel == 0 and text.plowingRequiredEnabled then
        self:addFieldInfoWarning(g_i18n:getText("ui_growthMapNeedsPlowing"))
    end
    if Platform.gameplay.useRolling and fieldInfo.rollerLevel > 0 then
        self:addFieldInfoWarning(g_i18n:getText("ui_growthMapNeedsRolling"))
    end
    if g_currentMission.missionInfo.weedsEnabled then
        local sprayFactor = g_currentMission.weedSystem
        local fieldInfoStates = sprayFactor:getFieldInfoStates()
        local weedState = fieldInfo.weedState
        local toolName = nil
        if weedState > 0 then
            local fruitTypeDesc = nil
            if farmland ~= nil then
                fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(farmland)
            end
            if Platform.gameplay.hasWeeder then
                if (fruitTypeDesc == nil or fruitTypeDesc:getIsWeedable(npc)) and sprayFactor:getWeederReplacements(false).weed.replacements[weedState] == 0 then
                    toolName = g_i18n:getText("weed_destruction_weeder")
                end
                if toolName == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsHoeable(npc)) and sprayFactor:getWeederReplacements(true).weed.replacements[weedState] == 0 then
                    toolName = g_i18n:getText("weed_destruction_hoe")
                end
            end
            if toolName == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsGrowing(npc)) then
                toolName = g_i18n:getText("weed_destruction_herbicide")
            end
            local weederReplacements = fieldInfoStates[weedState]
            if weederReplacements ~= nil then
                self:addFieldInfoKeyValue(weederReplacements, toolName or "")
            end
        end
    end
    return true
end
function InGameMenuMapFrame:setTargetPointHotspotPosition(localX, localY)
    local worldX, worldZ = self.ingameMap:localToWorldPos(localX, localY)
    self.aiTargetMapHotspot:setWorldPosition(worldX, worldZ)
end
function InGameMenuMapFrame:getCanCancelJob()
    return self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking() and (self.canCancel and g_currentMission:getHasPlayerPermission("hireAssistant")) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMapFrame:getCanCreateJob()
    return self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking() and (self.canCreateJob and g_currentMission:getHasPlayerPermission("hireAssistant")) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMapFrame:getCanGoTo()
    return self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking() and (self.canGoTo and g_currentMission:getHasPlayerPermission("hireAssistant")) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMapFrame:getCanStartJob()
    return self.mode == InGameMenuMapFrame.AI_MODE_CREATE and (not self:getIsPicking() and g_currentMission:getHasPlayerPermission("hireAssistant")) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMapFrame:getCanSkipJobTask()
    return self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking() and (self.canSkipTask and g_currentMission:getHasPlayerPermission("hireAssistant")) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMapFrame:getCanGoBack()
    return self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and not self:getIsPicking() and (not (self.mapOverviewSelector:getState() == InGameMenuMapFrame.AI_WORKER_LIST and self.currentHotspot ~= nil) and (not (self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS and self.selectedFarmland ~= nil) and not self.hotspotModeActive))
end
function InGameMenuMapFrame:setAIInputContext(canGoTo, canCreateJob, canCancel, canSkipTask, canEnter, canReset, canSell, isVehicleContext)
    self.canGoTo = canGoTo
    self.canCreateJob = canCreateJob
    self.canCancel = canCancel
    self.canSkipTask = canSkipTask
    if self.mode == InGameMenuMapFrame.AI_MODE_WORKER_LIST then
        isVehicleContext = false
    elseif isVehicleContext then
        isVehicleContext = not g_guidedTourManager:getIsTourRunning()
    end
    self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].isActive = isVehicleContext and canEnter
    self.contextActions[InGameMenuMapFrame.ACTIONS.RESET_VEHICLE].isActive = isVehicleContext and canReset
    self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].isActive = isVehicleContext and canSell
    self:updateContextInputBarVisibility()
end
function InGameMenuMapFrame:setMapInputContext(canEnter, canReset, canSellVehicle, canVisit, canSetMarker, removeMarker, canBuy, canSell, canManage)
    self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].isActive = canEnter
    self.contextActions[InGameMenuMapFrame.ACTIONS.RESET_VEHICLE].isActive = canReset
    self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].isActive = canSellVehicle
    self.contextActions[InGameMenuMapFrame.ACTIONS.BUY].isActive = canBuy
    self.contextActions[InGameMenuMapFrame.ACTIONS.SELL].isActive = canSell
    self.contextActions[InGameMenuMapFrame.ACTIONS.VISIT_PLACE].isActive = canVisit
    self.contextActions[InGameMenuMapFrame.ACTIONS.SET_MARKER].isActive = canSetMarker
    self.contextActions[InGameMenuMapFrame.ACTIONS.REMOVE_MARKER].isActive = removeMarker
    self.contextActions[InGameMenuMapFrame.ACTIONS.MANAGE].isActive = canManage
    self:updateContextInputBarVisibility()
end
function InGameMenuMapFrame:refreshContextInput()
    local hotspot = self.currentHotspot
    local vehicle = InGameMenuMapUtil.getHotspotVehicle(hotspot)
    local mission = g_currentMission
    local showContextButtons = not mission.paused
    if showContextButtons then
        showContextButtons = self.mode ~= InGameMenuMapFrame.AI_MODE_WORKER_LIST
    end
    local canGoTo = false
    local canCreateJob = false
    local canCancel = false
    local canSkipTask = false
    local canReset = false
    local canSell = false
    local canEnter = false
    if vehicle == nil then
        showContextButtons = canCancel
    else
        canEnter = vehicle.getIsEnterableFromMenu ~= nil and vehicle:getIsEnterableFromMenu()
        if canEnter then
            canEnter = not mission.paused
        end
        if not self.isResetPending and (vehicle:getCanBeReset() and (hotspot:getCategory() ~= MapHotspot.CATEGORY_AI and (mission:getHasPlayerPermission(Farm.PERMISSION.RESET_VEHICLE) and vehicle:getOwnerFarmId() == self.playerFarm.farmId))) then
            canReset = not mission.paused
        end
        if mission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) and (vehicle:getOwnerFarmId() == self.playerFarm.farmId and vehicle:getCanBeSold()) then
            canSell = false
            if vehicle.propertyState ~= VehiclePropertyState.MISSION then
                canSell = not mission.paused
            end
            if vehicle.propertyState == VehiclePropertyState.LEASED then
                self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].text = "button_return"
            else
                self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].text = "button_sell"
            end
        end
        if mission.accessHandler:canPlayerAccess(vehicle) and vehicle.spec_aiJobVehicle ~= nil then
            local job = vehicle:getIsAIActive()
            if job then
                local job = vehicle:getJob()
                if job ~= nil then
                    if job:getCanSkipTask() then
                        canSkipTask = showContextButtons
                    end
                end
            else
                canGoTo = self.jobTypeInstances[AIJobType.GOTO]:getIsAvailableForVehicle(vehicle) and showContextButtons
                canCreateJob = false
                canCancel, v32_, v33_ = pairs(self.jobTypeInstances)
                for typeIndex, instance in job, v32_, v33_ do
                    if instance:getIsAvailableForVehicle(vehicle) then
                        canCreateJob = showContextButtons
                        break
                    end
                end
            end
        else
            showContextButtons = canCancel
        end
    end
    local job = not canCreateJob
    if job then
        job = mission.aiSystem:getAILimitedReached()
    end
    self.limitReachedWarning:setVisible(job)
    self:setAIInputContext(canGoTo, canCreateJob, showContextButtons, canSkipTask, canEnter, canReset, canSell, vehicle ~= nil)
end
function InGameMenuMapFrame:updateContextInputBarVisibility()
    local isSelectAvailable = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD
    local isPicking = self:getIsPicking()
    if isSelectAvailable then
        if not isPicking then
            isPicking = self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW
        end
    else
        isPicking = isSelectAvailable
    end
    self.buttonSelectIngame:setVisible(isPicking)
    self.contextActions[InGameMenuMapFrame.ACTIONS.GOTO_JOB].isActive = self:getCanGoTo() and not (g_currentMission.paused or (self.mode == InGameMenuMapFrame.AI_MODE_WORKER_LIST or g_guidedTourManager:getIsTourRunning()))
    self.contextActions[InGameMenuMapFrame.ACTIONS.CREATE_JOB].isActive = self:getCanCreateJob() and isButtonEnabled
    self.contextActions[InGameMenuMapFrame.ACTIONS.START_JOB].isActive = self:getCanStartJob() and isButtonEnabled
    self.contextActions[InGameMenuMapFrame.ACTIONS.CANCEL_JOB].isActive = self:getCanCancelJob() and isButtonEnabled
    self.contextActions[InGameMenuMapFrame.ACTIONS.SKIP_TASK].isActive = self:getCanSkipJobTask() and isButtonEnabled
    self.contextButtonList:reloadData()
    self.contextButtonListFarmland:reloadData()
    self.contextButtonList:setHandleFocus(self.contextButtonList:getItemCount() > 0)
    self.contextButtonListFarmland:setHandleFocus(self.contextButtonListFarmland:getItemCount() > 0)
end
function InGameMenuMapFrame:setInGameMap(ingameMap)
    self.ingameMapBase = ingameMap
    self.ingameMap:setIngameMap(ingameMap)
    if ingameMap ~= nil then
        self.customFilterFarmlands = ingameMap:createCustomFilter(false)
    end
end
function InGameMenuMapFrame:setTerrainSize(terrainSize)
    self.ingameMap:setTerrainSize(terrainSize)
end
function InGameMenuMapFrame:setClient(client)
    self.client = client
end
function InGameMenuMapFrame:setPlayerFarm(playerFarm)
    self.playerFarm = playerFarm
end
function InGameMenuMapFrame:setAIVehicle(vehicle)
    local hotspot = vehicle:getMapHotspot()
    self:setMapSelectionItem(hotspot)
    self.ingameMap:panToHotspot(hotspot)
    self:onCreateJob()
    self.createJobEmptyText:setVisible(false)
end
function InGameMenuMapFrame:resetUIDeadzones()
    self.ingameMap:clearCursorDeadzones()
    self.ingameMap:addCursorDeadzone(0, 0, self.filterBox.absPosition[1] + self.filterBox.absSize[1], 1)
    self.ingameMap:addCursorDeadzone(0, 0, 1, self.buttonBox.absSize[2])
    self.ingameMap.zoomMin = (g_screenHeight - g_screenHeight * self.buttonBox.absSize[2]) / (g_screenWidth - g_screenWidth * (self.filterBox.absPosition[1] + self.filterBox.absSize[1]))
end
function InGameMenuMapFrame:setupMapOverview()
    self.mapSelectorTexts = {}
    table.insert(self.mapSelectorTexts, string.format(g_i18n:getText("ui_mapOverviewFruitTypes"), ""))
    table.insert(self.mapSelectorTexts, g_i18n:getText("ui_mapOverviewGrowth"))
    table.insert(self.mapSelectorTexts, g_i18n:getText("ui_mapOverviewSoil"))
    table.insert(self.mapSelectorTexts, g_i18n:getText("ui_mapOverviewHotspots"))
    table.insert(self.mapSelectorTexts, g_i18n:getText("ui_farmlandScreen"))
    table.insert(self.mapSelectorTexts, g_i18n:getText("button_createJob"))
    table.insert(self.mapSelectorTexts, g_i18n:getText("ui_activeAIJobs"))
    self.mapOverviewSelector:setTexts(self.mapSelectorTexts)
    self.isMapOverviewInitialized = true
end
function InGameMenuMapFrame:onOverviewOverlayFinished(overlayId)
    self.foliageStateOverlay = overlayId
    self.foliageStateOverlayIsReady = true
    self.dynamicMapImageLoadingBg:setVisible(false)
end
function InGameMenuMapFrame:onFarmlandOverlayFinished(overlayId)
    self.farmlandStateOverlay = overlayId
    self.farmlandStateOverlayIsReady = true
    self.dynamicMapImageLoadingBg:setVisible(false)
end
function InGameMenuMapFrame:generateOverviewOverlay()
    if self.isMapOverviewInitialized then
        if self.foliageStateOverlay == nil then
            self.foliageStateOverlayIsReady = false
        end
        self.dynamicMapImageLoadingBg:setVisible(true)
        local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
        if mapOverlayGenerator ~= nil then
            local state = self.mapOverviewSelector:getState()
            if state == InGameMenuMapFrame.MAP_FRUIT_TYPE or InGameMenuMapFrame.MAP_HOTSPOTS <= state then
                mapOverlayGenerator:generateFruitTypeOverlay(self.overviewOverlayFinishedCallback, self.fruitTypeFilter)
                return
            end
            if state == InGameMenuMapFrame.MAP_GROWTH then
                mapOverlayGenerator:generateGrowthStateOverlay(self.overviewOverlayFinishedCallback, self.growthStateFilter, self.fruitTypeFilter)
                return
            end
            if state == InGameMenuMapFrame.MAP_SOIL then
                mapOverlayGenerator:generateSoilStateOverlay(self.overviewOverlayFinishedCallback, self.soilStateFilter)
            end
        end
    end
end
function InGameMenuMapFrame:generateFarmlandOverlay(selectedFarmland)
    local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
    if mapOverlayGenerator ~= nil then
        if self.isMapOverviewInitialized then
            if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
                mapOverlayGenerator:generateFarmlandOverlay(self.farmlandOverlayFinishedCallback, selectedFarmland)
                return
            elseif selectedFarmland == nil then
                self.farmlandStateOverlayIsReady = false
            else
                mapOverlayGenerator:generateSingleFarmlandOverlay(self.farmlandOverlayFinishedCallback, selectedFarmland)
            end
        end
        self.farmlandStateOverlayIsReady = false
    end
end
function InGameMenuMapFrame:onDrawPostIngameMapHotspots()
    if self.currentContextBox ~= nil then
        InGameMenuMapUtil.updateContextBoxPosition(self.currentContextBox, self.currentHotspot)
    end
    if self.aiTargetMapHotspot ~= nil then
        local icon = self.aiTargetMapHotspot.icon
        self.actionMessage:setAbsolutePosition(self.aiTargetMapHotspot.lastScreenPositionX + icon.width * 0.5, self.aiTargetMapHotspot.lastScreenPositionY + icon.height * 0.5)
    end
end
function InGameMenuMapFrame:setMapSelectionItem(hotspot)
    if hotspot ~= nil then
        local x, _ = hotspot:getWorldPosition()
        if x == nil then
            hotspot = nil
        end
    end
    if self.ingameMapBase ~= nil then
        self.ingameMapBase:setSelectedHotspot(hotspot)
    end
    self.selectedFarmland = nil
    local x = g_currentMission
    local _ = false
    local isVehicle = false
    local isFarmland = false
    local isPlayer = false
    local canEnter = false
    local canReset = false
    local canSellVehicle = false
    local canVisit = false
    local canSetMarker = false
    local removeMarker = false
    local canBuy = false
    local canSell = false
    local canManage = false
    local name = nil
    local imageFilename = nil
    local uvs = nil
    local farmId = nil
    local playerName = nil
    if not (self.isPickingLocation or self.isPickingRotation) then
        x:removeMapHotspot(self.aiTargetMapHotspot)
        x:removeMapHotspot(self.aiLoadingMarkerHotspot)
        x:removeMapHotspot(self.aiUnloadingMarkerHotspot)
    end
    local showContextBox = hotspot ~= nil
    if hotspot == nil then
        if self.currentHotspot ~= nil then
            self.needsOverlayUpdate = true
        end
        self.currentHotspot = nil
    else
        local player = InGameMenuMapUtil.getHotspotVehicle(hotspot)
        if hotspot:isa(PlayerHotspot) then
            local player = hotspot:getPlayer()
            if player ~= nil then
                playerName = player:getNickname()
                farmId = player:getFarmId()
            end
        end
        if hotspot:isa(PlayerHotspot) and player == nil then
            if x.missionDynamicInfo.isMultiplayer then
                isPlayer = true
                self.currentHotspot = hotspot
            else
                self.currentHotspot = nil
                showContextBox = false
            end
        elseif player == nil then
            if hotspot:isa(PlaceableHotspot) then
                name = hotspot:getName()
                if name ~= nil then
                    local player = hotspot:getPlaceable()
                    if player == nil or not player:getIsBeingDeleted() then
                        if player ~= nil then
                            farmId = player:getOwnerFarmId()
                            imageFilename = player:getImageFilename()
                            uvs = Overlay.DEFAULT_UVS
                            _ = player.customImageFilename ~= nil
                            if g_currentMission.accessHandler:canPlayerAccess(player) then
                                canManage = SpecializationUtil.hasSpecialization(PlaceableProductionPoint, player.specializations)
                                canSell = player:canBeSold() and player.storeItem.canBeSold
                                if canSell then
                                    canSell = false
                                    if g_currentMission:getFarmId() == farmId then
                                        canSell = g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_PLACEABLE)
                                    end
                                end
                                if player.spec_productionPoint == nil then
                                    if player.spec_factory ~= nil then
                                        canBuy = player:getOwnerFarmId() == AccessHandler.EVERYONE
                                    end
                                else
                                    local x = player.spec_productionPoint.productionPoint
                                    farmId = x:getOwnerFarmId()
                                    local _ = player.spec_productionPoint.isFinalized
                                    canBuy = false
                                    if farmId == AccessHandler.EVERYONE then
                                        canBuy = x.useInteractionTriggerForBuying
                                    end
                                end
                            end
                        end
                        canSetMarker = x.currentMapTargetHotspot ~= hotspot
                        removeMarker = x.currentMapTargetHotspot == hotspot
                        canVisit = hotspot:getBeVisited()
                        self.currentHotspot = hotspot
                    else
                        showContextBox = false
                        self.currentHotspot = nil
                    end
                end
            elseif hotspot:isa(NPCHotspot) then
                name = hotspot:getName()
                imageFilename = hotspot:getImageFilename()
                canVisit = hotspot:getBeVisited()
                uvs = Overlay.DEFAULT_UVS
                canSetMarker = x.currentMapTargetHotspot == hotspot
                removeMarker = x.currentMapTargetHotspot == hotspot
                self.currentHotspot = hotspot
            elseif hotspot:isa(FarmlandHotspot) then
                if hotspot ~= self.currentHotspot then
                    self.needsOverlayUpdate = true
                end
                isFarmland = true
                self.currentHotspot = hotspot
                self.selectedFarmland = hotspot:getFarmland()
                local player = g_farmlandManager:getFarmlandOwner(self.selectedFarmland.id)
                local x = x:getHasPlayerPermission("farmManager")
                if g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID then
                    canBuy = false
                    if player == FarmlandManager.NO_OWNER_FARM_ID then
                        canBuy = x and self.selectedFarmland.showOnFarmlandsScreen
                    end
                    canSell = false
                    if player == self.playerFarm.farmId then
                        canSell = x and self.selectedFarmland.showOnFarmlandsScreen
                    end
                end
                canVisit = true
                canSetMarker = x.currentMapTargetHotspot ~= hotspot
                removeMarker = x.currentMapTargetHotspot == hotspot
            end
        else
            farmId = player:getOwnerFarmId()
            name = player:getName()
            imageFilename = player:getImageFilename()
            uvs = Overlay.DEFAULT_UVS
            self.currentHotspot = hotspot
            if x.tourIconsBase == nil or not x.tourIconsBase.visible then
                canEnter = false
                if player.getIsEnterableFromMenu ~= nil then
                    canEnter = player:getIsEnterableFromMenu()
                end
                if not self.isResetPending and (player:getCanBeReset() and hotspot:getCategory() ~= MapHotspot.CATEGORY_AI) then
                    canReset = true
                end
            end
            isVehicle = true
            if player.spec_rideable == nil then
                self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].text = "button_enterVehicle"
            else
                self.contextActions[InGameMenuMapFrame.ACTIONS.ENTER_VEHICLE].text = "action_rideAnimal"
            end
            if x:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) and (farmId == self.playerFarm.farmId and player:getCanBeSold()) then
                canSellVehicle = player.propertyState ~= VehiclePropertyState.MISSION
                if player.propertyState == VehiclePropertyState.LEASED then
                    self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].text = "button_return"
                else
                    self.contextActions[InGameMenuMapFrame.ACTIONS.SELL_VEHICLE].text = "button_sell"
                end
            end
            if player.getJob ~= nil then
                local player = player:getJob()
                if player ~= nil then
                    if player.getTarget ~= nil and player:getShowTarget() then
                        local x, z, rot = player:getTarget()
                        self.aiTargetMapHotspot:setWorldPosition(x, z)
                        if rot ~= nil then
                            self.aiTargetMapHotspot:setWorldRotation(rot + 3.141592653589793)
                        end
                        x:addMapHotspot(self.aiTargetMapHotspot)
                    end
                    if player.unloadingStationParameter ~= nil then
                        local x = player.unloadingStationParameter:getUnloadingStation()
                        if x ~= nil then
                            local z = x.owningPlaceable
                            if z ~= nil and z.getHotspot ~= nil then
                                local x, z = z:getHotspot(1):getWorldPosition()
                                self.aiUnloadingMarkerHotspot:setWorldPosition(x, z)
                                if not self.isLoadingStationParameterClick then
                                    self.ingameMap:panToHotspot(self.aiUnloadingMarkerHotspot)
                                end
                                x:addMapHotspot(self.aiUnloadingMarkerHotspot)
                            end
                        end
                    end
                    if player.loadingStationParameter ~= nil then
                        local x = player.loadingStationParameter:getLoadingStation()
                        if x ~= nil then
                            local z = x.owningPlaceable
                            if z ~= nil and z.getHotspot ~= nil then
                                local x, z = z:getHotspot(1):getWorldPosition()
                                self.aiLoadingMarkerHotspot:setWorldPosition(x, z)
                                if not self.isLoadAndDeliverParameter then
                                    self.ingameMap:panToHotspot(self.aiLoadingMarkerHotspot)
                                end
                                x:addMapHotspot(self.aiLoadingMarkerHotspot)
                            end
                        end
                    end
                end
            end
        end
    end
    local x = x.paused
    if not x then
        x = true
        if self.mode ~= InGameMenuMapFrame.AI_MODE_WORKER_LIST then
            x = g_guidedTourManager:getIsTourRunning()
        end
    end
    local player = not x
    self:setMapInputContext(canEnter and player, canReset and player, canSellVehicle and player, canVisit and player, canSetMarker, removeMarker, canBuy and player, canSell and player, canManage and player)
    self:refreshContextInput()
    if showContextBox then
        InGameMenuMapUtil.hideContextBox(self.contextBox)
        InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
        InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
        local x = self.contextBox
        local z = self.contextButtonList
        if isPlayer then
            InGameMenuMapUtil.showPlayerContextBox(self.contextBoxPlayer, playerName, farmId)
        else
            if isFarmland then
                x = self.contextBoxFarmland
                z = self.contextButtonListFarmland
            elseif self.mapOverviewSelector:getState() <= InGameMenuMapFrame.MAP_HOTSPOTS then
                self:setHotspotModeActive(true)
            end
            InGameMenuMapUtil.showContextBox(x, hotspot, name, imageFilename, uvs, farmId, playerName, _, isVehicle, isFarmland)
        end
        self.currentContextBox = x
        if self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW or self.mode == InGameMenuMapFrame.AI_MODE_WORKER_LIST and (self.activeWorkerList:getItemCount() == 0 and not isPlayer) then
            FocusManager:setFocus(z)
        end
    else
        if self.hotspotModeActive then
            self:setHotspotModeActive(false)
        end
        local x = self.mapOverviewSelector:getState()
        local z = not self.currentContextBox:getIsVisible()
        InGameMenuMapUtil.hideContextBox(self.contextBox)
        InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
        InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
        if x == InGameMenuMapFrame.AI_WORKER_LIST then
            self.blockListSelectionUpdates = true
            z = FocusManager:setFocus(self.activeWorkerList)
            if not z then
                z = FocusManager:getFocusedElement() == self.activeWorkerList
            end
            self.blockListSelectionUpdates = false
        elseif InGameMenuMapFrame.MAP_HOTSPOTS < x then
            z = FocusManager:setFocus(self.jobMenuLayout)
            if not z then
                z = FocusManager:getFocusedElement() == self.jobMenuLayout
            end
        end
        if not z then
            FocusManager:setFocus(self.mapOverviewSelector)
        end
    end
    self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
end
function InGameMenuMapFrame:showMapHotspot(hotspot)
    self:onClickHotspot(nil, hotspot)
    self.ingameMap:panToHotspot(hotspot)
end
function InGameMenuMapFrame:setHotspotModeActive(isActive)
    self.hotspotModeActive = isActive
    self.filterList:setHandleFocus(not isActive)
    self.filterList.selectedWithoutFocus = not isActive
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.SWITCH_VEHICLE, isActive)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.SWITCH_VEHICLE_BACK, isActive)
    self:updateInputGlyphs()
    if isActive then
        self.blockHotspotModeUpdate = true
        self.mapOverviewSelector:setState(InGameMenuMapFrame.MAP_HOTSPOTS, true)
        self.blockHotspotModeUpdate = false
    else
        self.filterList:setSelectedIndex(self.filterList.selectedSectionIndex)
        if self.currentHotspot ~= nil and self.mode ~= InGameMenuMapFrame.AI_MODE_CREATE then
            self:setMapSelectionItem(nil)
        end
    end
end
function InGameMenuMapFrame:updateMapSelectionFilterNavigation()
    local targetButtonTop = nil
    local targetButtonBottom = nil
    if self.mapSelectionPreviousItem.visible then
        targetButtonTop = self.mapSelectionPreviousItem
    elseif self.mapSelectionNextItem.visible then
        targetButtonTop = self.mapSelectionNextItem
    end
    if targetButtonBottom == nil then
        if self.mapSelectionEnter.visible then
            targetButtonBottom = self.mapSelectionEnter
        elseif self.mapSelectionReset.visible then
            targetButtonBottom = self.mapSelectionReset
        elseif self.mapSelectionVisit.visible then
            targetButtonBottom = self.mapSelectionVisit
        elseif self.mapSelectionTag.visible then
            targetButtonBottom = self.mapSelectionTag
        end
    end
    local targetButtonTop = Utils.getNoNil(targetButtonTop, self.mapSelectionPreviousItem)
    local targetButtonBottom = Utils.getNoNil(targetButtonBottom, self.mapSelectionEnter)
    for _, elem in pairs(self.mapOverviewFilters) do
        elem.focusChangeData[FocusManager.BOTTOM] = targetButtonTop.focusId
    end
    targetButtonTop.focusChangeData[FocusManager.BOTTOM] = targetButtonBottom.focusId
    targetButtonBottom.focusChangeData[FocusManager.TOP] = targetButtonTop.focusId
end
function InGameMenuMapFrame:setColorBlindMode(isActive)
    if isActive ~= self.isColorBlindMode then
        self.isColorBlindMode = isActive
        self.filterList:reloadData()
        self:generateOverviewOverlay()
    end
end
function InGameMenuMapFrame:showActionMessage(locaKey)
    if locaKey == nil then
        self.actionMessage:setVisible(false)
    else
        self.actionMessage:setVisible(true)
        self.actionMessage:setLocaKey(locaKey)
    end
end
function InGameMenuMapFrame:generateJobTypes()
    for _, jobType in pairs(AIJobType) do
        self.jobTypeInstances[jobType] = g_currentMission.aiJobTypeManager:createJob(jobType)
    end
end
function InGameMenuMapFrame:startGoToJob(vehicle, destX, destZ, angle)
    local job = self.jobTypeInstances[AIJobType.GOTO]
    job.vehicleParameter:setVehicle(vehicle)
    job.positionAngleParameter:setPosition(destX, destZ)
    job.positionAngleParameter:setAngle(angle)
    job:setValues()
    local success, errorMessage = job:validate(g_localPlayer.farmId)
    if success then
        self:tryStartJob(job, g_localPlayer.farmId, function(state)
            -- upvalues: (copy) self
            if state == AIJob.START_SUCCESS then
                self.jobTypeInstances[AIJobType.GOTO] = g_currentMission.aiJobTypeManager:createJob(AIJobType.GOTO)
                self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
                self:refreshContextInput()
            end
        end)
        return true
    else
        InfoDialog.show(tostring(errorMessage), nil, nil, DialogElement.TYPE_WARNING)
        return false
    end
end
function InGameMenuMapFrame:startJob()
    if self.startJobPending then
        return
    else
        self.currentJob:setValues()
        local success, errorMessage = self.currentJob:validate(g_localPlayer.farmId)
        if success then
            self:tryStartJob(self.currentJob, g_localPlayer.farmId, function(state)
                -- upvalues: (copy) self
                if state == AIJob.START_SUCCESS then
                    self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
                    self.currentJob = nil
                    self:setJobMenuVisible(false)
                    self:refreshContextInput()
                end
            end)
        else
            InfoDialog.show(tostring(errorMessage), nil, nil, DialogElement.TYPE_WARNING)
            self:updateWarnings()
        end
    end
end
function InGameMenuMapFrame:cancelJob()
    local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
    if vehicle ~= nil and vehicle:getIsAIActive() then
        vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
        g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
    end
end
function InGameMenuMapFrame:setActiveJobTypeSelection(jobTypeIndex)
    if self.currentJob == nil or jobTypeIndex ~= self.currentJob.jobTypeIndex then
        local i = #self.jobMenuLayout.elements
        local farmId = -1
        for i = i, 1, farmId do
            self.jobMenuLayout.elements[i]:delete()
        end
        self.currentJob = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)
        local farmId = 1
        if g_localPlayer ~= nil then
            farmId = g_localPlayer.farmId
        end
        self.currentJob:applyCurrentState(self.currentJobVehicle, mission, farmId, false)
        self.currentJobElements = {}
        for _, group in ipairs(self.currentJob:getGroupedParameters()) do
            self.createTitleTemplate:clone(self.jobMenuLayout):setText(group:getTitle())
            local invalidElement = nil
            for index, item in ipairs(group:getParameters()) do
                local element = nil
                local parameterType = item:getType()
                if parameterType == AIParameterType.TEXT then
                    element = self.createTextTemplate:clone(self.jobMenuLayout)
                elseif parameterType == AIParameterType.POSITION then
                    element = self.createPositionTemplate:clone(self.jobMenuLayout)
                    element:updateAbsolutePosition()
                elseif parameterType == AIParameterType.POSITION_ANGLE then
                    element = self.createPositionRotationTemplate:clone(self.jobMenuLayout)
                    element:updateAbsolutePosition()
                elseif parameterType == AIParameterType.SELECTOR or (parameterType == AIParameterType.UNLOADING_STATION or (parameterType == AIParameterType.LOADING_STATION or parameterType == AIParameterType.FILLTYPE)) then
                    element = self.createMultiOptionTemplate:clone(self.jobMenuLayout)
                    element:setDataSource(item)
                    if index == 1 then
                        invalidElement = element:getDescendantByName("invalid")
                    else
                        element:getDescendantByName("invalid"):setPosition(invalidElement.absPosition[1], invalidElement.absPosition[2])
                    end
                end
                element.aiParameter = item
                element:setDisabled(not item:getCanBeChanged())
                table.insert(self.currentJobElements, element)
            end
        end
        self:updateParameterValueTexts()
        self:validateParameters()
        self.jobMenuLayout:invalidateLayout()
        FocusManager:setFocus(self.jobTypeElement)
    end
    self:refreshContextInput()
end
function InGameMenuMapFrame:onMoneyChange()
    if g_localPlayer ~= nil then
        local farm = g_farmManager:getFarmById(g_localPlayer.farmId)
        if farm.money <= -1 then
            self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY_NEGATIVE, nil, true)
        else
            self.currentBalanceText:applyProfile(ShopMenu.GUI_PROFILE.SHOP_MONEY, nil, true)
        end
        local moneyText = g_i18n:formatMoney(farm.money, 0, true, false)
        self.currentBalanceText:setText(moneyText)
        if self.shopMoneyBox ~= nil then
            self.shopMoneyBox:invalidateLayout()
            self.shopMoneyBoxBg:setSize(self.shopMoneyBox.flowSizes[1] + 60 * g_pixelSizeScaledX)
        end
    end
end
function InGameMenuMapFrame:onAIVehicleStateChanged(_, vehicle)
    if vehicle ~= nil and (self.currentHotspot ~= nil and InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot) == vehicle) then
        self:refreshContextInput()
    end
end
function InGameMenuMapFrame:onVehicleEntered(vehicle, player)
    if self.currentHotspot == nil then
        return
    else
        local playerHotspot = false
        if player ~= nil then
            playerHotspot = player.playerHotspot
        end
        local vehicleHotspot = false
        if vehicle ~= nil then
            vehicleHotspot = vehicle.mapHotspot
        end
        if self.currentHotspot == playerHotspot then
            self:setMapSelectionItem(playerHotspot)
        elseif self.currentHotspot == vehicleHotspot then
            self:setMapSelectionItem(playerHotspot)
        end
    end
end
function InGameMenuMapFrame:onVehicleLeft(_, player)
    if self.currentHotspot ~= nil then
        local playerHotspot = false
        if player ~= nil then
            playerHotspot = player.playerHotspot
        end
        if self.currentHotspot == playerHotspot then
            self:setMapSelectionItem(playerHotspot)
        end
    end
end
function InGameMenuMapFrame:onAITaskSkipped()
    self:refreshContextInput()
end
function InGameMenuMapFrame:onDrawPostIngameMap(_, _)
    if not self.hideContentOverlay then
        local width, height = self.ingameMapBase.fullScreenLayout:getMapSize()
        local x, y = self.ingameMapBase.fullScreenLayout:getMapPosition()
        if self.foliageStateOverlay ~= nil and (self.foliageStateOverlay ~= 0 and self.foliageStateOverlayIsReady) then
            renderOverlay(self.foliageStateOverlay, x + width * 0.25, y + height * 0.25, width * 0.5, height * 0.5)
        end
        if self.farmlandStateOverlay ~= nil and (self.farmlandStateOverlay ~= 0 and self.farmlandStateOverlayIsReady) then
            renderOverlay(self.farmlandStateOverlay, overlayX, overlayY, width * 0.5, height * 0.5)
        end
    end
end
function InGameMenuMapFrame:onClickMapOverviewSelector(state)
    self:generateOverviewOverlay()
    if self.previousSubCategoryState <= InGameMenuMapFrame.MAP_HOTSPOTS then
        if self.hotspotModeActive and not self.blockHotspotModeUpdate then
            self:setHotspotModeActive(false)
        end
    elseif self.previousSubCategoryState == InGameMenuMapFrame.MAP_FARMLANDS then
        self.filterList:setHandleFocus(true)
        self.filterList.showHighlights = true
        self.filterList.selectedWithoutFocus = true
    end
    if state <= InGameMenuMapFrame.MAP_HOTSPOTS then
        self.filterList:reloadData()
    end
    if self.numSelectedFilters[state] == 0 then
        self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
    else
        self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
    end
    local farms = self.buttonDeselectAllContainer
    farms:setVisible(state <= InGameMenuMapFrame.MAP_HOTSPOTS)
    local farms = self.filterListContainer
    farms:setVisible(state <= InGameMenuMapFrame.MAP_FARMLANDS)
    local farms = self.createJobEmptyText
    farms:setVisible(state == InGameMenuMapFrame.AI_CREATE_JOB)
    local farms = self.workerListContainer
    farms:setVisible(state == InGameMenuMapFrame.AI_WORKER_LIST)
    if self:getIsPicking() then
        self:executePickingCallback(false)
        self:refreshContextInput()
    end
    if state ~= InGameMenuMapFrame.AI_CREATE_JOB and not self.hotspotModeActive then
        self:setMapSelectionItem(nil)
    end
    for _, hotspot in pairs(self.ingameMap.ingameMap.hotspots) do
        if hotspot:isa(VehicleHotspot) or hotspot:isa(AIHotspot) then
            if state == InGameMenuMapFrame.AI_CREATE_JOB then
                hotspot.oldVisibility = hotspot:getIsVisible()
                local vehicle = hotspot:getVehicle()
                hotspot:setVisible(hotspot.getVehicle ~= nil and (vehicle.spec_aiJobVehicle ~= nil and vehicle.spec_aiJobVehicle.supportsAIJobs) and vehicle:getJob() ~= nil == hotspot:isa(AIHotspot))
            elseif self.previousSubCategoryState == InGameMenuMapFrame.AI_CREATE_JOB then
                hotspot:setVisible(hotspot.oldVisibility)
            end
        end
    end
    if state == InGameMenuMapFrame.MAP_FARMLANDS then
        self.farmlandItems = {}
        local farms = g_farmManager:getFarms()
        local localPlayerFarm = g_farmManager:getFarmByUserId(g_localPlayer.userId)
        local hotspot = {
            ["name"] = g_i18n:getText("ui_farmlandUnowned"),
            ["color"] = MapOverlayGenerator.COLOR.FIELD_UNOWNED
        }
        table.insert(self.farmlandItems, hotspot)
        local hotspot = {
            ["name"] = g_i18n:getText("ui_farmlandsCurrentlySelected"),
            ["color"] = MapOverlayGenerator.COLOR.FIELD_SELECTED
        }
        table.insert(self.farmlandItems, hotspot)
        local hotspot = {
            ["name"] = localPlayerFarm.name,
            ["color"] = localPlayerFarm:getColor()
        }
        table.insert(self.farmlandItems, hotspot)
        for vehicle, farm in pairs(farms) do
            if farm ~= localPlayerFarm and farm.showInFarmScreen then
                table.insert(self.farmlandItems, {
                    ["name"] = farm.name,
                    ["color"] = farm:getColor()
                })
            end
        end
        self.filterList:reloadData()
        self.filterList:setHandleFocus(false)
        self.filterList.showHighlights = false
        self.filterList.selectedWithoutFocus = false
        self.filterList:setSelectedIndex(1)
        self.needsOverlayUpdate = true
        self.isShowingFarmlandsOverlay = true
    elseif self.isShowingFarmlandsOverlay then
        self.needsOverlayUpdate = true
        self.isShowingFarmlandsOverlay = false
    end
    self.previousSubCategoryState = state
end
function InGameMenuMapFrame:onClickHotspot(_, hotspot)
    if self.isPickingLocation then
        self:executePickingCallback(true, hotspot.worldX, hotspot.worldZ)
    elseif self.isPickingRotation then
        self:executePickingCallback(true, (math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])))
    elseif self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW and (self.currentHotspot ~= hotspot and hotspot ~= self.anywhereHotspot) then
        self:setMapSelectionItem(hotspot)
    end
    self:refreshContextInput()
end
function InGameMenuMapFrame:onClickMap(_, worldX, worldZ)
    if self.isPickingLocation then
        self:executePickingCallback(true, worldX, worldZ)
        return
    elseif self.isPickingRotation then
        self:executePickingCallback(true, (math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])))
    elseif self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
        local angle = g_farmlandManager:getFarmlandAtWorldPosition(worldX, worldZ)
        if angle ~= nil and angle.showOnFarmlandsScreen then
            self:setMapSelectionItem(angle ~= nil and angle:getMapHotspot() or nil)
            return
        end
    elseif self.mode == InGameMenuMapFrame.AI_MODE_OVERVIEW or self.mode == InGameMenuMapFrame.AI_MODE_WORKER_LIST then
        self:setMapSelectionItem(nil)
    end
end
function InGameMenuMapFrame:onVehiclesChanged(_, _, _)
    self:selectFirstHotspot()
end
function InGameMenuMapFrame:onPauseChanged(_)
    self:setMapSelectionItem(self.currentHotspot)
end
function InGameMenuMapFrame:selectFirstHotspot()
    self:setMapSelectionItem((self.ingameMapBase:cycleVisibleHotspot(nil, InGameMenuMapFrame.HOTSPOT_SWITCH_CATEGORIES, 1)))
end
function InGameMenuMapFrame:onVehicleReset(state)
    self.isResetPending = false
    g_messageCenter:unsubscribe(ResetVehicleEvent, self)
    if state == ResetVehicleEvent.STATE_SUCCESS then
        InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_DONE), nil, nil, DialogElement.TYPE_INFO)
        self:selectFirstHotspot()
        return
    elseif state == ResetVehicleEvent.STATE_FAILED then
        InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_FAILED))
        return
    elseif state == ResetVehicleEvent.STATE_IN_USE then
        InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_IN_USE))
    else
        InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_NO_PERMISSION))
    end
end
function InGameMenuMapFrame:onClickResetVehicle()
    local mission = g_currentMission
    if not self.isResetPending and (mission.tourIconsBase == nil or not mission.tourIconsBase.visible) and self.currentHotspot ~= nil then
        YesNoDialog.show(self.onYesNoReset, self, g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_CONFIRM), g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.VEHICLE_RESET))
    end
    return true
end
function InGameMenuMapFrame:onClickVisitPlace()
    if self.currentHotspot ~= nil then
        if self.currentHotspot:isa(NPCHotspot) then
            local npc = self.currentHotspot:getNPC()
            if npc ~= nil then
                self.onClickBackCallback()
                if g_localPlayer:getCurrentVehicle() ~= nil then
                    g_localPlayer:leaveVehicle()
                end
                g_localPlayer:teleportToNPC(npc)
            end
        else
            local npc, z, y
            if self.currentHotspot:isa(FarmlandHotspot) then
                npc, z = self.currentHotspot:getWorldPosition()
                y = getTerrainHeightAtWorldPos(g_terrainNode, npc, 0, z)
            else
                npc, y, z = self.currentHotspot:getTeleportWorldPosition()
            end
            if npc ~= nil and (y ~= nil and z ~= nil) then
                self.onClickBackCallback()
                if g_localPlayer:getCurrentVehicle() ~= nil then
                    g_localPlayer:leaveVehicle()
                end
                g_localPlayer:teleportTo(npc, y, z)
            end
        end
    end
    return true
end
function InGameMenuMapFrame:onClickTagPlace()
    if self.currentHotspot ~= nil and (self.currentHotspot.worldX ~= nil and self.currentHotspot.worldZ ~= nil) then
        local mission = g_currentMission
        if mission.currentMapTargetHotspot == self.currentHotspot then
            self.contextActions[InGameMenuMapFrame.ACTIONS.SET_MARKER].isActive = true
            self.contextActions[InGameMenuMapFrame.ACTIONS.REMOVE_MARKER].isActive = false
            mission:setMapTargetHotspot(nil)
        else
            self.contextActions[InGameMenuMapFrame.ACTIONS.SET_MARKER].isActive = false
            self.contextActions[InGameMenuMapFrame.ACTIONS.REMOVE_MARKER].isActive = true
            mission:setMapTargetHotspot(self.currentHotspot)
        end
        self:refreshContextInput()
    end
    return true
end
function InGameMenuMapFrame:onClickManage()
    if self.currentHotspot ~= nil then
        local placeable = self.currentHotspot:getPlaceable()
        local productionPoint = nil
        if placeable ~= nil and placeable.spec_productionPoint ~= nil then
            productionPoint = placeable.spec_productionPoint.productionPoint
        end
        g_inGameMenu:openProductionScreen(productionPoint)
    end
end
function InGameMenuMapFrame:onClickEnterVehicle()
    if not g_currentMission.isPlayerFrozen then
        local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot) or InGameMenuMapUtil.getHotspotVehicle(self.currentVehicleHotspot)
        if vehicle ~= nil and (vehicle.getIsEnterableFromMenu ~= nil and vehicle:getIsEnterableFromMenu()) then
            self.onClickBackCallback()
            g_localPlayer:requestToEnterVehicle(vehicle)
        end
    end
    return true
end
function InGameMenuMapFrame:onClickSellVehicle()
    if not g_currentMission.isPlayerFrozen then
        local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot) or InGameMenuMapUtil.getHotspotVehicle(self.currentVehicleHotspot)
        local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        g_shopController:sell(storeItem, vehicle)
        self:setMapSelectionItem(nil)
    end
    return true
end
function InGameMenuMapFrame:onClickBuy()
    if self.selectedFarmland == nil then
        local text = self.currentHotspot:getPlaceable()
        if text ~= nil then
            if text.spec_productionPoint == nil then
                if text.spec_factory ~= nil then
                    text:buyRequest(self.onYesNoBuyOrSellPlaceable, self)
                end
            else
                text.spec_productionPoint.productionPoint:buyRequest(self.onYesNoBuyOrSellPlaceable, self)
            end
        end
    else
        if g_missionManager:getIsMissionRunningOnFarmland(self.selectedFarmland) then
            InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_ACTIVE_MISSION))
            return false
        end
        if self.playerFarm:getBalance() >= self.selectedFarmland.price then
            local text = string.format(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND), g_i18n:formatMoney(self.selectedFarmland.price, 0, true, true))
            local title = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_TITLE)
            YesNoDialog.show(self.onYesNoBuyFarmland, self, text, title)
        else
            InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY), nil, nil, DialogElement.TYPE_WARNING)
        end
    end
    return true
end
function InGameMenuMapFrame:onClickSell()
    if self.selectedFarmland == nil then
        local mission = self.currentHotspot:getPlaceable()
        local price, text = mission:getSellPrice()
        local title = string.format(g_i18n:getText("ui_constructionSellConfirmation"), mission:getName(), g_i18n:formatMoney(price, 0, true, true))
        YesNoDialog.show(function(yes)
            -- upvalues: (copy) mission, (copy) text, (copy) self
            if yes then
                g_client:getServerConnection():sendEvent(SellPlaceableEvent.new(mission, nil, text))
            end
            self:onYesNoBuyOrSellPlaceable(yes)
        end, nil, title)
        self:setMapSelectionItem(nil)
    elseif g_currentMission.placeableSystem:getArePlaceablesOnFarmland(g_localPlayer.farmId, self.selectedFarmland.id) then
        InfoDialog.show(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_CANNOT_SELL_WTIH_PLACEABLES))
    else
        local text = string.format(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_SELL_FARMLAND), g_i18n:formatMoney(self.selectedFarmland.price, 0, true, true))
        local title = g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_SELL_FARMLAND_TITLE)
        YesNoDialog.show(self.onYesNoSellFarmland, self, text, title)
    end
    return true
end
function InGameMenuMapFrame:onClickBack()
    if self:getCanGoBack() then
        self:onClickBackCallback()
    elseif self:getIsPicking() then
        self:executePickingCallback(false)
        self:refreshContextInput()
        self.ingameMap.isTouchPickingRotation = false
        if self.buttonConfirmAITarget ~= nil then
            self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmPosition"))
        end
    elseif self.mode == InGameMenuMapFrame.AI_MODE_CREATE then
        self.currentJob:resetTasks()
        self.currentJobVehicle = nil
        self.mode = InGameMenuMapFrame.AI_MODE_OVERVIEW
        self:setJobMenuVisible(false)
        self:refreshContextInput()
        FocusManager:setFocus(self.contextButtonList)
    elseif self.hotspotModeActive then
        self:setHotspotModeActive(false)
    elseif self.mapOverviewSelector:getState() == InGameMenuMapFrame.AI_WORKER_LIST and self.currentHotspot ~= nil then
        self:setMapSelectionItem(nil)
    elseif self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS and self.selectedFarmland ~= nil then
        self:setMapSelectionItem(nil)
    end
    return true
end
function InGameMenuMapFrame:onStartGoToJob()
    if not g_currentMission.paused and self:getCanGoTo() then
        self:tryStartGoToJob()
    end
    return true
end
function InGameMenuMapFrame:onStartCancelJob()
    if not g_currentMission.paused then
        if self:getCanCancelJob() then
            self:cancelJob()
        elseif self:getCanStartJob() then
            self:startJob()
        end
    end
    return true
end
function InGameMenuMapFrame:onSkipJobTask()
    if not g_currentMission.paused and self:getCanSkipJobTask() then
        self:skipCurrentTask()
    end
    return true
end
function InGameMenuMapFrame:onPageNext()
    g_inGameMenu:onPageNext()
end
function InGameMenuMapFrame:onPagePrevious()
    g_inGameMenu:onPagePrevious()
end
function InGameMenuMapFrame:onClickDeselectAll(exceptionSection, exceptionIndex)
    if self.hotspotModeActive then
        self:setHotspotModeActive(false)
    end
    local overviewIndex = self.mapOverviewSelector:getState()
    local selectAll = self.numSelectedFilters[overviewIndex] == 0
    if selectAll then
        self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
        self.numSelectedFilters[overviewIndex] = #self.displayCropTypes
    else
        self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
        self.numSelectedFilters[overviewIndex] = 0
    end
    if overviewIndex == InGameMenuMapFrame.MAP_HOTSPOTS then
        for index, filter in pairs(self.dataTables[overviewIndex][1]) do
            if exceptionSection == 1 and exceptionIndex == index then
                self.filterStates[overviewIndex][1][index] = not selectAll
                self.numSelectedFilters[overviewIndex] = 1
                self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
                self.ingameMapBase:setDefaultFilterValue(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[1][index].id, not selectAll)
            else
                currentFilterState[index] = selectAll
                self.ingameMapBase:setDefaultFilterValue(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[1][index].id, selectAll)
            end
        end
        for index, filter in pairs(self.dataTables[overviewIndex][2]) do
            if exceptionSection == 2 and exceptionIndex == index then
                self.filterStates[overviewIndex][2][index] = not selectAll
                self.numSelectedFilters[overviewIndex] = 1
                self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
                self.ingameMapBase:setDefaultFilterValue(InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[2][index].id, not selectAll)
                if hotspotCategory == MapHotspot.CATEGORY_OTHER then
                    self.ingameMapBase:setDefaultFilterValue(MapHotspot.CATEGORY_SHOP, not selectAll)
                end
            else
                currentFilterState[index] = selectAll
                self.ingameMapBase:setDefaultFilterValue(hotspotCategory, selectAll)
                if hotspotCategory == MapHotspot.CATEGORY_OTHER then
                    self.ingameMapBase:setDefaultFilterValue(MapHotspot.CATEGORY_SHOP, selectAll)
                end
            end
        end
    else
        for index, filter in pairs(self.dataTables[overviewIndex]) do
            local hotspotCategory
            if filter.soilStateIndex == nil then
                hotspotCategory = index
            else
                hotspotCategory = filter.soilStateIndex
            end
            if overviewIndex == InGameMenuMapFrame.MAP_FRUIT_TYPE then
                hotspotCategory = self.displayCropTypes[index].fruitTypeIndex
            end
            if exceptionIndex == index then
                self.filterStates[overviewIndex][hotspotCategory] = not selectAll
                self.numSelectedFilters[overviewIndex] = 1
                self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
            else
                currentFilterState[hotspotCategory] = selectAll
            end
        end
    end
    self:generateOverviewOverlay()
    self:saveFilters()
end
function InGameMenuMapFrame:onYesNoReset(yes)
    if yes then
        if self.currentHotspot ~= nil then
            local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
            if vehicle ~= nil then
                self:setMapSelectionItem(nil)
                g_messageCenter:subscribe(ResetVehicleEvent, self.onVehicleReset, self)
                self.isResetPending = true
                g_client:getServerConnection():sendEvent(ResetVehicleEvent.new(vehicle))
                return
            end
        end
    else
        self.elementToFocus = self.contextButtonList
    end
end
function InGameMenuMapFrame:onYesNoBuyFarmland(yes)
    if yes then
        local price = self.selectedFarmland.price
        if price <= self.playerFarm:getBalance() then
            self.client:getServerConnection():sendEvent(FarmlandStateEvent.new(self.selectedFarmland.id, g_currentMission:getFarmId(), price))
            self:setMapSelectionItem()
            InGameMenuMapUtil.hideContextBox(self.contextBox)
            InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
            InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
            return
        end
    else
        self.elementToFocus = self.contextButtonListFarmland
    end
end
function InGameMenuMapFrame:onYesNoSellFarmland(yes)
    if yes then
        self.client:getServerConnection():sendEvent(FarmlandStateEvent.new(self.selectedFarmland.id, FarmlandManager.NO_OWNER_FARM_ID, self.selectedFarmland.price))
        self:setMapSelectionItem(nil)
        InGameMenuMapUtil.hideContextBox(self.contextBox)
        InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
        InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
    else
        self.elementToFocus = self.contextButtonListFarmland
    end
end
function InGameMenuMapFrame:onYesNoBuyOrSellPlaceable(yes)
    if yes then
        self:setMapSelectionItem(self.currentHotspot)
    end
    if self.currentHotspot == nil then
        self.elementToFocus = self.filterList
    else
        self.elementToFocus = self.contextButtonList
    end
end
function InGameMenuMapFrame:onCreateJob()
    if self:getCanCreateJob() and not g_currentMission.paused then
        self:createJob()
    end
    return true
end
function InGameMenuMapFrame:updateInputGlyphs()
    local isGamepadContext = self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD
    local moveText, moveActions
    if isGamepadContext then
        moveText = self.moveCursorText
        moveActions = { InputAction.AXIS_MAP_SCROLL_LEFT_RIGHT, InputAction.AXIS_MAP_SCROLL_UP_DOWN }
    else
        moveText = self.panMapText
        moveActions = { InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, InputAction.AXIS_LOOK_UPDOWN_DRAG }
    end
    self.mapMoveGlyph:setActions(moveActions, nil, nil, true)
    self.mapZoomGlyph:setActions({ InputAction.AXIS_MAP_ZOOM_OUT, InputAction.AXIS_MAP_ZOOM_IN }, nil, nil, false)
    self.mapMoveGlyphText:setText(moveText)
    self.mapZoomGlyphText:setText(self.zoomText)
    self.switchVehicleGlyph:setVisible(self.hotspotModeActive and isGamepadContext)
    self.switchVehicleGlyphText:setVisible(self.hotspotModeActive and isGamepadContext)
    self.switchVehicleGlyph:setActions({ InputAction.SWITCH_VEHICLE, InputAction.SWITCH_VEHICLE_BACK })
    self.buttonBox:invalidateLayout()
end
function InGameMenuMapFrame:validateParameters()
    local isValid = true
    local errorText = ""
    if self.currentJob ~= nil then
        self.currentJob:setValues()
        isValid, errorText = self.currentJob:validate(g_localPlayer.farmId)
        self:updateWarnings()
    end
    self.errorMessage:setText(errorText)
    self.errorMessage:setVisible(not isValid)
end
function InGameMenuMapFrame:updateWarnings()
    for _, element in ipairs(self.currentJobElements) do
        local invalidElement = element:getDescendantByName("invalid")
        if invalidElement ~= nil then
            invalidElement:setVisible(not element.aiParameter:getIsValid())
        end
    end
end
function InGameMenuMapFrame:addStatusMessage(message)
    table.insert(self.statusMessages, {
        ["removeTime"] = g_time + 5000,
        ["text"] = message
    })
    self:updateStatusMessages()
end
function InGameMenuMapFrame:updateStatusMessages()
    local text = ""
    for _, message in ipairs(self.statusMessages) do

    end
    self.statusMessage:setText(text)
end
function InGameMenuMapFrame:onJobTypeChanged(index)
    self:setActiveJobTypeSelection(self.currentJobTypes[index])
end
function InGameMenuMapFrame:onAIJobStarted(job, farmId)
    if g_localPlayer ~= nil and farmId == g_localPlayer.farmId then
        table.insert(self.playerFarmActiveJobs, job.jobId)
    end
    self.activeWorkerList:reloadData()
    self.createJobEmptyText:setVisible(not self.createJobContainer:getIsVisible() and self.activeWorkerList:getItemCount() == 0)
end
function InGameMenuMapFrame:onAIJobRemoved(jobId)
    table.removeElement(self.playerFarmActiveJobs, jobId)
    self.activeWorkerList:reloadData()
    self.createJobEmptyText:setVisible(self.mapOverviewSelector:getState() == InGameMenuMapFrame.AI_CREATE_JOB and not self.createJobContainer:getIsVisible() and self.activeWorkerList:getItemCount() == 0)
    InGameMenuMapUtil.hideContextBox(self.contextBox)
    InGameMenuMapUtil.hideContextBox(self.contextBoxPlayer)
    InGameMenuMapUtil.hideContextBox(self.contextBoxFarmland)
end
function InGameMenuMapFrame:onAIJobStopped(job, aiMessage)
    if aiMessage ~= nil and (job ~= nil and (g_localPlayer ~= nil and job.startedFarmId == g_localPlayer.farmId)) then
        self:addStatusMessage((aiMessage:getMessage(job)))
    end
end
function InGameMenuMapFrame:updateParameterValueTexts()
    local mission = g_currentMission
    mission:removeMapHotspot(self.aiTargetMapHotspot)
    mission:removeMapHotspot(self.aiLoadingMarkerHotspot)
    mission:removeMapHotspot(self.aiUnloadingMarkerHotspot)
    for _, element in ipairs(self.currentJobElements) do
        local parameter = element.aiParameter
        local parameterType = parameter:getType()
        if parameterType == AIParameterType.TEXT then
            element:getDescendantByName("title"):setText(parameter:getString())
        elseif parameterType == AIParameterType.POSITION or parameterType == AIParameterType.POSITION_ANGLE then
            element:setText(parameter:getString())
            mission:addMapHotspot(self.aiTargetMapHotspot)
            local title, z = parameter:getPosition()
            self.aiTargetMapHotspot:setWorldPosition(title, z)
            if parameterType == AIParameterType.POSITION_ANGLE then
                local angle = parameter:getAngle() + 3.141592653589793
                self.aiTargetMapHotspot:setWorldRotation(angle)
            end
        else
            element:updateTitle()
            if parameterType == AIParameterType.UNLOADING_STATION then
                local title = parameter:getUnloadingStation()
                if title ~= nil then
                    local z = title.owningPlaceable
                    if z ~= nil and z.getHotspot ~= nil then
                        local angle = z:getHotspot(1)
                        if angle ~= nil then
                            local x, z = angle:getWorldPosition()
                            self.aiUnloadingMarkerHotspot:setWorldPosition(x, z)
                            if not self.isLoadAndDeliverParameter then
                                self.ingameMap:panToHotspot(self.aiUnloadingMarkerHotspot)
                            end
                            mission:addMapHotspot(self.aiUnloadingMarkerHotspot)
                        end
                    end
                end
            elseif parameterType == AIParameterType.LOADING_STATION then
                local title = parameter:getLoadingStation()
                if title ~= nil then
                    local z = title.owningPlaceable
                    if z ~= nil and z.getHotspot ~= nil then
                        local angle = z:getHotspot(1)
                        if angle ~= nil then
                            local x, z = angle:getWorldPosition()
                            self.aiLoadingMarkerHotspot:setWorldPosition(x, z)
                            if self.isLoadingStationParameterClick then
                                self.ingameMap:panToHotspot(self.aiLoadingMarkerHotspot)
                            end
                            mission:addMapHotspot(self.aiLoadingMarkerHotspot)
                        end
                    end
                end
            end
        end
    end
end
function InGameMenuMapFrame:onClickMultiTextOptionParameter(_, element)
    if self.currentJob ~= nil then
        local parameter = element.aiParameter
        self.currentJob:onParameterValueChanged(parameter)
        self.isLoadingStationParameterClick = parameter:getType() == AIParameterType.LOADING_STATION
        self:updateParameterValueTexts()
    end
    self:validateParameters()
end
function InGameMenuMapFrame:onClickPositionParameter(element)
    local parameter = element.aiParameter
    self:startPickPosition(parameter, function(success, _, _)
        -- upvalues: (copy) element, (copy) parameter
        if success then
            element:setText(parameter:getString())
        end
    end)
end
function InGameMenuMapFrame:onClickPositionRotationParameter(element)
    local parameter = element.aiParameter
    self:startPickPositionAndRotation(parameter, function(success, _, _, _)
        -- upvalues: (copy) element, (copy) parameter
        if success then
            element:setText(parameter:getString())
        end
    end)
end
function InGameMenuMapFrame:getNumberOfSections(list)
    return list == self.filterList and self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_HOTSPOTS and 2 or 1
end
function InGameMenuMapFrame:getTitleForSectionHeader(list, section)
    return (list ~= self.filterList or self.mapOverviewSelector:getState() ~= InGameMenuMapFrame.MAP_HOTSPOTS) and "" or (section == 1 and g_i18n:getText("ui_mapHotspotFilter_vehicles") or g_i18n:getText("construction_category_buildings"))
end
function InGameMenuMapFrame:getNumberOfItemsInSection(list, section)
    if list ~= self.filterList then
        if list ~= self.contextButtonList and list ~= self.contextButtonListFarmland then
            return list == self.activeWorkerList and g_currentMission ~= nil and #self.playerFarmActiveJobs or 0
        end
        if self.mode == InGameMenuMapFrame.AI_MODE_CREATE then
            return 0
        end
        self.contextActionMapping = {}
        for index, action in ipairs(self.contextActions) do
            if action.isActive then
                table.insert(self.contextActionMapping, index)
            end
        end
        return #self.contextActionMapping
    end
    if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_FARMLANDS then
        return #self.farmlandItems
    end
    if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_HOTSPOTS then
        return #InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES[section]
    end
    local state = self.mapOverviewSelector:getState()
    local data = self.dataTables[state]
    if data ~= nil then
        return #data
    end
    Logging.devError("No data found for map overlay selector state \'%s\'", state)
    if g_showDevelopmentWarnings then
        printCallstack()
    end
    return 0
end
function InGameMenuMapFrame:populateCellForItemInSection(list, section, index, cell)
    if list == self.filterList then
        local overviewIndex = self.mapOverviewSelector:getState()
        if overviewIndex == InGameMenuMapFrame.MAP_FARMLANDS then
            cell:getAttribute("icon"):setVisible(false)
            local iconBg = cell:getAttribute("iconBg")
            local farmlandsFarm = self.farmlandItems[index]
            function iconBg.getIsSelected()
                return true
            end
            self:assignItemColors(iconBg, { farmlandsFarm.color })
            cell:getAttribute("name"):setText(farmlandsFarm.name)
        else
            if overviewIndex == InGameMenuMapFrame.MAP_SOIL then
                iconBg = self.displaySoilStateMapping[index].soilStateIndex
            end
            local iconBg
            local function farmlandsFarm()
                -- upvalues: (copy) self, (copy) overviewIndex, (ref) iconBg
                return self.filterStates[overviewIndex][iconBg]
            end
            local farmlandsFarm = overviewIndex == InGameMenuMapFrame.MAP_HOTSPOTS and function()
                -- upvalues: (copy) self, (copy) overviewIndex, (copy) section, (ref) iconBg
                return self.filterStates[overviewIndex][section][iconBg]
            end or (overviewIndex == InGameMenuMapFrame.MAP_FRUIT_TYPE and function()
                -- upvalues: (copy) self, (ref) iconBg, (copy) overviewIndex
                return self.filterStates[overviewIndex][self.displayCropTypes[iconBg].fruitTypeIndex]
            end or farmlandsFarm)
            local icon = cell:getAttribute("icon")
            icon:setVisible(true)
            icon.getIsSelected = farmlandsFarm
            local iconBg = cell:getAttribute("iconBg")
            iconBg.getIsSelected = farmlandsFarm
            local status = self.dataTables[overviewIndex][index]
            if self.mapOverviewSelector:getState() == InGameMenuMapFrame.MAP_HOTSPOTS then
                status = self.dataTables[overviewIndex][section][index]
            end
            if overviewIndex == InGameMenuMapFrame.MAP_HOTSPOTS then
                cell:getAttribute("name"):setText(g_i18n:getText(status.name))
                icon:setImageSlice(nil, status.sliceId)
                self:assignItemColors(iconBg, status.color)
            else
                cell:getAttribute("name"):setText(status.description)
                if overviewIndex == InGameMenuMapFrame.MAP_FRUIT_TYPE then
                    self:assignItemColors(iconBg, {
                        {
                            status.colors[self.isColorBlindMode].r,
                            status.colors[self.isColorBlindMode].g,
                            status.colors[self.isColorBlindMode].b,
                            status.colors[self.isColorBlindMode].a
                        }
                    })
                    icon:setImageFilename(status.iconFilename)
                    icon:setImageUVs(nil, unpack(Overlay.DEFAULT_UVS))
                else
                    self:assignItemColors(iconBg, statusColor, cell:getAttribute("colorTemplate"), farmlandsFarm)
                    icon:setVisible(false)
                end
            end
        end
    end
    if list == self.contextButtonList or list == self.contextButtonListFarmland then
        local overviewIndex = self.contextActions[self.contextActionMapping[index]]
        cell:getAttribute("text"):setText(overviewIndex.title or g_i18n:getText(overviewIndex.text))
        cell.onClickCallback = overviewIndex.callback
        if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
            cell:getAttribute("button"):applyProfile(InGameMenuMapFrame.PROFILE.CONTEXT_BUTTON_GAMEPAD)
        else
            cell:getAttribute("button"):applyProfile(InGameMenuMapFrame.PROFILE.CONTEXT_BUTTON)
        end
    end
    if list == self.activeWorkerList then
        local overviewIndex = 0
        local iconBg = nil
        local farmlandsFarm = 1
        if g_localPlayer ~= nil then
            farmlandsFarm = g_localPlayer.farmId
        end
        for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
            if job.startedFarmId == farmlandsFarm then
                overviewIndex = overviewIndex + 1
                if overviewIndex == index then
                    iconBg = job
                    break
                end
            end
        end
        if iconBg ~= nil then
            cell:getAttribute("text"):setText(iconBg:getDescription())
            cell:getAttribute("title"):setText(iconBg:getTitle())
            cell:getAttribute("helper"):setText(iconBg:getHelperName())
        end
    end
end
function InGameMenuMapFrame.assignItemColors(_, colorElement, stateColors, colorTemplate, selectedFunc)
    local i = #colorElement.elements
    local partWidth = 1
    for i = i, partWidth, -1 do
        colorElement.elements[i]:delete()
    end
    local partWidth = colorElement.size[1] / #stateColors
    local i = GuiOverlay.STATE_SELECTED
    colorElement:setImageColor(i, unpack(stateColors[1]))
    if #stateColors > 1 then
        local i = 2
        local i = 1
        for i = i, #stateColors, i do
            local newPart = colorTemplate:clone(colorElement)
            newPart:setSize(partWidth, nil)
            newPart:setPosition((i - 1) * partWidth, 0)
            newPart:setImageColor(GuiOverlay.STATE_SELECTED, unpack(stateColors[i]))
            newPart.getIsSelected = selectedFunc
        end
    end
end
function InGameMenuMapFrame:getHasChangeableFilterList()
    return self.mapOverviewSelector:getState() <= InGameMenuMapFrame.MAP_HOTSPOTS
end
function InGameMenuMapFrame:onClickList(list, section, index, listElement)
    local overviewIndex = self.mapOverviewSelector:getState()
    if list == self.filterList and self:getHasChangeableFilterList() then
        if self.hotspotModeActive then
            self:setHotspotModeActive(false)
        end
        local statusFilter = self.filterStates[overviewIndex]
        if overviewIndex == InGameMenuMapFrame.MAP_HOTSPOTS then
            statusFilter = self.filterStates[overviewIndex][section]
        end
        if overviewIndex == InGameMenuMapFrame.MAP_SOIL then
        end
        local filterIndex
        if overviewIndex == InGameMenuMapFrame.MAP_FRUIT_TYPE then
            filterIndex = self.displayCropTypes[index].fruitTypeIndex
        else
            filterIndex = index
        end
        statusFilter[filterIndex] = not statusFilter[filterIndex]
        if overviewIndex == InGameMenuMapFrame.MAP_HOTSPOTS then
            local fruitTypeDesc = self.dataTables[overviewIndex][section][index].id
            self.ingameMapBase:toggleDefaultFilter(fruitTypeDesc)
            if fruitTypeDesc == MapHotspot.CATEGORY_OTHER then
                self.ingameMapBase:setDefaultFilterValue(MapHotspot.CATEGORY_SHOP, self.ingameMapBase:getDefaultFilterValue(MapHotspot.CATEGORY_OTHER))
            end
            self:setMapSelectionItem(nil)
        else
            self:generateOverviewOverlay()
        end
        self:saveFilters()
        if statusFilter[filterIndex] then
            self.numSelectedFilters[overviewIndex] = self.numSelectedFilters[overviewIndex] + 1
        else
            self.numSelectedFilters[overviewIndex] = self.numSelectedFilters[overviewIndex] - 1
        end
        if self.numSelectedFilters[overviewIndex] == 0 then
            self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
        else
            self.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
        end
    elseif list == self.contextButtonList or list == self.contextButtonListFarmland then
        listElement.onClickCallback(self)
    elseif list == self.activeWorkerList then
        local filterIndex = g_currentMission.aiSystem:getJobById(self.playerFarmActiveJobs[index])
        if filterIndex ~= nil and filterIndex.vehicleParameter then
            local fruitTypeDesc = filterIndex.vehicleParameter:getVehicle()
            if fruitTypeDesc ~= nil then
                local hotspot = fruitTypeDesc:getMapHotspot()
                self:setMapSelectionItem(hotspot)
                self.ingameMap:panToHotspot(hotspot)
            end
        end
    end
end
function InGameMenuMapFrame:onListSelectionChanged(list, _, index)
    if list == self.activeWorkerList and not self.blockListSelectionUpdates then
        local job = g_currentMission.aiSystem:getJobById(self.playerFarmActiveJobs[index])
        if job ~= nil and job.vehicleParameter then
            local vehicle = job.vehicleParameter:getVehicle()
            if vehicle ~= nil then
                local hotspot = vehicle:getMapHotspot()
                self.mode = InGameMenuMapFrame.AI_MODE_WORKER_LIST
                self:setMapSelectionItem(hotspot)
                self.ingameMap:panToHotspot(hotspot)
            end
        end
    end
end
function InGameMenuMapFrame:registerInput()
    self:unregisterInput()
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_PREV, false)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_NEXT, false)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START, false)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END, false)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START_GAMEPAD, false)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END_GAMEPAD, false)
    g_inputBinding:registerActionEvent(InputAction.MENU_MAP_ACTION_1, self, self.onMenuMapAction1, false, true, false, true)
    g_inputBinding:registerActionEvent(InputAction.SWITCH_VEHICLE, self, self.onSwitchVehicle, false, true, false, false, 1)
    g_inputBinding:registerActionEvent(InputAction.SWITCH_VEHICLE_BACK, self, self.onSwitchVehicle, false, true, false, false, -1)
end
function InGameMenuMapFrame.unregisterInput(_, customOnly)
    for _, actionName in pairs(customOnly and InGameMenuMapFrame.CLEAR_CLOSE_INPUT_ACTIONS or InGameMenuMapFrame.CLEAR_INPUT_ACTIONS) do
        g_inputBinding:removeActionEventsByActionName(actionName)
    end
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_PREV, true)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_NEXT, true)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START, true)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END, true)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_START_GAMEPAD, true)
    g_inputBinding:setContextEventsActive(InGameMenuMapFrame.INPUT_CONTEXT_NAME, InputAction.MENU_LIST_PAGE_END_GAMEPAD, true)
end
function InGameMenuMapFrame:onMenuMapAction1()
    if self.buttonDeselectAll:getIsVisible() then
        self:onClickDeselectAll()
    elseif self.buttonStartJobContainer:getIsVisible() then
        self:onStartCancelJob()
    end
end
function InGameMenuMapFrame:onSwitchVehicle(_, _, direction)
    if self.contextBoxFarmland:getIsVisible() then
        self:setMapSelectionItem(nil)
    end
    local newHotspot = self.ingameMapBase:cycleVisibleHotspot(self.currentHotspot, InGameMenuMapFrame.HOTSPOT_SWITCH_CATEGORIES, direction)
    self:setMapSelectionItem(newHotspot)
    self.ingameMap:panToHotspot(newHotspot, self.filterBox.absSize[1] * 0.5)
end
function InGameMenuMapFrame:getIsPicking()
    return self.isPickingRotation or self.isPickingLocation
end
function InGameMenuMapFrame:executePickingCallback(...)
    self.ingameMap:setHotspotSelectionActive(true)
    self.isPickingLocation = false
    self.isPickingRotation = false
    self.ingameMap:unlockMapMovement()
    local cb = self.pickingCallback
    self.pickingCallback = nil
    if cb ~= nil then
        cb(...)
    end
end
function InGameMenuMapFrame:startPickPosition(parameter, callback)
    self.ingameMap:setHotspotSelectionActive(false)
    self.ingameMap:setIsCursorAvailable(false)
    self.isPickingLocation = true
    self:showActionMessage("ui_ai_pickTargetLocation")
    local mission = g_currentMission
    mission:removeMapHotspot(self.aiTargetMapHotspot)
    mission:addMapHotspot(self.aiTargetMapHotspot)
    self.contextBox:setVisible(false)
    function self.pickingCallback(success, x, z)
        -- upvalues: (copy) self, (copy) parameter, (copy) callback
        self:showActionMessage()
        self.ingameMap:setIsCursorAvailable(true)
        self.hasPickedRotationTouch = false
        self.contextBox:setVisible(true)
        if success then
            parameter:setValue(x, z)
            self.aiTargetMapHotspot:setWorldPosition(x, z)
        end
        callback(success, x, z, parameter)
        self:validateParameters()
    end
end
function InGameMenuMapFrame:startPickPositionAndRotation(parameter, callback)
    self.isPickingLocation = true
    self.ingameMap:setHotspotSelectionActive(false)
    self.ingameMap:setIsCursorAvailable(false)
    self:showActionMessage("ui_ai_pickTargetLocation")
    local mission = g_currentMission
    mission:removeMapHotspot(self.aiTargetMapHotspot)
    mission:addMapHotspot(self.aiTargetMapHotspot)
    self.contextBox:setVisible(false)
    function self.pickingCallback(success, x, z)
        -- upvalues: (copy) self, (copy) parameter, (copy) callback
        self:showActionMessage()
        self.ingameMap:setIsCursorAvailable(true)
        self.hasPickedRotationTouch = false
        self.contextBox:setVisible(true)
        if success then
            self.ingameMap:setHotspotSelectionActive(false)
            self.ingameMap:setIsCursorAvailable(false)
            self.aiTargetMapHotspot:setWorldPosition(x, z)
            self.isPickingRotation = true
            self.ingameMap:lockMapMovement()
            self.pickingRotationOrigin = { x, z }
            self.pickingRotationSnapAngle = parameter:getSnappingAngle()
            self:showActionMessage("ui_ai_pickTargetRotation")
            self.contextBox:setVisible(false)
            function self.pickingCallback(successRotation, angle)
                -- upvalues: (ref) self, (ref) parameter, (copy) x, (copy) z, (ref) callback
                self:showActionMessage()
                self.ingameMap:setIsCursorAvailable(true)
                self.contextBox:setVisible(true)
                if successRotation then
                    parameter:setPosition(x, z)
                    parameter:setAngle(angle)
                    local convertedAngle = parameter:getAngle()
                    self.aiTargetMapHotspot:setWorldRotation(convertedAngle + 3.141592653589793)
                    callback(true, x, z, angle)
                else
                    callback(false, x, z, nil)
                end
                self:validateParameters()
            end
        else
            callback(false, nil, nil, nil)
        end
        self:validateParameters()
    end
end
function InGameMenuMapFrame:setJobMenuVisible(isVisible)
    g_inputBinding:setActionEventActive(self.eventIdSwitchVehicle, not isVisible)
    g_inputBinding:setActionEventActive(self.eventIdSwitchVehicleBack, not isVisible)
    self.errorMessage:setText("")
    self.actionMessage:setText("")
    if self.hotspotModeActive then
        self:setHotspotModeActive(false)
    end
    if isVisible then
        self.createJobContainer:setVisible(false)
        self.mapOverviewSelector:setState(InGameMenuMapFrame.AI_CREATE_JOB, true)
    else
        local i = #self.jobMenuLayout.elements
        for i = i, 1, -1 do
            self.jobMenuLayout.elements[i]:delete()
        end
        self.currentJobElements = {}
        self.jobMenuLayout:invalidateLayout()
        self.jobTypeElement:setTexts({})
        self.createJobContainer:setVisible(false)
        FocusManager:setFocus(self.mapOverviewSelector)
    end
    self.createJobContainer:setVisible(isVisible)
    local i = not isVisible
    if i then
        i = self.activeWorkerList:getItemCount() == 0
    end
    self.createJobEmptyText:setVisible(i)
    self.mapOverviewSelector:setDisabled(isVisible)
end
function InGameMenuMapFrame:createJob()
    local vehicle = self.currentHotspot:getVehicle()
    if vehicle ~= nil then
        self.currentJobTypes = {}
        local currentJobTypesTexts = {}
        local currentJobTypeIndex = nil
        local currentIndex = nil
        local lastJob = nil
        if vehicle.getLastJob ~= nil then
            lastJob = vehicle:getLastJob()
        end
        for name, index in pairs(AIJobType) do
            if self.jobTypeInstances[index]:getIsAvailableForVehicle(vehicle) then
                table.insert(self.currentJobTypes, index)
                table.insert(currentJobTypesTexts, g_currentMission.aiJobTypeManager:getJobTypeByIndex(index).title)
                if currentJobTypeIndex == nil or lastJob ~= nil and lastJob.class == self.jobTypeInstances[index].class then
                    currentIndex = #self.currentJobTypes
                    currentJobTypeIndex = index
                end
            end
        end
        if #self.currentJobTypes == 0 then
            printError("Error: vehicle has no support for any jobs, so button should not have been shown!")
            return
        end
        self.jobTypeElement:setTexts(currentJobTypesTexts)
        self.jobTypeElement:setState(currentIndex or 1)
        self.mode = InGameMenuMapFrame.AI_MODE_CREATE
        self.currentJobVehicle = vehicle
        self.currentJob = nil
        self:setJobMenuVisible(true)
        FocusManager:setFocus(self.jobTypeElement)
        self:setActiveJobTypeSelection(currentJobTypeIndex)
    end
end
function InGameMenuMapFrame:tryStartGoToJob()
    if self.currentHotspot ~= nil then
        local vehicle = self.currentHotspot:getVehicle()
        if vehicle ~= nil then
            self:startPickPositionAndRotation(self.jobTypeInstances[AIJobType.GOTO].positionAngleParameter, function(success, x, z, angle)
                -- upvalues: (copy) self, (copy) vehicle
                if success then
                    self:startGoToJob(vehicle, x, z, angle)
                end
                self:refreshContextInput()
            end)
        end
    end
end
function InGameMenuMapFrame:tryStartJob(job, farmId, callback)
    self.startJobPending = true
    g_messageCenter:subscribe(AIJobStartRequestEvent, self.onStartedJob, self, { callback })
    g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(job, farmId))
end
function InGameMenuMapFrame:onStartedJob(args, state, jobTypeIndex)
    self.startJobPending = false
    g_messageCenter:unsubscribe(AIJobStartRequestEvent, self)
    if state == AIJob.START_SUCCESS then
        self.mapOverviewSelector:setState(InGameMenuMapFrame.AI_WORKER_LIST, true)
        FocusManager:setFocus(self.activeWorkerList)
    else
        local text = g_currentMission.aiJobTypeManager:getJobTypeByIndex(jobTypeIndex).classObject.getIsStartErrorText(state)
        InfoDialog.show(text, nil, nil, DialogElement.TYPE_INFO)
    end
    args[1](state)
end
function InGameMenuMapFrame:skipCurrentTask()
    local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
    if vehicle ~= nil and vehicle:getIsAIActive() then
        local job = vehicle:getJob()
        if job ~= nil then
            if job:getCanSkipTask() then
                vehicle:skipCurrentTask()
                return
            end
            self:refreshContextInput()
        end
    end
end
InGameMenuMapFrame.INPUT_CONTEXT_NAME = "MENU_MAP_OVERVIEW"
InGameMenuMapFrame.CLEAR_INPUT_ACTIONS = {
    InputAction.MENU_ACTIVATE,
    InputAction.MENU_CANCEL,
    InputAction.MENU_EXTRA_2,
    InputAction.CAMERA_ZOOM_IN_OUT
}
InGameMenuMapFrame.CLEAR_CLOSE_INPUT_ACTIONS = { InputAction.CAMERA_ZOOM_IN_OUT }
InGameMenuMapFrame.HOTSPOT_SWITCH_CATEGORIES = {
    [MapHotspot.CATEGORY_STEERABLE] = true,
    [MapHotspot.CATEGORY_COMBINE] = true,
    [MapHotspot.CATEGORY_TRAILER] = true,
    [MapHotspot.CATEGORY_TOOL] = true,
    [MapHotspot.CATEGORY_OTHER] = false,
    [MapHotspot.CATEGORY_AI] = true,
    [MapHotspot.CATEGORY_PLAYER] = false
}
InGameMenuMapFrame.HOTSPOT_FILTER_CATEGORIES = {
    {
        {
            ["id"] = MapHotspot.CATEGORY_STEERABLE,
            ["sliceId"] = "gui.ingameMap_vehicles",
            ["name"] = "ui_mapHotspotFilter_vehicles",
            ["color"] = {
                {
                    0.13,
                    0.13,
                    0.13,
                    1
                }
            }
        },
        {
            ["id"] = MapHotspot.CATEGORY_COMBINE,
            ["sliceId"] = "gui.ingameMap_harvester",
            ["name"] = "ui_mapHotspotFilter_combines",
            ["color"] = {
                {
                    0.13,
                    0.13,
                    0.13,
                    1
                }
            }
        },
        {
            ["id"] = MapHotspot.CATEGORY_TRAILER,
            ["sliceId"] = "gui.ingameMap_trailer",
            ["name"] = "ui_mapHotspotFilter_trailers",
            ["color"] = {
                {
                    0.13,
                    0.13,
                    0.13,
                    1
                }
            }
        },
        {
            ["id"] = MapHotspot.CATEGORY_TOOL,
            ["sliceId"] = "gui.ingameMap_tools",
            ["name"] = "ui_mapHotspotFilter_tools",
            ["color"] = {
                {
                    0.13,
                    0.13,
                    0.13,
                    1
                }
            }
        },
        {
            ["id"] = MapHotspot.CATEGORY_AI,
            ["sliceId"] = "gui.ingameMap_helper",
            ["name"] = "ui_mapHotspotFilter_ai",
            ["color"] = {
                {
                    0.13,
                    0.13,
                    0.13,
                    1
                }
            }
        }
    },
    {
        {
            ["id"] = MapHotspot.CATEGORY_UNLOADING,
            ["sliceId"] = "gui.ingameMap_tippingStation",
            ["name"] = "ui_mapHotspotFilter_tipStations",
            ["color"] = {
                {
                    0.26635,
                    0.00477,
                    0.11443,
                    1
                }
            }
        },
        {
            ["id"] = MapHotspot.CATEGORY_LOADING,
            ["sliceId"] = "gui.ingameMap_loadingStation",
            ["name"] = "ui_mapHotspotFilter_loadingStations",
            ["color"] = {
                {
                    0.02028,
                    0.07036,
                    0.43415,
                    1
                }
            }
        },
        {
            ["id"] = MapHotspot.CATEGORY_PRODUCTION,
            ["sliceId"] = "gui.ingameMap_productionPoint",
            ["name"] = "ui_mapHotspotFilter_productionPoints",
            ["color"] = {
                {
                    0.00651,
                    0.56471,
                    0.57758,
                    1
                }
            }
        },
        {
            ["id"] = MapHotspot.CATEGORY_ANIMAL,
            ["sliceId"] = "gui.ingameMap_animals",
            ["name"] = "ui_mapHotspotFilter_animals",
            ["color"] = {
                {
                    0.00604,
                    0.14412,
                    0.11443,
                    1
                }
            }
        },
        {
            ["id"] = MapHotspot.CATEGORY_MISSION,
            ["sliceId"] = "gui.ingameMap_contracts",
            ["name"] = "ui_mapHotspotFilter_contracts",
            ["color"] = {
                {
                    0.00303,
                    0.20155,
                    0.01599,
                    1
                }
            }
        },
        {
            ["id"] = MapHotspot.CATEGORY_OTHER,
            ["sliceId"] = "gui.ingameMap_other",
            ["name"] = "ui_mapHotspotFilter_others",
            ["color"] = {
                {
                    0.61049,
                    0.56471,
                    0.00303,
                    1
                }
            }
        }
    }
}
InGameMenuMapFrame.GLYPH_SIZE = { 36, 36 }
InGameMenuMapFrame.GLYPH_TEXT_SIZE = 20
InGameMenuMapFrame.GLYPH_COLOR = {
    1,
    1,
    1,
    1
}
InGameMenuMapFrame.L10N_SYMBOL = {
    ["VEHICLE_RESET"] = "button_reset",
    ["SELECT_ALL"] = "button_selectAll",
    ["DESELECT_ALL"] = "button_deselectAll",
    ["DIALOG_VEHICLE_RESET_DONE"] = "ui_vehicleResetDone",
    ["DIALOG_VEHICLE_RESET_FAILED"] = "ui_vehicleResetFailed",
    ["DIALOG_VEHICLE_IN_USE"] = "shop_messageReturnVehicleInUse",
    ["DIALOG_VEHICLE_NO_PERMISSION"] = "shop_messageNoPermissionGeneral",
    ["DIALOG_VEHICLE_RESET_CONFIRM"] = "ui_wantToResetVehicleText",
    ["DIALOG_BUY_FARMLAND"] = "shop_messageBuyFarmlandText",
    ["DIALOG_BUY_FARMLAND_TITLE"] = "shop_messageBuyFarmlandTitle",
    ["DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY"] = "shop_messageNotEnoughMoneyToBuyFarmland",
    ["DIALOG_BUY_FARMLAND_ACTIVE_MISSION"] = "shop_messageBuyFarmlandMissionRunning",
    ["DIALOG_SELL_FARMLAND"] = "shop_messageSellFarmlandText",
    ["DIALOG_SELL_FARMLAND_TITLE"] = "shop_messageSellFarmlandTitle",
    ["DIALOG_CANNOT_SELL_WTIH_PLACEABLES"] = "shop_messageCannotSellFarmlandWithPlaceables",
    ["INPUT_MOVE_CURSOR"] = "ui_ingameMenuMapMoveCursor",
    ["INPUT_PAN_MAP"] = "ui_ingameMenuMapPan",
    ["INPUT_ZOOM_MAP"] = "ui_ingameMenuMapZoom"
}
InGameMenuMapFrame.PROFILE = {
    ["MONEY_VALUE_NEUTRAL"] = "ingameMenuMapMoneyValue",
    ["MONEY_VALUE_NEGATIVE"] = "ingameMenuMapMoneyValueNegative",
    ["CONTEXT_BUTTON"] = "fs25_mapContextButtonListItemButton",
    ["CONTEXT_BUTTON_GAMEPAD"] = "fs25_mapContextButtonListItemButtonGamepad"
}
InGameMenuMapFrame.ACTIONS = {
    ["GOTO_JOB"] = 1,
    ["ENTER_VEHICLE"] = 2,
    ["CREATE_JOB"] = 3,
    ["START_JOB"] = 4,
    ["CANCEL_JOB"] = 5,
    ["SKIP_TASK"] = 6,
    ["RESET_VEHICLE"] = 7,
    ["SELL_VEHICLE"] = 8,
    ["VISIT_PLACE"] = 9,
    ["MANAGE"] = 10,
    ["BUY"] = 11,
    ["SELL"] = 12,
    ["SET_MARKER"] = 13,
    ["REMOVE_MARKER"] = 14
}