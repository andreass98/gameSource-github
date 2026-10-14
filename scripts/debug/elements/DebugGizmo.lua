DebugGizmo = {}
DebugGizmo.SCALE_DEFAULT = 0.5
local DebugGizmo_mt = Class(DebugGizmo, DebugElement)
function DebugGizmo.new(customMt)
    -- upvalues: (copy) DebugGizmo_mt
    local self = DebugGizmo:superClass().new(customMt or DebugGizmo_mt)
    self.dirX = 0
    self.dirY = 0
    self.dirZ = 1
    self.upX = 0
    self.upY = 1
    self.upZ = 0
    self.scale = DebugGizmo.SCALE_DEFAULT
    self.solid = true
    self.textOffsets = nil
    self.textColor = nil
    self.textSize = getCorrectTextSize(0.012)
    self.alignToGround = false
    self.hideWhenGuiIsOpen = false
    return self
end
function DebugGizmo:delete() end
function DebugGizmo:update(dt) end
function DebugGizmo:getShouldBeDrawn()
    if self.hideWhenGuiIsOpen and g_gui:getIsGuiVisible() then
        return false
    else
        return (not self.clipDistance or DebugUtil.isPositionInCameraRange(self.x, self.y, self.z, self.clipDistance)) and true or false
    end
end
function DebugGizmo:draw()
    DebugGizmo.renderAtPosition(self.x, self.y, self.z, self.dirX, self.dirY, self.dirZ, self.upX, self.upY, self.upZ, self.text, self.solid, self.scale, self.textSize, self.textColor, self.textOffsets)
end
function DebugGizmo.renderAtPosition(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, solid, scale, textSize, textColor, textOffsets)
    local normX, normY, normZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
    scale = scale or DebugGizmo.SCALE_DEFAULT
    if y == nil then
        if g_terrainNode == nil then
            return
        end
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.01
    end
    drawDebugLine(x, y, z, 1, 0, 0, x + scale * normX, y + scale * normY, z + scale * normZ, 1, 0, 0, solid)
    drawDebugLine(x, y, z, 0, 1, 0, x + scale * upX, y + scale * upY, z + scale * upZ, 0, 1, 0, solid)
    drawDebugLine(x, y, z, 0, 0, 1, x + scale * dirX, y + scale * dirY, z + scale * dirZ, 0, 0, 1, solid)
    if text ~= nil then
        textSize = textSize or getCorrectTextSize(0.012)
        if textOffsets ~= nil then
        end
        Utils.renderTextAtWorldPosition(x, y, z, text, textSize, 0, (textColor or Color.PRESETS.WHITE):unpack())
    end
end
function DebugGizmo.renderAtPositionSimple(x, y, z, text, solid, scale, textSize, textColor, textOffsets)
    DebugGizmo.renderAtPosition(x, y, z, 0, 0, 1, 0, 1, 0, text, solid, scale, textSize, textColor, textOffsets)
end
function DebugGizmo.renderAtNode(node, text, solid, scale, alignToGround, textSize, textColor, textOffsets)
    local x, y, z = getWorldTranslation(node)
    if alignToGround and g_terrainNode ~= nil then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.01
    end
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugGizmo.renderAtPosition(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, solid, scale, textSize, textColor, textOffsets)
end
function DebugGizmo.renderAtNodeWithOffset(node, offsetX, offsetY, offsetZ, text, solid, scale, alignToGround, textSize, textColor, textOffsets)
    local x, y, z = getWorldTranslation(node)
    local x = x + (offsetX or 0)
    local y = y + (offsetY or 0)
    local z = z + (offsetZ or 0)
    if alignToGround and g_terrainNode ~= nil then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.01
    end
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugGizmo.renderAtPosition(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, solid, scale, textSize, textColor, textOffsets)
end
function DebugGizmo.renderAtNodeWithLocalOffset(node, offsetX, offsetY, offsetZ, text, solid, scale, alignToGround, textSize, textColor, textOffsets)
    local x, y, z = localToWorld(node, offsetX or 0, offsetY or 0, offsetZ or 0)
    if alignToGround and g_terrainNode ~= nil then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.01
    end
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    DebugGizmo.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, text, solid, scale, textSize, textColor, textOffsets)
end
function DebugGizmo:createWithNode(node, text, alignToGround, textOffsets, scale, solid)
    local x, y, z = getWorldTranslation(node)
    local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
    local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
    self:createWithWorldPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround, textOffsets, scale, solid)
    return self
end
function DebugGizmo:createWithWorldPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround, textOffsets, scale, solid)
    if alignToGround and g_terrainNode ~= nil then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
    end
    self.x = x
    self.y = y
    self.z = z
    self.dirX = dirX
    self.dirY = dirY
    self.dirZ = dirZ
    self.upX = upX
    self.upY = upY
    self.upZ = upZ
    self.text = text and tostring(text) or nil
    self.scale = scale or self.scale
    self.solid = Utils.getNoNil(solid, self.solid)
    if textOffsets ~= nil then
        self.textOffsets = textOffsets
    end
    self.alignToGround = Utils.getNoNil(alignToGround, self.alignToGround)
    return self
end