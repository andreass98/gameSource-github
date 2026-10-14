CropSensor = {}
CropSensor.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".cropSensor"
CropSensor.MAX_UPDATES_PER_FRAME = 1
CropSensor.MIN_SENSOR_RADIUS = 5
CropSensor.PATTERN_OCTAGON = {
    {
        0.33,
        0,
        -1,
        -0.33,
        0,
        -1,
        -0.33,
        0,
        -0.33
    },
    {
        1,
        0,
        0.33,
        1,
        0,
        -0.33,
        0.33,
        0,
        -0.33
    },
    {
        -0.33,
        0,
        1,
        0.33,
        0,
        1,
        0.33,
        0,
        0.33
    },
    {
        -1,
        0,
        -0.33,
        -1,
        0,
        0.33,
        -0.33,
        0,
        0.33
    },
    {
        -0.33,
        0,
        1,
        -0.33,
        0,
        -0.33,
        0.33,
        0,
        0.33
    },
    {
        1,
        0,
        0.33,
        -0.33,
        0,
        0.33,
        0.33,
        0,
        -0.33
    }
}
CropSensor.PATTERN_CORNER_LEFT = {
    {
        0,
        0,
        0,
        -0.15,
        0,
        0.33,
        1,
        0,
        0
    },
    {
        0.33,
        0,
        0.33,
        0,
        0,
        0.66,
        0.85,
        0,
        0.33
    },
    {
        -0.15,
        0,
        0.33,
        -0.15,
        0,
        0.66,
        0.33,
        0,
        0.33
    }
}
CropSensor.PATTERN_CORNER_RIGHT = {
    {
        0,
        0,
        0,
        0.15,
        0,
        0.33,
        -1,
        0,
        0
    },
    {
        -0.33,
        0,
        0.33,
        0,
        0,
        0.66,
        -0.85,
        0,
        0.33
    },
    {
        0.15,
        0,
        0.33,
        0.15,
        0,
        0.66,
        -0.33,
        0,
        0.33
    }
}
function CropSensor.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function CropSensor.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("cropSensor", g_i18n:getText("configuration_cropSensor"), "cropSensor", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("CropSensor")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.cropSensor.sensorNode(?)#node", "Sensor Node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.cropSensor.sensorNode(?)#lightNode", "Real light source node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.cropSensor.sensorNode(?)#staticLight", "Static light shape")
    schema:register(XMLValueType.FLOAT, "vehicle.cropSensor.sensorNode(?)#radius", "Sensor radius", 18)
    schema:register(XMLValueType.BOOL, "vehicle.cropSensor.sensorNode(?)#requiresDaylight", "Sensor requires daylight to work", false)
    schema:register(XMLValueType.STRING, "vehicle.cropSensor.sensorNode(?)#shape", "Sensor shape (CIRCLE | HALF_CIRCLE_LEFT | HALF_CIRCLE_RIGHT)", "CIRCLE")
    CropSensor.registerSensorLinkNodePaths(schema, "vehicle.cropSensor.cropSensorConfigurations.cropSensorConfiguration(?).sensorLinkNode(?)")
    schema:setXMLSpecializationType()
end
function CropSensor.registerSensorLinkNodePaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Sensor Node")
    schema:register(XMLValueType.STRING, basePath .. "#type", "Type of node to link (SENSOR_LEFT | SENSOR_RIGHT | SENSOR_TOP)", "SENSOR_LEFT")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#translation", "Translation offset", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Rotation offset", "0 0 0")
    schema:register(XMLValueType.BOOL, basePath .. ".rotationNode(?)#autoRotate", "Rotation will be automatically adjusted to the vehicle orientation")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".rotationNode(?)#rotation", "Rotation of rotation node", "0 0 0")
end
function CropSensor.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setCropSensorActive", CropSensor.setCropSensorActive)
    SpecializationUtil.registerFunction(vehicleType, "updateCropSensorWorkingWidth", CropSensor.updateCropSensorWorkingWidth)
    SpecializationUtil.registerFunction(vehicleType, "updateSensorRadius", CropSensor.updateSensorRadius)
    SpecializationUtil.registerFunction(vehicleType, "updateSensorNode", CropSensor.updateSensorNode)
    SpecializationUtil.registerFunction(vehicleType, "linkCropSensor", CropSensor.linkCropSensor)
end
function CropSensor.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", CropSensor.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseTurnedOnSchema", CropSensor.getUseTurnedOnSchema)
end
function CropSensor.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", CropSensor)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", CropSensor)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", CropSensor)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CropSensor)
    SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", CropSensor)
end
function CropSensor:onLoad(_)
    local spec = self[CropSensor.SPEC_TABLE_NAME]
    spec.sensorNodes = {}
    self.xmlFile:iterate("vehicle.cropSensor.sensorNode", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local sensorNode = {
            ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        }
        if sensorNode.node ~= nil then
            sensorNode.radius = self.xmlFile:getValue(key .. "#radius", 20)
            sensorNode.origRadius = sensorNode.radius
            sensorNode.requiresDaylight = self.xmlFile:getValue(key .. "#requiresDaylight", false)
            local shapeStr = string.upper(self.xmlFile:getValue(key .. "#shape", "CIRCLE"))
            if shapeStr == "CIRCLE" then
                sensorNode.shape = DensityMapCircle.createCircle(0, 0, sensorNode.radius, 8)
            elseif shapeStr == "HALF_CIRCLE_LEFT" then
                sensorNode.shape = DensityMapPolygon.new()
                local i = -0.5235987755982988
                for i = i, 1.9198621771937625, 0.5235987755982988 do
                    sensorNode.shape:addPolygonPoint(math.cos(i), (math.sin(i)))
                end
            elseif shapeStr == "HALF_CIRCLE_RIGHT" then
                sensorNode.shape = DensityMapPolygon.new()
                local i = 0.5235987755982988
                for i = i, -1.9198621771937625, -0.5235987755982988 do
                    sensorNode.shape:addPolygonPoint(math.cos(i), (math.sin(i)))
                end
            end
            if sensorNode.shape ~= nil then
                sensorNode.lightNode = self.xmlFile:getValue(key .. "#lightNode", nil, self.components, self.i3dMappings)
                if sensorNode.lightNode ~= nil then
                    setVisibility(sensorNode.lightNode, false)
                end
                sensorNode.staticLight = self.xmlFile:getValue(key .. "#staticLight", nil, self.components, self.i3dMappings)
                if sensorNode.staticLight ~= nil then
                    setShaderParameter(sensorNode.staticLight, "lightIds0", 0, 0, 0, 0, false)
                end
                sensorNode.index = 1
                table.insert(spec.sensorNodes, sensorNode)
                return
            end
            Logging.xmlWarning(self.xmlFile, "Invalid sensor shape \'%s\' in \'%s\'", shapeStr, key)
        end
    end)
    local configIndex = #spec.sensorNodes > 0
    spec.isStandaloneSensor = configIndex
    spec.inputActionToggle = InputAction.PRECISIONFARMING_TOGGLE_CROP_SENSOR
    local configIndex = self.configurations.cropSensor
    if configIndex ~= nil then
        local configKey = string.format("vehicle.cropSensor.cropSensorConfigurations.cropSensorConfiguration(%d)", configIndex - 1)
        spec.sensorLinkNodeData = {}
        spec.sensorLinkNodeData.linkNodes = {}
        self.xmlFile:iterate(configKey .. ".sensorLinkNode", function(_, key)
            -- upvalues: (copy) self, (copy) spec
            local linkNode = {
                ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
            }
            if linkNode.node ~= nil then
                linkNode.typeName = string.upper(self.xmlFile:getValue(key .. "#type", "SENSOR_LEFT"))
                linkNode.translation = self.xmlFile:getValue(key .. "#translation", "0 0 0", true)
                linkNode.rotation = self.xmlFile:getValue(key .. "#rotation", "0 0 0", true)
                linkNode.rotationNodes = {}
                self.xmlFile:iterate(key .. ".rotationNode", function(_, rotationNodeKey)
                    -- upvalues: (ref) self, (copy) linkNode
                    local rotatioNode = {
                        ["autoRotate"] = self.xmlFile:getValue(rotationNodeKey .. "#autoRotate"),
                        ["rotation"] = self.xmlFile:getValue(rotationNodeKey .. "#rotation", nil, true)
                    }
                    table.insert(linkNode.rotationNodes, rotatioNode)
                end)
                table.insert(spec.sensorLinkNodeData.linkNodes, linkNode)
            end
        end)
        if #spec.sensorLinkNodeData.linkNodes > 0 then
            self:linkCropSensor(spec.sensorLinkNodeData)
        end
        if configIndex > 1 and g_precisionFarming ~= nil then
            local linkData = g_precisionFarming:getCropSensorLinkageData(self.configFileName)
            if linkData ~= nil then
                self:linkCropSensor(linkData)
            end
        end
    end
    local configKey = #spec.sensorNodes > 0
    spec.isAvailable = configKey
    spec.isActive = false
    spec.workingWidth = 0
    if spec.isAvailable then
        spec.texts = {}
        spec.texts.toggleCropSensorPos = g_i18n:getText("action_toggleCropSensorPos", self.customEnvironment)
        spec.texts.toggleCropSensorNeg = g_i18n:getText("action_toggleCropSensorNeg", self.customEnvironment)
        spec.texts.warningSensorDaylight = g_i18n:getText("warning_sensorRequiresDaylight", self.customEnvironment)
        if g_precisionFarming ~= nil then
            spec.soilMap = g_precisionFarming.soilMap
            spec.coverMap = g_precisionFarming.coverMap
            spec.nitrogenMap = g_precisionFarming.nitrogenMap
            spec.farmlandStatistics = g_precisionFarming.farmlandStatistics
        end
    end
end
function CropSensor:onUpdate(_, _, _, _)
    if self.isServer then
        local spec = self[CropSensor.SPEC_TABLE_NAME]
        if spec.isAvailable and spec.isActive then
            local i = 1
            for i = i, #spec.sensorNodes do
                local sensorNode = spec.sensorNodes[i]
                if not sensorNode.requiresDaylight or g_currentMission.environment.isSunOn then
                    self:updateSensorNode(sensorNode)
                end
            end
        end
    end
end
function CropSensor:onDraw()
    if self.isClient and not self:getIsAIActive() then
        local spec = self[CropSensor.SPEC_TABLE_NAME]
        if spec.isAvailable and spec.isActive then
            local i = 1
            for i = i, #spec.sensorNodes do
                if spec.sensorNodes[i].requiresDaylight and not g_currentMission.environment.isSunOn then
                    g_currentMission:showBlinkingWarning(spec.texts.warningSensorDaylight, 1000)
                end
            end
        end
    end
end
function CropSensor:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self[CropSensor.SPEC_TABLE_NAME]
        if spec.isAvailable then
            self:clearActionEventsTable(spec.actionEvents)
            if isActiveForInputIgnoreSelection then
                local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.inputActionToggle, self, CropSensor.actionEventToggle, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                CropSensor.updateActionEventTexts(self)
            end
        end
    end
end
function CropSensor:onRootVehicleChanged(rootVehicle)
    if self.isServer then
        local spec = self[CropSensor.SPEC_TABLE_NAME]
        if spec.isAvailable then
            local actionController = rootVehicle.actionController
            if actionController ~= nil then
                if spec.controlledAction == nil then
                    spec.controlledAction = actionController:registerAction("cropSensorTurnOn", nil, 1)
                    spec.controlledAction:setCallback(self, CropSensor.actionControllerToggleEvent)
                    spec.controlledAction:setFinishedFunctions(self, function()
                        -- upvalues: (copy) spec
                        return spec.isActive
                    end, true, false)
                    spec.controlledAction:setIsSaved(true)
                    spec.controlledAction:addAIEventListener(self, "onAIFieldWorkerStart", 1)
                    spec.controlledAction:addAIEventListener(self, "onAIFieldWorkerEnd", -1)
                    spec.controlledAction:addAIEventListener(self, "onAIImplementStart", 1)
                    spec.controlledAction:addAIEventListener(self, "onAIImplementEnd", -1)
                else
                    spec.controlledAction:updateParent(actionController)
                end
            end
            if spec.controlledAction ~= nil then
                spec.controlledAction:remove()
            end
        end
    end
end
function CropSensor:actionEventToggle(_, _, _, _)
    self:setCropSensorActive()
end
function CropSensor:updateActionEventTexts()
    local spec = self[CropSensor.SPEC_TABLE_NAME]
    local actionEvent = spec.actionEvents[spec.inputActionToggle]
    if actionEvent ~= nil then
        g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.isActive and spec.texts.toggleCropSensorNeg or spec.texts.toggleCropSensorPos)
    end
end
function CropSensor:actionControllerToggleEvent(direction)
    self:setCropSensorActive(direction >= 0)
    return true
end
function CropSensor:doCheckSpeedLimit(superFunc)
    local spec = self[CropSensor.SPEC_TABLE_NAME]
    return not superFunc(self) and (spec ~= nil and spec.isStandaloneSensor) and spec.isActive
end
function CropSensor:getUseTurnedOnSchema(superFunc)
    local spec = self[CropSensor.SPEC_TABLE_NAME]
    return not superFunc(self) and (spec ~= nil and spec.isStandaloneSensor) and spec.isActive
end
function CropSensor:setCropSensorActive(state, noEventSend)
    local spec = self[CropSensor.SPEC_TABLE_NAME]
    if state == nil then
        state = not spec.isActive
    end
    if state ~= spec.isActive then
        if self.isClient then
            local i = 1
            for i = i, #spec.sensorNodes do
                local sensorNode = spec.sensorNodes[i]
                if sensorNode.lightNode ~= nil then
                    setVisibility(sensorNode.lightNode, state)
                end
                if sensorNode.staticLight ~= nil then
                    setShaderParameter(sensorNode.staticLight, "lightIds0", state and 0.2 or 0, 0, 0, 0, false)
                end
            end
        end
        if state then
            self:updateCropSensorWorkingWidth()
        end
        spec.isActive = state
        CropSensor.updateActionEventTexts(self)
        CropSensorStateEvent.sendEvent(self, state, noEventSend)
    end
end
function CropSensor:updateCropSensorWorkingWidth()
    local spec = self[CropSensor.SPEC_TABLE_NAME]
    spec.workingWidth = CropSensor.getMaxWorkingWidth(self)
    local i = 1
    for i = i, #spec.sensorNodes do
        self:updateSensorRadius(spec.sensorNodes[i], spec.workingWidth)
    end
end
function CropSensor:updateSensorRadius(sensorNode, workingWidth)
    if workingWidth > 0 then
        local xOffset, _, _ = localToLocal(sensorNode.node, self.rootNode, 0, 0, 0)
        sensorNode.radius = math.max(workingWidth * 1.1 / 2 - math.abs(xOffset), CropSensor.MIN_SENSOR_RADIUS)
    else
        sensorNode.radius = sensorNode.origRadius
    end
end
function CropSensor:updateSensorNode(sensorNode)
    if sensorNode.shape:isa(DensityMapCircle) then
        local x, _, z = getWorldTranslation(sensorNode.node)
        sensorNode.shape:updateFromWorldPosition(x, z, sensorNode.radius, 8)
    elseif sensorNode.shape:isa(DensityMapPolygon) then
        local x, _, z = getWorldTranslation(sensorNode.node)
        local dirX, _, dirZ = localDirectionToWorld(sensorNode.node, 0, 0, 1)
        local dirX, dirZ = MathUtil.vector2Normalize(dirX, dirZ)
        sensorNode.shape:updateOrigin(x, z, dirX, dirZ)
        sensorNode.shape:updateScale(sensorNode.radius, sensorNode.radius)
    end
    self[CropSensor.SPEC_TABLE_NAME].nitrogenMap:updateCropSensorArea(sensorNode.shape)
end
function CropSensor:linkCropSensor(linkData)
    local i = 1
    for i = i, #linkData.linkNodes do
        local linkNodeData = linkData.linkNodes[i]
        local linkNode = linkNodeData.node
        if linkNode == nil and (linkNodeData.nodeName ~= nil and self.i3dMappings[linkNodeData.nodeName] ~= nil) then
            linkNode = self.i3dMappings[linkNodeData.nodeName].nodeId
        end
        if linkNode ~= nil then
            local sensorData = g_precisionFarming:getClonedCropSensorNode(linkNodeData.typeName)
            if sensorData ~= nil then
                link(linkNode, sensorData.node)
                setTranslation(sensorData.node, linkNodeData.translation[1], linkNodeData.translation[2], linkNodeData.translation[3])
                setRotation(sensorData.node, linkNodeData.rotation[1], linkNodeData.rotation[2], linkNodeData.rotation[3])
                local j = 1
                local sensorNode = #sensorData.rotationNodes
                for j = j, sensorNode do
                    local autoRotate = false
                    if linkNodeData.rotationNodes[j] == nil then
                        autoRotate = sensorData.rotationNodes[j].autoRotate
                    else
                        local vRotationNode = linkNodeData.rotationNodes[j]
                        if rotationNode.autoRotate and (vRotationNode.autoRotate ~= false and vRotationNode.rotation == nil) then
                            autoRotate = true
                        elseif vRotationNode.rotation ~= nil then
                            setRotation(rotationNode.node, vRotationNode.rotation[1], vRotationNode.rotation[2], vRotationNode.rotation[3])
                        end
                    end
                    if autoRotate then
                        local vRotationNode, ry, rz = localRotationToLocal(self:getParentComponent(sensorData.node), getParent(rotationNode.node), 0, 0, 0)
                        setRotation(rotationNode.node, vRotationNode, ry, rz)
                    end
                end
                if sensorData.measurementNode ~= nil then
                    local sensorNode = {
                        ["node"] = sensorData.measurementNode,
                        ["radius"] = 10
                    }
                    sensorNode.origRadius = sensorNode.radius
                    if linkNodeData.typeName == "SENSOR_LEFT" then
                        sensorNode.shape = DensityMapPolygon.new()
                        sensorNode.shape:addPolygonPoint(0, 0)
                        local rotationNode = 1.9198621771937625
                        for rotationNode = rotationNode, -0.5235987755982988, -0.5235987755982988 do
                            sensorNode.shape:addPolygonPoint(math.cos(rotationNode), (math.sin(rotationNode)))
                        end
                    elseif linkNodeData.typeName == "SENSOR_RIGHT" then
                        sensorNode.shape = DensityMapPolygon.new()
                        sensorNode.shape:addPolygonPoint(0, 0)
                        local rotationNode = 1.0471975511965976
                        for rotationNode = rotationNode, 3.490658503988659, 0.5235987755982988 do
                            sensorNode.shape:addPolygonPoint(math.cos(rotationNode), (math.sin(rotationNode)))
                        end
                    end
                    sensorNode.requiresDaylight = sensorData.requiresDaylight
                    sensorNode.index = 1
                    local j = self[CropSensor.SPEC_TABLE_NAME].sensorNodes
                    table.insert(j, sensorNode)
                end
            end
        end
    end
end
function CropSensor.getMaxWorkingWidth(sensorVehicle)
    local childVehicles = sensorVehicle.rootVehicle.childVehicles
    local maxWidth = 0
    local i = 1
    for i = i, #childVehicles do
        local childVehicle = childVehicles[i]
        if SpecializationUtil.hasSpecialization(ExtendedSprayer, childVehicle.specializations) then
            if childVehicle.getWorkAreaByIndex ~= nil then
                local workAreas = childVehicle.spec_workArea.workAreas
                local j = 1
                for j = j, #workAreas do
                    local workArea = workAreas[j]
                    if workArea.start ~= nil and workArea.width ~= nil then
                        local width = calcDistanceFrom(workArea.start, workArea.width)
                        local x1 = math.max(maxWidth, width)
                        local x1, _, _ = localToLocal(workArea.start, sensorVehicle.rootNode, 0, 0, 0)
                        local x2, _, _ = localToLocal(workArea.width, sensorVehicle.rootNode, 0, 0, 0)
                        maxWidth = math.max(x1, math.abs(x1) * 2, math.abs(x2) * 2)
                    end
                end
            end
            if childVehicle.getAIMarkers ~= nil then
                local workAreas, rightMarker, _, j = childVehicle:getAIMarkers()
                if workAreas ~= nil and rightMarker ~= nil then
                    local workArea = calcDistanceFrom(workAreas, rightMarker)
                    local width = math.max(maxWidth, workArea)
                    local width, x1, _ = localToLocal(workAreas, sensorVehicle.rootNode, 0, 0, 0)
                    local _, x2, _ = localToLocal(rightMarker, sensorVehicle.rootNode, 0, 0, 0)
                    maxWidth = math.max(width, math.abs(width) * 2, math.abs(_) * 2)
                end
            end
        end
    end
    return maxWidth
end