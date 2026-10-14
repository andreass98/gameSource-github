InGameMenu = {}
local InGameMenu_mt = Class(InGameMenu, TabbedMenu)
InGameMenu.SAVE_STATE_NONE = 0
InGameMenu.SAVE_STATE_VALIDATE_LIST = 1
InGameMenu.SAVE_STATE_VALIDATE_LIST_DIALOG_WAIT = 2
InGameMenu.SAVE_STATE_VALIDATE_LIST_WAIT = 3
InGameMenu.SAVE_STATE_OVERWRITE_DIALOG = 4
InGameMenu.SAVE_STATE_OVERWRITE_DIALOG_WAIT = 5
InGameMenu.SAVE_STATE_NOP_WRITE = 6
InGameMenu.SAVE_STATE_WRITE = 7
InGameMenu.SAVE_STATE_WRITE_WAIT = 8
InGameMenu.MULTIPLAYER_SAVING_DISPLAY_DURATION = 800
function InGameMenu.register()
    InGameMenuAnimalsFrame.register()
    InGameMenuCalendarFrame.register()
    InGameMenuContractsFrame.register()
    InGameMenuHelpFrame.register()
    InGameMenuMapFrame.register()
    InGameMenuMultiplayerFrame.register()
    InGameMenuProductionFrame.register()
    InGameMenuStatisticsFrame.register()
    InGameMenuSaveFrame.register()
    InGameMenuTourFrame.register()
    InGameMenuSettingsFrame.register()
    InGameMenuMobileSettingsFrame.register()
    InGameMenuMobileMapFrame.register()
    if Platform.hasHints then
        InGameMenuHintFrame.register()
    end
    if Platform.hasInGameMenuMainPage then
        InGameMenuMainFrame.register()
    end
    local inGameMenu = InGameMenu.new()
    g_gui:loadGui("dataS/gui/InGameMenu.xml", "InGameMenu", inGameMenu)
    return inGameMenu
end
function InGameMenu.new(target, custom_mt)
    -- upvalues: (copy) InGameMenu_mt
    local self = InGameMenu:superClass().new(target, custom_mt or InGameMenu_mt)
    self.hud = nil
    self.performBackgroundBlur = true
    self.gameState = GameState.MENU_INGAME
    self.playerFarm = nil
    self.playerFarmId = 0
    self.currentUserId = -1
    self.isSaving = false
    self.missionInfo = {}
    self.missionDynamicInfo = {}
    self.activeDetailPage = nil
    self.lastGaragePage = nil
    self.paused = false
    self.pageMain = nil
    self.pageTour = nil
    self.pageHint = nil
    self.pageMapOverview = nil
    self.pageMapMobile = nil
    self.pageCalendar = nil
    self.pageAnimals = nil
    self.pageContracts = nil
    self.pageProduction = nil
    self.pageStatistics = nil
    self.pageMultiplayer = nil
    self.pageHelpLine = nil
    self.pageSettings = nil
    self.pageSettingsMobile = nil
    self.pageSave = nil
    self.playerAlreadySaved = false
    self.doSaveGameState = InGameMenu.SAVE_STATE_NONE
    self.continueEnabled = true
    self.savingMinEndTime = 0
    self.currentDeviceHasNoSpace = false
    self.quitAfterSave = false
    self.client = nil
    self.server = nil
    self.isMasterUser = false
    self.isServer = false
    self.defaultMenuButtonInfo = {}
    self.backButtonInfo = {}
    self.customItems = {}
    self.blockNextPageNextEvent = false
    return self
end
function InGameMenu.createFromExistingGui(gui, guiName)
    if Platform.hasInGameMenuMainPage then
        InGameMenuMainFrame.createFromExistingGui(g_gui.frames.ingameMenuMain.target, "InGameMenuMainFrame")
    end
    InGameMenuHelpFrame.createFromExistingGui(g_gui.frames.ingameMenuHelpLine.target, "InGameMenuHelpFrame")
    InGameMenuStatisticsFrame.createFromExistingGui(g_gui.frames.ingameMenuGameStats.target, "InGameMenuStatisticsFrame")
    InGameMenuAnimalsFrame.createFromExistingGui(g_gui.frames.ingameMenuAnimals.target, "InGameMenuAnimalsFrame")
    InGameMenuMapFrame.createFromExistingGui(g_gui.frames.ingameMenuMapOverview.target, "InGameMenuMapFrame")
    InGameMenuCalendarFrame.createFromExistingGui(g_gui.frames.ingameMenuCalendar.target, "InGameMenuCalendarFrame")
    InGameMenuContractsFrame.createFromExistingGui(g_gui.frames.ingameMenuContracts.target, "InGameMenuContractsFrame")
    if g_gui.frames.ingameMenuGameSettingsMobile ~= nil then
        InGameMenuMobileSettingsFrame.createFromExistingGui(g_gui.frames.ingameMenuGameSettingsMobile.target, "InGameMenuMobileSettingsFrame")
    end
    if g_gui.frames.inGameMenuMobileMap ~= nil then
        InGameMenuMobileMapFrame.createFromExistingGui(g_gui.frames.inGameMenuMobileMap.target, "InGameMenuMobileMapFrame")
    end
    InGameMenuSettingsFrame.createFromExistingGui(g_gui.frames.ingameMenuSettings.target, "InGameMenuSettingsFrame")
    InGameMenuProductionFrame.createFromExistingGui(g_gui.frames.ingameMenuProduction.target, "InGameMenuProductionFrame")
    InGameMenuTourFrame.createFromExistingGui(g_gui.frames.ingameMenuTour.target, "InGameMenuTourFrame")
    if Platform.hasHints then
        InGameMenuHintFrame.createFromExistingGui(g_gui.frames.ingameMenuHint.target, "InGameMenuHintFrame")
    end
    InGameMenuSaveFrame.createFromExistingGui(g_gui.frames.ingameMenuSave.target, "InGameMenuSaveFrame")
    local newGui = InGameMenu.new()
    g_gui.guis.InGameMenu:delete()
    g_gui.guis.InGameMenu.target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    local mission = g_currentMission
    newGui:setEnvironment(mission.environment)
    newGui:setConnectedUsers(mission.userManager:getUsers())
    newGui:setClient(g_client)
    newGui:setServer(g_server)
    newGui:setPlayer(mission.player)
    newGui:setMissionInfo(mission.missionInfo, mission.missionDynamicInfo, mission.baseDirectory)
    newGui:setTerrainSize(mission.terrainSize)
    newGui:setHUD(mission.hud)
    newGui:setInGameMap(mission.hud:getIngameMap())
    newGui:setManureTriggers(mission.manureLoadingStations, mission.liquidManureLoadingStations)
    newGui:setPlayerFarm(gui.playerFarm)
    newGui:setCurrentUserId(mission.playerUserId)
    newGui:onLoadMapFinished()
    g_inGameMenu = newGui
    return newGui
end
function InGameMenu:setInGameMap(inGameMap)
    if Platform.isMobile then
        self.pageMapMobile:setInGameMap(inGameMap)
    else
        self.pageMapOverview:setInGameMap(inGameMap)
        self.pageContracts:setInGameMap(inGameMap)
        self.pageStatistics:setInGameMap(inGameMap)
    end
    self.baseIngameMap = inGameMap
end
function InGameMenu:setHUD(hud)
    self.hud = hud
end
function InGameMenu:setTerrainSize(terrainSize)
    if Platform.isMobile then
        self.pageMapMobile:setTerrainSize(terrainSize)
    else
        self.pageMapOverview:setTerrainSize(terrainSize)
    end
end
function InGameMenu:setConnectedUsers(users)
    if self.pageMultiplayer ~= nil then
        self.pageMultiplayer:setUsers(users)
    end
end
function InGameMenu:setClient(client)
    self.client = client
    if Platform.isMobile then
        self.pageMapMobile:setClient(client)
    else
        self.pageMapOverview:setClient(client)
    end
    self.pageStatistics:setClient(client)
end
function InGameMenu:setServer(server)
    self.server = server
    self.isServer = server ~= nil
    self:updateHasMasterRights()
end
function InGameMenu:updateHasMasterRights()
    if Platform.isMobile then
        self.pageSettingsMobile:setHasMasterRights(self.isMasterUser or self.isServer)
    else
        self.pageSettings:setHasMasterRights(hasMasterRights)
        self.pageSave:setHasMasterRights(hasMasterRights)
    end
    if self.currentPage ~= nil then
        self:updatePages()
    end
end
function InGameMenu:onGrowthModeChanged()
    if self.currentPage ~= nil then
        self:updatePages()
    end
end
function InGameMenu:onLoadMapFinished()
    if Platform.isMobile then
        self.pageMapMobile:onLoadMapFinished()
    else
        self.pageMapOverview:onLoadMapFinished()
    end
end
function InGameMenu:unloadMapData()
    for _, frame in pairs(self.pageFrames) do
        if frame.unloadMapData ~= nil then
            frame:unloadMapData()
        end
    end
end
function InGameMenu:initializePages()
    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)
    if Platform.isMobile then
        self.pageMapMobile:initialize(self.clickBackCallback)
    else
        self.pageMapOverview:initialize(self.clickBackCallback)
    end
    self.pageTour:initialize()
    self.pageCalendar:initialize()
    if self.pageContracts ~= nil then
        self.pageContracts:initialize()
    end
    self.pageProduction:initialize()
    self.pageStatistics:initialize()
    self.pageAnimals:initialize()
    if Platform.isMobile then
        self.pageSettingsMobile:initialize()
    elseif Platform.canChangeControls then
        local controlsController = ControlsController.new()
        self.pageSettings:initialize(self.pageMapOverview, self.clickBackCallback, controlsController, true)
    else
        self.pageSettings:initialize(self.pageMapOverview, self.clickBackCallback)
    end
    if Platform.hasHints then
        self.pageHint:initialize()
    end
    if Platform.supportsMultiplayer then
        self.pageMultiplayer:initialize()
    end
    self.pageSave:initialize()
    if Platform.hasInGameMenuMainPage then
        self.pageMain:initialize()
    end
end
function InGameMenu:setupMenuPages()
    local pageIndex = 1
    local function tryAddPage(page, isEnabledPredicate, sliceId, soundId)
        -- upvalues: (copy) self, (ref) pageIndex
        if page == nil then
            local pageElement = self.pagingElement:getPageElementByIndex(pageIndex)
            self.pagingElement:removePageByElement(pageElement)
        else
            self:registerPage(page, pageIndex, isEnabledPredicate)
            self:addPageTab(page, nil, nil, sliceId, soundId)
            pageIndex = pageIndex + 1
        end
    end
    tryAddPage(self.pageMain, self:makeIsMainEnabledPredicate(), InGameMenu.SLICE_ID.MAP, InGameMenu.SOUNDS.MAP)
    tryAddPage(self.pageTour, self:makeIsTourEnabledPredicate(), InGameMenu.SLICE_ID.TOUR, InGameMenu.SOUNDS.TOUR)
    tryAddPage(self.pageHint, self:makeIsHintEnabledPredicate(), InGameMenu.SLICE_ID.HELP, InGameMenu.SOUNDS.HELP)
    tryAddPage(self.pageMapOverview, self:makeIsMapEnabledPredicate(), InGameMenu.SLICE_ID.MAP, InGameMenu.SOUNDS.MAP)
    tryAddPage(self.pageMapMobile, self:makeIsMobileMapEnabledPredicate(), InGameMenu.SLICE_ID.MAP, InGameMenu.SOUNDS.MAP)
    tryAddPage(self.pageCalendar, self:makeIsCalendarEnabledPredicate(), InGameMenu.SLICE_ID.CALENDAR, InGameMenu.SOUNDS.CALENDAR)
    tryAddPage(self.pageAnimals, self:makeIsAnimalsEnabledPredicate(), InGameMenu.SLICE_ID.ANIMALS, InGameMenu.SOUNDS.ANIMALS)
    tryAddPage(self.pageContracts, self:makeIsContractsEnabledPredicate(), InGameMenu.SLICE_ID.CONTRACTS, InGameMenu.SOUNDS.CONTRACTS)
    tryAddPage(self.pageProduction, self:makeIsProductionEnabledPredicate(), InGameMenu.SLICE_ID.PRODUCTION, InGameMenu.SOUNDS.PRODUCTION)
    tryAddPage(self.pageStatistics, self:makeIsStatisticsEnabledPredicate(), InGameMenu.SLICE_ID.STATISTICS, InGameMenu.SOUNDS.STATISTICS)
    tryAddPage(self.pageMultiplayer, self:makeIsMpEnabledPredicate(), InGameMenu.SLICE_ID.MULTIPLAYER, InGameMenu.SOUNDS.MULTIPLAYER)
    tryAddPage(self.pageHelpLine, self:makeIsHelpEnabledPredicate(), InGameMenu.SLICE_ID.HELP, InGameMenu.SOUNDS.HELP)
    tryAddPage(self.pageSettings, self:makeIsSettingsEnabledPredicate(), InGameMenu.SLICE_ID.GENERAL_SETTINGS, InGameMenu.SOUNDS.SETTINGS)
    tryAddPage(self.pageSettingsMobile, self:makeIsMobileSettingsEnabledPredicate(), InGameMenu.SLICE_ID.HELP, InGameMenu.SOUNDS.HELP)
    tryAddPage(self.pageSave, self:makeIsSaveEnabledPredicate(), InGameMenu.SLICE_ID.SAVE, InGameMenu.SOUNDS.SAVE)
    self:rebuildTabList()
end
function InGameMenu:setupMenuButtonInfo()
    InGameMenu:superClass().setupMenuButtonInfo(self)
    local onButtonBackFunction = self.clickBackCallback
    local onButtonPagePreviousFunction = self:makeSelfCallback(self.onPagePrevious)
    local onButtonPageNextFunction = self:makeSelfCallback(self.onPageNext)
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK,
        ["text"] = g_i18n:getText(InGameMenu.L10N_SYMBOL.BUTTON_BACK),
        ["callback"] = onButtonBackFunction
    }
    self.nextPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_NEXT,
        ["text"] = g_i18n:getText("ui_ingameMenuNext"),
        ["callback"] = onButtonPageNextFunction
    }
    self.prevPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_PREV,
        ["text"] = g_i18n:getText("ui_ingameMenuPrev"),
        ["callback"] = onButtonPagePreviousFunction
    }
    if Platform.isMobile then
        self.defaultMenuButtonInfo = { self.backButtonInfo }
    else
        self.defaultMenuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    end
    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
    self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_PREV] = self.defaultMenuButtonInfo[2]
    self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_NEXT] = self.defaultMenuButtonInfo[3]
    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction,
        [InputAction.MENU_PAGE_PREV] = onButtonPagePreviousFunction,
        [InputAction.MENU_PAGE_NEXT] = onButtonPageNextFunction
    }
end
function InGameMenu:onGuiSetupFinished()
    InGameMenu:superClass().onGuiSetupFinished(self)
    if Platform.isMobile then
        self.buttonsPanel.absSize[1] = self.buttonsPanel.absSize[1] / g_aspectScaleX
    end
    g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_FINANCES_SCREEN, self.openFinancesScreen, self)
    g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_FARMS_SCREEN, self.openFarmsScreen, self)
    g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_PRODUCTION_SCREEN, self.openProductionScreen, self)
    g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_AI_SCREEN, self.openAIScreen, self)
    g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_HELP_SCREEN, self.openHelpLine, self)
    g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
    self:initializePages()
    self:setupMenuPages()
end
function InGameMenu:setEnvironment(environment)
    self.pageStatistics:setEnvironment(environment)
end
function InGameMenu:updateBackground()
    self.background:setVisible(self.currentPage.needsSolidBackground)
end
function InGameMenu:setMissionInfo(missionInfo, missionDynamicInfo, _)
    self.missionInfo = missionInfo
    self.missionDynamicInfo = missionDynamicInfo
    if Platform.isMobile then
        self.pageSettingsMobile:setMissionInfo(missionInfo)
    else
        self.pageSettings:setMissionInfo(missionInfo)
    end
    self.currentDeviceHasNoSpace = false
end
function InGameMenu:setPlayerFarm(farm)
    self.playerFarm = farm
    if farm == nil then
        self.playerFarmId = 0
    else
        self.playerFarmId = farm.farmId
    end
    if Platform.isMobile then
        self.pageMapMobile:setPlayerFarm(farm)
    else
        self.pageMapOverview:setPlayerFarm(farm)
    end
    self.pageStatistics:setPlayerFarm(farm)
    if self.pageMultiplayer ~= nil then
        self.pageMultiplayer:setPlayerFarm(farm)
    end
    self.pageAnimals:setPlayerFarm(farm)
    self.pageProduction:setPlayerFarm(farm)
    if farm ~= nil and self:getIsOpen() then
        self:updatePages()
    end
end
function InGameMenu:setPlayer(player)
    if self.pageMultiplayer ~= nil then
        self.pageMultiplayer:setPlayer(player)
    end
end
function InGameMenu:setCurrentUserId(currentUserId)
    self.currentUserId = currentUserId
    if self.pageMultiplayer ~= nil then
        self.pageMultiplayer:setCurrentUserId(currentUserId)
    end
end
function InGameMenu:setManureTriggers(manureLoadingStations, liquidManureLoadingStations)
    if Platform.isMobile then
        self.pageSettingsMobile:setManureTriggers(manureLoadingStations, liquidManureLoadingStations)
    else
        self.pageSettings:setManureTriggers(manureLoadingStations, liquidManureLoadingStations)
    end
end
function InGameMenu:leaveCurrentGame()
    OnInGameMenuMenu()
end
function InGameMenu:inputEvent(action, value, eventUsed)
    eventUsed = InGameMenu:superClass().inputEvent(self, action, value, eventUsed)
    if not eventUsed and action == InputAction.MENU then
        self:playSample(GuiSoundPlayer.SOUND_SAMPLES.BACK)
        self:exitMenu()
        eventUsed = true
    end
    return eventUsed
end
function InGameMenu:exitMenu()
    if self.continueEnabled and not self.isSaving then
        InGameMenu:superClass().exitMenu(self)
    end
end
function InGameMenu:reset()
    InGameMenu:superClass().reset(self)
    self.isSaving = false
    self.playerAlreadySaved = false
    self.doSaveGameState = InGameMenu.SAVE_STATE_NONE
    self.savingMinEndTime = 0
    self.currentDeviceHasNoSpace = false
    self.quitAfterSave = false
    self.isMasterUser = false
    self.isServer = false
    self.quitAfterSave = false
    self.continueEnabled = true
end
function InGameMenu:onMenuOpened()
    if self.playerFarmId == FarmManager.SPECTATOR_FARM_ID then
        self:setSoundSuppressed(true)
        local farmsPageId = self.pagingElement:getPageIdByElement(self.pageMultiplayer)
        local farmsPageIndex = self.pagingElement:getPageMappingIndex(farmsPageId)
        self.pageSelector:setState(farmsPageIndex, true)
        self:setSoundSuppressed(false)
    end
    if Platform.isMobile then
        g_currentMission:setManualPause(true)
    end
    if self.currentPage == nil or self.currentPage.dynamicMapImageLoading == nil then
        g_messageCenter:publish(MessageType.GUI_INGAME_OPEN)
    elseif self.currentPage.dynamicMapImageLoading:getIsVisible() then
        self.sendDelayedOpenMessage = true
    else
        g_messageCenter:publish(MessageType.GUI_INGAME_OPEN)
    end
    if Platform.hasInGameMenuMainPage then
        self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageMain), true)
    end
end
function InGameMenu:onClose(_)
    if Platform.isMobile then
        g_currentMission:setManualPause(false)
    end
    InGameMenu:superClass().onClose(self)
    self.mouseDown = false
    self.alreadyClosed = true
    if Platform.gameplay.canSellFromMenu then
        g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
        g_currentMission:showMoneyChange(MoneyType.SHOP_PROPERTY_SELL)
        g_currentMission:showMoneyChange(MoneyType.SHOP_HANDTOOL_SELL)
        g_currentMission:showMoneyChange(MoneyType.ANIMAL_UPKEEP)
    end
    g_gameSettings:save()
end
function InGameMenu:onButtonSaveGame()
    if (not self.missionDynamicInfo.isMultiplayer or (not self.missionDynamicInfo.isClient or self.isMasterUser)) and (g_currentMission.isMissionStarted and not self.isSaving) then
        if self.missionInfo:isa(FSCareerMissionInfo) and self.doSaveGameState == InGameMenu.SAVE_STATE_NONE then
            if not self.isServer and (self.isMasterUser and self.missionDynamicInfo.isMultiplayer) then
                self.client:getServerConnection():sendEvent(SaveEvent.new())
                self:notifyStartSaving()
                self.savingDisplayTimer = g_time + InGameMenu.MULTIPLAYER_SAVING_DISPLAY_DURATION
                return
            end
            g_messageCenter:publish(SaveEvent, false, false)
        end
    end
end
function InGameMenu:onButtonQuit()
    if Platform.isMobile then
        local menu = g_inGameMenu
        if not menu.isSaving then
            menu.quitAfterSave = true
            g_currentMission:startSaveCurrentGame(false)
            return
        end
    else
        if self.isSaving then
            return
        end
        local menu = g_i18n:getText(InGameMenu.L10N_SYMBOL.END_GAME)
        local isMultiplayerClient = self.missionDynamicInfo.isMultiplayer
        if isMultiplayerClient then
            isMultiplayerClient = self.missionDynamicInfo.isClient
        end
        if not isMultiplayerClient then
            if self.missionInfo:isa(FSCareerMissionInfo) then
                if not self.playerAlreadySaved then
                    menu = g_i18n:getText(InGameMenu.L10N_SYMBOL.END_WITHOUT_SAVING)
                end
            else
                menu = g_i18n:getText(InGameMenu.L10N_SYMBOL.END_TUTORIAL)
            end
        end
        YesNoDialog.show(self.onYesNoEnd, self, menu)
    end
end
function InGameMenu:onButtonBack()
    if Platform.isMobile then
        local closeMenuOneshot = Utils.getNoNil(self.currentPage.closeMenuOneshot, false)
        local goToMainMenu = Utils.getNoNil(currentPage.goToMainOverview, true)
        currentPage.closeMenuOneshot = false
        if closeMenuOneshot or not goToMainMenu then
            InGameMenu:superClass().onButtonBack(self)
        else
            self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageMain), true)
            self:goToPage(self.pageMain)
        end
    else
        if self.currentPage:requestClose(self.clickBackCallback) then
            if self.currentPage == self.pageSettings or self.currentPage == self.pageHelpLine then
                self:openSaveScreen()
                return
            end
            InGameMenu:superClass().onButtonBack(self)
        end
        return
    end
end
function InGameMenu:setIsGamePaused(paused)
    self.paused = paused
    if self.currentPage ~= nil then
        self:updateButtonsPanel(self.currentPage)
    end
end
function InGameMenu:startSavingGameDisplay()
    local text = g_i18n:getText(InGameMenu.L10N_SYMBOL.SAVING_CONTENT)
    MessageDialog.show(text, nil, nil, nil, false)
    self.savingMinEndTime = getTimeSec() + SavegameController.SAVING_DURATION
    self.isSaving = true
end
function InGameMenu:update(dt)
    self.alreadyClosed = false
    if self.doSaveGameState == InGameMenu.SAVE_STATE_NONE and (self.isSaving and getTimeSec() >= self.savingMinEndTime) then
        self.savingMinEndTime = 0
        MessageDialog.hide()
        self.isSaving = false
        if self.quitAfterSave then
            self:leaveCurrentGame()
            return
        end
    end
    if self.savingDisplayTimer ~= nil and self.savingDisplayTimer < g_time then
        self:notifySaveComplete()
        self.savingDisplayTimer = nil
    end
    if self.isSaving then
        return
    else
        InGameMenu:superClass().update(self, dt)
        if GS_PLATFORM_PLAYSTATION and (g_currentMission ~= nil and (self.missionDynamicInfo.isMultiplayer and (getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE and self.continueEnabled))) then
            self.continueEnabled = false
            g_gui:showGui("InGameMenu")
        elseif self.sendDelayedOpenMessage and (self.currentPage ~= nil and (self.currentPage.dynamicMapImageLoading ~= nil and not self.currentPage.dynamicMapImageLoading:getIsVisible())) then
            g_messageCenter:publish(MessageType.GUI_INGAME_OPEN)
            self.sendDelayedOpenMessage = false
        end
    end
end
function InGameMenu:updateButtonsPanel(page)
    if self.buttonsPanel ~= nil then
        local buttonsDisabled = page.hasFullScreenMap
        self.buttonsPanel:setVisible(not buttonsDisabled)
        self.buttonsPanel:setDisabled(buttonsDisabled)
        InGameMenu:superClass().updateButtonsPanel(self, page)
    end
end
function InGameMenu:updatePages(prevIndex)
    self.header:setVisible(true)
    if prevIndex ~= nil then
        local prevPage = self.pagingElement:getPageElementByIndex(prevIndex)
        local page = self.pagingElement:getPageElementByIndex(self.currentPageId)
        if page == self.pageMain then
            self.header:setVisible(false)
            self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageMain), true)
        elseif Platform.isMobile and page == self.pageMapMobile then
            self.header:setVisible(false)
        elseif prevPage == self.pageMain then
            self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageMain), false)
            self.pagingElement.currentPageMappingIndex = self.pagingElement.currentPageMappingIndex - 1
        elseif prevPage == self.pageHelpLine then
            self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageHelpLine), false)
        elseif prevPage == self.pageSettings then
            self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageSettings), false)
        end
    end
    InGameMenu:superClass().updatePages(self)
end
function InGameMenu:openFinancesScreen()
    if self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID then
        self:changeScreen(InGameMenu)
        local financesPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageStatistics)
        self.pageSelector:setState(financesPageIndex, true)
        self.pageStatistics:onClickFinances()
    end
end
function InGameMenu:openMapOverview()
    self:changeScreen(InGameMenu)
    local mapOverviewIndex = self.pagingElement:getPageMappingIndexByElement(self.pageMapOverview)
    if Platform.isMobile then
        mapOverviewIndex = self.pagingElement:getPageMappingIndexByElement(self.pageMapMobile)
    end
    self.pageSelector:setState(mapOverviewIndex, true)
end
function InGameMenu:openAIScreen(vehicle)
    self:changeScreen(InGameMenu)
    local pageAIIndex = self.pagingElement:getPageMappingIndexByElement(self.pageMapOverview)
    if Platform.isMobile then
        pageAIIndex = self.pagingElement:getPageMappingIndexByElement(self.pageMapMobile)
    end
    self.pageSelector:setState(pageAIIndex, true)
    if not Platform.isMobile then
        self.pageMapOverview:setAIVehicle(vehicle)
    end
end
function InGameMenu:openFarmlandsScreen()
    self:openMapOverview()
    self.pageMapOverview.mapOverviewSelector:setState(InGameMenuMapFrame.MAP_FARMLANDS, true)
end
function InGameMenu:openFarmsScreen()
    self:changeScreen(InGameMenu)
    local farmsPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageMultiplayer)
    self.pageSelector:setState(farmsPageIndex, true)
end
function InGameMenu:onOpenVehicleOverview()
    self:changeScreen(InGameMenu)
    local statisticsPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageStatistics)
    self.pageSelector:setState(statisticsPageIndex, true)
    self.pageStatistics:onClickVehicleOverview()
end
function InGameMenu:openHelpLine(categoryIndex, pageIndex)
    self:changeScreen(InGameMenu)
    self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageHelpLine), true)
    local helpLineIndex = self.pagingElement:getPageMappingIndexByElement(self.pageHelpLine)
    self.pageSelector:setState(helpLineIndex, true)
    self.pageHelpLine:openPage(pageIndex or 1, pageIndex)
end
function InGameMenu:openProductionScreen(productionPoint)
    if not self:getIsOpen() then
        self:changeScreen(InGameMenu)
    end
    local productionPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageProduction)
    self.pageSelector:setState(productionPageIndex, true)
    self.pageProduction:setSelectedProductionPoint(productionPoint)
end
function InGameMenu:openGeneralSettingsScreen()
    if not self:getIsOpen() then
        self:changeScreen(InGameMenu)
    end
    self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageSettings), true)
    local generalSettingsPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageSettings)
    self.pageSelector:setState(generalSettingsPageIndex, true)
    self.pageSettings.isOpening = true
    self.pageSettings:onClickGeneralSettings()
    self.pageSettings.isOpening = false
end
function InGameMenu:openGameSettingsScreen()
    if not self:getIsOpen() then
        self:changeScreen(InGameMenu)
    end
    self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageSettings), true)
    local gameSettingsPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageSettings)
    self.pageSelector:setState(gameSettingsPageIndex, true)
    self.pageSettings.isOpening = true
    self.pageSettings:onClickGameSettings()
    self.pageSettings.isOpening = false
end
function InGameMenu:openControlsScreen()
    if not self:getIsOpen() then
        self:changeScreen(InGameMenu)
    end
    self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageSettings), true)
    local controlsPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageSettings)
    self.pageSelector:setState(controlsPageIndex, true)
    self.pageSettings.isOpening = true
    self.pageSettings:onClickControls()
    self.pageSettings.isOpening = false
end
function InGameMenu:openSaveScreen()
    if not self:getIsOpen() then
        self:changeScreen(InGameMenu)
    end
    self:setPageEnabled(ClassUtil.getClassObjectByObject(self.pageSave), true)
    local savePageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageSave)
    self.pageSelector:setState(savePageIndex, true)
end
function InGameMenu:setMasterServerConnectionFailed(reason)
    if self.pageSettings == nil then
        return
    else
        local gameSettingsPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageSettings)
        self.pageSelector:setState(gameSettingsPageIndex, true)
        local quitGame = true
        if reason ~= MasterServerConnection.FAILED_PERMANENT_BAN then
            quitGame = true
            if reason ~= MasterServerConnection.FAILED_TEMPORARY_BAN then
                quitGame = not g_currentMission.isMissionStarted
            end
        end
        if quitGame or not self.isServer then
            self:leaveCurrentGame()
            InfoDialog.show(g_i18n:getText(InGameMenu.L10N_SYMBOL.MASTER_SERVER_CONNECTION_LOST), self.onConnectionFailedDialogClick, self)
        else
            self.continueEnabled = false
            YesNoDialog.show(self.onConnectionFailedDialogClick, self, g_i18n:getText(InGameMenu.L10N_SYMBOL.MASTER_SERVER_CONNECTION_LOST), nil, g_i18n:getText("button_save"), g_i18n:getText("button_quit"))
        end
    end
end
function InGameMenu:onMasterUserAdded(user)
    if user:getId() == g_currentMission.playerUserId then
        self.isMasterUser = true
        self:updateHasMasterRights()
    end
end
function InGameMenu:onMasterUserRemoved(user)
    if user:getId() == g_currentMission.playerUserId then
        self.isMasterUser = false
        self:updateHasMasterRights()
    end
end
function InGameMenu:onClickMenu()
    self:exitMenu()
    return true
end
function InGameMenu:onYesNoEnd(yes)
    if yes then
        if self.missionDynamicInfo.isMultiplayer and self.isServer then
            self.server:broadcastEvent(ShutdownEvent.new())
        end
        self:leaveCurrentGame()
    end
end
function InGameMenu:onPageNext()
    if self.blockNextPageNextEvent then
        self.blockNextPageNextEvent = false
    elseif self.currentPage:requestClose(self.frameClosePageNextCallback) then
        if self.currentPage == self.pageSettings or self.currentPage == self.pageHelpLine then
            self:openSaveScreen()
        end
        TabbedMenu:superClass().onPageNext(self)
    end
end
function InGameMenu:onPagePrevious()
    if self.currentPage:requestClose(self.frameClosePagePreviousCallback) then
        if self.currentPage == self.pageSettings or self.currentPage == self.pageHelpLine then
            self:openSaveScreen()
        end
        TabbedMenu:superClass().onPagePrevious(self)
    end
end
function InGameMenu:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
    local prevIndex = self.currentPageId or self.restorePageIndex
    self.pagingElement:getPageElementByIndex(prevIndex).closeMenuOneshot = false
    InGameMenu:superClass().onPageChange(self, pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
    local page = self.pagingElement:getPageElementByIndex(pageIndex)
    if page.hasFullScreenMap then
        page:resetUIDeadzones()
    end
    self:updatePages(prevIndex)
end
function InGameMenu:getPageButtonInfo(page)
    return InGameMenu:superClass().getPageButtonInfo(self, page)
end
function InGameMenu:onConnectionFailedDialogClick(yes)
    if yes then
        self.quitAfterSave = true
        g_messageCenter:publish(SaveEvent, false, false)
    else
        self:leaveCurrentGame()
    end
end
function InGameMenu:onVehiclesChanged(vehicle, wasAdded, isExitingGame)
    if Platform.isMobile then
        self.pageMapMobile:onVehiclesChanged(vehicle, wasAdded, isExitingGame)
    else
        self.pageMapOverview:onVehiclesChanged(vehicle, wasAdded, isExitingGame)
    end
end
function InGameMenu:notifyStartSaving()
    self.doSaveGameState = SavegameController.SAVE_STATE_NOP_WRITE
    self:startSavingGameDisplay()
end
function InGameMenu:notifySaveComplete()
    self.doSaveGameState = SavegameController.SAVE_STATE_NONE
    self.playerAlreadySaved = true
end
function InGameMenu:notifySavegameNotSaved(errorCode)
    self.doSaveGameState = SavegameController.SAVE_STATE_NONE
    self.savingMinEndTime = 0
    local text = g_i18n:getText(InGameMenu.L10N_SYMBOL.NOT_SAVED)
    if errorCode == Savegame.ERROR_DEVICE_UNAVAILABLE then
        text = g_i18n:getText(InGameMenu.L10N_SYMBOL.SAVE_NO_DEVICE)
    end
    InfoDialog.show(text, nil, nil, DialogElement.TYPE_WARNING)
end
function InGameMenu:notifyOverwriteSavegame(dialogCallback, callbackTarget)
    self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG_WAIT
    MessageDialog.hide()
    YesNoDialog.show(dialogCallback, callbackTarget, g_i18n:getText(InGameMenu.L10N_SYMBOL.SAVE_OVERWRITE))
end
function InGameMenu:onSoilSettingChanged()
    if Platform.isMobile then
        self.pageMapMobile:onSoilSettingChanged()
    else
        self.pageMapOverview:onSoilSettingChanged()
    end
end
function InGameMenu:makeIsMainEnabledPredicate()
    return function()
        return Platform.isMobile
    end
end
function InGameMenu:makeIsHintEnabledPredicate()
    return function()
        return Platform.hasHints and not g_guidedTourManager:getIsTourRunning()
    end
end
function InGameMenu:makeIsTourEnabledPredicate()
    return function()
        return g_guidedTourManager:getIsTourRunning()
    end
end
function InGameMenu:makeIsMapEnabledPredicate()
    return function()
        return not Platform.isMobile
    end
end
function InGameMenu:makeIsMobileMapEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return Platform.isMobile and self.showMap
    end
end
function InGameMenu:makeIsAIEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return not Platform.isMobile or self.showMap
    end
end
function InGameMenu:makeIsCalendarEnabledPredicate()
    return function()
        return not g_guidedTourManager:getIsTourRunning()
    end
end
function InGameMenu:makeIsWeatherEnabledPredicate()
    return function()
        return not g_guidedTourManager:getIsTourRunning()
    end
end
function InGameMenu:makeIsPricesEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer
        if not isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID
        end
        if isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = not g_guidedTourManager:getIsTourRunning()
        end
        return isNotMultiplayerOrIsInFarm
    end
end
function InGameMenu:makeIsAnimalsEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer
        if not isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID
        end
        if isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = not g_guidedTourManager:getIsTourRunning()
        end
        return isNotMultiplayerOrIsInFarm
    end
end
function InGameMenu:makeIsContractsEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        if self.missionDynamicInfo.isMultiplayer then
            isNotMultiplayerOrIsInFarm = false
            if self.playerFarmId == FarmManager.SPECTATOR_FARM_ID then
                ::l3::
                if isNotMultiplayerOrIsInFarm then
                    isNotMultiplayerOrIsInFarm = not g_guidedTourManager:getIsTourRunning()
                end
                return isNotMultiplayerOrIsInFarm
            end
        end
        local isNotMultiplayerOrIsInFarm = not Platform.isMobile
        goto l3
    end
end
function InGameMenu:makeIsGarageEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer
        if not isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID
        end
        if isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = not g_guidedTourManager:getIsTourRunning()
        end
        return isNotMultiplayerOrIsInFarm
    end
end
function InGameMenu:makeIsFinancesEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer
        if not isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID
        end
        if isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = not g_guidedTourManager:getIsTourRunning()
        end
        return isNotMultiplayerOrIsInFarm
    end
end
function InGameMenu:makeIsStatisticsEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer
        if not isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID
        end
        if isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = not g_guidedTourManager:getIsTourRunning()
        end
        return isNotMultiplayerOrIsInFarm
    end
end
function InGameMenu:makeIsSettingsEnabledPredicate()
    return function()
        return false
    end
end
function InGameMenu:makeIsMobileSettingsEnabledPredicate()
    return function()
        return Platform.isMobile and not g_guidedTourManager:getIsTourRunning()
    end
end
function InGameMenu:makeIsMpUsersEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return self.missionDynamicInfo.isMultiplayer
    end
end
function InGameMenu:makeIsMpFarmsEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return self.missionDynamicInfo.isMultiplayer
    end
end
function InGameMenu:makeIsMpEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        return self.missionDynamicInfo.isMultiplayer
    end
end
function InGameMenu:makeIsHelpEnabledPredicate()
    return function()
        return Platform.isMobile
    end
end
function InGameMenu:makeIsProductionEnabledPredicate()
    return function()
        -- upvalues: (copy) self
        local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer
        if not isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID
        end
        if isNotMultiplayerOrIsInFarm then
            isNotMultiplayerOrIsInFarm = not g_guidedTourManager:getIsTourRunning()
        end
        return isNotMultiplayerOrIsInFarm
    end
end
function InGameMenu:makeIsSaveEnabledPredicate()
    return function()
        return not Platform.isMobile
    end
end
InGameMenu.SLICE_ID = {
    ["MAP"] = "gui.icon_ingameMenu_map",
    ["CALENDAR"] = "gui.icon_ingameMenu_calendar",
    ["ANIMALS"] = "gui.icon_ingameMenu_animals",
    ["CONTRACTS"] = "gui.icon_ingameMenu_contracts",
    ["PRODUCTION"] = "gui.icon_ingameMenu_productionChains",
    ["STATISTICS"] = "gui.icon_ingameMenu_finances",
    ["TOUR"] = "gui.icon_tour",
    ["HELP"] = "gui.icon_options_help2",
    ["MULTIPLAYER"] = "gui.icon_multiplayer",
    ["SAVE"] = "gui.icon_ingameMenu_options"
}
InGameMenu.SOUNDS = {
    ["MAP"] = "map",
    ["CALENDAR"] = "calendar",
    ["ANIMALS"] = "animals",
    ["CONTRACTS"] = "contracts",
    ["PRODUCTION"] = "productions",
    ["STATISTICS"] = "statistics",
    ["MULTIPLAYER"] = "paging",
    ["SAVE"] = "settings"
}
InGameMenu.L10N_SYMBOL = {
    ["BUTTON_BACK"] = "button_back",
    ["BUTTON_RESTART"] = "button_restart",
    ["TUTORIAL_NOT_SAVED"] = "ui_tutorialIsNotSaved",
    ["END_TUTORIAL"] = "ui_endTutorial",
    ["END_WITHOUT_SAVING"] = "ui_endWithoutSaving",
    ["END_GAME"] = "ui_youWantToQuitGame",
    ["SAVING_CONTENT"] = "ui_savingContent",
    ["MASTER_SERVER_CONNECTION_LOST"] = "ui_masterServerConnectionLost",
    ["NOT_SAVED"] = "ui_savegameNotSaved",
    ["SAVE_NO_DEVICE"] = "ui_savegameSaveNoDevice",
    ["SAVE_OVERWRITE"] = "dialog_savegameOverwrite"
}
InGameMenu.PROFILES = {
    ["TAB_BAR_LIGHT"] = "uiInGameMenuHeader",
    ["TAB_BAR_DARK"] = "uiInGameMenuHeaderDark"
}