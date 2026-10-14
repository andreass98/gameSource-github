WildlifeSpeciesBoar = {}
local WildlifeSpeciesBoar_mt = Class(WildlifeSpeciesBoar, WildlifeSpeciesCompanion)
function WildlifeSpeciesBoar.new(customMt)
    -- upvalues: (copy) WildlifeSpeciesBoar_mt
    local self = WildlifeSpeciesCompanion.new(customMt or WildlifeSpeciesBoar_mt)
    self.companionAnimalType = CompanionAnimalType.BOAR
    return self
end
function WildlifeSpeciesBoar:drawDebug()
    WildlifeSpeciesBoar:superClass().drawDebug(self)
    if self.debugLastX ~= nil then
        DebugUtil.drawDebugCubeAtWorldPos(self.debugLastX, self.debugLastY, self.debugLastZ, 0, 0, 1, 0, 1, 0, 3, 3, 3, 1, 0, 0)
    end
end
function WildlifeSpeciesBoar:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, callbackFunc)
    if WildlifeSpeciesBoar:superClass().trySpawnAt(self, playerX, playerZ, playerRotY, cameraFovY, callbackFunc) then
        local spawnDistance = MathUtil.randomFloat(self.spawnRadiusMin, self.spawnRadiusMax)
        local x, z = WildlifeUtil.calculateRandomSpawnPosition(playerX, playerZ, playerRotY, cameraFovY, spawnDistance)
        local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
        self.debugLastX = x
        self.debugLastY = terrainY
        self.debugLastZ = z
        if FSDensityMapUtil.getIsFieldAtWorldPos(x, z) then
            local fruitTypeIndex, growthState = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
            local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
            if fruitTypeDesc == nil then
                self:finishSpawning(false)
                return true
            elseif WildlifeSpeciesBoar.defaultHarvestableCheck(fruitTypeDesc, growthState) then
                self:spawnInstances(x, terrainY, z)
                return true
            else
                self:finishSpawning(false)
                return true
            end
        else
            self:runForestCheck(x, terrainY, z, function(isForest)
                -- upvalues: (copy) self, (copy) x, (copy) terrainY, (copy) z
                if isForest then
                    self:spawnInstances(x, terrainY, z)
                else
                    self:finishSpawning(false)
                end
            end)
            return true
        end
    else
        return false
    end
end
function WildlifeSpeciesBoar.defaultHarvestableCheck(fruitTypeDesc, growthState)
    return (fruitTypeDesc:getIsGrowing(growthState) or fruitTypeDesc:getIsHarvestable(growthState)) and math.random() < 0.6
end