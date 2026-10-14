SettingsConsoleFrame = {}
local SettingsConsoleFrame_mt = Class(SettingsConsoleFrame, TabbedMenuFrameElement)
function SettingsConsoleFrame.register()
    local settingsConsoleFrame = SettingsConsoleFrame.new()
    g_gui:loadGui("dataS/gui/SettingsConsoleFrame.xml", "SettingsConsoleFrame", settingsConsoleFrame, true)
end
function SettingsConsoleFrame.new(target, custom_mt)
    -- upvalues: (copy) SettingsConsoleFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsConsoleFrame_mt)
    self.hasCustomMenuButtons = true
    return self
end
function SettingsConsoleFrame.createFromExistingGui(gui, guiName)
    local newGui = SettingsConsoleFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    newGui.hasCustomMenuButtons = gui.hasCustomMenuButtons
    return newGui
end
function SettingsConsoleFrame:copyAttributes(src)
    SettingsConsoleFrame:superClass().copyAttributes(self, src)
    self.hasCustomMenuButtons = src.hasCustomMenuButtons
end
function SettingsConsoleFrame:initialize()
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK
    }
    self.applyButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(SettingsConsoleFrame.L10N_SYMBOL.BUTTON_APPLY),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onApplySettings()
        end
    }
end
function SettingsConsoleFrame:onApplySettings()
    local needsRestart, needsProcessRestart = g_settingsModel:needsRestartToApplyChanges()
    g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
    if needsRestart then
        if Platform.allowRestartOnSettingsChange then
            RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS)
            InfoDialog.show(g_i18n:getText("dialog_restartToApplyChanges"), function()
                -- upvalues: (copy) needsProcessRestart
                doRestart(needsProcessRestart, "")
            end, nil)
        else
            Logging.warning("Trying to apply a setting that requires a restart, which is not allowed on this Platform")
        end
    else
        InfoDialog.show(g_i18n:getText(SettingsConsoleFrame.L10N_SYMBOL.SAVING_FINISHED), nil, nil, DialogElement.TYPE_INFO)
        self:setMenuButtonInfoDirty()
        return
    end
end
function SettingsConsoleFrame:getMenuButtonInfo()
    local buttons = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    if g_settingsModel:hasChanges() then
        table.insert(buttons, self.applyButtonInfo)
    end
    return buttons
end
function SettingsConsoleFrame:updateValues()
    self.languageElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.LANGUAGE))
    self.performanceModeElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.PERFORMANCE_MODE), self.isOpening)
    self.fovyElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y))
    self.fovyPlayerFirstPersonElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON))
    self.fovyPlayerThirdPersonElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
    self.uiScaleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.UI_SCALE))
    self.invertYLookElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.INVERT_Y_LOOK), self.isOpening)
    self.masterVolumeElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_MASTER))
    self.musicVolumeElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_MUSIC))
    self.volumeVehicleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_VEHICLE))
    self.volumeEnvironmentElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT))
    self.volumeCharacterElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_CHARACTER))
    self.volumeRadioElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_RADIO))
    self.volumeGUIElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_GUI))
    self.volumeNoFocusElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_NO_FOCUS))
    self.brightnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.BRIGHTNESS))
    self.realBeaconLightsElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS), self.isOpening)
    if self.realBeaconLightsElementBox == nil then
        self.realBeaconLightsElement:setVisible(Platform.supportsRealBeaconLights)
    else
        self.realBeaconLightsElementBox:setVisible(Platform.supportsRealBeaconLights)
    end
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
function SettingsConsoleFrame:onFrameOpen()
    SettingsConsoleFrame:superClass().onFrameOpen(self)
    self.isOpening = true
    g_messageCenter:subscribe(MessageType.USER_PROFILE_CHANGED, self.onUserProfileChanged, self)
    self:updateValues()
    self.performanceModeElementBox:setVisible(getSupportsPerformanceMode())
    self.languageElementBox:setVisible(Platform.canChangeLanguage)
    self.boxLayout:invalidateLayout()
    self:updateHDRFocus()
    self.isOpening = false
end
function SettingsConsoleFrame:onFrameClose()
    g_messageCenter:unsubscribeAll(self)
    SettingsConsoleFrame:superClass().onFrameClose(self)
end
function SettingsConsoleFrame:updateHDRFocus()
    self.boxLayout:invalidateLayout()
end
function SettingsConsoleFrame:onUserProfileChanged()
    g_settingsModel:refresh()
    self:updateValues()
end
function SettingsConsoleFrame:getMainElementSize()
    return self.settingsContainer.size
end
function SettingsConsoleFrame:getMainElementPosition()
    return self.settingsContainer.absPosition
end
function SettingsConsoleFrame:setOpenHDRSettingsCallback(itemSelectedCallback)
    self.notifyHDRSettingsButton = itemSelectedCallback
end
function SettingsConsoleFrame:update(dt)
    SettingsConsoleFrame:superClass().update(self, dt)
    local isHDRActive = getHdrAvailable()
    if self.lastHDRActive ~= isHDRActive then
        self.hdrCalibrationButton.parent:setVisible(isHDRActive)
        self:updateHDRFocus()
        self.lastHDRActive = isHDRActive
    end
end
function SettingsConsoleFrame:onHDRCalibration()
    self.notifyHDRSettingsButton()
end
function SettingsConsoleFrame:onClickPerformanceMode(_)
    g_settingsModel:setValue(SettingsModel.SETTING.PERFORMANCE_MODE, self.performanceModeElement:getIsChecked())
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame.onCreateLanguage(_, element)
    element:setTexts(g_settingsModel:getLanguageTexts())
end
function SettingsConsoleFrame.onCreateFovy(_, element)
    element:setTexts(g_settingsModel:getFovYTexts())
end
function SettingsConsoleFrame.onCreateFovyPlayerFirstPerson(_, element)
    element:setTexts(g_settingsModel:getFovYTexts())
end
function SettingsConsoleFrame.onCreateFovyPlayerThirdPerson(_, element)
    element:setTexts(g_settingsModel:getFovYTexts())
end
function SettingsConsoleFrame.onCreateUIScale(_, element)
    element:setTexts(g_settingsModel:getUiScaleTexts())
end
function SettingsConsoleFrame.onCreateVolume(_, element)
    element:setTexts(g_settingsModel:getAudioVolumeTexts())
end
function SettingsConsoleFrame.onCreateBrightness(_, element)
    element:setTexts(g_settingsModel:getBrightnessTexts())
end
function SettingsConsoleFrame:onClickLanguage(state)
    g_settingsModel:setValue(SettingsModel.SETTING.LANGUAGE, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickFovy(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickFovyPlayerFirstPerson(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickFovyPlayerThirdPerson(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickUIScale(state)
    g_settingsModel:setValue(SettingsModel.SETTING.UI_SCALE, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickInvertYLook(_)
    g_settingsModel:setValue(SettingsModel.SETTING.INVERT_Y_LOOK, self.invertYLookElement:getIsChecked())
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickMasterVolume(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_MASTER, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickMusicVolume(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_MUSIC, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickVolumeVehicle(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_VEHICLE, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickVolumeEnvironment(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickVolumeCharacter(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_CHARACTER, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickVolumeRadio(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_RADIO, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickVolumeGUI(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_GUI, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickVolumeNoFocus(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_NO_FOCUS, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickBrightness(state)
    g_settingsModel:setValue(SettingsModel.SETTING.BRIGHTNESS, state)
    self:setMenuButtonInfoDirty()
end
function SettingsConsoleFrame:onClickRealBeaconLights(_)
    g_settingsModel:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, self.realBeaconLightsElement:getIsChecked())
    self:setMenuButtonInfoDirty()
end
SettingsConsoleFrame.L10N_SYMBOL = {
    ["BUTTON_APPLY"] = "button_apply",
    ["DOWNSAMPLED"] = "setting_resolutionDownsampled",
    ["SAVING_FINISHED"] = "ui_savingFinished"
}