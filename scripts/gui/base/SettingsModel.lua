SettingsModel = {}
local SettingsModel_mt = Class(SettingsModel)
SettingsModel.SETTING_CLASS = {
    ["SAVE_NONE"] = 0,
    ["SAVE_ENGINE_QUALITY_SETTINGS"] = 1,
    ["SAVE_GAMEPLAY_SETTINGS"] = 2,
    ["SAVE_ALL"] = 3
}
SettingsModel.SETTING = {
    ["PERFORMANCE_CLASS"] = "performanceClass",
    ["PERFORMANCE_MODE"] = "performanceMode",
    ["HDR_ENABLED"] = "hdrEnabled",
    ["HDR_PEAK_BRIGHTNESS"] = "hdrPeakBrightness",
    ["HDR_CONTRAST"] = "hdrContrast",
    ["OVERLAY_BRIGHTNESS"] = "overlayBrightness",
    ["MSAA"] = "msaa",
    ["TEXTURE_FILTERING"] = "textureFiltering",
    ["TEXTURE_RESOLUTION"] = "textureResolution",
    ["SHADOW_QUALITY"] = "shadowQuality",
    ["SHADOW_DISTANCE_QUALITY"] = "shadowDistanceQuality",
    ["SOFT_SHADOWS"] = "softShadows",
    ["SCREEN_SPACE_SHADOWS_QUALITY"] = "screenSpaceShadowsQuality",
    ["SHADER_QUALITY"] = "shaderQuality",
    ["SHADOW_MAP_FILTERING"] = "shadowMapFiltering",
    ["MAX_LIGHTS"] = "maxLights",
    ["TERRAIN_QUALITY"] = "terrainQuality",
    ["OBJECT_DRAW_DISTANCE"] = "objectDrawDistance",
    ["FOLIAGE_DRAW_DISTANCE"] = "foliageDrawDistance",
    ["FOLIAGE_SHADOW"] = "foliageShadow",
    ["LOD_DISTANCE"] = "lodDistance",
    ["TERRAIN_LOD_DISTANCE"] = "terrainLODDistance",
    ["FOLIAGE_LOD_DISTANCE"] = "foliageLODDistance",
    ["VOLUME_MESH_TESSELLATION"] = "volumeMeshTessellation",
    ["MAX_TIRE_TRACKS"] = "maxTireTracks",
    ["LIGHTS_PROFILE"] = GameSettings.SETTING.LIGHTS_PROFILE,
    ["REAL_BEACON_LIGHTS"] = GameSettings.SETTING.REAL_BEACON_LIGHTS,
    ["MAX_MIRRORS"] = GameSettings.SETTING.MAX_NUM_MIRRORS,
    ["POST_PROCESS_AA"] = "postProcessAntiAliasing",
    ["DLSS"] = "dlss",
    ["DLSS_FRAME_GENERATION"] = "dlssFrameGeneration",
    ["FIDELITYFX_SR"] = "fidelityFxSR",
    ["FIDELITYFX_SR_30"] = "fidelityFxSR30",
    ["FIDELITYFX_SR_30_FRAME_GENERATION"] = "fidelityFxSR30FrameGeneration",
    ["DRS_QUALITY"] = "drsQuality",
    ["DRS_TARGET_FPS"] = "drsTargetFPS",
    ["VALAR"] = "valar",
    ["SCREEN_SPACE_REFLECTIONS"] = "screenSpaceReflections",
    ["XESS"] = "xess",
    ["XESS_FRAME_GENERATION"] = "xessFrameGeneration",
    ["SHARPNESS"] = "sharpness",
    ["SHADING_RATE_QUALITY"] = "shadingRateQuality",
    ["SSAO_QUALITY"] = "ssaoQuality",
    ["ATMOSPHERE_QUALITY"] = "atmosphereQuality",
    ["VOLUMETRIC_FOG_QUALITY"] = "volumetricFogQuality",
    ["CLOUD_SHADOWS_QUALITY"] = "cloudShadowsQuality",
    ["LENSFLARE_QUALITY"] = "lensFlareQuality",
    ["FULLSCREEN_MODE"] = "fullscreenMode",
    ["INPUT_HELP_MODE"] = GameSettings.SETTING.INPUT_HELP_MODE,
    ["GAMEPAD_ENABLED"] = GameSettings.SETTING.IS_GAMEPAD_ENABLED,
    ["HEAD_TRACKING_ENABLED"] = GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED,
    ["FORCE_FEEDBACK"] = GameSettings.SETTING.FORCE_FEEDBACK,
    ["LANGUAGE"] = "language",
    ["MP_LANGUAGE"] = "mpLanguage",
    ["VOLUME_MUSIC"] = GameSettings.SETTING.VOLUME_MUSIC,
    ["UI_SCALE"] = GameSettings.SETTING.UI_SCALE,
    ["RESOLUTION"] = "resolution",
    ["BRIGHTNESS"] = "brightness",
    ["V_SYNC"] = "vSync",
    ["FOV_Y"] = GameSettings.SETTING.FOV_Y,
    ["FOV_Y_PLAYER_FIRST_PERSON"] = GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON,
    ["FOV_Y_PLAYER_THIRD_PERSON"] = GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON,
    ["CAMERA_BOBBING"] = GameSettings.SETTING.CAMERA_BOBBING,
    ["FRAME_LIMIT"] = GameSettings.SETTING.FRAME_LIMIT,
    ["INVERT_Y_LOOK"] = GameSettings.SETTING.INVERT_Y_LOOK,
    ["VOLUME_MASTER"] = GameSettings.SETTING.VOLUME_MASTER,
    ["SHOW_HELP_MENU"] = GameSettings.SETTING.SHOW_HELP_MENU,
    ["EASY_ARM_CONTROL"] = GameSettings.SETTING.EASY_ARM_CONTROL,
    ["VOLUME_ENVIRONMENT"] = GameSettings.SETTING.VOLUME_ENVIRONMENT,
    ["VOLUME_CHARACTER"] = GameSettings.SETTING.VOLUME_CHARACTER,
    ["VOLUME_VEHICLE"] = GameSettings.SETTING.VOLUME_VEHICLE,
    ["RADIO_VEHICLE_ONLY"] = GameSettings.SETTING.RADIO_VEHICLE_ONLY,
    ["RADIO_IS_ACTIVE"] = GameSettings.SETTING.RADIO_IS_ACTIVE,
    ["VOLUME_RADIO"] = GameSettings.SETTING.VOLUME_RADIO,
    ["VOLUME_GUI"] = GameSettings.SETTING.VOLUME_GUI,
    ["VOLUME_NO_FOCUS"] = GameSettings.SETTING.VOLUME_NO_FOCUS,
    ["VOLUME_VOICE"] = GameSettings.SETTING.VOLUME_VOICE,
    ["VOLUME_VOICE_INPUT"] = GameSettings.SETTING.VOLUME_VOICE_INPUT,
    ["VOICE_MODE"] = GameSettings.SETTING.VOICE_MODE,
    ["VOICE_INPUT_SENSITIVITY"] = GameSettings.SETTING.VOICE_INPUT_SENSITIVITY,
    ["SHOW_HELP_ICONS"] = GameSettings.SETTING.SHOW_HELP_ICONS,
    ["USE_COLORBLIND_MODE"] = GameSettings.SETTING.USE_COLORBLIND_MODE,
    ["SHOW_TRIGGER_MARKER"] = GameSettings.SETTING.SHOW_TRIGGER_MARKER,
    ["SHOW_HELP_TRIGGER"] = GameSettings.SETTING.SHOW_HELP_TRIGGER,
    ["SHOW_FIELD_INFO"] = GameSettings.SETTING.SHOW_FIELD_INFO,
    ["USE_MILES"] = GameSettings.SETTING.USE_MILES,
    ["USE_FAHRENHEIT"] = GameSettings.SETTING.USE_FAHRENHEIT,
    ["USE_ACRE"] = GameSettings.SETTING.USE_ACRE,
    ["MONEY_UNIT"] = GameSettings.SETTING.MONEY_UNIT,
    ["RESET_CAMERA"] = GameSettings.SETTING.RESET_CAMERA,
    ["USE_WORLD_CAMERA"] = GameSettings.SETTING.USE_WORLD_CAMERA,
    ["ACTIVE_SUSPENSION_CAMERA"] = GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA,
    ["CAMERA_CHECK_COLLISION"] = GameSettings.SETTING.CAMERA_CHECK_COLLISION,
    ["IS_TRAIN_TABBABLE"] = GameSettings.SETTING.IS_TRAIN_TABBABLE,
    ["CAMERA_SENSITIVITY"] = GameSettings.SETTING.CAMERA_SENSITIVITY,
    ["VEHICLE_ARM_SENSITIVITY"] = GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY,
    ["REAL_BEACON_LIGHT_BRIGHTNESS"] = GameSettings.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS,
    ["STEERING_BACK_SPEED"] = GameSettings.SETTING.STEERING_BACK_SPEED,
    ["STEERING_SENSITIVITY"] = GameSettings.SETTING.STEERING_SENSITIVITY,
    ["DIRECTION_CHANGE_MODE"] = GameSettings.SETTING.DIRECTION_CHANGE_MODE,
    ["GEAR_SHIFT_MODE"] = GameSettings.SETTING.GEAR_SHIFT_MODE,
    ["HUD_SPEED_GAUGE"] = GameSettings.SETTING.HUD_SPEED_GAUGE,
    ["WOOD_HARVESTER_AUTO_CUT"] = GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT,
    ["SHOW_MULTIPLAYER_NAMES"] = GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES,
    ["GYROSCOPE_STEERING"] = GameSettings.SETTING.GYROSCOPE_STEERING,
    ["CAMERA_TILTING"] = GameSettings.SETTING.CAMERA_TILTING,
    ["HINTS"] = GameSettings.SETTING.HINTS,
    ["RESOLUTION_SCALE"] = "resolutionScale",
    ["RESOLUTION_SCALE_3D"] = "resolutionScale3d"
}
function SettingsModel.new()
    -- upvalues: (copy) SettingsModel_mt
    local self = setmetatable({}, SettingsModel_mt)
    self.settings = {}
    self.sortedSettings = {}
    self.settingReaders = {}
    self.settingWriters = {}
    self.settingTexts = {}
    self.settingsRawToValues = {}
    self.settingsValueToRaws = {}
    self.settingsOnChanges = {}
    self.defaultReaderFunction = self:makeDefaultReaderFunction()
    self.defaultWriterFunction = self:makeDefaultWriterFunction()
    self.volumeTexts = {}
    self.voiceInputThresholdTexts = {}
    self.recordingVolumeTexts = {}
    self.voiceModeTexts = {}
    self.brightnessTexts = {}
    self.fovYTexts = {}
    self.indexToFovYMapping = {}
    self.fovYToIndexMapping = {}
    self.uiScaleValues = {}
    self.uiScaleTexts = {}
    self.cameraSensitivityValues = {}
    self.cameraSensitivityStrings = {}
    self.cameraSensitivityStep = 0.25
    self.vehicleArmSensitivityValues = {}
    self.vehicleArmSensitivityStrings = {}
    self.vehicleArmSensitivityStep = 0.25
    self.realBeaconLightBrightnessValues = {}
    self.realBeaconLightBrightnessStrings = {}
    self.realBeaconLightBrightnessStep = 0.1
    self.steeringBackSpeedValues = {}
    self.steeringBackSpeedStrings = {}
    self.steeringBackSpeedStep = 1
    self.steeringSensitivityValues = {}
    self.steeringSensitivityStrings = {}
    self.steeringSensitivityStep = 0.1
    self.moneyUnitTexts = {}
    self.distanceUnitTexts = {}
    self.temperatureUnitTexts = {}
    self.areaUnitTexts = {}
    self.radioModeTexts = {}
    self.resolutionScaleTexts = {}
    self.resolutionScale3dTexts = {}
    self.drsTargetFPSTexts = {}
    self.sharpnessTexts = {}
    self.scalingModeTexts = {}
    self.shadowQualityTexts = {}
    self.shadowDistanceQualityTexts = {}
    self.softShadowsTexts = {}
    self.fourStateTexts = {}
    self.lowHighTexts = {}
    self.shadowMapMaxLightsTexts = {}
    self.hdrPeakBrightnessValues = {}
    self.hdrPeakBrightnessTexts = {}
    self.hdrPeakBrightnessStep = 0.05
    self.hdrContrastValues = {}
    self.hdrContrastTexts = {}
    self.hdrContrastStep = 0.01
    self.overlayBrightnessValues = {}
    self.overlayBrightnessTexts = {}
    self.overlayBrightnessStep = 0.05
    self.percentValues = {}
    self.perentageTexts = {}
    self.percentStep = 0.05
    self.tireTracksValues = {}
    self.tireTracksTexts = {}
    self.tireTracksStep = 0.5
    self.maxMirrorsTexts = {}
    self.ssaoQualityTexts = {}
    self.resolutionTexts = {}
    self.fullscreenModeTexts = {}
    self.mpLanguageTexts = {}
    self.inputHelpModeTexts = {}
    self.directionChangeModeTexts = {}
    self.gearShiftModeTexts = {}
    self.hudSpeedGaugeTexts = {}
    self.frameLimitTexts = {}
    self.intialValues = {}
    self.deviceSettings = {}
    self.currentDevice = {}
    self.minBrightness = 0.5
    self.maxBrightness = 2
    self.brightnessStep = 0.1
    self.minSharpness = 0
    self.maxSharpness = 2
    self.sharpnessStep = 0.1
    self.qualityTexts = {
        ["OFF"] = g_i18n:getText("ui_off"),
        ["ON"] = g_i18n:getText("ui_on"),
        ["LOW"] = g_i18n:getText("setting_low"),
        ["MEDIUM"] = g_i18n:getText("setting_medium"),
        ["HIGH"] = g_i18n:getText("setting_high"),
        ["VERY_HIGH"] = g_i18n:getText("setting_veryHigh"),
        ["ULTRA"] = g_i18n:getText("setting_ultra"),
        ["MAX_QUALITY"] = g_i18n:getText("setting_maxQuality"),
        ["BALANCED_PERFORMANCE"] = g_i18n:getText("setting_balancedPerformance"),
        ["MAX_PERFORMANCE"] = g_i18n:getText("setting_maxPerformance"),
        ["ULTRA_PERFORMANCE"] = g_i18n:getText("setting_ultraPerformance"),
        ["ULTRA_QUALITY"] = g_i18n:getText("setting_ultraQuality"),
        ["ULTRA_QUALITY_PLUS"] = g_i18n:getText("setting_ultraQualityPlus"),
        ["QUALITY"] = g_i18n:getText("setting_quality"),
        ["BALANCED"] = g_i18n:getText("setting_balanced"),
        ["PERFORMANCE"] = g_i18n:getText("setting_performance")
    }
    self:initialize()
    return self
end
function SettingsModel:initialize()
    self:createControlDisplayValues()
    self:addManagedSettings()
end
function SettingsModel:addManagedSettings()
    if not Platform.isConsole then
        self:addPerformanceClassSetting()
        self:addEngineQualitySetting(SettingsModel.SETTING.ATMOSPHERE_QUALITY, AtmosphereQuality, getSupportsAtmosphereQuality, getAtmosphereQualityName, setAtmosphereQuality, getAtmosphereQuality)
        self:addEngineQualitySetting(SettingsModel.SETTING.DRS_QUALITY, DRSQuality, getSupportsDRSQuality, getDRSQualityName, setDRSQuality, getDRSQuality)
        self:addEngineQualitySetting(SettingsModel.SETTING.LENSFLARE_QUALITY, LensFlareQuality, getSupportsLensFlareQuality, getLensFlareQualityName, setLensFlareQuality, getLensFlareQuality)
        self:addEngineQualitySetting(SettingsModel.SETTING.VOLUMETRIC_FOG_QUALITY, VolumetricFogQuality, getSupportsVolumetricFogQuality, getVolumetricFogQualityName, setVolumetricFogQuality, getVolumetricFogQuality)
        self:addEngineQualitySetting(SettingsModel.SETTING.SCREEN_SPACE_REFLECTIONS, ScreenSpaceReflectionsQuality, getSupportsScreenSpaceReflectionsQuality, getScreenSpaceReflectionsQualityName, setScreenSpaceReflectionsQuality, getScreenSpaceReflectionsQuality)
        self:addEngineQualitySetting(SettingsModel.SETTING.SCREEN_SPACE_SHADOWS_QUALITY, ScreenSpaceShadowsQuality, getSupportsScreenSpaceShadowsQuality, getScreenSpaceShadowsQualityName, setScreenSpaceShadowsQuality, getScreenSpaceShadowsQuality)
        self:addEngineQualitySetting(SettingsModel.SETTING.TEXTURE_FILTERING, TEXTURE_FILTERING, nil, getTextureFilteringName, setTextureFiltering, getTextureFiltering, nil, nil, false)
        self:addEngineQualitySetting(SettingsModel.SETTING.DLSS, DLSSQuality, getSupportsDLSSQuality, getDLSSQualityName, setDLSSQuality, getDLSSQuality, function(_, rawValue, _)
            -- upvalues: (copy) self
            if rawValue == DLSSQuality.OFF then
                self:setRawValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
            else
                self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
                self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
                self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
                self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
                self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
                self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
                self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
            end
        end, true)
        self:addEngineQualitySetting(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality, getSupportsFidelityFxSRQuality, getFidelityFxSRQualityName, setFidelityFxSRQuality, getFidelityFxSRQuality, function(_, rawValue, _)
            -- upvalues: (copy) self
            if rawValue ~= FidelityFxSRQuality.OFF then
                self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
                self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
                self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.TAA)
                self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
                self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
                self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
            end
        end, true)
        self:addEngineQualitySetting(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality, getSupportsFidelityFxSR30Quality, getFidelityFxSR30QualityName, setFidelityFxSR30Quality, getFidelityFxSR30Quality, function(_, rawValue, _)
            -- upvalues: (copy) self
            if rawValue == FidelityFxSR30Quality.OFF then
                self:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
            else
                self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
                self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
                self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
                self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
                self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
                self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
                self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
            end
        end, true)
        self:addEngineQualitySetting(SettingsModel.SETTING.VALAR, ValarQuality, getSupportsValarQuality, getValarQualityName, setValarQuality, getValarQuality, function(_, rawValue, _)
            if rawValue ~= ValarQuality.OFF then
                g_settingsModel:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
            end
        end)
        self:addEngineQualitySetting(SettingsModel.SETTING.XESS, XeSSQuality, getSupportsXeSSQuality, getXeSSQualityName, setXeSSQuality, getXeSSQuality, function(_, rawValue, _)
            -- upvalues: (copy) self
            if rawValue ~= XeSSQuality.OFF then
                self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE, SettingsModel.getScalingStateFromResolutionScaling(1))
                self:setRawValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, SettingsModel.getScalingStateFromResolutionScaling(1))
                self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
                self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
                self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
                self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
                self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
            end
        end, true)
        self:addEngineQualitySetting(SettingsModel.SETTING.MSAA, MSAA, nil, getMSAAName, setMSAA, getMSAA, function(_, rawValue, _)
            -- upvalues: (copy) self
            if rawValue ~= MSAA.OFF then
                self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
                self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
                self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
                if self:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) ~= PostProcessAntiAliasing.TAA and self:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) ~= PostProcessAntiAliasing.OFF then
                    self:setRawValue(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing.OFF)
                end
            end
        end)
        self:addEngineQualitySetting(SettingsModel.SETTING.POST_PROCESS_AA, PostProcessAntiAliasing, getSupportsPostProcessAntiAliasing, getPostProcessAntiAliasingName, setPostProcessAntiAliasing, getPostProcessAntiAliasing, function(_, rawValue, _)
            -- upvalues: (copy) self
            if rawValue == PostProcessAntiAliasing.OFF then
                self:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
                self:setValue(SettingsModel.SETTING.XESS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
            else
                self:setRawValue(SettingsModel.SETTING.DLSS, DLSSQuality.OFF)
                self:setRawValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
                self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30, FidelityFxSR30Quality.OFF)
                self:setRawValue(SettingsModel.SETTING.XESS, XeSSQuality.OFF)
                if rawValue ~= PostProcessAntiAliasing.FSR3 then
                    self:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
                end
                if rawValue ~= PostProcessAntiAliasing.XESS then
                    self:setValue(SettingsModel.SETTING.XESS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
                end
                if rawValue ~= PostProcessAntiAliasing.DLAA then
                    self:setRawValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, FrameInterpolationMode.FRAME_INTERPOLATION_OFF)
                end
                if rawValue ~= PostProcessAntiAliasing.TAA then
                    self:setRawValue(SettingsModel.SETTING.MSAA, MSAA.OFF)
                end
                if rawValue == PostProcessAntiAliasing.DLAA then
                    self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
                    return
                end
                if rawValue == PostProcessAntiAliasing.FSR3 then
                    self:setRawValue(SettingsModel.SETTING.FIDELITYFX_SR, FidelityFxSRQuality.OFF)
                    return
                end
            end
        end)
        self:addSetting(SettingsModel.SETTING.RESOLUTION, getScreenMode, setScreenMode, true)
        self:addResolutionScaleSetting()
        self:addResolutionScale3dSetting()
        self:addFidelityFxSR30FrameGenerationSetting()
        self:addXeSSFrameGenerationSetting()
        self:addDLSSFrameGenerationSetting()
        self:addTextureResolutionSetting()
        self:addShadowQualitySetting()
        self:addShadowDistanceQualitySetting()
        self:addSoftShadowsSetting()
        self:addShaderQualitySetting()
        self:addShadowMapFilteringSetting()
        self:addShadowMaxLightsSetting()
        self:addTerrainQualitySetting()
        self:addObjectDrawDistanceSetting()
        self:addFoliageDrawDistanceSetting()
        self:addFoliageShadowSetting()
        self:addLODDistanceSetting()
        self:addTerrainLODDistanceSetting()
        self:addFoliageLODDistanceSetting()
        self:addVolumeMeshTessellationSetting()
        self:addMaxTireTracksSetting()
        self:addLightsProfileSetting()
        self:addMaxMirrorsSetting()
        self:addDRSTargetFPSSetting()
        self:addSharpnessSetting()
        self:addShadingRateQualitySetting()
        self:addSSAOQualitySetting()
        self:addCloudShadowsQualitySetting()
        self:addVSyncSetting()
        self:addSetting(SettingsModel.SETTING.FULLSCREEN_MODE, getFullscreenMode, setFullscreenMode, true)
    end
    self:addPerformanceModeSetting()
    self:addRealBeaconLightsSetting()
    self:addLanguageSetting()
    self:addMPLanguageSetting()
    self:addInputHelpModeSetting()
    self:addBrightnessSetting()
    self:addFovYSetting()
    self:addFovYPlayerFirstPersonSetting()
    self:addFovYPlayerThirdPersonSetting()
    self:addUIScaleSetting()
    self:addMasterVolumeSetting()
    self:addMusicVolumeSetting()
    self:addEnvironmentVolumeSetting()
    self:addVehicleVolumeSetting()
    self:addRadioVolumeSetting()
    self:addVolumeGUISetting()
    self:addVolumeNoFocusSetting()
    self:addVolumeCharacterSetting()
    self:addVoiceVolumeSetting()
    self:addVoiceInputVolumeSetting()
    self:addVoiceModeSetting()
    self:addVoiceInputSensitivitySetting()
    self:addSteeringBackSpeedSetting()
    self:addSteeringSensitivitySetting()
    self:addCameraSensitivitySetting()
    self:addVehicleArmSensitivitySetting()
    self:addRealBeaconLightBrightnessSetting()
    self:addActiveCameraSuspensionSetting()
    self:addCamerCheckCollisionSetting()
    self:addDirectionChangeModeSetting()
    self:addGearShiftModeSetting()
    self:addHudSpeedGaugeSetting()
    self:addWoodHarvesterAutoCutSetting()
    self:addForceFeedbackSetting()
    if Platform.hasAdjustableFrameLimit then
        self:addFrameLimitSetting()
    end
    if Platform.isMobile then
        self:addGyroscopeSteeringSetting()
        self:addHintsSetting()
        self:addCameraTiltingSetting()
    end
    self:addHDRPeakBrightnessSetting()
    self:addHDRContrastSetting()
    self:addOverlayBrightnessSetting()
    self:addHDREnabledSetting()
    self:addDirectSetting(SettingsModel.SETTING.USE_COLORBLIND_MODE)
    self:addDirectSetting(SettingsModel.SETTING.GAMEPAD_ENABLED)
    self:addDirectSetting(SettingsModel.SETTING.SHOW_FIELD_INFO)
    self:addDirectSetting(SettingsModel.SETTING.SHOW_HELP_MENU)
    self:addDirectSetting(SettingsModel.SETTING.RADIO_IS_ACTIVE)
    self:addDirectSetting(SettingsModel.SETTING.RESET_CAMERA)
    self:addDirectSetting(SettingsModel.SETTING.RADIO_VEHICLE_ONLY)
    self:addDirectSetting(SettingsModel.SETTING.IS_TRAIN_TABBABLE)
    self:addDirectSetting(SettingsModel.SETTING.HEAD_TRACKING_ENABLED)
    self:addDirectSetting(SettingsModel.SETTING.USE_FAHRENHEIT)
    self:addDirectSetting(SettingsModel.SETTING.USE_WORLD_CAMERA)
    self:addDirectSetting(SettingsModel.SETTING.MONEY_UNIT)
    self:addDirectSetting(SettingsModel.SETTING.USE_ACRE)
    self:addDirectSetting(SettingsModel.SETTING.EASY_ARM_CONTROL)
    self:addDirectSetting(SettingsModel.SETTING.INVERT_Y_LOOK)
    self:addDirectSetting(SettingsModel.SETTING.USE_MILES)
    self:addDirectSetting(SettingsModel.SETTING.SHOW_TRIGGER_MARKER)
    self:addDirectSetting(SettingsModel.SETTING.SHOW_MULTIPLAYER_NAMES)
    self:addDirectSetting(SettingsModel.SETTING.SHOW_HELP_TRIGGER)
    self:addDirectSetting(SettingsModel.SETTING.SHOW_HELP_ICONS)
    self:addDirectSetting(SettingsModel.SETTING.CAMERA_BOBBING)
end
function SettingsModel:addSetting(gameSettingsKey, readerFunction, writerFunction, restartRequired, textFunction, rawToValueFunc, valueToRawFunc, onChangeFunc)
    local initialValue = readerFunction(gameSettingsKey)
    self.settings[gameSettingsKey] = {
        ["key"] = gameSettingsKey,
        ["initial"] = initialValue,
        ["saved"] = initialValue,
        ["changed"] = initialValue,
        ["restartRequired"] = restartRequired
    }
    self.settingReaders[gameSettingsKey] = readerFunction
    self.settingWriters[gameSettingsKey] = writerFunction
    self.settingTexts[gameSettingsKey] = textFunction
    self.settingsRawToValues[gameSettingsKey] = rawToValueFunc
    self.settingsValueToRaws[gameSettingsKey] = valueToRawFunc
    self.settingsOnChanges[gameSettingsKey] = onChangeFunc
    table.insert(self.sortedSettings, self.settings[gameSettingsKey])
end
function SettingsModel:setValue(settingKey, value)
    if self.settings[settingKey] == nil then
        Logging.warning("SettingsModel key %q is not registered", settingKey)
        return
    elseif value ~= nil then
        self.settings[settingKey].changed = value
        local func = self.settingsValueToRaws[settingKey]
        local onChangedFunc
        if func == nil then
            onChangedFunc = value
        else
            onChangedFunc = func(value)
        end
        local onChangedFunc = self.settingsOnChanges[settingKey]
        if onChangedFunc ~= nil then
            onChangedFunc(value, onChangedFunc, self.settings[settingKey].changed ~= value)
        end
    end
end
function SettingsModel:setRawValue(settingsKey, value)
    local func = self.settingsRawToValues[settingsKey]
    if func ~= nil then
        value = func(value)
    end
    self:setValue(settingsKey, value)
end
function SettingsModel:getValue(settingKey, trueValue)
    if trueValue then
        return self.settingReaders[settingKey](settingKey)
    else
        return self.settings[settingKey] == nil and 0 or self.settings[settingKey].changed
    end
end
function SettingsModel:getRawValue(settingKey, trueValue)
    local value = self:getValue(settingKey, trueValue)
    local func = self.settingsValueToRaws[settingKey]
    if func ~= nil then
        value = func(value)
    end
    return value
end
function SettingsModel:getTexts(settingKey)
    local func = self.settingTexts[settingKey]
    if func == nil then
        return nil
    else
        return func()
    end
end
function SettingsModel:refresh()
    for settingsKey, setting in pairs(self.settings) do
        setting.initial = self.settingReaders[settingsKey](settingsKey)
        setting.changed = setting.initial
        setting.saved = setting.initial
    end
end
function SettingsModel:refreshChangedValue()
    for settingsKey, setting in pairs(self.settings) do
        setting.changed = self.settingReaders[settingsKey](settingsKey)
        setting.saved = setting.changed
    end
end
function SettingsModel:reset()
    for _, setting in pairs(self.sortedSettings) do
        local hasChanged = true
        if setting.initial == setting.changed then
            hasChanged = setting.initial ~= setting.saved
        end
        setting.changed = setting.initial
        setting.saved = setting.initial
        if hasChanged then
            self.settingWriters[setting.key](setting.changed, setting.key)
        end
    end
    setUserConfirmScreenMode(true)
    self:resetDeviceChanges()
end
function SettingsModel:getSettingExists(settingsKey)
    return self.settings[settingsKey] ~= nil
end
function SettingsModel:getHasValueChanged(settingKey)
    local setting = self.settings[settingKey]
    if setting == nil then
        Logging.devError("Setting \'%s\' is not defined!", (tostring(settingKey)))
        return false
    end
    return setting.initial ~= setting.changed or setting.initial ~= setting.saved
end
function SettingsModel:hasChanges()
    for _, setting in pairs(self.settings) do
        if setting.initial ~= setting.changed or setting.initial ~= setting.saved then
            return true
        end
    end
    return self:hasDeviceChanges()
end
function SettingsModel:needsRestartToApplyChanges()
    for _, setting in pairs(self.settings) do
        if (setting.initial ~= setting.changed or setting.initial ~= setting.saved) and setting.restartRequired then
            return true, self:needsProcessRestartToApplyChanges()
        end
    end
    return false, false
end
function SettingsModel:needsProcessRestartToApplyChanges()
    return self:getSettingExists(SettingsModel.SETTING.RESOLUTION) and g_settingsModel:getHasValueChanged(SettingsModel.SETTING.RESOLUTION) and true or (self:getSettingExists(SettingsModel.SETTING.FULLSCREEN_MODE) and g_settingsModel:getHasValueChanged(SettingsModel.SETTING.FULLSCREEN_MODE) and true or false)
end
function SettingsModel:applyChanges(settingClassesToSave)
    for _, setting in pairs(self.sortedSettings) do
        local settingsKey = setting.key
        local changedValue = self.settings[settingsKey].changed
        if self.settings[settingsKey].saved ~= changedValue then
            self.settingWriters[settingsKey](changedValue, settingsKey)
            self.settings[settingsKey].saved = changedValue
        end
        self.settings[settingsKey].initial = changedValue
    end
    if settingClassesToSave ~= 0 then
        self:saveChanges(settingClassesToSave)
    end
end
function SettingsModel:saveChanges(settingClassesToSave)
    if bit32.band(settingClassesToSave, SettingsModel.SETTING_CLASS.SAVE_GAMEPLAY_SETTINGS) ~= 0 then
        g_gameSettings:save()
    end
    self:saveDeviceChanges()
    if bit32.band(settingClassesToSave, SettingsModel.SETTING_CLASS.SAVE_ENGINE_QUALITY_SETTINGS) ~= 0 then
        saveHardwareScalability()
        if GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION then
            executeSettingsChange()
        end
    end
end
function SettingsModel:applyPerformanceClass(value)
    local settingsKey = SettingsModel.SETTING.PERFORMANCE_CLASS
    self.settingWriters[settingsKey](value, settingsKey)
    self.settings[settingsKey].changed = value
    self.settings[settingsKey].saved = value
    self:refreshChangedValue()
end
function SettingsModel:applyCustomSettings()
    for settingsKey in pairs(self.settings) do
        if settingsKey ~= SettingsModel.SETTING.PERFORMANCE_CLASS then
            local changedValue = self.settings[settingsKey].changed
            if changedValue ~= self.settings[settingsKey].saved then
                self.settingWriters[settingsKey](changedValue, settingsKey)
                self.settings[settingsKey].saved = changedValue
            end
        end
    end
end
function SettingsModel:createControlDisplayValues()
    self.volumeTexts = {
        g_i18n:getText("ui_off"),
        "10%",
        "20%",
        "30%",
        "40%",
        "50%",
        "60%",
        "70%",
        "80%",
        "90%",
        "100%"
    }
    self.recordingVolumeTexts = {
        g_i18n:getText("ui_auto"),
        "50%",
        "60%",
        "70%",
        "80%",
        "90%",
        "100%",
        "110%",
        "120%",
        "130%",
        "140%",
        "150%"
    }
    self.voiceModeTexts = { g_i18n:getText("ui_off"), g_i18n:getText("ui_voiceActivity") }
    if Platform.supportsPushToTalk then
        table.insert(self.voiceModeTexts, g_i18n:getText("ui_pushToTalk"))
    end
    self.voiceInputThresholdTexts = {
        g_i18n:getText("ui_auto"),
        "0%",
        "10%",
        "20%",
        "30%",
        "40%",
        "50%",
        "60%",
        "70%",
        "80%",
        "90%",
        "100%"
    }
    local i = self.minBrightness
    local index = self.maxBrightness + 0.0001
    local min = self.brightnessStep
    for i = i, index, min do
        table.insert(self.brightnessTexts, string.format("%.1f", i))
    end
    local index = 1
    local i = Platform.minFovY
    local min = math.deg(i)
    local steeringBackSpeedSettings = Platform.maxFovY
    local i = math.deg(steeringBackSpeedSettings)
    local numR = 1
    for min = min, i, numR do
        self.indexToFovYMapping[index] = min
        self.fovYToIndexMapping[min] = index
        local y = g_i18n:getText("setting_fovyDegree")
        table.insert(self.fovYTexts, string.format(y, min))
        index = index + 1
    end
    local i = 1
    local steeringBackSpeedSettings = 16
    local numR = 1
    for i = i, steeringBackSpeedSettings, numR do
        table.insert(self.uiScaleTexts, string.format("%d%%", 50 + (i - 1) * 5))
    end
    local i = 0.5
    local steeringBackSpeedSettings = 2.1
    local numR = 0.1
    for i = i, steeringBackSpeedSettings, numR do
        table.insert(self.resolutionScaleTexts, string.format("%d%%", MathUtil.round(i * 100)))
    end
    local i = 0.5
    local steeringBackSpeedSettings = 2.1
    local numR = 0.1
    for i = i, steeringBackSpeedSettings, numR do
        table.insert(self.resolutionScale3dTexts, string.format("%d%%", MathUtil.round(i * 100)))
    end
    local i = 0.5
    local steeringBackSpeedSettings = 3
    local numR = self.cameraSensitivityStep
    for i = i, steeringBackSpeedSettings, numR do
        table.insert(self.cameraSensitivityStrings, string.format("%d%%", i * 100))
        table.insert(self.cameraSensitivityValues, i)
    end
    local i = 0.5
    local steeringBackSpeedSettings = 3
    local numR = self.vehicleArmSensitivityStep
    for i = i, steeringBackSpeedSettings, numR do
        table.insert(self.vehicleArmSensitivityStrings, string.format("%d%%", i * 100))
        table.insert(self.vehicleArmSensitivityValues, i)
    end
    local i = 0
    local steeringBackSpeedSettings = 1
    local numR = self.realBeaconLightBrightnessStep
    for i = i, steeringBackSpeedSettings, numR do
        if i > 0 then
            table.insert(self.realBeaconLightBrightnessStrings, string.format("%d%%", i * 100 + 0.5))
        else
            table.insert(self.realBeaconLightBrightnessStrings, g_i18n:getText("setting_off"))
        end
        table.insert(self.realBeaconLightBrightnessValues, i)
    end
    local steeringBackSpeedSettings = Platform.gameplay.steeringBackSpeedSettings
    local i = 1
    local numR = #steeringBackSpeedSettings
    local i = 1
    for i = i, numR, i do
        table.insert(self.steeringBackSpeedStrings, string.format("%d%%", steeringBackSpeedSettings[i] * 10))
        table.insert(self.steeringBackSpeedValues, steeringBackSpeedSettings[i])
    end
    local i = 0.5
    local numR = 3.1
    local i = self.steeringSensitivityStep
    for i = i, numR, i do
        table.insert(self.steeringSensitivityStrings, string.format("%d%%", i * 100 + 0.5))
        table.insert(self.steeringSensitivityValues, i)
    end
    self.moneyUnitTexts = { g_i18n:getText("unit_euro"), g_i18n:getText("unit_dollar"), g_i18n:getText("unit_pound") }
    self.distanceUnitTexts = { g_i18n:getText("unit_km"), g_i18n:getText("unit_miles") }
    self.temperatureUnitTexts = { g_i18n:getText("unit_celsius"), g_i18n:getText("unit_fahrenheit") }
    self.areaUnitTexts = { g_i18n:getText("unit_ha"), g_i18n:getText("unit_acre") }
    self.radioModeTexts = { g_i18n:getText("setting_radioAlways"), g_i18n:getText("setting_radioVehicleOnly") }
    self.shadowQualityTexts = {
        g_i18n:getText("setting_off"),
        g_i18n:getText("setting_medium"),
        g_i18n:getText("setting_high"),
        g_i18n:getText("setting_veryHigh")
    }
    self.shadowDistanceQualityTexts = { g_i18n:getText("setting_low"), g_i18n:getText("setting_medium"), g_i18n:getText("setting_high") }
    self.softShadowsTexts = { g_i18n:getText("ui_off"), g_i18n:getText("ui_on") }
    self.fourStateTexts = {
        g_i18n:getText("setting_low"),
        g_i18n:getText("setting_medium"),
        g_i18n:getText("setting_high"),
        g_i18n:getText("setting_veryHigh")
    }
    self.fiveStateTexts = {
        g_i18n:getText("setting_low"),
        g_i18n:getText("setting_medium"),
        g_i18n:getText("setting_high"),
        g_i18n:getText("setting_veryHigh"),
        g_i18n:getText("setting_ultra")
    }
    self.lowHighTexts = { g_i18n:getText("setting_low"), g_i18n:getText("setting_high") }
    self.ssaoQualityTexts = {
        g_i18n:getText("setting_low"),
        g_i18n:getText("setting_medium"),
        g_i18n:getText("setting_high"),
        g_i18n:getText("setting_veryHigh")
    }
    self.drsTargetFPSTexts = {}
    self.drsTargetFPSMapping = {}
    self.drsTargetFPSMappingReverse = {}
    for _, value in ipairs(g_gameSettings.frameLimitValues) do
        local aspectStr = tostring(value)
        table.insert(self.drsTargetFPSTexts, aspectStr)
        self.drsTargetFPSMapping[value] = #self.drsTargetFPSTexts
        self.drsTargetFPSMappingReverse[#self.drsTargetFPSTexts] = value
    end
    local i = self.minSharpness
    local numR = self.maxSharpness + 0.0001
    local i = self.sharpnessStep
    for i = i, numR, i do
        table.insert(self.sharpnessTexts, string.format("%.1f", i))
    end
    self.scalingModeTexts = { g_i18n:getText("setting_off") }
    for _, value in pairs(FidelityFxSRQuality) do
        if value ~= FidelityFxSRQuality.OFF and (value ~= FidelityFxSRQuality.NUM and getSupportsFidelityFxSRQuality(value)) then
            table.insert(self.scalingModeTexts, g_i18n:getText("setting_fsr1"))
            break
        end
    end
    for _, value in pairs(FidelityFxSR30Quality) do
        if value ~= FidelityFxSR30Quality.OFF and (value ~= FidelityFxSR30Quality.NUM and getSupportsFidelityFxSR30Quality(value)) then
            if getFidelityFxSuperResolutionVersion() == 4 then
                table.insert(self.scalingModeTexts, g_i18n:getText("setting_fsr4"))
            else
                table.insert(self.scalingModeTexts, g_i18n:getText("setting_fsr3"))
            end
            break
        end
    end
    for _, value in pairs(DLSSQuality) do
        if value ~= DLSSQuality.OFF and (value ~= DLSSQuality.NUM and getSupportsDLSSQuality(value)) then
            table.insert(self.scalingModeTexts, g_i18n:getText("setting_DLSS"))
            break
        end
    end
    for _, value in pairs(XeSSQuality) do
        if value ~= XeSSQuality.OFF and (value ~= XeSSQuality.NUM and getSupportsXeSSQuality(value)) then
            table.insert(self.scalingModeTexts, g_i18n:getText("setting_xeSS"))
            break
        end
    end
    self.postProcessAntiAliasingToolTip = g_i18n:getText("toolTip_ppaa")
    if getSupportsPostProcessAntiAliasing(PostProcessAntiAliasing.TAA) then
        self.postProcessAntiAliasingToolTip = self.postProcessAntiAliasingToolTip .. " " .. g_i18n:getText("toolTip_ppaa_taa")
    end
    if getSupportsPostProcessAntiAliasing(PostProcessAntiAliasing.DLAA) then
        self.postProcessAntiAliasingToolTip = self.postProcessAntiAliasingToolTip .. " " .. g_i18n:getText("toolTip_ppaa_dlaa")
    end
    self.hdrPeakBrightnessValues = {}
    self.hdrPeakBrightnessTexts = {}
    self.hdrPeakBrightnessStep = 10
    local i = 0
    local numR = 95
    local i = 1
    for i = i, numR, i do
        local _ = 50 + i * self.hdrPeakBrightnessStep
        table.insert(self.hdrPeakBrightnessTexts, string.format("%d", _))
        table.insert(self.hdrPeakBrightnessValues, _)
    end
    self.hdrContrastValues = {}
    self.hdrContrastTexts = {}
    local i = 0
    local numR = 120
    local i = 1
    for i = i, numR, i do
        local _ = 0.8 + i * self.hdrContrastStep
        table.insert(self.hdrContrastTexts, string.format("%.2f", _))
        table.insert(self.hdrContrastValues, _)
    end
    self.overlayBrightnessValues = {}
    self.overlayBrightnessTexts = {}
    self.overlayBrightnessStep = 10
    local i = 0
    local numR = 95
    local i = 1
    for i = i, numR, i do
        local _ = 50 + i * self.overlayBrightnessStep
        table.insert(self.overlayBrightnessTexts, string.format("%d", _))
        table.insert(self.overlayBrightnessValues, _)
    end
    self.shadowMapMaxLightsTexts = {}
    local i = 1
    local numR = 10
    local i = 1
    for i = i, numR, i do
        table.insert(self.shadowMapMaxLightsTexts, string.format("%d", i))
    end
    self.percentValues = {}
    self.perentageTexts = {}
    self.percentStep = 0.05
    local i = 0
    local numR = 30
    local i = 1
    for i = i, numR, i do
        table.insert(self.perentageTexts, string.format("%.f%%", (0.5 + i * self.percentStep) * 100))
        table.insert(self.percentValues, 0.5 + i * self.percentStep)
    end
    self.tireTracksValues = {}
    self.tireTracksTexts = {}
    self.tireTracksStep = 0.5
    local i = 0
    local numR = 4
    local i = self.tireTracksStep
    for i = i, numR, i do
        table.insert(self.tireTracksTexts, string.format("%d%%", i * 100))
        table.insert(self.tireTracksValues, i)
    end
    self.maxMirrorsTexts = {}
    local i = 0
    local numR = 7
    local i = 1
    for i = i, numR, i do
        table.insert(self.maxMirrorsTexts, string.format("%d", i))
    end
    self.resolutionTexts = {}
    local i = getNumOfScreenModes() - 1
    local i = 1
    for _ = 0, i, i do
        local value, y = getScreenModeInfo(_)
        local aspect = value / y
        local aspectStr = aspect == 1.25 and "(5:4)" or (aspect > 1.3 and aspect < 1.4 and "(4:3)" or (aspect > 1.7 and aspect < 1.8 and "(16:9)" or (aspect > 2.3 and aspect < 2.4 and "(21:9)" or string.format("(%1.0f:10)", aspect * 10))))
        table.insert(self.resolutionTexts, string.format("%dx%d %s", value, y, aspectStr))
    end
    self.fullscreenModeTexts = {}
    local i = FullscreenMode.NUM - 1
    local i = 1
    for _ = 0, i, i do
        if _ == FullscreenMode.WINDOWED then
            table.insert(self.fullscreenModeTexts, g_i18n:getText("ui_windowed"))
        elseif _ == FullscreenMode.WINDOWED_FULLSCREEN then
            table.insert(self.fullscreenModeTexts, g_i18n:getText("ui_windowed_fullscreen"))
        else
            table.insert(self.fullscreenModeTexts, g_i18n:getText("ui_exclusive_fullscreen"))
        end
    end
    self.mpLanguageTexts = {}
    local value = 0
    local i = getNumOfLanguages() - 1
    for value = value, i do
        table.insert(self.mpLanguageTexts, getLanguageName(value))
    end
    self.frameLimitMapping = {}
    self.frameLimitMappingReverse = {}
    self.frameLimitTexts = {}
    for y, aspect in ipairs(g_gameSettings.frameLimitValues) do
        table.insert(self.frameLimitTexts, (tostring(aspect)))
        self.frameLimitMapping[aspect] = #self.frameLimitTexts
        self.frameLimitMappingReverse[#self.frameLimitTexts] = aspect
    end
    self.inputHelpModeTexts = { g_i18n:getText("ui_auto"), g_i18n:getText("ui_keyboard"), g_i18n:getText("ui_gamepad") }
    self.directionChangeModeTexts = {
        [VehicleMotor.DIRECTION_CHANGE_MODE_AUTOMATIC] = g_i18n:getText("ui_directionChangeModeAutomatic"),
        [VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL] = g_i18n:getText("ui_directionChangeModeManual")
    }
    self.gearShiftModeTexts = {
        [VehicleMotor.SHIFT_MODE_AUTOMATIC] = g_i18n:getText("ui_gearShiftModeAutomatic"),
        [VehicleMotor.SHIFT_MODE_MANUAL] = g_i18n:getText("ui_gearShiftModeManual")
    }
    if not Platform.isConsole then
        self.gearShiftModeTexts[VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH] = g_i18n:getText("ui_gearShiftModeManualClutch")
    end
    self.hudSpeedGaugeTexts = {
        [SpeedMeterDisplay.GAUGE_MODE_RPM] = g_i18n:getText("ui_hudSpeedGaugeRPM"),
        [SpeedMeterDisplay.GAUGE_MODE_SPEED] = g_i18n:getText("ui_hudSpeedGaugeSpeed")
    }
    self.deadzoneValues = {}
    self.deadzoneTexts = {}
    self.deadzoneStep = 0.01
    local value = 0
    local i = 0.301
    for value = value, i, self.deadzoneStep do
        table.insert(self.deadzoneTexts, string.format("%d%%", (math.floor(value * 100 + 0.001))))
        table.insert(self.deadzoneValues, value)
    end
    self.sensitivityValues = {}
    self.sensitivityTexts = {}
    self.sensitivityStep = 0.25
    local value = 0.5
    local i = 2
    for value = value, i, self.sensitivityStep do
        table.insert(self.sensitivityTexts, string.format("%d%%", value * 100))
        table.insert(self.sensitivityValues, value)
    end
    self.headTrackingSensitivityValues = {}
    self.headTrackingSensitivityTexts = {}
    self.headTrackingSensitivityStep = 0.05
    local value = 0
    local i = 1.001
    for value = value, i, self.headTrackingSensitivityStep do
        table.insert(self.headTrackingSensitivityTexts, string.format("%d%%", value * 100 + 0.001))
        table.insert(self.headTrackingSensitivityValues, value)
    end
end
function SettingsModel:getDeadzoneTexts()
    return self.deadzoneTexts
end
function SettingsModel:getSensitivityTexts()
    return self.sensitivityTexts
end
function SettingsModel:getHeadTrackingSensitivityTexts()
    return self.headTrackingSensitivityTexts
end
function SettingsModel:getDeviceHasAxisDeadzone(axisIndex)
    local settings = self.deviceSettings[self.currentDevice]
    return settings ~= nil and settings.deadzones[axisIndex] ~= nil
end
function SettingsModel:getDeviceHasAxisSensitivity(axisIndex)
    local settings = self.deviceSettings[self.currentDevice]
    return settings ~= nil and settings.sensitivities[axisIndex] ~= nil
end
function SettingsModel:getNumDevices()
    return #self.deviceSettings
end
function SettingsModel:nextDevice()
    self.currentDevice = self.currentDevice + 1
    if self.currentDevice > #self.deviceSettings then
        self.currentDevice = 1
    end
end
function SettingsModel:getCurrentDeviceName()
    local setting = self.deviceSettings[self.currentDevice]
    return setting == nil and "" or setting.device.deviceName
end
function SettingsModel:initDeviceSettings()
    self.deviceSettings = {}
    self.currentDevice = 0
    for _, device in pairs(g_inputBinding.devicesByInternalId) do
        local deadzones = {}
        local sensitivities = {}
        local mouseSensitivity = {}
        local headTrackingSensitivity = {}
        table.insert(_, {
            ["device"] = device,
            ["deadzones"] = deadzones,
            ["sensitivities"] = sensitivities,
            ["mouseSensitivity"] = mouseSensitivity,
            ["headTrackingSensitivity"] = headTrackingSensitivity
        })
        local axisIndex = 0
        local scale = Input.MAX_NUM_AXES - 1
        for axisIndex = axisIndex, scale, self.deviceSettings do
            if getHasGamepadAxis(axisIndex, device.internalId) then
                local deadzone = device:getDeadzone(axisIndex)
                local deadzoneValue = Utils.getValueIndex(deadzone, self.deadzoneValues)
                deadzones[axisIndex] = {
                    ["current"] = deadzoneValue,
                    ["saved"] = deadzoneValue
                }
                local sensitivity = device:getSensitivity(axisIndex)
                local sensitivityValue = Utils.getValueIndex(sensitivity, self.sensitivityValues)
                sensitivities[axisIndex] = {
                    ["current"] = sensitivityValue,
                    ["saved"] = sensitivityValue
                }
            end
        end
        if device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
            local scale, _ = g_inputBinding:getMouseMotionScale()
            local axisIndex = Utils.getValueIndex(scale, self.sensitivityValues)
            mouseSensitivity.current = axisIndex
            mouseSensitivity.saved = axisIndex
        end
        local scale = Utils.getValueIndex(getCameraTrackingSensitivity(), self.headTrackingSensitivityValues)
        headTrackingSensitivity.current = scale
        headTrackingSensitivity.saved = scale
        self.currentDevice = 1
    end
end
function SettingsModel:hasDeviceChanges()
    for _, settings in ipairs(self.deviceSettings) do
        for axisIndex, _ in pairs(settings.deadzones) do
            local deadzone = settings.deadzones[axisIndex]
            if deadzone.current ~= deadzone.saved then
                return true
            end
            local sensitivity = settings.sensitivities[axisIndex]
            if sensitivity.current ~= sensitivity.saved then
                return true
            end
        end
        if settings.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
            local mouseSensitivity = settings.mouseSensitivity
            if mouseSensitivity.current ~= mouseSensitivity.saved then
                return true
            end
        end
        local mouseSensitivity = settings.headTrackingSensitivity
        if mouseSensitivity.current ~= mouseSensitivity.saved then
            return true
        end
    end
    return false
end
function SettingsModel:saveDeviceChanges()
    local changedSettings = false
    for _, settings in ipairs(self.deviceSettings) do
        for axisIndex, _ in pairs(settings.deadzones) do
            local deadzones = settings.deadzones[axisIndex]
            deadzones.saved = deadzones.current
            settings.device:setDeadzone(axisIndex, self.deadzoneValues[deadzones.current])
            local sensitivities = settings.sensitivities[axisIndex]
            sensitivities.saved = sensitivities.current
            device:setSensitivity(axisIndex, self.sensitivityValues[sensitivities.current])
            changedSettings = true
        end
        if settings.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
            local mouseSensitivity = settings.mouseSensitivity
            if mouseSensitivity.current ~= mouseSensitivity.saved then
                g_inputBinding:setMouseMotionScale(self.sensitivityValues[mouseSensitivity.current])
                mouseSensitivity.saved = mouseSensitivity.current
                changedSettings = true
            end
            local headTrackingSensitivity = settings.headTrackingSensitivity
            if headTrackingSensitivity.current ~= headTrackingSensitivity.saved then
                setCameraTrackingSensitivity(self.headTrackingSensitivityValues[headTrackingSensitivity.current])
                headTrackingSensitivity.saved = headTrackingSensitivity.current
                changedSettings = true
            end
        end
    end
    if changedSettings then
        g_inputBinding:applyGamepadDeadzones()
        g_inputBinding:saveToXMLFile()
    end
end
function SettingsModel:resetDeviceChanges()
    for _, settings in ipairs(self.deviceSettings) do
        for axisIndex, _ in pairs(settings.deadzones) do
            local deadzone = settings.deadzones[axisIndex]
            deadzone.current = deadzone.saved
            local sensitivity = settings.sensitivities[axisIndex]
            sensitivity.current = sensitivity.saved
        end
        settings.mouseSensitivity.current = settings.mouseSensitivity.saved
        settings.headTrackingSensitivity.current = settings.headTrackingSensitivity.saved
    end
end
function SettingsModel:setDeviceDeadzoneValue(axisIndex, value)
    local settings = self.deviceSettings[self.currentDevice]
    if settings ~= nil then
        settings.deadzones[axisIndex].current = value
    end
end
function SettingsModel:getCurrentDeviceDeadzoneValue(axisIndex)
    local settings = self.deviceSettings[self.currentDevice]
    if settings == nil then
        return nil
    else
        return self.deadzoneValues[settings.deadzones[axisIndex].current]
    end
end
function SettingsModel:setDeviceSensitivityValue(axisIndex, value)
    local settings = self.deviceSettings[self.currentDevice]
    if settings ~= nil then
        settings.sensitivities[axisIndex].current = value
    end
end
function SettingsModel:getCurrentDeviceSensitivityValue(axisIndex)
    local settings = self.deviceSettings[self.currentDevice]
    if settings == nil then
        return nil
    else
        return self.sensitivityValues[settings.sensitivities[axisIndex].current]
    end
end
function SettingsModel:setMouseSensitivity(value)
    local settings = self.deviceSettings[self.currentDevice]
    if settings ~= nil then
        settings.mouseSensitivity.current = value
    end
end
function SettingsModel:setHeadTrackingSensitivity(value)
    local settings = self.deviceSettings[self.currentDevice]
    if settings ~= nil then
        settings.headTrackingSensitivity.current = value
    end
end
function SettingsModel:getDeviceAxisDeadzoneValue(axisIndex)
    return self.deviceSettings[self.currentDevice].deadzones[axisIndex].current
end
function SettingsModel:getDeviceAxisSensitivityValue(axisIndex)
    return self.deviceSettings[self.currentDevice].sensitivities[axisIndex].current
end
function SettingsModel:getMouseSensitivityValue(_)
    return self.deviceSettings[self.currentDevice].mouseSensitivity.current
end
function SettingsModel:getHeadTrackingSensitivityValue(_)
    return self.deviceSettings[self.currentDevice].headTrackingSensitivity.current
end
function SettingsModel:getIsDeviceMouse()
    local settings = self.deviceSettings[self.currentDevice]
    return settings ~= nil and settings.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE
end
function SettingsModel:getResolutionTexts()
    return self.resolutionTexts
end
function SettingsModel:getFullscreenModeTexts()
    return self.fullscreenModeTexts
end
function SettingsModel:getMPLanguageTexts()
    return self.mpLanguageTexts
end
function SettingsModel:getFrameLimitTexts()
    return self.frameLimitTexts
end
function SettingsModel:getInputHelpModeTexts()
    return self.inputHelpModeTexts
end
function SettingsModel:getDirectionChangeModeTexts()
    return self.directionChangeModeTexts
end
function SettingsModel:getGearShiftModeTexts()
    return self.gearShiftModeTexts
end
function SettingsModel:getHudSpeedGaugeTexts()
    return self.hudSpeedGaugeTexts
end
function SettingsModel:getLanguageTexts()
    return g_availableLanguageNamesTable
end
function SettingsModel:getIsLanguageDisabled()
    return #g_availableLanguagesTable <= 1 or GS_IS_STEAM_VERSION
end
function SettingsModel:getPerformanceClassTexts()
    local class, isCustom = getPerformanceClass()
    local _, isAuto = getAutoPerformanceClass()
    local texts = {}
    table.insert(texts, g_i18n:getText("setting_veryLow"))
    table.insert(texts, g_i18n:getText("setting_low"))
    table.insert(texts, g_i18n:getText("setting_medium"))
    table.insert(texts, g_i18n:getText("setting_high"))
    table.insert(texts, g_i18n:getText("setting_veryHigh"))
    table.insert(texts, g_i18n:getText("setting_ultra"))
    if not GS_IS_MOBILE_VERSION then
        local index = Utils.getPerformanceClassIndex(class)
        if isCustom then
            texts[index] = g_i18n:getText("setting_custom")
        elseif isAuto then
            texts[index] = g_i18n:getText("setting_auto")
        end
    end
    return texts, class, isCustom
end
function SettingsModel:getHDRPeakBrightnessTexts()
    return self.hdrPeakBrightnessTexts
end
function SettingsModel:getHDRContrastTexts()
    return self.hdrContrastTexts
end
function SettingsModel:getOverlayBrightnessTexts()
    return self.overlayBrightnessTexts
end
function SettingsModel:getPostProcessAAToolTip()
    return self.postProcessAntiAliasingToolTip
end
function SettingsModel:getDRSTargetFPSTexts()
    return self.drsTargetFPSTexts
end
function SettingsModel:getSharpnessTexts()
    return self.sharpnessTexts
end
function SettingsModel:getScalingModeTexts()
    return self.scalingModeTexts
end
function SettingsModel:getShadingRateQualityTexts()
    return self.fourStateTexts
end
function SettingsModel:getShadowQualityTexts()
    return self.shadowQualityTexts
end
function SettingsModel:getShadowDistanceQualityTexts()
    return self.shadowDistanceQualityTexts
end
function SettingsModel:getSoftShadowsTexts()
    return self.softShadowsTexts
end
function SettingsModel:getSSAOQualityTexts()
    return self.ssaoQualityTexts
end
function SettingsModel:getShaderQualityTexts()
    return self.fourStateTexts
end
function SettingsModel:getTextureResolutionTexts()
    return self.lowHighTexts
end
function SettingsModel:getShadowMapFilteringTexts()
    return self.lowHighTexts
end
function SettingsModel:getTerraingQualityTexts()
    return self.fourStateTexts
end
function SettingsModel:getLightsProfileTexts()
    return self.fiveStateTexts
end
function SettingsModel:getShadowMapLightsTexts()
    return self.shadowMapMaxLightsTexts
end
function SettingsModel:getObjectDrawDistanceTexts()
    return self.perentageTexts
end
function SettingsModel:getFoliageDrawDistanceTexts()
    return self.perentageTexts
end
function SettingsModel:getLODDistanceTexts()
    return self.perentageTexts
end
function SettingsModel:getTerrainLODDistanceTexts()
    return self.perentageTexts
end
function SettingsModel:getFoliageLODDistanceTexts()
    return self.perentageTexts
end
function SettingsModel:getVolumeMeshTessalationTexts()
    return self.perentageTexts
end
function SettingsModel:getMaxTireTracksTexts()
    return self.tireTracksTexts
end
function SettingsModel:getMaxMirrorsTexts()
    return self.maxMirrorsTexts
end
function SettingsModel:getBrightnessTexts()
    return self.brightnessTexts
end
function SettingsModel:getFovYTexts()
    return self.fovYTexts
end
function SettingsModel:getUiScaleTexts()
    return self.uiScaleTexts
end
function SettingsModel:getAudioVolumeTexts()
    return self.volumeTexts
end
function SettingsModel:getVoiceInputSensitivityTexts()
    return self.voiceInputThresholdTexts
end
function SettingsModel:getForceFeedbackTexts()
    return self.volumeTexts
end
function SettingsModel:getRecordingVolumeTexts()
    return self.recordingVolumeTexts
end
function SettingsModel:getVoiceModeTexts()
    return self.voiceModeTexts
end
function SettingsModel:getCameraSensitivityTexts()
    return self.cameraSensitivityStrings
end
function SettingsModel:getVehicleArmSensitivityTexts()
    return self.vehicleArmSensitivityStrings
end
function SettingsModel:getRealBeaconLightBrightnessTexts()
    return self.realBeaconLightBrightnessStrings
end
function SettingsModel:getSteeringBackSpeedTexts()
    return self.steeringBackSpeedStrings
end
function SettingsModel:getSteeringSensitivityTexts()
    return self.steeringSensitivityStrings
end
function SettingsModel:getMoneyUnitTexts()
    return self.moneyUnitTexts
end
function SettingsModel:getDistanceUnitTexts()
    return self.distanceUnitTexts
end
function SettingsModel:getTemperatureUnitTexts()
    return self.temperatureUnitTexts
end
function SettingsModel:getAreaUnitTexts()
    return self.areaUnitTexts
end
function SettingsModel:getRadioModeTexts()
    return self.radioModeTexts
end
function SettingsModel:getResolutionScaleTexts()
    return self.resolutionScaleTexts
end
function SettingsModel:getResolutionScale3dTexts()
    return self.resolutionScale3dTexts
end
function SettingsModel:makeDefaultReaderFunction()
    return function(gameSettingsKey)
        return g_gameSettings:getValue(gameSettingsKey)
    end
end
function SettingsModel:makeDefaultWriterFunction()
    return function(value, gameSettingsKey)
        g_gameSettings:setValue(gameSettingsKey, value)
    end
end
function SettingsModel:addDirectSetting(gameSettingsKey, restartRequired)
    self:addSetting(gameSettingsKey, self.defaultReaderFunction, self.defaultWriterFunction, restartRequired)
end
function SettingsModel:addPerformanceClassSetting()
    self:addSetting(SettingsModel.SETTING.PERFORMANCE_CLASS, function()
        local perfomanceClassName, _isCustom = getPerformanceClass()
        return Utils.getPerformanceClassIndex(perfomanceClassName)
    end, function(value)
        local class = Utils.getPerformanceClassFromIndex(value)
        setPerformanceClass(class)
        if g_terrainNode ~= nil then
            local foliageViewCoeff = getFoliageViewDistanceCoeff()
            local lodBlendStart, lodBlendEnd = getTerrainLodBlendDynamicDistances(g_terrainNode)
            setTerrainLodBlendDynamicDistances(g_terrainNode, lodBlendStart * foliageViewCoeff, lodBlendEnd * foliageViewCoeff)
        end
        local foliageViewCoeff = GameSettings.PERFORMANCE_CLASS_PRESETS[Utils.getPerformanceClassId()]
        g_gameSettings:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, foliageViewCoeff[SettingsModel.SETTING.LIGHTS_PROFILE])
        g_gameSettings:setValue(SettingsModel.SETTING.MAX_MIRRORS, foliageViewCoeff[SettingsModel.SETTING.MAX_MIRRORS])
        g_gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, foliageViewCoeff[SettingsModel.SETTING.REAL_BEACON_LIGHTS])
    end)
end
function SettingsModel:addPerformanceModeSetting()
    self:addSetting(SettingsModel.SETTING.PERFORMANCE_MODE, function()
        return getIsPerformanceModeActive()
    end, function(value)
        setIsPerformanceModeActive(value)
    end)
end
function SettingsModel:addHDRPeakBrightnessSetting()
    self:addSetting(SettingsModel.SETTING.HDR_PEAK_BRIGHTNESS, function()
        -- upvalues: (copy) self
        return Utils.getValueIndex(getBrightnessNits(), self.hdrPeakBrightnessValues)
    end, function(value)
        -- upvalues: (copy) self
        setBrightnessNits(self.hdrPeakBrightnessValues[value])
    end)
end
function SettingsModel:addHDRContrastSetting()
    self:addSetting(SettingsModel.SETTING.HDR_CONTRAST, function()
        -- upvalues: (copy) self
        local hdrGamma = getHDRGamma()
        return Utils.getValueIndex(hdrGamma, self.hdrContrastValues)
    end, function(value)
        -- upvalues: (copy) self
        setHDRGamma(self.hdrContrastValues[value])
    end)
end
function SettingsModel:addOverlayBrightnessSetting()
    self:addSetting(SettingsModel.SETTING.OVERLAY_BRIGHTNESS, function()
        -- upvalues: (copy) self
        return Utils.getValueIndex(getOverlayBrightnessNits(), self.overlayBrightnessValues)
    end, function(value)
        -- upvalues: (copy) self
        setOverlayBrightnessNits(self.overlayBrightnessValues[value])
    end)
end
function SettingsModel:addHDREnabledSetting()
    self:addSetting(SettingsModel.SETTING.HDR_ENABLED, function()
        return getScreenHdrOutput() or false
    end, function(value)
        setScreenHdrOutput(value)
    end)
end
function SettingsModel:addFidelityFxSR30FrameGenerationSetting()
    self:addSetting(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, function()
        return getFidelityFxSR30FrameInterpolation()
    end, function(value)
        setFidelityFxSR30FrameInterpolation(value)
    end)
end
function SettingsModel:addXeSSFrameGenerationSetting()
    self:addSetting(SettingsModel.SETTING.XESS_FRAME_GENERATION, function()
        return getXeSSFrameInterpolation()
    end, function(value)
        setXeSSFrameInterpolation(value)
    end)
end
function SettingsModel:addDLSSFrameGenerationSetting()
    self:addSetting(SettingsModel.SETTING.DLSS_FRAME_GENERATION, function()
        return getDLSSFrameInterpolation()
    end, function(value)
        setDLSSFrameInterpolation(value)
    end)
end
function SettingsModel:addDRSTargetFPSSetting()
    self:addSetting(SettingsModel.SETTING.DRS_TARGET_FPS, function()
        -- upvalues: (copy) self
        return self.drsTargetFPSMapping[getDRSTargetFPS()]
    end, function(value)
        -- upvalues: (copy) self
        local newValue = self.drsTargetFPSMappingReverse[value]
        if getDRSTargetFPS() ~= newValue then
            setDRSTargetFPS(newValue)
        end
    end)
end
function SettingsModel:addSharpnessSetting()
    self:addSetting(SettingsModel.SETTING.SHARPNESS, function()
        -- upvalues: (copy) self
        local sharpness = getSharpness()
        local index = math.clamp(sharpness, self.minSharpness, self.maxSharpness)
        return MathUtil.round((index - self.minSharpness) / self.sharpnessStep + 1)
    end, function(index)
        -- upvalues: (copy) self
        setSharpness(self.minSharpness + self.sharpnessStep * (index - 1))
    end)
end
function SettingsModel:addShadingRateQualitySetting()
    self:addSetting(SettingsModel.SETTING.SHADING_RATE_QUALITY, function()
        return getShadingRateQuality() + 1
    end, function(value)
        setShadingRateQuality((math.max(value - 1, 0)))
    end)
end
function SettingsModel:addSSAOQualitySetting()
    self:addSetting(SettingsModel.SETTING.SSAO_QUALITY, function()
        return getSSAOQuality()
    end, function(value)
        setSSAOQuality(value)
    end)
end
function SettingsModel:addCloudShadowsQualitySetting()
    self:addSetting(SettingsModel.SETTING.CLOUD_SHADOWS_QUALITY, function()
        return getCloudShadowsQuality() == 1
    end, function(value)
        setCloudShadowsQuality(value and 1 or 0)
    end)
end
function SettingsModel:addTextureResolutionSetting()
    self:addSetting(SettingsModel.SETTING.TEXTURE_RESOLUTION, function()
        return SettingsModel.getTextureResolutionIndex(getTextureResolution())
    end, function(value)
        setTextureResolution(SettingsModel.getTextureResolutionByIndex(value))
    end)
end
function SettingsModel:addShadowQualitySetting()
    self:addSetting(SettingsModel.SETTING.SHADOW_QUALITY, function()
        return SettingsModel.getShadowQualityIndex(getShadowQuality(), getHasShadowFocusBox())
    end, function(value)
        setShadowQuality(SettingsModel.getShadowQualityByIndex(value), SettingsModel.getHasShadowFocusBoxByIndex(value))
    end)
end
function SettingsModel:addShadowDistanceQualitySetting()
    self:addSetting(SettingsModel.SETTING.SHADOW_DISTANCE_QUALITY, function()
        return getShadowDistanceQuality() + 1
    end, function(value)
        setShadowDistanceQuality((math.max(value - 1, 0)))
    end)
end
function SettingsModel:addSoftShadowsSetting()
    self:addSetting(SettingsModel.SETTING.SOFT_SHADOWS, function()
        return getShadowFilterQuality() + 1
    end, function(value)
        setShadowFilterQuality((math.max(value - 1, 0)))
    end)
end
function SettingsModel:addShaderQualitySetting()
    self:addSetting(SettingsModel.SETTING.SHADER_QUALITY, function()
        return SettingsModel.getShaderQualityIndex(getShaderQuality())
    end, function(value)
        setShaderQuality(SettingsModel.getShaderQualityByIndex(value))
    end)
end
function SettingsModel:addShadowMapFilteringSetting()
    self:addSetting(SettingsModel.SETTING.SHADOW_MAP_FILTERING, function()
        return SettingsModel.getShadowMapFilterIndex(getShadowMapFilterSize())
    end, function(value)
        setShadowMapFilterSize(SettingsModel.getShadowMapFilterByIndex(value))
    end)
end
function SettingsModel:addShadowMaxLightsSetting()
    self:addSetting(SettingsModel.SETTING.MAX_LIGHTS, function()
        return getMaxNumShadowLights()
    end, function(value)
        setMaxNumShadowLights(value)
    end)
end
function SettingsModel:addTerrainQualitySetting()
    self:addSetting(SettingsModel.SETTING.TERRAIN_QUALITY, function()
        return SettingsModel.getTerrainQualityIndex(getTerrainQuality())
    end, function(value)
        setTerrainQuality(SettingsModel.getTerrainQualityByIndex(value))
    end)
end
function SettingsModel:addObjectDrawDistanceSetting()
    self:addSetting(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE, function()
        -- upvalues: (copy) self
        return Utils.getValueIndex(getViewDistanceCoeff(), self.percentValues)
    end, function(value)
        -- upvalues: (copy) self
        setViewDistanceCoeff(self.percentValues[value])
    end)
end
function SettingsModel:addFoliageDrawDistanceSetting()
    self:addSetting(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE, function()
        -- upvalues: (copy) self
        return Utils.getValueIndex(getFoliageViewDistanceCoeff(), self.percentValues)
    end, function(value)
        -- upvalues: (copy) self
        setFoliageViewDistanceCoeff(self.percentValues[value])
    end)
end
function SettingsModel:addFoliageShadowSetting()
    self:addSetting(SettingsModel.SETTING.FOLIAGE_SHADOW, function()
        return getAllowFoliageShadows()
    end, function(value)
        setAllowFoliageShadows(value)
    end)
end
function SettingsModel:addLODDistanceSetting()
    self:addSetting(SettingsModel.SETTING.LOD_DISTANCE, function()
        -- upvalues: (copy) self
        return Utils.getValueIndex(getLODDistanceCoeff(), self.percentValues)
    end, function(value)
        -- upvalues: (copy) self
        setLODDistanceCoeff(self.percentValues[value])
    end)
end
function SettingsModel:addTerrainLODDistanceSetting()
    self:addSetting(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE, function()
        -- upvalues: (copy) self
        return Utils.getValueIndex(getTerrainLODDistanceCoeff(), self.percentValues)
    end, function(value)
        -- upvalues: (copy) self
        setTerrainLODDistanceCoeff(self.percentValues[value])
    end)
end
function SettingsModel:addFoliageLODDistanceSetting()
    self:addSetting(SettingsModel.SETTING.FOLIAGE_LOD_DISTANCE, function()
        -- upvalues: (copy) self
        return Utils.getValueIndex(getFoliageLODDistanceCoeff(), self.percentValues)
    end, function(value)
        -- upvalues: (copy) self
        setFoliageLODDistanceCoeff(self.percentValues[value])
    end)
end
function SettingsModel:addVolumeMeshTessellationSetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION, function()
        -- upvalues: (copy) self
        return Utils.getValueIndex(SettingsModel.getVolumeMeshTessellationCoeff(), self.percentValues)
    end, function(value)
        -- upvalues: (copy) self
        SettingsModel.setVolumeMeshTessellationCoeff(self.percentValues[value])
    end)
end
function SettingsModel:addMaxTireTracksSetting()
    self:addSetting(SettingsModel.SETTING.MAX_TIRE_TRACKS, function()
        -- upvalues: (copy) self
        return Utils.getValueIndex(getTyreTracksSegmentsCoeff(), self.tireTracksValues)
    end, function(value)
        -- upvalues: (copy) self
        setTyreTracksSegmentsCoeff(self.tireTracksValues[value])
    end)
end
function SettingsModel:addLightsProfileSetting()
    self:addSetting(SettingsModel.SETTING.LIGHTS_PROFILE, function()
        return g_gameSettings:getValue(SettingsModel.SETTING.LIGHTS_PROFILE)
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, value)
    end)
end
function SettingsModel:addRealBeaconLightsSetting()
    self:addSetting(SettingsModel.SETTING.REAL_BEACON_LIGHTS, function()
        return g_gameSettings:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS)
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, value)
    end)
end
function SettingsModel:addMaxMirrorsSetting()
    self:addSetting(SettingsModel.SETTING.MAX_MIRRORS, function()
        return SettingsModel.getNumOfReflectionMapsIndex(g_gameSettings:getValue(SettingsModel.SETTING.MAX_MIRRORS))
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.MAX_MIRRORS, SettingsModel.getNumOfReflectionMapsByIndex(value))
    end)
end
function SettingsModel:addLanguageSetting()
    self:addSetting(SettingsModel.SETTING.LANGUAGE, function()
        return g_settingsLanguageGUI + 1
    end, function(value)
        g_settingsLanguageGUI = value - 1
        setLanguage(g_availableLanguagesTable[value])
    end, true)
end
function SettingsModel:addMPLanguageSetting()
    self:addSetting(SettingsModel.SETTING.MP_LANGUAGE, function()
        return g_gameSettings:getValue(SettingsModel.SETTING.MP_LANGUAGE) + 1
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.MP_LANGUAGE, value - 1)
    end)
end
function SettingsModel:addInputHelpModeSetting()
    self:addSetting(SettingsModel.SETTING.INPUT_HELP_MODE, function()
        return g_gameSettings:getValue(SettingsModel.SETTING.INPUT_HELP_MODE)
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.INPUT_HELP_MODE, value)
    end)
end
function SettingsModel:addFrameLimitSetting()
    self:addSetting(SettingsModel.SETTING.FRAME_LIMIT, function()
        -- upvalues: (copy) self
        return self.frameLimitMapping[g_gameSettings:getValue(SettingsModel.SETTING.FRAME_LIMIT)]
    end, function(value)
        -- upvalues: (copy) self
        local frameLimit = self.frameLimitMappingReverse[value]
        g_gameSettings:setValue(SettingsModel.SETTING.FRAME_LIMIT, frameLimit)
        if Platform.hasAdjustableFrameLimit and g_currentMission ~= nil then
            setFramerateLimiter(true, frameLimit)
        end
    end)
end
function SettingsModel:addBrightnessSetting()
    self:addSetting(SettingsModel.SETTING.BRIGHTNESS, function()
        -- upvalues: (copy) self
        local brightness = getBrightness()
        local index = math.clamp(brightness, self.minBrightness, self.maxBrightness)
        return MathUtil.round((index - self.minBrightness) / self.brightnessStep + 1)
    end, function(index)
        -- upvalues: (copy) self
        setBrightness((math.clamp(self.minBrightness + self.brightnessStep * (index - 1), self.minBrightness, self.maxBrightness)))
    end)
end
function SettingsModel:addVSyncSetting()
    self:addSetting(SettingsModel.SETTING.V_SYNC, function()
        return getVsync()
    end, function(value)
        setVsync(value)
    end)
end
function SettingsModel:addFovYSetting()
    self:addSetting(SettingsModel.SETTING.FOV_Y, function()
        -- upvalues: (copy) self
        local fovY = math.deg((g_gameSettings:getValue(SettingsModel.SETTING.FOV_Y)))
        return self.fovYToIndexMapping[math.min(math.max(math.floor(fovY + 0.5), (math.deg(Platform.minFovY))), (math.deg(Platform.maxFovY)))]
    end, function(value)
        -- upvalues: (copy) self
        g_gameSettings:setValue(SettingsModel.SETTING.FOV_Y, (math.rad(self.indexToFovYMapping[value])))
    end)
end
function SettingsModel:addFovYPlayerFirstPersonSetting()
    self:addSetting(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON, function()
        -- upvalues: (copy) self
        local fovY = math.deg((g_gameSettings:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON)))
        return self.fovYToIndexMapping[math.min(math.max(math.floor(fovY + 0.5), (math.deg(Platform.minFovY))), (math.deg(Platform.maxFovY)))]
    end, function(value)
        -- upvalues: (copy) self
        g_gameSettings:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON, (math.rad(self.indexToFovYMapping[value])))
    end)
end
function SettingsModel:addFovYPlayerThirdPersonSetting()
    self:addSetting(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON, function()
        -- upvalues: (copy) self
        local fovY = math.deg((g_gameSettings:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON)))
        return self.fovYToIndexMapping[math.min(math.max(math.floor(fovY + 0.5), (math.deg(Platform.minFovY))), (math.deg(Platform.maxFovY)))]
    end, function(value)
        -- upvalues: (copy) self
        g_gameSettings:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON, (math.rad(self.indexToFovYMapping[value])))
    end)
end
function SettingsModel:addUIScaleSetting()
    self:addSetting(SettingsModel.SETTING.UI_SCALE, function()
        return Utils.getUIScaleIndex(g_gameSettings:getValue(SettingsModel.SETTING.UI_SCALE))
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.UI_SCALE, Utils.getUIScaleFromIndex(value))
    end)
end
function SettingsModel:addResolutionScaleSetting()
    self:addSetting(SettingsModel.SETTING.RESOLUTION_SCALE, function()
        return SettingsModel.getScalingStateFromResolutionScaling(getResolutionScaling())
    end, function(value)
        setResolutionScaling(SettingsModel.getScalingFromResolutionScalingState(value))
    end)
end
function SettingsModel:addResolutionScale3dSetting()
    self:addSetting(SettingsModel.SETTING.RESOLUTION_SCALE_3D, function()
        return SettingsModel.getScalingStateFromResolutionScaling(get3dResolutionScaling())
    end, function(value)
        set3dResolutionScaling(SettingsModel.getScalingFromResolutionScalingState(value))
    end)
end
function SettingsModel:addCameraSensitivitySetting()
    self:addSetting(SettingsModel.SETTING.CAMERA_SENSITIVITY, function()
        -- upvalues: (copy) self
        return Utils.getStateFromValues(self.cameraSensitivityValues, self.cameraSensitivityStep, g_gameSettings:getValue(SettingsModel.SETTING.CAMERA_SENSITIVITY))
    end, function(value)
        -- upvalues: (copy) self
        g_gameSettings:setValue(SettingsModel.SETTING.CAMERA_SENSITIVITY, self.cameraSensitivityValues[value])
    end)
end
function SettingsModel:addVehicleArmSensitivitySetting()
    self:addSetting(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY, function()
        -- upvalues: (copy) self
        return Utils.getStateFromValues(self.vehicleArmSensitivityValues, self.vehicleArmSensitivityStep, g_gameSettings:getValue(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY))
    end, function(value)
        -- upvalues: (copy) self
        g_gameSettings:setValue(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY, self.vehicleArmSensitivityValues[value])
    end)
end
function SettingsModel:addRealBeaconLightBrightnessSetting()
    self:addSetting(SettingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS, function()
        -- upvalues: (copy) self
        return Utils.getStateFromValues(self.realBeaconLightBrightnessValues, self.realBeaconLightBrightnessStep, g_gameSettings:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS))
    end, function(value)
        -- upvalues: (copy) self
        g_gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS, self.realBeaconLightBrightnessValues[value])
    end)
end
function SettingsModel:addActiveCameraSuspensionSetting()
    self:addSetting(SettingsModel.SETTING.ACTIVE_SUSPENSION_CAMERA, self.defaultReaderFunction, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.ACTIVE_SUSPENSION_CAMERA, value)
        g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA], value)
    end)
end
function SettingsModel:addCamerCheckCollisionSetting()
    self:addSetting(SettingsModel.SETTING.CAMERA_CHECK_COLLISION, self.defaultReaderFunction, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.CAMERA_CHECK_COLLISION, value)
        g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.CAMERA_CHECK_COLLISION], value)
    end)
end
function SettingsModel:addDirectionChangeModeSetting()
    self:addSetting(SettingsModel.SETTING.DIRECTION_CHANGE_MODE, self.defaultReaderFunction, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.DIRECTION_CHANGE_MODE, value)
        g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.DIRECTION_CHANGE_MODE], value)
    end)
end
function SettingsModel:addGearShiftModeSetting()
    self:addSetting(SettingsModel.SETTING.GEAR_SHIFT_MODE, self.defaultReaderFunction, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.GEAR_SHIFT_MODE, value)
        g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.GEAR_SHIFT_MODE], value)
    end)
end
function SettingsModel:addHudSpeedGaugeSetting()
    self:addSetting(SettingsModel.SETTING.HUD_SPEED_GAUGE, self.defaultReaderFunction, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.HUD_SPEED_GAUGE, value)
        g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.HUD_SPEED_GAUGE], value)
    end)
end
function SettingsModel:addWoodHarvesterAutoCutSetting()
    self:addSetting(SettingsModel.SETTING.WOOD_HARVESTER_AUTO_CUT, self.defaultReaderFunction, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.WOOD_HARVESTER_AUTO_CUT, value)
        g_messageCenter:publish(MessageType.SETTING_CHANGED[GameSettings.SETTING.WOOD_HARVESTER_AUTO_CUT], value)
    end)
end
function SettingsModel:addMasterVolumeSetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_MASTER, function()
        return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_MASTER))
    end, function(value)
        local volume = Utils.getMasterVolumeFromIndex(value)
        g_soundMixer:setMasterVolume(volume)
        g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_MASTER, volume)
    end)
end
function SettingsModel:addMusicVolumeSetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_MUSIC, function()
        return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_MUSIC))
    end, function(value)
        local volume = Utils.getMasterVolumeFromIndex(value)
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.MENU_MUSIC, volume)
        g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_MUSIC, volume)
    end)
end
function SettingsModel:addEnvironmentVolumeSetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_ENVIRONMENT, function()
        return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT))
    end, function(value)
        local volume = Utils.getMasterVolumeFromIndex(value)
        g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT, volume)
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, volume)
    end)
end
function SettingsModel:addVehicleVolumeSetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_VEHICLE, function()
        return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_VEHICLE))
    end, function(value)
        local volume = Utils.getMasterVolumeFromIndex(value)
        g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_VEHICLE, volume)
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, volume)
    end)
end
function SettingsModel:addRadioVolumeSetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_RADIO, function()
        return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_RADIO))
    end, function(value)
        local volume = Utils.getMasterVolumeFromIndex(value)
        g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_RADIO, volume)
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, volume)
    end)
end
function SettingsModel:addVoiceVolumeSetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_VOICE, function()
        return Utils.getMasterVolumeIndex(VoiceChatUtil.getOutputVolume())
    end, function(value)
        local volume = Utils.getMasterVolumeFromIndex(value)
        g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_VOICE, volume)
        VoiceChatUtil.setOutputVolume(volume)
    end)
end
function SettingsModel:addVoiceInputVolumeSetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_VOICE_INPUT, function()
        return Utils.getRecordingVolumeIndex(VoiceChatUtil.getInputVolume())
    end, function(value)
        local volume = Utils.getRecordingVolumeFromIndex(value)
        g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_VOICE_INPUT, volume)
        VoiceChatUtil.setInputVolume(volume)
    end)
end
function SettingsModel:addVoiceModeSetting()
    self:addSetting(SettingsModel.SETTING.VOICE_MODE, function()
        return VoiceChatUtil.getInputMode()
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.VOICE_MODE, value)
        VoiceChatUtil.setInputMode(value)
    end)
end
function SettingsModel:addVoiceInputSensitivitySetting()
    self:addSetting(SettingsModel.SETTING.VOICE_INPUT_SENSITIVITY, function()
        return g_gameSettings:getValue(SettingsModel.SETTING.VOICE_INPUT_SENSITIVITY)
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.VOICE_INPUT_SENSITIVITY, value)
        local threshold = -1
        if value > 1 then
            threshold = (value - 2) / 10
        end
        VoiceChatUtil.setInputSensitivity(threshold)
    end)
end
function SettingsModel:addVolumeGUISetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_GUI, function()
        return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_GUI))
    end, function(value)
        local volume = Utils.getMasterVolumeFromIndex(value)
        g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_GUI, volume)
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, volume)
    end)
end
function SettingsModel:addVolumeNoFocusSetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_NO_FOCUS, function()
        return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_NO_FOCUS))
    end, function(value)
        local volume = Utils.getMasterVolumeFromIndex(value)
        g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_NO_FOCUS, volume)
        setInactiveWindowAudioVolume(volume)
    end)
end
function SettingsModel:addVolumeCharacterSetting()
    self:addSetting(SettingsModel.SETTING.VOLUME_CHARACTER, function()
        return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.VOLUME_CHARACTER))
    end, function(value)
        local volume = Utils.getMasterVolumeFromIndex(value)
        g_gameSettings:setValue(SettingsModel.SETTING.VOLUME_CHARACTER, volume)
        g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.CHARACTER, volume)
    end)
end
function SettingsModel:addSteeringBackSpeedSetting()
    self:addSetting(SettingsModel.SETTING.STEERING_BACK_SPEED, function()
        -- upvalues: (copy) self
        return Utils.getStateFromValues(self.steeringBackSpeedValues, self.steeringBackSpeedStep, g_gameSettings:getValue(SettingsModel.SETTING.STEERING_BACK_SPEED))
    end, function(value)
        -- upvalues: (copy) self
        g_gameSettings:setValue(SettingsModel.SETTING.STEERING_BACK_SPEED, self.steeringBackSpeedValues[value])
    end)
end
function SettingsModel:addSteeringSensitivitySetting()
    self:addSetting(SettingsModel.SETTING.STEERING_SENSITIVITY, function()
        -- upvalues: (copy) self
        return Utils.getStateFromValues(self.steeringSensitivityValues, self.steeringSensitivityStep, g_gameSettings:getValue(SettingsModel.SETTING.STEERING_SENSITIVITY))
    end, function(value)
        -- upvalues: (copy) self
        g_gameSettings:setValue(SettingsModel.SETTING.STEERING_SENSITIVITY, self.steeringSensitivityValues[value])
    end)
end
function SettingsModel:addGyroscopeSteeringSetting()
    self:addSetting(SettingsModel.SETTING.GYROSCOPE_STEERING, function()
        return g_gameSettings:getValue(SettingsModel.SETTING.GYROSCOPE_STEERING)
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.GYROSCOPE_STEERING, value)
    end)
end
function SettingsModel:addHintsSetting()
    self:addSetting(SettingsModel.SETTING.HINTS, function()
        return g_gameSettings:getValue(SettingsModel.SETTING.HINTS)
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.HINTS, value)
    end)
end
function SettingsModel:addCameraTiltingSetting()
    self:addSetting(SettingsModel.SETTING.CAMERA_TILTING, function()
        return g_gameSettings:getValue(SettingsModel.SETTING.CAMERA_TILTING)
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.CAMERA_TILTING, value)
    end)
end
function SettingsModel:addForceFeedbackSetting()
    self:addSetting(SettingsModel.SETTING.FORCE_FEEDBACK, function()
        return Utils.getMasterVolumeIndex(g_gameSettings:getValue(SettingsModel.SETTING.FORCE_FEEDBACK))
    end, function(value)
        g_gameSettings:setValue(SettingsModel.SETTING.FORCE_FEEDBACK, Utils.getMasterVolumeFromIndex(value))
    end)
end
function SettingsModel:addEngineQualitySetting(key, enum, supportFunc, nameFunc, setFunc, getFunc, onChangedFunc, excludeOffText, restartRequired)
    local texts = {}
    local mapping = {}
    local mappingReverse = {}
    local enumOrdered = {}
    for name, quality in pairs(enum) do
        enumOrdered[quality + 1] = name
    end
    local numMappings = 1
    for quality, name in ipairs(enumOrdered) do
        local quality = quality - 1
        if quality ~= enum.NUM and (supportFunc == nil or supportFunc(quality)) then
            if excludeOffText and quality == enum.OFF then
                mapping[quality] = -1
                mappingReverse[-1] = quality
            else
                local text = self.qualityTexts[name]
                if text == nil and nameFunc ~= nil then
                    text = nameFunc(quality)
                end
                table.insert(texts, text)
                mapping[quality] = numMappings
                mappingReverse[numMappings] = quality
                numMappings = numMappings + 1
            end
        end
    end
    self:addSetting(key, function()
        -- upvalues: (copy) mapping, (copy) getFunc
        return mapping[getFunc()]
    end, function(value)
        -- upvalues: (copy) mappingReverse, (copy) getFunc, (copy) setFunc
        local newValue = mappingReverse[value]
        if newValue ~= nil and getFunc() ~= newValue then
            setFunc(newValue)
        end
    end, Utils.getNoNil(restartRequired, false), function()
        -- upvalues: (copy) texts
        return texts
    end, function(value)
        -- upvalues: (copy) mapping
        return mapping[value]
    end, function(value)
        -- upvalues: (copy) mappingReverse
        return mappingReverse[value]
    end, onChangedFunc)
end
function SettingsModel.getShadowQualityIndex(shadowQuality, hasShadowFocusBox)
    return shadowQuality == 1 and 2 or (shadowQuality == 2 and hasShadowFocusBox == false and 3 or (shadowQuality == 2 and hasShadowFocusBox == true and 4 or 1))
end
function SettingsModel.getShadowQualityByIndex(shadowIndex)
    return shadowIndex == 2 and 1 or (shadowIndex == 3 and 2 or (shadowIndex == 4 and 2 or 0))
end
function SettingsModel.getHasShadowFocusBoxByIndex(shadowIndex)
    if shadowIndex == 2 then
        return false
    elseif shadowIndex == 3 then
        return false
    else
        return shadowIndex == 4
    end
end
function SettingsModel.getShaderQualityIndex(shaderQuality)
    return shaderQuality == 1 and 2 or (shaderQuality == 2 and 3 or (shaderQuality == 3 and 4 or 1))
end
function SettingsModel.getShaderQualityByIndex(shaderIndex)
    return shaderIndex == 2 and 1 or (shaderIndex == 3 and 2 or (shaderIndex == 4 and 3 or 0))
end
function SettingsModel.getShadowMapFilterIndex(shadowFilter)
    return shadowFilter == 16 and 2 or 1
end
function SettingsModel.getShadowMapFilterByIndex(shadowFilterIndex)
    return shadowFilterIndex == 2 and 16 or 4
end
function SettingsModel.getTerrainQualityIndex(terrainQuality)
    return math.min(math.max(terrainQuality + 1, 1), 4)
end
function SettingsModel.getTerrainQualityByIndex(terrainQualityIndex)
    return math.min(math.max(terrainQualityIndex - 1, 0), 3)
end
function SettingsModel.getTextureResolutionIndex(textureResolution)
    return textureResolution == 0 and 2 or 1
end
function SettingsModel.getTextureResolutionByIndex(textureResolutionIndex)
    return textureResolutionIndex == 2 and 0 or 1
end
function SettingsModel.getNumOfReflectionMapsByIndex(index)
    return math.clamp(index - 1, 0, 7)
end
function SettingsModel.getNumOfReflectionMapsIndex(numOfReflectionMaps)
    return math.clamp(numOfReflectionMaps, 0, 7) + 1
end
function SettingsModel.getVolumeMeshTessellationCoeff()
    return 0.5 + (2 - getVolumeMeshTessellationCoeff())
end
function SettingsModel.setVolumeMeshTessellationCoeff(coeff)
    setVolumeMeshTessellationCoeff(2 + (0.5 - coeff))
end
function SettingsModel.getScalingFromResolutionScalingState(state)
    return 0.4 + 0.1 * state
end
function SettingsModel.getScalingStateFromResolutionScaling(scaling)
    return MathUtil.round((scaling - 0.4) * 10)
end