SettingsAdvancedFrame = {}
local SettingsAdvancedFrame_mt = Class(SettingsAdvancedFrame, TabbedMenuFrameElement)
function SettingsAdvancedFrame.register()
    local settingsAdvancedFrame = SettingsAdvancedFrame.new()
    g_gui:loadGui("dataS/gui/SettingsAdvancedFrame.xml", "SettingsAdvancedFrame", settingsAdvancedFrame, true)
end
function SettingsAdvancedFrame.new(target, custom_mt)
    -- upvalues: (copy) SettingsAdvancedFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsAdvancedFrame_mt)
    self.hasCustomMenuButtons = true
    return self
end
function SettingsAdvancedFrame.createFromExistingGui(gui, guiName)
    local newGui = SettingsAdvancedFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    newGui.hasCustomMenuButtons = gui.hasCustomMenuButtons
    return newGui
end
function SettingsAdvancedFrame:copyAttributes(src)
    SettingsAdvancedFrame:superClass().copyAttributes(self, src)
    self.hasCustomMenuButtons = src.hasCustomMenuButtons
end
function SettingsAdvancedFrame:initialize()
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK
    }
    self.nextPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_NEXT,
        ["text"] = g_i18n:getText("ui_ingameMenuNext"),
        ["callback"] = self.onPageNext
    }
    self.prevPageButtonInfo = {
        ["inputAction"] = InputAction.MENU_PAGE_PREV,
        ["text"] = g_i18n:getText("ui_ingameMenuPrev"),
        ["callback"] = self.onPagePrevious
    }
    self.applyButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(SettingsAdvancedFrame.L10N_SYMBOL.BUTTON_APPLY),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onApplySettings()
        end
    }
    self.settingElements = {}
    local function addElement(settingsKey, element, isMultiElement)
        -- upvalues: (copy) self
        self.settingElements[element] = {
            ["settingsKey"] = settingsKey,
            ["element"] = element,
            ["isMultiElement"] = isMultiElement
        }
        local texts = g_settingsModel:getTexts(settingsKey)
        if texts == nil then
            element:setVisible(false)
        else
            if #texts == 0 then
                table.insert(texts, g_i18n:getText("ui_unavailable"))
                element.parent:setDisabled(true)
            else
                element.parent:setDisabled(false)
            end
            if isMultiElement or #texts == 2 then
                element:setTexts(texts)
                return
            end
        end
    end
    addElement(SettingsModel.SETTING.POST_PROCESS_AA, self.ppaaElement, true)
    addElement(SettingsModel.SETTING.MSAA, self.msaaElement, true)
    addElement(SettingsModel.SETTING.LENSFLARE_QUALITY, self.lensFlareQualityElement, true)
    addElement(SettingsModel.SETTING.VALAR, self.valarElement, true)
    addElement(SettingsModel.SETTING.SCREEN_SPACE_REFLECTIONS, self.screenSpaceReflectionsElement, true)
    addElement(SettingsModel.SETTING.SCREEN_SPACE_SHADOWS_QUALITY, self.screenSpaceShadowsQualityElement, false)
    addElement(SettingsModel.SETTING.DRS_QUALITY, self.drsQualityElement, true)
    addElement(SettingsModel.SETTING.ATMOSPHERE_QUALITY, self.atmosphereQualityElement, true)
    addElement(SettingsModel.SETTING.VOLUMETRIC_FOG_QUALITY, self.volumetricFogQualityElement, true)
    addElement(SettingsModel.SETTING.TEXTURE_FILTERING, self.textureFilteringElement, true)
end
function SettingsAdvancedFrame:onGuiSetupFinished()
    SettingsAdvancedFrame:superClass().onGuiSetupFinished(self)
    local oldDisableFunc = self.msaaContainer.setDisabled
    for _, container in pairs(self.boxLayout.elements) do
        if container:getDescendantByName("iconDisabled") ~= nil then
            function container.setDisabled(container, disabled)
                -- upvalues: (copy) oldDisableFunc
                oldDisableFunc(container, disabled)
                container:getDescendantByName("iconDisabled"):setDisabled(not disabled)
            end
        end
    end
    function self.frameGenerationContainer.getIsActiveNonRec()
        -- upvalues: (copy) self
        return self.frameGenerationElement:getIsActiveNonRec()
    end
    self.scalingModeNameToIndexMapping = {}
    for _, container in pairs(g_settingsModel:getScalingModeTexts()) do
        for index, scalingMode in pairs(SettingsAdvancedFrame.SCALING_MODES) do
            if g_i18n:getText(scalingMode.title) == container then
                self.scalingModeNameToIndexMapping[container] = index
                break
            end
        end
    end
end
function SettingsAdvancedFrame:onApplySettings()
    local needsRestart, needsProcessRestart = g_settingsModel:needsRestartToApplyChanges()
    g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
    if needsRestart then
        RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
        InfoDialog.show(g_i18n:getText("dialog_restartToApplyChanges"), function()
            -- upvalues: (copy) needsProcessRestart
            doRestart(needsProcessRestart, "")
        end, nil)
    else
        self:setMenuButtonInfoDirty()
    end
end
function SettingsAdvancedFrame:getMenuButtonInfo()
    local buttons = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    if g_settingsModel:hasChanges() then
        table.insert(buttons, self.applyButtonInfo)
    end
    return buttons
end
function SettingsAdvancedFrame:updateValues()
    self:updatePerformanceClass()
    for _, data in pairs(self.settingElements) do
        if data.isMultiElement then
            data.element:setState(g_settingsModel:getValue(data.settingsKey) or 1)
        else
            local isNativeXeSS = g_settingsModel:getValue(data.settingsKey) == BinaryOptionElement.STATE_RIGHT
            data.element:setIsChecked(isNativeXeSS, self.isOpening)
        end
    end
    self.performanceClassElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.PERFORMANCE_CLASS))
    self.msaaElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MSAA))
    self.drsTargetFPSElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.DRS_TARGET_FPS))
    self.sharpnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHARPNESS))
    self.shadingRateQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADING_RATE_QUALITY))
    self.textureFilteringElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TEXTURE_FILTERING))
    self.textureResolutionElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TEXTURE_RESOLUTION))
    self.shadowQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADOW_QUALITY))
    self.shadowDistanceQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADOW_DISTANCE_QUALITY))
    self.softShadowsElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SOFT_SHADOWS))
    self.shaderQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADER_QUALITY))
    self.shadowMapFilteringElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADOW_MAP_FILTERING))
    self.maxLightsElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MAX_LIGHTS))
    self.terrainQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TERRAIN_QUALITY))
    self.objectDrawDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE))
    self.foliageDrawDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE))
    self.lodDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.LOD_DISTANCE))
    self.terrainLODDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE))
    self.foliageLODDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOLIAGE_LOD_DISTANCE))
    self.volumeMeshTessellationElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION))
    self.maxTireTracksElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MAX_TIRE_TRACKS))
    self.lightsProfileElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.LIGHTS_PROFILE) - 1)
    self.realBeaconLightsElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS), self.isOpening)
    self.maxMirrorsElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MAX_MIRRORS))
    self.foliageShadowsElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.FOLIAGE_SHADOW), self.isOpening)
    self.ssaoQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SSAO_QUALITY))
    self.cloudShadowsQualityElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.CLOUD_SHADOWS_QUALITY), self.isOpening)
    self.resolutionScale3dElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D))
    self.fovYElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y))
    self.fovYPlayerFirstPersonElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON))
    self.fovYPlayerThirdPersonElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
    local postProcessAA = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA)
    local isFSR30Active = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30) ~= FidelityFxSR30Quality.OFF
    local _ = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR) ~= FidelityFxSRQuality.OFF
    local data = getSupportsFidelityFxFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
    if data then
        if postProcessAA == PostProcessAntiAliasing.FSR3 or isFSR30Active then
            data = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
        else
            data = isFSR30Active
        end
    end
    local supportsXeSSFrameGeneration = getSupportsXeSSFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
    local isNativeXeSS = postProcessAA == PostProcessAntiAliasing.XESS
    local isXeSSActive = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS) ~= XeSSQuality.OFF
    if supportsXeSSFrameGeneration then
        if isNativeXeSS or isXeSSActive then
            supportsXeSSFrameGeneration = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
        else
            supportsXeSSFrameGeneration = isXeSSActive
        end
    end
    local supportsDLSSFrameGeneration = getSupportsDLSSFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
    local isDLSSActive = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS) ~= DLSSQuality.OFF
    local isDLAAActive = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.DLAA
    if supportsDLSSFrameGeneration then
        if isDLSSActive or isDLAAActive then
            isDLAAActive = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
        end
    else
        isDLAAActive = supportsDLSSFrameGeneration
    end
    local isDRSAvailable = getIsDRSAvailable()
    self.drsQualityContainer:setDisabled(not isDRSAvailable)
    self.drsTargetFPSContainer:setDisabled(not isDRSAvailable)
    self.frameGenerationContainer:setDisabled(not (data or (supportsXeSSFrameGeneration or isDLAAActive)))
    self.resolutionScale3dContainer:setDisabled(isDLSSActive or (isXeSSActive or (isFSR30Active or _)))
    local frameGenerationElementTexts = { getFrameInterpolationModeName(FrameInterpolationMode.FRAME_INTERPOLATION_OFF) }
    local textsFunc = getSupportsDLSSFrameInterpolation
    if supportsXeSSFrameGeneration then
        textsFunc = getSupportsXeSSFrameInterpolation
    elseif data then
        textsFunc = getSupportsFidelityFxFrameInterpolation
    end
    local i = 1
    local frameGenerationState = EnumUtil.getNumEntries(FrameInterpolationMode) - 1
    local settingsKey = 1
    for i = i, frameGenerationState, settingsKey do
        if textsFunc(i) then
            table.insert(frameGenerationElementTexts, getFrameInterpolationModeName(i))
        end
    end
    self.frameGenerationElement:setTexts(frameGenerationElementTexts)
    local settingsKey = g_settingsModel:getValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION)
    local i = g_settingsModel:getValue(SettingsModel.SETTING.XESS_FRAME_GENERATION)
    local isMSAAAllowed = g_settingsModel
    local frameGenerationState = math.max(settingsKey, i, isMSAAAllowed:getValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION))
    self.frameGenerationElement:setState(frameGenerationState + 1)
    if isNativeXeSS or isXeSSActive then
        self.frameGenerationTitle:setText(g_i18n:getText("setting_xeSSFrameGeneration"))
        self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_xeSSFrameGeneration"))
    elseif isNativeFSR3 or isFSR30Active then
        self.frameGenerationTitle:setText(g_i18n:getText("setting_fidelityFxSR30FrameInterpolation"))
        self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_fidelityFxSR30FrameInterpolation"))
    elseif isDLSSActive then
        self.frameGenerationTitle:setText(g_i18n:getText("setting_dlssFrameInterpolation"))
        self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_dlssFrameInterpolation"))
    else
        self.frameGenerationTitle:setText(g_i18n:getText("setting_frameGeneration"))
    end
    local settingsKey = nil
    for _, setting in pairs(SettingsAdvancedFrame.SCALING_MODES) do
        local currentValue = g_settingsModel:getRawValue(setting.name)
        if currentValue ~= nil and currentValue ~= setting.enum.OFF then
            local state = self.scalingModeNameToIndexMapping[g_i18n:getText(setting.title)] or 1
            self.scalingModeElement:setState(state)
            settingsKey = setting.name
            break
        end
    end
    if settingsKey == nil then
        self.scalingModeElement:setState(1)
    else
        local i = g_settingsModel:getTexts(settingsKey)
        if isDRSAvailable and g_settingsModel:getRawValue(SettingsModel.SETTING.DRS_QUALITY) ~= DRSQuality.OFF then
            self.scalingModeQualityElement:setTexts({ g_i18n:getText("ui_auto") })
            self.scalingModeQualityElement:setState(1)
            self.scalingModeQualityContainer:setDisabled(true)
        else
            self.scalingModeQualityElement:setTexts(i)
            self.scalingModeQualityContainer:setDisabled(false)
            self.scalingModeQualityElement:setState(g_settingsModel:getValue(settingsKey))
        end
    end
    local i = true
    if self.ppaaElement:getState() == 1 then
        i = settingsKey ~= nil
    end
    self.sharpnessContainer:setDisabled(not i)
    local isMSAAAllowed = true
    if self.ppaaElement:getState() - 1 == PostProcessAntiAliasing.TAA then
        isMSAAAllowed = self.ppaaElement:getState() - 1 ~= PostProcessAntiAliasing.OFF
    end
    self.msaaContainer:setDisabled(not isMSAAAllowed)
    local setting = settingsKey ~= nil
    self.scalingModeQualityContainer:setDisabled(setting)
    self:setMenuButtonInfoDirty()
    self.boxLayout:invalidateLayout()
end
function SettingsAdvancedFrame:onFrameOpen()
    SettingsAdvancedFrame:superClass().onFrameOpen(self)
    self.isOpening = true
    self:updateValues()
    self:updateAlternatingSettingsBackgrounds()
    self.isOpening = false
end
function SettingsAdvancedFrame:updateAlternatingSettingsBackgrounds()
    local isAlternate = true
    for _, container in pairs(self.boxLayout.elements) do
        if container.name == "sectionHeader" then
            isAlternate = true
        elseif container:getIsVisible() then
            container:setImageColor(nil, unpack(SettingsScreen.COLOR_ALTERNATING[isAlternate]))
            isAlternate = not isAlternate
        end
    end
    self.boxLayout:invalidateLayout()
end
function SettingsAdvancedFrame:updatePerformanceClass()
    local texts, _, _ = g_settingsModel:getPerformanceClassTexts()
    self.performanceClassElement:setTexts(texts)
end
function SettingsAdvancedFrame.onCreatePerformanceClass(_, element)
    local texts, _, _ = g_settingsModel:getPerformanceClassTexts()
    element:setTexts(texts)
end
function SettingsAdvancedFrame.onCreatePPAAToolTip(_, element)
    element:setText(g_settingsModel:getPostProcessAAToolTip())
end
function SettingsAdvancedFrame.onCreateDRSTargetFPS(_, element)
    element:setTexts(g_settingsModel:getDRSTargetFPSTexts())
end
function SettingsAdvancedFrame.onCreateSharpness(_, element)
    element:setTexts(g_settingsModel:getSharpnessTexts())
end
function SettingsAdvancedFrame.onCreateScalingMode(_, element)
    element:setTexts(g_settingsModel:getScalingModeTexts())
end
function SettingsAdvancedFrame.onCreateScalingModeQuality(_, element)
    element:setTexts(g_settingsModel:getTexts(SettingsModel.SETTING.FIDELITYFX_SR))
end
function SettingsAdvancedFrame.onCreateShadingRateQuality(_, element)
    element:setTexts(g_settingsModel:getShadingRateQualityTexts())
end
function SettingsAdvancedFrame.onCreateShadowQuality(_, element)
    element:setTexts(g_settingsModel:getShadowQualityTexts())
end
function SettingsAdvancedFrame.onCreateShadowDistanceQuality(_, element)
    element:setTexts(g_settingsModel:getShadowDistanceQualityTexts())
end
function SettingsAdvancedFrame.onCreateSoftShadows(_, element)
    element:setTexts(g_settingsModel:getSoftShadowsTexts())
end
function SettingsAdvancedFrame.onCreateSSAOQuality(_, element)
    element:setTexts(g_settingsModel:getSSAOQualityTexts())
end
function SettingsAdvancedFrame.onCreateShaderQuality(_, element)
    element:setTexts(g_settingsModel:getShaderQualityTexts())
end
function SettingsAdvancedFrame.onCreateTextureResolution(_, element)
    element:setTexts(g_settingsModel:getTextureResolutionTexts())
end
function SettingsAdvancedFrame.onCreateShadowMapFiltering(_, element)
    element:setTexts(g_settingsModel:getShadowMapFilteringTexts())
end
function SettingsAdvancedFrame.onCreateLightsProfile(_, element)
    element:setTexts(g_settingsModel:getLightsProfileTexts())
end
function SettingsAdvancedFrame.onCreateTerrainQuality(_, element)
    element:setTexts(g_settingsModel:getTerraingQualityTexts())
end
function SettingsAdvancedFrame.onCreateShadowMaxLights(_, element)
    element:setTexts(g_settingsModel:getShadowMapLightsTexts())
end
function SettingsAdvancedFrame.onCreateObjectDrawDistance(_, element)
    element:setTexts(g_settingsModel:getObjectDrawDistanceTexts())
end
function SettingsAdvancedFrame.onCreateFoliageDrawDistance(_, element)
    element:setTexts(g_settingsModel:getFoliageDrawDistanceTexts())
end
function SettingsAdvancedFrame.onCreateLODDistance(_, element)
    element:setTexts(g_settingsModel:getLODDistanceTexts())
end
function SettingsAdvancedFrame.onCreateTerrainLODDistance(_, element)
    element:setTexts(g_settingsModel:getTerrainLODDistanceTexts())
end
function SettingsAdvancedFrame.onCreateFoliageLODDistance(_, element)
    element:setTexts(g_settingsModel:getFoliageLODDistanceTexts())
end
function SettingsAdvancedFrame.onCreateVolumeMeshTessellation(_, element)
    element:setTexts(g_settingsModel:getVolumeMeshTessalationTexts())
end
function SettingsAdvancedFrame.onCreateMaxTireTracks(_, element)
    element:setTexts(g_settingsModel:getMaxTireTracksTexts())
end
function SettingsAdvancedFrame.onCreateMaxMirrors(_, element)
    element:setTexts(g_settingsModel:getMaxMirrorsTexts())
end
function SettingsAdvancedFrame.onCreateResolutionScale3d(_, element)
    element:setTexts(g_settingsModel:getResolutionScale3dTexts())
end
function SettingsAdvancedFrame.onCreateFovY(_, element)
    element:setTexts(g_settingsModel:getFovYTexts())
end
function SettingsAdvancedFrame.onCreateFovYPlayerFirstPerson(_, element)
    element:setTexts(g_settingsModel:getFovYTexts())
end
function SettingsAdvancedFrame.onCreateFovYPlayerThirdPerson(_, element)
    element:setTexts(g_settingsModel:getFovYTexts())
end
function SettingsAdvancedFrame.onCreateFrameGenerationTooltip(_, element)
    if getFidelityFxSuperResolutionVersion() == 4 then
        element:setText(g_i18n:getText("toolTip_frameGenerationDisabledFSR4"))
    end
end
function SettingsAdvancedFrame:onClick(state, element)
    g_settingsModel:setValue(self.settingElements[element].settingsKey, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickPerformanceClass(state)
    g_settingsModel:applyPerformanceClass(state)
    self:updateValues()
end
function SettingsAdvancedFrame:onClickPPAA(state, element)
    g_settingsModel:setValue(self.settingElements[element].settingsKey, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickMSAA(state)
    self.sharpnessContainer:setDisabled(state ~= 1)
    g_settingsModel:setValue(SettingsModel.SETTING.MSAA, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickScalingMode(state)
    local foundSetting = nil
    local settingName = g_settingsModel:getScalingModeTexts()[state]
    for name, index in pairs(self.scalingModeNameToIndexMapping) do
        if name == settingName then
            foundSetting = SettingsAdvancedFrame.SCALING_MODES[index]
        else
            g_settingsModel:setRawValue(setting.name, setting.enum.OFF)
        end
    end
    if foundSetting ~= nil then
        g_settingsModel:setValue(foundSetting.name, 1)
        local texts = g_settingsModel:getTexts(foundSetting.name)
        self.scalingModeQualityElement:setTexts(texts)
    end
    g_settingsModel:applyCustomSettings()
    if not getIsDRSAvailable() then
        g_settingsModel:setRawValue(SettingsModel.SETTING.DRS_QUALITY, DRSQuality.OFF)
    end
    self:updateValues()
end
function SettingsAdvancedFrame:onClickScalingModeQuality(state)
    local foundSetting = nil
    local settingName = g_settingsModel:getScalingModeTexts()[self.scalingModeElement:getState()]
    for name, index in pairs(self.scalingModeNameToIndexMapping) do
        if name == settingName then
            foundSetting = SettingsAdvancedFrame.SCALING_MODES[index]
            break
        end
    end
    g_settingsModel:setValue(foundSetting.name, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickFrameGeneration(_)
    local isNativeXeSS = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.XESS
    local isXeSSActive = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS) ~= XeSSQuality.OFF
    local isDLSSActive = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS) ~= DLSSQuality.OFF
    local isNativeFSR3 = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.FSR3
    local isFSR30Active = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30) ~= FidelityFxSR30Quality.OFF
    if isNativeXeSS or isXeSSActive then
        g_settingsModel:setValue(SettingsModel.SETTING.XESS_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
    elseif isDLSSActive then
        g_settingsModel:setValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
    elseif isNativeFSR3 or isFSR30Active then
        g_settingsModel:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
    end
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickDRSTargetFPS(state)
    g_settingsModel:setValue(SettingsModel.SETTING.DRS_TARGET_FPS, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickSharpness(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHARPNESS, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickShadingRateQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHADING_RATE_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickTextureResolution(state)
    g_settingsModel:setValue(SettingsModel.SETTING.TEXTURE_RESOLUTION, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickShadowQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickShadowDistanceQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_DISTANCE_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickSoftShadows(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SOFT_SHADOWS, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickShaderQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHADER_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickShadowMapFiltering(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_MAP_FILTERING, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickShadowMaxLights(state)
    g_settingsModel:setValue(SettingsModel.SETTING.MAX_LIGHTS, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickTerrainQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.TERRAIN_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickObjectDrawDistance(state)
    g_settingsModel:setValue(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickFoliageDrawDistance(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickLODDistance(state)
    g_settingsModel:setValue(SettingsModel.SETTING.LOD_DISTANCE, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickTerrainLODDistance(state)
    g_settingsModel:setValue(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickFoliageLODDistance(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_LOD_DISTANCE, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickVolumeMeshTessellation(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickMaxTireTracks(state)
    g_settingsModel:setValue(SettingsModel.SETTING.MAX_TIRE_TRACKS, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickLightsProfile(state)
    g_settingsModel:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, state + 1)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickRealBeaconLights(_)
    g_settingsModel:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, self.realBeaconLightsElement:getIsChecked())
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickFoliageShadows(_)
    g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_SHADOW, self.foliageShadowsElement:getIsChecked())
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickMaxMirrors(state)
    g_settingsModel:setValue(SettingsModel.SETTING.MAX_MIRRORS, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickSSAOQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SSAO_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickAtmosphereQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.ATMOSPHERE_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickCloudShadowsQuality(_)
    g_settingsModel:setValue(SettingsModel.SETTING.CLOUD_SHADOWS_QUALITY, self.cloudShadowsQualityElement:getIsChecked())
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickResolutionScale3d(state)
    g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickFovY(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickFovYPlayerFirstPerson(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickFovYPlayerThirdPerson(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON, state)
    g_settingsModel:applyCustomSettings()
    self:updateValues()
end
function SettingsAdvancedFrame:onClickLockedIcon() end
function SettingsAdvancedFrame:onFocusLockedIcon(icon)
    self.boxLayout:scrollToMakeElementVisible(icon)
end
SettingsAdvancedFrame.L10N_SYMBOL = {
    ["BUTTON_APPLY"] = "button_apply"
}
local fsr34LocaKey = getFidelityFxSuperResolutionVersion() == 4 and "setting_fsr4" or "setting_fsr3"
SettingsAdvancedFrame.SCALING_MODES = {
    [2] = {
        ["name"] = SettingsModel.SETTING.FIDELITYFX_SR,
        ["enum"] = FidelityFxSRQuality,
        ["title"] = "setting_fsr1"
    },
    [3] = {
        ["name"] = SettingsModel.SETTING.FIDELITYFX_SR_30,
        ["enum"] = FidelityFxSR30Quality,
        ["title"] = fsr34LocaKey
    },
    [4] = {
        ["name"] = SettingsModel.SETTING.DLSS,
        ["enum"] = DLSSQuality,
        ["title"] = "setting_DLSS"
    },
    [5] = {
        ["name"] = SettingsModel.SETTING.XESS,
        ["enum"] = XeSSQuality,
        ["title"] = "setting_xeSS"
    }
}