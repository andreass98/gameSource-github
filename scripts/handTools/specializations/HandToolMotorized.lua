HandToolMotorized = {}
function HandToolMotorized.registerXMLPaths(xmlSchema)
    xmlSchema:setXMLSpecializationType("HandToolMotorized")
    xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#startTime", "The amount of milliseconds it takes for the motor to start", 0, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#minRPM", "The RPM of the tool when it is not being used", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#maxRPM", "The RPM of the tool when it has no load and is being used", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#rpmGainSpeed", "The amount of RPM that can be gained per second", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#rpmLossSpeed", "The amount of RPM that can be lost per second", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#rpmVariability", "Variability in rpm while the tool has full load", 0)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.motorized.motor#rpmVariabilityChange", "Variability change factor (the higher, the faster changes the random variability)", 1)
    xmlSchema:register(XMLValueType.VECTOR_3, "handTool.motorized.vibrations#amount", "The base vibration amount along the 3 axes of the tool", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.motorized.vibrations#node", "The name of the node that is vibrated", nil, false)
    SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.motorized.sounds", "start")
    SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.motorized.sounds", "stop")
    SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.motorized.sounds", "idle")
    EffectManager.registerEffectXMLPaths(xmlSchema, "handTool.motorized.exhaustEffects")
    xmlSchema:setXMLSpecializationType()
end
function HandToolMotorized.registerFunctions(handToolType)
    SpecializationUtil.registerFunction(handToolType, "getTimeToReachRPM", HandToolMotorized.getTimeToReachRPM)
    SpecializationUtil.registerFunction(handToolType, "getRPMGainPerSecond", HandToolMotorized.getRPMGainPerSecond)
    SpecializationUtil.registerFunction(handToolType, "setRPMGainPerSecond", HandToolMotorized.setRPMGainPerSecond)
    SpecializationUtil.registerFunction(handToolType, "getRPMLossPerSecond", HandToolMotorized.getRPMLossPerSecond)
    SpecializationUtil.registerFunction(handToolType, "setRPMLossPerSecond", HandToolMotorized.setRPMLossPerSecond)
    SpecializationUtil.registerFunction(handToolType, "getCurrentLoad", HandToolMotorized.getCurrentLoad)
    SpecializationUtil.registerFunction(handToolType, "setCurrentLoad", HandToolMotorized.setCurrentLoad)
    SpecializationUtil.registerFunction(handToolType, "getCurrentRPM", HandToolMotorized.getCurrentRPM)
    SpecializationUtil.registerFunction(handToolType, "setCurrentRPM", HandToolMotorized.setCurrentRPM)
    SpecializationUtil.registerFunction(handToolType, "getMinRPM", HandToolMotorized.getMinRPM)
    SpecializationUtil.registerFunction(handToolType, "getTargetRPM", HandToolMotorized.getTargetRPM)
    SpecializationUtil.registerFunction(handToolType, "getMaxRPM", HandToolMotorized.getMaxRPM)
    SpecializationUtil.registerFunction(handToolType, "setTargetRPM", HandToolMotorized.setTargetRPM)
    SpecializationUtil.registerFunction(handToolType, "setTargetRPMToIdle", HandToolMotorized.setTargetRPMToIdle)
    SpecializationUtil.registerFunction(handToolType, "setTargetRPMToMax", HandToolMotorized.setTargetRPMToMax)
    SpecializationUtil.registerFunction(handToolType, "updateRPM", HandToolMotorized.updateRPM)
    SpecializationUtil.registerFunction(handToolType, "updateSounds", HandToolMotorized.updateSounds)
    SpecializationUtil.registerFunction(handToolType, "updateVibrations", HandToolMotorized.updateVibrations)
end
function HandToolMotorized.registerEventListeners(handToolType)
    SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onHeldStart", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onDebugDraw", HandToolMotorized)
end
function HandToolMotorized.prerequisitesPresent(specializations)
    return true
end
function HandToolMotorized:onLoad(xmlFile, baseDirectory)
    local spec = self.spec_motorized
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.currentLoad = 0
    spec.startTime = xmlFile:getValue("handTool.motorized.motor#startTime", 0)
    spec.minRPM = xmlFile:getValue("handTool.motorized.motor#minRPM", 10)
    spec.maxRPM = xmlFile:getValue("handTool.motorized.motor#maxRPM", 100)
    spec.rpmGainPerSecond = xmlFile:getValue("handTool.motorized.motor#rpmGainSpeed", spec.maxRPM - spec.minRPM)
    spec.rpmLossPerSecond = xmlFile:getValue("handTool.motorized.motor#rpmLossSpeed", spec.maxRPM - spec.minRPM)
    spec.rpmVariability = xmlFile:getValue("handTool.motorized.motor#rpmVariability", 0)
    spec.rpmVariabilityChange = xmlFile:getValue("handTool.motorized.motor#rpmVariabilityChange", 1)
    spec.currentRPM = spec.minRPM
    spec.targetRPM = spec.currentRPM
    spec.vibrationNode = xmlFile:getValue("handTool.motorized.vibrations#node", nil, self.components, self.i3dMappings)
    spec.vibrationAmountX, spec.vibrationAmountY, spec.vibrationAmountZ = xmlFile:getValue("handTool.motorized.vibrations#amount", "0 0 0")
    if self.isClient then
        spec.samples = {}
        spec.samples.start = g_soundManager:loadSampleFromXML(xmlFile, "sounds.motorized.sounds", "start", baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.idle = g_soundManager:loadSampleFromXML(xmlFile, "sounds.motorized.sounds", "idle", baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.stop = g_soundManager:loadSampleFromXML(xmlFile, "sounds.motorized.sounds", "stop", baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        self.exhaustEffects = g_effectManager:loadEffect(xmlFile, "handTool.motorized.exhaustEffects", self.components, self, self.i3dMappings)
    end
end
function HandToolMotorized:onDelete()
    if self.isClient then
        local spec = self.spec_motorized
        g_soundManager:deleteSamples(spec.samples)
        g_effectManager:deleteEffects(spec.fillEffects)
    end
end
function HandToolMotorized:onWriteUpdateStream(streamId, _, dirtyMask)
    local spec = self.spec_motorized
    if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
        NetworkUtil.writeCompressedPercentages(streamId, MathUtil.inverseLerp(spec.minRPM, spec.maxRPM, spec.currentRPM), 8)
        NetworkUtil.writeCompressedPercentages(streamId, spec.currentLoad, 8)
    end
end
function HandToolMotorized:onReadUpdateStream(streamId, _, connection)
    if streamReadBool(streamId) then
        local spec = self.spec_motorized
        local currentRPM = NetworkUtil.readCompressedPercentages(streamId, 8) * (spec.maxRPM - spec.minRPM) + spec.minRPM
        local currentLoad = NetworkUtil.readCompressedPercentages(streamId, 8)
        local carryingPlayer = self:getCarryingPlayer()
        if not connection:getIsServer() or carryingPlayer ~= nil and not carryingPlayer.isOwner then
            self:setCurrentRPM(currentRPM)
            self:setCurrentLoad(currentLoad)
        end
    end
end
function HandToolMotorized:onHeldStart()
    if self.isClient then
        local spec = self.spec_motorized
        local samples = spec.samples
        if not g_soundManager:getIsSamplePlaying(samples.idle) then
            g_soundManager:stopSample(samples.stop)
            g_soundManager:playSample(samples.start)
            g_soundManager:playSample(samples.idle, 0, samples.start)
        end
        g_effectManager:startEffects(spec.exhaustEffects)
    end
end
function HandToolMotorized:onHeldEnd()
    if self.isClient then
        local spec = self.spec_motorized
        local samples = spec.samples
        g_soundManager:stopSample(samples.start)
        g_soundManager:stopSample(samples.idle)
        g_soundManager:playSample(samples.stop)
        g_effectManager:stopEffects(spec.exhaustEffects)
    end
end
function HandToolMotorized:onUpdate(dt)
    self:updateRPM(dt)
    if self.isClient then
        self:updateSounds(dt)
        self:updateVibrations(dt)
    end
end
function HandToolMotorized:updateRPM(dt)
    local spec = self.spec_motorized
    if spec.currentRPM ~= spec.targetRPM then
        local targetRPM = spec.targetRPM
        if spec.rpmVariability > 0 then
            local t = g_currentMission.time * spec.rpmVariabilityChange
            local currentRPM = math.sin(t * 0.00157) * 0.4 + math.sin(t * 0.00414) * 0.4
            local change = currentRPM + math.sin(t * 0.00628) * 0.2
            targetRPM = targetRPM - math.abs(change) * (spec.targetRPM / spec.maxRPM) * (0.1 + spec.currentLoad * 0.9) * spec.maxRPM * spec.rpmVariability
        end
        local t = math.sign(targetRPM - spec.currentRPM)
        local change = t >= 0 and spec.rpmGainPerSecond or spec.rpmLossPerSecond
        self:setCurrentRPM(((t > 0 and math.min or math.max)(spec.currentRPM + change * dt * 0.001 * t, targetRPM)))
    end
end
function HandToolMotorized:updateSounds(_)
    local spec = self.spec_motorized
    local rpmPercentage = MathUtil.inverseLerp(spec.minRPM, spec.maxRPM, spec.currentRPM)
    g_soundManager:setSampleLoopSynthesisParameters(spec.samples.idle, rpmPercentage, self:getCurrentLoad())
end
function HandToolMotorized:updateVibrations(_)
    local spec = self.spec_motorized
    local vibrationX = MathUtil.inverseLerp(spec.minRPM, spec.maxRPM, spec.currentRPM)
    local rpmAmount = 1 - math.clamp(vibrationX, 0, 1)
    local vibrationScale = MathUtil.lerp(0.05, 1, rpmAmount) * (1 - spec.currentLoad)
    local vibrationX = MathUtil.randomFloat(-spec.vibrationAmountX, spec.vibrationAmountX) * vibrationScale
    local vibrationY = MathUtil.randomFloat(-spec.vibrationAmountY, spec.vibrationAmountY) * vibrationScale
    local vibrationZ = MathUtil.randomFloat(-spec.vibrationAmountZ, spec.vibrationAmountZ) * vibrationScale
    setTranslation(spec.vibrationNode, vibrationX, vibrationY, vibrationZ)
end
function HandToolMotorized:getTimeToReachRPM(rpm)
    local spec = self.spec_motorized
    if spec.currentRPM == rpm then
        return 0
    end
    local rpmDelta = rpm - spec.currentRPM
    local rpmPerSecond = math.sign(rpmDelta) >= 0 and spec.rpmGainPerSecond or spec.rpmLossPerSecond
    return math.abs(rpmDelta) / rpmPerSecond
end
function HandToolMotorized:getRPMGainPerSecond()
    return self.spec_motorized.rpmGainPerSecond
end
function HandToolMotorized:setRPMGainPerSecond(rpmGainPerSecond)
    self.spec_motorized.rpmGainPerSecond = rpmGainPerSecond
end
function HandToolMotorized:getRPMLossPerSecond()
    return self.spec_motorized.rpmLossPerSecond
end
function HandToolMotorized:setRPMLossPerSecond(rpmLossPerSecond)
    self.spec_motorized.rpmLossPerSecond = rpmLossPerSecond
end
function HandToolMotorized:getCurrentLoad()
    return self.spec_motorized.currentLoad
end
function HandToolMotorized:setCurrentLoad(currentLoad)
    local spec = self.spec_motorized
    local carryingPlayer = math.clamp(currentLoad, 0, 1)
    if math.abs(spec.currentLoad - carryingPlayer) > 0.01 then
        local carryingPlayer = self:getCarryingPlayer()
        if self.isServer or carryingPlayer ~= nil and carryingPlayer.isOwner then
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    end
    spec.currentLoad = carryingPlayer
end
function HandToolMotorized:getCurrentRPM()
    return self.spec_motorized.currentRPM
end
function HandToolMotorized:setCurrentRPM(currentRPM)
    local spec = self.spec_motorized
    local carryingPlayer = math.clamp(currentRPM, spec.minRPM, spec.maxRPM)
    if math.abs(spec.currentRPM - carryingPlayer) > 1 then
        local carryingPlayer = self:getCarryingPlayer()
        if self.isServer or carryingPlayer ~= nil and carryingPlayer.isOwner then
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    end
    spec.currentRPM = carryingPlayer
end
function HandToolMotorized:getTargetRPM()
    return self.spec_motorized.targetRPM
end
function HandToolMotorized:getMaxRPM()
    return self.spec_motorized.maxRPM
end
function HandToolMotorized:getMinRPM()
    return self.spec_motorized.minRPM
end
function HandToolMotorized:setTargetRPM(targetRPM)
    local spec = self.spec_motorized
    spec.targetRPM = math.clamp(targetRPM, spec.minRPM, spec.maxRPM)
end
function HandToolMotorized:setTargetRPMToIdle()
    self:setTargetRPM(self.spec_motorized.minRPM)
end
function HandToolMotorized:setTargetRPMToMax()
    self:setTargetRPM(self.spec_motorized.maxRPM)
end
function HandToolMotorized:onDebugDraw(x, y, textSize)
    local spec = self.spec_motorized
    local rpmAmount = DebugUtil.renderTextLine(x, y, textSize, string.format("Current RPM: %d", spec.currentRPM))
    local rpmAmount = DebugUtil.renderTextLine(x, rpmAmount, textSize, string.format("Target RPM: %d", spec.targetRPM))
    local rpmAmount = DebugUtil.renderTextLine(x, rpmAmount, textSize, string.format("Current Load: %d%%", spec.currentLoad * 100))
    local rpmAmount = 1 - math.clamp(MathUtil.inverseLerp(spec.minRPM, spec.maxRPM, spec.currentRPM), 0, 1)
    local vibrationScale = MathUtil.lerp(0.05, 1, rpmAmount) * (1 - spec.currentLoad)
    return DebugUtil.renderTextLine(x, rpmAmount, textSize, string.format("Vibration: %d%%", vibrationScale * 100))
end