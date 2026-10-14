MapDataGrid = {}
local MapDataGrid_mt = Class(MapDataGrid, DataGrid)
function MapDataGrid.new(mapSize, blocksPerRowColumn, customMt)
    -- upvalues: (copy) MapDataGrid_mt
    local self = DataGrid.new(blocksPerRowColumn, blocksPerRowColumn, customMt or MapDataGrid_mt)
    self.blocksPerRowColumn = blocksPerRowColumn
    self.mapSize = mapSize
    self.blockSize = self.mapSize / self.blocksPerRowColumn
    return self
end
function MapDataGrid.createFromBlockSize(mapSize, blockSize, customMt)
    local blocksPerRowColumn = math.ceil(mapSize / blockSize)
    return MapDataGrid.new(mapSize, blocksPerRowColumn, customMt)
end
function MapDataGrid:getValueAtWorldPos(worldX, worldZ)
    local rowIndex, colIndex = self:getRowColumnFromWorldPos(worldX, worldZ)
    return self:getValue(rowIndex, colIndex), rowIndex, colIndex
end
function MapDataGrid:setValueAtWorldPos(worldX, worldZ, value)
    local rowIndex, colIndex = self:getRowColumnFromWorldPos(worldX, worldZ)
    self:setValue(rowIndex, colIndex, value)
end
function MapDataGrid:getRowColumnFromWorldPos(worldX, worldZ)
    local mapSize = self.mapSize
    local blocksPerRowColumn = self.blocksPerRowColumn
    local column = math.ceil(blocksPerRowColumn * ((worldZ + mapSize * 0.5) / mapSize))
    local row = math.clamp(column, 1, blocksPerRowColumn)
    return row, math.clamp(math.ceil(blocksPerRowColumn * ((worldX + mapSize * 0.5) / mapSize)), 1, blocksPerRowColumn)
end
function MapDataGrid:isWorldPositionInRange(worldX, worldZ)
    return self.mapSize * -0.5 < worldX and worldX <= self.mapSize * 0.5 and self.mapSize * -0.5 < worldZ and worldZ <= self.mapSize * 0.5
end
function MapDataGrid:getBoundaries(row, column)
    return (column - 1) * self.blockSize - self.mapSize * 0.5, column * self.blockSize - self.mapSize * 0.5, (row - 1) * self.blockSize - self.mapSize * 0.5, row * self.blockSize - self.mapSize * 0.5
end