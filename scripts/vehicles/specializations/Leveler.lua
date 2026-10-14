Leveler = {}
Leveler.LEVELER_NODE_XML_KEY = "vehicle.leveler.levelerNode(?)"
Leveler.LEVEL_NUM_BITS = 8
Leveler.LEVEL_MAX_VALUE = 2 ^ Leveler.LEVEL_NUM_BITS - 1
Leveler.COLLISION_MASK = CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING
function Leveler.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(BunkerSiloInteractor, specializations)
end
function Leveler.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Leveler")
    local basePath = Leveler.LEVELER_NODE_XML_KEY
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Leveler node")
    schema:register(XMLValueType.FLOAT, basePath .. "#width", "Width")
    schema:register(XMLValueType.FLOAT, basePath .. "#zOffset", "Z axis offset", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#yOffset", "Y axis offset", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#minDropWidth", "Min. drop width", "half of width")
    schema:register(XMLValueType.FLOAT, basePath .. "#maxDropWidth", "Max. drop width", "width value")
    schema:register(XMLValueType.FLOAT, basePath .. "#minDropDirOffset", "Min. drop direction offset", 0.7)
    schema:register(XMLValueType.FLOAT, basePath .. "#maxDropDirOffset", "Max. drop direction offset", 0.7)
    schema:register(XMLValueType.INT, basePath .. "#numHeightLimitChecks", "Number of height limit checks", 6)
    schema:register(XMLValueType.BOOL, basePath .. "#alignToWorldY", "Defines if the leveler node is aligned to worlds Y axis", true)
    schema:register(XMLValueType.BOOL, basePath .. ".smoothing#allowed", "Leveler smoothes while driving backward", true)
    schema:register(XMLValueType.FLOAT, basePath .. ".smoothing#radius", "Smooth ground radius", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. ".smoothing#overlap", "Radius overlap", 1.7)
    schema:register(XMLValueType.INT, basePath .. ".smoothing#direction", "Smooth direction (if set to \'0\' it smooths in both directions)", -1)
    schema:register(XMLValueType.INT, basePath .. "#fillUnitIndex", "Fill unit index", "Value of vehicle.leveler#fillUnitIndex")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".occlusionAreas.occlusionArea(?)#startNode", "Start node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".occlusionAreas.occlusionArea(?)#widthNode", "Width node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".occlusionAreas.occlusionArea(?)#heightNode", "Height node")
    schema:register(XMLValueType.INT, "vehicle.leveler.pickUpDirection", "Pick up direction", 1)
    schema:register(XMLValueType.INT, "vehicle.leveler#fillUnitIndex", "Fill unit index")
    schema:register(XMLValueType.FLOAT, "vehicle.leveler#maxFillLevelPerMS", "Max. fill level change rate as reference for effect and force", 20)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.leveler.force#node", "Force node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.leveler.force#directionNode", "Force direction node")
    schema:register(XMLValueType.FLOAT, "vehicle.leveler.force#maxForce", "Max. force in kN", 0)
    schema:register(XMLValueType.INT, "vehicle.leveler.force#direction", "Driving direction for applying force", 1)
    schema:register(XMLValueType.BOOL, "vehicle.leveler#ignoreFarmlandState", "If set to true the farmland underneath the leveler does not need to be bought to actually work", false)
    EffectManager.registerEffectXMLPaths(schema, "vehicle.leveler.effects")
    schema:setXMLSpecializationType()
end
function Leveler.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsLevelerPickupNodeActive", Leveler.getIsLevelerPickupNodeActive)
    SpecializationUtil.registerFunction(vehicleType, "loadLevelerNodeFromXML", Leveler.loadLevelerNodeFromXML)
    SpecializationUtil.registerFunction(vehicleType, "onLevelerRaycastCallback", Leveler.onLevelerRaycastCallback)
end
function Leveler.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttacherJointControlDampingAllowed", Leveler.getIsAttacherJointControlDampingAllowed)
end
function Leveler.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Leveler)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Leveler)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Leveler)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Leveler)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Leveler)
end
function Leveler:onLoad(_)
    local spec = self.spec_leveler
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.leveler.levelerNode#index", "vehicle.leveler.levelerNode#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.levelerEffects", "vehicle.leveler.effects")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.leveler.levelerNode(0)#minDropHeight")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.leveler.levelerNode(0)#maxDropHeight")
    spec.pickUpDirection = self.xmlFile:getValue("vehicle.leveler.pickUpDirection", 1)
    spec.maxFillLevelPerMS = self.xmlFile:getValue("vehicle.leveler#maxFillLevelPerMS", 35)
    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.leveler#fillUnitIndex")
    spec.nodes = {}
    local i = 0
    while true do
        local key = string.format("vehicle.leveler.levelerNode(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local levelerNode = {}
        if self:loadLevelerNodeFromXML(levelerNode, self.xmlFile, key) then
            levelerNode.vehicle = self
            levelerNode.onLevelerRaycastCallback = self.onLevelerRaycastCallback
            table.insert(spec.nodes, levelerNode)
        end
        i = i + 1
    end
    spec.litersToPickup = 0
    spec.smoothAccumulation = 0
    spec.lastFillLevelMoved = 0
    spec.lastFillLevelMovedPct = 0
    spec.lastFillLevelMovedTarget = 0
    spec.lastFillLevelMovedBuffer = 0
    spec.lastFillLevelMovedBufferTime = 300
    spec.lastFillLevelMovedBufferTimer = 0
    spec.forceNode = self.xmlFile:getValue("vehicle.leveler.force#node", nil, self.components, self.i3dMappings)
    spec.forceDirNode = self.xmlFile:getValue("vehicle.leveler.force#directionNode", spec.forceNode, self.components, self.i3dMappings)
    spec.maxForce = self.xmlFile:getValue("vehicle.leveler.force#maxForce", 0)
    spec.lastForce = 0
    spec.forceDir = self.xmlFile:getValue("vehicle.leveler.force#direction", 1)
    spec.ignoreFarmlandState = self.xmlFile:getValue("vehicle.leveler#ignoreFarmlandState", false)
    if self.isClient then
        spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.leveler.effects", self.components, self, self.i3dMappings)
    end
    if #spec.nodes == 0 then
        SpecializationUtil.removeEventListener(self, "onUpdate", Leveler)
    end
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function Leveler:onDelete()
    g_effectManager:deleteEffects(self.spec_leveler.effects)
end
function Leveler:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        self.spec_leveler.lastFillLevelMovedPct = streamReadUIntN(streamId, Leveler.LEVEL_NUM_BITS) / Leveler.LEVEL_MAX_VALUE
    end
end
function Leveler:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_leveler
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, spec.lastFillLevelMovedPct * Leveler.LEVEL_MAX_VALUE, Leveler.LEVEL_NUM_BITS)
        end
    end
end
function Leveler:onUpdate(dt, _, _, _)
    if self.isClient then
        local fillType = FillType.UNKNOWN
        for _, levelerNode in pairs(self.spec_leveler.nodes) do
            fillType = self:getFillUnitLastValidFillType(levelerNode.fillUnitIndex)
            if fillType ~= FillType.UNKNOWN then
                break
            end
        end
        if fillType == FillType.UNKNOWN or spec.lastFillLevelMovedPct <= 0 then
            g_effectManager:stopEffects(spec.effects)
        else
            g_effectManager:setEffectTypeInfo(spec.effects, fillType)
            g_effectManager:startEffects(spec.effects)
            for _, levelerNode in pairs(spec.effects) do
                if levelerNode:isa(LevelerEffect) or levelerNode:isa(SnowPlowMotionPathEffect) then
                    levelerNode:setFillLevel(spec.lastFillLevelMovedPct)
                    levelerNode:setLastVehicleSpeed(self.movingDirection * self:getLastSpeed())
                end
            end
        end
    end
    if self.isServer then
        for _, _ in pairs(spec.nodes) do
            local levelerNode, y0, z0 = localToWorld(_.node, -_.halfWidth, _.yOffset, _.maxDropDirOffset)
            local x1, y1, z1 = localToWorld(_.node, _.halfWidth, _.yOffset, _.maxDropDirOffset)
            if not spec.ignoreFarmlandState then
                local ownerFarmId = self:getOwnerFarmId()
                if not (g_farmlandManager:getCanAccessLandAtWorldPosition(ownerFarmId, levelerNode, z0) and g_farmlandManager:getCanAccessLandAtWorldPosition(ownerFarmId, x1, z1)) then
                    break
                end
            end
            local ownerFarmId = 0
            local fillType = self:getFillUnitFillType(_.fillUnitIndex)
            local fillLevel = self:getFillUnitFillLevel(_.fillUnitIndex)
            local newFillType
            if fillType == FillType.UNKNOWN or fillLevel < g_densityMapHeightManager:getMinValidLiterValue(fillType) + 0.001 then
                newFillType = DensityMapHeightUtil.getFillTypeAtLine(levelerNode, y0, z0, x1, y1, z1, 0.5 * _.maxDropDirOffset)
                if newFillType == FillType.UNKNOWN or (newFillType == fillType or not self:getFillUnitSupportsFillType(_.fillUnitIndex, newFillType)) then
                    newFillType = fillType
                else
                    self:addFillUnitFillLevel(self:getOwnerFarmId(), _.fillUnitIndex, -math.huge)
                end
            else
                newFillType = fillType
            end
            local newFillType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(newFillType)
            if newFillType == FillType.UNKNOWN or newFillType == nil then
                spec.lastFillLevelMovedBuffer = 0
                spec.lastFillLevelMovedTarget = 0
            else
                local capacity = self:getFillUnitCapacity(_.fillUnitIndex)
                local dirY = 0
                if _.alignToWorldY then
                    local sz, ey
                    sz, dirY, ey = localDirectionToWorld(_.referenceFrame, 0, 0, 1)
                    I3DUtil.setWorldDirection(_.node, sz, math.max(dirY, 0), ey, 0, 1, 0)
                end
                if self:getIsLevelerPickupNodeActive(_) and (spec.pickUpDirection == self.movingDirection and self.lastSpeed > 0.0001) then
                    local dirX, dirZ, sz = localToWorld(_.node, -_.halfWidth, _.yOffset, _.zOffset)
                    local ex, ey, ez = localToWorld(_.node, _.halfWidth, _.yOffset, _.zOffset)
                    if dirY >= 0 then
                        local _, sy2, _ = localToWorld(_.node, -_.halfWidth, _.yOffset, _.zOffset + 0.5)
                        local _, ey2, _ = localToWorld(_.node, _.halfWidth, _.yOffset, _.zOffset + 0.5)
                        dirZ = math.max(dirZ, sy2)
                        ey = math.max(ey, ey2)
                    end
                    local _ = -(capacity - self:getFillUnitFillLevel(_.fillUnitIndex))
                    local sy2 = _.numHeightLimitChecks
                    if sy2 > 0 then
                        for _ = 0, sy2 do
                            local t = _ / sy2
                            local yi = dirZ + (ey - dirZ) * t
                            _ = math.max(_, DensityMapHeightUtil.getHeightAtWorldPos(dirX + (ex - dirX) * t, yi, sz + (ez - sz) * t) - 0.05 - yi)
                        end
                        if _ > 0 then
                        end
                    end
                    local _, _ = DensityMapHeightUtil.tipToGroundAroundLine(self, _, newFillType, dirX, dirZ, sz, ex, ey, ez, 0.5, 2, _.lineOffsetPickUp, true, nil)
                    _.lastPickUp = _
                    _.lineOffsetPickUp = _
                    if _.lastPickUp < 0 then
                        if self.notifiyBunkerSilo ~= nil then
                            self:notifiyBunkerSilo(_.lastPickUp, newFillType, (dirX + ex) * 0.5, (dirZ + ey) * 0.5, (sz + ez) * 0.5)
                        end
                        _.lastPickUp = _.lastPickUp + spec.litersToPickup
                        spec.litersToPickup = 0
                        self:addFillUnitFillLevel(self:getOwnerFarmId(), _.fillUnitIndex, -_.lastPickUp, newFillType, ToolType.UNDEFINED, nil)
                        ownerFarmId = _.lastPickUp
                    end
                end
                local dirX = -ownerFarmId
                spec.lastFillLevelMovedBuffer = spec.lastFillLevelMovedBuffer + dirX
                spec.lastFillLevelMovedBufferTimer = spec.lastFillLevelMovedBufferTimer + dt
                if spec.lastFillLevelMovedBufferTimer > spec.lastFillLevelMovedBufferTime then
                    spec.lastFillLevelMovedTarget = spec.lastFillLevelMovedBuffer / spec.lastFillLevelMovedBufferTimer
                    spec.lastFillLevelMovedBufferTimer = 0
                    spec.lastFillLevelMovedBuffer = 0
                end
                if self.movingDirection < 0 and self.lastSpeed * 3600 > 0.5 then
                    spec.lastFillLevelMovedBuffer = 0
                end
                local dirZ = self:getFillUnitFillLevel(_.fillUnitIndex)
                if dirZ > 0 then
                    local dirZ = dirZ / capacity
                    local sz = MathUtil.lerp(_.halfMinDropWidth, _.halfMaxDropWidth, dirZ)
                    local ex, ey, ez = localToWorld(_.node, -sz, _.yOffset, _.zOffset)
                    local _, sy2, _ = localToWorld(_.node, sz, _.yOffset, _.zOffset)
                    local ey2, _ = DensityMapHeightUtil.tipToGroundAroundLine(self, dirZ, newFillType, ex, ey + -0.15, ez, _, sy2 + -0.15, _, 0.5, 2, _.lineOffsetDrop1, true, nil)
                    _.lastDrop1 = ey2
                    _.lineOffsetDrop1 = _
                    if _.lastDrop1 > 0 then
                        local ey2 = dirZ - _.lastDrop1
                        if ey2 <= g_densityMapHeightManager:getMinValidLiterValue(newFillType) then
                            _.lastDrop1 = dirZ
                            spec.litersToPickup = spec.litersToPickup + ey2
                        end
                        self:addFillUnitFillLevel(self:getOwnerFarmId(), _.fillUnitIndex, -_.lastDrop1, newFillType, ToolType.UNDEFINED, nil)
                    end
                end
                if self:getFillUnitFillLevel(_.fillUnitIndex) > 0 then
                    local dirZ = MathUtil.lerp(_.minDropDirOffset, _.maxDropDirOffset, spec.lastFillLevelMovedPct)
                    local sz, ex, ey = localToWorld(_.node, 0, _.yOffset, 0)
                    local ez, _, sy2 = localToWorld(_.node, 0, _.yOffset, _.zOffset + dirZ)
                    _.raycastLastFillType = newFillType
                    _.raycastLastRadius = 2
                    _.raycastHitObject = false
                    local ey2 = sy2 - ey
                    local _ = MathUtil.vector3Length(ez - sz - ex, _, ey2)
                    local t, xi, yi = MathUtil.vector3Normalize(_, _, ey2)
                    raycastAllAsync(sz, ex, ey, t, xi, yi, _, "onLevelerRaycastCallback", _, Leveler.COLLISION_MASK)
                end
            end
            if ownerFarmId < 0 and newFillType ~= FillType.UNKNOWN then
                self:notifiyBunkerSilo(ownerFarmId, newFillType)
            end
            if _.allowsSmoothing and (_.smoothDirection == 0 or self.movingDirection == _.smoothDirection) then
                local innerRadius = 0
                if self.lastSpeedReal > 0.0002 then
                    innerRadius = spec.smoothAccumulation + math.max(self.lastMovedDistance * 0.5, 0.0003 * dt)
                    spec.smoothAccumulation = innerRadius - DensityMapHeightUtil.getRoundedHeightValue(innerRadius)
                else
                    spec.smoothAccumulation = 0
                end
                if innerRadius > 0 then
                    DensityMapHeightUtil.smoothAroundLine(_.node, _.width, _.smoothGroundRadius, _.smoothOverlap, innerRadius, true)
                end
            end
        end
        local fillType = spec.lastFillLevelMovedTarget == 0 and 0.2 or 0.05
        spec.lastFillLevelMoved = spec.lastFillLevelMoved * (1 - fillType) + spec.lastFillLevelMovedTarget * fillType
        if spec.lastFillLevelMoved < 0.005 then
            spec.lastFillLevelMoved = 0
        end
        local _ = spec.lastFillLevelMoved / spec.maxFillLevelPerMS
        local _ = math.min(_, 1)
        spec.lastFillLevelMovedPct = math.max(_, 0)
        if spec.lastFillLevelMovedPct ~= spec.lastFillLevelMovedPct then
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
        if spec.forceNode ~= nil and (self.movingDirection == spec.forceDir and spec.lastFillLevelMoved > 0) then
            spec.lastForce = -spec.maxForce * spec.lastFillLevelMovedPct
            local dx, _, _ = localDirectionToWorld(spec.forceDirNode, 0, 0, spec.lastForce)
            local levelerNode, y0, z0 = getCenterOfMass(spec.forceNode)
            addForce(spec.forceNode, dx, _, _, levelerNode, y0, z0, true)
        end
    end
end
function Leveler:loadLevelerNodeFromXML(levelerNode, xmlFile, key)
    levelerNode.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    if levelerNode.node == nil then
        return false
    end
    local referenceFrame = createTransformGroup("referenceFrame")
    link(getParent(levelerNode.node), referenceFrame)
    setTranslation(referenceFrame, getTranslation(levelerNode.node))
    setRotation(referenceFrame, getRotation(levelerNode.node))
    levelerNode.referenceFrame = referenceFrame
    levelerNode.zOffset = xmlFile:getValue(key .. "#zOffset", 0)
    levelerNode.yOffset = xmlFile:getValue(key .. "#yOffset", 0)
    levelerNode.width = xmlFile:getValue(key .. "#width")
    levelerNode.halfWidth = levelerNode.width * 0.5
    levelerNode.minDropWidth = xmlFile:getValue(key .. "#minDropWidth", levelerNode.width * 0.5)
    levelerNode.halfMinDropWidth = levelerNode.minDropWidth * 0.5
    levelerNode.maxDropWidth = xmlFile:getValue(key .. "#maxDropWidth", levelerNode.width)
    levelerNode.halfMaxDropWidth = levelerNode.maxDropWidth * 0.5
    levelerNode.minDropDirOffset = xmlFile:getValue(key .. "#minDropDirOffset", 0.7)
    levelerNode.maxDropDirOffset = xmlFile:getValue(key .. "#maxDropDirOffset", 0.7)
    levelerNode.numHeightLimitChecks = xmlFile:getValue(key .. "#numHeightLimitChecks", 6)
    levelerNode.alignToWorldY = xmlFile:getValue(key .. "#alignToWorldY", true)
    levelerNode.occlusionAreas = {}
    local i = 0
    while true do
        local baseKey = string.format("%s.occlusionAreas.occlusionArea(%d)", key, i)
        if not xmlFile:hasProperty(baseKey) then
            break
        end
        local entry = {
            ["startNode"] = xmlFile:getValue(baseKey .. "#startNode", nil, self.components, self.i3dMappings),
            ["widthNode"] = xmlFile:getValue(baseKey .. "#widthNode", nil, self.components, self.i3dMappings),
            ["heightNode"] = xmlFile:getValue(baseKey .. "#heightNode", nil, self.components, self.i3dMappings)
        }
        if entry.startNode == nil or (entry.widthNode == nil or entry.heightNode == nil) then
            Logging.xmlWarning(xmlFile, "Failed to load occlustion area \'%s\'. One or more nodes missing.", baseKey)
        else
            table.insert(levelerNode.occlusionAreas, entry)
        end
        i = i + 1
    end
    levelerNode.allowsSmoothing = xmlFile:getValue(key .. ".smoothing#allowed", true)
    levelerNode.smoothGroundRadius = xmlFile:getValue(key .. ".smoothing#radius", 0.5)
    levelerNode.smoothOverlap = xmlFile:getValue(key .. ".smoothing#overlap", 1.7)
    levelerNode.smoothDirection = xmlFile:getValue(key .. ".smoothing#direction", -1)
    levelerNode.lineOffsetPickUp = nil
    levelerNode.lineOffsetDrop = nil
    levelerNode.lastPickUp = 0
    levelerNode.lastDrop = 0
    levelerNode.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex", self.spec_leveler.fillUnitIndex)
    if self:getFillUnitExists(levelerNode.fillUnitIndex) then
        return true
    end
    local baseKey = Logging.xmlWarning
    local entry = self.xmlFile
    baseKey(entry, "Unknown fillUnitIndex \'%s\' for leveler", (tostring(levelerNode.fillUnitIndex)))
    return false
end
function Leveler:getIsLevelerPickupNodeActive(_)
    return self.getAttacherVehicle == nil or self:getAttacherVehicle() ~= nil
end
function Leveler:getIsAttacherJointControlDampingAllowed(superFunc)
    if not superFunc(self) then
        return false
    end
    for _, levelerNode in pairs(self.spec_leveler.nodes) do
        local x, y, z = getWorldTranslation(levelerNode.node)
        local _, height = DensityMapHeightUtil.getHeightAtWorldPos(x, y, z)
        if height == 0 then
            return false
        end
    end
    return true
end
function Leveler.onLevelerRaycastCallback(levelerNode, hitObjectId, _, _, _, _, _, _, _, _, _, isLast)
    local self = levelerNode.vehicle
    if not (self.isDeleted or self.isDeleting) then
        if hitObjectId ~= 0 and hitObjectId ~= g_terrainNode then
            levelerNode.raycastHitObject = true
        end
        if isLast and not levelerNode.raycastHitObject then
            local fillLevel = self:getFillUnitFillLevel(levelerNode.fillUnitIndex)
            if fillLevel > 0 then
                local fillType = levelerNode.raycastLastFillType
                local f = self.spec_leveler.lastFillLevelMovedPct
                local width = MathUtil.lerp(levelerNode.halfMinDropWidth, levelerNode.halfMaxDropWidth, f)
                local dropOffset = MathUtil.lerp(levelerNode.minDropDirOffset, levelerNode.maxDropDirOffset, f)
                local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
                if terrainHeightUpdater ~= nil then
                    local i = 1
                    for i = i, #levelerNode.occlusionAreas do
                        local occlusionArea = levelerNode.occlusionAreas[i]
                        local ox1, oy1, oz1 = getWorldTranslation(occlusionArea.startNode)
                        local ox2, _, oz2 = getWorldTranslation(occlusionArea.widthNode)
                        local ox3, _, oz3 = getWorldTranslation(occlusionArea.heightNode)
                        local ox, oz, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(ox1, oz1, ox2, oz2, ox3, oz3)
                        addDensityMapHeightOcclusionArea(terrainHeightUpdater, ox, oy1, oz, widthX, oy1, widthZ, heightX, oy1, heightZ, true)
                    end
                end
                local sx, sy, i = localToWorld(levelerNode.node, -width, levelerNode.yOffset, levelerNode.zOffset + dropOffset)
                local occlusionArea, ox1, oy1 = localToWorld(levelerNode.node, width, levelerNode.yOffset, levelerNode.zOffset + dropOffset)
                local oz1, ox2 = DensityMapHeightUtil.tipToGroundAroundLine(self, fillLevel, fillType, sx, sy, i, occlusionArea, ox1, oy1, 0, levelerNode.raycastLastRadius, levelerNode.lineOffsetDrop2, false, nil)
                levelerNode.lastDrop2 = oz1
                levelerNode.lineOffsetDrop2 = ox2
                if levelerNode.lastDrop2 > 0 then
                    local oz1 = fillLevel - levelerNode.lastDrop2
                    if oz1 <= g_densityMapHeightManager:getMinValidLiterValue(fillType) then
                        levelerNode.lastDrop2 = fillLevel
                        spec.litersToPickup = spec.litersToPickup + oz1
                    end
                    self:addFillUnitFillLevel(self:getOwnerFarmId(), levelerNode.fillUnitIndex, -levelerNode.lastDrop2, fillType, ToolType.UNDEFINED, nil)
                end
            end
        end
    end
end