Polygon2D = {}
local Polygon2D_mt = Class(Polygon2D)
function Polygon2D.new(numVertices, vertexCoordinates, customMt)
    -- upvalues: (copy) Polygon2D_mt
    local self = setmetatable({}, customMt or Polygon2D_mt)
    if vertexCoordinates == nil then
        if numVertices == nil or numVertices <= 4 then
            self.vertices = {}
            return self
        else
            self.vertices = table.create(numVertices * 2)
            return self
        end
    else
        self:setVertices(vertexCoordinates)
        return self
    end
end
function Polygon2D:addPos(x, z)
    self.vertices[#self.vertices + 1] = x
    self.vertices[#self.vertices + 1] = z
    self.bbMinX = nil
    self.bbMaxX = nil
    self.bbMinZ = nil
    self.bbMaxZ = nil
    self.area = nil
    self.curveOrientation = nil
end
function Polygon2D:addNode(node)
    local x, _y, z = getWorldTranslation(node)
    self.vertices[#self.vertices + 1] = x
    self.vertices[#self.vertices + 1] = z
    self.bbMinX = nil
    self.bbMaxX = nil
    self.bbMinZ = nil
    self.bbMaxZ = nil
    self.area = nil
    self.curveOrientation = nil
end
function Polygon2D:addNodes(nodes)
    for _, node in ipairs(nodes) do
        local x, _y, z = getWorldTranslation(node)
        self.vertices[#self.vertices + 1] = x
        self.vertices[#self.vertices + 1] = z
    end
    self.bbMinX = nil
    self.bbMaxX = nil
    self.bbMinZ = nil
    self.bbMaxZ = nil
    self.area = nil
    self.curveOrientation = nil
end
function Polygon2D:getVertices()
    return self.vertices
end
function Polygon2D:iteratorVertices(startOffset, endIndexOffset)
    local currentIndex = 1 + (startOffset or 0) * 2
    local endIndex = #self.vertices - 2 * (endIndexOffset or 0)
    return function()
        -- upvalues: (ref) currentIndex, (copy) endIndex, (copy) self
        if endIndex <= currentIndex then
            return nil
        end
        currentIndex = currentIndex + 2
        return (currentIndex - 1) / 2, self.vertices[currentIndex - 2], self.vertices[currentIndex - 1]
    end
end
function Polygon2D:setVertices(vertices)
    self.vertices = vertices
    self.bbMinX = nil
    self.bbMaxX = nil
    self.bbMinZ = nil
    self.bbMaxZ = nil
    self.area = nil
    self.curveOrientation = nil
end
function Polygon2D:setVerticesFromXYZ(verticesXYZ)
    local numVerts2D = math.floor(#verticesXYZ * 0.6666666666666666)
    self.vertices = table.create(numVerts2D)
    local i = 1
    for i = i, #verticesXYZ, 3 do
        table.insert(self.vertices, verticesXYZ[i])
        table.insert(self.vertices, verticesXYZ[i + 2])
    end
    self.bbMinX = nil
    self.bbMaxX = nil
    self.bbMinZ = nil
    self.bbMaxZ = nil
    self.area = nil
    self.curveOrientation = nil
end
function Polygon2D:getNumVertices()
    return #self.vertices / 2
end
function Polygon2D:removeVertex(index)
    index = index * 2 - 1
    table.remove(self.vertices, index)
    table.remove(self.vertices, index)
    self.bbMinX = nil
    self.bbMaxX = nil
    self.bbMinZ = nil
    self.bbMaxZ = nil
    self.area = nil
    self.curveOrientation = nil
end
function Polygon2D:getVertex(index)
    index = index * 2
    return self.vertices[index - 1], self.vertices[index]
end
function Polygon2D:getLastVertex()
    if #self.vertices == 0 then
        return nil
    else
        return self.vertices[#self.vertices - 1], self.vertices[#self.vertices]
    end
end
function Polygon2D:getVerticesAs3DCoordinates(worldY, worldYFunc)
    local polygon3DVertices = table.create(#self.vertices * 1.5)
    local i = 1
    for i = i, #self.vertices, 2 do
        polygon3DVertices[#polygon3DVertices + 1] = self.vertices[i]
        polygon3DVertices[#polygon3DVertices + 1] = worldYFunc and worldYFunc(self.vertices[i], self.vertices[i + 1], (i + 1) / 2) or (worldY or 0)
        polygon3DVertices[#polygon3DVertices + 1] = self.vertices[i + 1]
    end
    return polygon3DVertices
end
function Polygon2D:getNumEdges()
    return #self.vertices <= 2 and 0 or (#self.vertices == 4 and 1 or #self.vertices / 2)
end
function Polygon2D:getEdge(index)
    index = index * 2 - 1
    if index + 3 <= #self.vertices then
        return self.vertices[index], self.vertices[index + 1], self.vertices[index + 2], self.vertices[index + 3]
    else
        return self.vertices[index], self.vertices[index + 1], self.vertices[1], self.vertices[2]
    end
end
function Polygon2D:iteratorEdges(startOffset, endIndexOffset)
    if #self.vertices < 4 then
        return function()
            return nil
        end
    end
    local currentIndex = 1 + (startOffset or 0) * 2
    local endIndex = #self.vertices - 2 * (endIndexOffset or 0)
    return function()
        -- upvalues: (ref) currentIndex, (copy) endIndex, (copy) self
        if endIndex <= currentIndex then
            return nil
        else
            currentIndex = currentIndex + 2
            if currentIndex + 1 <= #self.vertices then
                return (currentIndex - 1) / 2, self.vertices[currentIndex - 2], self.vertices[currentIndex - 1], self.vertices[currentIndex], self.vertices[currentIndex + 1]
            elseif #self.vertices < 6 then
                return nil
            else
                return (currentIndex - 1) / 2, self.vertices[currentIndex - 2], self.vertices[currentIndex - 1], self.vertices[1], self.vertices[2]
            end
        end
    end
end
function Polygon2D:getBoundingBox()
    if self.bbMinX ~= nil then
        return self.bbMinX, self.bbMaxX, self.bbMinZ, self.bbMaxZ
    end
    if #self.vertices == 0 then
        return nil, nil, nil, nil
    end
    local minX = math.huge
    local maxX = -math.huge
    local minZ = math.huge
    local maxZ = -math.huge
    local i = 1
    for i = i, #self.vertices, 2 do
        minX = math.min(minX, self.vertices[i])
        maxX = math.max(maxX, self.vertices[i])
        minZ = math.min(minZ, self.vertices[i + 1])
        maxZ = math.max(maxZ, self.vertices[i + 1])
    end
    self.bbMinX = minX
    self.bbMaxX = maxX
    self.bbMinZ = minZ
    self.bbMaxZ = maxZ
    return minX, maxX, minZ, maxZ
end
function Polygon2D:getArea()
    if self.area ~= nil then
        return self.area
    end
    local doubleArea = 0
    local vertices = self.vertices
    local i = 1
    for i = i, #vertices, 2 do

    end
    self.area = math.abs(doubleArea / 2)
    return self.area
end
function Polygon2D:getConvexHull()
    local vertices = {}
    local hullVertices = {}
    local minX = math.huge
    local minZ = math.huge
    for _, vx, vz in self:iteratorVertices() do
        vertices[#vertices + 1] = { vx, vz }
        if vz < minZ or vz == minZ and vx < minX then
            vertices[1] = vertices[#vertices]
            vertices[#vertices] = vertices[1]
            minX = vx
            minZ = vz
        end
    end
    table.sort(vertices, function(a, b)
        -- upvalues: (ref) minX, (ref) minZ
        local x2 = a[1]
        local z2 = a[2]
        local value = (z2 - minZ) * (b[1] - x2) - (x2 - minX) * (b[2] - z2)
        local o = value > 0 and 1 or (value < 0 and -1 or 0)
        if o == 0 then
            return MathUtil.vector2LengthSq(minX - b[1], minZ - b[2]) < MathUtil.vector2LengthSq(minX - a[1], minZ - a[2])
        else
            return o ~= -1
        end
    end)
    for vx, vz in ipairs(vertices) do
        if #hullVertices > 3 then
            local x2 = hullVertices[#hullVertices - 1]
            local z2 = hullVertices[#hullVertices]
            local value = (z2 - hullVertices[#hullVertices - 2]) * (vz[1] - x2) - (x2 - hullVertices[#hullVertices - 3]) * (vz[2] - z2)
            if (value > 0 and 1 or (value < 0 and -1 or 0)) > 0 then
                break
            end
            table.remove(hullVertices)
            table.remove(hullVertices)
            continue
        end
        hullVertices[#hullVertices + 1] = vz[1]
        hullVertices[#hullVertices + 1] = vz[2]
    end
    return hullVertices
end
function Polygon2D:getCurveOrientation()
    if self.curveOrientation ~= nil then
        return self.curveOrientation
    end
    local doubleArea = 0
    local vertices = self.vertices
    local i = 1
    for i = i, #vertices, 2 do

    end
    self.curveOrientation = math.sign(doubleArea)
    return self.curveOrientation
end
function Polygon2D:getIsPosInside(x, z)
    if #self.vertices < 6 then
        return false
    end
    local minX, maxX, minZ, maxZ = self:getBoundingBox()
    if x < minX or (maxX < x or (z < minZ or maxZ < z)) then
        return false
    end
    local intersectCount = 0
    local i = 1
    for i = i, #self.vertices, 2 do
        local hasIntersection, _ix, _iz = MathUtil.getLineSegmentsIntersection(x, z, 100000, z, self.vertices[i], self.vertices[i + 1], self.vertices[i + 2] or self.vertices[1], self.vertices[i + 3] or self.vertices[2])
        if hasIntersection then
        end
    end
    return intersectCount % 2 ~= 0, intersectCount
end
function Polygon2D:getIsLineSegmentIntersecting(lx1, lz1, lx2, lz2)
    for _, x1, z1, x2, z2 in self:iteratorEdges() do
        if MathUtil.getAreLineSegmentsIntersecting(x1, z1, x2, z2, lx1, lz1, lx2, lz2) then
            return true
        end
    end
    return self:getIsPosInside(lx1, lz1) and true or (self:getIsPosInside(lx2, lz2) and true or false)
end
function Polygon2D:getIsCircleIntersecting(x, z, radius)
    if self:getIsPosInside(x, z) then
        return true
    end
    for _, x1, z1, x2, z2 in self:iteratorEdges() do
        if MathUtil.getDistanceToLineSegment2D(x1, z1, x2, z2, x, z) <= radius then
            return true
        end
    end
    return false
end
function Polygon2D:getIsCircleInside(x, z, radius)
    if not self:getIsPosInside(x, z) then
        return false
    end
    for _, x1, z1, x2, z2 in self:iteratorEdges() do
        if MathUtil.getDistanceToLineSegment2D(x1, z1, x2, z2, x, z) < radius then
            return false
        end
    end
    return true
end
function Polygon2D:renderEdges(worldY, color, alignToTerrain, showEdgeLength, solid)
    local r, g, b, a = (color or Color.PRESETS.WHITE):unpack()
    local v2y = worldY
    for edgeIndex, v1x, v1z, v2x, v2z in self:iteratorEdges() do
        if alignToTerrain and g_terrainNode ~= nil then
            worldY = getTerrainHeightAtWorldPos(g_terrainNode, v1x, 0, v1z)
            v2y = getTerrainHeightAtWorldPos(g_terrainNode, v2x, 0, v2z)
        end
        drawDebugLine(v1x, worldY, v1z, r, g, b, v2x, v2y, v2z, r, g, b, solid)
        if showEdgeLength then
            local len = MathUtil.vector2Length(v1x - v2x, v1z - v2z)
            Utils.renderTextAtWorldPosition((v1x + v2x) / 2, (worldY + v2y) / 2, (v1z + v2z) / 2, string.format("#%d %.2f", edgeIndex, len), nil, nil, r, g, b, a)
        end
    end
end
function Polygon2D:getOffsetPolygon(offset)
    if self:getNumEdges() < 3 then
        return nil
    end
    local offsetPolygon = Polygon2D.new()
    local orientation = self:getCurveOrientation()
    for edgeIndex, x1, z1, x2, z2 in self:iteratorEdges() do
        local oldEdge = edgeIndex - 1
        if oldEdge < 1 then
            oldEdge = #self.vertices / 2
        end
        local e1nX = x2 - x1
        local e1nZ = z2 - z1
        if MathUtil.vector2Length(e1nX, e1nZ) < offset then
            return nil
        end
        local x0, z0 = MathUtil.vector2Normalize(e1nX, e1nZ)
        local x0, z0 = self:getEdge(oldEdge)
        local e2nX = x1 - x0
        local e2nZ = z1 - z0
        if MathUtil.vector2Length(e2nX, e2nZ) < offset then
            return nil
        end
        local nX, nZ = MathUtil.vector2Normalize(e2nX, e2nZ)
        local nX = z0 + nZ
        local nZ = -x0 - nX
        if nX == 0 and nZ == 0 then
            return nil
        end
        local offsetLen = offset * orientation / math.sqrt((1 + z0 * nZ + -x0 * -nX) / 2)
        local nX, nZ = MathUtil.vector2SetLength(nX, nZ, offsetLen)
        offsetPolygon:addPos(x1 + nX, z1 + nZ)
    end
    return offsetPolygon
end
function Polygon2D:renderFace(worldY, color, alignToTerrain)
    if #self.vertices >= 6 then
        local r, g, b, a = (color or Color.PRESETS.WHITE):unpack()
        drawDebugPolygon(self:getVerticesAs3DCoordinates(worldY, alignToTerrain and g_terrainNode ~= nil and function(x, z)
            return getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
        end or nil), r, g, b, a, false)
    end
end