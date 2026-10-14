SettingsHDRFrame = {}
local SettingsHDRFrame_mt = Class(SettingsHDRFrame, TabbedMenuFrameElement)
SettingsHDRFrame.DEFAULT_HDR_PEAK_BRIGHTNESS = 300
SettingsHDRFrame.DEFAULT_HDR_CONTRAST = 1
SettingsHDRFrame.DEFAULT_OVERLAY_BRIGHTNESS = 300
function SettingsHDRFrame.register()
    local settingsHDRFrame = SettingsHDRFrame.new()
    g_gui:loadGui("dataS/gui/SettingsHDRFrame.xml", "SettingsHDRFrame", settingsHDRFrame, true)
end
function SettingsHDRFrame.new(target, custom_mt)
    -- upvalues: (copy) SettingsHDRFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsHDRFrame_mt)
    self.lastHDRActive = false
    self.hasCustomMenuButtons = true
    return self
end
function SettingsHDRFrame.createFromExistingGui(gui, guiName)
    local newGui = SettingsHDRFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    newGui.hasCustomMenuButtons = gui.hasCustomMenuButtons
    return newGui
end
function SettingsHDRFrame:copyAttributes(src)
    SettingsHDRFrame:superClass().copyAttributes(self, src)
    self.hasCustomMenuButtons = src.hasCustomMenuButtons
end
function SettingsHDRFrame:onGuiSetupFinished()
    SettingsHDRFrame:superClass().onGuiSetupFinished(self)
    self.hdrSceneElement:setTexts({ g_i18n:getText("ui_day"), g_i18n:getText("ui_night") })
    local isAlternate = true
    for _, container in pairs(self.boxLayout.elements) do
        container:setImageColor(nil, unpack(SettingsScreen.COLOR_ALTERNATING[isAlternate]))
        isAlternate = not isAlternate
    end
    self.boxLayout:invalidateLayout()
end
function SettingsHDRFrame:initialize()
    SettingsHDRFrame:superClass().initialize(self)
    self.backButtonInfo = {
        ["inputAction"] = InputAction.MENU_BACK
    }
    self.applyButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(SettingsHDRFrame.L10N_SYMBOL.BUTTON_APPLY),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onApplySettings()
        end
    }
    self.resetButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText(SettingsHDRFrame.L10N_SYMBOL.BUTTON_RESET),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onResetSettings()
        end
    }
end
function SettingsHDRFrame:delete()
    if self.loadRequestId ~= nil then
        g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
        self.loadRequestId = nil
    end
    SettingsHDRFrame:superClass().delete(self)
end
function SettingsHDRFrame:onApplySettings()
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
function SettingsHDRFrame:onResetSettings()
    self.hdrPeakBrightnessElement:setState(SettingsHDRFrame.DEFAULT_HDR_PEAK_BRIGHTNESS, true)
    self.hdrContrastElement:setState(SettingsHDRFrame.DEFAULT_HDR_CONTRAST, true)
    self.overlayBrightnessElement:setState(SettingsHDRFrame.DEFAULT_OVERLAY_BRIGHTNESS, true)
end
function SettingsHDRFrame:getMenuButtonInfo()
    local buttons = { self.backButtonInfo }
    if g_settingsModel:hasChanges() then
        table.insert(buttons, self.applyButtonInfo)
        table.insert(buttons, self.resetButtonInfo)
    end
    return buttons
end
function SettingsHDRFrame:updateValues()
    self.hdrPeakBrightnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.HDR_PEAK_BRIGHTNESS))
    self.hdrContrastElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.HDR_CONTRAST))
    self.overlayBrightnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.OVERLAY_BRIGHTNESS))
    self:setMenuButtonInfoDirty()
end
function SettingsHDRFrame:update(dt)
    SettingsHDRFrame:superClass().update(self, dt)
    local isHDRActive = getHdrAvailable()
    if self.lastHDRActive ~= isHDRActive then
        self.hdrPeakBrightnessElement:setDisabled(not isHDRActive)
        self.hdrContrastElement:setDisabled(not isHDRActive)
        self.overlayBrightnessElement:setDisabled(not isHDRActive)
        self.lastHDRActive = isHDRActive
    end
end
function SettingsHDRFrame:onFrameOpen()
    SettingsHDRFrame:superClass().onFrameOpen(self)
    self.lastHDRActive = getHdrAvailable()
    self:loadHDRPlane()
    self:updateValues()
end
function SettingsHDRFrame:hdrPlaneChanged()
    local isDay = self.hdrSceneElement:getIsChecked() == false
    if isDay then
        setFixedLuminanceForExposure(0.0630673)
    else
        setFixedLuminanceForExposure(0.0630672)
    end
    if self.hdrPlaneRootNode ~= nil then
        if isDay then
            setVisibility(self.dayPlaneNode, true)
            setVisibility(self.nightPlaneNode, false)
            return
        end
        setVisibility(self.dayPlaneNode, false)
        setVisibility(self.nightPlaneNode, true)
    end
end
function SettingsHDRFrame:hdrPlaneLoaded(i3dNode, _, _)
    link(getRootNode(), i3dNode)
    self.hdrPlaneRootNode = i3dNode
    self.cameraId = getChild(i3dNode, "hdrPlaneCamera")
    self.dayPlaneNode = getChild(i3dNode, "hdrPlaneDay")
    self.nightPlaneNode = getChild(i3dNode, "hdrPlaneNight")
    g_cameraManager:addCamera(self.cameraId, nil, false)
    g_cameraManager:setActiveCamera(self.cameraId)
    setTranslation(self.cameraId, (-(self.hdrImage.size[1] / 2 + self.hdrImage.absPosition[1]) + 0.5) * g_screenAspectRatio, 1, self.hdrImage.size[2] / 2 + self.hdrImage.absPosition[2] - 0.5)
    self:hdrPlaneChanged()
end
function SettingsHDRFrame:loadHDRPlane()
    if self.loadRequestId ~= nil then
        g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
        self.loadRequestId = nil
    end
    self.loadRequestId = g_i3DManager:loadI3DFileAsync("dataS/menu/hdrPlane/hdrPlane.i3d", true, true, SettingsHDRFrame.hdrPlaneLoaded, self, nil)
end
function SettingsHDRFrame:onFrameClose()
    if self.cameraId ~= nil then
        g_cameraManager:setDefaultCamera()
        g_cameraManager:removeCamera(self.cameraId)
        self.cameraId = nil
    end
    self.dayPlaneNode = nil
    self.nightPlaneNode = nil
    if self.hdrPlaneRootNode ~= nil then
        delete(self.hdrPlaneRootNode)
        self.hdrPlaneRootNode = nil
    end
    setFixedLuminanceForExposure(-1)
end
function SettingsHDRFrame:getMainElementSize()
    return self.settingsContainer.size
end
function SettingsHDRFrame:getMainElementPosition()
    return self.settingsContainer.absPosition
end
function SettingsHDRFrame.onCreateHDRPeakBrightness(_, element)
    local texts, _, _ = g_settingsModel:getHDRPeakBrightnessTexts()
    element:setTexts(texts)
end
function SettingsHDRFrame.onCreateHDRContrast(_, element)
    local texts, _, _ = g_settingsModel:getHDRContrastTexts()
    element:setTexts(texts)
end
function SettingsHDRFrame.onCreateOverlayBrightness(_, element)
    local texts, _, _ = g_settingsModel:getOverlayBrightnessTexts()
    element:setTexts(texts)
end
function SettingsHDRFrame:onClickHDRPeakBrightness(state)
    g_settingsModel:setValue(SettingsModel.SETTING.HDR_PEAK_BRIGHTNESS, state)
    g_settingsModel:applyCustomSettings()
    self:setMenuButtonInfoDirty()
end
function SettingsHDRFrame:onClickHDRContrast(state)
    g_settingsModel:setValue(SettingsModel.SETTING.HDR_CONTRAST, state)
    g_settingsModel:applyCustomSettings()
    self:setMenuButtonInfoDirty()
end
function SettingsHDRFrame:onClickOverlayBrightness(state)
    g_settingsModel:setValue(SettingsModel.SETTING.OVERLAY_BRIGHTNESS, state)
    g_settingsModel:applyCustomSettings()
    self:setMenuButtonInfoDirty()
end
function SettingsHDRFrame:onClickHDRSceneChange(_)
    self:hdrPlaneChanged()
end
SettingsHDRFrame.L10N_SYMBOL = {
    ["BUTTON_APPLY"] = "button_apply",
    ["BUTTON_RESET"] = "button_reset"
}