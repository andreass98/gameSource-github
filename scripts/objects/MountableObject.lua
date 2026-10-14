MountableObject = {}
MountableObject.MOUNT_TYPE_NONE = 0
MountableObject.MOUNT_TYPE_DEFAULT = 1
MountableObject.MOUNT_TYPE_KINEMATIC = 2
MountableObject.MOUNT_TYPE_DYNAMIC = 3
MountableObject.MOUNT_TYPE_SEND_NUM_BITS = 2
MountableObject.FORCE_LIMIT_UPDATE_TIME = 1000
MountableObject.FORCE_LIMIT_RAYCAST_DISTANCE = 20
local MountableObject_mt = Class(MountableObject, PhysicsObject)
InitStaticObjectClass(MountableObject, "MountableObject")
function MountableObject.new(isServer, isClient, customMt)
    -- upvalues: (copy) MountableObject_mt
    local self = PhysicsObject.new(isServer, isClient, customMt or MountableObject_mt)
    self.dynamicMountSingleAxisFreeX = false
    self.dynamicMountSingleAxisFreeY = false
    self.dynamicMountType = MountableObject.MOUNT_TYPE_NONE
    self.dynamicMountObjectId = nil
    self.forceLimitUpdate = {}
    self.forceLimitUpdate.raycastActive = false
    self.forceLimitUpdate.timer = 0
    self.forceLimitUpdate.lastDistance = 0
    self.forceLimitUpdate.nextMountingDistance = 0
    self.forceLimitUpdate.additionalMass = 0
    self.forceLimitUpdate.isAllowed = false
    self.supportsForkJointOffset = true
    self.lastMoveTime = -100000
    self.mountStateChangeListeners = {}
    return self
end
function MountableObject:delete()
    if self.dynamicMountTriggerId ~= nil then
        removeTrigger(self.dynamicMountTriggerId)
    end
    if self.dynamicMountJointIndex ~= nil then
        removeJointBreakReport(self.dynamicMountJointIndex)
        removeJoint(self.dynamicMountJointIndex)
    end
    if self.dynamicMountObject ~= nil then
        self.dynamicMountObject:removeDynamicMountedObject(self, true)
    end
    if self.mountObject ~= nil then
        if self.mountObject.removeMountedObject ~= nil then
            self.mountObject:removeMountedObject(self, true)
        end
        if self.mountObject.onUnmountObject ~= nil then
            self.mountObject:onUnmountObject(self)
        end
    end
    MountableObject:superClass().delete(self)
end
function MountableObject:getAllowsAutoDelete()
    return self.mountObject == nil and MountableObject:superClass().getAllowsAutoDelete(self)
end
function MountableObject:testScope(x, y, z, coeff)
    if self.mountObject ~= nil then
        local testScope = self.mountObject.testScope
        return testScope == nil or testScope(self.mountObject, x, y, z, coeff)
    end
    if self.dynamicMountObject == nil then
        return MountableObject:superClass().testScope(self, x, y, z, coeff)
    end
    local testScope = self.dynamicMountObject.testScope
    return testScope == nil or testScope(self.dynamicMountObject, x, y, z, coeff)
end
function MountableObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
    if self.mountObject == nil then
        if self.dynamicMountObject == nil then
            return MountableObject:superClass().getUpdatePriority(self, skipCount, x, y, z, coeff, connection, isGuiVisible)
        else
            return self.dynamicMountObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
        end
    else
        return self.mountObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
    end
end
function MountableObject:updateTick(dt)
    if self.isServer then
        if self:updateMove() then
            self.lastMoveTime = g_currentMission.time
        end
        if self.dynamicMountObjectTriggerCount ~= nil and self.dynamicMountObjectTriggerCount <= 0 then
            if self.dynamicMountJointNodeDynamicRefNode == nil then
                self:unmountDynamic()
                self.dynamicMountObjectTriggerCount = nil
            else
                local _, _, zOffset = localToLocal(self.dynamicMountJointNodeDynamic, self.dynamicMountJointNodeDynamicRefNode, 0, 0, 0)
                if self.dynamicMountJointNodeDynamicMountOffset < zOffset then
                    self.dynamicMountJointNodeDynamicMountOffset = nil
                    self.dynamicMountJointNodeDynamicRefNode = nil
                    self:unmountDynamic()
                    self.dynamicMountObjectTriggerCount = nil
                else
                    self:raiseActive()
                end
            end
        end
        if self.dynamicMountJointIndex ~= nil and self.forceLimitUpdate.isAllowed then
            self:updateDynamicMountJointForceLimit(dt)
        end
    end
end
function MountableObject:getIsMounted()
    return self.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE
end
function MountableObject:mount(object, node, x, y, z, rx, ry, rz)
    if self.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
        self:unmountDynamic()
    elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
        self:unmountKinematic()
    end
    self:unmountDynamic(true)
    if self.mountObject == nil then
        removeFromPhysics(self.nodeId)
    end
    link(node, self.nodeId)
    local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(rx, ry, rz)
    self:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
    self.mountObject = object
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_DEFAULT, object)
end
function MountableObject:unmount()
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
    if self.mountObject == nil then
        return false
    end
    self.mountObject = nil
    local x, y, z = getWorldTranslation(self.nodeId)
    local quatX, quatY, quatZ, quatW = getWorldQuaternion(self.nodeId)
    link(getRootNode(), self.nodeId)
    self:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
    addToPhysics(self.nodeId)
    return true
end
function MountableObject:mountKinematic(object, node, x, y, z, rx, ry, rz)
    if self.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
        self:unmount()
    elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
        self:unmountDynamic()
    end
    self:unmountDynamic(true)
    removeFromPhysics(self.nodeId)
    link(node, self.nodeId)
    local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(rx, ry, rz)
    self:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
    addToPhysics(self.nodeId)
    if self.isServer then
        setRigidBodyType(self.nodeId, RigidBodyType.KINEMATIC)
    end
    if object.components ~= nil then
        local i = 1
        for i = i, #object.components do
            if getRigidBodyType(object.components[i].node) == RigidBodyType.DYNAMIC then
                setPairCollision(object.components[i].node, self.nodeId, false)
            end
        end
    end
    self.mountObject = object
    self.mountJointNode = node
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_KINEMATIC, object)
end
function MountableObject:unmountKinematic()
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
    if self.mountObject == nil then
        return false
    end
    local components = self.mountObject.components
    if self.mountObject.onUnmountObject ~= nil then
        self.mountObject:onUnmountObject(self)
    end
    self.mountObject = nil
    self.mountJointNode = nil
    local x, y, z = getWorldTranslation(self.nodeId)
    local quatX, quatY, quatZ, quatW = getWorldQuaternion(self.nodeId)
    removeFromPhysics(self.nodeId)
    link(getRootNode(), self.nodeId)
    self:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
    addToPhysics(self.nodeId)
    if self.isServer then
        setRigidBodyType(self.nodeId, self:getDefaultRigidBodyType())
    end
    if components ~= nil then
        local i = 1
        for i = i, #components do
            if getRigidBodyType(components[i].node) == RigidBodyType.DYNAMIC then
                setPairCollision(components[i].node, self.nodeId, true)
            end
        end
    end
    return true
end
function MountableObject:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
    local y = self.isServer
    assert(y)
    if self.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
        self:unmount()
    elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
        self:unmountKinematic()
    end
    if self:getSupportsMountDynamic() and self.mountObject == nil then
        if object:getOwnerFarmId() == nil or g_currentMission.accessHandler:canFarmAccess(object:getOwnerFarmId(), self) then
            if self.dynamicMountTriggerId ~= nil then
                local _, _, zOffset
                if mountType == DynamicMountUtil.TYPE_FORK and self.supportsForkJointOffset then
                    local _, _, zOffset = worldToLocal(jointNode, localToWorld(self.nodeId, getCenterOfMass(self.nodeId)))
                    _, _, zOffset = localToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, zOffset)
                else
                    _, _, zOffset = localToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, 0)
                end
                setTranslation(self.dynamicMountJointNodeDynamic, _, _, zOffset)
                setRotation(self.dynamicMountJointNodeDynamic, localRotationToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, 0))
                _, zOffset, self.dynamicMountJointNodeDynamicMountOffset = localToLocal(self.dynamicMountJointNodeDynamic, jointNode, 0, 0, 0)
                self.dynamicMountJointNodeDynamicRefNode = jointNode
            end
            self.mountBaseForceAcceleration = forceAcceleration
            self.mountBaseMass = self:getMass()
            self.forceLimitUpdate.isAllowed = mountType == DynamicMountUtil.TYPE_FORK
            if DynamicMountUtil.mountDynamic(self, self.nodeId, object, objectActorId, jointNode, mountType, forceAcceleration * self.dynamicMountForceLimitScale, self.dynamicMountJointNodeDynamic) then
                self:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC, object)
                return true
            else
                self.dynamicMountJointNodeDynamicRefNode = nil
                return false
            end
        else
            return false
        end
    else
        return false
    end
end
function MountableObject:unmountDynamic(isDelete)
    DynamicMountUtil.unmountDynamic(self, isDelete)
    self:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
    if self.isServer then
        self.lastMoveTime = g_currentMission.time
    end
    self.dynamicMountJointNodeDynamicMountOffset = nil
    self.dynamicMountJointNodeDynamicRefNode = nil
end
function MountableObject:getSupportsMountDynamic()
    return true
end
function MountableObject:getAdditionalMountingDistance()
    return 0
end
function MountableObject:addToPhysics()
    MountableObject:superClass().addToPhysics(self)
    if self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
        local object = self.mountObject
        if object ~= nil and object.components ~= nil then
            local i = 1
            for i = i, #object.components do
                if getRigidBodyType(object.components[i].node) == RigidBodyType.DYNAMIC then
                    setPairCollision(object.components[i].node, self.nodeId, false)
                end
            end
        end
    end
end
function MountableObject:removeFromPhysics()
    MountableObject:superClass().removeFromPhysics(self)
end
function MountableObject:updateDynamicMountJointForceLimit(dt)
    if not self.forceLimitUpdate.raycastActive then
        self.forceLimitUpdate.timer = self.forceLimitUpdate.timer - dt
        if self.forceLimitUpdate.timer <= 0 then
            self.forceLimitUpdate.raycastActive = true
            self.forceLimitUpdate.timer = MountableObject.FORCE_LIMIT_UPDATE_TIME
            self.forceLimitUpdate.lastDistance = 0
            self.forceLimitUpdate.lastObject = nil
            self.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance()
            self.forceLimitUpdate.additionalMass = 0
            local x, y, z = getWorldTranslation(self.nodeId)
            raycastAllAsync(x, y, z, 0, 1, 0, MountableObject.FORCE_LIMIT_RAYCAST_DISTANCE, "additionalMountingMassRaycastCallback", self, CollisionFlag.DYNAMIC_OBJECT)
        end
    end
end
function MountableObject:getAdditionalMountingMass()
    return 0
end
function MountableObject:additionalMountingMassRaycastCallback(hitObjectId, _, _, _, distance, _, _, _, _, _, isLast)
    if g_currentMission ~= nil then
        self.forceLimitUpdate.raycastActive = false
        local object = g_currentMission.nodeToObject[hitObjectId]
        if object ~= self and (object ~= nil and (object:isa(MountableObject) and (self.getAdditionalMountingDistance ~= nil and object ~= self.forceLimitUpdate.lastObject))) then
            if math.abs(distance - self.forceLimitUpdate.lastDistance - self.forceLimitUpdate.nextMountingDistance) < 0.25 then
                self.forceLimitUpdate.lastDistance = distance
                self.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance() * 2
                self.forceLimitUpdate.additionalMass = self.forceLimitUpdate.additionalMass + object:getMass()
                self.forceLimitUpdate.lastObject = object
            end
        end
        if isLast and self.dynamicMountJointIndex ~= nil then
            setJointLinearDrive(self.dynamicMountJointIndex, 2, false, true, 0, 0, self.mountBaseMass * (self.mountBaseForceAcceleration * ((self.forceLimitUpdate.additionalMass + self.mountBaseMass) / self.mountBaseMass)), 0, 0)
        end
        return true
    end
end
function MountableObject:setNodeId(nodeId)
    MountableObject:superClass().setNodeId(self, nodeId)
    if self.isServer then
        local triggerId = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "dynamicMountTriggerIndex"))
        if triggerId ~= nil then
            local forceAcceleration = tonumber(getUserAttribute(nodeId, "dynamicMountTriggerForceAcceleration"))
            local axisFreeX = getUserAttribute(nodeId, "dynamicMountSingleAxisFreeX") == true
            self:setMountableObjectAttributes(triggerId, forceAcceleration, tonumber(getUserAttribute(nodeId, "dynamicMountForceLimitScale")), getUserAttribute(nodeId, "dynamicMountSingleAxisFreeY") == true, axisFreeX)
        end
        if self.dynamicMountJointNodeDynamic == nil then
            self.dynamicMountJointNodeDynamic = createTransformGroup("dynamicMountJointNodeDynamic")
            link(self.nodeId, self.dynamicMountJointNodeDynamic)
        end
    end
end
function MountableObject:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
    if self.isServer then
        MountableObject:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
    elseif self.dynamicMountType ~= MountableObject.MOUNT_TYPE_KINEMATIC and self.dynamicMountType ~= MountableObject.MOUNT_TYPE_DEFAULT then
        MountableObject:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
        return
    end
end
function MountableObject:setMountableObjectAttributes(triggerId, forceAcceleration, forceLimitScale, axisFreeY, axisFreeX)
    if self.isServer then
        if self.dynamicMountTriggerId == nil then
            self.dynamicMountTriggerId = triggerId
            if self.dynamicMountTriggerId ~= nil then
                addTrigger(self.dynamicMountTriggerId, "dynamicMountTriggerCallback", self)
            end
        end
        self.dynamicMountTriggerForceAcceleration = forceAcceleration or 4
        self.dynamicMountForceLimitScale = forceLimitScale or 1
        self.dynamicMountSingleAxisFreeY = axisFreeY
        self.dynamicMountSingleAxisFreeX = axisFreeX
    end
end
function MountableObject:dynamicMountTriggerCallback(_, otherActorId, onEnter, onLeave, _, otherShapeId)
    local vehicle = g_currentMission.nodeToObject[otherActorId]
    if vehicle ~= nil and vehicle:isa(Vehicle) then
        otherActorId = vehicle.components[1].node
        if vehicle.spec_dynamicMountAttacher == nil then
        else
            local dynamicMountAttacherNode = vehicle.spec_dynamicMountAttacher.dynamicMountAttacherNode
            if dynamicMountAttacherNode == nil then
            else
                otherActorId = vehicle:getParentComponent(dynamicMountAttacherNode)
                if otherActorId == 0 then
                end
            end
        end
    end
    if onEnter then
        if self.mountObject == nil then
            local dynamicMountAttacherNode = nil
            local componentNode = DynamicMountUtil.TYPE_FORK
            local forceLimit = 1
            if vehicle ~= nil and vehicle.spec_dynamicMountAttacher ~= nil then
                dynamicMountAttacherNode = vehicle.spec_dynamicMountAttacher
                componentNode, forceLimit = vehicle:getDynamicMountAttacherSettingsByNode(otherShapeId)
            end
            if dynamicMountAttacherNode ~= nil then
                if self.dynamicMountObjectActorId == nil then
                    self:mountDynamic(vehicle, otherActorId, dynamicMountAttacherNode.dynamicMountAttacherNode, componentNode, self.dynamicMountTriggerForceAcceleration * forceLimit)
                    self.dynamicMountObjectTriggerCount = 1
                    return
                end
                if otherActorId ~= self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount == nil then
                    self:unmountDynamic()
                    self:mountDynamic(vehicle, otherActorId, dynamicMountAttacherNode.dynamicMountAttacherNode, componentNode, self.dynamicMountTriggerForceAcceleration * forceLimit)
                    self.dynamicMountObjectTriggerCount = 1
                    return
                end
                if otherActorId == self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount ~= nil then
                    self.dynamicMountObjectTriggerCount = self.dynamicMountObjectTriggerCount + 1
                    return
                end
            end
        end
    elseif onLeave and (otherActorId == self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount ~= nil) then
        self.dynamicMountObjectTriggerCount = self.dynamicMountObjectTriggerCount - 1
        if self.dynamicMountObjectTriggerCount <= 0 then
            if self.dynamicMountTriggerId == nil then
                self:unmountDynamic()
                self.dynamicMountObjectTriggerCount = nil
                return
            end
            self:raiseActive()
        end
    end
end
function MountableObject:onDynamicMountJointBreak(jointIndex, _)
    if jointIndex == self.dynamicMountJointIndex then
        self:unmountDynamic()
    end
    return false
end
function MountableObject:getMeshNodes()
    return nil
end
function MountableObject:setDynamicMountType(mountState, mountObject)
    if mountState ~= self.dynamicMountType then
        self.dynamicMountType = mountState
        if mountObject == nil then
            self.dynamicMountObjectId = nil
        else
            self.dynamicMountObjectId = NetworkUtil.getObjectId(mountObject)
        end
        for _, listener in ipairs(self.mountStateChangeListeners) do
            if type(listener.callbackFunc) == "string" then
                listener.object[listener.callbackFunc](listener.object, self, mountState, mountObject)
            elseif type(listener.callbackFunc) == "function" then
                listener.callbackFunc(listener.object, self, mountState, mountObject)
            end
        end
    end
end
function MountableObject:getDynamicMountObject()
    if self.dynamicMountObjectId ~= nil then
        return NetworkUtil.getObject(self.dynamicMountObjectId)
    end
end
function MountableObject:addMountStateChangeListener(object, callbackFunc)
    callbackFunc = callbackFunc == nil and "onObjectMountStateChanged" or callbackFunc
    for _, listener in ipairs(self.mountStateChangeListeners) do
        if listener.object == object and listener.callbackFunc == callbackFunc then
            return
        end
    end
    table.insert(self.mountStateChangeListeners, {
        ["object"] = object,
        ["callbackFunc"] = callbackFunc
    })
end
function MountableObject:removeMountStateChangeListener(object, callbackFunc)
    callbackFunc = callbackFunc == nil and "onObjectMountStateChanged" or callbackFunc
    local indexToRemove = -1
    for i, listener in ipairs(self.mountStateChangeListeners) do
        if listener.object == object and listener.callbackFunc == callbackFunc then
            indexToRemove = i
        end
    end
    if indexToRemove > 0 then
        table.remove(self.mountStateChangeListeners, indexToRemove)
    end
end