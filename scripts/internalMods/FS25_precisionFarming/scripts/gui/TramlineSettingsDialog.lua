TramlineSettingsDialog = {}
TramlineSettingsDialog.MOD_DIR = g_currentModDirectory
TramlineSettingsDialog.LINE_COLORS = {}
TramlineSettingsDialog.LINE_COLORS.BOUNDARY = {
    0.0273,
    0.0612,
    0.3324,
    1
}
TramlineSettingsDialog.LINE_COLORS.HEADLAND = {
    0.2122,
    0.5029,
    0.402,
    1
}
TramlineSettingsDialog.LINE_COLORS.STRAIGHT = {
    0.402,
    0.2051,
    0.0144,
    1
}
local TramlineSettingsDialog_mt = Class(TramlineSettingsDialog, MessageDialog)
function TramlineSettingsDialog.register()
    local tramlineSettingsDialog = TramlineSettingsDialog.new()
    g_gui:loadGui(TramlineSettingsDialog.MOD_DIR .. "gui/TramlineSettingsDialog.xml", "TramlineSettingsDialog", tramlineSettingsDialog)
    TramlineSettingsDialog.INSTANCE = tramlineSettingsDialog
end
function TramlineSettingsDialog.show(implementWidthIndex, workDirectionIndex, spacingIndex, fieldX, fieldZ, callback)
    if TramlineSettingsDialog.INSTANCE ~= nil then
        local dialog = TramlineSettingsDialog.INSTANCE
        dialog:setCallback(callback)
        dialog.implementWidthIndex = implementWidthIndex
        dialog.workDirectionIndex = workDirectionIndex
        dialog.spacingIndex = spacingIndex
        dialog.fieldX = fieldX
        dialog.fieldZ = fieldZ
        g_gui:showDialog("TramlineSettingsDialog")
    end
end
function TramlineSettingsDialog.new(target, custom_mt)
    -- upvalues: (copy) TramlineSettingsDialog_mt
    local self = MessageDialog.new(target, custom_mt or TramlineSettingsDialog_mt)
    self.ingameMapElement = nil
    self.fieldCourseUpdateTimer = 0
    self.lineWidth = 1 / g_screenHeight
    self.farmlands = {}
    self.farmlandText = g_i18n:getText("contract_farmland")
    self.fieldCourseSettings = FieldCourseSettings.new()
    self.fieldCourseSettings.implementWidth = 27
    self.fieldCourseSettings.numHeadlands = 1
    self.fieldCourseSettings.segmentExtendedToBoundary = true
    self.fieldCourseSettings.segmentHeadlandReverseLines = true
    self.fieldCourseSettings.segmentMinOffset = 3
    self.fieldCourseSettings.segmentMinLength = 25
    return self
end
function TramlineSettingsDialog.createFromExistingGui(gui, _)
    TramlineSettingsDialog.register()
    TramlineSettingsDialog.show(gui.aiUserSettings)
end
function TramlineSettingsDialog:onGuiSetupFinished()
    TramlineSettingsDialog:superClass().onGuiSetupFinished(self)
end
function TramlineSettingsDialog:setCallback(callbackFunc, target)
    self.callbackFunc = callbackFunc
    self.target = target
end
function TramlineSettingsDialog:sendCallback(applyChanges)
    self:close()
    if self.callbackFunc ~= nil then
        if self.target == nil then
            self.callbackFunc(applyChanges, self.farmlands, self.implementWidthIndex, self.workDirectionIndex, self.spacingIndex)
        else
            self.callbackFunc(self.target, applyChanges, self.farmlands, self.implementWidthIndex, self.workDirectionIndex, self.spacingIndex)
        end
    end
    self.callbackFunc = nil
    self.target = nil
end
function TramlineSettingsDialog:delete()
    TramlineSettingsDialog:superClass().delete(self)
end
function TramlineSettingsDialog:update(dt)
    TramlineSettingsDialog:superClass().update(self, dt)
    if self.fieldCourseUpdateTimer > 0 then
        self.fieldCourseUpdateTimer = self.fieldCourseUpdateTimer - dt
        if self.fieldCourseUpdateTimer <= 0 then
            self:updateFieldCourse()
        end
    end
end
function TramlineSettingsDialog:onOpen()
    TramlineSettingsDialog:superClass().onOpen(self)
    self.isOpening = true
    self.ingameMapElement.drawHotspots = false
    self.ingameMapElement:setIngameMap(g_currentMission.hud:getIngameMap())
    self.ingameMapElement:onOpen()
    self.okButton:setDisabled(true)
    self:updateSettingsValues()
    self:updateFieldCourse()
    self.isOpening = false
end
function TramlineSettingsDialog:onClose()
    TramlineSettingsDialog:superClass().onClose(self)
    self.ingameMapElement:onClose()
    self.fieldCourse = nil
    self.fieldCourseLoading = false
end
function TramlineSettingsDialog:updateSettingsValues()
    local tramlineMap = g_precisionFarming.tramlineMap
    if tramlineMap ~= nil then
        self.implementWidthOption:setTexts(tramlineMap.implementWidthTexts)
        self.workDirectionOption:setTexts(tramlineMap.workDirectionTexts)
        self.spacingOption:setTexts(tramlineMap.spacingTexts)
    end
    self.implementWidthOption:setState(self.implementWidthIndex)
    self.workDirectionOption:setState(self.workDirectionIndex)
    self.spacingOption:setState(self.spacingIndex)
    self.implementWidthOption.parent:setImageColor(nil, unpack(TramlineSettingsDialog.COLOR_ALTERNATING[false]))
    self.workDirectionOption.parent:setImageColor(nil, unpack(TramlineSettingsDialog.COLOR_ALTERNATING[true]))
    self.spacingOption.parent:setImageColor(nil, unpack(TramlineSettingsDialog.COLOR_ALTERNATING[false]))
end
function TramlineSettingsDialog:updateFieldCourse()
    local tramlineMap = g_precisionFarming.tramlineMap
    if tramlineMap ~= nil then
        if self.implementWidthIndex > 1 then
            self.fieldCourseSettings.implementWidth = tramlineMap.implementWidths[self.implementWidthIndex]
        else
            self.fieldCourseSettings.implementWidth = tramlineMap.implementWidths[2]
        end
        local implementWidth = tramlineMap.workDirectionTextToDeg[self.workDirectionIndex]
        self.fieldCourseSettings.workDirection = math.rad(implementWidth)
    end
    if self.fieldX ~= nil and (self.fieldZ ~= nil and not self.fieldCourseLoading) then
        if self.fieldCourse == nil then
            self.fieldCourseLoading = true
            if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                self.fieldCourseSettings:print()
            end
            FieldCourse.generateUICourseByFieldPosition(self.fieldX, self.fieldZ, self.fieldCourseSettings, function(fieldCourse)
                -- upvalues: (copy) self
                self.fieldCourseLoading = false
                if self.callbackFunc ~= nil then
                    if fieldCourse == nil then
                        self.fieldCourse = nil
                    else
                        self.fieldCourse = fieldCourse
                    end
                    self:updateMapState()
                    self:updateFarmlands()
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
                if self.callbackFunc ~= nil then
                    if not success then
                        self.fieldCourse = nil
                    end
                    self:updateMapState()
                    self:updateFarmlands()
                end
            end)
        end
    end
    self:updateMapState()
end
function TramlineSettingsDialog:updateFarmlands()
    self.farmlands = {}
    if self.fieldCourse ~= nil then
        local farmlands = g_farmlandManager:getFarmlands()
        for _, farmland in ipairs(farmlands) do
            local x, z = farmland:getIndicatorPosition()
            if FieldCourseUtil.getIsPointInsideBoundary(x, z, self.fieldCourse.courseField.fieldRootBoundary.boundaryLine) then
                table.insert(self.farmlands, farmland)
            end
        end
    end
    local boundary = self.okButton
    boundary:setDisabled(#self.farmlands == 0)
end
function TramlineSettingsDialog:updateMapState()
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
        self.tramlinesDisabledText:setVisible(false)
    elseif self.implementWidthIndex == 1 then
        self.loadingAnimation:setVisible(false)
        self.noFieldFoundText:setVisible(false)
        self.fieldNotSupportedText:setVisible(false)
        self.tramlinesDisabledText:setVisible(true)
    elseif self.fieldCourse == nil then
        local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
        self.ingameMapElement:setCenterToWorldPosition(x, z)
        self.ingameMapElement:setMapZoom(10)
        self.ingameMapElement:setMapAlpha(0.25)
        self.loadingAnimation:setVisible(false)
        self.noFieldFoundText:setVisible(true)
        self.fieldNotSupportedText:setVisible(false)
        self.tramlinesDisabledText:setVisible(false)
    else
        self.loadingAnimation:setVisible(false)
        self.noFieldFoundText:setVisible(false)
        self.fieldNotSupportedText:setVisible(false)
        self.tramlinesDisabledText:setVisible(false)
    end
    if self.fieldCourse ~= nil then
        local x, _, z, maxWorldPosZ = self.fieldCourse.courseField:getBoundingBox()
        self.ingameMapElement:fitToBoundary(x, _, z, maxWorldPosZ, 0.1)
        self.ingameMapElement:setMapAlpha(1)
    end
    local x = g_precisionFarming.tramlineMap
    if x ~= nil then
        if self.workDirectionIndex > 1 then
            self.workDirectionArrow:setVisible(true)
            self.workDirectionArrow:setImageRotation(3.141592653589793 + math.rad(x.workDirectionTextToDeg[self.workDirectionIndex]))
            return
        end
        self.workDirectionArrow:setVisible(false)
    end
end
function TramlineSettingsDialog:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, positions, color)
    local i = 1
    for i = i, #positions - 1 do
        local pos1 = positions[i]
        local pos2 = positions[i + 1]
        drawLine2D(((pos1[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX, (1 - ((pos1[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY, ((pos2[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX, (1 - ((pos2[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY, self.lineWidth, color[1], color[2], color[3], color[4])
    end
end
function TramlineSettingsDialog:onDrawPostIngameMapHotspots(_, ingameMap)
    local posX, posY = self.ingameMapElement:getMapPosition()
    local sizeX, sizeZ = self.ingameMapElement:getMapSize()
    if self.fieldCourse ~= nil and self.fieldCourse.courseField ~= nil then
        for _, farmland in ipairs(self.farmlands) do
            local farmlandX, farmlandZ = farmland:getIndicatorPosition()
            setTextAlignment(RenderText.ALIGN_CENTER)
            setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
            setTextColor(1, 1, 1, 1)
            renderText(((farmlandX / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX, (1 - ((farmlandZ / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY, 0.01, string.format(self.farmlandText, farmland:getName()))
            setTextAlignment(RenderText.ALIGN_LEFT)
            setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
        end
        self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, self.fieldCourse.courseField.fieldRootBoundary.boundaryLine, TramlineSettingsDialog.LINE_COLORS.BOUNDARY)
        if self.implementWidthIndex > 1 then
            for _, farmland in ipairs(self.fieldCourse.segments) do
                if farmland.isHeadlandSegment or farmland.isIslandSegment then
                    if self.fieldCourseSettings.workHeadlands then
                        self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, farmland.positions, TramlineSettingsDialog.LINE_COLORS.HEADLAND)
                    end
                elseif fieldCourseSettings.skipNumLines == 0 then
                    self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, farmland.positions, TramlineSettingsDialog.LINE_COLORS.STRAIGHT)
                end
            end
            if fieldCourseSettings.skipNumLines > 0 then
                local i = #self.fieldCourse.segments
                for i = i, 1, -1 do
                    local _ = self.fieldCourse.segments[i]
                    if _.lineGroupIndex ~= nil and (_.offsetLineIndex - 1) % (fieldCourseSettings.skipNumLines + 1) == 0 then
                        self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, _.positions, TramlineSettingsDialog.LINE_COLORS.STRAIGHT)
                    end
                end
            end
        end
    end
end
function TramlineSettingsDialog:onClickImplementWidth(state, _)
    self.implementWidthIndex = state
    self.fieldCourseUpdateTimer = 1000
    self:updateMapState()
end
function TramlineSettingsDialog:onClickWorkDirection(state, _)
    self.workDirectionIndex = state
    self.fieldCourseUpdateTimer = 1000
    self:updateMapState()
end
function TramlineSettingsDialog:onClickSpacing(state, _)
    self.spacingIndex = state
end
function TramlineSettingsDialog:onClickOk(_, _)
    self:sendCallback(true)
end
function TramlineSettingsDialog:onClickBack(_, _)
    self:sendCallback(false)
end
TramlineSettingsDialog.COLOR_ALTERNATING = {
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