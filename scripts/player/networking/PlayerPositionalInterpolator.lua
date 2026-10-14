PlayerPositionalInterpolator = {}
local PlayerPositionalInterpolator_mt = Class(PlayerPositionalInterpolator)
PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM = {
    ["ROOT_NODE"] = 1,
    ["GRAPHICAL_NODE"] = 2
}
function PlayerPositionalInterpolator.new(player, targetNodeType)
    -- upvalues: (copy) PlayerPositionalInterpolator_mt
    local self = setmetatable({}, PlayerPositionalInterpolator_mt)
    self.player = player
    self.targetNodeType = targetNodeType
    self.timeInterpolator = InterpolationTime.new(1.2)
    local playerPositionX, playerPositionY, playerPositionZ = self.player:getPosition()
    self.positionInterpolator = InterpolatorPosition.new(playerPositionX, playerPositionY, playerPositionZ)
    self.interpolatedPositionX = playerPositionX
    self.interpolatedPositionY = playerPositionY
    self.interpolatedPositionZ = playerPositionZ
    self.interpolatedSpeed = 0
    self.interpolatedVelocityX = 0
    self.interpolatedVelocityY = 0
    self.interpolatedVelocityZ = 0
    local playerYaw = self.player:getYaw()
    self.yawInterpolator = InterpolatorAngle.new(playerYaw)
    local playerSpeed = self.player:getSpeed()
    self.speedInterpolator = InterpolatorValue.new(playerSpeed)
    self.verticalVelocityInterpolator = InterpolatorValue.new(self.player.mover.currentVelocityY)
    self.directionX = 0
    self.directionZ = 0
    self.targetPhysicsIndex = -1
    self.player.mover.onPositionTeleport:registerListener(PlayerPositionalInterpolator.onPlayerPositionTeleport, self)
    return self
end
function PlayerPositionalInterpolator:update(_)
    local deltaTime = g_physicsDtUnclamped
    self.timeInterpolator:update(deltaTime)
    local alpha = self.timeInterpolator:getAlpha()
    local interpolatedPositionX, interpolatedPositionY, interpolatedPositionZ = self.positionInterpolator:getInterpolatedValues(alpha)
    local interpolatedYaw = self.yawInterpolator:getInterpolatedValue(alpha)
    local dirX = interpolatedPositionX - self.interpolatedPositionX
    local dirZ = interpolatedPositionZ - self.interpolatedPositionZ
    local distance = MathUtil.vector2Length(dirX, dirZ)
    local _ = self.player.isOwner
    local speedXZ = 0
    local speedY = 0
    if distance > 0 then
        dirX, dirZ = MathUtil.vector2Normalize(dirX, dirZ)
        speedXZ = distance / deltaTime
        speedY = (interpolatedPositionY - self.interpolatedPositionY) / deltaTime
    end
    self.interpolatedPositionX = interpolatedPositionX
    self.interpolatedPositionY = interpolatedPositionY
    self.interpolatedPositionZ = interpolatedPositionZ
    self.interpolatedYaw = interpolatedYaw
    self.interpolatedSpeed = speedXZ * 1000
    self.interpolatedVelocityX = dirX * speedXZ
    self.interpolatedVelocityZ = dirZ * speedXZ
    self.interpolatedVelocityY = speedY
    if self.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE then
        self.player.mover:setPosition(interpolatedPositionX, interpolatedPositionY, interpolatedPositionZ)
        self.player.mover:setMovementYaw(interpolatedYaw)
        self.player.mover:setSpeed(speedXZ)
        self.player.mover:setVelocity(self.interpolatedVelocityX, self.interpolatedVelocityZ, self.interpolatedVelocityZ)
    end
end
function PlayerPositionalInterpolator:updateTick(_)
    if self.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE then
        if self.targetPhysicsIndex >= 0 then
            local x, y, z = self.player.mover:getPosition()
            local targetPositionX, targetPositionY, targetPositionZ
            if self.player.isOwner or not getIsPhysicsUpdateIndexSimulated(self.targetPhysicsIndex) then
                targetPositionX = self.positionInterpolator.targetPositionX
                targetPositionY = interpolator.targetPositionY
                targetPositionZ = interpolator.targetPositionZ
                local distanceY = x - targetPositionX
                local distanceX = math.abs(distanceY)
                local distanceZ = y - targetPositionY
                local distanceY = math.abs(distanceZ)
                local isVeryClose = z - targetPositionZ
                local distanceZ = math.abs(isVeryClose)
                local isVeryClose = false
                if distanceX < 0.001 then
                    isVeryClose = false
                    if distanceY < 0.001 then
                        isVeryClose = distanceZ < 0.001
                    end
                end
                if not isVeryClose then
                    targetPositionZ = z
                    targetPositionY = y
                    targetPositionX = x
                end
            else
                self.targetPhysicsIndex = -1
                targetPositionZ = z
                targetPositionY = y
                targetPositionX = x
            end
            self:setTargetPosition(targetPositionX, targetPositionY, targetPositionZ)
            self.timeInterpolator:startNewPhase(75)
            local targetPositionX = self.player:getYaw()
            local targetPositionY = self.yawInterpolator.targetValue
            local isVeryClose = targetPositionX - targetPositionY
            if math.abs(isVeryClose) < 0.005 then
            end
            self:setTargetYaw(targetPositionX)
        end
    end
end
function PlayerPositionalInterpolator:startNetworkNewPhase()
    self.timeInterpolator:startNewPhaseNetwork()
end
function PlayerPositionalInterpolator:setTargetPosition(targetPositionX, targetPositionY, targetPositionZ)
    local _ = self.player.isOwner
    self.positionInterpolator:setTargetPosition(targetPositionX, targetPositionY, targetPositionZ)
end
function PlayerPositionalInterpolator:setPosition(x, y, z)
    self.positionInterpolator:setPosition(x, y, z)
    self.timeInterpolator:reset()
    self.targetPhysicsIndex = -1
end
function PlayerPositionalInterpolator:onPlayerPositionTeleport(x, y, z)
    self.positionInterpolator:setPosition(x, y, z)
end
function PlayerPositionalInterpolator:setTargetPhysicsIndex(targetPhysicsIndex)
    self.targetPhysicsIndex = targetPhysicsIndex
end
function PlayerPositionalInterpolator:getInterpolatedPosition()
    return self.interpolatedPositionX, self.interpolatedPositionY, self.interpolatedPositionZ
end
function PlayerPositionalInterpolator:setTargetYaw(targetYaw)
    targetYaw = MathUtil.getValidLimit(targetYaw)
    self.yawInterpolator:setTargetAngle(targetYaw)
end
function PlayerPositionalInterpolator:getInterpolatedYaw()
    return self.interpolatedYaw
end
function PlayerPositionalInterpolator:getInterpolatedSpeed()
    return self.interpolatedSpeed
end
function PlayerPositionalInterpolator:getInterpolatedVelocity()
    return self.interpolatedVelocityX, self.interpolatedVelocityY, self.interpolatedVelocityZ
end