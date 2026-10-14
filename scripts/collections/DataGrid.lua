DataGrid = {}
local DataGrid_mt = Class(DataGrid)
function DataGrid.new(numRows, numColumns, customMt)
    -- upvalues: (copy) DataGrid_mt
    local self = setmetatable({}, customMt or DataGrid_mt)
    self.grid = {}
    self.numRows = numRows
    self.numColumns = numColumns
    for _ = 1, numRows do
        table.insert(self.grid, {})
    end
    return self
end
function DataGrid:delete()
    self.grid = nil
end
function DataGrid:getValue(rowIndex, colIndex)
    if rowIndex < 1 or self.numRows < rowIndex then
        Logging.error("rowIndex out of bounds!")
        printCallstack()
        return nil
    end
    if colIndex >= 1 and self.numColumns >= colIndex then
        return self.grid[rowIndex][colIndex]
    end
    Logging.error("colIndex out of bounds!")
    printCallstack()
    return nil
end
function DataGrid:setValue(rowIndex, colIndex, value)
    if rowIndex < 1 or self.numRows < rowIndex then
        Logging.error("rowIndex out of bounds!")
        printCallstack()
        return false
    end
    if colIndex >= 1 and self.numColumns >= colIndex then
        self.grid[rowIndex][colIndex] = value
        return true
    end
    Logging.error("colIndex out of bounds!")
    printCallstack()
    return false
end
function DataGrid:isRowColumnInRange(rowIndex, colIndex)
    return rowIndex > 0 and rowIndex <= self.numRows and colIndex > 0 and colIndex <= self.numColumns
end
function DataGrid:doForAll(cellFunction)
    local cellX = 1
    for cellX = cellX, self.numColumns do
        local cellY = 1
        for cellY = cellY, self.numRows do
            cellFunction(cellX, cellY, self:getValue(cellY, cellX))
        end
    end
end