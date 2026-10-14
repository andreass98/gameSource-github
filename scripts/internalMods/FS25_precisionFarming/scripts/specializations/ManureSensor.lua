ManureSensor = {}
ManureSensor.SPEC_NAME = g_currentModName .. ".manureSensor"
ManureSensor.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".manureSensor"
ManureSensor.MAX_NITROGEN_OFFSET_PCT = 0.4
ManureSensor.CHANGE_TIME = 120000
function ManureSensor.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Sprayer, specializations) and SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function ManureSensor.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("manureSensor", g_i18n:getText("configuration_manureSensor"), "manureSensor", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ManureSensor")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.manureSensor.manureSensorConfigurations.manureSensorConfiguration(?).linkNode#node", "Sensor Link Node")
    schema:register(XMLValueType.STRING, "vehicle.manureSensor.manureSensorConfigurations.manureSensorConfiguration(?).linkNode#type", "Sensor Type (DEFAULT, LARGE, SMALL or STANDALONE)")
    schema:setXMLSpecializationType()
end
function ManureSensor.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "linkManureSensor", ManureSensor.linkManureSensor)
    SpecializationUtil.registerFunction(vehicleType, "getManureSensorNitrogenOffset", ManureSensor.getManureSensorNitrogenOffset)
end
function ManureSensor.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCurrentNitrogenLevelOffset", ManureSensor.getCurrentNitrogenLevelOffset)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCurrentNitrogenUsageLevelOffset", ManureSensor.getCurrentNitrogenUsageLevelOffset)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsUsingExactNitrogenAmount", ManureSensor.getIsUsingExactNitrogenAmount)
end
function ManureSensor.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ManureSensor)
end
function ManureSensor:onLoad(_)
    local spec = self[ManureSensor.SPEC_TABLE_NAME]
    spec.currentCurveOffset = math.random()
    spec.sensorRequired = false
    local i = 1
    local configIndex = #self:getFillUnits()
    local configKey = 1
    for i = i, configIndex, configKey do
        spec.sensorRequired = spec.sensorRequired or (self:getFillUnitAllowsFillType(i, FillType.LIQUIDMANURE) or self:getFillUnitAllowsFillType(i, FillType.DIGESTATE))
    end
    spec.sensorAvailable = false
    local configIndex = self.configurations.manureSensor
    if configIndex ~= nil then
        local configKey = string.format("vehicle.manureSensor.manureSensorConfigurations.manureSensorConfiguration(%d)", configIndex - 1)
        local i = self.xmlFile:getValue(configKey .. ".linkNode#node", nil, self.components, self.i3dMappings)
        if i ~= nil then
            local linkData = {
                ["linkNodes"] = {}
            }
            linkData.linkNodes[1] = {
                ["linkNode"] = i,
                ["typeName"] = self.xmlFile:getValue(configKey .. ".linkNode#type", "DEFAULT")
            }
            self:linkManureSensor(linkData)
        end
        if configIndex > 1 and g_precisionFarming ~= nil then
            local typeName = g_precisionFarming:getManureSensorLinkageData(self.configFileName)
            if typeName ~= nil then
                self:linkManureSensor(typeName)
            end
        end
    end
end
function ManureSensor:linkManureSensor(linkData)
    local i = 1
    for i = i, #linkData.linkNodes do
        local linkNodeData = linkData.linkNodes[i]
        local linkNode = linkNodeData.linkNode
        if linkNode == nil and (linkNodeData.nodeName ~= nil and self.i3dMappings[linkNodeData.nodeName] ~= nil) then
            linkNode = self.i3dMappings[linkNodeData.nodeName].nodeId
        end
        if linkNode ~= nil then
            local sensorData = g_precisionFarming:getClonedManureSensorNode(linkNodeData.typeName)
            if sensorData ~= nil then
                link(linkNode, sensorData.node)
                if linkNodeData.translation ~= nil then
                    setTranslation(sensorData.node, linkNodeData.translation[1], linkNodeData.translation[2], linkNodeData.translation[3])
                end
                if linkNodeData.rotation ~= nil then
                    setRotation(sensorData.node, linkNodeData.rotation[1], linkNodeData.rotation[2], linkNodeData.rotation[3])
                end
                if linkNodeData.scale ~= nil then
                    setScale(sensorData.node, linkNodeData.scale[1], linkNodeData.scale[2], linkNodeData.scale[3])
                end
            end
        end
    end
    self[ManureSensor.SPEC_TABLE_NAME].sensorAvailable = true
end
function ManureSensor:getManureSensorNitrogenOffset(lastChangeLevels)
    local curve = g_time % ManureSensor.CHANGE_TIME / ManureSensor.CHANGE_TIME + self[ManureSensor.SPEC_TABLE_NAME].currentCurveOffset
    local direction = math.sin(curve * 3.141592653589793 * 2) * 0.75
    local stepOffset = direction + math.sin(curve * 3.141592653589793 * 10) * 0.15
    local stepOffset = (stepOffset + math.sin(curve * 3.141592653589793 * 20) * 0.15) * (lastChangeLevels * ManureSensor.MAX_NITROGEN_OFFSET_PCT)
    local direction = math.sign(stepOffset)
    return MathUtil.round((math.abs(stepOffset))) * direction
end
function ManureSensor:getCurrentNitrogenLevelOffset(superFunc, lastChangeLevels)
    local spec = self[ManureSensor.SPEC_TABLE_NAME]
    if spec.sensorRequired then
        return spec.sensorAvailable and 0 or self:getManureSensorNitrogenOffset(lastChangeLevels)
    else
        return superFunc(self)
    end
end
function ManureSensor:getCurrentNitrogenUsageLevelOffset(superFunc, lastChangeLevels)
    local spec = self[ManureSensor.SPEC_TABLE_NAME]
    if spec.sensorRequired then
        return not spec.sensorAvailable and 0 or self:getManureSensorNitrogenOffset(lastChangeLevels)
    else
        return superFunc(self)
    end
end
function ManureSensor:getIsUsingExactNitrogenAmount(superFunc)
    local spec = self[ManureSensor.SPEC_TABLE_NAME]
    if spec.sensorRequired then
        return spec.sensorAvailable
    else
        return superFunc(self)
    end
end