WildlifeFollowState = {}
local WildlifeFollowState_mt = Class(WildlifeFollowState, BaseStateMachineState)
WildlifeFollowState.DEFAULT_ATTRIBUTES = {
    ["frequency"] = {
        ["minimum"] = 120,
        ["maximum"] = 360
    },
    ["targetRange"] = {
        ["minimum"] = 2,
        ["maximum"] = 4
    },
    ["maximumDistance"] = 6
}
function WildlifeFollowState.registerXMLPaths(xmlSchema)
    xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.follow#frequency", "The range of seconds that the instance will wait between going to a position around the target", WildlifeSpecies.formatRange(WildlifeFollowState.DEFAULT_ATTRIBUTES.frequency), false)
    xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.follow#targetRange", "The range of radii where the instance can set a target", WildlifeSpecies.formatRange(WildlifeFollowState.DEFAULT_ATTRIBUTES.targetRange), false)
    xmlSchema:register(XMLValueType.FLOAT, "species.behavior.follow#maximumDistance", "The maximum range before the instance will force find a target to the leader", WildlifeFollowState.DEFAULT_ATTRIBUTES.maximumDistance, false)
end
function WildlifeFollowState.new(stateMachine)
    -- upvalues: (copy) WildlifeFollowState_mt
    local self = BaseStateMachineState.new(stateMachine, WildlifeFollowState_mt)
    self.isActive = false
    self.mover = stateMachine.instance.mover
    self.frequency = WildlifeFollowState.DEFAULT_ATTRIBUTES.frequency
    self.targetRange = WildlifeFollowState.DEFAULT_ATTRIBUTES.targetRange
    self.maximumDistance = WildlifeFollowState.DEFAULT_ATTRIBUTES.maximumDistance
    self.timeOfLastTarget = g_time * 0.001
    self.targetCooldown = 0
    self.leaderInstance = nil
    return self
end
function WildlifeFollowState:calculateIfShouldBeForced()
    return self:canSetFollowTarget()
end
function WildlifeFollowState:canSetFollowTarget()
    if not self.isActive or (self.leaderInstance == nil or self.stateMachine.states.flee.fleeingToDespawn) then
        return false
    end
    local currentX, _, currentZ = self.mover.instance:getCurrentPosition()
    return self.leaderInstance:calculateDistanceFrom(currentX, currentZ) >= self.maximumDistance or g_time * 0.001 - self.timeOfLastTarget >= self.targetCooldown
end
function WildlifeFollowState:resetMovementState()
    self.targetCooldown = MathUtil.randomFloat(self.frequency.minimum, self.frequency.maximum)
    self.timeOfLastTarget = g_time * 0.001
end
function WildlifeFollowState:onStateEntered(_)
    self.timeOfLastTarget = g_time * 0.001
    local targetX, targetY, targetZ = self.leaderInstance:getCurrentPosition()
    local randomAngle = MathUtil.randomFloat(-3.141592653589793, 3.141592653589793)
    local randomDistance = MathUtil.randomFloat(self.targetRange.minimum, self.targetRange.maximum)
    local targetX = targetX + math.cos(randomAngle) * randomDistance
    local targetZ = targetZ + math.sin(randomAngle) * randomDistance
    local moveSpeed = math.max(1, self.leaderInstance.mover.currentAverageSpeed * 1.1)
    if self.leaderInstance.mover.isFlyingToTarget and self.stateMachine.instance.species.movementAttributes.canFly then
        self.mover:flyToTarget(targetX, targetY, targetZ, moveSpeed)
    else
        self.mover:moveToTarget(targetX, targetY, targetZ, moveSpeed)
    end
end
function WildlifeFollowState:onStateExited(_)
    self:resetMovementState()
end
function WildlifeFollowState:onInstanceSpawned(_, _, _, species, _, mainInstance)
    self.isActive = species.behaviourAttributes.follow ~= nil
    if self.isActive then
        self.frequency = species.behaviourAttributes.follow.frequency
        self.targetRange = species.behaviourAttributes.follow.targetRange
        self.maximumDistance = species.behaviourAttributes.follow.maximumDistance
        self.timeOfLastTarget = g_time * 0.001 - MathUtil.randomFloat(0, self.frequency.maximum)
        self.targetCooldown = MathUtil.randomFloat(self.frequency.minimum, self.frequency.maximum)
        if self.mover.instance ~= mainInstance and (mainInstance ~= nil and self.stateMachine.instance.species.behaviourAttributes.follow ~= nil) then
            self.leaderInstance = mainInstance
            self.stateMachine:changeState(self)
        end
    else
        return
    end
end
function WildlifeFollowState:onInstanceDespawned()
    self.leaderInstance = nil
    self.isActive = false
    self:resetMovementState()
end
function WildlifeFollowState:onMovementTargetReached()
    if self.stateMachine.currentState == self then
        if not self:canSetFollowTarget() then
            self.stateMachine:determineState()
        end
        self:resetMovementState()
    end
end
function WildlifeFollowState.loadAttributesTable(xmlFile)
    local frequency = xmlFile:getValue("species.behavior.follow#frequency", nil, true)
    if frequency == nil then
        return nil
    else
        ({}).frequency = {
            ["minimum"] = frequency[1],
            ["maximum"] = frequency[2]
        }
        local targetRange = xmlFile:getValue("species.behavior.follow#targetRange", nil, true)
        if targetRange == nil then
            return nil
        else
            attributes.targetRange = {
                ["minimum"] = targetRange[1],
                ["maximum"] = targetRange[2]
            }
            attributes.maximumDistance = xmlFile:getValue("species.behavior.follow#maximumDistance", nil)
            if attributes.maximumDistance == nil then
                return nil
            else
                return attributes
            end
        end
    end
end