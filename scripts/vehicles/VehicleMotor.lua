VehicleMotor = {}
local VehicleMotor_mt = Class(VehicleMotor)
VehicleMotor.DAMAGE_TORQUE_REDUCTION = 0.3
VehicleMotor.DEFAULT_DAMPING_RATE_FULL_THROTTLE = 0.00025
VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_EN = 0.0015
VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_DIS = 0.0015
VehicleMotor.GEAR_START_THRESHOLD = 1.5
VehicleMotor.REASON_CLUTCH_NOT_ENGAGED = 0
VehicleMotor.SHIFT_MODE_AUTOMATIC = 1
VehicleMotor.SHIFT_MODE_MANUAL = 2
VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH = 3
VehicleMotor.DIRECTION_CHANGE_MODE_AUTOMATIC = 1
VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL = 2
VehicleMotor.TRANSMISSION_TYPE = {}
VehicleMotor.TRANSMISSION_TYPE.DEFAULT = 1
VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT = 2
local MODULATION_SPEED = 0.0009
local MODULATION_RPM_MAX_OFFSET = 150
local MODULATION_RPM_MIN_REF_LOAD = 0.1
local MODULATION_RPM_MAX_REF_LOAD = 1
local MODULATION_RPM_MIN_INTENSITY = 0.01
local MODULATION_LOAD_MAX_OFFSET = 0.05
local MODULATION_LOAD_MIN_REF_LOAD = 0
local MODULATION_LOAD_MAX_REF_LOAD = 0.5
local MODULATION_LOAD_MIN_INTENSITY = 0
local MAX_ACCELERATION_LOAD = 0.8
function VehicleMotor.new(vehicle, minRpm, maxRpm, maxForwardSpeed, maxBackwardSpeed, torqueCurve, brakeForce, forwardGears, backwardGears, minForwardGearRatio, maxForwardGearRatio, minBackwardGearRatio, maxBackwardGearRatio, ptoMotorRpmRatio, minSpeed)
    -- upvalues: (copy) VehicleMotor_mt
    local v = VehicleMotor_mt
    local self = setmetatable({}, v)
    self.vehicle = vehicle
    self.minRpm = minRpm
    self.maxRpm = maxRpm
    self.minSpeed = minSpeed
    self.maxForwardSpeed = maxForwardSpeed
    self.maxBackwardSpeed = maxBackwardSpeed
    self.maxClutchTorque = 5
    self.torqueCurve = torqueCurve
    self.brakeForce = brakeForce
    self.lastAcceleratorPedal = 0
    self.idleGearChangeTimer = 0
    self.doSecondBestGearSelection = 0
    self.gear = 0
    self.bestGearSelected = 0
    self.minGearRatio = 0
    self.maxGearRatio = 0
    self.allowGearChangeTimer = 0
    self.allowGearChangeDirection = 0
    self.forwardGears = forwardGears
    self.backwardGears = backwardGears
    self.currentGears = self.forwardGears
    self.minForwardGearRatio = minForwardGearRatio
    self.maxForwardGearRatio = maxForwardGearRatio
    self.minBackwardGearRatio = minBackwardGearRatio
    self.maxBackwardGearRatio = maxBackwardGearRatio
    self.transmissionDirection = 1
    self.maxClutchSpeedDifference = 0
    self.defaultForwardGear = 1
    if self.forwardGears ~= nil then
        local i = 1
        for i = i, #self.forwardGears do
            self.maxClutchSpeedDifference = math.max(self.maxClutchSpeedDifference, self.minRpm / self.forwardGears[i].ratio * 3.141592653589793 / 30)
            if self.forwardGears[i].default then
                self.defaultForwardGear = i
            end
        end
    end
    self.defaultBackwardGear = 1
    if self.backwardGears ~= nil then
        local i = 1
        for i = i, #self.backwardGears do
            self.maxClutchSpeedDifference = math.max(self.maxClutchSpeedDifference, self.minRpm / self.backwardGears[i].ratio * 3.141592653589793 / 30)
            if self.backwardGears[i].default then
                self.defaultBackwardGear = i
            end
        end
    end
    self.gearType = VehicleMotor.TRANSMISSION_TYPE.DEFAULT
    self.groupType = VehicleMotor.TRANSMISSION_TYPE.DEFAULT
    self.manualTargetGear = nil
    self.targetGear = 0
    self.previousGear = 0
    self.gearChangeTimer = -1
    self.gearChangeTime = 250
    self.gearChangeTimeOrig = self.gearChangeTime
    self.autoGearChangeTimer = -1
    self.autoGearChangeTime = 1000
    self.manualClutchValue = 0
    self.stallTimer = 0
    self.lastGearChangeTime = 0
    self.gearChangeTimeAutoReductionTime = 500
    self.gearChangeTimeAutoReductionTimer = 0
    self.lastManualShifterActive = false
    self.clutchSlippingTime = 1000
    self.clutchSlippingTimer = 0
    self.clutchSlippingGearRatio = 0
    self.groupChangeTime = 500
    self.groupChangeTimer = 0
    self.gearGroupUpShiftTime = 3000
    self.gearGroupUpShiftTimer = 0
    self.currentDirection = 1
    self.directionChangeTimer = 0
    self.directionChangeTime = 500
    self.directionChangeUseGear = false
    self.directionChangeGearIndex = 1
    self.directionLastGear = -1
    self.directionChangeUseGroup = false
    self.directionChangeGroupIndex = 1
    self.directionLastGroup = -1
    self.directionChangeUseInverse = true
    self.gearChangedIsLocked = false
    self.gearGroupChangedIsLocked = false
    self.startGearValues = {
        ["slope"] = 0,
        ["mass"] = 0,
        ["lastMass"] = 0,
        ["maxForce"] = 0,
        ["massDirectionDifferenceXZ"] = 0,
        ["massDirectionDifferenceY"] = 0,
        ["massDirectionFactor"] = 0,
        ["availablePower"] = 0,
        ["massFactor"] = 0
    }
    self.startGearThreshold = VehicleMotor.GEAR_START_THRESHOLD
    self.lastSmoothedClutchPedal = 0
    self.lastRealMotorRpm = 0
    self.lastMotorRpm = 0
    self.lastModulationPercentage = 0
    self.lastModulationTimer = 0
    self.rawLoadPercentage = 0
    self.rawLoadPercentageBuffer = 0
    self.rawLoadPercentageBufferIndex = 0
    self.smoothedLoadPercentage = 0
    self.loadPercentageChangeCharge = 0
    self.accelerationLimitLoadScale = 1
    self.accelerationLimitLoadScaleTimer = 0
    self.accelerationLimitLoadScaleDelay = 2000
    self.constantRpmCharge = 0
    self.constantAccelerationCharge = 0
    self.lastTurboScale = 0
    self.blowOffValveState = 0
    self.overSpeedTimer = 0
    self.rpmLimit = math.huge
    self.speedLimit = math.huge
    self.speedLimitAcc = math.huge
    self.accelerationLimit = 2
    self.motorRotationAccelerationLimit = (maxRpm - minRpm) * 3.141592653589793 / 30 / 2
    self.equalizedMotorRpm = 0
    self.requiredMotorPower = 0
    if self.maxForwardSpeed == nil then
        self.maxForwardSpeed = self:calculatePhysicalMaximumForwardSpeed()
    end
    if self.maxBackwardSpeed == nil then
        self.maxBackwardSpeed = self:calculatePhysicalMaximumBackwardSpeed()
    end
    self.maxForwardSpeedOrigin = self.maxForwardSpeed
    self.maxBackwardSpeedOrigin = self.maxBackwardSpeed
    self.minForwardGearRatioOrigin = self.minForwardGearRatio
    self.maxForwardGearRatioOrigin = self.maxForwardGearRatio
    self.minBackwardGearRatioOrigin = self.minBackwardGearRatio
    self.maxBackwardGearRatioOrigin = self.maxBackwardGearRatio
    self.peakMotorTorque = self.torqueCurve:getMaximum()
    self.peakMotorPower = 0
    self.peakMotorPowerRotSpeed = 0
    local numKeyFrames = #self.torqueCurve.keyframes
    if numKeyFrames >= 2 then
        local i = 2
        local i = 1
        for i = i, numKeyFrames, i do
            local v0 = self.torqueCurve.keyframes[i - 1]
            local v1 = self.torqueCurve.keyframes[i]
            local torque0 = self.torqueCurve:getFromKeyframes(v0, v0, i - 1, i - 1, 0)
            local torque1 = self.torqueCurve:getFromKeyframes(v1, v1, i, i, 0)
            local power
            if math.abs(torque0 - torque1) > 0.0001 then
                power = math.min(math.max((v1.time * torque0 - v0.time * torque1) / (2 * (torque0 - torque1)), v0.time), v1.time)
                torque0 = self.torqueCurve:getFromKeyframes(v0, v1, i - 1, i, (v1.time - power) / (v1.time - v0.time))
            else
                power = v0.time
            end
            local power = torque0 * power
            if self.peakMotorPower < power then
                self.peakMotorPower = power
                self.peakMotorPowerRotSpeed = power
            end
        end
        self.peakMotorPower = self.peakMotorPower * 3.141592653589793 / 30
        self.peakMotorPowerRotSpeed = self.peakMotorPowerRotSpeed * 3.141592653589793 / 30
    else
        local v = self.torqueCurve.keyframes[1]
        local i = v.time * 3.141592653589793 / 30
        self.peakMotorPower = i * self.torqueCurve:getFromKeyframes(v, v, 1, 1, 0)
        self.peakMotorPowerRotSpeed = i
    end
    self.ptoMotorRpmRatio = ptoMotorRpmRatio
    self.rotInertia = self.peakMotorTorque / 600
    self.dampingRateFullThrottle = VehicleMotor.DEFAULT_DAMPING_RATE_FULL_THROTTLE
    self.dampingRateZeroThrottleClutchEngaged = VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_EN
    self.dampingRateZeroThrottleClutchDisengaged = VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_DIS
    self.gearRatio = 0
    self.motorRotSpeed = 0
    self.motorRotSpeedClutchEngaged = 0
    self.motorRotAcceleration = 0
    self.motorRotAccelerationSmoothed = 0
    self.motorAvailableTorque = 0
    self.lastMotorAvailableTorque = 0
    self.motorAppliedTorque = 0
    self.lastMotorAppliedTorque = 0
    self.motorExternalTorque = 0
    self.lastMotorExternalTorque = 0
    self.externalTorqueVirtualMultiplicator = 1
    self.differentialRotSpeed = 0
    self.differentialRotAcceleration = 0
    self.differentialRotAccelerationSmoothed = 0
    self.differentialRotAccelerationIndex = 1
    self.differentialRotAccelerationSamples = {}
    local i = self.differentialRotAccelerationSamples
    table.insert(i, 0)
    local i = self.differentialRotAccelerationSamples
    table.insert(i, 0)
    local i = self.differentialRotAccelerationSamples
    table.insert(i, 0)
    local i = self.differentialRotAccelerationSamples
    table.insert(i, 0)
    local i = self.differentialRotAccelerationSamples
    table.insert(i, 0)
    local i = self.differentialRotAccelerationSamples
    table.insert(i, 0)
    local i = self.differentialRotAccelerationSamples
    table.insert(i, 0)
    local i = self.differentialRotAccelerationSamples
    table.insert(i, 0)
    local i = self.differentialRotAccelerationSamples
    table.insert(i, 0)
    local i = self.differentialRotAccelerationSamples
    table.insert(i, 0)
    self.lastDifference = 0
    self.directionChangeMode = g_gameSettings:getValue(GameSettings.SETTING.DIRECTION_CHANGE_MODE)
    self.gearShiftMode = g_gameSettings:getValue(GameSettings.SETTING.GEAR_SHIFT_MODE)
    return self
end
function VehicleMotor:postLoad(_)
    if self.gearGroups ~= nil then
        SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, 0)
    end
end
function VehicleMotor:delete()
    g_messageCenter:unsubscribeAll(self)
end
function VehicleMotor:setGearGroups(gearGroups, groupType, groupChangeTime)
    self.gearGroups = gearGroups
    self.groupType = VehicleMotor.TRANSMISSION_TYPE[string.upper(groupType)] or VehicleMotor.TRANSMISSION_TYPE.DEFAULT
    self.groupChangeTime = groupChangeTime
    if gearGroups ~= nil then
        self.numGearGroups = #gearGroups
        self.defaultGearGroup = 1
        local i = 1
        for i = i, self.numGearGroups do
            if self.gearGroups[i].ratio > 0 then
                self.defaultGearGroup = i
                break
            end
        end
        local i = 1
        for i = i, self.numGearGroups do
            if self.gearGroups[i].isDefault then
                self.defaultGearGroup = i
                break
            end
        end
        self.activeGearGroupIndex = self.defaultGearGroup
    end
end
function VehicleMotor:setDirectionChange(directionChangeUseGear, directionChangeGearIndex, directionChangeUseGroup, directionChangeGroupIndex, directionChangeTime)
    self.directionChangeUseGear = directionChangeUseGear
    self.directionChangeGearIndex = directionChangeGearIndex
    self.directionChangeUseGroup = directionChangeUseGroup
    self.directionChangeGroupIndex = directionChangeGroupIndex
    self.directionChangeTime = directionChangeTime
    self.directionChangeUseInverse = not directionChangeUseGear and not directionChangeUseGroup
end
function VehicleMotor:setManualShift(manualShiftGears, manualShiftGroups)
    self.manualShiftGears = manualShiftGears
    self.manualShiftGroups = manualShiftGroups
end
function VehicleMotor:setStartGearThreshold(startGearThreshold)
    self.startGearThreshold = startGearThreshold
end
function VehicleMotor:setLowBrakeForce(lowBrakeForceScale, lowBrakeForceSpeedLimit)
    self.lowBrakeForceScale = lowBrakeForceScale
    self.lowBrakeForceSpeedLimit = lowBrakeForceSpeedLimit
end
function VehicleMotor:getMaxClutchTorque()
    return self.maxClutchTorque
end
function VehicleMotor:getRotInertia()
    return self.rotInertia
end
function VehicleMotor:setRotInertia(rotInertia)
    self.rotInertia = rotInertia
end
function VehicleMotor:getDampingRateFullThrottle()
    return self.dampingRateFullThrottle
end
function VehicleMotor:getDampingRateZeroThrottleClutchEngaged()
    return self.dampingRateZeroThrottleClutchEngaged
end
function VehicleMotor:getDampingRateZeroThrottleClutchDisengaged()
    return self.dampingRateZeroThrottleClutchDisengaged
end
function VehicleMotor:setDampingRateScale(dampingRateScale)
    self.dampingRateFullThrottle = VehicleMotor.DEFAULT_DAMPING_RATE_FULL_THROTTLE * dampingRateScale
    self.dampingRateZeroThrottleClutchEngaged = VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_EN * dampingRateScale
    self.dampingRateZeroThrottleClutchDisengaged = VehicleMotor.DEFAULT_DAMPING_RATE_ZERO_THROTTLE_CLUTCH_DIS * dampingRateScale
end
function VehicleMotor:setGearChangeTime(gearChangeTime)
    self.gearChangeTime = gearChangeTime
    self.gearChangeTimeOrig = gearChangeTime
    self.gearChangeTimer = math.min(self.gearChangeTimer, gearChangeTime)
    self.gearType = gearChangeTime == 0 and VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT or VehicleMotor.TRANSMISSION_TYPE.DEFAULT
end
function VehicleMotor:setAutoGearChangeTime(autoGearChangeTime)
    self.autoGearChangeTime = autoGearChangeTime
    self.autoGearChangeTimer = math.min(self.autoGearChangeTimer, autoGearChangeTime)
end
function VehicleMotor:getPeakTorque()
    return self.peakMotorTorque
end
function VehicleMotor:getBrakeForce()
    return self.brakeForce
end
function VehicleMotor:getMinRpm()
    return self.minRpm
end
function VehicleMotor:getMaxRpm()
    return self.maxRpm
end
function VehicleMotor:getRequiredMotorRpmRange()
    local motorPtoRpm = math.min(PowerConsumer.getMaxPtoRpm(self.vehicle) * self.ptoMotorRpmRatio, self.maxRpm)
    if motorPtoRpm == 0 then
        return self.minRpm, self.maxRpm
    else
        return motorPtoRpm, self.maxRpm
    end
end
function VehicleMotor:getLastMotorRpm()
    return self.lastMotorRpm
end
function VehicleMotor:getLastModulatedMotorRpm()
    -- upvalues: (copy) MODULATION_RPM_MIN_REF_LOAD, (copy) MODULATION_RPM_MAX_REF_LOAD, (copy) MODULATION_RPM_MIN_INTENSITY, (copy) MODULATION_RPM_MAX_OFFSET
    local modulationIntensity = math.clamp((self.smoothedLoadPercentage - 0.1) / 0.9, 0.01, 1)
    local loadChangeChargeDrop = 0
    if self:getClutchPedal() < 0.1 and self.minGearRatio > 0 then
        local rpmRange = self.maxRpm - self.minRpm
        loadChangeChargeDrop = self.loadPercentageChangeCharge * rpmRange * ((self.lastMotorRpm - self.minRpm) / rpmRange * 0.5)
    else
        self.loadPercentageChangeCharge = 0
    end
    return self.lastMotorRpm == 0 and 0 or self.lastMotorRpm + self.lastModulationPercentage * (150 * modulationIntensity) * self.constantRpmCharge - loadChangeChargeDrop
end
function VehicleMotor:getLastRealMotorRpm()
    return self.lastRealMotorRpm
end
function VehicleMotor:getSmoothLoadPercentage()
    -- upvalues: (copy) MODULATION_LOAD_MIN_REF_LOAD, (copy) MODULATION_LOAD_MAX_REF_LOAD, (copy) MODULATION_LOAD_MIN_INTENSITY, (copy) MODULATION_LOAD_MAX_OFFSET
    local modulationIntensity = math.clamp((self.smoothedLoadPercentage - 0) / 0.5, 0, 1)
    return self.smoothedLoadPercentage - self.lastModulationPercentage * (0.05 * modulationIntensity)
end
function VehicleMotor:getClutchPedal()
    if not self.vehicle.isServer or self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
        return self.manualClutchValue
    end
    local clutchRpm = self:getNonClampedMotorRpm()
    if clutchRpm == 0 then
        return 0
    end
    return 1 - math.max(math.min((self:getClutchRotSpeed() * 30 / 3.141592653589793 + 50) / clutchRpm, 1), 0)
end
function VehicleMotor:getSmoothedClutchPedal()
    return self.lastSmoothedClutchPedal
end
function VehicleMotor:getManualClutchPedal()
    return self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and 0 or self.manualClutchValue
end
function VehicleMotor:getGearToDisplay(isDashboard)
    local gearName = "N"
    if self.backwardGears or self.forwardGears then
        if self.targetGear > 0 then
            local gear = self.currentGears[self.targetGear]
            if gear ~= nil then
                if isDashboard then
                    return (self.currentGears == self.forwardGears and self.currentDirection or 1) == 1 and (gear.dashboardName or gear.name) or (gear.dashboardReverseName or gear.reverseName)
                else
                    return gearNameDirection == 1 and gear.name or gear.reverseName
                end
            end
        end
    else
        local gear = self:getDrivingDirection()
        if gear > 0 then
            return "D"
        end
    end
    return gearName
end
function VehicleMotor:getGearInfoToDisplay()
    local gearName = "N"
    local available = false
    local prevGearName = nil
    local nextGearName = nil
    local prevPrevGearName = nil
    local nextNextGearName = nil
    local isAutomatic = false
    local isGearChanging = false
    if self.backwardGears or self.forwardGears then
        if self.targetGear > 0 then
            local gear = self.currentGears[self.targetGear]
            if gear ~= nil then
                local displayDirection = self.currentDirection
                local gearNameDirection = self.currentGears == self.forwardGears and self.currentDirection or 1
                gearName = gearNameDirection == 1 and gear.name or gear.reverseName
                local prevGear = self.currentGears[self.targetGear + 1 * -displayDirection]
                if prevGear ~= nil then
                    prevGearName = gearNameDirection == 1 and prevGear.name or prevGear.reverseName
                    local prevGear = self.currentGears[self.targetGear + 2 * -displayDirection]
                    if prevGear ~= nil then
                        prevPrevGearName = gearNameDirection == 1 and prevGear.name or prevGear.reverseName
                    end
                end
                local nextGear = self.currentGears[self.targetGear + 1 * displayDirection]
                if nextGear ~= nil then
                    nextGearName = gearNameDirection == 1 and nextGear.name or nextGear.reverseName
                    local nextGear = self.currentGears[self.targetGear + 2 * displayDirection]
                    if nextGear ~= nil then
                        nextNextGearName = gearNameDirection == 1 and nextGear.name or nextGear.reverseName
                    end
                end
                if self.gear ~= self.targetGear then
                    isGearChanging = true
                end
            end
        end
        available = true
    else
        local gear = self:getDrivingDirection()
        if gear > 0 then
            gearName = "D"
            prevGearName = "N"
        elseif gear < 0 then
            gearName = "R"
            nextGearName = "N"
        else
            nextGearName = "D"
            prevGearName = "R"
        end
        isAutomatic = true
    end
    return gearName, available, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging
end
function VehicleMotor:getDrivingDirection()
    if self.directionChangeMode == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL or (self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_AUTOMATIC or (self.backwardGears or self.forwardGears)) then
        return self.currentDirection * self.transmissionDirection
    else
        return self.vehicle:getLastSpeed() <= 0.95 and 0 or self.vehicle.movingDirection * self.transmissionDirection
    end
end
function VehicleMotor:getGearGroupToDisplay(isDashboard)
    local gearGroupName = "N"
    local available = false
    if (self.backwardGears or self.forwardGears) and self.gearGroups ~= nil then
        if self.activeGearGroupIndex > 0 then
            local gearGroup = self.gearGroups[self.activeGearGroupIndex]
            if gearGroup ~= nil then
                if isDashboard then
                    gearGroupName = gearGroup.dashboardName or gearGroup.name
                else
                    gearGroupName = gearGroup.name
                end
            end
        end
        available = true
    end
    return gearGroupName, available
end
function VehicleMotor:readGearDataFromStream(streamId)
    self.currentDirection = streamReadUIntN(streamId, 2) - 1
    if streamReadBool(streamId) then
        local gear = streamReadUIntN(streamId, 6)
        local changingGear = streamReadBool(streamId)
        if streamReadBool(streamId) then
            self.currentGears = self.forwardGears
        else
            self.currentGears = self.backwardGears
        end
        local activeGearGroupIndex = nil
        if self.gearGroups ~= nil then
            activeGearGroupIndex = streamReadUIntN(streamId, 5)
        end
        if gear ~= self.gear then
            if changingGear and self.gear ~= 0 then
                self.lastGearChangeTime = g_time
            end
            self.previousGear = self.gear
            self.gear = changingGear and 0 or gear
            self.targetGear = gear
            local directionMultiplier = self.directionChangeUseGear and self.currentDirection or 1
            SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * directionMultiplier, self.targetGear * directionMultiplier, 0, self.previousGear)
        end
        if activeGearGroupIndex ~= self.activeGearGroupIndex then
            self.activeGearGroupIndex = activeGearGroupIndex
            SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, self.groupType == VehicleMotor.TRANSMISSION_TYPE.DEFAULT and self.groupChangeTime or 0)
        end
    end
end
function VehicleMotor:writeGearDataToStream(streamId)
    streamWriteUIntN(streamId, math.sign(self.currentDirection) + 1, 2)
    if streamWriteBool(streamId, self.backwardGears ~= nil or self.forwardGears ~= nil) then
        streamWriteUIntN(streamId, self.targetGear, 6)
        streamWriteBool(streamId, self.targetGear ~= self.gear)
        streamWriteBool(streamId, self.currentGears == self.forwardGears)
        if self.gearGroups ~= nil then
            streamWriteUIntN(streamId, self.activeGearGroupIndex, 5)
        end
    end
end
function VehicleMotor:setLastRpm(lastRpm)
    self.lastRealMotorRpm = lastRpm
    local interpolationSpeed = self.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT and g_time - self.lastGearChangeTime < 200 and 0.2 or 0.05
    self.lastMotorRpm = self.lastMotorRpm * (1 - interpolationSpeed) + self.lastRealMotorRpm * interpolationSpeed
    local targetTurboRpm = (self.lastMotorRpm - math.max(self.lastPtoRpm or self.minRpm, self.minRpm)) / (self.maxRpm - self.minRpm) * self:getSmoothLoadPercentage()
    self.lastTurboScale = self.lastTurboScale * 0.95 + targetTurboRpm * 0.05
    if self.lastAcceleratorPedal == 0 or self.minGearRatio == 0 and self.autoGearChangeTime > 0 then
        self.blowOffValveState = self.lastTurboScale
    else
        self.blowOffValveState = 0
    end
    if self.blowOffValveState > 0 ~= (self.blowOffValveState > 0) then
        SpecializationUtil.raiseEvent(self.vehicle, "onMotorBlowOffValveChanged", self.blowOffValveState)
    end
    self.constantRpmCharge = 1 - math.min(math.abs(self.lastMotorRpm - self.lastMotorRpm) * 0.15, 1)
end
function VehicleMotor:getMotorAppliedTorque()
    return self.motorAppliedTorque
end
function VehicleMotor:getMotorExternalTorque()
    return self.motorExternalTorque
end
function VehicleMotor:getMotorAvailableTorque()
    return self.motorAvailableTorque
end
function VehicleMotor:getEqualizedMotorRpm()
    return self.equalizedMotorRpm
end
function VehicleMotor:setEqualizedMotorRpm(rpm)
    self.equalizedMotorRpm = rpm
    self:setLastRpm(rpm)
end
function VehicleMotor:getPtoMotorRpmRatio()
    return self.ptoMotorRpmRatio
end
function VehicleMotor:setExternalTorqueVirtualMultiplicator(externalTorqueVirtualMultiplicator)
    self.externalTorqueVirtualMultiplicator = externalTorqueVirtualMultiplicator or 1
end
function VehicleMotor:getNonClampedMotorRpm()
    return self.motorRotSpeed * 30 / 3.141592653589793
end
function VehicleMotor:getMotorRotSpeed()
    return self.motorRotSpeed
end
function VehicleMotor:getClutchRpm()
    return self.differentialRotSpeed * self.gearRatio * 30 / 3.141592653589793
end
function VehicleMotor:getClutchRotSpeed()
    return self.differentialRotSpeed * self.gearRatio
end
function VehicleMotor:getTorqueCurve()
    return self.torqueCurve
end
function VehicleMotor:getTorque(acceleration)
    return self:getTorqueCurveValue((math.clamp(self.motorRotSpeed * 30 / 3.141592653589793, self.minRpm, self.maxRpm))) * math.abs(acceleration)
end
function VehicleMotor:getTorqueCurveValue(rpm)
    local damage = 1 - self.vehicle:getVehicleDamage() * VehicleMotor.DAMAGE_TORQUE_REDUCTION
    return self:getTorqueCurve():get(rpm) * damage
end
function VehicleMotor:getTorqueAndSpeedValues()
    local rotationSpeeds = {}
    local torques = {}
    for _, v in ipairs(self:getTorqueCurve().keyframes) do
        table.insert(rotationSpeeds, v.time * 3.141592653589793 / 30)
        table.insert(torques, self:getTorqueCurveValue(v.time))
    end
    return torques, rotationSpeeds
end
function VehicleMotor:getMaximumForwardSpeed()
    return self.maxForwardSpeed
end
function VehicleMotor:getMaximumBackwardSpeed()
    return self.maxBackwardSpeed
end
function VehicleMotor:calculatePhysicalMaximumForwardSpeed()
    return VehicleMotor.calculatePhysicalMaximumSpeed(self.minForwardGearRatio, self.forwardGears, self.maxRpm)
end
function VehicleMotor:calculatePhysicalMaximumBackwardSpeed()
    return VehicleMotor.calculatePhysicalMaximumSpeed(self.minBackwardGearRatio, self.backwardGears or self.forwardGears, self.maxRpm)
end
function VehicleMotor.calculatePhysicalMaximumSpeed(minGearRatio, gears, maxRpm)
    if minGearRatio == nil then
        if gears == nil then
            printCallstack()
            return 0
        end
        minGearRatio = math.huge
        for _, gear in pairs(gears) do
            minGearRatio = math.min(minGearRatio, gear.ratio)
        end
    end
    return maxRpm * 3.141592653589793 / (30 * minGearRatio)
end
function VehicleMotor:update(dt)
    -- upvalues: (copy) MAX_ACCELERATION_LOAD, (copy) MODULATION_SPEED
    local vehicle = self.vehicle
    if next(vehicle.spec_motorized.differentials) == nil or vehicle.spec_motorized.motorizedNode == nil then
        local lastMotorRotSpeed, lastDiffRotSpeed = self:getMinMaxGearRatio()
        self.differentialRotSpeed = WheelsUtil.computeDifferentialRotSpeedNonMotor(vehicle)
        local clutchValue = math.abs(self.differentialRotSpeed * lastDiffRotSpeed)
        self.motorRotSpeed = math.max(clutchValue, 0)
        self.gearRatio = lastDiffRotSpeed
    else
        local minDifferentialSpeed, clutchValue, direction = getMotorRotationSpeed(vehicle.spec_motorized.motorizedNode)
        self.motorRotSpeed = minDifferentialSpeed
        self.differentialRotSpeed = clutchValue
        self.gearRatio = direction
        if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and (self.backwardGears or self.forwardGears) and (self.gearRatio ~= 0 and (self.maxGearRatio ~= 0 and self.lastAcceleratorPedal ~= 0)) then
            local minDifferentialSpeed = self.minRpm / math.abs(self.maxGearRatio) * 3.141592653589793 / 30
            local direction = self.differentialRotSpeed
            if math.abs(direction) < minDifferentialSpeed * 0.75 then
                self.clutchSlippingTimer = self.clutchSlippingTime
                self.clutchSlippingGearRatio = self.gearRatio
            else
                self.clutchSlippingTimer = math.max(self.clutchSlippingTimer - dt, 0)
            end
        end
        if not self:getUseAutomaticGearShifting() then
            local minDifferentialSpeed = self.lastAcceleratorPedal * self.currentDirection
            local direction = ((self.minGearRatio == 0 and self.maxGearRatio == 0 or self.manualClutchValue > 0.1) and 1 or 0) * minDifferentialSpeed
            local direction = direction == 0 and -1 or direction
            local minRotSpeed = self.minRpm * 3.141592653589793 / 30
            self.motorRotSpeedClutchEngaged = math.min(math.max(self.motorRotSpeedClutchEngaged + direction * (direction > 0 and self.motorRotationAccelerationLimit * 0.02 or self.dampingRateZeroThrottleClutchEngaged * 30 * 3.141592653589793) * dt, minRotSpeed), minRotSpeed + (self.maxRpm * 3.141592653589793 / 30 - minRotSpeed) * minDifferentialSpeed)
            self.motorRotSpeed = math.max(self.motorRotSpeed, self.motorRotSpeedClutchEngaged)
        end
        if g_physicsDtNonInterpolated > 0 and not getIsSleeping(vehicle.rootNode) then
            local minDifferentialSpeed, clutchValue, direction = getMotorTorque(vehicle.spec_motorized.motorizedNode)
            self.lastMotorAvailableTorque = minDifferentialSpeed
            self.lastMotorAppliedTorque = clutchValue
            self.lastMotorExternalTorque = direction
        end
        local minDifferentialSpeed = self.lastMotorAvailableTorque
        local clutchValue = self.lastMotorAppliedTorque
        local direction = self.lastMotorExternalTorque
        self.motorAvailableTorque = minDifferentialSpeed
        self.motorAppliedTorque = clutchValue
        self.motorExternalTorque = direction
        self.motorAppliedTorque = self.motorAppliedTorque - self.motorExternalTorque
        local clutchValue = self.motorExternalTorque * self.externalTorqueVirtualMultiplicator
        local direction = self.motorAvailableTorque - self.motorAppliedTorque
        self.motorExternalTorque = math.min(clutchValue, direction)
        self.motorAppliedTorque = self.motorAppliedTorque + self.motorExternalTorque
        local minDifferentialSpeed = 0
        local clutchValue = 0
        if g_physicsDtNonInterpolated > 0 then
            minDifferentialSpeed = (self.motorRotSpeed - self.motorRotSpeed) / (g_physicsDtNonInterpolated * 0.001)
            clutchValue = (self.differentialRotSpeed - self.differentialRotSpeed) / (g_physicsDtNonInterpolated * 0.001)
        end
        self.motorRotAcceleration = minDifferentialSpeed
        self.motorRotAccelerationSmoothed = 0.8 * self.motorRotAccelerationSmoothed + 0.2 * minDifferentialSpeed
        self.differentialRotAcceleration = clutchValue
        self.differentialRotAccelerationSmoothed = 0.8 * self.differentialRotAccelerationSmoothed + 0.2 * clutchValue
        self.requiredMotorPower = math.huge
    end
    if self.lastPtoRpm == nil then
        self.lastPtoRpm = self.minRpm
    end
    local lastMotorRotSpeed = PowerConsumer.getMaxPtoRpm(self.vehicle) * self.ptoMotorRpmRatio
    if self.lastPtoRpm < lastMotorRotSpeed then
        self.lastPtoRpm = math.min(lastMotorRotSpeed, self.lastPtoRpm + self.maxRpm * dt / 2000)
    elseif lastMotorRotSpeed < self.lastPtoRpm then
        self.lastPtoRpm = math.max(self.minRpm, self.lastPtoRpm - self.maxRpm * dt / 1000)
    end
    if self.vehicle.isServer then
        local accelerationSpeed = self.maxRpm
        local clutchValue = math.min(self.lastPtoRpm, accelerationSpeed)
        local lastDiffRotSpeed = math.max(self.motorRotSpeed * 30 / 3.141592653589793, clutchValue, self.minRpm)
        self:setLastRpm(lastDiffRotSpeed)
        self.equalizedMotorRpm = lastDiffRotSpeed
        local clutchValue = self:getMotorAppliedTorque()
        local accelerationSpeed = self:getMotorAvailableTorque()
        self.rawLoadPercentageBuffer = self.rawLoadPercentageBuffer + clutchValue / math.max(accelerationSpeed, 0.0001)
        self.rawLoadPercentageBufferIndex = self.rawLoadPercentageBufferIndex + 1
        if self.rawLoadPercentageBufferIndex >= 2 then
            self.rawLoadPercentage = self.rawLoadPercentageBuffer / 2
            self.rawLoadPercentageBuffer = 0
            self.rawLoadPercentageBufferIndex = 0
        end
        if self.rawLoadPercentage < 0.01 and self.lastAcceleratorPedal < 0.2 and (not (self.backwardGears or self.forwardGears) or (self.gear ~= 0 or self.targetGear == 0)) then
            self.rawLoadPercentage = -1
        else
            self.rawLoadPercentage = (self.rawLoadPercentage - 0.05) / 0.95
        end
        local clutchValue = math.min(self.vehicle.lastSpeedAcceleration * 1000 * 1000 * self.vehicle.movingDirection / self.accelerationLimit, 1)
        if clutchValue < 0.95 and self.lastAcceleratorPedal > 0.2 then
            self.accelerationLimitLoadScale = 1
            self.accelerationLimitLoadScaleTimer = self.accelerationLimitLoadScaleDelay
        elseif self.accelerationLimitLoadScaleTimer > 0 then
            self.accelerationLimitLoadScaleTimer = self.accelerationLimitLoadScaleTimer - dt
            local maxRotSpeed = (1 - math.max(self.accelerationLimitLoadScaleTimer / self.accelerationLimitLoadScaleDelay, 0)) * 3.14
            self.accelerationLimitLoadScale = math.sin(maxRotSpeed) * 0.85
        end
        if clutchValue > 0 then
            self.rawLoadPercentage = math.max(self.rawLoadPercentage, clutchValue * self.accelerationLimitLoadScale)
        end
        local minRotSpeed = math.abs(self.vehicle.lastSpeedAcceleration) * 1000 * 1000 / self.accelerationLimit
        self.constantAccelerationCharge = 1 - math.min(minRotSpeed, 1)
        if self.rawLoadPercentage > 0 then
            self.rawLoadPercentage = self.rawLoadPercentage * 0.8 + self.rawLoadPercentage * 0.19999999999999996 * self.constantAccelerationCharge
        end
        if (self.backwardGears or self.forwardGears) and self:getUseAutomaticGearShifting() then
            if self.constantRpmCharge > 0.99 then
                if self.maxRpm - lastDiffRotSpeed < 50 then
                    self.gearChangeTimeAutoReductionTimer = math.min(self.gearChangeTimeAutoReductionTimer + dt, self.gearChangeTimeAutoReductionTime)
                    self.gearChangeTime = self.gearChangeTimeOrig * (1 - self.gearChangeTimeAutoReductionTimer / self.gearChangeTimeAutoReductionTime)
                else
                    self.gearChangeTimeAutoReductionTimer = 0
                    self.gearChangeTime = self.gearChangeTimeOrig
                end
            else
                self.gearChangeTimeAutoReductionTimer = 0
                self.gearChangeTime = self.gearChangeTimeOrig
            end
        end
    end
    self:updateSmoothLoadPercentage(dt, self.rawLoadPercentage)
    local minDifferentialSpeed = self.idleGearChangeTimer - dt
    self.idleGearChangeTimer = math.max(minDifferentialSpeed, 0)
    if self.forwardGears or self.backwardGears then
        self:updateStartGearValues(dt)
        local lastDiffRotSpeed = self:getClutchPedal()
        self.lastSmoothedClutchPedal = self.lastSmoothedClutchPedal * 0.9 + lastDiffRotSpeed * 0.1
    end
    self.lastModulationTimer = self.lastModulationTimer + dt * 0.0009
    local accelerationSpeed = self.lastModulationTimer
    local direction = math.sin(accelerationSpeed)
    local minRotSpeed = (self.lastModulationTimer + 2) * 0.3
    local minDifferentialSpeed = direction * math.sin(minRotSpeed) * 0.8
    local accelerationSpeed = self.lastModulationTimer * 5
    self.lastModulationPercentage = minDifferentialSpeed + math.cos(accelerationSpeed) * 0.2
end
function VehicleMotor:updateSmoothLoadPercentage(dt, rawLoadPercentage)
    local maxSpeed = self:getMaximumForwardSpeed() * 3.6
    if self.vehicle.movingDirection < 0 then
        maxSpeed = self:getMaximumBackwardSpeed() * 3.6
    end
    local invFactor = self.vehicle:getLastSpeed() / maxSpeed
    local factor = math.min(invFactor, 1)
    local factor = 0.05 + (1 - math.max(factor, 0)) * 0.3
    if rawLoadPercentage < self.smoothedLoadPercentage then
        if self.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT and g_time - self.lastGearChangeTime <= 200 then
        else
            factor = factor * 0.2
            if self:getClutchPedal() > 0.75 then
            end
            if rawLoadPercentage < 0 then
            end
        end
    end
    self.smoothedLoadPercentage = (1 - factor) * self.smoothedLoadPercentage + factor * rawLoadPercentage
    local difference = math.max(self.smoothedLoadPercentage - self.smoothedLoadPercentage, 0)
    self.loadPercentageChangeCharge = self.loadPercentageChangeCharge + difference
    self.loadPercentageChangeCharge = math.min(math.max(self.loadPercentageChangeCharge - dt * 0.0005, 0), 1)
end
function VehicleMotor:updateStartGearValues(dt)
    local totalMass = self.vehicle:getTotalMass()
    local totalMassOnGround = 0
    local vehicleMass = self.vehicle:getTotalMass(true)
    if math.abs(totalMass - self.startGearValues.lastMass) > 0.00001 * dt then
        self.startGearValues.lastMass = totalMass
        self.idleGearChangeTimer = 500
    end
    local maxForce = 0
    for _, vehicle in ipairs((self.vehicle:getChildVehicles())) do
        if vehicle ~= self.vehicle then
            if vehicle.spec_powerConsumer ~= nil and (vehicle.spec_powerConsumer.maxForce ~= nil and vehicle:getPowerMultiplier() ~= 0) then
            end
            if vehicle.spec_leveler ~= nil then
                maxForce = maxForce + math.abs(vehicle.spec_leveler.lastForce)
            end
            if vehicle.spec_wheels ~= nil and #vehicle.spec_wheels.wheels > 0 then
                totalMassOnGround = totalMassOnGround + vehicle:getTotalMass(true)
            end
        end
    end
    local comX = 0
    local comY = 0
    local comZ = 0
    local _ = 0
    local vehicle = 0
    local multiplier = 0
    for _, vehicle in ipairs(vehicles) do
        if vehicle ~= self.vehicle and (vehicle.spec_wheels ~= nil and #vehicle.spec_wheels.wheels > 0) then
            local percentage = vehicle:getTotalMass(true) / totalMassOnGround
            local cx, cy, cz = vehicle:getOverallCenterOfMass()
            local iDirX, iDirY, iDirZ = vehicle:getVehicleWorldDirection()
        end
    end
    local vdx, vdy, vdz = self.vehicle:getVehicleWorldDirection()
    if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
        local _, vehicle, objectMass = getWorldTranslation(self.vehicle.components[1].node)
        DebugGizmo.renderAtPosition(comX, comY, comZ, _, vehicle, multiplier, 0, 1, 0, "TOOLS DIR")
        DebugGizmo.renderAtPosition(_, vehicle, objectMass, vdx, vdy, vdz, 0, 1, 0, "VEHICLE DIR")
    end
    local _ = 0
    local vehicle = 0
    if _ ~= 0 or (vehicle ~= 0 or multiplier ~= 0) then
        _ = math.max(math.abs(_ - vdx), (math.abs(multiplier - vdz)))
        vehicle = math.max(vehicle - vdy, 0)
    end
    local percentage = (totalMass - vehicleMass) / 5
    local objectMass = math.min(percentage, 1)
    self.startGearValues.massDirectionDifferenceXZ = _
    self.startGearValues.massDirectionDifferenceY = vehicle
    self.startGearValues.massDirectionFactor = (1 + _ * objectMass) * (1 + vehicle / 0.15 * objectMass)
    local percentage = PowerConsumer.getTotalConsumedPtoTorque(self.vehicle, nil, nil, true) / self:getPtoMotorRpmRatio()
    local cx = self.peakMotorPowerRotSpeed * percentage
    self.startGearValues.availablePower = self.peakMotorPower - cx
    local cz = (((totalMass + maxForce * (1 + cx / self.peakMotorPower * 0.75)) / vehicleMass - 1) * 0.5 + 1) * vehicleMass
    self.startGearValues.maxForce = maxForce
    self.startGearValues.mass = cz
    self.startGearValues.slope = self.vehicle:getVehicleWorldXRot()
    self.startGearValues.massFactor = self.startGearValues.mass * self.startGearValues.massDirectionFactor / (((self.startGearValues.availablePower / 100 - 1) * 50 + 100) * 0.4)
end
function VehicleMotor:getBestStartGear(gears)
    local minFactor = math.huge
    local minFactorGear = 1
    local minFactorGroup = 1
    local maxFactor = 0
    local maxFactorGear = 1
    local maxFactorGroup = 1
    if self.gearGroups == nil then
        local start = self:getGearRatioMultiplier()
        local i = #gears
        for i = i, 1, -1 do
            local factor = self:getStartInGearFactor(gears[i].ratio * start)
            if factor < self.startGearThreshold then
                if maxFactor == 0 then
                    maxFactorGear = i
                    maxFactor = factor
                end
            end
            if factor < minFactor then
                minFactorGear = i
                minFactor = factor
            end
        end
    elseif self:getUseAutomaticGroupShifting() then
        local start = #self.gearGroups
        local limit = 1
        local step = -1
        if self.currentDirection < 0 then
            start = 1
            limit = #self.gearGroups
            step = 1
        end
        for start = start, limit, step do
            local groupRatio = self.gearGroups[start].ratio * (self.directionChangeUseGroup and 1 or self.currentDirection)
            if math.sign(groupRatio) == self.currentDirection or not self.directionChangeUseGroup then
                local i = #gears
                for i = i, 1, -1 do
                    local factor = self:getStartInGearFactor(gears[i].ratio * groupRatio)
                    if factor < self.startGearThreshold then
                        if maxFactor == 0 then
                            maxFactorGroup = start
                            maxFactorGear = i
                            maxFactor = factor
                        end
                    end
                    if factor < minFactor then
                        minFactorGroup = start
                        minFactorGear = i
                        minFactor = factor
                    end
                end
            end
        end
    end
    if maxFactor == 0 then
        return minFactorGear, minFactorGroup
    else
        return maxFactorGear, maxFactorGroup
    end
end
function VehicleMotor:getRequiredRpmAtSpeedLimit(ratio)
    local speedLimit = math.min(self.vehicle:getSpeedLimit(true), (math.max(self.speedLimitAcc, self.vehicle.lastSpeedReal * 3600)))
    if self.vehicle:getCruiseControlState() == Drivable.CRUISECONTROL_STATE_ACTIVE then
        speedLimit = math.min(speedLimit, self.vehicle:getCruiseControlSpeed())
    end
    if ratio > 0 then
        speedLimit = math.min(speedLimit, self.maxForwardSpeed * 3.6)
        if speedLimit then
            ::l5::
            return speedLimit / 3.6 * 30 / 3.141592653589793 * math.abs(ratio)
        end
    end
    local speedLimit = math.min(speedLimit, self.maxBackwardSpeed * 3.6)
    goto l5
end
function VehicleMotor:getStartInGearFactor(ratio)
    if self:getRequiredRpmAtSpeedLimit(ratio) < self.minRpm + (self.maxRpm - self.minRpm) * 0.25 then
        return math.huge
    end
    local slope = self.startGearValues.slope
    if ratio < 0 then
    end
    local slopeFactor = 1 + math.max(slope, 0) / ((((self.startGearValues.availablePower / 100 - 1) / 2) ^ 2 * 2 + 1) * 0.06981)
    return self.startGearValues.massFactor * slopeFactor / (math.abs(ratio) / 300)
end
function VehicleMotor:getBestGearRatio(wheelSpeedRpm, minRatio, maxRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
    if requiredMotorRpm ~= 0 then
        local gearRatio = math.max(requiredMotorRpm - accSafeMotorRpm, requiredMotorRpm * 0.8) / math.max(wheelSpeedRpm, 0.001)
        return math.clamp(gearRatio, minRatio, maxRatio)
    end
    local gearRatio = math.max(wheelSpeedRpm, 0.0001)
    local gearRatio = 0
    local bestGearRatio = minRatio
    for minRatio = minRatio, maxRatio, 0.5 do
        local motorRpm = gearRatio * minRatio
        if self.maxRpm - accSafeMotorRpm < motorRpm then
            break
        end
        local motorPower = self:getTorqueCurveValue((math.max(motorRpm, self.minRpm))) * motorRpm * 3.141592653589793 / 30
        if gearRatio < motorPower then
            bestGearRatio = minRatio
            gearRatio = motorPower
        end
        if requiredMotorPower <= motorPower then
            break
        end
    end
    return bestGearRatio
end
function VehicleMotor:getBestGear(acceleration, wheelSpeedRpm, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
    if (math.abs(acceleration) < 0.001 and (wheelSpeedRpm < 0 and -1 or 1) or acceleration) > 0 then
        if self.minForwardGearRatio == nil then
            return 1, self.forwardGears[1].ratio
        else
            return 1, self:getBestGearRatio(math.max(wheelSpeedRpm, 0), self.minForwardGearRatio, self.maxForwardGearRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
        end
    elseif self.minBackwardGearRatio == nil then
        if self.backwardGears == nil then
            return 1, self.forwardGears[1].ratio
        else
            return -1, -self.backwardGears[1].ratio
        end
    else
        return -1, -self:getBestGearRatio(math.max(-wheelSpeedRpm, 0), self.minBackwardGearRatio, self.maxBackwardGearRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
    end
end
function VehicleMotor:findGearChangeTargetGearPrediction(curGear, gears, gearSign, gearChangeTimer, acceleratorPedal, _)
    local gearRatioMultiplier = self:getGearRatioMultiplier()
    local differentialRotSpeed = gears[curGear].ratio * gearRatioMultiplier
    local gearRatio = math.abs(differentialRotSpeed)
    local differentialRpm = self.differentialRotSpeed * gearSign
    local differentialRotSpeed = math.max(differentialRpm, 0.0001)
    local differentialRpm = differentialRotSpeed * 30 / 3.141592653589793
    local power
    if math.abs(acceleratorPedal) < 0.0001 then
        local neededInertiaTorque = differentialRotSpeed + math.min(self.differentialRotAccelerationSmoothed * gearSign * 0.8, 0) * self.gearChangeTime * 0.001
        power = math.max(neededInertiaTorque, 0)
    else
        local totalMass = self.vehicle:getTotalMass()
        local power = (self.motorAppliedTorque - self.motorExternalTorque - (self.motorRotSpeed - (self.motorRotSpeed - self.motorRotAcceleration * (g_physicsDtLastValidNonInterpolated * 0.001)) / (1 + self.dampingRateFullThrottle / self.rotInertia * g_physicsDtLastValidNonInterpolated * 0.001)) / (g_physicsDtLastValidNonInterpolated * 0.001) * self.rotInertia) * gearRatio / totalMass * 0.9 - math.max(self.differentialRotAccelerationSmoothed * gearSign, 0)
        power = math.max(differentialRotSpeed - math.max(power, 0) * self.gearChangeTime * 0.001, 0)
    end
    local brakeAcc = 0
    local lastDampedMotorRotSpeed = 0
    local totalMass = 1
    local neededInertiaTorque = #gears
    local lastMotorTorque = 1
    local newGear = curGear
    for totalMass = totalMass, neededInertiaTorque, lastMotorTorque do
        local expectedAcc
        if totalMass == curGear then
            expectedAcc = differentialRpm * gearRatio
        else
            expectedAcc = power * math.abs(gears[totalMass].ratio * gearRatioMultiplier) * 30 / 3.141592653589793
        end
        local gravityAcc = self:getStartInGearFactor(gears[totalMass].ratio * gearRatioMultiplier) < self.startGearThreshold and 0 or 1
        if expectedAcc <= self.maxRpm and self.minRpm * gravityAcc <= expectedAcc or totalMass == curGear then
            local power = self:getTorqueCurveValue(expectedAcc) * expectedAcc
            if brakeAcc <= power then
                lastDampedMotorRotSpeed = totalMass
                brakeAcc = power
            end
        end
    end
    if lastDampedMotorRotSpeed ~= 0 then
        local lastMotorTorque = 0
        local uncalculatedAccFactor = #gears
        for uncalculatedAccFactor = uncalculatedAccFactor, 1, -1 do
            local gravityAcc = false
            local power
            if uncalculatedAccFactor == curGear then
                power = clutchRpm
            else
                power = power * math.abs(gears[uncalculatedAccFactor].ratio * gearRatioMultiplier) * 30 / 3.141592653589793
            end
            local startInGearFactor = self:getStartInGearFactor(gears[uncalculatedAccFactor].ratio * gearRatioMultiplier)
            local minRpmFactor = 1
            local neededPowerPctGear = 0.5
            if startInGearFactor < self.startGearThreshold then
                neededPowerPctGear = 0
                minRpmFactor = 0
            end
            if power <= maxAllowedRpm and minAllowedRpm * minRpmFactor <= power or uncalculatedAccFactor == curGear then
                local nextPower = self:getTorqueCurveValue(power) * power
                if brakeAcc * neededPowerPctGear <= nextPower or uncalculatedAccFactor == curGear then
                    local powerFactor = (nextPower - brakeAcc * neededPowerPctGear) / (brakeAcc * (1 - neededPowerPctGear))
                    local gearChangeFactor = gears[uncalculatedAccFactor].ratio * gearRatioMultiplier
                    local rpmPreferenceFactor = maxAllowedRpm - differentialRpm * math.abs(gearChangeFactor)
                    local gearChangeFactor = rpmPreferenceFactor / math.max(maxAllowedRpm - minAllowedRpm, 0.001)
                    local rpmFactor = math.clamp(gearChangeFactor, 0, 2)
                    if rpmFactor > 1 then
                    end
                    local gearChangeFactor
                    if uncalculatedAccFactor == curGear then
                        gearChangeFactor = 1
                    else
                        gearChangeFactor = math.min(-gearChangeTimer / 2000, 0.9)
                    end
                    local rpmPreferenceFactor = 0
                    if uncalculatedAccFactor < curGear then
                        rpmPreferenceFactor = math.clamp((power - clutchRpm) / 250, -1, 0)
                    end
                    local gearChangeFactor = uncalculatedAccFactor < self.bestGearSelected and self:getStartInGearFactor(gearRatio) < self.startGearThreshold and -4 or gearChangeFactor
                    local rpmPreferenceFactor = rpmPreferenceFactor - (1 - math.min(math.sin(rpmFactor * 3.141592653589793) * 5, 2)) * 0.7
                    if uncalculatedAccFactor == curGear and rpmPreferenceFactor > 0 then
                    end
                    local rpmFactor
                    if math.abs(acceleratorPedal) < 0.0001 then
                    end
                    if math.abs(acceleratorPedal) < 0.0001 and (clutchRpm - minRpmFactor) / (maxAllowedRpm - minRpmFactor) > 0.25 then
                        if uncalculatedAccFactor < curGear then
                            powerFactor = 0
                            rpmFactor = 0
                        elseif uncalculatedAccFactor == curGear then
                            powerFactor = 1
                            rpmFactor = 1
                        end
                    end
                    if curGear < uncalculatedAccFactor and startInGearFactor < self.startGearThreshold then
                        powerFactor = 1
                        rpmPreferenceFactor = 1
                    end
                    local factor = powerFactor + rpmFactor + gearChangeFactor + rpmPreferenceFactor
                    if lastMotorTorque <= factor then
                        newGear = uncalculatedAccFactor
                        lastMotorTorque = factor
                    end
                    if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
                        gears[uncalculatedAccFactor].lastTradeoff = factor
                        gears[uncalculatedAccFactor].lastDiffSpeedAfterChange = uncalculatedAccFactor == curGear and power and power or nil
                        gears[uncalculatedAccFactor].lastPowerFactor = powerFactor
                        gears[uncalculatedAccFactor].lastRpmFactor = rpmFactor
                        gears[uncalculatedAccFactor].lastGearChangeFactor = gearChangeFactor
                        gears[uncalculatedAccFactor].lastRpmPreferenceFactor = rpmPreferenceFactor
                        gears[uncalculatedAccFactor].lastNextPower = nextPower
                        gears[uncalculatedAccFactor].nextPowerValid = true
                        gears[uncalculatedAccFactor].lastNextRpm = power
                        gears[uncalculatedAccFactor].nextRpmValid = true
                        gears[uncalculatedAccFactor].lastMaxPower = brakeAcc
                        gears[uncalculatedAccFactor].lastHasPower = true
                    end
                    gravityAcc = true
                elseif VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
                    gears[uncalculatedAccFactor].lastNextPower = nextPower
                end
            end
            if not gravityAcc and VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
                gears[uncalculatedAccFactor].lastTradeoff = 0
                gears[uncalculatedAccFactor].lastPowerFactor = 0
                gears[uncalculatedAccFactor].lastRpmFactor = 0
                gears[uncalculatedAccFactor].lastGearChangeFactor = 0
                gears[uncalculatedAccFactor].lastRpmPreferenceFactor = 0
                gears[uncalculatedAccFactor].lastDiffSpeedAfterChange = uncalculatedAccFactor == curGear and power and power or nil
                gears[uncalculatedAccFactor].lastNextRpm = power
                local powerFactor = false
                if power <= maxAllowedRpm then
                    powerFactor = minAllowedRpm * minRpmFactor <= power
                end
                gears[uncalculatedAccFactor].nextRpmValid = powerFactor
                gears[uncalculatedAccFactor].nextPowerValid = false
                gears[uncalculatedAccFactor].lastMaxPower = brakeAcc
                gears[uncalculatedAccFactor].lastHasPower = false
            end
        end
        return newGear
    end
    local lastMotorTorque = 0
    local totalMass = math.huge
    local gravityAcc = 1
    local expectedAcc = #gears
    local uncalculatedAccFactor = 1
    for gravityAcc = gravityAcc, expectedAcc, uncalculatedAccFactor do
        local power = power * math.abs(gears[gravityAcc].ratio * gearRatioMultiplier) * 30 / 3.141592653589793
        local startInGearFactor = math.max(power - maxAllowedRpm, minAllowedRpm - power)
        if startInGearFactor < totalMass then
            lastMotorTorque = gravityAcc
            totalMass = startInGearFactor
        end
    end
    return lastMotorTorque
end
function VehicleMotor:applyTargetGear()
    local gearRatioMultiplier = self:getGearRatioMultiplier()
    self.gear = self.targetGear
    if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
        if self.currentGears[self.gear] == nil then
            self.minGearRatio = 0
            self.maxGearRatio = 0
        else
            self.minGearRatio = self.currentGears[self.gear].ratio * gearRatioMultiplier
            self.maxGearRatio = self.minGearRatio
        end
    end
    self.gearChangeTime = self.gearChangeTimeOrig
    local directionMultiplier = self.directionChangeUseGear and self.currentDirection or 1
    SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * directionMultiplier, self.targetGear * directionMultiplier, 0, self.previousGear)
end
function VehicleMotor:updateGear(acceleratorPedal, brakePedal, dt)
    self.lastAcceleratorPedal = acceleratorPedal
    if self.gearChangeTimer >= 0 then
        self.gearChangeTimer = self.gearChangeTimer - dt
        if self.gearChangeTimer < 0 and self.targetGear ~= 0 then
            self.allowGearChangeTimer = 3000
            self.allowGearChangeDirection = math.sign(self.targetGear - self.previousGear)
            self:applyTargetGear()
        end
        acceleratorPedal = 0
    elseif self.groupChangeTimer > 0 or self.directionChangeTimer > 0 then
        self.groupChangeTimer = self.groupChangeTimer - dt
        self.directionChangeTimer = self.directionChangeTimer - dt
        if self.groupChangeTimer < 0 and self.directionChangeTimer < 0 then
            self:applyTargetGear()
        end
    else
        local gearSign = 0
        if acceleratorPedal > 0 then
            if self.minForwardGearRatio == nil then
                gearSign = 1
            else
                self.minGearRatio = self.minForwardGearRatio
                self.maxGearRatio = self.maxForwardGearRatio
            end
        elseif acceleratorPedal < 0 then
            if self.minBackwardGearRatio == nil then
                gearSign = -1
            else
                self.minGearRatio = -self.minBackwardGearRatio
                self.maxGearRatio = -self.maxBackwardGearRatio
            end
        elseif self.maxGearRatio > 0 then
        end
        local newGear = self.gear
        local forceGearChange = false
        local skipGearChangeTimer = false
        local bestGear
        if (self.backwardGears or self.forwardGears) and self:getUseAutomaticGearShifting() then
            self.autoGearChangeTimer = self.autoGearChangeTimer - dt
            if self.vehicle:getIsAutomaticShiftingAllowed() or acceleratorPedal ~= 0 then
                local trySelectBestGear = self.vehicle.lastSpeed
                if math.abs(trySelectBestGear) < 0.0003 then
                    local directionChanged = false
                    local trySelectBestGear = false
                    local allowGearOverwritting = false
                    if gearSign < 0 and (self.currentDirection == 1 or self.gear == 0) then
                        self:changeDirection(-1, true)
                        directionChanged = true
                        skipGearChangeTimer = self.directionChangeTime > 0
                    elseif gearSign > 0 and (self.currentDirection == -1 or self.gear == 0) then
                        self:changeDirection(1, true)
                        directionChanged = true
                        skipGearChangeTimer = self.directionChangeTime > 0
                    elseif self.lastAcceleratorPedal == 0 and self.idleGearChangeTimer <= 0 then
                        trySelectBestGear = true
                        self.doSecondBestGearSelection = 3
                    elseif self.doSecondBestGearSelection > 0 and self.lastAcceleratorPedal ~= 0 then
                        self.doSecondBestGearSelection = self.doSecondBestGearSelection - 1
                        if self.doSecondBestGearSelection == 0 then
                            trySelectBestGear = true
                            allowGearOverwritting = true
                        end
                    end
                    if directionChanged then
                        if self.targetGear ~= self.gear then
                            newGear = self.targetGear
                        end
                        trySelectBestGear = true
                    end
                    if trySelectBestGear then
                        local maxFactorGroup
                        bestGear, maxFactorGroup = self:getBestStartGear(self.currentGears)
                        if bestGear == self.gear and bestGear == self.bestGearSelected then
                            bestGear = newGear
                        elseif bestGear > 1 or allowGearOverwritting then
                            self.bestGearSelected = bestGear
                            self.allowGearChangeTimer = 0
                        end
                        if self:getUseAutomaticGroupShifting() and (maxFactorGroup ~= nil and maxFactorGroup ~= self.activeGearGroupIndex) then
                            self:setGearGroup(maxFactorGroup)
                        end
                    else
                        bestGear = newGear
                    end
                elseif self.gear == 0 then
                    bestGear = newGear
                else
                    if self.autoGearChangeTimer <= 0 then
                        local directionChanged = math.sign(acceleratorPedal)
                        local allowGearOverwritting = self.currentDirection
                        acceleratorPedal = directionChanged ~= math.sign(allowGearOverwritting) and 0 or acceleratorPedal
                        newGear = self:findGearChangeTargetGearPrediction(self.gear, self.currentGears, self.currentDirection, self.autoGearChangeTimer, acceleratorPedal, dt)
                        if self:getUseAutomaticGroupShifting() and self.gearGroups ~= nil then
                            if self.activeGearGroupIndex < #self.gearGroups then
                                local bestGear = self:getLastRealMotorRpm()
                                local trySelectBestGear = math.min(bestGear, self.maxRpm) - self.maxRpm
                                if math.abs(trySelectBestGear) < 50 then
                                    if self.gear == #self.currentGears then
                                        if math.sign(self.gearGroups[self.activeGearGroupIndex].ratio) == math.sign(self.gearGroups[self.activeGearGroupIndex + 1].ratio) then
                                            self:shiftGroup(true)
                                            newGear = self:findGearChangeTargetGearPrediction(self.targetGear, self.currentGears, self.currentDirection, self.autoGearChangeTimer, acceleratorPedal, dt)
                                            forceGearChange = true
                                        end
                                    elseif self.groupType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
                                        local directionChanged = math.sign(self.gearGroups[self.activeGearGroupIndex].ratio)
                                        if directionChanged == math.sign(self.gearGroups[self.activeGearGroupIndex + 1].ratio) then
                                            self.gearGroupUpShiftTimer = self.gearGroupUpShiftTimer + dt
                                            if self.gearGroupUpShiftTimer > self.gearGroupUpShiftTime then
                                                self.gearGroupUpShiftTimer = 0
                                                self:shiftGroup(true)
                                            end
                                        else
                                            self.gearGroupUpShiftTimer = 0
                                        end
                                    end
                                else
                                    self.gearGroupUpShiftTimer = 0
                                end
                            else
                                self.gearGroupUpShiftTimer = 0
                            end
                            if self.gear == 1 and self.lastRealMotorRpm < self.minRpm + (self.maxRpm - self.minRpm) * 0.25 then
                                local directionChanged, trySelectBestGear = self:getBestStartGear(self.currentGears)
                                if trySelectBestGear < self.activeGearGroupIndex then
                                    local allowGearOverwritting = math.sign(self.gearGroups[trySelectBestGear].ratio)
                                    if allowGearOverwritting == math.sign(self.gearGroups[self.activeGearGroupIndex].ratio) then
                                        self:setGearGroup(trySelectBestGear)
                                    end
                                end
                            end
                        end
                    end
                    local trySelectBestGear = math.max(newGear, 1)
                    local allowGearOverwritting = #self.currentGears
                    bestGear = math.min(trySelectBestGear, allowGearOverwritting)
                end
                self.allowGearChangeTimer = self.allowGearChangeTimer - dt
                if self.allowGearChangeTimer > 0 and (acceleratorPedal * self.currentDirection > 0 and bestGear < self.gear) then
                    if self.allowGearChangeDirection ~= math.sign(bestGear - self.gear) then
                        bestGear = self.gear
                    end
                end
            else
                bestGear = newGear
            end
        else
            bestGear = newGear
        end
        if bestGear ~= self.gear or forceGearChange then
            if bestGear ~= self.bestGearSelected then
                self.bestGearSelected = -1
            end
            self.targetGear = bestGear
            self.previousGear = self.gear
            self.gear = 0
            self.minGearRatio = 0
            self.maxGearRatio = 0
            if not skipGearChangeTimer then
                self.autoGearChangeTimer = self.autoGearChangeTime
                self.gearChangeTimer = self.gearChangeTime
            end
            self.lastGearChangeTime = g_time
            acceleratorPedal = 0
            local directionChanged = self.directionChangeUseGear and self.currentDirection or 1
            SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * directionChanged, self.targetGear * directionChanged, self.gearChangeTimer, self.previousGear)
            if self.gearChangeTimer == 0 then
                self.gearChangeTimer = -1
                self.allowGearChangeTimer = 3000
                self.allowGearChangeDirection = math.sign(self.targetGear - self.previousGear)
                self:applyTargetGear()
            end
        end
    end
    if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and (self.backwardGears or self.forwardGears) then
        local gearSign = nil
        local newGear = nil
        if self.currentGears[self.gear] ~= nil then
            newGear = self.currentGears[self.gear].ratio * self:getGearRatioMultiplier()
            local skipGearChangeTimer = math.abs(self.differentialRotSpeed)
            local forceGearChange = math.max(skipGearChangeTimer, 0.0001)
            gearSign = math.min(self.motorRotSpeed / forceGearChange, 5000)
        end
        local forceGearChange = 0
        if newGear ~= nil then
            local directionChanged = math.abs(newGear)
            local trySelectBestGear = math.abs(gearSign)
            forceGearChange = MathUtil.lerp(directionChanged, trySelectBestGear, math.min(self.manualClutchValue, 0.9) / 0.9 * 0.5) * math.sign(newGear)
        end
        self.minGearRatio = forceGearChange
        self.maxGearRatio = forceGearChange
        if self.manualClutchValue == 0 and self.maxGearRatio ~= 0 then
            local skipGearChangeTimer = 1
            local directionChanged = self:getNonClampedMotorRpm()
            if directionChanged > 0 then
                skipGearChangeTimer = (self:getClutchRpm() + 50) / directionChanged
            end
            if skipGearChangeTimer < 0.2 then
                self.stallTimer = self.stallTimer + dt
                if self.stallTimer > 500 then
                    self.vehicle:stopMotor()
                    self.stallTimer = 0
                end
            else
                self.stallTimer = 0
            end
        else
            self.stallTimer = 0
        end
    end
    if self:getUseAutomaticGearShifting() then
        if math.abs(self.vehicle.lastSpeed) > 0.0003 and (self.backwardGears or self.forwardGears) and (self.currentDirection > 0 and acceleratorPedal < 0 or self.currentDirection < 0 and acceleratorPedal > 0) then
            acceleratorPedal = 0
            brakePedal = 1
        end
    end
    return acceleratorPedal, brakePedal
end
function VehicleMotor:shiftGear(up)
    if not self.gearChangedIsLocked then
        if self:getIsGearChangeAllowed() then
            local newGear
            if up then
                newGear = self.targetGear + 1 * self.currentDirection
            else
                newGear = self.targetGear - 1 * self.currentDirection
            end
            local newGear
            if self.currentDirection > 0 or self.backwardGears == nil then
                newGear = #self.forwardGears < newGear and #self.forwardGears or newGear
            else
                newGear = (self.currentDirection < 0 or self.backwardGears ~= nil) and #self.backwardGears < newGear and #self.backwardGears or newGear
            end
            if newGear ~= self.targetGear then
                if self.currentDirection > 0 then
                    if newGear < 0 then
                        self:changeDirection(-1)
                        newGear = 1
                    end
                elseif newGear < 0 then
                    self:changeDirection(1)
                    newGear = 1
                end
                self:setGear(newGear)
                self.lastManualShifterActive = false
                return
            end
        else
            SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", true, false)
        end
    end
end
function VehicleMotor:selectGear(gearIndex, activation)
    if activation then
        if self.gear ~= gearIndex then
            if not self:getIsGearChangeAllowed() then
                SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", false, false, gearIndex)
                return
            end
            if self.currentGears[gearIndex] ~= nil then
                self:setGear(gearIndex, true)
                self.lastManualShifterActive = true
                return
            end
        end
    else
        self:setGear(0, false)
        self.lastManualShifterActive = true
    end
end
function VehicleMotor:setGear(gearIndex, _)
    if gearIndex ~= self.targetGear then
        if self.gearChangeTime == 0 and gearIndex < self.targetGear then
            self.loadPercentageChangeCharge = 1
        end
        if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
            self.targetGear = gearIndex
            self.previousGear = self.gear
            self.gear = gearIndex
        else
            self.targetGear = gearIndex
            self.previousGear = self.gear
            self.gear = 0
            self.minGearRatio = 0
            self.maxGearRatio = 0
            self.autoGearChangeTimer = self.autoGearChangeTime
            self.gearChangeTimer = self.gearChangeTime
        end
        self.lastGearChangeTime = g_time
        local directionMultiplier = self.directionChangeUseGear and self.currentDirection or 1
        SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * directionMultiplier, self.targetGear * directionMultiplier, self.gearChangeTime, self.previousGear)
    end
end
function VehicleMotor:shiftGroup(up)
    if not self.gearGroupChangedIsLocked then
        if self:getIsGearGroupChangeAllowed() then
            if self.gearGroups ~= nil then
                local newGearGroupIndex
                if up then
                    newGearGroupIndex = self.activeGearGroupIndex + 1
                else
                    newGearGroupIndex = self.activeGearGroupIndex - 1
                end
                self:setGearGroup((math.clamp(newGearGroupIndex, 1, self.numGearGroups)))
                return
            end
        else
            SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", true, true)
        end
    end
end
function VehicleMotor:selectGroup(groupIndex, activation)
    if activation then
        if self:getIsGearGroupChangeAllowed() then
            if self.gearGroups ~= nil and self.gearGroups[groupIndex] ~= nil then
                self:setGearGroup(groupIndex, true)
                return
            end
        elseif self.activeGearGroupIndex ~= groupIndex then
            SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", false, true, nil, groupIndex)
            return
        end
    else
        self:setGearGroup(0, false)
    end
end
function VehicleMotor:setGearGroup(groupIndex, isLocked)
    local lastActiveGearGroupIndex = self.activeGearGroupIndex
    self.activeGearGroupIndex = groupIndex
    self.gearGroupChangedIsLocked = isLocked
    if self.activeGearGroupIndex ~= lastActiveGearGroupIndex then
        if self.groupType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT and lastActiveGearGroupIndex < self.activeGearGroupIndex then
            self.loadPercentageChangeCharge = 1
        end
        if self.directionChangeUseGroup then
            if self.activeGearGroupIndex > 0 then
                self.currentDirection = math.sign(self.gearGroups[self.activeGearGroupIndex].ratio)
            else
                self.currentDirection = 1
            end
        end
        if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH then
            if self.groupType == VehicleMotor.TRANSMISSION_TYPE.DEFAULT then
                self.groupChangeTimer = self.groupChangeTime
                self.gear = 0
                self.minGearRatio = 0
                self.maxGearRatio = 0
            elseif self.groupType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
                self:applyTargetGear()
            end
        end
        SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, self.groupType == VehicleMotor.TRANSMISSION_TYPE.DEFAULT and self.groupChangeTime or 0)
    end
end
function VehicleMotor:changeDirection(direction, force)
    if direction == nil then
        direction = -self.currentDirection
    end
    if self.backwardGears == nil and self.forwardGears == nil then
        self.currentDirection = direction
        SpecializationUtil.raiseEvent(self.vehicle, "onGearDirectionChanged", self.currentDirection)
    else
        local changeAllowed = ((not self.directionChangeUseGroup or self.gearGroupChangedIsLocked) and true or false) and ((not self.directionChangeUseGear or self.gearChangedIsLocked) and not self.directionChangeUseGear and true or false)
        if changeAllowed then
            changeAllowed = not self.directionChangeUseGroup
        end
        if changeAllowed and (direction ~= self.currentDirection or force) then
            self.currentDirection = direction
            if self.directionChangeTime > 0 then
                self.directionChangeTimer = self.directionChangeTime
                self.gear = 0
                self.minGearRatio = 0
                self.maxGearRatio = 0
            end
            if self.currentDirection < 0 then
                if self.directionChangeUseGear then
                    self.directionLastGear = self.targetGear
                    if not (self:getUseAutomaticGearShifting() and self.lastManualShifterActive) then
                        self.targetGear = self.directionChangeGearIndex
                    end
                    self.currentGears = self.backwardGears or self.forwardGears
                elseif self.directionChangeUseGroup then
                    self.directionLastGroup = self.activeGearGroupIndex
                    self.activeGearGroupIndex = self.directionChangeGroupIndex
                end
            elseif self.directionChangeUseGear then
                if not (self:getUseAutomaticGearShifting() and self.lastManualShifterActive) then
                    if self.directionLastGear > 0 then
                        self.targetGear = not self:getUseAutomaticGearShifting() and self.directionLastGear or self.defaultForwardGear
                    else
                        self.targetGear = self.defaultForwardGear
                    end
                end
                self.currentGears = self.forwardGears
            elseif self.directionChangeUseGroup then
                if self.directionLastGroup > 0 then
                    self.activeGearGroupIndex = self.directionLastGroup
                else
                    self.activeGearGroupIndex = self.defaultGearGroup
                end
            end
            SpecializationUtil.raiseEvent(self.vehicle, "onGearDirectionChanged", self.currentDirection)
            local directionMultiplier = self.directionChangeUseGear and self.currentDirection or 1
            SpecializationUtil.raiseEvent(self.vehicle, "onGearChanged", self.gear * directionMultiplier, self.targetGear * directionMultiplier, self.directionChangeTime, self.previousGear)
            if self.activeGearGroupIndex ~= self.activeGearGroupIndex then
                SpecializationUtil.raiseEvent(self.vehicle, "onGearGroupChanged", self.activeGearGroupIndex, self.directionChangeTime)
            end
            if self.directionChangeTime == 0 then
                self:applyTargetGear()
            end
        end
    end
end
function VehicleMotor:onManualClutchChanged(clutchValue)
    self.manualClutchValue = clutchValue
end
function VehicleMotor:getIsGearChangeAllowed()
    if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH or self.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
        return true
    end
    return self.manualClutchValue > 0.5
end
function VehicleMotor:getIsGearGroupChangeAllowed()
    if self.gearGroups == nil then
        return false
    end
    if self.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH or self.groupType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
        return true
    end
    return self.manualClutchValue > 0.5
end
function VehicleMotor:setTransmissionDirection(direction)
    if direction > 0 then
        self.maxForwardSpeed = self.maxForwardSpeedOrigin
        self.maxBackwardSpeed = self.maxBackwardSpeedOrigin
        self.minForwardGearRatio = self.minForwardGearRatioOrigin
        self.maxForwardGearRatio = self.maxForwardGearRatioOrigin
        self.minBackwardGearRatio = self.minBackwardGearRatioOrigin
        self.maxBackwardGearRatio = self.maxBackwardGearRatioOrigin
    else
        self.maxForwardSpeed = self.maxBackwardSpeedOrigin
        self.maxBackwardSpeed = self.maxForwardSpeedOrigin
        self.minForwardGearRatio = self.minBackwardGearRatioOrigin
        self.maxForwardGearRatio = self.maxBackwardGearRatioOrigin
        self.minBackwardGearRatio = self.minForwardGearRatioOrigin
        self.maxBackwardGearRatio = self.maxForwardGearRatioOrigin
    end
    self.transmissionDirection = direction
end
function VehicleMotor:getMinMaxGearRatio()
    local minRatio = self.minGearRatio
    local maxRatio = self.maxGearRatio
    if self.minGearRatio ~= 0 or self.maxGearRatio ~= 0 then
        if self.clutchSlippingTimer == self.clutchSlippingTime then
            return minRatio, math.max(350, self.maxGearRatio) * math.sign(self.maxGearRatio)
        end
        if self.clutchSlippingTimer > 0 then
            minRatio = MathUtil.lerp(minRatio, self.clutchSlippingGearRatio, self.clutchSlippingTimer / self.clutchSlippingTime)
            maxRatio = MathUtil.lerp(maxRatio, self.clutchSlippingGearRatio, self.clutchSlippingTimer / self.clutchSlippingTime)
        end
    end
    return minRatio, maxRatio
end
function VehicleMotor:getGearRatio()
    return self.gearRatio
end
function VehicleMotor:getGearRatioMultiplier()
    local multiplier = self.directionChangeUseGroup and 1 or self.currentDirection
    if self.gearGroups ~= nil then
        if self.activeGearGroupIndex == 0 then
            return 0
        end
        local group = self.gearGroups[self.activeGearGroupIndex]
        if group ~= nil then
            return group.ratio * multiplier
        end
    end
    return multiplier
end
function VehicleMotor:getIsInNeutral()
    return (self.backwardGears or self.forwardGears) and (self.gear == 0 and self.targetGear == 0) and true or false
end
function VehicleMotor:getCanMotorRun()
    if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and (not self.vehicle:getIsMotorStarted() and (self.backwardGears or self.forwardGears)) and (self.manualClutchValue == 0 and self.maxGearRatio ~= 0) then
        local factor = 1
        local motorRpm = self:getNonClampedMotorRpm()
        if motorRpm > 0 then
            factor = (self:getClutchRpm() + 50) / motorRpm
        end
        if factor < 0.2 then
            return false, VehicleMotor.REASON_CLUTCH_NOT_ENGAGED
        end
    end
    return true
end
function VehicleMotor:getCurMaxRpm()
    local maxRpm = self.maxRpm
    local gearRatio = self:getGearRatio()
    if gearRatio ~= 0 then
        local speedLimit = math.min(self.speedLimit, (math.max(self.speedLimitAcc, self.vehicle.lastSpeedReal * 3600))) * 0.277778
        local speedLimit
        if gearRatio > 0 then
            speedLimit = math.min(speedLimit, self.maxForwardSpeed)
        else
            speedLimit = math.min(speedLimit, self.maxBackwardSpeed)
        end
        maxRpm = math.min(maxRpm, speedLimit * 30 / 3.141592653589793 * math.abs(gearRatio))
    end
    return math.min(maxRpm, self.rpmLimit)
end
function VehicleMotor:setSpeedLimit(limit)
    self.speedLimit = math.max(limit, self.minSpeed)
end
function VehicleMotor:getSpeedLimit()
    return self.speedLimit
end
function VehicleMotor:setAccelerationLimit(accelerationLimit)
    self.accelerationLimit = accelerationLimit
end
function VehicleMotor:getAccelerationLimit()
    return self.accelerationLimit
end
function VehicleMotor:setRpmLimit(rpmLimit)
    self.rpmLimit = rpmLimit
end
function VehicleMotor:setMotorRotationAccelerationLimit(limit)
    self.motorRotationAccelerationLimit = limit
end
function VehicleMotor:getMotorRotationAccelerationLimit()
    return self.motorRotationAccelerationLimit
end
function VehicleMotor:setDirectionChangeMode(directionChangeMode)
    self.directionChangeMode = directionChangeMode
end
function VehicleMotor:setGearShiftMode(gearShiftMode)
    self.gearShiftMode = gearShiftMode
    if self.gearShiftMode == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and self.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT then
        self.gearShiftMode = VehicleMotor.SHIFT_MODE_MANUAL
    end
end
function VehicleMotor:getUseAutomaticGearShifting()
    return self.gearShiftMode == VehicleMotor.SHIFT_MODE_AUTOMATIC and true or not self.manualShiftGears
end
function VehicleMotor:getUseAutomaticGroupShifting()
    return self.gearShiftMode == VehicleMotor.SHIFT_MODE_AUTOMATIC and true or not self.manualShiftGroups
end