StateMachine = {}
local StateMachine_mt = Class(StateMachine)
StateMachine.STATE_INDEX_NUM_BITS = 5
function StateMachine.new(custom_mt)
    -- upvalues: (copy) StateMachine_mt
    local self = setmetatable({}, custom_mt or StateMachine_mt)
    self.currentState = nil
    self.defaultState = nil
    self.isPassive = false
    self.states = {}
    self.sortedStates = nil
    return self
end
function StateMachine:delete()
    if self.currentState ~= nil then
        self.currentState:onStateExited(nil)
    end
end
function StateMachine:createStateIndexNameMapping(isForced)
    if isForced or not self:getHasMappings() then
        self.sortedStates = {}
        for stateName, state in pairs(self.states) do
            if string.isNilOrWhitespace(state.name) then
                self:initialiseStateNames()
            end
            table.insert(self.sortedStates, state)
        end
        table.sort(self.sortedStates, function(a, b)
            return a.name < b.name
        end)
    end
end
function StateMachine:implementStateInterface()
    for name, value in pairs(BaseStateMachineState) do
        if not self[name] then
            self[name] = value
        end
    end
end
function StateMachine:changeState(newState, ...)
    local previousState = self.currentState
    self.currentState = newState
    previousState:onStateExited(newState)
    newState:onStateEntered(previousState, ...)
end
function StateMachine:initialiseStateNames()
    for stateName, state in pairs(self.states) do
        if string.isNilOrWhitespace(state.name) then
            state.name = stateName
        end
    end
end
function StateMachine:initialiseStateTransitions(...)
    for _, state in pairs(self.states) do
        state:createTransitions(...)
    end
end
function StateMachine:determineState()
    for _, state in pairs(self.states) do
        if state:calculateIfValidEntryState() then
            self:changeState(state)
            return
        end
    end
    self:changeState(self.defaultState)
end
function StateMachine:resolveCurrentState()
    return self.currentState.resolveCurrentState ~= nil and self.currentState:resolveCurrentState() or self.currentState
end
function StateMachine:getCurrentStateName()
    return self:getNameOfState(self.currentState)
end
function StateMachine:getNameOfState(state)
    if state == nil then
        return "No state"
    end
    if string.isNilOrWhitespace(state.name) then
        self:initialiseStateNames()
    end
    return state.name
end
function StateMachine:getCurrentStateIndex()
    return self:getIndexOfState(self.currentState)
end
function StateMachine:getIndexOfState(state)
    if not self:getHasMappings() then
        self:createStateIndexNameMapping()
    end
    for i, otherState in ipairs(self.sortedStates) do
        if otherState == state then
            return i
        end
    end
    return nil
end
function StateMachine:getStateByIndex(index)
    if not self:getHasMappings() then
        self:createStateIndexNameMapping()
    end
    return self.sortedStates[index]
end
function StateMachine:getHasMappings()
    return self.sortedStates ~= nil
end
function StateMachine:getIsPassive()
    return self.isPassive
end
function StateMachine:setIsPassive(isPassive)
    self.isPassive = isPassive == true
end
function StateMachine:update(dt)
    if not self:getIsPassive() then
        for _, state in pairs(self.states) do
            if state:calculateIfShouldBeForced() and state ~= self.currentState then
                self:changeState(state)
                break
            end
        end
    end
    for _, state in pairs(self.states) do
        if state == self.currentState then
            state:updateAsCurrent(dt)
        else
            state:updateAsInactive(dt)
        end
    end
end
function StateMachine:callStateFunction(functionName, ...)
    for _, state in pairs(self.states) do
        if state[functionName] ~= nil then
            state[functionName](state, ...)
        end
    end
end