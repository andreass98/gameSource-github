DebugCamera = {}
local DebugCamera_mt = Class(DebugCamera, DebugElement)
function DebugCamera.new(customMt)
    -- upvalues: (copy) DebugCamera_mt
    local self = DebugCamera:superClass().new(customMt or DebugCamera_mt)
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
    return self
end
function DebugCamera:draw()
    DebugCamera.renderAtPosition(self.x, self.y, self.z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ, self.color, self.solid, self.text, self.textSize, self.drawFaces)
end
function DebugCamera.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
    local sx = (sizeX == nil or not sizeX) and 1 or sizeX
    local sy = (sizeY == nil or not sizeY) and 1 or sizeY
    local sz = (sizeZ == nil or not sizeZ) and 1 or sizeZ
    local bodyShift = -sy * 0.5
    local bodyCenterX = x + dirX * bodyShift
    local bodyCenterY = y + dirY * bodyShift
    local bodyCenterZ = z + dirZ * bodyShift
    DebugGizmo.renderAtPosition(x, y, z, 0, 0, 1, 0, 1, 0)
    DebugBox.renderAtPosition(bodyCenterX, bodyCenterY, bodyCenterZ, upX, upY, upZ, dirX, dirY, dirZ, sx, sy, sz, color, solid, text, textSize, drawFaces)
    local lensOffset = sz * 0.5
    DebugPyramid.renderAtPosition(x + dirX * lensOffset, y + dirY * lensOffset, z + dirZ * lensOffset, -dirX, -dirY, -dirZ, upX, upY, upZ, sx, sy, sz, color, solid, text, textSize, drawFaces)
    local reelRadius = sy * 0.3
    local reelHeight = sx * 0.4
    local reelStackOffset = sy * 0.5 + reelRadius
    local reelAlongDir = sz * 0.25
    local stackX = upX * reelStackOffset
    local stackY = upY * reelStackOffset
    local stackZ = upZ * reelStackOffset
    DebugCylinder.renderAtPosition(bodyCenterX + stackX + dirX * reelAlongDir, bodyCenterY + stackY + dirY * reelAlongDir, bodyCenterZ + stackZ + dirZ * reelAlongDir, reelRadius, reelHeight, Axis.X, color)
    DebugCylinder.renderAtPosition(bodyCenterX + stackX - dirX * reelAlongDir, bodyCenterY + stackY - dirY * reelAlongDir, bodyCenterZ + stackZ - dirZ * reelAlongDir, reelRadius, reelHeight, Axis.X, color)
end
function DebugCamera.renderAtNode(node, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
    local x, y, z = getWorldTranslation(node)
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugCamera.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end
function DebugCamera.renderAtNodeWithOffset(node, offsetX, offsetY, offsetZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
    local x, y, z = localToWorld(node, offsetX, offsetY, offsetZ)
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugCamera.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end
function DebugCamera.renderWithStartAndEndNode(nodeStart, nodeEnd, color, solid, text, textSize, drawFaces)
    local offsetX, offsetY, offsetZ = localToLocal(nodeEnd, nodeStart, 0, 0, 0)
    local x, y, z = localToWorld(nodeStart, offsetX * 0.5, offsetY * 0.5, offsetZ * 0.5)
    local dirX = math.abs(offsetX)
    local dirX = math.abs(offsetY)
    local sizeZ = math.abs(offsetZ)
    local dirX, dirY, dirZ = localDirectionToWorld(nodeStart, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(nodeStart, 0, 1, 0)
    DebugCamera.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, dirX / 2, dirX / 2, sizeZ / 2, color, solid, text, textSize, drawFaces)
end