TerrainDeformationSyncer = {}
TerrainDeformationSyncer.DEBUG_ENABLED = false
TerrainDeformationSyncer.DEBUG_COLOR = Color.new(0, 1, 0, 0.15)
local TerrainDeformationSyncer_mt = Class(TerrainDeformationSyncer)
function TerrainDeformationSyncer.new(terrainNode, terrainSize, customMt)
    -- upvalues: (copy) TerrainDeformationSyncer_mt
    local self = setmetatable({}, customMt or TerrainDeformationSyncer_mt)
    self.terrainNode = terrainNode
    self.updateListeners = {}
    self.cellSize = 4
    local numCellsPerSide = terrainSize / self.cellSize
    setTerrainHeightSyncerCellChangedCallback(terrainNode, "onCellUpdate", numCellsPerSide, self)
    self.cellIdOffset = numCellsPerSide * numCellsPerSide
    addConsoleCommand("gsTerrainDeformationDebug", "Toggles debug mode", "consoleCommandToggleDebug", self)
    return self
end
function TerrainDeformationSyncer:delete()
    removeConsoleCommand("gsTerrainDeformationDebug")
    for cellId in pairs(self.updateListeners) do
        local cellX, cellZ = self:getCellIndicesById(cellId)
        setEnableTerrainHeightSyncerCellChangedCallback(self.terrainNode, cellX, cellZ, false)
    end
    table.clear(self.updateListeners)
end
function TerrainDeformationSyncer:writeUpdateStream(connection, maxPacketSize, x, y, z, _, networkDebug)
    local terrainStreamOffsetStart = streamGetWriteOffset(connection.streamId)
    if networkDebug then
        streamWriteInt32(connection.streamId, 0)
    end
    writeTerrainUpdateStream(self.terrainNode, connection.streamId, connection.streamId, maxPacketSize, x, y, z)
    local terrainStreamOffsetEnd = streamGetWriteOffset(connection.streamId)
    local terrainPacketSizeBits = terrainStreamOffsetEnd - terrainStreamOffsetStart
    g_server:addPacketSize(connection, NetworkNode.PACKET_TERRAIN_DEFORM, terrainPacketSizeBits / 8)
    if networkDebug then
        streamSetWriteOffset(connection.streamId, terrainStreamOffsetStart)
        streamWriteInt32(connection.streamId, terrainStreamOffsetEnd - (terrainStreamOffsetStart + 32))
        streamSetWriteOffset(connection.streamId, terrainStreamOffsetEnd)
    end
    return terrainPacketSizeBits
end
function TerrainDeformationSyncer:readUpdateStream(connection, networkDebug)
    local startOffset = 0
    local numBits = 0
    if networkDebug then
        startOffset = streamGetReadOffset(connection.streamId)
        numBits = streamReadInt32(connection.streamId)
    end
    readTerrainUpdateStream(self.terrainNode, connection.streamId)
    if networkDebug then
        g_client:checkObjectUpdateDebugReadSize(connection.streamId, numBits, startOffset, "terrainmods")
    end
end
function TerrainDeformationSyncer:draw()
    if TerrainDeformationSyncer.DEBUG_ENABLED then
        for cellId, listeners in pairs(self.updateListeners) do
            local cellX, cellZ = self:getCellIndicesById(cellId)
            local startX = cellX * self.cellSize - g_currentMission.terrainSize * 0.5
            local startZ = cellZ * self.cellSize - g_currentMission.terrainSize * 0.5
            local text = tostring(cellId)
            DebugPlane.renderWithPositions(startX, 0, startZ, startX + self.cellSize, 0, startZ, startX, 0, startZ + self.cellSize, TerrainDeformationSyncer.DEBUG_COLOR, true, true, true, false, text)
        end
    end
end
function TerrainDeformationSyncer:getCellIndicesAtWorldPosition(x, z)
    local cellX, cellZ, inRange = getTerrainHeightSyncerCellIndicesAtWorldPosition(self.terrainNode, x, z)
    if inRange then
        return cellX, cellZ
    else
        return nil, nil
    end
end
function TerrainDeformationSyncer:getCellId(cellX, cellZ)
    return cellX * self.cellIdOffset + cellZ
end
function TerrainDeformationSyncer:getCellIndicesById(cellId)
    return math.floor(cellId / self.cellIdOffset), cellId % self.cellIdOffset
end
function TerrainDeformationSyncer:addCellUpdateListener(listener, cellX, cellZ)
    local cellId = self:getCellId(cellX, cellZ)
    local listeners = self.updateListeners[cellId]
    if listeners == nil then
        self.updateListeners[cellId] = {}
        setEnableTerrainHeightSyncerCellChangedCallback(self.terrainNode, cellX, cellZ, true)
    end
    if listeners[listener] == nil then
        listeners[listener] = 0
    end
    listeners[listener] = listeners[listener] + 1
    return cellId
end
function TerrainDeformationSyncer:removeCellUpdateListener(listener, cellX, cellZ)
    local cellId = self:getCellId(cellX, cellZ)
    local listeners = self.updateListeners[cellId]
    if listeners == nil then
        return false
    end
    if listeners[listener] == nil then
        return false
    end
    listeners[listener] = listeners[listener] - 1
    if listeners[listener] == 0 then
        listeners[listener] = nil
    end
    if next(listeners) == nil then
        self.updateListeners[cellId] = nil
        setEnableTerrainHeightSyncerCellChangedCallback(self.terrainNode, cellX, cellZ, false)
    end
    return true
end
function TerrainDeformationSyncer:onCellUpdate(cellX, cellZ)
    local cellId = self:getCellId(cellX, cellZ)
    local listeners = self.updateListeners[cellId]
    if listeners ~= nil then
        for listener, _ in pairs(listeners) do
            listener:onTerrainDeformationSyncerUpdate(cellX, cellZ, cellId)
        end
    end
end
function TerrainDeformationSyncer:consoleCommandToggleDebug()
    TerrainDeformationSyncer.DEBUG_ENABLED = not TerrainDeformationSyncer.DEBUG_ENABLED
    if TerrainDeformationSyncer.DEBUG_ENABLED then
        g_currentMission:addDrawable(self)
    else
        g_currentMission:removeDrawable(self)
    end
end