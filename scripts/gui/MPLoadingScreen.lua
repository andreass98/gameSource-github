MPLoadingScreen = {}
MPLoadingScreen.STATE_NONE = 0
MPLoadingScreen.STATE_CONNECTING = 1
MPLoadingScreen.STATE_WAIT_FOR_ACCEPT = 2
MPLoadingScreen.STATE_SYNCHRONIZING = 3
MPLoadingScreen.STATE_LOADING = 4
MPLoadingScreen.STATE_WAIT_FOR_MISSION = 5
MPLoadingScreen.STATE_READY = 6
MPLoadingScreen.STATE_PORT_TESTING = 7
MPLoadingScreen.NUM_GAMEPLAY_HINTS = 4
MPLoadingScreen.SAVEGAME_LOADING_DIALOG_DELAY = 500
local percentagePerMs = 0.000015833333333333333
MPLoadingScreen.LOAD_TARGETS = {
    ["WAIT_FOR_ACCEPT"] = 1,
    ["VEHICLE_VALIDATION"] = 2,
    ["SPECIALIZATIONS"] = 3,
    ["STORE"] = 4,
    ["DATA"] = 5,
    ["MAP"] = 6,
    ["TERRAIN"] = 7,
    ["ADDITIONAL_FILES"] = 8,
    ["VEHICLES"] = 9,
    ["FINISHED"] = 10
}
MPLoadingScreen.LOAD_TARGET_DATA = {}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.WAIT_FOR_ACCEPT] = {
    ["percentage"] = 0,
    ["percentagePerMs"] = 0,
    ["nextStepText"] = nil,
    ["nextStepTextMultiplayer"] = "ui_loading_connectingToServer"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.VEHICLE_VALIDATION] = {
    ["percentage"] = 0.1,
    ["percentagePerMs"] = percentagePerMs,
    ["nextStepText"] = "ui_loading_data"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.SPECIALIZATIONS] = {
    ["percentage"] = 0.15,
    ["percentagePerMs"] = percentagePerMs,
    ["nextStepText"] = "ui_loading_store"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.STORE] = {
    ["percentage"] = 0.2,
    ["percentagePerMs"] = percentagePerMs,
    ["nextStepText"] = "ui_loading_map"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.DATA] = {
    ["percentage"] = 0.4,
    ["percentagePerMs"] = percentagePerMs,
    ["nextStepText"] = "ui_loading_map"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.MAP] = {
    ["percentage"] = 0.55,
    ["percentagePerMs"] = percentagePerMs,
    ["nextStepText"] = "ui_loading_map"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.TERRAIN] = {
    ["percentage"] = 0.58,
    ["percentagePerMs"] = percentagePerMs,
    ["nextStepText"] = "ui_loading_map"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.ADDITIONAL_FILES] = {
    ["percentage"] = 0.6,
    ["percentagePerMs"] = 0,
    ["nextStepText"] = "ui_loading_vehicles"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.VEHICLES] = {
    ["percentage"] = 0.9,
    ["percentagePerMs"] = 0,
    ["nextStepText"] = "ui_loading_compilingShaders",
    ["nextStepTextConsole"] = "ui_loading_vehicles"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.FINISHED] = {
    ["percentage"] = 1,
    ["percentagePerMs"] = 0,
    ["nextStepText"] = "ui_loading_finished"
}
local MPLoadingScreen_mt = Class(MPLoadingScreen, ScreenElement)
function MPLoadingScreen.register()
    local mpLoadingScreen = MPLoadingScreen.new()
    g_gui:loadGui("dataS/gui/MPLoadingScreen.xml", "MPLoadingScreen", mpLoadingScreen)
    return mpLoadingScreen
end
function MPLoadingScreen.new(target, custom_mt)
    -- upvalues: (copy) MPLoadingScreen_mt
    local self = ScreenElement.new(target, custom_mt or MPLoadingScreen_mt)
    self.acceptCancelTimer = -1
    self.actionTimerCount = -1
    self.doLoad = false
    self.preSimulateCount = -1
    self.preSimulateSteps = 5
    self.loadFunction = OnLoadingScreen
    self.isClient = false
    self.isBackAllowed = false
    self.currentGameplayHint = nil
    self.currentGameplayHints = nil
    self.isCancel = true
    self.gameplayHintDuration = 6500
    self.gameplayHintTime = self.gameplayHintDuration
    self.savegameLoadingDialogDelay = -1
    self.state = MPLoadingScreen.STATE_NONE
    self.currentTarget = MPLoadingScreen.LOAD_TARGETS.WAIT_FOR_ACCEPT
    return self
end
function MPLoadingScreen:onCreate()
    self.button = self.buttonOkPC
end
function MPLoadingScreen:onOpen()
    MPLoadingScreen:superClass().onOpen(self)
    self.button:setVisible(false)
    self:setMapTitleAndPreview()
    self.loadingBar.absSize[1] = 0
    self.gameTitle = self.missionInfo.savegameName
    if self.missionDynamicInfo.isMultiplayer then
        self.gameTitle = ""
    end
    self.mpLoadingAnimation:setVisible(true)
    self.mpLoadingAnimationDone:setVisible(false)
    self.loadPercentage = 0
    self.totalLoadPercentage = 0
    self.loadTarget = 1
    g_messageCenter:subscribe(MessageType.ENQUEUED_ALL_LOADINGS, self.onEnqueuedAllLoadings, self)
    self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.WAIT_FOR_ACCEPT)
    enterCpuBoostMode()
end
function MPLoadingScreen:onClose()
    MPLoadingScreen:superClass().onClose(self)
    self.mapSelectionPreview:setImageFilename("dataS/menu/black.png")
    g_messageCenter:unsubscribe(MessageType.ENQUEUED_ALL_LOADINGS, self)
    leaveCpuBoostMode()
end
function MPLoadingScreen:cancelLoading(showConnectionLost)
    saveReadSavegameFinish("", self)
    leaveCpuBoostMode()
    g_cameraManager:setDefaultCamera()
    if self.state == MPLoadingScreen.STATE_PORT_TESTING then
        netShutdown(0, 0)
        g_gui:changeScreen(nil, self.returnScreenClass or MultiplayerScreen)
    elseif self.isClient then
        if g_currentMission == nil then
            self:cleanup()
        else
            OnInGameMenuMenu()
        end
        if masterServerConnectFront == nil then
            RestartManager:setStartScreen(RestartManager.START_SCREEN_MULTIPLAYER)
            doRestart(false, "")
        else
            g_gui:changeScreen(nil, self.returnScreenClass or MultiplayerScreen)
        end
    else
        if g_currentMission == nil then
            self:cleanup()
        end
        OnInGameMenuMenu()
    end
    if showConnectionLost then
        InfoDialog.show(g_i18n:getText("ui_connectionLost"))
    end
end
function MPLoadingScreen:onClickCancel()
    if self.isCancel and (self.missionDynamicInfo.isMultiplayer and self.missionDynamicInfo.isClient) then
        self:cancelLoading()
    end
end
function MPLoadingScreen:onClickOk(_)
    MPLoadingScreen:superClass().onClickOk(self)
    if self.state == MPLoadingScreen.STATE_READY then
        self:setButtonState(MPLoadingScreen.STATE_NONE)
        g_inputBinding:revertContext(false)
        g_currentMission:onStartMission()
        g_inputBinding:setContext(Gui.INPUT_CONTEXT_MENU, false, false)
        g_gui:showGui("")
        g_inputBinding:setShowMouseCursor(false)
        g_currentMission.pressStartPaused = false
        if g_currentMission:getIsServer() then
            g_currentMission:tryUnpauseGame()
        end
        if g_dedicatedServer ~= nil then
            g_dedicatedServer:lowerFramerate()
            if g_dedicatedServer.pauseGameIfEmpty then
                g_currentMission.dediEmptyPaused = true
                g_currentMission:pauseGame()
            end
        end
        if Profiler.IS_INITIALIZED then
            Profiler.setIsReady()
        end
        g_messageCenter:publish(MessageType.CURRENT_MISSION_LOADED)
        if g_dedicatedServer == nil and (Platform.hasWardrobe and not Profiler.IS_INITIALIZED) and (g_currentMission:getIsServer() and not self.missionInfo.isValid or not g_currentMission:getIsServer() and self.knownPlayerOnServer == false) then
            self:openWardrobe()
        end
    end
end
function MPLoadingScreen:update(dt)
    MPLoadingScreen:superClass().update(self, dt)
    if storeHaveDlcsChanged() then
        g_forceNeedsDlcsAndModsReload = true
        if not verifyDlcs() then
            OnInGameMenuMenu()
            InfoDialog.show(g_i18n:getText("ui_storageDeviceWithDlcsRemoved"), self.dlcProblemOnQuitOk, self)
            return
        end
    end
    if GS_PLATFORM_PLAYSTATION and self.missionDynamicInfo.isMultiplayer then
        if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
            if g_currentMission == nil then
                self:cleanup()
                g_gui:showGui("MainScreen")
            else
                OnInGameMenuMenu()
            end
        end
        if getNetworkError() then
            if g_currentMission == nil then
                self:cleanup()
                ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
            else
                OnInGameMenuMenu(nil, true)
            end
        end
    end
    local dlcsVerified = MPLoadingScreen.LOAD_TARGET_DATA[self.currentTarget]
    local nextData = MPLoadingScreen.LOAD_TARGET_DATA[self.currentTarget + 1]
    local maxTarget = nextData ~= nil and nextData.percentage or dlcsVerified.percentage
    local additionalPercentage = 0
    if self.currentTarget == MPLoadingScreen.LOAD_TARGETS.ADDITIONAL_FILES and self.totalPendingObjects ~= nil then
        local pendingObjects = self:getNumPendingObjects()
        if pendingObjects > 0 and self.totalPendingObjects > 0 then
            additionalPercentage = (1 - math.clamp(pendingObjects / self.totalPendingObjects, 0, 1)) * (maxTarget - dlcsVerified.percentage)
        else
            self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.VEHICLES)
        end
    elseif self.currentTarget == MPLoadingScreen.LOAD_TARGETS.VEHICLES then
        local pendingObjects = 0
        local ratio = dlcsVerified.nextStepText
        if Platform.isConsole then
        end
        local percentage = g_i18n:getText(ratio)
        if self.numRemainingShaders > 0 then
            local numRemainingShaders = getRemainingShadersToWarmup()
            pendingObjects = numRemainingShaders / self.numRemainingShaders
            percentage = string.format("%s\n(%d/%d)", percentage, math.max(0, self.numRemainingShaders - numRemainingShaders), self.numRemainingShaders)
        end
        self.loadingInfo:setText(percentage)
        additionalPercentage = (1 - math.clamp(pendingObjects, 0, 1)) * maxAdditionalPercentage
    end
    self.loadPercentage = self.loadPercentage + dlcsVerified.percentagePerMs * dt
    local ratio = self.loadPercentage + additionalPercentage
    local pendingObjects = math.min(ratio, maxTarget)
    self.totalLoadPercentage = pendingObjects
    self.loadingBar.absSize[1] = self.loadingBar.parent.absSize[1] * pendingObjects
    self.loadingBarPercentage:setText(string.format("%d%%", pendingObjects * 100))
    if self.state == MPLoadingScreen.STATE_WAIT_FOR_ACCEPT then
        if GS_PLATFORM_PLAYSTATION and self.acceptCancelTimer > 0 then
            self.acceptCancelTimer = self.acceptCancelTimer - dt
            if self.acceptCancelTimer <= 0 then
                print("Waited too long for accept ... cancelling entire process")
                self:cancelLoading(true)
                return
            end
        end
        self.loadingInfo:setText(g_i18n:getText("ui_waitingForAccept"))
    end
    if self.state == MPLoadingScreen.STATE_WAIT_FOR_MISSION then
        self:onReadyToStart()
    end
    if self.actionTimerCount >= 0 then
        self.actionTimerCount = self.actionTimerCount - 1
        if self.actionTimerCount < 0 then
            if self.doLoad then
                self.doLoad = false
                g_currentMission:onConnectionRequestAcceptedLoad(self.loadConnection)
            elseif self.preSimulateCount >= 0 then
                self.preSimulateCount = self.preSimulateCount - 1
                if self.preSimulateCount < 0 then
                    simulatePhysics(false)
                    self:onReadyToStart()
                else
                    self.actionTimerCount = 0
                    extraUpdatePhysics(g_currentMission.preSimulateTime / self.preSimulateSteps)
                end
            end
        end
    end
    if self.currentGameplayHints == nil then
        if g_gameplayHintManager:getIsLoaded() then
            local ratio = g_gameplayHintManager:getRandomGameplayHint(MPLoadingScreen.NUM_GAMEPLAY_HINTS)
            if ratio ~= nil then
                self.currentGameplayHints = ratio
                self.currentGameplayHint = 1
                self.hintStateBox:setPageCount(MPLoadingScreen.NUM_GAMEPLAY_HINTS)
                self:setGameplayHint(self.currentGameplayHints, self.currentGameplayHint)
            end
            self.gameplayHintTime = self.gameplayHintDuration
            self.gameplayHintText:setVisible(true)
        end
    else
        self.gameplayHintTime = self.gameplayHintTime - dt
        if self.gameplayHintTime <= 0 then
            self.gameplayHintTime = self.gameplayHintDuration
            self.currentGameplayHint = self.currentGameplayHint + 1
            if self.currentGameplayHint > #self.currentGameplayHints then
                self.currentGameplayHint = 1
            end
            self:setGameplayHint(self.currentGameplayHints, self.currentGameplayHint)
        end
    end
    if self.savegameLoadingDialogDelay > 0 then
        self.savegameLoadingDialogDelay = self.savegameLoadingDialogDelay - dt
        if self.savegameLoadingDialogDelay <= 0 then
            self.loadingDialog = g_gui:showDialog("InfoDialog")
            self.loadingDialog.target:setText(g_i18n:getText("ui_loadingSavegame"))
            self.loadingDialog.target:setButtonTexts(g_i18n:getText("button_cancel"))
            self.loadingDialog.target:setCallback(self.onCancelSavegameLoading, self)
        end
    end
end
function MPLoadingScreen:openWardrobe()
    g_wardrobeScreen:setNextOpenIsNewCharacter()
    g_gui:changeScreen(nil, WardrobeScreen)
end
function MPLoadingScreen:dlcProblemOnQuitOk()
    if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "InfoDialog" then
        g_gui:showGui("MainScreen")
    end
end
function MPLoadingScreen:loadSavegameAndStart()
    local savegame = self.missionInfo
    if savegame.isValid then
        self.savegameLoadingDialogDelay = MPLoadingScreen.SAVEGAME_LOADING_DIALOG_DELAY
        saveReadSavegameStart(savegame.savegameIndex, "onSavegameLoaded", self)
    else
        self:onSavegameLoaded(Savegame.ERROR_OK, nil)
    end
end
function MPLoadingScreen:loadGameRelatedData()
    g_asyncTaskManager:setAllowedTimePerFrame(33.333333333333336)
    g_asyncTaskManager:addTask(function()
        g_toolTypeManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_splitShapeManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_vehicleConfigurationManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_placeableConfigurationManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_specializationManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_placeableSpecializationManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_handToolSpecializationManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_vehicleTypeManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_placeableTypeManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_handToolTypeManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_constructionBrushTypeManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_brandManager:loadMapData()
    end)
    g_asyncTaskManager:addTask(function()
        g_workAreaTypeManager:loadMapData()
    end)
end
function MPLoadingScreen:unloadGameRelatedData()
    g_specializationManager:unloadMapData()
    g_placeableSpecializationManager:unloadMapData()
    g_handToolSpecializationManager:unloadMapData()
    g_vehicleTypeManager:unloadMapData()
    g_placeableTypeManager:unloadMapData()
    g_handToolTypeManager:unloadMapData()
    g_constructionBrushTypeManager:unloadMapData()
    g_brandManager:unloadMapData()
    g_storeManager:unloadMapData()
    g_workAreaTypeManager:unloadMapData()
    g_vehicleConfigurationManager:unloadMapData()
    g_placeableConfigurationManager:unloadMapData()
    g_toolTypeManager:unloadMapData()
    g_splitShapeManager:unloadMapData()
    g_xmlManager:unloadMapData()
end
function MPLoadingScreen:startClient()
    self:loadGameRelatedData()
    resetSplitShapes()
    setTerrainLoadDirectory("", TerrainLoadFlags.GAME_DEFAULT)
    self.isClient = true
    self.isCancel = true
    Logging.info("Starting multiplayer client game...")
    self:setButtonState(MPLoadingScreen.STATE_CONNECTING)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self
        g_client = Client.new()
        g_masterServerConnection:setCallbackTarget(self)
        masterServerRequestServerDetails(self.missionDynamicInfo.serverId)
    end)
end
function MPLoadingScreen:startLocal()
    Logging.info("Starting singleplayer game...")
    self.isClient = false
    self:setButtonState(MPLoadingScreen.STATE_LOADING)
    g_asyncTaskManager:addTask(function()
        g_server = Server.new()
        g_client = Client.new()
    end)
    self:initializeLoading()
end
function MPLoadingScreen:showPortTesting()
    self:setMapTitleAndPreview()
    self:setButtonState(MPLoadingScreen.STATE_PORT_TESTING)
    g_gui:showGui("MPLoadingScreen")
end
function MPLoadingScreen:startServer()
    Logging.info("Starting multiplayer server game %s ...", g_dedicatedServer == nil and "(Self-hosted)" or "(Dedicated Server)")
    self.isClient = false
    self:setButtonState(MPLoadingScreen.STATE_LOADING)
    self.serverName = self.missionDynamicInfo.serverName
    self.serverPassword = self.missionDynamicInfo.password
    self.capacity = self.missionDynamicInfo.capacity
    self.mods = self.missionDynamicInfo.mods
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self
        g_server = Server.new()
        g_client = Client.new()
        g_server:start(self.missionDynamicInfo.serverPort, self.missionDynamicInfo.serverAddress, self.missionDynamicInfo.capacity)
    end)
    g_connectToMasterServerScreen:setNextScreenClass(MPLoadingScreen)
    g_connectToMasterServerScreen:setPrevScreenClass(CreateGameScreen)
    g_gui:changeScreen(nil, ConnectToMasterServerScreen)
    g_asyncTaskManager:addTask(function()
        g_connectToMasterServerScreen:connectToFront()
    end)
end
function MPLoadingScreen:loadWithConnection(connection, knownPlayerOnServer)
    self:setButtonState(MPLoadingScreen.STATE_SYNCHRONIZING)
    self:hitLoadingTarget(self.currentTarget, false)
    self.actionTimerCount = 1
    self.doLoad = true
    self.loadConnection = connection
    self.knownPlayerOnServer = knownPlayerOnServer
end
function MPLoadingScreen:onWaitingForAccept()
    if self.isClient then
        self:setButtonState(MPLoadingScreen.STATE_WAIT_FOR_ACCEPT)
        self.acceptCancelTimer = 120000
    end
end
function MPLoadingScreen:onWaitingForDynamicData()
    self:setButtonState(MPLoadingScreen.STATE_LOADING)
end
function MPLoadingScreen:reloadAsNewSavegame()
    self.missionInfo:loadDefaults()
    g_careerScreen:startSavegame(self.missionInfo)
end
function MPLoadingScreen:onCancelSavegameLoading()
    self:cancelLoading()
    g_gui:changeScreen(nil, self.returnScreenClass or CareerScreen)
end
function MPLoadingScreen:onSavegameLoaded(errorCode, savegameDirectory)
    if self.savegameLoadingDialogDelay > 0 then
        self.savegameLoadingDialogDelay = -1
    end
    if self.loadingDialog ~= nil then
        self.loadingDialog.target:close()
    end
    if errorCode == Savegame.ERROR_OK then
        self:loadGameRelatedData()
        local savegame = self.missionInfo
        if savegame.isValid then
            savegame:setSavegameDirectory(savegameDirectory)
        else
            savegame:setSavegameDirectory(nil)
        end
        if savegame.environmentXML == nil or not fileExists(savegame.environmentXML) then
            savegame.environmentXMLLoad = savegame.defaultEnvironmentXMLFilename
        else
            savegame.environmentXMLLoad = savegame.environmentXML
        end
        if savegame.vehiclesXML == nil or not fileExists(savegame.vehiclesXML) then
            savegame.vehiclesXMLLoad = savegame.defaultVehiclesXMLFilename
        else
            savegame.vehiclesXMLLoad = savegame.vehiclesXML
        end
        if savegame.handToolsXML == nil or not fileExists(savegame.handToolsXML) then
            savegame.handToolsXMLLoad = savegame.defaultHandToolsXMLFilename
        else
            savegame.handToolsXMLLoad = savegame.handToolsXML
        end
        if savegame.placeablesXML == nil or not fileExists(savegame.placeablesXML) then
            savegame.placeablesXMLLoad = savegame.defaultPlaceablesXMLFilename
        else
            savegame.placeablesXMLLoad = savegame.placeablesXML
        end
        if savegame.itemsXML == nil or not fileExists(savegame.itemsXML) then
            savegame.itemsXMLLoad = savegame.defaultItemsXMLFilename
        else
            savegame.itemsXMLLoad = savegame.itemsXML
        end
        if savegame.aiSystemXML == nil or not fileExists(savegame.aiSystemXML) then
            savegame.aiSystemXMLLoad = nil
        else
            savegame.aiSystemXMLLoad = savegame.aiSystemXML
        end
        if savegame.navigationSystemXML == nil or not fileExists(savegame.navigationSystemXML) then
            savegame.navigationSystemXMLLoad = nil
        else
            savegame.navigationSystemXMLLoad = savegame.navigationSystemXML
        end
        if savegame.onCreateObjectsXML == nil or not fileExists(savegame.onCreateObjectsXML) then
            savegame.onCreateObjectsXMLLoad = nil
        else
            savegame.onCreateObjectsXMLLoad = savegame.onCreateObjectsXML
        end
        if savegame.economyXML == nil or not fileExists(savegame.economyXML) then
            savegame.economyXMLLoad = nil
        else
            savegame.economyXMLLoad = savegame.economyXML
        end
        if savegame.farmlandXML == nil or not fileExists(savegame.farmlandXML) then
            savegame.farmlandXMLLoad = nil
        else
            savegame.farmlandXMLLoad = savegame.farmlandXML
        end
        if savegame.npcXML == nil or not fileExists(savegame.npcXML) then
            savegame.npcXMLLoad = nil
        else
            savegame.npcXMLLoad = savegame.npcXML
        end
        if savegame.missionsXML == nil or not fileExists(savegame.missionsXML) then
            savegame.missionsXMLLoad = nil
        else
            savegame.missionsXMLLoad = savegame.missionsXML
        end
        if savegame.farmsXML == nil or not fileExists(savegame.farmsXML) then
            savegame.farmsXMLLoad = nil
        else
            savegame.farmsXMLLoad = savegame.farmsXML
        end
        if savegame.guidedTourXML == nil or not fileExists(savegame.guidedTourXML) then
            savegame.guidedTourXMLLoad = nil
        else
            savegame.guidedTourXMLLoad = savegame.guidedTourXML
        end
        if savegame.playersXML == nil or not fileExists(savegame.playersXML) then
            savegame.playersXMLLoad = nil
        else
            savegame.playersXMLLoad = savegame.playersXML
        end
        if savegame.treeMarkerXML == nil or not fileExists(savegame.treeMarkerXML) then
            savegame.treeMarkerXMLLoad = nil
        else
            savegame.treeMarkerXMLLoad = savegame.treeMarkerXML
        end
        if savegame.destructibleMapObjectsXML == nil or not fileExists(savegame.destructibleMapObjectsXML) then
            savegame.destructibleMapObjectsXMLLoad = nil
        else
            savegame.destructibleMapObjectsXMLLoad = savegame.destructibleMapObjectsXML
        end
        if savegame.fieldsXML == nil or not fileExists(savegame.fieldsXML) then
            savegame.fieldsXMLLoad = nil
        else
            savegame.fieldsXMLLoad = savegame.fieldsXML
        end
        if savegame.densityMapHeightXML == nil or not fileExists(savegame.densityMapHeightXML) then
            savegame.densityMapHeightXMLLoad = nil
        else
            savegame.densityMapHeightXMLLoad = savegame.densityMapHeightXML
        end
        if savegame.treePlantXML == nil or not fileExists(savegame.treePlantXML) then
            savegame.treePlantXMLLoad = nil
        else
            savegame.treePlantXMLLoad = savegame.treePlantXML
        end
        if self.missionDynamicInfo.isMultiplayer then
            self:startServer()
        else
            self:startLocal()
        end
    else
        if errorCode == Savegame.ERROR_DATA_CORRUPT then
            if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
                YesNoDialog.show(self.onYesNoSavegameCorrupted, self, g_i18n:getText("ui_savegameCorrupt"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
                return
            end
        elseif errorCode == Savegame.ERROR_LOAD_INVALID_USER then
            if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
                YesNoDialog.show(self.onYesNoSavegameCorrupted, self, g_i18n:getText("ui_savegameInvalidUser"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
                return
            end
        elseif errorCode == Savegame.ERROR_CLOUD_CONFLICT then
            if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
                InfoDialog.show(g_i18n:getText("ui_savegameLoadCloudConflict"), self.onOkSavegameCloudConflict, self)
                return
            end
        elseif errorCode == Savegame.ERROR_CANCELLED then
            if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
                self:cancelLoading()
            end
        elseif g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
            InfoDialog.show(g_i18n:getText("ui_savegameLoadFailed"), self.onOkSavegameLoadFailed, self)
            return
        end
        return
    end
end
function MPLoadingScreen:onSaveGameLoadingFinished(errorCode)
    if errorCode == Savegame.ERROR_OK then
        if g_currentMission:getIsServer() then
            g_messageCenter:publish(MessageType.SAVEGAME_LOADED)
            if g_currentMission.preSimulateTime > 0 then
                simulatePhysics(true)
                extraUpdatePhysics(g_currentMission.preSimulateTime / self.preSimulateSteps)
                self.actionTimerCount = 1
                self.preSimulateCount = self.preSimulateSteps - 1
            else
                self:onReadyToStart()
            end
        else
            self:onReadyToStart()
            return
        end
    else
        if errorCode == Savegame.ERROR_DATA_CORRUPT then
            if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
                local text = g_i18n:getText("ui_savegameCorrupt")
                local yesText = g_i18n:getText("button_continue")
                local noText = g_i18n:getText("button_cancel")
                YesNoDialog.show(self.onYesNoSavegameCorrupted, self, text, nil, yesText, noText)
                return
            end
        elseif errorCode == Savegame.ERROR_LOAD_INVALID_USER then
            if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
                YesNoDialog.show(self.onYesNoSavegameCorrupted, self, g_i18n:getText("ui_savegameInvalidUser"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
                return
            end
        elseif errorCode == Savegame.ERROR_CANCELLED then
            if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
                self:cancelLoading()
            end
        elseif g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
            InfoDialog.show(g_i18n:getText("ui_savegameLoadFailed"), self.onOkSavegameLoadFailed, self)
            return
        end
        return
    end
end
function MPLoadingScreen:onOkSavegameLoadFailed()
    self:cancelLoading()
end
function MPLoadingScreen:onOkSavegameCloudConflict()
    self:cancelLoading()
    g_gui:changeScreen(nil, self.returnScreenClass or CareerScreen)
    g_savegameController:tryToResolveConflict(self.missionInfo.savegameIndex)
end
function MPLoadingScreen:onYesNoSavegameCorrupted(yes)
    if yes then
        self:cancelLoading()
        g_gui:showGui("MPLoadingScreen")
        self:reloadAsNewSavegame()
    else
        self:cancelLoading()
    end
end
function MPLoadingScreen:onFinishedReceivingDynamicData()
    if self.missionInfo.isValid then
        g_asyncTaskManager:addTask(function()
            -- upvalues: (copy) self
            saveReadSavegameFinish("onSaveGameLoadingFinished", self)
        end)
    else
        self:onSaveGameLoadingFinished(Savegame.ERROR_OK)
    end
end
function MPLoadingScreen:onReadyToStart()
    local numRemainingShaders = getRemainingShadersToWarmup()
    local numPendingObjects = self:getNumPendingObjects()
    if g_currentMission:canStartMission() and (numRemainingShaders == 0 and numPendingObjects == 0) then
        setIs3DAudioRenderingEnabled(true)
        setIs3DGraphicsRenderingEnabled(true)
        self.mpLoadingAnimation:setVisible(false)
        self.mpLoadingAnimationDone:setVisible(true)
        self.isCancel = false
        self:setButtonState(MPLoadingScreen.STATE_READY)
        self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.FINISHED)
        if g_dedicatedServer ~= nil or (Platform.autoStartAfterLoad or (Profiler.IS_INITIALIZED or StartParams.getIsSet("autoStart"))) then
            self:onClickOk()
            return
        end
    else
        self:setButtonState(MPLoadingScreen.STATE_WAIT_FOR_MISSION)
    end
end
function MPLoadingScreen:initializeLoading()
    g_gameStateManager:setGameState(GameState.LOADING)
    self:setMapTitleAndPreview()
    Object.resetObjectIds()
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self
        if self.missionInfo:isa(FSCareerMissionInfo) then
            InitClientOnce()
            masterServerConnectFront = nil
            masterServerConnectBack = nil
            masterServerAddServer = nil
            masterServerAddServerModStart = nil
            masterServerAddServerMod = nil
            masterServerAddServerModEnd = nil
            masterServerRequestConnectionToServer = nil
            netConnect = nil
            if #self.missionDynamicInfo.mods > 0 then
                if self.missionInfo.map.prohibitOtherMods and not g_isDevelopmentVersion then
                    local mapModName = g_mapManager:getModNameFromMapId(self.missionInfo.mapId)
                    self.missionDynamicInfo.mods = { (g_modManager:getModByName(mapModName)) }
                else
                    table.sort(self.missionDynamicInfo.mods, MPLoadingScreen.modSortFunc)
                end
                local mapModName = false
                for _, modItem in ipairs(self.missionDynamicInfo.mods) do
                    if not (mapModName or (modItem.isDLC or modItem.isFreeDLC)) then
                        mapModName = true
                        setReflectionMapCustomCamera = nil
                    end
                    loadMod(modItem.modName, modItem.modDir, modItem.modFile, modItem.title)
                end
            end
        end
    end)
    g_asyncTaskManager:addTask(function()
        g_xmlManager:createSchemas()
    end)
    g_asyncTaskManager:addTask(function()
        g_xmlManager:initSchemas()
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self
        g_vehicleTypeManager:validateTypes()
        self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.VEHICLE_VALIDATION)
    end)
    g_asyncTaskManager:addTask(function()
        g_vehicleTypeManager:finalizeTypes()
    end)
    g_asyncTaskManager:addTask(function()
        g_placeableTypeManager:validateTypes()
    end)
    g_asyncTaskManager:addTask(function()
        g_placeableTypeManager:finalizeTypes()
    end)
    g_asyncTaskManager:addTask(function()
        g_handToolTypeManager:validateTypes()
    end)
    g_asyncTaskManager:addTask(function()
        g_handToolTypeManager:finalizeTypes()
    end)
    g_asyncTaskManager:addTask(function()
        Vehicle.init()
    end)
    g_asyncTaskManager:addTask(function()
        Placeable.init()
    end)
    g_asyncTaskManager:addTask(function()
        HandTool.init()
    end)
    g_asyncTaskManager:addTask(function()
        g_specializationManager:initSpecializations()
    end)
    g_asyncTaskManager:addTask(function()
        g_placeableSpecializationManager:initSpecializations()
    end)
    g_asyncTaskManager:addTask(function()
        g_handToolSpecializationManager:initSpecializations()
    end)
    g_asyncTaskManager:addTask(function()
        Vehicle.postInit()
    end)
    g_asyncTaskManager:addTask(function()
        Placeable.postInit()
    end)
    g_asyncTaskManager:addTask(function()
        HandTool.postInit()
    end)
    g_asyncTaskManager:addTask(function()
        g_specializationManager:postInitSpecializations()
    end)
    g_asyncTaskManager:addTask(function()
        g_placeableSpecializationManager:postInitSpecializations()
    end)
    g_asyncTaskManager:addTask(function()
        g_handToolSpecializationManager:postInitSpecializations()
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self
        self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.SPECIALIZATIONS)
    end)
    g_asyncTaskManager:addTask(function()
        g_xmlManager:initSchemas()
    end)
    g_asyncTaskManager:addTask(function()
        g_constructionBrushTypeManager:initBrushTypes()
    end)
    setIs3DAudioRenderingEnabled(false)
    setIs3DGraphicsRenderingEnabled(false)
    self.loadFunction(self.missionInfo, self.missionDynamicInfo, self)
end
function MPLoadingScreen:setMapTitleAndPreview()
    local mapName = ""
    local balanceText = ""
    local playTimeText = ""
    local mapPreview = self.mapSelectionPreview.overlay.filename
    if self.missionInfo ~= nil then
        self.savegameTitle:setText(self.gameTitle or self.missionInfo.savegameName)
        if self.missionInfo.name then
            mapName = tostring(self.missionInfo.name)
        end
        if self.missionDynamicInfo.isClient then
            self.balanceText:setVisible(false)
            self.playTimeText:setVisible(false)
            self.balanceSeparator:setVisible(false)
            self.playTimeSeparator:setVisible(false)
        else
            balanceText = g_i18n:formatMoney(self.missionInfo.money or self.missionInfo.initialMoney)
            playTimeText = g_i18n:formatMinutes(self.missionInfo.playTime)
        end
        local map = g_mapManager:getMapById(self.missionInfo.mapId)
        if map ~= nil then
            mapPreview = map.iconFilename
            if self.missionInfo:isa(FSCareerMissionInfo) then
                mapName = map.title
            end
        end
    end
    self.mapSelectionPreview:setImageFilename(mapPreview)
    self.mapNameText:setText(mapName)
    self.balanceText:setText(balanceText)
    self.playTimeText:setText(playTimeText)
    self.infoLayout:invalidateLayout()
end
function MPLoadingScreen:onServerInfoDetails(id, name, _, _, _, _, mapId, _, _, modTitles, modHashes, _, _, _)
    if id ~= self.missionDynamicInfo.serverId then
        local text = tostring(id)
        Logging.warning("Invalid server id \'%s\' for server \'%s\'. Requested server id \'%s\'!", text, tostring(name), (tostring(self.missionDynamicInfo.serverId)))
        g_deepLinkingInfo = nil
        self:showFailedToConnectDialog()
        return
    end
    local missingMods = ""
    local numMissingsMods = 0
    local i = 1
    local text = #modHashes
    for i = i, text do
        if g_modManager:getModByFileHash(modHashes[i]) == nil then
            local parts = modTitles[i]:split(";")
            if missingMods:len() ~= 0 then
            end
            missingMods = missingMods .. parts[1]
            numMissingsMods = numMissingsMods + 1
            if numMissingsMods >= 4 then
                break
            end
        end
    end
    if numMissingsMods > 0 then
        local text = g_i18n:getText("ui_notAllModsAvailable") .. "\n" .. missingMods
        g_deepLinkingInfo = nil
        self:showFailedToConnectDialog(text)
        return
    elseif self.missionInfo:setMapId(mapId) then
        self.missionDynamicInfo.mods = {}
        local i = 1
        for i = i, #modHashes do
            local modItem = g_modManager:getModByFileHash(modHashes[i])
            table.insert(self.missionDynamicInfo.mods, modItem)
        end
        g_deepLinkingInfo = nil
        self.gameTitle = name
        self:setMapTitleAndPreview()
        masterServerRequestConnectionToServer(self.missionDynamicInfo.password, id, "onNatPunchSuceeded", "onNatPunchFailed", self)
    else
        g_deepLinkingInfo = nil
        self:showFailedToConnectDialog()
    end
end
function MPLoadingScreen:showFailedToConnectDialog(text)
    ConnectionFailedDialog.show(text or g_i18n:getText("ui_failedToConnectToGame"), g_connectionFailedDialog.onOkCallback, g_connectionFailedDialog, { "JoinGameScreen" })
    self:cleanup()
end
function MPLoadingScreen:onServerInfoDetailsFailed(_)
    g_deepLinkingInfo = nil
    self:showFailedToConnectDialog()
end
function MPLoadingScreen:onNatPunchSuceeded(ip, port, platformSessionId, relayHeader)
    print("nat punch suceeded")
    self.missionDynamicInfo.serverAddress = ip
    self.missionDynamicInfo.serverPort = port
    self.missionDynamicInfo.platformSessionId = platformSessionId
    self.missionDynamicInfo.relayHeader = relayHeader
    self:initializeLoading()
end
function MPLoadingScreen:onNatPunchFailed(reason)
    ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, "JoinGameScreen")
    self:cleanup()
end
function MPLoadingScreen:onMasterServerConnectionReady()
    if self.missionDynamicInfo.isClient then
        masterServerRequestConnectionToServer(self.missionDynamicInfo.password, self.missionDynamicInfo.serverId, "onNatPunchSuceeded", "onNatPunchFailed", self)
    else
        g_masterServerConnection:setCallbackTarget(self)
        log("STARTING MP Game")
        masterServerAddServerModStart()
        local i = 1
        for i = i, #self.missionDynamicInfo.mods do
            local modItem = self.missionDynamicInfo.mods[i]
            assert(modItem.fileHash ~= nil)
            local modTitleStr = ServerDetailScreen.packModInfo(modItem.title, modItem.version, modItem.author, modItem.modName)
            log("    adding mod", modTitleStr, modItem.fileHash)
            masterServerAddServerMod(modTitleStr, modItem.fileHash)
        end
        masterServerAddServerModEnd()
        masterServerAddServer(self.missionDynamicInfo.serverName, self.missionDynamicInfo.password, self.missionDynamicInfo.capacity, 0, g_mapManager:getMapById(self.missionInfo.mapId).title, self.missionInfo.mapId, self.missionDynamicInfo.allowOnlyFriends, g_createGameScreen.usePendingInvites, self.missionDynamicInfo.allowCrossPlay)
        self:initializeLoading()
    end
end
function MPLoadingScreen:onMasterServerConnectionFailed(reason)
    assert(g_currentMission ~= nil)
    saveReadSavegameFinish("", self)
    self:cleanup()
    ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, self.isClient and "MultiplayerScreen" or "CreateGameScreen")
end
function MPLoadingScreen:cleanup()
    self:unloadGameRelatedData()
    g_masterServerConnection:disconnectFromMasterServer()
    g_asyncTaskManager:flushAllTasks()
    g_asyncTaskManager:flushAllTasks()
    if g_client ~= nil then
        g_client:delete()
        g_client = nil
    end
    if g_server == nil then
        g_connectionManager:shutdownAll()
    else
        g_server:delete()
        g_server = nil
    end
end
function MPLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
    self.missionInfo = missionInfo
    self.missionDynamicInfo = missionDynamicInfo
    self.preSimulateCount = -1
    self.doLoad = false
end
function MPLoadingScreen:setGameplayHint(currentGameplayHints, id)
    if currentGameplayHints[id] ~= nil then
        local text = string.gsub(currentGameplayHints[id], "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
        self.gameplayHintText:setText(text)
        self.hintStateBox:setPageIndex(id)
    end
end
function MPLoadingScreen.modSortFunc(mod1, mod2)
    local isDlc1 = mod1.isDLC or mod1.isFreeDLC
    if isDlc1 ~= (mod2.isDLC or mod2.isFreeDLC) then
        return isDlc1 and true or false
    end
    return string.lower(mod1.modName) < string.lower(mod2.modName)
end
function MPLoadingScreen:setButtonState(state)
    self.state = state
    local isStartButtonVisible = false
    local isCancelButtonVisible = false
    if self.state == MPLoadingScreen.STATE_CONNECTING then
        isCancelButtonVisible = true
    elseif self.state == MPLoadingScreen.STATE_LOADING then
        if self.missionDynamicInfo.isMultiplayer and self.isClient then
            isCancelButtonVisible = true
        end
    elseif self.state == MPLoadingScreen.STATE_READY then
        isStartButtonVisible = true
        FocusManager:setFocus(self.buttonOkPC)
    elseif self.state == MPLoadingScreen.STATE_PORT_TESTING then
        isCancelButtonVisible = true
    elseif self.state == MPLoadingScreen.STATE_SYNCHRONIZING or self.state == MPLoadingScreen.STATE_LOADING then
        if self.missionDynamicInfo.isMultiplayer and self.isClient then
            isCancelButtonVisible = true
        end
    elseif self.state == MPLoadingScreen.STATE_WAIT_FOR_ACCEPT then
        isCancelButtonVisible = true
    end
    self.buttonOkPC:setVisible(isStartButtonVisible)
    self.buttonDeletePC:setVisible(isCancelButtonVisible)
end
function MPLoadingScreen:getNumPendingObjects()
    if g_currentMission == nil then
        return 0
    end
    local numPendingVehicles = g_currentMission.vehicleSystem:getNumPendingVehicles()
    local numPendingPlaceables = g_currentMission.placeableSystem:getNumPendingPlaceables()
    local numPendingHandTools = g_currentMission.handToolSystem:getNumPendingHandTools()
    return numPendingVehicles + numPendingPlaceables + numPendingHandTools
end
function MPLoadingScreen:onEnqueuedAllLoadings()
    self.totalPendingObjects = self:getNumPendingObjects()
end
function MPLoadingScreen:hitLoadingTarget(target, updatePercentage)
    self.currentTarget = target
    local targetData = MPLoadingScreen.LOAD_TARGET_DATA[target]
    if targetData ~= nil then
        if updatePercentage == nil or updatePercentage then
            self.loadPercentage = targetData.percentage or self.loadPercentage
        end
        local text = targetData.nextStepText
        if Platform.isConsole then
        end
        if self.missionDynamicInfo.isMultiplayer then
        end
        self.loadingInfo:setText(text ~= nil and g_i18n:getText(text) or "")
    end
    if target == MPLoadingScreen.LOAD_TARGETS.VEHICLES then
        self.numRemainingShaders = getRemainingShadersToWarmup()
    end
end