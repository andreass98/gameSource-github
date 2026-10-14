WildlifeWanderState = {}
local WildlifeWanderState_mt = Class(WildlifeWanderState, BaseStateMachineState)
WildlifeWanderState.DEFAULT_ATTRIBUTES = {
    ["frequency"] = {
        ["minimum"] = 120,
        ["maximum"] = 360
    },
    ["walkRange"] = {
        ["minimum"] = 1,
        ["maximum"] = 2
    },
    ["flyRange"] = nil,
    ["swimRange"] = nil,
    ["flyChance"] = nil
}
WildlifeWanderState.MAXIMUM_WALKABLE_HEIGHT = 1
WildlifeWanderState.CALCULATION_STATE_ENUM = {
    ["NONE"] = 1,
    ["FINDING_TARGET"] = 2,
    ["MOVING"] = 3,
    ["REACHED_TARGET"] = 4
}
function WildlifeWanderState.registerXMLPaths(xmlSchema)
    xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.wander#frequency", "The minimum and maximum frequency that this species will want to move somewhere else. Every time the species moves, a value between these values will be generated", WildlifeSpecies.formatRange(WildlifeWanderState.DEFAULT_ATTRIBUTES.frequency), false)
    xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.wander.walk#range", "The minimum and maximum range that this species will walk", WildlifeSpecies.formatRange(WildlifeWanderState.DEFAULT_ATTRIBUTES.walkRange), false)
    xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.wander.fly#range", "The minimum and maximum range that this species will fly", WildlifeSpecies.formatRange(WildlifeWanderState.DEFAULT_ATTRIBUTES.flyRange), false)
    xmlSchema:register(XMLValueType.FLOAT, "species.behavior.wander.fly#chance", "The chance that this species will fly rather than walk to its target", WildlifeWanderState.DEFAULT_ATTRIBUTES.flyChance, false)
    xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.wander.swim#range", "The minimum and maximum range that this species will swim", WildlifeSpecies.formatRange(WildlifeWanderState.DEFAULT_ATTRIBUTES.swimRange), false)
end
function WildlifeWanderState.new(stateMachine)
    -- upvalues: (copy) WildlifeWanderState_mt
    local self = BaseStateMachineState.new(stateMachine, WildlifeWanderState_mt)
    self.isActive = false
    self.mover = stateMachine.instance.mover
    self.frequency = WildlifeWanderState.DEFAULT_ATTRIBUTES.frequency
    self.walkRange = WildlifeWanderState.DEFAULT_ATTRIBUTES.walkRange
    self.flyRange = WildlifeWanderState.DEFAULT_ATTRIBUTES.flyRange
    self.swimRange = WildlifeWanderState.DEFAULT_ATTRIBUTES.swimRange
    self.flyChance = WildlifeWanderState.DEFAULT_ATTRIBUTES.flyChance
    self.lastWanderedAt = nil
    self.wanderCooldown = 0
    self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.NONE
    self.isFlying = false
    self.pendingTargetCheck = nil
    return self
end
function WildlifeWanderState:createTransitions()
    self:addTransition(self.hasFinishedWandering, self.stateMachine.states.idle, self)
end
function WildlifeWanderState:initialiseToSpecies(species) end
function WildlifeWanderState:canStartWandering()
    return self.isActive and not self.stateMachine.instance.mover:getIsMoving() and (g_time * 0.001 - math.abs(self.lastWanderedAt) >= self.wanderCooldown and self.calculationState == WildlifeWanderState.CALCULATION_STATE_ENUM.NONE)
end
function WildlifeWanderState:hasFinishedWandering()
    return self.calculationState == WildlifeWanderState.CALCULATION_STATE_ENUM.REACHED_TARGET
end
function WildlifeWanderState:onStateEntered(_)
    self.wanderCooldown = MathUtil.randomFloat(self.frequency.minimum, self.frequency.maximum)
    self:randomlySetTarget()
    self.stateMachine.instance.graphics:transitionToAnimation("idleAttention")
end
function WildlifeWanderState:onStateExited(_)
    self.lastWanderedAt = g_time * 0.001
    self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.NONE
    self.pendingTargetCheck = nil
end
function WildlifeWanderState:randomlySetTarget()
    self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.FINDING_TARGET
    local isFlying = false
    local range
    if self.mover.canFly and (self.flyRange and math.random() <= self.flyChance) then
        isFlying = true
        range = self.flyRange
    elseif self.mover.canSwim and (self.swimRange and self.mover.isSwimming) then
        range = self.swimRange
    else
        range = self.walkRange
    end
    local currentX, currentY, currentZ = self.mover.instance:getCurrentPosition()
    local randomAngle = MathUtil.randomFloat(-3.141592653589793, 3.141592653589793)
    local randomX = currentX + math.cos(randomAngle) * MathUtil.randomFloat(math.min(range.minimum, WildlifeInstanceMover.MINIMUM_TARGET_DISTANCE), range.maximum)
    self.pendingTargetCheck = true
    self.isFlying = isFlying
    raycastClosestAsync(randomX, currentY + 100, currentZ + math.sin(randomAngle) * randomDistance, 0, -1, 0, 200, "onTargetCallback", self, WildlifeInstanceMover.COLLISION_MASK)
end
function WildlifeWanderState:onTargetCallback(nodeId, x, y, z, _, _, _, _, _, _, _)
    if self.pendingTarget == nil then
        return
    else
        self.pendingTargetCheck = nil
        if nodeId == nil or nodeId == 0 then
            return
        else
            local correctedTargetY = WildlifeInstanceMover.adjustRayHitForWater(nodeId, x, y, z, self.stateMachine.instance.species.movementAttributes, true)
            if correctedTargetY == nil then
                return
            else
                local isMoving
                if self.isFlying then
                    isMoving = self.mover:flyToTarget(x, correctedTargetY, z)
                else
                    isMoving = self.mover:moveToTarget(x, correctedTargetY, z)
                end
                if isMoving then
                    self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.MOVING
                    self.stateMachine.instance.graphics:transitionToAnimation("idleWalk")
                end
            end
        end
    end
end
function WildlifeWanderState:onInstanceSpawned(_, _, _, species, _, _)
    self.isActive = species.behaviourAttributes.wander ~= nil
    if self.isActive then
        self.frequency = species.behaviourAttributes.wander.frequency
        self.walkRange = species.behaviourAttributes.wander.walkRange
        self.flyRange = species.behaviourAttributes.wander.flyRange
        self.flyChance = species.behaviourAttributes.wander.flyChance
        self.swimRange = species.behaviourAttributes.wander.swimRange
        self.lastWanderedAt = g_time * 0.001 - MathUtil.randomFloat(0, self.frequency.maximum)
        self.wanderCooldown = MathUtil.randomFloat(self.frequency.minimum, self.frequency.maximum)
    end
end
function WildlifeWanderState:onInstanceDespawned()
    self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.NONE
    self.pendingTargetCheck = nil
end
function WildlifeWanderState:onMovementTargetReached()
    self.wanderCooldown = MathUtil.randomFloat(self.frequency.minimum, self.frequency.maximum)
    self.lastWanderedAt = g_time * 0.001
    if self.stateMachine.currentState == self then
        self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.REACHED_TARGET
    else
        self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.NONE
    end
end
function WildlifeWanderState:updateAsCurrent(_)
    if self.calculationState == WildlifeWanderState.CALCULATION_STATE_ENUM.FINDING_TARGET and not self.pendingTargetCheck then
        self:randomlySetTarget()
    end
    self:trySwitchToValidTransition()
end
function WildlifeWanderState.loadAttributesTable(xmlFile)
    local attributes = {}
    local frequency = xmlFile:getValue("species.behavior.wander#frequency", nil, true)
    if not frequency then
        return nil
    end
    attributes.frequency = {
        ["minimum"] = frequency[1],
        ["maximum"] = frequency[2]
    }
    local walkRange = xmlFile:getValue("species.behavior.wander.walk#range", nil, true)
    if not walkRange then
        return nil
    end
    attributes.walkRange = {
        ["minimum"] = walkRange[1],
        ["maximum"] = walkRange[2]
    }
    local flyRange = xmlFile:getValue("species.behavior.wander.fly#range", nil, true)
    local flyChance = xmlFile:getValue("species.behavior.wander.fly#chance", nil)
    if flyRange and flyChance then
        attributes.flyRange = {
            ["minimum"] = flyRange[1],
            ["maximum"] = flyRange[2]
        }
        attributes.flyChance = flyChance
    else
        if flyRange ~= nil ~= (flyChance ~= nil) then
            Logging.xmlError(xmlFile, "Fly attribute node is missing either range or chance")
            return nil
        end
        attributes.flyRange = WildlifeWanderState.DEFAULT_ATTRIBUTES.flyRange
        attributes.flyChance = WildlifeWanderState.DEFAULT_ATTRIBUTES.flyChance
    end
    local swimRange = xmlFile:getValue("species.behavior.wander.swim#range", nil, true)
    attributes.swimRange = swimRange and {
        ["minimum"] = swimRange[1],
        ["maximum"] = swimRange[2]
    } or WildlifeWanderState.DEFAULT_ATTRIBUTES.swimRange
    return attributes
end