DebugCircle = {}
local DebugCircle_mt = Class(DebugCircle, DebugElement)
function DebugCircle.new(customMt)
    -- upvalues: (copy) DebugCircle_mt
    local self = DebugCircle:superClass().new(customMt or DebugCircle_mt)
    self.radius = 1
    self.numSegments = 16
    self.solid = false
    self.alignToGround = false
    self.drawSectors = false
    self.text = nil
    return self
end
function DebugCircle:draw()
    DebugCircle.renderAtPosition(self.x, not self.alignToGround and self.y or nil, self.z, self.radius, self.color, self.numSegments, self.solid, self.filled, self.drawSectors, self.text)
end
function DebugCircle.renderAtNode(node, offsets, radius, color, numSegments, solid, alignToGround, filled, drawSectors, text)
    local x, y, z = getWorldTranslation(node)
    if offsets ~= nil then
    end
    if alignToGround then
        y = nil
    end
    DebugCircle.renderAtPosition(x, y, z, radius, color, numSegments, solid, filled, drawSectors, text)
end
function DebugCircle.renderAtPosition(x, y, z, radius, color, numSegments, solid, filled, drawSectors, text)
    local r = 1
    local g = 1
    local b = 1
    local a = 1
    if color ~= nil then
        r, g, b, a = color:unpack()
    end
    local alignToTerrain = y ~= nil
    if not alignToTerrain or g_terrainNode ~= nil then
        numSegments = numSegments or 16
        local i = 1
        for i = i, numSegments do
            local a1 = (i - 1) / numSegments * 2 * 3.141592653589793
            local a2 = i / numSegments * 2 * 3.141592653589793
            local c = math.cos(a1) * radius
            local s = math.sin(a1) * radius
            local x1 = x + c
            local z1 = z + s
            local c = math.cos(a2) * radius
            local s = math.sin(a2) * radius
            local x2 = x + c
            local z2 = z + s
            local y1, y2
            if alignToTerrain then
                y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + 0.05
                y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + 0.05
            else
                y2 = y
                y1 = y2
                y2 = y1
            end
            drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, solid)
            if filled then
                drawDebugTriangle(x, y, z, x1, y1, z1, x2, y2, z2, r, g, b, 0.5, solid)
                drawDebugTriangle(x1, y1, z1, x, y, z, x2, y2, z2, r, g, b, 0.5, solid)
                drawDebugTriangle(x1, y1, z1, x2, y2, z2, x, y, z, r, g, b, 0.5, solid)
                drawDebugTriangle(x2, y2, z2, x, y, z, x1, y1, z1, r, g, b, 0.5, solid)
            end
            if drawSectors then
                if alignToTerrain then
                    y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.05
                end
                drawDebugLine(x, y, z, r, g, b, x1, y1, z1, r, g, b, solid)
            end
        end
        if text ~= nil then
            if y == nil then
                y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.05
            end
            Utils.renderTextAtWorldPosition(x, y, z, text, 0.02, 0.01, r, g, b, a)
        end
    end
end
function DebugCircle:createWithNode(node, radius, color, numSegments, solid, alignToGround, filled, drawSectors)
    local x, y, z = getWorldTranslation(node)
    self:createWithWorldPos(x, y, z, radius, color, numSegments, solid, alignToGround, filled, drawSectors)
    return self
end
function DebugCircle:createWithWorldPos(x, y, z, radius, color, numSegments, solid, alignToGround, filled, drawSectors)
    self.x = x
    self.y = y
    self.z = z
    self.radius = radius
    self.color = color or self.color
    self.numSegments = numSegments or self.numSegments
    self.solid = Utils.getNoNil(solid, self.solid)
    self.alignToGround = Utils.getNoNil(alignToGround, self.alignToGround)
    self.filled = Utils.getNoNil(filled, self.filled)
    self.drawSectors = Utils.getNoNil(drawSectors, self.drawSectors)
    return self
end