FieldCourseBoundary = {}
FieldCourseBoundary.SEGMENT_SPLIT_ANGLE = 0.4363323129985824
local FieldCourseBoundary_mt = Class(FieldCourseBoundary)
function FieldCourseBoundary.new()
    -- upvalues: (copy) FieldCourseBoundary_mt
    local self = setmetatable({}, FieldCourseBoundary_mt)
    self.segmentSplitAngle = FieldCourseBoundary.SEGMENT_SPLIT_ANGLE
    self.segments = {}
    self.boundaryLine = {}
    return self
end
function FieldCourseBoundary.createByBoundaryLine(boundaryLine, segmentSplitAngle)
    local self = FieldCourseBoundary.new()
    self.segmentSplitAngle = segmentSplitAngle
    self.segments, removedSegments = FieldCourseBoundary.generateSegmentsByBoundaryLine(boundaryLine, segmentSplitAngle)
    if self.segments == nil or #self.segments <= 0 then
        return nil
    end
    self.boundaryLine = boundaryLine
    if removedSegments then
        self:generateBoundaryLine()
    end
    return self
end
function FieldCourseBoundary:isValid()
    return #self.segments > 0
end
function FieldCourseBoundary:extend(offset)
    if self.segments == nil or #self.segments == 0 then
        return nil
    else
        local segmentParts = {}
        for _, segment in ipairs(self.segments) do
            local i = 1
            for i = i, #segment.positions - 1 do
                table.insert(segmentParts, {
                    ["p1"] = segment.positions[i],
                    ["p2"] = segment.positions[i + 1]
                })
            end
        end
        local boundaryLine = FieldCourseBoundary.getOffsetBoundaryBySegmentParts(segmentParts, offset)
        if #boundaryLine == 0 then
            return nil
        else
            local _ = table.clone
            table.insert(boundaryLine, _(boundaryLine[1]))
            FieldCourseUtil.removeShortSegments(boundaryLine, 0.25)
            local lengthBefore = FieldCourseUtil.getSegmentLength(boundaryLine)
            if FieldCourseBoundary.resolveSelfIntersections(boundaryLine) then
                local lengthAfter = FieldCourseUtil.getSegmentLength(boundaryLine)
                if lengthAfter < lengthBefore * 0.66 then
                    return nil
                elseif lengthAfter <= 0.1 then
                    return nil
                else
                    local _ = FieldCourseUtil.getSegmentLength(self.boundaryLine)
                    if offset > 0 then
                        if _ < lengthAfter then
                            return nil
                        end
                    elseif lengthAfter < _ then
                        return nil
                    end
                    if FieldCourseBoundary.getIsBoundaryLineInverted(boundaryLine) then
                        return nil
                    elseif FieldCourseUtil.getAreBoundariesColliding(boundaryLine, self.boundaryLine) then
                        return nil
                    else
                        return FieldCourseBoundary.createByBoundaryLine(boundaryLine, self.segmentSplitAngle)
                    end
                end
            else
                return nil
            end
        end
    end
end
function FieldCourseBoundary:generateBoundaryLine()
    local boundaryLine = {}
    for i, segment in ipairs(self.segments) do
        local numPositions = #segment.positions
        local posIndex = 1
        for posIndex = posIndex, i == #self.segments and numPositions and numPositions or numPositions - 1 do
            table.insert(boundaryLine, table.clone(segment.positions[posIndex]))
        end
    end
    self.boundaryLine = boundaryLine
end
function FieldCourseBoundary:isColliding(otherBoundary)
    return FieldCourseUtil.getAreBoundariesColliding(self.boundaryLine, otherBoundary.boundaryLine)
end
function FieldCourseBoundary:isInsideOf(otherBoundary)
    local i = 1
    for i = i, #self.boundaryLine - 1 do
        if not FieldCourseUtil.getIsPointInsideBoundary(self.boundaryLine[i][1], self.boundaryLine[i][2], otherBoundary.boundaryLine) then
            return false
        end
    end
    return true
end
function FieldCourseBoundary:cut(otherBoundary, invert)
    if invert == nil then
        invert = false
    end
    for segmentIndex, segment in ipairs(self.segments) do
        if #segment.positions >= 2 then
            local posIndex = 1
            while posIndex <= #segment.positions do
                local x1 = segment.positions[posIndex][1]
                local z1 = segment.positions[posIndex][2]
                if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, otherBoundary.boundaryLine) == not invert then
                    local lastPosition = segment.positions[posIndex - 1]
                    if lastPosition == nil then
                        local intersect = segment.positions[posIndex + 1]
                        if intersect ~= nil then
                            if FieldCourseUtil.getIsPointInsideBoundary(intersect[1], intersect[2], otherBoundary.boundaryLine) == not invert then
                                table.remove(segment.positions, posIndex)
                                posIndex = posIndex - 1
                            else
                                local ix, iz, iz = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, intersect[1], intersect[2], otherBoundary.boundaryLine)
                                if ix then
                                    segment.positions[posIndex][1] = iz
                                    segment.positions[posIndex][2] = iz
                                end
                            end
                        end
                    elseif FieldCourseUtil.getIsPointInsideBoundary(lastPosition[1], lastPosition[2], otherBoundary.boundaryLine) == invert then
                        local intersect, ix, iz = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, lastPosition[1], lastPosition[2], otherBoundary.boundaryLine)
                        if intersect then
                            local i = posIndex + 1
                            local iz = #segment.positions
                            for i = i, iz do
                                local nextPos = segment.positions[i]
                                if FieldCourseUtil.getIsPointInsideBoundary(nextPos[1], nextPos[2], otherBoundary.boundaryLine) == invert then
                                    local prevPos = segment.positions[i - 1]
                                    local intersect2, ix2, iz2 = FieldCourseUtil.getSegmentBoundaryIntersection(prevPos[1], prevPos[2], nextPos[1], nextPos[2], otherBoundary.boundaryLine)
                                    if intersect2 then
                                        local newSegment = segment.positions[posIndex]
                                        newSegment[1] = ix
                                        segment.positions[posIndex][2] = iz
                                        local newSegment = {
                                            ["positions"] = {}
                                        }
                                        table.insert(newSegment.positions, { ix2, iz2 })
                                        for i = i, #segment.positions do
                                            table.insert(newSegment.positions, segment.positions[i])
                                            segment.positions[i] = nil
                                        end
                                        local indexToRemove = i - 1
                                        for indexToRemove = indexToRemove, posIndex + 1, -1 do
                                            segment.positions[indexToRemove] = nil
                                        end
                                        local indexToRemove = segmentIndex + 1
                                        table.insert(self.segments, indexToRemove, newSegment)
                                        return self:cut(otherBoundary, invert)
                                    end
                                    break
                                end
                            end
                            local i = #segment.positions
                            local iz = posIndex + 1
                            for i = i, iz, -1 do
                                segment.positions[i] = nil
                            end
                        end
                    end
                elseif segment.positions[posIndex + 1] ~= nil then
                    local intersect = segment.positions[posIndex + 1][1]
                    local ix = segment.positions[posIndex + 1][2]
                    if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, otherBoundary.boundaryLine) == invert and FieldCourseUtil.getIsPointInsideBoundary(intersect, ix, otherBoundary.boundaryLine) == invert then
                        local iz, iz, iz1 = FieldCourseUtil.getSegmentClosestBoundaryIntersection(x1, z1, intersect, ix, otherBoundary.boundaryLine)
                        if iz then
                            local i, nextPos, prevPos = FieldCourseUtil.getSegmentClosestBoundaryIntersection(intersect, ix, x1, z1, otherBoundary.boundaryLine)
                            if i then
                                table.insert(segment.positions, posIndex + 1, { iz, iz1 })
                                local intersect2 = {
                                    ["positions"] = {}
                                }
                                table.insert(intersect2.positions, { nextPos, prevPos })
                                local newSegment = posIndex + 2
                                for newSegment = newSegment, #segment.positions do
                                    table.insert(intersect2.positions, segment.positions[newSegment])
                                    segment.positions[newSegment] = nil
                                end
                                local newSegment = segmentIndex + 1
                                table.insert(self.segments, newSegment, intersect2)
                                return self:cut(otherBoundary, invert)
                            end
                        end
                    end
                end
                posIndex = posIndex + 1
            end
        end
    end
    local i = #self.segments
    for i = i, 1, -1 do
        local segmentIndex = self.segments[i].positions
        if #segmentIndex < 2 then
            table.remove(self.segments, i)
        elseif FieldCourseUtil.getSegmentLength(segmentIndex) == 0 then
            table.remove(self.segments, i)
        end
    end
end
function FieldCourseBoundary:removeCollidingSegments(otherBoundary, workWidth)
    local numSegmentsStart = #self.segments
    for numSegmentsStart = numSegmentsStart, 1, -1 do
        local segment = self.segments[numSegmentsStart]
        local posIndex = #segment.positions - 1
        for posIndex = posIndex, 1, -1 do
            local x1 = segment.positions[posIndex][1]
            local z1 = segment.positions[posIndex][2]
            local x2 = segment.positions[posIndex + 1][1]
            local z2 = segment.positions[posIndex + 1][2]
            local dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
            if FieldCourseUtil.getIsSegmentInsideBoundary(x1 - dirZ * workWidth, z1 + dirX * workWidth, x2 - dirZ * workWidth, z2 + dirX * workWidth, otherBoundary.boundaryLine) then
                if not FieldCourseUtil.getIsSegmentInsideBoundary(x1 + dirZ * workWidth, z1 - dirX * workWidth, x2 + dirZ * workWidth, z2 - dirX * workWidth, otherBoundary.boundaryLine) then
                    if posIndex == 1 then
                        table.remove(segment.positions, posIndex)
                    else
                        table.remove(segment.positions, posIndex + 1)
                    end
                end
            elseif posIndex == 1 then
                table.remove(segment.positions, posIndex)
            else
                table.remove(segment.positions, posIndex + 1)
            end
        end
        if #segment.positions < 2 then
            table.remove(self.segments, numSegmentsStart)
        end
    end
    return numSegmentsStart ~= #self.segments
end
function FieldCourseBoundary:generateDebugLines(line)
    if dl == nil or dp == nil then
        return
    elseif line == nil then
        for posIndex, x1 in ipairs(self.segments) do
            if x1.invalid ~= true then
                local posIndex = 1
                local x2 = #x1.positions - 1
                local z2 = 1
                for posIndex = posIndex, x2, z2 do
                    dl(x1, x1.positions[posIndex][1].positions[posIndex][2], x1.positions[posIndex + 1][1], x1.positions[posIndex + 1][2], 0.5, false, { 1, 0, 0 })
                end
            end
        end
    else
        local posIndex = 1
        for posIndex = posIndex, #line - 1 do
            dl(line[posIndex][1], line[posIndex][2], line[posIndex + 1][1], line[posIndex + 1][2], 0.5, false, { 1, 0, 0 })
        end
    end
end
function FieldCourseBoundary:draw(r, g, b, offset)
    for _, segment in ipairs(self.segments) do
        local numPositions = #segment.positions
        local posIndex = 1
        for posIndex = posIndex, numPositions - 1 do
            local x1 = segment.positions[posIndex][1]
            local z1 = segment.positions[posIndex][2]
            local x2 = segment.positions[posIndex + 1][1]
            local z2 = segment.positions[posIndex + 1][2]
            local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + (offset or 1)
            local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + (offset or 1)
            drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, false)
            drawDebugPoint(x1, y1, z1, r, g, b, 1, false)
            if posIndex + 1 == numPositions then
                drawDebugPoint(x2, y2, z2, r, g, b, 1, false)
            end
        end
    end
end
function FieldCourseBoundary.generateSegmentsByBoundaryLine(boundaryLine, segmentSplitAngle)
    if #boundaryLine < 4 then
        return nil, false
    end
    if FieldCourseBoundary.splitBoundary(boundaryLine, segmentSplitAngle or FieldCourseBoundary.SEGMENT_SPLIT_ANGLE) == nil then
        return nil, false
    end
    local segments = {}
    for _, splitSegment in ipairs(splitSegments) do
        table.insert(segments, {
            ["positions"] = splitSegment
        })
    end
    local removedSegments = false
    if segments ~= nil then
        for _ = #segments, 1, -1 do
            if FieldCourseUtil.getSegmentLength(segments[_].positions) < FieldCourse.MIN_SEGMENT_LENGTH then
                local segment = segments[_ - 1] or segments[#segments]
                local nextSegment = segments[_ + 1] or segments[1]
                if segment ~= nil and nextSegment ~= nil then
                    local p1 = segment.positions[#segment.positions]
                    local p2 = nextSegment.positions[1]
                    local x = (p1[1] + p2[1]) * 0.5
                    local z = (p1[2] + p2[2]) * 0.5
                    p1[1] = x
                    p1[2] = z
                    p2[1] = x
                    p2[2] = z
                end
                table.remove(segments, _)
                removedSegments = true
            end
        end
    end
    return segments, removedSegments
end
function FieldCourseBoundary.getLineSegmentIntersections(boundaryLine, ignoreIndex, x, z, dirX, dirZ)
    local intersectCount = 0
    local posIndex = 1
    for posIndex = posIndex, #boundaryLine - 1 do
        if posIndex ~= ignoreIndex then
            local pos1 = boundaryLine[posIndex]
            local pos2 = boundaryLine[posIndex + 1]
            local intersect, ix, iz = MathUtil.getLineSegmentsIntersection(x, z, x + dirX * 65535, z + dirZ * 65535, pos1[1], pos1[2], pos2[1], pos2[2])
            if intersect then
                local distance1 = MathUtil.vector2Length(ix - pos1[1], iz - pos1[2])
                local distance2 = MathUtil.vector2Length(ix - pos2[1], iz - pos2[2])
                if distance1 ~= 0 and distance2 ~= 0 then
                end
            end
        end
    end
    local posIndex = 1
    for posIndex = posIndex, #boundaryLine - 1 do
        local pos1 = boundaryLine[posIndex]
        local pos2 = MathUtil.getProjectOnLineParameter(pos1[1], pos1[2], x, z, dirX, dirZ)
        if pos2 > 0 then
            if MathUtil.vector2Length(x + dirX * pos2 - pos1[1], z + dirZ * pos2 - pos1[2]) == 0 and FieldCourseUtil.getIsPointInsideBoundary(pos1[1] - dirX * 0.01, pos1[2] - dirZ * 0.01, boundaryLine) ~= FieldCourseUtil.getIsPointInsideBoundary(pos1[1] + dirX * 0.01, pos1[2] + dirZ * 0.01, boundaryLine) then
            end
        end
    end
    return intersectCount
end
function FieldCourseBoundary.getIsBoundaryLineInverted(boundaryLine)
    local posIndex = 1
    for posIndex = posIndex, #boundaryLine - 1 do
        local pos1 = boundaryLine[posIndex]
        local pos2 = boundaryLine[posIndex + 1]
        if pos2 == nil then
            pos1 = boundaryLine[posIndex - 1]
            pos2 = boundaryLine[posIndex]
        end
        local dirX, dirZ = MathUtil.vector2Normalize(pos2[1] - pos1[1], pos2[2] - pos1[2])
        if FieldCourseBoundary.getLineSegmentIntersections(boundaryLine, posIndex, (pos2[1] + pos1[1]) * 0.5, (pos2[2] + pos1[2]) * 0.5, -dirZ, dirX) % 2 == 0 then
            return true
        end
    end
    return false
end
function FieldCourseBoundary.resolveSelfIntersections(boundaryLine)
    local p1 = boundaryLine[1]
    local p2 = boundaryLine[#boundaryLine]
    local isLoop = MathUtil.vector2Length(p1[1] - p2[1], p1[2] - p2[2]) < 0.001
    local startIndex = 1
    while true do
        local foundIntersection = false
        local boundaryLineLength = #boundaryLine - 1
        local posIndex = 1
        for startIndex = startIndex, boundaryLineLength, posIndex do
            local index2 = #boundaryLine
            for index2 = index2, startIndex + 3, -1 do
                local p1 = boundaryLine[startIndex]
                local p2 = boundaryLine[startIndex + 1]
                local p3 = boundaryLine[index2 - 1]
                local p4 = boundaryLine[index2]
                local intersect, pX, pZ = MathUtil.getLineSegmentsIntersection(p1[1], p1[2], p2[1], p2[2], p3[1], p3[2], p4[1], p4[2])
                if intersect then
                    table.insert(boundaryLine, index2, { pX, pZ })
                    table.insert(boundaryLine, startIndex + 1, { pX, pZ })
                    startIndex = startIndex + 1
                    foundIntersection = true
                end
            end
            if foundIntersection then
                goto l5
            end
        end
        ::l5::
        if not foundIntersection then
            local posIndex = 1
            local foundIntersection = #boundaryLine - 1
            local boundaryLineLength = 1
            for posIndex = posIndex, foundIntersection, boundaryLineLength do
                local index1 = boundaryLine[posIndex]
                local pos2 = boundaryLine[posIndex + 1]
                if pos2 == nil then
                    index1 = boundaryLine[posIndex - 1]
                    pos2 = boundaryLine[posIndex]
                end
                local p1 = pos2[1] - index1[1]
                local p3 = MathUtil.vector2Length(pos2[1] - index1[1], pos2[2] - index1[2])
                if p3 > 0 then
                    if isLoop then
                        if FieldCourseBoundary.getLineSegmentIntersections(boundaryLine, posIndex, (pos2[1] + index1[1]) * 0.5, (pos2[2] + index1[2]) * 0.5, -((pos2[2] - index1[2]) / p3), p1 / p3) % 2 == 0 then
                            index1.isInvalid1 = true
                            pos2.isInvalid2 = true
                        end
                    end
                else
                    index1.isInvalid1 = true
                    pos2.isInvalid2 = true
                end
            end
            local posIndex = #boundaryLine
            local foundIntersection = 1
            local boundaryLineLength = -1
            for posIndex = posIndex, foundIntersection, boundaryLineLength do
                if boundaryLine[posIndex].isInvalid1 and boundaryLine[posIndex].isInvalid2 then
                    table.remove(boundaryLine, posIndex)
                end
            end
            while true do
                local foundIntersection = false
                local boundaryLineLength = #boundaryLine
                local pos2 = 1
                local posIndex = boundaryLineLength - 1
                local index1 = 1
                for pos2 = pos2, posIndex, index1 do
                    local p2 = 1
                    local x = pos2
                    for p2 = p2, boundaryLineLength do
                        local pZ = p2 * 0.5
                        local i = math.floor(boundaryLineLength * 0.5)
                        local intersect = math.ceil((math.min(pZ, i)))
                        local p3 = x + intersect * (p2 % 2 == 0 and 1 or -1)
                        local p4 = boundaryLine[(x - 1) % boundaryLineLength + 1]
                        local intersect = boundaryLine[(p3 - 1) % boundaryLineLength + 1]
                        if MathUtil.vector2Length(p4[1] - intersect[1], p4[2] - intersect[2]) < 0.001 then
                            if p3 >= x then
                            end
                            local i = p3 + 1
                            x = p3
                            for i = i, x do
                                boundaryLine[(i - 1) % boundaryLineLength + 1].isInvalid = true
                            end
                        end
                    end
                end
                local pos2 = #boundaryLine
                local posIndex = 1
                local index1 = -1
                for pos2 = pos2, posIndex, index1 do
                    if boundaryLine[pos2].isInvalid then
                        table.remove(boundaryLine, pos2)
                        foundIntersection = true
                    end
                end
                if not foundIntersection then
                    if #boundaryLine == 0 then
                        return false
                    end
                    if isLoop then
                        table.insert(boundaryLine, table.clone(boundaryLine[1], 1))
                    end
                    return true
                end
            end
        end
    end
end
function FieldCourseBoundary.getMaxSegmentAngle(points, maxSamples)
    if #points <= 3 then
        return 0
    end
    local angle = {}
    local i = 1
    for i = i, #points - 2 do
        local x2 = points[i + 1][1]
        local z2 = points[i + 1][2]
        local dir1X = x2 - points[i][1]
        local dir1Z = z2 - points[i][2]
        local dir2X = x2 - points[i + 2][1]
        local dir2Z = z2 - points[i + 2][2]
        local length1 = MathUtil.vector2Length(dir1X, dir1Z)
        local length2 = MathUtil.vector2Length(dir2X, dir2Z)
        if length1 > 0 and length2 > 0 then
            table.insert(angle, 3.141592653589793 - math.acos((MathUtil.dotProduct(dir1X / length1, 0, dir1Z / length1, dir2X / length2, 0, dir2Z / length2))))
        end
    end
    table.sort(angle, function(a, b)
        return b < a
    end)
    for maxSamples = maxSamples, 1, -1 do
        if angle[maxSamples] ~= nil then
            return angle[maxSamples]
        end
    end
    return 0
end
function FieldCourseBoundary.segmentApplySideOffset(segment, sideOffset)
    FieldCourseUtil.extendSegment(segment.positions, -1, 100)
    FieldCourseUtil.extendSegment(segment.positions, 1, 100)
    local offsetLine = FieldCourseBoundary.getOffsetBoundaryLine(segment.positions, -sideOffset, 0.01)
    if offsetLine ~= nil then
        FieldCourseUtil.extendSegment(offsetLine, -1, -100)
        FieldCourseUtil.extendSegment(offsetLine, 1, -100)
        if #offsetLine >= 2 then
            segment.positions = offsetLine
            return true
        end
    end
    FieldCourseUtil.extendSegment(segment.positions, -1, -100)
    FieldCourseUtil.extendSegment(segment.positions, 1, -100)
    return false
end
function FieldCourseBoundary.getOffsetBoundaryLine(boundaryLine, offset, minSegmentLength)
    local segmentParts = {}
    local i = 1
    for i = i, #boundaryLine - 1 do
        local segmentPart = {
            ["p1"] = boundaryLine[i],
            ["p2"] = boundaryLine[i + 1]
        }
        if (minSegmentLength or 0.001) < MathUtil.vector2Length(segmentPart.p2[1] - segmentPart.p1[1], segmentPart.p2[2] - segmentPart.p1[2]) then
            table.insert(segmentParts, segmentPart)
        end
    end
    local segmentPart = MathUtil.vector2Length(boundaryLine[1][1] - boundaryLine[#boundaryLine][1], boundaryLine[1][2] - boundaryLine[#boundaryLine][2]) < 0.001
    if #segmentParts < 1 then
        return nil
    else
        return FieldCourseBoundary.getOffsetBoundaryBySegmentParts(segmentParts, offset, segmentPart)
    end
end
function FieldCourseBoundary.getOffsetBoundaryBySegmentParts(segmentParts, offset, isLoop)
    local function connectSingleSegments(segments, segmentIndex, nextSegmentIndex)
        local segment = segments[segmentIndex]
        if not segment.connected then
            local pX = segment.p2Offset[1] - segments[nextSegmentIndex].p1Offset[1]
            if math.abs(pX) < 0.01 then
                local pX = segment.p2Offset[2] - nextSegment.p1Offset[2]
                if math.abs(pX) < 0.01 then
                    segment.p2Offset[1] = nextSegment.p1Offset[1]
                    segment.p2Offset[2] = nextSegment.p1Offset[2]
                    segment.connected = true
                end
            end
        end
        if not segment.connected then
            local intersect, pX, pZ = MathUtil.getLineSegmentsIntersection(segment.p1Offset[1], segment.p1Offset[2], segment.p2Offset[1], segment.p2Offset[2], nextSegment.p1Offset[1], nextSegment.p1Offset[2], nextSegment.p2Offset[1], nextSegment.p2Offset[2])
            if intersect then
                segment.p2Offset[1] = pX
                segment.p2Offset[2] = pZ
                nextSegment.p1Offset[1] = pX
                nextSegment.p1Offset[2] = pZ
                segment.connected = true
                return
            end
            local sx = segment.p1Offset[1]
            local sz = segment.p1Offset[2]
            local dirSX = segment.p2Offset[1] - segment.p1Offset[1]
            local dirSZ = segment.p2Offset[2] - segment.p1Offset[2]
            local sLength = MathUtil.vector2Length(dirSX, dirSZ)
            if sLength > 0 then
                local dirSX = dirSX / sLength
                local dirSZ = dirSZ / sLength
                local dirEX = nextSegment.p1Offset[1] - nextSegment.p2Offset[1]
                local dirEZ = nextSegment.p1Offset[2] - nextSegment.p2Offset[2]
                local eLength = MathUtil.vector2Length(dirEX, dirEZ)
                if eLength > 0 then
                    local intersect, intersectionPos, _ = MathUtil.getLineLineIntersection2D(sx, sz, dirSX, dirSZ, nextSegment.p2Offset[1], nextSegment.p2Offset[2], dirEX / eLength, dirEZ / eLength)
                    if intersect then
                        local pX = sx + dirSX * intersectionPos
                        local pZ = sz + dirSZ * intersectionPos
                        segment.p2Offset[1] = pX
                        segment.p2Offset[2] = pZ
                        nextSegment.p1Offset[1] = pX
                        nextSegment.p1Offset[2] = pZ
                        segment.connected = true
                    end
                end
            end
        end
    end
    local function connectSegments()
        -- upvalues: (copy) segmentParts, (copy) isLoop, (copy) connectSingleSegments
        local numSegmentParts = #segmentParts
        local segmentIndex = 1
        local limit = 1
        for segmentIndex = segmentIndex, numSegmentParts, limit do
            segmentParts[segmentIndex].connected = false
        end
        local limit = numSegmentParts + numSegmentParts - 1
        local start
        if isLoop == false then
            start = numSegmentParts + 1
            limit = numSegmentParts + numSegmentParts - 2
        else
            start = numSegmentParts
        end
        for start = start, limit do
            connectSingleSegments(segmentParts, (start - 1) % numSegmentParts + 1, (start + 1 - 1) % numSegmentParts + 1)
        end
        for start = start, limit do
            connectSingleSegments(segmentParts, (start - 1) % numSegmentParts + 1, (start + 1 - 1) % numSegmentParts + 1)
        end
        local segmentIndex = true
        local segmentIndex = 1
        local segmentIndex = 1
        for segmentIndex = segmentIndex, #segmentParts, segmentIndex do
            local segment = segmentParts[segmentIndex]
            if not segment.connected and (isLoop ~= false or segmentIndex < #segmentParts - 1) then
                local nextSegment = segmentParts[(segmentIndex + 1 - 1) % numSegmentParts + 1]
                if MathUtil.vector2Length(segment.p2Offset[1] - segment.p1Offset[1], segment.p2Offset[2] - segment.p1Offset[2]) < MathUtil.vector2Length(nextSegment.p2Offset[1] - nextSegment.p1Offset[1], nextSegment.p2Offset[2] - nextSegment.p1Offset[2]) then
                    segment.pendingRemove = true
                else
                    nextSegment.pendingRemove = true
                end
            end
        end
        local segmentIndex = -1
        for numSegmentParts = numSegmentParts, 1, segmentIndex do
            if segmentParts[numSegmentParts].pendingRemove then
                table.remove(segmentParts, numSegmentParts)
                segmentIndex = false
            end
        end
        if not segmentIndex then
            segmentIndex = #segmentParts == 0
        end
        return segmentIndex
    end
    local segmentIndex = 1
    local numSegments = 1
    for segmentIndex = segmentIndex, #segmentParts, numSegments do
        local segment = segmentParts[segmentIndex]
        local dirX1, dirZ1 = MathUtil.vector2Normalize(segment.p2[1] - segment.p1[1], segment.p2[2] - segment.p1[2])
        segment.p1Offset = { segment.p1[1] - dirZ1 * offset, segment.p1[2] + dirX1 * offset }
        segment.p2Offset = { segment.p2[1] - dirZ1 * offset, segment.p2[2] + dirX1 * offset }
    end
    while not connectSegments() do

    end
    local reconnectionRequired = false
    local segment = #segmentParts
    local numSegments = 1
    local segmentIndex = -1
    for segment = segment, numSegments, segmentIndex do
        local x1 = segmentParts[segment]
        if x1.connected then
            local z1, x2 = MathUtil.vector2Normalize(x1.p2[1] - x1.p1[1], x1.p2[2] - x1.p1[2])
            local z2 = x1.p2Offset[1] - x1.p1Offset[1]
            local dirX1 = x1.p2Offset[2] - x1.p1Offset[2]
            local dirZ1 = MathUtil.vector2Length(z2, dirX1)
            if dirZ1 == 0 then
                reconnectionRequired = true
                table.remove(segmentParts, segment)
            elseif MathUtil.dotProduct(z1, 0, x2, z2 / dirZ1, 0, dirX1 / dirZ1) < 0 then
                reconnectionRequired = true
                table.remove(segmentParts, segment)
            end
        end
    end
    if reconnectionRequired then
        local segment = 1
        for segment = segment, #segmentParts do
            segmentParts[segment].connected = false
        end
        while not connectSegments() do

        end
    end
    if isLoop == false then
        segmentParts[1].connected = true
        local numSegments = #segmentParts
        if numSegments > 1 then
            segmentParts[numSegments - 1].connected = true
            segmentParts[numSegments].connected = true
        end
    end
    local numSegments = {}
    for z1, x2 in ipairs(segmentParts) do
        if x2.connected then
            local dirZ1 = x2.p1Offset
            table.insert(numSegments, dirZ1)
            if isLoop == false and z1 == #segmentParts then
                table.insert(numSegments, x2.p2Offset)
            end
        end
    end
    return numSegments
end
function FieldCourseBoundary:adjustSegmentByHitPoints(hitPoints, segmentAdjustLength, _)
    for _, hitPoint in ipairs(hitPoints) do
        local posIndex = #self.boundaryLine - 1
        while true do
            local p1 = self.boundaryLine[posIndex]
            if p1 == nil then
                break
            end
            local p2 = self.boundaryLine[posIndex + 1]
            local sx = p1[1]
            local sz = p1[2]
            local ex = p2[1]
            local ez = p2[2]
            local dx = ex - sx
            local dz = ez - sz
            local length = MathUtil.vector2Length(dx, dz)
            local dx = dx / length
            local dz = dz / length
            local dot = MathUtil.getProjectOnLineParameter(hitPoint[1], hitPoint[2], p1[1], p1[2], dx, dz)
            if dot >= 0 and dot <= length then
                if MathUtil.vector2Length(hitPoint[1] - (p1[1] + dx * dot), hitPoint[2] - (p1[2] + dz * dot)) < segmentAdjustLength * 2 then
                    if dot < length - segmentAdjustLength then
                        table.insert(self.boundaryLine, posIndex + 1, { sx + dx * (dot + segmentAdjustLength), sz + dz * (dot + segmentAdjustLength) })
                    else
                        local lengthLeft = length - dot
                        local p3 = self.boundaryLine[posIndex + 2]
                        if p3 ~= nil then
                            local nextLength = MathUtil.vector2Length(p3[1] - ex, p3[2] - ez)
                            local lengthLeft = math.min(lengthLeft, nextLength - 0.05)
                            table.insert(self.boundaryLine, posIndex + 2, { ex + dx2 / nextLength * lengthLeft, ez + dz2 / nextLength * lengthLeft })
                        end
                    end
                    local p3 = self.boundaryLine
                    local dx2 = posIndex + 1
                    local dz2 = { sx + dx * dot, sz + dz * dot }
                    table.insert(p3, dx2, dz2)
                    if segmentAdjustLength < dot then
                        table.insert(self.boundaryLine, posIndex + 1, { sx + dx * (dot - segmentAdjustLength), sz + dz * (dot - segmentAdjustLength) })
                    else
                        local lengthLeft = segmentAdjustLength - dot
                        local p3 = self.boundaryLine[posIndex - 1]
                        if p3 ~= nil then
                            local nextLength = MathUtil.vector2Length(p3[1] - sx, p3[2] - sz)
                            local lengthLeft = math.min(lengthLeft, nextLength - 0.05)
                            table.insert(self.boundaryLine, posIndex, { sx + dx2 / nextLength * lengthLeft, sz + dz2 / nextLength * lengthLeft })
                            posIndex = posIndex - 1
                        end
                    end
                end
            end
            posIndex = posIndex - 1
        end
        FieldCourseUtil.removeShortSegments(self.boundaryLine, 0.25)
    end
    FieldCourseUtil.removeShortSegments(self.boundaryLine, 0.25)
    local pendingPositionChanges = {}
    for hitPoint, posIndex in ipairs(hitPoints) do
        local p1 = posIndex[1]
        local p2 = posIndex[2]
        local sx, sz = FieldCourseUtil.getClosestPositionOnBoundary(p1, p2, self.boundaryLine)
        local ex = MathUtil.vector2Length(sx - p1, sz - p2)
        if FieldCourseUtil.getIsPointInsideBoundary(p1, p2, self.boundaryLine) then
        end
        if VehicleDebug.state == VehicleDebug.DEBUG_AI then
            local ez = DebugCircle.new():createWithWorldPos(sx, 0, sz, self.segmentCollisionCheckSafetyOffset, nil, 25, false, true, false, false)
            g_debugManager:addElement(ez, nil, math.huge, math.huge)
        end
        local dz = 1
        local ez = #self.boundaryLine
        for dz = dz, ez do
            local length = self.boundaryLine[dz - 1]
            local dot = self.boundaryLine[dz]
            local lx = self.boundaryLine[dz + 1]
            local lz = nil
            local lengthLeft = nil
            if length == nil or lx == nil then
                if length == nil then
                    if lx ~= nil then
                        lz, lengthLeft = MathUtil.vector2Normalize(lx[1] - dot[1], lx[2] - dot[2])
                    end
                else
                    lz, lengthLeft = MathUtil.vector2Normalize(dot[1] - length[1], dot[2] - length[2])
                end
            else
                local p3, dx2 = MathUtil.vector2Normalize(dot[1] - length[1], dot[2] - length[2])
                local dz2, nextLength = MathUtil.vector2Normalize(lx[1] - dot[1], lx[2] - dot[2])
                lz, lengthLeft = MathUtil.vector2Normalize(p3 + dz2, dx2 + nextLength)
            end
            local dz2 = MathUtil.vector2Length(dot[1] - sx, dot[2] - sz) / 5
            local p3 = 1 - math.min(dz2, 1)
            if p3 > 0 then
                local dx2 = math.min(p3 * 1.5, 1)
                local nextLength = self.segmentCollisionCheckSafetyOffset + 1 - ex
                local dx2 = math.max(nextLength, 0.5) * dx2
                if dx2 > 0 then
                    if pendingPositionChanges[dz] == nil then
                        pendingPositionChanges[dz] = {}
                    end
                    table.insert(pendingPositionChanges[dz], { -lengthLeft * dx2, lz * dx2 })
                end
            end
        end
    end
    for hitPoint, posIndex in pairs(pendingPositionChanges) do
        local p1 = #posIndex
        local p2 = 0
        local sx = 0
        local sz = 0
        local dx = 1
        local ez = 1
        for dx = dx, p1, ez do
            sz = math.max(sz, MathUtil.vector2Length(posIndex[dx][1], posIndex[dx][2]))
        end
        local p2 = p2 / p1
        local sx = sx / p1
        local ex, ez = MathUtil.vector2Normalize(p2, sx)
        local dx = self.boundaryLine[hitPoint]
        if VehicleDebug.state == VehicleDebug.DEBUG_AI then
            local dz = DebugLine.new():createWithStartAndEndPos(dx[1], 0, dx[2], dx[1] + ex * sz, 0, dx[2] + ez * sz, true, true)
            g_debugManager:addElement(dz, nil, math.huge, math.huge)
        end
        local dz = dx[1] + ex * sz
        dx[1] = dz
        dx[2] = dx[2] + ez * sz
    end
    self.boundaryLine[1] = table.clone(self.boundaryLine[#self.boundaryLine])
    FieldCourseUtil.removeShortSegments(self.boundaryLine, 0.25)
    FieldCourseUtil.douglasPeucker(self.boundaryLine, 1)
end
function FieldCourseBoundary:segmentCollisionOverlapCallback(nodeId, _, isLast)
    if nodeId ~= 0 then
        local object = g_currentMission:getNodeObject(nodeId)
        if object == nil or object.spec_vine == nil then
            local x, _, z = getWorldTranslation(nodeId)
            table.insert(self.segmentCollisionCheckHitPoints, { x, z })
            if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                local debugCircle = DebugCircle.new():createWithWorldPos(x, 0, z, self.segmentCollisionCheckSafetyOffset, nil, 25, false, true, false, false)
                debugCircle.text = "obstacle: " .. getName(nodeId)
                g_debugManager:addElement(debugCircle, nil, math.huge, math.huge)
            end
        end
    end
    if isLast then
        self.segmentCollisionCheckNumOverlapChecks = self.segmentCollisionCheckNumOverlapChecks - 1
        if self.segmentCollisionCheckNumOverlapChecks <= 0 then
            local object = #self.segmentCollisionCheckHitPoints
            if object > 0 then
                self:adjustSegmentByHitPoints(self.segmentCollisionCheckHitPoints, 15, 4)
            end
            self.segmentCollisionCheckCallback(object > 0)
        end
    end
    return true
end
function FieldCourseBoundary:segmentCollisionOffset(testWidth, safetyOffset, callback)
    self.segmentCollisionCheckCallback = callback
    self.segmentCollisionCheckFinished = false
    self.segmentCollisionCheckSafetyOffset = safetyOffset
    self.segmentCollisionCheckHitPoints = {}
    self.segmentCollisionCheckNumOverlapChecks = #self.boundaryLine - 1
    local i = 1
    for i = i, #self.boundaryLine - 1 do
        local p1 = self.boundaryLine[i]
        local p2 = self.boundaryLine[i + 1]
        local dx = p2[1] - p1[1]
        local dz = p2[2] - p1[2]
        local length = MathUtil.vector2Length(dx, dz)
        local dx = dx / length
        local dz = dz / length
        local rotY = MathUtil.getYRotationFromDirection(dx, dz)
        local y1 = getTerrainHeightAtWorldPos(g_terrainNode, p1[1], 0, p1[2])
        local y2 = getTerrainHeightAtWorldPos(g_terrainNode, p2[1], 0, p2[2])
        local rotX = -math.atan((y2 - y1) / length)
        overlapBoxAsync((p1[1] + p2[1]) * 0.5 - dz * (testWidth - safetyOffset) * 0.5, (y1 + y2) * 0.5 + 2, (p1[2] + p2[2]) * 0.5 + dx * (testWidth - safetyOffset) * 0.5, rotX, rotY, 0, (testWidth + safetyOffset) * 0.5, 2, length * 0.5, "segmentCollisionOverlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
    end
end
function FieldCourseBoundary:regenerateSegments()
    self.segments, _ = FieldCourseBoundary.generateSegmentsByBoundaryLine(self.boundaryLine)
end
function FieldCourseBoundary.getBoundaryOffsetPosition(positions, index, length, direction, isLoop)
    local numChecks
    if isLoop then
        numChecks = #positions
    elseif direction > 0 then
        numChecks = numPositions - index
    else
        numChecks = index - 1
    end
    local i = 0
    for i = i, numChecks - 1 do
        local pos3, pos4
        if direction > 0 then
            pos3 = positions[(index + i - 1) % numPositions + 1]
            pos4 = positions[(index + i + 1 - 1) % numPositions + 1]
        else
            pos3 = positions[(index - i - 1) % numPositions + 1]
            pos4 = positions[(index - i - 1 - 1) % numPositions + 1]
        end
        local dir2X = pos4[1] - pos3[1]
        local dir2Z = pos4[2] - pos3[2]
        local segmentLength = MathUtil.vector2Length(dir2X, dir2Z)
        if length < segmentLength or i == numChecks - 1 then
            length = math.min(length, segmentLength)
            return pos3[1] + dir2X / segmentLength * length, pos3[2] + dir2Z / segmentLength * length
        end
        length = length - segmentLength
    end
    return positions[index][1], positions[index][2]
end
function FieldCourseBoundary.getSegmentAngle(positions, excludeIndex, isLoop)
    local maxAngle = 0
    local maxAngleIndex = -1
    local numPositions = #positions
    local min = 0
    local max = numPositions + 1
    if not isLoop then
        min = 2
        max = numPositions - 1
    end
    for min = min, max do
        local x1, z1 = FieldCourseBoundary.getBoundaryOffsetPosition(positions, min, 2, -1, isLoop)
        local p2 = positions[(min - 1) % numPositions + 1]
        local x2 = p2[1]
        local z2 = p2[2]
        local x3, z3 = FieldCourseBoundary.getBoundaryOffsetPosition(positions, min, 2, 1, isLoop)
        local dirX1 = x2 - x1
        local dirZ1 = z2 - z1
        local length1 = MathUtil.vector2Length(dirX1, dirZ1)
        local dirX2 = x3 - x2
        local dirZ2 = z3 - z2
        local length2 = MathUtil.vector2Length(dirX2, dirZ2)
        if length1 > 0 and length2 > 0 then
            local angle = math.acos((FieldCourseUtil.vector2Dot(dirX1 / length1, dirZ1 / length1, dirX2 / length2, dirZ2 / length2)))
            if maxAngle < angle and (excludeIndex == nil or (min - 1) % numPositions + 1 ~= excludeIndex) then
                maxAngleIndex = (min - 1) % numPositions + 1
                maxAngle = angle
            end
        end
    end
    return maxAngle, maxAngleIndex
end
function FieldCourseBoundary.splitBoundarySegment(positions, splitAngle)
    local maxAngle, maxAngleIndex = FieldCourseBoundary.getSegmentAngle(positions, nil, false)
    if maxAngleIndex == -1 or splitAngle >= maxAngle then
        return positions, nil
    end
    local segment1 = {}
    local i = 1
    for i = i, maxAngleIndex do
        local pos = positions[i]
        if i == maxAngleIndex then
            pos = table.clone(pos)
        end
        table.insert(segment1, pos)
    end
    local segment2 = {}
    local i = 1
    for maxAngleIndex = maxAngleIndex, #positions, i do
        table.insert(segment2, positions[maxAngleIndex])
    end
    return segment1, segment2
end
function FieldCourseBoundary.splitBoundarySegments(segments, splitAngle)
    local segmentsSplit = false
    local i = #segments
    for i = i, 1, -1 do
        local segment1, segment2 = FieldCourseBoundary.splitBoundarySegment(segments[i], splitAngle)
        if segment2 ~= nil then
            table.remove(segments, i)
            table.insert(segments, i, segment2)
            table.insert(segments, i, segment1)
            segmentsSplit = true
        end
    end
    return segmentsSplit
end
function FieldCourseBoundary.splitBoundary(positions, splitAngle)
    positions = table.clone(positions, math.huge)
    table.remove(positions, #positions)
    local _, maxAngleIndex1 = FieldCourseBoundary.getSegmentAngle(positions, nil, true)
    local _, maxAngleIndex2 = FieldCourseBoundary.getSegmentAngle(positions, maxAngleIndex1, true)
    if maxAngleIndex1 == -1 or maxAngleIndex2 == -1 then
        return nil
    end
    if maxAngleIndex2 >= maxAngleIndex1 then
    end
    local segments = {}
    local numPositions = #positions
    local segment1 = {}
    local maxAngleIndex1 = maxAngleIndex2
    local maxAngleIndex2 = maxAngleIndex1
    for maxAngleIndex2 = maxAngleIndex2, maxAngleIndex1 do
        local pos = positions[(maxAngleIndex2 - 1) % numPositions + 1]
        if (maxAngleIndex2 - 1) % numPositions + 1 == maxAngleIndex2 then
            pos = table.clone(pos)
        end
        table.insert(segment1, pos)
    end
    table.insert(segments, segment1)
    local segment2 = {}
    for maxAngleIndex2 = maxAngleIndex2, numPositions + maxAngleIndex1 do
        local pos = positions[(maxAngleIndex2 - 1) % numPositions + 1]
        if (maxAngleIndex2 - 1) % numPositions + 1 == maxAngleIndex1 then
            pos = table.clone(pos)
        end
        table.insert(segment2, pos)
    end
    table.insert(segments, segment2)
    while FieldCourseBoundary.splitBoundarySegments(segments, splitAngle) do

    end
    return segments
end
function FieldCourseBoundary.extendBoundaryLine(boundaryLine, offset)
    local boundary = FieldCourseBoundary.createByBoundaryLine(boundaryLine, nil)
    if boundary ~= nil then
        local boundary = boundary:extend(offset)
        if boundary ~= nil then
            return boundary.boundaryLine
        end
    end
    return nil
end