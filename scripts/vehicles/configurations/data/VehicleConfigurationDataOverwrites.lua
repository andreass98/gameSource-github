VehicleConfigurationDataOverwrites = {}
function VehicleConfigurationDataOverwrites.registerXMLPaths(schema, _, configPath)
    schema:register(XMLValueType.STRING, configPath .. ".xmlOverwrites.remove(?)#path", "Path to remove from parent xml")
    schema:register(XMLValueType.STRING, configPath .. ".xmlOverwrites.set(?)#path", "Path change in parent xml")
    schema:register(XMLValueType.STRING, configPath .. ".xmlOverwrites.set(?)#value", "Target value to set in parent file")
    schema:register(XMLValueType.STRING, configPath .. ".xmlOverwrites.clearList(?)#path", "List to clear but keep one item")
    schema:register(XMLValueType.INT, configPath .. ".xmlOverwrites.clearList(?)#keepIndex", "Index of list to keep")
end
function VehicleConfigurationDataOverwrites.onPreLoad(vehicle, configItem, _)
    local xmlFile = vehicle.xmlFile
    local configKey = configItem.configKey
    if configKey ~= "" then
        xmlFile:iterate(configKey .. ".xmlOverwrites.remove", function(_, key)
            -- upvalues: (copy) xmlFile
            xmlFile:removeProperty((xmlFile:getString(key .. "#path")))
        end)
        xmlFile:iterate(configKey .. ".xmlOverwrites.set", function(_, key)
            -- upvalues: (copy) xmlFile
            xmlFile:setString(xmlFile:getString(key .. "#path"), (xmlFile:getString(key .. "#value")))
        end)
        xmlFile:iterate(configKey .. ".xmlOverwrites.clearList", function(_, key)
            -- upvalues: (copy) xmlFile
            local attributePath = xmlFile:getString(key .. "#path")
            local keepIndex = xmlFile:getInt(key .. "#keepIndex")
            local numItems = 0
            while xmlFile:hasProperty(string.format(attributePath .. "(%d)", numItems)) do
                numItems = numItems + 1
            end
            for numItems = numItems, 1, -1 do
                if numItems ~= keepIndex then
                    xmlFile:removeProperty(string.format(attributePath .. "(%d)", numItems - 1))
                end
            end
        end)
    end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataOverwrites)