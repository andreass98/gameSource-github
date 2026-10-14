PlayerStateFall = {}
local PlayerStateFall_mt = Class(PlayerStateFall, BaseStateMachineState)
PlayerStateFall.MAXIMUM_ROTATION_SPEED = 45
PlayerStateFall.MAXIMUM_MOVE_SPEED = 3
PlayerStateFall.GROUND_LANDING_DISTANCE = 2
PlayerStateFall.FALL_TIME_THRESHOLD = 1.2
function PlayerStateFall.new(player, stateMachine)
    -- upvalues: (copy) PlayerStateFall_mt
    local self = BaseStateMachineState.new(stateMachine, PlayerStateFall_mt)
    self.player = player
    return self
end
function PlayerStateFall:calculateIfShouldBeForced()
    return self:calculateIfFalling() and self.stateMachine.currentState ~= self.stateMachine.states.jumping
end
function PlayerStateFall:calculateIfFalling()
    return not self.stateMachine.states.swimming:calculateIfSubmerged() and self.player.mover.currentFallTime >= PlayerStateFall.FALL_TIME_THRESHOLD
end
function PlayerStateFall:calculateIfLanding()
    return self.player.mover.currentGroundDistance <= PlayerStateFall.GROUND_LANDING_DISTANCE
end
function PlayerStateFall:updateAsCurrent(_)
    if not self:calculateIfShouldBeForced() then
        self.stateMachine:determineState()
    end
end
function PlayerStateFall:calculateMaximumSpeed()
    return PlayerStateFall.MAXIMUM_MOVE_SPEED
end
function PlayerStateFall:calculateDesiredHorizontalVelocity(directionX, directionZ)
    local maximumMoveSpeed = self.player.toggleSuperSpeedCommand.value and PlayerStateFall.MAXIMUM_MOVE_SPEED * 8 or PlayerStateFall.MAXIMUM_MOVE_SPEED
    return directionX * maximumMoveSpeed, directionZ * maximumMoveSpeed
end