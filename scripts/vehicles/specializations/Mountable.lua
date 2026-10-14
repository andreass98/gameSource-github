Mountable = {}
Mountable.FORCE_LIMIT_UPDATE_TIME = 1000
Mountable.FORCE_LIMIT_RAYCAST_DISTANCE = 20
source("dataS/scripts/vehicles/specializations/events/MountableSetMountTypeEvent.lua")
function Mountable.prerequisitesPresent(specializations)
    return true
end
function Mountable.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Mountable")
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMount#forceLimitScale", "Force limit scale", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMount#triggerNode", "Trigger node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMount#jointNode", "Joint node")
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMount#triggerForceAcceleration", "Trigger force acceleration", 4)
    schema:register(XMLValueType.BOOL, "vehicle.dynamicMount#singleAxisFreeY", "Single axis free Y")
    schema:register(XMLValueType.BOOL, "vehicle.dynamicMount#singleAxisFreeX", "Single axis free X")
    schema:register(XMLValueType.BOOL, "vehicle.dynamicMount#allowFoldingWhileMounted", "Allow folding while vehicle is mounted", false)
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMount#jointTransY", "Fixed Y translation of local placed joint", "not defined")
    schema:register(XMLValueType.BOOL, "vehicle.dynamicMount#jointLimitToRotY", "Local placed joint will only be adjusted on Y axis to the target mounter object. X and Z will be 0.", false)
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMount#additionalMountDistance", "Distance from root node to the object laying on top (normally height of object). If defined the mass of this object has influence in mounting.", 0)
    schema:register(XMLValueType.BOOL, "vehicle.dynamicMount#allowMassReduction", "Defines if mass can be reduced by the mount vehicle", true)
    schema:register(XMLValueType.STRING, "vehicle.dynamicMount.lockPosition(?)#xmlFilename", "XML filename of vehicle to lock on (needs to match only the end of the filename)")
    schema:register(XMLValueType.STRING, "vehicle.dynamicMount.lockPosition(?)#jointNode", "Joint node of other vehicle (path or i3dMapping name)", "vehicle root node")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.dynamicMount.lockPosition(?)#transOffset", "Translation offset from joint node", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.dynamicMount.lockPosition(?)#rotOffset", "Rotation offset from joint node", "0 0 0")
    schema:setXMLSpecializationType()
end
function Mountable.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onDynamicMountTypeChanged")
end
function Mountable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getSupportsMountDynamic", Mountable.getSupportsMountDynamic)
    SpecializationUtil.registerFunction(vehicleType, "getSupportsMountKinematic", Mountable.getSupportsMountKinematic)
    SpecializationUtil.registerFunction(vehicleType, "onDynamicMountJointBreak", Mountable.onDynamicMountJointBreak)
    SpecializationUtil.registerFunction(vehicleType, "mountableTriggerCallback", Mountable.mountableTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "mount", Mountable.mount)
    SpecializationUtil.registerFunction(vehicleType, "unmount", Mountable.unmount)
    SpecializationUtil.registerFunction(vehicleType, "mountKinematic", Mountable.mountKinematic)
    SpecializationUtil.registerFunction(vehicleType, "unmountKinematic", Mountable.unmountKinematic)
    SpecializationUtil.registerFunction(vehicleType, "mountDynamic", Mountable.mountDynamic)
    SpecializationUtil.registerFunction(vehicleType, "unmountDynamic", Mountable.unmountDynamic)
    SpecializationUtil.registerFunction(vehicleType, "getAdditionalMountingDistance", Mountable.getAdditionalMountingDistance)
    SpecializationUtil.registerFunction(vehicleType, "getAdditionalMountingMass", Mountable.getAdditionalMountingMass)
    SpecializationUtil.registerFunction(vehicleType, "updateDynamicMountJointForceLimit", Mountable.updateDynamicMountJointForceLimit)
    SpecializationUtil.registerFunction(vehicleType, "additionalMountingMassRaycastCallback", Mountable.additionalMountingMassRaycastCallback)
    SpecializationUtil.registerFunction(vehicleType, "getMountObject", Mountable.getMountObject)
    SpecializationUtil.registerFunction(vehicleType, "getDynamicMountObject", Mountable.getDynamicMountObject)
    SpecializationUtil.registerFunction(vehicleType, "setReducedComponentMass", Mountable.setReducedComponentMass)
    SpecializationUtil.registerFunction(vehicleType, "getAllowComponentMassReduction", Mountable.getAllowComponentMassReduction)
    SpecializationUtil.registerFunction(vehicleType, "getDefaultAllowComponentMassReduction", Mountable.getDefaultAllowComponentMassReduction)
    SpecializationUtil.registerFunction(vehicleType, "getMountableLockPositions", Mountable.getMountableLockPositions)
    SpecializationUtil.registerFunction(vehicleType, "setDynamicMountType", Mountable.setDynamicMountType)
    SpecializationUtil.registerFunction(vehicleType, "addMountStateChangeListener", Mountable.addMountStateChangeListener)
    SpecializationUtil.registerFunction(vehicleType, "removeMountStateChangeListener", Mountable.removeMountStateChangeListener)
end
function Mountable.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", Mountable.getIsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getOwnerConnection", Mountable.getOwnerConnection)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "findRootVehicle", Mountable.findRootVehicle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", Mountable.getIsMapHotspotVisible)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", Mountable.getAdditionalComponentMass)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPositionQuaternion", Mountable.setWorldPositionQuaternion)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Mountable.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Mountable.removeFromPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Mountable.getIsFoldAllowed)
end
function Mountable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Mountable)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Mountable)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Mountable)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Mountable)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Mountable)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", Mountable)
end
function Mountable:onLoad(_)
    local spec = self.spec_mountable
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicMount#triggerIndex", "vehicle.dynamicMount#triggerNode")
    spec.dynamicMountJointIndex = nil
    spec.dynamicMountObject = nil
    self.dynamicMountObjectActorId = nil
    spec.dynamicMountForceLimitScale = self.xmlFile:getValue("vehicle.dynamicMount#forceLimitScale", 1)
    spec.componentNode = self.rootNode
    spec.dynamicMountTriggerId = self.xmlFile:getValue("vehicle.dynamicMount#triggerNode", nil, self.components, self.i3dMappings)
    if spec.dynamicMountTriggerId ~= nil then
        if self.isServer then
            addTrigger(spec.dynamicMountTriggerId, "mountableTriggerCallback", self)
        end
        spec.componentNode = self:getParentComponent(spec.dynamicMountTriggerId)
        if spec.dynamicMountJointNodeDynamic == nil then
            spec.dynamicMountJointNodeDynamic = createTransformGroup("dynamicMountJointNodeDynamic")
            link(spec.componentNode, spec.dynamicMountJointNodeDynamic)
        end
        spec.dynamicMountJointTransY = self.xmlFile:getValue("vehicle.dynamicMount#jointTransY")
        spec.dynamicMountJointLimitToRotY = self.xmlFile:getValue("vehicle.dynamicMount#jointLimitToRotY", false)
    end
    spec.jointNode = self.xmlFile:getValue("vehicle.dynamicMount#jointNode", nil, self.components, self.i3dMappings)
    spec.dynamicMountTriggerForceAcceleration = self.xmlFile:getValue("vehicle.dynamicMount#triggerForceAcceleration", 4)
    spec.dynamicMountSingleAxisFreeY = self.xmlFile:getValue("vehicle.dynamicMount#singleAxisFreeY")
    spec.dynamicMountSingleAxisFreeX = self.xmlFile:getValue("vehicle.dynamicMount#singleAxisFreeX")
    spec.dynamicMountAllowFoldingWhileMounted = self.xmlFile:getValue("vehicle.dynamicMount#allowFoldingWhileMounted", false)
    spec.additionalMountDistance = self.xmlFile:getValue("vehicle.dynamicMount#additionalMountDistance", 0)
    spec.forceLimitUpdate = {}
    spec.forceLimitUpdate.raycastActive = false
    spec.forceLimitUpdate.timer = 0
    spec.forceLimitUpdate.lastDistance = 0
    spec.forceLimitUpdate.nextMountingDistance = 0
    spec.forceLimitUpdate.additionalMass = 0
    spec.forceLimitUpdate.isAllowed = false
    spec.allowMassReduction = self.xmlFile:getValue("vehicle.dynamicMount#allowMassReduction", self:getDefaultAllowComponentMassReduction())
    spec.reducedComponentMass = false
    spec.lockPositions = {}
    self.xmlFile:iterate("vehicle.dynamicMount.lockPosition", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {
            ["xmlFilename"] = self.xmlFile:getValue(key .. "#xmlFilename"),
            ["jointNode"] = self.xmlFile:getValue(key .. "#jointNode", "0>")
        }
        if entry.xmlFilename == nil or entry.jointNode == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid lock position \'%s\'. Missing xmlFilename or jointNode!", key)
        else
            entry.xmlFilename = entry.xmlFilename:gsub("$data", "data")
            entry.transOffset = self.xmlFile:getValue(key .. "#transOffset", "0 0 0", true)
            entry.rotOffset = self.xmlFile:getValue(key .. "#rotOffset", "0 0 0", true)
            table.insert(spec.lockPositions, entry)
        end
    end)
    self.dynamicMountType = MountableObject.MOUNT_TYPE_NONE
    self.dynamicMountObjectId = nil
    spec.mountStateChangeListeners = {}
end
function Mountable:onDelete()
    local spec = self.spec_mountable
    local mountObject = self:getDynamicMountObject()
    if mountObject ~= nil and mountObject.onUnmountObject ~= nil then
        mountObject:onUnmountObject(self)
    end
    if spec.dynamicMountJointIndex ~= nil then
        removeJointBreakReport(spec.dynamicMountJointIndex)
        removeJoint(spec.dynamicMountJointIndex)
    end
    if spec.dynamicMountObject ~= nil then
        spec.dynamicMountObject:removeDynamicMountedObject(self, true)
    end
    if spec.dynamicMountTriggerId ~= nil then
        removeTrigger(spec.dynamicMountTriggerId)
    end
end
function Mountable:onReadStream(streamId, _)
    self:setDynamicMountType(streamReadUIntN(streamId, MountableObject.MOUNT_TYPE_SEND_NUM_BITS), nil, true)
end
function Mountable:onWriteStream(streamId, _)
    streamWriteUIntN(streamId, self.spec_mountable.dynamicMountType, MountableObject.MOUNT_TYPE_SEND_NUM_BITS)
end
function Mountable:onUpdate(dt, _, _, _)
    if self.isServer then
        local spec = self.spec_mountable
        if spec.dynamicMountObjectTriggerCount ~= nil and spec.dynamicMountObjectTriggerCount <= 0 then
            if spec.dynamicMountJointNodeDynamicRefNode == nil then
                self:unmountDynamic()
                spec.dynamicMountObjectTriggerCount = nil
            else
                local _, _, zOffset = localToLocal(spec.dynamicMountJointNodeDynamic, spec.dynamicMountJointNodeDynamicRefNode, 0, 0, 0)
                if spec.dynamicMountJointNodeDynamicMountOffset < zOffset then
                    spec.dynamicMountJointNodeDynamicMountOffset = nil
                    spec.dynamicMountJointNodeDynamicRefNode = nil
                    self:unmountDynamic()
                    spec.dynamicMountObjectTriggerCount = nil
                else
                    self:raiseActive()
                end
            end
        end
        if self.dynamicMountJointIndex ~= nil and spec.forceLimitUpdate.isAllowed then
            self:updateDynamicMountJointForceLimit(dt)
        end
    end
end
function Mountable:getSupportsMountDynamic()
    return self.spec_mountable.dynamicMountForceLimitScale ~= nil
end
function Mountable:getSupportsMountKinematic()
    return #self.components == 1
end
function Mountable:onDynamicMountJointBreak(jointIndex, _)
    if jointIndex == self.spec_mountable.dynamicMountJointIndex then
        self:unmountDynamic()
    end
    return false
end
function Mountable:mountableTriggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    if onEnter then
        local vehicle = g_currentMission.nodeToObject[otherActorId]
        if vehicle ~= nil and vehicle.spec_dynamicMountAttacher ~= nil then
            local dynamicMountAttacher = vehicle.spec_dynamicMountAttacher
            if dynamicMountAttacher ~= nil and dynamicMountAttacher.dynamicMountAttacherNode ~= nil then
                if self.dynamicMountObjectActorId == nil then
                    self:mountDynamic(vehicle, otherActorId, dynamicMountAttacher.dynamicMountAttacherNode, DynamicMountUtil.TYPE_FORK, self.spec_mountable.dynamicMountTriggerForceAcceleration * dynamicMountAttacher.dynamicMountAttacherForceLimitScale)
                    spec.dynamicMountObjectTriggerCount = 1
                    return
                end
                if otherActorId ~= self.dynamicMountObjectActorId and spec.dynamicMountObjectTriggerCount == nil then
                    self:unmountDynamic()
                    self:mountDynamic(vehicle, otherActorId, dynamicMountAttacher.dynamicMountAttacherNode, DynamicMountUtil.TYPE_FORK, spec.dynamicMountTriggerForceAcceleration * dynamicMountAttacher.dynamicMountAttacherForceLimitScale)
                    spec.dynamicMountObjectTriggerCount = 1
                    return
                end
                if otherActorId == self.dynamicMountObjectActorId and spec.dynamicMountObjectTriggerCount ~= nil then
                    spec.dynamicMountObjectTriggerCount = spec.dynamicMountObjectTriggerCount + 1
                    return
                end
            end
        end
    elseif onLeave and (otherActorId == self.dynamicMountObjectActorId and spec.dynamicMountObjectTriggerCount ~= nil) then
        spec.dynamicMountObjectTriggerCount = spec.dynamicMountObjectTriggerCount - 1
        if spec.dynamicMountJointNodeDynamic == nil and spec.dynamicMountObjectTriggerCount == 0 then
            self:unmountDynamic()
            spec.dynamicMountObjectTriggerCount = nil
        end
    end
end
function Mountable:mount(object, node, x, y, z, rx, ry, rz)
    local spec = self.spec_mountable
    self:unmountDynamic(true)
    if self.dynamicMountType == MountableObject.MOUNT_TYPE_NONE then
        removeFromPhysics(spec.componentNode)
    end
    link(node, spec.componentNode)
    local wx, wy, wz = localToWorld(node, x, y, z)
    local wqx, wqy, wqz, wqw = mathEulerToQuaternion(localRotationToWorld(node, rx, ry, rz))
    self:setWorldPositionQuaternion(wx, wy, wz, wqx, wqy, wqz, wqw, 1, true)
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_DEFAULT, object)
end
function Mountable:unmount(noEventSend)
    local spec = self.spec_mountable
    if self.dynamicMountType ~= MountableObject.MOUNT_TYPE_DEFAULT then
        return false
    end
    local mountObject = self:getDynamicMountObject()
    if mountObject ~= nil and mountObject.onUnmountObject ~= nil then
        mountObject:onUnmountObject(self)
    end
    local x, y, z = getWorldTranslation(spec.componentNode)
    local qx, qy, qz, qw = getWorldQuaternion(spec.componentNode)
    link(getRootNode(), spec.componentNode)
    self:setWorldPositionQuaternion(x, y, z, qx, qy, qz, qw, 1, true)
    addToPhysics(spec.componentNode)
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE, nil, noEventSend)
    return true
end
function Mountable:mountKinematic(object, node, x, y, z, rx, ry, rz)
    local spec = self.spec_mountable
    self:unmountDynamic(true)
    removeFromPhysics(spec.componentNode)
    if self.isServer then
        setRigidBodyType(spec.componentNode, RigidBodyType.KINEMATIC)
        self.components[1].isKinematic = true
        self.components[1].isDynamic = false
    end
    link(node, spec.componentNode)
    local wx, wy, wz = localToWorld(node, x, y, z)
    local wqx, wqy, wqz, wqw = mathEulerToQuaternion(localRotationToWorld(node, rx, ry, rz))
    self:setWorldPositionQuaternion(wx, wy, wz, wqx, wqy, wqz, wqw, 1, true)
    addToPhysics(spec.componentNode)
    if object.getParentComponent ~= nil then
        local componentNode = object:getParentComponent(node)
        if getRigidBodyType(componentNode) == RigidBodyType.DYNAMIC then
            setPairCollision(componentNode, spec.componentNode, false)
        end
    end
    spec.mountJointNode = node
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_KINEMATIC, object)
end
function Mountable:unmountKinematic()
    local spec = self.spec_mountable
    if self.dynamicMountType ~= MountableObject.MOUNT_TYPE_KINEMATIC then
        return false
    end
    local mountObject = self:getDynamicMountObject()
    if mountObject ~= nil then
        if mountObject.getParentComponent ~= nil then
            local componentNode = mountObject:getParentComponent(spec.mountJointNode)
            if getRigidBodyType(componentNode) == RigidBodyType.DYNAMIC then
                setPairCollision(componentNode, spec.componentNode, true)
            end
        end
        if mountObject.onUnmountObject ~= nil then
            mountObject:onUnmountObject(self)
        end
    end
    spec.mountJointNode = nil
    local componentNode, y, z = getWorldTranslation(spec.componentNode)
    local qx, qy, qz, qw = getWorldQuaternion(spec.componentNode)
    removeFromPhysics(spec.componentNode)
    link(getRootNode(), spec.componentNode)
    self:setWorldPositionQuaternion(componentNode, y, z, qx, qy, qz, qw, 1, true)
    addToPhysics(spec.componentNode)
    if self.isServer then
        setRigidBodyType(spec.componentNode, RigidBodyType.DYNAMIC)
        self.components[1].isKinematic = false
        self.components[1].isDynamic = true
    end
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
    return true
end
function Mountable:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
    local spec = self.spec_mountable
    if not self:getSupportsMountDynamic() or (self:getDynamicMountObject() ~= nil or self.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE) then
        return false
    end
    local dynamicMountSpec = self.spec_dynamicMountAttacher
    if dynamicMountSpec ~= nil then
        for _, mountedObject in pairs(dynamicMountSpec.dynamicMountedObjects) do
            if mountedObject:isa(Vehicle) and mountedObject.rootVehicle == object.rootVehicle then
                return false
            end
        end
    end
    if object.rootVehicle == self.rootVehicle then
        return false
    end
    jointNode = spec.jointNode or jointNode
    if spec.dynamicMountTriggerId ~= nil then
        local rx, ry, rz
        if mountType == DynamicMountUtil.TYPE_FORK then
            local _, mountedObject, zOffset = worldToLocal(jointNode, localToWorld(spec.componentNode, getCenterOfMass(spec.componentNode)))
            rx, ry, rz = localToLocal(jointNode, getParent(spec.dynamicMountJointNodeDynamic), 0, 0, zOffset)
        else
            rx, ry, rz = localToLocal(jointNode, getParent(spec.dynamicMountJointNodeDynamic), 0, 0, 0)
        end
        setTranslation(spec.dynamicMountJointNodeDynamic, rx, spec.dynamicMountJointTransY or ry, rz)
        if spec.dynamicMountJointLimitToRotY then
            local _, mountedObject, zOffset = localDirectionToLocal(jointNode, getParent(spec.dynamicMountJointNodeDynamic), 0, 0, 1)
            if math.abs(mountedObject) > 0.2 then
                return false
            end
            local rx, ry = MathUtil.vector2Normalize(_, zOffset)
            setRotation(spec.dynamicMountJointNodeDynamic, 0, MathUtil.getYRotationFromDirection(rx, ry), 0)
            local _, upY, _ = localDirectionToLocal(jointNode, getParent(spec.dynamicMountJointNodeDynamic), 0, 1, 0)
            if upY < 0 then
                rotateAboutLocalAxis(spec.dynamicMountJointNodeDynamic, 3.141592653589793, 0, 0, 1)
            end
        else
            local _, mountedObject, zOffset = localRotationToLocal(jointNode, getParent(spec.dynamicMountJointNodeDynamic), 0, 0, 0)
            setRotation(spec.dynamicMountJointNodeDynamic, _, mountedObject, zOffset)
        end
        local mountedObject, zOffset, rx = localToLocal(spec.dynamicMountJointNodeDynamic, jointNode, 0, 0, 0)
        spec.dynamicMountJointNodeDynamicMountOffset = rx
        spec.dynamicMountJointNodeDynamicRefNode = jointNode
    end
    spec.mountBaseForceAcceleration = forceAcceleration
    spec.mountBaseMass = self:getTotalMass()
    local x = spec.forceLimitUpdate
    local y = mountType == DynamicMountUtil.TYPE_FORK
    x.isAllowed = y
    if not DynamicMountUtil.mountDynamic(self, spec.componentNode, object, objectActorId, jointNode, mountType, forceAcceleration * spec.dynamicMountForceLimitScale, spec.dynamicMountJointNodeDynamic) then
        return false
    end
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC, object)
    return true
end
function Mountable:unmountDynamic(isDelete)
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
    local mountObject = self:getDynamicMountObject()
    if mountObject ~= nil and mountObject.onUnmountObject ~= nil then
        mountObject:onUnmountObject(self)
    end
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
    DynamicMountUtil.unmountDynamic(self, isDelete)
end
function Mountable:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    if self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
        local object = self:getDynamicMountObject()
        if object ~= nil and object.getParentComponent ~= nil then
            local componentNode = object:getParentComponent(self.spec_mountable.mountJointNode)
            if getRigidBodyType(componentNode) == RigidBodyType.DYNAMIC then
                setPairCollision(componentNode, spec.componentNode, false)
            end
        end
    end
    return true
end
function Mountable:removeFromPhysics(superFunc)
    return superFunc(self)
end
function Mountable:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    if self.dynamicMountType == MountableObject.MOUNT_TYPE_NONE or self.spec_mountable.dynamicMountAllowFoldingWhileMounted then
        return superFunc(self, direction, onAiTurnOn)
    else
        return false, g_i18n:getText("warning_foldingNotWhileAttached")
    end
end
function Mountable:getAdditionalMountingDistance()
    return self.spec_mountable.additionalMountDistance
end
function Mountable:getAdditionalMountingMass()
    return 0
end
function Mountable:updateDynamicMountJointForceLimit(dt)
    local spec = self.spec_mountable
    if not spec.forceLimitUpdate.raycastActive then
        spec.forceLimitUpdate.timer = spec.forceLimitUpdate.timer - dt
        if spec.forceLimitUpdate.timer <= 0 then
            spec.forceLimitUpdate.raycastActive = true
            spec.forceLimitUpdate.timer = Mountable.FORCE_LIMIT_UPDATE_TIME
            spec.forceLimitUpdate.lastDistance = 0
            spec.forceLimitUpdate.lastObject = nil
            spec.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance()
            spec.forceLimitUpdate.additionalMass = 0
            local x, y, z = getWorldTranslation(self.rootNode)
            raycastAllAsync(x, y, z, 0, 1, 0, Mountable.FORCE_LIMIT_RAYCAST_DISTANCE, "additionalMountingMassRaycastCallback", self, CollisionFlag.DYNAMIC_OBJECT)
        end
    end
end
function Mountable:additionalMountingMassRaycastCallback(hitObjectId, _, _, _, distance, _, _, _, _, _, isLast)
    if g_currentMission ~= nil and not (self.isDeleted or self.isDeleting) then
        local spec = self.spec_mountable
        spec.forceLimitUpdate.raycastActive = false
        local vehicle = g_currentMission.nodeToObject[hitObjectId]
        if vehicle ~= self and (vehicle ~= nil and (vehicle:isa(Vehicle) and (self.getAdditionalMountingDistance ~= nil and vehicle ~= spec.forceLimitUpdate.lastObject))) then
            if math.abs(distance - spec.forceLimitUpdate.lastDistance - spec.forceLimitUpdate.nextMountingDistance) < 0.25 then
                spec.forceLimitUpdate.lastDistance = distance
                spec.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance()
                spec.forceLimitUpdate.additionalMass = spec.forceLimitUpdate.additionalMass + vehicle:getTotalMass()
                spec.forceLimitUpdate.lastObject = vehicle
            end
        end
        if isLast and self.dynamicMountJointIndex ~= nil then
            setJointLinearDrive(self.dynamicMountJointIndex, 2, false, true, 0, 0, spec.mountBaseMass * (spec.mountBaseForceAcceleration * ((spec.forceLimitUpdate.additionalMass + spec.mountBaseMass) / spec.mountBaseMass)), 0, 0)
        end
        return true
    end
end
function Mountable:getIsActive(superFunc)
    local isActive = false
    local dynamicMountObject = self:getDynamicMountObject()
    if dynamicMountObject ~= nil and dynamicMountObject.getIsActive ~= nil then
        isActive = dynamicMountObject:getIsActive()
    end
    return superFunc(self) or isActive
end
function Mountable:getMountObject()
    if self.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
        return nil
    else
        return self:getDynamicMountObject()
    end
end
function Mountable:getDynamicMountObject()
    if self.dynamicMountObjectId == nil then
        return nil
    else
        return NetworkUtil.getObject(self.dynamicMountObjectId)
    end
end
function Mountable:setReducedComponentMass(state)
    local spec = self.spec_mountable
    if not self:getAllowComponentMassReduction() then
        return false
    end
    if spec.reducedComponentMass ~= state then
        spec.reducedComponentMass = state
        self:setMassDirty()
    end
    return true
end
function Mountable:getAllowComponentMassReduction()
    return self.spec_mountable.allowMassReduction
end
function Mountable:getDefaultAllowComponentMassReduction()
    return false
end
function Mountable:getMountableLockPositions()
    return self.spec_mountable.lockPositions
end
function Mountable:setDynamicMountType(mountType, mountObject, noEventSend)
    if mountType ~= self.dynamicMountType then
        self.dynamicMountType = mountType
        if mountObject == nil then
            self.dynamicMountObjectId = nil
        else
            self.dynamicMountObjectId = NetworkUtil.getObjectId(mountObject)
        end
        if mountType == MountableObject.MOUNT_TYPE_NONE then
            self:setReducedComponentMass(false)
        end
        for _, listener in ipairs(self.spec_mountable.mountStateChangeListeners) do
            if type(listener.callbackFunc) == "string" then
                listener.object[listener.callbackFunc](listener.object, self, mountType, mountObject)
            elseif type(listener.callbackFunc) == "function" then
                listener.callbackFunc(listener.object, self, mountType, mountObject)
            end
        end
        SpecializationUtil.raiseEvent(self, "onDynamicMountTypeChanged", self.dynamicMountType, mountObject)
        MountableSetMountTypeEvent.sendEvent(self, self.dynamicMountType, mountObject, noEventSend)
    end
end
function Mountable:addMountStateChangeListener(object, callbackFunc)
    local spec = self.spec_mountable
    callbackFunc = callbackFunc == nil and "onObjectMountStateChanged" or callbackFunc
    for _, listener in ipairs(spec.mountStateChangeListeners) do
        if listener.object == object and listener.callbackFunc == callbackFunc then
            return
        end
    end
    table.insert(spec.mountStateChangeListeners, {
        ["object"] = object,
        ["callbackFunc"] = callbackFunc
    })
end
function Mountable:removeMountStateChangeListener(object, callbackFunc)
    local spec = self.spec_mountable
    callbackFunc = callbackFunc == nil and "onObjectMountStateChanged" or callbackFunc
    local indexToRemove = -1
    for i, listener in ipairs(spec.mountStateChangeListeners) do
        if listener.object == object and listener.callbackFunc == callbackFunc then
            indexToRemove = i
        end
    end
    if indexToRemove > 0 then
        table.remove(spec.mountStateChangeListeners, indexToRemove)
    end
end
function Mountable:getOwnerConnection(superFunc)
    local spec = self.spec_mountable
    local dynamicMountObject = self:getMountObject()
    if dynamicMountObject == nil or dynamicMountObject.getOwnerConnection == nil then
        return superFunc(self)
    else
        return dynamicMountObject:getOwnerConnection()
    end
end
function Mountable:findRootVehicle(superFunc)
    local spec = self.spec_mountable
    local rootAttacherVehicle = superFunc(self)
    if rootAttacherVehicle == nil or rootAttacherVehicle == self then
        local dynamicMountObject = self:getMountObject()
        if dynamicMountObject ~= nil and dynamicMountObject.findRootVehicle ~= nil then
            rootAttacherVehicle = dynamicMountObject:findRootVehicle()
        end
    end
    if rootAttacherVehicle ~= nil then
        self = rootAttacherVehicle
    end
    return self
end
function Mountable:getIsMapHotspotVisible(superFunc)
    if superFunc(self) then
        return self:getDynamicMountObject() == nil
    else
        return false
    end
end
function Mountable:getAdditionalComponentMass(superFunc, component)
    local additionalMass = superFunc(self, component)
    if self.spec_mountable.reducedComponentMass then
        additionalMass = -component.defaultMass + 0.1
    end
    return additionalMass
end
function Mountable:setWorldPositionQuaternion(superFunc, x, y, z, qx, qy, qz, qw, i, changeInterp)
    if self.isServer or self:getMountObject() == nil then
        return superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)
    end
end
function Mountable:onPreAttach(_, _, _)
    self:unmountDynamic()
end