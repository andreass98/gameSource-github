SettingsGeneralFrame = {}
local SettingsGeneralFrame_mt = Class(SettingsGeneralFrame, TabbedMenuFrameElement)
function SettingsGeneralFrame.register()
    local settingsGeneralFrame = SettingsGeneralFrame.new()
    g_gui:loadGui("dataS/gui/SettingsGeneralFrame.xml", "SettingsGeneralFrame", settingsGeneralFrame, true)
end
function SettingsGeneralFrame.new(target, custom_mt)
    -- upvalues: (copy) SettingsGeneralFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsGeneralFrame_mt)
    self.hasCustomMenuButtons = true
    return self
end
function SettingsGeneralFrame.createFromExistingGui(gui, guiName)
    local newGui = SettingsGeneralFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    newGui.hasCustomMenuButtons = gui.hasCustomMenuButtons
    return newGui
end
function SettingsGeneralFrame:copyAttributes(src)
    SettingsGeneralFrame:superClass().copyAttributes(self, src)
    self.hasCustomMenuButtons = src.hasCustomMenuButtons
end
function SettingsGeneralFrame:applyDefaultSettingsValues()
    self.inputHelpModeElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.INPUT_HELP_MODE))
    self.isGamepadEnabledElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.GAMEPAD_ENABLED), self.isOpening)
    self.isHeadTrackingEnabledElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.HEAD_TRACKING_ENABLED), self.isOpening)
    self.forceFeedbackElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FORCE_FEEDBACK))
    self.languageElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.LANGUAGE))
    self.mpLanguageElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MP_LANGUAGE))
    self.masterVolumeElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_MASTER))
    self.musicVolumeElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_MUSIC))
    self.volumeVehicleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_VEHICLE))
    self.volumeEnvironmentElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT))
    self.volumeCharacterElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_CHARACTER))
    self.volumeRadioElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_RADIO))
    self.volumeGUIElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_GUI))
    self.volumeNoFocusElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_NO_FOCUS))
    self.invertYLookElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.INVERT_Y_LOOK), self.isOpening)
    self.multiVolumeVoice:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_VOICE))
    self.multiVolumeVoiceInput:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_VOICE_INPUT))
    self.multiVoiceMode:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOICE_MODE))
end
function SettingsGeneralFrame:initialize()
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
end
function SettingsGeneralFrame:onApplySettings()
    local needsRestart, needsProcessRestart = g_settingsModel:needsRestartToApplyChanges()
    g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
    if needsRestart then
        RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS)
        InfoDialog.show(g_i18n:getText("dialog_restartToApplyChanges"), function()
            -- upvalues: (copy) needsProcessRestart
            doRestart(needsProcessRestart, "")
        end, nil)
    else
        self:setMenuButtonInfoDirty()
    end
end
function SettingsGeneralFrame:getMenuButtonInfo()
    local buttons = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    if g_settingsModel:hasChanges() then
        table.insert(buttons, self.applyButtonInfo)
    end
    return buttons
end
function SettingsGeneralFrame:onFrameOpen()
    SettingsGeneralFrame:superClass().onFrameOpen(self)
    self.isOpening = true
    if self.isHeadTrackingEnabledElementBox == nil then
        self.isHeadTrackingEnabledElement:setVisible(true)
    else
        self.isHeadTrackingEnabledElementBox:setVisible(true)
    end
    if self.languageElementBox == nil then
        self.languageElement:setVisible(not g_settingsModel:getIsLanguageDisabled())
    else
        self.languageElementBox:setVisible(not g_settingsModel:getIsLanguageDisabled())
    end
    if self.isGamepadEnabledElementBox == nil then
        self.isGamepadEnabledElement:setVisible(true)
    else
        self.isGamepadEnabledElementBox:setVisible(true)
    end
    if self.inputHelpModeElementBox == nil then
        self.inputHelpModeElement:setVisible(true)
    else
        self.inputHelpModeElementBox:setVisible(true)
    end
    if self.forceFeedbackElementBox == nil then
        self.forceFeedbackElement:setVisible(true)
    else
        self.forceFeedbackElementBox:setVisible(true)
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
    self:applyDefaultSettingsValues()
    self.isOpening = false
end
function SettingsGeneralFrame.onCreateLanguage(_, element)
    element:setTexts(g_settingsModel:getLanguageTexts())
end
function SettingsGeneralFrame.onCreateMPLanguage(_, element)
    element:setTexts(g_settingsModel:getMPLanguageTexts())
end
function SettingsGeneralFrame.onCreateInputHelpMode(_, element)
    element:setTexts(g_settingsModel:getInputHelpModeTexts())
end
function SettingsGeneralFrame.onCreateVolume(_, element)
    element:setTexts(g_settingsModel:getAudioVolumeTexts())
end
function SettingsGeneralFrame.onCreateForceFeedback(_, element)
    element:setTexts(g_settingsModel:getForceFeedbackTexts())
end
function SettingsGeneralFrame.onCreateRecordingVolume(_, element)
    element:setTexts(g_settingsModel:getRecordingVolumeTexts())
end
function SettingsGeneralFrame.onCreateVoiceMode(_, element)
    element:setTexts(g_settingsModel:getVoiceModeTexts())
end
function SettingsGeneralFrame:onClickLanguage(state)
    g_settingsModel:setValue(SettingsModel.SETTING.LANGUAGE, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickMPLanguage(state)
    g_settingsModel:setValue(SettingsModel.SETTING.MP_LANGUAGE, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickIsHeadTrackingEnabled(_)
    g_settingsModel:setValue(SettingsModel.SETTING.HEAD_TRACKING_ENABLED, self.isHeadTrackingEnabledElement:getIsChecked())
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickForceFeedback(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FORCE_FEEDBACK, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickIsGamepadEnabled(_)
    g_settingsModel:setValue(SettingsModel.SETTING.GAMEPAD_ENABLED, self.isGamepadEnabledElement:getIsChecked())
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickInputHelpMode(_)
    g_settingsModel:setValue(SettingsModel.SETTING.INPUT_HELP_MODE, self.inputHelpModeElement:getState())
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickMasterVolume(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_MASTER, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickMusicVolume(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_MUSIC, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickVolumeVehicle(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_VEHICLE, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickVolumeEnvironment(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickVolumeCharacter(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_CHARACTER, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickCharacterEnvironment(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_CHARACTER, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickVolumeRadio(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_RADIO, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickVolumeGUI(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_GUI, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickVolumeNoFocus(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_NO_FOCUS, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickInvertYLook(_)
    g_settingsModel:setValue(SettingsModel.SETTING.INVERT_Y_LOOK, self.invertYLookElement:getIsChecked())
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickVoiceVolume(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_VOICE, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickRecordingVolume(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_VOICE_INPUT, state)
    self:setMenuButtonInfoDirty()
end
function SettingsGeneralFrame:onClickVoiceMode(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOICE_MODE, state)
    self:setMenuButtonInfoDirty()
end
SettingsGeneralFrame.L10N_SYMBOL = {
    ["BUTTON_APPLY"] = "button_apply"
}