WildlifeInstanceFlyByGroup = {}
local WildlifeInstanceFlyByGroup_mt = Class(WildlifeInstanceFlyByGroup, WildlifeInstance)
function WildlifeInstanceFlyByGroup.new(species, customMt)
    -- upvalues: (copy) WildlifeInstanceFlyByGroup_mt
    local self = WildlifeInstance.new(species, customMt or WildlifeInstanceFlyByGroup_mt)
    self.pooledAnimals = ObjectPool.new(WildlifeAnimalFlyBy.new, species)
    self.animals = {}
    self.numAnimals = 0
    self.flyDirectionX = 0
    self.flyDirectionZ = 1
    self.groupMinRadius = 0.5
    self.groupMaxRadius = 10
    return self
end
function WildlifeInstanceFlyByGroup:delete()
    for _, animal in ipairs(self.animals) do
        self.pooledAnimals:returnToPool(animal)
    end
    table.clear(self.animals)
    for _, animal in pairs(self.pooledAnimals.pool) do
        animal:delete()
    end
    WildlifeInstanceFlyByGroup:superClass().delete(self)
end
function WildlifeInstanceFlyByGroup:getNumAnimals()
    return self.numAnimals
end
function WildlifeInstanceFlyByGroup:setNumAnimals(numAnimals)
    self.numAnimals = numAnimals
end
function WildlifeInstanceFlyByGroup:calculateDistanceFrom(positionX, positionZ)
    return #self.animals == 0 and math.huge or self.animals[1]:calculateDistanceFrom(positionX, positionZ)
end
function WildlifeInstanceFlyByGroup:setFlyDirection(directionX, directionZ)
    self.flyDirectionX = directionX
    self.flyDirectionZ = directionZ
    for _, animal in ipairs(self.animals) do
        animal:setFlyDirection(directionX, directionZ)
    end
end
function WildlifeInstanceFlyByGroup:setGroupRadius(minRadius, maxRadius)
    self.groupMinRadius = minRadius
    self.groupMaxRadius = maxRadius
end
function WildlifeInstanceFlyByGroup:spawnAt(x, y, z)
    WildlifeInstanceFlyByGroup:superClass().spawnAt(self, x, y, z)
    local animal = self.pooledAnimals:getOrCreateNext()
    animal:setFlyDirection(self.flyDirectionX, self.flyDirectionZ)
    animal:spawnAt(x, y, z)
    table.addElement(self.animals, animal)
    local offsetAngle = MathUtil.getYRotationFromDirection(self.flyDirectionX, self.flyDirectionZ) * 3.141592653589793 * 0.5
    local numExtraAnimals = self.numAnimals - 1
    local i = 1
    for i = i, numExtraAnimals do
        local sectionAngle = 6.283185307179586 / numExtraAnimals
        local offset = offsetAngle + sectionAngle * MathUtil.lerp(0.1, 0.9, math.random())
        local angle = (i - 1) * sectionAngle + offset
        local radius = MathUtil.lerp(self.groupMinRadius, self.groupMaxRadius, math.random())
        local x1 = x + math.cos(angle) * radius
        local z2 = z + math.sin(angle) * radius
        local animal = self.pooledAnimals:getOrCreateNext()
        animal:setFlyDirection(self.flyDirectionX, self.flyDirectionZ)
        animal:spawnAt(x1, y, z2)
        table.addElement(self.animals, animal)
    end
end
function WildlifeInstanceFlyByGroup:despawn()
    for _, animal in ipairs(self.animals) do
        animal:despawn()
        self.pooledAnimals:returnToPool(animal)
    end
    table.clear(self.animals)
    WildlifeInstanceFlyByGroup:superClass().despawn(self)
end
function WildlifeInstanceFlyByGroup:update(dt)
    WildlifeInstanceFlyByGroup:superClass().update(dt)
    for _, animal in ipairs(self.animals) do
        animal:update(dt)
    end
end
function WildlifeInstanceFlyByGroup:drawDebug()
    for _, animal in ipairs(self.animals) do
        animal:drawDebug()
    end
end