InGameMenuMobileMapFrame = {}
local InGameMenuMobileMapFrame_mt = Class(InGameMenuMobileMapFrame, TabbedMenuFrameElement)
InGameMenuMobileMapFrame.MODE_NONE = 0
InGameMenuMobileMapFrame.MODE_OVERVIEW = 1
InGameMenuMobileMapFrame.MODE_AI_PAGE = 2
InGameMenuMobileMapFrame.MODE_CREATE_JOB = 3
InGameMenuMobileMapFrame.MAP_FRUIT_TYPE = 1
InGameMenuMobileMapFrame.MAP_GROWTH = 2
InGameMenuMobileMapFrame.MAP_SOIL = 3
InGameMenuMobileMapFrame.MAP_HOTSPOTS = InGameMenuMobileMapFrame.MAP_FRUIT_TYPE
InGameMenuMobileMapFrame.PAGE_ID = {
    ["STATUS"] = 1,
    ["VEHICLES"] = 2,
    ["POINTS"] = 3,
    ["FIELDS"] = 4,
    ["AI"] = 5
}
InGameMenuMobileMapFrame.PAGE_NAMES = {
    [InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = "ui_inGameMenuVehicles",
    [InGameMenuMobileMapFrame.PAGE_ID.POINTS] = "ui_inGameMenuPointsOfInterest",
    [InGameMenuMobileMapFrame.PAGE_ID.STATUS] = "ui_inGameMenuFieldStatus",
    [InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = "ui_inGameMenuFields",
    [InGameMenuMobileMapFrame.PAGE_ID.AI] = "ui_helpers"
}
InGameMenuMobileMapFrame.SECTION_NAMES = {
    ["VEHICLES"] = { "ui_mapHotspotFilter_driveables", "ui_mapHotspotFilter_tools", "helpLine_Animals_Horses" },
    ["POINTS"] = {
        "ui_mapHotspotFilter_buyingSelling",
        "ui_mapHotspotFilter_productionPoints",
        "ui_mapHotspotFilter_animals",
        "ui_mapHotspotFilter_others"
    },
    ["FIELDS"] = { "ui_mapPageFields_ownedByYou", "ui_mapPageFields_availableToBuy" }
}
InGameMenuMobileMapFrame.HOTSPOT_FILTERS = {
    ["LOADING"] = 1,
    ["PRODUCTIONS"] = 2,
    ["ANIMALS"] = 3,
    ["OTHER"] = 4
}
InGameMenuMobileMapFrame.FIELD_STATUS = { "ui_mapViewMode2", "ui_mapViewMode1", "ui_mapOverviewSoil" }
local NO_CALLBACK = InGameMenuMobileMapFrame
NO_CALLBACK.HOTSPOT_SWITCH_CATEGORIES = {
    [InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = {
        [MapHotspot.CATEGORY_TOOL] = true,
        [MapHotspot.CATEGORY_TRAILER] = true,
        [MapHotspot.CATEGORY_COMBINE] = true,
        [MapHotspot.CATEGORY_STEERABLE] = true,
        [MapHotspot.CATEGORY_AI] = true
    },
    [InGameMenuMobileMapFrame.PAGE_ID.POINTS] = {
        [MapHotspot.CATEGORY_ANIMAL] = true,
        [MapHotspot.CATEGORY_LOADING] = true,
        [MapHotspot.CATEGORY_OTHER] = true
    },
    [InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = {
        [MapHotspot.CATEGORY_FIELD] = true
    },
    [InGameMenuMobileMapFrame.PAGE_ID.AI] = {
        [MapHotspot.CATEGORY_TOOL] = true,
        [MapHotspot.CATEGORY_TRAILER] = true,
        [MapHotspot.CATEGORY_COMBINE] = true,
        [MapHotspot.CATEGORY_STEERABLE] = true,
        [MapHotspot.CATEGORY_AI] = true,
        [MapHotspot.CATEGORY_ANIMAL] = true,
        [MapHotspot.CATEGORY_LOADING] = true,
        [MapHotspot.CATEGORY_OTHER] = true
    },
    [MapHotspot.CATEGORY_PLAYER] = true
}
InGameMenuMobileMapFrame.HOTSPOT_SORTING_PRIO = {
    [InGameMenuMobileMapFrame.PAGE_ID.STATUS] = {
        MapHotspot.CATEGORY_FIELD,
        MapHotspot.CATEGORY_MISSION,
        MapHotspot.CATEGORY_TOUR,
        MapHotspot.CATEGORY_STEERABLE,
        MapHotspot.CATEGORY_COMBINE,
        MapHotspot.CATEGORY_TRAILER,
        MapHotspot.CATEGORY_TOOL,
        MapHotspot.CATEGORY_AI,
        MapHotspot.CATEGORY_ANIMAL,
        MapHotspot.CATEGORY_UNLOADING,
        MapHotspot.CATEGORY_LOADING,
        MapHotspot.CATEGORY_PRODUCTION,
        MapHotspot.CATEGORY_SHOP,
        MapHotspot.CATEGORY_OTHER,
        MapHotspot.CATEGORY_PLAYER
    },
    [InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = {
        MapHotspot.CATEGORY_FIELD,
        MapHotspot.CATEGORY_ANIMAL,
        MapHotspot.CATEGORY_MISSION,
        MapHotspot.CATEGORY_TOUR,
        MapHotspot.CATEGORY_UNLOADING,
        MapHotspot.CATEGORY_LOADING,
        MapHotspot.CATEGORY_PRODUCTION,
        MapHotspot.CATEGORY_SHOP,
        MapHotspot.CATEGORY_OTHER,
        MapHotspot.CATEGORY_STEERABLE,
        MapHotspot.CATEGORY_COMBINE,
        MapHotspot.CATEGORY_TRAILER,
        MapHotspot.CATEGORY_TOOL,
        MapHotspot.CATEGORY_AI,
        MapHotspot.CATEGORY_PLAYER
    },
    [InGameMenuMobileMapFrame.PAGE_ID.POINTS] = {
        MapHotspot.CATEGORY_FIELD,
        MapHotspot.CATEGORY_MISSION,
        MapHotspot.CATEGORY_TOUR,
        MapHotspot.CATEGORY_STEERABLE,
        MapHotspot.CATEGORY_COMBINE,
        MapHotspot.CATEGORY_TRAILER,
        MapHotspot.CATEGORY_TOOL,
        MapHotspot.CATEGORY_AI,
        MapHotspot.CATEGORY_ANIMAL,
        MapHotspot.CATEGORY_UNLOADING,
        MapHotspot.CATEGORY_LOADING,
        MapHotspot.CATEGORY_PRODUCTION,
        MapHotspot.CATEGORY_SHOP,
        MapHotspot.CATEGORY_OTHER,
        MapHotspot.CATEGORY_PLAYER
    },
    [InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = {
        MapHotspot.CATEGORY_MISSION,
        MapHotspot.CATEGORY_TOUR,
        MapHotspot.CATEGORY_OTHER,
        MapHotspot.CATEGORY_STEERABLE,
        MapHotspot.CATEGORY_COMBINE,
        MapHotspot.CATEGORY_TRAILER,
        MapHotspot.CATEGORY_TOOL,
        MapHotspot.CATEGORY_ANIMAL,
        MapHotspot.CATEGORY_UNLOADING,
        MapHotspot.CATEGORY_LOADING,
        MapHotspot.CATEGORY_PRODUCTION,
        MapHotspot.CATEGORY_SHOP,
        MapHotspot.CATEGORY_AI,
        MapHotspot.CATEGORY_FIELD,
        MapHotspot.CATEGORY_PLAYER
    },
    [InGameMenuMobileMapFrame.PAGE_ID.AI] = {
        MapHotspot.CATEGORY_FIELD,
        MapHotspot.CATEGORY_MISSION,
        MapHotspot.CATEGORY_TOUR,
        MapHotspot.CATEGORY_ANIMAL,
        MapHotspot.CATEGORY_UNLOADING,
        MapHotspot.CATEGORY_LOADING,
        MapHotspot.CATEGORY_PRODUCTION,
        MapHotspot.CATEGORY_SHOP,
        MapHotspot.CATEGORY_OTHER,
        MapHotspot.CATEGORY_STEERABLE,
        MapHotspot.CATEGORY_COMBINE,
        MapHotspot.CATEGORY_TRAILER,
        MapHotspot.CATEGORY_TOOL,
        MapHotspot.CATEGORY_AI,
        MapHotspot.CATEGORY_PLAYER
    }
}
InGameMenuMobileMapFrame.BUTTON_TEXTS = {
    ["SET_MARKER"] = "action_tag",
    ["REMOVE_MARKER"] = "action_untag",
    ["VEHICLE_RESET"] = "button_reset",
    ["DIALOG_VEHICLE_RESET_DONE"] = "ui_vehicleResetDone",
    ["DIALOG_VEHICLE_RESET_FAILED"] = "ui_vehicleResetFailed",
    ["DIALOG_VEHICLE_IN_USE"] = "shop_messageReturnVehicleInUse",
    ["DIALOG_VEHICLE_NO_PERMISSION"] = "shop_messageNoPermissionGeneral",
    ["DIALOG_VEHICLE_RESET_CONFIRM"] = "ui_wantToResetVehicleText",
    ["DIALOG_BUY_FARMLAND_TITLE"] = "shop_messageBuyFarmlandTitle",
    ["DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY"] = "shop_messageNotEnoughMoneyToBuyFarmland",
    ["MOBILE_BUY_FIELD_TEXT"] = "ui_mobile_buyFieldDialogText",
    ["MOBILE_BUY_FIELD_TEXT_COINS"] = "ui_mobile_buyFieldDialogText_buyCoins",
    ["BUTTON_CLOSE_MAP"] = "button_closeMap",
    ["BUTTON_CANCEL"] = "button_cancel"
}
InGameMenuMobileMapFrame.CLEAR_INPUT_ACTIONS = {
    InputAction.MENU_ACCEPT,
    InputAction.MENU_ACTIVATE,
    InputAction.MENU_CANCEL,
    InputAction.MENU_EXTRA_1,
    InputAction.MENU_EXTRA_2,
    InputAction.SWITCH_VEHICLE,
    InputAction.SWITCH_VEHICLE_BACK,
    InputAction.CAMERA_ZOOM_IN_OUT,
    InputAction.MENU_AXIS_LEFT_RIGHT
}
InGameMenuMobileMapFrame.CLEAR_CLOSE_INPUT_ACTIONS = { InputAction.SWITCH_VEHICLE, InputAction.SWITCH_VEHICLE_BACK, InputAction.CAMERA_ZOOM_IN_OUT }
local function NO_CALLBACK() end
InGameMenuMobileMapFrame.INPUT_CONTEXT_NAME = "MENU_MOBILE_MAP"
function InGameMenuMobileMapFrame.register()
    if Platform.isMobile then
        local inGameMenuMobileMapFrame = InGameMenuMobileMapFrame.new()
        g_gui:loadGui("dataS/gui/InGameMenuMobileMapFrame.xml", "MobileMapFrame", inGameMenuMobileMapFrame, true)
    end
end
function InGameMenuMobileMapFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuMobileMapFrame_mt, (copy) NO_CALLBACK
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMobileMapFrame_mt)
    self.onClickBackCallback = NO_CALLBACK
    self.client = nil
    self.playerFarm = nil
    self.statusMessages = {}
    self.mode = InGameMenuMobileMapFrame.MODE_NONE
    self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
    self.fruitTypeFilter = {}
    self.fruitTypeFilterMapping = {}
    self.growthStateFilter = {}
    self.soilStateFilter = {}
    self.fieldStatusFilters = {
        [InGameMenuMobileMapFrame.MAP_FRUIT_TYPE] = self.fruitTypeFilter,
        [InGameMenuMobileMapFrame.MAP_GROWTH] = self.growthStateFilter,
        [InGameMenuMobileMapFrame.MAP_SOIL] = self.soilStateFilter
    }
    self.foliageStateOverlay = nil
    self.foliageStateOverlayIsReady = false
    function self.overviewOverlayFinishedCallback(overlayId)
        -- upvalues: (copy) self
        self:onOverviewOverlayFinished(overlayId)
    end
    self.inGameMapBase = nil
    self.needsSolidBackground = Platform.ingameMap.needsSolidBackground
    self.isOpening = true
    self.blockListSelectionEvents = false
    self.hasFullScreenMap = true
    self.goToMainOverview = false
    self.pageLists = {}
    self.vehicles = {}
    self.fieldStatus = {}
    self.fields = {}
    self.hotspotsSorted = {}
    self.hotspotFiltersActive = {
        true,
        true,
        true,
        true
    }
    self.hotspotFiltersMapping = {}
    self.marqueeBoxes = {}
    self.clonedElements = {}
    self.currentHotspot = nil
    self.currentList = nil
    self.currentListItem = nil
    self.jobTypeInstances = {}
    self.statusMessages = {}
    self.currentJob = nil
    self.hasPickedLocationTouch = false
    self.hasPickedRotationTouch = false
    self.lastTouchPosX = 0
    self.lastTouchPosY = 0
    self.updateTime = 0
    self.aiTargetMapHotspot = AITargetHotspot.new()
    self.pickingRotationSnapAngle = 0
    return self
end
function InGameMenuMobileMapFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuMobileMapFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuMobileMapFrame:copyAttributes(src)
    -- upvalues: (copy) NO_CALLBACK
    InGameMenuMobileMapFrame:superClass().copyAttributes(self, src)
    self.onClickBackCallback = src.onClickBackCallback or NO_CALLBACK
end
function InGameMenuMobileMapFrame:delete()
    InGameMenuMobileMapFrame:superClass().delete(self)
    if self.aiTargetMapHotspot ~= nil then
        self.aiTargetMapHotspot:delete()
        self.aiTargetMapHotspot = nil
    end
end
function InGameMenuMobileMapFrame:initialize(onClickBackCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.onClickBackCallback = onClickBackCallback or NO_CALLBACK
    self.buttonsResizeTextSize = self.buttonSelectInGame.defaultTextSize
    self.buttonsResizeNeeded = {
        self.buttonSelectInGame,
        self.buttonEnterVehicle,
        self.buttonResetVehicle,
        self.buttonGoToJob,
        self.buttonCreateJob
    }
    self.pageLists = {
        [InGameMenuMobileMapFrame.PAGE_ID.STATUS] = self.statusList,
        [InGameMenuMobileMapFrame.PAGE_ID.VEHICLES] = self.vehiclesList,
        [InGameMenuMobileMapFrame.PAGE_ID.POINTS] = self.pointsList,
        [InGameMenuMobileMapFrame.PAGE_ID.FIELDS] = self.fieldsList,
        [InGameMenuMobileMapFrame.PAGE_ID.AI] = self.aiWorkersList
    }
    self.currentList = self.statusList
    self.vehiclesList.detailsBox = self.vehicleDetailsBox
    self.pointsList.detailsBox = self.pointDetailsBox
    self.aiWorkersList.detailsBox = self.aiDetailsBox
    self.mapPageSelector.texts = {}
    for _, pageName in pairs(InGameMenuMobileMapFrame.PAGE_NAMES) do
        table.insert(self.mapPageSelector.texts, g_i18n:getText(pageName))
    end
    for _, pageName in pairs(self.pagingElement.elements) do
        if pageName.getOverlayState ~= nil then
            local _
            function pageName.getOverlayState()
                -- upvalues: (copy) self, (copy) _
                return self.mapPageSelector.state == _ and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
            end
        end
    end
    self.mapPageSelector:setState(1)
    self.statusSelector.texts = {}
    for _, pageName in pairs(InGameMenuMobileMapFrame.FIELD_STATUS) do
        table.insert(self.statusSelector.texts, g_i18n:getText(pageName))
    end
    self.statusSelector:setState(1)
    for _, pageName in pairs(self.pointsFilterButtonBox.elements) do
        local _
        function pageName.getOverlayState()
            -- upvalues: (copy) self, (copy) _
            return self.hotspotFiltersActive[_] and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
        end
    end
    function self.pointsFilterButtonGlyph.glyphElement.overlay.getIsVisible()
        -- upvalues: (copy) self
        return self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and FocusManager:getFocusedElement() ~= self.pointsList
    end
    FocusManager:linkElements(self.pointsList, FocusManager.BOTTOM, nil)
    FocusManager:linkElements(self.pointsList, FocusManager.RIGHT, self.pointsFilterButtonBox)
    self.aiWorkersList.onClickCallback = self.onListSelectionChanged
end
function InGameMenuMobileMapFrame:reset()
    InGameMenuMobileMapFrame:superClass().reset(self)
    self.isInputContextActive = false
end
function InGameMenuMobileMapFrame:onFrameOpen()
    InGameMenuMobileMapFrame:superClass().onFrameOpen(self)
    self:loadFilters()
    self:setColorBlindMode(Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false))
    self:updateElementSizes()
    local inGameMap = self.inGameMap
    local inGameMapBase = self.inGameMapBase
    self:toggleMapInput(true)
    inGameMapBase.fullScreenLayout:setMapWidth(1 - self.filterBoxContainer.absSize[1] - self.leftInset + 27 * g_aspectScaleX / g_referenceScreenWidth)
    inGameMapBase.clipHotspots = true
    inGameMapBase:restoreDefaultFilter()
    inGameMap:onOpen()
    inGameMap:registerActionEvents()
    self:generateOverviewOverlay()
    self.statusList:reloadData()
    self:updateVehicles()
    self.vehiclesList:reloadData()
    self:updatePoints()
    self.pointsList:reloadData()
    self:updateFields()
    self.fieldsList:reloadData()
    self:setJobMenuVisible(false)
    self:generateJobTypes()
    self.aiWorkersList:reloadData()
    self.inGameMap.ingameMap:updateHotspotSorting()
    local playerVehicle = self.inGameMap:getPlayerHotspot(self.inGameMap.ingameMap.hotspotsSorted[true]):getVehicle()
    if playerVehicle ~= nil then
        self:selectHotspotInList(playerVehicle:getMapHotspot(), self.vehiclesList)
        if self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.VEHICLES or self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.AI then
            self:setMapSelectionItem(playerVehicle:getMapHotspot())
        end
    end
    g_messageCenter:subscribe(MessageType.AI_JOB_STARTED, self.onAIJobStarted, self)
    g_messageCenter:subscribe(MessageType.AI_JOB_STOPPED, self.onAIJobStopped, self)
    g_messageCenter:subscribe(MessageType.AI_JOB_REMOVED, self.onAIJobRemoved, self)
    g_messageCenter:subscribe(MessageType.AI_TASK_SKIPPED, self.onAITaskSkipped, self)
    g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.onInsetsChanged, self)
    local slider = self.currentList.sliderElement
    if slider ~= nil then
        slider.parent:setVisible(self.currentList.visible and self.currentList.totalItemCount > 0 and slider.needsSlider)
    end
    self:onMapPageSelected()
end
function InGameMenuMobileMapFrame:onFrameClose()
    g_messageCenter:unsubscribeAll(self)
    InGameMenuMobileMapFrame:superClass().onFrameClose(self)
    self.inGameMap:onClose()
    self:toggleMapInput(false)
    self.inGameMapBase:restoreDefaultFilter()
    self.inGameMapBase:applyCustomHotspotSortingOrder(InGameMenuMobileMapFrame.HOTSPOT_SORTING_PRIO[InGameMenuMobileMapFrame.PAGE_ID.STATUS])
    self.inGameMapBase.clipHotspots = false
    g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
    self.isOpening = true
end
function InGameMenuMobileMapFrame:saveFilters()
    local fruitValue = ""
    for index, state in pairs(self.fruitTypeFilter) do
        if self.fruitTypeFilter[index] == false then
            local name = g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeFilterMapping[index])
            if fruitValue == "" then
                fruitValue = name
            end
        end
    end
    local growthValue = 0
    for state, fruitId in ipairs(self.growthStateFilter) do
        if fruitId then
            growthValue = Utils.setBit(growthValue, state)
        end
    end
    local soilValue = 0
    for fruitId, name in ipairs(self.soilStateFilter) do
        if name then
            soilValue = Utils.setBit(soilValue, fruitId)
        end
    end
    g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER, fruitValue, false)
    g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER, growthValue, false)
    g_gameSettings:setValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER, soilValue, true)
    self.statusMessages = {}
    self:updateStatusMessages()
end
function InGameMenuMobileMapFrame:loadFilters()
    local fruitNames = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER):split(";")
    for index, key in pairs(self.fruitTypeFilterMapping) do
        ({})[key] = index
    end
    for index, key in ipairs(fruitNames) do
        local fruitDesc = g_fruitTypeManager:getFruitTypeByName(key)
        if fruitDesc ~= nil and inverseFruitTypeFilterMapping[fruitDesc.index] ~= nil then
            self.fruitTypeFilter[inverseFruitTypeFilterMapping[fruitDesc.index]] = false
        end
    end
    local growthValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER)
    for key, fruitDesc in pairs(self.displayGrowthStates) do
        self.growthStateFilter[key] = Utils.isBitSet(growthValue, key)
    end
    local soilValue = g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER)
    for fruitDesc, _ in pairs(self.displaySoilStates) do
        self.soilStateFilter[fruitDesc] = Utils.isBitSet(soilValue, fruitDesc)
    end
end
function InGameMenuMobileMapFrame:onLoadMapFinished()
    local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
    if mapOverlayGenerator ~= nil then
        self.displayCropTypes = mapOverlayGenerator:getDisplayCropTypes()
        self.displayGrowthStates = mapOverlayGenerator:getDisplayGrowthStates()
        self.displaySoilStates = mapOverlayGenerator:getDisplaySoilStates()
    end
    table.insert(self.fieldStatus, self.displayCropTypes)
    table.insert(self.fieldStatus, self.displayGrowthStates)
    table.insert(self.fieldStatus, self.displaySoilStates)
    for i, cropType in pairs(self.displayCropTypes) do
        self.fruitTypeFilter[i] = true
        self.fruitTypeFilterMapping[i] = cropType.fruitTypeIndex
    end
    self.inGameMapBase:applyCustomHotspotSortingOrder(InGameMenuMobileMapFrame.HOTSPOT_SORTING_PRIO[InGameMenuMobileMapFrame.PAGE_ID.STATUS])
    self:setMapSelectionItem(nil)
end
function InGameMenuMobileMapFrame:toggleMapInput(isActive)
    if self.isInputContextActive ~= isActive then
        self.isInputContextActive = isActive
        self:toggleCustomInputContext(isActive, InGameMenuMobileMapFrame.INPUT_CONTEXT_NAME)
        if isActive then
            self:registerInput()
            return
        end
        self:unregisterInput(true)
    end
end
function InGameMenuMobileMapFrame:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
    if self.isPickingRotation and not self.hasPickedRotationTouch then
        local localX, localY = self.inGameMap:getLocalPosition(posX, posY)
        local worldX, worldZ = self.inGameMap:localToWorldPos(localX, localY)
        local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2]) + 3.141592653589793
        if self.pickingRotationSnapAngle > 0 then
            angle = MathUtil.round(angle / self.pickingRotationSnapAngle, 0) * self.pickingRotationSnapAngle
        end
        self.aiTargetMapHotspot:setWorldRotation(angle)
    end
    if isUp then
        self.lastTouchPosX = posX
        self.lastTouchPosY = posY
    end
    return InGameMenuMobileMapFrame:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed)
end
function InGameMenuMobileMapFrame:update(dt)
    InGameMenuMobileMapFrame:superClass().update(self, dt)
    self.isOpening = false
    local currentInputHelpMode = g_inputBinding:getInputHelpMode()
    if currentInputHelpMode ~= self.lastInputHelpMode then
        self.lastInputHelpMode = currentInputHelpMode
        self:refreshContextInput()
    end
    if currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
        local localX, localY = self.inGameMap:getLocalPointerTarget()
        if self.isPickingLocation then
            self:setTargetPointHotspotPosition(localX, localY)
        elseif self.isPickingRotation then
            local worldX, worldZ = self.inGameMap:localToWorldPos(localX, localY)
            local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2]) + 3.141592653589793
            if self.pickingRotationSnapAngle > 0 then
                angle = MathUtil.round(angle / self.pickingRotationSnapAngle, 0) * self.pickingRotationSnapAngle
            end
            self.aiTargetMapHotspot:setWorldRotation(angle)
        end
    end
    local localX = false
    local worldZ = 1
    local localY = #self.statusMessages
    local worldX = 1
    for worldZ = worldZ, localY, worldX do
        if self.statusMessages[1].removeTime < g_time then
            table.remove(self.statusMessages, 1)
            localX = true
        end
    end
    if localX then
        self:updateStatusMessages()
    end
    self:updateMarqueeAnimation(dt)
end
function InGameMenuMobileMapFrame:setTargetPointHotspotPosition(localX, localY)
    local worldX, worldZ = self.inGameMap:localToWorldPos(localX, localY)
    self.aiTargetMapHotspot:setWorldPosition(worldX, worldZ)
end
function InGameMenuMobileMapFrame:showContextInput(canEnter, canReset, canSetMarker, removeMarker, canBuy)
    local currentPageIsNotAI = self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.AI
    self.buttonEnterVehicle:setVisible(canEnter and currentPageIsNotAI)
    self.buttonResetVehicle:setVisible(canReset and currentPageIsNotAI)
    self.buttonSetMarker:setVisible(canSetMarker and currentPageIsNotAI)
    self.buttonBuyField:setVisible(canBuy and currentPageIsNotAI)
    self.buttonCancelJob:setVisible(self:getCanCancelJob())
    self.buttonGoToJob:setVisible(self:getCanGoTo())
    self.buttonCreateJob:setVisible(self:getCanCreateJob())
    self.buttonStartJob:setVisible(self:getCanStartJob())
    self.buttonSkipTask:setVisible(self:getCanSkipJobTask())
    self.buttonConfirmAITarget:setVisible(self:canConfirmAITarget())
    self:showContextMarker(canSetMarker, removeMarker)
    local buttonNeedsCancelText = self:getIsPicking()
    if not buttonNeedsCancelText then
        buttonNeedsCancelText = self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB
    end
    self.buttonCloseMap:setText(g_i18n:getText(buttonNeedsCancelText and InGameMenuMobileMapFrame.BUTTON_TEXTS.BUTTON_CANCEL or InGameMenuMobileMapFrame.BUTTON_TEXTS.BUTTON_CLOSE_MAP))
    self.buttonSelectInGame:setVisible(self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD or self:getIsPicking() or self.mode ~= InGameMenuMobileMapFrame.MODE_CREATE_JOB)
    self.buttonBox:invalidateLayout()
end
function InGameMenuMobileMapFrame:showContextInputAI(canGoTo, canCreateJob, canCancel, canSkipTask)
    local currentPageIsAI = self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.AI
    self.canGoTo = canGoTo and currentPageIsAI
    self.canCreateJob = canCreateJob and currentPageIsAI
    self.canCancel = canCancel and currentPageIsAI
    self.canSkipTask = canSkipTask and currentPageIsAI
end
function InGameMenuMobileMapFrame:showContextMarker(canSetMarker, removeMarker)
    if canSetMarker then
        local markerText
        if removeMarker then
            markerText = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.REMOVE_MARKER)
        else
            markerText = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.SET_MARKER)
        end
        self.buttonSetMarker:setText(markerText)
    end
end
function InGameMenuMobileMapFrame:getCanCancelJob()
    return self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and not self:getIsPicking() and (self.canCancel and g_currentMission:getHasPlayerPermission("hireAssistant")) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMobileMapFrame:getCanCreateJob()
    return self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and not self:getIsPicking() and (self.canCreateJob and g_currentMission:getHasPlayerPermission("hireAssistant")) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMobileMapFrame:getCanGoTo()
    return self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and not self:getIsPicking() and (self.canGoTo and g_currentMission:getHasPlayerPermission("hireAssistant")) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMobileMapFrame:getCanStartJob()
    return self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB and (not self:getIsPicking() and g_currentMission:getHasPlayerPermission("hireAssistant")) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMobileMapFrame:getCanSkipJobTask()
    return self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and not self:getIsPicking() and (self.canSkipTask and g_currentMission:getHasPlayerPermission("hireAssistant")) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMobileMapFrame:getCanCloseMap()
    return self.mode ~= InGameMenuMobileMapFrame.MODE_CREATE_JOB and not self:getIsPicking()
end
function InGameMenuMobileMapFrame:canConfirmAITarget()
    return self.lastInputHelpMode == GS_INPUT_HELP_MODE_TOUCH and (not self.aiTaskDialog.visible and (self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB or self:getIsPicking())) and not g_guidedTourManager:getIsTourRunning()
end
function InGameMenuMobileMapFrame:refreshContextInput()
    local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
    local canGoTo = false
    local canCreateJob = false
    local canCancel = false
    local canSkipTask = false
    if vehicle ~= nil and (g_currentMission.accessHandler:canPlayerAccess(vehicle) and vehicle.spec_aiJobVehicle ~= nil) then
        canCancel = vehicle:getIsAIActive()
        if canCancel then
            local job = vehicle:getJob()
            if job ~= nil and job:getCanSkipTask() then
                canSkipTask = true
            end
        else
            canGoTo = self.jobTypeInstances[AIJobType.GOTO]:getIsAvailableForVehicle(vehicle)
            canCreateJob = false
            for typeIndex, instance in pairs(self.jobTypeInstances) do
                if instance:getIsAvailableForVehicle(vehicle) and not self:getIsPicking() then
                    canCreateJob = true
                    break
                end
            end
        end
    end
    local job = not canCreateJob
    if job then
        job = g_currentMission.aiSystem:getAILimitedReached()
    end
    self.limitReachedWarning:setVisible(job)
    self.limitReachedWarningBg:setVisible(job)
    self:showContextInputAI(canGoTo, canCreateJob, canCancel, canSkipTask)
    self:showContextInput()
end
function InGameMenuMobileMapFrame:updateElementSizes()
    local leftInset = getSafeFrameInsets()
    self.leftInset = leftInset
    local sliderPosX = self.filterBoxContainer.absSize[1] - self.statusListSlider.absSize[1] * 1.5
    local buttonBoxHeight = self.buttonBox.absSize[2]
    local filterBoxWidth = self.pagingElement.size[1]
    self.mapPageSelector:setPosition(leftInset, nil)
    self.pagingElement:setPosition(leftInset, nil)
    self.roundedTopContainer:setSize(filterBoxWidth + leftInset, nil)
    self.roundedTopCenter:setSize(filterBoxWidth - 42 * g_pixelSizeX + leftInset, nil)
    self.buttonCloseMapContainer:setSize(filterBoxWidth + leftInset, nil)
    self.filterBoxContainer:setAnchors(0, 0, 0, 1 - self.pagingElement.absSize[2])
    self.filterBoxContainer:setPosition(leftInset, nil)
    local uv1 = self.filterBoxContainer.absSize[1] * g_screenWidth
    local uv2 = self.filterBoxContainer.absSize[2] * g_screenHeight
    self.filterBoxContainer:setImageUVs(nil, unpack(GuiUtils.getUVs({
        leftInset,
        0,
        uv1,
        uv2
    }, { 2048, 2048 })))
    self.filterBoxContainerBg:setAnchors(0, 0, 0, 1 - self.pagingElement.absSize[2])
    self.filterBoxContainerBg:updateAbsolutePosition()
    self.filterBoxContainerBg:setImageUVs(nil, unpack(GuiUtils.getUVs({
        0,
        0,
        uv1,
        uv2
    }, { 2048, 2048 })))
    self.inGameMap:setCursorCenter((self.filterBoxContainer.absSize[1] + self.leftInset) * 0.5, 0)
    self.buttonBox:setSize(1 - filterBoxWidth - leftInset - 50 * g_pixelSizeX)
    self.statusList:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 + self.statusSelector.position[2] - self.statusSelector.absSize[2] - 30 * g_pixelSizeY)
    self.statusList:updateAbsolutePosition()
    self.statusListSlider:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 + self.statusSelector.position[2] - self.statusSelector.absSize[2] - 30 * g_pixelSizeY)
    self.statusListSliderBar:setAnchors(0.5, 0.5, 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
    self.statusListSlider:setPosition(sliderPosX)
    self.statusListTopClipper:setPosition(0, self.statusList.absPosition[2] + self.statusList.absSize[2])
    self.statusListBottomClipper:setPosition(0, self.statusList.absPosition[2] - self.statusListBottomClipper.absSize[2])
    self.vehiclesList:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
    self.vehiclesList:updateAbsolutePosition()
    self.vehiclesListSlider:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
    self.vehiclesListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
    self.vehiclesListSlider:setPosition(sliderPosX)
    self.vehiclesListTopClipper:setPosition(0, self.vehiclesList.absPosition[2] + self.vehiclesList.absSize[2])
    self.vehiclesListBottomClipper:setPosition(0, self.vehiclesList.absPosition[2] - self.vehiclesListBottomClipper.absSize[2])
    self.pointsList:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, self.pointsFilterButtonBox.absPosition[2] - self.pointsFilterButtonBox.position[2] - 20 * g_pixelSizeY)
    self.pointsList:updateAbsolutePosition()
    self.pointsListSlider:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, self.pointsFilterButtonBox.absPosition[2] - self.pointsFilterButtonBox.position[2] - 20 * g_pixelSizeY)
    self.pointsListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
    self.pointsListSlider:setPosition(sliderPosX)
    self.pointsListTopClipper:setPosition(0, self.pointsList.absPosition[2] + self.pointsList.absSize[2])
    self.pointsListBottomClipper:setPosition(0, self.pointsList.absPosition[2] - self.pointsListBottomClipper.absSize[2])
    self.fieldsList:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
    self.fieldsList:updateAbsolutePosition()
    self.fieldsListSlider:setAnchors(0, 0, buttonBoxHeight + 20 * g_pixelSizeY, 1 - self.mapPageSelector.absSize[2] - 45 * g_pixelSizeY)
    self.fieldsListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
    self.fieldsListSlider:setPosition(sliderPosX)
    self.fieldsListTopClipper:setPosition(0, self.fieldsList.absPosition[2] + self.fieldsList.absSize[2])
    self.fieldsListBottomClipper:setPosition(0, self.fieldsList.absPosition[2] - self.fieldsListBottomClipper.absSize[2])
    self.aiWorkersList:setAnchors(0, 0, buttonBoxHeight + 15 * g_pixelSizeY, self.aiWorkersListTitle.absPosition[2] + 20 * g_pixelSizeY)
    self.aiWorkersList:updateAbsolutePosition()
    self.aiWorkersListSlider:setAnchors(0, 0, buttonBoxHeight + 15 * g_pixelSizeY, self.aiWorkersListTitle.absPosition[2] + 20 * g_pixelSizeY)
    self.aiWorkersListSliderBar:setAnchors(0.5, 0.5, 0 + 4 * g_pixelSizeY, 1 - 4 * g_pixelSizeY)
    self.aiWorkersListSlider:setPosition(sliderPosX)
    self.aiWorkersListTopClipper:setPosition(0, self.aiWorkersList.absPosition[2] + self.aiWorkersList.absSize[2])
    self.aiWorkersListBottomClipper:setPosition(0, self.aiWorkersList.absPosition[2] - self.aiWorkersListBottomClipper.absSize[2])
end
function InGameMenuMobileMapFrame:setInGameMap(inGameMap)
    self.inGameMapBase = inGameMap
    self.inGameMap:setIngameMap(inGameMap)
    if inGameMap ~= nil then
        self.customFilterFarmlands = inGameMap:createCustomFilter(false)
    end
end
function InGameMenuMobileMapFrame:setTerrainSize(terrainSize)
    self.inGameMap:setTerrainSize(terrainSize)
end
function InGameMenuMobileMapFrame:setClient(client)
    self.client = client
end
function InGameMenuMobileMapFrame:setPlayerFarm(playerFarm)
    self.playerFarm = playerFarm
end
function InGameMenuMobileMapFrame.assignGroundStatusColors(_, colorElement, statusColors, listElement)
    local partWidth = colorElement.absSize[1] / #statusColors
    colorElement:setSize(partWidth, nil)
    local y = InGameMenuMobileMapFrame.STATUS_BG_COLOR_UVS
    local x, y, width, height = unpack(y)
    local width = width / #statusColors
    local imageUVs = GuiUtils.getUVs({
        x,
        y,
        width,
        height
    }, { 2048, 2048 })
    colorElement:setImageUVs(nil, unpack(imageUVs))
    local clones = GuiOverlay.setSelectedColor
    local i = statusColors[1]
    clones(colorElement.overlay, unpack(i))
    if #statusColors > 1 then
        local clones = {}
        local i = 2
        for i = i, #statusColors do
            local newPart = colorElement:clone()
            table.insert(clones, newPart)
            newPart:setSize(partWidth, nil)
            newPart:setImageUVs(nil, unpack((GuiUtils.getUVs({
                x + width * (i - 1),
                y,
                width,
                height
            }, { 2048, 2048 }))))
            newPart:setPosition((i - 1) * partWidth, 0)
            GuiOverlay.setSelectedColor(newPart.overlay, unpack(statusColors[i]))
            function newPart.getOverlayState()
                -- upvalues: (copy) listElement
                return listElement.isStatusEnabled and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
            end
        end
        for newPart, clone in ipairs(clones) do
            colorElement:addElement(clone)
        end
    end
end
function InGameMenuMobileMapFrame:resetUIDeadzones()
    self.inGameMap:clearCursorDeadzones()
    if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB and not self:getIsPicking() then
        self.inGameMap:addCursorDeadzone(0, 0, 1, 1)
    else
        self.inGameMap:addCursorDeadzone(0, 0, self.filterBoxContainer.absPosition[1] + self.filterBoxContainer.absSize[1], self.filterBoxContainer.absPosition[2] + self.filterBoxContainer.absSize[2])
    end
end
function InGameMenuMobileMapFrame:onOverviewOverlayFinished(overlayId)
    self.foliageStateOverlay = overlayId
    self.foliageStateOverlayIsReady = true
    self.dynamicMapImageLoadingBg:setVisible(false)
end
function InGameMenuMobileMapFrame:generateOverviewOverlay()
    if self.foliageStateOverlay == nil then
        self.foliageStateOverlayIsReady = false
    end
    self.dynamicMapImageLoadingBg:setVisible(true)
    self.dynamicMapImageLoadingBg:setSize(self.dynamicMapImageLoading.absSize[1] + 80 * g_pixelSizeX)
    for buttonIndex, fruitIndex in pairs(self.fruitTypeFilterMapping) do
        ({})[fruitIndex] = self.fruitTypeFilter[buttonIndex]
    end
    local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
    if mapOverlayGenerator ~= nil then
        local currentMapFilter = self.statusSelector:getState()
        if currentMapFilter == InGameMenuMobileMapFrame.MAP_FRUIT_TYPE then
            mapOverlayGenerator:generateFruitTypeOverlay(self.overviewOverlayFinishedCallback, mappedFruitTypeFilters)
            return
        end
        if currentMapFilter == InGameMenuMobileMapFrame.MAP_GROWTH then
            mapOverlayGenerator:generateGrowthStateOverlay(self.overviewOverlayFinishedCallback, self.growthStateFilter, mappedFruitTypeFilters)
            return
        end
        if currentMapFilter == InGameMenuMobileMapFrame.MAP_SOIL then
            mapOverlayGenerator:generateSoilStateOverlay(self.overviewOverlayFinishedCallback, self.soilStateFilter)
        end
    end
end
function InGameMenuMobileMapFrame:setMode(mode)
    self.mode = mode
    if mode ~= InGameMenuMobileMapFrame.MODE_NONE then
        self:generateOverviewOverlay()
    end
    self.inGameMapBase:restoreDefaultFilter()
    self:resetUIDeadzones()
end
function InGameMenuMobileMapFrame:setMapSelectionItem(hotspot)
    self.inGameMapBase:setSelectedHotspot(hotspot)
    self.selectedField = nil
    g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
    if self.currentHotspot ~= nil then
        self.currentHotspot:setBlinking(false)
    end
    local canEnter = false
    local canReset = false
    local canSetMarker = false
    local removeMarker = false
    local canBuy = false
    local name = nil
    local isHorse = nil
    if hotspot == nil then
        self.currentHotspot = nil
    else
        local brand = InGameMenuMapUtil.getHotspotVehicle(hotspot)
        if brand == nil then
            if hotspot:isa(PlaceableHotspot) then
                name = hotspot:getName()
                if name ~= nil then
                    if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.POINTS and self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.AI then
                        self.blockListSelectionEvents = true
                        self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.POINTS, true)
                        self.blockListSelectionEvents = false
                    end
                    self.currentHotspot = hotspot
                    self.currentList = mapPageSelectorState == InGameMenuMobileMapFrame.PAGE_ID.AI and self.aiWorkersList or self.pointsList
                    local brand = hotspot:getPlaceable()
                    if brand ~= nil then
                        local horse = brand:getImageFilename()
                        self.pointDetailsImage:setImageFilename(horse)
                        self.pointDetailsName:setText(name)
                        self.aiDetailsImage:setImageFilename(horse)
                        self.aiDetailsBrand:setVisible(false)
                        self.aiDetailsName:setText(name)
                        if brand.storeItem ~= nil then
                            local horse = g_currentMission.slotSystem
                            horse.slotLimit = math.huge
                            local i = g_shopController:makeDisplayItem(brand.storeItem)
                            self:setDetailAttributes(brand.storeItem, i)
                            horse.slotLimit = horse.slotLimit
                        end
                    end
                    canSetMarker = true
                    removeMarker = g_currentMission.currentMapTargetHotspot == hotspot
                end
            elseif hotspot:isa(FieldHotspot) then
                if mapPageSelectorState ~= InGameMenuMobileMapFrame.PAGE_ID.FIELDS then
                    self.blockListSelectionEvents = true
                    self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.FIELDS, true)
                    self.blockListSelectionEvents = false
                    if self.currentHotspot ~= nil then
                        self.currentHotspot:setBlinking(false)
                    end
                end
                self.currentHotspot = hotspot
                self.currentList = self.fieldsList
                local brand = hotspot:getField()
                canBuy = not brand:getHasOwner()
                self.selectedField = brand:getId()
            end
        else
            if mapPageSelectorState ~= InGameMenuMobileMapFrame.PAGE_ID.VEHICLES and mapPageSelectorState ~= InGameMenuMobileMapFrame.PAGE_ID.AI then
                self.blockListSelectionEvents = true
                self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.VEHICLES, true)
                self.blockListSelectionEvents = false
            end
            self.currentHotspot = hotspot
            self.currentList = mapPageSelectorState == InGameMenuMobileMapFrame.PAGE_ID.AI and self.aiWorkersList or self.vehiclesList
            name = brand:getName()
            local brand = brand:getImageFilename()
            if g_currentMission.tourIconsBase == nil or g_currentMission.tourIconsBase.visible == false then
                canEnter = false
                if brand.getIsEnterableFromMenu ~= nil then
                    canEnter = brand:getIsEnterableFromMenu()
                end
                if not self.isResetPending and (brand:getCanBeReset() and hotspot:getCategory() ~= MapHotspot.CATEGORY_AI) then
                    canReset = true
                end
            end
            isHorse = brand.spec_rideable ~= nil
            self.vehicleDetailsImage:setImageFilename(brand)
            local brand = g_brandManager:getBrandByIndex(brand:getBrand())
            self.vehicleDetailsBrand:setImageFilename(brand.image)
            self.vehicleDetailsName:setText(name)
            self.vehicleDetailsBrand:setVisible(not isHorse)
            self.vehicleDetailsDailyRiding:setVisible(isHorse)
            if isHorse then
                local i = brand:getCluster():getRidingFactor() * 100
                local dailyRiding = math.floor(i)
                self.vehicleDetailsDailyRiding:setText(string.format("%s: %s%%", g_i18n:getText("ui_horseDailyRiding"), dailyRiding))
            end
            self.aiDetailsImage:setImageFilename(brand)
            self.aiDetailsBrand:setVisible(true)
            self.aiDetailsBrand:setImageFilename(brand.image)
            self.aiDetailsName:setText(name)
            for i, attachableContainer in pairs(self.vehicleDetailsAttachables) do
                local attachable = brand.childVehicles[i]
                if attachable == nil then
                    attachableContainer:setVisible(false)
                else
                    attachableContainer:getDescendantByName("text"):setText(attachable:getName())
                    local attachableIcon = attachableContainer:getDescendantByName("icon")
                    attachableIcon:setImageUVs(nil, unpack(attachable.mapHotspot.icon.uvs))
                    attachableContainer:setVisible(true)
                end
            end
            local i = #brand.childVehicles
            local dailyRiding = 1
            for i = i, 3, dailyRiding do
                self.vehicleDetailsAttachables[i]:setVisible(false)
            end
        end
    end
    if self.currentHotspot ~= nil then
        self.currentHotspot:setBlinking(true)
    end
    if isHorse then
        self.buttonEnterVehicle:setText(string.format(g_i18n:getText("action_rideAnimal"), name))
        self.buttonEnterVehicle.touchIcon.uvs = GuiUtils.getUVs(InGameMenuMobileMapFrame.UV.BUTTON_RIDE_HORSE)
    else
        self.buttonEnterVehicle:setText(g_i18n:getText("button_enterVehicle"))
        self.buttonEnterVehicle.touchIcon.uvs = GuiUtils.getUVs(InGameMenuMobileMapFrame.UV.BUTTON_ENTER_VEHICLE)
    end
    self.buttonEnterVehicle:setTextSize(self.buttonsResizeTextSize)
    self:refreshContextInput()
    self:showContextInput(canEnter, canReset, canSetMarker, removeMarker, canBuy)
    self.canEnter = canEnter
    self.canReset = canReset
    self.canSetMarker = canSetMarker
    self.removeMarker = removeMarker
    self.canBuy = canBuy
end
function InGameMenuMobileMapFrame:showDetailsBox(showBox)
    local detailsBox = self.currentList.detailsBox
    if not showBox then
        showBox = false
        if self.currentList == self.aiWorkersList then
            showBox = self.currentHotspot ~= nil
        end
    end
    if detailsBox ~= nil then
        detailsBox:setVisible(showBox)
    end
    local showList = not showBox
    if not showList then
        showList = true
        if detailsBox ~= nil then
            showList = self.currentList == self.aiWorkersList
        end
    end
    self.currentList:setVisible(showList)
    self.currentList:updateScrollClippers()
    if self.currentList.sliderElement ~= nil and (self.currentList.sliderElement.needsSlider and self.currentList.totalItemCount > 0) then
        self.currentList.sliderElement.parent:setVisible(showList)
    end
    if self.currentList == self.pointsList then
        self.pointsFilterButtonBox:setVisible(showList)
    end
end
function InGameMenuMobileMapFrame:showActionMessage(text, locaKey)
    local needBg = false
    if text == nil then
        if locaKey == nil then
            self.actionMessageBg:setVisible(false)
        else
            self.actionMessage:setVisible(true)
            self.actionMessage:setLocaKey(locaKey)
            needBg = true
        end
    else
        self.actionMessage:setVisible(true)
        self.actionMessage:setText(text)
        needBg = true
    end
    if needBg then
        self.actionMessageBg:setVisible(true)
        self.actionMessageBg:setSize(self.actionMessage.absSize[1] + 80 * g_pixelSizeX)
    end
end
function InGameMenuMobileMapFrame:setColorBlindMode(isActive)
    if isActive ~= self.isColorBlindMode then
        self.isColorBlindMode = isActive
        self.statusList:reloadData()
        self:generateOverviewOverlay()
    end
end
function InGameMenuMobileMapFrame:setActiveJobTypeSelection(jobTypeIndex)
    if self.currentJob == nil or jobTypeIndex ~= self.currentJob.jobTypeIndex then
        local i = #self.aiTaskDialogLayout.elements
        local farmId = 2
        for i = i, farmId, -1 do
            self.aiTaskDialogLayout.elements[i]:delete()
        end
        self.currentJob = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)
        local farmId = 1
        if g_localPlayer ~= nil then
            farmId = g_localPlayer.farmId
        end
        self.currentJob:applyCurrentState(self.currentJobVehicle, g_currentMission, farmId, false)
        self.currentJobElements = {}
        for _, group in ipairs(self.currentJob:getGroupedParameters()) do
            for _, item in ipairs(group:getParameters()) do
                local element = nil
                local parameterType = item:getType()
                if parameterType == AIParameterType.TEXT then
                    break
                end
                if parameterType == AIParameterType.POSITION then
                    element = self.aiTaskDialogPositionTemplate:clone(self.aiTaskDialogLayout)
                    element:getDescendantByName("title"):setText(group:getTitle())
                    element:getDescendantByName("button").aiParameter = item
                elseif parameterType == AIParameterType.POSITION_ANGLE then
                    element = self.aiTaskDialogPositionRotationTemplate:clone(self.aiTaskDialogLayout)
                    element:getDescendantByName("title"):setText(group:getTitle())
                    element:getDescendantByName("button").aiParameter = item
                elseif parameterType == AIParameterType.SELECTOR or (parameterType == AIParameterType.UNLOADING_STATION or (parameterType == AIParameterType.LOADING_STATION or parameterType == AIParameterType.FILLTYPE)) then
                    element = self.aiTaskDialogMultiOptionTemplate:clone(self.aiTaskDialogLayout)
                    element:setDataSource(item)
                    element:setLabel(group:getTitle())
                end
                element.aiParameter = item
                element:setDisabled(not item:getCanBeChanged())
                table.insert(self.currentJobElements, element)
            end
        end
        self:updateParameterValueTexts()
        self:validateParameters()
        self.aiTaskDialogLayout:invalidateLayout()
    end
    self:refreshContextInput()
end
function InGameMenuMobileMapFrame:updateVehicles()
    self.vehicles = {
        {},
        {}
    }
    if g_localPlayer ~= nil then
        for _, vehicle in ipairs(g_currentMission.vehicleSystem.vehicles) do
            if g_currentMission.accessHandler:canPlayerAccess(vehicle) then
                if vehicle:getShowInVehiclesOverview() then
                    local item = {
                        ["vehicle"] = vehicle
                    }
                    local name = vehicle:getName()
                    local brand = g_brandManager:getBrandByIndex(vehicle:getBrand())
                    if brand ~= nil then
                    end
                    item.name = name
                    local section = SpecializationUtil.hasSpecialization(Drivable, vehicle.specializations) and 1 or 2
                    if self.vehicles[section] == nil then
                        self.vehicles[section] = {}
                    end
                    table.insert(self.vehicles[section], item)
                elseif SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations) then
                    local item = {
                        ["vehicle"] = vehicle,
                        ["name"] = vehicle:getName()
                    }
                    if self.vehicles[3] == nil then
                        self.vehicles[3] = {}
                    end
                    table.insert(self.vehicles[3], item)
                end
            end
        end
    end
    local function sortFunction(vehicle1, vehicle2)
        if vehicle1 == nil then
            return true
        end
        if vehicle2 == nil then
            return false
        end
        return vehicle1.name < vehicle2.name
    end
    for _ = 1, #self.vehicles do
        table.sort(self.vehicles[_], sortFunction)
    end
end
function InGameMenuMobileMapFrame:updatePoints()
    self.hotspotsSorted = {}
    for _, hotspot in pairs(self.inGameMap.ingameMap.hotspots) do
        if hotspot:isa(PlaceableHotspot) then
            local section = (function(hotspot)
                if hotspot == nil or hotspot.placeable == nil then
                    return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER
                elseif SpecializationUtil.hasSpecialization(PlaceableProductionPoint, hotspot.placeable.specializations) then
                    return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS
                elseif SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, hotspot.placeable.specializations) then
                    return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS
                elseif SpecializationUtil.hasSpecialization(PlaceableSellingStation, hotspot.placeable.specializations) or SpecializationUtil.hasSpecialization(PlaceableBuyingStation, hotspot.placeable.specializations) then
                    return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING
                else
                    return InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER
                end
            end)(hotspot)
            if self.hotspotsSorted[section] == nil then
                self.hotspotsSorted[section] = {}
            end
            table.insert(self.hotspotsSorted[section], hotspot)
        end
    end
    for _ = 1, #self.hotspotsSorted do
        table.sort(self.hotspotsSorted[_], function(hotspot1, hotspot2)
            if hotspot1 == nil then
                return true
            end
            if hotspot2 == nil then
                return false
            end
            return hotspot1:getName() < hotspot2:getName()
        end)
    end
    self:updatePointsFilterMapping()
end
function InGameMenuMobileMapFrame:updatePointsFilterMapping()
    self.hotspotFiltersMapping = {}
    local numActive = 1
    for i, isActive in pairs(self.hotspotFiltersActive) do
        if isActive then
            self.hotspotFiltersMapping[numActive] = i
            numActive = numActive + 1
        end
    end
    if numActive == 1 then
        self.pointsListSlider:setVisible(false)
        self:setMapSelectionItem(nil)
    else
        self.pointsListSlider:setVisible(self.pointsList.visible)
    end
    self.pointsList:reloadData()
end
function InGameMenuMobileMapFrame:updateFields()
    self.fields = {}
    for _, field in pairs(g_fieldManager:getFields()) do
        local section = g_farmlandManager:getFarmlandOwner(field.farmland.id) == g_currentMission:getFarmId() and 1 or 2
        if self.fields[section] == nil then
            self.fields[section] = {}
        end
        table.insert(self.fields[section], field)
    end
    for _ = 1, #self.fields do
        table.sort(self.fields[_], function(field1, field2)
            return field1:getId() < field2:getId()
        end)
    end
end
function InGameMenuMobileMapFrame:generateJobTypes()
    for _, jobType in pairs(AIJobType) do
        self.jobTypeInstances[jobType] = g_currentMission.aiJobTypeManager:createJob(jobType)
    end
end
function InGameMenuMobileMapFrame:startGoToJob(vehicle, destX, destZ, angle)
    local job = self.jobTypeInstances[AIJobType.GOTO]
    job.vehicleParameter:setVehicle(vehicle)
    job.positionAngleParameter:setPosition(destX, destZ)
    job.positionAngleParameter:setAngle(angle)
    job:setValues()
    local success, errorMessage = job:validate(g_localPlayer.farmId)
    if not success then
        InfoDialog.show(tostring(errorMessage), nil, nil, DialogElement.TYPE_WARNING)
        return false
    end
    FocusManager:setFocus(self.aiWorkersList)
    self:tryStartJob(job, g_localPlayer.farmId, function(state)
        -- upvalues: (copy) self
        if state == AIJob.START_SUCCESS then
            self.jobTypeInstances[AIJobType.GOTO] = g_currentMission.aiJobTypeManager:createJob(AIJobType.GOTO)
        end
    end)
    return true
end
function InGameMenuMobileMapFrame:getIsPicking()
    return self.isPickingRotation or self.isPickingLocation
end
function InGameMenuMobileMapFrame:executePickingCallback(...)
    self.inGameMap:setHotspotSelectionActive(true)
    self.isPickingLocation = false
    self.isPickingRotation = false
    self.inGameMap:unlockMapMovement()
    self:resetUIDeadzones()
    local cb = self.pickingCallback
    self.pickingCallback = nil
    if cb ~= nil then
        cb(...)
    end
end
function InGameMenuMobileMapFrame:startPickPosition(parameter, callback)
    self.inGameMap:setHotspotSelectionActive(false)
    self.inGameMap:setIsCursorAvailable(false)
    self.isPickingLocation = true
    self.hasPickedLocationTouch = false
    self:showActionMessage(nil, "ui_ai_pickTargetLocation")
    self:resetUIDeadzones()
    g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
    g_currentMission:addMapHotspot(self.aiTargetMapHotspot)
    function self.pickingCallback(success, x, z)
        -- upvalues: (copy) self, (copy) parameter, (copy) callback
        self:showActionMessage()
        self.inGameMap:setIsCursorAvailable(true)
        self.hasPickedRotationTouch = false
        if success then
            parameter:setValue(x, z)
            self.aiTargetMapHotspot:setWorldPosition(x, z)
        end
        callback(success, x, z, parameter)
        self:validateParameters()
    end
end
function InGameMenuMobileMapFrame:startPickPositionAndRotation(parameter, callback)
    self.isPickingLocation = true
    self.hasPickedLocationTouch = false
    self.inGameMap:setHotspotSelectionActive(false)
    self.inGameMap:setIsCursorAvailable(false)
    self:showActionMessage(nil, "ui_ai_pickTargetLocation")
    self:resetUIDeadzones()
    g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
    g_currentMission:addMapHotspot(self.aiTargetMapHotspot)
    function self.pickingCallback(success, x, z)
        -- upvalues: (copy) self, (copy) parameter, (copy) callback
        self:showActionMessage()
        self.inGameMap:setIsCursorAvailable(true)
        self.hasPickedRotationTouch = false
        if success then
            self.inGameMap:setHotspotSelectionActive(false)
            self.inGameMap:setIsCursorAvailable(false)
            self.aiTargetMapHotspot:setWorldPosition(x, z)
            self.isPickingRotation = true
            self.inGameMap:lockMapMovement()
            self.pickingRotationOrigin = { x, z }
            self.pickingRotationSnapAngle = parameter:getSnappingAngle()
            self:showActionMessage(nil, "ui_ai_pickTargetRotation")
            self:resetUIDeadzones()
            function self.pickingCallback(successRotation, angle)
                -- upvalues: (ref) self, (ref) parameter, (copy) x, (copy) z, (ref) callback
                self:showActionMessage()
                self.inGameMap:setIsCursorAvailable(true)
                if successRotation then
                    parameter:setPosition(x, z)
                    parameter:setAngle(angle)
                    local convertedAngle = parameter:getAngle()
                    if self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_TOUCH then
                        self.aiTargetMapHotspot:setWorldRotation(convertedAngle + 3.141592653589793)
                    end
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
function InGameMenuMobileMapFrame:onClickHotspot(_, hotspot)
    if self.mode ~= InGameMenuMobileMapFrame.MODE_CREATE_JOB then
        self:setMapSelectionItem(hotspot)
        self:showDetailsBox(true)
        if InGameMenuMobileMapFrame.MODE_OVERVIEW or self.mode == InGameMenuMobileMapFrame.MODE_NONE and self.currentHotspot ~= hotspot then
            self:selectHotspotInList(hotspot, self.currentList)
        end
        self:resizeButtonTexts()
    end
end
function InGameMenuMobileMapFrame:onClickMap(_, worldX, worldZ)
    if (self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW or self.mode == InGameMenuMobileMapFrame.MODE_NONE) and self.currentList.totalItemCount > 0 then
        self:showDetailsBox(false)
        FocusManager:setFocus(self.currentList)
    elseif self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE or self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
        if self.isPickingLocation then
            if self.lastInputHelpMode == GS_INPUT_HELP_MODE_TOUCH then
                local localX, localY = self.inGameMap:getLocalPosition(self.lastTouchPosX, self.lastTouchPosY)
                self:setTargetPointHotspotPosition(localX, localY)
            elseif not self.hasPickedLocationTouch then
                self:executePickingCallback(true, worldX, worldZ)
            end
        elseif self.isPickingRotation then
            local localX = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])
            if self.lastInputHelpMode == GS_INPUT_HELP_MODE_TOUCH then
                self.aiTargetMapHotspot:setWorldRotation(localX + 3.141592653589793)
                self.hasPickedRotationTouch = true
            else
                self.inGameMap:panToHotspot(self.aiTargetMapHotspot)
                self:executePickingCallback(true, localX)
            end
        end
        self:refreshContextInput()
    end
end
function InGameMenuMobileMapFrame:selectHotspotInList(hotspot, hotspotList)
    local sectionIndex, index = self:findListItemForHotspot(hotspot, hotspotList)
    self.blockListSelectionEvents = true
    hotspotList:setSelectedItem(sectionIndex, index)
    self.blockListSelectionEvents = self.blockListSelectionEvents
end
function InGameMenuMobileMapFrame:findListItemForHotspot(hotspot, hotspotList)
    local list = self.vehicles
    if hotspotList == self.pointsList then
        list = self.hotspotsSorted
    elseif hotspotList == self.fieldsList then
        list = self.fields
    end
    for sectionIndex, section in pairs(list) do
        local index = 1
        for index = index, #section do
            if hotspotList == self.vehiclesList then
                if hotspot ~= nil and self.vehicles[sectionIndex][index].vehicle == hotspot.vehicle then
                    return sectionIndex, index
                end
            elseif hotspotList == self.pointsList then
                if hotspot == self.hotspotsSorted[self.hotspotFiltersMapping[sectionIndex]][index] then
                    return sectionIndex, index
                end
            elseif hotspotList == self.fieldsList then
                if hotspot ~= nil and hotspot.field == self.fields[sectionIndex][index] then
                    return sectionIndex, index
                end
            end
        end
    end
    return nil, nil
end
function InGameMenuMobileMapFrame:resizeButtonTexts()
    if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
        local totalButtonWidth = 0
        if self.buttonEnterVehicle.visible then
            totalButtonWidth = self.buttonSelectInGame.absSize[1] + self.buttonEnterVehicle.absSize[1] + self.buttonResetVehicle.absSize[1] + self.buttonBox.elementSpacing * 2
        elseif self.buttonGoToJob.visible then
            totalButtonWidth = self.buttonSelectInGame.absSize[1] + self.buttonGoToJob.absSize[1] + self.buttonCreateJob.absSize[1] + self.buttonBox.elementSpacing * 2
        else
            for _, button in pairs(self.buttonsResizeNeeded) do
                button:setTextSize(button.defaultTextSize)
            end
            self.buttonsResizeTextSize = self.buttonSelectInGame.defaultTextSize
        end
        while self.buttonBox.absSize[1] <= totalButtonWidth do
            for _, button in pairs(self.buttonsResizeNeeded) do
                button:setTextSize(button.textSize - 1 * g_pixelSizeY)
            end
            self.buttonsResizeTextSize = self.buttonSelectInGame.textSize
            if self.buttonEnterVehicle.visible then
                totalButtonWidth = self.buttonSelectInGame.absSize[1] + self.buttonEnterVehicle.absSize[1] + self.buttonResetVehicle.absSize[1] + self.buttonBox.elementSpacing * 2
            elseif self.buttonGoToJob.visible then
                totalButtonWidth = self.buttonSelectInGame.absSize[1] + self.buttonGoToJob.absSize[1] + self.buttonCreateJob.absSize[1] + self.buttonBox.elementSpacing * 2
            end
        end
    else
        for _, _ in pairs(self.buttonsResizeNeeded) do
            _:setTextSize(_.defaultTextSize)
        end
        self.buttonsResizeTextSize = self.buttonSelectInGame.defaultTextSize
    end
end
function InGameMenuMobileMapFrame:onMoneyChanged(farmId, newBalance)
    if farmId == self.playerFarm.farmId and self.balanceText ~= nil then
        self.balanceText:setValue(newBalance)
        local requiredProfile = InGameMenuMobileMapFrame.PROFILE.MONEY_VALUE_NEUTRAL
        if math.floor(newBalance) <= -1 then
            requiredProfile = InGameMenuMobileMapFrame.PROFILE.MONEY_VALUE_NEGATIVE
        end
        self.balanceText:applyProfile(requiredProfile)
        self.balanceText.parent:invalidateLayout()
    end
end
function InGameMenuMobileMapFrame:onAIJobStarted(job, _)
    self.blockListSelectionEvents = true
    self.aiWorkersList:reloadData()
    FocusManager:setFocus(self.aiWorkersList)
    self.blockListSelectionEvents = false
    local hotspots = g_currentMission.hud:getIngameMap().hotspots
    local aiHotspot = nil
    for _, hotspot in pairs(hotspots) do
        local vehicle = InGameMenuMapUtil.getHotspotVehicle(hotspot)
        if vehicle ~= nil and vehicle.getJob ~= nil then
            local vehicleJob = vehicle:getJob()
            if vehicleJob ~= nil and (hotspot:isa(AIHotspot) and job.jobId == vehicleJob.jobId) then
                aiHotspot = hotspot
            end
        end
    end
    self:setMapSelectionItem(aiHotspot)
    InfoDialog.show(g_i18n:getText("ai_startStateSuccess"))
end
function InGameMenuMobileMapFrame:onAIJobRemoved(_)
    self.aiWorkersList:reloadData()
end
function InGameMenuMobileMapFrame:onAITaskSkipped()
    self:refreshContextInput()
end
function InGameMenuMobileMapFrame:onAIJobStopped(job, aiMessage)
    if aiMessage ~= nil and (job ~= nil and (g_localPlayer ~= nil and job.startedFarmId == g_localPlayer.farmId)) then
        self:addStatusMessage((aiMessage:getMessage(job)))
    end
end
function InGameMenuMobileMapFrame:onInsetsChanged()
    self:updateElementSizes()
end
function InGameMenuMobileMapFrame:onDrawPostIngameMap()
    if self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW and self.foliageStateOverlayIsReady then
        local width, height = self.inGameMapBase.fullScreenLayout:getMapSize()
        local x, y = self.inGameMapBase.fullScreenLayout:getMapPosition()
        local filterBoxWidth = self.filterBoxContainer.absSize[1] + self.leftInset
        local pixWidth = width * g_screenWidth
        local pixHeight = height * g_screenHeight
        local deltaX = filterBoxWidth * g_screenWidth - x * g_screenWidth
        local u1, v1, u2, v2, u3, v3, u4, v4 = unpack(GuiUtils.getUVs({
            deltaX,
            0,
            pixWidth + deltaX,
            pixHeight
        }, { pixWidth, pixHeight }))
        setOverlayUVs(self.foliageStateOverlay, u1, v1, u2, v2, u3, v3, u4, v4)
        renderOverlay(self.foliageStateOverlay, filterBoxWidth, y, width + filterBoxWidth - x, height)
    end
end
function InGameMenuMobileMapFrame:validateParameters()
    local isValid = true
    local errorText = ""
    if self.currentJob ~= nil then
        self.currentJob:setValues()
        isValid, errorText = self.currentJob:validate(g_localPlayer.farmId)
        self:updateWarnings()
    end
    self.aiTaskDialogErrorMessage:setText(errorText)
    self.aiTaskDialogErrorMessageBg:setSize(self.aiTaskDialogErrorMessage.absSize[1] + 80 * g_pixelSizeX)
    self.aiTaskDialogErrorMessageBg:setVisible(not isValid)
end
function InGameMenuMobileMapFrame:updateWarnings()
    for _, element in ipairs(self.currentJobElements) do
        local invalidElement = element:getDescendantByName("invalid")
        if invalidElement ~= nil then
            invalidElement:setVisible(not element.aiParameter:getIsValid())
        end
    end
end
function InGameMenuMobileMapFrame:addStatusMessage(message)
    table.insert(self.statusMessages, {
        ["removeTime"] = g_time + 5000,
        ["text"] = message
    })
    self:updateStatusMessages()
end
function InGameMenuMobileMapFrame:updateStatusMessages()
    local text = ""
    for _, message in ipairs(self.statusMessages) do

    end
    self.statusMessage:setText(text)
    local height = getTextLength(self.statusMessage.textSize, text, 99999) > 0
    self.statusMessageBg:setVisible(height)
    setTextBold(true)
    local width = getTextWidth(self.statusMessage.textSize, self.statusMessage.text) + 20 * g_pixelSizeX
    local height = getTextHeight(textSize, self.statusMessage.text) + 14 * g_pixelSizeX
    setTextBold(false)
    self.statusMessageBg:setSize(width, height)
    self.statusMessageBg:setPosition(nil, self.statusMessage.absPosition[2] + textSize * 0.5 - height * 0.5)
end
function InGameMenuMobileMapFrame:assignItemFillTypesData(baseIconProfile, iconFilenames, detailsIndex)
    local parentBox = self.pointDetailsIconsLayout[detailsIndex]
    if #self.pointDetailsValue < detailsIndex or #iconFilenames == 0 then
        parentBox.parent:setVisible(false)
        return detailsIndex
    end
    local totalWidth = 0
    self.pointDetailsIcon[detailsIndex]:applyProfile(baseIconProfile)
    self.pointDetailsIcon[detailsIndex]:setVisible(true)
    parentBox.parent:setVisible(true)
    self.pointDetailsValue[detailsIndex]:setVisible(false)
    local i = 1
    for i = i, #iconFilenames do
        local icon = self.pointDetailsIconTemplate:clone(parentBox)
        icon:setVisible(true)
        table.insert(self.clonedElements, icon)
        icon:applyProfile("inGameMenuMobileMapDetailsIconTemplate")
        icon:setImageFilename(iconFilenames[i])
    end
    parentBox.parent:setSize(math.min(self.pointDetailsLayout.absSize[1] * 0.75, totalWidth), nil)
    parentBox:setPosition(0)
    parentBox:setSize(totalWidth, nil)
    parentBox:invalidateLayout()
    if parentSize < totalWidth then
        self.marqueeBoxes[parentBox] = 0
    else
        self.marqueeBoxes[parentBox] = nil
    end
    return detailsIndex + 1
end
function InGameMenuMobileMapFrame:assignItemTextData(_, displayItem)
    local numDetailsUsed = 0
    local i = 1
    for i = i, #self.pointDetailsValue do
        local detailsVisible = false
        if displayItem ~= nil and i <= #displayItem.attributeValues then
            local profile = displayItem.attributeValues[i]
            local value = tostring(profile)
            local profile = displayItem.attributeIconProfiles[i]
            if profile ~= nil and profile ~= "" then
                self.pointDetailsValue[i]:setText(value)
                self.pointDetailsValue[i]:updateAbsolutePosition()
                if profile:startsWith("shopListAttributeIcon") then
                    profile = "inGameMenuMobileMapDetailsIcon" .. profile:sub(22)
                end
                self.pointDetailsIcon[i]:applyProfile(profile)
                detailsVisible = false
                if value ~= nil then
                    detailsVisible = value ~= ""
                end
            end
        end
        self.pointDetailsValue[i]:setVisible(detailsVisible)
        self.pointDetailsIcon[i]:setVisible(detailsVisible)
        self.pointDetailsIconsLayout[i].parent:setVisible(false)
        if detailsVisible then
        end
    end
    return numDetailsUsed
end
function InGameMenuMobileMapFrame:setDetailAttributes(storeItem, displayItem)
    for k, clone in pairs(self.clonedElements) do
        clone:delete()
        self.clonedElements[k] = nil
    end
    for k, clone in pairs(self.marqueeBoxes) do
        self.marqueeBoxes[k] = nil
    end
    local numDetailsUsed = self:assignItemTextData(storeItem, displayItem)
    if displayItem ~= nil then
        local nextDetailsIndex = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconFillTypes", displayItem.fillTypeIconFilenames, numDetailsUsed + 1)
        local nextDetailsIndex = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconFillTypes", displayItem.foodFillTypeIconFilenames, nextDetailsIndex)
        local nextDetailsIndex = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconInput", displayItem.prodPointInputFillTypeIconFilenames, nextDetailsIndex)
        local nextDetailsIndex = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconOutput", displayItem.prodPointOutputFillTypeIconFilenames, nextDetailsIndex)
        local nextDetailsIndex = self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconInput", displayItem.sellingStationFillTypesIconFilenames, nextDetailsIndex)
        self:assignItemFillTypesData("inGameMenuMobileMapDetailsIconOutput", displayItem.buyingStationFillTypesIconFilenames, nextDetailsIndex)
    end
    self.pointDetailsLayout:invalidateLayout()
end
function InGameMenuMobileMapFrame:updateMarqueeAnimation(dt)
    for box, boxTime in pairs(self.marqueeBoxes) do
        local visibleWidth = box.parent.absSize[1]
        local scrollAmount = box.absSize[1] - visibleWidth
        local scrollDuration = 9000 * ((scrollAmount / visibleWidth - 1) * 0.5 + 1)
        local boxTime = boxTime + dt
        if scrollDuration <= boxTime then
            boxTime = -scrollDuration
        end
        box:setPosition(-(scrollAmount * MathUtil.smoothstep(0.2, 0.8, math.abs(boxTime) / scrollDuration)))
        self.marqueeBoxes[box] = boxTime
    end
end
function InGameMenuMobileMapFrame:onSlotUsageChanged()
    self:refreshDetails()
end
function InGameMenuMobileMapFrame:getNumberOfItemsInSection(list, section)
    if list == self.vehiclesList then
        return #self.vehicles[section]
    end
    if list == self.pointsList then
        return #self.hotspotsSorted[self.hotspotFiltersMapping[section]]
    end
    if list == self.statusList then
        return #self.fieldStatus[self.statusSelector.state]
    end
    if list == self.fieldsList then
        return self.fields[section] ~= nil and #self.fields[section] or 0
    end
    if list ~= self.aiWorkersList then
        return 0
    end
    local count = 0
    for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do

    end
    return count
end
function InGameMenuMobileMapFrame:populateCellForItemInSection(list, section, index, cell)
    local glyph = cell:getAttribute("glyph")
    if glyph ~= nil then
        function glyph.glyphElement.overlay.getIsVisible()
            -- upvalues: (copy) self, (copy) cell, (copy) list
            return self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and cell:getIsSelected() and FocusManager:getFocusedElement() == list
        end
    end
    if list == self.vehiclesList then
        local item = self.vehicles[section][index]
        local icon = cell:getAttribute("icon")
        icon:setImageUVs(nil, unpack(item.vehicle.mapHotspot.icon.uvs))
        cell:getAttribute("text"):setText(item.name)
        return
    end
    if list == self.pointsList then
        local item = self.hotspotsSorted[self.hotspotFiltersMapping[section]][index]
        cell:getAttribute("text"):setText(item:getName())
        local vehicle = cell:getAttribute("icon")
        vehicle:setImageUVs(nil, unpack(item.icon.uvs))
        return
    end
    if list == self.statusList then
        self:populateStatusCellForItemInSection(list, section, index, cell)
        return
    end
    if list == self.fieldsList then
        local item = self.fields[section][index]
        cell:getAttribute("text"):setText(g_i18n:getText("ui_fieldNo") .. " " .. item:getId())
        cell:getAttribute("size"):setText(g_i18n:formatArea(item:getAreaHa(), 2))
        local vehicle = cell:getAttribute("icon")
        if section == 1 then
            vehicle:applyProfile("inGameMenuMobileMapFieldsListIconOwned")
            cell:getAttribute("cost"):setText("")
        else
            vehicle:applyProfile("inGameMenuMobileMapFieldsListIcon")
            cell:getAttribute("cost"):setText(g_i18n:formatMoney(item.farmland.price, 0, true, true))
        end
    end
    if list == self.aiWorkersList then
        local item = 0
        local vehicle = nil
        for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
            if job.startedFarmId == self.playerFarm.farmId then
                item = item + 1
                if item == index then
                    vehicle = job
                    break
                end
            end
        end
        if vehicle ~= nil then
            cell:getAttribute("text"):setText(vehicle:getDescription())
            cell:getAttribute("title"):setText(vehicle:getTitle())
            cell:getAttribute("helper"):setText(vehicle:getHelperName())
        end
    end
end
function InGameMenuMobileMapFrame:populateStatusCellForItemInSection(_, section, index, cell)
    if self.fieldStatusFilters[section][index] == nil then
        self.fieldStatusFilters[section][index] = true
    end
    local statusSelectorState = self.statusSelector.state
    local status = self.fieldStatus[statusSelectorState][index]
    cell:getAttribute("text"):setText(status.description)
    cell:getAttribute("text").getIsSelected = function()
        -- upvalues: (copy) self, (copy) index
        return self.fieldStatusFilters[self.statusSelector.state][index]
    end
    local iconBg = cell:getAttribute("iconBg")
    local i = #iconBg.elements
    local getIsSelectedFunc = 1
    local icon = -1
    for i = i, getIsSelectedFunc, icon do
        iconBg.elements[i]:delete()
    end
    iconBg:applyProfile(InGameMenuMobileMapFrame.STATUS_BG_COLOR_PROFILE)
    if statusSelectorState == 1 then
        GuiOverlay.setSelectedColor(iconBg.overlay, unpack(status.colors[self.isColorBlindMode]))
    else
        self:assignGroundStatusColors(iconBg, statusColors, cell)
    end
    local function getIsSelectedFunc()
        -- upvalues: (copy) self, (copy) index
        return self.fieldStatusFilters[self.statusSelector.state][index] and GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_NORMAL
    end
    iconBg.getOverlayState = getIsSelectedFunc
    local i = #iconBg.elements
    local icon = 1
    local i = -1
    for i = i, icon, i do
        iconBg.elements[i].getOverlayState = getIsSelectedFunc
    end
    local icon = cell:getAttribute("icon")
    if statusSelectorState == 1 then
        icon:setVisible(true)
        icon:setImageFilename(status.iconFilename)
        icon.getOverlayState = getIsSelectedFunc
    else
        icon:setVisible(false)
    end
end
function InGameMenuMobileMapFrame:onListSelectionChanged(list, section, index)
    if not (self.isOpening or self.blockListSelectionEvents) then
        if list == self.aiWorkersList then
            local job = g_currentMission.aiSystem:getJobByIndex(index)
            if job ~= nil and job.vehicleParameter then
                local vehicle = job.vehicleParameter:getVehicle()
                if vehicle ~= nil then
                    local hotspot = vehicle:getMapHotspot()
                    if self.blockPanToHotspot then
                        self.blockPanToHotspot = false
                    else
                        self.inGameMap:panToHotspot(hotspot)
                    end
                    self:setMapSelectionItem(hotspot)
                    return
                end
            end
        elseif list ~= self.statusList then
            local job = nil
            if list == self.vehiclesList then
                job = self.vehicles[section][index].vehicle:getMapHotspot()
            elseif list == self.pointsList then
                job = self.hotspotsSorted[self.hotspotFiltersMapping[section]][index]
            else
                local _ = list == self.fieldsList
            end
            self.currentList = list
            self.currentListItemSectionIndex = list.selectedSectionIndex
            self.currentListItemIndex = list.selectedIndex
            if self.blockPanToHotspot then
                self.blockPanToHotspot = false
            else
                self.inGameMap:panToHotspot(job)
            end
            self:setMapSelectionItem(job)
        end
    end
end
function InGameMenuMobileMapFrame:getNumberOfSections(list)
    return list == self.vehiclesList and #self.vehicles or (list == self.pointsList and #self.hotspotFiltersMapping or (list == self.fieldsList and #self.fields or 1))
end
function InGameMenuMobileMapFrame:getTitleForSectionHeader(list, section)
    if list == self.vehiclesList then
        return g_i18n:getText(InGameMenuMobileMapFrame.SECTION_NAMES.VEHICLES[section])
    end
    if list == self.pointsList then
        return g_i18n:getText(InGameMenuMobileMapFrame.SECTION_NAMES.POINTS[self.hotspotFiltersMapping[section]])
    end
    if list ~= self.fieldsList then
        return ""
    end
    local sectionTitle = g_i18n:getText(InGameMenuMobileMapFrame.SECTION_NAMES.FIELDS[section])
    if section == 2 then
        sectionTitle = sectionTitle .. "\n" .. g_i18n:getText("ui_balance") .. ": " .. g_i18n:formatMoney(self.playerFarm:getBalance(), 0, true, true)
    end
    return sectionTitle
end
function InGameMenuMobileMapFrame:onClickListItem(element)
    if not element.parent.wasScrolling then
        if element.indexInSection == self.currentListItemIndex and element.sectionIndex == self.currentListItemSectionIndex then
            self:showDetailsBox(true)
            return
        end
        self.currentListItem = element
    end
end
function InGameMenuMobileMapFrame:onClickStatusListItem(element)
    if not element.parent.wasScrolling then
        statusFilter[element.indexInSection] = self.fieldStatusFilters[self.statusSelector.state][element.indexInSection] ~= nil and not self.fieldStatusFilters[self.statusSelector.state][element.indexInSection]
    end
    self:generateOverviewOverlay()
    self:saveFilters()
end
function InGameMenuMobileMapFrame:onJobTypeChanged(index)
    self:setActiveJobTypeSelection(self.currentJobTypes[index])
end
function InGameMenuMobileMapFrame:updateParameterValueTexts()
    g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
    for _, element in ipairs(self.currentJobElements) do
        local parameter = element.aiParameter
        local parameterType = parameter:getType()
        if parameterType == AIParameterType.TEXT then
            element:getDescendantByName("title"):setText(parameter:getString())
        elseif parameterType == AIParameterType.POSITION or parameterType == AIParameterType.POSITION_ANGLE then
            element:getDescendantByName("text"):setText(parameter:getString())
            g_currentMission:addMapHotspot(self.aiTargetMapHotspot)
            local title, z = parameter:getPosition()
            self.aiTargetMapHotspot:setWorldPosition(title, z)
            if parameterType == AIParameterType.POSITION_ANGLE then
                local angle = parameter:getAngle() + 3.141592653589793
                self.aiTargetMapHotspot:setWorldRotation(angle)
            end
        else
            element:updateTitle()
        end
    end
end
function InGameMenuMobileMapFrame:onClickMultiTextOptionParameter(_, element)
    if self.currentJob ~= nil then
        self.currentJob:onParameterValueChanged(element.aiParameter)
        self:updateParameterValueTexts()
    end
    self:validateParameters()
end
function InGameMenuMobileMapFrame:onClickPositionParameter(element)
    local parameter = element.aiParameter
    self:startPickPosition(parameter, function(success, _, _)
        -- upvalues: (copy) element, (copy) parameter, (copy) self
        if success then
            element:getDescendantByName("text"):setText(parameter:getString())
        end
        self:setJobMenuVisible(true)
    end)
    self:setJobMenuVisible(false, true)
end
function InGameMenuMobileMapFrame:onClickPositionRotationParameter(element)
    local parameter = element.aiParameter
    self:startPickPositionAndRotation(parameter, function(success, _, _, _)
        -- upvalues: (copy) element, (copy) parameter, (copy) self
        if success then
            element:getDescendantByName("text"):setText(parameter:getString())
        end
        self:setJobMenuVisible(true)
    end)
    self:setJobMenuVisible(false, true)
end
function InGameMenuMobileMapFrame:registerInput()
    self:unregisterInput()
    g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onMenuAccept, false, true, false, true)
    g_inputBinding:registerActionEvent(InputAction.MENU_ACTIVATE, self, self.onMenuActivate, false, true, false, true)
    g_inputBinding:registerActionEvent(InputAction.MENU_CANCEL, self, self.onMenuCancel, false, true, false, true)
    g_inputBinding:registerActionEvent(InputAction.MENU_AXIS_LEFT_RIGHT, self, self.onMenuLeftRight, false, true, false, true)
    g_inputBinding:registerActionEvent(InputAction.MENU_AXIS_LEFT_RIGHT, self, self.onMenuLeftRightContinuous, false, false, true, true)
end
function InGameMenuMobileMapFrame.unregisterInput(_, customOnly)
    for _, actionName in pairs(customOnly and InGameMenuMobileMapFrame.CLEAR_CLOSE_INPUT_ACTIONS or InGameMenuMobileMapFrame.CLEAR_INPUT_ACTIONS) do
        g_inputBinding:removeActionEventsByActionName(actionName)
    end
end
function InGameMenuMobileMapFrame:onMenuAccept()
    if self.mode == InGameMenuMobileMapFrame.MODE_NONE or self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW then
        if self.currentList == self.statusList then
            self:onClickStatusListItem(self.currentList.sections[self.currentList.selectedSectionIndex].cells[self.currentList.selectedIndex])
            return
        end
        if not self.currentList.visible then
            self:onDetailsButtonBack()
            return
        end
        local focusElement = FocusManager:getFocusedElement()
        if self.currentList == self.pointsList and (focusElement ~= self.pointsList and focusElement.onClickCallback ~= nil) then
            focusElement.onClickCallback(self)
            return
        end
        if self.currentList.totalItemCount > 0 then
            self:onClickListItem(self.currentList.sections[self.currentList.selectedSectionIndex].cells[self.currentList.selectedIndex])
            return
        end
    elseif self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
        local focusElement = FocusManager:getFocusedElement()
        if focusElement.name == "button" then
            focusElement.onClickCallback(self, focusElement)
        end
    end
end
function InGameMenuMobileMapFrame:onMenuActivate()
    if self.mode == InGameMenuMobileMapFrame.MODE_NONE and self.canEnter then
        self:onClickEnterVehicle()
        return
    elseif self.mode == InGameMenuMobileMapFrame.MODE_NONE and self.canBuy then
        self:onClickBuyField()
        return
    elseif self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and self:getCanCreateJob() then
        self:onCreateJob()
        return
    elseif self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE and self:getCanCancelJob() then
        self:onCancelJob()
    elseif self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
        self:onStartJob()
    end
end
function InGameMenuMobileMapFrame:onMenuCancel()
    if self.mode == InGameMenuMobileMapFrame.MODE_NONE then
        if self.canSetMarker then
            self:onClickTagPlace()
            return
        end
        if self.canReset then
            self:onClickResetVehicle()
            return
        end
    elseif self.mode == InGameMenuMobileMapFrame.MODE_AI_PAGE then
        if self:getCanGoTo() then
            self:onStartGoToJob()
            return
        end
        self:onSkipJobTask()
    end
end
function InGameMenuMobileMapFrame:onMenuLeftRight(actionName, dir)
    if self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.STATUS and math.abs(dir) > g_analogStickVTolerance then
        self:onStatusFilterChanged(actionName, dir)
    end
end
function InGameMenuMobileMapFrame:onMenuLeftRightContinuous(actionName, dir)
    if self.mapPageSelector.state == InGameMenuMobileMapFrame.PAGE_ID.POINTS then
        FocusManager:inputEvent(InputAction.MENU_AXIS_LEFT_RIGHT, dir)
    elseif self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
        local element = FocusManager:getFocusedElement()
        if element.inputEvent ~= nil then
            element:inputEvent(actionName, dir)
        end
    end
end
function InGameMenuMobileMapFrame:onDetailsButtonBack()
    self:showDetailsBox(false)
    FocusManager:setFocus(self.currentList)
end
function InGameMenuMobileMapFrame:onClickCloseMap()
    if self:getCanCloseMap() then
        self:onClickBackCallback()
    end
    if self:getIsPicking() then
        self:executePickingCallback(false)
        self:refreshContextInput()
        g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
        self.inGameMap.isTouchPickingRotation = false
        self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmPosition"))
    end
    if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
        self:setMode(InGameMenuMobileMapFrame.MODE_AI_PAGE)
        self:setJobMenuVisible(false)
        self.aiWorkersList.handleFocus = true
        FocusManager:setFocus(self.aiWorkersList)
    end
end
function InGameMenuMobileMapFrame:onClickEnterVehicle()
    local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
    if vehicle ~= nil and (vehicle.getIsEnterableFromMenu ~= nil and vehicle:getIsEnterableFromMenu()) then
        self.onClickBackCallback()
        g_localPlayer:requestToEnterVehicle(vehicle)
    end
end
function InGameMenuMobileMapFrame:onClickResetVehicle()
    if not self.isResetPending and (g_currentMission.tourIconsBase == nil or not g_currentMission.tourIconsBase.visible) and self.currentHotspot ~= nil then
        YesNoDialog.show(self.onYesNoReset, self, g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_RESET_CONFIRM), g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.VEHICLE_RESET))
    end
end
function InGameMenuMobileMapFrame:onYesNoReset(yes)
    if yes and self.currentHotspot ~= nil then
        local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
        if vehicle ~= nil then
            self.buttonResetVehicle:setVisible(false)
            g_messageCenter:subscribe(ResetVehicleEvent, self.onVehicleReset, self)
            self.isResetPending = true
            g_client:getServerConnection():sendEvent(ResetVehicleEvent.new(vehicle))
        end
    end
end
function InGameMenuMobileMapFrame:onVehicleReset(state)
    self.isResetPending = false
    g_messageCenter:unsubscribe(ResetVehicleEvent, self)
    if state == ResetVehicleEvent.STATE_SUCCESS then
        InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_RESET_DONE), nil, nil, DialogElement.TYPE_INFO)
        self:updateVehicles()
        self.vehiclesList:reloadData()
        self.vehiclesList.sliderElement.parent:setVisible(self.vehiclesList.visible and self.vehiclesList.totalItemCount > 0 and self.vehiclesList.sliderElement.needsSlider)
        self:showDetailsBox(false)
        self.blockListSelectionEvents = true
        self.vehiclesList:setSelectedItem(1, 1)
        self.blockListSelectionEvents = false
        self.blockPanToHotspot = true
        return
    elseif state == ResetVehicleEvent.STATE_FAILED then
        InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_RESET_FAILED))
        return
    elseif state == ResetVehicleEvent.STATE_IN_USE then
        InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_IN_USE))
    else
        InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_VEHICLE_NO_PERMISSION))
    end
end
function InGameMenuMobileMapFrame:onClickTagPlace()
    if self.currentHotspot ~= nil and (self.currentHotspot.worldX ~= nil and self.currentHotspot.worldZ ~= nil) then
        if g_currentMission.currentMapTargetHotspot == self.currentHotspot then
            self.removeMarker = false
            g_currentMission:setMapTargetHotspot(nil)
            self.currentHotspot:setBlinking(true)
        else
            self.removeMarker = true
            g_currentMission:setMapTargetHotspot(self.currentHotspot)
        end
        self:showContextMarker(self.canSetMarker, self.removeMarker)
    end
end
function InGameMenuMobileMapFrame:onClickBuyField()
    local field = self.currentHotspot:getField()
    local farmland = field.farmland
    if g_farmlandManager:getFarmlandOwner(farmland.id) ~= g_currentMission:getFarmId() then
        local money = self.playerFarm:getBalance()
        local price = farmland.price
        if price <= money then
            local text = string.format(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.MOBILE_BUY_FIELD_TEXT), g_i18n:formatMoney(money, 0, true, true), g_i18n:formatMoney(price, 0, true, true))
            local title = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_BUY_FARMLAND_TITLE)
            YesNoDialog.show(self.onYesNoBuyField, self, text, title)
        elseif Platform.hasInAppPurchases and (g_inAppPurchaseController ~= nil and g_inAppPurchaseController:getIsAvailable()) then
            local text = string.format(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.MOBILE_BUY_FIELD_TEXT_COINS), g_i18n:formatMoney(money, 0, true, true), g_i18n:formatMoney(price, 0, true, true))
            local title = g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_BUY_FARMLAND_TITLE)
            YesNoDialog.show(self.onYesNoBuyCoins, self, text, title)
            self.toBuyField = nil
        else
            InfoDialog.show(g_i18n:getText(InGameMenuMobileMapFrame.BUTTON_TEXTS.DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY))
        end
    end
    self.toBuyField = field
end
function InGameMenuMobileMapFrame:onYesNoBuyField(yes)
    if yes then
        self.client:getServerConnection():sendEvent(FarmlandStateEvent.new(self.toBuyField.farmland.id, g_currentMission:getFarmId(), self.toBuyField.farmland.price))
        self:setMapSelectionItem(self.currentHotspot)
        self:updateFields()
        self.fieldsList:reloadData()
    end
    self.toBuyField = nil
end
function InGameMenuMobileMapFrame:onYesNoBuyCoins(yes)
    if yes then
        self.onClickBackCallback()
        g_shopMenu:showCoinShop()
    end
end
function InGameMenuMobileMapFrame:onStartGoToJob()
    if self:getCanGoTo() then
        self:tryStartGoToJob()
    end
end
function InGameMenuMobileMapFrame:onStartJob()
    if self:getCanStartJob() then
        self:startJob()
    end
end
function InGameMenuMobileMapFrame:onCancelJob()
    if self:getCanCancelJob() then
        self:cancelJob()
    end
end
function InGameMenuMobileMapFrame:onSkipJobTask()
    if self:getCanSkipJobTask() then
        self:skipCurrentTask()
    end
end
function InGameMenuMobileMapFrame:onConfirmAITarget()
    if self.isPickingLocation then
        local worldX = self.aiTargetMapHotspot.worldX
        local worldZ = self.aiTargetMapHotspot.worldZ
        if g_currentMission.aiSystem:getIsPositionReachable(worldX, 0, worldZ) then
            self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmRotation"))
            self.hasPickedLocationTouch = true
            self.inGameMap.isTouchPickingRotation = true
            self:executePickingCallback(true, worldX, worldZ)
        else
            InfoDialog.show(g_i18n:getText("ai_validationErrorBlockedPosition"), nil, nil, DialogElement.TYPE_WARNING)
        end
    else
        if self.isPickingRotation then
            self.inGameMap.isTouchPickingRotation = false
            self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmPosition"))
            self:executePickingCallback(true, self.aiTargetMapHotspot.worldRotation + 3.141592653589793)
        end
        return
    end
end
function InGameMenuMobileMapFrame:onCreateJob()
    if self:getCanCreateJob() then
        self:createJob()
    end
end
function InGameMenuMobileMapFrame:onMapPageSelected()
    self:showDetailsBox(false)
    for _, filterPage in pairs(self.filterBoxes) do
        filterPage:setVisible(false)
    end
    local mapPageId = self.mapPageSelector.state
    self.filterBoxes[mapPageId]:setVisible(true)
    self.inGameMapBase:applyCustomHotspotSortingOrder(InGameMenuMobileMapFrame.HOTSPOT_SORTING_PRIO[mapPageId])
    if self.previousMapPageId == InGameMenuMobileMapFrame.PAGE_ID.AI then
        if self:getIsPicking() then
            self:executePickingCallback(false)
            g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
            self.inGameMap.isTouchPickingRotation = false
            self.buttonConfirmAITarget:setText(g_i18n:getText("button_confirmPosition"))
        end
        self:refreshContextInput()
        self:showContextInput(self.canEnter, self.canReset, self.canSetMarker, self.removeMarker, self.canBuy)
        self:selectHotspotInList(self.currentHotspot, self.currentList)
        if self.mode == InGameMenuMobileMapFrame.MODE_CREATE_JOB then
            self:onClickCloseMap()
        end
    elseif mapPageId == InGameMenuMobileMapFrame.PAGE_ID.AI and self.previousMapPageId == InGameMenuMobileMapFrame.PAGE_ID.FIELDS then
        self:setMapSelectionItem(nil)
    end
    self.currentList = self.pageLists[mapPageId]
    local listRecievedFocus = FocusManager:setFocus(self.currentList)
    if not self.isOpening then
        self:showDetailsBox(false)
    end
    if mapPageId == InGameMenuMobileMapFrame.PAGE_ID.STATUS then
        if self.mode ~= InGameMenuMobileMapFrame.MODE_OVERVIEW then
            self:setMode(InGameMenuMobileMapFrame.MODE_OVERVIEW)
        end
        self:setMapSelectionItem(nil)
    elseif mapPageId == InGameMenuMobileMapFrame.PAGE_ID.AI then
        if self.mode ~= InGameMenuMobileMapFrame.MODE_AI_PAGE then
            self:setMode(InGameMenuMobileMapFrame.MODE_AI_PAGE)
        end
        self:refreshContextInput()
        if not listRecievedFocus then
            FocusManager:unsetFocus(FocusManager.currentFocusData.focusElement)
        end
    elseif self.mode ~= InGameMenuMobileMapFrame.MODE_NONE then
        self:setMode(InGameMenuMobileMapFrame.MODE_NONE)
    end
    self.previousMapPageId = mapPageId
end
function InGameMenuMobileMapFrame:onPreviousPage()
    self.mapPageSelector:setState(self.mapPageSelector.state - 1 == 0 and #self.mapPageSelector.texts or self.mapPageSelector.state - 1, true)
end
function InGameMenuMobileMapFrame:onNextPage()
    self.mapPageSelector:setState(#self.mapPageSelector.texts < self.mapPageSelector.state + 1 and 1 or self.mapPageSelector.state + 1, true)
end
function InGameMenuMobileMapFrame:onClickPagingStatus()
    if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.STATUS then
        self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.STATUS, true)
    end
end
function InGameMenuMobileMapFrame:onClickPagingVehicles()
    if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.VEHICLES then
        self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.VEHICLES, true)
    end
end
function InGameMenuMobileMapFrame:onClickPagingPoints()
    if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.POINTS then
        self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.POINTS, true)
    end
end
function InGameMenuMobileMapFrame:onClickPagingFields()
    if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.FIELDS then
        self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.FIELDS, true)
    end
end
function InGameMenuMobileMapFrame:onClickPagingAI()
    if self.mapPageSelector.state ~= InGameMenuMobileMapFrame.PAGE_ID.AI then
        self.mapPageSelector:setState(InGameMenuMobileMapFrame.PAGE_ID.AI, true)
    end
end
function InGameMenuMobileMapFrame:onStatusFilterChanged(_, dir)
    if self.mode == InGameMenuMobileMapFrame.MODE_OVERVIEW then
        if dir < 0 then
            local newState = math.max(self.statusSelector.state - 1, 1)
            self.statusSelector:setState(newState, true)
        else
            local newState = math.min(self.statusSelector.state + 1, #self.statusSelector.texts)
            self.statusSelector:setState(newState, true)
        end
        self:onStatusSelected()
    end
end
function InGameMenuMobileMapFrame:onStatusSelected()
    self.statusList:reloadData()
    self:generateOverviewOverlay()
end
function InGameMenuMobileMapFrame:onClickFilterLoading()
    self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING]
    for _, hotspot in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING]) do
        hotspot:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.LOADING])
    end
    self:updatePointsFilterMapping()
end
function InGameMenuMobileMapFrame:onClickFilterProductions()
    self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS]
    for _, hotspot in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS]) do
        hotspot:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.PRODUCTIONS])
    end
    self:updatePointsFilterMapping()
end
function InGameMenuMobileMapFrame:onClickFilterAnimals()
    self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS]
    for _, hotspot in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS]) do
        hotspot:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.ANIMALS])
    end
    self:updatePointsFilterMapping()
end
function InGameMenuMobileMapFrame:onClickFilterOther()
    self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER] = not self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER]
    for _, hotspot in pairs(self.hotspotsSorted[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER]) do
        hotspot:setVisible(self.hotspotFiltersActive[InGameMenuMobileMapFrame.HOTSPOT_FILTERS.OTHER])
    end
    self:updatePointsFilterMapping()
end
function InGameMenuMobileMapFrame.onFilterButtonFocusEnter(_, button)
    button.overlay.color = {
        0,
        0,
        0,
        0
    }
    button.overlay.alpha = 0
    button.icon.color = {
        1,
        1,
        1,
        1
    }
    button.icon.alpha = 1
end
function InGameMenuMobileMapFrame.onFilterButtonFocusLeave(_, button)
    button.overlay.color = {
        1,
        1,
        1,
        1
    }
    button.overlay.alpha = 1
    button.icon.color = {
        0,
        0,
        0,
        0
    }
    button.icon.alpha = 0
end
function InGameMenuMobileMapFrame:setJobMenuVisible(isVisible, ignoreActionMessage)
    self.aiTaskDialogErrorMessage:setText("")
    self.aiTaskDialogErrorMessageBg:setVisible(false)
    if not ignoreActionMessage then
        self.actionMessage:setText("")
        self.actionMessageBg:setVisible(false)
    end
    self.aiTaskDialog:setVisible(isVisible)
    self:refreshContextInput()
end
function InGameMenuMobileMapFrame:createJob()
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
        self.aiTaskDialogJobTypeSelector:setTexts(currentJobTypesTexts)
        self.aiTaskDialogJobTypeSelector:setState(currentIndex or 1)
        self:setMode(InGameMenuMobileMapFrame.MODE_CREATE_JOB)
        self.currentJobVehicle = vehicle
        self.currentJob = nil
        self:setJobMenuVisible(true)
        self.aiWorkersList.handleFocus = false
        FocusManager:setFocus(self.aiTaskDialogJobTypeSelector)
        self:setActiveJobTypeSelection(currentJobTypeIndex)
    end
end
function InGameMenuMobileMapFrame:tryStartGoToJob()
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
            self:refreshContextInput()
        end
    end
end
function InGameMenuMobileMapFrame:startJob()
    if self.startJobPending then
        return
    else
        self.currentJob:setValues()
        local success, errorMessage = self.currentJob:validate(g_localPlayer.farmId)
        if success then
            self:tryStartJob(self.currentJob, g_localPlayer.farmId, function(state)
                -- upvalues: (copy) self
                if state == AIJob.START_SUCCESS then
                    self:setMode(InGameMenuMobileMapFrame.MODE_AI_PAGE)
                    self.currentJob = nil
                    self:setJobMenuVisible(false)
                    self.aiWorkersList.handleFocus = true
                end
            end)
        else
            InfoDialog.show(tostring(errorMessage), nil, nil, DialogElement.TYPE_WARNING)
            self:updateWarnings()
        end
    end
end
function InGameMenuMobileMapFrame:cancelJob()
    local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)
    if vehicle ~= nil and vehicle:getIsAIActive() then
        vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
    end
    self:refreshContextInput()
end
function InGameMenuMobileMapFrame:tryStartJob(job, farmId, callback)
    self.startJobPending = true
    g_messageCenter:subscribe(AIJobStartRequestEvent, self.onStartedJob, self, { callback })
    g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(job, farmId))
end
function InGameMenuMobileMapFrame:onStartedJob(args, state, jobTypeIndex)
    self.startJobPending = false
    g_messageCenter:unsubscribe(AIJobStartRequestEvent, self)
    if state ~= AIJob.START_SUCCESS then
        local text = g_currentMission.aiJobTypeManager:getJobTypeByIndex(jobTypeIndex).classObject.getIsStartErrorText(state)
        InfoDialog.show(text, nil, nil, DialogElement.TYPE_INFO)
    end
    args[1](state)
end
function InGameMenuMobileMapFrame:skipCurrentTask()
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
InGameMenuMobileMapFrame.STATUS_BG_COLOR_PROFILE = "inGameMenuMobileMapStatusListIconBg"
InGameMenuMobileMapFrame.STATUS_BG_COLOR_UVS = {
    700,
    0,
    82,
    82
}
InGameMenuMobileMapFrame.COLOR = {
    ["MAIN_MENU_BLUE"] = {
        0.0227,
        0.5346,
        0.8519,
        1
    }
}
InGameMenuMobileMapFrame.UV = {
    ["BUTTON_RIDE_HORSE"] = {
        946,
        539,
        36,
        36
    },
    ["BUTTON_ENTER_VEHICLE"] = {
        909,
        502,
        36,
        36
    }
}