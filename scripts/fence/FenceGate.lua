source("dataS/scripts/objects/AnimatedObject.lua")
FenceGate = {}
FenceGate.DEFAULT_PRICE_PER_M = FenceSegment.DEFAULT_PRICE_PER_M * 2
FenceGate.MIN_WIDTH_AI_BLOCKING_REGION = 3
local FenceGate_mt = Class(FenceGate, FenceSegment)
function FenceGate.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Fence")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".gate#node", "")
    schema:register(XMLValueType.BOOL, basePath .. ".gate#alignY", "")
    schema:register(XMLValueType.BOOL, basePath .. ".gate#hasStartPole", "")
    schema:register(XMLValueType.BOOL, basePath .. ".gate#hasEndPole", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".gate#length", "length resp. width of the gate")
    schema:register(XMLValueType.FLOAT, basePath .. ".gate#depth", "depth of the gate including its doors used for overlap checking", "length / 2")
    schema:register(XMLValueType.FLOAT, basePath .. ".gate#depthOffset", "offset of overlap area", "depth / 2")
    AnimatedObject.registerXMLPaths(schema, basePath .. ".gate")
    schema:register(XMLValueType.BOOL, basePath .. ".gate.animatedObject(?)#useAIBlockingRegion", "Flag to enable AI blocking regions for the fence gate causing GoTo-AI agents to wait in front of gate and automatically open it", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".gate.animatedObject(?).aiBlockingRegion#stopDistance", "Distance the GoTo-AI agent waits in front of the blocking region", 2)
    schema:register(XMLValueType.FLOAT, basePath .. ".gate.animatedObject(?).aiBlockingRegion#openedStateAnimTime", "Normalized time [0..1] of the animation where the gate is in its opened state", 1)
end
function FenceGate.registerSavegameXMLPaths(schema, basePath)
    FenceSegment.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#reversed", "Segment is reversed")
    schema:register(XMLValueType.STRING, basePath .. ".animatedObject(?)#id")
    AnimatedObject.registerSavegameXMLPaths(schema, basePath .. ".animatedObject(?)")
end
function FenceGate.new(id, metadata, fence, customMt)
    -- upvalues: (copy) FenceGate_mt
    local self = FenceGate:superClass().new(id, metadata, fence, customMt or FenceGate_mt)
    self.isReversed = false
    self.rootHidden = nil
    local xmlFile = XMLFile.load("fenceGateXML", self.fence.xmlFilename, Fence.xmlSchema)
    local fenceI3d, sharedLoadRequestId, _ = g_i3DManager:loadSharedI3DFile(fence.i3dFilename, false, false)
    local components = I3DUtil.loadI3DComponents(fenceI3d)
    local i3dMapping = I3DUtil.loadI3DMapping(xmlFile, nil, components)
    local gate = self.metadata.gate
    local node = xmlFile:getNode(gate.xmlKey .. "#node", nil, components, i3dMapping)
    unlink(node)
    self.rootHidden = node
    delete(fenceI3d)
    g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
    for _, animatedObjectKey in xmlFile:iterator(gate.xmlKey .. ".animatedObject") do
        local animatedObject = AnimatedObject.new
        local animatedObject = animatedObject(g_server ~= nil, g_client ~= nil)
        animatedObject:load(node, xmlFile, animatedObjectKey, xmlFile:getFilename(), i3dMapping)
        animatedObject.getCanBeTriggered = Utils.overwrittenFunction(animatedObject.getCanBeTriggered, function(_, superFunc)
            -- upvalues: (copy) animatedObject, (copy) self
            if not superFunc(animatedObject) then
                return false
            end
            local playerFarmId = g_currentMission:getFarmId()
            local mission = g_missionManager:getMissionByFarmlandId(self.farmlandId)
            if mission ~= nil and g_currentMission.accessHandler:canFarmAccessOtherId(playerFarmId, mission.farmId) then
                return true
            end
            local farmlandOwnerFarmId = g_farmlandManager:getFarmlandOwner(self.farmlandId)
            return g_currentMission.accessHandler:canFarmAccessOtherId(playerFarmId, farmlandOwnerFarmId) and true or false
        end)
        if xmlFile:getBool(animatedObjectKey .. "#useAIBlockingRegion") and self.metadata.gate.length > FenceGate.MIN_WIDTH_AI_BLOCKING_REGION then
            animatedObject.aiBlockingRegion = {
                ["stopDistance"] = xmlFile:getFloat(animatedObjectKey .. ".aiBlockingRegion#stopDistance"),
                ["openedStateAnimTime"] = xmlFile:getFloat(animatedObjectKey .. ".aiBlockingRegion#openedStateAnimTime") or 1
            }
        end
        self.animatedObjects = self.animatedObjects or {}
        table.insert(self.animatedObjects, animatedObject)
        animatedObject:register(true)
    end
    xmlFile:delete()
    return self
end
function FenceGate.loadMetadataFromXML(xmlFile, key, id, fence)
    local metadata = FenceSegment.loadMetadataFromXML(xmlFile, key, id, fence)
    metadata.class = FenceGate
    local gateKey = key .. ".gate"
    local length = xmlFile:getFloat(gateKey .. "#length")
    local depth = xmlFile:getFloat(gateKey .. "#depth")
    local depthOffset = xmlFile:getFloat(gateKey .. "#depthOffset")
    metadata.gate = {
        ["xmlKey"] = gateKey,
        ["length"] = length,
        ["depth"] = depth,
        ["alignY"] = xmlFile:getBool(gateKey .. "#alignY"),
        ["depthOffset"] = depthOffset,
        ["hasStartPole"] = xmlFile:getBool(gateKey .. "#hasStartPole", true),
        ["hasEndPole"] = xmlFile:getBool(gateKey .. "#hasEndPole", true)
    }
    return metadata
end
function FenceGate:delete()
    if self.animatedObjects ~= nil then
        for _, animatedObject in ipairs(self.animatedObjects) do
            if animatedObject.aiBlockingRegion ~= nil then
                g_currentMission.aiSystem:removeBlockingRegion(animatedObject.aiBlockingRegion.blockingRegionId)
                animatedObject.aiBlockingRegion = nil
            end
            animatedObject:delete()
        end
        self.animatedObjects = nil
    end
    if self.rootHidden ~= nil then
        delete(self.rootHidden)
        self.rootHidden = nil
    end
    g_messageCenter:unsubscribe(MessageType.FARMLAND_OWNER_CHANGED, self)
    FenceGate:superClass().delete(self)
end
function FenceGate:loadFromXMLFile(xmlFile, key)
    self.isReversed = xmlFile:getBool(key .. "#reversed", false)
    if not FenceGate:superClass().loadFromXMLFile(self, xmlFile, key) then
        return false
    end
    local needsUpdate = false
    local isNewSavegame = not g_currentMission.missionInfo.isValid
    local startY = getTerrainHeightAtWorldPos(g_terrainNode, self.startPosX, 0, self.startPosZ)
    if isNewSavegame or self.startPosY < startY then
        self.startPosY = startY
        needsUpdate = true
    end
    local endY = getTerrainHeightAtWorldPos(g_terrainNode, self.endPosX, 0, self.endPosZ)
    if isNewSavegame or self.endPosY < endY then
        self.endPosY = endY
        needsUpdate = true
    end
    if needsUpdate then
        self:updateMeshes(true, false)
    end
    for _, animatedObjectKey in xmlFile:iterator(key .. ".animatedObject") do
        local id = xmlFile:getString(animatedObjectKey .. "#id")
        for _, animatedObject in ipairs(self.animatedObjects) do
            if animatedObject.saveId == id then
                animatedObject:loadFromXMLFile(xmlFile, animatedObjectKey)
            end
        end
    end
    return true
end
function FenceGate:saveToXMLFile(xmlFile, key)
    if not FenceGate:superClass().saveToXMLFile(self, xmlFile, key) then
        return false
    end
    if self.isReversed then
        xmlFile:setBool(key .. "#reversed", self.isReversed)
    end
    if self.animatedObjects ~= nil then
        local index = 0
        for _, animatedObject in ipairs(self.animatedObjects) do
            local animatedObjectKey = string.format("%s.animatedObject(%d)", key, index)
            xmlFile:setString(animatedObjectKey .. "#id", animatedObject.saveId)
            animatedObject:saveToXMLFile(xmlFile, animatedObjectKey)
            index = index + 1
        end
    end
    return true
end
function FenceGate:readStream(streamId, connection, lastSegment)
    FenceGate:superClass().readStream(self, streamId, connection, lastSegment)
    self.isReversed = streamReadBool(streamId)
    if connection:getIsServer() and self.animatedObjects ~= nil then
        for _, animatedObject in ipairs(self.animatedObjects) do
            local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)
            animatedObject:readStream(streamId, connection)
            g_client:finishRegisterObject(animatedObject, animatedObjectId)
        end
    end
end
function FenceGate:writeStream(streamId, connection, lastSegment)
    FenceGate:superClass().writeStream(self, streamId, connection, lastSegment)
    streamWriteBool(streamId, self.isReversed)
    if not connection:getIsServer() and self.animatedObjects ~= nil then
        for _, animatedObject in ipairs(self.animatedObjects) do
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
            animatedObject:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, animatedObject)
        end
    end
end
function FenceGate:registerTerrainHeightChangeCallbacks() end
function FenceGate:getPrice()
    return self:getActualLength() * (self.metadata.price or FenceGate.DEFAULT_PRICE_PER_M)
end
function FenceGate:setIsReversed(isReversed)
    self.isReversed = isReversed
    self:updateMeshes(true)
end
function FenceGate:getIsReversed()
    return self.isReversed
end
function FenceGate:updateMeshes(force, validatePlacement)
    local terrain = Utils.getNoNil(force, false)
    local terrain = Utils.getNoNil(validatePlacement, true)
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
    local length = 0
    local curLen = -1
    for i = i, length, curLen do
        local child = getChildAt(self.root, i)
        removeFromPhysics(child)
        unlink(child)
        self.rootHidden = child
    end
    if terrain then
        if MathUtil.vector3Length(self.endPosX - self.startPosX, self.endPosY - self.startPosY, self.endPosZ - self.startPosZ) < 0.1 then
            self.lastError = FenceSegment.ERROR_TOO_SHORT
            return false
        end
        if MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ) < 0.1 then
            self.lastError = FenceSegment.ERROR_TOO_SHORT
            return false
        end
    end
    local length = MathUtil.vector2Length(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
    local curLen = 0
    local i, child = MathUtil.vector2Normalize(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
    if length - curLen >= 0.1 then
        local x = self.startPosX
        local y = self.startPosY
        local z = self.startPosZ
        local _x = self.endPosX
        local yTest = self.endPosY
        local _z = self.endPosZ
        if terrain then
            x, y, z = self:lerpOnTerrain(terrain, curLen / length)
            _x, yTest, _z = self:lerpOnTerrain(terrain, (curLen + self.metadata.gate.length) / length)
            local actualPanelLength = math.atan((y - yTest) / gate.length)
            if math.abs(actualPanelLength) > self.metadata.maxSlopeAngle then
                self.lastError = FenceSegment.ERROR_TOO_STEEP
                return false
            end
        end
        local slopeAngle = self.rootHidden
        removeFromPhysics(slopeAngle)
        link(self.root, slopeAngle)
        self.rootHidden = nil
        local actualPanelLength = gate.length
        local dirY = 0
        if gate.alignY then
            i, dirY, child = MathUtil.vector3Normalize(_x - x, yTest - y, _z - z)
            if terrain then
                _x = x + i * gate.length
                yTest = y + dirY * gate.length
                _z = z + child * gate.length
                if terrain ~= nil and terrain ~= 0 then
                    yTest = getTerrainHeightAtWorldPos(terrain, _x, 0, _z)
                end
                i, dirY, child = MathUtil.vector3Normalize(_x - x, yTest - y, _z - z)
            end
            actualPanelLength = MathUtil.vector2Length(_x - x, _z - z)
        end
        curLen = curLen + actualPanelLength
        if self.isReversed then
        else
            _z = z
            yTest = y
            _x = x
        end
        setWorldTranslation(slopeAngle, _x, yTest, _z)
        setWorldDirection(slopeAngle, i, dirY, child, 0, 1, 0)
    end
    local _x, yTest, _z = self:lerpOnTerrain(terrain, curLen / length)
    self.actualEndX = _x
    self.actualEndY = yTest
    self.actualEndZ = _z
    if self.notYetFinalized and self.animatedObjects ~= nil then
        for slopeAngle, actualPanelLength in ipairs(self.animatedObjects) do
            actualPanelLength:setAnimTime(0.4)
        end
    end
    self.isDirty = false
    return true
end
function FenceGate:lerpOnTerrain(terrain, alpha)
    if terrain == nil or terrain == 0 then
        local x, y, z = MathUtil.vector3Lerp(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ, alpha)
        return x, y, z
    else
        local x, z = MathUtil.vector2Lerp(self.startPosX, self.startPosZ, self.endPosX, self.endPosZ, alpha)
        return x, getTerrainHeightAtWorldPos(terrain, x, 0, z), z
    end
end
function FenceGate:getOverlapBox()
    local gate = self.metadata.gate
    local dx, dz = MathUtil.vector2Normalize(self.endPosX - self.startPosX, self.endPosZ - self.startPosZ)
    local halfWidth = gate.depth or gate.length / 2
    local widthOffset = (gate.depthOffset or halfWidth) / 2
    return (self.startPosX + self.actualEndX) / 2 - dz * widthOffset * (self.isReversed and -1 or 1), (self.startPosY + self.actualEndY) / 2, (self.startPosZ + self.actualEndZ) / 2 + dx * widthOffset * (self.isReversed and -1 or 1), 0, math.atan2(self.actualEndX - self.startPosX, self.actualEndZ - self.startPosZ) + 6.283185307179586, 0, math.max(halfWidth / 2, 0.05), math.abs(self.actualEndY - self.startPosY) / 2 + (gate.height or 2), gate.length / 2
end
function FenceGate:update()
    self:checkOverlap({})
end
function FenceGate:finalize(loadedFromSavegame)
    if not FenceGate:superClass().finalize(self, loadedFromSavegame) then
        return false
    end
    if self.animatedObjects ~= nil then
        for _, animatedObject in ipairs(self.animatedObjects) do
            if not loadedFromSavegame then
                animatedObject:setAnimTime(0)
            end
            if g_server ~= nil and (animatedObject.aiBlockingRegion ~= nil and (g_currentMission ~= nil and g_currentMission.aiSystem ~= nil)) then
                local aiBlockingRegion = animatedObject.aiBlockingRegion or {}
                local x, y, z, rx, ry, rz, ex, ey, ez = self:getOverlapBox()
                aiBlockingRegion.blockingRegionId = g_currentMission.aiSystem:addBlockingRegion(x, y, z, rx, ry, rz, ex * 2, ey * 2, ez * 2, aiBlockingRegion.stopDistance or 2, "blockingPositionCallback", self)
            end
        end
    end
    if g_farmlandManager ~= nil then
        self.farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(self.startPosX, self.startPosZ)
        self:updateOwnerFarmId()
    end
    if g_messageCenter ~= nil then
        g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
    end
    return true
end
function FenceGate:blockingPositionCallback(_, _, blockerId)
    for _, animatedObject in ipairs(self.animatedObjects) do
        local openedStateAnimTime = animatedObject.aiBlockingRegion.openedStateAnimTime
        if animatedObject.animation.time == 1 - openedStateAnimTime then
            animatedObject:setDirection(openedStateAnimTime)
        end
        if animatedObject.animation.time == openedStateAnimTime then
            g_currentMission.aiSystem:setBlockingRegionState(blockerId, false)
        end
    end
end
function FenceGate:setOwnerFarmId(ownerFarmId, noEventSend)
    FenceGate:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)
    if self.animatedObjects ~= nil then
        for _, animatedObject in ipairs(self.animatedObjects) do
            animatedObject:setOwnerFarmId(ownerFarmId, true)
        end
    end
end
function FenceGate:onFarmlandStateChanged(farmlandId, _, _)
    if self.farmlandId == farmlandId then
        self:updateOwnerFarmId()
    end
end
function FenceGate:updateOwnerFarmId()
    local farmId = g_farmlandManager:getFarmlandOwner(self.farmlandId)
    if self.animatedObjects ~= nil then
        for _, animatedObject in ipairs(self.animatedObjects) do
            animatedObject:setOwnerFarmId(farmId, true)
        end
    end
end
function FenceGate:getHasVisualStartPole()
    if self.isReversed then
        return self.metadata.gate.hasEndPole
    else
        return self.metadata.gate.hasStartPole
    end
end
function FenceGate:getHasVisualEndPole()
    if self.isReversed then
        return self.metadata.gate.hasStartPole
    else
        return self.metadata.gate.hasEndPole
    end
end
function FenceGate:getSegmentPartStartEnd(node)
    local sx = self:getSegmentPartFromNode(node)
    if sx == nil then
        return nil
    end
    local sx, sy, sz = getWorldTranslation(sx)
    local isFirst = MathUtil.vector3Length(sx - self.startPosX, sy - self.startPosY, sz - self.startPosZ) < 0.01
    local isLast = MathUtil.vector3Length(sx - self.endPosX, sy - self.endPosY, sz - self.endPosZ) < 0.01
    return self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ, isFirst, isLast
end