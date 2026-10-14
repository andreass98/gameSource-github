AISettingsDialog = {}
AISettingsDialog.LINE_COLORS = {}
AISettingsDialog.LINE_COLORS.BOUNDARY = {
    0.0273,
    0.0612,
    0.3324,
    1
}
AISettingsDialog.LINE_COLORS.HEADLAND = {
    0.2122,
    0.5029,
    0.402,
    1
}
AISettingsDialog.LINE_COLORS.STRAIGHT = {
    0.402,
    0.2051,
    0.0144,
    1
}
local AISettingsDialog_mt = Class(AISettingsDialog, MessageDialog)
function AISettingsDialog.register()
    local aiSettingsDialog = AISettingsDialog.new()
    g_gui:loadGui("dataS/gui/dialogs/AISettingsDialog.xml", "AISettingsDialog", aiSettingsDialog)
    AISettingsDialog.INSTANCE = aiSettingsDialog
end
function AISettingsDialog.show(aiUserSettings, fieldCourseSettings, vehicle, selectedMode, fieldX, fieldZ, callback, target)
    if AISettingsDialog.INSTANCE ~= nil then
        local dialog = AISettingsDialog.INSTANCE
        dialog:setCallback(callback, target)
        dialog.aiUserSettings = aiUserSettings
        dialog.fieldCourseSettings = fieldCourseSettings
        dialog.vehicle = vehicle
        dialog.selectedMode = selectedMode
        dialog.fieldX = fieldX
        dialog.fieldZ = fieldZ
        g_gui:showDialog("AISettingsDialog")
    end
end
function AISettingsDialog.new(target, custom_mt)
    -- upvalues: (copy) AISettingsDialog_mt
    local self = MessageDialog.new(target, custom_mt or AISettingsDialog_mt)
    self.ingameMapElement = nil
    self.selectedMode = 0
    self.fieldCourseUpdateTimer = 0
    self.lineWidth = 1 / g_screenHeight
    self.elementToSettingMapping = {}
    return self
end
function AISettingsDialog.createFromExistingGui(gui, _)
    AISettingsDialog.register()
    AISettingsDialog.show(gui.aiUserSettings)
end
function AISettingsDialog:onGuiSetupFinished()
    AISettingsDialog:superClass().onGuiSetupFinished(self)
    self.templateBinarySetting:unlinkElement()
    self.templateMTOSetting:unlinkElement()
    self.templateSliderSetting:unlinkElement()
    FocusManager:removeElement(self.templateBinarySetting)
    FocusManager:removeElement(self.templateMTOSetting)
    FocusManager:removeElement(self.templateSliderSetting)
    self.modeElement:setTexts({ g_i18n:getText("ai_modeWorker"), g_i18n:getText("ai_modeSteeringAssist") })
end
function AISettingsDialog:setCallback(callbackFunc, target)
    self.callbackFunc = callbackFunc
    self.target = target
end
function AISettingsDialog:sendCallback()
    self.aiUserSettings:apply(self.fieldCourseSettings, self.selectedMode)
    if self.callbackFunc ~= nil then
        if self.target == nil then
            self.callbackFunc(self.selectedMode, self.fieldCourseSettings)
        else
            self.callbackFunc(self.target, self.selectedMode, self.fieldCourseSettings)
        end
    end
    self:close()
end
function AISettingsDialog:delete()
    self.templateBinarySetting:delete()
    self.templateMTOSetting:delete()
    self.templateSliderSetting:delete()
    AISettingsDialog:superClass().delete(self)
end
function AISettingsDialog:update(dt)
    AISettingsDialog:superClass().update(self, dt)
    if self.fieldCourseUpdateTimer > 0 then
        self.fieldCourseUpdateTimer = self.fieldCourseUpdateTimer - dt
        if self.fieldCourseUpdateTimer <= 0 then
            self:updateFieldCourse()
        end
    end
end
function AISettingsDialog:onOpen()
    AISettingsDialog:superClass().onOpen(self)
    self.isOpening = true
    if self.vehicle:getIsAutomaticSteeringAllowed() then
        self.modeElement:setDisabled(false)
    else
        self.selectedMode = AIModeSelection.MODE.WORKER
        self.modeElement:setDisabled(true)
    end
    self.modeElement:setIsChecked(self.selectedMode == AIModeSelection.MODE.STEERING_ASSIST, true)
    self:assignSettingsOptions()
    self.ingameMapElement.drawHotspots = false
    self.ingameMapElement:setIngameMap(g_currentMission.hud:getIngameMap())
    self.ingameMapElement:onOpen()
    self:updateSettingsStates()
    self:updateFieldCourse()
    self.isOpening = false
end
function AISettingsDialog:onClose()
    AISettingsDialog:superClass().onClose(self)
    self.ingameMapElement:onClose()
    self.fieldCourse = nil
    self.aiUserSettings = nil
    self.fieldCourseSettings = nil
    self.vehicle = nil
    self.callbackFunc = nil
    self.target = nil
end
function AISettingsDialog:assignSettingsOptions()
    local i = #self.settingsBox.elements
    local settings = 1
    local firstOption = -1
    for i = i, settings, firstOption do
        self.settingsBox.elements[i]:delete()
        self.settingsBox.elements[i] = nil
    end
    self.elementToSettingMapping = {}
    if self.aiUserSettings == nil then
        return
    else
        local settings = self.aiUserSettings.settings[self.selectedMode]
        if settings ~= nil then
            local firstOption = nil
            local i = nil
            local isAlternate = true
            for index, settingData in pairs(settings) do
                local texts = settingData.value
                local isBinaryElement = type(texts) == "boolean"
                local option
                if isBinaryElement then
                    option = self.templateBinarySetting:clone(self.settingsBox)
                elseif settingData.useSlider then
                    option = self.templateSliderSetting:clone(self.settingsBox)
                else
                    option = self.templateMTOSetting:clone(self.settingsBox)
                end
                local value = AISettingsDialog.COLOR_ALTERNATING[isAlternate]
                option:setImageColor(nil, unpack(value))
                i = option:getDescendantByName("option")
                if settingData.step == nil then
                    if settingData.setting.valueTexts == nil then
                        if settingData.setting.texts ~= nil then
                            i:setTexts(settingData.setting.texts)
                        end
                    else
                        for value, roundedValue in pairs(settingData.setting.valueTexts) do
                            if string.endsWith(roundedValue, settingData.setting.defaultPostFix) then
                                settingData.setting.valueTexts[value] = string.sub(roundedValue, 1, -string.len(settingData.setting.defaultPostFix) - 2)
                            end
                        end
                        local texts = {}
                        if settingData.min == settingData.setting.min and settingData.max == settingData.setting.max then
                            local index2 = settingData.setting.valueToTextIndex[settingData.defaultValue]
                            if index2 ~= nil then
                                settingData.setting.valueTexts[index2] = settingData.setting.valueTexts[index2] .. " " .. settingData.setting.defaultPostFix
                            end
                        else
                            local value = settingData.min
                            for value = value, settingData.max do
                                local roundedValue = settingData.setting.valueTexts[settingData.setting.valueToTextIndex[value]]
                                if value == settingData.defaultValue then
                                end
                                table.insert(texts, roundedValue)
                            end
                        end
                        i:setTexts(texts)
                        if settingData.setting.inputDelay ~= nil then
                            i.baseScrollDelayDuration = settingData.setting.inputDelay
                        end
                    end
                else
                    local texts = {}
                    local value = settingData.min
                    for value = value, settingData.max + settingData.step, settingData.step do
                        local roundedValue, text
                        if settingData.step < 1 then
                            roundedValue = MathUtil.round(value, 1)
                            text = string.format("%.1f", roundedValue)
                        else
                            roundedValue = MathUtil.round(value, 0)
                            text = string.format("%d", roundedValue)
                        end
                        if settingData.setting.unitText ~= nil then
                        end
                        if settingData.setting.defaultPostFix ~= nil and (settingData.defaultValue ~= nil and roundedValue == MathUtil.round(settingData.defaultValue, 1)) then
                        end
                        table.insert(texts, text)
                    end
                    i:setTexts(texts)
                    if settingData.setting.inputDelay ~= nil then
                        i.baseScrollDelayDuration = settingData.setting.inputDelay
                    end
                end
                self.elementToSettingMapping[i] = settingData
                local texts = option:getDescendantByName("name")
                texts:setText(settingData.setting.title)
                function texts.getIsFocused()
                    -- upvalues: (copy) i
                    return i:getIsFocused()
                end
                isAlternate = not isAlternate
                if index == 1 then
                    firstOption = i
                end
            end
            self.settingsBox:invalidateLayout()
            FocusManager:linkElements(self.modeElement, FocusManager.BOTTOM, firstOption)
            FocusManager:linkElements(firstOption, FocusManager.TOP, self.modeElement)
            FocusManager:linkElements(self.modeElement, FocusManager.TOP, i)
            FocusManager:linkElements(i, FocusManager.BOTTOM, self.modeElement)
            self:updateSettingsValues()
        end
    end
end
function AISettingsDialog:updateFieldCourseSettings()
    if self.fieldX ~= nil and self.fieldZ ~= nil then
        self.aiUserSettings:apply(self.fieldCourseSettings, self.selectedMode)
    end
end
function AISettingsDialog:updateFieldCourse()
    if self.vehicle:getCanStartFieldWork() or self.selectedMode ~= AIModeSelection.MODE.WORKER then
        if self.fieldX ~= nil and self.fieldZ ~= nil then
            self:updateFieldCourseSettings()
            if not self.fieldCourseLoading then
                if self.fieldCourse == nil then
                    self.fieldCourseLoading = true
                    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                        self.fieldCourseSettings:print()
                    end
                    FieldCourse.generateUICourseByFieldPosition(self.fieldX, self.fieldZ, self.fieldCourseSettings, function(fieldCourse)
                        -- upvalues: (copy) self
                        self.fieldCourseLoading = false
                        if self.vehicle ~= nil then
                            if fieldCourse == nil then
                                self.fieldCourse = nil
                            else
                                self.fieldCourse = fieldCourse
                                self.aiUserSettings:adjustToCourse(fieldCourse, self.selectedMode)
                                self:updateSettingsValues()
                            end
                            self:updateSettingsStates()
                            self:updateMapState()
                        end
                    end)
                else
                    self.fieldCourseLoading = true
                    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                        self.fieldCourseSettings:print()
                    end
                    self.fieldCourse:updateFieldCourseSettings(self.fieldCourseSettings, function(success)
                        -- upvalues: (copy) self
                        self.fieldCourseLoading = false
                        if self.vehicle ~= nil then
                            if success then
                                if self.fieldCourse ~= nil then
                                    self.aiUserSettings:adjustToCourse(self.fieldCourse, self.selectedMode)
                                    self:updateSettingsValues()
                                end
                            else
                                self.fieldCourse = nil
                            end
                            self:updateSettingsStates()
                            self:updateMapState()
                        end
                    end)
                end
            end
        end
        self:updateMapState()
    else
        self.fieldCourse = nil
        self:updateMapState()
    end
end
function AISettingsDialog:updateSettingsStates()
    local isVineyardCourse = false
    if self.fieldCourse ~= nil then
        isVineyardCourse = self.fieldCourse.isVineyardCourse
    end
    local settingsAvailable
    if self.selectedMode == AIModeSelection.MODE.STEERING_ASSIST then
        settingsAvailable = self.vehicle:getIsAutomaticSteeringAllowed()
    else
        settingsAvailable = self.vehicle:getCanStartFieldWork()
    end
    if settingsAvailable then
        for option, settingsData in pairs(self.elementToSettingMapping) do
            option:setDisabled(isVineyardCourse and not settingsData.setting.isVineyardSetting or settingsData.setting:getIsDisabled(self.elementToSettingMapping))
        end
    else
        for option, settingsData in pairs(self.elementToSettingMapping) do
            option:setDisabled(settingsData.setting:getIsDisabled(self.elementToSettingMapping))
        end
    end
end
function AISettingsDialog:updateSettingsValues()
    for option, settingData in pairs(self.elementToSettingMapping) do
        local numTexts = settingData.value
        local isBinaryElement = type(numTexts) == "boolean"
        if settingData.step == nil then
            if settingData.setting.valueTexts == nil then
                if settingData.setting.texts == nil then
                    if isBinaryElement then
                        option:setIsChecked(settingData.value, self.isOpening)
                    end
                else
                    local selectedIndex = 1
                    for value, roundedValue in ipairs(settingData.setting.textMapping) do
                        if type(roundedValue) == "boolean" then
                            if roundedValue == settingData.value then
                                selectedIndex = value
                                break
                            end
                        elseif MathUtil.round(roundedValue, 2) == MathUtil.round(settingData.value, 2) then
                            selectedIndex = value
                            break
                        end
                    end
                    if isBinaryElement then
                        option:setIsChecked(selectedIndex == 2, self.isOpening)
                    else
                        option:setState(selectedIndex)
                    end
                end
            else
                local selectedIndex = 1
                local numTexts = 1
                if settingData.min == settingData.setting.min and settingData.max == settingData.setting.max then
                else
                    local value = settingData.min
                    for value = value, settingData.max do
                        if value == settingData.value then
                            selectedIndex = numTexts
                        end
                        numTexts = numTexts + 1
                    end
                end
                option:setState(selectedIndex)
            end
        else
            local selectedIndex = 1
            local numTexts = 0
            local value = settingData.min
            for value = value, settingData.max + settingData.step, settingData.step do
                local roundedValue
                if settingData.step < 1 then
                    roundedValue = MathUtil.round(value, 1)
                else
                    roundedValue = MathUtil.round(value, 0)
                end
                numTexts = numTexts + 1
                if roundedValue == MathUtil.round(settingData.value, 1) then
                    selectedIndex = numTexts
                end
            end
            option:setState(selectedIndex)
        end
    end
end
function AISettingsDialog:updateMapState()
    if self.fieldCourseLoading then
        self.ingameMapElement:setMapAlpha(1)
        if self.fieldCourse == nil then
            local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
            self.ingameMapElement:setCenterToWorldPosition(x, z)
            self.ingameMapElement:setMapZoom(10)
        end
        self.loadingAnimation:setVisible(true)
        self.noFieldFoundText:setVisible(false)
        self.fieldNotSupportedText:setVisible(false)
    elseif self.fieldCourse == nil then
        local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
        self.ingameMapElement:setCenterToWorldPosition(x, z)
        self.ingameMapElement:setMapZoom(10)
        self.ingameMapElement:setMapAlpha(0.25)
        self.loadingAnimation:setVisible(false)
        self.noFieldFoundText:setVisible(true)
        self.fieldNotSupportedText:setVisible(false)
    else
        local x, _, z, maxWorldPosZ = self.fieldCourse.courseField:getBoundingBox()
        self.ingameMapElement:fitToBoundary(x, _, z, maxWorldPosZ, 0.1)
        self.ingameMapElement:setMapAlpha(1)
        self.loadingAnimation:setVisible(false)
        self.noFieldFoundText:setVisible(false)
        self.fieldNotSupportedText:setVisible(false)
        if self.fieldCourse.isVineyardCourse and self.selectedMode == AIModeSelection.MODE.WORKER then
            self.fieldNotSupportedText:setVisible(true)
        end
    end
    self.workDirectionArrow:setVisible(false)
    local x = self.aiUserSettings.settings[self.selectedMode]
    for _, settingData in pairs(x) do
        if settingData.setting.identifier == "workDirection" and settingData.value >= 0 then
            self.workDirectionArrow:setVisible(true)
            self.workDirectionArrow:setImageRotation(3.141592653589793 + math.rad(settingData.value))
        end
    end
end
function AISettingsDialog:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, positions, color)
    local i = 1
    for i = i, #positions - 1 do
        local pos1 = positions[i]
        local pos2 = positions[i + 1]
        drawLine2D(((pos1[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX, (1 - ((pos1[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY, ((pos2[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX, (1 - ((pos2[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY, self.lineWidth, color[1], color[2], color[3], color[4])
    end
end
function AISettingsDialog:onDrawPostIngameMapHotspots(_, ingameMap)
    local posX, posY = self.ingameMapElement:getMapPosition()
    local sizeX, sizeZ = self.ingameMapElement:getMapSize()
    if self.fieldCourse ~= nil and self.fieldCourse.courseField ~= nil then
        local fieldCourseSettings = self.fieldCourseSettings
        self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, self.fieldCourse.courseField.fieldRootBoundary.boundaryLine, AISettingsDialog.LINE_COLORS.BOUNDARY)
        for _, segment in ipairs(self.fieldCourse.segments) do
            if segment.isHeadlandSegment or segment.isIslandSegment then
                if fieldCourseSettings.workHeadlands then
                    self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, segment.positions, AISettingsDialog.LINE_COLORS.HEADLAND)
                end
            elseif fieldCourseSettings.skipNumLines == 0 then
                self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, segment.positions, AISettingsDialog.LINE_COLORS.STRAIGHT)
            end
        end
        if fieldCourseSettings.skipNumLines > 0 then
            local i = #self.fieldCourse.segments
            for i = i, 1, -1 do
                local _ = self.fieldCourse.segments[i]
                if _.lineGroupIndex ~= nil and (_.offsetLineIndex - 1) % (fieldCourseSettings.skipNumLines + 1) == 0 then
                    self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, _.positions, AISettingsDialog.LINE_COLORS.STRAIGHT)
                end
            end
        end
    end
end
function AISettingsDialog:onClickMode(state, _)
    self.selectedMode = state == 2 and AIModeSelection.MODE.STEERING_ASSIST or AIModeSelection.MODE.WORKER
    self:assignSettingsOptions()
    self:updateFieldCourse()
    self:updateSettingsStates()
end
function AISettingsDialog:onClickOption(_, element)
    local settingData = self.elementToSettingMapping[element]
    local settingFunction = settingData.callback
    if settingFunction ~= nil then
        if settingFunction(settingData.target, element.texts[element:getState()], element:getState()) then
            self.fieldCourseUpdateTimer = 1000
            self:updateMapState()
        else
            self:updateFieldCourseSettings()
        end
        if settingData.setting:onSettingsChanged(settingData, self.elementToSettingMapping) then
            self:updateSettingsValues()
        end
        self:updateSettingsStates()
    end
end
function AISettingsDialog:onClickBinary(_, element)
    local settingData = self.elementToSettingMapping[element]
    local settingFunction = settingData.callback
    if settingFunction ~= nil then
        if settingFunction(settingData.target, element:getIsChecked(), element:getIsChecked() and 2 or 1) then
            self.fieldCourseUpdateTimer = 1000
            self:updateMapState()
        else
            self:updateFieldCourseSettings()
        end
        if settingData.setting:onSettingsChanged(settingData, self.elementToSettingMapping) then
            self:updateSettingsValues()
        end
        self:updateSettingsStates()
    end
end
function AISettingsDialog:onClickOk(_, _)
    self:sendCallback()
end
function AISettingsDialog:onClickReset(_, _)
    self.fieldCourseSettings:reset(self.vehicle)
    self.aiUserSettings:reinitialize(self.fieldCourseSettings, true)
    self:assignSettingsOptions()
    self:updateFieldCourse()
    self:updateSettingsStates()
end
AISettingsDialog.COLOR_ALTERNATING = {
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