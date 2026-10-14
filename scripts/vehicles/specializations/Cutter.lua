Cutter = {}
Cutter.AUTO_TILT_COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA + CollisionFlag.STATIC_OBJECT
Cutter.CUTTER_TILT_XML_KEY = "vehicle.cutter.automaticTilt"
Cutter.CLIENT_DM_UPDATE_RADIUS = 50
function Cutter.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("cutter", false, true, true)
    g_workAreaTypeManager:addWorkAreaType("haulmDrop", false, false, false)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Cutter")
    schema:register(XMLValueType.STRING, "vehicle.cutter#fruitTypes", "List with supported fruit types")
    schema:register(XMLValueType.STRING, "vehicle.cutter#fruitTypeCategories", "List with supported fruit types categories")
    schema:register(XMLValueType.STRING, "vehicle.cutter#fruitTypeConverter", "Name of fruit type converter")
    schema:register(XMLValueType.STRING, "vehicle.cutter#fillTypeConverter", "Name of fill type converter (defines the supported fill types for pickup headers)")
    schema:register(XMLValueType.BOOL, "vehicle.cutter#supportsPickupAI", "AI works for pickup from the ground as well", false)
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.cutter.animationNodes")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.cutter.effect")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.cutter.fillEffect")
    schema:register(XMLValueType.NODE_INDEX, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#node", "Automatic tilt node")
    schema:register(XMLValueType.ANGLE, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#minAngle", "Min. angle", -5)
    schema:register(XMLValueType.ANGLE, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#maxAngle", "Max. angle", 5)
    schema:register(XMLValueType.ANGLE, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#maxSpeed", "Max. angle change per second", 1)
    schema:register(XMLValueType.NODE_INDEX, Cutter.CUTTER_TILT_XML_KEY .. "#raycastNode1", "Raycast node 1")
    schema:register(XMLValueType.NODE_INDEX, Cutter.CUTTER_TILT_XML_KEY .. "#raycastNode2", "Raycast node 2")
    schema:register(XMLValueType.BOOL, "vehicle.cutter#allowsForageGrowthState", "Allows forage growth state", false)
    schema:register(XMLValueType.BOOL, "vehicle.cutter#allowCuttingWhileRaised", "Allow cutting while raised", false)
    schema:register(XMLValueType.INT, "vehicle.cutter#movingDirection", "Moving direction", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.cutter#strawRatio", "Straw ratio", 1)
    schema:register(XMLValueType.TIME, "vehicle.cutter.haulmDrop#delay", "Delay between pickup and haulm drop", 0)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.cutter.spikedDrums.spikedDrum(?)#node", "Spiked drum node (Needs to rotate on X axis)")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.cutter.spikedDrums.spikedDrum(?)#spline", "Reference spline")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.cutter.spikedDrums.spikedDrum(?).spike(?)#node", "Spike that is translated on Y axis depending on spline")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.cutter.sounds", "cut")
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".chopperArea#index", "Chopper area index")
    schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".chopperArea#index", "Chopper area index")
    schema:register(XMLValueType.BOOL, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#moveOnlyIfCut", "Move only if cutters cuts something", false)
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#rotateIfTurnedOn", "Rotate only if turned on", false)
    schema:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#useFruitCutHeight", "The lower distance to ground is used from the cutHeight defined in the current fruit type", true)
    schema:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#useFruitCutHeight", "The lower distance to ground is used from the cutHeight defined in the current fruit type", true)
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).cutter#cutHeight", "Last used cut height")
end
function Cutter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TestAreas, specializations) and SpecializationUtil.hasSpecialization(FruitExtraObjects, specializations)
end
function Cutter.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "readCutterFromStream", Cutter.readCutterFromStream)
    SpecializationUtil.registerFunction(vehicleType, "writeCutterToStream", Cutter.writeCutterToStream)
    SpecializationUtil.registerFunction(vehicleType, "getCombine", Cutter.getCombine)
    SpecializationUtil.registerFunction(vehicleType, "getAllowCutterAIFruitRequirements", Cutter.getAllowCutterAIFruitRequirements)
    SpecializationUtil.registerFunction(vehicleType, "processCutterArea", Cutter.processCutterArea)
    SpecializationUtil.registerFunction(vehicleType, "processPickupCutterArea", Cutter.processPickupCutterArea)
    SpecializationUtil.registerFunction(vehicleType, "processHaulmDropArea", Cutter.processHaulmDropArea)
    SpecializationUtil.registerFunction(vehicleType, "getCutterLoad", Cutter.getCutterLoad)
    SpecializationUtil.registerFunction(vehicleType, "getCutterStoneMultiplier", Cutter.getCutterStoneMultiplier)
    SpecializationUtil.registerFunction(vehicleType, "loadCutterTiltFromXML", Cutter.loadCutterTiltFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getCutterTiltIsAvailable", Cutter.getCutterTiltIsAvailable)
    SpecializationUtil.registerFunction(vehicleType, "getCutterTiltIsActive", Cutter.getCutterTiltIsActive)
    SpecializationUtil.registerFunction(vehicleType, "getCutterTiltDelta", Cutter.getCutterTiltDelta)
    SpecializationUtil.registerFunction(vehicleType, "tiltRaycastDetectionCallbackLeft", Cutter.tiltRaycastDetectionCallbackLeft)
    SpecializationUtil.registerFunction(vehicleType, "tiltRaycastDetectionCallbackRight", Cutter.tiltRaycastDetectionCallbackRight)
    SpecializationUtil.registerFunction(vehicleType, "setCutterCutHeight", Cutter.setCutterCutHeight)
end
function Cutter.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Cutter.loadSpeedRotatingPartFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Cutter.getIsSpeedRotatingPartActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadRandomlyMovingPartFromXML", Cutter.loadRandomlyMovingPartFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsRandomlyMovingPartActive", Cutter.getIsRandomlyMovingPartActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Cutter.getIsWorkAreaActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Cutter.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Cutter.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Cutter.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cutter.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "isAttachAllowed", Cutter.isAttachAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Cutter.getConsumingLoad)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsGroundReferenceNodeThreshold", Cutter.getIsGroundReferenceNodeThreshold)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDefaultAllowComponentMassReduction", Cutter.getDefaultAllowComponentMassReduction)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", Cutter.loadInputAttacherJoint)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFruitExtraObjectTypeData", Cutter.getFruitExtraObjectTypeData)
end
function Cutter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", Cutter)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", Cutter)
end
function Cutter:onLoad(savegame)
    local spec = self.spec_cutter
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.cutter.animationNodes.animationNode", "cutter")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnScrollers", "vehicle.cutter.animationNodes.animationNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.turnedOnScrollers", "vehicle.cutter.animationNodes.animationNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.reelspikes", "vehicle.cutter.rotationNodes.rotationNode or vehicle.turnOnVehicle.turnedOnAnimation")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.threshingParticleSystems.threshingParticleSystem", "vehicle.cutter.fillEffect.effectNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.threshingParticleSystems.emitterShape", "vehicle.cutter.fillEffect.effectNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter#convertedFillTypeCategories", "vehicle.cutter#fruitTypeConverter")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter#startAnimationName", "vehicle.turnOnVehicle.turnOnAnimation#name")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.testAreas", "vehicle.workAreas.workArea.testAreas")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter#useWindrowed", "Windrows are now picked up if a fillTypeConverter is defined and the work area uses \'processPickupCutterArea\'")
    local fruitTypeIndices = nil
    local fruitTypeNames = self.xmlFile:getValue("vehicle.cutter#fruitTypes")
    local fruitTypeCategories = self.xmlFile:getValue("vehicle.cutter#fruitTypeCategories")
    if fruitTypeCategories == nil or fruitTypeNames ~= nil then
        if fruitTypeCategories == nil and fruitTypeNames ~= nil then
            fruitTypeIndices = g_fruitTypeManager:getFruitTypeIndicesByNames(fruitTypeNames, "Warning: Cutter has invalid fruitType \'%s\' in \'" .. self.configFileName .. "\'")
        end
    else
        fruitTypeIndices = g_fruitTypeManager:getFruitTypeIndicesByCategoryNames(fruitTypeCategories, "Warning: Cutter has invalid fruitTypeCategory \'%s\' in \'" .. self.configFileName .. "\'")
    end
    spec.currentCutHeight = 0
    spec.outputFillTypes = {}
    spec.fruitTypeConverters = {}
    local category = self.xmlFile:getValue("vehicle.cutter#fruitTypeConverter")
    if category ~= nil then
        local data = g_fruitTypeManager:getConverterDataByName(category)
        if data == nil then
            Logging.xmlWarning(self.xmlFile, "Cutter has invalid fruitTypeConverter \'%s\'", category)
        else
            for input, converter in pairs(data) do
                spec.fruitTypeConverters[input] = converter
            end
        end
    end
    if fruitTypeIndices ~= nil then
        spec.fruitTypeIndices = {}
        for _, input in pairs(fruitTypeIndices) do
            table.insert(spec.fruitTypeIndices, input)
            if #spec.fruitTypeIndices == 1 then
                self:setCutterCutHeight((g_fruitTypeManager:getCutHeightByFruitTypeIndex(input, spec.allowsForageGrowthState)))
            end
        end
        for _, input in ipairs(spec.fruitTypeIndices) do
            if spec.fruitTypeConverters[input] == nil then
                local converter = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(input)
                if converter ~= nil then
                    table.insert(spec.outputFillTypes, converter)
                end
            else
                table.insert(spec.outputFillTypes, spec.fruitTypeConverters[input].fillTypeIndex)
            end
        end
    end
    spec.fillTypeConverter = nil
    local data = self.xmlFile:getValue("vehicle.cutter#fillTypeConverter")
    if data ~= nil then
        local fillTypeConverter = g_fillTypeManager:getConverterDataByName(data)
        if fillTypeConverter == nil then
            Logging.xmlWarning(self.xmlFile, "Cutter has invalid fillTypeConverter \'%s\'", data)
        else
            spec.fillTypeConverter = fillTypeConverter
            for converter, outputData in pairs(fillTypeConverter) do
                table.insert(spec.outputFillTypes, outputData.targetFillTypeIndex)
            end
        end
    end
    if #spec.outputFillTypes == 0 then
        Logging.xmlWarning(self.xmlFile, "Cutter has no valid fruit/fill type definition (requires either fruitTypes/fruitTypeCategories or fillTypeConverter attribute)")
    end
    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.cutter.animationNodes", self.components, self, self.i3dMappings)
        spec.spikedDrums = {}
        self.xmlFile:iterate("vehicle.cutter.spikedDrums.spikedDrum", function(_, key)
            -- upvalues: (copy) self, (copy) spec
            local entry = {
                ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
            }
            if entry.node == nil then
                Logging.xmlWarning(self.xmlFile, "No drum node defined for spiked drum \'%s\'", key)
                return
            else
                entry.spline = self.xmlFile:getValue(key .. "#spline", nil, self.components, self.i3dMappings)
                if entry.spline == nil then
                    Logging.xmlWarning(self.xmlFile, "No spline defined for spiked drum \'%s\'", key)
                    return
                else
                    setVisibility(entry.spline, false)
                    entry.spikes = {}
                    self.xmlFile:iterate(key .. ".spike", function(_, spikeKey)
                        -- upvalues: (ref) self, (copy) entry
                        local spike = {
                            ["node"] = self.xmlFile:getValue(spikeKey .. "#node", nil, self.components, self.i3dMappings)
                        }
                        if spike.node ~= nil then
                            local parent = createTransformGroup(getName(spike.node) .. "Parent")
                            link(getParent(spike.node), parent, getChildIndex(spike.node))
                            setTranslation(parent, getTranslation(spike.node))
                            setRotation(parent, getRotation(spike.node))
                            link(parent, spike.node)
                            setTranslation(spike.node, 0, 0, 0)
                            setRotation(spike.node, 0, 0, 0)
                            local _, y, z = localToLocal(spike.node, entry.node, 0, 0, 0)
                            local initalTime = -MathUtil.getYRotationFromDirection(y, z) / 6.283185307179586
                            if initalTime < 0 then
                            end
                            spike.initalTime = initalTime
                            table.insert(entry.spikes, spike)
                        end
                    end)
                    local splineTimes = {}
                    local t = 0
                    for t = t, 1, 0.01 do
                        local x, y, z = getSplinePosition(entry.spline, t)
                        local angle, alpha, z = worldToLocal(entry.node, x, y, z)
                        local alpha = -MathUtil.getYRotationFromDirection(alpha, z) / 6.283185307179586
                        if alpha < 0 then
                        end
                        table.insert(splineTimes, {
                            ["alpha"] = alpha,
                            ["time"] = t
                        })
                    end
                    local t = {
                        ["alpha"] = splineTimes[1].alpha - 1e-6,
                        ["time"] = 1
                    }
                    table.insert(splineTimes, t)
                    table.sort(splineTimes, function(a, b)
                        return a.alpha < b.alpha
                    end)
                    entry.splineCurve = AnimCurve.new(linearInterpolator1)
                    local t = 1
                    for t = t, #splineTimes do
                        entry.splineCurve:addKeyframe({
                            splineTimes[t].time,
                            ["time"] = splineTimes[t].alpha
                        })
                    end
                    local t = 1
                    for t = t, #spec.animationNodes do
                        local x = spec.animationNodes[t]
                        if x.rootNode == entry.node then
                            entry.animationNode = x
                        end
                    end
                    if entry.animationNode == nil then
                        Logging.xmlWarning(self.xmlFile, "Could not find animation node for spikedDrum \'%s\'", getName(entry.node))
                    else
                        table.insert(spec.spikedDrums, entry)
                    end
                end
            end
        end)
        spec.cutterEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.cutter.effect", self.components, self, self.i3dMappings)
        spec.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.cutter.fillEffect", self.components, self, self.i3dMappings)
        spec.samples = {}
        spec.samples.cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cutter.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.lastAutomaticTiltRaycastPosition = { 0, 0, 0 }
    spec.automaticTilt = {}
    spec.automaticTilt.isAvailable = false
    spec.automaticTilt.hasNodes = false
    if self:loadCutterTiltFromXML(self.xmlFile, Cutter.CUTTER_TILT_XML_KEY, spec.automaticTilt) then
        spec.automaticTilt.currentDelta = 0
        spec.automaticTilt.lastHit1 = { 0, 0, 0 }
        spec.automaticTilt.lastHit2 = { 0, 0, 0 }
        spec.automaticTilt.raycastHit = true
        spec.automaticTilt.isAvailable = true
        spec.automaticTilt.hasNodes = #spec.automaticTilt.nodes > 0
    end
    if not Platform.gameplay.allowAutomaticHeaderTilt and spec.automaticTilt.hasNodes then
        Logging.xmlWarning(self.xmlFile, "Automatic header tilt is not allowed on this platform!")
        spec.automaticTilt.hasNodes = false
    end
    spec.allowsForageGrowthState = self.xmlFile:getValue("vehicle.cutter#allowsForageGrowthState", false)
    spec.allowCuttingWhileRaised = self.xmlFile:getValue("vehicle.cutter#allowCuttingWhileRaised", false)
    spec.movingDirection = math.sign((self.xmlFile:getValue("vehicle.cutter#movingDirection", 1)))
    spec.strawRatio = self.xmlFile:getValue("vehicle.cutter#strawRatio", 1)
    spec.delay = self.xmlFile:getValue("vehicle.cutter.haulmDrop#delay", 0)
    if spec.delay ~= 0 then
        spec.valueDelay = ValueDelay.new(spec.delay)
    end
    spec.useWindrow = false
    spec.currentInputFillType = FillType.UNKNOWN
    spec.currentInputFillTypeSent = FillType.UNKNOWN
    spec.currentInputFruitType = FruitType.UNKNOWN
    spec.currentInputFruitTypeAI = FruitType.UNKNOWN
    spec.lastValidInputFruitType = FruitType.UNKNOWN
    spec.currentInputFruitTypeSent = FruitType.UNKNOWN
    spec.currentOutputFillType = FillType.UNKNOWN
    spec.currentConversionFactor = 1
    spec.currentGrowthStateTime = 0
    spec.currentGrowthStateTimer = 0
    spec.currentGrowthState = 0
    spec.lastAreaBiggerZero = false
    spec.lastAreaBiggerZeroSent = false
    spec.lastAreaBiggerZeroTime = -1
    spec.workAreaParameters = {}
    spec.workAreaParameters.lastLiters = 0
    spec.workAreaParameters.lastArea = 0
    spec.workAreaParameters.lastMultiplierArea = 0
    spec.workAreaParameters.fruitTypeIndicesToUse = {}
    spec.workAreaParameters.lastFruitTypeToUse = {}
    spec.workAreaParameters.lastOutputFillType = nil
    spec.lastOutputFillTypes = {}
    spec.lastPrioritizedOutputType = FillType.UNKNOWN
    spec.lastOutputTime = 0
    spec.cutterLoad = 0
    spec.isWorking = false
    spec.stoneLastState = 0
    spec.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("CUTTER")
    spec.workAreaParameters.countArea = true
    if self.xmlFile:getValue("vehicle.cutter#supportsPickupAI", false) and self.addAIDensityHeightTypeRequirement ~= nil then
        for input, converter in pairs(spec.fillTypeConverter) do
            self:addAIDensityHeightTypeRequirement(input)
        end
    end
    if savegame ~= nil and not savegame.resetVehicles then
        spec.currentCutHeight = savegame.xmlFile:getValue(savegame.key .. ".cutter#cutHeight", spec.currentCutHeight)
    end
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.effectDirtyFlag = self:getNextDirtyFlag()
end
function Cutter:onPostLoad(_)
    if self.addCutterToCombine ~= nil then
        self:addCutterToCombine(self)
    end
    self:setCutterCutHeight(self.spec_cutter.currentCutHeight)
end
function Cutter:onDelete()
    local spec = self.spec_cutter
    g_effectManager:deleteEffects(spec.cutterEffects)
    g_effectManager:deleteEffects(spec.fillEffects)
    g_animationManager:deleteAnimations(spec.animationNodes)
    g_soundManager:deleteSamples(spec.samples)
end
function Cutter:onReadStream(streamId, connection)
    self:readCutterFromStream(streamId, connection)
    local spec = self.spec_cutter
    spec.lastAreaBiggerZero = streamReadBool(streamId)
    if spec.lastAreaBiggerZero then
        spec.lastAreaBiggerZeroTime = g_currentMission.time
    end
    self:setTestAreaRequirements(spec.currentInputFruitType, nil, spec.allowsForageGrowthState)
end
function Cutter:onWriteStream(streamId, connection)
    self:writeCutterToStream(streamId, connection)
    streamWriteBool(streamId, self.spec_cutter.lastAreaBiggerZeroSent)
end
function Cutter:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        local spec = self.spec_cutter
        if streamReadBool(streamId) then
            self:readCutterFromStream(streamId, connection)
        end
        spec.lastAreaBiggerZero = streamReadBool(streamId)
        if spec.lastAreaBiggerZero then
            spec.lastAreaBiggerZeroTime = g_currentMission.time
        end
        self:setTestAreaRequirements(spec.currentInputFruitType, nil, spec.allowsForageGrowthState)
    end
end
function Cutter:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_cutter
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.effectDirtyFlag) ~= 0) then
            self:writeCutterToStream(streamId, connection)
        end
        streamWriteBool(streamId, spec.lastAreaBiggerZeroSent)
    end
end
function Cutter:readCutterFromStream(streamId, _)
    local spec = self.spec_cutter
    spec.currentGrowthState = streamReadUIntN(streamId, 4)
    spec.currentInputFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
    if streamReadBool(streamId) then
        spec.lastValidInputFruitType = spec.currentInputFruitType
    else
        spec.currentInputFruitType = FruitType.UNKNOWN
    end
    spec.currentOutputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)
    if spec.fruitTypeConverters[spec.currentInputFruitType] ~= nil then
        spec.currentOutputFillType = spec.fruitTypeConverters[spec.currentInputFruitType].fillTypeIndex
        spec.currentConversionFactor = spec.fruitTypeConverters[spec.currentInputFruitType].conversionFactor
    end
    spec.useWindrow = streamReadBool(streamId)
    if spec.useWindrow then
        spec.currentInputFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
    else
        spec.currentInputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)
    end
end
function Cutter:writeCutterToStream(streamId, _)
    local spec = self.spec_cutter
    streamWriteUIntN(streamId, spec.currentGrowthState, 4)
    streamWriteUIntN(streamId, spec.currentInputFruitType, FruitTypeManager.SEND_NUM_BITS)
    streamWriteBool(streamId, spec.currentInputFruitType == spec.lastValidInputFruitType)
    if streamWriteBool(streamId, spec.useWindrow) then
        streamWriteUIntN(streamId, spec.currentInputFillType, FillTypeManager.SEND_NUM_BITS)
    end
end
function Cutter:saveToXMLFile(xmlFile, key, _)
    xmlFile:setValue(key .. "#cutHeight", self.spec_cutter.currentCutHeight)
end
function Cutter:onUpdate(dt, _, _, _)
    local spec = self.spec_cutter
    if spec.automaticTilt.hasNodes then
        local currentDelta, isActive, doReset = self:getCutterTiltDelta()
        local currentDelta = -currentDelta
        if self.isActive then
            local i = 1
            for i = i, #spec.automaticTilt.nodes do
                local automaticTiltNode = spec.automaticTilt.nodes[i]
                local _, _, curZ = getRotation(automaticTiltNode.node)
                if not isActive and doReset then
                    currentDelta = -curZ
                end
                if math.abs(currentDelta) > 0.00001 then
                    local splineTime = math.abs(currentDelta) / 0.01745
                    local newRotZ = math.pow(splineTime, 2)
                    local splineTime = curZ + math.min(newRotZ, 1) * math.sign(currentDelta) * automaticTiltNode.maxSpeed * dt
                    local newRotZ = math.clamp(splineTime, automaticTiltNode.minAngle, automaticTiltNode.maxAngle)
                    setRotation(automaticTiltNode.node, 0, 0, newRotZ)
                    if self.setMovingToolDirty ~= nil then
                        self:setMovingToolDirty(automaticTiltNode.node)
                    end
                end
            end
        end
    end
    if self.isClient then
        local doReset = 1
        for doReset = doReset, #spec.spikedDrums do
            local spikedDrum = spec.spikedDrums[doReset]
            if spikedDrum.animationNode.state ~= RotationAnimation.STATE_OFF then
                local rot, i, automaticTiltNode = getRotation(spikedDrum.node)
                if rot < 0 then
                end
                local rotSpeed = 1
                for rotSpeed = rotSpeed, rot / 6.283185307179586 do
                    local newRotZ = spikedDrum.spikes[rotSpeed]
                    local splineTime = spikedDrum.splineCurve:get((_ + newRotZ.initalTime) % 1)
                    local x, y, z = getSplinePosition(spikedDrum.spline, splineTime)
                    local _, spikeY, _ = worldToLocal(getParent(newRotZ.node), x, y, z)
                    setTranslation(newRotZ.node, 0, spikeY, 0)
                end
            end
        end
    end
end
function Cutter:onUpdateTick(dt, _, _, _)
    local spec = self.spec_cutter
    local isEffectActive = self:getIsTurnedOn() and (self.movingDirection == spec.movingDirection and (self:getLastSpeed() > 0.5 and (spec.allowCuttingWhileRaised or self:getIsLowered(true))))
    if isEffectActive then
        isEffectActive = spec.workAreaParameters.combineVehicle ~= nil
    end
    if isEffectActive then
        local currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX, isValid = self:getTestAreaWidthByWorkAreaIndex(1)
        local testAreaCharge = self:getTestAreaChargeByWorkAreaIndex(1)
        if not spec.useWindrow then
            spec.cutterLoad = spec.cutterLoad * 0.95 + testAreaCharge * 0.05
        end
        local reset = false
        if currentTestAreaMinX == -math.huge and currentTestAreaMaxX == math.huge then
            currentTestAreaMinX = 0
            currentTestAreaMaxX = 0
            reset = true
        elseif not isValid and spec.lastAreaBiggerZeroTime + 300 < g_currentMission.time then
            currentTestAreaMinX = 0
            currentTestAreaMaxX = 0
            reset = true
        end
        local currentTestAreaMinX
        if spec.movingDirection > 0 then
            currentTestAreaMinX = currentTestAreaMinX * -1
            currentTestAreaMinX = currentTestAreaMaxX * -1
            if currentTestAreaMinX >= currentTestAreaMinX then
            end
        else
            currentTestAreaMinX = currentTestAreaMaxX
        end
        local t = 0
        if testAreaMinX ~= 0 then
            t = currentTestAreaMinX / testAreaMinX
        end
        local testAreaMaxAlpha = 0
        if testAreaMaxX ~= 0 then
            testAreaMaxAlpha = currentTestAreaMinX / testAreaMaxX
        end
        local inputFruitType = spec.currentInputFruitType
        if inputFruitType ~= spec.lastValidInputFruitType then
            inputFruitType = nil
        end
        if inputFruitType ~= nil then
            self:updateFruitExtraObjects()
        end
        if spec.useWindrow then
            if spec.lastAreaBiggerZeroTime + 300 > g_currentMission.time then
                spec.cutterLoad = spec.cutterLoad * 0.95 + 0.05
            else
                spec.cutterLoad = spec.cutterLoad * 0.9
            end
        end
        if self.isClient then
            local cutSoundActive = false
            if spec.currentInputFillType == nil or (spec.currentInputFillType == FillType.UNKNOWN or not isCollecting) then
                g_effectManager:stopEffects(spec.fillEffects)
            else
                g_effectManager:setEffectTypeInfo(spec.fillEffects, fillType)
                g_effectManager:setMinMaxWidth(spec.fillEffects, currentTestAreaMinX, currentTestAreaMinX, t, testAreaMaxAlpha, reset)
                g_effectManager:startEffects(spec.fillEffects)
                cutSoundActive = true
            end
            if inputFruitType == nil or (inputFruitType == FruitType.UNKNOWN or reset) then
                g_effectManager:stopEffects(spec.cutterEffects)
            else
                g_effectManager:setEffectTypeInfo(spec.cutterEffects, fillType, inputFruitType, spec.currentGrowthState)
                g_effectManager:setMinMaxWidth(spec.cutterEffects, currentTestAreaMinX, currentTestAreaMinX, t, testAreaMaxAlpha, reset)
                g_effectManager:startEffects(spec.cutterEffects)
                cutSoundActive = true
            end
            if cutSoundActive then
                if not g_soundManager:getIsSamplePlaying(spec.samples.cut) then
                    g_soundManager:playSample(spec.samples.cut)
                end
            elseif g_soundManager:getIsSamplePlaying(spec.samples.cut) then
                g_soundManager:stopSample(spec.samples.cut)
            end
        end
    else
        if self.isClient then
            g_effectManager:stopEffects(spec.cutterEffects)
            g_effectManager:stopEffects(spec.fillEffects)
            g_soundManager:stopSample(spec.samples.cut)
        end
        spec.cutterLoad = spec.cutterLoad * 0.9
    end
    spec.lastOutputTime = spec.lastOutputTime + dt
    if spec.lastOutputTime > 500 then
        spec.lastPrioritizedOutputType = FillType.UNKNOWN
        local currentTestAreaMinX = 0
        for isValid, testAreaCharge in pairs(spec.lastOutputFillTypes) do
            if currentTestAreaMinX < spec.lastOutputFillTypes[isValid] then
                spec.lastPrioritizedOutputType = isValid
                currentTestAreaMinX = spec.lastOutputFillTypes[isValid]
            end
            spec.lastOutputFillTypes[isValid] = 0
        end
        spec.lastOutputTime = 0
    end
    local currentTestAreaMinX = spec.automaticTilt
    local currentTestAreaMaxX, testAreaMinX = self:getCutterTiltIsActive(currentTestAreaMinX)
    if currentTestAreaMaxX and (currentTestAreaMinX ~= nil and (currentTestAreaMinX.raycastNode1 ~= nil and currentTestAreaMinX.raycastNode2 ~= nil)) then
        currentTestAreaMinX.currentDelta = 0
        local reset, t, testAreaMaxAlpha = localToWorld(currentTestAreaMinX.raycastNode1, 0, -1, 0)
        currentTestAreaMinX.lastHit1[1] = reset
        currentTestAreaMinX.lastHit1[2] = t
        currentTestAreaMinX.lastHit1[3] = testAreaMaxAlpha
        local reset, t, testAreaMaxAlpha = localToWorld(currentTestAreaMinX.raycastNode2, 0, -1, 0)
        currentTestAreaMinX.lastHit2[1] = reset
        currentTestAreaMinX.lastHit2[2] = t
        currentTestAreaMinX.lastHit2[3] = testAreaMaxAlpha
        local testAreaMaxX, isValid, testAreaCharge = localToWorld(currentTestAreaMinX.raycastNode1, 0, 1, 0)
        local reset, t, testAreaMaxAlpha = localDirectionToWorld(currentTestAreaMinX.raycastNode1, 0, -1, 0)
        raycastAllAsync(testAreaMaxX, isValid, testAreaCharge, reset, t, testAreaMaxAlpha, 2, "tiltRaycastDetectionCallbackLeft", self, Cutter.AUTO_TILT_COLLISION_MASK)
        local inputFruitType, isCollecting, fillType = localToWorld(currentTestAreaMinX.raycastNode2, 0, 1, 0)
        local inputFruitType, isCollecting, fillType = localDirectionToWorld(currentTestAreaMinX.raycastNode2, 0, -1, 0)
        raycastAllAsync(inputFruitType, isCollecting, fillType, inputFruitType, isCollecting, fillType, 2, "tiltRaycastDetectionCallbackRight", self, Cutter.AUTO_TILT_COLLISION_MASK)
    end
end
function Cutter:getCombine(fruitTypeIndex, outputFillTypeIndex)
    if self.verifyCombine ~= nil then
        return self:verifyCombine(fruitTypeIndex or self.spec_cutter.currentInputFruitType, outputFillTypeIndex or self.spec_cutter.currentOutputFillType)
    end
    if self.getAttacherVehicle ~= nil then
        local attacherVehicle = self:getAttacherVehicle()
        if attacherVehicle ~= nil and attacherVehicle.verifyCombine ~= nil then
            return attacherVehicle:verifyCombine(fruitTypeIndex or spec.currentInputFruitType, outputFillTypeIndex or spec.currentOutputFillType)
        end
    end
    return nil
end
function Cutter:getAllowCutterAIFruitRequirements()
    return true
end
function Cutter:processCutterArea(workArea, dt)
    local spec = self.spec_cutter
    if not self.isServer and self.currentUpdateDistance > Cutter.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    if spec.workAreaParameters.combineVehicle == nil then
        return 0, 0
    end
    local xs, _, zs = getWorldTranslation(workArea.start)
    local xw, _, zw = getWorldTranslation(workArea.width)
    local xh, _, zh = getWorldTranslation(workArea.height)
    local lastArea = 0
    local lastMultiplierArea = 0
    local lastTotalArea = 0
    for _, fruitTypeIndex in ipairs(spec.workAreaParameters.fruitTypeIndicesToUse) do
        local excludedSprayType = g_currentMission.fieldGroundSystem:getChopperTypeValue(g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex).chopperType)
        local area, totalArea, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPerc, growthState, _, terrainDetailPixelsSum = FSDensityMapUtil.cutFruitArea(fruitTypeIndex, xs, zs, xw, zw, xh, zh, true, spec.allowsForageGrowthState, excludedSprayType)
        if area > 0 then
            if self.isServer then
                if growthState == spec.currentGrowthState then
                    spec.currentGrowthStateTimer = 0
                    spec.currentGrowthStateTime = g_time
                else
                    spec.currentGrowthStateTimer = spec.currentGrowthStateTimer + dt
                    if spec.currentGrowthStateTimer > 500 or spec.currentGrowthStateTime + 1000 < g_time then
                        spec.currentGrowthState = growthState
                        spec.currentGrowthStateTimer = 0
                    end
                end
                if fruitTypeIndex ~= spec.currentInputFruitType then
                    spec.currentInputFruitType = fruitTypeIndex
                    spec.currentGrowthState = growthState
                    spec.currentOutputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)
                    if spec.fruitTypeConverters[spec.currentInputFruitType] ~= nil then
                        spec.currentOutputFillType = spec.fruitTypeConverters[spec.currentInputFruitType].fillTypeIndex
                        spec.currentConversionFactor = spec.fruitTypeConverters[spec.currentInputFruitType].conversionFactor
                    end
                    self:setCutterCutHeight((g_fruitTypeManager:getCutHeightByFruitTypeIndex(fruitTypeIndex, spec.allowsForageGrowthState)))
                end
                self:setTestAreaRequirements(fruitTypeIndex, nil, spec.allowsForageGrowthState)
                if terrainDetailPixelsSum > 0 then
                    spec.currentInputFruitTypeAI = fruitTypeIndex
                end
                spec.currentInputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
                spec.useWindrow = false
            end
            lastMultiplierArea = area * g_currentMission:getHarvestScaleMultiplier(fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPerc)
            spec.workAreaParameters.lastFruitType = fruitTypeIndex
            lastArea = area
            break
        end
    end
    if lastArea > 0 then
        if workArea.chopperAreaIndex ~= nil and spec.workAreaParameters.lastFruitType ~= nil then
            local chopperWorkArea = self:getWorkAreaByIndex(workArea.chopperAreaIndex)
            if chopperWorkArea == nil then
                Logging.xmlWarning(self.xmlFile, "Invalid chopperAreaIndex \'%d\' for workArea \'%d\'!", workArea.chopperAreaIndex, workArea.index)
                workArea.chopperAreaIndex = nil
            else
                local strawGroundType
                xs, strawGroundType, zs = getWorldTranslation(chopperWorkArea.start)
                local strawGroundType
                xw, strawGroundType, zw = getWorldTranslation(chopperWorkArea.width)
                local strawGroundType
                xh, strawGroundType, zh = getWorldTranslation(chopperWorkArea.height)
                local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(spec.workAreaParameters.lastFruitType)
                if fruitTypeDesc.chopperType == nil then
                    if fruitTypeDesc.chopperUseHaulm and FSDensityMapUtil.updateFruitHaulmArea(spec.workAreaParameters.lastFruitType, xs, zs, xw, zw, xh, zh) > 0 then
                        FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)
                    end
                else
                    local strawGroundType = FieldChopperType.getValueByType(fruitTypeDesc.chopperType)
                    if strawGroundType ~= nil then
                        FSDensityMapUtil.setGroundTypeLayerArea(xs, zs, xw, zw, xh, zh, strawGroundType)
                    end
                end
            end
        end
        spec.stoneLastState = FSDensityMapUtil.getStoneArea(xs, zs, xw, zw, xh, zh)
        spec.isWorking = true
    end
    spec.workAreaParameters.lastArea = spec.workAreaParameters.lastArea + lastArea
    spec.workAreaParameters.lastMultiplierArea = spec.workAreaParameters.lastMultiplierArea + lastMultiplierArea
    return spec.workAreaParameters.lastArea, lastTotalArea
end
function Cutter:processPickupCutterArea(workArea, _)
    local spec = self.spec_cutter
    if not self.isServer and self.currentUpdateDistance > Cutter.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    if spec.workAreaParameters.combineVehicle ~= nil then
        local hasPickedUp = false
        local sx, sy, sz = getWorldTranslation(workArea.start)
        local wx, wy, wz = getWorldTranslation(workArea.width)
        local hx, hy, hz = getWorldTranslation(workArea.height)
        local lsx, lsy, lsz, lex, ley, lez, lineRadius = DensityMapHeightUtil.getLineByAreaDimensions(sx, sy, sz, wx, wy, wz, hx, hy, hz)
        for inputFillTypeIndex, outputData in pairs(spec.fillTypeConverter) do
            if spec.workAreaParameters.lastOutputFillType == nil or outputData.targetFillTypeIndex == spec.workAreaParameters.lastOutputFillType then
                local pickedUpLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, inputFillTypeIndex, lsx, lsy, lsz, lex, ley, lez, lineRadius, nil, nil, false, nil)
                if self.isServer and pickedUpLiters > 0 then
                    spec.currentOutputFillType = outputData.targetFillTypeIndex
                    spec.currentConversionFactor = outputData.conversionFactor
                    spec.useWindrow = true
                    spec.currentInputFillType = inputFillTypeIndex
                    local pickedUpLiters = g_fruitTypeManager:getCutWindrowHarvestFillLevel(inputFillTypeIndex, pickedUpLiters)
                    spec.workAreaParameters.lastLiters = pickedUpLiters
                    spec.workAreaParameters.lastOutputFillType = outputData.targetFillTypeIndex
                    spec.stoneLastState = FSDensityMapUtil.getStoneArea(sx, sz, wx, wz, hx, hz)
                    spec.isWorking = true
                    self:setTestAreaRequirements(nil, inputFillTypeIndex, nil)
                    hasPickedUp = true
                    break
                end
            end
        end
        if not self.isServer and spec.lastAreaBiggerZeroTime + 300 > g_currentMission.time and true or hasPickedUp then
            return 1, 1
        end
        spec.workAreaParameters.lastOutputFillType = nil
    end
    return 0, 0
end
function Cutter:processHaulmDropArea(workArea, dt)
    local spec = self.spec_cutter
    if not self.isServer and self.currentUpdateDistance > Cutter.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    if spec.valueDelay ~= nil then
        if spec.valueDelay:add(spec.lastAreaBiggerZeroTime >= g_currentMission.time - 150 and 1 or 0, dt) == 0 then
            return 0, 0
        end
    end
    local isCutting = spec.currentInputFruitType
    if isCutting == nil or isCutting == FruitType.UNKNOWN then
        return 0, 0
    end
    local value, _, sz = getWorldTranslation(workArea.start)
    local wx, _, wz = getWorldTranslation(workArea.width)
    local hx, _, hz = getWorldTranslation(workArea.height)
    local area = FSDensityMapUtil.updateFruitHaulmArea(isCutting, value, sz, wx, wz, hx, hz)
    if area > 0 then
        FSDensityMapUtil.eraseTireTrack(value, sz, wx, wz, hx, hz)
    end
    return area, area
end
function Cutter:onStartWorkAreaProcessing(_)
    local spec = self.spec_cutter
    local alternativeCombine, alternativeCombine, requiredFillType = self:getCombine()
    if alternativeCombine == nil then
        local _ = requiredFillType == nil
    end
    spec.workAreaParameters.combineVehicle = alternativeCombine
    spec.workAreaParameters.lastLiters = 0
    spec.workAreaParameters.lastArea = 0
    spec.workAreaParameters.lastMultiplierArea = 0
    if spec.workAreaParameters.lastFruitType == nil then
        spec.workAreaParameters.fruitTypeIndicesToUse = spec.fruitTypeIndices
    else
        local i = 1
        for i = i, #spec.workAreaParameters.lastFruitTypeToUse do
            spec.workAreaParameters.lastFruitTypeToUse[i] = nil
        end
        spec.workAreaParameters.lastFruitTypeToUse[1] = spec.workAreaParameters.lastFruitType
        spec.workAreaParameters.fruitTypeIndicesToUse = spec.workAreaParameters.lastFruitTypeToUse
    end
    if requiredFillType ~= nil then
        local i = 1
        local fruitType = #spec.workAreaParameters.lastFruitTypeToUse
        for i = i, fruitType do
            spec.workAreaParameters.lastFruitTypeToUse[i] = nil
        end
        local fruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(requiredFillType)
        for inputFruitType, fruitTypeConverter in pairs(spec.fruitTypeConverters) do
            if fruitTypeConverter.fillTypeIndex == requiredFillType then
                table.insert(spec.workAreaParameters.lastFruitTypeToUse, inputFruitType)
                fruitType = nil
            end
        end
        if fruitType ~= nil then
            table.insert(spec.workAreaParameters.lastFruitTypeToUse, fruitType)
        end
        spec.workAreaParameters.fruitTypeIndicesToUse = spec.workAreaParameters.lastFruitTypeToUse
    end
    spec.workAreaParameters.lastFruitType = nil
    spec.isWorking = false
end
function Cutter:onEndWorkAreaProcessing(_, _)
    if self.isServer then
        local spec = self.spec_cutter
        local lastArea = spec.workAreaParameters.lastArea
        local lastLiters = spec.workAreaParameters.lastLiters
        spec.lastAreaBiggerZero = false
        if lastArea > 0 or lastLiters > 0 then
            if spec.workAreaParameters.combineVehicle ~= nil then
                local inputFruitType = spec.workAreaParameters.lastFruitType
                if self:getIsAIActive() then
                    local requirements = self:getAIFruitRequirements()
                    local requirement = requirements[1]
                    if #requirements == 1 and (requirement ~= nil and requirement.fruitType ~= FruitType.UNKNOWN) then
                        inputFruitType = requirement.fruitType
                    end
                end
                local requirements = g_fruitTypeManager:getFruitTypeAreaLiters(inputFruitType, spec.workAreaParameters.lastMultiplierArea, false) + lastLiters
                local requirement = spec.currentOutputFillType
                if spec.lastOutputFillTypes[requirement] == nil then
                    spec.lastOutputFillTypes[requirement] = lastArea
                else
                    spec.lastOutputFillTypes[requirement] = spec.lastOutputFillTypes[requirement] + lastArea
                end
                local requirement
                if spec.lastPrioritizedOutputType == FillType.UNKNOWN then
                else
                    requirement = spec.lastPrioritizedOutputType
                end
                local conversionFactor = spec.currentConversionFactor or 1
                local requirements = requirements * conversionFactor
                local farmId = self:getLastTouchedFarmlandFarmId()
                if spec.workAreaParameters.combineVehicle:addCutterArea(lastArea, requirements, inputFruitType, requirement, spec.strawRatio * (1 / conversionFactor), farmId, self:getCutterLoad()) > 0 and requirement == requirement then
                    spec.lastValidInputFruitType = inputFruitType
                end
            end
            local inputFruitType = MathUtil.areaToHa(lastArea, g_currentMission:getFruitPixelsToSqm())
            g_farmManager:updateFarmStats(self:getLastTouchedFarmlandFarmId(), "threshedHectares", inputFruitType)
            self:updateLastWorkedArea(lastArea)
            local requirements = true
            if lastArea <= 0 then
                requirements = lastLiters > 0
            end
            spec.lastAreaBiggerZero = requirements
            if spec.currentInputFruitType ~= spec.currentInputFruitTypeSent then
                self:raiseDirtyFlags(spec.effectDirtyFlag)
                spec.currentInputFruitTypeSent = spec.currentInputFruitType
            end
            if spec.currentInputFillType ~= spec.currentInputFillTypeSent then
                self:raiseDirtyFlags(spec.effectDirtyFlag)
                spec.currentInputFillTypeSent = spec.currentInputFillType
            end
            if self:getAllowCutterAIFruitRequirements() and (self.setAIFruitRequirements ~= nil and not spec.useWindrow) then
                local requirements = self:getAIFruitRequirements()
                local requirement = requirements[1]
                if #requirements > 1 or (requirement == nil or requirement.fruitType == FruitType.UNKNOWN) then
                    local targetOutputFillType = g_fruitTypeManager:getFruitTypeByIndex(spec.currentInputFruitTypeAI)
                    if targetOutputFillType ~= nil then
                        self:setAIFruitRequirements(spec.currentInputFruitTypeAI, spec.allowsForageGrowthState and targetOutputFillType.minForageGrowthState or targetOutputFillType.minHarvestingGrowthState, targetOutputFillType.maxHarvestingGrowthState)
                    end
                end
            end
        end
        if spec.lastAreaBiggerZero then
            spec.lastAreaBiggerZeroTime = g_currentMission.time
        end
        if spec.lastAreaBiggerZero ~= spec.lastAreaBiggerZeroSent then
            self:raiseDirtyFlags(spec.dirtyFlag)
            spec.lastAreaBiggerZeroSent = spec.lastAreaBiggerZero
        end
    end
end
function Cutter:getCutterLoad()
    local speedLimitFactor = math.clamp(self:getLastSpeed() / self.speedLimit, 0, 1) * 0.75 + 0.25
    return self.spec_cutter.cutterLoad * speedLimitFactor
end
function Cutter:getCutterStoneMultiplier()
    local spec = self.spec_cutter
    return (spec.stoneLastState == 0 or spec.stoneWearMultiplierData == nil) and 1 or (spec.stoneWearMultiplierData[spec.stoneLastState] or 1)
end
function Cutter:loadCutterTiltFromXML(xmlFile, key, target)
    target.nodes = {}
    xmlFile:iterate(key .. ".automaticTiltNode", function(_, nodeKey)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) target
        local entry = {
            ["node"] = xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)
        }
        if entry.node ~= nil then
            entry.minAngle = xmlFile:getValue(nodeKey .. "#minAngle", -5)
            entry.maxAngle = xmlFile:getValue(nodeKey .. "#maxAngle", 5)
            entry.maxSpeed = xmlFile:getValue(nodeKey .. "#maxSpeed", 2) / 1000
            table.insert(target.nodes, entry)
        end
    end)
    target.raycastNode1 = xmlFile:getValue(key .. "#raycastNode1", nil, self.components, self.i3dMappings)
    target.raycastNode2 = xmlFile:getValue(key .. "#raycastNode2", nil, self.components, self.i3dMappings)
    if target.raycastNode1 == nil or target.raycastNode2 == nil then
        return false
    end
    local x1, _, _ = localToLocal(target.raycastNode1, self.rootNode, 0, 0, 0)
    local x2, _, _ = localToLocal(target.raycastNode2, self.rootNode, 0, 0, 0)
    if x1 < x2 then
        target.raycastNode1 = target.raycastNode2
        target.raycastNode2 = target.raycastNode1
    end
    return true
end
function Cutter:getCutterTiltIsAvailable()
    return self.spec_cutter.automaticTilt.isAvailable
end
function Cutter:getCutterTiltIsActive(automaticTilt)
    if automaticTilt.isAvailable and self.isActive then
        if self:getIsLowered(true) and (self.getAttacherVehicle == nil or self:getAttacherVehicle() ~= nil) then
            return true, false
        else
            return false, true
        end
    else
        return false, false
    end
end
function Cutter:getCutterTiltDelta()
    local spec = self.spec_cutter
    local isActive, doReset = self:getCutterTiltIsActive(spec.automaticTilt)
    return isActive and spec.automaticTilt.currentDelta or 0, isActive, doReset
end
function Cutter:tiltRaycastDetectionCallbackLeft(hitObjectId, x, y, z, _, _, _, _, _, _, _)
    if hitObjectId == 0 or getRigidBodyType(hitObjectId) ~= RigidBodyType.STATIC then
        return true
    end
    local automaticTilt = self.spec_cutter.automaticTilt
    automaticTilt.lastHit1[1] = x
    automaticTilt.lastHit1[2] = y
    automaticTilt.lastHit1[3] = z
    return false
end
function Cutter:tiltRaycastDetectionCallbackRight(hitObjectId, x, y, z, _, _, _, _, _, _, isLast)
    if not (self.isDeleted or self.isDeleting) then
        if hitObjectId ~= 0 and getRigidBodyType(hitObjectId) == RigidBodyType.STATIC then
            self.spec_cutter.automaticTilt.lastHit2[1] = x
            automaticTilt.lastHit2[2] = y
            automaticTilt.lastHit2[3] = z
        end
        if isLast then
            local rDirX, rDirY, rDirZ = localDirectionToWorld(automaticTilt.raycastNode1, 0, -1, 0)
            local hit1Y = automaticTilt.lastHit1[2]
            local node1X, node1Y, node1Z = getWorldTranslation(automaticTilt.raycastNode1)
            local hit2Y = automaticTilt.lastHit2[2]
            local node2X, node2Y, node2Z = getWorldTranslation(automaticTilt.raycastNode2)
            local gHeight = hit1Y - hit2Y
            local gDistance = MathUtil.vector3Length(automaticTilt.lastHit1[1] - (automaticTilt.lastHit2[1] + rDirX * gHeight), hit1Y - (hit2Y + rDirY * gHeight), automaticTilt.lastHit1[3] - (automaticTilt.lastHit2[3] + rDirZ * gHeight))
            local cDistance = math.abs(gHeight) / gDistance
            local gAngle = math.atan(cDistance) * (hit1Y < hit2Y and -1 or 1)
            local cDistance = MathUtil.vector3Length(node1X - node2X, node1Y - node2Y, node1Z - node2Z)
            local cAngle = math.atan(math.abs(node2Y - node1Y) / cDistance) * (node1Y < node2Y and -1 or 1)
            if not (MathUtil.isNan(gAngle) or MathUtil.isNan(cAngle)) then
                automaticTilt.currentDelta = gAngle - cAngle
            end
        end
    end
end
function Cutter:setCutterCutHeight(cutHeight)
    if cutHeight ~= nil then
        self.spec_cutter.currentCutHeight = cutHeight
        if self.spec_attachable ~= nil then
            local inputAttacherJoint = self:getActiveInputAttacherJoint()
            if inputAttacherJoint == nil or not inputAttacherJoint.useFruitCutHeight then
                local inputAttacherJoints = self:getInputAttacherJoints()
                local i = 1
                for i = i, #inputAttacherJoints do
                    local inputAttacherJoint = inputAttacherJoints[i]
                    if inputAttacherJoint.useFruitCutHeight and (inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTER or inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER) then
                        inputAttacherJoint.lowerDistanceToGround = cutHeight
                    end
                end
            elseif inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTER or inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER then
                inputAttacherJoint.lowerDistanceToGround = cutHeight
                return
            end
        end
    end
end
function Cutter:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
    if not superFunc(self, speedRotatingPart, xmlFile, key) then
        return false
    end
    speedRotatingPart.rotateIfTurnedOn = xmlFile:getValue(key .. "#rotateIfTurnedOn", false)
    return true
end
function Cutter:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
    if speedRotatingPart.rotateIfTurnedOn and not self:getIsTurnedOn() then
        return false
    else
        return superFunc(self, speedRotatingPart)
    end
end
function Cutter:loadRandomlyMovingPartFromXML(superFunc, part, xmlFile, key)
    local retValue = superFunc(self, part, xmlFile, key)
    part.moveOnlyIfCut = xmlFile:getValue(key .. "#moveOnlyIfCut", false)
    return retValue
end
function Cutter:getIsRandomlyMovingPartActive(superFunc, part)
    local retValue = superFunc(self, part)
    if part.moveOnlyIfCut then
        if retValue then
            retValue = self.spec_cutter.lastAreaBiggerZeroTime >= g_currentMission.time - 150
        end
    end
    return retValue
end
function Cutter:getIsWorkAreaActive(superFunc, workArea)
    if workArea.type == WorkAreaType.CUTTER then
        if (self.getAllowsLowering == nil or self:getAllowsLowering()) and not (self.spec_cutter.allowCuttingWhileRaised or self:getIsLowered(true)) then
            return false
        end
    end
    return superFunc(self, workArea)
end
function Cutter:doCheckSpeedLimit(superFunc)
    return not superFunc(self) and self:getIsTurnedOn() and (self.getIsLowered == nil or self:getIsLowered())
end
function Cutter:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = superFunc(self, workArea, xmlFile, key)
    workArea.chopperAreaIndex = xmlFile:getValue(key .. ".chopperArea#index")
    return retValue
end
function Cutter:getDirtMultiplier(superFunc)
    if self.spec_cutter.isWorking then
        return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    else
        return superFunc(self)
    end
end
function Cutter:getWearMultiplier(superFunc)
    local spec = self.spec_cutter
    if not spec.isWorking then
        return superFunc(self)
    end
    return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * (spec.stoneLastState ~= 0 and spec.stoneWearMultiplierData ~= nil and (spec.stoneWearMultiplierData[spec.stoneLastState] or 1) or 1)
end
function Cutter:isAttachAllowed(superFunc, farmId, attacherVehicle)
    if attacherVehicle.spec_combine == nil or attacherVehicle:getIsCutterCompatible(self.spec_cutter.outputFillTypes) then
        return superFunc(self, farmId, attacherVehicle)
    else
        return false, g_i18n:getText("warning_cutterNotCompatible")
    end
end
function Cutter:getConsumingLoad(superFunc)
    local value, count = superFunc(self)
    return value + self:getCutterLoad(), count + 1
end
function Cutter:getIsGroundReferenceNodeThreshold(superFunc, groundReferenceNode)
    return superFunc(self, groundReferenceNode) + self.spec_cutter.currentCutHeight
end
function Cutter:getDefaultAllowComponentMassReduction()
    return true
end
function Cutter:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, i)
    if not superFunc(self, xmlFile, key, inputAttacherJoint, i) then
        return false
    end
    inputAttacherJoint.useFruitCutHeight = xmlFile:getValue(key .. "#useFruitCutHeight", true)
    return true
end
function Cutter:getFruitExtraObjectTypeData(_)
    return self.spec_cutter.lastValidInputFruitType, nil
end
function Cutter:onTurnedOn()
    if self.isClient then
        g_animationManager:startAnimations(self.spec_cutter.animationNodes)
    end
end
function Cutter:onTurnedOff()
    local spec = self.spec_cutter
    if self.isClient then
        g_animationManager:stopAnimations(spec.animationNodes)
    end
    spec.currentInputFruitType = FruitType.UNKNOWN
    spec.currentInputFruitTypeSent = FruitType.UNKNOWN
    spec.currentInputFruitTypeAI = FruitType.UNKNOWN
    spec.currentInputFillType = FillType.UNKNOWN
    spec.currentOutputFillType = FillType.UNKNOWN
end
function Cutter:onAIImplementStart()
    if self:getAllowCutterAIFruitRequirements() then
        self:clearAIFruitRequirements()
        local spec = self.spec_cutter
        for _, fruitTypeIndex in ipairs(spec.fruitTypeIndices) do
            local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
            if fruitType ~= nil then
                local outputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
                if spec.fruitTypeConverters[fruitTypeIndex] ~= nil then
                    outputFillType = spec.fruitTypeConverters[fruitTypeIndex].fillTypeIndex
                end
                if self:getCombine(fruitTypeIndex, outputFillType) ~= nil then
                    self:addAIFruitRequirement(fruitType.index, spec.allowsForageGrowthState and fruitType.minForageGrowthState or fruitType.minHarvestingGrowthState, fruitType.maxHarvestingGrowthState)
                end
            end
        end
    end
end
function Cutter.onAIFieldCourseSettingsInitialized(_, fieldCourseSettings)
    fieldCourseSettings.headlandsFirst = true
    fieldCourseSettings.workInitialSegment = true
    fieldCourseSettings.cornerCutOutSupported = true
end
function Cutter.getDefaultSpeedLimit()
    return 10
end
function Cutter:updateDebugValues(values)
    local spec = self.spec_cutter
    table.insert(values, {
        ["name"] = "lastPrioritizedOutputType",
        ["value"] = string.format("%s", g_fillTypeManager:getFillTypeNameByIndex(spec.lastPrioritizedOutputType))
    })
    table.insert(values, {
        ["name"] = "currentCutHeight",
        ["value"] = string.format("%.2f", spec.currentCutHeight)
    })
    local sum = 0
    for fillType, value in pairs(spec.lastOutputFillTypes) do

    end
    for fillType, value in pairs(spec.lastOutputFillTypes) do
        table.insert(values, {
            ["name"] = string.format("buffer (%s)", g_fillTypeManager:getFillTypeNameByIndex(fillType)),
            ["value"] = string.format("%.0f%%", value / math.max(sum, 0.01) * 100)
        })
    end
end