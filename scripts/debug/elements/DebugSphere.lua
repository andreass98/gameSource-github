DebugSphere = {}
local DebugSphere_mt = Class(DebugSphere, DebugElement)
function DebugSphere.new(customMt)
    -- upvalues: (copy) DebugSphere_mt
    local self = DebugSphere:superClass().new(customMt or DebugSphere_mt)
    self.radius = 1
    self.numSegments = 16
    self.solid = false
    self.alignToGround = false
    self.text = nil
    return self
end
function DebugSphere:delete() end
function DebugSphere:draw()
    DebugSphere.renderAtPosition(self.x, self.y, self.z, self.radius, self.color, self.numSegments, self.solid, self.alignToGround, self.text, self.textSize)
end
function DebugSphere.renderAtPosition(x, y, z, radius, color, numSegments, solid, alignToGround, text, textSize)
    numSegments = numSegments or 16
    if alignToGround and g_terrainNode ~= nil then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z) + 0.05
    end
    local r, g, b, a = (color or Color.PRESETS.WHITE):unpack()
    local i = 1
    for i = i, numSegments do
        local a1 = (i - 1) / numSegments * 2 * 3.141592653589793
        local a2 = i / numSegments * 2 * 3.141592653589793
        local c1 = math.cos(a1) * radius
        local s1 = math.sin(a1) * radius
        local c2 = math.cos(a2) * radius
        local s2 = math.sin(a2) * radius
        drawDebugLine(x + c1, y, z + s1, r, g, b, x + c2, y, z + s2, r, g, b, solid)
        drawDebugLine(x + c1, y + s1, z, r, g, b, x + c2, y + s2, z, r, g, b, solid)
        drawDebugLine(x, y + s1, z + c1, r, g, b, x, y + s2, z + c2, r, g, b, solid)
    end
    drawDebugPoint(x, y, z, r, g, b, 1, solid)
    if text ~= nil then
        Utils.renderTextAtWorldPosition(x, y, z, text, textSize or 0.016, 0.005, r, g, b, a)
    end
end
function DebugSphere.renderAtNode(node, offsets, radius, color, numSegments, solid, alignToGround, text, textSize)
    local x, y, z = getWorldTranslation(node)
    if alignToGround then
        y = nil
    elseif offsets ~= nil then
    end
    DebugSphere.renderAtPosition(x, y, z, radius, color, numSegments, solid, alignToGround, text, textSize)
end
function DebugSphere.renderShapeBoundingSphere(shape, color, numSegments, solid, text, textSize)
    if getHasClassId(shape, ClassIds.SHAPE) then
        local x, y, z, bvRadius = getShapeWorldBoundingSphere(shape)
        DebugSphere.renderAtPosition(x, y, z, bvRadius, color, numSegments, solid, false, text, textSize)
    end
end
function DebugSphere:createWithNode(node, radius, color, numSegments, solid, alignToGround)
    local x, y, z = getWorldTranslation(node)
    self:createWithWorldPos(x, y, z, radius, color, numSegments, solid, alignToGround)
    return self
end
function DebugSphere:createShapeBoundingSphere(node, color, numSegments, solid)
    if not getHasClassId(node, ClassIds.SHAPE) then
        Logging.error("DebugSphere:createShapeBoundingSphere(): node \'%s\' is not a shape", getName(node))
        return self
    end
    local x, y, z, bvRadius = getShapeWorldBoundingSphere(node)
    self:createWithWorldPos(x, y, z, bvRadius, color, numSegments, solid, false, (string.format("\'%s\' (id=%d)\nBV", getName(node), node)))
    return self
end
function DebugSphere:createWithWorldPos(x, y, z, radius, color, numSegments, solid, alignToGround, text)
    self.x = x
    self.y = y
    self.z = z
    self.radius = radius
    self.color = color or self.color
    self.numSegments = numSegments or self.numSegments
    self.solid = Utils.getNoNil(solid, self.solid)
    self.alignToGround = Utils.getNoNil(alignToGround, self.alignToGround)
    self.text = text or self.text
    return self
end