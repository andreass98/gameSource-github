AIFieldCourseUtil = {}
function AIFieldCourseUtil.getSegmentPosition(startPosition, segment, direction, offset)
    if not startPosition then
    end
    offset = offset or 0
    if direction >= 0 then
        return segment.positions[1 + offset][1], segment.positions[1 + offset][2]
    end
    local numPositions = #segment.positions
    return segment.positions[numPositions - offset][1], segment.positions[numPositions - offset][2]
end
function AIFieldCourseUtil.getSegmentPositionAndDirection(startPosition, segment, direction, offset, limitToOneSegment)
    offset = offset or 0
    if not startPosition then
    end
    local drivingDirection = startPosition and -1 or 1
    if direction >= 0 then
        local x = segment.positions[1][1]
        local z = segment.positions[1][2]
        local dirX, dirZ = MathUtil.vector2Normalize(segment.positions[1][1] - segment.positions[2][1], segment.positions[1][2] - segment.positions[2][2])
        if offset ~= 0 then
            x, z, dirX, dirZ = AIFieldCourseUtil.getSegmentPositionOffset(segment, -direction, -offset, limitToOneSegment)
        end
        return x, z, dirX * drivingDirection, dirZ * drivingDirection
    end
    local x = #segment.positions
    local z = segment.positions[x][1]
    local dirX = segment.positions[x][2]
    local dirZ, dirZ = MathUtil.vector2Normalize(segment.positions[x][1] - segment.positions[x - 1][1], segment.positions[x][2] - segment.positions[x - 1][2])
    if offset ~= 0 then
        z, dirX, dirZ, dirZ = AIFieldCourseUtil.getSegmentPositionOffset(segment, -direction, -offset, limitToOneSegment)
    end
    return z, dirX, dirZ * drivingDirection, dirZ * drivingDirection
end
function AIFieldCourseUtil.getSegmentPositionOffset(segment, direction, offset, limitToOneSegment)
    if direction > 0 then
        local indexOffset = 0
        while true do
            local p1 = segment.positions[#segment.positions - indexOffset - 1]
            local length, dirX, dirZ
            if p1 == nil then
                local p3 = segment.positions[#segment.positions - indexOffset + 1]
                local dirX = p3[1] - segment.positions[#segment.positions - indexOffset][1]
                local dirZ = p3[2] - p2[2]
                length = MathUtil.vector2Length(dirX, dirZ)
                dirX = dirX / length
                dirZ = dirZ / length
            else
                local dirX = p2[1] - p1[1]
                local dirZ = p2[2] - p1[2]
                length = MathUtil.vector2Length(dirX, dirZ)
                dirX = dirX / length
                dirZ = dirZ / length
            end
            if offset >= 0 then
                return p2[1] + dirX * offset, p2[2] + dirZ * offset, dirX, dirZ
            end
            if length >= -offset then
                return p2[1] + dirX * offset, p2[2] + dirZ * offset, dirX, dirZ
            end
            if limitToOneSegment == true or p1 == nil then
                if limitToOneSegment == true then
                    offset = length * math.sign(offset)
                end
                return p2[1] + dirX * offset, p2[2] + dirZ * offset, dirX, dirZ
            end
            offset = offset + length
            indexOffset = indexOffset + 1
        end
    else
        local indexOffset = 0
        while true do
            local p2 = segment.positions[indexOffset + 2]
            local length, dirX, dirZ
            if p2 == nil then
                local p3 = segment.positions[indexOffset]
                local dirX = p3[1] - segment.positions[indexOffset + 1][1]
                local dirZ = p3[2] - p1[2]
                length = MathUtil.vector2Length(dirX, dirZ)
                dirX = dirX / length
                dirZ = dirZ / length
            else
                local dirX = p1[1] - p2[1]
                local dirZ = p1[2] - p2[2]
                length = MathUtil.vector2Length(dirX, dirZ)
                dirX = dirX / length
                dirZ = dirZ / length
            end
            if offset >= 0 then
                return p1[1] + dirX * offset, p1[2] + dirZ * offset, dirX, dirZ
            end
            if length >= -offset then
                return p1[1] + dirX * offset, p1[2] + dirZ * offset, dirX, dirZ
            end
            if limitToOneSegment == true or p2 == nil then
                if limitToOneSegment == true then
                    offset = length * math.sign(offset)
                end
                return p1[1] + dirX * offset, p1[2] + dirZ * offset, dirX, dirZ
            end
            offset = offset + length
            indexOffset = indexOffset + 1
        end
    end
end
function AIFieldCourseUtil.getSegmentSideOffset(segment, x, z, extendSegment)
    if segment == nil then
        return math.huge, -1
    end
    local numPositions = #segment.positions
    local minDistance = math.huge
    local minDistanceIndex = -1
    local i = 1
    local x2 = numPositions - 1
    local z2 = 1
    for i = i, x2, z2 do
        local x2 = segment.positions[i][1]
        local z2 = segment.positions[i][2]
        local x3 = segment.positions[i + 1][1]
        local z3 = segment.positions[i + 1][2]
        local dirX = x3 - x2
        local dirZ = z3 - z2
        local length = MathUtil.vector2Length(dirX, dirZ)
        local dirX = dirX / length
        local dirZ = dirZ / length
        local dot = MathUtil.getProjectOnLineParameter(x, z, x2, z2, dirX, dirZ)
        if dot >= 0 and dot <= length then
            local distance = MathUtil.vector2Length(x2 + dirX * dot - x, z2 + dirZ * dot - z)
            if distance < minDistance then
                minDistanceIndex = i
                minDistance = distance
            end
        else
            local hitX = MathUtil.vector2Length(x2 - x, z2 - z)
            if hitX < minDistance then
                minDistanceIndex = i
            else
                hitX = minDistance
            end
            minDistance = MathUtil.vector2Length(x3 - x, z3 - z)
            if minDistance < hitX then
                minDistanceIndex = i
            else
                minDistance = hitX
            end
        end
    end
    if minDistanceIndex < 0 and extendSegment ~= false then
        local x2 = segment.positions[1][1]
        local z2 = segment.positions[1][2]
        local x2 = segment.positions[2][2]
        local z2 = segment.positions[2][1] - x2
        local x3 = x2 - z2
        local z3 = MathUtil.vector2Length(z2, x3)
        local z2 = z2 / z3
        local x3 = x3 / z3
        local dirX = MathUtil.getProjectOnLineParameter(x, z, x2, z2, z2, x3)
        local dot
        if dirX <= z3 then
            dot = MathUtil.vector2Length(x2 + z2 * dirX - x, z2 + x3 * dirX - z)
            if dot < minDistance then
                minDistanceIndex = 1
            else
                dot = minDistance
            end
        else
            dot = minDistance
        end
        local x2 = segment.positions[numPositions - 1][1]
        local z2 = segment.positions[numPositions - 1][2]
        local x2 = segment.positions[numPositions][2]
        local z2 = segment.positions[numPositions][1] - x2
        local x3 = x2 - z2
        local dirZ = MathUtil.vector2Length(z2, x3)
        local z2 = z2 / dirZ
        local x3 = x3 / dirZ
        local dirZ = MathUtil.getProjectOnLineParameter(x, z, x2, z2, z2, x3)
        if dirZ > 0 then
            minDistance = MathUtil.vector2Length(dirZ - x, z2 + x3 * (x2 + z2 * dirZ) - z)
            if minDistance < dot then
                minDistanceIndex = numPositions - 1
            else
                minDistance = dot
            end
        else
            minDistance = dot
        end
    end
    return minDistance, minDistanceIndex
end
function AIFieldCourseUtil.cutSegmentByDistance(segment, direction, distance)
    local numPositions = #segment.positions
    if direction > 0 then
        local i = 1
        for i = i, numPositions - 1 do
            local x1 = segment.positions[i][1]
            local z1 = segment.positions[i][2]
            local dx = segment.positions[i + 1][1] - x1
            local dz = segment.positions[i + 1][2] - z1
            local length = MathUtil.vector2Length(dx, dz)
            if distance < length then
                segment.positions[i][1] = x1 + dx / length * distance
                segment.positions[i][2] = z1 + dz / length * distance
                for indexToRemove = 1, i - 1 do
                    table.remove(segment.positions, 1)
                end
                return true
            end
            distance = distance - length
        end
        return false
    else
        for numPositions = numPositions, 2, -1 do
            local x1 = segment.positions[numPositions][1]
            local z1 = segment.positions[numPositions][2]
            local dx = segment.positions[numPositions - 1][1] - x1
            local dz = segment.positions[numPositions - 1][2] - z1
            local length = MathUtil.vector2Length(dx, dz)
            if distance < length then
                segment.positions[numPositions][1] = x1 + dx / length * distance
                segment.positions[numPositions][2] = z1 + dz / length * distance
                for numPositions = numPositions, numPositions + 1, -1 do
                    table.remove(segment.positions)
                end
                return true
            end
            distance = distance - length
        end
        return false
    end
end
function AIFieldCourseUtil.drawPath(positions, r, g, b, limitedPositionIndex, indexToDraw, yOffset, drawArrows)
    yOffset = yOffset or 0.25
    local fullLength = FieldCourseUtil.getSegmentLength(positions)
    local length = 0
    local i = 1
    for i = i, #positions - 1 do
        if limitedPositionIndex == nil or (limitedPositionIndex == 0 or i == limitedPositionIndex) then
            local x1 = positions[i][1]
            local z1 = positions[i][2]
            local x2 = positions[i + 1][1]
            local z2 = positions[i + 1][2]
            local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + yOffset
            local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + yOffset
            if (positions[i + 1][3] or 1) < 0 then
                drawDebugLine(x1, y1 + 0.01, z1, 1, 0, 0, x2, y2 + 0.01, z2, 1, 0, 0, false)
                drawDebugPoint(x1, y1 + 0.01, z1, 1, 0, 0, 1, false)
                drawDebugPoint(x2, y2 + 0.01, z2, 1, 0, 0, 1, false)
            else
                drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, false)
                drawDebugPoint(x1, y1, z1, r, g, b, 1, false)
                drawDebugPoint(x2, y2, z2, r, g, b, 1, false)
            end
            if indexToDraw ~= nil and i == 1 then
                local tx = (x1 + x2) * 0.5
                local tz = (z1 + z2) * 0.5
                local ty = getTerrainHeightAtWorldPos(g_terrainNode, tx, 0, tz) + yOffset
                Utils.renderTextAtWorldPosition(tx, ty, tz, tostring(indexToDraw), 0.02, 0, r, g, b, 1)
            end
            if drawArrows ~= false then
                local tx = MathUtil.vector2Length(x2 - x1, z2 - z1)
                if tx > 0 then
                    local tz, ty = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
                    local numArrows = math.min(math.floor(tx / math.min(0.9, tx)), 10)
                    local j = 1
                    for j = j, numArrows do
                        local offset = (j - 1) * tx / numArrows
                        local alpha = (length + offset) / fullLength
                        local sx = x1 + tz * offset
                        local sz = z1 + ty * offset
                        local y = getTerrainHeightAtWorldPos(g_terrainNode, sx, 0, sz) + yOffset
                        drawDebugTriangle(sx + ty * 0.25, y, sz - tz * 0.25, sx - ty * 0.25, y, sz + tz * 0.25, sx + tz * 0.5, y, sz + ty * 0.5, alpha, 1 - alpha, 0, 0.3, true)
                    end
                    length = length + tx
                end
            end
        end
    end
end
function AIFieldCourseUtil.drawPathArea(positions, r, g, b, a, width)
    width = width * 0.5
    local i = 1
    for i = i, #positions - 1 do
        local x1 = positions[i][1]
        local z1 = positions[i][2]
        local x2 = positions[i + 1][1]
        local z2 = positions[i + 1][2]
        local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + 0.25
        local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + 0.25
        local dx, dz = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
        drawDebugTriangle(x1 + dz * width, y1, z1 - dx * width, x1 - dz * width, y1, z1 + dx * width, x2 + dz * width, y2, z2 - dx * width, r, g, b, a, true)
        drawDebugTriangle(x1 - dz * width, y1, z1 + dx * width, x2 - dz * width, y2, z2 + dx * width, x2 + dz * width, y2, z2 - dx * width, r, g, b, a, true)
    end
end
function AIFieldCourseUtil.extendHeadlandSegment(segments, segmentIndex, direction, adjustDirection, implementWidth, boundaryLine, applyChanges, lockDirection)
    applyChanges = applyChanges == nil and true or applyChanges
    local segment = segments[segmentIndex]
    local nextSegment = segments[segmentIndex + direction]
    if nextSegment ~= nil and (segment.isHeadlandSegment ~= nextSegment.isHeadlandSegment or (segment.headlandIndex ~= nextSegment.headlandIndex or (segment.isIslandSegment ~= nextSegment.isIslandSegment or segment.islandIndex ~= nextSegment.islandIndex))) then
        nextSegment = nil
    end
    local drivingDirection
    if nextSegment == nil then
        local min = direction < 0 and #segments or 1
        drivingDirection = direction
        direction = drivingDirection
        drivingDirection = direction
        for min = min, segmentIndex, direction do
            local segmentToCheck = segments[min]
            if segment.isHeadlandSegment == segmentToCheck.isHeadlandSegment and (segment.headlandIndex == segmentToCheck.headlandIndex and (segment.isIslandSegment == segmentToCheck.isIslandSegment and segment.islandIndex == segmentToCheck.islandIndex)) then
                nextSegment = segmentToCheck
                break
            end
        end
    else
        drivingDirection = direction
        direction = drivingDirection
        drivingDirection = direction
    end
    if nextSegment ~= nil then
        if adjustDirection < 0 then
        end
        local min = #nextSegment.positions
        local max = nextSegment.positions[min - 1]
        local step = nextSegment.positions[min]
        local pos3 = segment.positions[1]
        local pos4 = segment.positions[2]
        if direction < 0 then
            max = nextSegment.positions[2]
            step = nextSegment.positions[1]
            local min = #segment.positions
            pos3 = segment.positions[min]
            pos4 = segment.positions[min - 1]
        end
        local x2 = step[1]
        local z2 = step[2]
        local x3 = pos3[1]
        local z3 = pos3[2]
        local dx1, dz1 = MathUtil.vector2Normalize(x2 - max[1], z2 - max[2])
        local dx2, dz2 = MathUtil.vector2Normalize(x3 - pos4[1], z3 - pos4[2])
        local rotationOffset = MathUtil.getYRotationFromDirection(dx1, dz1) - MathUtil.getYRotationFromDirection(dx2, dz2)
        if rotationOffset > 3.141592653589793 then
        elseif rotationOffset < -3.141592653589793 then
        end
        local halfWidth = implementWidth * 0.5
        local offset = implementWidth * 5
        local lineLength = offset * 2
        if MathUtil.vector2Length(x3 - x2, z3 - z2) < 0.01 then
            local distance1 = rotationOffset < 0 and 1 or -1
            local side2 = distance1 * direction
            local distance1, _, _ = (function(dir, side1, side2)
                -- upvalues: (copy) x2, (copy) dx1, (copy) offset, (copy) dz1, (copy) halfWidth, (copy) z2, (copy) x3, (copy) dx2, (copy) dz2, (copy) z3, (copy) lineLength
                local sx, sz, sdx, sdz, ex, ez, edx, edz
                if dir > 0 then
                    sx = x2 - dx1 * offset + dz1 * halfWidth * side1
                    sz = z2 - dz1 * offset - dx1 * halfWidth * side1
                    sdx = dx1
                    sdz = dz1
                    ex = x3 - dx2 * offset + dz2 * halfWidth * side2
                    ez = z3 - dz2 * offset - dx2 * halfWidth * side2
                    edx = dx2
                    edz = dz2
                else
                    sx = x3 - dx2 * offset + dz2 * halfWidth * side1
                    sz = z3 - dz2 * offset - dx2 * halfWidth * side1
                    sdx = dx2
                    sdz = dz2
                    ex = x2 - dx1 * offset + dz1 * halfWidth * side2
                    ez = z2 - dz1 * offset - dx1 * halfWidth * side2
                    edx = dx1
                    edz = dz1
                end
                local intersect, px, pz = MathUtil.getLineSegmentsIntersection(sx, sz, sx + sdx * lineLength, sz + sdz * lineLength, ex, ez, ex + edx * lineLength, ez + edz * lineLength)
                if intersect then
                    return MathUtil.vector2Length(px - sx, pz - sz) - offset, px, pz
                else
                    return nil, nil, nil
                end
            end)(direction, 1, side2)
            local distance2, _, _ = intersection(direction, -1, side2)
            if distance1 ~= nil and distance2 ~= nil then
                local maxDistance = math.max(distance1, distance2)
                local segmentLength = MathUtil.vector2Length(pos4[1] - pos3[1], pos4[2] - pos3[2])
                local ox2 = math.abs(maxDistance)
                local maxDistance = math.min(ox2, segmentLength - 0.01) * math.sign(maxDistance)
                if applyChanges then
                    pos3[1] = x3 + dx2 * maxDistance
                    pos3[2] = z3 + dz2 * maxDistance
                end
            end
            local maxDistance, segmentLength, oz1 = intersection(-direction, 1, side2)
            local maxDistance, segmentLength, oz1 = intersection(-direction, -1, side2)
            if maxDistance ~= nil and maxDistance ~= nil then
                local maxDistance = math.max(maxDistance, maxDistance)
                if math.abs(rotationOffset) > 1.5707963267948966 then
                    local dot1 = MathUtil.getProjectOnLineParameter(pos3[1] + dz2 * halfWidth, pos3[2] - dx2 * halfWidth, x2, z2, dx1, dz1)
                    local dot2 = MathUtil.getProjectOnLineParameter(pos3[1] - dz2 * halfWidth, pos3[2] + dx2 * halfWidth, x2, z2, dx1, dz1)
                    maxDistance = math.min(math.max(dot1, dot2), maxDistance)
                else
                    local oz1 = step[1]
                    local ox2 = step[2]
                    local oz2, dot1, dot2, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(oz1, ox2, oz1 + dx1 * maxDistance, ox2 + dz1 * maxDistance, boundaryLine)
                    if oz2 then
                        local distance = MathUtil.vector2Length(oz1 - dot1, dot2 - ox2)
                        local sideOffset = math.max(0, distance)
                        local sideOffset = halfWidth - 0.01
                        local oz1 = step[1] + dz1 * sideOffset
                        local ox2 = step[2] - dx1 * sideOffset
                        local oz2, dot1, dot2, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(oz1, ox2, oz1 + dx1 * maxDistance, ox2 + dz1 * maxDistance, boundaryLine)
                        if oz2 then
                            local distance = MathUtil.vector2Length(oz1 - dot1, dot2 - ox2)
                            sideOffset = math.max(sideOffset, distance)
                        end
                        local oz1 = step[1] - dz1 * sideOffset
                        local ox2 = step[2] + dx1 * sideOffset
                        local oz2, dot1, dot2, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(oz1, ox2, oz1 + dx1 * maxDistance, ox2 + dz1 * maxDistance, boundaryLine)
                        if oz2 then
                            local distance = MathUtil.vector2Length(oz1 - dot1, dot2 - ox2)
                            sideOffset = math.max(sideOffset, distance)
                        end
                        maxDistance = math.min(maxDistance, sideOffset)
                    end
                end
                if not applyChanges then
                    return x2 + dx1 * maxDistance, z2 + dz1 * maxDistance
                end
                local segmentLength = x2 + dx1 * maxDistance
                local oz1 = z2 + dz1 * maxDistance
                step[1] = segmentLength
                step[2] = oz1
            end
            if applyChanges then
                nextSegment.length = FieldCourseUtil.getSegmentLength(nextSegment.positions)
                segment.length = FieldCourseUtil.getSegmentLength(segment.positions)
                if nextSegment.lockedDirection == nil then
                    nextSegment.lockedDirection = lockDirection or drivingDirection
                end
                if segment.lockedDirection == nil then
                    segment.lockedDirection = lockDirection or drivingDirection
                end
            end
        end
    end
    return nil, nil
end
function AIFieldCourseUtil.getClosestPositionOnSegment(positions, x, z)
    local numPositions = #positions
    local minDistance = math.huge
    local minDistanceIndex = -1
    local minDistanceX = 0
    local minDistanceZ = 0
    local i = 1
    for i = i, numPositions - 1 do
        local x2 = positions[i][1]
        local z2 = positions[i][2]
        local dirX = positions[i + 1][1] - x2
        local dirZ = positions[i + 1][2] - z2
        local length = MathUtil.vector2Length(dirX, dirZ)
        local dirX = dirX / length
        local dirZ = dirZ / length
        local dot = MathUtil.getProjectOnLineParameter(x, z, x2, z2, dirX, dirZ)
        if dot >= 0 and dot <= length then
            local hitX = x2 + dirX * dot
            local hitZ = z2 + dirZ * dot
            local distance = MathUtil.vector2Length(hitX - x, hitZ - z)
            if distance < minDistance then
                minDistanceIndex = i
                minDistanceZ = hitZ
                minDistanceX = hitX
                minDistance = distance
            end
        end
    end
    local i = 1
    for i = i, numPositions do
        local x2 = positions[i][1]
        local z2 = positions[i][2]
        local x3 = MathUtil.vector2Length(x2 - x, z2 - z)
        if x3 < minDistance then
            minDistanceIndex = i
            minDistanceZ = z2
            minDistanceX = x2
            minDistance = x3
        end
    end
    return minDistanceX, minDistanceZ, minDistance, minDistanceIndex
end
function AIFieldCourseUtil.getSegmentToSegmentDistance(segment1, segment2)
    local distance = math.huge
    local i = 1
    for i = i, #segment1.positions - 1 do
        local cx = (segment1.positions[i][1] + segment1.positions[i + 1][1]) * 0.5
        local cz = (segment1.positions[i][2] + segment1.positions[i + 1][2]) * 0.5
        local sx, sz = AIFieldCourseUtil.getClosestPositionOnSegment(segment2.positions, cx, cz)
        distance = math.min(distance, MathUtil.vector2Length(sx - cx, sz - cz))
    end
    return distance
end