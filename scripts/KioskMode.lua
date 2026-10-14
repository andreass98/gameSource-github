local localDeleteFile = deleteFile
local localDeleteFolder = deleteFolder
KioskMode = {}
KioskMode.GAMEPAD_NAME = "JoyWarrior Gamepad 32"
KioskMode.BIT_TO_BUTTON_ID = {
    [1] = 7,
    [2] = 6,
    [3] = 5,
    [4] = 4,
    [5] = 3,
    [6] = 2,
    [7] = 1,
    [8] = 0,
    [15] = 8,
    [16] = 9,
    [17] = 10
}
function KioskMode.EMPTY_FUNC() end
KioskMode.END_SLIDE_BAR_POSITION = "576px 130px"
KioskMode.END_SLIDE_BAR_SIZE = "768px 13px"
KioskMode.END_SLIDE_TEXT_SIZE = "22px"
KioskMode.END_SLIDE_TEXT_OFFSET = "13px"
KioskMode.END_SLIDE_BUTTON_OFFSET = "14px"
local KioskMode_mt = Class(KioskMode)
function KioskMode.new(customMt)
    -- upvalues: (copy) KioskMode_mt
    local self = setmetatable({}, customMt or KioskMode_mt)
    self.configPaths = { "dataS/kioskMode/", "data/kioskMode/", getUserProfileAppPath() .. "kioskMode/" }
    self.profileSelectorGamepadId = nil
    self.currentProfile = nil
    self.profiles = {}
    self.maskToProfile = {}
    self.settings = {}
    self.nextLanguageRestartTimer = nil
    self.nextLanguageIndex = nil
    self.maps = {}
    return self
end
function KioskMode:generateBitmasks()
    local mapping = {
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        15,
        16,
        17
    }
    local generatedMasks = {}
    local hashedMasks = {}
    local function printResult(target, _)
        -- upvalues: (copy) mapping, (copy) hashedMasks, (copy) generatedMasks
        local bitMask = 0
        for k, v in ipairs(target) do
            if v == 1 then
                bitMask = Utils.setBit(bitMask, mapping[k])
            end
        end
        if hashedMasks[bitMask] == nil then
            table.insert(generatedMasks, bitMask)
            hashedMasks[bitMask] = true
        else
            Logging.warning("Mask %s already exists", table.concat(target, ""))
        end
    end
    local function bitmask(n, target, i)
        -- upvalues: (copy) printResult, (copy) bitmask
        if i == n then
            printResult(target, n)
        else
            target[i] = 0
            bitmask(n, target, i + 1)
            target[i] = 1
            bitmask(n, target, i + 1)
        end
    end
    local target = { 0 }
    bitmask(12, target, 2)
    target[1] = 1
    bitmask(12, target, 2)
    for i, mask in ipairs(generatedMasks) do
        local str = ""
        local k = 1
        for k = k, 20 do
            if (k - 1) % 5 == 0 then
            end
            if k == 18 then
            elseif KioskMode.BIT_TO_BUTTON_ID[k] == nil then
                str = str .. (math.random() > 0.5 and 1 or 0)
            else
                str = str .. (Utils.isBitSet(mask, k) and 1 or 0)
            end
        end
        print(string.format("%s", str))
    end
end
function KioskMode:delete()
    self:disposeVideo()
end
function KioskMode:load()
    -- upvalues: (copy) localDeleteFile
    if StartParams.getIsSet("kioskDisabled") then
        return false
    end
    local isLoaded = false
    for _, path in ipairs(self.configPaths) do
        if self:loadFromPath(path) then
            isLoaded = true
        end
    end
    if not isLoaded then
        return false
    end
    InGameMenu.makeIsAIEnabledPredicate = KioskMode.inj_inGameMenu_makeIsAIEnabledPredicate
    InGameMenu.makeIsPricesEnabledPredicate = KioskMode.inj_inGameMenu_makeIsPricesEnabledPredicate
    InGameMenu.makeIsAnimalsEnabledPredicate = KioskMode.inj_inGameMenu_makeIsAnimalsEnabledPredicate
    InGameMenu.makeIsContractsEnabledPredicate = KioskMode.inj_inGameMenu_makeIsContractsEnabledPredicate
    InGameMenu.makeIsGarageEnabledPredicate = KioskMode.inj_inGameMenu_makeIsGarageEnabledPredicate
    InGameMenu.makeIsSettingsEnabledPredicate = KioskMode.inj_inGameMenu_makeIsSettingsEnabledPredicate
    InGameMenu.makeIsHelpEnabledPredicate = KioskMode.inj_inGameMenu_makeIsHelpEnabledPredicate
    InGameMenuSettingsFrame.initializeButtons = Utils.overwrittenFunction(InGameMenuSettingsFrame.initializeButtons, KioskMode.inj_inGameMenuSettingsFrame_initializeButtons)
    MapManager.addMapItem = Utils.overwrittenFunction(MapManager.addMapItem, KioskMode.inj_mapManager_addMapItem)
    function loadMods()
        haveModsChanged()
    end
    InputBinding.loadModActions = Utils.overwrittenFunction(InputBinding.loadModActions, KioskMode.inj_inputBinding_loadModActions)
    InputBinding.loadModBindingDefaults = Utils.overwrittenFunction(InputBinding.loadModBindingDefaults, KioskMode.inj_inputBinding_loadModBindingDefaults)
    Gui.changeScreen = Utils.overwrittenFunction(Gui.changeScreen, KioskMode.inj_gui_changeScreen)
    Gui.showGui = Utils.overwrittenFunction(Gui.showGui, KioskMode.inj_gui_showGui)
    MessageCenter.publish = Utils.overwrittenFunction(MessageCenter.publish, KioskMode.inj_messageCenter_publish)
    if Platform.isPC and StartParams.getIsSet("kioskModeResetFiles") then
        local inputBinding = getUserProfileAppPath() .. "inputBinding.xml"
        if fileExists(inputBinding) then
            localDeleteFile(inputBinding)
        end
        local gameSettings = getUserProfileAppPath() .. "gameSettings.xml"
        if fileExists(gameSettings) then
            localDeleteFile(gameSettings)
        end
    end
    function modDownloadManagerLoaded()
        return false
    end
    return true
end
function KioskMode:loadFromPath(path)
    local configFileName = path .. "kioskMode.xml"
    if not fileExists(configFileName) then
        return false
    end
    local zipFilePath = string.sub(path, 1, #path - 1) .. ".zip"
    if folderExists(path) and fileExists(zipFilePath) then
        Logging.error("Kiosk mode config directory %q also has a zip file with the same name %q next to it overriding any changes made in the directory. Delete or rename the zip file!", path, zipFilePath)
        return false
    end
    local xmlFile = XMLFile.load("KioskMode", configFileName, nil)
    if xmlFile == nil then
        return false
    end
    local defaultConfigFile = Utils.getFilename(xmlFile:getString("kioskMode.defaultProfile.configFile", ""), path)
    if not fileExists(defaultConfigFile) then
        Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - default config file \'%s\' not found", defaultConfigFile)
        return false
    end
    self.defaultConfigFile = defaultConfigFile
    for _, key in xmlFile:iterator("kioskMode.profiles.profile") do
        local name = xmlFile:getString(key .. "#name", "")
        local configFile = Utils.getFilename(xmlFile:getString(key .. ".configFile", ""), path)
        if fileExists(configFile) then
            local mask = 0
            local bitCount = 1
            local bitsStr = xmlFile:getString(key .. "#bits", "")
            if bitsStr:len() == 23 then
                local i = 1
                local bit = bitsStr:len()
                for i = i, bit do
                    local bit = bitsStr:sub(i, i)
                    if bit ~= " " then
                        if tonumber(bit) == 1 then
                            if KioskMode.BIT_TO_BUTTON_ID[bitCount] == nil then
                                if bitCount == 18 then
                                    Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - Bit %d cannot be used. Please replace it with 0 for profile \'%s\'", bitCount, name)
                                end
                            else
                                mask = Utils.setBit(mask, bitCount)
                            end
                        end
                        bitCount = bitCount + 1
                    end
                end
                if self.maskToProfile[mask] == nil then
                    local usedProfile = {
                        ["id"] = #self.profiles + 1,
                        ["name"] = name,
                        ["mask"] = mask,
                        ["configFile"] = configFile
                    }
                    self.maskToProfile[mask] = usedProfile
                    table.insert(self.profiles, usedProfile)
                else
                    Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - %s mask already used for profile \'%s\'. Ignoring this profile", name, self.maskToProfile[mask].name)
                end
            else
                Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - invalid bitsformat (##### ##### ##### #####) for profile \'%s\'. Ignoring this profile", name)
            end
        else
            Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - config file \'%s\' for profile \'%s\' not found. Ignoring this profile", configFile, name)
        end
    end
    xmlFile:delete()
    if #self.profiles == 0 then
        Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - No profiles defined!")
        return false
    end
    self.configFileName = configFileName
    table.insert(g_dlcsDirectories, {
        ["path"] = path .. "pdlc/",
        ["isLoaded"] = true
    })
    return true
end
function KioskMode:loadInputActions()
    if self.configFileName ~= nil then
        local xmlFileObj = XMLFile.load("KioskMode Inputs", self.configFileName)
        local xmlFile = xmlFileObj:getHandle()
        g_inputBinding:loadActionsFromXMLPath(xmlFile, "kioskMode.input.actions", g_i18n, nil)
        xmlFileObj:delete()
    end
end
function KioskMode:loadInputBindings()
    if self.configFileName ~= nil then
        local xmlFileObj = XMLFile.load("KioskMode Inputs", self.configFileName)
        local xmlFile = xmlFileObj:getHandle()
        g_inputBinding:loadActionBindingsFromXMLPath(xmlFile, "kioskMode.input.bindings", true, nil, true, true)
        xmlFileObj:delete()
    end
end
function KioskMode:initializedGUIClasses()
    MainScreen.onOpen = Utils.appendedFunction(MainScreen.onOpen, KioskMode.inj_mainScreen_onOpen)
    MainScreen.update = Utils.overwrittenFunction(MainScreen.update, KioskMode.inj_mainScreen_update)
    MainScreen.onClose = Utils.appendedFunction(MainScreen.onClose, KioskMode.inj_mainScreen_onClose)
    MainScreen.inputEvent = Utils.overwrittenFunction(MainScreen.inputEvent, KioskMode.inj_mainScreen_inputEvent)
    MainScreen.updateStoreButtons = KioskMode.EMPTY_FUNC
    MPLoadingScreen.openWardrobe = KioskMode.EMPTY_FUNC
    MPLoadingScreen.onReadyToStart = Utils.overwrittenFunction(MPLoadingScreen.onReadyToStart, KioskMode.inj_mpLoadingScreen_onReadyToStart)
    InGameMenuMobileSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuMobileSettingsFrame.onFrameOpen, KioskMode.inj_inGameMenuMobileSettingsFrame_onFrameOpen)
    InGameMenu.onButtonSaveGame = KioskMode.EMPTY_FUNC
    CareerScreen.updateButtons = Utils.appendedFunction(CareerScreen.updateButtons, KioskMode.inj_careerScreen_updateButtons)
    CareerScreen.update = Utils.appendedFunction(CareerScreen.update, KioskMode.inj_careerScreen_update)
    ModSelectionScreen.update = Utils.appendedFunction(ModSelectionScreen.update, KioskMode.inj_modSelectionScreenn_update)
    NewGameScreen.update = Utils.appendedFunction(NewGameScreen.update, KioskMode.inj_newGameScreen_update)
    InGameMenuMapFrame.updateInputGlyphs = Utils.appendedFunction(InGameMenuMapFrame.updateInputGlyphs, KioskMode.inj_inGameMenuMapFrame_updateInputGlyphs)
end
function KioskMode:init()
    self:initProfileSelectorGamepad()
    HUD.createDisplayComponents = Utils.appendedFunction(HUD.createDisplayComponents, KioskMode.inj_hud_createDisplayComponents)
    Mission00.getIsTourSupported = Utils.overwrittenFunction(Mission00.getIsTourSupported, KioskMode.inj_mission00_getIsTourSupported)
    Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, KioskMode.inj_mission00_onStartMission)
    SpecializationManager.addSpecialization = Utils.appendedFunction(SpecializationManager.addSpecialization, KioskMode.inj_specializationManager_addSpecialization)
    PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(PlayerInputComponent.registerGlobalPlayerActionEvents, KioskMode.inj_playerInputComponent_registerGlobalPlayerActionEvents)
    PlayerInputComponent.getCanToggleCamera = Utils.appendedFunction(PlayerInputComponent.getCanToggleCamera, KioskMode.inj_playerInputComponent_getCanToggleCamera)
    FSBaseMission.getIsAutoSaveSupported = Utils.appendedFunction(FSBaseMission.getIsAutoSaveSupported, KioskMode.inj_fsBaseMission_getIsAutoSaveSupported)
    FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, KioskMode.inj_fsBaseMission_update)
    AnimalLoadingTrigger.load = Utils.overwrittenFunction(AnimalLoadingTrigger.load, KioskMode.inj_animalLoadingTrigger_load)
    VehicleSellingPoint.load = Utils.overwrittenFunction(VehicleSellingPoint.load, KioskMode.inj_vehicleSellingPoint_load)
    ShopTrigger.new = Utils.overwrittenFunction(ShopTrigger.new, KioskMode.inj_shopTrigger_new)
    LoanTrigger.new = Utils.overwrittenFunction(LoanTrigger.new, KioskMode.inj_loanTrigger_new)
    Environment.load = Utils.overwrittenFunction(Environment.load, KioskMode.inj_environment_load)
    StoreManager.getDefaultStoreItemsFilename = Utils.overwrittenFunction(StoreManager.getDefaultStoreItemsFilename, KioskMode.inj_storeManager_getDefaultStoreItemsFilename)
    ProductionPointActivatable.run = Utils.overwrittenFunction(ProductionPointActivatable.run, KioskMode.inj_productionPointActivatable_run)
    Farm.setInitialEconomy = Utils.appendedFunction(Farm.setInitialEconomy, KioskMode.inj_Farm_setInitialEconomy)
    function MissionManager.update(dt) end
    function SavegameController.getCanDeleteGame()
        return false
    end
    IngameMap.registerInput = Utils.overwrittenFunction(IngameMap.registerInput, KioskMode.inj_ingameMap_registerInput)
    RailroadCallerActivatable.run = Utils.overwrittenFunction(RailroadCallerActivatable.run, KioskMode.inj_railroadCallerActivatable_run)
    function getNumOfNotifications()
        return 0
    end
    function areAchievementsAvailable()
        return false
    end
    self:loadProfileConfig(self.defaultConfigFile)
    if GS_PLATFORM_PC and not g_gameSettings:getValue("gamepadEnabledSetByUser") then
        g_gameSettings:setValue("gamepadEnabledSetByUser", true)
        g_gameSettings:setValue("isGamepadEnabled", true)
        g_gameSettings:save()
    end
end
function KioskMode:initProfileSelectorGamepad()
    local i = 0
    local oldGetIsDeviceSupported = getNumOfGamepads() - 1
    for i = i, oldGetIsDeviceSupported do
        local gamepadName = getGamepadName(i)
        if gamepadName == KioskMode.GAMEPAD_NAME then
            Logging.info("KioskMode:initProfileSelectorGamepad - Found Gaming Station with gamepad \'%s\'", gamepadName)
            self.profileSelectorGamepadId = i
        end
    end
    if self.profileSelectorGamepadId ~= nil then
        local oldGetIsDeviceSupported = InputDevice.getIsDeviceSupported
        function InputDevice.getIsDeviceSupported(engineDeviceId, deviceName)
            -- upvalues: (copy) oldGetIsDeviceSupported
            if oldGetIsDeviceSupported(engineDeviceId, deviceName) then
                return deviceName ~= KioskMode.GAMEPAD_NAME
            else
                return false
            end
        end
    end
    local oldGetIsDeviceSupported = self.profileSelectorGamepadId ~= nil
    return oldGetIsDeviceSupported
end
function KioskMode:loadProfileConfig(configFileName)
    Logging.info("KioskMode:loadProfileConfig - Loading profile config \'%s\'", configFileName)
    local xmlFile = XMLFile.load("KioskMode Profile", configFileName)
    local path = Utils.getDirectory(configFileName)
    self.settings.canSelectSavegame = xmlFile:getBool("config.canSelectSavegame", false)
    self.settings.canSelectMods = xmlFile:getBool("config.canSelectMods", false)
    if not self.settings.canSelectSavegame then
        local savegamePath = xmlFile:getString("config.savegame")
        if savegamePath ~= nil then
            savegamePath = Utils.getFilename(savegamePath, path)
        end
        self:setSavegame(savegamePath)
        self.settings.savegame = savegamePath
    end
    local savegamePath = xmlFile:getString("config.logo")
    if savegamePath ~= nil then
        self.settings.logoFilename = Utils.getFilename(savegamePath, path)
        self.settings.logoWidth = xmlFile:getInt("config.logo#width", 600)
        self.settings.logoHeight = xmlFile:getInt("config.logo#height", 150)
    end
    local endSlide = self.settings
    local timescales = savegamePath ~= nil
    endSlide.logoEnabled = timescales
    local endSlide = xmlFile:getString("config.endSlide")
    if endSlide ~= nil then
        self.settings.endSlide = Utils.getFilename(endSlide, path)
    end
    self.settings.tourEnabled = xmlFile:getBool("config.tourEnabled", false)
    self.settings.aiEnabled = xmlFile:getBool("config.aiEnabled", true)
    self.settings.aiWorkerEnabled = xmlFile:getBool("config.aiWorkerEnabled", true)
    self.settings.mainMenuEnabled = xmlFile:getBool("config.mainMenuEnabled", false)
    self.settings.watermarkEnabled = xmlFile:getBool("config.watermarkEnabled", false)
    self.settings.ingameMenuEnabled = xmlFile:getBool("config.ingameMenuEnabled", true)
    self.settings.reloadEnabled = xmlFile:getBool("config.reloadEnabled", false)
    self.settings.animalShopEnabled = xmlFile:getBool("config.shopsEnabled.animals", false)
    self.settings.vehicleShopEnabled = xmlFile:getBool("config.shopsEnabled.vehicles", false)
    self.settings.farmlandShopEnabled = xmlFile:getBool("config.shopsEnabled.farmlands", false)
    self.settings.placeableShopEnabled = xmlFile:getBool("config.shopsEnabled.placeables", false)
    self.settings.wardrobeShopEnabled = xmlFile:getBool("config.shopsEnabled.wardrobe", false)
    self.settings.productionEnabled = xmlFile:getBool("config.productionEnabled", true)
    self.settings.trainEnabled = xmlFile:getBool("config.trainEnabled", false)
    self.settings.riceFieldEnabled = xmlFile:getBool("config.riceFieldEnabled", true)
    self.settings.helpLineTriggerEnabled = xmlFile:getBool("config.helpLineTriggerEnabled", true)
    self.settings.extendedDrivingHelp = xmlFile:getBool("config.extendedDrivingHelp", false)
    self.settings.alwaysDay = xmlFile:getBool("config.alwaysDay", false)
    self.settings.startMoney = xmlFile:getInt("config.startMoney", 1000000)
    self.settings.skipMainMenu = xmlFile:getBool("config.skipMainMenu", false)
    self.settings.farmlandsBuyAll = xmlFile:getBool("config.farmlandsBuyAll", false)
    self.settings.startVehicleIndex = xmlFile:getInt("config.startVehicleIndex", nil)
    self.settings.playerCanToggleCamera = xmlFile:getBool("config.player.canToggleCamera", false)
    if KioskMode.TIMESCALE_BACKUP == nil then
        KioskMode.TIMESCALE_BACKUP = Platform.gameplay.timeScaleSettings
        KioskMode.TIMESCALE_DEV_BACKUP = Platform.gameplay.timeScaleDevSettings
    end
    Platform.gameplay.timeScaleSettings = KioskMode.TIMESCALE_BACKUP
    Platform.gameplay.timeScaleDevSettings = KioskMode.TIMESCALE_DEV_BACKUP
    local timescales = xmlFile:getString("config.timescales", nil)
    if timescales ~= nil then
        local newTimescales = string.getVector(timescales)
        if #newTimescales > 0 then
            Platform.gameplay.timeScaleSettings = newTimescales
            Platform.gameplay.timeScaleDevSettings = {}
        end
    end
    local newTimescales = xmlFile:getString("config.maps", "")
    local mapIds = string.split(newTimescales, " ")
    self.settings.maps = nil
    for _, id in ipairs(mapIds) do
        if self.settings.maps == nil then
            self.settings.maps = {}
        end
        self.settings.maps[id] = true
    end
    self:updateAvailableMaps()
    local storeItems = xmlFile:getString("config.storeItems", "")
    local storeItems
    if storeItems == "" then
        storeItems = nil
    else
        storeItems = Utils.getFilename(storeItems, path)
    end
    self.settings.storeItems = storeItems
    local videos = nil
    local duration = nil
    local _ = xmlFile:getString("config.videos", "")
    if _ ~= "" then
        local id = Utils.getFilename(_, path)
        local id = Files.new(id).files
        for _, file in ipairs(id) do
            if fileExists(id .. "/" .. file.filename) then
                videos = videos == nil and {} or videos
                table.insert(videos, id .. "/" .. file.filename)
            end
        end
        duration = xmlFile:getInt("config.videos#inactiveDurationSeconds", 180) * 1000
        if videos == nil or #videos == 0 then
            videos = nil
            duration = nil
            Logging.warning("KioskMode: No videos found in \'%s\'", id)
        end
    end
    self.settings.videos = videos
    self.settings.videoTimer = duration
    local id = xmlFile:getFloat("config.playtimeSeconds")
    if id ~= nil then
        self.settings.playtimeDuration = id * 1000
    end
    local mods = self.settings
    mods.playtimeEnabled = id ~= nil
    local mods = {}
    xmlFile:iterate("config.mods.mod", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) mods
        local modId = xmlFile:getString(key)
        if modId ~= nil then
            table.insert(mods, modId)
        end
    end)
    self.settings.mods = mods
    self:openMainMenu()
    self:setupMainMenu()
    xmlFile:delete()
end
function KioskMode:update(dt)
    if (self.profileSelectorGamepadId ~= nil or (StartParams.getIsSet("kioskProfileId") or StartParams.getIsSet("kioskProfileName"))) and (g_gui.currentGuiName == "MainScreen" and self.currentProfile == nil) then
        local profile = self:getProfile()
        if profile ~= nil then
            self:loadProfileConfig(profile.configFile)
            self.currentProfile = profile
        end
    end
    if GS_PLATFORM_PC and (self.nextLanguageRestartTimer ~= nil and self.nextLanguageRestartTimer < g_time) then
        doRestart(false, "")
    end
    if g_currentMission ~= nil and self.playtimeReloadTimer ~= nil then
        self.playtimeReloadTimer = self.playtimeReloadTimer - dt
        if self.playtimeReloadTimer <= 0 then
            self.playtimeReloadTimer = nil
            self:onPlaytimeReload()
        end
    end
    if self.currentVideoIndex == nil then
        if self.videoStartTimer ~= nil then
            self.videoStartTimer = self.videoStartTimer - dt
            if self.videoStartTimer < 0 then
                self:nextVideo()
                return
            end
        end
    else
        if self.videoOverlay ~= nil and isVideoOverlayPlaying(self.videoOverlay) then
            updateVideoOverlay(self.videoOverlay)
            return
        end
        if self.videoOverlay ~= nil then
            self:disposeVideo()
            self:nextVideo()
        end
    end
end
function KioskMode:draw()
    self:drawEndSlide()
    if self.nextLanguageIndex ~= nil then
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(true)
        setTextColor(0, 0, 0, 1)
        local timeLeft = math.ceil((self.nextLanguageRestartTimer - g_time) / 1000)
        renderText(0.5 + 2 * g_pixelSizeX, 0.75 - g_pixelSizeY, 0.025, string.format("Changing Language.\nNew language after restart will be \'%s\'. \nRestarting in %d seconds...", getLanguageName(self.nextLanguageIndex), timeLeft))
        setTextColor(1, 1, 1, 1)
        renderText(0.5, 0.75, 0.025, string.format("Changing Language.\nNew language after restart will be \'%s\'. \nRestarting in %d seconds...", langName, timeLeft))
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
    end
    if g_gui.currentGuiName == "MainScreen" and self.currentProfile ~= nil then
        setTextAlignment(RenderText.ALIGN_LEFT)
        local timeLeft = self.currentProfile.name
        setTextColor(0, 0, 0, 0.75)
        renderText(0.01, 0.9585, 0.011, timeLeft)
        setTextColor(1, 1, 1, 1)
        renderText(0.01, 0.96, 0.011, timeLeft)
    end
    if g_currentMission ~= nil and g_currentMission.hud ~= nil then
        local timeLeft = not g_currentMission.hud:getIsFading()
        local langName = g_gui:getIsGuiVisible()
        if self:getSetting("logoEnabled") and (not langName and timeLeft) then
            g_currentMission.hud.kioskModeLogoElement:draw()
        end
        if self.playtimeReloadTimer ~= nil then
            local left = string.format("%0.1d:", self.playtimeReloadTimer / 60000)
            local right = string.format("%0.2d", self.playtimeReloadTimer / 1000 % 60)
            setTextBold(true)
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText(0.5, langName and 0.85 or 0.932, 0.05, left)
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(0.5, langName and 0.85 or 0.932, 0.05, right)
            setTextBold(false)
        end
    end
    if self:getSetting("watermarkEnabled") then
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(true)
        setTextColor(1, 1, 1, 0.5)
        renderText(0.5, 0.75, getCorrectTextSize(0.075), "INTERNAL USE ONLY")
        renderText(0.5, 0.73, getCorrectTextSize(0.03), "Copyright GIANTS Software GmbH")
        setTextColor(1, 1, 1, 1)
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
    if self.videoOverlay ~= nil and isVideoOverlayPlaying(self.videoOverlay) then
        new2DLayer()
        renderOverlay(self.videoOverlay, 0, 0, 1, 1)
    end
end
function KioskMode:drawEndSlide()
    local endSlide = self:getEndSlideOnLoad()
    local isLoadingScreen = false
    if endSlide ~= nil then
        isLoadingScreen = g_gui.currentGuiName == "MPLoadingScreen"
    end
    if isLoadingScreen then
        if self.endSlideOverlay == nil then
            self.endSlideOverlay = Overlay.new(endSlide, 0, 0, 1, g_screenAspectRatio)
        end
        new2DLayer()
        self.endSlideOverlay:render()
        local barPosition = math.clamp(g_mpLoadingScreen ~= nil and g_mpLoadingScreen.totalLoadPercentage or 0, 0, 1)
        local barPosition = GuiUtils.getNormalizedScreenValues(KioskMode.END_SLIDE_BAR_POSITION)
        local barSize = GuiUtils.getNormalizedScreenValues(KioskMode.END_SLIDE_BAR_SIZE)
        local barX = barPosition[1]
        local barY = barPosition[2]
        local barWidth = barSize[1]
        local barHeight = barSize[2]
        drawFilledRect(barX, barY, barWidth, barHeight, 0, 0, 0, 0.5)
        drawFilledRect(barX, barY, barWidth * barPosition, barHeight, 1, 1, 1, 1)
        local textSize = GuiUtils.getNormalizedValue(KioskMode.END_SLIDE_TEXT_SIZE, false)
        local textOffset = GuiUtils.getNormalizedValue(KioskMode.END_SLIDE_TEXT_OFFSET, false)
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(true)
        setTextColor(1, 1, 1, 1)
        renderText(0.5, barY + barHeight + textOffset, textSize, string.format("%d%%", barPosition * 100))
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
        local isReady = false
        if g_mpLoadingScreen ~= nil then
            isReady = false
            if g_mpLoadingScreen.button ~= nil then
                isReady = g_mpLoadingScreen.state == MPLoadingScreen.STATE_READY
            end
        end
        if isReady then
            local button = g_mpLoadingScreen.button
            local buttonOffset = GuiUtils.getNormalizedValue(KioskMode.END_SLIDE_BUTTON_OFFSET, false)
            button:setAbsolutePosition(0.5 - button.absSize[1] / 2, barY - buttonOffset - button.absSize[2])
            button:draw()
        end
    elseif self.endSlideOverlay ~= nil then
        self.endSlideOverlay:delete()
        self.endSlideOverlay = nil
    end
end
function KioskMode:getSetting(name)
    return self.settings[name]
end
function KioskMode:getProfile()
    if StartParams.getIsSet("kioskProfileId") then
        local profile = StartParams.getValue
        local profileId = tonumber(profile("kioskProfileId"))
        local profile = self.profiles[profileId]
        if profile ~= nil then
            return profile
        end
        if not self.startParamProfileIdWarningShown then
            self.startParamProfileIdWarningShown = true
            Logging.error("Invalid kioskProfileId \'%s\'!", profileId)
        end
        return nil
    end
    if not StartParams.getIsSet("kioskProfileName") then
        if self.profileSelectorGamepadId ~= nil then
            local profileId = 0
            for bit, _ in pairs(KioskMode.BIT_TO_BUTTON_ID) do
                if getInputButton(_, self.profileSelectorGamepadId) > 0 then
                    profileId = Utils.setBit(profileId, bit)
                end
            end
            local profile = self.maskToProfile[profileId]
            if profile ~= nil then
                return profile
            end
        end
        return nil
    end
    local profileId = StartParams.getValue("kioskProfileName")
    local profile = string.upper(profileId)
    for _, profile in pairs(self.profiles) do
        if string.upper(profile.name) == profile then
            return profile
        end
    end
    if not self.startParamProfileNameWarningShown then
        self.startParamProfileNameWarningShown = true
        Logging.error("Invalid kioskProfileName \'%s\'!", profileId)
    end
    return nil
end
function KioskMode.setSavegame(_, path)
    -- upvalues: (copy) localDeleteFolder
    if path == nil then
        if not GS_IS_CONSOLE_VERSION then
            localDeleteFolder(getUserProfileAppPath() .. "savegame1")
        end
    else
        if GS_IS_CONSOLE_VERSION then
            saveSetFixedSavegame(path)
            return
        end
        local savegamePath = getUserProfileAppPath() .. "savegame1"
        localDeleteFolder(savegamePath)
        createFolder(savegamePath)
        local newFiles = Files.new(path).files
        for _, file in ipairs(newFiles) do
            copyFile(path .. "/" .. file.filename, savegamePath .. "/" .. file.filename, true)
        end
        if not fileExists(savegamePath .. "/careerSavegame.xml") then
            Logging.error("Failed to copy savegame from \'%s\' to \'%s\'!", path, savegamePath)
            return
        end
    end
end
function KioskMode:setupMainMenu()
    local areButtonsDisabled = not self:getSetting("mainMenuEnabled")
    g_mainScreen.careerButton:setDisabled(self:getSetting("bscSPAutoStart"))
    g_mainScreen.multiplayerButton:setDisabled(areButtonsDisabled)
    g_mainScreen.downloadModsButton:setDisabled(areButtonsDisabled)
    g_mainScreen.achievementsButton:setDisabled(areButtonsDisabled)
    if Platform.isConsole then
        g_mainScreen.settingsButton:setDisabled(true)
    else
        g_mainScreen.settingsButton:setDisabled(areButtonsDisabled)
    end
    g_mainScreen.quitButton:setDisabled(areButtonsDisabled)
    g_mainScreen.storeButton:setDisabled(areButtonsDisabled)
    g_mainScreen.buttonBox:invalidateLayout()
end
function KioskMode:addRegisteredMaps(map)
    table.addElement(self.maps, map)
end
function KioskMode:updateAvailableMaps()
    table.clear(g_mapManager.maps)
    for _, map in ipairs(self.maps) do
        if self.settings.maps == nil or self.settings.maps[map.id] == true then
            table.insert(g_mapManager.maps, map)
            g_mapManager.idToMap[map.id] = map
        end
    end
end
function KioskMode:resetVideoTimer()
    if self:getSetting("videos") == nil then
        return false
    end
    self.videoStartTimer = self:getSetting("videoTimer")
    self:disposeVideo()
    self.currentVideoIndex = nil
    return self.videoOverlay ~= nil
end
function KioskMode:openMainMenu()
    self:resetVideoTimer()
end
function KioskMode:closeMainMenu()
    self.videoStartTimer = nil
end
function KioskMode:disposeVideo()
    if self.videoOverlay ~= nil and isVideoOverlayPlaying(self.videoOverlay) then
        stopVideoOverlay(self.videoOverlay)
        delete(self.videoOverlay)
        self.videoOverlay = nil
    end
end
function KioskMode:nextVideo()
    self:disposeVideo()
    if self.currentVideoIndex == nil or self.currentVideoIndex >= #self:getSetting("videos") then
        self.currentVideoIndex = 1
    else
        self.currentVideoIndex = self.currentVideoIndex + 1
    end
    self.videoStartTimer = nil
    self.videoOverlay = createVideoOverlay(self.settings.videos[self.currentVideoIndex], false, 1)
    playVideoOverlay(self.videoOverlay)
end
function KioskMode:onResetFiles()
    if GS_PLATFORM_PC then
        doRestart(false, "-kioskModeResetFiles")
    end
end
function KioskMode:onStartVideos()
    if g_gui.currentGuiName == "MainScreen" then
        g_kioskMode:nextVideo()
    end
end
function KioskMode.onToggleLanguage(_, _, inputValue, _, _, _, _, _)
    if GS_PLATFORM_PC and g_gui.currentGuiName == "MainScreen" then
        local currentLanguage = getLanguage()
        local nextIndex = nil
        for k, v in ipairs(g_availableLanguagesTable) do
            if v == currentLanguage then
                nextIndex = k + math.sign(inputValue)
            end
        end
        local nextIndex = (nextIndex == nil or #g_availableLanguagesTable < nextIndex) and 1 or (nextIndex < 1 and #g_availableLanguagesTable or nextIndex)
        local currentLanguage = g_availableLanguagesTable[nextIndex]
        g_kioskMode.nextLanguageIndex = currentLanguage
        g_kioskMode.nextLanguageRestartTimer = g_time + 5000
        setLanguage(currentLanguage)
        g_kioskMode:resetVideoTimer()
    end
end
function KioskMode:onReloadSavegame()
    if g_kioskMode:getSetting("reloadEnabled") or self.playtimeReloadTimer ~= nil then
        OnInGameMenuMenu()
    end
end
function KioskMode:getEndSlideOnLoad()
    if StartParams.getIsSet("kioskEndSlide") then
        return self.settings.endSlide
    else
        return nil
    end
end
function KioskMode:onPlaytimeReload()
    if g_currentMission ~= nil then
        OnInGameMenuMenu(nil, nil, self.settings.endSlide ~= nil and "-kioskEndSlide" or "")
    end
end
function KioskMode.inj_mpLoadingScreen_onReadyToStart(screen, superFunc)
    if g_kioskMode:getEndSlideOnLoad() == nil then
        superFunc(screen)
    else
        screen.onClickOk = KioskMode.EMPTY_FUNC
        superFunc(screen)
        screen.onClickOk = screen.onClickOk
    end
end
function KioskMode:registerGlobalInputActionEvents()
    if GS_PLATFORM_PC then
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_RESET_FILES, g_kioskMode, g_kioskMode.onResetFiles, false, true, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_RELOAD_GAME, g_kioskMode, g_kioskMode.onReloadSavegame, false, true, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_TOGGLE_LANGUAGE, nil, g_kioskMode.onToggleLanguage, false, true, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_START_VIDEOS, nil, g_kioskMode.onStartVideos, false, true, false, true)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
    end
end
function KioskMode.inj_mapManager_addMapItem(mapManager, superFunc, ...)
    local success = superFunc(mapManager, ...)
    if success then
        local map = table.remove(mapManager.maps, #mapManager.maps)
        mapManager.idToMap[map.id] = nil
        g_kioskMode:addRegisteredMaps(map)
    end
    g_kioskMode:updateAvailableMaps()
    return success
end
function KioskMode.inj_Farm_setInitialEconomy(farm, ...)
    if not farm.isSpectator then
        farm.money = g_kioskMode:getSetting("startMoney")
        Logging.info("Set Kiosk-Mode farm startmoney: %d", farm.money)
    end
end
function KioskMode.inj_ingameMap_registerInput(ingameMap, superFunc, ...)
    if not g_kioskMode:getSetting("logoEnabled") then
        superFunc(ingameMap, ...)
    end
end
function KioskMode.inj_inGameMenuMapFrame_updateInputGlyphs(ingameMenu, ...)
    local farmlandShopEnabled = g_kioskMode:getSetting("farmlandShopEnabled")
    ingameMenu.buttonSwitchMapMode:setDisabled(not farmlandShopEnabled)
end
function KioskMode.inj_storeManager_getDefaultStoreItemsFilename(storeManager, superFunc, ...)
    local storeConfig = g_kioskMode:getSetting("storeItems")
    if storeConfig == nil then
        return superFunc(storeManager, ...)
    else
        return storeConfig
    end
end
function KioskMode.inj_environment_load(environment, superFunc, ...)
    local success = superFunc(environment, ...)
    if g_kioskMode:getSetting("alwaysDay") then
        environment.dayNightCycle = false
    end
    return success
end
function KioskMode.inj_loanTrigger_new(id, superFunc, ...)
    local loanTrigger = superFunc(id)
    loanTrigger.isEnabled = g_kioskMode:getSetting("vehicleShopEnabled")
    return loanTrigger
end
function KioskMode.inj_shopTrigger_new(id, superFunc, ...)
    local shopTrigger = superFunc(id)
    shopTrigger.isEnabled = g_kioskMode:getSetting("vehicleShopEnabled")
    return shopTrigger
end
function KioskMode.inj_vehicleSellingPoint_load(vehicleSellingPoint, superFunc, ...)
    local ret = superFunc(vehicleSellingPoint, ...)
    vehicleSellingPoint.isEnabled = g_kioskMode:getSetting("vehicleShopEnabled")
    return ret
end
function KioskMode.inj_animalLoadingTrigger_load(animalTrigger, superFunc, ...)
    local ret = superFunc(animalTrigger, ...)
    animalTrigger.isEnabled = g_kioskMode:getSetting("animalShopEnabled")
    return ret
end
function KioskMode.inj_fsBaseMission_getIsAutoSaveSupported(mission)
    return false
end
function KioskMode.inj_playerInputComponent_registerGlobalPlayerActionEvents(player)
    g_kioskMode:getSetting("reloadEnabled")
end
function KioskMode.inj_playerInputComponent_getCanToggleCamera(player, superFunc, ...)
    if g_kioskMode:getSetting("playerCanToggleCamera") then
        return superFunc(player, ...)
    else
        return false
    end
end
function KioskMode.inj_fsBaseMission_update(mission, dt)
    if g_kioskMode.tryToEnterVehicle ~= nil then
        g_localPlayer:requestToEnterVehicle(g_kioskMode.tryToEnterVehicle)
        g_kioskMode.tryToEnterVehicle = nil
    end
end
function KioskMode.inj_mission00_onStartMission()
    if g_kioskMode:getSetting("playtimeEnabled") then
        g_kioskMode.playtimeReloadTimer = g_kioskMode:getSetting("playtimeDuration")
    end
    if g_kioskMode:getSetting("farmlandsBuyAll") then
        g_currentMission:playerOwnsAllFields()
    end
    local startVehicleIndex = g_kioskMode:getSetting("startVehicleIndex")
    if startVehicleIndex ~= nil then
        g_kioskMode.tryToEnterVehicle = g_currentMission.vehicleSystem.enterables[startVehicleIndex] or g_kioskMode.tryToEnterVehicle
    end
    if not g_kioskMode:getSetting("helpLineTriggerEnabled") then
        g_currentMission:setShowHelpTrigger(false)
    end
end
function KioskMode.inj_inGameMenu_makeIsAIEnabledPredicate(ingameMenu)
    return function()
        return g_kioskMode:getSetting("aiEnabled")
    end
end
function KioskMode.inj_inGameMenu_makeIsPricesEnabledPredicate(ingameMenu)
    return function()
        return false
    end
end
function KioskMode.inj_inGameMenu_makeIsAnimalsEnabledPredicate(ingameMenu)
    return function()
        return false
    end
end
function KioskMode.inj_inGameMenu_makeIsContractsEnabledPredicate(ingameMenu)
    return function()
        return false
    end
end
function KioskMode.inj_inGameMenu_makeIsGarageEnabledPredicate(ingameMenu)
    return function()
        return false
    end
end
function KioskMode.inj_inGameMenu_makeIsSettingsEnabledPredicate(ingameMenu)
    return function()
        return false
    end
end
function KioskMode.inj_inGameMenu_makeIsHelpEnabledPredicate(ingameMenu)
    return function()
        return false
    end
end
function KioskMode.inj_inGameMenuSettingsFrame_initializeButtons(frame)
    frame.saveButton = nil
end
function KioskMode.inj_inputBinding_loadModActions(inputBinding, superFunc)
    superFunc(inputBinding)
    g_kioskMode:loadInputActions()
end
function KioskMode.inj_inputBinding_loadModBindingDefaults(inputBinding, superFunc)
    superFunc(inputBinding)
    g_kioskMode:loadInputBindings()
end
function KioskMode:inj_productionPointActivatable_run(superFunc)
    if g_kioskMode:getSetting("productionEnabled") then
        superFunc(self)
    else
        InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
    end
end
function KioskMode:inj_railroadCallerActivatable_run(superFunc)
    if g_kioskMode:getSetting("trainEnabled") then
        superFunc(self)
    else
        InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
    end
end
function KioskMode.inj_specializationManager_addSpecialization(specializationManager, _, className, ...)
    if specializationManager == g_specializationManager then
        if className == "AIJobVehicle" then
            if not g_kioskMode:getSetting("aiEnabled") then
                local old = AIJobVehicle.onRegisterActionEvents
                function AIJobVehicle.onRegisterActionEvents(vehicle, isActiveForInput, isActiveForInputIgnoreSelection)
                    -- upvalues: (copy) old
                    if vehicle.isClient then
                        vehicle:clearActionEventsTable(vehicle.spec_aiJobVehicle.actionEvents)
                    end
                    if g_kioskMode:getSetting("aiEnabled") then
                        if g_kioskMode:getSetting("ingameMenuEnabled") or vehicle:getStartableAIJob() ~= nil then
                            old(vehicle, isActiveForInput, isActiveForInputIgnoreSelection)
                        end
                    else
                        return
                    end
                end
            end
            if not g_kioskMode:getSetting("aiWorkerEnabled") then
                local old = AIJobVehicle.onRegisterActionEvents
                function AIJobVehicle.toggleAIVehicle(vehicle)
                    -- upvalues: (copy) old
                    if g_kioskMode:getSetting("aiWorkerEnabled") then
                        old(vehicle)
                    else
                        InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
                    end
                end
                return
            end
        elseif className == "Drivable" and g_kioskMode:getSetting("extendedDrivingHelp") then
            local old = Drivable.onRegisterActionEvents
            function Drivable.onRegisterActionEvents(vehicle, isActiveForInput, isActiveForInputIgnoreSelection)
                -- upvalues: (copy) old
                old(vehicle, isActiveForInput, isActiveForInputIgnoreSelection)
                for inputAction, data in pairs(vehicle.spec_drivable.actionEvents) do
                    local actionEventId = data.actionEventId
                    local event = g_inputBinding.events[actionEventId]
                    if event.displayPriority == GS_PRIO_VERY_LOW then
                        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
                    elseif event.displayPriority == GS_PRIO_LOW then
                        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                    end
                    if not event.displayIsVisible then
                        g_inputBinding:setActionEventTextVisibility(actionEventId, true)
                    end
                end
            end
            return
        end
    elseif specializationManager == g_placeableSpecializationManager then
        if className == "PlaceableWardrobe" then
            if not g_kioskMode:getSetting("wardrobeShopEnabled") then
                function WardrobeActivatable.run()
                    InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
                end
                return
            end
        elseif className == "PlaceableRiceField" and not g_kioskMode:getSetting("riceFieldEnabled") then
            function PlaceableRiceFieldActivatable.run()
                InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
            end
        end
    end
end
function KioskMode.inj_mission00_getIsTourSupported(mission, superFunc)
    if g_kioskMode:getSetting("tourEnabled") then
        return superFunc(mission)
    else
        return false
    end
end
function KioskMode.inj_hud_createDisplayComponents(hud, _)
    if g_kioskMode:getSetting("logoEnabled") then
        hud.ingameMap:setIsVisible(false)
        local width = g_kioskMode:getSetting("logoWidth")
        local height = g_kioskMode:getSetting("logoHeight")
        local filename = g_kioskMode:getSetting("logoFilename")
        local overlay, height = getNormalizedScreenValues(width, height)
        local overlay = Overlay.new(filename, g_safeFrameOffsetX, g_safeFrameOffsetY, overlay, height)
        hud.kioskModeLogoElement = HUDElement.new(overlay)
        table.insert(hud.displayComponents, hud.kioskModeLogoElement)
    end
end
function KioskMode.inj_inGameMenuMobileSettingsFrame_onFrameOpen(frame)
    frame.multiGraphics:setDisabled(true)
    frame.checkGyroscope:setDisabled(true)
    frame.checkTilt:setDisabled(true)
end
function KioskMode.inj_careerScreen_updateButtons(screen)
    if screen.buttonDelete then
        screen.buttonDelete:setDisabled(true)
    end
end
function KioskMode.inj_modSelectionScreenn_update(screen, _)
    if not g_kioskMode:getSetting("canSelectMods") then
        for _, modItem in pairs(screen.selectedMods) do
            screen:setItemState(modItem, false)
        end
        for _, modItem in pairs(g_kioskMode:getSetting("mods")) do
            local modItem = g_modManager:getModByName(modItem)
            if modItem ~= nil then
                if screen:shouldShowModInList(modItem) then
                    screen:setItemState(modItem, true)
                else
                    Logging.error("Mod \'%s\' is not available for current kiosk mode setup", modItem.title)
                end
            end
        end
        screen:onClickOk()
    end
end
function KioskMode.inj_newGameScreen_update(screen, _)
    local info = screen.startMissionInfo or g_startMissionInfo
    if g_mapManager:getNumOfMaps() == 1 then
        info.mapId = g_mapManager:getMapDataByIndex(1).id
    end
    info.initialMoney = g_kioskMode:getSetting("startMoney") or 100000
    screen:onClickOk()
end
function KioskMode.inj_careerScreen_update(screen, _)
    if not g_kioskMode:getSetting("canSelectSavegame") then
        screen.selectedIndex = 1
        screen:startSavegame(((screen.savegameController or g_savegameController):getSavegame(screen.selectedIndex)))
    end
end
function KioskMode.inj_mainScreen_inputEvent(screen, superFunc, action, value, eventUsed)
    eventUsed = action == InputAction.KIOSK_MODE_START_VIDEOS and true or (g_kioskMode:resetVideoTimer() and true or eventUsed)
    return superFunc(screen, action, value, eventUsed)
end
function KioskMode.inj_mainScreen_onClose(screen)
    g_kioskMode:closeMainMenu()
end
function KioskMode.inj_mainScreen_update(screen, superFunc, dt)
    if g_kioskMode:getSetting("skipMainMenu") then
        screen:onCareerClick()
    else
        superFunc(screen, dt)
    end
end
function KioskMode.inj_mainScreen_onOpen(screen)
    g_kioskMode:openMainMenu()
end
function KioskMode.inj_gui_changeScreen(gui, superFunc, sourceScreen, screenClass, ...)
    if screenClass == InGameMenu then
        if not g_kioskMode:getSetting("ingameMenuEnabled") then
            return
        end
    elseif screenClass == ShopMenu then
        if not g_kioskMode:getSetting("vehicleShopEnabled") then
            return
        end
    elseif screenClass == WardrobeScreen then
        if not g_kioskMode:getSetting("wardrobeShopEnabled") then
            return
        end
    elseif screenClass == ConstructionScreen then
        if not g_kioskMode:getSetting("placeableShopEnabled") then
            return
        end
    elseif screenClass == AnimalScreen and not g_kioskMode:getSetting("animalShopEnabled") then
        return
    end
    return superFunc(gui, sourceScreen, screenClass, ...)
end
function KioskMode.inj_gui_showGui(gui, superFunc, screenName, ...)
    if screenName == "InGameMenu" then
        if not g_kioskMode:getSetting("ingameMenuEnabled") then
            return
        end
    elseif screenName == "ShopMenu" then
        if not g_kioskMode:getSetting("vehicleShopEnabled") then
            return
        end
    elseif screenName == "WardrobeScreen" then
        if not g_kioskMode:getSetting("wardrobeShopEnabled") then
            return
        end
    elseif screenName == "ConstructionScreen" then
        if not g_kioskMode:getSetting("placeableShopEnabled") then
            return
        end
    elseif screenName == "AnimalScreen" and not g_kioskMode:getSetting("animalShopEnabled") then
        return
    end
    return superFunc(gui, screenName, ...)
end
function KioskMode.inj_messageCenter_publish(messageCenter, superFunc, msg, ...)
    if g_kioskMode:getSetting("ingameMenuEnabled") or msg ~= MessageType.GUI_INGAME_OPEN_AI_SCREEN then
        return superFunc(messageCenter, msg, ...)
    end
end