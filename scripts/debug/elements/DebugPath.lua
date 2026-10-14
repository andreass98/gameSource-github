DebugPath = {}
local DebugPath_mt = Class(DebugPath, DebugElement)
function DebugPath.new(customMt)
    -- upvalues: (copy) DebugPath_mt
    local self = DebugPath:superClass().new(customMt or DebugPath_mt)
    self.points = {}
    self.alignToGround = false
    self.minimumDistanceBetweenPoints = nil
    self.solid = true
    return self
end
function DebugPath.newSimple(color, alignToGround, minimumDistanceBetweenPoints, solid, text)
    local self = DebugPath.new()
    self:setColorRGBA(unpack(color))
    self.alignToGround = Utils.getNoNil(alignToGround, self.alignToGround)
    self.minimumDistanceBetweenPoints = minimumDistanceBetweenPoints
    self.solid = Utils.getNoNil(solid, self.solid)
    self:setText(text)
    return self
end
function DebugPath:getShouldBeDrawn()
    return true
end
function DebugPath:draw()
    DebugPath.renderPath(self.points, self.color, self.alignToGround, self.forcedY, self.solid, self.clipDistance, self.text)
end
function DebugPath.renderPath(points, color, alignToGround, forcedY, solid, clipDistance, text)
    if #points < 2 then
        return
    end
    local r, g, b = (color or Color.PRESETS.WHITE):unpack()
    local cameraX = nil
    local cameraY = nil
    local cameraZ = nil
    if clipDistance ~= nil then
        cameraX, cameraY, cameraZ = getWorldTranslation(g_cameraManager:getActiveCamera())
    end
    local firstPoint = points[1]
    local lastPoint = points[#points]
    if clipDistance == nil or MathUtil.vector3Length(firstPoint[1] - cameraX, firstPoint[2] - cameraY, firstPoint[3] - cameraZ) < clipDistance then
        drawDebugPoint(firstPoint[1], firstPoint[2], firstPoint[3], 0, 1, 0, 1, false)
    end
    if clipDistance == nil or MathUtil.vector3Length(lastPoint[1] - cameraX, lastPoint[2] - cameraY, lastPoint[3] - cameraZ) < clipDistance then
        drawDebugPoint(lastPoint[1], lastPoint[2], lastPoint[3], 1, 0, 0, 1, false)
    end
    local minimalDistance = math.huge
    local closestPoint = nil
    for pointIndex, point in ipairs(points) do
        local nextPoint = points[pointIndex + 1]
        if nextPoint == nil then
            break
        end
        local drawSection = true
        if clipDistance ~= nil then
            local distanceToCam = MathUtil.vector3Length(point[1] - cameraX, point[2] - cameraY, point[3] - cameraZ)
            if clipDistance < distanceToCam then
                drawSection = false
            elseif distanceToCam < minimalDistance then
                closestPoint = pointIndex
                minimalDistance = distanceToCam
            end
        end
        if drawSection then
            local distanceToCam = point[1]
            local py = point[2]
            local pz = point[3]
            local npx = nextPoint[1]
            local npy = nextPoint[2]
            local npz = nextPoint[3]
            if forcedY == nil and (alignToGround and g_terrainNode ~= nil) then
                py = getTerrainHeightAtWorldPos(g_terrainNode, distanceToCam, 0, pz) + 0.025
                npy = getTerrainHeightAtWorldPos(g_terrainNode, npx, 0, npz) + 0.025
            end
            drawDebugLine(distanceToCam, forcedY or py, pz, r, g, b, npx, forcedY or npy, npz, r, g, b, solid)
        end
    end
    if text ~= nil and closestPoint ~= nil then
        local point = points[closestPoint]
        Utils.renderTextAtWorldPosition(point[1], point[2], point[3], text, 0.02, 0.01, color:unpack())
    end
end
function DebugPath:addPoint(x, y, z)
    if self.minimumDistanceBetweenPoints ~= nil then
        local p = self.points[#self.points]
        if p ~= nil and MathUtil.vector3Length(p[1] - x, p[2] - y, p[3] - z) < self.minimumDistanceBetweenPoints then
            return self
        end
    end
    table.insert(self.points, { x, y, z })
    return self
end
function DebugPath:clear()
    self.points = {}
    return self
end
function DebugPath:setForcedY(forcedY)
    self.forcedY = forcedY
    return self
end