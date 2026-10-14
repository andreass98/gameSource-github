DebugCylinder = {}
local DebugCylinder_mt = Class(DebugCylinder, DebugElement)
function DebugCylinder.new(customMt)
    -- upvalues: (copy) DebugCylinder_mt
    local self = DebugCylinder:superClass().new(customMt or DebugCylinder_mt)
    self.radius = 1
    self.height = 1
    self.axis = Axis.Y
    self.numSegments = 16
    self.solid = false
    self.alignToGround = false
    self.text = nil
    return self
end
function DebugCylinder:delete() end
function DebugCylinder:draw()
    DebugCylinder.renderAtPosition(self.x, self.y, self.z, self.radius, self.height, self.axis, self.color, self.numSegments, self.solid, self.alignToGround, self.text)
end
function DebugCylinder.renderAtPosition(x, y, z, radius, height, axis, color, numSegments, solid, alignToGround, text)
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
        if axis == Axis.Y then
            local x1 = x + c1
            local z1 = z + s1
            local x2 = x + c2
            local z2 = z + s2
            drawDebugLine(x1, y - height * 0.5, z1, r, g, b, x2, y - height * 0.5, z2, r, g, b)
            drawDebugLine(x1, y + height * 0.5, z1, r, g, b, x2, y + height * 0.5, z2, r, g, b)
            drawDebugLine(x1, y - height * 0.5, z1, r, g, b, x1, y + height * 0.5, z1, r, g, b)
            drawDebugLine(x2, y - height * 0.5, z2, r, g, b, x2, y + height * 0.5, z2, r, g, b)
        elseif axis == Axis.X then
            local y1 = y + c1
            local z1 = z + s1
            local y2 = y + c2
            local z2 = z + s2
            drawDebugLine(x - height * 0.5, y1, z1, r, g, b, x - height * 0.5, y2, z2, r, g, b)
            drawDebugLine(x + height * 0.5, y1, z1, r, g, b, x + height * 0.5, y2, z2, r, g, b)
            drawDebugLine(x - height * 0.5, y1, z1, r, g, b, x + height * 0.5, y1, z1, r, g, b)
            drawDebugLine(x - height * 0.5, y2, z2, r, g, b, x + height * 0.5, y2, z2, r, g, b)
        elseif axis == Axis.Z then
            local x1 = x + c1
            local y1 = y + s1
            local x2 = x + c2
            local y2 = y + s2
            drawDebugLine(x1, y1, z - height * 0.5, r, g, b, x2, y2, z - height * 0.5, r, g, b)
            drawDebugLine(x1, y1, z + height * 0.5, r, g, b, x2, y2, z + height * 0.5, r, g, b)
            drawDebugLine(x1, y1, z - height * 0.5, r, g, b, x1, y1, z + height * 0.5, r, g, b)
            drawDebugLine(x2, y2, z - height * 0.5, r, g, b, x2, y2, z + height * 0.5, r, g, b)
        end
        DebugGizmo.renderAtPosition(x, y, z, 0, 0, 1, 0, 1, 0)
    end
    drawDebugPoint(x, y, z, r, g, b, 1, solid)
    if text ~= nil then
        Utils.renderTextAtWorldPosition(x, y, z, text, 0.02, 0.005, r, g, b, a)
    end
end
function DebugCylinder.renderAtNode(node, offsets, radius, height, axis, color, numSegments, solid, alignToGround, text)
    local x, y, z = getWorldTranslation(node)
    if alignToGround then
        y = nil
    elseif offsets ~= nil then
    end
    DebugCylinder.renderAtPosition(x, y, z, radius, height, axis, color, numSegments, solid, alignToGround, text)
end
function DebugCylinder:createWithNode(node, radius, height, axis, color, numSegments, solid, alignToGround)
    local x, y, z = getWorldTranslation(node)
    self:createWithWorldPos(x, y, z, radius, height, axis, color, numSegments, solid, alignToGround)
    return self
end
function DebugCylinder:createWithWorldPos(x, y, z, radius, height, axis, color, numSegments, solid, alignToGround, text)
    self.x = x
    self.y = y
    self.z = z
    self.radius = radius
    self.height = height
    self.axis = axis or Axis.Y
    self.color = color or self.color
    self.numSegments = numSegments or self.numSegments
    self.solid = Utils.getNoNil(solid, self.solid)
    self.alignToGround = Utils.getNoNil(alignToGround, self.alignToGround)
    self.text = text or self.text
    return self
end