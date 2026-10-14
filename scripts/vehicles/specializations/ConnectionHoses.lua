ConnectionHoses = {}
ConnectionHoses.DEFAULT_MAX_UPDATE_DISTANCE = 50
source("dataS/scripts/vehicles/specializations/components/ToolConnectionHoseMount.lua")
function ConnectionHoses.prerequisitesPresent(specializations)
    return true
end
function ConnectionHoses.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ConnectionHoses")
    schema:register(XMLValueType.FLOAT, "vehicle.connectionHoses#maxUpdateDistance", "Max. distance to vehicle root to update connection hoses", ConnectionHoses.DEFAULT_MAX_UPDATE_DISTANCE)
    ConnectionHoses.registerConnectionHoseXMLPaths(schema, "vehicle.connectionHoses")
    ConnectionHoses.registerConnectionHoseXMLPaths(schema, "vehicle.connectionHoses.connectionHoseConfigurations.connectionHoseConfiguration(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.connectionHoses.sounds", "connect(?)")
    schema:register(XMLValueType.STRING, "vehicle.connectionHoses.sounds.connect(?)#type", "Connection hose type")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.connectionHoses.sounds", "disconnect(?)")
    schema:register(XMLValueType.STRING, "vehicle.connectionHoses.sounds.disconnect(?)#type", "Connection hose type")
    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".connectionHoses#customHoseIndices", "Custom hoses to update")
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".connectionHoses#customTargetIndices", "Custom hose targets to update")
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".connectionHoses#localHoseIndices", "Local hoses to update")
    end)
    schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".connectionHoses#customHoseIndices", "Custom hoses to update")
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".connectionHoses#customTargetIndices", "Custom hose targets to update")
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".connectionHoses#localHoseIndices", "Local hoses to update")
    end)
    schema:setXMLSpecializationType()
end
function ConnectionHoses.registerConnectionHoseXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".skipNode(?)#node", "Skip node")
    schema:register(XMLValueType.INT, basePath .. ".skipNode(?)#inputAttacherJointIndex", "Input attacher joint index", 1)
    schema:register(XMLValueType.INT, basePath .. ".skipNode(?)#attacherJointIndex", "Attacher joint index", 1)
    schema:register(XMLValueType.STRING, basePath .. ".skipNode(?)#type", "Connection hose type")
    schema:register(XMLValueType.STRING, basePath .. ".skipNode(?)#specType", "Connection hose specialization type (if defined it needs to match the type of the other tool)")
    schema:register(XMLValueType.FLOAT, basePath .. ".skipNode(?)#length", "Hose length")
    schema:register(XMLValueType.BOOL, basePath .. ".skipNode(?)#isTwoPointHose", "Is two point hose without sagging", false)
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".skipNode(?)")
    ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".target(?)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".toolConnectorHose(?)#mountingNode", "Mounting node to toggle visibility")
    schema:register(XMLValueType.BOOL, basePath .. ".toolConnectorHose(?)#moveNodes", "Defines if the start and end nodes are moved up depending on hose diameter", true)
    schema:register(XMLValueType.BOOL, basePath .. ".toolConnectorHose(?)#additionalHose", "Defines if between start and end node a additional hose is created", true)
    ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".toolConnectorHose(?).startTarget(?)")
    ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".toolConnectorHose(?).endTarget(?)")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath .. ".toolConnectorHose(?)")
    ConnectionHoses.registerHoseNodesXMLPaths(schema, basePath .. ".hose(?)")
    ConnectionHoses.registerHoseNodesXMLPaths(schema, basePath .. ".localHose(?).hose")
    ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".localHose(?).target")
    ConnectionHoses.registerCustomHoseNodesXMLPaths(schema, basePath .. ".customHose(?)")
    ConnectionHoses.registerCustomHoseTargetNodesXMLPaths(schema, basePath .. ".customTarget(?)")
end
function ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath)
    schema:addDelayedRegistrationPath(basePath, "ConnectionHoses:targetNode")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Target node")
    schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "List of corresponding attacher joint indices")
    schema:register(XMLValueType.NODE_INDICES, basePath .. "#attacherJointNodes", "List of corresponding attacher joint nodes (i3dIdentifiers or paths separated by space)")
    schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type")
    schema:registerAutoCompletionDataSource(basePath .. "#type", "data/shared/connectionHoses/connectionHoses.xml", "connectionHoses.connectionHoseTypes.connectionHoseType#name")
    schema:register(XMLValueType.STRING, basePath .. "#specType", "Connection hose specialization type (if defined it needs to match the type of the other tool)")
    schema:register(XMLValueType.FLOAT, basePath .. "#straighteningFactor", "Straightening Factor", 1)
    schema:register(XMLValueType.VECTOR_3, basePath .. "#straighteningDirection", "Straightening direction", "0 0 1")
    schema:register(XMLValueType.STRING, basePath .. "#socket", "Socket name to load")
    schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#socketMaterialTemplateName", "Socket custom material")
    schema:registerAutoCompletionDataSource(basePath .. "#socketMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
    schema:register(XMLValueType.STRING, basePath .. "#adapterType", "Adapter type to use", "DEFAULT")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end
function ConnectionHoses.registerHoseNodesXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "List of corresponding input attacher joint indices")
    schema:register(XMLValueType.NODE_INDICES, basePath .. "#inputAttacherJointNodes", "List of corresponding input attacher joint nodes (i3dIdentifiers or paths separated by space)")
    schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type")
    schema:register(XMLValueType.STRING, basePath .. "#specType", "Connection hose specialization type (if defined it needs to match the type of the other tool)")
    schema:register(XMLValueType.STRING, basePath .. "#hoseType", "Hose material type", "DEFAULT")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Hose output node")
    schema:register(XMLValueType.BOOL, basePath .. "#isTwoPointHose", "Is two point hose without sagging", false)
    schema:register(XMLValueType.BOOL, basePath .. "#isWorldSpaceHose", "Sagging is calculated in world space or local space of hose node", true)
    schema:register(XMLValueType.STRING, basePath .. "#dampingRange", "Damping range in meters", 0.05)
    schema:register(XMLValueType.FLOAT, basePath .. "#dampingFactor", "Damping factor", 50)
    schema:register(XMLValueType.FLOAT, basePath .. "#length", "Hose length", 3)
    schema:register(XMLValueType.BOOL, basePath .. "#dynamicLength", "Use will calculate the length on attach", false)
    schema:register(XMLValueType.FLOAT, basePath .. "#diameter", "Hose diameter", 0.02)
    schema:register(XMLValueType.FLOAT, basePath .. "#straighteningFactor", "Straightening Factor", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#centerPointDropFactor", "Can be used to manipulate how much the hose will drop while it\'s getting shorter then set", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#centerPointTension", "Defines the tension on the center control point (0: default behavior)", 0)
    schema:register(XMLValueType.ANGLE, basePath .. "#minCenterPointAngle", "Min. angle of sagged curve", "Defined on connectionHose xml, default 90 degree")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#minCenterPointOffset", "Min. center point offset from hose node", "unlimited")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#maxCenterPointOffset", "Max. center point offset from hose node", "unlimited")
    schema:register(XMLValueType.FLOAT, basePath .. "#minDeltaY", "Min. delta Y from center point")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#minDeltaYComponent", "Min. delta Y reference node")
    schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#materialTemplateName", "Hose material")
    schema:registerAutoCompletionDataSource(basePath .. "#materialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
    schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#adapterMaterialTemplateName", "Material of colorable part of adapter")
    schema:registerAutoCompletionDataSource(basePath .. "#adapterMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
    schema:register(XMLValueType.STRING, basePath .. "#adapterType", "Adapter type name")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#adapterNode", "Link node for detached adapter")
    schema:register(XMLValueType.STRING, basePath .. "#outgoingAdapter", "Adapter type that is used for outgoing connection hose")
    schema:register(XMLValueType.STRING, basePath .. "#socket", "Outgoing socket name to load")
    schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#socketMaterialTemplateName", "Socket custom material")
    schema:registerAutoCompletionDataSource(basePath .. "#socketMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end
function ConnectionHoses.registerCustomHoseNodesXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Target or source node")
    schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type which can be any string that needs to match between hose and target node")
    schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "Input attacher joint indices")
    schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "Attacher joint indices")
    schema:register(XMLValueType.BOOL, basePath .. "#isActiveDirty", "Custom hose is permanently updated", false)
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end
function ConnectionHoses.registerCustomHoseTargetNodesXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Target or source node")
    schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type which can be any string that needs to match between hose and target node")
    schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "Input attacher joint indices")
    schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "Attacher joint indices")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end
function ConnectionHoses.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getConnectionHoseConfigIndex", ConnectionHoses.getConnectionHoseConfigIndex)
    SpecializationUtil.registerFunction(vehicleType, "updateAttachedConnectionHoses", ConnectionHoses.updateAttachedConnectionHoses)
    SpecializationUtil.registerFunction(vehicleType, "updateConnectionHose", ConnectionHoses.updateConnectionHose)
    SpecializationUtil.registerFunction(vehicleType, "getCenterPointAngle", ConnectionHoses.getCenterPointAngle)
    SpecializationUtil.registerFunction(vehicleType, "getCenterPointAngleRegulation", ConnectionHoses.getCenterPointAngleRegulation)
    SpecializationUtil.registerFunction(vehicleType, "loadConnectionHosesFromXML", ConnectionHoses.loadConnectionHosesFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadHoseSkipNode", ConnectionHoses.loadHoseSkipNode)
    SpecializationUtil.registerFunction(vehicleType, "loadToolConnectorHoseNode", ConnectionHoses.loadToolConnectorHoseNode)
    SpecializationUtil.registerFunction(vehicleType, "addHoseTargetNodes", ConnectionHoses.addHoseTargetNodes)
    SpecializationUtil.registerFunction(vehicleType, "loadCustomHosesFromXML", ConnectionHoses.loadCustomHosesFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadHoseTargetNode", ConnectionHoses.loadHoseTargetNode)
    SpecializationUtil.registerFunction(vehicleType, "loadHoseNode", ConnectionHoses.loadHoseNode)
    SpecializationUtil.registerFunction(vehicleType, "getClonedSkipHoseNode", ConnectionHoses.getClonedSkipHoseNode)
    SpecializationUtil.registerFunction(vehicleType, "getConnectionTarget", ConnectionHoses.getConnectionTarget)
    SpecializationUtil.registerFunction(vehicleType, "iterateConnectionTargets", ConnectionHoses.iterateConnectionTargets)
    SpecializationUtil.registerFunction(vehicleType, "getIsConnectionTargetUsed", ConnectionHoses.getIsConnectionTargetUsed)
    SpecializationUtil.registerFunction(vehicleType, "getIsConnectionHoseUsed", ConnectionHoses.getIsConnectionHoseUsed)
    SpecializationUtil.registerFunction(vehicleType, "getIsSkipNodeAvailable", ConnectionHoses.getIsSkipNodeAvailable)
    SpecializationUtil.registerFunction(vehicleType, "getConnectionHosesByInputAttacherJoint", ConnectionHoses.getConnectionHosesByInputAttacherJoint)
    SpecializationUtil.registerFunction(vehicleType, "connectHose", ConnectionHoses.connectHose)
    SpecializationUtil.registerFunction(vehicleType, "disconnectHose", ConnectionHoses.disconnectHose)
    SpecializationUtil.registerFunction(vehicleType, "updateToolConnectionHose", ConnectionHoses.updateToolConnectionHose)
    SpecializationUtil.registerFunction(vehicleType, "addHoseToDelayedMountings", ConnectionHoses.addHoseToDelayedMountings)
    SpecializationUtil.registerFunction(vehicleType, "connectHoseToSkipNode", ConnectionHoses.connectHoseToSkipNode)
    SpecializationUtil.registerFunction(vehicleType, "connectHosesToAttacherVehicle", ConnectionHoses.connectHosesToAttacherVehicle)
    SpecializationUtil.registerFunction(vehicleType, "retryHoseSkipNodeConnections", ConnectionHoses.retryHoseSkipNodeConnections)
    SpecializationUtil.registerFunction(vehicleType, "connectCustomHosesToAttacherVehicle", ConnectionHoses.connectCustomHosesToAttacherVehicle)
    SpecializationUtil.registerFunction(vehicleType, "connectCustomHoseNode", ConnectionHoses.connectCustomHoseNode)
    SpecializationUtil.registerFunction(vehicleType, "updateCustomHoseNode", ConnectionHoses.updateCustomHoseNode)
    SpecializationUtil.registerFunction(vehicleType, "disconnectCustomHoseNode", ConnectionHoses.disconnectCustomHoseNode)
    SpecializationUtil.registerFunction(vehicleType, "setConnectionHosesActive", ConnectionHoses.setConnectionHosesActive)
end
function ConnectionHoses.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", ConnectionHoses.loadExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", ConnectionHoses.updateExtraDependentParts)
end
function ConnectionHoses.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", ConnectionHoses)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ConnectionHoses)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ConnectionHoses)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ConnectionHoses)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", ConnectionHoses)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", ConnectionHoses)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", ConnectionHoses)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", ConnectionHoses)
end
function ConnectionHoses:onPreLoad(_)
    local spec = self.spec_connectionHoses
    spec.configIndex = self:getConnectionHoseConfigIndex()
    spec.connectionHosesActive = true
    spec.numHosesByType = {}
    spec.numToolConnectionsByType = {}
    spec.hoseSkipNodes = {}
    spec.hoseSkipNodeByType = {}
    spec.targetNodes = {}
    spec.targetNodesByType = {}
    spec.toolConnectorHoses = {}
    spec.targetNodeToToolConnection = {}
    spec.hoseNodes = {}
    spec.hoseNodesByInputAttacher = {}
    spec.localHoseNodes = {}
    spec.customHoses = {}
    spec.customHosesByAttacher = {}
    spec.customHosesByInputAttacher = {}
    spec.customHosesActiveDirty = {}
    spec.customHoseTargets = {}
    spec.customHoseTargetsByAttacher = {}
    spec.customHoseTargetsByInputAttacher = {}
    spec.additionalSharedLoadRequestIds = {}
    spec.toolConnectionHoseMounts = {}
    spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.connectionHoses#maxUpdateDistance", ConnectionHoses.DEFAULT_MAX_UPDATE_DISTANCE)
end
function ConnectionHoses:onPostLoad(_)
    local spec = self.spec_connectionHoses
    local configKey = string.format("vehicle.connectionHoses.connectionHoseConfigurations.connectionHoseConfiguration(%d)", spec.configIndex - 1)
    self:loadConnectionHosesFromXML(self.xmlFile, "vehicle.connectionHoses")
    if self.xmlFile:hasProperty(configKey) then
        self:loadConnectionHosesFromXML(self.xmlFile, configKey)
    end
    ConnectionHoses.registerAdditionalToolConnectionHoses(self)
    local loadSamplesFromKey = #spec.targetNodes > 0
    spec.targetNodesAvailable = loadSamplesFromKey
    local loadSamplesFromKey = #spec.hoseNodes > 0
    spec.hoseNodesAvailable = loadSamplesFromKey
    local loadSamplesFromKey = #spec.localHoseNodes > 0
    spec.localHosesAvailable = loadSamplesFromKey
    local loadSamplesFromKey = #spec.hoseSkipNodes > 0
    spec.skipNodesAvailable = loadSamplesFromKey
    local loadSamplesFromKey = #spec.customHosesActiveDirty > 0
    spec.activeDirtyCustomHosesAvailable = loadSamplesFromKey
    spec.updateableHoses = {}
    if self.isClient then
        local function loadSamplesFromKey(key)
            -- upvalues: (copy) self, (copy) spec
            local i = 0
            while true do
                local actionKey = string.format("%s(%d)", key, i)
                local baseKey = "vehicle.connectionHoses.sounds." .. actionKey
                if not self.xmlFile:hasProperty(baseKey) then
                    return {}
                end
                local sample = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.connectionHoses.sounds", actionKey, self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
                if sample ~= nil then
                    local type = self.xmlFile:getValue(baseKey .. "#type")
                    local isValid = false
                    for i, hose in ipairs(spec.hoseNodes) do
                        if hose.type == type then
                            isValid = true
                            break
                        end
                    end
                    if isValid then
                        samples[type] = sample
                    else
                        Logging.xmlWarning(self.xmlFile, "Failed load %s-sound with type %s. No hose with that type available.", key, type)
                    end
                end
                i = i + 1
            end
        end
        spec.samples = {}
        spec.samples.connect = loadSamplesFromKey("connect")
        spec.samples.disconnect = loadSamplesFromKey("disconnect")
    end
    if not (self.isClient and (spec.targetNodesAvailable or (spec.hoseNodesAvailable or (spec.localHosesAvailable or (spec.skipNodesAvailable or spec.activeDirtyCustomHosesAvailable))))) then
        SpecializationUtil.removeEventListener(self, "onUpdateInterpolation", ConnectionHoses)
    end
end
function ConnectionHoses:onLoadFinished(_)
    for _, localHoseNode in ipairs(self.spec_connectionHoses.localHoseNodes) do
        self:connectHose(localHoseNode.hose, self, localHoseNode.target, false)
    end
end
function ConnectionHoses:onDelete()
    local spec = self.spec_connectionHoses
    if spec.additionalSharedLoadRequestIds ~= nil then
        local i = 1
        for i = i, #spec.additionalSharedLoadRequestIds do
            g_i3DManager:releaseSharedI3DFile(spec.additionalSharedLoadRequestIds[i])
        end
        spec.additionalSharedLoadRequestIds = nil
    end
    if spec.toolConnectionHoseMounts ~= nil then
        for _, toolConnectionHoseMount in pairs(spec.toolConnectionHoseMounts) do
            toolConnectionHoseMount:delete()
        end
        spec.toolConnectionHoseMounts = nil
    end
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples.connect)
        g_soundManager:deleteSamples(spec.samples.disconnect)
    end
end
function ConnectionHoses:onUpdateInterpolation(_, _, _, _)
    local spec = self.spec_connectionHoses
    if self.currentUpdateDistance < spec.maxUpdateDistance then
        local i = 1
        local impements = #spec.updateableHoses
        for i = i, impements do
            local hose = spec.updateableHoses[i]
            if self.updateLoopIndex == hose.connectedObject.updateLoopIndex then
                self:updateConnectionHose(hose, i)
            end
        end
        for hose, customHose in ipairs(spec.customHosesActiveDirty) do
            if customHose.isActive and (customHose.connectedTarget ~= nil and self.updateLoopIndex == customHose.connectedObject.updateLoopIndex) then
                self:updateCustomHoseNode(customHose, customHose.connectedTarget)
            end
        end
        if self.getAttachedImplements ~= nil then
            local impements = self:getAttachedImplements()
            local hose = 1
            for hose = hose, #impements do
                local customHose = impements[hose].object
                if customHose.updateAttachedConnectionHoses ~= nil then
                    customHose:updateAttachedConnectionHoses(self)
                end
            end
        end
    end
end
function ConnectionHoses:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    ConnectionHoses.onUpdateInterpolation(self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end
function ConnectionHoses:getConnectionHoseConfigIndex()
    return 1
end
function ConnectionHoses:updateAttachedConnectionHoses(attacherVehicle)
    local spec = self.spec_connectionHoses
    local i = 1
    for i = i, #spec.updateableHoses do
        local hose = spec.updateableHoses[i]
        if hose.connectedObject == attacherVehicle and self.updateLoopIndex == hose.connectedObject.updateLoopIndex then
            self:updateConnectionHose(hose, i)
        end
    end
    for hose, customHose in ipairs(spec.customHosesActiveDirty) do
        if customHose.isActive and (customHose.connectedTarget ~= nil and (customHose.connectedObject == attacherVehicle and self.updateLoopIndex == customHose.connectedObject.updateLoopIndex)) then
            self:updateCustomHoseNode(customHose, customHose.connectedTarget)
        end
    end
end
function ConnectionHoses:updateConnectionHose(hose, index)
    local p3x, p3y, p3z = localToLocal(hose.targetNode, hose.hoseNode, 0, 0, 0)
    local p4x, p4y, p4z = localToLocal(hose.targetNode, hose.hoseNode, hose.endStraighteningDirection[1] * hose.endStraightening, hose.endStraighteningDirection[2] * hose.endStraightening, hose.endStraighteningDirection[3] * hose.endStraightening)
    local p2x, p2y, p2z
    if hose.isWorldSpaceHose then
        local w1x, w1y, w1z = getWorldTranslation(hose.hoseNode)
        local w2x, w2y, w2z = getWorldTranslation(hose.targetNode)
        p2x = (w1x + w2x) / 2
        p2y = (w1y + w2y) / 2
        p2z = (w1z + w2z) / 2
    else
        p2x = p3x / 2
        p2y = p3y / 2
        p2z = p3z / 2
    end
    local w1x = MathUtil.vector3Length(p3x, p3y, p3z)
    local w2x = hose.length - w1x
    local w1y = math.max(w2x, 0) * (hose.centerPointDropFactor or 1)
    local w2z
    if hose.isWorldSpaceHose then
        w2z = p2y
    else
        local w2y, _
        w2y, w2z, _ = localToWorld(hose.hoseNode, p2x, p2y, p2z)
    end
    local w2z = 0.04 * w1x
    local p2y = p2y - math.max(w1y, w2z)
    if hose.isWorldSpaceHose then
        if hose.minDeltaY ~= math.huge then
            local w2x, w2y, w2z = worldToLocal(hose.minDeltaYComponent, p2x, p2y, p2z)
            local _, yTarget, _ = localToLocal(hose.hoseNode, hose.minDeltaYComponent, 0, 0, 0)
            p2x, p2y, p2z = localToWorld(hose.minDeltaYComponent, w2x, math.max(w2y, yTarget + hose.minDeltaY), w2z)
        end
        p2x, p2y, p2z = worldToLocal(hose.hoseNode, p2x, p2y, p2z)
    end
    local w2x, w2y = self:getCenterPointAngle(hose.hoseNode, p2x, p2y, p2z, p3x, p3y, p3z, hose.isWorldSpaceHose)
    local w2z = w2x + w2y
    if w2z < hose.minCenterPointAngle then
        p2x, p2y, p2z = self:getCenterPointAngleRegulation(hose.hoseNode, p2x, p2y, p2z, p3x, p3y, p3z, w2x, w2y, hose.minCenterPointAngle, hose.isWorldSpaceHose)
    end
    if hose.minCenterPointOffset ~= nil and hose.maxCenterPointOffset ~= nil then
        p2x = math.clamp(p2x, hose.minCenterPointOffset[1], hose.maxCenterPointOffset[1])
        p2y = math.clamp(p2y, hose.minCenterPointOffset[2], hose.maxCenterPointOffset[2])
        p2z = math.clamp(p2z, hose.minCenterPointOffset[3], hose.maxCenterPointOffset[3])
    end
    local _, yTarget, _ = getWorldTranslation(hose.component)
    if hose.lastComponentPosition == nil or hose.lastComponentVelocity == nil then
        hose.lastComponentPosition = { _, yTarget, _ }
        hose.lastComponentVelocity = { _, yTarget, _ }
    end
    local newVelX = _ - hose.lastComponentPosition[1]
    local newVelY = yTarget - hose.lastComponentPosition[2]
    local newVelZ = _ - hose.lastComponentPosition[3]
    local velZ = hose.lastComponentPosition
    hose.lastComponentPosition[1] = _
    hose.lastComponentPosition[2] = yTarget
    velZ[3] = _
    local velZ = newVelZ - hose.lastComponentVelocity[3]
    hose.lastComponentVelocity[1] = newVelX
    hose.lastComponentVelocity[2] = newVelY
    hose.lastComponentVelocity[3] = newVelZ
    local worldX, worldY, worldZ = getWorldTranslation(hose.hoseNode)
    local _, wp2y, _ = worldToLocal(hose.hoseNode, worldX + (newVelX - hose.lastComponentVelocity[1]), worldY + (newVelY - hose.lastComponentVelocity[2]), worldZ + velZ)
    local _, wp2y, _ = localToWorld(hose.hoseNode, p2x, p2y, p2z)
    local realLengthDifference = w2z - wp2y
    local x1 = wp2y * -hose.dampingFactor
    local y1 = -hose.dampingRange
    local z1 = hose.dampingRange
    local velY = math.clamp(x1, y1, z1) * realLengthDifference
    local x1 = _ * -hose.dampingFactor
    local y1 = -hose.dampingRange
    local z1 = hose.dampingRange
    local velZ = math.clamp(x1, y1, z1) * realLengthDifference
    local velZ = velZ * 0.1 + hose.lastVelZ * 0.9
    hose.lastVelY = velY * 0.1 + hose.lastVelY * 0.9
    hose.lastVelZ = velZ
    local p2y = p2y + velY
    local p2z = p2z + velZ
    if hose.isTwoPointHose then
        p2x = 0
        p2y = 0
        p2z = 0
    end
    setShaderParameter(hose.hoseNode, "cv2", p2x, p2y, p2z, hose.centerPointTension or 0, false)
    setShaderParameter(hose.hoseNode, "cv3", p3x, p3y, p3z, 0, false)
    setShaderParameter(hose.hoseNode, "cv4", p4x, p4y, p4z, 1, false)
    if VehicleDebug.state == VehicleDebug.DEBUG_ATTACHER_JOINTS and self:getIsActiveForInput() then
        local realLength = MathUtil.vector3Length(p2x, p2y, p2z) + MathUtil.vector3Length(p2x - p3x, p2y - p3y, p2z - p3z)
        renderText(0.5, 0.9 - index * 0.02, 0.0175, string.format("hose %s:", getName(hose.node)))
        local x3 = math.deg(w2z)
        renderText(0.62, 0.9 - index * 0.02, 0.0175, string.format("directLength: %.2f configLength: %.2f realLength: %.2f angle: %.2f minAngle: %.2f", w1x, hose.length, realLength, x3, (math.deg(hose.minCenterPointAngle))))
        local x1, y1, z1 = localToWorld(hose.hoseNode, 0, 0, -hose.startStraightening)
        local x2, y2, z2 = localToWorld(hose.hoseNode, 0, 0, 0)
        drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 0, 1, 0)
        local x0, y0, z0 = localToWorld(hose.hoseNode, 0, 0, 0)
        local x0, y0, z0 = localToWorld(hose.hoseNode, p2x, p2y, p2z)
        drawDebugLine(x0, y0, z0, 1, 0, 0, x0, y0, z0, 0, 1, 0)
        local x0, y0, z0 = localToWorld(hose.hoseNode, p2x, p2y, p2z)
        local x0, y0, z0 = localToWorld(hose.hoseNode, p3x, p3y, p3z)
        drawDebugLine(x0, y0, z0, 1, 0, 0, x0, y0, z0, 0, 1, 0)
        local x0, y0, z0 = localToWorld(hose.hoseNode, p3x, p3y, p3z)
        local x0, y0, z0 = localToWorld(hose.hoseNode, p4x, p4y, p4z)
        drawDebugLine(x0, y0, z0, 1, 0, 0, x0, y0, z0, 0, 1, 0)
        local x0, y0, z0 = localToWorld(hose.hoseNode, 0, 0, p0z)
        local x3, y3, z3 = localToWorld(hose.hoseNode, 0, 0, 0)
        local x3, y3, z3 = localToWorld(hose.hoseNode, p2x, p2y, p2z)
        local x3, y3, z3 = localToWorld(hose.hoseNode, p3x, p3y, p3z)
        local x4, y4, z4 = localToWorld(hose.hoseNode, p4x, p4y, p4z)
        drawDebugPoint(x0, y0, z0, 1, 0, 0, 1)
        drawDebugPoint(x3, y3, z3, 1, 0, 0, 1)
        drawDebugPoint(x3, y3, z3, 1, 0, 0, 1)
        drawDebugPoint(x3, y3, z3, 1, 0, 0, 1)
        drawDebugPoint(x4, y4, z4, 1, 0, 0, 1)
        DebugGizmo.renderAtNode(hose.hoseNode, "hn")
        DebugGizmo.renderAtNode(hose.targetNode, "tn")
        if hose.minCenterPointOffset ~= nil and hose.maxCenterPointOffset ~= nil then
            local x, y, z = localToWorld(hose.hoseNode, 0, 0, 0)
            local upX, upY, upZ = localDirectionToWorld(hose.hoseNode, 0, 1, 0)
            local dirX, dirY, dirZ = localDirectionToWorld(hose.hoseNode, 0, 0, 1)
            local sideDirX, sideDirY, sideDirZ = localDirectionToWorld(hose.hoseNode, 1, 0, 0)
            local maxY = hose.minCenterPointOffset[1]
            local minY = math.clamp(maxY, -1, 1)
            local minY = hose.maxCenterPointOffset[1]
            local maxX = math.clamp(minY, -1, 1)
            local maxZ = hose.minCenterPointOffset[2]
            local minZ = math.clamp(maxZ, -1, 1)
            local minZ = hose.maxCenterPointOffset[2]
            local maxY = math.clamp(minZ, -1, 1)
            local cy = hose.minCenterPointOffset[3]
            local cx = math.clamp(cy, -1, 1)
            local cx = hose.maxCenterPointOffset[3]
            local maxZ = math.clamp(cx, -1, 1)
            if hose.minCenterPointOffset[3] ~= -math.huge or hose.maxCenterPointOffset[3] ~= math.huge then
                local blue = Color.new(0, 0, 1, 0.1)
                DebugPlane.newSimple(true, true, blue, false):createFromPosAndDir(x + upX * (minZ + maxY) * 0.5 + sideDirX * (minY + maxX) * 0.5 + dirX * cx, y + upY * (minZ + maxY) * 0.5 + sideDirY * (minY + maxX) * 0.5 + dirY * cx, z + upZ * (minZ + maxY) * 0.5 + sideDirZ * (minY + maxX) * 0.5 + dirZ * cx, upX, upY, upZ, dirX, dirY, dirZ, maxX - minY, maxY - minZ):draw()
                DebugPlane.newSimple(true, true, blue, false):createFromPosAndDir(cx + dirX * maxZ, cy + dirY * maxZ, cz + dirZ * maxZ, upX, upY, upZ, dirX, dirY, dirZ, maxX - minY, maxY - minZ):draw()
            end
            if hose.minCenterPointOffset[2] ~= -math.huge or hose.maxCenterPointOffset[2] ~= math.huge then
                local blue = Color.new(0, 1, 0, 0.1)
                DebugPlane.newSimple(true, true, blue, false):createFromPosAndDir(cx + sideDirX * (minY + maxX) * 0.5 + upX * minZ, y + dirY * (x + dirX * (cx + maxZ) * 0.5 + maxZ) * 0.5 + sideDirY * (minY + maxX) * 0.5 + upY * minZ, z + dirZ * (cx + maxZ) * 0.5 + sideDirZ * (minY + maxX) * 0.5 + upZ * minZ, dirX, dirY, dirZ, upX, upY, upZ, maxX - minY, maxZ - cx):draw()
                DebugPlane.newSimple(true, true, blue, false):createFromPosAndDir(cx + upX * maxY, cy + upY * maxY, cz + upZ * maxY, dirX, dirY, dirZ, upX, upY, upZ, maxX - minY, maxZ - cx):draw()
            end
            if hose.minCenterPointOffset[1] ~= -math.huge or hose.maxCenterPointOffset[1] ~= math.huge then
                local cx = x + dirX * (cx + maxZ) * 0.5
                local cy = y + dirY * (cx + maxZ) * 0.5
                local cz = z + dirZ * (cx + maxZ) * 0.5
                local blue = Color.new(1, 0, 0, 0.1)
                DebugPlane.newSimple(true, true, blue, false):createFromPosAndDir(cx + sideDirX * minY, cy + sideDirY * minY, cz + sideDirZ * minY, dirX, dirY, dirZ, sideDirX, sideDirY, sideDirZ, maxY - minZ, maxZ - cx):draw()
                DebugPlane.newSimple(true, true, blue, false):createFromPosAndDir(cx + sideDirX * maxX, cy + sideDirY * maxX, cz + sideDirZ * maxX, dirX, dirY, dirZ, sideDirX, sideDirY, sideDirZ, maxY - minZ, maxZ - cx):draw()
            end
        end
        if hose.minDeltaY ~= math.huge and hose.minDeltaYComponent ~= nil then
            local x, y, z = localToLocal(hose.hoseNode, hose.minDeltaYComponent, p2x, p2y, p2z)
            local upX, upY, upZ = localToLocal(hose.hoseNode, hose.minDeltaYComponent, 0, 0, 0)
            local dirX, dirY, dirZ = localToWorld(hose.minDeltaYComponent, x, upY + hose.minDeltaY, z)
            local sideDirX, sideDirY, sideDirZ = localDirectionToWorld(hose.minDeltaYComponent, 0, 1, 0)
            local minX, maxX, minY = localDirectionToWorld(hose.minDeltaYComponent, 0, 0, 1)
            DebugPlane.newSimple(true, true, Color.new(0, 1, 0, 0.1), false):createFromPosAndDir(dirX, dirY, dirZ, minX, maxX, minY, sideDirX, sideDirY, sideDirZ, 1, 1):draw()
        end
    end
end
function ConnectionHoses.getCenterPointAngle(_, node, cX, cY, cZ, eX, eY, eZ, useWorldSpace)
    local lengthStartToCenter = MathUtil.vector3Length(cX, cY, cZ)
    local lengthCenterToEnd = math.abs((MathUtil.vector3Length(cX - eX, cY - eY, cZ - eZ)))
    local _, sY, _ = getWorldTranslation(node)
    if useWorldSpace then
        local lengthStartToCenter2, angle1
        lengthStartToCenter2, cY, angle1 = localToWorld(node, cX, cY, cZ)
        local lengthStartToCenter2, angle1
        lengthStartToCenter2, eY, angle1 = localToWorld(node, eX, eY, eZ)
    else
        sY = 0
    end
    local lengthStartToCenter2 = sY - cY
    local angle1 = math.acos(lengthStartToCenter2 / lengthStartToCenter)
    return angle1, math.acos((eY - cY) / lengthCenterToEnd)
end
function ConnectionHoses.getCenterPointAngleRegulation(_, node, cX, cY, cZ, eX, eY, eZ, angle1, angle2, targetAngle, useWorldSpace)
    local sX, sY, sZ = getWorldTranslation(node)
    if useWorldSpace then
        local pct
        cX, pct, cZ = localToWorld(node, cX, cY, cZ)
        local pct
        eX, pct, eZ = localToWorld(node, eX, eY, eZ)
    else
        sX = 0
        sY = 0
        sZ = 0
    end
    local centerEndLength = MathUtil.vector2Length(eX - cX, eZ - cZ)
    local alpha = 1.5707963267948966 - angle1 / (angle1 + angle2) * targetAngle
    local newY = (math.tan(alpha) * MathUtil.vector2Length(sX - cX, sZ - cZ) + math.tan(alpha) * centerEndLength) / 2
    if useWorldSpace then
        return worldToLocal(node, cX, sY - newY, cZ)
    else
        return cX, sY - newY, cZ
    end
end
function ConnectionHoses:loadConnectionHosesFromXML(xmlFile, key)
    local spec = self.spec_connectionHoses
    xmlFile:iterate(key .. ".skipNode", function(_, hoseKey)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) spec
        local entry = {}
        if self:loadHoseSkipNode(xmlFile, hoseKey, entry) then
            table.insert(spec.hoseSkipNodes, entry)
            if spec.hoseSkipNodeByType[entry.type] == nil then
                spec.hoseSkipNodeByType[entry.type] = {}
            end
            table.insert(spec.hoseSkipNodeByType[entry.type], entry)
        end
    end)
    self:addHoseTargetNodes(xmlFile, key .. ".target")
    xmlFile:iterate(key .. ".toolConnectorHose", function(_, hoseKey)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) spec
        local entry = {}
        if self:loadToolConnectorHoseNode(xmlFile, hoseKey, entry) then
            table.insert(spec.toolConnectorHoses, entry)
            spec.targetNodeToToolConnection[entry.startTargetNodeIndex] = entry
            spec.targetNodeToToolConnection[entry.endTargetNodeIndex] = entry
        end
    end)
    xmlFile:iterate(key .. ".hose", function(_, hoseKey)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) spec
        local entry = {}
        if self:loadHoseNode(xmlFile, hoseKey, entry, true) then
            table.insert(spec.hoseNodes, entry)
            entry.index = #spec.hoseNodes
            for _, index in pairs(entry.inputAttacherJointIndices) do
                if spec.hoseNodesByInputAttacher[index] == nil then
                    spec.hoseNodesByInputAttacher[index] = {}
                end
                table.insert(spec.hoseNodesByInputAttacher[index], entry)
            end
        end
    end)
    xmlFile:iterate(key .. ".localHose", function(_, hoseKey)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) spec
        local hose = {}
        if self:loadHoseNode(xmlFile, hoseKey .. ".hose", hose, false) then
            local target = {}
            if self:loadHoseTargetNode(xmlFile, hoseKey .. ".target", target) then
                table.insert(spec.localHoseNodes, {
                    ["hose"] = hose,
                    ["target"] = target
                })
            end
        end
    end)
    self:loadCustomHosesFromXML(true, spec.customHoses, spec.customHosesByAttacher, spec.customHosesByInputAttacher, xmlFile, key .. ".customHose")
    self:loadCustomHosesFromXML(false, spec.customHoseTargets, spec.customHoseTargetsByAttacher, spec.customHoseTargetsByInputAttacher, xmlFile, key .. ".customTarget")
end
function ConnectionHoses:loadHoseSkipNode(xmlFile, targetKey, entry)
    entry.node = xmlFile:getValue(targetKey .. "#node", nil, self.components, self.i3dMappings)
    if entry.node == nil then
        Logging.xmlWarning(xmlFile, "Missing node for hose skip node \'%s\'", targetKey)
        return false
    end
    entry.inputAttacherJointIndex = xmlFile:getValue(targetKey .. "#inputAttacherJointIndex", 1)
    entry.attacherJointIndex = xmlFile:getValue(targetKey .. "#attacherJointIndex", 1)
    entry.type = xmlFile:getValue(targetKey .. "#type")
    entry.specType = xmlFile:getValue(targetKey .. "#specType")
    if entry.type == nil then
        Logging.xmlWarning(xmlFile, "Missing type for hose skip node \'%s\'", targetKey)
        return false
    end
    entry.length = xmlFile:getValue(targetKey .. "#length")
    entry.isTwoPointHose = xmlFile:getValue(targetKey .. "#isTwoPointHose", false)
    entry.objectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, targetKey, entry.objectChanges, self.components, self)
    ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty, true)
    entry.objectChangesTarget = self
    entry.isSkipNode = true
    return true
end
function ConnectionHoses:loadToolConnectorHoseNode(xmlFile, targetKey, entry)
    local spec = self.spec_connectionHoses
    entry.startTargetNodeIndex = self:addHoseTargetNodes(xmlFile, (string.format("%s.startTarget", targetKey)))
    if entry.startTargetNodeIndex == nil then
        Logging.xmlWarning(xmlFile, "startTarget is missing for tool connection hose \'%s\'", targetKey)
        return false
    end
    entry.endTargetNodeIndex = self:addHoseTargetNodes(xmlFile, (string.format("%s.endTarget", targetKey)))
    if entry.endTargetNodeIndex == nil then
        Logging.xmlWarning(xmlFile, "endTarget is missing for tool connection hose \'%s\'", targetKey)
        return false
    end
    local startTarget = spec.targetNodes[entry.startTargetNodeIndex]
    for index, _ in pairs(startTarget.attacherJointIndices) do
        if spec.targetNodes[entry.endTargetNodeIndex].attacherJointIndices[index] ~= nil then
            Logging.xmlWarning(xmlFile, "Double usage of attacher joint index \'%d\' in \'%s\'", index, targetKey)
        end
    end
    entry.moveNodes = xmlFile:getValue(targetKey .. "#moveNodes", true)
    entry.additionalHose = xmlFile:getValue(targetKey .. "#additionalHose", true)
    if entry.moveNodes then
        local x1, y1, z1 = getTranslation(startTarget.node)
        local index, _, z2 = getTranslation(endTarget.node)
        local dirX, dirY, dirZ = MathUtil.vector3Normalize(x1 - index, y1 - _, z1 - z2)
        local upX, upY, upZ = localDirectionToLocal(endTarget.node, getParent(endTarget.node), 0, 1, 0)
        if (dirX ~= 0 or (dirY ~= 0 or dirZ ~= 0)) and not (MathUtil.isNan(dirX) or (MathUtil.isNan(dirY) or MathUtil.isNan(dirZ))) then
            setDirection(startTarget.node, -dirX, -dirY, -dirZ, upX, upY, upZ)
            setDirection(endTarget.node, dirX, dirY, dirZ, upX, upY, upZ)
        end
    end
    entry.mountingNode = xmlFile:getValue(targetKey .. "#mountingNode", nil, self.components, self.i3dMappings)
    if entry.mountingNode ~= nil then
        setVisibility(entry.mountingNode, false)
    end
    entry.objectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, targetKey, entry.objectChanges, self.components, self)
    ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty, true)
    entry.objectChangesTarget = self
    local x1 = spec.targetNodes[entry.startTargetNodeIndex].type .. (spec.targetNodes[entry.startTargetNodeIndex].specType or "")
    if spec.numToolConnectionsByType[x1] == nil then
        spec.numToolConnectionsByType[x1] = 0
    end
    spec.numToolConnectionsByType[x1] = spec.numToolConnectionsByType[x1] + 1
    entry.typedIndex = spec.numToolConnectionsByType[x1]
    entry.connected = false
    return true
end
function ConnectionHoses:addHoseTargetNodes(xmlFile, key)
    local spec = self.spec_connectionHoses
    local addedTarget = false
    xmlFile:iterate(key, function(_, targetKey)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) spec, (ref) addedTarget
        local entry = {}
        if self:loadHoseTargetNode(xmlFile, targetKey, entry) then
            table.insert(spec.targetNodes, entry)
            entry.index = #spec.targetNodes
            if spec.targetNodesByType[entry.type] == nil then
                spec.targetNodesByType[entry.type] = {}
            end
            table.insert(spec.targetNodesByType[entry.type], entry)
            addedTarget = true
        end
    end)
    return addedTarget and #spec.targetNodes or nil
end
function ConnectionHoses:loadCustomHosesFromXML(isHose, targetTable, attacherJointMapping, inputAttacherJointMapping, xmlFile, key)
    xmlFile:iterate(key, function(_, customKey)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) inputAttacherJointMapping, (copy) attacherJointMapping, (copy) isHose, (copy) targetTable
        local entry = {
            ["node"] = xmlFile:getValue(customKey .. "#node", nil, self.components, self.i3dMappings)
        }
        if entry.node == nil then
            Logging.xmlWarning(xmlFile, "Missing node for custom hose \'%s\'", customKey)
            return
        else
            entry.type = xmlFile:getValue(customKey .. "#type")
            if entry.type == nil then
                Logging.xmlWarning(xmlFile, "Missing type for custom hose \'%s\'", customKey)
            else
                entry.type = string.upper(entry.type)
                entry.inputAttacherJointIndices = {}
                local inputAttacherJointIndices = xmlFile:getValue(customKey .. "#inputAttacherJointIndices", nil, true)
                if inputAttacherJointIndices ~= nil then
                    for _, v in ipairs(inputAttacherJointIndices) do
                        entry.inputAttacherJointIndices[v] = v
                        if inputAttacherJointMapping[v] == nil then
                            inputAttacherJointMapping[v] = {}
                        end
                        table.insert(inputAttacherJointMapping[v], entry)
                    end
                end
                entry.attacherJointIndices = {}
                local attacherJointIndices = xmlFile:getValue(customKey .. "#attacherJointIndices", nil, true)
                if attacherJointIndices ~= nil then
                    for v, v in ipairs(attacherJointIndices) do
                        entry.attacherJointIndices[v] = v
                        if attacherJointMapping[v] == nil then
                            attacherJointMapping[v] = {}
                        end
                        table.insert(attacherJointMapping[v], entry)
                    end
                end
                if isHose then
                    entry.isActiveDirty = xmlFile:getValue(customKey .. "#isActiveDirty", false)
                    if entry.isActiveDirty then
                        table.insert(self.spec_connectionHoses.customHosesActiveDirty, entry)
                    end
                    entry.startTranslation = { getTranslation(entry.node) }
                    entry.startRotation = { getRotation(entry.node) }
                end
                if next(entry.inputAttacherJointIndices) == nil and next(entry.attacherJointIndices) == nil then
                    Logging.xmlWarning(xmlFile, "Missing inputAttacherJointIndices for custom hose \'%s\'", customKey)
                    return false
                end
                entry.objectChanges = {}
                ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, customKey, entry.objectChanges, self.components, self)
                ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty, true)
                entry.objectChangesTarget = self
                entry.isActive = false
                table.insert(targetTable, entry)
            end
        end
    end)
end
function ConnectionHoses:loadHoseTargetNode(xmlFile, targetKey, entry)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, targetKey .. "#socketColor", targetKey .. "#socketMaterialTemplateName")
    entry.node = xmlFile:getValue(targetKey .. "#node", nil, self.components, self.i3dMappings)
    if entry.node == nil then
        Logging.xmlWarning(xmlFile, "Missing node for connection hose target \'%s\'", targetKey)
        return false
    end
    entry.attacherJointIndices = {}
    local attacherJointIndices = xmlFile:getValue(targetKey .. "#attacherJointIndices", nil, true)
    if attacherJointIndices ~= nil then
        for _, attacherJointIndex in ipairs(attacherJointIndices) do
            entry.attacherJointIndices[attacherJointIndex] = attacherJointIndex
        end
    end
    local attacherJointNodes = xmlFile:getValue(targetKey .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
    if attacherJointNodes ~= nil then
        for attacherJointIndex, node in ipairs(attacherJointNodes) do
            entry.attacherJointIndices[attacherJointIndex] = self:getAttacherJointIndexByNode(node) or entry.attacherJointIndices[attacherJointIndex]
        end
    end
    entry.type = xmlFile:getValue(targetKey .. "#type")
    entry.specType = xmlFile:getValue(targetKey .. "#specType")
    entry.straighteningFactor = xmlFile:getValue(targetKey .. "#straighteningFactor", 1)
    entry.straighteningDirection = xmlFile:getValue(targetKey .. "#straighteningDirection", nil, true)
    local socketName = xmlFile:getValue(targetKey .. "#socket")
    if socketName ~= nil then
        local socketMaterial = xmlFile:getValue(targetKey .. "#socketMaterialTemplateName", nil, self.customEnvironment)
        entry.socket = g_connectionHoseManager:linkSocketToNode(socketName, entry.node, self.customEnvironment, socketMaterial)
    end
    if entry.type == nil then
        Logging.xmlWarning(xmlFile, "Missing type for \'%s\'", targetKey)
        return false
    end
    entry.adapterName = xmlFile:getValue(targetKey .. "#adapterType", "DEFAULT")
    if entry.adapter == nil then
        entry.adapter = {}
        entry.adapter.node = entry.node
        entry.adapter.refNode = entry.node
    end
    entry.objectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, targetKey, entry.objectChanges, self.components, self)
    ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty, true)
    return true
end
function ConnectionHoses:loadHoseNode(xmlFile, hoseKey, entry, isBaseHose)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, hoseKey .. "#color", hoseKey .. "#materialTemplateName")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, hoseKey .. "#socketColor", hoseKey .. "#socketMaterialTemplateName")
    entry.inputAttacherJointIndices = {}
    local inputAttacherJointIndices = xmlFile:getValue(hoseKey .. "#inputAttacherJointIndices", nil, true)
    if inputAttacherJointIndices ~= nil then
        for _, inputAttacherJointIndex in ipairs(inputAttacherJointIndices) do
            entry.inputAttacherJointIndices[inputAttacherJointIndex] = inputAttacherJointIndex
        end
    end
    local inputAttacherJointNodes = xmlFile:getValue(hoseKey .. "#inputAttacherJointNodes", nil, self.components, self.i3dMappings, true)
    if inputAttacherJointNodes ~= nil then
        for inputAttacherJointIndex, node in ipairs(inputAttacherJointNodes) do
            entry.inputAttacherJointIndices[inputAttacherJointIndex] = self:getInputAttacherJointIndexByNode(node) or entry.inputAttacherJointIndices[inputAttacherJointIndex]
        end
    end
    entry.type = xmlFile:getValue(hoseKey .. "#type")
    entry.specType = xmlFile:getValue(hoseKey .. "#specType")
    if entry.type == nil then
        Logging.xmlWarning(xmlFile, "Missing type attribute in \'%s\'", hoseKey)
        return false
    end
    entry.hoseType = xmlFile:getValue(hoseKey .. "#hoseType", "DEFAULT")
    entry.node = xmlFile:getValue(hoseKey .. "#node", nil, self.components, self.i3dMappings)
    if entry.node == nil then
        Logging.xmlWarning(xmlFile, "Missing node for connection hose \'%s\'", hoseKey)
        return false
    end
    if isBaseHose then
        local spec = self.spec_connectionHoses
        local type = entry.type .. (entry.specType or "")
        if spec.numHosesByType[type] == nil then
            spec.numHosesByType[type] = 0
        end
        spec.numHosesByType[type] = spec.numHosesByType[type] + 1
        entry.typedIndex = spec.numHosesByType[type]
    end
    entry.isTwoPointHose = xmlFile:getValue(hoseKey .. "#isTwoPointHose", false)
    entry.isWorldSpaceHose = xmlFile:getValue(hoseKey .. "#isWorldSpaceHose", true)
    entry.component = self:getParentComponent(entry.node)
    entry.lastVelY = 0
    entry.lastVelZ = 0
    entry.dampingRange = xmlFile:getValue(hoseKey .. "#dampingRange", 0.05)
    entry.dampingFactor = xmlFile:getValue(hoseKey .. "#dampingFactor", 50)
    entry.length = xmlFile:getValue(hoseKey .. "#length", 3)
    entry.dynamicLength = xmlFile:getValue(hoseKey .. "#dynamicLength", false)
    entry.diameter = xmlFile:getValue(hoseKey .. "#diameter", 0.02)
    entry.straighteningFactor = xmlFile:getValue(hoseKey .. "#straighteningFactor", 1)
    entry.centerPointDropFactor = xmlFile:getValue(hoseKey .. "#centerPointDropFactor", 1)
    entry.centerPointTension = xmlFile:getValue(hoseKey .. "#centerPointTension", 0)
    entry.minCenterPointAngle = xmlFile:getValue(hoseKey .. "#minCenterPointAngle")
    entry.minCenterPointOffset = xmlFile:getValue(hoseKey .. "#minCenterPointOffset", nil, true)
    entry.maxCenterPointOffset = xmlFile:getValue(hoseKey .. "#maxCenterPointOffset", nil, true)
    if entry.minCenterPointOffset ~= nil and entry.maxCenterPointOffset ~= nil then
        for _ = 1, 3 do
            if entry.minCenterPointOffset[_] == 0 then
                entry.minCenterPointOffset[_] = -math.huge
            end
            if entry.maxCenterPointOffset[_] == 0 then
                entry.maxCenterPointOffset[_] = math.huge
            end
        end
        for _ = 1, 3 do
            if entry.maxCenterPointOffset[_] < entry.minCenterPointOffset[_] or entry.minCenterPointOffset[_] > entry.maxCenterPointOffset[_] then
                entry.minCenterPointOffset = nil
                entry.maxCenterPointOffset = nil
                Logging.xmlWarning(xmlFile, "Invalid centerPointOffset in \'%s\'. Max is smaller than min or min is greater than max.", hoseKey)
                break
            end
        end
    end
    entry.minDeltaY = xmlFile:getValue(hoseKey .. "#minDeltaY", math.huge)
    entry.minDeltaYComponent = xmlFile:getValue(hoseKey .. "#minDeltaYComponent", entry.component, self.components, self.i3dMappings)
    entry.material = xmlFile:getValue(hoseKey .. "#materialTemplateName", nil, self.customEnvironment)
    entry.adapterMaterial = xmlFile:getValue(hoseKey .. "#adapterMaterialTemplateName", nil, self.customEnvironment)
    entry.adapterName = xmlFile:getValue(hoseKey .. "#adapterType")
    entry.outgoingAdapter = xmlFile:getValue(hoseKey .. "#outgoingAdapter")
    entry.adapterNode = xmlFile:getValue(hoseKey .. "#adapterNode", nil, self.components, self.i3dMappings)
    if entry.adapterNode ~= nil then
        local spec = g_connectionHoseManager:getClonedAdapterNode(entry.type, entry.adapterName or "DEFAULT", self.customEnvironment, true)
        if spec == nil then
            Logging.xmlWarning(xmlFile, "Unable to find detached adapter for type \'%s\' in \'%s\'", entry.adapterName or "DEFAULT", hoseKey)
        else
            if entry.adapterMaterial ~= nil then
                entry.adapterMaterial:apply(spec, "connector_color_mat")
            end
            link(entry.adapterNode, spec)
        end
    end
    local spec = xmlFile:getValue(hoseKey .. "#socket")
    if spec ~= nil then
        local type = xmlFile:getValue(hoseKey .. "#socketMaterialTemplateName", nil, self.customEnvironment)
        entry.socket = g_connectionHoseManager:linkSocketToNode(spec, entry.node, self.customEnvironment, type)
        if entry.socket ~= nil then
            setRotation(entry.socket.node, 0, 3.141592653589793, 0)
        end
    end
    local type, _, inputAttacherJointIndex, node = g_connectionHoseManager:getClonedHoseNode(entry.type, entry.hoseType, entry.length, entry.diameter, entry.material, self.customEnvironment)
    if type == nil then
        Logging.xmlWarning(xmlFile, "Unable to find connection hose with length \'%.2f\' and diameter \'%.2f\' in \'%s\'", entry.length, entry.diameter, hoseKey)
        return false
    end
    local rx = g_connectionHoseManager:getSocketTarget(entry.socket, entry.node)
    local ry = 0
    local node
    if entry.outgoingAdapter == nil then
        node = type
    else
        local referenceNode
        node, referenceNode = g_connectionHoseManager:getClonedAdapterNode(entry.type, entry.outgoingAdapter, self.customEnvironment)
        if node == nil then
            Logging.xmlWarning(xmlFile, "Unable to find adapter type \'%s\' in \'%s\'", entry.outgoingAdapter, hoseKey)
            node = type
        else
            if entry.adapterMaterial ~= nil then
                entry.adapterMaterial:apply(node, "connector_color_mat")
            end
            link(rx, node)
            if entry.socket == nil then
                setRotation(node, 0, 3.141592653589793, 0)
                rx = referenceNode
            else
                rx = referenceNode
            end
        end
    end
    link(rx, type)
    setTranslation(type, 0, 0, 0)
    setRotation(type, 0, ry, 0)
    entry.hoseNode = type
    entry.visibilityNode = node
    entry.startStraightening = _ * entry.straighteningFactor
    entry.endStraightening = inputAttacherJointIndex
    entry.endStraighteningBase = inputAttacherJointIndex
    entry.endStraighteningDirectionBase = { 0, 0, 1 }
    entry.endStraighteningDirection = entry.endStraighteningDirectionBase
    entry.minCenterPointAngle = entry.minCenterPointAngle or node
    setVisibility(entry.visibilityNode, false)
    entry.objectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, hoseKey, entry.objectChanges, self.components, self)
    ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty, true)
    return true
end
function ConnectionHoses:getClonedSkipHoseNode(sourceHose, skipNode)
    local clonedHose = {
        ["isClonedSkipNodeHose"] = true,
        ["type"] = sourceHose.type,
        ["specType"] = sourceHose.specType,
        ["hoseType"] = sourceHose.hoseType,
        ["node"] = skipNode.node,
        ["component"] = self:getParentComponent(skipNode.node),
        ["lastVelY"] = 0,
        ["lastVelZ"] = 0,
        ["dampingRange"] = 0.05,
        ["dampingFactor"] = 50,
        ["minDeltaYComponent"] = self:getParentComponent(skipNode.node),
        ["minDeltaY"] = math.huge,
        ["length"] = skipNode.length or sourceHose.length,
        ["diameter"] = sourceHose.diameter,
        ["isTwoPointHose"] = skipNode.isTwoPointHose,
        ["material"] = sourceHose.material
    }
    local hose, startStraightening, endStraightening, minCenterPointAngle = g_connectionHoseManager:getClonedHoseNode(clonedHose.type, clonedHose.hoseType, clonedHose.length, clonedHose.diameter, clonedHose.material, self.customEnvironment)
    if hose == nil then
        Logging.xmlWarning(self.xmlFile, "Unable to find connection hose with length \'%.2f\' and diameter \'%.2f\' in \'%s\'", clonedHose.length, clonedHose.diameter, "skipHoseClone")
        return false
    end
    link(clonedHose.node, hose)
    setTranslation(hose, 0, 0, 0)
    setRotation(hose, 0, 0, 0)
    clonedHose.hoseNode = hose
    clonedHose.visibilityNode = hose
    clonedHose.startStraightening = startStraightening
    clonedHose.endStraightening = endStraightening
    clonedHose.endStraighteningBase = endStraightening
    clonedHose.endStraighteningDirectionBase = { 0, 0, 1 }
    clonedHose.endStraighteningDirection = clonedHose.endStraighteningDirectionBase
    clonedHose.minCenterPointAngle = minCenterPointAngle
    setVisibility(clonedHose.visibilityNode, false)
    clonedHose.objectChanges = {}
    return clonedHose
end
function ConnectionHoses:getConnectionTarget(attacherJointIndex, type, specType, excludeToolConnections)
    local spec = self.spec_connectionHoses
    if #spec.targetNodes == 0 and #spec.hoseSkipNodes == 0 then
        return nil
    end
    local nodes = spec.targetNodesByType[type]
    if nodes ~= nil then
        for _, node in ipairs(nodes) do
            if node.attacherJointIndices[attacherJointIndex] ~= nil and (node.specType == specType and not self:getIsConnectionTargetUsed(node)) then
                local toolConnectionHose = spec.targetNodeToToolConnection[node.index]
                if toolConnectionHose == nil or (excludeToolConnections == nil or (not excludeToolConnections or toolConnectionHose.delayedMounting ~= nil)) then
                    return node, false
                else
                    return nil
                end
            end
        end
    end
    local nodes = spec.hoseSkipNodeByType[type]
    if nodes ~= nil then
        for _, node in ipairs(nodes) do
            if node.specType == specType and self:getIsSkipNodeAvailable(node) then
                return node, true
            end
        end
    end
    return nil
end
function ConnectionHoses:iterateConnectionTargets(func, attacherJointIndex, type, specType, excludeToolConnections)
    local spec = self.spec_connectionHoses
    if #spec.targetNodes == 0 and #spec.hoseSkipNodes == 0 then
        return nil
    end
    local nodes = spec.targetNodesByType[type]
    if nodes ~= nil then
        for _, node in ipairs(nodes) do
            if node.attacherJointIndices[attacherJointIndex] ~= nil and (node.specType == specType and not self:getIsConnectionTargetUsed(node)) then
                local toolConnectionHose = spec.targetNodeToToolConnection[node.index]
                if toolConnectionHose ~= nil and (excludeToolConnections ~= nil and (excludeToolConnections and toolConnectionHose.delayedMounting == nil)) then
                    return nil
                end
                if not func(node, false) then
                    break
                end
            end
        end
    end
    local nodes = spec.hoseSkipNodeByType[type]
    if nodes ~= nil then
        for _, node in ipairs(nodes) do
            if node.specType == specType and (self:getIsSkipNodeAvailable(node) and not func(node, true)) then
                break
            end
        end
    end
    return nil
end
function ConnectionHoses.getIsConnectionTargetUsed(_, desc)
    return desc.connectedObject ~= nil
end
function ConnectionHoses.getIsConnectionHoseUsed(_, desc)
    return desc.connectedObject ~= nil
end
function ConnectionHoses:getIsSkipNodeAvailable(skipNode)
    if self.getAttacherVehicle == nil then
        return false
    end
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle ~= nil then
        local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(self)
        if attacherVehicle:getImplementFromAttacherJointIndex(attacherJointIndex).inputJointDescIndex == skipNode.inputAttacherJointIndex then
            return attacherVehicle:getConnectionTarget(attacherJointIndex, skipNode.type, skipNode.specType, true) ~= nil and skipNode.parentHose ~= nil
        end
    end
    return false
end
function ConnectionHoses:getConnectionHosesByInputAttacherJoint(inputJointDescIndex)
    local spec = self.spec_connectionHoses
    return spec.hoseNodesByInputAttacher[inputJointDescIndex] == nil and {} or spec.hoseNodesByInputAttacher[inputJointDescIndex]
end
function ConnectionHoses:connectHose(sourceHose, targetObject, targetHose, updateToolConnections)
    local spec = self.spec_connectionHoses
    local doConnect = false
    if updateToolConnections == nil or updateToolConnections then
        if targetObject:updateToolConnectionHose(self, sourceHose, targetObject, targetHose, true) then
            doConnect = true
        else
            targetObject:addHoseToDelayedMountings(self, sourceHose, targetObject, targetHose)
        end
    else
        doConnect = true
    end
    if not doConnect then
        return false
    end
    targetHose.connectedObject = self
    sourceHose.connectedObject = targetObject
    sourceHose.targetHose = targetHose
    local node = nil
    local referenceNode = nil
    if sourceHose.adapterName == nil then
        if targetHose.adapterName ~= "NONE" then
            node, referenceNode = g_connectionHoseManager:getClonedAdapterNode(targetHose.type, targetHose.adapterName, self.customEnvironment)
        end
    elseif sourceHose.adapterName ~= "NONE" then
        node, referenceNode = g_connectionHoseManager:getClonedAdapterNode(targetHose.type, sourceHose.adapterName, self.customEnvironment)
    end
    if node ~= nil then
        if sourceHose.adapterMaterial ~= nil then
            sourceHose.adapterMaterial:apply(node, "connector_color_mat")
        end
        link(g_connectionHoseManager:getSocketTarget(targetHose.socket, targetHose.node), node)
        setTranslation(node, 0, 0, 0)
        setRotation(node, 0, 0, 0)
        targetObject:addAllSubWashableNodes(node)
        targetHose.adapter.node = node
        targetHose.adapter.refNode = referenceNode
        targetHose.adapter.isLinked = true
    end
    sourceHose.targetNode = targetHose.adapter.refNode
    setVisibility(sourceHose.visibilityNode, true)
    setShaderParameter(sourceHose.hoseNode, "cv0", 0, 0, -sourceHose.startStraightening, 1, false)
    sourceHose.endStraightening = sourceHose.endStraighteningBase * targetHose.straighteningFactor
    sourceHose.endStraighteningDirection = targetHose.straighteningDirection or sourceHose.endStraighteningDirectionBase
    if sourceHose.dynamicLength then
        local hoseType = g_connectionHoseManager:getHoseTypeByName(sourceHose.type, self.customEnvironment)
        if hoseType ~= nil then
            local material = g_connectionHoseManager:getHoseMaterialByName(hoseType, sourceHose.hoseType, self.customEnvironment)
            if material ~= nil then
                local realLength, _, _, _ = getShaderParameter(sourceHose.hoseNode, "lengthAndDiameter")
                local actualLength = calcDistanceFrom(sourceHose.hoseNode, sourceHose.targetNode)
                setShaderParameter(sourceHose.hoseNode, "uvScale", actualLength / realLength * material.uvLengthScale, nil, nil, nil, false)
            end
        end
    end
    ObjectChangeUtil.setObjectChanges(targetHose.objectChanges, true, sourceHose.connectedObject, sourceHose.connectedObject.setMovingToolDirty)
    ObjectChangeUtil.setObjectChanges(sourceHose.objectChanges, true, targetHose.connectedObject, targetHose.connectedObject.setMovingToolDirty)
    g_connectionHoseManager:openSocket(sourceHose.socket)
    g_connectionHoseManager:openSocket(targetHose.socket)
    self:updateConnectionHose(sourceHose, 0)
    if self.isClient then
        local hoseType = spec.samples.connect[sourceHose.type]
        if hoseType ~= nil and not g_soundManager:getIsSamplePlaying(hoseType) then
            g_soundManager:playSample(hoseType)
        end
    end
    local material = spec.updateableHoses
    table.insert(material, sourceHose)
    return true
end
function ConnectionHoses:disconnectHose(hose)
    local target = hose.targetHose
    if target ~= nil then
        hose.connectedObject:updateToolConnectionHose(self, hose, hose.connectedObject, target, false)
        local hoseHasSkipNodeTarget = false
        if target.isSkipNode ~= nil then
            hoseHasSkipNodeTarget = target.isSkipNode
        end
        local hoseIsFromSkipNodeTarget = false
        if hose.isClonedSkipNodeHose ~= nil then
            hoseIsFromSkipNodeTarget = hose.isClonedSkipNodeHose
        end
        if hoseHasSkipNodeTarget or hoseIsFromSkipNodeTarget then
            if hose.parentVehicle ~= nil and hose.parentHose ~= nil then
                hose.parentHose.childVehicle = nil
                hose.parentHose.childHose = nil
                hose.parentVehicle:disconnectHose(hose.parentHose)
            end
            if hose.childVehicle ~= nil and hose.childHose ~= nil then
                hose.childHose.parentVehicle = nil
                hose.childHose.parentHose = nil
                hose.childVehicle:disconnectHose(hose.childHose)
            end
            target.parentHose = nil
        end
        if target.adapter ~= nil and (target.adapter.isLinked ~= nil and target.adapter.isLinked) then
            hose.connectedObject:removeAllSubWashableNodes(target.adapter.node)
            delete(target.adapter.node)
            target.adapter.node = target.node
            target.adapter.refNode = target.node
            target.adapter.isLinked = false
        end
        setVisibility(hose.visibilityNode, false)
        ObjectChangeUtil.setObjectChanges(target.objectChanges, false, hose.connectedObject, hose.connectedObject.setMovingToolDirty)
        ObjectChangeUtil.setObjectChanges(hose.objectChanges, false, target.connectedObject, target.connectedObject.setMovingToolDirty)
        g_connectionHoseManager:closeSocket(hose.socket)
        g_connectionHoseManager:closeSocket(target.socket)
        target.connectedObject = nil
        hose.connectedObject = nil
        hose.targetHose = nil
        table.removeElement(self.spec_connectionHoses.updateableHoses, hose)
        if self.isClient then
            local sample = spec.samples.disconnect[hose.type]
            if sample ~= nil and not g_soundManager:getIsSamplePlaying(sample) then
                g_soundManager:playSample(sample)
            end
        end
    end
end
function ConnectionHoses:updateToolConnectionHose(sourceObject, sourceHose, targetObject, targetHose, visibility)
    local spec = self.spec_connectionHoses
    local toolConnectionHose = spec.targetNodeToToolConnection[targetHose.index]
    if toolConnectionHose == nil then
        return true
    end
    local opositTargetIndex = toolConnectionHose.startTargetNodeIndex
    if opositTargetIndex == targetHose.index then
        opositTargetIndex = toolConnectionHose.endTargetNodeIndex
    end
    local opositTarget = spec.targetNodes[opositTargetIndex]
    if opositTarget ~= nil then
        if visibility and (toolConnectionHose.delayedMounting ~= nil and toolConnectionHose.delayedMounting.sourceHose.connectedObject == nil) then
            local sameType = false
            if toolConnectionHose.delayedMounting.sourceHose.type == sourceHose.type then
                sameType = toolConnectionHose.delayedMounting.sourceHose.specType == sourceHose.specType
            end
            if toolConnectionHose.delayedMounting.sourceObject ~= sourceObject and sameType then
                local x, y, z = localToLocal(targetHose.node, opositTarget.node, 0, 0, 0)
                local length = MathUtil.vector3Length(x, y, z) - (toolConnectionHose.additionalHoseOffset or 0) * 2
                if toolConnectionHose.additionalHose then
                    local hose, _, _, _ = g_connectionHoseManager:getClonedHoseNode(sourceHose.type, sourceHose.hoseType, length, sourceHose.diameter, sourceHose.material, self.customEnvironment)
                    if hose == nil then
                        return false
                    end
                    link(targetHose.node, hose)
                    setTranslation(hose, 0, 0, toolConnectionHose.additionalHoseOffset or 0)
                    local dirX, dirY, dirZ = localToLocal(hose, opositTarget.node, 0, 0, 0)
                    if dirX ~= 0 or (dirY ~= 0 or dirZ ~= 0) then
                        setDirection(hose, dirX, dirY, dirZ, 0, 0, 1)
                    end
                    local meshLength, diameterScale, _, _ = getShaderParameter(hose, "lengthAndDiameter", 0)
                    setScale(hose, diameterScale, diameterScale, length / meshLength)
                    local materialId = getMaterial(hose, 0)
                    local dirZ = setMaterialCustomShaderVariation(materialId, "uvTransform", false)
                    setMaterial(hose, dirZ, 0)
                    if toolConnectionHose.moveNodes then
                        (function(hose)
                            -- upvalues: (copy) sourceHose
                            if hose.originalNodeTranslation == nil then
                                hose.originalNodeTranslation = { getTranslation(hose.node) }
                            else
                                setTranslation(hose.node, unpack(hose.originalNodeTranslation))
                            end
                            local wx, wy, wz = localToWorld(hose.node, 0, sourceHose.diameter * 0.5, 0)
                            local lx, ly, lz = worldToLocal(getParent(hose.node), wx, wy, wz)
                            setTranslation(hose.node, lx, ly, lz)
                        end)(targetHose)
                        setTargetNodeTranslation(opositTarget)
                    end
                    sourceObject:addAllSubWashableNodes(hose)
                    toolConnectionHose.hoseNode = hose
                    toolConnectionHose.hoseNodeObject = sourceObject
                end
                if toolConnectionHose.additionalHoses ~= nil then
                    for _, dirX in ipairs(toolConnectionHose.additionalHoses) do
                        local dirY = calcDistanceFrom(dirX.startNode, dirX.endNode)
                        local dirZ, meshLength, diameterScale, _ = g_connectionHoseManager:getClonedHoseNode(sourceHose.type, sourceHose.hoseType, dirY, sourceHose.diameter, sourceHose.material, self.customEnvironment)
                        if dirZ ~= nil then
                            link(dirX.startNode, dirZ)
                            setTranslation(dirZ, 0, 0, 0)
                            local _, materialId, dirZ = localToLocal(dirX.endNode, dirX.startNode, 0, 0, 0)
                            if _ ~= 0 or (materialId ~= 0 or dirZ ~= 0) then
                                setDirection(dirZ, _, materialId, dirZ, 0, 0, 1)
                            end
                            local meshLength, diameterScale, _, _ = getShaderParameter(dirZ, "lengthAndDiameter", 0)
                            setScale(dirZ, diameterScale, diameterScale, dirY / meshLength)
                            local materialId = getMaterial(dirZ, 0)
                            local materialId = setMaterialCustomShaderVariation(materialId, "uvTransform", false)
                            setMaterial(dirZ, materialId, 0)
                            sourceObject:addAllSubWashableNodes(dirZ)
                            dirX.hoseNode = dirZ
                            dirX.hoseNodeObject = sourceObject
                        end
                    end
                end
                toolConnectionHose.connected = true
                if toolConnectionHose.mountingNode ~= nil then
                    setVisibility(toolConnectionHose.mountingNode, true)
                end
                ObjectChangeUtil.setObjectChanges(toolConnectionHose.objectChanges, true, toolConnectionHose.objectChangesTarget, toolConnectionHose.objectChangesTarget.setMovingToolDirty)
                if toolConnectionHose.parentToolConnectionHose ~= nil then
                    local hose = toolConnectionHose.parentToolConnectionHose
                    if hose.mountingNode ~= nil then
                        setVisibility(hose.mountingNode, true)
                    end
                    ObjectChangeUtil.setObjectChanges(hose.objectChanges, true, hose.objectChangesTarget, hose.objectChangesTarget.setMovingToolDirty)
                end
                if toolConnectionHose.delayedMounting ~= nil then
                    toolConnectionHose.delayedUnmounting = {}
                    table.insert(toolConnectionHose.delayedUnmounting, toolConnectionHose.delayedMounting)
                    table.insert(toolConnectionHose.delayedUnmounting, {
                        ["sourceObject"] = sourceObject,
                        ["sourceHose"] = sourceHose,
                        ["targetObject"] = targetObject,
                        ["targetHose"] = targetHose
                    })
                    local hose = toolConnectionHose.delayedMounting
                    toolConnectionHose.delayedMounting = nil
                    hose.sourceObject:connectHose(hose.sourceHose, hose.targetObject, hose.targetHose, false)
                    hose.sourceObject:retryHoseSkipNodeConnections(false)
                end
                return true
            end
        elseif toolConnectionHose.connected then
            toolConnectionHose.connected = false
            if toolConnectionHose.hoseNode ~= nil then
                toolConnectionHose.hoseNodeObject:removeAllSubWashableNodes(toolConnectionHose.hoseNode)
                delete(toolConnectionHose.hoseNode)
                toolConnectionHose.hoseNode = nil
                toolConnectionHose.hoseNodeObject = nil
            end
            if toolConnectionHose.additionalHoses ~= nil then
                for y, z in ipairs(toolConnectionHose.additionalHoses) do
                    if z.hoseNode ~= nil then
                        z.hoseNodeObject:removeAllSubWashableNodes(z.hoseNode)
                        delete(z.hoseNode)
                        z.hoseNode = nil
                        z.hoseNodeObject = nil
                    end
                end
            end
            if toolConnectionHose.mountingNode ~= nil then
                setVisibility(toolConnectionHose.mountingNode, false)
            end
            ObjectChangeUtil.setObjectChanges(toolConnectionHose.objectChanges, false, toolConnectionHose.objectChangesTarget, toolConnectionHose.objectChangesTarget.setMovingToolDirty)
            if toolConnectionHose.parentToolConnectionHose ~= nil then
                local differentSource = toolConnectionHose.parentToolConnectionHose
                if not differentSource.connected then
                    if differentSource.mountingNode ~= nil then
                        setVisibility(differentSource.mountingNode, false)
                    end
                    ObjectChangeUtil.setObjectChanges(differentSource.objectChanges, false, differentSource.objectChangesTarget, differentSource.objectChangesTarget.setMovingToolDirty)
                end
            end
            if toolConnectionHose.delayedUnmounting ~= nil then
                for y, z in ipairs(toolConnectionHose.delayedUnmounting) do
                    if sourceHose ~= z.sourceHose then
                        z.sourceObject:disconnectHose(z.sourceHose)
                        if z.sourceHose.isClonedSkipNodeHose == nil or not z.sourceHose.isClonedSkipNodeHose then
                            toolConnectionHose.delayedMounting = z
                        end
                    end
                end
                toolConnectionHose.delayedUnmounting = nil
            end
        end
    end
    return false
end
function ConnectionHoses:addHoseToDelayedMountings(sourceObject, sourceHose, targetObject, targetHose)
    local toolConnectionHose = self.spec_connectionHoses.targetNodeToToolConnection[targetHose.index]
    if toolConnectionHose ~= nil and (toolConnectionHose.delayedMounting == nil or sourceHose.typedIndex == toolConnectionHose.typedIndex) then
        toolConnectionHose.delayedMounting = {
            ["sourceObject"] = sourceObject,
            ["sourceHose"] = sourceHose,
            ["targetObject"] = targetObject,
            ["targetHose"] = targetHose
        }
        if toolConnectionHose.delayedMounting ~= nil then
            self.rootVehicle:retryHoseSkipNodeConnections(true, sourceObject)
        end
    end
end
function ConnectionHoses:connectHoseToSkipNode(sourceHose, targetObject, skipNode, childHose, childVehicle)
    local spec = self.spec_connectionHoses
    skipNode.connectedObject = self
    sourceHose.connectedObject = targetObject
    sourceHose.targetHose = skipNode
    sourceHose.targetNode = skipNode.node
    setVisibility(sourceHose.visibilityNode, true)
    setShaderParameter(sourceHose.hoseNode, "cv0", 0, 0, -sourceHose.startStraightening, 1, false)
    ObjectChangeUtil.setObjectChanges(sourceHose.objectChanges, true, self, self.setMovingToolDirty)
    ObjectChangeUtil.setObjectChanges(skipNode.objectChanges, true, self, self.setMovingToolDirty)
    self:addAllSubWashableNodes(sourceHose.hoseNode)
    sourceHose.childVehicle = childVehicle
    sourceHose.childHose = childHose
    if self.getAttacherVehicle ~= nil then
        local attacherVehicle1 = self:getAttacherVehicle()
        if attacherVehicle1.getAttacherVehicle ~= nil then
            local attacherVehicle2 = attacherVehicle1:getAttacherVehicle()
            if attacherVehicle2 ~= nil then
                local attacherJointIndex = attacherVehicle2:getAttacherJointIndexFromObject(attacherVehicle1)
                if attacherVehicle2:getImplementFromAttacherJointIndex(attacherJointIndex).inputJointDescIndex == skipNode.inputAttacherJointIndex then
                    local firstValidTarget, isSkipNode = attacherVehicle2:getConnectionTarget(attacherJointIndex, skipNode.type, skipNode.specType)
                    if firstValidTarget == nil then
                        if skipNode.parentHose ~= nil then
                            sourceHose.parentVehicle = skipNode.parentVehicle
                            sourceHose.parentHose = skipNode.parentHose
                            sourceHose.parentHose.childVehicle = self
                            sourceHose.parentHose.childHose = sourceHose
                        end
                    else
                        local hose = attacherVehicle1:getClonedSkipHoseNode(sourceHose, skipNode)
                        if isSkipNode then
                            attacherVehicle1:connectHoseToSkipNode(hose, attacherVehicle2, firstValidTarget, sourceHose, attacherVehicle1)
                        else
                            attacherVehicle1:connectHose(hose, attacherVehicle2, firstValidTarget)
                        end
                        if skipNode.parentHose ~= nil then
                            skipNode.parentVehicle:removeWashableNode(skipNode.parentHose.hoseNode)
                            delete(skipNode.parentHose.hoseNode)
                            table.removeElement(spec.updateableHoses, skipNode.parentHose.childHose)
                        end
                        skipNode.parentVehicle = attacherVehicle1
                        skipNode.parentHose = hose
                        sourceHose.parentVehicle = attacherVehicle1
                        sourceHose.parentHose = hose
                        hose.childVehicle = self
                        hose.childHose = sourceHose
                        attacherVehicle1:addAllSubWashableNodes(hose.hoseNode)
                    end
                end
            end
        end
    end
    local attacherVehicle2 = spec.updateableHoses
    table.insert(attacherVehicle2, sourceHose)
    return true
end
function ConnectionHoses:connectHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex, updateToolConnections, excludeVehicle)
    if attacherVehicle.getConnectionTarget ~= nil then
        local hoses = self:getConnectionHosesByInputAttacherJoint(inputJointDescIndex)
        for _, hose in ipairs(hoses) do
            local hose
            attacherVehicle:iterateConnectionTargets(function(target, isSkipNode)
                -- upvalues: (copy) self, (copy) hose, (copy) attacherVehicle, (copy) updateToolConnections
                if self:getIsConnectionHoseUsed(hose) then
                    return false
                end
                if isSkipNode then
                    if self:connectHoseToSkipNode(hose, attacherVehicle, target) then
                        return false
                    end
                elseif self:connectHose(hose, attacherVehicle, target, updateToolConnections) then
                    return false
                end
                return true
            end, jointDescIndex, hose.type, hose.specType)
        end
        self:retryHoseSkipNodeConnections(updateToolConnections, excludeVehicle)
    end
end
function ConnectionHoses:retryHoseSkipNodeConnections(updateToolConnections, excludeVehicle)
    if self.getAttachedImplements ~= nil then
        local attachedImplements = self:getAttachedImplements()
        for _, implement in ipairs(attachedImplements) do
            local object = implement.object
            if object ~= excludeVehicle and object.connectHosesToAttacherVehicle ~= nil then
                object:connectHosesToAttacherVehicle(self, implement.inputJointDescIndex, implement.jointDescIndex, updateToolConnections, excludeVehicle)
            end
        end
    end
end
function ConnectionHoses:connectCustomHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex)
    local spec = self.spec_connectionHoses
    local customHoses = spec.customHosesByInputAttacher[inputJointDescIndex]
    if customHoses ~= nil then
        local i = 1
        local customTargets = #customHoses
        for i = i, customTargets do
            local customHose = customHoses[i]
            if not customHose.isActive and attacherVehicle.spec_connectionHoses ~= nil then
                local customTargets = attacherVehicle.spec_connectionHoses.customHoseTargetsByAttacher[jointDescIndex]
                if customTargets ~= nil then
                    local j = 1
                    for j = j, #customTargets do
                        local customTarget = customTargets[j]
                        if not customTarget.isActive and (customHose.type == customTarget.type and customHose.specType == customTarget.specType) then
                            self:connectCustomHoseNode(customHose, customTarget, attacherVehicle)
                        end
                    end
                end
            end
        end
    end
    local customTargets = spec.customHoseTargetsByInputAttacher[inputJointDescIndex]
    if customTargets ~= nil then
        local customHose = 1
        for customHose = customHose, #customTargets do
            local customTargets = customTargets[customHose]
            if not customTargets.isActive and attacherVehicle.spec_connectionHoses ~= nil then
                local customHoses = attacherVehicle.spec_connectionHoses.customHosesByAttacher[jointDescIndex]
                if customHoses ~= nil then
                    local j = 1
                    for j = j, #customHoses do
                        local customTarget = customHoses[j]
                        if not customTarget.isActive and (customTarget.type == customTargets.type and customTarget.specType == customTargets.specType) then
                            self:connectCustomHoseNode(customTarget, customTargets, attacherVehicle)
                        end
                    end
                end
            end
        end
    end
end
function ConnectionHoses:connectCustomHoseNode(customHose, customTarget, targetObject)
    self:updateCustomHoseNode(customHose, customTarget)
    customHose.isActive = true
    customTarget.isActive = true
    customHose.connectedTarget = customTarget
    customHose.connectedObject = targetObject
    customTarget.connectedHose = customHose
    customTarget.connectedObject = self
    ObjectChangeUtil.setObjectChanges(customHose.objectChanges, true, customHose.objectChangesTarget, customHose.objectChangesTarget.setMovingToolDirty)
    ObjectChangeUtil.setObjectChanges(customTarget.objectChanges, true, customTarget.objectChangesTarget, customTarget.objectChangesTarget.setMovingToolDirty)
    if self.setMovingToolDirty ~= nil then
        self:setMovingToolDirty(customHose.node, true)
    end
end
function ConnectionHoses:updateCustomHoseNode(customHose, customTarget)
    setTranslation(customHose.node, localToLocal(customTarget.node, getParent(customHose.node), 0, 0, 0))
    setRotation(customHose.node, localRotationToLocal(customTarget.node, getParent(customHose.node), 0, 0, 0))
    if self.setMovingToolDirty ~= nil then
        self:setMovingToolDirty(customHose.node)
    end
end
function ConnectionHoses:disconnectCustomHoseNode(customHose, customTarget)
    setTranslation(customHose.node, unpack(customHose.startTranslation))
    setRotation(customHose.node, unpack(customHose.startRotation))
    if self.setMovingToolDirty ~= nil then
        self:setMovingToolDirty(customHose.node, true)
    end
    customHose.isActive = false
    customTarget.isActive = false
    customHose.connectedTarget = nil
    customHose.connectedObject = nil
    customTarget.connectedHose = nil
    customTarget.connectedObject = nil
    ObjectChangeUtil.setObjectChanges(customHose.objectChanges, false, customHose.objectChangesTarget, customHose.objectChangesTarget.setMovingToolDirty)
    ObjectChangeUtil.setObjectChanges(customTarget.objectChanges, false, customTarget.objectChangesTarget, customTarget.objectChangesTarget.setMovingToolDirty)
end
function ConnectionHoses:setConnectionHosesActive(connectionHosesActive)
    local spec = self.spec_connectionHoses
    if connectionHosesActive ~= spec.connectionHosesActive then
        spec.connectionHosesActive = connectionHosesActive
        local attacherVehicle = self:getAttacherVehicle()
        if attacherVehicle ~= nil then
            local implement = attacherVehicle:getImplementByObject(self)
            if implement ~= nil then
                if connectionHosesActive then
                    self:connectHosesToAttacherVehicle(attacherVehicle, implement.inputJointDescIndex, implement.jointDescIndex)
                    self:connectCustomHosesToAttacherVehicle(attacherVehicle, implement.inputJointDescIndex, implement.jointDescIndex)
                    return
                end
                ConnectionHoses.onPreDetach(self, attacherVehicle, implement)
            end
        end
    end
end
function ConnectionHoses:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
    if not superFunc(self, xmlFile, baseName, entry) then
        return false
    end
    local customHoseIndices = xmlFile:getValue(baseName .. ".connectionHoses#customHoseIndices", nil, true)
    if customHoseIndices ~= nil and #customHoseIndices > 0 then
        entry.customHoseIndices = customHoseIndices
    end
    local customTargetIndices = xmlFile:getValue(baseName .. ".connectionHoses#customTargetIndices", nil, true)
    if customTargetIndices ~= nil and #customTargetIndices > 0 then
        entry.customTargetIndices = customTargetIndices
    end
    local localHoseIndices = xmlFile:getValue(baseName .. ".connectionHoses#localHoseIndices", nil, true)
    if localHoseIndices ~= nil and #localHoseIndices > 0 then
        entry.localHoseIndices = localHoseIndices
    end
    return true
end
function ConnectionHoses:updateExtraDependentParts(superFunc, part, dt)
    superFunc(self, part, dt)
    if part.customHoseIndices ~= nil then
        local i = 1
        for i = i, #part.customHoseIndices do
            local customHose = self.spec_connectionHoses.customHoses[part.customHoseIndices[i]]
            if customHose ~= nil and customHose.isActive then
                self:updateCustomHoseNode(customHose, customHose.connectedTarget)
            end
        end
    end
    if part.customTargetIndices ~= nil then
        local i = 1
        for i = i, #part.customTargetIndices do
            local customHose = self.spec_connectionHoses.customHoseTargets[part.customTargetIndices[i]]
            if customHose ~= nil and customHose.isActive then
                self:updateCustomHoseNode(customHose.connectedHose, customHose)
            end
        end
    end
    if part.localHoseIndices ~= nil then
        local i = 1
        for i = i, #part.localHoseIndices do
            local customHoseIndex = part.localHoseIndices[i]
            local customHose = self.spec_connectionHoses.localHoseNodes[customHoseIndex]
            if customHose ~= nil and customHose.hose.connectedObject ~= nil then
                self:updateConnectionHose(customHose.hose, customHoseIndex)
            end
        end
    end
end
function ConnectionHoses:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
    if self.spec_connectionHoses.connectionHosesActive then
        self:connectHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex)
        self:connectCustomHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex)
    end
end
function ConnectionHoses:onPreDetach(attacherVehicle, _)
    local spec = self.spec_connectionHoses
    local inputJointDescIndex = self:getActiveInputAttacherJointDescIndex()
    local hoses = self:getConnectionHosesByInputAttacherJoint(inputJointDescIndex)
    for _, hose in ipairs(hoses) do
        self:disconnectHose(hose)
    end
    local i = #spec.updateableHoses
    local attacherVehicleSpec = 1
    local customHoses = -1
    for i = i, attacherVehicleSpec, customHoses do
        local _ = spec.updateableHoses[i]
        if _.connectedObject == attacherVehicle then
            self:disconnectHose(_)
        end
    end
    local attacherVehicleSpec = attacherVehicle.spec_connectionHoses
    if attacherVehicleSpec ~= nil then
        for hose, toolConnector in pairs(attacherVehicleSpec.toolConnectorHoses) do
            if toolConnector.delayedMounting ~= nil and toolConnector.delayedMounting.sourceObject == self then
                toolConnector.delayedMounting = nil
            end
        end
    end
    local customHoses = spec.customHosesByInputAttacher[inputJointDescIndex]
    if customHoses ~= nil then
        local hose = 1
        for hose = hose, #customHoses do
            local toolConnector = customHoses[hose]
            if toolConnector.isActive then
                self:disconnectCustomHoseNode(toolConnector, toolConnector.connectedTarget)
            end
        end
    end
    local i = spec.customHoseTargetsByInputAttacher[inputJointDescIndex]
    if i ~= nil then
        local toolConnector = 1
        for toolConnector = toolConnector, #i do
            local customTarget = i[toolConnector]
            if customTarget.isActive then
                self:disconnectCustomHoseNode(customTarget.connectedHose, customTarget)
            end
        end
    end
end
local ADDITIONAL_TOOL_CONNECTION_HOSES = {
    {
        ["sourceType"] = "TOOL_CONNECTOR_TOP_RIGHT",
        ["name"] = "TOOL_CONNECTOR_TOP_RIGHT_02",
        ["filename"] = "data/shared/connectionHoses/AdditionalTopRightHose.i3d",
        ["sourceLength"] = 3.045
    }
}
local ADDITIONAL_TOOL_CONNECTION_HOSES_XML = {
    {
        ["sourceType"] = "TOOL_CONNECTOR_TOP_RIGHT",
        ["filename"] = "data/shared/connectionHoses/toolConnectionHoseMounts/vaderstadProceedV.xml"
    },
    {
        ["sourceType"] = "TOOL_CONNECTOR_TOP_RIGHT",
        ["filename"] = "data/shared/connectionHoses/toolConnectionHoseMounts/skyProgressTF.xml"
    }
}
function ConnectionHoses:registerAdditionalToolConnectionHoses()
    -- upvalues: (copy) ADDITIONAL_TOOL_CONNECTION_HOSES, (copy) ADDITIONAL_TOOL_CONNECTION_HOSES_XML
    local spec = self.spec_connectionHoses
    local i = 1
    for i = i, #spec.toolConnectorHoses do
        local toolConnectorHose = spec.toolConnectorHoses[i]
        for _, data in pairs(ADDITIONAL_TOOL_CONNECTION_HOSES) do
            if spec.targetNodes[toolConnectorHose.startTargetNodeIndex] ~= nil and (spec.targetNodes[toolConnectorHose.startTargetNodeIndex].type == data.sourceType and (spec.targetNodes[toolConnectorHose.endTargetNodeIndex] ~= nil and (spec.targetNodes[toolConnectorHose.endTargetNodeIndex].type == data.sourceType and calcDistanceFrom(spec.targetNodes[toolConnectorHose.startTargetNodeIndex].node, spec.targetNodes[toolConnectorHose.endTargetNodeIndex].node) > 0))) then
                local sharedLoadRequestId = self:loadSubSharedI3DFile(data.filename, false, false, ConnectionHoses.onAdditionalI3DFileLoaded, self, {
                    ["spec"] = spec,
                    ["startTarget"] = startTarget,
                    ["endTarget"] = endTarget,
                    ["data"] = data
                })
                table.insert(spec.additionalSharedLoadRequestIds, sharedLoadRequestId)
            end
        end
        for _, data in pairs(ADDITIONAL_TOOL_CONNECTION_HOSES_XML) do
            if startTarget ~= nil and (startTarget.type == data.sourceType and (endTarget ~= nil and endTarget.type == data.sourceType)) then
                local length = calcDistanceFrom(startTarget.node, endTarget.node)
                if length > 0 then
                    local arguments = getParent(endTarget.node)
                    local sharedLoadRequestId, y, z = getTranslation(endTarget.node)
                    local rx, ry, rz = getRotation(endTarget.node)
                    local toolConnectionHoseMount = ToolConnectionHoseMount.new(self)
                    toolConnectionHoseMount:setReferenceTargets(startTarget, endTarget)
                    toolConnectionHoseMount:setLinkNode(arguments, sharedLoadRequestId, y, z, rx, ry, rz)
                    toolConnectionHoseMount:setLength(length)
                    toolConnectionHoseMount:setCallback(function(success)
                        -- upvalues: (copy) spec, (copy) toolConnectionHoseMount
                        if success then
                            table.insert(spec.toolConnectionHoseMounts, toolConnectionHoseMount)
                        else
                            toolConnectionHoseMount:delete()
                        end
                    end)
                    toolConnectionHoseMount:loadFromXML(data.filename, self.baseDirectory)
                end
            end
        end
    end
end
local function addHoseTarget(spec, node, sourceTarget, newType)
    local hoseTarget = {
        ["node"] = node,
        ["attacherJointIndices"] = sourceTarget.attacherJointIndices,
        ["type"] = newType,
        ["straighteningFactor"] = sourceTarget.straighteningFactor,
        ["adapterName"] = sourceTarget.adapterName,
        ["adapter"] = {}
    }
    hoseTarget.adapter.node = node
    hoseTarget.adapter.refNode = node
    hoseTarget.objectChanges = {}
    table.insert(spec.targetNodes, hoseTarget)
    hoseTarget.index = #spec.targetNodes
    if spec.targetNodesByType[hoseTarget.type] == nil then
        spec.targetNodesByType[hoseTarget.type] = {}
    end
    table.insert(spec.targetNodesByType[hoseTarget.type], hoseTarget)
    return hoseTarget.index
end
function ConnectionHoses:onAdditionalI3DFileLoaded(node, _, args)
    -- upvalues: (copy) addHoseTarget
    if node ~= 0 then
        local spec = args.spec
        local newMounting = getChildAt(node, 0)
        local newStartNode = getChildAt(newMounting, 1)
        local newEndNode = getChildAt(newMounting, 0)
        link(getParent(args.endTarget.node), newMounting)
        setTranslation(newMounting, getTranslation(args.endTarget.node))
        setRotation(newMounting, getRotation(args.endTarget.node))
        local length = calcDistanceFrom(args.startTarget.node, args.endTarget.node)
        setScale(newMounting, 1, 1, length / args.data.sourceLength)
        setScale(newStartNode, 1, 1, 1 / (length / args.data.sourceLength))
        setScale(newEndNode, 1, 1, 1 / (length / args.data.sourceLength))
        delete(node)
        local newToolConnectionHose = {
            ["startTargetNodeIndex"] = addHoseTarget(spec, newStartNode, args.startTarget, args.data.name),
            ["endTargetNodeIndex"] = addHoseTarget(spec, newEndNode, args.endTarget, args.data.name),
            ["mountingNode"] = newMounting,
            ["moveNodes"] = true,
            ["additionalHose"] = true,
            ["objectChanges"] = {},
            ["objectChangesTarget"] = self
        }
        setVisibility(newMounting, false)
        if getHasShaderParameter(newToolConnectionHose.mountingNode, "colorMat0") then
            newToolConnectionHose.mountingNodeDefaultColor = { getShaderParameter(newToolConnectionHose.mountingNode, "colorMat0") }
        end
        table.insert(args.spec.toolConnectorHoses, newToolConnectionHose)
        args.spec.targetNodeToToolConnection[newToolConnectionHose.startTargetNodeIndex] = newToolConnectionHose
        args.spec.targetNodeToToolConnection[newToolConnectionHose.endTargetNodeIndex] = newToolConnectionHose
    end
end
function ConnectionHoses.consoleCommandTestSockets(vehicle, attacherJointIndex)
    local spec = vehicle.spec_connectionHoses
    if spec ~= nil then
        local colors = {
            ["hydraulicIn"] = Color.new(0, 1, 0),
            ["hydraulicOut"] = Color.new(0, 0, 1),
            ["electric"] = Color.new(1, 0, 1),
            ["airDoubleRed"] = Color.new(1, 0, 0),
            ["airDoubleYellow"] = Color.new(1, 1, 0),
            ["isobus"] = Color.new(1, 1, 1)
        }
        for index, targetHose in ipairs(spec.targetNodes) do
            if targetHose.socket ~= nil then
                g_connectionHoseManager:closeSocket(targetHose.socket)
            end
            if targetHose.debugNode ~= nil then
                delete(targetHose.debugNode)
                targetHose.debugNode = nil
            end
            if targetHose.debugLine ~= nil then
                g_debugManager:removeElement(targetHose.debugLine)
                targetHose.debugLine = nil
            end
            if targetHose.debugText ~= nil then
                g_debugManager:removeElement(targetHose.debugText)
                targetHose.debugText = nil
            end
            if targetHose.objectChanges ~= nil then
                ObjectChangeUtil.setObjectChanges(targetHose.objectChanges, false, vehicle, vehicle.setMovingToolDirty)
            end
            if targetHose.attacherJointIndices[attacherJointIndex] ~= nil then
                if ({})[targetHose.type] == nil then
                    indexByType[targetHose.type] = 0
                end
                indexByType[targetHose.type] = indexByType[targetHose.type] + 1
                if targetHose.socket ~= nil then
                    g_connectionHoseManager:openSocket(targetHose.socket)
                end
                local node, referenceNode = g_connectionHoseManager:getClonedAdapterNode(targetHose.type, "DEFAULT", vehicle.customEnvironment)
                if node ~= nil then
                    local material = VehicleMaterial.new()
                    material:setTemplateName("plasticPainted")
                    material:setColor(1, 1, 1)
                    material:apply(node)
                    link(g_connectionHoseManager:getSocketTarget(targetHose.socket, targetHose.node), node)
                    setTranslation(node, 0, 0, 0)
                    setRotation(node, 0, 0, 0)
                    targetHose.debugNode = node
                    local attacherJointDesc = vehicle:getAttacherJointByJointDescIndex(attacherJointIndex)
                    if attacherJointDesc ~= nil then
                        targetHose.debugLine = DebugLine.new():createWithStartAndEndNode(attacherJointDesc.jointTransform, referenceNode or node, false, true, 100, true)
                        targetHose.debugLine:setColors(colors[targetHose.type], colors[targetHose.type])
                        g_debugManager:addElement(targetHose.debugLine, nil, nil, math.huge)
                        targetHose.debugText = DebugText.new():createWithNode(referenceNode, ({
                            ["hydraulicIn"] = "in",
                            ["hydraulicOut"] = "out",
                            ["electric"] = "e",
                            ["airDoubleRed"] = "red",
                            ["airDoubleYellow"] = "yel",
                            ["isobus"] = "iso"
                        })[targetHose.type] .. tostring(indexByType[targetHose.type]), 0.015, true)
                        targetHose.debugText.color = colors[targetHose.type]
                        g_debugManager:addElement(targetHose.debugText, nil, nil, math.huge)
                    end
                end
                if targetHose.objectChanges ~= nil then
                    ObjectChangeUtil.setObjectChanges(targetHose.objectChanges, true, vehicle, vehicle.setMovingToolDirty)
                end
            end
        end
    end
end
function ConnectionHoses.consoleCommandTestToolConnection(vehicle, toolConnectionIndex)
    local spec = vehicle.spec_connectionHoses
    if spec ~= nil then
        local startColor = Color.new(0, 1, 0)
        local betweenColor = Color.new(0, 0, 1)
        local endColor = Color.new(1, 0, 0)
        for _, targetHose in ipairs(spec.targetNodes) do
            if targetHose.socket ~= nil then
                g_connectionHoseManager:closeSocket(targetHose.socket)
            end
            if targetHose.debugElements ~= nil then
                for _, element in pairs(targetHose.debugElements) do
                    g_debugManager:removeElement(element)
                end
                targetHose.debugElements = nil
            end
            if targetHose.debugText ~= nil then
                g_debugManager:removeElement(targetHose.debugText)
                targetHose.debugText = nil
            end
            if targetHose.objectChanges ~= nil then
                ObjectChangeUtil.setObjectChanges(targetHose.objectChanges, false, vehicle, vehicle.setMovingToolDirty)
            end
        end
        local i = 1
        local toolConnectionHose = #spec.toolConnectorHoses
        local startTarget = 1
        for i = i, toolConnectionHose, startTarget do
            local _ = spec.toolConnectorHoses[i]
            if _.mountingNode ~= nil then
                setVisibility(_.mountingNode, false)
            end
            ObjectChangeUtil.setObjectChanges(_.objectChanges, false, _.objectChangesTarget, _.objectChangesTarget.setMovingToolDirty)
            if _.parentToolConnectionHose ~= nil then
                local targetHose = _.parentToolConnectionHose
                if targetHose.mountingNode ~= nil then
                    setVisibility(targetHose.mountingNode, false)
                end
                ObjectChangeUtil.setObjectChanges(targetHose.objectChanges, false, targetHose.objectChangesTarget, targetHose.objectChangesTarget.setMovingToolDirty)
            end
            if _.debugElements ~= nil then
                for _, _ in pairs(_.debugElements) do
                    g_debugManager:removeElement(_)
                end
                _.debugElements = nil
            end
        end
        local toolConnectionHose = spec.toolConnectorHoses[toolConnectionIndex]
        if toolConnectionHose ~= nil then
            local startTarget = spec.targetNodes[toolConnectionHose.startTargetNodeIndex]
            local i = spec.targetNodes[toolConnectionHose.endTargetNodeIndex]
            for _, _ in pairs(startTarget.attacherJointIndices) do
                local _ = vehicle:getAttacherJointByJointDescIndex(_)
                if _ ~= nil then
                    local element = DebugLine.new():createWithStartAndEndNode(_.jointTransform, startTarget.node, false, false, 100, true)
                    element:setColors(startColor, startColor)
                    g_debugManager:addElement(element, nil, nil, math.huge)
                    local debugText = DebugText.new():createWithNode(_.jointTransform, getName(_.jointTransform), 0.01, true)
                    debugText.color = startColor
                    g_debugManager:addElement(debugText, nil, nil, math.huge)
                    if startTarget.debugElements == nil then
                        startTarget.debugElements = {}
                    end
                    table.insert(startTarget.debugElements, element)
                    table.insert(startTarget.debugElements, debugText)
                end
            end
            for _, _ in pairs(i.attacherJointIndices) do
                local _ = vehicle:getAttacherJointByJointDescIndex(_)
                if _ ~= nil then
                    local element = DebugLine.new():createWithStartAndEndNode(_.jointTransform, i.node, false, false, 100, true)
                    element:setColors(endColor, endColor)
                    g_debugManager:addElement(element, nil, nil, math.huge)
                    local debugText = DebugText.new():createWithNode(_.jointTransform, getName(_.jointTransform), 0.01, true)
                    debugText.color = endColor
                    g_debugManager:addElement(debugText, nil, nil, math.huge)
                    if i.debugElements == nil then
                        i.debugElements = {}
                    end
                    table.insert(i.debugElements, element)
                    table.insert(i.debugElements, debugText)
                end
            end
            local _ = DebugLine.new():createWithStartAndEndNode(startTarget.node, i.node, false, true, 100, true)
            _:setColors(betweenColor, betweenColor)
            g_debugManager:addElement(_, nil, nil, math.huge)
            local targetHose = DebugText.new():createWithNode(startTarget.node, getName(startTarget.node), 0.01, true)
            targetHose.color = startColor
            g_debugManager:addElement(targetHose, nil, nil, math.huge)
            local debugTextEnd = DebugText.new():createWithNode(i.node, getName(i.node), 0.01, true)
            debugTextEnd.color = endColor
            g_debugManager:addElement(debugTextEnd, nil, nil, math.huge)
            if toolConnectionHose.debugElements == nil then
                toolConnectionHose.debugElements = {}
            end
            local _ = toolConnectionHose.debugElements
            table.insert(_, _)
            local _ = toolConnectionHose.debugElements
            table.insert(_, targetHose)
            local _ = toolConnectionHose.debugElements
            table.insert(_, debugTextEnd)
            if toolConnectionHose.mountingNode ~= nil then
                setVisibility(toolConnectionHose.mountingNode, true)
            end
            ObjectChangeUtil.setObjectChanges(toolConnectionHose.objectChanges, true, toolConnectionHose.objectChangesTarget, toolConnectionHose.objectChangesTarget.setMovingToolDirty)
            if toolConnectionHose.parentToolConnectionHose ~= nil then
                local _ = toolConnectionHose.parentToolConnectionHose
                if _.mountingNode ~= nil then
                    setVisibility(_.mountingNode, true)
                end
                ObjectChangeUtil.setObjectChanges(_.objectChanges, true, _.objectChangesTarget, _.objectChangesTarget.setMovingToolDirty)
            end
        end
    end
end