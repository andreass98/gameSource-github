DynamicMountAttacher = {}
DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH = "vehicle.dynamicMountAttacher.grab"
function DynamicMountAttacher.prerequisitesPresent(specializations)
    return true
end
function DynamicMountAttacher.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("DynamicMountAttacher")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#node", "Attacher node")
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher#forceLimitScale", "Force limit", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher#timeToMount", "No movement time until mounting", 1000)
    schema:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#stateChangeMount", "Mount / unmount the object while the allowed state changes (e.g. due to foldable limits)", false)
    schema:register(XMLValueType.INT, "vehicle.dynamicMountAttacher#numObjectBits", "Number of object bits to sync", 5)
    schema:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#limitToKnownObjects", "Only mount objects that are defined with a lockPosition", false)
    schema:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#collisionBetweenObjects", "Collision between mounted objects is enabled", true)
    schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.grab#openMountType", "Open mount type", "TYPE_FORK")
    schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.grab#closedMountType", "Closed mount type", "TYPE_AUTO_ATTACH_XYZ")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher.fork(?)#node", "Fork collision node (starting from FS25 one combined node for front and back part)")
    schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.fork(?)#mountType", "Mount type that is used if object is mounted via this fork node", "FORK")
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.fork(?)#forceLimitScale", "Force limit that is used if object is mounted via this fork node", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#triggerNode", "Trigger node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#rootNode", "Root node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#jointNode", "Joint node")
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher#forceAcceleration", "Force acceleration", 30)
    schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher#mountType", "Mount type", "TYPE_AUTO_ATTACH_XZ")
    schema:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#transferMass", "If this is set to \'true\' the mass of the object to mount is transferred to our own component. This improves physics stability", false)
    schema:addDelayedRegistrationPath("vehicle.dynamicMountAttacher.lockPosition(?)", "DynamicMountAttacher:lockPosition")
    schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.lockPosition(?)#xmlFilename", "XML filename of vehicle to lock (needs to match only the end of the filename)")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher.lockPosition(?)#jointNode", "Joint node (Represents the position of the other vehicles root node)")
    schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.lockPosition(?).configuration(?)#name", "Name of configuration")
    schema:register(XMLValueType.INT, "vehicle.dynamicMountAttacher.lockPosition(?).configuration(?)#index", "Configuration index that needs to match to use the lock position")
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.lockPosition(?)#width", "Width of lock position (if defined, collision to other vehicles is checked during locking)")
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.lockPosition(?)#length", "Length of lock position (if defined, collision to other vehicles is checked during locking)")
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.lockPosition(?)#height", "Height of lock position (if defined, collision to other vehicles is checked during locking)")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.dynamicMountAttacher.lockPosition(?)")
    schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.animation#name", "Animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.animation#speed", "Animation speed", 1)
    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.BOOL, cKey .. ".dynamicMountAttacher#value", "Update dynamic mount attacher joints")
        cSchema:register(XMLValueType.BOOL, cKey .. ".dynamicMountAttacher#allowedMounted", "Allow moving tool movement while something is mounted", true)
    end)
    schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(cSchema, cKey)
        cSchema:register(XMLValueType.BOOL, cKey .. ".dynamicMountAttacher#value", "Update dynamic mount attacher joints")
    end)
    schema:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#allowFoldingWhileMounted", "Folding is allowed while a object is mounted", true)
    schema:setXMLSpecializationType()
end
function DynamicMountAttacher.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadDynamicLockPositionFromXML", DynamicMountAttacher.loadDynamicLockPositionFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsDynamicLockPositionActive", DynamicMountAttacher.getIsDynamicLockPositionActive)
    SpecializationUtil.registerFunction(vehicleType, "writeDynamicMountObjectsToStream", DynamicMountAttacher.writeDynamicMountObjectsToStream)
    SpecializationUtil.registerFunction(vehicleType, "readDynamicMountObjectsFromStream", DynamicMountAttacher.readDynamicMountObjectsFromStream)
    SpecializationUtil.registerFunction(vehicleType, "getAllowDynamicMountObjects", DynamicMountAttacher.getAllowDynamicMountObjects)
    SpecializationUtil.registerFunction(vehicleType, "dynamicMountTriggerCallback", DynamicMountAttacher.dynamicMountTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "lockDynamicMountedObject", DynamicMountAttacher.lockDynamicMountedObject)
    SpecializationUtil.registerFunction(vehicleType, "addDynamicMountedObject", DynamicMountAttacher.addDynamicMountedObject)
    SpecializationUtil.registerFunction(vehicleType, "removeDynamicMountedObject", DynamicMountAttacher.removeDynamicMountedObject)
    SpecializationUtil.registerFunction(vehicleType, "onUnmountObject", DynamicMountAttacher.onUnmountObject)
    SpecializationUtil.registerFunction(vehicleType, "setDynamicMountAnimationState", DynamicMountAttacher.setDynamicMountAnimationState)
    SpecializationUtil.registerFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", DynamicMountAttacher.getAllowDynamicMountFillLevelInfo)
    SpecializationUtil.registerFunction(vehicleType, "loadDynamicMountGrabFromXML", DynamicMountAttacher.loadDynamicMountGrabFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsDynamicMountGrabOpened", DynamicMountAttacher.getIsDynamicMountGrabOpened)
    SpecializationUtil.registerFunction(vehicleType, "getDynamicMountTimeToMount", DynamicMountAttacher.getDynamicMountTimeToMount)
    SpecializationUtil.registerFunction(vehicleType, "getHasDynamicMountedObjects", DynamicMountAttacher.getHasDynamicMountedObjects)
    SpecializationUtil.registerFunction(vehicleType, "forceDynamicMountPendingObjects", DynamicMountAttacher.forceDynamicMountPendingObjects)
    SpecializationUtil.registerFunction(vehicleType, "forceUnmountDynamicMountedObjects", DynamicMountAttacher.forceUnmountDynamicMountedObjects)
    SpecializationUtil.registerFunction(vehicleType, "getDynamicMountAttacherSettingsByNode", DynamicMountAttacher.getDynamicMountAttacherSettingsByNode)
    SpecializationUtil.registerFunction(vehicleType, "dynamicMountLockPositionOverlapCallback", DynamicMountAttacher.dynamicMountLockPositionOverlapCallback)
end
function DynamicMountAttacher.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", DynamicMountAttacher.getFillLevelInformation)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", DynamicMountAttacher.loadExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", DynamicMountAttacher.updateExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttachedTo", DynamicMountAttacher.getIsAttachedTo)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", DynamicMountAttacher.getAdditionalComponentMass)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", DynamicMountAttacher.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", DynamicMountAttacher.loadMovingToolFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", DynamicMountAttacher.getIsMovingToolActive)
end
function DynamicMountAttacher.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", DynamicMountAttacher)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", DynamicMountAttacher)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", DynamicMountAttacher)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", DynamicMountAttacher)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", DynamicMountAttacher)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", DynamicMountAttacher)
end
function DynamicMountAttacher:onLoad(_)
    local spec = self.spec_dynamicMountAttacher
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicMountAttacher#index", "vehicle.dynamicMountAttacher#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicMountAttacher.mountCollisionMask", "vehicle.dynamicMountAttacher.fork")
    spec.dynamicMountAttacherNode = self.xmlFile:getValue("vehicle.dynamicMountAttacher#node", nil, self.components, self.i3dMappings)
    spec.dynamicMountAttacherForceLimitScale = self.xmlFile:getValue("vehicle.dynamicMountAttacher#forceLimitScale", 1)
    spec.dynamicMountAttacherTimeToMount = self.xmlFile:getValue("vehicle.dynamicMountAttacher#timeToMount", 1000)
    spec.dynamicMountAttacherStateChangeMount = self.xmlFile:getValue("vehicle.dynamicMountAttacher#stateChangeMount", false)
    spec.numObjectBits = self.xmlFile:getValue("vehicle.dynamicMountAttacher#numObjectBits", 5)
    spec.maxNumObjectsToSend = 2 ^ spec.numObjectBits - 1
    spec.limitToKnownObjects = self.xmlFile:getValue("vehicle.dynamicMountAttacher#limitToKnownObjects", false)
    spec.collisionBetweenObjects = self.xmlFile:getValue("vehicle.dynamicMountAttacher#collisionBetweenObjects", true)
    if self.xmlFile:hasProperty("vehicle.dynamicMountAttacher.grab") then
        spec.dynamicMountAttacherGrab = {}
        self:loadDynamicMountGrabFromXML(self.xmlFile, "vehicle.dynamicMountAttacher.grab", spec.dynamicMountAttacherGrab)
    end
    spec.pendingDynamicMountObjects = {}
    spec.lockPositions = {}
    if self.isServer then
        spec.forks = {}
        for _, key in self.xmlFile:iterator("vehicle.dynamicMountAttacher.fork") do
            local fork = {
                ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
            }
            if fork.node == nil then
                Logging.xmlWarning(self.xmlFile, "Missing node or fork in \'%s\'", key)
            elseif getCollisionFilterGroup(fork.node) == CollisionFlag.VEHICLE_FORK then
                local mountTypeStr = self.xmlFile:getValue(key .. "#mountType", "FORK")
                fork.mountType = DynamicMountUtil["TYPE_" .. mountTypeStr] or DynamicMountUtil.TYPE_FORK
                fork.forceLimitScale = self.xmlFile:getValue(key .. "#forceLimitScale", spec.dynamicMountAttacherForceLimitScale)
                table.insert(spec.forks, fork)
            else
                Logging.xmlWarning(self.xmlFile, "Fork node \'%s\' has invalid collision filter group, should have %s!", getName(fork.node), CollisionFlag.getBitAndName(CollisionFlag.VEHICLE_FORK))
            end
        end
        local dynamicMountTrigger = {
            ["triggerNode"] = self.xmlFile:getValue("vehicle.dynamicMountAttacher#triggerNode", nil, self.components, self.i3dMappings),
            ["rootNode"] = self.xmlFile:getValue("vehicle.dynamicMountAttacher#rootNode", nil, self.components, self.i3dMappings),
            ["jointNode"] = self.xmlFile:getValue("vehicle.dynamicMountAttacher#jointNode", nil, self.components, self.i3dMappings)
        }
        if dynamicMountTrigger.triggerNode ~= nil and (dynamicMountTrigger.rootNode ~= nil and dynamicMountTrigger.jointNode ~= nil) then
            local collisionMask = getCollisionFilterMask(dynamicMountTrigger.triggerNode)
            local key = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE
            if bit32.band(collisionMask, key) > 0 then
                addTrigger(dynamicMountTrigger.triggerNode, "dynamicMountTriggerCallback", self)
                dynamicMountTrigger.forceAcceleration = self.xmlFile:getValue("vehicle.dynamicMountAttacher#forceAcceleration", 30)
                local mountTypeString = self.xmlFile:getValue("vehicle.dynamicMountAttacher#mountType", "TYPE_AUTO_ATTACH_XZ")
                dynamicMountTrigger.mountType = Utils.getNoNil(DynamicMountUtil[mountTypeString], DynamicMountUtil.TYPE_AUTO_ATTACH_XZ)
                dynamicMountTrigger.currentMountType = dynamicMountTrigger.mountType
                dynamicMountTrigger.component = self:getParentComponent(dynamicMountTrigger.triggerNode)
                spec.dynamicMountAttacherTrigger = dynamicMountTrigger
            else
                Logging.xmlWarning(self.xmlFile, "Dynamic Mount trigger has invalid collision filter mask, should have %s or %s!", CollisionFlag.getBitAndName(CollisionFlag.DYNAMIC_OBJECT), CollisionFlag.getBitAndName(CollisionFlag.VEHICLE))
            end
            if string.contains(string.lower(getName(dynamicMountTrigger.jointNode)), "cutter") then
                if bit32.band(collisionMask, CollisionFlag.VEHICLE) == 0 then
                    Logging.xmlWarning(self.xmlFile, "Dynamic Mount trigger has invalid collision filter mask, should have %s for cutter trailers!", CollisionFlag.getBitAndName(CollisionFlag.VEHICLE))
                end
            end
            g_currentMission:addNodeObject(dynamicMountTrigger.triggerNode, self)
        end
        spec.transferMass = self.xmlFile:getValue("vehicle.dynamicMountAttacher#transferMass", false)
        self.xmlFile:iterate("vehicle.dynamicMountAttacher.lockPosition", function(_, key)
            -- upvalues: (copy) self, (copy) spec
            local lockPosition = {}
            if self:loadDynamicLockPositionFromXML(self.xmlFile, key, lockPosition) then
                table.insert(spec.lockPositions, lockPosition)
            end
        end)
    end
    spec.animationName = self.xmlFile:getValue("vehicle.dynamicMountAttacher.animation#name")
    spec.animationSpeed = self.xmlFile:getValue("vehicle.dynamicMountAttacher.animation#speed", 1)
    if spec.animationName ~= nil then
        self:playAnimation(spec.animationName, spec.animationSpeed, self:getAnimationTime(spec.animationName), true)
    end
    spec.allowFoldingWhileMounted = self.xmlFile:getValue("vehicle.dynamicMountAttacher#allowFoldingWhileMounted", true)
    spec.lastMountingIsAllowed = false
    spec.overlapBoxHasCollision = false
    spec.overlapBoxIgnoreVehicle = nil
    spec.dynamicMountedObjects = {}
    spec.dynamicMountedObjectsDirtyFlag = self:getNextDirtyFlag()
end
function DynamicMountAttacher:onDelete()
    local spec = self.spec_dynamicMountAttacher
    if self.isServer and spec.dynamicMountedObjects ~= nil then
        for object, _ in pairs(spec.dynamicMountedObjects) do
            object:unmountDynamic()
        end
    end
    if spec.dynamicMountAttacherTrigger ~= nil then
        removeTrigger(spec.dynamicMountAttacherTrigger.triggerNode)
        g_currentMission:removeNodeObject(spec.dynamicMountAttacherTrigger.triggerNode)
    end
end
function DynamicMountAttacher:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self:setDynamicMountAnimationState(self:readDynamicMountObjectsFromStream(streamId, self.spec_dynamicMountAttacher.dynamicMountedObjects) > 0)
            self:readDynamicMountObjectsFromStream(streamId, spec.pendingDynamicMountObjects)
        end
    end
end
function DynamicMountAttacher:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_dynamicMountAttacher
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dynamicMountedObjectsDirtyFlag) ~= 0) then
            self:writeDynamicMountObjectsToStream(streamId, spec.dynamicMountedObjects)
            self:writeDynamicMountObjectsToStream(streamId, spec.pendingDynamicMountObjects)
        end
    end
end
function DynamicMountAttacher:onUpdateTick(_, _, _, _)
    if self.isServer then
        local spec = self.spec_dynamicMountAttacher
        local mountingIsAllowed = self:getAllowDynamicMountObjects()
        if mountingIsAllowed ~= spec.lastMountingIsAllowed or not spec.dynamicMountAttacherStateChangeMount then
            spec.lastMountingIsAllowed = mountingIsAllowed
            if mountingIsAllowed then
                for object, _ in pairs(spec.pendingDynamicMountObjects) do
                    self:raiseActive()
                    if spec.dynamicMountedObjects[object] == nil then
                        if object.lastMoveTime + self:getDynamicMountTimeToMount() < g_currentMission.time then
                            local doAttach = false
                            local objectRoot = nil
                            if object.components ~= nil then
                                if object.getCanBeMounted == nil then
                                    doAttach = entityExists(object.components[1].node) and true or doAttach
                                else
                                    doAttach = object:getCanBeMounted()
                                end
                                objectRoot = object.components[1].node
                            end
                            if object.nodeId ~= nil then
                                if object.getCanBeMounted == nil then
                                    doAttach = entityExists(object.nodeId) and true or doAttach
                                else
                                    doAttach = object:getCanBeMounted()
                                end
                                objectRoot = object.nodeId
                            end
                            if doAttach then
                                local trigger = spec.dynamicMountAttacherTrigger
                                local objectJoint = createTransformGroup("dynamicMountObjectJoint")
                                link(trigger.jointNode, objectJoint)
                                setWorldTranslation(objectJoint, getWorldTranslation(objectRoot))
                                if object:mountDynamic(self, trigger.rootNode, objectJoint, trigger.mountType, trigger.forceAcceleration) then
                                    object.additionalDynamicMountJointNode = objectJoint
                                    self:addDynamicMountedObject(object)
                                else
                                    delete(objectJoint)
                                end
                            else
                                spec.pendingDynamicMountObjects[object] = nil
                                self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
                            end
                        end
                    else
                        spec.pendingDynamicMountObjects[object] = nil
                    end
                end
            else
                for object, _ in pairs(spec.dynamicMountedObjects) do
                    self:removeDynamicMountedObject(object, false)
                    object:unmountDynamic()
                    if object.additionalDynamicMountJointNode ~= nil then
                        delete(object.additionalDynamicMountJointNode)
                        object.additionalDynamicMountJointNode = nil
                    end
                end
            end
        end
        if spec.dynamicMountAttacherGrab ~= nil then
            for object, _ in pairs(spec.dynamicMountedObjects) do
                local doAttach = spec.dynamicMountAttacherGrab.closedMountType
                if self:getIsDynamicMountGrabOpened(spec.dynamicMountAttacherGrab) then
                    doAttach = spec.dynamicMountAttacherGrab.openMountType
                end
                if spec.dynamicMountAttacherGrab.currentMountType ~= doAttach then
                    spec.dynamicMountAttacherGrab.currentMountType = doAttach
                    local objectRoot, trigger, objectJoint = getWorldTranslation(spec.dynamicMountAttacherNode)
                    setJointPosition(object.dynamicMountJointIndex, 1, objectRoot, trigger, objectJoint)
                    if doAttach == DynamicMountUtil.TYPE_FORK then
                        setJointRotationLimit(object.dynamicMountJointIndex, 0, true, 0, 0)
                        setJointRotationLimit(object.dynamicMountJointIndex, 1, true, 0, 0)
                        setJointRotationLimit(object.dynamicMountJointIndex, 2, true, 0, 0)
                        if object.dynamicMountSingleAxisFreeX then
                            setJointTranslationLimit(object.dynamicMountJointIndex, 0, false, 0, 0)
                        else
                            setJointTranslationLimit(object.dynamicMountJointIndex, 0, true, -0.01, 0.01)
                        end
                        if object.dynamicMountSingleAxisFreeY then
                            setJointTranslationLimit(object.dynamicMountJointIndex, 1, false, 0, 0)
                        else
                            setJointTranslationLimit(object.dynamicMountJointIndex, 1, true, -0.01, 0.01)
                        end
                        setJointTranslationLimit(object.dynamicMountJointIndex, 2, false, 0, 0)
                    else
                        setJointRotationLimit(object.dynamicMountJointIndex, 0, true, 0, 0)
                        setJointRotationLimit(object.dynamicMountJointIndex, 1, true, 0, 0)
                        setJointRotationLimit(object.dynamicMountJointIndex, 2, true, 0, 0)
                        if doAttach == DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ or doAttach == DynamicMountUtil.TYPE_FIX_ATTACH then
                            setJointTranslationLimit(object.dynamicMountJointIndex, 0, true, -0.01, 0.01)
                            setJointTranslationLimit(object.dynamicMountJointIndex, 1, true, -0.01, 0.01)
                            setJointTranslationLimit(object.dynamicMountJointIndex, 2, true, -0.01, 0.01)
                        elseif doAttach == DynamicMountUtil.TYPE_AUTO_ATTACH_XZ then
                            setJointTranslationLimit(object.dynamicMountJointIndex, 0, true, -0.01, 0.01)
                            setJointTranslationLimit(object.dynamicMountJointIndex, 1, false, 0, 0)
                            setJointTranslationLimit(object.dynamicMountJointIndex, 2, true, -0.01, 0.01)
                        elseif doAttach == DynamicMountUtil.TYPE_AUTO_ATTACH_Y then
                            setJointTranslationLimit(object.dynamicMountJointIndex, 0, false, 0, 0)
                            setJointTranslationLimit(object.dynamicMountJointIndex, 1, true, -0.01, 0.01)
                            setJointTranslationLimit(object.dynamicMountJointIndex, 2, false, 0, 0)
                        end
                    end
                end
            end
        end
    end
end
function DynamicMountAttacher:lockDynamicMountedObject(object, x, y, z, rx, ry, rz)
    local spec = self.spec_dynamicMountAttacher
    DynamicMountUtil.unmountDynamic(object, false)
    object:removeFromPhysics()
    spec.pendingDynamicMountObjects[object] = nil
    object:setAbsolutePosition(x, y, z, rx, ry, rz, nil)
    object:addToPhysics()
    local trigger = spec.dynamicMountAttacherTrigger
    if object:mountDynamic(self, trigger.rootNode, trigger.jointNode, trigger.mountType, trigger.forceAcceleration) then
        return true
    end
    self:removeDynamicMountedObject(object, false)
    return false
end
function DynamicMountAttacher:addDynamicMountedObject(object)
    local spec = self.spec_dynamicMountAttacher
    if spec.dynamicMountedObjects[object] == nil then
        spec.dynamicMountedObjects[object] = object
        local lockedToPosition = false
        if object.getMountableLockPositions ~= nil then
            local lockPositions = object:getMountableLockPositions()
            local i = 1
            local x = 1
            for i = i, #lockPositions, x do
                local position = lockPositions[i]
                if string.endsWith(self.configFileName, position.xmlFilename) then
                    local jointNode = I3DUtil.indexToObject(self.components, position.jointNode, self.i3dMappings)
                    if jointNode ~= nil then
                        local x, y, z = localToWorld(jointNode, position.transOffset[1], position.transOffset[2], position.transOffset[3])
                        local rx, ry, rz = localRotationToWorld(jointNode, position.rotOffset[1], position.rotOffset[2], position.rotOffset[3])
                        if self:lockDynamicMountedObject(object, x, y, z, rx, ry, rz) then
                            lockedToPosition = true
                            break
                        end
                    end
                end
            end
        end
        if not lockedToPosition and object:isa(Vehicle) then
            local lockPositions = nil
            local minDistance = math.huge
            for jointNode, x in ipairs(spec.lockPositions) do
                if self:getIsDynamicLockPositionActive(x) and (object.configFileName ~= nil and string.endsWith(object.configFileName, x.xmlFilename)) then
                    local y = true
                    if next(x.configurations) ~= nil then
                        for rz, configIndex in pairs(x.configurations) do
                            if y then
                                y = true
                                if object.configurations ~= nil then
                                    y = object.configurations[rz] == configIndex
                                end
                            end
                        end
                    end
                    if y then
                        local z = calcDistanceFrom(x.jointNode, object.rootNode)
                        if z < minDistance then
                            lockPositions = x
                            minDistance = z
                        end
                    end
                end
            end
            if lockPositions ~= nil and (lockPositions.width ~= nil and (lockPositions.length ~= nil and lockPositions.height ~= nil)) then
                local x, i, position = localToWorld(lockPositions.jointNode, 0, lockPositions.height * 0.5, 0)
                local jointNode, x, y = getWorldRotation(lockPositions.jointNode)
                spec.overlapBoxHasCollision = false
                spec.overlapBoxIgnoreVehicle = object
                overlapBox(x, i, position, jointNode, x, y, lockPositions.width * 0.5, lockPositions.height * 0.5, lockPositions.length * 0.5, "dynamicMountLockPositionOverlapCallback", self, CollisionFlag.VEHICLE, true, false, false, true)
                if spec.overlapBoxHasCollision then
                    lockPositions = nil
                end
                spec.overlapBoxIgnoreVehicle = nil
            end
            if lockPositions ~= nil then
                local x, i, position = getWorldTranslation(lockPositions.jointNode)
                local jointNode, x, y = getWorldRotation(lockPositions.jointNode)
                if self:lockDynamicMountedObject(object, x, i, position, jointNode, x, y) then
                    ObjectChangeUtil.setObjectChanges(lockPositions.objectChanges, true, self, self.setMovingToolDirty)
                    lockPositions.state = true
                    lockPositions.object = object
                end
            end
        end
        if spec.transferMass and (object.setReducedComponentMass ~= nil and object:getAllowComponentMassReduction()) then
            object:setReducedComponentMass(true)
            self:setMassDirty()
        end
        if not spec.collisionBetweenObjects then
            for i, position in pairs(spec.dynamicMountedObjects) do
                if i ~= object then
                    local jointNode = object.nodeId or object.rootNode
                    local x = i.nodeId or i.rootNode
                    if jointNode ~= nil and x ~= nil then
                        setPairCollision(jointNode, x, false)
                    end
                end
            end
        end
        self:setDynamicMountAnimationState(true)
        self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
    end
end
function DynamicMountAttacher:removeDynamicMountedObject(object, isDeleting)
    local spec = self.spec_dynamicMountAttacher
    spec.dynamicMountedObjects[object] = nil
    if isDeleting then
        spec.pendingDynamicMountObjects[object] = nil
    end
    local i = 1
    for i = i, #spec.lockPositions do
        local position = spec.lockPositions[i]
        if position.state and position.object == object then
            ObjectChangeUtil.setObjectChanges(spec.lockPositions[i].objectChanges, false, self, self.setMovingToolDirty)
            position.state = false
            position.object = nil
        end
    end
    if spec.transferMass then
        self:setMassDirty()
    end
    if not spec.collisionBetweenObjects then
        for position, _ in pairs(spec.dynamicMountedObjects) do
            if position ~= object then
                local node1 = object.nodeId or object.rootNode
                local node2 = position.nodeId or position.rootNode
                if node1 ~= nil and node2 ~= nil then
                    setPairCollision(node1, node2, true)
                end
            end
        end
    end
    self:setDynamicMountAnimationState(false)
    self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
end
function DynamicMountAttacher:onUnmountObject(object)
    if self.spec_dynamicMountAttacher.dynamicMountedObjects[object] ~= nil then
        self:removeDynamicMountedObject(object, false)
    end
end
function DynamicMountAttacher:setDynamicMountAnimationState(state)
    if state then
        self:playAnimation(self.spec_dynamicMountAttacher.animationName, self.spec_dynamicMountAttacher.animationSpeed, self:getAnimationTime(self.spec_dynamicMountAttacher.animationName), true)
    else
        self:playAnimation(spec.animationName, -spec.animationSpeed, self:getAnimationTime(spec.animationName), true)
    end
end
function DynamicMountAttacher:loadDynamicLockPositionFromXML(xmlFile, key, lockPosition)
    lockPosition.xmlFilename = xmlFile:getValue(key .. "#xmlFilename")
    if lockPosition.xmlFilename == nil then
        Logging.xmlWarning(xmlFile, "Missing xmlFilename for lock position \'%s\'", key)
        return false
    end
    lockPosition.xmlFilename = lockPosition.xmlFilename:gsub("$data", "data")
    lockPosition.jointNode = xmlFile:getValue(key .. "#jointNode", nil, self.components, self.i3dMappings)
    if lockPosition.jointNode == nil then
        Logging.xmlWarning(xmlFile, "Missing jointNode for lock position \'%s\'", key)
        return false
    end
    lockPosition.configurations = {}
    xmlFile:iterate(key .. ".configuration", function(_, configKey)
        -- upvalues: (copy) self, (copy) lockPosition
        local name = self.xmlFile:getValue(configKey .. "#name")
        local index = self.xmlFile:getValue(configKey .. "#index")
        if name ~= nil and index ~= nil then
            lockPosition.configurations[name] = index
        end
    end)
    lockPosition.width = xmlFile:getValue(key .. "#width")
    lockPosition.length = xmlFile:getValue(key .. "#length")
    lockPosition.height = xmlFile:getValue(key .. "#height")
    lockPosition.objectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, lockPosition.objectChanges, self.components, self)
    lockPosition.state = false
    return true
end
function DynamicMountAttacher.getIsDynamicLockPositionActive(_, lockPosition)
    return not lockPosition.state
end
function DynamicMountAttacher:writeDynamicMountObjectsToStream(streamId, objects)
    local spec = self.spec_dynamicMountAttacher
    local objectIndex = table.size(objects)
    local num = math.min(objectIndex, spec.maxNumObjectsToSend)
    streamWriteUIntN(streamId, num, spec.numObjectBits)
    local objectIndex = 0
    for object, _ in pairs(objects) do
        objectIndex = objectIndex + 1
        if objectIndex <= num then
            NetworkUtil.writeNodeObject(streamId, object)
        else
            Logging.xmlWarning(self.xmlFile, "Not enough bits to send all mounted objects. Please increase \'%s\'", "vehicle.dynamicMountAttacher#numObjectBits")
        end
    end
end
function DynamicMountAttacher:readDynamicMountObjectsFromStream(streamId, objects)
    local sum = streamReadUIntN(streamId, self.spec_dynamicMountAttacher.numObjectBits)
    for k, _ in pairs(objects) do
        objects[k] = nil
    end
    for _ = 1, sum do
        objects[k] = NetworkUtil.readNodeObject(streamId) or objects[k]
    end
    return sum
end
function DynamicMountAttacher:getAllowDynamicMountObjects()
    return true
end
function DynamicMountAttacher:dynamicMountTriggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    local spec = self.spec_dynamicMountAttacher
    if spec.limitToKnownObjects then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil then
            local foundVehicle = false
            local i = 1
            for i = i, #spec.lockPositions do
                local position = spec.lockPositions[i]
                if not position.state and (object.configFileName ~= nil and string.endsWith(object.configFileName, position.xmlFilename)) then
                    foundVehicle = true
                    if next(position.configurations) ~= nil then
                        for configName, configIndex in pairs(position.configurations) do
                            if foundVehicle then
                                foundVehicle = true
                                if object.configurations ~= nil then
                                    foundVehicle = object.configurations[configName] == configIndex
                                end
                            end
                        end
                    end
                    if foundVehicle then
                        break
                    end
                end
            end
            if not foundVehicle then
                return
            end
        end
    end
    if getRigidBodyType(otherActorId) == RigidBodyType.DYNAMIC and not getHasTrigger(otherActorId) then
        if onEnter then
            local object = g_currentMission:getNodeObject(otherActorId)
            if object == nil then
                object = g_currentMission.nodeToObject[otherActorId]
            end
            if object == self.rootVehicle or self.spec_attachable ~= nil and self.spec_attachable.attacherVehicle == object then
                object = nil
            end
            if object ~= nil and object ~= self then
                local foundVehicle = object.getSupportsMountDynamic ~= nil and object:getSupportsMountDynamic()
                if foundVehicle then
                    foundVehicle = object.lastMoveTime ~= nil
                end
                local isVehicle = object.getSupportsTensionBelts ~= nil and object:getSupportsTensionBelts()
                if isVehicle then
                    isVehicle = object.lastMoveTime ~= nil
                end
                if foundVehicle or isVehicle then
                    spec.pendingDynamicMountObjects[object] = Utils.getNoNil(spec.pendingDynamicMountObjects[object], 0) + 1
                    if spec.pendingDynamicMountObjects[object] == 1 then
                        self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
                        return
                    end
                end
            end
        elseif onLeave then
            local object = g_currentMission:getNodeObject(otherActorId)
            if object == nil then
                object = g_currentMission.nodeToObject[otherActorId]
            end
            if object ~= nil and spec.pendingDynamicMountObjects[object] ~= nil then
                local foundVehicle = spec.pendingDynamicMountObjects[object] - 1
                if foundVehicle == 0 then
                    spec.pendingDynamicMountObjects[object] = nil
                    if spec.dynamicMountedObjects[object] ~= nil then
                        self:removeDynamicMountedObject(object, false)
                        object:unmountDynamic()
                        if object.additionalDynamicMountJointNode ~= nil then
                            delete(object.additionalDynamicMountJointNode)
                            object.additionalDynamicMountJointNode = nil
                        end
                    end
                    self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
                    return
                end
                spec.pendingDynamicMountObjects[object] = foundVehicle
            end
        end
    end
end
function DynamicMountAttacher:getAllowDynamicMountFillLevelInfo()
    return true
end
function DynamicMountAttacher:loadDynamicMountGrabFromXML(_, key, entry)
    local openMountType = self.xmlFile:getValue(key .. "#openMountType")
    entry.openMountType = Utils.getNoNil(DynamicMountUtil[openMountType], DynamicMountUtil.TYPE_FORK)
    local closedMountType = self.xmlFile:getValue(key .. "#closedMountType")
    entry.closedMountType = Utils.getNoNil(DynamicMountUtil[closedMountType], DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ)
    entry.currentMountType = entry.openMountType
    return true
end
function DynamicMountAttacher:getIsDynamicMountGrabOpened(grab)
    return true
end
function DynamicMountAttacher:getDynamicMountTimeToMount()
    return self.spec_dynamicMountAttacher.dynamicMountAttacherTimeToMount
end
function DynamicMountAttacher:getHasDynamicMountedObjects()
    return next(self.spec_dynamicMountAttacher.dynamicMountedObjects) ~= nil
end
function DynamicMountAttacher:forceDynamicMountPendingObjects(onlyBales)
    if self:getAllowDynamicMountObjects() then
        local spec = self.spec_dynamicMountAttacher
        for object, _ in pairs(spec.pendingDynamicMountObjects) do
            if spec.dynamicMountedObjects[object] == nil and (not onlyBales or object:isa(Bale)) then
                local trigger = spec.dynamicMountAttacherTrigger
                if object:mountDynamic(self, trigger.rootNode, trigger.jointNode, trigger.mountType, trigger.forceAcceleration) then
                    self:addDynamicMountedObject(object)
                end
            end
        end
    end
end
function DynamicMountAttacher:forceUnmountDynamicMountedObjects()
    for object, _ in pairs(self.spec_dynamicMountAttacher.dynamicMountedObjects) do
        self:removeDynamicMountedObject(object, false)
        object:unmountDynamic()
        if object.additionalDynamicMountJointNode ~= nil then
            delete(object.additionalDynamicMountJointNode)
            object.additionalDynamicMountJointNode = nil
        end
    end
end
function DynamicMountAttacher:getDynamicMountAttacherSettingsByNode(node)
    for _, fork in pairs(self.spec_dynamicMountAttacher.forks) do
        if fork.node == node then
            return fork.mountType, fork.forceLimitScale
        end
    end
    return DynamicMountUtil.TYPE_FORK, 1
end
function DynamicMountAttacher:dynamicMountLockPositionOverlapCallback(transformId)
    if g_currentMission.nodeToObject[transformId] ~= nil or g_currentMission.players[transformId] ~= nil then
        local spec = self.spec_dynamicMountAttacher
        if g_currentMission.nodeToObject[transformId] ~= self and g_currentMission.nodeToObject[transformId] ~= spec.overlapBoxIgnoreVehicle then
            spec.overlapBoxHasCollision = true
        end
    end
end
function DynamicMountAttacher:getFillLevelInformation(superFunc, display)
    superFunc(self, display)
    if self:getAllowDynamicMountFillLevelInfo() then
        for object, _ in pairs(self.spec_dynamicMountAttacher.dynamicMountedObjects) do
            if object.getFillLevelInformation == nil then
                if object.getFillLevel ~= nil and object.getFillType ~= nil then
                    local fillType = object:getFillType()
                    local fillLevel = object:getFillLevel()
                    local capacity
                    if object.getCapacity == nil then
                        capacity = fillLevel
                    else
                        capacity = object:getCapacity()
                    end
                    display:addFillLevel(fillType, fillLevel, capacity)
                end
            else
                object:getFillLevelInformation(display)
            end
        end
    end
end
function DynamicMountAttacher:getHasObjectMounted(superFunc, object)
    if superFunc(self, object) then
        return true
    end
    for dynamicMountedObject, _ in pairs(self.spec_dynamicMountAttacher.dynamicMountedObjects) do
        if dynamicMountedObject == object then
            return true
        end
        if dynamicMountedObject.getHasObjectMounted ~= nil and dynamicMountedObject:getHasObjectMounted(object) then
            return true
        end
    end
    return false
end
function DynamicMountAttacher:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
    if not superFunc(self, xmlFile, baseName, entry) then
        return false
    end
    entry.updateDynamicMountAttacher = xmlFile:getValue(baseName .. ".dynamicMountAttacher#value")
    return true
end
function DynamicMountAttacher:updateExtraDependentParts(superFunc, part, dt)
    superFunc(self, part, dt)
    if self.isServer and (part.updateDynamicMountAttacher ~= nil and part.updateDynamicMountAttacher) then
        for object, _ in pairs(self.spec_dynamicMountAttacher.dynamicMountedObjects) do
            setJointFrame(object.dynamicMountJointIndex, 0, object.dynamicMountJointNode)
        end
    end
end
function DynamicMountAttacher:getIsAttachedTo(superFunc, vehicle)
    if superFunc(self, vehicle) then
        return true
    end
    local spec = self.spec_dynamicMountAttacher
    for object, _ in pairs(spec.dynamicMountedObjects) do
        if object == vehicle then
            return true
        end
    end
    for object, _ in pairs(spec.pendingDynamicMountObjects) do
        if object == vehicle then
            return true
        end
    end
    return false
end
function DynamicMountAttacher:getAdditionalComponentMass(superFunc, component)
    local additionalMass = superFunc(self, component)
    local spec = self.spec_dynamicMountAttacher
    if spec.dynamicMountAttacherTrigger ~= nil and (spec.transferMass and spec.dynamicMountAttacherTrigger.component == component.node) then
        for object, _ in pairs(spec.dynamicMountedObjects) do
            if object.getAllowComponentMassReduction ~= nil and object:getAllowComponentMassReduction() then
                additionalMass = additionalMass + (object:getDefaultMass() - 0.1)
            end
        end
    end
    return additionalMass
end
function DynamicMountAttacher:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    if self.spec_dynamicMountAttacher.allowFoldingWhileMounted or not self:getHasDynamicMountedObjects() then
        return superFunc(self, direction, onAiTurnOn)
    else
        return false, g_i18n:getText("warning_toolIsFull")
    end
end
function DynamicMountAttacher:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
    if not superFunc(self, xmlFile, key, entry) then
        return false
    end
    entry.dynamicMountAttacherAllowedMounted = xmlFile:getValue(key .. ".dynamicMountAttacher#allowedMounted", true)
    return true
end
function DynamicMountAttacher:getIsMovingToolActive(superFunc, movingTool)
    if movingTool.dynamicMountAttacherAllowedMounted or next(self.spec_dynamicMountAttacher.dynamicMountedObjects) == nil then
        return superFunc(self, movingTool)
    else
        return false
    end
end
function DynamicMountAttacher:onPreAttachImplement(object, _, _, _)
    local objSpec = object.spec_dynamicMountAttacher
    if objSpec ~= nil and self.isServer then
        objSpec.pendingDynamicMountObjects[self] = nil
        if objSpec.dynamicMountedObjects[self] ~= nil then
            object:removeDynamicMountedObject(self, false)
            self:unmountDynamic()
            if object.additionalDynamicMountJointNode ~= nil then
                delete(object.additionalDynamicMountJointNode)
                object.additionalDynamicMountJointNode = nil
            end
        end
    end
end
function DynamicMountAttacher:updateDebugValues(values)
    local spec = self.spec_dynamicMountAttacher
    if self.isServer then
        table.insert(values, {
            ["name"] = "timeToMount:",
            ["value"] = string.format("%d", self.lastMoveTime + spec.dynamicMountAttacherTimeToMount - g_currentMission.time)
        })
        for object, _ in pairs(spec.pendingDynamicMountObjects) do
            local objectNode = {
                ["name"] = "pendingDynamicMountObject:"
            }
            objectNode.value = string.format("%s timeToMount: %d", object.configFileNameClean or object, (math.max(object.lastMoveTime + spec.dynamicMountAttacherTimeToMount - g_currentMission.time, 0)))
            table.insert(values, objectNode)
        end
        for object, _ in pairs(spec.dynamicMountedObjects) do
            local objectName = object.configFileNameClean
            if not objectName then
                if object.xmlFilename then
                    objectName = Utils.getFilenameFromPath(object.xmlFilename) or object
                else
                    objectName = object
                end
            end
            local objectColor = DebugUtil.tableToColor(object)
            local y = {
                ["name"] = "dynamicMountedObjects:",
                ["value"] = string.format("%s jointIndex:%s mountOffset:%.3f triggerCount:%s", objectName, object.dynamicMountJointIndex, object.dynamicMountJointNodeDynamicMountOffset or -1, object.dynamicMountObjectTriggerCount),
                ["color"] = objectColor
            }
            table.insert(values, y)
            local objectNode = object.nodeId or object.rootNode
            if objectNode ~= nil then
                local x, y, z = getWorldTranslation(objectNode)
                drawDebugPoint(x, y, z, objectColor[1], objectColor[2], objectColor[3], objectColor[4], false)
            end
        end
    end
    table.insert(values, {
        ["name"] = "allowMountObjects:",
        ["value"] = string.format("%s", self:getAllowDynamicMountObjects())
    })
    if spec.dynamicMountAttacherGrab ~= nil then
        table.insert(values, {
            ["name"] = "grabOpened:",
            ["value"] = string.format("%s", self:getIsDynamicMountGrabOpened(spec.dynamicMountAttacherGrab))
        })
    end
end