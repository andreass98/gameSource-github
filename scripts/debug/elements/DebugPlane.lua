DebugPlane = {}
local DebugPlane_mt = Class(DebugPlane, DebugElement)
DebugPlane.STATIC_CALL_POSITIONS_TABLE = {
    { -1, 0, -1 },
    { 1, 0, -1 },
    { 1, 0, 1 },
    { -1, 0, 1 }
}
function DebugPlane.new(customMt)
    -- upvalues: (copy) DebugPlane_mt
    local self = DebugPlane:superClass().new(customMt or DebugPlane_mt)
    self.alignToTerrain = false
    self.filled = false
    self.doubleSided = true
    self.solid = false
    self.cornerPositions = {
        { -1, 0, -1 },
        { 1, 0, -1 },
        { 1, 0, 1 },
        { -1, 0, 1 }
    }
    return self
end
function DebugPlane.newSimple(filled, doubleSided, color, alignToTerrain)
    local self = DebugPlane.new()
    if color ~= nil then
        self:setColor(color)
    end
    self.filled = Utils.getNoNil(filled, self.filled)
    self.alignToTerrain = Utils.getNoNil(alignToTerrain, self.alignToTerrain)
    self.doubleSided = Utils.getNoNil(doubleSided, self.doubleSided)
    return self
end
function DebugPlane.calculateCornerPositions(positions, startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ)
    positions[1][1] = startX
    positions[1][2] = startY
    positions[1][3] = startZ
    positions[2][1] = widthX
    positions[2][2] = widthY
    positions[2][3] = widthZ
    positions[3][1] = startX + (widthX - startX + (heightX - startX))
    positions[3][2] = startY + (widthY - startY + (heightY - startY))
    positions[3][3] = startZ + (widthZ - startZ + (heightZ - startZ))
    positions[4][1] = heightX
    positions[4][2] = heightY
    positions[4][3] = heightZ
    return positions
end
function DebugPlane:draw()
    DebugPlane.renderWithPositions(nil, nil, nil, nil, nil, nil, nil, nil, nil, self.color, self.alignToTerrain, self.filled, self.doubleSided, self.solid, self.text, self.cornerPositions)
end
function DebugPlane.renderWithNodes(startNode, widthNode, heightNode, color, alignToTerrain, filled, doubleSided, solid, text)
    local startX, startY, startZ = getWorldTranslation(startNode)
    local widthX, widthY, widthZ = getWorldTranslation(widthNode)
    local heightX, heightY, heightZ = getWorldTranslation(heightNode)
    DebugPlane.renderWithPositions(startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ, color, alignToTerrain, filled, doubleSided, solid, text)
end
function DebugPlane.renderWithPositions(startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ, color, alignToTerrain, filled, doubleSided, solid, text, positions)
    local x1 = positions or DebugPlane.calculateCornerPositions(DebugPlane.STATIC_CALL_POSITIONS_TABLE, startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ)
    local x1 = x1[1][1]
    local y1 = x1[1][2]
    local y2 = x1[2][2]
    local y3 = x1[3][2]
    local y4 = x1[4][2]
    local r, g, b, a = (color or Color.PRESETS.WHITE):unpack()
    local x = Utils.getNoNil(alignToTerrain, true)
    local x = Utils.getNoNil(filled, false)
    local x = Utils.getNoNil(doubleSided, false)
    local x = Utils.getNoNil(solid, false)
    if x and g_terrainNode then
        y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, x1[1][3]) + 0.01
        y2 = getTerrainHeightAtWorldPos(g_terrainNode, x1[2][1], 0, x1[2][3]) + 0.01
        y3 = getTerrainHeightAtWorldPos(g_terrainNode, x1[3][1], 0, x1[3][3]) + 0.01
        y4 = getTerrainHeightAtWorldPos(g_terrainNode, x1[4][1], 0, x1[4][3]) + 0.01
    end
    if x then
        drawDebugTriangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, r, g, b, a, x)
        drawDebugTriangle(x1, y1, z1, x3, y3, z3, x4, y4, z4, r, g, b, a, x)
        if x then
            drawDebugTriangle(x3, y3, z3, x2, y2, z2, x1, y1, z1, r, g, b, a, x)
            drawDebugTriangle(x4, y4, z4, x3, y3, z3, x1, y1, z1, r, g, b, a, x)
        end
    else
        drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, x)
        drawDebugLine(x2, y2, z2, r, g, b, x3, y3, z3, r, g, b, x)
        drawDebugLine(x3, y3, z3, r, g, b, x4, y4, z4, r, g, b, x)
        drawDebugLine(x4, y4, z4, r, g, b, x1, y1, z1, r, g, b, x)
    end
    if text ~= nil then
        Utils.renderTextAtWorldPosition((x1 + x2 + x3 + x4) / 4, (y1 + y2 + y3 + y4) / 4, (z1 + z2 + z3 + z4) / 4, text, 0.02, 0, r, g, b, a)
    end
end
function DebugPlane:createWithNodes(startNode, widthNode, heightNode)
    local startX, startY, startZ = getWorldTranslation(startNode)
    local widthX, widthY, widthZ = getWorldTranslation(widthNode)
    local heightX, heightY, heightZ = getWorldTranslation(heightNode)
    self:createWithPositions(startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ)
    return self
end
function DebugPlane:createWithPositions(startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ)
    local pos = self.cornerPositions
    pos[1][1] = startX
    pos[1][2] = startY
    pos[1][3] = startZ
    pos[2][1] = widthX
    pos[2][2] = widthY
    pos[2][3] = widthZ
    pos[3][1] = startX + (widthX - startX + (heightX - startX))
    pos[3][2] = startY + (widthY - startY + (heightY - startY))
    pos[3][3] = startZ + (widthZ - startZ + (heightZ - startZ))
    pos[4][1] = heightX
    pos[4][2] = heightY
    pos[4][3] = heightZ
    return self
end
function DebugPlane:createWithPositionsOffset(startX, startY, startZ, widthXOffset, widthYOffset, widthZOffset, heightXOffset, heightYOffset, heightZOffset)
    local pos = self.cornerPositions
    pos[1][1] = startX
    pos[1][2] = startY
    pos[1][3] = startZ
    pos[2][1] = startX + widthXOffset
    pos[2][2] = startY + widthYOffset
    pos[2][3] = startZ + widthZOffset
    pos[3][1] = startX + (widthXOffset + heightXOffset)
    pos[3][2] = startY + (widthYOffset + heightYOffset)
    pos[3][3] = startZ + (widthZOffset + heightZOffset)
    pos[4][1] = startX + heightXOffset
    pos[4][2] = startY + heightYOffset
    pos[4][3] = startZ + heightZOffset
    return self
end
function DebugPlane:createWithStartEnd(startNode, endNode)
    local offsetX, offsetY, offsetZ = localToLocal(endNode, startNode, 0, 0, 0)
    local x, y, z = localToWorld(startNode, offsetX * 0.5, offsetY * 0.5, offsetZ * 0.5)
    local dirX = math.abs(offsetX)
    local sizeZ = math.abs(offsetZ)
    local dirX, _, dirZ = localDirectionToWorld(startNode, 0, 0, 1)
    self:createFromPosAndDir(x, y, z, dirX, 0, dirZ, 0, 1, 0, dirX, sizeZ)
    return self
end
function DebugPlane:createSimple(x, y, z, size)
    self:createFromPosAndDir(x, y, z, 0, 0, 1, 0, 1, 0, size, size)
    return self
end
function DebugPlane:createWithSizeAndOffset(node, width, length, widthOffset, lengthOffset)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local x, y, z = getWorldTranslation(node)
    local x, y, z = MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, widthOffset, 0, lengthOffset)
    self:createFromPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, width, length)
    return self
end
function DebugPlane:createFromPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, width, length)
    local halfWidth = width * 0.5
    local halfLength = length * 0.5
    local pos = self.cornerPositions
    pos[1] = { MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -halfWidth, 0, -halfLength) }
    pos[2] = { MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -halfWidth, 0, halfLength) }
    pos[3] = { MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, halfWidth, 0, halfLength) }
    pos[4] = { MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, halfWidth, 0, -halfLength) }
    return self
end
function DebugPlane:createWithNode(node, sizeX, sizeZ)
    local sizeXHalf = sizeX * 0.5
    local sizeZHalf = sizeZ * 0.5
    local pos = self.cornerPositions
    pos[1] = { localToWorld(node, -sizeXHalf, 0, -sizeZHalf) }
    pos[2] = { localToWorld(node, -sizeXHalf, 0, sizeZHalf) }
    pos[3] = { localToWorld(node, sizeXHalf, 0, sizeZHalf) }
    pos[4] = { localToWorld(node, sizeXHalf, 0, -sizeZHalf) }
    return self
end
function DebugPlane:setIsFilled(isFilled)
    self.filled = isFilled
    return self
end