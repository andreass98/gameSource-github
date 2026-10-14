source("dataS/scripts/vehicles/specializations/events/MotorClutchCreakingEvent.lua")
source("dataS/scripts/vehicles/specializations/events/MotorSetTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/events/MotorGearShiftEvent.lua")
source("dataS/scripts/vehicles/specializations/events/MotorStateEvent.lua")
source("dataS/scripts/vehicles/specializations/enums/MotorState.lua")
Motorized = {}
Motorized.DAMAGED_USAGE_INCREASE = 0.3
function Motorized.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("motor", g_i18n:getText("configuration_motorSetup"), "motorized", VehicleConfigurationItemMotor, nil, nil, nil, 1)
    g_storeManager:addSpecType("fuel", "shopListAttributeIconFuel", Motorized.loadSpecValueFuel, Motorized.getSpecValueFuelDiesel, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("electricCharge", "shopListAttributeIconElectricCharge", Motorized.loadSpecValueFuel, Motorized.getSpecValueFuelElectricCharge, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("methane", "shopListAttributeIconMethane", Motorized.loadSpecValueFuel, Motorized.getSpecValueFuelMethane, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("maxSpeed", "shopListAttributeIconMaxSpeed", Motorized.loadSpecValueMaxSpeed, Motorized.getSpecValueMaxSpeed, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("power", "shopListAttributeIconPower", Motorized.loadSpecValuePower, Motorized.getSpecValuePower, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("powerConfig", "shopListAttributeIconPower", Motorized.loadSpecValuePowerConfig, Motorized.getSpecValuePowerConfig, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("transmission", "shopListAttributeIconTransmission", Motorized.loadSpecValueTransmission, Motorized.getSpecValueTransmission, StoreSpecies.VEHICLE)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Motorized")
    Motorized.registerDifferentialXMLPaths(schema, "vehicle.motorized.differentialConfigurations.differentialConfiguration(?)")
    Motorized.registerDifferentialXMLPaths(schema, "vehicle.motorized.differentials")
    Motorized.registerMotorXMLPaths(schema, "vehicle.motorized.motorConfigurations.motorConfiguration(?)")
    Motorized.registerConsumerXMLPaths(schema, "vehicle.motorized.consumerConfigurations.consumerConfiguration(?)")
    Motorized.registerConsumerXMLPaths(schema, "vehicle.motorized.consumers")
    Motorized.registerSoundXMLPaths(schema, "vehicle.motorized.sounds")
    Motorized.registerSoundXMLPaths(schema, "vehicle.motorized.motorConfigurations.motorConfiguration(?).sounds")
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.reverseDriveSound#threshold", "Reverse drive sound turn on speed threshold", 4)
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.brakeCompressor#capacity", "Brake compressor capacity", 6)
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.brakeCompressor#refillFillLevel", "Brake compressor refill threshold", "half of capacity")
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.brakeCompressor#fillSpeed", "Brake compressor fill speed", 0.6)
    ParticleUtil.registerParticleXMLPaths(schema, "vehicle.motorized.exhaustParticleSystems", "exhaustParticleSystem(?)")
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustParticleSystems#minScale", "Min. scale", 0.5)
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustParticleSystems#maxScale", "Max. scale", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.motorized.exhaustFlap(?)#node", "Exhaust Flap Node")
    schema:register(XMLValueType.ANGLE, "vehicle.motorized.exhaustFlap(?)#maxRot", "Max. rotation", 0)
    schema:register(XMLValueType.INT, "vehicle.motorized.exhaustFlap(?)#rotationAxis", "Rotation Axis", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#node", "Effect link node")
    schema:register(XMLValueType.STRING, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#filename", "Effect i3d filename")
    schema:register(XMLValueType.VECTOR_4, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#minRpmColor", "Min. rpm color", "0 0 0 1")
    schema:register(XMLValueType.VECTOR_4, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#maxRpmColor", "Max. rpm color", "0.0384 0.0359 0.0627 2.0")
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#minRpmScale", "Min. rpm scale", 0.25)
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#maxRpmScale", "Max. rpm scale", 0.95)
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#upFactor", "Defines how far the effect goes up in the air in meter", 0.75)
    EffectManager.registerEffectXMLPaths(schema, "vehicle.motorized.effects")
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.motorStartDuration", "Motor start duration", "Duration motor takes to start. After this time player can start to drive")
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.brakeForce#force", "Brake force when vehicle is empty", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.brakeForce#maxForce", "Brake force when vehicle reached mass of #maxForceMass", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.motorized.brakeForce#maxForceMass", "When this mass is reached the vehicle will brake with #maxForce", 0)
    schema:register(XMLValueType.BOOL, "vehicle.motorized.brakeForce#includeAttachables", "Defines if the mass of the attached vehicles is included in the calculations", false)
    schema:register(XMLValueType.L10N_STRING, "vehicle.motorized#clutchNoEngagedWarning", "Warning to be displayed if try to start the engine but clutch not engaged", "warning_motorClutchNoEngaged")
    schema:register(XMLValueType.L10N_STRING, "vehicle.motorized#clutchCrackingGearWarning", "Warning to be display if user tries to select a gear without pressing clutch pedal", "action_clutchCrackingGear")
    schema:register(XMLValueType.L10N_STRING, "vehicle.motorized#clutchCrackingGroupWarning", "Warning to be display if user tries to select a gear without pressing clutch pedal", "action_clutchCrackingGroup")
    schema:register(XMLValueType.L10N_STRING, "vehicle.motorized#turnOnText", "Motor start text", "action_startMotor")
    schema:register(XMLValueType.L10N_STRING, "vehicle.motorized#turnOffText", "Motor stop text", "action_stopMotor")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.motorized.gearLevers.gearLever(?)#node", "Gear lever node")
    schema:register(XMLValueType.INT, "vehicle.motorized.gearLevers.gearLever(?)#centerAxis", "Axis of center bay")
    schema:register(XMLValueType.TIME, "vehicle.motorized.gearLevers.gearLever(?)#changeTime", "Time to move lever from one state to another", 0.5)
    schema:register(XMLValueType.TIME, "vehicle.motorized.gearLevers.gearLever(?)#handsOnDelay", "The animation is delayed by this time to have time to put the hand on the lever", 0)
    schema:register(XMLValueType.INT, "vehicle.motorized.gearLevers.gearLever(?).state(?)#gear", "Gear index")
    schema:register(XMLValueType.INT, "vehicle.motorized.gearLevers.gearLever(?).state(?)#group", "Group index")
    schema:register(XMLValueType.ANGLE, "vehicle.motorized.gearLevers.gearLever(?).state(?)#xRot", "X rotation")
    schema:register(XMLValueType.ANGLE, "vehicle.motorized.gearLevers.gearLever(?).state(?)#yRot", "Y rotation")
    schema:register(XMLValueType.ANGLE, "vehicle.motorized.gearLevers.gearLever(?).state(?)#zRot", "Z rotation")
    schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.power", "Power")
    schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.maxSpeed", "Max speed")
    schema:register(XMLValueType.STRING, "vehicle.motorized#statsType", "Statistic type", "tractor")
    schema:register(XMLValueType.BOOL, "vehicle.motorized#forceSpeedHudDisplay", "Force usage of vehicle speed display in hud independent of setting", false)
    schema:register(XMLValueType.BOOL, "vehicle.motorized#forceRpmHudDisplay", "Force usage of motor speed display in hud independent of setting", false)
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.motorized.dashboards", {
        "rpm",
        "load",
        "speed",
        "speedDir",
        "fuelUsage",
        "motorTemperature",
        "motorTemperatureWarning",
        "clutchPedal",
        "gear",
        "gearGroup",
        "gearIndex",
        "gearGroupIndex",
        "gearShiftUp",
        "gearShiftDown",
        "gearShiftUpDown",
        "movingDirection",
        "directionForward",
        "directionForwardExclusive",
        "directionBackward",
        "directionNeutral",
        "movingDirectionLetter",
        "ignitionState",
        "battery"
    })
    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.motorized.animationNodes")
    schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isMotorStarting", "Is motor starting")
    schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isMotorRunning", "Is motor running")
    schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#electronicsStarting", "Electrical components starting (depending on defined \'electronicsStartingTime\')", false)
    schema:register(XMLValueType.TIME, Dashboard.GROUP_XML_KEY .. "#electronicsStartingTime", "Starting time of electric components", 2)
    schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#electronicsRunning", "Electrical components are started and running (depending on defined \'electronicsStartingTime\')", false)
    schema:setXMLSpecializationType()
end
function Motorized.registerMotorXMLPaths(schema, baseKey)
    schema:register(XMLValueType.STRING, baseKey .. ".motor#type", "Motor type", "vehicle")
    schema:register(XMLValueType.STRING, baseKey .. ".motor#startAnimationName", "Motor start animation", "vehicle")
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#minRpm", "Min. RPM", 1000)
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#maxRpm", "Max. RPM", 1800)
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#minSpeed", "Min. driving speed", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#maxForwardSpeed", "Max. forward speed")
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#maxBackwardSpeed", "Max. backward speed")
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#accelerationLimit", "Acceleration limit", 2)
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#brakeForce", "Brake force", 10)
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#lowBrakeForceScale", "Low brake force scale", 0.5)
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#lowBrakeForceSpeedLimit", "Low brake force speed limit (below this speed the lowBrakeForceScale is activated)", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#torqueScale", "Scale factor for torque curve", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#ptoMotorRpmRatio", "PTO to motor rpm ratio", 4)
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#minForwardGearRatio", "Min. forward gear ratio")
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#maxForwardGearRatio", "Max. forward gear ratio")
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#minBackwardGearRatio", "Min. backward gear ratio")
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#maxBackwardGearRatio", "Max. backward gear ratio")
    schema:register(XMLValueType.TIME, baseKey .. ".transmission#gearChangeTime", "Gear change time")
    schema:register(XMLValueType.TIME, baseKey .. ".transmission#autoGearChangeTime", "Auto gear change time")
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#axleRatio", "Axle ratio", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#startGearThreshold", "Adjusts which gear is used as start gear", VehicleMotor.GEAR_START_THRESHOLD)
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor.torque(?)#normRpm", "Norm RPM (0-1)")
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor.torque(?)#rpm", "RPM")
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor.torque(?)#torque", "Torque")
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#rotInertia", "Rotation inertia", "Peak. motor torque / 600")
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#dampingRateScale", "Scales motor damping rate", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. ".motor#rpmSpeedLimit", "Motor rotation acceleration limit")
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.forwardGear(?)#gearRatio", "Gear ratio")
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.forwardGear(?)#maxSpeed", "Gear ratio")
    schema:register(XMLValueType.BOOL, baseKey .. ".transmission.forwardGear(?)#defaultGear", "Gear ratio")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#name", "Gear name to display")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#reverseName", "Gear name to display (if reverse direction is active)")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#dashboardName", "Gear name to display in dashboard")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#dashboardReverseName", "Gear name to display in dashboard (if reverse direction is active)")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#actionName", "Input Action to select this gear", "SHIFT_GEAR_SELECT_X")
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.backwardGear(?)#gearRatio", "Gear ratio")
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.backwardGear(?)#maxSpeed", "Gear ratio")
    schema:register(XMLValueType.BOOL, baseKey .. ".transmission.backwardGear(?)#defaultGear", "Gear ratio")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#name", "Gear name to display")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#reverseName", "Gear name to display (if reverse direction is active)")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#dashboardName", "Gear name to display in dashboard")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#dashboardReverseName", "Gear name to display in dashboard (if reverse direction is active)")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#actionName", "Input Action to select this gear", "SHIFT_GEAR_SELECT_X")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.groups#type", "Type of groups (powershift/default)", "default")
    schema:register(XMLValueType.TIME, baseKey .. ".transmission.groups#changeTime", "Change time if default type", 0.5)
    schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.groups.group(?)#ratio", "Ratio while stage active")
    schema:register(XMLValueType.BOOL, baseKey .. ".transmission.groups.group(?)#isDefault", "Is default stage", false)
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.groups.group(?)#name", "Gear name to display")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.groups.group(?)#dashboardName", "Gear name to display in dashboard")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission.groups.group(?)#actionName", "Input Action to select this group", "SHIFT_GROUP_SELECT_X")
    schema:register(XMLValueType.BOOL, baseKey .. ".transmission.directionChange#useGroup", "Use group as reverse change", false)
    schema:register(XMLValueType.INT, baseKey .. ".transmission.directionChange#reverseGroupIndex", "Group will be activated while direction is changed", 1)
    schema:register(XMLValueType.BOOL, baseKey .. ".transmission.directionChange#useGear", "Use gear as reverse change", false)
    schema:register(XMLValueType.INT, baseKey .. ".transmission.directionChange#reverseGearIndex", "Gear will be activated while direction is changed", 1)
    schema:register(XMLValueType.TIME, baseKey .. ".transmission.directionChange#changeTime", "Direction change time", 0.5)
    schema:register(XMLValueType.BOOL, baseKey .. ".transmission.manualShift#gears", "Defines if gears can be shifted manually", true)
    schema:register(XMLValueType.BOOL, baseKey .. ".transmission.manualShift#groups", "Defines if groups can be shifted manually", true)
    schema:register(XMLValueType.L10N_STRING, baseKey .. ".transmission#name", "Name of transmission to display in the shop")
    schema:register(XMLValueType.STRING, baseKey .. ".transmission#param", "Parameter to insert in transmission name")
    schema:register(XMLValueType.FLOAT, baseKey .. ".motorStartDuration", "Motor start duration", "Duration motor takes to start. After this time player can start to drive")
end
function Motorized.registerDifferentialXMLPaths(schema, baseKey)
    schema:register(XMLValueType.FLOAT, baseKey .. ".differentials.differential(?)#torqueRatio", "Torque ratio", 0.5)
    schema:register(XMLValueType.FLOAT, baseKey .. ".differentials.differential(?)#maxSpeedRatio", "Max. speed ratio", 1.3)
    schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#wheelIndex1", "Wheel index 1")
    schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#wheelIndex2", "Wheel index 2")
    schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#differentialIndex1", "Differential index 1")
    schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#differentialIndex2", "Differential index 2")
end
function Motorized.registerConsumerXMLPaths(schema, baseKey)
    schema:register(XMLValueType.L10N_STRING, baseKey .. "#consumersEmptyWarning", "Consumers empty warning", "warning_motorFuelEmpty")
    schema:register(XMLValueType.INT, baseKey .. ".consumer(?)#fillUnitIndex", "Fill unit index", 1)
    schema:register(XMLValueType.STRING, baseKey .. ".consumer(?)#fillType", "Fill type name")
    schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#usage", "Usage in l/h", 1)
    schema:register(XMLValueType.BOOL, baseKey .. ".consumer(?)#permanentConsumption", "Do permanent consumption", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#refillLitersPerSecond", "Refill liters per second", 0)
    schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#refillCapacityPercentage", "Refill capacity percentage", 0)
    schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#capacity", "If defined the capacity of the fillUnit fill be overwritten with this value")
end
function Motorized.registerSoundXMLPaths(schema, baseKey)
    SoundManager.registerSampleXMLPaths(schema, baseKey, "motorStart")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "motorStop")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "gearbox(?)")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "clutchCracking")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "gearEngaged")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "gearDisengaged")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "gearLeverStart")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "gearLeverEnd")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "gearGroupLeverStart")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "gearGroupLeverEnd")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "gearRangeChange")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "gearGroupChange")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "blowOffValve")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "retarder")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "motor(?)")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "airCompressorStart")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "airCompressorStop")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "airCompressorRun")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "compressedAir")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "airRelease")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "reverseDrive")
    SoundManager.registerSampleXMLPaths(schema, baseKey, "brake")
end
function Motorized.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(VehicleSettings, specializations)
end
function Motorized.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onStartMotor")
    SpecializationUtil.registerEvent(vehicleType, "onStopMotor")
    SpecializationUtil.registerEvent(vehicleType, "onGearDirectionChanged")
    SpecializationUtil.registerEvent(vehicleType, "onGearChanged")
    SpecializationUtil.registerEvent(vehicleType, "onGearGroupChanged")
    SpecializationUtil.registerEvent(vehicleType, "onMotorBlowOffValveChanged")
    SpecializationUtil.registerEvent(vehicleType, "onClutchCreaking")
end
function Motorized.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadDifferentials", Motorized.loadDifferentials)
    SpecializationUtil.registerFunction(vehicleType, "loadMotor", Motorized.loadMotor)
    SpecializationUtil.registerFunction(vehicleType, "loadGears", Motorized.loadGears)
    SpecializationUtil.registerFunction(vehicleType, "loadGearGroups", Motorized.loadGearGroups)
    SpecializationUtil.registerFunction(vehicleType, "loadExhaustEffects", Motorized.loadExhaustEffects)
    SpecializationUtil.registerFunction(vehicleType, "onExhaustEffectI3DLoaded", Motorized.onExhaustEffectI3DLoaded)
    SpecializationUtil.registerFunction(vehicleType, "loadSounds", Motorized.loadSounds)
    SpecializationUtil.registerFunction(vehicleType, "loadConsumerConfiguration", Motorized.loadConsumerConfiguration)
    SpecializationUtil.registerFunction(vehicleType, "setMotorState", Motorized.setMotorState)
    SpecializationUtil.registerFunction(vehicleType, "getMotorState", Motorized.getMotorState)
    SpecializationUtil.registerFunction(vehicleType, "getIsMotorStarted", Motorized.getIsMotorStarted)
    SpecializationUtil.registerFunction(vehicleType, "getIsMotorInNeutral", Motorized.getIsMotorInNeutral)
    SpecializationUtil.registerFunction(vehicleType, "getCanMotorRun", Motorized.getCanMotorRun)
    SpecializationUtil.registerFunction(vehicleType, "getStopMotorOnLeave", Motorized.getStopMotorOnLeave)
    SpecializationUtil.registerFunction(vehicleType, "getMotorNotAllowedWarning", Motorized.getMotorNotAllowedWarning)
    SpecializationUtil.registerFunction(vehicleType, "startMotor", Motorized.startMotor)
    SpecializationUtil.registerFunction(vehicleType, "stopMotor", Motorized.stopMotor)
    SpecializationUtil.registerFunction(vehicleType, "updateMotorProperties", Motorized.updateMotorProperties)
    SpecializationUtil.registerFunction(vehicleType, "controlVehicle", Motorized.controlVehicle)
    SpecializationUtil.registerFunction(vehicleType, "updateConsumers", Motorized.updateConsumers)
    SpecializationUtil.registerFunction(vehicleType, "updateMotorTemperature", Motorized.updateMotorTemperature)
    SpecializationUtil.registerFunction(vehicleType, "getMotor", Motorized.getMotor)
    SpecializationUtil.registerFunction(vehicleType, "getMotorStartTime", Motorized.getMotorStartTime)
    SpecializationUtil.registerFunction(vehicleType, "getMotorType", Motorized.getMotorType)
    SpecializationUtil.registerFunction(vehicleType, "getMotorRpmPercentage", Motorized.getMotorRpmPercentage)
    SpecializationUtil.registerFunction(vehicleType, "getMotorRpmReal", Motorized.getMotorRpmReal)
    SpecializationUtil.registerFunction(vehicleType, "getMotorLoadPercentage", Motorized.getMotorLoadPercentage)
    SpecializationUtil.registerFunction(vehicleType, "getMotorBlowOffValveState", Motorized.getMotorBlowOffValveState)
    SpecializationUtil.registerFunction(vehicleType, "getMotorDifferentialSpeed", Motorized.getMotorDifferentialSpeed)
    SpecializationUtil.registerFunction(vehicleType, "getConsumerFillUnitIndex", Motorized.getConsumerFillUnitIndex)
    SpecializationUtil.registerFunction(vehicleType, "getAirConsumerUsage", Motorized.getAirConsumerUsage)
    SpecializationUtil.registerFunction(vehicleType, "getTraveledDistanceStatsActive", Motorized.getTraveledDistanceStatsActive)
    SpecializationUtil.registerFunction(vehicleType, "setGearLeversState", Motorized.setGearLeversState)
    SpecializationUtil.registerFunction(vehicleType, "generateShiftAnimation", Motorized.generateShiftAnimation)
    SpecializationUtil.registerFunction(vehicleType, "getGearInfoToDisplay", Motorized.getGearInfoToDisplay)
    SpecializationUtil.registerFunction(vehicleType, "setTransmissionDirection", Motorized.setTransmissionDirection)
    SpecializationUtil.registerFunction(vehicleType, "getDirectionChangeMode", Motorized.getDirectionChangeMode)
    SpecializationUtil.registerFunction(vehicleType, "getIsManualDirectionChangeAllowed", Motorized.getIsManualDirectionChangeAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getIsManualDirectionChangeActive", Motorized.getIsManualDirectionChangeActive)
    SpecializationUtil.registerFunction(vehicleType, "getGearShiftMode", Motorized.getGearShiftMode)
    SpecializationUtil.registerFunction(vehicleType, "stopVehicle", Motorized.stopVehicle)
end
function Motorized.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", Motorized.getBrakeForce)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Motorized.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Motorized.removeFromPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", Motorized.getIsOperating)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", Motorized.getDeactivateOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateLightsOnLeave", Motorized.getDeactivateLightsOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Motorized.loadDashboardGroupFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Motorized.getIsDashboardGroupActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActiveForInteriorLights", Motorized.getIsActiveForInteriorLights)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActiveForWipers", Motorized.getIsActiveForWipers)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUsageCausesDamage", Motorized.getUsageCausesDamage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getName", Motorized.getName)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Motorized.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowered", Motorized.getIsPowered)
end
function Motorized.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onGearDirectionChanged", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onGearChanged", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onGearGroupChanged", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onMotorBlowOffValveChanged", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onClutchCreaking", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onReverseDirectionChanged", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onVehicleSettingChanged", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onAIJobStarted", Motorized)
    SpecializationUtil.registerEventListener(vehicleType, "onAIJobFinished", Motorized)
end
function Motorized:onLoad(_)
    local spec = self.spec_motorized
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.motor.animationNodes.animationNode", "motor")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.differentialConfigurations", "vehicle.motorized.differentialConfigurations")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.motorConfigurations", "vehicle.motorized.motorConfigurations")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.maximalAirConsumptionPerFullStop", "vehicle.motorized.consumerConfigurations.consumerConfiguration.consumer(with fill type \'air\')#usage (is now in usage per second at full brake power)")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.rpm", "vehicle.motorized.dashboards.dashboard with valueType \'rpm\'")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.speed", "vehicle.motorized.dashboards.dashboard with valueType \'speed\'")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.fuelUsage", "vehicle.motorized.dashboards.dashboard with valueType \'fuelUsage\'")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.fuel", "fillUnit.dashboard with valueType \'fillLevel\'")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.motor", "vehicle.motorized.motorConfigurations.motorConfiguration(?).motor")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.transmission", "vehicle.motorized.motorConfigurations.motorConfiguration(?).transmission")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fuelCapacity", "vehicle.motorized.consumerConfigurations.consumerConfiguration.consumer#capacity")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.motorized.motorConfigurations.motorConfiguration(?).fuelCapacity", "vehicle.motorized.consumerConfigurations.consumerConfiguration.consumer#capacity")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle#consumerConfigurationIndex", "vehicle.motorized.motorConfigurations.motorConfiguration(?)#consumerConfigurationIndex\'")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.motorized.exhaustParticleSystems#count")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.motorized.exhaustParticleSystems.exhaustParticleSystem1", "vehicle.motorized.exhaustParticleSystems.exhaustParticleSystem")
    spec.motorizedNode = nil
    for _, component in pairs(self.components) do
        if component.motorized then
            spec.motorizedNode = component.node
            break
        end
    end
    spec.directionChangeMode = VehicleMotor.DIRECTION_CHANGE_MODE_AUTOMATIC
    spec.gearShiftMode = VehicleMotor.SHIFT_MODE_AUTOMATIC
    local configKey = string.format("vehicle.motorized.motorConfigurations.motorConfiguration(%d)", self.configurations.motor - 1)
    self:loadDifferentials(self.xmlFile, self.differentialIndex)
    self:loadMotor(self.xmlFile, self.configurations.motor)
    self:loadSounds(self.xmlFile, "vehicle.motorized.sounds")
    if self.xmlFile:hasProperty(configKey) then
        self:loadSounds(self.xmlFile, configKey .. ".sounds")
    end
    self:loadConsumerConfiguration(self.xmlFile, spec.consumerConfigurationIndex)
    if self.isClient then
        self:loadExhaustEffects(self.xmlFile)
    end
    spec.gearLevers = {}
    spec.activeGearLeverInterpolators = {}
    self.xmlFile:iterate("vehicle.motorized.gearLevers.gearLever", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {
            ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if entry.node == nil then
            Logging.xmlWarning(self.xmlFile, "Unable to load gear lever. Missing node! \'%s\'", key)
        else
            entry.centerAxis = self.xmlFile:getValue(key .. "#centerAxis")
            entry.changeTime = self.xmlFile:getValue(key .. "#changeTime", 500)
            entry.handsOnDelay = self.xmlFile:getValue(key .. "#handsOnDelay", 0)
            entry.curTarget = { getRotation(entry.node) }
            entry.states = {}
            self.xmlFile:iterate(key .. ".state", function(_, stateKey)
                -- upvalues: (ref) self, (copy) entry
                local state = {
                    ["gear"] = self.xmlFile:getValue(stateKey .. "#gear"),
                    ["group"] = self.xmlFile:getValue(stateKey .. "#group")
                }
                if state.gear == nil and state.group == nil then
                    Logging.xmlWarning(self.xmlFile, "Unable to load gear lever state. Missing gear or group! \'%s\'", stateKey)
                else
                    state.node = entry.node
                    state.gearLever = entry
                    local x, y, z = getRotation(entry.node)
                    local xRot = self.xmlFile:getValue(stateKey .. "#xRot", x)
                    local yRot = self.xmlFile:getValue(stateKey .. "#yRot", y)
                    local zRot = self.xmlFile:getValue(stateKey .. "#zRot", z)
                    state.rotation = { xRot, yRot, zRot }
                    state.useRotation = { self.xmlFile:getValue(stateKey .. "#xRot") ~= nil, self.xmlFile:getValue(stateKey .. "#yRot") ~= nil, self.xmlFile:getValue(stateKey .. "#zRot") ~= nil }
                    state.curRotation = { xRot, yRot, zRot }
                    table.insert(entry.states, state)
                end
            end)
            table.insert(spec.gearLevers, entry)
        end
    end)
    spec.stopMotorOnLeave = true
    spec.motorStartDuration = 0
    if spec.samples ~= nil and spec.samples.motorStart ~= nil then
        spec.motorStartDuration = spec.samples.motorStart.duration
    end
    if spec.motorSamples ~= nil then
        local maxDuration = 0
        for _, sample in ipairs(spec.motorSamples) do
            maxDuration = math.max(maxDuration, g_soundManager:getSampleLoopSynthesisStartDuration(sample))
        end
        if maxDuration ~= 0 then
            spec.motorStartDuration = maxDuration
        end
    end
    spec.motorStartDuration = self.xmlFile:getValue("vehicle.motorized.motorStartDuration", spec.motorStartDuration) or 0
    if self.xmlFile:hasProperty(configKey) then
        spec.motorStartDuration = self.xmlFile:getValue(configKey .. ".motorStartDuration", spec.motorStartDuration)
    end
    spec.minBrakeForce = self.xmlFile:getValue("vehicle.motorized.brakeForce#force", 0) * 2
    spec.maxBrakeForce = self.xmlFile:getValue("vehicle.motorized.brakeForce#maxForce", 0) * 2
    spec.maxBrakeForceMass = self.xmlFile:getValue("vehicle.motorized.brakeForce#maxForceMass", 0) / 1000
    spec.maxBrakeForceMassIncludeAttachables = self.xmlFile:getValue("vehicle.motorized.brakeForce#includeAttachables", false)
    spec.clutchNoEngagedWarning = self.xmlFile:getValue("vehicle.motorized#clutchNoEngagedWarning", "warning_motorClutchNoEngaged", self.customEnvironment)
    spec.clutchCrackingGearWarning = self.xmlFile:getValue("vehicle.motorized#clutchCrackingGearWarning", "action_clutchCrackingGear", self.customEnvironment)
    spec.clutchCrackingGroupWarning = self.xmlFile:getValue("vehicle.motorized#clutchCrackingGroupWarning", "action_clutchCrackingGroup", self.customEnvironment)
    spec.turnOnText = self.xmlFile:getValue("vehicle.motorized#turnOnText", "action_startMotor", self.customEnvironment)
    spec.turnOffText = self.xmlFile:getValue("vehicle.motorized#turnOffText", "action_stopMotor", self.customEnvironment)
    spec.speedDisplayScale = 1
    spec.motorStartTime = 0
    spec.actualLoadPercentage = 0
    spec.smoothedLoadPercentage = 0
    spec.maxDecelerationDuringBrake = 0
    spec.blowOffValveState = 0
    spec.lastControlParameters = {
        ["acceleratorPedal"] = nil,
        ["maxSpeed"] = nil,
        ["maxAcceleration"] = nil,
        ["minMotorRotSpeed"] = nil,
        ["maxMotorRotSpeed"] = nil,
        ["maxMotorRotAcceleration"] = nil,
        ["minGearRatio"] = nil,
        ["maxGearRatio"] = nil,
        ["maxClutchTorque"] = nil,
        ["neededPtoTorque"] = nil
    }
    spec.clutchCrackingTimeOut = math.huge
    spec.clutchState = 0
    spec.clutchStateSent = 0
    spec.motorState = MotorState.OFF
    spec.motorStopTimerDuration = g_gameSettings:getValue(GameSettings.SETTING.MOTOR_STOP_TIMER_DURATION)
    spec.motorStopTimer = spec.motorStopTimerDuration
    spec.motorNotRequiredTimer = 0
    spec.motorStateIgnitionTime = 0
    spec.motorTemperature = {}
    spec.motorTemperature.value = 20
    spec.motorTemperature.valueSend = 20
    spec.motorTemperature.valueMax = 120
    spec.motorTemperature.valueMin = 20
    spec.motorTemperature.heatingPerMS = 0.0015
    spec.motorTemperature.coolingByWindPerMS = 0.001
    spec.motorFan = {}
    spec.motorFan.enabled = false
    spec.motorFan.enableTemperature = 95
    spec.motorFan.disableTemperature = 85
    spec.motorFan.coolingPerMS = 0.003
    spec.lastFuelUsage = 0
    spec.lastFuelUsageDisplay = 0
    spec.lastFuelUsageDisplayTime = 0
    spec.fuelUsageBuffer = ValueBuffer.new(250)
    spec.lastDefUsage = 0
    spec.lastAirUsage = 0
    spec.lastVehicleDamage = 0
    spec.forceSpeedHudDisplay = self.xmlFile:getValue("vehicle.motorized#forceSpeedHudDisplay", false)
    spec.forceRpmHudDisplay = self.xmlFile:getValue("vehicle.motorized#forceRpmHudDisplay", false)
    spec.statsType = string.lower(self.xmlFile:getValue("vehicle.motorized#statsType", "tractor"))
    if spec.statsType ~= "tractor" and (spec.statsType ~= "car" and spec.statsType ~= "truck") then
        spec.statsType = "tractor"
    end
    spec.statsTypeDistance = spec.statsType .. "Distance"
    spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.motorized.animationNodes", self.components, self, self.i3dMappings)
    spec.traveledDistanceBuffer = 0
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.inputDirtyFlag = self:getNextDirtyFlag()
    self:registerVehicleSetting(GameSettings.SETTING.DIRECTION_CHANGE_MODE, false)
    self:registerVehicleSetting(GameSettings.SETTING.GEAR_SHIFT_MODE, false)
end
function Motorized:onPostLoad(savegame)
    local spec = self.spec_motorized
    if self.isServer then
        local moneyChange = 0
        for _, consumer in pairs(spec.consumersByFillTypeName) do
            local fillLevel = self:getFillUnitFillLevel(consumer.fillUnitIndex)
            local minFillLevel = self:getFillUnitCapacity(consumer.fillUnitIndex) * 0.1
            if fillLevel < minFillLevel then
                local fillLevelToFill = minFillLevel - fillLevel
                self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, fillLevelToFill, consumer.fillType, ToolType.UNDEFINED)
                local costs = fillLevelToFill * g_currentMission.economyManager:getCostPerLiter(consumer.fillType) * 2
                g_farmManager:updateFarmStats(self:getOwnerFarmId(), "expenses", costs)
                g_currentMission:addMoney(-costs, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, false, false)
            end
        end
        if moneyChange > 0 then
            g_currentMission:addMoneyChange(-moneyChange, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, true)
        end
    end
    spec.propellantFillUnitIndices = {}
    for _, _ in pairs({
        FillType.DIESEL,
        FillType.DEF,
        FillType.ELECTRICCHARGE,
        FillType.METHANE
    }) do
        local consumer = g_fillTypeManager:getFillTypeNameByIndex(_)
        if spec.consumersByFillTypeName[consumer] ~= nil then
            table.insert(spec.propellantFillUnitIndices, spec.consumersByFillTypeName[consumer].fillUnitIndex)
        end
    end
    if spec.motor ~= nil then
        spec.motor:postLoad(savegame)
    end
end
function Motorized:onRegisterDashboardValueTypes()
    local spec = self.spec_motorized
    local rpm = DashboardValueType.new("motorized", "rpm")
    rpm:setValue(self, "getMotorRpmReal")
    rpm:setRange(0, spec.motor:getMaxRpm())
    rpm:setInterpolationSpeed(function(_, dashboard)
        -- upvalues: (copy) spec
        return spec.motor:getMaxRpm() * 0.001
    end)
    self:registerDashboardValueType(rpm)
    local load = DashboardValueType.new("motorized", "load")
    load:setValue(spec.motor, "getSmoothLoadPercentage")
    load:setRange(0, 100)
    load:setInterpolationSpeed(0.1)
    load:setValueFactor(100)
    self:registerDashboardValueType(load)
    local speed = DashboardValueType.new("motorized", "speed")
    speed:setValue(self, "getLastSpeed")
    speed:setRange(0, spec.motor:getMaximumForwardSpeed() * 3.6)
    speed:setInterpolationSpeed(function(_, dashboard)
        -- upvalues: (copy) self
        return self:getLastSpeed() * 0.001
    end)
    self:registerDashboardValueType(speed)
    local speedDir = DashboardValueType.new("motorized", "speedDir")
    speedDir:setValue(self, function()
        -- upvalues: (copy) self, (copy) spec
        return self:getLastSpeed() * spec.motor:getDrivingDirection()
    end)
    speedDir:setRange(-spec.motor:getMaximumBackwardSpeed() * 3.6, spec.motor:getMaximumForwardSpeed() * 3.6)
    speedDir:setInterpolationSpeed(function(_, dashboard)
        -- upvalues: (copy) spec
        return spec.motor:getMaximumForwardSpeed() * 3.6 * 0.001
    end)
    speedDir:setCenter(0)
    self:registerDashboardValueType(speedDir)
    local fuelUsage = DashboardValueType.new("motorized", "fuelUsage")
    fuelUsage:setValue(spec, "lastFuelUsageDisplay")
    self:registerDashboardValueType(fuelUsage)
    local motorTemperature = DashboardValueType.new("motorized", "motorTemperature")
    motorTemperature:setValue(spec.motorTemperature, "value")
    motorTemperature:setRange("valueMin", "valueMax")
    motorTemperature:setInterpolationSpeed(function(motorTemperature, _)
        return (motorTemperature.valueMax - motorTemperature.valueMin) * 0.001
    end)
    self:registerDashboardValueType(motorTemperature)
    local motorTemperatureWarning = DashboardValueType.new("motorized", "motorTemperatureWarning")
    motorTemperatureWarning:setValue(spec.motorTemperature, function(_, dashboard)
        -- upvalues: (copy) spec
        local motorTemperature = spec.motorTemperature.value
        return dashboard.warningThresholdMin < motorTemperature and motorTemperature < dashboard.warningThresholdMax
    end)
    motorTemperatureWarning:setAdditionalFunctions(Dashboard.warningAttributes)
    self:registerDashboardValueType(motorTemperatureWarning)
    local clutchPedal = DashboardValueType.new("motorized", "clutchPedal")
    clutchPedal:setValue(spec.motor, "getSmoothedClutchPedal")
    clutchPedal:setRange(0, 1)
    self:registerDashboardValueType(clutchPedal)
    local gear = DashboardValueType.new("motorized", "gear")
    gear:setValue(spec.motor, function()
        -- upvalues: (copy) spec
        return spec.motor:getGearToDisplay(true)
    end)
    gear:setRange(0, math.huge)
    gear:setPollUpdate(spec.motor.forwardGears ~= nil)
    self:registerDashboardValueType(gear)
    local gearGroup = DashboardValueType.new("motorized", "gearGroup")
    gearGroup:setValue(spec.motor, function()
        -- upvalues: (copy) spec
        return spec.motor:getGearGroupToDisplay(true)
    end)
    gearGroup:setRange(0, math.huge)
    gearGroup:setPollUpdate(false)
    self:registerDashboardValueType(gearGroup)
    local gearIndex = DashboardValueType.new("motorized", "gearIndex")
    gearIndex:setValue(spec.motor, function()
        -- upvalues: (copy) spec
        return spec.motor.targetGear
    end)
    gearIndex:setRange(0, math.huge)
    gearIndex:setPollUpdate(false)
    self:registerDashboardValueType(gearIndex)
    DashboardValueType.new("motorized", "gearGroupIndex"):setValue(spec.motor, function()
        -- upvalues: (copy) spec
        return spec.motor.activeGearGroupIndex
    end)
    gearGroupIndex:setRange(0, math.huge)
    gearGroupIndex:setPollUpdate(false)
    self:registerDashboardValueType(gearGroupIndex)
    local gearShiftUp = DashboardValueType.new("motorized", "gearShiftUp")
    gearShiftUp:setValue(spec.motor, function(motor)
        return g_time - motor.lastGearChangeTime < 200 and motor.targetGear > motor.previousGear
    end)
    self:registerDashboardValueType(gearShiftUp)
    local gearShiftDown = DashboardValueType.new("motorized", "gearShiftDown")
    gearShiftDown:setValue(spec.motor, function(motor)
        return g_time - motor.lastGearChangeTime < 200 and motor.targetGear < motor.previousGear
    end)
    self:registerDashboardValueType(gearShiftDown)
    local gearShiftUpDown = DashboardValueType.new("motorized", "gearShiftUpDown")
    gearShiftUpDown:setValue(spec.motor, function(motor)
        if g_time - motor.lastGearChangeTime >= 200 then
            return 0
        end
        return math.sign(motor.targetGear - motor.previousGear)
    end)
    gearShiftUpDown:setRange(-1, 1)
    self:registerDashboardValueType(gearShiftUpDown)
    local movingDirection = DashboardValueType.new("motorized", "movingDirection")
    movingDirection:setValue(spec.motor, "getDrivingDirection")
    movingDirection:setRange(-1, 1)
    self:registerDashboardValueType(movingDirection)
    local directionForward = DashboardValueType.new("motorized", "directionForward")
    directionForward:setValue(spec.motor, function(motor)
        return motor:getDrivingDirection() >= 0
    end)
    self:registerDashboardValueType(directionForward)
    local directionForwardExclusive = DashboardValueType.new("motorized", "directionForwardExclusive")
    directionForwardExclusive:setValue(spec.motor, function(motor)
        return motor:getDrivingDirection() > 0
    end)
    self:registerDashboardValueType(directionForwardExclusive)
    local directionBackward = DashboardValueType.new("motorized", "directionBackward")
    directionBackward:setValue(spec.motor, function(motor)
        return motor:getDrivingDirection() < 0
    end)
    self:registerDashboardValueType(directionBackward)
    local directionNeutral = DashboardValueType.new("motorized", "directionNeutral")
    directionNeutral:setValue(spec.motor, function(motor)
        return motor:getDrivingDirection() == 0
    end)
    self:registerDashboardValueType(directionNeutral)
    local movingDirectionLetter = DashboardValueType.new("motorized", "movingDirectionLetter")
    movingDirectionLetter:setValue(spec.motor, function(motor)
        return motor:getDrivingDirection() == 1 and "F" or (motor:getDrivingDirection() == -1 and "R" or "N")
    end)
    self:registerDashboardValueType(movingDirectionLetter)
    local ignitionState = DashboardValueType.new("motorized", "ignitionState")
    ignitionState:setValue(self, function()
        -- upvalues: (copy) self
        if not g_ignitionLockManager:getIsAvailable() then
            local ignitionState = self:getMotorState()
            return ignitionState == MotorState.ON and 2 or (ignitionState == MotorState.STARTING and 1 or 0)
        end
        local ignitionState = g_ignitionLockManager:getState()
        if ignitionState == IgnitionLockState.OFF then
            return 0
        end
        if ignitionState == IgnitionLockState.IGNITION then
            return 2
        end
        if ignitionState == IgnitionLockState.START then
            return 1
        end
    end)
    ignitionState:setRange(0, 2)
    self:registerDashboardValueType(ignitionState)
    local battery = DashboardValueType.new("motorized", "battery")
    battery:setValue(self, 12 + (math.random() * 0.5 - 0.15))
    battery:setRange(0, 15)
    battery:setInterpolationSpeed(0.015)
    self:registerDashboardValueType(battery)
end
function Motorized:onDelete()
    local spec = self.spec_motorized
    if spec.motor ~= nil then
        spec.motor:delete()
    end
    if spec.sharedLoadRequestIds ~= nil then
        for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
        end
        spec.sharedLoadRequestIds = nil
    end
    ParticleUtil.deleteParticleSystems(spec.exhaustParticleSystems)
    g_soundManager:deleteSamples(spec.samples)
    g_soundManager:deleteSamples(spec.motorSamples)
    g_soundManager:deleteSamples(spec.gearboxSamples)
    g_animationManager:deleteAnimations(spec.animationNodes)
    if spec.effects ~= nil then
        g_effectManager:deleteEffects(spec.effects)
    end
end
function Motorized:onReadStream(streamId, _)
    self:setMotorState(MotorState.readStream(streamId), true)
end
function Motorized:onWriteStream(streamId, _)
    MotorState.writeStream(streamId, self.spec_motorized.motorState)
end
function Motorized:onReadUpdateStream(streamId, _, connection)
    if connection.isServer then
        if streamReadBool(streamId) then
            local rpm = streamReadUIntN(streamId, 11) / 2047
            local rpmRange = self.spec_motorized.motor:getMaxRpm() - self.spec_motorized.motor:getMinRpm()
            spec.motor:setEqualizedMotorRpm(rpm * rpmRange + spec.motor:getMinRpm())
            local loadPercentage = streamReadUIntN(streamId, 7)
            spec.motor.rawLoadPercentage = loadPercentage / 127
            spec.brakeCompressor.doFill = streamReadBool(streamId)
            local clutchState = streamReadUIntN(streamId, 5)
            spec.motor:onManualClutchChanged(clutchState / 31)
        end
        if streamReadBool(streamId) then
            spec.motor:readGearDataFromStream(streamId)
            return
        end
    elseif streamReadBool(streamId) and streamReadBool(streamId) then
        spec.clutchState = streamReadUIntN(streamId, 7) / 127
        spec.motor:onManualClutchChanged(spec.clutchState)
        if spec.clutchState > 0 then
            self:raiseActive()
        end
    end
end
function Motorized:onWriteUpdateStream(streamId, connection, dirtyMask)
    if connection.isServer then
        local motorState = streamWriteBool
        local rpm = bit32.band(dirtyMask, self.spec_motorized.inputDirtyFlag) ~= 0
        if motorState(streamId, rpm) then
            if streamWriteBool(streamId, spec.clutchState ~= spec.clutchStateSent) then
                streamWriteUIntN(streamId, 127 * spec.clutchState, 7)
                spec.clutchStateSent = spec.clutchState
            end
        end
    else
        local motorState = self:getMotorState()
        local rpmRange = streamWriteBool
        if rpmRange(streamId, motorState == MotorState.STARTING or motorState == MotorState.ON) then
            local rpmRange = spec.motor:getMaxRpm() - spec.motor:getMinRpm()
            local rpm = math.floor(math.clamp((spec.motor:getEqualizedMotorRpm() - spec.motor:getMinRpm()) / rpmRange, 0, 1) * 2047)
            streamWriteUIntN(streamId, rpm, 11)
            streamWriteUIntN(streamId, 127 * spec.actualLoadPercentage, 7)
            streamWriteBool(streamId, spec.brakeCompressor.doFill)
            streamWriteUIntN(streamId, 31 * spec.motor:getClutchPedal(), 5)
        end
        local rpmRange = streamWriteBool
        if rpmRange(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
            spec.motor:writeGearDataToStream(streamId)
            return
        end
    end
end
function Motorized:onUpdate(dt, _, _, _)
    local accInput = 0
    if self.getAxisForward ~= nil then
        accInput = self:getAxisForward()
    end
    local motorState = self:getMotorState()
    if motorState == MotorState.STARTING or motorState == MotorState.ON then
        if self.isServer and (motorState == MotorState.STARTING and self.spec_motorized.motorStartTime < g_currentMission.time) then
            self:setMotorState(MotorState.ON)
        end
        spec.motor:update(dt)
        if self.isServer then
            spec.actualLoadPercentage = math.clamp(spec.motor.rawLoadPercentage, 0, 1)
        end
        spec.smoothedLoadPercentage = spec.motor:getSmoothLoadPercentage()
        local accInput = self.getCruiseControlState ~= nil and self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_OFF and 1 or accInput
        if self.isServer then
            self:updateConsumers(dt, accInput)
            local minRpm = self:getVehicleDamage() - spec.lastVehicleDamage
            if math.abs(minRpm) > 0.05 then
                self:updateMotorProperties()
                spec.lastVehicleDamage = self:getVehicleDamage()
            end
        end
        if self.isClient then
            local rpmPercentage = self:getMotorRpmReal()
            local minRpm = spec.motor.minRpm
            local consumer = (rpmPercentage - minRpm) / (spec.motor.maxRpm - minRpm)
            local loadPercentage = math.min(consumer, 1)
            local rpmPercentage = math.max(loadPercentage, 0)
            local reverserDirection = self:getMotorLoadPercentage()
            local consumer = math.min(reverserDirection, 1)
            local loadPercentage = math.max(consumer, -1)
            g_soundManager:setSamplesLoopSynthesisParameters(spec.motorSamples, rpmPercentage, loadPercentage)
            if g_soundManager:getIsSamplePlaying(spec.motorSamples[1]) then
                if spec.samples.airCompressorRun ~= nil and (spec.consumersByFillTypeName ~= nil and spec.consumersByFillTypeName.AIR ~= nil) then
                    if spec.consumersByFillTypeName.AIR.doRefill then
                        if not g_soundManager:getIsSamplePlaying(damage.airCompressorRun) then
                            if damage.airCompressorStart == nil then
                                g_soundManager:playSample(damage.airCompressorRun)
                            else
                                if not g_soundManager:getIsSamplePlaying(damage.airCompressorStart) and spec.brakeCompressor.playSampleRunTime == nil then
                                    g_soundManager:playSample(damage.airCompressorStart)
                                    spec.brakeCompressor.playSampleRunTime = g_currentMission.time + damage.airCompressorStart.duration
                                end
                                if not g_soundManager:getIsSamplePlaying(damage.airCompressorStart) then
                                    spec.brakeCompressor.playSampleRunTime = nil
                                    g_soundManager:stopSample(damage.airCompressorStart)
                                    g_soundManager:playSample(damage.airCompressorRun)
                                end
                            end
                        end
                    elseif g_soundManager:getIsSamplePlaying(damage.airCompressorRun) then
                        g_soundManager:stopSample(damage.airCompressorRun)
                        g_soundManager:playSample(damage.airCompressorStop)
                    end
                end
                if spec.compressionSoundTime <= g_currentMission.time then
                    g_soundManager:playSample(damage.airRelease)
                    spec.compressionSoundTime = g_currentMission.time + math.random(10000, 40000)
                end
                local consumer = false
                if self:getDecelerationAxis() > 0 then
                    consumer = self:getLastSpeed() > 1
                end
                if damage.compressedAir ~= nil then
                    if consumer then
                        damage.compressedAir.brakeTime = damage.compressedAir.brakeTime + dt
                    elseif damage.compressedAir.brakeTime > 0 then
                        damage.compressedAir.lastBrakeTime = damage.compressedAir.brakeTime
                        damage.compressedAir.brakeTime = 0
                        g_soundManager:playSample(damage.compressedAir)
                    end
                end
                if damage.brake ~= nil then
                    if consumer then
                        if not spec.isBrakeSamplePlaying then
                            g_soundManager:playSample(damage.brake)
                            spec.isBrakeSamplePlaying = true
                        end
                    elseif spec.isBrakeSamplePlaying then
                        g_soundManager:stopSample(damage.brake)
                        spec.isBrakeSamplePlaying = false
                    end
                end
                if damage.reverseDrive ~= nil then
                    local reverserDirection = self.getReverserDirection == nil and 1 or self:getReverserDirection()
                    local isReverseDriving = false
                    if self:getLastSpeed() > spec.reverseDriveThreshold then
                        isReverseDriving = self.movingDirection ~= reverserDirection
                    end
                    if g_soundManager:getIsSamplePlaying(damage.reverseDrive) or not isReverseDriving then
                        if not isReverseDriving then
                            g_soundManager:stopSample(damage.reverseDrive)
                        end
                    else
                        g_soundManager:playSample(damage.reverseDrive)
                    end
                end
            end
            for state, gearLeverInterpolator in pairs(spec.activeGearLeverInterpolators) do
                local currentInterpolation = gearLeverInterpolator.interpolations[gearLeverInterpolator.currentInterpolation]
                if currentInterpolation == nil then
                    spec.activeGearLeverInterpolators[state] = nil
                elseif gearLeverInterpolator.handsOnDelay > 0 then
                    gearLeverInterpolator.handsOnDelay = gearLeverInterpolator.handsOnDelay - dt
                    if gearLeverInterpolator.handsOnDelay <= 0 then
                        local sample = gearLeverInterpolator.isGear and spec.samples.gearLeverStart or spec.samples.gearGroupLeverStart
                        if not g_soundManager:getIsSamplePlaying(sample) then
                            g_soundManager:playSample(sample)
                        end
                    end
                    if self.setCharacterTargetNodeStateDirty ~= nil then
                        self:setCharacterTargetNodeStateDirty(state.node, true)
                    end
                else
                    local sample = state.curRotation
                    local sample = state.curRotation
                    sample[1], sample[2], state.curRotation[3] = getRotation(state.node)
                    local sample = math.min
                    if currentInterpolation.speed < 0 then
                        sample = math.max
                    end
                    state.curRotation[currentInterpolation.axis] = sample(state.curRotation[currentInterpolation.axis] + currentInterpolation.speed * dt, currentInterpolation.tar)
                    setRotation(state.node, state.curRotation[1], state.curRotation[2], state.curRotation[3])
                    if state.curRotation[currentInterpolation.axis] == currentInterpolation.tar then
                        gearLeverInterpolator.currentInterpolation = gearLeverInterpolator.currentInterpolation + 1
                        if gearLeverInterpolator.currentInterpolation > #gearLeverInterpolator.interpolations then
                            spec.activeGearLeverInterpolators[state] = nil
                            if gearLeverInterpolator.isResetPosition and self.resetCharacterTargetNodeStateDefaults ~= nil then
                                self:resetCharacterTargetNodeStateDefaults(state.node)
                            end
                            local sample = gearLeverInterpolator.isGear and spec.samples.gearLeverEnd or spec.samples.gearGroupLeverEnd
                            if not g_soundManager:getIsSamplePlaying(sample) then
                                g_soundManager:playSample(sample)
                            end
                        end
                    end
                    if self.setCharacterTargetNodeStateDirty ~= nil then
                        self:setCharacterTargetNodeStateDirty(state.node)
                    end
                end
            end
        end
        if self.isServer and (not self:getIsAIActive() and (self:getTraveledDistanceStatsActive() and self.lastMovedDistance > 0.001)) then
            spec.traveledDistanceBuffer = spec.traveledDistanceBuffer + self.lastMovedDistance
            if spec.traveledDistanceBuffer > 10 then
                local damage = self:getOwnerFarmId()
                local rpm = spec.traveledDistanceBuffer * 0.001
                g_farmManager:updateFarmStats(damage, "traveledDistance", rpm)
                g_farmManager:updateFarmStats(damage, spec.statsTypeDistance, rpm)
                spec.traveledDistanceBuffer = 0
            end
        end
    end
end
function Motorized:onUpdateTick(dt, _, isActiveForInputIgnoreSelection, _)
    if self.isServer then
        if not g_currentMission.missionInfo.automaticMotorStartEnabled then
            local motorState = self:getMotorState()
            if (motorState == MotorState.STARTING or motorState == MotorState.ON) and not self:getIsAIActive() then
                local isEntered = false
                if self.getIsEntered ~= nil then
                    isEntered = self:getIsEntered()
                end
                local isControlled = false
                if self.getIsControlled ~= nil then
                    isControlled = self:getIsControlled()
                end
                if not (isEntered or isControlled) then
                    local isPlayerInRange = false
                    for _, player in pairs(g_currentMission.playerSystem.players) do
                        if player.isControlled and calcDistanceFrom(self.rootNode, player.rootNode) < 250 then
                            isPlayerInRange = true
                            break
                        end
                    end
                    if not isPlayerInRange then
                        for _, player in pairs(g_currentMission.vehicleSystem.enterables) do
                            if player:getIsInUse(nil) and calcDistanceFrom(self.rootNode, player.rootNode) < 250 then
                                isPlayerInRange = true
                                break
                            end
                        end
                    end
                    if isPlayerInRange then
                        self.spec_motorized.motorStopTimer = self.spec_motorized.motorStopTimerDuration
                    else
                        spec.motorStopTimer = spec.motorStopTimer - dt
                        if spec.motorStopTimer <= 0 then
                            self:stopMotor()
                        end
                    end
                end
            end
        end
        local motorState = self:getMotorState()
        if motorState == MotorState.STARTING or motorState == MotorState.ON then
            self:updateMotorTemperature(dt)
        end
        if automaticMotorStartEnabled then
            if motorState == MotorState.OFF or motorState == MotorState.IGNITION then
                if not g_ignitionLockManager:getIsAvailable() then
                    if (self.getIsControlled ~= nil and self:getIsControlled() or self.getIsEnteredForInput ~= nil and self:getIsEnteredForInput()) and self:getCanMotorRun() then
                        self:startMotor(true)
                    end
                    if self:getRequiresPower() and self:getCanMotorRun() then
                        self:startMotor(true)
                    end
                end
            elseif self.getIsControlled ~= nil and (not self:getIsControlled() and (self.getIsEnteredForInput ~= nil and not self:getIsEnteredForInput())) then
                if self:getStopMotorOnLeave() then
                    spec.motorNotRequiredTimer = spec.motorNotRequiredTimer + dt
                    if spec.motorNotRequiredTimer > 250 then
                        self:stopMotor(true)
                    end
                end
                self:raiseActive()
            end
        end
    end
    if self.isClient then
        local motorState = self:getMotorState()
        if motorState == MotorState.STARTING or motorState == MotorState.ON then
            local isEntered = self:getMotorRpmReal() / spec.motor:getMaxRpm()
            if spec.exhaustParticleSystems ~= nil then
                for _, ps in pairs(spec.exhaustParticleSystems) do
                    local _ = MathUtil.lerp(spec.exhaustParticleSystems.minScale, spec.exhaustParticleSystems.maxScale, isEntered)
                    ParticleUtil.setEmitCountScale(spec.exhaustParticleSystems, _)
                    ParticleUtil.setParticleLifespan(ps, ps.originalLifespan * _)
                end
            end
            for _, ps in ipairs(spec.exhaustFlaps) do
                local angle = MathUtil.lerp(-0.1, 0.1, math.random()) + isEntered
                local angle = math.clamp(angle, 0, 1) * ps.maxRot
                if ps.rotationAxis == 1 then
                    setRotation(ps.node, angle, 0, 0)
                elseif ps.rotationAxis == 2 then
                    setRotation(ps.node, 0, angle, 0)
                else
                    setRotation(ps.node, 0, 0, angle)
                end
            end
            if spec.effects ~= nil then
                g_effectManager:setDensity(spec.effects, isEntered)
            end
            if spec.exhaustEffects ~= nil then
                for _, ps in pairs(spec.exhaustEffects) do
                    local _, player, distance = localToWorld(ps.effectNode, 0, 0.5, 0)
                    if ps.lastPosition == nil then
                        ps.lastPosition = { _, player, distance }
                    end
                    local ex, ey, ez = localToWorld(ps.effectNode, 0, 1, 0)
                    local lx, ly, lz = worldToLocal(ps.effectNode, ex - (_ - ps.lastPosition[1]) * 10, ey - (player - ps.lastPosition[2]) * 10 + ps.upFactor, ez - (distance - ps.lastPosition[3]) * 10)
                    local distance = MathUtil.vector2Length(lx, lz)
                    if distance > 0 then
                        lx, lz = MathUtil.vector2Normalize(lx, lz)
                    end
                    local yFactor = math.max(ly, 0.01)
                    local xFactor = math.abs(yFactor)
                    local xFactor = math.atan(distance / xFactor) * (1.2 + 2 * xFactor)
                    local yFactor = math.atan(distance / xFactor) * (1.2 + 2 * xFactor)
                    ps.xRot = ps.xRot * 0.95 + math.atan(lz / xFactor) * xFactor * 0.05
                    ps.zRot = ps.zRot * 0.95 + -math.atan(lx / xFactor) * yFactor * 0.05
                    setShaderParameter(ps.effectNode, "param", ps.xRot, ps.zRot, 0, MathUtil.lerp(ps.minRpmScale, ps.maxRpmScale, isEntered), false)
                    local r = MathUtil.lerp(ps.minRpmColor[1], ps.maxRpmColor[1], isEntered)
                    local b = MathUtil.lerp(ps.minRpmColor[3], ps.maxRpmColor[3], isEntered)
                    local a = MathUtil.lerp(ps.minRpmColor[4], ps.maxRpmColor[4], isEntered)
                    setShaderParameter(ps.effectNode, "exhaustColor", r, MathUtil.lerp(ps.minRpmColor[2], ps.maxRpmColor[2], isEntered), b, a, false)
                    ps.lastPosition[1] = _
                    ps.lastPosition[2] = player
                    ps.lastPosition[3] = distance
                end
            end
            spec.lastFuelUsageDisplayTime = spec.lastFuelUsageDisplayTime + dt
            if spec.lastFuelUsageDisplayTime > 250 then
                spec.lastFuelUsageDisplayTime = 0
                spec.lastFuelUsageDisplay = spec.fuelUsageBuffer:getAverage()
            end
            spec.fuelUsageBuffer:add(spec.lastFuelUsage)
        end
        if spec.clutchCrackingTimeOut < g_time then
            if g_soundManager:getIsSamplePlaying(spec.samples.clutchCracking) then
                g_soundManager:stopSample(spec.samples.clutchCracking)
            end
            if spec.clutchCrackingGearIndex ~= nil then
                self:setGearLeversState(0, nil, 500)
            end
            if spec.clutchCrackingGroupIndex ~= nil then
                self:setGearLeversState(nil, 0, 500)
            end
            spec.clutchCrackingTimeOut = math.huge
        end
        if isActiveForInputIgnoreSelection then
            if automaticMotorStartEnabled and not self:getCanMotorRun() then
                local isEntered = self:getMotorNotAllowedWarning()
                if isEntered ~= nil then
                    g_currentMission:showBlinkingWarning(isEntered, 2000)
                end
            end
            if g_ignitionLockManager:getIsAvailable() and not self:getIsAIActive() then
                local isEntered = g_ignitionLockManager:getState()
                local isControlled = self:getMotorState()
                if isEntered == IgnitionLockState.OFF then
                    if isControlled ~= MotorState.OFF then
                        self:setMotorState(MotorState.OFF)
                    end
                elseif isEntered == IgnitionLockState.IGNITION then
                    if isControlled == MotorState.OFF then
                        self:setMotorState(MotorState.IGNITION)
                    end
                elseif isEntered == IgnitionLockState.START and (isControlled ~= MotorState.STARTING and isControlled ~= MotorState.ON) then
                    if self:getCanMotorRun() then
                        self:setMotorState(MotorState.STARTING)
                    else
                        local isControlled = self:getMotorNotAllowedWarning()
                        if isControlled ~= nil then
                            g_currentMission:showBlinkingWarning(isControlled, 2000)
                        end
                    end
                end
            end
            Motorized.updateActionEvents(self)
        end
    end
end
function Motorized:loadDifferentials(xmlFile, configDifferentialIndex)
    local key, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, configDifferentialIndex, "vehicle.motorized.differentialConfigurations.differentialConfiguration", "vehicle.motorized.differentials", "differentials")
    local spec = self.spec_motorized
    spec.differentials = {}
    if self.isServer and spec.motorizedNode ~= nil then
        xmlFile:iterate(key .. ".differentials.differential", function(_, differentialKey)
            -- upvalues: (copy) xmlFile, (copy) self, (copy) spec
            local torqueRatio = xmlFile:getValue(differentialKey .. "#torqueRatio", 0.5)
            local maxSpeedRatio = xmlFile:getValue(differentialKey .. "#maxSpeedRatio", 1.3)
            local indices = { -1, -1 }
            local j = 1
            for j = j, 2 do
                local wheelIndex = xmlFile:getValue(differentialKey .. string.format("#wheelIndex%d", j))
                if wheelIndex == nil then
                    local diffIndex = xmlFile:getValue(differentialKey .. string.format("#differentialIndex%d", j))
                    if diffIndex ~= nil then
                        indices[j] = diffIndex - 1
                        ({ false, false })[j] = false
                        if diffIndex == 0 then
                            Logging.xmlWarning(self.xmlFile, "Unable to find differentialIndex \'0\' for differential \'%s\' (Indices start at 1)", differentialKey)
                        end
                    end
                elseif self:getWheelFromWheelIndex(wheelIndex) == nil then
                    Logging.xmlWarning(self.xmlFile, "Unable to find wheelIndex \'%d\' for differential \'%s\' (Indices start at 1)", wheelIndex, differentialKey)
                else
                    indices[j] = wheelIndex
                    indexIsWheel[j] = true
                end
            end
            if indices[1] ~= -1 and indices[2] ~= -1 then
                table.insert(spec.differentials, {
                    ["torqueRatio"] = torqueRatio,
                    ["maxSpeedRatio"] = maxSpeedRatio,
                    ["diffIndex1"] = indices[1],
                    ["diffIndex1IsWheel"] = indexIsWheel[1],
                    ["diffIndex2"] = indices[2],
                    ["diffIndex2IsWheel"] = indexIsWheel[2]
                })
            end
        end)
        if #spec.differentials == 0 then
            Logging.xmlWarning(self.xmlFile, "No differentials defined")
        end
    end
end
function Motorized:loadMotor(xmlFile, motorId)
    local spec, fallbackConfigKey = ConfigurationUtil.getXMLConfigurationKey(xmlFile, motorId, "vehicle.motorized.motorConfigurations.motorConfiguration", "vehicle.motorized", "motor")
    local spec = self.spec_motorized
    local vehicleName = xmlFile:getValue(spec .. "#name", nil, self.customEnvironment, false)
    local params = xmlFile:getValue(spec .. "#params")
    if vehicleName ~= nil and params ~= nil then
        vehicleName = g_i18n:insertTextParams(vehicleName, params, self.customEnvironment, xmlFile)
    end
    spec.vehicleName = xmlFile:getValue(spec .. "#vehicleName", vehicleName, self.customEnvironment, false)
    spec.motorType = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#type", "vehicle", "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    spec.motorStartAnimation = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#startAnimationName", "vehicle", "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    spec.consumerConfigurationIndex = ConfigurationUtil.getConfigurationValue(xmlFile, spec, "#consumerConfigurationIndex", "", 1, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    local motorMinRpm = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#minRpm", 1000, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    local motorMaxRpm = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#maxRpm", 1800, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    local minSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#minSpeed", 1, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    local maxForwardSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#maxForwardSpeed", nil, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    local maxBackwardSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#maxBackwardSpeed", nil, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    if maxForwardSpeed ~= nil then
    end
    if maxBackwardSpeed ~= nil then
    end
    local spec_wheels = self.spec_wheels
    if spec_wheels ~= nil and (spec_wheels.configItem ~= nil and spec_wheels.configItem.maxForwardSpeed ~= nil) then
        maxForwardSpeed = spec_wheels.configItem.maxForwardSpeed / 3.6
    end
    local accelerationLimit = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#accelerationLimit", 2, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    local brakeForce = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#brakeForce", 10, "vehicle.motorized.motorConfigurations.motorConfiguration(0)") * 2
    local lowBrakeForceScale = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#lowBrakeForceScale", 0.5, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    local lowBrakeForceSpeedLimit = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#lowBrakeForceSpeedLimit", 1, "vehicle.motorized.motorConfigurations.motorConfiguration(0)") / 3600
    local torqueScale = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#torqueScale", 1, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    local ptoMotorRpmRatio = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#ptoMotorRpmRatio", 4, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
    local transmissionKey = spec .. ".transmission"
    local transmissionKey = not xmlFile:hasProperty(transmissionKey) and "vehicle.motorized.motorConfigurations.motorConfiguration(0).transmission" or transmissionKey
    local minForwardGearRatio = xmlFile:getValue(transmissionKey .. "#minForwardGearRatio")
    local maxForwardGearRatio = xmlFile:getValue(transmissionKey .. "#maxForwardGearRatio")
    local minBackwardGearRatio = xmlFile:getValue(transmissionKey .. "#minBackwardGearRatio")
    local maxBackwardGearRatio = xmlFile:getValue(transmissionKey .. "#maxBackwardGearRatio")
    local gearChangeTime = xmlFile:getValue(transmissionKey .. "#gearChangeTime")
    local autoGearChangeTime = xmlFile:getValue(transmissionKey .. "#autoGearChangeTime")
    local axleRatio = xmlFile:getValue(transmissionKey .. "#axleRatio", 1)
    local startGearThreshold = xmlFile:getValue(transmissionKey .. "#startGearThreshold", VehicleMotor.GEAR_START_THRESHOLD)
    local minForwardGearRatio, maxForwardGearRatio
    if maxForwardGearRatio == nil or minForwardGearRatio == nil then
        minForwardGearRatio = nil
        maxForwardGearRatio = nil
    end
    local minBackwardGearRatio, maxBackwardGearRatio
    if minBackwardGearRatio == nil or maxBackwardGearRatio == nil then
        minBackwardGearRatio = nil
        maxBackwardGearRatio = nil
    end
    local forwardGears = nil
    if minForwardGearRatio == nil then
        forwardGears = self:loadGears(xmlFile, "forwardGear", transmissionKey, motorMaxRpm, axleRatio, 1)
        if forwardGears == nil then
            printWarning("Warning: Missing forward gear ratios for motor in \'" .. self.configFileName .. "\'!")
            forwardGears = {
                {
                    ["ratio"] = 1,
                    ["default"] = false
                }
            }
        end
    end
    local backwardGears = nil
    if minBackwardGearRatio == nil then
        backwardGears = self:loadGears(xmlFile, "backwardGear", transmissionKey, motorMaxRpm, axleRatio, -1)
    end
    local gearGroups = self:loadGearGroups(xmlFile, transmissionKey .. ".groups", motorMaxRpm, axleRatio)
    local groupsType = xmlFile:getValue(transmissionKey .. ".groups#type", "default")
    local groupChangeTime = xmlFile:getValue(transmissionKey .. ".groups#changeTime", 0.5)
    local directionChangeUseGear = xmlFile:getValue(transmissionKey .. ".directionChange#useGear", false)
    local directionChangeGearIndex = xmlFile:getValue(transmissionKey .. ".directionChange#reverseGearIndex", 1)
    local directionChangeUseGroup = xmlFile:getValue(transmissionKey .. ".directionChange#useGroup", false)
    local directionChangeGroupIndex = xmlFile:getValue(transmissionKey .. ".directionChange#reverseGroupIndex", 1)
    local directionChangeTime = xmlFile:getValue(transmissionKey .. ".directionChange#changeTime", 0.5)
    local manualShiftGears = xmlFile:getValue(transmissionKey .. ".manualShift#gears", true)
    local manualShiftGroups = xmlFile:getValue(transmissionKey .. ".manualShift#groups", true)
    local torqueCurve = AnimCurve.new(linearInterpolator1)
    local torqueI = 0
    local torqueBase = "vehicle.motorized.motorConfigurations.motorConfiguration(0).motor.torque"
    if spec ~= nil and xmlFile:hasProperty(spec .. ".motor.torque(0)") then
        torqueBase = spec .. ".motor.torque"
    end
    while true do
        local torqueKey = string.format(torqueBase .. "(%d)", torqueI)
        local normRpm = xmlFile:getValue(torqueKey .. "#normRpm")
        local rpm
        if normRpm == nil then
            rpm = xmlFile:getValue(torqueKey .. "#rpm")
        else
            rpm = normRpm * motorMaxRpm
        end
        local torque = xmlFile:getValue(torqueKey .. "#torque")
        if torque == nil or rpm == nil then
            spec.motor = VehicleMotor.new(self, motorMinRpm, motorMaxRpm, maxForwardSpeed, maxBackwardSpeed, torqueCurve, brakeForce, forwardGears, backwardGears, minForwardGearRatio, maxForwardGearRatio, minBackwardGearRatio, maxBackwardGearRatio, ptoMotorRpmRatio, minSpeed)
            spec.motor:setGearGroups(gearGroups, groupsType, groupChangeTime)
            spec.motor:setDirectionChange(directionChangeUseGear, directionChangeGearIndex, directionChangeUseGroup, directionChangeGroupIndex, directionChangeTime)
            spec.motor:setManualShift(manualShiftGears, manualShiftGroups)
            spec.motor:setStartGearThreshold(startGearThreshold)
            local torqueKey = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#rotInertia", spec.motor:getRotInertia(), "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
            local normRpm = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#dampingRateScale", 1, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
            spec.motor:setRotInertia(torqueKey)
            spec.motor:setDampingRateScale(normRpm)
            spec.motor:setLowBrakeForce(lowBrakeForceScale, lowBrakeForceSpeedLimit)
            spec.motor:setAccelerationLimit(accelerationLimit)
            local rpm = ConfigurationUtil.getConfigurationValue(xmlFile, spec, ".motor", "#rpmSpeedLimit", nil, "vehicle.motorized.motorConfigurations.motorConfiguration(0)")
            if rpm ~= nil then
                spec.motor:setMotorRotationAccelerationLimit(rpm * 3.141592653589793 / 30)
            end
            if gearChangeTime ~= nil then
                spec.motor:setGearChangeTime(gearChangeTime)
            end
            if autoGearChangeTime ~= nil then
                spec.motor:setAutoGearChangeTime(autoGearChangeTime)
            end
            return
        end
        torqueCurve:addKeyframe({
            torque * torqueScale,
            ["time"] = rpm
        })
        torqueI = torqueI + 1
    end
end
function Motorized.sortGears(a, b)
    if a.ratio < 0 and b.ratio >= 0 then
        return true
    end
    if a.ratio >= 0 and b.ratio < 0 then
        return false
    end
    return a.ratio > b.ratio
end
function Motorized.loadGears(_, xmlFile, gearName, key, motorMaxRpm, axleRatio, direction)
    local gears = {}
    local gearI = 0
    while true do
        local gearKey = string.format(key .. ".%s(%d)", gearName, gearI)
        if not xmlFile:hasProperty(gearKey) then
            break
        end
        local gearRatio = xmlFile:getValue(gearKey .. "#gearRatio")
        local maxSpeed = xmlFile:getValue(gearKey .. "#maxSpeed")
        if maxSpeed ~= nil then
            gearRatio = motorMaxRpm * 3.141592653589793 / (maxSpeed / 3.6 * 30)
        end
        if gearRatio ~= nil then
            local gearEntry = {
                ["ratio"] = gearRatio * axleRatio,
                ["default"] = xmlFile:getValue(gearKey .. "#defaultGear", false)
            }
            gearEntry.name = xmlFile:getValue(gearKey .. "#name", (tostring((gearI + 1) * direction)))
            gearEntry.reverseName = xmlFile:getValue(gearKey .. "#reverseName", (tostring((gearI + 1) * direction * -1)))
            gearEntry.dashboardName = xmlFile:getValue(gearKey .. "#dashboardName")
            gearEntry.dashboardReverseName = xmlFile:getValue(gearKey .. "#dashboardReverseName")
            gearEntry.actionName = xmlFile:getValue(gearKey .. "#actionName")
            if (gearI < 8 or gearEntry.actionName ~= nil) and gearEntry.actionName ~= "-" then
                gearEntry.actionName = gearEntry.actionName or string.format("SHIFT_GEAR_SELECT_%d", gearI + 1)
                gearEntry.inputAction = InputAction[gearEntry.actionName]
                if gearEntry.inputAction == nil then
                    Logging.xmlWarning(xmlFile, "Invalid actionName \'%s\' found for gear \'%s\'", gearEntry.actionName, gearKey)
                    gearEntry.inputAction = InputAction[string.format("SHIFT_GEAR_SELECT_%d", gearI + 1)]
                end
            end
            table.insert(gears, gearEntry)
        end
        gearI = gearI + 1
    end
    if #gears <= 0 then
        return nil
    end
    if #gears > 8 then
        for gearEntry, gearEntry in pairs(gears) do
            if gearEntry.actionName == nil then
                Logging.xmlDevWarning(xmlFile, "More than 8 gears defined, but manual assignment of actionName missing for gear %d. (Use \'-\' to skip a gear)", gearEntry)
            end
        end
    end
    table.sort(gears, Motorized.sortGears)
    return gears
end
function Motorized.loadGearGroups(_, xmlFile, key, _, _)
    local groups = {}
    local i = 0
    while true do
        local groupKey = string.format(key .. ".group(%d)", i)
        if not xmlFile:hasProperty(groupKey) then
            break
        end
        local ratio = xmlFile:getValue(groupKey .. "#ratio")
        if ratio ~= nil then
            local groupEntry = {
                ["ratio"] = 1 / ratio,
                ["isDefault"] = xmlFile:getValue(groupKey .. "#isDefault", false)
            }
            groupEntry.name = xmlFile:getValue(groupKey .. "#name", (tostring(i + 1)))
            groupEntry.dashboardName = xmlFile:getValue(groupKey .. "#dashboardName")
            groupEntry.actionName = xmlFile:getValue(groupKey .. "#actionName")
            if (i < 4 or groupEntry.actionName ~= nil) and groupEntry.actionName ~= "-" then
                groupEntry.actionName = groupEntry.actionName or string.format("SHIFT_GROUP_SELECT_%d", i + 1)
                groupEntry.inputAction = InputAction[groupEntry.actionName]
                if groupEntry.inputAction == nil then
                    Logging.xmlWarning(xmlFile, "Invalid actionName \'%s\' found for gear group \'%s\'", groupEntry.actionName, groupKey)
                    groupEntry.inputAction = InputAction[string.format("SHIFT_GROUP_SELECT_%d", i + 1)]
                end
            end
            table.insert(groups, groupEntry)
        end
        i = i + 1
    end
    if #groups <= 0 then
        return nil
    end
    if #groups > 4 then
        for j, groupEntry in pairs(groups) do
            if groupEntry.actionName == nil then
                Logging.xmlDevWarning(xmlFile, "More than 4 gear groups defined, but manual assignment of actionName missing for gearGroup %d. (Use \'-\' to skip a group)", j)
            end
        end
    end
    table.sort(groups, Motorized.sortGears)
    return groups
end
function Motorized:loadExhaustEffects(xmlFile)
    local spec = self.spec_motorized
    local minScale = xmlFile:getValue("vehicle.motorized.exhaustParticleSystems#minScale", 0.5)
    local maxScale = xmlFile:getValue("vehicle.motorized.exhaustParticleSystems#maxScale", 1)
    spec.exhaustParticleSystems = {}
    local i = 0
    while true do
        local baseKey = string.format("vehicle.motorized.exhaustParticleSystems.exhaustParticleSystem(%d)", i)
        if not xmlFile:hasProperty(baseKey) then
            break
        end
        local particleSystem = {}
        ParticleUtil.loadParticleSystem(xmlFile, particleSystem, baseKey, self.components, false, nil, self.baseDirectory)
        particleSystem.minScale = minScale
        particleSystem.maxScale = maxScale
        table.insert(spec.exhaustParticleSystems, particleSystem)
        i = i + 1
    end
    if #spec.exhaustParticleSystems == 0 then
        spec.exhaustParticleSystems = nil
    end
    XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.motorized.exhaustFlap#index", "vehicle.motorized.exhaustFlap#node")
    spec.exhaustFlaps = {}
    for _, key in self.xmlFile:iterator("vehicle.motorized.exhaustFlap") do
        local exhaustFlap = {
            ["node"] = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if exhaustFlap.node ~= nil then
            exhaustFlap.maxRot = xmlFile:getValue(key .. "#maxRot", 0)
            exhaustFlap.rotationAxis = xmlFile:getValue(key .. "#rotationAxis", 1)
            table.insert(spec.exhaustFlaps, exhaustFlap)
        end
    end
    spec.exhaustEffects = {}
    spec.sharedLoadRequestIds = {}
    xmlFile:iterate("vehicle.motorized.exhaustEffects.exhaustEffect", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) spec
        XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
        local linkNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        local filename = xmlFile:getValue(key .. "#filename")
        if filename ~= nil and linkNode ~= nil then
            local arguments = {
                ["xmlFile"] = xmlFile,
                ["key"] = key,
                ["linkNode"] = linkNode,
                ["filename"] = Utils.getFilename(filename, self.baseDirectory)
            }
            local sharedLoadRequestId = self:loadSubSharedI3DFile(arguments, false, false, self.onExhaustEffectI3DLoaded, self, arguments)
            table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
        end
    end)
    spec.exhaustEffectMaxSteeringSpeed = 0.001
    spec.effects = g_effectManager:loadEffect(xmlFile, "vehicle.motorized.effects", self.components, self, self.i3dMappings)
    g_effectManager:setEffectTypeInfo(spec.effects, FillType.UNKNOWN)
end
function Motorized:onExhaustEffectI3DLoaded(i3dNode, _, args)
    if i3dNode ~= 0 then
        local node = getChildAt(i3dNode, 0)
        if getHasShaderParameter(node, "param") then
            local xmlFile = args.xmlFile
            local key = args.key
            local effect = {
                ["effectNode"] = node,
                ["node"] = args.linkNode,
                ["filename"] = args.filename
            }
            link(effect.node, effect.effectNode)
            setVisibility(effect.effectNode, false)
            delete(i3dNode)
            effect.minRpmColor = xmlFile:getValue(key .. "#minRpmColor", "0 0 0 1", true)
            effect.maxRpmColor = xmlFile:getValue(key .. "#maxRpmColor", "0.0384 0.0359 0.0627 2.0", true)
            effect.minRpmScale = xmlFile:getValue(key .. "#minRpmScale", 0.25)
            effect.maxRpmScale = xmlFile:getValue(key .. "#maxRpmScale", 0.95)
            effect.upFactor = xmlFile:getValue(key .. "#upFactor", 0.75)
            effect.lastPosition = nil
            effect.xRot = 0
            effect.zRot = 0
            table.insert(self.spec_motorized.exhaustEffects, effect)
        end
    end
end
function Motorized:loadSounds(xmlFile, baseString)
    if self.isClient then
        local spec = self.spec_motorized
        spec.samples = spec.samples or {}
        spec.samples.motorStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "motorStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.motorStart
        spec.samples.motorStop = g_soundManager:loadSampleFromXML(xmlFile, baseString, "motorStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.motorStop
        spec.samples.clutchCracking = g_soundManager:loadSampleFromXML(xmlFile, baseString, "clutchCracking", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.clutchCracking
        spec.samples.gearEngaged = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearEngaged", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearEngaged
        spec.samples.gearDisengaged = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearDisengaged", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearDisengaged
        spec.samples.gearGroupChange = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearGroupChange", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearGroupChange
        spec.samples.gearLeverStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearLeverStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearLeverStart
        spec.samples.gearLeverEnd = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearLeverEnd", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearLeverEnd
        spec.samples.gearGroupLeverStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearGroupLeverStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearGroupLeverStart
        spec.samples.gearGroupLeverEnd = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearGroupLeverEnd", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearGroupLeverEnd
        spec.samples.gearRangeChange = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearRangeChange", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearRangeChange
        spec.samples.blowOffValve = g_soundManager:loadSampleFromXML(xmlFile, baseString, "blowOffValve", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.blowOffValve
        spec.samples.retarder = g_soundManager:loadSampleFromXML(xmlFile, baseString, "retarder", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.retarder
        spec.gearboxSamples = g_soundManager:loadSamplesFromXML(xmlFile, baseString, "gearbox", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self, spec.gearboxSamples)
        spec.motorSamples = g_soundManager:loadSamplesFromXML(xmlFile, baseString, "motor", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self, spec.motorSamples)
        spec.samples.airCompressorStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.airCompressorStart
        spec.samples.airCompressorStop = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.airCompressorStop
        spec.samples.airCompressorRun = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorRun", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.airCompressorRun
        spec.samples.compressedAir = g_soundManager:loadSampleFromXML(xmlFile, baseString, "compressedAir", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.compressedAir
        if spec.samples.compressedAir ~= nil then
            spec.samples.compressedAir.brakeTime = 0
            spec.samples.compressedAir.lastBrakeTime = 0
        end
        spec.samples.airRelease = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airRelease", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.airRelease
        spec.samples.reverseDrive = g_soundManager:loadSampleFromXML(xmlFile, baseString, "reverseDrive", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.reverseDrive
        spec.reverseDriveThreshold = xmlFile:getValue("vehicle.motorized.reverseDriveSound#threshold", 4)
        spec.brakeCompressor = {}
        spec.brakeCompressor.capacity = xmlFile:getValue("vehicle.motorized.brakeCompressor#capacity", 6)
        spec.brakeCompressor.refillFilllevel = math.min(spec.brakeCompressor.capacity, xmlFile:getValue("vehicle.motorized.brakeCompressor#refillFillLevel", spec.brakeCompressor.capacity / 2))
        spec.brakeCompressor.fillSpeed = xmlFile:getValue("vehicle.motorized.brakeCompressor#fillSpeed", 0.6) / 1000
        spec.brakeCompressor.fillLevel = 0
        spec.brakeCompressor.doFill = true
        spec.isBrakeSamplePlaying = false
        spec.samples.brake = g_soundManager:loadSampleFromXML(xmlFile, baseString, "brake", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.brake
        spec.compressionSoundTime = 0
    end
end
function Motorized:loadConsumerConfiguration(xmlFile, consumerIndex)
    local key = string.format("vehicle.motorized.consumerConfigurations.consumerConfiguration(%d)", consumerIndex - 1)
    local spec = self.spec_motorized
    spec.consumersEmptyWarning = self.xmlFile:getValue(key .. "#consumersEmptyWarning", "warning_motorFuelEmpty", self.customEnvironment)
    spec.consumers = {}
    spec.consumersByFillTypeName = {}
    spec.consumersByFillType = {}
    if xmlFile:hasProperty(key) then
        local i = 0
        while true do
            local consumerKey = string.format(".consumer(%d)", i)
            if not xmlFile:hasProperty(key .. consumerKey) then
                break
            end
            local consumer = {
                ["fillUnitIndex"] = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#fillUnitIndex", 1, "vehicle.motorized.consumers")
            }
            local fillTypeName = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#fillType", "consumer", "vehicle.motorized.consumers")
            consumer.fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
            consumer.capacity = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#capacity", nil, "vehicle.motorized.consumers")
            local fillUnit = self:getFillUnitByIndex(consumer.fillUnitIndex)
            if fillUnit == nil then
                Logging.xmlWarning(self.xmlFile, "Unknown fillUnit \'%d\' for consumer \'%s\'", consumer.fillUnitIndex, key .. consumerKey)
            else
                if fillUnit.supportedFillTypes[consumer.fillType] == nil then
                    fillUnit.supportedFillTypes = {}
                    fillUnit.supportedFillTypes[consumer.fillType] = true
                end
                fillUnit.capacity = consumer.capacity or fillUnit.capacity
                if (consumer.fillType == FillType.DIESEL or (consumer.fillType == FillType.ELECTRICCHARGE or consumer.fillType == FillType.METHANE)) and fillUnit.exactFillRootNode == nil then
                    Logging.xmlWarning(self.xmlFile, "Missing exactFillRootNode for fuel fill unit (%d).", consumer.fillUnitIndex)
                end
                fillUnit.startFillLevel = fillUnit.capacity
                fillUnit.startFillTypeIndex = consumer.fillType
                fillUnit.ignoreFillLimit = true
                local usage = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#usage", 1, "vehicle.motorized.consumers")
                consumer.permanentConsumption = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#permanentConsumption", true, "vehicle.motorized.consumers")
                if consumer.permanentConsumption then
                    consumer.usage = usage / 3600000
                else
                    consumer.usage = usage
                end
                consumer.refillLitersPerSecond = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#refillLitersPerSecond", 0, "vehicle.motorized.consumers")
                consumer.refillCapacityPercentage = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#refillCapacityPercentage", 0, "vehicle.motorized.consumers")
                consumer.fillLevelToChange = 0
                table.insert(spec.consumers, consumer)
                spec.consumersByFillTypeName[string.upper(fillTypeName)] = consumer
                spec.consumersByFillType[consumer.fillType] = consumer
            end
            i = i + 1
        end
    end
end
function Motorized:getIsMotorStarted()
    return self.spec_motorized.motorState == MotorState.ON
end
function Motorized:getIsMotorInNeutral()
    return self.spec_motorized.motor:getIsInNeutral()
end
function Motorized:getMotorState()
    return self.spec_motorized.motorState
end
function Motorized:getCanMotorRun()
    local spec = self.spec_motorized
    for _, fillUnitIndex in ipairs(spec.propellantFillUnitIndices) do
        if self:getFillUnitFillLevel(fillUnitIndex) == 0 then
            return false
        end
    end
    return spec.motor:getCanMotorRun() and true or false
end
function Motorized:getStopMotorOnLeave()
    return self.spec_motorized.stopMotorOnLeave and not self:getRequiresPower()
end
function Motorized:getMotorNotAllowedWarning()
    local spec = self.spec_motorized
    for _, fillUnit in pairs(spec.propellantFillUnitIndices) do
        if self:getFillUnitFillLevel(fillUnit) == 0 then
            return spec.consumersEmptyWarning
        end
    end
    local canMotorRun, reason = spec.motor:getCanMotorRun()
    if canMotorRun or reason ~= VehicleMotor.REASON_CLUTCH_NOT_ENGAGED then
        return nil
    else
        return spec.clutchNoEngagedWarning
    end
end
function Motorized:setMotorState(motorState, noEventSend)
    local spec = self.spec_motorized
    if spec.motorState ~= motorState then
        MotorStateEvent.sendEvent(self, motorState, noEventSend)
        local lastMotorState = spec.motorState
        spec.motorState = motorState
        local startMotor = false
        local stopMotor = false
        if lastMotorState == MotorState.OFF or lastMotorState == MotorState.IGNITION then
            if motorState == MotorState.STARTING or motorState == MotorState.ON then
                startMotor = true
            end
        elseif (lastMotorState == MotorState.STARTING or lastMotorState == MotorState.ON) and (motorState == MotorState.OFF or motorState == MotorState.IGNITION) then
            stopMotor = true
        end
        if g_ignitionLockManager:getIsAvailable() then
            if motorState == MotorState.IGNITION then
                spec.motorStateIgnitionTime = g_currentMission.time
            elseif motorState == MotorState.OFF then
                spec.motorStateIgnitionTime = 0
            elseif (motorState == MotorState.STARTING or motorState == MotorState.ON) and spec.motorStateIgnitionTime == 0 then
                spec.motorStateIgnitionTime = g_currentMission.time
            end
        elseif (motorState == MotorState.STARTING or motorState == MotorState.ON) and spec.motorStateIgnitionTime == 0 then
            spec.motorStateIgnitionTime = g_currentMission.time
        elseif motorState == MotorState.OFF then
            spec.motorStateIgnitionTime = 0
        end
        if startMotor then
            if self.isClient then
                if spec.exhaustParticleSystems ~= nil then
                    for _, ps in pairs(spec.exhaustParticleSystems) do
                        ParticleUtil.setEmittingState(ps, true)
                    end
                end
                if spec.exhaustEffects ~= nil then
                    for _, ps in pairs(spec.exhaustEffects) do
                        setVisibility(ps.effectNode, true)
                        setShaderParameter(ps.effectNode, "param", ps.xRot, ps.zRot, 0, 0, false)
                        local color = ps.minRpmColor
                        setShaderParameter(ps.effectNode, "exhaustColor", color[1], color[2], color[3], color[4], false)
                    end
                end
                if spec.samples == nil then
                    Logging.error("Motor samples not found (%s, %d)", self.configFileName, self.loadingState)
                    printCallstack()
                end
                g_soundManager:stopSample(spec.samples.motorStop)
                g_soundManager:playSample(spec.samples.motorStart)
                g_soundManager:playSamples(spec.motorSamples, 0, spec.samples.motorStart)
                g_soundManager:playSamples(spec.gearboxSamples, 0, spec.samples.motorStart)
                g_soundManager:playSample(spec.samples.retarder, 0, spec.samples.motorStart)
                g_animationManager:startAnimations(spec.animationNodes)
                if spec.motorStartAnimation ~= nil then
                    self:playAnimation(spec.motorStartAnimation, 1, nil, true)
                end
                g_effectManager:startEffects(spec.effects)
            end
            spec.motorStartTime = g_currentMission.time + spec.motorStartDuration
            spec.motorNotRequiredTimer = 0
            spec.compressionSoundTime = g_currentMission.time + math.random(5000, 20000)
            spec.motor.lastMotorRpm = 0
            SpecializationUtil.raiseEvent(self, "onStartMotor")
            self.rootVehicle:raiseStateChange(VehicleStateChange.MOTOR_TURN_ON)
        elseif stopMotor then
            if self.isClient then
                if spec.exhaustParticleSystems ~= nil then
                    for _, ps in pairs(spec.exhaustParticleSystems) do
                        ParticleUtil.setEmittingState(ps, false)
                    end
                end
                if spec.exhaustEffects ~= nil then
                    for _, ps in pairs(spec.exhaustEffects) do
                        setVisibility(ps.effectNode, false)
                    end
                end
                for _, ps in ipairs(spec.exhaustFlaps) do
                    setRotation(ps.node, 0, 0, 0)
                end
                g_soundManager:stopSamples(spec.samples)
                g_soundManager:playSample(spec.samples.motorStop)
                g_soundManager:stopSamples(spec.motorSamples)
                g_soundManager:stopSamples(spec.gearboxSamples)
                spec.isBrakeSamplePlaying = false
                g_animationManager:stopAnimations(spec.animationNodes)
                if spec.motorStartAnimation ~= nil then
                    self:playAnimation(spec.motorStartAnimation, -1, nil, true)
                end
                g_effectManager:stopEffects(spec.effects)
            end
            SpecializationUtil.raiseEvent(self, "onStopMotor")
            self.rootVehicle:raiseStateChange(VehicleStateChange.MOTOR_TURN_OFF)
        end
    end
    if motorState == MotorState.ON or motorState == MotorState.STARTING then
        if self.isServer then
            self:wakeUp()
        end
    else
        spec.motor.lastMotorRpm = 0
    end
    if self.setDashboardsDirty ~= nil then
        self:setDashboardsDirty()
    end
end
function Motorized:startMotor(noEventSend)
    local motorState = self:getMotorState()
    if motorState == MotorState.OFF or motorState == MotorState.IGNITION then
        MotorSetTurnedOnEvent.sendEvent(self, true, noEventSend)
        self:setMotorState(MotorState.STARTING, true)
    end
end
function Motorized:stopMotor(noEventSend)
    local motorState = self:getMotorState()
    if motorState == MotorState.ON or motorState == MotorState.STARTING then
        MotorSetTurnedOnEvent.sendEvent(self, false, noEventSend)
        self:setMotorState(MotorState.OFF, true)
    end
end
function Motorized:updateConsumers(dt, accInput)
    local spec = self.spec_motorized
    local rpmPercentage = (spec.motor.lastMotorRpm - spec.motor.minRpm) / (spec.motor.maxRpm - spec.motor.minRpm)
    local motorFactor = spec.smoothedLoadPercentage * rpmPercentage
    local loadFactor = math.max(motorFactor, 0)
    local motorFactor = 0.5 * (0.2 * (0.5 + rpmPercentage * 0.5) + 1.8 * loadFactor)
    local missionInfo = g_currentMission.missionInfo
    local fuelUsage = missionInfo.fuelUsage
    local usageFactor = 1.5
    local usageFactor = fuelUsage == 1 and 1 or (fuelUsage == 3 and 2.5 or usageFactor)
    local damage = self:getVehicleDamage()
    if damage > 0 then
    end
    for _, consumer in pairs(spec.consumers) do
        if consumer.permanentConsumption and consumer.usage > 0 then
            local used = usageFactor * motorFactor * consumer.usage * dt
            if used ~= 0 then
                consumer.fillLevelToChange = consumer.fillLevelToChange + used
                local price = consumer.fillLevelToChange
                if math.abs(price) > 1 then
                    used = consumer.fillLevelToChange
                    consumer.fillLevelToChange = 0
                    local fillType = self:getFillUnitLastValidFillType(consumer.fillUnitIndex)
                    g_farmManager:updateFarmStats(self:getOwnerFarmId(), "fuelUsage", used)
                    if self:getIsAIActive() and (fillType == FillType.DIESEL or fillType == FillType.DEF) and missionInfo.helperBuyFuel then
                        if fillType == FillType.DIESEL then
                            local price = used * g_currentMission.economyManager:getCostPerLiter(fillType) * 1.5
                            g_farmManager:updateFarmStats(self:getOwnerFarmId(), "expenses", price)
                            g_currentMission:addMoney(-price, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, true)
                        end
                    end
                    if fillType == consumer.fillType then
                        self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, -used, fillType, ToolType.UNDEFINED)
                    end
                end
                if consumer.fillType == FillType.DIESEL or (consumer.fillType == FillType.ELECTRICCHARGE or consumer.fillType == FillType.METHANE) then
                    spec.lastFuelUsage = used / dt * 1000 * 60 * 60
                elseif consumer.fillType == FillType.DEF then
                    spec.lastDefUsage = used / dt * 1000 * 60 * 60
                end
            end
        end
    end
    if spec.consumersByFillTypeName.AIR ~= nil then
        local consumer = spec.consumersByFillTypeName.AIR
        if self:getFillUnitLastValidFillType(consumer.fillUnitIndex) == consumer.fillType then
            local usage = 0
            local _ = self.movingDirection * self:getReverserDirection()
            local consumer = false
            if _ > 0 then
                consumer = accInput < 0
            end
            local used = false
            if _ < 0 then
                used = accInput > 0
            end
            local fillType = false
            if self:getLastSpeed() > 1 then
                fillType = consumer or used
            end
            if fillType then
                local price = math.abs(accInput) * dt * self:getAirConsumerUsage() / 1000
                self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, -price, consumer.fillType, ToolType.UNDEFINED)
                usage = price / dt * 1000
            end
            local price = self:getFillUnitFillLevelPercentage(consumer.fillUnitIndex)
            if price < consumer.refillCapacityPercentage then
                consumer.doRefill = true
            elseif price == 1 then
                consumer.doRefill = false
            end
            if consumer.doRefill then
                local delta = consumer.refillLitersPerSecond / 1000 * dt
                self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, delta, consumer.fillType, ToolType.UNDEFINED)
                usage = -delta / dt * 1000
            end
            spec.lastAirUsage = usage
        end
    end
end
function Motorized:updateMotorTemperature(dt)
    local spec = self.spec_motorized
    local delta = spec.motorTemperature.heatingPerMS * dt * ((1 + 4 * spec.actualLoadPercentage) / 5 + self:getMotorRpmPercentage())
    spec.motorTemperature.value = math.min(spec.motorTemperature.valueMax, spec.motorTemperature.value + delta)
    local delta = spec.motorTemperature.coolingByWindPerMS * dt
    spec.motorTemperature.value = math.max(spec.motorTemperature.valueMin, spec.motorTemperature.value - math.pow(math.min(1, self:getLastSpeed() / 30), 2) * delta)
    if spec.motorTemperature.value > spec.motorFan.enableTemperature then
        spec.motorFan.enabled = true
    end
    if spec.motorFan.enabled and spec.motorTemperature.value < spec.motorFan.disableTemperature then
        spec.motorFan.enabled = false
    end
    if spec.motorFan.enabled then
        spec.motorTemperature.value = math.max(spec.motorTemperature.valueMin, spec.motorTemperature.value - spec.motorFan.coolingPerMS * dt)
    end
end
function Motorized:onGearDirectionChanged(_)
    if self.isServer then
        self:raiseDirtyFlags(self.spec_motorized.dirtyFlag)
    end
    if self.isClient and self.updateDashboardValueType ~= nil then
        self:updateDashboardValueType("motorized.gear")
        self:updateDashboardValueType("motorized.gearIndex")
    end
end
function Motorized:onGearChanged(gear, targetGear, changeTime, previousGear)
    self:setGearLeversState(targetGear, nil, changeTime)
    if self.isClient then
        if gear == 0 then
            if not g_soundManager:getIsSamplePlaying(self.spec_motorized.samples.gearDisengaged) then
                g_soundManager:playSample(spec.samples.gearDisengaged)
            end
        else
            if not g_soundManager:getIsSamplePlaying(spec.samples.gearEngaged) then
                g_soundManager:playSample(spec.samples.gearEngaged)
            end
            if previousGear ~= 0 and spec.motor.currentGears ~= nil then
                local lowRangeMax = math.ceil(#spec.motor.currentGears * 0.5)
                if (previousGear <= lowRangeMax and lowRangeMax < gear or gear <= lowRangeMax and lowRangeMax < previousGear) and not g_soundManager:getIsSamplePlaying(spec.samples.gearRangeChange) then
                    g_soundManager:playSample(spec.samples.gearRangeChange)
                end
            end
        end
    end
    if self.isServer then
        self:raiseDirtyFlags(spec.dirtyFlag)
    end
    if self.isClient and self.updateDashboardValueType ~= nil then
        self:updateDashboardValueType("motorized.gear")
        self:updateDashboardValueType("motorized.gearIndex")
    end
end
function Motorized:onGearGroupChanged(targetGroup, changeTime)
    self:setGearLeversState(nil, targetGroup, changeTime)
    local spec = self.spec_motorized
    if self.isClient and not g_soundManager:getIsSamplePlaying(spec.samples.gearGroupChange) then
        g_soundManager:playSample(spec.samples.gearGroupChange)
    end
    if self.isServer then
        self:raiseDirtyFlags(spec.dirtyFlag)
    end
    if self.isClient and self.updateDashboardValueType ~= nil then
        self:updateDashboardValueType("motorized.gearGroup")
        self:updateDashboardValueType("motorized.gearGroupIndex")
    end
end
function Motorized:onMotorBlowOffValveChanged(blowOffValveState)
    if blowOffValveState > 0 then
        self.spec_motorized.blowOffValveState = blowOffValveState
        if not g_soundManager:getIsSamplePlaying(spec.samples.blowOffValve) then
            g_soundManager:playSample(spec.samples.blowOffValve)
            return
        end
    elseif g_soundManager:getIsSamplePlaying(spec.samples.blowOffValve) then
        g_soundManager:stopSample(spec.samples.blowOffValve)
    end
end
function Motorized:onClutchCreaking(isEvent, groupTransmission, gearIndex, groupIndex)
    local spec = self.spec_motorized
    if self:getIsActiveForInput(true) then
        if groupTransmission then
            g_currentMission:showBlinkingWarning(spec.clutchCrackingGroupWarning, 2000)
        else
            g_currentMission:showBlinkingWarning(spec.clutchCrackingGearWarning, 2000)
        end
    end
    if not g_soundManager:getIsSamplePlaying(spec.samples.clutchCracking) then
        g_soundManager:playSample(spec.samples.clutchCracking)
    end
    if gearIndex ~= nil then
        self:setGearLeversState(gearIndex, nil, 500, false)
        spec.clutchCrackingGearIndex = gearIndex
    end
    if groupIndex ~= nil then
        self:setGearLeversState(nil, groupIndex, 500, false)
        spec.clutchCrackingGroupIndex = groupIndex
    end
    spec.clutchCrackingTimeOut = g_time + (isEvent and 750 or 100)
    if g_server ~= nil then
        g_server:broadcastEvent(MotorClutchCreakingEvent.new(self, isEvent, groupTransmission, gearIndex, groupIndex), nil, nil, self)
    end
end
function Motorized:onReverseDirectionChanged()
    if self:getDirectionChangeMode() == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL then
        MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE)
    end
end
function Motorized:onVehicleSettingChanged(gameSettingId, state)
    local spec = self.spec_motorized
    if gameSettingId == GameSettings.SETTING.DIRECTION_CHANGE_MODE then
        spec.directionChangeMode = state
        if spec.motor ~= nil then
            motor:setDirectionChangeMode(state)
            self:requestActionEventUpdate()
        end
    end
    if gameSettingId == GameSettings.SETTING.GEAR_SHIFT_MODE then
        spec.gearShiftMode = state
        if not self:getIsAIActive() and motor ~= nil then
            motor:setGearShiftMode(state)
            self:requestActionEventUpdate()
        end
    end
end
function Motorized:onAIJobStarted(_)
    local spec = self.spec_motorized
    self:startMotor(true)
    if spec.motor ~= nil then
        spec.motor:setGearShiftMode(VehicleMotor.SHIFT_MODE_AUTOMATIC)
    end
end
function Motorized:onAIJobFinished(_)
    if self.getIsControlled == nil or not self:getIsControlled() then
        self:stopMotor(true)
    end
    local spec = self.spec_motorized
    if spec.motor ~= nil then
        spec.motor:setGearShiftMode(spec.gearShiftMode)
    end
end
function Motorized:getMotor()
    return self.spec_motorized.motor
end
function Motorized:getMotorStartTime()
    return self.spec_motorized.motorStartTime
end
function Motorized:getMotorType()
    return self.spec_motorized.motorType
end
function Motorized:getMotorRpmPercentage()
    local motor = self.spec_motorized.motor
    return (motor:getLastModulatedMotorRpm() - motor:getMinRpm()) / (motor:getMaxRpm() - motor:getMinRpm())
end
g_soundManager:registerModifierType("MOTOR_RPM", Motorized.getMotorRpmPercentage)
function Motorized:getMotorRpmReal()
    return self.spec_motorized.motor:getLastModulatedMotorRpm()
end
g_soundManager:registerModifierType("MOTOR_RPM_REAL", Motorized.getMotorRpmReal)
function Motorized:getMotorLoadPercentage()
    return self.spec_motorized.smoothedLoadPercentage
end
g_soundManager:registerModifierType("MOTOR_LOAD", Motorized.getMotorLoadPercentage)
function Motorized:getMotorBrakeTime()
    local sample = self.spec_motorized.samples.compressedAir
    return sample == nil and 0 or sample.lastBrakeTime / 1000
end
g_soundManager:registerModifierType("BRAKE_TIME", Motorized.getMotorBrakeTime)
function Motorized:getMotorBlowOffValveState()
    return self.spec_motorized.blowOffValveState
end
g_soundManager:registerModifierType("BLOW_OFF_VALVE_STATE", Motorized.getMotorBlowOffValveState)
function Motorized:getMotorDifferentialSpeed()
    if self.spec_motorized == nil then
        Logging.error("Sound modifier \'DIFFERENTIAL_SPEED\' used on non motorized vehicle \'%s\'", self.configFileName)
        return 0
    else
        return math.abs(self.spec_motorized.motor.differentialRotSpeed * 3.6)
    end
end
g_soundManager:registerModifierType("DIFFERENTIAL_SPEED", Motorized.getMotorDifferentialSpeed)
function Motorized:getConsumerFillUnitIndex(fillTypeIndex)
    local consumer = self.spec_motorized.consumersByFillType[fillTypeIndex]
    if consumer == nil then
        return nil
    else
        return consumer.fillUnitIndex
    end
end
function Motorized:getAirConsumerUsage()
    local consumer = self.spec_motorized.consumersByFillTypeName.AIR
    return consumer and consumer.usage or 0
end
function Motorized:getBrakeForce(superFunc)
    local brakeForce = superFunc(self)
    local spec = self.spec_motorized
    local mass
    if spec.maxBrakeForceMass > 0 then
        local percentage = math.min(math.max((self:getTotalMass(not spec.maxBrakeForceMassIncludeAttachables) - self.defaultMass) / (spec.maxBrakeForceMass - self.defaultMass), 0), 1)
        mass = math.max(MathUtil.lerp(spec.minBrakeForce, spec.maxBrakeForce, percentage), brakeForce)
    else
        mass = self.spec_motorized.motor:getBrakeForce()
    end
    return math.max(brakeForce, mass)
end
function Motorized:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
    if not superFunc(self, xmlFile, key, group) then
        return false
    end
    group.isMotorStarting = xmlFile:getValue(key .. "#isMotorStarting")
    group.isMotorRunning = xmlFile:getValue(key .. "#isMotorRunning")
    group.electronicsStarting = xmlFile:getValue(key .. "#electronicsStarting", false)
    group.electronicsStartingTime = xmlFile:getValue(key .. "#electronicsStartingTime", 2)
    group.electronicsRunning = xmlFile:getValue(key .. "#electronicsRunning", false)
    return true
end
function Motorized:getIsDashboardGroupActive(superFunc, group)
    local motorState = self:getMotorState()
    if group.isMotorRunning and (group.isMotorStarting and (motorState ~= MotorState.STARTING and motorState ~= MotorState.ON)) then
        return false
    end
    if group.isMotorStarting and (not group.isMotorRunning and motorState ~= MotorState.STARTING) then
        return false
    end
    if group.isMotorRunning and (not group.isMotorStarting and motorState ~= MotorState.ON) then
        return false
    end
    if group.electronicsStarting and group.electronicsRunning then
        if self.spec_motorized.motorStateIgnitionTime == 0 then
            return false
        end
    elseif group.electronicsStarting then
        local spec = self.spec_motorized
        if spec.motorStateIgnitionTime == 0 or g_currentMission.time - spec.motorStateIgnitionTime > group.electronicsStartingTime then
            return false
        end
    elseif group.electronicsRunning then
        local spec = self.spec_motorized
        if spec.motorStateIgnitionTime == 0 or g_currentMission.time - spec.motorStateIgnitionTime < group.electronicsStartingTime then
            return false
        end
    end
    return superFunc(self, group)
end
function Motorized:getIsActiveForInteriorLights(superFunc)
    local state = self:getMotorState()
    return (state == MotorState.IGNITION or (state == MotorState.STARTING or state == MotorState.ON)) and true or superFunc(self)
end
function Motorized:getIsActiveForWipers(superFunc)
    if self:getMotorState() == MotorState.OFF then
        return false
    else
        return superFunc(self)
    end
end
function Motorized:getUsageCausesDamage(superFunc)
    local motorState = self:getMotorState()
    if motorState == MotorState.STARTING or motorState == MotorState.ON then
        return superFunc(self)
    else
        return false
    end
end
function Motorized:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    if self.isServer then
        local spec = self.spec_motorized
        if spec.motorizedNode ~= nil and next(spec.differentials) ~= nil then
            for _, differential in pairs(spec.differentials) do
                local diffIndex1 = differential.diffIndex1
                local diffIndex2 = differential.diffIndex2
                if differential.diffIndex1IsWheel then
                    diffIndex1 = self:getWheelFromWheelIndex(diffIndex1).physics.wheelShape
                end
                if differential.diffIndex2IsWheel then
                    diffIndex2 = self:getWheelFromWheelIndex(diffIndex2).physics.wheelShape
                end
                addDifferential(spec.motorizedNode, diffIndex1, differential.diffIndex1IsWheel, diffIndex2, differential.diffIndex2IsWheel, differential.torqueRatio, differential.maxSpeedRatio)
            end
            self:updateMotorProperties()
            self:controlVehicle(0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
        end
    end
    return true
end
function Motorized:removeFromPhysics(superFunc)
    if self.isServer then
        local spec = self.spec_motorized
        if spec.motorizedNode ~= nil and next(spec.differentials) ~= nil then
            removeAllDifferentials(spec.motorizedNode)
        end
    end
    return superFunc(self) and true or false
end
function Motorized:updateMotorProperties()
    local spec = self.spec_motorized
    local motor = spec.motor
    local torques, rotationSpeeds = motor:getTorqueAndSpeedValues()
    setMotorProperties(spec.motorizedNode, motor:getMinRpm() * 3.141592653589793 / 30, motor:getMaxRpm() * 3.141592653589793 / 30, motor:getRotInertia(), motor:getDampingRateFullThrottle(), motor:getDampingRateZeroThrottleClutchEngaged(), motor:getDampingRateZeroThrottleClutchDisengaged(), rotationSpeeds, torques)
end
function Motorized:controlVehicle(acceleratorPedal, maxSpeed, maxAcceleration, minMotorRotSpeed, maxMotorRotSpeed, maxMotorRotAcceleration, minGearRatio, maxGearRatio, maxClutchTorque, neededPtoTorque)
    local spec = self.spec_motorized
    controlVehicle(spec.motorizedNode, acceleratorPedal, maxSpeed, maxAcceleration, minMotorRotSpeed, maxMotorRotSpeed, maxMotorRotAcceleration, minGearRatio, maxGearRatio, maxClutchTorque, neededPtoTorque)
    local lastParameters = spec.lastControlParameters
    if getIsSleeping(spec.motorizedNode) and (acceleratorPedal ~= lastParameters.acceleratorPedal or (maxSpeed ~= lastParameters.maxSpeed or (maxAcceleration ~= lastParameters.maxAcceleration or (minMotorRotSpeed ~= lastParameters.minMotorRotSpeed or (maxMotorRotSpeed ~= lastParameters.maxMotorRotSpeed or (maxMotorRotAcceleration ~= lastParameters.maxMotorRotAcceleration or (minGearRatio ~= lastParameters.minGearRatio or (maxGearRatio ~= lastParameters.maxGearRatio or (maxClutchTorque ~= lastParameters.maxClutchTorque or neededPtoTorque ~= lastParameters.neededPtoTorque))))))))) then
        I3DUtil.wakeUpObject(spec.motorizedNode)
    end
    lastParameters.acceleratorPedal = acceleratorPedal
    lastParameters.maxSpeed = maxSpeed
    lastParameters.maxAcceleration = maxAcceleration
    lastParameters.minMotorRotSpeed = minMotorRotSpeed
    lastParameters.maxMotorRotSpeed = maxMotorRotSpeed
    lastParameters.maxMotorRotAcceleration = maxMotorRotAcceleration
    lastParameters.minGearRatio = minGearRatio
    lastParameters.maxGearRatio = maxGearRatio
    lastParameters.maxClutchTorque = maxClutchTorque
    lastParameters.neededPtoTorque = neededPtoTorque
end
function Motorized:getIsOperating(superFunc)
    local motorState = self:getMotorState()
    return superFunc(self) or motorState == MotorState.ON
end
function Motorized:getDeactivateOnLeave(superFunc)
    return superFunc(self) and g_currentMission.missionInfo.automaticMotorStartEnabled
end
function Motorized:getDeactivateLightsOnLeave(superFunc)
    return superFunc(self) and g_currentMission.missionInfo.automaticMotorStartEnabled and not self:getRequiresPower()
end
function Motorized:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_motorized
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_MOTOR_STATE, self, Motorized.actionEventToggleMotorState, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            g_inputBinding:setActionEventText(actionEventId, spec.turnOnText)
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.MOTOR_STATE_IGNITION, self, Motorized.actionEventSetMotorStateIgnition, false, true, false, true, nil)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.MOTOR_STATE_ON, self, Motorized.actionEventSetMotorStateOn, false, true, false, true, nil)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.MOTOR_STATE_OFF, self, Motorized.actionEventSetMotorStateOff, false, true, false, true, nil)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            if (spec.motor.minForwardGearRatio == nil or spec.motor.minBackwardGearRatio == nil) and (self:getGearShiftMode() ~= VehicleMotor.SHIFT_MODE_AUTOMATIC or not GS_IS_CONSOLE_VERSION) then
                if spec.motor.manualShiftGears then
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_UP, self, Motorized.actionEventShiftGear, false, true, false, true, nil)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_DOWN, self, Motorized.actionEventShiftGear, false, true, false, true, nil)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_1, self, Motorized.actionEventSelectGear, true, true, false, true, 1)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_2, self, Motorized.actionEventSelectGear, true, true, false, true, 2)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_3, self, Motorized.actionEventSelectGear, true, true, false, true, 3)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_4, self, Motorized.actionEventSelectGear, true, true, false, true, 4)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_5, self, Motorized.actionEventSelectGear, true, true, false, true, 5)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_6, self, Motorized.actionEventSelectGear, true, true, false, true, 6)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_7, self, Motorized.actionEventSelectGear, true, true, false, true, 7)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_8, self, Motorized.actionEventSelectGear, true, true, false, true, 8)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                end
                if spec.motor.manualShiftGroups and spec.motor.gearGroups ~= nil then
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_UP, self, Motorized.actionEventShiftGroup, false, true, false, true, nil)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_DOWN, self, Motorized.actionEventShiftGroup, false, true, false, true, nil)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_1, self, Motorized.actionEventSelectGroup, true, true, false, true, 1)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_2, self, Motorized.actionEventSelectGroup, true, true, false, true, 2)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_3, self, Motorized.actionEventSelectGroup, true, true, false, true, 3)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_4, self, Motorized.actionEventSelectGroup, true, true, false, true, 4)
                    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                end
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_CLUTCH_VEHICLE, self, Motorized.actionEventClutch, false, false, true, true, nil)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            end
            if self:getDirectionChangeMode() == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL or self:getGearShiftMode() ~= VehicleMotor.SHIFT_MODE_AUTOMATIC then
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DIRECTION_CHANGE, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, nil, true)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DIRECTION_CHANGE_POS, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, nil, true)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DIRECTION_CHANGE_NEG, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, nil, true)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            end
            Motorized.updateActionEvents(self)
        end
    end
end
function Motorized:actionEventShiftGear(actionName, _, _, _)
    if actionName == InputAction.SHIFT_GEAR_UP then
        MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SHIFT_UP)
    else
        MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SHIFT_DOWN)
    end
end
function Motorized:actionEventSelectGear(actionName, inputValue, callbackState, _)
    local gears = self.spec_motorized.motor.currentGears
    if gears ~= nil then
        local i = 1
        for i = i, #gears do
            if gears[i].inputAction == InputAction[actionName] then
                MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SELECT_GEAR, inputValue == 1 and i and i or 0)
                return
            end
        end
    end
    return MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SELECT_GEAR, inputValue == 1 and callbackState and callbackState or 0)
end
function Motorized:actionEventShiftGroup(actionName, _, _, _)
    if actionName == InputAction.SHIFT_GROUP_UP then
        MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SHIFT_GROUP_UP)
    else
        MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SHIFT_GROUP_DOWN)
    end
end
function Motorized:actionEventSelectGroup(actionName, inputValue, callbackState, _)
    local groups = self.spec_motorized.motor.gearGroups
    if groups ~= nil then
        local i = 1
        for i = i, #groups do
            if groups[i].inputAction == InputAction[actionName] then
                MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SELECT_GROUP, inputValue == 1 and i and i or 0)
                return
            end
        end
    end
    return MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_SELECT_GROUP, inputValue == 1 and callbackState and callbackState or 0)
end
function Motorized:actionEventDirectionChange(actionName, _, _, _)
    if actionName == InputAction.DIRECTION_CHANGE_POS then
        MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_POS)
        return
    elseif actionName == InputAction.DIRECTION_CHANGE_NEG then
        MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_NEG)
    else
        MotorGearShiftEvent.sendToServer(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE)
    end
end
function Motorized:actionEventClutch(_, inputValue, _, _)
    local spec = self.spec_motorized
    spec.clutchState = inputValue
    if self.isServer then
        spec.motor:onManualClutchChanged(spec.clutchState)
        if inputValue > 0 then
            self:raiseActive()
            return
        end
    else
        self:raiseDirtyFlags(spec.inputDirtyFlag)
    end
end
function Motorized:updateActionEvents()
    local spec = self.spec_motorized
    local actionEvent = spec.actionEvents[InputAction.TOGGLE_MOTOR_STATE]
    if actionEvent ~= nil then
        if g_currentMission.missionInfo.automaticMotorStartEnabled then
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
        else
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)
            local motorState = self:getMotorState()
            local text
            if motorState == MotorState.STARTING or motorState == MotorState.ON then
                g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_VERY_LOW)
                text = spec.turnOffText
            else
                g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_VERY_HIGH)
                text = spec.turnOnText
            end
            g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
        end
    end
    local actionEvent = spec.actionEvents[InputAction.MOTOR_STATE_IGNITION]
    if actionEvent ~= nil then
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, not automaticMotorStartEnabled)
    end
    local actionEvent = spec.actionEvents[InputAction.MOTOR_STATE_ON]
    if actionEvent ~= nil then
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, not automaticMotorStartEnabled)
    end
    local actionEvent = spec.actionEvents[InputAction.MOTOR_STATE_OFF]
    if actionEvent ~= nil then
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, not automaticMotorStartEnabled)
    end
end
function Motorized:getTraveledDistanceStatsActive()
    return true
end
function Motorized:setGearLeversState(gear, group, time, isResetPosition)
    local spec = self.spec_motorized
    local i = 1
    for i = i, #spec.gearLevers do
        local gearLever = spec.gearLevers[i]
        local j = 1
        for j = j, #gearLever.states do
            local state = gearLever.states[j]
            if state.gear ~= nil and state.gear == gear or state.group ~= nil and state.group == group then
                self:generateShiftAnimation(gearLever, state, time, isResetPosition)
            end
        end
    end
end
function Motorized:generateShiftAnimation(gearLever, state, _, isResetPosition)
    local requiresChange = state.curRotation
    local alreadyMovingToTarget = state.curRotation
    local requiresMoveToCenter = state.curRotation
    local axis, axis, axis = getRotation(gearLever.node)
    requiresChange[1] = axis
    alreadyMovingToTarget[2] = axis
    requiresMoveToCenter[3] = axis
    local requiresChange = false
    local axis = 1
    local alreadyMovingToTarget = 3
    local requiresMoveToCenter = 1
    for axis = axis, alreadyMovingToTarget, requiresMoveToCenter do
        if math.abs(state.curRotation[axis] - state.rotation[axis]) > 0.00001 then
            requiresChange = true
            break
        end
    end
    local alreadyMovingToTarget = true
    local axis = 1
    local requiresMoveToCenter = 3
    local axis = 1
    for axis = axis, requiresMoveToCenter, axis do
        if math.abs(gearLever.curTarget[axis] - state.rotation[axis]) > 0.00001 then
            alreadyMovingToTarget = false
            break
        end
    end
    if not requiresChange or alreadyMovingToTarget then
        return false
    end
    local requiresMoveToCenter = gearLever.curTarget
    local axis = gearLever.curTarget
    local axis = gearLever.curTarget
    local axis = state.curRotation[1]
    local cur = state.curRotation[2]
    local tar = state.curRotation[3]
    requiresMoveToCenter[1] = axis
    axis[2] = cur
    axis[3] = tar
    local requiresMoveToCenter = false
    if gearLever.centerAxis ~= nil then
        requiresMoveToCenter = math.abs(state.curRotation[gearLever.centerAxis] - state.rotation[gearLever.centerAxis]) > 0.00001
    end
    if requiresMoveToCenter then
        local axis = 1
        local axis = 3
        local axis = 1
        for axis = axis, axis, axis do
            if axis ~= gearLever.centerAxis then
                local cur = state.curRotation[axis]
                local tar = state.rotation[axis]
                local tar = gearLever.centerAxis ~= nil and 0 or tar
                local allowed = math.abs(cur - tar) > 0.00001
                local goToCenter = false
                if gearLever.centerAxis ~= nil and not allowed then
                    allowed = state.useRotation[axis]
                    if allowed then
                        allowed = math.abs(state.curRotation[gearLever.centerAxis] - state.rotation[gearLever.centerAxis]) > 0.00001
                    end
                    goToCenter = allowed
                end
                if allowed then
                    table.insert(({
                        ["interpolations"] = {}
                    }).interpolations, {
                        ["axis"] = axis,
                        ["cur"] = cur,
                        ["tar"] = goToCenter and 0 or tar
                    })
                    gearLever.curTarget[axis] = tar
                end
            end
        end
    end
    if gearLever.centerAxis ~= nil then
        if requiresMoveToCenter then
            table.insert(gearLeverInterpolator.interpolations, {
                ["axis"] = gearLever.centerAxis,
                ["cur"] = state.curRotation[gearLever.centerAxis],
                ["tar"] = state.rotation[gearLever.centerAxis]
            })
            gearLever.curTarget[gearLever.centerAxis] = axis
        end
        local axis = 1
        local axis = 3
        local axis = 1
        for axis = axis, axis, axis do
            if axis ~= gearLever.centerAxis then
                local cur = state.curRotation[axis]
                local tar = state.rotation[axis]
                local allowed = math.abs(cur - tar) > 0.00001
                if gearLever.centerAxis ~= nil and not allowed then
                    allowed = state.useRotation[axis]
                    if allowed then
                        allowed = math.abs(state.curRotation[gearLever.centerAxis] - state.rotation[gearLever.centerAxis]) > 0.00001
                    end
                end
                if allowed then
                    table.insert(gearLeverInterpolator.interpolations, {
                        ["axis"] = axis,
                        ["cur"] = requiresMoveToCenter and 0 or cur,
                        ["tar"] = tar
                    })
                    gearLever.curTarget[axis] = tar
                end
            end
        end
    end
    for cur, tar in pairs(self.spec_motorized.activeGearLeverInterpolators) do
        if cur.gearLever == state.gearLever then
            self.spec_motorized.activeGearLeverInterpolators[cur] = nil
        end
    end
    if self.spec_motorized.activeGearLeverInterpolators[state] == nil then
        local axis = #gearLeverInterpolator.interpolations
        if axis > 0 then
            local axis = math.max(gearLever.changeTime, 0.001) / axis
            local tar = 1
            for tar = tar, axis do
                local allowed = gearLeverInterpolator.interpolations[tar]
                allowed.speed = (allowed.tar - allowed.cur) / axis
            end
            gearLeverInterpolator.currentInterpolation = 1
            local axis = true
            if isResetPosition ~= nil then
                axis = isResetPosition == true
            end
            gearLeverInterpolator.isResetPosition = axis
            gearLeverInterpolator.handsOnDelay = gearLever.handsOnDelay
            local axis = state.gear ~= nil
            gearLeverInterpolator.isGear = axis
            self.spec_motorized.activeGearLeverInterpolators[state] = gearLeverInterpolator
        end
    end
    return true
end
function Motorized:getGearInfoToDisplay()
    local gear = nil
    local gearGroup = nil
    local gearsAvailable = nil
    local isAutomatic = nil
    local prevGearName = nil
    local nextGearName = nil
    local prevPrevGearName = nil
    local nextNextGearName = nil
    local isGearChanging = nil
    local showNeutralWarning = false
    local motor = self.spec_motorized.motor
    if motor ~= nil then
        gear, gearsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging = motor:getGearInfoToDisplay()
        local groupsAvailable
        gearGroup, groupsAvailable = motor:getGearGroupToDisplay()
        if not groupsAvailable then
            gearGroup = nil
        end
        if self.getAcDecelerationAxis ~= nil then
            if math.abs((self:getAcDecelerationAxis())) > 0 then
                showNeutralWarning = self:getIsMotorInNeutral()
            end
        end
    end
    return gear, gearGroup, gearsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging, showNeutralWarning
end
function Motorized:setTransmissionDirection(direction)
    local motor = self.spec_motorized.motor
    if motor ~= nil then
        motor:setTransmissionDirection(direction)
    end
end
function Motorized:getDirectionChangeMode()
    return self.spec_motorized.directionChangeMode
end
function Motorized:getIsManualDirectionChangeAllowed()
    return not self:getIsAIActive()
end
function Motorized:getIsManualDirectionChangeActive()
    local motor = self.spec_motorized.motor
    local isManualTransmission = true
    if motor.backwardGears == nil then
        isManualTransmission = motor.forwardGears ~= nil
    end
    local useManualDirectionChange
    if isManualTransmission then
        useManualDirectionChange = true
        if motor.gearShiftMode ~= VehicleMotor.SHIFT_MODE_AUTOMATIC then
            ::l7::
            if useManualDirectionChange then
                useManualDirectionChange = self:getIsManualDirectionChangeAllowed()
            end
            return useManualDirectionChange
        end
    end
    useManualDirectionChange = motor.directionChangeMode == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL
    goto l7
end
function Motorized:getGearShiftMode()
    return self.spec_motorized.gearShiftMode
end
function Motorized:onStateChange(state, _, _)
    if state == VehicleStateChange.ENTER_VEHICLE then
        if g_currentMission.missionInfo.automaticMotorStartEnabled and (not g_ignitionLockManager:getIsAvailable() and self:getCanMotorRun()) then
            self:startMotor(true)
            return
        end
    elseif state == VehicleStateChange.LEAVE_VEHICLE then
        if self:getStopMotorOnLeave() and missionInfo.automaticMotorStartEnabled then
            self:stopMotor(true)
        end
        self:stopVehicle()
    end
end
function Motorized:stopVehicle()
    if self.isServer and self.spec_motorized.motorizedNode ~= nil then
        self:controlVehicle(0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
    end
end
function Motorized:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, _, _, _)
    if fillLevelDelta > 0 and fillType == FillType.DIESEL then
        local factor = self:getFillUnitFillLevel(fillUnitIndex) / self:getFillUnitCapacity(fillUnitIndex)
        local defFillUnitIndex = self:getConsumerFillUnitIndex(FillType.DEF)
        if defFillUnitIndex ~= nil then
            local delta = self:getFillUnitCapacity(defFillUnitIndex) * factor - self:getFillUnitFillLevel(defFillUnitIndex)
            self:addFillUnitFillLevel(self:getOwnerFarmId(), defFillUnitIndex, delta, FillType.DEF, ToolType.UNDEFINED, nil)
        end
    end
end
function Motorized:onSetBroken()
    self:stopMotor(true)
end
function Motorized:getName(superFunc)
    if self.spec_motorized.vehicleName == nil then
        return superFunc(self)
    else
        return self.spec_motorized.vehicleName
    end
end
function Motorized:getCanBeSelected(superFunc)
    if not g_currentMission.missionInfo.automaticMotorStartEnabled then
        local vehicles = self.rootVehicle:getChildVehicles()
        for _, vehicle in pairs(vehicles) do
            if vehicle.spec_motorized ~= nil then
                return true
            end
        end
    end
    return superFunc(self)
end
function Motorized:getIsPowered(superFunc)
    local ret = superFunc(self)
    if ret then
        local motorState = self:getMotorState()
        if motorState ~= MotorState.STARTING and motorState ~= MotorState.ON then
            local vehicles = self.rootVehicle:getChildVehicles()
            for _, vehicle in pairs(vehicles) do
                if vehicle ~= self and vehicle.getMotorState ~= nil then
                    local vehicleMotorState = vehicle:getMotorState()
                    if vehicleMotorState == MotorState.STARTING or vehicleMotorState == MotorState.ON then
                        return true
                    end
                end
            end
            if self:getCanMotorRun() then
                return false, g_i18n:getText("warning_motorNotStarted")
            else
                return false, self:getMotorNotAllowedWarning()
            end
        end
    end
    return ret
end
function Motorized.tryStartMotor(vehicle)
    local i = 1
    for i = i, #vehicle.rootVehicle.childVehicles do
        local otherVehicle = vehicle.rootVehicle.childVehicles[i]
        if otherVehicle.getCanMotorRun ~= nil and otherVehicle:getCanMotorRun() then
            otherVehicle:startMotor()
        end
    end
end
function Motorized:actionEventToggleMotorState(_, _, _, _)
    if not self:getIsAIActive() then
        local motorState = self:getMotorState()
        if motorState == MotorState.STARTING or motorState == MotorState.ON then
            self:stopMotor()
            return
        end
        if self:getCanMotorRun() then
            self:startMotor()
            return
        end
        local warning = self:getMotorNotAllowedWarning()
        if warning ~= nil then
            g_currentMission:showBlinkingWarning(warning, 2000)
        end
    end
end
function Motorized:actionEventSetMotorStateIgnition(_, _, _, _)
    if not self:getIsAIActive() and self:getMotorState() == MotorState.OFF then
        self:setMotorState(MotorState.IGNITION)
    end
end
function Motorized:actionEventSetMotorStateOn(_, _, _, _)
    if not self:getIsAIActive() then
        local motorState = self:getMotorState()
        if motorState == MotorState.OFF or motorState == MotorState.IGNITION then
            if self:getCanMotorRun() then
                self:startMotor()
                return
            end
            local warning = self:getMotorNotAllowedWarning()
            if warning ~= nil then
                g_currentMission:showBlinkingWarning(warning, 2000)
            end
        end
    end
end
function Motorized:actionEventSetMotorStateOff(_, _, _, _)
    if not self:getIsAIActive() and self:getMotorState() ~= MotorState.OFF then
        self:stopMotor()
    end
end
function Motorized.loadSpecValueFuel(xmlFile, _, _)
    local rootName = xmlFile:getRootName()
    local fillUnits = {}
    local i = 0
    while true do
        local configKey = string.format(rootName .. ".fillUnit.fillUnitConfigurations.fillUnitConfiguration(%d)", i)
        if not xmlFile:hasProperty(configKey) then
            break
        end
        local configFillUnits = {}
        local j = 0
        while true do
            local fillUnitKey = string.format(configKey .. ".fillUnits.fillUnit(%d)", j)
            if not xmlFile:hasProperty(fillUnitKey) then
                break
            end
            table.insert(configFillUnits, {
                ["fillTypes"] = xmlFile:getValue(fillUnitKey .. "#fillTypes"),
                ["capacity"] = xmlFile:getValue(fillUnitKey .. "#capacity")
            })
            j = j + 1
        end
        table.insert(fillUnits, configFillUnits)
        i = i + 1
    end
    local configKey = {}
    local i = 0
    while true do
        local configFillUnits = string.format(rootName .. ".motorized.consumerConfigurations.consumerConfiguration(%d)", i)
        if not xmlFile:hasProperty(configFillUnits) then
            break
        end
        local j = {}
        local fillUnitKey = 0
        while true do
            local fillTypes = string.format(configFillUnits .. ".consumer(%d)", fillUnitKey)
            if not xmlFile:hasProperty(fillTypes) then
                break
            end
            table.insert(j, {
                ["fillType"] = xmlFile:getValue(fillTypes .. "#fillType"),
                ["fillUnitIndex"] = xmlFile:getValue(fillTypes .. "#fillUnitIndex"),
                ["capacity"] = xmlFile:getValue(fillTypes .. "#capacity")
            })
            fillUnitKey = fillUnitKey + 1
        end
        table.insert(configKey, j)
        i = i + 1
    end
    return {
        ["fillUnits"] = fillUnits,
        ["consumers"] = configKey
    }
end
function Motorized.getSpecValueFuelDiesel(storeItem, realItem, configurations)
    return Motorized.getSpecValueFuel(storeItem, realItem, configurations, FillType.DIESEL)
end
function Motorized.getSpecValueFuelElectricCharge(storeItem, realItem, configurations)
    return Motorized.getSpecValueFuel(storeItem, realItem, configurations, FillType.ELECTRICCHARGE)
end
function Motorized.getSpecValueFuelMethane(storeItem, realItem, configurations)
    return Motorized.getSpecValueFuel(storeItem, realItem, configurations, FillType.METHANE)
end
function Motorized.getSpecValueFuel(storeItem, realItem, configurations, fillTypeFilter, returnValue)
    local consumerIndex = 1
    if realItem == nil or (storeItem.configurations == nil or (realItem.configurations.motor == nil or storeItem.configurations.motor == nil)) then
        if configurations ~= nil then
            local motorConfigId = configurations.motor
            if motorConfigId ~= nil then
                consumerIndex = Utils.getNoNil(storeItem.configurations.motor[motorConfigId].consumerConfigurationIndex, consumerIndex)
            end
        end
    else
        consumerIndex = Utils.getNoNil(storeItem.configurations.motor[realItem.configurations.motor].consumerConfigurationIndex, consumerIndex)
    end
    local motorConfigId = nil
    local def = nil
    local electricCharge = nil
    local methane = nil
    local fuelFillUnitIndex = 0
    local defFillUnitIndex = 0
    local electricFillUnitIndex = 0
    local methaneFillUnitIndex = 0
    local consumerConfiguration = storeItem.specs.fuel
    if consumerConfiguration then
        consumerConfiguration = storeItem.specs.fuel.consumers[consumerIndex]
    end
    if consumerConfiguration ~= nil then
        for _, unitConsumers in ipairs(consumerConfiguration) do
            local fillType = g_fillTypeManager:getFillTypeIndexByName(unitConsumers.fillType)
            if fillTypeFilter == nil or fillType == fillTypeFilter then
                if fillType == FillType.DIESEL then
                    fuelFillUnitIndex = unitConsumers.fillUnitIndex
                    motorConfigId = unitConsumers.capacity
                    if fillType == FillType.DEF then
                        defFillUnitIndex = unitConsumers.fillUnitIndex
                        def = unitConsumers.capacity
                    end
                elseif fillType == FillType.DEF then
                    defFillUnitIndex = unitConsumers.fillUnitIndex
                    def = unitConsumers.capacity
                elseif fillType == FillType.ELECTRICCHARGE then
                    electricFillUnitIndex = unitConsumers.fillUnitIndex
                    electricCharge = unitConsumers.capacity
                elseif fillType == FillType.METHANE then
                    methaneFillUnitIndex = unitConsumers.fillUnitIndex
                    methane = unitConsumers.capacity
                end
            end
        end
    end
    local fuelConfigIndex = 1
    if realItem ~= nil and (storeItem.configurations ~= nil and (realItem.configurations.fillUnit ~= nil and storeItem.configurations.fillUnit ~= nil)) then
        fuelConfigIndex = realItem.configurations.fillUnit
    end
    if storeItem.specs.fuel and storeItem.specs.fuel.fillUnits[fuelConfigIndex] ~= nil then
        if realItem == nil or realItem.getFillUnitCapacity == nil then
            local fuelFillUnit = storeItem.specs.fuel.fillUnits[fuelConfigIndex][fuelFillUnitIndex]
            if fuelFillUnit ~= nil and motorConfigId == nil then
                motorConfigId = math.max(fuelFillUnit.capacity, motorConfigId or 0)
            end
            local defFillUnit = storeItem.specs.fuel.fillUnits[fuelConfigIndex][defFillUnitIndex]
            if defFillUnit ~= nil and def == nil then
                def = math.max(defFillUnit.capacity, def or 0)
            end
            local _ = storeItem.specs.fuel.fillUnits[fuelConfigIndex][electricFillUnitIndex]
            if _ ~= nil and electricCharge == nil then
                electricCharge = math.max(_.capacity, electricCharge or 0)
            end
            local unitConsumers = storeItem.specs.fuel.fillUnits[fuelConfigIndex][methaneFillUnitIndex]
            if unitConsumers ~= nil and methane == nil then
                methane = math.max(unitConsumers.capacity, methane or 0)
            end
        else
            if fuelFillUnitIndex ~= 0 then
                motorConfigId = realItem:getFillUnitCapacity(fuelFillUnitIndex)
            end
            if defFillUnitIndex ~= 0 then
                def = realItem:getFillUnitCapacity(defFillUnitIndex)
            end
            if electricFillUnitIndex ~= 0 then
                electricCharge = realItem:getFillUnitCapacity(electricFillUnitIndex)
            end
            if methaneFillUnitIndex ~= 0 then
                methane = realItem:getFillUnitCapacity(methaneFillUnitIndex)
            end
        end
    end
    if returnValue then
        if fillTypeFilter == FillType.DIESEL or fillTypeFilter == nil then
            return motorConfigId
        elseif fillTypeFilter == FillType.DEF then
            return def
        elseif fillTypeFilter == FillType.ELECTRICCHARGE then
            return electricCharge
        else
            return fillTypeFilter ~= FillType.METHANE and 0 or methane
        end
    elseif motorConfigId == nil then
        if electricCharge == nil then
            if methane == nil then
                return nil
            else
                return string.format(g_i18n:getText("shop_fuelValue"), methane, g_i18n:getText("unit_kg"))
            end
        else
            return string.format(g_i18n:getText("shop_fuelValue"), electricCharge, g_i18n:getText("unit_kw"))
        end
    elseif def == nil or def <= 0 then
        return string.format(g_i18n:getText("shop_fuelValue"), motorConfigId, g_i18n:getText("unit_literShort"))
    else
        return string.format(g_i18n:getText("shop_fuelDefValue"), motorConfigId, g_i18n:getText("unit_literShort"), def, g_i18n:getText("unit_literShort"), g_i18n:getText("fillType_def_short"))
    end
end
function Motorized.loadSpecValueMaxSpeed(xmlFile, _, _)
    local motorKey = nil
    local motorKey = xmlFile:hasProperty("vehicle.motorized.motorConfigurations.motorConfiguration(0)") and "vehicle.motorized.motorConfigurations.motorConfiguration(0)" or (xmlFile:hasProperty("vehicle.motor") and "vehicle" or motorKey)
    if motorKey == nil then
        return nil
    else
        local maxRpm = xmlFile:getValue(motorKey .. ".motor#maxRpm", 1800)
        local minForwardGearRatio = xmlFile:getValue(motorKey .. ".transmission#minForwardGearRatio", nil)
        local axleRatio = xmlFile:getValue(motorKey .. ".transmission#axleRatio", 1)
        local forwardGears = Motorized.loadGears(nil, xmlFile, "forwardGear", motorKey .. ".transmission", maxRpm, axleRatio, 1)
        if minForwardGearRatio == nil and forwardGears == nil then
            Logging.xmlWarning(xmlFile, "No gear ratios defined for transmission")
        end
        local storeDataMaxSpeed = VehicleMotor.calculatePhysicalMaximumSpeed(minForwardGearRatio, forwardGears, maxRpm) * 3.6
        local calculatedMaxSpeed = math.ceil(storeDataMaxSpeed)
        local storeDataMaxSpeed = xmlFile:getValue("vehicle.storeData.specs.maxSpeed")
        local maxSpeed = xmlFile:getValue("vehicle.motorized.motorConfigurations.motorConfiguration(0)#maxSpeed")
        local maxForwardSpeed = xmlFile:getValue(motorKey .. ".motor#maxForwardSpeed")
        if storeDataMaxSpeed == nil then
            if maxSpeed == nil then
                if maxForwardSpeed == nil then
                    return calculatedMaxSpeed
                else
                    return math.min(maxForwardSpeed, calculatedMaxSpeed)
                end
            else
                return maxSpeed
            end
        else
            return storeDataMaxSpeed
        end
    end
end
function Motorized.getSpecValueMaxSpeed(storeItem, realItem, _, _, returnValues, _)
    local maxSpeed = nil
    if realItem ~= nil and storeItem.configurations ~= nil then
        if realItem.configurations.motor ~= nil and storeItem.configurations.motor ~= nil then
            maxSpeed = Utils.getNoNil(storeItem.configurations.motor[realItem.configurations.motor].maxSpeed, maxSpeed)
        end
        if realItem.configurations.wheel ~= nil and storeItem.configurations.wheel ~= nil then
            maxSpeed = Utils.getNoNil(storeItem.configurations.wheel[realItem.configurations.wheel].maxForwardSpeedShop, maxSpeed)
        end
    end
    if maxSpeed == nil then
        maxSpeed = storeItem.specs.maxSpeed
    end
    if maxSpeed == nil then
        return nil
    elseif returnValues then
        return MathUtil.round(maxSpeed)
    else
        return string.format(g_i18n:getText("shop_maxSpeed"), string.format("%1d", g_i18n:getSpeed(maxSpeed)), g_i18n:getSpeedMeasuringUnit())
    end
end
function Motorized.loadSpecValuePower(xmlFile, _, _)
    return xmlFile:getValue("vehicle.storeData.specs.power")
end
function Motorized.getSpecValuePower(storeItem, realItem, _, _, returnValues, _)
    local minPower = nil
    local maxPower = nil
    if realItem == nil or (storeItem.configurations == nil or (realItem.configurations.motor == nil or storeItem.configurations.motor == nil)) then
        if realItem == nil and (storeItem.configurations ~= nil and storeItem.configurations.motor ~= nil) then
            for _, configItem in ipairs(storeItem.configurations.motor) do
                if configItem.isSelectable and configItem.power ~= nil then
                    minPower = math.min(minPower or math.huge, configItem.power)
                    maxPower = math.max(maxPower or 0, configItem.power)
                end
            end
        end
    else
        maxPower = storeItem.configurations.motor[realItem.configurations.motor].power
    end
    if minPower == nil then
        maxPower = storeItem.specs.power
    end
    if minPower == nil then
        return nil
    elseif returnValues == nil or returnValues == false then
        if minPower == maxPower then
            return string.format(g_i18n:getText("shop_maxPowerValueSingle"), MathUtil.round(minPower))
        else
            return string.format(g_i18n:getText("shop_maxPowerValueRange"), MathUtil.round(minPower), MathUtil.round(maxPower))
        end
    else
        return MathUtil.round(minPower), MathUtil.round(maxPower)
    end
end
function Motorized.loadSpecValuePowerConfig(xmlFile, _, _)
    local powerValues = nil
    for name, configDesc in pairs(g_vehicleConfigurationManager:getConfigurations()) do
        for index, baseKey in xmlFile:iterator(configDesc.configurationKey) do
            if xmlFile:getValue(baseKey .. "#isSelectable", true) then
                local configValue = xmlFile:getFloat(baseKey .. "#hp")
                if configValue ~= nil then
                    powerValues = powerValues or {}
                    powerValues[name] = powerValues[name] or {}
                    powerValues[name][index] = MathUtil.round(configValue)
                end
            end
        end
    end
    return powerValues
end
function Motorized.getSpecValuePowerConfig(storeItem, _, configurations, _, returnValues, _)
    if storeItem.specs.powerConfig ~= nil then
        local minPower = nil
        local maxPower = nil
        if configurations == nil then
            minPower = math.huge
            maxPower = 0
            local numConfigs = 0
            for config, configPower in pairs(storeItem.specs.powerConfig) do
                for _, configPower in pairs(configPower) do
                    minPower = math.min(minPower, configPower)
                    maxPower = math.max(maxPower, configPower)
                end
            end
        else
            for configName, config in pairs(configurations) do
                local configPower = storeItem.specs.powerConfig[configName][config]
                if configPower ~= nil then
                    maxPower = configPower
                    minPower = maxPower
                    maxPower = minPower
                end
            end
        end
        if minPower ~= nil then
            if returnValues then
                return MathUtil.round(minPower), MathUtil.round(maxPower)
            elseif minPower == maxPower then
                return string.format(g_i18n:getText("shop_maxPowerValueSingle"), MathUtil.round(minPower))
            else
                return string.format(g_i18n:getText("shop_maxPowerValueRange"), MathUtil.round(minPower), MathUtil.round(maxPower))
            end
        end
    end
    return nil
end
function Motorized.loadSpecValueTransmission(xmlFile, customEnvironment, _)
    local nameByConfigIndex = {}
    xmlFile:iterate("vehicle.motorized.motorConfigurations.motorConfiguration", function(index, key)
        -- upvalues: (copy) nameByConfigIndex, (copy) xmlFile, (copy) customEnvironment
        nameByConfigIndex[index] = xmlFile:getValue(key .. ".transmission#name", nil, customEnvironment, false)
        local param = xmlFile:getValue(key .. ".transmission#param")
        if param ~= nil then
            local param = g_i18n:convertText(param, customEnvironment)
            nameByConfigIndex[index] = string.format(nameByConfigIndex[index], param)
        end
    end)
    return nameByConfigIndex
end
function Motorized.getSpecValueTransmission(storeItem, realItem, _, _, _, _)
    local name
    if realItem == nil or (storeItem.configurations == nil or (realItem.configurations.motor == nil or storeItem.configurations.motor == nil)) then
        name = storeItem.specs.transmission[1]
    elseif storeItem.specs.transmission[realItem.configurations.motor] == nil then
        return storeItem.specs.transmission[1]
    end
    return name
end