PlayerStateWalk = {}
local PlayerStateWalk_mt = Class(PlayerStateWalk, BaseStateMachineState)
PlayerStateWalk.MAXIMUM_WALK_SPEED = 4
PlayerStateWalk.MAXIMUM_RUN_SPEED = 7
function PlayerStateWalk.new(player, stateMachine)
    -- upvalues: (copy) PlayerStateWalk_mt
    local self = BaseStateMachineState.new(stateMachine, PlayerStateWalk_mt)
    self.player = player
    self.walkAxis = 0
    self.runAxis = 0
    return self
end
function PlayerStateWalk:createTransitions()
    self:addTransition(self.stateMachine.states.idle.calculateIfIdle, self.stateMachine.states.idle)
    self:addTransition(self.stateMachine.states.jumping.calculateIfJumping, self.stateMachine.states.jumping)
    self:addTransition(self.stateMachine.states.crouching.calculateIfCrouching, self.stateMachine.states.crouching)
end
function PlayerStateWalk:calculateIfValidEntryState()
    return self:calculateIfMoving() and self.player.mover.isGrounded and not self.stateMachine.states.swimming:calculateIfSubmerged()
end
function PlayerStateWalk:calculateIfMoving()
    if self.player.isOwner then
        return self.player.mover:getSpeed() <= 0.01 and self.player.inputComponent.hasMovementInputs and not self.stateMachine.states.crouching:calculateIfCrouching()
    else
        return self.player.mover:getSpeed() > 0.01 and not self.stateMachine.states.crouching:calculateIfCrouching()
    end
end
function PlayerStateWalk:calculateIfWalking()
    return self:calculateIfMoving() and self.runAxis == 0
end
function PlayerStateWalk:calculateIfRunning()
    local runMultiplier = self.player:getRunMultiplier()
    return self:calculateIfMoving() and self.runAxis > 0 and runMultiplier > 0
end
function PlayerStateWalk:updateAsCurrent(dt)
    if self.player.isOwner then
        self.walkAxis = self.player.inputComponent.walkAxis
        self.runAxis = self.player.inputComponent.runAxis
        PlayerStateWalk:superClass().updateAsCurrent(self, dt)
    else
        PlayerStateWalk:superClass().updateAsCurrent(self, dt)
    end
end
function PlayerStateWalk:calculateMaximumSpeed()
    if self:calculateIfRunning() then
        return self:getMaximumRunSpeed()
    else
        return self:getMaximumWalkSpeed()
    end
end
function PlayerStateWalk:getMaximumRunSpeed()
    local runSpeed = PlayerStateWalk.MAXIMUM_RUN_SPEED
    if self.player.toggleSuperSpeedCommand ~= nil and self.player.toggleSuperSpeedCommand.value then
    end
    return runSpeed
end
function PlayerStateWalk:getMaximumWalkSpeed()
    return PlayerStateWalk.MAXIMUM_WALK_SPEED
end
function PlayerStateWalk:calculateDesiredSpeed()
    local maxWalkSpeed = self:getMaximumWalkSpeed()
    local maxRunSpeed = self:getMaximumRunSpeed()
    if self:calculateIfRunning() then
        local moveScalar = self.runAxis * self.walkAxis * self.player:getRunMultiplier()
        return self.player.mover:calculateSmoothSpeed(moveScalar, true, maxWalkSpeed, maxRunSpeed)
    else
        local moveScalar = self.walkAxis * self.player:getWalkMultiplier()
        return self.player.mover:calculateSmoothSpeed(moveScalar, true, 0, maxWalkSpeed)
    end
end
function PlayerStateWalk:calculateDesiredHorizontalVelocity(directionX, directionZ)
    local speed = self:calculateDesiredSpeed()
    return directionX * speed, directionZ * speed
end