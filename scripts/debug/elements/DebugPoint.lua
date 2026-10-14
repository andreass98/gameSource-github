DebugPoint = {}
local DebugPoint_mt = Class(DebugPoint, DebugElement)
function DebugPoint.new(customMt)
    -- upvalues: (copy) DebugPoint_mt
    local self = DebugPoint:superClass().new(customMt or DebugPoint_mt)
    self.solid = false
    self.alignToGround = false
    self.text = nil
    return self
end
function DebugPoint:draw()
    DebugPoint.renderAtPosition(self.x, self.y, self.z, self.color, self.solid, self.text, self.textSize, self.clipDistance, self.textClipDistance)
end
function DebugPoint.renderAtPosition(x, y, z, color, solid, text, textSize, clipDistance, textClipDistance)
    if y == nil then
        if g_terrainNode == nil then
            return
        end
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.01
    end
    if clipDistance == nil or DebugUtil.isPositionInCameraRange(x, y, z, clipDistance) then
        local r, g, b, a = (color or Color.PRESETS.WHITE):unpack()
        drawDebugPoint(x, y, z, r, g, b, a, solid)
        if text ~= nil and (textClipDistance == nil or DebugUtil.isPositionInCameraRange(x, y, z, textClipDistance)) then
            Utils.renderTextAtWorldPosition(x, y, z, text, textSize or 0.016, 0.005, r, g, b, a)
        end
    end
end
function DebugPoint.renderAtNode(node, offsets, color, solid, text, textSize, clipDistance, textClipDistance)
    local x, y, z = getWorldTranslation(node)
    if offsets ~= nil then
    end
    DebugPoint.renderAtPosition(x, y, z, color, solid, text, textSize, clipDistance, textClipDistance)
end
function DebugPoint:createWithNode(node, alignToGround, solid, clipDistance)
    local x, y, z = getWorldTranslation(node)
    self:createWithWorldPos(x, y, z, alignToGround, solid, clipDistance)
    return self
end
function DebugPoint:createWithWorldPos(x, y, z, alignToGround, solid, clipDistance)
    if alignToGround and g_terrainNode ~= nil then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
    end
    self.x = x
    self.y = y
    self.z = z
    self.solid = Utils.getNoNil(solid, self.solid)
    self.clipDistance = Utils.getNoNil(clipDistance, self.clipDistance)
    return self
end