FieldCourseUtil = {}
function FieldCourseUtil.douglasPeucker(points, minDistance)
    local numPoints = #points
    if numPoints <= 2 then
        return
    else
        local isLoop = false
        if points[1][1] == points[numPoints][1] and points[1][2] == points[numPoints][2] then
            table.remove(points, numPoints)
            isLoop = true
            numPoints = numPoints - 1
        end
        local function getMaxDistancePoint(startIndex, endIndex)
            -- upvalues: (copy) points
            if endIndex - startIndex <= 1 then
                return 0, -1
            end
            local firstPoint = points[(startIndex - 1) % #points + 1]
            local lastPoint = points[(endIndex - 1) % #points + 1]
            local lineDirX = lastPoint[1] - firstPoint[1]
            local lineDirZ = lastPoint[2] - firstPoint[2]
            local lineLength = MathUtil.vector2Length(lineDirX, lineDirZ)
            if lineLength <= 0 then
                return 0, -1
            end
            local lineDirX = lineDirX / lineLength
            local lineDirZ = lineDirZ / lineLength
            local maxLength = -1
            local maxLengthPoint = 0
            local i = startIndex + 1
            for i = i, endIndex - 1 do
                local p = points[(i - 1) % #points + 1]
                local px = p[1]
                local pz = p[2]
                local lx, lz = MathUtil.projectOnLine(px, pz, firstPoint[1], firstPoint[2], lineDirX, lineDirZ)
                local length = MathUtil.vector2Length(px - lx, pz - lz)
                if maxLength < length then
                    maxLengthPoint = i
                    maxLength = length
                end
            end
            return maxLengthPoint, maxLength
        end
        local function douglasPeuckerRec(startIndex, endIndex)
            -- upvalues: (copy) getMaxDistancePoint, (copy) minDistance, (copy) douglasPeuckerRec, (copy) points
            local maxDistancePoint, maxDistance = getMaxDistancePoint(startIndex, endIndex)
            if minDistance < maxDistance then
                if maxDistancePoint - startIndex > 0 then
                    douglasPeuckerRec(startIndex, maxDistancePoint)
                end
                if endIndex - maxDistancePoint > 0 then
                    douglasPeuckerRec(maxDistancePoint, endIndex)
                    return
                end
            elseif maxDistance ~= -1 then
                local i = startIndex + 1
                for i = i, endIndex - 1 do
                    points[(i - 1) % #points + 1].valid = false
                end
            end
        end
        if isLoop then
            douglasPeuckerRec(1, numPoints - 1)
            for numPoints = numPoints, 1, -1 do
                if points[numPoints].valid == false then
                    table.remove(points, numPoints)
                end
            end
            local numPoints = #points
            douglasPeuckerRec(math.floor(numPoints * 0.5) + 1, numPoints + math.floor(numPoints * 0.5))
            for numPoints = numPoints, 1, -1 do
                if points[numPoints].valid == false then
                    table.remove(points, numPoints)
                end
            end
            table.insert(points, { points[1][1], points[1][2] })
        else
            douglasPeuckerRec(1, numPoints)
            for numPoints = numPoints, 1, -1 do
                if points[numPoints].valid == false then
                    table.remove(points, numPoints)
                end
            end
        end
    end
end
function FieldCourseUtil.visvalingamWhyattSimplification(positions, areaThreshold)
    while true do
        local minIndex = -1
        local minArea = math.huge
        local i = 1
        for i = i, #positions - 2 do
            local p1 = positions[i]
            local p2 = positions[i + 1]
            local p3 = positions[i + 2]
            local a = MathUtil.vector2Length(p2[1] - p1[1], p2[2] - p1[2])
            local b = MathUtil.vector2Length(p3[1] - p1[1], p3[2] - p1[2])
            local c = MathUtil.vector2Length(p3[1] - p2[1], p3[2] - p2[2])
            local area = 0.25 * math.sqrt((a ^ 2 + b ^ 2 + c ^ 2) ^ 2 - 2 * (a ^ 4 + b ^ 4 + c ^ 4))
            if area < areaThreshold and area < minArea then
                minIndex = i + 1
                minArea = area
            end
        end
        if minIndex <= 0 then
            return
        end
        table.remove(positions, minIndex)
    end
end
function FieldCourseUtil.langSimplification(positions, maxOffset, regionSize)
    local index = 1
    while true do
        local lx = #positions - index
        local startPos = math.min(regionSize, lx)
        local startPos = positions[index]
        local endPos = positions[index + startPos]
        if startPos == nil or endPos == nil then
            local startPos = #positions
            if positions[1][1] ~= positions[startPos][1] or positions[1][2] ~= positions[startPos][2] then
                table.insert(positions, table.clone(positions[1], 1))
            end
            return
        end
        local lx = startPos[1]
        local lz = startPos[2]
        local lineDirX, lineDirZ = MathUtil.vector2Normalize(endPos[1], endPos[2])
        local greaterThanOffset = false
        for index = index, index + startPos - 1 do
            local p = positions[index]
            local plx, plz = MathUtil.projectOnLine(p[1], p[2], lx, lz, lineDirX, lineDirZ)
            if maxOffset < MathUtil.vector2Length(p[1] - plx, p[2] - plz) then
                greaterThanOffset = true
                break
            end
        end
        if greaterThanOffset then
            regionSize = startPos - 1
        else
            local i = index + startPos - 1
            for i = i, index, -1 do
                table.remove(positions, i)
            end
        end
    end
end
function FieldCourseUtil.pointAveragePositions(positions)
    local numPositions = #positions
    if numPositions ~= 0 then
        local i = 1
        for i = i, numPositions - 1 do
            local p1 = positions[i]
            local p2 = positions[i + 1]
            p1[1] = (p1[1] + p2[1]) * 0.5
            p1[2] = (p1[2] + p2[2]) * 0.5
        end
        positions[numPositions][1] = positions[1][1]
        lastPosition[2] = positions[1][2]
    end
end
function FieldCourseUtil.vector2Dot(x1, z1, x2, z2)
    return x1 * x2 + z1 * z2
end
function FieldCourseUtil.semiConvexSimplification(positions, maxDistance, _)
    local numPositions = #positions
    local index1 = 1
    while true do
        if index1 >= numPositions - 1 then
            for numPositions = numPositions, 1, -1 do
                if positions[numPositions].invalid then
                    table.remove(positions, numPositions)
                end
            end
            return
        end
        local maxAngle = 0
        local maxAngleIndex = -1
        local distance = 1
        local p1 = 1
        for distance = distance, maxDistance, p1 do
            local index2 = index1 + distance
            if numPositions < index2 then
                break
            end
            local p1 = positions[index1]
            local p1_2 = positions[index1 + 1]
            local bDirX = p1_2[1] - p1[1]
            local bDirZ = p1_2[2] - p1[2]
            local bLength = MathUtil.vector2Length(bDirX, bDirZ)
            if bLength > 0 then
                local bDirX = bDirX / bLength
                local bDirZ = bDirZ / bLength
                local dirX = positions[index2][1] - p1[1]
                local dirZ = p2[2] - p1[2]
                local length = MathUtil.vector2Length(dirX, dirZ)
                if length > 0 then
                    local dirX = dirX / length
                    local dirZ = dirZ / length
                    if FieldCourseUtil.vector2Dot(dirX, dirZ, -bDirZ, bDirX) < 0 then
                        local angle = math.acos((FieldCourseUtil.vector2Dot(dirX, dirZ, bDirX, bDirZ)))
                        if maxAngle < angle then
                            maxAngleIndex = index2
                            maxAngle = angle
                        end
                    end
                end
            end
        end
        if maxAngleIndex > 0 then
            local p1 = index1 - 1
            local startIndex = math.max(p1, 1)
            local p1 = positions[startIndex]
            local distance = positions[startIndex + 1]
            local p2 = numPositions - 1
            local index2 = positions[math.min(maxAngleIndex, p2)]
            local p2 = maxAngleIndex + 1
            local p1 = positions[math.min(p2, numPositions)]
            local p1_2 = distance[1] - p1[1]
            local p2 = distance[2] - p1[2]
            local bDirX = MathUtil.vector2Length(p1_2, p2)
            if bDirX > 0 then
                local p1_2 = p1_2 / bDirX
                local p2 = p2 / bDirX
                local bDirZ = p1[1] - index2[1]
                local bLength = p1[2] - index2[2]
                local dirX = MathUtil.vector2Length(bDirZ, bLength)
                if dirX > 0 then
                    local length = FieldCourseUtil.vector2Dot(p1_2, p2, bDirZ / dirX, bLength / dirX)
                    if math.acos(length) < 0.7853981633974483 then
                        local angle = index1 + 1
                        for angle = angle, maxAngleIndex - 1 do
                            positions[angle].invalid = true
                        end
                    end
                end
            end
        end
        index1 = index1 + 1
    end
end
function FieldCourseUtil.getLineSegmentsIntersection(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
    local denominator = (bz2 - bz1) * (ax2 - ax1) - (bx2 - bx1) * (az2 - az1)
    if denominator ~= 0 then
        local uA = ((bx2 - bx1) * (az1 - bz1) - (bz2 - bz1) * (ax1 - bx1)) / denominator
        local uB = ((ax2 - ax1) * (az1 - bz1) - (az2 - az1) * (ax1 - bx1)) / denominator
        if uA > 0 and (uA < 1 and (uB > 0 and uB < 1)) then
            return true, ax1 + uA * (ax2 - ax1), az1 + uA * (az2 - az1)
        end
    end
    local uA = ax2 - ax1
    local uB = az2 - az1
    local x = MathUtil.vector2Length(uA, uB)
    local uA = uA / x
    local uB = uB / x
    local z = MathUtil.getProjectOnLineParameter(bx1, bz1, ax1, az1, uA, uB)
    if z > 0 and z < x then
        local ix = ax1 + uA * z
        local iz = az1 + uB * z
        if MathUtil.vector2Length(ix - bx1, iz - bz1) == 0 then
            return true, ix, iz
        end
    end
    local ix = MathUtil.getProjectOnLineParameter(bx2, bz2, ax1, az1, uA, uB)
    if ix > 0 and ix < x then
        local ix = ax1 + uA * ix
        local iz = az1 + uB * ix
        if MathUtil.vector2Length(ix - bx2, iz - bz2) == 0 then
            return true, ix, iz
        end
    end
    return false, 0, 0
end
function FieldCourseUtil.getIsPointInsideBoundary(x, z, boundary)
    local intersectCount = 0
    local i = 1
    for i = i, #boundary - 1 do
        local z2 = boundary[i][2]
        local z3 = boundary[i + 1][2]
        if z == z2 or z == z3 then
        end
        if MathUtil.getLineSegmentsIntersection(x, z, x + 65535, z, boundary[i][1], z2, boundary[i + 1][1], z3) then
        end
    end
    return intersectCount % 2 ~= 0, intersectCount
end
function FieldCourseUtil.getDistanceToBoundary(x, z, boundary)
    local minDistance = math.huge
    local minDistanceIndex = -1
    local i = 1
    for i = i, #boundary - 1 do
        local x2 = boundary[i][1]
        local z2 = boundary[i][2]
        local x3 = boundary[i + 1][1]
        local z3 = boundary[i + 1][2]
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
    return minDistance, minDistanceIndex
end
function FieldCourseUtil.getPositionSegmentOverlap(x, z, segment, maxDistance)
    local i = 1
    for i = i, #segment - 1 do
        local x2 = segment[i][1]
        local z2 = segment[i][2]
        local dirX = segment[i + 1][1] - x2
        local dirZ = segment[i + 1][2] - z2
        local length = MathUtil.vector2Length(dirX, dirZ)
        local dirX = dirX / length
        local dirZ = dirZ / length
        local dot = MathUtil.getProjectOnLineParameter(x, z, x2, z2, dirX, dirZ)
        if dot >= 0 and dot <= length then
            if MathUtil.vector2Length(x2 + dirX * dot - x, z2 + dirZ * dot - z) < maxDistance then
                return true
            end
        else
            local hitX = MathUtil.vector2Length(x2 - x, z2 - z)
            if hitX < maxDistance then
                return true
            end
            if hitX < maxDistance then
                return true
            end
        end
    end
    return false
end
function FieldCourseUtil.getDistanceToSegment(sx1, sz1, sx2, sz2, x, z)
    local dirX = sx2 - sx1
    local dirZ = sz2 - sz1
    local length = MathUtil.vector2Length(dirX, dirZ)
    local dirX = dirX / length
    local dirZ = dirZ / length
    local dot = MathUtil.getProjectOnLineParameter(x, z, sx1, sz1, dirX, dirZ)
    if dot >= 0 and dot <= length then
        return MathUtil.vector2Length(sx1 + dirX * dot - x, sz1 + dirZ * dot - z)
    else
        local hitX = MathUtil.vector2Length(sx1 - x, sz1 - z)
        local hitZ = MathUtil.vector2Length(sx2 - x, sz2 - z)
        return math.min(hitX, hitZ)
    end
end
function FieldCourseUtil.getAreParallelSegmentsNextToEachOther(sx1, sz1, ex1, ez1, sx2, sz2, ex2, ez2)
    local dirX = ex1 - sx1
    local dirZ = ez1 - sz1
    local length = MathUtil.vector2Length(dirX, dirZ)
    local dirX = dirX / length
    local dirZ = dirZ / length
    local dot = MathUtil.getProjectOnLineParameter(sx2, sz2, sx1, sz1, dirX, dirZ)
    if dot >= 0 and dot <= length then
        return true
    end
    local dot = MathUtil.getProjectOnLineParameter(ex2, ez2, sx1, sz1, dirX, dirZ)
    if dot >= 0 and dot <= length then
        return true
    end
    local dirX = ex2 - sx2
    local dirZ = ez2 - sz2
    local dot = MathUtil.vector2Length(dirX, dirZ)
    local dirX = dirX / dot
    local dirZ = dirZ / dot
    local dot = MathUtil.getProjectOnLineParameter(sx1, sz1, sx2, sz2, dirX, dirZ)
    if dot >= 0 and dot <= dot then
        return true
    end
    local dot = MathUtil.getProjectOnLineParameter(ex1, ez1, sx2, sz2, dirX, dirZ)
    return dot >= 0 and dot <= dot
end
function FieldCourseUtil.getAreBoundariesColliding(boundary1, boundary2)
    local i1 = 1
    for i1 = i1, #boundary1 - 1 do
        local i2 = 1
        for i2 = i2, #boundary2 - 1 do
            if MathUtil.getLineSegmentsIntersection(boundary1[i1][1], boundary1[i1][2], boundary1[i1 + 1][1], boundary1[i1 + 1][2], boundary2[i2][1], boundary2[i2][2], boundary2[i2 + 1][1], boundary2[i2 + 1][2]) then
                return true
            end
        end
    end
    return false
end
function FieldCourseUtil.getIsSegmentInsideBoundary(l1x, l1z, l2x, l2z, boundary)
    local lDirX, lDirZ = MathUtil.vector2Normalize(l2x - l1x, l2z - l1z)
    l1x = l1x + lDirX * 0.001
    l1z = l1z + lDirZ * 0.001
    l2x = l2x - lDirX * 0.001
    l2z = l2z - lDirZ * 0.001
    if not (FieldCourseUtil.getIsPointInsideBoundary(l1x, l1z, boundary) and FieldCourseUtil.getIsPointInsideBoundary(l2x, l2z, boundary)) then
        return false
    end
    local numIntersections = 0
    local i = 1
    for i = i, #boundary - 1 do
        local intersect, _, _ = MathUtil.getLineSegmentsIntersection(boundary[i][1], boundary[i][2], boundary[i + 1][1], boundary[i + 1][2], l1x, l1z, l2x, l2z)
        if intersect then
        end
    end
    return numIntersections == 0
end
function FieldCourseUtil.getSegmentBoundaryIntersection(l1x, l1z, l2x, l2z, boundary)
    local i = 1
    for i = i, #boundary - 1 do
        local intersect, x, z = MathUtil.getLineSegmentsIntersection(boundary[i][1], boundary[i][2], boundary[i + 1][1], boundary[i + 1][2], l1x, l1z, l2x, l2z)
        if intersect then
            return intersect, x, z
        end
    end
    return false, 0, 0
end
function FieldCourseUtil.getSegmentNumBoundaryIntersections(l1x, l1z, l2x, l2z, boundary)
    local intersections = 0
    local i = 1
    for i = i, #boundary - 1 do
        local intersect, _, _ = MathUtil.getLineSegmentsIntersection(boundary[i][1], boundary[i][2], boundary[i + 1][1], boundary[i + 1][2], l1x, l1z, l2x, l2z)
        if intersect then
        end
    end
    return intersections
end
function FieldCourseUtil.getSegmentClosestBoundaryIntersection(l1x, l1z, l2x, l2z, boundary)
    local minDistance = math.huge
    local ix = nil
    local iz = nil
    local psx = nil
    local psz = nil
    local pex = nil
    local pez = nil
    local i = 1
    for i = i, #boundary - 1 do
        local sx = boundary[i][1]
        local sz = boundary[i][2]
        local ex = boundary[i + 1][1]
        local ez = boundary[i + 1][2]
        local intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, l1x, l1z, l2x, l2z)
        if intersect then
            local distance = MathUtil.vector2Length(l1x - x, l1z - z)
            if distance < minDistance then
                pez = ez
                pex = ex
                psz = sz
                psx = sx
                iz = z
                ix = x
                minDistance = distance
            end
        end
    end
    return minDistance ~= math.huge, ix, iz, psx, psz, pex, pez
end
function FieldCourseUtil.getSegmentClosestBoundaryCircleIntersection(refX, refZ, circleX, circleZ, radius, boundary)
    local minDistance = math.huge
    local ix = nil
    local iz = nil
    local i = 1
    for i = i, #boundary - 1 do
        local sx = boundary[i][1]
        local sz = boundary[i][2]
        local ex = boundary[i + 1][1]
        local ez = boundary[i + 1][2]
        if MathUtil.vector2Length(sx - ex, sz - ez) > 0 then
            local intersect, ix1, iz1, ix2, iz2 = MathUtil.getCircleLineIntersection(circleX, circleZ, radius, sx, sz, ex, ez)
            if intersect then
                local distance
                if ix1 == nil or iz1 == nil then
                    iz1 = iz
                    ix1 = ix
                    distance = minDistance
                else
                    distance = MathUtil.vector2Length(ix1 - refX, iz1 - refZ)
                    if distance >= minDistance then
                        iz1 = iz
                        ix1 = ix
                        distance = minDistance
                    end
                end
                if ix2 == nil or iz2 == nil then
                    iz = iz1
                    ix = ix1
                    minDistance = distance
                else
                    minDistance = MathUtil.vector2Length(ix2 - refX, iz2 - refZ)
                    if minDistance < distance then
                        iz = iz2
                        ix = ix2
                    else
                        iz = iz1
                        ix = ix1
                        minDistance = distance
                    end
                end
            end
        end
    end
    return ix ~= nil, ix, iz
end
function FieldCourseUtil.getClosestPositionOnBoundary(x, z, boundary)
    local minDistance = math.huge
    local cx = nil
    local cz = nil
    local i = 1
    for i = i, #boundary - 1 do
        local sx = boundary[i][1]
        local sz = boundary[i][2]
        local ex = boundary[i + 1][1]
        local ez = boundary[i + 1][2]
        local dirX = ex - sx
        local dirZ = ez - sz
        local length = MathUtil.vector2Length(dirX, dirZ)
        local dirX = dirX / length
        local dirZ = dirZ / length
        local dot = MathUtil.getProjectOnLineParameter(x, z, sx, sz, dirX, dirZ)
        local ix, iz, distance
        if dot >= 0 and dot <= length then
            ix = sx + dirX * dot
            iz = sz + dirZ * dot
            distance = MathUtil.vector2Length(ix - x, iz - z)
            if distance >= minDistance then
                iz = cz
                ix = cx
                distance = minDistance
            end
        else
            iz = cz
            ix = cx
            distance = minDistance
        end
        local ix = MathUtil.vector2Length(sx - x, sz - z)
        if ix >= distance then
            sz = iz
            sx = ix
        end
        minDistance = MathUtil.vector2Length(ex - x, ez - z)
        if minDistance < ix then
            cz = ez
            cx = ex
        else
            cz = sz
            cx = sx
            minDistance = ix
        end
    end
    return cx, cz
end
function FieldCourseUtil.getClosestPositionAndDirectionOnBoundary(x, z, boundary)
    local minDistance = math.huge
    local cx = nil
    local cz = nil
    local cDirX = nil
    local cDirZ = nil
    local i = 1
    for i = i, #boundary - 1 do
        local sx = boundary[i][1]
        local sz = boundary[i][2]
        local ex = boundary[i + 1][1]
        local ez = boundary[i + 1][2]
        local dirX = ex - sx
        local dirZ = ez - sz
        local length = MathUtil.vector2Length(dirX, dirZ)
        local dirX = dirX / length
        local dirZ = dirZ / length
        local dot = MathUtil.getProjectOnLineParameter(x, z, sx, sz, dirX, dirZ)
        local ix, iz, distance
        if dot >= 0 and dot <= length then
            ix = sx + dirX * dot
            iz = sz + dirZ * dot
            distance = MathUtil.vector2Length(ix - x, iz - z)
            if distance < minDistance then
                cDirZ = dirZ
                cDirX = dirX
            else
                iz = cz
                ix = cx
                distance = minDistance
            end
        else
            iz = cz
            ix = cx
            distance = minDistance
        end
        local ix = MathUtil.vector2Length(sx - x, sz - z)
        if ix < distance then
            cDirZ = dirZ
            cDirX = dirX
        else
            sz = iz
            sx = ix
        end
        minDistance = MathUtil.vector2Length(ex - x, ez - z)
        if minDistance < ix then
            cDirZ = dirZ
            cDirX = dirX
            cz = ez
            cx = ex
        else
            cz = sz
            cx = sx
            minDistance = ix
        end
    end
    return cx, cz, cDirX, cDirZ
end
function FieldCourseUtil.getClosestExtendedPositionAndDirectionOnSegment(x, z, positions, maxExtension)
    local numPositions = #positions
    local minDistance = math.huge
    local cx = nil
    local cz = nil
    local cDirX = nil
    local cDirZ = nil
    local i = 1
    local sx = numPositions - 1
    local sz = 1
    for i = i, sx, sz do
        local sx = positions[i][1]
        local sz = positions[i][2]
        local ex = positions[i + 1][1]
        local ez = positions[i + 1][2]
        local dirX = ex - sx
        local dirZ = ez - sz
        local length = MathUtil.vector2Length(dirX, dirZ)
        local dirX = dirX / length
        local dirZ = dirZ / length
        local dot = MathUtil.getProjectOnLineParameter(x, z, sx, sz, dirX, dirZ)
        local ix, iz, distance
        if dot >= 0 and dot <= length then
            ix = sx + dirX * dot
            iz = sz + dirZ * dot
            distance = MathUtil.vector2Length(ix - x, iz - z)
            if distance < minDistance then
                cDirZ = dirZ
                cDirX = dirX
            else
                iz = cz
                ix = cx
                distance = minDistance
            end
        else
            iz = cz
            ix = cx
            distance = minDistance
        end
        local ix = MathUtil.vector2Length(sx - x, sz - z)
        if ix < distance then
            cDirZ = dirZ
            cDirX = dirX
        else
            sz = iz
            sx = ix
        end
        minDistance = MathUtil.vector2Length(ex - x, ez - z)
        if minDistance < ix then
            cDirZ = dirZ
            cDirX = dirX
            cz = ez
            cx = ex
        else
            cz = sz
            cx = sx
            minDistance = ix
        end
    end
    local sx = positions[1][1]
    local sz = positions[1][2]
    local i = positions[2][1]
    local sx = positions[2][2]
    local sz, ex = MathUtil.vector2Normalize(sx - i, sz - sx)
    local ez = MathUtil.getProjectOnLineParameter(x, z, sx, sz, sz, ex)
    local dirX, dirZ, length
    if ez > 0 then
        local dirX = math.min(ez, maxExtension)
        dirX = sx + sz * dirX
        dirZ = sz + ex * dirX
        length = MathUtil.vector2Length(dirX - x, dirZ - z)
        if length >= minDistance then
            sz = cz
            sx = cx
            ex = cDirZ
            sz = cDirX
            dirZ = sz
            dirX = sx
            length = minDistance
            sz = dirZ
            sx = dirX
            dirZ = sz
            dirX = sx
        end
    else
        sz = cz
        sx = cx
        ex = cDirZ
        sz = cDirX
        dirZ = sz
        dirX = sx
        length = minDistance
        sz = dirZ
        sx = dirX
        dirZ = sz
        dirX = sx
    end
    local sx = positions[numPositions][1]
    local sz = positions[numPositions][2]
    local i = positions[numPositions - 1][1]
    local sx = positions[numPositions - 1][2]
    local dirX, dirZ = MathUtil.vector2Normalize(sx - i, sz - sx)
    local dirX = MathUtil.getProjectOnLineParameter(x, z, sx, sz, dirX, dirZ)
    local dirX, dirZ
    if dirX > 0 then
        local dirX = math.min(dirX, maxExtension)
        dirX = sx + dirX * dirX
        dirZ = sz + dirZ * dirX
        if MathUtil.vector2Length(dirX - x, dirZ - z) >= length then
        end
    end
    return dirX, dirZ, dirX, dirZ, sx, sz
end
function FieldCourseUtil.getSegmentLength(positions)
    local length = 0
    local i = 1
    for i = i, #positions - 1 do
        length = length + MathUtil.vector2Length(positions[i + 1][1] - positions[i][1], positions[i + 1][2] - positions[i][2])
    end
    return length
end
function FieldCourseUtil.extendSegment(positions, direction, offset)
    if direction > 0 then
        local p1 = positions[#positions - 1]
        local p2 = positions[#positions]
        local dirX = p2[1] - p1[1]
        local dirZ = p2[2] - p1[2]
        local length = MathUtil.vector2Length(dirX, dirZ)
        local dirX = dirX / length
        local dirZ = dirZ / length
        if offset >= 0 then
            p2[1] = p2[1] + dirX * offset
            p2[2] = p2[2] + dirZ * offset
            return
        end
        if length >= -offset then
            p2[1] = p2[1] + dirX * offset
            p2[2] = p2[2] + dirZ * offset
            return
        end
        if #positions > 2 then
            table.remove(positions, #positions)
            FieldCourseUtil.extendSegment(positions, direction, offset + length)
            return
        end
    else
        local p1 = positions[1]
        local p2 = positions[2]
        local dirX = p1[1] - p2[1]
        local dirZ = p1[2] - p2[2]
        local length = MathUtil.vector2Length(dirX, dirZ)
        local dirX = dirX / length
        local dirZ = dirZ / length
        if offset < 0 then
            if length >= -offset then
                p1[1] = p1[1] + dirX * offset
                p1[2] = p1[2] + dirZ * offset
                return
            end
            if #positions > 2 then
                table.remove(positions, 1)
                FieldCourseUtil.extendSegment(positions, direction, offset + length)
                return
            end
        else
            p1[1] = p1[1] + dirX * offset
            p1[2] = p1[2] + dirZ * offset
        end
    end
end
function FieldCourseUtil.extendSegmentToBoundary(positions, boundary, extendStart, extendEnd, maxDistance)
    maxDistance = maxDistance or math.huge
    if extendStart ~= false then
        local p1 = positions[1]
        local p2 = positions[2]
        local length = MathUtil.vector2Length(p1[1] - p2[1], p1[2] - p2[2])
        local intersect1, ix1, iz1 = FieldCourseUtil.getSegmentBoundaryIntersection(p1[1], p1[2], p1[1] + dirX / length * 65535, p1[2] + dirZ / length * 65535, boundary)
        if intersect1 and MathUtil.vector2Length(ix1 - p1[1], iz1 - p1[2]) < maxDistance then
            p1[1] = ix1
            p1[2] = iz1
        end
    end
    if extendEnd ~= false then
        local p1 = positions[#positions]
        local p2 = positions[#positions - 1]
        local length = MathUtil.vector2Length(p1[1] - p2[1], p1[2] - p2[2])
        local intersect1, ix1, iz1 = FieldCourseUtil.getSegmentBoundaryIntersection(p1[1], p1[2], p1[1] + dirX / length * 65535, p1[2] + dirZ / length * 65535, boundary)
        if intersect1 and MathUtil.vector2Length(ix1 - p1[1], iz1 - p1[2]) < maxDistance then
            p1[1] = ix1
            p1[2] = iz1
        end
    end
end
function FieldCourseUtil.extendSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, distanceToAdjust, step)
    local pos1 = positions[1]
    local pos2 = positions[2]
    if direction == 1 then
        local numPositions = #positions
        pos1 = positions[numPositions]
        pos2 = positions[numPositions - 1]
    end
    local numPositions, dz = MathUtil.vector2Normalize(pos1[1] - pos2[1], pos1[2] - pos2[2])
    local overlap1 = false
    local overlap2 = false
    for otherGroupIndex, otherLines in pairs(lines) do
        if groupIndex ~= otherGroupIndex then
            for _, otherLine in ipairs(otherLines) do
                overlap1 = FieldCourseUtil.getPositionSegmentOverlap(pos1[1] + dz * sideOffset, pos1[2] - numPositions * sideOffset, otherLine.positions, sideOffset) and true or overlap1
                overlap2 = FieldCourseUtil.getPositionSegmentOverlap(pos1[1] - dz * sideOffset, pos1[2] + numPositions * sideOffset, otherLine.positions, sideOffset) and true or overlap2
                if overlap1 and overlap2 then
                    break
                end
            end
        end
        if overlap1 and overlap2 then
            break
        end
    end
    if not (overlap1 and overlap2) then
        for otherGroupIndex, otherLines in ipairs(islands) do
            for _, otherLine in ipairs(otherLines.boundaries) do
                local i = 1
                for i = i, #otherLine.segments do
                    local otherLine = otherLine.segments[i]
                    overlap1 = FieldCourseUtil.getPositionSegmentOverlap(x1, z1, otherLine.positions, sideOffset) and true or overlap1
                    overlap2 = FieldCourseUtil.getPositionSegmentOverlap(x2, z2, otherLine.positions, sideOffset) and true or overlap2
                    if overlap1 and overlap2 then
                        break
                    end
                end
                if overlap1 and overlap2 then
                    break
                end
            end
            if overlap1 and overlap2 then
                break
            end
        end
    end
    if not (overlap1 and overlap2) then
        for otherGroupIndex, otherLines in ipairs(boundaries) do
            local i = 1
            for i = i, #otherLines.segments do
                local _ = otherLines.segments[i]
                overlap1 = FieldCourseUtil.getPositionSegmentOverlap(x1, z1, _.positions, sideOffset) and true or overlap1
                overlap2 = FieldCourseUtil.getPositionSegmentOverlap(x2, z2, _.positions, sideOffset) and true or overlap2
                if overlap1 and overlap2 then
                    break
                end
            end
            if overlap1 and overlap2 then
                break
            end
        end
    end
    if not (overlap1 and overlap2) then
        distanceToAdjust = distanceToAdjust - step
        if distanceToAdjust > 0 then
            FieldCourseUtil.extendSegment(positions, direction, step)
            FieldCourseUtil.extendSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, distanceToAdjust, step)
        end
    end
end
function FieldCourseUtil.shrinkSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, distanceToAdjust, step)
    local pos1 = positions[1]
    local pos2 = positions[2]
    if direction == 1 then
        local numPositions = #positions
        pos1 = positions[numPositions]
        pos2 = positions[numPositions - 1]
    end
    local numPositions, dz = MathUtil.vector2Normalize(pos1[1] - pos2[1], pos1[2] - pos2[2])
    local overlap1 = false
    local overlap2 = false
    for otherGroupIndex, otherLines in pairs(lines) do
        if groupIndex ~= otherGroupIndex then
            for _, otherLine in ipairs(otherLines) do
                overlap1 = FieldCourseUtil.getPositionSegmentOverlap(pos1[1] + dz * sideOffset, pos1[2] - numPositions * sideOffset, otherLine.positions, sideOffset) and true or overlap1
                overlap2 = FieldCourseUtil.getPositionSegmentOverlap(pos1[1] - dz * sideOffset, pos1[2] + numPositions * sideOffset, otherLine.positions, sideOffset) and true or overlap2
                if overlap1 and overlap2 then
                    break
                end
            end
        end
        if overlap1 and overlap2 then
            break
        end
    end
    if not (overlap1 and overlap2) then
        for otherGroupIndex, otherLines in ipairs(islands) do
            for _, otherLine in ipairs(otherLines.boundaries) do
                local i = 1
                for i = i, #otherLine.segments do
                    local otherLine = otherLine.segments[i]
                    overlap1 = FieldCourseUtil.getPositionSegmentOverlap(x1, z1, otherLine.positions, sideOffset) and true or overlap1
                    overlap2 = FieldCourseUtil.getPositionSegmentOverlap(x2, z2, otherLine.positions, sideOffset) and true or overlap2
                    if overlap1 and overlap2 then
                        break
                    end
                end
                if overlap1 and overlap2 then
                    break
                end
            end
            if overlap1 and overlap2 then
                break
            end
        end
    end
    if not (overlap1 and overlap2) then
        for otherGroupIndex, otherLines in ipairs(boundaries) do
            local i = 1
            for i = i, #otherLines.segments do
                local _ = otherLines.segments[i]
                overlap1 = FieldCourseUtil.getPositionSegmentOverlap(x1, z1, _.positions, sideOffset) and true or overlap1
                overlap2 = FieldCourseUtil.getPositionSegmentOverlap(x2, z2, _.positions, sideOffset) and true or overlap2
                if overlap1 and overlap2 then
                    break
                end
            end
            if overlap1 and overlap2 then
                break
            end
        end
    end
    if overlap1 and overlap2 then
        distanceToAdjust = distanceToAdjust - step
        if distanceToAdjust >= 0 then
            if FieldCourseUtil.getSegmentLength(positions) <= step + 1 then
                return
            end
            FieldCourseUtil.extendSegment(positions, direction, -step)
            FieldCourseUtil.shrinkSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, distanceToAdjust, step)
        end
    end
end
function FieldCourseUtil.extendSegmentPositions(segment, toolFrontOffset)
    if toolFrontOffset > 0 then
        local i = #segment.positions - 1
        for i = i, 2, -1 do
            local p1 = segment.positions[i - 1]
            local p2 = segment.positions[i]
            local p3 = segment.positions[i + 1]
            local x = p2[1]
            local z = p2[2]
            local length1 = MathUtil.vector2Length(x - p1[1], z - p1[2])
            local length2 = MathUtil.vector2Length(p3[1] - x, p3[2] - z)
            local offset1 = math.min(length1 * 0.5, toolFrontOffset)
            local offset2 = math.min(length2 * 0.5, toolFrontOffset)
            p2[1] = x - dx1 / length1 * offset1
            p2[2] = z - dz1 / length1 * offset1
            table.insert(segment.positions, i + 1, { x + dx2 / length2 * offset2, z + dz2 / length2 * offset2 })
        end
    end
end
function FieldCourseUtil.segmentApplySideOffset(segment, sideOffset)
    local numPositions = #segment.positions
    local i = 1
    for i = i, numPositions - 1 do
        local p1 = segment.positions[i]
        local p2 = segment.positions[i + 1]
        local dx, dz = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
        p1[1] = p1[1] + dz * sideOffset
        p1[2] = p1[2] - dx * sideOffset
        if i + 1 == numPositions then
            p2[1] = p2[1] + dz * sideOffset
            p2[2] = p2[2] - dx * sideOffset
        end
    end
    return true
end
function FieldCourseUtil.removeShortSegments(boundaryLine, threshold, isLoop)
    local posIndex = #boundaryLine - 1
    for posIndex = posIndex, 1, -1 do
        local pos1 = boundaryLine[posIndex]
        local pos2 = boundaryLine[posIndex + 1]
        if MathUtil.vector2Length(pos2[1] - pos1[1], pos2[2] - pos1[2]) < threshold then
            table.remove(boundaryLine, posIndex)
            if posIndex == 1 and isLoop ~= false then
                boundaryLine[1] = table.clone(boundaryLine[#boundaryLine])
            end
        end
    end
    return false
end