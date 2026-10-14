StumpCutter = {}
StumpCutter.CLIENT_DM_UPDATE_RADIUS = 50
function StumpCutter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function StumpCutter.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("stumpCutter", true, false, false)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("StumpCutter")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.stumpCutter.cutNode(?)#node", "Cut node")
    schema:register(XMLValueType.FLOAT, "vehicle.stumpCutter.cutNode(?)#cutSizeY", "Cut size Y", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.stumpCutter.cutNode(?)#cutSizeZ", "Cut size X", 1)
    schema:register(XMLValueType.TIME, "vehicle.stumpCutter.cutNode(?)#maxCutTime", "Time until cut", 4)
    schema:register(XMLValueType.TIME, "vehicle.stumpCutter.cutNode(?)#maxResetCutTime", "Time between cuts", 4)
    schema:register(XMLValueType.FLOAT, "vehicle.stumpCutter.cutNode(?)#cutFullTreeThreshold", "If the tree length below the cut node is smaller than this value it gets removed", 0.4)
    schema:register(XMLValueType.FLOAT, "vehicle.stumpCutter.cutNode(?)#cutPartThreshold", "Cut part threshold", 0.2)
    schema:register(XMLValueType.INT, "vehicle.stumpCutter.cutNode(?)#workAreaIndex", "Work area index")
    schema:register(XMLValueType.TIME, "vehicle.stumpCutter.cutNode(?)#cutDuration", "Cut duration", 1)
    EffectManager.registerEffectXMLPaths(schema, "vehicle.stumpCutter.cutNode(?).effects")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.stumpCutter.sounds", "start")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.stumpCutter.sounds", "stop")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.stumpCutter.sounds", "idle")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.stumpCutter.sounds", "work")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.stumpCutter.effects")
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.stumpCutter.animationNodes")
    schema:setXMLSpecializationType()
end
function StumpCutter.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "crushSplitShape", StumpCutter.crushSplitShape)
    SpecializationUtil.registerFunction(vehicleType, "stumpCutterSplitShapeCallback", StumpCutter.stumpCutterSplitShapeCallback)
    SpecializationUtil.registerFunction(vehicleType, "processStumpCutterArea", StumpCutter.processStumpCutterArea)
end
function StumpCutter.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", StumpCutter.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", StumpCutter.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCultivatorLimitToField", StumpCutter.getCultivatorLimitToField)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPlowLimitToField", StumpCutter.getPlowLimitToField)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPlowForceLimitToField", StumpCutter.getPlowForceLimitToField)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", StumpCutter.getConsumingLoad)
end
function StumpCutter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", StumpCutter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", StumpCutter)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", StumpCutter)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", StumpCutter)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", StumpCutter)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", StumpCutter)
end
function StumpCutter:onLoad(_)
    local spec = self.spec_stumpCutter
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode", "vehicle.stumpCutter.animationNodes.animationNode", "stumbCutter")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutterStartSound", "vehicle.stumpCutter.sounds.start")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutterIdleSound", "vehicle.stumpCutter.sounds.idle")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutterWorkSound", "vehicle.stumpCutter.sounds.work")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutterStopSound", "vehicle.stumpCutter.sounds.stop")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter.emitterShape(0)", "vehicle.stumpCutter.effects.effectNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter.particleSystem(0)", "vehicle.stumpCutter.effects.effectNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter#cutNode", "vehicle.stumpCutter.cutNode#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter#cutSizeY", "vehicle.stumpCutter.cutNode#cutSizeY")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter#cutSizeZ", "vehicle.stumpCutter.cutNode#cutSizeZ")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter#cutFullTreeThreshold", "vehicle.stumpCutter.cutNode#cutFullTreeThreshold")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.stumpCutter#cutPartThreshold", "vehicle.stumpCutter.cutNode#cutPartThreshold")
    spec.cutNodes = {}
    spec.currentCutNodeIndex = 1
    local i = 0
    while true do
        local key = string.format("%s.cutNode(%d)", "vehicle.stumpCutter", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        if node == nil then
            Logging.xmlWarning(self.xmlFile, "Missing \'node\' for \'%s\'!", key)
            break
        end
        local cutNode = {
            ["node"] = node,
            ["cutSizeY"] = self.xmlFile:getValue(key .. "#cutSizeY", 1),
            ["cutSizeZ"] = self.xmlFile:getValue(key .. "#cutSizeZ", 1),
            ["maxCutTime"] = self.xmlFile:getValue(key .. "#maxCutTime", 4)
        }
        cutNode.nextCutTime = cutNode.maxCutTime
        cutNode.maxResetCutTime = self.xmlFile:getValue(key .. "#maxResetCutTime", 1)
        cutNode.resetCutTime = cutNode.maxResetCutTime
        cutNode.cutFullTreeThreshold = self.xmlFile:getValue(key .. "#cutFullTreeThreshold", 0.4)
        cutNode.cutPartThreshold = self.xmlFile:getValue(key .. "#cutPartThreshold", 0.2)
        cutNode.workAreaIndex = self.xmlFile:getValue(key .. "#workAreaIndex")
        cutNode.workTimer = 0
        cutNode.workDuration = self.xmlFile:getValue(key .. "#cutDuration", 1)
        cutNode.lastWorkTime = -1000
        cutNode.workFadeTime = 0
        cutNode.maxWorkFadeTime = 1000
        if self.isClient then
            cutNode.effects = g_effectManager:loadEffect(self.xmlFile, key .. ".effects", self.components, self, self.i3dMappings)
        end
        table.insert(spec.cutNodes, cutNode)
        i = i + 1
    end
    if self.isClient then
        spec.samples = {}
        spec.samples.start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stumpCutter.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.stop = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stumpCutter.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.idle = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stumpCutter.sounds", "idle", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stumpCutter.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.maxWorkFadeTime = 1000
        spec.workFadeTime = 0
        spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.stumpCutter.effects", self.components, self, self.i3dMappings)
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.stumpCutter.animationNodes", self.components, self, self.i3dMappings)
    end
end
function StumpCutter:onDelete()
    local spec = self.spec_stumpCutter
    g_soundManager:deleteSamples(spec.samples)
    g_animationManager:deleteAnimations(spec.animationNodes)
    g_effectManager:deleteEffects(spec.effects)
    if spec.cutNodes ~= nil then
        local i = 1
        for i = i, #spec.cutNodes do
            g_effectManager:deleteEffects(spec.cutNodes[i].effects)
        end
    end
end
function StumpCutter:onUpdateTick(dt, _, _, _)
    if self:getIsTurnedOn() then
        local spec = self.spec_stumpCutter
        local numCutNodes = #spec.cutNodes
        if numCutNodes > 0 then
            local nextCutNodeIndex = spec.currentCutNodeIndex + 1
            local nextCutNodeIndex = numCutNodes < nextCutNodeIndex and 1 or nextCutNodeIndex
            spec.currentCutNodeIndex = nextCutNodeIndex
            local cutNode = spec.cutNodes[nextCutNodeIndex]
            cutNode.curLenAbove = 0
            cutNode.curLenBelow = 0
            local x, y, z = getWorldTranslation(cutNode.node)
            local nx, ny, nz = localDirectionToWorld(cutNode.node, 1, 0, 0)
            local yx, yy, yz = localDirectionToWorld(cutNode.node, 0, 1, 0)
            if cutNode.curSplitShape ~= nil and (not entityExists(cutNode.curSplitShape) or testSplitShape(cutNode.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, cutNode.cutSizeY, cutNode.cutSizeZ) == nil) then
                cutNode.curSplitShape = nil
            end
            if cutNode.curSplitShape == nil then
                local shape, _, _, _, _ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, cutNode.cutSizeY, cutNode.cutSizeZ)
                if shape ~= 0 then
                    cutNode.curSplitShape = shape
                end
            end
            if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
                local shape, _, _ = localToWorld(cutNode.node, 0, 0, cutNode.cutSizeZ)
                local _, _, z2 = localToWorld(cutNode.node, 0, cutNode.cutSizeY, 0)
                DebugPlane.renderWithPositions(x, y, z, shape, _, _, _, _, z2, Color.PRESETS.PINK, false)
            end
            if cutNode.curSplitShape == nil then
                cutNode.workFadeTime = math.max(0, cutNode.workFadeTime - dt)
                if self.isServer and cutNode.resetCutTime > 0 then
                    cutNode.resetCutTime = cutNode.resetCutTime - dt
                    if cutNode.resetCutTime <= 0 then
                        cutNode.nextCutTime = cutNode.maxCutTime
                    end
                end
            else
                local shape, _ = getSplitShapePlaneExtents(cutNode.curSplitShape, x, y, z, nx, ny, nz)
                if cutNode.cutPartThreshold <= _ then
                    cutNode.lastWorkTime = g_time
                end
                local _ = cutNode.maxWorkFadeTime
                local _ = cutNode.workFadeTime + dt * numCutNodes
                cutNode.workFadeTime = math.min(_, _)
                if self.isServer then
                    cutNode.resetCutTime = cutNode.maxResetCutTime
                    if cutNode.nextCutTime > 0 then
                        cutNode.nextCutTime = cutNode.nextCutTime - dt
                        if cutNode.nextCutTime <= 0 then
                            local _, _, _ = worldToLocal(cutNode.curSplitShape, x, y, z)
                            if (shape <= cutNode.cutFullTreeThreshold or _ < cutNode.cutPartThreshold + 0.01) and _ < 1 then
                                self:crushSplitShape(cutNode.curSplitShape)
                                cutNode.curSplitShape = nil
                            elseif cutNode.cutPartThreshold <= _ and cutNode.cutPartThreshold <= shape then
                                cutNode.nextCutTime = cutNode.maxCutTime
                                local z2 = cutNode.curSplitShape
                                cutNode.curSplitShape = nil
                                cutNode.curLenAbove = _
                                cutNode.curLenBelow = shape
                                self.shapeBeingCut = z2
                                splitShape(z2, x, y, z, nx, ny, nz, yx, yy, yz, cutNode.cutSizeY, cutNode.cutSizeZ, "stumpCutterSplitShapeCallback", self)
                                g_treePlantManager:removingSplitShape(z2)
                            else
                                cutNode.curSplitShape = nil
                                cutNode.nextCutTime = cutNode.maxCutTime
                            end
                        end
                    end
                end
            end
            if self.isClient then
                if cutNode.lastWorkTime + 500 > g_time then
                    g_effectManager:setEffectTypeInfo(cutNode.effects, FillType.WOODCHIPS)
                    g_effectManager:startEffects(cutNode.effects)
                else
                    g_effectManager:stopEffects(cutNode.effects)
                end
                local shape = false
                local _ = 1
                local _ = #spec.cutNodes
                local _ = 1
                for _ = _, _, _ do
                    if spec.cutNodes[_].lastWorkTime + 500 > g_time then
                        shape = true
                        break
                    end
                end
                if shape then
                    g_effectManager:setEffectTypeInfo(spec.effects, FillType.WOODCHIPS)
                    g_effectManager:startEffects(spec.effects)
                    if not g_soundManager:getIsSamplePlaying(spec.samples.work) then
                        g_soundManager:playSample(spec.samples.work)
                        return
                    end
                else
                    g_effectManager:stopEffects(spec.effects)
                    if g_soundManager:getIsSamplePlaying(spec.samples.work) then
                        g_soundManager:stopSample(spec.samples.work)
                    end
                end
            end
        end
    end
end
function StumpCutter:onDeactivate()
    if self.isClient then
        local spec = self.spec_stumpCutter
        g_effectManager:stopEffects(spec.effects)
        local i = 1
        for i = i, #spec.cutNodes do
            g_effectManager:stopEffects(spec.cutNodes[i].effects)
        end
    end
end
function StumpCutter:onTurnedOn()
    if self.isClient then
        local spec = self.spec_stumpCutter
        g_soundManager:stopSamples(spec.samples)
        g_soundManager:playSample(spec.samples.start)
        g_soundManager:playSample(spec.samples.idle, 0, spec.samples.start)
        g_animationManager:startAnimations(spec.animationNodes)
    end
end
function StumpCutter:onTurnedOff()
    if self.isClient then
        local spec = self.spec_stumpCutter
        spec.workFadeTime = 0
        g_effectManager:stopEffects(spec.effects)
        local i = 1
        for i = i, #spec.cutNodes do
            g_effectManager:stopEffects(spec.cutNodes[i].effects)
        end
        g_soundManager:stopSamples(spec.samples)
        g_soundManager:playSample(spec.samples.stop)
        g_animationManager:stopAnimations(spec.animationNodes)
    end
end
function StumpCutter:crushSplitShape(shape)
    if self.isServer then
        local x, _, z = getWorldTranslation(shape)
        delete(shape)
        g_densityMapHeightManager:setCollisionMapAreaDirty(x - 10, z - 10, x + 10, z + 10, true)
        g_currentMission.aiSystem:setAreaDirty(x - 10, x + 10, z - 10, z + 10)
    end
end
function StumpCutter:stumpCutterSplitShapeCallback(shape, isBelow, _, minY, maxY, minZ, maxZ)
    local spec = self.spec_stumpCutter
    if isBelow then
        local _, y, _ = localToWorld(spec.cutNodes[spec.currentCutNodeIndex].node, -0.05, minY + (maxY - minY) / 2, minZ + (maxZ - minZ) / 2)
        if y < getTerrainHeightAtWorldPos(g_terrainNode, getWorldTranslation(cutNode.node)) then
            self:crushSplitShape(shape)
        else
            spec.curSplitShape = shape
            g_treePlantManager:addingSplitShape(shape, self.shapeBeingCut)
        end
    elseif cutNode.curLenAbove < 1 then
        self:crushSplitShape(shape)
    else
        g_treePlantManager:addingSplitShape(shape, self.shapeBeingCut)
    end
end
function StumpCutter:processStumpCutterArea(workArea, _)
    if not self.isServer and self.currentUpdateDistance > StumpCutter.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local area = 0
    local totalArea = 0
    for _, cutNode in ipairs(self.spec_stumpCutter.cutNodes) do
        if cutNode.workAreaIndex == workArea.index then
            local xs, _, zs = getWorldTranslation(workArea.start)
            local xw, _, zw = getWorldTranslation(workArea.width)
            local xh, _, zh = getWorldTranslation(workArea.height)
            local _area, _totalArea, nonMowableCut = FSDensityMapUtil.clearDecoArea(xs, zs, xw, zw, xh, zh)
            if _area > 0 and nonMowableCut then
                cutNode.lastWorkTime = g_time
            end
        end
    end
    return area, totalArea
end
function StumpCutter:getDirtMultiplier(superFunc)
    local multiplier = superFunc(self)
    if self.spec_stumpCutter.curSplitShape ~= nil then
        multiplier = multiplier + self:getWorkDirtMultiplier()
    end
    return multiplier
end
function StumpCutter:getWearMultiplier(superFunc)
    local multiplier = superFunc(self)
    if self.spec_stumpCutter.curSplitShape ~= nil then
        multiplier = multiplier + self:getWorkWearMultiplier()
    end
    return multiplier
end
function StumpCutter:getCultivatorLimitToField(superFunc)
    return false
end
function StumpCutter:getPlowLimitToField()
    return false
end
function StumpCutter:getPlowForceLimitToField()
    return true
end
function StumpCutter:getConsumingLoad(superFunc)
    local value, count = superFunc(self)
    local spec = self.spec_stumpCutter
    local loadPercentage = 0
    local i = 1
    for i = i, #spec.cutNodes do
        if spec.cutNodes[i].lastWorkTime + 500 > g_time then
            loadPercentage = 1
            break
        end
    end
    return value + loadPercentage, count + 1
end