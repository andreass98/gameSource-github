source("dataS/scripts/vehicles/specializations/events/VehicleSetBeaconLightEvent.lua")
source("dataS/scripts/vehicles/specializations/events/VehicleSetTurnLightEvent.lua")
source("dataS/scripts/vehicles/specializations/events/VehicleSetLightEvent.lua")
source("dataS/scripts/vehicles/specializations/components/SharedLight.lua")
source("dataS/scripts/vehicles/specializations/components/BeaconLight.lua")
source("dataS/scripts/vehicles/specializations/components/StaticLight.lua")
source("dataS/scripts/vehicles/specializations/components/StaticLightCompound.lua")
source("dataS/scripts/vehicles/specializations/components/RealLight.lua")
Lights = {}
Lights.TURNLIGHT_OFF = 0
Lights.TURNLIGHT_LEFT = 1
Lights.TURNLIGHT_RIGHT = 2
Lights.TURNLIGHT_HAZARD = 3
Lights.turnLightSendNumBits = 3
Lights.LIGHT_TYPE_DEFAULT = 0
Lights.LIGHT_TYPE_WORK_BACK = 1
Lights.LIGHT_TYPE_WORK_FRONT = 2
Lights.LIGHT_TYPE_HIGHBEAM = 3
Lights.sharedLightXMLSchema = nil
Lights.beaconLightXMLSchema = nil
Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS = {
    "vehicle.lights.sharedLight(?)",
    "vehicle.lights.realLights.low.light(?)",
    "vehicle.lights.realLights.low.topLight(?)",
    "vehicle.lights.realLights.low.bottomLight(?)",
    "vehicle.lights.realLights.low.brakeLight(?)",
    "vehicle.lights.realLights.low.reverseLight(?)",
    "vehicle.lights.realLights.low.turnLightLeft(?)",
    "vehicle.lights.realLights.low.turnLightRight(?)",
    "vehicle.lights.realLights.low.interiorLight(?)",
    "vehicle.lights.realLights.high.light(?)",
    "vehicle.lights.realLights.high.topLight(?)",
    "vehicle.lights.realLights.high.bottomLight(?)",
    "vehicle.lights.realLights.high.brakeLight(?)",
    "vehicle.lights.realLights.high.reverseLight(?)",
    "vehicle.lights.realLights.high.turnLightLeft(?)",
    "vehicle.lights.realLights.high.turnLightRight(?)",
    "vehicle.lights.realLights.high.interiorLight(?)",
    "vehicle.lights.defaultLights.defaultLight(?)",
    "vehicle.lights.topLights.topLight(?)",
    "vehicle.lights.bottomLights.bottomLight(?)",
    "vehicle.lights.brakeLights.brakeLight(?)",
    "vehicle.lights.reverseLights.reverseLight(?)",
    "vehicle.lights.dayTimeLights.dayTimeLight(?)",
    "vehicle.lights.turnLights.turnLightLeft(?)",
    "vehicle.lights.turnLights.turnLightRight(?)",
    "vehicle.lights.staticLightCompounds.staticLightCompound(?).node(?)"
}
function Lights.prerequisitesPresent(specializations)
    return true
end
function Lights.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("beaconLight", g_i18n:getText("configuration_beacon"), "lights", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Lights")
    schema:register(XMLValueType.FLOAT, "vehicle.lights#reverseLightActivationSpeed", "Speed which needs to be reached to activate reverse lights (km/h)", 1)
    schema:register(XMLValueType.VECTOR_N, "vehicle.lights.states.state(?)#lightTypes", "Light states")
    schema:register(XMLValueType.VECTOR_N, "vehicle.lights.states.automaticState#lightTypes", "Light states while ai is active", "0")
    schema:register(XMLValueType.VECTOR_N, "vehicle.lights.states.automaticState#lightTypesWork", "Light states while ai is working", "0 1 2")
    SharedLight.registerXMLPaths(schema, "vehicle.lights.sharedLight(?)")
    Lights.registerRealLightSetupXMLPath(schema, "vehicle.lights.realLights.low")
    Lights.registerRealLightSetupXMLPath(schema, "vehicle.lights.realLights.high")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.defaultLights.defaultLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.topLights.topLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.bottomLights.bottomLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.brakeLights.brakeLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.reverseLights.reverseLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.dayTimeLights.dayTimeLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.turnLights.turnLightLeft(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.turnLights.turnLightRight(?)")
    StaticLightCompound.registerXMLPaths(schema, "vehicle.lights.staticLightCompounds.staticLightCompound(?)")
    BeaconLight.registerVehicleXMLPaths(schema, "vehicle.lights.beaconLights.beaconLight(?)")
    schema:register(XMLValueType.BOOL, "vehicle.lights.beaconLights.beaconLight(?)#alwaysActive", "Defines if the beacon light is always active while the vehicle is entered", false)
    BeaconLight.registerVehicleXMLPaths(schema, "vehicle.lights.beaconLightConfigurations.beaconLightConfiguration(?).beaconLight(?)")
    schema:register(XMLValueType.BOOL, "vehicle.lights.beaconLightConfigurations.beaconLightConfiguration(?).beaconLight(?)#alwaysActive", "Defines if the beacon light is always active while the vehicle is entered", false)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.lights.sounds", "toggleLights")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.lights.sounds", "turnLight")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.lights.dashboards", {
        "lightState",
        "turnLightLeft",
        "turnLightRight",
        "turnLight",
        "turnLightHazard",
        "turnLightAny",
        "beaconLight"
    })
    Dashboard.addDelayedRegistrationFunc(schema, function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. "#lightTypes", "Light types")
        cSchema:register(XMLValueType.VECTOR_N, cKey .. "#excludedLightTypes", "Excluded light types")
    end)
    local i = 1
    for i = i, #Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS do
        local key = Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS[i]
        schema:register(XMLValueType.BOOL, key .. "#isTopLight", "Light is only active when switched to top light mode", false)
        schema:register(XMLValueType.BOOL, key .. "#isBottomLight", "Light is only active when not switched to top light mode", false)
    end
    schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#lightTypes", "Defined light types need to be enabled to activate group")
    schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#excludedLightTypes", "Defined light types need to be disabled to activate group")
    schema:setXMLSpecializationType()
end
function Lights.registerRealLightSetupXMLPath(schema, basePath)
    RealLight.registerXMLPaths(schema, basePath .. ".light(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".topLight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".bottomLight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".brakeLight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".reverseLight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".dayTimeLight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".turnLightLeft(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".turnLightRight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".interiorLight(?)")
end
function Lights.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onTurnLightStateChanged")
    SpecializationUtil.registerEvent(vehicleType, "onTopLightsVisibilityChanged")
    SpecializationUtil.registerEvent(vehicleType, "onBrakeLightsVisibilityChanged")
    SpecializationUtil.registerEvent(vehicleType, "onReverseLightsVisibilityChanged")
    SpecializationUtil.registerEvent(vehicleType, "onLightsTypesMaskChanged")
    SpecializationUtil.registerEvent(vehicleType, "onBeaconLightsVisibilityChanged")
end
function Lights.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadRealLightSetup", Lights.loadRealLightSetup)
    SpecializationUtil.registerFunction(vehicleType, "applyAdditionalActiveLightType", Lights.applyAdditionalActiveLightType)
    SpecializationUtil.registerFunction(vehicleType, "getIsActiveForLights", Lights.getIsActiveForLights)
    SpecializationUtil.registerFunction(vehicleType, "getIsActiveForInteriorLights", Lights.getIsActiveForInteriorLights)
    SpecializationUtil.registerFunction(vehicleType, "getCanToggleLight", Lights.getCanToggleLight)
    SpecializationUtil.registerFunction(vehicleType, "getUseHighProfile", Lights.getUseHighProfile)
    SpecializationUtil.registerFunction(vehicleType, "setNextLightsState", Lights.setNextLightsState)
    SpecializationUtil.registerFunction(vehicleType, "setLightsTypesMask", Lights.setLightsTypesMask)
    SpecializationUtil.registerFunction(vehicleType, "getLightsTypesMask", Lights.getLightsTypesMask)
    SpecializationUtil.registerFunction(vehicleType, "setTurnLightState", Lights.setTurnLightState)
    SpecializationUtil.registerFunction(vehicleType, "getTurnLightState", Lights.getTurnLightState)
    SpecializationUtil.registerFunction(vehicleType, "setTopLightsVisibility", Lights.setTopLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "setBrakeLightsVisibility", Lights.setBrakeLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "setBeaconLightsVisibility", Lights.setBeaconLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "getBeaconLightsVisibility", Lights.getBeaconLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "setReverseLightsVisibility", Lights.setReverseLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "setInteriorLightsVisibility", Lights.setInteriorLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "getInteriorLightBrightness", Lights.getInteriorLightBrightness)
    SpecializationUtil.registerFunction(vehicleType, "deactivateLights", Lights.deactivateLights)
    SpecializationUtil.registerFunction(vehicleType, "getDeactivateLightsOnLeave", Lights.getDeactivateLightsOnLeave)
    SpecializationUtil.registerFunction(vehicleType, "loadSharedLight", Lights.loadSharedLight)
    SpecializationUtil.registerFunction(vehicleType, "loadAdditionalLightAttributesFromXML", Lights.loadAdditionalLightAttributesFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsLightActive", Lights.getIsLightActive)
    SpecializationUtil.registerFunction(vehicleType, "getStaticLightFromNode", Lights.getStaticLightFromNode)
    SpecializationUtil.registerFunction(vehicleType, "getRealLightFromNode", Lights.getRealLightFromNode)
    SpecializationUtil.registerFunction(vehicleType, "updateAutomaticLights", Lights.updateAutomaticLights)
    SpecializationUtil.registerFunction(vehicleType, "lightsWeatherChanged", Lights.lightsWeatherChanged)
    SpecializationUtil.registerFunction(vehicleType, "onLightsProfileChanged", Lights.onLightsProfileChanged)
    SpecializationUtil.registerFunction(vehicleType, "onLightsRealBeaconLightChanged", Lights.onLightsRealBeaconLightChanged)
    SpecializationUtil.registerFunction(vehicleType, "deactivateBeaconLights", Lights.deactivateBeaconLights)
end
function Lights.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Lights.loadDashboardGroupFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Lights.getIsDashboardGroupActive)
end
function Lights.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onStartMotor", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onStopMotor", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onStartReverseDirectionChange", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAutomatedTrainTravelActive", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIDriveableActive", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIDriveableEnd", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerActive", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIJobVehicleBlock", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIJobVehicleContinue", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerEnd", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onVehiclePhysicsUpdate", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onRequiresTopLightsChanged", Lights)
end
function Lights:onLoad(_)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.low.light#decoration", "vehicle.lights.defaultLights#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.high.light#decoration", "vehicle.lights.defaultLights#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.low.light#realLight", "vehicle.lights.realLights.low.light#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.high.light#realLight", "vehicle.lights.realLights.high.light#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.brakeLights.brakeLight#realLight", "vehicle.lights.realLights.high.brakeLight#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.brakeLights.brakeLight#decoration", "vehicle.lights.brakeLights.brakeLight#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#realLight", "vehicle.lights.realLights.high.reverseLight#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#decoration", "vehicle.lights.reverseLights.reverseLight#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightLeft#realLight", "vehicle.lights.realLights.high.turnLightLeft#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightLeft#decoration", "vehicle.lights.turnLights.turnLightLeft#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightRight#realLight", "vehicle.lights.realLights.high.turnLightRight#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightRight#decoration", "vehicle.lights.turnLights.turnLightRight#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#realLight", "vehicle.lights.realLights.high.reverseLight#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#decoration", "vehicle.lights.reverseLights.reverseLight#node")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.states.aiState#lightTypes", "vehicle.lights.states.automaticState#lightTypes")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.states.aiState#lightTypesWork", "vehicle.lights.states.automaticState#lightTypesWork")
    local spec = self.spec_lights
    spec.reverseLightActivationSpeed = self.xmlFile:getValue("vehicle.lights#reverseLightActivationSpeed", 1) / 3600
    spec.sharedLoadRequestIds = {}
    spec.xmlLoadingHandles = {}
    spec.lightsTypesMask = 0
    spec.currentLightState = 0
    spec.maxLightState = Lights.LIGHT_TYPE_HIGHBEAM
    spec.numLightTypes = 0
    spec.lightStates = {}
    spec.lastIsActiveForLights = false
    local i = 0
    while true do
        local key = string.format("vehicle.lights.states.state(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        for _, lightType in pairs(self.xmlFile:getValue(key .. "#lightTypes", nil, true) or {}) do
            if ({})[lightType] == nil then
                registeredLightTypes[lightType] = lightType
                spec.numLightTypes = spec.numLightTypes + 1
                spec.maxLightState = math.max(spec.maxLightState, lightType)
            end
        end
        table.insert(spec.lightStates, lightTypes)
        i = i + 1
    end
    local lightTypes = self.xmlFile:getValue("vehicle.lights.states.automaticState#lightTypes", "0", true)
    local lightsTypesMask = 0
    for _, lightType in pairs(lightTypes) do
        lightsTypesMask = bit32.bor(lightsTypesMask, 2 ^ lightType)
    end
    spec.automaticLightsTypesMask = lightsTypesMask
    local lightTypes = self.xmlFile:getValue("vehicle.lights.states.automaticState#lightTypesWork", "0 1 2", true)
    local lightsTypesMask = 0
    for _, lightType in pairs(lightTypes) do
        lightsTypesMask = bit32.bor(lightsTypesMask, 2 ^ lightType)
    end
    spec.automaticLightsTypesMaskWork = lightsTypesMask
    spec.interiorLightsBrightness = 0
    spec.interiorLightsAvailable = false
    spec.realLights = {}
    spec.realLights.low = {}
    self:loadRealLightSetup(self.xmlFile, "vehicle.lights.realLights.low", spec.realLights.low)
    spec.realLights.high = {}
    self:loadRealLightSetup(self.xmlFile, "vehicle.lights.realLights.high", spec.realLights.high)
    spec.staticLights = {}
    spec.staticLights.defaultLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.defaultLights.defaultLight", self, self.components, self.i3dMappings, true)
    spec.staticLights.topLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.topLights.topLight", self, self.components, self.i3dMappings, false)
    spec.staticLights.bottomLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.bottomLights.bottomLight", self, self.components, self.i3dMappings, false)
    spec.staticLights.brakeLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.brakeLights.brakeLight", self, self.components, self.i3dMappings, false)
    spec.staticLights.reverseLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.reverseLights.reverseLight", self, self.components, self.i3dMappings, false)
    spec.staticLights.dayTimeLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.dayTimeLights.dayTimeLight", self, self.components, self.i3dMappings, false)
    spec.staticLights.turnLightsLeft = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.turnLights.turnLightLeft", self, self.components, self.i3dMappings, false)
    spec.staticLights.turnLightsRight = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.turnLights.turnLightRight", self, self.components, self.i3dMappings, false)
    spec.staticLightCompounds = {}
    for lightsTypesMask, _ in self.xmlFile:iterator("vehicle.lights.staticLightCompounds.staticLightCompound") do
        local lightType = StaticLightCompound.new(self)
        if lightType:loadFromXML(self.xmlFile, _, self.components, self.i3dMappings, self) then
            table.insert(spec.staticLightCompounds, lightType)
        end
    end
    spec.sharedLights = {}
    self.xmlFile:iterate("vehicle.lights.sharedLight", function(_, key)
        -- upvalues: (copy) self
        self:loadSharedLight(self.xmlFile, key)
    end)
    for lightsTypesMask, _ in pairs(spec.staticLights) do
        for lightType, staticLight in ipairs(_) do
            if staticLight.lightTypes ~= nil then
                spec.maxLightState = math.max(spec.maxLightState, unpack(staticLight.lightTypes))
            end
        end
    end
    for lightsTypesMask, _ in pairs(spec.realLights) do
        for lightType, staticLight in pairs(_) do
            for _, realLight in ipairs(staticLight) do
                if realLight.lightTypes ~= nil then
                    spec.maxLightState = math.max(spec.maxLightState, unpack(realLight.lightTypes))
                end
            end
        end
    end
    spec.maxLightStateMask = 2 ^ (spec.maxLightState + 1) - 1
    spec.additionalLightTypes = {}
    spec.additionalLightTypes.bottomLight = spec.maxLightState + 1
    spec.additionalLightTypes.topLight = spec.maxLightState + 2
    spec.additionalLightTypes.brakeLight = spec.maxLightState + 3
    spec.additionalLightTypes.turnLightLeft = spec.maxLightState + 4
    spec.additionalLightTypes.turnLightRight = spec.maxLightState + 5
    spec.additionalLightTypes.turnLightAny = spec.maxLightState + 6
    spec.additionalLightTypes.reverseLight = spec.maxLightState + 7
    spec.additionalLightTypes.interiorLight = spec.maxLightState + 8
    spec.totalNumLightTypes = spec.additionalLightTypes.interiorLight + 1
    if spec.totalNumLightTypes > 31 then
        Logging.xmlError(self.xmlFile, "Max. number of light types reached (31). Please reduce them.")
        spec.totalNumLightTypes = 31
    end
    spec.topLightsVisibility = false
    spec.brakeLightsVisibility = false
    spec.reverseLightsVisibility = false
    spec.turnLightState = Lights.TURNLIGHT_OFF
    spec.turnLightTriState = 0.5
    spec.turnLightRepetitionCount = nil
    spec.actionEventsActiveChange = {}
    spec.beaconLightsActive = false
    spec.beaconLights = {}
    spec.alwaysActiveBeaconLights = {}
    local lightTypes = string.format("vehicle.lights.beaconLightConfigurations.beaconLightConfiguration(%d)", (self.configurations.beaconLight or 1) - 1)
    self.xmlFile:iterate(lightTypes .. ".beaconLight", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        if self.xmlFile:hasProperty(key .. "#alwaysActive") then
            BeaconLight.loadFromVehicleXML(spec.alwaysActiveBeaconLights, self.xmlFile, key, self)
        else
            BeaconLight.loadFromVehicleXML(spec.beaconLights, self.xmlFile, key, self)
        end
    end)
    self.xmlFile:iterate("vehicle.lights.beaconLights.beaconLight", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        if self.xmlFile:hasProperty(key .. "#alwaysActive") then
            BeaconLight.loadFromVehicleXML(spec.alwaysActiveBeaconLights, self.xmlFile, key, self)
        else
            BeaconLight.loadFromVehicleXML(spec.beaconLights, self.xmlFile, key, self)
        end
    end)
    if self.isClient ~= nil then
        spec.samples = {}
        spec.samples.toggleLights = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lights.sounds", "toggleLights", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.turnLight = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lights.sounds", "turnLight", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    if g_currentMission ~= nil and g_currentMission.environment ~= nil then
        g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, self.lightsWeatherChanged, self)
    end
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.LIGHTS_PROFILE], self.onLightsProfileChanged, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.REAL_BEACON_LIGHTS], self.onLightsRealBeaconLightChanged, self)
end
function Lights:onLoadFinished(_)
    local spec = self.spec_lights
    self:applyAdditionalActiveLightType(spec.staticLights.topLights, spec.additionalLightTypes.topLight)
    self:applyAdditionalActiveLightType(spec.staticLights.bottomLights, spec.additionalLightTypes.bottomLight)
    self:applyAdditionalActiveLightType(spec.staticLights.brakeLights, spec.additionalLightTypes.brakeLight)
    self:applyAdditionalActiveLightType(spec.staticLights.reverseLights, spec.additionalLightTypes.reverseLight)
    self:applyAdditionalActiveLightType(spec.staticLights.turnLightsLeft, spec.additionalLightTypes.turnLightLeft, true)
    self:applyAdditionalActiveLightType(spec.staticLights.turnLightsLeft, spec.additionalLightTypes.turnLightAny, true)
    self:applyAdditionalActiveLightType(spec.staticLights.turnLightsRight, spec.additionalLightTypes.turnLightRight, true)
    self:applyAdditionalActiveLightType(spec.staticLights.turnLightsRight, spec.additionalLightTypes.turnLightAny, true)
    for _, profile in pairs(spec.realLights) do
        self:applyAdditionalActiveLightType(profile.topLights, spec.additionalLightTypes.topLight)
        self:applyAdditionalActiveLightType(profile.bottomLights, spec.additionalLightTypes.bottomLight)
        self:applyAdditionalActiveLightType(profile.brakeLights, spec.additionalLightTypes.brakeLight)
        self:applyAdditionalActiveLightType(profile.reverseLights, spec.additionalLightTypes.reverseLight)
        self:applyAdditionalActiveLightType(profile.turnLightsLeft, spec.additionalLightTypes.turnLightLeft, true)
        self:applyAdditionalActiveLightType(profile.turnLightsLeft, spec.additionalLightTypes.turnLightAny, true)
        self:applyAdditionalActiveLightType(profile.turnLightsRight, spec.additionalLightTypes.turnLightRight, true)
        self:applyAdditionalActiveLightType(profile.turnLightsRight, spec.additionalLightTypes.turnLightAny, true)
        self:applyAdditionalActiveLightType(profile.interiorLights, spec.additionalLightTypes.interiorLight)
        for _, lights in pairs(profile) do
            for _, realLight in ipairs(lights) do
                realLight:finalize()
            end
        end
    end
    if self:getIsInShowroom() then
        for _, profile in ipairs(spec.staticLights.dayTimeLights) do
            profile:setState(true)
        end
    end
end
function Lights:onRegisterDashboardValueTypes()
    local spec = self.spec_lights
    local lightState = DashboardValueType.new("lights", "lightState")
    lightState:setValue(spec, function(_, dashboard)
        -- upvalues: (copy) spec, (copy) self
        if dashboard.displayTypeIndex == Dashboard.TYPES.MULTI_STATE then
            return spec.lightsTypesMask
        end
        local lightIsActive = false
        if dashboard.lightTypes ~= nil then
            for _, lightType in pairs(dashboard.lightTypes) do
                if bit32.band(spec.lightsTypesMask, 2 ^ lightType) ~= 0 or lightType == -1 and self:getIsActiveForLights(true) then
                    lightIsActive = true
                    break
                end
            end
        end
        if lightIsActive and dashboard.excludedLightTypes ~= nil then
            for _, lightType in pairs(dashboard.excludedLightTypes) do
                if bit32.band(spec.lightsTypesMask, 2 ^ lightType) ~= 0 then
                    lightIsActive = false
                    break
                end
            end
        end
        return lightIsActive and 1 or 0
    end)
    lightState:setAdditionalFunctions(Lights.dashboardLightAttributes, Lights.dashboardLightState)
    lightState:setPollUpdate(false)
    self:registerDashboardValueType(lightState)
    local turnLightLeft = DashboardValueType.new("lights", "turnLightLeft")
    turnLightLeft:setValue(spec, "turnLightState")
    turnLightLeft:setValueCompare(Lights.TURNLIGHT_LEFT, Lights.TURNLIGHT_HAZARD)
    turnLightLeft:setPollUpdate(false)
    self:registerDashboardValueType(turnLightLeft)
    local turnLightRight = DashboardValueType.new("lights", "turnLightRight")
    turnLightRight:setValue(spec, "turnLightState")
    turnLightRight:setValueCompare(Lights.TURNLIGHT_RIGHT, Lights.TURNLIGHT_HAZARD)
    turnLightRight:setPollUpdate(false)
    self:registerDashboardValueType(turnLightRight)
    local turnLight = DashboardValueType.new("lights", "turnLight")
    turnLight:setValue(spec, "turnLightTriState")
    turnLight:setIdleValue(0.5)
    turnLight:setPollUpdate(false)
    self:registerDashboardValueType(turnLight)
    local turnLightHazard = DashboardValueType.new("lights", "turnLightHazard")
    turnLightHazard:setValue(spec, "turnLightState")
    turnLightHazard:setValueCompare(Lights.TURNLIGHT_HAZARD)
    turnLightHazard:setPollUpdate(false)
    self:registerDashboardValueType(turnLightHazard)
    local turnLightAny = DashboardValueType.new("lights", "turnLightAny")
    turnLightAny:setValue(spec, "turnLightState")
    turnLightAny:setValueCompare(Lights.TURNLIGHT_LEFT, Lights.TURNLIGHT_RIGHT, Lights.TURNLIGHT_HAZARD)
    turnLightAny:setPollUpdate(false)
    self:registerDashboardValueType(turnLightAny)
    local beaconLight = DashboardValueType.new("lights", "beaconLight")
    beaconLight:setValue(spec, function(_spec)
        return _spec.beaconLightsActive and 1 or 0
    end)
    beaconLight:setPollUpdate(false)
    self:registerDashboardValueType(beaconLight)
end
function Lights:onDelete()
    local spec = self.spec_lights
    if spec.sharedLights ~= nil then
        for _, sharedLight in ipairs(spec.sharedLights) do
            sharedLight:delete()
        end
        spec.sharedLights = {}
    end
    if spec.beaconLights ~= nil then
        for _, sharedLight in ipairs(spec.beaconLights) do
            sharedLight:delete()
        end
        spec.beaconLights = {}
    end
    if spec.alwaysActiveBeaconLights ~= nil then
        for _, sharedLight in ipairs(spec.alwaysActiveBeaconLights) do
            sharedLight:delete()
        end
        spec.alwaysActiveBeaconLights = {}
    end
    if spec.xmlLoadingHandles ~= nil then
        for _, sharedLight in pairs(spec.xmlLoadingHandles) do
            _:delete()
            spec.xmlLoadingHandles[_] = nil
        end
    end
    if spec.sharedLoadRequestIds ~= nil then
        for _, sharedLight in ipairs(spec.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLight)
        end
    end
    if spec.staticLightCompounds ~= nil then
        spec.staticLightCompounds = {}
    end
    g_soundManager:deleteSamples(spec.samples)
end
function Lights:onReadStream(streamId, _)
    self:setLightsTypesMask(streamReadUIntN(streamId, self.spec_lights.totalNumLightTypes), true, true)
    self:setBeaconLightsVisibility(streamReadBool(streamId), true, true)
end
function Lights:onWriteStream(streamId, _)
    local spec = self.spec_lights
    streamWriteUIntN(streamId, spec.lightsTypesMask, spec.totalNumLightTypes)
    streamWriteBool(streamId, spec.beaconLightsActive)
end
function Lights:onUpdate(_, _, isActiveForInputIgnoreSelection, _)
    if self.isClient then
        local spec = self.spec_lights
        if spec.turnLightState ~= Lights.TURNLIGHT_OFF then
            local shaderTime = getShaderTimeSec()
            local _, fracTime = math.modf(shaderTime)
            local light = fracTime - 0.5
            local turnLightRepetitionCount = 4 * math.abs(light) - 0.8
            local alpha = math.clamp(turnLightRepetitionCount, 0, 1)
            if spec.turnLightState == Lights.TURNLIGHT_LEFT or spec.turnLightState == Lights.TURNLIGHT_HAZARD then
                for _, light in pairs(spec.activeTurnLightSetup.turnLightsLeft) do
                    light:setCharge(alpha)
                end
            end
            if spec.turnLightState == Lights.TURNLIGHT_RIGHT or spec.turnLightState == Lights.TURNLIGHT_HAZARD then
                for _, light in pairs(spec.activeTurnLightSetup.turnLightsRight) do
                    light:setCharge(alpha)
                end
            end
            if spec.samples.turnLight ~= nil and isActiveForInputIgnoreSelection then
                local turnLightRepetitionCount = math.floor(shaderTime - 0.8)
                if spec.turnLightRepetitionCount ~= nil and turnLightRepetitionCount ~= spec.turnLightRepetitionCount then
                    g_soundManager:playSample(spec.samples.turnLight)
                end
                spec.turnLightRepetitionCount = turnLightRepetitionCount
            end
            self:raiseActive()
        end
    end
end
function Lights:onUpdateTick(_, _, _, _)
    if self.isClient then
        local spec = self.spec_lights
        local isActiveForLights = self:getIsActiveForLights()
        if isActiveForLights ~= spec.lastIsActiveForLights then
            for _, beaconLight in ipairs(spec.alwaysActiveBeaconLights) do
                beaconLight:setIsActive(isActiveForLights)
            end
            spec.lastIsActiveForLights = isActiveForLights
        end
        if spec.interiorLightsAvailable then
            self:setInteriorLightsVisibility(self:getIsActiveForInteriorLights())
        end
        for _, beaconLight in ipairs(spec.actionEventsActiveChange) do
            g_inputBinding:setActionEventActive(beaconLight, isActiveForLights)
        end
        g_inputBinding:setActionEventActive(spec.actionEventIdLight, isActiveForLights)
        if Platform.gameplay.automaticLights and (self == self.rootVehicle and not self:getIsAIActive()) then
            self:updateAutomaticLights(not g_currentMission.environment.isSunOn and isActiveForLights, self.rootVehicle:getActionControllerDirection() == -1)
        end
    end
end
function Lights:getIsActiveForLights(onlyPowered)
    if onlyPowered == true and not self:getIsPowered() then
        return false
    elseif self.getIsEntered == nil or not (self:getIsEntered() and self:getCanToggleLight()) then
        if self.attacherVehicle == nil then
            return false
        else
            return self.attacherVehicle:getIsActiveForLights()
        end
    else
        return true
    end
end
function Lights:getIsActiveForInteriorLights()
    return false
end
function Lights:getCanToggleLight()
    if self:getIsAIActive() then
        return false
    elseif self.spec_lights.numLightTypes == 0 then
        return false
    else
        return g_localPlayer:getCurrentVehicle() == self
    end
end
function Lights:getUseHighProfile()
    local lightsProfile = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
    return Utils.getNoNil(Platform.gameplay.lightsProfile, lightsProfile) >= GS_PROFILE_HIGH
end
function Lights:setNextLightsState(increment)
    local spec = self.spec_lights
    if spec.lightStates ~= nil and #spec.lightStates > 0 then
        local currentLightState = spec.lightsTypesMask
        local lightsTypesMask = spec.maxLightStateMask
        local oldLightsTypesMask = bit32.band(currentLightState, lightsTypesMask)
        local currentLightState = spec.currentLightState + increment
        local currentLightState = (#spec.lightStates < currentLightState or spec.currentLightState == 0 and oldLightsTypesMask > 0) and 0 or (currentLightState < 0 and #spec.lightStates or currentLightState)
        local lightsTypesMask = bit32.band(spec.lightsTypesMask, (bit32.bnot(spec.maxLightStateMask)))
        if currentLightState > 0 then
            for _, lightType in pairs(spec.lightStates[currentLightState]) do
                lightsTypesMask = bit32.bor(lightsTypesMask, 2 ^ lightType)
            end
        end
        spec.currentLightState = currentLightState
        self:setLightsTypesMask(lightsTypesMask)
    end
end
function Lights:setLightsTypesMask(lightsTypesMask, force, noEventSend)
    local spec = self.spec_lights
    local activeLightSetup
    if self.isServer then
        activeLightSetup = bit32.band(lightsTypesMask, spec.maxLightStateMask)
        if spec.turnLightState == Lights.TURNLIGHT_LEFT then
            activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.turnLightLeft)
        end
        if spec.turnLightState == Lights.TURNLIGHT_RIGHT then
            activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.turnLightRight)
        end
        if spec.turnLightState == Lights.TURNLIGHT_HAZARD then
            activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.turnLightAny)
        end
        if bit32.band(activeLightSetup, 2 ^ Lights.LIGHT_TYPE_DEFAULT) ~= 0 then
            if spec.topLightsVisibility then
                activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.topLight)
            else
                activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.bottomLight)
            end
        end
        if spec.brakeLightsVisibility then
            activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.brakeLight)
        end
        if spec.reverseLightsVisibility then
            activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.reverseLight)
        end
        if spec.interiorLightsVisibility then
            activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.interiorLight)
        end
    else
        local activeLightSetup = bit32.band(lightsTypesMask, (bit32.bnot(2 ^ spec.additionalLightTypes.topLight)))
        local activeLightSetup = bit32.band(activeLightSetup, (bit32.bnot(2 ^ spec.additionalLightTypes.bottomLight)))
        if bit32.band(activeLightSetup, 2 ^ Lights.LIGHT_TYPE_DEFAULT) ~= 0 then
            if spec.topLightsVisibility then
                activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.topLight)
            else
                activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.bottomLight)
            end
        end
        activeLightSetup = bit32.band(activeLightSetup, (bit32.bnot(2 ^ spec.additionalLightTypes.interiorLight)))
        if spec.interiorLightsVisibility then
            activeLightSetup = bit32.bor(activeLightSetup, 2 ^ spec.additionalLightTypes.interiorLight)
        end
    end
    if activeLightSetup ~= spec.lightsTypesMask or force then
        if noEventSend == nil or noEventSend == false then
            if g_server == nil then
                g_client:getServerConnection():sendEvent(VehicleSetLightEvent.new(self, activeLightSetup, spec.totalNumLightTypes))
            else
                g_server:broadcastEvent(VehicleSetLightEvent.new(self, activeLightSetup, spec.totalNumLightTypes), nil, nil, self)
            end
        end
        local activeLightSetup = bit32.band(activeLightSetup, spec.maxLightStateMask)
        if activeLightSetup ~= bit32.band(spec.lightsTypesMask, spec.maxLightStateMask) and self.isClient then
            g_soundManager:playSample(spec.samples.toggleLights)
        end
        local activeLightSetup = spec.realLights.low
        if self:getUseHighProfile() then
            activeLightSetup = spec.realLights.high
        end
        for _, lights in pairs(spec.staticLights) do
            for _, staticLight in ipairs(lights) do
                staticLight:setLightTypesMask(activeLightSetup)
            end
        end
        for _, lights in pairs(spec.realLights) do
            for _, staticLight in pairs(lights) do
                for _, realLight in ipairs(staticLight) do
                    realLight:setLightTypesMask(lights == activeLightSetup and activeLightSetup and activeLightSetup or 0)
                end
            end
        end
        for _, lights in pairs(spec.staticLightCompounds) do
            lights:setLightTypesMask(activeLightSetup, self)
        end
        spec.lightsTypesMask = activeLightSetup
        if self.isClient and self.updateDashboardValueType ~= nil then
            self:updateDashboardValueType("lights.lightState")
            self:updateDashboardValueType("lights.turnLightLeft")
            self:updateDashboardValueType("lights.turnLightRight")
            self:updateDashboardValueType("lights.turnLight")
            self:updateDashboardValueType("lights.turnLightHazard")
            self:updateDashboardValueType("lights.turnLightAny")
        end
        SpecializationUtil.raiseEvent(self, "onLightsTypesMaskChanged", activeLightSetup)
    end
    return true
end
function Lights:getLightsTypesMask()
    return self.spec_lights.lightsTypesMask
end
function Lights:setBeaconLightsVisibility(visibility, force, noEventSend)
    local spec = self.spec_lights
    if visibility ~= spec.beaconLightsActive or force then
        if noEventSend == nil or noEventSend == false then
            if g_server == nil then
                g_client:getServerConnection():sendEvent(VehicleSetBeaconLightEvent.new(self, visibility))
            else
                g_server:broadcastEvent(VehicleSetBeaconLightEvent.new(self, visibility), nil, nil, self)
            end
        end
        local isActiveForInput = self:getIsActiveForInput(true)
        spec.beaconLightsActive = visibility
        for _, beaconLight in pairs(spec.beaconLights) do
            beaconLight:setIsActive(visibility)
            if isActiveForInput then
                beaconLight:setDeviceIsActive(visibility)
            end
        end
        if self.isClient and self.updateDashboardValueType ~= nil then
            self:updateDashboardValueType("lights.beaconLight")
        end
        SpecializationUtil.raiseEvent(self, "onBeaconLightsVisibilityChanged", visibility)
    end
    return true
end
function Lights:getBeaconLightsVisibility()
    return self.spec_lights.beaconLightsActive
end
function Lights:setTurnLightState(state, force, noEventSend)
    local spec = self.spec_lights
    if state ~= spec.turnLightState or force then
        if noEventSend == nil or noEventSend == false then
            if g_server == nil then
                g_client:getServerConnection():sendEvent(VehicleSetTurnLightEvent.new(self, state))
            else
                g_server:broadcastEvent(VehicleSetTurnLightEvent.new(self, state), nil, nil, self)
            end
        end
        local activeLightSetup = spec.realLights.low
        if self:getUseHighProfile() then
            activeLightSetup = spec.realLights.high
        end
        spec.activeTurnLightSetup = activeLightSetup
        spec.turnLightState = state
        spec.turnLightTriState = spec.turnLightState == Lights.TURNLIGHT_LEFT and 0 or (spec.turnLightState == Lights.TURNLIGHT_RIGHT and 1 or 0.5)
        spec.turnLightRepetitionCount = nil
        if self.isServer then
            self:setLightsTypesMask(spec.lightsTypesMask, nil)
        end
        SpecializationUtil.raiseEvent(self, "onTurnLightStateChanged", state)
    end
    return true
end
function Lights:getTurnLightState()
    return self.spec_lights.turnLightState
end
function Lights:setTopLightsVisibility(visibility)
    local spec = self.spec_lights
    if visibility ~= spec.topLightsVisibility then
        spec.topLightsVisibility = visibility
        self:setLightsTypesMask(spec.lightsTypesMask, nil, true)
        SpecializationUtil.raiseEvent(self, "onTopLightsVisibilityChanged", visibility)
    end
    return true
end
function Lights:setBrakeLightsVisibility(visibility)
    local spec = self.spec_lights
    if visibility ~= spec.brakeLightsVisibility then
        spec.brakeLightsVisibility = visibility
        self:setLightsTypesMask(spec.lightsTypesMask)
        SpecializationUtil.raiseEvent(self, "onBrakeLightsVisibilityChanged", visibility)
    end
    return true
end
function Lights:setReverseLightsVisibility(visibility)
    local spec = self.spec_lights
    if visibility ~= spec.reverseLightsVisibility then
        spec.reverseLightsVisibility = visibility
        self:setLightsTypesMask(spec.lightsTypesMask)
        SpecializationUtil.raiseEvent(self, "onReverseLightsVisibilityChanged", visibility)
    end
    return true
end
function Lights:setInteriorLightsVisibility(visibility)
    local spec = self.spec_lights
    local brightness, hasChanged = self:getInteriorLightBrightness(true)
    if brightness == 0 then
        visibility = false
    end
    if visibility ~= spec.interiorLightsVisibility or hasChanged then
        spec.interiorLightsVisibility = visibility
        self:setLightsTypesMask(spec.lightsTypesMask, true, true)
    end
    return true
end
function Lights:getInteriorLightBrightness(updateState)
    local spec = self.spec_lights
    local changed = false
    if updateState then
        local brightness = 0
        local hour = g_currentMission.environment.currentHour + g_currentMission.environment.currentMinute / 60
        if hour < 10 then
            brightness = 1 - (hour - 8) / 2
        end
        if hour > 16 then
            brightness = (hour - 16) / 2
        end
        spec.interiorLightsBrightness = math.clamp(brightness, 0, 1)
        changed = spec.interiorLightsBrightness ~= spec.interiorLightsBrightness
    end
    return spec.interiorLightsBrightness, changed
end
function Lights:deactivateLights(keepHazardLightsOn)
    local spec = self.spec_lights
    self:setLightsTypesMask(0, true, true)
    self:setBeaconLightsVisibility(false, true, true)
    if not keepHazardLightsOn or spec.turnLightState ~= Lights.TURNLIGHT_HAZARD then
        self:setTurnLightState(Lights.TURNLIGHT_OFF, true, true)
    end
    self:setBrakeLightsVisibility(false)
    self:setReverseLightsVisibility(false)
    self:setInteriorLightsVisibility(false)
    spec.currentLightState = 0
end
function Lights:deactivateBeaconLights()
    for _, beaconLight in pairs(self.spec_lights.beaconLights) do
        beaconLight:setIsActive(false)
        beaconLight:setDeviceIsActive(false)
    end
end
function Lights:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
    if not superFunc(self, xmlFile, key, group) then
        return false
    end
    group.lightTypes = xmlFile:getValue(key .. "#lightTypes", nil, true)
    group.excludedLightTypes = xmlFile:getValue(key .. "#excludedLightTypes", nil, true)
    return true
end
function Lights:getIsDashboardGroupActive(superFunc, group)
    if group.lightTypes ~= nil or group.excludedLightTypes ~= nil then
        if group.lightTypes ~= nil then
            local lightIsActive = false
            for _, lightType in pairs(group.lightTypes) do
                if bit32.band(self.spec_lights.lightsTypesMask, 2 ^ lightType) ~= 0 then
                    lightIsActive = true
                    break
                end
            end
            if not lightIsActive then
                return false
            end
        end
        if group.excludedLightTypes ~= nil then
            for _, _ in pairs(group.excludedLightTypes) do
                if bit32.band(spec.lightsTypesMask, 2 ^ _) ~= 0 then
                    return false
                end
            end
        end
    end
    return superFunc(self, group)
end
function Lights:getDeactivateLightsOnLeave()
    return true
end
function Lights:loadSharedLight(_, key)
    local spec = self.spec_lights
    local sharedLight = SharedLight.new(self, spec.staticLights)
    sharedLight:loadFromVehicleXML(key, self.baseDirectory, function(success)
        -- upvalues: (copy) spec, (copy) sharedLight
        if success then
            table.insert(spec.sharedLights, sharedLight)
            if sharedLight.staticLightCompound ~= nil then
                table.insert(spec.staticLightCompounds, sharedLight.staticLightCompound)
            end
        end
    end)
end
function Lights.loadAdditionalLightAttributesFromXML(_, xmlFile, key, light)
    light.isTopLight = xmlFile:getValue(key .. "#isTopLight", false)
    light.isBottomLight = xmlFile:getValue(key .. "#isBottomLight", false)
    return true
end
function Lights:getIsLightActive(light)
    if light.isTopLight then
        if not self.spec_lights.topLightsVisibility then
            return false
        end
    elseif light.isBottomLight and self.spec_lights.topLightsVisibility then
        return false
    end
    return true
end
function Lights:getStaticLightFromNode(node)
    for _, lights in pairs(self.spec_lights.staticLights) do
        for _, staticLight in ipairs(lights) do
            if staticLight.node == node then
                return staticLight
            end
        end
    end
end
function Lights:getRealLightFromNode(node)
    for _, profile in pairs(self.spec_lights.realLights) do
        for _, lights in pairs(profile) do
            for _, realLight in ipairs(lights) do
                if realLight.node == node then
                    return realLight
                end
            end
        end
    end
end
function Lights:updateAutomaticLights(isTurnedOn, isWorking)
    if isTurnedOn then
        local lightsTypesMask = isWorking and self.spec_lights.automaticLightsTypesMaskWork or self.spec_lights.automaticLightsTypesMask
        if spec.lightsTypesMask ~= lightsTypesMask then
            self:setLightsTypesMask(lightsTypesMask)
            return
        end
    elseif spec.lightsTypesMask ~= 0 then
        self:setLightsTypesMask(0)
    end
end
function Lights:lightsWeatherChanged()
    g_inputBinding:setActionEventTextVisibility(self.spec_lights.actionEventIdLight, not g_currentMission.environment.isSunOn)
end
function Lights:onLightsProfileChanged(lightsProfile)
    local spec = self.spec_lights
    for _, profile in pairs(spec.realLights) do
        for _, lights in pairs(profile) do
            for _, realLight in ipairs(lights) do
                realLight:onLightsProfileChanged(lightsProfile)
            end
        end
    end
    self:setLightsTypesMask(spec.lightsTypesMask, true, true)
end
function Lights:onLightsRealBeaconLightChanged()
    for _, beaconLight in pairs(self.spec_lights.beaconLights) do
        beaconLight:onLightsRealBeaconLightChanged()
    end
end
function Lights:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient and (self.getIsEntered ~= nil and self:getIsEntered()) then
        local spec = self.spec_lights
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local _, actionEventIdReverse = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHTS, self, Lights.actionEventToggleLights, false, true, false, true, nil)
            spec.actionEventIdLight = actionEventIdReverse
            local _, actionEventIdReverse = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHTS_BACK, self, Lights.actionEventToggleLightsBack, false, true, false, true, nil)
            local _, actionEventIdFront = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHT_FRONT, self, Lights.actionEventToggleLightFront, false, true, false, true, nil)
            local _, actionEventIdWorkBack = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_WORK_LIGHT_BACK, self, Lights.actionEventToggleWorkLightBack, false, true, false, true, nil)
            local _, actionEventIdWorkFront = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_WORK_LIGHT_FRONT, self, Lights.actionEventToggleWorkLightFront, false, true, false, true, nil)
            local _, actionEventIdHighBeam = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_HIGH_BEAM_LIGHT, self, Lights.actionEventToggleHighBeamLight, false, true, false, true, nil)
            self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_HAZARD, self, Lights.actionEventToggleTurnLightHazard, false, true, false, true, nil)
            self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_LEFT, self, Lights.actionEventToggleTurnLightLeft, false, true, false, true, nil)
            self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_RIGHT, self, Lights.actionEventToggleTurnLightRight, false, true, false, true, nil)
            local _, actionEventIdBeacon = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_BEACON_LIGHTS, self, Lights.actionEventToggleBeaconLights, false, true, false, true, nil)
            spec.actionEventsActiveChange = {
                actionEventIdFront,
                actionEventIdWorkBack,
                actionEventIdWorkFront,
                actionEventIdHighBeam,
                actionEventIdBeacon
            }
            for _, actionEvent in pairs(spec.actionEvents) do
                if actionEvent.actionEventId ~= nil then
                    g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
                    g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_LOW)
                end
            end
            g_inputBinding:setActionEventTextVisibility(spec.actionEventIdLight, not g_currentMission.environment.isSunOn)
            g_inputBinding:setActionEventTextVisibility(actionEventIdReverse, false)
        end
    end
end
function Lights:onRegisterExternalActionEvents(trigger, name, _, _)
    if name == "lights" and #self.spec_lights.lightStates > 0 then
        self:registerExternalActionEvent(trigger, name, Lights.externalActionEventRegister, Lights.externalActionEventUpdate)
    end
end
function Lights:onEnterVehicle(_)
    local spec = self.spec_lights
    self:setLightsTypesMask(spec.lightsTypesMask, true, true)
    self:setBeaconLightsVisibility(spec.beaconLightsActive, true, true)
    self:setTurnLightState(spec.turnLightState, true, true)
end
function Lights:onLeaveVehicle()
    if self:getDeactivateLightsOnLeave() then
        self:deactivateLights(true)
        self:deactivateBeaconLights()
    end
    for _, beaconLight in pairs(self.spec_lights.beaconLights) do
        beaconLight:setDeviceIsActive(false)
    end
end
function Lights:onDeactivate()
    if self:getDeactivateLightsOnLeave() then
        self:deactivateBeaconLights()
    end
end
function Lights:onRequiresTopLightsChanged(requiresTopLights)
    self:setTopLightsVisibility(requiresTopLights)
end
function Lights:onStartMotor()
    local spec = self.spec_lights
    self:setLightsTypesMask(spec.lightsTypesMask, true, true)
    for _, staticLight in ipairs(spec.staticLights.dayTimeLights) do
        staticLight:setState(true)
    end
end
function Lights:onStopMotor()
    local spec = self.spec_lights
    self:setLightsTypesMask(spec.lightsTypesMask, true, true)
    for _, staticLight in ipairs(spec.staticLights.dayTimeLights) do
        staticLight:setState((self:getIsInShowroom()))
    end
end
function Lights:onStartReverseDirectionChange()
    local spec = self.spec_lights
    if spec.lightsTypesMask > 0 then
        self:setLightsTypesMask(spec.lightsTypesMask, true, true)
    end
end
function Lights:onPostAttach(attacherVehicle, _, _)
    if attacherVehicle.getLightsTypesMask ~= nil then
        self:setLightsTypesMask(attacherVehicle:getLightsTypesMask(), true, true)
        self:setBeaconLightsVisibility(attacherVehicle:getBeaconLightsVisibility(), true, true)
        self:setTurnLightState(attacherVehicle:getTurnLightState(), true, true)
    end
end
function Lights:onPostDetach()
    self:deactivateLights()
end
function Lights:onAutomatedTrainTravelActive()
    self:updateAutomaticLights(not g_currentMission.environment.isSunOn, false)
end
function Lights:onAIDriveableActive()
    self:updateAutomaticLights(not g_currentMission.environment.isSunOn, false)
end
function Lights:onAIDriveableEnd()
    if self.getIsControlled ~= nil and not self:getIsControlled() then
        self:setLightsTypesMask(0)
    end
    self:setBeaconLightsVisibility(false, true, true)
end
function Lights:onAIFieldWorkerStart()
    self:setBeaconLightsVisibility(false, true, true)
end
function Lights:onAIFieldWorkerActive()
    self:updateAutomaticLights(not g_currentMission.environment.isSunOn, true)
end
function Lights:onAIJobVehicleBlock()
    self:setBeaconLightsVisibility(true, true, true)
end
function Lights:onAIJobVehicleContinue()
    self:setBeaconLightsVisibility(false, true, true)
end
function Lights:onAIFieldWorkerEnd()
    if self.getIsControlled ~= nil and not self:getIsControlled() then
        self:setLightsTypesMask(0)
    end
    self:setBeaconLightsVisibility(false, true, true)
end
function Lights:onVehiclePhysicsUpdate(acceleratorPedal, brakePedal, automaticBrake, currentSpeed)
    self:setBrakeLightsVisibility(not automaticBrake and math.abs(brakePedal) > 0)
    local reverserDirection = 1
    if self.spec_drivable ~= nil then
        reverserDirection = self.spec_drivable.reverserDirection
    end
    if currentSpeed >= -self.spec_lights.reverseLightActivationSpeed then
        if acceleratorPedal >= 0 then
            ::l9::
            self:setReverseLightsVisibility(false)
            return
        end
    end
    v174_ = reverserDirection == 1
    goto l9
end
function Lights:loadRealLightSetup(xmlFile, key, lightTable, _)
    lightTable.defaultLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".light", self, self.components, self.i3dMappings, true)
    lightTable.topLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".topLight", self, self.components, self.i3dMappings, false)
    lightTable.bottomLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".bottomLight", self, self.components, self.i3dMappings, false)
    lightTable.brakeLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".brakeLight", self, self.components, self.i3dMappings, false)
    lightTable.reverseLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".reverseLight", self, self.components, self.i3dMappings, false)
    lightTable.turnLightsLeft = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".turnLightLeft", self, self.components, self.i3dMappings, false)
    lightTable.turnLightsRight = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".turnLightRight", self, self.components, self.i3dMappings, false)
    lightTable.interiorLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".interiorLight", self, self.components, self.i3dMappings, false)
    for i, light in ipairs(lightTable.interiorLights) do
        light:setChargeFunction(self.getInteriorLightBrightness, self)
        self.spec_lights.interiorLightsAvailable = true
    end
end
function Lights.applyAdditionalActiveLightType(_, lights, lightType, isBlinking)
    for _, light in ipairs(lights) do
        table.insert(light.lightTypes, lightType)
        if isBlinking then
            light:setIsBlinking(true)
        end
    end
end
function Lights:actionEventToggleLightFront(_, _, _, _)
    local spec = self.spec_lights
    if self:getCanToggleLight() and spec.numLightTypes >= 1 then
        self:setLightsTypesMask((bit32.bxor(spec.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT)))
    end
end
function Lights:actionEventToggleLights(_, _, _, _)
    if self:getCanToggleLight() then
        self:setNextLightsState(1)
    end
end
function Lights:actionEventToggleLightsBack(_, _, _, _)
    if self:getCanToggleLight() then
        self:setNextLightsState(-1)
    end
end
function Lights:actionEventToggleWorkLightBack(_, _, _, _)
    if self:getCanToggleLight() then
        self:setLightsTypesMask((bit32.bxor(self.spec_lights.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_BACK)))
    end
end
function Lights:actionEventToggleWorkLightFront(_, _, _, _)
    if self:getCanToggleLight() then
        self:setLightsTypesMask((bit32.bxor(self.spec_lights.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_FRONT)))
    end
end
function Lights:actionEventToggleHighBeamLight(_, _, _, _)
    if self:getCanToggleLight() then
        self:setLightsTypesMask((bit32.bxor(self.spec_lights.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_HIGHBEAM)))
    end
end
function Lights:actionEventToggleTurnLightHazard(_, _, _, _)
    if self:getCanToggleLight() then
        local state = Lights.TURNLIGHT_OFF
        if self.spec_lights.turnLightState ~= Lights.TURNLIGHT_HAZARD then
            state = Lights.TURNLIGHT_HAZARD
        end
        self:setTurnLightState(state)
    end
end
function Lights:actionEventToggleTurnLightLeft(_, _, _, _)
    if self:getCanToggleLight() then
        local state = Lights.TURNLIGHT_OFF
        if self.spec_lights.turnLightState ~= Lights.TURNLIGHT_LEFT then
            state = Lights.TURNLIGHT_LEFT
        end
        self:setTurnLightState(state)
    end
end
function Lights:actionEventToggleTurnLightRight(_, _, _, _)
    if self:getCanToggleLight() then
        local state = Lights.TURNLIGHT_OFF
        if self.spec_lights.turnLightState ~= Lights.TURNLIGHT_RIGHT then
            state = Lights.TURNLIGHT_RIGHT
        end
        self:setTurnLightState(state)
    end
end
function Lights:actionEventToggleBeaconLights(_, _, _, _)
    if self:getCanToggleLight() then
        self:setBeaconLightsVisibility(not self.spec_lights.beaconLightsActive)
    end
end
function Lights.externalActionEventRegister(data, vehicle)
    _, data.actionEventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_LIGHTS_EXTERNAL, data, function(_, actionName, inputValue, callbackState, isAnalog)
        -- upvalues: (copy) vehicle
        vehicle:setNextLightsState(1)
    end, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
    g_inputBinding:setActionEventText(data.actionEventId, g_i18n:getText("input_TOGGLE_LIGHTS"))
end
function Lights.externalActionEventUpdate(data, vehicle) end
function Lights:dashboardLightAttributes(xmlFile, key, dashboard, _)
    dashboard.lightTypes = xmlFile:getValue(key .. "#lightTypes", nil, true)
    dashboard.excludedLightTypes = xmlFile:getValue(key .. "#excludedLightTypes", nil, true)
    dashboard.lightStates = {}
    local i = 0
    for i = i, self.spec_lights.maxLightState do
        dashboard.lightStates[i] = false
    end
    return true
end
function Lights:dashboardLightState(dashboard, newValue, minValue, maxValue, isActive)
    if dashboard.displayTypeIndex == Dashboard.TYPES.MULTI_STATE then
        local anyLightActive = false
        local i = 0
        for i = i, self.spec_lights.maxLightState do
            dashboard.lightStates[i] = bit32.band(self.spec_lights.lightsTypesMask, 2 ^ i) ~= 0
        end
        if anyLightActive then
            Dashboard.defaultDashboardStateFunc(self, dashboard, dashboard.lightStates, minValue, maxValue, isActive)
        else
            Dashboard.defaultDashboardStateFunc(self, dashboard, -1, minValue, maxValue, isActive)
        end
    else
        Dashboard.defaultDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
        return
    end
end
function Lights.consoleCommandTopLights()
    local vehicle = g_localPlayer:getCurrentVehicle()
    if vehicle ~= nil and vehicle.setTopLightsVisibility ~= nil then
        vehicle:setTopLightsVisibility(not vehicle.spec_lights.topLightsVisibility)
    end
end
addConsoleCommand("gsVehicleDebugTopLights", "Toggles between top and bottom lights", "Lights.consoleCommandTopLights", nil)
function Lights.consoleCommandProfile()
    if g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE) >= GS_PROFILE_HIGH then
        g_gameSettings:setValue(GameSettings.SETTING.LIGHTS_PROFILE, GS_PROFILE_LOW)
        Logging.info("Activated LOW light setup.")
    else
        g_gameSettings:setValue(GameSettings.SETTING.LIGHTS_PROFILE, GS_PROFILE_VERY_HIGH)
        Logging.info("Activated HIGH light setup.")
    end
end
addConsoleCommand("gsLightProfileToggle", "Toggles between high and low light profile on vehicles & placeables", "Lights.consoleCommandProfile", nil)