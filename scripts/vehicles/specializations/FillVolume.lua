FillVolume = {}
FillVolume.SEND_NUM_BITS = 6
FillVolume.SEND_MAX_SIZE = 15
FillVolume.SEND_MAX_VALUE = math.pow(2, FillVolume.SEND_NUM_BITS) - 1
FillVolume.SEND_PRECISION = FillVolume.SEND_MAX_SIZE / FillVolume.SEND_MAX_VALUE
function FillVolume.writeStreamCompressedPosition(streamId, position)
    local value = math.clamp((position + FillVolume.SEND_MAX_SIZE * 0.5) / FillVolume.SEND_MAX_SIZE, 0, 1) * FillVolume.SEND_MAX_VALUE
    streamWriteUIntN(streamId, value, FillVolume.SEND_NUM_BITS)
end
function FillVolume.readStreamCompressedPosition(streamId)
    return streamReadUIntN(streamId, FillVolume.SEND_NUM_BITS) / FillVolume.SEND_MAX_VALUE * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
end
function FillVolume.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function FillVolume.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("fillVolume", g_i18n:getText("configuration_fillVolume"), "fillVolume", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("FillVolume")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#node", "Fill volume node")
    schema:register(XMLValueType.INT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#fillUnitIndex", "Fill unit index")
    schema:register(XMLValueType.FLOAT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#fillUnitFactor", "Fill unit factor", 1)
    schema:register(XMLValueType.BOOL, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#useFullCapacity", "Defines if the fill volume represents the full fill unit capacity when multiple fill volumes are given. If set to \'false\' (default), the fill level is split across the defined volumes. If set to \'true\' all fill up the same.", true)
    schema:register(XMLValueType.BOOL, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#allSidePlanes", "All side planes", true)
    schema:register(XMLValueType.BOOL, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#retessellateTop", "Retessellate top plane for better triangulation quality", false)
    schema:register(XMLValueType.STRING, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#defaultFillType", "Default fill type name")
    schema:register(XMLValueType.STRING, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#forcedVolumeFillType", "Forced fill type name")
    schema:register(XMLValueType.FLOAT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#maxDelta", "Max. heap size above above input surface [m]", 1)
    schema:register(XMLValueType.ANGLE, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#maxAllowedHeapAngle", "Max. allowed heap surface slope angle [deg]", 35)
    schema:register(XMLValueType.FLOAT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#maxSurfaceDistanceError", "Max. allowed distance from input mesh surface to created fill plane mesh [m]", 0.05)
    schema:register(XMLValueType.FLOAT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#maxSubDivEdgeLength", "Max. length of sub division edges [m]", 0.9)
    schema:register(XMLValueType.FLOAT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#syncMaxSubDivEdgeLength", "Max. length of sub division edges used to sync in multiplayer [m]", 1.35)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?).deformNode(?)#node", "Deformer node")
    FillVolume.registerInfoNodeXMLPaths(schema, "vehicle.fillVolume.loadInfos.loadInfo(?)")
    FillVolume.registerInfoNodeXMLPaths(schema, "vehicle.fillVolume.unloadInfos.unloadInfo(?)")
    schema:register(XMLValueType.INT, "vehicle.fillVolume.heightNodes.heightNode(?)#fillVolumeIndex", "Fill volume index")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.fillVolume.heightNodes.heightNode(?).refNode(?)#node", "Reference node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#node", "Height node")
    schema:register(XMLValueType.VECTOR_SCALE, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#baseScale", "Base scale", "1 1 1")
    schema:register(XMLValueType.VECTOR_3, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#scaleAxis", "Scale axis", "0 0 0")
    schema:register(XMLValueType.VECTOR_SCALE, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#scaleMax", "Max. scale", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#transAxis", "Translation axis", "0 0 0")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#transMax", "Max. translation", "0 0 0")
    schema:register(XMLValueType.FLOAT, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#minHeight", "Min. fill volume height used for height node", 0)
    schema:register(XMLValueType.FLOAT, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#heightOffset", "Fill plane height offset", 0)
    schema:register(XMLValueType.BOOL, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#orientateToWorldY", "Orientate to world Y", false)
    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. ".fillVolume#fillVolumeIndex", "Fill Unit index which includes the deformers", 1)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".fillVolume#deformerNodeIndices", "Indices of deformer nodes to update")
    end)
    schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. ".fillVolume#fillVolumeIndex", "Fill Unit index which includes the deformers", 1)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".fillVolume#deformerNodeIndices", "Indices of deformer nodes to update")
    end)
    schema:setXMLSpecializationType()
end
function FillVolume.registerInfoNodeXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Info node")
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#width", "Info width", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#length", "Info length", 1)
    schema:register(XMLValueType.INT, basePath .. ".node(?)#fillVolumeHeightIndex", "Fill volume height index")
    schema:register(XMLValueType.INT, basePath .. ".node(?)#priority", "Priority", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#minHeight", "Min. height")
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#maxHeight", "Max. height")
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#minFillLevelPercentage", "Min. fill level percentage")
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#maxFillLevelPercentage", "Min. fill level percentage")
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#heightForTranslation", "Min. height for translation")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".node(?)#translationStart", "Translation start")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".node(?)#translationEnd", "Translation end")
end
function FillVolume.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadFillVolume", FillVolume.loadFillVolume)
    SpecializationUtil.registerFunction(vehicleType, "loadFillVolumeInfo", FillVolume.loadFillVolumeInfo)
    SpecializationUtil.registerFunction(vehicleType, "loadFillVolumeHeightNode", FillVolume.loadFillVolumeHeightNode)
    SpecializationUtil.registerFunction(vehicleType, "getFillVolumeLoadInfo", FillVolume.getFillVolumeLoadInfo)
    SpecializationUtil.registerFunction(vehicleType, "getFillVolumeUnloadInfo", FillVolume.getFillVolumeUnloadInfo)
    SpecializationUtil.registerFunction(vehicleType, "getFillVolumeIndicesByFillUnitIndex", FillVolume.getFillVolumeIndicesByFillUnitIndex)
    SpecializationUtil.registerFunction(vehicleType, "setFillVolumeForcedFillTypeByFillUnitIndex", FillVolume.setFillVolumeForcedFillTypeByFillUnitIndex)
    SpecializationUtil.registerFunction(vehicleType, "setFillVolumeForcedFillType", FillVolume.setFillVolumeForcedFillType)
    SpecializationUtil.registerFunction(vehicleType, "getFillVolumeUVScrollSpeed", FillVolume.getFillVolumeUVScrollSpeed)
end
function FillVolume.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setMovingToolDirty", FillVolume.setMovingToolDirty)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", FillVolume.loadExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", FillVolume.updateExtraDependentParts)
end
function FillVolume.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FillVolume)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", FillVolume)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FillVolume)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FillVolume)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", FillVolume)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", FillVolume)
end
function FillVolume:onLoad(_)
    local spec = self.spec_fillVolume
    local fillVolumeConfigurationId = Utils.getNoNil(self.configurations.fillVolume, 1)
    local configKey = string.format("vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(%d).volumes", fillVolumeConfigurationId - 1)
    spec.volumes = {}
    spec.fillVolumeDeformersByNode = {}
    spec.fillUnitFillVolumeMapping = {}
    self.xmlFile:iterate(configKey .. ".volume", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {}
        if self:loadFillVolume(self.xmlFile, key, entry) then
            table.insert(spec.volumes, entry)
            entry.index = #spec.volumes
        end
    end)
    for _, mapping in ipairs(spec.fillUnitFillVolumeMapping) do
        for _, fillVolume in ipairs(mapping.fillVolumes) do
            if not fillVolume.useFullCapacity then
                fillVolume.fillUnitFactor = fillVolume.fillUnitFactor / mapping.sumFactors
            end
        end
    end
    for _, mapping in ipairs(spec.volumes) do
        mapping.capacity = self:getFillUnitCapacity(mapping.fillUnitIndex) * mapping.fillUnitFactor
        mapping.fillLevel = 0
        mapping.volume = createFillPlaneShape(mapping.baseNode, "fillPlane", mapping.capacity, mapping.maxDelta, mapping.maxSurfaceAngle, mapping.maxPhysicalSurfaceAngle, mapping.maxSurfaceDistanceError, mapping.maxSubDivEdgeLength, mapping.syncMaxSubDivEdgeLength, mapping.allSidePlanes, mapping.retessellateTop)
        if mapping.volume == nil or mapping.volume == 0 then
            printWarning("Warning: fillVolume \'" .. tostring(getName(mapping.baseNode)) .. "\' could not create actual fillVolume in \'" .. self.configFileName .. "\'! Simplifying the mesh could help")
            mapping.volume = nil
        else
            setVisibility(mapping.volume, false)
            local fillVolumeMaterial = 1
            for _ = #mapping.deformers, fillVolumeMaterial, -1 do
                local fillVolume = mapping.deformers[_]
                fillVolume.polyline = findPolyline(mapping.volume, fillVolume.posX, fillVolume.posZ)
                if fillVolume.polyline == nil and fillVolume.polyline ~= -1 then
                    printWarning("Warning: Could not find \'polyline\' for \'" .. tostring(getName(fillVolume.node)) .. "\' in \'" .. self.configFileName .. "\'")
                    table.remove(mapping.deformers, _)
                end
            end
            link(mapping.baseNode, mapping.volume)
            local fillVolumeMaterial = g_materialManager:getBaseMaterialByName("fillPlane")
            if fillVolumeMaterial == nil then
                Logging.error("Failed to assign material to fill volume. Base Material \'fillPlane\' not found!")
            else
                setMaterial(mapping.volume, fillVolumeMaterial, 0)
                g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(mapping.volume, g_terrainNode, true, true, true)
            end
            fillPlaneAdd(mapping.volume, 1, 0, 1, 0, 11, 0, 0, 0, 0, 11)
            mapping.heightOffset = getFillPlaneHeightAtLocalPos(mapping.volume, 0, 0)
            fillPlaneAdd(mapping.volume, -1, 0, 1, 0, 11, 0, 0, 0, 0, 11)
        end
    end
    spec.loadInfos = {}
    self.xmlFile:iterate("vehicle.fillVolume.loadInfos.loadInfo", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {}
        if self:loadFillVolumeInfo(self.xmlFile, key, entry) then
            table.insert(spec.loadInfos, entry)
        end
    end)
    spec.unloadInfos = {}
    self.xmlFile:iterate("vehicle.fillVolume.unloadInfos.unloadInfo", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {}
        if self:loadFillVolumeInfo(self.xmlFile, key, entry) then
            table.insert(spec.unloadInfos, entry)
        end
    end)
    spec.heightNodes = {}
    spec.fillVolumeIndexToHeightNode = {}
    self.xmlFile:iterate("vehicle.fillVolume.heightNodes.heightNode", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local entry = {}
        if self:loadFillVolumeHeightNode(self.xmlFile, key, entry) then
            table.insert(spec.heightNodes, entry)
            if spec.fillVolumeIndexToHeightNode[entry.fillVolumeIndex] == nil then
                spec.fillVolumeIndexToHeightNode[entry.fillVolumeIndex] = {}
            end
            table.insert(spec.fillVolumeIndexToHeightNode[entry.fillVolumeIndex], entry)
        end
    end)
    spec.lastPositionInfo = { 0, 0 }
    spec.lastPositionInfoSent = { 0, 0 }
    spec.availableFillNodes = {}
    spec.dirtyFlag = self:getNextDirtyFlag()
    if not self.isClient or #spec.volumes == 0 and #spec.heightNodes == 0 then
        SpecializationUtil.removeEventListener(self, "onUpdate", FillVolume)
    end
end
function FillVolume:onDelete()
    local spec = self.spec_fillVolume
    if spec.volumes ~= nil then
        for _, fillVolume in ipairs(spec.volumes) do
            if fillVolume.volume ~= nil then
                delete(fillVolume.volume)
            end
            fillVolume.volume = nil
        end
    end
end
function FillVolume:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self.spec_fillVolume.lastPositionInfo[1] = FillVolume.readStreamCompressedPosition(streamId)
            spec.lastPositionInfo[2] = FillVolume.readStreamCompressedPosition(streamId)
        end
    end
end
function FillVolume:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_fillVolume
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
            FillVolume.writeStreamCompressedPosition(streamId, spec.lastPositionInfoSent[1])
            FillVolume.writeStreamCompressedPosition(streamId, spec.lastPositionInfoSent[2])
        end
    end
end
function FillVolume:onUpdate(dt, _, _, _)
    if not self.isClient then
        ::l2::
        return
    end
    local spec = self.spec_fillVolume
    for _, fillVolume in pairs(spec.volumes) do
        for _, deformer in ipairs(fillVolume.deformers) do
            if deformer.isDirty and (deformer.polyline ~= nil and deformer.polyline ~= -1) then
                deformer.isDirty = false
                local posX, posY, posZ = localToLocal(deformer.node, deformer.baseNode, 0, 0, 0)
                local dz = posX - deformer.posX
                if math.abs(dz) > 0.0001 then
                    ::l11::
                    deformer.lastPosX = posX
                    deformer.lastPosZ = posZ
                    setPolylineTranslation(fillVolume.volume, deformer.polyline, posX - deformer.initPos[1], posZ - deformer.initPos[3])
                elseif math.abs(posZ - deformer.posZ) > 0.0001 then
                    goto l11
                end
            end
        end
        local uvScrollSpeedX, uvScrollSpeedY, uvScrollSpeedZ = self:getFillVolumeUVScrollSpeed(fillVolume.index)
        if uvScrollSpeedX ~= 0 or (uvScrollSpeedY ~= 0 or uvScrollSpeedZ ~= 0) then
            fillVolume.uvPosition[1] = fillVolume.uvPosition[1] + uvScrollSpeedX * (dt / 1000)
            fillVolume.uvPosition[2] = fillVolume.uvPosition[2] + uvScrollSpeedY * (dt / 1000)
            fillVolume.uvPosition[3] = fillVolume.uvPosition[3] + uvScrollSpeedZ * (dt / 1000)
            setShaderParameter(fillVolume.volume, "uvOffset", fillVolume.uvPosition[1], fillVolume.uvPosition[2], fillVolume.uvPosition[3], 0, false)
        end
    end
    for _, fillVolume in pairs(spec.heightNodes) do
        if fillVolume.isDirty then
            fillVolume.isDirty = false
            local uvScrollSpeedX = spec.volumes[fillVolume.fillVolumeIndex]
            local uvScrollSpeedY = uvScrollSpeedX.baseNode
            local uvScrollSpeedZ = uvScrollSpeedX.volume
            if uvScrollSpeedY ~= nil and uvScrollSpeedZ ~= nil then
                local _ = math.huge
                local deformer = -math.huge
                local posX = -math.huge
                for dz, refNode in pairs(fillVolume.refNodes) do
                    local x, _, z = localToLocal(refNode.refNode, uvScrollSpeedY, 0, 0, 0)
                    local height = getFillPlaneHeightAtLocalPos(uvScrollSpeedZ, x, z)
                    if not MathUtil.isNan(height) then
                        local height = height - uvScrollSpeedX.heightOffset
                        _ = math.min(_, height)
                        deformer = math.max(deformer, height)
                        local _, yw, _ = localToWorld(uvScrollSpeedY, x, height, z)
                        posX = math.max(posX, yw)
                        if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
                            local wx1, wy1, wz1 = localToWorld(uvScrollSpeedY, x, uvScrollSpeedX.heightOffset, z)
                            local wx2, wy2, wz2 = localToWorld(uvScrollSpeedY, x, height, z)
                            drawDebugLine(wx1, wy1, wz1, 0, 1, 0, wx2, wy2, wz2, 0, 1, 0, false)
                            Utils.renderTextAtWorldPosition(wx2, wy2, wz2, string.format("Height: %.2fm", height), 0.01)
                        end
                    end
                end
                fillVolume.currentMinHeight = _
                fillVolume.currentMaxHeight = deformer
                fillVolume.currentMaxHeightWorld = posX
                for dz, refNode in pairs(fillVolume.nodes) do
                    local _ = _ + refNode.heightOffset
                    local z = refNode.minHeight
                    local x = math.max(_, z)
                    local _ = refNode.scaleAxis[1] * x
                    local z = refNode.scaleAxis[2] * x
                    local height = refNode.scaleAxis[3] * x
                    if refNode.scaleMax[1] > 0 then
                        _ = math.min(refNode.scaleMax[1], _)
                    end
                    if refNode.scaleMax[2] > 0 then
                        z = math.min(refNode.scaleMax[2], z)
                    end
                    if refNode.scaleMax[3] > 0 then
                        height = math.min(refNode.scaleMax[3], height)
                    end
                    local _ = refNode.transAxis[1] * x
                    local yw = refNode.transAxis[2] * x
                    local _ = refNode.transAxis[3] * x
                    if refNode.transMax[1] > 0 then
                        _ = math.min(refNode.transMax[1], _)
                    end
                    if refNode.transMax[2] > 0 then
                        yw = math.min(refNode.transMax[2], yw)
                    end
                    if refNode.transMax[3] > 0 then
                        _ = math.min(refNode.transMax[3], _)
                    end
                    setScale(refNode.node, refNode.baseScale[1] + _, refNode.baseScale[2] + z, refNode.baseScale[3] + height)
                    setTranslation(refNode.node, refNode.basePosition[1] + _, refNode.basePosition[2] + yw, refNode.basePosition[3] + _)
                    if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES and getEffectiveVisibility(refNode.node) then
                        renderShapeOutline(refNode.node, false)
                        if z ~= 0 then
                            setScale(refNode.node, 1, 1, 1)
                            local wx1, wy1, wz1 = localToWorld(refNode.node, 0, 0, 0)
                            local wx2, wy2, wz2 = localToWorld(refNode.node, 0, refNode.baseScale[2] + z, 0)
                            drawDebugLine(wx1, wy1, wz1, 0, 1, 0, wx2, wy2, wz2, 0, 1, 0, false)
                            Utils.renderTextAtWorldPosition(wx2, wy2, wz2, string.format("%s scaleY: %.2f", getName(refNode.node), refNode.baseScale[2] + z), 0.01)
                            setScale(refNode.node, refNode.baseScale[1] + _, refNode.baseScale[2] + z, refNode.baseScale[3] + height)
                        end
                        if yw ~= 0 then
                            local wx1, wy1, wz1 = localToWorld(getParent(refNode.node), refNode.basePosition[1] + _, refNode.basePosition[2], refNode.basePosition[3] + _)
                            local wx2, wy2, wz2 = localToWorld(getParent(refNode.node), refNode.basePosition[1] + _, refNode.basePosition[2] + yw, refNode.basePosition[3] + _)
                            drawDebugLine(wx1, wy1, wz1, 0, 1, 0, wx2, wy2, wz2, 0, 1, 0, false)
                            Utils.renderTextAtWorldPosition(wx2, wy2, wz2, string.format("%s transY: %.2f", getName(refNode.node), refNode.basePosition[2] + yw), 0.01)
                        end
                    end
                    if refNode.orientateToWorldY then
                        local wx1, wy1, wz1 = localDirectionToWorld(getParent(refNode.node), 0, 1, 0)
                        local wy2 = math.clamp(wy1, -1, 1)
                        local wx2 = math.acos(wy2)
                        setRotation(refNode.node, wx2, 0, 0)
                    end
                end
            end
        end
    end
    goto l2
end
function FillVolume:loadFillVolume(xmlFile, key, entry)
    local spec = self.spec_fillVolume
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
    entry.baseNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    if entry.baseNode == nil then
        printWarning("Warning: fillVolume \'" .. tostring(key) .. "\' has an invalid \'node\' in \'" .. self.configFileName .. "\'!")
        return false
    end
    if not getHasClassId(entry.baseNode, ClassIds.SHAPE) then
        Logging.xmlWarning(xmlFile, "fillVolume \'" .. getName(entry.baseNode) .. "\' at \'" .. tostring(key) .. "\' is not a shape!")
        return false
    end
    local fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex")
    entry.fillUnitIndex = fillUnitIndex
    if fillUnitIndex == nil then
        printWarning("Warning: fillVolume \'" .. tostring(key) .. "\' has no \'fillUnitIndex\' given in \'" .. self.configFileName .. "\'!")
        return false
    end
    if not self:getFillUnitExists(fillUnitIndex) then
        printWarning("Warning: fillVolume \'" .. tostring(key) .. "\' has an invalid \'fillUnitIndex\' in \'" .. self.configFileName .. "\'!")
        return false
    end
    entry.fillUnitFactor = xmlFile:getValue(key .. "#fillUnitFactor", 1)
    entry.useFullCapacity = xmlFile:getValue(key .. "#useFullCapacity", true)
    if spec.fillUnitFillVolumeMapping[fillUnitIndex] == nil then
        spec.fillUnitFillVolumeMapping[fillUnitIndex] = {
            ["fillVolumes"] = {},
            ["sumFactors"] = 0
        }
    end
    local defaultFillTypeIndex = spec.fillUnitFillVolumeMapping[fillUnitIndex].fillVolumes
    table.insert(defaultFillTypeIndex, entry)
    spec.fillUnitFillVolumeMapping[fillUnitIndex].sumFactors = spec.fillUnitFillVolumeMapping[fillUnitIndex].sumFactors + entry.fillUnitFactor
    entry.allSidePlanes = xmlFile:getValue(key .. "#allSidePlanes", true)
    entry.retessellateTop = xmlFile:getValue(key .. "#retessellateTop", false)
    local defaultFillTypeStr = xmlFile:getValue(key .. "#defaultFillType")
    if defaultFillTypeStr == nil then
        entry.defaultFillType = self:getFillUnitFirstSupportedFillType(fillUnitIndex)
    else
        local defaultFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(defaultFillTypeStr)
        if defaultFillTypeIndex == nil then
            printWarning("Warning: Invalid defaultFillType \'" .. tostring(defaultFillTypeStr) .. "\' for \'" .. tostring(key) .. "\' in \'" .. self.configFileName .. "\'")
            return false
        end
        entry.defaultFillType = defaultFillTypeIndex
    end
    local defaultFillTypeIndex = xmlFile:getValue(key .. "#forcedVolumeFillType")
    if defaultFillTypeIndex ~= nil then
        local forcedVolumeFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(defaultFillTypeIndex)
        if forcedVolumeFillTypeIndex == nil then
            printWarning("Warning: Invalid forcedVolumeFillType \'" .. tostring(defaultFillTypeIndex) .. "\' for \'" .. tostring(key) .. "\' in \'" .. self.configFileName .. "\'")
            return false
        end
        entry.forcedVolumeFillType = forcedVolumeFillTypeIndex
    end
    entry.maxDelta = xmlFile:getValue(key .. "#maxDelta", 1)
    entry.maxSurfaceAngle = xmlFile:getValue(key .. "#maxAllowedHeapAngle", 35)
    entry.maxPhysicalSurfaceAngle = 0.6108652381980153
    entry.maxSurfaceDistanceError = xmlFile:getValue(key .. "#maxSurfaceDistanceError", 0.05)
    entry.maxSubDivEdgeLength = xmlFile:getValue(key .. "#maxSubDivEdgeLength", 0.9)
    entry.syncMaxSubDivEdgeLength = xmlFile:getValue(key .. "#syncMaxSubDivEdgeLength", 1.35)
    entry.uvPosition = { 0, 0, 0 }
    entry.deformers = {}
    local forcedVolumeFillTypeIndex = 0
    while true do
        local deformerKey = string.format("%s.deformNode(%d)", key, forcedVolumeFillTypeIndex)
        if not xmlFile:hasProperty(deformerKey) then
            break
        end
        XMLUtil.checkDeprecatedXMLElements(xmlFile, deformerKey .. "#index", deformerKey .. "#node")
        local node = xmlFile:getValue(deformerKey .. "#node", nil, self.components, self.i3dMappings)
        if node ~= nil then
            local initPos = { localToLocal(node, entry.baseNode, 0, 0, 0) }
            local deformer = {
                ["node"] = node,
                ["initPos"] = initPos,
                ["posX"] = initPos[1],
                ["posZ"] = initPos[3],
                ["polyline"] = nil,
                ["volume"] = entry.volume,
                ["baseNode"] = entry.baseNode
            }
            table.insert(entry.deformers, deformer)
            spec.fillVolumeDeformersByNode[node] = deformer
        end
        forcedVolumeFillTypeIndex = forcedVolumeFillTypeIndex + 1
    end
    entry.lastFillType = FillType.UNKNOWN
    return true
end
function FillVolume:loadFillVolumeInfo(xmlFile, key, entry)
    entry.nodes = {}
    local i = 0
    while true do
        local infoKey = key .. string.format(".node(%d)", i)
        if not xmlFile:hasProperty(infoKey) then
            break
        end
        XMLUtil.checkDeprecatedXMLElements(xmlFile, infoKey .. "#index", infoKey .. "#node")
        local node = xmlFile:getValue(infoKey .. "#node", nil, self.components, self.i3dMappings)
        if node == nil then
            Logging.xmlWarning(self.xmlFile, "Missing node for \'%s\'", infoKey)
        else
            local nodeEntry = {
                ["node"] = node,
                ["width"] = xmlFile:getValue(infoKey .. "#width", 1),
                ["length"] = xmlFile:getValue(infoKey .. "#length", 1),
                ["fillVolumeHeightIndex"] = xmlFile:getValue(infoKey .. "#fillVolumeHeightIndex"),
                ["priority"] = xmlFile:getValue(infoKey .. "#priority", 1),
                ["minHeight"] = xmlFile:getValue(infoKey .. "#minHeight"),
                ["maxHeight"] = xmlFile:getValue(infoKey .. "#maxHeight"),
                ["minFillLevelPercentage"] = xmlFile:getValue(infoKey .. "#minFillLevelPercentage"),
                ["maxFillLevelPercentage"] = xmlFile:getValue(infoKey .. "#maxFillLevelPercentage"),
                ["heightForTranslation"] = xmlFile:getValue(infoKey .. "#heightForTranslation"),
                ["translationStart"] = xmlFile:getValue(infoKey .. "#translationStart", nil, true),
                ["translationEnd"] = xmlFile:getValue(infoKey .. "#translationEnd", nil, true),
                ["translationAlpha"] = 0
            }
            table.insert(entry.nodes, nodeEntry)
        end
        i = i + 1
    end
    table.sort(entry.nodes, function(a, b)
        return a.priority > b.priority
    end)
    return true
end
function FillVolume:loadFillVolumeHeightNode(xmlFile, key, entry)
    entry.isDirty = false
    entry.fillVolumeIndex = xmlFile:getValue(key .. "#fillVolumeIndex", 1)
    if self.spec_fillVolume.volumes[entry.fillVolumeIndex] == nil then
        Logging.xmlWarning(self.xmlFile, "Invalid fillVolumeIndex \'%d\' for heightNode \'%s\'. Igoring heightNode!", entry.fillVolumeIndex, key)
        return false
    end
    entry.refNodes = {}
    local i = 0
    while true do
        local nodeKey = key .. string.format(".refNode(%d)", i)
        if not xmlFile:hasProperty(nodeKey) then
            break
        end
        XMLUtil.checkDeprecatedXMLElements(xmlFile, nodeKey .. "#index", nodeKey .. "#node")
        local node = xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)
        if node == nil then
            Logging.xmlWarning(self.xmlFile, "Missing node for \'%s\'", nodeKey)
        else
            table.insert(entry.refNodes, {
                ["refNode"] = node
            })
        end
        i = i + 1
    end
    entry.nodes = {}
    local i = 0
    while true do
        local nodeKey = key .. string.format(".node(%d)", i)
        if not xmlFile:hasProperty(nodeKey) then
            break
        end
        XMLUtil.checkDeprecatedXMLElements(xmlFile, nodeKey .. "#index", nodeKey .. "#node")
        local node = xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)
        if node == nil then
            Logging.xmlWarning(self.xmlFile, "Missing node for \'%s\'", nodeKey)
        else
            local nodeEntry = {
                ["node"] = node,
                ["baseScale"] = xmlFile:getValue(nodeKey .. "#baseScale", "1 1 1", true),
                ["scaleAxis"] = xmlFile:getValue(nodeKey .. "#scaleAxis", "0 0 0", true),
                ["scaleMax"] = xmlFile:getValue(nodeKey .. "#scaleMax", "0 0 0", true),
                ["basePosition"] = { getTranslation(node) },
                ["transAxis"] = xmlFile:getValue(nodeKey .. "#transAxis", "0 0 0", true),
                ["transMax"] = xmlFile:getValue(nodeKey .. "#transMax", "0 0 0", true),
                ["minHeight"] = xmlFile:getValue(nodeKey .. "#minHeight", 0),
                ["heightOffset"] = xmlFile:getValue(nodeKey .. "#heightOffset", 0),
                ["orientateToWorldY"] = xmlFile:getValue(nodeKey .. "#orientateToWorldY", false)
            }
            table.insert(entry.nodes, nodeEntry)
        end
        i = i + 1
    end
    return true
end
function FillVolume:getFillVolumeLoadInfo(loadInfoIndex)
    return self.spec_fillVolume.loadInfos[loadInfoIndex]
end
function FillVolume:getFillVolumeUnloadInfo(unloadInfoIndex)
    return self.spec_fillVolume.unloadInfos[unloadInfoIndex]
end
function FillVolume:getFillVolumeIndicesByFillUnitIndex(fillUnitIndex)
    local indices = {}
    for i, fillVolume in ipairs(self.spec_fillVolume.volumes) do
        if fillVolume.fillUnitIndex == fillUnitIndex then
            table.insert(indices, i)
        end
    end
    return indices
end
function FillVolume:setFillVolumeForcedFillTypeByFillUnitIndex(fillUnitIndex, forcedFillType)
    for i, fillVolume in ipairs(self.spec_fillVolume.volumes) do
        if fillVolume.fillUnitIndex == fillUnitIndex then
            self:setFillVolumeForcedFillType(i, forcedFillType)
        end
    end
end
function FillVolume:setFillVolumeForcedFillType(fillVolumeIndex, forcedFillType)
    local spec = self.spec_fillVolume
    if spec.volumes[fillVolumeIndex] ~= nil then
        spec.volumes[fillVolumeIndex].forcedFillType = forcedFillType
    end
end
function FillVolume:getFillVolumeUVScrollSpeed()
    return 0, 0, 0
end
function FillVolume:setMovingToolDirty(superFunc, node, forceUpdate, dt)
    superFunc(self, node, forceUpdate, dt)
    local spec = self.spec_fillVolume
    if spec.fillVolumeDeformersByNode ~= nil then
        local deformer = spec.fillVolumeDeformersByNode[node]
        if deformer ~= nil then
            deformer.isDirty = true
        end
    end
end
function FillVolume:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
    if not superFunc(self, xmlFile, baseName, entry) then
        return false
    end
    local fillVolumeIndex = xmlFile:getValue(baseName .. ".fillVolume#fillVolumeIndex", 1)
    local indices = xmlFile:getValue(baseName .. ".fillVolume#deformerNodeIndices", nil, true)
    if indices ~= nil and #indices > 0 then
        entry.fillVolumeIndex = fillVolumeIndex
        entry.deformerNodes = {}
        local i = 1
        for i = i, #indices do
            table.insert(entry.deformerNodes, indices[i])
        end
    end
    return true
end
function FillVolume:updateExtraDependentParts(superFunc, part, dt)
    superFunc(self, part, dt)
    if part.deformerNodes ~= nil then
        if part.fillVolumeIndex ~= nil then
            part.fillVolume = self.spec_fillVolume.volumes[part.fillVolumeIndex]
            if part.fillVolume == nil then
                Logging.xmlWarning(self.xmlFile, "Unable to find fillVolume with index \'%d\' for movingPart/movingTool \'%s\'", part.fillVolumeIndex, getName(part.node))
                part.deformerNodes = nil
            end
            part.fillVolumeIndex = nil
        end
        if part.fillVolume ~= nil then
            for i, nodeIndex in pairs(part.deformerNodes) do
                local deformerNode = part.fillVolume.deformers[nodeIndex]
                if deformerNode == nil then
                    part.deformerNodes[i] = nil
                else
                    deformerNode.isDirty = true
                end
            end
        end
    end
end
function FillVolume:onFillUnitFillLevelChanged(fillUnitIndex, _, _, _, fillPositionData, _)
    local spec = self.spec_fillVolume
    local mapping = spec.fillUnitFillVolumeMapping[fillUnitIndex]
    if mapping == nil then
        return
    end
    local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)
    local fillType = self:getFillUnitFillType(fillUnitIndex)
    for _, fillVolume in ipairs(mapping.fillVolumes) do
        local baseNode = fillVolume.baseNode
        local volumeNode = fillVolume.volume
        if baseNode == nil or volumeNode == nil then
            return
        end
        local i = fillVolume.capacity
        fillVolume.fillLevel = math.clamp(fillLevel, 0, i)
        if fillVolume.forcedFillType ~= nil then
            fillType = fillVolume.forcedFillType
        end
        if fillLevel == 0 then
            fillVolume.forcedFillType = nil
        end
        if fillType ~= fillVolume.lastFillType then
            local maxPhysicalSurfaceAngle = nil
            local fillTypeInfo = g_fillTypeManager:getFillTypeByIndex(fillType)
            if fillTypeInfo ~= nil then
                maxPhysicalSurfaceAngle = fillTypeInfo.maxPhysicalSurfaceAngle
            end
            if maxPhysicalSurfaceAngle ~= nil and fillVolume.volume ~= nil then
                setFillPlaneMaxPhysicalSurfaceAngle(fillVolume.volume, maxPhysicalSurfaceAngle)
                fillVolume.maxPhysicalSurfaceAngle = maxPhysicalSurfaceAngle
            end
        end
        local maxPhysicalSurfaceAngle = setVisibility
        local fillTypeInfo = fillVolume.volume
        local i = fillLevel > 0
        maxPhysicalSurfaceAngle(fillTypeInfo, i)
        if fillType ~= FillType.UNKNOWN and fillType ~= fillVolume.lastFillType then
            local maxPhysicalSurfaceAngle = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(fillType)
            if maxPhysicalSurfaceAngle ~= nil then
                setShaderParameter(fillVolume.volume, "fillTypeId", maxPhysicalSurfaceAngle - 1, 0, 0, 0, false)
            end
        end
        if fillPositionData == nil then
            local maxPhysicalSurfaceAngle = (fillVolume.maxPhysicalSurfaceAngle == 0 or fillVolume.maxSurfaceAngle == 0) and 10 or 0.1
            local fillTypeInfo, i, newX = localToWorld(fillVolume.volume, -maxPhysicalSurfaceAngle * 0.5, 0, -maxPhysicalSurfaceAngle * 0.5)
            local _, node, doInsert = localDirectionToWorld(fillVolume.volume, maxPhysicalSurfaceAngle, 0, 0)
            local height, x, _ = localDirectionToWorld(fillVolume.volume, 0, 0, maxPhysicalSurfaceAngle)
            if not self.isServer and (spec.lastPositionInfo[1] ~= 0 and spec.lastPositionInfo[2] ~= 0) then
                fillTypeInfo, i, newX = localToWorld(fillVolume.volume, spec.lastPositionInfo[1], 0, spec.lastPositionInfo[2])
            end
            local _ = math.floor((fillVolume.fillLevel - fillVolume.fillLevel) / 400)
            local z = math.clamp(_, 1, 25)
            local x = 1
            for x = x, z do
                fillPlaneAdd(fillVolume.volume, fillLevelDelta / z, fillTypeInfo, i, newX, _, node, doInsert, height, x, _)
            end
        else
            local i = #spec.availableFillNodes
            local maxPhysicalSurfaceAngle = 1
            local fillTypeInfo = -1
            for i = i, maxPhysicalSurfaceAngle, fillTypeInfo do
                spec.availableFillNodes[i] = nil
            end
            if fillPositionData.nodes == nil then
                table.insert(spec.availableFillNodes, fillPositionData)
            else
                local maxPhysicalSurfaceAngle = fillPositionData.nodes[1].priority
                while #spec.availableFillNodes == 0 and maxPhysicalSurfaceAngle >= 1 do
                    for _, node in pairs(fillPositionData.nodes) do
                        if maxPhysicalSurfaceAngle <= node.priority then
                            local doInsert = true
                            if node.minHeight ~= nil or node.maxHeight ~= nil then
                                local height = -math.huge
                                if node.fillVolumeHeightIndex == nil or spec.heightNodes[node.fillVolumeHeightIndex] == nil then
                                    local x, _, z = localToLocal(node.node, baseNode, 0, 0, 0)
                                    local x = getFillPlaneHeightAtLocalPos(volumeNode, x, z) - fillVolume.heightOffset
                                    height = math.max(height, x)
                                else
                                    for _, refNode in pairs(spec.heightNodes[node.fillVolumeHeightIndex].refNodes) do
                                        local x, _, z = localToLocal(refNode.refNode, baseNode, 0, 0, 0)
                                        local newZ = getFillPlaneHeightAtLocalPos(volumeNode, x, z) - fillVolume.heightOffset
                                        height = math.max(height, newZ)
                                    end
                                end
                                if node.minHeight ~= nil and height < node.minHeight then
                                    doInsert = false
                                end
                                if node.maxHeight ~= nil and node.maxHeight < height then
                                    doInsert = false
                                end
                                if node.heightForTranslation ~= nil then
                                    if node.heightForTranslation < height then
                                        node.translationAlpha = node.translationAlpha + 0.01
                                        local x, _, z = MathUtil.vector3ArrayLerp(node.translationStart, node.translationEnd, node.translationAlpha)
                                        setTranslation(node.node, x, _, z)
                                    else
                                        node.translationAlpha = node.translationAlpha - 0.01
                                    end
                                    node.translationAlpha = math.clamp(node.translationAlpha, 0, 1)
                                end
                            end
                            if node.minFillLevelPercentage ~= nil or node.maxFillLevelPercentage ~= nil then
                                local height = fillLevel / self:getFillUnitCapacity(fillUnitIndex)
                                if node.minFillLevelPercentage ~= nil and height < node.minFillLevelPercentage then
                                    doInsert = false
                                end
                                if node.maxFillLevelPercentage ~= nil and node.maxFillLevelPercentage < height then
                                    doInsert = false
                                end
                            end
                            if doInsert then
                                table.insert(spec.availableFillNodes, node)
                            end
                        end
                    end
                    if #spec.availableFillNodes > 0 then
                        break
                    end
                    maxPhysicalSurfaceAngle = maxPhysicalSurfaceAngle - 1
                end
            end
            local maxPhysicalSurfaceAngle = #spec.availableFillNodes
            local fillTypeInfo = 0
            local i = 0
            local node = 1
            for node = node, maxPhysicalSurfaceAngle do
                local doInsert = spec.availableFillNodes[node]
                local height, x, _ = getWorldTranslation(doInsert.node)
                local z, _, refNode = localDirectionToWorld(doInsert.node, doInsert.width, 0, 0)
                local x, _, z = localDirectionToWorld(doInsert.node, 0, 0, doInsert.length)
                if VehicleDebug.state == VehicleDebug.DEBUG then
                    drawDebugLine(height, x, _, 1, 0, 0, height + z, x + _, _ + refNode, 1, 0, 0)
                    drawDebugLine(height, x, _, 0, 0, 1, height + x, x + _, _ + z, 0, 0, 1)
                    drawDebugPoint(height, x, _, 1, 1, 1, 1)
                    drawDebugPoint(height + z, x + _, _ + refNode, 1, 0, 0, 1)
                    drawDebugPoint(height + x, x + _, _ + z, 0, 0, 1, 1)
                end
                local height = height - (z + x) / 2
                local x = x - (_ + _) / 2
                local _ = _ - (refNode + z) / 2
                fillPlaneAdd(fillVolume.volume, fillLevelDelta / maxPhysicalSurfaceAngle, height, x, _, z, _, refNode, x, _, z)
                local newX, _, newZ = localToLocal(doInsert.node, fillVolume.volume, 0, 0, 0)
            end
            local newX = fillTypeInfo / maxPhysicalSurfaceAngle
            local _ = i / maxPhysicalSurfaceAngle
            local doInsert = newX - spec.lastPositionInfoSent[1]
            if math.abs(doInsert) > FillVolume.SEND_PRECISION then
                ::l77::
                spec.lastPositionInfoSent[1] = newX
                spec.lastPositionInfoSent[2] = _
                self:raiseDirtyFlags(spec.dirtyFlag)
                goto l78
            end
            local doInsert = _ - spec.lastPositionInfoSent[2]
            if math.abs(doInsert) > FillVolume.SEND_PRECISION then
                goto l77
            end
        end
        ::l78::
        local maxPhysicalSurfaceAngle = spec.fillVolumeIndexToHeightNode[fillVolume.index]
        if maxPhysicalSurfaceAngle ~= nil then
            for _, node in ipairs(maxPhysicalSurfaceAngle) do
                node.isDirty = true
            end
        end
        for _, node in pairs(fillVolume.deformers) do
            node.isDirty = true
        end
        fillVolume.lastFillType = fillType
    end
end
function FillVolume:updateDebugValues(values)
    local spec = self.spec_fillVolume
    for fillUnitIndex, mapping in pairs(spec.fillUnitFillVolumeMapping) do
        for index, fillVolume in ipairs(mapping.fillVolumes) do
            table.insert(values, {
                ["name"] = "fillUnitIndex/fillVolume",
                ["value"] = tostring(fillUnitIndex) .. " / " .. tostring(index)
            })
            table.insert(values, {
                ["name"] = "lastFillType",
                ["value"] = g_fillTypeManager:getFillTypeNameByIndex(fillVolume.lastFillType)
            })
            table.insert(values, {
                ["name"] = "volume",
                ["value"] = tostring(fillVolume.volume)
            })
            if fillVolume.volume ~= nil then
                table.insert(values, {
                    ["name"] = "visibility",
                    ["value"] = tostring(getVisibility(fillVolume.volume))
                })
                local textureArrayIndex, _, _, _ = getShaderParameter(fillVolume.volume, "fillTypeId")
                table.insert(values, {
                    ["name"] = "textureArrayIndex",
                    ["value"] = tostring(textureArrayIndex)
                })
            end
        end
    end
    table.insert(values, {
        ["name"] = "lastPositionInfo",
        ["value"] = string.format("%.2f %.2f", spec.lastPositionInfo[1], spec.lastPositionInfo[2])
    })
    table.insert(values, {
        ["name"] = "lastPositionInfoSent",
        ["value"] = string.format("%.2f %.2f", spec.lastPositionInfoSent[1], spec.lastPositionInfoSent[2])
    })
end