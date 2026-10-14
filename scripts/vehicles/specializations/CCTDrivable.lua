CCTDrivable = {}
function CCTDrivable.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Enterable, specializations)
end
function CCTDrivable.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("CCTDrivable")
    schema:register(XMLValueType.FLOAT, "vehicle.cctDrivable#cctRadius", "CCT radius", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.cctDrivable#cctHeight", "CCT height", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.cctDrivable#cctSlopeLimit", "CCT slope limit", 25)
    schema:register(XMLValueType.FLOAT, "vehicle.cctDrivable#cctStepOffset", "CCT step offset", 0.35)
    schema:setXMLSpecializationType()
end
function CCTDrivable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getTouchingNode", CCTDrivable.getTouchingNode)
    SpecializationUtil.registerFunction(vehicleType, "moveCCTExternal", CCTDrivable.moveCCTExternal)
    SpecializationUtil.registerFunction(vehicleType, "moveCCT", CCTDrivable.moveCCT)
    SpecializationUtil.registerFunction(vehicleType, "getIsCCTOnGround", CCTDrivable.getIsCCTOnGround)
    SpecializationUtil.registerFunction(vehicleType, "getCCTCollisionMask", CCTDrivable.getCCTCollisionMask)
    SpecializationUtil.registerFunction(vehicleType, "getCCTWorldTranslation", CCTDrivable.getCCTWorldTranslation)
end
function CCTDrivable.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", CCTDrivable.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPosition", CCTDrivable.setWorldPosition)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPositionQuaternion", CCTDrivable.setWorldPositionQuaternion)
end
function CCTDrivable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", CCTDrivable)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", CCTDrivable)
end
function CCTDrivable:onLoad(_)
    local spec = self.spec_cctdrivable
    spec.cctRadius = self.xmlFile:getValue("vehicle.cctDrivable#cctRadius", 1)
    spec.cctHeight = self.xmlFile:getValue("vehicle.cctDrivable#cctHeight", 1)
    spec.cctSlopeLimit = self.xmlFile:getValue("vehicle.cctDrivable#cctSlopeLimit", 25)
    spec.cctStepOffset = self.xmlFile:getValue("vehicle.cctDrivable#cctStepOffset", 0.3)
    spec.cctCenterOffset = -spec.cctRadius
    spec.kinematicCollisionGroup = CollisionFlag.ANIMAL + CollisionFlag.CAMERA_BLOCKING
    spec.kinematicCollisionMask = CollisionMask.ALL - bit32.bor(CollisionFlag.VEHICLE, CollisionFlag.ANIMAL, CollisionFlag.PLAYER, CollisionFlag.WATER, CollisionFlag.AI_BLOCKING, CollisionFlag.GROUND_TIP_BLOCKING, CollisionFlag.PLACEMENT_BLOCKING, CollisionFlag.CAMERA_BLOCKING, CollisionFlag.PRECIPITATION_BLOCKING, CollisionFlag.ANIMAL_NAV_MESH_BLOCKING, CollisionFlag.TERRAIN_DISPLACEMENT)
    spec.movementCollisionGroup = spec.kinematicCollisionGroup
    spec.movementCollisionMask = CollisionMask.ALL - bit32.bor(CollisionFlag.TRIGGER, CollisionFlag.WATER, CollisionFlag.AI_BLOCKING, CollisionFlag.GROUND_TIP_BLOCKING, CollisionFlag.PLACEMENT_BLOCKING, CollisionFlag.CAMERA_BLOCKING, CollisionFlag.PRECIPITATION_BLOCKING, CollisionFlag.ANIMAL_NAV_MESH_BLOCKING, CollisionFlag.TERRAIN_DISPLACEMENT)
    if self.isServer then
        spec.cctNode = createTransformGroup("cctDrivable")
        link(getRootNode(), spec.cctNode)
    end
end
function CCTDrivable:onDelete()
    local spec = self.spec_cctdrivable
    if spec.controllerIndex ~= nil then
        removeCCT(spec.controllerIndex)
        delete(spec.cctNode)
    end
end
function CCTDrivable:moveCCT(moveX, moveY, moveZ)
    if self.isServer then
        local spec = self.spec_cctdrivable
        moveCCT(spec.controllerIndex, moveX, moveY, moveZ, spec.movementCollisionGroup, spec.movementCollisionMask)
        self:raiseActive()
    end
end
function CCTDrivable:moveCCTExternal(moveX, moveY, moveZ)
    self:moveCCT(moveX, moveY, moveZ)
end
function CCTDrivable:getTouchingNode()
    local spec = self.spec_cctdrivable
    local node = 0
    if spec.controllerIndex ~= nil then
        node = getCCTGroundObject(spec.controllerIndex)
    end
    if node == 0 or not node then
        node = nil
    end
    return node
end
function CCTDrivable:getIsCCTOnGround()
    if not self.isServer then
        return false
    end
    local _, _, isOnGround = getCCTCollisionFlags(self.spec_cctdrivable.controllerIndex)
    return isOnGround
end
function CCTDrivable:getCCTCollisionMask()
    return self.spec_cctdrivable.kinematicCollisionMask
end
function CCTDrivable:getCCTWorldTranslation()
    local spec = self.spec_cctdrivable
    local cctX, cctY, cctZ = getTranslation(spec.cctNode)
    return cctX, cctY + spec.cctCenterOffset, cctZ
end
function CCTDrivable:setWorldPosition(superFunc, x, y, z, xRot, yRot, zRot, i, changeInterp)
    superFunc(self, x, y, z, xRot, yRot, zRot, i, changeInterp)
    if self.isServer and i == 1 then
        local spec = self.spec_cctdrivable
        setTranslation(spec.cctNode, x, y - spec.cctCenterOffset, z)
    end
end
function CCTDrivable:setWorldPositionQuaternion(superFunc, x, y, z, qx, qy, qz, qw, i, changeInterp)
    superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)
    if self.isServer and i == 1 then
        local spec = self.spec_cctdrivable
        setTranslation(spec.cctNode, x, y - spec.cctCenterOffset, z)
    end
end
function CCTDrivable:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    if self.isServer then
        local spec = self.spec_cctdrivable
        if spec.controllerIndex ~= nil then
            removeCCT(spec.controllerIndex)
        end
        spec.controllerIndex = createCCT(spec.cctNode, spec.cctRadius, spec.cctHeight, spec.cctStepOffset, spec.cctSlopeLimit, 0.2, spec.kinematicCollisionGroup, spec.kinematicCollisionMask, self.components[1].defaultMass * 1000)
        setCCTPairCollision(spec.controllerIndex, self.rootNode, false)
    end
    return true
end