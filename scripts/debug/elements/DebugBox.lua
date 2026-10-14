DebugBox = {}
local DebugBox_mt = Class(DebugBox, DebugElement)
DebugBox.STATIC_CALL_POSITIONS_TABLE = {
    { -1, -1, -1 },
    { 1, -1, -1 },
    { 1, -1, 1 },
    { -1, -1, 1 },
    { -1, 1, -1 },
    { 1, 1, -1 },
    { 1, 1, 1 },
    { -1, 1, 1 }
}
function DebugBox.new(customMt)
    -- upvalues: (copy) DebugBox_mt
    local self = DebugBox:superClass().new(customMt or DebugBox_mt)
    self.upX = 0
    self.upY = 1
    self.upZ = 0
    self.dirX = 0
    self.dirY = 0
    self.dirZ = 1
    self.sizeX = 1
    self.sizeY = 1
    self.sizeZ = 1
    self.solid = true
    self.text = nil
    self.drawFaces = false
    self.cornerPositions = {
        { -1, -1, -1 },
        { 1, -1, -1 },
        { 1, -1, 1 },
        { -1, -1, 1 },
        { -1, 1, -1 },
        { 1, 1, -1 },
        { 1, 1, 1 },
        { -1, 1, 1 }
    }
    return self
end
function DebugBox:delete() end
function DebugBox:update(dt) end
function DebugBox:draw()
    DebugBox.renderAtPosition(self.x, self.y, self.z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ, self.color, self.solid, self.text, self.textSize, self.drawFaces, self.cornerPositions)
end
function DebugBox.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces, positions)
    local r = 1
    local g = 1
    local b = 1
    local a = 1
    if color ~= nil then
        r, g, b, a = color:unpack()
    end
    local pos = positions or DebugBox.calculateCornerPositions(DebugBox.STATIC_CALL_POSITIONS_TABLE, x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ)
    drawDebugLine(pos[1][1], pos[1][2], pos[1][3], r, g, b, pos[2][1], pos[2][2], pos[2][3], r, g, b, solid)
    drawDebugLine(pos[2][1], pos[2][2], pos[2][3], r, g, b, pos[3][1], pos[3][2], pos[3][3], r, g, b, solid)
    drawDebugLine(pos[3][1], pos[3][2], pos[3][3], r, g, b, pos[4][1], pos[4][2], pos[4][3], r, g, b, solid)
    drawDebugLine(pos[4][1], pos[4][2], pos[4][3], r, g, b, pos[1][1], pos[1][2], pos[1][3], r, g, b, solid)
    drawDebugLine(pos[5][1], pos[5][2], pos[5][3], r, g, b, pos[6][1], pos[6][2], pos[6][3], r, g, b, solid)
    drawDebugLine(pos[6][1], pos[6][2], pos[6][3], r, g, b, pos[7][1], pos[7][2], pos[7][3], r, g, b, solid)
    drawDebugLine(pos[7][1], pos[7][2], pos[7][3], r, g, b, pos[8][1], pos[8][2], pos[8][3], r, g, b, solid)
    drawDebugLine(pos[8][1], pos[8][2], pos[8][3], r, g, b, pos[5][1], pos[5][2], pos[5][3], r, g, b, solid)
    drawDebugLine(pos[1][1], pos[1][2], pos[1][3], r, g, b, pos[5][1], pos[5][2], pos[5][3], r, g, b, solid)
    drawDebugLine(pos[2][1], pos[2][2], pos[2][3], r, g, b, pos[6][1], pos[6][2], pos[6][3], r, g, b, solid)
    drawDebugLine(pos[3][1], pos[3][2], pos[3][3], r, g, b, pos[7][1], pos[7][2], pos[7][3], r, g, b, solid)
    drawDebugLine(pos[4][1], pos[4][2], pos[4][3], r, g, b, pos[8][1], pos[8][2], pos[8][3], r, g, b, solid)
    if drawFaces then
        drawDebugTriangle(pos[1][1], pos[1][2], pos[1][3], pos[2][1], pos[2][2], pos[2][3], pos[3][1], pos[3][2], pos[3][3], r, g, b, 0.1, solid)
        drawDebugTriangle(pos[1][1], pos[1][2], pos[1][3], pos[3][1], pos[3][2], pos[3][3], pos[4][1], pos[4][2], pos[4][3], r, g, b, 0.1, solid)
        drawDebugTriangle(pos[7][1], pos[7][2], pos[7][3], pos[6][1], pos[6][2], pos[6][3], pos[5][1], pos[5][2], pos[5][3], r, g, b, 0.2, solid)
        drawDebugTriangle(pos[7][1], pos[7][2], pos[7][3], pos[5][1], pos[5][2], pos[5][3], pos[8][1], pos[8][2], pos[8][3], r, g, b, 0.2, solid)
        drawDebugTriangle(pos[1][1], pos[1][2], pos[1][3], pos[5][1], pos[5][2], pos[5][3], pos[2][1], pos[2][2], pos[2][3], r, g, b, 0.3, solid)
        drawDebugTriangle(pos[2][1], pos[2][2], pos[2][3], pos[5][1], pos[5][2], pos[5][3], pos[6][1], pos[6][2], pos[6][3], r, g, b, 0.3, solid)
        drawDebugTriangle(pos[3][1], pos[3][2], pos[3][3], pos[8][1], pos[8][2], pos[8][3], pos[4][1], pos[4][2], pos[4][3], r, g, b, 0.4, solid)
        drawDebugTriangle(pos[3][1], pos[3][2], pos[3][3], pos[7][1], pos[7][2], pos[7][3], pos[8][1], pos[8][2], pos[8][3], r, g, b, 0.4, solid)
        drawDebugTriangle(pos[1][1], pos[1][2], pos[1][3], pos[4][1], pos[4][2], pos[4][3], pos[8][1], pos[8][2], pos[8][3], r, g, b, 0.5, solid)
        drawDebugTriangle(pos[1][1], pos[1][2], pos[1][3], pos[8][1], pos[8][2], pos[8][3], pos[5][1], pos[5][2], pos[5][3], r, g, b, 0.5, solid)
        drawDebugTriangle(pos[2][1], pos[2][2], pos[2][3], pos[6][1], pos[6][2], pos[6][3], pos[7][1], pos[7][2], pos[7][3], r, g, b, 0.6, solid)
        drawDebugTriangle(pos[2][1], pos[2][2], pos[2][3], pos[7][1], pos[7][2], pos[7][3], pos[3][1], pos[3][2], pos[3][3], r, g, b, 0.6, solid)
    end
    local normX, normY, normZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
    drawDebugLine(x, y, z, 1, 0, 0, x + normX, y + normY, z + normZ, 1, 0, 0, solid)
    drawDebugLine(x, y, z, 0, 1, 0, x + upX, y + upY, z + upZ, 0, 1, 0, solid)
    drawDebugLine(x, y, z, 0, 0, 1, x + dirX, y + dirY, z + dirZ, 0, 0, 1, solid)
    if text ~= nil then
        Utils.renderTextAtWorldPosition(x + 0.5 * upX, y + 0.5 * upY, z + 0.5 * upZ, text, textSize or 0.016, nil, r, g, b, a)
    end
end
function DebugBox.renderAtNode(node, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
    local x, y, z = getWorldTranslation(node)
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugBox.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end
function DebugBox.renderAtNodeWithOffset(node, offsetX, offsetY, offsetZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
    local x, y, z = localToWorld(node, offsetX, offsetY, offsetZ)
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugBox.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end
function DebugBox.renderWithStartAndEndNode(nodeStart, nodeEnd, color, solid, text, textSize, drawFaces)
    local offsetX, offsetY, offsetZ = localToLocal(nodeEnd, nodeStart, 0, 0, 0)
    local x, y, z = localToWorld(nodeStart, offsetX * 0.5, offsetY * 0.5, offsetZ * 0.5)
    local dirX = math.abs(offsetX)
    local dirX = math.abs(offsetY)
    local sizeZ = math.abs(offsetZ)
    local dirX, dirY, dirZ = localDirectionToWorld(nodeStart, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(nodeStart, 0, 1, 0)
    DebugBox.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, dirX / 2, dirX / 2, sizeZ / 2, color, solid, text, textSize, drawFaces)
end
function DebugBox.calculateCornerPositions(positions, x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ)
    local normX, normY, normZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
    sizeX = (sizeX or 1) / 2
    sizeY = (sizeY or 1) / 2
    sizeZ = (sizeZ or 1) / 2
    if sizeX ~= nil then
    end
    positions[1][1] = x - normX - upX - dirX
    positions[1][2] = y - normY - upY - dirY
    positions[1][3] = z - normZ - upZ - dirZ
    positions[2][1] = x + normX - upX - dirX
    positions[2][2] = y + normY - upY - dirY
    positions[2][3] = z + normZ - upZ - dirZ
    positions[3][1] = x + normX - upX + dirX
    positions[3][2] = y + normY - upY + dirY
    positions[3][3] = z + normZ - upZ + dirZ
    positions[4][1] = x - normX - upX + dirX
    positions[4][2] = y - normY - upY + dirY
    positions[4][3] = z - normZ - upZ + dirZ
    positions[5][1] = x - normX + upX - dirX
    positions[5][2] = y - normY + upY - dirY
    positions[5][3] = z - normZ + upZ - dirZ
    positions[6][1] = x + normX + upX - dirX
    positions[6][2] = y + normY + upY - dirY
    positions[6][3] = z + normZ + upZ - dirZ
    positions[7][1] = x + normX + upX + dirX
    positions[7][2] = y + normY + upY + dirY
    positions[7][3] = z + normZ + upZ + dirZ
    positions[8][1] = x - normX + upX + dirX
    positions[8][2] = y - normY + upY + dirY
    positions[8][3] = z - normZ + upZ + dirZ
    return positions
end
function DebugBox:createWithWorldPos(x, y, z, size)
    self:createWithWorldPosAndRot(x, y, z, 0, 0, 0, size, size, size)
    return self
end
function DebugBox:createWithStartEnd(startNode, endNode)
    local offsetX, offsetY, offsetZ = localToLocal(endNode, startNode, 0, 0, 0)
    local x, y, z = localToWorld(startNode, offsetX * 0.5, offsetY * 0.5, offsetZ * 0.5)
    local dirX = math.abs(offsetX)
    local dirX = math.abs(offsetY)
    local sizeZ = math.abs(offsetZ)
    local dirX, _, dirZ = localDirectionToWorld(startNode, 0, 0, 1)
    self:createWithWorldPosAndRot(x, y, z, 0, MathUtil.getYRotationFromDirection(dirX, dirZ), 0, dirX * 0.5, dirX * 0.5, sizeZ * 0.5)
    return self
end
function DebugBox:createWithNode(node, sizeX, sizeY, sizeZ, offsetX, offsetY, offsetZ)
    local x, y, z = localToWorld(node, offsetX or 0, offsetY or 0, offsetZ or 0)
    self.x = x
    self.y = y
    self.z = z
    self.sizeX = sizeX or self.sizeX
    self.sizeY = sizeY or self.sizeY
    self.sizeZ = sizeZ or self.sizeZ
    self.upX, self.upY, self.upZ = localDirectionToWorld(node, 0, 1, 0)
    self.dirX, self.dirY, self.dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugBox.calculateCornerPositions(self.cornerPositions, x, y, z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ)
    return self
end
function DebugBox:createWithPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, sizeX, sizeY, sizeZ)
    self.x = x
    self.y = y
    self.z = z
    self.dirX, self.dirY, self.dirZ = MathUtil.vector3Normalize(dirX, dirY, dirZ)
    self.upX, self.upY, self.upZ = MathUtil.vector3Normalize(upX, upY, upZ)
    self.sizeX = sizeX or self.sizeX
    self.sizeY = sizeY or self.sizeY
    self.sizeZ = sizeZ or self.sizeZ
    DebugBox.calculateCornerPositions(self.cornerPositions, x, y, z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ)
    return self
end
function DebugBox:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, sizeX, sizeY, sizeZ)
    local temp = createTransformGroup("temp_drawDebugBoxAtWorldPos")
    link(getRootNode(), temp)
    setTranslation(temp, x, y, z)
    setRotation(temp, rotX, rotY, rotZ)
    self:createWithNode(temp, sizeX, sizeY, sizeZ)
    delete(temp)
    return self
end
function DebugBox:createFromOverlapBoxParameters(x, y, z, rotX, rotY, rotZ, extentX, extentY, extentZ)
    local temp = createTransformGroup("temp_drawDebugBoxAtWorldPos")
    link(getRootNode(), temp)
    setTranslation(temp, x, y, z)
    setRotation(temp, rotX, rotY, rotZ)
    self:createWithNode(temp, extentX * 2, extentY * 2, extentZ * 2)
    delete(temp)
    return self
end
function DebugBox:setSize(sizeX, sizeY, sizeZ)
    self.sizeX = sizeX or self.sizeX
    self.sizeY = sizeY or self.sizeY
    self.sizeZ = sizeZ or self.sizeZ
    DebugBox.calculateCornerPositions(self.cornerPositions, self.x, self.y, self.z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ)
    return self
end
function DebugBox:setDrawFaces(drawFaces)
    self.drawFaces = drawFaces
    return self
end