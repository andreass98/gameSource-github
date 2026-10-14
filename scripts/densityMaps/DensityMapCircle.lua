DensityMapCircle = {}
local DensityMapCircle_mt = Class(DensityMapCircle)
function DensityMapCircle.new(customMt)
    -- upvalues: (copy) DensityMapCircle_mt
    local self = setmetatable({}, customMt or DensityMapCircle_mt)
    self.worldPosX = 0
    self.worldPosZ = 0
    self.radius = 0
    self.numSegments = 1
    self.points = {}
    return self
end
function DensityMapCircle:saveToXMLFile(xmlFile, key)
    xmlFile:setValue(key .. ".circle#worldPositionXZ", self.worldPosX, self.worldPosZ)
    xmlFile:setValue(key .. ".circle#radius", self.radius)
    xmlFile:setValue(key .. ".circle#numSegments", self.numSegments)
end
function DensityMapCircle:loadFromXMLFile(xmlFile, key)
    local worldPosX, worldPosZ = xmlFile:getValue(key .. ".circle#worldPositionXZ")
    local radius = xmlFile:getValue(key .. ".circle#radius")
    local numSegments = xmlFile:getValue(key .. ".circle#numSegments")
    if worldPosX == nil or (worldPosZ == nil or (radius == nil or numSegments == nil)) then
        return false
    end
    self.worldPosX = worldPosX
    self.worldPosZ = worldPosZ
    self.radius = radius
    self.numSegments = numSegments
    return true
end
function DensityMapCircle:updateFromWorldPosition(worldPosX, worldPosZ, radius, numSegments)
    if numSegments < #self.points then
        table.clear(self.points)
    end
    self.worldPosX = worldPosX
    self.worldPosZ = worldPosZ
    self.radius = radius
    self.numSegments = numSegments
    local i = 1
    for i = i, numSegments do
        local a1 = (i - 1) / numSegments * 2 * 3.141592653589793
        local c = math.cos(a1) * radius
        local s = math.sin(a1) * radius
        if self.points[i] == nil then
            self.points[i] = { worldPosX + c, worldPosZ + s }
        else
            self.points[i][1] = x
            self.points[i][2] = z
        end
    end
end
function DensityMapCircle:getVerticesAs3DCoordinates(worldY, worldYFunc)
    local polygon3DVertices = table.create(#self.points * 3)
    for _, point in ipairs(self.points) do
        local x = point[1]
        local z = point[2]
        local y = worldYFunc and worldYFunc(x, z) or (worldY or 0)
        table.insert(polygon3DVertices, x)
        table.insert(polygon3DVertices, y)
        table.insert(polygon3DVertices, z)
    end
    return polygon3DVertices
end
function DensityMapCircle:getCenter()
    return self.worldPosX, self.worldPosZ
end
function DensityMapCircle:applyToModifier(modifier)
    modifier:clearPolygonPoints()
    for _, point in ipairs(self.points) do
        modifier:addPolygonPointWorldCoords(point[1], point[2])
    end
end
function DensityMapCircle:visualize(lifetime, groupId, maxCount)
    local debugPolygon = DebugPolygon.new()
    for _, point in ipairs(self.points) do
        local x = point[1]
        local z = point[2]
        debugPolygon:addPosition(x, getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z), z)
    end
    local color = DebugUtil.getDebugColor():copy()
    color.a = 0.3
    debugPolygon:setColor(color)
    debugPolygon:setIsSolid(false)
    debugPolygon:setDrawContour(true)
    debugPolygon:addToManager(groupId, lifetime or 15000, maxCount)
end
function DensityMapCircle.createCircle(worldPosX, worldPosZ, radius, numSegments)
    local polygon = DensityMapCircle.new()
    polygon:updateFromWorldPosition(worldPosX, worldPosZ, radius, numSegments)
    return polygon
end
function DensityMapCircle.createFromXMLFile(xmlFile, key)
    local worldPosX, worldPosZ = xmlFile:getValue(key .. ".circle#worldPositionXZ")
    if worldPosX == nil and worldPosZ == nil then
        return nil
    end
    if worldPosX == nil or worldPosZ == nil then
        Logging.xmlWarning(xmlFile, "Invalid worldStartXZ for DensityMapCircle in \'%s\'", key)
        return nil
    end
    local radius = xmlFile:getValue(key .. ".circle#radius", 5)
    local numSegments = xmlFile:getValue(key .. ".circle#numSegments", 5)
    return DensityMapCircle.createCircle(worldPosX, worldPosZ, radius, numSegments)
end
function DensityMapCircle.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.VECTOR_2, basePath .. ".circle#worldPositionXZ", "Circle center world position (x,z)", nil, false)
    schema:register(XMLValueType.FLOAT, basePath .. ".circle#radius", "Circle radius", 5, false)
    schema:register(XMLValueType.INT, basePath .. ".circle#numSegments", "Number of circle segments", 5, false)
end