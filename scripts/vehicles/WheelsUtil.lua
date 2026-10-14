WheelsUtil = {}
WheelsUtil.GROUND_ROAD = 1
WheelsUtil.GROUND_HARD_TERRAIN = 2
WheelsUtil.GROUND_SOFT_TERRAIN = 3
WheelsUtil.GROUND_FIELD = 4
WheelsUtil.NUM_GROUNDS = 4
WheelsUtil.tireTypes = {}
function WheelsUtil.registerTireType(name, frictionCoeffs, frictionCoeffsWet, frictionCoeffsSnow)
    local getNoNilCoeffs = string.upper(name)
    if WheelsUtil.getTireType(getNoNilCoeffs) == nil then
        local function getNoNilCoeffs(frictionCoeffs)
            local localCoeffs = {}
            if frictionCoeffs[1] == nil then
                localCoeffs[1] = 1.15
                local i = 2
                for i = i, WheelsUtil.NUM_GROUNDS do
                    if frictionCoeffs[i] ~= nil then
                        localCoeffs[1] = frictionCoeffs[i]
                        break
                    end
                end
            else
                localCoeffs[1] = frictionCoeffs[1]
            end
            local i = 2
            for i = i, WheelsUtil.NUM_GROUNDS do
                localCoeffs[i] = frictionCoeffs[i] or frictionCoeffs[i - 1]
            end
            return localCoeffs
        end
        local tireType = {
            ["name"] = getNoNilCoeffs,
            ["frictionCoeffs"] = getNoNilCoeffs(frictionCoeffs),
            ["frictionCoeffsWet"] = getNoNilCoeffs(frictionCoeffsWet or frictionCoeffs)
        }
        tireType.frictionCoeffsSnow = getNoNilCoeffs(frictionCoeffsSnow or tireType.frictionCoeffsWet)
        table.insert(WheelsUtil.tireTypes, tireType)
    else
        printWarning("Warning: Tire type \'" .. getNoNilCoeffs .. "\' already registered, ignoring this definition")
    end
end
function WheelsUtil.unregisterTireType(name)
    name = string.upper(name)
    for i, tireType in ipairs(WheelsUtil.tireTypes) do
        if tireType.name == name then
            table.remove(WheelsUtil.tireTypes, i)
            return
        end
    end
end
function WheelsUtil.getTireType(name)
    name = string.upper(name)
    for i, t in pairs(WheelsUtil.tireTypes) do
        if t.name == name then
            return i
        end
    end
    return nil
end
function WheelsUtil.getTireTypeName(index)
    return WheelsUtil.tireTypes[index] == nil and "unknown" or WheelsUtil.tireTypes[index].name
end
WheelsUtil.registerTireType("mud", {
    [WheelsUtil.GROUND_ROAD] = 1.15,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1.1,
    [WheelsUtil.GROUND_FIELD] = 0.95
}, {
    [WheelsUtil.GROUND_ROAD] = 1.05,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1,
    [WheelsUtil.GROUND_FIELD] = 0.7
}, {
    [WheelsUtil.GROUND_ROAD] = 0.45,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 0.45,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 0.4,
    [WheelsUtil.GROUND_FIELD] = 0.35
})
WheelsUtil.registerTireType("offRoad", {
    [WheelsUtil.GROUND_ROAD] = 1.2,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
    [WheelsUtil.GROUND_FIELD] = 1
}, {
    [WheelsUtil.GROUND_ROAD] = 1.05,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 0.95,
    [WheelsUtil.GROUND_FIELD] = 0.6
}, {
    [WheelsUtil.GROUND_ROAD] = 0.45,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 0.4,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 0.35,
    [WheelsUtil.GROUND_FIELD] = 0.3
})
WheelsUtil.registerTireType("street", {
    [WheelsUtil.GROUND_ROAD] = 1.25,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1,
    [WheelsUtil.GROUND_FIELD] = 0.9
}, {
    [WheelsUtil.GROUND_ROAD] = 1.15,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 0.85,
    [WheelsUtil.GROUND_FIELD] = 0.45
}, {
    [WheelsUtil.GROUND_ROAD] = 0.55,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 0.4,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 0.3,
    [WheelsUtil.GROUND_FIELD] = 0.35
})
WheelsUtil.registerTireType("crawler", {
    [WheelsUtil.GROUND_ROAD] = 1.15,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_FIELD] = 1.15
}, {
    [WheelsUtil.GROUND_ROAD] = 1.05,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
    [WheelsUtil.GROUND_FIELD] = 0.85
}, {
    [WheelsUtil.GROUND_ROAD] = 0.65,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 0.65,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 0.65,
    [WheelsUtil.GROUND_FIELD] = 0.65
})
WheelsUtil.registerTireType("chains", {
    [WheelsUtil.GROUND_ROAD] = 1.15,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_FIELD] = 1.15
}, {
    [WheelsUtil.GROUND_ROAD] = 1.05,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
    [WheelsUtil.GROUND_FIELD] = 0.95
}, {
    [WheelsUtil.GROUND_ROAD] = 1.05,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
    [WheelsUtil.GROUND_FIELD] = 1.05
})
WheelsUtil.registerTireType("metalSpikes", {
    [WheelsUtil.GROUND_ROAD] = 1.15,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_FIELD] = 1.15
}, {
    [WheelsUtil.GROUND_ROAD] = 1.15,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_FIELD] = 1.15
}, {
    [WheelsUtil.GROUND_ROAD] = 1.15,
    [WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
    [WheelsUtil.GROUND_FIELD] = 1.15
})
local SMOOTHING_SPEED_SCALE = 0.002
function WheelsUtil:getSmoothedAcceleratorAndBrakePedals(acceleratorPedal, brakePedal, dt)
    -- upvalues: (copy) SMOOTHING_SPEED_SCALE
    if self.wheelsUtilSmoothedAcceleratorPedal == nil then
        self.wheelsUtilSmoothedAcceleratorPedal = 0
    end
    local appliedAcc = 0
    if acceleratorPedal > 0 then
        if self.wheelsUtilSmoothedAcceleratorPedal < acceleratorPedal then
            local decSpeed = math.max(self.wheelsUtilSmoothedAcceleratorPedal + 0.002 * dt, 0.002)
            appliedAcc = math.min(decSpeed, acceleratorPedal)
        else
            appliedAcc = acceleratorPedal
        end
        self.wheelsUtilSmoothedAcceleratorPedal = appliedAcc
    elseif acceleratorPedal < 0 then
        if acceleratorPedal < self.wheelsUtilSmoothedAcceleratorPedal then
            local decSpeed = math.min(self.wheelsUtilSmoothedAcceleratorPedal - 0.002 * dt, -0.002)
            appliedAcc = math.max(decSpeed, acceleratorPedal)
        else
            appliedAcc = acceleratorPedal
        end
        self.wheelsUtilSmoothedAcceleratorPedal = appliedAcc
    elseif self.wheelsUtilSmoothedAcceleratorPedal > 0 then
        self.wheelsUtilSmoothedAcceleratorPedal = math.max(self.wheelsUtilSmoothedAcceleratorPedal - (0.0005 + 0.001 * brakePedal) * dt, 0)
    else
        self.wheelsUtilSmoothedAcceleratorPedal = math.min(self.wheelsUtilSmoothedAcceleratorPedal + decSpeed * dt, 0)
    end
    if self.wheelsUtilSmoothedBrakePedal == nil then
        self.wheelsUtilSmoothedBrakePedal = 0
    end
    local decSpeed = 0
    if brakePedal > 0 then
        if self.wheelsUtilSmoothedBrakePedal < brakePedal then
            brakePedal = math.min(self.wheelsUtilSmoothedBrakePedal + 0.0025 * dt, brakePedal)
        end
        self.wheelsUtilSmoothedBrakePedal = brakePedal
        return appliedAcc, brakePedal
    end
    local decSpeed = 0.0005 + 0.001 * acceleratorPedal
    self.wheelsUtilSmoothedBrakePedal = math.max(self.wheelsUtilSmoothedBrakePedal - decSpeed * dt, 0)
    return appliedAcc, decSpeed
end
function WheelsUtil:updateWheelsPhysics(dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking)
    local acceleratorPedal = 0
    local brakePedal = 0
    local reverserDirection = 1
    if self.spec_drivable ~= nil then
        reverserDirection = self.spec_drivable.reverserDirection
    end
    local motor = self.spec_motorized.motor
    local isManualTransmission = true
    if motor.backwardGears == nil then
        isManualTransmission = motor.forwardGears ~= nil
    end
    local useManualDirectionChange = self:getIsManualDirectionChangeActive()
    if useManualDirectionChange then
    end
    local absCurrentSpeed = math.abs(currentSpeed)
    local accSign = math.sign(acceleration)
    self.nextMovingDirection = self.nextMovingDirection or 0
    self.nextMovingDirectionTimer = self.nextMovingDirectionTimer or 0
    local automaticBrake = false
    if math.abs(acceleration) < 0.001 then
        automaticBrake = true
        if stopAndGoBraking or currentSpeed * self.nextMovingDirection < 0.0003 then
            self.nextMovingDirection = 0
        end
    else
        if self.nextMovingDirection * currentSpeed < -0.0014 then
            self.nextMovingDirection = 0
        end
        if accSign == self.nextMovingDirection or currentSpeed * accSign > -0.0003 and (stopAndGoBraking or self.nextMovingDirection == 0) then
            self.nextMovingDirectionTimer = math.max(self.nextMovingDirectionTimer - dt, 0)
            if self.nextMovingDirectionTimer == 0 then
                brakePedal = 0
                self.nextMovingDirection = accSign
                acceleratorPedal = acceleration
            else
                acceleratorPedal = 0
                brakePedal = math.abs(acceleration)
            end
        else
            acceleratorPedal = 0
            brakePedal = math.abs(acceleration)
            if stopAndGoBraking then
                self.nextMovingDirectionTimer = 100
            end
        end
    end
    if useManualDirectionChange and (acceleratorPedal ~= 0 and math.sign(acceleratorPedal) ~= motor.currentDirection) then
        brakePedal = math.abs(acceleratorPedal)
    end
    local isSlow, isArticulatedSteering = motor:updateGear(automaticBrake and 0 or acceleratorPedal, brakePedal, dt)
    if motor.gear == 0 and motor.targetGear ~= 0 then
        automaticBrake = currentSpeed * math.sign(motor.targetGear) < 0 and absCurrentSpeed < motor.lowBrakeForceSpeedLimit and true or automaticBrake
    end
    if motor.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and isManualTransmission then
        automaticBrake = false
    end
    if accSign ~= 0 and motor.lowBrakeForceLocked then
        motor.lowBrakeForceLocked = false
    end
    if automaticBrake then
        local isArticulatedSteering = false
        if self.spec_articulatedAxis ~= nil then
            isArticulatedSteering = false
            if self.spec_articulatedAxis.componentJoint ~= nil then
                isArticulatedSteering = math.abs(self.rotatedTime) > 0.01
            end
        end
        if (absCurrentSpeed < motor.lowBrakeForceSpeedLimit or doHandbrake) and not isArticulatedSteering or motor.lowBrakeForceLocked then
            isArticulatedSteering = 1
            if not motor.lowBrakeForceLocked and accSign == 0 then
                motor.lowBrakeForceLocked = true
            end
        else
            local factor = math.min(absCurrentSpeed / 0.001, 1)
            isArticulatedSteering = MathUtil.lerp(1, motor.lowBrakeForceScale, factor)
        end
    end
    SpecializationUtil.raiseEvent(self, "onVehiclePhysicsUpdate", isSlow, isArticulatedSteering, automaticBrake, currentSpeed)
    local isSlow, isArticulatedSteering = WheelsUtil.getSmoothedAcceleratorAndBrakePedals(self, isSlow, isArticulatedSteering, dt)
    local isSlow = motor:getMaximumForwardSpeed() * 3.6
    if self.movingDirection < 0 then
        isSlow = motor:getMaximumBackwardSpeed() * 3.6
    end
    local factor = self:getLastSpeed()
    local maxGearRatio = motor:getSpeedLimit()
    local isArticulatedSteering = factor - math.min(maxGearRatio, isSlow)
    local acceleratorPedal
    if isArticulatedSteering > 0 then
        if isArticulatedSteering > 0.3 then
            motor.overSpeedTimer = math.min(motor.overSpeedTimer + dt, 2000)
        else
            motor.overSpeedTimer = math.max(motor.overSpeedTimer - dt, 0)
        end
        local acceleratorPedalControlsSpeed = math.pow(isArticulatedSteering * (0.5 + motor.overSpeedTimer / 2000 * 1), 2)
        local maxGearRatio = math.min(acceleratorPedalControlsSpeed, 1)
        isArticulatedSteering = math.max(maxGearRatio, isArticulatedSteering)
        acceleratorPedal = 0.2 * math.max(1 - isArticulatedSteering / 0.2, 0) * isSlow
    else
        local minGearRatio = math.abs(isArticulatedSteering) / 0.3 + 0.2
        acceleratorPedal = isSlow * math.min(minGearRatio, 1)
        motor.overSpeedTimer = 0
    end
    if next(self.spec_motorized.differentials) == nil or self.spec_motorized.motorizedNode == nil then
        ::l68::
        self:brake(isArticulatedSteering)
        return
    end
    local factor = math.abs(acceleratorPedal)
    local minGearRatio, maxGearRatio = motor:getMinMaxGearRatio()
    local acceleratorPedalControlsSpeed
    if maxGearRatio >= 0 then
        acceleratorPedalControlsSpeed = motor:getMaximumForwardSpeed()
    else
        acceleratorPedalControlsSpeed = motor:getMaximumBackwardSpeed()
    end
    local minMotorRpm = motor:getSpeedLimit() / 3.6
    local maxAcceleration = math.min(acceleratorPedalControlsSpeed, minMotorRpm)
    local maxAcceleration = motor:getAccelerationLimit()
    local maxMotorRotAcceleration = motor:getMotorRotationAccelerationLimit()
    local minMotorRpm, maxMotorRpm = motor:getRequiredMotorRpmRange()
    local neededPtoTorque, ptoTorqueVirtualMultiplicator = PowerConsumer.getTotalConsumedPtoTorque(self)
    local neededPtoTorque = neededPtoTorque / motor:getPtoMotorRpmRatio()
    local neutralActive
    if minGearRatio == 0 then
        if maxGearRatio == 0 then
            ::l75::
            motor:setExternalTorqueVirtualMultiplicator(ptoTorqueVirtualMultiplicator)
            if true then
                self:controlVehicle(0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
                isArticulatedSteering = math.max(isArticulatedSteering, 0.03)
            else
                self:controlVehicle(factor, maxAcceleration, maxAcceleration, minMotorRpm * 3.141592653589793 / 30, maxMotorRpm * 3.141592653589793 / 30, maxMotorRotAcceleration, minGearRatio, maxGearRatio, motor:getMaxClutchTorque(), neededPtoTorque)
            end
            goto l68
        end
    end
    neutralActive = motor:getManualClutchPedal() > 0.9
    goto l75
end
function WheelsUtil:computeDifferentialRotSpeedNonMotor()
    if not self.isServer or (self.spec_wheels == nil or #self.spec_wheels.wheels == 0) then
        return self.lastSpeedReal * 1000
    end
    local wheelSpeed = 0
    local numWheels = 0
    for _, wheel in pairs(self.spec_wheels.wheels) do
        local axleSpeed = getWheelShapeAxleSpeed(wheel.node, wheel.physics.wheelShape)
        if wheel.physics.hasGroundContact then
        end
    end
    return numWheels <= 0 and 0 or wheelSpeed / numWheels
end
function WheelsUtil.getTireFriction(tireType, groundType, wetScale, snowScale)
    local coeff = WheelsUtil.tireTypes[tireType].frictionCoeffs[groundType]
    return coeff + (WheelsUtil.tireTypes[tireType].frictionCoeffsWet[groundType] - coeff) * (wetScale == nil and 0 or wetScale) + (WheelsUtil.tireTypes[tireType].frictionCoeffsSnow[groundType] - coeff) * snowScale
end
function WheelsUtil.getGroundType(isField, isRoad, depth)
    if isField then
        return WheelsUtil.GROUND_FIELD
    elseif isRoad or depth < 0.1 then
        return WheelsUtil.GROUND_ROAD
    elseif depth > 0.8 then
        return WheelsUtil.GROUND_SOFT_TERRAIN
    else
        return WheelsUtil.GROUND_HARD_TERRAIN
    end
end