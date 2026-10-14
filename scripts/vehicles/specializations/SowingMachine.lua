source("dataS/scripts/vehicles/specializations/events/SetSeedIndexEvent.lua")
SowingMachine = {}
SowingMachine.DAMAGED_USAGE_INCREASE = 0.3
SowingMachine.AI_REQUIRED_GROUND_TYPES = {
    FieldGroundType.STUBBLE_TILLAGE,
    FieldGroundType.CULTIVATED,
    FieldGroundType.SEEDBED,
    FieldGroundType.PLOWED,
    FieldGroundType.ROLLED_SEEDBED,
    FieldGroundType.RIDGE
}
SowingMachine.AI_OUTPUT_GROUND_TYPES = {
    FieldGroundType.SOWN,
    FieldGroundType.DIRECT_SOWN,
    FieldGroundType.PLANTED,
    FieldGroundType.RIDGE_SOWN,
    FieldGroundType.ROLLER_LINES,
    FieldGroundType.HARVEST_READY,
    FieldGroundType.HARVEST_READY_OTHER,
    FieldGroundType.GRASS,
    FieldGroundType.GRASS_CUT
}
SowingMachine.CLIENT_DM_UPDATE_RADIUS = 50
function SowingMachine.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("sowingMachine", true, true, true)
    g_storeManager:addSpecType("seedFillTypes", "shopListAttributeIconSeeds", SowingMachine.loadSpecValueSeedFillTypes, SowingMachine.getSpecValueSeedFillTypes, StoreSpecies.VEHICLE)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("SowingMachine")
    schema:register(XMLValueType.BOOL, "vehicle.sowingMachine.allowFillFromAirWhileTurnedOn#value", "Allow fill from air while turned on")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.sowingMachine.directionNode#node", "Direction node")
    schema:register(XMLValueType.BOOL, "vehicle.sowingMachine.useDirectPlanting#value", "Use direct planting", false)
    schema:register(XMLValueType.BOOL, "vehicle.sowingMachine.waterSeeding#value", "Seeding in water is required or prohibited (false: prohibited, true: required)", false)
    schema:register(XMLValueType.STRING, "vehicle.sowingMachine.seedFruitTypeCategories", "Seed fruit type categories")
    schema:register(XMLValueType.STRING, "vehicle.sowingMachine.seedFruitTypes", "Seed fruit types")
    schema:register(XMLValueType.STRING, "vehicle.sowingMachine.seedFillType", "Name of seeds fill type to use", "SEEDS")
    schema:register(XMLValueType.BOOL, "vehicle.sowingMachine.needsActivation#value", "Needs activation", false)
    schema:register(XMLValueType.BOOL, "vehicle.sowingMachine.requiresFilling#value", "Requires filling", true)
    schema:register(XMLValueType.STRING, "vehicle.sowingMachine.fieldGroundType#value", "Defines the field ground type", "SOWN")
    schema:register(XMLValueType.BOOL, "vehicle.sowingMachine.fieldGroundType#ridgeSeeding", "Defines if the sowing machine can seed into created ridges or destroys them", false)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.sowingMachine.sounds", "work(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.sowingMachine.sounds", "airBlower(?)")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.sowingMachine.animationNodes")
    schema:register(XMLValueType.STRING, "vehicle.sowingMachine.changeSeedInputButton", "Input action name", "IMPLEMENT_EXTRA3")
    schema:register(XMLValueType.INT, "vehicle.sowingMachine#fillUnitIndex", "Fill unit index", 1)
    schema:register(XMLValueType.INT, "vehicle.sowingMachine#unloadInfoIndex", "Unload info index", 1)
    schema:register(XMLValueType.STRING, "vehicle.sowingMachine#defaultFruitType", "Name if fruit type that is selected by default")
    schema:register(XMLValueType.STRING, "vehicle.sowingMachine#consumableName", "Define a consumable that is emptied instead of the fill unit")
    schema:register(XMLValueType.FLOAT, "vehicle.sowingMachine#seedUsageScale", "Seed usage scale (Can be used to increase or decrease the usage for certain tools)", 1)
    EffectManager.registerEffectXMLPaths(schema, "vehicle.sowingMachine.effects")
    schema:register(XMLValueType.STRING, "vehicle.storeData.specs.seedFruitTypeCategories", "Seed fruit type categories")
    schema:register(XMLValueType.STRING, "vehicle.storeData.specs.seedFruitTypes", "Seed fruit types")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).sowingMachine#selectedSeedFruitType", "Selected fruit type name")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).sowingMachine#allowsSeedChanging", "If seed change is allowed")
end
function SowingMachine.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function SowingMachine.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setSeedFruitType", SowingMachine.setSeedFruitType)
    SpecializationUtil.registerFunction(vehicleType, "setSeedIndex", SowingMachine.setSeedIndex)
    SpecializationUtil.registerFunction(vehicleType, "changeSeedIndex", SowingMachine.changeSeedIndex)
    SpecializationUtil.registerFunction(vehicleType, "getIsSeedChangeAllowed", SowingMachine.getIsSeedChangeAllowed)
    SpecializationUtil.registerFunction(vehicleType, "setIsSeedChangeAllowed", SowingMachine.setIsSeedChangeAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getSowingMachineFillUnitIndex", SowingMachine.getSowingMachineFillUnitIndex)
    SpecializationUtil.registerFunction(vehicleType, "getSowingMachineSeedFillTypeIndex", SowingMachine.getSowingMachineSeedFillTypeIndex)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentSeedTypeIcon", SowingMachine.getCurrentSeedTypeIcon)
    SpecializationUtil.registerFunction(vehicleType, "processSowingMachineArea", SowingMachine.processSowingMachineArea)
    SpecializationUtil.registerFunction(vehicleType, "getUseSowingMachineAIRequirements", SowingMachine.getUseSowingMachineAIRequirements)
    SpecializationUtil.registerFunction(vehicleType, "setFillTypeSourceDisplayFillType", SowingMachine.setFillTypeSourceDisplayFillType)
    SpecializationUtil.registerFunction(vehicleType, "updateMissionSowingWarning", SowingMachine.updateMissionSowingWarning)
    SpecializationUtil.registerFunction(vehicleType, "getCanPlantOutsideSeason", SowingMachine.getCanPlantOutsideSeason)
    SpecializationUtil.registerFunction(vehicleType, "getSowingMachineCanConsume", SowingMachine.getSowingMachineCanConsume)
end
function SowingMachine.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", SowingMachine.getDrawFirstFillText)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", SowingMachine.getAreControlledActionsAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", SowingMachine.getFillUnitAllowsFillType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", SowingMachine.getCanBeTurnedOn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", SowingMachine.getCanToggleTurnedOn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowFillFromAir", SowingMachine.getAllowFillFromAir)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirectionSnapAngle", SowingMachine.getDirectionSnapAngle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", SowingMachine.addFillUnitFillLevel)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", SowingMachine.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", SowingMachine.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", SowingMachine.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", SowingMachine.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", SowingMachine.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", SowingMachine.getCanAIImplementContinueWork)
end
function SowingMachine.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", SowingMachine)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", SowingMachine)
end
function SowingMachine:onLoad(savegame)
    local spec = self.spec_sowingMachine
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.sowingMachine.animationNodes.animationNode", "sowingMachine")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnScrollers", "vehicle.sowingMachine.scrollerNodes.scrollerNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.useDirectPlanting", "vehicle.sowingMachine.useDirectPlanting#value")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.needsActivation#value", "vehicle.sowingMachine.needsActivation#value")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingEffects", "vehicle.sowingMachine.effects")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingEffectsWithFixedFillType", "vehicle.sowingMachine.fixedEffects")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingMachine#supportsAiWithoutSowingMachine", "vehicle.turnOnVehicle.aiRequiresTurnOn")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingMachine.directionNode#index", "vehicle.sowingMachine.directionNode#node")
    spec.allowFillFromAirWhileTurnedOn = self.xmlFile:getValue("vehicle.sowingMachine.allowFillFromAirWhileTurnedOn#value", true)
    spec.directionNode = self.xmlFile:getValue("vehicle.sowingMachine.directionNode#node", self.components[1].node, self.components, self.i3dMappings)
    spec.useDirectPlanting = self.xmlFile:getValue("vehicle.sowingMachine.useDirectPlanting#value", false)
    spec.waterSeeding = self.xmlFile:getValue("vehicle.sowingMachine.waterSeeding#value", false)
    spec.isWorking = false
    spec.isProcessing = false
    spec.stoneLastState = 0
    spec.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("SOWINGMACHINE")
    spec.seeds = {}
    local fruitTypeIndices = {}
    local fruitTypeCategories = self.xmlFile:getValue("vehicle.sowingMachine.seedFruitTypeCategories")
    local fruitTypeNames = self.xmlFile:getValue("vehicle.sowingMachine.seedFruitTypes")
    if fruitTypeCategories == nil or fruitTypeNames ~= nil then
        if fruitTypeCategories == nil and fruitTypeNames ~= nil then
            fruitTypeIndices = g_fruitTypeManager:getFruitTypeIndicesByNames(fruitTypeNames, "Warning: \'" .. self.configFileName .. "\' has invalid fruitType \'%s\'.")
        else
            printWarning("Warning: \'" .. self.configFileName .. "\' a sowingMachine needs either the \'seedFruitTypeCategories\' or \'seedFruitTypes\' element.")
        end
    else
        fruitTypeIndices = g_fruitTypeManager:getFruitTypeIndicesByCategoryNames(fruitTypeCategories, "Warning: \'" .. self.configFileName .. "\' has invalid fruitTypeCategory \'%s\'.")
    end
    if fruitTypeIndices ~= nil then
        for _, fruitTypeIndex in pairs(fruitTypeIndices) do
            table.insert(spec.seeds, fruitTypeIndex)
        end
    end
    local seedFillType = self.xmlFile:getValue("vehicle.sowingMachine.seedFillType", "SEEDS")
    spec.seedFillType = FillType[seedFillType] or FillType.SEEDS
    spec.needsActivation = self.xmlFile:getValue("vehicle.sowingMachine.needsActivation#value", false)
    spec.requiresFilling = self.xmlFile:getValue("vehicle.sowingMachine.requiresFilling#value", true)
    spec.fieldGroundType = FieldGroundType.getValueByName(self.xmlFile:getValue("vehicle.sowingMachine.fieldGroundType#value", "SOWN"))
    spec.ridgeSeeding = self.xmlFile:getValue("vehicle.sowingMachine.fieldGroundType#ridgeSeeding", false)
    if spec.fieldGroundType == FieldGroundType.getValueByName("RIDGE") then
        spec.fieldGroundType = FieldGroundType.getValueByName("RIDGE_SOWN")
    end
    if self.isClient then
        spec.isWorkSamplePlaying = false
        spec.samples = {}
        spec.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.sowingMachine.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.airBlower = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.sowingMachine.sounds", "airBlower", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.sampleFillEnabled = false
        spec.sampleFillStopTime = -1
        spec.lastFillLevel = -1
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.sowingMachine.animationNodes", self.components, self, self.i3dMappings)
        g_animationManager:setFillType(spec.animationNodes, FillType.UNKNOWN)
        local changeSeedInputButtonStr = self.xmlFile:getValue("vehicle.sowingMachine.changeSeedInputButton")
        if changeSeedInputButtonStr ~= nil then
            spec.changeSeedInputButton = InputAction[changeSeedInputButtonStr]
        end
        spec.changeSeedInputButton = Utils.getNoNil(spec.changeSeedInputButton, InputAction.TOGGLE_SEEDS)
    end
    spec.currentSeed = 1
    spec.allowsSeedChanging = true
    spec.showFruitCanNotBePlantedWarning = false
    spec.showWrongFruitForMissionWarning = false
    spec.showWaterPlantingRequiredWarning = false
    spec.showWaterPlantingProhibitedWarning = false
    spec.showFieldTypeWarningRegularRequired = false
    spec.showFieldTypeWarningRiceRequired = false
    spec.warnings = {}
    spec.warnings.fruitCanNotBePlanted = g_i18n:getText("warning_theSelectedFruitTypeIsNotAvailableOnThisMap")
    spec.warnings.wrongFruitForMission = g_i18n:getText("warning_theSelectedFruitTypeIsWrongForTheMission")
    spec.warnings.wrongPlantingTime = g_i18n:getText("warning_theSelectedFruitTypeCantBePlantedInThisPeriod")
    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.sowingMachine#fillUnitIndex", 1)
    spec.unloadInfoIndex = self.xmlFile:getValue("vehicle.sowingMachine#unloadInfoIndex", 1)
    spec.consumableName = self.xmlFile:getValue("vehicle.sowingMachine#consumableName")
    if spec.consumableName ~= nil and self.updateConsumable == nil then
        Logging.xmlWarning("Sowing machine has consumableName \'%s\' attribute defined but has no consumable specialization!", spec.consumableName)
        spec.consumableName = nil
    end
    spec.seedUsageScale = self.xmlFile:getValue("vehicle.sowingMachine#seedUsageScale", 1)
    if self:getFillUnitByIndex(spec.fillUnitIndex) == nil then
        Logging.xmlError(self.xmlFile, "FillUnit \'%d\' not defined!", spec.fillUnitIndex)
        self:setLoadingState(VehicleLoadingState.ERROR)
    else
        spec.fillTypeSources = {}
        if self.isClient then
            spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.sowingMachine.effects", self.components, self, self.i3dMappings)
        end
        spec.workAreaParameters = {}
        spec.workAreaParameters.seedsFruitType = nil
        spec.workAreaParameters.angle = 0
        spec.workAreaParameters.lastChangedArea = 0
        spec.workAreaParameters.lastStatsArea = 0
        spec.workAreaParameters.lastArea = 0
        self:setSeedIndex(1, true)
        if savegame == nil then
            local changeSeedInputButtonStr = self.xmlFile:getValue("vehicle.sowingMachine#defaultFruitType")
            if changeSeedInputButtonStr ~= nil then
                local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(changeSeedInputButtonStr)
                if fruitTypeDesc ~= nil then
                    self:setSeedFruitType(fruitTypeDesc.index, true)
                end
            end
        else
            local changeSeedInputButtonStr = savegame.xmlFile:getValue(savegame.key .. ".sowingMachine#selectedSeedFruitType")
            if changeSeedInputButtonStr ~= nil then
                local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(changeSeedInputButtonStr)
                if fruitTypeDesc ~= nil then
                    self:setSeedFruitType(fruitTypeDesc.index, true)
                end
            end
            spec.allowsSeedChanging = savegame.xmlFile:getValue(savegame.key .. ".sowingMachine#allowsSeedChanging", spec.allowsSeedChanging)
        end
        if not self.isClient then
            SpecializationUtil.removeEventListener(self, "onUpdate", SowingMachine)
            SpecializationUtil.removeEventListener(self, "onUpdateTick", SowingMachine)
        end
        self.needWaterInfo = true
    end
end
function SowingMachine:onPostLoad(_)
    SowingMachine.updateAiParameters(self)
end
function SowingMachine:onDelete()
    if self.isClient then
        local spec = self.spec_sowingMachine
        if spec.samples ~= nil then
            g_soundManager:deleteSamples(spec.samples.work)
            g_soundManager:deleteSamples(spec.samples.airBlower)
        end
        g_effectManager:deleteEffects(spec.effects)
        g_animationManager:deleteAnimations(spec.animationNodes)
    end
end
function SowingMachine:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_sowingMachine
    local selectedSeedFruitTypeName = "unknown"
    local selectedSeedFruitType = spec.seeds[spec.currentSeed]
    if selectedSeedFruitType ~= nil and selectedSeedFruitType ~= FruitType.UNKNOWN then
        selectedSeedFruitTypeName = g_fruitTypeManager:getFruitTypeByIndex(selectedSeedFruitType).name
    end
    xmlFile:setValue(key .. "#selectedSeedFruitType", selectedSeedFruitTypeName)
    if spec.allowsSeedChanging ~= nil then
        xmlFile:setValue(key .. "#allowsSeedChanging", spec.allowsSeedChanging)
    end
end
function SowingMachine:onReadStream(streamId, _)
    self:setSeedIndex(streamReadUInt8(streamId), true)
end
function SowingMachine:onWriteStream(streamId, _)
    streamWriteUInt8(streamId, self.spec_sowingMachine.currentSeed)
end
function SowingMachine:onUpdate(_, _, _, _)
    local spec = self.spec_sowingMachine
    if spec.isProcessing then
        local fillType = self:getFillUnitForcedMaterialFillType(spec.fillUnitIndex)
        if fillType ~= nil then
            g_effectManager:setEffectTypeInfo(spec.effects, fillType)
            g_effectManager:startEffects(spec.effects)
            return
        end
    else
        g_effectManager:stopEffects(spec.effects)
    end
end
function SowingMachine:onUpdateTick(_, _, _, _)
    local spec = self.spec_sowingMachine
    local actionEvent = spec.actionEvents[spec.changeSeedInputButton]
    if actionEvent ~= nil then
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getIsSeedChangeAllowed())
    end
    if self.isActiveForInputIgnoreSelectionIgnoreAI then
        if spec.showFruitCanNotBePlantedWarning then
            g_currentMission:showBlinkingWarning(spec.warnings.fruitCanNotBePlanted, 5000)
            return
        end
        if spec.showWrongFruitForMissionWarning then
            g_currentMission:showBlinkingWarning(spec.warnings.wrongFruitForMission, 5000)
            return
        end
        if spec.showWrongPlantingTimeWarning then
            g_currentMission:showBlinkingWarning(string.format(spec.warnings.wrongPlantingTime, g_i18n:formatPeriod()), 5000)
            return
        end
        if spec.showWaterPlantingRequiredWarning then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_seedingInWaterRequired"), 5000)
            return
        end
        if spec.showWaterPlantingProhibitedWarning then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_seedingInWaterProhibited"), 5000)
            return
        end
        if spec.showFieldTypeWarningRegularRequired then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_seedingOnRegularFieldRequired"), 5000)
            return
        end
        if spec.showFieldTypeWarningRiceRequired then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_seedingOnRiceFieldRequired"), 5000)
        end
    end
end
function SowingMachine:setSeedIndex(seedIndex, noEventSend)
    local spec = self.spec_sowingMachine
    SetSeedIndexEvent.sendEvent(self, seedIndex, noEventSend)
    local fillType = math.max(seedIndex, 1)
    spec.currentSeed = math.min(fillType, #spec.seeds)
    local fruitTypeIndex = spec.seeds[spec.currentSeed]
    if fruitTypeIndex ~= nil then
        local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
        if fillType ~= nil then
            self:setFillUnitFillTypeToDisplay(spec.fillUnitIndex, fillType, true)
            self:setFillTypeSourceDisplayFillType(fillType)
        end
    end
    SowingMachine.updateAiParameters(self)
    SowingMachine.updateChooseSeedActionEvent(self)
end
function SowingMachine:changeSeedIndex(increment)
    local spec = self.spec_sowingMachine
    self:setSeedIndex(#spec.seeds < spec.currentSeed + increment and 1 or (spec.currentSeed + increment < 1 and #spec.seeds or spec.currentSeed + increment))
end
function SowingMachine:setSeedFruitType(fruitType, noEventSend)
    for i, v in ipairs(self.spec_sowingMachine.seeds) do
        if v == fruitType then
            self:setSeedIndex(i, noEventSend)
            return
        end
    end
end
function SowingMachine:setIsSeedChangeAllowed(isAllowed)
    self.spec_sowingMachine.allowsSeedChanging = isAllowed
end
function SowingMachine:getIsSeedChangeAllowed()
    return self.spec_sowingMachine.allowsSeedChanging
end
function SowingMachine:getSowingMachineFillUnitIndex()
    return self.spec_sowingMachine.fillUnitIndex
end
function SowingMachine:getSowingMachineSeedFillTypeIndex()
    local spec = self.spec_sowingMachine
    return g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.seeds[spec.currentSeed])
end
function SowingMachine:getCurrentSeedTypeIcon()
    local spec = self.spec_sowingMachine
    local fillType = g_fruitTypeManager:getFillTypeByFruitTypeIndex(spec.seeds[spec.currentSeed])
    if fillType == nil then
        return nil
    else
        return fillType.hudOverlayFilename
    end
end
function SowingMachine:processSowingMachineArea(workArea, _)
    local spec = self.spec_sowingMachine
    local changedArea = 0
    local totalArea = 0
    local rootVehicle = self:getLastSpeed() > 0.5
    spec.isWorking = rootVehicle
    if spec.waterSeeding and not self.isInWater then
        spec.showWaterPlantingRequiredWarning = true
        if self:getIsAIActive() then
            self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
        end
        return changedArea, totalArea
    end
    if not spec.waterSeeding and self.isInWater then
        spec.showWaterPlantingProhibitedWarning = true
        if self:getIsAIActive() then
            self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
        end
        return changedArea, totalArea
    end
    if not spec.workAreaParameters.isActive then
        return changedArea, totalArea
    end
    if not (self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds) and spec.workAreaParameters.seedsVehicle == nil then
        if self:getIsAIActive() then
            self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
        end
        return changedArea, totalArea
    end
    if not spec.workAreaParameters.canFruitBePlanted then
        return changedArea, totalArea
    end
    local rootVehicle, _, sz = getWorldTranslation(workArea.start)
    local wx, _, wz = getWorldTranslation(workArea.width)
    local hx, _, hz = getWorldTranslation(workArea.height)
    FSDensityMapUtil.eraseTireTrack(rootVehicle, sz, wx, wz, hx, hz)
    if not self.isServer and self.currentUpdateDistance > SowingMachine.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(spec.workAreaParameters.seedsFruitType)
    if fruitTypeDesc.seedRequiredFieldType ~= nil then
        if FSDensityMapUtil.getFieldTypeAtWorldPos((rootVehicle + wx + hx) / 3, (sz + wz + hz) / 3) ~= fruitTypeDesc.seedRequiredFieldType then
            if fruitTypeDesc.seedRequiredFieldType == FieldType.RICE then
                spec.showFieldTypeWarningRiceRequired = true
                if self:getIsAIActive() then
                    self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
                end
            else
                spec.showFieldTypeWarningRegularRequired = true
            end
        end
    end
    spec.isProcessing = spec.isWorking
    local changedArea
    if spec.useDirectPlanting then
        local cx, cz = FSDensityMapUtil.updateDirectSowingArea(spec.workAreaParameters.seedsFruitType, rootVehicle, sz, wx, wz, hx, hz, spec.workAreaParameters.fieldGroundType, spec.workAreaParameters.ridgeSeeding, spec.workAreaParameters.angle, nil)
    else
        local cx, cz = FSDensityMapUtil.updateSowingArea(spec.workAreaParameters.seedsFruitType, rootVehicle, sz, wx, wz, hx, hz, spec.workAreaParameters.fieldGroundType, spec.workAreaParameters.ridgeSeeding, spec.workAreaParameters.angle, nil)
    end
    if spec.isWorking then
        spec.stoneLastState = FSDensityMapUtil.getStoneArea(rootVehicle, sz, wx, wz, hx, hz)
    else
        spec.stoneLastState = 0
    end
    spec.workAreaParameters.lastChangedArea = spec.workAreaParameters.lastChangedArea + changedArea
    spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + changedArea
    spec.workAreaParameters.lastTotalArea = spec.workAreaParameters.lastTotalArea + 0
    self:updateMissionSowingWarning(rootVehicle, sz)
    return changedArea, totalArea
end
function SowingMachine:updateMissionSowingWarning(x, z)
    local spec = self.spec_sowingMachine
    spec.showWrongFruitForMissionWarning = false
    if self:getLastTouchedFarmlandFarmId() == 0 then
        local mission = g_missionManager:getMissionAtWorldPosition(x, z)
        if mission ~= nil and (mission.type.name == "sow" and mission.fruitType ~= spec.workAreaParameters.seedsFruitType) then
            spec.showWrongFruitForMissionWarning = true
        end
    end
end
function SowingMachine:getUseSowingMachineAIRequirements()
    return self:getAIRequiresTurnOn() or self:getIsTurnedOn()
end
function SowingMachine:setFillTypeSourceDisplayFillType(fillType)
    local spec = self.spec_sowingMachine
    if spec.fillTypeSources[spec.seedFillType] ~= nil then
        for _, src in ipairs(spec.fillTypeSources[spec.seedFillType]) do
            local vehicle = src.vehicle
            local fillLevel = vehicle:getFillUnitFillLevel(src.fillUnitIndex)
            if fillLevel > 0 and vehicle:getFillUnitFillType(src.fillUnitIndex) == spec.seedFillType then
                vehicle:setFillUnitFillTypeToDisplay(src.fillUnitIndex, fillType)
                return
            end
            if fillLevel == 0 then
                local fillTypes = vehicle:getFillUnitSupportedFillTypes(src.fillUnitIndex)
                local numFillTypes = 0
                for fillTypeIndex, state in pairs(fillTypes) do
                    if state then
                    end
                end
                if numFillTypes == 1 and fillTypes[spec.seedFillType] == true then
                    vehicle:setFillUnitFillTypeToDisplay(src.fillUnitIndex, fillType)
                    return
                end
            end
        end
    end
end
function SowingMachine:getDrawFirstFillText(superFunc)
    if self.isClient and (self:getIsActiveForInput() and self:getIsSelected()) then
        if self.spec_sowingMachine.consumableName == nil then
            if self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
                return true
            end
        elseif not self:getConsumableIsAvailable(spec.consumableName) then
            return true
        end
    end
    return superFunc(self)
end
function SowingMachine:getAreControlledActionsAllowed(superFunc)
    local spec = self.spec_sowingMachine
    if spec.requiresFilling then
        if spec.consumableName == nil then
            if self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
                return false, g_i18n:getText("info_firstFillTheTool")
            end
        elseif not self:getConsumableIsAvailable(spec.consumableName) then
            return false, g_i18n:getText("info_firstFillTheTool")
        end
    end
    return superFunc(self)
end
function SowingMachine:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillType)
    if superFunc(self, fillUnitIndex, fillType) then
        return true
    end
    local specFillUnit = self.spec_fillUnit
    if specFillUnit.fillUnits[fillUnitIndex] ~= nil and self:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
        local spec = self.spec_sowingMachine
        if fillType == spec.seedFillType or specFillUnit.fillUnits[fillUnitIndex].fillType == spec.seedFillType then
            return true
        end
    end
    return false
end
function SowingMachine:getCanBeTurnedOn(superFunc)
    if self.spec_sowingMachine.needsActivation then
        return superFunc(self)
    else
        return false
    end
end
function SowingMachine:getCanToggleTurnedOn(superFunc)
    if self.spec_sowingMachine.needsActivation then
        return superFunc(self)
    else
        return false
    end
end
function SowingMachine:getCanPlantOutsideSeason()
    return false
end
function SowingMachine:getSowingMachineCanConsume()
    local spec = self.spec_sowingMachine
    if spec.consumableName ~= nil then
        return self:getConsumableIsAvailable(spec.consumableName)
    end
    if self:getFillUnitFillLevel(spec.fillUnitIndex) > 0 or self:getFillUnitCapacity(spec.fillUnitIndex) == 0 then
        return true
    end
end
function SowingMachine:getAllowFillFromAir(superFunc)
    if self:getIsTurnedOn() and not self.spec_sowingMachine.allowFillFromAirWhileTurnedOn then
        return false
    else
        return superFunc(self)
    end
end
function SowingMachine:getDirectionSnapAngle(superFunc)
    local spec = self.spec_sowingMachine
    local desc = g_fruitTypeManager:getFruitTypeByIndex(spec.seeds[spec.currentSeed])
    local snapAngle = 0
    if desc ~= nil then
        snapAngle = desc.directionSnapAngle
    end
    return math.max(snapAngle, superFunc(self))
end
function SowingMachine:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillType, toolType, fillInfo)
    local spec = self.spec_sowingMachine
    if fillUnitIndex == spec.fillUnitIndex then
        if self:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
            self:setFillUnitForcedMaterialFillType(fillUnitIndex, spec.seedFillType)
        end
        local fruitType = spec.seeds[spec.currentSeed]
        if fruitType ~= nil then
            local seedsFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitType)
            if seedsFillType ~= nil and self:getFillUnitSupportsFillType(fillUnitIndex, seedsFillType) then
                self:setFillUnitForcedMaterialFillType(fillUnitIndex, seedsFillType)
            end
        end
    end
    return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillType, toolType, fillInfo)
end
function SowingMachine:doCheckSpeedLimit(superFunc)
    return not superFunc(self) and (self.getIsImplementChainLowered == nil or self:getIsImplementChainLowered()) and (not self.spec_sowingMachine.needsActivation or self:getIsTurnedOn())
end
function SowingMachine:getDirtMultiplier(superFunc)
    local spec = self.spec_sowingMachine
    local multiplier = superFunc(self)
    if self.movingDirection > 0 and (spec.isWorking and (not spec.needsActivation or self:getIsTurnedOn())) then
        multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    end
    return multiplier
end
function SowingMachine:getWearMultiplier(superFunc)
    local spec = self.spec_sowingMachine
    local multiplier = superFunc(self)
    if self.movingDirection > 0 and (spec.isWorking and (not spec.needsActivation or self:getIsTurnedOn())) then
        multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * (spec.stoneLastState ~= 0 and spec.stoneWearMultiplierData ~= nil and (spec.stoneWearMultiplierData[spec.stoneLastState] or 1) or 1)
    end
    return multiplier
end
function SowingMachine:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = superFunc(self, workArea, xmlFile, key)
    if workArea.type == WorkAreaType.DEFAULT then
        workArea.type = WorkAreaType.SOWINGMACHINE
    end
    return retValue
end
function SowingMachine:getCanBeSelected(superFunc)
    return true
end
function SowingMachine:getCanAIImplementContinueWork(superFunc, isTurning)
    local canContinue, stopAI, stopReason = superFunc(self, isTurning)
    if not canContinue then
        return false, stopAI, stopReason
    end
    if not self:getCanPlantOutsideSeason() and self:getUseSowingMachineAIRequirements() then
        local spec = self.spec_sowingMachine
        if spec.workAreaParameters.seedsFruitType ~= nil and not g_fruitTypeManager:getFruitTypeByIndex(spec.workAreaParameters.seedsFruitType):getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod) then
            return false, true, AIMessageErrorWrongSeason.new()
        end
    end
    return canContinue, stopAI, stopReason
end
function SowingMachine:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_sowingMachine
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection and #spec.seeds > 1 then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.changeSeedInputButton, self, SowingMachine.actionEventToggleSeedType, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            SowingMachine.updateChooseSeedActionEvent(self)
            local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_SEEDS_BACK, self, SowingMachine.actionEventToggleSeedTypeBack, false, true, false, true, nil)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
        end
    end
end
function SowingMachine:updateChooseSeedActionEvent()
    local spec = self.spec_sowingMachine
    local actionEvent = spec.actionEvents[spec.changeSeedInputButton]
    if actionEvent ~= nil then
        local additionalText = ""
        local fillType = g_fillTypeManager:getFillTypeByIndex(g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.seeds[spec.currentSeed]))
        if fillType ~= nil and fillType ~= FillType.UNKNOWN then
            additionalText = string.format(" (%s)", fillType.title)
        end
        g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format("%s%s", g_i18n:getText("action_chooseSeed"), additionalText))
    end
end
function SowingMachine:onTurnedOn()
    local spec = self.spec_sowingMachine
    if self.isClient then
        g_soundManager:playSamples(spec.samples.airBlower)
        g_animationManager:startAnimations(spec.animationNodes)
    end
    if self.isServer and spec.fillTypeSources[spec.seedFillType] ~= nil then
        for _, src in ipairs(spec.fillTypeSources[spec.seedFillType]) do
            if src.vehicle.setIsTurnedOn ~= nil then
                src.vehicle:setIsTurnedOn(true)
            end
        end
    end
    SowingMachine.updateAiParameters(self)
end
function SowingMachine:onTurnedOff()
    local spec = self.spec_sowingMachine
    if self.isClient then
        g_soundManager:stopSamples(spec.samples.airBlower)
        g_animationManager:stopAnimations(spec.animationNodes)
    end
    if self.isServer and spec.fillTypeSources[spec.seedFillType] ~= nil then
        for _, src in ipairs(spec.fillTypeSources[spec.seedFillType]) do
            if src.vehicle.setIsTurnedOn ~= nil then
                src.vehicle:setIsTurnedOn(false)
            end
        end
    end
    SowingMachine.updateAiParameters(self)
end
function SowingMachine:onStartWorkAreaProcessing(_)
    local spec = self.spec_sowingMachine
    spec.isWorking = false
    spec.isProcessing = false
    local seedsFruitType = spec.seeds[spec.currentSeed]
    local dx, _, dz = localDirectionToWorld(spec.directionNode, 0, 0, 1)
    local angleRad = MathUtil.getYRotationFromDirection(dx, dz)
    local desc = g_fruitTypeManager:getFruitTypeByIndex(seedsFruitType)
    if desc ~= nil and desc.directionSnapAngle ~= 0 then
        angleRad = math.floor(angleRad / desc.directionSnapAngle + 0.5) * desc.directionSnapAngle
    end
    local angle = FSDensityMapUtil.convertToDensityMapAngle(angleRad, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
    local seedsVehicle = nil
    local seedsVehicleFillUnitIndex = nil
    local seedsVehicleUnloadInfoIndex = nil
    local isFilled
    if spec.consumableName == nil then
        isFilled = self:getFillUnitFillLevel(spec.fillUnitIndex) > 0
    else
        isFilled = self:getConsumableIsAvailable(spec.consumableName)
    end
    if isFilled then
        seedsVehicleFillUnitIndex = spec.fillUnitIndex
        seedsVehicleUnloadInfoIndex = spec.unloadInfoIndex
    elseif spec.fillTypeSources[spec.seedFillType] == nil then
    else
        self = seedsVehicle
        for _, src in ipairs(spec.fillTypeSources[spec.seedFillType]) do
            local vehicle = src.vehicle
            if vehicle:getFillUnitFillLevel(src.fillUnitIndex) > 0 and vehicle:getFillUnitFillType(src.fillUnitIndex) == spec.seedFillType then
                seedsVehicleFillUnitIndex = src.fillUnitIndex
                self = vehicle
                break
            end
        end
    end
    if self ~= nil and self ~= self then
        local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(seedsFruitType)
        if fillType ~= nil then
            self:setFillUnitFillTypeToDisplay(seedsVehicleFillUnitIndex, fillType)
        end
    end
    local fillType = self:getIsTurnedOn()
    local canFruitBePlanted = desc ~= nil and desc.terrainDataPlaneId ~= nil and true or false
    if spec.showWrongFruitForMissionWarning then
        spec.showWrongFruitForMissionWarning = false
    end
    local isPlantingSeason = true
    if not self:getCanPlantOutsideSeason() then
        seedsFruitType = g_fruitTypeManager:getFruitTypeByIndex(seedsFruitType)
        if seedsFruitType ~= nil then
            isPlantingSeason = seedsFruitType:getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod)
        end
    end
    local _ = self ~= spec.workAreaParameters.seedsVehicle or seedsVehicleFillUnitIndex ~= spec.workAreaParameters.seedsVehicleFillUnitIndex
    spec.showFruitCanNotBePlantedWarning = not canFruitBePlanted
    local src = not (isPlantingSeason or (fillType or spec.needsActivation))
    if src then
        src = self:getIsLowered()
    end
    spec.showWrongPlantingTimeWarning = src
    spec.showWaterPlantingRequiredWarning = false
    spec.showWaterPlantingProhibitedWarning = false
    spec.showFieldTypeWarningRegularRequired = false
    spec.showFieldTypeWarningRiceRequired = false
    spec.workAreaParameters.isActive = not spec.needsActivation or fillType
    spec.workAreaParameters.canFruitBePlanted = canFruitBePlanted and isPlantingSeason
    spec.workAreaParameters.seedsFruitType = seedsFruitType
    spec.workAreaParameters.fieldGroundType = spec.fieldGroundType
    spec.workAreaParameters.ridgeSeeding = spec.ridgeSeeding
    spec.workAreaParameters.angle = angle
    spec.workAreaParameters.seedsVehicle = self
    spec.workAreaParameters.seedsVehicleFillUnitIndex = seedsVehicleFillUnitIndex
    spec.workAreaParameters.seedsVehicleUnloadInfoIndex = seedsVehicleUnloadInfoIndex
    spec.workAreaParameters.lastTotalArea = 0
    spec.workAreaParameters.lastChangedArea = 0
    spec.workAreaParameters.lastStatsArea = 0
    if _ then
        SowingMachine.updateAiParameters(self)
    end
end
function SowingMachine:onEndWorkAreaProcessing(dt, _)
    if self.isServer then
        local farmId = self:getLastTouchedFarmlandFarmId()
        if self.spec_sowingMachine.workAreaParameters.lastChangedArea > 0 then
            local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(spec.workAreaParameters.seedsFruitType)
            local lastHa = MathUtil.areaToHa(spec.workAreaParameters.lastChangedArea, g_currentMission:getFruitPixelsToSqm())
            local usage = fruitDesc.seedUsagePerSqm * lastHa * 10000 * spec.seedUsageScale
            local ha = MathUtil.areaToHa(spec.workAreaParameters.lastStatsArea, g_currentMission:getFruitPixelsToSqm())
            local damage = self:getVehicleDamage()
            if damage > 0 then
            end
            g_farmManager:updateFarmStats(farmId, "seedUsage", usage)
            g_farmManager:updateFarmStats(farmId, "sownHectares", ha)
            self:updateLastWorkedArea(spec.workAreaParameters.lastStatsArea)
            if self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds then
                local vehicle = usage * g_currentMission.economyManager:getCostPerLiter(spec.seedFillType, false) * 1.5
                g_farmManager:updateFarmStats(farmId, "expenses", vehicle)
                g_currentMission:addMoney(-vehicle, self:getOwnerFarmId(), MoneyType.PURCHASE_SEEDS)
            elseif spec.consumableName == nil then
                local vehicle = spec.workAreaParameters.seedsVehicle
                local fillUnitIndex = spec.workAreaParameters.seedsVehicleFillUnitIndex
                local fillType = vehicle:getFillUnitFillType(fillUnitIndex)
                local unloadInfo = nil
                if vehicle.getFillVolumeUnloadInfo ~= nil then
                    unloadInfo = vehicle:getFillVolumeUnloadInfo(spec.workAreaParameters.seedsVehicleUnloadInfoIndex)
                end
                vehicle:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, -usage, fillType, ToolType.UNDEFINED, unloadInfo)
            else
                self:updateConsumable(spec.consumableName, -usage, true)
            end
        end
        self:updateLastWorkedArea(0)
        if spec.isWorking then
            g_farmManager:updateFarmStats(farmId, "sownTime", dt / 60000)
        end
    end
    if self.isClient then
        if spec.isWorking then
            if not spec.isWorkSamplePlaying then
                g_soundManager:playSamples(spec.samples.work)
                spec.isWorkSamplePlaying = true
                return
            end
        elseif spec.isWorkSamplePlaying then
            g_soundManager:stopSamples(spec.samples.work)
            spec.isWorkSamplePlaying = false
        end
    end
end
function SowingMachine:onDeactivate()
    if self.isClient then
        g_soundManager:stopSamples(self.spec_sowingMachine.samples.work)
        g_soundManager:stopSamples(spec.samples.airBlower)
        spec.isWorkSamplePlaying = false
    end
end
function SowingMachine:onStateChange(state, _)
    if state == VehicleStateChange.ATTACH or (state == VehicleStateChange.DETACH or VehicleStateChange.FILLTYPE_CHANGE) then
        local spec = self.spec_sowingMachine
        spec.fillTypeSources = {}
        if spec.seedFillType ~= nil then
            spec.fillTypeSources[spec.seedFillType] = {}
            FillUnit.addFillTypeSources(spec.fillTypeSources, self.rootVehicle, self, { spec.seedFillType })
            local fruitTypeIndex = spec.seeds[spec.currentSeed]
            if fruitTypeIndex ~= nil then
                local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
                if fillType ~= nil then
                    self:setFillTypeSourceDisplayFillType(fillType)
                end
            end
        end
    end
end
function SowingMachine:onChangedFillType(fillUnitIndex, fillTypeIndex, _)
    local spec = self.spec_sowingMachine
    if fillUnitIndex == spec.fillUnitIndex then
        g_animationManager:setFillType(spec.animationNodes, fillTypeIndex)
    end
end
function SowingMachine:onAIFieldCourseSettingsInitialized(fieldCourseSettings)
    if self.spec_sowingMachine.fieldGroundType == FieldGroundType.PLANTED then
        fieldCourseSettings.headlandsFirst = true
        fieldCourseSettings.workInitialSegment = true
    end
end
function SowingMachine:updateAiParameters()
    if self.addAITerrainDetailRequiredRange ~= nil then
        self:clearAITerrainDetailRequiredRange()
        self:clearAITerrainDetailProhibitedRange()
        self:clearAIFruitProhibitions()
        local isCultivatorAttached = false
        local isWeederAttached = false
        local isRollerAttached = false
        local vehicles = self.rootVehicle:getChildVehicles()
        local i = 1
        local fruitTypeIndex = #vehicles
        local fruitTypeDesc = 1
        for i = i, fruitTypeIndex, fruitTypeDesc do
            local vehicle = vehicles[i]
            if SpecializationUtil.hasSpecialization(Cultivator, vehicle.specializations) then
                vehicle:updateCultivatorEnabledState()
                if vehicle:getIsCultivationEnabled() then
                    isCultivatorAttached = true
                    vehicle:updateCultivatorAIRequirements()
                end
            end
            if SpecializationUtil.hasSpecialization(Weeder, vehicle.specializations) then
                isWeederAttached = true
                vehicle:updateWeederAIRequirements()
            end
            if SpecializationUtil.hasSpecialization(Roller, vehicle.specializations) then
                isRollerAttached = true
                vehicle:updateRollerAIRequirements()
            end
        end
        if isCultivatorAttached then
            if self:getUseSowingMachineAIRequirements() then
                self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
                self:addAIGroundTypeRequirements(SowingMachine.AI_OUTPUT_GROUND_TYPES)
            end
        elseif isWeederAttached then
            if self:getUseSowingMachineAIRequirements() then
                self:clearAITerrainDetailRequiredRange()
                self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
            end
        elseif isRollerAttached then
            if self:getUseSowingMachineAIRequirements() then
                self:clearAITerrainDetailRequiredRange()
                self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
            end
        else
            self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
            if self.spec_sowingMachine.useDirectPlanting then
                self:addAIGroundTypeRequirements(SowingMachine.AI_OUTPUT_GROUND_TYPES)
            end
        end
        if self:getUseSowingMachineAIRequirements() then
            local fruitTypeIndex = spec.seeds[spec.currentSeed]
            local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
            if fruitTypeDesc ~= nil then
                if fruitTypeDesc.cutState < fruitTypeDesc.maxHarvestingGrowthState then
                    self:clearAIFruitProhibitions()
                    self:addAIFruitProhibitions(fruitTypeIndex, 0, fruitTypeDesc.cutState - 1)
                    self:addAIFruitProhibitions(fruitTypeIndex, fruitTypeDesc.cutState + 1, fruitTypeDesc.maxHarvestingGrowthState)
                    return
                end
                self:setAIFruitProhibitions(fruitTypeIndex, 0, fruitTypeDesc.maxHarvestingGrowthState)
            end
        end
    end
end
function SowingMachine.getDefaultSpeedLimit()
    return 15
end
function SowingMachine:actionEventToggleSeedType(_, _, _, _)
    if self:getIsSeedChangeAllowed() then
        self:changeSeedIndex(1)
    end
end
function SowingMachine:actionEventToggleSeedTypeBack(_, _, _, _)
    if self:getIsSeedChangeAllowed() then
        self:changeSeedIndex(-1)
    end
end
function SowingMachine.loadSpecValueSeedFillTypes(xmlFile, _, _)
    return {
        ["categories"] = Utils.getNoNil(xmlFile:getValue("vehicle.storeData.specs.seedFruitTypeCategories"), xmlFile:getValue("vehicle.sowingMachine.seedFruitTypeCategories")),
        ["names"] = Utils.getNoNil(xmlFile:getValue("vehicle.storeData.specs.seedFruitTypes"), xmlFile:getValue("vehicle.sowingMachine.seedFruitTypes"))
    }
end
function SowingMachine.getSpecValueSeedFillTypes(storeItem, _)
    local fruitTypes = nil
    if storeItem.specs.seedFillTypes ~= nil then
        local fruits = storeItem.specs.seedFillTypes
        if fruits.categories == nil or fruits.names ~= nil then
            if fruits.categories == nil and fruits.names ~= nil then
                fruitTypes = g_fruitTypeManager:getFillTypeIndicesByFruitTypeNames(fruits.names, nil)
            end
        else
            fruitTypes = g_fruitTypeManager:getFillTypeIndicesByFruitTypeCategoryName(fruits.categories, nil)
        end
        if fruitTypes ~= nil then
            return fruitTypes
        end
    end
    return nil
end