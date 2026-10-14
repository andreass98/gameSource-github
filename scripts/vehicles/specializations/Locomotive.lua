source("dataS/scripts/vehicles/specializations/events/LocomotiveStateEvent.lua")
Locomotive = {}
Locomotive.STATE_NONE = 0
Locomotive.STATE_MANUAL_TRAVEL_ACTIVE = 1
Locomotive.STATE_MANUAL_TRAVEL_INACTIVE = 2
Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE = 3
Locomotive.STATE_REQUESTED_POSITION = 4
Locomotive.STATE_REQUESTED_POSITION_BRAKING = 5
Locomotive.NUM_BITS_STATE = 3
Locomotive.AUTOMATIC_DRIVE_DELAY = 1500000
function Locomotive.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SplineVehicle, specializations) and SpecializationUtil.hasSpecialization(Drivable, specializations)
end
function Locomotive.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Locomotive")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.locomotive.powerArm#node", "Power arm node")
    schema:setXMLSpecializationType()
end
function Locomotive.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onAutomatedTrainTravelActive")
end
function Locomotive.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getDownhillForce", Locomotive.getDownhillForce)
    SpecializationUtil.registerFunction(vehicleType, "getLocomotiveSpeed", Locomotive.getLocomotiveSpeed)
    SpecializationUtil.registerFunction(vehicleType, "setRequestedSplinePosition", Locomotive.setRequestedSplinePosition)
    SpecializationUtil.registerFunction(vehicleType, "getDistanceToRequestedPosition", Locomotive.getDistanceToRequestedPosition)
    SpecializationUtil.registerFunction(vehicleType, "setLocomotiveState", Locomotive.setLocomotiveState)
    SpecializationUtil.registerFunction(vehicleType, "startAutomatedTrainTravel", Locomotive.startAutomatedTrainTravel)
    SpecializationUtil.registerFunction(vehicleType, "notifyPlayerFarmChanged", Locomotive.notifyPlayerFarmChanged)
end
function Locomotive.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMotorStarted", Locomotive.getIsMotorStarted)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateVehiclePhysics", Locomotive.updateVehiclePhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", Locomotive.getIsReadyForAutomatedTrainTravel)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "alignToSplineTime", Locomotive.alignToSplineTime)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setTrainSystem", Locomotive.setTrainSystem)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFullName", Locomotive.getFullName)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreSurfaceSoundsActive", Locomotive.getAreSurfaceSoundsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTraveledDistanceStatsActive", Locomotive.getTraveledDistanceStatsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnterable", Locomotive.getIsEnterable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", Locomotive.getIsMapHotspotVisible)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeReset", Locomotive.getCanBeReset)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStopMotorOnLeave", Locomotive.getStopMotorOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMapHotspotPosition", Locomotive.getMapHotspotPosition)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMotorRpmReal", Locomotive.getMotorRpmReal)
end
function Locomotive.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Locomotive)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Locomotive)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Locomotive)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Locomotive)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Locomotive)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Locomotive)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Locomotive)
end
function Locomotive:onLoad(_)
    local spec = self.spec_locomotive
    self.serverMass = 1
    spec.powerArm = self.xmlFile:getValue("vehicle.locomotive.powerArm#node", nil, self.components, self.i3dMappings)
    spec.electricitySpline = nil
    spec.lastVirtualRpm = self:getMotor():getMinRpm()
    spec.speed = 0
    spec.lastAcceleration = 0
    spec.nextMovingDirection = 0
    spec.sellingDirection = 1
    spec.startBrakeDistance = 0
    spec.startBrakeSpeed = 0
    self:setLocomotiveState(Locomotive.STATE_NONE)
    spec.motor = self:getMotor()
    spec.doStartCheck = true
    g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.notifyPlayerFarmChanged, self)
    g_messageCenter:subscribe(MessageType.PLAYER_CREATED, self.notifyPlayerFarmChanged, self)
end
function Locomotive:onDelete()
    g_messageCenter:unsubscribeAll(self)
end
function Locomotive:onReadStream(streamId, _)
    self.spec_locomotive.state = streamReadUIntN(streamId, Locomotive.NUM_BITS_STATE)
end
function Locomotive:onWriteStream(streamId, _)
    streamWriteUIntN(streamId, self.spec_locomotive.state, Locomotive.NUM_BITS_STATE)
end
function Locomotive:onUpdate(dt, _, _, _)
    local spec = self.spec_locomotive
    if spec.doStartCheck and self.trainSystem ~= nil then
        if self.trainSystem:getIsRented() then
            self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_ACTIVE)
        else
            self:startAutomatedTrainTravel()
        end
        self:raiseActive()
        spec.doStartCheck = false
    end
    if self.isServer then
        if spec.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE then
            self:raiseActive()
            self:updateVehiclePhysics(1, 0, 0, dt)
            SpecializationUtil.raiseEvent(self, "onAutomatedTrainTravelActive", dt)
            return
        end
        if spec.state == Locomotive.STATE_REQUESTED_POSITION then
            if spec.requestedSplinePosition ~= nil then
                local splineLength = self.trainSystem:getSplineLength()
                local currentPosition = self:getCurrentSplinePosition() % 1
                local requestedPosition = spec.requestedSplinePosition % 1
                local targetDirection = math.sign(requestedPosition - currentPosition)
                local brakeDistance = math.abs(spec.speed ^ 2 / (2 * Locomotive.getBrakeAcceleration(self)))
                if (targetDirection == self.movingDirection or self.movingDirection == 0) and (targetDirection >= 0 and ((requestedPosition - brakeDistance / splineLength * targetDirection) % 1 < currentPosition and currentPosition < (requestedPosition - brakeDistance / splineLength * targetDirection) % 1 + 0.5) or targetDirection < 0 and (currentPosition < (requestedPosition - brakeDistance / splineLength * targetDirection) % 1 and (requestedPosition - brakeDistance / splineLength * targetDirection) % 1 - 0.5 < currentPosition)) then
                    self:setLocomotiveState(Locomotive.STATE_REQUESTED_POSITION_BRAKING)
                    spec.startBrakeDistance = brakeDistance
                    spec.startBrakeSpeed = spec.speed
                else
                    self:updateVehiclePhysics(targetDirection, 0, 0, dt)
                end
                self:raiseActive()
                return
            end
        elseif spec.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING then
            local splineLength = Locomotive.getBrakeAcceleration(self)
            if math.abs(spec.startBrakeSpeed ^ 2 / (2 * splineLength)) < spec.startBrakeDistance - 10 then
                self:setLocomotiveState(Locomotive.STATE_REQUESTED_POSITION)
            end
            if self.movingDirection > 0 then
                self:updateVehiclePhysics(-1, 0, 0, dt)
            else
                self:updateVehiclePhysics(1, 0, 0, dt)
            end
            self:raiseActive()
            if spec.speed == 0 then
                self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_ACTIVE)
                self:stopMotor()
                return
            end
        elseif spec.state == Locomotive.STATE_MANUAL_TRAVEL_INACTIVE then
            if self.movingDirection > 0 then
                self:updateVehiclePhysics(-1, 0, 0, dt)
            elseif self.movingDirection < 0 then
                self:updateVehiclePhysics(1, 0, 0, dt)
            end
            self:raiseActive()
            return
        end
    elseif spec.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE or (spec.state == Locomotive.STATE_REQUESTED_POSITION or spec.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING) then
        self:raiseActive()
    end
end
function Locomotive:setTrainSystem(superFunc, trainSystem)
    superFunc(self, trainSystem)
    local spec = self.spec_locomotive
    if spec.powerArm ~= nil then
        local spline = trainSystem:getElectricitySpline()
        if spline ~= nil then
            local electricitySplineLength = trainSystem:getElectricitySplineLength()
            spec.splineDiff = math.abs(electricitySplineLength - trainSystem:getSplineLength())
            spec.electricitySplineSearchTime = spec.splineDiff * 5 / electricitySplineLength
            spec.electricitySpline = spline
        end
    end
end
function Locomotive:getFullName(_)
    return g_storeManager:getItemByXMLFilename(self.configFileName).name
end
function Locomotive:getAreSurfaceSoundsActive(_)
    return self:getLastSpeed() > 0.1
end
function Locomotive:getTraveledDistanceStatsActive(_)
    return self.spec_locomotive.state == Locomotive.STATE_MANUAL_TRAVEL_ACTIVE
end
function Locomotive:getIsEnterable(superFunc)
    if not superFunc(self) then
        return false
    end
    if self.trainSystem ~= nil and not self.trainSystem:getIsTrainInDriveableRange() then
        return false
    end
    local spec = self.spec_locomotive
    return spec.state == Locomotive.STATE_MANUAL_TRAVEL_ACTIVE or spec.state == Locomotive.STATE_MANUAL_TRAVEL_INACTIVE
end
function Locomotive:getIsMapHotspotVisible(superFunc)
    if not superFunc(self) then
        return false
    end
    if self.trainSystem ~= nil and not self.trainSystem:getIsTrainInDriveableRange() then
        return false
    end
    local x, _, z = getWorldTranslation(self.rootNode)
    return math.abs(x) <= g_currentMission.terrainSize * 0.5 and math.abs(z) <= g_currentMission.terrainSize * 0.5
end
function Locomotive:getMapHotspotPosition(_)
    if self.trainSystem == nil then
        return 0, 0, 0
    else
        return self.trainSystem:getTrainPosition()
    end
end
function Locomotive:getMotorRpmReal(_)
    return self.spec_locomotive.lastVirtualRpm
end
function Locomotive:setRequestedSplinePosition(splinePosition, _)
    local spec = self.spec_locomotive
    spec.requestedSplinePosition = splinePosition
    self:setLocomotiveState(Locomotive.STATE_REQUESTED_POSITION, true)
    local currentPosition = self:getCurrentSplinePosition()
    if spec.requestedSplinePosition < currentPosition then
        if math.abs(currentPosition - (spec.requestedSplinePosition + 1)) < math.abs(currentPosition - requestedPosition) then
            spec.requestedSplinePosition = requestedPosition + 1
        end
    end
    if self.isServer then
        self:startMotor()
    end
end
function Locomotive:getDistanceToRequestedPosition()
    local spec = self.spec_locomotive
    if spec.state ~= Locomotive.STATE_REQUESTED_POSITION_BRAKING and spec.state ~= Locomotive.STATE_REQUESTED_POSITION then
        return 0
    end
    local currentPosition = self:getCurrentSplinePosition()
    local distanceToGo = math.abs(spec.requestedSplinePosition % 1 - currentPosition)
    return spec.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING and distanceToGo > 0.5 and 0 or distanceToGo * self.trainSystem:getSplineLength()
end
function Locomotive:setLocomotiveState(state, noEventSend)
    self.spec_locomotive.state = state
    if state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE then
        if self.setRandomVehicleCharacter ~= nil then
            self:setRandomVehicleCharacter()
        end
    elseif state == Locomotive.STATE_MANUAL_TRAVEL_ACTIVE then
        self:restoreVehicleCharacter()
    end
    if g_server ~= nil and not noEventSend then
        g_server:broadcastEvent(LocomotiveStateEvent.new(self, state), nil, nil, self)
    end
    self:raiseActive()
end
function Locomotive:startAutomatedTrainTravel()
    self:setLocomotiveState(Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE)
    self:startMotor()
end
function Locomotive:notifyPlayerFarmChanged()
    if self.trainSystem ~= nil then
        self:setIsTabbable(self.trainSystem.isRented and g_localPlayer.farmId == self.trainSystem.rentFarmId)
    end
end
function Locomotive:onLeaveVehicle()
    local spec = self.spec_locomotive
    if spec.state ~= Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE then
        if self:getIsReadyForAutomatedTrainTravel() then
            spec.automaticTravelStartTime = g_time + Locomotive.AUTOMATIC_DRIVE_DELAY
        end
        self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_INACTIVE)
        self:raiseActive()
        spec.requestedSplinePosition = nil
    end
end
function Locomotive:onEnterVehicle()
    local spec = self.spec_locomotive
    spec.requestedSplinePosition = nil
    spec.automaticTravelStartTime = nil
    if not g_currentMission.missionInfo.automaticMotorStartEnabled and (spec.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE or (spec.state == Locomotive.STATE_REQUESTED_POSITION or spec.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING)) then
        self:startMotor(true)
    end
    self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_ACTIVE)
end
function Locomotive:getIsReadyForAutomatedTrainTravel(superFunc)
    if self:getIsControlled() then
        return false
    else
        return superFunc(self)
    end
end
function Locomotive:getIsMotorStarted(superFunc)
    return superFunc(self) or (self.spec_locomotive.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE or (self.spec_locomotive.state == Locomotive.STATE_REQUESTED_POSITION or self.spec_locomotive.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING))
end
function Locomotive:getDownhillForce()
    local dirX, dirY, dirZ = localDirectionToWorld(self.rootNode, 0, 0, 1)
    local angleX = math.acos(dirY / MathUtil.vector3Length(dirX, dirY, dirZ)) - 1.5707963267948966
    return self.serverMass * 9.81 * math.sin(-angleX)
end
function Locomotive:getLocomotiveSpeed()
    return self.spec_locomotive.speed
end
function Locomotive:getBrakeAcceleration()
    local spec = self.spec_locomotive
    local downhillForce = self:getDownhillForce()
    local maxBrakeForce = self.serverMass * 9.81 * 0.18
    local brakeForceSum = spec.speed
    if math.abs(brakeForceSum) >= 0.3 and self:getIsControlled() then
    end
    local brakeForce = maxBrakeForce * (spec.speed < 0 and -1 or 1)
    local brakeForceSum = -brakeForce - downhillForce
    if math.abs(brakeForceSum) < 0.0001 then
        brakeForceSum = -brakeForce - downhillForce * 0.95
    end
    return 1 / self.serverMass * brakeForceSum
end
function Locomotive:updateVehiclePhysics(superFunc, axisForward, axisSide, doHandbrake, dt)
    local spec = self.spec_locomotive
    local acceleration = superFunc(self, axisForward * spec.sellingDirection, axisSide, doHandbrake, dt)
    local interpDt = g_physicsDt
    if g_server == nil then
        interpDt = g_physicsDtUnclamped
    end
    local maxBrakeForce = self.serverMass * 9.81 * 0.18
    local downhillForce = self:getDownhillForce()
    local reverserDirection = math.min(300000, maxBrakeForce)
    if self:getIsMotorStarted() then
        if self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_OFF then
            local cruiseControlSpeed = self:getCruiseControlSpeed() / 3.6
            if spec.speed < (self.spec_drivable == nil and 1 or self.spec_drivable.reverserDirection) * cruiseControlSpeed then
                acceleration = 1
            elseif spec.speed > reverserDirection * cruiseControlSpeed then
                acceleration = -1
            end
        end
    else
        reverserDirection = maxBrakeForce
    end
    if math.abs(acceleration) < 0.001 then
        local reverserDirection = Locomotive.getBrakeAcceleration(self)
        if spec.speed > 0 then
            spec.speed = math.max(0, spec.speed + reverserDirection * dt / 1000)
        elseif spec.speed < 0 then
            spec.speed = math.min(0, spec.speed + reverserDirection * dt / 1000)
        elseif maxBrakeForce < math.abs(downhillForce) then
            spec.speed = spec.speed + reverserDirection * dt / 1000
        end
        if spec.speed == 0 then
            spec.hasStopped = true
        else
            spec.hasStopped = false
        end
    else
        local cruiseControlSpeed = spec.speed
        if math.abs(cruiseControlSpeed) > 0.1 then
            spec.hasStopped = false
        elseif math.abs(spec.speed) == 0 then
            spec.hasStopped = true
        end
        if spec.hasStopped == nil or spec.hasStopped and math.abs(acceleration) > 0.01 then
            spec.nextMovingDirection = math.sign(acceleration)
        end
        local reverserDirection = 0
        if spec.nextMovingDirection == nil or spec.nextMovingDirection * acceleration > 0 then
        else
            local cruiseControlSpeed = math.sign(spec.speed) * math.abs(acceleration) * maxBrakeForce
            if math.abs(spec.speed) < 0.1 then
                spec.speed = 0
            else
                reverserDirection = 1 / self.serverMass * (0 - cruiseControlSpeed - downhillForce)
            end
        end
        spec.speed = spec.speed + reverserDirection * interpDt / 1000
    end
    local reverserDirection = spec.motor
    if spec.speed > 0 then
        spec.speed = math.min(spec.speed, reverserDirection.maxForwardSpeed)
    elseif spec.speed < 0 then
        spec.speed = math.max(spec.speed, -reverserDirection.maxBackwardSpeed)
    end
    local cruiseControlSpeed = reverserDirection.minRpm
    local maxRpm = reverserDirection.maxRpm
    if spec.lastAcceleration * spec.nextMovingDirection > 0 then
        spec.lastVirtualRpm = math.min(maxRpm, spec.lastVirtualRpm + 0.0005 * dt * (maxRpm - cruiseControlSpeed))
    else
        spec.lastVirtualRpm = math.max(cruiseControlSpeed, spec.lastVirtualRpm - 0.001 * dt * (maxRpm - cruiseControlSpeed))
    end
    reverserDirection:setEqualizedMotorRpm(spec.lastVirtualRpm)
    spec.lastAcceleration = acceleration
end
function Locomotive:alignToSplineTime(superFunc, spline, yOffset, tFront)
    local retValue = superFunc(self, spline, yOffset, tFront)
    if retValue ~= nil then
        local spec = self.spec_locomotive
        if spec.powerArm ~= nil and spec.electricitySpline ~= nil then
            local x, y, z = getWorldTranslation(spec.powerArm)
            local cx, cy, cz = getWorldTranslation(g_cameraManager:getActiveCamera())
            if MathUtil.vector3Length(x - cx, y - cy, z - cz) < 50 then
                retValue = SplineUtil.getValidSplineTime(retValue)
                local x, y, z, _ = getLocalClosestSplinePosition(spec.electricitySpline, retValue, spec.electricitySplineSearchTime, x, y, z, 0.01)
                local _, y, _ = worldToLocal(getParent(spec.powerArm), x, y, z)
                local x, _, z = getTranslation(spec.powerArm)
                setTranslation(spec.powerArm, x, y, z)
                if spec.powerArm ~= nil then
                    self:setMovingToolDirty(spec.powerArm)
                end
            end
        end
    end
    if not self.isServer then
        self:updateMapHotspot()
    end
    return retValue
end
function Locomotive:getCanBeReset(superFunc)
    return false
end
function Locomotive:getStopMotorOnLeave(_)
    return self.spec_locomotive.state == Locomotive.STATE_MANUAL_TRAVEL_ACTIVE or self.spec_locomotive.state == Locomotive.STATE_MANUAL_TRAVEL_INACTIVE
end