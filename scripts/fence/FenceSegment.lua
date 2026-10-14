source("dataS/scripts/std.lua")
source("dataS/scripts/utils/MathUtil.lua")
source("dataS/scripts/utils/Utils.lua")
source("dataS/scripts/misc/Logging.lua")
source("dataS/scripts/fence/FenceNewSegmentEvent.lua")
source("dataS/scripts/fence/FenceSegmentEvent.lua")
source("dataS/scripts/fence/FenceDeleteSegmentEvent.lua")
source("dataS/scripts/fence/FenceRequestDeleteSegmentEvent.lua")
FenceSegment = {}
FenceSegment.DEFAULT_PRICE_PER_M = 100
FenceSegment.USER_ATTRIBUTE_VARIATION = "variationName"
FenceSegment.ERROR_TOO_SHORT = 1
FenceSegment.ERROR_TOO_STEEP = 2
local FenceSegment_mt = Class(FenceSegment)
function FenceSegment.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Fence")
    schema:register(XMLValueType.ANGLE, basePath .. "#maxVerticalAngle", "")
    schema:register(XMLValueType.ANGLE, basePath .. "#maxSlopeAngle", "")
    schema:register(XMLValueType.FLOAT, basePath .. "#snapDistance", "snap distance")
    schema:register(XMLValueType.FLOAT, basePath .. "#boundingCheckWidth", "Optional bounding check width")
    schema:register(XMLValueType.FLOAT, basePath .. ".settings.parallelSnapping#snapDistance", "Parallel snap distance")
    schema:register(XMLValueType.FLOAT, basePath .. ".settings.parallelSnapping#snapCheckDistance", "Parallel snap check distance")
    schema:register(XMLValueType.BOOL, basePath .. ".settings.parallelSnapping#canToggle", "If parallel snapping can be toggled")
    schema:register(XMLValueType.BOOL, basePath .. ".settings.extending#allowExtendingOnly", "Segments can be attached to a middle pole")
    schema:register(XMLValueType.ANGLE, basePath .. ".settings.extending#maxCornerAngle", "Max angle of extending segments")
    schema:register(XMLValueType.FLOAT, basePath .. "#price", "price per segment")
    schema:register(XMLValueType.STRING, basePath .. ".poles.pole(?)#variationName", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".poles.pole(?)#node", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".poles.pole(?)#radius", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".poles.pole(?)#height", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".panels#maxScale", "", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".panels#useRandomization", "If true and multiple panels are defined for the same length they will be used randomly, otherwise only the first panel is used", false)
    schema:register(XMLValueType.STRING, basePath .. ".panels.panel(?)#variationName", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".panels.panel(?)#node", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".panels.panel(?)#collisionNode", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".panels.panel(?)#length", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".panels.panel(?)#width", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".panels.panel(?)#height", "")
    schema:register(XMLValueType.BOOL, basePath .. ".panels.panel(?)#alignY", "")
end
function FenceSegment.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#start", "Segment start position")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#end", "Segment end position")
end
function FenceSegment.loadMetadataFromXML(xmlFile, key, id, fence)
    local metadata = {
        ["class"] = FenceSegment,
        ["id"] = id,
        ["maxWidth"] = 0.1,
        ["maxHeight"] = 0.1,
        ["maxVerticalAngle"] = xmlFile:getFloat(key .. "#maxVerticalAngle", 45),
        ["maxSlopeAngle"] = xmlFile:getAngle(key .. "#maxSlopeAngle", 45),
        ["snapAngle"] = xmlFile:getFloat(key .. "#snapAngle", nil),
        ["snapDistance"] = xmlFile:getFloat(key .. "#snapDistance", nil),
        ["boundingCheckWidth"] = xmlFile:getFloat(key .. "#boundingCheckWidth", nil),
        ["allowExtendingOnly"] = xmlFile:getBool(key .. "#allowExtendingOnly", false),
        ["price"] = xmlFile:getFloat(key .. "#price")
    }
    local extendingKey = key .. ".settings.extending"
    if xmlFile:hasProperty(extendingKey) then
        metadata.extending = {}
        metadata.extending.allowExtendingOnly = xmlFile:getBool(extendingKey .. "#allowExtendingOnly", nil)
        metadata.extending.maxCornerAngle = xmlFile:getAngle(extendingKey .. "#maxCornerAngle", nil)
    end
    local parallelSnappingKey = key .. ".settings.parallelSnapping"
    local parallelSnapDistance = xmlFile:getFloat(parallelSnappingKey .. "#snapDistance", nil)
    if parallelSnapDistance ~= nil then
        metadata.parallelSnapping = {}
        metadata.parallelSnapping.snapDistance = parallelSnapDistance
        metadata.parallelSnapping.checkDistance = xmlFile:getFloat(parallelSnappingKey .. "#snapCheckDistance", parallelSnapDistance)
        metadata.parallelSnapping.canToggle = xmlFile:getBool(parallelSnappingKey .. "#canToggle", nil)
    end
    local poles = {}
    local panels = {}
    for _, poleKey in xmlFile:iterator(key .. ".poles.pole") do
        local variationName = xmlFile:getString(poleKey .. "#variationName")
        local node = xmlFile:getNode(poleKey .. "#node", nil, fence.components, fence.i3dMapping)
        if node ~= nil then
            local radius = xmlFile:getFloat(poleKey .. "#radius", 0)
            local height = xmlFile:getFloat(poleKey .. "#height", 2)
            metadata.maxWidth = math.max(metadata.maxWidth, radius * 2)
            metadata.maxHeight = math.max(metadata.maxHeight, height)
            metadata.poleNames = metadata.poleNames or {}
            metadata.poleNames[getName(node)] = true
            if variationName == nil then
                ::l11::
                table.insert(poles, {
                    ["node"] = node,
                    ["radius"] = radius,
                    ["height"] = height,
                    ["template"] = templateId,
                    ["variationName"] = variationName
                })
            else
                if ({})[variationName] == nil then
                    variationNameToPole[variationName] = pole
                    goto l11
                end
                Logging.xmlWarning(xmlFile, "Variation name already defined for \'%s\'", poleKey)
            end
        end
    end
    if #poles > 0 then
        metadata.variationNameToPole = variationNameToPole
        metadata.poles = poles
    end
    for _, poleKey in xmlFile:iterator(key .. ".panels.panel") do
        local variationName = xmlFile:getString(poleKey .. "#variationName")
        local node = xmlFile:getNode(poleKey .. "#node", nil, fence.components, fence.i3dMapping)
        local radius = xmlFile:getNode(poleKey .. "#collisionNode", nil, fence.components, fence.i3dMapping)
        local height = xmlFile:getFloat(poleKey .. "#length")
        local nodeClone = xmlFile:getFloat(poleKey .. "#width", 0)
        local templateId = xmlFile:getFloat(poleKey .. "#height", 2)
        local pole = xmlFile:getBool(poleKey .. "#alignY")
        local nodeClone = clone(node, false, false, false)
        local templateId = fence.nodeCache:addTemplate(nodeClone)
        local colPosX = metadata.maxWidth
        metadata.maxWidth = math.max(colPosX, nodeClone)
        local colPosX = metadata.maxHeight
        metadata.maxHeight = math.max(colPosX, templateId)
        local collisionIndexPath = nil
        local colPosX = nil
        local colPosY = nil
        local colPosZ = nil
        if radius ~= nil then
            collisionIndexPath = I3DUtil.getNodePathIndices(radius, node, false)
            colPosX, colPosY, colPosZ = getTranslation(radius)
        end
        if variationName == nil then
            ::l22::
            table.insert(panels, {
                ["node"] = node,
                ["collisionIndexPath"] = collisionIndexPath,
                ["length"] = height,
                ["height"] = templateId,
                ["alignY"] = pole,
                ["template"] = templateId,
                ["colPosX"] = colPosX,
                ["colPosY"] = colPosY,
                ["colPosZ"] = colPosZ,
                ["variationName"] = variationName
            })
        else
            if ({})[variationName] == nil then
                variationNameToPanel[variationName] = panel
                goto l22
            end
            Logging.xmlWarning(xmlFile, "Variation name already defined for \'%s\'", poleKey)
        end
    end
    if #panels > 0 then
        table.sort(panels, function(a, b)
            if a.length == b.length then
                return a.template < b.template
            else
                return a.length > b.length
            end
        end)
        metadata.panels = panels
        local maxScale = xmlFile:getFloat(key .. ".panels#maxScale")
        if maxScale ~= nil then
            if maxScale < 1 then
                Logging.xmlWarning(xmlFile, "Panels max scale %.3f at %q needs to be >= 1", maxScale, key .. ".panels#maxScale")
            else
                metadata.panelsMaxScale = maxScale
            end
        end
        metadata.panelsUseRandomization = xmlFile:getBool(key .. ".panels#useRandomization") or metadata.panelsUseRandomization
        local panelsByLength = {}
        local _ = math.huge
        local poleKey = nil
        for height, nodeClone in ipairs(metadata.panels) do
            if nodeClone.length < _ then
                if poleKey ~= nil then
                    table.insert(panelsByLength, poleKey)
                end
                poleKey = {}
            end
            table.insert(poleKey, nodeClone)
        end
        table.insert(panelsByLength, poleKey)
        metadata.panelsGroupedByLength = panelsByLength
        metadata.variationNameToPanel = variationNameToPanel
    end
    return metadata
end
function FenceSegment.new(id, metadata, fence, customMt)
    -- upvalues: (copy) FenceSegment_mt
    local self = setmetatable({}, customMt or FenceSegment_mt)
    self.id = id
    if g_isDevelopmentVersion and g_server == nil then
        self.id = math.random(1, 99999999)
    end
    self.metadata = metadata
    self.fence = fence
    self.startPosX = nil
    self.startPosY = nil
    self.startPosZ = nil
    self.endPosX = nil
    self.endPosY = nil
    self.endPosZ = nil
    self.hasStartPole = nil
    self.hasEndPole = nil
    self.root = createTransformGroup("fenceSegmentRoot_" .. self.metadata.id .. "_" .. tostring(self):sub(10))
    self.notYetFinalized = true
    return self
end
function FenceSegment:delete()
    if self.cellIdUpdateListeners ~= nil then
        local terrainDeformationSyncer = g_currentMission.terrainDeformationSyncer
        if terrainDeformationSyncer ~= nil then
            for cellId, _ in pairs(self.cellIdUpdateListeners) do
                local cellX, cellZ = terrainDeformationSyncer:getCellIndicesById(cellId)
                terrainDeformationSyncer:removeCellUpdateListener(self, cellX, cellZ)
            end
        end
        self.cellIdUpdateListeners = nil
    end
    if self.pendingUpdateTimer ~= nil then
        self.pendingUpdateTimer:delete()
        self.pendingUpdateTimer = nil
    end
    local terrainDeformationSyncer = nil
    local endNeighbor = nil
    if self.fence ~= nil then
        if self.startPosX ~= nil then
            terrainDeformationSyncer = self.fence:getNeighborSegmentNeedingPoleUpdate(self.startPosX, self.startPosY, self.startPosZ, 0.1, self.id)
        end
        if self.endPosX ~= nil then
            endNeighbor = self.fence:getNeighborSegmentNeedingPoleUpdate(self.endPosX, self.endPosY, self.endPosZ, 0.1, self.id)
        end
    end
    if self.fence ~= nil then
        self.fence:removeSegment(self)
        self.fence = nil
    end
    if terrainDeformationSyncer ~= nil then
        terrainDeformationSyncer:removeNodeObjectMapping()
        terrainDeformationSyncer:removeFromPhysics()
        terrainDeformationSyncer:updateMeshes(true, false)
        terrainDeformationSyncer:addToPhysics()
        terrainDeformationSyncer:addNodeObjectMapping()
    end
    if endNeighbor ~= nil and endNeighbor ~= terrainDeformationSyncer then
        endNeighbor:removeNodeObjectMapping()
        endNeighbor:removeFromPhysics()
        endNeighbor:updateMeshes(true, false)
        endNeighbor:addToPhysics()
        endNeighbor:addNodeObjectMapping()
    end
    if self.root ~= nil then
        if not self.notYetFinalized then
            self:setCollisionAreaDirty()
        end
        if entityExists(self.root) then
            delete(self.root)
        end
        self.root = nil
    end
end
function FenceSegment:loadFromXMLFile(xmlFile, key)
    local sx, sy, sz = xmlFile:getTranslation(key .. "#start")
    local ex, ey, ez = xmlFile:getTranslation(key .. "#end")
    if MathUtil.isNan(sx) or (MathUtil.isNan(sz) or (MathUtil.isNan(ex) or MathUtil.isNan(ez))) then
        return false
    end
    self.startPosX = sx
    self.startPosY = sy
    self.startPosZ = sz
    self.endPosX = ex
    self.endPosY = ey
    self.endPosZ = ez
    self:updateMeshes(true, false)
    return true
end
function FenceSegment:saveToXMLFile(xmlFile, key)
    if self.startPosX == nil or self.endPosX == nil then
        Logging.devInfo("FenceSegment:saveToXMLFile incomplete fence %s %s %s - %s %s %s", self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
        return false
    end
    xmlFile:setTranslation(key .. "#start", self.startPosX, self.startPosY, self.startPosZ)
    xmlFile:setTranslation(key .. "#end", self.endPosX, self.endPosY, self.endPosZ)
    return true
end
function FenceSegment:readStream(streamId, connection, lastSegment)
    local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
    local paramsY = g_currentMission.vehicleYPosCompressionParams
    if connection:getIsServer() then
        self.id = streamReadUInt16(streamId)
    end
    if streamReadBool(streamId) then
        self.startPosX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        self.startPosY = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
        self.startPosZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
    else
        self.startPosX = lastSegment.endPosX
        self.startPosY = lastSegment.endPosY
        self.startPosZ = lastSegment.endPosZ
    end
    self.endPosX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
    self.endPosY = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
    self.endPosZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
    if self.metadata.poles and #self.metadata.poles > 0 then
        self.hasStartPole = streamReadBool(streamId)
        self.hasEndPole = streamReadBool(streamId)
    end
    self:registerTerrainHeightChangeCallbacks()
end
function FenceSegment:writeStream(streamId, connection, lastSegment)
    local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
    local paramsY = g_currentMission.vehicleYPosCompressionParams
    if not connection:getIsServer() then
        streamWriteUInt16(streamId, self.id)
    end
    local sendStartPos = true
    if lastSegment ~= nil and (lastSegment.endPosX == self.startPosX and (lastSegment.endPosY == self.startPosY and lastSegment.endPosZ == self.startPosZ)) then
        sendStartPos = false
    end
    if streamWriteBool(streamId, sendStartPos) then
        NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosX, paramsXZ)
        NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosY, paramsY)
        NetworkUtil.writeCompressedWorldPosition(streamId, self.startPosZ, paramsXZ)
    end
    NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosX, paramsXZ)
    NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosY, paramsY)
    NetworkUtil.writeCompressedWorldPosition(streamId, self.endPosZ, paramsXZ)
    if self.metadata.poles and #self.metadata.poles > 0 then
        streamWriteBool(streamId, Utils.getNoNil(self.hasStartPole, false))
        streamWriteBool(streamId, Utils.getNoNil(self.hasEndPole, false))
    end
end
function FenceSegment:registerTerrainHeightChangeCallbacks()
    local dirX = self.endPosX - self.startPosX
    local dirZ = self.endPosZ - self.startPosZ
    if dirX == 0 and dirZ == 0 then
        return
    end
    local length = MathUtil.vector2Length(dirX, dirZ)
    local terrainDeformationSyncer, offset = MathUtil.vector2Normalize(dirX, dirZ)
    local offset = 0
    while true do
        local cellX, cellZ = g_currentMission.terrainDeformationSyncer:getCellIndicesAtWorldPosition(self.startPosX + terrainDeformationSyncer * offset, self.startPosZ + offset * offset)
        if cellX ~= nil then
            local cellId = terrainDeformationSyncer:getCellId(cellX, cellZ)
            if self.cellIdUpdateListeners == nil then
                self.cellIdUpdateListeners = {}
            end
            if self.cellIdUpdateListeners[cellId] == nil then
                self.cellIdUpdateListeners[cellId] = true
                terrainDeformationSyncer:addCellUpdateListener(self, cellX, cellZ)
            end
        end
        if length <= offset then
            return
        end
        offset = math.min(offset + 0.5, length)
    end
end
function FenceSegment:onTerrainDeformationSyncerUpdate(_, _, _)
    if self.pendingUpdateTimer == nil then
        self.pendingUpdateTimer = Timer.new(5000)
        self.pendingUpdateTimer:setFinishCallback(function()
            -- upvalues: (copy) self
            self:removeNodeObjectMapping()
            removeFromPhysics(self.root)
            self:updateMeshes(true, false)
            addToPhysics(self.root)
            self:addNodeObjectMapping()
            self:setCollisionAreaDirty()
            self.pendingUpdateTimer = nil
        end)
        self.pendingUpdateTimer:start()
    end
end
function FenceSegment:addNodeObjectMapping()
    I3DUtil.iterateRecursively(self.root, function(node)
        -- upvalues: (copy) self
        if getHasClassId(node, ClassIds.SHAPE) and getRigidBodyType(node) ~= RigidBodyType.NONE then
            g_currentMission:addNodeObject(node, self.fence)
        end
    end)
end
function FenceSegment:removeNodeObjectMapping()
    if self.root ~= nil then
        I3DUtil.iterateRecursively(self.root, function(node)
            if getHasClassId(node, ClassIds.SHAPE) and getRigidBodyType(node) ~= RigidBodyType.NONE then
                g_currentMission:removeNodeObject(node)
            end
        end)
    end
end
function FenceSegment:setStartPos(x, y, z)
    if x ~= self.startPosX or (y ~= self.startPosY or z ~= self.startPosZ) then
        self.startPosX = x
        self.startPosY = y
        self.startPosZ = z
        self.isDirty = true
    end
end
function FenceSegment:setStartNode(node)
    local x, y, z = getWorldTranslation(node)
    self:setStartPos(x, y, z)
end
function FenceSegment:setEndPos(x, y, z)
    if x ~= self.endPosX or (y ~= self.endPosY or z ~= self.endPosZ) then
        self.endPosX = x
        self.endPosY = y
        self.endPosZ = z
        self.isDirty = true
    end
end
function FenceSegment:setEndNode(node)
    local x, y, z = getWorldTranslation(node)
    self:setEndPos(x, y, z)
end
function FenceSegment:getStartPos()
    return self.startPosX, self.startPosY, self.startPosZ
end
function FenceSegment:getLength()
    return (self.startPosX == nil or self.endPosX == nil) and 0 or MathUtil.vector3Length(self.endPosX - self.startPosX, self.endPosY - self.startPosY, self.endPosZ - self.startPosZ)
end
function FenceSegment:getActualLength()
    return (self.startPosX == nil or self.actualEndX == nil) and 0 or MathUtil.vector3Length(self.actualEndX - self.startPosX, self.actualEndY - self.startPosY, self.actualEndZ - self.startPosZ)
end
function FenceSegment:getPrice()
    return self:getActualLength() * (self.metadata.price or FenceSegment.DEFAULT_PRICE_PER_M)
end
function FenceSegment:getEndPos()
    return self.endPosX, self.endPosY, self.endPosZ
end
function FenceSegment:getActualEndPos()
    return self.actualEndX, self.actualEndY, self.actualEndZ
end
function FenceSegment:getMinimumPanelLength()
    local panels = self.metadata.panels
    if panels == nil or #panels == 0 then
        return nil
    else
        return panels[#panels].length
    end
end
function FenceSegment:getLastError()
    return self.lastError
end
function FenceSegment:updateMeshes(force, validatePlacement)
    local terrain = Utils.getNoNil(force, false)
    local terrain = Utils.getNoNil(validatePlacement, true)
    if g_server ~= nil then
        self.hasStartPole = nil
        self.hasEndPole = nil
    end
    self.lastError = nil
    if not (terrain or self.isDirty) then
        return true
    end
    if self.startPosX == nil or self.endPosX == nil then
        return false
    end
    if not entityExists(self.root) then
        return false
    end
    local terrain = g_terrainNode or getChild(getRootNode(), "terrain")
    local i = getNumOfChildren(self.root) - 1
    local segmentLengthXZ = -1
    for i = i, 0, segmentLengthXZ do
        local child = getChildAt(self.root, i)
        removeFromPhysics(child)
        unlink(child)
        self.fence.nodeCache:returnNodeToCache(child)
    end
    if MathUtil.vector3Length(self.endPosX - self.startPosX, self.endPosY - self.startPosY, self.endPosZ - self.startPosZ) < 0.1 then
        if self.metadata.poles and #self.metadata.poles > 0 then
            self:placePole(self.startPosX, self.startPosY, self.startPosZ, 1, 0)
        end
        self.lastError = FenceSegment.ERROR_TOO_SHORT
        return false
    end
    if MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ) < 0.1 then
        self.lastError = FenceSegment.ERROR_TOO_SHORT
        return false
    end
    local segmentLengthXZ = MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
    local i = 0
    local child, dz = MathUtil.vector2Normalize(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
    local lastY = self.startPosY
    local previousPanel = nil
    local previousPanelLength = 0
    local previousPanelData = nil
    local maxScaleDiff = (self.metadata.panelsMaxScale or 1) - 1
    local isFirstPole = true
    for _, panelGroup in ipairs(self.metadata.panelsGroupedByLength) do
        local panelGroupLength = panelGroup[1].length
        while segmentLengthXZ - i >= panelGroupLength * (1 - maxScaleDiff) - 0.01 do
            local randomPanelIndex = 1
            if self.metadata.panelsUseRandomization then
                randomPanelIndex = Fence.getDeterministicRandomValueForPosition(self.startPosX + i / 5, self.startPosY + i, self.startPosZ + i / 3, #panelGroup)
            end
            local panelData = panelGroup[randomPanelIndex]
            if self.metadata.poles and #self.metadata.poles > 0 then
                local poleTemplate, needsPole, segment = self:lerpOnTerrain(terrain, i / segmentLengthXZ)
                local poleTemplate = self.metadata.poles[Fence.getDeterministicRandomValueForPosition(poleTemplate, needsPole, segment, #self.metadata.poles)]
                local needsPole = true
                if isFirstPole then
                    if g_server == nil then
                        needsPole = self.hasStartPole
                    else
                        local segment = self.fence
                        local segment, isStartPole = segment:getNearPoleSegment(poleTemplate, needsPole, segment, math.max(poleTemplate.radius, 0.05), self.id)
                        if segment ~= nil then
                            if isStartPole then
                                local hasVisualStartPole = false
                                if segment.getHasVisualStartPole ~= nil then
                                    hasVisualStartPole = segment:getHasVisualStartPole()
                                end
                                if hasVisualStartPole and segment.hasStartPole then
                                    needsPole = false
                                end
                            else
                                local hasVisualStartPole = false
                                if segment.getHasVisualEndPole ~= nil then
                                    hasVisualStartPole = segment:getHasVisualEndPole()
                                end
                                if hasVisualStartPole and segment.hasEndPole then
                                    needsPole = false
                                end
                            end
                        end
                        self.hasStartPole = needsPole
                    end
                end
                if needsPole then
                    self:placePole(poleTemplate, needsPole, segment, child, dz)
                end
                i = i + poleTemplate.radius
            end
            local poleTemplate = segmentLengthXZ - i
            local needsPole = panelData.length
            if poleTemplate - panelData.length < self.metadata.panels[#self.metadata.panels].length * minScale then
                needsPole = panelData.length * (1 + maxScaleDiff)
            end
            local isStartPole = segmentLengthXZ - i
            local hasVisualStartPole = panelData.length * minScale
            local segment = math.clamp(isStartPole, hasVisualStartPole, needsPole)
            local isStartPole, hasVisualStartPole, hasAlreadyStartPole = self:lerpOnTerrain(terrain, i / segmentLengthXZ)
            if previousPanel ~= nil then
                FenceSegment.adjustPanelOffset(previousPanelData, previousPanel, previousPanelLength, hasVisualStartPole - lastY)
                self:updatePanel(previousPanelData, previousPanel, previousPanelLength, hasVisualStartPole - lastY)
            end
            if terrain then
                local isStartPole, hasVisualStartPole, hasAlreadyStartPole = self:lerpOnTerrain(terrain, (i + segment) / segmentLengthXZ)
                local endY = math.atan((hasVisualStartPole - hasVisualStartPole) / segment)
                if math.abs(endY) > self.metadata.maxSlopeAngle then
                    self.lastError = FenceSegment.ERROR_TOO_STEEP
                    return false
                end
            end
            previousPanel = self.fence.nodeCache:getNodeInstance(panelData.template)
            removeFromPhysics(previousPanel)
            link(self.root, previousPanel)
            setWorldTranslation(previousPanel, isStartPole, hasVisualStartPole, hasAlreadyStartPole)
            setWorldDirection(previousPanel, child, 0, dz, 0, 1, 0)
            if panelData.variationName == nil then
                removeUserAttribute(previousPanel, FenceSegment.USER_ATTRIBUTE_VARIATION)
            else
                setUserAttribute(previousPanel, FenceSegment.USER_ATTRIBUTE_VARIATION, UserAttributeType.STRING, panelData.variationName)
            end
            local hasVisualStartPole = segment / panelData.length
            if panelData.alignY then
                local slopeAngle, endY, endZ = self:lerpOnTerrain(terrain, (i + segment) / segmentLengthXZ)
                local dirX, dirY, dirZ = MathUtil.vector3Normalize(slopeAngle - isStartPole, endY - hasVisualStartPole, endZ - hasAlreadyStartPole)
                local slopeAngle = isStartPole + dirX * segment
                local endY = hasVisualStartPole + dirY * segment
                local endZ = hasAlreadyStartPole + dirZ * segment
                if terrain ~= nil and terrain ~= 0 then
                    endY = getTerrainHeightAtWorldPos(terrain, slopeAngle, 0, endZ)
                end
                local alignedLength, dirY, dirZ = MathUtil.vector3Normalize(slopeAngle - isStartPole, endY - hasVisualStartPole, endZ - hasAlreadyStartPole)
                setWorldDirection(previousPanel, alignedLength, dirY, dirZ, 0, 1, 0)
                previousPanelLength = MathUtil.vector2Length(slopeAngle - isStartPole, endZ - hasAlreadyStartPole)
                hasVisualStartPole = MathUtil.vector3Length(slopeAngle - isStartPole, endY - hasVisualStartPole, endZ - hasAlreadyStartPole) / panelData.length
            else
                previousPanelLength = segment
            end
            if hasVisualStartPole ~= 1 then
                setScale(previousPanel, 1, 1, hasVisualStartPole)
            end
            i = i + previousPanelLength
        end
    end
    local needsPole, segment, isStartPole = self:lerpOnTerrain(terrain, i / segmentLengthXZ)
    if self.metadata.poles and #self.metadata.poles > 0 then
        local needsPole = true
        if g_server == nil then
            needsPole = self.hasEndPole
        else
            local segment, isStartPole = self.fence:getNearPoleSegment(needsPole, segment, isStartPole, 0.05, self.id)
            if segment ~= nil then
                if isStartPole then
                    if segment.getHasVisualStartPole ~= nil and segment:getHasVisualStartPole() then
                        needsPole = false
                    end
                elseif segment.getHasVisualEndPole ~= nil and segment:getHasVisualEndPole() then
                    needsPole = false
                end
            end
            self.hasEndPole = needsPole
        end
        if needsPole then
            self:placePole(needsPole, segment, isStartPole, child, dz)
        end
    end
    if previousPanel ~= nil then
        FenceSegment.adjustPanelOffset(previousPanelData, previousPanel, previousPanelLength, segment - lastY)
        self:updatePanel(previousPanelData, previousPanel, previousPanelLength, segment - lastY)
    end
    self.actualEndX = needsPole
    self.actualEndY = segment
    self.actualEndZ = isStartPole
    self.isDirty = false
    return true
end
function FenceSegment:placePole(x, y, z, dx, dz)
    local sx, sy, sz = self:getStartPos()
    local distance = MathUtil.vector2Length(x - sx, z - sz)
    local randomIndex = Fence.getDeterministicRandomValueForPosition(sx + distance / 5, sy + distance, sz + distance / 3, #self.metadata.poles)
    local poleTemplate = self.metadata.poles[randomIndex]
    local pole = self.fence.nodeCache:getNodeInstance(poleTemplate.template)
    removeFromPhysics(pole)
    link(self.root, pole)
    setWorldTranslation(pole, x, y, z)
    setWorldDirection(pole, dx, 0, dz, 0, 1, 0)
    if poleTemplate.variationName == nil then
        removeUserAttribute(pole, FenceSegment.USER_ATTRIBUTE_VARIATION)
    else
        setUserAttribute(pole, FenceSegment.USER_ATTRIBUTE_VARIATION, UserAttributeType.STRING, poleTemplate.variationName)
    end
end
function FenceSegment:lerpOnTerrain(terrain, alpha)
    if terrain == nil or terrain == 0 then
        local x, y, z = MathUtil.vector3Lerp(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ, alpha)
        return x, y, z
    else
        local x, z = MathUtil.vector2Lerp(self.startPosX, self.startPosZ, self.endPosX, self.endPosZ, alpha)
        return x, getTerrainHeightAtWorldPos(terrain, x, 0, z), z
    end
end
function FenceSegment:getOverlapBox(length)
    local cx = length or MathUtil.vector3Length(self.actualEndX - self.startPosX, self.actualEndY - self.startPosY, self.actualEndZ - self.startPosZ)
    local cx = (self.startPosX + self.actualEndX) / 2
    local ex = self.actualEndZ - self.startPosZ
    local ry = math.atan2(self.actualEndX - self.startPosX, ex) + 6.283185307179586
    local ex = self.metadata.maxWidth / 2
    local ey = math.abs(self.actualEndY - self.startPosY) / 2 + self.metadata.maxHeight
    local ez = cx / 2
    local boundingCheckWidth = self.metadata.boundingCheckWidth
    if boundingCheckWidth ~= nil then
        ex = boundingCheckWidth * 0.5
        ez = cx * 0.5 + boundingCheckWidth * 0.5
    end
    return cx, (self.startPosY + self.actualEndY) / 2, (self.startPosZ + self.actualEndZ) / 2, 0, ry, 0, ex, ey, ez
end
function FenceSegment:checkOverlap(hitNodesTable, ignoreChildrenNode)
    if self.actualEndX ~= nil then
        local length = MathUtil.vector3Length(self.actualEndX - self.startPosX, self.actualEndY - self.startPosY, self.actualEndZ - self.startPosZ)
        if length ~= 0 then
            local cx, cy, cz, rx, ry, rz, ex, ey, ez = self:getOverlapBox(length)
            self.numOverlapHits = 0
            self.hitNodesTable = hitNodesTable
            self.ignoreChildrenNode = ignoreChildrenNode
            local mask = CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING + CollisionFlag.PLAYER + CollisionFlag.VEHICLE + CollisionFlag.TREE + CollisionFlag.DYNAMIC_OBJECT
            overlapCylinder(self.startPosX, self.startPosY + 0.5, self.startPosZ, 0.15, 3, Axis.Y, "onOverlapCylinderCallback", self, mask, false, true, true, true)
            overlapCylinder(self.actualEndX, self.actualEndY + 0.5, self.actualEndZ, 0.15, 3, Axis.Y, "onOverlapCylinderCallback", self, mask, false, true, true, true)
            overlapBox(cx, cy, cz, rx, ry, rz, ex, ey, ez, "onOverlapBoxCallback", self, mask, true, true, true, true)
            self.hitNodesTable = nil
            self.ignoreNodes = nil
            return hitNodesTable
        end
    end
end
function FenceSegment:onOverlapCylinderCallback(hitNode)
    self.ignoreNodes = self.ignoreNodes or {}
    self.ignoreNodes[hitNode] = not self.ignoreNodes[hitNode]
end
function FenceSegment:onOverlapBoxCallback(hitNode)
    if hitNode == 0 then
        return
    elseif self:getIsNodePartOfSegment(hitNode) then
        return
    elseif self.ignoreChildrenNode == nil or not I3DUtil.getIsLinkedToNode(self.ignoreChildrenNode, hitNode) then
        if self.ignoreNodes == nil or not self.ignoreNodes[hitNode] then
            if self.parallelSnappingSegment == nil or self.fence:getSegmentFromNode(hitNode) ~= self.parallelSnappingSegment then
                if self.hitNodesTable ~= nil then
                    self.hitNodesTable[hitNode] = true
                end
                self.numOverlapHits = self.numOverlapHits + 1
            end
        else
            return
        end
    else
        return
    end
end
function FenceSegment:getHasBlockingOverlap(farmId)
    if self.actualEndX == nil then
        return false
    else
        return not g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, self.startPosX, self.startPosZ, self.actualEndX, self.actualEndZ)
    end
end
function FenceSegment:getIsNodePartOfSegment(node)
    local parent = getParent(node)
    while parent ~= 0 do
        if self.root == parent then
            return true
        end
        parent = getParent(parent)
    end
    return false
end
function FenceSegment:getSegmentPartFromNode(node)
    while node ~= 0 do
        if self.root == getParent(node) then
            return node, getChildIndex(node)
        end
        node = getParent(node)
    end
    return nil
end
function FenceSegment:getSegmentPartStartEnd(node)
    local sx = self:getSegmentPartFromNode(node)
    if sx == nil then
        return nil
    end
    local sx, sy, sz = getWorldTranslation(sx)
    local childIndex = getChildIndex(sx)
    local isFirst = MathUtil.vector3Length(sx - self.startPosX, sy - self.startPosY, sz - self.startPosZ) < 0.01
    local parent = getParent(sx)
    local nextPart = getNumOfChildren(parent) > childIndex + 1 and getChildAt(parent, childIndex + 1) or nil
    local isLast, ey, ez
    if nextPart == nil then
        isLast = self.endPosX
        ey = self.endPosY
        ez = self.endPosZ
    else
        isLast, ey, ez = getWorldTranslation(nextPart)
    end
    local isLast = MathUtil.vector3Length(isLast - self.endPosX, ey - self.endPosY, ez - self.endPosZ) < 0.01
    return sx, sy, sz, isLast, ey, ez, isFirst, isLast
end
function FenceSegment:getId()
    return self.metadata.id
end
function FenceSegment:getHasVisualEndPole()
    return self.metadata.poles ~= nil and #self.metadata.poles > 0
end
function FenceSegment:getHasVisualStartPole()
    return self.metadata.poles ~= nil and #self.metadata.poles > 0
end
function FenceSegment:iteratorPanels()
    local currentChildIndex = 0
    local endIndex = getNumOfChildren(self.root)
    local currentPanelIndex = 0
    return function()
        -- upvalues: (ref) currentChildIndex, (copy) endIndex, (copy) self, (ref) currentPanelIndex
        if endIndex <= currentChildIndex then
            return nil
        end
        if self.metadata.poles ~= nil then
            while self.metadata.poleNames[getName(getChildAt(self.root, currentChildIndex))] ~= nil do
                currentChildIndex = currentChildIndex + 1
                if endIndex <= currentChildIndex then
                    return nil
                end
            end
        end
        currentChildIndex = currentChildIndex + 1
        currentPanelIndex = currentPanelIndex + 1
        return currentPanelIndex, getChildAt(self.root, currentChildIndex - 1)
    end
end
function FenceSegment:iteratorPoles()
    local currentChildIndex = 0
    local endIndex = getNumOfChildren(self.root)
    local currentPoleIndex = 0
    return self.metadata.poles == nil and function()
        return nil
    end or function()
        -- upvalues: (ref) currentChildIndex, (copy) endIndex, (copy) self, (ref) currentPoleIndex
        if endIndex <= currentChildIndex then
            return nil
        end
        while self.metadata.poleNames[getName(getChildAt(self.root, currentChildIndex))] == nil do
            currentChildIndex = currentChildIndex + 1
            if endIndex <= currentChildIndex then
                return nil
            end
        end
        currentChildIndex = currentChildIndex + 1
        currentPoleIndex = currentPoleIndex + 1
        return currentPoleIndex, getChildAt(self.root, currentChildIndex - 1)
    end
end
function FenceSegment:update()
    self:checkOverlap({})
end
function FenceSegment:draw()
    if self.startPosX ~= nil and self.endPosX ~= nil then
    end
end
function FenceSegment:finalize(_)
    if self.actualEndX == nil then
        return false
    end
    self.startPosX = self.actualStartX or self.startPosX
    self.startPosY = self.actualStartY or self.startPosY
    self.startPosZ = self.actualStartZ or self.startPosZ
    self.endPosX = self.actualEndX or self.endPosX
    self.endPosY = self.actualEndY or self.endPosY
    self.endPosZ = self.actualEndZ or self.endPosZ
    self:addToPhysics()
    self.fence:addSegment(self)
    self.notYetFinalized = nil
    return true
end
function FenceSegment:addToPhysics()
    addToPhysics(self.root)
    self:setCollisionAreaDirty()
end
function FenceSegment:removeFromPhysics()
    removeFromPhysics(self.root)
    self:setCollisionAreaDirty()
end
function FenceSegment:setCollisionAreaDirty()
    if self.startPosX ~= nil and self.endPosX ~= nil then
        local minX = math.min(self.startPosX, self.endPosX)
        local maxX = math.max(self.startPosX, self.endPosX)
        local minZ = math.min(self.startPosZ, self.endPosZ)
        local maxZ = math.max(self.startPosZ, self.endPosZ)
        if g_densityMapHeightManager ~= nil then
            g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
        end
        if g_currentMission ~= nil and g_currentMission.aiSystem ~= nil then
            g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
        end
    end
end
function FenceSegment:setOwnerFarmId(ownerFarmId, noEventSend) end
function FenceSegment:getOwnerFarmId()
    return g_farmlandManager:getOwnerIdAtWorldPosition(self.startPosX, self.startPosZ)
end
function FenceSegment:getCanBeModifiedByFarmId(farmId)
    return g_farmlandManager:getOwnerIdAtWorldPosition(self.startPosX, self.startPosZ) == farmId and true or g_farmlandManager:getOwnerIdAtWorldPosition(self.endPosX, self.endPosZ) == farmId
end
function FenceSegment:updatePanel(panelData, panelNode, panelLength, deltaY) end
function FenceSegment:setParallelSnappingSegment(segment)
    self.parallelSnappingSegment = segment
end
function FenceSegment.adjustPanelOffset(panelData, panelNode, panelLength, deltaY)
    if not panelData.alignY then
        setShaderParameterRecursive(panelNode, "yOffset", deltaY, nil, nil, nil, false)
    end
    local collisionIndexPath = panelData.collisionIndexPath
    if collisionIndexPath ~= nil then
        local collisionNode = I3DUtil.indexToObject(panelNode, collisionIndexPath)
        if collisionNode ~= nil then
            local panelLengthCorrected
            if panelData.alignY then
                deltaY = 0
                panelLengthCorrected = panelLength
            else
                panelLengthCorrected = math.sqrt(deltaY * deltaY + panelLength * panelLength)
            end
            local scale = panelLengthCorrected / panelData.length
            local offsetY = deltaY * scale
            local xDir, yDir, zDir = MathUtil.vector3Normalize(0, offsetY, panelLengthCorrected * scale)
            local offset = (panelLengthCorrected - panelLength) * 0.5
            setDirection(collisionNode, xDir, yDir, zDir, 0, 1, 0)
            setTranslation(collisionNode, panelData.colPosX + xDir * offset, panelData.colPosY + yDir * offset, panelData.colPosZ + zDir * offset)
        end
    end
end