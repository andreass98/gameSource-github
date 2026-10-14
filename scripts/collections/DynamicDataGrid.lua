DynamicDataGrid = {}
local DynamicDataGrid_mt = Class(DynamicDataGrid)
function DynamicDataGrid.new(size, tileSize, startX, startZ, cellConstructor, customMt)
    -- upvalues: (copy) DynamicDataGrid_mt
    local self = setmetatable({}, customMt or DynamicDataGrid_mt)
    self.tileSize = tileSize or 1
    self.size = size or 20
    self.rowColumnCount = math.ceil(self.size / self.tileSize)
    local columnIndex = self.rowColumnCount * 0.5
    self.centreIndex = math.floor(columnIndex) + 1
    self.localStartIndex = 1 - self.centreIndex
    self.localEndIndex = self.localStartIndex + self.rowColumnCount - 1
    self.lastPosition = {
        ["x"] = 0,
        ["z"] = 0
    }
    if startX and startZ then
        self.lastPosition.x = startX
        self.lastPosition.z = startZ
    end
    self.movedCells = {}
    self.grid = {}
    local columnIndex = self.localStartIndex
    for columnIndex = columnIndex, self.localEndIndex do
        local column = {}
        local rowIndex = self.localStartIndex
        for rowIndex = rowIndex, self.localEndIndex do
            local cell
            if cellConstructor then
                local cellWorldX, cellWorldZ = self:getWorldPositionByLocalIndices(columnIndex, rowIndex)
                cell = cellConstructor(cellWorldX, cellWorldZ)
            else
                cell = {}
            end
            table.insert(column, cell)
        end
        table.insert(self.grid, column)
    end
    self.yOffset = 0.05
    return self
end
function DynamicDataGrid:delete()
    local columnIndex = self.localStartIndex
    for columnIndex = columnIndex, self.localEndIndex do
        local rowIndex = self.localStartIndex
        for rowIndex = rowIndex, self.localEndIndex do
            local cell = self:getCellFromLocalIndices(columnIndex, rowIndex)
            if cell and cell.delete then
                cell:delete()
            end
        end
    end
    self.grid = nil
end
function DynamicDataGrid:drawDebug(areaColorFunction, cellFunction)
    local startX = self.lastPosition.x / self.tileSize
    local xIndexLast = math.floor(startX) * self.tileSize
    local startZ = self.lastPosition.z / self.tileSize
    local zIndexLast = math.floor(startZ) * self.tileSize
    local startX = xIndexLast - math.floor(self.rowColumnCount * 0.5) * self.tileSize
    local startZ = zIndexLast - math.floor(self.rowColumnCount * 0.5) * self.tileSize
    for xIndex, column in ipairs(self.grid) do
        for zIndex, cell in ipairs(column) do
            if areaColorFunction ~= nil then
                local x1 = startX + self.tileSize
                local z2 = startZ + self.tileSize
                local r, g, b, a = areaColorFunction(cell)
                local y = getTerrainHeightAtWorldPos(g_terrainNode, startX, 0, startZ) + self.yOffset
                local y1 = getTerrainHeightAtWorldPos(terrainNode, x1, 0, startZ) + self.yOffset
                local y2 = getTerrainHeightAtWorldPos(terrainNode, startX, 0, z2) + self.yOffset
                local y3 = getTerrainHeightAtWorldPos(terrainNode, x1, 0, z2) + self.yOffset
                drawDebugTriangle(startX, y, startZ, startX, y2, z2, x1, y1, startZ, r, g, b, a, false)
                drawDebugTriangle(x1, y1, startZ, startX, y2, z2, x1, y3, z2, r, g, b, a, false)
            end
            if cellFunction ~= nil then
                cellFunction(cell, startX + self.tileSize * 0.5, startZ + self.tileSize * 0.5)
            end
            startZ = startZ + self.tileSize
        end
        startX = startX + self.tileSize
    end
end
function DynamicDataGrid:getCellFromLocalIndices(localIndexX, localIndexZ)
    localIndexZ = localIndexZ or 0
    local column = self.grid[self.centreIndex + (localIndexX or 0)]
    if column == nil then
        return nil
    else
        return column[self.centreIndex + localIndexZ]
    end
end
function DynamicDataGrid:getCellFromWorldPosition(worldX, worldZ, clamp)
    local xIndex, zIndex = self:getLocalIndicesByWorldPosition(worldX, worldZ)
    if clamp then
        xIndex = math.clamp(xIndex, self.localStartIndex, self.localEndIndex)
        zIndex = math.clamp(zIndex, self.localStartIndex, self.localEndIndex)
    end
    local xrows = self.grid[self.centreIndex + xIndex]
    if xrows == nil then
        return nil
    else
        return xrows[self.centreIndex + zIndex]
    end
end
function DynamicDataGrid:getWorldPositionByLocalIndices(localIndexX, localIndexZ)
    local currentIndexX, currentIndexZ = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
    return self:getGridSnappedPositionByLocalIndices(currentIndexX + localIndexX, currentIndexZ + localIndexZ)
end
function DynamicDataGrid:getLocalIndicesByWorldPosition(worldX, worldZ)
    local currentIndexX, currentIndexZ = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
    local worldIndexX, worldIndexZ = self:getWorldIndicesByWorldPosition(worldX, worldZ)
    return worldIndexX - currentIndexX, worldIndexZ - currentIndexZ
end
function DynamicDataGrid:getGridSnappedPositionByLocalIndices(localIndexX, localIndexZ)
    return self:getGridSnappedPosition(localIndexX * self.tileSize, localIndexZ * self.tileSize)
end
function DynamicDataGrid:getGridSnappedPosition(x, z)
    local snappedX = math.floor(x / self.tileSize) * self.tileSize
    local snappedZ = math.floor(z / self.tileSize) * self.tileSize
    return snappedX + self.tileSize / 2, snappedZ + self.tileSize / 2
end
function DynamicDataGrid:getGridIndicesByWorldPosition(worldX, worldZ)
    local worldIndexX, worldIndexZ = self:getWorldIndicesByWorldPosition(worldX, worldZ)
    local currentIndexX, currentIndexZ = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
    return worldIndexX - currentIndexX + self.centreIndex, worldIndexZ - currentIndexZ + self.centreIndex
end
function DynamicDataGrid:getWorldIndicesByWorldPosition(worldX, worldZ)
    return math.floor(worldX / self.tileSize), math.floor(worldZ / self.tileSize)
end
function DynamicDataGrid:setWorldPosition(x, z)
    local xIndex, zIndex = self:getWorldIndicesByWorldPosition(x, z)
    local lastXIndex, lastZIndex = self:getWorldIndicesByWorldPosition(self.lastPosition.x, self.lastPosition.z)
    self.lastPosition.x = x
    self.lastPosition.z = z
    local xChange = xIndex - lastXIndex
    local zChange = zIndex - lastZIndex
    if xChange ~= 0 then
        local direction = math.sign(xChange)
        local insertIndex = math.abs(xChange)
        local removeIndex = self.rowColumnCount
        local movingLeft = math.min(insertIndex, removeIndex)
        for i = 1, movingLeft do
            local movingLeft = direction < 0
            local insertIndex = movingLeft and 1 or nil
            local removeIndex = movingLeft and self.rowColumnCount or 1
            local column = table.remove(self.grid, removeIndex)
            for rowIndex, cell in ipairs(column) do
                self.movedCells[cell] = cell
            end
            if insertIndex == nil then
                table.insert(self.grid, column)
            else
                table.insert(self.grid, insertIndex, column)
            end
        end
    end
    if zChange ~= 0 then
        local direction = math.sign(zChange)
        local insertIndex = math.abs(zChange)
        local removeIndex = self.rowColumnCount
        local movingLeft = math.min(insertIndex, removeIndex)
        for i = 1, movingLeft do
            local removeIndex = 1
            local insertIndex = 1
            for removeIndex = removeIndex, self.rowColumnCount, insertIndex do
                local column = direction < 0
                local insertIndex = column and 1 or nil
                local column = self.grid[column and self.rowColumnCount or 1]
                local rowIndex = table.remove(column, removeIndex)
                self.movedCells[rowIndex] = rowIndex
                if insertIndex == nil then
                    table.insert(column, rowIndex)
                else
                    table.insert(column, insertIndex, rowIndex)
                end
            end
        end
    end
    local columnIndex = self.localStartIndex
    local direction = self.localEndIndex
    for columnIndex = columnIndex, direction do
        local insertIndex = self.localStartIndex
        for insertIndex = insertIndex, self.localEndIndex do
            local removeIndex = self:getCellFromLocalIndices(columnIndex, insertIndex)
            if self.movedCells[removeIndex] then
                if removeIndex.onCellMoved then
                    local column, insertIndex = self:getWorldPositionByLocalIndices(columnIndex, insertIndex)
                    removeIndex:onCellMoved(column, insertIndex)
                else
                    table.clear(removeIndex)
                end
            end
        end
    end
    table.clear(self.movedCells)
end