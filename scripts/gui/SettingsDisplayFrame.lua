SettingsDisplayFrame = {}
local SettingsDisplayFrame_mt = Class(SettingsDisplayFrame, TabbedMenuFrameElement)
local function NO_CALLBACK() end
function SettingsDisplayFrame.register()
    local settingsDisplayFrame = SettingsDisplayFrame.new()
    g_gui:loadGui("dataS/gui/SettingsDisplayFrame.xml", "SettingsDisplayFrame", settingsDisplayFrame, true)
end
function SettingsDisplayFrame.new(target, custom_mt)
    -- upvalues: (copy) SettingsDisplayFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsDisplayFrame_mt)
    self.hasCustomMenuButtons = true
    return self
end
function SettingsDisplayFrame.createFromExistingGui(gui, guiName)
    local newGui = SettingsDisplayFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    newGui.hasCustomMenuButtons = gui.hasCustomMenuButtons
    return newGui
end
function SettingsDisplayFrame:copyAttributes(src)
    SettingsDisplayFrame:superClass().copyAttributes(self, src)
    self.hasCustomMenuButtons = src.hasCustomMenuButtons
end
function SettingsDisplayFrame:initialize()
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
        ["text"] = g_i18n:getText(SettingsDisplayFrame.L10N_SYMBOL.BUTTON_APPLY),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onApplySettings()
        end
    }
    self.advancedButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText(SettingsDisplayFrame.L10N_SYMBOL.BUTTON_ADVANCED),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onClickAdvancedButton()
        end
    }
end
function SettingsDisplayFrame:onGuiSetupFinished()
    SettingsDisplayFrame:superClass().onGuiSetupFinished(self)
    for _, container in pairs(self.boxLayout.elements) do
        if container:getDescendantByName("iconDisabled") ~= nil then
            container.setDisabled = Utils.appendedFunction(container.setDisabled, function(container, disabled)
                container:getDescendantByName("iconDisabled"):setDisabled(not disabled)
            end)
        end
    end
end
function SettingsDisplayFrame:setOpenAdvancedSettingsCallback(itemSelectedCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.notifyAdvancedSettingsButton = itemSelectedCallback or NO_CALLBACK
end
function SettingsDisplayFrame:onApplySettings()
    local showResolutionWarning = false
    if g_settingsModel:getSettingExists(SettingsModel.SETTING.RESOLUTION_SCALE) and g_settingsModel:getHasValueChanged(SettingsModel.SETTING.RESOLUTION_SCALE) then
        showResolutionWarning = g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE) > SettingsModel.getScalingStateFromResolutionScaling(1) and true or showResolutionWarning
    end
    if g_settingsModel:getSettingExists(SettingsModel.SETTING.RESOLUTION_SCALE_3D) and g_settingsModel:getHasValueChanged(SettingsModel.SETTING.RESOLUTION_SCALE_3D) then
        showResolutionWarning = g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D) > SettingsModel.getScalingStateFromResolutionScaling(1) and true or showResolutionWarning
    end
    if showResolutionWarning then
        YesNoDialog.show(function(yes)
            -- upvalues: (copy) self
            if yes then
                self:applySettings()
            end
        end, nil, g_i18n:getText("ui_resolutionScaleWarning"))
    else
        self:applySettings()
    end
end
function SettingsDisplayFrame:applySettings()
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
    self.hdrCalibrationButton:setDisabled(not getScreenHdrOutput())
end
function SettingsDisplayFrame:getMenuButtonInfo()
    local buttons = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    if g_settingsModel:hasChanges() then
        table.insert(buttons, self.applyButtonInfo)
    end
    table.insert(buttons, self.advancedButtonInfo)
    return buttons
end
function SettingsDisplayFrame:updateValues()
    self:updatePerformanceClass()
    self.performanceClassElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.PERFORMANCE_CLASS))
    self.fullscreenModeElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) + 1)
    self.resolutionElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION) + 1)
    self.vSyncElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.V_SYNC), self.isOpening)
    self.brightnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.BRIGHTNESS))
    self.uiScaleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.UI_SCALE))
    self.resolutionScaleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE))
    self.hdrEnabledElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.HDR_ENABLED), self.isOpening)
    if Platform.hasAdjustableFrameLimit and #Platform.frameLimits > 1 then
        self.frameLimitElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FRAME_LIMIT))
    end
    local settingFSR30 = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30)
    local settingFSR = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR)
    local settingXeSS = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS)
    local settingDLSS = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS)
    local isFSR30Active = false
    if settingFSR30 ~= FidelityFxSR30Quality.OFF then
        isFSR30Active = settingFSR30 ~= nil
    end
    local isFSRActive = false
    if settingFSR ~= FidelityFxSRQuality.OFF then
        isFSRActive = settingFSR ~= nil
    end
    local isXeSSActive = false
    if settingXeSS ~= XeSSQuality.OFF then
        isXeSSActive = settingXeSS ~= nil
    end
    local isDLSSActive = false
    if settingDLSS ~= DLSSQuality.OFF then
        isDLSSActive = settingDLSS ~= nil
    end
    self.resolutionScaleContainer:setDisabled(isDLSSActive or (isXeSSActive or (isFSR30Active or isFSRActive)))
    self:setMenuButtonInfoDirty()
end
function SettingsDisplayFrame:onFrameOpen()
    SettingsDisplayFrame:superClass().onFrameOpen(self)
    self.isOpening = true
    self.hdrCalibrationButton.parent:setVisible(getHdrAvailable())
    self.hdrCalibrationButton:setDisabled(not getScreenHdrOutput())
    self.hdrEnabledElement.parent:setVisible(getHdrAvailable())
    self.resolutionScaleElement.parent:setVisible(true)
    self.performanceClassElement.parent:setVisible(true)
    self.resolutionElement.parent:setVisible(true)
    self.fullscreenModeElement.parent:setVisible(true)
    self.vSyncElement.parent:setVisible(true)
    local isAlternate = self.frameLimitElement.parent
    isAlternate:setVisible(Platform.hasAdjustableFrameLimit and #Platform.frameLimits > 1)
    local isAlternate = true
    for _, container in pairs(self.boxLayout.elements) do
        container:setImageColor(nil, unpack(SettingsScreen.COLOR_ALTERNATING[isAlternate]))
        isAlternate = not isAlternate
    end
    self.boxLayout:invalidateLayout()
    self:updateValues()
    self.isOpening = false
end
function SettingsDisplayFrame:updatePerformanceClass()
    local texts, _, _ = g_settingsModel:getPerformanceClassTexts()
    self.performanceClassElement:setTexts(texts)
end
function SettingsDisplayFrame:setOpenHDRSettingsCallback(itemSelectedCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.notifyHDRSettingsButton = itemSelectedCallback or NO_CALLBACK
end
function SettingsDisplayFrame.onCreatePerformanceClass(_, element)
    local texts, _, _ = g_settingsModel:getPerformanceClassTexts()
    element:setTexts(texts)
end
function SettingsDisplayFrame.onCreateResolution(_, element)
    element:setTexts(g_settingsModel:getResolutionTexts())
end
function SettingsDisplayFrame.onCreateFullscreenMode(_, element)
    element:setTexts(g_settingsModel:getFullscreenModeTexts())
end
function SettingsDisplayFrame.onCreateBrightness(_, element)
    element:setTexts(g_settingsModel:getBrightnessTexts())
end
function SettingsDisplayFrame.onCreateUIScale(_, element)
    element:setTexts(g_settingsModel:getUiScaleTexts())
end
function SettingsDisplayFrame.onCreateResolutionScale(_, element)
    element:setTexts(g_settingsModel:getResolutionScaleTexts())
end
function SettingsDisplayFrame.onCreateFrameLimit(_, element)
    element:setTexts(g_settingsModel:getFrameLimitTexts())
end
function SettingsDisplayFrame:onClickPerformanceClass(state)
    g_settingsModel:applyPerformanceClass(state)
    self:updateValues()
end
function SettingsDisplayFrame:onClickResolution(state)
    g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION, state - 1)
    self:setMenuButtonInfoDirty()
end
function SettingsDisplayFrame:onClickBrightness(state)
    g_settingsModel:setValue(SettingsModel.SETTING.BRIGHTNESS, state)
    self:setMenuButtonInfoDirty()
end
function SettingsDisplayFrame:onClickFullscreenMode(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FULLSCREEN_MODE, state - 1)
    self:setMenuButtonInfoDirty()
end
function SettingsDisplayFrame:onClickVSync(_)
    g_settingsModel:setValue(SettingsModel.SETTING.V_SYNC, self.vSyncElement:getIsChecked())
    self:setMenuButtonInfoDirty()
    self:updateValues()
end
function SettingsDisplayFrame:onClickFrameLimit(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FRAME_LIMIT, state)
    self:setMenuButtonInfoDirty()
end
function SettingsDisplayFrame:onClickUIScale(state)
    g_settingsModel:setValue(SettingsModel.SETTING.UI_SCALE, state)
    self:setMenuButtonInfoDirty()
end
function SettingsDisplayFrame:onClickAdvancedButton()
    self.notifyAdvancedSettingsButton()
end
function SettingsDisplayFrame:onClickResolutionScale(state)
    g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION_SCALE, state)
    self:setMenuButtonInfoDirty()
end
function SettingsDisplayFrame:onClickHDREnabled(_)
    local hdrEnabled = self.hdrEnabledElement:getIsChecked()
    g_settingsModel:setValue(SettingsModel.SETTING.HDR_ENABLED, hdrEnabled)
    self.hdrCalibrationButton.parent:setVisible(getHdrAvailable())
    self:setMenuButtonInfoDirty()
end
function SettingsDisplayFrame:onHDRCalibration()
    self.notifyHDRSettingsButton()
end
function SettingsDisplayFrame:onClickLockedIcon() end
function SettingsDisplayFrame:onFocusLockedIcon(icon)
    self.boxLayout:scrollToMakeElementVisible(icon)
end
SettingsDisplayFrame.L10N_SYMBOL = {
    ["BUTTON_APPLY"] = "button_apply",
    ["BUTTON_ADVANCED"] = "setting_advanced"
}