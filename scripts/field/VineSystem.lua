VineSystem = {}
VineSystem.MAX_NUM_OBJECTS_PER_FRAME = 5
local VineSystem_mt = Class(VineSystem)
function VineSystem.new(isServer, mission, customMt)
    -- upvalues: (copy) VineSystem_mt
    local self = setmetatable({}, customMt or VineSystem_mt)
    self.mission = mission
    self.isServer = isServer
    self.isDebugAreaActive = false
    self.debugAreas = {}
    self.densityMapCellIdToNode = {}
    self.dirtyNodes = {}
    self.nodes = {}
    self.poleNodes = {}
    if g_addCheatCommands then
        if mission:getIsServer() then
            addConsoleCommand("gsVineSystemSetGrowthState", "Sets vineyard growthstate", "consoleCommandSetGrowthState", self)
        end
        addConsoleCommand("gsVineSystemUpdateVisuals", "Updates the visuals", "consoleCommandUpdateVisuals", self)
        addConsoleCommand("gsVineSystemPrintCellMapping", "Print the current cellmapping", "consoleCommandPrintCellMapping", self)
        addConsoleCommand("gsVineSystemToggleDebug", "Toggles debug view", "consoleCommandToggleDebug", self)
    end
    return self
end
function VineSystem:initTerrain(_, _)
    g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.onFinishedGrowthPeriod, self)
end
function VineSystem:delete()
    g_messageCenter:unsubscribeAll(self)
    removeConsoleCommand("gsVineSystemSetGrowthState")
    removeConsoleCommand("gsVineSystemUpdateVisuals")
    removeConsoleCommand("gsVineSystemPrintCellMapping")
    removeConsoleCommand("gsVineSystemToggleDebug")
    for fruitTypeIndex, debugArea in pairs(self.debugAreas) do
        debugArea:delete()
        self.debugAreas[fruitTypeIndex] = nil
    end
end
function VineSystem:addElement(placeable, node, sizeX, sizeZ)
    if self.nodes[node] == nil then
        local fruitTypeIndex = placeable:getVineFruitType()
        if self.debugAreas[fruitTypeIndex] == nil then
            local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
            if fruitType.terrainDataPlaneId ~= nil then
                local colors = {
                    [0] = Color.new(0, 0.5, 0, 0.05),
                    [1] = Color.new(0, 0, 1, 0.075),
                    [2] = Color.new(0.995, 0.685, 0, 0.05),
                    [3] = Color.new(0.846, 0.216, 0, 0.05),
                    [4] = Color.new(0.695, 0.007, 0, 0.05),
                    [5] = Color.new(0, 1, 0, 0.05),
                    [6] = Color.new(0, 1, 0, 0.05),
                    [7] = Color.new(0, 1, 0, 0.05),
                    [8] = Color.new(0, 1, 0, 0.05),
                    [9] = Color.new(0, 1, 0, 0.05),
                    [10] = Color.new(0, 1, 0, 0.05),
                    [11] = Color.new(0, 1, 0, 0.05),
                    [12] = Color.new(0, 1, 0, 0.05),
                    [13] = Color.new(0, 1, 0, 0.05),
                    [14] = Color.new(0, 1, 0, 0.05),
                    [15] = Color.new(0, 1, 0, 0.05),
                    [16] = Color.new(0, 1, 0, 0.05)
                }
                self.debugAreas[fruitTypeIndex] = DebugDensityMap.newFromMap(fruitType.terrainDataPlaneId, fruitType.startStateChannel, fruitType.numStateChannels, 10, 0.05, colors)
            end
        end
        if not self.isServer and self.mission.missionDynamicInfo.isMultiplayer then
            local fruitType = g_currentMission.densityMapSyncer:activateFruitUpdateCallback(fruitTypeIndex)
            if fruitType ~= nil then
                local colors, _, z = getWorldTranslation(node)
                local dirX, _, dirZ = localDirectionToWorld(node, 0, 0, 1)
                local minCellX, maxCellX, minCellZ, maxCellZ = self:getDensityMapSyncerCellIndexRange(fruitTypeIndex, colors, z, dirX, dirZ, sizeX, sizeZ)
                for minCellX = minCellX, maxCellX do
                    for cellZ = minCellZ, maxCellZ do
                        local cellId = g_currentMission.densityMapSyncer:addCellUpdateListener(self, fruitType, minCellX, cellZ)
                        if cellId ~= nil then
                            if self.densityMapCellIdToNode[fruitType] == nil then
                                self.densityMapCellIdToNode[fruitType] = {}
                            end
                            if self.densityMapCellIdToNode[fruitType][cellId] == nil then
                                self.densityMapCellIdToNode[fruitType][cellId] = {}
                            end
                            if self.densityMapCellIdToNode[fruitType][cellId][placeable] == nil then
                                self.densityMapCellIdToNode[fruitType][cellId][placeable] = {}
                            end
                            if self.densityMapCellIdToNode[fruitType][cellId][placeable][node] == nil then
                                self.densityMapCellIdToNode[fruitType][cellId][placeable][node] = true
                            end
                        end
                    end
                end
            end
        end
        local fruitType = getParent(node)
        local colors = getParent(fruitType)
        self.poleNodes[_] = node
        self.nodes[node] = placeable
        self.dirtyNodes[node] = true
    end
end
function VineSystem:removeElement(placeable, node, sizeX, sizeZ)
    if self.nodes[node] == nil or not entityExists(node) then
        return
    end
    if not self.isServer and self.mission.missionDynamicInfo.isMultiplayer then
        local fruitTypeIndex = placeable:getVineFruitType()
        local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
        if desc.foliageTransformGroupId == nil then
            return
        end
        local densityMapId = desc.foliageTransformGroupId
        if densityMapId ~= nil then
            local x, _, z = getWorldTranslation(node)
            local dirX, _, dirZ = localDirectionToWorld(node, 0, 0, 1)
            local minCellX, maxCellX, minCellZ, maxCellZ = self:getDensityMapSyncerCellIndexRange(fruitTypeIndex, x, z, dirX, dirZ, sizeX, sizeZ)
            for minCellX = minCellX, maxCellX do
                for cellZ = minCellZ, maxCellZ do
                    local cellId = g_currentMission.densityMapSyncer:removeCellUpdateListener(self, densityMapId, minCellX, cellZ)
                    if cellId ~= nil and self.densityMapCellIdToNode[densityMapId][cellId] ~= nil then
                        if self.densityMapCellIdToNode[densityMapId][cellId][placeable] ~= nil then
                            self.densityMapCellIdToNode[densityMapId][cellId][placeable][node] = nil
                        end
                        if next(self.densityMapCellIdToNode[densityMapId][cellId][placeable]) == nil then
                            self.densityMapCellIdToNode[densityMapId][cellId][placeable] = nil
                            if next(self.densityMapCellIdToNode[densityMapId][cellId]) == nil then
                                self.densityMapCellIdToNode[densityMapId][cellId] = nil
                            end
                        end
                    end
                end
            end
        end
    end
    for x, _ in pairs(self.poleNodes) do
        if _ == node then
            self.poleNodes[x] = nil
            break
        end
    end
    self.nodes[node] = nil
    self.dirtyNodes[node] = nil
end
function VineSystem:onDensityMapSyncerUpdate(densityMapId, _, _, cellId)
    local densityMapCellData = self.densityMapCellIdToNode[densityMapId]
    if densityMapCellData == nil then
        Logging.devWarning("VineSystem:onDensityMapSyncerUpdate: No placeables registered for densityMap \'%d\'", densityMapId)
        return
    else
        local placeables = densityMapCellData[cellId]
        if placeables == nil then
            Logging.devWarning("VineSystem:onDensityMapSyncerUpdate: No placeables registered for cellId \'%d\'", cellId)
        else
            for placeable, nodes in pairs(placeables) do
                for node, _ in pairs(nodes) do
                    self.dirtyNodes[node] = true
                end
            end
        end
    end
end
function VineSystem:onFinishedGrowthPeriod(_)
    for node, placeable in pairs(self.nodes) do
        self.dirtyNodes[node] = true
    end
end
function VineSystem:update(_)
    for i = 1, VineSystem.MAX_NUM_OBJECTS_PER_FRAME do
        local node = next(self.dirtyNodes)
        if node ~= nil then
            local placeable = self.nodes[node]
            if placeable ~= nil then
                placeable:updateVineNode(node, true)
            end
            self.dirtyNodes[node] = nil
        end
    end
end
function VineSystem.getDensityMapSyncerCellIndexRange(_, fruitTypeIndex, x, z, dirX, dirZ, sizeX, sizeZ)
    local normX, _, normZ = MathUtil.crossProduct(dirX, 0, dirZ, 0, 1, 0)
    local sizeHalfX = sizeX * 0.5
    local p1CellX, p1CellZ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, x + normX * -sizeHalfX, z + normZ * -sizeHalfX)
    local p2CellX, p2CellZ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, x + normX * sizeHalfX, z + normZ * sizeHalfX)
    local p3CellX, p3CellZ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, x + dirX * sizeZ + normX * -sizeHalfX, z + dirZ * sizeZ + normZ * -sizeHalfX)
    local p4CellX, p4CellZ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, x + dirX * sizeZ + normX * sizeHalfX, z + dirZ * sizeZ + normZ * sizeHalfX)
    return math.min(p1CellX, p2CellX, p3CellX, p4CellX), math.max(p1CellX, p2CellX, p3CellX, p4CellX), math.min(p1CellZ, p2CellZ, p3CellZ, p4CellZ), math.max(p1CellZ, p2CellZ, p3CellZ, p4CellZ)
end
function VineSystem:getPlaceable(node)
    if node == nil then
        return nil
    else
        local placeable = self.nodes[node]
        if placeable == nil and self.poleNodes[node] ~= nil then
            placeable = self.nodes[self.poleNodes[node]]
        end
        if placeable == nil then
            return nil
        else
            return placeable
        end
    end
end
function VineSystem:consoleCommandSetGrowthState(fruitTypeName, growthState)
    local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
    if fruitType == nil then
        return "FruitType " .. tostring(fruitTypeName) .. " not defined"
    end
    local fruitTypeIndex = tonumber(growthState)
    if fruitTypeIndex == nil then
        return "Invalid growthstate " .. tostring(fruitTypeIndex)
    end
    local fruitTypeIndex = fruitType.index
    local count = 0
    for node, placeable in pairs(self.nodes) do
        if placeable:getVineFruitType() == fruitTypeIndex then
            local startX, startZ, widthX, widthZ, heightX, heightZ = placeable:getVineAreaByNode(node)
            FSDensityMapUtil:setVineAreaValue(fruitTypeIndex, startX, startZ, widthX, widthZ, heightX, heightZ, fruitTypeIndex)
            self.dirtyNodes[node] = true
        end
    end
    return string.format("Updated %d vine areas", count)
end
function VineSystem:consoleCommandUpdateVisuals()
    for node, _ in pairs(self.nodes) do
        self.dirtyNodes[node] = true
    end
end
function VineSystem:consoleCommandPrintCellMapping()
    for densityMapId, cellIds in pairs(self.densityMapCellIdToNode) do
        log("DensityMapId", densityMapId)
        for cellId, placeables in pairs(cellIds) do
            log("    CellId", cellId)
            for placeable, nodes in pairs(placeables) do
                log("        Placeable", placeable, placeable.spec_vine.fruitType.name)
                for node, _ in pairs(nodes) do
                    log("            ", node, getName(node))
                end
            end
        end
    end
end
function VineSystem:consoleCommandToggleDebug()
    self.isDebugAreaActive = not self.isDebugAreaActive
    for _, debugArea in pairs(self.debugAreas) do
        if self.isDebugAreaActive then
            g_currentMission:addDrawable(debugArea)
        else
            g_currentMission:removeDrawable(debugArea)
        end
    end
end