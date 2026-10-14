source("dataS/scripts/vehicles/specializations/events/SetCruiseControlStateEvent.lua")
source("dataS/scripts/vehicles/specializations/events/SetCruiseControlSpeedEvent.lua")
Drivable = {}
Drivable.CRUISECONTROL_STATE_OFF = 0
Drivable.CRUISECONTROL_STATE_ACTIVE = 1
Drivable.CRUISECONTROL_STATE_FULL = 2
Drivable.CRUISECONTROL_FULL_TOGGLE_TIME = 500
source("dataS/scripts/gui/hud/extensions/CruiseControlHUDExtension.lua")
function Drivable.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Enterable, specializations) and SpecializationUtil.hasSpecialization(Motorized, specializations)
end
function Drivable.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Drivable")
    schema:register(XMLValueType.INT, "vehicle.drivable#reverserDirection", "Default state of reverser direction (when set to -1 the driving direction is inverted)", 1)
    schema:register(XMLValueType.INT, "vehicle.drivable#steeringDirection", "Default state of steering direction (when set to -1 the steering direction is inverted)", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.drivable.speedRotScale#scale", "Speed dependent steering speed scale", 80)
    schema:register(XMLValueType.FLOAT, "vehicle.drivable.speedRotScale#offset", "Speed dependent steering speed offset", 0.7)
    schema:register(XMLValueType.FLOAT, "vehicle.drivable.cruiseControl#maxSpeed", "Max. cruise control speed", "Max. vehicle speed")
    schema:register(XMLValueType.FLOAT, "vehicle.drivable.cruiseControl#minSpeed", "Min. cruise control speed", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.drivable.cruiseControl#maxSpeedReverse", "Max. cruise control speed in reverse", "Max. value reverse speed")
    schema:register(XMLValueType.BOOL, "vehicle.drivable.cruiseControl#enabled", "Cruise control enabled", true)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.drivable.steeringWheel#node", "Steering wheel node")
    schema:register(XMLValueType.ANGLE, "vehicle.drivable.steeringWheel#indoorRotation", "Steering wheel indoor rotation", 0)
    schema:register(XMLValueType.ANGLE, "vehicle.drivable.steeringWheel#outdoorRotation", "Steering wheel outdoor rotation", 0)
    schema:register(XMLValueType.BOOL, "vehicle.drivable.idleTurning#allowed", "When vehicle is not moving and steering keys are pressed turns on the same spot", false)
    schema:register(XMLValueType.BOOL, "vehicle.drivable.idleTurning#updateSteeringWheel", "Update steering wheel", true)
    schema:register(XMLValueType.BOOL, "vehicle.drivable.idleTurning#lockDirection", "Defines if the direction is locked until player accelerates again", true)
    schema:register(XMLValueType.INT, "vehicle.drivable.idleTurning#direction", "Driving direction [-1, 1]", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.drivable.idleTurning#maxSpeed", "Max. speed while turning", 10)
    schema:register(XMLValueType.FLOAT, "vehicle.drivable.idleTurning#steeringFactor", "Steering speed factor", 100)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.drivable.idleTurning.wheel(?)#node", "Wheel node to change")
    schema:register(XMLValueType.ANGLE, "vehicle.drivable.idleTurning.wheel(?)#steeringAngle", "Steering angle while idle turning")
    schema:register(XMLValueType.BOOL, "vehicle.drivable.idleTurning.wheel(?)#inverted", "Acceleration is inverted", false)
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.drivable.dashboards", {
        "cruiseControl",
        "cruiseControlReverse",
        "directionForward",
        "directionBackward",
        "movingDirection",
        "cruiseControlActive",
        "accelerationAxis",
        "decelerationAxis",
        "ac_decelerationAxis",
        "steeringAngle",
        "combinedPedalLeft",
        "combinedPedalRight",
        "odometerMilage"
    })
    SoundManager.registerSampleXMLPaths(schema, "vehicle.drivable.sounds", "waterSplash")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).drivable#cruiseControl", "Current cruise control speed")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).drivable#cruiseControlReverse", "Current cruise control speed reverse")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).drivable#odometerMilage", "Current odometer milage (km)", 0)
end
function Drivable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "updateSteeringWheel", Drivable.updateSteeringWheel)
    SpecializationUtil.registerFunction(vehicleType, "setCruiseControlState", Drivable.setCruiseControlState)
    SpecializationUtil.registerFunction(vehicleType, "setCruiseControlMaxSpeed", Drivable.setCruiseControlMaxSpeed)
    SpecializationUtil.registerFunction(vehicleType, "getCruiseControlState", Drivable.getCruiseControlState)
    SpecializationUtil.registerFunction(vehicleType, "getCruiseControlSpeed", Drivable.getCruiseControlSpeed)
    SpecializationUtil.registerFunction(vehicleType, "getCruiseControlMaxSpeed", Drivable.getCruiseControlMaxSpeed)
    SpecializationUtil.registerFunction(vehicleType, "getCruiseControlDisplayInfo", Drivable.getCruiseControlDisplayInfo)
    SpecializationUtil.registerFunction(vehicleType, "getAxisForward", Drivable.getAxisForward)
    SpecializationUtil.registerFunction(vehicleType, "getAccelerationAxis", Drivable.getAccelerationAxis)
    SpecializationUtil.registerFunction(vehicleType, "getDecelerationAxis", Drivable.getDecelerationAxis)
    SpecializationUtil.registerFunction(vehicleType, "getCruiseControlAxis", Drivable.getCruiseControlAxis)
    SpecializationUtil.registerFunction(vehicleType, "getAcDecelerationAxis", Drivable.getAcDecelerationAxis)
    SpecializationUtil.registerFunction(vehicleType, "getDashboardSteeringAxis", Drivable.getDashboardSteeringAxis)
    SpecializationUtil.registerFunction(vehicleType, "setReverserDirection", Drivable.setReverserDirection)
    SpecializationUtil.registerFunction(vehicleType, "getReverserDirection", Drivable.getReverserDirection)
    SpecializationUtil.registerFunction(vehicleType, "getSteeringDirection", Drivable.getSteeringDirection)
    SpecializationUtil.registerFunction(vehicleType, "getIsDrivingForward", Drivable.getIsDrivingForward)
    SpecializationUtil.registerFunction(vehicleType, "getIsDrivingBackward", Drivable.getIsDrivingBackward)
    SpecializationUtil.registerFunction(vehicleType, "getDrivingDirection", Drivable.getDrivingDirection)
    SpecializationUtil.registerFunction(vehicleType, "getIsVehicleControlledByPlayer", Drivable.getIsVehicleControlledByPlayer)
    SpecializationUtil.registerFunction(vehicleType, "getIsPlayerVehicleControlAllowed", Drivable.getIsPlayerVehicleControlAllowed)
    SpecializationUtil.registerFunction(vehicleType, "registerPlayerVehicleControlAllowedFunction", Drivable.registerPlayerVehicleControlAllowedFunction)
    SpecializationUtil.registerFunction(vehicleType, "updateVehiclePhysics", Drivable.updateVehiclePhysics)
    SpecializationUtil.registerFunction(vehicleType, "setAccelerationPedalInput", Drivable.setAccelerationPedalInput)
    SpecializationUtil.registerFunction(vehicleType, "setBrakePedalInput", Drivable.setBrakePedalInput)
    SpecializationUtil.registerFunction(vehicleType, "setTargetSpeedAndDirection", Drivable.setTargetSpeedAndDirection)
    SpecializationUtil.registerFunction(vehicleType, "setSteeringInput", Drivable.setSteeringInput)
    SpecializationUtil.registerFunction(vehicleType, "brakeToStop", Drivable.brakeToStop)
    SpecializationUtil.registerFunction(vehicleType, "updateSteeringAngle", Drivable.updateSteeringAngle)
end
function Drivable.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsManualDirectionChangeAllowed", Drivable.getIsManualDirectionChangeAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMapHotspotRotation", Drivable.getMapHotspotRotation)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setTransmissionDirection", Drivable.setTransmissionDirection)
end
function Drivable.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onVehiclePhysicsUpdate")
    SpecializationUtil.registerEvent(vehicleType, "onCruiseControlSpeedChanged")
end
function Drivable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Drivable)
    SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Drivable)
end
function Drivable:onLoad(savegame)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.steering#index", "vehicle.drivable.steeringWheel#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.steering#node", "vehicle.drivable.steeringWheel#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cruiseControl", "vehicle.drivable.cruiseControl")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.cruiseControl", "vehicle.drivable.dashboards.dashboard with valueType \'cruiseControl\'")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.showChangeToolSelectionHelp")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.maxRotatedTimeSpeed#value")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.speedRotScale#scale", "vehicle.drivable.speedRotScale#scale")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.speedRotScale#offset", "vehicle.drivable.speedRotScale#offset")
    local spec = self.spec_drivable
    spec.showToolSelectionHud = true
    spec.doHandbrake = false
    spec.doHandbrakeSend = false
    spec.reverserDirection = self.xmlFile:getValue("vehicle.drivable#reverserDirection", 1)
    spec.steeringDirection = self.xmlFile:getValue("vehicle.drivable#steeringDirection", 1)
    spec.lastInputValues = {}
    spec.lastInputValues.axisAccelerate = 0
    spec.lastInputValues.axisBrake = 0
    spec.lastInputValues.axisSteer = 0
    spec.lastInputValues.axisSteerIsAnalog = false
    spec.lastInputValues.axisSteerDeviceCategory = InputDevice.CATEGORY.UNKNOWN
    spec.lastInputValues.cruiseControlValue = 0
    spec.lastInputValues.cruiseControlState = 0
    spec.axisForward = 0
    spec.axisForwardSend = 0
    spec.axisSide = 0
    spec.axisSideSend = 0
    spec.axisSideLast = 0
    spec.lastIsControlled = false
    spec.speedRotScale = self.xmlFile:getValue("vehicle.drivable.speedRotScale#scale", 80)
    spec.speedRotScaleOffset = self.xmlFile:getValue("vehicle.drivable.speedRotScale#offset", 0.7)
    local motor = self:getMotor()
    spec.cruiseControl = {}
    spec.cruiseControl.maxSpeed = self.xmlFile:getValue("vehicle.drivable.cruiseControl#maxSpeed", MathUtil.round(motor:getMaximumForwardSpeed() * 3.6))
    local node = spec.cruiseControl
    node.minSpeed = self.xmlFile:getValue("vehicle.drivable.cruiseControl#minSpeed", (math.min(1, spec.cruiseControl.maxSpeed)))
    spec.cruiseControl.speed = spec.cruiseControl.maxSpeed
    spec.cruiseControl.maxSpeedReverse = self.xmlFile:getValue("vehicle.drivable.cruiseControl#maxSpeedReverse", MathUtil.round(motor:getMaximumBackwardSpeed() * 3.6))
    spec.cruiseControl.speedReverse = spec.cruiseControl.maxSpeedReverse
    spec.cruiseControl.isActive = self.xmlFile:getValue("vehicle.drivable.cruiseControl#enabled", true)
    spec.cruiseControl.state = Drivable.CRUISECONTROL_STATE_OFF
    spec.cruiseControl.topSpeedTime = 1000
    spec.cruiseControl.changeDelay = 250
    spec.cruiseControl.changeCurrentDelay = 0
    spec.cruiseControl.changeMultiplier = 1
    spec.cruiseControl.transmissionDirection = 1
    spec.cruiseControl.speedSent = spec.cruiseControl.speed
    spec.cruiseControl.speedReverseSent = spec.cruiseControl.speedReverse
    local node = self.xmlFile:getValue("vehicle.drivable.steeringWheel#node", nil, self.components, self.i3dMappings)
    if node ~= nil then
        spec.steeringWheel = {}
        spec.steeringWheel.node = node
        local _, ry, _ = getRotation(spec.steeringWheel.node)
        spec.steeringWheel.lastRotation = ry
        spec.steeringWheel.indoorRotation = self.xmlFile:getValue("vehicle.drivable.steeringWheel#indoorRotation", 0)
        spec.steeringWheel.outdoorRotation = self.xmlFile:getValue("vehicle.drivable.steeringWheel#outdoorRotation", 0)
    end
    spec.idleTurningAllowed = self.xmlFile:getValue("vehicle.drivable.idleTurning#allowed", false)
    spec.idleTurningUpdateSteeringWheel = self.xmlFile:getValue("vehicle.drivable.idleTurning#updateSteeringWheel", true)
    spec.idleTurningLockDirection = self.xmlFile:getValue("vehicle.drivable.idleTurning#lockDirection", true)
    spec.idleTurningDrivingDirection = self.xmlFile:getValue("vehicle.drivable.idleTurning#direction", 1)
    spec.idleTurningMaxSpeed = self.xmlFile:getValue("vehicle.drivable.idleTurning#maxSpeed", 10)
    spec.idleTurningSteeringFactor = self.xmlFile:getValue("vehicle.drivable.idleTurning#steeringFactor", 100)
    spec.idleTurningWheels = {}
    self.xmlFile:iterate("vehicle.drivable.idleTurning.wheel", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local wheelNode = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        if wheelNode ~= nil then
            local entry = {
                ["wheelNode"] = wheelNode,
                ["steeringAngle"] = self.xmlFile:getValue(key .. "#steeringAngle", 0),
                ["inverted"] = self.xmlFile:getValue(key .. "#inverted", false)
            }
            table.insert(spec.idleTurningWheels, entry)
        end
    end)
    spec.idleTurningActive = false
    spec.idleTurningActiveSend = false
    spec.idleTurningDirection = 0
    self.customSteeringAngleFunction = self.customSteeringAngleFunction or #spec.idleTurningWheels > 0
    spec.forceFeedback = {}
    spec.forceFeedback.isActive = false
    spec.forceFeedback.device = nil
    spec.forceFeedback.binding = nil
    spec.forceFeedback.axisIndex = 0
    spec.forceFeedback.intensity = g_gameSettings:getValue(GameSettings.SETTING.FORCE_FEEDBACK)
    spec.playerControlAllowedFunctions = {}
    spec.hasPlayerControlAllowedFunctions = false
    spec.initialWheelPhysicsUpdate = true
    spec.odometerMilage = 0
    if self.isClient then
        spec.samples = {}
        spec.samples.waterSplash = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.drivable.sounds", "waterSplash", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        if self.isClient and (g_isDevelopmentVersion and (not GS_IS_MOBILE_VERSION and spec.samples.waterSplash == nil)) then
            Logging.xmlDevWarning(self.xmlFile, "Missing drivable waterSplash sound")
        end
    end
    if savegame ~= nil then
        self:setCruiseControlMaxSpeed(savegame.xmlFile:getValue(savegame.key .. ".drivable#cruiseControl"), (savegame.xmlFile:getValue(savegame.key .. ".drivable#cruiseControlReverse")))
        spec.odometerMilage = savegame.xmlFile:getValue(savegame.key .. ".drivable#odometerMilage", spec.odometerMilage)
    end
    spec.hudExtension = CruiseControlHUDExtension.new(self)
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function Drivable:onRegisterDashboardValueTypes()
    local spec = self.spec_drivable
    local cruiseControl = DashboardValueType.new("drivable", "cruiseControl")
    cruiseControl:setValue(spec.cruiseControl, "speed")
    self:registerDashboardValueType(cruiseControl)
    local cruiseControlReverse = DashboardValueType.new("drivable", "cruiseControlReverse")
    cruiseControlReverse:setValue(spec.cruiseControl, "speedReverse")
    self:registerDashboardValueType(cruiseControlReverse)
    local cruiseControlActive = DashboardValueType.new("drivable", "cruiseControlActive")
    cruiseControlActive:setValue(spec.cruiseControl, "state")
    cruiseControlActive:setValueCompare(Drivable.CRUISECONTROL_STATE_ACTIVE, Drivable.CRUISECONTROL_STATE_FULL)
    self:registerDashboardValueType(cruiseControlActive)
    local directionForward = DashboardValueType.new("drivable", "directionForward")
    directionForward:setValue(self, "getIsDrivingForward")
    self:registerDashboardValueType(directionForward)
    local directionBackward = DashboardValueType.new("drivable", "directionBackward")
    directionBackward:setValue(self, "getIsDrivingBackward")
    self:registerDashboardValueType(directionBackward)
    local movingDirection = DashboardValueType.new("drivable", "movingDirection")
    movingDirection:setValue(self, "getDrivingDirection")
    movingDirection:setRange(-1, 1)
    self:registerDashboardValueType(movingDirection)
    local accelerationAxis = DashboardValueType.new("drivable", "accelerationAxis")
    accelerationAxis:setValue(self, "getAccelerationAxis")
    self:registerDashboardValueType(accelerationAxis)
    local decelerationAxis = DashboardValueType.new("drivable", "decelerationAxis")
    decelerationAxis:setValue(self, "getDecelerationAxis")
    self:registerDashboardValueType(decelerationAxis)
    local ac_decelerationAxis = DashboardValueType.new("drivable", "ac_decelerationAxis")
    ac_decelerationAxis:setValue(self, "getAcDecelerationAxis")
    self:registerDashboardValueType(ac_decelerationAxis)
    local steeringAngle = DashboardValueType.new("drivable", "steeringAngle")
    steeringAngle:setValue(self, "getDashboardSteeringAxis")
    steeringAngle:setRange(-1, 1)
    self:registerDashboardValueType(steeringAngle)
    local combinedPedalLeft = DashboardValueType.new("drivable", "combinedPedalLeft")
    combinedPedalLeft:setValue(self, Drivable.getDashboardCombinedPedalLeft)
    combinedPedalLeft:setRange(-1, 1)
    self:registerDashboardValueType(combinedPedalLeft)
    local combinedPedalRight = DashboardValueType.new("drivable", "combinedPedalRight")
    combinedPedalRight:setValue(self, Drivable.getDashboardCombinedPedalRight)
    combinedPedalRight:setRange(-1, 1)
    self:registerDashboardValueType(combinedPedalRight)
    local odometerMilage = DashboardValueType.new("drivable", "odometerMilage")
    odometerMilage:setValue(spec, "odometerMilage")
    self:registerDashboardValueType(odometerMilage)
end
function Drivable:onDelete()
    local spec = self.spec_drivable
    g_soundManager:deleteSamples(spec.samples)
    if spec.hudExtension ~= nil then
        spec.hudExtension:delete()
    end
end
function Drivable:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_drivable
    xmlFile:setValue(key .. "#cruiseControl", spec.cruiseControl.speed)
    xmlFile:setValue(key .. "#cruiseControlReverse", spec.cruiseControl.speedReverse)
    xmlFile:setValue(key .. "#odometerMilage", spec.odometerMilage)
end
function Drivable:onReadStream(streamId, _)
    local spec = self.spec_drivable
    if spec.cruiseControl.isActive then
        self:setCruiseControlState(streamReadUIntN(streamId, 2), true)
        local speed = streamReadUInt8(streamId)
        local speedReverse = streamReadUInt8(streamId)
        self:setCruiseControlMaxSpeed(speed, speedReverse)
        spec.cruiseControl.speedSent = speed
        spec.cruiseControl.speedReverseSent = speedReverse
        spec.odometerMilage = streamReadFloat32(streamId)
    end
end
function Drivable:onWriteStream(streamId, _)
    local spec = self.spec_drivable
    if spec.cruiseControl.isActive then
        streamWriteUIntN(streamId, spec.cruiseControl.state, 2)
        streamWriteUInt8(streamId, spec.cruiseControl.speed)
        streamWriteUInt8(streamId, spec.cruiseControl.speedReverse)
        streamWriteFloat32(streamId, spec.odometerMilage)
    end
end
function Drivable:onReadUpdateStream(streamId, _, _)
    if streamReadBool(streamId) then
        self.spec_drivable.axisForward = streamReadUIntN(streamId, 10) / 1023 * 2 - 1
        if math.abs(spec.axisForward) < 0.00099 then
            spec.axisForward = 0
        end
        spec.axisSide = streamReadUIntN(streamId, 10) / 1023 * 2 - 1
        if math.abs(spec.axisSide) < 0.00099 then
            spec.axisSide = 0
        end
        spec.doHandbrake = streamReadBool(streamId)
        spec.idleTurningActive = streamReadBool(streamId)
    end
end
function Drivable:onWriteUpdateStream(streamId, _, dirtyMask)
    local spec = self.spec_drivable
    local axisForward = streamWriteBool
    if axisForward(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
        local axisForward = math.clamp(spec.axisForward + 1, 0, 2) / 2 * 1023
        streamWriteUIntN(streamId, axisForward, 10)
        local axisSide = math.clamp(spec.axisSide + 1, 0, 2) / 2 * 1023
        streamWriteUIntN(streamId, axisSide, 10)
        streamWriteBool(streamId, spec.doHandbrake)
        streamWriteBool(streamId, spec.idleTurningActive)
    end
end
function Drivable:onUpdate(dt, _, _, _)
    local spec = self.spec_drivable
    if self.isClient and (self.getIsEntered ~= nil and self:getIsEntered()) then
        if self.isActiveForInputIgnoreSelectionIgnoreAI then
            if self:getIsVehicleControlledByPlayer() then
                local lastSpeed = self:getLastSpeed()
                spec.doHandbrake = false
                local currentSpeed = spec.lastInputValues.axisAccelerate - spec.lastInputValues.axisBrake
                local axisForward = math.clamp(currentSpeed, -1, 1)
                spec.axisForward = axisForward
                if spec.brakeToStop then
                    spec.lastInputValues.targetSpeed = 0.51
                    spec.lastInputValues.targetDirection = 1
                    if lastSpeed < 1 then
                        spec.brakeToStop = false
                        spec.lastInputValues.targetSpeed = nil
                        spec.lastInputValues.targetDirection = nil
                    end
                end
                if spec.lastInputValues.targetSpeed ~= nil then
                    local currentSpeed = lastSpeed * self.movingDirection * self:getReverserDirection()
                    local targetSpeed = spec.lastInputValues.targetSpeed * spec.lastInputValues.targetDirection
                    local speedDifference = targetSpeed - currentSpeed
                    if math.abs(speedDifference) > 0.1 and math.abs(targetSpeed) > 0.5 then
                        local speedForceFactor = math.abs(speedDifference)
                        local forceFeedback = math.pow(speedForceFactor, 1.5) * math.sign(speedDifference)
                        spec.axisForward = math.clamp(forceFeedback, -1, 1)
                    end
                end
                if self:getIsPowered() then
                    local currentSpeed = 1
                    local targetSpeed = g_gameSettings:getValue(GameSettings.SETTING.STEERING_SENSITIVITY)
                    local speedDifference = spec.lastInputValues.axisSteer
                    local currentSpeed
                    if spec.lastInputValues.axisSteerIsAnalog then
                        local isArticulatedSteering = false
                        if self.spec_articulatedAxis ~= nil then
                            isArticulatedSteering = self.spec_articulatedAxis.componentJoint ~= nil
                        end
                        currentSpeed = isArticulatedSteering and 1.5 or 2.5
                        if GS_IS_MOBILE_VERSION then
                            currentSpeed = currentSpeed * 1.5
                            if speedDifference == 0 then
                                currentSpeed = currentSpeed * g_gameSettings:getValue(GameSettings.SETTING.STEERING_BACK_SPEED) / 10
                            end
                            local forceFeedback = math.pow(math.abs(speedDifference), 1 / targetSpeed)
                            speedDifference = forceFeedback * (speedDifference >= 0 and 1 or -1)
                        elseif spec.lastInputValues.axisSteerDeviceCategory == InputDevice.CATEGORY.GAMEPAD then
                            local forceFeedback = math.min(1 / (self.lastSpeed * spec.speedRotScale + spec.speedRotScaleOffset), 1)
                            currentSpeed = forceFeedback * forceFeedback * targetSpeed * 1.75
                        end
                        local forceFeedback = spec.forceFeedback
                        if forceFeedback.isActive then
                            if forceFeedback.intensity > 0 then
                                local angleFactor = math.abs(speedDifference)
                                local targetState = math.min((lastSpeed - 2) / 15, 1)
                                local speedForceFactor = math.max(targetState, 0)
                                local targetState = speedDifference - 0.2 * speedForceFactor * math.sign(speedDifference)
                                forceFeedback.device:setForceFeedback(forceFeedback.axisIndex, math.max(math.abs(targetState) * 0.4, 0.25) * speedForceFactor * angleFactor * 2 * forceFeedback.intensity, targetState)
                            else
                                forceFeedback.device:setForceFeedback(forceFeedback.axisIndex, 0, speedDifference)
                            end
                        end
                    else
                        local isArticulatedSteering = false
                        if spec.lastInputValues.axisSteer ~= 0 then
                            local forceFeedback = math.sign(spec.lastInputValues.axisSteer)
                            isArticulatedSteering = forceFeedback ~= math.sign(spec.axisSide)
                        end
                        if spec.lastInputValues.axisSteer == 0 or isArticulatedSteering then
                            local forceFeedback = g_gameSettings:getValue(GameSettings.SETTING.STEERING_BACK_SPEED) / 10
                            if not isArticulatedSteering and (forceFeedback < 1 and self.speedDependentRotateBack) then
                                local force = math.max(lastSpeed - 0.5, 0) / 36 * (forceFeedback / 0.5)
                                currentSpeed = currentSpeed * math.min(force, 1)
                            end
                            currentSpeed = currentSpeed * (self.autoRotateBackSpeed or 1) / 1.5
                        else
                            currentSpeed = math.min(1 / (self.lastSpeed * spec.speedRotScale + spec.speedRotScaleOffset), 1) * targetSpeed
                        end
                    end
                    if spec.idleTurningAllowed then
                        if axisForward == 0 and (math.abs(speedDifference) > 0.05 and (lastSpeed < 1 and not spec.idleTurningActive)) then
                            spec.idleTurningActive = true
                            spec.idleTurningDirection = math.sign(speedDifference) * spec.idleTurningDrivingDirection
                        end
                        if axisForward ~= 0 and spec.idleTurningActive then
                            spec.idleTurningActive = false
                            if speedDifference > 0 then
                                self.rotatedTime = self.minRotTime
                                spec.axisSide = 1
                            elseif speedDifference < 0 then
                                self.rotatedTime = self.maxRotTime
                                spec.axisSide = -1
                            end
                        end
                        if spec.idleTurningActive and not spec.idleTurningLockDirection then
                            spec.idleTurningDirection = spec.idleTurningDrivingDirection
                            if speedDifference == 0 then
                                spec.idleTurningActive = false
                                spec.axisSide = 0
                            end
                        end
                        if spec.idleTurningActive then
                            spec.axisForward = spec.idleTurningDirection * math.sign(speedDifference)
                            speedDifference = math.abs(speedDifference) * spec.idleTurningDirection
                        end
                    end
                    local forceFeedback = dt / ((self.wheelSteeringDuration or 1) * 1000) * currentSpeed
                    if spec.axisSide < speedDifference then
                        spec.axisSide = math.min(speedDifference, spec.axisSide + forceFeedback)
                    elseif speedDifference < spec.axisSide then
                        spec.axisSide = math.max(speedDifference, spec.axisSide - forceFeedback)
                    end
                end
            else
                spec.axisForward = 0
                spec.idleTurningActive = false
                if self.rotatedTime < 0 then
                    spec.axisSide = self.rotatedTime / -self.maxRotTime / self:getSteeringDirection()
                else
                    spec.axisSide = self.rotatedTime / self.minRotTime / self:getSteeringDirection()
                end
            end
        else
            spec.doHandbrake = true
            spec.axisForward = 0
            spec.idleTurningActive = false
        end
        spec.lastInputValues.axisAccelerate = 0
        spec.lastInputValues.axisBrake = 0
        spec.lastInputValues.axisSteer = 0
        if spec.axisForward ~= spec.axisForwardSend or (spec.axisSide ~= spec.axisSideSend or (spec.doHandbrake ~= spec.doHandbrakeSend or spec.idleTurningActiveSend ~= spec.idleTurningActive)) then
            spec.axisForwardSend = spec.axisForward
            spec.axisSideSend = spec.axisSide
            spec.doHandbrakeSend = spec.doHandbrake
            spec.idleTurningActiveSend = spec.idleTurningActive
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    end
    if self.isClient and (self.getIsEntered ~= nil and self:getIsEntered()) then
        spec.lastInputValues.cruiseControlState = 0
        if spec.lastInputValues.cruiseControlState == 1 then
            if spec.cruiseControl.topSpeedTime == Drivable.CRUISECONTROL_FULL_TOGGLE_TIME then
                if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF then
                    self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
                else
                    self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
                end
            end
            if spec.cruiseControl.topSpeedTime > 0 then
                spec.cruiseControl.topSpeedTime = spec.cruiseControl.topSpeedTime - dt
                if spec.cruiseControl.topSpeedTime < 0 then
                    self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_FULL)
                end
            end
        else
            spec.cruiseControl.topSpeedTime = Drivable.CRUISECONTROL_FULL_TOGGLE_TIME
        end
        local axisForward = spec.lastInputValues.cruiseControlValue
        spec.lastInputValues.cruiseControlValue = 0
        if axisForward == 0 then
            spec.cruiseControl.changeCurrentDelay = 0
            spec.cruiseControl.changeMultiplier = 1
        else
            spec.cruiseControl.changeCurrentDelay = spec.cruiseControl.changeCurrentDelay - dt * spec.cruiseControl.changeMultiplier
            local currentSpeed = spec.cruiseControl
            local speedDifference = spec.cruiseControl.changeMultiplier + dt * 0.003
            currentSpeed.changeMultiplier = math.min(speedDifference, 10)
            if spec.cruiseControl.changeCurrentDelay < 0 then
                spec.cruiseControl.changeCurrentDelay = spec.cruiseControl.changeDelay
                local currentSpeed = math.sign(axisForward)
                local targetSpeed = spec.cruiseControl.speed
                local speedDifference = spec.cruiseControl.speedReverse
                local isArticulatedSteering = self:getDrivingDirection() < 0
                if self:getReverserDirection() < 0 then
                end
                if isArticulatedSteering then
                end
                self:setCruiseControlMaxSpeed(targetSpeed, speedDifference)
                if spec.cruiseControl.speed ~= spec.cruiseControl.speedSent or spec.cruiseControl.speedReverse ~= spec.cruiseControl.speedReverseSent then
                    if g_server == nil then
                        g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent.new(self, spec.cruiseControl.speed, spec.cruiseControl.speedReverse))
                    else
                        g_server:broadcastEvent(SetCruiseControlSpeedEvent.new(self, spec.cruiseControl.speed, spec.cruiseControl.speedReverse), nil, nil, self)
                    end
                    spec.cruiseControl.speedSent = spec.cruiseControl.speed
                    spec.cruiseControl.speedReverseSent = spec.cruiseControl.speedReverse
                end
            end
        end
    end
    local lastSpeed = false
    if self.getIsControlled ~= nil then
        lastSpeed = self:getIsControlled()
    end
    if self:getIsVehicleControlledByPlayer() and self.isServer then
        if lastSpeed then
            local axisForward = math.huge
            if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
                if self:getReverserDirection() < 0 then
                    axisForward = spec.cruiseControl.speedReverse
                else
                    axisForward = spec.cruiseControl.speed
                end
            end
            if self:getDrivingDirection() < 0 then
                if self:getReverserDirection() < 0 then
                    axisForward = math.min(axisForward, spec.cruiseControl.speed)
                else
                    axisForward = math.min(axisForward, spec.cruiseControl.speedReverse)
                end
            end
            if axisForward == math.huge then
                spec.cruiseControl.speedInterpolated = nil
            else
                spec.cruiseControl.speedInterpolated = spec.cruiseControl.speedInterpolated or axisForward
                if axisForward ~= spec.cruiseControl.speedInterpolated then
                    local currentSpeed = axisForward - spec.cruiseControl.speedInterpolated
                    local targetSpeed = math.sign(currentSpeed)
                    spec.cruiseControl.speedInterpolated = (targetSpeed == 1 and math.min or math.max)(spec.cruiseControl.speedInterpolated + dt * 0.0025 * math.max(1, (math.abs(currentSpeed))) * targetSpeed, axisForward)
                    axisForward = spec.cruiseControl.speedInterpolated
                end
            end
            local currentSpeed, targetSpeed = self:getSpeedLimit(true)
            local speedDifference = math.min(currentSpeed, axisForward)
            if spec.idleTurningAllowed and spec.idleTurningActive then
                speedDifference = math.min(speedDifference, spec.idleTurningMaxSpeed)
            end
            self:getMotor():setSpeedLimit(speedDifference)
            self:updateVehiclePhysics(spec.axisForward, spec.axisSide, spec.doHandbrake, dt)
        elseif spec.lastIsControlled then
            SpecializationUtil.raiseEvent(self, "onVehiclePhysicsUpdate", 0, 0, true, 0)
        end
    end
    if self.isClient and lastSpeed then
        local axisForward = true
        if spec.idleTurningAllowed and (spec.idleTurningActive and not spec.idleTurningUpdateSteeringWheel) then
            axisForward = false
        end
        if axisForward then
            self:updateSteeringWheel(spec.steeringWheel, dt, 1)
        end
    end
    spec.lastIsControlled = lastSpeed
    if self:getIsActiveForInput(true) and (g_inputBinding:getInputHelpMode() ~= GS_INPUT_HELP_MODE_GAMEPAD or GS_PLATFORM_SWITCH) and g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING) then
        local currentSpeed, targetSpeed, speedDifference = getGravityDirection()
        self:setSteeringInput(MathUtil.getSteeringAngleFromDeviceGravity(currentSpeed, targetSpeed, speedDifference), true, InputDevice.CATEGORY.WHEEL)
    end
    spec.odometerMilage = spec.odometerMilage + self.lastMovedDistance * 0.001
end
function Drivable:onDraw()
    local spec = self.spec_drivable
    if spec.hudExtension ~= nil and (self.getIsControlled ~= nil and self:getIsControlled()) then
        g_currentMission.hud:addHelpExtension(spec.hudExtension)
    end
end
function Drivable:setCruiseControlState(state, noEventSend)
    local spec = self.spec_drivable
    if spec.cruiseControl ~= nil and spec.cruiseControl.state ~= state then
        spec.cruiseControl.state = state
        if noEventSend == nil or not noEventSend then
            if self.isServer then
                local ownerConnection = self:getOwnerConnection()
                if ownerConnection ~= nil then
                    ownerConnection:sendEvent(SetCruiseControlStateEvent.new(self, state))
                end
            else
                g_client:getServerConnection():sendEvent(SetCruiseControlStateEvent.new(self, state))
            end
        end
        if spec.toggleCruiseControlEvent ~= nil then
            local ownerConnection
            if state == Drivable.CRUISECONTROL_STATE_ACTIVE then
                ownerConnection = g_i18n:getText("action_deactivateCruiseControl")
            else
                ownerConnection = g_i18n:getText("action_activateCruiseControl")
            end
            g_inputBinding:setActionEventText(spec.toggleCruiseControlEvent, ownerConnection)
        end
    end
end
function Drivable:setCruiseControlMaxSpeed(speed, speedReverse)
    if speed ~= nil then
        local speedLimit = math.clamp(speed, self.spec_drivable.cruiseControl.minSpeed, spec.cruiseControl.maxSpeed)
        if spec.cruiseControl.speed ~= speedLimit then
            spec.cruiseControl.speed = speedLimit
            if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_FULL then
                spec.cruiseControl.state = Drivable.CRUISECONTROL_STATE_ACTIVE
            end
        end
        if speedReverse ~= nil then
            speedReverse = math.clamp(speedReverse, spec.cruiseControl.minSpeed, spec.cruiseControl.maxSpeedReverse)
            spec.cruiseControl.speedReverse = speedReverse
        end
        if spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
            if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
                local speedLimit, _ = self:getSpeedLimit(true)
                local speedLimit = math.min(speedLimit, spec.cruiseControl.speed)
                self:getMotor():setSpeedLimit(speedLimit)
            else
                self:getMotor():setSpeedLimit(math.huge)
            end
        end
        if self:getDrivingDirection() < 0 then
            local speedLimit, _ = self:getSpeedLimit(true)
            local speedLimit = math.min(speedLimit, spec.cruiseControl.speedReverse)
            self:getMotor():setSpeedLimit(speedLimit)
        end
        SpecializationUtil.raiseEvent(self, "onCruiseControlSpeedChanged", speedLimit, speedReverse)
    end
end
function Drivable:updateSteeringWheel(steeringWheel, _, direction)
    if steeringWheel ~= nil then
        local maxRotation = steeringWheel.outdoorRotation
        if g_localPlayer:getCurrentVehicle() == self and self.getActiveCamera ~= nil then
            local activeCamera = self:getActiveCamera()
            if activeCamera ~= nil and (activeCamera.isInside and not activeCamera.isPassengerCamera) then
                maxRotation = steeringWheel.indoorRotation
            end
        end
        local activeCamera = self.rotatedTime * maxRotation
        if steeringWheel.lastRotation ~= activeCamera then
            steeringWheel.lastRotation = activeCamera
            setRotation(steeringWheel.node, 0, activeCamera * direction, 0)
            if self.getVehicleCharacter ~= nil then
                local vehicleCharacter = self:getVehicleCharacter()
                if vehicleCharacter ~= nil and vehicleCharacter:getAllowCharacterUpdate() then
                    vehicleCharacter:setDirty(true)
                end
            end
        end
    end
end
function Drivable:getCruiseControlState()
    return self.spec_drivable.cruiseControl.state
end
function Drivable:getCruiseControlSpeed()
    local spec = self.spec_drivable
    if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_FULL then
        return spec.cruiseControl.maxSpeed
    else
        return spec.cruiseControl.speed
    end
end
function Drivable:getCruiseControlMaxSpeed()
    return self.spec_drivable.cruiseControl.maxSpeed
end
function Drivable:getCruiseControlDisplayInfo()
    local isActive = true
    local cruiseControl = self.spec_drivable.cruiseControl
    local cruiseControlSpeed
    if self:getReverserDirection() < 0 then
        cruiseControlSpeed = cruiseControl.speedReverse
    else
        cruiseControlSpeed = cruiseControl.speed
    end
    if cruiseControl.state == Drivable.CRUISECONTROL_STATE_FULL then
        cruiseControlSpeed = cruiseControl.maxSpeed
    elseif cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF then
        isActive = false
    end
    if self:getDrivingDirection() < 0 then
        if self:getReverserDirection() < 0 then
            return cruiseControl.speed, isActive
        end
        cruiseControlSpeed = cruiseControl.speedReverse
    end
    return cruiseControlSpeed, isActive
end
function Drivable:getAxisForward()
    return self.spec_drivable.axisForward
end
function Drivable:getAccelerationAxis()
    return math.max(self.spec_drivable.axisForward * (self.movingDirection > -1 and 1 or -1) * self:getReverserDirection(), 0)
end
g_soundManager:registerModifierType("ACCELERATE", Drivable.getAccelerationAxis)
function Drivable:getDecelerationAxis()
    if self.lastSpeedReal > 0.0001 then
        if self.movingDirection == math.sign(self.spec_drivable.axisForward) or self.lastSpeedReal > 0.002 then
            return math.abs((math.min(self.spec_drivable.axisForward * self.movingDirection * self:getReverserDirection(), 0)))
        end
    end
    return 0
end
g_soundManager:registerModifierType("DECELERATE", Drivable.getDecelerationAxis)
function Drivable:getCruiseControlAxis()
    return self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF and 0 or 1
end
g_soundManager:registerModifierType("CRUISECONTROL", Drivable.getCruiseControlAxis)
function Drivable:getAcDecelerationAxis()
    return self.spec_drivable.axisForward * self:getReverserDirection()
end
function Drivable:getDashboardSteeringAxis()
    local spec = self.spec_drivable
    if spec.idleTurningAllowed and spec.idleTurningActive then
        return not spec.idleTurningUpdateSteeringWheel and 0 or self.rotatedTime / self.maxRotTime * self:getReverserDirection() * spec.idleTurningDirection * spec.axisForward
    else
        return self.rotatedTime / self.maxRotTime * self:getReverserDirection()
    end
end
function Drivable:getDashboardCombinedPedalLeft()
    local value = self:getAcDecelerationAxis()
    local spec = self.spec_drivable
    if spec.idleTurningAllowed and spec.idleTurningActive then
        return value * spec.idleTurningDirection
    end
    return math.clamp(value - self:getDashboardSteeringAxis(), -1, 1)
end
function Drivable:getDashboardCombinedPedalRight()
    local value = self:getAcDecelerationAxis()
    local spec = self.spec_drivable
    if spec.idleTurningAllowed and spec.idleTurningActive then
        return -value * spec.idleTurningDirection
    end
    return math.clamp(value + self:getDashboardSteeringAxis(), -1, 1)
end
function Drivable:setReverserDirection(reverserDirection)
    self.spec_drivable.reverserDirection = reverserDirection
end
function Drivable:getReverserDirection()
    return self.spec_drivable.reverserDirection
end
function Drivable:getSteeringDirection()
    return self.spec_drivable.steeringDirection
end
function Drivable:getIsDrivingForward()
    return self:getDrivingDirection() >= 0
end
function Drivable:getIsDrivingBackward()
    return self:getDrivingDirection() < 0
end
function Drivable:getDrivingDirection()
    local lastSpeed = self:getLastSpeed()
    return lastSpeed < 0.2 and 0 or (lastSpeed < 1.5 and self.spec_drivable.axisForward == 0 and 0 or self.movingDirection * self:getReverserDirection())
end
g_soundManager:registerModifierType("DRIVING_DIRECTION", Drivable.getDrivingDirection)
function Drivable:getIsVehicleControlledByPlayer()
    return true
end
function Drivable:getIsPlayerVehicleControlAllowed()
    local spec = self.spec_drivable
    if spec.hasPlayerControlAllowedFunctions then
        for objectId, func in pairs(spec.playerControlAllowedFunctions) do
            local vehicle = NetworkUtil.getObject(objectId)
            if vehicle == nil or vehicle.rootVehicle ~= self then
                spec.playerControlAllowedFunctions[objectId] = nil
                local isAllowed = table.size(spec.playerControlAllowedFunctions) > 0
                spec.hasPlayerControlAllowedFunctions = isAllowed
            else
                local isAllowed, warning = func(vehicle)
                if not isAllowed then
                    return isAllowed, warning
                end
            end
        end
    end
    return true, nil
end
function Drivable:registerPlayerVehicleControlAllowedFunction(vehicle, func)
    local objectId = NetworkUtil.getObjectId(vehicle)
    if objectId ~= nil and func ~= nil then
        local spec = self.spec_drivable
        spec.playerControlAllowedFunctions[objectId] = func
        spec.hasPlayerControlAllowedFunctions = table.size(spec.playerControlAllowedFunctions) > 0
    end
end
function Drivable:stopMotor(_)
    self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
end
function Drivable:onRegisterActionEvents(_, _)
    if self.isClient then
        local spec = self.spec_drivable
        spec.toggleCruiseControlEvent = nil
        self:clearActionEventsTable(spec.actionEvents)
        local entered = true
        if self.getIsEntered ~= nil then
            entered = self:getIsEntered()
        end
        if self:getIsActiveForInput(true, true) and entered then
            if not self:getIsAIActive() then
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_ACCELERATE_VEHICLE, self, Drivable.actionEventAccelerate, false, false, true, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_BRAKE_VEHICLE, self, Drivable.actionEventBrake, false, false, true, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.AXIS_MOVE_SIDE_VEHICLE, self, Drivable.actionEventSteer, false, false, true, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_steer"))
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CRUISE_CONTROL, self, Drivable.actionEventCruiseControlState, false, true, true, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
                spec.toggleCruiseControlEvent = actionEventId
            end
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_CRUISE_CONTROL, self, Drivable.actionEventCruiseControlValue, false, true, true, true, nil)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_changeCruiseControlLevel"))
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
        end
    end
end
function Drivable:onLeaveVehicle(wasEntered)
    self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
    if self.brake ~= nil then
        self:brake(1)
    end
    if wasEntered then
        local forceFeedback = self.spec_drivable.forceFeedback
        if forceFeedback.isActive then
            forceFeedback.device:setForceFeedback(forceFeedback.axisIndex, 0, 0)
            forceFeedback.isActive = false
            forceFeedback.device = nil
        end
    end
end
function Drivable:onSetBroken()
    if self.isClient then
        g_soundManager:playSample(self.spec_drivable.samples.waterSplash)
    end
end
function Drivable:updateVehiclePhysics(axisForward, axisSide, doHandbrake, dt)
    axisSide = self:getSteeringDirection() * axisSide
    if self:getIsMotorStarted() then
        if math.abs(axisForward) > 0 then
            self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
        end
        axisForward = self.spec_drivable.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF and 1 or axisForward
    elseif self:getIsManualDirectionChangeActive() then
        if axisForward >= 0 then
            axisForward = 0
        end
    elseif self.movingDirection == 0 then
        axisForward = acceleration
    elseif math.sign(axisForward) == self.movingDirection then
        axisForward = acceleration
    end
    if not self:getCanMotorRun() then
        axisForward = math.min(axisForward, 0)
        if self:getIsMotorStarted() then
            self:stopMotor()
        end
    end
    if self.getIsControlled ~= nil and self:getIsControlled() then
        local targetRotatedTime = 0
        if self.maxRotTime ~= nil and self.minRotTime ~= nil then
            if axisSide < 0 then
                targetRotatedTime = math.min(-self.maxRotTime * axisSide, self.maxRotTime)
            else
                targetRotatedTime = math.max(self.minRotTime * axisSide, self.minRotTime)
            end
        end
        self.rotatedTime = targetRotatedTime
    end
    if self.finishedFirstUpdate and (self.spec_wheels ~= nil and #self.spec_wheels.wheels > 0) then
        if spec.initialWheelPhysicsUpdate then
            dt = 99999
            spec.initialWheelPhysicsUpdate = false
        end
        WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, axisForward, doHandbrake, g_currentMission.missionInfo.stopAndGoBraking)
    end
    return axisForward
end
function Drivable:setAccelerationPedalInput(inputValue)
    local spec = self.spec_drivable
    spec.lastInputValues.axisAccelerate = math.clamp(inputValue, 0, 1)
    if spec.lastInputValues.targetSpeed ~= nil then
        spec.lastInputValues.targetSpeed = nil
        spec.lastInputValues.targetDirection = nil
    end
end
function Drivable:setBrakePedalInput(inputValue)
    local spec = self.spec_drivable
    spec.lastInputValues.axisBrake = math.clamp(inputValue, 0, 1)
    if spec.lastInputValues.targetSpeed ~= nil then
        spec.lastInputValues.targetSpeed = nil
        spec.lastInputValues.targetDirection = nil
    end
end
function Drivable:setTargetSpeedAndDirection(speed, direction)
    local spec = self.spec_drivable
    if direction > 0 then
        speed = speed * self:getMotor():getMaximumForwardSpeed() * 3.6
    elseif direction < 0 then
        speed = speed * self:getMotor():getMaximumBackwardSpeed() * 3.6
    end
    spec.lastInputValues.targetSpeed = speed
    spec.lastInputValues.targetDirection = direction
end
function Drivable:setSteeringInput(inputValue, isAnalog, deviceCategory)
    local spec = self.spec_drivable
    spec.lastInputValues.axisSteer = inputValue
    if inputValue ~= 0 then
        spec.lastInputValues.axisSteerIsAnalog = isAnalog
        spec.lastInputValues.axisSteerDeviceCategory = deviceCategory
    end
end
function Drivable:brakeToStop()
    self.spec_drivable.brakeToStop = true
end
function Drivable:updateSteeringAngle(wheel, _, steeringAngle)
    local spec = self.spec_drivable
    if spec.idleTurningAllowed then
        local i = 1
        for i = i, #spec.idleTurningWheels do
            local wheelData = spec.idleTurningWheels[i]
            if wheel.repr == wheelData.wheelNode or wheel.driveNode == wheelData.wheelNode then
                local idleTurnAngle = wheelData.steeringAngle
                if wheelData.inverted then
                    idleTurnAngle = wheelData.steeringAngle + 3.141592653589793
                end
                if spec.idleTurningActive then
                end
                return steeringAngle
            end
        end
    end
    return steeringAngle
end
function Drivable:getIsManualDirectionChangeAllowed(superFunc)
    local spec = self.spec_drivable
    if spec.idleTurningAllowed and spec.idleTurningActive then
        return false
    else
        return superFunc(self)
    end
end
function Drivable:getMapHotspotRotation(superFunc, isPlayerHotspot)
    if self:getReverserDirection() < 0 then
        return superFunc(self, isPlayerHotspot) + 3.141592653589793
    else
        return superFunc(self, isPlayerHotspot)
    end
end
function Drivable:setTransmissionDirection(superFunc, direction)
    superFunc(self, direction)
    local spec = self.spec_drivable
    if direction ~= spec.cruiseControl.transmissionDirection then
        spec.cruiseControl.maxSpeed = spec.cruiseControl.maxSpeedReverse
        spec.cruiseControl.maxSpeedReverse = spec.cruiseControl.maxSpeed
        self:setCruiseControlMaxSpeed(spec.cruiseControl.speedReverse, spec.cruiseControl.speed)
        spec.cruiseControl.transmissionDirection = direction
    end
end
function Drivable:actionEventAccelerate(_, inputValue, _, _)
    if inputValue ~= 0 then
        local isPowered, isPoweredWarning = self:getIsPowered()
        if not isPowered and isPoweredWarning ~= nil then
            g_currentMission:showBlinkingWarning(isPoweredWarning, 2000)
        end
        local isAllowed, warning = self:getIsPlayerVehicleControlAllowed()
        if isAllowed then
            self:setAccelerationPedalInput(inputValue)
            return
        end
        if warning ~= nil then
            g_currentMission:showBlinkingWarning(warning, 2000)
        end
    end
end
function Drivable:actionEventBrake(_, inputValue, _, _)
    if inputValue ~= 0 then
        local isPowered, isPoweredWarning = self:getIsPowered()
        if not isPowered and isPoweredWarning ~= nil then
            g_currentMission:showBlinkingWarning(isPoweredWarning, 2000)
        end
        local isAllowed, warning = self:getIsPlayerVehicleControlAllowed()
        if isAllowed then
            self:setBrakePedalInput(inputValue)
            return
        end
        if warning ~= nil then
            g_currentMission:showBlinkingWarning(warning, 2000)
        end
    end
end
function Drivable:actionEventSteer(_, inputValue, _, isAnalog, _, deviceCategory, binding)
    local spec = self.spec_drivable
    if spec.forceFeedback.isActive then
        if binding ~= spec.forceFeedback.binding then
            local isSupported, device, axisIndex = g_inputBinding:getBindingForceFeedbackInfo(binding)
            if not isSupported then
                spec.forceFeedback.isActive = false
                spec.forceFeedback.device = nil
                spec.forceFeedback.binding = nil
                spec.forceFeedback.axisIndex = 0
            end
        end
    else
        local isSupported, device, axisIndex = g_inputBinding:getBindingForceFeedbackInfo(binding)
        spec.forceFeedback.isActive = isSupported
        spec.forceFeedback.device = device
        spec.forceFeedback.binding = binding
        spec.forceFeedback.axisIndex = axisIndex
        if isSupported then
            device:setForceFeedback(axisIndex, 0, inputValue)
        end
    end
    if inputValue ~= 0 then
        local isSupported, device = self:getIsPlayerVehicleControlAllowed()
        if isSupported then
            self:setSteeringInput(inputValue, isAnalog, deviceCategory)
            return
        end
        if device ~= nil then
            g_currentMission:showBlinkingWarning(device, 2000)
        end
    end
end
function Drivable:actionEventCruiseControlState(_, _, _, _)
    local isAllowed, warning = self:getIsPlayerVehicleControlAllowed()
    if isAllowed then
        self.spec_drivable.lastInputValues.cruiseControlState = 1
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
    end
end
function Drivable:actionEventCruiseControlValue(_, inputValue, _, _)
    self.spec_drivable.lastInputValues.cruiseControlValue = inputValue
end