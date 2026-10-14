PushHandTool = {}
PushHandTool.PLAYER_COLLISION_MASK = PlayerCCT.DEFAULT_MOVEMENT_COLLISION_MASK
source("dataS/scripts/vehicles/specializations/events/PushHandToolDriveModeEvent.lua")
function PushHandTool.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("PushHandTool")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#node1", "Front raycast node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#node2", "Back raycast node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#playerNode", "Player node to adjust")
    schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.raycast#positionSmoothnessFactor", "Defines how delayed the player position can be (lower value is a higher delay)", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.raycast#positionSmoothnessFactorReverse", "Smoothness factor while reversing", "same as #positionSmoothnessFactor")
    schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.raycast#positionSmoothnessFactorSteering", "Defines additional delay when the vehicle is fully steered (high value is a higher delay)", 0.15)
    schema:register(XMLValueType.VECTOR_N, "vehicle.pushHandTool.wheels#front", "Indices of front wheels")
    schema:register(XMLValueType.VECTOR_N, "vehicle.pushHandTool.wheels#back", "Indices of back wheels")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.handle#node", "Handle node")
    schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#upperLimit", "Max. upper distance between handle node and hand ik root node", 0.4)
    schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#lowerLimit", "Max. lower distance between handle node and hand ik root node", 0.4)
    schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#interpolateDistance", "Interpolation distance if limit is exceeded", 0.4)
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.handle#minRot", "Min. rotation of handle", -20)
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.handle#maxRot", "Max. rotation of handle", 20)
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#rotationForward", "Spine rotation while moving forward")
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#rotationBackward", "Spine rotation while moving backward")
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#rotationIdle", "Spine rotation while in idle position")
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.spine#speed", "Speed of adjustment (degree per second)", 10)
    schema:register(XMLValueType.VECTOR_3, "vehicle.pushHandTool.spine#ratio", "Ratio between the 3 spine nodes to apply the rotation", "0.33 0.33 0.33")
    IKUtil.registerIKChainTargetsXMLPaths(schema, "vehicle.pushHandTool.ikChains")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.pushHandTool.effect")
    schema:register(XMLValueType.STRING, "vehicle.pushHandTool.driveMode#animationName", "Name of toggle mode animation", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.driveMode#animationSpeed", "Animation speed scale", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.driveMode#maxSpeed", "Max. vehicle speed while drive mode is enabled")
    schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.driveMode#gearRatio", "Min. gear ratio while drive mode is enabled")
    VehicleCharacter.registerCharacterXMLPaths(schema, "vehicle.pushHandTool.driveMode.characterNode")
    schema:register(XMLValueType.STRING, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#chainId", "Chain identifier string", 20)
    schema:register(XMLValueType.INT, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#nodeIndex", "Index of node")
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRx", "Min. X rotation")
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRx", "Max. X rotation")
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRy", "Min. Y rotation")
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRy", "Max. Y rotation")
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRz", "Min. Z rotation")
    schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRz", "Max. Z rotation")
    schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#damping", "Damping")
    schema:register(XMLValueType.BOOL, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#localLimits", "Local limits")
    ConditionalAnimation.registerXMLPaths(schema, "vehicle.pushHandTool.playerConditionalAnimation")
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).pushHandTool#driveModeIsActive", "DriveMode is active")
end
function PushHandTool.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Enterable, specializations)
end
function PushHandTool.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getRaycastPosition", PushHandTool.getRaycastPosition)
    SpecializationUtil.registerFunction(vehicleType, "playerRaycastCallback", PushHandTool.playerRaycastCallback)
    SpecializationUtil.registerFunction(vehicleType, "postAnimationUpdate", PushHandTool.postAnimationUpdate)
    SpecializationUtil.registerFunction(vehicleType, "customVehicleCharacterLoaded", PushHandTool.customVehicleCharacterLoaded)
    SpecializationUtil.registerFunction(vehicleType, "setPushHandToolDriveMode", PushHandTool.setPushHandToolDriveMode)
end
function PushHandTool.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setVehicleCharacter", PushHandTool.setVehicleCharacter)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "deleteVehicleCharacter", PushHandTool.deleteVehicleCharacter)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowCharacterVisibilityUpdate", PushHandTool.getAllowCharacterVisibilityUpdate)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setActiveCameraIndex", PushHandTool.setActiveCameraIndex)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", PushHandTool.getIsFoldAllowed)
end
function PushHandTool.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onCameraChanged", PushHandTool)
    SpecializationUtil.registerEventListener(vehicleType, "onVehicleCharacterChanged", PushHandTool)
end
function PushHandTool:onLoad(_)
    local spec = self.spec_pushHandTool
    spec.animationParameters = {}
    spec.animationParameters.absSmoothedForwardVelocity = {
        ["id"] = 1,
        ["value"] = 0,
        ["type"] = 1
    }
    spec.animationParameters.smoothedForwardVelocity = {
        ["id"] = 2,
        ["value"] = 0,
        ["type"] = 1
    }
    spec.animationParameters.accelerate = {
        ["id"] = 3,
        ["value"] = false,
        ["type"] = 0
    }
    spec.animationParameters.leftRightWeight = {
        ["id"] = 4,
        ["value"] = 0,
        ["type"] = 1
    }
    spec.raycastNode1 = self.xmlFile:getValue("vehicle.pushHandTool.raycast#node1", nil, self.components, self.i3dMappings)
    spec.raycastNode2 = self.xmlFile:getValue("vehicle.pushHandTool.raycast#node2", nil, self.components, self.i3dMappings)
    spec.playerNode = self.xmlFile:getValue("vehicle.pushHandTool.raycast#playerNode", nil, self.components, self.i3dMappings)
    spec.playerTargetNode = createTransformGroup("playerTargetNode")
    if spec.playerNode ~= nil then
        link(getParent(spec.playerNode), spec.playerTargetNode)
        setTranslation(spec.playerTargetNode, getTranslation(spec.playerNode))
    end
    spec.positionSmoothnessFactor = self.xmlFile:getValue("vehicle.pushHandTool.raycast#positionSmoothnessFactor", 1)
    spec.positionSmoothnessFactorReverse = self.xmlFile:getValue("vehicle.pushHandTool.raycast#positionSmoothnessFactorReverse", spec.positionSmoothnessFactor)
    spec.positionSmoothnessFactorSteering = self.xmlFile:getValue("vehicle.pushHandTool.raycast#positionSmoothnessFactorSteering", 0.15)
    local frontWheels = self.xmlFile:getValue("vehicle.pushHandTool.wheels#front", nil, true)
    spec.frontWheels = {}
    if frontWheels ~= nil then
        local i = 1
        for i = i, #frontWheels do
            local wheel = self:getWheelFromWheelIndex(frontWheels[i])
            if wheel ~= nil then
                table.insert(spec.frontWheels, wheel)
            end
        end
    end
    local backWheels = self.xmlFile:getValue("vehicle.pushHandTool.wheels#back", nil, true)
    spec.backWheels = {}
    if backWheels ~= nil then
        local wheel = 1
        for wheel = wheel, #backWheels do
            local wheel = self:getWheelFromWheelIndex(backWheels[wheel])
            if wheel ~= nil then
                table.insert(spec.backWheels, wheel)
            end
        end
    end
    spec.handle = {}
    spec.handle.node = self.xmlFile:getValue("vehicle.pushHandTool.handle#node", nil, self.components, self.i3dMappings)
    spec.handle.upperLimit = self.xmlFile:getValue("vehicle.pushHandTool.handle#upperLimit", 0.4)
    spec.handle.lowerLimit = self.xmlFile:getValue("vehicle.pushHandTool.handle#lowerLimit", 0.4)
    spec.handle.interpolateDistance = self.xmlFile:getValue("vehicle.pushHandTool.handle#interpolateDistance", 0.4)
    spec.handle.minRot = self.xmlFile:getValue("vehicle.pushHandTool.handle#minRot", -20)
    spec.handle.maxRot = self.xmlFile:getValue("vehicle.pushHandTool.handle#maxRot", 20)
    spec.spine = {}
    spec.spine.node = nil
    spec.spine.rotationForward = self.xmlFile:getValue("vehicle.pushHandTool.spine#rotationForward")
    spec.spine.rotationBackward = self.xmlFile:getValue("vehicle.pushHandTool.spine#rotationBackward")
    spec.spine.rotationIdle = self.xmlFile:getValue("vehicle.pushHandTool.spine#rotationIdle")
    spec.spine.speed = self.xmlFile:getValue("vehicle.pushHandTool.spine#speed", 10) * 0.001
    spec.spine.ratio = self.xmlFile:getValue("vehicle.pushHandTool.spine#ratio", "0.33 0.33 0.33", true)
    spec.spine.currentRotation = spec.spine.rotationIdle
    local i = false
    if spec.spine.rotationForward ~= nil then
        i = false
        if spec.spine.rotationBackward ~= nil then
            i = spec.spine.rotationIdle ~= nil
        end
    end
    spec.spine.doAdjustment = i
    spec.characterIKNodes = {}
    spec.ikChainTargets = {}
    IKUtil.loadIKChainTargets(self.xmlFile, "vehicle.pushHandTool.ikChains", self.components, spec.ikChainTargets, self.i3dMappings)
    spec.lastRaycastPosition = {
        0,
        0,
        0,
        0
    }
    spec.lastRaycastHit = false
    if self.isClient then
        spec.cutterEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.pushHandTool.effect", self.components, self, self.i3dMappings)
    end
    spec.customChainLimits = {}
    self.xmlFile:iterate("vehicle.pushHandTool.customChainLimits.customChainLimit", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {
            ["chainId"] = self.xmlFile:getValue(key .. "#chainId"),
            ["nodeIndex"] = self.xmlFile:getValue(key .. "#nodeIndex")
        }
        if entry.chainId ~= nil and entry.nodeIndex ~= nil then
            entry.minRx = self.xmlFile:getValue(key .. "#minRx")
            entry.maxRx = self.xmlFile:getValue(key .. "#maxRx")
            entry.minRy = self.xmlFile:getValue(key .. "#minRy")
            entry.maxRy = self.xmlFile:getValue(key .. "#maxRy")
            entry.minRz = self.xmlFile:getValue(key .. "#minRz")
            entry.maxRz = self.xmlFile:getValue(key .. "#maxRz")
            entry.damping = self.xmlFile:getValue(key .. "#damping")
            entry.localLimits = self.xmlFile:getValue(key .. "#localLimits")
            table.insert(spec.customChainLimits, entry)
        end
    end)
    spec.driveMode = {}
    spec.driveMode.animationName = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#animationName")
    spec.driveMode.animationSpeed = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#animationSpeed", 1)
    spec.driveMode.baseSpeed = self.spec_motorized.motor.maxForwardSpeed
    spec.driveMode.baseGearRatio = self.spec_motorized.motor.minForwardGearRatio
    spec.driveMode.maxSpeed = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#maxSpeed")
    if spec.driveMode.maxSpeed ~= nil then
        spec.driveMode.maxSpeed = spec.driveMode.maxSpeed / 3.6
    end
    spec.driveMode.gearRatio = self.xmlFile:getValue("vehicle.pushHandTool.driveMode#gearRatio")
    spec.driveMode.vehicleCharacter = VehicleCharacter.new(self)
    if spec.driveMode.vehicleCharacter ~= nil and not spec.driveMode.vehicleCharacter:load(self.xmlFile, "vehicle.pushHandTool.driveMode.characterNode") then
        spec.driveMode.vehicleCharacter = nil
    end
    spec.driveMode.isActive = false
    spec.effectDirtyFlag = self:getNextDirtyFlag()
    spec.effectsAreRunning = false
    spec.lastFruitTypeIndex = FruitType.UNKNOWN
    spec.lastFruitGrowthState = 0
    spec.raycastsValid = true
    spec.lastSmoothSpeed = 0
    if self.setTestAreaRequirements ~= nil then
        self:setTestAreaRequirements(FruitType.GRASS, nil, false)
    end
    spec.postAnimationCallback = addPostAnimationCallback(self.postAnimationUpdate, self)
end
function PushHandTool:onPostLoad(savegame)
    if savegame ~= nil and savegame.xmlFile:getValue(savegame.key .. ".pushHandTool#driveModeIsActive", false) then
        self:setPushHandToolDriveMode(true, true)
        AnimatedVehicle.updateAnimationByName(self, self.spec_pushHandTool.driveMode.animationName, 99999, true)
    end
end
function PushHandTool:onDelete()
    local spec = self.spec_pushHandTool
    g_effectManager:deleteEffects(spec.cutterEffects)
    removePostAnimationCallback(spec.postAnimationCallback)
end
function PushHandTool:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_pushHandTool
    if spec.driveMode.animationName ~= nil then
        xmlFile:setValue(key .. "#driveModeIsActive", spec.driveMode.isActive)
    end
end
function PushHandTool:onReadStream(streamId, _)
    self:setPushHandToolDriveMode(streamReadBool(streamId), true)
    AnimatedVehicle.updateAnimationByName(self, self.spec_pushHandTool.driveMode.animationName, 99999, true)
end
function PushHandTool:onWriteStream(streamId, _)
    streamWriteBool(streamId, self.spec_pushHandTool.driveMode.isActive)
end
function PushHandTool:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        local spec = self.spec_pushHandTool
        local effectsAreRunning = streamReadBool(streamId)
        if effectsAreRunning then
            spec.lastFruitGrowthState = streamReadUIntN(streamId, 4)
            spec.lastFruitTypeIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
        end
        if effectsAreRunning ~= spec.effectsAreRunning then
            spec.effectsAreRunning = effectsAreRunning
            if not effectsAreRunning then
                g_effectManager:stopEffects(spec.cutterEffects)
            end
        end
    end
end
function PushHandTool:onWriteUpdateStream(streamId, connection, _)
    if not connection:getIsServer() then
        local spec = self.spec_pushHandTool
        if streamWriteBool(streamId, spec.effectsAreRunning) then
            streamWriteUIntN(streamId, spec.lastFruitGrowthState, 4)
            streamWriteUIntN(streamId, spec.lastFruitTypeIndex, FruitTypeManager.SEND_NUM_BITS)
        end
    end
end
function PushHandTool:onUpdate(dt, _, _, _)
    local spec = self.spec_pushHandTool
    if self.getTestAreaWidthByWorkAreaIndex ~= nil then
        if self:getIsTurnedOn() and self:getLastSpeed() > 0.5 then
            local currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX = self:getTestAreaWidthByWorkAreaIndex(1)
            local reset = false
            if currentTestAreaMinX == -math.huge and currentTestAreaMaxX == math.huge then
                currentTestAreaMinX = 0
                currentTestAreaMaxX = 0
                reset = true
            end
            local currentTestAreaMinX
            if self.movingDirection > 0 then
                currentTestAreaMinX = currentTestAreaMinX * -1
                currentTestAreaMinX = currentTestAreaMaxX * -1
                if currentTestAreaMinX >= currentTestAreaMinX then
                end
            else
                currentTestAreaMinX = currentTestAreaMaxX
            end
            local t, inputGrowthState, specMower
            if self.isServer then
                t = FruitType.UNKNOWN
                inputGrowthState = 3
                if self.spec_mower ~= nil then
                    local specMower = self.spec_mower
                    if g_time - specMower.workAreaParameters.lastCutTime < 500 then
                        t = specMower.workAreaParameters.lastInputFruitType
                        inputGrowthState = specMower.workAreaParameters.lastInputGrowthState
                    end
                end
                specMower = not reset
                if specMower then
                    specMower = false
                    if t ~= nil then
                        specMower = t ~= FruitType.UNKNOWN
                    end
                end
                if specMower then
                    if not spec.effectsAreRunning then
                        spec.effectsAreRunning = true
                        self:raiseDirtyFlags(spec.effectDirtyFlag)
                    end
                elseif spec.effectsAreRunning then
                    g_effectManager:stopEffects(spec.cutterEffects)
                    spec.effectsAreRunning = false
                    self:raiseDirtyFlags(spec.effectDirtyFlag)
                end
                spec.lastFruitTypeIndex = t
                spec.lastFruitGrowthState = inputGrowthState
            else
                t = spec.lastFruitTypeIndex
                inputGrowthState = spec.lastFruitGrowthState
                specMower = spec.effectsAreRunning
                if specMower then
                    specMower = spec.lastFruitTypeIndex ~= FruitType.UNKNOWN
                end
            end
            if specMower then
                g_effectManager:setEffectTypeInfo(spec.cutterEffects, nil, t, inputGrowthState)
                g_effectManager:setMinMaxWidth(spec.cutterEffects, currentTestAreaMinX, currentTestAreaMinX, currentTestAreaMinX / testAreaMinX, currentTestAreaMinX / testAreaMaxX, reset)
                g_effectManager:startEffects(spec.cutterEffects)
            end
        elseif spec.effectsAreRunning then
            g_effectManager:stopEffects(spec.cutterEffects)
            spec.effectsAreRunning = false
            self:raiseDirtyFlags(spec.effectDirtyFlag)
        end
    end
    local currentTestAreaMinX = self.lastSignedSpeed * 1000
    local currentTestAreaMaxX = 0
    local testAreaMinX = 0
    for inputGrowthState, isActive in pairs(spec.backWheels) do
        if isActive.physics.netInfo.xDriveSpeed ~= nil then
            currentTestAreaMaxX = currentTestAreaMaxX + MathUtil.rpmToMps(isActive.physics.netInfo.xDriveSpeed / 6.283185307179586 * 60, isActive.physics.radius) * 1000
        end
    end
    if testAreaMinX > 0 then
        currentTestAreaMinX = currentTestAreaMaxX / testAreaMinX
    end
    spec.lastSmoothSpeed = spec.lastSmoothSpeed * 0.9 + currentTestAreaMinX * 0.1
    spec.animationParameters.smoothedForwardVelocity.value = spec.lastSmoothSpeed
    local testAreaMaxX = spec.animationParameters.absSmoothedForwardVelocity
    local t = spec.lastSmoothSpeed
    testAreaMaxX.value = math.abs(t)
    spec.animationParameters.leftRightWeight.value = self.rotatedTime
    local testAreaMaxX = spec.animationParameters.accelerate
    local reset = self:getAccelerationAxis() > 0
    testAreaMaxX.value = reset
    if self:getIsEntered() or (self:getIsControlled() or self:getIsAIActive()) then
        local testAreaMaxX = self:getVehicleCharacter()
        if testAreaMaxX ~= nil and (testAreaMaxX.animationCharsetId ~= nil and testAreaMaxX.animationPlayer ~= nil) then
            for isActive, specMower in pairs(spec.animationParameters) do
                if specMower.type == 0 then
                    setConditionalAnimationBoolValue(testAreaMaxX.animationPlayer, specMower.id, specMower.value)
                elseif specMower.type == 1 then
                    setConditionalAnimationFloatValue(testAreaMaxX.animationPlayer, specMower.id, specMower.value)
                end
            end
            setConditionalAnimationSpecificParameterIds(testAreaMaxX.animationPlayer, spec.animationParameters.absSmoothedForwardVelocity.id, 0)
            updateConditionalAnimation(testAreaMaxX.animationPlayer, dt)
        end
        if spec.driveMode.vehicleCharacter ~= nil and (spec.driveMode.isActive and not self:getIsAnimationPlaying(spec.driveMode.animationName)) then
            spec.driveMode.vehicleCharacter:update(dt)
        end
    end
    if spec.spine.doAdjustment then
        local testAreaMaxX = spec.spine.rotationIdle
        if self:getLastSpeed() > 0.75 then
            if self.movingDirection > 0 then
                testAreaMaxX = spec.spine.rotationForward
            elseif self.movingDirection < 0 then
                testAreaMaxX = spec.spine.rotationBackward
            end
        end
        local reset = math.sign(testAreaMaxX - spec.spine.currentRotation)
        spec.spine.currentRotation = (reset > 0 and math.min or math.max)(spec.spine.currentRotation + reset * dt * spec.spine.speed, testAreaMaxX)
    end
    if spec.raycastNode1 ~= nil and (spec.raycastNode2 ~= nil and (spec.playerNode ~= nil and (#spec.frontWheels >= 1 and #spec.backWheels >= 1))) then
        local testAreaMaxX, reset, t = self:getRaycastPosition(spec.raycastNode1)
        local inputGrowthState, isActive, specMower = self:getRaycastPosition(spec.raycastNode2)
        if testAreaMaxX ~= nil and inputGrowthState ~= nil then
            local tx = (testAreaMaxX + inputGrowthState) * 0.5
            local ty = (reset + isActive) * 0.5
            local tz = (t + specMower) * 0.5
            setWorldTranslation(spec.playerTargetNode, tx, ty, tz)
            local cx, cy, cz = MathUtil.vector3Normalize(testAreaMaxX - inputGrowthState, reset - isActive, t - specMower)
            if spec.lastYDirection == nil then
                spec.lastYDirection = cy
            else
                cy = spec.lastYDirection * 0.9 + cy * 0.1
                spec.lastYDirection = cy
            end
            I3DUtil.setWorldDirection(spec.playerTargetNode, cx, cy, cz, 0, 1, 0)
            if spec.lastWorldTrans == nil then
                spec.lastWorldTrans = { getWorldTranslation(spec.playerNode) }
            end
            local cx = spec.lastWorldTrans[1]
            local cy = spec.lastWorldTrans[2]
            local cz = spec.lastWorldTrans[3]
            local newX = math.abs(self.rotatedTime / 0.5)
            local smoothFactor = (0.3 - math.min(newX, 1) * spec.positionSmoothnessFactorSteering) * (self.movingDirection > 0 and spec.positionSmoothnessFactor or spec.positionSmoothnessFactorReverse)
            local newX = cx - (cx - tx) * smoothFactor
            local newZ = cz - (cz - tz) * smoothFactor
            setWorldTranslation(spec.playerNode, newX, cy - (cy - ty) * smoothFactor, newZ)
            spec.lastWorldTrans[1] = newX
            spec.lastWorldTrans[2] = newY
            spec.lastWorldTrans[3] = newZ
            local dirY2, _, fcx = localToWorld(spec.playerTargetNode, 0, 0, 0.2 * (self.movingDirection == 0 and 1 or self.movingDirection))
            local fcx, fcy, fcz = MathUtil.vector3Normalize(dirY2 - newX, _ - newY, fcx - newZ)
            if direction < 0 then
            end
            local fcx = 0
            local fcy = 0
            local fcz = 0
            local numFrontWheels = #spec.frontWheels
            local i = 1
            local bcy = 1
            for i = i, numFrontWheels, bcy do
                local wheel = spec.frontWheels[i]
                local wheel, wx, wy = localToWorld(wheel.node, wheel.physics.netInfo.x, wheel.physics.netInfo.y - wheel.physics.radius, wheel.physics.netInfo.z)
            end
            local fcx = fcx / numFrontWheels
            local fcy = fcy / numFrontWheels
            local fcz = fcz / numFrontWheels
            local bcx = 0
            local bcy = 0
            local i = 0
            local wheel = #spec.backWheels
            local wz = 1
            local wy = 1
            for wz = wz, wheel, wy do
                local wheel = spec.backWheels[wz]
                local wx, wy, wz = localToWorld(wheel.node, wheel.physics.netInfo.x, wheel.physics.netInfo.y - wheel.physics.radius, wheel.physics.netInfo.z)
            end
            local bcx = bcx / wheel
            local bcy = bcy / wheel
            local i = i / wheel
            local wx = bcx - fcx
            local wy = bcy - fcy
            local wz = i - fcz
            local wheel, wx, wy = MathUtil.vector3Normalize(wx, wy, wz)
            local wheel = wx < 0 and 1 or -1
            local dirY = wx + math.min(0.15, (math.abs(wx))) * wheel
            local wx, wy, wz = localDirectionToWorld(self.rootNode, 0, 1, 0)
            local wy = wy + 0.5
            local wx, wy, wz = MathUtil.vector3Normalize(wx, wy, wz)
            I3DUtil.setWorldDirection(spec.playerNode, fcx, dirY, fcz, wx, wy, wz)
            spec.raycastsValid = true
            return
        end
        if spec.raycastsValid and self:getIsEntered() then
            spec.raycastsValid = false
            local tx = self:getVehicleCharacter()
            if tx ~= nil then
                tx:setCharacterVisibility(false)
            end
            self:setActiveCameraIndex(self.spec_enterable.camIndex)
        end
    end
end
function PushHandTool:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_pushHandTool
        if spec.driveMode.vehicleCharacter ~= nil then
            self:clearActionEventsTable(spec.actionEvents)
            if isActiveForInputIgnoreSelection then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, PushHandTool.actionEventToggleDriveMode, false, true, false, true, 1)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
                g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_changeDriveMode"))
            end
        end
    end
end
function PushHandTool:actionEventToggleDriveMode(_, _, _, _)
    self:setPushHandToolDriveMode()
end
function PushHandTool:setVehicleCharacter(_, playerStyle)
    local enterableSpec = self.spec_enterable
    if enterableSpec.vehicleCharacter ~= nil then
        enterableSpec.vehicleCharacter:unloadCharacter()
        enterableSpec.vehicleCharacter:loadCharacter(playerStyle, self, self.customVehicleCharacterLoaded)
    end
    local spec = self.spec_pushHandTool
    if spec.driveMode.vehicleCharacter ~= nil and playerStyle ~= nil then
        spec.driveMode.vehicleCharacter:loadCharacter(playerStyle, self, PushHandTool.driveModeVehicleCharacterLoaded, {})
    end
end
function PushHandTool:deleteVehicleCharacter(superFunc)
    superFunc(self)
    local spec = self.spec_pushHandTool
    if spec.driveMode.vehicleCharacter ~= nil then
        spec.driveMode.vehicleCharacter:unloadCharacter()
    end
end
function PushHandTool:customVehicleCharacterLoaded(loadingState, _)
    if loadingState == HumanModelLoadingState.OK then
        local character = self.spec_enterable.vehicleCharacter
        if character ~= nil then
            character:updateVisibility()
        end
        SpecializationUtil.raiseEvent(self, "onVehicleCharacterChanged", character)
        local spec = self.spec_pushHandTool
        spec.characterIKNodes = {}
        spec.spine.node = character.playerModel.thirdPersonSpineNode
        for name, ikChain in pairs(character.playerModel.ikChains) do
            if spec.ikChainTargets[name] ~= nil then
                for k, nodeData in pairs(ikChain.nodes) do
                    if spec.characterIKNodes[nodeData.node] == nil then
                        local duplicate = createTransformGroup(getName(nodeData.node) .. "_ikChain")
                        local parent = getParent(nodeData.node)
                        if spec.characterIKNodes[parent] ~= nil then
                        end
                        link(parent, duplicate)
                        setTranslation(duplicate, getTranslation(nodeData.node))
                        setRotation(duplicate, getRotation(nodeData.node))
                        spec.characterIKNodes[nodeData.node] = duplicate
                    end
                end
            end
            for k, nodeData in pairs(ikChain.nodes) do
                if spec.characterIKNodes[nodeData.node] ~= nil then
                    nodeData.node = spec.characterIKNodes[nodeData.node]
                end
            end
        end
        character.ikChainTargets = spec.ikChainTargets
        for name, ikChain in pairs(spec.ikChainTargets) do
            IKUtil.setTarget(character.playerModel.ikChains, name, ikChain)
        end
        spec.ikChains = character.playerModel.ikChains
        for name, ikChain in pairs(character.playerModel.ikChains) do
            ikChain.ikChainSolver = IKChain.new(#ikChain.nodes)
            for k, nodeData in ipairs(ikChain.nodes) do
                local duplicate = nodeData.minRx
                local parent = nodeData.maxRx
                local minRy = nodeData.minRy
                local maxRy = nodeData.maxRy
                local minRz = nodeData.minRz
                local maxRz = nodeData.maxRz
                local damping = nodeData.damping
                local localLimits = nodeData.localLimits
                local j = 1
                for j = j, #spec.customChainLimits do
                    local customLimit = spec.customChainLimits[j]
                    if customLimit.chainId == name and customLimit.nodeIndex == k then
                        if customLimit.localLimits ~= nil then
                            localLimits = customLimit.localLimits
                        end
                    end
                end
                ikChain.ikChainSolver:setJointTransformGroup(k - 1, nodeData.node, duplicate, parent, minRy, maxRy, minRz, maxRz, damping, localLimits)
            end
            ikChain.numIterations = 40
            ikChain.positionThreshold = 0.0001
        end
        character:setDirty()
        if character ~= nil and (character.animationCharsetId ~= nil and character.animationPlayer ~= nil) then
            for name, ikChain in pairs(spec.animationParameters) do
                conditionalAnimationRegisterParameter(character.animationPlayer, ikChain.id, ikChain.type, name)
            end
            initConditionalAnimation(character.animationPlayer, character.animationCharsetId, self.configFileName, "vehicle.pushHandTool.playerConditionalAnimation")
            conditionalAnimationZeroiseTrackTimes(character.animationPlayer)
        end
    end
end
function PushHandTool:driveModeVehicleCharacterLoaded(loadingState, _)
    if loadingState == HumanModelLoadingState.OK then
        local spec = self.spec_pushHandTool
        if spec.driveMode.vehicleCharacter ~= nil then
            local activeCamera = self:getActiveCamera()
            if activeCamera ~= nil then
                spec.driveMode.vehicleCharacter:setCharacterVisibility(not activeCamera.isInside)
            end
            spec.driveMode.vehicleCharacter:updateIKChains()
        end
    end
end
function PushHandTool:setPushHandToolDriveMode(driveModeState, noEventSend)
    local spec = self.spec_pushHandTool
    if driveModeState == nil then
        driveModeState = not spec.driveMode.isActive
    end
    if spec.driveMode.isActive ~= driveModeState then
        spec.driveMode.isActive = driveModeState
        self.spec_motorized.motor.maxForwardSpeed = driveModeState and spec.driveMode.maxSpeed or spec.driveMode.baseSpeed
        self.spec_motorized.motor.minForwardGearRatio = driveModeState and spec.driveMode.gearRatio or spec.driveMode.baseGearRatio
        self.spec_drivable.cruiseControl.maxSpeed = self.spec_motorized.motor.maxForwardSpeed * 3.6
        self:setCruiseControlMaxSpeed(math.min(self.spec_drivable.cruiseControl.speed, self.spec_drivable.cruiseControl.maxSpeed), nil)
        self:playAnimation(spec.driveMode.animationName, driveModeState and spec.driveMode.animationSpeed or -spec.driveMode.animationSpeed, self:getAnimationTime(spec.driveMode.animationName), true)
        self:setFoldState(self.spec_foldable.turnOnFoldDirection, false, true)
        if spec.driveMode.vehicleCharacter ~= nil then
            local character = self:getVehicleCharacter()
            if character ~= nil then
                character:setCharacterVisibility(false)
            end
        end
    end
    PushHandToolDriveModeEvent.sendEvent(self, driveModeState, noEventSend)
end
function PushHandTool:getAllowCharacterVisibilityUpdate(superFunc)
    if superFunc(self) then
        if self:getIsEntered() then
            local activeCamera = self:getActiveCamera()
            if activeCamera ~= nil and activeCamera.isInside then
                return false
            end
        end
        local activeCamera = self.spec_pushHandTool
        if activeCamera.raycastsValid then
            if activeCamera.driveMode.isActive and activeCamera.driveMode.vehicleCharacter ~= nil then
                return false
            else
                return (activeCamera.driveMode.vehicleCharacter == nil or not self:getIsAnimationPlaying(activeCamera.driveMode.animationName)) and true or false
            end
        else
            return false
        end
    else
        return false
    end
end
function PushHandTool:setActiveCameraIndex(superFunc, index)
    if not self.spec_pushHandTool.raycastsValid then
        local specEnterable = self.spec_enterable
        index = specEnterable.numCameras < index and 1 or index
        if specEnterable.cameras[index].isInside then
            for i, camera in pairs(specEnterable.cameras) do
                if not camera.isInside then
                    index = i
                    break
                end
            end
        end
    end
    return superFunc(self, index)
end
function PushHandTool:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    if self.spec_pushHandTool.driveMode.isActive then
        return false
    else
        return superFunc(self, direction, onAiTurnOn)
    end
end
function PushHandTool:onEnterVehicle(isControlling)
    local hideCharacter = false
    if isControlling then
        local activeCamera = self:getActiveCamera()
    end
    if not self.spec_pushHandTool.raycastsValid and true or hideCharacter then
        local character = self:getVehicleCharacter()
        if character ~= nil then
            character:setCharacterVisibility(false)
        end
    end
end
function PushHandTool:onCameraChanged(activeCamera, _)
    if self:getIsEntered() then
        local spec = self.spec_pushHandTool
        local character = self:getVehicleCharacter()
        if character ~= nil and activeCamera.isInside then
            character:setCharacterVisibility(false)
        end
        if spec.driveMode.vehicleCharacter ~= nil then
            spec.driveMode.vehicleCharacter:setCharacterVisibility(not activeCamera.isInside)
        end
    end
end
function PushHandTool:onVehicleCharacterChanged(character)
    if self:getIsEntered() and character ~= nil then
        local activeCamera = self:getActiveCamera()
        if activeCamera ~= nil and activeCamera.isInside then
            character:setCharacterVisibility(false)
        end
    end
    if character == nil then
        local activeCamera = self.spec_pushHandTool
        activeCamera.characterIKNodes = {}
        activeCamera.spine.node = nil
    end
end
function PushHandTool:postAnimationUpdate(_)
    if self.isActive then
        local spec = self.spec_pushHandTool
        if spec.raycastsValid and (spec.handle.node ~= nil and spec.ikChains ~= nil) then
            local yDifference = nil
            for name, ikChain in pairs(spec.ikChains) do
                local node = ikChain.nodes[1].node
                if node ~= nil and spec.ikChainTargets[name] ~= nil then
                    local targetNode = spec.ikChainTargets[name].targetNode
                    if targetNode ~= nil then
                        local x, y, z = getRotation(spec.handle.node)
                        setRotation(spec.handle.node, 0, 0, 0)
                        if yDifference == nil then
                            yDifference = calcDistanceFrom(node, targetNode)
                        else
                            yDifference = (yDifference + calcDistanceFrom(node, targetNode)) / 2
                        end
                        setRotation(spec.handle.node, x, y, z)
                    end
                end
            end
            if yDifference ~= nil then
                if yDifference < spec.handle.upperLimit then
                    setRotation(spec.handle.node, spec.handle.minRot * ((spec.handle.upperLimit - yDifference) / spec.handle.interpolateDistance), 0, 0)
                elseif spec.handle.lowerLimit < yDifference then
                    setRotation(spec.handle.node, spec.handle.maxRot * ((yDifference - spec.handle.lowerLimit) / spec.handle.interpolateDistance), 0, 0)
                end
            end
        end
        if spec.spine.node ~= nil and spec.spine.doAdjustment then
            setRotation(spec.spine.node, 0, 0, spec.spine.currentRotation * spec.spine.ratio[1])
            local yDifference = getChildAt(spec.spine.node, 0)
            setRotation(yDifference, 0, 0, spec.spine.currentRotation * spec.spine.ratio[2])
            local alpha = getChildAt(yDifference, 0)
            setRotation(alpha, 0, 0, spec.spine.currentRotation * spec.spine.ratio[3])
        end
        if (not (spec.driveMode.isActive or self:getIsAnimationPlaying(spec.driveMode.animationName)) or spec.driveMode.vehicleCharacter == nil) and spec.ikChains ~= nil then
            for chainId, name in pairs(spec.ikChainTargets) do
                IKUtil.setIKChainDirty(spec.ikChains, chainId)
            end
            IKUtil.updateIKChains(spec.ikChains)
            for chainId, name in pairs(spec.characterIKNodes) do
                if entityExists(chainId) and entityExists(name) then
                    setTranslation(chainId, getTranslation(name))
                    setRotation(chainId, getRotation(name))
                end
            end
            for chainId, name in pairs(spec.ikChainTargets) do
                IKUtil.setIKChainPose(spec.ikChains, chainId, name.poseId)
            end
        end
    end
end
function PushHandTool:getRaycastPosition(node)
    local spec = self.spec_pushHandTool
    local x, y, z = getWorldTranslation(node)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, -1, 0)
    spec.lastRaycastHit = false
    raycastAll(x, y, z, dirX, dirY * 1.5, dirZ, 2, "playerRaycastCallback", self, PushHandTool.PLAYER_COLLISION_MASK)
    if not spec.lastRaycastHit or (spec.lastRaycastPosition[4] <= 0.35 or spec.lastRaycastPosition[2] >= y - 0.25) then
        return nil
    end
    return unpack(spec.lastRaycastPosition)
end
function PushHandTool:playerRaycastCallback(hitObjectId, x, y, z, distance)
    local spec = self.spec_pushHandTool
    local vehicle = g_currentMission.nodeToObject[hitObjectId]
    if vehicle ~= nil and vehicle == self then
        return true
    end
    spec.lastRaycastPosition[1] = x
    spec.lastRaycastPosition[2] = y
    spec.lastRaycastPosition[3] = z
    spec.lastRaycastPosition[4] = distance
    spec.lastRaycastHit = true
    return false
end