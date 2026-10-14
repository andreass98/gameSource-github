WildlifeStateMachine = {}
local WildlifeStateMachine_mt = Class(WildlifeStateMachine, StateMachine)
function WildlifeStateMachine.new(instance)
    -- upvalues: (copy) WildlifeStateMachine_mt
    local self = StateMachine.new(WildlifeStateMachine_mt)
    self.instance = instance
    self.states = {
        ["idle"] = WildlifeIdleState.new(self),
        ["wander"] = WildlifeWanderState.new(self),
        ["flee"] = WildlifeFleeState.new(self),
        ["follow"] = WildlifeFollowState.new(self)
    }
    self:initialiseStateTransitions()
    self.currentState = self.states.idle
    self.defaultState = self.states.idle
    return self
end
function WildlifeStateMachine:onInstanceSpawned(spawnX, spawnY, spawnZ, species, group, mainInstance)
    self:callStateFunction("onInstanceSpawned", spawnX, spawnY, spawnZ, species, group, mainInstance)
    self:changeState(self.states.idle)
    self.states.idle:updateAsCurrent(g_currentDt)
end
function WildlifeStateMachine:onInstanceDespawned()
    self:callStateFunction("onInstanceDespawned")
end
function WildlifeStateMachine:onMovementTargetReached()
    self:callStateFunction("onMovementTargetReached")
end
function WildlifeStateMachine:callStateFunction(functionName, ...)
    WildlifeStateMachine:superClass().callStateFunction(self, functionName, ...)
end