PlayerStateMachine = {}
local PlayerStateMachine_mt = Class(PlayerStateMachine, StateMachine)
function PlayerStateMachine.new(player)
    -- upvalues: (copy) PlayerStateMachine_mt
    local self = StateMachine.new(PlayerStateMachine_mt)
    self.player = player
    self.states = {
        ["onFoot"] = PlayerOnFootStateMachine.new(player),
        ["driving"] = PlayerStateDriving.new(player, self),
        ["passenger"] = PlayerStatePassenger.new(player, self),
        ["rollercoaster"] = PlayerStateRollercoaster.new(player, self)
    }
    self:initialiseStateTransitions()
    self.currentState = self.states.onFoot
    self.defaultState = self.states.onFoot
    self:setIsPassive(true)
    return self
end
function PlayerStateMachine:updateWhilePaused(dt, isInGui, isFrozen)
    self:callStateFunction("updateWhilePaused", dt, isInGui, isFrozen)
end