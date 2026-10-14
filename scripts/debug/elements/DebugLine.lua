DebugLine = {}
local DebugLine_mt = Class(DebugLine, DebugElement)
function DebugLine.new(customMt)
    -- upvalues: (copy) DebugLine_mt
    local self = DebugLine:superClass().new(customMt or DebugLine_mt)
    self.solid = false
    self.colorStart = nil
    self.colorEnd = nil
    self.alignToGround = false
    self.nodeStart = nil
    self.nodeEnd = nil
    return self
end
function DebugLine:draw()
    if self.nodeStart ~= nil and (self.nodeEnd ~= nil and (entityExists(self.nodeStart) and entityExists(self.nodeEnd))) then
        self.xStart, self.yStart, self.zStart = getWorldTranslation(self.nodeStart)
        self.xEnd, self.yEnd, self.zEnd = getWorldTranslation(self.nodeEnd)
    end
    DebugLine.renderBetweenPositions(self.xStart, self.yStart, self.zStart, self.xEnd, self.yEnd, self.zEnd, self.color, self.solid, self.text, self.textSize, self.colorStart, self.colorEnd, self.clipDistance, self.textClipDistance)
end
function DebugLine.renderBetweenPositions(xStart, yStart, zStart, xEnd, yEnd, zEnd, color, solid, text, textSize, colorStart, colorEnd, clipDistance, textClipDistance)
    if yStart == nil or yEnd == nil then
        if g_terrainNode == nil then
            return
        end
        yStart = yStart or getTerrainHeightAtWorldPos(g_terrainNode, xStart, 0, zStart) + 0.01
        yEnd = yEnd or getTerrainHeightAtWorldPos(g_terrainNode, xEnd, 0, zEnd) + 0.01
    end
    if clipDistance == nil or (DebugUtil.isPositionInCameraRange(xStart, yStart, zStart, clipDistance) or DebugUtil.isPositionInCameraRange(xEnd, yEnd, zEnd, clipDistance)) then
        local rStart, gStart, bStart = (colorStart or (color or Color.PRESETS.WHITE)):unpack()
        local rEnd, gEnd, bEnd = (colorEnd or (color or Color.PRESETS.WHITE)):unpack()
        drawDebugLine(xStart, yStart, zStart, rStart, gStart, bStart, xEnd, yEnd, zEnd, rEnd, gEnd, bEnd, solid)
        if text ~= nil then
            local x = (xStart + xEnd) / 2
            local y = (yStart + yEnd) / 2
            local z = (zStart + zEnd) / 2
            if textClipDistance == nil or DebugUtil.isPositionInCameraRange(x, y, z, textClipDistance) then
                Utils.renderTextAtWorldPosition(x, y, z, text, textSize or 0.016, 0.005, (color or (colorStart or (colorEnd or Color.PRESETS.WHITE))):unpack())
            end
        end
    end
end
function DebugLine.renderBetweenNodes(nodeStart, nodeEnd, color, solid, text, textSize, colorStart, colorEnd, clipDistance, textClipDistance)
    local xStart, yStart, zStart = getWorldTranslation(nodeStart)
    local xEnd, yEnd, zEnd = getWorldTranslation(nodeEnd)
    DebugLine.renderBetweenPositions(xStart, yStart, zStart, xEnd, yEnd, zEnd, color, solid, text, textSize, colorStart, colorEnd, clipDistance, textClipDistance)
end
function DebugLine:createWithStartAndEndNode(nodeStart, nodeEnd, alignToGround, solid, clipDistance, updatePosition)
    local xStart, yStart, zStart = getWorldTranslation(nodeStart)
    local xEnd, yEnd, zEnd = getWorldTranslation(nodeEnd)
    self:createWithStartAndEndPos(xStart, yStart, zStart, xEnd, yEnd, zEnd, alignToGround, solid, clipDistance)
    if updatePosition == true then
        self.nodeStart = nodeStart
        self.nodeEnd = nodeEnd
    end
    return self
end
function DebugLine:createWithStartAndEndPos(xStart, yStart, zStart, xEnd, yEnd, zEnd, alignToGround, solid, clipDistance)
    if alignToGround and g_terrainNode ~= nil then
        yStart = getTerrainHeightAtWorldPos(g_terrainNode, xStart, 0, zStart) + 0.1
        yEnd = getTerrainHeightAtWorldPos(g_terrainNode, xEnd, 0, zEnd) + 0.1
    end
    self.x = (xStart + xEnd) / 2
    self.y = (yStart + yEnd) / 2
    self.z = (zStart + zEnd) / 2
    self.xStart = xStart
    self.yStart = yStart
    self.zStart = zStart
    self.xEnd = xEnd
    self.yEnd = yEnd
    self.zEnd = zEnd
    self.solid = Utils.getNoNil(solid, self.solid)
    self.clipDistance = Utils.getNoNil(clipDistance, self.clipDistance)
    return self
end
function DebugLine:setColors(colorStart, colorEnd)
    self.colorStart = colorStart or self.colorStart
    self.colorEnd = colorEnd or self.colorEnd
    return self
end