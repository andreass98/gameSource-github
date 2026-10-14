source("dataS/scripts/vehicles/specializations/events/MowerToggleWindrowDropEvent.lua")
Mower = {}
Mower.CLIENT_DM_UPDATE_RADIUS = 50
function Mower.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("mower", false, true, true)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Mower")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.mower.animationNodes")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.mower.cutterEffects")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.mower.dropEffects.dropEffect(?)")
    schema:register(XMLValueType.INT, "vehicle.mower.dropEffects.dropEffect(?)#dropAreaIndex", "Drop area index", 1)
    schema:register(XMLValueType.INT, "vehicle.mower.dropEffects.dropEffect(?)#workAreaIndex", "Work area index", 1)
    schema:register(XMLValueType.STRING, "vehicle.mower#fruitTypeConverter", "Fruit type converter name")
    schema:register(XMLValueType.INT, "vehicle.mower#fillUnitIndex", "Fill unit index")
    schema:register(XMLValueType.FLOAT, "vehicle.mower#pickupFillScale", "Pickup fill scale", 1)
    schema:register(XMLValueType.L10N_STRING, "vehicle.mower.toggleWindrowDrop#enableText", "Enable windrow drop text")
    schema:register(XMLValueType.L10N_STRING, "vehicle.mower.toggleWindrowDrop#disableText", "Disable windrow drop text")
    schema:register(XMLValueType.STRING, "vehicle.mower.toggleWindrowDrop#animationName", "Windrow drop animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.mower.toggleWindrowDrop#animationEnableSpeed", "Animation enable speed", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.mower.toggleWindrowDrop#animationDisableSpeed", "Animation disable speed", "inversed \'animationEnableSpeed\'")
    schema:register(XMLValueType.BOOL, "vehicle.mower.toggleWindrowDrop#startEnabled", "Start windrow drop enabled", false)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.mower.sounds", "cut(?)")
    schema:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_KEY .. ".mower#dropWindrow", "Drop windrow", true)
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".mower#dropAreaIndex", "Drop area index", 1)
    schema:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".mower#dropWindrow", "Drop windrow", true)
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".mower#dropAreaIndex", "Drop area index", 1)
    schema:setXMLSpecializationType()
end
function Mower.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(FruitExtraObjects, specializations)
end
function Mower.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "processMowerArea", Mower.processMowerArea)
    SpecializationUtil.registerFunction(vehicleType, "processDropArea", Mower.processDropArea)
    SpecializationUtil.registerFunction(vehicleType, "getDropArea", Mower.getDropArea)
    SpecializationUtil.registerFunction(vehicleType, "setDropEffectEnabled", Mower.setDropEffectEnabled)
    SpecializationUtil.registerFunction(vehicleType, "setCutSoundEnabled", Mower.setCutSoundEnabled)
    SpecializationUtil.registerFunction(vehicleType, "setUseMowerWindrowDropAreas", Mower.setUseMowerWindrowDropAreas)
end
function Mower.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Mower.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Mower.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Mower.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Mower.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Mower.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFruitExtraObjectTypeData", Mower.getFruitExtraObjectTypeData)
end
function Mower.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Mower)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", Mower)
end
function Mower:onLoad(_)
    local spec = self.spec_mower
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mowerEffects.mowerEffect", "vehicle.mower.dropEffects.dropEffect")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mowerEffects.mowerEffect#mowerCutArea", "vehicle.mower.dropEffects.dropEffect#dropAreaIndex")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.mower.turnOnNodes.turnOnNode", "mower")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mowerStartSound", "vehicle.turnOnVehicle.sounds.start")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mowerStopSound", "vehicle.turnOnVehicle.sounds.stop")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mowerSound", "vehicle.turnOnVehicle.sounds.work")
    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.mower.animationNodes", self.components, self, self.i3dMappings)
        spec.samples = {}
        spec.samples.cut = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.mower.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.dropEffects = {}
    self.xmlFile:iterate("vehicle.mower.dropEffects.dropEffect", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local effects = g_effectManager:loadEffect(self.xmlFile, key, self.components, self, self.i3dMappings)
        if effects ~= nil then
            local dropEffect = {
                ["effects"] = effects,
                ["dropAreaIndex"] = self.xmlFile:getValue(key .. "#dropAreaIndex", 1),
                ["workAreaIndex"] = self.xmlFile:getValue(key .. "#workAreaIndex", 1)
            }
            if self:getWorkAreaByIndex(dropEffect.dropAreaIndex) ~= nil then
                if self:getWorkAreaByIndex(dropEffect.workAreaIndex) == nil then
                    Logging.xmlWarning(self.xmlFile, "Invalid workAreaIndex \'%s\' in \'%s\'", dropEffect.workAreaIndex, key)
                else
                    dropEffect.activeTime = -1
                    dropEffect.activeTimeDuration = 750
                    dropEffect.isActive = false
                    dropEffect.isActiveSent = false
                    table.insert(spec.dropEffects, dropEffect)
                end
            end
            Logging.xmlWarning(self.xmlFile, "Invalid dropAreaIndex \'%s\' in \'%s\'", dropEffect.dropAreaIndex, key)
        end
    end)
    spec.cutterEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.mower.cutterEffects", self.components, self, self.i3dMappings)
    if spec.dropAreas == nil then
        spec.dropAreas = {}
    end
    spec.fruitTypeConverters = {}
    local converter = self.xmlFile:getValue("vehicle.mower#fruitTypeConverter")
    if converter == nil then
        printWarning(string.format("Warning: Missing fruit type converter in \'%s\'", self.configFileName))
    else
        local data = g_fruitTypeManager:getConverterDataByName(converter)
        if data ~= nil then
            for input, converted in pairs(data) do
                spec.fruitTypeConverters[input] = converted
            end
        end
    end
    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.mower#fillUnitIndex")
    spec.pickupFillScale = self.xmlFile:getValue("vehicle.mower#pickupFillScale", 1)
    spec.toggleWindrowDropEnableText = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#enableText", nil, self.customEnvironment, false)
    spec.toggleWindrowDropDisableText = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#disableText", nil, self.customEnvironment, false)
    spec.toggleWindrowDropAnimation = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#animationName")
    spec.enableWindrowDropAnimationSpeed = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#animationEnableSpeed", 1)
    spec.disableWindrowDropAnimationSpeed = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#animationDisableSpeed", -spec.enableWindrowDropAnimationSpeed)
    spec.useWindrowDropAreas = self.xmlFile:getValue("vehicle.mower.toggleWindrowDrop#startEnabled", false)
    spec.workAreaParameters = {}
    spec.workAreaParameters.lastChangedArea = 0
    spec.workAreaParameters.lastStatsArea = 0
    spec.workAreaParameters.lastTotalArea = 0
    spec.workAreaParameters.lastUsedAreas = 0
    spec.workAreaParameters.lastUsedAreasSum = 0
    spec.workAreaParameters.lastUsedAreasPct = 0
    spec.workAreaParameters.lastUsedAreasTime = 0
    spec.workAreaParameters.lastCutTime = -math.huge
    spec.workAreaParameters.lastInputFruitType = FruitType.UNKNOWN
    spec.workAreaParameters.lastInputGrowthState = 0
    spec.isWorking = false
    spec.isCutting = false
    spec.lastDropTime = -math.huge
    spec.effectsAreRunning = false
    spec.lastFruitTypeIndex = FruitType.UNKNOWN
    spec.lastFruitGrowthState = 0
    spec.stoneLastState = 0
    spec.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("MOWER")
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.effectDirtyFlag = self:getNextDirtyFlag()
    if self.addAITerrainDetailRequiredRange ~= nil then
        local _, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local input = FieldGroundType.getValueByType(FieldGroundType.GRASS)
        self:addAITerrainDetailRequiredRange(input, input, groundTypeFirstChannel, groundTypeNumChannels)
        local converted = FieldGroundType.getValueByType(FieldGroundType.SOWN)
        self:addAITerrainDetailRequiredRange(converted, converted, groundTypeFirstChannel, groundTypeNumChannels)
        local harvestReady = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY)
        self:addAITerrainDetailRequiredRange(harvestReady, harvestReady, groundTypeFirstChannel, groundTypeNumChannels)
        local harvestReadyOther = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY_OTHER)
        self:addAITerrainDetailRequiredRange(harvestReadyOther, harvestReadyOther, groundTypeFirstChannel, groundTypeNumChannels)
    end
    if self.addAIFruitRequirement ~= nil then
        for groundTypeNumChannels, input in pairs(spec.fruitTypeConverters) do
            local converted = g_fruitTypeManager:getFruitTypeByIndex(groundTypeNumChannels)
            self:addAIFruitRequirement(converted.index, converted.minHarvestingGrowthState, converted.maxHarvestingGrowthState)
        end
    end
    if #spec.cutterEffects == 0 then
        SpecializationUtil.removeEventListener(self, "onUpdate", Mower)
    end
end
function Mower:onPostLoad(_)
    local spec = self.spec_mower
    spec.workAreas = self:getTypedWorkAreas(WorkAreaType.MOWER)
    local i = 1
    for i = i, #spec.workAreas do
        local workArea = spec.workAreas[i]
        workArea.dropEffects = {}
        for _, dropEffect in pairs(spec.dropEffects) do
            if dropEffect.workAreaIndex == workArea.index then
                table.insert(workArea.dropEffects, dropEffect)
            end
        end
    end
end
function Mower:onDelete()
    local spec = self.spec_mower
    if self.isClient then
        g_animationManager:deleteAnimations(spec.animationNodes)
        if spec.samples ~= nil then
            g_soundManager:deleteSamples(spec.samples.cut)
        end
    end
    if spec.dropEffects ~= nil then
        for _, dropEffect in pairs(spec.dropEffects) do
            g_effectManager:deleteEffects(dropEffect.effects)
        end
    end
    g_effectManager:deleteEffects(spec.cutterEffects)
end
function Mower:onReadStream(streamId, _)
    local spec = self.spec_mower
    if spec.toggleWindrowDropEnableText ~= nil and spec.toggleWindrowDropDisableText ~= nil then
        self:setUseMowerWindrowDropAreas(streamReadBool(streamId), true)
    end
end
function Mower:onWriteStream(streamId, _)
    local spec = self.spec_mower
    if spec.toggleWindrowDropEnableText ~= nil and spec.toggleWindrowDropDisableText ~= nil then
        streamWriteBool(streamId, spec.useWindrowDropAreas)
    end
end
function Mower:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        local spec = self.spec_mower
        if #spec.dropEffects > 0 then
            if streamReadBool(streamId) then
                for _, dropEffect in ipairs(spec.dropEffects) do
                    dropEffect.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
                    self:setDropEffectEnabled(dropEffect, streamReadBool(streamId))
                end
            end
        else
            self:setCutSoundEnabled(streamReadBool(streamId))
        end
        if streamReadBool(streamId) then
            local effectsAreRunning = streamReadBool(streamId)
            if effectsAreRunning then
                spec.lastFruitGrowthState = streamReadUIntN(streamId, 4)
                local inputFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
                if inputFruitType ~= spec.lastFruitTypeIndex then
                    self:updateFruitExtraObjects()
                    spec.lastFruitTypeIndex = inputFruitType
                end
                self:setTestAreaRequirements(spec.lastFruitTypeIndex)
            end
            if effectsAreRunning ~= spec.effectsAreRunning then
                spec.effectsAreRunning = effectsAreRunning
                if not effectsAreRunning then
                    g_effectManager:stopEffects(spec.cutterEffects)
                end
            end
        end
    end
end
function Mower:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_mower
        if #spec.dropEffects > 0 then
            if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
                for _, dropEffect in ipairs(spec.dropEffects) do
                    streamWriteUIntN(streamId, dropEffect.fillType or FillType.UNKNOWN, FillTypeManager.SEND_NUM_BITS)
                    streamWriteBool(streamId, dropEffect.isActiveSent)
                end
            end
        else
            streamWriteBool(streamId, spec.isCutting)
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.effectDirtyFlag) ~= 0) and streamWriteBool(streamId, spec.effectsAreRunning) then
            streamWriteUIntN(streamId, spec.lastFruitGrowthState, 4)
            streamWriteUIntN(streamId, spec.lastFruitTypeIndex, FruitTypeManager.SEND_NUM_BITS)
        end
    end
end
function Mower:onUpdate(_, _, _, _)
    if self:getIsTurnedOn() and self:getLastSpeed() > 0.5 then
        local currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX = self:getTestAreaWidthByWorkAreaIndex(1)
        local reset = false
        if currentTestAreaMinX == -math.huge and currentTestAreaMaxX == math.huge then
            currentTestAreaMinX = 0
            currentTestAreaMaxX = 0
            reset = true
        end
        local currentTestAreaMinX
        if self.movingDirection > 0 then
            currentTestAreaMinX = currentTestAreaMinX * -1
            currentTestAreaMinX = currentTestAreaMaxX * -1
            if currentTestAreaMinX >= currentTestAreaMinX then
            end
        else
            currentTestAreaMinX = currentTestAreaMaxX
        end
        local t, inputGrowthState, isActive
        if self.isServer then
            t = FruitType.UNKNOWN
            inputGrowthState = 3
            if g_time - self.spec_mower.workAreaParameters.lastCutTime < 500 then
                t = spec.workAreaParameters.lastInputFruitType
                inputGrowthState = spec.workAreaParameters.lastInputGrowthState
            end
            isActive = not reset
            if isActive then
                isActive = false
                if t ~= nil then
                    isActive = t ~= FruitType.UNKNOWN
                end
            end
            if isActive then
                if not spec.effectsAreRunning then
                    spec.effectsAreRunning = true
                    self:raiseDirtyFlags(spec.effectDirtyFlag)
                end
            elseif spec.effectsAreRunning then
                g_effectManager:stopEffects(spec.cutterEffects)
                spec.effectsAreRunning = false
                self:raiseDirtyFlags(spec.effectDirtyFlag)
            end
            if t ~= spec.lastFruitTypeIndex then
                spec.lastFruitTypeIndex = t
                self:updateFruitExtraObjects()
            end
            spec.lastFruitGrowthState = inputGrowthState
        else
            t = spec.lastFruitTypeIndex
            inputGrowthState = spec.lastFruitGrowthState
            isActive = spec.effectsAreRunning
            if isActive then
                isActive = spec.lastFruitTypeIndex ~= FruitType.UNKNOWN
            end
        end
        if isActive then
            g_effectManager:setEffectTypeInfo(spec.cutterEffects, nil, t, inputGrowthState)
            g_effectManager:setMinMaxWidth(spec.cutterEffects, currentTestAreaMinX, currentTestAreaMinX, currentTestAreaMinX / testAreaMinX, currentTestAreaMinX / testAreaMaxX, reset)
            g_effectManager:startEffects(spec.cutterEffects)
            return
        end
    elseif spec.effectsAreRunning then
        g_effectManager:stopEffects(spec.cutterEffects)
        spec.effectsAreRunning = false
        self:raiseDirtyFlags(spec.effectDirtyFlag)
    end
end
function Mower:processMowerArea(workArea, _)
    local spec = self.spec_mower
    if not self.isServer and self.currentUpdateDistance > Mower.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local xs, _, zs = getWorldTranslation(workArea.start)
    local xw, _, zw = getWorldTranslation(workArea.width)
    local xh, _, zh = getWorldTranslation(workArea.height)
    if self:getLastSpeed() > 1 then
        spec.isWorking = true
        spec.stoneLastState = FSDensityMapUtil.getStoneArea(xs, zs, xw, zw, xh, zh)
    else
        spec.stoneLastState = 0
    end
    local workAreaChanged = 0
    local workAreaTotal = 0
    local limitToField = self:getIsAIActive()
    for inputFruitType, converterData in pairs(spec.fruitTypeConverters) do
        local changedArea, totalArea, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPerc, growthState, _ = FSDensityMapUtil.updateMowerArea(inputFruitType, xs, zs, xw, zw, xh, zh, limitToField)
        if changedArea > 0 then
            local multiplier = g_currentMission:getHarvestScaleMultiplier(inputFruitType, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPerc)
            local litersToDrop = g_fruitTypeManager:getFruitTypeAreaLiters(inputFruitType, changedArea, true) * multiplier * converterData.conversionFactor
            workArea.lastPickupLiters = litersToDrop
            workArea.pickedUpLiters = litersToDrop
            local dropArea = self:getDropArea(workArea)
            if dropArea == nil then
                if spec.fillUnitIndex ~= nil and self.isServer then
                    self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, litersToDrop, converterData.fillTypeIndex, ToolType.UNDEFINED)
                end
            else
                dropArea.litersToDrop = dropArea.litersToDrop + litersToDrop
                dropArea.fillType = converterData.fillTypeIndex
                dropArea.workAreaIndex = workArea.index
                if dropArea.fillType == FillType.GRASS_WINDROW then
                    local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height, true)
                    pickup, workArea.lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, FillType.DRYGRASS_WINDROW, lsx, lsy, lsz, lex, ley, lez, radius, nil, workArea.lineOffset or 0, false, nil, false)
                    dropArea.litersToDrop = dropArea.litersToDrop - pickup
                end
                local lsy = dropArea.litersToDrop
                dropArea.litersToDrop = math.min(lsy, 1000)
            end
            spec.workAreaParameters.lastInputFruitType = inputFruitType
            spec.workAreaParameters.lastInputGrowthState = growthState
            spec.workAreaParameters.lastCutTime = g_time
            spec.workAreaParameters.lastChangedArea = spec.workAreaParameters.lastChangedArea + changedArea
            spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + totalArea
            spec.workAreaParameters.lastTotalArea = spec.workAreaParameters.lastTotalArea + totalArea
            spec.workAreaParameters.lastUsedAreas = spec.workAreaParameters.lastUsedAreas + 1
            self:setTestAreaRequirements(inputFruitType)
            workAreaTotal = totalArea
        end
    end
    spec.workAreaParameters.lastUsedAreasSum = spec.workAreaParameters.lastUsedAreasSum + 1
    return workAreaChanged, workAreaTotal
end
function Mower:processDropArea(dropArea, _)
    if self.isServer or self.currentUpdateDistance <= Mower.CLIENT_DM_UPDATE_RADIUS then
        if dropArea.litersToDrop > g_densityMapHeightManager:getMinValidLiterValue(dropArea.fillType) then
            local xs, _, zs = getWorldTranslation(dropArea.start)
            local xw, _, zw = getWorldTranslation(dropArea.width)
            local xh, _, zh = getWorldTranslation(dropArea.height)
            local f = math.random()
            local sx = xs + f * (xh - xs)
            local sz = zs + f * (zh - zs)
            local sy = getTerrainHeightAtWorldPos(g_terrainNode, sx, 0, sz)
            local ex = math.random()
            local ex = xw + ex * (xh - xs)
            local ez = zw + ex * (zh - zs)
            local ey = getTerrainHeightAtWorldPos(g_terrainNode, ex, 0, ez)
            local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self, dropArea.litersToDrop, dropArea.fillType, sx, sy, sz, ex, ey, ez, 0, nil, dropArea.dropLineOffset, false, nil, false)
            dropArea.litersToDrop = dropArea.litersToDrop - dropped
            dropArea.dropLineOffset = lineOffset
            if dropped ~= 0 then
                self.spec_mower.lastDropTime = g_time
            end
        end
    end
end
function Mower:getDropArea(workArea)
    if not workArea.dropWindrow then
        return nil
    end
    local dropArea = nil
    if workArea.dropAreaIndex ~= nil then
        dropArea = self.spec_workArea.workAreas[workArea.dropAreaIndex]
        if dropArea == nil then
            printWarning("Warning: Invalid dropAreaIndex \'" .. tostring(workArea.dropAreaIndex) .. "\' in \'" .. tostring(self.configFileName) .. "\'!")
            workArea.dropAreaIndex = nil
        end
        if dropArea.type ~= WorkAreaType.AUXILIARY then
            Logging.xmlWarning(self.xmlFile, "Invalid dropAreaIndex \'%s\'. Drop area type needs to be \'AUXILIARY\'!", workArea.dropAreaIndex)
            workArea.dropAreaIndex = nil
            dropArea = nil
        end
    end
    return dropArea
end
function Mower:setDropEffectEnabled(dropEffect, isActive)
    dropEffect.isActive = isActive
    if self.isClient then
        if isActive then
            g_effectManager:setEffectTypeInfo(dropEffect.effects, dropEffect.fillType)
            g_effectManager:startEffects(dropEffect.effects)
            return
        end
        g_effectManager:stopEffects(dropEffect.effects)
    end
end
function Mower:setCutSoundEnabled(isActive)
    if self.isClient then
        local spec = self.spec_mower
        if isActive then
            local i = 1
            for i = i, #spec.samples.cut do
                if not g_soundManager:getIsSamplePlaying(spec.samples.cut[i]) then
                    g_soundManager:playSample(spec.samples.cut[i])
                end
            end
            return
        end
        local i = 1
        for i = i, #spec.samples.cut do
            if g_soundManager:getIsSamplePlaying(spec.samples.cut[i]) then
                g_soundManager:stopSample(spec.samples.cut[i])
            end
        end
    end
end
function Mower:setUseMowerWindrowDropAreas(useMowerWindrowDropAreas, noEventSend)
    local spec = self.spec_mower
    if useMowerWindrowDropAreas ~= spec.useWindrowDropAreas then
        MowerToggleWindrowDropEvent.sendEvent(self, useMowerWindrowDropAreas, noEventSend)
        spec.useWindrowDropAreas = useMowerWindrowDropAreas
        if spec.toggleWindrowDropAnimation ~= nil and self.playAnimation ~= nil then
            local speed = spec.enableWindrowDropAnimationSpeed
            if not useMowerWindrowDropAreas then
                speed = spec.disableWindrowDropAnimationSpeed
            end
            self:playAnimation(spec.toggleWindrowDropAnimation, speed, nil, true)
        end
    end
end
function Mower:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = superFunc(self, workArea, xmlFile, key)
    if workArea.type == WorkAreaType.DEFAULT then
        workArea.type = WorkAreaType.MOWER
    end
    if workArea.type == WorkAreaType.MOWER then
        workArea.dropWindrow = xmlFile:getValue(key .. ".mower#dropWindrow", true)
        workArea.dropAreaIndex = xmlFile:getValue(key .. ".mower#dropAreaIndex", 1)
        workArea.lastPickupLiters = 0
        workArea.pickedUpLiters = 0
    end
    if workArea.type == WorkAreaType.AUXILIARY then
        workArea.litersToDrop = 0
        if self.spec_mower.dropAreas == nil then
            self.spec_mower.dropAreas = {}
        end
        table.insert(self.spec_mower.dropAreas, workArea)
    end
    return retValue
end
function Mower:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_mower
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection and (spec.toggleWindrowDropEnableText ~= nil and spec.toggleWindrowDropDisableText ~= nil) then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Mower.actionEventToggleDrop, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
            Mower.updateActionEventToggleDrop(self)
        end
    end
end
function Mower:doCheckSpeedLimit(superFunc)
    return not superFunc(self) and self:getIsTurnedOn() and (self.getIsLowered == nil or self:getIsLowered())
end
function Mower:getCanBeSelected(superFunc)
    return true
end
function Mower:getDirtMultiplier(superFunc)
    local multiplier = superFunc(self)
    if self.spec_mower.isWorking then
        multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    end
    return multiplier
end
function Mower:getWearMultiplier(superFunc)
    local spec = self.spec_mower
    local multiplier = superFunc(self)
    if spec.isWorking then
        multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * (spec.stoneLastState ~= 0 and spec.stoneWearMultiplierData ~= nil and (spec.stoneWearMultiplierData[spec.stoneLastState] or 1) or 1)
    end
    return multiplier
end
function Mower:getFruitExtraObjectTypeData(_)
    return self.spec_mower.lastFruitTypeIndex, nil
end
function Mower:onTurnedOn()
    if self.isClient then
        g_animationManager:startAnimations(self.spec_mower.animationNodes)
    end
end
function Mower:onTurnedOff()
    local spec = self.spec_mower
    if self.isClient then
        for _, dropEffect in pairs(spec.dropEffects) do
            self:setDropEffectEnabled(dropEffect, false)
        end
        g_animationManager:stopAnimations(spec.animationNodes)
    end
    g_effectManager:stopEffects(spec.cutterEffects)
    spec.effectsAreRunning = false
end
function Mower:onStartWorkAreaProcessing(_)
    local spec = self.spec_mower
    if self.isServer then
        for _, dropEffect in pairs(spec.dropEffects) do
            if dropEffect.isActive ~= dropEffect.isActiveSent then
                dropEffect.isActiveSent = dropEffect.isActive
                self:setDropEffectEnabled(dropEffect, dropEffect.isActiveSent)
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
            dropEffect.isActive = false
        end
    end
    local workAreas = self:getTypedWorkAreas(WorkAreaType.MOWER)
    for _ = 1, #workAreas do
        workAreas[_].pickedUpLiters = 0
    end
    spec.workAreaParameters.lastChangedArea = 0
    spec.workAreaParameters.lastStatsArea = 0
    spec.workAreaParameters.lastTotalArea = 0
    spec.isWorking = false
end
function Mower:onEndWorkAreaProcessing(dt, _)
    local spec = self.spec_mower
    for _, dropArea in ipairs(spec.dropAreas) do
        self:processDropArea(dropArea, dt)
    end
    local i = 1
    local lastStatsArea = #spec.workAreas
    local ha = 1
    for i = i, lastStatsArea, ha do
        local _ = spec.workAreas[i]
        local j = 1
        local dropArea = #_.dropEffects
        for j = j, dropArea do
            local dropEffect = _.dropEffects[j]
            local dropArea = self:getDropArea(_)
            if dropArea ~= nil and dropEffect.dropAreaIndex == dropArea.index then
                if _.pickedUpLiters > 0 then
                    if dropEffect.fillType ~= dropArea.fillType then
                        dropEffect.fillType = dropArea.fillType
                        g_effectManager:setEffectTypeInfo(dropEffect.effects, dropEffect.fillType)
                    end
                    dropEffect.activeTime = dropEffect.activeTimeDuration
                    dropEffect.isActive = true
                else
                    dropEffect.activeTime = math.max(dropEffect.activeTime - dt, 0)
                    if dropEffect.activeTime > 0 then
                        dropEffect.isActive = true
                    end
                end
            end
        end
    end
    if self.isServer then
        local lastStatsArea = spec.workAreaParameters.lastStatsArea
        if lastStatsArea > 0 then
            local ha = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
            g_farmManager:updateFarmStats(self:getLastTouchedFarmlandFarmId(), "threshedHectares", ha)
            self:updateLastWorkedArea(lastStatsArea)
        end
        local ha = g_time - spec.lastDropTime < 500
        if spec.isCutting ~= ha then
            spec.isCutting = ha
            self:raiseDirtyFlags(spec.dirtyFlag)
            self:setCutSoundEnabled(spec.isCutting)
        end
    end
    spec.workAreaParameters.lastUsedAreasTime = spec.workAreaParameters.lastUsedAreasTime + dt
    if spec.workAreaParameters.lastUsedAreasTime > 500 then
        spec.workAreaParameters.lastUsedAreasPct = spec.workAreaParameters.lastUsedAreas / math.max(spec.workAreaParameters.lastUsedAreasSum, 0.01)
        spec.workAreaParameters.lastUsedAreas = 0
        spec.workAreaParameters.lastUsedAreasSum = 0
        spec.workAreaParameters.lastUsedAreasTime = 0
    end
end
function Mower.onAIFieldCourseSettingsInitialized(_, fieldCourseSettings)
    fieldCourseSettings.headlandsFirst = true
    fieldCourseSettings.workInitialSegment = true
    fieldCourseSettings.cornerCutOutSupported = true
end
function Mower:getMowerLoadPercentage()
    return self.spec_mower == nil and 0 or self.spec_mower.workAreaParameters.lastUsedAreasPct
end
g_soundManager:registerModifierType("MOWER_LOAD", Mower.getMowerLoadPercentage)
function Mower.getDefaultSpeedLimit()
    return 20
end
function Mower:actionEventToggleDrop(_, _, _, _)
    self:setUseMowerWindrowDropAreas(not self.spec_mower.useWindrowDropAreas)
end
function Mower:updateActionEventToggleDrop()
    local spec = self.spec_mower
    local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]
    if actionEvent ~= nil then
        local text = string.format(spec.toggleWindrowDropDisableText, self.typeDesc)
        if not spec.useWindrowDropAreas then
            text = string.format(spec.toggleWindrowDropEnableText, self.typeDesc)
        end
        g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
    end
end