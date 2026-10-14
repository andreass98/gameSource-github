WildlifeInstanceCompanion = {}
local WildlifeInstanceCompanion_mt = Class(WildlifeInstanceCompanion, WildlifeInstance)
function WildlifeInstanceCompanion.new(species, customMt)
    -- upvalues: (copy) WildlifeInstanceCompanion_mt
    local self = WildlifeInstance.new(species, customMt or WildlifeInstanceCompanion_mt)
    self.companionId = nil
    self.numAnimals = 0
    return self
end
function WildlifeInstanceCompanion:delete()
    if self.companionId ~= nil then
        delete(self.companionId)
        self.companionId = nil
    end
    WildlifeInstanceCompanion:superClass().delete(self)
end
function WildlifeInstanceCompanion:getNumAnimals()
    return self.numAnimals
end
function WildlifeInstanceCompanion:setNumAnimals(numAnimals)
    self.numAnimals = numAnimals
end
function WildlifeInstanceCompanion:calculateDistanceFrom(positionX, positionZ)
    if self.companionId == nil then
        return math.huge
    end
    local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, positionX, 0, positionZ)
    return getCompanionClosestDistance(self.companionId, positionX, terrainY, positionZ)
end
function WildlifeInstanceCompanion:spawnAt(x, y, z)
    WildlifeInstanceCompanion:superClass().spawnAt(self, x, y, z)
    if self.companionId ~= nil then
        delete(self.companionId)
        self.companionId = nil
    end
    local companionId = createAnimalCompanionManager(self.species.companionAnimalType or CompanionAnimalType.DEER, self.species.filename, "species.companion", x, y, z, g_terrainNode, false, true, self.numAnimals, AudioGroup.ENVIRONMENT)
    if companionId ~= 0 then
        self.companionId = companionId
        setCompanionCollisionMask(self.companionId, CollisionFlag.TERRAIN, CollisionFlag.STATIC_OBJECT + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.BUILDING, CollisionFlag.WATER)
        self.foliageBendingNodes = {}
    end
end
function WildlifeInstanceCompanion:despawn()
    for _, foliagBendingNode in ipairs(self.foliageBendingNodes) do
        g_currentMission.foliageBendingSystem:destroyObject(foliagBendingNode)
    end
    table.clear(self.foliageBendingNodes)
    if self.companionId ~= nil then
        delete(self.companionId)
        self.companionId = nil
    end
    self.numAnimals = 0
    self.isInitialized = nil
    WildlifeInstanceCompanion:superClass().despawn(self)
end
function WildlifeInstanceCompanion:update(dt)
    WildlifeInstanceCompanion:superClass().update(dt)
    if self.companionId ~= nil then
        local playerNode = g_localPlayer:getCurrentRootNode()
        if playerNode ~= nil then
            setCompanionAvoidPlayer(self.companionId, playerNode, self.species.fleeDistance)
        end
        if not self.isInitialized and isCompanionReady(self.companionId) then
            self.isInitialized = true
            local foliageBendingArea = self.species.foliageBendingArea
            if foliageBendingArea ~= nil then
                local nodes = getCompanionNodes(self.companionId)
                for _, node in ipairs(nodes) do
                    local foliageBendingId = g_currentMission.foliageBendingSystem:createRectangle(foliageBendingArea.minX, foliageBendingArea.maxX, foliageBendingArea.minZ, foliageBendingArea.maxZ, foliageBendingArea.yOffset, node)
                    table.insert(self.foliageBendingNodes, foliageBendingId)
                end
            end
        end
    end
end
function WildlifeInstanceCompanion:drawDebug()
    if self.isInitialized then
        local nodes = getCompanionNodes(self.companionId)
        for index, node in ipairs(nodes) do
            DebugText.renderAtNode(node, string.format("%s companion:%d\nnode:%d #%d", self.species.name, self.companionId, node, index), DebugUtil.getDebugColor(self.companionId), 0.015)
        end
    end
end