WildlifeInstance = {}
local WildlifeInstance_mt = Class(WildlifeInstance)
function WildlifeInstance.new(species, customMt)
    -- upvalues: (copy) WildlifeInstance_mt
    local self = setmetatable({}, customMt or WildlifeInstance_mt)
    self.species = species
    self.spawnedAtTimestamp = 0
    self.despawnTime = nil
    return self
end
function WildlifeInstance:delete() end
function WildlifeInstance:update(dt) end
function WildlifeInstance:drawDebug() end
function WildlifeInstance:getNumAnimals()
    return 1
end
function WildlifeInstance:spawnAt(_, _, _)
    self:setSpawnTimestampToNow()
    self:randomiseDespawnTime()
end
function WildlifeInstance:despawn() end
function WildlifeInstance:getSecondsSinceSpawn()
    return g_time * 0.001 - self.spawnedAtTimestamp
end
function WildlifeInstance:setSpawnTimestampToNow()
    self.spawnedAtTimestamp = g_time * 0.001
end
function WildlifeInstance:randomiseDespawnTime()
    if self.species.despawnTimeRange == nil then
        self.despawnTime = nil
    else
        self.despawnTime = MathUtil.randomFloat(self.species.despawnTimeRange.minimum, self.species.despawnTimeRange.maximum)
    end
end