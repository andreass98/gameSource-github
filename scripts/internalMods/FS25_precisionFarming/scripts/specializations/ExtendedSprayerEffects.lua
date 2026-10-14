ExtendedSprayerEffects = {}
ExtendedSprayerEffects.SPEC_NAME = g_currentModName .. ".extendedSprayerEffects"
ExtendedSprayerEffects.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedSprayerEffects"
ExtendedSprayerEffects.EFFECT_DIRECTION_OFF = { 0, 0 }
ExtendedSprayerEffects.EFFECT_DIRECTION_START = { 1, 1 }
ExtendedSprayerEffects.EFFECT_DIRECTION_STOP = { 1, -1 }
function ExtendedSprayerEffects.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Sprayer, specializations) and SpecializationUtil.hasSpecialization(ExtendedSprayer, specializations)
end
function ExtendedSprayerEffects.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ExtendedSprayerEffects")
    schema:register(XMLValueType.INT, "vehicle.sprayer.nozzles(?)#foldingConfigurationIndex", "Folding configuration index to use these nozzles", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.sprayer.nozzles(?).nozzle(?)#node", "Nozzle Node")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.sprayer.nozzles(?).nozzle(?)#translation", "Translation offset from the defined node")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.sprayer.nozzles(?).nozzle(?)#rotation", "Rotation offset from the defined node")
    schema:setXMLSpecializationType()
end
function ExtendedSprayerEffects.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "addExtendedSprayerNozzleEffects", ExtendedSprayerEffects.addExtendedSprayerNozzleEffects)
    SpecializationUtil.registerFunction(vehicleType, "addExtendedSprayerNozzleEffect", ExtendedSprayerEffects.addExtendedSprayerNozzleEffect)
    SpecializationUtil.registerFunction(vehicleType, "initExtendedSprayerNozzleEffect", ExtendedSprayerEffects.initExtendedSprayerNozzleEffect)
    SpecializationUtil.registerFunction(vehicleType, "updateExtendedSprayerNozzleEffectsState", ExtendedSprayerEffects.updateExtendedSprayerNozzleEffectsState)
    SpecializationUtil.registerFunction(vehicleType, "updateExtendedSprayerNozzleEffectState", ExtendedSprayerEffects.updateExtendedSprayerNozzleEffectState)
    SpecializationUtil.registerFunction(vehicleType, "updateExtendedSprayerNozzleEffects", ExtendedSprayerEffects.updateExtendedSprayerNozzleEffects)
    SpecializationUtil.registerFunction(vehicleType, "getNumExtendedSprayerNozzleEffectsActive", ExtendedSprayerEffects.getNumExtendedSprayerNozzleEffectsActive)
end
function ExtendedSprayerEffects.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreEffectsVisible", ExtendedSprayerEffects.getAreEffectsVisible)
end
function ExtendedSprayerEffects.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedSprayerEffects)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ExtendedSprayerEffects)
    SpecializationUtil.registerEventListener(vehicleType, "onPreInitComponentPlacement", ExtendedSprayerEffects)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedSprayerEffects)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExtendedSprayerEffects)
end
function ExtendedSprayerEffects:onLoad(_)
    local spec = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
    local linkData = (self.configurations.pulseWidthModulation or 1) > 1
    spec.pwmEnabled = linkData
    local linkData = spec.pwmEnabled
    if not linkData then
        linkData = false
        if self.getIsSpotSprayEnabled ~= nil then
            linkData = self:getIsSpotSprayEnabled()
        end
    end
    spec.individualNozzleControl = linkData
    spec.effectFadeTime = 250
    spec.effectsDirty = false
    spec.sprayerEffects = {}
    spec.sprayerEffectsBySection = {}
    spec.soundSamplesBySection = {}
    if g_precisionFarming ~= nil then
        local linkData, _ = g_precisionFarming:getSprayerNodeData(self.configFileName, self.configurations)
        if linkData ~= nil then
            self:addExtendedSprayerNozzleEffects(linkData)
        end
    end
    spec.nozzleNodesToDelete = {}
    self.xmlFile:iterate("vehicle.sprayer.nozzles", function(_, nozzlesKey)
        -- upvalues: (copy) self, (copy) spec
        local foldingConfigIndex = self.xmlFile:getValue(nozzlesKey .. "#foldingConfigurationIndex", 1)
        self.xmlFile:iterate(nozzlesKey .. ".nozzle", function(_, key)
            -- upvalues: (ref) self, (copy) foldingConfigIndex, (ref) spec
            local linkNode = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
            if linkNode ~= nil then
                if foldingConfigIndex == self.configurations.folding or self.configurations.folding == nil and foldingConfigIndex == 1 then
                    local effectNode = g_precisionFarming:getClonedSprayerEffectNode()
                    if effectNode ~= nil then
                        local effectData = {}
                        if self:addExtendedSprayerNozzleEffect(effectData, effectNode, linkNode, {
                            ["translation"] = self.xmlFile:getValue(key .. "#translation", { 0, 0, 0 }, true),
                            ["rotation"] = self.xmlFile:getValue(key .. "#rotation", { 0, 0, 0 }, true)
                        }) then
                            table.insert(spec.sprayerEffects, effectData)
                            return
                        end
                    end
                else
                    spec.nozzleNodesToDelete[linkNode] = true
                end
            end
        end)
    end)
    local i = 1
    local linkData = #spec.nozzleNodesToDelete
    for i = i, linkData do
        if entityExists(spec.nozzleNodesToDelete[i]) then
            delete(spec.nozzleNodesToDelete[i])
        end
    end
    spec.nozzleNodesToDelete = {}
end
function ExtendedSprayerEffects:onPostLoad(_)
    local spec = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
    for _, effectData in pairs(spec.sprayerEffects) do
        self:initExtendedSprayerNozzleEffect(effectData)
        if spec.sprayerEffectsBySection[effectData.sectionIndex] == nil then
            spec.sprayerEffectsBySection[effectData.sectionIndex] = {}
        end
        table.insert(spec.sprayerEffectsBySection[effectData.sectionIndex], effectData)
    end
end
function ExtendedSprayerEffects:onPreInitComponentPlacement(_)
    local spec = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
    spec.numCustomEffects = #spec.sprayerEffects
    local specSprayer = spec.numCustomEffects > 0
    spec.hasCustomEffects = specSprayer
    if spec.hasCustomEffects then
        SpecializationUtil.removeEventListener(self, "onDraw", VariableWorkWidth)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", VariableWorkWidth)
        local specSprayer = self.spec_sprayer
        if specSprayer.samples ~= nil then
            g_soundManager:deleteSamples(specSprayer.samples.spray)
            specSprayer.samples.spray = {}
        end
        for _, sprayType in pairs(specSprayer.sprayTypes) do
            if sprayType.samples ~= nil then
                g_soundManager:deleteSamples(sprayType.samples.spray)
                sprayType.samples.spray = {}
            end
        end
        local leftX = 0
        local leftY = 0
        local leftZ = 0
        local _ = 0
        local sprayType = 0
        local rightY = 0
        local rightZ = 0
        local numRight = 0
        for sectionIndex, sprayerEffects in pairs(spec.sprayerEffectsBySection) do
            local linkNode = createTransformGroup("sectionCenterNode" .. tostring(sectionIndex))
            link(self.rootNode, linkNode)
            local wx = 0
            local wy = 0
            local wz = 0
            local isLeft = false
            for i, effectData in ipairs(sprayerEffects) do
                local x, y, z = getWorldTranslation(effectData.effectNode)
                local xOffset, _, _ = localToLocal(effectData.effectNode, self.rootNode, 0, 0, 0)
                if xOffset > 0 then
                    isLeft = true
                end
            end
            local numEffects = #sprayerEffects
            local wx = wx / numEffects
            local wy = wy / numEffects
            local wz = wz / numEffects
            setWorldTranslation(linkNode, wx, wy, wz)
            spec.soundSamplesBySection[sectionIndex] = {
                ["linkNode"] = linkNode,
                ["sectionIndex"] = sectionIndex,
                ["sprayIsActive"] = false,
                ["isLeft"] = isLeft
            }
        end
        if _ > 0 then
            local sampleLinkNode = createTransformGroup("sectionsLeftNode")
            link(self.rootNode, sampleLinkNode)
            setWorldTranslation(sampleLinkNode, leftX / _, leftY / _, leftZ / _)
            spec.spraySampleLeft = g_precisionFarming:getSprayerClonedSectionSamples("spray", sampleLinkNode, self)
        end
        if numRight > 0 then
            local sampleLinkNode = createTransformGroup("sectionsRightNode")
            link(self.rootNode, sampleLinkNode)
            setWorldTranslation(sampleLinkNode, sprayType / numRight, rightY / numRight, rightZ / numRight)
            spec.spraySampleRight = g_precisionFarming:getSprayerClonedSectionSamples("spray", sampleLinkNode, self)
        end
        for sectionIndex, sprayerEffects in pairs(spec.soundSamplesBySection) do
            if sprayerEffects.isLeft then
                sprayerEffects.spray = spec.spraySampleLeft
            else
                sprayerEffects.spray = spec.spraySampleRight
            end
        end
    else
        SpecializationUtil.removeEventListener(self, "onUpdate", ExtendedSprayerEffects)
    end
end
function ExtendedSprayerEffects:onUpdate(dt, _, _, _)
    local spec = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
    local isTurnedOn = self:getIsTurnedOn()
    local lastSpeed = self:getLastSpeed()
    if spec.individualNozzleControl then
        self:updateExtendedSprayerNozzleEffectsState(spec.sprayerEffects, false, dt, isTurnedOn, lastSpeed)
    else
        for _, sprayerEffects in pairs(spec.sprayerEffectsBySection) do
            self:updateExtendedSprayerNozzleEffectsState(sprayerEffects, true, dt, isTurnedOn, lastSpeed)
        end
    end
    if spec.effectsDirty then
        spec.effectsDirty = false
        self:updateExtendedSprayerNozzleEffects(dt)
        self:raiseActive()
    end
end
function ExtendedSprayerEffects:onDelete()
    local spec = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
    g_soundManager:deleteSample(spec.spraySampleLeft)
    g_soundManager:deleteSample(spec.spraySampleRight)
end
function ExtendedSprayerEffects:addExtendedSprayerNozzleEffects(linkData)
    for _, effectNodeData in pairs(linkData.effectNodes) do
        local linkNode = nil
        if effectNodeData.nodeName ~= nil and self.i3dMappings[effectNodeData.nodeName] ~= nil then
            linkNode = self.i3dMappings[effectNodeData.nodeName].nodeId
        end
        if linkNode ~= nil then
            local effectNode = g_precisionFarming:getClonedSprayerEffectNode()
            if effectNode ~= nil then
                local effectData = {}
                if self:addExtendedSprayerNozzleEffect(effectData, effectNode, linkNode, effectNodeData) then
                    table.insert(self[ExtendedSprayerEffects.SPEC_TABLE_NAME].sprayerEffects, effectData)
                end
            end
        end
    end
end
function ExtendedSprayerEffects:addExtendedSprayerNozzleEffect(effectData, effectNode, linkNode, effectNodeData)
    effectData.effectNode = effectNode
    effectData.isActive = false
    effectData.amountScale = 1
    effectData.lastWorldTranslation = { 0, 0, 0 }
    effectData.speed = 0
    effectData.fadeCur = { -1, 1 }
    effectData.fadeDir = ExtendedSprayerEffects.EFFECT_DIRECTION_OFF
    effectData.state = ShaderPlaneEffect.STATE_OFF
    setShaderParameter(effectNode, "fadeProgress", effectData.fadeCur[1], effectData.fadeCur[2], 0, 0, false)
    setShaderParameter(effectNode, "offsetUV", math.random(), math.random(), 0, 0, false)
    setShaderParameter(effectNode, "isPulsating", self[ExtendedSprayerEffects.SPEC_TABLE_NAME].pwmEnabled and 1 or 0, nil, nil, nil, false)
    setShaderParameter(effectNode, "blinkMulti", 1, 1, 100, math.random() * 100, false)
    link(linkNode, effectNode)
    if effectNodeData ~= nil then
        setTranslation(effectNode, effectNodeData.translation[1], effectNodeData.translation[2], effectNodeData.translation[3])
        setRotation(effectNode, effectNodeData.rotation[1], effectNodeData.rotation[2], effectNodeData.rotation[3])
    end
    effectData.xOffset, _, _ = localToLocal(effectNode, self:getParentComponent(linkNode), 0, 0, 0)
    return true
end
function ExtendedSprayerEffects:initExtendedSprayerNozzleEffect(effectData)
    local spec_variableWorkWidth = self.spec_variableWorkWidth
    if spec_variableWorkWidth ~= nil and #spec_variableWorkWidth.sections > 0 then
        local minWidth = 1
        if #spec_variableWorkWidth.sectionNodes > 0 then
            local sectionNode = spec_variableWorkWidth.sectionNodes[1]
            minWidth = math.abs(sectionNode.startTransX or sectionNode.startTrans[1])
        end
        local sectionNode = effectData.xOffset or 0
        if sectionNode > 0 then
            effectData.sectionIndex = 0
            for _, section in ipairs(spec_variableWorkWidth.sectionsLeft) do
                if minWidth < sectionNode and sectionNode <= section.widthAbs then
                    effectData.sectionIndex = section.index
                    return
                end
            end
            return
        end
        effectData.sectionIndex = 0
        for _, section in ipairs(spec_variableWorkWidth.sectionsRight) do
            if sectionNode < -minWidth and section.widthAbs <= sectionNode then
                effectData.sectionIndex = section.index
                return
            end
        end
    end
end
function ExtendedSprayerEffects:updateExtendedSprayerNozzleEffectsState(sprayerEffects, useFullSection, dt, isTurnedOn, lastSpeed)
    local anyEffectActive = false
    for _, effectData in pairs(sprayerEffects) do
        local isActive, amountScale = self:updateExtendedSprayerNozzleEffectState(effectData, dt, isTurnedOn, lastSpeed)
        effectData.isDirty = isActive ~= effectData.isActive
        effectData.isActive = isActive
        if amountScale ~= effectData.amountScale then
            effectData.amountScale = amountScale
            self[ExtendedSprayerEffects.SPEC_TABLE_NAME].effectsDirty = true
        end
        if useFullSection and isActive then
            anyEffectActive = true
            break
        end
    end
    if useFullSection and anyEffectActive then
        for _, effectData in pairs(sprayerEffects) do
            if not effectData.isActive then
                effectData.isActive = true
                effectData.isDirty = true
            end
        end
    end
    for _, effectData in pairs(sprayerEffects) do
        if effectData.isDirty then
            effectData.isDirty = false
            spec.effectsDirty = true
            if effectData.isActive then
                if effectData.state ~= ShaderPlaneEffect.STATE_ON and effectData.state ~= ShaderPlaneEffect.STATE_TURNING_ON then
                    effectData.state = ShaderPlaneEffect.STATE_TURNING_ON
                    effectData.fadeDir = ExtendedSprayerEffects.EFFECT_DIRECTION_START
                    effectData.fadeCur[1] = -1
                    effectData.fadeCur[2] = 1
                end
            elseif effectData.state ~= ShaderPlaneEffect.STATE_OFF and effectData.state ~= ShaderPlaneEffect.STATE_TURNING_OFF then
                effectData.state = ShaderPlaneEffect.STATE_TURNING_OFF
                effectData.fadeDir = ExtendedSprayerEffects.EFFECT_DIRECTION_STOP
            end
            local isActive = spec.soundSamplesBySection[effectData.sectionIndex]
            if isActive ~= nil then
                local amountScale = g_soundManager:getIsSamplePlaying(isActive.spray)
                if effectData.isActive and not amountScale then
                    g_soundManager:playSample(isActive.spray)
                end
                if not effectData.isActive then
                    local anyOtherEffectActive = false
                    for sectionIndex, otherSampleData in pairs(spec.soundSamplesBySection) do
                        if otherSampleData ~= isActive and otherSampleData.spray == isActive.spray then
                            for _, otherEffect in pairs(spec.sprayerEffectsBySection[sectionIndex]) do
                                if otherEffect.isActive then
                                    anyOtherEffectActive = true
                                    break
                                end
                            end
                        end
                    end
                    if not anyOtherEffectActive and amountScale then
                        g_soundManager:stopSample(isActive.spray)
                    end
                end
            end
        end
    end
end
function ExtendedSprayerEffects:updateExtendedSprayerNozzleEffectState(effectData, _, isTurnedOn, lastSpeed)
    if effectData.sectionIndex ~= 0 and not self.spec_variableWorkWidth.sections[effectData.sectionIndex].isActive then
        return false, 1
    end
    if not self[ExtendedSprayerEffects.SPEC_TABLE_NAME].pwmEnabled then
        if (lastSpeed or 1) < 0.1 then
            isTurnedOn = false
        end
        return isTurnedOn, 1
    end
    local x, y, z = getWorldTranslation(effectData.effectNode)
    effectData.speed = MathUtil.vector3Length(x - effectData.lastWorldTranslation[1], y - effectData.lastWorldTranslation[2], z - effectData.lastWorldTranslation[3]) / (g_physicsDt * 0.001) * 3.6
    effectData.lastWorldTranslation[1] = x
    effectData.lastWorldTranslation[2] = y
    effectData.lastWorldTranslation[3] = z
    return isTurnedOn, math.min(effectData.speed / self.speedLimit, 1)
end
function ExtendedSprayerEffects:updateExtendedSprayerNozzleEffects(dt)
    local spec = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
    for _, effectData in pairs(spec.sprayerEffects) do
        if effectData.state == ShaderPlaneEffect.STATE_TURNING_ON or effectData.state == ShaderPlaneEffect.STATE_TURNING_OFF then
            effectData.fadeCur[1] = math.max(math.min(effectData.fadeCur[1] + effectData.fadeDir[1] * (dt / (spec.effectFadeTime * 1)), 1), -1)
            effectData.fadeCur[2] = math.max(math.min(effectData.fadeCur[2] + effectData.fadeDir[2] * (dt / (spec.effectFadeTime * 1)), 1), -1)
            setShaderParameter(effectData.effectNode, "fadeProgress", effectData.fadeCur[1], effectData.fadeCur[2], 0, 0, false)
            if effectData.state == ShaderPlaneEffect.STATE_TURNING_OFF then
                if effectData.fadeCur[1] == 1 and effectData.fadeCur[2] == -1 then
                    effectData.state = ShaderPlaneEffect.STATE_OFF
                end
            elseif effectData.state == ShaderPlaneEffect.STATE_TURNING_ON and (effectData.fadeCur[1] == 1 and effectData.fadeCur[2] == 1) then
                effectData.state = ShaderPlaneEffect.STATE_ON
            end
            spec.effectsDirty = true
        end
        if spec.pwmEnabled then
            local pauseTicks = 1 + math.max(math.floor((1 - effectData.amountScale) * 5), 0)
            setShaderParameter(effectData.effectNode, "blinkMulti", nil, pauseTicks, nil, nil, false)
        end
    end
end
function ExtendedSprayerEffects:getNumExtendedSprayerNozzleEffectsActive()
    local specEffects = self[ExtendedSprayerEffects.SPEC_TABLE_NAME]
    if not specEffects.hasCustomEffects then
        return 1, 1
    end
    local numActiveEffects = 0
    for _, effectData in pairs(specEffects.sprayerEffects) do
        if effectData.isActive then
        end
    end
    return numActiveEffects, numActiveEffects / specEffects.numCustomEffects
end
function ExtendedSprayerEffects:getAreEffectsVisible(superFunc)
    if self[ExtendedSprayerEffects.SPEC_TABLE_NAME].hasCustomEffects then
        return false
    else
        return superFunc(self)
    end
end