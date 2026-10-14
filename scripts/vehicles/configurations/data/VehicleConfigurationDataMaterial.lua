VehicleConfigurationDataMaterial = {}
function VehicleConfigurationDataMaterial.registerXMLPaths(schema, _, configPath)
    schema:setXMLSharedRegistration("VehicleConfigurationDataMaterial", configPath)
    local materialKey = configPath .. ".material(?)"
    VehicleMaterial.registerXMLPaths(schema, materialKey)
    schema:register(XMLValueType.BOOL, materialKey .. "#ignoreWarning", "If set to \'true\' there is no warning if the material is not found.", false)
    schema:register(XMLValueType.NODE_INDEX, materialKey .. "#node", "If defined, the \'targetMaterialSlotName\' is only replaced for this node")
    schema:register(XMLValueType.STRING, materialKey .. "#sourceMaterialSlotName", "Material with this slot name replaces the material defined with \'targetMaterialSlotName\'")
    schema:register(XMLValueType.STRING, materialKey .. "#targetMaterialSlotName", "Material with this slot name is replaced the material defined with \'sourceMaterialSlotName\'")
    schema:register(XMLValueType.BOOL, materialKey .. "#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, materialKey .. "#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, materialKey .. "#useRimColor", "Use rim color", false)
    schema:resetXMLSharedRegistration("VehicleConfigurationDataMaterial", configPath)
end
function VehicleConfigurationDataMaterial.onLoadFinished(vehicle, configItem, _, ...)
    if configItem.configKey ~= "" then
        local color = nil
        if configItem:isa(VehicleConfigurationItemColor) then
            color = configItem:getColor()
        end
        vehicle.xmlFile:iterate(configItem.configKey .. ".material", function(_, materialKey)
            -- upvalues: (copy) vehicle, (ref) color, (copy) configItem
            XMLUtil.checkDeprecatedXMLElements(vehicle.xmlFile, materialKey .. "#refNode", materialKey .. "#sourceMaterialSlotName")
            local targetMaterialSlotName = vehicle.xmlFile:getValue(materialKey .. "#materialSlotName")
            if targetMaterialSlotName == nil then
                local material = vehicle.xmlFile:getValue(materialKey .. "#node", nil, vehicle.components, vehicle.i3dMappings)
                local useDesignColorIndex = vehicle.xmlFile:getValue(materialKey .. "#sourceMaterialSlotName")
                local configName = vehicle.xmlFile:getValue(materialKey .. "#targetMaterialSlotName")
                if useDesignColorIndex ~= nil and configName ~= nil then
                    local oldMaterial = nil
                    for _, component in pairs(vehicle.components) do
                        oldMaterial = MaterialUtil.getMaterialBySlotName(component.node, configName)
                        if oldMaterial ~= nil then
                            break
                        end
                    end
                    local newMaterial = nil
                    for component, component in pairs(vehicle.components) do
                        newMaterial = MaterialUtil.getMaterialBySlotName(component.node, useDesignColorIndex)
                        if newMaterial ~= nil then
                            break
                        end
                    end
                    if oldMaterial == nil then
                        Logging.xmlWarning(vehicle.xmlFile, "Unable to find targetMaterialSlotName \'%s\' in \'%s\'", configName, configItem.configKey)
                        return
                    elseif newMaterial == nil then
                        Logging.xmlWarning(vehicle.xmlFile, "Unable to find sourceMaterialSlotName \'%s\' in \'%s\'", useDesignColorIndex, configItem.configKey)
                        return
                    elseif material == nil then
                        for component, component in pairs(vehicle.components) do
                            MaterialUtil.replaceMaterialRec(component.node, oldMaterial, newMaterial)
                        end
                    else
                        MaterialUtil.replaceMaterialRec(material, oldMaterial, newMaterial)
                    end
                end
                if useDesignColorIndex ~= nil or configName ~= nil then
                    Logging.xmlWarning(vehicle.xmlFile, "Both \'sourceMaterialSlotName\' and \'targetMaterialSlotName\' need to be defined in \'%s\'", materialKey)
                end
            else
                local material = nil
                if vehicle.xmlFile:getValue(materialKey .. "#useBaseColor") then
                    material = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, "baseColor")
                else
                    local useDesignColorIndex = vehicle.xmlFile:getValue(materialKey .. "#useDesignColorIndex")
                    if useDesignColorIndex == nil then
                        if vehicle.xmlFile:getBool(materialKey .. "#useRimColor", false) then
                            material = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, "rimColor")
                            if material == nil then
                                material = VehicleMaterial.new(vehicle.baseDirectory)
                                material:setTemplateName("RIM_DEFAULT")
                            end
                        end
                    else
                        local configName = "designColor"
                        if useDesignColorIndex >= 2 then
                            configName = string.format("designColor%d", useDesignColorIndex)
                        end
                        material = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, configName)
                    end
                end
                if material == nil then
                    material = VehicleMaterial.new(vehicle.baseDirectory)
                    material:setColor(color)
                    material:loadFromXML(vehicle.xmlFile, materialKey, vehicle.customEnvironment)
                end
                if material ~= nil and (targetMaterialSlotName ~= nil and not (material:applyToVehicle(vehicle, targetMaterialSlotName) or vehicle.xmlFile:getValue(materialKey .. "#ignoreWarning", false))) then
                    Logging.xmlWarning(vehicle.xmlFile, "Failed to find material by material slot name \'%s\' in \'%s\'", targetMaterialSlotName, materialKey)
                    return
                end
            end
        end)
    end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataMaterial)