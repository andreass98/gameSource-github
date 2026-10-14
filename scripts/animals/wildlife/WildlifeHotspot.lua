WildlifeHotspot = {}
local WildlifeHotspot_mt = Class(WildlifeHotspot)
WildlifeHotspot.MAXIMUM_INSTANCES_PER_HOTSPOT = 2
WildlifeHotspot.MAXIMUM_LIFESPAN = 10
WildlifeHotspot.HOTSPOT_TYPE_ENUM = {
    ["FIELD_SEEDS"] = 0,
    ["DUMPED_GRAINS"] = 1
}
function WildlifeHotspot.new(wildlifeManager)
    -- upvalues: (copy) WildlifeHotspot_mt
    local self = setmetatable({}, WildlifeHotspot_mt)
    self.wildlifeManager = wildlifeManager
    self.worldX = 0
    self.worldY = -200
    self.worldZ = 0
    self.radius = 0
    self.hotspotType = WildlifeHotspot.HOTSPOT_TYPE_ENUM.FIELD_SEEDS
    self.attractedSpecies = {}
    self.spawnedInstanceCount = 0
    self.timeOfCreation = g_time
    return self
end
function WildlifeHotspot:spawnAt(worldX, worldY, worldZ, radius, hotspotType)
    worldY = worldY or getTerrainHeightAtWorldPos(g_terrainNode, worldX, 0, worldZ)
    self.worldX = worldX
    self.worldY = worldY
    self.worldZ = worldZ
    self.radius = radius
    self.hotspotType = hotspotType
    self.timeOfCreation = g_time
    table.clear(self.attractedSpecies)
    for _, species in pairs(self.wildlifeManager.species) do
        if species.hotspotType == self.hotspotType then
            table.insert(self.attractedSpecies, species)
        end
    end
    if #self.attractedSpecies <= 0 then
        return false
    end
    self.spawnedInstanceCount = 0
    return true
end
function WildlifeHotspot:calculateRandomTargetInRadius()
    local randomAngle = MathUtil.randomFloat(-3.141592653589793, 3.141592653589793)
    local randomDistance = MathUtil.randomFloat(0, self.radius)
    local randomX = self.worldX + math.cos(randomAngle) * randomDistance
    local randomZ = self.worldZ + math.sin(randomAngle) * randomDistance
    return randomX, getTerrainHeightAtWorldPos(g_terrainNode, randomX, 0, randomZ), randomZ
end
function WildlifeHotspot:calculateRandomSpawnPositionForSpecies(_)
    local spawnX, spawnZ = self.wildlifeManager:calculateRandomSpawnPositionAroundPlayer(g_localPlayer)
    return spawnX, getTerrainHeightAtWorldPos(g_terrainNode, spawnX, 0, spawnZ), spawnZ
end
function WildlifeHotspot:trySpawnInstances()
    if self.spawnedInstanceCount >= WildlifeHotspot.MAXIMUM_INSTANCES_PER_HOTSPOT then
        return
    else
        local species = table.getRandomElement(self.attractedSpecies)
        local spawnX, spawnY, spawnZ = self:calculateRandomSpawnPositionForSpecies(species)
        local mainInstance, group = self.wildlifeManager:spawnInstanceAt(spawnX, spawnY, spawnZ, species, false, true, species.hotspotReuseTime)
        if mainInstance == nil then
            return
        elseif group then
            self.spawnedInstanceCount = self.spawnedInstanceCount + #group
            for _, instance in pairs(group) do
                local targetX, targetY, targetZ = self:calculateRandomTargetInRadius()
                instance.mover:flyOrMoveToTarget(targetX, targetY, targetZ, nil, false)
            end
        else
            self.spawnedInstanceCount = self.spawnedInstanceCount + 1
            local targetX, targetY, targetZ = self:calculateRandomTargetInRadius()
            mainInstance.mover:flyOrMoveToTarget(targetX, targetY, targetZ)
        end
    end
end