source("dataS/scripts/vehicles/specializations/events/SprayerDoubledAmountEvent.lua")
Sprayer = {}
Sprayer.SPRAY_TYPE_XML_KEY = "vehicle.sprayer.sprayTypes.sprayType(?)"
Sprayer.AI_REQUIRED_GROUND_TYPES = {
    FieldGroundType.STUBBLE_TILLAGE,
    FieldGroundType.CULTIVATED,
    FieldGroundType.SEEDBED,
    FieldGroundType.PLOWED,
    FieldGroundType.ROLLED_SEEDBED,
    FieldGroundType.RIDGE,
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
Sprayer.CLIENT_DM_UPDATE_RADIUS = 50
function Sprayer.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("sprayer", false, true, true)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Sprayer")
    schema:register(XMLValueType.BOOL, "vehicle.sprayer#allowsSpraying", "Allows spraying", true)
    schema:register(XMLValueType.BOOL, "vehicle.sprayer#activateTankOnLowering", "Activate tank on lowering", false)
    schema:register(XMLValueType.BOOL, "vehicle.sprayer#activateOnLowering", "Activate on lowering", false)
    schema:register(XMLValueType.FLOAT, "vehicle.sprayer.usageScales#scale", "Usage scale", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.sprayer.usageScales#workingWidth", "Working width", 12)
    schema:register(XMLValueType.INT, "vehicle.sprayer.usageScales#workAreaIndex", "Work area that is used for working width reference instead of #workingWidth")
    schema:register(XMLValueType.STRING, "vehicle.sprayer.usageScales.sprayUsageScale(?)#fillType", "Fill type name")
    schema:register(XMLValueType.FLOAT, "vehicle.sprayer.usageScales.sprayUsageScale(?)#scale", "Scale")
    schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#fillUnitIndex", "Fill unit index")
    schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#unloadInfoIndex", "Unload info index")
    schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#fillVolumeIndex", "Fill volume index")
    schema:register(XMLValueType.BOOL, Sprayer.SPRAY_TYPE_XML_KEY .. "#supportsVariableWorkWidth", "Spray type support variable work width", true)
    SoundManager.registerSampleXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY .. ".sounds", "work(?)")
    SoundManager.registerSampleXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY .. ".sounds", "spray(?)")
    AnimationManager.registerAnimationNodesXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY .. ".animationNodes")
    EffectManager.registerEffectXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY .. ".effects")
    schema:register(XMLValueType.STRING, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#name", "Turned animation name")
    schema:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#turnOnSpeedScale", "Speed Scale while turned on", 1)
    schema:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#turnOffSpeedScale", "Speed Scale while turned off", "Inversed #turnOnSpeedScale")
    schema:register(XMLValueType.BOOL, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#externalFill", "Animation is played while sprayer is externally filled", true)
    AIImplement.registerAIImplementBaseXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY .. ".ai")
    schema:register(XMLValueType.STRING, Sprayer.SPRAY_TYPE_XML_KEY .. "#fillTypes", "Fill types")
    schema:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. ".usageScales#workingWidth", "Work width", 12)
    schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. ".usageScales#workAreaIndex", "Work area that is used for working width reference instead of #workingWidth")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY)
    EffectManager.registerEffectXMLPaths(schema, "vehicle.sprayer.effects")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.sprayer.sounds", "work(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.sprayer.sounds", "spray(?)")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.sprayer.animationNodes")
    schema:register(XMLValueType.STRING, "vehicle.sprayer.animation#name", "Spray animation name")
    schema:register(XMLValueType.INT, "vehicle.sprayer#fillUnitIndex", "Fill unit index", 1)
    schema:register(XMLValueType.INT, "vehicle.sprayer#unloadInfoIndex", "Unload info index", 1)
    schema:register(XMLValueType.INT, "vehicle.sprayer#fillVolumeIndex", "Fill volume index")
    schema:register(XMLValueType.VECTOR_3, "vehicle.sprayer#fillVolumeDischargeScrollSpeed", "Fill volume discharge scroll speed", "0 0 0")
    schema:register(XMLValueType.FLOAT, "vehicle.sprayer.doubledAmount#decreasedSpeed", "Speed while doubled amount is sprayed", "automatically calculated")
    schema:register(XMLValueType.FLOAT, "vehicle.sprayer.doubledAmount#decreaseFactor", "Decrease factor that is applied on speedLimit while doubled amount is sprayed", 0.5)
    schema:register(XMLValueType.STRING, "vehicle.sprayer.doubledAmount#toggleButton", "Name of input action to toggle doubled amount", "IMPLEMENT_EXTRA4")
    schema:register(XMLValueType.L10N_STRING, "vehicle.sprayer.doubledAmount#deactivateText", "Deactivated text", "action_deactivateDoubledSprayAmount")
    schema:register(XMLValueType.L10N_STRING, "vehicle.sprayer.doubledAmount#activateText", "Activate text", "action_activateDoubledSprayAmount")
    schema:register(XMLValueType.STRING, "vehicle.sprayer.turnedAnimation#name", "Turned animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.sprayer.turnedAnimation#turnOnSpeedScale", "Speed Scale while turned on", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.sprayer.turnedAnimation#turnOffSpeedScale", "Speed Scale while turned off", "Inversed #turnOnSpeedScale")
    schema:register(XMLValueType.BOOL, "vehicle.sprayer.turnedAnimation#externalFill", "Animation is played while sprayer is externally filled", true)
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. "#sprayType", "Spray type index")
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#sprayType", "Spray type index")
    schema:setXMLSpecializationType()
end
function Sprayer.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function Sprayer.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onSprayTypeChange")
end
function Sprayer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "processSprayerArea", Sprayer.processSprayerArea)
    SpecializationUtil.registerFunction(vehicleType, "getIsSprayerExternallyFilled", Sprayer.getIsSprayerExternallyFilled)
    SpecializationUtil.registerFunction(vehicleType, "getExternalFill", Sprayer.getExternalFill)
    SpecializationUtil.registerFunction(vehicleType, "getAreEffectsVisible", Sprayer.getAreEffectsVisible)
    SpecializationUtil.registerFunction(vehicleType, "updateSprayerEffects", Sprayer.updateSprayerEffects)
    SpecializationUtil.registerFunction(vehicleType, "getSprayerUsage", Sprayer.getSprayerUsage)
    SpecializationUtil.registerFunction(vehicleType, "getUseSprayerAIRequirements", Sprayer.getUseSprayerAIRequirements)
    SpecializationUtil.registerFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", Sprayer.setSprayerAITerrainDetailProhibitedRange)
    SpecializationUtil.registerFunction(vehicleType, "getSprayerFillUnitIndex", Sprayer.getSprayerFillUnitIndex)
    SpecializationUtil.registerFunction(vehicleType, "loadSprayTypeFromXML", Sprayer.loadSprayTypeFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getActiveSprayType", Sprayer.getActiveSprayType)
    SpecializationUtil.registerFunction(vehicleType, "getIsSprayTypeActive", Sprayer.getIsSprayTypeActive)
    SpecializationUtil.registerFunction(vehicleType, "setSprayerDoubledAmountActive", Sprayer.setSprayerDoubledAmountActive)
    SpecializationUtil.registerFunction(vehicleType, "getSprayerDoubledAmountActive", Sprayer.getSprayerDoubledAmountActive)
end
function Sprayer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", Sprayer.getDrawFirstFillText)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", Sprayer.getAreControlledActionsAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", Sprayer.getCanToggleTurnedOn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Sprayer.getCanBeTurnedOn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Sprayer.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Sprayer.getIsWorkAreaActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Sprayer.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRawSpeedLimit", Sprayer.getRawSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillVolumeUVScrollSpeed", Sprayer.getFillVolumeUVScrollSpeed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIRequiresTurnOffOnHeadland", Sprayer.getAIRequiresTurnOffOnHeadland)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Sprayer.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Sprayer.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getEffectByNode", Sprayer.getEffectByNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVariableWorkWidthUsage", Sprayer.getVariableWorkWidthUsage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementUseVineSegment", Sprayer.getAIImplementUseVineSegment)
end
function Sprayer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onSprayTypeChange", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEnd", Sprayer)
    SpecializationUtil.registerEventListener(vehicleType, "onVariableWorkWidthSectionChanged", Sprayer)
end
function Sprayer:onLoad(_)
    local spec = self.spec_sprayer
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sprayParticles.emitterShape", "vehicle.sprayer.effects.effectNode#effectClass=\'ParticleEffect\'")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sprayer#needsTankActivation")
    spec.allowsSpraying = self.xmlFile:getValue("vehicle.sprayer#allowsSpraying", true)
    spec.activateTankOnLowering = self.xmlFile:getValue("vehicle.sprayer#activateTankOnLowering", false)
    spec.activateOnLowering = self.xmlFile:getValue("vehicle.sprayer#activateOnLowering", false)
    spec.usageScale = {}
    spec.usageScale.default = self.xmlFile:getValue("vehicle.sprayer.usageScales#scale", 1)
    spec.usageScale.workingWidth = self.xmlFile:getValue("vehicle.sprayer.usageScales#workingWidth", 12)
    spec.usageScale.workAreaIndex = self.xmlFile:getValue("vehicle.sprayer.usageScales#workAreaIndex")
    spec.usageScale.fillTypeScales = {}
    local i = 0
    while true do
        local key = string.format("vehicle.sprayer.usageScales.sprayUsageScale(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local fillTypeStr = self.xmlFile:getValue(key .. "#fillType")
        local scale = self.xmlFile:getValue(key .. "#scale")
        if fillTypeStr ~= nil and scale ~= nil then
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
            if fillTypeIndex == nil then
                printWarning("Warning: Invalid spray usage scale fill type \'" .. fillTypeStr .. "\' in \'" .. self.configFileName .. "\'")
            else
                spec.usageScale.fillTypeScales[fillTypeIndex] = scale
            end
        end
        i = i + 1
    end
    spec.sprayTypes = {}
    local i = 0
    while true do
        local key = string.format("vehicle.sprayer.sprayTypes.sprayType(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local fillTypeStr = {}
        if self:loadSprayTypeFromXML(self.xmlFile, key, fillTypeStr) then
            table.insert(spec.sprayTypes, fillTypeStr)
            fillTypeStr.index = #spec.sprayTypes
        end
        i = i + 1
    end
    spec.lastActiveSprayType = nil
    if self.isClient then
        spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.sprayer.effects", self.components, self, self.i3dMappings)
        spec.animationName = self.xmlFile:getValue("vehicle.sprayer.animation#name", "")
        spec.samples = {}
        spec.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.sprayer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.spray = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.sprayer.sounds", "spray", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.sampleFillEnabled = false
        spec.sampleFillStopTime = -1
        spec.lastFillLevel = -1
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.sprayer.animationNodes", self.components, self, self.i3dMappings)
    end
    if self.addAIGroundTypeRequirements ~= nil then
        self:addAIGroundTypeRequirements(Sprayer.AI_REQUIRED_GROUND_TYPES)
    end
    spec.supportedSprayTypes = {}
    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.sprayer#fillUnitIndex", 1)
    spec.unloadInfoIndex = self.xmlFile:getValue("vehicle.sprayer#unloadInfoIndex", 1)
    spec.fillVolumeIndex = self.xmlFile:getValue("vehicle.sprayer#fillVolumeIndex")
    spec.dischargeUVScrollSpeed = self.xmlFile:getValue("vehicle.sprayer#fillVolumeDischargeScrollSpeed", "0 0 0", true)
    if self:getFillUnitByIndex(spec.fillUnitIndex) == nil then
        Logging.xmlError(self.xmlFile, "FillUnit \'%d\' not defined!", spec.fillUnitIndex)
        self:setLoadingState(VehicleLoadingState.ERROR)
    else
        local key = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#decreasedSpeed")
        if key == nil then
            local fillTypeStr = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#decreaseFactor", 0.5)
            key = self:getSpeedLimit() * fillTypeStr
        end
        spec.doubledAmountSpeed = key
        spec.doubledAmountIsActive = false
        local fillTypeStr = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#toggleButton")
        if fillTypeStr ~= nil then
            spec.toggleDoubledAmountInputBinding = InputAction[fillTypeStr]
        end
        spec.toggleDoubledAmountInputBinding = spec.toggleDoubledAmountInputBinding or InputAction.DOUBLED_SPRAY_AMOUNT
        spec.doubledAmountDeactivateText = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#deactivateText", "action_deactivateDoubledSprayAmount", self.customEnvironment)
        spec.doubledAmountActivateText = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#activateText", "action_activateDoubledSprayAmount", self.customEnvironment)
        spec.turnedAnimation = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#name", "")
        spec.turnedAnimationTurnOnSpeedScale = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#turnOnSpeedScale", 1)
        spec.turnedAnimationTurnOffSpeedScale = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#turnOffSpeedScale", -spec.turnedAnimationTurnOnSpeedScale)
        spec.turnedAnimationExternalFill = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#externalFill", true)
        spec.needsToBeFilledToTurnOn = true
        spec.useSpeedLimit = true
        spec.isWorking = false
        spec.lastEffectsState = false
        local scale = self:getSprayerFillUnitIndex()
        spec.isSlurryTanker = self:getFillUnitAllowsFillType(scale, FillType.LIQUIDMANURE) or self:getFillUnitAllowsFillType(scale, FillType.DIGESTATE)
        spec.isManureSpreader = self:getFillUnitAllowsFillType(scale, FillType.MANURE)
        local fillTypeIndex = not spec.isSlurryTanker
        if fillTypeIndex then
            fillTypeIndex = not spec.isManureSpreader
        end
        spec.isFertilizerSprayer = fillTypeIndex
        local fillTypeIndex = self:getWorkAreaByIndex(1) ~= nil
        spec.hasWorkAreas = fillTypeIndex
        spec.workAreaParameters = {}
        spec.workAreaParameters.sprayVehicle = nil
        spec.workAreaParameters.sprayVehicleFillUnitIndex = nil
        spec.workAreaParameters.lastChangedArea = 0
        spec.workAreaParameters.lastTotalArea = 0
        spec.workAreaParameters.lastIsExternallyFilled = false
        spec.workAreaParameters.lastSprayTime = -math.huge
        spec.workAreaParameters.usage = 0
        spec.workAreaParameters.usagePerMin = 0
        if not spec.hasWorkAreas then
            SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Sprayer)
        end
    end
end
function Sprayer:onDelete()
    local spec = self.spec_sprayer
    g_effectManager:deleteEffects(spec.effects)
    g_animationManager:deleteAnimations(spec.animationNodes)
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples.work)
        g_soundManager:deleteSamples(spec.samples.spray)
    end
    if spec.sprayTypes ~= nil then
        for _, sprayType in ipairs(spec.sprayTypes) do
            g_effectManager:deleteEffects(sprayType.effects)
            g_animationManager:deleteAnimations(sprayType.animationNodes)
            if sprayType.samples ~= nil then
                g_soundManager:deleteSamples(sprayType.samples.work)
                g_soundManager:deleteSamples(sprayType.samples.spray)
            end
        end
    end
end
function Sprayer:onUpdateTick(_, _, _, _)
    local activeSprayType = self:getActiveSprayType()
    if activeSprayType ~= nil then
        local spec = self.spec_sprayer
        if activeSprayType ~= spec.lastActiveSprayType then
            for _, sprayType in ipairs(spec.sprayTypes) do
                if sprayType == spec.lastActiveSprayType then
                    g_effectManager:stopEffects(sprayType.effects)
                    g_animationManager:stopAnimations(sprayType.animationNodes)
                end
            end
            SpecializationUtil.raiseEvent(self, "onSprayTypeChange", activeSprayType)
            spec.lastActiveSprayType = activeSprayType
            self:updateSprayerEffects(true)
        end
    end
    if self.isClient then
        local spec = self.spec_sprayer
        local actionEvent = spec.actionEvents[spec.toggleDoubledAmountInputBinding]
        if actionEvent ~= nil then
            local text
            if spec.doubledAmountIsActive then
                text = spec.doubledAmountDeactivateText
            else
                text = spec.doubledAmountActivateText
            end
            g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
            local _, _ = self:getSprayerDoubledAmountActive(spec.workAreaParameters.sprayType)
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, _)
        end
    end
    if self.isServer then
        local spec = self.spec_sprayer
        if spec.pendingActivationAfterLowering and self:getCanBeTurnedOn() then
            self:setIsTurnedOn(true)
            spec.pendingActivationAfterLowering = false
        end
    end
end
function Sprayer:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_sprayer
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.toggleDoubledAmountInputBinding, self, Sprayer.actionEventDoubledAmount, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
        end
    end
end
function Sprayer:actionEventDoubledAmount(_, _, _, _)
    self:setSprayerDoubledAmountActive(not self.spec_sprayer.doubledAmountIsActive)
end
function Sprayer:processSprayerArea(workArea, _)
    local spec = self.spec_sprayer
    if self:getIsAIActive() and (self.isServer and (spec.workAreaParameters.sprayFillType == nil or spec.workAreaParameters.sprayFillType == FillType.UNKNOWN)) then
        self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
        return 0, 0
    end
    if spec.workAreaParameters.sprayFillLevel <= 0 then
        return 0, 0
    end
    local rootVehicle, _, sz = getWorldTranslation(workArea.start)
    local wx, _, wz = getWorldTranslation(workArea.width)
    local hx, _, hz = getWorldTranslation(workArea.height)
    if not self.isServer and self.currentUpdateDistance > Sprayer.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local sprayAmount = self:getSprayerDoubledAmountActive(spec.workAreaParameters.sprayType) and 2 or 1
    local changedArea, totalArea = FSDensityMapUtil.updateSprayArea(rootVehicle, sz, wx, wz, hx, hz, spec.workAreaParameters.sprayType, sprayAmount)
    spec.workAreaParameters.isActive = true
    spec.workAreaParameters.lastChangedArea = spec.workAreaParameters.lastChangedArea + changedArea
    spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + changedArea
    spec.workAreaParameters.lastTotalArea = spec.workAreaParameters.lastTotalArea + totalArea
    spec.workAreaParameters.lastSprayTime = g_time
    if self:getLastSpeed() > 1 then
        spec.isWorking = true
    end
    return changedArea, totalArea
end
function Sprayer:getIsSprayerExternallyFilled()
    if not self:getIsAIActive() then
        return false
    end
    if self:getFillUnitCapacity(self:getSprayerFillUnitIndex()) == 0 then
        local spec = self.spec_sprayer
        local hasSource = false
        for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
            if #spec.fillTypeSources[supportedSprayType] > 0 then
                hasSource = true
                break
            end
        end
        if not hasSource then
            return false
        end
    end
    if self.rootVehicle.getIsFieldWorkActive == nil or not self.rootVehicle:getIsFieldWorkActive() then
        return false
    end
    local spec = self.spec_sprayer
    local hasSource
    if spec.isSlurryTanker then
        if g_currentMission.missionInfo.helperSlurrySource > 1 then
            ::l16::
            return true
        end
    end
    if spec.isManureSpreader then
        hasSource = true
        if g_currentMission.missionInfo.helperManureSource <= 1 then
            goto l18
        end
    else
        ::l18::
        hasSource = spec.isFertilizerSprayer
        if hasSource then
            hasSource = g_currentMission.missionInfo.helperBuyFertilizer
        end
    end
    goto l16
end
function Sprayer:getExternalFill(fillType, dt)
    local found = false
    local fillUnitIndex = self:getSprayerFillUnitIndex()
    local allowLiquidManure = self:getFillUnitAllowsFillType(fillUnitIndex, FillType.LIQUIDMANURE)
    local allowDigestate = self:getFillUnitAllowsFillType(fillUnitIndex, FillType.DIGESTATE)
    local allowManure = self:getFillUnitAllowsFillType(fillUnitIndex, FillType.MANURE)
    local allowLiquidFertilizer = self:getFillUnitAllowsFillType(fillUnitIndex, FillType.LIQUIDFERTILIZER)
    local allowFertilizer = self:getFillUnitAllowsFillType(fillUnitIndex, FillType.FERTILIZER)
    local allowHerbicide = self:getFillUnitAllowsFillType(fillUnitIndex, FillType.HERBICIDE)
    local usage = 0
    local farmId = self:getActiveFarm()
    local statsFarmId = self:getLastTouchedFarmlandFarmId()
    if fillType == FillType.LIQUIDMANURE or (fillType == FillType.DIGESTATE or fillType == FillType.UNKNOWN and (allowLiquidManure or allowDigestate)) then
        if g_currentMission.missionInfo.helperSlurrySource == 2 then
            found = true
            if g_currentMission.economyManager:getCostPerLiter(FillType.LIQUIDMANURE, false) then
                fillType = FillType.LIQUIDMANURE
            else
                fillType = FillType.DIGESTATE
            end
            usage = self:getSprayerUsage(fillType, dt)
            if self.isServer then
                local price = usage * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5
                g_farmManager:updateFarmStats(statsFarmId, "expenses", price)
                g_currentMission:addMoney(-price, farmId, MoneyType.PURCHASE_FERTILIZER)
            end
        elseif g_currentMission.missionInfo.helperSlurrySource > 2 then
            local price = g_currentMission.liquidManureLoadingStations[g_currentMission.missionInfo.helperSlurrySource - 2]
            if self.isServer and price ~= nil then
                usage = self:getSprayerUsage(FillType.LIQUIDMANURE, dt)
                if usage - price:removeFillLevel(FillType.LIQUIDMANURE, usage, farmId or self:getOwnerFarmId()) > 1e-6 then
                    found = true
                    fillType = FillType.LIQUIDMANURE
                elseif usage - price:removeFillLevel(FillType.DIGESTATE, usage, farmId or self:getOwnerFarmId()) > 1e-6 then
                    found = true
                    fillType = FillType.DIGESTATE
                end
            end
        end
    elseif fillType == FillType.MANURE or fillType == FillType.UNKNOWN and allowManure then
        if g_currentMission.missionInfo.helperManureSource == 2 then
            found = true
            fillType = FillType.MANURE
            usage = self:getSprayerUsage(fillType, dt)
            if self.isServer then
                local price = usage * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5
                g_farmManager:updateFarmStats(statsFarmId, "expenses", price)
                g_currentMission:addMoney(-price, farmId, MoneyType.PURCHASE_FERTILIZER)
            end
        elseif g_currentMission.missionInfo.helperManureSource > 2 then
            local price = g_currentMission.manureLoadingStations[g_currentMission.missionInfo.helperManureSource - 2]
            if self.isServer and price ~= nil then
                usage = self:getSprayerUsage(FillType.MANURE, dt)
                if usage - price:removeFillLevel(FillType.MANURE, usage, farmId or self:getOwnerFarmId()) > 1e-6 then
                    found = true
                    fillType = FillType.MANURE
                end
            end
        end
    elseif (fillType == FillType.FERTILIZER or (fillType == FillType.LIQUIDFERTILIZER or (fillType == FillType.HERBICIDE or (fillType == FillType.LIME or fillType == FillType.UNKNOWN and (allowLiquidFertilizer or (allowFertilizer or allowHerbicide)))))) and g_currentMission.missionInfo.helperBuyFertilizer then
        found = true
        if fillType == FillType.UNKNOWN then
            if allowLiquidFertilizer then
                fillType = FillType.LIQUIDFERTILIZER
            elseif allowFertilizer then
                fillType = FillType.FERTILIZER
            elseif allowHerbicide then
                fillType = FillType.HERBICIDE
            end
        end
        usage = self:getSprayerUsage(fillType, dt)
        if self.isServer then
            local price = usage * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5
            g_farmManager:updateFarmStats(statsFarmId, "expenses", price)
            g_currentMission:addMoney(-price, farmId, MoneyType.PURCHASE_FERTILIZER)
        end
    end
    if found then
        return fillType, usage
    else
        return FillType.UNKNOWN, 0
    end
end
function Sprayer:getAreEffectsVisible()
    return self.spec_sprayer.workAreaParameters.lastSprayTime + 100 > g_time
end
function Sprayer:updateSprayerEffects(force)
    local spec = self.spec_sprayer
    local effectsState = self:getAreEffectsVisible()
    if effectsState ~= spec.lastEffectsState or force then
        if effectsState then
            local fillUnitIndex = self:getSprayerFillUnitIndex()
            local fillType = self:getFillUnitLastValidFillType(fillUnitIndex)
            if fillType == FillType.UNKNOWN then
                fillType = self:getFillUnitFirstSupportedFillType(fillUnitIndex)
            end
            g_effectManager:setEffectTypeInfo(spec.effects, fillType)
            g_effectManager:startEffects(spec.effects)
            g_soundManager:playSamples(spec.samples.spray)
            local sprayType = self:getActiveSprayType()
            if sprayType ~= nil then
                g_effectManager:setEffectTypeInfo(sprayType.effects, fillType)
                g_effectManager:startEffects(sprayType.effects)
                g_animationManager:startAnimations(sprayType.animationNodes)
                g_soundManager:playSamples(sprayType.samples.spray)
            end
            g_animationManager:startAnimations(spec.animationNodes)
        else
            g_effectManager:stopEffects(spec.effects)
            g_animationManager:stopAnimations(spec.animationNodes)
            g_soundManager:stopSamples(spec.samples.spray)
            for _, sprayType in ipairs(spec.sprayTypes) do
                g_effectManager:stopEffects(sprayType.effects)
                g_animationManager:stopAnimations(sprayType.animationNodes)
                g_soundManager:stopSamples(sprayType.samples.spray)
            end
        end
        spec.lastEffectsState = effectsState
    end
end
function Sprayer:getSprayerUsage(fillType, dt)
    if fillType == FillType.UNKNOWN then
        return 0
    end
    local spec = self.spec_sprayer
    local scale = Utils.getNoNil(spec.usageScale.fillTypeScales[fillType], spec.usageScale.default)
    local litersPerSecond = 1
    local sprayType = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
    if sprayType ~= nil then
        litersPerSecond = sprayType.litersPerSecond
    end
    local usageScale = spec.usageScale
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
    return scale * litersPerSecond * self.speedLimit * workWidth * dt * 0.001
end
function Sprayer:getUseSprayerAIRequirements()
    return true
end
function Sprayer:setSprayerAITerrainDetailProhibitedRange(fillType)
    if self:getUseSprayerAIRequirements() and self.addAITerrainDetailProhibitedRange ~= nil then
        self:clearAITerrainDetailRequiredRange()
        self:clearAITerrainDetailProhibitedRange()
        self:clearAIFruitRequirements()
        self:clearAIFruitProhibitions()
        local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
        if sprayTypeDesc ~= nil then
            if sprayTypeDesc.isHerbicide then
                local weedSystem = g_currentMission.weedSystem
                if weedSystem ~= nil then
                    local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
                    local replacementData = weedSystem:getHerbicideReplacements()
                    if replacementData.weed ~= nil then
                        local startState = -1
                        local lastState = -1
                        for sourceState, targetState in pairs(replacementData.weed.replacements) do
                            if startState == -1 then
                                startState = sourceState
                            elseif sourceState ~= lastState + 1 then
                                self:addAIFruitRequirement(nil, startState, lastState, weedMapId, weedFirstChannel, weedNumChannels)
                            end
                        end
                        if startState ~= -1 then
                            self:addAIFruitRequirement(nil, startState, lastState, weedMapId, weedFirstChannel, weedNumChannels)
                        end
                    end
                end
            elseif sprayTypeDesc.isFertilizer then
                self:addAIGroundTypeRequirements(Sprayer.AI_REQUIRED_GROUND_TYPES)
                local weedSystem = g_currentMission
                local weedMapId, weedFirstChannel, weedNumChannels = weedSystem.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
                local replacementData, startState, lastState = weedSystem.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
                local sprayLevelMaxValue = weedSystem.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
                self:addAIFruitProhibitions(0, sprayTypeDesc.sprayGroundType, sprayTypeDesc.sprayGroundType, weedMapId, weedFirstChannel, weedNumChannels)
                self:addAIFruitProhibitions(0, sprayLevelMaxValue, sprayLevelMaxValue, replacementData, startState, lastState)
            elseif sprayTypeDesc.isLime then
                self:addAIGroundTypeRequirements(Sprayer.AI_REQUIRED_GROUND_TYPES)
                local weedMapId, weedFirstChannel, weedNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
                self:addAIFruitProhibitions(0, sprayTypeDesc.sprayGroundType, sprayTypeDesc.sprayGroundType, weedMapId, weedFirstChannel, weedNumChannels)
            end
            if sprayTypeDesc.isHerbicide or (sprayTypeDesc.isFertilizer or sprayTypeDesc.isLime) then
                for weedNumChannels, replacementData in pairs(g_fruitTypeManager:getFruitTypes()) do
                    if replacementData.terrainDataPlaneId ~= nil and (string.lower(replacementData.name) ~= "grass" and (replacementData.minHarvestingGrowthState ~= nil and replacementData.maxHarvestingGrowthState ~= nil)) then
                        self:addAIFruitProhibitions(replacementData.index, replacementData.minHarvestingGrowthState, replacementData.maxHarvestingGrowthState)
                    end
                end
            end
        end
    end
end
function Sprayer:getSprayerFillUnitIndex()
    local sprayType = self:getActiveSprayType()
    if sprayType == nil then
        return self.spec_sprayer.fillUnitIndex
    else
        return sprayType.fillUnitIndex
    end
end
function Sprayer:loadSprayTypeFromXML(xmlFile, key, sprayType)
    sprayType.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex", 1)
    sprayType.unloadInfoIndex = xmlFile:getValue(key .. "#unloadInfoIndex", 1)
    sprayType.fillVolumeIndex = xmlFile:getValue(key .. "#fillVolumeIndex")
    sprayType.supportsVariableWorkWidth = xmlFile:getValue(key .. "#supportsVariableWorkWidth", true)
    sprayType.samples = {}
    sprayType.samples.work = g_soundManager:loadSamplesFromXML(xmlFile, key .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    sprayType.samples.spray = g_soundManager:loadSamplesFromXML(xmlFile, key .. ".sounds", "spray", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    sprayType.effects = g_effectManager:loadEffect(xmlFile, key .. ".effects", self.components, self, self.i3dMappings)
    sprayType.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
    sprayType.turnedAnimation = xmlFile:getValue(key .. ".turnedAnimation#name", "")
    sprayType.turnedAnimationTurnOnSpeedScale = xmlFile:getValue(key .. ".turnedAnimation#turnOnSpeedScale", 1)
    sprayType.turnedAnimationTurnOffSpeedScale = xmlFile:getValue(key .. ".turnedAnimation#turnOffSpeedScale", -sprayType.turnedAnimationTurnOnSpeedScale)
    sprayType.turnedAnimationExternalFill = xmlFile:getValue(key .. ".turnedAnimation#externalFill", true)
    if self.loadAIImplementBaseSetupFromXML ~= nil then
        self:loadAIImplementBaseSetupFromXML(xmlFile, key .. ".ai", function(_)
            -- upvalues: (copy) self, (copy) sprayType
            return self:getIsSprayTypeActive(sprayType)
        end)
    end
    local fillTypesStr = xmlFile:getValue(key .. "#fillTypes")
    if fillTypesStr ~= nil then
        sprayType.fillTypes = fillTypesStr:split(" ")
    end
    sprayType.objectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, sprayType.objectChanges, self.components, self)
    ObjectChangeUtil.setObjectChanges(sprayType.objectChanges, false, self, self.setMovingToolDirty)
    sprayType.usageScale = {}
    if xmlFile:hasProperty(key .. ".usageScales") then
        sprayType.usageScale.workingWidth = xmlFile:getValue(key .. ".usageScales#workingWidth", 12)
        sprayType.usageScale.workAreaIndex = xmlFile:getValue(key .. ".usageScales#workAreaIndex")
    else
        sprayType.usageScale.workingWidth = self.spec_sprayer.usageScale.workingWidth
        sprayType.usageScale.workAreaIndex = self.spec_sprayer.usageScale.workAreaIndex
    end
    return true
end
function Sprayer:getActiveSprayType()
    for _, sprayType in ipairs(self.spec_sprayer.sprayTypes) do
        if self:getIsSprayTypeActive(sprayType) then
            return sprayType
        end
    end
    return nil
end
function Sprayer:getIsSprayTypeActive(sprayType)
    if sprayType.fillTypes ~= nil then
        local retValue = false
        local currentFillType = self:getFillUnitFillType(sprayType.fillUnitIndex or self.spec_sprayer.fillUnitIndex)
        for _, fillType in ipairs(sprayType.fillTypes) do
            if currentFillType == g_fillTypeManager:getFillTypeIndexByName(fillType) then
                retValue = true
            end
        end
        if not retValue then
            return false
        end
    end
    return true
end
function Sprayer:setSprayerDoubledAmountActive(isActive, noEventSend)
    local spec = self.spec_sprayer
    if isActive ~= spec.doubledAmountIsActive then
        spec.doubledAmountIsActive = isActive
        SprayerDoubledAmountEvent.sendEvent(self, isActive, noEventSend)
    end
end
function Sprayer:getSprayerDoubledAmountActive(sprayTypeIndex)
    local spec = self.spec_sprayer
    if not spec.isFertilizerSprayer then
        if sprayTypeIndex == nil then
            return spec.doubledAmountIsActive, true
        end
        local desc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
        if desc == nil then
            return spec.doubledAmountIsActive, true
        end
        if desc.isFertilizer then
            return spec.doubledAmountIsActive, true
        end
    end
    return false, false
end
function Sprayer:getDrawFirstFillText(superFunc)
    if self.isClient and (self.spec_sprayer.needsToBeFilledToTurnOn and (self:getIsActiveForInput() and (self:getIsSelected() and not self.isAlwaysTurnedOn))) then
        local fillUnitIndex = self:getSprayerFillUnitIndex()
        if not self:getCanBeTurnedOn() and (self:getFillUnitFillLevel(fillUnitIndex) <= 0 and self:getFillUnitCapacity(fillUnitIndex) > 0) then
            return true
        end
    end
    return superFunc(self)
end
function Sprayer:getAreControlledActionsAllowed(superFunc)
    local spec = self.spec_sprayer
    if spec.needsToBeFilledToTurnOn and (self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0) then
        return false, g_i18n:getText("info_firstFillTheTool")
    else
        return superFunc(self)
    end
end
function Sprayer:getCanToggleTurnedOn(superFunc)
    if self.isClient and (self.spec_sprayer.needsToBeFilledToTurnOn and (not self:getCanBeTurnedOn() and self:getFillUnitCapacity(self:getSprayerFillUnitIndex()) <= 0)) then
        return false
    else
        return superFunc(self)
    end
end
function Sprayer:getCanBeTurnedOn(superFunc)
    local spec = self.spec_sprayer
    if not spec.allowsSpraying then
        return false
    end
    if self:getFillUnitFillLevel(self:getSprayerFillUnitIndex()) <= 0 and (spec.needsToBeFilledToTurnOn and not self:getIsAIActive()) then
        local sprayVehicle = nil
        for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
            for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
                local vehicle = src.vehicle
                if vehicle:getFillUnitFillType(src.fillUnitIndex) == supportedSprayType and vehicle:getFillUnitFillLevel(src.fillUnitIndex) > 0 then
                    sprayVehicle = vehicle
                    break
                end
            end
        end
        if sprayVehicle == nil then
            return false
        end
    end
    return superFunc(self)
end
function Sprayer:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = superFunc(self, workArea, xmlFile, key)
    if workArea.type == WorkAreaType.DEFAULT then
        workArea.type = WorkAreaType.SPRAYER
    end
    workArea.sprayType = xmlFile:getValue(key .. "#sprayType")
    return retValue
end
function Sprayer:getIsWorkAreaActive(superFunc, workArea)
    if workArea.sprayType ~= nil then
        local sprayType = self:getActiveSprayType()
        if sprayType ~= nil and sprayType.index ~= workArea.sprayType then
            return false
        end
    end
    return superFunc(self, workArea)
end
function Sprayer:doCheckSpeedLimit(superFunc)
    return not superFunc(self) and self:getIsTurnedOn() and self.spec_sprayer.useSpeedLimit
end
function Sprayer:getRawSpeedLimit(superFunc)
    local spec = self.spec_sprayer
    local sprayType = nil
    if spec.workAreaParameters ~= nil then
        sprayType = spec.workAreaParameters.sprayType
    end
    if self:getSprayerDoubledAmountActive(sprayType) and self:getIsTurnedOn() then
        return spec.doubledAmountSpeed
    else
        return superFunc(self)
    end
end
function Sprayer:getFillVolumeUVScrollSpeed(superFunc, fillVolumeIndex)
    local spec = self.spec_sprayer
    local sprayerFillVolumeIndex = spec.fillVolumeIndex
    local sprayType = self:getActiveSprayType()
    if sprayType ~= nil then
    end
    if fillVolumeIndex == sprayerFillVolumeIndex and (self:getIsTurnedOn() and not self:getIsSprayerExternallyFilled()) then
        return spec.dischargeUVScrollSpeed[1], spec.dischargeUVScrollSpeed[2], spec.dischargeUVScrollSpeed[3]
    else
        return superFunc(self, fillVolumeIndex)
    end
end
function Sprayer:getAIRequiresTurnOffOnHeadland(superFunc)
    return true
end
function Sprayer:getDirtMultiplier(superFunc)
    if self.spec_sprayer.isWorking then
        return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    else
        return superFunc(self)
    end
end
function Sprayer:getWearMultiplier(superFunc)
    if self.spec_sprayer.isWorking then
        return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
    else
        return superFunc(self)
    end
end
function Sprayer:getEffectByNode(superFunc, node)
    local spec = self.spec_sprayer
    local i = 1
    for i = i, #spec.effects do
        local effect = spec.effects[i]
        if node == effect.node then
            return effect
        end
    end
    local i = 1
    for i = i, #spec.sprayTypes do
        local effect = spec.sprayTypes[i]
        local j = 1
        for j = j, #effect.effects do
            local effect = effect.effects[j]
            if node == effect.node then
                return effect
            end
        end
    end
    return superFunc(self, node)
end
function Sprayer:getVariableWorkWidthUsage(superFunc)
    local usage = superFunc(self)
    if usage == nil then
        return not self:getIsTurnedOn() and 0 or self.spec_sprayer.workAreaParameters.usagePerMin
    else
        return usage
    end
end
function Sprayer:getAIImplementUseVineSegment(_, placeable, segment, segmentSide)
    local startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ = placeable:getSegmentSideArea(segment, segmentSide)
    local area, areaTotal = AIVehicleUtil.getAIAreaOfVehicle(self, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    if areaTotal <= 0 then
        return false
    end
    return area / areaTotal > 0.1
end
function Sprayer:onTurnedOn()
    if self.isClient then
        self:updateSprayerEffects()
        if self.spec_sprayer.animationName ~= "" and self.playAnimation ~= nil then
            self:playAnimation(spec.animationName, 1, self:getAnimationTime(spec.animationName), true)
        end
        g_soundManager:playSamples(spec.samples.work)
        local sprayType = self:getActiveSprayType()
        if sprayType ~= nil then
            g_soundManager:playSamples(sprayType.samples.work)
            if sprayType.turnedAnimationExternalFill or not self:getIsSprayerExternallyFilled() then
                self:playAnimation(sprayType.turnedAnimation, sprayType.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(sprayType.turnedAnimation), true)
            end
        end
        if spec.turnedAnimationExternalFill or not self:getIsSprayerExternallyFilled() then
            self:playAnimation(spec.turnedAnimation, spec.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(spec.turnedAnimation), true)
        end
    end
end
function Sprayer:onTurnedOff()
    if self.isClient then
        self:updateSprayerEffects()
        if self.spec_sprayer.animationName ~= "" and self.stopAnimation ~= nil then
            self:stopAnimation(spec.animationName, true)
        end
        g_soundManager:stopSamples(spec.samples.work)
        for _, sprayType in ipairs(spec.sprayTypes) do
            g_soundManager:stopSamples(sprayType.samples.work)
            self:playAnimation(sprayType.turnedAnimation, sprayType.turnedAnimationTurnOffSpeedScale, self:getAnimationTime(sprayType.turnedAnimation), true)
        end
        self:playAnimation(spec.turnedAnimation, spec.turnedAnimationTurnOffSpeedScale, self:getAnimationTime(spec.turnedAnimation), true)
    end
end
function Sprayer.onPreDetach(_, attacherVehicle, _)
    if attacherVehicle.setIsTurnedOn ~= nil and attacherVehicle:getIsTurnedOn() then
        attacherVehicle:setIsTurnedOn(false)
    end
end
function Sprayer:onStartWorkAreaProcessing(dt)
    local spec = self.spec_sprayer
    local fillUnitIndex = self:getSprayerFillUnitIndex()
    local sprayVehicle = nil
    local sprayVehicleFillUnitIndex = nil
    local fillType = self:getFillUnitFillType(fillUnitIndex)
    local usage = self:getSprayerUsage(fillType, dt)
    local sprayFillLevel = self:getFillUnitFillLevel(fillUnitIndex)
    if sprayFillLevel > 0 then
        sprayVehicle = self
        sprayVehicleFillUnitIndex = fillUnitIndex
    else
        for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
            for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
                local vehicle = src.vehicle
                if vehicle:getIsFillUnitActive(src.fillUnitIndex) then
                    local vehicleFillType = vehicle:getFillUnitFillType(src.fillUnitIndex)
                    local vehicleFillLevel = vehicle:getFillUnitFillLevel(src.fillUnitIndex)
                    if vehicleFillLevel > 0 and vehicleFillType == supportedSprayType then
                        fillType = vehicle:getFillUnitFillType(src.fillUnitIndex)
                        usage = self:getSprayerUsage(fillType, dt)
                        sprayVehicle = vehicle
                        sprayFillLevel = vehicleFillLevel
                        break
                    end
                elseif self:getIsAIActive() and (vehicle.setIsTurnedOn ~= nil and not vehicle:getIsTurnedOn()) then
                    vehicle:setIsTurnedOn(true)
                end
            end
        end
    end
    local isExternallyFilled = self:getIsSprayerExternallyFilled()
    local externalFillType, externalUsage
    if isExternallyFilled and self:getIsTurnedOn() then
        externalFillType, externalUsage = self:getExternalFill(fillType, dt)
        if externalFillType == FillType.UNKNOWN then
            externalUsage = sprayFillLevel
            externalFillType = fillType
        else
            sprayVehicle = nil
            sprayVehicleFillUnitIndex = nil
            usage = externalUsage
        end
    else
        externalUsage = sprayFillLevel
        externalFillType = fillType
    end
    if isExternallyFilled ~= spec.workAreaParameters.lastIsExternallyFilled then
        local externalFillType = self:getActiveSprayType()
        if externalFillType ~= nil then
            if isExternallyFilled then
                if not externalFillType.turnedAnimationExternalFill and self:getIsAnimationPlaying(externalFillType.turnedAnimation) then
                    self:stopAnimation(externalFillType.turnedAnimation)
                end
            elseif not self:getIsAnimationPlaying(externalFillType.turnedAnimation) then
                self:playAnimation(externalFillType.turnedAnimation, externalFillType.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(externalFillType.turnedAnimation), true)
            end
        end
        if isExternallyFilled then
            if not spec.turnedAnimationExternalFill and self:getIsAnimationPlaying(spec.turnedAnimation) then
                self:stopAnimation(spec.turnedAnimation)
            end
        elseif not self:getIsAnimationPlaying(spec.turnedAnimation) then
            self:playAnimation(spec.turnedAnimation, spec.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(spec.turnedAnimation), true)
        end
        spec.workAreaParameters.lastIsExternallyFilled = isExternallyFilled
    end
    if self.isServer and (externalFillType ~= FillType.UNKNOWN and externalFillType ~= spec.workAreaParameters.sprayFillType) then
        self:setSprayerAITerrainDetailProhibitedRange(externalFillType)
    end
    spec.workAreaParameters.sprayType = g_sprayTypeManager:getSprayTypeIndexByFillTypeIndex(externalFillType)
    spec.workAreaParameters.sprayFillType = externalFillType
    spec.workAreaParameters.sprayFillLevel = externalUsage
    spec.workAreaParameters.usage = usage
    spec.workAreaParameters.usagePerMin = usage / dt * 1000 * 60
    spec.workAreaParameters.sprayVehicle = sprayVehicle
    spec.workAreaParameters.sprayVehicleFillUnitIndex = sprayVehicleFillUnitIndex
    spec.workAreaParameters.lastChangedArea = 0
    spec.workAreaParameters.lastTotalArea = 0
    spec.workAreaParameters.lastStatsArea = 0
    spec.workAreaParameters.isActive = false
    spec.isWorking = false
end
function Sprayer:onEndWorkAreaProcessing(dt, _)
    local spec = self.spec_sprayer
    if self.isServer and spec.workAreaParameters.isActive then
        local sprayVehicle = spec.workAreaParameters.sprayVehicle
        local usage = spec.workAreaParameters.usage
        if sprayVehicle ~= nil then
            local unloadInfoIndex = spec.unloadInfoIndex
            local sprayType = self:getActiveSprayType()
            if sprayType ~= nil then
                unloadInfoIndex = sprayType.unloadInfoIndex
            end
            local unloadInfo = self:getFillVolumeUnloadInfo(unloadInfoIndex)
            sprayVehicle:addFillUnitFillLevel(self:getOwnerFarmId(), spec.workAreaParameters.sprayVehicleFillUnitIndex, -usage, spec.workAreaParameters.sprayFillType, ToolType.UNDEFINED, unloadInfo)
        end
        local sprayVehicleFillUnitIndex = MathUtil.areaToHa(spec.workAreaParameters.lastStatsArea, g_currentMission:getFruitPixelsToSqm())
        local sprayFillType = self:getLastTouchedFarmlandFarmId()
        g_farmManager:updateFarmStats(sprayFillType, "sprayedHectares", sprayVehicleFillUnitIndex)
        g_farmManager:updateFarmStats(sprayFillType, "sprayedTime", dt / 60000)
        g_farmManager:updateFarmStats(sprayFillType, "sprayUsage", usage)
        self:updateLastWorkedArea(spec.workAreaParameters.lastStatsArea)
    end
    self:updateSprayerEffects()
end
function Sprayer:onStateChange(state, _)
    if state == VehicleStateChange.ATTACH or (state == VehicleStateChange.DETACH or state == VehicleStateChange.FILLTYPE_CHANGE) then
        local spec = self.spec_sprayer
        spec.fillTypeSources = {}
        local supportedFillTypes = self:getFillUnitSupportedFillTypes(self:getSprayerFillUnitIndex())
        spec.supportedSprayTypes = {}
        if supportedFillTypes ~= nil then
            for fillType, supported in pairs(supportedFillTypes) do
                if supported then
                    spec.fillTypeSources[fillType] = {}
                    table.insert(spec.supportedSprayTypes, fillType)
                end
            end
        end
        local root = self.rootVehicle
        FillUnit.addFillTypeSources(spec.fillTypeSources, root, self, spec.supportedSprayTypes)
    end
end
function Sprayer:onSetLowered(isLowered)
    local spec = self.spec_sprayer
    if self.isServer then
        if spec.activateOnLowering then
            if self:getCanBeTurnedOn() then
                self:setIsTurnedOn(isLowered)
            else
                spec.pendingActivationAfterLowering = true
            end
        end
        if not isLowered then
            spec.pendingActivationAfterLowering = false
        end
    end
    if spec.activateTankOnLowering then
        for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
            for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
                local vehicle = src.vehicle
                local fillLevel = vehicle:getFillUnitFillLevel(src.fillUnitIndex)
                if vehicle.getIsTurnedOn ~= nil then
                    if isLowered then
                        if fillLevel > 0 and vehicle:getCanBeTurnedOn() then
                            vehicle:setIsTurnedOn(true, true)
                        end
                    else
                        vehicle:setIsTurnedOn(false, true)
                    end
                end
            end
        end
    end
end
function Sprayer:onFillUnitFillLevelChanged(fillUnitIndex, _, fillType, _, _, _)
    local spec = self.spec_sprayer
    if fillUnitIndex == spec.fillUnitIndex and (self:getFillUnitFillLevel(fillUnitIndex) == 0 and (self:getIsTurnedOn() and not self:getIsAIActive())) then
        local hasValidSource = false
        if spec.fillTypeSources[fillType] ~= nil then
            for _, src in ipairs(spec.fillTypeSources[fillType]) do
                local vehicle = src.vehicle
                if vehicle:getIsFillUnitActive(src.fillUnitIndex) then
                    local vehicleFillType = vehicle:getFillUnitFillType(src.fillUnitIndex)
                    if vehicle:getFillUnitFillLevel(src.fillUnitIndex) > 0 and vehicleFillType == fillType then
                        hasValidSource = true
                    end
                end
            end
        end
        if not hasValidSource then
            self:setIsTurnedOn(false)
            if Platform.gameplay.automaticVehicleControl then
                self.rootVehicle:playControlledActions()
            end
        end
    end
end
function Sprayer:onSprayTypeChange(activeSprayType)
    for _, sprayType in ipairs(self.spec_sprayer.sprayTypes) do
        ObjectChangeUtil.setObjectChanges(sprayType.objectChanges, sprayType == activeSprayType, self, self.setMovingToolDirty)
    end
    if self.setVariableWorkWidthActive ~= nil then
        self:setVariableWorkWidthActive(activeSprayType == nil or activeSprayType.supportsVariableWorkWidth)
    end
end
function Sprayer:onAIImplementEnd()
    local spec = self.spec_sprayer
    for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
        for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
            local vehicle = src.vehicle
            if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
                vehicle:setIsTurnedOn(false, true)
            end
        end
    end
end
function Sprayer:onVariableWorkWidthSectionChanged()
    self:updateSprayerEffects(true)
end
function Sprayer.getDefaultSpeedLimit()
    return 15
end