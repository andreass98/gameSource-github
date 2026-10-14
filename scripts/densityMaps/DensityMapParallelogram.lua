DensityMapParallelogram = {}
local DensityMapParallelogram_mt = Class(DensityMapParallelogram)
function DensityMapParallelogram.new(customMt)
    -- upvalues: (copy) DensityMapParallelogram_mt
    local self = setmetatable({}, customMt or DensityMapParallelogram_mt)
    self.worldStartX = 0
    self.worldStartZ = 0
    self.worldWidthX = 0
    self.worldWidthZ = 0
    self.worldHeightX = 0
    self.worldHeightZ = 0
    return self
end
function DensityMapParallelogram:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. ".parallelogram#worldStartXZ", self.worldStartX, self.worldStartZ)
    xmlFile:setValue(key .. ".parallelogram#worldWidthXZ", self.worldWidthX, self.worldWidthZ)
    xmlFile:setValue(key .. ".parallelogram#worldWidthXZ", self.worldHeightX, self.worldHeightZ)
end
function DensityMapParallelogram:loadFromXMLFile(xmlFile, key)
    local worldStartX, worldStartZ = xmlFile:getValue(key .. "#worldStartXZ")
    local worldWidthX, worldWidthZ = xmlFile:getValue(key .. "#worldWidthXZ")
    local worldHeightX, worldHeightZ = xmlFile:getValue(key .. "#worldHeightXZ")
    if worldWidthX == nil or (worldWidthZ == nil or (worldHeightX == nil or worldHeightZ == nil)) then
        return false
    end
    self.worldStartX = worldStartX
    self.worldStartZ = worldStartZ
    self.worldWidthX = worldWidthX
    self.worldWidthZ = worldWidthZ
    self.worldHeightX = worldHeightX
    self.worldHeightZ = worldHeightZ
    return true
end
function DensityMapParallelogram:getVerticesAs3DCoordinates(worldY, worldYFunc)
    local polygon3DVertices = table.create(12)
    local x = self.worldStartX + (self.worldWidthX - self.worldStartX) + (self.worldHeightX - self.worldStartX)
    local z = self.worldStartZ + (self.worldWidthZ - self.worldStartZ) + (self.worldHeightZ - self.worldStartZ)
    local x = self.worldStartX
    local z = self.worldStartZ
    local y = worldYFunc and worldYFunc(x, z) or (worldY or 0)
    table.insert(polygon3DVertices, x)
    table.insert(polygon3DVertices, y)
    table.insert(polygon3DVertices, z)
    local x = self.worldWidthX
    local z = self.worldWidthZ
    local y = worldYFunc and worldYFunc(x, z) or (worldY or 0)
    table.insert(polygon3DVertices, x)
    table.insert(polygon3DVertices, y)
    table.insert(polygon3DVertices, z)
    local x = worldYFunc and worldYFunc(x, z) or (worldY or 0)
    table.insert(polygon3DVertices, x)
    table.insert(polygon3DVertices, x)
    table.insert(polygon3DVertices, z)
    local x = self.worldHeightX
    local z = self.worldHeightZ
    local y = worldYFunc and worldYFunc(x, z) or (worldY or 0)
    table.insert(polygon3DVertices, x)
    table.insert(polygon3DVertices, y)
    table.insert(polygon3DVertices, z)
    return polygon3DVertices
end
function DensityMapParallelogram:getCenter()
    return (self.worldStartX + self.worldWidthX + (self.worldStartX + (self.worldWidthX - self.worldStartX) + (self.worldHeightX - self.worldStartX)) + self.worldHeightX) * 0.25, (self.worldStartZ + self.worldWidthZ + (self.worldStartZ + (self.worldWidthZ - self.worldStartZ) + (self.worldHeightZ - self.worldStartZ)) + self.worldHeightZ) * 0.25
end
function DensityMapParallelogram:visualize(lifetime, groupId, maxCount)
    local debugPlane = DebugPlane.newSimple(true, true, nil, true)
    debugPlane:createWithPositions(self.worldStartX, 0, self.worldStartZ, self.worldWidthX, 0, self.worldWidthZ, self.worldHeightX, 0, self.worldHeightZ)
    debugPlane:addToManager(groupId, lifetime or 15000, maxCount)
end
function DensityMapParallelogram:applyToModifier(modifier)
    modifier:clearPolygonPoints()
    modifier:addPolygonPointWorldCoords(self.worldStartX, self.worldStartZ)
    modifier:addPolygonPointWorldCoords(self.worldWidthX, self.worldWidthZ)
    modifier:addPolygonPointWorldCoords(self.worldStartX + (self.worldWidthX - self.worldStartX) + (self.worldHeightX - self.worldStartX), self.worldStartZ + (self.worldWidthZ - self.worldStartZ) + (self.worldHeightZ - self.worldStartZ))
    modifier:addPolygonPointWorldCoords(self.worldHeightX, self.worldHeightZ)
end
function DensityMapParallelogram:updateFromNodes(startNode, widthNode, heightNode)
    self.worldStartX, _, self.worldStartZ = getWorldTranslation(startNode)
    self.worldWidthX, _, self.worldWidthZ = getWorldTranslation(widthNode)
    self.worldHeightX, _, self.worldHeightZ = getWorldTranslation(heightNode)
end
function DensityMapParallelogram:updateFromPositionAndSize(worldX, worldZ, widthX, widthZ, heightX, heightZ)
    self.worldStartX = worldX
    self.worldStartZ = worldZ
    self.worldWidthX = worldX + widthX
    self.worldWidthZ = worldZ + widthZ
    self.worldHeightX = worldX + heightX
    self.worldHeightZ = worldZ + heightZ
end
function DensityMapParallelogram:updateFromWorldPositions(worldStartX, worldStartZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ)
    self.worldStartX = worldStartX
    self.worldStartZ = worldStartZ
    self.worldWidthX = worldWidthX
    self.worldWidthZ = worldWidthZ
    self.worldHeightX = worldHeightX
    self.worldHeightZ = worldHeightZ
end
function DensityMapParallelogram.createFromNodes(startNode, widthNode, heightNode)
    local parallelogram = DensityMapParallelogram.new()
    parallelogram:updateFromNodes(startNode, widthNode, heightNode)
    return parallelogram
end
function DensityMapParallelogram.createFromPositionAndSize(worldX, worldZ, widthX, widthZ, heightX, heightZ)
    local parallelogram = DensityMapParallelogram.new()
    parallelogram:updateFromPositionAndSize(worldX, worldZ, widthX, widthZ, heightX, heightZ)
    return parallelogram
end
function DensityMapParallelogram.createFromWorldPositions(worldStartX, worldStartZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ)
    local parallelogram = DensityMapParallelogram.new()
    parallelogram:updateFromWorldPositions(worldStartX, worldStartZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ)
    return parallelogram
end
function DensityMapParallelogram.createFromXMLFile(xmlFile, key)
    local worldStartX, worldStartZ = xmlFile:getValue(key .. ".parallelogram#worldStartXZ")
    if worldStartX == nil and worldStartZ == nil then
        return nil
    elseif worldStartX == nil or worldStartZ == nil then
        Logging.xmlWarning(xmlFile, "Invalid worldStartXZ for DensityMapParallelogram in \'%s\'", key)
        return nil
    else
        local worldWidthX, worldWidthZ = xmlFile:getValue(key .. ".parallelogram#worldWidthXZ")
        local worldHeightX, worldHeightZ = xmlFile:getValue(key .. ".parallelogram#worldHeightXZ")
        if worldWidthX == nil or (worldWidthZ == nil or (worldHeightX == nil or worldHeightZ == nil)) then
            if worldWidthX == nil and (worldWidthZ == nil and (worldHeightX == nil and worldHeightZ == nil)) then
                local widthX, widthZ = xmlFile:getValue(key .. ".parallelogram#widthXZ")
                local heightX, heightZ = xmlFile:getValue(key .. ".parallelogram#heightXZ")
                if widthX == nil or (widthZ == nil or (heightX == nil or heightZ == nil)) then
                    if widthX == nil and (widthZ == nil and (heightX == nil and heightZ == nil)) then
                        Logging.xmlWarning(xmlFile, "Invalid data for DensityMapParallelogram in \'%s\'", key)
                        return nil
                    elseif widthX == nil or widthZ == nil then
                        Logging.xmlWarning(xmlFile, "Invalid worldWidthXZ for DensityMapParallelogram in \'%s\'", key)
                        return nil
                    else
                        Logging.xmlWarning(xmlFile, "Invalid worldHeightXZ for DensityMapParallelogram in \'%s\'", key)
                        return nil
                    end
                else
                    return DensityMapParallelogram.createFromPositionAndSize(worldStartX, worldStartZ, widthX, widthZ, heightX, heightZ)
                end
            elseif worldWidthX == nil or worldWidthZ == nil then
                Logging.xmlWarning(xmlFile, "Invalid worldWidthXZ for DensityMapParallelogram in \'%s\'", key)
                return nil
            else
                Logging.xmlWarning(xmlFile, "Invalid worldHeightXZ for DensityMapParallelogram in \'%s\'", key)
                return nil
            end
        else
            return DensityMapParallelogram.createFromWorldPositions(worldStartX, worldStartZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ)
        end
    end
end
function DensityMapParallelogram.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_2, basePath .. ".parallelogram#worldStartXZ", "Parallelogram world start position (x,z)", nil, false)
    schema:register(XMLValueType.VECTOR_2, basePath .. ".parallelogram#worldWidthXZ", "Parallelogram world width position (x,z)", nil, false)
    schema:register(XMLValueType.VECTOR_2, basePath .. ".parallelogram#worldHeightXZ", "Parallelogram world height position (x,z)", nil, false)
    schema:register(XMLValueType.VECTOR_2, basePath .. ".parallelogram#widthXZ", "Parallelogram world width size (x,z)", nil, false)
    schema:register(XMLValueType.VECTOR_2, basePath .. ".parallelogram#heightXZ", "Parallelogram world height size (x,z)", nil, false)
end