GameSettings = {}
local GameSettings_mt = Class(GameSettings)
g_xmlManager:addEarlyCreateSchemaFunction(function()
    GameSettings.xmlSchema = XMLSchema.new("gameSettings")
    GameSettings.registerXMLPaths(GameSettings.xmlSchema)
end)
GameSettings.SETTING = {
    ["DEFAULT_SERVER_PORT"] = "defaultServerPort",
    ["MAX_NUM_MIRRORS"] = "maxNumMirrors",
    ["LIGHTS_PROFILE"] = "lightsProfile",
    ["REAL_BEACON_LIGHTS"] = "realBeaconLights",
    ["MP_LANGUAGE"] = "mpLanguage",
    ["CAMERA_BOBBING"] = "cameraBobbing",
    ["INPUT_HELP_MODE"] = "inputHelpMode",
    ["GAMEPAD_ENABLED_SET_BY_USER"] = "gamepadEnabledSetByUser",
    ["IS_GAMEPAD_ENABLED"] = "isGamepadEnabled",
    ["HEAD_TRACKING_ENABLED_SET_BY_USER"] = "headTrackingEnabledSetByUser",
    ["IS_HEAD_TRACKING_ENABLED"] = "isHeadTrackingEnabled",
    ["FORCE_FEEDBACK"] = "forceFeedback",
    ["IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED"] = "isSoundPlayerStreamAccessAllowed",
    ["MOTOR_STOP_TIMER_DURATION"] = "motorStopTimerDuration",
    ["HORSE_ABANDON_TIMER_DURATION"] = "horseAbandonTimerDuration",
    ["FOV_Y"] = "fovY",
    ["FOV_Y_PLAYER_FIRST_PERSON"] = "fovYPlayerFirstPerson",
    ["FOV_Y_PLAYER_THIRD_PERSON"] = "fovYPlayerThirdPerson",
    ["UI_SCALE"] = "uiScale",
    ["ONLINE_PRESENCE_NAME"] = "onlinePresenceName",
    ["LAST_PLAYER_STYLE_MALE"] = "lastPlayerStyleMale",
    ["IS_TRAIN_TABBABLE"] = "isTrainTabbable",
    ["RADIO_VEHICLE_ONLY"] = "radioVehicleOnly",
    ["RADIO_IS_ACTIVE"] = "radioIsActive",
    ["USE_COLORBLIND_MODE"] = "useColorblindMode",
    ["EASY_ARM_CONTROL"] = "easyArmControl",
    ["USE_MILES"] = "useMiles",
    ["USE_FAHRENHEIT"] = "useFahrenheit",
    ["USE_ACRE"] = "useAcre",
    ["SHOW_TRIGGER_MARKER"] = "showTriggerMarker",
    ["SHOW_HELP_TRIGGER"] = "showHelpTrigger",
    ["SHOW_FIELD_INFO"] = "showFieldInfo",
    ["RESET_CAMERA"] = "resetCamera",
    ["USE_WORLD_CAMERA"] = "useWorldCamera",
    ["ACTIVE_SUSPENSION_CAMERA"] = "activeSuspensionCamera",
    ["CAMERA_CHECK_COLLISION"] = "cameraCheckCollision",
    ["INVERT_Y_LOOK"] = "invertYLook",
    ["STEERING_ASSIST_LINES"] = "steeringAssistLines",
    ["STEERING_ASSIST_CRUISE_CONTROL"] = "steeringAssistCruiseControl",
    ["DIRECTION_CHANGE_MODE"] = "directionChangeMode",
    ["GEAR_SHIFT_MODE"] = "gearShiftMode",
    ["HUD_SPEED_GAUGE"] = "hudSpeedGauge",
    ["WOOD_HARVESTER_AUTO_CUT"] = "woodHarvesterAutoCut",
    ["SHOW_HELP_ICONS"] = "showHelpIcons",
    ["SHOW_HELP_MENU"] = "showHelpMenu",
    ["VOLUME_RADIO"] = "radioVolume",
    ["VOLUME_VEHICLE"] = "vehicleVolume",
    ["VOLUME_ENVIRONMENT"] = "environmentVolume",
    ["VOLUME_CHARACTER"] = "characterVolume",
    ["VOLUME_GUI"] = "volumeGUI",
    ["VOLUME_NO_FOCUS"] = "volumeNoFocus",
    ["VOLUME_VOICE"] = "volumeVoice",
    ["VOLUME_VOICE_INPUT"] = "volumeVoiceInput",
    ["VOICE_MODE"] = "voiceMode",
    ["VOICE_INPUT_SENSITIVITY"] = "voiceInputThreshold",
    ["CAMERA_SENSITIVITY"] = "cameraSensitivity",
    ["CAMERA_ZOOM_SENSITIVITY"] = "cameraZoomSensitivity",
    ["JOYSTICK_DEADZONE"] = "joystickDeadzone",
    ["VEHICLE_ARM_SENSITIVITY"] = "vehicleArmSensitivity",
    ["REAL_BEACON_LIGHT_BRIGHTNESS"] = "realBeaconLightBrightness",
    ["STEERING_BACK_SPEED"] = "steeringBackSpeed",
    ["STEERING_SENSITIVITY"] = "steeringSensitivity",
    ["INGAME_MAP_STATE"] = "ingameMapState",
    ["INGAME_MAP_FILTER"] = "ingameMapFilter",
    ["MONEY_UNIT"] = "moneyUnit",
    ["VOLUME_MASTER"] = "masterVolume",
    ["VOLUME_MUSIC"] = "musicVolume",
    ["JOYSTICK_VIBRATION_ENABLED"] = "joystickVibrationEnabled",
    ["GYROSCOPE_STEERING"] = "gyroscopeSteering",
    ["CAMERA_TILTING"] = "cameraTilting",
    ["HINTS"] = "hints",
    ["SHOW_ALL_MODS"] = "showAllMods",
    ["SHOWN_FREEMODE_WARNING"] = "shownFreemodeWarning",
    ["SHOW_MULTIPLAYER_NAMES"] = "showMultiplayerNames",
    ["INGAME_MAP_GROWTH_FILTER"] = "ingameMapGrowthFilter",
    ["INGAME_MAP_SOIL_FILTER"] = "ingameMapSoilFilter",
    ["INGAME_MAP_FRUIT_FILTER"] = "ingameMapFruitFilter",
    ["INGAME_MAP_HOTSPOT_FILTER"] = "ingameMapHotspotFilter",
    ["FRAME_LIMIT"] = "frameLimit",
    ["CREATE_GAME"] = "createGame",
    ["JOIN_GAME"] = "joinGame",
    ["CUSTOM_COLORS"] = "customColors",
    ["ESRB_UPDATE_SHOWN"] = "wasESRBUpdateShown",
    ["SHOW_FISHING_INTRO"] = "showFishingIntro",
    ["PLAYED_MULTIPLAYER"] = "playedMultiplayer",
    ["TOTAL_PLAYED_SECONDS"] = "totalPlayedSeconds",
    ["STARTED_GUIDED_TOUR"] = "startedGuidedTour"
}
GameSettings.PERFORMANCE_CLASS_PRESETS = {
    {
        ["lightsProfile"] = GS_PROFILE_VERY_LOW,
        ["maxNumMirrors"] = 0,
        ["realBeaconLights"] = false
    },
    {
        ["lightsProfile"] = GS_PROFILE_LOW,
        ["maxNumMirrors"] = 0,
        ["realBeaconLights"] = false
    },
    {
        ["lightsProfile"] = GS_PROFILE_MEDIUM,
        ["maxNumMirrors"] = 3,
        ["realBeaconLights"] = false
    },
    {
        ["lightsProfile"] = GS_PROFILE_HIGH,
        ["maxNumMirrors"] = 4,
        ["realBeaconLights"] = false
    },
    {
        ["lightsProfile"] = GS_PROFILE_VERY_HIGH,
        ["maxNumMirrors"] = 5,
        ["realBeaconLights"] = false
    },
    {
        ["lightsProfile"] = GS_PROFILE_ULTRA,
        ["maxNumMirrors"] = 6,
        ["realBeaconLights"] = true
    }
}
function GameSettings.registerXMLPaths(xmlSchema)
    PlayerStyle.registerSavegameXMLPaths(xmlSchema, "gameSettings.lastPlayerStyle")
    LicensePlateManager.registerSavegameXMLpaths(xmlSchema, "gameSettings.lastCreatedLicensePlate")
    xmlSchema:register(XMLValueType.VECTOR_3, "gameSettings.customColors.color(?)#color", "Color values (sRGB)")
end
function GameSettings.new(customMt)
    -- upvalues: (copy) GameSettings_mt
    local self = setmetatable({}, customMt or GameSettings_mt)
    self.notifyOnChange = false
    self.joinGame = {}
    self.createGame = {}
    self.frameLimitValues = Platform.frameLimits
    self:setDefault()
    self.printedSettingsChanges = {
        [GameSettings.SETTING.VOLUME_MASTER] = "Setting \'Master Volume\': %.3f",
        [GameSettings.SETTING.VOLUME_MUSIC] = "Setting \'Music Volume\': %.3f",
        [GameSettings.SETTING.VOLUME_VEHICLE] = "Setting \'Vehicle Volume\': %.3f",
        [GameSettings.SETTING.VOLUME_ENVIRONMENT] = "Setting \'Environment Volume\': %.3f",
        [GameSettings.SETTING.VOLUME_CHARACTER] = "Setting \'Character Volume\': %.3f",
        [GameSettings.SETTING.VOLUME_RADIO] = "Setting \'Radio Volume\': %.3f",
        [GameSettings.SETTING.VOLUME_GUI] = "Setting \'GUI Volume\': %.3f",
        [GameSettings.SETTING.VOLUME_NO_FOCUS] = "Setting \'Game Volume While Not In Focus\': %.3f",
        [GameSettings.SETTING.SHOW_TRIGGER_MARKER] = "Setting \'Show Trigger Marker\': %s",
        [GameSettings.SETTING.SHOW_HELP_TRIGGER] = "Setting \'Show Help Trigger\': %s",
        [GameSettings.SETTING.IS_TRAIN_TABBABLE] = "Setting \'Is Train Tabbable\': %s",
        [GameSettings.SETTING.RADIO_IS_ACTIVE] = "Setting \'Radio Active\': %s",
        [GameSettings.SETTING.RADIO_VEHICLE_ONLY] = "Setting \'Radio Vehicle Only\': %s",
        [GameSettings.SETTING.SHOW_HELP_ICONS] = "Setting \'Show Help Icons\': %s",
        [GameSettings.SETTING.USE_COLORBLIND_MODE] = "Setting \'Use Colorblind Mode\': %s",
        [GameSettings.SETTING.EASY_ARM_CONTROL] = "Setting \'Easy Arm Control\': %s",
        [GameSettings.SETTING.INVERT_Y_LOOK] = "Setting \'Invert Y-Look\': %s",
        [GameSettings.SETTING.SHOW_FIELD_INFO] = "Setting \'Show Field-Info\': %s"
    }
    return self
end
function GameSettings:setDefault()
    self.joinGame = {}
    self.createGame = {}
    self[GameSettings.SETTING.FRAME_LIMIT] = Platform.defaultFrameLimit
    self[GameSettings.SETTING.DEFAULT_SERVER_PORT] = 10823
    self[GameSettings.SETTING.MAX_NUM_MIRRORS] = Platform.maxNumMirrors
    self[GameSettings.SETTING.LIGHTS_PROFILE] = GS_PROFILE_VERY_HIGH
    self[GameSettings.SETTING.REAL_BEACON_LIGHTS] = false
    self[GameSettings.SETTING.MP_LANGUAGE] = getSystemLanguage()
    self[GameSettings.SETTING.CAMERA_BOBBING] = true
    self[GameSettings.SETTING.INPUT_HELP_MODE] = GS_INPUT_HELP_MODE_AUTO
    self[GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED] = false
    self[GameSettings.SETTING.GAMEPAD_ENABLED_SET_BY_USER] = false
    self[GameSettings.SETTING.IS_GAMEPAD_ENABLED] = true
    self[GameSettings.SETTING.JOYSTICK_VIBRATION_ENABLED] = false
    self[GameSettings.SETTING.GYROSCOPE_STEERING] = Platform.gameplay.defaultGyroscopeSteering
    self[GameSettings.SETTING.HEAD_TRACKING_ENABLED_SET_BY_USER] = false
    self[GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED] = true
    self[GameSettings.SETTING.FORCE_FEEDBACK] = 0.5
    self[GameSettings.SETTING.MOTOR_STOP_TIMER_DURATION] = 30000
    self[GameSettings.SETTING.HORSE_ABANDON_TIMER_DURATION] = 30000
    self[GameSettings.SETTING.FOV_Y] = g_fovYDefault
    self[GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON] = 1.0471975511965976
    self[GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON] = 0.6981317007977318
    self[GameSettings.SETTING.UI_SCALE] = Platform.defaultUIScale
    self[GameSettings.SETTING.HINTS] = true
    self[GameSettings.SETTING.CAMERA_TILTING] = Platform.gameplay.defaultCameraTilt
    self[GameSettings.SETTING.SHOW_ALL_MODS] = true
    self[GameSettings.SETTING.ONLINE_PRESENCE_NAME] = string.trim(getUserName())
    self[GameSettings.SETTING.LAST_PLAYER_STYLE_MALE] = true
    self[GameSettings.SETTING.INVERT_Y_LOOK] = false
    self[GameSettings.SETTING.STEERING_ASSIST_LINES] = true
    self[GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL] = false
    self[GameSettings.SETTING.VOLUME_MASTER] = 1
    self[GameSettings.SETTING.VOLUME_MUSIC] = 0.45
    self[GameSettings.SETTING.VOLUME_VEHICLE] = 1
    self[GameSettings.SETTING.VOLUME_CHARACTER] = 0.7
    self[GameSettings.SETTING.VOLUME_ENVIRONMENT] = 0.7
    self[GameSettings.SETTING.VOLUME_RADIO] = 0.6
    self[GameSettings.SETTING.VOLUME_GUI] = 0.5
    self[GameSettings.SETTING.VOLUME_NO_FOCUS] = 1
    self[GameSettings.SETTING.VOLUME_VOICE] = 1
    self[GameSettings.SETTING.VOLUME_VOICE_INPUT] = 1
    self[GameSettings.SETTING.VOICE_MODE] = VoiceChatUtil.MODE.VOICE_ACTIVITY
    self[GameSettings.SETTING.VOICE_INPUT_SENSITIVITY] = 1
    self[GameSettings.SETTING.RADIO_IS_ACTIVE] = false
    self[GameSettings.SETTING.RADIO_VEHICLE_ONLY] = true
    self[GameSettings.SETTING.SHOW_HELP_ICONS] = true
    self[GameSettings.SETTING.USE_COLORBLIND_MODE] = false
    self[GameSettings.SETTING.EASY_ARM_CONTROL] = true
    self[GameSettings.SETTING.MONEY_UNIT] = GS_MONEY_EURO
    if GS_IS_MOBILE_VERSION then
        self[GameSettings.SETTING.MONEY_UNIT] = GS_MONEY_DOLLAR
    end
    self[GameSettings.SETTING.USE_MILES] = false
    self[GameSettings.SETTING.USE_FAHRENHEIT] = false
    self[GameSettings.SETTING.USE_ACRE] = false
    self[GameSettings.SETTING.SHOW_TRIGGER_MARKER] = true
    self[GameSettings.SETTING.SHOW_HELP_TRIGGER] = true
    self[GameSettings.SETTING.SHOW_FIELD_INFO] = true
    self[GameSettings.SETTING.RESET_CAMERA] = false
    self[GameSettings.SETTING.USE_WORLD_CAMERA] = true
    self[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA] = false
    self[GameSettings.SETTING.CAMERA_CHECK_COLLISION] = true
    self[GameSettings.SETTING.SHOW_HELP_MENU] = true
    self[GameSettings.SETTING.IS_TRAIN_TABBABLE] = true
    self[GameSettings.SETTING.CAMERA_SENSITIVITY] = 1
    self[GameSettings.SETTING.CAMERA_ZOOM_SENSITIVITY] = 1
    self[GameSettings.SETTING.JOYSTICK_DEADZONE] = 0.05
    self[GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY] = 1
    self[GameSettings.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS] = 1
    self[GameSettings.SETTING.STEERING_BACK_SPEED] = 7
    self[GameSettings.SETTING.STEERING_SENSITIVITY] = GS_IS_MOBILE_VERSION and 0.8 or 1
    self[GameSettings.SETTING.DIRECTION_CHANGE_MODE] = VehicleMotor.DIRECTION_CHANGE_MODE_AUTOMATIC
    self[GameSettings.SETTING.GEAR_SHIFT_MODE] = VehicleMotor.SHIFT_MODE_AUTOMATIC
    self[GameSettings.SETTING.HUD_SPEED_GAUGE] = SpeedMeterDisplay.GAUGE_MODE_RPM
    self[GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT] = true
    self[GameSettings.SETTING.INGAME_MAP_FILTER] = 0
    self[GameSettings.SETTING.INGAME_MAP_SOIL_FILTER] = 4294967295
    self[GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER] = 4294967295
    self[GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER] = 4294967295
    self[GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER] = ""
    self[GameSettings.SETTING.INGAME_MAP_STATE] = GS_IS_MOBILE_VERSION and IngameMapState.OFF or IngameMapState.MINIMAP_ROUND
    self[GameSettings.SETTING.SHOWN_FREEMODE_WARNING] = false
    self[GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES] = true
    self[GameSettings.SETTING.CUSTOM_COLORS] = {}
    self[GameSettings.SETTING.ESRB_UPDATE_SHOWN] = false
    self[GameSettings.SETTING.SHOW_FISHING_INTRO] = true
    self[GameSettings.SETTING.PLAYED_MULTIPLAYER] = false
    self[GameSettings.SETTING.TOTAL_PLAYED_SECONDS] = -1
    self[GameSettings.SETTING.STARTED_GUIDED_TOUR] = false
    if GS_IS_CONSOLE_VERSION then
        self[GameSettings.SETTING.IS_GAMEPAD_ENABLED] = true
        self[GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED] = false
        self[GameSettings.SETTING.INPUT_HELP_MODE] = GS_INPUT_HELP_MODE_GAMEPAD
    end
end
function GameSettings:getTableValue(name, tableKey)
    if name == nil then
        Logging.error("GameSetting table name missing or nil!")
        return false
    end
    if tableKey ~= nil then
        return self[name][tableKey]
    end
    Logging.error("GameSetting table tableKey missing or nil!")
    return false
end
function GameSettings:setTableValue(name, tableKey, value, doSave)
    if name == nil then
        printError("Error: GameSetting table name missing or nil!")
        return false
    end
    if tableKey == nil then
        printError("Error: GameSetting tableKey missing or nil!")
        return false
    end
    if value == nil then
        printError("Error: GameSetting table value missing or nil for index \'" .. tableKey .. "\'!")
        return false
    end
    if self[name] == nil then
        printError("Error: GameSetting table \'" .. name .. "\' not found!")
        return false
    end
    self[name][tableKey] = value
    if doSave then
        self:save()
    end
    return true
end
function GameSettings:getValue(name)
    if name ~= nil then
        return self[name]
    end
    Logging.error("GameSetting %s missing or nil!", name)
    printCallstack()
    return false
end
function GameSettings:setValue(name, value, doSave)
    if name == nil then
        Logging.error("GameSetting %s missing or nil!", name)
        printCallstack()
        return false
    end
    if value == nil then
        Logging.error("GameSetting value missing or nil for setting \'%s\'!", name)
        printCallstack()
        return false
    end
    if self[name] == nil then
        Logging.error("GameSetting \'" .. name .. "\' not found!")
        return false
    end
    self[name] = value
    if self.printedSettingsChanges[name] ~= nil then
        print("  " .. string.format(self.printedSettingsChanges[name], value))
    end
    if self.notifyOnChange then
        g_messageCenter:publish(MessageType.SETTING_CHANGED[name], value)
    end
    if doSave then
        self:save()
    end
    return true
end
function GameSettings:loadFromXML(xmlFile)
    if xmlFile ~= nil then
        if GS_PLATFORM_PC then
            local motorStopTimerDuration = GameSettings.SETTING.DEFAULT_SERVER_PORT
            local isGamepadEnabled = getXMLInt(xmlFile, "gameSettings.defaultMultiplayerPort") or 10823
            self:setValue(motorStopTimerDuration, (math.clamp(isGamepadEnabled, 0, 65535)))
            local preset = GameSettings.PERFORMANCE_CLASS_PRESETS[Utils.getPerformanceClassId()]
            local horseAbandonTimerDuration = GameSettings.SETTING.MAX_NUM_MIRRORS
            local onlinePresenceName = getXMLInt(xmlFile, "gameSettings.maxNumMirrors") or preset.maxNumMirrors
            self:setValue(horseAbandonTimerDuration, (math.clamp(onlinePresenceName, 0, 7)))
            local horseAbandonTimerDuration = GameSettings.SETTING.LIGHTS_PROFILE
            local onlinePresenceName = getXMLInt(xmlFile, "gameSettings.lightsProfile") or preset.lightsProfile
            self:setValue(horseAbandonTimerDuration, (math.clamp(onlinePresenceName, GS_PROFILE_LOW, GS_PROFILE_ULTRA)))
            local isHeadTrackingEnabled = getXMLBool(xmlFile, "gameSettings.isHeadTrackingEnabled")
            if isHeadTrackingEnabled ~= nil then
                self:setValue(GameSettings.SETTING.HEAD_TRACKING_ENABLED_SET_BY_USER, true)
                self:setValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED, isHeadTrackingEnabled)
            end
            self:setValue(GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.soundPlayer#allowStreams"), self[GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED]))
            local motorStopTimerDuration = getXMLInt(xmlFile, "gameSettings.motorStopTimerDuration")
            if motorStopTimerDuration ~= nil then
                self:setValue(GameSettings.SETTING.MOTOR_STOP_TIMER_DURATION, motorStopTimerDuration * 1000)
            end
            local horseAbandonTimerDuration = getXMLInt(xmlFile, "gameSettings.horseAbandonTimerDuration")
            if horseAbandonTimerDuration ~= nil then
                self:setValue(GameSettings.SETTING.HORSE_ABANDON_TIMER_DURATION, horseAbandonTimerDuration * 1000)
            end
            local isGamepadEnabled = getXMLBool(xmlFile, "gameSettings.isGamepadEnabled")
            if isGamepadEnabled ~= nil then
                self:setValue(GameSettings.SETTING.GAMEPAD_ENABLED_SET_BY_USER, true)
                self:setValue(GameSettings.SETTING.IS_GAMEPAD_ENABLED, isGamepadEnabled)
            end
        end
        self:setValue(GameSettings.SETTING.REAL_BEACON_LIGHTS, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.realBeaconLights"), self[GameSettings.SETTING.REAL_BEACON_LIGHTS]))
        if GS_PLATFORM_PC then
            local preset = getXMLInt(xmlFile, "gameSettings.mpLanguage")
            if preset ~= nil and (preset >= 0 and preset <= getNumOfLanguages() - 1) then
                self:setValue(GameSettings.SETTING.MP_LANGUAGE, preset)
            end
            local isHeadTrackingEnabled = getXMLInt(xmlFile, "gameSettings.inputHelpMode")
            if isHeadTrackingEnabled ~= nil then
                if isHeadTrackingEnabled == GS_INPUT_HELP_MODE_AUTO or (isHeadTrackingEnabled == GS_INPUT_HELP_MODE_GAMEPAD or isHeadTrackingEnabled == GS_INPUT_HELP_MODE_KEYBOARD) then
                    self:setValue(GameSettings.SETTING.INPUT_HELP_MODE, isHeadTrackingEnabled)
                    if not getGamepadEnabled() and isHeadTrackingEnabled == GS_INPUT_HELP_MODE_GAMEPAD then
                        self:setValue(GameSettings.SETTING.INPUT_HELP_MODE, GS_INPUT_HELP_MODE_AUTO)
                    end
                else
                    printWarning("Warning: Invalid input help mode")
                end
            end
        end
        local preset = getXMLFloat(xmlFile, "gameSettings.fovY")
        if preset ~= nil then
            local onlinePresenceName = math.rad(preset)
            self:setValue(GameSettings.SETTING.FOV_Y, (math.clamp(onlinePresenceName, g_fovYMin, g_fovYMax)))
        end
        local isHeadTrackingEnabled = getXMLFloat(xmlFile, "gameSettings.fovY#playerFirstPerson")
        if isHeadTrackingEnabled ~= nil then
            local found = math.rad(isHeadTrackingEnabled)
            self:setValue(GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON, (math.clamp(found, g_fovYMin, g_fovYMax)))
        end
        local motorStopTimerDuration = getXMLFloat(xmlFile, "gameSettings.fovY#playerThirdPerson")
        if motorStopTimerDuration ~= nil then
            self:setValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON, (math.clamp(math.rad(motorStopTimerDuration), g_fovYMin, g_fovYMax)))
        end
        local horseAbandonTimerDuration = getXMLFloat(xmlFile, "gameSettings.uiScale")
        if horseAbandonTimerDuration ~= nil then
            self:setValue(GameSettings.SETTING.UI_SCALE, (math.clamp(horseAbandonTimerDuration, 0.5, 1.5)))
        end
        local isGamepadEnabled = getXMLBool(xmlFile, "gameSettings.showAllMods")
        if isGamepadEnabled ~= nil then
            self:setValue(GameSettings.SETTING.SHOW_ALL_MODS, isGamepadEnabled)
        end
        if not GS_IS_CONSOLE_VERSION then
            local onlinePresenceName = getXMLString(xmlFile, "gameSettings.onlinePresenceName")
            if onlinePresenceName ~= nil then
                if onlinePresenceName == "" then
                    onlinePresenceName = string.trim(getUserName())
                end
                self:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, onlinePresenceName)
            end
        end
        self:setValue(GameSettings.SETTING.LAST_PLAYER_STYLE_MALE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.player#lastPlayerStyleMale"), self[GameSettings.SETTING.LAST_PLAYER_STYLE_MALE]))
        self:setTableValueFromXML(GameSettings.SETTING.JOIN_GAME, "password", getXMLString, xmlFile, "gameSettings.joinGame#password")
        self:setTableValueFromXML(GameSettings.SETTING.JOIN_GAME, "includePasswordProtected", getXMLBool, xmlFile, "gameSettings.joinGame#includePasswordProtected")
        self:setTableValueFromXML(GameSettings.SETTING.JOIN_GAME, "includeFullGames", getXMLBool, xmlFile, "gameSettings.joinGame#includeFullGames")
        self:setTableValueFromXML(GameSettings.SETTING.JOIN_GAME, "onlyWithAllModsAvailable", getXMLBool, xmlFile, "gameSettings.joinGame#onlyWithAllModsAvailable")
        self:setTableValueFromXML(GameSettings.SETTING.JOIN_GAME, "serverName", getXMLString, xmlFile, "gameSettings.joinGame#serverName")
        self:setTableValueFromXML(GameSettings.SETTING.JOIN_GAME, "mapId", getXMLString, xmlFile, "gameSettings.joinGame#mapId")
        self:setTableValueFromXML(GameSettings.SETTING.JOIN_GAME, "language", getXMLInt, xmlFile, "gameSettings.joinGame#language")
        self:setTableValueFromXML(GameSettings.SETTING.JOIN_GAME, "capacity", getXMLInt, xmlFile, "gameSettings.joinGame#capacity")
        self:setTableValueFromXML(GameSettings.SETTING.JOIN_GAME, "allowCrossPlay", getXMLBool, xmlFile, "gameSettings.joinGame#allowCrossPlay")
        self:setTableValueFromXML(GameSettings.SETTING.CREATE_GAME, "password", getXMLString, xmlFile, "gameSettings.createGame#password")
        if not GS_IS_CONSOLE_VERSION then
            self:setTableValueFromXML(GameSettings.SETTING.CREATE_GAME, "serverName", getXMLString, xmlFile, "gameSettings.createGame#name")
        end
        self:setTableValueFromXML(GameSettings.SETTING.CREATE_GAME, "port", getXMLInt, xmlFile, "gameSettings.createGame#port")
        self:setTableValueFromXML(GameSettings.SETTING.CREATE_GAME, "autoAccept", getXMLBool, xmlFile, "gameSettings.createGame#autoAccept")
        self:setTableValueFromXML(GameSettings.SETTING.CREATE_GAME, "autoSave", getXMLBool, xmlFile, "gameSettings.createGame#autoSave")
        self:setTableValueFromXML(GameSettings.SETTING.CREATE_GAME, "allowOnlyFriends", getXMLBool, xmlFile, "gameSettings.createGame#allowOnlyFriends")
        self:setTableValueFromXML(GameSettings.SETTING.CREATE_GAME, "allowCrossPlay", getXMLBool, xmlFile, "gameSettings.createGame#allowCrossPlay")
        self:setTableValueFromXML(GameSettings.SETTING.CREATE_GAME, "capacity", getXMLInt, xmlFile, "gameSettings.createGame#capacity")
        self:setTableValueFromXML(GameSettings.SETTING.CREATE_GAME, "bandwidth", getXMLInt, xmlFile, "gameSettings.createGame#bandwidth")
        self:setTableValueFromXML(GameSettings.SETTING.CREATE_GAME, "allowCrossPlay", getXMLBool, xmlFile, "gameSettings.createGame#allowCrossPlay")
        self:setValue(GameSettings.SETTING.IS_TRAIN_TABBABLE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.isTrainTabbable"), self[GameSettings.SETTING.IS_TRAIN_TABBABLE]))
        self:setValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.radioVehicleOnly"), self[GameSettings.SETTING.RADIO_VEHICLE_ONLY]))
        self:setValue(GameSettings.SETTING.RADIO_IS_ACTIVE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.radioIsActive"), self[GameSettings.SETTING.RADIO_IS_ACTIVE]))
        self:setValue(GameSettings.SETTING.USE_COLORBLIND_MODE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.useColorblindMode"), self[GameSettings.SETTING.USE_COLORBLIND_MODE]))
        self:setValue(GameSettings.SETTING.EASY_ARM_CONTROL, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.easyArmControl"), self[GameSettings.SETTING.EASY_ARM_CONTROL]))
        self:setValue(GameSettings.SETTING.SHOW_TRIGGER_MARKER, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showTriggerMarker"), self[GameSettings.SETTING.SHOW_TRIGGER_MARKER]))
        self:setValue(GameSettings.SETTING.SHOW_HELP_TRIGGER, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showHelpTrigger"), self[GameSettings.SETTING.SHOW_HELP_TRIGGER]))
        self:setValue(GameSettings.SETTING.SHOW_FIELD_INFO, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showFieldInfo"), self[GameSettings.SETTING.SHOW_FIELD_INFO]))
        self:setValue(GameSettings.SETTING.RESET_CAMERA, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.resetCamera"), self[GameSettings.SETTING.RESET_CAMERA]))
        self:setValue(GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.activeSuspensionCamera"), self[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA]))
        self:setValue(GameSettings.SETTING.CAMERA_CHECK_COLLISION, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.cameraCheckCollision"), self[GameSettings.SETTING.CAMERA_CHECK_COLLISION]))
        self:setValue(GameSettings.SETTING.USE_WORLD_CAMERA, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.useWorldCamera"), self[GameSettings.SETTING.USE_WORLD_CAMERA]))
        self:setValue(GameSettings.SETTING.INVERT_Y_LOOK, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.invertYLook"), self[GameSettings.SETTING.INVERT_Y_LOOK]))
        self:setValue(GameSettings.SETTING.STEERING_ASSIST_LINES, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.steeringAssistLines"), self[GameSettings.SETTING.STEERING_ASSIST_LINES]))
        self:setValue(GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.steeringAssistCruiseControl"), self[GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL]))
        self:setValue(GameSettings.SETTING.SHOW_HELP_ICONS, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showHelpIcons"), self[GameSettings.SETTING.SHOW_HELP_ICONS]))
        self:setValue(GameSettings.SETTING.SHOW_HELP_MENU, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showHelpMenu"), self[GameSettings.SETTING.SHOW_HELP_MENU]))
        self:setValue(GameSettings.SETTING.VOLUME_RADIO, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.radio"), self[GameSettings.SETTING.VOLUME_RADIO]))
        self:setValue(GameSettings.SETTING.VOLUME_VEHICLE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.vehicle"), self[GameSettings.SETTING.VOLUME_VEHICLE]))
        self:setValue(GameSettings.SETTING.VOLUME_ENVIRONMENT, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.environment"), self[GameSettings.SETTING.VOLUME_ENVIRONMENT]))
        self:setValue(GameSettings.SETTING.VOLUME_CHARACTER, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.character"), self[GameSettings.SETTING.VOLUME_CHARACTER]))
        self:setValue(GameSettings.SETTING.VOLUME_GUI, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.gui"), self[GameSettings.SETTING.VOLUME_GUI]))
        self:setValue(GameSettings.SETTING.VOLUME_NO_FOCUS, getInactiveWindowAudioVolume())
        self:setValue(GameSettings.SETTING.VOLUME_MASTER, getMasterVolume())
        self:setValue(GameSettings.SETTING.VOLUME_MUSIC, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.music"), self[GameSettings.SETTING.VOLUME_MUSIC]))
        self:setValue(GameSettings.SETTING.VOLUME_VOICE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.voice"), self[GameSettings.SETTING.VOLUME_VOICE]))
        self:setValue(GameSettings.SETTING.VOLUME_VOICE_INPUT, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.voiceInput"), self[GameSettings.SETTING.VOLUME_VOICE_INPUT]))
        self:setValue(GameSettings.SETTING.VOICE_MODE, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.voice#mode"), self[GameSettings.SETTING.VOICE_MODE]))
        self:setValue(GameSettings.SETTING.VOICE_INPUT_SENSITIVITY, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.voice#inputSensitivity"), self[GameSettings.SETTING.VOICE_INPUT_SENSITIVITY]))
        self:setValue(GameSettings.SETTING.FORCE_FEEDBACK, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.forceFeedback"), self[GameSettings.SETTING.FORCE_FEEDBACK]))
        self:setValue(GameSettings.SETTING.SHOWN_FREEMODE_WARNING, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.shownFreemodeWarning"), self[GameSettings.SETTING.SHOWN_FREEMODE_WARNING]))
        self:setValue(GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showMultiplayerNames"), self[GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES]))
        self:setValue(GameSettings.SETTING.CAMERA_SENSITIVITY, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.cameraSensitivity"), self[GameSettings.SETTING.CAMERA_SENSITIVITY]))
        self:setValue(GameSettings.SETTING.CAMERA_ZOOM_SENSITIVITY, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.cameraZoomSensitivity"), self[GameSettings.SETTING.CAMERA_ZOOM_SENSITIVITY]))
        self:setValue(GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.vehicleArmSensitivity"), self[GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY]))
        self:setValue(GameSettings.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.realBeaconLightBrightness"), self[GameSettings.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS]))
        self:setValue(GameSettings.SETTING.STEERING_BACK_SPEED, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.steeringBackSpeed"), self[GameSettings.SETTING.STEERING_BACK_SPEED]))
        self:setValue(GameSettings.SETTING.STEERING_SENSITIVITY, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.steeringSensitivity"), self[GameSettings.SETTING.STEERING_SENSITIVITY]))
        self:setValue(GameSettings.SETTING.DIRECTION_CHANGE_MODE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.directionChangeMode"), self[GameSettings.SETTING.DIRECTION_CHANGE_MODE]))
        self:setValue(GameSettings.SETTING.GEAR_SHIFT_MODE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.gearShiftMode"), self[GameSettings.SETTING.GEAR_SHIFT_MODE]))
        self:setValue(GameSettings.SETTING.HUD_SPEED_GAUGE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.hudSpeedGauge"), self[GameSettings.SETTING.HUD_SPEED_GAUGE]))
        self:setValue(GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.woodHarvesterAutoCut"), self[GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT]))
        self:setValue(GameSettings.SETTING.INGAME_MAP_STATE, Utils.getNoNil(IngameMapState.getByName(getXMLString(xmlFile, "gameSettings.ingameMapState")), self[GameSettings.SETTING.INGAME_MAP_STATE]))
        self:setValue(GameSettings.SETTING.INGAME_MAP_FILTER, Utils.getNoNil(getXMLUInt(xmlFile, "gameSettings.ingameMapFilters"), self[GameSettings.SETTING.INGAME_MAP_FILTER]))
        self:setValue(GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER, Utils.getNoNil(getXMLUInt(xmlFile, "gameSettings.ingameMapGrowthFilter"), self[GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER]))
        self:setValue(GameSettings.SETTING.INGAME_MAP_SOIL_FILTER, Utils.getNoNil(getXMLUInt(xmlFile, "gameSettings.ingameMapSoilFilter"), self[GameSettings.SETTING.INGAME_MAP_SOIL_FILTER]))
        self:setValue(GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER, Utils.getNoNil(getXMLUInt(xmlFile, "gameSettings.ingameMapHotspotFilter"), self[GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER]))
        self:setValue(GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER, Utils.getNoNil(getXMLString(xmlFile, "gameSettings.ingameMapFruitFilter"), self[GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER]))
        self:setValue(GameSettings.SETTING.MONEY_UNIT, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.units.money"), self[GameSettings.SETTING.MONEY_UNIT]))
        self:setValue(GameSettings.SETTING.USE_MILES, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.units.miles"), self[GameSettings.SETTING.USE_MILES]))
        self:setValue(GameSettings.SETTING.USE_FAHRENHEIT, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.units.fahrenheit"), self[GameSettings.SETTING.USE_FAHRENHEIT]))
        self:setValue(GameSettings.SETTING.USE_ACRE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.units.acre"), self[GameSettings.SETTING.USE_ACRE]))
        self:setValue(GameSettings.SETTING.GYROSCOPE_STEERING, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.gyroscopeSteering"), self[GameSettings.SETTING.GYROSCOPE_STEERING]))
        self:setValue(GameSettings.SETTING.HINTS, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.hints"), self[GameSettings.SETTING.HINTS]))
        self:setValue(GameSettings.SETTING.CAMERA_TILTING, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.cameraTilting"), self[GameSettings.SETTING.CAMERA_TILTING]))
        self:setValue(GameSettings.SETTING.CAMERA_BOBBING, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.cameraBobbing"), self[GameSettings.SETTING.CAMERA_BOBBING]))
        self:setValue(GameSettings.SETTING.ESRB_UPDATE_SHOWN, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.wasESRBUpdateShown"), self[GameSettings.SETTING.ESRB_UPDATE_SHOWN]))
        self:setValue(GameSettings.SETTING.SHOW_FISHING_INTRO, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showFishingIntro"), self[GameSettings.SETTING.SHOW_FISHING_INTRO]))
        self:setValue(GameSettings.SETTING.PLAYED_MULTIPLAYER, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.recommender#playedMultiplayer"), self[GameSettings.SETTING.PLAYED_MULTIPLAYER]))
        self:setValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.recommender#totalPlayedSeconds"), self[GameSettings.SETTING.TOTAL_PLAYED_SECONDS]))
        self:setValue(GameSettings.SETTING.STARTED_GUIDED_TOUR, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.recommender#startedGuidedTour"), self[GameSettings.SETTING.STARTED_GUIDED_TOUR]))
        if Platform.hasAdjustableFrameLimit then
            local onlinePresenceName = getXMLInt(xmlFile, "gameSettings.frameLimit") or self[GameSettings.SETTING.FRAME_LIMIT]
            local found = false
            for _, value in ipairs(self.frameLimitValues) do
                if value == onlinePresenceName then
                    found = true
                    break
                end
            end
            if not found then
                onlinePresenceName = self[GameSettings.SETTING.FRAME_LIMIT]
            end
            self:setValue(GameSettings.SETTING.FRAME_LIMIT, onlinePresenceName)
        end
        local onlinePresenceName = XMLFile.wrap(xmlFile, GameSettings.xmlSchema)
        self.lastCreatedLicensePlate = g_licensePlateManager.loadLicensePlateDataFromXML(onlinePresenceName, "gameSettings.lastCreatedLicensePlate", true)
        if onlinePresenceName:hasProperty("gameSettings.lastPlayerStyle") then
            local found = PlayerStyle.new()
            if found:loadFromXMLFile(onlinePresenceName, "gameSettings.lastPlayerStyle") then
                self.lastPlayerStyle = found
            else
                found:delete()
            end
        end
        local found = {}
        for _, value in onlinePresenceName:iterator("gameSettings.customColors.color") do
            local name = onlinePresenceName:getString(value .. "#name")
            local materialName = onlinePresenceName:getString(value .. "#materialName", nil, true)
            local color = onlinePresenceName:getValue(value .. "#color", nil, true)
            if color ~= nil then
                table.insert(found, {
                    ["name"] = name,
                    ["color"] = color,
                    ["materialName"] = materialName
                })
            end
        end
        self:setValue(GameSettings.SETTING.CUSTOM_COLORS, found)
        onlinePresenceName:delete()
        self.notifyOnChange = true
    end
end
function GameSettings:setTableValueFromXML(tableName, tableKey, xmlFunc, xmlFile, xmlPath)
    local value = xmlFunc(xmlFile, xmlPath)
    if value ~= nil then
        self:setTableValue(tableName, tableKey, value)
    end
end
function GameSettings:save()
    self:saveToXMLFile(g_savegameXML)
end
function GameSettings:saveToXMLFile(xmlFile)
    if xmlFile ~= nil then
        setXMLBool(xmlFile, "gameSettings.invertYLook", self[GameSettings.SETTING.INVERT_Y_LOOK])
        setXMLBool(xmlFile, "gameSettings.isHeadTrackingEnabled", self[GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED])
        setXMLFloat(xmlFile, "gameSettings.forceFeedback", self[GameSettings.SETTING.FORCE_FEEDBACK])
        setXMLBool(xmlFile, "gameSettings.isGamepadEnabled", self[GameSettings.SETTING.IS_GAMEPAD_ENABLED])
        setXMLFloat(xmlFile, "gameSettings.cameraSensitivity", self[GameSettings.SETTING.CAMERA_SENSITIVITY])
        setXMLFloat(xmlFile, "gameSettings.vehicleArmSensitivity", self[GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY])
        setXMLFloat(xmlFile, "gameSettings.realBeaconLightBrightness", self[GameSettings.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS])
        setXMLFloat(xmlFile, "gameSettings.steeringBackSpeed", self[GameSettings.SETTING.STEERING_BACK_SPEED])
        setXMLFloat(xmlFile, "gameSettings.steeringSensitivity", self[GameSettings.SETTING.STEERING_SENSITIVITY])
        setXMLInt(xmlFile, "gameSettings.inputHelpMode", self[GameSettings.SETTING.INPUT_HELP_MODE])
        setXMLBool(xmlFile, "gameSettings.easyArmControl", self[GameSettings.SETTING.EASY_ARM_CONTROL])
        setXMLBool(xmlFile, "gameSettings.gyroscopeSteering", self[GameSettings.SETTING.GYROSCOPE_STEERING])
        setXMLBool(xmlFile, "gameSettings.hints", self[GameSettings.SETTING.HINTS])
        setXMLBool(xmlFile, "gameSettings.cameraTilting", self[GameSettings.SETTING.CAMERA_TILTING])
        if Platform.hasAdjustableFrameLimit then
            setXMLInt(xmlFile, "gameSettings.frameLimit", self[GameSettings.SETTING.FRAME_LIMIT])
        end
        setXMLBool(xmlFile, "gameSettings.showAllMods", self[GameSettings.SETTING.SHOW_ALL_MODS])
        setXMLString(xmlFile, "gameSettings.onlinePresenceName", self[GameSettings.SETTING.ONLINE_PRESENCE_NAME])
        setXMLBool(xmlFile, "gameSettings.player#lastPlayerStyleMale", self[GameSettings.SETTING.LAST_PLAYER_STYLE_MALE])
        setXMLInt(xmlFile, "gameSettings.mpLanguage", self[GameSettings.SETTING.MP_LANGUAGE])
        self:setXMLValue(xmlFile, setXMLString, "gameSettings.createGame#password", self.createGame.password)
        self:setXMLValue(xmlFile, setXMLString, "gameSettings.createGame#name", self.createGame.serverName)
        self:setXMLValue(xmlFile, setXMLInt, "gameSettings.createGame#port", self.createGame.port)
        self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#autoAccept", self.createGame.autoAccept)
        self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#autoSave", self.createGame.autoSave)
        self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#allowOnlyFriends", self.createGame.allowOnlyFriends)
        self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#allowCrossPlay", self.createGame.allowCrossPlay)
        self:setXMLValue(xmlFile, setXMLInt, "gameSettings.createGame#capacity", self.createGame.capacity)
        self:setXMLValue(xmlFile, setXMLInt, "gameSettings.createGame#bandwidth", self.createGame.bandwidth)
        self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#allowCrossPlay", self.createGame.allowCrossPlay)
        self:setXMLValue(xmlFile, setXMLString, "gameSettings.joinGame#password", self.joinGame.password)
        self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#includePasswordProtected", self.joinGame.includePasswordProtected)
        self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#includeFullGames", self.joinGame.includeFullGames)
        self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#onlyWithAllModsAvailable", self.joinGame.onlyWithAllModsAvailable)
        self:setXMLValue(xmlFile, setXMLString, "gameSettings.joinGame#serverName", self.joinGame.serverName)
        self:setXMLValue(xmlFile, setXMLString, "gameSettings.joinGame#mapId", self.joinGame.mapId)
        self:setXMLValue(xmlFile, setXMLInt, "gameSettings.joinGame#language", self.joinGame.language)
        self:setXMLValue(xmlFile, setXMLInt, "gameSettings.joinGame#capacity", self.joinGame.capacity)
        self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#allowCrossPlay", self.joinGame.allowCrossPlay)
        setXMLFloat(xmlFile, "gameSettings.volume.music", self[GameSettings.SETTING.VOLUME_MUSIC])
        setXMLFloat(xmlFile, "gameSettings.volume.vehicle", self[GameSettings.SETTING.VOLUME_VEHICLE])
        setXMLFloat(xmlFile, "gameSettings.volume.environment", self[GameSettings.SETTING.VOLUME_ENVIRONMENT])
        setXMLFloat(xmlFile, "gameSettings.volume.character", self[GameSettings.SETTING.VOLUME_CHARACTER])
        setXMLFloat(xmlFile, "gameSettings.volume.radio", self[GameSettings.SETTING.VOLUME_RADIO])
        setXMLFloat(xmlFile, "gameSettings.volume.gui", self[GameSettings.SETTING.VOLUME_GUI])
        setXMLFloat(xmlFile, "gameSettings.volume.noFocus", self[GameSettings.SETTING.VOLUME_NO_FOCUS])
        setXMLFloat(xmlFile, "gameSettings.volume.voice", self[GameSettings.SETTING.VOLUME_VOICE])
        setXMLFloat(xmlFile, "gameSettings.volume.voiceInput", self[GameSettings.SETTING.VOLUME_VOICE_INPUT])
        setXMLBool(xmlFile, "gameSettings.soundPlayer#allowStreams", self[GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED])
        setXMLBool(xmlFile, "gameSettings.radioIsActive", self[GameSettings.SETTING.RADIO_IS_ACTIVE])
        setXMLBool(xmlFile, "gameSettings.radioVehicleOnly", self[GameSettings.SETTING.RADIO_VEHICLE_ONLY])
        setXMLInt(xmlFile, "gameSettings.voice#mode", self[GameSettings.SETTING.VOICE_MODE])
        setXMLInt(xmlFile, "gameSettings.voice#inputSensitivity", self[GameSettings.SETTING.VOICE_INPUT_SENSITIVITY])
        setXMLInt(xmlFile, "gameSettings.units.money", self[GameSettings.SETTING.MONEY_UNIT])
        setXMLBool(xmlFile, "gameSettings.units.miles", self[GameSettings.SETTING.USE_MILES])
        setXMLBool(xmlFile, "gameSettings.units.fahrenheit", self[GameSettings.SETTING.USE_FAHRENHEIT])
        setXMLBool(xmlFile, "gameSettings.units.acre", self[GameSettings.SETTING.USE_ACRE])
        setXMLBool(xmlFile, "gameSettings.isTrainTabbable", self[GameSettings.SETTING.IS_TRAIN_TABBABLE])
        setXMLBool(xmlFile, "gameSettings.showTriggerMarker", self[GameSettings.SETTING.SHOW_TRIGGER_MARKER])
        setXMLBool(xmlFile, "gameSettings.showHelpTrigger", self[GameSettings.SETTING.SHOW_HELP_TRIGGER])
        setXMLBool(xmlFile, "gameSettings.showFieldInfo", self[GameSettings.SETTING.SHOW_FIELD_INFO])
        setXMLBool(xmlFile, "gameSettings.showHelpIcons", self[GameSettings.SETTING.SHOW_HELP_ICONS])
        setXMLBool(xmlFile, "gameSettings.showHelpMenu", self[GameSettings.SETTING.SHOW_HELP_MENU])
        setXMLBool(xmlFile, "gameSettings.resetCamera", self[GameSettings.SETTING.RESET_CAMERA])
        setXMLBool(xmlFile, "gameSettings.activeSuspensionCamera", self[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA])
        setXMLBool(xmlFile, "gameSettings.cameraCheckCollision", self[GameSettings.SETTING.CAMERA_CHECK_COLLISION])
        setXMLBool(xmlFile, "gameSettings.useWorldCamera", self[GameSettings.SETTING.USE_WORLD_CAMERA])
        setXMLString(xmlFile, "gameSettings.ingameMapState", IngameMapState.getName(self[GameSettings.SETTING.INGAME_MAP_STATE]))
        setXMLUInt(xmlFile, "gameSettings.ingameMapFilters", self[GameSettings.SETTING.INGAME_MAP_FILTER])
        setXMLInt(xmlFile, "gameSettings.directionChangeMode", self[GameSettings.SETTING.DIRECTION_CHANGE_MODE])
        setXMLInt(xmlFile, "gameSettings.gearShiftMode", self[GameSettings.SETTING.GEAR_SHIFT_MODE])
        setXMLInt(xmlFile, "gameSettings.hudSpeedGauge", self[GameSettings.SETTING.HUD_SPEED_GAUGE])
        setXMLBool(xmlFile, "gameSettings.woodHarvesterAutoCut", self[GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT])
        setXMLBool(xmlFile, "gameSettings.shownFreemodeWarning", self[GameSettings.SETTING.SHOWN_FREEMODE_WARNING])
        setXMLBool(xmlFile, "gameSettings.showMultiplayerNames", self[GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES])
        setXMLUInt(xmlFile, "gameSettings.ingameMapGrowthFilter", self[GameSettings.SETTING.INGAME_MAP_GROWTH_FILTER])
        setXMLUInt(xmlFile, "gameSettings.ingameMapSoilFilter", self[GameSettings.SETTING.INGAME_MAP_SOIL_FILTER])
        setXMLUInt(xmlFile, "gameSettings.ingameMapHotspotFilter", self[GameSettings.SETTING.INGAME_MAP_HOTSPOT_FILTER])
        setXMLString(xmlFile, "gameSettings.ingameMapFruitFilter", self[GameSettings.SETTING.INGAME_MAP_FRUIT_FILTER])
        setXMLBool(xmlFile, "gameSettings.wasESRBUpdateShown", self[GameSettings.SETTING.ESRB_UPDATE_SHOWN])
        if not self[GameSettings.SETTING.SHOW_FISHING_INTRO] then
            setXMLBool(xmlFile, "gameSettings.showFishingIntro", self[GameSettings.SETTING.SHOW_FISHING_INTRO])
        end
        setXMLBool(xmlFile, "gameSettings.recommender#playedMultiplayer", self[GameSettings.SETTING.PLAYED_MULTIPLAYER])
        setXMLInt(xmlFile, "gameSettings.recommender#totalPlayedSeconds", self[GameSettings.SETTING.TOTAL_PLAYED_SECONDS])
        setXMLBool(xmlFile, "gameSettings.recommender#startedGuidedTour", self[GameSettings.SETTING.STARTED_GUIDED_TOUR])
        setXMLBool(xmlFile, "gameSettings.useColorblindMode", self[GameSettings.SETTING.USE_COLORBLIND_MODE])
        setXMLInt(xmlFile, "gameSettings.maxNumMirrors", self[GameSettings.SETTING.MAX_NUM_MIRRORS])
        setXMLInt(xmlFile, "gameSettings.lightsProfile", self[GameSettings.SETTING.LIGHTS_PROFILE])
        local wrapped = setXMLFloat
        wrapped(xmlFile, "gameSettings.fovY", (math.deg(self[GameSettings.SETTING.FOV_Y])))
        local wrapped = setXMLFloat
        wrapped(xmlFile, "gameSettings.fovY#playerFirstPerson", (math.deg(self[GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON])))
        local wrapped = setXMLFloat
        wrapped(xmlFile, "gameSettings.fovY#playerThirdPerson", (math.deg(self[GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON])))
        setXMLFloat(xmlFile, "gameSettings.uiScale", self[GameSettings.SETTING.UI_SCALE])
        setXMLBool(xmlFile, "gameSettings.realBeaconLights", self[GameSettings.SETTING.REAL_BEACON_LIGHTS])
        setXMLBool(xmlFile, "gameSettings.cameraBobbing", self[GameSettings.SETTING.CAMERA_BOBBING])
        setXMLBool(xmlFile, "gameSettings.steeringAssistLines", self[GameSettings.SETTING.STEERING_ASSIST_LINES])
        setXMLBool(xmlFile, "gameSettings.steeringAssistCruiseControl", self[GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL])
        local wrapped = XMLFile.wrap(xmlFile, GameSettings.xmlSchema)
        g_licensePlateManager.saveLicensePlateDataToXML(wrapped, "gameSettings.lastCreatedLicensePlate", self.lastCreatedLicensePlate, true)
        if self.lastPlayerStyle ~= nil then
            self.lastPlayerStyle:saveToXMLFile(wrapped, "gameSettings.lastPlayerStyle")
        end
        wrapped:removeProperty("gameSettings.customColors")
        local index = 0
        for _, color in pairs(self[GameSettings.SETTING.CUSTOM_COLORS]) do
            local key = string.format("gameSettings.customColors.color(%d)", index)
            wrapped:setString(key .. "#name", color.name or "")
            wrapped:setString(key .. "#materialName", color.materialName or "")
            wrapped:setValue(key .. "#color", unpack(color.color))
            index = index + 1
        end
        wrapped:delete()
        saveXMLFile(xmlFile)
        syncProfileFiles()
    end
end
function GameSettings.setXMLValue(_, xmlFile, func, xPath, value)
    if value ~= nil then
        func(xmlFile, xPath, value)
    end
end
function GameSettings:setLastPlayerStyle(playerStyle)
    if self.lastPlayerStyle == nil then
        self.lastPlayerStyle = PlayerStyle.new()
    end
    self.lastPlayerStyle:copySelectionFrom(playerStyle)
end