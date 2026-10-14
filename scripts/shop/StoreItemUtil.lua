StoreItemUtil = {}
function StoreItemUtil.getIsVehicle(storeItem)
    return storeItem ~= nil and storeItem.species == StoreSpecies.VEHICLE
end
function StoreItemUtil.getIsAnimal(storeItem)
    return storeItem ~= nil and storeItem.species == StoreSpecies.ANIMAL
end
function StoreItemUtil.getIsPlaceable(storeItem)
    return storeItem ~= nil and storeItem.species == StoreSpecies.PLACEABLE
end
function StoreItemUtil.getIsObject(storeItem)
    return storeItem ~= nil and storeItem.species == StoreSpecies.OBJECT
end
function StoreItemUtil.getIsHandTool(storeItem)
    return storeItem ~= nil and storeItem.species == StoreSpecies.HANDTOOL
end
function StoreItemUtil.getIsConfigurable(storeItem)
    local hasConfigurations = false
    if storeItem ~= nil then
        hasConfigurations = storeItem.configurations ~= nil
    end
    local hasMoreThanOneOption = false
    if hasConfigurations then
        for _, configItems in pairs(storeItem.configurations) do
            local selectableItems = 0
            local i = 1
            for i = i, #configItems do
                if configItems[i].isSelectable ~= false then
                    selectableItems = selectableItems + 1
                    if selectableItems > 1 then
                        hasMoreThanOneOption = true
                        break
                    end
                end
            end
            if hasMoreThanOneOption then
                break
            end
        end
    end
    return hasConfigurations and hasMoreThanOneOption
end
function StoreItemUtil.getCanBeShownInConfigScreen(storeItem)
    return not StoreItemUtil.getIsHandTool(storeItem)
end
function StoreItemUtil.getIsLeasable(storeItem)
    return storeItem ~= nil and storeItem.allowLeasing and storeItem.runningLeasingFactor ~= nil and not StoreItemUtil.getIsPlaceable(storeItem)
end
function StoreItemUtil.getDefaultConfigId(storeItem, configurationName)
    return ConfigurationUtil.getDefaultConfigIdFromItems(storeItem.configurations[configurationName])
end
function StoreItemUtil.getDefaultPrice(storeItem, configurations)
    return StoreItemUtil.getCosts(storeItem, configurations, "price")
end
function StoreItemUtil.getDailyUpkeep(storeItem, configurations)
    return StoreItemUtil.getCosts(storeItem, configurations, "dailyUpkeep")
end
function StoreItemUtil.getCosts(storeItem, configurations, costType)
    if storeItem == nil then
        return 0
    end
    local costs = storeItem[costType]
    local costs = costs == nil and 0 or costs
    if storeItem.configurations ~= nil then
        for name, value in pairs(configurations) do
            local nameConfig = storeItem.configurations[name]
            if nameConfig ~= nil then
                local valueConfig = nameConfig[value]
                if valueConfig ~= nil then
                    local costTypeConfig = valueConfig[costType]
                    if costTypeConfig ~= nil then
                        costs = costs + tonumber(costTypeConfig)
                    end
                end
            end
        end
    end
    return costs
end
function StoreItemUtil.getPriceWithBoughtConfigurations(storeItem, boughtConfigurations, costType)
    if storeItem == nil then
        return 0
    end
    local costs = storeItem[costType]
    local costs = costs == nil and 0 or costs
    if storeItem.configurations ~= nil then
        for name, values in pairs(boughtConfigurations) do
            for value, check in pairs(values) do
                if check then
                    local nameConfig = storeItem.configurations[name]
                    if nameConfig ~= nil then
                        local valueConfig = nameConfig[value]
                        if valueConfig ~= nil then
                            local costTypeConfig = valueConfig[costType]
                            if costTypeConfig ~= nil then
                                costs = costs + tonumber(costTypeConfig)
                            end
                        end
                    end
                end
            end
        end
    end
    return costs
end
function StoreItemUtil.getFunctionsFromXML(xmlFile, storeDataXMLName, customEnvironment)
    local functions = nil
    for functionIndex, functionKey in xmlFile:iterator(storeDataXMLName .. ".functions.function") do
        local functionName = xmlFile:getValue(functionKey, nil, customEnvironment, true)
        if functionName ~= nil then
            functions = functions or {}
            table.insert(functions, functionName)
        end
    end
    return functions
end
function StoreItemUtil.loadSpecsFromXML(item)
    if item.specs == nil then
        local storeItemXmlFile = XMLFile.load("storeItemXML", item.xmlFilename, item.xmlSchema)
        if storeItemXmlFile ~= nil then
            item.specs = StoreItemUtil.getSpecsFromXML(g_storeManager:getSpecTypes(), item.species, storeItemXmlFile, item.customEnvironment, item.baseDir)
            storeItemXmlFile:delete()
        end
    end
    if item.bundleInfo ~= nil then
        local storeItemXmlFile = item.bundleInfo.bundleItems
        local i = 1
        for i = i, #storeItemXmlFile do
            StoreItemUtil.loadSpecsFromXML(storeItemXmlFile[i].item)
        end
    end
end
function StoreItemUtil.getSpecsFromXML(specTypes, species, xmlFile, customEnvironment, baseDirectory)
    local specs = {}
    for _, specType in ipairs(specTypes) do
        if specType.species == species and specType.loadFunc ~= nil then
            specs[specType.name] = specType.loadFunc(xmlFile, customEnvironment, baseDirectory)
        end
    end
    return specs
end
function StoreItemUtil.getBrandIndexFromXML(xmlFile, storeDataXMLKey)
    local brandName = xmlFile:getValue(storeDataXMLKey .. ".brand", "")
    return g_brandManager:getBrandIndexByName(brandName)
end
function StoreItemUtil.getVRamUsageFromXML(xmlFile, storeDataXMLName)
    local vertexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".vertexBufferMemoryUsage", 0)
    local indexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".indexBufferMemoryUsage", 0)
    local textureMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".textureMemoryUsage", 0)
    local instanceVertexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".instanceVertexBufferMemoryUsage", 0)
    local instanceIndexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".instanceIndexBufferMemoryUsage", 0)
    local ignoreVramUsage = xmlFile:getValue(storeDataXMLName .. ".ignoreVramUsage", false)
    return vertexBufferMemoryUsage + indexBufferMemoryUsage + textureMemoryUsage, instanceVertexBufferMemoryUsage + instanceIndexBufferMemoryUsage, ignoreVramUsage
end
function StoreItemUtil.getSubConfigurationIndex(storeItem, configName, configIndex)
    local subConfigurations = storeItem.subConfigurations[configName]
    for k, identifier in ipairs(subConfigurations.subConfigValues) do
        for _, item in ipairs(subConfigurations.subConfigItemMapping[identifier]) do
            if item.index == configIndex then
                return k
            end
        end
    end
    return nil
end
function StoreItemUtil.getSubConfigurationItems(storeItem, configName, state)
    local subConfigurations = storeItem.subConfigurations[configName]
    return subConfigurations.subConfigItemMapping[subConfigurations.subConfigValues[state]]
end
function StoreItemUtil.getSizeValues(xmlFilename, baseName, rotationOffset, configurations)
    local xmlFile = XMLFile.load("storeItemGetSizeXml", xmlFilename, Vehicle.xmlSchema)
    local size = {
        ["width"] = Vehicle.defaultWidth,
        ["length"] = Vehicle.defaultLength,
        ["height"] = Vehicle.defaultHeight,
        ["widthOffset"] = 0,
        ["lengthOffset"] = 0,
        ["heightOffset"] = 0
    }
    if xmlFile ~= nil then
        size = StoreItemUtil.getSizeValuesFromXML(xmlFilename, xmlFile, baseName, rotationOffset, configurations)
        xmlFile:delete()
    end
    return size
end
function StoreItemUtil.getSizeValuesFromXML(xmlFilename, xmlFile, baseName, rotationOffset, configurations)
    return StoreItemUtil.getSizeValuesFromXMLByKey(xmlFilename, xmlFile, baseName, "base", "size", "size", rotationOffset, configurations, Vehicle.DEFAULT_SIZE)
end
function StoreItemUtil.getSizeValuesFromXMLByKey(xmlFilename, xmlFile, baseName, baseKey, elementKey, _, rotationOffset, configurations, defaults)
    local baseSizeKey = string.format("%s.%s.%s", baseName, baseKey, elementKey)
    local size = {
        ["width"] = xmlFile:getValue(baseSizeKey .. "#width", defaults.width),
        ["length"] = xmlFile:getValue(baseSizeKey .. "#length", defaults.length),
        ["height"] = xmlFile:getValue(baseSizeKey .. "#height", defaults.height),
        ["widthOffset"] = xmlFile:getValue(baseSizeKey .. "#widthOffset", defaults.widthOffset),
        ["lengthOffset"] = xmlFile:getValue(baseSizeKey .. "#lengthOffset", defaults.lengthOffset),
        ["heightOffset"] = xmlFile:getValue(baseSizeKey .. "#heightOffset", defaults.heightOffset)
    }
    if configurations ~= nil then
        for name, id in pairs(configurations) do
            local configItem = ConfigurationUtil.getConfigItemByConfigId(xmlFilename, name, id)
            if configItem ~= nil and configItem.onSizeLoad ~= nil then
                configItem.onSizeLoad(configItem, xmlFile, size)
            end
        end
        if size.minWidth ~= nil then
            size.width = math.max(size.width, size.minWidth)
        end
        if size.minLength ~= nil then
            size.length = math.max(size.length, size.minLength)
        end
        if size.minHeight ~= nil then
            size.height = math.max(size.height, size.minHeight)
        end
    end
    rotationOffset = math.floor(rotationOffset / 1.5707963267948966 + 0.5) * 1.5707963267948966 % 6.283185307179586
    if rotationOffset < 0 then
    end
    local rotationIndex = math.floor(rotationOffset / 1.5707963267948966 + 0.5)
    if rotationIndex ~= 1 then
        if rotationIndex ~= 2 then
            if rotationIndex == 3 then
                size.width = size.length
                size.length = size.width
                size.widthOffset = -size.lengthOffset
                size.lengthOffset = size.widthOffset
            end
            return size
        end
        size.widthOffset = -size.widthOffset
        size.lengthOffset = -size.lengthOffset
        return size
    end
    size.width = size.length
    size.length = size.width
    size.widthOffset = size.lengthOffset
    size.lengthOffset = -size.widthOffset
    return size
end
function StoreItemUtil.registerConfigurationSetXMLPaths(schema, baseKey)
    baseKey = baseKey .. ".configurationSets"
    schema:register(XMLValueType.L10N_STRING, baseKey .. "#title", "Title to display in config screen")
    schema:register(XMLValueType.BOOL, baseKey .. "#isYesNoOption", "Defines if the configuration set is a yes/no option", false)
    local setKey = baseKey .. ".configurationSet(?)"
    schema:register(XMLValueType.L10N_STRING, setKey .. "#name", "Set name")
    schema:register(XMLValueType.STRING, setKey .. "#params", "Parameters to insert into name")
    schema:register(XMLValueType.BOOL, setKey .. "#isDefault", "Is default set")
    schema:register(XMLValueType.STRING, setKey .. ".configuration(?)#name", "Configuration name")
    schema:register(XMLValueType.INT, setKey .. ".configuration(?)#index", "Selected index")
    schema:register(XMLValueType.BOOL, setKey .. ".configuration(?)#showWarning", "Show warning if config is not available (e.g. config that is added via a mod like Precision Farming)", true)
end