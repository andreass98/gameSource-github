source("dataS/scripts/vehicles/specializations/events/BalerSetIsUnloadingBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerSetBaleTimeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerCreateBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerDropFromPlatformEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerAutomaticDropEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerBaleTypeEvent.lua")
Baler = {}
Baler.CONSUMABLE_TYPE_NAME_ROUND = "BALE_NET"
Baler.CONSUMABLE_TYPE_NAME_SQUARE = "BALE_TWINE"
Baler.UNLOADING_CLOSED = 1
Baler.UNLOADING_OPENING = 2
Baler.UNLOADING_OPEN = 3
Baler.UNLOADING_CLOSING = 4
Baler.CLIENT_DM_UPDATE_RADIUS = 50
function Baler.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("baler", g_i18n:getText("shop_configuration"), "baler", VehicleConfigurationItem)
    AIFieldWorker.registerDriveStrategy(function(vehicle)
        return SpecializationUtil.hasSpecialization(Baler, vehicle.specializations)
    end, AIDriveStrategyBaler)
    g_workAreaTypeManager:addWorkAreaType("baler", false, false, true)
    g_storeManager:addSpecType("balerBaleSizeRound", "shopListAttributeIconBaleSizeRound", Baler.loadSpecValueBaleSizeRound, Baler.getSpecValueBaleSizeRound, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("balerBaleSizeSquare", "shopListAttributeIconBaleSizeSquare", Baler.loadSpecValueBaleSizeSquare, Baler.getSpecValueBaleSizeSquare, StoreSpecies.VEHICLE)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Baler")
    Baler.registerBalerXMLPaths(schema, "vehicle.baler")
    Baler.registerBalerXMLPaths(schema, "vehicle.baler.balerConfigurations.balerConfiguration(?)")
    schema:register(XMLValueType.BOOL, FillUnit.ALARM_TRIGGER_XML_KEY .. "#needsBaleLoaded", "Alarm triggers only when a full bale is loaded", false)
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baler#numBales", "Number of bales")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).baler.bale(?)#filename", "XML Filename of bale")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).baler.bale(?)#variationId", "Variation ID of the bale")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baler.bale(?)#ownerFarmId", "Owner of the bale")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).baler.bale(?)#fillType", "Bale fill type index")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baler.bale(?)#fillLevel", "Bale fill level")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baler.bale(?)#baleTime", "Bale time")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).baler#platformReadyToDrop", "Platform is ready to drop", false)
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baler#baleTypeIndex", "Current bale type index", 1)
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baler#preSelectedBaleTypeIndex", "Pre selected bale type index", 1)
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baler#fillUnitCapacity", "Current baler capacity depending on bale size")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).baler#bufferUnloadingStarted", "Baler buffer unloading in progress")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).baler#workAreaMissionUniqueId", "Workarea mission unique id")
end
function Baler.registerBalerXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#fillScale", "Fill scale", 1)
    schema:register(XMLValueType.INT, basePath .. "#fillUnitIndex", "Fill unit index", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#consumableUsage", "Usage of bale net or twine per bale", 0.025)
    schema:register(XMLValueType.BOOL, basePath .. "#useDropLandOwnershipForBales", "Defines if the produced bales are always owned by the land owner of the current location while dropping the bale. If not, the owner is either the owner from the last workArea pickup location (if available) or the owner of the bale as default.", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleAnimation#spacing", "Spacing between bales", 0)
    schema:register(XMLValueType.BOOL, basePath .. ".baleAnimation#enableCollision", "Enable collision of bales with any other object", true)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleAnimation.key(?)#time", "Key time")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".baleAnimation.key(?)#pos", "Key position")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".baleAnimation.key(?)#rot", "Key rotation")
    schema:register(XMLValueType.STRING, basePath .. ".baleAnimation#closeAnimationName", "Close animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".baleAnimation#closeAnimationSpeed", "Close animation speed", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".automaticDrop#enabled", "Automatic drop default enabled", "true on mobile")
    schema:register(XMLValueType.BOOL, basePath .. ".automaticDrop#toggleable", "Automatic bale drop can be toggled", "false on mobile")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".baleTypes#changeText", "Change bale size text", "action_changeBaleSize")
    schema:register(XMLValueType.BOOL, basePath .. ".baleTypes.baleType(?)#isRoundBale", "Is round bale", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#width", "Bale width", 1.2)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#height", "Bale height", 0.9)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#length", "Bale length", 2.4)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#diameter", "Bale diameter", 2.8)
    schema:register(XMLValueType.BOOL, basePath .. ".baleTypes.baleType(?)#isDefault", "Bale type is selected by default", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?)#consumableUsage", "Usage of bale net or twine per bale", 0.025)
    schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?)#chamberBaleVariationId", "Variation identifier of the dummy bale in the chamber", "DEFAULT")
    schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?)#defaultBaleVariationId", "Variation identifier of the final bale of no consumables are used", "DEFAULT")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".baleTypes.baleType(?).nodes#baleNode", "Bale link node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".baleTypes.baleType(?).nodes#baleRootNode", "Bale root node", "Same as baleNode")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".baleTypes.baleType(?).nodes#scaleNode", "Bale scale node")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".baleTypes.baleType(?).nodes#scaleComponents", "Bale scale component")
    schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).animations#fillAnimation", "Fill animation while this bale type is active")
    schema:register(XMLValueType.STRING, basePath .. ".baleTypes.baleType(?).animations#unloadAnimation", "Unload animation while this bale type is active")
    schema:register(XMLValueType.FLOAT, basePath .. ".baleTypes.baleType(?).animations#unloadAnimationSpeed", "Unload animation speed", 1)
    schema:register(XMLValueType.TIME, basePath .. ".baleTypes.baleType(?).animations#dropAnimationTime", "Specific time in #unloadAnimation when to drop the bale", "At the end of the unloading animation")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".baleTypes.baleType(?).detailVisibilityCutNode(?)#node", "Reference node for details visibility cut")
    schema:register(XMLValueType.INT, basePath .. ".baleTypes.baleType(?).detailVisibilityCutNode(?)#axis", "Axis of visibility cut [1, 3]", 3)
    schema:register(XMLValueType.INT, basePath .. ".baleTypes.baleType(?).detailVisibilityCutNode(?)#direction", "Direction of visibility cut [-1, 1]", 1)
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".baleTypes.baleType(?)")
    schema:register(XMLValueType.FLOAT, basePath .. "#unfinishedBaleThreshold", "Threshold to unload a unfinished bale", 2000)
    schema:register(XMLValueType.BOOL, basePath .. "#canUnloadUnfinishedBale", "Can unload unfinished bale", false)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "work")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "eject")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "unload")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "door")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "knotCleaning")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "bufferOverloadingStart(?)")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "bufferOverloadingStop(?)")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "bufferOverloadingWork(?)")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".unloadAnimationNodes")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".fillEffect")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".additiveEffects")
    schema:register(XMLValueType.STRING, basePath .. ".knotingAnimation#name", "Knoting animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".knotingAnimation#speed", "Knoting animation speed", 1)
    schema:register(XMLValueType.STRING, basePath .. ".compactingAnimation#name", "Compacting animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".compactingAnimation#interval", "Compacting interval", 60)
    schema:register(XMLValueType.FLOAT, basePath .. ".compactingAnimation#compactTime", "Compacting time", 5)
    schema:register(XMLValueType.FLOAT, basePath .. ".compactingAnimation#speed", "Compacting animation speed", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".compactingAnimation#minFillLevelTime", "Compacting min. fill level animation target time", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".compactingAnimation#maxFillLevelTime", "Compacting max. fill level animation target time", 0.1)
    schema:register(XMLValueType.STRING, basePath .. "#maxPickupLitersPerSecond", "Max pickup liters per second", 500)
    schema:register(XMLValueType.BOOL, basePath .. ".baleUnloading#allowed", "Bale unloading allowed", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleUnloading#time", "Bale unloading time", 4)
    schema:register(XMLValueType.FLOAT, basePath .. ".baleUnloading#foldThreshold", "Bale unloading fold threshold", 0.25)
    schema:register(XMLValueType.L10N_STRING, basePath .. ".automaticDrop#textPos", "Positive toggle automatic drop text", "action_toggleAutomaticBaleDropPos")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".automaticDrop#textNeg", "Negative toggle automatic drop text", "action_toggleAutomaticBaleDropNeg")
    schema:register(XMLValueType.STRING, basePath .. ".platform#animationName", "Platform animation")
    schema:register(XMLValueType.FLOAT, basePath .. ".platform#nextBaleTime", "Animation time when directly the next bale is unloaded after dropping from platform", 0)
    schema:register(XMLValueType.BOOL, basePath .. ".platform#automaticDrop", "Bale is automatically dropped from platform", "true on mobile")
    schema:register(XMLValueType.FLOAT, basePath .. ".platform#aiSpeed", "Speed of AI while dropping a bale from platform (km/h)", 3)
    schema:register(XMLValueType.INT, basePath .. ".buffer#fillUnitIndex", "Buffer fill unit index")
    schema:register(XMLValueType.INT, basePath .. ".buffer#unloadInfoIndex", "Fill volume unload info index index", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".buffer#capacityPercentage", "If set, this percentage of the bale capacity is set for the buffer. If not set the defined capacity from the xml is used.")
    schema:register(XMLValueType.TIME, basePath .. ".buffer#overloadingDuration", "Duration of overloading from buffer to baler unit (sec)", 0.5)
    schema:register(XMLValueType.TIME, basePath .. ".buffer#overloadingDelay", "Time until the real overloading is starting (can be used to wait for the effects to be fully fade in) (sec)", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".buffer#overloadingStartFillLevelPct", "Fill level percentage [0-1] of the buffer to start the overloading", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".buffer#fillMainUnitAfterOverload", "After overloading the full buffer to the main unit it will continue filling the main unit until it\'s full", false)
    schema:register(XMLValueType.STRING, basePath .. ".buffer#balerDisplayType", "Forced fill type to display on baler unit")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".buffer.dummyBale#node", "Dummy bale link node")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".buffer.dummyBale#scaleComponents", "Dummy bale link scale components", "1 1 0")
    schema:register(XMLValueType.STRING, basePath .. ".buffer.overloadAnimation#name", "Name of overload animation")
    schema:register(XMLValueType.FLOAT, basePath .. ".buffer.overloadAnimation#speedScale", "Speed of overload animation", 1)
    schema:register(XMLValueType.STRING, basePath .. ".buffer.loadingStateAnimation#name", "Name of loading state animation")
    schema:register(XMLValueType.FLOAT, basePath .. ".buffer.loadingStateAnimation#speedScale", "Speed of loading state animation", 1)
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".buffer.overloadingEffect")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".buffer.overloadingAnimationNodes")
    schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit#targetLiterPerSecond", "Target liters per second", 200)
    schema:register(XMLValueType.TIME, basePath .. ".variableSpeedLimit#changeInterval", "Interval which adjusts speed limit to conditions", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit#minSpeedLimit", "Min. speed limit", 5)
    schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit#maxSpeedLimit", "Max. speed limit", 15)
    schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit#defaultSpeedLimit", "Default speed limit", 10)
    schema:register(XMLValueType.STRING, basePath .. ".variableSpeedLimit.target(?)#fillType", "Name of fill type")
    schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit.target(?)#targetLiterPerSecond", "Target liters per second with this fill type", 200)
    schema:register(XMLValueType.FLOAT, basePath .. ".variableSpeedLimit.target(?)#defaultSpeedLimit", "Default speed limit with this fill type", 10)
    schema:register(XMLValueType.INT, basePath .. ".additives#fillUnitIndex", "Additives fill unit index")
    schema:register(XMLValueType.FLOAT, basePath .. ".additives#usage", "Usage per picked up liter", 0.0000275)
    schema:register(XMLValueType.STRING, basePath .. ".additives#fillTypes", "Fill types to apply additives", "GRASS_WINDROW")
    schema:register(XMLValueType.BOOL, basePath .. ".additives#appliedByBufferOverloading", "Additives are applied while the buffer unit is overloaded into main unit", false)
end
function Baler.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and (SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)) and SpecializationUtil.hasSpecialization(Consumable, specializations)
end
function Baler.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onBalerUnloadingStarted")
    SpecializationUtil.registerEvent(vehicleType, "onBalerUnloadingFinished")
end
function Baler.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "processBalerArea", Baler.processBalerArea)
    SpecializationUtil.registerFunction(vehicleType, "setBaleTypeIndex", Baler.setBaleTypeIndex)
    SpecializationUtil.registerFunction(vehicleType, "isUnloadingAllowed", Baler.isUnloadingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getTimeFromLevel", Baler.getTimeFromLevel)
    SpecializationUtil.registerFunction(vehicleType, "moveBales", Baler.moveBales)
    SpecializationUtil.registerFunction(vehicleType, "moveBale", Baler.moveBale)
    SpecializationUtil.registerFunction(vehicleType, "setIsUnloadingBale", Baler.setIsUnloadingBale)
    SpecializationUtil.registerFunction(vehicleType, "getIsBaleUnloading", Baler.getIsBaleUnloading)
    SpecializationUtil.registerFunction(vehicleType, "dropBale", Baler.dropBale)
    SpecializationUtil.registerFunction(vehicleType, "finishBale", Baler.finishBale)
    SpecializationUtil.registerFunction(vehicleType, "createBale", Baler.createBale)
    SpecializationUtil.registerFunction(vehicleType, "setBaleTime", Baler.setBaleTime)
    SpecializationUtil.registerFunction(vehicleType, "getCanUnloadUnfinishedBale", Baler.getCanUnloadUnfinishedBale)
    SpecializationUtil.registerFunction(vehicleType, "setBalerAutomaticDrop", Baler.setBalerAutomaticDrop)
    SpecializationUtil.registerFunction(vehicleType, "updateDummyBale", Baler.updateDummyBale)
    SpecializationUtil.registerFunction(vehicleType, "deleteDummyBale", Baler.deleteDummyBale)
    SpecializationUtil.registerFunction(vehicleType, "createDummyBale", Baler.createDummyBale)
    SpecializationUtil.registerFunction(vehicleType, "handleUnloadingBaleEvent", Baler.handleUnloadingBaleEvent)
    SpecializationUtil.registerFunction(vehicleType, "dropBaleFromPlatform", Baler.dropBaleFromPlatform)
    SpecializationUtil.registerFunction(vehicleType, "getBalerBaleOwnerFarmId", Baler.getBalerBaleOwnerFarmId)
    SpecializationUtil.registerFunction(vehicleType, "getIsRoundBaler", Baler.getIsRoundBaler)
end
function Baler.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Baler.loadSpeedRotatingPartFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Baler.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Baler.getIsSpeedRotatingPartActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Baler.getCanBeTurnedOn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Baler.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Baler.getIsWorkAreaActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Baler.getConsumingLoad)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", Baler.getRequiresPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Baler.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttachedTo", Baler.getIsAttachedTo)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", Baler.getAllowDynamicMountFillLevelInfo)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAlarmTriggerIsActive", Baler.getAlarmTriggerIsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAlarmTrigger", Baler.loadAlarmTrigger)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowConsumableEmptyWarning", Baler.getShowConsumableEmptyWarning)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Baler.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Baler.removeFromPhysics)
end
function Baler.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Baler)
    SpecializationUtil.registerEventListener(vehicleType, "onConsumableVariationChanged", Baler)
end
function Baler:onLoad(savegame)
    local spec = self.spec_baler
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fillScale#value", "vehicle.baler#fillScale")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.baler.animationNodes.animationNode", "baler")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.balingAnimation#name", "vehicle.turnOnVehicle.turnedOnAnimation#name")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.fillParticleSystems", "vehicle.baler.fillEffect with effectClass \'ParticleEffect\'")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.uvScrollParts.uvScrollPart", "vehicle.baler.animationNodes.animationNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.balerAlarm", "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit.alarmTriggers.alarmTrigger.alarmSound")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#node", "vehicle.baler.baleTypes.baleType#baleNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#baleNode", "vehicle.baler.baleTypes.baleType#baleNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#scaleNode", "vehicle.baler.baleTypes.baleType#scaleNode")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#baleScaleComponent", "vehicle.baler.baleTypes.baleType#scaleComponents")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#unloadAnimationName", "vehicle.baler.baleTypes.baleType#unloadAnimation")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#unloadAnimationSpeed", "vehicle.baler.baleTypes.baleType#unloadAnimationSpeed")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#baleDropAnimTime", "vehicle.baler.baleTypes.baleType#dropAnimationTime")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler#toggleAutomaticDropTextPos", "vehicle.baler.automaticDrop#textPos")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler#toggleAutomaticDropTextNeg", "vehicle.baler.automaticDrop#textNeg")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#firstBaleMarker", "Please adjust bale nodes to match the default balers")
    local configKey = string.format("vehicle.baler.balerConfigurations.balerConfiguration(%d)", (self.configurations.baler or 1) - 1)
    local baseKey = not self.xmlFile:hasProperty(configKey) and "vehicle.baler" or configKey
    spec.fillScale = self.xmlFile:getValue(baseKey .. "#fillScale", 1)
    spec.fillUnitIndex = self.xmlFile:getValue(baseKey .. "#fillUnitIndex", 1)
    spec.consumableUsage = self.xmlFile:getValue(baseKey .. "#consumableUsage", 0.025)
    spec.useDropLandOwnershipForBales = self.xmlFile:getValue(baseKey .. "#useDropLandOwnershipForBales", false)
    if self.xmlFile:hasProperty(baseKey .. ".baleAnimation") then
        local baleAnimCurve = AnimCurve.new(linearInterpolatorN)
        local keyframes = {}
        local lastX = nil
        local lastY = nil
        local lastZ = nil
        local totalLength = 0
        self.xmlFile:iterate(baseKey .. ".baleAnimation.key", function(_, key)
            -- upvalues: (copy) self, (ref) lastX, (ref) lastY, (ref) lastZ, (ref) totalLength, (copy) keyframes
            XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#time")
            local keyframe = {}
            keyframe.x, keyframe.y, keyframe.z = self.xmlFile:getValue(key .. "#pos")
            if keyframe.x == nil then
                Logging.xmlWarning(self.xmlFile, "Missing values for \'%s\'", key .. "#pos")
            else
                keyframe.rx, keyframe.ry, keyframe.rz = self.xmlFile:getValue(key .. "#rot", "0 0 0")
                if lastX ~= nil then
                    keyframe.length = MathUtil.vector3Length(lastX - keyframe.x, lastY - keyframe.y, lastZ - keyframe.z)
                    totalLength = totalLength + keyframe.length
                    keyframe.pos = totalLength
                end
                table.insert(keyframes, keyframe)
                lastX = keyframe.x
            end
        end)
        local i = 1
        for i = i, #keyframes do
            local keyframe = keyframes[i]
            local t = 0
            if keyframe.pos ~= nil then
                t = keyframe.pos / totalLength
            end
            baleAnimCurve:addKeyframe({
                keyframe.x,
                keyframe.y,
                keyframe.z,
                keyframe.rx,
                keyframe.ry,
                keyframe.rz,
                ["time"] = t
            })
        end
        if #keyframes > 0 then
            spec.baleAnimCurve = baleAnimCurve
            spec.baleAnimLength = totalLength
            spec.baleAnimSpacing = self.xmlFile:getValue(baseKey .. ".baleAnimation#spacing", 0)
            spec.baleAnimEnableCollision = self.xmlFile:getValue(baseKey .. ".baleAnimation#enableCollision", true)
        end
    end
    spec.hasUnloadingAnimation = true
    spec.isRoundBaler = false
    spec.lastBaleVariationId = nil
    local baleAnimCurve = 1
    spec.baleTypes = {}
    self.xmlFile:iterate(baseKey .. ".baleTypes.baleType", function(index, key)
        -- upvalues: (copy) spec, (copy) self, (ref) baleAnimCurve
        if #spec.baleTypes >= BalerBaleTypeEvent.MAX_NUM_BALE_TYPES then
            Logging.xmlError(self.xmlFile, "Too many bale types defined. Max. amount is \'%d\'! \'%s\'", BalerBaleTypeEvent.MAX_NUM_BALE_TYPES, key)
            return false
        else
            local baleTypeDefinition = {
                ["index"] = index,
                ["isRoundBale"] = self.xmlFile:getValue(key .. "#isRoundBale", false),
                ["width"] = MathUtil.round(self.xmlFile:getValue(key .. "#width", 1.2), 2),
                ["height"] = MathUtil.round(self.xmlFile:getValue(key .. "#height", 0.9), 2),
                ["length"] = MathUtil.round(self.xmlFile:getValue(key .. "#length", 2.4), 2),
                ["diameter"] = MathUtil.round(self.xmlFile:getValue(key .. "#diameter", 1.8), 2)
            }
            if baleTypeDefinition.isRoundBale then
                spec.isRoundBaler = true
            end
            baleTypeDefinition.isDefault = self.xmlFile:getValue(key .. "#isDefault", false)
            if baleTypeDefinition.isDefault then
                baleAnimCurve = index
            end
            baleTypeDefinition.consumableUsage = self.xmlFile:getValue(key .. "#consumableUsage", spec.consumableUsage)
            baleTypeDefinition.chamberBaleVariationId = self.xmlFile:getValue(key .. "#chamberBaleVariationId", "DEFAULT")
            baleTypeDefinition.defaultBaleVariationId = self.xmlFile:getValue(key .. "#defaultBaleVariationId", "DEFAULT")
            baleTypeDefinition.baleNode = self.xmlFile:getValue(key .. ".nodes#baleNode", nil, self.components, self.i3dMappings)
            baleTypeDefinition.baleRootNode, baleTypeDefinition.baleNodeComponent = self.xmlFile:getValue(key .. ".nodes#baleRootNode", baleTypeDefinition.baleNode, self.components, self.i3dMappings)
            if baleTypeDefinition.baleRootNode ~= nil and baleTypeDefinition.baleNodeComponent == nil then
                baleTypeDefinition.baleNodeComponent = self:getParentComponent(baleTypeDefinition.baleRootNode)
            end
            if baleTypeDefinition.baleNode == nil then
                Logging.xmlError(self.xmlFile, "Missing baleNode for bale type. \'%s\'", key)
            else
                baleTypeDefinition.scaleNode = self.xmlFile:getValue(key .. ".nodes#scaleNode", nil, self.components, self.i3dMappings)
                baleTypeDefinition.scaleComponents = self.xmlFile:getValue(key .. ".nodes#scaleComponents", nil, true)
                baleTypeDefinition.animations = {}
                baleTypeDefinition.animations.fill = self.xmlFile:getValue(key .. ".animations#fillAnimation")
                baleTypeDefinition.animations.unloading = self.xmlFile:getValue(key .. ".animations#unloadAnimation")
                baleTypeDefinition.animations.unloadingSpeed = self.xmlFile:getValue(key .. ".animations#unloadAnimationSpeed", 1)
                baleTypeDefinition.animations.dropAnimationTime = self.xmlFile:getValue(key .. ".animations#dropAnimationTime", self:getAnimationDuration(baleTypeDefinition.animations.unloading) / 1000)
                baleTypeDefinition.detailVisibilityCutNodes = {}
                self.xmlFile:iterate(key .. ".detailVisibilityCutNode", function(_, detailsVisNodeKey)
                    -- upvalues: (ref) self, (copy) baleTypeDefinition
                    local detailVisibilityCutNode = {
                        ["node"] = self.xmlFile:getValue(detailsVisNodeKey .. "#node", nil, self.components, self.i3dMappings)
                    }
                    if detailVisibilityCutNode.node ~= nil then
                        detailVisibilityCutNode.axis = self.xmlFile:getValue(detailsVisNodeKey .. "#axis", 3)
                        detailVisibilityCutNode.direction = self.xmlFile:getValue(detailsVisNodeKey .. "#direction", 1)
                        table.insert(baleTypeDefinition.detailVisibilityCutNodes, detailVisibilityCutNode)
                    end
                end)
                baleTypeDefinition.changeObjects = {}
                ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, baleTypeDefinition.changeObjects, self.components, self)
                table.insert(spec.baleTypes, baleTypeDefinition)
                spec.hasUnloadingAnimation = spec.hasUnloadingAnimation and baleTypeDefinition.animations.unloading ~= nil
            end
        end
    end)
    local keyframes = spec.baleTypes[baleAnimCurve]
    if keyframes ~= nil then
        ObjectChangeUtil.setObjectChanges(keyframes.changeObjects, true, self, self.setMovingToolDirty)
    end
    spec.changeBaleTypeText = self.xmlFile:getValue(baseKey .. ".baleTypes#changeText", "action_changeBaleSize", self.customEnvironment)
    spec.preSelectedBaleTypeIndex = baleAnimCurve
    spec.currentBaleTypeIndex = baleAnimCurve
    spec.currentBaleXMLFilename = nil
    spec.currentBaleTypeDefinition = nil
    if #spec.baleTypes == 0 then
        Logging.xmlError(self.xmlFile, "No baleTypes definded for baler.")
    end
    if spec.hasUnloadingAnimation then
        spec.automaticDrop = self.xmlFile:getValue(baseKey .. ".automaticDrop#enabled", Platform.gameplay.automaticBaleDrop)
        spec.toggleableAutomaticDrop = self.xmlFile:getValue(baseKey .. ".automaticDrop#toggleable", not Platform.gameplay.automaticBaleDrop)
        spec.toggleAutomaticDropTextPos = self.xmlFile:getValue(baseKey .. ".automaticDrop#textPos", "action_toggleAutomaticBaleDropPos", self.customEnvironment)
        spec.toggleAutomaticDropTextNeg = self.xmlFile:getValue(baseKey .. ".automaticDrop#textNeg", "action_toggleAutomaticBaleDropNeg", self.customEnvironment)
        spec.baleCloseAnimationName = self.xmlFile:getValue(baseKey .. ".baleAnimation#closeAnimationName")
        spec.baleCloseAnimationSpeed = self.xmlFile:getValue(baseKey .. ".baleAnimation#closeAnimationSpeed", 1)
        local lastX = self:getAnimationByName(spec.baleCloseAnimationName)
        if spec.baleCloseAnimationName == nil or lastX == nil then
            Logging.xmlError(self.xmlFile, "Failed to find baler close animation. (%s)", baseKey .. ".baleAnimation#closeAnimationName")
        else
            lastX.resetOnStart = false
        end
    end
    spec.unfinishedBaleThreshold = self.xmlFile:getValue(baseKey .. "#unfinishedBaleThreshold", 2000)
    spec.canUnloadUnfinishedBale = self.xmlFile:getValue(baseKey .. "#canUnloadUnfinishedBale", false)
    spec.lastBaleFillLevel = nil
    if self.isClient then
        spec.samples = {}
        spec.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.eject = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "eject", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.unload = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "unload", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.door = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "door", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.knotCleaning = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "knotCleaning", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.knotCleaningTimer = 10000
        spec.knotCleaningTime = 120000
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, baseKey .. ".animationNodes", self.components, self, self.i3dMappings)
        spec.unloadAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, baseKey .. ".unloadAnimationNodes", self.components, self, self.i3dMappings)
        spec.fillEffects = g_effectManager:loadEffect(self.xmlFile, baseKey .. ".fillEffect", self.components, self, self.i3dMappings)
        spec.fillEffectType = FillType.UNKNOWN
        spec.additiveEffects = g_effectManager:loadEffect(self.xmlFile, baseKey .. ".additiveEffects", self.components, self, self.i3dMappings)
        spec.knotingAnimation = self.xmlFile:getValue(baseKey .. ".knotingAnimation#name")
        spec.knotingAnimationSpeed = self.xmlFile:getValue(baseKey .. ".knotingAnimation#speed", 1)
        spec.compactingAnimation = self.xmlFile:getValue(baseKey .. ".compactingAnimation#name")
        spec.compactingAnimationInterval = self.xmlFile:getValue(baseKey .. ".compactingAnimation#interval", 60) * 1000
        spec.compactingAnimationCompactTime = self.xmlFile:getValue(baseKey .. ".compactingAnimation#compactTime", 5) * 1000
        spec.compactingAnimationCompactTimer = spec.compactingAnimationCompactTime
        spec.compactingAnimationTime = spec.compactingAnimationInterval
        spec.compactingAnimationSpeed = self.xmlFile:getValue(baseKey .. ".compactingAnimation#speed", 1)
        spec.compactingAnimationMinTime = self.xmlFile:getValue(baseKey .. ".compactingAnimation#minFillLevelTime", 1)
        spec.compactingAnimationMaxTime = self.xmlFile:getValue(baseKey .. ".compactingAnimation#maxFillLevelTime", 0.1)
    end
    spec.lastAreaBiggerZero = false
    spec.lastAreaBiggerZeroSent = false
    spec.lastAreaBiggerZeroTime = 0
    spec.workAreaParameters = {}
    spec.workAreaParameters.lastPickedUpLiters = 0
    spec.fillUnitOverflowFillLevel = 0
    spec.maxPickupLitersPerSecond = self.xmlFile:getValue(baseKey .. "#maxPickupLitersPerSecond", 500)
    spec.pickUpLitersBuffer = ValueBuffer.new(750)
    spec.unloadingState = Baler.UNLOADING_CLOSED
    spec.pickupFillTypes = {}
    spec.bales = {}
    spec.dummyBale = {}
    spec.dummyBale.currentBaleFillType = FillType.UNKNOWN
    spec.dummyBale.currentBale = nil
    spec.dummyBale.currentBaleLength = 0
    spec.allowsBaleUnloading = self.xmlFile:getValue(baseKey .. ".baleUnloading#allowed", false)
    spec.baleUnloadingTime = self.xmlFile:getValue(baseKey .. ".baleUnloading#time", 4) * 1000
    spec.baleFoldThreshold = self.xmlFile:getValue(baseKey .. ".baleUnloading#foldThreshold", 0.25) * self:getFillUnitCapacity(spec.fillUnitIndex)
    spec.platformAnimation = self.xmlFile:getValue(baseKey .. ".platform#animationName")
    spec.platformAnimationNextBaleTime = self.xmlFile:getValue(baseKey .. ".platform#nextBaleTime", 0)
    spec.platformAutomaticDrop = self.xmlFile:getValue(baseKey .. ".platform#automaticDrop", Platform.gameplay.automaticBaleDrop)
    spec.platformAIDropSpeed = self.xmlFile:getValue(baseKey .. ".platform#aiSpeed", 3)
    local lastX = spec.platformAnimation ~= nil
    spec.hasPlatform = lastX
    spec.hasDynamicMountPlatform = SpecializationUtil.hasSpecialization(DynamicMountAttacher, self.specializations)
    if spec.hasPlatform then
        spec.automaticDrop = true
    end
    spec.platformReadyToDrop = false
    spec.platformDropInProgress = false
    spec.platformDelayedDropping = false
    spec.platformMountDelay = -1
    spec.buffer = {}
    spec.buffer.fillUnitIndex = self.xmlFile:getValue(baseKey .. ".buffer#fillUnitIndex")
    spec.buffer.unloadInfoIndex = self.xmlFile:getValue(baseKey .. ".buffer#unloadInfoIndex", 1)
    spec.buffer.capacityPercentage = self.xmlFile:getValue(baseKey .. ".buffer#capacityPercentage")
    spec.buffer.overloadingDuration = self.xmlFile:getValue(baseKey .. ".buffer#overloadingDuration", 1)
    spec.buffer.overloadingDelay = self.xmlFile:getValue(baseKey .. ".buffer#overloadingDelay", 0)
    spec.buffer.overloadingTimer = 0
    spec.buffer.overloadingStartFillLevelPct = MathUtil.round(self.xmlFile:getValue(baseKey .. ".buffer#overloadingStartFillLevelPct", 1), 2)
    spec.buffer.fillMainUnitAfterOverload = self.xmlFile:getValue(baseKey .. ".buffer#fillMainUnitAfterOverload", false)
    spec.buffer.unloadingStarted = false
    spec.buffer.fillLevelToEmpty = 0
    spec.buffer.dummyBale = {}
    spec.buffer.dummyBale.available = self.xmlFile:hasProperty(baseKey .. ".buffer.dummyBale")
    spec.buffer.dummyBale.linkNode = self.xmlFile:getValue(baseKey .. ".buffer.dummyBale#node", nil, self.components, self.i3dMappings)
    spec.buffer.dummyBale.scaleComponents = self.xmlFile:getValue(baseKey .. ".buffer.dummyBale#scaleComponents", "1 1 0", true)
    spec.buffer.overloadAnimation = self.xmlFile:getValue(baseKey .. ".buffer.overloadAnimation#name")
    spec.buffer.overloadAnimationSpeed = self.xmlFile:getValue(baseKey .. ".buffer.overloadAnimation#speedScale", 1)
    spec.buffer.loadingStateAnimation = self.xmlFile:getValue(baseKey .. ".buffer.loadingStateAnimation#name")
    spec.buffer.loadingStateAnimationSpeed = self.xmlFile:getValue(baseKey .. ".buffer.loadingStateAnimation#speedScale", 1)
    if self.isClient then
        spec.buffer.overloadingEffects = g_effectManager:loadEffect(self.xmlFile, baseKey .. ".buffer.overloadingEffect", self.components, self, self.i3dMappings)
        spec.buffer.overloadingAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, baseKey .. ".buffer.overloadingAnimationNodes", self.components, self, self.i3dMappings)
        spec.buffer.samplesOverloadingStart = g_soundManager:loadSamplesFromXML(self.xmlFile, baseKey .. ".sounds", "bufferOverloadingStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.buffer.samplesOverloadingStop = g_soundManager:loadSamplesFromXML(self.xmlFile, baseKey .. ".sounds", "bufferOverloadingStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.buffer.samplesOverloadingWork = g_soundManager:loadSamplesFromXML(self.xmlFile, baseKey .. ".sounds", "bufferOverloadingWork", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    local lastX = spec.buffer.fillUnitIndex ~= nil
    spec.nonStopBaling = lastX
    if spec.nonStopBaling ~= nil then
        local lastX = self.xmlFile:getValue(baseKey .. ".buffer#balerDisplayType")
        local lastY = g_fillTypeManager:getFillTypeIndexByName(lastX)
        if lastY ~= nil then
            self:setFillUnitFillTypeToDisplay(spec.fillUnitIndex, lastY, true)
        end
    end
    spec.variableSpeedLimit = {}
    spec.variableSpeedLimit.enabled = self.xmlFile:hasProperty(baseKey .. ".variableSpeedLimit")
    spec.variableSpeedLimit.pickupPerSecond = 0
    spec.variableSpeedLimit.pickupPerSecondTimer = 0
    spec.variableSpeedLimit.targetLiterPerSecond = self.xmlFile:getValue(baseKey .. ".variableSpeedLimit#targetLiterPerSecond", 200)
    spec.variableSpeedLimit.changeInterval = self.xmlFile:getValue(baseKey .. ".variableSpeedLimit#changeInterval", 1)
    spec.variableSpeedLimit.minSpeedLimit = self.xmlFile:getValue(baseKey .. ".variableSpeedLimit#minSpeedLimit", 5)
    spec.variableSpeedLimit.maxSpeedLimit = self.xmlFile:getValue(baseKey .. ".variableSpeedLimit#maxSpeedLimit", 15)
    spec.variableSpeedLimit.defaultSpeedLimit = self.xmlFile:getValue(baseKey .. ".variableSpeedLimit#defaultSpeedLimit", 10)
    spec.variableSpeedLimit.backupSpeedLimit = self.speedLimit
    spec.variableSpeedLimit.usedBackupSpeedLimit = false
    spec.variableSpeedLimit.lastAdjustedSpeedLimit = nil
    spec.variableSpeedLimit.lastAdjustedSpeedLimitType = nil
    spec.variableSpeedLimit.fillTypeToTargetLiterPerSecond = {}
    self.xmlFile:iterate(baseKey .. ".variableSpeedLimit.target", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local fillType = g_fillTypeManager:getFillTypeIndexByName(self.xmlFile:getValue(key .. "#fillType"))
        if fillType ~= nil then
            spec.variableSpeedLimit.fillTypeToTargetLiterPerSecond[fillType] = {
                ["targetLiterPerSecond"] = self.xmlFile:getValue(key .. "#targetLiterPerSecond", 200),
                ["defaultSpeedLimit"] = self.xmlFile:getValue(key .. "#defaultSpeedLimit", 10)
            }
        end
    end)
    spec.additives = {}
    spec.additives.fillUnitIndex = self.xmlFile:getValue(baseKey .. ".additives#fillUnitIndex")
    local lastX = spec.additives
    local lastY = self:getFillUnitByIndex(spec.additives.fillUnitIndex) ~= nil
    lastX.available = lastY
    spec.additives.usage = self.xmlFile:getValue(baseKey .. ".additives#usage", 0.0000275)
    local lastX = self.xmlFile:getValue(baseKey .. ".additives#fillTypes", "GRASS_WINDROW")
    spec.additives.fillTypes = g_fillTypeManager:getFillTypesByNames(lastX, "Warning: \'" .. self.xmlFile:getFilename() .. "\' has invalid fillType \'%s\'.")
    spec.additives.appliedByBufferOverloading = self.xmlFile:getValue(baseKey .. ".additives#appliedByBufferOverloading", false)
    spec.additives.isActiveTimer = 0
    spec.additives.isActive = false
    spec.isBaleUnloading = false
    spec.balesToUnload = 0
    spec.texts = {}
    spec.texts.warningFoldingBaleLoaded = g_i18n:getText("warning_foldingNotWhileBaleLoaded")
    spec.texts.warningFoldingTurnedOn = g_i18n:getText("warning_foldingNotWhileTurnedOn")
    spec.texts.warningTooManyBales = g_i18n:getText("warning_tooManyBales")
    spec.texts.unloadUnfinishedBale = g_i18n:getText("action_unloadUnfinishedBale")
    spec.texts.unloadBaler = g_i18n:getText("action_unloadBaler")
    spec.texts.closeBack = g_i18n:getText("action_closeBack")
    spec.showBaleLimitWarning = false
    spec.dirtyFlag = self:getNextDirtyFlag()
    if savegame ~= nil and not savegame.resetVehicles then
        self:setBaleTypeIndex(savegame.xmlFile:getValue(savegame.key .. ".baler#baleTypeIndex", spec.currentBaleTypeIndex), true, true)
        self:setBaleTypeIndex(savegame.xmlFile:getValue(savegame.key .. ".baler#preSelectedBaleTypeIndex", spec.preSelectedBaleTypeIndex), nil, true)
        local totalLength = savegame.xmlFile:getValue(savegame.key .. ".baler#fillUnitCapacity")
        if totalLength ~= nil then
            local totalLength = totalLength == 0 and math.huge or totalLength
            self:setFillUnitCapacity(spec.fillUnitIndex, totalLength)
            if spec.buffer.capacityPercentage ~= nil then
                self:setFillUnitCapacity(spec.fillUnitIndex, totalLength * spec.buffer.capacityPercentage, false)
            end
        end
        spec.workAreaParameters.lastMissionUniqueId = savegame.xmlFile:getValue(savegame.key .. ".baler#workAreaMissionUniqueId")
        if spec.nonStopBaling then
            spec.buffer.unloadingStarted = savegame.xmlFile:getValue(savegame.key .. ".baler#bufferUnloadingStarted", spec.buffer.unloadingStarted)
        end
    end
end
function Baler:onPostLoad(savegame)
    local spec = self.spec_baler
    for fillTypeIndex, enabled in pairs(self:getFillUnitSupportedFillTypes(spec.fillUnitIndex)) do
        if enabled and fillTypeIndex ~= FillType.UNKNOWN then
            spec.pickupFillTypes[fillTypeIndex] = 0
        end
    end
    if savegame ~= nil and not savegame.resetVehicles then
        local numBales = savegame.xmlFile:getValue(savegame.key .. ".baler#numBales")
        if numBales ~= nil then
            spec.balesToLoad = {}
            local fillTypeIndex = 1
            for fillTypeIndex = fillTypeIndex, numBales do
                local enabled = string.format("%s.baler.bale(%d)", savegame.key, fillTypeIndex - 1)
                local filename = savegame.xmlFile:getValue(enabled .. "#filename")
                local fillTypeStr = savegame.xmlFile:getValue(enabled .. "#fillType")
                local fillType = g_fillTypeManager:getFillTypeByName(fillTypeStr)
                if filename ~= nil and fillType ~= nil then
                    ({}).filename = filename
                    bale.fillType = fillType.index
                    bale.fillLevel = savegame.xmlFile:getValue(enabled .. "#fillLevel")
                    bale.baleTime = savegame.xmlFile:getValue(enabled .. "#baleTime")
                    bale.variationId = savegame.xmlFile:getValue(enabled .. "#variationId")
                    bale.ownerFarmId = savegame.xmlFile:getValue(enabled .. "#ownerFarmId")
                    table.insert(spec.balesToLoad, bale)
                end
            end
        end
        if spec.hasPlatform then
            spec.platformReadyToDrop = savegame.xmlFile:getValue(savegame.key .. ".baler#platformReadyToDrop", spec.platformReadyToDrop)
            if spec.platformReadyToDrop then
                self:setAnimationTime(spec.platformAnimation, 1, true)
                self:setAnimationTime(spec.platformAnimation, 0, true)
                spec.platformMountDelay = 1
            end
        end
    end
end
function Baler:onLoadFinished(_)
    local spec = self.spec_baler
    if self.isServer and (spec.createBaleNextFrame ~= nil and spec.createBaleNextFrame) then
        self:finishBale()
        spec.createBaleNextFrame = nil
    end
    if spec.balesToLoad ~= nil then
        for _, v in ipairs(spec.balesToLoad) do
            if self:createBale(v.fillType, v.fillLevel, nil, v.baleTime, v.filename, v.ownerFarmId, v.variationId, true) then
                self:setBaleTime(#spec.bales, v.baleTime, true)
            end
        end
        spec.balesToLoad = nil
    end
end
function Baler:onDelete()
    local spec = self.spec_baler
    if spec.bales ~= nil then
        local dropBales = spec.dropBalesOnDelete
        if not dropBales then
            dropBales = spec.dropBalesOnDelete ~= nil
        end
        if dropBales and (self.isReconfigurating == nil or not self.isReconfigurating) then
            for k, _ in pairs(spec.bales) do
                self:dropBale(k)
            end
        else
            for k, _ in pairs(spec.bales) do
                if _.baleObject ~= nil then
                    _.baleObject:delete()
                end
            end
        end
    end
    self:deleteDummyBale(spec.dummyBale)
    if spec.buffer ~= nil then
        if spec.buffer.dummyBale.available then
            self:deleteDummyBale(spec.buffer.dummyBale)
        end
        g_soundManager:deleteSamples(spec.buffer.samplesOverloadingStart)
        g_soundManager:deleteSamples(spec.buffer.samplesOverloadingWork)
        g_soundManager:deleteSamples(spec.buffer.samplesOverloadingStop)
        g_effectManager:deleteEffects(spec.buffer.overloadingEffects)
        g_animationManager:deleteAnimations(spec.buffer.overloadingAnimationNodes)
    end
    g_soundManager:deleteSamples(spec.samples)
    g_effectManager:deleteEffects(spec.fillEffects)
    g_effectManager:deleteEffects(spec.additiveEffects)
    g_animationManager:deleteAnimations(spec.animationNodes)
    g_animationManager:deleteAnimations(spec.unloadAnimationNodes)
end
function Baler:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_baler
    if not spec.hasUnloadingAnimation or self:getFillUnitFreeCapacity(spec.fillUnitIndex) > 0 then
        xmlFile:setValue(key .. "#numBales", #spec.bales)
        for k, bale in ipairs(spec.bales) do
            local baleKey = string.format("%s.bale(%d)", key, k - 1)
            xmlFile:setValue(baleKey .. "#filename", bale.filename)
            xmlFile:setValue(baleKey .. "#variationId", bale.baleObject:getVariationId())
            xmlFile:setValue(baleKey .. "#ownerFarmId", bale.baleObject:getOwnerFarmId())
            local fillTypeStr = "UNKNOWN"
            if bale.fillType ~= FillType.UNKNOWN then
                fillTypeStr = g_fillTypeManager:getFillTypeNameByIndex(bale.fillType)
            end
            xmlFile:setValue(baleKey .. "#fillType", fillTypeStr)
            xmlFile:setValue(baleKey .. "#fillLevel", bale.fillLevel)
            if spec.baleAnimCurve ~= nil then
                xmlFile:setValue(baleKey .. "#baleTime", bale.time)
            end
        end
    end
    if spec.hasPlatform then
        xmlFile:setValue(key .. "#platformReadyToDrop", spec.platformReadyToDrop)
    end
    xmlFile:setValue(key .. "#baleTypeIndex", spec.currentBaleTypeIndex)
    xmlFile:setValue(key .. "#preSelectedBaleTypeIndex", spec.preSelectedBaleTypeIndex)
    xmlFile:setValue(key .. "#fillUnitCapacity", self:getFillUnitCapacity(spec.fillUnitIndex))
    local mission = g_missionManager:getMissionByUniqueId(spec.workAreaParameters.lastMissionUniqueId)
    if mission ~= nil and mission:getIsRunning() then
        xmlFile:setValue(key .. "#workAreaMissionUniqueId", mission:getUniqueId())
    end
    if spec.nonStopBaling then
        xmlFile:setValue(key .. "#bufferUnloadingStarted", spec.buffer.unloadingStarted)
    end
end
function Baler:onReadStream(streamId, _)
    local spec = self.spec_baler
    if spec.hasUnloadingAnimation then
        local state = streamReadUIntN(streamId, 7)
        local animTime = streamReadFloat32(streamId)
        if state == Baler.UNLOADING_CLOSED or state == Baler.UNLOADING_CLOSING then
            self:setIsUnloadingBale(false, true)
            self:setRealAnimationTime(spec.baleCloseAnimationName, animTime)
        elseif state == Baler.UNLOADING_OPEN or state == Baler.UNLOADING_OPENING then
            self:setIsUnloadingBale(true, true)
            self:setRealAnimationTime(spec.baleUnloadAnimationName, animTime)
        end
    end
    local state = streamReadUInt8(streamId)
    local i = 1
    local fillLevel = 1
    for i = i, state, fillLevel do
        self:createBale(streamReadIntN(streamId, FillTypeManager.SEND_NUM_BITS), (streamReadFloat32(streamId)))
        if spec.baleAnimCurve ~= nil then
            self:setBaleTime(i, (streamReadFloat32(streamId)))
        end
    end
    spec.lastAreaBiggerZero = streamReadBool(streamId)
    if spec.hasPlatform then
        spec.platformReadyToDrop = streamReadBool(streamId)
        if spec.platformReadyToDrop then
            self:setAnimationTime(spec.platformAnimation, 1, true)
            self:setAnimationTime(spec.platformAnimation, 0, true)
        end
    end
    spec.currentBaleTypeIndex = streamReadUIntN(streamId, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
    spec.preSelectedBaleTypeIndex = streamReadUIntN(streamId, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
    local animTime = streamReadFloat32(streamId)
    self:setFillUnitCapacity(spec.fillUnitIndex, animTime)
    local fillLevel = streamReadFloat32(streamId)
    local i = self:getFillUnitByIndex(spec.fillUnitIndex)
    if i ~= nil then
        i.fillLevel = fillLevel
    end
end
function Baler:onWriteStream(streamId, _)
    local spec = self.spec_baler
    if spec.hasUnloadingAnimation then
        streamWriteUIntN(streamId, spec.unloadingState, 7)
        local animTime = 0
        if spec.unloadingState == Baler.UNLOADING_CLOSED or spec.unloadingState == Baler.UNLOADING_CLOSING then
            animTime = self:getRealAnimationTime(spec.baleCloseAnimationName)
        elseif spec.unloadingState == Baler.UNLOADING_OPEN or spec.unloadingState == Baler.UNLOADING_OPENING then
            animTime = self:getRealAnimationTime(spec.baleUnloadAnimationName)
        end
        streamWriteFloat32(streamId, animTime)
    end
    streamWriteUInt8(streamId, #spec.bales)
    local i = 1
    local animTime = #spec.bales
    for i = i, animTime do
        local bale = spec.bales[i]
        streamWriteIntN(streamId, bale.fillType, FillTypeManager.SEND_NUM_BITS)
        streamWriteFloat32(streamId, bale.fillLevel)
        if spec.baleAnimCurve ~= nil then
            streamWriteFloat32(streamId, bale.time)
        end
    end
    streamWriteBool(streamId, spec.lastAreaBiggerZero)
    if spec.hasPlatform then
        streamWriteBool(streamId, spec.platformReadyToDrop)
    end
    streamWriteUIntN(streamId, spec.currentBaleTypeIndex, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
    streamWriteUIntN(streamId, spec.preSelectedBaleTypeIndex, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
    streamWriteFloat32(streamId, self:getFillUnitCapacity(spec.fillUnitIndex))
    streamWriteFloat32(streamId, self:getFillUnitFillLevel(spec.fillUnitIndex))
end
function Baler:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        self.spec_baler.lastAreaBiggerZero = streamReadBool(streamId)
        spec.fillEffectType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
        spec.showBaleLimitWarning = streamReadBool(streamId)
        if spec.nonStopBaling then
            spec.buffer.unloadingStarted = streamReadBool(streamId)
            if spec.buffer.unloadingStarted then
                local fillType = self:getFillUnitFillType(spec.buffer.fillUnitIndex)
                if fillType == FillType.UNKNOWN then
                    fillType = self:getFillUnitFillType(spec.fillUnitIndex)
                end
                g_effectManager:setEffectTypeInfo(spec.buffer.overloadingEffects, fillType)
                g_effectManager:startEffects(spec.buffer.overloadingEffects)
                g_soundManager:playSamples(spec.buffer.samplesOverloadingStart)
                g_soundManager:playSamples(spec.buffer.samplesOverloadingWork, 0, spec.buffer.samplesOverloadingStart[0])
                g_animationManager:startAnimations(spec.buffer.overloadingAnimationNodes)
            else
                g_effectManager:stopEffects(spec.buffer.overloadingEffects)
                g_soundManager:stopSamples(spec.buffer.samplesOverloadingStart)
                if g_soundManager:getIsSamplePlaying(spec.buffer.samplesOverloadingWork[0]) then
                    g_soundManager:stopSamples(spec.buffer.samplesOverloadingWork)
                    g_soundManager:playSamples(spec.buffer.samplesOverloadingStop)
                end
                g_animationManager:stopAnimations(spec.buffer.overloadingAnimationNodes)
            end
        end
        spec.additives.isActive = streamReadBool(streamId)
        if spec.additives.isActive then
            g_effectManager:setEffectTypeInfo(spec.additiveEffects, FillType.LIQUIDFERTILIZER)
            g_effectManager:startEffects(spec.additiveEffects)
            return
        end
        g_effectManager:stopEffects(spec.additiveEffects)
    end
end
function Baler:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spec_baler.dirtyFlag) ~= 0) then
            streamWriteBool(streamId, spec.lastAreaBiggerZero)
            streamWriteUIntN(streamId, spec.fillEffectTypeSent, FillTypeManager.SEND_NUM_BITS)
            streamWriteBool(streamId, spec.showBaleLimitWarning)
            if spec.nonStopBaling then
                streamWriteBool(streamId, spec.buffer.unloadingStarted)
            end
            streamWriteBool(streamId, spec.additives.isActive)
        end
    end
end
function Baler:onUpdate(dt, _, _, _)
    if self.isClient then
        if self.spec_baler.baleToMount ~= nil then
            local baleObject = NetworkUtil.getObject(spec.baleToMount.baleServerId)
            if baleObject ~= nil then
                baleObject:mountKinematic(self, spec.baleToMount.jointNode, 0, 0, 0, 0, 0, 0)
                spec.baleToMount.baleInfo.baleObject = baleObject
                spec.baleToMount.baleInfo.baleServerId = spec.baleToMount.baleServerId
                spec.baleToMount = nil
            end
        end
        local baleObject = spec.baleTypes[spec.currentBaleTypeIndex]
        if baleObject ~= nil and #baleObject.detailVisibilityCutNodes > 0 then
            local i = 1
            local targetLiterPerSecond = #spec.bales
            local fillTypeIndex = 1
            for i = i, targetLiterPerSecond, fillTypeIndex do
                local bale = spec.bales[i]
                if bale.baleObject ~= nil then
                    bale.baleObject:resetDetailVisibilityCut()
                    if bale.time < 1 then
                        local j = 1
                        for j = j, #baleObject.detailVisibilityCutNodes do
                            local detailVisibilityCutNode = baleObject.detailVisibilityCutNodes[j]
                            bale.baleObject:setDetailVisibilityCutNode(detailVisibilityCutNode.node, detailVisibilityCutNode.axis, detailVisibilityCutNode.direction)
                        end
                    end
                end
            end
            if spec.dummyBale.currentBale ~= nil then
                local i = 1
                for i = i, #baleObject.detailVisibilityCutNodes do
                    local bale = baleObject.detailVisibilityCutNodes[i]
                    Bale.setBaleMeshVisibilityCut(spec.dummyBale.currentBale, bale.node, bale.axis, bale.direction, true)
                end
            end
        end
    end
    if self.isServer then
        if self.isAddedToPhysics and (spec.createBaleNextFrame ~= nil and spec.createBaleNextFrame) then
            self:finishBale()
            spec.createBaleNextFrame = nil
        end
        if spec.variableSpeedLimit.enabled then
            spec.variableSpeedLimit.pickupPerSecondTimer = spec.variableSpeedLimit.pickupPerSecondTimer + dt
            if spec.variableSpeedLimit.pickupPerSecondTimer > spec.variableSpeedLimit.changeInterval then
                local baleObject = spec.variableSpeedLimit.defaultSpeedLimit
                local targetLiterPerSecond = spec.variableSpeedLimit.targetLiterPerSecond
                local fillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)
                if fillTypeIndex == FillType.UNKNOWN and spec.nonStopBaling then
                    fillTypeIndex = self:getFillUnitFillType(spec.buffer.fillUnitIndex)
                end
                if fillTypeIndex ~= nil and spec.variableSpeedLimit.fillTypeToTargetLiterPerSecond[fillTypeIndex] ~= nil then
                    local i = spec.variableSpeedLimit.fillTypeToTargetLiterPerSecond[fillTypeIndex]
                    baleObject = i.defaultSpeedLimit
                    targetLiterPerSecond = i.targetLiterPerSecond
                end
                local i = spec.variableSpeedLimit.pickupPerSecond / (spec.variableSpeedLimit.changeInterval / 1000)
                if i > 0 then
                    if spec.variableSpeedLimit.usedBackupSpeedLimit then
                        spec.variableSpeedLimit.usedBackupSpeedLimit = false
                        self.speedLimit = spec.variableSpeedLimit.lastAdjustedSpeedLimit or baleObject
                        if (spec.variableSpeedLimit.lastAdjustedSpeedLimitType or fillTypeIndex) ~= fillTypeIndex then
                            self.speedLimit = baleObject
                        end
                    end
                    local bale = targetLiterPerSecond * 0.15
                    local j = i * 2 / targetLiterPerSecond
                    local changeAmount = math.max(math.floor(j), 1)
                    if targetLiterPerSecond + bale < i then
                        self.speedLimit = math.max(self.speedLimit - changeAmount, spec.variableSpeedLimit.minSpeedLimit)
                    elseif i < targetLiterPerSecond - bale then
                        self.speedLimit = math.min(self.speedLimit + changeAmount, spec.variableSpeedLimit.maxSpeedLimit)
                    end
                    spec.variableSpeedLimit.lastAdjustedSpeedLimit = self.speedLimit
                    spec.variableSpeedLimit.lastAdjustedSpeedLimitType = fillTypeIndex
                else
                    spec.variableSpeedLimit.usedBackupSpeedLimit = true
                    self.speedLimit = spec.variableSpeedLimit.backupSpeedLimit
                end
                spec.variableSpeedLimit.pickupPerSecondTimer = 0
                spec.variableSpeedLimit.pickupPerSecond = 0
            end
        end
    end
end
function Baler:onUpdateTick(dt, _, _, _)
    local spec = self.spec_baler
    local showBaleLimitWarning = false
    local isTurnedOn = self:getIsTurnedOn()
    if isTurnedOn then
        showBaleLimitWarning = not g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_BALE, 1) and true or showBaleLimitWarning
        if self.isClient then
            if spec.lastAreaBiggerZero and spec.fillEffectType ~= FillType.UNKNOWN then
                spec.lastAreaBiggerZeroTime = 500
            elseif spec.lastAreaBiggerZeroTime > 0 then
                spec.lastAreaBiggerZeroTime = math.max(spec.lastAreaBiggerZeroTime - dt, 0)
            end
            if spec.lastAreaBiggerZeroTime > 0 then
                if spec.fillEffectType ~= FillType.UNKNOWN then
                    g_effectManager:setEffectTypeInfo(spec.fillEffects, spec.fillEffectType)
                end
                g_effectManager:startEffects(spec.fillEffects)
                local loadPercentage = spec.pickUpLitersBuffer:get(1000) / spec.maxPickupLitersPerSecond
                g_effectManager:setDensity(spec.fillEffects, (math.max(loadPercentage, 0.4)))
            else
                g_effectManager:stopEffects(spec.fillEffects)
            end
            if spec.knotCleaningTimer <= g_currentMission.time then
                g_soundManager:playSample(spec.samples.knotCleaning)
                spec.knotCleaningTimer = g_currentMission.time + spec.knotCleaningTime
            end
            if spec.compactingAnimation ~= nil and spec.unloadingState == Baler.UNLOADING_CLOSED then
                if spec.compactingAnimationTime <= g_currentMission.time then
                    local loadPercentage = self:getFillUnitFillLevelPercentage(spec.fillUnitIndex)
                    local stopTime = MathUtil.lerp(spec.compactingAnimationMinTime, spec.compactingAnimationMaxTime, loadPercentage)
                    if stopTime > 0 then
                        self:setAnimationStopTime(spec.compactingAnimation, (math.clamp(stopTime, 0, 1)))
                        self:playAnimation(spec.compactingAnimation, spec.compactingAnimationSpeed, self:getAnimationTime(spec.compactingAnimation), false)
                        spec.compactingAnimationTime = math.huge
                    end
                end
                if spec.compactingAnimationTime == math.huge and not self:getIsAnimationPlaying(spec.compactingAnimation) then
                    spec.compactingAnimationCompactTimer = spec.compactingAnimationCompactTimer - dt
                    if spec.compactingAnimationCompactTimer < 0 then
                        self:playAnimation(spec.compactingAnimation, -spec.compactingAnimationSpeed, self:getAnimationTime(spec.compactingAnimation), false)
                        spec.compactingAnimationCompactTimer = spec.compactingAnimationCompactTime
                    end
                    if self:getAnimationTime(spec.compactingAnimation) == 0 then
                        spec.compactingAnimationTime = g_currentMission.time + spec.compactingAnimationInterval
                    end
                end
            end
        end
    elseif spec.isBaleUnloading and self.isServer then
        self:moveBales(dt / spec.baleUnloadingTime)
    end
    if self.isClient and spec.unloadingState == Baler.UNLOADING_OPEN then
        local loadPercentage = spec.baleTypes[spec.currentBaleTypeIndex]
        if getNumOfChildren(loadPercentage.baleNode) > 0 then
            delete(getChildAt(loadPercentage.baleNode, 0))
        end
    end
    if spec.unloadingState == Baler.UNLOADING_OPENING then
        local loadPercentage = spec.baleTypes[spec.currentBaleTypeIndex]
        local stopTime = self:getIsAnimationPlaying(loadPercentage.animations.unloading)
        if stopTime and self:getRealAnimationTime(loadPercentage.animations.unloading) < loadPercentage.animations.dropAnimationTime then
            g_animationManager:startAnimations(spec.unloadAnimationNodes)
        else
            if #spec.bales > 0 then
                self:dropBale(1)
                if self.isServer then
                    self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, self:getFillUnitFillType(spec.fillUnitIndex), ToolType.UNDEFINED)
                    spec.buffer.unloadingStarted = false
                    for fillType, _ in pairs(spec.pickupFillTypes) do
                        spec.pickupFillTypes[fillType] = 0
                    end
                    if self:getFillUnitFillLevel(spec.fillUnitIndex) == 0 and spec.preSelectedBaleTypeIndex ~= spec.currentBaleTypeIndex then
                        self:setBaleTypeIndex(spec.preSelectedBaleTypeIndex, true)
                    end
                end
            end
            if not stopTime then
                spec.unloadingState = Baler.UNLOADING_OPEN
                if self.isClient then
                    g_soundManager:stopSample(spec.samples.eject)
                    g_soundManager:stopSample(spec.samples.door)
                    g_animationManager:stopAnimations(spec.unloadAnimationNodes)
                end
            end
        end
    elseif spec.unloadingState == Baler.UNLOADING_CLOSING and not self:getIsAnimationPlaying(spec.baleCloseAnimationName) then
        spec.unloadingState = Baler.UNLOADING_CLOSED
        if self.isClient then
            g_soundManager:stopSample(spec.samples.door)
        end
    end
    if (spec.unloadingState == Baler.UNLOADING_OPEN or spec.unloadingState == Baler.UNLOADING_CLOSING) and (not self.isServer and #spec.bales > 0) then
        self:dropBale(1)
    end
    Baler.updateActionEvents(self)
    if self.isServer then
        if spec.automaticDrop ~= nil and spec.automaticDrop or self:getIsAIActive() then
            if self:isUnloadingAllowed() and (spec.hasUnloadingAnimation or spec.allowsBaleUnloading) and (spec.unloadingState == Baler.UNLOADING_CLOSED and #spec.bales > 0) then
                self:setIsUnloadingBale(true)
            end
            if spec.hasUnloadingAnimation and spec.unloadingState == Baler.UNLOADING_OPEN then
                self:setIsUnloadingBale(false)
            end
        end
        spec.pickUpLitersBuffer:add(spec.workAreaParameters.lastPickedUpLiters)
        if spec.additives.isActiveTimer > 0 then
            spec.additives.isActiveTimer = spec.additives.isActiveTimer - dt
            if spec.additives.isActiveTimer < 0 then
                spec.additives.isActiveTimer = 0
                spec.additives.isActive = false
                if self.isClient then
                    g_effectManager:stopEffects(spec.additiveEffects)
                end
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
        end
        if spec.platformAutomaticDrop and spec.platformReadyToDrop then
            self:dropBaleFromPlatform(true)
        end
        if spec.hasPlatform then
            if #spec.bales > 0 and spec.platformReadyToDrop then
                self:dropBaleFromPlatform(true)
            end
            if spec.hasDynamicMountPlatform then
                if spec.platformMountDelay > 0 then
                    spec.platformMountDelay = spec.platformMountDelay - 1
                    if spec.platformMountDelay == 0 then
                        self:forceDynamicMountPendingObjects(true)
                    end
                elseif spec.platformReadyToDrop and not self:getHasDynamicMountedObjects() then
                    self:dropBaleFromPlatform(false)
                end
            end
        end
        if spec.nonStopBaling then
            local stopTime = self:getFillUnitFillLevel(spec.buffer.fillUnitIndex)
            if stopTime > 0 then
                local animTime = self:getFillUnitCapacity(spec.buffer.fillUnitIndex)
                if isTurnedOn and MathUtil.round(stopTime / animTime, 2) >= spec.buffer.overloadingStartFillLevelPct then
                    local delta = self:getFillUnitCapacity(spec.fillUnitIndex)
                    if (delta == 0 or (delta == math.huge or self:getFillUnitFreeCapacity(spec.fillUnitIndex) > 0)) and (not spec.buffer.unloadingStarted and spec.unloadingState == Baler.UNLOADING_CLOSED) then
                        spec.buffer.unloadingStarted = true
                        spec.buffer.overloadingTimer = 0
                        if spec.buffer.overloadAnimation ~= nil then
                            self:playAnimation(spec.buffer.overloadAnimation, spec.buffer.overloadAnimationSpeed)
                        end
                    end
                end
                if spec.buffer.unloadingStarted then
                    spec.buffer.overloadingTimer = spec.buffer.overloadingTimer + dt
                    if spec.buffer.overloadingTimer >= spec.buffer.overloadingDelay and self:getFillUnitFreeCapacity(spec.fillUnitIndex) > 0 then
                        local sourceFillType = self:getFillUnitCapacity(spec.buffer.fillUnitIndex) / spec.buffer.overloadingDuration * dt
                        local delta = math.min(sourceFillType, stopTime)
                        local sourceFillType = self:getFillUnitFillType(spec.buffer.fillUnitIndex)
                        local unloadInfo = self:getFillVolumeUnloadInfo(spec.buffer.unloadInfoIndex)
                        local fillType = self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.buffer.fillUnitIndex, -delta, sourceFillType, ToolType.UNDEFINED, unloadInfo)
                        local _ = self:getFillUnitFillType(spec.fillUnitIndex)
                        if _ ~= FillType.UNKNOWN then
                            sourceFillType = _
                        end
                        local overloadedLiters = -fillType
                        if spec.additives.available and spec.additives.appliedByBufferOverloading then
                            local fillTypeSupported = false
                            local i = 1
                            local additivesFillLevel = #spec.additives.fillTypes
                            local usage = 1
                            for i = i, additivesFillLevel, usage do
                                if sourceFillType == spec.additives.fillTypes[i] then
                                    fillTypeSupported = true
                                    break
                                end
                            end
                            if fillTypeSupported then
                                local additivesFillLevel = self:getFillUnitFillLevel(spec.additives.fillUnitIndex)
                                if additivesFillLevel > 0 then
                                    local usage = spec.additives.usage * overloadedLiters
                                    if usage > 0 then
                                        overloadedLiters = overloadedLiters * (1 + 0.05 * math.min(additivesFillLevel / usage, 1))
                                        self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.additives.fillUnitIndex, -usage, self:getFillUnitFillType(spec.additives.fillUnitIndex), ToolType.UNDEFINED)
                                        spec.additives.isActiveTimer = 250
                                        spec.additives.isActive = true
                                        self:raiseDirtyFlags(spec.dirtyFlag)
                                        if self.isClient then
                                            g_effectManager:setEffectTypeInfo(spec.additiveEffects, FillType.LIQUIDFERTILIZER)
                                            g_effectManager:startEffects(spec.additiveEffects)
                                        end
                                    end
                                end
                            end
                        end
                        self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, overloadedLiters, sourceFillType, ToolType.UNDEFINED, nil)
                        if spec.buffer.fillLevelToEmpty > 0 then
                            spec.buffer.fillLevelToEmpty = math.max(spec.buffer.fillLevelToEmpty - delta, 0)
                            if spec.buffer.fillLevelToEmpty == 0 then
                                spec.platformDelayedDropping = true
                                spec.buffer.unloadingStarted = false
                            end
                        end
                    end
                    if self:getFillUnitFillLevelPercentage(spec.fillUnitIndex) == 1 or not isTurnedOn then
                        spec.buffer.unloadingStarted = false
                    end
                end
            elseif not spec.buffer.fillMainUnitAfterOverload then
                spec.buffer.unloadingStarted = false
            end
            if spec.buffer.unloadingStarted ~= spec.buffer.unloadingStarted then
                if self.isClient then
                    if spec.buffer.unloadingStarted then
                        local animTime = self:getFillUnitFillType(spec.buffer.fillUnitIndex)
                        g_effectManager:setEffectTypeInfo(spec.buffer.overloadingEffects, animTime)
                        g_effectManager:startEffects(spec.buffer.overloadingEffects)
                        g_animationManager:startAnimations(spec.buffer.overloadingAnimationNodes)
                        g_soundManager:playSamples(spec.buffer.samplesOverloadingStart)
                        g_soundManager:playSamples(spec.buffer.samplesOverloadingWork, 0, spec.buffer.samplesOverloadingStart[1])
                    else
                        g_effectManager:stopEffects(spec.buffer.overloadingEffects)
                        g_animationManager:stopAnimations(spec.buffer.overloadingAnimationNodes)
                        g_soundManager:stopSamples(spec.buffer.samplesOverloadingStart)
                        if g_soundManager:getIsSamplePlaying(spec.buffer.samplesOverloadingWork[1]) then
                            g_soundManager:stopSamples(spec.buffer.samplesOverloadingWork)
                            g_soundManager:playSamples(spec.buffer.samplesOverloadingStop)
                        end
                    end
                end
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
            if spec.buffer.overloadAnimation ~= nil and (not self:getIsAnimationPlaying(spec.buffer.overloadAnimation) and self:getAnimationTime(spec.buffer.overloadAnimation) > 0.5) then
                self:playAnimation(spec.buffer.overloadAnimation, -spec.buffer.overloadAnimationSpeed)
            end
            if isTurnedOn then
                self:raiseActive()
            end
        end
    end
    if self.isServer and spec.showBaleLimitWarning ~= showBaleLimitWarning then
        spec.showBaleLimitWarning = showBaleLimitWarning
        self:raiseDirtyFlags(spec.dirtyFlag)
    end
    if spec.hasPlatform then
        if spec.platformDelayedDropping and not spec.platformDropInProgress then
            Baler.actionEventUnloading(self)
            spec.platformDelayedDropping = false
        end
        if spec.platformDropInProgress and not self:getIsAnimationPlaying(spec.platformAnimation) then
            spec.platformDropInProgress = false
        end
    end
end
function Baler:onDraw()
    local spec = self.spec_baler
    if spec.showBaleLimitWarning then
        g_currentMission:showBlinkingWarning(spec.texts.warningTooManyBales, 100)
    end
end
function Baler:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    local spec = self.spec_baler
    if #spec.bales > 0 and self:getFillUnitFillLevel(spec.fillUnitIndex) > spec.baleFoldThreshold then
        return false, spec.texts.warningFoldingBaleLoaded
    elseif #spec.bales > 1 then
        return false, spec.texts.warningFoldingBaleLoaded
    elseif self:getIsTurnedOn() then
        return false, spec.texts.warningFoldingTurnedOn
    elseif spec.hasPlatform and (spec.platformReadyToDrop or spec.platformDropInProgress) then
        return false, spec.texts.warningFoldingBaleLoaded
    else
        return superFunc(self, direction, onAiTurnOn)
    end
end
function Baler:onChangedFillType(fillUnitIndex, fillTypeIndex, _)
    local spec = self.spec_baler
    if fillUnitIndex == spec.fillUnitIndex or fillUnitIndex == spec.buffer.fillUnitIndex then
        local mainFillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)
        if mainFillTypeIndex == FillType.UNKNOWN then
            mainFillTypeIndex = fillTypeIndex
        end
        if mainFillTypeIndex ~= FillType.UNKNOWN then
            local baleTypeDef = spec.baleTypes[spec.currentBaleTypeIndex]
            spec.currentBaleTypeDefinition = baleTypeDef
            spec.currentBaleXMLFilename, spec.currentBaleIndex = g_baleManager:getBaleXMLFilename(mainFillTypeIndex, baleTypeDef.isRoundBale, baleTypeDef.width, baleTypeDef.height, baleTypeDef.length, baleTypeDef.diameter, self.customEnvironment)
            local baleCapacity = g_baleManager:getBaleCapacityByBaleIndex(spec.currentBaleIndex, mainFillTypeIndex)
            if fillUnitIndex == spec.fillUnitIndex then
                self:setFillUnitCapacity(fillUnitIndex, baleCapacity, false)
            elseif spec.buffer.capacityPercentage ~= nil then
                self:setFillUnitCapacity(fillUnitIndex, baleCapacity * spec.buffer.capacityPercentage, false)
            end
            ObjectChangeUtil.setObjectChanges(baleTypeDef.changeObjects, true, self, self.setMovingToolDirty)
            if spec.currentBaleXMLFilename == nil then
                Logging.warning("Could not find bale for given bale type definition \'%s\'", baleTypeDef.index)
            end
        end
    end
end
function Baler:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, _, appliedDelta)
    local spec = self.spec_baler
    if fillUnitIndex == spec.fillUnitIndex then
        local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
        local capacity = self:getFillUnitCapacity(spec.fillUnitIndex)
        if self:updateDummyBale(spec.dummyBale, fillTypeIndex, fillLevel, capacity) then
            local i = 1
            for i = i, #spec.baleTypes do
                self:setAnimationTime(spec.baleTypes[i].animations.fill, 0)
            end
        end
        if fillLevel > 0 then
            self:setAnimationTime(spec.baleTypes[spec.currentBaleTypeIndex].animations.fill, fillLevel / capacity)
        end
        if self.isServer and fillLevelDelta > 0 then
            if self:getFillUnitFreeCapacity(spec.fillUnitIndex) <= 0 then
                if self.isAddedToPhysics then
                    self:finishBale()
                else
                    spec.createBaleNextFrame = true
                end
                spec.fillUnitOverflowFillLevel = fillLevelDelta - appliedDelta
                return
            end
            if spec.fillUnitOverflowFillLevel > 0 and fillLevelDelta > 0 then
                local overflow = spec.fillUnitOverflowFillLevel
                spec.fillUnitOverflowFillLevel = 0
                spec.fillUnitOverflowFillLevel = overflow - self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, overflow, fillTypeIndex, toolType)
                return
            end
        end
    elseif spec.nonStopBaling and (fillUnitIndex == spec.buffer.fillUnitIndex and spec.buffer.dummyBale.available) then
        local baleTypeDef = self:getFillUnitFillLevel(spec.buffer.fillUnitIndex)
        local fillLevel = self:getFillUnitCapacity(spec.buffer.fillUnitIndex)
        if spec.buffer.overloadAnimation ~= nil and (self:getAnimationTime(spec.buffer.overloadAnimation) > 0 and baleTypeDef > 0) then
            return
        end
        self:updateDummyBale(spec.buffer.dummyBale, fillTypeIndex, baleTypeDef, fillLevel)
    end
end
function Baler:onConsumableVariationChanged(_, metaData)
    if metaData.bale_variation ~= nil then
        self.spec_baler.lastBaleVariationId = metaData.bale_variation
    end
end
function Baler:onTurnedOn()
    if self.setFoldState ~= nil and #self.spec_foldable.foldingParts > 0 then
        self:setFoldState(self.spec_foldable.turnOnFoldDirection, false, true)
    end
    if self.isClient then
        local spec = self.spec_baler
        g_animationManager:startAnimations(spec.animationNodes)
        g_soundManager:playSample(spec.samples.work)
    end
    self:raiseActive()
end
function Baler:onTurnedOff()
    if self.isClient then
        local spec = self.spec_baler
        g_effectManager:stopEffects(spec.fillEffects)
        g_effectManager:stopEffects(spec.additiveEffects)
        g_effectManager:stopEffects(spec.buffer.overloadingEffects)
        g_animationManager:stopAnimations(spec.animationNodes)
        g_soundManager:stopSample(spec.samples.work)
        g_soundManager:stopSample(spec.samples.eject)
        g_soundManager:stopSample(spec.samples.unload)
        g_soundManager:stopSample(spec.samples.door)
        g_soundManager:stopSample(spec.samples.knotCleaning)
        g_soundManager:stopSamples(spec.buffer.samplesOverloadingStart)
        if g_soundManager:getIsSamplePlaying(spec.buffer.samplesOverloadingWork[1]) then
            g_soundManager:stopSamples(spec.buffer.samplesOverloadingWork)
            g_soundManager:playSamples(spec.buffer.samplesOverloadingStop)
        end
    end
end
function Baler:onRootVehicleChanged(rootVehicle)
    local actionController = rootVehicle.actionController
    if actionController == nil then
        if self.spec_baler.controlledAction ~= nil then
            spec.controlledAction:remove()
            spec.controlledAction = nil
        end
        return
    elseif spec.controlledAction == nil then
        spec.controlledAction = actionController:registerAction("baleUnload", nil, 1)
        spec.controlledAction:setCallback(self, Baler.actionControllerBaleUnloadEvent)
        spec.controlledAction:setFinishedFunctions(self, Baler.getIsBaleUnloading, false, false)
    else
        spec.controlledAction:updateParent(actionController)
    end
end
function Baler:actionControllerBaleUnloadEvent(direction)
    if direction < 0 then
        local spec = self.spec_baler
        if self:isUnloadingAllowed() and (spec.allowsBaleUnloading and (spec.unloadingState == Baler.UNLOADING_CLOSED and #spec.bales > 0)) then
            self:setIsUnloadingBale(true)
        end
    end
    return true
end
function Baler:doCheckSpeedLimit(superFunc)
    return not superFunc(self) and self:getIsTurnedOn() and self:getIsLowered()
end
function Baler:setBaleTypeIndex(baleTypeIndex, force, noEventSend)
    local spec = self.spec_baler
    spec.preSelectedBaleTypeIndex = baleTypeIndex
    if self:getFillUnitFillLevel(spec.fillUnitIndex) == 0 or force then
        spec.currentBaleTypeIndex = baleTypeIndex
    end
    Baler.updateActionEvents(self)
    BalerBaleTypeEvent.sendEvent(self, baleTypeIndex, force, noEventSend)
end
function Baler:isUnloadingAllowed()
    local spec = self.spec_baler
    if (spec.platformReadyToDrop or spec.platformDropInProgress) and spec.unloadingState ~= Baler.UNLOADING_OPEN then
        return false
    end
    if self.spec_baleWrapper ~= nil then
        return self:allowsGrabbingBale()
    end
    return (spec.allowsBaleUnloading and true or false) and (spec.allowsBaleUnloading and not self:getIsTurnedOn()) and not spec.isBaleUnloading
end
function Baler:handleUnloadingBaleEvent()
    local spec = self.spec_baler
    if self:isUnloadingAllowed() and (spec.hasUnloadingAnimation or spec.allowsBaleUnloading) then
        if spec.unloadingState == Baler.UNLOADING_CLOSED then
            if #spec.bales > 0 or self:getCanUnloadUnfinishedBale() then
                self:setIsUnloadingBale(true)
                return
            end
        elseif spec.unloadingState == Baler.UNLOADING_OPEN and spec.hasUnloadingAnimation then
            self:setIsUnloadingBale(false)
        end
    end
end
function Baler:dropBaleFromPlatform(waitForNextBale, noEventSend)
    local spec = self.spec_baler
    if spec.platformReadyToDrop then
        self:setAnimationTime(spec.platformAnimation, 0, false)
        self:playAnimation(spec.platformAnimation, 1, self:getAnimationTime(spec.platformAnimation), true)
        if waitForNextBale == true then
            self:setAnimationStopTime(spec.platformAnimation, spec.platformAnimationNextBaleTime)
        end
        spec.platformReadyToDrop = false
        spec.platformDropInProgress = true
        if self.isServer and spec.hasDynamicMountPlatform then
            self:forceUnmountDynamicMountedObjects()
        end
    end
    BalerDropFromPlatformEvent.sendEvent(self, waitForNextBale, noEventSend)
end
function Baler:getBalerBaleOwnerFarmId(x, z)
    local farmlandId
    if self.spec_baler.useDropLandOwnershipForBales then
        local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
        farmlandId = g_farmlandManager:getFarmlandOwner(farmlandId)
    else
        farmlandId = self:getLastTouchedFarmlandFarmId()
    end
    if farmlandId == FarmManager.SPECTATOR_FARM_ID then
        farmlandId = self:getOwnerFarmId()
    end
    return farmlandId
end
function Baler:getIsRoundBaler()
    return self.spec_baler.isRoundBaler
end
function Baler:setIsUnloadingBale(isUnloadingBale, noEventSend)
    local spec = self.spec_baler
    if spec.hasUnloadingAnimation then
        if isUnloadingBale then
            if spec.unloadingState ~= Baler.UNLOADING_OPENING then
                if #spec.bales == 0 and spec.canUnloadUnfinishedBale then
                    local fillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)
                    local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
                    if spec.buffer.fillUnitIndex ~= nil then
                        fillLevel = fillLevel + self:getFillUnitFillLevel(spec.buffer.fillUnitIndex)
                        if fillTypeIndex == FillType.UNKNOWN then
                            fillTypeIndex = self:getFillUnitFillType(spec.buffer.fillUnitIndex)
                        end
                    end
                    if spec.unfinishedBaleThreshold < fillLevel then
                        local delta = self:getFillUnitFreeCapacity(spec.fillUnitIndex)
                        local mainFillLevel = math.min(fillLevel, self:getFillUnitCapacity(spec.fillUnitIndex))
                        if spec.buffer.fillUnitIndex ~= nil then
                            local mainFillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
                            self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.buffer.fillUnitIndex, -math.max(mainFillLevel - mainFillLevel, 0), self:getFillUnitFillType(spec.buffer.fillUnitIndex), ToolType.UNDEFINED)
                        end
                        spec.lastBaleFillLevel = mainFillLevel
                        self:setFillUnitFillLevelToDisplay(spec.fillUnitIndex, mainFillLevel)
                        self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, delta, fillTypeIndex, ToolType.UNDEFINED)
                        spec.buffer.unloadingStarted = false
                    end
                end
                BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
                spec.unloadingState = Baler.UNLOADING_OPENING
                if self.isClient then
                    g_soundManager:playSample(spec.samples.eject)
                    g_soundManager:playSample(spec.samples.door)
                end
                local fillTypeIndex = spec.baleTypes[spec.currentBaleTypeIndex]
                self:playAnimation(fillTypeIndex.animations.unloading, fillTypeIndex.animations.unloadingSpeed, nil, true)
                return
            end
        elseif spec.unloadingState ~= Baler.UNLOADING_CLOSING and spec.unloadingState ~= Baler.UNLOADING_CLOSED then
            BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
            spec.unloadingState = Baler.UNLOADING_CLOSING
            if self.isClient then
                g_soundManager:playSample(spec.samples.door)
            end
            self:playAnimation(spec.baleCloseAnimationName, spec.baleCloseAnimationSpeed, nil, true)
            return
        end
    elseif spec.allowsBaleUnloading and isUnloadingBale then
        BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)
        spec.isBaleUnloading = true
        spec.balesToUnload = #spec.bales
        if self.isClient then
            g_soundManager:playSample(spec.samples.unload)
        end
        SpecializationUtil.raiseEvent(self, "onBalerUnloadingStarted", spec.balesToUnload)
    end
end
function Baler:getIsBaleUnloading()
    return self.spec_baler.isBaleUnloading
end
function Baler:getTimeFromLevel(level)
    local spec = self.spec_baler
    if spec.currentBaleTypeDefinition == nil then
        return 0
    end
    return level / self:getFillUnitCapacity(spec.fillUnitIndex) * ((spec.currentBaleTypeDefinition.length + spec.baleAnimSpacing) / spec.baleAnimLength)
end
function Baler:moveBales(dt)
    local i = #self.spec_baler.bales
    for i = i, 1, -1 do
        self:moveBale(i, dt)
    end
end
function Baler:moveBale(i, dt, noEventSend)
    self:setBaleTime(i, self.spec_baler.bales[i].time + dt, noEventSend)
end
function Baler:setBaleTime(i, baleTime, noEventSend)
    local spec = self.spec_baler
    if spec.baleAnimCurve ~= nil then
        local bale = spec.bales[i]
        if bale ~= nil then
            bale.time = baleTime
            if self.isServer then
                local x, y, z, rx, ry, rz = spec.baleAnimCurve:get(bale.time)
                setTranslation(bale.baleJointNode, x, y, z)
                setRotation(bale.baleJointNode, rx, ry, rz)
                if bale.baleJointIndex ~= 0 then
                    setJointFrame(bale.baleJointIndex, 0, bale.baleJointNode)
                end
            end
            if bale.time >= 1 then
                self:dropBale(i)
            end
            if #spec.bales == 0 then
                spec.isBaleUnloading = false
                if self.isClient then
                    g_soundManager:stopSample(spec.samples.unload)
                end
                SpecializationUtil.raiseEvent(self, "onBalerUnloadingFinished", spec.balesToUnload)
            end
            if self.isServer and (noEventSend == nil or not noEventSend) then
                g_server:broadcastEvent(BalerSetBaleTimeEvent.new(self, i, bale.time), nil, nil, self)
            end
        end
    end
end
function Baler:finishBale()
    local spec = self.spec_baler
    if spec.baleTypes ~= nil then
        local fillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)
        if spec.hasUnloadingAnimation then
            if self:createBale(fillTypeIndex, self:getFillUnitCapacity(spec.fillUnitIndex)) then
                g_server:broadcastEvent(BalerCreateBaleEvent.new(self, fillTypeIndex, 0, NetworkUtil.getObjectId(spec.bales[#spec.bales].baleObject)), nil, nil, self)
                return
            end
            Logging.error("Failed to create bale!")
        else
            self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, fillTypeIndex, ToolType.UNDEFINED)
            spec.buffer.unloadingStarted = false
            for fillType, _ in pairs(spec.pickupFillTypes) do
                spec.pickupFillTypes[fillType] = 0
            end
            if not self:createBale(fillTypeIndex, self:getFillUnitCapacity(spec.fillUnitIndex)) then
                Logging.error("Failed to create bale!")
                return
            end
            g_server:broadcastEvent(BalerCreateBaleEvent.new(self, fillTypeIndex, spec.bales[#spec.bales].time), nil, nil, self)
            if self:getFillUnitFillLevel(spec.fillUnitIndex) == 0 and spec.preSelectedBaleTypeIndex ~= spec.currentBaleTypeIndex then
                self:setBaleTypeIndex(spec.preSelectedBaleTypeIndex, true)
                return
            end
        end
    end
end
function Baler:createBale(baleFillType, fillLevel, baleServerId, baleTime, xmlFilename, ownerFarmId, variationId, loadFromSavegame)
    local spec = self.spec_baler
    if spec.knotingAnimation ~= nil and not loadFromSavegame then
        self:playAnimation(spec.knotingAnimation, spec.knotingAnimationSpeed, nil, true)
    end
    local isValid = false
    if baleTime == nil then
        self:deleteDummyBale(spec.dummyBale)
    end
    local bale = {
        ["filename"] = xmlFilename or spec.currentBaleXMLFilename,
        ["time"] = baleTime
    }
    if bale.time == nil and spec.baleAnimLength ~= nil then
        bale.time = spec.baleTypes[spec.currentBaleTypeIndex].length * 0.5 / spec.baleAnimLength
    end
    bale.fillType = baleFillType
    bale.fillLevel = fillLevel
    if spec.hasUnloadingAnimation then
        if not loadFromSavegame then
            self:updateConsumable(Baler.CONSUMABLE_TYPE_NAME_ROUND, -baleTypeDef.consumableUsage)
        end
        if self.isServer then
            local baleObject = Bale.new(self.isServer, self.isClient)
            local x, y, z = getWorldTranslation(baleTypeDef.baleRootNode)
            local rx, ry, rz = getWorldRotation(baleTypeDef.baleRootNode)
            if baleObject:loadFromConfigXML(bale.filename, x, y, z, rx, ry, rz) then
                baleObject:setFillType(baleFillType)
                baleObject:setFillLevel(fillLevel)
                baleObject:setVariationId(variationId or (spec.lastBaleVariationId or baleTypeDef.defaultBaleVariationId))
                if ownerFarmId == nil then
                    baleObject:setOwnerFarmId(self:getBalerBaleOwnerFarmId(x, z), true)
                else
                    baleObject:setOwnerFarmId(ownerFarmId, true)
                end
                baleObject:register()
                baleObject:mountKinematic(self, baleTypeDef.baleRootNode, 0, 0, 0, 0, 0, 0)
                bale.baleObject = baleObject
                isValid = true
            end
        elseif baleServerId ~= nil then
            local baleObject = NetworkUtil.getObject(baleServerId)
            if baleObject == nil then
                spec.baleToMount = {
                    ["baleServerId"] = baleServerId,
                    ["jointNode"] = baleTypeDef.baleRootNode,
                    ["baleInfo"] = bale
                }
            else
                bale.baleServerId = baleServerId
                baleObject:mountKinematic(self, baleTypeDef.baleRootNode, 0, 0, 0, 0, 0, 0)
            end
            isValid = true
        end
    elseif not loadFromSavegame then
        self:updateConsumable(Baler.CONSUMABLE_TYPE_NAME_SQUARE, -baleTypeDef.consumableUsage)
    end
    if self.isServer and not spec.hasUnloadingAnimation then
        local baleObject, x, y = getWorldTranslation(baleTypeDef.baleRootNode)
        local z, rx, ry = getWorldRotation(baleTypeDef.baleRootNode)
        local rz = createTransformGroup("BaleJointTG")
        link(baleTypeDef.baleRootNode, rz)
        if bale.time == nil then
            setTranslation(rz, 0, 0, 0)
            setRotation(rz, 0, 0, 0)
        else
            local baleObject, constr, baleJointIndex, z, i, i = spec.baleAnimCurve:get(bale.time)
            setTranslation(rz, baleObject, constr, baleJointIndex)
            setRotation(rz, z, i, i)
            baleObject, x, y = getWorldTranslation(rz)
            z, rx, ry = getWorldRotation(rz)
        end
        local baleObject = Bale.new(self.isServer, self.isClient)
        if baleObject:loadFromConfigXML(bale.filename, baleObject, x, y, z, rx, ry) then
            baleObject:setFillType(baleFillType)
            baleObject:setFillLevel(fillLevel)
            baleObject:setVariationId(variationId or (spec.lastBaleVariationId or baleTypeDef.defaultBaleVariationId))
            if ownerFarmId == nil then
                baleObject:setOwnerFarmId(self:getBalerBaleOwnerFarmId(baleObject, y), true)
            else
                baleObject:setOwnerFarmId(ownerFarmId, true)
            end
            baleObject:register()
            baleObject:setCanBeSold(false)
            baleObject:setNeedsSaving(false)
            local constr = JointConstructor.new()
            constr:setActors(baleTypeDef.baleNodeComponent, baleObject.nodeId)
            constr:setJointTransforms(rz, baleObject.nodeId)
            local i = 1
            for i = i, 3 do
                constr:setRotationLimit(i - 1, 0, 0)
                constr:setTranslationLimit(i - 1, true, 0, 0)
            end
            constr:setEnableCollision(false)
            bale.baleJointNode = rz
            bale.baleJointIndex = constr:finalize()
            bale.baleObject = baleObject
            baleObject.baleJointIndex = baleJointIndex
            local i = 1
            local i = 1
            for i = i, #spec.bales, i do
                setPairCollision(spec.bales[i].baleObject.nodeId, baleObject.nodeId, false)
            end
            if not spec.baleAnimEnableCollision then
                setCollisionFilterMask(baleObject.nodeId, 0)
            end
            isValid = true
        end
    elseif not (self.isServer or spec.hasUnloadingAnimation) then
        isValid = true
    end
    if isValid then
        table.insert(spec.bales, bale)
    end
    return isValid
end
function Baler:dropBale(baleIndex)
    local spec = self.spec_baler
    local bale = spec.bales[baleIndex]
    if bale.baleObject ~= nil then
        local mission = g_missionManager:getMissionByUniqueId(spec.workAreaParameters.lastMissionUniqueId)
        if mission ~= nil and mission.addBale ~= nil then
            mission:addBale(bale.baleObject)
        end
    end
    if self.isServer then
        local mission = bale.baleObject
        if bale.baleJointIndex == nil then
            mission:unmountKinematic()
        else
            removeJoint(bale.baleJointIndex)
            delete(bale.baleJointNode)
        end
        if not spec.baleAnimEnableCollision then
            setCollisionFilterMask(mission.nodeId, CollisionPreset.BALE.mask)
        end
        local i = 1
        local baleTypeDef = #spec.bales
        local x = 1
        for i = i, baleTypeDef, x do
            if i ~= baleIndex then
                setPairCollision(spec.bales[i].baleObject.nodeId, mission.nodeId, true)
            end
        end
        if spec.lastBaleFillLevel ~= nil and #spec.bales == 1 then
            mission:setFillLevel(spec.lastBaleFillLevel)
            spec.lastBaleFillLevel = nil
        end
        mission.baleJointIndex = nil
        mission:setCanBeSold(true)
        mission:setNeedsSaving(true)
        if mission.nodeId ~= nil and mission.nodeId ~= 0 then
            local x, i, otherBale = getWorldTranslation(mission.nodeId)
            local vx, vy, vz = getVelocityAtWorldPos(spec.baleTypes[spec.currentBaleTypeIndex].baleNodeComponent or self.components[1].node, x, i, otherBale)
            setLinearVelocity(mission.nodeId, vx, vy, vz)
            g_farmManager:updateFarmStats(self:getBalerBaleOwnerFarmId(x, otherBale), "baleCount", 1)
        end
    elseif spec.hasUnloadingAnimation then
        local mission = NetworkUtil.getObject(bale.baleServerId)
        if mission ~= nil then
            mission:unmountKinematic()
        end
    end
    table.remove(spec.bales, baleIndex)
    if spec.hasPlatform then
        if not spec.platformReadyToDrop then
            spec.platformReadyToDrop = true
        end
        if spec.hasDynamicMountPlatform then
            spec.platformMountDelay = 5
        end
    end
end
function Baler:updateDummyBale(dummyBaleData, fillTypeIndex, fillLevel, capacity)
    local spec = self.spec_baler
    local baleTypeDef = dummyBaleData.baleTypeDef or spec.baleTypes[spec.currentBaleTypeIndex]
    local generatedBale = false
    if (dummyBaleData.linkNode or baleTypeDef.baleNode) ~= nil and (fillLevel > 0 and (fillLevel < capacity and (dummyBaleData.currentBale == nil or dummyBaleData.currentBaleFillType ~= fillTypeIndex))) then
        if dummyBaleData.currentBale ~= nil then
            self:deleteDummyBale(dummyBaleData)
        end
        self:createDummyBale(dummyBaleData, fillTypeIndex)
        generatedBale = true
    end
    if dummyBaleData.currentBale ~= nil then
        local scaleNode = dummyBaleData.linkNode or baleTypeDef.scaleNode
        if scaleNode ~= nil and capacity > 0 then
            local percentage = fillLevel / capacity
            local x = 1
            local y = baleTypeDef.isRoundBale and percentage and percentage or 1
            local scaleComponents = dummyBaleData.scaleComponents or baleTypeDef.scaleComponents
            local z
            if scaleComponents == nil then
                z = percentage
            else
                x = 1
                y = 1
                z = 1
                for axis, value in ipairs(scaleComponents) do
                    if value > 0 then
                        if axis == 1 then
                            x = percentage * value
                        elseif axis == 2 then
                            y = percentage * value
                        else
                            z = percentage * value
                        end
                    end
                end
            end
            setScale(scaleNode, x, y, z)
        end
    end
    return generatedBale
end
function Baler.deleteDummyBale(_, dummyBaleData)
    if dummyBaleData ~= nil then
        if dummyBaleData.currentBale ~= nil then
            delete(dummyBaleData.currentBale)
            dummyBaleData.currentBale = nil
        end
        if dummyBaleData.sharedLoadRequestId ~= nil then
            g_i3DManager:releaseSharedI3DFile(dummyBaleData.sharedLoadRequestId)
            dummyBaleData.sharedLoadRequestId = nil
        end
    end
end
function Baler:createDummyBale(dummyBaleData, fillTypeIndex)
    local spec = self.spec_baler
    if spec.currentBaleXMLFilename ~= nil then
        local baleTypeDef = spec.baleTypes[spec.currentBaleTypeIndex]
        local baleId, sharedLoadRequestId = Bale.createDummyBale(spec.currentBaleXMLFilename, fillTypeIndex, baleTypeDef.chamberBaleVariationId)
        link(dummyBaleData.linkNode or baleTypeDef.baleNode, baleId)
        dummyBaleData.currentBale = baleId
        dummyBaleData.baleTypeDef = baleTypeDef
        dummyBaleData.currentBaleFillType = fillTypeIndex
        dummyBaleData.sharedLoadRequestId = sharedLoadRequestId
    end
end
function Baler:getCanUnloadUnfinishedBale()
    local spec = self.spec_baler
    local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
    if spec.buffer.fillUnitIndex ~= nil then
        fillLevel = fillLevel + self:getFillUnitFillLevel(spec.buffer.fillUnitIndex)
    end
    return spec.canUnloadUnfinishedBale and spec.unfinishedBaleThreshold < fillLevel
end
function Baler:setBalerAutomaticDrop(state, noEventSend)
    local spec = self.spec_baler
    if state == nil then
        if spec.hasPlatform then
            state = not spec.platformAutomaticDrop
        else
            state = not spec.automaticDrop
        end
    end
    if spec.hasPlatform then
        spec.platformAutomaticDrop = state
    else
        spec.automaticDrop = state
    end
    self:requestActionEventUpdate()
    BalerAutomaticDropEvent.sendEvent(self, state, noEventSend)
end
function Baler:getCanBeTurnedOn(superFunc)
    if self.spec_baler.isBaleUnloading then
        return false
    else
        return superFunc(self)
    end
end
function Baler:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
    speedRotatingPart.rotateOnlyIfFillLevelIncreased = xmlFile:getValue(key .. "#rotateOnlyIfFillLevelIncreased", false)
    return superFunc(self, speedRotatingPart, xmlFile, key)
end
function Baler:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
    if speedRotatingPart.rotateOnlyIfFillLevelIncreased == nil or (not speedRotatingPart.rotateOnlyIfFillLevelIncreased or self.spec_baler.lastAreaBiggerZeroTime ~= 0) then
        return superFunc(self, speedRotatingPart)
    else
        return false
    end
end
function Baler.getDefaultSpeedLimit()
    return 25
end
function Baler:getIsWorkAreaActive(superFunc, workArea)
    if g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_BALE, 1) or not self:getIsTurnedOn() then
        if self:getFillUnitFreeCapacity(self.spec_baler.buffer.fillUnitIndex or self.spec_baler.fillUnitIndex) == 0 then
            return false
        elseif self.allowPickingUp == nil or self:allowPickingUp() then
            if self:getConsumableIsAvailable(Baler.CONSUMABLE_TYPE_NAME_ROUND) and self:getConsumableIsAvailable(Baler.CONSUMABLE_TYPE_NAME_SQUARE) then
                if spec.hasUnloadingAnimation and (not spec.nonStopBaling and (#spec.bales > 0 or spec.unloadingState ~= Baler.UNLOADING_CLOSED)) then
                    return false
                else
                    return superFunc(self, workArea)
                end
            else
                return false
            end
        else
            return false
        end
    else
        return false
    end
end
function Baler:getConsumingLoad(superFunc)
    local value, count = superFunc(self)
    local spec = self.spec_baler
    return value + spec.pickUpLitersBuffer:get(1000) / spec.maxPickupLitersPerSecond, count + 1
end
function Baler:getRequiresPower(superFunc)
    local spec = self.spec_baler
    if spec.nonStopBaling then
        if self:getFillUnitFillLevelPercentage(spec.buffer.fillUnitIndex) > spec.buffer.overloadingStartFillLevelPct then
            return true
        end
        if spec.buffer.unloadingStarted then
            return true
        end
    end
    return spec.unloadingState ~= Baler.UNLOADING_CLOSED and true or (self:getIsTurnedOn() and true or superFunc(self))
end
function Baler:getCanBeSelected(superFunc)
    return true
end
function Baler:getIsAttachedTo(superFunc, vehicle)
    if superFunc(self, vehicle) then
        return true
    end
    local spec = self.spec_baler
    local i = 1
    for i = i, #spec.bales do
        if spec.bales[i].baleObject == vehicle then
            return true
        end
    end
    return false
end
function Baler:getAllowDynamicMountFillLevelInfo(superFunc)
    return false
end
function Baler:getAlarmTriggerIsActive(superFunc, alarmTrigger)
    local ret = superFunc(self, alarmTrigger)
    if alarmTrigger.needsBaleLoaded and (self.spec_baler ~= nil and #self.spec_baler.bales == 0) then
        return false
    else
        return ret
    end
end
function Baler:loadAlarmTrigger(superFunc, xmlFile, key, alarmTrigger, fillUnit)
    local ret = superFunc(self, xmlFile, key, alarmTrigger, fillUnit)
    alarmTrigger.needsBaleLoaded = xmlFile:getValue(key .. "#needsBaleLoaded", false)
    return ret
end
function Baler:getShowConsumableEmptyWarning(superFunc, typeName)
    if typeName ~= Baler.CONSUMABLE_TYPE_NAME_ROUND and typeName ~= Baler.CONSUMABLE_TYPE_NAME_SQUARE then
        return superFunc(self, typeName)
    end
    return self:getIsTurnedOn() and superFunc(self, typeName)
end
function Baler:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    local spec = self.spec_baler
    for baleIndex, bale in pairs(spec.bales) do
        local baleObject = bale.baleObject
        if baleObject ~= nil then
            bale.baleObject:addToPhysics()
            if not spec.hasUnloadingAnimation then
                local constr = JointConstructor.new()
                constr:setActors(spec.baleTypes[spec.currentBaleTypeIndex].baleNodeComponent, baleObject.nodeId)
                constr:setJointTransforms(bale.baleJointNode, baleObject.nodeId)
                local i = 1
                for i = i, 3 do
                    constr:setRotationLimit(i - 1, 0, 0)
                    constr:setTranslationLimit(i - 1, true, 0, 0)
                end
                constr:setEnableCollision(false)
                bale.baleJointIndex = constr:finalize()
                bale.baleObject = baleObject
                for otherBaleIndex, otherBale in pairs(spec.bales) do
                    if otherBaleIndex ~= baleIndex then
                        setPairCollision(otherBale.baleObject.nodeId, baleObject.nodeId, false)
                    end
                end
            end
        end
    end
    return true
end
function Baler:removeFromPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    local spec = self.spec_baler
    for baleIndex, bale in pairs(spec.bales) do
        if bale.baleObject ~= nil then
            bale.baleObject:removeFromPhysics()
            if not spec.hasUnloadingAnimation and bale.baleJointIndex ~= nil then
                removeJoint(bale.baleJointIndex)
                bale.baleJointIndex = nil
            end
        end
    end
    return true
end
function Baler:processBalerArea(workArea, _)
    local spec = self.spec_baler
    if not self.isServer and self.currentUpdateDistance > Baler.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local lsx, lsy, lsz, lex, ley, lez, lineRadius = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height)
    if self.isServer then
        spec.fillEffectType = FillType.UNKNOWN
    end
    local mission = self:getMissionByWorkArea(workArea)
    for fillTypeIndex, _ in pairs(spec.pickupFillTypes) do
        local pickedUpLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, fillTypeIndex, lsx, lsy, lsz, lex, ley, lez, lineRadius, nil, nil, false, nil)
        if pickedUpLiters > 0 then
            if self.isServer then
                spec.fillEffectType = fillTypeIndex
                if spec.additives.available and not spec.additives.appliedByBufferOverloading then
                    local fillTypeSupported = false
                    local i = 1
                    local additivesFillLevel = #spec.additives.fillTypes
                    local usage = 1
                    for i = i, additivesFillLevel, usage do
                        if fillTypeIndex == spec.additives.fillTypes[i] then
                            fillTypeSupported = true
                            break
                        end
                    end
                    if fillTypeSupported then
                        local additivesFillLevel = self:getFillUnitFillLevel(spec.additives.fillUnitIndex)
                        if additivesFillLevel > 0 then
                            local usage = spec.additives.usage * pickedUpLiters
                            if usage > 0 then
                                pickedUpLiters = pickedUpLiters * (1 + 0.05 * math.min(additivesFillLevel / usage, 1))
                                self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.additives.fillUnitIndex, -usage, self:getFillUnitFillType(spec.additives.fillUnitIndex), ToolType.UNDEFINED)
                                spec.additives.isActiveTimer = 250
                                spec.additives.isActive = true
                                self:raiseDirtyFlags(spec.dirtyFlag)
                                if self.isClient then
                                    g_effectManager:setEffectTypeInfo(spec.additiveEffects, FillType.LIQUIDFERTILIZER)
                                    g_effectManager:startEffects(spec.additiveEffects)
                                end
                            end
                        end
                    end
                end
            end
            spec.pickupFillTypes[fillTypeIndex] = spec.pickupFillTypes[fillTypeIndex] + pickedUpLiters
            spec.workAreaParameters.lastMissionUniqueId = mission ~= nil and mission:getUniqueId() or nil
            spec.workAreaParameters.lastPickedUpLiters = spec.workAreaParameters.lastPickedUpLiters + pickedUpLiters
            return pickedUpLiters, pickedUpLiters
        end
    end
    return 0, 0
end
function Baler:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_baler
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            if not (spec.automaticDrop and spec.platformAutomaticDrop) then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Baler.actionEventUnloading, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            end
            if #spec.baleTypes > 1 then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_BALE_TYPES, self, Baler.actionEventToggleSize, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            end
            if spec.toggleableAutomaticDrop then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, Baler.actionEventToggleAutomaticDrop, false, true, false, true, nil)
                local automaticDropState = spec.automaticDrop
                if spec.hasPlatform then
                    automaticDropState = spec.platformAutomaticDrop
                end
                g_inputBinding:setActionEventText(actionEventId, automaticDropState and spec.toggleAutomaticDropTextNeg or spec.toggleAutomaticDropTextPos)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            end
            Baler.updateActionEvents(self)
        end
    end
end
function Baler:onRegisterExternalActionEvents(trigger, name, _, _)
    if name == "balerDrop" then
        self:registerExternalActionEvent(trigger, name, Baler.externalActionEventUnloadRegister, Baler.externalActionEventUnloadUpdate)
    elseif name == "balerAutomaticDrop" then
        if self.spec_baler.toggleableAutomaticDrop then
            self:registerExternalActionEvent(trigger, name, Baler.externalActionEventAutomaticUnloadRegister, Baler.externalActionEventAutomaticUnloadUpdate)
            return
        end
    elseif name == "balerBaleSize" and #spec.baleTypes > 1 then
        self:registerExternalActionEvent(trigger, name, Baler.externalActionEventBaleTypeRegister, Baler.externalActionEventBaleTypeUpdate)
    end
end
function Baler:onStartWorkAreaProcessing(_)
    if self.isServer then
        self.spec_baler.lastAreaBiggerZero = false
        spec.workAreaParameters.lastPickedUpLiters = 0
    end
end
function Baler:onEndWorkAreaProcessing(_, _)
    if self.isServer then
        local maxFillType = FillType.UNKNOWN
        local maxFillTypeFillLevel = 0
        for fillTypeIndex, fillLevel in pairs(self.spec_baler.pickupFillTypes) do
            if maxFillTypeFillLevel < fillLevel then
                maxFillType = fillTypeIndex
                maxFillTypeFillLevel = fillLevel
            end
        end
        local pickedUpLiters = spec.workAreaParameters.lastPickedUpLiters
        if pickedUpLiters > 0 then
            spec.lastAreaBiggerZero = true
            local deltaLevel = pickedUpLiters * spec.fillScale
            spec.variableSpeedLimit.pickupPerSecond = spec.variableSpeedLimit.pickupPerSecond + deltaLevel
            if not spec.hasUnloadingAnimation then
                self:moveBales((self:getTimeFromLevel(deltaLevel)))
            end
            local deltaTime = spec.fillUnitIndex
            if spec.nonStopBaling then
                if spec.buffer.fillMainUnitAfterOverload and spec.buffer.unloadingStarted then
                    if self:getFillUnitFreeCapacity(spec.fillUnitIndex) <= 0 then
                        deltaTime = spec.buffer.fillUnitIndex
                    end
                else
                    deltaTime = spec.buffer.fillUnitIndex
                end
            end
            if spec.buffer.loadingStateAnimation ~= nil then
                local fillTypeIndex = self:getAnimationTime(spec.buffer.loadingStateAnimation)
                if deltaTime == spec.fillUnitIndex then
                    if fillTypeIndex >= 0.99 then
                        self:playAnimation(spec.buffer.loadingStateAnimation, -spec.buffer.loadingStateAnimationSpeed)
                    end
                elseif fillTypeIndex <= 0.01 then
                    self:playAnimation(spec.buffer.loadingStateAnimation, spec.buffer.loadingStateAnimationSpeed)
                end
            end
            self:setFillUnitFillType(deltaTime, maxFillType)
            self:addFillUnitFillLevel(self:getOwnerFarmId(), deltaTime, deltaLevel, maxFillType, ToolType.UNDEFINED)
        end
        if spec.lastAreaBiggerZero ~= spec.lastAreaBiggerZeroSent then
            self:raiseDirtyFlags(spec.dirtyFlag)
            spec.lastAreaBiggerZeroSent = spec.lastAreaBiggerZero
        end
        if spec.fillEffectType ~= spec.fillEffectTypeSent then
            spec.fillEffectTypeSent = spec.fillEffectType
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    end
end
function Baler:actionEventUnloading(_, _, _, _)
    local spec = self.spec_baler
    if spec.hasPlatform then
        if self:getCanUnloadUnfinishedBale() and not spec.platformReadyToDrop then
            self:handleUnloadingBaleEvent()
        else
            self:dropBaleFromPlatform(false)
        end
    else
        self:handleUnloadingBaleEvent()
        return
    end
end
function Baler:actionEventToggleSize(_, _, _, _)
    local spec = self.spec_baler
    local newIndex = spec.preSelectedBaleTypeIndex + 1
    self:setBaleTypeIndex(#spec.baleTypes < newIndex and 1 or newIndex)
end
function Baler:actionEventToggleAutomaticDrop(_, _, _, _)
    self:setBalerAutomaticDrop()
end
function Baler:updateActionEvents()
    local spec = self.spec_baler
    local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]
    if actionEvent ~= nil then
        local showAction = false
        if not spec.automaticDrop and (self:isUnloadingAllowed() and (spec.hasUnloadingAnimation or spec.allowsBaleUnloading)) then
            if spec.unloadingState == Baler.UNLOADING_CLOSED then
                if self:getCanUnloadUnfinishedBale() then
                    g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unloadUnfinishedBale)
                    showAction = true
                end
                if #spec.bales > 0 then
                    g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unloadBaler)
                    showAction = true
                end
            elseif spec.unloadingState == Baler.UNLOADING_OPEN and spec.hasUnloadingAnimation then
                g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.closeBack)
                showAction = true
            end
        end
        if spec.platformReadyToDrop then
            g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unloadBaler)
            showAction = true
        elseif spec.hasPlatform and (spec.automaticDrop and (self:isUnloadingAllowed() and (spec.hasUnloadingAnimation or spec.allowsBaleUnloading))) and (spec.unloadingState == Baler.UNLOADING_CLOSED and self:getCanUnloadUnfinishedBale()) then
            g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unloadUnfinishedBale)
            showAction = true
        end
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
    end
    if spec.toggleableAutomaticDrop then
        local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA4]
        if actionEvent ~= nil then
            local showAction = spec.automaticDrop
            if spec.hasPlatform then
                showAction = spec.platformAutomaticDrop
            end
            g_inputBinding:setActionEventText(actionEvent.actionEventId, showAction and spec.toggleAutomaticDropTextNeg or spec.toggleAutomaticDropTextPos)
        end
    end
    if #spec.baleTypes > 1 then
        local actionEvent = spec.actionEvents[InputAction.TOGGLE_BALE_TYPES]
        if actionEvent ~= nil then
            local baleSize
            if spec.hasUnloadingAnimation then
                baleSize = spec.baleTypes[spec.preSelectedBaleTypeIndex].diameter
            else
                baleSize = showAction.length
            end
            g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.changeBaleTypeText:format(baleSize * 100))
        end
    end
end
function Baler.externalActionEventUnloadRegister(data, vehicle)
    _, data.actionEventId = g_inputBinding:registerActionEvent(InputAction.IMPLEMENT_EXTRA3, data, function(_, actionName, inputValue, callbackState, isAnalog)
        -- upvalues: (copy) vehicle
        if not vehicle.spec_baler.automaticDrop then
            Baler.actionEventUnloading(vehicle, actionName, inputValue, callbackState, isAnalog)
        end
    end, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end
function Baler.externalActionEventUnloadUpdate(data, vehicle)
    local spec = vehicle.spec_baler
    local showAction = false
    if vehicle:isUnloadingAllowed() and (spec.hasUnloadingAnimation or spec.allowsBaleUnloading) then
        if spec.unloadingState == Baler.UNLOADING_CLOSED then
            if vehicle:getCanUnloadUnfinishedBale() then
                g_inputBinding:setActionEventText(data.actionEventId, spec.texts.unloadUnfinishedBale)
                showAction = true
            end
            if #spec.bales > 0 then
                g_inputBinding:setActionEventText(data.actionEventId, spec.texts.unloadBaler)
                showAction = true
            end
        elseif spec.unloadingState == Baler.UNLOADING_OPEN and spec.hasUnloadingAnimation then
            g_inputBinding:setActionEventText(data.actionEventId, spec.texts.closeBack)
            showAction = true
        end
    end
    if spec.platformReadyToDrop then
        g_inputBinding:setActionEventText(data.actionEventId, spec.texts.unloadBaler)
        showAction = true
    end
    g_inputBinding:setActionEventActive(data.actionEventId, showAction)
end
function Baler.externalActionEventAutomaticUnloadRegister(data, vehicle)
    _, data.actionEventId = g_inputBinding:registerActionEvent(InputAction.IMPLEMENT_EXTRA4, data, function(_, actionName, inputValue, callbackState, isAnalog)
        -- upvalues: (copy) vehicle
        Baler.actionEventToggleAutomaticDrop(vehicle, actionName, inputValue, callbackState, isAnalog)
    end, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end
function Baler.externalActionEventAutomaticUnloadUpdate(data, vehicle)
    local spec = vehicle.spec_baler
    local automaticDropState = spec.automaticDrop
    if spec.hasPlatform then
        automaticDropState = spec.platformAutomaticDrop
    end
    g_inputBinding:setActionEventText(data.actionEventId, automaticDropState and spec.toggleAutomaticDropTextNeg or spec.toggleAutomaticDropTextPos)
end
function Baler.externalActionEventBaleTypeRegister(data, vehicle)
    _, data.actionEventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_BALE_TYPES, data, function(_, actionName, inputValue, callbackState, isAnalog)
        -- upvalues: (copy) vehicle
        Baler.actionEventToggleSize(vehicle, actionName, inputValue, callbackState, isAnalog)
    end, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end
function Baler.externalActionEventBaleTypeUpdate(data, vehicle)
    local spec = vehicle.spec_baler
    local baleSize
    if spec.hasUnloadingAnimation then
        baleSize = spec.baleTypes[spec.preSelectedBaleTypeIndex].diameter
    else
        baleSize = baleTypeDef.length
    end
    g_inputBinding:setActionEventText(data.actionEventId, spec.changeBaleTypeText:format(baleSize * 100))
end
function Baler.loadSpecValueBaleSize(xmlFile, _, _)
    local baleSizeAttributes = {
        ["isRoundBaler"] = false,
        ["minDiameter"] = math.huge,
        ["maxDiameter"] = -math.huge,
        ["minLength"] = math.huge,
        ["maxLength"] = -math.huge
    }
    xmlFile:iterate(xmlFile:getRootName() .. ".baler.baleTypes.baleType", function(_, key)
        -- upvalues: (copy) baleSizeAttributes, (copy) xmlFile
        baleSizeAttributes.isRoundBaler = xmlFile:getValue(key .. "#isRoundBale", baleSizeAttributes.isRoundBaler)
        local diameter = MathUtil.round(xmlFile:getValue(key .. "#diameter", 0), 2)
        baleSizeAttributes.minDiameter = math.min(baleSizeAttributes.minDiameter, diameter)
        baleSizeAttributes.maxDiameter = math.max(baleSizeAttributes.maxDiameter, diameter)
        baleSizeAttributes.minLength = math.min(baleSizeAttributes.minLength, (MathUtil.round(xmlFile:getValue(key .. "#length", 0), 2)))
        baleSizeAttributes.maxLength = math.max(baleSizeAttributes.maxLength, length)
    end)
    if baleSizeAttributes.minDiameter == math.huge and baleSizeAttributes.minLength == math.huge then
        return nil
    else
        return baleSizeAttributes
    end
end
function Baler.getSpecValueBaleSize(storeItem, _, _, _, returnValues, returnRange, roundBale)
    local baleSizeAttributes = roundBale and storeItem.specs.balerBaleSizeRound or storeItem.specs.balerBaleSizeSquare
    if baleSizeAttributes == nil then
        if returnValues and returnRange then
            return 0, 0, ""
        elseif returnValues then
            return 0, ""
        else
            return ""
        end
    elseif returnValues == nil or not returnValues then
        local unit = g_i18n:getText("unit_cmShort")
        if (baleSizeAttributes.isRoundBaler and baleSizeAttributes.maxDiameter or baleSizeAttributes.maxLength) == (baleSizeAttributes.isRoundBaler and baleSizeAttributes.minDiameter or baleSizeAttributes.minLength) then
            return string.format("%d%s", minValue * 100, unit)
        else
            return string.format("%d%s-%d%s", minValue * 100, unit, maxValue * 100, unit)
        end
    elseif returnRange == true and maxValue ~= minValue then
        return minValue * 100, maxValue * 100, g_i18n:getText("unit_cmShort")
    else
        return minValue * 100, g_i18n:getText("unit_cmShort")
    end
end
function Baler.loadSpecValueBaleSizeRound(xmlFile, customEnvironment, baseDir)
    local baleSizeAttributes = Baler.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir)
    if baleSizeAttributes == nil or not baleSizeAttributes.isRoundBaler then
        return nil
    else
        return baleSizeAttributes
    end
end
function Baler.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment, baseDir)
    local baleSizeAttributes = Baler.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir)
    if baleSizeAttributes == nil or baleSizeAttributes.isRoundBaler then
        return nil
    else
        return baleSizeAttributes
    end
end
function Baler.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.balerBaleSizeRound == nil or not storeItem.specs.balerBaleSizeRound.isRoundBaler then
        return nil
    else
        return Baler.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
    end
end
function Baler.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.balerBaleSizeSquare == nil or storeItem.specs.balerBaleSizeSquare.isRoundBaler then
        return nil
    else
        return Baler.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
    end
end