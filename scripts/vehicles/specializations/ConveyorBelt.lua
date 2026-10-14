ConveyorBelt = {}
function ConveyorBelt.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Dischargeable, specializations)
end
function ConveyorBelt.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ConveyorBelt")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.conveyorBelt.animationNodes")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.conveyorBelt.effects")
    schema:register(XMLValueType.INT, "vehicle.conveyorBelt#dischargeNodeIndex", "Discharge node index", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.conveyorBelt#startPercentage", "Start unloading percentage", 0.9)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.conveyorBelt.offset(?)#movingToolNode", "Moving tool node")
    schema:register(XMLValueType.INT, "vehicle.conveyorBelt.offset(?).effect(?)#index", "Index of effect", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.conveyorBelt.offset(?).effect(?)#minOffset", "Min. offset", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.conveyorBelt.offset(?).effect(?)#maxOffset", "Max. offset", 1)
    schema:register(XMLValueType.BOOL, "vehicle.conveyorBelt.offset(?).effect(?)#inverted", "Is inverted", false)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.conveyorBelt.sounds", "belt")
    schema:setXMLSpecializationType()
end
function ConveyorBelt.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getConveyorBeltFillLevel", ConveyorBelt.getConveyorBeltFillLevel)
    SpecializationUtil.registerFunction(vehicleType, "getConveyorBeltTargetObject", ConveyorBelt.getConveyorBeltTargetObject)
    SpecializationUtil.registerFunction(vehicleType, "getLoadTriggerMaxFillSpeed", ConveyorBelt.getLoadTriggerMaxFillSpeed)
end
function ConveyorBelt.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", ConveyorBelt.getDischargeNodeEmptyFactor)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeOnEmpty", ConveyorBelt.handleDischargeOnEmpty)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischarge", ConveyorBelt.handleDischarge)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnterable", ConveyorBelt.getIsEnterable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", ConveyorBelt.getFillUnitAllowsFillType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFreeCapacity", ConveyorBelt.getFillUnitFreeCapacity)
end
function ConveyorBelt.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ConveyorBelt)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ConveyorBelt)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ConveyorBelt)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ConveyorBelt)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ConveyorBelt)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ConveyorBelt)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", ConveyorBelt)
    SpecializationUtil.registerEventListener(vehicleType, "onMovingToolChanged", ConveyorBelt)
end
function ConveyorBelt:onLoad(_)
    local spec = self.spec_conveyorBelt
    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.conveyorBelt.animationNodes", self.components, self, self.i3dMappings)
        spec.samples = {}
        spec.samples.belt = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.conveyorBelt.sounds", "belt", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.conveyorBelt.effects", self.components, self, self.i3dMappings)
    spec.currentDelay = 0.0001
    table.sort(spec.effects, function(effect1, effect2)
        return effect1.startDelay < effect2.startDelay
    end)
    for _, effect in pairs(spec.effects) do
        if effect.planeFadeTime ~= nil then
            spec.currentDelay = spec.currentDelay + effect.planeFadeTime
        end
        if effect.setScrollUpdate ~= nil then
            effect:setScrollUpdate(false)
        end
    end
    spec.maxDelay = spec.currentDelay
    spec.morphStartPos = 0
    spec.morphEndPos = 0
    spec.isEffectDirty = true
    spec.emptyFactor = 1
    spec.scrollUpdateTime = 0
    spec.lastScrollUpdate = false
    spec.fillUnitIndex = 1
    spec.startFillLevel = 0
    spec.dischargeNodeIndex = self.xmlFile:getValue("vehicle.conveyorBelt#dischargeNodeIndex", 1)
    self:setCurrentDischargeNodeIndex(spec.dischargeNodeIndex)
    local dischargeNode = self:getDischargeNodeByIndex(spec.dischargeNodeIndex)
    if dischargeNode ~= nil then
        local capacity = self:getFillUnitCapacity(dischargeNode.fillUnitIndex)
        spec.fillUnitIndex = dischargeNode.fillUnitIndex
        spec.startFillLevel = capacity * self.xmlFile:getValue("vehicle.conveyorBelt#startPercentage", 0.9)
    end
    local capacity = 0
    while true do
        local key = string.format("vehicle.conveyorBelt.offset(%d)", capacity)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local _ = self.xmlFile:getValue(key .. "#movingToolNode", nil, self.components, self.i3dMappings)
        if _ == nil then
            Logging.xmlWarning(self.xmlFile, "Missing movingToolNode for conveyor offset \'%s\'!", key)
        else
            if spec.offsets == nil then
                spec.offsets = {}
            end
            local effect = {
                ["lastState"] = nil,
                ["movingToolNode"] = _,
                ["effects"] = {}
            }
            local j = 0
            while true do
                local effectKey = string.format(key .. ".effect(%d)", j)
                if not self.xmlFile:hasProperty(effectKey) then
                    break
                end
                local effectIndex = self.xmlFile:getValue(effectKey .. "#index", 0)
                local effect = spec.effects[effectIndex]
                if effect == nil or effect.setOffset == nil then
                    Logging.xmlWarning(self.xmlFile, "Effect index \'%d\' not found at \'%s\'!", effectIndex, effectKey)
                else
                    local entry = {
                        ["effect"] = effect,
                        ["minValue"] = self.xmlFile:getValue(effectKey .. "#minOffset", 0) * 1000,
                        ["maxValue"] = self.xmlFile:getValue(effectKey .. "#maxOffset", 1) * 1000,
                        ["inverted"] = self.xmlFile:getValue(effectKey .. "#inverted", false)
                    }
                    table.insert(effect.effects, entry)
                end
                j = j + 1
            end
            local effectIndex = spec.offsets
            table.insert(effectIndex, effect)
        end
        capacity = capacity + 1
    end
    spec.isFilling = false
    spec.isScrolling = false
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function ConveyorBelt:onPostLoad(_)
    local spec = self.spec_conveyorBelt
    if spec.offsets ~= nil then
        if self.getMovingToolByNode == nil then
            Logging.xmlError(self.xmlFile, "\'Cylindered\' specialization is required to use conveyorBelt offsets!")
            spec.offsets = nil
        else
            spec.movingToolToOffset = {}
            local i = #spec.offsets
            for i = i, 1, -1 do
                local offset = spec.offsets[i]
                local movingTool = self:getMovingToolByNode(offset.movingToolNode)
                if movingTool == nil then
                    Logging.xmlWarning(self.xmlFile, "No movingTool node \'%s\' defined for conveyor offset \'%d\'!", getName(offset.movingToolNode), i)
                    table.remove(spec.offsets, i)
                else
                    offset.movingTool = movingTool
                    spec.movingToolToOffset[movingTool] = offset
                    ConveyorBelt.onMovingToolChanged(self, movingTool, 0, 0)
                end
            end
            if #spec.offsets == 0 then
                spec.offsets = nil
                spec.movingToolToOffset = nil
                return
            end
        end
    end
end
function ConveyorBelt:onDelete()
    local spec = self.spec_conveyorBelt
    g_effectManager:deleteEffects(spec.effects)
    g_animationManager:deleteAnimations(spec.animationNodes)
    g_soundManager:deleteSamples(spec.samples)
end
function ConveyorBelt:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        local spec = self.spec_conveyorBelt
        spec.isFilling = streamReadBool(streamId)
        spec.isScrolling = streamReadBool(streamId)
    end
end
function ConveyorBelt:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_conveyorBelt
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
            streamWriteBool(streamId, spec.isFilling)
            streamWriteBool(streamId, spec.isScrolling)
        end
    end
end
function ConveyorBelt:onUpdateTick(dt, _, _, _)
    local spec = self.spec_conveyorBelt
    if not self.isServer then
        if spec.isFilling then
            spec.morphStartPos = 0
            spec.morphEndPos = math.max(spec.morphEndPos, self:getFillUnitFillLevelPercentage(spec.fillUnitIndex))
            spec.isEffectDirty = true
        end
        if spec.isScrolling then
            spec.scrollUpdateTime = 100
        end
    end
    local doScrollUpdate = spec.scrollUpdateTime > 0
    if doScrollUpdate ~= spec.lastScrollUpdate then
        if self.isClient then
            if doScrollUpdate then
                g_animationManager:startAnimations(spec.animationNodes)
                g_soundManager:playSample(spec.samples.belt)
            else
                g_animationManager:stopAnimations(spec.animationNodes)
                g_soundManager:stopSample(spec.samples.belt)
            end
            for _, effect in pairs(spec.effects) do
                if effect.setScrollUpdate ~= nil then
                    effect:setScrollUpdate(doScrollUpdate)
                end
            end
        end
        spec.lastScrollUpdate = doScrollUpdate
    end
    local fillFactor = spec.scrollUpdateTime - dt
    spec.scrollUpdateTime = math.max(fillFactor, 0)
    local isBeltActive = self:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF
    if isBeltActive then
        local fillFactor = self:getFillUnitFillLevelPercentage(spec.fillUnitIndex)
        if fillFactor > 0.0001 then
            local movedFactor = dt / spec.currentDelay
            local effect = spec.morphStartPos + movedFactor
            spec.morphStartPos = math.clamp(effect, 0, 1)
            local effect = spec.morphEndPos + movedFactor
            spec.morphEndPos = math.clamp(effect, 0, 1)
            local _ = spec.morphEndPos - spec.morphStartPos
            spec.emptyFactor = 1
            if fillFactor < _ then
                local effect = fillFactor / math.max(_, 0.001)
                spec.emptyFactor = math.clamp(effect, 0, 1)
            else
                local effect = fillFactor - _
                spec.offset = effect
                local effectStart = spec.morphStartPos - effect / math.max((1 - spec.morphStartPos) * spec.currentDelay, 0.001) * dt
                spec.morphStartPos = math.clamp(effectStart, 0, 1)
            end
            spec.isEffectDirty = true
            spec.scrollUpdateTime = dt * 3
        end
    end
    if doScrollUpdate then
        self:raiseActive()
    end
    if self.isClient and spec.isEffectDirty then
        for effect, effect in pairs(spec.effects) do
            if effect.setMorphPosition ~= nil then
                local effectStart = effect.startDelay / spec.currentDelay
                local effectEnd = (effect.startDelay + effect.planeFadeTime - effect.offset) / spec.currentDelay
                local offsetFactor = effect.offset / effect.planeFadeTime
                local startMorph = math.clamp(offsetFactor + (spec.morphStartPos - effectStart) / (effectEnd - effectStart) * (1 - offsetFactor), offsetFactor, 1)
                effect:setMorphPosition(startMorph, (math.clamp(offsetFactor + (spec.morphEndPos - effectStart) / (effectEnd - effectStart) * (1 - offsetFactor), offsetFactor, 1)))
            end
        end
        spec.isEffectDirty = false
    end
end
function ConveyorBelt:getConveyorBeltFillLevel()
    local fillLevel = self:getFillUnitFillLevel(self.spec_conveyorBelt.fillUnitIndex)
    if self.getCurrentDischargeNode ~= nil then
        local object = self:getCurrentDischargeNode().dischargeHitObject
        if object ~= nil and object.getConveyorBeltFillLevel ~= nil then
            fillLevel = fillLevel + object:getConveyorBeltFillLevel()
        end
    end
    return fillLevel
end
function ConveyorBelt:getConveyorBeltTargetObject()
    if self.getCurrentDischargeNode ~= nil then
        local currentDischargeNode = self:getCurrentDischargeNode()
        local object = currentDischargeNode.dischargeHitObject
        if object ~= nil then
            if object.getConveyorBeltTargetObject == nil then
                return object, currentDischargeNode.dischargeHitObjectUnitIndex
            else
                return object:getConveyorBeltTargetObject()
            end
        end
    end
    return nil
end
function ConveyorBelt:getLoadTriggerMaxFillSpeed()
    local maxSpeed = math.huge
    if self.getCurrentDischargeNode ~= nil then
        local currentDischargeNode = self:getCurrentDischargeNode()
        maxSpeed = currentDischargeNode.emptySpeed
        local object = currentDischargeNode.dischargeHitObject
        if object ~= nil and object.getLoadTriggerMaxFillSpeed ~= nil then
            maxSpeed = math.min(object:getLoadTriggerMaxFillSpeed(), maxSpeed)
        end
    end
    return maxSpeed
end
function ConveyorBelt:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
    local spec = self.spec_conveyorBelt
    local parentFactor = superFunc(self, dischargeNode)
    if spec.dischargeNodeIndex == dischargeNode.index then
        return spec.morphEndPos ~= 1 and 0 or spec.emptyFactor
    else
        return parentFactor
    end
end
function ConveyorBelt:handleDischargeOnEmpty(superFunc, dischargeNode)
    if dischargeNode.index ~= self.spec_conveyorBelt.dischargeNodeIndex then
        superFunc(self, dischargeNode)
    end
end
function ConveyorBelt:handleDischarge(superFunc, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
    if dischargeNode.index ~= self.spec_conveyorBelt.dischargeNodeIndex then
        superFunc(self, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
    end
end
function ConveyorBelt:getIsEnterable(superFunc)
    if self.getAttacherVehicle ~= nil then
        if self:getAttacherVehicle() ~= nil then
            ::l3::
            return false
        end
    end
    local v10_ = superFunc(self)
    goto l3
end
function ConveyorBelt.getHasConveyorBeltLoop(rootVehicle, vehicle, fillUnitIndex)
    if vehicle.getCurrentDischargeNode ~= nil then
        local currentDischargeNode = vehicle:getCurrentDischargeNode()
        if currentDischargeNode.fillUnitIndex == fillUnitIndex then
            local object = currentDischargeNode.dischargeHitObject
            local targetFillUnitIndex = currentDischargeNode.dischargeHitObjectUnitIndex
            if object ~= nil and (object.spec_conveyorBelt ~= nil and targetFillUnitIndex ~= nil) then
                return object == rootVehicle and true or ConveyorBelt.getHasConveyorBeltLoop(rootVehicle, object, targetFillUnitIndex)
            end
        end
    end
    return false
end
function ConveyorBelt:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillType)
    if not superFunc(self, fillUnitIndex, fillType) then
        return false
    end
    if not ConveyorBelt.getHasConveyorBeltLoop(self, self, fillUnitIndex) and self.getCurrentDischargeNode ~= nil then
        local currentDischargeNode = self:getCurrentDischargeNode()
        if currentDischargeNode.fillUnitIndex == fillUnitIndex then
            local object = currentDischargeNode.dischargeHitObject
            local targetFillUnitIndex = currentDischargeNode.dischargeHitObjectUnitIndex
            if object ~= nil and (object.getFillUnitAllowsFillType ~= nil and targetFillUnitIndex ~= nil) then
                if currentDischargeNode.fillTypeConverter ~= nil then
                    local conversion = currentDischargeNode.fillTypeConverter[fillType]
                    if conversion ~= nil and object:getFillUnitAllowsFillType(targetFillUnitIndex, conversion.targetFillTypeIndex) then
                        return true
                    end
                end
                return object:getFillUnitAllowsFillType(targetFillUnitIndex, fillType)
            end
        end
    end
    return true
end
function ConveyorBelt:getFillUnitFreeCapacity(superFunc, fillUnitIndex, fillTypeIndex, farmId)
    local freeCapacity = superFunc(self, fillUnitIndex, fillTypeIndex, farmId)
    if not ConveyorBelt.getHasConveyorBeltLoop(self, self, fillUnitIndex) and self.getCurrentDischargeNode ~= nil then
        local currentDischargeNode = self:getCurrentDischargeNode()
        if currentDischargeNode.fillUnitIndex == fillUnitIndex then
            local object = currentDischargeNode.dischargeHitObject
            local targetFillUnitIndex = currentDischargeNode.dischargeHitObjectUnitIndex
            if object ~= nil and (object.getFillUnitFreeCapacity ~= nil and targetFillUnitIndex ~= nil) then
                return freeCapacity + object:getFillUnitFreeCapacity(targetFillUnitIndex, fillTypeIndex, farmId)
            end
        end
    end
    return freeCapacity
end
function ConveyorBelt:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, _, _, _)
    local spec = self.spec_conveyorBelt
    if spec.fillUnitIndex == fillUnitIndex then
        local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)
        if self.isServer then
            local isFilling = false
            local isScrolling = false
            if fillLevelDelta > 0 then
                spec.morphStartPos = 0
                local effect = fillLevel / self:getFillUnitCapacity(fillUnitIndex)
                spec.morphEndPos = math.max(spec.morphEndPos, effect)
                spec.isEffectDirty = true
                isFilling = true
            end
            if fillLevelDelta ~= 0 then
                spec.scrollUpdateTime = 100
                isScrolling = true
            end
            if isFilling ~= spec.isFilling or isScrolling ~= spec.isScrolling then
                spec.isFilling = isFilling
                spec.isScrolling = isScrolling
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
        end
        if fillLevel == 0 then
            g_effectManager:stopEffects(spec.effects)
            spec.morphStartPos = 0
            spec.morphEndPos = 0
            spec.isEffectDirty = true
            return
        end
        g_effectManager:setEffectTypeInfo(spec.effects, fillType)
        for _, effect in pairs(spec.effects) do
            g_effectManager:startEffect(effect, true)
        end
    end
end
function ConveyorBelt:onMovingToolChanged(movingTool, _, _)
    local spec = self.spec_conveyorBelt
    if spec.offsets ~= nil and spec.movingToolToOffset ~= nil then
        local offset = spec.movingToolToOffset[movingTool]
        if offset ~= nil then
            local state = Cylindered.getMovingToolState(self, movingTool)
            if state ~= offset.lastState then
                local updateDelay = false
                for _, entry in pairs(offset.effects) do
                    local effectState
                    if entry.inverted then
                        effectState = 1 - state
                    else
                        effectState = state
                    end
                    entry.effect:setOffset(MathUtil.lerp(entry.minValue, entry.maxValue, effectState))
                    updateDelay = true
                    spec.isEffectDirty = true
                end
                if updateDelay then
                    spec.currentDelay = 0
                    for _, entry in pairs(spec.effects) do
                        if entry.planeFadeTime ~= nil then
                            spec.currentDelay = spec.currentDelay + entry.planeFadeTime - entry.offset
                        end
                    end
                end
                offset.lastState = state
            end
        end
    end
end
function ConveyorBelt:updateDebugValues(values)
    local spec = self.spec_conveyorBelt
    table.insert(values, {
        ["name"] = "fillFactor",
        ["value"] = self:getFillUnitFillLevelPercentage(spec.fillUnitIndex)
    })
    table.insert(values, {
        ["name"] = "visualFactor",
        ["value"] = spec.morphEndPos - spec.morphStartPos
    })
    table.insert(values, {
        ["name"] = "currentDelay",
        ["value"] = spec.currentDelay
    })
    table.insert(values, {
        ["name"] = "offset",
        ["value"] = spec.offset
    })
    table.insert(values, {
        ["name"] = "morphStartPos",
        ["value"] = spec.morphStartPos
    })
    table.insert(values, {
        ["name"] = "morphEndPos",
        ["value"] = spec.morphEndPos
    })
end