WildlifeAnimalFlyBy = {}
local WildlifeAnimalFlyBy_mt = Class(WildlifeAnimalFlyBy, WildlifeAnimal)
function WildlifeAnimalFlyBy.new(species, customMt)
    -- upvalues: (copy) WildlifeAnimalFlyBy_mt
    local self = WildlifeAnimal.new(customMt or WildlifeAnimalFlyBy_mt)
    self.species = species
    self.flyDirectionX = 0
    self.flyDirectionZ = 1
    self.graphics = WildlifeInstanceGraphics.new(species.graphics)
    self.graphics:load(self.rootNode)
    return self
end
function WildlifeAnimalFlyBy:delete()
    self.graphics:delete()
    WildlifeAnimalFlyBy:superClass().delete(self)
end
function WildlifeAnimalFlyBy:setFlyDirection(directionX, directionZ)
    self.flyDirectionX = directionX
    self.flyDirectionZ = directionZ
    setWorldDirection(self.rootNode, directionX, 0, directionZ, 0, 1, 0)
end
function WildlifeAnimalFlyBy:spawnAt(x, y, z)
    WildlifeAnimalFlyBy:superClass().spawnAt(self, x, y, z)
    self.graphics:setAnimation("fly")
    self.graphics:setAnimationOffset(math.random())
end
function WildlifeAnimalFlyBy:update(dt)
    WildlifeAnimalFlyBy:superClass().update(self, dt)
    local species = self.species
    local x, y, z = getWorldTranslation(self.rootNode)
    local movedDistance = species.moveDistancePerMs * dt
    local x = x + self.flyDirectionX * movedDistance
    local z = z + self.flyDirectionZ * movedDistance
    local targetHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + species.minDistanceToGround
    local y
    if targetHeight - y > 0 then
        y = math.min(y + species.climbPerMeter * movedDistance, targetHeight)
    else
        y = math.max(y - species.fallPerMeter * movedDistance, targetHeight)
    end
    setWorldTranslation(self.rootNode, x, y, z)
    self.graphics:update(dt)
end
function WildlifeAnimalFlyBy:drawDebug()
    DebugText.renderAtNode(self.rootNode, string.format("%s\nnode:%d", self.species.name, self.rootNode), DebugUtil.getDebugColor(self.rootNode), 0.015)
end