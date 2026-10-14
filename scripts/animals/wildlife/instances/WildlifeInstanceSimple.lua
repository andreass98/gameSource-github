WildlifeInstanceSimple = {}
local WildlifeInstanceSimple_mt = Class(WildlifeInstanceSimple, WildlifeInstance)
function WildlifeInstanceSimple.new(species, customMt)
    -- upvalues: (copy) WildlifeInstanceSimple_mt
    local self = WildlifeInstance.new(species, customMt or WildlifeInstanceSimple_mt)
    self.mover = WildlifeInstanceMover.new(self)
    self.graphics = WildlifeInstanceGraphics.new(self)
    self.sounds = WildlifeInstanceSounds.new(self)
    self.stateMachine = WildlifeStateMachine.new(self)
    self.rootNode = createTransformGroup("WildlifeCreature")
    link(getRootNode(), self.rootNode)
    return self
end
function WildlifeInstanceSimple:delete()
    self.graphics:delete()
    self.mover:delete()
    self.sounds:delete()
    self.stateMachine:delete()
    delete(self.rootNode)
    WildlifeInstanceSimple:superClass().delete(self)
end
function WildlifeInstanceSimple:getCurrentPosition()
    return getWorldTranslation(self.rootNode)
end
function WildlifeInstanceSimple:calculateDistanceFrom(positionX, positionZ)
    local instanceX, _, instanceZ = self:getCurrentPosition()
    return MathUtil.vector2Length(positionX - instanceX, positionZ - instanceZ)
end
function WildlifeInstanceSimple:spawnAt(x, y, z)
    WildlifeInstanceSimple:superClass().spawnAt(self, x, y, z)
    self.mover:recalculateGroundReference(nil, x, y, z)
    setWorldTranslation(self.rootNode, x, y, z)
    self.stateMachine:onInstanceSpawned(x, y, z, self.species)
    self.graphics:onInstanceSpawned(self.species)
    self.sounds:onInstanceSpawned(self.species)
    setVisibility(self.rootNode, true)
end
function WildlifeInstanceSimple:despawn()
    setVisibility(self.rootNode, false)
    self.mover:cancelTarget()
    self.stateMachine:onInstanceDespawned()
    WildlifeInstanceSimple:superClass().despawn(self)
end
function WildlifeInstanceSimple:update(dt)
    WildlifeInstanceSimple:superClass().update(self, dt)
    self.stateMachine:update(dt)
    self.mover:update(dt)
    self.graphics:update(dt)
    if self:getCanDespawnNow() then
        local fleeAngle = MathUtil.randomFloat(-3.141592653589793, 3.141592653589793)
        local fleeDirectionX, fleeDirectionZ = MathUtil.getDirectionFromYRotation(fleeAngle)
        self.stateMachine.states.flee:fleeInDirection(fleeDirectionX, fleeDirectionZ)
        self.stateMachine:changeState(self.stateMachine.states.flee)
    end
end
function WildlifeInstanceSimple:getCanDespawnNow()
    return not self.stateMachine.states.flee.fleeingToDespawn and self.despawnTime ~= nil and self:getSecondsSinceSpawn() >= self.despawnTime
end