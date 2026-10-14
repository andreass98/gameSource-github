source("dataS/scripts/fence/FenceSegment.lua")
source("dataS/scripts/fence/FenceGate.lua")
Fence = {}
local Fence_mt = Class(Fence)
function Fence.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Fence")
    schema:register(XMLValueType.STRING, basePath .. ".fence.segment(?)#id", "", nil, true)
    schema:register(XMLValueType.STRING, basePath .. ".fence.segment(?)#class", "", nil, true)
    FenceSegment.registerXMLPaths(schema, basePath .. ".fence.segment(?)")
    FenceGate.registerXMLPaths(schema, basePath .. ".fence.segment(?)")
end
g_xmlManager:addInitSchemaFunction(function()
    Fence.xmlSchema = XMLSchema.new("fence")
    Fence.registerXMLPaths(Fence.xmlSchema, "placeable")
end)
function Fence.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".segment(?)#id", "Segment id from config xml")
    FenceSegment.registerSavegameXMLPaths(schema, basePath .. ".segment(?)")
    FenceGate.registerSavegameXMLPaths(schema, basePath .. ".segment(?)")
end
function Fence.new(xmlFile, _, i3dFilename, components, i3dMapping, parentObject, linkNode, customMt)
    -- upvalues: (copy) Fence_mt
    local sharedLoadRequestId = customMt or Fence_mt
    local self = setmetatable({}, sharedLoadRequestId)
    self.nextUniqueSegmentId = 1
    self.xmlFilename = xmlFile:getFilename()
    self.i3dFilename = i3dFilename
    local fenceI3d, sharedLoadRequestId, _ = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
    if fenceI3d ~= nil then
        self.fenceI3DNode = fenceI3d
        self.sharedLoadRequestId = sharedLoadRequestId
    end
    self.components = components
    self.i3dMapping = i3dMapping
    self.parentObject = parentObject
    self.segmentTemplates = {}
    self.segmentTemplatesSorted = {}
    self.segments = {}
    self.nodeCache = NodeCache.new()
    self.root = createTransformGroup(Utils.getFilenameFromPath(self.xmlFilename))
    link(linkNode or getRootNode(), self.root)
    return self
end
function Fence:delete()
    for _, segment in ipairs_reverse(self.segments) do
        segment:delete()
    end
    table.clear(self.segments)
    table.clear(self.segmentTemplates)
    table.clear(self.segmentTemplatesSorted)
    if self.nodeCache ~= nil then
        self.nodeCache:delete()
        self.nodeCache = nil
    end
    if self.fenceI3DNode ~= nil then
        delete(self.fenceI3DNode)
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.fenceI3DNode = nil
        self.sharedLoadRequestId = nil
    end
    self.parentObject = nil
    if self.root ~= nil and entityExists(self.root) then
        delete(self.root)
    end
    self.root = nil
end
function Fence:load(xmlFile, key)
    for _, segmentKey in xmlFile:iterator(key .. ".segment") do
        local className = xmlFile:getString(segmentKey .. "#class")
        local id = xmlFile:getString(segmentKey .. "#id")
        if self.segmentTemplates[id] == nil then
            local segmentClass = ClassUtil.getClassObject(className)
            if segmentClass == nil then
                Logging.xmlError(xmlFile, "class \'%s\' not defined for \'%s\'", className, segmentKey)
            else
                local metadata = segmentClass.loadMetadataFromXML(xmlFile, segmentKey, id, self)
                self.segmentTemplates[id] = metadata
                table.insert(self.segmentTemplatesSorted, id)
            end
        else
            Logging.xmlError(xmlFile, "given segment id %q at %q already in use", id, segmentKey)
        end
    end
    if table.size(self.segmentTemplates) ~= 0 then
        return true
    end
    Logging.xmlError(xmlFile, "No segments defined for \'%s\'", key)
    return false
end
function Fence:loadFromXMLFile(xmlFile, key)
    for _, segmentKey in xmlFile:iterator(key .. ".segment") do
        local id = xmlFile:getString(segmentKey .. "#id")
        local segment = self:createNewSegment(id)
        if segment == nil then
            Logging.xmlWarning(xmlFile, "Unable to create fence segment for id %q, ignoring", id)
        elseif segment:loadFromXMLFile(xmlFile, segmentKey) then
            if not segment:finalize(true) then
                Logging.xmlWarning(xmlFile, "Unable to finalize fence segment for id %q, ignoring", id)
                segment:delete()
            end
        else
            Logging.xmlWarning(xmlFile, "Unable to load fence segment for id %q, ignoring", id)
            segment:delete()
        end
    end
end
function Fence:saveToXMLFile(xmlFile, key, _)
    local segmentXMLIndex = 0
    for _, segment in ipairs(self.segments) do
        if segment.needsSaving == nil or segment.needsSaving == true then
            local segmentKey = string.format("%s.segment(%d)", key, segmentXMLIndex)
            if segment:saveToXMLFile(xmlFile, segmentKey) then
                xmlFile:setString(segmentKey .. "#id", segment:getId())
            end
        end
    end
end
function Fence:readStream(streamId, connection)
    local numSegments = streamReadUInt16(streamId)
    local lastSegment = nil
    for i = 1, numSegments do
        local segmentTemplateIndex = streamReadUInt8(streamId)
        local segment = self:createNewSegment(self.segmentTemplatesSorted[segmentTemplateIndex])
        segment:readStream(streamId, connection, lastSegment)
        segment:updateMeshes(true, false)
        segment:finalize(true)
    end
end
function Fence:writeStream(streamId, connection)
    streamWriteUInt16(streamId, #self.segments)
    local lastSegment = nil
    for _, segment in ipairs(self.segments) do
        local segmentTemplateIndex = self:getSegmentTemplateIndexById(segment:getId())
        streamWriteUInt8(streamId, segmentTemplateIndex)
        segment:writeStream(streamId, connection, lastSegment)
    end
end
function Fence:getSegmentTemplateIndexById(segmentId)
    return table.find(self.segmentTemplatesSorted, segmentId)
end
function Fence:getSegmentTemplateIdByIndex(segmentTemplateIndex)
    return self.segmentTemplatesSorted[segmentTemplateIndex]
end
function Fence:getSegmentTemplateById(segmentId)
    return self.segmentTemplates[segmentId]
end
function Fence:getSegmentTemplates()
    return self.segmentTemplatesSorted
end
function Fence:createNewSegment(segmentId)
    local metadata = self.segmentTemplates[segmentId]
    if metadata == nil then
        Logging.error("No metadata for fence segment id %q", segmentId)
        return nil
    end
    self.nextUniqueSegmentId = self.nextUniqueSegmentId + 1
    local segment = metadata.class.new(self.nextUniqueSegmentId, metadata, self)
    link(self.root, segment.root)
    return segment
end
function Fence:addSegment(segment)
    if table.hasElement(self.segments, segment) then
        Logging.error("Fence segment %q already added to fence", segment)
    else
        for _, s in ipairs(self.segments) do
            if s.id == segment.id then
                Logging.error("Fence segment id %q already added to fence", segment.id)
                return
            end
        end
        segment:addNodeObjectMapping()
        table.insert(self.segments, segment)
        self:onSegmentCreated(segment)
    end
end
function Fence:removeSegment(segment)
    if segment ~= nil then
        segment:removeNodeObjectMapping()
    end
    return table.removeElement(self.segments, segment)
end
function Fence:getNumSegments()
    return #self.segments
end
function Fence:getSegments()
    return self.segments
end
function Fence:getSegment(index)
    return self.segments[index or #self.segments]
end
function Fence:getSegmentById(id)
    for _, segment in pairs(self.segments) do
        if segment.id == id then
            return segment
        end
    end
    return nil
end
function Fence:getSegmentIndex(segment)
    return table.find(self.segments, segment)
end
function Fence:getSegmentFromNode(node)
    while node ~= 0 and node ~= self.root do
        for _, segment in ipairs(self.segments) do
            if segment.root == node then
                return segment
            end
        end
        node = getParent(node)
    end
    return nil
end
function Fence:getIsOnFarmland(farmlandId)
    for _, segment in ipairs(self.segments) do
        local x, _, z = segment:getStartPos()
        if g_farmlandManager:getFarmlandIdAtWorldPosition(x, z) == farmlandId then
            return true
        end
        local x, _, z = segment:getEndPos()
        if g_farmlandManager:getFarmlandIdAtWorldPosition(x, z) == farmlandId then
            return true
        end
    end
    return false
end
function Fence:getHasPoleNear(x, y, z, r)
    if self:getPoleNear(x, y, z, r) ~= nil then
        return true
    end
    for _, segment in ipairs_reverse(self.segments) do
        if segment.parentBackup == nil then
            local px, py, pz = segment:getStartPos()
            if MathUtil.vector3Length(px - x, py - y, pz - z) < r then
                return true
            end
            local px, py, pz = segment:getEndPos()
            if px ~= nil and MathUtil.vector3Length(px - x, py - y, pz - z) < r then
                return true
            end
        end
    end
    return false
end
function Fence:getNearPoleSegment(x, y, z, r, ignoreId)
    local _, _, _, _, _, closestSegmentId, isStartPole = self:getPoleNear(x, y, z, r, ignoreId)
    if closestSegmentId == nil then
        for _, segment in ipairs_reverse(self.segments) do
            if segment.parentBackup == nil and segment.id ~= ignoreId then
                local px, py, pz = segment:getStartPos()
                if MathUtil.vector3Length(px - x, py - y, pz - z) < r then
                    closestSegmentId = segment.id
                    isStartPole = true
                    break
                end
                local px, py, pz = segment:getEndPos()
                if px ~= nil and MathUtil.vector3Length(px - x, py - y, pz - z) < r then
                    closestSegmentId = segment.id
                    isStartPole = false
                    break
                end
            end
        end
    end
    if closestSegmentId == nil then
        return nil
    else
        return self:getSegmentById(closestSegmentId), isStartPole
    end
end
function Fence:getNeighborSegmentNeedingPoleUpdate(x, y, z, r, ignoreId)
    local candidate = nil
    for _, segment in ipairs(self.segments) do
        if segment.parentBackup == nil and segment.id ~= ignoreId then
            local segStartX, segStartY, segStartZ = segment:getStartPos()
            local connectedAtStart = false
            if segStartX ~= nil then
                connectedAtStart = MathUtil.vector3Length(segStartX - x, segStartY - y, segStartZ - z) < r
            end
            local segEndX, segEndY, segEndZ = segment:getEndPos()
            local connectedAtEnd = false
            if segEndX ~= nil then
                connectedAtEnd = MathUtil.vector3Length(segEndX - x, segEndY - y, segEndZ - z) < r
            end
            if connectedAtStart or connectedAtEnd then
                if connectedAtStart and segment.hasStartPole == true then
                    return nil
                end
                if connectedAtEnd and segment.hasEndPole == true then
                    return nil
                end
                if candidate == nil then
                    candidate = segment
                end
            end
        end
    end
    return candidate
end
function Fence:getPoleNear(x, y, z, r, ignoreId)
    r = r or 0.05
    self.poleNearTargetX = x
    self.poleNearTargetY = y
    self.poleNearTargetZ = z
    self.poleNearTargetRadius = r
    self.closestPoleDistance = math.huge
    self.closestPoleOrPanel = nil
    self.closestSegmentId = nil
    self.poleNearX = nil
    self.poleNearY = nil
    self.poleNearZ = nil
    self.segmentIgnoreId = ignoreId
    self.closestPoleIsStartPole = false
    self.closestPoleIsEndPole = false
    overlapSphere(x, y, z, r, "onPoleOverlapSphereCallback", self, CollisionFlag.STATIC_OBJECT, false, false, true, false)
    return self.closestPoleOrPanel, self.closestPoleDistance, self.poleNearX, self.poleNearY, self.poleNearZ, self.closestSegmentId, self.closestPoleIsStartPole, self.closestPoleIsEndPole
end
function Fence:onPoleOverlapSphereCallback(nodeId, _, _)
    local segment = self:getSegmentFromNode(nodeId)
    if segment == nil then
        return true
    end
    if self.segmentIgnoreId ~= nil and self.segmentIgnoreId == segment.id then
        return true
    end
    while getParent(nodeId) ~= segment.root do
        nodeId = getParent(nodeId)
    end
    local sx, sy, sz, ex, ey, ez, isFirstPole, isLastPole = segment:getSegmentPartStartEnd(nodeId)
    local distanceStart = MathUtil.vector3Length(self.poleNearTargetX - sx, self.poleNearTargetY - sy, self.poleNearTargetZ - sz)
    local distanceEnd = MathUtil.vector3Length(self.poleNearTargetX - ex, self.poleNearTargetY - ey, self.poleNearTargetZ - ez)
    if distanceStart < self.closestPoleDistance and distanceStart < self.poleNearTargetRadius then
        self.closestPoleDistance = distanceStart
        self.closestPoleOrPanel = nodeId
        self.poleNearX = sx
        self.poleNearY = sy
        self.poleNearZ = sz
        self.closestSegmentId = segment.id
        self.closestPoleIsStartPole = isFirstPole
        self.closestPoleIsEndPole = isLastPole
    end
    if distanceEnd < self.closestPoleDistance and distanceEnd < self.poleNearTargetRadius then
        self.closestPoleDistance = distanceEnd
        self.closestPoleOrPanel = nodeId
        self.poleNearX = ex
        self.poleNearY = ey
        self.poleNearZ = ez
        self.closestSegmentId = segment.id
        self.closestPoleIsStartPole = isFirstPole
        self.closestPoleIsEndPole = isLastPole
    end
    return true
end
function Fence:getAllowSegmentDeletion()
    return (self.parentObject == nil or (self.parentObject.getAllowFenceSegmentDeletion == nil or self.parentObject.getAllowFenceSegmentDeletion())) and true or false
end
function Fence:deleteSegmentPart(segment, nodeId, wholeSegment)
    local sx, sy, sz, ex, ey, ez, first, last = segment:getSegmentPartStartEnd(nodeId)
    if sx == nil then
        return false
    end
    local osx, osy, osz = segment:getStartPos()
    local oex, oey, oez = segment:getEndPos()
    local id = segment:getId()
    self:removeSegment(segment)
    segment:delete()
    if last and first then
        return true
    end
    if wholeSegment then
        return true
    end
    if not first then
        local newSegment = self:createNewSegment(id)
        newSegment:setStartPos(osx, osy, osz)
        newSegment:setEndPos(sx, sy, sz)
        newSegment:updateMeshes()
        newSegment:finalize(false)
    end
    if not last then
        local newSegment = self:createNewSegment(id)
        newSegment:setStartPos(ex, ey, ez)
        newSegment:setEndPos(oex, oey, oez)
        newSegment:updateMeshes()
        newSegment:finalize(false)
    end
    return true
end
function Fence:onSegmentCreated(segment)
    if self.parentObject ~= nil and self.parentObject.onSegmentCreated ~= nil then
        self.parentObject:onSegmentCreated(segment)
    end
end
function Fence:update() end
function Fence:draw()
    for _, segment in ipairs(self.segments) do
        if segment.draw ~= nil then
            segment:draw()
        end
    end
end
function Fence:finalize(_)
    self.nodeCache:empty()
end
function Fence:setOwnerFarmId(ownerFarmId, noEventSend)
    for _, segment in ipairs(self.segments) do
        segment:setOwnerFarmId(ownerFarmId, noEventSend)
    end
end
function Fence.getDeterministicRandomValueForPosition(x, y, z, maxInt)
    local alpha = (x * 11.1 + y * 13.21 + z * 17.39) % 1
    if maxInt == nil then
        return alpha
    end
    return math.floor(alpha * maxInt) + 1
end