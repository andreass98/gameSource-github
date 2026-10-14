InGameMenuSettingsFrame = {}
local InGameMenuSettingsFrame_mt = Class(InGameMenuSettingsFrame, TabbedMenuFrameElement)
local function NO_CALLBACK() end
InGameMenuSettingsFrame.SUB_CATEGORY = {
    ["GAME_SETTINGS"] = 1,
    ["GENERAL_SETTINGS"] = 2,
    ["GRAPHIC_SETTINGS"] = 3,
    ["CONTROLS"] = 4,
    ["DEADZONE"] = 5,
    ["SERVER_SETTINGS"] = 6
}
function InGameMenuSettingsFrame.register()
    local inGameMenuSettingsFrame = InGameMenuSettingsFrame.new()
    g_gui:loadGui("dataS/gui/InGameMenuSettingsFrame.xml", "SettingsFrame", inGameMenuSettingsFrame, true)
end
function InGameMenuSettingsFrame.new(target, custom_mt)
    -- upvalues: (copy) InGameMenuSettingsFrame_mt
    local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuSettingsFrame_mt)
    self.missionInfo = nil
    self.manureLoadingStations = {}
    self.liquidManureLoadingStations = {}
    self.hasMasterRights = false
    self.isOpening = false
    self.hasCustomMenuButtons = true
    self.binaryOptionMapping = {}
    self.optionMapping = {}
    self.capacityTable = {}
    self.capacityNumberTable = {}
    local i = g_serverMinCapacity
    for i = i, g_serverMaxCapacity do
        table.insert(self.capacityTable, (tostring(i)))
        table.insert(self.capacityNumberTable, i)
    end
    self.controlsController = nil
    self.controlsData = {}
    self.controlsMessageText = ""
    self.userChangedInput = false
    self.currentFocusCell = nil
    self.dataRowOffset = 0
    self.stateBars = {}
    return self
end
function InGameMenuSettingsFrame.createFromExistingGui(gui, guiName)
    local newGui = InGameMenuSettingsFrame.new()
    g_gui.frames[gui.name].target:delete()
    g_gui.frames[gui.name]:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
    return newGui
end
function InGameMenuSettingsFrame:initialize(_, _, controlsController, _)
    self:initializeSubCategoryPages()
    self:initializeGameSettings()
    self:initializeGeneralSettings()
    self:initializeGraphicSettings()
    self:initializeButtons()
    if Platform.canChangeControls then
        self.controlsController = controlsController
        self.controlsController:setMessageCallback(function(messageId, additionalText, addLine)
            -- upvalues: (copy) self
            self:setControlsMessage(messageId, additionalText, addLine)
        end)
        self.controlsController:setInputDoneCallback(function(madeChange)
            -- upvalues: (copy) self
            self:notifyInputGatheringFinished(madeChange)
        end)
        function self.controlsList.queueReusableCell(instance, cell, _)
            local isFocused = cell:getAttribute("actionButton1") ~= nil and cell:getAttribute("actionButton1"):getIsFocused() or cell:getAttribute("actionButton2") ~= nil and cell:getAttribute("actionButton2"):getIsFocused()
            if not isFocused then
                isFocused = false
                if cell:getAttribute("actionButton3") ~= nil then
                    isFocused = cell:getAttribute("actionButton3"):getIsFocused()
                end
            end
            if not isFocused and instance.sections[cell.sectionIndex] ~= nil then
                instance.sections[cell.sectionIndex].cells[cell.indexInSection] = nil
            end
            if not isFocused then
                cell.sectionIndex = nil
                cell.indexInSection = nil
                local cache = instance.cellCache[cell.reusableName]
                cache[#cache + 1] = cell
                FocusManager:removeElement(cell)
                cell:unlinkElement()
            end
        end
        self.subCategoryPagingFocusChangeFunc = self.subCategoryPaging.shouldFocusChange
        self.sectionTemplate:unlinkElement()
        FocusManager:removeElement(self.sectionTemplate)
        self.deadzoneTemplate:unlinkElement()
        FocusManager:removeElement(self.deadzoneTemplate)
        self.sensitivityTemplate:unlinkElement()
        FocusManager:removeElement(self.sensitivityTemplate)
        self:updateController()
    end
end
function InGameMenuSettingsFrame:initializeSubCategoryPages()
    local subCategories = {}
    for index, button in pairs(self.subCategoryTabs) do
        local index
        button:getDescendantByName("background").getIsSelected = function()
            -- upvalues: (copy) index, (copy) self
            return index == tonumber(self.subCategoryPaging.texts[self.subCategoryPaging:getState()])
        end
        function button.getIsSelected()
            -- upvalues: (copy) index, (copy) self
            return index == tonumber(self.subCategoryPaging.texts[self.subCategoryPaging:getState()])
        end
        if index == InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS and not Platform.canChangeControls then
            button:setVisible(false)
        elseif index == InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE and not Platform.canChangeControls then
            button:setVisible(false)
        elseif index == InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS and not (self.hasMasterRights and g_currentMission.missionDynamicInfo.isMultiplayer) then
            button:setVisible(false)
        else
            if index == InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS then
                self.graphicSettingsLayout:setVisible(not Platform.isConsole)
                self.graphicSettingsLayoutConsole:setVisible(Platform.isConsole)
            end
            button:setVisible(true)
            table.insert(subCategories, (tostring(index)))
        end
    end
    self.subCategoryBox:invalidateLayout()
    self.subCategoryPaging:setTexts(subCategories)
    self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
end
function InGameMenuSettingsFrame:initializeGameSettings(pageMapOverview, onClickBackCallback)
    -- upvalues: (copy) NO_CALLBACK
    self.pageMapOverview = pageMapOverview
    self:assignStaticTexts()
    self.onClickBackCallback = onClickBackCallback or NO_CALLBACK
    local old = self.textSavegameName.onFocusLeave
    function self.textSavegameName.onFocusLeave(...)
        -- upvalues: (copy) old, (copy) self
        old(...)
        self:updateSavegameName()
    end
end
function InGameMenuSettingsFrame:initializeGeneralSettings()
    self.binaryOptionMapping[self.checkAutoHelp] = g_settingsModel.SETTING.SHOW_HELP_MENU
    self.binaryOptionMapping[self.checkColorBlindMode] = g_settingsModel.SETTING.USE_COLORBLIND_MODE
    self.binaryOptionMapping[self.checkUseMiles] = g_settingsModel.SETTING.USE_MILES
    self.binaryOptionMapping[self.checkUseFahrenheit] = g_settingsModel.SETTING.USE_FAHRENHEIT
    self.binaryOptionMapping[self.checkUseAcre] = g_settingsModel.SETTING.USE_ACRE
    self.binaryOptionMapping[self.checkShowTriggerMarker] = g_settingsModel.SETTING.SHOW_TRIGGER_MARKER
    self.binaryOptionMapping[self.checkShowHelpTrigger] = g_settingsModel.SETTING.SHOW_HELP_TRIGGER
    self.binaryOptionMapping[self.checkShowFieldInfo] = g_settingsModel.SETTING.SHOW_FIELD_INFO
    self.binaryOptionMapping[self.checkIsRadioVehicleOnly] = g_settingsModel.SETTING.RADIO_VEHICLE_ONLY
    self.binaryOptionMapping[self.checkIsRadioActive] = g_settingsModel.SETTING.RADIO_IS_ACTIVE
    self.binaryOptionMapping[self.checkResetCamera] = g_settingsModel.SETTING.RESET_CAMERA
    self.binaryOptionMapping[self.checkActiveSuspensionCamera] = g_settingsModel.SETTING.ACTIVE_SUSPENSION_CAMERA
    self.binaryOptionMapping[self.checkCameraCheckCollision] = g_settingsModel.SETTING.CAMERA_CHECK_COLLISION
    self.binaryOptionMapping[self.checkUseWorldCamera] = g_settingsModel.SETTING.USE_WORLD_CAMERA
    self.binaryOptionMapping[self.checkInvertYLook] = g_settingsModel.SETTING.INVERT_Y_LOOK
    self.binaryOptionMapping[self.checkUseEasyArmControl] = g_settingsModel.SETTING.EASY_ARM_CONTROL
    self.binaryOptionMapping[self.checkIsTrainTabbable] = g_settingsModel.SETTING.IS_TRAIN_TABBABLE
    self.binaryOptionMapping[self.checkShowMultiplayerNames] = g_settingsModel.SETTING.SHOW_MULTIPLAYER_NAMES
    self.binaryOptionMapping[self.checkWoodHarvesterAutoCut] = g_settingsModel.SETTING.WOOD_HARVESTER_AUTO_CUT
    self.checkUseMiles:setTexts(g_settingsModel:getDistanceUnitTexts())
    self.checkUseFahrenheit:setTexts(g_settingsModel:getTemperatureUnitTexts())
    self.checkUseAcre:setTexts(g_settingsModel:getAreaUnitTexts())
    self.checkIsRadioVehicleOnly:setTexts(g_settingsModel:getRadioModeTexts())
    self.optionMapping[self.multiMoneyUnit] = g_settingsModel.SETTING.MONEY_UNIT
    self.optionMapping[self.multiCameraSensitivity] = g_settingsModel.SETTING.CAMERA_SENSITIVITY
    self.optionMapping[self.multiVehicleArmSensitivity] = g_settingsModel.SETTING.VEHICLE_ARM_SENSITIVITY
    self.optionMapping[self.multiSteeringBackSpeed] = g_settingsModel.SETTING.STEERING_BACK_SPEED
    self.optionMapping[self.multiSteeringSensitivity] = g_settingsModel.SETTING.STEERING_SENSITIVITY
    self.optionMapping[self.multiMasterVolume] = g_settingsModel.SETTING.VOLUME_MASTER
    self.optionMapping[self.multiVehicleVolume] = g_settingsModel.SETTING.VOLUME_VEHICLE
    self.optionMapping[self.multiEnvironmentVolume] = g_settingsModel.SETTING.VOLUME_ENVIRONMENT
    self.optionMapping[self.multiCharacterVolume] = g_settingsModel.SETTING.VOLUME_CHARACTER
    self.optionMapping[self.multiRadioVolume] = g_settingsModel.SETTING.VOLUME_RADIO
    self.optionMapping[self.multiVolumeGUI] = g_settingsModel.SETTING.VOLUME_GUI
    self.optionMapping[self.multiVolumeNoFocus] = g_settingsModel.SETTING.VOLUME_NO_FOCUS
    self.optionMapping[self.multiInputHelpMode] = g_settingsModel.SETTING.INPUT_HELP_MODE
    self.optionMapping[self.multiDirectionChangeMode] = g_settingsModel.SETTING.DIRECTION_CHANGE_MODE
    self.optionMapping[self.multiGearShiftMode] = g_settingsModel.SETTING.GEAR_SHIFT_MODE
    self.optionMapping[self.multiHudSpeedGauge] = g_settingsModel.SETTING.HUD_SPEED_GAUGE
    self.optionMapping[self.multiVolumeVoice] = g_settingsModel.SETTING.VOLUME_VOICE
    self.optionMapping[self.multiVolumeVoiceInput] = g_settingsModel.SETTING.VOLUME_VOICE_INPUT
    self.optionMapping[self.multiVoiceMode] = g_settingsModel.SETTING.VOICE_MODE
    self.optionMapping[self.multiVoiceInputSensitivity] = g_settingsModel.SETTING.VOICE_INPUT_SENSITIVITY
    self.optionMapping[self.multiRealBeaconLightBrightness] = g_settingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS
    self.multiMoneyUnit:setTexts(g_settingsModel:getMoneyUnitTexts())
    self.multiCameraSensitivity:setTexts(g_settingsModel:getCameraSensitivityTexts())
    self.multiVehicleArmSensitivity:setTexts(g_settingsModel:getVehicleArmSensitivityTexts())
    self.multiSteeringBackSpeed:setTexts(g_settingsModel:getSteeringBackSpeedTexts())
    self.multiSteeringSensitivity:setTexts(g_settingsModel:getSteeringSensitivityTexts())
    self.multiMasterVolume:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.multiVehicleVolume:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.multiEnvironmentVolume:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.multiCharacterVolume:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.multiRadioVolume:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.multiVolumeGUI:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.multiVolumeNoFocus:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.multiVolumeVoice:setTexts(g_settingsModel:getAudioVolumeTexts())
    self.multiVolumeVoiceInput:setTexts(g_settingsModel:getRecordingVolumeTexts())
    self.multiVoiceMode:setTexts(g_settingsModel:getVoiceModeTexts())
    self.multiVoiceInputSensitivity:setTexts(g_settingsModel:getVoiceInputSensitivityTexts())
    self.multiInputHelpMode:setTexts(g_settingsModel:getInputHelpModeTexts())
    self.multiDirectionChangeMode:setTexts(g_settingsModel:getDirectionChangeModeTexts())
    self.multiGearShiftMode:setTexts(g_settingsModel:getGearShiftModeTexts())
    self.multiHudSpeedGauge:setTexts(g_settingsModel:getHudSpeedGaugeTexts())
    if GS_PLATFORM_PC then
        self.multiRealBeaconLightBrightness:setTexts(g_settingsModel:getRealBeaconLightBrightnessTexts())
    end
    if GS_IS_CONSOLE_VERSION then
        self.multiInputHelpMode.parent:setVisible(false)
        self.multiSteeringBackSpeed.parent:setVisible(false)
    end
end
function InGameMenuSettingsFrame:initializeGraphicSettings()
    self.graphicSettingElements = {}
    local function addElement(settingsKey, element, isMultiElement)
        -- upvalues: (copy) self
        self.graphicSettingElements[element] = {
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
    addElement(SettingsModel.SETTING.LENSFLARE_QUALITY, self.lensFlareQualityElement, true)
    addElement(SettingsModel.SETTING.VALAR, self.valarElement, true)
    addElement(SettingsModel.SETTING.SCREEN_SPACE_REFLECTIONS, self.screenSpaceReflectionsElement, true)
    addElement(SettingsModel.SETTING.SCREEN_SPACE_SHADOWS_QUALITY, self.screenSpaceShadowsQualityElement, false)
    addElement(SettingsModel.SETTING.DRS_QUALITY, self.drsQualityElement, true)
    addElement(SettingsModel.SETTING.ATMOSPHERE_QUALITY, self.atmosphereQualityElement, true)
    addElement(SettingsModel.SETTING.VOLUMETRIC_FOG_QUALITY, self.volumetricFogQualityElement, true)
    addElement(SettingsModel.SETTING.TEXTURE_FILTERING, self.textureFilteringElement, true)
    self.realBeaconLightsElementBoxConsole:setVisible(Platform.supportsRealBeaconLights)
end
function InGameMenuSettingsFrame:initializeButtons()
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
    self.saveButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_SAVE_CONTROLS),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:saveControlChanges()
        end,
        ["showWhenPaused"] = true
    }
    self.resetButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_DEFAULTS),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onClickDefaults()
        end,
        ["showWhenPaused"] = true
    }
    self.saveServerSettingsButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACTIVATE,
        ["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_SAVE),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:saveServerChanges()
        end,
        ["showWhenPaused"] = true
    }
    self.unblockButtonInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_1,
        ["text"] = g_i18n:getText("button_blocklist"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonUnBan()
        end
    }
    self.unblockRemoteButtonInfo = {
        ["inputAction"] = InputAction.MENU_CANCEL,
        ["text"] = g_i18n:getText("button_blocklist"),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onButtonUnBanRemote()
        end
    }
    self.applyButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_APPLY),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onApplyGraphicSettings()
        end
    }
    self.switchButtonInfo = {
        ["inputAction"] = InputAction.MENU_EXTRA_1,
        ["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SWITCH_DEVICE),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onSwitchDevice()
        end
    }
    self.applyDeadzoneButtonInfo = {
        ["inputAction"] = InputAction.MENU_ACCEPT,
        ["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_APPLY),
        ["callback"] = function()
            -- upvalues: (copy) self
            self:onApplyDeadzoneChanges()
        end
    }
end
function InGameMenuSettingsFrame:onGuiSetupFinished()
    InGameMenuSettingsFrame:superClass().onGuiSetupFinished(self)
    local oldDisableFunc = self.sharpnessElement.setDisabled
    for _, container in pairs(self.graphicSettingsLayout.elements) do
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
        for index, scalingMode in pairs(InGameMenuSettingsFrame.SCALING_MODES) do
            if g_i18n:getText(scalingMode.title) == container then
                self.scalingModeNameToIndexMapping[container] = index
                break
            end
        end
    end
end
function InGameMenuSettingsFrame:delete()
    if self.sectionTemplate ~= nil then
        self.sectionTemplate:delete()
    end
    if self.deadzoneTemplate ~= nil then
        self.deadzoneTemplate:delete()
    end
    if self.sensitivityTemplate ~= nil then
        self.sensitivityTemplate:delete()
    end
    InGameMenuSettingsFrame:superClass().delete(self)
end
function InGameMenuSettingsFrame:onCreateNumPlayer(element)
    element:setTexts(self.capacityTable)
    element:setState(#self.capacityTable)
end
function InGameMenuSettingsFrame:setMissionInfo(missionInfo)
    self.missionInfo = missionInfo
end
function InGameMenuSettingsFrame:setManureTriggers(manureLoadingStations, liquidManureLoadingStations)
    self.manureLoadingStations = manureLoadingStations
    self.liquidManureLoadingStations = liquidManureLoadingStations
end
function InGameMenuSettingsFrame:setHasMasterRights(hasMasterRights)
    self.hasMasterRights = hasMasterRights
    if g_currentMission ~= nil then
        self:updateButtons()
    end
end
function InGameMenuSettingsFrame:onFrameOpen(_)
    InGameMenuSettingsFrame:superClass().onFrameOpen(self)
    self:initializeSubCategoryPages()
    self.isOpening = true
    local mission = g_currentMission
    local isMultiplayer = mission.missionDynamicInfo.isMultiplayer
    if not isMultiplayer or (g_inGameMenu.isServer or self.hasMasterRights) then
        self:assignDynamicTexts()
        self:updateGameSettings()
        self:updatePauseButtonState()
        self.gameSettingsLayout:setVisible(true)
        self.gameSettingsSeparator:setVisible(true)
        self.gameSettingsNoPermissionText:setVisible(false)
    else
        self.gameSettingsLayout:setVisible(false)
        self.gameSettingsSeparator:setVisible(false)
        self.gameSettingsNoPermissionText:setVisible(true)
    end
    self:updateAlternatingElements(self.gameSettingsLayout)
    self:updateGeneralSettings()
    self.checkIsTrainTabbableBox:setVisible(not isMultiplayer)
    self.multiVolumeVoiceBox:setVisible(isMultiplayer and not VoiceChatUtil.getIsVoiceRestricted())
    self.multiVoiceModeBox:setVisible(isMultiplayer)
    self.multiVolumeVoiceInputBox:setVisible(isMultiplayer and VoiceChatUtil.getHasRecordingDevice() and not VoiceChatUtil.getIsVoiceRestricted())
    self.checkShowMultiplayerNamesBox:setVisible(isMultiplayer and not GS_IS_CONSOLE_VERSION)
    self.multiRealBeaconLightBrightnessBox:setVisible(g_beaconLightManager:getNumOfLights() > 0)
    self.multiVoiceInputSensitivityBox:setVisible(isMultiplayer)
    self.checkCameraCheckCollisionBox:setVisible(g_modIsLoaded.FS25_disableVehicleCameraCollision or g_isDevelopmentVersion)
    self:updateAlternatingElements(self.generalSettingsLayout)
    self:updateGraphicSettings()
    self.frameLimitElement.parent:setVisible(Platform.hasAdjustableFrameLimit and #Platform.frameLimits > 1)
    self:updateAlternatingElements(self.graphicSettingsLayout)
    self:updateAlternatingElements(self.graphicSettingsLayoutConsole)
    if self.hasMasterRights and mission.missionDynamicInfo.isMultiplayer then
        self:assignServerSettings()
    end
    if Platform.canChangeControls then
        self.numTotalDevices = 3 + g_inputBinding.numActiveGamepads
        self.dataRowOffset = 0
        self:assignDeviceTableData()
        self.controlsMessageText = ""
        g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, self.onControllerChanged, self)
        g_inputBinding:resetBindingInputStates()
    end
    self:updateSubCategoryPages((self.subCategoryPaging:getState()))
    self.isOpening = false
end
function InGameMenuSettingsFrame.updateAlternatingElements(_, layout)
    local isAlternate = true
    for _, container in pairs(layout.elements) do
        if container.name == "sectionHeader" then
            isAlternate = true
        elseif container.visible then
            container:setImageColor(nil, unpack(InGameMenuSettingsFrame.COLOR_ALTERNATING[isAlternate]))
            isAlternate = not isAlternate
        end
    end
    layout:invalidateLayout()
end
function InGameMenuSettingsFrame:assignServerSettings()
    self.allowOnlyFriendsElementBg:setVisible(Platform.hasFriendFilter)
    local dynInfo = g_currentMission.missionDynamicInfo
    local capacityState = g_serverMinCapacity
    local i = 1
    for i = i, #self.capacityNumberTable do
        if dynInfo.capacity == self.capacityNumberTable[i] then
            capacityState = i
            break
        end
    end
    self.numPlayersElement:setState(capacityState)
    self.serverNameElementBg:setVisible(not g_currentMission.connectedToDedicatedServer)
    self.autoAcceptElementBg:setVisible(not g_currentMission.connectedToDedicatedServer)
    self.numPlayersBg:setVisible(not g_currentMission.connectedToDedicatedServer)
    self.serverNameElement:setText(dynInfo.serverName)
    self.passwordElement:setText(dynInfo.password)
    self.autoAcceptElement:setIsChecked(dynInfo.autoAccept, true)
    self.allowOnlyFriendsElement:setIsChecked(dynInfo.allowOnlyFriends, true)
    self:updateAlternatingElements(self.serverSettingsLayout)
end
function InGameMenuSettingsFrame:requestClose(callback)
    local hasSettingsChanges = g_settingsModel:hasChanges()
    local canClose = not (self.userChangedInput or (self.hasServerSettingsChanges or hasSettingsChanges))
    if self.userChangedInput then
        InGameMenuSettingsFrame:superClass().requestClose(self, callback)
        YesNoDialog.show(self.onYesNoSaveControls, self, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SAVE_CHANGES_PROMPT))
        return canClose
    end
    if not self.hasServerSettingsChanges then
        if hasSettingsChanges then
            InGameMenuSettingsFrame:superClass().requestClose(self, callback)
            YesNoDialog.show(self.onYesNoSaveGraphicSettings, self, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SAVE_CHANGES_PROMPT))
        end
        return canClose
    end
    InGameMenuSettingsFrame:superClass().requestClose(self, callback)
    YesNoDialog.show(self.onYesNoSaveServerSettings, self, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SAVE_CHANGES_PROMPT))
    return canClose
end
function InGameMenuSettingsFrame:onFrameClose()
    if self.menuAcceptUpEventId ~= nil then
        g_inputBinding:removeActionEvent(self.menuAcceptUpEventId)
    end
    if self.menuUpDownEvent ~= nil then
        g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_LEFT_RIGHT, true)
        g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_UP_DOWN, true)
        g_inputBinding:removeActionEvent(self.menuUpDownEvent)
        g_inputBinding:removeActionEvent(self.menuLeftRightEvent)
    end
    g_messageCenter:unsubscribe(MessageType.INPUT_DEVICES_CHANGED, self)
    g_settingsModel:saveChanges(SettingsModel.SETTING_CLASS.SAVE_GAMEPLAY_SETTINGS)
    InGameMenuSettingsFrame:superClass().onFrameClose(self)
end
function InGameMenuSettingsFrame:update(dt)
    InGameMenuSettingsFrame:superClass().update(self, dt)
    if self.nextFocusSection ~= nil then
        local newCell = self.controlsList:getElementAtSectionIndex(self.nextFocusSection, self.nextFocusCell)
        if newCell ~= nil then
            local newButton = newCell:getAttribute(self.nextFocusedButtonName)
            FocusManager:setFocus(newButton)
            self.nextFocusSection = nil
            self.nextFocusCell = nil
        end
    end
    if self.menuUpDownEvent ~= nil then
        if getNumOfGamepads() ~= self.numOfGamepads then
            self:updateController()
        end
        self:updateGamepadInputStates()
    end
end
function InGameMenuSettingsFrame:onYesNoSaveControls(yes)
    -- upvalues: (copy) NO_CALLBACK
    if yes then
        self:saveControlChanges()
    else
        self:revertChanges()
        self.requestCloseCallback()
        self.requestCloseCallback = NO_CALLBACK
    end
end
function InGameMenuSettingsFrame:revertChanges()
    self.controlsController:discardChanges()
    self.userChangedInput = false
    self:updateButtons()
end
function InGameMenuSettingsFrame:saveControlChanges()
    -- upvalues: (copy) NO_CALLBACK
    if self.userChangedInput then
        self.controlsController:saveChanges()
        self.userChangedInput = false
        self:updateButtons()
        InfoDialog.show(g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SAVED_CHANGES_INFO), self.requestCloseCallback)
        self.requestCloseCallback = NO_CALLBACK
    end
end
function InGameMenuSettingsFrame:onYesNoSaveServerSettings(yes)
    -- upvalues: (copy) NO_CALLBACK
    if yes then
        self:saveServerChanges()
    else
        self:assignServerSettings()
        self.hasServerSettingsChanges = false
        self.requestCloseCallback()
        self.requestCloseCallback = NO_CALLBACK
    end
    self:updateButtons()
end
function InGameMenuSettingsFrame:saveServerChanges()
    -- upvalues: (copy) NO_CALLBACK
    if self.hasServerSettingsChanges then
        local serverName = self.serverNameElement:getText()
        local filteredServerName = filterText(serverName, false, true)
        if serverName == "" or serverName ~= filteredServerName then
            if serverName == "" then
                self.serverNameElement:setText(g_currentMission:getDefaultServerName())
            else
                self.serverNameElement:setText(filteredServerName)
                printWarning("Warning: Gamename not allowed. Profanity text filter. Gamename adjusted")
            end
        end
        local password = self.passwordElement:getText()
        local capacity = self.capacityNumberTable[self.numPlayersElement:getState()]
        local autoAccept = self.autoAcceptElement:getIsChecked()
        local allowOnlyFriends = self.allowOnlyFriendsElement:getIsChecked()
        g_currentMission:updateMissionDynamicInfo(serverName, capacity, password, autoAccept, allowOnlyFriends, g_currentMission.missionDynamicInfo.allowCrossPlay)
        if g_currentMission:getIsServer() then
            g_currentMission:updateMasterServerInfo()
        else
            g_client:getServerConnection():sendEvent(MissionDynamicInfoEvent.new())
        end
        self.hasServerSettingsChanges = false
        InfoDialog.show(g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SAVED_CHANGES_INFO), self.requestCloseCallback)
        self.requestCloseCallback = NO_CALLBACK
    end
    self:updateButtons()
end
function InGameMenuSettingsFrame:onButtonUnBan()
    UnBanDialog.show(self.updateButtons, self, true)
end
function InGameMenuSettingsFrame:onButtonUnBanRemote()
    UnBanDialog.show(self.updateButtons, self, false)
end
function InGameMenuSettingsFrame:onYesNoSaveGraphicSettings(yes)
    -- upvalues: (copy) NO_CALLBACK
    if yes then
        self:onApplyGraphicSettings()
    else
        g_settingsModel:reset()
        self:updateGraphicSettings()
        self.requestCloseCallback()
        self.requestCloseCallback = NO_CALLBACK
    end
    self:updateButtons()
end
function InGameMenuSettingsFrame:onApplyGraphicSettings()
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
                self:applyGraphicSettings()
            end
        end, nil, g_i18n:getText("ui_resolutionScaleWarning"))
    else
        self:applyGraphicSettings()
    end
end
function InGameMenuSettingsFrame:applyGraphicSettings()
    local needsRestart, needsProcessRestart = g_settingsModel:needsRestartToApplyChanges()
    g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
    if needsRestart or needsProcessRestart then
        Logging.warning("A setting change needs a restart to be applied, no such setting should be in the ingame menu!")
    else
        self:updateButtons()
    end
end
function InGameMenuSettingsFrame:updateButtons()
    self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
    local subCategoryIndex = tonumber(self.subCategoryPaging.texts[self.subCategoryPaging:getState()])
    if subCategoryIndex == InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS and Platform.canChangeControls then
        if self.userChangedInput then
            table.insert(self.menuButtonInfo, self.saveButtonInfo)
        end
        table.insert(self.menuButtonInfo, self.resetButtonInfo)
    elseif subCategoryIndex == InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS then
        if self.hasServerSettingsChanges then
            table.insert(self.menuButtonInfo, self.saveServerSettingsButtonInfo)
        end
        if getNumOfBlockedUsers() > 0 then
            table.insert(self.menuButtonInfo, self.unblockButtonInfo)
        end
        if g_currentMission ~= nil and g_currentMission.connectedToDedicatedServer then
            table.insert(self.menuButtonInfo, self.unblockRemoteButtonInfo)
        end
    elseif subCategoryIndex == InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS then
        if g_settingsModel:hasChanges() then
            table.insert(self.menuButtonInfo, self.applyButtonInfo)
        end
    elseif subCategoryIndex == InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE then
        if g_settingsModel:getNumDevices() > 1 then
            table.insert(self.menuButtonInfo, self.switchButtonInfo)
        end
        if g_settingsModel:hasChanges() then
            table.insert(self.menuButtonInfo, self.applyDeadzoneButtonInfo)
        end
    end
    self:setMenuButtonInfoDirty()
end
function InGameMenuSettingsFrame:updateGameSettings()
    self.savegameName = self.missionInfo.savegameName
    self.textSavegameName:setText(self.missionInfo.savegameName)
    self.multiTimeScale:setState(Utils.getTimeScaleIndex(self.missionInfo.timeScale))
    self.economicDifficulty:setState(self.missionInfo.economicDifficulty)
    self.checkSnowEnabled:setIsChecked(self.missionInfo.isSnowEnabled, self.isOpening)
    self.multiGrowthMode:setState(self.missionInfo.growthMode)
    local period = self.missionInfo.fixedSeasonalVisuals
    self.multiFixedSeasonalVisuals:setState(period == nil and 1 or period + 1)
    self.multiPlannedDaysPerPeriod:setState(self.missionInfo.plannedDaysPerPeriod)
    self.checkFruitDestruction:setIsChecked(self.missionInfo.fruitDestruction, self.isOpening)
    self.checkPlowingRequired:setIsChecked(self.missionInfo.plowingRequiredEnabled, self.isOpening)
    self.checkStonesEnabled:setIsChecked(self.missionInfo.stonesEnabled, self.isOpening)
    self.checkLimeRequired:setIsChecked(self.missionInfo.limeRequired, self.isOpening)
    self.checkWeedsEnabled:setIsChecked(self.missionInfo.weedsEnabled, self.isOpening)
    self.multiAutoSaveInterval:setState(g_autoSaveManager:getIndexFromInterval(g_autoSaveManager:getInterval()))
    self.checkTraffic:setIsChecked(self.missionInfo.trafficEnabled, self.isOpening)
    self.multiDirt:setState(self.missionInfo.dirtInterval)
    self.checkAutoMotorStart:setIsChecked(self.missionInfo.automaticMotorStartEnabled, self.isOpening)
    self.checkHelperRefillFuel:setIsChecked(self.missionInfo.helperBuyFuel, self.isOpening)
    self.checkHelperRefillSeed:setIsChecked(self.missionInfo.helperBuySeeds, self.isOpening)
    self.checkHelperRefillFertilizer:setIsChecked(self.missionInfo.helperBuyFertilizer, self.isOpening)
    self.multiFuelUsage:setState(self.missionInfo.fuelUsage)
    self.checkStopAndGoBraking:setIsChecked(self.missionInfo.stopAndGoBraking, self.isOpening)
    self.checkTrailerFillLimit:setIsChecked(self.missionInfo.trailerFillLimit, self.isOpening)
    self.multiDisasterDestructionState:setState(self.missionInfo.disasterDestructionState)
    self.multiHelperRefillSlurry:setState(self.missionInfo.helperSlurrySource)
    self.multiHelperRefillManure:setState(self.missionInfo.helperManureSource)
    local isTourRunning = g_guidedTourManager:getIsTourRunning()
    self.textSavegameName:setDisabled(not self.hasMasterRights)
    self.multiTimeScale:setDisabled(not self.hasMasterRights or isTourRunning)
    self.economicDifficulty:setDisabled(not self.hasMasterRights)
    self.checkSnowEnabled:setDisabled(not self.hasMasterRights)
    self.multiGrowthMode:setDisabled(not self.hasMasterRights)
    self.multiFixedSeasonalVisuals:setDisabled(not self.hasMasterRights)
    self.multiPlannedDaysPerPeriod:setDisabled(not self.hasMasterRights)
    self.checkFruitDestruction:setDisabled(not self.hasMasterRights)
    self.checkPlowingRequired:setDisabled(not self.hasMasterRights)
    self.checkLimeRequired:setDisabled(not self.hasMasterRights)
    self.checkWeedsEnabled:setDisabled(not self.hasMasterRights)
    self.multiDirt:setDisabled(not self.hasMasterRights)
    self.multiAutoSaveInterval:setDisabled(not g_currentMission:getIsServer())
    if self.multiAutoSaveIntervalBox == nil then
        self.multiAutoSaveInterval:setVisible(g_currentMission:getIsServer())
    else
        self.multiAutoSaveIntervalBox:setVisible(g_currentMission:getIsServer())
    end
end
function InGameMenuSettingsFrame:updatePauseButtonState()
    if g_currentMission.paused then
        self.buttonPauseGame:applyProfile(InGameMenuSettingsFrame.PROFILE.BUTTON_UNPAUSE)
        self.buttonPauseGame:setText(g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.UNPAUSE))
    else
        self.buttonPauseGame:applyProfile(InGameMenuSettingsFrame.PROFILE.BUTTON_PAUSE)
        self.buttonPauseGame:setText(g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.PAUSE))
    end
end
function InGameMenuSettingsFrame:assignStaticTexts()
    self:assignTimeScaleTexts()
    self:assignEconomicDifficultyTexts()
    self:assignDirtTexts()
    self:assignAutoSaveTexts()
    self.multiFuelUsage:setTexts({ g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.USAGE_LOW), g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.USAGE_DEFAULT), g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.USAGE_HIGH) })
    self.multiDisasterDestructionState:setTexts({ g_i18n:getText("setting_disasterDestructionState_enabled"), g_i18n:getText("setting_disasterDestructionState_visualsOnly"), g_i18n:getText("setting_disasterDestructionState_disabled") })
    local helperTexts = { g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.OFF), g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUY) }
    self.checkHelperRefillFuel:setTexts(helperTexts)
    self.checkHelperRefillSeed:setTexts(helperTexts)
    self.checkHelperRefillFertilizer:setTexts(helperTexts)
    self.multiGrowthMode:setTexts({ g_i18n:getText("ui_yes"), g_i18n:getText("ui_no"), g_i18n:getText("ui_paused") })
    local options = { g_i18n:getText("ui_off") }
    local i = 1
    local days = 12
    for i = i, days do
        table.insert(options, g_i18n:formatPeriod(i))
    end
    self.multiFixedSeasonalVisuals:setTexts(options)
    local days = {}
    local i = 1
    local i = 1
    for i = i, Environment.MAX_DAYS_PER_PERIOD, i do
        table.insert(days, g_i18n:formatNumDay(i))
    end
    self.multiPlannedDaysPerPeriod:setTexts(days)
end
function InGameMenuSettingsFrame:assignTimeScaleTexts()
    local timeScaleTable = {}
    local numTimeScales = Utils.getNumTimeScales()
    local i = 1
    for i = i, numTimeScales do
        table.insert(timeScaleTable, Utils.getTimeScaleString(i))
    end
    self.multiTimeScale:setTexts(timeScaleTable)
end
function InGameMenuSettingsFrame:assignEconomicDifficultyTexts()
    local economicDifficultyTable = {}
    table.insert(economicDifficultyTable, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.DIFFICULTY_EASY))
    table.insert(economicDifficultyTable, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.DIFFICULTY_NORMAL))
    table.insert(economicDifficultyTable, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.DIFFICULTY_HARD))
    self.economicDifficulty:setTexts(economicDifficultyTable)
end
function InGameMenuSettingsFrame:assignDirtTexts()
    local textTable = {}
    local i = g_i18n
    table.insert(textTable, i:getText(InGameMenuSettingsFrame.L10N_SYMBOL.OFF))
    local i = 1
    for i = i, 3 do
        table.insert(textTable, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.DIRT_TEMPLATE .. i))
    end
    self.multiDirt:setTexts(textTable)
end
function InGameMenuSettingsFrame:assignAutoSaveTexts()
    local textTable = {}
    for _, interval in ipairs(g_autoSaveManager:getIntervalOptions()) do
        if interval > 0 then
            table.insert(textTable, interval .. " " .. g_i18n:getText("unit_minutesShort"))
        else
            table.insert(textTable, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.OFF))
        end
    end
    self.multiAutoSaveInterval:setTexts(textTable)
end
function InGameMenuSettingsFrame:assignDynamicTexts()
    self.helperManureTextToStationIndexMapping = { 1, 2 }
    self.helperSlurryTextToStationIndexMapping = { 1, 2 }
    local helperTexts = { g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.OFF), g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUY) }
    local textTable = {}
    table.insert(textTable, helperTexts[1])
    table.insert(textTable, helperTexts[2])
    for stationIndex, station in ipairs(self.manureLoadingStations) do
        if g_currentMission.accessHandler:canPlayerAccess(station) then
            table.insert(textTable, station:getName())
            self.helperManureTextToStationIndexMapping[#textTable] = stationIndex + 2
        end
    end
    self.multiHelperRefillManure:setTexts(textTable)
    local textTable = {}
    table.insert(textTable, helperTexts[1])
    table.insert(textTable, helperTexts[2])
    for stationIndex, station in ipairs(self.liquidManureLoadingStations) do
        if g_currentMission.accessHandler:canPlayerAccess(station) and station:getIsFillAllowedToFarm(g_currentMission:getFarmId()) then
            table.insert(textTable, station:getName())
            self.helperSlurryTextToStationIndexMapping[#textTable] = stationIndex + 2
        end
    end
    self.multiHelperRefillSlurry:setTexts(textTable)
end
function InGameMenuSettingsFrame:updateGeneralSettings()
    g_settingsModel:refresh()
    for element, settingsKey in pairs(self.binaryOptionMapping) do
        element:setIsChecked(g_settingsModel:getValue(settingsKey), self.isOpening)
    end
    for element, settingsKey in pairs(self.optionMapping) do
        element:setState(g_settingsModel:getValue(settingsKey))
    end
end
function InGameMenuSettingsFrame:updateGraphicSettings()
    if Platform.isConsole then
        self.fovYElementConsole:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y))
        self.fovYPlayerFirstPersonElementConsole:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON))
        self.fovYPlayerThirdPersonElementConsole:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
        self.uiScaleElementConsole:setState(g_settingsModel:getValue(SettingsModel.SETTING.UI_SCALE))
        self.brightnessElementConsole:setState(g_settingsModel:getValue(SettingsModel.SETTING.BRIGHTNESS))
        self.realBeaconLightsElementConsole:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS), self.isOpening)
        self:updateButtons()
        self.graphicSettingsLayoutConsole:invalidateLayout()
        return
    end
    local performanceTexts, _, _ = g_settingsModel:getPerformanceClassTexts()
    self.performanceClassElement:setTexts(performanceTexts)
    self.performanceClassElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.PERFORMANCE_CLASS))
    self.vSyncElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.V_SYNC), self.isOpening)
    self.brightnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.BRIGHTNESS))
    self.uiScaleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.UI_SCALE))
    self.resolutionScaleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE))
    if Platform.hasAdjustableFrameLimit and #Platform.frameLimits > 1 then
        self.frameLimitElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FRAME_LIMIT))
    end
    for _, data in pairs(self.graphicSettingElements) do
        if data.isMultiElement then
            data.element:setState(g_settingsModel:getValue(data.settingsKey) or 1)
        else
            local frameGenerationActive = g_settingsModel:getValue(data.settingsKey) == BinaryOptionElement.STATE_RIGHT
            data.element:setIsChecked(frameGenerationActive, self.isOpening)
        end
    end
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
    local settingFSR30 = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30)
    local _ = settingFSR30 ~= FidelityFxSR30Quality.OFF and settingFSR30 ~= nil
    local data = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR)
    local isFSRActive = false
    if data ~= FidelityFxSRQuality.OFF then
        isFSRActive = data ~= nil
    end
    local supportsFrameGeneration = getSupportsFidelityFxFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
    if supportsFrameGeneration then
        if postProcessAA == PostProcessAntiAliasing.FSR3 or _ then
            supportsFrameGeneration = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
        else
            supportsFrameGeneration = _
        end
    end
    local supportsXeSSFrameGeneration = getSupportsXeSSFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
    local isNativeXeSS = postProcessAA == PostProcessAntiAliasing.XESS
    local settingXeSS = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS)
    local isXeSSActive = false
    if settingXeSS ~= XeSSQuality.OFF then
        isXeSSActive = settingXeSS ~= nil
    end
    if supportsXeSSFrameGeneration then
        if isNativeXeSS or isXeSSActive then
            supportsXeSSFrameGeneration = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
        else
            supportsXeSSFrameGeneration = isXeSSActive
        end
    end
    local supportsDLSSFrameGeneration = getSupportsDLSSFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
    local settingDLSS = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS)
    local isDLSSActive = false
    if settingDLSS ~= DLSSQuality.OFF then
        isDLSSActive = settingDLSS ~= nil
    end
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
    self.frameGenerationContainer:setDisabled(not (supportsFrameGeneration or (supportsXeSSFrameGeneration or isDLAAActive)))
    local frameGenerationElementTexts = { getFrameInterpolationModeName(FrameInterpolationMode.FRAME_INTERPOLATION_OFF) }
    local textsFunc = getSupportsDLSSFrameInterpolation
    if supportsXeSSFrameGeneration then
        textsFunc = getSupportsXeSSFrameInterpolation
    elseif supportsFrameGeneration then
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
    local _ = SettingsModel.SETTING.DLSS_FRAME_GENERATION
    local frameGenerationState = math.max(settingsKey, i, g_settingsModel:getValue(_))
    self.frameGenerationElement:setState(frameGenerationState + 1)
    if isNativeXeSS or isXeSSActive then
        self.frameGenerationTitle:setText(g_i18n:getText("setting_xeSSFrameGeneration"))
        self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_xeSSFrameGeneration"))
    elseif isNativeFSR3 or _ then
        self.frameGenerationTitle:setText(g_i18n:getText("setting_fidelityFxSR30FrameInterpolation"))
        self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_fidelityFxSR30FrameInterpolation"))
    elseif isDLSSActive then
        self.frameGenerationTitle:setText(g_i18n:getText("setting_dlssFrameInterpolation"))
        self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_dlssFrameInterpolation"))
    else
        self.frameGenerationTitle:setText(g_i18n:getText("setting_frameGeneration"))
    end
    self.resolutionScaleContainer:setDisabled(isDLSSActive or (isXeSSActive or (_ or isFSRActive)))
    self.resolutionScale3dContainer:setDisabled(isDLSSActive or (isXeSSActive or (_ or isFSRActive)))
    local settingsKey = nil
    for _, setting in pairs(InGameMenuSettingsFrame.SCALING_MODES) do
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
    self.scalingModeQualityContainer:setDisabled(settingsKey ~= nil)
    self:updateButtons()
    self.graphicSettingsLayout:invalidateLayout()
end
function InGameMenuSettingsFrame:updateHeader()
    local hasGamepads = g_inputBinding.numActiveGamepads > 0
    local hasKeyboard = getIsKeyboardAvailable()
    self.gamepadHeaderText:setVisible(hasGamepads)
    self.keyboardHeaderText:setVisible(hasKeyboard)
    self.gamepadHeaderText:setDisabled(true)
    self.keyboardHeaderText:setDisabled(true)
    if hasKeyboard then
        self.keyboardHeaderText:setDisabled(false)
    elseif hasGamepads then
        self.gamepadHeaderText:setDisabled(false)
    end
end
function InGameMenuSettingsFrame:setupControlsView()
    if getIsKeyboardAvailable() then
        self.deviceCategoryTables[InputDevice.CATEGORY.KEYBOARD_MOUSE] = self.keyboardMouseTable
        self:bindControls(InGameMenuSettingsFrame.KB_MOUSE_BOUND_CONTROLS, InputDevice.CATEGORY.KEYBOARD_MOUSE)
    else
        self.deviceCategoryTables[InputDevice.CATEGORY.KEYBOARD_MOUSE] = nil
        self.deviceCategoryDataBindings[InputDevice.CATEGORY.KEYBOARD_MOUSE] = nil
    end
    if g_inputBinding.numActiveGamepads > 0 then
        self:bindControls(InGameMenuSettingsFrame.GAMEPAD_BOUND_CONTROLS, InputDevice.CATEGORY.GAMEPAD)
        self.deviceCategoryTables[InputDevice.CATEGORY.GAMEPAD] = self.gamepadTable
    else
        self.deviceCategoryTables[InputDevice.CATEGORY.GAMEPAD] = nil
        self.deviceCategoryDataBindings[InputDevice.CATEGORY.GAMEPAD] = nil
    end
end
function InGameMenuSettingsFrame:assignDeviceTableData()
    self.controlsController:loadBindings()
    self.controlsData = self.controlsController:getDeviceCategoryActionBindings()
    self.controlsList:reloadData()
    self:updateListHeaderNames()
end
function InGameMenuSettingsFrame:updateListHeaderNames()
    local gamepads = g_inputBinding:getGamepadDevices()
    local index = 1 + self.dataRowOffset
    local headerName
    if index <= 3 then
        headerName = g_i18n:getText(SettingsControlsFrame.DEVICES[index].name)
    else
        headerName = gamepads[index - 3].name
        if g_i18n:hasText(headerName) then
            headerName = g_i18n:getText(headerName)
        elseif InputDevice.NAMES[headerName] ~= nil then
        end
    end
    self.headerText1:setText(headerName)
    local index = index + 1
    local headerName
    if index <= 3 then
        headerName = g_i18n:getText(SettingsControlsFrame.DEVICES[index].name)
    else
        headerName = gamepads[index - 3].name
        if g_i18n:hasText(headerName) then
            headerName = g_i18n:getText(headerName)
        elseif InputDevice.NAMES[headerName] ~= nil then
        end
    end
    self.headerText2:setText(headerName)
    local index = index + 1
    local headerName
    if index <= 3 then
        headerName = g_i18n:getText(SettingsControlsFrame.DEVICES[index].name)
    else
        headerName = gamepads[index - 3].name
        if g_i18n:hasText(headerName) then
            headerName = g_i18n:getText(headerName)
        elseif InputDevice.NAMES[headerName] ~= nil then
        end
    end
    self.headerText3:setText(headerName)
    self.buttonPrevRow:setVisible(self.dataRowOffset > 0)
    self.buttonNextRow:setVisible(self.dataRowOffset < self.numTotalDevices - 3)
    self.gamepads = gamepads
end
function InGameMenuSettingsFrame:setControlsMessage(messageId, additionalText, addLine)
    if messageId and messageId ~= ControlsController.MESSAGE_CLEAR then
        local text = ""
        if addLine then
            text = self.controlsMessageText .. "\n"
        end
        local uiSymbol = SettingsControlsFrame.CONTROLS_UI_STRINGS[messageId]
        local text
        if uiSymbol then
            text = text .. g_i18n:getText(uiSymbol)
            if additionalText and #additionalText > 0 then
            end
        else
            local formatString = g_i18n:getText(SettingsControlsFrame.L10N_TEMPLATE_SYMBOL[messageId])
            if additionalText and #additionalText > 0 then
                text = text .. string.format(formatString, unpack(additionalText))
            end
        end
        self.controlsMessageText = text
        InfoDialog.show(text, nil, nil, InGameMenuSettingsFrame.CONFLICT_MESSAGES[uiSymbol] ~= nil and DialogElement.TYPE_WARNING or DialogElement.TYPE_INFO)
    else
        self.controlsMessageText = ""
    end
end
function InGameMenuSettingsFrame:notifyInputGatheringFinished(madeChange)
    self:setSoundSuppressed(true)
    g_gui:closeAllDialogs()
    FocusManager:setGui(self.name)
    self:setSoundSuppressed(false)
    if madeChange then
        self:assignDeviceTableData()
        self.userChangedInput = true
        self:updateButtons()
    end
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end
function InGameMenuSettingsFrame.showInputPrompt(_, deviceCategory, bindingId, actionData)
    local promptStringSymbol
    if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
        if bindingId == ControlsController.BINDING_PRIMARY or bindingId == ControlsController.BINDING_SECONDARY then
            promptStringSymbol = InGameMenuSettingsFrame.L10N_SYMBOL.KEY_PROMPT
        else
            promptStringSymbol = InGameMenuSettingsFrame.L10N_SYMBOL.MOUSE_PROMPT
        end
    else
        promptStringSymbol = InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_PROMPT
    end
    local promptTemplate = g_i18n:getText(promptStringSymbol)
    local text = string.format(promptTemplate, actionData.displayName) .. "\n" .. g_i18n:getText(InGameMenuSettingsFrame.CONTROLS_UI_STRINGS[ControlsController.MESSAGE_PROMPT_CANCEL_DELETE])
    local ensureInNeutral = g_i18n:getText(InGameMenuSettingsFrame.CONTROLS_UI_STRINGS[ControlsController.MESSAGE_ENSURE_IN_NEUTRAL])
    if utf8Strlen(ensureInNeutral) > 1 then
    end
    MessageDialog.show(text, nil, nil, DialogElement.TYPE_KEY)
end
InGameMenuSettingsFrame.KB_MOUSE_BOUND_CONTROLS = {
    ["ACTION"] = "action",
    ["KEY_1"] = "key1",
    ["KEY_2"] = "key2",
    ["MOUSE_BUTTON"] = "mouseButton"
}
InGameMenuSettingsFrame.GAMEPAD_BOUND_CONTROLS = {
    ["ACTION"] = "gamepadAction",
    ["BUTTON_1"] = "gamepadButton1",
    ["BUTTON_2"] = "gamepadButton2"
}
function InGameMenuSettingsFrame:bindControls(bindings, deviceCategory)
    for bindingName, columnName in pairs(bindings) do
        if not self.deviceCategoryDataBindings[deviceCategory] then
            self.deviceCategoryDataBindings[deviceCategory] = {}
        end
        self.deviceCategoryDataBindings[deviceCategory][bindingName] = columnName
    end
end
function InGameMenuSettingsFrame:onEnterPressedSavegameName()
    self:updateSavegameName()
end
function InGameMenuSettingsFrame:updateSavegameName()
    local newName = self.textSavegameName.text
    if newName ~= self.savegameName then
        if newName == "" then
            newName = g_i18n:getText("defaultSavegameName")
            self.textSavegameName:setText(newName)
        end
        self.missionInfo.savegameName = newName
        self.savegameName = newName
        SavegameSettingsEvent.sendEvent()
    end
end
function InGameMenuSettingsFrame:onClickTimeScale(state)
    if self.hasMasterRights then
        g_currentMission:setTimeScale(Utils.getTimeScaleFromIndex(state))
    end
end
function InGameMenuSettingsFrame:onClickEconomicDifficulty(state)
    if self.hasMasterRights then
        g_currentMission:setEconomicDifficulty(state)
    end
end
function InGameMenuSettingsFrame:onClickTraffic(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setTrafficEnabled(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickDirt(state)
    if self.hasMasterRights then
        g_currentMission:setDirtInterval(state)
    end
end
function InGameMenuSettingsFrame:onClickFuelUsage(state)
    if self.hasMasterRights then
        g_currentMission:setFuelUsage(state)
    end
end
function InGameMenuSettingsFrame:onClickHelperRefillFuel(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setHelperBuyFuel(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickHelperRefillSeed(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setHelperBuySeeds(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickHelperRefillFertilizer(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setHelperBuyFertilizer(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickHelperRefillSlurry(state)
    if self.hasMasterRights then
        if self.helperSlurryTextToStationIndexMapping ~= nil then
            g_currentMission:setHelperSlurrySource(self.helperSlurryTextToStationIndexMapping[state] or 1)
            return
        end
        g_currentMission:setHelperSlurrySource(1)
    end
end
function InGameMenuSettingsFrame:onClickHelperRefillManure(state)
    if self.hasMasterRights then
        if self.helperManureTextToStationIndexMapping ~= nil then
            g_currentMission:setHelperManureSource(self.helperManureTextToStationIndexMapping[state] or 1)
            return
        end
        g_currentMission:setHelperManureSource(1)
    end
end
function InGameMenuSettingsFrame:onClickAutomaticMotorStart(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setAutomaticMotorStartEnabled(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickSnowEnabled(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setSnowEnabled(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickPlannedDaysPerPeriod(state)
    if self.hasMasterRights then
        g_currentMission:setPlannedDaysPerPeriod(state)
    end
end
function InGameMenuSettingsFrame:onClickGrowthMode(state)
    if self.hasMasterRights then
        g_currentMission:setGrowthMode(state)
    end
end
function InGameMenuSettingsFrame:onClickFixedSeasonalVisuals(state)
    if self.hasMasterRights then
        if state == 1 then
            g_currentMission:setFixedSeasonalVisuals(nil)
            return
        end
        g_currentMission:setFixedSeasonalVisuals(state - 1)
    end
end
function InGameMenuSettingsFrame:onClickDisasterDestructionState(state)
    if self.hasMasterRights then
        g_currentMission:setDisasterDestructionState(state)
    end
end
function InGameMenuSettingsFrame:onClickFruitDestruction(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setFruitDestructionEnabled(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickPlowingRequired(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setPlowingRequiredEnabled(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickStonesEnabled(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setStonesEnabled(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickLimeRequired(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setLimeRequired(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickWeedsEnabled(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setWeedsEnabled(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickStopAndGoBraking(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setStopAndGoBraking(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickTrailerFillLimit(_, binaryElement)
    if self.hasMasterRights then
        g_currentMission:setTrailerFillLimit(binaryElement:getIsChecked())
    end
end
function InGameMenuSettingsFrame:onClickAutoSaveInterval(state)
    if self.hasMasterRights then
        g_currentMission:setAutoSaveInterval(g_autoSaveManager:getIntervalFromIndex(state))
    end
end
function InGameMenuSettingsFrame:onClickPauseGame()
    if GS_IS_CONSOLE_VERSION then
        self.onClickBackCallback()
    end
    g_currentMission:setManualPause(not g_currentMission.paused)
    self:updatePauseButtonState()
end
function InGameMenuSettingsFrame:onClickBinaryOption(_, binaryElement)
    local settingsKey = self.binaryOptionMapping[binaryElement]
    if settingsKey == nil then
        printWarning("Warning: Invalid settings checkbox event or key configuration for element " .. binaryElement:toString())
    else
        g_settingsModel:setValue(settingsKey, binaryElement:getIsChecked())
        g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_NONE)
        self.dirty = true
    end
end
function InGameMenuSettingsFrame:onClickMultiOption(state, optionElement)
    if optionElement == self.multiVoiceMode and VoiceChatUtil.getIsVoiceRestricted() then
        VoiceChatUtil.showVoiceRestrictedPopup()
        optionElement:setState(VoiceChatUtil.MODE.DISABLED)
    else
        local settingsKey = self.optionMapping[optionElement]
        if settingsKey == nil then
            printWarning("Warning: Invalid settings multi option event or key configuration for element " .. optionElement:toString())
        else
            g_settingsModel:setValue(settingsKey, state)
            g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_NONE)
            self.dirty = true
        end
        if optionElement == self.multiRealBeaconLightBrightness then
            g_beaconLightManager:updateBeaconLights()
        end
    end
end
function InGameMenuSettingsFrame:onEnterPressedServerName()
    if g_currentMission.missionDynamicInfo.serverName ~= self.serverNameElement:getText() then
        self.hasServerSettingsChanges = true
    end
    self:updateButtons()
end
function InGameMenuSettingsFrame:onEnterOrEscPressedServerPassword()
    if g_currentMission.missionDynamicInfo.password ~= self.passwordElement:getText() then
        self.hasServerSettingsChanges = true
    end
    self:updateButtons()
end
function InGameMenuSettingsFrame:onClickServerNumPlayers()
    if g_currentMission.missionDynamicInfo.capacity ~= self.numPlayersElement.textElement:getText() then
        self.hasServerSettingsChanges = true
    end
    self:updateButtons()
end
function InGameMenuSettingsFrame:onClickServerAutoAccept()
    if g_currentMission.missionDynamicInfo.autoAccept ~= self.autoAcceptElement:getIsChecked() then
        self.hasServerSettingsChanges = true
    end
    self:updateButtons()
end
function InGameMenuSettingsFrame:onClickServerAllowOnlyFriends()
    if g_currentMission.missionDynamicInfo.allowOnlyFriends ~= self.allowOnlyFriendsElement:getIsChecked() then
        self.hasServerSettingsChanges = true
    end
    self:updateButtons()
end
function InGameMenuSettingsFrame.onCreatePerformanceClass(_, element)
    local texts, _, _ = g_settingsModel:getPerformanceClassTexts()
    element:setTexts(texts)
end
function InGameMenuSettingsFrame.onCreateBrightness(_, element)
    element:setTexts(g_settingsModel:getBrightnessTexts())
end
function InGameMenuSettingsFrame.onCreateUIScale(_, element)
    element:setTexts(g_settingsModel:getUiScaleTexts())
end
function InGameMenuSettingsFrame.onCreateResolutionScale(_, element)
    element:setTexts(g_settingsModel:getResolutionScaleTexts())
end
function InGameMenuSettingsFrame.onCreateFrameLimit(_, element)
    element:setTexts(g_settingsModel:getFrameLimitTexts())
end
function InGameMenuSettingsFrame.onCreatePPAAToolTip(_, element)
    element:setText(g_settingsModel:getPostProcessAAToolTip())
end
function InGameMenuSettingsFrame.onCreateDRSTargetFPS(_, element)
    element:setTexts(g_settingsModel:getDRSTargetFPSTexts())
end
function InGameMenuSettingsFrame.onCreateSharpness(_, element)
    element:setTexts(g_settingsModel:getSharpnessTexts())
end
function InGameMenuSettingsFrame.onCreateScalingMode(_, element)
    element:setTexts(g_settingsModel:getScalingModeTexts())
end
function InGameMenuSettingsFrame.onCreateScalingModeQuality(_, element)
    element:setTexts(g_settingsModel:getTexts(SettingsModel.SETTING.FIDELITYFX_SR))
end
function InGameMenuSettingsFrame.onCreateShadingRateQuality(_, element)
    element:setTexts(g_settingsModel:getShadingRateQualityTexts())
end
function InGameMenuSettingsFrame.onCreateShadowQuality(_, element)
    element:setTexts(g_settingsModel:getShadowQualityTexts())
end
function InGameMenuSettingsFrame.onCreateShadowDistanceQuality(_, element)
    element:setTexts(g_settingsModel:getShadowDistanceQualityTexts())
end
function InGameMenuSettingsFrame.onCreateSoftShadows(_, element)
    element:setTexts(g_settingsModel:getSoftShadowsTexts())
end
function InGameMenuSettingsFrame.onCreateSSAOQuality(_, element)
    element:setTexts(g_settingsModel:getSSAOQualityTexts())
end
function InGameMenuSettingsFrame.onCreateShaderQuality(_, element)
    element:setTexts(g_settingsModel:getShaderQualityTexts())
end
function InGameMenuSettingsFrame.onCreateTextureResolution(_, element)
    element:setTexts(g_settingsModel:getTextureResolutionTexts())
end
function InGameMenuSettingsFrame.onCreateShadowMapFiltering(_, element)
    element:setTexts(g_settingsModel:getShadowMapFilteringTexts())
end
function InGameMenuSettingsFrame.onCreateLightsProfile(_, element)
    element:setTexts(g_settingsModel:getLightsProfileTexts())
end
function InGameMenuSettingsFrame.onCreateTerrainQuality(_, element)
    element:setTexts(g_settingsModel:getTerraingQualityTexts())
end
function InGameMenuSettingsFrame.onCreateShadowMaxLights(_, element)
    element:setTexts(g_settingsModel:getShadowMapLightsTexts())
end
function InGameMenuSettingsFrame.onCreateObjectDrawDistance(_, element)
    element:setTexts(g_settingsModel:getObjectDrawDistanceTexts())
end
function InGameMenuSettingsFrame.onCreateFoliageDrawDistance(_, element)
    element:setTexts(g_settingsModel:getFoliageDrawDistanceTexts())
end
function InGameMenuSettingsFrame.onCreateLODDistance(_, element)
    element:setTexts(g_settingsModel:getLODDistanceTexts())
end
function InGameMenuSettingsFrame.onCreateTerrainLODDistance(_, element)
    element:setTexts(g_settingsModel:getTerrainLODDistanceTexts())
end
function InGameMenuSettingsFrame.onCreateFoliageLODDistance(_, element)
    element:setTexts(g_settingsModel:getFoliageLODDistanceTexts())
end
function InGameMenuSettingsFrame.onCreateVolumeMeshTessellation(_, element)
    element:setTexts(g_settingsModel:getVolumeMeshTessalationTexts())
end
function InGameMenuSettingsFrame.onCreateMaxTireTracks(_, element)
    element:setTexts(g_settingsModel:getMaxTireTracksTexts())
end
function InGameMenuSettingsFrame.onCreateMaxMirrors(_, element)
    element:setTexts(g_settingsModel:getMaxMirrorsTexts())
end
function InGameMenuSettingsFrame.onCreateResolutionScale3d(_, element)
    element:setTexts(g_settingsModel:getResolutionScale3dTexts())
end
function InGameMenuSettingsFrame.onCreateFovY(_, element)
    element:setTexts(g_settingsModel:getFovYTexts())
end
function InGameMenuSettingsFrame.onCreateFovYPlayerFirstPerson(_, element)
    element:setTexts(g_settingsModel:getFovYTexts())
end
function InGameMenuSettingsFrame.onCreateFovYPlayerThirdPerson(_, element)
    element:setTexts(g_settingsModel:getFovYTexts())
end
function InGameMenuSettingsFrame.onCreateFrameGenerationTooltip(_, element)
    if getFidelityFxSuperResolutionVersion() == 4 then
        element:setText(g_i18n:getText("toolTip_frameGenerationDisabledFSR4"))
    end
end
function InGameMenuSettingsFrame:onClickGameSettings()
    self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.GAME_SETTINGS, true)
end
function InGameMenuSettingsFrame:onClickGeneralSettings()
    self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.GENERAL_SETTINGS, true)
end
function InGameMenuSettingsFrame:onClickGraphicSettingss()
    self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS, true)
end
function InGameMenuSettingsFrame:onClickServerSettings()
    self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS, true)
end
function InGameMenuSettingsFrame:onClickControls()
    self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS, true)
end
function InGameMenuSettingsFrame:onClickDeadzoneSettings()
    self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE, true)
end
function InGameMenuSettingsFrame:onClickPreviousSubCategory()
    self.subCategoryPaging:onLeftButtonClicked()
end
function InGameMenuSettingsFrame:onClickNextSubCategory()
    self.subCategoryPaging:onRightButtonClicked()
end
function InGameMenuSettingsFrame:updateSubCategoryPages(state)
    local subCategoryIndex = self.subCategoryPaging.texts[state]
    if subCategoryIndex == nil then
        return
    else
        local makeSubCategoryUpdateCallback = tonumber(subCategoryIndex)
        if self:requestClose(makeSubCategoryUpdateCallback == InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS and function()
            -- upvalues: (copy) self, (copy) state
            self:assignDeviceTableData()
            self:updateSubCategoryPages(state)
        end or function()
            -- upvalues: (copy) self, (copy) state
            self:updateSubCategoryPages(state)
        end) then
            for index, page in pairs(self.subCategoryPages) do
                page:setVisible(index == makeSubCategoryUpdateCallback)
            end
            self.subCategoryPaging.shouldFocusChange = self.subCategoryPagingFocusChangeFunc
            self.categoryHeaderIcon:setImageSlice(nil, InGameMenuSettingsFrame.HEADER_SLICES[makeSubCategoryUpdateCallback])
            self.categoryHeaderText:setText(g_i18n:getText(InGameMenuSettingsFrame.HEADER_TITLES[makeSubCategoryUpdateCallback]))
            if self.menuAcceptUpEventId ~= nil then
                g_inputBinding:removeActionEvent(self.menuAcceptUpEventId)
            end
            if self.menuUpDownEvent ~= nil then
                g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_LEFT_RIGHT, true)
                g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_UP_DOWN, true)
                g_inputBinding:removeActionEvent(self.menuUpDownEvent)
                g_inputBinding:removeActionEvent(self.menuLeftRightEvent)
            end
            if makeSubCategoryUpdateCallback == InGameMenuSettingsFrame.SUB_CATEGORY.GAME_SETTINGS then
                self.settingsSlider:setDataElement(self.gameSettingsLayout)
                FocusManager:linkElements(self.subCategoryPaging, FocusManager.TOP, self.gameSettingsLayout.elements[#self.gameSettingsLayout.elements].elements[1])
                FocusManager:linkElements(self.subCategoryPaging, FocusManager.BOTTOM, self.gameSettingsLayout:findFirstFocusable(true))
            elseif makeSubCategoryUpdateCallback == InGameMenuSettingsFrame.SUB_CATEGORY.GENERAL_SETTINGS then
                self.settingsSlider:setDataElement(self.generalSettingsLayout)
                FocusManager:linkElements(self.subCategoryPaging, FocusManager.TOP, self.generalSettingsLayout.elements[#self.generalSettingsLayout.elements].elements[1])
                FocusManager:linkElements(self.subCategoryPaging, FocusManager.BOTTOM, self.generalSettingsLayout:findFirstFocusable(true))
            elseif makeSubCategoryUpdateCallback == InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS then
                local layout = Platform.isConsole and self.graphicSettingsLayoutConsole or self.graphicSettingsLayout
                self.settingsSlider:setDataElement(layout)
                FocusManager:linkElements(self.subCategoryPaging, FocusManager.TOP, layout.elements[#layout.elements].elements[1])
                FocusManager:linkElements(self.subCategoryPaging, FocusManager.BOTTOM, layout:findFirstFocusable(true))
            elseif makeSubCategoryUpdateCallback == InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS then
                self.settingsSlider:setDataElement(self.serverSettingsLayout)
                FocusManager:linkElements(self.subCategoryPaging, FocusManager.TOP, self.serverSettingsLayout.elements[#self.serverSettingsLayout.elements].elements[1])
                FocusManager:linkElements(self.subCategoryPaging, FocusManager.BOTTOM, self.serverSettingsLayout:findFirstFocusable(true))
            elseif makeSubCategoryUpdateCallback == InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS then
                layout, self.menuAcceptUpEventId = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onMenuAcceptUp, true, false, false, true)
                self.settingsSlider:setDataElement(self.controlsList)
                self.controlsList:makeCellVisible(1, 1)
                function self.subCategoryPaging.shouldFocusChange(_, direction)
                    -- upvalues: (copy) self
                    if direction == FocusManager.TOP then
                        local newSection = #self.controlsList.sections
                        local newIndex = self.controlsList.sections[newSection].numItems
                        self.controlsList:makeCellVisible(newSection, newIndex)
                        self.nextFocusSection = newSection
                        self.nextFocusCell = newIndex
                        self.nextFocusedButtonName = "actionButton1"
                        return false
                    end
                    if direction ~= FocusManager.BOTTOM then
                        return self.subCategoryPagingFocusChangeFunc(direction)
                    end
                    local newSection = 1
                    local newIndex = 1
                    self.controlsList:makeCellVisible(newSection, newIndex)
                    self.nextFocusSection = newSection
                    self.nextFocusCell = newIndex
                    self.nextFocusedButtonName = "actionButton1"
                    return false
                end
            elseif makeSubCategoryUpdateCallback == InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE then
                g_settingsModel:initDeviceSettings()
                g_settingsModel:refresh()
                self:updateDeadzoneView()
                g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_LEFT_RIGHT, false)
                g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_UP_DOWN, false)
                layout, self.menuUpDownEvent = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onAxisUpDown, false, true, false, true)
                layout, self.menuLeftRightEvent = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onAxisLeftRight, true, true, true, true)
                self.settingsSlider:setDataElement(self.deadzoneLayout)
            end
            self:updateButtons()
            FocusManager:setFocus(self.subCategoryPaging)
        end
    end
end
function InGameMenuSettingsFrame:onClickNativeHelp()
    openNativeHelpMenu()
end
function InGameMenuSettingsFrame:onClick(state, element)
    g_settingsModel:setValue(self.graphicSettingElements[element].settingsKey, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickPerformanceClass(state)
    g_settingsModel:applyPerformanceClass(state)
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickResolution(state)
    g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION, state - 1)
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickBrightness(state)
    g_settingsModel:setValue(SettingsModel.SETTING.BRIGHTNESS, state)
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickFullscreenMode(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FULLSCREEN_MODE, state - 1)
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickVSync(_)
    g_settingsModel:setValue(SettingsModel.SETTING.V_SYNC, self.vSyncElement:getIsChecked())
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickFrameLimit(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FRAME_LIMIT, state)
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickUIScale(state)
    g_settingsModel:setValue(SettingsModel.SETTING.UI_SCALE, state)
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickResolutionScale(state)
    g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION_SCALE, state)
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickPPAA(state, element)
    g_settingsModel:setValue(self.graphicSettingElements[element].settingsKey, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickScalingMode(state)
    local foundSetting = nil
    local settingName = g_settingsModel:getScalingModeTexts()[state]
    for name, index in pairs(self.scalingModeNameToIndexMapping) do
        if name == settingName then
            foundSetting = InGameMenuSettingsFrame.SCALING_MODES[index]
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
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickScalingModeQuality(state)
    local foundSetting = nil
    local settingName = g_settingsModel:getScalingModeTexts()[self.scalingModeElement:getState()]
    for name, index in pairs(self.scalingModeNameToIndexMapping) do
        if name == settingName then
            foundSetting = InGameMenuSettingsFrame.SCALING_MODES[index]
            break
        end
    end
    g_settingsModel:setValue(foundSetting.name, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickFrameGeneration(_)
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
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickDRSTargetFPS(state)
    g_settingsModel:setValue(SettingsModel.SETTING.DRS_TARGET_FPS, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickSharpness(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHARPNESS, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickShadingRateQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHADING_RATE_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickTextureResolution(state)
    g_settingsModel:setValue(SettingsModel.SETTING.TEXTURE_RESOLUTION, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickShadowQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickShadowDistanceQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_DISTANCE_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickSoftShadows(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SOFT_SHADOWS, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickShaderQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHADER_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickShadowMapFiltering(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_MAP_FILTERING, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickShadowMaxLights(state)
    g_settingsModel:setValue(SettingsModel.SETTING.MAX_LIGHTS, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickTerrainQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.TERRAIN_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickObjectDrawDistance(state)
    g_settingsModel:setValue(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickFoliageDrawDistance(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickLODDistance(state)
    g_settingsModel:setValue(SettingsModel.SETTING.LOD_DISTANCE, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickTerrainLODDistance(state)
    g_settingsModel:setValue(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickFoliageLODDistance(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_LOD_DISTANCE, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickVolumeMeshTessellation(state)
    g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickMaxTireTracks(state)
    g_settingsModel:setValue(SettingsModel.SETTING.MAX_TIRE_TRACKS, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickLightsProfile(state)
    g_settingsModel:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, state + 1)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickRealBeaconLights(_)
    g_settingsModel:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, self.realBeaconLightsElement:getIsChecked())
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickRealBeaconLightsConsole(_)
    g_settingsModel:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, self.realBeaconLightsElementConsole:getIsChecked())
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickFoliageShadows(_)
    g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_SHADOW, self.foliageShadowsElement:getIsChecked())
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickMaxMirrors(state)
    g_settingsModel:setValue(SettingsModel.SETTING.MAX_MIRRORS, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickSSAOQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.SSAO_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickAtmosphereQuality(state)
    g_settingsModel:setValue(SettingsModel.SETTING.ATMOSPHERE_QUALITY, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickCloudShadowsQuality(_)
    g_settingsModel:setValue(SettingsModel.SETTING.CLOUD_SHADOWS_QUALITY, self.cloudShadowsQualityElement:getIsChecked())
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickResolutionScale3d(state)
    g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickFovY(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickFovYPlayerFirstPerson(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickFovYPlayerThirdPerson(state)
    g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON, state)
    g_settingsModel:applyCustomSettings()
    self:updateGraphicSettings()
end
function InGameMenuSettingsFrame:onClickLockedIcon() end
function InGameMenuSettingsFrame:onFocusLockedIcon(icon)
    self.graphicSettingsLayout:scrollToMakeElementVisible(icon)
end
function InGameMenuSettingsFrame:onApplyDeadzoneChanges()
    g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
    self:updateButtons()
end
function InGameMenuSettingsFrame:onSwitchDevice()
    g_settingsModel:nextDevice()
    self:updateDeadzoneView()
end
function InGameMenuSettingsFrame:updateGamepadInputStates()
    for _, barInfo in pairs(self.stateBars) do
        local deadzone = g_settingsModel:getCurrentDeviceDeadzoneValue(barInfo.axisIndex)
        local sensitivity = g_settingsModel:getCurrentDeviceSensitivityValue(barInfo.axisIndex)
        local value = g_inputBinding:getGamepadAxisValue(g_settingsModel.deviceSettings[g_settingsModel.currentDevice].device.internalId, barInfo.axisIndex, "", 0, deadzone) * sensitivity
        local bar = math.clamp(value, -1, 1)
        local bar = barInfo.element.elements[1]
        local boxSize = barInfo.element.absSize[1]
        bar:setSize((math.max(math.abs(bar) * boxSize * 0.5, 2 * g_pixelSizeX)))
        if bar < 0 then
            bar:setPosition((1 - math.abs(bar)) * boxSize * 0.5)
        else
            bar:setPosition(boxSize * 0.5)
        end
        barInfo.element:updateAbsolutePosition()
    end
end
function InGameMenuSettingsFrame.onAxisUpDown(_, _, value)
    g_gui:notifyControls(InputAction.MENU_AXIS_UP_DOWN, value)
end
function InGameMenuSettingsFrame.onAxisLeftRight(_, _, value)
    g_gui:notifyControls(InputAction.MENU_AXIS_LEFT_RIGHT, value)
end
function InGameMenuSettingsFrame:updateController()
    self.numOfGamepads = getNumOfGamepads()
    g_settingsModel:initDeviceSettings()
    self:updateDeadzoneView()
    self:updateButtons()
end
function InGameMenuSettingsFrame:updateDeadzoneView()
    local name = g_settingsModel:getCurrentDeviceName()
    if name == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
        name = g_i18n:getText("ui_mouse")
    elseif g_i18n:hasText(name) then
        name = g_i18n:getText(name)
    end
    self.deadzoneTitleElement:setText(string.format("%s: %s", g_i18n:getText("ui_deviceConfiguration"), name))
    local i = #self.deadzoneLayout.elements
    local isMouse = 1
    local sensitivityTemplate = -1
    for i = i, isMouse, sensitivityTemplate do
        self.deadzoneLayout.elements[i]:delete()
        self.deadzoneLayout.elements[i] = nil
    end
    self.stateBars = {}
    local isMouse = g_settingsModel:getIsDeviceMouse()
    local i
    if isMouse then
        (function(title, axis)
            -- upvalues: (copy) self
            local cell = self.sectionTemplate:clone(self.deadzoneLayout)
            cell:getDescendantByName("title"):setText(title)
            local box = cell:getDescendantByName("box")
            box:setVisible(axis ~= nil)
            if axis ~= nil then
                table.insert(self.stateBars, {
                    ["element"] = box,
                    ["axisIndex"] = axis
                })
            end
        end)(g_i18n:getText("ui_mouse"))
        i = self.sensitivityTemplate:clone(self.deadzoneLayout).elements[1]
        i:setTexts(g_settingsModel:getSensitivityTexts())
        i:setState(g_settingsModel:getMouseSensitivityValue())
        function i.onClickCallback(_, state)
            -- upvalues: (copy) self
            g_settingsModel:setMouseSensitivity(state)
            self:updateButtons()
        end
        if nil ~= nil then
            i = firstOptionElement
        end
    else
        i = firstOptionElement
    end
    local sensitivityTemplate = g_gameSettings:getValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED)
    if sensitivityTemplate then
        sensitivityTemplate = isHeadTrackingAvailable()
    end
    local i = getIsKeyboardAvailable()
    if sensitivityTemplate then
        sensitivityTemplate = isMouse or not i
    end
    local optionElement
    if sensitivityTemplate then
        addSectionHeader(g_i18n:getText("setting_headTracking"))
        optionElement = self.sensitivityTemplate:clone(self.deadzoneLayout).elements[1]
        optionElement:setTexts(g_settingsModel:getHeadTrackingSensitivityTexts())
        optionElement:setState(g_settingsModel:getHeadTrackingSensitivityValue())
        function optionElement.onClickCallback(_, state)
            -- upvalues: (copy) self
            g_settingsModel:setHeadTrackingSensitivity(state)
            self:updateButtons()
        end
        if i ~= nil then
            optionElement = i
        end
    else
        optionElement = i
    end
    if not isMouse then
        local optionElement = g_settingsModel.deviceSettings[g_settingsModel.currentDevice].device.internalId
        local axis = 0
        for axis = axis, Input.MAX_NUM_AXES - 1 do
            local hasDeadzone = g_settingsModel:getDeviceHasAxisDeadzone(axis)
            local hasSensitiviy = g_settingsModel:getDeviceHasAxisSensitivity(axis)
            if hasDeadzone or hasSensitiviy then
                local label = getGamepadAxisLabel(axis, optionElement)
                local title = string.format(g_i18n:getText("setting_gamepadAxis"), axis + 1)
                if label ~= "" then
                end
                addSectionHeader(title, axis)
                local optionElement
                if hasDeadzone then
                    optionElement = self.deadzoneTemplate:clone(self.deadzoneLayout).elements[1]
                    optionElement:setTexts(g_settingsModel:getDeadzoneTexts())
                    optionElement:setState(g_settingsModel:getDeviceAxisDeadzoneValue(axis))
                    function optionElement.onClickCallback(_, state)
                        -- upvalues: (copy) axis, (copy) self
                        g_settingsModel:setDeviceDeadzoneValue(axis, state)
                        self:updateButtons()
                    end
                    if optionElement ~= nil then
                    end
                end
                if hasSensitiviy then
                    optionElement = self.sensitivityTemplate:clone(self.deadzoneLayout).elements[1]
                    optionElement:setTexts(g_settingsModel:getSensitivityTexts())
                    optionElement:setState(g_settingsModel:getDeviceAxisSensitivityValue(axis))
                    function optionElement.onClickCallback(_, state)
                        -- upvalues: (copy) axis, (copy) self
                        g_settingsModel:setDeviceSensitivityValue(axis, state)
                        self:updateButtons()
                    end
                    if optionElement ~= nil then
                    end
                end
            end
        end
    end
    self.deadzoneLayout:scrollTo(0, true)
    local sensitivityTemplate = true
    for axis, hasDeadzone in pairs(self.deadzoneLayout.elements) do
        if hasDeadzone.name == "sectionHeader" then
            sensitivityTemplate = true
        elseif hasDeadzone:getIsVisible() then
            hasDeadzone:setImageColor(nil, unpack(SettingsScreen.COLOR_ALTERNATING[sensitivityTemplate]))
            sensitivityTemplate = not sensitivityTemplate
        end
    end
    self.deadzoneLayout:invalidateLayout()
    if optionElement ~= nil then
        self.deadzoneLayout:scrollToMakeElementVisible(optionElement)
        FocusManager:setFocus(optionElement)
        FocusManager:linkElements(self.subCategoryPaging, FocusManager.TOP, self.deadzoneLayout:findLastFocusable(true))
        FocusManager:linkElements(self.subCategoryPaging, FocusManager.BOTTOM, self.deadzoneLayout:findFirstFocusable(true))
        optionElement.forceFocusScrollToTop = true
    end
end
function InGameMenuSettingsFrame:getNumberOfSections(_)
    return #self.controlsData
end
function InGameMenuSettingsFrame:getTitleForSectionHeader(_, section)
    return g_i18n:convertText(self.controlsData[section].name)
end
function InGameMenuSettingsFrame:getNumberOfItemsInSection(_, section)
    return #self.controlsData[section]
end
function InGameMenuSettingsFrame:populateCellForItemInSection(list, section, index, cell)
    local actionBinding = self.controlsData[section][index]
    cell:getAttribute("actionName"):setText(actionBinding.displayName)
    local i = 1
    for i = i, 3 do
        local dataIndex = i + self.dataRowOffset
        local binding = nil
        if dataIndex - 3 > 0 then
            for id, columnBinding in pairs(actionBinding.columnBindings) do
                if columnBinding.deviceId == self.gamepads[dataIndex - 3].deviceId then
                    binding = columnBinding
                    dataIndex = id
                    break
                end
            end
        else
            binding = actionBinding.columnBindings[dataIndex]
        end
        local deviceId = cell:getAttribute("actionGlyph" .. i)
        local button = cell:getAttribute("actionButton" .. i)
        deviceId:setActions({ actionBinding.action.name }, nil, nil, nil, binding)
        local hasIcon = false
        if deviceId.glyphElement ~= nil then
            for _, keyName in pairs(deviceId.glyphElement.actionNames) do
                if deviceId.glyphElement.keyNames[keyName] ~= nil and deviceId.glyphElement.keyNames[keyName][1] ~= "" then
                    hasIcon = true
                end
            end
        end
        local columnBinding
        if binding == nil then
            columnBinding = false
        else
            columnBinding = hasIcon
        end
        deviceId:setVisible(columnBinding)
        if hasIcon then
            button:setText("")
        else
            button:setText(actionBinding.columnTexts[dataIndex])
        end
        local oldFocusEnterFunc = deviceId.onFocusEnter
        function deviceId.onFocusEnter()
            -- upvalues: (copy) oldFocusEnterFunc, (copy) deviceId
            oldFocusEnterFunc(deviceId)
            deviceId.glyphElement:setButtonGlyphColor(SettingsControlsFrame.COLOR.BLACK)
        end
        local id = deviceId.onFocusLeave
        function deviceId.onFocusLeave(element)
            -- upvalues: (copy) id, (copy) deviceId
            id(deviceId)
            if deviceId.glyphElement ~= nil then
                deviceId.glyphElement:setButtonGlyphColor(SettingsControlsFrame.COLOR.GREEN)
            end
        end
        local columnBinding = button.onFocusEnter
        function button.onFocusEnter()
            -- upvalues: (copy) columnBinding, (copy) button, (copy) list, (copy) cell, (copy) self, (copy) i
            columnBinding(button)
            list:makeCellVisible(cell.sectionIndex, cell.indexInSection)
            self.currentFocusCell = cell
            self.currentFocusSection = cell.sectionIndex
            self.currentFocusIndex = cell.indexInSection
            self["headerText" .. 1]:setSelected(i == 1)
            self["headerText" .. 2]:setSelected(i == 2)
            self["headerText" .. 3]:setSelected(i == 3)
        end
        local dataIndex
        function button.shouldFocusChange(_, direction)
            -- upvalues: (copy) cell, (copy) self, (copy) dataIndex, (copy) list, (copy) i
            if g_gui:getIsDialogVisible() then
                return false
            end
            local section = cell.sectionIndex
            local index = cell.indexInSection
            if section == nil then
                section = self.currentFocusSection
                index = self.currentFocusIndex
            end
            if direction == FocusManager.LEFT then
                if dataIndex == 1 then
                    return false
                end
                if dataIndex == 1 + self.dataRowOffset then
                    self.dataRowOffset = self.dataRowOffset - 1
                    self.controlsList:reloadData()
                    self:updateListHeaderNames()
                    return false
                end
            elseif direction == FocusManager.RIGHT then
                if dataIndex == self.numTotalDevices then
                    return false
                end
                if dataIndex == 3 + self.dataRowOffset then
                    self.dataRowOffset = self.dataRowOffset + 1
                    self.controlsList:reloadData()
                    self:updateListHeaderNames()
                    return false
                end
            else
                if direction == FocusManager.TOP then
                    local newIndex = index - 1
                    if newIndex == 0 then
                        section = section - 1
                        if section == 0 then
                            FocusManager:setFocus(self.subCategoryPaging)
                            return false
                        end
                        newIndex = list.sections[section].numItems
                    end
                    list:makeCellVisible(section, newIndex)
                    self.nextFocusSection = section
                    self.nextFocusCell = newIndex
                    self.nextFocusedButtonName = "actionButton" .. i
                    return false
                end
                if direction == FocusManager.BOTTOM then
                    local newIndex = index + 1
                    if list.sections[section].numItems < newIndex then
                        section = section + 1
                        if #list.sections < section then
                            FocusManager:setFocus(self.subCategoryPaging)
                            return false
                        end
                        newIndex = 1
                    end
                    list:makeCellVisible(section, newIndex)
                    self.nextFocusSection = section
                    self.nextFocusCell = newIndex
                    self.nextFocusedButtonName = "actionButton" .. i
                    return false
                end
            end
            return true
        end
    end
    cell.actionBinding = actionBinding
end
function InGameMenuSettingsFrame:inputEvent(action, _, eventUsed)
    if action ~= InputAction.MENU_ACCEPT then
        return eventUsed
    end
    return FocusManager:getFocusedElement() ~= self.buttonPauseGame
end
function InGameMenuSettingsFrame:onMenuAcceptUp(_, _, _)
    if self.currentFocusCell == nil then
        return false
    end
    local focusedButton = FocusManager:getFocusedElement()
    local bindingControlsRowIndex = (focusedButton.name == "actionButton2" and 2 or (focusedButton.name == "actionButton3" and 3 or 1)) + self.dataRowOffset
    local deviceInfoIndex = math.min(bindingControlsRowIndex, 4)
    self:onInputClicked(InGameMenuSettingsFrame.DEVICES[deviceInfoIndex].category, InGameMenuSettingsFrame.DEVICES[deviceInfoIndex].binding, self.currentFocusCell.actionBinding, bindingControlsRowIndex)
    return true
end
function InGameMenuSettingsFrame:onInputClicked(deviceCategory, bindingId, actionData, bindingControlsRowIndex)
    if self.controlsController:onClickInput(deviceCategory, bindingId, actionData, bindingControlsRowIndex) then
        self:showInputPrompt(deviceCategory, bindingId, actionData)
    end
end
function InGameMenuSettingsFrame:onClickDefaults()
    YesNoDialog.show(function(dialogAccepted)
        -- upvalues: (copy) self
        if dialogAccepted then
            self.controlsController:loadDefaultSettings()
            self.userChangedInput = false
            self:assignDeviceTableData()
            self:updateButtons()
            InfoDialog.show(g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.DEFAULTS_LOADED), function(target)
                target.controlsList:makeCellVisible(1, 1)
                target.nextFocusSection = 1
                target.nextFocusCell = 1
                target.nextFocusedButtonName = "actionButton1"
            end, self, DialogElement.TYPE_INFO)
        end
    end, nil, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.LOAD_DEFAULTS), g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_RESET))
end
function InGameMenuSettingsFrame:onControllerChanged()
    self.dataRowOffset = 0
    self.numTotalDevices = 3 + g_inputBinding.numActiveGamepads
    self.controlsList:makeCellVisible(1, 1, true)
    self.nextFocusSection = 1
    self.nextFocusCell = 1
    self.nextFocusedButtonName = "actionButton1"
    self:assignDeviceTableData()
    self.controlsMessageText = ""
    self:updateButtons()
end
function InGameMenuSettingsFrame:onClickNextRow()
    self.dataRowOffset = self.dataRowOffset + 1
    self.controlsList:reloadData()
    self:updateListHeaderNames()
end
function InGameMenuSettingsFrame:onClickPrevRow()
    self.dataRowOffset = self.dataRowOffset - 1
    self.controlsList:reloadData()
    self:updateListHeaderNames()
end
InGameMenuSettingsFrame.PROFILE = {
    ["BUTTON_PAUSE"] = "fs25_settingsPauseButton",
    ["BUTTON_UNPAUSE"] = "fs25_settingsUnpauseButton"
}
InGameMenuSettingsFrame.L10N_SYMBOL = {
    ["DIRT_TEMPLATE"] = "setting_dirtState",
    ["OFF"] = "ui_off",
    ["BUY"] = "ui_buy",
    ["USAGE_LOW"] = "setting_fuelUsageLow",
    ["USAGE_DEFAULT"] = "setting_fuelUsageDefault",
    ["USAGE_HIGH"] = "setting_fuelUsageHigh",
    ["PAUSE"] = "input_PAUSE",
    ["UNPAUSE"] = "ui_unpause",
    ["DIFFICULTY_EASY"] = "button_easy",
    ["DIFFICULTY_NORMAL"] = "button_normal",
    ["DIFFICULTY_HARD"] = "button_hard",
    ["SUBSTITUTION_PREFIX"] = "$l10n_",
    ["BUTTON_SAVE_CONTROLS"] = "button_saveControls",
    ["BUTTON_SAVE"] = "ui_saveSettings",
    ["BUTTON_DEFAULTS"] = "button_defaults",
    ["BUTTON_KEYBOARD"] = "ui_keyboard",
    ["BUTTON_GAMEPAD"] = "ui_gamepad",
    ["SAVE_CHANGES_PROMPT"] = "ui_saveChanges",
    ["SAVED_CHANGES_INFO"] = "ui_savingFinished",
    ["LOAD_DEFAULTS"] = "ui_loadDefaultSettings",
    ["DEFAULTS_LOADED"] = "ui_loadedDefaultSettings",
    ["KEY_PROMPT"] = "ui_pressKeyToMap",
    ["MOUSE_PROMPT"] = "ui_pressMouseButtonToMap",
    ["BUTTON_PROMPT"] = "ui_pressGamepadButtonToMap",
    ["BUTTON_RESET"] = "button_reset",
    ["BUTTON_APPLY"] = "button_apply",
    ["SWITCH_DEVICE"] = "ui_switchDevice",
    ["SAVING_FINISHED"] = "ui_savingFinished"
}
InGameMenuSettingsFrame.HEADER_SLICES = {
    [InGameMenuSettingsFrame.SUB_CATEGORY.GAME_SETTINGS] = "gui.icon_options_gameSettings2",
    [InGameMenuSettingsFrame.SUB_CATEGORY.GENERAL_SETTINGS] = "gui.icon_options_generalSettings2",
    [InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS] = "gui.icon_options_displaySettings",
    [InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS] = "gui.icon_options_serverSettings",
    [InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS] = "gui.icon_options_keyboardControls",
    [InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE] = "gui.icon_options_device"
}
InGameMenuSettingsFrame.HEADER_TITLES = {
    [InGameMenuSettingsFrame.SUB_CATEGORY.GAME_SETTINGS] = "ui_ingameMenuGameSettingsGame",
    [InGameMenuSettingsFrame.SUB_CATEGORY.GENERAL_SETTINGS] = "ui_ingameMenuGameSettingsGeneral",
    [InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS] = "ui_inGameMenuGraphicSettings",
    [InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS] = "button_serverSettings",
    [InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS] = "ui_inGameMenuControls",
    [InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE] = "ui_inGameMenuDevices"
}
InGameMenuSettingsFrame.COLOR_ALTERNATING = {
    [true] = {
        0.02956,
        0.02956,
        0.02956,
        0.6
    },
    [false] = {
        0.02956,
        0.02956,
        0.02956,
        0.2
    }
}
InGameMenuSettingsFrame.CONTROLS_UI_STRINGS = {
    [ControlsController.MESSAGE_CANNOT_MAP_KEY] = "ui_cannotMapKeyHere",
    [ControlsController.MESSAGE_CANNOT_MAP_MOUSE] = "ui_cannotMapMouseHere",
    [ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER] = "ui_cannotMapGamepadHere",
    [ControlsController.MESSAGE_PROMPT_KEY] = "ui_pressKeyToMap",
    [ControlsController.MESSAGE_PROMPT_MOUSE] = "ui_pressMouseButtonToMap",
    [ControlsController.MESSAGE_PROMPT_CONTROLLER] = "ui_pressGamepadButtonToMap",
    [ControlsController.MESSAGE_PROMPT_CANCEL_DELETE] = "ui_pressESCToCancel",
    [ControlsController.MESSAGE_ENSURE_IN_NEUTRAL] = "ui_ensureAxisToMapInNeutral",
    [ControlsController.MESSAGE_SELECT_ACTION] = "ui_selectActionToRemap",
    [ControlsController.MESSAGE_CONFLICT_KEY] = "ui_keyAlreadyMapped",
    [ControlsController.MESSAGE_CONFLICT_MOUSE] = "ui_buttonAlreadyMapped",
    [ControlsController.MESSAGE_CONFLICT_BUTTON] = "ui_buttonAlreadyMapped",
    [ControlsController.MESSAGE_CONFLICT_AXIS] = "ui_axisAlreadyMapped",
    [ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY] = "ui_blockedKeyCombination"
}
InGameMenuSettingsFrame.CONFLICT_MESSAGES = {
    [ControlsController.MESSAGE_CANNOT_MAP_KEY] = true,
    [ControlsController.MESSAGE_CANNOT_MAP_MOUSE] = true,
    [ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER] = true,
    [ControlsController.MESSAGE_CONFLICT_KEY] = true,
    [ControlsController.MESSAGE_CONFLICT_MOUSE] = true,
    [ControlsController.MESSAGE_CONFLICT_BUTTON] = true,
    [ControlsController.MESSAGE_CONFLICT_AXIS] = true,
    [ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY] = true
}
InGameMenuSettingsFrame.L10N_TEMPLATE_SYMBOL = {
    [ControlsController.MESSAGE_REMAPPED] = "ui_actionRemapped"
}
InGameMenuSettingsFrame.COLOR = {
    ["BLACK"] = {
        0.00439,
        0.00478,
        0.00368,
        1
    },
    ["GREEN"] = {
        0.22323,
        0.40724,
        0.00368,
        1
    }
}
InGameMenuSettingsFrame.DEVICES = {
    {
        ["name"] = "ui_key1",
        ["category"] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
        ["binding"] = ControlsController.BINDING_PRIMARY
    },
    {
        ["name"] = "ui_key2",
        ["category"] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
        ["binding"] = ControlsController.BINDING_SECONDARY
    },
    {
        ["name"] = "ui_mouse",
        ["category"] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
        ["binding"] = ControlsController.BINDING_TERTIARY
    },
    {
        ["category"] = InputDevice.CATEGORY.GAMEPAD,
        ["binding"] = ControlsController.BINDING_PRIMARY
    }
}
local fsr34LocaKey = getFidelityFxSuperResolutionVersion() == 4 and "setting_fsr4" or "setting_fsr3"
InGameMenuSettingsFrame.SCALING_MODES = {
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