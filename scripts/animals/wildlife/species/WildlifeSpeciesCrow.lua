WildlifeSpeciesCrow = {}
local WildlifeSpeciesCrow_mt = Class(WildlifeSpeciesCrow, WildlifeSpeciesSimple)
g_xmlManager:addInitSchemaFunction(function()
    local xmlSchema = WildlifeSpecies.xmlSchema
end)
function WildlifeSpeciesCrow.new(customMt)
    -- upvalues: (copy) WildlifeSpeciesCrow_mt
    local self = WildlifeSpeciesSimple.new(customMt or WildlifeSpeciesCrow_mt)
    self.spawnCallbackFunc = nil
    self.nonFieldSpawnChange = 0.1
    self.maxNumExtraInstances = 2
    self.flyByChance = 0.8
    self.maxNumExtraInstancesFlyBy = 5
    self.minSpawnDistanceRadiusFlyBy = 70
    self.maxSpawnDistanceRadiusFlyBy = 100
    self.spawnTimerThreshold = 7000
    self.spawnTimer = self.spawnTimerThreshold
    self.groupMinRadius = 0.5
    self.groupMaxRadius = 10
    return self
end
function WildlifeSpeciesCrow:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, callbackFunc)
    if WildlifeSpeciesCrow:superClass().trySpawnAt(self, playerX, playerZ, playerRotY, cameraFovY, callbackFunc) then
        return self:spawn(playerX, playerZ, playerRotY, cameraFovY)
    else
        return false
    end
end
function WildlifeSpeciesCrow:spawn(playerX, playerZ, playerRotY, cameraFovY)
    local spawnDistance = MathUtil.randomFloat(self.spawnRadiusMin, self.spawnRadiusMax)
    local x, z = WildlifeUtil.calculateRandomSpawnPosition(playerX, playerZ, playerRotY, cameraFovY, spawnDistance)
    local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
    if FSDensityMapUtil.getIsFieldAtWorldPos(x, z) then
        local fruitIndex, growthState = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
        if fruitIndex ~= nil then
            if g_currentMission.fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.WATER_LEVEL, x, 0, z) > 0 then
                self:finishSpawning(false)
                return false
            else
                local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
                if fruitTypeDesc == nil then
                    self:finishSpawning(false)
                    return false
                elseif fruitTypeDesc:getIsCut(growthState) and math.random() < 0.6 then
                    self:spawnInstances(x, terrainY, z, math.random(1, self.maxNumExtraInstances), nil, nil, nil)
                    return true
                elseif fruitTypeDesc:getIsWeedable(growthState) and math.random() < 0.6 then
                    self:spawnInstances(x, terrainY, z, math.random(1, self.maxNumExtraInstances), nil, nil, nil)
                    return true
                else
                    self:finishSpawning(false)
                    return false
                end
            end
        end
    end
    if math.random() > self.nonFieldSpawnChange then
        self:finishSpawning(false)
        return false
    else
        raycastClosestAsync(x, terrainY + 100, z, 0, -1, 0, 200, "onSpawnYCallback", self, CollisionFlag.TERRAIN + CollisionFlag.ROAD + CollisionFlag.WATER)
        return true
    end
end
function WildlifeSpeciesCrow:onSpawnYCallback(nodeId, x, y, z, _, _, _, _, _, _, _)
    if nodeId == nil or nodeId == 0 then
        self:finishSpawning(false)
        return
    else
        local transformCollisionGroup = getCollisionFilterGroup(nodeId)
        local isRoad = CollisionFlag.getHasGroupFlagSet(nodeId, CollisionFlag.ROAD)
        if isRoad then
            isRoad = nodeId ~= g_terrainNode
        end
        if isRoad then
            self:finishSpawning(false)
            return
        elseif CollisionFlag.getHasGroupFlagSet(nodeId, CollisionFlag.WATER) then
            self:finishSpawning(false)
            return
        else
            local isObject = bit32.band(transformCollisionGroup, CollisionFlag.TERRAIN) == 0
            if self.canSpawnOnObjects or not isObject then
                self:spawnInstances(x, y, z, math.random(1, self.maxNumExtraInstances), nodeId, nil, nil)
            else
                self:finishSpawning(false)
            end
        end
    end
end
function WildlifeSpeciesCrow:spawnInstances(x, y, z, numInstances, _, dirX, dirZ)
    local i = 1
    for i = i, numInstances do
        local instance = self:createInstance()
        local angle = i * (6.283185307179586 / numInstances)
        local radius = MathUtil.lerp(self.groupMinRadius, self.groupMaxRadius, math.random())
        x = x + math.cos(angle) * radius
        z = z + math.sin(angle) * radius
        instance:spawnAt(x, y, z)
        if dirX ~= nil and dirZ ~= nil then
            instance.stateMachine.states.flee:fleeToDespawn(dirX, dirZ, false)
            instance.mover.overiddenSpeed = nil
            instance.mover:randomiseCurrentSpeed()
        end
    end
    self:finishSpawning(true)
end
function WildlifeSpeciesCrow:debugSpawn(x, y, z, numInstances)
    WildlifeSpeciesCrow:superClass().debugSpawn(self, x, y, z, numInstances)
    self:spawnInstances(x, y, z, numInstances, nil, nil, nil)
end