TreeTransportMissionTree = {}
local TreeTransportMissionTree_mt = Class(TreeTransportMissionTree, PhysicsObject)
InitStaticObjectClass(TreeTransportMissionTree, "TreeTransportMissionTree")
function TreeTransportMissionTree.new(isServer, isClient, customMt)
    -- upvalues: (copy) TreeTransportMissionTree_mt
    return PhysicsObject.new(isServer, isClient, customMt or TreeTransportMissionTree_mt)
end
function TreeTransportMissionTree:delete()
    if self.isServer and entityExists(self.nodeId) then
        removeWakeUpReport(self.nodeId)
    end
    self.nodeId = 0
    PhysicsObject:superClass().delete(self)
end
function TreeTransportMissionTree:readStream(streamId, _)
    local entityId, splitShapeId1, splitShapeId2 = readSplitShapeIdFromStream(streamId)
    local x = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
    local y = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleYPosHighPrecisionCompressionParams)
    local z = NetworkUtil.readCompressedWorldPosition(streamId, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
    local xRot = NetworkUtil.readCompressedAngle(streamId)
    local yRot = NetworkUtil.readCompressedAngle(streamId)
    local zRot = NetworkUtil.readCompressedAngle(streamId)
    if entityId == 0 then
        if splitShapeId1 ~= 0 then
            self.splitShapePart1 = splitShapeId1
            self.splitShapePart2 = splitShapeId2
            self.splitShapePositionData = {
                x,
                y,
                z,
                xRot,
                yRot,
                zRot
            }
            self:raiseActive()
        end
    else
        self:setNodeId(entityId, x, y, z, xRot, yRot, zRot)
    end
end
function TreeTransportMissionTree:writeStream(streamId, _)
    writeSplitShapeIdToStream(streamId, self.nodeId)
    local x, y, z = getWorldTranslation(self.nodeId)
    NetworkUtil.writeCompressedWorldPosition(streamId, x, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
    NetworkUtil.writeCompressedWorldPosition(streamId, y, g_currentMission.vehicleYPosHighPrecisionCompressionParams)
    NetworkUtil.writeCompressedWorldPosition(streamId, z, g_currentMission.vehicleXZPosHighPrecisionCompressionParams)
    local xRot, yRot, zRot = getWorldRotation(self.nodeId)
    NetworkUtil.writeCompressedAngle(streamId, xRot)
    NetworkUtil.writeCompressedAngle(streamId, yRot)
    NetworkUtil.writeCompressedAngle(streamId, zRot)
end
function TreeTransportMissionTree:setNodeId(nodeId, x, y, z, xRot, yRot, zRot)
    self.nodeId = nodeId
    setRigidBodyType(self.nodeId, self:getDefaultRigidBodyType())
    addToPhysics(self.nodeId)
    self.forcedClipDistance = getClipDistance(self.nodeId)
    if x == nil or (y == nil or z == nil) then
        x, y, z = getWorldTranslation(self.nodeId)
    end
    if xRot == nil or (yRot == nil or zRot == nil) then
        xRot, yRot, zRot = getWorldRotation(self.nodeId)
    end
    self.sendPosX = x
    self.sendPosY = y
    self.sendPosZ = z
    self.sendRotX = xRot
    self.sendRotY = yRot
    self.sendRotZ = zRot
    if not self.isServer then
        local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(xRot, yRot, zRot)
        self.positionInterpolator = InterpolatorPosition.new(x, y, z)
        self.quaternionInterpolator = InterpolatorQuaternion.new(quatX, quatY, quatZ, quatW)
    end
    if self.isServer then
        addWakeUpReport(nodeId, "onPhysicObjectWakeUpCallback", self)
    end
end
function TreeTransportMissionTree:update(dt)
    if not self.isServer and self.splitShapePart1 ~= nil then
        local entityId = resolveStreamSplitShapeId(self.splitShapePart1, self.splitShapePart2)
        if entityId == 0 then
            self:raiseActive()
        else
            self:setNodeId(entityId, self.splitShapePositionData[1], self.splitShapePositionData[2], self.splitShapePositionData[3], self.splitShapePositionData[4], self.splitShapePositionData[5], self.splitShapePositionData[6])
            self.splitShapePart1 = nil
            self.splitShapePart2 = nil
            self.splitShapePositionData = nil
        end
    end
    if entityExists(self.nodeId) then
        TreeTransportMissionTree:superClass().update(self, dt)
    end
end
function TreeTransportMissionTree:updateMove()
    if entityExists(self.nodeId) then
        return TreeTransportMissionTree:superClass().updateMove(self)
    else
        return false
    end
end
function TreeTransportMissionTree:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
    return not entityExists(self.nodeId) and 0 or TreeTransportMissionTree:superClass().getUpdatePriority(self, skipCount, x, y, z, coeff, connection, isGuiVisible)
end
function TreeTransportMissionTree:testScope(x, y, z, coeff, isGuiVisible)
    if entityExists(self.nodeId) then
        return TreeTransportMissionTree:superClass().testScope(self, x, y, z, coeff, isGuiVisible)
    else
        return false
    end
end
function TreeTransportMissionTree:onGhostRemove()
    if entityExists(self.nodeId) then
        TreeTransportMissionTree:superClass().onGhostRemove(self)
    end
end
function TreeTransportMissionTree:onGhostAdd()
    if entityExists(self.nodeId) then
        TreeTransportMissionTree:superClass().onGhostAdd(self)
    end
end
function TreeTransportMissionTree:wakeUp()
    if entityExists(self.nodeId) then
        TreeTransportMissionTree:superClass().wakeUp(self)
    end
end
function TreeTransportMissionTree:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
    if entityExists(self.nodeId) then
        TreeTransportMissionTree:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
    end
end
function TreeTransportMissionTree:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
    if entityExists(self.nodeId) then
        TreeTransportMissionTree:superClass().setLocalPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
    end
end