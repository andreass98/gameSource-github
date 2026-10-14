FSBaseMission = {}
FSBaseMission.USER_STATE_LOADING = 1
FSBaseMission.USER_STATE_SYNCHRONIZING = 2
FSBaseMission.USER_STATE_CONNECTED = 3
FSBaseMission.USER_STATE_INGAME = 4
FSBaseMission.CONNECTION_LOST_DEFAULT = 0
FSBaseMission.CONNECTION_LOST_KICKED = 1
FSBaseMission.CONNECTION_LOST_BANNED = 2
FSBaseMission.LIMITED_OBJECT_TYPE_BALE = 1
FSBaseMission.INGAME_NOTIFICATION_OK = {
    0.305,
    0.521,
    0.0356,
    1
}
FSBaseMission.INGAME_NOTIFICATION_INFO = {
    1,
    1,
    1,
    1
}
FSBaseMission.INGAME_NOTIFICATION_GREATDEMAND = {
    1,
    1,
    1,
    1
}
FSBaseMission.INGAME_NOTIFICATION_CRITICAL = {
    1,
    0.305,
    0,
    1
}
FSBaseMission.RECORDING_DEVICE_CHECK_INTERVAL = 2500
local l_engineState = true
local l_engineStateTimer = math.random(900000, 1200000)
if getEngineState ~= nil then
    l_engineState = getEngineState()
    getEngineState = nil
end
local function onEngineStateCallback()
    openWebFile(Platform.urlBuyNow, "")
end
source("dataS/scripts/events/SavegameSettingsEvent.lua")
source("dataS/scripts/events/BaseMissionFinishedLoadingEvent.lua")
source("dataS/scripts/events/BaseMissionReadyEvent.lua")
source("dataS/scripts/events/SetSplitShapesEvent.lua")
source("dataS/scripts/events/UpdateSplitShapesEvent.lua")
source("dataS/scripts/events/ConnectionRequestEvent.lua")
source("dataS/scripts/events/ConnectionRequestAnswerEvent.lua")
source("dataS/scripts/events/ChangeLoanEvent.lua")
source("dataS/scripts/events/GamePauseEvent.lua")
source("dataS/scripts/events/GamePauseRequestEvent.lua")
source("dataS/scripts/events/PlayerPermissionsEvent.lua")
source("dataS/scripts/events/FinanceStatsEvent.lua")
local FSBaseMission_mt = Class(FSBaseMission, BaseMission)
function FSBaseMission.new(baseDirectory, customMt)
    -- upvalues: (copy) FSBaseMission_mt
    local self = FSBaseMission:superClass().new(baseDirectory, customMt or FSBaseMission_mt)
    g_inGameMenu:setClient(g_client)
    g_inGameMenu:setServer(g_server)
    g_shopMenu:setClient(g_client)
    g_shopMenu:setServer(g_server)
    self.trainSystems = {}
    self.objectsToCallOnMapFinished = {}
    self:registerToLoadOnMapFinished(g_inGameMenu)
    self:registerToLoadOnMapFinished(g_shopMenu)
    self.mapDensityMapRevision = 1
    self.mapTerrainTextureRevision = 1
    self.mapTerrainLodTextureRevision = 1
    self.mapSplitShapesRevision = 1
    self.mapTipCollisionRevision = 1
    self.mapPlacementCollisionRevision = 1
    self.mapNavigationCollisionRevision = 1
    self.densityMapSyncer = nil
    self.fieldGroundSystem = FieldGroundSystem.new()
    self.stoneSystem = StoneSystem.new()
    self.weedSystem = WeedSystem.new()
    self.playersToAccept = {}
    self.playersLoading = {}
    self.doSaveGameState = SavegameController.SAVE_STATE_NONE
    self.currentDeviceHasNoSpace = false
    self.dediEmptyPaused = false
    self.userSigninPaused = false
    self.isSynchronizingWithPlayers = false
    self.playersSynchronizing = {}
    self.isServerSaving = false
    self.userManager = UserManager.new(self:getIsServer())
    self.aiSystem = AISystem.new(self:getIsServer(), self)
    self.aiJobTypeManager = AIJobTypeManager.new(self:getIsServer())
    self.aiMessageManager = AIMessageManager.new()
    self.animalSystem = AnimalSystem.new(self:getIsServer(), self)
    self.animalFoodSystem = AnimalFoodSystem.new(self)
    self.animalNameSystem = AnimalNameSystem.new(self)
    self.husbandrySystem = HusbandrySystem.new(self:getIsServer(), self)
    self.navigationSystem = NavigationSystem.new()
    self.vineSystem = VineSystem.new(self:getIsServer(), self)
    self.vehicleSaleSystem = VehicleSaleSystem.new(self)
    self.collectiblesSystem = CollectiblesSystem.new(self:getIsServer())
    self.indoorMask = IndoorMask.new(self, self:getIsServer())
    self.snowSystem = SnowSystem.new(self, self:getIsServer())
    self.growthSystem = GrowthSystem.new(self, self:getIsServer())
    self.foliageSystem = FoliageSystem.new()
    self.slotSystem = SlotSystem.new(self, self:getIsServer())
    self.economyManager = EconomyManager.new()
    self.treeMarkerSystem = TreeMarkerSystem.new(self:getIsServer())
    self.destructibleMapObjectSystem = DestructibleMapObjectSystem.new(self, self:getIsServer())
    self.shipSystem = ShipSystem.new()
    self.playerUserId = -1
    self.playerNickname = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
    self.clientUserId = nil
    self.terrainSize = 1
    self.terrainDetailMapSize = 1
    self.fruitMapSize = 1
    self.dynamicFoliageLayers = {}
    self.terrainDetailId = 0
    self.mapsSplitShapeFileIds = {}
    self.isMasterUser = false
    self.connectionWasClosed = false
    self.connectionWasAccepted = false
    self.checkRecordingDeviceTimer = 0
    self.lastRecordingDeviceState = not Platform.hasRecordingDeviceDetection
    self.lastConstructionScreenOpenTime = -1
    self.cameraPaths = {}
    self.cullingWorldXZOffset = 0
    self.cullingWorldMinY = -100
    self.cullingWorldMaxY = 500
    self.cullingClipDistanceThreshold1 = 150
    self.cullingClipDistanceThreshold2 = 400
    self.densityMapPercentageFraction = 0.7
    self.splitShapesPercentageFraction = 0.2
    self.restPercentageFraction = 1 - self.densityMapPercentageFraction - self.splitShapesPercentageFraction
    self.doghouses = {}
    self.tireTrackSystem = nil
    self.liquidManureLoadingStations = {}
    self.manureLoadingStations = {}
    self.connectedToDedicatedServer = false
    self.wasNetworkError = false
    self.ambientSoundSystem = AmbientSoundSystem.new(g_soundPlayer)
    self.environmentAreaSystem = EnvironmentAreaSystem.new()
    self.reverbSystem = ReverbSystem.new(self)
    self.radioEvents = {}
    self.moneyChanges = {}
    self.introductionHelpSystem = IntroductionHelpSystem.new()
    if self:getIsServer() and StartParams.getIsSet("debugCameraClone") then
        self.debugCameraClone = DebugCameraClone.new(true, true)
        self.debugCameraClone:register(false)
    end
    return self
end
function FSBaseMission:initialize()
    FSBaseMission:superClass().initialize(self)
    g_treePlantManager:initialize()
    MoneyType.reset()
    self.foliageBendingSystem = nil
    if Platform.supportsFoliageBending then
        self.foliageBendingSystem = FoliageBendingSystem.new()
    end
    self.accessHandler = AccessHandler.new()
    self.storageSystem = StorageSystem.new(self.accessHandler)
    self:subscribeMessages()
    g_inGameMenu:setInGameMap(self.hud:getIngameMap())
    g_inGameMenu:setHUD(self.hud)
    self.productionChainManager = ProductionChainManager.new(self:getIsServer())
end
function FSBaseMission:delete()
    self.isExitingGame = true
    g_inGameMenu:reset()
    self:pauseRadio()
    if self.missionDynamicInfo ~= nil and self.missionDynamicInfo.isMultiplayer then
        voiceChatCleanup()
    end
    if self.mapOverlayGenerator ~= nil then
        self.mapOverlayGenerator:delete()
    end
    if self.receivingDensityMapEvent ~= nil then
        self.receivingDensityMapEvent:delete()
        self.receivingDensityMapEvent = nil
    end
    if self.receivingSplitShapesEvent ~= nil then
        self.receivingSplitShapesEvent:delete()
        self.receivingSplitShapesEvent = nil
    end
    if self.densityMapSyncer ~= nil then
        self.densityMapSyncer:delete()
    end
    if self.terrainDeformationSyncer ~= nil then
        self.terrainDeformationSyncer:delete()
        self.terrainDeformationSyncer = nil
    end
    destroyLowResCollisionHandler()
    if self.accessHandler ~= nil then
        self.accessHandler:delete()
    end
    if self.storageSystem ~= nil then
        self.storageSystem:delete()
    end
    if self.playerSystem ~= nil then
        self.playerSystem:delete()
    end
    if self.debugCameraClone ~= nil then
        self.debugCameraClone:delete()
    end
    if g_dedicatedServer ~= nil then
        g_dedicatedServer:delete()
    end
    self.growthSystem:delete()
    self.snowSystem:delete()
    self.indoorMask:delete()
    self.collectiblesSystem:delete()
    self.vehicleSaleSystem:delete()
    self.reverbSystem:delete()
    self.environmentAreaSystem:delete()
    self.ambientSoundSystem:delete()
    self.aiSystem:delete()
    self.husbandrySystem:delete()
    self.animalFoodSystem:delete()
    self.animalNameSystem:delete()
    self.animalSystem:delete()
    self.fieldGroundSystem:delete()
    self.stoneSystem:delete()
    self.weedSystem:delete()
    self.vineSystem:delete()
    self.foliageSystem:delete()
    self.slotSystem:delete()
    self.aiJobTypeManager:delete()
    self.aiMessageManager:delete()
    self.introductionHelpSystem:delete()
    self.navigationSystem:delete()
    self.treeMarkerSystem:delete()
    self.destructibleMapObjectSystem:delete()
    g_guidedTourManager:unloadMapData()
    g_farmManager:unloadMapData()
    g_helperManager:unloadMapData()
    g_npcManager:unloadMapData()
    g_farmlandManager:unloadMapData()
    g_missionManager:unloadMapData()
    g_fieldManager:unloadMapData()
    g_gameplayHintManager:unloadMapData()
    g_sprayTypeManager:unloadMapData()
    g_connectionHoseManager:unloadMapData()
    g_consumableManager:unloadMapData()
    g_densityMapHeightManager:unloadMapData()
    g_vehicleTypeManager:unloadMapData()
    g_placeableTypeManager:unloadMapData()
    g_constructionBrushTypeManager:unloadMapData()
    g_specializationManager:unloadMapData()
    g_placeableSpecializationManager:unloadMapData()
    g_treePlantManager:unloadMapData()
    g_materialManager:unloadMapData()
    g_particleSystemManager:unloadMapData()
    g_motionPathEffectManager:unloadMapData()
    g_effectManager:unloadMapData()
    g_animationManager:unloadMapData()
    g_tensionBeltManager:unloadMapData()
    g_groundTypeManager:unloadMapData()
    g_gui:unloadMapData()
    g_xmlManager:unloadMapData()
    g_debugManager:unloadMapData()
    g_noteManager:unloadMapData()
    g_fieldCourseManager:unloadMapData()
    FSBaseMission:superClass().delete(self)
    if AIFieldWorker ~= nil then
        AIFieldWorker.deleteCollisionBox()
    end
    g_shopMenu:reset()
    FSDensityMapUtil.clearCache()
    DensityMapHeightUtil.clearCache()
    g_fillTypeManager:unloadMapData()
    g_fruitTypeManager:unloadMapData()
    g_baleManager:unloadMapData()
    g_vehicleMaterialManager:unloadMapData()
    g_licensePlateManager:unloadMapData()
    g_helpLineManager:unloadMapData()
    g_storeManager:unloadMapData()
    g_workAreaTypeManager:unloadMapData()
    g_vehicleConfigurationManager:unloadMapData()
    g_placeableConfigurationManager:unloadMapData()
    g_toolTypeManager:unloadMapData()
    g_splitShapeManager:unloadMapData()
    g_brandManager:unloadMapData()
    g_sleepManager:unloadMapData()
    if g_dedicatedServer == nil then
        g_wildlifeManager:unloadMapData()
    end
    if self.productionChainManager ~= nil then
        self.productionChainManager:unloadMapData()
    end
    if self.tireTrackSystem ~= nil then
        self.tireTrackSystem:delete()
    end
    if self.foliageBendingSystem ~= nil then
        self.foliageBendingSystem:delete()
    end
    if self.economyManager ~= nil then
        self.economyManager:delete()
        self.economyManager = nil
    end
    if self.shipSystem ~= nil then
        self.shipSystem:delete()
        self.shipSystem = nil
    end
    if g_soundPlayer ~= nil then
        g_soundPlayer:removeEventListener(self)
        if not (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) then
            g_soundPlayer:setStreamingAccessOwner(nil)
        end
    end
    removeConsoleCommand("gsMoneyAdd")
    removeConsoleCommand("gsStoreItemsExport")
    removeConsoleCommand("gsGreatDemandStart")
    removeConsoleCommand("gsTeleport")
    removeConsoleCommand("gsSaveGame")
    removeConsoleCommand("gsActivateCameraPath")
    removeConsoleCommand("gsDisplacementDebug")
    removeConsoleCommand("gsDisplacementReset")
    removeConsoleCommand("gsUnloadTriggersValidate")
    removeConsoleCommand("gsPhysicsStressTest")
    for _, v in pairs(self.cameraPaths) do
        v:delete()
    end
    g_gui:setClient(nil)
    g_gui:setServer(nil)
    g_inGameMenu:setInGameMap(nil)
    g_inGameMenu:setHUD(nil)
    g_inGameMenu:setPlayerFarm(nil)
    g_shopMenu:setPlayerFarm(nil)
    self.userManager:delete()
end
function FSBaseMission:load()
    self:startLoadingTask()
    if self:getIsServer() and g_addTestCommands then
        addConsoleCommand("gsStoreItemsExport", "Exports storeItem data", "consoleCommandExportStoreItems", self)
        addConsoleCommand("gsGreatDemandStart", "Starts a great demand", "consoleStartGreatDemand", self)
        addConsoleCommand("gsSaveGame", "Saves the current savegame", "consoleCommandSaveGame", self)
        addConsoleCommand("gsDisplacementDebug", "Opens the displacement debug dialog", "consoleCommandDisplacementDebug", self)
        addConsoleCommand("gsDisplacementReset", "Resets the displacement", "consoleCommandDisplacementReset", self)
        addConsoleCommand("gsUnloadTriggersValidate", "Validate the height of unload triggers to detect if they are below the terrain", "consoleCommandValidateUnloadTriggers", self)
        addConsoleCommand("gsRunFSDensityMapUtilBenchmark", "Runs a benchmark on FS Density Map Util", "consoleCommandRunDSDensityMapUtil", self)
        addConsoleCommand("gsPhysicsStressTest", "Starts spawning random physic objects", "consoleCommandTogglePhysicsStressTest", self)
    end
    if g_isDevelopmentVersion then
        addConsoleCommand("gsActivateCameraPath", "Activate camera path", "consoleActivateCameraPath", self)
    end
    if self:getIsServer() and g_addCheatCommands or g_isDevelopmentVersion then
        addConsoleCommand("gsTeleport", "Teleports to given field or x/z-position", "consoleCommandTeleport", self, "farmlandId or xPos; [zPos]; [useWorldCoords]")
    end
    self.economyManager:init(self)
    FSBaseMission:superClass().load(self)
    g_inGameMenu:setTerrainSize(self.terrainSize)
    self:setHarvestScaleRatio(unpack(Platform.gameplay.harvestScaleRation))
    self:finishLoadingTask()
end
function FSBaseMission:setHarvestScaleRatio(sprayRatio, plowRatio, limeRatio, weedRatio, stubbleRatio, rollerRatio)
    self.harvestSprayScaleRatio = sprayRatio
    self.harvestPlowScaleRatio = plowRatio
    self.harvestLimeScaleRatio = limeRatio
    self.harvestWeedScaleRatio = weedRatio
    self.harvestStubbleScaleRatio = stubbleRatio
    self.harvestRollerRatio = rollerRatio
end
function FSBaseMission:getHarvestScaleMultiplier(_, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPercentage)
    return 1 + self.harvestSprayScaleRatio * sprayFactor + self.harvestPlowScaleRatio * plowFactor + self.harvestLimeScaleRatio * limeFactor + self.harvestWeedScaleRatio * weedFactor + self.harvestStubbleScaleRatio * stubbleFactor + self.harvestRollerRatio * rollerFactor + (beeYieldBonusPercentage or 0)
end
function FSBaseMission:onStartMission()
    FSBaseMission:superClass().onStartMission(self)
    g_asyncTaskManager:setAllowedTimePerFrame(nil)
    if g_client ~= nil then
        if self:getIsServer() then
            local connection = g_server.clientConnections[NetworkNode.LOCAL_STREAM_ID]
            local user = self.userManager:getUserByConnection(connection)
            local farm = g_farmManager:getFarmByUserId(user:getId())
            local farmId = FarmManager.SPECTATOR_FARM_ID
            if farm ~= nil then
                farmId = farm.farmId
            end
            Player.createServerInstance(true, true, connection, user:getId(), farmId, self.userManager)
            user:setState(FSBaseMission.USER_STATE_INGAME)
        else
            g_client:getServerConnection():sendEvent(ClientStartMissionEvent.new())
        end
        if g_dedicatedServer == nil and Platform.hasAdjustableFrameLimit then
            setFramerateLimiter(true, g_gameSettings:getValue(SettingsModel.SETTING.FRAME_LIMIT))
        end
        if not g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
            self:playRadio()
        end
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_RADIO))
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VEHICLE))
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_GUI))
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.CHARACTER, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_CHARACTER))
    end
    if self.missionInfo ~= nil then
        Logging.info("Savegame Setting \'dirtInterval\': %d", self.missionInfo.dirtInterval)
        Logging.info("Savegame Setting \'snowEnabled\': %s", self.missionInfo.isSnowEnabled)
        Logging.info("Savegame Setting \'trafficEnabled\': %s", self.missionInfo.trafficEnabled)
        Logging.info("Savegame Setting \'growthMode\': %s", GrowthMode.getName(self.missionInfo.growthMode))
        Logging.info("Savegame Setting \'fuelUsage\': %d", self.missionInfo.fuelUsage)
        Logging.info("Savegame Setting \'plowingRequiredEnabled\': %s", self.missionInfo.plowingRequiredEnabled)
        Logging.info("Savegame Setting \'weedsEnabled\': %s", self.missionInfo.weedsEnabled)
        Logging.info("Savegame Setting \'limeRequired\': %s", self.missionInfo.limeRequired)
        Logging.info("Savegame Setting \'stonesEnabled\': %s", self.missionInfo.stonesEnabled)
        Logging.info("Savegame Setting \'economicDifficulty\': %s", EconomicDifficulty.getName(self.missionInfo.economicDifficulty))
        Logging.info("Savegame Setting \'fixedSeasonalVisuals\': %s", self.missionInfo.fixedSeasonalVisuals)
        Logging.info("Savegame Setting \'plannedDaysPerPeriod\': %s", self.missionInfo.plannedDaysPerPeriod)
        if self:getIsServer() then
            self.pendingSavegameDateAchievement = true
        end
        self.introductionHelpSystem:loadHelpElementsFromXML()
        self.introductionHelpSystem:loadShownElements()
    end
    if g_dedicatedServer ~= nil then
        g_dedicatedServer:onStartMission(self)
    end
    if self.helpIconsBase ~= nil then
        self.helpIconsBase:showHelpIcons(g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_ICONS))
    end
    self:notifyPlayerFarmChanged(g_localPlayer)
    if self.missionDynamicInfo.isMultiplayer and g_dedicatedServer == nil then
        voiceChatAddLocalUser(self:getIsServer())
    end
    self.slotSystem:updateSlotUsage()
end
function FSBaseMission:getClientPosition()
    return getWorldTranslation(g_cameraManager:getActiveCamera())
end
function FSBaseMission:getClientGuiVisibility()
    return g_gui:getIsGuiVisible()
end
function FSBaseMission:setLoadingScreen(loadingScreen)
    self.loadingScreen = loadingScreen
end
function FSBaseMission:onConnectionOpened(connection) end
function FSBaseMission:onConnectionAccepted(_)
    self.connectionWasAccepted = true
    if self.loadingScreen ~= nil then
        self.loadingScreen:onWaitingForAccept()
    end
    local mpLanguage = g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE)
    local playerName = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
    g_client:getServerConnection():sendEvent(ConnectionRequestEvent.new(mpLanguage, self.missionDynamicInfo.password, getUniqueUserId(), getUserId(), getPlatformId(), playerName, self.missionDynamicInfo.platformSessionId), nil, true)
end
function FSBaseMission:onConnectionRequest(connection, languageIndex, password, uniqueUserId, platformUserId, platformId, playerName, platformSessionId)
    if connection.streamId == NetworkNode.LOCAL_STREAM_ID then
        local userCount = self.userManager:getNextUserId()
        assert(userCount == 1)
        self.playerUserId = 1
        local user = User.new()
        user:setId(userCount)
        user:setConnection(connection)
        user:setUniqueUserId(uniqueUserId)
        user:setPlatformUserId(platformUserId)
        user:setPlatformId(platformId)
        user:setIsMasterUser(true)
        user:setLanguageIndex(languageIndex)
        user:setConnectedTime(self.time)
        user:setState(FSBaseMission.USER_STATE_CONNECTED)
        user:setNickname(playerName)
        self.playerNickname = playerName
        local keyAlreadyInUse = self.playerSystem:getHasPlayerWithUniqueId(uniqueUserId)
        self.userManager:addUser(user)
        self.userManager:addMasterUserByConnection(connection)
        self:sendNumPlayersToMasterServer(1)
        connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_OK, self.missionInfo.economicDifficulty, self.missionInfo.timeScale, g_dedicatedServer ~= nil, self.playerUserId, playerName, keyAlreadyInUse), nil, true)
        self.slotSystem:updateSlotLimit()
        return
    end
    local userCount = self.userManager:getNumberOfUsers()
    if g_dedicatedServer ~= nil then
    end
    if userCount + #self.playersToAccept >= self.missionDynamicInfo.capacity then
        connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_FULL), nil, true)
        g_server:closeConnection(connection)
        return
    end
    if getIsUserBlocked(uniqueUserId, platformUserId, platformId) then
        connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED), nil, true)
        g_server:closeConnection(connection)
        return
    end
    local user = self.userManager:getUserByUniqueId(uniqueUserId)
    local keyAlreadyInUse = user ~= nil
    if not keyAlreadyInUse then
        for _, playerToAccept in ipairs(self.playersToAccept) do
            if playerToAccept.uniqueUserId == uniqueUserId then
                keyAlreadyInUse = true
                break
            end
        end
    end
    if keyAlreadyInUse then
        if not Platform.isConsole then
            connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ALREADY_IN_USE), nil, true)
            g_server:closeConnection(connection)
            return
        end
        local oldConnection = user:getConnection()
        if oldConnection:getIsServer() then
            connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ALREADY_IN_USE), nil, true)
            g_server:closeConnection(connection)
            return
        end
        g_server:closeConnection(oldConnection)
    end
    if self.slotSystem:getCanConnect(uniqueUserId, platformId) then
        if self.missionDynamicInfo.password == password then
            table.insert(self.playersToAccept, {
                ["connection"] = connection,
                ["playerName"] = playerName,
                ["language"] = languageIndex,
                ["platformUserId"] = platformUserId,
                ["platformId"] = platformId,
                ["uniqueUserId"] = uniqueUserId,
                ["platformSessionId"] = platformSessionId
            })
        else
            connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD), nil, true)
            g_server:closeConnection(connection)
        end
    else
        connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.SLOT_LIMIT_REACHED), nil, true)
        g_server:closeConnection(connection)
        return
    end
end
function FSBaseMission:canPlayerChangeNickname(player, nickname)
    if utf8Strlen(nickname) < 3 then
        return false
    end
    local name = string.trim(nickname)
    if name ~= filterText(name, true, true) then
        return false
    end
    local existingUser = self.userManager:getUserByNickname(nickname, true)
    local index = 1
    while existingUser ~= nil and existingUser.id ~= player.userId do
        existingUser = self.userManager:getUserByNickname(nickname .. " (" .. index .. ")", true)
        index = index + 1
    end
    return true, nickname
end
function FSBaseMission:setPlayerNickname(player, nickname, userId, noEventSend)
    if self:getIsServer() then
        local user, farm = self:canPlayerChangeNickname(player, nickname)
        if user then
            local user = self.userManager:getUserByUserId(player.userId)
            user:setNickname(farm)
            if g_localPlayer == player then
                self.playerNickname = farm
            end
            g_messageCenter:publish(MessageType.PLAYER_NICKNAME_CHANGED, player)
            local farm = g_farmManager:getFarmByUserId(player.userId)
            if farm ~= nil then
                farm:updateLastNickname(player.userId, user)
            end
            if noEventSend == nil or noEventSend == false then
                g_server:broadcastEvent(PlayerSetNicknameEvent.new(player, farm, player.userId), false, nil, player)
                return
            end
        end
    else
        if noEventSend == nil or noEventSend == false then
            g_client:getServerConnection():sendEvent(PlayerSetNicknameEvent.new(player, nickname, player.userId))
            return
        end
        if noEventSend == true then
            local user = self.userManager:getUserByUserId(userId)
            if user ~= nil then
                user:setNickname(nickname)
            end
            if g_localPlayer == player then
                self.playerNickname = nickname
            end
            g_messageCenter:publish(MessageType.PLAYER_NICKNAME_CHANGED, player)
        end
    end
end
function FSBaseMission:onConnectionDenyAccept(connection, isDenied, isAlwaysDenied)
    local playerToAccept = nil
    local i = 1
    local playerName = #self.playersToAccept
    local user = 1
    for i = i, playerName, user do
        local p = self.playersToAccept[i]
        if p.connection == connection then
            table.remove(self.playersToAccept, i)
            playerToAccept = p
            break
        end
    end
    if playerToAccept == nil then
        return
    else
        local playerName = ""
        local user = nil
        local i = false
        local p = ConnectionRequestAnswerEvent.ANSWER_OK
        if isAlwaysDenied then
            setIsUserBlocked(playerToAccept.uniqueUserId, playerToAccept.platformUserId, playerToAccept.platformId, true, playerToAccept.playerName)
            g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
            p = ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED
        elseif isDenied then
            p = ConnectionRequestAnswerEvent.ANSWER_DENIED
        else
            playerName = playerToAccept.playerName
            local uniqueUserId = playerToAccept.uniqueUserId
            i = self.playerSystem:getHasPlayerWithUniqueId(uniqueUserId)
            local index = 1
            local existingUser = self.userManager:getUserByNickname(playerName, true)
            while existingUser ~= nil do
                existingUser = self.userManager:getUserByNickname(playerName .. " (" .. index .. ")", true)
                index = index + 1
            end
            local financeUpdateSendTime = self.time + math.floor(math.random() * 300 + 400)
            user = User.new()
            user:setId(self.userManager:getNextUserId())
            user:setNickname(playerName)
            user:setConnection(connection)
            user:setUniqueUserId(uniqueUserId)
            user:setPlatformUserId(playerToAccept.platformUserId)
            user:setPlatformId(playerToAccept.platformId)
            user:setPlatformSessionId(playerToAccept.platformSessionId)
            user:setLanguageIndex(playerToAccept.language)
            user:setConnectedTime(self.time)
            user:setState(FSBaseMission.USER_STATE_LOADING)
            user:setFinanceUpdateSendTime(financeUpdateSendTime)
            self.userManager:addUser(user)
            self:sendNumPlayersToMasterServer(self.userManager:getNumberOfUsers())
            self:sendPlatformSessionIdsToMasterServer(self.userManager:getAllPlatformSessionIds())
            voiceChatAddConnection(connection.streamId, playerToAccept.uniqueUserId, playerToAccept.platformUserId, playerToAccept.platformId)
            self.playersLoading[connection] = {
                ["connection"] = connection,
                ["user"] = user
            }
            self.slotSystem:updateSlotLimit()
        end
        local languageIndex = g_farmManager:getFarmForUniqueUserId(playerToAccept.uniqueUserId)
        local uniqueUserId = user ~= nil and user:getId() or nil
        local platformSessionId = ConnectionRequestAnswerEvent.new
        local index = self.missionInfo.economicDifficulty
        local existingUser = self.missionInfo.timeScale
        local financeUpdateSendTime = g_dedicatedServer ~= nil
        connection:sendEvent(platformSessionId(p, index, existingUser, financeUpdateSendTime, uniqueUserId, playerName, i), nil, true)
        if p == ConnectionRequestAnswerEvent.ANSWER_OK then
            Player.createServerInstance(g_client ~= nil, false, connection, user:getId(), languageIndex.farmId, self.userManager)
        else
            g_server:closeConnection(connection)
        end
    end
end
function FSBaseMission:onConnectionRequestAnswer(connection, answer, economicDifficulty, timeScale, connectedToDedicatedServer, clientUserId, playerName, knownPlayer)
    if answer == ConnectionRequestAnswerEvent.ANSWER_OK then
        self.missionInfo.economicDifficulty = economicDifficulty
        self.missionInfo.timeScale = timeScale
        self.connectedToDedicatedServer = connectedToDedicatedServer
        self:onConnectionRequestAccepted(connection, knownPlayer)
        self.playerUserId = clientUserId
        self.playerNickname = playerName
    else
        self.connectionWasClosed = true
        local text = g_i18n:getText("ui_serverDeniedAccess")
        if answer == ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD then
            text = g_i18n:getText("ui_wrongPassword")
        elseif answer == ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED then
            text = g_i18n:getText("ui_banned")
        elseif answer == ConnectionRequestAnswerEvent.ANSWER_FULL then
            text = g_i18n:getText("ui_gameFull")
        elseif answer == ConnectionRequestAnswerEvent.ALREADY_IN_USE then
            text = g_i18n:getText("ui_connectionLostKeyInUse")
        elseif answer == ConnectionRequestAnswerEvent.SLOT_LIMIT_REACHED then
            text = g_i18n:getText("ui_serverDeniedSlotLimitReached")
        elseif answer == ConnectionRequestAnswerEvent.MATCH_IN_PROGRESS then
            text = g_i18n:getText("ui_serverDeniedMatchInProgress")
        end
        InfoDialog.show(text, self.onConnectionRequestAnswerOk, self)
    end
end
function FSBaseMission:onConnectionRequestAnswerOk()
    OnInGameMenuMenu()
    if masterServerConnectFront ~= nil then
        g_multiplayerScreen:initJoinGameScreen()
        g_gui:showGui("ConnectToMasterServerScreen")
        if g_masterServerConnection.lastBackServerIndex >= 0 then
            g_connectToMasterServerScreen:connectToBack(g_masterServerConnection.lastBackServerIndex)
            return
        end
        g_connectToMasterServerScreen:connectToFront()
    end
end
function FSBaseMission:onConnectionRequestAccepted(connection, knownPlayer)
    if self.loadingScreen ~= nil then
        self.loadingScreen:loadWithConnection(connection, knownPlayer)
    end
end
function FSBaseMission:onConnectionRequestAcceptedLoad(connection)
    self.loadingConnection = connection
    simulatePhysics(false)
    self:load()
end
function FSBaseMission:onFinishedLoading()
    FSBaseMission:superClass().onFinishedLoading(self)
    self.lastPlayTimeSampleTime = g_time
    if self.missionDynamicInfo.isMultiplayer and not g_gameSettings:getValue(GameSettings.SETTING.PLAYED_MULTIPLAYER) then
        g_gameSettings:setValue(GameSettings.SETTING.PLAYED_MULTIPLAYER, true, true)
    end
    if self:getIsServer() then
        self.pressStartPaused = true
        self:pauseGame()
        if self.loadingScreen ~= nil then
            self.loadingScreen:onFinishedReceivingDynamicData()
        end
    else
        g_cameraManager:setDefaultCamera()
        local x, y, z = self:getClientPosition()
        if self.loadingScreen ~= nil then
            self.loadingScreen:onWaitingForDynamicData()
        end
        self.pressStartPaused = true
        self:pauseGame()
        self.loadingConnection:sendEvent(BaseMissionFinishedLoadingEvent.new(x, y, z, getViewDistanceCoeff()), nil, true)
    end
end
function FSBaseMission:getAllowsGuiDisplay()
    if self.isSynchronizingWithPlayers and g_localPlayer ~= nil then
        return false
    else
        return not g_sleepManager:getIsSleeping()
    end
end
function FSBaseMission:onConnectionFinishedLoading(connection, x, y, z, viewDistanceCoeff)
    local syncPlayer = not connection:getIsLocal()
    assert(syncPlayer, "No local connection allowed in BaseMission:onConnectionFinishedLoading")
    if self.playersSynchronizing[connection] == nil and self.playersLoading[connection] ~= nil then
        local user = self.playersLoading[connection].user
        self.playersLoading[connection] = nil
        addSplitShapeConnection(connection.streamId, user:getPlatformId())
        if self.densityMapSyncer ~= nil then
            self.densityMapSyncer:addConnection(connection.streamId)
        end
        addTerrainUpdateConnection(g_terrainNode, connection.streamId)
        connection:setIsReadyForEvents(true)
        user:setState(FSBaseMission.USER_STATE_SYNCHRONIZING)
        local syncPlayer = {
            ["connection"] = connection,
            ["user"] = user
        }
        self.playersSynchronizing[connection] = syncPlayer
        if g_dedicatedServer ~= nil then
            g_dedicatedServer:raiseFramerate()
            self.dediEmptyPaused = false
        end
        self.isSynchronizingWithPlayers = true
        self:pauseGame()
        g_farmManager:playerJoinedGame(user:getUniqueUserId(), user:getId(), user, connection)
        g_server:sendEventIds(connection)
        g_server:sendObjectClassIds(connection)
        connection:sendEvent(OnCreateLoadedObjectEvent.new())
        connection:sendEvent(PlaceablePreplacedInfoEvent.new())
        g_server:sendObjects(connection, x, y, z, viewDistanceCoeff)
        connection:sendEvent(SavegameSettingsEvent.new())
        connection:sendEvent(SlotSystemUpdateEvent.new(self.slotSystem.slotLimit))
        self:sendInitialClientState(connection, user, (g_farmManager:getFarmForUniqueUserId(user:getUniqueUserId())))
        g_server:broadcastEvent(UserEvent.new(self.userManager:getUsers(), {}, self.missionDynamicInfo.capacity))
        local splitShapesEvent = SetSplitShapesEvent.new()
        syncPlayer.splitShapesEvent = splitShapesEvent
        connection:sendEvent(splitShapesEvent, false)
    else
        g_server:closeConnection(connection)
    end
end
function FSBaseMission:sendInitialClientState(connection, user, farm)
    connection:sendEvent(EnvironmentTimeEvent.new(self.environment.currentMonotonicDay, self.environment.currentDay, self.environment.dayTime, self.environment.daysPerPeriod))
    self.environment.weather:sendInitialState(connection)
    connection:sendEvent(FarmsInitialStateEvent.new(farm.farmId))
    if farm.farmId ~= 0 then
        connection:sendEvent(ChangeLoanEvent.new(farm.loan, farm.farmId))
        local i = 0
        for i = i, 4 do
            connection:sendEvent(FinanceStatsEvent.new(i, farm.farmId))
        end
        user:setFinancesVersionCounter(farm.stats.financesVersionCounter)
    end
    connection:sendEvent(FarmlandInitialStateEvent.new())
    connection:sendEvent(GreatDemandsEvent.new(self.economyManager.greatDemands))
    connection:sendEvent(PricingHistoryInitialEvent.new())
    self.vehicleSaleSystem:sendAllToClient(connection)
    self.collectiblesSystem:onClientJoined(connection)
    self.aiSystem:onClientJoined(connection)
    self.destructibleMapObjectSystem:onClientJoined(connection)
    self.treeMarkerSystem:onClientJoined(connection)
end
function FSBaseMission:onSplitShapesProgress(connection, percentage)
    if percentage >= 1 and self:getIsServer() then
        local syncPlayer = self.playersSynchronizing[connection]
        if syncPlayer ~= nil then
            if syncPlayer.splitShapesEvent ~= nil then
                syncPlayer.splitShapesEvent:delete()
                syncPlayer.splitShapesEvent = nil
            end
            connection:sendEvent(BaseMissionReadyEvent.new(), nil, true)
        end
    end
end
function FSBaseMission:onFinishedReceivingDynamicData(connection)
    if self.loadingScreen ~= nil then
        self.loadingScreen:onFinishedReceivingDynamicData()
        connection:sendEvent(BaseMissionReadyEvent.new(), nil, true)
    end
end
function FSBaseMission:onConnectionReady(connection)
    local syncPlayer = self.playersSynchronizing[connection]
    if syncPlayer == nil then
        g_server:closeConnection(connection)
    else
        if syncPlayer.densityMapEvent ~= nil then
            syncPlayer.densityMapEvent:delete()
            syncPlayer.densityMapEvent = nil
        end
        if syncPlayer.splitShapesEvent ~= nil then
            syncPlayer.splitShapesEvent:delete()
            syncPlayer.splitShapesEvent = nil
        end
        connection:setIsReadyForObjects(true)
        syncPlayer.user:setState(FSBaseMission.USER_STATE_CONNECTED)
        self.playersSynchronizing[connection] = nil
        if next(self.playersSynchronizing) == nil then
            self.isSynchronizingWithPlayers = false
            self:tryUnpauseGame()
            self:showPauseDisplay(self.paused)
        end
    end
end
function FSBaseMission:onConnectionClosed(connection, disconnectReason)
    if self:getIsServer() then
        removeSplitShapeConnection(connection.streamId)
        if self.densityMapSyncer ~= nil then
            self.densityMapSyncer:removeConnection(connection.streamId)
        end
        removeTerrainUpdateConnection(g_terrainNode, connection.streamId)
        local i = 1
        local text = #self.playersToAccept
        local syncPlayer = 1
        for i = i, text, syncPlayer do
            if self.playersToAccept[i].connection == connection then
                table.remove(self.playersToAccept, i)
                break
            end
        end
        self.playersLoading[connection] = nil
        local text = self.userManager:getUserByConnection(connection)
        if text ~= nil then
            g_farmManager:playerQuitGame(text:getId())
        end
        self.userManager:removeUserByConnection(connection, disconnectReason)
        voiceChatRemoveConnection(connection.streamId)
        local syncPlayer = self.playersSynchronizing[connection]
        if syncPlayer ~= nil then
            if syncPlayer.densityMapEvent ~= nil then
                syncPlayer.densityMapEvent:delete()
            end
            if syncPlayer.splitShapesEvent ~= nil then
                syncPlayer.splitShapesEvent:delete()
            end
            self.playersSynchronizing[connection] = nil
            if next(self.playersSynchronizing) == nil then
                self.isSynchronizingWithPlayers = false
                self:tryUnpauseGame()
                self:showPauseDisplay(self.paused)
            end
        end
        if self.connectionsToPlayer[connection] ~= nil then
            self.connectionsToPlayer[connection]:delete()
            self.connectionsToPlayer[connection] = nil
        end
        local i = self.userManager:getNumberOfUsers()
        self:sendNumPlayersToMasterServer(i)
        self:sendPlatformSessionIdsToMasterServer(self.userManager:getAllPlatformSessionIds())
        g_server:broadcastEvent(UserEvent.new({}, { text }, self.missionDynamicInfo.capacity, disconnectReason))
        self.slotSystem:updateSlotLimit()
        if i == 1 and g_dedicatedServer ~= nil then
            g_dedicatedServer:lowerFramerate()
            if g_dedicatedServer.pauseGameIfEmpty then
                self.dediEmptyPaused = true
                self:pauseGame()
            end
        end
    else
        if self.receivingDensityMapEvent ~= nil then
            self.receivingDensityMapEvent:delete()
            self.receivingDensityMapEvent = nil
        end
        if self.receivingSplitShapesEvent ~= nil then
            self.receivingSplitShapesEvent:delete()
            self.receivingSplitShapesEvent = nil
        end
        self:pauseGame()
        if not self.connectionWasClosed then
            self.isSynchronizingWithPlayers = false
            self.connectionWasClosed = true
            setPresenceMode(PresenceModes.PRESENCE_IDLE)
            if self.cleanServerShutDown == nil or not self.cleanServerShutDown then
                local text = g_i18n:getText("ui_failedToConnectToGame")
                if self.connectionWasAccepted then
                    if self.connectionLostState == FSBaseMission.CONNECTION_LOST_KICKED then
                        text = g_i18n:getText("ui_connectionLostKicked")
                    elseif self.connectionLostState == FSBaseMission.CONNECTION_LOST_BANNED then
                        text = g_i18n:getText("ui_connectionLostBanned")
                    else
                        text = g_i18n:getText("ui_connectionLost")
                    end
                end
                if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "ChatDialog" then
                    g_gui:showGui("")
                end
                InfoDialog.show(text, OnInGameMenuMenu)
            end
            self.cleanServerShutDown = false
            self.connectionLostState = nil
            return
        end
    end
end
function FSBaseMission:cancelPlayersSynchronizing()
    for connection, _ in pairs(self.playersSynchronizing) do
        g_server:closeConnection(connection)
    end
end
function FSBaseMission:onConnectionsUpdateTick(dt)
    if self:getIsServer() and #g_server.clients > 0 then
        prepareSplitShapesServerWriteUpdateStream(dt)
        if startWriteSplitShapesServerEvents() then
            for streamId, connection in pairs(g_server.clientConnections) do
                if streamId ~= NetworkNode.LOCAL_STREAM_ID then
                    connection:sendEvent(UpdateSplitShapesEvent.new())
                end
            end
            finishWriteSplitShapesServerEvents()
        end
    end
end
function FSBaseMission:onConnectionWriteUpdateStream(connection, maxPacketSize, networkDebug)
    if not connection:getIsServer() then
        streamWriteBool(connection.streamId, g_savegameController:getIsSaving())
        local maxTreePacketSize = maxPacketSize * 0.3
        local densityMaxPacketSize = maxPacketSize * 0.2
        local terrainDeformMaxPacketSize = maxPacketSize * 0.2
        local x, y, z = g_server:getClientPosition(connection.streamId)
        local viewCoeff = g_server:getClientClipDistCoeff(connection.streamId)
        local splitShapeStreamOffsetStart = streamGetWriteOffset(connection.streamId)
        if networkDebug then
            streamWriteInt32(connection.streamId, 0)
        end
        writeSplitShapesServerUpdateToStream(connection.streamId, connection.streamId, x, y, z, viewCoeff, maxTreePacketSize)
        local splitShapeStreamOffsetEnd = streamGetWriteOffset(connection.streamId)
        local splitShapePacketSize = splitShapeStreamOffsetEnd - splitShapeStreamOffsetStart
        local densityPacketSize = maxTreePacketSize - splitShapePacketSize
        local remainingPacketSize = math.max(densityPacketSize, 0)
        g_server:addPacketSize(connection, NetworkNode.PACKET_SPLITSHAPES, splitShapePacketSize / 8)
        if networkDebug then
            streamSetWriteOffset(connection.streamId, splitShapeStreamOffsetStart)
            streamWriteInt32(connection.streamId, splitShapeStreamOffsetEnd - (splitShapeStreamOffsetStart + 32))
            streamSetWriteOffset(connection.streamId, splitShapeStreamOffsetEnd)
        end
        if self.densityMapSyncer ~= nil then
            local densityMaxPacketSize = densityMaxPacketSize + remainingPacketSize
            local voiceChatPacketSize = densityMaxPacketSize - self.densityMapSyncer:writeUpdateStream(connection, densityMaxPacketSize, x, y, z, viewCoeff, networkDebug)
            remainingPacketSize = math.max(voiceChatPacketSize, 0)
        end
        if self.terrainDeformationSyncer ~= nil then
            local terrainDeformMaxPacketSize = terrainDeformMaxPacketSize + remainingPacketSize
            local voiceChatPacketSize = terrainDeformMaxPacketSize - self.terrainDeformationSyncer:writeUpdateStream(connection, terrainDeformMaxPacketSize, x, y, z, viewCoeff, networkDebug)
            math.max(voiceChatPacketSize, 0)
        end
        local densityPacketSize = streamGetWriteOffset(connection.streamId)
        if networkDebug then
            streamWriteInt32(connection.streamId, 0)
        end
        voiceChatWriteServerUpdateToStream(connection.streamId, connection.streamId, connection.lastSeqSent)
        local voiceChatStreamOffsetEnd = streamGetWriteOffset(connection.streamId)
        local voiceChatPacketSize = voiceChatStreamOffsetEnd - densityPacketSize
        g_server:addPacketSize(connection, NetworkNode.PACKET_VOICE_CHAT, voiceChatPacketSize / 8)
        if networkDebug then
            streamSetWriteOffset(connection.streamId, densityPacketSize)
            streamWriteInt32(connection.streamId, voiceChatStreamOffsetEnd - (densityPacketSize + 32))
            streamSetWriteOffset(connection.streamId, voiceChatStreamOffsetEnd)
        end
    end
end
function FSBaseMission:onConnectionReadUpdateStream(connection, networkDebug)
    if connection:getIsServer() then
        self.isServerSaving = streamReadBool(connection.streamId)
        local startOffset = 0
        local numBits = 0
        if networkDebug then
            startOffset = streamGetReadOffset(connection.streamId)
            numBits = streamReadInt32(connection.streamId)
        end
        readSplitShapesServerUpdateFromStream(connection.streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)
        if networkDebug then
            g_client:checkObjectUpdateDebugReadSize(connection.streamId, numBits, startOffset, "splitshape")
        end
        if self.densityMapSyncer ~= nil then
            self.densityMapSyncer:readUpdateStream(connection, networkDebug)
        end
        if self.terrainDeformationSyncer ~= nil then
            self.terrainDeformationSyncer:readUpdateStream(connection, networkDebug)
        end
        local startOffset = 0
        local numBits = 0
        if networkDebug then
            startOffset = streamGetReadOffset(connection.streamId)
            numBits = streamReadInt32(connection.streamId)
        end
        voiceChatReadServerUpdateFromStream(connection.streamId, g_clientInterpDelay, connection.lastSeqSent)
        if networkDebug then
            g_client:checkObjectUpdateDebugReadSize(connection.streamId, numBits, startOffset, "voicechat")
        end
    end
end
function FSBaseMission:onFinishedClientsWriteUpdateStream() end
function FSBaseMission.onConnectionPacketSent(_, _, packetId)
    voiceChatNotifyPacketSent(packetId)
end
function FSBaseMission:onConnectionPacketLost(connection, packetId)
    voiceChatNotifyPacketLost(packetId)
    if not connection:getIsServer() and self.densityMapSyncer ~= nil then
        self.densityMapSyncer:onPacketLost(connection, packetId)
    end
end
function FSBaseMission:onShutdownEvent(connection)
    if self:getIsServer() then
        local user = self.userManager:getUserByConnection(connection)
        self.userManager:removeUserByConnection(connection)
        voiceChatRemoveConnection(connection.streamId)
        self:sendNumPlayersToMasterServer(self.userManager:getNumberOfUsers())
        self:sendPlatformSessionIdsToMasterServer(self.userManager:getAllPlatformSessionIds())
        g_server:broadcastEvent(UserEvent.new({}, { user }, self.missionDynamicInfo.capacity))
    else
        g_gui:closeAllDialogs()
        self.cleanServerShutDown = true
        setPresenceMode(PresenceModes.PRESENCE_IDLE)
        InfoDialog.show(g_i18n:getText("ui_serverWasShutdown"), self.onShutdownEventOk, self)
    end
end
function FSBaseMission:onShutdownEventOk()
    OnInGameMenuMenu()
end
function FSBaseMission:onMasterServerConnectionReady() end
function FSBaseMission:onMasterServerConnectionFailed(reason)
    if g_dedicatedServer == nil then
        if self.isMissionStarted then
            g_gui:showGui("InGameMenu")
            g_inGameMenu:setMasterServerConnectionFailed(reason)
        else
            OnInGameMenuMenu(false, true)
        end
    else
        Logging.error("Lost connection to master server. Shutting down server...")
        doExit()
        return
    end
end
function FSBaseMission:getServerUserId()
    return 1
end
function FSBaseMission:getFarmId(connection)
    if self:getIsServer() then
        if g_localPlayer == nil or connection ~= nil then
            if connection == nil then
                return nil
            else
                local player = self:getPlayerByConnection(connection)
                if player == nil then
                    return nil
                else
                    return player.farmId
                end
            end
        else
            return g_localPlayer.farmId
        end
    else
        return g_localPlayer == nil and 0 or g_localPlayer.farmId
    end
end
function FSBaseMission.farmStats(_, farmId)
    if farmId == nil then
        farmId = g_localPlayer.farmId
    end
    local farm = g_farmManager:getFarmById(farmId)
    if farm ~= nil then
        return farm.stats
    end
    printError("Error: Farm not found for stats")
    return FarmStats.new()
end
function FSBaseMission:getPlayerByConnection(connection)
    return self.connectionsToPlayer[connection]
end
function FSBaseMission:kickUser(user)
    assert(self:getIsServer())
    local connection = user:getConnection()
    connection:sendEvent(KickBanNotificationEvent.new(true))
    g_server:closeConnection(connection, DisconnectReason.KICKED)
end
function FSBaseMission:banUser(user)
    user:block()
    if self:getIsServer() then
        local connection = user:getConnection()
        connection:sendEvent(KickBanNotificationEvent.new(false))
        g_server:closeConnection(connection, DisconnectReason.BANNED)
    end
end
function FSBaseMission:getObjectByUniqueId(uniqueId)
    local vehicle = self.vehicleSystem:getVehicleByUniqueId(uniqueId)
    if vehicle == nil then
        local placeable = self.placeableSystem:getPlaceableByUniqueId(uniqueId)
        if placeable == nil then
            local item = self.itemSystem:getItemByUniqueId(uniqueId)
            if item == nil then
                local handTool = self.handToolSystem:getHandToolByUniqueId(uniqueId)
                if handTool == nil then
                    local handToolHolder = self.handToolSystem:getHandToolHolderByUniqueId(uniqueId)
                    if handToolHolder == nil then
                        local player = self.playerSystem:getPlayerByUniqueId(uniqueId)
                        if player == nil then
                            return nil
                        else
                            return player
                        end
                    else
                        return handToolHolder
                    end
                else
                    return handTool
                end
            else
                return item
            end
        else
            return placeable
        end
    else
        return vehicle
    end
end
function FSBaseMission:onObjectCreated(object)
    FSBaseMission:superClass().onObjectCreated(self, object)
    if self.slotSystem:getIsCountableObject(object) then
        self.slotSystem:updateSlotUsage()
    end
end
function FSBaseMission:onObjectDeleted(object)
    FSBaseMission:superClass().onObjectDeleted(self, object)
    if self.slotSystem:getIsCountableObject(object) then
        self.slotSystem:updateSlotUsage()
    end
end
function FSBaseMission:addOwnedItem(item)
    FSBaseMission:superClass().addOwnedItem(self, item)
    g_shopController:setOwnedFarmItems(self.ownedItems, g_localPlayer ~= nil and g_localPlayer.farmId or AccessHandler.EVERYONE)
end
function FSBaseMission:removeOwnedItem(item)
    FSBaseMission:superClass().removeOwnedItem(self, item)
    g_shopController:setOwnedFarmItems(self.ownedItems, g_localPlayer ~= nil and g_localPlayer.farmId or AccessHandler.EVERYONE)
end
function FSBaseMission:addLeasedItem(item)
    FSBaseMission:superClass().addLeasedItem(self, item)
    g_shopController:setLeasedFarmItems(self.leasedItems, g_localPlayer ~= nil and g_localPlayer.farmId or AccessHandler.EVERYONE)
end
function FSBaseMission:removeLeasedItem(item)
    FSBaseMission:superClass().removeLeasedItem(self, item)
    g_shopController:setLeasedFarmItems(self.leasedItems, g_localPlayer ~= nil and g_localPlayer.farmId or AccessHandler.EVERYONE)
end
function FSBaseMission:loadMap(filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    local loadingFileId = -1
    if self.missionInfo.mapsSplitShapeFileIds ~= nil then
        loadingFileId = Utils.getNoNil(self.missionInfo.mapsSplitShapeFileIds[#self.mapsSplitShapeFileIds + 1], -1)
    end
    setSplitShapesLoadingFileId(loadingFileId)
    local splitShapeFileId = setSplitShapesNextFileId()
    table.insert(self.mapsSplitShapeFileIds, splitShapeFileId)
    FSBaseMission:superClass().loadMap(self, filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
end
function FSBaseMission:registerToLoadOnMapFinished(object)
    table.insert(self.objectsToCallOnMapFinished, object)
end
function FSBaseMission:loadMapFinished(node, failedReason, arguments, callAsyncCallback)
    local startedRepeat = startFrameRepeatMode()
    FSBaseMission:superClass().loadMapFinished(self, node, failedReason, arguments, false)
    local asyncCallbackFunction = arguments.asyncCallbackFunction
    if not self.missionDynamicInfo.isMultiplayer and (self.trafficSystem ~= nil and (self.trafficSystem.trafficSystemId ~= nil and (self.pedestrianSystem ~= nil and self.pedestrianSystem.pedestrianSystemId ~= nil))) then
        setPedestrianSystemTrafficSystem(self.pedestrianSystem.pedestrianSystemId, self.trafficSystem.trafficSystemId)
    end
    if g_dedicatedServer == nil then
        self.mapOverlayGenerator = MapOverlayGenerator.new(g_i18n, g_fruitTypeManager, g_fillTypeManager, g_farmlandManager, g_farmManager, self.weedSystem)
        self.mapOverlayGenerator:setColorBlindMode(Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false))
        self.mapOverlayGenerator:setFieldColor(self.mapFieldColor, self.mapGrassFieldColor)
    end
    if node ~= 0 then
        local terrainNode = 0
        local i = 0
        for i = i, getNumOfChildren(node) - 1 do
            local t = getChildAt(node, i)
            if getHasClassId(t, ClassIds.TERRAIN_TRANSFORM_GROUP) then
                terrainNode = t
                break
            end
        end
        if terrainNode ~= 0 then
            self:initTerrain(terrainNode, arguments.filename)
        end
    end
    if self.trafficSystem ~= nil and (self.trafficSystem.trafficSystemId ~= nil and (self.aiSystem ~= nil and self.aiSystem.navigationMap ~= nil)) then
        setTrafficSystemVehicleNavigationMap(self.trafficSystem.trafficSystemId, self.aiSystem.navigationMap)
        setVehicleNavigationMapTrafficSystem(self.aiSystem.navigationMap, self.trafficSystem.trafficSystemId)
    end
    if (callAsyncCallback == nil or callAsyncCallback) and asyncCallbackFunction ~= nil then
        asyncCallbackFunction(arguments.asyncCallbackObject, node, arguments.asyncCallbackArguments)
    end
    if startedRepeat then
        endFrameRepeatMode()
    end
    if not self.cancelLoading then
        if g_dedicatedServer == nil then
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) self
                g_wildlifeManager:loadMapData(self.xmlFile, self.baseDirectory)
            end)
        end
        for _, i in pairs(self.objectsToCallOnMapFinished) do
            i:onLoadMapFinished()
        end
        g_inGameMenu:setManureTriggers(self.manureLoadingStations, self.liquidManureLoadingStations)
        g_inGameMenu:setConnectedUsers(self.userManager:getUsers())
    end
    self.objectsToCallOnMapFinished = {}
end
function FSBaseMission:initTerrain(terrainNode, filename)
    local isMultiplayer = self.missionDynamicInfo.isMultiplayer
    self.terrainRootNode = terrainNode
    g_terrainNode = terrainNode
    local terrainColMask = getCollisionFilterMask(terrainNode)
    local cellSizeMeters
    if CollisionFlag.getHasGroupFlagSet(terrainNode, CollisionFlag.TERRAIN) then
        cellSizeMeters = terrainColMask
    else
        cellSizeMeters = bit32.bor(terrainColMask, CollisionFlag.TERRAIN)
        Logging.warning("Missing collision mask bit \'%d\'. Automatically added bit to terrain node \'%s\'", CollisionFlag.getBit(CollisionFlag.TERRAIN), getName(terrainNode))
    end
    if CollisionFlag.getHasGroupFlagSet(terrainNode, CollisionFlag.AI_BLOCKING) then
        local numSpheres = bit32.bnot(CollisionFlag.AI_BLOCKING)
        cellSizeMeters = bit32.band(cellSizeMeters, numSpheres)
        Logging.warning("Terrain node \'%s\' has bit \'%d\' activated. Automatically removed this bit from collision mask", getName(terrainNode), CollisionFlag.getBit(CollisionFlag.AI_BLOCKING))
    end
    if terrainColMask ~= cellSizeMeters then
        setCollisionFilterMask(terrainNode, cellSizeMeters)
    end
    self.terrainSize = getTerrainSize(terrainNode)
    g_terrainSize = self.terrainSize
    g_terrainSizeHalf = self.terrainSize * 0.5
    g_inGameMenu:setTerrainSize(self.terrainSize)
    local cellCollisionMask = CollisionFlag.STATIC_OBJECT + CollisionFlag.TREE + CollisionFlag.BUILDING + CollisionFlag.PRECIPITATION_BLOCKING + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.WATER
    createLowResCollisionHandler(Platform.lowResCollisionHandlerGridSize, Platform.lowResCollisionHandlerGridSize, 1, cellCollisionMask, Platform.lowResCollisionHandlerCellRaysPerFrame, cellCollisionMask, 5)
    addLowResCollisionHandlerLOD(2, Platform.lowResCollisionHandlerCellRaysPerFrame / 2)
    addLowResCollisionHandlerLOD(2, Platform.lowResCollisionHandlerCellRaysPerFrame / 2)
    setLowResCollisionHandlerTerrainRootNode(terrainNode)
    local x, y, z = getWorldTranslation(terrainNode)
    if math.abs(x) > 0.1 or (math.abs(z) > 0.1 or y < 0) then
        printWarning("Warning: the terrain node needs to be a x=0 and z=0 and y >= 0")
    end
    self.areaCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize, 0.5 * self.terrainSize, 0.02)
    self.areaRelativeCompressionParams = NetworkUtil.createWorldPositionCompressionParams(100, 50, 0.02)
    self.vehicleXZPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize + 500, 0.5 * (self.terrainSize + 500), 0.005)
    self.vehicleYPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.005)
    self.vehicleXZPosHighPrecisionCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize + 500, 0.5 * (self.terrainSize + 500), 0.0001)
    self.vehicleYPosHighPrecisionCompressionParams = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.0001)
    setSplitShapesWorldCompressionParams(self.terrainSize, 0.5 * self.terrainSize, 0.005, 1700, 200, 0.005, self.terrainSize, 0.5 * self.terrainSize, 0.005)
    local worldSizeHalf = 0.5 * self.terrainSize + self.cullingWorldXZOffset
    local worldMinY = self.cullingWorldMinY
    local worldMaxY = self.cullingWorldMaxY
    local clipDistanceThreshold1 = self.cullingClipDistanceThreshold1
    local clipDistanceThreshold2 = self.cullingClipDistanceThreshold2
    setAudioCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 16, clipDistanceThreshold1, clipDistanceThreshold2)
    setLightCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 16, clipDistanceThreshold1, clipDistanceThreshold2)
    setShapeCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 64, clipDistanceThreshold1, clipDistanceThreshold2)
    local foliageViewCoeff = getFoliageViewDistanceCoeff()
    local lodBlendStart, lodBlendEnd = getTerrainLodBlendDynamicDistances(terrainNode)
    setTerrainLodBlendDynamicDistances(terrainNode, lodBlendStart * foliageViewCoeff, lodBlendEnd * foliageViewCoeff)
    setGroundFogTerrainEntityId(terrainNode)
    if self.foliageBendingSystem then
        self.foliageBendingSystem:setTerrainTransformGroup(terrainNode)
    end
    local fruitTypes, generatedTipCollisionMap = getTerrainDataPlaneByName(terrainNode, "terrainDetail")
    self.terrainDetailId = fruitTypes
    if self.terrainDetailId ~= 0 then
        self.terrainDetailMapSize = getDensityMapSize(self.terrainDetailId)
    end
    self.fieldGroundSystem:initTerrain(self, terrainNode, self.terrainDetailId)
    self.stoneSystem:initTerrain(self, terrainNode, self.terrainDetailId)
    self.weedSystem:initTerrain(self, terrainNode, self.terrainDetailId)
    self.vineSystem:initTerrain(self.terrainSize, self.terrainDetailMapSize)
    self.foliageSystem:initTerrain(self, terrainNode, self.terrainDetailId)
    self.treeMarkerSystem:initTerrain()
    self.environmentAreaSystem:initTerrain(terrainNode)
    if isMultiplayer then
        self.densityMapSyncer = DensityMapSyncer.new(terrainNode, 32)
        self.terrainDeformationSyncer = TerrainDeformationSyncer.new(terrainNode, self.terrainSize)
        for _, id in pairs(self.dynamicFoliageLayers) do
            self.densityMapSyncer:addDensityMap(id)
        end
        self.fieldGroundSystem:addDensityMapSyncer(self.densityMapSyncer)
        self.stoneSystem:addDensityMapSyncer(self.densityMapSyncer)
        self.weedSystem:addDensityMapSyncer(self.densityMapSyncer)
        self.foliageSystem:addDensityMapSyncer(self.densityMapSyncer)
    end
    local fruitTypes = {}
    for id, fruitTypeDesc in ipairs(g_fruitTypeManager:getFruitTypes()) do
        local isValid = false
        local layerName = fruitTypeDesc:getLayerName()
        local foliageTransfromGroupId = getFoliageTransformGroupIdByFoliageName(terrainNode, layerName)
        local terrainDataPlaneId, terrainDataPlaneIndex = getTerrainDataPlaneByName(terrainNode, layerName)
        if terrainDataPlaneId ~= 0 then
            isValid = true
            fruitTypeDesc:setTerrainDataPlane(terrainDataPlaneId)
            fruitTypeDesc:setTerrainDataPlaneIndex(terrainDataPlaneIndex)
            fruitTypeDesc:setFoliageTransformGroup(foliageTransfromGroupId)
            g_fruitTypeManager:addTerrainDataPlane(terrainDataPlaneId)
            g_fruitTypeManager:setTerrainDataPlaneIndex(fruitTypeDesc, terrainDataPlaneIndex)
            local terrainDataPlaneIdHaulm = self.fruitMapSize
            self.fruitMapSize = math.max(terrainDataPlaneIdHaulm, getDensityMapSize(terrainDataPlaneId))
            if self:getIsServer() then
                local mapName = getDensityMapFilename(terrainDataPlaneId)
                local terrainDataPlaneIdHaulm = Utils.getFilenameInfo(mapName)
                self.growthSystem:setFruitLayer(terrainDataPlaneIdHaulm, fruitTypeDesc, layerName, terrainDataPlaneId)
            end
            if isMultiplayer then
                self.densityMapSyncer:addDensityMap(terrainDataPlaneId)
            end
        end
        local mapName = fruitTypeDesc:getHaulmLayerName()
        if mapName ~= nil then
            local terrainDataPlaneIdHaulm, terrainDataPlaneIndexHaulm = getTerrainDataPlaneByName(terrainNode, mapName)
            if terrainDataPlaneIdHaulm ~= 0 then
                isValid = true
                g_fruitTypeManager:addTerrainDataPlane(terrainDataPlaneIdHaulm)
                g_fruitTypeManager:addHaulmFruitType(fruitTypeDesc)
                fruitTypeDesc:setTerrainDataPlaneHaulm(terrainDataPlaneIdHaulm)
                fruitTypeDesc:setTerrainDataPlaneHaulmIndex(terrainDataPlaneIndexHaulm)
                if isMultiplayer then
                    self.densityMapSyncer:addDensityMap(terrainDataPlaneIdHaulm)
                end
            end
        end
        if isValid then
            table.insert(fruitTypes, fruitTypeDesc)
        end
    end
    if self.mapOverlayGenerator ~= nil then
        self.mapOverlayGenerator:setMissionFruitTypes(fruitTypes)
    end
    self.growthSystem:onTerrainLoad(terrainNode)
    if self.terrainDetailId ~= 0 then
        self.fieldCropsQuery = FieldCropsQuery.new(self.terrainDetailId)
    end
    self.terrainDetailHeightId = getTerrainDataPlaneByName(terrainNode, "terrainDetailHeight")
    self.terrainDetailHeightTGId = getTerrainDetailByName(terrainNode, "terrainDetailHeight")
    self.terrainDetailHeightMapSize = self.fruitMapSize
    if self.terrainDetailHeightId ~= 0 then
        self.terrainDetailHeightMapSize = getDensityMapSize(self.terrainDetailHeightId)
        g_densityMapHeightManager:loadFromXMLFile(self.missionInfo.densityMapHeightXMLLoad)
        local generatedTipCollisionMap = getInfoLayerFromTerrain(terrainNode, "tipCollisionGenerated")
        local generatedPlacementCollisionMap = getInfoLayerFromTerrain(terrainNode, "placementCollisionGenerated")
        g_densityMapHeightManager:initialize(self:getIsServer(), generatedTipCollisionMap, generatedPlacementCollisionMap)
        if g_densityMapHeightManager:getTerrainDetailHeightUpdater() ~= nil and isMultiplayer then
            self.densityMapSyncer:addDensityMap(self.terrainDetailHeightId, true)
        end
    end
    if isMultiplayer then
        self.densityMapSyncer:onDensityMapsAdded()
    end
    self.indoorMask:onTerrainLoad(terrainNode)
    self.snowSystem:onTerrainLoad(terrainNode)
    self.aiSystem:onTerrainLoad(terrainNode, filename)
    if self.shallowWaterSimulation ~= nil then
        self.shallowWaterSimulation:onTerrainLoad(terrainNode)
    end
    g_groundTypeManager:initTerrain(terrainNode)
    DensityMapHeightUtil.initTerrain(self, self.terrainDetailId, self.terrainDetailHeightId)
    g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.TERRAIN)
end
function FSBaseMission:addTrainSystem(trainSystem)
    self.trainSystems[trainSystem] = trainSystem
end
function FSBaseMission:removeTrainSystem(trainSystem)
    self.trainSystems[trainSystem] = nil
end
function FSBaseMission:setTrainSystemTabbable(isTabbable)
    for trainSystem, _ in pairs(self.trainSystems) do
        trainSystem:setIsTrainTabbable(isTabbable)
    end
end
function FSBaseMission:mouseEvent(posX, posY, isDown, isUp, button)
    FSBaseMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
    self.hud:mouseEvent(posX, posY, isDown, isUp, button)
end
function FSBaseMission:updatePauseInputContext()
    local inputBinding = g_inputBinding
    local hasPauseContext = true
    if inputBinding:getContextName() ~= BaseMission.INPUT_CONTEXT_PAUSE then
        hasPauseContext = inputBinding:getContextName() == BaseMission.INPUT_CONTEXT_SYNCHRONIZING
    end
    local needPause = self.gameStarted and self.paused
    if needPause then
        needPause = not g_gui:getIsGuiVisible() or self.isSynchronizingWithPlayers
    end
    local needUnpause = self.gameStarted
    if needUnpause then
        needUnpause = not self.paused
    end
    if not self.isSynchronizingWithPlayers and inputBinding:getContextName() == BaseMission.INPUT_CONTEXT_SYNCHRONIZING then
        inputBinding:revertContext()
    end
    if needPause and not hasPauseContext then
        inputBinding:setContext(BaseMission.INPUT_CONTEXT_PAUSE)
    elseif needUnpause and hasPauseContext then
        inputBinding:revertContext()
    end
    if needPause and (self.isSynchronizingWithPlayers and inputBinding:getContextName() ~= BaseMission.INPUT_CONTEXT_SYNCHRONIZING) then
        inputBinding:setContext(BaseMission.INPUT_CONTEXT_SYNCHRONIZING, true)
    end
end
function FSBaseMission:update(dt)
    -- upvalues: (ref) l_engineState, (ref) l_engineStateTimer, (copy) onEngineStateCallback
    FSBaseMission:superClass().update(self, dt)
    if not l_engineState and (self.isRunning and Utils.getNoNil(g_farmManager:getFarmById(g_localPlayer.farmId).stats:getTotalValue("playTime"), 0) / 60 > 4) then
        l_engineStateTimer = l_engineStateTimer - dt
        if l_engineStateTimer < 0 and not g_gui:getIsGuiVisible() then
            InfoDialog.show(g_i18n:getText("dialog_getFullVersion"), onEngineStateCallback)
            l_engineStateTimer = math.random(1200000, 1800000)
        end
    end
    if self.debugPhysicsStressTest then
        self.debugPhysicsStressTestSpawn()
        self.debugPhysicsStressTestRemove(dt)
    end
    self.hud:updateMessage(dt)
    self.hud:setIsSaving(self.isServerSaving or g_savegameController:getIsSaving())
    self.hud:updateMap(dt)
    self.introductionHelpSystem:update(dt)
    self.aiSystem:update(dt)
    self.environmentAreaSystem:update(dt)
    self.reverbSystem:update(dt)
    self.ambientSoundSystem:update(dt)
    self.vineSystem:update(dt)
    self.userManager:update(dt)
    self.snowSystem:update(dt)
    if self.economyManager ~= nil then
        self.economyManager:update(dt)
    end
    g_densityMapHeightManager:update(dt)
    if g_dedicatedServer == nil then
        g_wildlifeManager:update(dt)
    end
    self:updatePauseInputContext()
    if self.isRunning or g_dedicatedServer ~= nil then
        if #self.playersToAccept > 0 then
            if self.missionDynamicInfo.autoAccept then
                self:onConnectionDenyAccept(self.playersToAccept[1].connection, false, false)
            elseif self:getCanAcceptPlayers() then
                local playTimeH = self.playersToAccept[1]
                DenyAcceptDialog.show(self.onConnectionDenyAccept, self, playTimeH.connection, playTimeH.playerName, playTimeH.platformId, getIsSplitShapeConnectionWithinLimits(playTimeH.platformId))
            end
        end
        if self.pendingSavegameDateAchievement then
            local playTimeH = self.missionInfo.saveDate
            if playTimeH ~= nil then
                local todayStr = getDate("%Y-%m-%d")
                local yearLastSave, monthLastSave = string.match(playTimeH, "(%d%d%d%d)-(%d%d)")
                local yearToday, monthToday = string.match(todayStr, "(%d%d%d%d)-(%d%d)")
                local datesValid = tonumber(yearLastSave)
                local datesValid = tonumber(monthLastSave)
                local datesValid = tonumber(yearToday)
                local datesValid = tonumber(monthToday)
                local datesValid = false
                if datesValid ~= nil then
                    datesValid = false
                    if datesValid ~= nil then
                        datesValid = false
                        if datesValid ~= nil then
                        end
                    end
                end
                if datesValid then
                    local numMonthsDif = (datesValid - datesValid) * 12 + (datesValid - datesValid)
                    if numMonthsDif > 0 then
                        g_achievementManager:tryUnlock("LoadedOldSavegame", numMonthsDif)
                    end
                end
            end
            self.pendingSavegameDateAchievement = nil
        end
        g_effectManager:update(dt)
        g_animationManager:update(dt)
        g_guidedTourManager:update(dt)
        self.growthSystem:update(dt)
        g_npcManager:update(dt)
        if self.mapOverlayGenerator ~= nil then
            self.mapOverlayGenerator:update(dt)
        end
        if self:getIsServer() then
            for monthLastSave, yearToday in ipairs(self.userManager:getUsers()) do
                if monthLastSave > 1 then
                    local monthToday = g_farmManager:getFarmByUserId(yearToday:getId())
                    if yearToday:getState() == FSBaseMission.USER_STATE_INGAME and yearToday:getFinanceUpdateSendTime() < self.time then
                        yearToday:setFinanceUpdateSendTime(self.time + math.floor(math.random() * 300 + 5000))
                        if monthToday.stats.financesVersionCounter ~= yearToday:getFinancesVersionCounter() then
                            yearToday:setFinancesVersionCounter(monthToday.stats.financesVersionCounter)
                            yearToday:getConnection():sendEvent(FinanceStatsEvent.new(0, monthToday.farmId))
                        end
                    end
                end
            end
            g_treePlantManager:updateTrees(dt, dt * self:getEffectiveTimeScale())
        end
        if g_dedicatedServer ~= nil then
            g_dedicatedServer:update(dt)
        end
        if self:getIsClient() then
            if not g_gui:getIsGuiVisible() then
                if g_soundPlayer ~= nil then
                    local playTimeH = g_localPlayer:getCurrentVehicle()
                    local todayStr = playTimeH ~= nil and playTimeH.supportsRadio or not g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY)
                    g_inputBinding:setActionEventActive(g_localPlayer.inputComponent.radioActionId, todayStr)
                end
                self.hud:updateVehicleName(dt)
            end
            self:updateSaving()
            self:checkRecordingDeviceState(dt)
        end
        local playTimeH
        if self.missionDynamicInfo.isMultiplayer then
            if self:getIsServer() then
                local todayStr = 0
                local yearLastSave = false
                for datesValid, numMonthsDif in ipairs(self.userManager:getUsers()) do
                    local connection = numMonthsDif:getConnection()
                    if numMonthsDif:getState() == FSBaseMission.USER_STATE_INGAME and (connection ~= nil and self.connectionsToPlayer[connection] ~= nil) then
                        if numMonthsDif:getId() ~= self.playerUserId and not getPlatformIdsAreCompatible(numMonthsDif:getPlatformId(), getPlatformId()) then
                            yearLastSave = true
                        end
                    end
                end
                if todayStr > 1 then
                    if yearLastSave then
                        playTimeH = PresenceModes.PRESENCE_MULTIPLAYER_CROSSPLAY
                    else
                        playTimeH = PresenceModes.PRESENCE_MULTIPLAYER
                    end
                else
                    playTimeH = PresenceModes.PRESENCE_MULTIPLAYER_ALONE
                end
            else
                local todayStr = false
                for monthToday, datesValid in ipairs(self.userManager:getUsers()) do
                    if datesValid:getId() ~= self.playerUserId and not getPlatformIdsAreCompatible(datesValid:getPlatformId(), getPlatformId()) then
                        todayStr = true
                    end
                end
                if todayStr then
                    playTimeH = PresenceModes.PRESENCE_MULTIPLAYER_CROSSPLAY
                else
                    playTimeH = PresenceModes.PRESENCE_MULTIPLAYER
                end
            end
        else
            playTimeH = PresenceModes.PRESENCE_CAREER
        end
        if self.wasNetworkError and GS_PLATFORM_PLAYSTATION then
            playTimeH = PresenceModes.PRESENCE_IDLE
        end
        if self.presenceMode ~= playTimeH then
            if self.presenceMode == PresenceModes.PRESENCE_MULTIPLAYER or self.presenceMode == PresenceModes.PRESENCE_MULTIPLAYER_CROSSPLAY then
                setPresenceMode(playTimeH)
                self.presenceMode = playTimeH
            elseif not g_gui:getIsGuiVisible() or self:getIsServer() then
                setPresenceMode(playTimeH)
                self.presenceMode = playTimeH
            end
        end
        if GS_PLATFORM_PLAYSTATION and self.missionDynamicInfo.isMultiplayer then
            local todayStr = getNetworkError()
            if todayStr and not self.wasNetworkError then
                local yearLastSave = string.gsub(todayStr, "Network", "dialog_network")
                self.wasNetworkError = true
                ConnectionFailedDialog.show(g_i18n:getText(yearLastSave), g_connectionFailedDialog.onOkCallback, g_connectionFailedDialog, { g_gui.currentGuiName })
            elseif not todayStr and self.wasNetworkError then
                self.wasNetworkError = false
            end
            if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
                OnInGameMenuMenu()
            end
        end
        if self.isExitingGame then
            OnInGameMenuMenu()
        end
        if Platform.supportsGameRating then
            self:testForGameRating()
        end
    else
        if self.paused and (not self.isSynchronizingWithPlayers and (not g_gui:getIsGuiVisible() and GS_PLATFORM_PLAYSTATION)) then
            setPresenceMode(PresenceModes.PRESENCE_IDLE)
            self.presenceMode = PresenceModes.PRESENCE_IDLE
        end
        self:updateSaving()
    end
end
function FSBaseMission:postUpdate(dt)
    self.hud:postUpdateMap(dt)
end
function FSBaseMission:checkRecordingDeviceState(dt)
    if self.missionDynamicInfo.isMultiplayer and Platform.hasRecordingDeviceDetection then
        self.checkRecordingDeviceTimer = self.checkRecordingDeviceTimer + dt
        if self.checkRecordingDeviceTimer >= FSBaseMission.RECORDING_DEVICE_CHECK_INTERVAL then
            self.checkRecordingDeviceTimer = 0
            local hasDevice = VoiceChatUtil.getHasRecordingDevice()
            if hasDevice ~= self.lastRecordingDeviceState then
                self.lastRecordingDeviceState = hasDevice
                if hasDevice then
                    self:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ui_microphoneDetected"))
                    return
                end
                self:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ui_microphoneRemoved"))
            end
        end
    end
end
function FSBaseMission:testForGameRating()
    if g_gui:getIsGuiVisible() then
        return
    elseif not self.introductionHelpSystem:getIsHelpVisible() then
        local lifetimeStats = g_lifetimeStats
        local totalPlayTime = lifetimeStats:getTotalRuntime()
        local amountGameRateDialogShown = lifetimeStats.gameRateMessagesShown
        local show = false
        if amountGameRateDialogShown < 4 then
            show = amountGameRateDialogShown * 3 + 1 <= totalPlayTime
        end
        if show then
            lifetimeStats.gameRateMessagesShown = amountGameRateDialogShown + 1
            lifetimeStats:save()
            GameRateDialog.show()
        end
    end
end
function FSBaseMission:updateSaving()
    if self.doSaveGameState == SavegameController.SAVE_STATE_NONE then
        return
    else
        local inGameMenu = g_inGameMenu
        if self.doSaveGameState == SavegameController.SAVE_STATE_VALIDATE_LIST then
            if g_savegameController:isStorageDeviceUnavailable() then
                self.doSaveGameState = SavegameController.SAVE_STATE_VALIDATE_LIST_DIALOG_WAIT
                if g_dedicatedServer == nil then
                    InfoDialog.show(g_i18n:getText("ui_savegameSaveNoSpace"))
                else
                    Logging.error("The device has no space to save the game.")
                end
            else
                self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG
                return
            end
        elseif self.doSaveGameState == SavegameController.SAVE_STATE_OVERWRITE_DIALOG then
            local metadata, _ = saveGetInfoById(self.missionInfo.savegameIndex)
            if metadata == "" then
                self.doSaveGameState = SavegameController.SAVE_STATE_NOP_WRITE
                return
            else
                self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG_WAIT
                if g_dedicatedServer == nil then
                    inGameMenu:notifyOverwriteSavegame(self.onYesNoSavegameOverwrite, self)
                else
                    self:onYesNoSavegameOverwrite(true)
                end
            end
        elseif self.doSaveGameState == SavegameController.SAVE_STATE_NOP_WRITE then
            self.doSaveGameState = SavegameController.SAVE_STATE_WRITE
            return
        elseif self.doSaveGameState == SavegameController.SAVE_STATE_WRITE then
            if g_dedicatedServer == nil then
                inGameMenu:notifyStartSaving()
            end
            self.doSaveGameState = SavegameController.SAVE_STATE_WRITE_WAIT
            self.savingMinEndTime = getTimeSec() + SavegameController.SAVING_DURATION
            self:saveSavegame(self.doSaveGameBlocking)
        elseif self.doSaveGameState == SavegameController.SAVE_STATE_WRITE_WAIT and not g_savegameController:getIsSaving() then
            local metadata = g_savegameController:getSavingErrorCode()
            if metadata == Savegame.ERROR_OK then
                self.doSaveGameState = SavegameController.SAVE_STATE_NONE
                if g_dedicatedServer == nil then
                    inGameMenu:notifySaveComplete()
                end
            else
                self.doSaveGameState = SavegameController.SAVE_STATE_NONE
                self.savingMinEndTime = 0
                if metadata == Savegame.ERROR_SAVE_NO_SPACE and not GS_PLATFORM_PLAYSTATION then
                    self.currentDeviceHasNoSpace = true
                    if g_dedicatedServer == nil then
                        InfoDialog.show(g_i18n:getText("ui_savegameSaveNoSpace"), function()
                            -- upvalues: (copy) inGameMenu
                            inGameMenu:notifySavegameNotSaved()
                        end)
                        return
                    end
                else
                    g_savegameController:resetStorageDeviceSelection()
                    if g_dedicatedServer == nil then
                        inGameMenu:notifySavegameNotSaved()
                        return
                    end
                end
            end
        end
    end
end
function FSBaseMission:onSaveGameUpdateComplete(errorCode)
    if self.doSaveGameState == SavegameController.SAVE_STATE_VALIDATE_LIST_WAIT then
        if errorCode == Savegame.ERROR_OK or errorCode == Savegame.ERROR_DATA_CORRUPT then
            self.currentDeviceHasNoSpace = false
            self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG
            return
        end
        self.doSaveGameState = SavegameController.SAVE_STATE_NONE
        g_savegameController:resetStorageDeviceSelection()
        g_inGameMenu:notifySavegameNotSaved(errorCode)
    end
end
function FSBaseMission:onYesNoSavegameOverwrite(yes)
    if yes then
        self.doSaveGameState = InGameMenu.SAVE_STATE_NOP_WRITE
    else
        self.doSaveGameState = InGameMenu.SAVE_STATE_NONE
        self.savingMinEndTime = 0
        g_inGameMenu:notifySavegameNotSaved()
    end
end
function FSBaseMission:getSynchronizingPercentage()
    local percentage = 0
    local numSyncPlayers = 0
    for _, syncPlayer in pairs(self.playersSynchronizing) do
        percentage = percentage + self.restPercentageFraction
        if syncPlayer.densityMapEvent ~= nil then
        end
        if syncPlayer.splitShapesEvent ~= nil then
        end
    end
    if numSyncPlayers > 0 then
    end
    return math.floor(percentage * 100)
end
function FSBaseMission:showPauseDisplay(enableDisplay)
    local pauseText = ""
    if enableDisplay then
        pauseText = g_i18n:getText("ui_gamePaused")
        if GS_IS_CONSOLE_VERSION and self:getIsServer() then
            pauseText = pauseText .. " " .. g_i18n:getText("ui_continueGame")
        end
    end
    if self.hud ~= nil then
        self.hud:onPauseGameChange(enableDisplay, pauseText)
    end
end
function FSBaseMission:draw()
    if self.paused then
        if self.isSynchronizingWithPlayers then
            local percentageStr = ""
            if self:getIsServer() then
                percentageStr = string.format(" %i%%", self:getSynchronizingPercentage())
            end
            local pauseText = g_i18n:getText("ui_synchronizingWithOtherPlayers") .. percentageStr
            self.hud:onPauseGameChange(nil, pauseText)
        end
        local percentageStr = g_gui:getIsGuiVisible()
        if percentageStr then
            percentageStr = not g_gui:getIsOverlayGuiVisible()
        end
        if not percentageStr or self.isSynchronizingWithPlayers then
            self.hud:drawGamePaused(not self.isMissionStarted and not percentageStr)
        end
    end
    if not self.paused and self.introductionHelpSystem ~= nil then
        self.introductionHelpSystem:draw()
    end
    local percentageStr = not g_gui:getIsMenuVisible()
    if percentageStr and (g_gui:getIsDialogVisible() and not Platform.ui.drawHudOnDialog) then
        percentageStr = false
    end
    if self.isRunning and (percentageStr or g_gui:getIsOverlayGuiVisible()) and not self.hud:getIsFading() then
        if self.hud:getIsVisible() then
            self.hud:drawBaseHUD()
            self.hud:drawVehicleName()
        end
        g_guidedTourManager:draw()
    end
    FSBaseMission:superClass().draw(self)
    if not self.hud:getIsFading() then
        self.hud:drawInGameMessageAndIcon()
    end
end
function FSBaseMission:addMoneyChange(amount, farmId, moneyType, forceShow)
    if self:getIsServer() then
        if self.moneyChanges[moneyType.id] == nil then
            self.moneyChanges[moneyType.id] = {}
        end
        local changes = self.moneyChanges[moneyType.id]
        if changes[farmId] == nil then
            changes[farmId] = 0
        end
        changes[farmId] = changes[farmId] + amount
        if self:getFarmId() == farmId then
            self.hud:addMoneyChange(moneyType, amount)
        end
        if forceShow then
            self:broadcastNotifications(moneyType, farmId)
            return
        end
    else
        Logging.error("addMoneyChange() called on client")
        printCallstack()
    end
end
function FSBaseMission:showMoneyChange(moneyType, text, allFarms, farmId)
    if self:getIsServer() then
        if allFarms then
            for _, farm in ipairs(g_farmManager:getFarms()) do
                self:broadcastNotifications(moneyType, farm.farmId, text)
            end
        else
            self:broadcastNotifications(moneyType, farmId or self:getFarmId(), text)
        end
    else
        g_client:getServerConnection():sendEvent(RequestMoneyChangeEvent.new(moneyType))
        return
    end
end
function FSBaseMission:broadcastNotifications(moneyType, farmId, text)
    if moneyType == nil then
        printCallstack()
    end
    local farms = self.moneyChanges[moneyType.id]
    local amount = farms and farms[farmId]
    if amount then
        self:broadcastEventToFarm(MoneyChangeEvent.new(amount, moneyType, farmId, text), farmId, false)
        if farmId == self:getFarmId() then
            if text ~= nil then
                text = g_i18n:getText(text)
            end
            self.hud:showMoneyChange(moneyType, text)
        end
        farms[farmId] = nil
    end
end
function FSBaseMission:setMapTargetHotspot(mapHotspot)
    FSBaseMission:superClass().setMapTargetHotspot(self, mapHotspot)
    if self.navigationSystem ~= nil then
        self.navigationSystem:stop()
        if mapHotspot ~= nil then
            local x, z = mapHotspot:getWorldPosition()
            local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.25
            self.navigationSystem:navigateTo(x, y, z)
        end
    end
end
function FSBaseMission:showAttachContext(attachableVehicle)
    self.hud:showAttachContext(attachableVehicle:getUppercaseName())
end
function FSBaseMission:showTipContext(fillTypeIndex)
    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    self.hud:showTipContext(fillType.title)
end
function FSBaseMission:showFuelContext(fuelingVehicle)
    self.hud:showFuelContext(fuelingVehicle:getUppercaseName())
end
function FSBaseMission:showFillDogBowlContext(dogName)
    self.hud:showFillDogBowlContext(dogName)
end
function FSBaseMission:addIngameNotification(notificationType, text)
    self.hud:addSideNotification(notificationType, text)
end
function FSBaseMission:getIsAutoSaveSupported()
    return true
end
function FSBaseMission:doPauseGame()
    FSBaseMission:superClass().doPauseGame(self)
    g_inGameMenu:setIsGamePaused(true)
    g_shopMenu:setIsGamePaused(true)
    if self.growthSystem ~= nil then
        self.growthSystem:setIsGamePaused(true)
    end
end
function FSBaseMission:canUnpauseGame()
    return FSBaseMission:superClass().canUnpauseGame(self) and not (self.isSynchronizingWithPlayers or self.dediEmptyPaused) and not self.userSigninPaused
end
function FSBaseMission:doUnpauseGame()
    FSBaseMission:superClass().doUnpauseGame(self)
    g_inGameMenu:setIsGamePaused(false)
    g_shopMenu:setIsGamePaused(false)
    self.growthSystem:setIsGamePaused(false)
    if g_dedicatedServer ~= nil then
        g_dedicatedServer:raiseFramerate()
    end
end
function FSBaseMission:getCanAcceptPlayers()
    return not (g_gui:getIsDialogVisible() or g_sleepManager:getIsSleeping()) and not g_savegameController:getIsSaving()
end
function FSBaseMission:onEndMissionCallback()
    if self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED then
        self.isExitingGame = true
    end
end
function FSBaseMission:setMissionInfo(missionInfo, missionDynamicInfo)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self
        resetSplitShapes()
        Logging.info("resetSplitShapes()")
        setUseKinematicSplitShapes(not self:getIsServer())
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) missionInfo, (copy) self
        if missionInfo.isValid then
            local flags = TerrainLoadFlags.TEXTURE_CACHE + TerrainLoadFlags.NORMAL_MAP_CACHE + TerrainLoadFlags.OCCLUDER_CACHE
            if missionInfo:getIsDensityMapValid(self) then
            else
                Logging.warning("density map is not valid, ignoring density map from savegame")
            end
            if not GS_IS_MOBILE_VERSION then
                flags = flags + TerrainLoadFlags.HEIGHT_MAP_USE_LOAD_DIR + TerrainLoadFlags.NORMAL_MAP_CACHE_USE_LOAD_DIR + TerrainLoadFlags.OCCLUDER_CACHE_USE_LOAD_DIR
                if missionInfo:getIsTerrainLodTextureValid(self) then
                    flags = flags + TerrainLoadFlags.TEXTURE_CACHE_USE_LOAD_DIR
                    if missionInfo:getIsTerrainLodTextureValid(self) and (g_densityMapHeightManager ~= nil and g_densityMapHeightManager:checkTypeMappings()) then
                    end
                end
            end
            setTerrainLoadDirectory(missionInfo.savegameDirectory, flags)
        else
            setTerrainLoadDirectory("", TerrainLoadFlags.GAME_DEFAULT)
        end
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) missionInfo, (copy) self
        if missionInfo:getAreSplitShapesValid(self) then
            local splitShapesFilePath = missionInfo.savegameDirectory .. "/splitShapes.gmss"
            if fileExists(splitShapesFilePath) and not loadSplitShapesFromFile(splitShapesFilePath) then
                Logging.error("Unable to load split shapes from \'%s\'", splitShapesFilePath)
                return
            end
        elseif missionInfo.isValid then
            Logging.warning("splitshapes are not valid, ignoring splitshapes from savegame")
        end
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self, (copy) missionInfo, (copy) missionDynamicInfo
        FSBaseMission:superClass().setMissionInfo(self, missionInfo, missionDynamicInfo)
    end)
    g_asyncTaskManager:addTask(function()
        -- upvalues: (copy) self
        if g_soundPlayer ~= nil then
            g_soundPlayer:addEventListener(self)
            if not (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) then
                g_soundPlayer:setStreamingAccessOwner(self)
            end
        end
        self:updateMaxNumHirables()
        self.hud:setIngameMapSize(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_STATE))
    end)
end
function FSBaseMission:updateMaxNumHirables()
    if self.missionDynamicInfo.isMultiplayer then
        if self.missionDynamicInfo.capacity ~= nil then
            self.maxNumHirables = math.max(4, (math.min(self.missionDynamicInfo.capacity, g_helperManager:getNumOfHelpers())))
            return
        end
    else
        self.maxNumHirables = math.min(Platform.gameplay.maxNumHirables, g_helperManager:getNumOfHelpers())
    end
end
function FSBaseMission:addLiquidManureLoadingStation(loadingStation)
    if not table.addElement(self.liquidManureLoadingStations, loadingStation) then
        printError("Error: Liquid manure loading station already added")
    end
end
function FSBaseMission:removeLiquidManureLoadingStation(loadingStation)
    table.removeElement(self.liquidManureLoadingStations, loadingStation)
end
function FSBaseMission:addManureLoadingStation(loadingStation)
    if not table.addElement(self.manureLoadingStations, loadingStation) then
        printError("Error: Manure loading station already added")
    end
end
function FSBaseMission:removeManureLoadingStation(loadingStation)
    table.removeElement(self.manureLoadingStations, loadingStation)
end
function FSBaseMission:addMoney(amount, farmId, moneyType, addChange, forceShowChange)
    if self:getIsServer() then
        if farmId == 0 then
            printError("Error: Can\'t change money of spectator farm")
            printCallstack()
            return
        end
        local farm = g_farmManager:getFarmById(farmId)
        if farm == nil then
            return
        end
        farm:changeBalance(amount, moneyType)
        if addChange then
            self:addMoneyChange(amount, farmId, moneyType, forceShowChange)
            return
        end
    else
        printError("Error: FSBaseMission:addMoney is only allowed on a server")
        printCallstack()
    end
end
function FSBaseMission:addPurchasedMoney(amount)
    if self:getIsServer() then
        local farm = g_farmManager:getFarmById(FarmManager.SINGLEPLAYER_FARM_ID)
        if farm ~= nil then
            farm:addPurchasedCoins(amount)
        end
    else
        printError("Error: FSBaseMission:addPurchasedMoney is only allowed on a server")
        printCallstack()
        return
    end
end
function FSBaseMission:getMoney(farmId)
    if farmId == nil then
        farmId = g_localPlayer == nil and FarmManager.SINGLEPLAYER_FARM_ID or g_localPlayer.farmId
    end
    local farm = g_farmManager:getFarmById(farmId)
    if farm == nil then
        return 0
    end
    self.cacheFarm = farm
    return farm.money
end
function FSBaseMission:setPlayerPermission(userId, permission, allow)
    if self:getIsServer() then
        local farm = g_farmManager:getFarmByUserId(userId)
        if farm == nil then
            return
        end
        farm.userIdToPlayer[userId].permissions[permission] = allow
    end
end
function FSBaseMission:setPlayerPermissions(userId, permissions)
    if self:getIsServer() then
        local farm = g_farmManager:getFarmByUserId(userId)
        if farm == nil then
            return
        end
        for _, permission in ipairs(Farm.PERMISSIONS) do
            if permissions[permission] ~= nil then
                farm.userIdToPlayer[userId].permissions[permission] = permissions[permission]
            end
        end
    end
end
function FSBaseMission:getHasPlayerPermission(permission, connection, farmId, checkClient)
    if checkClient == nil or not checkClient then
        if self:getIsServer() then
            if connection == nil or (connection:getIsLocal() or (connection:getIsServer() or self.userManager:getIsConnectionMasterUser(connection))) then
                return true
            end
        elseif self.isMasterUser then
            return true
        end
        if connection ~= nil and connection:getIsServer() then
            return true
        end
    end
    local farm
    if connection == nil then
        farm = self.userManager:getUserByUserId(self.playerUserId)
    else
        farm = self.userManager:getUserByConnection(connection)
    end
    if farm == nil then
        return false
    else
        local farm = g_farmManager:getFarmByUserId(farm:getId())
        if farm == nil then
            return false
        else
            local player = farm.userIdToPlayer[farm:getId()]
            if farmId == nil or farm.farmId == farmId then
                if player == nil then
                    return false
                else
                    return player.isFarmManager or Utils.getNoNil(player.permissions[permission], false)
                end
            else
                return false
            end
        end
    end
end
function FSBaseMission:getTerrainDetailPixelsToSqm()
    local f = self.terrainSize / self.terrainDetailMapSize
    return f * f
end
function FSBaseMission:getFruitPixelsToSqm()
    local f = self.terrainSize / self.fruitMapSize
    return f * f
end
function FSBaseMission:getIngameMap()
    return self.hud:getIngameMap()
end
function FSBaseMission:sendNumPlayersToMasterServer(numPlayers)
    if self.missionDynamicInfo.isMultiplayer then
        if g_dedicatedServer ~= nil then
        end
        masterServerSetServerNumPlayers(numPlayers)
    end
end
function FSBaseMission:sendPlatformSessionIdsToMasterServer(platformSessionIds)
    if self.missionDynamicInfo.isMultiplayer then
        masterServerSetServerPlatformSessionIds(platformSessionIds)
    end
end
function FSBaseMission:setTimeScale(timeScale, noEventSend)
    if timeScale ~= self.missionInfo.timeScale then
        self.missionInfo.timeScale = timeScale
        g_messageCenter:publish(MessageType.TIMESCALE_CHANGED)
        SavegameSettingsEvent.sendEvent(noEventSend)
        if g_server ~= nil then
            EnvironmentTimeEvent.broadcastEvent()
        end
    end
end
function FSBaseMission:setTimeScaleMultiplier(timeScaleMultiplier)
    if timeScaleMultiplier ~= self.missionInfo.timeScaleMultiplier then
        self.missionInfo.timeScaleMultiplier = timeScaleMultiplier
        g_messageCenter:publish(MessageType.TIMESCALE_CHANGED)
    end
end
function FSBaseMission:getEffectiveTimeScale()
    return self.missionInfo:getEffectiveTimeScale()
end
function FSBaseMission:setEconomicDifficulty(economicDifficulty, noEventSend)
    if economicDifficulty ~= self.missionInfo.economicDifficulty then
        self.missionInfo.economicDifficulty = economicDifficulty
        SavegameSettingsEvent.sendEvent(noEventSend)
        Logging.info("Savegame Setting \'economicDifficulty\': %s", EconomicDifficulty.getName(economicDifficulty))
    end
end
function FSBaseMission:setSnowEnabled(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.isSnowEnabled then
        self.missionInfo.isSnowEnabled = isEnabled
        SavegameSettingsEvent.sendEvent(noEventSend)
        if not isEnabled then
            self.snowSystem:removeAll(true)
        end
        Logging.info("Savegame Setting \'snowEnabled\': %s", isEnabled)
    end
end
function FSBaseMission:setSavegameName(name, noEventSend)
    if name ~= self.missionInfo.savegameName then
        self.missionInfo.savegameName = name
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission:startSaveCurrentGame(_, blocking)
    self.currentDeviceHasNoSpace = false
    if g_dedicatedServer == nil then
        self.doSaveGameState = InGameMenu.SAVE_STATE_WRITE
        self.doSaveGameBlocking = blocking
        g_inGameMenu:startSavingGameDisplay()
    else
        self:saveSavegame(blocking)
    end
    self:accumulatePlayedTime()
    g_gameSettings:save()
end
function FSBaseMission:accumulatePlayedTime()
    local now = g_time
    local deltaMs = now - (self.lastPlayTimeSampleTime or now)
    self.lastPlayTimeSampleTime = now
    if deltaMs > 0 then
        local deltaSeconds = math.floor(deltaMs / 1000)
        g_gameSettings:setValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS, (g_gameSettings:getValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS) < 0 and 0 or g_gameSettings:getValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS)) + deltaSeconds)
    end
end
function FSBaseMission:saveSavegame(blocking)
    if not g_sleepManager:getIsSleeping() then
        if GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION then
            self.isSaving = true
            self:pauseGame()
        end
        g_savegameController:saveSavegame(self.missionInfo, blocking)
    end
end
function FSBaseMission:setGrowthMode(mode, noEventSend)
    self.growthSystem:setGrowthMode(mode, noEventSend)
    g_inGameMenu:onGrowthModeChanged()
end
function FSBaseMission:setFixedSeasonalVisuals(period, noEventSend)
    if period ~= self.missionInfo.fixedSeasonalVisuals then
        self.environment:setFixedPeriod(period)
        SavegameSettingsEvent.sendEvent(noEventSend)
        Logging.info("Savegame Setting \'fixedSeasonalVisuals\': %s", period)
    end
end
function FSBaseMission:setPlannedDaysPerPeriod(days, noEventSend)
    days = math.clamp(days, 1, Environment.MAX_DAYS_PER_PERIOD)
    if days ~= self.missionInfo.plannedDaysPerPeriod then
        self.environment:setPlannedDaysPerPeriod(days)
        SavegameSettingsEvent.sendEvent(noEventSend)
        Logging.info("Savegame Setting \'plannedDaysPerPeriod\': %s", days)
    end
end
function FSBaseMission:setFruitDestructionEnabled(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.fruitDestruction then
        self.missionInfo.fruitDestruction = isEnabled
        SavegameSettingsEvent.sendEvent(noEventSend)
        Logging.info("Savegame Setting \'fruitDesctructionEnabled\': %s", isEnabled)
    end
end
function FSBaseMission:setPlowingRequiredEnabled(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.plowingRequiredEnabled then
        self.missionInfo.plowingRequiredEnabled = isEnabled
        SavegameSettingsEvent.sendEvent(noEventSend)
        Logging.info("Savegame Setting \'plowingRequiredEnabled\': %s", isEnabled)
        g_inGameMenu:onSoilSettingChanged()
    end
end
function FSBaseMission:setStonesEnabled(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.stonesEnabled then
        self.missionInfo.stonesEnabled = isEnabled
        SavegameSettingsEvent.sendEvent(noEventSend)
        Logging.info("Savegame Setting \'stonesEnabled\': %s", isEnabled)
        g_inGameMenu:onSoilSettingChanged()
    end
end
function FSBaseMission:setLimeRequired(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.limeRequired then
        self.missionInfo.limeRequired = isEnabled
        SavegameSettingsEvent.sendEvent(noEventSend)
        Logging.info("Savegame Setting \'limeRequired\': %s", isEnabled)
        g_inGameMenu:onSoilSettingChanged()
    end
end
function FSBaseMission:setWeedsEnabled(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.weedsEnabled then
        self.missionInfo.weedsEnabled = isEnabled
        self.growthSystem:onWeedGrowthChanged()
        SavegameSettingsEvent.sendEvent(noEventSend)
        Logging.info("Savegame Setting \'weedsEnabled\': %s", isEnabled)
        g_inGameMenu:onSoilSettingChanged()
    end
end
function FSBaseMission:setStopAndGoBraking(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.stopAndGoBraking then
        self.missionInfo.stopAndGoBraking = isEnabled
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission:setTrailerFillLimit(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.trailerFillLimit then
        self.missionInfo.trailerFillLimit = isEnabled
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission:setDisasterDestructionState(state, noEventSend)
    if state ~= self.missionInfo.disasterDestructionState then
        self.missionInfo.disasterDestructionState = state
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission.setAutoSaveInterval(_, intervalMinutes, noEventSend)
    if intervalMinutes ~= g_autoSaveManager:getInterval() then
        g_autoSaveManager:setInterval(intervalMinutes)
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission:setTrafficEnabled(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.trafficEnabled then
        self.missionInfo.trafficEnabled = isEnabled
        SavegameSettingsEvent.sendEvent(noEventSend)
        if self.trafficSystem ~= nil then
            self.trafficSystem:setEnabled(self.missionInfo.trafficEnabled)
            if not self.missionInfo.trafficEnabled then
                self.trafficSystem:reset()
            end
            Logging.info("Savegame Setting \'trafficEnabled\': %s", isEnabled)
        end
    end
end
function FSBaseMission:setDirtInterval(dirtInterval, noEventSend)
    if dirtInterval ~= self.missionInfo.dirtInterval then
        self.missionInfo.dirtInterval = dirtInterval
        SavegameSettingsEvent.sendEvent(noEventSend)
        Logging.info("Savegame Setting \'dirtInterval\': %d", dirtInterval)
    end
end
function FSBaseMission:setFuelUsage(fuelUsage, noEventSend)
    if fuelUsage ~= self.missionInfo.fuelUsage then
        self.missionInfo.fuelUsage = fuelUsage
        SavegameSettingsEvent.sendEvent(noEventSend)
        Logging.info("Savegame Setting \'fuelUsage\': %d", fuelUsage)
    end
end
function FSBaseMission:setHelperBuyFuel(helperBuyFuel, noEventSend)
    if helperBuyFuel ~= self.missionInfo.helperBuyFuel then
        self.missionInfo.helperBuyFuel = helperBuyFuel
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission:setHelperBuySeeds(helperBuySeeds, noEventSend)
    if helperBuySeeds ~= self.missionInfo.helperBuySeeds then
        self.missionInfo.helperBuySeeds = helperBuySeeds
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission:setHelperBuyFertilizer(helperBuyFertilizer, noEventSend)
    if helperBuyFertilizer ~= self.missionInfo.helperBuyFertilizer then
        self.missionInfo.helperBuyFertilizer = helperBuyFertilizer
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission:setHelperSlurrySource(helperSlurrySource, noEventSend)
    if helperSlurrySource ~= self.missionInfo.helperSlurrySource then
        local loadingStation = self.liquidManureLoadingStations[helperSlurrySource - 2]
        if loadingStation == nil then
            if helperSlurrySource == 2 then
                Logging.devInfo("Set Helper Slurry Source to \'Buy\'")
            elseif helperSlurrySource == 1 then
                Logging.devInfo("Set Helper Slurry Source to \'None\'")
            end
        else
            Logging.devInfo("Set Helper Slurry Source to \'%s\'", loadingStation:getName())
        end
        self.missionInfo.helperSlurrySource = helperSlurrySource
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission:setHelperManureSource(helperManureSource, noEventSend)
    if helperManureSource ~= self.missionInfo.helperManureSource then
        self.missionInfo.helperManureSource = helperManureSource
        local loadingStation = self.manureLoadingStations[helperManureSource - 2]
        if loadingStation == nil then
            if helperManureSource == 2 then
                Logging.devInfo("Set Helper Manure Source to \'Buy\'")
            elseif helperManureSource == 1 then
                Logging.devInfo("Set Helper Manure Source to \'None\'")
            end
        else
            Logging.devInfo("Set Helper Manure Source to %s", loadingStation:getName())
        end
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission:setAutomaticMotorStartEnabled(isEnabled, noEventSend)
    if isEnabled ~= self.missionInfo.automaticMotorStartEnabled then
        self.missionInfo.automaticMotorStartEnabled = isEnabled
        SavegameSettingsEvent.sendEvent(noEventSend)
    end
end
function FSBaseMission:addKnownSplitShape(shape) end
function FSBaseMission:removeKnownSplitShape(shape) end
function FSBaseMission:getDoghouse(farmId)
    for _, doghouse in pairs(self.doghouses) do
        if doghouse:getOwnerFarmId() == farmId then
            return doghouse
        end
    end
    return nil
end
function FSBaseMission:onDayChanged() end
function FSBaseMission:onHourChanged()
    if self:getIsServer() then
        self:showMoneyChange(MoneyType.AI, nil, true)
    end
end
function FSBaseMission:onMinuteChanged() end
function FSBaseMission:pauseRadio()
    if g_soundPlayer ~= nil then
        self:setRadioActionEventsState(false)
        if self.hud ~= nil then
            self.hud:hideTopNotification()
        end
        g_soundPlayer:pause()
    end
end
function FSBaseMission:playRadio()
    if g_soundPlayer ~= nil and g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE) then
        self:setRadioActionEventsState((g_soundPlayer:play()))
    end
end
function FSBaseMission:getIsRadioPlaying()
    if g_soundPlayer == nil then
        return false
    else
        return g_soundPlayer:getIsPlaying()
    end
end
function FSBaseMission:onSoundPlayerChange(channelName, itemName, isOnlineStream, iconFilename)
    if not GS_IS_MOBILE_VERSION then
        local rating = ""
        if isOnlineStream then
            rating = g_i18n:getText("ui_radioRating")
        end
        self:addGameNotification(channelName, itemName, rating, iconFilename, 4000)
    end
    g_messageCenter:publish(MessageType.RADIO_CHANNEL_CHANGE, channelName, itemName, isOnlineStream)
end
function FSBaseMission:onSoundPlayerStreamAccess()
    if g_gameSettings:getValue(GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED) then
        self:onStreamAccessAllowed(true)
    else
        YesNoDialog.show(self.onStreamAccessAllowed, self, g_i18n:getText("ui_radioRating") .. "\n\n" .. g_i18n:getText("ui_continueQuestion"))
    end
end
function FSBaseMission.onStreamAccessAllowed(_, yes)
    if g_soundPlayer ~= nil then
        if yes then
            g_gameSettings:setValue(GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED, true, true)
        end
        g_soundPlayer:setStreamAccessAllowed(yes)
    end
end
function FSBaseMission:setMoneyUnit(unit)
    FSBaseMission:superClass().setMoneyUnit(self, unit)
    self.hud:setMoneyUnit(unit)
end
function FSBaseMission:teleportVehicle(teleportVehicle, targetX, targetZ, rotY)
    self.isTeleporting = true
    local vehicleCombos = {}
    local vehicles = {}
    local attachedVehicles = {}
    local function addVehiclePositions(vehicle)
        -- upvalues: (copy) teleportVehicle, (copy) vehicles, (copy) addVehiclePositions, (copy) attachedVehicles, (copy) vehicleCombos
        local x, y, z = getWorldTranslation(vehicle.rootNode)
        local rx, ry, rz = getWorldRotation(vehicle.rootNode)
        local ox, oy, oz = worldToLocal(teleportVehicle.rootNode, x, y, z)
        local rox, roy, roz = worldRotationToLocal(teleportVehicle.rootNode, rx, ry, rz)
        table.insert(vehicles, {
            ["vehicle"] = vehicle,
            ["offset"] = { ox, oy, oz },
            ["rotationOffset"] = { rox, roy, roz }
        })
        if vehicle.getAttachedImplements ~= nil then
            local attachedImplements = vehicle:getAttachedImplements()
            for k, implement in ipairs(attachedImplements) do
                if not implement.object:getIsAdditionalAttachment() then
                    addVehiclePositions(implement.object)
                    table.insert(attachedVehicles, implement.object)
                    table.insert(vehicleCombos, {
                        ["vehicle"] = vehicle,
                        ["object"] = implement.object,
                        ["jointDescIndex"] = implement.jointDescIndex,
                        ["inputAttacherJointDescIndex"] = implement.object:getActiveInputAttacherJointDescIndex()
                    })
                end
            end
        end
    end
    addVehiclePositions(teleportVehicle)
    for _, attachedVehicle in ipairs(attachedVehicles) do
        local attacherVehicle = attachedVehicle:getAttacherVehicle()
        if attacherVehicle ~= nil then
            attacherVehicle:detachImplementByObject(attachedVehicle, true)
        end
    end
    for _, attachedVehicle in pairs(vehicles) do
        attachedVehicle.vehicle:removeFromPhysics()
    end
    for _, attachedVehicle in pairs(vehicles) do
        local xRot = 0
        local zRot = 0
        local attacherVehicle, y, z, yRot
        if _ > 1 then
            attacherVehicle, y, z = localToWorld(teleportVehicle.rootNode, unpack(attachedVehicle.offset))
            xRot, yRot, zRot = localRotationToWorld(teleportVehicle.rootNode, unpack(attachedVehicle.rotationOffset))
        else
            y = getTerrainHeightAtWorldPos(g_terrainNode, targetX, 300, targetZ) + 0.5
            yRot = rotY
            z = targetZ
            attacherVehicle = targetX
        end
        attachedVehicle.vehicle:setAbsolutePosition(attacherVehicle, y, z, xRot, yRot, zRot)
    end
    for _, attachedVehicle in pairs(vehicles) do
        attachedVehicle.vehicle:addToPhysics()
    end
    for _, attachedVehicle in pairs(vehicleCombos) do
        attachedVehicle.vehicle:attachImplement(attachedVehicle.object, attachedVehicle.inputAttacherJointDescIndex, attachedVehicle.jointDescIndex, true)
    end
    self.isTeleporting = false
end
function FSBaseMission:consoleCommandCheatMoney(amount, farmId)
    if not (self:getIsServer() or self.isMasterUser) then
        return "gsMoneyAdd is only available for server and/or admins"
    end
    amount = tonumber(amount) or 10000000
    amount = math.clamp(amount, -1000000000, 1000000000)
    farmId = tonumber(farmId) or g_localPlayer.farmId
    if g_farmManager:getFarmById(farmId) == nil then
        return string.format("No farm for id \'%s\'", farmId)
    end
    if self:getIsServer() then
        self:addMoney(amount, farmId, MoneyType.OTHER, true, true)
    else
        g_client:getServerConnection():sendEvent(CheatMoneyEvent.new(amount, farmId))
    end
    return string.format("Added money %d. Use \'gsMoneyAdd <amount> <farmId>\' to add or remove a custom amount to a specific farm", amount)
end
function FSBaseMission:consoleCommandExportStoreItems()
    local csvFile = getUserProfileAppPath() .. "storeItems.csv"
    local specTypes = g_storeManager:getSpecTypes()
    local file = io.open(csvFile, "w")
    if file == nil then
        printError(string.format("Error: Unable to create csv file \'%s\'", csvFile))
    else
        local header = "xmlFilename;category;brand;brandTitle;name;price;lifetime;dailyUpkeep;showInStore;brushType;brushCategory;brushTab;"
        for _, spec in ipairs(specTypes) do

        end
        file:write(header .. "\n")
        local storeItems = g_storeManager:getItems()
        for spec, storeItem in pairs(storeItems) do
            local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
            local brushType = ""
            local brushCategory = ""
            local brushTab = ""
            if storeItem.brush ~= nil then
                brushType = storeItem.brush.type
                brushCategory = storeItem.brush.category.name
                brushTab = storeItem.brush.tab.name
            end
            local data = string.format("%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;", storeItem.xmlFilename, storeItem.categoryName, brand.name, brand.title, storeItem.name, storeItem.price, storeItem.lifetime, storeItem.dailyUpkeep, storeItem.showInStore, brushType, brushCategory, brushTab)
            StoreItemUtil.loadSpecsFromXML(storeItem)
            for _, spec in ipairs(specTypes) do
                local value = nil
                if spec.species == storeItem.species then
                    value = spec.getValueFunc(storeItem, nil)
                end
                local value = (value == nil or type(value) == "table") and "" or value
                if spec.name == "placeableSlots" then
                    value = string.gsub(value, " %$SLOTS%$", "")
                end
                data = data .. string.trim((tostring(value))) .. ";"
            end
            file:write(data .. "\n")
        end
        printf("Exported %i store items to \'%s\'", #storeItems, csvFile)
        file:close()
    end
end
function FSBaseMission:consoleStartGreatDemand()
    for _, greatDemand in pairs(self.economyManager.greatDemands) do
        self.economyManager:stopGreatDemand(greatDemand)
    end
    for _, greatDemand in pairs(self.economyManager.greatDemands) do
        greatDemand:setUpRandomDemand(true, self.economyManager.greatDemands, self)
        greatDemand.demandStart.day = g_currentMission.environment.currentDay
        greatDemand.demandStart.hour = g_currentMission.environment.currentHour + 1
    end
    return "Great demand starts in the next hour..."
end
function FSBaseMission:consoleCommandTeleport(farmlandIdOrX, zPos, useWorldCoords)
    local targetX = tonumber(farmlandIdOrX)
    local targetX = tonumber(zPos)
    local targetX = Utils.stringToBoolean(useWorldCoords)
    if targetX == nil then
        return "Error: Invalid farmland-id or x-position\nUsage: gsTeleport xPos|farmland [zPos] [useWorldCoords]\n  if zPos is not given first parameter is used as field id.\n  set useWorldCoords to true if given coordinates are in 3D/world (0 0 = map center) instead of minimap (0 0 = map corner) space."
    end
    if targetX == nil then
        local farmland = g_farmlandManager:getFarmlandById(targetX)
        if farmland == nil then
            return string.format("Error: Invalid farmland id \'%s\'\n%s", targetX, "Usage: gsTeleport xPos|farmland [zPos] [useWorldCoords]\n  if zPos is not given first parameter is used as field id.\n  set useWorldCoords to true if given coordinates are in 3D/world (0 0 = map center) instead of minimap (0 0 = map corner) space.")
        end
        targetX, targetX = farmland:getTeleportPosition()
    elseif not targetX then
        local farmland = self.terrainSize
        local worldSizeZ = self.terrainSize
        targetX = math.clamp(targetX, 0, farmland) - farmland * 0.5
        targetX = math.clamp(targetX, 0, worldSizeZ) - worldSizeZ * 0.5
    end
    local farmland = g_localPlayer:getCurrentVehicle()
    if farmland == nil then
        local worldSizeZ = getTerrainHeightAtWorldPos(g_terrainNode, targetX, 0, targetX)
        local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, targetX, 0, targetX)
        local _, _, colY, _ = RaycastUtil.raycastClosest(targetX, terrainHeight + 30, targetX, 0, -1, 0, 30, CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD + CollisionFlag.BUILDING)
        local worldSizeZ = math.max((colY or terrainHeight) + 0.1, worldSizeZ)
        g_localPlayer:teleportTo(targetX, worldSizeZ + 0.1, targetX)
    else
        local worldSizeZ, terrainHeight, raycastLength = getWorldRotation(farmland.rootNode)
        if self:getIsServer() then
            self:teleportVehicle(farmland, targetX, targetX, terrainHeight)
        else
            g_client:getServerConnection():sendEvent(VehicleTeleportEvent.new(farmland, targetX, targetX, terrainHeight))
        end
    end
    return string.format("Teleported to world coordinates x=%d z=%d", targetX, targetX)
end
function FSBaseMission:consoleActivateCameraPath(cameraPathIndex)
    local finishedCallback = tonumber(cameraPathIndex)
    if finishedCallback == nil or (finishedCallback < 1 or #self.cameraPaths < finishedCallback) then
        return "Invalid argument. Argument: cameraPathIndex"
    end
    if self.currentCameraPath ~= nil then
        self.currentCameraPath:deactivate()
    end
    self.currentCameraPath = self.cameraPaths[finishedCallback]
    function self.currentCameraPath.finishedCallback()
        -- upvalues: (copy) self
        print("camera path finished")
        self.currentCameraPath:deactivate()
    end
    self.currentCameraPath:activate()
    self:addUpdateable(self.currentCameraPath)
    return "Camera path activated"
end
function FSBaseMission:consoleCommandSaveGame()
    self:saveSavegame(true)
end
function FSBaseMission:consoleCommandDisplacementDebug()
    DebugDisplacementDialog.show()
end
function FSBaseMission:consoleCommandDisplacementReset()
    local fieldGroundSystem = self.fieldGroundSystem
    local displacementMapId, displacementFirstChannel, displacementNumChannels = fieldGroundSystem:getDisplacementData()
    DensityMapModifier.new(displacementMapId, displacementFirstChannel, displacementNumChannels, g_terrainNode):executeSet((fieldGroundSystem:getDisplacementResetValue()))
end
function FSBaseMission:consoleCommandValidateUnloadTriggers()
    I3DUtil.iterateRecursively(getRootNode(), function(node)
        if getHasClassId(node, ClassIds.SHAPE) and (getRigidBodyType(node) ~= RigidBodyType.DYNAMIC and (getHasCollision(node) and CollisionFlag.getHasGroupFlagSet(node, CollisionFlag.FILLABLE))) then
            local object = g_currentMission:getNodeObject(node)
            if object ~= nil and (object.isa ~= nil and object:isa(Vehicle)) then
                return
            end
            local x, y, z = getWorldTranslation(node)
            local raycastCallbackTarget = {}
            local triggerTopDistanceToTerrainThresholdMin = 0.03
            local triggerTopDistanceToTerrainThresholdMax = 0.2
            function raycastCallbackTarget.onRaycastHit(_, actorId, _, hy, _)
                -- upvalues: (copy) node, (copy) x, (copy) z, (copy) y, (copy) triggerTopDistanceToTerrainThresholdMin, (copy) triggerTopDistanceToTerrainThresholdMax
                if actorId == g_terrainNode then
                    Logging.error("Terrain is above trigger/unloadFillNode %q at %d %d", I3DUtil.getNodePath(node), x, z)
                    return false
                end
                if actorId ~= node then
                    return true
                end
                local ty = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
                if hy - ty < 0.03 then
                    Logging.warning("Terrain very close to trigger %q (trigger top face %.4f, terrain %.4f) at %d %d", I3DUtil.getNodePath(node), hy, ty, x, z)
                    return false
                end
                local col, _, colH = RaycastUtil.raycastClosest(x, y + 3, z, 0, -1, 0, 5, CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD + CollisionFlag.AI_DRIVABLE + CollisionFlag.TERRAIN)
                if colH == nil or (col == node or hy - colH <= 0.2) then
                    return false
                end
                Logging.warning("trigger %q too far from terrain (trigger top face %.4f, col %s %.4f) at %d %d", I3DUtil.getNodePath(node), hy, getName(col), ty, x, z)
                return false
            end
            raycastAll(x, y + 3, z, 0, -1, 0, 5, "onRaycastHit", raycastCallbackTarget, CollisionFlag.FILLABLE + CollisionFlag.TERRAIN)
        end
    end)
end
function FSBaseMission:consoleCommandRunDSDensityMapUtil()
    FSDensityMapUtil.runBenchmark()
end
function FSBaseMission:consoleCommandTogglePhysicsStressTest()
    if self.debugPhysicsStressTest == nil then
        self.debugPhysicsStressTest = true
        self.debugPhysicsStressTestNextTime = 0
        self.debugPhysicsStressTestNumBlocksPerRow = 10
        self.debugPhysicsStressTestObjects = {}
        self.debugPhysicsStressTestFilename = "data/shared/assets/physicsTest.i3d"
        g_i3DManager:pinSharedI3DFileInCache(self.debugPhysicsStressTestFilename)
        function self.debugPhysicsStressTestSpawn()
            -- upvalues: (copy) self
            if g_time > self.debugPhysicsStressTestNextTime then
                local px, py, pz = g_localPlayer:getPosition()
                local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
                local i = 1
                for i = i, self.debugPhysicsStressTestNumBlocksPerRow do
                    local j = 1
                    for j = j, self.debugPhysicsStressTestNumBlocksPerRow do
                        local k = 1
                        for k = k, self.debugPhysicsStressTestNumBlocksPerRow do
                            local node, requestId = g_i3DManager:loadSharedI3DFile(self.debugPhysicsStressTestFilename, false, true)
                            setName(node, "DebugPhysicsStressTest_" .. node)
                            link(getRootNode(), node)
                            setWorldTranslation(node, px + dirX * 4 + i * 0.25, py + 1 + j * 0.25, pz + dirZ * 4 + k * 0.25)
                            table.insert(self.debugPhysicsStressTestObjects, {
                                ["node"] = node,
                                ["requestId"] = requestId
                            })
                        end
                    end
                end
                self.debugPhysicsStressTestNextTime = g_time + 3000
            end
        end
        function self.debugPhysicsStressTestRemove(dt)
            -- upvalues: (copy) self
            local numDeletes = 0
            local index = dt / 16.666666666666668 * 8
            local maxBlocks = math.floor(index)
            while numDeletes < maxBlocks do
                if #self.debugPhysicsStressTestObjects > 200 then
                    local index = math.random(1, #self.debugPhysicsStressTestObjects)
                    local data = table.remove(self.debugPhysicsStressTestObjects, index)
                    if data ~= nil then
                        delete(data.node)
                        g_i3DManager:releaseSharedI3DFile(data.requestId)
                    end
                end
                numDeletes = numDeletes + 1
            end
        end
    else
        for _, data in ipairs(self.debugPhysicsStressTestObjects) do
            delete(data.node)
            g_i3DManager:releaseSharedI3DFile(data.requestId)
        end
        g_i3DManager:unpinSharedI3DFileInCache(self.debugPhysicsStressTestFilename)
        self.debugPhysicsStressTestObjects = nil
        self.debugPhysicsStressTest = nil
        self.debugPhysicsStressTestNextTime = nil
        self.debugPhysicsStressTestNumBlocksPerRow = nil
        self.debugPhysicsStressTestFilename = nil
        self.debugPhysicsStressTestRemove = nil
        self.debugPhysicsStressTestSpawn = nil
    end
end
function FSBaseMission:updateFoundHelpIcons()
    if self.helpIconsBase ~= nil then
        local i = 1
        for i = i, string.len(self.missionInfo.foundHelpIcons) do
            if string.sub(self.missionInfo.foundHelpIcons, i, i) == "1" then
                self.helpIconsBase:deleteHelpIcon(i)
            end
        end
    end
end
function FSBaseMission:removeAllHelpIcons()
    if self.helpIconsBase ~= nil then
        local i = 1
        for i = i, string.len(self.missionInfo.foundHelpIcons) do
            self.helpIconsBase:deleteHelpIcon(i)
        end
    end
end
function FSBaseMission:playerOwnsAllFields()
    for k, _ in pairs(g_farmlandManager:getFarmlands()) do
        g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(k, 1, 0))
    end
end
function FSBaseMission:broadcastEventToMasterUser(event, ignoreConnection)
    for _, user in pairs(self.userManager:getMasterUsers()) do
        local connection = user:getConnection()
        if connection ~= ignoreConnection then
            connection:sendEvent(event)
        end
    end
    event:delete()
end
function FSBaseMission:broadcastMissionDynamicInfo(connection)
    assert(self:getIsServer(), "broadcastMissionDynamicInfo call is only allowed on Server")
    self:broadcastEventToMasterUser(MissionDynamicInfoEvent.new(), connection)
end
function FSBaseMission:updateMissionDynamicInfo(serverName, capacity, password, autoAccept, allowOnlyFriends, allowCrossPlay)
    if serverName ~= "" and g_dedicatedServer == nil then
        self.missionDynamicInfo.serverName = serverName
    end
    if g_dedicatedServer == nil then
        self.missionDynamicInfo.capacity = capacity
    end
    self.missionDynamicInfo.password = password
    if not autoAccept then
        autoAccept = g_dedicatedServer ~= nil
    end
    self.missionDynamicInfo.autoAccept = autoAccept
    self.missionDynamicInfo.allowOnlyFriends = allowOnlyFriends
    self.missionDynamicInfo.allowCrossPlay = allowCrossPlay
    self:updateMaxNumHirables()
    if g_dedicatedServer ~= nil then
        self:updateDedicatedServerXML()
    end
end
function FSBaseMission:updateMasterServerInfo(connection)
    if self:getIsServer() then
        local userCount = self.userManager:getNumberOfUsers()
        if g_dedicatedServer ~= nil then
        end
        local missionDynamicInfo = g_currentMission.missionDynamicInfo
        masterServerSetServerInfo(missionDynamicInfo.serverName, missionDynamicInfo.password, missionDynamicInfo.capacity, userCount, missionDynamicInfo.allowOnlyFriends)
        self:broadcastMissionDynamicInfo(connection)
    end
end
function FSBaseMission:updateDedicatedServerXML()
    if g_dedicatedServer ~= nil then
        local info = self.missionDynamicInfo
        g_dedicatedServer:updateServerInfo(info.serverName, info.password, info.capacity)
    end
end
function FSBaseMission:setConnectionLostState(state)
    self.connectionLostState = state
end
function FSBaseMission:addMapHotspot(hotspot)
    return self.hud:addMapHotspot(hotspot)
end
function FSBaseMission:removeMapHotspot(hotspot)
    if self.hud ~= nil then
        self.hud:removeMapHotspot(hotspot)
    end
end
function FSBaseMission:onShowHelpIconsChanged(isVisible)
    if self.helpIconsBase ~= nil then
        self.helpIconsBase:showHelpIcons(isVisible)
    end
end
function FSBaseMission:onRadioVehicleOnlyChanged(isVehicleOnly)
    local isRadioPlayingSettingActive = g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE)
    local playerVehicle = g_localPlayer:getCurrentVehicle()
    local canPlayRadioNow = not isVehicleOnly
    if canPlayRadioNow then
        isVehicleOnly = canPlayRadioNow
    elseif isVehicleOnly then
        isVehicleOnly = false
        if playerVehicle ~= nil then
            isVehicleOnly = playerVehicle.supportsRadio
        end
    end
    if isRadioPlayingSettingActive then
        if isVehicleOnly then
            if not self:getIsRadioPlaying() then
                self:playRadio()
                return
            end
        else
            self:pauseRadio()
        end
    end
end
function FSBaseMission:onRadioIsActiveChanged(isActive)
    if isActive then
        local isVehicleOnly = g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY)
        local playerVehicle = g_localPlayer:getCurrentVehicle()
        if not isVehicleOnly or isVehicleOnly and (playerVehicle ~= nil and playerVehicle.supportsRadio) then
            self:playRadio()
        end
    else
        self:pauseRadio()
    end
end
function FSBaseMission:setRadioActionEventsState(isActive)
    for _, eventId in pairs(self.radioEvents) do
        g_inputBinding:setActionEventActive(eventId, isActive)
    end
end
function FSBaseMission:subscribeMessages()
    g_messageCenter:subscribe(SaveEvent, self.startSaveCurrentGame, self)
    g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.notifyPlayerFarmChanged, self)
    g_messageCenter:subscribe(MessageType.USER_ADDED, self.onUserAdded, self)
    g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
    g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.IS_TRAIN_TABBABLE], self.setTrainSystemTabbable, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_HELP_ICONS], self.onShowHelpIconsChanged, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.RADIO_VEHICLE_ONLY], self.onRadioVehicleOnlyChanged, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.RADIO_IS_ACTIVE], self.onRadioIsActiveChanged, self)
    g_messageCenter:subscribe(MessageType.APP_SUSPENDED, self.onAppSuspended, self)
    g_messageCenter:subscribe(MessageType.APP_RESUMED, self.onAppResumed, self)
    g_messageCenter:subscribe(MessageType.WINDOW_SIZE_CHANGED, self.onWindowSizeChanged, self)
    g_messageCenter:subscribe(MessageType.GUIDED_TOUR_STARTED, self.onGuidedTourStarted, self)
    g_messageCenter:subscribe(MessageType.GUIDED_TOUR_FINISHED, self.onGuidedTourFinished, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
end
function FSBaseMission:onWindowSizeChanged()
    if self.isLoaded then
        if GS_IS_MOBILE_VERSION and not g_savegameController:getIsSaving() then
            self:saveSavegame(true)
        end
    end
end
function FSBaseMission:onAppSuspended()
    if self.isLoaded then
        if GS_IS_MOBILE_VERSION and not g_savegameController:getIsSaving() then
            self:saveSavegame(true)
        end
    end
end
function FSBaseMission:onAppResumed()
    if not g_gui:getIsGuiVisible() then
        g_autoSaveManager:resetTime()
        if not g_sleepManager:getIsSleeping() then
            g_gui:changeScreen(nil, InGameMenu)
            if GS_IS_MOBILE_VERSION then
                g_inGameMenu:goToPage(g_inGameMenu.pageMain)
            end
        end
    end
end
function FSBaseMission:getCanShowHelpTriggers()
    if g_guidedTourManager:getIsTourRunning() then
        return false
    else
        return FSBaseMission:superClass().getCanShowHelpTriggers(self)
    end
end
function FSBaseMission:onGuidedTourStarted()
    if not g_gameSettings:getValue(GameSettings.SETTING.STARTED_GUIDED_TOUR) then
        g_gameSettings:setValue(GameSettings.SETTING.STARTED_GUIDED_TOUR, true, true)
    end
end
function FSBaseMission:onGuidedTourFinished() end
function FSBaseMission:setColorBlindMode(isActive)
    if self.mapOverlayGenerator ~= nil then
        self.mapOverlayGenerator:setColorBlindMode(isActive)
    end
end
function FSBaseMission:notifyPlayerFarmChanged(player)
    local localPlayer = g_localPlayer
    if localPlayer ~= nil and player == localPlayer then
        if self:getIsClient() and localPlayer:getIsInVehicle() then
            localPlayer:leaveVehicle()
        end
        local farm = g_farmManager:getFarmById(localPlayer:getFarmId())
        g_inGameMenu:setPlayerFarm(farm)
        g_shopMenu:setPlayerFarm(farm)
        g_shopController:setOwnedFarmItems(self.ownedItems, localPlayer.farmId)
        g_shopController:setLeasedFarmItems(self.leasedItems, localPlayer.farmId)
        g_shopMenu:onMoneyChange()
    end
end
function FSBaseMission:onUserAdded(user)
    self:updateMaxNumHirables()
    if user:getId() == self.playerUserId then
        g_inGameMenu:setCurrentUserId(self.playerUserId)
        g_shopMenu:setCurrentUserId(self.playerUserId)
    end
    if user:getId() ~= self:getServerUserId() and user:getId() ~= self.playerUserId then
        print(user:getNickname() .. " joined the game")
        g_currentMission:addChatMessage(user:getNickname(), g_i18n:getText("ui_serverUserJoin"), FarmManager.SPECTATOR_FARM_ID)
    end
    g_inGameMenu:setConnectedUsers(self.userManager:getUsers())
    self.userManager:setUserBlockDataDirty()
end
function FSBaseMission:onUserRemoved(user, disconnectReason)
    self:updateMaxNumHirables()
    if user:getId() ~= self:getServerUserId() and user:getId() ~= self.playerUserId then
        local nickname = user:getNickname()
        if disconnectReason == nil or disconnectReason == DisconnectReason.PLAYER_LEFT then
            print(nickname .. " left the game")
            g_currentMission:addChatMessage(nickname, g_i18n:getText("ui_serverUserLeave"), FarmManager.SPECTATOR_FARM_ID)
        elseif disconnectReason == DisconnectReason.PLAYER_LOST_CONNECTION then
            print(nickname .. " lost connection to the game")
            g_currentMission:addChatMessage(nickname, g_i18n:getText("ui_serverUserLostConnection"), FarmManager.SPECTATOR_FARM_ID)
        elseif disconnectReason == DisconnectReason.KICKED then
            print(nickname .. " was kicked from the game")
            g_currentMission:addChatMessage(nickname, g_i18n:getText("ui_serverUserWasKicked"), FarmManager.SPECTATOR_FARM_ID)
        elseif disconnectReason == DisconnectReason.BANNED then
            print(nickname .. " was banned")
            g_currentMission:addChatMessage(nickname, g_i18n:getText("ui_serverUserWasBanned"), FarmManager.SPECTATOR_FARM_ID)
        end
    end
    g_inGameMenu:setConnectedUsers(self.userManager:getUsers())
end
function FSBaseMission:onMasterUserAdded(user)
    if user:getId() == self.playerUserId then
        self.isMasterUser = true
        if g_addCheatCommands then
            addConsoleCommand("gsMoneyAdd", "Add a lot of money", "consoleCommandCheatMoney", self, "[amount]; [farmId]")
        end
    end
    if self:getIsServer() then
        g_server:broadcastEvent(UserDataEvent.new({ user }))
    end
end
function FSBaseMission:broadcastEventToFarm(event, farmId, sendLocal, ignoreConnection, ghostObject, force)
    local connectionList = {}
    for streamId, connection in pairs(g_server.clientConnections) do
        local player = self.connectionsToPlayer[connection]
        if player ~= nil and player.farmId == farmId then
            connectionList[streamId] = connection
        end
    end
    g_server:broadcastEvent(event, sendLocal, ignoreConnection, ghostObject, force, connectionList)
end
function FSBaseMission:getDefaultServerName()
    local nickname = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
    if g_languageShort == "pl" then
        return nickname .. " - " .. g_i18n:getText("ui_serverNameGame")
    elseif nickname:endsWith("s") then
        return nickname .. "\' " .. g_i18n:getText("ui_serverNameGame")
    elseif nickname:endsWith("\'") then
        return nickname .. "s " .. g_i18n:getText("ui_serverNameGame")
    else
        return nickname .. "\'s " .. g_i18n:getText("ui_serverNameGame")
    end
end
function FSBaseMission.setLastCreatedLicensePlate(_, licensePlateData)
    if licensePlateData ~= nil and licensePlateData.placementIndex ~= LicensePlateManager.PLATE_POSITION.NONE then
        local copy = {
            ["variation"] = licensePlateData.variation,
            ["colorIndex"] = licensePlateData.colorIndex,
            ["placementIndex"] = licensePlateData.placementIndex,
            ["characters"] = table.clone(licensePlateData.characters),
            ["xmlFilename"] = g_licensePlateManager.xmlFilename
        }
        g_gameSettings.lastCreatedLicensePlate = copy
        g_gameSettings:save()
    end
end
function FSBaseMission:getLastCreatedLicensePlate()
    local data = g_gameSettings.lastCreatedLicensePlate
    if data == nil then
        return nil
    elseif data.xmlFilename == g_licensePlateManager.xmlFilename then
        return data.characters ~= nil and {
            ["variation"] = data.variation,
            ["colorIndex"] = data.colorIndex,
            ["placementIndex"] = data.placementIndex,
            ["characters"] = table.clone(data.characters)
        } or nil
    else
        return nil
    end
end