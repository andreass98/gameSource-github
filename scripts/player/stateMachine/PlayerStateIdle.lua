PlayerStateIdle = {}
local PlayerStateIdle_mt = Class(PlayerStateIdle, BaseStateMachineState)
function PlayerStateIdle.new(player, stateMachine)
    -- upvalues: (copy) PlayerStateIdle_mt
    local self = BaseStateMachineState.new(stateMachine, PlayerStateIdle_mt)
    self.player = player
    return self
end
function PlayerStateIdle:createTransitions()
    self:addTransition(self.stateMachine.states.walking.calculateIfMoving, self.stateMachine.states.walking)
    self:addTransition(self.stateMachine.states.jumping.calculateIfJumping, self.stateMachine.states.jumping)
    self:addTransition(self.stateMachine.states.crouching.calculateIfCrouching, self.stateMachine.states.crouching)
end
function PlayerStateIdle:calculateIfValidEntryState()
    return self:calculateIfIdle() and self.player.mover.isGrounded
end
function PlayerStateIdle:calculateIfIdle()
    if self.player.isOwner then
        return self.player.mover:getSpeed() <= 0.01 and not self.player.inputComponent.hasMovementInputs and not self.stateMachine.states.crouching:calculateIfCrouching()
    else
        return self.player.mover:getSpeed() <= 0.01 and not self.stateMachine.states.crouching:calculateIfCrouching()
    end
end