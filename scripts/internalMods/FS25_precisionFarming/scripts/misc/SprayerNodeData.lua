SprayerNodeData = {}
SprayerNodeData.MOD_NAME = g_currentModName
SprayerNodeData.BASE_DIRECTORY = g_currentModDirectory
SprayerNodeData.xmlSchema = nil
SprayerNodeData.SPRAYER_NOZZLE_EFFECT_FILENAME = g_currentModDirectory .. "shared/sprayerNozzleEffect.i3d"
local SprayerNodeData_mt = Class(SprayerNodeData)
function SprayerNodeData.new(precisionFarming, customMt)
    -- upvalues: (copy) SprayerNodeData_mt
    local self = setmetatable({}, customMt or SprayerNodeData_mt)
    self.precisionFarming = precisionFarming
    self.linkageData = {}
    self.sensorTypes = {}
    self.dataLoaded = false
    self.priceWeedSpotSpray = 0
    self.priceSeeAndSpray = 0
    self.pricePulseWidthModulation = 0
    SprayerNodeData.xmlSchema = XMLSchema.new("sprayerNodeData")
    self:registerXMLPaths(SprayerNodeData.xmlSchema)
    return self
end
function SprayerNodeData:delete()
    if self.sprayerEffectNode ~= nil then
        delete(self.sprayerEffectNode)
        self.sprayerEffectNode = nil
    end
    for _, sensorType in ipairs(self.sensorTypes) do
        if sensorType.node ~= nil then
            delete(sensorType.node)
            sensorType.node = nil
        end
        if sensorType.sharedLoadRequestId ~= nil then
            g_i3DManager:releaseSharedI3DFile(sensorType.sharedLoadRequestId)
            sensorType.sharedLoadRequestId = nil
        end
    end
    if self.samples ~= nil then
        g_soundManager:deleteSamples(self.samples)
    end
    self.linkageData = {}
end
function SprayerNodeData:loadFromXML(_, _, _, _, _)
    if not self.dataLoaded then
        self:loadData()
    end
end
function SprayerNodeData:getConfigPrices()
    return self.priceWeedSpotSpray, self.priceSeeAndSpray, self.pricePulseWidthModulation
end
function SprayerNodeData:getClonedSectionSamples(name, linkNode, modifierTargetObject)
    local sample = self.samples[name]
    if sample ~= nil then
        return g_soundManager:cloneSample(sample, linkNode, modifierTargetObject)
    end
    Logging.warning("Missing sample \'%s\' in SprayerNodeData", name)
    return nil
end
function SprayerNodeData:loadData(loadVehicleData, loadEffect)
    if loadEffect ~= false then
        g_i3DManager:loadI3DFileAsync(SprayerNodeData.SPRAYER_NOZZLE_EFFECT_FILENAME, true, true, SprayerNodeData.onSprayerEffectLoaded, self, {})
    end
    local filename = Utils.getFilename("SprayerNodeData.xml", SprayerNodeData.BASE_DIRECTORY)
    local xmlFile = XMLFile.load("SprayerNodeData", filename, SprayerNodeData.xmlSchema)
    if xmlFile ~= nil then
        self.priceWeedSpotSpray = xmlFile:getValue("sprayerNodeData.configuration#priceWeedSpotSpray", 1000)
        self.priceSeeAndSpray = xmlFile:getValue("sprayerNodeData.configuration#priceSeeAndSpray", 1000)
        self.pricePulseWidthModulation = xmlFile:getValue("sprayerNodeData.configuration#pricePulseWidthModulation", 1000)
        local linkNode = getRootNode()
        self.samples = {}
        self.samples.spray = g_soundManager:loadSampleFromXML(xmlFile, "sprayerNodeData.sounds", "spray", SprayerNodeData.BASE_DIRECTORY, linkNode, 0, AudioGroup.VEHICLE, nil, self)
        if loadEffect ~= false then
            xmlFile:iterate("sprayerNodeData.sensorTypes.sensorType", function(_, key)
                -- upvalues: (copy) xmlFile, (copy) self
                local sensorType = {
                    ["id"] = xmlFile:getValue(key .. "#id"),
                    ["filename"] = xmlFile:getValue(key .. "#filename", nil, SprayerNodeData.BASE_DIRECTORY),
                    ["nodePath"] = xmlFile:getValue(key .. "#node"),
                    ["hasBracket"] = xmlFile:getValue(key .. "#hasBracket", false)
                }
                if sensorType.id == nil or sensorType.filename == nil then
                    Logging.xmlWarning(xmlFile, "Missing sensor type id or filename in \'%s\'", key)
                else
                    sensorType.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(sensorType.filename, true, true, SprayerNodeData.onWeedSensorLoaded, self, sensorType)
                end
            end)
        end
        if loadVehicleData ~= false then
            self.linkageData = {}
            xmlFile:iterate("sprayerNodeData.vehicles.vehicle", function(_, key)
                -- upvalues: (copy) xmlFile, (copy) self
                local vehicleData = {
                    ["filename"] = xmlFile:getValue(key .. "#filename")
                }
                if vehicleData.filename ~= nil then
                    vehicleData.configurationName = xmlFile:getValue(key .. "#configurationName", "variableWorkWidth")
                    vehicleData.configurations = {}
                    for _, configKey in xmlFile:iterator(key .. ".configuration") do
                        local configurationData = {
                            ["effectNodes"] = {}
                        }
                        for _, effectNodeKey in xmlFile:iterator(configKey .. ".effectNode") do
                            local effectNode = {
                                ["nodeName"] = xmlFile:getValue(effectNodeKey .. "#node"),
                                ["translation"] = xmlFile:getValue(effectNodeKey .. "#translation", "0 0 0", true),
                                ["rotation"] = xmlFile:getValue(effectNodeKey .. "#rotation", "0 0 0", true)
                            }
                            table.insert(configurationData.effectNodes, effectNode)
                        end
                        configurationData.sensorNodes = {}
                        for _, effectNodeKey in xmlFile:iterator(configKey .. ".sensorNode") do
                            local effectNode = {
                                ["id"] = xmlFile:getValue(effectNodeKey .. "#id"),
                                ["nodeName"] = xmlFile:getValue(effectNodeKey .. "#node"),
                                ["translation"] = xmlFile:getValue(effectNodeKey .. "#translation", "0 0 0", true),
                                ["rotation"] = xmlFile:getValue(effectNodeKey .. "#rotation", "0 0 0", true),
                                ["bracketSize"] = xmlFile:getValue(effectNodeKey .. "#bracketSize", 1)
                            }
                            table.insert(configurationData.sensorNodes, effectNode)
                        end
                        if #configurationData.effectNodes > 0 or #configurationData.sensorNodes > 0 then
                            table.insert(vehicleData.configurations, configurationData)
                        end
                    end
                end
                table.insert(self.linkageData, vehicleData)
            end)
        end
        xmlFile:delete()
    end
    self.dataLoaded = true
    return true
end
function SprayerNodeData:onSprayerEffectLoaded(i3dNode, _, _)
    if i3dNode ~= 0 then
        self.sprayerEffectNode = getChildAt(i3dNode, 0)
        unlink(self.sprayerEffectNode)
        delete(i3dNode)
    end
end
function SprayerNodeData:onWeedSensorLoaded(i3dNode, _, sensorType)
    if i3dNode ~= 0 then
        sensorType.node = I3DUtil.indexToObject(i3dNode, sensorType.nodePath)
        if sensorType.node ~= nil then
            setTranslation(sensorType.node, 0, 0, 0)
            setRotation(sensorType.node, 0, 0, 0)
            unlink(sensorType.node)
            table.insert(self.sensorTypes, sensorType)
        end
        delete(i3dNode)
    end
end
function SprayerNodeData:getClonedSprayerEffectNode()
    if self.sprayerEffectNode == nil then
        return nil
    end
    local effectNode = clone(self.sprayerEffectNode, false, false, false)
    local material = g_materialManager:getMaterial(FillType.LIQUIDFERTILIZER, "sprayer", 1)
    if material ~= nil then
        setMaterial(effectNode, material, 0)
    end
    return effectNode
end
function SprayerNodeData:getClonedSprayerWeedSensorNode(sensorTypeId)
    for _, sensorType in ipairs(self.sensorTypes) do
        if sensorType.id == sensorTypeId and sensorType.node ~= nil then
            return clone(sensorType.node, false, false, false), sensorType.hasBracket
        end
    end
    return nil, false
end
function SprayerNodeData:getSprayerNodeData(configFileName, configurations)
    if configFileName ~= nil then
        local i = 1
        for i = i, #self.linkageData do
            local vehicleData = self.linkageData[i]
            if string.endsWith(configFileName, vehicleData.filename) then
                if configurations == nil then
                    return vehicleData.configurations[1], vehicleData
                else
                    local configId = configurations[vehicleData.configurationName]
                    if configId == nil then
                        return vehicleData.configurations[1], vehicleData
                    else
                        return vehicleData.configurations[configId], vehicleData
                    end
                end
            end
        end
    end
    return nil
end
function SprayerNodeData:overwriteGameFunctions(pfModule)
    pfModule:overwriteGameFunction(VehicleSystem, "consoleCommandReloadVehicle", function(superFunc, vehicleSystem, resetVehicle, radius)
        -- upvalues: (copy) self
        self:loadData(true, false)
        return superFunc(vehicleSystem, resetVehicle, radius)
    end)
    pfModule:overwriteGameFunction(ConfigurationUtil, "getConfigurationsFromXML", function(superFunc, manager, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
        -- upvalues: (copy) self
        local configurations, defaultConfigurationIds = superFunc(manager, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
        if not self.dataLoaded then
            self:loadData()
        end
        local _, vehicleData = self:getSprayerNodeData(xmlFile.filename)
        if vehicleData ~= nil then
            configurations = configurations == nil and {} or configurations
            defaultConfigurationIds = defaultConfigurationIds == nil and {} or defaultConfigurationIds
            if configurations.weedSpotSpray == nil then
                local configurationItems = {}
                local configItem1 = VehicleConfigurationItem.new("weedSpotSpray")
                configItem1.isDefault = true
                configItem1.name = g_i18n:getText("configuration_valueNo")
                configItem1.index = 1
                configItem1.saveId = "1"
                configItem1.price = 0
                configItem1.isYesNoOption = true
                table.insert(configurationItems, configItem1)
                local configItem2 = VehicleConfigurationItem.new("weedSpotSpray")
                configItem2.name = g_i18n:getText("configuration_valueYes")
                configItem2.index = 2
                configItem2.saveId = "2"
                configItem2.price = 1
                configItem2.isYesNoOption = true
                configItem2.overwrittenTitle = "PTx Trimble - WeedSeeker\194\174 2"
                table.insert(configurationItems, configItem2)
                defaultConfigurationIds.weedSpotSpray = ConfigurationUtil.getDefaultConfigIdFromItems(configurationItems)
                configurations.weedSpotSpray = configurationItems
            end
            if configurations.pulseWidthModulation == nil then
                local configurationItems = {}
                local configItem1 = VehicleConfigurationItem.new("pulseWidthModulation")
                configItem1.isDefault = true
                configItem1.name = g_i18n:getText("configuration_valueNo")
                configItem1.index = 1
                configItem1.saveId = "1"
                configItem1.price = 0
                configItem1.isYesNoOption = true
                table.insert(configurationItems, configItem1)
                local configItem2 = VehicleConfigurationItem.new("pulseWidthModulation")
                configItem2.name = g_i18n:getText("configuration_valueYes")
                configItem2.index = 2
                configItem2.saveId = "2"
                configItem2.price = 1
                configItem2.isYesNoOption = true
                table.insert(configurationItems, configItem2)
                defaultConfigurationIds.pulseWidthModulation = ConfigurationUtil.getDefaultConfigIdFromItems(configurationItems)
                configurations.pulseWidthModulation = configurationItems
            end
        end
        return configurations, defaultConfigurationIds
    end)
end
function SprayerNodeData.registerXMLPaths(_, schema)
    schema:register(XMLValueType.INT, "sprayerNodeData.configuration#priceWeedSpotSpray", "Default spot spray config price per meter")
    schema:register(XMLValueType.INT, "sprayerNodeData.configuration#priceSeeAndSpray", "Default spot spray config price per meter (JD See & Spray)")
    schema:register(XMLValueType.INT, "sprayerNodeData.configuration#pricePulseWidthModulation", "Default pulse width modulation config price per meter")
    SoundManager.registerSampleXMLPaths(schema, "sprayerNodeData.sounds", "spray")
    schema:register(XMLValueType.STRING, "sprayerNodeData.vehicles.vehicle(?)#filename", "Last part of vehicle filename")
    schema:register(XMLValueType.STRING, "sprayerNodeData.vehicles.vehicle(?)#configurationName", "Name of configuration", "variableWorkWidth")
    schema:register(XMLValueType.STRING, "sprayerNodeData.vehicles.vehicle(?).configuration(?).effectNode(?)#node", "Name of node in i3d mapping")
    schema:register(XMLValueType.VECTOR_TRANS, "sprayerNodeData.vehicles.vehicle(?).configuration(?).effectNode(?)#translation", "Translation offset from node", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, "sprayerNodeData.vehicles.vehicle(?).configuration(?).effectNode(?)#rotation", "Rotation offset from node", "0 0 0")
    schema:register(XMLValueType.STRING, "sprayerNodeData.sensorTypes.sensorType(?)#id", "Sensor identifier")
    schema:register(XMLValueType.FILENAME, "sprayerNodeData.sensorTypes.sensorType(?)#filename", "Path to the sensor i3d file")
    schema:register(XMLValueType.STRING, "sprayerNodeData.sensorTypes.sensorType(?)#node", "Path to the node in the i3d file")
    schema:register(XMLValueType.BOOL, "sprayerNodeData.sensorTypes.sensorType(?)#hasBracket", "Defines if the first child node is a scaleable bracket", false)
    schema:register(XMLValueType.STRING, "sprayerNodeData.vehicles.vehicle(?).configuration(?).sensorNode(?)#id", "Sensor identifier of the type to use")
    schema:register(XMLValueType.STRING, "sprayerNodeData.vehicles.vehicle(?).configuration(?).sensorNode(?)#node", "Name of node in i3d mapping")
    schema:register(XMLValueType.VECTOR_TRANS, "sprayerNodeData.vehicles.vehicle(?).configuration(?).sensorNode(?)#translation", "Translation offset from node", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, "sprayerNodeData.vehicles.vehicle(?).configuration(?).sensorNode(?)#rotation", "Rotation offset from node", "0 0 0")
    schema:register(XMLValueType.FLOAT, "sprayerNodeData.vehicles.vehicle(?).configuration(?).sensorNode(?)#bracketSize", "Size of the bracket", 1)
end