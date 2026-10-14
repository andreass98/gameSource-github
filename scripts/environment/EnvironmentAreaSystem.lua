EnvironmentAreaSystem = {}
local EnvironmentAreaSystem_mt = Class(EnvironmentAreaSystem)
function EnvironmentAreaSystem.getName(index)
    for name, id in pairs(EnvironmentAreaSystem) do
        if index == id then
            return name
        end
    end
    return ""
end
function EnvironmentAreaSystem.new(customMt)
    -- upvalues: (copy) EnvironmentAreaSystem_mt
    local self = setmetatable({}, customMt or EnvironmentAreaSystem_mt)
    self.isDebugViewActive = false
    self.referenceNode = g_cameraManager:getActiveCamera()
    self.raycastCollisionMask = CollisionFlag.BUILDING
    self.raycastsXZMaxDistance = 30
    self.raycastsYMaxDistance = 30
    self.raycastsXZ = {
        {
            ["dir"] = { MathUtil.vector3Normalize(0, 0, 1) }
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(1, 0, 0) }
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(0, 0, -1) }
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(-1, 0, 0) }
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(1, 0, 1) }
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(1, 0, -1) }
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(-1, 0, -1) }
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(-1, 0, 1) }
        }
    }
    self.raycastsY = {
        {
            ["dir"] = { MathUtil.vector3Normalize(0, 1, 0) },
            ["isTopRaycast"] = true
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(0, 1.5, 1) },
            ["isTopRaycast"] = false
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(1, 1.5, 0) },
            ["isTopRaycast"] = false
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(0, 1.5, -1) },
            ["isTopRaycast"] = false
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(-1, 1.5, 0) },
            ["isTopRaycast"] = false
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(0, 1, 0) },
            ["isTopRaycast"] = true
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(1, 1.5, 1) },
            ["isTopRaycast"] = false
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(1, 1.5, -1) },
            ["isTopRaycast"] = false
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(-1, 1.5, -1) },
            ["isTopRaycast"] = false
        },
        {
            ["dir"] = { MathUtil.vector3Normalize(-1, 1.5, 1) },
            ["isTopRaycast"] = false
        }
    }
    self.lastPosition = {
        ["x"] = 0,
        ["y"] = 0,
        ["z"] = 0
    }
    self.tileSize = 4
    self.dataGrid = DynamicDataGrid.new(60, self.tileSize)
    self.treeCheckRadius = 25
    self.maxNumForestThreshold = 15
    self.minNumForestThreshold = 8
    self.minTopCollisionDistanceThreshold = 10
    self.maxTopCollisionDistanceThreshold = 20
    self.minWallCollisionDistanceThreshold = 5
    self.maxWallCollisionDistanceThreshold = 15
    self.normalizedWeights = {}
    self.currentWeight = EnvironmentAreaWeight.new()
    addConsoleCommand("gsEnvironmentAreaSystemToggleDebugView", "Toggles the environment checker debug view", "consoleCommandToggleDebugView", self)
    return self
end
function EnvironmentAreaSystem:delete()
    g_currentMission:removeDrawable(self)
    removeConsoleCommand("gsEnvironmentAreaSystemToggleDebugView")
    if self.infoLayer ~= nil then
        self.infoLayer:delete()
        self.infoLayer = nil
    end
end
function EnvironmentAreaSystem:initTerrain(terrainNode)
    self.infoLayer = InfoLayer.newFromMap(terrainNode, "environment")
    self.areaTypeStartChannel = 0
    self.areaTypeNumChannels = 3
    self.areaTypeMapping = {}
    self.areaTypeMapping[0] = AreaType.OPEN_FIELD
    self.areaTypeMapping[1] = AreaType.CITY
    self.areaTypeMapping[2] = AreaType.VILLAGE
    self.areaTypeMapping[3] = AreaType.HARBOR
    self.areaTypeMapping[4] = AreaType.INDUSTRIAL
    self.areaTypeMapping[5] = AreaType.OPEN_WATER
    self.waterStartChannel = 3
    self.waterNumChannels = 1
    self.waterTypeMapping = {}
    self.waterTypeMapping[0] = WaterType.NO_WATER
    self.waterTypeMapping[1] = WaterType.NEAR_WATER
end
function EnvironmentAreaSystem:loadMapData(mapXMLFile, _, _)
    local outOfBoundsAreaTypeStr = getXMLString(mapXMLFile, "map.environmentAreaSystem#outOfBoundsAreaType")
    if outOfBoundsAreaTypeStr ~= nil then
        self.outOfBoundsAreaType = AreaType.getByName(outOfBoundsAreaTypeStr)
        if self.outOfBoundsAreaType == nil then
            Logging.xmlWarning(mapXMLFile, "Unknown AreaType %q at %q", outOfBoundsAreaTypeStr, "map.environmentAreaSystem#outOfBoundsAreaType")
        end
    end
end
function EnvironmentAreaSystem:getAreaTypeFromInfoLayerAtWorldPos(x, z)
    local infoLayer = self.infoLayer
    if infoLayer == nil then
        return nil
    end
    if self.outOfBoundsAreaType and (math.abs(x) > g_terrainSizeHalf or math.abs(z) > g_terrainSizeHalf) then
        return self.outOfBoundsAreaType
    end
    local value = infoLayer:getValueAtWorldPos(x, z, self.areaTypeStartChannel, self.areaTypeNumChannels)
    return self.areaTypeMapping[value]
end
function EnvironmentAreaSystem:getWaterTypeFromInfoLayerAtWorldPos(x, z)
    local infoLayer = self.infoLayer
    if infoLayer == nil then
        return nil
    end
    local value = infoLayer:getValueAtWorldPos(x, z, self.waterStartChannel, self.waterNumChannels)
    return self.waterTypeMapping[value]
end
function EnvironmentAreaSystem:getAreaWeights()
    return self.currentWeight
end
function EnvironmentAreaSystem:update(_)
    if not entityExists(self.referenceNode) then
        self.referenceNode = g_cameraManager:getActiveCamera()
    end
    if self.currentCell ~= nil then
        self:updateCell(self.currentCell)
        self:updateWeights()
    end
    local x, y, z = getWorldTranslation(self.referenceNode)
    self.dataGrid:setWorldPosition(x, z)
    local cell = self.dataGrid:getCellFromLocalIndices(0, 0)
    local wx, wz = self.dataGrid:getWorldPositionByLocalIndices(0, 0)
    self.currentCell = cell
    if cell.raycastIndexXZ == nil then
        self:setupCell(cell, wx, wz)
    else
        cell.raycastIndexXZ = cell.raycastIndexXZ + 2
    end
    if cell.raycastIndexXZ >= #self.raycastsXZ then
        cell.raycastIndexXZ = 0
        cell.isDone = true
        self.lastDoneCell = cell
    end
    local raycastXZ1 = self.raycastsXZ[cell.raycastIndexXZ + 1]
    raycastClosestAsync(x, y, z, raycastXZ1.dir[1], raycastXZ1.dir[2], raycastXZ1.dir[3], self.raycastsXZMaxDistance, "raycastXZCallback1", self, self.raycastCollisionMask)
    local raycastXZ2 = self.raycastsXZ[cell.raycastIndexXZ + 2]
    raycastClosestAsync(x, y, z, raycastXZ2.dir[1], raycastXZ2.dir[2], raycastXZ2.dir[3], self.raycastsXZMaxDistance, "raycastXZCallback2", self, self.raycastCollisionMask)
    if not cell.hasTopHit then
        raycastClosestAsync(x, y, z, 0, 1, 0, self.raycastsYMaxDistance, "raycastYCallback", self, self.raycastCollisionMask)
    end
    if cell.treeCount == nil then
        cell.treeCount = 0
        overlapSphereAsync(wx, y, wz, self.treeCheckRadius, "forestCheckCallback", self, CollisionFlag.TREE, false, false, true, false)
    end
    self.lastPosition.x = x
    self.lastPosition.y = y
    self.lastPosition.z = z
end
function EnvironmentAreaSystem:setupCell(cell, wx, wz)
    local areaType = self:getAreaTypeFromInfoLayerAtWorldPos(wx, wz)
    local waterType = self:getWaterTypeFromInfoLayerAtWorldPos(wx, wz)
    cell.isValid = true
    cell.isDone = false
    cell.raycastIndexXZ = 0
    cell.hitDataXZ = {}
    cell.areaTypeWeights = {}
    cell.treeCount = nil
    if cell.weights == nil then
        cell.weights = EnvironmentAreaWeight.new()
    else
        cell.weights:reset()
    end
    if waterType == WaterType.NEAR_WATER then
        cell.weights.isNearWaterWeight = 1
    end
    if areaType ~= nil then
        cell.weights.areaTypeWeights[areaType] = 1
    end
end
function EnvironmentAreaSystem:updateCell(cell)
    if cell.treeCount > self.maxNumForestThreshold then
        cell.weights.isInForestWeight = 1
    elseif cell.treeCount > self.minNumForestThreshold then
        weights.isInForestWeight = MathUtil.inverseLerp(self.minNumForestThreshold, self.maxNumForestThreshold, cell.treeCount)
    end
    if cell.hasTopHit then
        weights.isUnderRoofWeight = 1
    end
    local nearestWallDistance = math.huge
    for _, data in pairs(cell.hitDataXZ) do
        nearestWallDistance = math.min(nearestWallDistance, data.distance)
    end
    if nearestWallDistance < self.maxWallCollisionDistanceThreshold then
        weights.isNearWallWeight = 1 - MathUtil.inverseLerp(self.minWallCollisionDistanceThreshold, self.maxWallCollisionDistanceThreshold, nearestWallDistance)
    end
end
function EnvironmentAreaSystem:updateWeights()
    local currentWeight = self.currentWeight
    currentWeight:reset()
    local fallbackCell = self.dataGrid:getCellFromLocalIndices(0, 0)
    if not fallbackCell.isDone and (self.lastDoneCell ~= nil and self.lastDoneCell.weights ~= nil) then
        fallbackCell = self.lastDoneCell
    end
    local weightSum = 0
    local i = 1
    for i = i, 3 do
        local j = 1
        local cell = 3
        for j = j, cell do
            local cell = self.dataGrid:getCellFromLocalIndices(i - 2, j - 2)
            local wx, wz = self.dataGrid:getWorldPositionByLocalIndices(i - 2, j - 2)
            local weightFactor = MathUtil.vector2Length(wx - self.lastPosition.x, wz - self.lastPosition.z)
            local weightFactor = math.clamp(1 - math.min(weightFactor, self.tileSize) / self.tileSize, 0, 1)
            self.normalizedWeights[cell] = weightFactor
        end
    end
    for cell, normalizedWeight in pairs(self.normalizedWeights) do
        local normalizedWeight = normalizedWeight / weightSum
        local j = cell.weights
        if j == nil or not cell.isDone then
            j = fallbackCell.weights
        end
        currentWeight.isNearWallWeight = currentWeight.isNearWallWeight + j.isNearWallWeight * normalizedWeight
        currentWeight.isNearWaterWeight = currentWeight.isNearWaterWeight + j.isNearWaterWeight * normalizedWeight
        currentWeight.isUnderRoofWeight = currentWeight.isUnderRoofWeight + j.isUnderRoofWeight * normalizedWeight
        currentWeight.isInForestWeight = currentWeight.isInForestWeight + j.isInForestWeight * normalizedWeight
        for distance, weightFactor in pairs(j.areaTypeWeights) do
            currentWeight.areaTypeWeights[distance] = currentWeight.areaTypeWeights[distance] + weightFactor * normalizedWeight
        end
        self.normalizedWeights[cell] = nil
    end
end
function EnvironmentAreaSystem:raycastXZCallback1(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
    self:handleRaycast(1, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
end
function EnvironmentAreaSystem:raycastXZCallback2(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
    self:handleRaycast(2, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
end
function EnvironmentAreaSystem:handleRaycast(indexOffset, hitObjectId, x, y, z, distance, _, _, _, _, _, _)
    local cell = self.currentCell
    local raycastIndexXZ = cell.raycastIndexXZ + indexOffset
    if hitObjectId ~= 0 and (cell.hitDataXZ[raycastIndexXZ] == nil or distance < cell.hitDataXZ[raycastIndexXZ].distance) then
        cell.hitDataXZ[raycastIndexXZ] = {
            ["name"] = getName(hitObjectId),
            ["x"] = x,
            ["y"] = y,
            ["z"] = z,
            ["distance"] = distance
        }
    end
end
function EnvironmentAreaSystem:raycastYCallback(hitObjectId, _, _, _, _, _, _, _, _, _, _)
    if hitObjectId ~= 0 then
        self.currentCell.hasTopHit = true
    end
end
function EnvironmentAreaSystem:setReferenceNode(node)
    self.referenceNode = node
end
function EnvironmentAreaSystem:forestCheckCallback(transformId)
    if transformId ~= 0 and (getHasClassId(transformId, ClassIds.MESH_SPLIT_SHAPE) and (getSplitType(transformId) ~= 0 and not getIsSplitShapeSplit(transformId))) then
        self.currentCell.treeCount = self.currentCell.treeCount + 1
    end
    return true
end
function EnvironmentAreaSystem:draw()
    local terrainNode = g_terrainNode
    self.dataGrid:drawDebug(function(cell)
        if cell.isValid then
            if cell.isDone then
                return 0, 1, 0, 0.1
            else
                return 0, 0, 1, 0.1
            end
        else
            return 1, 0, 0, 0.1
        end
    end, function(cell, cx, cz)
        -- upvalues: (copy) terrainNode, (copy) self
        local text = nil
        if cell.treeCount ~= nil then
            text = string.format("%s\nTrees: %d", text or "", cell.treeCount)
        end
        if text ~= nil then
            local cy = getTerrainHeightAtWorldPos(terrainNode, cx, 0, cz) + 0.1
            DebugGizmo.renderAtPosition(cx, cy, cz, 0, 0, 1, 0, 1, 0, text, false)
        end
        if cell == self.currentCell and cell.hitDataXZ ~= nil then
            for k, data in pairs(cell.hitDataXZ) do
                DebugPoint.renderAtPosition(data.x, data.y, data.z, nil, false, string.format("Raycast-XZ %d\n%.3f", k, data.distance), nil, nil, 150)
            end
        end
    end)
    setTextColor(1, 1, 1, 1)
    self.currentWeight:drawDebug(0.3, 0.6, getCorrectTextSize(0.012))
end
function EnvironmentAreaSystem:getWaterYAtWorldPosition(x, y, z)
    self.waterY = nil
    raycastClosest(x, (y or 100) + 100, z, 0, -1, 0, 200, "onWaterRaycastCallback", self, CollisionFlag.WATER)
    return self.waterY
end
function EnvironmentAreaSystem:onWaterRaycastCallback(hitObjectId, _, y, _, _, _, _, _, _, _, _)
    if hitObjectId ~= 0 then
        self.waterY = y
    end
end
function EnvironmentAreaSystem.getWaterYAtWorldPositionAsync(_, x, y, z, callbackFunction, callbackTarget, _, arguments)
    raycastClosestAsync(x, y + 100, z, 0, -1, 0, 200, "onWaterCallback", {
        ["onWaterCallback"] = function(_, nodeId, _, y, _, _, _, _, _, _, _, _)
            -- upvalues: (copy) callbackTarget, (copy) callbackFunction, (copy) arguments
            if nodeId == 0 then
                y = nil
            end
            if callbackTarget == nil then
                callbackFunction(y, arguments)
            else
                callbackFunction(callbackTarget, y, arguments)
            end
        end
    }, CollisionFlag.WATER)
end
function EnvironmentAreaSystem.getWaterDepthAtWorldPositionAsync(_, x, y, z, callbackFunction, callbackTarget, arguments)
    raycastClosestAsync(x, y + 100, z, 0, -1, 0, 200, "onWaterCallback", {
        ["onWaterCallback"] = function(_, nodeId, x, y, z, _, _, _, _, _, _, _)
            -- upvalues: (copy) callbackTarget, (copy) callbackFunction, (copy) arguments
            local depth = 0
            if nodeId == 0 then
                y = nil
            else
                local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
                if terrainHeight < y then
                    depth = y - terrainHeight
                end
            end
            if callbackTarget == nil then
                callbackFunction(depth, y, arguments)
            else
                callbackFunction(callbackTarget, depth, y, arguments)
            end
        end
    }, CollisionFlag.WATER)
end
function EnvironmentAreaSystem:consoleCommandToggleDebugView()
    self.isDebugViewActive = not self.isDebugViewActive
    if self.isDebugViewActive then
        g_currentMission:addDrawable(self)
    else
        mission:removeDrawable(self)
    end
    return string.format("EnvironmentAreaSystem.isDebugViewActive=%s", self.isDebugViewActive)
end