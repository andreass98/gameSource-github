VehicleConfigurationDataSprayerNodes = {}
function VehicleConfigurationDataSprayerNodes.registerXMLPaths(schema, _, configPath)
    schema:register(XMLValueType.NODE_INDEX, configPath .. ".sprayerNozzles.nozzle(?)#node", "Nozzle Node")
    schema:register(XMLValueType.VECTOR_TRANS, configPath .. ".sprayerNozzles.nozzle(?)#translation", "Translation offset from the defined node")
    schema:register(XMLValueType.VECTOR_ROT, configPath .. ".sprayerNozzles.nozzle(?)#rotation", "Rotation offset from the defined node")
    schema:register(XMLValueType.STRING, configPath .. ".weedSpotSpraySensors.sensorNode(?)#id", "Sensor identifier of the type to use")
    schema:register(XMLValueType.STRING, configPath .. ".weedSpotSpraySensors.sensorNode(?)#node", "Name of node in i3d mapping")
    schema:register(XMLValueType.VECTOR_TRANS, configPath .. ".weedSpotSpraySensors.sensorNode(?)#translation", "Translation offset from node", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, configPath .. ".weedSpotSpraySensors.sensorNode(?)#rotation", "Rotation offset from node", "0 0 0")
    schema:register(XMLValueType.FLOAT, configPath .. ".weedSpotSpraySensors.sensorNode(?)#bracketSize", "Size of the bracket", 1)
end
function VehicleConfigurationDataSprayerNodes.onPrePostLoad(vehicle, configItem, _)
    if configItem.configKey ~= "" then
        local spec = vehicle[ExtendedSprayerEffects.SPEC_TABLE_NAME]
        if spec ~= nil then
            for _, key in vehicle.xmlFile:iterator(configItem.configKey .. ".sprayerNozzles.nozzle") do
                local linkNode = vehicle.xmlFile:getValue(key .. "#node", nil, vehicle.components, vehicle.i3dMappings)
                if linkNode ~= nil then
                    local effectNode = g_precisionFarming:getClonedSprayerEffectNode()
                    if effectNode ~= nil then
                        local effectData = {}
                        if vehicle:addExtendedSprayerNozzleEffect(effectData, effectNode, linkNode, {
                            ["translation"] = vehicle.xmlFile:getValue(key .. "#translation", { 0, 0, 0 }, true),
                            ["rotation"] = vehicle.xmlFile:getValue(key .. "#rotation", { 0, 0, 0 }, true)
                        }) then
                            table.insert(spec.sprayerEffects, effectData)
                        end
                    end
                end
            end
        end
        if vehicle[WeedSpotSpray.SPEC_TABLE_NAME] ~= nil and vehicle[WeedSpotSpray.SPEC_TABLE_NAME].isEnabled then
            local linkData = {
                ["sensorNodes"] = {}
            }
            for key, linkNode in vehicle.xmlFile:iterator(configItem.configKey .. ".weedSpotSpraySensors.sensorNode") do
                local effectNode = {
                    ["id"] = vehicle.xmlFile:getValue(linkNode .. "#id"),
                    ["nodeName"] = vehicle.xmlFile:getValue(linkNode .. "#node"),
                    ["translation"] = vehicle.xmlFile:getValue(linkNode .. "#translation", "0 0 0", true),
                    ["rotation"] = vehicle.xmlFile:getValue(linkNode .. "#rotation", "0 0 0", true),
                    ["bracketSize"] = vehicle.xmlFile:getValue(linkNode .. "#bracketSize", 1)
                }
                table.insert(linkData.sensorNodes, effectNode)
            end
            if #linkData.sensorNodes > 0 then
                vehicle:addWeedSpotSpraySensorNodes(linkData)
            end
        end
    end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataSprayerNodes)