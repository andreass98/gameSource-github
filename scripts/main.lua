source("dataS/scripts/std.lua")
source("dataS/scripts/StartParams.lua")
source("dataS/scripts/testing.lua")
source("dataS/scripts/events.lua")
source("dataS/scripts/menu.lua")
newGetSafeFrameInsets = getSafeFrameInsets
function getSafeFrameInsets()
    return 0, 0, 0, 0
end
AutoLoadParams = {
    ["enable"] = false,
    ["x"] = 0,
    ["y"] = 0,
    ["z"] = 0
}
local debugTool = debug
debug = nil
GS_PROFILE_VERY_LOW = 1
GS_PROFILE_LOW = 2
GS_PROFILE_MEDIUM = 3
GS_PROFILE_HIGH = 4
GS_PROFILE_VERY_HIGH = 5
GS_PROFILE_ULTRA = 6
g_gameVersion = 23
g_gameVersionNotification = "1.21.1.0"
g_gameVersionDisplay = "1.21.1.0"
g_gameVersionDisplayExtra = ""
g_isDevelopmentConsoleScriptModTesting = false
g_minModDescVersion = 90
g_maxModDescVersion = 111
g_language = 0
g_languageShort = "en"
g_languageSuffix = "_en"
g_showSafeFrame = false
g_noHudModeEnabled = false
g_woodCuttingMarkerEnabled = true
g_isDevelopmentVersion = false
g_isServerStreamingVersion = false
g_addTestCommands = false
g_addCheatCommands = false
g_showDevelopmentWarnings = false
g_appIsSuspended = false
g_networkDebug = false
g_networkDebugPrints = false
g_gameRevision = "000"
g_buildName = ""
g_buildTypeParam = ""
g_gameBasePath = g_gameBasePath or ""
g_showDeeplinkingFailedMessage = false
g_isSignedIn = false
g_settingsLanguageGUI = 0
g_availableLanguageNamesTable = {}
g_availableLanguagesTable = {}
g_fovYDefault = 1.0471975511965976
g_fovYMin = 0.6981317007977318
g_fovYMax = 2.0943951023931953
g_uiDebugEnabled = false
g_uiFocusDebugEnabled = false
g_logFilePrefixTimestamp = true
g_densityMapRevision = 4
g_terrainTextureRevision = 1
g_terrainLodTextureRevision = 2
g_splitShapesRevision = 2
g_tipCollisionRevision = 2
g_placementCollisionRevision = 2
g_navigationCollisionRevision = 2
g_menuMusic = nil
g_menuMusicIsPlayingStarted = false
g_clientInterpDelay = 100
g_clientInterpDelayMin = 60
g_clientInterpDelayMax = 150
g_clientInterpDelayBufferOffset = 30
g_clientInterpDelayBufferScale = 0.5
g_clientInterpDelayBufferMin = 45
g_clientInterpDelayBufferMax = 60
g_clientInterpDelayAdjustDown = 0.002
g_clientInterpDelayAdjustUp = 0.08
g_time = 0
g_currentDt = 16.666666666666668
g_updateLoopIndex = 0
g_physicsTimeLooped = 0
g_physicsDt = 16.666666666666668
g_physicsDtUnclamped = 16.666666666666668
g_physicsDtNonInterpolated = 16.666666666666668
g_physicsDtLastValidNonInterpolated = 16.666666666666668
g_packetPhysicsNetworkTime = 0
g_networkTime = netGetTime()
g_physicsNetworkTime = g_networkTime
g_analogStickHTolerance = 0.45
g_analogStickVTolerance = 0.45
g_referenceScreenWidth = 1920
g_referenceScreenHeight = 1080
g_maxUploadRate = 30.72
g_maxUploadRatePerClient = 393.216
g_drawGuiHelper = false
g_guiHelperSteps = 0.1
g_lastMousePosX = 0
g_lastMousePosY = 0
g_screenWidth = 800
g_screenHeight = 600
g_pixelSizeX = 1 / g_screenWidth
g_pixelSizeY = 1 / g_screenHeight
g_screenAspectRatio = g_screenWidth / g_screenHeight
g_presentedScreenAspectRatio = g_screenAspectRatio
g_aspectScaleX = 1
g_aspectScaleY = 1
g_dedicatedServer = nil
g_joinServerMaxCapacity = 16
g_serverMaxClientCapacity = 16
g_serverMinCapacity = 2
g_nextModRecommendationTime = 0
g_maxNumLoadingBarSteps = 35
g_curNumLoadingBarStep = 0
g_updateDownloadFinished = false
g_updateDownloadFinishedDialogShown = false
g_skipStartupScreen = false
function initPlatform()
    local debugPlatformId = nil
    if StartParams.getIsSet("platform") then
        local debugPlatform = string.upper(string.trim(StartParams.getValue("platform") or ""))
        if PlatformId[debugPlatform] == nil then
            if debugPlatform == "STEAM" then
                debugPlatformId = PlatformId.WIN
                GS_IS_STEAM_VERSION = true
            elseif debugPlatform == "EPIC" then
                debugPlatformId = PlatformId.WIN
                GS_IS_EPIC_VERSION = true
            elseif debugPlatform == "MSSTORE" then
                debugPlatformId = PlatformId.WIN
                GS_IS_MSSTORE_VERSION = true
            elseif debugPlatform == "NETFLIX" then
                debugPlatformId = PlatformId.ANDROID
                GS_IS_NETFLIX_VERSION = true
            else
                printError(string.format("Error: Invalid platform \'%s\'", debugPlatform))
            end
        else
            debugPlatformId = PlatformId[debugPlatform]
        end
    end
    if debugPlatformId ~= nil then
        function getPlatformId()
            -- upvalues: (ref) debugPlatformId
            return debugPlatformId
        end
    end
    local debugPlatform = getPlatformId()
    GS_PLATFORM_ID = debugPlatform
    GS_PLATFORM_PC = debugPlatform == PlatformId.WIN or debugPlatform == PlatformId.MAC
    GS_PLATFORM_XBOX = debugPlatform == PlatformId.XBOX_SERIES
    GS_PLATFORM_PLAYSTATION = debugPlatform == PlatformId.PS5
    GS_PLATFORM_SWITCH = debugPlatform == PlatformId.SWITCH
    GS_PLATFORM_SWITCH2 = debugPlatform == PlatformId.SWITCH2
    GS_PLATFORM_PHONE = debugPlatform == PlatformId.ANDROID or debugPlatform == PlatformId.IOS
    GS_IS_CONSOLE_VERSION = GS_PLATFORM_XBOX or (GS_PLATFORM_PLAYSTATION or GS_PLATFORM_SWITCH2)
    GS_IS_MOBILE_VERSION = GS_PLATFORM_PHONE or GS_PLATFORM_SWITCH
end
function init(args)
    -- upvalues: (copy) debugTool
    StartParams.init(args)
    initPlatform()
    source("dataS/scripts/game.lua")
    getClipboard = nil
    addFoliageTypeFromXML = nil
    setModHubRating = nil
    getModHubRating = nil
    if not initTesting() then
        setTextureStreamingPaused(true)
        local settingsXML = XMLFile.load("SettingsFile", "dataS/settings.xml")
        local developmentLevel = settingsXML:getString("settings#developmentLevel", "release"):lower()
        g_buildName = settingsXML:getString("settings#buildName", g_buildName)
        g_buildTypeParam = settingsXML:getString("settings#buildTypeParam", g_buildTypeParam)
        g_gameRevision = settingsXML:getString("settings#revision", g_gameRevision)
        g_gameRevision = g_gameRevision .. getGameRevisionExtraText()
        g_isDevelopmentVersion = false
        if developmentLevel == "internal" then
            print("INTERNAL VERSION")
            g_addTestCommands = true
        elseif developmentLevel == "development" then
            print("DEVELOPMENT VERSION")
            g_isDevelopmentVersion = true
            g_addTestCommands = true
            enableDevelopmentControls()
        end
        if StartParams.getIsSet("releaseBuild") then
            g_isDevelopmentVersion = false
        end
        if g_isDevelopmentVersion then
            g_networkDebug = true
            print(string.format("GameDirectory: %s", getAppBasePath()))
            print(string.format("UniqueUserId: %s", getUniqueUserId()))
        end
        if g_addTestCommands or StartParams.getIsSet("cheats") then
            g_addCheatCommands = true
        end
        if g_addTestCommands or StartParams.getIsSet("devWarnings") then
            g_showDevelopmentWarnings = true
        end
        if g_isDevelopmentVersion then
            if StartParams.getIsSet("consoleSimulator") then
                ConsoleSimulator.init()
                ImeSimulator.init()
            end
            if StartParams.getIsSet("imeSimulator") then
                ImeSimulator.init()
            end
            if StartParams.getIsSet("iapSimulator") then
                IAPSimulator.init()
            end
            if StartParams.getIsSet("mobileSimulator") then
                MobileSimulator.init()
            end
            if StartParams.getIsSet("gameLoadingCancelSimulator") then
                GameLoadingCancelSimulator.init()
            end
            Profiler.init()
        end
        if setLuaErrorHandler ~= nil and (StartParams.getIsSet("scriptDebug") or g_isDevelopmentVersion) then
            if debugTool == nil or debugTool.traceback == nil then
                print("Info: lua custom error handler enabled (B)")
                setLuaErrorHandler(function(errorString)
                    printCallstack()
                    return errorString
                end)
            else
                print("Info: lua custom error handler enabled (A)")
                setLuaErrorHandler(function(errorString)
                    -- upvalues: (ref) debugTool
                    return debugTool.traceback(errorString, 2)
                end)
            end
        end
        local kioskMode = GS_IS_CONSOLE_VERSION and 6 or 16
        g_serverMaxCapacity = kioskMode
        AudioGroup.loadGroups()
        CollisionPreset.init()
        ObjectMask.init()
        g_i3DManager:init()
        g_cameraManager:init()
        updateLoadingBarProgress()
        g_messageCenter = MessageCenter.new()
        updateLoadingBarProgress()
        g_soundMixer = SoundMixer.new()
        g_soundMixer:loadFromXML("dataS/soundMixer.xml")
        updateLoadingBarProgress()
        g_autoSaveManager = AutoSaveManager.new()
        updateLoadingBarProgress()
        local kioskMode = KioskMode.new()
        if kioskMode:load() then
            g_kioskMode = kioskMode
        end
        g_lifetimeStats = LifetimeStats.new()
        g_lifetimeStats:load()
        local isServerStart = StartParams.getIsSet("server") or StartParams.getIsSet("serverWithGui")
        local autoStartSavegameId = StartParams.getValue("autoStartSavegameId")
        local autoLoadURI = StartParams.getValue("autoLoadURI")
        local devStartServer = StartParams.getValue("devStartServer")
        local devStartClient = StartParams.getValue("devStartClient")
        local devUniqueUserId = g_isDevelopmentVersion and StartParams.getValue("uniqueUserId") or nil
        if Platform.isPlaystation then
            g_unsafeScreenWidth = 1920
            g_unsafeScreenHeight = 1080
        else
            local safeFrameOffsetX, safeFrameOffsetY = getScreenModeInfo(getScreenMode())
            g_unsafeScreenWidth = safeFrameOffsetX
            g_unsafeScreenHeight = safeFrameOffsetY
        end
        g_safeFrameScreenOffsetX = 0
        g_safeFrameScreenOffsetY = 0
        g_screenWidth = g_unsafeScreenWidth - g_safeFrameScreenOffsetX * 2
        g_screenHeight = g_unsafeScreenHeight - g_safeFrameScreenOffsetY * 2
        g_safeFrameRatioX = g_screenWidth / g_unsafeScreenWidth
        g_safeFrameRatioY = g_screenHeight / g_unsafeScreenHeight
        g_pixelSizeX = 1 / g_unsafeScreenWidth
        g_pixelSizeY = 1 / g_unsafeScreenHeight
        g_baseUIFilename = "dataS/menu/hud/ui_elements.png"
        g_baseUIPostfix = ""
        g_iconsUIFilename = "dataS/menu/hud/ui_icons.png"
        g_baseHUDFilename = "dataS/menu/hud/hud_elements.png"
        g_controlHUDFilename = "dataS/menu/hud/hud_elements2.png"
        if g_isDevelopmentVersion then
            print(string.format(" Loading UI-textures: \'%s\' \'%s\' \'%s\'", g_baseUIFilename, g_baseHUDFilename, g_iconsUIFilename))
        end
        g_screenAspectRatio = g_screenWidth / g_screenHeight
        g_presentedScreenAspectRatio = getScreenAspectRatio()
        updateAspectRatio(g_screenAspectRatio)
        local safeFrameOffsetX, safeFrameOffsetY = getNormalizedScreenValues(1, 1)
        g_pixelSizeScaledX = safeFrameOffsetX
        g_pixelSizeScaledY = safeFrameOffsetY
        g_colorBgUVs = GuiUtils.getUVs({
            10,
            1010,
            4,
            4
        })
        local safeFrameOffsetX = Platform.safeFrameOffsetX
        local safeFrameOffsetY = Platform.safeFrameOffsetY
        local safeFrameMajorOffsetX, safeFrameMajorOffsetY = getNormalizedScreenValues(safeFrameOffsetX, safeFrameOffsetY)
        g_safeFrameOffsetX = safeFrameMajorOffsetX
        g_safeFrameOffsetY = safeFrameMajorOffsetY
        local safeFramePixels, xOffset = getNormalizedScreenValues(Platform.safeFrameMajorOffsetX, Platform.safeFrameMajorOffsetY)
        g_safeFrameMajorOffsetX = safeFramePixels
        g_safeFrameMajorOffsetY = xOffset
        local xOffset, yOffset = getNormalizedScreenValues(30, 30)
        g_hudAnchorLeft = xOffset
        g_hudAnchorRight = 1 - xOffset
        g_hudAnchorBottom = yOffset
        g_hudAnchorTop = 1 - yOffset
        registerProfileFile("gameSettings.xml")
        registerProfileFile("extraContent.xml")
        g_textWidthScale = 0.95
        setTextWidthScale(g_textWidthScale)
        g_xmlManager:earlyCreateSchemas()
        g_xmlManager:earlyInitSchemas()
        PlayerSystem.loadStyleConfigurationsXML("dataS/character/playerModels.xml")
        updateLoadingBarProgress()
        g_gameSettings = GameSettings.new()
        loadUserSettings(g_gameSettings)
        updateLoadingBarProgress()
        loadLanguageSettings(settingsXML)
        local availableLanguagesString = "Available Languages:"
        for _, lang in ipairs(g_availableLanguagesTable) do
            availableLanguagesString = availableLanguagesString .. " " .. getLanguageCode(lang)
        end
        settingsXML:delete()
        g_gameTitle = "Farming Simulator 25"
        if GS_IS_MOBILE_VERSION then
            g_gameTitle = "Farming Simulator 26"
        end
        CaptionUtil.addText(g_gameTitle)
        if Platform.isPlaystation then
            CaptionUtil.addText("- PlayStation 5")
        elseif Platform.isXbox then
            CaptionUtil.addText("- Xbox Series")
        elseif Platform.isSwitch then
            CaptionUtil.addText("- Switch")
        elseif Platform.isAndroid then
            CaptionUtil.addText("- Android")
        elseif Platform.isIOS then
            CaptionUtil.addText("- iOS")
        end
        if g_isDevelopmentVersion then
            local gameVersionText = g_gameVersionDisplay .. g_gameVersionDisplayExtra .. " (" .. getEngineRevision() .. "/" .. g_gameRevision .. ")"
            CaptionUtil.addText("- DevelopmentVersion " .. gameVersionText .. " - " .. getAppBasePath() .. " - " .. getUserProfileAppPath())
        elseif g_addTestCommands then
            CaptionUtil.addText("- InternalVersion")
        end
        addNotificationFilter(GS_PRODUCT_ID, g_gameVersionNotification)
        updateLoadingBarProgress()
        local gameVersionText = ""
        if g_buildTypeParam ~= "" then
        end
        if GS_IS_STEAM_VERSION then
        end
        if GS_IS_EPIC_VERSION then
        end
        if GS_IS_MSSTORE_VERSION then
        end
        if GS_IS_MAC_APP_STORE_VERSION then
        end
        if isServerStart then
        end
        print(g_gameTitle .. gameVersionText)
        print("  Game-Version: " .. g_gameVersionDisplay .. g_gameVersionDisplayExtra)
        print("  Build-Id: " .. g_buildName)
        print("  Build-Revision: " .. g_gameRevision)
        print("  " .. availableLanguagesString)
        print("  Language: " .. g_languageShort)
        print("  Time: " .. getDate("%Y-%m-%d %H:%M:%S"))
        print("  ModDesc Version: " .. g_maxModDescVersion)
        if Platform.isPC then
            local screenshotsDir = getUserProfileAppPath() .. "screenshots/"
            g_screenshotsDirectory = screenshotsDir
            createFolder(screenshotsDir)
            local modSettingsDir = getUserProfileAppPath() .. "modSettings/"
            g_modSettingsDirectory = modSettingsDir
            createFolder(modSettingsDir)
        end
        g_adsSystem = AdsSystem.new()
        local screenshotsDir = getModInstallPath()
        local modSettingsDir = getModDownloadPath()
        updateLoadingBarProgress()
        if Platform.allowsModDirectoryOverride then
            local _ = nil
            local lang = StartParams.getValue("modsDirectory")
            if string.isNilOrWhitespace(lang) then
                if Utils.getNoNil(getXMLBool(g_savegameXML, "gameSettings.modsDirectoryOverride#active"), false) then
                    _ = getXMLString(g_savegameXML, "gameSettings.modsDirectoryOverride#directory")
                end
            else
                _ = lang
            end
            if not string.isNilOrWhitespace(_) then
                screenshotsDir = string.gsub(_, "\\", "/")
                if screenshotsDir:sub(1, 2) == "//" then
                    screenshotsDir = "\\\\" .. string.sub(screenshotsDir, 3)
                end
                local soundPlayerLocal = string.len(screenshotsDir)
                local soundPlayerTemplate = string.len(screenshotsDir)
                if string.sub(screenshotsDir, soundPlayerLocal, soundPlayerTemplate) ~= "/" then
                end
            end
        end
        updateLoadingBarProgress()
        if screenshotsDir then
            print("  Mod Directory: " .. screenshotsDir)
            createFolder(screenshotsDir)
        end
        if modSettingsDir then
            createFolder(modSettingsDir)
        end
        g_modsDirectory = screenshotsDir
        if g_addTestCommands then
            print("  Testing Commands: Enabled")
        elseif g_addCheatCommands then
            print("  Cheats: Enabled")
        end
        updateLoadingBarProgress()
        g_i18n = I18N.new()
        g_i18n:load()
        if Platform.hasExtraContent then
            g_extraContentSystem = ExtraContentSystem.new()
            g_extraContentSystem:loadFromXML("dataS/extraContent.xml")
            g_extraContentSystem:loadFromProfile()
        end
        updateLoadingBarProgress()
        math.randomseed(getTime())
        math.random()
        math.random()
        math.random()
        updateLoadingBarProgress()
        g_splitShapeManager:load()
        addSplitShapesShaderParameterOverwrite("windSnowLeafScale", 0, 0, 0, 80)
        local _ = XMLFile.load("MapsXML", "dataS/maps.xml")
        _:iterate("maps.map", function(_, key)
            -- upvalues: (copy) _
            g_mapManager:loadMapFromXML(_, key, "", nil, true, true, false)
        end)
        _:delete()
        updateLoadingBarProgress()
        g_animCache = AnimationCache.new()
        g_animCache:load(AnimationCache.CHARACTER, "dataS/character/playerAnimations/animations.i3d")
        updateLoadingBarProgress()
        g_animCache:load(AnimationCache.VEHICLE_CHARACTER, "dataS/character/playerAnimations/animationsVehicleCharacter.i3d")
        if Platform.supportsPedestrians then
            g_animCache:load(AnimationCache.PEDESTRIAN, "dataS/character/playerAnimations/animationsPedestrians.i3d")
        end
        g_achievementManager = AchievementManager.new()
        g_achievementManager:load()
        g_updateables = {}
        updateLoadingBarProgress()
        if g_modsDirectory then
            initModDownloadManager(g_modsDirectory, modSettingsDir, g_minModDescVersion, g_maxModDescVersion, g_isDevelopmentVersion)
            initModDownloadManager = nil
        end
        startUpdatePendingMods()
        updateLoadingBarProgress()
        loadDlcs()
        updateLoadingBarProgress()
        local lang = startFrameRepeatMode()
        while isModUpdateRunning() do
            usleep(16000)
        end
        if lang then
            endFrameRepeatMode()
        end
        if Platform.supportsMods then
            loadAllMods()
        end
        if not Platform.isConsole then
            copyFile(getAppBasePath() .. "VERSION", getUserProfileAppPath() .. "VERSION", true)
        end
        updateLoadingBarProgress()
        g_inputBinding = InputBinding.new(g_modManager, g_messageCenter, GS_IS_CONSOLE_VERSION)
        g_inputBinding:load()
        g_overlayManager = OverlayManager.new()
        g_overlayManager:addTextureConfigFile("dataS/menu/ui_elements.xml", "ui_elements")
        g_overlayManager:addTextureConfigFile("dataS/menu/gui.xml", "gui")
        g_overlayManager:addTextureConfigFile("dataS/menu/hud/mapHotspots.xml", "mapHotspots")
        g_overlayManager:addTextureConfigFile("dataS/menu/helpline/helplineAtlasSmall.xml", HelpLineManager.SLICE_PREFIX)
        g_gui = Gui.new()
        g_gui:loadProfiles("dataS/guiProfiles.xml")
        updateLoadingBarProgress()
        g_inputDisplayManager = InputDisplayManager.new(g_messageCenter, g_inputBinding, g_modManager, GS_IS_CONSOLE_VERSION)
        g_inputDisplayManager:load()
        if Platform.hasTouchInput then
            g_touchHandler = TouchHandler.new()
        end
        simulatePhysics(false)
        if isServerStart then
            local userProfilePath = getUserProfileAppPath()
            g_dedicatedServer = DedicatedServer.new()
            g_dedicatedServer:load(userProfilePath .. "dedicated_server/dedicatedServerConfig.xml", userProfilePath .. "dedicated_server/gameStats.xml")
        end
        updateLoadingBarProgress()
        g_connectionManager = ConnectionManager.new()
        g_masterServerConnection = MasterServerConnection.new()
        g_startMissionInfo = StartMissionInfo.new()
        g_savegameController = SavegameController.new()
        g_inAppPurchaseController = InAppPurchaseController.new()
        g_shopController = ShopController.new()
        g_modHubController = ModHubController.new()
        g_settingsModel = SettingsModel.new()
        updateLoadingBarProgress()
        AchievementsScreen.register()
        if Platform.isMobile then
            MobileSettingsScreen.register()
        end
        g_animalScreen = AnimalScreen.register()
        g_careerScreen = CareerScreen.register()
        if Platform.hasContruction then
            g_constructionScreen = ConstructionScreen.register()
        end
        g_createGameScreen = CreateGameScreen.register()
        updateLoadingBarProgress()
        CreditsScreen.register()
        g_connectToMasterServerScreen = ConnectToMasterServerScreen.register()
        if Platform.needsSignIn then
            g_gamepadSigninScreen = GamepadSigninScreen.register()
        end
        if GS_IS_NETFLIX_VERSION then
            g_netflixSigninScreen = NetflixSigninScreen.register()
        end
        g_joinGameScreen = JoinGameScreen.register()
        g_mainScreen = MainScreen.register()
        updateLoadingBarProgress()
        if Platform.supportsMods then
            g_modHubScreen = ModHubScreen.register()
        end
        g_modSelectionScreen = ModSelectionScreen.register()
        g_newGameScreen = NewGameScreen.register()
        g_mpLoadingScreen = MPLoadingScreen.register()
        g_multiplayerScreen = MultiplayerScreen.register()
        g_serverDetailScreen = ServerDetailScreen.register()
        updateLoadingBarProgress()
        g_settingsScreen = SettingsScreen.register()
        updateLoadingBarProgress()
        g_shopConfigScreen = ShopConfigScreen.register()
        g_shopMenu = ShopMenu.register()
        updateLoadingBarProgress()
        if Platform.showStartupScreen and g_skipStartupScreen == false then
            g_startupScreen = StartupScreen.register()
        end
        if Platform.hasWardrobe then
            g_wardrobeScreen = WardrobeScreen.register()
        end
        g_workshopScreen = WorkshopScreen.register()
        updateLoadingBarProgress()
        g_inGameMenu = InGameMenu.register()
        updateLoadingBarProgress()
        if Platform.hasAnimalTradingDialog then
            AnimalTradingDialog.register()
        end
        ChatDialog.register()
        ColorPickerDialog.register()
        g_connectionFailedDialog = ConnectionFailedDialog.register()
        DenyAcceptDialog.register()
        EditFarmDialog.register()
        updateLoadingBarProgress()
        GameRateDialog.register()
        InfoDialog.register()
        LeaseYesNoDialog.register()
        LicensePlateDialog.register()
        MessageDialog.register()
        ConnectionPendingDialog.register()
        ModHubScreenshotDialog.register()
        ModHubDownloadDialog.register()
        updateLoadingBarProgress()
        OptionDialog.register()
        PasswordDialog.register()
        PlaceableInfoDialog.register()
        RefillDialog.register()
        RiceFieldDialog.register()
        SellItemDialog.register()
        PalletShopDialog.register()
        VehicleShopDialog.register()
        AISettingsDialog.register()
        ESRBUpdateDialog.register()
        MultiOptionDialog.register()
        updateLoadingBarProgress()
        SavegameConflictDialog.register()
        SavegameUploadDialog.register()
        SavegameUploadProgressDialog.register()
        SavegameMigrationDialog.register()
        SavegameMigrationProgressDialog.register()
        SiloDialog.register()
        ObjectStorageDialog.register()
        SleepDialog.register()
        FieldStateDialog.register()
        ToneMappingDialog.register()
        DebugPhysicsCollisionGroupDialog.register()
        DebugDisplacementDialog.register()
        updateLoadingBarProgress()
        TextInputDialog.register()
        if Platform.hasTourDialog then
            TourDialog.register()
        end
        TransferMoneyDialog.register()
        UnBanDialog.register()
        if Platform.supportsMods then
            VoteDialog.register()
        end
        YesNoDialog.register()
        ConversationDialog.register()
        updateLoadingBarProgress()
        if g_kioskMode ~= nil then
            g_kioskMode:initializedGUIClasses()
        end
        updateLoadingBarProgress()
        g_menuMusic = createStreamedSample("menuMusic", true)
        loadStreamedSample(g_menuMusic, "data/music/menu.ogg")
        setStreamedSampleGroup(g_menuMusic, AudioGroup.MENU_MUSIC)
        setStreamedSampleVolume(g_menuMusic, 1)
        g_soundMixer:addVolumeChangedListener(AudioGroup.MENU_MUSIC, function(_, _, volume)
            if g_menuMusicIsPlayingStarted then
                if volume > 0 then
                    resumeStreamedSample(g_menuMusic)
                    return
                end
                pauseStreamedSample(g_menuMusic)
            end
        end, nil)
        if Platform.preShaderContentFiles ~= nil then
            g_preShaderContents = {}
            for _, filename in ipairs(Platform.preShaderContentFiles) do
                local node = g_i3DManager:loadI3DFile(filename, false, false)
                table.insert(g_preShaderContents, {
                    ["step"] = 0,
                    ["node"] = node
                })
            end
            g_preShaderContentStepIndex = 1
            if #g_preShaderContents == 0 then
                g_preShaderContents = nil
            end
        end
        updateLoadingBarProgress(true)
        if g_kioskMode ~= nil then
            g_kioskMode:init()
        end
        if Platform.showStartupScreen and g_skipStartupScreen == false then
            g_gui:showGui("StartupScreen")
        else
            g_gui:showGui("MainScreen")
        end
        g_inputBinding:setShowMouseCursor(true)
        local defaultCamera = getCamera()
        g_cameraManager:addCamera(defaultCamera, nil, true)
        g_cameraManager:setActiveCamera(defaultCamera)
        if g_dedicatedServer == nil then
            local soundPlayerLocal = getAppBasePath() .. "data/music/"
            local soundPlayerTemplate = getAppBasePath() .. "profileTemplate/streamingInternetRadios.xml"
            local _ = getAppBasePath() .. "profileTemplate/ReadmeMusic.txt"
            local filename, node
            if Platform.supportsCustomInternetRadios then
                filename = getUserProfileAppPath() .. "music/"
                createFolder(filename)
                copyFile(soundPlayerTemplate, filename .. "streamingInternetRadios.xml", false)
                copyFile(_, filename .. "ReadmeMusic.txt", false)
            else
                filename = soundPlayerLocal
                node = soundPlayerTemplate
            end
            g_soundPlayer = SoundPlayer.new(getAppBasePath(), "https://www.farming-simulator.com/feed/fs2025-radio-station-feed.xml", node, soundPlayerLocal, filename, g_languageShort, AudioGroup.RADIO)
        end
        RestartManager:init(args)
        if RestartManager.restarting then
            g_gui:showGui("MainScreen")
            RestartManager:handleRestart()
        end
        SystemConsoleCommands.init()
        if g_dedicatedServer ~= nil then
            g_dedicatedServer:start()
        end
        if devStartServer ~= nil then
            startDevServer(devStartServer, devUniqueUserId)
        end
        if devStartClient ~= nil then
            startDevClient(devStartClient, devUniqueUserId)
        end
        if autoStartSavegameId == nil then
            if autoLoadURI ~= nil then
                autoLoadByURI(autoLoadURI)
                return
            end
        elseif StartParams.getIsSet("restart") and not GameLoadingCancelSimulator.ACTIVE then
            Logging.info("Ignored \'autoStartSavegame\' start parameter after game restart")
        else
            autoStartLocalSavegame(autoStartSavegameId)
        end
        if GS_PLATFORM_PC then
            registerGlobalActionEvents(g_inputBinding)
        elseif GS_IS_CONSOLE_VERSION and g_isDevelopmentVersion then
            local soundPlayerLocal, soundPlayerTemplate = g_inputBinding:registerActionEvent(InputAction.CONSOLE_DEBUG_TOGGLE_FPS, nil, toggleShowFPS, false, true, false, true)
            if soundPlayerLocal then
                g_inputBinding:setActionEventTextVisibility(soundPlayerTemplate, false)
            end
            local _, filename = g_inputBinding:registerActionEvent(InputAction.CONSOLE_DEBUG_TOGGLE_STATS, nil, toggleStatsOverlay, false, true, false, true)
            if _ then
                g_inputBinding:setActionEventTextVisibility(filename, false)
            end
        end
        if Platform.supportsMods then
            postInitMods()
        end
        g_logFilePrefixTimestamp = true
        setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
        if StartParams.getIsSet("invitePlatformServerId") then
            g_invitePlatformServerId = StartParams.getValue("invitePlatformServerId")
            local soundPlayerLocal = StartParams.getValue("inviteRequestUserName")
            g_inviteRequestUserName = base64Decode(soundPlayerLocal)
            g_handleInviteRequest = true
        end
        if StartParams.getIsSet("restart") and Platform.needsSignIn then
            if StartParams.getIsSet("autoSignIn") and g_gui.currentGuiName ~= "GamepadSigninScreen" then
                g_autoSignIn = true
            else
                g_gui:showGui("GamepadSigninScreen")
            end
        end
        if Platform.hasAdjustableFrameLimit then
            setFramerateLimiter(true, Platform.defaultFrameLimit)
        end
        Profiler.startProfiler()
        return true
    end
end
function update(dt)
    if Platform.isMobile then
        checkInsets()
    end
    if g_preShaderContents ~= nil then
        local data = g_preShaderContents[g_preShaderContentStepIndex]
        local step = data.step
        data.step = data.step + 1
        if step == 0 then
            link(getRootNode(), data.node)
            setTranslation(g_cameraManager:getActiveCamera(), 0, 0, 5)
            Logging.devInfo("PreShaderContent (%d/%d): render default", g_preShaderContentStepIndex, #g_preShaderContents)
        elseif step == 1 then
            setTranslation(g_cameraManager:getActiveCamera(), 0, 0, 30 * getViewDistanceCoeff() + 2)
            Logging.devInfo("PreShaderContent (%d/%d): render blended", g_preShaderContentStepIndex, #g_preShaderContents)
        elseif step == 2 then
            Logging.devInfo("PreShaderContent (%d/%d): compiling done", g_preShaderContentStepIndex, #g_preShaderContents)
            g_preShaderContentStepIndex = g_preShaderContentStepIndex + 1
        end
        if g_preShaderContentStepIndex > #g_preShaderContents then
            Logging.devInfo("PreShaderContent: finished shader compilation")
            for _, item in ipairs(g_preShaderContents) do
                delete(item.node)
            end
            g_preShaderContents = nil
            setTranslation(g_cameraManager:getActiveCamera(), 0, 0, 0)
        end
    end
    if g_autoSignIn then
        g_autoSignIn = nil
        g_gamepadSigninScreen:signIn()
    end
    if g_handleInviteRequest then
        g_invitePlatformServerId = nil
        g_inviteRequestUserName = nil
        g_handleInviteRequest = nil
        acceptedGameInvite(g_invitePlatformServerId, g_inviteRequestUserName)
    end
    g_time = g_time + dt
    g_currentDt = dt
    g_physicsDt = getPhysicsDt()
    g_physicsDtUnclamped = getPhysicsDtUnclamped()
    g_physicsDtNonInterpolated = getPhysicsDtNonInterpolated()
    if g_physicsDtNonInterpolated > 0 then
        g_physicsDtLastValidNonInterpolated = g_physicsDtNonInterpolated
    end
    g_networkTime = netGetTime()
    g_physicsNetworkTime = g_physicsNetworkTime + g_physicsDtUnclamped
    g_physicsTimeLooped = (g_physicsTimeLooped + g_physicsDt * 10) % 65535
    g_updateLoopIndex = g_updateLoopIndex + 1
    if g_updateLoopIndex > 1073741824 then
        g_updateLoopIndex = 0
    end
    local step = g_physicsDt
    g_physicsDt = math.max(step, 0.001)
    local step = g_physicsDtUnclamped
    g_physicsDtUnclamped = math.max(step, 0.001)
    if g_currentTest == nil then
        setTextWidthScale(g_textWidthScale)
        g_ignitionLockManager:update(dt)
        g_debugManager:update(dt)
        g_lifetimeStats:update(dt)
        g_soundMixer:update(dt)
        g_asyncTaskManager:update(dt)
        g_messageCenter:update(dt)
        Profiler.update(dt)
        if g_nextModRecommendationTime < g_time and (g_currentMission == nil and (g_dedicatedServer == nil and g_modHubController ~= nil)) then
            g_modHubController:updateRecommendationSystem()
            g_nextModRecommendationTime = g_time + 1800000
        end
        g_inputBinding:update(dt)
        for _, updateable in ipairs(g_updateables) do
            updateable:update(dt)
        end
        if g_currentMission ~= nil and (g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen") then
            g_currentMission:preUpdate(dt)
        end
        if Platform.hasFriendInvitation and (g_showDeeplinkingFailedMessage == true and g_gui.currentGuiName ~= "GamepadSigninScreen") then
            g_showDeeplinkingFailedMessage = false
            if GS_PLATFORM_XBOX then
                if PlatformPrivilegeUtil.checkMultiplayer(onShowDeepLinkingErrorMsg, nil, nil, 30000) then
                    onShowDeepLinkingErrorMsg()
                end
            else
                onShowDeepLinkingErrorMsg()
            end
        end
        if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
            g_gui:update(dt)
        end
        if g_currentMission ~= nil and (g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen") then
            g_currentMission:update(dt)
        end
        if g_currentMission ~= nil and (g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen") then
            g_currentMission:postUpdate(dt)
        end
        if g_soundPlayer ~= nil then
            g_soundPlayer:update(dt)
        end
        if g_gui.currentGuiName == "MainScreen" then
            g_achievementManager:update(dt)
        end
        g_soundManager:update(dt)
        if g_kioskMode ~= nil then
            g_kioskMode:update(dt)
        end
        Input.updateFrameEnd()
        if GS_PLATFORM_PC and g_dedicatedServer == nil then
            if getIsUpdateDownloadFinished() then
                g_updateDownloadFinished = true
            end
            if g_updateDownloadFinished and (not g_updateDownloadFinishedDialogShown and (g_gui.currentGuiName == "MainScreen" or g_currentMission ~= nil and g_currentMission.gameStarted)) then
                g_updateDownloadFinishedDialogShown = true
                InfoDialog.show(g_i18n:getText("ui_updateDownloadFinishedText"))
            end
        end
        g_inputBinding:refresh()
        if g_pendingRestartData ~= nil then
            performRestart()
        end
        if g_pendingExit then
            performExit()
        end
    else
        g_currentTest.update(dt)
    end
end
function draw()
    if g_currentTest == nil then
        if g_dedicatedServer == nil then
            g_debugManager:drawPreUI()
            if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
                g_gui:draw()
            end
            if g_currentMission ~= nil and (g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen") then
                g_currentMission:draw()
            end
            if g_inputBinding ~= nil then
                g_inputBinding:draw()
            end
            if g_inputDisplayManager ~= nil then
                g_inputDisplayManager:draw()
            end
            if g_kioskMode ~= nil then
                g_kioskMode:draw()
            end
            if g_isDevelopmentConsoleScriptModTesting then
                renderText(0.2, 0.85, getCorrectTextSize(0.05), "CONSOLE SCRIPTS. DEVELOPMENT USE ONLY")
            end
            g_debugManager:drawPostUI()
            if g_showSafeFrame then
                if g_safeFrameOverlay == nil then
                    g_safeFrameOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
                    setOverlayColor(g_safeFrameOverlay, 1, 0, 0, 0.4)
                end
                renderOverlay(g_safeFrameOverlay, g_safeFrameOffsetX, 0, 1 - 2 * g_safeFrameOffsetX, g_safeFrameOffsetY)
                renderOverlay(g_safeFrameOverlay, g_safeFrameOffsetX, 1 - g_safeFrameOffsetY, 1 - 2 * g_safeFrameOffsetX, g_safeFrameOffsetY)
                renderOverlay(g_safeFrameOverlay, 0, 0, g_safeFrameOffsetX, 1)
                renderOverlay(g_safeFrameOverlay, 1 - g_safeFrameOffsetX, 0, g_safeFrameOffsetX, 1)
                if g_safeFrameMajorOverlay == nil then
                    g_safeFrameMajorOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
                    setOverlayColor(g_safeFrameMajorOverlay, 1, 0, 0, 0.4)
                end
                renderOverlay(g_safeFrameMajorOverlay, g_safeFrameMajorOffsetX, 0, 1 - 2 * g_safeFrameMajorOffsetX, g_safeFrameMajorOffsetY)
                renderOverlay(g_safeFrameMajorOverlay, g_safeFrameMajorOffsetX, 1 - g_safeFrameMajorOffsetY, 1 - 2 * g_safeFrameMajorOffsetX, g_safeFrameMajorOffsetY)
                renderOverlay(g_safeFrameMajorOverlay, 0, 0, g_safeFrameMajorOffsetX, 1)
                renderOverlay(g_safeFrameMajorOverlay, 1 - g_safeFrameMajorOffsetX, 0, g_safeFrameMajorOffsetX, 1)
            end
            if g_drawGuiHelper then
                if g_guiHelperOverlay == nil then
                    g_guiHelperOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
                end
                if g_guiHelperOverlay ~= 0 then
                    setTextColor(1, 1, 1, 1)
                    local width, height = getScreenModeInfo(getScreenMode())
                    local i = g_guiHelperSteps
                    for i = i, 1, g_guiHelperSteps do
                        renderOverlay(g_guiHelperOverlay, i, 0, 1 / width, 1)
                        renderOverlay(g_guiHelperOverlay, 0, i, 1, 1 / height)
                    end
                    local i = 0.05
                    for i = i, 1, 0.05 do
                        renderText(i, 0.97, getCorrectTextSize(0.02), string.format("%.2f", i))
                        renderText(0.01, i, getCorrectTextSize(0.02), string.format("%.2f", i))
                    end
                    local textSize = getCorrectTextSize(0.016)
                    setTextAlignment(RenderText.ALIGN_RIGHT)
                    setTextColor(0, 0, 0, 0.9)
                    renderText(g_lastMousePosX - 0.005, g_lastMousePosY - 0.01 - 0.002, textSize, string.format("y %1.4f", g_lastMousePosY))
                    setTextColor(1, 1, 1, 1)
                    renderText(g_lastMousePosX - 0.005, g_lastMousePosY - 0.01, textSize, string.format("y %1.4f", g_lastMousePosY))
                    setTextAlignment(RenderText.ALIGN_CENTER)
                    setTextColor(0, 0, 0, 0.9)
                    renderText(g_lastMousePosX, g_lastMousePosY + 0.01 - 0.002, textSize, string.format("x %1.4f", g_lastMousePosX))
                    setTextColor(1, 1, 1, 1)
                    renderText(g_lastMousePosX, g_lastMousePosY + 0.01, textSize, string.format("x %1.4f", g_lastMousePosX))
                    setTextAlignment(RenderText.ALIGN_LEFT)
                    local i = 5 / height
                    renderOverlay(g_guiHelperOverlay, g_lastMousePosX - 5 / width, g_lastMousePosY, 2 * (5 / width), 1 / height)
                    renderOverlay(g_guiHelperOverlay, g_lastMousePosX, g_lastMousePosY - i, 1 / width, 2 * i)
                end
            end
            if Platform.requiresConnectedGamepad and (getNumOfGamepads() == 0 and (g_gui.currentGuiName ~= "StartupScreen" and g_gui.currentGuiName ~= "GamepadSigninScreen")) then
                if Platform.isXbox then
                    requestGamepadSignin(Input.BUTTON_2, true, false)
                end
                setTextBold(true)
                setTextAlignment(RenderText.ALIGN_CENTER)
                setTextColor(0, 0, 0, 1)
                local halfCrosshairWidth = getCorrectTextSize(0.05)
                local i = g_i18n:getText("ui_pleaseReconnectController")
                renderText(0.497, 0.6053333333333333, halfCrosshairWidth, i)
                renderText(0.5, 0.6053333333333333, halfCrosshairWidth, i)
                renderText(0.503, 0.6053333333333333, halfCrosshairWidth, i)
                renderText(0.497, 0.6, halfCrosshairWidth, i)
                renderText(0.503, 0.6, halfCrosshairWidth, i)
                renderText(0.497, 0.5946666666666667, halfCrosshairWidth, i)
                renderText(0.5, 0.5946666666666667, halfCrosshairWidth, i)
                renderText(0.503, 0.5946666666666667, halfCrosshairWidth, i)
                setTextColor(1, 1, 1, 1)
                renderText(0.5, 0.6, halfCrosshairWidth, i)
                setTextBold(false)
                setTextColor(1, 1, 1, 1)
                setTextAlignment(RenderText.ALIGN_LEFT)
                drawFilledRect(0, 0, 1, 1, 1, 1, 1, 0.3)
            end
            if g_showRawInput then
                new2DLayer()
                setOverlayColor(GuiElement.debugOverlay, 0, 0, 0, 0.8)
                renderOverlay(GuiElement.debugOverlay, 0, 0, 1, 1)
                setTextAlignment(RenderText.ALIGN_LEFT)
                local width = getNumOfGamepads()
                local height = 0.95
                local textSize = 0
                local i = 0
                local i = 1
                for i = i, width - 1, i do
                    local numButtons = 0
                    local j = 0
                    local numAxes = Input.MAX_NUM_BUTTONS - 1
                    local versionId = 1
                    for j = j, numAxes, versionId do
                        if getHasGamepadButton(Input.BUTTON_1 + j, i) then
                        end
                    end
                    local numAxes = 0
                    local axis = 0
                    local versionId = Input.MAX_NUM_AXES - 1
                    local j = 1
                    for axis = axis, versionId, j do
                        if getHasGamepadAxis(axis, i) then
                        end
                    end
                    local versionId = getGamepadVersionId(i)
                    local j = ""
                    if versionId < 65535 then
                        j = string.format("%04X", versionId)
                    end
                    setTextColor(0.5, 0.5, 0.5, 1)
                    renderText(textSize + 0.025, height, 0.018, "Name:")
                    local height = height - 0.018
                    renderText(textSize + 0.025, height, 0.018, "ProductId:")
                    local height = height - 0.018
                    renderText(textSize + 0.025, height, 0.018, "VendorId:")
                    local height = height - 0.018
                    renderText(textSize + 0.025, height, 0.018, "Version:")
                    local height = height - 0.018
                    renderText(textSize + 0.025, height, 0.018, "Axis / Buttons:")
                    setTextColor(1, 1, 1, 1)
                    renderText(textSize + 0.11, height, 0.018, string.format("%s (#%d)", getGamepadName(i), i))
                    local height = height - 0.018
                    renderText(textSize + 0.11, height, 0.018, string.format("%04X", getGamepadProductId(i)))
                    local height = height - 0.018
                    renderText(textSize + 0.11, height, 0.018, string.format("%04X", getGamepadVendorId(i)))
                    local height = height - 0.018
                    renderText(textSize + 0.11, height, 0.018, string.format("%s", j))
                    local height = height - 0.018
                    renderText(textSize + 0.11, height, 0.018, string.format("%d / %d", numAxes, numButtons))
                    local height = height - 0.035
                    setTextColor(0.5, 0.5, 0.5, 1)
                    renderText(textSize + 0.025, height, 0.018, "Physical")
                    renderText(textSize + 0.07, height, 0.018, "Logical")
                    renderText(textSize + 0.11, height, 0.018, "Ingame")
                    renderText(textSize + 0.165, height, 0.018, "Label")
                    renderText(textSize + 0.2, height, 0.018, "Value")
                    setTextColor(1, 1, 1, 1)
                    local height = height - 0.005
                    local axis = 0
                    for axis = axis, Input.MAX_NUM_AXES - 1 do
                        if getHasGamepadAxis(axis, i) then
                            local physical = getGamepadAxisPhysicalName(axis, i)
                            height = height - 0.016
                            renderText(textSize + 0.025, height, 0.016, string.format("%s", physical))
                            renderText(textSize + 0.07, height, 0.016, string.format("%d", axis))
                            renderText(textSize + 0.11, height, 0.016, string.format("AXIS_%d", axis + 1))
                            renderText(textSize + 0.165, height, 0.016, string.format("%s", getGamepadAxisLabel(axis, i)))
                            renderText(textSize + 0.2, height, 0.016, string.format("%1.2f", getInputAxis(axis, i)))
                        end
                    end
                    local height = height - 0.035
                    setTextColor(0.5, 0.5, 0.5, 1)
                    renderText(textSize + 0.025, height, 0.018, "Physical")
                    renderText(textSize + 0.07, height, 0.018, "Logical")
                    renderText(textSize + 0.11, height, 0.018, "Ingame")
                    renderText(textSize + 0.165, height, 0.018, "Label")
                    setTextColor(1, 1, 1, 1)
                    local height = height - 0.005
                    local axis = 0
                    for axis = axis, Input.MAX_NUM_BUTTONS - 1 do
                        if getInputButton(axis, i) > 0 then
                            local physical = getGamepadButtonPhysicalName(axis, i)
                            height = height - 0.016
                            renderText(textSize + 0.025, height, 0.016, string.format("%s", physical))
                            renderText(textSize + 0.07, height, 0.016, string.format("%d", axis))
                            renderText(textSize + 0.11, height, 0.016, string.format("BUTTON_%d", axis + 1))
                            renderText(textSize + 0.165, height, 0.016, string.format("%s", getGamepadButtonLabel(axis, i)))
                        end
                    end
                    height = height - 0.1
                    if height < 0.05 then
                        height = 0.95
                    end
                end
                if width == 0 then
                    renderText(0.025, height, 0.025, "No gamepads found")
                end
            end
            setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
            setTextAlignment(RenderText.ALIGN_LEFT)
        end
    else
        g_currentTest.draw()
        return
    end
end
function postAnimationUpdate(dt)
    for _, callbackData in pairs(g_postAnimationUpdateCallbacks) do
        callbackData.callbackFunc(callbackData.callbackTarget, dt, callbackData.callbackArguments)
    end
end
function cleanUp()
    if g_safeFrameOverlay ~= nil then
        delete(g_safeFrameOverlay)
    end
    if g_safeFrameMajorOverlay ~= nil then
        delete(g_safeFrameMajorOverlay)
    end
    if g_guiHelperOverlay ~= nil then
        delete(g_guiHelperOverlay)
    end
    if GuiElement.debugOverlay ~= nil then
        delete(GuiElement.debugOverlay)
    end
    deleteDrawingOverlays()
    g_masterServerConnection:disconnectFromMasterServer()
    g_connectionManager:shutdownAll()
    g_inputDisplayManager:delete()
    g_inputBinding:delete()
    g_modHubController:delete()
    g_shopController:delete()
    g_gui:delete()
    g_i18n:delete()
    g_adsSystem:delete()
    g_depthOfFieldManager:delete()
    delete(g_menuMusic)
    delete(g_savegameXML)
    Profiler.delete()
    g_lifetimeStats:save()
    if g_soundPlayer ~= nil then
        g_soundPlayer:delete()
        g_soundPlayer = nil
    end
    if g_soundMixer ~= nil then
        g_soundMixer:delete()
        g_soundMixer = nil
    end
    g_animCache:delete()
    g_i3DManager:clearEntireSharedI3DFileCache(g_isDevelopmentVersion)
    g_soundManager:delete()
    g_cameraManager:delete()
    if g_isDevelopmentVersion or StartParams.getIsSet("scriptDebug") then
        setFileLogPrefixTimestamp(false)
        printActiveEntities()
        print("\nScenegraph:")
        I3DUtil.printChildren(getRootNode())
        setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
    end
    g_messageCenter:delete()
    SystemConsoleCommands.delete()
end
function doExit()
    g_pendingExit = true
end
function performExit()
    g_pendingExit = false
    OnInGameMenuMenu()
    cleanUp()
    print("Application quit")
    requestExit()
end
function doRestart(restartProcess, args)
    if g_invitePlatformServerId ~= nil then
        local userName = base64Encode(g_inviteRequestUserName)
    end
    g_pendingRestartData = {
        ["restartProcess"] = restartProcess,
        ["args"] = args
    }
end
function checkInsets()
    local left, right, top, bottom = getSafeFrameInsets()
    if g_insetLeft == nil then
        g_insetLeft = left
        g_insetRight = right
        g_insetTop = top
        g_insetBottom = bottom
    end
    if left ~= g_insetLeft or (right ~= g_insetRight or (top ~= g_insetTop or bottom ~= g_insetBottom)) then
        g_insetLeft = left
        g_insetRight = right
        g_insetTop = top
        g_insetBottom = bottom
        g_messageCenter:publish(MessageType.INSETS_CHANGED)
    end
end
function performRestart()
    if g_pendingRestartData ~= nil then
        local data = g_pendingRestartData
        if Platform.needsSignIn and (g_isSignedIn and getStartMode() ~= RestartManager.START_SCREEN_GAMEPAD_SIGNIN) then
            data.args = data.args .. " -autoSignIn"
        end
        cleanUp()
        print("Application restart " .. (not data.restartProcess and "(soft restart)" or ""))
        restartApplication(data.restartProcess, data.args)
    end
end
function loadLanguageSettings(xmlFile)
    local numLanguages = getNumOfLanguages()
    local languageCodeToLanguage = {}
    local i = 0
    local language = numLanguages - 1
    local languageSet = 1
    for i = i, language, languageSet do
        languageCodeToLanguage[getLanguageCode(i)] = i
    end
    local language = getLanguage()
    local languageSet = false
    local i = {}
    xmlFile:iterate("settings.languages.language", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) languageCodeToLanguage, (copy) language, (ref) languageSet, (copy) i
        local code = xmlFile:getString(key .. "#code")
        local languageShort = xmlFile:getString(key .. "#short")
        local languageSuffix = xmlFile:getString(key .. "#suffix")
        local lang = languageCodeToLanguage[code]
        if lang ~= nil then
            if lang == language or not languageSet then
                languageSet = true
                g_language = lang
                g_languageShort = languageShort
                g_languageSuffix = languageSuffix
            end
            if getIsLanguageEnabled(lang) then
                i[lang] = true
            end
        end
    end)
    g_availableLanguagesTable = {}
    g_availableLanguageNamesTable = {}
    local i = 0
    for i = i, numLanguages - 1 do
        if i[i] or i == g_language then
            table.insert(g_availableLanguagesTable, i)
            if getLanguageNativeName == nil then
                table.insert(g_availableLanguageNamesTable, getLanguageName(i))
            else
                table.insert(g_availableLanguageNamesTable, getLanguageNativeName(i))
            end
            if i == g_language then
                g_settingsLanguageGUI = #g_availableLanguagesTable - 1
            end
        end
    end
    if GS_IS_CONSOLE_VERSION then
        g_gameSettings:setValue(GameSettings.SETTING.MP_LANGUAGE, getSystemLanguage())
    end
end
function loadUserSettings(gameSettings)
    gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, (getUserName():trim() == nil or getUserName():trim() == "") and "Player" or getUserName():trim())
    gameSettings:setValue(GameSettings.SETTING.VOLUME_MASTER, getMasterVolume())
    gameSettings:setValue("joystickVibrationEnabled", getGamepadVibrationEnabled())
    if g_savegameXML ~= nil then
        delete(g_savegameXML)
    end
    local gameSettingsPathTemplate = getAppBasePath() .. "profileTemplate/gameSettingsTemplate.xml"
    g_savegamePath = getUserProfileAppPath() .. "gameSettings.xml"
    copyFile(gameSettingsPathTemplate, g_savegamePath, false)
    g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)
    if g_savegameXML == nil or g_savegameXML == 0 then
        Logging.error("Detected corrupt gameSettings.xml. Restoring default file!")
        copyFile(gameSettingsPathTemplate, g_savegamePath, true)
        g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)
    end
    syncProfileFiles()
    local revision = getXMLInt(g_savegameXML, "gameSettings#revision")
    local gameSettingsTemplate = loadXMLFile("GameSettingsTemplate", gameSettingsPathTemplate)
    local revisionTemplate = getXMLInt(gameSettingsTemplate, "gameSettings#revision")
    delete(gameSettingsTemplate)
    if revision == nil or revision ~= revisionTemplate then
        copyFile(gameSettingsPathTemplate, g_savegamePath, true)
        delete(g_savegameXML)
        g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)
    end
    gameSettings:setDefault()
    gameSettings:loadFromXML(g_savegameXML)
    if g_settingsModel ~= nil then
        g_settingsModel:refresh()
    end
    g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_RADIO))
    g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VEHICLE))
    g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.MENU_MUSIC, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_MUSIC))
    g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))
    g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_GUI))
    g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.CHARACTER, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_CHARACTER))
    g_soundMixer:setMasterVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_MASTER))
    g_soundMixer:immediateUpdate()
    VoiceChatUtil.setOutputVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VOICE))
    VoiceChatUtil.setInputVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VOICE_INPUT))
    VoiceChatUtil.setInputMode(g_gameSettings:getValue(GameSettings.SETTING.VOICE_MODE))
    g_lifetimeStats:reload()
    if g_extraContentSystem ~= nil then
        g_extraContentSystem:reset()
        g_extraContentSystem:loadFromProfile()
    end
end
function takeScreenshot()
    if g_screenshotsDirectory == nil then
        printError("Error: Screenshot directory not defined!")
    else
        local screenshotName = g_screenshotsDirectory .. "fsScreen_" .. getDate("%Y_%m_%d_%H_%M_%S") .. ".png"
        print("Saving screenshot: " .. screenshotName)
        if not saveScreenshot(screenshotName) then
            printError(string.format("Error while saving screenshot \'%s\'", screenshotName))
        end
    end
end
function registerGlobalActionEvents(inputManager)
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.TAKE_SCREENSHOT, nil, takeScreenshot, false, true, false, true)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    if g_addTestCommands and Platform.isPC then
        g_noteManager:registerInputActionEvent()
    end
    if g_kioskMode ~= nil then
        g_kioskMode:registerGlobalInputActionEvents()
    end
end
function updateAspectRatio(aspect)
    local referenceAspect = g_referenceScreenWidth / g_referenceScreenHeight
    if referenceAspect < aspect then
        g_aspectScaleX = referenceAspect / aspect
        g_aspectScaleY = 1
    else
        g_aspectScaleX = 1
        g_aspectScaleY = aspect / referenceAspect
    end
    g_aspectScaleX = g_aspectScaleX * g_safeFrameRatioX
    g_aspectScaleY = g_aspectScaleY * g_safeFrameRatioY
end
g_postAnimationUpdateCallbacks = {}
function addPostAnimationCallback(callbackFunc, callbackTarget, callbackArguments)
    local callbackData = {
        ["callbackFunc"] = callbackFunc,
        ["callbackTarget"] = callbackTarget,
        ["callbackArguments"] = callbackArguments
    }
    table.insert(g_postAnimationUpdateCallbacks, callbackData)
    return callbackData
end
function removePostAnimationCallback(callbackDataToRemove)
    for i, callbackData in pairs(g_postAnimationUpdateCallbacks) do
        if callbackData == callbackDataToRemove then
            table.remove(g_postAnimationUpdateCallbacks, i)
        end
    end
end
function addGlobalUpdateable(updateable)
    table.addElement(g_updateables, updateable)
end
function removeGlobalUpdateable(updateable)
    table.removeElement(g_updateables, updateable)
end
function updateLoadingBarProgress(isLast)
    g_curNumLoadingBarStep = g_curNumLoadingBarStep + 1
    local ratio = g_curNumLoadingBarStep / g_maxNumLoadingBarSteps
    if isLast and ratio < 1 or ratio > 1 then
        printError("Error: Invalid g_maxNumLoadingBarSteps. Last step number is " .. g_curNumLoadingBarStep)
    end
    updateLoadingBar(ratio)
end
function onShowDeepLinkingErrorMsg()
    g_deepLinkingInfo = nil
    ConnectionFailedDialog.show(g_i18n:getText("ui_failedToConnectToGame"), OnInGameMenuMenu)
    g_showDeeplinkingFailedMessage = false
end
function startDevServer(savegameId, _)
    if StartParams.getIsSet("restart") then
        print("Skipping server auto start due to restart")
        return
    else
        g_savegameController:updateSavegames()
        g_savegameController:loadSavegames()
        print("Start developer mp server (Savegame-Id: " .. tostring(savegameId) .. ")")
        g_mainScreen:onMultiplayerClick()
        g_multiplayerScreen:onClickCreateGame()
        local savegame = g_savegameController:getSavegame((tonumber(savegameId)))
        if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
            printWarning("    Savegame not found! Please select savegame manually!")
        else
            g_careerScreen.savegameList.selectedIndex = tonumber(savegameId)
            g_careerScreen:onStartAction()
            if g_gui.currentGuiName == "ModSelectionScreen" then
                g_modSelectionScreen:onClickOk()
            end
            g_autoDevMP = {
                ["serverName"] = "InternalTest_" .. getUserName()
            }
            g_createGameScreen.serverNameElement:setText(g_autoDevMP.serverName)
            g_createGameScreen.autoAccept = true
            g_createGameScreen:onClickOk()
        end
    end
end
function startDevClient(serverName, _)
    if StartParams.getIsSet("restart") then
        print("Skipping client auto join due to restart")
    else
        print("Start developer mp client")
        g_mainScreen:onMultiplayerClick()
        if serverName == nil or serverName == "" then
            serverName = "InternalTest_" .. getUserName()
        end
        g_autoDevMP = {
            ["serverName"] = serverName
        }
        g_multiplayerScreen:onClickJoinGame()
    end
end
function autoStartLocalSavegame(savegameId)
    print("Auto start local savegame (Id: " .. tostring(savegameId) .. ")")
    g_gui:setIsMultiplayer(false)
    g_gui:showGui("CareerScreen")
    g_careerScreen:setSelectedSavegameIndex((tonumber(savegameId)))
    local savegame = g_savegameController:getSavegame((tonumber(savegameId)))
    if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
        printWarning("    Savegame not found! Please select savegame manually!")
    else
        g_careerScreen.currentSavegame = savegame
        g_careerScreen:onStartAction()
        if g_gui.currentGuiName == "ModSelectionScreen" then
            g_modSelectionScreen:onClickOk()
        end
    end
end
function autoLoadByURI(uri)
    local uriComponents = string.split(uri, ":")
    local uriParamStrings = string.split(uriComponents[2], "&")
    local uriParams = {}
    for i, v in ipairs(uriParamStrings) do
        local keyValues = string.split(v, "=")
        uriParams[keyValues[1]] = keyValues[2]
    end
    if uriParams.map == nil then
        printError("Error: URI Parameter \'map\' not set! Cannot auto load from URI.")
    else
        local i = tonumber(uriParams.savegameIndex) or 1
        AutoLoadParams.enable = true
        AutoLoadParams.x = tonumber(uriParams.x)
        AutoLoadParams.z = tonumber(uriParams.z)
        g_gui:setIsMultiplayer(false)
        g_gui:showGui("CareerScreen")
        g_savegameController:deleteSavegame(i)
        g_careerScreen:setSelectedSavegameIndex(i)
        local v = g_savegameController:getSavegame(i)
        g_careerScreen.currentSavegame = v
        g_startMissionInfo.mapId = uriParams.map
        g_startMissionInfo.canStart = true
        g_careerScreen:startSavegame(v)
        g_gui:changeScreen(nil, CareerScreen)
        if g_gui.currentGuiName == "ModSelectionScreen" then
            g_modSelectionScreen:onClickOk()
        end
    end
end
function connectToServer(platformServerId)
    if storeHaveDlcsChanged() or (haveModsChanged() or g_forceNeedsDlcsAndModsReload) then
        g_forceNeedsDlcsAndModsReload = false
        reloadDlcsAndMods()
    end
    if storeAreDlcsCorrupted() then
        InfoDialog.show(g_i18n:getText("ui_dlcsCorruptRedownload"), g_mainScreen.onDlcCorruptClick, g_mainScreen)
    else
        g_deepLinkingInfo = {}
        g_deepLinkingInfo.platformServerId = platformServerId
        g_masterServerConnection:disconnectFromMasterServer()
        g_connectionManager:shutdownAll()
        g_gui:changeScreen(nil, CareerScreen)
        g_mainScreen:onMultiplayerClick()
        g_multiplayerScreen:onClickJoinGame()
    end
end
function startMenuMusic()
    if not g_menuMusicIsPlayingStarted then
        g_menuMusicIsPlayingStarted = true
        playStreamedSample(g_menuMusic, 0)
        if g_soundMixer:getAudioGroupVolume(AudioGroup.MENU_MUSIC) == 0 then
            pauseStreamedSample(g_menuMusic)
        end
    end
end