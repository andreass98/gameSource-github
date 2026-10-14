HookLiftContainer = {}
function HookLiftContainer.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) and SpecializationUtil.hasSpecialization(Attachable, specializations)
end
function HookLiftContainer.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("HookLiftContainer")
    schema:register(XMLValueType.BOOL, "vehicle.hookLiftContainer#tiltContainerOnDischarge", "Tilt container on discharge", true)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftContainer.visualRollReference#startNode", "Reference nodes that represent the bottom of the container")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftContainer.visualRollReference#endNode", "Reference nodes that represent the bottom of the container")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.hookLiftContainer.containerLock")
    schema:setXMLSpecializationType()
end
function HookLiftContainer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "onHookLiftContainerLockChanged", HookLiftContainer.onHookLiftContainerLockChanged)
end
function HookLiftContainer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToObject", HookLiftContainer.getCanDischargeToObject)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToGround", HookLiftContainer.getCanDischargeToGround)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", HookLiftContainer.isDetachAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", HookLiftContainer.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", HookLiftContainer.removeFromPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", HookLiftContainer.getBrakeForce)
end
function HookLiftContainer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HookLiftContainer)
    SpecializationUtil.registerEventListener(vehicleType, "onStartTipping", HookLiftContainer)
    SpecializationUtil.registerEventListener(vehicleType, "onStopTipping", HookLiftContainer)
end
function HookLiftContainer:onLoad(_)
    local spec = self.spec_hookLiftContainer
    spec.tiltContainerOnDischarge = self.xmlFile:getValue("vehicle.hookLiftContainer#tiltContainerOnDischarge", true)
    spec.visualReferenceNodeStart = self.xmlFile:getValue("vehicle.hookLiftContainer.visualRollReference#startNode", nil, self.components, self.i3dMappings)
    spec.visualReferenceNodeEnd = self.xmlFile:getValue("vehicle.hookLiftContainer.visualRollReference#endNode", nil, self.components, self.i3dMappings)
    spec.containerLockChangeObjects = {}
    ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.hookLiftContainer.containerLock", spec.containerLockChangeObjects, self.components, self)
    ObjectChangeUtil.setObjectChanges(spec.containerLockChangeObjects, false, self, self.setMovingToolDirty)
    if self.setConnectionHosesActive ~= nil then
        self:setConnectionHosesActive(false)
    end
end
function HookLiftContainer:getCanDischargeToObject(superFunc, dischargeNode)
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle == nil or (attacherVehicle.getIsTippingAllowed == nil or attacherVehicle:getIsTippingAllowed()) then
        return superFunc(self, dischargeNode)
    else
        return false
    end
end
function HookLiftContainer:getCanDischargeToGround(superFunc, dischargeNode)
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle == nil or (attacherVehicle.getIsTippingAllowed == nil or attacherVehicle:getIsTippingAllowed()) then
        return superFunc(self, dischargeNode)
    else
        return false
    end
end
function HookLiftContainer:isDetachAllowed(superFunc)
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle == nil or (attacherVehicle.getCanDetachContainer == nil or attacherVehicle:getCanDetachContainer()) then
        return superFunc(self)
    else
        return false, nil
    end
end
function HookLiftContainer:onStartTipping(_)
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle ~= nil and (attacherVehicle.startTipping ~= nil and self.spec_hookLiftContainer.tiltContainerOnDischarge) then
        attacherVehicle:startTipping()
    end
end
function HookLiftContainer:onStopTipping()
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle ~= nil and (attacherVehicle.stopTipping ~= nil and self.spec_hookLiftContainer.tiltContainerOnDischarge) then
        attacherVehicle:stopTipping()
    end
end
function HookLiftContainer:onHookLiftContainerLockChanged(state)
    if self.setConnectionHosesActive ~= nil and self:getAttacherVehicle():getImplementByObject(self) ~= nil then
        self:setConnectionHosesActive(state)
    end
    ObjectChangeUtil.setObjectChanges(self.spec_hookLiftContainer.containerLockChangeObjects, state, self, self.setMovingToolDirty)
end
function HookLiftContainer:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle ~= nil and attacherVehicle.setHookLiftContainerPhysicsState ~= nil then
        attacherVehicle:setHookLiftContainerPhysicsState(self, true)
    end
    return true
end
function HookLiftContainer:removeFromPhysics(superFunc)
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle ~= nil and attacherVehicle.setHookLiftContainerPhysicsState ~= nil then
        attacherVehicle:setHookLiftContainerPhysicsState(self, false)
    end
    return superFunc(self) and true or false
end
function HookLiftContainer:getBrakeForce(superFunc)
    return self:getAttacherVehicle() ~= nil and 0 or superFunc(self)
end