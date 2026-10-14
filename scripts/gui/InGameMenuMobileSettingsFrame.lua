InGameMenuMobileSettingsFrame = {}
local InGameMenuMobileSettingsFrame_mt = Class(InGameMenuMobileSettingsFrame, TabbedMenuFrameElement)
function InGameMenuMobileSettingsFrame.register()
    if Platform.isMobile then
        local inGameMenuMobileSettingsFrame = InGameMenuMobileSettingsFrame.new()
        g_gui:loadGui("dataS/gui/InGameMenuMobileSettingsFrame.xml", "MobileSettingsFrame", inGameMenuMobileSettingsFrame, true)
    end
end
function InGameMenuMobileSettingsFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuMobileSettingsFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMobileSettingsFrame_mt)
    self.missionInfo = nil
    self.hasMasterRights = false
    self.checkboxMapping = {}
    self.checkboxMappingGame = {}
    self.optionMapping = {}
    self.manureLoadingStations = {}
    self.liquidManureLoadingStations = {}
    self.instantApplySettings = {}
    self.instantApplySettings[GameSettings.SETTING.VOLUME_MASTER] = true
    self.instantApplySettings[GameSettings.SETTING.VOLUME_MUSIC] = true
    self.instantApplySettings[GameSettings.SETTING.VOLUME_GUI] = true
    self.hasCustomMenuButtons = false
    return self
end
function InGameMenuMobileSettingsFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuMobileSettingsFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuMobileSettingsFrame:initialize()
    self.checkboxMapping[self.checkGyroscope] = SettingsModel.SETTING.GYROSCOPE_STEERING
    self.checkboxMapping[self.checkTilt] = SettingsModel.SETTING.CAMERA_TILTING
    self.checkboxMapping[self.checkUseMiles] = g_settingsModel.SETTING.USE_MILES
    self.checkboxMapping[self.checkUseFahrenheit] = g_settingsModel.SETTING.USE_FAHRENHEIT
    self.checkboxMapping[self.checkUseAcre] = g_settingsModel.SETTING.USE_ACRE
    self.checkboxMapping[self.checkColorBlindMode] = g_settingsModel.SETTING.USE_COLORBLIND_MODE
    self.checkboxMapping[self.checkShowTriggerMarker] = g_settingsModel.SETTING.SHOW_TRIGGER_MARKER
    self.checkboxMapping[self.checkShowHelpTrigger] = g_settingsModel.SETTING.SHOW_HELP_TRIGGER
    self.checkboxMapping[self.checkResetCamera] = g_settingsModel.SETTING.RESET_CAMERA
    self.checkboxMapping[self.checkCameraCheckCollision] = g_settingsModel.SETTING.CAMERA_CHECK_COLLISION
    self.checkboxMapping[self.checkUseWorldCamera] = g_settingsModel.SETTING.USE_WORLD_CAMERA
    self.checkboxMapping[self.checkInvertYLook] = g_settingsModel.SETTING.INVERT_Y_LOOK
    self.checkUseMiles:setTexts(g_settingsModel:getDistanceUnitTexts())
    self.checkUseFahrenheit:setTexts(g_settingsModel:getTemperatureUnitTexts())
    self.checkUseAcre:setTexts(g_settingsModel:getAreaUnitTexts())
    self.optionMapping[self.multiMoneyUnit] = SettingsModel.SETTING.MONEY_UNIT
    self.multiMoneyUnit:setTexts(g_settingsModel:getMoneyUnitTexts())
    self.optionMapping[self.multiVolumeMusic] = SettingsModel.SETTING.VOLUME_MUSIC
    self.multiVolumeMusic:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.optionMapping[self.multiVolumeVehicle] = SettingsModel.SETTING.VOLUME_VEHICLE
    self.multiVolumeVehicle:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.optionMapping[self.multiVolumeEnvironment] = SettingsModel.SETTING.VOLUME_ENVIRONMENT
    self.multiVolumeEnvironment:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.optionMapping[self.multiVolumeCharacter] = SettingsModel.SETTING.VOLUME_CHARACTER
    self.multiVolumeCharacter:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.optionMapping[self.multiVolumeGUI] = SettingsModel.SETTING.VOLUME_GUI
    self.multiVolumeGUI:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.optionMapping[self.multiCameraSensitivity] = g_settingsModel.SETTING.CAMERA_SENSITIVITY
    self.multiCameraSensitivity:setTexts(g_settingsModel:getCameraSensitivityTexts())
    self.optionMapping[self.multiSteeringBackSpeed] = g_settingsModel.SETTING.STEERING_BACK_SPEED
    self.multiSteeringBackSpeed:setTexts(g_settingsModel:getSteeringBackSpeedTexts())
    self.optionMapping[self.multiUIScale] = g_settingsModel.SETTING.UI_SCALE
    self.multiUIScale:setTexts(g_settingsModel:getUiScaleTexts())
    self.optionMapping[self.multiSteeringSensitivity] = g_settingsModel.SETTING.STEERING_SENSITIVITY
    self.multiSteeringSensitivity:setTexts(g_settingsModel:getSteeringSensitivityTexts())
    self.optionMapping[self.multiGraphics] = SettingsModel.SETTING.PERFORMANCE_CLASS
    self.multiGraphics:setTexts(g_settingsModel:getPerformanceClassTexts())
    self.multiGraphics.parent:setVisible(GS_PLATFORM_PHONE)
    self.optionMapping[self.multiFrameLimit] = SettingsModel.SETTING.FRAME_LIMIT
    self.multiFrameLimit:setTexts(g_settingsModel:getFrameLimitTexts())
    self.multiFrameLimit.parent:setVisible(#Platform.frameLimits > 1)
    self.separatorGraphics:setVisible(self.multiGraphics.parent.visible or self.multiFrameLimit.parent.visible)
end
function InGameMenuMobileSettingsFrame:setMissionInfo(missionInfo)
    self.missionInfo = missionInfo
end
function InGameMenuMobileSettingsFrame:setHasMasterRights(hasMasterRights)
    self.hasMasterRights = hasMasterRights
end
function InGameMenuMobileSettingsFrame:onFrameOpen(_)
    InGameMenuMobileSettingsFrame:superClass().onFrameOpen(self)
    self:assignDynamicTexts()
    self:updateGeneralSettings()
    self:updateGameSettings()
    local showRestoreButton = g_inAppPurchaseController:getHasPurchasesToRestore()
    self.iapRestoreSeparator:setVisible(showRestoreButton)
    self.iapRestoreButton:setVisible(showRestoreButton)
    self.iapRestoreSeparatorEnd:setVisible(showRestoreButton)
    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.multiTimeScale)
        self:setSoundSuppressed(false)
    end
    self.boxLayout:invalidateLayout()
end
function InGameMenuMobileSettingsFrame:onFrameClose()
    InGameMenuMobileSettingsFrame:superClass().onFrameClose(self)
    if g_settingsModel:hasChanges() then
        if g_settingsModel:getHasValueChanged(SettingsModel.SETTING.PERFORMANCE_CLASS) then
            g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
            return
        end
        g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_GAMEPLAY_SETTINGS)
    end
end
function InGameMenuMobileSettingsFrame:updateGeneralSettings()
    g_settingsModel:refresh()
    for element, settingsKey in pairs(self.checkboxMapping) do
        element:setIsChecked(g_settingsModel:getValue(settingsKey))
    end
    for element, settingsKey in pairs(self.optionMapping) do
        if type(settingsKey) == "table" then
            element:setState(g_settingsModel:getValue(settingsKey[1]))
        else
            element:setState(g_settingsModel:getValue(settingsKey))
        end
    end
end
function InGameMenuMobileSettingsFrame:updateGameSettings()
    self.checkTraffic:setIsChecked(self.missionInfo.trafficEnabled)
    self.checkHelperRefillSlurry:setState(self.missionInfo.helperSlurrySource)
    self.checkHelperRefillManure:setState(self.missionInfo.helperManureSource)
    self.checkHelperRefillFuel:setIsChecked(self.missionInfo.helperBuyFuel)
    self.checkHelperRefillSeed:setIsChecked(self.missionInfo.helperBuySeeds)
    self.checkHelperRefillFertilizer:setIsChecked(self.missionInfo.helperBuyFertilizer)
    self.checkIntroductionHelp:setIsChecked(self.missionInfo.introductionHelpActive)
    local timeScaleTable = {}
    local numTimeScales = Utils.getNumTimeScales()
    local i = 1
    for i = i, numTimeScales do
        table.insert(timeScaleTable, Utils.getTimeScaleString(i))
    end
    self.multiTimeScale:setTexts(timeScaleTable)
    self.multiTimeScale:setState(Utils.getTimeScaleIndex(self.missionInfo.timeScale))
end
function InGameMenuMobileSettingsFrame:assignDynamicTexts()
    self.helperManureTextToStationIndexMapping = { 1, 2 }
    self.helperSlurryTextToStationIndexMapping = { 1, 2 }
    local helperTexts = { g_i18n:getText("ui_off"), g_i18n:getText("ui_buy") }
    local textTable = {}
    table.insert(textTable, helperTexts[1])
    table.insert(textTable, helperTexts[2])
    for stationIndex, station in ipairs(self.manureLoadingStations) do
        if g_currentMission.accessHandler:canPlayerAccess(station) then
            table.insert(textTable, station:getName())
            self.helperManureTextToStationIndexMapping[#textTable] = stationIndex + 2
        end
    end
    self.checkHelperRefillManure:setTexts(textTable)
    local textTable = {}
    table.insert(textTable, helperTexts[1])
    table.insert(textTable, helperTexts[2])
    for stationIndex, station in ipairs(self.liquidManureLoadingStations) do
        if g_currentMission.accessHandler:canPlayerAccess(station) and station:getIsFillAllowedToFarm(g_currentMission:getFarmId()) then
            table.insert(textTable, station:getName())
            self.helperSlurryTextToStationIndexMapping[#textTable] = stationIndex + 2
        end
    end
    self.checkHelperRefillSlurry:setTexts(textTable)
end
function InGameMenuMobileSettingsFrame:setManureTriggers(manureLoadingStations, liquidManureLoadingStations)
    self.manureLoadingStations = manureLoadingStations
    self.liquidManureLoadingStations = liquidManureLoadingStations
end
function InGameMenuMobileSettingsFrame:onClickTraffic(state)
    if self.hasMasterRights then
        g_currentMission:setTrafficEnabled(state == CheckedOptionElement.STATE_CHECKED)
    end
end
function InGameMenuMobileSettingsFrame:onClickTimeScale(state)
    if self.hasMasterRights then
        g_currentMission:setTimeScale(Utils.getTimeScaleFromIndex(state))
    end
end
function InGameMenuMobileSettingsFrame:onClickCheckbox(state, checkboxElement)
    local settingsKey = self.checkboxMapping[checkboxElement]
    if settingsKey == nil then
        printWarning("Warning: Invalid settings checkbox event or key configuration for element " .. checkboxElement:toString())
    else
        g_settingsModel:setValue(settingsKey, state == CheckedOptionElement.STATE_CHECKED)
    end
end
function InGameMenuMobileSettingsFrame:onClickMultiOption(state, optionElement)
    local settingsKey = self.optionMapping[optionElement]
    if settingsKey == nil then
        printWarning("Warning: Invalid settings multi option event or key configuration for element " .. optionElement:toString())
    else
        if type(settingsKey) == "table" then
            for _, v in ipairs(settingsKey) do
                g_settingsModel:setValue(v, state)
            end
        else
            g_settingsModel:setValue(settingsKey, state)
        end
        if self.instantApplySettings[settingsKey] then
            g_settingsModel:applyChange(settingsKey)
            return
        end
    end
end
function InGameMenuMobileSettingsFrame:onClickGraphics(state, optionElement)
    local settingsKey = self.optionMapping[optionElement]
    if settingsKey == nil then
        printWarning("Warning: Invalid settings multi option event or key configuration for element " .. optionElement:toString())
    else
        g_settingsModel:setValue(settingsKey, state)
    end
end
function InGameMenuMobileSettingsFrame:onClickHelperRefillFuel(state)
    if self.hasMasterRights then
        g_currentMission:setHelperBuyFuel(state == CheckedOptionElement.STATE_CHECKED)
    end
end
function InGameMenuMobileSettingsFrame:onClickHelperRefillSeed(state)
    if self.hasMasterRights then
        g_currentMission:setHelperBuySeeds(state == CheckedOptionElement.STATE_CHECKED)
    end
end
function InGameMenuMobileSettingsFrame:onClickHelperRefillFertilizer(state)
    if self.hasMasterRights then
        g_currentMission:setHelperBuyFertilizer(state == CheckedOptionElement.STATE_CHECKED)
    end
end
function InGameMenuMobileSettingsFrame:onClickHelperRefillSlurry(state)
    if self.hasMasterRights then
        if self.helperSlurryTextToStationIndexMapping ~= nil then
            g_currentMission:setHelperSlurrySource(self.helperSlurryTextToStationIndexMapping[state] or 1)
            return
        end
        g_currentMission:setHelperSlurrySource(1)
    end
end
function InGameMenuMobileSettingsFrame:onClickHelperRefillManure(state)
    if self.hasMasterRights then
        if self.helperManureTextToStationIndexMapping ~= nil then
            g_currentMission:setHelperManureSource(self.helperManureTextToStationIndexMapping[state] or 1)
            return
        end
        g_currentMission:setHelperManureSource(1)
    end
end
function InGameMenuMobileSettingsFrame:onClickIntroductionHelp(state)
    if self.hasMasterRights then
        self.missionInfo.introductionHelpActive = state == CheckedOptionElement.STATE_CHECKED
    end
end
function InGameMenuMobileSettingsFrame:onClickRestoreInAppPurchases(state)
    g_inAppPurchaseController:restorePurchases()
end