VehicleConfigurationDataDependentConfig = {}
function VehicleConfigurationDataDependentConfig.registerXMLPaths(schema, _, configPath)
    schema:register(XMLValueType.STRING, configPath .. ".dependentConfiguration(?)#name", "Name of the other configuration to set")
    schema:register(XMLValueType.INT, configPath .. ".dependentConfiguration(?)#index", "Index of the configuration to use")
end
function VehicleConfigurationDataDependentConfig.loadConfigItem(configItem, xmlFile, _, configKey, _, _)
    configItem.dependentConfigurations = {}
    for _, key in xmlFile:iterator(configKey .. ".dependentConfiguration") do
        local dependentConfiguration = {
            ["name"] = xmlFile:getValue(key .. "#name"),
            ["index"] = xmlFile:getValue(key .. "#index")
        }
        if dependentConfiguration.name ~= nil and dependentConfiguration.index ~= nil then
            table.insert(configItem.dependentConfigurations, dependentConfiguration)
        end
    end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataDependentConfig)