Tedder = {}
Tedder.CLIENT_DM_UPDATE_RADIUS = 50
function Tedder.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("tedder", false, true, true)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Tedder")
    schema:register(XMLValueType.STRING, "vehicle.tedder#fillTypeConverter", "Fill type converter name")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.tedder.effects.effect(?)")
    schema:register(XMLValueType.INT, "vehicle.tedder.effects.effect(?)#workAreaIndex", "Work area index", 1)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.tedder.effects.effect(?).sounds", "work")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.tedder.animationNodes")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.tedder.sounds", "work(?)")
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".tedder#dropWindrowWorkAreaIndex", "Drop work area index", 1)
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".tedder#dropWindrowWorkAreaIndex", "Drop work area index", 1)
    schema:setXMLSpecializationType()
end
function Tedder.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function Tedder.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "preprocessTedderArea", Tedder.preprocessTedderArea)
    SpecializationUtil.registerFunction(vehicleType, "processTedderArea", Tedder.processTedderArea)
    SpecializationUtil.registerFunction(vehicleType, "processDropArea", Tedder.processDropArea)
end
function Tedder.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Tedder.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Tedder.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Tedder.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Tedder.doCheckSpeedLimit)
end
function Tedder.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Tedder)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", Tedder)
end
function Tedder:onLoad(_)
    local spec = self.spec_tedder
    spec.fillTypeConverters = {}
    spec.fillTypeConvertersReverse = {}
    local converter = self.xmlFile:getValue("vehicle.tedder#fillTypeConverter")
    if converter == nil then
        printWarning(string.format("Warning: Missing fill type converter in \'%s\'", self.configFileName))
    else
        local data = g_fillTypeManager:getConverterDataByName(converter)
        if data ~= nil then
            for input, converted in pairs(data) do
                spec.fillTypeConverters[input] = converted
                if spec.fillTypeConvertersReverse[converted.targetFillTypeIndex] == nil then
                    spec.fillTypeConvertersReverse[converted.targetFillTypeIndex] = {}
                end
                table.insert(spec.fillTypeConvertersReverse[converted.targetFillTypeIndex], input)
            end
        end
    end
    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.tedder.animationNodes", self.components, self, self.i3dMappings)
        spec.effects = {}
        spec.workAreaToEffects = {}
        local data = 0
        while true do
            local key = string.format("vehicle.tedder.effects.effect(%d)", data)
            if not self.xmlFile:hasProperty(key) then
                break
            end
            local effects = g_effectManager:loadEffect(self.xmlFile, key, self.components, self, self.i3dMappings)
            if effects ~= nil then
                local effect = {
                    ["effects"] = effects,
                    ["workAreaIndex"] = self.xmlFile:getValue(key .. "#workAreaIndex", 1),
                    ["activeTime"] = -1,
                    ["activeTimeDuration"] = 250,
                    ["isActive"] = false,
                    ["isActiveSent"] = false,
                    ["samples"] = {}
                }
                effect.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, key .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
                table.insert(spec.effects, effect)
            end
            data = data + 1
        end
        spec.samples = {}
        spec.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.tedder.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.lastDroppedLiters = 0
    spec.stoneLastState = 0
    spec.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("TEDDER")
    spec.fillTypesDirtyFlag = self:getNextDirtyFlag()
    spec.effectDirtyFlag = self:getNextDirtyFlag()
    if self.addAIDensityHeightTypeRequirement ~= nil then
        self:addAIDensityHeightTypeRequirement(FillType.GRASS_WINDROW)
    end
end
function Tedder:onPostLoad(_)
    local spec = self.spec_tedder
    local i = #spec.effects
    for i = i, 1, -1 do
        local effect = spec.effects[i]
        local workArea = self:getWorkAreaByIndex(effect.workAreaIndex)
        if workArea == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid workAreaIndex \'%d\' for effect \'vehicle.tedder.effects.effect(%d)\'!", effect.workAreaIndex, i)
            table.insert(spec.effects, i)
        else
            effect.tedderWorkAreaFillTypeIndex = workArea.tedderWorkAreaIndex
            if spec.workAreaToEffects[workArea.index] == nil then
                spec.workAreaToEffects[workArea.index] = {}
            end
            table.insert(spec.workAreaToEffects[workArea.index], effect)
        end
    end
    if not self.isServer then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", Tedder)
    end
end
function Tedder:onDelete()
    local spec = self.spec_tedder
    if spec.effects ~= nil then
        for _, effect in ipairs(spec.effects) do
            g_effectManager:deleteEffects(effect.effects)
            if effect.samples ~= nil then
                g_soundManager:deleteSample(effect.samples.work)
            end
        end
    end
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples.work)
    end
    g_animationManager:deleteAnimations(spec.animationNodes)
end
function Tedder:onReadStream(streamId, _)
    local spec = self.spec_tedder
    for index, _ in ipairs(spec.tedderWorkAreaFillTypes) do
        local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
        spec.tedderWorkAreaFillTypes[index] = fillType
    end
    for index, _ in ipairs(spec.effects) do
        if streamReadBool(streamId) then
            g_effectManager:setEffectTypeInfo(_.effects, spec.tedderWorkAreaFillTypes[_.tedderWorkAreaFillTypeIndex])
            g_effectManager:startEffects(_.effects)
        else
            g_effectManager:stopEffects(_.effects)
        end
    end
end
function Tedder:onWriteStream(streamId, _)
    local spec = self.spec_tedder
    for _, fillTypeIndex in ipairs(spec.tedderWorkAreaFillTypes) do
        streamWriteUIntN(streamId, fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
    end
    for _, fillTypeIndex in ipairs(spec.effects) do
        streamWriteBool(streamId, fillTypeIndex.isActiveSent)
    end
end
function Tedder:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for index, _ in ipairs(self.spec_tedder.tedderWorkAreaFillTypes) do
                local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
                spec.tedderWorkAreaFillTypes[index] = fillType
            end
        end
        if streamReadBool(streamId) then
            local anyEffectActive = false
            for _, fillType in ipairs(spec.effects) do
                if streamReadBool(streamId) then
                    local fillType = spec.tedderWorkAreaFillTypes[fillType.tedderWorkAreaFillTypeIndex]
                    g_effectManager:setEffectTypeInfo(fillType.effects, fillType)
                    g_effectManager:startEffects(fillType.effects)
                    anyEffectActive = true
                    if not g_soundManager:getIsSamplePlaying(fillType.samples.work) then
                        g_soundManager:playSample(fillType.samples.work)
                    end
                else
                    g_effectManager:stopEffects(fillType.effects)
                    g_soundManager:stopSample(fillType.samples.work)
                end
            end
            if anyEffectActive then
                if not g_soundManager:getIsSamplePlaying(spec.samples.work[1]) then
                    g_soundManager:playSamples(spec.samples.work)
                    return
                end
            else
                g_soundManager:stopSamples(spec.samples.work)
            end
        end
    end
end
function Tedder:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_tedder
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.fillTypesDirtyFlag) ~= 0) then
            for _, fillTypeIndex in ipairs(spec.tedderWorkAreaFillTypes) do
                streamWriteUIntN(streamId, fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
            end
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.effectDirtyFlag) ~= 0) then
            for _, fillTypeIndex in ipairs(spec.effects) do
                streamWriteBool(streamId, fillTypeIndex.isActiveSent)
            end
        end
    end
end
function Tedder:onUpdateTick(_, _, _, _)
    if self.isServer then
        local anyEffectActive = false
        for _, effect in ipairs(self.spec_tedder.effects) do
            if effect.isActive and g_currentMission.time > effect.activeTime then
                effect.isActive = false
                if effect.isActiveSent then
                    effect.isActiveSent = false
                    self:raiseDirtyFlags(spec.effectDirtyFlag)
                end
                if self.isClient then
                    g_effectManager:stopEffects(effect.effects)
                    g_soundManager:stopSample(effect.samples.work)
                end
            end
        end
        if self.isClient and not anyEffectActive then
            g_soundManager:stopSamples(spec.samples.work)
        end
    end
end
function Tedder:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = superFunc(self, workArea, xmlFile, key)
    if workArea.type == WorkAreaType.DEFAULT then
        workArea.type = WorkAreaType.TEDDER
    end
    if workArea.type == WorkAreaType.TEDDER then
        workArea.dropWindrowWorkAreaIndex = xmlFile:getValue(key .. ".tedder#dropWindrowWorkAreaIndex", 1)
        workArea.litersToDrop = 0
        workArea.lastPickupLiters = 0
        workArea.lastDropFillType = FillType.UNKNOWN
        workArea.lastDroppedLiters = 0
        workArea.tedderParticlesActive = false
        workArea.tedderParticlesActiveSent = false
        local spec = self.spec_tedder
        if spec.tedderWorkAreaFillTypes == nil then
            spec.tedderWorkAreaFillTypes = {}
        end
        table.insert(spec.tedderWorkAreaFillTypes, FruitType.UNKNOWN)
        workArea.tedderWorkAreaIndex = #spec.tedderWorkAreaFillTypes
    end
    return retValue
end
function Tedder:getDirtMultiplier(superFunc)
    local multiplier = superFunc(self)
    if self.spec_tedder.isWorking then
        multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    end
    return multiplier
end
function Tedder:getWearMultiplier(superFunc)
    local spec = self.spec_tedder
    local multiplier = superFunc(self)
    if spec.isWorking then
        multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * (spec.stoneLastState ~= 0 and spec.stoneWearMultiplierData ~= nil and (spec.stoneWearMultiplierData[spec.stoneLastState] or 1) or 1)
    end
    return multiplier
end
function Tedder:doCheckSpeedLimit(superFunc)
    return not superFunc(self) and self:getIsTurnedOn() and self:getIsImplementChainLowered()
end
function Tedder.preprocessTedderArea(_, workArea)
    workArea.lastPickupLiters = 0
    workArea.lastDroppedLiters = 0
end
function Tedder:processTedderArea(workArea, _)
    local spec = self.spec_tedder
    if not self.isServer and self.currentUpdateDistance > Tedder.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local sx, sy, sz = getWorldTranslation(workArea.start)
    local wx, wy, wz = getWorldTranslation(workArea.width)
    local hx, hy, hz = getWorldTranslation(workArea.height)
    local lsx, lsy, lsz, lex, ley, lez, lineRadius = DensityMapHeightUtil.getLineByAreaDimensions(sx, sy, sz, wx, wy, wz, hx, hy, hz, true)
    for targetFillType, inputFillTypes in pairs(spec.fillTypeConvertersReverse) do
        local pickedUpLiters = 0
        for _, inputFillType in ipairs(inputFillTypes) do
            pickedUpLiters = pickedUpLiters + DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, inputFillType, lsx, lsy, lsz, lex, ley, lez, lineRadius, nil, nil, false, nil)
        end
        if pickedUpLiters == 0 and workArea.lastDropFillType ~= FillType.UNKNOWN then
            local targetFillType = workArea.lastDropFillType
        end
        workArea.lastPickupLiters = -pickedUpLiters
        workArea.litersToDrop = workArea.litersToDrop + workArea.lastPickupLiters
        local dropArea = self.spec_workArea.workAreas[workArea.dropWindrowWorkAreaIndex]
        if dropArea ~= nil and workArea.litersToDrop > 0 then
            local dropped = self:processDropArea(dropArea, targetFillType, workArea.litersToDrop)
            workArea.lastDropFillType = targetFillType
            workArea.lastDroppedLiters = dropped
            spec.lastDroppedLiters = spec.lastDroppedLiters + dropped
            workArea.litersToDrop = workArea.litersToDrop - dropped
            if self.isServer then
                local lastSpeed = self:getLastSpeed(true)
                if dropped > 0 and lastSpeed > 0.5 then
                    local _ = false
                    if spec.tedderWorkAreaFillTypes[workArea.tedderWorkAreaIndex] ~= targetFillType then
                        spec.tedderWorkAreaFillTypes[workArea.tedderWorkAreaIndex] = targetFillType
                        self:raiseDirtyFlags(spec.fillTypesDirtyFlag)
                        _ = true
                    end
                    local inputFillType = spec.workAreaToEffects[workArea.index]
                    if inputFillType ~= nil then
                        for _, effect in ipairs(inputFillType) do
                            effect.activeTime = g_currentMission.time + effect.activeTimeDuration
                            if not effect.isActiveSent then
                                effect.isActiveSent = true
                                self:raiseDirtyFlags(spec.effectDirtyFlag)
                            end
                            if self.isClient then
                                if _ then
                                    g_effectManager:setEffectTypeInfo(effect.effects, targetFillType)
                                end
                                if not effect.isActive then
                                    g_effectManager:setEffectTypeInfo(effect.effects, targetFillType)
                                    g_effectManager:startEffects(effect.effects)
                                    g_soundManager:playSample(effect.samples.work)
                                    if not g_soundManager:getIsSamplePlaying(spec.samples.work[1]) then
                                        g_soundManager:playSamples(spec.samples.work)
                                    end
                                end
                                g_effectManager:setDensity(effect.effects, (math.max(lastSpeed / self:getSpeedLimit(), 0.6)))
                            end
                            effect.isActive = true
                        end
                    end
                end
            end
        end
    end
    if self:getLastSpeed() > 0.5 then
        spec.stoneLastState = FSDensityMapUtil.getStoneArea(sx, sz, wx, wz, hx, hz)
    else
        spec.stoneLastState = 0
    end
    local area = MathUtil.vector3Length(lsx - lex, lsy - ley, lsz - lez) * self.lastMovedDistance
    return area, area
end
function Tedder:processDropArea(dropArea, fillType, litersToDrop)
    if not self.isServer and self.currentUpdateDistance > Tedder.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local lsx, lsy, lsz, lex, ley, lez, lineRadius = DensityMapHeightUtil.getLineByArea(dropArea.start, dropArea.width, dropArea.height, true)
    local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self, litersToDrop, fillType, lsx, lsy, lsz, lex, ley, lez, lineRadius, nil, dropArea.lineOffset, false, nil, false)
    dropArea.lineOffset = lineOffset
    return dropped
end
function Tedder:onStartWorkAreaProcessing(_)
    self.spec_tedder.lastDroppedLiters = 0
end
function Tedder:onEndWorkAreaProcessing(_, _)
    local spec = self.spec_tedder
    spec.isWorking = spec.lastDroppedLiters > 0
end
function Tedder:onTurnedOn()
    if self.isClient then
        g_animationManager:startAnimations(self.spec_tedder.animationNodes)
    end
end
function Tedder:onTurnedOff()
    if self.isClient then
        local spec = self.spec_tedder
        g_animationManager:stopAnimations(spec.animationNodes)
        for _, effect in ipairs(spec.effects) do
            g_effectManager:stopEffects(effect.effects)
        end
    end
end
function Tedder.onAIFieldCourseSettingsInitialized(_, fieldCourseSettings)
    fieldCourseSettings.headlandsFirst = true
    fieldCourseSettings.workInitialSegment = true
end
function Tedder:onDeactivate()
    if self.isClient then
        for _, effect in ipairs(self.spec_tedder.effects) do
            g_effectManager:stopEffects(effect.effects)
        end
    end
end
function Tedder.getDefaultSpeedLimit()
    return 15
end