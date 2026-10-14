PlayerCCT = {}
local PlayerCCT_mt = Class(PlayerCCT)
PlayerCCT.DEFAULT_HEIGHT = 1.1
PlayerCCT.DEFAULT_COLLISION_GROUP = CollisionFlag.PLAYER
PlayerCCT.DEFAULT_COLLISION_MASK = CollisionMask.ALL - bit32.bor(CollisionFlag.WATER, CollisionFlag.AI_BLOCKING, CollisionFlag.GROUND_TIP_BLOCKING, CollisionFlag.PLACEMENT_BLOCKING, CollisionFlag.PRECIPITATION_BLOCKING, CollisionFlag.CAMERA_BLOCKING, CollisionFlag.ANIMAL_POSITIONING, CollisionFlag.ANIMAL_NAV_MESH_BLOCKING, CollisionFlag.TRAFFIC_VEHICLE_BLOCKING, CollisionFlag.TERRAIN_DISPLACEMENT)
PlayerCCT.DEFAULT_MOVEMENT_COLLISION_GROUP = PlayerCCT.DEFAULT_COLLISION_GROUP
PlayerCCT.DEFAULT_MOVEMENT_COLLISION_MASK = Utils.clearFlags(PlayerCCT.DEFAULT_COLLISION_MASK, CollisionFlag.TRIGGER, CollisionFlag.FILLABLE)
function PlayerCCT.new()
    -- upvalues: (copy) PlayerCCT_mt
    local self = setmetatable({}, PlayerCCT_mt)
    self.capsuleId = nil
    self.height = PlayerCCT.DEFAULT_HEIGHT
    self.desiredHeight = self.height
    self.heightChangePhysicsIndex = nil
    self.radius = 0.35
    self.slopeLimit = 60
    self.stepOffset = 0.4
    self.mass = 0
    self.collisionGroup = PlayerCCT.DEFAULT_COLLISION_GROUP
    self.collisionMask = PlayerCCT.DEFAULT_COLLISION_MASK
    self.movementCollisionGroup = PlayerCCT.DEFAULT_MOVEMENT_COLLISION_GROUP
    self.movementCollisionMask = PlayerCCT.DEFAULT_MOVEMENT_COLLISION_MASK
    return self
end
function PlayerCCT:onPlayerLoad(player)
    if player ~= nil and player.toggleNoClipCommand ~= nil then
        player.toggleNoClipCommand.onEnabled:registerListener(function(disableTerrainCollision, ignorePlayerInTriggers)
            -- upvalues: (copy) self
            local newCollisionGroup = Utils.stringToBoolean(disableTerrainCollision)
            local newCollisionGroup = Utils.stringToBoolean(ignorePlayerInTriggers) and CollisionFlag.DEFAULT or PlayerCCT.DEFAULT_COLLISION_GROUP
            local newCollisionMask = bit32.bor(CollisionFlag.TRIGGER, newCollisionGroup and 0 or CollisionFlag.TERRAIN)
            self:setMovementCollisionFilter(newCollisionGroup, newCollisionMask)
            self:setKinematicCollisionFilter(newCollisionGroup, newCollisionMask)
            self:rebuild()
        end)
        player.toggleNoClipCommand.onDisabled:registerListener(function()
            -- upvalues: (copy) self
            self:setMovementCollisionFilter(PlayerCCT.DEFAULT_MOVEMENT_COLLISION_GROUP, PlayerCCT.DEFAULT_MOVEMENT_COLLISION_MASK)
            self:setKinematicCollisionFilter(PlayerCCT.DEFAULT_COLLISION_GROUP, PlayerCCT.DEFAULT_COLLISION_MASK)
            self:rebuild()
        end)
    end
end
function PlayerCCT:delete()
    if self.capsuleId ~= nil then
        removeCCT(self.capsuleId)
        self.capsuleId = nil
    end
end
function PlayerCCT:getMovementCollisionFilter()
    return self.movementCollisionGroup, self.movementCollisionMask
end
function PlayerCCT:setMovementCollisionFilter(movementCollisionGroup, movementCollisionMask)
    self.movementCollisionGroup = movementCollisionGroup
    self.movementCollisionMask = movementCollisionMask
end
function PlayerCCT:getKinematicCollisionFilter()
    return self.collisionGroup, self.collisionMask
end
function PlayerCCT:setKinematicCollisionFilter(kinematicCollisionGroup, kinematicCollisionMask)
    self.collisionGroup = kinematicCollisionGroup
    self.collisionMask = kinematicCollisionMask
end
function PlayerCCT:getTotalHeight()
    return self:getHeight() + self.radius * 2
end
function PlayerCCT:getHeight()
    return self.height
end
function PlayerCCT:setHeight(height)
    if height == self.desiredHeight or height < 0 then
        return
    else
        self.desiredHeight = height
        setCCTHeight(self.capsuleId, self.desiredHeight, self.movementCollisionGroup, self.movementCollisionMask)
        if self.height < height then
            self.heightChangePhysicsIndex = getPhysicsUpdateIndex()
        else
            self.heightChangePhysicsIndex = nil
            self.height = height
        end
    end
end
function PlayerCCT:getRadius()
    return self.radius
end
function PlayerCCT:getSlopeLimit()
    return self.slopeLimit
end
function PlayerCCT:setSlopeLimit(slopeLimit)
    self.slopeLimit = slopeLimit
end
function PlayerCCT:getStepOffset()
    return self.stepOffset
end
function PlayerCCT:setStepOffset(stepOffset)
    self.stepOffset = stepOffset
end
function PlayerCCT:getMass()
    return self.mass
end
function PlayerCCT:setMass(mass)
    self.mass = mass
end
function PlayerCCT:getSkinWidth()
    return self.radius * 0.2
end
function PlayerCCT:getBottomOffsetY()
    return -self.radius
end
function PlayerCCT:setRootNode(rootNode)
    self.rootNode = rootNode
end
function PlayerCCT:rebuild()
    if self.capsuleId ~= nil then
        removeCCT(self.capsuleId)
        self.capsuleId = nil
    end
    self.capsuleId = createCCT(self.rootNode, self.radius, self.desiredHeight, self.stepOffset, self.slopeLimit, self:getSkinWidth(), self.collisionGroup, self.collisionMask, self.mass)
    self.height = self.desiredHeight
    self.heightChangePhysicsIndex = nil
end
function PlayerCCT:move(movementX, movementY, movementZ)
    moveCCT(self.capsuleId, movementX, movementY, movementZ, self.movementCollisionGroup, self.movementCollisionMask)
end
function PlayerCCT:moveExternal(movementX, movementY, movementZ)
    self:move(movementX, movementY, movementZ)
end
function PlayerCCT:getTouchingNode()
    local node = 0
    if self.capsuleId ~= nil then
        node = getCCTGroundObject(self.capsuleId)
    end
    if node == 0 or not node then
        node = nil
    end
    return node
end
function PlayerCCT:getPosition()
    local x, y, z = getWorldTranslation(self.rootNode)
    return x, y + self:getBottomOffsetY(), z
end
function PlayerCCT:setPosition(x, y, z, setNodeTranslation)
    if setNodeTranslation then
        setWorldTranslation(self.rootNode, x, y - self:getBottomOffsetY(), z)
    end
    setCCTPosition(self.capsuleId, x, y - self:getBottomOffsetY(), z)
end
function PlayerCCT:calculateIfBottomTouchesGround()
    local _, _, isGrounded = getCCTCollisionFlags(self.capsuleId)
    return isGrounded
end
function PlayerCCT:update()
    if self.heightChangePhysicsIndex ~= nil and getIsPhysicsUpdateIndexSimulated(self.heightChangePhysicsIndex) then
        self.heightChangePhysicsIndex = nil
        if math.abs(getCCTHeight(self.capsuleId) - self.desiredHeight) <= 0.001 then
            self.height = self.desiredHeight
            return
        end
        self.desiredHeight = self.height
    end
end
function PlayerCCT:debugDraw(x, y, textSize)
    y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "CCT", nil, true)
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Height: %.2f", self.height))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Physics height: %.2f", getCCTHeight(self.capsuleId)))
    return DebugUtil.renderTextLine(x, y, textSize, string.format("Desired height: %.2f", self.desiredHeight))
end