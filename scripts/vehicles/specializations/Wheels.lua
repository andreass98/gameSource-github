Wheels = {}
Wheels.VRAM_PER_WHEEL = 524288
Wheels.CONFIG_XML_PATH = "vehicle.wheels.wheelConfigurations.wheelConfiguration"
Wheels.WHEELS_XML_PATH = "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).wheels"
Wheels.WHEEL_XML_PATH = "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).wheels.wheel(?)"
Wheels.xmlSchema = nil
Wheels.xmlSchemaHub = nil
Wheels.xmlSchemaConnector = nil
source("dataS/scripts/vehicles/wheels/WheelContactType.lua")
source("dataS/scripts/vehicles/wheels/Wheel.lua")
source("dataS/scripts/vehicles/wheels/WheelAxle.lua")
function Wheels.prerequisitesPresent(specializations)
    return true
end
function Wheels.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onBrake")
    SpecializationUtil.registerEvent(vehicleType, "onFinishedWheelLoading")
    SpecializationUtil.registerEvent(vehicleType, "onWheelConfigurationChanged")
end
function Wheels.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getSteeringRotTimeByCurvature", Wheels.getSteeringRotTimeByCurvature)
    SpecializationUtil.registerFunction(vehicleType, "getTurningRadiusByRotTime", Wheels.getTurningRadiusByRotTime)
    SpecializationUtil.registerFunction(vehicleType, "loadHubsFromXML", Wheels.loadHubsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadHubFromXML", Wheels.loadHubFromXML)
    SpecializationUtil.registerFunction(vehicleType, "onWheelHubI3DLoaded", Wheels.onWheelHubI3DLoaded)
    SpecializationUtil.registerFunction(vehicleType, "loadAckermannSteeringFromXML", Wheels.loadAckermannSteeringFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadWheelsFromXML", Wheels.loadWheelsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadWheelFromXML", Wheels.loadWheelFromXML)
    SpecializationUtil.registerFunction(vehicleType, "onLoadWheelChockFromXML", Wheels.onLoadWheelChockFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsWheelChockAllowed", Wheels.getIsWheelChockAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getIsVersatileYRotActive", Wheels.getIsVersatileYRotActive)
    SpecializationUtil.registerFunction(vehicleType, "getWheelFromWheelIndex", Wheels.getWheelFromWheelIndex)
    SpecializationUtil.registerFunction(vehicleType, "getWheelByWheelNode", Wheels.getWheelByWheelNode)
    SpecializationUtil.registerFunction(vehicleType, "getWheels", Wheels.getWheels)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentSurfaceSound", Wheels.getCurrentSurfaceSound)
    SpecializationUtil.registerFunction(vehicleType, "getAreSurfaceSoundsActive", Wheels.getAreSurfaceSoundsActive)
    SpecializationUtil.registerFunction(vehicleType, "brake", Wheels.brake)
    SpecializationUtil.registerFunction(vehicleType, "getBrakeForce", Wheels.getBrakeForce)
    SpecializationUtil.registerFunction(vehicleType, "setCustomBrakeForce", Wheels.setCustomBrakeForce)
    SpecializationUtil.registerFunction(vehicleType, "updateWheelDirtAmount", Wheels.updateWheelDirtAmount)
    SpecializationUtil.registerFunction(vehicleType, "updateWheelMudAmount", Wheels.updateWheelMudAmount)
    SpecializationUtil.registerFunction(vehicleType, "forceUpdateWheelPhysics", Wheels.forceUpdateWheelPhysics)
    SpecializationUtil.registerFunction(vehicleType, "onWheelSnowHeightChanged", Wheels.onWheelSnowHeightChanged)
    SpecializationUtil.registerFunction(vehicleType, "getSteeringNodeByNode", Wheels.getSteeringNodeByNode)
    SpecializationUtil.registerFunction(vehicleType, "updateSteeringNodes", Wheels.updateSteeringNodes)
end
function Wheels.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Wheels.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Wheels.removeFromPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getComponentMass", Wheels.getComponentMass)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleWorldXRot", Wheels.getVehicleWorldXRot)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleWorldDirection", Wheels.getVehicleWorldDirection)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", Wheels.validateWashableNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIDirectionNode", Wheels.getAIDirectionNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIRootNode", Wheels.getAIRootNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSupportsMountKinematic", Wheels.getSupportsMountKinematic)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadBendingNodeFromXML", Wheels.loadBendingNodeFromXML)
end
function Wheels.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerEnd", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEnd", Wheels)
end
function Wheels.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("wheel", g_i18n:getText("configuration_wheelSetup"), "wheels", VehicleConfigurationItemWheel, g_i18n:getText("configuration_wheelBrand"), Wheels.getBrands, Wheels.getWheelsByBrand, 2)
    g_vehicleConfigurationManager:addConfigurationType("rimColor", g_i18n:getText("configuration_rimColor"), nil, VehicleConfigurationItemColor)
    g_storeManager:addSpecType("wheels", "shopListAttributeIconWheels", Wheels.loadSpecValueWheels, Wheels.getSpecValueWheels, StoreSpecies.VEHICLE)
    g_storeManager:addVRamUsageFunction(Wheels.getVRamUsageFromXML)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Wheels")
    schema:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations#tireCategories", "List of tire categories to include in the automatic wheel config generation (separated by whitespace)")
    schema:register(XMLValueType.STRING_LIST, "vehicle.wheels.wheelConfigurations#customBrandOrder", "Custom brand order for dynamic configurations (names of the brands separated by whitespace)")
    schema:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations.tireCombination(?)#brand", "Brand name of the combination")
    schema:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations.tireCombination(?)#names", "List of tire names that are allowed to be mixed. Otherwise all mixes are allowed. Does not effect configuration with all tires from the same name. (separated by whitespace)")
    schema:register(XMLValueType.INT, Wheels.CONFIG_XML_PATH .. "(?)#numDynamicConfigurations", "Max. number of dynamic configurations per brand", "unlimited")
    schema:register(XMLValueType.STRING, Wheels.CONFIG_XML_PATH .. "(?)#tireCategories", "List of tire categories to include in the automatic wheel config generation (separated by whitespace)")
    schema:register(XMLValueType.STRING, Wheels.CONFIG_XML_PATH .. "(?).tireCombination(?)#brand", "Brand name of the combination")
    schema:register(XMLValueType.STRING, Wheels.CONFIG_XML_PATH .. "(?).tireCombination(?)#names", "List of tire names that are allowed to be mixed. Otherwise all mixes are allowed. Does not effect configuration with all tires from the same name. (separated by whitespace)")
    WheelAxle.registerXMLPaths(schema, "vehicle.wheels.axles.axle(?)")
    WheelAxle.registerXMLPaths(schema, Wheels.CONFIG_XML_PATH .. "(?).axle(?)")
    local configKey = Wheels.WHEELS_XML_PATH
    schema:register(XMLValueType.FLOAT, configKey .. "#autoRotateBackSpeed", "Auto rotate back speed", 1)
    schema:register(XMLValueType.BOOL, configKey .. "#speedDependentRotateBack", "Speed dependent auto rotate back speed", true)
    schema:register(XMLValueType.INT, configKey .. "#differentialIndex", "Differential index")
    schema:register(XMLValueType.INT, configKey .. "#ackermannSteeringIndex", "Ackermann steering index")
    schema:register(XMLValueType.FLOAT, configKey .. "#ackermannSteeringAngle", "Ackermann steering angle to set while this config is active")
    schema:register(XMLValueType.BOOL, configKey .. "#isCareWheelConfiguration", "All wheels will be care wheels")
    schema:register(XMLValueType.STRING, configKey .. "#baseConfig", "Base for this configuration")
    schema:register(XMLValueType.BOOL, configKey .. "#hasSurfaceSounds", "Has surface sounds", true)
    schema:register(XMLValueType.STRING, configKey .. "#surfaceSoundTireType", "Tire type that is used for surface sounds", "Tire type of first wheel")
    schema:register(XMLValueType.NODE_INDEX, configKey .. "#surfaceSoundLinkNode", "Surface sound link node", "Root component")
    Wheel.registerXMLPaths(schema, configKey .. ".wheel(?)")
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.rimMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.rimMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.rimMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.innerRimMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.innerRimMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.innerRimMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.outerRimMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.outerRimMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.outerRimMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.additionalMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.additionalMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.additionalMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubMaterial#useRimColor", "Use rim color", false)
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubBoltMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubBoltMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubBoltMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubBoltMaterial#useRimColor", "Use rim color", false)
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubs.material")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.material#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubs.material#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.material#useRimColor", "Use rim color", false)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.wheels.hubs.hub(?)#linkNode", "Link node")
    schema:register(XMLValueType.STRING, "vehicle.wheels.hubs.hub(?)#filename", "Filename")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?)#isLeft", "Is left side", false)
    schema:register(XMLValueType.FLOAT, "vehicle.wheels.hubs.hub(?)#offset", "X axis offset")
    schema:register(XMLValueType.VECTOR_SCALE, "vehicle.wheels.hubs.hub(?)#scale", "Hub scale")
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubs.hub(?).material")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).material#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).material#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).material#useRimColor", "Use rim color", false)
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubs.hub(?).boltMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).boltMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltMaterial#useRimColor", "Use rim color", false)
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubs.hub(?).additionalMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).additionalMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).additionalMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).additionalMaterial#useRimColor", "Use rim color", false)
    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial#useRimColor", "Use rim color", false)
    schema:addDelayedRegistrationFunc("AnimatedVehicle:part", function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. "#wheelIndex", "Wheel index [1..n]")
        cSchema:register(XMLValueType.ANGLE, cKey .. "#startSteeringAngle", "Start steering angle")
        cSchema:register(XMLValueType.ANGLE, cKey .. "#endSteeringAngle", "End steering angle")
        cSchema:register(XMLValueType.FLOAT, cKey .. "#startBrakeFactor", "Start brake force factor")
        cSchema:register(XMLValueType.FLOAT, cKey .. "#endBrakeFactor", "End brake force factor")
        cSchema:register(XMLValueType.FLOAT, cKey .. "#startTorqueDirection", "Start torque direction")
        cSchema:register(XMLValueType.FLOAT, cKey .. "#endTorqueDirection", "End torque direction")
    end)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)#linkNode", "Link node")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)#isLeft", "Is Left", false)
    schema:register(XMLValueType.STRING, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)#filename", "Filename")
    schema:register(XMLValueType.STRING, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)#configId", "Wheel config id", "default")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)#isShallowWaterObstacle", "The dynamically loaded wheel will interact with the shallow water simulation", false)
    WheelVisual.registerXMLPaths(schema, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)")
    Wheels.registerAckermannSteeringXMLPaths(schema, "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering(?)")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.wheels.steeringNodes.steeringNode(?)#node", "Additional node that is used for steering (Same behaviour as wheels using the ackermann steering setting)")
    schema:register(XMLValueType.FLOAT, "vehicle.wheels.steeringNodes.steeringNode(?)#rotScale", "Scale factor for rotation", 1)
    schema:register(XMLValueType.ANGLE, "vehicle.wheels.steeringNodes.steeringNode(?)#rotChangeSpeed", "Max. rotation speed when limits change", 45)
    schema:register(XMLValueType.VECTOR_N, FoliageBending.BENDING_NODE_XML_KEY .. "#wheelIndices", "Wheel Indices to calculate the bending node size automatically")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.wheels.dashboards", { "brake", "steeringAngle" })
    Dashboard.addDelayedRegistrationFunc(schema, function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. "#steeringNodeIndex", "Index of steering node")
        cSchema:register(XMLValueType.INT, cKey .. "#wheelIndex", "Index of wheel")
        cSchema:register(XMLValueType.VECTOR_N, cKey .. "#wheelIndices", "List of wheel indices (separated by whitespace)")
    end)
    schema:setXMLSpecializationType()
    Wheels.xmlSchema = XMLSchema.new("wheel")
    Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.metadata#brand", "Wheel tire brand", "LIZARD")
    Wheels.xmlSchema:registerAutoCompletionDataSource("wheel.metadata#brand", "$dataS/brands.xml", "brands.brand#name")
    Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.metadata#name", "Wheel tire name", "Tire")
    Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.metadata#category", "Wheel tire category for automatic wheel configurations")
    Wheels.xmlSchema:register(XMLValueType.BOOL, "wheel.metadata#allowMixture", "Allow mixing with other tires from the same brand", false)
    Wheels.xmlSchema:register(XMLValueType.FLOAT, "wheel.metadata#priority", "Tire priority for selection in the shop (wheels with high prio will be shown first)", 1)
    Wheel.registerXMLPaths(Wheels.xmlSchema, "wheel.default")
    Wheel.registerXMLPaths(Wheels.xmlSchema, "wheel.configurations.configuration(?)")
    Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.configurations.configuration(?)#id", "Configuration Id")
    Wheels.xmlSchemaHub = XMLSchema.new("wheelHub")
    local hubSchema = Wheels.xmlSchemaHub
    hubSchema:register(XMLValueType.STRING, "hub.filename", "I3D filename")
    hubSchema:register(XMLValueType.STRING, "hub.nodes#left", "Index of left node in hub i3d file")
    hubSchema:register(XMLValueType.STRING, "hub.nodes#right", "Index of right node in hub i3d file")
    Wheels.xmlSchemaConnector = XMLSchema.new("wheelConnector")
    local connectorSchema = Wheels.xmlSchemaConnector
    connectorSchema:register(XMLValueType.STRING, "connector.file#name", "I3D filename")
    connectorSchema:register(XMLValueType.STRING, "connector.file#leftNode", "Index of left node in connector i3d file")
    connectorSchema:register(XMLValueType.STRING, "connector.file#rightNode", "Index of right node in connector i3d file")
    Vehicle.xmlSchemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).wheels#lastConfigId", "Last selected wheel configuration id")
end
function Wheels.registerAckermannSteeringXMLPaths(schema, key)
    schema:register(XMLValueType.FLOAT, key .. "#rotSpeed", "Rotation speed")
    schema:register(XMLValueType.FLOAT, key .. "#rotMax", "Max. rotation")
    schema:register(XMLValueType.INT, key .. "#rotCenterWheel1", "Rotation center wheel 1")
    schema:register(XMLValueType.INT, key .. "#rotCenterWheel2", "Rotation center wheel 2")
    schema:register(XMLValueType.VECTOR_N, key .. "#rotCenterWheels", "List of wheel indices which represent the steering center")
    schema:register(XMLValueType.NODE_INDEX, key .. "#rotCenterNode", "Rotation center node (Used if rotCenterWheelX not given)")
    schema:register(XMLValueType.VECTOR_2, key .. "#rotCenter", "Center position (from root component) (Used if rotCenterWheelX not given)")
    schema:register(XMLValueType.FLOAT, key .. "#minTurningRadius", "Overwrites the automatically calculated turning radius for this config")
end
function Wheels:onPreLoad(_)
    local spec = self.spec_wheels
    spec.wheelConfigurationId = self.configurations.wheel or 1
    spec.configKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", spec.wheelConfigurationId - 1)
    spec.configItem = ConfigurationUtil.getConfigItemByConfigId(self.configFileName, "wheel", spec.wheelConfigurationId)
    if spec.configItem ~= nil then
        spec.configItem:applyGeneratedConfiguration(self.xmlFile)
        spec.configKey = spec.configItem.configKey
        spec.lastWheelConfigSaveId = spec.configItem.saveId
    end
end
function Wheels:onLoad(_)
    local spec = self.spec_wheels
    spec.sharedLoadRequestIds = {}
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.driveGroundParticleSystems", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#hasParticles")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheelConfigurations.wheelConfiguration", "vehicle.wheels.wheelConfigurations.wheelConfiguration")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rimColor", "vehicle.wheels.rimColor")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.hubColor", "vehicle.wheels.hubs.color0")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicallyLoadedWheels", "vehicle.wheels.dynamicallyLoadedWheels")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ackermannSteeringConfigurations", "vehicle.wheels.ackermannSteeringConfigurations")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheel", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheelConfigurations.wheelConfiguration.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#configIndex", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#configId")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ackermannSteering", "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheel.rimColor", "vehicle.wheels.rimMaterial")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheel.hubs.rimColor.color0", "vehicle.wheels.hubMaterial")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheel.hubs.rimColor.color1", "vehicle.wheels.hubBoltMaterial")
    spec.configurationIndexToParentConfigIndex = Wheels.createConfigToParentConfigMapping(self.xmlFile)
    if spec.configItem ~= nil then
        spec.configItem:applyObjectChanges(self, spec.configurationIndexToParentConfigIndex)
    end
    local function loadMaterial(name, key, hubMaterial)
        -- upvalues: (copy) self, (copy) spec
        local material = VehicleMaterial.new(self.baseDirectory)
        if material:loadFromXML(self.xmlFile, key, self.customEnvironment) then
            spec[name] = material
        else
            material = nil
        end
        if self.xmlFile:getValue(key .. "#useBaseColor") then
            spec[name] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(self, "baseColor") or spec[name]
            return
        else
            local useDesignColorIndex = self.xmlFile:getValue(key .. "#useDesignColorIndex")
            if useDesignColorIndex == nil then
                if material == nil and not hubMaterial or self.xmlFile:getBool(key .. "#useRimColor", false) then
                    spec[name] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(self, "rimColor") or (spec.rimMaterial or spec[name])
                    if spec[name] == nil then
                        spec[name] = VehicleMaterial.new(self.baseDirectory)
                        spec[name]:setTemplateName("RIM_DEFAULT")
                    end
                end
            else
                local configName = "designColor"
                if useDesignColorIndex >= 2 then
                    configName = string.format("designColor%d", useDesignColorIndex)
                end
                spec[name] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(self, configName) or spec[name]
            end
        end
    end
    loadMaterial("rimMaterial", "vehicle.wheels.rimMaterial", false)
    loadMaterial("innerRimMaterial", "vehicle.wheels.innerRimMaterial", false)
    loadMaterial("outerRimMaterial", "vehicle.wheels.outerRimMaterial", false)
    loadMaterial("additionalMaterial", "vehicle.wheels.additionalMaterial", false)
    loadMaterial("hubMaterial", "vehicle.wheels.hubMaterial", true)
    loadMaterial("hubBoltMaterial", "vehicle.wheels.hubBoltMaterial", true)
    self:loadHubsFromXML()
    self.maxRotTime = 0
    self.minRotTime = 0
    self.rotatedTimeInterpolator = InterpolatorValue.new(0)
    self.autoRotateBackSpeed = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#autoRotateBackSpeed", 1)
    self.speedDependentRotateBack = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#speedDependentRotateBack", true)
    self.differentialIndex = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#differentialIndex")
    spec.ackermannSteeringIndex = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#ackermannSteeringIndex")
    spec.ackermannSteeringAngle = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#ackermannSteeringAngle")
    spec.isCareWheelConfiguration = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#isCareWheelConfiguration")
    local hasSurfaceSounds = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#hasSurfaceSounds", true)
    spec.wheelSmoothAccumulation = 0
    spec.currentUpdateIndex = 1
    spec.wheels = {}
    spec.wheelsByNode = {}
    self:loadWheelsFromXML(self.xmlFile, spec.configKey, spec.wheelConfigurationId)
    if hasSurfaceSounds then
        local surfaceSoundLinkNode = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#surfaceSoundLinkNode", self.components[1].node, self.components, self.i3dMappings)
        local tireTypeName = ""
        if #spec.wheels > 0 and spec.wheels[1].physics.tireType ~= nil then
            tireTypeName = WheelsUtil.getTireTypeName(spec.wheels[1].physics.tireType)
        end
        local addSurfaceSound = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#surfaceSoundTireType", tireTypeName)
        spec.surfaceSounds = {}
        spec.surfaceIdToSound = {}
        spec.surfaceNameToSound = {}
        spec.currentSurfaceSound = nil
        local surfaceSounds = g_currentMission.surfaceSounds
        local j = 1
        for j = j, #surfaceSounds do
            local surfaceSound = surfaceSounds[j]
            if string.lower(surfaceSound.type) == "wheel_" .. string.lower(addSurfaceSound) then
                local sample = g_soundManager:cloneSample(surfaceSound.sample, surfaceSoundLinkNode, self)
                sample.sampleName = surfaceSound.name
                table.insert(spec.surfaceSounds, sample)
                spec.surfaceIdToSound[surfaceSound.materialId] = sample
                spec.surfaceNameToSound[surfaceSound.name] = sample
            end
        end
        local j = 1
        for j = j, #surfaceSounds do
            local surfaceSound = surfaceSounds[j]
            if spec.surfaceNameToSound[surfaceSound.name] == nil and surfaceSound.type == "wheel" then
                local sample = g_soundManager:cloneSample(surfaceSound.sample, surfaceSoundLinkNode, self)
                sample.sampleName = surfaceSound.name
                table.insert(spec.surfaceSounds, sample)
                spec.surfaceIdToSound[surfaceSound.materialId] = sample
                spec.surfaceNameToSound[surfaceSound.name] = sample
            end
        end
    end
    spec.dynamicallyLoadedWheels = {}
    self.xmlFile:iterate("vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel", function(index, key)
        -- upvalues: (copy) self, (copy) spec
        local linkNode = self.xmlFile:getValue(key .. "#linkNode", self.components[1].node, self.components, self.i3dMappings)
        local isLeft = self.xmlFile:getValue(key .. "#isLeft", false)
        local isShallowWaterObstacle = self.xmlFile:getValue(key .. "#isShallowWaterObstacle", false)
        local xmlObject = WheelXMLObject.new(self.xmlFile, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel", index, "", {})
        local visualWheel = WheelVisual.new(self, nil, linkNode, isLeft, 0, self.baseDirectory)
        if visualWheel:loadFromXML(xmlObject) then
            if isShallowWaterObstacle then
                visualWheel:addShallowWaterObstacle()
            end
            visualWheel.name = xmlObject.externalWheelName
            table.insert(spec.dynamicallyLoadedWheels, visualWheel)
        else
            visualWheel:delete()
        end
        xmlObject:delete()
    end)
    spec.steeringNodes = {}
    self.xmlFile:iterate("vehicle.wheels.steeringNodes.steeringNode", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        if node ~= nil then
            local steeringNode = {
                ["node"] = node,
                ["rotScale"] = self.xmlFile:getValue(key .. "#rotScale", 1),
                ["rotChangeSpeed"] = self.xmlFile:getValue(key .. "#rotChangeSpeed", 45)
            }
            steeringNode.rotScaleOrig = steeringNode.rotScale
            steeringNode.rotScaleTarget = steeringNode.rotScale
            steeringNode.rotScaleTargetSpeed = 1
            steeringNode.steeringAngle = 0
            steeringNode.offset = 0
            steeringNode.offsetTarget = 0
            steeringNode.offsetTargetSpeed = 1
            for _, componentJoint in pairs(self.componentJoints) do
                if componentJoint.jointNode == node then
                    steeringNode.componentJoint = componentJoint
                    break
                end
            end
            table.insert(spec.steeringNodes, steeringNode)
        end
    end)
    local surfaceSoundLinkNode = #spec.steeringNodes > 0
    spec.hasSteeringNodes = surfaceSoundLinkNode
    spec.axles = {}
    self.xmlFile:iterate("vehicle.wheels.axles.axle", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local axle = WheelAxle.new(self)
        if axle:loadFromXML(self.xmlFile, key) then
            table.insert(spec.axles, axle)
        end
    end)
    self.xmlFile:iterate(spec.configKey .. ".axle", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local axle = WheelAxle.new(self)
        if axle:loadFromXML(self.xmlFile, key) then
            table.insert(spec.axles, axle)
        end
    end)
    local surfaceSoundLinkNode = #spec.axles > 0
    spec.hasAxles = surfaceSoundLinkNode
    spec.networkTimeInterpolator = InterpolationTime.new(1.2)
    self:loadAckermannSteeringFromXML(self.xmlFile, spec.ackermannSteeringIndex, spec.ackermannSteeringAngle)
    SpecializationUtil.raiseEvent(self, "onFinishedWheelLoading", self.xmlFile, spec.configKey .. ".wheels")
    spec.brakePedal = 0
    spec.dirtyFlag = self:getNextDirtyFlag()
    g_messageCenter:subscribe(MessageType.SNOW_HEIGHT_CHANGED, self.onWheelSnowHeightChanged, self)
end
function Wheels:onLoadFinished(savegame)
    local spec = self.spec_wheels
    if self.isServer then
        for _, wheel in pairs(spec.wheels) do
            self.defaultMass = self.defaultMass + wheel:getMass()
        end
        if savegame ~= nil and not savegame.resetVehicles then
            local lastConfigId = savegame.xmlFile:getValue(savegame.key .. ".wheels#lastConfigId")
            if lastConfigId ~= nil and (spec.configItem ~= nil and spec.configItem.saveId ~= lastConfigId) then
                for wheel, wheel in pairs(spec.wheels) do
                    local washableNode = self:getWashableNodeByCustomIndex(wheel)
                    if washableNode ~= nil then
                        self:setNodeDirtAmount(washableNode, 0, true)
                    end
                    if wheel.wheelMudMeshes ~= nil then
                        local mudWashableNode = self:getWashableNodeByCustomIndex(wheel.wheelMudMeshes)
                        if mudWashableNode ~= nil then
                            self:setNodeDirtAmount(mudWashableNode, 0, true)
                        end
                    end
                end
                SpecializationUtil.raiseEvent(self, "onWheelConfigurationChanged")
            end
        end
    end
    if spec.rimMaterial ~= nil then
        spec.rimMaterial:applyToVehicle(self, "rim_inner_mat")
        spec.rimMaterial:applyToVehicle(self, "rim_outer_mat")
    end
    if spec.innerRimMaterial ~= nil then
        spec.innerRimMaterial:applyToVehicle(self, "rim_inner_mat")
    end
    if spec.outerRimMaterial ~= nil then
        spec.outerRimMaterial:applyToVehicle(self, "rim_outer_mat")
    end
    if spec.additionalMaterial ~= nil then
        spec.additionalMaterial:applyToVehicle(self, "rim_additional_mat")
    end
    if spec.hubMaterial ~= nil then
        spec.hubMaterial:applyToVehicle(self, "hub_main_mat")
    end
    if spec.hubBoltMaterial ~= nil then
        spec.hubBoltMaterial:applyToVehicle(self, "hub_bolt_mat")
    end
    for _, wheel in ipairs(spec.hubs) do
        if wheel.material ~= nil then
            wheel.material:apply(wheel.node, "hub_main_mat")
        end
        if wheel.boltMaterial ~= nil then
            wheel.boltMaterial:apply(wheel.node, "hub_bolt_mat")
        end
        if wheel.additionalMaterial ~= nil then
            wheel.additionalMaterial:apply(wheel.node, "hub_main_additional_mat")
        end
        if wheel.boltAdditionalMaterial ~= nil then
            wheel.boltAdditionalMaterial:apply(wheel.node, "hub_bolt_additional_mat")
        end
    end
    for _, wheel in pairs(spec.wheels) do
        wheel:postLoad()
    end
    for _, wheel in pairs(spec.dynamicallyLoadedWheels) do
        wheel:postLoad()
    end
    for _, wheel in ipairs(spec.wheels) do
        wheel:update(99999, spec.currentUpdateIndex, 0, true)
    end
end
function Wheels:onRegisterDashboardValueTypes()
    local spec = self.spec_wheels
    local brake = DashboardValueType.new("wheels", "brake")
    brake:setValue(spec, "brakePedal")
    brake:setRange(0, 1)
    self:registerDashboardValueType(brake)
    local steeringAngle = DashboardValueType.new("wheels", "steeringAngle")
    steeringAngle:setRange(-180, 180)
    steeringAngle:setValue(spec, function(_, dashboard)
        -- upvalues: (copy) spec
        if dashboard.steeringNodeIndex ~= nil then
            local steeringNode = spec.steeringNodes[dashboard.steeringNodeIndex]
            if steeringNode ~= nil then
                return math.deg(steeringNode.steeringAngle)
            end
        end
        if dashboard.wheelIndex ~= nil then
            local steeringNode = spec.wheels[dashboard.wheelIndex]
            if steeringNode ~= nil then
                return math.deg(steeringNode.physics.steeringAngle)
            end
        end
        if dashboard.wheelIndices == nil then
            return 0
        end
        local steeringNode = 0
        for _, wheelIndex in ipairs(dashboard.wheelIndices) do
            local wheel = spec.wheels[wheelIndex]
            if wheel ~= nil then
                steeringNode = math.max(steeringNode, (math.abs(wheel.physics.steeringAngle)))
            end
        end
        return math.deg(steeringNode)
    end)
    steeringAngle:setAdditionalFunctions(function(_, xmlFile, key, dashboard, _)
        dashboard.steeringNodeIndex = xmlFile:getValue(key .. "#steeringNodeIndex")
        dashboard.wheelIndex = xmlFile:getValue(key .. "#wheelIndex")
        dashboard.wheelIndices = xmlFile:getValue(key .. "#wheelIndices", nil, true)
        return true
    end)
    self:registerDashboardValueType(steeringAngle)
end
function Wheels:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_wheels
    if spec.lastWheelConfigSaveId ~= nil then
        xmlFile:setValue(key .. "#lastConfigId", spec.lastWheelConfigSaveId)
    end
end
function Wheels:onDelete()
    local spec = self.spec_wheels
    if spec.sharedLoadRequestIds ~= nil then
        for _, sharedLoadRequestId in pairs(spec.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
        end
    end
    if spec.hubs ~= nil then
        for _, sharedLoadRequestId in pairs(spec.hubs) do
            delete(sharedLoadRequestId.node)
        end
    end
    if spec.wheels ~= nil then
        for _, sharedLoadRequestId in pairs(spec.wheels) do
            sharedLoadRequestId:delete()
        end
    end
    if spec.dynamicallyLoadedWheels ~= nil then
        for _, sharedLoadRequestId in ipairs(spec.dynamicallyLoadedWheels) do
            sharedLoadRequestId:delete()
        end
    end
    g_soundManager:deleteSamples(spec.surfaceSounds)
end
function Wheels:onReadStream(streamId, connection)
    if connection.isServer then
        local spec = self.spec_wheels
        spec.networkTimeInterpolator:reset()
        local i = 1
        for i = i, #spec.wheels do
            local wheel = spec.wheels[i]
            if wheel.physics.isSynchronized then
                wheel:readStream(streamId, true)
            end
        end
        self.rotatedTimeInterpolator:setValue(0)
    end
end
function Wheels:onWriteStream(streamId, connection)
    if not connection.isServer then
        local spec = self.spec_wheels
        local i = 1
        for i = i, #spec.wheels do
            local wheel = spec.wheels[i]
            if wheel.physics.isSynchronized then
                wheel:writeStream(streamId)
            end
        end
    end
end
function Wheels:onReadUpdateStream(streamId, _, connection)
    if connection.isServer and streamReadBool(streamId) then
        local spec = self.spec_wheels
        spec.networkTimeInterpolator:startNewPhaseNetwork()
        local i = 1
        local rotatedTimeRange = #spec.wheels
        local rotatedTime = 1
        for i = i, rotatedTimeRange, rotatedTime do
            local wheel = spec.wheels[i]
            if wheel.physics.isSynchronized then
                wheel:readStream(streamId, false)
            end
        end
        if self.maxRotTime ~= 0 and self.minRotTime ~= 0 then
            local rotatedTimeRange = math.max(self.maxRotTime - self.minRotTime, 0.001)
            local rotatedTime = streamReadUIntN(streamId, 8)
            if math.abs(self.rotatedTime) < 0.001 then
                self.rotatedTime = 0
            end
            self.rotatedTimeInterpolator:setTargetValue(rotatedTime / 255 * rotatedTimeRange + self.minRotTime)
        end
    end
end
function Wheels:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection.isServer then
        local spec = self.spec_wheels
        local rotatedTimeRange = streamWriteBool
        local i = bit32.band(dirtyMask, spec.dirtyFlag) ~= 0
        if rotatedTimeRange(streamId, i) then
            local i = 1
            local rotatedTimeRange = #spec.wheels
            local rotatedTime = 1
            for i = i, rotatedTimeRange, rotatedTime do
                local wheel = spec.wheels[i]
                if wheel.physics.isSynchronized then
                    wheel:writeStream(streamId)
                end
            end
            if self.maxRotTime ~= 0 and self.minRotTime ~= 0 then
                local rotatedTimeRange = math.max(self.maxRotTime - self.minRotTime, 0.001)
                local i = math.floor((self.rotatedTime - self.minRotTime) / rotatedTimeRange * 255)
                streamWriteUIntN(streamId, math.clamp(i, 0, 255), 8)
            end
        end
    end
end
function Wheels:onUpdate(dt, _, _, _)
    local spec = self.spec_wheels
    if not self.isServer and self.isClient then
        spec.networkTimeInterpolator:update(dt)
        local interpolationAlpha = spec.networkTimeInterpolator:getAlpha()
        self.rotatedTime = self.rotatedTimeInterpolator:getInterpolatedValue(interpolationAlpha)
        local i = 1
        for i = i, #spec.wheels do
            spec.wheels[i]:updateInterpolation(dt, interpolationAlpha)
        end
        if spec.networkTimeInterpolator:isInterpolating() then
            self:raiseActive()
        end
    end
    if self.finishedFirstUpdate then
        local interpolationAlpha = g_currentMission.environment.weather:getGroundWetness()
        for wheel, wheel in ipairs(spec.wheels) do
            wheel:update(dt, spec.currentUpdateIndex, interpolationAlpha)
        end
        spec.currentUpdateIndex = spec.currentUpdateIndex + 1
        if spec.currentUpdateIndex > 4 then
            spec.currentUpdateIndex = 1
        end
        if self.isActive then
            local allowFoliageDestruction = g_currentMission.missionInfo.fruitDestruction
            if allowFoliageDestruction then
                allowFoliageDestruction = not self:getIsAIActive()
            end
            if allowFoliageDestruction then
                allowFoliageDestruction = true
                if self.getBlockFoliageDestruction ~= nil then
                    allowFoliageDestruction = not self:getBlockFoliageDestruction()
                end
            end
            for wheel, wheel in ipairs(spec.wheels) do
                wheel.destruction:update(dt, allowFoliageDestruction)
            end
            if self.isServer and spec.hasAxles then
                for wheel, wheel in ipairs(spec.axles) do
                    wheel:update(dt)
                end
            end
        end
        if spec.surfaceSounds ~= nil then
            if self:getAreSurfaceSoundsActive() then
                local allowFoliageDestruction = self:getCurrentSurfaceSound()
                if allowFoliageDestruction ~= spec.currentSurfaceSound then
                    if spec.currentSurfaceSound ~= nil then
                        g_soundManager:stopSample(spec.currentSurfaceSound)
                    end
                    if allowFoliageDestruction ~= nil then
                        g_soundManager:playSample(allowFoliageDestruction)
                    end
                    spec.currentSurfaceSound = allowFoliageDestruction
                end
            elseif spec.currentSurfaceSound ~= nil then
                g_soundManager:stopSample(spec.currentSurfaceSound)
                spec.currentSurfaceSound = nil
            end
        end
        if spec.hasSteeringNodes then
            self:updateSteeringNodes(dt)
        end
    end
    if #spec.wheels > 0 and self.isServer then
        self:raiseDirtyFlags(spec.dirtyFlag)
    end
end
function Wheels:onPostUpdate(dt, _, _, _)
    if self.isServer then
        for _, wheel in ipairs(self.spec_wheels.wheels) do
            wheel:postUpdate(dt)
        end
    end
end
function Wheels:onUpdateTick(dt, _, _, _)
    local groundWetness = g_currentMission.environment.weather:getGroundWetness()
    for _, wheel in pairs(self.spec_wheels.wheels) do
        wheel:updateTick(dt, groundWetness, self.currentUpdateDistance)
    end
end
function Wheels:onUpdateEnd(_, _, _, _)
    if self.isClient then
        local spec = self.spec_wheels
        for _, wheel in pairs(spec.wheels) do
            wheel:onUpdateEnd()
        end
        if spec.currentSurfaceSound ~= nil then
            g_soundManager:stopSample(spec.currentSurfaceSound)
            spec.currentSurfaceSound = nil
        end
    end
end
function Wheels:loadHubsFromXML()
    self.spec_wheels.hubs = {}
    self.xmlFile:iterate("vehicle.wheels.hubs.hub", function(_, key)
        -- upvalues: (copy) self
        self:loadHubFromXML(self.xmlFile, key)
    end)
end
function Wheels.loadHubMaterial(vehicle, xmlFile, key, hub, materialName)
    local material = VehicleMaterial.new(vehicle.baseDirectory)
    if material:loadFromXML(xmlFile, key, vehicle.customEnvironment) then
        hub[materialName] = material
    end
    if xmlFile:getValue(key .. "#useBaseColor", false) then
        hub[materialName] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, "baseColor") or hub[materialName]
    elseif xmlFile:getValue(key .. "#useRimColor", false) then
        hub[materialName] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, "rimColor") or (vehicle.spec_wheels.rimMaterial or hub[materialName])
        if hub[materialName] == nil then
            hub[materialName] = VehicleMaterial.new(vehicle.baseDirectory)
            hub[materialName]:setTemplateName("RIM_DEFAULT")
            return
        end
    else
        local useDesignColorIndex = xmlFile:getValue(key .. "#useDesignColorIndex")
        if useDesignColorIndex ~= nil then
            local configName = "designColor"
            if useDesignColorIndex >= 2 then
                configName = string.format("designColor%d", useDesignColorIndex)
            end
            hub[materialName] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, configName) or hub[materialName]
        end
    end
end
function Wheels:loadHubFromXML(xmlFile, key)
    local linkNode = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)
    if linkNode ~= nil then
        local hub = {
            ["linkNode"] = linkNode,
            ["isLeft"] = xmlFile:getValue(key .. "#isLeft")
        }
        local hubXmlFilename = xmlFile:getValue(key .. "#filename")
        hub.xmlFilename = Utils.getFilename(hubXmlFilename, self.baseDirectory)
        local xmlFileHub = XMLFile.load("wheelHubXml", hub.xmlFilename, Wheels.xmlSchemaHub)
        if xmlFileHub ~= nil then
            local i3dFilename = xmlFileHub:getValue("hub.filename")
            if i3dFilename == nil then
                Logging.xmlError(xmlFileHub, "Unable to retrieve hub i3d filename!")
                return
            end
            hub.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
            Wheels.loadHubMaterial(self, xmlFile, key .. ".material", hub, "material")
            Wheels.loadHubMaterial(self, xmlFile, key .. ".boltMaterial", hub, "boltMaterial")
            Wheels.loadHubMaterial(self, xmlFile, key .. ".additionalMaterial", hub, "additionalMaterial")
            Wheels.loadHubMaterial(self, xmlFile, key .. ".boltAdditionalMaterial", hub, "boltAdditionalMaterial")
            hub.nodeStr = xmlFileHub:getValue("hub.nodes#" .. (hub.isLeft and "left" or "right"))
            local sharedLoadRequestId = self:loadSubSharedI3DFile(hub.i3dFilename, false, false, self.onWheelHubI3DLoaded, self, {
                ["hub"] = hub,
                ["linkNode"] = linkNode,
                ["xmlFile"] = xmlFile,
                ["key"] = key
            })
            table.insert(self.spec_wheels.sharedLoadRequestIds, sharedLoadRequestId)
            xmlFileHub:delete()
        end
        return true
    end
    Logging.xmlError(xmlFile, "Missing link node for hub \'%s\'", key)
end
function Wheels:onWheelHubI3DLoaded(i3dNode, _, args)
    if i3dNode == 0 then
        if not (self.isDeleting or self.isDeleted) then
            Logging.xmlError(args.xmlFile, "Unable to load \'%s\' in hub \'%s\'", args.hub.i3dFilename, args.hub.xmlFilename)
        end
        return
    else
        hub.node = I3DUtil.indexToObject(i3dNode, hub.nodeStr, self.i3dMappings)
        if hub.node == nil then
            Logging.xmlError(xmlFile, "Could not find hub node \'%s\' in \'%s\'", hub.nodeStr, hub.xmlFilename)
        else
            link(args.linkNode, hub.node)
            delete(i3dNode)
            local offset = xmlFile:getValue(args.key .. "#offset")
            if offset ~= nil then
                if not hub.isLeft then
                end
                setTranslation(hub.node, offset, 0, 0)
            end
            local scale = xmlFile:getValue(key .. "#scale", nil, true)
            if scale ~= nil then
                setScale(hub.node, scale[1], scale[2], scale[3])
            end
            table.insert(self.spec_wheels.hubs, hub)
        end
    end
end
function Wheels.getAckermannSteeringAngles(steeringNode, steeringCenterNode, maxTurningRadius)
    local diffX, _, diffZ = localToLocal(steeringNode, steeringCenterNode, 0, 0, 0)
    local rotMin
    if maxTurningRadius - diffX == 0 then
        rotMin = 1.5707963267948966 * math.sign(diffZ)
    else
        rotMin = math.atan(diffZ / (maxTurningRadius - diffX))
    end
    local rotMin
    if maxTurningRadius + diffX == 0 then
        rotMin = -1.5707963267948966 * math.sign(diffZ)
    else
        rotMin = -math.atan(diffZ / (maxTurningRadius + diffX))
    end
    local inverted = rotMin < rotMin
    if not inverted then
    end
    return rotMin, rotMin, inverted
end
function Wheels:loadAckermannSteeringFromXML(xmlFile, ackermannSteeringIndex, ackermannSteeringAngle)
    local spec = self.spec_wheels
    local key, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, ackermannSteeringIndex, "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering", nil, "ackermann")
    spec.steeringCenterNode = nil
    if key ~= nil then
        local rotSpeed = xmlFile:getValue(key .. "#rotSpeed")
        local rotMax = ackermannSteeringAngle or xmlFile:getValue(key .. "#rotMax")
        local centerX = nil
        local centerZ = nil
        local rotCenterWheel1 = xmlFile:getValue(key .. "#rotCenterWheel1")
        if rotCenterWheel1 == nil or spec.wheels[rotCenterWheel1] == nil then
            local wheel, rotCenterWheel2 = xmlFile:getValue(key .. "#rotCenterNode", nil, self.components, self.i3dMappings)
            if wheel == nil then
                local wheel2 = xmlFile:getValue(key .. "#rotCenterWheels", nil, true)
                if wheel2 == nil or #wheel2 <= 0 then
                    local x = xmlFile:getValue(key .. "#rotCenter", nil, true)
                    if x ~= nil then
                        centerX = x[1]
                        centerZ = x[2]
                    end
                else
                    local x = 0
                    local _ = 0
                    local z = 0
                    local i = 1
                    local wheel = #wheel2
                    for i = i, wheel do
                        local wheel = spec.wheels[wheel2[i]]
                        if wheel ~= nil then
                            local _x, _, _z = localToLocal(wheel.node, self.components[1].node, wheel.physics.positionX, 0, wheel.physics.positionZ)
                        end
                    end
                    if z > 0 then
                        centerX = x / z
                        centerZ = _ / z
                    end
                end
            else
                local x
                centerX, x, centerZ = localToLocal(wheel, self.components[1].node, 0, 0, 0)
                spec.steeringCenterNode = wheel
            end
        else
            local wheel = spec.wheels[rotCenterWheel1]
            local wheel2
            centerX, wheel2, centerZ = localToLocal(wheel.node, self.components[1].node, wheel.physics.positionX, wheel.physics.positionY, wheel.physics.positionZ)
            local rotCenterWheel2 = xmlFile:getValue(key .. "#rotCenterWheel2")
            if rotCenterWheel2 ~= nil and spec.wheels[rotCenterWheel2] ~= nil then
                if rotCenterWheel2 == rotCenterWheel1 then
                    Logging.xmlWarning(xmlFile, "The ackermann steering wheels are identical (both index %d). Are you sure this is correct? (%s)", rotCenterWheel1, key)
                end
                local wheel2 = spec.wheels[rotCenterWheel2]
                local x, _, z = localToLocal(wheel2.node, self.components[1].node, wheel2.physics.positionX, wheel2.physics.positionY, wheel2.physics.positionZ)
            end
        end
        if spec.steeringCenterNode == nil then
            spec.steeringCenterNode = createTransformGroup("steeringCenterNode")
            link(self.components[1].node, spec.steeringCenterNode)
            if centerX ~= nil and centerZ ~= nil then
                setTranslation(spec.steeringCenterNode, centerX, 0, centerZ)
            end
        end
        if rotSpeed ~= nil and (rotMax ~= nil and centerX ~= nil) then
            local rotCenterWheel2 = math.rad(rotSpeed)
            local wheel = math.abs(rotCenterWheel2)
            local rotCenterWheel2 = math.rad(rotMax)
            local wheel = math.abs(rotCenterWheel2)
            local wheel = 0
            local rotCenterWheel2 = false
            for z, wheel in ipairs(spec.wheels) do
                if wheel.physics.rotSpeed ~= 0 then
                    local diffX, i, wheel = localToLocal(wheel.repr, spec.steeringCenterNode, 0, 0, 0)
                    local _x = math.abs(wheel) / math.tan(wheel) + math.abs(diffX)
                    if wheel <= _x then
                        rotCenterWheel2 = true
                        wheel = _x
                    end
                end
            end
            for z, wheel in ipairs(spec.steeringNodes) do
                local diffX, i, wheel = localToLocal(wheel.node, spec.steeringCenterNode, 0, 0, 0)
                local _x = math.abs(wheel) / math.tan(wheel) + math.abs(diffX)
                if wheel <= _x then
                    rotCenterWheel2 = true
                    wheel = _x
                end
            end
            local x = Utils.getNoNil(self.maxRotation, 0)
            self.maxRotation = math.max(x, wheel)
            self.maxTurningRadius = xmlFile:getValue(key .. "#minTurningRadius", wheel)
            self.wheelSteeringDuration = wheel / wheel
            if rotCenterWheel2 then
                for z, wheel in ipairs(spec.wheels) do
                    if wheel.physics.rotSpeed ~= 0 then
                        local diffX, i, wheel = Wheels.getAckermannSteeringAngles(wheel.repr, spec.steeringCenterNode, wheel)
                        wheel:setSteeringValues(diffX, i, i / self.wheelSteeringDuration, -diffX / self.wheelSteeringDuration, wheel)
                    end
                end
                for z, wheel in ipairs(spec.steeringNodes) do
                    local diffX, i, wheel = Wheels.getAckermannSteeringAngles(wheel.node, spec.steeringCenterNode, wheel)
                    wheel.rotMin = diffX
                    wheel.rotMax = i
                    wheel.rotSpeed = i / self.wheelSteeringDuration
                    wheel.rotSpeedNeg = -diffX / self.wheelSteeringDuration
                    if wheel then
                        wheel.rotSpeed = -wheel.rotSpeedNeg
                        wheel.rotSpeedNeg = -wheel.rotSpeed
                    end
                    local _x = wheel.rotMin
                    local _ = wheel.rotMax
                    wheel.rotMinOrig = _x
                    wheel.rotMaxOrig = _
                    local _x = wheel.rotSpeed
                    local _ = wheel.rotSpeedNeg
                    wheel.rotSpeedOrig = _x
                    wheel.rotSpeedNegOrig = _
                end
            end
        end
    end
    for centerZ, rotCenterWheel1 in ipairs(spec.wheels) do
        if rotCenterWheel1.physics.rotSpeed ~= 0 then
            local wheel = rotCenterWheel1.physics.rotMax >= 0
            local rotCenterWheel2 = rotCenterWheel1.physics.rotSpeed >= 0
            if wheel == rotCenterWheel2 then
                self.maxRotTime = math.max(rotCenterWheel1.physics.rotMax / rotCenterWheel1.physics.rotSpeed, self.maxRotTime)
            end
            local wheel = rotCenterWheel1.physics.rotMin >= 0
            local rotCenterWheel2 = rotCenterWheel1.physics.rotSpeed >= 0
            if wheel == rotCenterWheel2 then
                self.maxRotTime = math.max(rotCenterWheel1.physics.rotMin / rotCenterWheel1.physics.rotSpeed, self.maxRotTime)
            end
            local wheel = rotCenterWheel1.physics.rotSpeedNeg
            if wheel == nil or wheel == 0 then
                wheel = rotCenterWheel1.physics.rotSpeed
            end
            local rotCenterWheel2 = rotCenterWheel1.physics.rotMax >= 0
            local wheel2 = wheel >= 0
            if rotCenterWheel2 ~= wheel2 then
                self.minRotTime = math.min(rotCenterWheel1.physics.rotMax / wheel, self.minRotTime)
            end
            local rotCenterWheel2 = rotCenterWheel1.physics.rotMin >= 0
            local wheel2 = wheel >= 0
            if rotCenterWheel2 ~= wheel2 then
                self.minRotTime = math.min(rotCenterWheel1.physics.rotMin / wheel, self.minRotTime)
            end
        end
        if rotCenterWheel1.physics.rotSpeedLimit ~= nil then
            rotCenterWheel1.physics.rotSpeedDefault = rotCenterWheel1.physics.rotSpeed
            rotCenterWheel1.physics.rotSpeedNegDefault = rotCenterWheel1.physics.rotSpeedNeg
            rotCenterWheel1.physics.currentRotSpeedAlpha = 1
        end
    end
    for centerZ, rotCenterWheel1 in ipairs(spec.steeringNodes) do
        self.maxRotTime = math.max(rotCenterWheel1.rotMax / rotCenterWheel1.rotSpeed, self.maxRotTime)
        local wheel = rotCenterWheel1.rotSpeedNeg
        if wheel == nil or wheel == 0 then
            wheel = rotCenterWheel1.rotSpeed
        end
        self.minRotTime = math.min(rotCenterWheel1.rotMin / wheel, self.minRotTime)
    end
end
function Wheels:loadWheelsFromXML(xmlFile, key, wheelConfigurationId)
    local i = 0
    while true do
        local wheelKey = string.format(".wheels.wheel(%d)", i)
        if not xmlFile:hasProperty(key .. wheelKey) then
            break
        end
        local wheel = Wheel.new(self, self.xmlFile, Wheels.CONFIG_XML_PATH, wheelKey, i + 1, wheelConfigurationId, self.spec_wheels.configurationIndexToParentConfigIndex, self.baseDirectory)
        if self:loadWheelFromXML(wheel) then
            wheel:finalize()
            if spec.isCareWheelConfiguration ~= nil then
                wheel:setIsCareWheel(spec.isCareWheelConfiguration)
            end
            table.insert(spec.wheels, wheel)
        end
        i = i + 1
    end
end
function Wheels.loadWheelFromXML(_, wheel)
    return wheel:loadFromXML()
end
function Wheels:onLoadWheelChockFromXML(wheelChock) end
function Wheels:getIsWheelChockAllowed(wheelChock)
    return true
end
function Wheels:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    local brakeForce = self:getBrakeForce()
    for _, wheel in pairs(self.spec_wheels.wheels) do
        wheel:addToPhysics(brakeForce)
    end
    if self.isServer then
        self:brake(brakeForce)
    end
    return true
end
function Wheels:removeFromPhysics(superFunc)
    local ret = superFunc(self)
    if self.isServer then
        for _, wheel in pairs(self.spec_wheels.wheels) do
            wheel:removeFromPhysics()
        end
    end
    return ret
end
function Wheels:getComponentMass(superFunc, component)
    local mass = superFunc(self, component)
    for _, wheel in pairs(self.spec_wheels.wheels) do
        if wheel.node == component.node then
            mass = mass + wheel:getMass()
        end
    end
    return mass
end
function Wheels:getVehicleWorldXRot(superFunc)
    local slopeAngle = 0
    local minWheelZ = math.huge
    local minWheelZHeight = 0
    local maxWheelZ = -math.huge
    local maxWheelZHeight = 0
    local spec = self.spec_wheels
    local i = 1
    local y = #spec.wheels
    local l = 1
    for i = i, y, l do
        local wheel = spec.wheels[i]
        if wheel.physics.hasGroundContact then
            local netInfo = wheel.physics.netInfo
            local _, _, z = localToLocal(wheel.node, self.components[1].node, 0, 0, netInfo.z)
            local _, wheelY, _ = localToWorld(wheel.node, netInfo.x, netInfo.y - wheel.physics.radius, netInfo.z)
            if z < minWheelZ then
                minWheelZHeight = wheelY
                minWheelZ = z
            end
            if maxWheelZ < z then
                maxWheelZHeight = wheelY
                maxWheelZ = z
            end
        end
    end
    if minWheelZ ~= math.huge then
        local y = maxWheelZHeight - minWheelZHeight
        if y ~= 0 then
            local l = maxWheelZ - minWheelZ
            if l < 0.25 and superFunc ~= nil then
                return superFunc(self)
            end
            slopeAngle = 1.5707963267948966 - math.atan(l / y)
            if slopeAngle > 1.5707963267948966 then
            end
        end
    end
    return slopeAngle
end
function Wheels:getVehicleWorldDirection(superFunc)
    local avgDirX = 0
    local avgDirY = 0
    local avgDirZ = 0
    local centerZ = 0
    local contactedWheels = 0
    local spec = self.spec_wheels
    local i = 1
    local frontCenterX = #spec.wheels
    local frontCenterY = 1
    for i = i, frontCenterX, frontCenterY do
        local wheel = spec.wheels[i]
        if wheel.physics.hasGroundContact then
            local netInfo = wheel.physics.netInfo
            local _, _, z = localToLocal(wheel.node, self.components[1].node, netInfo.x, netInfo.y, netInfo.z)
            local dx, dy, dz = localDirectionToWorld(wheel.node, wheel.physics.directionZ, wheel.physics.directionX, -wheel.physics.directionY)
        end
    end
    if contactedWheels > 0 then
        local _ = avgDirY / contactedWheels
    end
    if contactedWheels <= 2 then
        return 0, 0, 0
    end
    local centerZ = centerZ / contactedWheels
    local frontCenterX = 0
    local frontCenterY = 0
    local i = 0
    local wheel = 0
    local netInfo = 0
    local _ = 0
    local _ = 0
    local z = 0
    local dz = 1
    local dx = #spec.wheels
    local dy = 1
    for dz = dz, dx, dy do
        local wheel = spec.wheels[dz]
        if wheel.physics.hasGroundContact then
            local netInfo = wheel.physics.netInfo
            local radius = wheel.physics.radius
            local x, y, z = localToLocal(wheel.node, self.components[1].node, netInfo.x + wheel.physics.directionX * radius, netInfo.y + wheel.physics.directionY * radius, netInfo.z + wheel.physics.directionZ * radius)
            if centerZ + 0.25 < z then
            elseif z < centerZ - 0.25 then
            end
        end
    end
    if wheel <= 0 or z <= 0 then
        return superFunc(self)
    end
    local frontCenterX = frontCenterX / wheel
    local frontCenterY = frontCenterY / wheel
    local i = i / wheel
    local netInfo = netInfo / z
    local _ = _ / z
    local _ = _ / z
    local dx, dy, dz = localToWorld(self.components[1].node, frontCenterX, frontCenterY, i)
    local dx, dy, dz = localToWorld(self.components[1].node, netInfo, _, _)
    if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
        DebugGizmo.renderAtPosition(dx, dy, dz, 1, 0, 0, 0, 1, 0, "frontWheels")
        DebugGizmo.renderAtPosition(dx, dy, dz, 1, 0, 0, 0, 1, 0, "backWheels")
    end
    local dx = dx - dx
    local dy = dy - dy
    local dz = dz - dz
    local netInfo, radius, x = MathUtil.vector3Normalize(dx, dy, dz)
    return MathUtil.vector3Normalize(avgDirX, radius, avgDirZ)
end
function Wheels:validateWashableNode(superFunc, node)
    if self.loadingStep >= SpecializationLoadStep.FINISHED then
        local spec = self.spec_wheels
        local i = 1
        for i = i, #spec.wheels do
            local wheel = spec.wheels[i]
            local wheelNode = wheel.driveNode
            if wheel.linkNode ~= wheel.driveNode then
                wheelNode = wheel.linkNode
            end
            if wheel.wheelDirtNodes == nil then
                wheel.wheelDirtNodes = {}
                I3DUtil.getNodesByShaderParam(wheelNode, "scratches_dirt_snow_wetness", wheel.wheelDirtNodes)
            end
            if wheel.wheelMudMeshes == nil then
                wheel.wheelMudMeshes = {}
                I3DUtil.getNodesByShaderParam(wheelNode, "mudAmount", wheel.wheelMudMeshes)
            end
            if wheel.wheelDirtNodes[node] ~= nil then
                local nodeData = {
                    ["wheel"] = wheel,
                    ["fieldDirtMultiplier"] = wheel.physics.fieldDirtMultiplier,
                    ["streetDirtMultiplier"] = wheel.physics.streetDirtMultiplier,
                    ["waterWetnessFactor"] = wheel.physics.waterWetnessFactor,
                    ["minDirtPercentage"] = wheel.physics.minDirtPercentage,
                    ["maxDirtOffset"] = wheel.physics.maxDirtOffset,
                    ["dirtColorChangeSpeed"] = wheel.physics.dirtColorChangeSpeed,
                    ["isSnowNode"] = true,
                    ["loadFromSavegameFunc"] = function(xmlFile, key)
                        -- upvalues: (copy) nodeData, (copy) self, (copy) wheel
                        nodeData.wheel.physics.snowScale = xmlFile:getValue(key .. "#snowScale", 0)
                        nodeData.wheel.physics.lastSnowScale = nodeData.wheel.physics.snowScale
                        local defaultColor, snowColor = g_currentMission.environment:getDirtColors()
                        local r, g, b = MathUtil.vector3ArrayLerp(defaultColor, snowColor, nodeData.wheel.physics.snowScale)
                        self:setNodeDirtColor(self:getWashableNodeByCustomIndex(wheel), r, g, b, true)
                    end,
                    ["saveToSavegameFunc"] = function(xmlFile, key)
                        -- upvalues: (copy) nodeData
                        xmlFile:setValue(key .. "#snowScale", nodeData.wheel.physics.snowScale)
                    end
                }
                return false, self.updateWheelDirtAmount, wheel, nodeData
            end
            if wheel.wheelMudMeshes[node] ~= nil then
                rotateAboutLocalAxis(node, math.random() * 3.14, 1, 0, 0)
                return false, self.updateWheelMudAmount, wheel.wheelMudMeshes, {
                    ["wheel"] = wheel,
                    ["fieldDirtMultiplier"] = wheel.physics.fieldDirtMultiplier,
                    ["streetDirtMultiplier"] = wheel.physics.streetDirtMultiplier,
                    ["waterWetnessFactor"] = wheel.physics.waterWetnessFactor,
                    ["minDirtPercentage"] = wheel.physics.minDirtPercentage,
                    ["maxDirtOffset"] = wheel.physics.maxDirtOffset,
                    ["dirtColorChangeSpeed"] = wheel.physics.dirtColorChangeSpeed,
                    ["isSnowNode"] = true,
                    ["cleaningMultiplier"] = 4
                }
            end
        end
    end
    return superFunc(self, node)
end
function Wheels:getAIDirectionNode(superFunc)
    return self.spec_wheels.steeringCenterNode or superFunc(self)
end
function Wheels:getAIRootNode(superFunc)
    return self.spec_wheels.steeringCenterNode or superFunc(self)
end
function Wheels:getSupportsMountKinematic(superFunc)
    return #self.spec_wheels.wheels == 0 and superFunc(self)
end
function Wheels:loadBendingNodeFromXML(superFunc, xmlFile, key, bendingNode, ...)
    if not superFunc(self, xmlFile, key, bendingNode, ...) then
        return false
    end
    local wheelIndices = xmlFile:getValue(key .. "#wheelIndices", nil, true)
    if wheelIndices ~= nil and #wheelIndices > 0 then
        bendingNode.minX = math.huge
        bendingNode.maxX = -math.huge
        bendingNode.minZ = math.huge
        bendingNode.maxZ = -math.huge
        for _, wheelIndex in ipairs(wheelIndices) do
            local wheel = self:getWheelFromWheelIndex(wheelIndex)
            if wheel == nil then
                Logging.xmlWarning(xmlFile, "Unable to find wheel index \'%s\' in \'%s\'", wheelIndex, key)
            else
                local x1, _, z1 = localToLocal(wheel.driveNode, bendingNode.node, wheel.physics.wheelShapeWidth * 0.5 + 0.05 + wheel.physics.wheelShapeWidthOffset, 0, wheel.physics.radius * 0.5 + 0.05)
                local x2, _, z2 = localToLocal(wheel.driveNode, bendingNode.node, -(wheel.physics.wheelShapeWidth * 0.5 + 0.05 - wheel.physics.wheelShapeWidthOffset), 0, -(wheel.physics.radius * 0.5 + 0.05))
                bendingNode.minX = math.min(bendingNode.minX, x1, x2)
                bendingNode.maxX = math.max(bendingNode.maxX, x1, x2)
                bendingNode.minZ = math.min(bendingNode.minZ, z1, z2)
                bendingNode.maxZ = math.max(bendingNode.maxZ, z1, z2)
            end
        end
        bendingNode.minX = xmlFile:getValue(key .. "#minX", bendingNode.minX)
        bendingNode.maxX = xmlFile:getValue(key .. "#maxX", bendingNode.maxX)
        bendingNode.minZ = xmlFile:getValue(key .. "#minZ", bendingNode.minZ)
        bendingNode.maxZ = xmlFile:getValue(key .. "#maxZ", bendingNode.maxZ)
    end
    return true
end
function Wheels:updateWheelDirtAmount(nodeData, dt, _, rainScale, _, temperature)
    local changeDirt = 0
    local changeWetness = 0
    local dirtMultiplier = self.spec_washable.lastDirtMultiplier
    if dirtMultiplier ~= 0 then
        changeDirt = dt * self.spec_washable.dirtDuration * dirtMultiplier
    end
    local allowManipulation = true
    if nodeData.wheel ~= nil and (nodeData.wheel.physics.contact == WheelContactType.NONE and nodeData.wheel.forceWheelDirtUpdate ~= true) then
        allowManipulation = false
    end
    if allowManipulation then
        local physics = nodeData.wheel.physics
        local isOnDirtField = physics:getIsOnField()
        local lastSpeed = self.lastSpeed * 3600
        if isOnDirtField then
        elseif not self.isOnField and nodeData.dirtAmount > nodeData.minDirtPercentage then
        end
        if nodeData.wetness < 0.25 then
            local dirtFactor = self.spec_washable.washableNodes[1].dirtAmount
            local maxDirtOffset = nodeData.maxDirtOffset
            local minDirtOffset = maxDirtOffset * (math.pow(1 - dirtFactor, 2) * 0.75 + 0.25)
            local maxDirtOffset = nodeData.maxDirtOffset * (math.pow(1 - dirtFactor, 2) * 0.95 + 0.05)
            if minDirtOffset < dirtFactor - nodeData.dirtAmount then
                changeDirt = changeDirt < 0 and 0 or changeDirt
            else
                changeDirt = dirtFactor - nodeData.dirtAmount < -maxDirtOffset and changeDirt > 0 and 0 or changeDirt
            end
        end
        local dirtFactor = physics.hasSnowContact and (temperature or 0) < 1 and 1 or -0.25
        local maxDirtOffset = lastSpeed / 5
        local minDirtOffset = math.min(maxDirtOffset, 2)
        local r = physics.snowScale + dirtFactor * dt * nodeData.dirtColorChangeSpeed * minDirtOffset
        local snowColor = math.max(r, 0)
        physics.snowScale = math.min(snowColor, 1)
        if physics.snowScale ~= physics.lastSnowScale then
            local defaultColor, snowColor = g_currentMission.environment:getDirtColors()
            local r, g, b = MathUtil.vector3ArrayLerp(defaultColor, snowColor, physics.snowScale)
            self:setNodeDirtColor(nodeData, r, g, b)
            physics.lastSnowScale = physics.snowScale
        end
        if physics.hasWaterContact then
            changeWetness = dt * self.spec_washable.wetDuration * nodeData.waterWetnessFactor * (1 + math.min(self.lastSpeed * 3600 / 10, 1))
        else
            changeWetness = -dt * self.spec_washable.dryDuration * (math.min(self.lastSpeed * 3600 / 10, 1) * 5)
        end
        nodeData.wheel.forceWheelDirtUpdate = false
    end
    return changeDirt, changeWetness
end
function Wheels:updateWheelMudAmount(nodeData, dt, _, rainScale, _, _)
    local changeDirt = 0
    local dirtMultiplier = self.spec_washable.lastDirtMultiplier
    if dirtMultiplier ~= 0 then
        changeDirt = dt * self.spec_washable.dirtDuration * dirtMultiplier
    end
    if nodeData.wheelDirtNode == nil then
        nodeData.wheelDirtNode = self:getWashableNodeByCustomIndex(nodeData.wheel)
        if nodeData.wheelDirtNode == nil then
            return 0, 0
        end
    end
    if nodeData.wheel ~= nil and (nodeData.wheel.physics.contact == WheelContactType.NONE and nodeData.wheel.forceWheelDirtUpdate ~= true) then
        return 0, nodeData.wheelDirtNode.wetness - nodeData.wetness
    end
    local maxAmount = WheelEffects.MAX_MUD_AMOUNT[nodeData.wheel.physics.densityType] or 0
    local wheelDirtAmount = rainScale > 0.1 and 1 or 0.5
    local maxAmount = maxAmount * wheelDirtAmount
    local wheelDirtAmount = nodeData.wheelDirtNode.dirtAmount
    if nodeData.dirtAmount < maxAmount and wheelDirtAmount > 0.75 then
    elseif maxAmount < nodeData.dirtAmount or wheelDirtAmount < 0.75 then
    end
    local speedFactor = nodeData.color
    local colorWheel = nodeData.wheelDirtNode.color
    if speedFactor[1] ~= colorWheel[1] or (speedFactor[2] ~= colorWheel[2] or speedFactor[3] ~= colorWheel[3]) then
        self:setNodeDirtColor(nodeData, colorWheel[1], colorWheel[2], colorWheel[3])
    end
    return changeDirt, nodeData.wheelDirtNode.wetness - nodeData.wetness
end
function Wheels:forceUpdateWheelPhysics(_)
    local spec = self.spec_wheels
    local i = 1
    for i = i, #spec.wheels do
        spec.wheels[i]:updatePhysics(self:getBrakeForce())
    end
end
function Wheels:onWheelSnowHeightChanged(heightPct, _)
    if heightPct <= 0 then
        local spec = self.spec_wheels
        local changedSnowScale = false
        local i = 1
        for i = i, #spec.wheels do
            if spec.wheels[i].physics.snowScale > 0 then
                spec.wheels[i].physics.snowScale = 0
                spec.wheels[i].forceWheelDirtUpdate = true
                changedSnowScale = true
            end
        end
        if changedSnowScale then
            self:raiseActive()
        end
    end
end
function Wheels:getSteeringNodeByNode(node)
    for _, steeringNode in ipairs(self.spec_wheels.steeringNodes) do
        if steeringNode.node == node then
            return steeringNode
        end
    end
    return nil
end
function Wheels:updateSteeringNodes(dt)
    for _, steeringNode in ipairs(self.spec_wheels.steeringNodes) do
        local targetSteeringAngle
        if self.rotatedTime > 0 or steeringNode.rotSpeedNeg == nil then
            targetSteeringAngle = self.rotatedTime * steeringNode.rotSpeed
        else
            targetSteeringAngle = self.rotatedTime * steeringNode.rotSpeedNeg
        end
        if steeringNode.rotMax < targetSteeringAngle then
            targetSteeringAngle = steeringNode.rotMax
        elseif targetSteeringAngle < steeringNode.rotMin then
            targetSteeringAngle = steeringNode.rotMin
        end
        if steeringNode.rotScale ~= steeringNode.rotScaleTarget then
            local direction = math.sign(steeringNode.rotScaleTarget - steeringNode.rotScale)
            steeringNode.rotScale = (direction > 0 and math.min or math.max)(steeringNode.rotScale + dt * steeringNode.rotScaleTargetSpeed * direction, steeringNode.rotScaleTarget)
        end
        local targetSteeringAngle = targetSteeringAngle * steeringNode.rotScale
        if steeringNode.offset ~= steeringNode.offsetTarget then
            local direction = math.sign(steeringNode.offsetTarget - steeringNode.offset)
            steeringNode.offset = (direction > 0 and math.min or math.max)(steeringNode.offset + dt * steeringNode.offsetTargetSpeed * direction, steeringNode.offsetTarget)
        end
        local targetSteeringAngle = targetSteeringAngle + steeringNode.offset
        local direction, change, limit = getRotation(steeringNode.node)
        local change = change - targetSteeringAngle
        if math.abs(change) > 0.004 then
            local direction = math.sign(targetSteeringAngle - change)
            setRotation(steeringNode.node, 0, (direction > 0 and math.min or math.max)(dt * steeringNode.rotChangeSpeed * 0.001 * direction + change, targetSteeringAngle), 0)
            steeringNode.steeringAngle = change
            if self.isServer and steeringNode.componentJoint ~= nil then
                self:setComponentJointFrame(steeringNode.componentJoint, 0)
            end
        end
    end
end
function Wheels:getCurrentSurfaceSound()
    local spec = self.spec_wheels
    for i, wheel in ipairs(spec.wheels) do
        if wheel.syncContactState or i == #spec.wheels then
            local surfaceName, surfaceId = wheel.physics:getSurfaceSoundAttributes()
            if surfaceName ~= nil then
                return spec.surfaceNameToSound[surfaceName]
            end
            if surfaceId ~= nil then
                return spec.surfaceIdToSound[surfaceId]
            end
        end
    end
    return nil
end
function Wheels:getAreSurfaceSoundsActive()
    return self.isActiveForLocalSound
end
function Wheels:getIsVersatileYRotActive(wheel)
    return true
end
function Wheels:getWheelFromWheelIndex(wheelIndex)
    return self.spec_wheels.wheels[wheelIndex]
end
function Wheels:getWheelByWheelNode(wheelNode)
    local spec = self.spec_wheels
    if type(wheelNode) == "string" then
        local mapping = self.i3dMappings[wheelNode]
        if mapping ~= nil then
            wheelNode = mapping.nodeId
        end
    end
    local i = 1
    local mapping = #spec.wheels
    for i = i, mapping do
        local wheel = spec.wheels[i]
        if wheel.repr == wheelNode or (wheel.driveNode == wheelNode or wheel.linkNode == wheelNode) then
            return wheel
        end
    end
    return nil
end
function Wheels:getWheels()
    return self.spec_wheels.wheels
end
function Wheels:brake(brakePedal)
    local spec = self.spec_wheels
    if brakePedal ~= spec.brakePedal then
        spec.brakePedal = brakePedal
        for _, wheel in pairs(spec.wheels) do
            wheel:setBrakePedal(spec.brakePedal)
        end
        SpecializationUtil.raiseEvent(self, "onBrake", spec.brakePedal)
    end
end
function Wheels:setCustomBrakeForce(brakeForce)
    self.spec_wheels.customBrakeForce = brakeForce
end
function Wheels:getBrakeForce()
    return self.spec_wheels.customBrakeForce or 0
end
function Wheels:onLeaveVehicle()
    if self.isServer and self.isAddedToPhysics then
        local brakeForce = self:getBrakeForce()
        for _, wheel in pairs(self.spec_wheels.wheels) do
            wheel:updatePhysics(brakeForce, 0)
        end
    end
end
function Wheels:onPreAttach()
    for _, wheel in pairs(self.spec_wheels.wheels) do
        wheel:onPreAttach()
    end
end
function Wheels:onPostDetach()
    for _, wheel in pairs(self.spec_wheels.wheels) do
        wheel:onPostDetach()
    end
end
function Wheels:getSteeringRotTimeByCurvature(curvature)
    local targetRotTime = 0
    if curvature ~= 0 then
        local spec = self.spec_wheels
        local targetRotTime = curvature > 0 and -math.huge or math.huge
        for i, wheel in ipairs(spec.wheels) do
            if wheel.physics.rotSpeed ~= 0 then
                local diffX, _, diffZ = localToLocal(wheel.repr, spec.steeringCenterNode, 0, 0, 0)
                local wheelRotTime = diffZ * math.abs(curvature) / (1 - math.abs(curvature) * math.abs(diffX))
                local wheelRotTime = math.atan(wheelRotTime) / wheel.physics.rotSpeed
                if curvature > 0 then
                    targetRotTime = math.max(targetRotTime, -wheelRotTime)
                else
                    targetRotTime = math.min(targetRotTime, wheelRotTime)
                end
            end
        end
        targetRotTime = targetRotTime * -1
    end
    return targetRotTime
end
function Wheels:getTurningRadiusByRotTime(rotTime)
    local spec = self.spec_wheels
    local maxTurningRadius = math.huge
    if spec.steeringCenterNode ~= nil then
        for i, wheel in ipairs(spec.wheels) do
            if wheel.physics.rotSpeed ~= 0 then
                local diffX = rotTime * wheel.physics.rotSpeed
                local wheelRot = math.abs(diffX)
                if wheelRot > 0 then
                    local diffX, _, diffZ = localToLocal(wheel.repr, spec.steeringCenterNode, 0, 0, 0)
                    local turningRadius = math.abs(diffZ) / math.tan(wheelRot) + math.abs(diffX)
                    if turningRadius < maxTurningRadius then
                        maxTurningRadius = turningRadius
                    end
                end
            end
        end
    end
    return maxTurningRadius
end
function Wheels:onRegisterAnimationValueTypes()
    self:registerAnimationValueType("steeringAngle", "startSteeringAngle", "endSteeringAngle", false, AnimationValueFloat, function(value, xmlFile, xmlKey)
        -- upvalues: (copy) self
        value.wheelIndex = xmlFile:getValue(xmlKey .. "#wheelIndex")
        value.wheelNode = xmlFile:getValue(xmlKey .. "#node", nil, self.components, self.i3dMappings)
        if value.wheelIndex == nil and not value.wheelNode then
            return false
        end
        if value.wheelIndex == nil then
            value:setWarningInformation("wheelNode: " .. getName(value.wheelNode))
            value:addCompareParameters("wheelNode")
        else
            value:setWarningInformation("wheelIndex: " .. value.wheelIndex)
            value:addCompareParameters("wheelIndex")
        end
        return true
    end, function(value)
        -- upvalues: (copy) self
        if value.wheelIndex == nil and value.wheelNode == nil then
            return 0
        end
        if value.wheel == nil and value.wheelIndex ~= nil then
            value.wheel = self:getWheelFromWheelIndex(value.wheelIndex)
            if value.wheel == nil then
                Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%s\' for animation part.", value.wheelIndex)
                value.wheelIndex = nil
                return 0
            end
        end
        if value.wheel == nil and value.wheelNode ~= nil then
            value.wheel = self:getWheelByWheelNode(value.wheelNode)
            if value.wheel == nil then
                Logging.xmlWarning(self.xmlFile, "Unknown wheel node \'%s\' for animation part.", getName(value.wheelNode))
                value.wheelNode = nil
                return 0
            end
        end
        return value.wheel.physics.steeringAngle
    end, function(value, steeringAngle)
        if value.wheel ~= nil then
            value.wheel.physics.steeringAngle = steeringAngle
        end
    end)
    self:registerAnimationValueType("brakeFactor", "startBrakeFactor", "endBrakeFactor", false, AnimationValueFloat, function(value, xmlFile, xmlKey)
        -- upvalues: (copy) self
        value.wheelIndex = xmlFile:getValue(xmlKey .. "#wheelIndex")
        value.wheelNode = xmlFile:getValue(xmlKey .. "#node", nil, self.components, self.i3dMappings)
        if value.wheelIndex == nil and not value.wheelNode then
            return false
        end
        if value.wheelIndex == nil then
            value:setWarningInformation("wheelNode: " .. getName(value.wheelNode))
            value:addCompareParameters("wheelNode")
        else
            value:setWarningInformation("wheelIndex: " .. value.wheelIndex)
            value:addCompareParameters("wheelIndex")
        end
        return true
    end, function(value)
        -- upvalues: (copy) self
        if value.wheel == nil and value.wheelIndex ~= nil then
            value.wheel = self:getWheelFromWheelIndex(value.wheelIndex)
            if value.wheel == nil then
                Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%s\' for animation part.", value.wheelIndex)
                value.wheelIndex = nil
                return 0
            end
        end
        if value.wheel == nil and value.wheelNode ~= nil then
            value.wheel = self:getWheelByWheelNode(value.wheelNode)
            if value.wheel == nil then
                Logging.xmlWarning(self.xmlFile, "Unknown wheel node \'%s\' for animation part.", getName(value.wheelNode))
                value.wheelNode = nil
                return 0
            end
        end
        return value.wheel.physics.brakeFactor
    end, function(value, brakeFactor)
        -- upvalues: (copy) self
        if value.wheel ~= nil then
            value.wheel.physics.brakeFactor = brakeFactor
            value.wheel:updatePhysics(self:getBrakeForce())
        end
    end)
    self:registerAnimationValueType("torqueDirection", "startTorqueDirection", "endTorqueDirection", false, AnimationValueFloat, function(value, xmlFile, xmlKey)
        -- upvalues: (copy) self
        value.wheelIndex = xmlFile:getValue(xmlKey .. "#wheelIndex")
        value.wheelNode = xmlFile:getValue(xmlKey .. "#node", nil, self.components, self.i3dMappings)
        if value.wheelIndex == nil and not value.wheelNode then
            return false
        end
        if value.wheelIndex == nil then
            value:setWarningInformation("wheelNode: " .. getName(value.wheelNode))
            value:addCompareParameters("wheelNode")
        else
            value:setWarningInformation("wheelIndex: " .. value.wheelIndex)
            value:addCompareParameters("wheelIndex")
        end
        return true
    end, function(value)
        -- upvalues: (copy) self
        if value.wheel == nil and value.wheelIndex ~= nil then
            value.wheel = self:getWheelFromWheelIndex(value.wheelIndex)
            if value.wheel == nil then
                Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%s\' for animation part.", value.wheelIndex)
                value.wheelIndex = nil
                return 0
            end
        end
        if value.wheel == nil and value.wheelNode ~= nil then
            value.wheel = self:getWheelByWheelNode(value.wheelNode)
            if value.wheel == nil then
                Logging.xmlWarning(self.xmlFile, "Unknown wheel node \'%s\' for animation part.", getName(value.wheelNode))
                value.wheelNode = nil
                return 0
            end
        end
        return value.wheel.physics.torqueDirection
    end, function(value, torqueDirection)
        if value.wheel ~= nil then
            value.wheel.physics:setTorqueDirection(torqueDirection)
        end
    end)
end
function Wheels:onPostAttachImplement(_, _, _, _)
    SpecializationUtil.raiseEvent(self, "onBrake", self.spec_wheels.brakePedal)
end
function Wheels:onAIFieldWorkerStart()
    for _, wheel in ipairs(self.spec_wheels.wheels) do
        wheel.physics:setDisplacementAllowed(false)
        wheel.physics:setDisplacementCollisionEnabled(false)
    end
end
function Wheels:onAIImplementStart()
    for _, wheel in ipairs(self.spec_wheels.wheels) do
        wheel.physics:setDisplacementAllowed(false)
        wheel.physics:setDisplacementCollisionEnabled(false)
    end
end
function Wheels:onAIFieldWorkerEnd()
    for _, wheel in ipairs(self.spec_wheels.wheels) do
        wheel.physics:setDisplacementAllowed(true)
        wheel.physics:setDisplacementCollisionEnabled(true)
    end
end
function Wheels:onAIImplementEnd()
    for _, wheel in ipairs(self.spec_wheels.wheels) do
        wheel.physics:setDisplacementAllowed(true)
        wheel.physics:setDisplacementCollisionEnabled(true)
    end
end
function Wheels:getWheelSuspensionModfier()
    local spec = self.spec_wheels
    local numWheels = #spec.wheels
    if numWheels <= 0 then
        return 0
    end
    local totalDelta = 0
    for _, wheel in ipairs(spec.wheels) do

    end
    local maxDelta = 0
    for _, wheel in ipairs(spec.wheels) do
        maxDelta = math.max(math.abs(totalDelta / numWheels - (wheel.physics.deltaY - wheel.physics.netInfo.suspensionLength)), maxDelta)
    end
    return maxDelta
end
g_soundManager:registerModifierType("WHEEL_SUSPENSION", Wheels.getWheelSuspensionModfier)
function Wheels.getTireNames(instance)
    local spec = instance.spec_wheels
    if spec == nil then
        return nil
    else
        local tireNames = {}
        for _, wheel in ipairs(spec.wheels) do
            if wheel.name ~= nil then
                tireNames[wheel.name] = true
            end
        end
        for _, wheel in ipairs(spec.dynamicallyLoadedWheels) do
            if wheel.name ~= nil then
                tireNames[wheel.name] = true
            end
        end
        if table.size(tireNames) == 0 then
            return nil
        else
            return tireNames
        end
    end
end
function Wheels.getBrands(items)
    local brands = {}
    for _, item in ipairs(items) do
        if item.isSelectable ~= false and (item.wheelBrandName ~= nil and ({})[item.wheelBrandName] == nil) then
            table.insert(brands, {
                ["title"] = item.wheelBrandName,
                ["icon"] = item.wheelBrandIconFilename
            })
            addedBrands[item.wheelBrandName] = true
        end
    end
    return brands
end
function Wheels.getWheelsByBrand(items, brand)
    local wheels = {}
    for _, item in ipairs(items) do
        if item.isSelectable ~= false and item.wheelBrandName == brand.title then
            table.insert(wheels, item)
        end
    end
    return wheels
end
function Wheels.loadSpecValueWheelWeight(xmlFile, _, _)
    local storeItem = g_storeManager:getItemByXMLFilename(xmlFile.filename)
    local configItem = nil
    if storeItem.configurations ~= nil then
        local configItems = storeItem.configurations.wheel
        if configItems ~= nil then
            for i, item in ipairs(configItems) do
                if item.isSelectable and item.isDefault then
                    configItem = item
                    break
                end
            end
            if configItem == nil then
                for i, item in ipairs(configItems) do
                    if item.isSelectable then
                        configItem = item
                        break
                    end
                end
            end
        end
    end
    local configItems = 0
    if configItem ~= nil then
        configItem:applyGeneratedConfiguration(xmlFile)
        local configurationIndexToParentConfigIndex = Wheels.createConfigToParentConfigMapping(xmlFile)
        xmlFile:iterate(configItem.configKey .. ".wheels.wheel", function(index, _)
            -- upvalues: (copy) xmlFile, (ref) configItem, (copy) configurationIndexToParentConfigIndex, (ref) configItems
            local wheelKey = string.format(".wheels.wheel(%d)", index - 1)
            local wheeXMLObject = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", configItem.index, wheelKey, configurationIndexToParentConfigIndex)
            wheeXMLObject:setXMLLoadKey("")
            local mass = wheeXMLObject:cacheWheelMass()
            wheeXMLObject:delete()
        end)
    end
    return configItems
end
function Wheels.loadSpecValueWheels(xmlFile, customEnvironment, baseDir)
    return nil
end
function Wheels.getSpecValueWheels(_, realItem)
    if realItem == nil then
        return nil
    else
        local tireNames = Wheels.getTireNames(realItem)
        if tireNames == nil then
            return nil
        else
            return table.concatKeys(tireNames, " / ")
        end
    end
end
function Wheels.getVRamUsageFromXML(xmlFile)
    if not xmlFile:hasProperty("vehicle.wheels") then
        return 0, 0
    end
    local defaultConfigIndex = 0
    xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function(configIndex, wheelConfigKey)
        -- upvalues: (copy) xmlFile, (ref) defaultConfigIndex
        if xmlFile:getValue(wheelConfigKey .. "#isDefault") then
            defaultConfigIndex = configIndex
            return false
        end
    end)
    local defaultConfigKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", defaultConfigIndex)
    local visualWheelCount = 0
    local usedWheels = {}
    xmlFile:iterate(defaultConfigKey .. ".wheels.wheel", function(_, key)
        -- upvalues: (copy) xmlFile, (copy) usedWheels, (ref) visualWheelCount
        local filename = xmlFile:getString(key .. "#filename")
        if filename ~= nil and usedWheels[filename] == nil then
            usedWheels[filename] = true
        end
    end)
    return visualWheelCount * Wheels.VRAM_PER_WHEEL, 0
end
function Wheels.createConfigToParentConfigMapping(xmlFile)
    local configurationSaveIdToIndex = {}
    local configurationIndexToParentConfigIndex = {}
    xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function(index, key)
        -- upvalues: (copy) xmlFile, (copy) configurationSaveIdToIndex
        configurationSaveIdToIndex[xmlFile:getValue(key .. "#saveId", (tostring(index)))] = index
    end)
    xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function(index, key)
        -- upvalues: (copy) xmlFile, (copy) configurationSaveIdToIndex, (copy) configurationIndexToParentConfigIndex
        XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".wheels.foliageBendingModifier", key .. ".foliageBendingModifier")
        local baseConfigId = xmlFile:getValue(key .. ".wheels#baseConfig")
        if baseConfigId ~= nil then
            local baseIndex = configurationSaveIdToIndex[baseConfigId]
            if index == baseIndex then
                Logging.xmlError(xmlFile, "Wheel configuration %s references itself as baseConfig! Ignoring this reference", key)
                return
            end
            configurationIndexToParentConfigIndex[index] = baseIndex
        end
    end)
    return configurationIndexToParentConfigIndex
end