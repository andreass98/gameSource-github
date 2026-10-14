VinePrepruner = {}
VinePrepruner.PRUNER_NODE_XML_KEY = "vehicle.vinePrepruner.prunerNode(?)"
function VinePrepruner.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("VinePrepruner")
    schema:register(XMLValueType.STRING, "vehicle.vinePrepruner#fruitType", "Fruit type")
    local nodeKey = VinePrepruner.PRUNER_NODE_XML_KEY
    schema:register(XMLValueType.NODE_INDEX, nodeKey .. "#node", "Pruner node that adjusts translation depending on raycast distance")
    schema:register(XMLValueType.FLOAT, nodeKey .. "#offset", "Offset from raycast node to center of pruning unit", 0.5)
    schema:register(XMLValueType.INT, nodeKey .. "#axis", "Move axis", 1)
    schema:register(XMLValueType.INT, nodeKey .. "#direction", "Translation direction", 1)
    schema:register(XMLValueType.FLOAT, nodeKey .. "#transMin", "Min. translation", 0)
    schema:register(XMLValueType.FLOAT, nodeKey .. "#transMax", "Max. translation", 1)
    schema:register(XMLValueType.FLOAT, nodeKey .. "#transSpeed", "Translation speed (m/sec)", 0.5)
    schema:register(XMLValueType.INT, nodeKey .. "#numBits", "Number of bits to sync state in multiplayer", 8)
    schema:register(XMLValueType.STRING, "vehicle.vinePrepruner.poleAnimation#name", "Name of pole animation (will be triggered as soon as pole has been detected)")
    schema:register(XMLValueType.FLOAT, "vehicle.vinePrepruner.poleAnimation#speedScale", "Animation speed scale", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.vinePrepruner.poleAnimation#poleThreshold", "Defines when the pole is detected as percentage of segment length", 0.1)
    EffectManager.registerEffectXMLPaths(schema, "vehicle.vinePrepruner.effect")
    schema:setXMLSpecializationType()
end
function VinePrepruner.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(VineDetector, specializations)
end
function VinePrepruner.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadPreprunerNodeFromXML", VinePrepruner.loadPreprunerNodeFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsPreprunerNodeActive", VinePrepruner.getIsPreprunerNodeActive)
end
function VinePrepruner.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", VinePrepruner.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartVineDetection", VinePrepruner.getCanStartVineDetection)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsValidVinePlaceable", VinePrepruner.getIsValidVinePlaceable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleVinePlaceable", VinePrepruner.handleVinePlaceable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementUseVineSegment", VinePrepruner.getAIImplementUseVineSegment)
end
function VinePrepruner.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", VinePrepruner)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", VinePrepruner)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", VinePrepruner)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", VinePrepruner)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", VinePrepruner)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", VinePrepruner)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", VinePrepruner)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", VinePrepruner)
    SpecializationUtil.registerEventListener(vehicleType, "onAnimationPartChanged", VinePrepruner)
end
function VinePrepruner:onLoad(_)
    local spec = self.spec_vinePrepruner
    local fruitTypeName = self.xmlFile:getValue("vehicle.vinePrepruner#fruitType")
    local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
    if fruitType == nil then
        spec.fruitTypeIndex = FruitType.GRAPE
    else
        spec.fruitTypeIndex = fruitType.index
    end
    spec.prunerNodes = {}
    self.xmlFile:iterate("vehicle.vinePrepruner.prunerNode", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {}
        if self:loadPreprunerNodeFromXML(self.xmlFile, key, entry) then
            table.insert(spec.prunerNodes, entry)
        end
    end)
    spec.poleAnimation = {}
    spec.poleAnimation.name = self.xmlFile:getValue("vehicle.vinePrepruner.poleAnimation#name")
    spec.poleAnimation.speedScale = self.xmlFile:getValue("vehicle.vinePrepruner.poleAnimation#speedScale", 1)
    spec.poleAnimation.poleThreshold = 1 - self.xmlFile:getValue("vehicle.vinePrepruner.poleAnimation#poleThreshold", 0.1)
    spec.lastWorkTime = -10000
    spec.effectState = false
    if self.isClient then
        spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.vinePrepruner.effect", self.components, self, self.i3dMappings)
    end
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function VinePrepruner:onDelete()
    g_effectManager:deleteEffects(self.spec_vinePrepruner.effects)
end
function VinePrepruner:onReadStream(streamId, _)
    VinePrepruner.readPrePrunerFromStream(self, streamId, true)
end
function VinePrepruner:onWriteStream(streamId, _)
    VinePrepruner.writePrePrunerToStream(self, streamId)
end
function VinePrepruner:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        VinePrepruner.readPrePrunerFromStream(self, streamId)
    end
end
function VinePrepruner:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spec_vinePrepruner.dirtyFlag) ~= 0) then
            VinePrepruner.writePrePrunerToStream(self, streamId)
        end
    end
end
function VinePrepruner:readPrePrunerFromStream(streamId, forceState)
    local spec = self.spec_vinePrepruner
    local i = 1
    local effectState = #spec.prunerNodes
    for i = i, effectState do
        local prunerNode = spec.prunerNodes[i]
        prunerNode.transTarget = streamReadUIntN(streamId, prunerNode.numBits) / (2 ^ prunerNode.numBits - 1) * (prunerNode.transMax - prunerNode.transMin) + prunerNode.transMin
        if forceState then
            prunerNode.curTrans[prunerNode.axis] = prunerNode.transTarget
            setTranslation(prunerNode.node, prunerNode.curTrans[1], prunerNode.curTrans[2], prunerNode.curTrans[3])
        end
    end
    local effectState = streamReadBool(streamId)
    if effectState ~= spec.effectState then
        spec.effectState = effectState
        if effectState then
            g_effectManager:setEffectTypeInfo(spec.effects, nil, spec.fruitTypeIndex, nil)
            g_effectManager:startEffects(spec.effects)
            return
        end
        g_effectManager:stopEffects(spec.effects)
    end
end
function VinePrepruner:writePrePrunerToStream(streamId)
    local spec = self.spec_vinePrepruner
    local i = 1
    for i = i, #spec.prunerNodes do
        local prunerNode = spec.prunerNodes[i]
        streamWriteUIntN(streamId, (prunerNode.transTarget - prunerNode.transMin) / (prunerNode.transMax - prunerNode.transMin) * (2 ^ prunerNode.numBits - 1), prunerNode.numBits)
    end
    streamWriteBool(streamId, spec.effectState)
end
function VinePrepruner:onUpdate(dt, _, _, _)
    local spec = self.spec_vinePrepruner
    local i = 1
    local effectState = #spec.prunerNodes
    for i = i, effectState do
        local prunerNode = spec.prunerNodes[i]
        if self:getIsPreprunerNodeActive(prunerNode) then
            local curTrans = prunerNode.curTrans[prunerNode.axis]
            if prunerNode.transTarget ~= curTrans then
                local moveDirection = math.sign(prunerNode.transTarget - curTrans)
                prunerNode.curTrans[prunerNode.axis] = (moveDirection >= 0 and math.min or math.max)(curTrans + prunerNode.transSpeed * dt * moveDirection, prunerNode.transTarget)
                setTranslation(prunerNode.node, prunerNode.curTrans[1], prunerNode.curTrans[2], prunerNode.curTrans[3])
            end
        end
    end
    if self.isServer then
        local effectState = spec.lastWorkTime + 1000 > g_time
        if effectState ~= spec.effectState then
            spec.effectState = effectState
            if self.isClient then
                if effectState then
                    g_effectManager:setEffectTypeInfo(spec.effects, nil, spec.fruitTypeIndex, nil)
                    g_effectManager:startEffects(spec.effects)
                else
                    g_effectManager:stopEffects(spec.effects)
                end
            end
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    end
end
function VinePrepruner:onTurnedOff()
    self:cancelVineDetection()
end
function VinePrepruner:onAnimationPartChanged(node)
    local spec = self.spec_vinePrepruner
    local i = 1
    for i = i, #spec.prunerNodes do
        local prunerNode = spec.prunerNodes[i]
        if prunerNode.node == node then
            prunerNode.curTrans[1], prunerNode.curTrans[2], prunerNode.curTrans[3] = getTranslation(prunerNode.node)
        end
    end
end
function VinePrepruner:loadPreprunerNodeFromXML(_, key, prunerNode)
    prunerNode.node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    if prunerNode.node == nil then
        return false
    end
    prunerNode.offset = self.xmlFile:getValue(key .. "#offset", 0.5)
    prunerNode.axis = self.xmlFile:getValue(key .. "#axis", 1)
    prunerNode.direction = self.xmlFile:getValue(key .. "#direction", 1)
    prunerNode.transMin = self.xmlFile:getValue(key .. "#transMin", 0)
    prunerNode.transMax = self.xmlFile:getValue(key .. "#transMax", 1)
    prunerNode.transSpeed = self.xmlFile:getValue(key .. "#transSpeed", 0.5) / 1000
    prunerNode.curTrans = { getTranslation(prunerNode.node) }
    prunerNode.transTarget = prunerNode.curTrans[prunerNode.axis]
    prunerNode.numBits = self.xmlFile:getValue(key .. "#numBits", 8)
    return true
end
function VinePrepruner:getIsPreprunerNodeActive(prunerNode)
    return true
end
function VinePrepruner:getCanStartVineDetection(superFunc)
    if superFunc(self) then
        if self:getIsTurnedOn() then
            return self.movingDirection ~= 0
        else
            return false
        end
    else
        return false
    end
end
function VinePrepruner:getIsValidVinePlaceable(superFunc, placeable)
    if not superFunc(self, placeable) then
        return false
    end
    return placeable:getVineFruitType() == self.spec_vinePrepruner.fruitTypeIndex
end
function VinePrepruner:handleVinePlaceable(superFunc, node, placeable, x, y, z, distance)
    if not superFunc(self, node, placeable, x, y, z, distance) then
        return false
    end
    if placeable == nil then
        return false
    end
    local spec = self.spec_vinePrepruner
    local startPosX, startPosY, startPosZ = self:getFirstVineHitPosition()
    local currentPosX, currentPosY, currentPosZ = self:getCurrentVineHitPosition()
    if placeable:prepareVine(node, startPosX, startPosY, startPosZ, currentPosX, currentPosY, currentPosZ) > 0 then
        spec.lastWorkTime = g_time
    end
    if spec.poleAnimation.name ~= nil then
        local _, _, localStartZ = worldToLocal(node, startPosX, startPosY, startPosZ)
        local _, _, localCurrentZ = worldToLocal(node, currentPosX, currentPosY, currentPosZ)
        local direction = math.sign(localCurrentZ - localStartZ) >= 0 and 1 or -1
        local posPercentage = localCurrentZ / placeable:getPanelLength()
        if direction < 0 then
        end
        if not self:getIsAnimationPlaying(spec.poleAnimation.name) then
            if spec.poleAnimation.poleThreshold < posPercentage then
                if self:getAnimationTime(spec.poleAnimation.name) < 0.5 then
                    self:playAnimation(spec.poleAnimation.name, spec.poleAnimation.speedScale)
                end
            elseif self:getAnimationTime(spec.poleAnimation.name) > 0.5 then
                self:playAnimation(spec.poleAnimation.name, -spec.poleAnimation.speedScale)
            end
        end
    end
    local localStartZ = 1
    local _ = #spec.prunerNodes
    local _ = 1
    for localStartZ = localStartZ, _, _ do
        local _ = spec.prunerNodes[localStartZ]
        _.transTarget = math.clamp((distance - _.offset) * _.direction, _.transMin, _.transMax)
        self:raiseDirtyFlags(spec.dirtyFlag)
    end
    return true
end
function VinePrepruner:getAIImplementUseVineSegment(_, placeable, segment, segmentSide)
    if segmentSide >= 0 then
        return placeable:getHasSegmentTargetGrowthState(segment, self.spec_vinePrepruner.fruitTypeIndex, false, true)
    else
        return false
    end
end
function VinePrepruner:doCheckSpeedLimit(superFunc)
    return superFunc(self) or self:getIsTurnedOn()
end
function VinePrepruner.getDefaultSpeedLimit()
    return 5
end