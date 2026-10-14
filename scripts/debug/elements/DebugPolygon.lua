DebugPolygon = {}
local DebugPolygon_mt = Class(DebugPolygon, DebugElement)
function DebugPolygon.new(customMt)
    -- upvalues: (copy) DebugPolygon_mt
    local self = DebugPolygon:superClass().new(customMt or DebugPolygon_mt)
    self.solid = false
    self.drawContour = false
    self.positions = {}
    return self
end
function DebugPolygon:draw()
    DebugPolygon.renderWithPositions(self.positions, self.color, self.solid, self.drawContour)
end
function DebugPolygon.renderWithPositions(positions, color, solid, drawContour)
    local r, g, b, a = (color or Color.PRESETS.WHITE):unpack()
    solid = Utils.getNoNil(solid, false)
    drawDebugPolygon(positions, r, g, b, a, solid)
    if drawContour then
        local i = 1
        for i = i, #positions, 3 do
            if i + 3 < #positions then
                drawDebugLine(positions[i], positions[i + 1], positions[i + 2], r, g, b, positions[i + 3], positions[i + 4], positions[i + 5], r, g, b, solid)
            else
                drawDebugLine(positions[i], positions[i + 1], positions[i + 2], r, g, b, positions[1], positions[2], positions[3], r, g, b, solid)
            end
        end
    end
end
function DebugPolygon:create(positions)
    self.positions = positions
    return self
end
function DebugPolygon:addPosition(x, y, z)
    table.insert(self.positions, x)
    table.insert(self.positions, y)
    table.insert(self.positions, z)
    return self
end
function DebugPolygon:setDrawContour(drawContour)
    self.drawContour = drawContour
    return self
end