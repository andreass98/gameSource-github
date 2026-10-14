FieldCourseVisualTile = {}
FieldCourseVisualTile.TILE_SIZE = 32
local FieldCourseVisualTile_mt = Class(FieldCourseVisualTile)
function FieldCourseVisualTile.new(fieldCourseVisual)
    -- upvalues: (copy) FieldCourseVisualTile_mt
    local self = setmetatable({}, FieldCourseVisualTile_mt)
    self.fieldCourseVisual = fieldCourseVisual
    self.visualSegments = {}
    self.toolSideSegments = {}
    self.sideOffsetSegmentsLeft = {}
    self.sideOffsetSegmentsRight = {}
    self.index = -1
    self.isValid = false
    self.foliageDataPlaneId = g_fruitTypeManager:getDefaultDataPlaneId()
    return self
end
function FieldCourseVisualTile:reset()
    local i = #self.visualSegments
    for i = i, 1, -1 do
        self.fieldCourseVisual:releaseVisualSegment(self.visualSegments[i])
        table.remove(self.visualSegments, i)
    end
    local i = #self.toolSideSegments
    for i = i, 1, -1 do
        self.fieldCourseVisual:releaseVisualSegment(self.toolSideSegments[i])
        table.remove(self.toolSideSegments, i)
    end
    local i = #self.sideOffsetSegmentsLeft
    for i = i, 1, -1 do
        self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsLeft[i])
        table.remove(self.sideOffsetSegmentsLeft, i)
    end
    local i = #self.sideOffsetSegmentsRight
    for i = i, 1, -1 do
        self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsRight[i])
        table.remove(self.sideOffsetSegmentsRight, i)
    end
    self.index = -1
    self.isValid = false
end
function FieldCourseVisualTile:init(index)
    self.index = index
    self.isValid = true
    local numRows = g_currentMission.terrainSize / FieldCourseVisualTile.TILE_SIZE
    local tilePositionZ = math.floor(index / numRows)
    self.tileMinX = (index - tilePositionZ * numRows) * FieldCourseVisualTile.TILE_SIZE - g_currentMission.terrainSize * 0.5
    self.tileMinZ = tilePositionZ * FieldCourseVisualTile.TILE_SIZE - g_currentMission.terrainSize * 0.5
    self.tileMaxX = self.tileMinX + FieldCourseVisualTile.TILE_SIZE
    self.tileMaxZ = self.tileMinZ + FieldCourseVisualTile.TILE_SIZE
    self:fillTile(self.fieldCourseVisual.fieldCourse.segments, self.visualSegments, true)
end
function FieldCourseVisualTile:fillTile(segments, target, doReset)
    if doReset then
        local i = #target
        for i = i, 1, -1 do
            self.fieldCourseVisual:releaseVisualSegment(target[i])
            table.remove(target, i)
        end
    end
    for segmentIndex, segment in ipairs(segments) do
        self:fillTileBySegment(segment, segmentIndex, target)
    end
end
function FieldCourseVisualTile:resetAdditionalSegments()
    local i = #self.toolSideSegments
    for i = i, 1, -1 do
        self.fieldCourseVisual:releaseVisualSegment(self.toolSideSegments[i])
        table.remove(self.toolSideSegments, i)
    end
    local i = #self.sideOffsetSegmentsLeft
    for i = i, 1, -1 do
        self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsLeft[i])
        table.remove(self.sideOffsetSegmentsLeft, i)
    end
    local i = #self.sideOffsetSegmentsRight
    for i = i, 1, -1 do
        self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsRight[i])
        table.remove(self.sideOffsetSegmentsRight, i)
    end
end
function FieldCourseVisualTile:fillAdditionalTileSegment(segment, segmentIndex, isToolSideSegment, isSideOffsetSegmentLeft, isSideOffsetSegmentRight)
    if segment ~= nil then
        if isToolSideSegment then
            self:fillTileBySegment(segment, segmentIndex, self.toolSideSegments)
            return
        end
        if isSideOffsetSegmentLeft then
            self:fillTileBySegment(segment, segmentIndex, self.sideOffsetSegmentsLeft)
            return
        end
        if isSideOffsetSegmentRight then
            self:fillTileBySegment(segment, segmentIndex, self.sideOffsetSegmentsRight)
        end
    end
end
function FieldCourseVisualTile:fillTileBySegment(segment, segmentIndex, target)
    local i = 1
    for i = i, #segment.positions - 1 do
        local p1 = segment.positions[i]
        local p2 = segment.positions[i + 1]
        local sx = p1[1]
        local ex = p2[1]
        local p1Inside = false
        if self.tileMinX <= sx then
            p1Inside = false
            if sx <= self.tileMaxX then
                p1Inside = false
                if self.tileMinZ <= p1[2] then
                    p1Inside = sz <= self.tileMaxZ
                end
            end
        end
        local p2Inside = false
        if self.tileMinX <= ex then
            p2Inside = false
            if ex <= self.tileMaxX then
                p2Inside = false
                if self.tileMinZ <= p2[2] then
                    p2Inside = ez <= self.tileMaxZ
                end
            end
        end
        if p1Inside and p2Inside then
            self:addSegment(sx, sz, ex, ez, segmentIndex, target)
            ::l18::
            if sx == self.tileMinX and ex == self.tileMinX then
                local z = math.clamp(sz, self.tileMinZ, self.tileMaxZ)
                self:addSegment(sx, self.tileMaxZ, ex, math.clamp(ez, self.tileMinZ, z), segmentIndex, target)
            end
            if sz == self.tileMinZ and ez == self.tileMinZ then
                local z = math.clamp(sx, self.tileMinX, self.tileMaxX)
                self:addSegment(self.tileMaxX, sz, math.clamp(ex, self.tileMinX, z), ez, segmentIndex, target)
            end
        else
            if p1Inside or p2Inside then
                local intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMinZ, self.tileMaxX, self.tileMinZ)
                if intersect then
                    if p1Inside then
                        self:addSegment(sx, sz, x, z, segmentIndex, target)
                    else
                        self:addSegment(x, z, ex, ez, segmentIndex, target)
                    end
                else
                    local x, z, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMaxZ, self.tileMaxX, self.tileMaxZ)
                    if x then
                        if p1Inside then
                            self:addSegment(sx, sz, z, z, segmentIndex, target)
                        else
                            self:addSegment(z, z, ex, ez, segmentIndex, target)
                        end
                    else
                        local x, z, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMinZ, self.tileMinX, self.tileMaxZ)
                        if x then
                            if p1Inside then
                                self:addSegment(sx, sz, z, z, segmentIndex, target)
                            else
                                self:addSegment(z, z, ex, ez, segmentIndex, target)
                            end
                        else
                            local x, z, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMaxX, self.tileMinZ, self.tileMaxX, self.tileMaxZ)
                            if x then
                                if p1Inside then
                                    self:addSegment(sx, sz, z, z, segmentIndex, target)
                                else
                                    self:addSegment(z, z, ex, ez, segmentIndex, target)
                                end
                            end
                        end
                    end
                end
                goto l18
            end
            local z, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMinZ, self.tileMaxX, self.tileMinZ)
            if not z then
                x = nil
                z = nil
            end
            local z, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMaxZ, self.tileMaxX, self.tileMaxZ)
            if z then
                if x == nil then
                    goto l40
                end
                self:addSegment(x, z, x, z, segmentIndex, target)
            else
                ::l40::
                local z, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMinZ, self.tileMinX, self.tileMaxZ)
                if not z then
                    ::l45::
                    local z, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMaxX, self.tileMinZ, self.tileMaxX, self.tileMaxZ)
                    if z and x ~= nil then
                        self:addSegment(x, z, x, z, segmentIndex, target)
                    end
                    goto l18
                end
                if x == nil then
                    goto l45
                end
                self:addSegment(x, z, x, z, segmentIndex, target)
            end
        end
    end
end
function FieldCourseVisualTile:addSegment(x1, z1, x2, z2, segmentIndex, target)
    local maxLength = self.fieldCourseVisual:getMaxVisualLineLength()
    local dirX = x2 - x1
    local dirZ = z2 - z1
    local length = MathUtil.vector2Length(dirX, dirZ)
    if length > 0 then
        local dirX = dirX / length
        local dirZ = dirZ / length
        local offset = 0
        for offset = offset, length - 0.01, maxLength do
            local sx = x1 + dirX * offset
            local sz = z1 + dirZ * offset
            local sy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz)
            local segmentLength = length - offset
            local l = math.min(segmentLength, maxLength)
            if l > 0 then
                local lineSegment = math.ceil(l)
                local segmentLength = math.min(lineSegment, maxLength)
                local lineSegment = self.fieldCourseVisual:getVisualSegment(segmentLength)
                setTranslation(lineSegment, sx, sy, sz)
                local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
                setRotation(lineSegment, 0, yRot, 0)
                setUserAttribute(lineSegment, "segmentIndex", UserAttributeType.INTEGER, segmentIndex)
                setShaderParameter(lineSegment, "intensitySize", nil, l / segmentLength, nil, segmentLength, false)
                table.insert(target, lineSegment)
            end
        end
    end
end
function FieldCourseVisualTile:setSegmentData(segmentToData, _, isLeft, activeSegmentIndex)
    for _, segment in ipairs(self.visualSegments) do
        local segmentIndex = getUserAttribute(segment, "segmentIndex")
        local data = segmentToData[segmentIndex]
        if data ~= nil then
            if self.fieldCourseVisual.fieldCourseSettings.sideOffset ~= 0 and segmentIndex == activeSegmentIndex then
                data = FieldCourseVisual.VISUALS[self.fieldCourseVisual.isColorBlindMode].INACTIVE
            end
            local visibility = data[4]
            if visibility then
                local color = data[1]
                setShaderParameter(segment, "emitColor", color[1], color[2], color[3], color[4], false)
                setShaderParameter(segment, "intensitySize", data[2], nil, data[3], nil, false)
                local borderColor = data[5]
                if borderColor == nil then
                    setShaderParameter(segment, "borderColor", nil, nil, nil, 1, false)
                else
                    setShaderParameter(segment, "borderColor", borderColor[1], borderColor[2], borderColor[3], borderColor[4], false)
                end
                local dashNumLength = data[6]
                if dashNumLength == nil then
                    setShaderParameter(segment, "dashNumLength", 0, nil, nil, nil, false)
                else
                    setShaderParameter(segment, "dashNumLength", dashNumLength[1], dashNumLength[2], nil, nil, false)
                end
            end
            setVisibility(segment, visibility)
        end
    end
    for segment, segmentIndex in ipairs(self.toolSideSegments) do
        local data = FieldCourseVisual.VISUALS[self.fieldCourseVisual.isColorBlindMode].TOOL_SIDE[1]
        setShaderParameter(segmentIndex, "emitColor", data[1], data[2], data[3], data[4], false)
        setShaderParameter(segmentIndex, "intensitySize", toolData[2], nil, toolData[3], nil, false)
        local visibility = toolData[5]
        if visibility == nil then
            setShaderParameter(segmentIndex, "borderColor", nil, nil, nil, 1, false)
        else
            setShaderParameter(segmentIndex, "borderColor", visibility[1], visibility[2], visibility[3], visibility[4], false)
        end
        local color = toolData[6]
        if color == nil then
            setShaderParameter(segmentIndex, "dashNumLength", 0, nil, nil, nil, false)
        else
            setShaderParameter(segmentIndex, "dashNumLength", color[1], color[2], nil, nil, false)
        end
    end
    for segment, segmentIndex in ipairs(self.sideOffsetSegmentsLeft) do
        local visibility = segmentToData[getUserAttribute(segmentIndex, "segmentIndex")]
        if visibility ~= nil then
            local color = visibility[4] and isLeft
            if color then
                local borderColor = visibility[1]
                setShaderParameter(segmentIndex, "emitColor", borderColor[1], borderColor[2], borderColor[3], borderColor[4], false)
                setShaderParameter(segmentIndex, "intensitySize", visibility[2], nil, visibility[3], nil, false)
                local dashNumLength = visibility[5]
                if dashNumLength == nil then
                    setShaderParameter(segmentIndex, "borderColor", nil, nil, nil, 1, false)
                else
                    setShaderParameter(segmentIndex, "borderColor", dashNumLength[1], dashNumLength[2], dashNumLength[3], dashNumLength[4], false)
                end
                local dashNumLength = visibility[6]
                if dashNumLength == nil then
                    setShaderParameter(segmentIndex, "dashNumLength", 0, nil, nil, nil, false)
                else
                    setShaderParameter(segmentIndex, "dashNumLength", dashNumLength[1], dashNumLength[2], nil, nil, false)
                end
            end
            setVisibility(segmentIndex, color)
        end
    end
    for segment, segmentIndex in ipairs(self.sideOffsetSegmentsRight) do
        local visibility = segmentToData[getUserAttribute(segmentIndex, "segmentIndex")]
        if visibility ~= nil then
            local color = visibility[4]
            if color then
                color = not isLeft
            end
            if color then
                local borderColor = visibility[1]
                setShaderParameter(segmentIndex, "emitColor", borderColor[1], borderColor[2], borderColor[3], borderColor[4], false)
                setShaderParameter(segmentIndex, "intensitySize", visibility[2], nil, visibility[3], nil, false)
                local dashNumLength = visibility[5]
                if dashNumLength == nil then
                    setShaderParameter(segmentIndex, "borderColor", nil, nil, nil, 1, false)
                else
                    setShaderParameter(segmentIndex, "borderColor", dashNumLength[1], dashNumLength[2], dashNumLength[3], dashNumLength[4], false)
                end
                local dashNumLength = visibility[6]
                if dashNumLength == nil then
                    setShaderParameter(segmentIndex, "dashNumLength", 0, nil, nil, nil, false)
                else
                    setShaderParameter(segmentIndex, "dashNumLength", dashNumLength[1], dashNumLength[2], nil, nil, false)
                end
            end
            setVisibility(segmentIndex, color)
        end
    end
end
function FieldCourseVisualTile:debugDraw()
    local title = string.format("Tile %d\nNumSegments: %d\nSeg Data Update: %.5fms", self.index, #self.visualSegments, self.segmentDataTime or -1)
    DebugPlane.renderWithPositions(self.tileMinX, 0, self.tileMinZ, self.tileMinX, 0, self.tileMaxZ, self.tileMaxX, 0, self.tileMinZ, self.color, true, false, true, false, title, nil)
end