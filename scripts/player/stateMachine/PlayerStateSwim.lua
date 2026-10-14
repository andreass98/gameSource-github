PlayerStateSwim = {}
local PlayerStateSwim_mt = Class(PlayerStateSwim, BaseStateMachineState)
PlayerStateSwim.MAXIMUM_ROTATION_SPEED = 180
PlayerStateSwim.MAXIMUM_MOVE_SPEED = 3
PlayerStateSwim.MAXIMUM_SPRINT_SPEED = 5
PlayerStateSwim.SWIM_SUBMERGE_THRESHOLD = 1.4
PlayerStateSwim.SLOW_SUBMERGE_THRESHOLD = 0.4
function PlayerStateSwim.new(player, stateMachine)
    -- upvalues: (copy) PlayerStateSwim_mt
    local self = BaseStateMachineState.new(stateMachine, PlayerStateSwim_mt)
    self.player = player
    return self
end
function PlayerStateSwim:calculateIfShouldBeForced()
    return self:calculateIfSubmerged()
end
function PlayerStateSwim:calculateIfSubmerged()
    if self.player.toggleNoClipCommand == nil or not self.player.toggleNoClipCommand.value then
        return self.player.mover.isSwimming
    else
        return false
    end
end
function PlayerStateSwim:calculateIfMoving()
    return self:calculateIfSubmerged() and self.player.inputComponent.hasMovementInputs
end
function PlayerStateSwim:calculateIfSwimmingNormally()
    return self:calculateIfMoving() and self.player.inputComponent.runAxis == 0
end
function PlayerStateSwim:calculateIfSprinting()
    return self:calculateIfMoving() and self.player.inputComponent.runAxis > 0
end
function PlayerStateSwim:onStateEntered(_)
    if self.player.isOwner and self.player:getIsHoldingHandTool() then
        self.player:setCurrentHandTool(nil)
    end
end
function PlayerStateSwim:updateAsCurrent(_)
    if not self:calculateIfShouldBeForced() then
        self.stateMachine:determineState()
    end
end
function PlayerStateSwim:calculateMaximumSpeed()
    if self:calculateIfSprinting() then
        return PlayerStateSwim.MAXIMUM_SPRINT_SPEED
    else
        return PlayerStateSwim.MAXIMUM_MOVE_SPEED
    end
end
function PlayerStateSwim:calculateDesiredSpeed(_, _)
    if not self:calculateIfSprinting() then
        return self.player.mover:calculateSmoothSpeed(self.player.inputComponent.walkAxis, false, 0, PlayerStateSwim.MAXIMUM_MOVE_SPEED)
    end
    return self.player.mover:calculateSmoothSpeed(self.player.inputComponent.runAxis * self.player.inputComponent.walkAxis, false, PlayerStateSwim.MAXIMUM_MOVE_SPEED, PlayerStateSwim.MAXIMUM_SPRINT_SPEED)
end
function PlayerStateSwim:calculateDesiredHorizontalVelocity(directionX, directionZ)
    local speed = self:calculateDesiredSpeed()
    return directionX * speed, directionZ * speed
end