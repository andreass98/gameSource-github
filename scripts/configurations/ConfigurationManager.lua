ConfigurationManager = {}
local ConfigurationManager_mt = Class(ConfigurationManager, AbstractManager)
function ConfigurationManager.new(typeName, rootElementName, customMt)
    -- upvalues: (copy) ConfigurationManager_mt
    local self = AbstractManager.new(customMt or ConfigurationManager_mt)
    self.typeName = typeName
    self.rootElementName = rootElementName
    self:initDataStructures()
    return self
end
function ConfigurationManager:initDataStructures()
    self.configurations = {}
    self.intToConfigurationName = {}
    self.configurationNameToInt = {}
    self.sortedConfigurationNames = {}
end
function ConfigurationManager:addConfigurationType(name, title, xmlKey, itemClass, subConfigurationTitle, getSubConfigurationValuesFunc, getItemsBySubConfigurationIdentifierFunc, priority)
    if self.configurations[name] == nil then
        if self:getNumOfConfigurationTypes() >= 2 ^ ConfigurationUtil.SEND_NUM_BITS then
            printError("Error: ConfigurationManager.addConfigurationType too many configuration types. Only " .. 2 ^ ConfigurationUtil.SEND_NUM_BITS .. " configuration types are supported")
            return
        elseif itemClass == nil then
            Logging.error("Missing \'itemClass\' for configuration \'%s\'. (\'addConfigurationType\' function arguments: name, title, xmlKey, itemClass, subConfigurationTitle, getSubConfigurationValuesFunc, getItemsBySubConfigurationIdentifierFunc, priority)", name)
            printCallstack()
        else
            local entry = {
                ["name"] = name,
                ["xmlKey"] = xmlKey,
                ["title"] = title,
                ["itemClass"] = itemClass,
                ["subConfigurationTitle"] = subConfigurationTitle,
                ["getSubConfigurationValuesFunc"] = getSubConfigurationValuesFunc,
                ["getItemsBySubConfigurationIdentifierFunc"] = getItemsBySubConfigurationIdentifierFunc
            }
            entry.hasSubselection = getSubConfigurationValuesFunc ~= nil
            entry.priority = priority or #self.intToConfigurationName + 1000
            if entry.xmlKey == nil then
                entry.configurationsKey = string.format("%s.%sConfigurations", self.rootElementName, name)
            else
                entry.configurationsKey = string.format("%s.%s.%sConfigurations", self.rootElementName, xmlKey, name)
            end
            entry.configurationKey = string.format("%s.%sConfiguration", entry.configurationsKey, name)
            self.configurations[name] = entry
            table.insert(self.intToConfigurationName, name)
            self.configurationNameToInt[name] = self:getNumOfConfigurationTypes()
            table.insert(self.sortedConfigurationNames, name)
            table.sort(self.sortedConfigurationNames, function(a, b)
                -- upvalues: (copy) self
                return self.configurations[a].priority < self.configurations[b].priority
            end)
            print("  Register configuration \'" .. name .. "\'")
        end
    else
        printError("Error: configuration name \'" .. name .. "\' is already in use!")
        return
    end
end
function ConfigurationManager:getNumOfConfigurationTypes()
    return #self.intToConfigurationName
end
function ConfigurationManager:getConfigurationTypes()
    return self.intToConfigurationName
end
function ConfigurationManager:getSortedConfigurationTypes()
    return self.sortedConfigurationNames
end
function ConfigurationManager:getConfigurationNameByIndex(index)
    return self.intToConfigurationName[index]
end
function ConfigurationManager:getConfigurationIndexByName(name)
    return self.configurationNameToInt[name]
end
function ConfigurationManager:getConfigurations()
    return self.configurations
end
function ConfigurationManager:getConfigurationDescByName(name)
    return self.configurations[name]
end
function ConfigurationManager:getConfigurationAttribute(configurationName, attribute)
    return self:getConfigurationDescByName(configurationName)[attribute]
end
function ConfigurationManager:getConfigurationSelectorType(configurationName)
    local config = self:getConfigurationDescByName(configurationName)
    if config == nil then
        return ConfigurationUtil.SELECTOR_MULTIOPTION
    else
        return config.itemClass.SELECTOR
    end
end
function ConfigurationManager:getConfigurationKeys(configurationName)
    local config = self:getConfigurationDescByName(configurationName)
    if config == nil then
        return nil, nil
    else
        return config.configurationsKey, config.configurationKey
    end
end
function ConfigurationManager:configurationKeyIterator()
    local currentIndex = 0
    local numElements = #self.intToConfigurationName
    return function()
        -- upvalues: (ref) currentIndex, (copy) numElements, (copy) self
        if numElements <= currentIndex then
            return nil
        end
        currentIndex = currentIndex + 1
        local configurationsKey, configurationKey = self:getConfigurationKeys(self.intToConfigurationName[currentIndex])
        return configurationsKey, configurationKey .. "(?)"
    end
end
g_vehicleConfigurationManager = ConfigurationManager.new("vehicle", "vehicle")
g_placeableConfigurationManager = ConfigurationManager.new("placeable", "placeable")
g_configurationManager = {
    ["addConfigurationType"] = function()
        Logging.error("g_configurationManager is not available anymore. Please adjust mod script to use new g_vehicleConfigurationManager and VehicleConfigurationItems instead")
    end,
    ["getConfigurationDescByName"] = function()
        Logging.error("g_configurationManager is not available anymore. Please adjust mod script to use new g_vehicleConfigurationManager and VehicleConfigurationItems instead")
        return nil
    end,
    ["configurations"] = {}
}