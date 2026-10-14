WildlifeIdleState = {}
local WildlifeIdleState_mt = Class(WildlifeIdleState, BaseStateMachineState)
WildlifeIdleState.DEFAULT_ATTRIBUTES = {
    ["eatDuration"] = {
        ["minimum"] = 1,
        ["maximum"] = 2
    },
    ["attentionDuration"] = {
        ["minimum"] = 1,
        ["maximum"] = 2
    }
}
WildlifeIdleState.SOUND_TOGGLE_TARGET = 25
function WildlifeIdleState.registerXMLPaths(xmlSchema)
    xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.idle#eatDuration", "The range of durations in which the wildlife will eat", WildlifeSpecies.formatRange(WildlifeIdleState.DEFAULT_ATTRIBUTES.eatDuration), false)
    xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.idle#attentionDuration", "The range of durations in which the wildlife will look for danger", WildlifeSpecies.formatRange(WildlifeIdleState.DEFAULT_ATTRIBUTES.attentionDuration), false)
end
function WildlifeIdleState.new(stateMachine)
    -- upvalues: (copy) WildlifeIdleState_mt
    local self = BaseStateMachineState.new(stateMachine, WildlifeIdleState_mt)
    self.isEating = false
    self.currentAnimationTimer = 0
    self.soundToggleCounter = 0
    return self
end
function WildlifeIdleState:createTransitions()
    self:addTransition(self.stateMachine.states.wander.canStartWandering, self.stateMachine.states.wander)
end
function WildlifeIdleState:onStateEntered(_)
    self.isEating = true
    self:toggleCurrentAnimation()
end
function WildlifeIdleState:toggleCurrentAnimation()
    local timerRange
    if self.isEating then
        self.isEating = false
        self.stateMachine.instance.graphics:transitionToAnimation("idleAttention")
        timerRange = self.stateMachine.instance.species.behaviourAttributes.idle.attentionDuration
    else
        self.isEating = true
        self.stateMachine.instance.graphics:transitionToAnimation("idleEat")
        timerRange = self.stateMachine.instance.species.behaviourAttributes.idle.eatDuration
    end
    if self.soundToggleCounter >= WildlifeIdleState.SOUND_TOGGLE_TARGET then
        self.stateMachine.instance.sounds:playSound("idle")
        self.soundToggleCounter = 0
    else
        self.soundToggleCounter = self.soundToggleCounter + 1
    end
    self.currentAnimationTimer = MathUtil.randomFloat(timerRange.minimum, timerRange.maximum) * 1000
end
function WildlifeIdleState:updateAsCurrent(dt)
    if self:trySwitchToValidTransition() == nil then
        self.currentAnimationTimer = self.currentAnimationTimer - dt
        if self.currentAnimationTimer <= 0 then
            self:toggleCurrentAnimation()
        end
    end
end
function WildlifeIdleState.loadAttributesTable(xmlFile)
    local eatDuration = xmlFile:getValue("species.behavior.idle#eatDuration", nil, true)
    if eatDuration == nil then
        ({}).eatDuration = WildlifeIdleState.DEFAULT_ATTRIBUTES.eatDuration
    else
        attributes.eatDuration = {
            ["minimum"] = eatDuration[1],
            ["maximum"] = eatDuration[2]
        }
    end
    local attentionDuration = xmlFile:getValue("species.behavior.idle#attentionDuration", nil, true)
    if attentionDuration == nil then
        attributes.attentionDuration = WildlifeIdleState.DEFAULT_ATTRIBUTES.attentionDuration
        return attributes
    else
        attributes.attentionDuration = {
            ["minimum"] = attentionDuration[1],
            ["maximum"] = attentionDuration[2]
        }
        return attributes
    end
end