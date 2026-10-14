DebugPyramid = {}
local DebugPyramid_mt = Class(DebugPyramid, DebugBox)
DebugPyramid.STATIC_CALL_POSITIONS_TABLE = {
    Vector3.new(-0.5, -0.5, -0.5),
    Vector3.new(0.5, -0.5, -0.5),
    Vector3.new(0.5, -0.5, 0.5),
    Vector3.new(-0.5, -0.5, 0.5),
    Vector3.new(0, 0.5, 0)
}
function DebugPyramid.new(customMt)
    -- upvalues: (copy) DebugPyramid_mt
    local self = DebugPyramid:superClass().new(customMt or DebugPyramid_mt)
    self.cornerPositions = nil
    return self
end
function DebugPyramid:draw()
    DebugPyramid.renderAtPosition(self.x, self.y, self.z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ, self.color, self.solid, self.text, self.textSize, self.drawFaces, self.cornerPositions)
end
function DebugPyramid.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces, positions)
    local r = 1
    local g = 1
    local b = 1
    local a = 1
    if color ~= nil then
        r, g, b, a = color:unpack()
    end
    solid = solid == nil and true or solid
    local pos = positions or DebugPyramid.STATIC_CALL_POSITIONS_TABLE
    if x == nil or (y == nil or z == nil) then
        offset = vector.zero
    else
        offset = vector.create(x, y, z)
    end
    local sx = (sizeX == nil or not sizeX) and 1 or sizeX
    local sy = (sizeY == nil or not sizeY) and 1 or sizeY
    local sz = (sizeZ == nil or not sizeZ) and 1 or sizeZ
    local dirNx, dirNy, dirNz = MathUtil.vector3Normalize(dirX, dirY, dirZ)
    local normX, normY, normZ = MathUtil.crossProduct(upX, upY, upZ, dirNx, dirNy, dirNz)
    local upNx, upNy, upNz = MathUtil.vector3Normalize(normX, normY, normZ)
    local upNx, upNy, upNz = MathUtil.crossProduct(dirNx, dirNy, dirNz, upNx, upNy, upNz)
    local norSx, norSy, norSz = MathUtil.vector3Normalize(upNx, upNy, upNz)
    local norSx = upNx * sx
    local norSy = upNy * sx
    local norSz = upNz * sx
    local upSx = norSx * sy
    local upSy = norSy * sy
    local upSz = norSz * sy
    local dirSx = dirNx * sz
    local dirSy = dirNy * sz
    local dirSz = dirNz * sz
    local offset
    local function toWorld(p)
        -- upvalues: (ref) offset, (copy) norSx, (copy) upSx, (copy) dirSx, (copy) norSy, (copy) upSy, (copy) dirSy, (copy) norSz, (copy) upSz, (copy) dirSz
        return vector.create(offset.x + p.x * norSx + p.y * upSx + p.z * dirSx, offset.y + p.x * norSy + p.y * upSy + p.z * dirSy, offset.z + p.x * norSz + p.y * upSz + p.z * dirSz)
    end
    local point01 = toWorld(pos[1])
    local point02 = toWorld(pos[2])
    local point03 = toWorld(pos[3])
    local point04 = toWorld(pos[4])
    local point05 = toWorld(pos[5])
    drawDebugLineVector(point01, r, g, b, point02, r, g, b, solid)
    drawDebugLineVector(point02, r, g, b, point03, r, g, b, solid)
    drawDebugLineVector(point03, r, g, b, point04, r, g, b, solid)
    drawDebugLineVector(point04, r, g, b, point01, r, g, b, solid)
    drawDebugLineVector(point01, r, g, b, point05, r, g, b, solid)
    drawDebugLineVector(point02, r, g, b, point05, r, g, b, solid)
    drawDebugLineVector(point03, r, g, b, point05, r, g, b, solid)
    drawDebugLineVector(point04, r, g, b, point05, r, g, b, solid)
    if drawFaces then
        drawDebugTriangleVector(point01, point02, point03, r, g, b, 0.1, solid)
        drawDebugTriangleVector(point01, point03, point04, r, g, b, 0.1, solid)
        drawDebugTriangleVector(point01, point05, point02, r, g, b, 0.3, solid)
        drawDebugTriangleVector(point02, point05, point03, r, g, b, 0.5, solid)
        drawDebugTriangleVector(point03, point05, point04, r, g, b, 0.4, solid)
        drawDebugTriangleVector(point04, point05, point01, r, g, b, 0.7, solid)
    end
    drawDebugLineVector(offset, 1, 0, 0, offset + (point02 - point01), 1, 0, 0, solid)
    drawDebugLineVector(offset, 0, 1, 0, point05, 0, 1, 0, solid)
    drawDebugLineVector(offset, 0, 0, 1, offset + (point04 - point01), 0, 0, 1, solid)
    if text ~= nil then
        Utils.renderTextAtWorldPosition(point05.x, point05.y, point05.z, text, textSize or 0.016, nil, r, g, b, a)
    end
end
function DebugPyramid.renderAtNode(node, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
    local x, y, z = getWorldTranslation(node)
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugPyramid.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end
function DebugPyramid.renderAtNodeWithOffset(node, offsetX, offsetY, offsetZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
    local x, y, z = localToWorld(node, offsetX, offsetY, offsetZ)
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugPyramid.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end
function DebugPyramid.renderWithStartAndEndNode(nodeStart, nodeEnd, color, solid, text, textSize, drawFaces)
    local offsetX, offsetY, offsetZ = localToLocal(nodeEnd, nodeStart, 0, 0, 0)
    local x, y, z = localToWorld(nodeStart, offsetX * 0.5, offsetY * 0.5, offsetZ * 0.5)
    local dirX = math.abs(offsetX)
    local dirX = math.abs(offsetY)
    local sizeZ = math.abs(offsetZ)
    local dirX, dirY, dirZ = localDirectionToWorld(nodeStart, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(nodeStart, 0, 1, 0)
    DebugPyramid.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, dirX / 2, dirX / 2, sizeZ / 2, color, solid, text, textSize, drawFaces)
end