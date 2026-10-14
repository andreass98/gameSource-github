HookLiftTrailer = {}
function HookLiftTrailer.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) and SpecializationUtil.hasSpecialization(Foldable, specializations)
end
function HookLiftTrailer.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("HookLiftTrailer")
    schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.jointLimits#refAnimation", "Reference animation", "unfoldHand")
    schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.jointLimits.key(?)#time", "Key time")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.jointLimits.key(?)#rotLimit", "Rotation limit", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.jointLimits.key(?)#rotMinLimit", "Negative rotation limit")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.jointLimits.key(?)#rotMaxLimit", "Positive rotation limit")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.jointLimits.key(?)#transLimit", "Translation limit", "0 0 0")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.jointLimits.key(?)#transMinLimit", "Negative translation limit")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.jointLimits.key(?)#transMaxLimit", "Positive translation limit")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftTrailer.additionalJoint#node", "Additional joint to mount the container when fully lifted")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftTrailer.additionalJoint#attacherJointNode", "Attacher joint node of the hook")
    schema:register(XMLValueType.BOOL, "vehicle.hookLiftTrailer.additionalJoint#disableCollision", "Disable collision between trailer and container when fully lifted", false)
    schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.additionalJoint#lockTime", "Animation time when the additional joint is created", 0.01)
    schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.additionalJoint.key(?)#time", "Key time")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.additionalJoint.key(?)#rotLimit", "Rotation limit", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.additionalJoint.key(?)#rotMinLimit", "Negative rotation limit")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.additionalJoint.key(?)#rotMaxLimit", "Positive rotation limit")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.additionalJoint.key(?)#transLimit", "Translation limit", "0 0 0")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.additionalJoint.key(?)#transMinLimit", "Negative translation limit")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.additionalJoint.key(?)#transMaxLimit", "Positive translation limit")
    schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.unloadingAnimation#name", "Unload animation", "unloading")
    schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.unloadingAnimation#speed", "Unload animation speed", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.unloadingAnimation#reverseSpeed", "Unload animation reverse speed", -1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftTrailer.hookLock#referenceNode", "Reference node for distance to the container")
    schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.hookLock#minDistance", "Min. distance to the reference node to activate object change (in Y and Z offset)", 0.05)
    schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.hookLock#minDistanceSide", "Min. distance to the reference node to activate object change (in X offset)", 0.15)
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.hookLiftTrailer.hookLock")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.hookLiftTrailer.containerLock")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftTrailer.visualRoll(?)#node", "Visual roll that spins when the container gets close")
    schema:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.visualRoll(?)#radius", "Radius of the roll", 0.1)
    schema:register(XMLValueType.INT, "vehicle.hookLiftTrailer.visualRoll(?)#rotAxis", "Rotation axis", 1)
    schema:register(XMLValueType.INT, "vehicle.hookLiftTrailer.visualRoll(?)#direction", "Rotation direction", -1)
    schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#unloadContainer", "Unload container text", "$l10n_unload_container")
    schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#loadContainer", "Load container text", "$l10n_load_container")
    schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#unloadArm", "Unload arm text", "$l10n_unload_arm")
    schema:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#loadArm", "Load arm text", "$l10n_load_arm")
    schema:setXMLSpecializationType()
end
function HookLiftTrailer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "startTipping", HookLiftTrailer.startTipping)
    SpecializationUtil.registerFunction(vehicleType, "stopTipping", HookLiftTrailer.stopTipping)
    SpecializationUtil.registerFunction(vehicleType, "getIsTippingAllowed", HookLiftTrailer.getIsTippingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getCanDetachContainer", HookLiftTrailer.getCanDetachContainer)
    SpecializationUtil.registerFunction(vehicleType, "updateHookLiftContainerLockState", HookLiftTrailer.updateHookLiftContainerLockState)
    SpecializationUtil.registerFunction(vehicleType, "updateAdditionalHookLiftContainerJoint", HookLiftTrailer.updateAdditionalHookLiftContainerJoint)
    SpecializationUtil.registerFunction(vehicleType, "setHookLiftContainerPhysicsState", HookLiftTrailer.setHookLiftContainerPhysicsState)
end
function HookLiftTrailer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", HookLiftTrailer.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", HookLiftTrailer.isDetachAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", HookLiftTrailer.getDoConsumePtoPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPtoRpm", HookLiftTrailer.getPtoRpm)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", HookLiftTrailer.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", HookLiftTrailer.removeFromPhysics)
end
function HookLiftTrailer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HookLiftTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", HookLiftTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", HookLiftTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", HookLiftTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", HookLiftTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateAnimation", HookLiftTrailer)
end
function HookLiftTrailer:onLoad(_)
    local spec = self.spec_hookLiftTrailer
    spec.refAnimation = self.xmlFile:getValue("vehicle.hookLiftTrailer.jointLimits#refAnimation", "unfoldHand")
    local function loadJointLimits(xmlFile, limitsKey)
        local jointLimits = AnimCurve.new(linearInterpolatorN)
        for _, key in xmlFile:iterator(limitsKey .. ".key") do
            local t = xmlFile:getValue(key .. "#time")
            if t ~= nil then
                local rx, ry, rz = xmlFile:getValue(key .. "#rotLimit", "0 0 0")
                local minRx, minRy, minRz = xmlFile:getValue(key .. "#rotMinLimit")
                local maxRx, maxRy, maxRz = xmlFile:getValue(key .. "#rotMaxLimit")
                local tx, ty, tz = xmlFile:getValue(key .. "#transLimit", "0 0 0")
                local minTx, minTy, minTz = xmlFile:getValue(key .. "#transMinLimit")
                local maxTx, maxTy, maxTz = xmlFile:getValue(key .. "#transMaxLimit")
                jointLimits:addKeyframe({
                    minRx or -rx,
                    minRy or -ry,
                    minRz or -rz,
                    maxRx or rx,
                    maxRy or ry,
                    maxRz or rz,
                    minTx or -tx,
                    minTy or -ty,
                    minTz or -tz,
                    maxTx or tx,
                    maxTy or ty,
                    maxTz or tz,
                    ["time"] = t
                })
            end
        end
        if jointLimits.numKeyframes == 0 then
            return nil
        else
            return jointLimits
        end
    end
    spec.jointLimits = loadJointLimits(self.xmlFile, "vehicle.hookLiftTrailer.jointLimits")
    spec.additionalJointNode = self.xmlFile:getValue("vehicle.hookLiftTrailer.additionalJoint#node", nil, self.components, self.i3dMappings)
    spec.additionalJointReferenceJointNode = self.xmlFile:getValue("vehicle.hookLiftTrailer.additionalJoint#attacherJointNode", nil, self.components, self.i3dMappings)
    spec.additionalJointDisableCollision = self.xmlFile:getValue("vehicle.hookLiftTrailer.additionalJoint#disableCollision", false)
    spec.additionalJointLockTime = self.xmlFile:getValue("vehicle.hookLiftTrailer.additionalJoint#lockTime", 0.01)
    spec.additionalJointState = false
    if spec.additionalJointNode ~= nil and spec.additionalJointReferenceJointNode ~= nil then
        spec.additionalJointOffset = { localToLocal(spec.additionalJointNode, spec.additionalJointReferenceJointNode, 0, 0, 0) }
    end
    spec.additionalJointLimits = loadJointLimits(self.xmlFile, "vehicle.hookLiftTrailer.additionalJoint")
    spec.unloadingAnimation = self.xmlFile:getValue("vehicle.hookLiftTrailer.unloadingAnimation#name", "unloading")
    spec.unloadingAnimationSpeed = self.xmlFile:getValue("vehicle.hookLiftTrailer.unloadingAnimation#speed", 1)
    spec.unloadingAnimationReverseSpeed = self.xmlFile:getValue("vehicle.hookLiftTrailer.unloadingAnimation#reverseSpeed", -1)
    if self.isClient then
        spec.hookLock = {}
        spec.hookLock.state = false
        spec.hookLock.referenceNode = self.xmlFile:getValue("vehicle.hookLiftTrailer.hookLock#referenceNode", nil, self.components, self.i3dMappings)
        spec.hookLock.minDistance = self.xmlFile:getValue("vehicle.hookLiftTrailer.hookLock#minDistance", 0.05)
        spec.hookLock.minDistanceSide = self.xmlFile:getValue("vehicle.hookLiftTrailer.hookLock#minDistanceSide", 0.15)
        spec.hookLock.changeObjects = {}
        ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.hookLiftTrailer.hookLock", spec.hookLock.changeObjects, self.components, self)
        ObjectChangeUtil.setObjectChanges(spec.hookLock.changeObjects, false, self, self.setMovingToolDirty)
    end
    spec.containerLockState = false
    spec.containerLockChangeObjects = {}
    ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.hookLiftTrailer.containerLock", spec.containerLockChangeObjects, self.components, self)
    ObjectChangeUtil.setObjectChanges(spec.containerLockChangeObjects, false, self, self.setMovingToolDirty)
    spec.visualRolls = {}
    for _, key in self.xmlFile:iterator("vehicle.hookLiftTrailer.visualRoll") do
        local visualRoll = {
            ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if visualRoll.node ~= nil then
            visualRoll.radius = self.xmlFile:getValue(key .. "#radius", 0.1)
            visualRoll.rotAxis = self.xmlFile:getValue(key .. "#rotAxis", 1)
            visualRoll.direction = self.xmlFile:getValue(key .. "#direction", 1)
            table.insert(spec.visualRolls, visualRoll)
        end
    end
    spec.texts = {}
    spec.texts.unloadContainer = g_i18n:convertText(self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#unloadContainer", "$l10n_unload_container"), self.customEnvironment)
    spec.texts.loadContainer = g_i18n:convertText(self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#loadContainer", "$l10n_load_container"), self.customEnvironment)
    spec.texts.unloadArm = g_i18n:convertText(self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#unloadArm", "$l10n_unload_arm"), self.customEnvironment)
    spec.texts.loadArm = g_i18n:convertText(self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#loadArm", "$l10n_load_arm"), self.customEnvironment)
end
function HookLiftTrailer:onPostLoad(_)
    local spec = self.spec_hookLiftTrailer
    local foldableSpec = self.spec_foldable
    foldableSpec.posDirectionText = spec.texts.unloadArm
    foldableSpec.negDirectionText = spec.texts.loadArm
end
function HookLiftTrailer:onUpdateTick(_, _, _, _)
    local spec = self.spec_hookLiftTrailer
    if spec.attachedContainer ~= nil then
        local animTime = self:getAnimationTime(spec.refAnimation)
        local minRx = spec.attachedContainer.object
        local minRy = animTime > 0.95
        minRx.allowsDetaching = minRy
        if (self:getIsAnimationPlaying(spec.refAnimation) or not spec.attachedContainer.limitLocked) and not spec.attachedContainer.implement.attachingIsInProgress then
            if spec.jointLimits ~= nil then
                local minRx, minRy, minRz, maxRx, maxRy, maxRz, minTx, minTy, minTz, maxTx, maxTy, maxTz = spec.jointLimits:get(animTime)
                setJointRotationLimit(spec.attachedContainer.jointIndex, 0, true, minRx, maxRx)
                setJointRotationLimit(spec.attachedContainer.jointIndex, 1, true, minRy, maxRy)
                setJointRotationLimit(spec.attachedContainer.jointIndex, 2, true, minRz, maxRz)
                setJointTranslationLimit(spec.attachedContainer.jointIndex, 0, true, minTx, maxTx)
                setJointTranslationLimit(spec.attachedContainer.jointIndex, 1, true, minTy, maxTy)
                setJointTranslationLimit(spec.attachedContainer.jointIndex, 2, true, minTz, maxTz)
            end
            if spec.additionalJointLimits ~= nil and spec.attachedContainer.additionalJointIndex ~= nil then
                local minRx, minRy, minRz, maxRx, maxRy, maxRz, minTx, minTy, minTz, maxTx, maxTy, maxTz = spec.additionalJointLimits:get(animTime)
                setJointRotationLimit(spec.attachedContainer.additionalJointIndex, 0, true, minRx, maxRx)
                setJointRotationLimit(spec.attachedContainer.additionalJointIndex, 1, true, minRy, maxRy)
                setJointRotationLimit(spec.attachedContainer.additionalJointIndex, 2, true, minRz, maxRz)
                setJointTranslationLimit(spec.attachedContainer.additionalJointIndex, 0, true, minTx, maxTx)
                setJointTranslationLimit(spec.attachedContainer.additionalJointIndex, 1, true, minTy, maxTy)
                setJointTranslationLimit(spec.attachedContainer.additionalJointIndex, 2, true, minTz, maxTz)
            end
            if animTime >= 0.99 then
                spec.attachedContainer.limitLocked = true
            end
        end
    end
    if self.isClient and spec.hookLock.referenceNode ~= nil then
        local animTime = false
        local minRx = self.spec_attacherJoints.attachableInfo
        if minRx.attachable ~= nil and minRx.attachableJointDescIndex ~= nil then
            local minRy = minRx.attachable:getInputAttacherJointByJointDescIndex(minRx.attachableJointDescIndex)
            if minRy ~= nil then
                local minRz, maxRx, maxRy = localToLocal(minRy.node, spec.hookLock.referenceNode, 0, 0, 0)
                animTime = MathUtil.vector2Length(maxRx, maxRy) < spec.hookLock.minDistance and math.abs(minRz) < spec.hookLock.minDistanceSide and true or animTime
            end
        end
        if animTime ~= spec.hookLock.state then
            spec.hookLock.state = animTime
            ObjectChangeUtil.setObjectChanges(spec.hookLock.changeObjects, animTime, self, self.setMovingToolDirty)
        end
    end
end
function HookLiftTrailer:onPostAttachImplement(attachable, _, jointDescIndex, _)
    local attacherJoint = attachable:getActiveInputAttacherJoint()
    if attacherJoint ~= nil and attacherJoint.jointType == AttacherJoints.JOINTTYPE_HOOKLIFT then
        local jointDesc = self:getAttacherJointByJointDescIndex(jointDescIndex)
        self.spec_hookLiftTrailer.attachedContainer = {}
        spec.attachedContainer.jointIndex = jointDesc.jointIndex
        spec.attachedContainer.jointDescIndex = jointDescIndex
        spec.attachedContainer.implement = self:getImplementByObject(attachable)
        spec.attachedContainer.object = attachable
        spec.attachedContainer.limitLocked = false
        local foldableSpec = self.spec_foldable
        foldableSpec.posDirectionText = spec.texts.unloadContainer
        foldableSpec.negDirectionText = spec.texts.loadContainer
    end
    self:updateHookLiftContainerLockState()
end
function HookLiftTrailer:onPreDetachImplement(implement)
    local spec = self.spec_hookLiftTrailer
    if spec.attachedContainer ~= nil and implement == spec.attachedContainer.implement then
        spec.attachedContainer.object:onHookLiftContainerLockChanged(false)
        local foldableSpec = self.spec_foldable
        foldableSpec.posDirectionText = spec.texts.unloadArm
        foldableSpec.negDirectionText = spec.texts.loadArm
        if spec.attachedContainer.additionalJointIndex ~= nil then
            removeJoint(spec.attachedContainer.additionalJointIndex)
            spec.attachedContainer.additionalJointIndex = nil
        end
        if spec.attachedContainer.jointNodeContainer ~= nil then
            delete(spec.attachedContainer.jointNodeContainer)
            spec.attachedContainer.jointNodeContainer = nil
        end
        spec.attachedContainer = nil
    end
    self:updateHookLiftContainerLockState()
end
function HookLiftTrailer:onUpdateAnimation(name)
    local spec = self.spec_hookLiftTrailer
    if name == spec.refAnimation then
        self:updateHookLiftContainerLockState()
        if spec.attachedContainer ~= nil then
            local spec_hookLiftContainer = spec.attachedContainer.object.spec_hookLiftContainer
            local startNode = spec_hookLiftContainer.visualReferenceNodeStart
            local endNode = spec_hookLiftContainer.visualReferenceNodeEnd
            if startNode ~= nil and endNode ~= nil then
                local _, y1, z1 = localToLocal(startNode, self.rootNode, 0, 0, 0)
                local _, y2, z2 = localToLocal(endNode, self.rootNode, 0, 0, 0)
                local dirY = y2 - y1
                local dirZ = z2 - z1
                local length = MathUtil.vector2Length(dirY, dirZ)
                if length > 0 then
                    local dirY = dirY / length
                    local dirZ = dirZ / length
                    for _, visualRoll in ipairs(spec.visualRolls) do
                        local _, y3, z3 = localToLocal(visualRoll.node, self.rootNode, 0, 0, 0)
                        local positionOnLine = MathUtil.getProjectOnLineParameter(y3, z3, y1, z1, dirY, dirZ)
                        if positionOnLine >= 0 and positionOnLine <= length then
                            if MathUtil.vector2Length(y3 - (y1 + dirY * positionOnLine), z3 - (z1 + dirZ * positionOnLine)) <= visualRoll.radius + 0.025 then
                                if visualRoll.lastPositionOnLine == nil then
                                    visualRoll.lastPositionOnLine = positionOnLine
                                end
                                if visualRoll.rotAxis == 1 then
                                    rotate(visualRoll.node, (visualRoll.lastPositionOnLine - positionOnLine) / visualRoll.radius * visualRoll.direction, 0, 0)
                                elseif visualRoll.rotAxis == 2 then
                                    rotate(visualRoll.node, 0, rotOffset, 0)
                                elseif visualRoll.rotAxis == 3 then
                                    rotate(visualRoll.node, 0, 0, rotOffset)
                                end
                                visualRoll.lastPositionOnLine = positionOnLine
                            else
                                visualRoll.lastPositionOnLine = nil
                            end
                        else
                            visualRoll.lastPositionOnLine = nil
                        end
                    end
                end
            end
        end
    end
    if self.isServer and (name == spec.unloadingAnimation and (spec.attachedContainer ~= nil and spec.attachedContainer.additionalJointIndex ~= nil)) then
        setJointFrame(spec.attachedContainer.additionalJointIndex, 1, spec.additionalJointNode)
    end
end
function HookLiftTrailer:startTipping()
    local spec = self.spec_hookLiftTrailer
    self:playAnimation(spec.unloadingAnimation, spec.unloadingAnimationSpeed, self:getAnimationTime(spec.unloadingAnimation), true)
end
function HookLiftTrailer:stopTipping()
    local spec = self.spec_hookLiftTrailer
    self:playAnimation(spec.unloadingAnimation, spec.unloadingAnimationReverseSpeed, self:getAnimationTime(spec.unloadingAnimation), true)
end
function HookLiftTrailer:getIsTippingAllowed()
    return self:getAnimationTime(self.spec_hookLiftTrailer.refAnimation) == 0
end
function HookLiftTrailer:getCanDetachContainer()
    return self:getAnimationTime(self.spec_hookLiftTrailer.refAnimation) == 1
end
function HookLiftTrailer:updateHookLiftContainerLockState()
    local spec = self.spec_hookLiftTrailer
    local animTime = self:getAnimationTime(spec.refAnimation)
    local state = false
    if animTime < 0.001 then
        state = spec.attachedContainer ~= nil
    end
    if state ~= spec.containerLockState then
        spec.containerLockState = state
        ObjectChangeUtil.setObjectChanges(spec.containerLockChangeObjects, state, self, self.setMovingToolDirty)
        if spec.attachedContainer ~= nil then
            spec.attachedContainer.object:onHookLiftContainerLockChanged(state)
        end
    end
    if self.isServer then
        local additionalJointState = false
        if animTime < spec.additionalJointLockTime then
            additionalJointState = spec.attachedContainer ~= nil
        end
        if additionalJointState ~= spec.additionalJointState then
            spec.additionalJointState = additionalJointState
            self:updateAdditionalHookLiftContainerJoint()
        end
    end
end
function HookLiftTrailer:updateAdditionalHookLiftContainerJoint()
    local spec = self.spec_hookLiftTrailer
    if spec.additionalJointNode == nil then
        return
    else
        local attachedContainer = spec.attachedContainer
        if spec.additionalJointState and (attachedContainer ~= nil and (self.isAddedToPhysics and attachedContainer.object.isAddedToPhysics)) then
            local jointDesc = self:getAttacherJointByJointDescIndex(attachedContainer.jointDescIndex)
            local inputAttacherJoint = attachedContainer.object:getActiveInputAttacherJoint()
            local jointNodeContainer, constr, animTime
            if spec.additionalJointOffset == nil then
                jointNodeContainer, constr, animTime = localToLocal(spec.additionalJointNode, jointDesc.jointTransform, 0, 0, 0)
            else
                jointNodeContainer = spec.additionalJointOffset[1]
                constr = spec.additionalJointOffset[2]
                animTime = spec.additionalJointOffset[3]
            end
            local jointNodeContainer = createTransformGroup("hookLiftJointContainer")
            link(inputAttacherJoint.node, jointNodeContainer)
            setTranslation(jointNodeContainer, jointNodeContainer, constr, animTime)
            setRotation(jointNodeContainer, 0, 0, 0)
            local constr = JointConstructor.new()
            constr:setActors(inputAttacherJoint.rootNode, jointDesc.rootNode)
            constr:setJointTransforms(jointNodeContainer, spec.additionalJointNode)
            local animTime = self:getAnimationTime(spec.refAnimation)
            local minRx, minRy, minRz, maxRx, maxRy, maxRz, minTx, minTy, minTz, maxTx, maxTy, maxTz = spec.additionalJointLimits:get(animTime)
            constr:setRotationLimit(0, minRx, maxRx)
            constr:setRotationLimit(1, minRy, maxRy)
            constr:setRotationLimit(2, minRz, maxRz)
            constr:setTranslationLimit(0, true, minTx, maxTx)
            constr:setTranslationLimit(1, true, minTy, maxTy)
            constr:setTranslationLimit(2, true, minTz, maxTz)
            constr:setEnableCollision(not spec.additionalJointDisableCollision)
            attachedContainer.additionalJointIndex = constr:finalize()
            attachedContainer.jointNodeContainer = jointNodeContainer
        elseif attachedContainer ~= nil then
            if attachedContainer.additionalJointIndex ~= nil then
                removeJoint(spec.attachedContainer.additionalJointIndex)
                attachedContainer.additionalJointIndex = nil
            end
            if attachedContainer.jointNodeContainer ~= nil then
                delete(spec.attachedContainer.jointNodeContainer)
                attachedContainer.jointNodeContainer = nil
            end
        end
    end
end
function HookLiftTrailer:setHookLiftContainerPhysicsState(container, state)
    local spec = self.spec_hookLiftTrailer
    if spec.attachedContainer ~= nil and spec.attachedContainer.object == container then
        if state then
            local jointDesc = self:getAttacherJointByJointDescIndex(spec.attachedContainer.jointDescIndex)
            if jointDesc.jointIndex ~= 0 then
                spec.attachedContainer.jointIndex = jointDesc.jointIndex
                spec.attachedContainer.limitLocked = false
            end
        else
            spec.attachedContainer.jointIndex = 0
        end
        self:updateAdditionalHookLiftContainerJoint()
    end
end
function HookLiftTrailer:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    local spec = self.spec_hookLiftTrailer
    if spec.attachedContainer ~= nil then
        self:setHookLiftContainerPhysicsState(spec.attachedContainer.object, true)
    end
    return true
end
function HookLiftTrailer:removeFromPhysics(superFunc)
    local spec = self.spec_hookLiftTrailer
    if spec.attachedContainer ~= nil then
        self:setHookLiftContainerPhysicsState(spec.attachedContainer.object, false)
    end
    return superFunc(self) and true or false
end
function HookLiftTrailer:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    if self:getAnimationTime(self.spec_hookLiftTrailer.unloadingAnimation) > 0 then
        return false
    else
        return superFunc(self, direction, onAiTurnOn)
    end
end
function HookLiftTrailer:isDetachAllowed(superFunc)
    if self:getAnimationTime(self.spec_hookLiftTrailer.unloadingAnimation) == 0 then
        return superFunc(self)
    else
        return false, nil
    end
end
function HookLiftTrailer:getDoConsumePtoPower(superFunc)
    local spec = self.spec_hookLiftTrailer
    return superFunc(self) or (self:getIsAnimationPlaying(spec.refAnimation) or self:getIsAnimationPlaying(spec.unloadingAnimation))
end
function HookLiftTrailer:getPtoRpm(superFunc)
    local spec = self.spec_hookLiftTrailer
    local rpm = superFunc(self)
    if self:getIsAnimationPlaying(spec.refAnimation) or self:getIsAnimationPlaying(spec.unloadingAnimation) then
        return self.spec_powerConsumer.ptoRpm
    else
        return rpm
    end
end