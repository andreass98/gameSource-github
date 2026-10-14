ManureSensorLinkageData = {}
ManureSensorLinkageData.MOD_NAME = g_currentModName
ManureSensorLinkageData.BASE_DIRECTORY = g_currentModDirectory
ManureSensorLinkageData.xmlSchema = nil
local ManureSensorLinkageData_mt = Class(ManureSensorLinkageData)
function ManureSensorLinkageData.new(precisionFarming, customMt)
    -- upvalues: (copy) ManureSensorLinkageData_mt
    local self = setmetatable({}, customMt or ManureSensorLinkageData_mt)
    self.precisionFarming = precisionFarming
    self.configurationPrice = 0
    self.sensorData = {}
    self.linkageData = {}
    self.dataLoaded = false
    ManureSensorLinkageData.xmlSchema = XMLSchema.new("manureSensorLinkageData")
    self:registerXMLPaths(ManureSensorLinkageData.xmlSchema)
    return self
end
function ManureSensorLinkageData:delete()
    local i = 1
    for i = i, #self.sensorData do
        delete(self.sensorData[i].node)
    end
    self.sensorData = {}
    self.linkageData = {}
end
function ManureSensorLinkageData:loadFromXML(_, _, _, _, _)
    if not self.dataLoaded then
        self:loadLinkageData()
    end
end
function ManureSensorLinkageData:loadLinkageData(loadVehicleData, loadSensorData)
    local filename = Utils.getFilename("ManureSensorLinkageData.xml", ManureSensorLinkageData.BASE_DIRECTORY)
    local xmlFile = XMLFile.load("ManureSensorLinkageData", filename, ManureSensorLinkageData.xmlSchema)
    if xmlFile ~= nil then
        self.configurationPrice = xmlFile:getValue("manureSensorLinkageData.configuration#price", 0)
        if loadVehicleData ~= false then
            self.linkageData = {}
            xmlFile:iterate("manureSensorLinkageData.vehicles.vehicle", function(_, key)
                -- upvalues: (copy) xmlFile, (copy) self
                local vehicleData = {
                    ["filename"] = xmlFile:getValue(key .. "#filename")
                }
                if vehicleData.filename ~= nil then
                    vehicleData.linkNodes = {}
                    xmlFile:iterate(key .. ".linkNode", function(_, linkNodeKey)
                        -- upvalues: (ref) xmlFile, (copy) vehicleData
                        local linkNode = {
                            ["nodeName"] = xmlFile:getValue(linkNodeKey .. "#node"),
                            ["typeName"] = string.upper(xmlFile:getValue(linkNodeKey .. "#type", "DEFAULT")),
                            ["translation"] = xmlFile:getValue(linkNodeKey .. "#translation", "0 0 0", true),
                            ["rotation"] = xmlFile:getValue(linkNodeKey .. "#rotation", "0 0 0", true),
                            ["scale"] = xmlFile:getValue(linkNodeKey .. "#scale", nil, true)
                        }
                        table.insert(vehicleData.linkNodes, linkNode)
                    end)
                end
                table.insert(self.linkageData, vehicleData)
            end)
        end
        if loadSensorData == false then
            xmlFile:delete()
        else
            local sensorsFilename = xmlFile:getValue("manureSensorLinkageData.sensors#filename")
            if sensorsFilename == nil then
                xmlFile:delete()
            else
                local sensorsFilename = Utils.getFilename(sensorsFilename, ManureSensorLinkageData.BASE_DIRECTORY)
                g_i3DManager:loadI3DFileAsync(sensorsFilename, true, true, ManureSensorLinkageData.onSensorDataLoaded, self, { xmlFile })
            end
        end
    end
    self.dataLoaded = true
    return true
end
function ManureSensorLinkageData:onSensorDataLoaded(i3dNode, _, args)
    local xmlFile = unpack(args)
    if i3dNode ~= 0 then
        xmlFile:iterate("manureSensorLinkageData.sensors.sensor", function(_, key)
            -- upvalues: (copy) xmlFile, (copy) i3dNode, (copy) self
            local sensorData = {
                ["node"] = xmlFile:getValue(key .. "#node", nil, i3dNode)
            }
            if sensorData.node ~= nil then
                sensorData.type = xmlFile:getValue(key .. "#type", "DEFAULT")
                table.insert(self.sensorData, sensorData)
            end
        end)
        local i = 1
        for i = i, #self.sensorData do
            unlink(self.sensorData[i].node)
        end
        delete(i3dNode)
    end
    xmlFile:delete()
end
function ManureSensorLinkageData:getManureSensorLinkageData(configFileName)
    if configFileName ~= nil then
        local i = 1
        for i = i, #self.linkageData do
            local vehicleData = self.linkageData[i]
            if string.endsWith(configFileName, vehicleData.filename) then
                return vehicleData
            end
        end
    end
    return nil
end
function ManureSensorLinkageData:getClonedManureSensorNode(typeName)
    local i = 1
    for i = i, #self.sensorData do
        local sensorData = self.sensorData[i]
        if string.upper(sensorData.type) == string.upper(typeName) then
            local clonedData = table.clone(sensorData, 10)
            clonedData.node = clone(sensorData.node, false, false, false)
            setTranslation(clonedData.node, 0, 0, 0)
            setRotation(clonedData.node, 0, 0, 0)
            setScale(clonedData.node, 1, 1, 1)
            return clonedData
        end
    end
    return nil
end
function ManureSensorLinkageData:overwriteGameFunctions(pfModule)
    pfModule:overwriteGameFunction(VehicleSystem, "consoleCommandReloadVehicle", function(superFunc, vehicleSystem, resetVehicle, radius)
        -- upvalues: (copy) self
        self:loadLinkageData(true, false)
        return superFunc(vehicleSystem, resetVehicle, radius)
    end)
    pfModule:overwriteGameFunction(ConfigurationUtil, "getConfigurationsFromXML", function(superFunc, manager, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
        -- upvalues: (copy) self
        local configurations, defaultConfigurationIds = superFunc(manager, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
        if not self.dataLoaded then
            self:loadLinkageData(true)
        end
        if self:getManureSensorLinkageData(xmlFile.filename) ~= nil then
            configurations = configurations == nil and {} or configurations
            defaultConfigurationIds = defaultConfigurationIds == nil and {} or defaultConfigurationIds
            local configurationItems = {}
            local configItem1 = VehicleConfigurationItem.new("manureSensor")
            configItem1.isDefault = true
            configItem1.name = g_i18n:getText("configuration_valueNo")
            configItem1.index = 1
            configItem1.saveId = "1"
            configItem1.price = 0
            configItem1.isYesNoOption = true
            table.insert(configurationItems, configItem1)
            local configItem2 = VehicleConfigurationItem.new("manureSensor")
            configItem2.name = g_i18n:getText("configuration_valueYes")
            configItem2.index = 2
            configItem2.saveId = "2"
            configItem2.price = self.configurationPrice
            configItem2.isYesNoOption = true
            table.insert(configurationItems, configItem2)
            defaultConfigurationIds.manureSensor = ConfigurationUtil.getDefaultConfigIdFromItems(configurationItems)
            configurations.manureSensor = configurationItems
        end
        return configurations, defaultConfigurationIds
    end)
end
function ManureSensorLinkageData.registerXMLPaths(_, schema)
    schema:register(XMLValueType.STRING, "manureSensorLinkageData.sensors#filename", "Link to i3d filename containing the sensors")
    schema:register(XMLValueType.STRING, "manureSensorLinkageData.sensors.sensor(?)#type", "Type of sensor (DEFAULT)")
    schema:register(XMLValueType.NODE_INDEX, "manureSensorLinkageData.sensors.sensor(?)#node", "Path to sensor node")
    schema:register(XMLValueType.STRING, "manureSensorLinkageData.vehicles.vehicle(?)#filename", "Last part of vehicle filename")
    schema:register(XMLValueType.STRING, "manureSensorLinkageData.vehicles.vehicle(?).linkNode(?)#node", "Name of node in i3d mapping")
    schema:register(XMLValueType.STRING, "manureSensorLinkageData.vehicles.vehicle(?).linkNode(?)#type", "Type of node to link (DEFAULT)")
    schema:register(XMLValueType.VECTOR_TRANS, "manureSensorLinkageData.vehicles.vehicle(?).linkNode(?)#translation", "Translation offset from node", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, "manureSensorLinkageData.vehicles.vehicle(?).linkNode(?)#rotation", "Rotation offset from node", "0 0 0")
    schema:register(XMLValueType.VECTOR_SCALE, "manureSensorLinkageData.vehicles.vehicle(?).linkNode(?)#scale", "Scale of sensor node", "1 1 1")
    schema:register(XMLValueType.FLOAT, "manureSensorLinkageData.configuration#price", "Price of crop sensor config", 0)
end