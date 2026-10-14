WoodHarvesterLight = {}
WoodHarvesterLight.SPAWN_COLLISION_MASK = CollisionFlag.STATIC_OBJECT + CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.ANIMAL
function WoodHarvesterLight.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(AutomaticArmControlHarvester, specializations)
end
function WoodHarvesterLight.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("woodHarvesterLight", g_i18n:getText("shop_configuration"), "woodHarvesterLight", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("WoodHarvesterLight")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.woodHarvesterLight.cutNode#node", "Cut node")
    schema:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.cutNode#maxRadius", "Max. radius of the tree", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.cutNode#sizeY", "Size in Y direction", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.cutNode#sizeZ", "Size in Z direction", 1)
    schema:register(XMLValueType.STRING, "vehicle.woodHarvesterLight.cutAnimation#name", "Cut animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.cutAnimation#speedScale", "Cut animation speed scale")
    schema:register(XMLValueType.STRING, "vehicle.woodHarvesterLight.grabAnimation#name", "Grab animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.grabAnimation#speedScale", "Grab animation speed scale")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.woodHarvesterLight.logSpawner#startNode", "Start reference node for spawning (end node is the tree)")
    schema:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.logSpawner#offset", "Offset from tree", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.logSpawner#maxSpawnWidth", "Max. spawning width to the left and right", 10)
    schema:register(XMLValueType.FLOAT, "vehicle.woodHarvesterLight.logSpawner#additionalLength", "Length of area behind the tree that can be used for the spawning", 4)
    EffectManager.registerEffectXMLPaths(schema, "vehicle.woodHarvesterLight.cutEffects")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.woodHarvesterLight.sounds", "cut")
    schema:setXMLSpecializationType()
end
function WoodHarvesterLight.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "updateLogSpawner", WoodHarvesterLight.updateLogSpawner)
    SpecializationUtil.registerFunction(vehicleType, "onWoodHarversterLogSpawnerCallback", WoodHarvesterLight.onWoodHarversterLogSpawnerCallback)
    SpecializationUtil.registerFunction(vehicleType, "spawnLogHeap", WoodHarvesterLight.spawnLogHeap)
    SpecializationUtil.registerFunction(vehicleType, "spawnTreeStump", WoodHarvesterLight.spawnTreeStump)
end
function WoodHarvesterLight.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSupportsAutoTreeAlignment", WoodHarvesterLight.getSupportsAutoTreeAlignment)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAutoAlignHasValidTree", WoodHarvesterLight.getAutoAlignHasValidTree)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", WoodHarvesterLight.getAreControlledActionsAllowed)
end
function WoodHarvesterLight.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", WoodHarvesterLight)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", WoodHarvesterLight)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WoodHarvesterLight)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", WoodHarvesterLight)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", WoodHarvesterLight)
end
function WoodHarvesterLight:onLoad(_)
    local spec = self.spec_woodHarvesterLight
    spec.cutNode = {}
    spec.cutNode.node = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutNode#node", nil, self.components, self.i3dMappings)
    spec.cutNode.maxRadius = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutNode#maxRadius", 1)
    spec.cutNode.sizeY = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutNode#sizeY", 1)
    spec.cutNode.sizeZ = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutNode#sizeZ", 1)
    spec.cutAnimation = {}
    spec.cutAnimation.name = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutAnimation#name")
    spec.cutAnimation.speedScale = self.xmlFile:getValue("vehicle.woodHarvesterLight.cutAnimation#speedScale", 1)
    spec.grabAnimation = {}
    spec.grabAnimation.name = self.xmlFile:getValue("vehicle.woodHarvesterLight.grabAnimation#name")
    spec.grabAnimation.speedScale = self.xmlFile:getValue("vehicle.woodHarvesterLight.grabAnimation#speedScale", 1)
    spec.logSpawner = {}
    spec.logSpawner.startNode = self.xmlFile:getValue("vehicle.woodHarvesterLight.logSpawner#startNode", nil, self.components, self.i3dMappings)
    spec.logSpawner.offset = self.xmlFile:getValue("vehicle.woodHarvesterLight.logSpawner#offset", 1)
    spec.logSpawner.maxSpawnWidth = self.xmlFile:getValue("vehicle.woodHarvesterLight.logSpawner#maxSpawnWidth", 10)
    spec.logSpawner.additionalLength = self.xmlFile:getValue("vehicle.woodHarvesterLight.logSpawner#additionalLength", 4)
    spec.logSpawner.currentCheckIndex = 0
    spec.logSpawner.hasValidBox = false
    spec.logSpawner.validCheckBoxIndex = 0
    spec.logSpawner.lastValidBox = {
        0,
        0,
        0,
        0
    }
    spec.logSpawner.lastBoxToCheck = {
        0,
        0,
        0,
        0
    }
    spec.logSpawner.logFilename = "data/maps/trees/logs/pineLog.i3d"
    spec.logSpawner.logSize = { 0.4, 5 }
    spec.logSpawner.logVolume = 0.66
    spec.curSplitShape = nil
    if self.isClient then
        spec.cutEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.woodHarvesterLight.cutEffects", self.components, self, self.i3dMappings)
        spec.samples = {}
        spec.samples.cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.woodHarvesterLight.sounds", "cut", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    if spec.cutNode.node == nil then
        SpecializationUtil.removeEventListener(self, "onUpdate", WoodHarvesterLight)
        SpecializationUtil.removeEventListener(self, "onTurnedOn", WoodHarvesterLight)
        SpecializationUtil.removeEventListener(self, "onTurnedOff", WoodHarvesterLight)
    end
    spec.texts = {}
    spec.texts.warning_woodHarvesterNoTreeInRange = g_i18n:getText("warning_woodHarvesterNoTreeInRange")
    spec.texts.warning_woodHarvesterNoSpawnPlace = g_i18n:getText("warning_woodHarvesterNoSpawnPlace")
    spec.texts.warning_woodHarvesterTreeNotAllowed = g_i18n:getText("warning_youAreNotAllowedToCutThisTree")
    spec.texts.warning_woodHarvesterTreeTypeNotSupported = g_i18n:getText("warning_treeTypeNotSupported")
    spec.texts.warning_woodHarvesterTreeTooThick = g_i18n:getText("warning_treeTooThick")
end
function WoodHarvesterLight:onDelete()
    if self.isClient then
        g_effectManager:deleteEffects(self.spec_woodHarvesterLight.cutEffects)
        g_soundManager:deleteSamples(spec.samples)
    end
end
function WoodHarvesterLight:onUpdate(_, _, _, _)
    local spec = self.spec_woodHarvesterLight
    spec.curSplitShape = nil
    if self:getIsTurnedOn() then
        local x, y, z = localToWorld(spec.cutNode.node, 0, 0, 0)
        local nx, ny, nz = localDirectionToWorld(spec.cutNode.node, 1, 0, 0)
        local yx, yy, yz = localDirectionToWorld(spec.cutNode.node, 0, 1, 0)
        local splitShapeId, _, _, _, _ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, spec.cutNode.sizeY, spec.cutNode.sizeZ)
        if splitShapeId == 0 or getUserAttribute(splitShapeId, "isTreeStump") == true then
            if self:getAnimationTime(spec.cutAnimation.name) > 0.99 then
                self:setAnimationTime(spec.cutAnimation.name, 0)
                if Platform.gameplay.automaticVehicleControl then
                    self:playControlledActions()
                end
            end
        else
            spec.curSplitShape = splitShapeId
            if not (self:getIsAutomaticAlignmentActive() or self:getIsAnimationPlaying(spec.cutAnimation.name)) then
                local animTime = self:getAnimationTime(spec.cutAnimation.name)
                if animTime < 0.5 then
                    self:setAnimationTime(spec.cutAnimation.name, 0)
                    self:playAnimation(spec.cutAnimation.name, spec.cutAnimation.speedScale, self:getAnimationTime(spec.cutAnimation.name))
                    if self.isClient then
                        g_effectManager:setEffectTypeInfo(spec.cutEffects, FillType.WOODCHIPS)
                        g_effectManager:startEffects(spec.cutEffects)
                        g_soundManager:playSample(spec.samples.cut)
                    end
                elseif animTime >= 0.5 then
                    self:setAnimationTime(spec.cutAnimation.name, 0)
                    if self.isClient then
                        g_effectManager:stopEffects(spec.cutEffects)
                        g_soundManager:stopSample(spec.samples.cut)
                    end
                    g_currentMission:removeKnownSplitShape(splitShapeId)
                    if getVolume(splitShapeId) ~= 0 then
                        self:spawnLogHeap(getSplitType(splitShapeId), getVolume(splitShapeId))
                        local tx, ty, tz = getWorldTranslation(splitShapeId)
                        self:spawnTreeStump(tx, ty, tz)
                    end
                    delete(getParent(splitShapeId))
                    g_treePlantManager:removingSplitShape(splitShapeId)
                    local tx, ty = g_farmManager:updateFarmStats(self:getActiveFarm(), "cutTreeCount", 1)
                    if tx ~= nil then
                        g_achievementManager:tryUnlock("CutTreeFirst", tx)
                        g_achievementManager:tryUnlock("CutTree", tx)
                        if tx == 1 then
                            g_currentMission.introductionHelpSystem:showHint("forestryFirstTree")
                        elseif tx == 20 then
                            local tz, plantedTreeCount = g_farmManager:getFarmStatValue(self:getActiveFarm(), "plantedTreeCount")
                            if plantedTreeCount == 0 then
                                g_currentMission.introductionHelpSystem:showHint("forestryStumpCutter")
                            end
                        end
                    end
                    if Platform.gameplay.automaticVehicleControl then
                        self:playControlledActions()
                    end
                end
            end
        end
    end
    local x, y, z, nx = self:getAutomaticAlignmentCurrentTarget()
    if x == nil then
        spec.logSpawner.lastOverlapCheckIsBlocked = false
        spec.logSpawner.pendingOverlapCheck = false
        spec.logSpawner.currentCheckIndex = 0
        spec.logSpawner.validCheckBoxIndex = 0
        spec.logSpawner.hasValidBox = false
    else
        self:updateLogSpawner(x, y, z, nx)
    end
end
function WoodHarvesterLight:onTurnedOn()
    local spec = self.spec_woodHarvesterLight
    self:playAnimation(spec.grabAnimation.name, spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name), true)
end
function WoodHarvesterLight:onTurnedOff()
    local spec = self.spec_woodHarvesterLight
    self:playAnimation(spec.grabAnimation.name, -spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name), true)
    if self.isClient then
        g_effectManager:stopEffects(spec.cutEffects)
        g_soundManager:stopSamples(spec.samples)
    end
end
function WoodHarvesterLight:getSupportsAutoTreeAlignment(superFunc)
    return true
end
function WoodHarvesterLight:getAutoAlignHasValidTree(_, radius)
    local spec = self.spec_woodHarvesterLight
    return spec.curSplitShape ~= nil, radius <= spec.cutNode.maxRadius
end
function WoodHarvesterLight:getAreControlledActionsAllowed(superFunc)
    if self:getActionControllerDirection() == 1 then
        local reason = self:getAutomaticAlignmentInvalidTreeReason()
        if reason == AutomaticArmControlHarvester.INVALID_REASON_NONE then
            local x, _, _, _ = self:getAutomaticAlignmentCurrentTarget()
            if x == nil then
                return false, self.spec_woodHarvesterLight.texts.warning_woodHarvesterNoTreeInRange
            end
            if not spec.logSpawner.hasValidBox then
                return false, spec.texts.warning_woodHarvesterNoSpawnPlace
            end
        else
            if reason == AutomaticArmControlHarvester.INVALID_REASON_NO_ACCESS then
                return false, spec.texts.warning_woodHarvesterTreeNotAllowed
            end
            if reason == AutomaticArmControlHarvester.INVALID_REASON_WRONG_TYPE then
                return false, spec.texts.warning_woodHarvesterTreeTypeNotSupported
            end
            if reason == AutomaticArmControlHarvester.INVALID_REASON_TOO_THICK then
                return false, spec.texts.warning_woodHarvesterTreeTooThick
            end
        end
    end
    return superFunc(self)
end
function WoodHarvesterLight:updateLogSpawner(tx, _, tz, radius)
    local spec = self.spec_woodHarvesterLight
    if not spec.logSpawner.pendingOverlapCheck then
        if spec.logSpawner.lastOverlapCheckIsBlocked then
            if spec.logSpawner.currentCheckIndex > spec.logSpawner.validCheckBoxIndex then
                spec.logSpawner.hasValidBox = false
                spec.logSpawner.validCheckBoxIndex = 0
            end
        else
            spec.logSpawner.hasValidBox = true
            spec.logSpawner.lastValidBox[1] = spec.logSpawner.lastBoxToCheck[1]
            spec.logSpawner.lastValidBox[2] = spec.logSpawner.lastBoxToCheck[2]
            spec.logSpawner.lastValidBox[3] = spec.logSpawner.lastBoxToCheck[3]
            spec.logSpawner.lastValidBox[4] = spec.logSpawner.lastBoxToCheck[4]
            spec.logSpawner.validCheckBoxIndex = spec.logSpawner.currentCheckIndex
            spec.logSpawner.currentCheckIndex = 0
        end
    end
    local requiredWidth = spec.logSpawner.logSize[1] * 5
    local requiredLength = spec.logSpawner.logSize[2] + 0.5
    local ex = requiredWidth * 0.5
    local ez = requiredLength * 0.5
    local sx, _, sz = getWorldTranslation(spec.logSpawner.startNode)
    local dx, dz = MathUtil.vector2Normalize(tx - sx, tz - sz)
    local ry = MathUtil.getYRotationFromDirection(dx, dz)
    local zOffset = 0
    local xOffset = radius + spec.logSpawner.offset + requiredWidth * 0.5
    local x = spec.logSpawner.currentCheckIndex / 5
    local offsetDistance = math.floor(x) * 2
    local offsetDirection = spec.logSpawner.currentCheckIndex % 5
    if offsetDirection == 0 then
    elseif offsetDirection == 1 then
    elseif offsetDirection == 2 then
    elseif offsetDirection == 3 then
    elseif offsetDirection == 4 then
        zOffset = requiredLength + offsetDistance
        xOffset = 0
    end
    if spec.logSpawner.maxSpawnWidth < offsetDistance then
        spec.logSpawner.currentCheckIndex = 0
    end
    local x = tx + dx * zOffset + dz * xOffset
    local z = tz + dz * zOffset - dx * xOffset
    local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
    if not spec.logSpawner.pendingOverlapCheck then
        spec.logSpawner.lastOverlapCheckIsBlocked = false
        spec.logSpawner.pendingOverlapCheck = true
        spec.logSpawner.lastBoxToCheck[1] = x
        spec.logSpawner.lastBoxToCheck[2] = y
        spec.logSpawner.lastBoxToCheck[3] = z
        spec.logSpawner.lastBoxToCheck[4] = ry
        overlapBoxAsync(x, y, z, 0, ry, 0, ex, 2.5, ez, "onWoodHarversterLogSpawnerCallback", self, WoodHarvesterLight.SPAWN_COLLISION_MASK, true, true, true, true)
    end
end
function WoodHarvesterLight:onWoodHarversterLogSpawnerCallback(nodeId, ...)
    local spec = self.spec_woodHarvesterLight
    if nodeId ~= 0 and not (getHasClassId(nodeId, ClassIds.TERRAIN_TRANSFORM_GROUP) or spec.logSpawner.lastOverlapCheckIsBlocked) then
        spec.logSpawner.lastOverlapCheckIsBlocked = true
        spec.logSpawner.currentCheckIndex = spec.logSpawner.currentCheckIndex + 1
    end
    spec.logSpawner.pendingOverlapCheck = false
end
function WoodHarvesterLight:spawnLogHeap(_, treeVolume)
    local spec = self.spec_woodHarvesterLight
    if spec.logSpawner.hasValidBox then
        WoodHarvesterLight.spawnLogs(spec.logSpawner.logFilename, math.max(math.floor(treeVolume / spec.logSpawner.logVolume), 1), spec.logSpawner.lastValidBox[1], spec.logSpawner.lastValidBox[2], spec.logSpawner.lastValidBox[3], spec.logSpawner.lastValidBox[4], spec.logSpawner.logSize[1], spec.logSpawner.logSize[2], self:getOwnerFarmId())
    end
end
function WoodHarvesterLight.spawnLogs(filename, numTrees, bx, by, bz, bry, lDiameter, lLength, farmId)
    local bDirX, bDirZ = MathUtil.getDirectionFromYRotation(bry)
    local spawnPositions = {}
    local numTopRow = 0
    if numTrees > 2 then
        numTopRow = math.floor((numTrees - 1) / 2)
    end
    local numBaseRow = numTrees - numTopRow
    local hLength = lLength * 0.5
    local i = 1
    for i = i, numBaseRow do
        local sideOffset = -numBaseRow * 0.5 * lDiameter + lDiameter * 0.5 + (i - 1) * lDiameter
        local sx = bx + bDirX * hLength + bDirZ * sideOffset
        local sz = bz + bDirZ * hLength - bDirX * sideOffset
        local ex = bx - bDirX * hLength + bDirZ * sideOffset
        local ez = bz - bDirZ * hLength - bDirX * sideOffset
        local sy = getTerrainHeightAtWorldPos(g_terrainNode, sx, by, sz) + lDiameter * 0.5
        local ey = getTerrainHeightAtWorldPos(g_terrainNode, ex, by, ez) + lDiameter * 0.5
        local cx = (sx + ex) * 0.5
        local cz = (sz + ez) * 0.5
        local dx, dy, dz = MathUtil.vector3Normalize(sx - ex, sy - ey, sz - ez)
        local cy = getTerrainHeightAtWorldPos(g_terrainNode, cx, (sy + ey) * 0.5, cz) + lDiameter * 0.5
        table.insert(spawnPositions, {
            ["sx"] = cx + dx * hLength,
            ["sy"] = cy + dy * hLength,
            ["sz"] = cz + dz * hLength,
            ["ex"] = cx - dx * hLength,
            ["ey"] = cy - dy * hLength,
            ["ez"] = cz - dz * hLength,
            ["cx"] = cx,
            ["cy"] = cy,
            ["cz"] = cz,
            ["dx"] = dx,
            ["dy"] = dy,
            ["dz"] = dz
        })
    end
    local i = 1
    for i = i, numTopRow do
        local sideOffset = spawnPositions[i]
        local sx = spawnPositions[i + 1]
        if sideOffset ~= nil and sx ~= nil then
            local sy = (sideOffset.sx + sx.sx) * 0.5
            local ex = (sideOffset.sz + sx.sz) * 0.5
            local ey = (sideOffset.ex + sx.ex) * 0.5
            local cx = (sideOffset.ez + sx.ez) * 0.5
            local cy = math.sqrt(math.pow(lDiameter, 2) - math.pow(lDiameter * 0.5, 2))
            local dz, dy, dz = MathUtil.vector3Normalize(sy - ey, sz - ez, ex - cx)
            table.insert(spawnPositions, {
                ["sx"] = sy,
                ["sy"] = sz,
                ["sz"] = ex,
                ["ex"] = ey,
                ["ey"] = ez,
                ["ez"] = cx,
                ["cx"] = (sy + ey) * 0.5,
                ["cy"] = ((sideOffset.sy + sx.sy) * 0.5 + cy + ((sideOffset.ey + sx.ey) * 0.5 + cy)) * 0.5,
                ["cz"] = (ex + cx) * 0.5,
                ["dx"] = dz,
                ["dy"] = dy,
                ["dz"] = dz
            })
        end
    end
    local tempHelperNode = createTransformGroup("tempHelperNode")
    link(getRootNode(), tempHelperNode)
    local sideOffset = 1
    local i = 1
    for sideOffset = sideOffset, #spawnPositions, i do
        local sx = spawnPositions[sideOffset].cx
        local sy = spawnPositions[sideOffset].cy
        local sz = spawnPositions[sideOffset].cz
        setTranslation(tempHelperNode, sx, sy, sz)
        setDirection(tempHelperNode, spawnPositions[sideOffset].dx, spawnPositions[sideOffset].dy, spawnPositions[sideOffset].dz, 0, 1, 0)
        local cx, cy, cz = getRotation(tempHelperNode)
        local dy = g_currentMission:getIsServer()
        ForestryLog.new(dy, g_client ~= nil):loadFromFilename(filename, sx, sy, sz, cx, cy, cz)
        dx:setOwnerFarmId(farmId)
    end
    delete(tempHelperNode)
end
function WoodHarvesterLight.spawnTreeStump(_, x, y, z)
    local treeType = g_treePlantManager:getTreeTypeDescFromName("pineStump")
    if treeType ~= nil then
        g_treePlantManager:plantTree(treeType.index, x, y, z, 0, 0, 0, 1, 1, false, nil)
    end
end