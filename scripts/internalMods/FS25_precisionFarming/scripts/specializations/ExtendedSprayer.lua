ExtendedSprayer = {}
ExtendedSprayer.SPEC_NAME = g_currentModName .. ".extendedSprayer"
ExtendedSprayer.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedSprayer"
source(g_currentModDirectory .. "scripts/hud/ExtendedSprayerHUDExtension.lua")
function ExtendedSprayer.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Sprayer, specializations) and SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function ExtendedSprayer.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("pulseWidthModulation", g_i18n:getText("configuration_pulseWidthModulation"), "sprayer", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ExtendedSprayer")
    schema:register(XMLValueType.BOOL, "vehicle.sprayer.pulseWidthModulationConfigurations#isAlwaysActive", "Pulse width modulation is always active", false)
    schema:register(XMLValueType.BOOL, "vehicle.sprayer.speedDependentApplication#isSupported", "Spreader / sprayer does automatically reduce the application rate while driving slower", "by default supported on all except sprayers")
    schema:setXMLSpecializationType()
end
function ExtendedSprayer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setSprayAmountAutoMode", ExtendedSprayer.setSprayAmountAutoMode)
    SpecializationUtil.registerFunction(vehicleType, "setSprayAmountManualValue", ExtendedSprayer.setSprayAmountManualValue)
    SpecializationUtil.registerFunction(vehicleType, "setSprayAmountAutoFruitTypeIndex", ExtendedSprayer.setSprayAmountAutoFruitTypeIndex)
    SpecializationUtil.registerFunction(vehicleType, "setSprayAmountDefaultFruitRequirementIndex", ExtendedSprayer.setSprayAmountDefaultFruitRequirementIndex)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentSprayerMode", ExtendedSprayer.getCurrentSprayerMode)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentNitrogenLevelOffset", ExtendedSprayer.getCurrentNitrogenLevelOffset)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentNitrogenUsageLevelOffset", ExtendedSprayer.getCurrentNitrogenUsageLevelOffset)
    SpecializationUtil.registerFunction(vehicleType, "getUseExtendedSprayerHudExtension", ExtendedSprayer.getUseExtendedSprayerHudExtension)
    SpecializationUtil.registerFunction(vehicleType, "getShowExtendedSprayerHudExtension", ExtendedSprayer.getShowExtendedSprayerHudExtension)
    SpecializationUtil.registerFunction(vehicleType, "getIsUsingExactNitrogenAmount", ExtendedSprayer.getIsUsingExactNitrogenAmount)
    SpecializationUtil.registerFunction(vehicleType, "getIsPrecisionSprayingRequired", ExtendedSprayer.getIsPrecisionSprayingRequired)
    SpecializationUtil.registerFunction(vehicleType, "preProcessExtUnderRootFertilizerArea", ExtendedSprayer.preProcessExtUnderRootFertilizerArea)
    SpecializationUtil.registerFunction(vehicleType, "updateWorkAreaSubSectionData", ExtendedSprayer.updateWorkAreaSubSectionData)
    SpecializationUtil.registerFunction(vehicleType, "processWorkAreaSubSectionData", ExtendedSprayer.processWorkAreaSubSectionData)
end
function ExtendedSprayer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateWorkAreaWidth", ExtendedSprayer.updateWorkAreaWidth)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerUsage", ExtendedSprayer.getSprayerUsage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSprayerArea", ExtendedSprayer.processSprayerArea)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "changeSeedIndex", ExtendedSprayer.changeSeedIndex)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerDoubledAmountActive", ExtendedSprayer.getSprayerDoubledAmountActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateSprayerEffects", ExtendedSprayer.updateSprayerEffects)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtendedSprayerNozzleEffectState", ExtendedSprayer.updateExtendedSprayerNozzleEffectState)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", ExtendedSprayer.setSprayerAITerrainDetailProhibitedRange)
end
function ExtendedSprayer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onVariableWorkWidthSectionChanged", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", ExtendedSprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ExtendedSprayer)
end
function ExtendedSprayer:onPreLoad(_)
    if g_precisionFarming ~= nil then
        self[ExtendedSprayer.SPEC_TABLE_NAME].soilMap = g_precisionFarming.soilMap
        spec.pHMap = g_precisionFarming.pHMap
        spec.nitrogenMap = g_precisionFarming.nitrogenMap
    end
end
function ExtendedSprayer:onLoad(_)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    spec.pwmEnabled = (self.configurations.pulseWidthModulation or 1) > 1
    spec.spotSprayEnabled = (self.configurations.weedSpotSpray or 1) > 1
    if self.xmlFile:getValue("vehicle.sprayer.pulseWidthModulationConfigurations#isAlwaysActive", false) then
        spec.pwmEnabled = true
    end
    if self.spec_sowingMachine ~= nil then
        spec.pwmEnabled = true
    end
    spec.texts = {}
    spec.texts.toggleSprayAmountAutoModePos = g_i18n:getText("action_toggleSprayAmountAutoModePos", self.customEnvironment)
    spec.texts.toggleSprayAmountAutoModeNeg = g_i18n:getText("action_toggleSprayAmountAutoModeNeg", self.customEnvironment)
    spec.texts.toggleSprayAmountAutoManual = g_i18n:getText("action_toggleSprayAmountManual", self.customEnvironment)
    spec.texts.toggleSprayDefaultFruitRequirement = g_i18n:getText("action_toggleSprayDefaultFruitRequirement", self.customEnvironment)
    spec.lastLitersPerHectar = 0
    spec.lastNitrogenProportion = 0
    spec.lastRegularUsage = 0
    spec.lastTouchedSoilType = 0
    spec.lastTouchedSoilTypeSent = 0
    spec.lastGroundUpdateDistance = math.huge
    spec.groundUpdateDistance = 2
    spec.phActualValue = 0
    spec.phActualValueSent = 0
    spec.phTargetValue = 0
    spec.phTargetValueSent = 0
    spec.nActualValue = 0
    spec.nActualValueSent = 0
    spec.nTargetValue = 0
    spec.nTargetValueSent = 0
    spec.sprayAmountAutoMode = true
    spec.sprayAmountAutoModeChangeAllowed = true
    spec.sprayAmountManual = 1
    spec.sprayAmountManualMin = 1
    spec.sprayAmountManualMax = 1
    spec.inputActionToggleAuto = InputAction.PRECISIONFARMING_SPRAY_AMOUNT_MODE
    spec.inputActionToggleSprayAmount = InputAction.PRECISIONFARMING_SPRAY_AMOUNT
    spec.isDoingMissionWork = false
    local _, _, nMaxValue = spec.nitrogenMap:getMinMaxValue()
    spec.sprayAmountManualMax = nMaxValue - 1
    spec.attachStateChanged = false
    spec.nApplyAutoModeFruitType = FruitType.UNKNOWN
    spec.nApplyAutoModeFruitTypeSent = FruitType.UNKNOWN
    spec.nApplyAutoModeFruitRequirementDefaultIndex = 1
    spec.nApplyAutoModeFruitTypeRequiresDefaultMode = false
    spec.lastAreaChangeTime = -math.huge
    spec.lastSprayerEffectState = true
    spec.densityMapParallelogram = DensityMapParallelogram.new()
    spec.densityMapPolygon = DensityMapPolygon.new()
    spec.densityMapPolygon:addPolygonPoint(0, 0)
    spec.densityMapPolygon:addPolygonPoint(0, 0)
    spec.densityMapPolygon:addPolygonPoint(0, 0)
    spec.densityMapPolygon:addPolygonPoint(0, 0)
    local sprayerFillUnitIndex = self:getSprayerFillUnitIndex()
    spec.isSlurryTanker = self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.LIQUIDMANURE) or self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.DIGESTATE)
    spec.isManureSpreader = self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.MANURE)
    spec.isSolidFertilizerSprayer = self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.FERTILIZER) or self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.LIME)
    spec.isLiquidFertilizerSprayer = self:getFillUnitAllowsFillType(sprayerFillUnitIndex, FillType.LIQUIDFERTILIZER)
    spec.speedDependentApplication = self.xmlFile:getValue("vehicle.sprayer.speedDependentApplication#isSupported", not spec.isLiquidFertilizerSprayer)
    spec.usageValuesDirtyFlag = self:getNextDirtyFlag()
    if self:getUseExtendedSprayerHudExtension() then
        spec.hudExtension = ExtendedSprayerHUDExtension.new(self)
    end
    spec.sprayerWorkAreas = self:getTypedWorkAreas(WorkAreaType.SPRAYER)
    spec.sowingMachineWorkAreas = self:getTypedWorkAreas(WorkAreaType.SOWINGMACHINE)
    spec.cultivatorWorkAreas = self:getTypedWorkAreas(WorkAreaType.CULTIVATOR)
    spec.workAreas = {}
    for _, workArea in pairs(spec.sprayerWorkAreas) do
        table.insert(spec.workAreas, workArea)
    end
    for _, workArea in pairs(spec.sowingMachineWorkAreas) do
        table.insert(spec.workAreas, workArea)
    end
    for _, workArea in pairs(spec.cultivatorWorkAreas) do
        table.insert(spec.workAreas, workArea)
    end
    spec.useFertilizerSprayType = #spec.cultivatorWorkAreas > 0 or #spec.sowingMachineWorkAreas > 0
    spec.groundTypeMapId, spec.groundTypeFirstChannel, spec.groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
end
function ExtendedSprayer:onPostLoad(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
        local specName = ExtendedSprayer.SPEC_NAME
        self:setSprayAmountAutoMode(Utils.getNoNil(savegame.xmlFile:getBool(savegame.key .. "." .. specName .. "#sprayAmountAutoMode"), spec.sprayAmountAutoMode), true)
        self:setSprayAmountManualValue(savegame.xmlFile:getInt(savegame.key .. "." .. specName .. "#sprayAmountManual") or spec.sprayAmountManual, true)
    end
end
function ExtendedSprayer:onDelete()
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    if spec.hudExtension ~= nil then
        spec.hudExtension:delete()
    end
end
function ExtendedSprayer:saveToXMLFile(xmlFile, key, _)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    xmlFile:setBool(key .. "#sprayAmountAutoMode", spec.sprayAmountAutoMode)
    xmlFile:setInt(key .. "#sprayAmountManual", spec.sprayAmountManual)
end
function ExtendedSprayer:onReadStream(streamId, _)
    local sprayAmountAutoMode = streamReadBool(streamId)
    local sprayAmountManual = streamReadUIntN(streamId, NitrogenMap.NUM_BITS)
    self:setSprayAmountAutoMode(sprayAmountAutoMode, true)
    self:setSprayAmountManualValue(sprayAmountManual, true)
end
function ExtendedSprayer:onWriteStream(streamId, _)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    streamWriteBool(streamId, spec.sprayAmountAutoMode)
    streamWriteUIntN(streamId, spec.sprayAmountManual, NitrogenMap.NUM_BITS)
end
function ExtendedSprayer:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self[ExtendedSprayer.SPEC_TABLE_NAME].phActualValue = streamReadUIntN(streamId, PHMap.NUM_BITS)
            spec.phTargetValue = streamReadUIntN(streamId, PHMap.NUM_BITS)
            spec.nActualValue = streamReadUIntN(streamId, NitrogenMap.NUM_BITS)
            spec.nTargetValue = streamReadUIntN(streamId, NitrogenMap.NUM_BITS)
            spec.lastTouchedSoilType = streamReadUIntN(streamId, 3)
            if streamReadBool(streamId) then
                self:setSprayAmountAutoFruitTypeIndex(streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS))
                return
            end
            self:setSprayAmountAutoFruitTypeIndex(nil)
        end
    end
end
function ExtendedSprayer:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.usageValuesDirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, spec.phActualValue, PHMap.NUM_BITS)
            streamWriteUIntN(streamId, spec.phTargetValue, PHMap.NUM_BITS)
            streamWriteUIntN(streamId, spec.nActualValue, NitrogenMap.NUM_BITS)
            streamWriteUIntN(streamId, spec.nTargetValue, NitrogenMap.NUM_BITS)
            streamWriteUIntN(streamId, spec.lastTouchedSoilType, 3)
            if streamWriteBool(streamId, spec.nApplyAutoModeFruitType ~= nil) then
                streamWriteUIntN(streamId, spec.nApplyAutoModeFruitType, FruitTypeManager.SEND_NUM_BITS)
            end
        end
    end
end
function ExtendedSprayer:onUpdate(_, _, _, _)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    if self.isServer then
        if not self.finishedFirstUpdate then
            spec.isLiming, spec.isFertilizing = self:getCurrentSprayerMode()
            ExtendedSprayer.updateActionEventState(self)
            ExtendedSprayer.updateActionEventAutoModeDefault(self)
        end
        if self.finishedFirstUpdate then
            spec.lastGroundUpdateDistance = spec.lastGroundUpdateDistance + self.lastMovedDistance
            if spec.lastGroundUpdateDistance > spec.groundUpdateDistance then
                spec.lastGroundUpdateDistance = 0
                for _, workArea in pairs(spec.sprayerWorkAreas) do
                    local isAllowed = true
                    if workArea.sprayType ~= nil then
                        local sprayType = self:getActiveSprayType()
                        if sprayType ~= nil and sprayType.index ~= workArea.sprayType then
                            isAllowed = false
                        end
                    end
                    if isAllowed then
                        self:updateWorkAreaSubSectionData(workArea)
                    end
                end
                for _, workArea in pairs(spec.sowingMachineWorkAreas) do
                    self:updateWorkAreaSubSectionData(workArea)
                end
                for _, workArea in pairs(spec.cultivatorWorkAreas) do
                    self:updateWorkAreaSubSectionData(workArea)
                end
                for _, workArea in ipairs(self.rootVehicle.childVehicles) do
                    if workArea["spec_pdlc_nexatPack.cultivatorSowingMachineExtension"] ~= nil then
                        for _, workArea in pairs(workArea.spec_workArea.workAreas) do
                            if workArea.type == WorkAreaType.CULTIVATOR then
                                if workArea.subSectionData == nil then
                                    self:updateWorkAreaWidth(0, workArea)
                                end
                                self:updateWorkAreaSubSectionData(workArea)
                            end
                        end
                    end
                end
            end
        end
    end
    if self.isActiveForInputIgnoreSelectionIgnoreAI and (self:getShowExtendedSprayerHudExtension() and spec.hudExtension ~= nil) then
        g_currentMission.hud:addHelpExtension(spec.hudExtension)
    end
end
function ExtendedSprayer:onUpdateTick(_, _, _, _)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    if self.isClient then
        if self:getIsTurnedOn() then
            ExtendedSprayer.updateSprayerEffectState(self)
        else
            spec.lastSprayerEffectState = true
        end
    end
    local isLiming, isFertilizing = self:getCurrentSprayerMode()
    if isLiming ~= spec.isLiming or isFertilizing ~= spec.isFertilizing then
        spec.isLiming = isLiming
        spec.isFertilizing = isFertilizing
        ExtendedSprayer.updateActionEventState(self)
        ExtendedSprayer.updateActionEventAutoModeDefault(self)
    end
    if self.isActiveForInputIgnoreSelectionIgnoreAI then
        ExtendedSprayer.updateMinimapActiveState(self)
        local _, _, _, _, mission = self:getPFStatisticInfo()
        local isDoingMissionWork = mission == nil and spec.sprayAmountAutoMode
        if isDoingMissionWork then
            isDoingMissionWork = spec.nApplyAutoModeFruitTypeRequiresDefaultMode
        end
        if spec.isDoingMissionWork ~= isDoingMissionWork then
            spec.isDoingMissionWork = isDoingMissionWork
            ExtendedSprayer.updateMinimapActiveState(self)
        end
    end
end
function ExtendedSprayer:onChangedFillType(_, fillTypeIndex, _)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    if spec.isSolidFertilizerSprayer and fillTypeIndex == FillType.LIME then
        local _, _, pHMaxValue = spec.pHMap:getMinMaxValue()
        spec.sprayAmountManualMax = pHMaxValue - 1
    else
        local _, _, pHMaxValue = spec.nitrogenMap:getMinMaxValue()
        spec.sprayAmountManualMax = pHMaxValue - 1
    end
end
function ExtendedSprayer:onTurnedOn()
    if self.isClient then
        ExtendedSprayer.updateSprayerEffectState(self, true)
    end
end
function ExtendedSprayer:onTurnedOff()
    if self.isClient then
        ExtendedSprayer.updateSprayerEffectState(self, true)
    end
end
function ExtendedSprayer:onStateChange(state, _)
    if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
        self[ExtendedSprayer.SPEC_TABLE_NAME].attachStateChanged = true
    end
end
function ExtendedSprayer:onVariableWorkWidthSectionChanged()
    local vehicles = self.rootVehicle.childVehicles
    local i = 1
    for i = i, #vehicles do
        local vehicle = vehicles[i]
        if SpecializationUtil.hasSpecialization(CropSensor, vehicle.specializations) then
            vehicle:updateCropSensorWorkingWidth()
        end
    end
    if self.isClient then
        ExtendedSprayer.updateSprayerEffectState(self, true)
    end
end
function ExtendedSprayer:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
        self:clearActionEventsTable(spec.actionEvents)
        spec.pHMap:setRequireMinimapDisplay(false, self)
        spec.nitrogenMap:setRequireMinimapDisplay(false, self)
        if isActiveForInputIgnoreSelection and self == ExtendedSprayer.getValidSprayerToUse(self) then
            if spec.sprayAmountAutoModeChangeAllowed then
                local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.inputActionToggleAuto, self, ExtendedSprayer.actionEventToggleAuto, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            end
            local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.inputActionToggleSprayAmount, self, ExtendedSprayer.actionEventChangeSprayAmount, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.toggleSprayAmountAutoManual)
            if self.spec_sowingMachine == nil then
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_SEEDS, self, ExtendedSprayer.actionEventChangeDefaultFruitRequirement, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
                g_inputBinding:setActionEventText(actionEventId, spec.texts.toggleSprayDefaultFruitRequirement)
            end
            ExtendedSprayer.updateActionEventState(self)
            ExtendedSprayer.updateActionEventAutoModeDefault(self)
            ExtendedSprayer.updateMinimapActiveState(self)
        end
        spec.attachStateChanged = true
    end
end
function ExtendedSprayer:getValidSprayerToUse()
    local vehicleList = self.rootVehicle.childVehicles
    local i = 1
    for i = i, #vehicleList do
        local subVehicle = vehicleList[i]
        if ExtendedSprayer.getIsVehicleValid(subVehicle) then
            return subVehicle
        end
    end
    return nil
end
function ExtendedSprayer.getIsVehicleValid(vehicle)
    if SpecializationUtil.hasSpecialization(ExtendedSprayer, vehicle.specializations) then
        if SpecializationUtil.hasSpecialization(WorkArea, vehicle.specializations) then
            if #vehicle.spec_workArea.workAreas == 0 then
                return false
            else
                return (not SpecializationUtil.hasSpecialization(ManureBarrel, vehicle.specializations) or vehicle.spec_manureBarrel.attachedTool == nil) and true or false
            end
        else
            return false
        end
    else
        return false
    end
end
function ExtendedSprayer:actionEventToggleAuto(_, _, _, _)
    self:setSprayAmountAutoMode()
end
function ExtendedSprayer:actionEventChangeSprayAmount(_, inputValue, _, _)
    self:setSprayAmountManualValue(self[ExtendedSprayer.SPEC_TABLE_NAME].sprayAmountManual + math.sign(inputValue))
end
function ExtendedSprayer:actionEventChangeDefaultFruitRequirement(_, _, _, _)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    self:setSprayAmountDefaultFruitRequirementIndex(spec.nitrogenMap:getNextFruitRequirementIndex(spec.nApplyAutoModeFruitRequirementDefaultIndex))
end
function ExtendedSprayer:updateActionEventState()
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    local actionEventToggleAuto = spec.actionEvents[spec.inputActionToggleAuto]
    if actionEventToggleAuto ~= nil then
        g_inputBinding:setActionEventActive(actionEventToggleAuto.actionEventId, spec.isLiming or spec.isFertilizing)
        g_inputBinding:setActionEventText(actionEventToggleAuto.actionEventId, spec.sprayAmountAutoMode and spec.texts.toggleSprayAmountAutoModeNeg or spec.texts.toggleSprayAmountAutoModePos)
    end
    local actionEventToggleSprayAmount = spec.actionEvents[spec.inputActionToggleSprayAmount]
    if actionEventToggleSprayAmount ~= nil then
        g_inputBinding:setActionEventActive(actionEventToggleSprayAmount.actionEventId, not spec.sprayAmountAutoMode and (spec.isLiming or spec.isFertilizing))
    end
end
function ExtendedSprayer:updateActionEventAutoModeDefault()
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    local actionEvent = spec.actionEvents[InputAction.TOGGLE_SEEDS]
    if actionEvent ~= nil then
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.isFertilizing and spec.sprayAmountAutoMode and (spec.nApplyAutoModeFruitType == nil or spec.nApplyAutoModeFruitType == FruitType.UNKNOWN))
    end
end
function ExtendedSprayer.getFillTypeSourceVehicle(sprayer)
    local firstEmptySource = nil
    local firstEmptySourceFillUnitIndex = 1
    local fillUnitIndex = sprayer:getSprayerFillUnitIndex()
    if sprayer:getFillUnitFillLevel(fillUnitIndex) <= 0 then
        local spec = sprayer.spec_sprayer
        for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
            for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
                local vehicle = src.vehicle
                local fillLevel = vehicle:getFillUnitFillLevel(src.fillUnitIndex)
                if vehicle:getFillUnitFillType(src.fillUnitIndex) == supportedSprayType then
                    if fillLevel > 0 then
                        return vehicle, src.fillUnitIndex
                    end
                elseif fillLevel == 0 and vehicle:getFillUnitSupportsFillType(src.fillUnitIndex, supportedSprayType) then
                    firstEmptySourceFillUnitIndex = src.fillUnitIndex
                    firstEmptySource = vehicle
                end
            end
        end
    end
    if sprayer:getIsAIActive() and sprayer:getFillUnitCapacity(fillUnitIndex) == 0 then
        return firstEmptySource or sprayer, firstEmptySourceFillUnitIndex or fillUnitIndex
    else
        return sprayer, fillUnitIndex
    end
end
function ExtendedSprayer:getCurrentSprayerMode()
    local sprayer, fillUnitIndex = ExtendedSprayer.getFillTypeSourceVehicle(self)
    local fillType = sprayer:getFillUnitFillType(fillUnitIndex)
    if fillType == FillType.UNKNOWN then
        if self:getIsAIActive() then
            return false, true
        end
        fillType = sprayer:getFillUnitLastValidFillType(fillUnitIndex)
    end
    if fillType == FillType.LIME then
        return true, false
    elseif self[ExtendedSprayer.SPEC_TABLE_NAME].nitrogenMap:getFillTypeIsFertilizer(fillType) then
        return false, true
    elseif fillType == FillType.HERBICIDE then
        return false, false
    else
        return false, false
    end
end
function ExtendedSprayer:getCurrentNitrogenLevelOffset(lastChangeLevels)
    return 0
end
function ExtendedSprayer:getCurrentNitrogenUsageLevelOffset(lastChangeLevels)
    return 0
end
function ExtendedSprayer:getUseExtendedSprayerHudExtension()
    if SpecializationUtil.hasSpecialization(WorkArea, self.specializations) then
        return #self.spec_workArea.workAreas ~= 0
    else
        return false
    end
end
function ExtendedSprayer:getShowExtendedSprayerHudExtension()
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    if not self.isClient then
        return false
    end
    if self.spec_manureBarrel ~= nil and self.spec_manureBarrel.attachedTool ~= nil then
        return false
    end
    if not (spec.isSlurryTanker or spec.isManureSpreader) then
        local sourceVehicle, sourceFillUnitIndex = ExtendedSprayer.getFillTypeSourceVehicle(self)
        if sourceVehicle:getFillUnitFillLevel(sourceFillUnitIndex) <= 0 and not self:getIsAIActive() then
            return false
        end
        if not (spec.isLiming or spec.isFertilizing) then
            return false
        end
    end
    return true
end
function ExtendedSprayer:getIsUsingExactNitrogenAmount()
    return true
end
function ExtendedSprayer:updateMinimapActiveState()
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    local _, _, _, isOnField = self:getPFStatisticInfo()
    if isOnField then
        local sprayer, fillUnitIndex = ExtendedSprayer.getFillTypeSourceVehicle(self)
        if isOnField then
            isOnField = true
            if sprayer:getFillUnitFillLevel(fillUnitIndex) <= 0 then
                isOnField = self:getIsAIActive()
            end
        end
    end
    if isOnField then
        isOnField = spec.isLiming or spec.isFertilizing
    end
    if spec.isLiming then
        spec.pHMap:setRequireMinimapDisplay(isOnField, self, self:getIsSelected())
    elseif spec.isFertilizing then
        spec.nitrogenMap:setRequireMinimapDisplay(isOnField, self, self:getIsSelected())
        spec.nitrogenMap:setMinimapMissionState(spec.isDoingMissionWork)
    end
end
function ExtendedSprayer:getIsPrecisionSprayingRequired()
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    if spec.isDoingMissionWork then
        return true
    end
    if spec.sprayAmountAutoMode then
        local dataUncovered = false
        for _, workArea in pairs(spec.workAreas) do
            if workArea.isPrecisionFarmingDataUncovered then
                dataUncovered = true
                break
            end
        end
        if not dataUncovered then
            return true
        end
        if not spec.pwmEnabled then
            if spec.isLiming then
                if spec.phActualValue >= spec.phTargetValue then
                    return false
                end
            elseif spec.isFertilizing and spec.nActualValue >= spec.nTargetValue then
                return false
            end
        end
    end
    return true
end
function ExtendedSprayer:updateSprayerEffectState(force)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    local effectState = self:getIsPrecisionSprayingRequired() and self:getAreEffectsVisible()
    if effectState then
        effectState = self:getIsTurnedOn()
    end
    if spec.lastSprayerEffectState ~= effectState or force then
        local sprayType = self:getActiveSprayType()
        if effectState then
            local fillType = self:getFillUnitLastValidFillType(self:getSprayerFillUnitIndex())
            if fillType == FillType.UNKNOWN then
                fillType = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
            end
            g_effectManager:setEffectTypeInfo(self.spec_sprayer.effects, fillType)
            g_effectManager:startEffects(specSprayer.effects)
            g_soundManager:playSamples(specSprayer.samples.spray)
            if sprayType ~= nil then
                g_effectManager:setEffectTypeInfo(sprayType.effects, fillType)
                g_effectManager:startEffects(sprayType.effects)
                g_animationManager:startAnimations(sprayType.animationNodes)
                g_soundManager:playSamples(sprayType.samples.spray)
            end
            g_animationManager:startAnimations(specSprayer.animationNodes)
        else
            g_effectManager:stopEffects(specSprayer.effects)
            g_soundManager:stopSamples(specSprayer.samples.spray)
            for _, _sprayType in ipairs(specSprayer.sprayTypes) do
                g_effectManager:stopEffects(_sprayType.effects)
                g_animationManager:stopAnimations(_sprayType.animationNodes)
                g_soundManager:stopSamples(_sprayType.samples.spray)
            end
            g_animationManager:stopAnimations(specSprayer.animationNodes)
        end
        spec.lastSprayerEffectState = effectState
    end
end
function ExtendedSprayer:updateWorkAreaWidth(superFunc, workAreaIndex, workArea)
    superFunc(self, workAreaIndex)
    local spec = workArea or self.spec_workArea.workAreas[workAreaIndex]
    if spec ~= nil then
        local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
        local xOffset, _, _ = localToLocal(spec.start, self.rootNode, 0, 0, 0)
        local isFertilizerSpreader = math.abs(xOffset) < 0.1
        local numMainDivisions = 1
        local subSectionIndex = spec.workWidth * 0.5
        local numSubDivisions = math.ceil(subSectionIndex)
        if isFertilizerSpreader then
            numMainDivisions = 2
            numSubDivisions = math.ceil(spec.workWidth * 0.5 * 0.5)
        end
        if numMainDivisions ~= spec.numMainDivisions or numSubDivisions ~= spec.numSubDivisions then
            spec.numMainDivisions = numMainDivisions
            spec.numSubDivisions = numSubDivisions
            spec.maxPHApplicationOffset = 0
            spec.maxNApplicationOffset = 0
            local subSectionIndex = 1
            spec.subSectionData = {}
            local mainIndex = 1
            for mainIndex = mainIndex, spec.numMainDivisions do
                local subIndex = 1
                for subIndex = subIndex, spec.numSubDivisions do
                    local subSectionData = nil
                    if spec.subSectionData[subSectionIndex] == nil then
                        spec.subSectionData[subSectionIndex] = {}
                        subSectionData = spec.subSectionData[subSectionIndex]
                    end
                    subSectionData.index = subSectionIndex
                    subSectionData.mainIndex = mainIndex
                    subSectionData.subIndex = subIndex
                    subSectionData.isValid = false
                    subSectionData.nitrogenLevel = 0
                    subSectionData.nitrogenTargetLevel = 0
                    subSectionData.phLevel = 0
                    subSectionData.phTargetLevel = 0
                    subSectionData.soilTypeIndex = 0
                    subSectionData.fruitType = FruitType.UNKNOWN
                    subSectionData.growthState = 0
                    subSectionData.lastSpeed = 0
                    subSectionData.phApplicationOffset = 0
                    subSectionData.nApplicationOffset = 0
                    if spec.numMainDivisions > 1 and spec.numSubDivisions > 1 then
                        subSectionData.phApplicationOffset = -math.floor((subIndex - 1) / (spec.numSubDivisions - 1) * 2.01)
                        subSectionData.nApplicationOffset = -math.floor((subIndex - 1) / (spec.numSubDivisions - 1) * 4.01)
                        spec.maxPHApplicationOffset = math.max(spec.maxPHApplicationOffset, (math.abs(subSectionData.phApplicationOffset)))
                        spec.maxNApplicationOffset = math.max(spec.maxNApplicationOffset, (math.abs(subSectionData.nApplicationOffset)))
                    end
                    subSectionData.lastDetectionX = 0
                    subSectionData.lastDetectionZ = 0
                    subSectionIndex = subSectionIndex + 1
                end
            end
            spec.numSubSections = subSectionIndex - 1
            spec.nitrogenLevel = 0
            spec.nitrogenTargetLevel = 0
            spec.phLevel = 0
            spec.phTargetLevel = 0
            spec.lastSpeed = 0
            spec.fruitType = FruitType.UNKNOWN
            if spec.fruitTypes == nil then
                spec.fruitTypes = {}
            end
            for index, _ in pairs(g_fruitTypeManager:getFruitTypes()) do
                spec.fruitTypes[index] = 0
            end
            spec.growthState = 0
            spec.soilTypeIndex = 0
            if spec.soilTypes == nil then
                spec.soilTypes = {}
            end
            if spec.soilMap ~= nil and spec.soilMap.soilTypes ~= nil then
                for index, _ in pairs(spec.soilMap.soilTypes) do
                    spec.soilTypes[index] = 0
                end
            end
            spec.lastGroundUpdateDistance = math.huge
        end
    end
end
function ExtendedSprayer:updateWorkAreaSubSectionData(workArea)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    local sprayType = self.spec_sprayer.workAreaParameters.sprayType
    if sprayType == nil then
        local fillType = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
        sprayType = g_sprayTypeManager:getSprayTypeIndexByFillTypeIndex(fillType)
    end
    if spec.useFertilizerSprayType then
        fillType = SprayType.FERTILIZER
    end
    if workArea.subSectionData == nil then
        self:updateWorkAreaWidth(workArea.index)
    end
    local fillType
    if workArea.subSectionData ~= nil then
        local moveDirX, _, moveDirZ = localDirectionToWorld(workArea.start, 0, 0, 1)
        local worldStartX, y = MathUtil.vector2Normalize(moveDirX, moveDirZ)
        local worldStartX, y, worldStartZ = getWorldTranslation(workArea.start)
        local worldWidthX, _, worldWidthZ = getWorldTranslation(workArea.width)
        local worldHeightX, _, worldHeightZ = getWorldTranslation(workArea.height)
        if workArea.numMainDivisions == 1 then
            local dirX = worldWidthX - worldStartX
            local dirZ = worldWidthZ - worldStartZ
            local width = MathUtil.vector2Length(dirX, dirZ)
            local dirX = dirX / width
            local dirZ = dirZ / width
            local i = 1
            for i = i, workArea.numSubDivisions do
                (function(subSectionData, x, y, z, dirX, dirZ)
                    -- upvalues: (copy) self, (copy) spec, (ref) fillType, (ref) sprayType
                    local lx, ly, lz = worldToLocal(self.rootNode, x, y, z)
                    local vx, _, vz = getVelocityAtLocalPos(self.rootNode, lx, ly, lz)
                    subSectionData.lastSpeed = MathUtil.vector2Length(vx, vz) * 3.6
                    subSectionData.isValid = spec.isLiming or spec.isFertilizing
                    subSectionData.isUncovered = spec.isLiming or spec.isFertilizing
                    local fruitTypeDesc, _
                    if spec.isLiming then
                        local foundUncovered
                        fruitTypeDesc, _, foundUncovered = spec.pHMap:getNextValidDetectionPoint(x, z, dirX, dirZ, 10, fillType)
                        if fruitTypeDesc == nil then
                            subSectionData.isValid = false
                            _ = z
                            fruitTypeDesc = x
                        end
                        if not foundUncovered then
                            subSectionData.isUncovered = false
                        end
                    else
                        _ = z
                        fruitTypeDesc = x
                    end
                    if spec.isFertilizing then
                        local foundUncovered
                        fruitTypeDesc, _, foundUncovered = spec.nitrogenMap:getNextValidDetectionPoint(x, z, dirX, dirZ, 10, fillType)
                        if fruitTypeDesc == nil then
                            subSectionData.isValid = false
                            _ = z
                            fruitTypeDesc = x
                        end
                        if not foundUncovered then
                            subSectionData.isUncovered = false
                        end
                    end
                    local _ = x - subSectionData.lastDetectionX
                    if math.abs(_) <= 0.01 then
                        if math.abs(z - subSectionData.lastDetectionZ) <= 0.01 then
                            ::l17::
                            return
                        end
                    end
                    subSectionData.soilTypeIndex = spec.soilMap:getTypeIndexAtWorldPos(fruitTypeDesc, _)
                    if subSectionData.soilTypeIndex == 0 then
                        subSectionData.isValid = false
                    end
                    if spec.isLiming then
                        subSectionData.phLevel = spec.pHMap:getLevelAtWorldPos(fruitTypeDesc, _)
                        subSectionData.phTargetLevel = spec.pHMap:getOptimalPHValueForSoilTypeIndex(subSectionData.soilTypeIndex) or subSectionData.phLevel
                    end
                    if spec.isFertilizing then
                        subSectionData.nitrogenLevel = spec.nitrogenMap:getLevelAtWorldPos(fruitTypeDesc, _)
                        if self.spec_sowingMachine == nil then
                            local fruitTypeDesc, _ = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
                            subSectionData.fruitTypeIndex = fruitTypeDesc
                            subSectionData.growthState = _
                            subSectionData.fruitTypeIndex = subSectionData.fruitTypeIndex or FruitType.UNKNOWN
                            subSectionData.growthState = subSectionData.growthState or 0
                            if subSectionData.fruitTypeIndex ~= FruitType.UNKNOWN then
                                local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(subSectionData.fruitTypeIndex)
                                if subSectionData.growthState > fruitTypeDesc.maxHarvestingGrowthState then
                                    subSectionData.fruitTypeIndex = FruitType.UNKNOWN
                                end
                            end
                        else
                            subSectionData.fruitTypeIndex = self.spec_sowingMachine.seeds[self.spec_sowingMachine.currentSeed]
                            subSectionData.growthState = 0
                        end
                        local fruitTypeDesc, _ = spec.nitrogenMap:getNitrogenApplicationRate(subSectionData.nitrogenLevel, subSectionData.fruitTypeIndex, subSectionData.soilTypeIndex, sprayType)
                        subSectionData.nitrogenTargetLevel = subSectionData.nitrogenLevel + (fruitTypeDesc or 0)
                    end
                    subSectionData.lastDetectionX = x
                    subSectionData.lastDetectionZ = z
                    goto l17
                end)(workArea.subSectionData[i], worldStartX + dirX * (i - 0.5) * (width / workArea.numSubDivisions), y, worldStartZ + dirZ * (i - 0.5) * (width / workArea.numSubDivisions), worldStartX, y)
            end
        else
            local dirX = worldWidthX - worldStartX
            local dirZ = worldWidthZ - worldStartZ
            local width = MathUtil.vector2Length(dirX, dirZ)
            local dirX = dirX / width
            local dirZ = dirZ / width
            local i = 1
            for i = i, workArea.numSubDivisions do
                checkSubSectionPos(workArea.subSectionData[i], worldStartX + dirX * (i - 0.5) * (width / workArea.numSubDivisions), y, worldStartZ + dirZ * (i - 0.5) * (width / workArea.numSubDivisions), worldStartX, y)
            end
            local dirX = worldHeightX - worldStartX
            local dirZ = worldHeightZ - worldStartZ
            local dirX = dirX / _
            local dirZ = dirZ / _
            local i = 1
            for i = i, MathUtil.vector2Length(dirX, dirZ) do
                checkSubSectionPos(workArea.subSectionData[i + workArea.numSubDivisions], worldStartX + dirX * (i - 0.5) * (_ / workArea.numSubDivisions), y, worldStartZ + dirZ * (i - 0.5) * (_ / workArea.numSubDivisions), worldStartX, y)
            end
        end
        workArea.nitrogenLevel = 0
        workArea.nitrogenLevelMax = 0
        workArea.nitrogenTargetLevel = 0
        workArea.phLevel = 0
        workArea.phLevelMax = 0
        workArea.phTargetLevel = 0
        workArea.lastSpeed = 0
        workArea.fruitTypeIndex = 0
        workArea.growthState = 0
        workArea.soilTypeIndex = 0
        workArea.isPrecisionFarmingDataUncovered = false
        if workArea.numSubSections > 0 then
            for subSectionWidth, _ in ipairs(workArea.fruitTypes) do
                workArea.fruitTypes[subSectionWidth] = 0
            end
            for subSectionWidth, _ in ipairs(workArea.soilTypes) do
                workArea.soilTypes[subSectionWidth] = 0
            end
            local dirX = 0
            local dirZ = 0
            local width = workArea.numSubSections
            local subSectionWidth = 1
            for _ = 1, width, subSectionWidth do
                local subSectionData = workArea.subSectionData[_]
                if subSectionData.isValid then
                    workArea.nitrogenLevel = workArea.nitrogenLevel + subSectionData.nitrogenLevel
                    local subSectionData = workArea.nitrogenLevelMax
                    workArea.nitrogenLevelMax = math.max(subSectionData, subSectionData.nitrogenLevel)
                    workArea.phLevel = workArea.phLevel + subSectionData.phLevel
                    local subSectionData = workArea.phLevelMax
                    workArea.phLevelMax = math.max(subSectionData, subSectionData.phLevel)
                    workArea.phTargetLevel = workArea.phTargetLevel + subSectionData.phTargetLevel
                    workArea.lastSpeed = workArea.lastSpeed + subSectionData.lastSpeed
                    if subSectionData.fruitTypeIndex ~= nil and subSectionData.fruitTypeIndex ~= FruitType.UNKNOWN then
                        workArea.fruitTypes[subSectionData.fruitTypeIndex] = workArea.fruitTypes[subSectionData.fruitTypeIndex] + 1
                        workArea.nitrogenTargetLevel = workArea.nitrogenTargetLevel + subSectionData.nitrogenTargetLevel
                    end
                    local subSectionData = workArea.growthState
                    workArea.growthState = math.max(subSectionData, subSectionData.growthState)
                    if subSectionData.soilTypeIndex ~= nil and subSectionData.soilTypeIndex ~= 0 then
                        workArea.soilTypes[subSectionData.soilTypeIndex] = workArea.soilTypes[subSectionData.soilTypeIndex] + 1
                    end
                end
                if subSectionData.isUncovered then
                    workArea.isPrecisionFarmingDataUncovered = true
                end
            end
            if dirX > 0 then
                local subSectionWidth = workArea.nitrogenLevel / dirX
                workArea.nitrogenLevel = math.ceil(subSectionWidth)
                local subSectionWidth = workArea.phLevel / dirX
                workArea.phLevel = math.ceil(subSectionWidth)
                local subSectionWidth = workArea.phTargetLevel / dirX
                workArea.phTargetLevel = math.ceil(subSectionWidth)
                if dirZ > 0 then
                    workArea.nitrogenTargetLevel = math.ceil(workArea.nitrogenTargetLevel / dirZ)
                end
                workArea.lastSpeed = MathUtil.round(workArea.lastSpeed / dirX)
            else
                for _ = 1, workArea.numSubSections do
                    local subSectionData = workArea.subSectionData[_]
                    workArea.nitrogenLevel = workArea.nitrogenLevel + subSectionData.nitrogenLevel
                    local subSectionData = workArea.nitrogenLevelMax
                    workArea.nitrogenLevelMax = math.max(subSectionData, subSectionData.nitrogenLevel)
                    workArea.nitrogenTargetLevel = workArea.nitrogenTargetLevel + subSectionData.nitrogenTargetLevel
                    workArea.phLevel = workArea.phLevel + subSectionData.phLevel
                    local subSectionData = workArea.phLevelMax
                    workArea.phLevelMax = math.max(subSectionData, subSectionData.phLevel)
                    workArea.phTargetLevel = workArea.phTargetLevel + subSectionData.phTargetLevel
                    if subSectionData.fruitTypeIndex ~= nil and subSectionData.fruitTypeIndex ~= FruitType.UNKNOWN then
                        workArea.fruitTypes[subSectionData.fruitTypeIndex] = workArea.fruitTypes[subSectionData.fruitTypeIndex] + 1
                    end
                    local subSectionData = workArea.growthState
                    workArea.growthState = math.max(subSectionData, subSectionData.growthState)
                    if subSectionData.soilTypeIndex ~= nil and subSectionData.soilTypeIndex ~= 0 then
                        workArea.soilTypes[subSectionData.soilTypeIndex] = workArea.soilTypes[subSectionData.soilTypeIndex] + 1
                    end
                end
                workArea.nitrogenLevel = math.ceil(workArea.nitrogenLevel / workArea.numSubSections)
                workArea.nitrogenTargetLevel = math.ceil(workArea.nitrogenTargetLevel / workArea.numSubSections)
                workArea.phLevel = math.ceil(workArea.phLevel / workArea.numSubSections)
                workArea.phTargetLevel = math.ceil(workArea.phTargetLevel / workArea.numSubSections)
            end
            local width = 0
            local subSectionWidth = 0
            for subSectionData, checkX in ipairs(workArea.soilTypes) do
                if subSectionWidth < checkX then
                    width = subSectionData
                    subSectionWidth = checkX
                end
            end
            workArea.soilTypeIndex = width
            spec.lastTouchedSoilType = workArea.soilTypeIndex
            if self.spec_sowingMachine == nil then
                local _ = 0
                local subSectionData = 0
                for checkZ, count in ipairs(workArea.fruitTypes) do
                    if subSectionData < count then
                        _ = checkZ
                        subSectionData = count
                    end
                end
                workArea.fruitTypeIndex = _
                if workArea.fruitTypeIndex == FruitType.UNKNOWN then
                    local i = spec.nApplyAutoModeFruitRequirementDefaultIndex
                    local subSectionData, checkX = spec.nitrogenMap:getNitrogenApplicationRate(workArea.nitrogenLevel, i, workArea.soilTypeIndex, sprayType)
                    workArea.nitrogenTargetLevel = workArea.nitrogenLevel + (subSectionData or 0)
                    local i = 1
                    for i = i, workArea.numSubSections do
                        local subSectionData = workArea.subSectionData[i]
                        if subSectionData.isValid then
                            subSectionData.nitrogenTargetLevel = workArea.nitrogenTargetLevel
                            subSectionData.fruitTypeIndex = workArea.fruitTypeIndex
                        end
                    end
                end
            else
                workArea.fruitTypeIndex = self.spec_sowingMachine.seeds[self.spec_sowingMachine.currentSeed]
            end
            if workArea.maxNApplicationOffset > 0 and workArea.nitrogenLevel < workArea.nitrogenTargetLevel then
                local _ = workArea.nitrogenLevelMax - workArea.nitrogenLevel
                if _ > 0 and _ <= workArea.maxNApplicationOffset + 0.01 then
                    workArea.nitrogenLevel = workArea.nitrogenLevelMax
                end
            end
            if workArea.maxPHApplicationOffset > 0 and workArea.phLevel < workArea.phTargetLevel then
                local _ = workArea.phLevelMax - workArea.phLevel
                if _ > 0 and _ <= workArea.maxPHApplicationOffset + 0.01 then
                    workArea.phLevel = workArea.phLevelMax
                end
            end
            local i = 1
            local subSectionData = 1
            for i = i, workArea.numSubSections, subSectionData do
                local subSectionData = workArea.subSectionData[i]
                if not subSectionData.isValid then
                    subSectionData.nitrogenLevel = workArea.nitrogenLevel
                    subSectionData.nitrogenTargetLevel = workArea.nitrogenTargetLevel
                    subSectionData.phLevel = workArea.phLevel
                    subSectionData.phTargetLevel = workArea.phTargetLevel
                    subSectionData.fruitTypeIndex = workArea.fruitTypeIndex
                    subSectionData.soilTypeIndex = workArea.soilTypeIndex
                end
            end
            if spec.lastTouchedSoilTypeSent ~= spec.lastTouchedSoilType then
                self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
                spec.lastTouchedSoilTypeSent = spec.lastTouchedSoilType
            end
            spec.phActualValue = workArea.phLevel
            spec.phTargetValue = spec.pHMap:getOptimalPHValueForSoilTypeIndex(workArea.soilTypeIndex) or workArea.phLevel
            if spec.phActualValue ~= spec.phActualValueSent or spec.phTargetValue ~= spec.phTargetValueSent then
                self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
                spec.phActualValueSent = spec.phActualValue
                spec.phTargetValueSent = spec.phTargetValue
            end
            spec.nActualValue = workArea.nitrogenLevel
            local _ = FruitType.UNKNOWN
            if workArea.fruitTypeIndex ~= FruitType.UNKNOWN then
                local subSectionData, i = spec.nitrogenMap:getNitrogenApplicationRate(workArea.nitrogenLevel, workArea.fruitTypeIndex, workArea.soilTypeIndex, self.spec_sprayer.workAreaParameters.sprayType)
                if i then
                    _ = workArea.fruitTypeIndex
                end
            end
            spec.nTargetValue = workArea.nitrogenTargetLevel
            if spec.nActualValue ~= spec.nActualValueSent or spec.nTargetValue ~= spec.nTargetValueSent then
                self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
                spec.nActualValueSent = spec.nActualValue
                spec.nTargetValueSent = spec.nTargetValue
            end
            self:setSprayAmountAutoFruitTypeIndex(_)
            if spec.nApplyAutoModeFruitType ~= spec.nApplyAutoModeFruitTypeSent then
                self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
                spec.nApplyAutoModeFruitTypeSent = spec.nApplyAutoModeFruitType
            end
        end
    end
end
function ExtendedSprayer:processWorkAreaSubSectionData(workArea)
    if workArea.subSectionData ~= nil then
        local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
        local specSpray = self.spec_sprayer
        local sprayType = specSpray.workAreaParameters.sprayType
        local sprayVehicle = specSpray.workAreaParameters.sprayVehicle
        if sprayVehicle == nil then
            sprayVehicle = ExtendedSprayer.getFillTypeSourceVehicle(self)
        end
        local phDelta = 0
        if spec.isLiming then
            if spec.sprayAmountAutoMode then
                if workArea.soilTypeIndex == 0 then
                    phDelta = spec.pHMap:getDefaultLimeStateChange()
                else
                    phDelta = math.max(spec.phTargetValue - workArea.phLevel, 0)
                end
            else
                phDelta = spec.sprayAmountManual
            end
            if phDelta == 0 and not spec.pwmEnabled then
                return
            end
        end
        local nitrogenDelta = 0
        if spec.isFertilizing then
            if spec.sprayAmountAutoMode then
                if workArea.soilTypeIndex == 0 then
                    nitrogenDelta = spec.nitrogenMap:getDefaultNitrogenStateChange()
                else
                    nitrogenDelta = math.max(spec.nTargetValue - workArea.nitrogenLevel, 0)
                end
            else
                nitrogenDelta = spec.sprayAmountManual
            end
            if nitrogenDelta == 0 and not spec.pwmEnabled then
                return
            end
        end
        local speedLimit = self:getRawSpeedLimit()
        local function processSubSectionPos(subSectionData, shape)
            -- upvalues: (copy) spec, (copy) sprayType, (ref) phDelta, (ref) sprayVehicle, (ref) nitrogenDelta, (copy) speedLimit
            if spec.isLiming then
                if spec.sprayAmountAutoMode then
                    spec.pHMap:updatePHLevelAtArea(shape, sprayType, subSectionData.phTargetLevel)
                else
                    spec.pHMap:addPHLevelAtArea(shape, sprayType, phDelta)
                end
            end
            if spec.isFertilizing then
                local levelOffset = 0
                if sprayVehicle.getCurrentNitrogenLevelOffset ~= nil then
                    levelOffset = sprayVehicle:getCurrentNitrogenLevelOffset(subSectionData.nitrogenTargetLevel - subSectionData.nitrogenLevel)
                end
                if spec.pwmEnabled then
                    if spec.sprayAmountAutoMode then
                        spec.nitrogenMap:updateNitrogenLevelAtArea(shape, sprayType, subSectionData.nitrogenTargetLevel + levelOffset)
                    else
                        spec.nitrogenMap:addNitrogenLevelAtArea(shape, sprayType, nitrogenDelta)
                    end
                end
                local speedDifference = 1
                if spec.pHMap.realisticSpreadOutputEnabled and not spec.speedDependentApplication then
                    local subSectionDelta = 1 / math.max(subSectionData.lastSpeed / speedLimit, 0.01)
                    speedDifference = math.min(subSectionDelta, 2)
                end
                local applicationOffset = 0
                if spec.pHMap.realisticSpreadPatternEnabled then
                    applicationOffset = subSectionData.nApplicationOffset
                end
                local subSectionDelta = MathUtil.round(nitrogenDelta * speedDifference) + levelOffset + applicationOffset
                local subSectionDelta = math.max(subSectionDelta, 1)
                spec.nitrogenMap:addNitrogenLevelAtArea(shape, sprayType, subSectionDelta)
            end
        end
        local worldStartX, _, worldStartZ = getWorldTranslation(workArea.start)
        local worldWidthX, _, worldWidthZ = getWorldTranslation(workArea.width)
        local worldHeightX, _, worldHeightZ = getWorldTranslation(workArea.height)
        if workArea.numMainDivisions == 1 then
            local dirX = worldWidthX - worldStartX
            local dirZ = worldWidthZ - worldStartZ
            local width = MathUtil.vector2Length(dirX, dirZ)
            local dirX = dirX / width
            local dirZ = dirZ / width
            local i = 1
            for i = i, workArea.numSubDivisions do
                spec.densityMapParallelogram:updateFromWorldPositions(worldStartX + dirX * (i - 1) * (width / workArea.numSubDivisions), worldStartZ + dirZ * (i - 1) * subSectionWidth, worldStartX + dirX * i * subSectionWidth, worldStartZ + dirZ * i * subSectionWidth, worldHeightX + dirX * (i - 1) * subSectionWidth, worldHeightZ + dirZ * (i - 1) * subSectionWidth)
                processSubSectionPos(workArea.subSectionData[i], spec.densityMapParallelogram)
            end
        else
            local dirX = worldStartX + (worldWidthX - worldStartX) + (worldHeightX - worldStartX)
            local dirZ = worldStartZ + (worldWidthZ - worldStartZ) + (worldHeightZ - worldStartZ)
            local width = worldWidthX - dirX
            local subSectionWidth = worldWidthZ - dirZ
            local cornerDistance = MathUtil.vector2Length(width, subSectionWidth)
            local width = width / cornerDistance
            local subSectionWidth = subSectionWidth / cornerDistance
            local widthDirX = worldWidthX - worldStartX
            local i = worldWidthZ - worldStartZ
            local subSectionData = MathUtil.vector2Length(widthDirX, i)
            local widthDirX = widthDirX / subSectionData
            local i = i / subSectionData
            local hx = 1
            local wx = workArea.numSubDivisions
            local wz = 1
            for hx = hx, wx, wz do
                spec.densityMapPolygon:setPolygonPoint(1, worldStartX + widthDirX * hx * (subSectionData / workArea.numSubDivisions), worldStartZ + i * hx * sx)
                spec.densityMapPolygon:setPolygonPoint(2, worldStartX + widthDirX * (hx - 1) * sx, worldStartZ + i * (hx - 1) * sx)
                spec.densityMapPolygon:setPolygonPoint(3, dirX + width * (hx - 1) * (cornerDistance / workArea.numSubDivisions), dirZ + subSectionWidth * (hx - 1) * sz)
                spec.densityMapPolygon:setPolygonPoint(4, dirX + width * hx * sz, dirZ + subSectionWidth * hx * sz)
                processSubSectionPos(workArea.subSectionData[hx], spec.densityMapPolygon)
            end
            local wx = worldHeightX - worldStartX
            local wz = worldHeightZ - worldStartZ
            local hx = MathUtil.vector2Length(wx, wz)
            local wx = wx / hx
            local wz = wz / hx
            local width = worldHeightX - dirX
            local subSectionWidth = worldHeightZ - dirZ
            local hz = MathUtil.vector2Length(width, subSectionWidth)
            local width = width / hz
            local subSectionWidth = subSectionWidth / hz
            local x2 = 1
            local hz = workArea.numSubDivisions
            local z1 = 1
            for x2 = x2, hz, z1 do
                spec.densityMapPolygon:setPolygonPoint(1, worldStartX + wx * x2 * (hx / workArea.numSubDivisions), worldStartZ + wz * x2 * sx)
                spec.densityMapPolygon:setPolygonPoint(2, worldStartX + wx * (x2 - 1) * sx, worldStartZ + wz * (x2 - 1) * sx)
                spec.densityMapPolygon:setPolygonPoint(3, dirX + width * (x2 - 1) * (hz / workArea.numSubDivisions), dirZ + subSectionWidth * (x2 - 1) * sz)
                spec.densityMapPolygon:setPolygonPoint(4, dirX + width * x2 * sz, dirZ + subSectionWidth * x2 * sz)
                processSubSectionPos(workArea.subSectionData[x2 + workArea.numSubDivisions], spec.densityMapPolygon)
            end
        end
    end
end
function ExtendedSprayer:getSprayerUsage(superFunc, fillType, dt)
    local usage = superFunc(self, fillType, dt)
    if self:getIsTurnedOn() then
        local specSpray = self.spec_sprayer
        local usageScale = specSpray.usageScale
        local activeSprayType = self:getActiveSprayType()
        if activeSprayType ~= nil then
            usageScale = activeSprayType.usageScale
        end
        local workWidth
        if usageScale.workAreaIndex == nil then
            workWidth = usageScale.workingWidth
        else
            workWidth = self:getWorkAreaWidth(usageScale.workAreaIndex)
        end
        local spec = self:getLastSpeed()
        local lastSpeed = math.max(spec, 1)
        local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
        local dataUncovered = false
        for _, workArea in pairs(spec.workAreas) do
            if workArea.isPrecisionFarmingDataUncovered then
                dataUncovered = true
                break
            end
        end
        if spec.isLiming then
            if spec.pHMap ~= nil then
                local changeValue
                if spec.sprayAmountAutoMode then
                    if spec.pwmEnabled then
                        local accumulatedChange = 0
                        local _ = 0
                        for _, workArea in pairs(spec.workAreas) do
                            if workArea.numSubSections > 0 then
                                for _, subSectionData in ipairs(workArea.subSectionData) do
                                    accumulatedChange = accumulatedChange + math.max(subSectionData.phTargetLevel - subSectionData.phLevel, 0)
                                end
                            end
                        end
                        if _ > 0 then
                            changeValue = accumulatedChange / _
                        else
                            changeValue = 0
                        end
                    else
                        changeValue = math.ceil(spec.phTargetValue - spec.phActualValue)
                        if spec.pHMap.realisticSpreadOutputEnabled and not spec.speedDependentApplication then
                            lastSpeed = self:getRawSpeedLimit()
                        end
                    end
                    if not dataUncovered then
                        changeValue = spec.pHMap:getDefaultLimeStateChange()
                    end
                else
                    changeValue = math.max(spec.sprayAmountManual, 1)
                    if spec.pHMap.realisticSpreadOutputEnabled and not spec.speedDependentApplication then
                        lastSpeed = self:getRawSpeedLimit()
                    end
                end
                if self.getNumExtendedSprayerNozzleEffectsActive ~= nil then
                    local accumulatedChange, _ = self:getNumExtendedSprayerNozzleEffectsActive()
                end
                local _, workArea
                usage, _, workArea = spec.pHMap:getLimeUsage(workWidth, lastSpeed, changeValue, dt)
                spec.lastRegularUsage = workArea
                spec.lastLitersPerHectar = _
                spec.lastNitrogenProportion = 0
            end
        elseif spec.isFertilizing and spec.nitrogenMap ~= nil then
            if spec.isDoingMissionWork then
                spec.lastRegularUsage = usage
                spec.lastLitersPerHectar = usage / dt * (10000 / workWidth) / (self.speedLimit / 3600)
                spec.lastNitrogenProportion = 0
            else
                local changeValue = specSpray.workAreaParameters.sprayVehicle
                if changeValue == nil then
                    changeValue = ExtendedSprayer.getFillTypeSourceVehicle(self)
                end
                local accumulatedChange
                if spec.sprayAmountAutoMode then
                    if spec.pwmEnabled then
                        local _ = 0
                        local workArea = 0
                        for workArea, workArea in pairs(spec.sprayerWorkAreas) do
                            if workArea.numSubSections > 0 then
                                for subSectionData, subSectionData in ipairs(workArea.subSectionData) do
                                    _ = _ + math.max(subSectionData.nitrogenTargetLevel - subSectionData.nitrogenLevel, 0)
                                end
                            end
                        end
                        for workArea, workArea in pairs(spec.sowingMachineWorkAreas) do
                            if workArea.numSubSections > 0 then
                                for subSectionData, subSectionData in ipairs(workArea.subSectionData) do
                                    _ = _ + math.max(subSectionData.nitrogenTargetLevel - subSectionData.nitrogenLevel, 0)
                                end
                            end
                        end
                        if workArea > 0 then
                            accumulatedChange = _ / workArea
                        else
                            accumulatedChange = 0
                        end
                    else
                        accumulatedChange = math.ceil(spec.nTargetValue - spec.nActualValue)
                        if spec.pHMap.realisticSpreadOutputEnabled and not spec.speedDependentApplication then
                            lastSpeed = self:getRawSpeedLimit()
                        end
                    end
                    if not dataUncovered then
                        accumulatedChange = spec.nitrogenMap:getDefaultNitrogenStateChange()
                    end
                else
                    accumulatedChange = math.max(spec.sprayAmountManual, 1)
                    if spec.pHMap.realisticSpreadOutputEnabled and not spec.speedDependentApplication then
                        lastSpeed = self:getRawSpeedLimit()
                    end
                end
                if self.getNumExtendedSprayerNozzleEffectsActive ~= nil then
                    local _, workArea = self:getNumExtendedSprayerNozzleEffectsActive()
                end
                local _ = changeValue ~= nil and changeValue.getCurrentNitrogenUsageLevelOffset ~= nil and changeValue:getCurrentNitrogenUsageLevelOffset(accumulatedChange) or 0
                local literPerHectar, regularUsage, _
                usage, literPerHectar, regularUsage, _ = spec.nitrogenMap:getFertilizerUsage(workWidth, lastSpeed, math.max(accumulatedChange, spec.sprayAmountAutoMode and 0 or 1), fillType, dt, spec.sprayAmountAutoMode, spec.nApplyAutoModeFruitType, spec.nActualValue, _)
                spec.lastRegularUsage = regularUsage
                spec.lastLitersPerHectar = literPerHectar
                spec.lastNitrogenProportion = _
            end
        end
        if self:getIsAIActive() then
            usage = usage == 0 and 0.0001 or usage
        end
    end
    return usage
end
function ExtendedSprayer:processSprayerArea(superFunc, workArea, dt)
    local specSpray = self.spec_sprayer
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    if specSpray.workAreaParameters.sprayFillLevel <= 0 then
        return superFunc(self, workArea, dt)
    end
    if not (spec.isLiming or spec.isFertilizing) then
        return superFunc(self, workArea, dt)
    end
    local sx, _, sz = getWorldTranslation(workArea.start)
    local wx, _, wz = getWorldTranslation(workArea.width)
    local hx, _, hz = getWorldTranslation(workArea.height)
    if not self.isServer then
        local changedArea = 0
        local totalArea = 0
        if self:getIsPrecisionSprayingRequired() then
            changedArea, totalArea = superFunc(self, workArea, dt)
            if changedArea > 0 then
                spec.nitrogenMap:setMinimapRequiresUpdate(true)
            end
        end
        local desc = g_sprayTypeManager:getSprayTypeByIndex(specSpray.workAreaParameters.sprayType)
        if desc ~= nil then
            FSDensityMapUtil.setGroundTypeLayerArea(sx, sz, wx, wz, hx, hz, desc.sprayGroundType)
        end
        return changedArea, totalArea
    end
    if specSpray.workAreaParameters.sprayType ~= workArea.lastSprayTypeIndex then
        workArea.lastSprayTypeIndex = specSpray.workAreaParameters.sprayType
        self:updateWorkAreaSubSectionData(workArea)
    end
    spec.densityMapParallelogram:updateFromWorldPositions(sx, sz, wx, wz, hx, hz)
    if spec.isLiming then
        spec.pHMap:preUpdatePHLevelAtArea(spec.densityMapParallelogram, specSpray.workAreaParameters.sprayType)
    end
    if spec.isFertilizing then
        spec.nitrogenMap:preUpdateNitrogenLevelAtArea(spec.densityMapParallelogram, specSpray.workAreaParameters.sprayType)
    end
    self:processWorkAreaSubSectionData(workArea)
    local changedArea = 0
    local totalArea = 0
    if self:getIsPrecisionSprayingRequired() then
        changedArea, totalArea = superFunc(self, workArea, dt)
        if changedArea > 0 then
            spec.nitrogenMap:setMinimapRequiresUpdate(true)
        end
    end
    local desc = g_sprayTypeManager:getSprayTypeByIndex(specSpray.workAreaParameters.sprayType)
    if desc ~= nil then
        FSDensityMapUtil.setGroundTypeLayerArea(sx, sz, wx, wz, hx, hz, desc.sprayGroundType)
    end
    return changedArea, totalArea
end
function ExtendedSprayer:changeSeedIndex(superFunc, ...)
    superFunc(self, ...)
    self[ExtendedSprayer.SPEC_TABLE_NAME].lastGroundUpdateDistance = math.huge
end
function ExtendedSprayer:getSprayerDoubledAmountActive(superFunc, sprayTypeIndex)
    return false, false
end
function ExtendedSprayer:updateSprayerEffects(superFunc, force) end
function ExtendedSprayer:updateExtendedSprayerNozzleEffectState(superFunc, effectData, dt, isTurnedOn, lastSpeed)
    local isActive, amountScale = superFunc(self, effectData, dt, isTurnedOn, lastSpeed)
    if isActive then
        local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
        if (spec.pwmEnabled or spec.spotSprayEnabled) and (spec.isLiming or spec.isFertilizing) then
            local x, y, z = localToWorld(effectData.effectNode, 0, 0, 1)
            local densityBitsGround = getDensityAtWorldPos(spec.groundTypeMapId, x, y, z)
            local groundType = bit32.rshift(densityBitsGround, spec.groundTypeFirstChannel)
            local groundTypeValue = bit32.band(groundType, 2 ^ spec.groundTypeNumChannels - 1)
            if FieldGroundType.getTypeByValue(groundTypeValue) == FieldGroundType.NONE then
                isActive = false
            end
        end
    end
    return isActive, amountScale
end
function ExtendedSprayer:setSprayerAITerrainDetailProhibitedRange(superFunc, fillType)
    superFunc(self, fillType)
    if self:getUseSprayerAIRequirements() and self.addAITerrainDetailProhibitedRange ~= nil then
        self:clearAIFruitProhibitions()
        local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
        if sprayTypeDesc ~= nil then
            if sprayTypeDesc.isFertilizer then
                local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
                self:addAIFruitProhibitions(0, sprayTypeDesc.sprayGroundType, sprayTypeDesc.sprayGroundType, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
            elseif sprayTypeDesc.isLime then
                local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
                self:addAIFruitProhibitions(0, sprayTypeDesc.sprayGroundType, sprayTypeDesc.sprayGroundType, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
            end
            if sprayTypeDesc.isHerbicide or (sprayTypeDesc.isFertilizer or sprayTypeDesc.isLime) then
                for sprayTypeNumChannels, fruitType in pairs(g_fruitTypeManager:getFruitTypes()) do
                    if fruitType.terrainDataPlaneId ~= nil and (string.lower(fruitType.name) ~= "grass" and (fruitType.minHarvestingGrowthState ~= nil and fruitType.maxHarvestingGrowthState ~= nil)) then
                        self:addAIFruitProhibitions(fruitType.index, fruitType.minHarvestingGrowthState, fruitType.maxHarvestingGrowthState)
                    end
                end
            end
        end
    end
end
function ExtendedSprayer:preProcessExtUnderRootFertilizerArea(workArea, _)
    if self.isServer then
        local sx, _, sz = getWorldTranslation(workArea.start)
        local wx, _, wz = getWorldTranslation(workArea.width)
        local hx, _, hz = getWorldTranslation(workArea.height)
        if self[ExtendedSprayer.SPEC_TABLE_NAME].nitrogenMap ~= nil then
            spec.densityMapParallelogram:updateFromWorldPositions(sx, sz, wx, wz, hx, hz)
            spec.nitrogenMap:preUpdateNitrogenLevelAtArea(spec.densityMapParallelogram, SprayType.FERTILIZER)
            self:processWorkAreaSubSectionData(workArea)
        end
    end
end
function ExtendedSprayer:onEndWorkAreaProcessing(_, _)
    local specSprayer = self.spec_sprayer
    if self.isServer and specSprayer.workAreaParameters.isActive then
        if (specSprayer.workAreaParameters.sprayVehicle ~= nil or self:getIsAIActive()) and self:getIsTurnedOn() then
            if specSprayer.workAreaParameters.sprayFillType == FillType.LIME then
                self:updatePFStatistic("usedLime", specSprayer.workAreaParameters.usage)
                self:updatePFStatistic("usedLimeRegular", self[ExtendedSprayer.SPEC_TABLE_NAME].lastRegularUsage)
                return
            end
            if fillType == FillType.FERTILIZER then
                self:updatePFStatistic("usedMineralFertilizer", usage)
                self:updatePFStatistic("usedMineralFertilizerRegular", usageRegular)
                return
            end
            if fillType == FillType.LIQUIDFERTILIZER then
                self:updatePFStatistic("usedLiquidFertilizer", usage)
                self:updatePFStatistic("usedLiquidFertilizerRegular", usageRegular)
                return
            end
            if fillType == FillType.MANURE then
                self:updatePFStatistic("usedManure", usage)
                self:updatePFStatistic("usedManureRegular", usageRegular)
                return
            end
            if fillType == FillType.LIQUIDMANURE or fillType == FillType.DIGESTATE then
                self:updatePFStatistic("usedLiquidManure", usage)
                self:updatePFStatistic("usedLiquidManureRegular", usageRegular)
            end
        end
    end
end
function ExtendedSprayer:setSprayAmountAutoMode(state, noEventSend)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    if state == nil then
        state = not spec.sprayAmountAutoMode
    end
    if not spec.sprayAmountAutoModeChangeAllowed then
        state = false
    end
    spec.sprayAmountAutoMode = state
    ExtendedSprayer.updateActionEventState(self)
    ExtendedSprayer.updateActionEventAutoModeDefault(self)
    ExtendedSprayerAmountEvent.sendEvent(self, spec.sprayAmountAutoMode, spec.sprayAmountManual, noEventSend)
end
function ExtendedSprayer:setSprayAmountManualValue(value, noEventSend)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    spec.sprayAmountManual = math.clamp(value, spec.sprayAmountManualMin, spec.sprayAmountManualMax)
    ExtendedSprayer.updateActionEventState(self)
    ExtendedSprayerAmountEvent.sendEvent(self, spec.sprayAmountAutoMode, spec.sprayAmountManual, noEventSend)
end
function ExtendedSprayer:setSprayAmountAutoFruitTypeIndex(index)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    if index ~= spec.nApplyAutoModeFruitType then
        spec.nApplyAutoModeFruitType = index
        spec.nApplyAutoModeFruitTypeRequiresDefaultMode = spec.nitrogenMap:getFruitTypeRequirementRequiresDefaultMode(index)
        ExtendedSprayer.updateActionEventAutoModeDefault(self)
    end
end
function ExtendedSprayer:setSprayAmountDefaultFruitRequirementIndex(index, noEventSend)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    spec.nApplyAutoModeFruitRequirementDefaultIndex = index
    spec.lastGroundUpdateDistance = math.huge
    ExtendedSprayerDefaultFruitTypeEvent.sendEvent(self, index, noEventSend)
end
function ExtendedSprayer:updateDebugValues(values)
    local spec = self[ExtendedSprayer.SPEC_TABLE_NAME]
    for i, workArea in pairs(spec.sprayerWorkAreas) do
        local isAllowed = true
        if workArea.sprayType ~= nil then
            local sprayType = self:getActiveSprayType()
            if sprayType ~= nil and sprayType.index ~= workArea.sprayType then
                isAllowed = false
            end
        end
        if isAllowed then
            (function(workArea, name)
                -- upvalues: (copy) spec, (copy) values
                if workArea.subSectionData ~= nil then
                    local nitrogenValue = spec.nitrogenMap:getNitrogenValueFromInternalValue(workArea.nitrogenLevel)
                    local nitrogenTargetValue = spec.nitrogenMap:getNitrogenValueFromInternalValue(workArea.nitrogenTargetLevel)
                    local phValue = spec.pHMap:getPhValueFromInternalValue(workArea.phLevel)
                    local phTargetValue = spec.pHMap:getPhValueFromInternalValue(workArea.phTargetLevel)
                    local fruitTypeName = g_fruitTypeManager:getFruitTypeNameByIndex(workArea.fruitTypeIndex)
                    local soilType = spec.soilMap:getSoilTypeByIndex(workArea.soilTypeIndex)
                    local soilTypeName = soilType == nil and "Unknown" or soilType.name
                    table.insert(values, {
                        ["name"] = string.format("Detected (%s)", name),
                        ["value"] = string.format("N %dkg pH %.3f FruitType: %s|%d Soil: %s (Target: N: %dkg | pH %.3f)", nitrogenValue, phValue, fruitTypeName, workArea.growthState, soilTypeName, nitrogenTargetValue, phTargetValue)
                    })
                    for subSectionDataIndex, subSectionData in ipairs(workArea.subSectionData) do
                        local fruitTypeName = g_fruitTypeManager:getFruitTypeNameByIndex(subSectionData.fruitTypeIndex)
                        local nitrogenValue = spec.nitrogenMap:getNitrogenValueFromInternalValue(subSectionData.nitrogenLevel)
                        local nitrogenTargetValue = spec.nitrogenMap:getNitrogenValueFromInternalValue(subSectionData.nitrogenTargetLevel)
                        local phValue = spec.pHMap:getPhValueFromInternalValue(subSectionData.phLevel)
                        local phTargetValue = spec.pHMap:getPhValueFromInternalValue(subSectionData.phTargetLevel)
                        local soilType = spec.soilMap:getSoilTypeByIndex(subSectionData.soilTypeIndex)
                        table.insert(values, {
                            ["name"] = string.format("Sub Section %d", subSectionDataIndex),
                            ["value"] = string.format("%dkg/%dkg pH %.3f/%.3f FruitType: %s|%d Soil: %s Speed: %.2fkm/h (%s)", nitrogenValue, nitrogenTargetValue, phValue, phTargetValue, fruitTypeName, subSectionData.growthState, soilType == nil and "Unknown" or soilType.name, subSectionData.lastSpeed, subSectionData.isValid and "Valid" or "Invalid")
                        })
                    end
                end
            end)(workArea, "SPRAYER" .. tostring(i))
        end
    end
    for i, workArea in pairs(spec.sowingMachineWorkAreas) do
        addWorkArea(workArea, "SOWINGMACHINE" .. tostring(i))
    end
    for i, workArea in pairs(spec.cultivatorWorkAreas) do
        addWorkArea(workArea, "CULTIVATOR" .. tostring(i))
    end
end