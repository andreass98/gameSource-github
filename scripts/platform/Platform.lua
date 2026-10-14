Platform = {}
function Platform.init()
    local self = Platform
    self.id = getPlatformId()
    self.gameplay = {}
    self.ingameMap = {}
    self.settings = {}
    self.ui = {}
    self.blockedKeyboardCombos = {}
    self.lockedInputActionNames = {}
    self.playerInfo = {}
    Platform.applyDefault()
    if GS_PLATFORM_XBOX then
        Platform.applyConsole()
        Platform.applyXbox()
    elseif GS_PLATFORM_PLAYSTATION then
        Platform.applyConsole()
        Platform.applyPlaystation()
    elseif GS_PLATFORM_SWITCH2 then
        Platform.applyConsole()
        Platform.applySwitch2()
    elseif GS_PLATFORM_SWITCH then
        Platform.applyMobile()
        Platform.applySwitch()
    elseif GS_PLATFORM_ID == PlatformId.IOS then
        Platform.applyMobile()
        Platform.applyIOS()
        if GS_IS_NETFLIX_VERSION then
            Platform.applyNetflix()
        end
    elseif GS_PLATFORM_ID == PlatformId.ANDROID then
        Platform.applyMobile()
        Platform.applyAndroid()
        if GS_IS_NETFLIX_VERSION then
            Platform.applyNetflix()
        end
    elseif GS_IS_MSSTORE_VERSION then
        Platform.applyMSStore()
    end
    if GS_IS_STEAM_VERSION then
        Platform.applySteam()
    end
end
function Platform.applyDefault()
    print("Platform: loading defaults")
    local self = Platform
    self.isPC = GS_PLATFORM_PC
    self.isSteam = GS_IS_STEAM_VERSION
    self.checkGPUDriver = true
    self.showVideoGIANTS = true
    self.showVideoFS = true
    self.showStartupScreen = true
    self.showGamerTagInMainScreen = false
    self.canChangeGamerTag = true
    self.canChangeControls = true
    self.showRentServerWebButton = true
    self.hasFriendInvitation = false
    self.hasFriendFilter = false
    self.hasNativeProfiles = false
    self.hasNetworkSettings = true
    self.hasExtraContent = true
    self.hasWardrobe = true
    self.hasMapSelection = true
    self.hasModHub = true
    self.hasConfigScreen = true
    self.hasOnlineAchievements = true
    self.autoStartAfterLoad = false
    self.hasContruction = true
    self.hasIngameMenuGameFrame = false
    self.hasAnimalTradingDialog = false
    self.hasRecordingDeviceDetection = false
    self.hasTourDialog = false
    self.hasDifficulty = true
    self.hasAdjustableFrameLimit = true
    self.supportsRealBeaconLights = true
    self.canChangeLanguage = true
    self.allowSavegameMigration = false
    self.allowRestartOnSettingsChange = true
    self.frameLimits = {
        30,
        60,
        90,
        120,
        144,
        240
    }
    self.defaultUIScale = 1
    self.defaultFrameLimit = 60
    self.guiPrefixes = {}
    self.l10nPostfixes = {}
    self.gameLogos = {
        ["en"] = "dataS/menu/main_logo_en.png"
    }
    self.supportsMods = true
    self.allowsScriptMods = true
    self.allowsModDirectoryOverride = self.isPC
    self.hasSlotLimitation = true
    self.supportsCustomInternetRadios = self.isPC
    self.hasLimitedModSpace = false
    self.autoSelectDLCs = false
    self.verboseDLCLoading = false
    self.allowCrossPlatformSavegames = true
    self.supportsPushToTalk = true
    self.hasTextChat = true
    self.hasAudioChat = false
    self.hasPlayer = true
    self.allowPlayerPickUp = true
    self.supportsPedestrians = true
    self.supportsFoliageBending = true
    self.canQuitApplication = true
    self.supportsMultiplayer = true
    self.hasMainScreenLanguageSelection = false
    self.hasCloudSyncSetting = false
    self.hasGrassFilterEnabledByDefault = false
    self.supportsSavegameDebugUpload = true
    self.supportsSavegameDebugDownload = true
    self.supportsGameRating = false
    self.gameRatingEnabled = false
    self.showGamepadModeDialog = true
    self.showHeadTrackingDialog = true
    self.urlBuyNow = "buy-now.php"
    self.urlEshop = "lp/fs25-go-to-eshop.php"
    self.urlUpdate = "updates.php"
    self.urlUpdateGPUDriver = "gpuDriverDownload.php"
    self.urlDedicatedServer = "fs25-rent-a-dedicated-server.php"
    self.urlRating = "lp/fs25-rating.php"
    self.hasHints = false
    self.hasInGameMenuMainPage = false
    self.safeFrameOffsetX = 25
    self.safeFrameOffsetY = 25
    self.lowResCollisionHandlerGridSize = 64
    self.lowResCollisionHandlerCellRaysPerFrame = 16
    self.safeFrameMajorOffsetX = 25
    self.safeFrameMajorOffsetY = 25
    self.minFovY = g_fovYMin
    self.maxFovY = g_fovYMax
    self.maxNumMirrors = 3
    self.forcedUIResolution = nil
    self.usesFixedExposure = false
    self.hasShallowWaterSimulation = true
    self.verifyMultiplayerAvailabilityInMenu = Platform.verifyMultiplayerAvailabilityInMenu
    self.ui.drawHudOnDialog = false
    self.preShaderContentFiles = nil
    self.settings.canManageInputDevices = true
    self.settings.canManageInputBindings = true
    self.settings.canManageDisplaySettings = true
    self.gameplay.hasLoans = true
    self.gameplay.hasVehicleSales = true
    self.gameplay.hasMissions = true
    self.gameplay.defaultTimeScale = 5
    self.gameplay.timeScaleSettings = {
        0.5,
        1,
        2,
        3,
        5,
        6,
        10,
        15,
        30,
        60,
        120,
        240,
        360
    }
    self.gameplay.timeScaleDevSettings = { 2000, 12000, 60000 }
    self.gameplay.canSellFromMenu = true
    self.gameplay.sprayLevelMaxValue = 2
    self.gameplay.harvestScaleRation = {
        0.45,
        0.15,
        0.15,
        0.2,
        0.025,
        0.025
    }
    self.gameplay.useSprayDiffuseMaps = true
    self.gameplay.useMultipleSprayLevels = true
    self.gameplay.usePlowCounter = true
    self.gameplay.useLimeCounter = true
    self.gameplay.useStubbleShred = true
    self.gameplay.useRolling = true
    self.gameplay.ingameMapFruitsPerPage = 15
    self.gameplay.supportsWithering = true
    self.gameplay.maxNumHirables = math.huge
    self.gameplay.canVisitPOI = true
    self.gameplay.supportSeasonalGrowth = true
    self.gameplay.supportSnow = true
    self.gameplay.autoActivateTrigger = false
    self.gameplay.canCreateFields = true
    self.gameplay.treeCutFarmlandRestrictions = true
    self.gameplay.hasDynamicPallets = true
    self.gameplay.hasVehicleConfigs = true
    self.gameplay.hasWeeder = true
    self.gameplay.supportsTwister = true
    self.gameplay.automaticDischarge = false
    self.gameplay.automaticFilling = false
    self.gameplay.automaticAttach = false
    self.gameplay.automaticBaleDrop = false
    self.gameplay.automaticLights = false
    self.gameplay.automaticPipeUnfolding = false
    self.gameplay.automaticVehicleControl = false
    self.gameplay.keepFoldingWhileDetached = false
    self.gameplay.foldAfterAIFinished = false
    self.gameplay.lightsProfile = nil
    self.gameplay.useWorldCameraInside = true
    self.gameplay.useWorldCameraOutside = true
    self.gameplay.hasShadowFocusBox = true
    self.gameplay.hasVehicleCharacterIdleAnimations = true
    self.gameplay.allowVehicleCharacterIKDirtyUpdate = true
    self.gameplay.hasDetachedPowerTakeOffs = true
    self.gameplay.hasTMRMixing = true
    self.gameplay.dischargeSpeedFactor = 1
    self.gameplay.maxCameraZoomFactor = 1
    self.gameplay.dirtDurationScale = 1
    self.gameplay.hasVehicleDamage = true
    self.gameplay.allowSuspensionNodes = true
    self.gameplay.allowTestAreas = true
    self.gameplay.allowAutomaticHeaderTilt = true
    self.gameplay.hasBaleFermentation = true
    self.gameplay.steeringBackSpeedSettings = {
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10
    }
    self.gameplay.disabledShopSpecValues = {}
    self.gameplay.wheelTerrainDisplacement = true
    self.gameplay.wheelDensityHeightSmooth = true
    self.gameplay.wheelVisualPressure = true
    self.gameplay.wheelVisualPressureUpdateThreshold = 0.0003
    self.gameplay.wheelTireTracks = true
    self.gameplay.defaultFruitDestruction = true
    self.gameplay.defaultGyroscopeSteering = false
    self.gameplay.defaultCameraTilt = false
    self.gameplay.needHorseCleaning = true
    self.gameplay.canRenameHorses = true
    self.ingameMap.canZoom = true
    self.ingameMap.needsSolidBackground = true
    self.ingameMap.sortsSpatially = false
    self.ingameMap.zoomDefault = 2
    self.ingameMap.zoomSpeedFactor = 0.1
    self.ingameMap.dragStartDistance = 2
    self.ingameMap.taggedHotspotsArePersistent = true
    self.ingameMap.resetZoomOnOpen = true
    self.playerInfo.showVehicleInfo = true
    self.playerInfo.showPlaceableInfo = true
    self.playerInfo.showNPCNames = true
    self.playerInfo.fieldInfoDistance = { 5, 5 }
end
function Platform.applyConsole()
    print("Platform: loading console")
    local self = Platform
    self.isConsole = true
    self.checkGPUDriver = false
    self.allowsScriptMods = false
    self.allowsModDirectoryOverride = false
    self.hasSlotLimitation = true
    self.canChangeGamerTag = false
    self.canChangeControls = false
    self.hasLimitedModSpace = true
    self.showRentServerWebButton = false
    self.hasFriendInvitation = true
    self.hasFriendFilter = true
    self.hasNativeProfiles = true
    self.hasNetworkSettings = false
    self.hasAdjustableFrameLimit = false
    self.canChangeLanguage = false
    self.verboseDLCLoading = true
    self.allowRestartOnSettingsChange = false
    self.supportsPushToTalk = false
    self.supportsSavegameDebugUpload = true
    self.hasTextChat = false
    self.hasAudioChat = true
    self.canQuitApplication = false
    self.hasNativeStore = true
    self.requiresConnectedGamepad = true
    self.showGamepadModeDialog = false
    self.showHeadTrackingDialog = false
    self.safeFrameOffsetX = 40
    self.safeFrameOffsetY = 40
    self.safeFrameMajorOffsetX = 96
    self.safeFrameMajorOffsetY = 54
    self.forcedUIResolution = 1080
    self.gameplay.maxNumHirables = 6
    self.settings.canManageInputDevices = false
    self.settings.canManageInputBindings = false
    self.settings.canManageDisplaySettings = false
    self.settings.simplified = true
    self.maxFovY = 1.5707963267948966
    self.maxNumMirrors = 0
    local files = Files.new("data/shaders/").files
    for _, file in ipairs(files) do
        addReplacedCustomShader(file.filename, "data/shaders/" .. file.filename)
    end
end
function Platform.applyXbox()
    print("Platform: loading Xbox")
    local self = Platform
    self.isXbox = true
    self.needsSignIn = true
    self.showGamerTagInMainScreen = true
    self.maxNumMirrors = 3
    table.insert(self.guiPrefixes, "xbox_")
    table.insert(self.l10nPostfixes, "_xboxseries")
    table.insert(self.l10nPostfixes, "_xbox")
end
function Platform.applyPlaystation()
    print("Platform: loading Playstation")
    local self = Platform
    self.isPlaystation = true
    self.maxNumMirrors = 5
    table.insert(self.guiPrefixes, "ps_")
    table.insert(self.l10nPostfixes, "_ps5")
    table.insert(self.l10nPostfixes, "_ps")
end
function Platform.applyMobile()
    print("Platform: loading mobile")
    local self = Platform
    self.isMobile = true
    self.frameLimits = { 30 }
    self.defaultFrameLimit = 30
    self.lowResCollisionHandlerGridSize = 32
    self.lowResCollisionHandlerCellRaysPerFrame = 4
    self.checkGPUDriver = false
    self.showStartupScreen = false
    self.hasMainScreenLanguageSelection = true
    self.hasCloudSyncSetting = true
    self.hasGrassFilterEnabledByDefault = true
    self.supportsSavegameDebugUpload = true
    self.hasHDRSettings = false
    self.showGamepadModeDialog = false
    self.showHeadTrackingDialog = false
    self.supportsRealBeaconLights = false
    self.canChangeLanguage = false
    self.hasTouchInput = true
    self.supportsMods = false
    self.allowsScriptMods = self.supportsMods
    self.supportsPedestrians = false
    self.supportsFoliageBending = false
    self.hasExtraContent = false
    self.hasWardrobe = false
    self.hasMapSelection = true
    self.hasConfigScreen = false
    self.autoStartAfterLoad = true
    self.hasContruction = false
    self.hasIngameMenuGameFrame = true
    self.hasAnimalTradingDialog = true
    self.hasTourDialog = true
    self.hasDifficulty = false
    self.hasTouchSliders = true
    self.hasModHub = false
    self.canQuitApplication = false
    self.supportsMultiplayer = false
    self.hasHints = true
    self.hasInGameMenuMainPage = true
    self.hasPlayer = true
    self.allowPlayerPickUp = false
    self.safeFrameOffsetX = 50
    self.safeFrameOffsetY = 50
    self.forcedUIResolution = 1080
    self.urlRating = "lp/fs23-rating.php"
    self.settings.simplified = false
    self.settings.canManageInputDevices = false
    self.settings.canManageInputBindings = false
    self.settings.canManageDisplaySettings = false
    self.gameLogos = {
        ["en"] = "dataS/menu/main_logo_mobile_en.png",
        ["de"] = "dataS/menu/main_logo_mobile_de.png"
    }
    self.usesFixedExposure = true
    self.preShaderContentFiles = {
        "data/preShaderContent/map_part1.i3d",
        "data/preShaderContent/map_part2.i3d",
        "data/preShaderContent/map_part3.i3d",
        "data/preShaderContent/map_part4.i3d",
        "data/preShaderContent/map_part5.i3d",
        "data/preShaderContent/vehicle_part1.i3d",
        "data/preShaderContent/vehicle_part2.i3d",
        "data/preShaderContent/vehicle_part3.i3d",
        "data/preShaderContent/vehicle_part4.i3d",
        "data/preShaderContent/vehicle_part5.i3d"
    }
    self.gameplay.defaultTimeScale = 60
    self.gameplay.timeScaleSettings = {
        1,
        2,
        5,
        10,
        30,
        45,
        60,
        90
    }
    self.gameplay.hasShortNights = true
    self.gameplay.hasLoans = false
    self.gameplay.hasVehicleSales = false
    self.gameplay.sprayLevelMaxValue = 1
    self.gameplay.harvestScaleRation = {
        0.6,
        0.2,
        0,
        0.2,
        0,
        0
    }
    self.gameplay.useSprayDiffuseMaps = false
    self.gameplay.useMultipleSprayLevels = false
    self.gameplay.usePlowCounter = true
    self.gameplay.defaultPlowingRequiredEnabled = true
    self.gameplay.useLimeCounter = false
    self.gameplay.useStubbleShred = false
    self.gameplay.useRolling = false
    self.gameplay.ingameMapFruitsPerPage = math.huge
    self.gameplay.supportsWithering = false
    self.gameplay.maxNumHirables = 6
    self.gameplay.canVisitPOI = false
    self.gameplay.supportSeasonalGrowth = false
    self.gameplay.supportSnow = false
    self.gameplay.automaticDischarge = true
    self.gameplay.automaticFilling = false
    self.gameplay.automaticAttach = true
    self.gameplay.automaticBaleDrop = true
    self.gameplay.automaticLights = true
    self.gameplay.automaticPipeUnfolding = true
    self.gameplay.automaticVehicleControl = true
    self.gameplay.keepFoldingWhileDetached = true
    self.gameplay.foldAfterAIFinished = true
    self.gameplay.lightsProfile = GS_PROFILE_LOW
    self.gameplay.useWorldCameraInside = false
    self.gameplay.useWorldCameraOutside = true
    self.gameplay.hasShadowFocusBox = false
    self.gameplay.hasVehicleCharacterIdleAnimations = false
    self.gameplay.allowVehicleCharacterIKDirtyUpdate = false
    self.gameplay.hasDetachedPowerTakeOffs = false
    self.gameplay.hasTMRMixing = false
    self.gameplay.dischargeSpeedFactor = 2
    self.gameplay.maxCameraZoomFactor = 0.6
    self.gameplay.dirtDurationScale = 2
    self.gameplay.hasVehicleDamage = false
    self.gameplay.allowSuspensionNodes = false
    self.gameplay.allowTestAreas = false
    self.gameplay.allowAutomaticHeaderTilt = false
    self.gameplay.hasBaleFermentation = false
    self.gameplay.steeringBackSpeedSettings = { 5, 7.5, 10 }
    self.gameplay.canCreateFields = false
    self.gameplay.treeCutFarmlandRestrictions = false
    self.gameplay.hasDynamicPallets = false
    self.gameplay.hasVehicleConfigs = false
    self.gameplay.hasWeeder = false
    self.gameplay.needHorseCleaning = false
    self.gameplay.canRenameHorses = false
    self.gameplay.disabledShopSpecValues = {
        ["balerBaleSizeRound"] = true,
        ["balerBaleSizeSquare"] = true,
        ["baleWrapperBaleSizeRound"] = true,
        ["baleWrapperBaleSizeSquare"] = true,
        ["baleLoaderBaleSizeRound"] = true,
        ["baleLoaderBaleSizeSquare"] = true,
        ["transmission"] = true,
        ["woodHarvesterMaxTreeSize"] = true
    }
    self.ui.drawHudOnDialog = true
    self.gameplay.wheelDensityHeightSmooth = false
    self.gameplay.wheelVisualPressure = true
    self.gameplay.wheelVisualPressureUpdateThreshold = 0.0025
    self.gameplay.wheelTireTracks = false
    self.gameplay.defaultFruitDestruction = false
    self.ingameMap.canZoom = true
    self.ingameMap.needsSolidBackground = false
    self.ingameMap.sortsSpatially = true
    self.ingameMap.zoomDefault = 1
    self.ingameMap.zoomSpeedFactor = 0.07
    self.ingameMap.dragStartDistance = 3
    self.ingameMap.taggedHotspotsArePersistent = false
    self.ingameMap.resetZoomOnOpen = false
    self.playerInfo.showVehicleInfo = false
    self.playerInfo.showPlaceableInfo = false
    self.playerInfo.showNPCNames = false
    self.playerInfo.fieldInfoDistance = { 1, 1 }
    table.insert(self.l10nPostfixes, "_mobile")
end
function Platform.applySwitch2()
    print("Platform: loading Switch 2")
    local self = Platform
    self.isSwitch2 = true
    self.canQuitApplication = false
    self.supportsMultiplayer = false
    self.requiresConnectedGamepad = false
    self.supportsMods = true
    self.hasNativeStore = false
    self.showGamepadModeDialog = false
    self.showHeadTrackingDialog = false
    self.autoSelectDLCs = true
    self.hasTouchInput = true
    self.hasOnlineAchievements = false
    self.maxNumMirrors = 0
    self.canChangeLanguage = true
    self.showVideoFS = false
    self.defaultUIScale = 1.25
    self.gameplay.supportsTwister = false
    self.allowRestartOnSettingsChange = true
    table.insert(self.guiPrefixes, "switch2_")
    table.insert(self.guiPrefixes, "switch_")
    table.insert(self.l10nPostfixes, "_switch2")
    table.insert(self.l10nPostfixes, "_switch")
    self.gameLogos = {
        ["en"] = "dataS/menu/main_logo_signatureEdition_en.png",
        ["de"] = "dataS/menu/main_logo_signatureEdition_de.png"
    }
end
function Platform.applySwitch()
    print("Platform: loading Switch")
    local self = Platform
    self.isSwitch = true
    self.showStartupScreen = true
    self.showVideoFS = false
    self.hasTouchSliders = false
    self.hasCloudSyncSetting = false
    self.preShaderContentFiles = nil
    table.insert(self.guiPrefixes, "switch_")
    table.insert(self.l10nPostfixes, "_switch")
    self.gameLogos = {
        ["en"] = "dataS/menu/main_logo_switch_en.png",
        ["de"] = "dataS/menu/main_logo_switch_de.png"
    }
    self.gameplay.defaultGyroscopeSteering = false
    self.gameplay.defaultCameraTilt = false
end
function Platform.applyIOS()
    print("Platform: loading iOS")
    local self = Platform
    self.isIOS = true
    self.hasInAppPurchases = true
    self.gameRatingEnabled = true
    self.showGamerTagInMainScreen = false
end
function Platform.applyAndroid()
    print("Platform: loading Android")
    local self = Platform
    self.isAndroid = true
    self.hasInAppPurchases = true
    self.gameRatingEnabled = true
    self.showGamerTagInMainScreen = false
end
function Platform.applyNetflix()
    print("Platform: loading Netflix")
    Platform.gameRatingEnabled = true
    Platform.urlRating = "lp/fs23Netflix-rating.php"
    Platform.hasInAppPurchases = false
    Platform.isNetflix = true
    Platform.gameLogos = {
        ["en"] = "dataS/menu/main_logo_netflix_en.png",
        ["de"] = "dataS/menu/main_logo_netflix_de.png"
    }
end
function Platform.applyMSStore()
    print("Platform: loading MSStore")
    local self = Platform
    self.canChangeGamerTag = false
    self.showGamerTagInMainScreen = true
end
function Platform.applySteam()
    print("Platform: loading Steam")
    Platform.urlDedicatedServer = "fs25-rent-a-dedicated-server-from-steam.php"
end
function Platform.verifyMultiplayerAvailabilityInMenu()
    if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
        g_masterServerConnection:disconnectFromMasterServer()
        g_gui:changeScreen(nil, MainScreen)
    end
    if getNetworkError() then
        g_masterServerConnection:disconnectFromMasterServer()
        ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
    end
end
Platform.init()