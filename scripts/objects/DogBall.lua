DogBall = {}
DogBall.RESET_DISTANCE = 100
DogBall.RESET_DISTANCE_SQ = DogBall.RESET_DISTANCE * DogBall.RESET_DISTANCE
local DogBall_mt = Class(DogBall, PhysicsObject)
InitStaticObjectClass(DogBall, "DogBall")
function DogBall.new(isServer, isClient, customMt)
    -- upvalues: (copy) DogBall_mt
    local self = PhysicsObject.new(isServer, isClient, customMt or DogBall_mt)
    self.forcedClipDistance = 150
    registerObjectClassName(self, "DogBall")
    self.sharedLoadRequestId = nil
    return self
end
function DogBall:delete()
    self.isDeleted = true
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
    end
    unregisterObjectClassName(self)
    DogBall:superClass().delete(self)
end
function DogBall:readStream(streamId, connection)
    if connection:getIsServer() then
        local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
        if self.i3dFilename ~= nil then
            self:load(i3dFilename, 0, 0, 0, 0, 0, 0)
        end
    end
    DogBall:superClass().readStream(self, streamId, connection)
end
function DogBall:writeStream(streamId, connection)
    if not connection:getIsServer() then
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
    end
    DogBall:superClass().writeStream(self, streamId, connection)
end
function DogBall:createNode(i3dFilename)
    self.i3dFilename = i3dFilename
    local dogBallRoot, sharedLoadRequestId = Utils.getModNameAndBaseDirectory(i3dFilename)
    self.customEnvironment = dogBallRoot
    self.baseDirectory = sharedLoadRequestId
    local dogBallRoot, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
    self.sharedLoadRequestId = sharedLoadRequestId
    local dogBallId = getChildAt(dogBallRoot, 0)
    link(getRootNode(), dogBallId)
    delete(dogBallRoot)
    self:setNodeId(dogBallId)
end
function DogBall:setNodeId(nodeId)
    DogBall:superClass().setNodeId(self, nodeId)
    if getNumOfChildren(nodeId) == 1 then
        self.ballVisualNode = getChildAt(nodeId, 0)
        local _, y, _ = getTranslation(self.ballVisualNode)
        self.ballVisualOffsetY = y
    end
end
function DogBall:getTerrainHeightWithProps(x, z)
    local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
    self.groundY = -1
    raycastClosest(x, terrainY + 1, z, 0, -1, 0, 5, "groundRaycastCallback", self, CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD + CollisionFlag.BUILDING)
    return math.max(terrainY, self.groundY)
end
function DogBall:groundRaycastCallback(hitObjectId, _, y, _, _)
    if hitObjectId ~= nil then
        local objectType = getRigidBodyType(hitObjectId)
        if objectType ~= RigidBodyType.DYNAMIC and objectType ~= RigidBodyType.KINEMATIC then
            self.groundY = y
            return false
        end
    end
    return true
end
function DogBall:update(dt)
    DogBall:superClass().update(self, dt)
    if self.isClient and self.ballVisualNode ~= nil then
        local x, y, z = getWorldTranslation(self.nodeId)
        setWorldTranslation(self.ballVisualNode, x, y + self.ballVisualOffsetY, z)
    end
end
function DogBall:updateTick(dt)
    if self.isServer then
        local x, y, z = getWorldTranslation(self.nodeId)
        if self:getTerrainHeightWithProps(x, z) > y + 1 then
            self:reset()
        end
        local parentNode = getParent(self.nodeId)
        if parentNode == 0 or parentNode ~= getRootNode() and parentNode ~= g_terrainNode then
            if MathUtil.vector3LengthSq(x - self.throwPos[1], y - self.throwPos[2], z - self.throwPos[3]) > DogBall.RESET_DISTANCE_SQ then
                self:reset()
            end
        elseif MathUtil.vector3LengthSq(x - self.spawnPos[1], y - self.spawnPos[2], z - self.spawnPos[3]) > DogBall.RESET_DISTANCE_SQ then
            self:reset()
        end
    end
    DogBall:superClass().updateTick(self, dt)
end
function DogBall:load(i3dFilename, x, y, z, rx, ry, rz)
    self:createNode(i3dFilename)
    setTranslation(self.nodeId, x, y, z)
    setRotation(self.nodeId, rx, ry, rz)
    if self.isServer then
        self.spawnPos = { x, y, z }
        self.throwPos = { x, y, z }
        self.startRot = { rx, ry, rz }
    end
    return true
end
function DogBall:reset()
    if self.isServer then
        removeFromPhysics(self.nodeId)
        setTranslation(self.nodeId, unpack(self.spawnPos))
        setRotation(self.nodeId, unpack(self.startRot))
        addToPhysics(self.nodeId)
    end
end