WheelPhysics = {}
WheelPhysics.COLLISION_GROUP = CollisionFlag.VEHICLE
WheelPhysics.COLLISION_MASK = CollisionMask.ALL - bit32.bor(CollisionFlag.WATER, CollisionFlag.AI_BLOCKING, CollisionFlag.GROUND_TIP_BLOCKING, CollisionFlag.PLACEMENT_BLOCKING, CollisionFlag.CAMERA_BLOCKING, CollisionFlag.PRECIPITATION_BLOCKING, CollisionFlag.ANIMAL_POSITIONING, CollisionFlag.ANIMAL_NAV_MESH_BLOCKING, CollisionFlag.TRAFFIC_VEHICLE_BLOCKING)
WheelPhysics.X_DRIVE_MAX_REAL_VALUE = 0.08726646259971647
WheelPhysics.X_DRIVE_NUM_BITS = 9
WheelPhysics.X_DRIVE_MAX_VALUE = 2 ^ WheelPhysics.X_DRIVE_NUM_BITS - 1
WheelPhysics.MAX_SINK = {}
WheelPhysics.MAX_SINK[FieldGroundType.STUBBLE_TILLAGE] = 0.07
WheelPhysics.MAX_SINK[FieldGroundType.CULTIVATED] = 0.08
WheelPhysics.MAX_SINK[FieldGroundType.SEEDBED] = 0.07
WheelPhysics.MAX_SINK[FieldGroundType.PLOWED] = 0.12
WheelPhysics.MAX_SINK[FieldGroundType.ROLLED_SEEDBED] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.RIDGE] = 0.1
WheelPhysics.MAX_SINK[FieldGroundType.SOWN] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.DIRECT_SOWN] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.PLANTED] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.RIDGE_SOWN] = 0.1
WheelPhysics.MAX_SINK[FieldGroundType.ROLLER_LINES] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.HARVEST_READY] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.HARVEST_READY_OTHER] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.GRASS] = 0.05
WheelPhysics.MAX_SINK[FieldGroundType.GRASS_CUT] = 0.05
WheelPhysics.WATER_SINK = 0.15
function WheelPhysics.new(wheel)
    local self = setmetatable({}, {
        ["__index"] = WheelPhysics
    })
    self.wheel = wheel
    self.vehicle = wheel.vehicle
    self.wheelShape = 0
    self.wheelShapeCreationFrameIndex = math.huge
    self.wheelShapeCreated = false
    self.torque = 0
    self.torqueDirection = 1
    self.dirtAmount = 0
    self.trackAlpha = 0
    self.groundColor = { 0, 0, 0 }
    self.fieldGroundColor = { 0, 0, 0 }
    self.trackColor = { 0, 0, 0 }
    self.groundDepth = 0
    self.colorBlendWithTerrain = 1
    self.lastTerrainAttribute = 0
    self.contact = WheelContactType.NONE
    self.hasWaterContact = false
    self.hasSnowContact = false
    self.snowScale = 0
    self.lastSnowScale = 0
    self.steeringAngle = 0
    self.hasGroundContact = false
    self.lastContactObjectAllowsTireTracks = true
    self.densityBits = 0
    self.densityType = FieldGroundType.NONE
    self.displacementScale = 1
    self.displacementAllowed = true
    self.displacementCollisionEnabled = true
    self.sink = 0
    self.sinkTarget = 0
    self.hasSoilContact = false
    self.tireGroundFrictionCoeff = 1
    return self
end
function WheelPhysics:loadFromXML(xmlObject)
    self.radius = xmlObject:getValue(".physics#radius")
    if self.radius == nil then
        xmlObject:xmlWarning(".physics#radius", "No radius defined for wheel! Using default value of 0.5!")
        self.radius = 0.5
    end
    self.radiusOriginal = self.radius
    self.width = xmlObject:getValue(".physics#width")
    if self.width == nil then
        xmlObject:xmlWarning(".physics#width", "No width defined for wheel! Using default value of 0.5!")
        self.width = 0.5
    end
    self.wheelShapeWidth = self.width
    self.wheelShapeWidthOffset = 0
    self.mass = xmlObject:getValue(".physics#mass", 0.1)
    self.baseMass = self.mass
    self.restLoad = xmlObject:getValue(".physics#restLoad", 1)
    self.frictionScale = xmlObject:getValue(".physics#frictionScale", 1)
    if self.frictionScale <= 0 then
        self.frictionScale = 0.01
        xmlObject:xmlWarning(".physics#frictionScale", "Wheel \'frictionScale\' set to \'0\'. This is not allowed!")
    end
    self.maxLongStiffness = xmlObject:getValue(".physics#maxLongStiffness", 30)
    self.maxLatStiffness = xmlObject:getValue(".physics#maxLatStiffness", 40)
    self.maxLatStiffnessLoad = xmlObject:getValue(".physics#maxLatStiffnessLoad", 2)
    self.xOffset = xmlObject:getValue(".physics#xOffset", 0)
    self.yOffset = xmlObject:getValue(".physics#yOffset", 0)
    self.zOffset = xmlObject:getValue(".physics#zOffset", 0)
    self.useReprOffset = xmlObject:getValue(".physics#useReprOffset", false)
    if self.xOffset ~= 0 or (self.yOffset ~= 0 or self.zOffset ~= 0) then
        if self.useReprOffset then
            setTranslation(self.wheel.repr, localToLocal(self.wheel.repr, getParent(self.wheel.repr), self.wheel.isLeft and self.xOffset or -self.xOffset, self.yOffset, self.zOffset))
        else
            setTranslation(self.wheel.driveNode, localToLocal(self.wheel.driveNode, getParent(self.wheel.driveNode), self.wheel.isLeft and self.xOffset or -self.xOffset, self.yOffset, self.zOffset))
        end
    end
    self.showSteeringAngle = xmlObject:getValue(".physics#showSteeringAngle")
    self.steeringAngleFactor = xmlObject:getValue(".physics#steeringAngleFactor", self.steeringAngleFactor or 1)
    self.steeringAngleFactorInv = 1 / self.steeringAngleFactor
    self.steeringAngle = xmlObject:getValue(".physics#startSteeringAngle", 0)
    self.suspTravel = xmlObject:getValue(".physics#suspTravel", 0.01)
    local initialCompression = xmlObject:getValue(".physics#initialCompression")
    if initialCompression == nil then
        self.deltaY = xmlObject:getValue(".physics#deltaY", 0)
    else
        self.deltaY = (1 - initialCompression * 0.01) * self.suspTravel
    end
    self.deltaYOriginal = self.deltaY
    self.spring = xmlObject:getValue(".physics#spring", 0) * Vehicle.SPRING_SCALE
    self.brakeFactor = xmlObject:getValue(".physics#brakeFactor", 1)
    self.autoHoldBrakeFactor = xmlObject:getValue(".physics#autoHoldBrakeFactor", self.brakeFactor)
    self.dampingMultiplier = 1
    self.springMultiplier = 1
    self.damperCompressionLowSpeed = xmlObject:getValue(".physics#damperCompressionLowSpeed")
    self.damperRelaxationLowSpeed = xmlObject:getValue(".physics#damperRelaxationLowSpeed")
    if self.damperRelaxationLowSpeed == nil then
        self.damperRelaxationLowSpeed = xmlObject:getValue(".physics#damper", self.damperCompressionLowSpeed or 0)
    end
    self.damperRelaxationHighSpeed = xmlObject:getValue(".physics#damperRelaxationHighSpeed", self.damperRelaxationLowSpeed * 0.7)
    if self.damperCompressionLowSpeed == nil then
        self.damperCompressionLowSpeed = self.damperRelaxationLowSpeed * 0.9
    end
    self.damperCompressionHighSpeed = xmlObject:getValue(".physics#damperCompressionHighSpeed", self.damperCompressionLowSpeed * 0.2)
    self.damperCompressionLowSpeedThreshold = xmlObject:getValue(".physics#damperCompressionLowSpeedThreshold", 0.1016)
    self.damperRelaxationLowSpeedThreshold = xmlObject:getValue(".physics#damperRelaxationLowSpeedThreshold", 0.1524)
    self.forcePointRatio = xmlObject:getValue(".physics#forcePointRatio", 0)
    if self.forcePointRatio < 0 or self.forcePointRatio > 1 then
        xmlObject:xmlWarning(".physics#forcePointRatio", "Invalid value for \'forcePointRatio\'. Must be between 0 and 1. Defaulting to 0!")
        self.forcePointRatio = 0
    end
    self.driveMode = xmlObject:getValue(".physics#driveMode", 0)
    self.isSynchronized = xmlObject:getValue(".physics#isSynchronized", true)
    self.tipOcclusionAreaGroupId = xmlObject:getValue(".physics#tipOcclusionAreaGroupId")
    self.useReprDirection = xmlObject:getValue(".physics#useReprDirection", false)
    self.useDriveNodeDirection = xmlObject:getValue(".physics#useDriveNodeDirection", false)
    self.rotationDamping = xmlObject:getValue(".physics#rotationDamping", self.mass * 0.035)
    local tireTypeName = xmlObject:getValue(".physics#tireType", "mud")
    self.tireType = WheelsUtil.getTireType(tireTypeName)
    if self.tireType == nil then
        xmlObject:xmlWarning(".physics#tireType", "Failed to find tire type \'%s\'. Defaulting to \'mud\'!", tireTypeName)
        self.tireType = WheelsUtil.getTireType("mud")
    end
    self.fieldDirtMultiplier = xmlObject:getValue(".physics#fieldDirtMultiplier", 75)
    self.streetDirtMultiplier = xmlObject:getValue(".physics#streetDirtMultiplier", -150)
    self.waterWetnessFactor = xmlObject:getValue(".physics#waterWetnessFactor", 20)
    self.minDirtPercentage = xmlObject:getValue(".physics#minDirtPercentage", 0.35)
    self.maxDirtOffset = xmlObject:getValue(".physics#maxDirtOffset", 0.5)
    self.dirtColorChangeSpeed = 1 / (xmlObject:getValue(".physics#dirtColorChangeSpeed", 20) * 1000)
    self.versatileYRot = xmlObject:getValue(".physics#versatileYRot", false)
    self.versatileYRotSpring = xmlObject:getValue(".physics#versatileYRotSpring")
    self.versatileYRotDamping = xmlObject:getValue(".physics#versatileYRotDamping")
    self.versatileYRotFriction = xmlObject:getValue(".physics#versatileYRotFriction", "0.0000015 0.0000010", true)
    self.versatileYRotSpeed = 0
    self.forceVersatility = xmlObject:getValue(".physics#forceVersatility", false)
    local maxInnerSpacing = xmlObject:getValue(".physics#supportsWheelSink", true)
    if maxInnerSpacing then
        maxInnerSpacing = self.vehicle.isServer
    end
    self.supportsWheelSink = maxInnerSpacing
    self.configCollisionMask = xmlObject:getValue(".physics#collisionMask")
    if not (Platform.gameplay.wheelTerrainDisplacement and self.supportsWheelSink) then
        local x = bit32.bnot(CollisionFlag.TERRAIN_DISPLACEMENT)
        self.collisionMask = bit32.band(self.configCollisionMask or WheelPhysics.COLLISION_MASK, x)
    end
    self.extraSinkSupported = xmlObject:getValue(".physics.extraSink#supported", false)
    self.extraSinkMaxValue = xmlObject:getValue(".physics.extraSink#maxValue", self.radius * 0.2)
    self.rotSpeed = xmlObject:getValue(".physics#rotSpeed", 0)
    self.rotSpeedNeg = xmlObject:getValue(".physics#rotSpeedNeg", 0)
    self.rotMax = xmlObject:getValue(".physics#rotMax", 0)
    self.rotMin = xmlObject:getValue(".physics#rotMin", 0)
    self.invertRotLimit = xmlObject:getValue(".physics#invertRotLimit", false)
    self.rotSpeedLimit = xmlObject:getValue(".physics#rotSpeedLimit")
    local maxInnerSpacing = xmlObject:getValue(".physics#maxInnerSpacing")
    if maxInnerSpacing ~= nil then
        local offset = self.width * 0.5 - maxInnerSpacing
        if offset > 0 then
            local x, y, z = localToLocal(self.wheel.driveNode, getParent(self.wheel.driveNode), self.wheel.isLeft and offset and offset or -offset, 0, 0)
            setTranslation(self.wheel.driveNode, x, y, z)
        end
    end
    local offset, x, y = localToLocal(self.wheel.driveNode, self.wheel.node, 0, 0, 0)
    self.positionX = offset
    self.positionY = x
    self.positionZ = y
    if self.useReprDirection then
        local offset, x, y = localDirectionToLocal(self.wheel.repr, self.wheel.node, 0, -1, 0)
        self.directionX = offset
        self.directionY = x
        self.directionZ = y
        local offset, x, y = localDirectionToLocal(self.wheel.repr, self.wheel.node, 1, 0, 0)
        self.axleX = offset
        self.axleY = x
        self.axleZ = y
    elseif self.useDriveNodeDirection then
        local offset, x, y = localDirectionToLocal(self.wheel.driveNodeDirectionNode, self.wheel.node, 0, -1, 0)
        self.directionX = offset
        self.directionY = x
        self.directionZ = y
        local offset, x, y = localDirectionToLocal(self.wheel.driveNodeDirectionNode, self.wheel.node, 1, 0, 0)
        self.axleX = offset
        self.axleY = x
        self.axleZ = y
    else
        self.directionX = 0
        self.directionY = -1
        self.directionZ = 0
        self.axleX = 1
        self.axleY = 0
        self.axleZ = 0
    end
    self.steeringCenterOffsetX = 0
    self.steeringCenterOffsetY = 0
    self.steeringCenterOffsetZ = 0
    if self.wheel.repr ~= self.wheel.driveNode then
        local offset, x, y = localToLocal(self.wheel.driveNode, self.wheel.repr, 0, 0, 0)
        self.steeringCenterOffsetX = offset
        self.steeringCenterOffsetY = x
        self.steeringCenterOffsetZ = y
        self.steeringCenterOffsetX = -self.steeringCenterOffsetX
        self.steeringCenterOffsetY = -self.steeringCenterOffsetY
        self.steeringCenterOffsetZ = -self.steeringCenterOffsetZ
    end
    return true
end
function WheelPhysics:loadAdditionalWheel(xmlObject)
    self.mass = self.mass + xmlObject:getValue(".physics#mass", 0)
    self.maxLatStiffness = self.maxLatStiffness + xmlObject:getValue(".physics#maxLatStiffness", 0)
    self.maxLongStiffness = self.maxLongStiffness + xmlObject:getValue(".physics#maxLongStiffness", 0)
end
function WheelPhysics:finalize()
    local positionY = self.positionY + self.deltaY
    self.netInfo = {}
    self.netInfo.xDrive = 0
    self.netInfo.xDriveDiff = 0
    self.netInfo.xDriveSpeed = 0
    self.netInfo.xDriveLastRaw = 0
    self.netInfo.x = self.positionX
    self.netInfo.y = positionY
    self.netInfo.z = self.positionZ
    self.netInfo.suspensionLength = self.deltaY
    self.netInfo.lastSpeedSmoothed = 0
    self.netInfo.slip = 0
    self.netInfo.sync = {
        ["yMin"] = -5,
        ["yRange"] = 10
    }
    self.netInfo.yMin = positionY - 1.2 * self.suspTravel
    local vehicleNode = self.vehicle.vehicleNodes[self.wheel.node]
    if vehicleNode ~= nil and (vehicleNode.component ~= nil and vehicleNode.component.motorized == nil) then
        vehicleNode.component.motorized = true
    end
    local additionalMass = self.wheel:getMass() - self.baseMass
    self.restLoad = self.restLoad + additionalMass
    self.maxLatStiffness = self.maxLatStiffness * self.restLoad
    self.maxLatStiffnessLoad = self.maxLatStiffnessLoad * self.restLoad
    self.networkInterpolators = {}
    self.networkInterpolators.xDriveDiff = InterpolatorValue.new(0)
    self.networkInterpolators.position = InterpolatorPosition.new(self.netInfo.x, self.netInfo.y, self.netInfo.z)
    self.networkInterpolators.suspensionLength = InterpolatorValue.new(self.netInfo.suspensionLength)
end
function WheelPhysics:postLoad() end
function WheelPhysics:readStream(streamId, updateInterpolation)
    local xDriveDirection = streamReadBool(streamId) and 1 or -1
    local xDriveDiff = (1 - (1 - streamReadUIntN(streamId, WheelPhysics.X_DRIVE_NUM_BITS) / WheelPhysics.X_DRIVE_MAX_VALUE) ^ 0.25) * WheelPhysics.X_DRIVE_MAX_REAL_VALUE * xDriveDirection
    if updateInterpolation then
        self.networkInterpolators.xDriveDiff:setValue(xDriveDiff)
    else
        self.networkInterpolators.xDriveDiff:setTargetValue(xDriveDiff)
    end
    local y = streamReadUIntN(streamId, 8) / 255 * self.netInfo.sync.yRange + self.netInfo.sync.yMin
    if updateInterpolation then
        self.netInfo.y = y
        self.networkInterpolators.position:setPosition(self.netInfo.x, y, self.netInfo.z)
    else
        self.networkInterpolators.position:setTargetPosition(self.netInfo.x, y, self.netInfo.z)
    end
    local suspLength = streamReadUIntN(streamId, 7)
    if updateInterpolation then
        self.netInfo.suspensionLength = suspLength / 100
        self.networkInterpolators.suspensionLength:setValue(suspLength / 100)
    else
        self.networkInterpolators.suspensionLength:setTargetValue(suspLength / 100)
    end
    if self.wheel.syncContactState then
        self.contact = streamReadUIntN(streamId, 2) + 1
        self.lastContactObjectAllowsTireTracks = streamReadBool(streamId)
    end
    if self.versatileYRot then
        self.steeringAngle = streamReadUIntN(streamId, 9) / 511 * 3.141592653589793 * 2
    end
end
function WheelPhysics:writeStream(streamId)
    local yRot = math.abs(self.netInfo.xDriveDiff) / WheelPhysics.X_DRIVE_MAX_REAL_VALUE
    local xDriveDiff = math.clamp(yRot, 0, 1)
    local yRot = streamWriteBool
    yRot(streamId, self.netInfo.xDriveDiff >= 0)
    streamWriteUIntN(streamId, (1 - (1 - xDriveDiff) ^ 4) * WheelPhysics.X_DRIVE_MAX_VALUE, WheelPhysics.X_DRIVE_NUM_BITS)
    local yRot = streamWriteUIntN
    yRot(streamId, math.clamp(math.floor((self.netInfo.y - self.netInfo.sync.yMin) / self.netInfo.sync.yRange * 255), 0, 255), 8)
    local yRot = streamWriteUIntN
    yRot(streamId, math.clamp(self.netInfo.suspensionLength * 100, 0, 128), 7)
    if self.wheel.syncContactState then
        streamWriteUIntN(streamId, self.contact - 1, 2)
        streamWriteBool(streamId, self.lastContactObjectAllowsTireTracks)
    end
    if self.versatileYRot then
        streamWriteUIntN(streamId, math.clamp(math.floor(self.steeringAngle % 6.283185307179586 / 6.283185307179586 * 511), 0, 511), 9)
    end
end
function WheelPhysics:updateContact()
    local nx = self.netInfo.x
    local ny = self.netInfo.y
    local nz = self.netInfo.z
    local cx, cy, cz = localToWorld(self.wheel.node, nx, ny, nz)
    raycastClosestAsync(cx, cy, cz, 0, -1, 0, self.radius + 0.25, "waterRaycastCallback", self, CollisionFlag.WATER)
    local wx, wy, wz = localToWorld(self.wheel.node, nx, ny - self.radius, nz)
    if g_updateLoopIndex - self.wheelShapeCreationFrameIndex > 2 then
        self.wheelShapeCreated = true
        local contactX, contactY, contactZ, _ = getWheelShapeContactPoint(self.wheel.node, self.wheelShape)
        local contactObject = contactX ~= nil
        self.hasGroundContact = contactObject
        if self.hasGroundContact then
            self.lastContactX = contactX
            self.lastContactY = contactY
            self.lastContactZ = contactZ
        end
        local contactObject, _ = getWheelShapeContactObject(self.wheel.node, self.wheelShape)
        if contactObject == 0 then
            self.contact = WheelContactType.NONE
            self.lastContactObjectAllowsTireTracks = false
        elseif getDensityMapHeightTypeAtWorldPos(g_densityMapHeightManager.terrainDetailHeightUpdater, wx, wy, wz, 0) == 0 then
            if contactObject == g_terrainNode then
                self.contact = WheelContactType.GROUND
                self.lastContactObjectAllowsTireTracks = true
            elseif self.hasGroundContact then
                self.contact = WheelContactType.OBJECT
                self.lastContactObjectAllowsTireTracks = entityExists(contactObject) and getRigidBodyType(contactObject) == RigidBodyType.STATIC and getUserAttribute(contactObject, "noTireTracks") ~= true
            else
                self.contact = WheelContactType.NONE
                self.lastContactObjectAllowsTireTracks = false
            end
        else
            self.contact = WheelContactType.GROUND_HEIGHT
            self.lastContactObjectAllowsTireTracks = true
        end
    end
    if self.contact == WheelContactType.GROUND then
        local contactX, contactY, contactZ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        self.densityBits = getDensityAtWorldPos(contactX, wx, wy, wz)
        local contactObject = bit32.rshift(self.densityBits, contactY)
        self.densityType = FieldGroundType.getTypeByValue((bit32.band(contactObject, 2 ^ contactZ - 1)))
    else
        self.densityBits = 0
        self.densityType = FieldGroundType.NONE
    end
    if self.contact == WheelContactType.GROUND_HEIGHT then
        local contactX = getDensityAtWorldPos(mission.terrainDetailHeightId, wx, wy, wz)
        self.hasSnowContact = bit32.band(contactX, 2 ^ g_densityMapHeightManager.heightTypeNumChannels - 1) == mission.snowSystem.snowHeightTypeIndex
    else
        self.hasSnowContact = false
    end
end
function WheelPhysics:updateContactClient()
    local wx, wy, wz = localToWorld(self.wheel.node, self.netInfo.x, self.netInfo.y - self.radius, self.netInfo.z)
    if self.contact == WheelContactType.GROUND then
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        self.densityBits = getDensityAtWorldPos(groundTypeMapId, wx, wy, wz)
        local densityType = bit32.band(bit32.rshift(self.densityBits, groundTypeFirstChannel), 2 ^ groundTypeNumChannels - 1)
        self.densityType = FieldGroundType.getTypeByValue(densityType)
    else
        self.densityBits = 0
        self.densityType = FieldGroundType.NONE
    end
    if self.contact == WheelContactType.GROUND_HEIGHT then
        local groundTypeMapId = getDensityAtWorldPos(mission.terrainDetailHeightId, wx, wy, wz)
        local densityType = bit32.band(groundTypeMapId, 2 ^ g_densityMapHeightManager.heightTypeNumChannels - 1) == mission.snowSystem.snowHeightTypeIndex
        self.hasSnowContact = densityType
    else
        self.hasSnowContact = false
    end
end
function WheelPhysics:updateSink(dt, _)
    if self.wheelShape ~= 0 then
        local sinkTarget = self.sinkTarget
        local lastSpeed = self.vehicle:getLastSpeed()
        local interpolationFactor = 1
        if self.contact == WheelContactType.NONE or lastSpeed <= 0.3 then
            if self.contact == WheelContactType.NONE then
                sinkTarget = 0
                lastSpeed = 10
                interpolationFactor = 0.075
            end
        else
            local sinkTarget = WheelPhysics.MAX_SINK[self.densityType] or 0
            if self.hasWaterContact and sinkTarget ~= 0 then
                sinkTarget = math.max(sinkTarget, WheelPhysics.WATER_SINK)
            end
            sinkTarget = math.min(sinkTarget, self.extraSinkMaxValue)
        end
        if self.sinkTarget < sinkTarget then
            self.sinkTarget = math.min(sinkTarget, self.sinkTarget + 0.05 * math.min(30, (math.max(0, lastSpeed - 0.2))) * (dt / 1000) * interpolationFactor)
        elseif sinkTarget < self.sinkTarget then
            self.sinkTarget = math.max(sinkTarget, self.sinkTarget - 0.05 * math.min(30, (math.max(0, lastSpeed - 0.2))) * (dt / 1000) * interpolationFactor)
        end
        if math.abs(self.sink - self.sinkTarget) > 0.001 then
            self.sink = self.sinkTarget
            local deltaY = self.deltaYOriginal + self.sink
            if deltaY ~= self.deltaY then
                self.deltaY = deltaY
                self.isPositionDirty = true
            end
        end
    end
end
function WheelPhysics:updateFriction(_, groundWetness)
    local snowScale = 0
    if self.hasSnowContact then
        groundWetness = 0
        snowScale = 1
    end
    local coeff = WheelsUtil.getTireFriction(self.tireType, WheelsUtil.getGroundType(self.densityType ~= FieldGroundType.NONE, self.contact ~= WheelContactType.GROUND, self.groundDepth), groundWetness, snowScale)
    if self.vehicle:getLastSpeed() > 0.2 and coeff ~= self.tireGroundFrictionCoeff then
        self.tireGroundFrictionCoeff = coeff
        self.isFrictionDirty = true
    end
end
function WheelPhysics:updateBase()
    if self.vehicle.isServer and self.vehicle.isAddedToPhysics then
        local positionY = self.positionY - self.directionY * self.deltaY
        local positionZ = self.positionZ - self.directionZ * self.deltaY
        if self.wheelShape == 0 then
            self.wheelShapeCreationFrameIndex = g_updateLoopIndex
            self.wheelShapeCreated = false
        end
        self.wheelShape = createWheelShape(self.wheel.node, self.positionX - self.directionX * self.deltaY, positionY, positionZ, self.radius, self.suspTravel, self.spring * self.springMultiplier, self.damperCompressionLowSpeed * self.dampingMultiplier, self.damperCompressionHighSpeed * self.dampingMultiplier, self.damperCompressionLowSpeedThreshold, self.damperRelaxationLowSpeed * self.dampingMultiplier, self.damperRelaxationHighSpeed * self.dampingMultiplier, self.damperRelaxationLowSpeedThreshold, self.wheel:getMass(), WheelPhysics.COLLISION_GROUP, self.collisionMask or (self.configCollisionMask or WheelPhysics.COLLISION_MASK), self.wheelShape)
        local steeringX, steeringY, steeringZ = localToLocal(getParent(self.wheel.repr), self.wheel.node, self.wheel.startPositionX, self.wheel.startPositionY + self.deltaY, self.wheel.startPositionZ)
        setWheelShapeForcePoint(self.wheel.node, self.wheelShape, self.positionX, positionY - self.radius * self.forcePointRatio, positionZ)
        setWheelShapeSteeringCenter(self.wheel.node, self.wheelShape, steeringX, steeringY, steeringZ)
        local direction = self.torqueDirection
        setWheelShapeDirection(self.wheel.node, self.wheelShape, self.directionX, self.directionY, self.directionZ, self.axleX * direction, self.axleY * direction, self.axleZ * direction)
        setWheelShapeWidth(self.wheel.node, self.wheelShape, self.wheelShapeWidth, self.wheelShapeWidthOffset)
        setWheelShapeTerrainDisplacement(self.wheel.node, self.wheelShape, self.displacementAllowed and self.displacementScale or 0)
        self.isPositionDirty = false
    end
end
function WheelPhysics:updateShapePosition()
    self.positionX, self.positionY, self.positionZ = localToLocal(getParent(self.wheel.repr), self.wheel.node, self.wheel.startPositionX - self.steeringCenterOffsetX, self.wheel.startPositionY - self.steeringCenterOffsetY, self.wheel.startPositionZ - self.steeringCenterOffsetZ)
    if self.useReprDirection then
        self.directionX, self.directionY, self.directionZ = localDirectionToLocal(self.wheel.repr, self.wheel.node, 0, -1, 0)
        self.axleX, self.axleY, self.axleZ = localDirectionToLocal(self.wheel.repr, self.wheel.node, 1, 0, 0)
    elseif self.useDriveNodeDirection then
        self.directionX, self.directionY, self.directionZ = localDirectionToLocal(self.wheel.driveNodeDirectionNode, self.wheel.node, 0, -1, 0)
        self.axleX, self.axleY, self.axleZ = localDirectionToLocal(self.wheel.driveNodeDirectionNode, self.wheel.node, 1, 0, 0)
    end
    self.isPositionDirty = true
end
function WheelPhysics:updateTireFriction()
    if self.vehicle.isServer and self.vehicle.isAddedToPhysics then
        setWheelShapeTireFriction(self.wheel.node, self.wheelShape, self.maxLongStiffness, self.maxLatStiffness, self.maxLatStiffnessLoad, self.frictionScale * self.tireGroundFrictionCoeff)
        self.isFrictionDirty = false
    end
end
function WheelPhysics:updatePhysics(brakeForce, torque)
    if self.vehicle.isServer and self.vehicle.isAddedToPhysics then
        setWheelShapeProps(self.wheel.node, self.wheelShape, torque or self.torque, (brakeForce or 0) * self.brakeFactor, self.steeringAngle, self.rotationDamping)
        setWheelShapeAutoHoldBrakeForce(self.wheel.node, self.wheelShape, (brakeForce or 0) * self.autoHoldBrakeFactor)
    end
end
function WheelPhysics:updateNetInfo(_)
    if self.updateWheel then
        if g_physicsDtNonInterpolated ~= 0 then
            local x, y, z, xDrive, suspensionLength = getWheelShapePosition(self.wheel.node, self.wheelShape)
            if self.torqueDirection < 0 then
                self.netInfo.xDrive = self.netInfo.xDrive - (xDrive - self.netInfo.xDriveLastRaw)
            else
                self.netInfo.xDrive = self.netInfo.xDrive + (xDrive - self.netInfo.xDriveLastRaw)
            end
            self.netInfo.xDriveLastRaw = xDrive
            if self.dirtyFlag ~= nil and (self.netInfo.x ~= x or self.netInfo.z ~= z) then
                self.vehicle:raiseDirtyFlags(self.dirtyFlag)
            end
            self.netInfo.x = x
            self.netInfo.y = y
            self.netInfo.z = z
            self.netInfo.suspensionLength = suspensionLength
            self.netInfo.xDriveDiff = 0
            self:updateXDriveSpeed(g_physicsDtNonInterpolated)
        end
    else
        self.updateWheel = true
        return
    end
end
function WheelPhysics:updateSteeringAngle(dt)
    local steeringAngle = self.steeringAngle
    if self.wheel.steering.steeringAxleScale == nil or self.wheel.steering.steeringAxleScale == 0 then
        if self.versatileYRot and self.vehicle:getIsVersatileYRotActive(self.wheel) then
            if self.vehicle.isServer then
                steeringAngle = self:getVersatileYRotation(dt)
            end
        elseif self.rotSpeed ~= 0 and (self.rotMax ~= nil and self.rotMin ~= nil) or self.wheel.forceSteeringAngleUpdate then
            if self.vehicle.rotatedTime > 0 or self.rotSpeedNeg == nil then
                steeringAngle = rotatedTime * self.rotSpeed
            else
                steeringAngle = rotatedTime * self.rotSpeedNeg
            end
            if self.rotMax < steeringAngle then
                steeringAngle = self.rotMax
            elseif steeringAngle < self.rotMin then
                steeringAngle = self.rotMin
            end
            if self.vehicle.customSteeringAngleFunction then
                steeringAngle = self.vehicle:updateSteeringAngle(self.wheel, dt, steeringAngle)
            end
        end
    else
        local steeringAxleAngle = 0
        if self.vehicle.spec_attachable ~= nil then
            steeringAxleAngle = self.vehicle.spec_attachable.steeringAxleAngle
        end
        steeringAngle = math.clamp(steeringAxleAngle * self.wheel.steering.steeringAxleScale, self.wheel.steering.steeringAxleRotMin, self.wheel.steering.steeringAxleRotMax)
    end
    self.steeringAngle = steeringAngle
end
function WheelPhysics:addToPhysics(brakeForce)
    self.netInfo.xDriveLastRaw = 0
    self.updateWheel = false
    self:updateBase()
    self:updateTireFriction()
    self:updatePhysics(brakeForce, 0)
end
function WheelPhysics:removeFromPhysics()
    self.wheelShape = 0
    self.wheelShapeCreationFrameIndex = math.huge
    self.wheelShapeCreated = false
end
function WheelPhysics:setSteeringValues(rotMin, rotMax, rotSpeed, rotSpeedNeg, inverted)
    self.rotMin = rotMin
    self.rotMax = rotMax
    if self.invertRotLimit then
    end
    if inverted then
    end
    self.rotSpeed = rotSpeed
    self.rotSpeedNeg = rotSpeedNeg
end
function WheelPhysics:setWheelShapeWidth(width, offset)
    self.wheelShapeWidth = width or self.wheelShapeWidth
    self.wheelShapeWidthOffset = offset or self.wheelShapeWidthOffset
    self.isPositionDirty = true
end
function WheelPhysics:setTorqueDirection(torqueDirection)
    torqueDirection = torqueDirection >= 0 and 1 or -1
    if torqueDirection ~= self.torqueDirection then
        self.torqueDirection = torqueDirection
        self:updateBase()
    end
end
function WheelPhysics:setDisplacementAllowed(displacementAllowed)
    self.displacementAllowed = displacementAllowed
    if self.vehicle.isServer and self.vehicle.isAddedToPhysics then
        setWheelShapeTerrainDisplacement(self.wheel.node, self.wheelShape, self.displacementAllowed and self.displacementScale or 0)
    end
end
function WheelPhysics:setDisplacementCollisionEnabled(displacementCollisionEnabled)
    self.displacementCollisionEnabled = displacementCollisionEnabled
    if Platform.gameplay.wheelTerrainDisplacement and (self.supportsWheelSink and self.displacementCollisionEnabled) then
        self.collisionMask = nil
    else
        self.collisionMask = bit32.band(self.configCollisionMask or WheelPhysics.COLLISION_MASK, (bit32.bnot(CollisionFlag.TERRAIN_DISPLACEMENT)))
    end
    if self.collisionMask ~= self.collisionMask then
        self:updateBase()
    end
end
function WheelPhysics:setSuspensionMultipliers(springMultiplier, dampingMultiplier)
    self.springMultiplier = springMultiplier or 1
    self.dampingMultiplier = dampingMultiplier or 1
    self.isPositionDirty = true
end
function WheelPhysics:getVisualInfo()
    local steeringAngle = 0
    if self.showSteeringAngle ~= false then
        steeringAngle = self.steeringAngle * self.steeringAngleFactorInv
    end
    return self.netInfo.x, self.netInfo.y, self.netInfo.z, self.netInfo.xDrive, self.netInfo.suspensionLength - self.deltaYOriginal, steeringAngle
end
function WheelPhysics:serverUpdate(dt, currentUpdateIndex, groundWetness)
    if self.vehicle.isActive then
        if currentUpdateIndex == self.wheel.updateIndex then
            self:updateContact()
        end
        if self.extraSinkSupported then
            self:updateSink(dt, groundWetness)
        end
        if self.vehicle.isServer then
            self:updateFriction(dt, groundWetness)
        end
        local brakeForce = 0
        if self.wheel.brakePedal > 0 then
            brakeForce = self.vehicle:getBrakeForce() * self.wheel.brakePedal
        end
        self:updatePhysics(brakeForce)
        self:updateSteeringAngle(dt)
    end
    self:updateNetInfo(dt)
end
function WheelPhysics:clientUpdate(_, currentUpdateIndex, _)
    if self.vehicle.isActive and currentUpdateIndex == self.wheel.updateIndex then
        self:updateContactClient()
    end
end
function WheelPhysics:updateTick(dt, groundWetness, currentUpdateDistance)
    if self.rotSpeedLimit ~= nil then
        local dir = self:getLastSpeed() <= self.rotSpeedLimit and 1 or -1
        self.currentRotSpeedAlpha = math.clamp(self.currentRotSpeedAlpha + dir * (dt / 1000), 0, 1)
        self.rotSpeed = self.rotSpeedDefault * self.currentRotSpeedAlpha
        self.rotSpeedNeg = self.rotSpeedNegDefault * self.currentRotSpeedAlpha
    end
    if currentUpdateDistance < TireTracks.MAX_CREATION_DISTANCE or currentUpdateDistance < WheelEffects.MAX_UPDATE_DISTANCE then
        self.hasSoilContact = false
        local dir, wy, wz = getWorldTranslation(self.wheel.driveNode)
        local targetDirtAmount = 0
        local targetAlpha = 0
        if self.contact == WheelContactType.GROUND then
            local colorBlendWithTerrain = 1
            local depth, t
            if self.densityType ~= FieldGroundType.NONE then
                local r, g, b
                r, g, b, depth = g_currentMission.fieldGroundSystem:getFieldGroundTyreTrackColor(self.densityBits)
                t = 1
                targetDirtAmount = 1
                if self.densityType == FieldGroundType.GRASS then
                    targetDirtAmount = 0.7
                elseif self.densityType == FieldGroundType.GRASS_CUT then
                    targetDirtAmount = 0.6
                else
                    self.hasSoilContact = true
                end
                self.fieldGroundColor[1] = r
                self.fieldGroundColor[2] = g
                self.fieldGroundColor[3] = b
                colorBlendWithTerrain = 0.75
            else
                local r, g, b
                r, g, b, depth, t = getTerrainAttributesAtWorldPos(g_terrainNode, dir, wy, wz, true, true, true, true, false)
                self.groundColor[1] = r
                self.groundColor[2] = g
                self.groundColor[3] = b
                if depth > 0 then
                    targetAlpha = 0.5
                end
            end
            self.groundDepth = depth
            self.colorBlendWithTerrain = colorBlendWithTerrain
            self.lastTerrainAttribute = t
        elseif self.contact == WheelContactType.GROUND_HEIGHT then
            self.groundDepth = 1
            targetAlpha = 1
            self.colorBlendWithTerrain = 0
        elseif self.contact == WheelContactType.OBJECT then
            self.groundDepth = 0
        end
        if targetDirtAmount ~= self.dirtAmount then
            if targetDirtAmount < self.dirtAmount then
                self.dirtAmount = math.max(self.dirtAmount - self.vehicle.lastMovedDistance / (30 * (1 + groundWetness) * (2 - math.min(self.vehicle:getLastSpeed(), 20) / 20)), targetDirtAmount)
            else
                self.dirtAmount = math.min(self.dirtAmount + self.vehicle.lastMovedDistance, targetDirtAmount)
            end
        end
        if targetAlpha ~= self.trackAlpha then
            if self.trackAlpha < targetAlpha then
                self.trackAlpha = math.min(self.trackAlpha + self.vehicle.lastMovedDistance * 2, targetAlpha)
            else
                self.trackAlpha = math.max(self.trackAlpha - self.vehicle.lastMovedDistance * 2, targetAlpha)
            end
        end
        if self.groundDepth > 0 then
            local r = 1
            for r = r, 3 do
                self.trackColor[r] = self.fieldGroundColor[r] * self.dirtAmount + self.groundColor[r] * (1 - self.dirtAmount)
            end
            return
        end
        self.trackColor[1] = self.fieldGroundColor[1]
        self.trackColor[2] = self.fieldGroundColor[2]
        self.trackColor[3] = self.fieldGroundColor[3]
    end
end
function WheelPhysics:postUpdate(_)
    if self.isPositionDirty then
        self:updateBase()
    end
    if self.isFrictionDirty then
        self:updateTireFriction()
    end
end
function WheelPhysics:updateInterpolation(dt, interpolationAlpha)
    self.netInfo.x, self.netInfo.y, self.netInfo.z = self.networkInterpolators.position:getInterpolatedValues(interpolationAlpha)
    self.netInfo.suspensionLength = self.networkInterpolators.suspensionLength:getInterpolatedValue(interpolationAlpha)
    self.netInfo.xDrive = (self.netInfo.xDrive + self.networkInterpolators.xDriveDiff:getInterpolatedValue(interpolationAlpha) * dt) % 6.283185307179586
    self:updateXDriveSpeed(dt)
    self:updateSteeringAngle(dt)
end
function WheelPhysics:updateXDriveSpeed(dt)
    local xDrive = self.netInfo.xDrive
    if self.netInfo.xDriveBefore == nil then
        self.netInfo.xDriveBefore = xDrive
    end
    local xDriveDiff = xDrive - self.netInfo.xDriveBefore
    if xDriveDiff > 3.141592653589793 then
        self.netInfo.xDriveBefore = self.netInfo.xDriveBefore + 6.283185307179586
    elseif xDriveDiff < -3.141592653589793 then
        self.netInfo.xDriveBefore = self.netInfo.xDriveBefore - 6.283185307179586
    end
    self.netInfo.xDriveDiff = (xDrive - self.netInfo.xDriveBefore) / dt
    self.netInfo.xDriveSpeed = self.netInfo.xDriveDiff * 1000
    self.netInfo.xDriveBefore = xDrive
    local speed = MathUtil.rpmToMps(self.netInfo.xDriveSpeed / 6.283185 * 60, self.radius)
    self.netInfo.lastSpeedSmoothed = self.netInfo.lastSpeedSmoothed * 0.9 + speed * 0.1
    self.netInfo.slip = math.clamp(self.netInfo.lastSpeedSmoothed / math.max(self.vehicle.lastSpeedSmoothed, 1e-8), 1, 2) - 1
end
function WheelPhysics:getGroundAttributes()
    return self.trackColor[1], self.trackColor[2], self.trackColor[3], self.groundDepth, self.lastTerrainAttribute, math.max(self.trackAlpha, self.dirtAmount), self.colorBlendWithTerrain
end
function WheelPhysics:getIsOnField()
    local isOnField = self.hasSnowContact
    if self.densityType ~= FieldGroundType.NONE and self.densityType ~= FieldGroundType.GRASS then
    end
    return isOnField
end
function WheelPhysics:getSurfaceSoundAttributes()
    if self.contact == WheelContactType.GROUND then
        if self.hasWaterContact then
            return "shallowWater", nil
        elseif self.densityType == FieldGroundType.NONE then
            return nil, self.lastTerrainAttribute
        else
            return "field", nil
        end
    else
        if self.contact == WheelContactType.GROUND_HEIGHT then
            if self.hasSnowContact then
                return "snow", nil
            end
        elseif self.contact == WheelContactType.OBJECT then
            return "asphalt", nil
        end
        return nil, nil
    end
end
function WheelPhysics:getTireLoad()
    if self.wheelShapeCreated then
        local tireLoad = getWheelShapeContactForce(self.wheel.node, self.wheelShape)
        if tireLoad ~= nil then
            local nx, ny, nz = getWheelShapeContactNormal(self.wheel.node, self.wheelShape)
            local dx, dy, dz = localDirectionToWorld(self.wheel.node, self.directionX, self.directionY, self.directionZ)
            local tireLoad = -tireLoad * MathUtil.dotProduct(dx, dy, dz, nx, ny, nz)
            return (tireLoad + math.max(ny * 9.81, 0) * self.wheel:getMass()) / 9.81
        end
    end
    return 0
end
function WheelPhysics:getVersatileYRotation(dt)
    if self.forceVersatility or self.hasGroundContact then
        return Utils.getVersatileRotation(self.wheel.repr, self.wheel.node, dt, self.positionX, self.positionY, self.positionZ, self.steeringAngle, self.rotMin, self.rotMax)
    end
    if self.versatileYRotSpring == nil then
        return self.steeringAngle
    end
    local mass = self.mass * 1000
    local velocityX, velocityY, velocityZ = getVelocityAtLocalPos(self.wheel.node, self.positionX, self.positionY, self.positionZ)
    local velocityX = velocityX * mass
    local velocityY = velocityY * mass
    local velocityZ = velocityZ * mass
    if self.versatileYRotLastVelocity == nil then
        self.versatileYRotLastVelocity = { velocityX, velocityY, velocityZ }
    end
    local invDt = 1 / (dt * 0.001)
    self.versatileYRotLastVelocity[1] = velocityX
    self.versatileYRotLastVelocity[2] = velocityY
    self.versatileYRotLastVelocity[3] = velocityZ
    local localX, _, localZ = worldDirectionToLocal(getParent(self.wheel.repr), -((velocityX - self.versatileYRotLastVelocity[1]) * invDt * 0.2), -((velocityY - self.versatileYRotLastVelocity[2]) * invDt * 0.2) - 9.81 * mass, -((velocityZ - self.versatileYRotLastVelocity[3]) * invDt * 0.2))
    local localLength = MathUtil.vector2Length(localX, localZ)
    local targetRotY = (MathUtil.getYRotationFromDirection(localX, localZ) + 3.141592653589793) % 6.283185307179586
    local rotio = MathUtil.normalizeRotationForShortestPath(targetRotY, self.steeringAngle % 6.283185307179586)
    local rotio = math.clamp(localLength / gravityForceY, 0, 1)
    local drive = self.versatileYRotSpring * ((rotio - steeringAngle) * rotio) - self.versatileYRotDamping * self.versatileYRotSpeed
    local drive
    if math.abs(self.versatileYRotSpeed) < 0.00001 then
        if math.abs(drive) <= self.versatileYRotFriction[1] then
            drive = 0
            self.versatileYRotSpeed = 0
        else
            drive = drive - math.sign(drive) * self.versatileYRotFriction[2]
        end
    else
        drive = drive - math.sign(self.versatileYRotSpeed) * dynamicFriction
    end
    self.versatileYRotSpeed = self.versatileYRotSpeed + drive * dt
    return steeringAngle + self.versatileYRotSpeed * dt
end
function WheelPhysics:waterRaycastCallback(actorId, x, y, z, _, _, _, _, _, _, isLast, ...)
    if actorId == 0 then
        if isLast then
            self.hasWaterContact = false
        end
    else
        self.hasWaterContact = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) < y
    end
end
function WheelPhysics.registerXMLPaths(schema, key)
    schema:register(XMLValueType.FLOAT, key .. ".physics#xOffset", "Moves the default position of the drive node on the X axis", 0)
    schema:register(XMLValueType.FLOAT, key .. ".physics#yOffset", "Moves the default position of the drive node on the Y axis", 0)
    schema:register(XMLValueType.FLOAT, key .. ".physics#zOffset", "Moves the default position of the drive node on the Z axis", 0)
    schema:register(XMLValueType.BOOL, key .. ".physics#useReprOffset", "Defines if the x/y/z offset attribute is applied to the repr or driveNode", false)
    schema:register(XMLValueType.BOOL, key .. ".physics#showSteeringAngle", "Show steering angle", true)
    schema:register(XMLValueType.FLOAT, key .. ".physics#steeringAngleFactor", "Scale factor for physics steering angle to steer more than the visuals show", 1)
    schema:register(XMLValueType.ANGLE, key .. ".physics#startSteeringAngle", "Default steering angle after loading of the vehicle", 0)
    schema:register(XMLValueType.FLOAT, key .. ".physics#suspTravel", "Suspension travel", 0.01)
    schema:register(XMLValueType.FLOAT, key .. ".physics#initialCompression", "Initial compression value")
    schema:register(XMLValueType.FLOAT, key .. ".physics#deltaY", "Delta Y", 0)
    schema:register(XMLValueType.FLOAT, key .. ".physics#spring", "Spring", 0)
    schema:register(XMLValueType.FLOAT, key .. ".physics#brakeFactor", "Brake factor", 1)
    schema:register(XMLValueType.FLOAT, key .. ".physics#autoHoldBrakeFactor", "Auto hold brake factor", "brakeFactor")
    schema:register(XMLValueType.FLOAT, key .. ".physics#damper", "Damper", 0)
    schema:register(XMLValueType.FLOAT, key .. ".physics#damperCompressionLowSpeed", "Damper compression on low speeds")
    schema:register(XMLValueType.FLOAT, key .. ".physics#damperCompressionHighSpeed", "Damper compression on high speeds")
    schema:register(XMLValueType.FLOAT, key .. ".physics#damperCompressionLowSpeedThreshold", "Damper compression on low speeds threshold", 0.1016)
    schema:register(XMLValueType.FLOAT, key .. ".physics#damperRelaxationLowSpeed", "Damper relaxation on low speeds")
    schema:register(XMLValueType.FLOAT, key .. ".physics#damperRelaxationHighSpeed", "Damper relaxation on high speeds")
    schema:register(XMLValueType.FLOAT, key .. ".physics#damperRelaxationLowSpeedThreshold", "Damper relaxation on low speeds threshold", 0.1524)
    schema:register(XMLValueType.FLOAT, key .. ".physics#forcePointRatio", "Force point ratio", 0)
    schema:register(XMLValueType.INT, key .. ".physics#driveMode", "Drive mode", 0)
    schema:register(XMLValueType.BOOL, key .. ".physics#isSynchronized", "Wheel is synchronized in multiplayer", true)
    schema:register(XMLValueType.INT, key .. ".physics#tipOcclusionAreaGroupId", "Tip occlusion area group id")
    schema:register(XMLValueType.BOOL, key .. ".physics#useReprDirection", "Use repr direction instead of component direction", false)
    schema:register(XMLValueType.BOOL, key .. ".physics#useDriveNodeDirection", "Use drive node direction instead of component direction", false)
    schema:register(XMLValueType.FLOAT, key .. ".physics#mass", "Wheel mass (to.)", 0.1)
    schema:register(XMLValueType.FLOAT, key .. ".physics#radius", "Wheel radius", 0.5)
    schema:register(XMLValueType.FLOAT, key .. ".physics#width", "Wheel width", 0.6)
    schema:register(XMLValueType.FLOAT, key .. ".physics#visualOffset", "Radius offset of visual wheel in percentage (0-1). Not used on the game.")
    schema:register(XMLValueType.FLOAT, key .. ".physics#widthOffset", "Wheel width offset", 0)
    schema:register(XMLValueType.FLOAT, key .. ".physics#restLoad", "Wheel load while resting", 1)
    schema:register(XMLValueType.FLOAT, key .. ".physics#maxLongStiffness", "Max. longitude stiffness")
    schema:register(XMLValueType.FLOAT, key .. ".physics#maxLatStiffness", "Max. latitude stiffness")
    schema:register(XMLValueType.FLOAT, key .. ".physics#maxLatStiffnessLoad", "Max. latitude stiffness load")
    schema:register(XMLValueType.FLOAT, key .. ".physics#frictionScale", "Wheel friction scale", 1)
    schema:register(XMLValueType.FLOAT, key .. ".physics#rotationDamping", "Rotation damping ", "mass * 0.035")
    schema:register(XMLValueType.STRING, key .. ".physics#tireType", "Tire type (mud, offRoad, street, crawler)")
    schema:register(XMLValueType.FLOAT, key .. ".physics#fieldDirtMultiplier", "Field dirt multiplier", 75)
    schema:register(XMLValueType.FLOAT, key .. ".physics#streetDirtMultiplier", "Street dirt multiplier", -150)
    schema:register(XMLValueType.FLOAT, key .. ".physics#waterWetnessFactor", "Factor for wheel wetness while driving in water", 20)
    schema:register(XMLValueType.FLOAT, key .. ".physics#minDirtPercentage", "Min. dirt scale while cleaning on street drive", 0.35)
    schema:register(XMLValueType.FLOAT, key .. ".physics#maxDirtOffset", "Max. dirt amount offset to global dirt node", 0.5)
    schema:register(XMLValueType.FLOAT, key .. ".physics#dirtColorChangeSpeed", "Defines speed to change the dirt color (sec)", 20)
    schema:register(XMLValueType.BOOL, key .. ".physics#versatileYRot", "Do versatile Y rotation", false)
    schema:register(XMLValueType.ANGLE, key .. ".physics#versatileYRotSpring", "Spring value while wheels does not have ground contact")
    schema:register(XMLValueType.ANGLE, key .. ".physics#versatileYRotDamping", "Damping value while wheels does not have ground contact")
    schema:register(XMLValueType.VECTOR_2, key .. ".physics#versatileYRotFriction", "Static and dynamic friction values while wheels does not have ground contact", "0.0000015 0.0000010")
    schema:register(XMLValueType.BOOL, key .. ".physics#forceVersatility", "Force versatility, also if no ground contact", false)
    schema:register(XMLValueType.BOOL, key .. ".physics#supportsWheelSink", "The wheel is allowed to deform the terrain displacement collision and \'sink\' into the terrain", true)
    schema:register(XMLValueType.INT, key .. ".physics#collisionMask", "Custom collision mask for the wheel")
    schema:register(XMLValueType.BOOL, key .. ".physics.extraSink#supported", "Additional sinking into the terrain independent of the adjustment of the terrain displacement. (FS22 in prior style)", false)
    schema:register(XMLValueType.FLOAT, key .. ".physics.extraSink#maxValue", "Max. sink value in meter", "20% of the wheel radius")
    schema:register(XMLValueType.ANGLE, key .. ".physics#rotSpeed", "Rotation speed")
    schema:register(XMLValueType.ANGLE, key .. ".physics#rotSpeedNeg", "Rotation speed in negative direction")
    schema:register(XMLValueType.ANGLE, key .. ".physics#rotMax", "Max. rotation")
    schema:register(XMLValueType.ANGLE, key .. ".physics#rotMin", "Min. rotation")
    schema:register(XMLValueType.BOOL, key .. ".physics#invertRotLimit", "Invert the rotation limits")
    schema:register(XMLValueType.FLOAT, key .. ".physics#rotSpeedLimit", "Rotation speed limit")
    schema:register(XMLValueType.FLOAT, key .. ".physics#maxInnerSpacing", "Defines a maximum spacing to the inside which is now allowed to be exceeded by the tire, if so, the tire will be moved out automatically")
end
function WheelPhysics.registerAdditionalWheelXMLPaths(schema, key)
    schema:register(XMLValueType.FLOAT, key .. ".physics#mass", "Wheel mass (to.)", 0)
    schema:register(XMLValueType.FLOAT, key .. ".physics#maxLongStiffness", "Max. longitude stiffness")
    schema:register(XMLValueType.FLOAT, key .. ".physics#maxLatStiffness", "Max. latitude stiffness")
end