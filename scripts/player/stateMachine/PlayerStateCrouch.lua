PlayerStateCrouch = {}
local PlayerStateCrouch_mt = Class(PlayerStateCrouch, BaseStateMachineState)
PlayerStateCrouch.MAXIMUM_ROTATION_SPEED = 180
PlayerStateCrouch.MAXIMUM_MOVE_SPEED = 3
PlayerStateCrouch.SMOOTHING_TIME = 0.2
PlayerStateCrouch.CROUCHED_CAMERA_OFFSET = -0.6
function PlayerStateCrouch.new(player, stateMachine)
    -- upvalues: (copy) PlayerStateCrouch_mt
    local self = BaseStateMachineState.new(stateMachine, PlayerStateCrouch_mt)
    self.player = player
    self.cameraOffsetY = 0
    self.crouchTime = 0
    self.transitionTime = 0
    return self
end
function PlayerStateCrouch:createTransitions()
    self:addTransition(self.stateMachine.states.idle.calculateIfIdle, self.stateMachine.states.idle)
    self:addTransition(self.stateMachine.states.walking.calculateIfMoving, self.stateMachine.states.walking)
    self:addTransition(self.stateMachine.states.jumping.calculateIfJumping, self.stateMachine.states.jumping)
end
function PlayerStateCrouch:calculateIfValidEntryState()
    return self:calculateIfCrouching() and self.player.mover.isGrounded and not self.stateMachine.states.swimming:calculateIfSubmerged()
end
function PlayerStateCrouch:calculateIfCrouching()
    if not self.player.isOwner then
        return false
    end
    return self.player.inputComponent.crouchValue > 0 and (not self.player:getIsHoldingHandTool() or self.player:getHeldHandTool().canCrouch) and self.player.mover.currentWaterSubmergeDistance < 1
end
function PlayerStateCrouch:onStateEntered(_)
    self.player.mover:setIsCrouching(true)
    self:resetTimers()
end
function PlayerStateCrouch:onStateExited(_)
    self.player.mover:setIsCrouching(false)
    self:resetTimers()
end
function PlayerStateCrouch:resetTimers()
    self.transitionTime = 0
    self.crouchTime = 0
    self.cameraOffsetY = 0
end
function PlayerStateCrouch:updateAsCurrent(dt)
    if self:calculateIfCrouching() then
        self.player.capsuleController:setHeight(PlayerCCT.DEFAULT_HEIGHT * 0.5)
        self.crouchTime = self.crouchTime + dt * 0.001
        self.transitionTime = math.min(self.transitionTime + dt * 0.001, PlayerStateCrouch.SMOOTHING_TIME)
    else
        self.player.capsuleController:setHeight(PlayerCCT.DEFAULT_HEIGHT)
        if self.player.capsuleController:getHeight() == PlayerCCT.DEFAULT_HEIGHT then
            self.crouchTime = 0
            self.transitionTime = math.max(0, self.transitionTime - dt * 0.001)
        end
    end
    local crouchProgress = math.clamp(self.transitionTime / PlayerStateCrouch.SMOOTHING_TIME, 0, 1)
    self.cameraOffsetY = PlayerStateCrouch.CROUCHED_CAMERA_OFFSET * crouchProgress
    if not self.stateMachine:getIsPassive() and (self.transitionTime <= 0 and self.player.capsuleController:getHeight() == PlayerCCT.DEFAULT_HEIGHT) then
        self:trySwitchToValidTransition()
    end
end
function PlayerStateCrouch:calculateMaximumSpeed()
    return PlayerStateCrouch.MAXIMUM_MOVE_SPEED
end
function PlayerStateCrouch:calculateDesiredHorizontalVelocity(directionX, directionZ)
    local speed = self.player.mover:calculateSmoothSpeed(self.player.inputComponent.walkAxis, true, 0, PlayerStateCrouch.MAXIMUM_MOVE_SPEED)
    return directionX * speed, directionZ * speed
end