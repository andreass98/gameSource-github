BoundaryLineGenerationTask = {}
local BoundaryLineGenerationTask_mt = Class(BoundaryLineGenerationTask)
function BoundaryLineGenerationTask.new(boundaryLine, sx, sz, dirX, dirZ, islands, fieldCourseSettings, callback)
    -- upvalues: (copy) BoundaryLineGenerationTask_mt
    local yRot = BoundaryLineGenerationTask_mt
    local self = setmetatable({}, yRot)
    local forceStraightLines = false
    if fieldCourseSettings.workDirection >= 0 then
        dirX, dirZ = MathUtil.getDirectionFromYRotation(fieldCourseSettings.workDirection)
        forceStraightLines = true
    end
    if fieldCourseSettings.rowSpacing ~= 0 and fieldCourseSettings.workDirection < 0 then
        local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
        local snapAngle = fieldCourseSettings.rowSnapAngle
        if snapAngle == 0 then
            snapAngle = g_currentMission.fieldGroundSystem:getGroundAngleStep()
        end
        if snapAngle > 0 then
            local yRot = MathUtil.round(yRot / snapAngle) * snapAngle
            dirX, dirZ = MathUtil.getDirectionFromYRotation(yRot)
            forceStraightLines = true
        end
    end
    local yRot, snapAngle, intersect, t1, _ = BoundaryLineGenerationTask.getFurthestPointToLine(sx, sz, dirX, dirZ, boundaryLine)
    self.sx = yRot
    self.sz = snapAngle
    self.offsetDirX = intersect
    self.offsetDirZ = t1
    self.distanceToCheck = _
    if self.sx == nil then
        return nil
    end
    if fieldCourseSettings.rowSpacing ~= 0 then
        local intersect, t1, _ = MathUtil.getLineLineIntersection2D(self.sx, self.sz, self.offsetDirX, self.offsetDirZ, -g_currentMission.terrainSize * 0.5, -g_currentMission.terrainSize * 0.5, dirX, dirZ)
        if intersect then
            local offset = MathUtil.round(t1 / fieldCourseSettings.rowSpacing) * fieldCourseSettings.rowSpacing - t1
            if MathUtil.round(fieldCourseSettings.implementWidth / fieldCourseSettings.rowSpacing) % 2 ~= 0 then
            end
            local offset = offset + fieldCourseSettings.rowOffset
            self.sx = self.sx - self.offsetDirX * offset
            self.sz = self.sz - self.offsetDirZ * offset
        end
    end
    local snapAngle = fieldCourseSettings.segmentSplitAngle
    self.segmentSplitAngle = math.rad(snapAngle)
    self.boundary = FieldCourseBoundary.createByBoundaryLine(boundaryLine, self.segmentSplitAngle)
    if self.boundary == nil then
        Logging.warning("BoundaryLineGenerationTask: Failed to create boundary from boundary line")
        return nil
    end
    self.boundaryLine = self.boundary.boundaryLine
    self.dirX = dirX
    self.dirZ = dirZ
    self.islands = islands
    self.lineToLineDistance = fieldCourseSettings.implementWidth
    self.segmentMinOffset = fieldCourseSettings.segmentMinOffset or 0
    self.segmentMinLength = fieldCourseSettings.segmentMinLength or 0
    self.callback = callback
    local yRot = self.sx + self.offsetDirX * self.lineToLineDistance * 0.5
    local snapAngle = self.sz + self.offsetDirZ * self.lineToLineDistance * 0.5
    self.curX = yRot
    self.curZ = snapAngle
    self.hasFinished = false
    local yRot = 0
    self.rootSegment = nil
    if not forceStraightLines then
        for _, roundedT1 in ipairs(self.boundary.segments) do
            local offset, angleSum = BoundaryLineGenerationTask.getSegmentsAngleData(roundedT1.positions)
            if offset < self.segmentSplitAngle then
                local length = FieldCourseUtil.getSegmentLength(roundedT1.positions)
                local factor = length * (1 - math.min(angleSum / length / 0.005, 1) * 0.66)
                if yRot < factor then
                    self.rootSegment = roundedT1
                    yRot = factor
                end
            end
        end
    end
    self.detectStraightLines = true
    self.offsetLineIndex = 0
    self.straightLines = {}
    self.contourLines = {}
    if self.rootSegment ~= nil then
        self.detectStraightLines = false
        self.lastContourLine = self.rootSegment.positions
        local snapAngle = self.lastContourLine[1]
        local intersect = self.lastContourLine[2]
        local t1, _ = MathUtil.vector2Normalize(snapAngle[1] - intersect[1], snapAngle[2] - intersect[2])
        snapAngle[1] = snapAngle[1] + t1 * 65535
        snapAngle[2] = snapAngle[2] + _ * 65535
        local snapAngle = self.lastContourLine[#self.lastContourLine]
        local intersect = self.lastContourLine[#self.lastContourLine - 1]
        local roundedT1, offset = MathUtil.vector2Normalize(snapAngle[1] - intersect[1], snapAngle[2] - intersect[2])
        snapAngle[1] = snapAngle[1] + roundedT1 * 65535
        snapAngle[2] = snapAngle[2] + offset * 65535
        self.contourExtensionDirection = 1
    end
    return self
end
function BoundaryLineGenerationTask:update(_, frameBudget)
    if self.detectStraightLines then
        local success = getTimeSec()
        while getTimeSec() - success < frameBudget do
            self.offsetLineIndex = self.offsetLineIndex + 1
            BoundaryLineGenerationTask.detectInsideBoundaryLines(self.straightLines, self.curX, self.curZ, self.dirX, self.dirZ, self.boundaryLine, self.islands, self.offsetLineIndex)
            local lines = self.curX + self.offsetDirX * self.lineToLineDistance
            local numContourLines = self.curZ + self.offsetDirZ * self.lineToLineDistance
            self.curX = lines
            self.curZ = numContourLines
            self.distanceToCheck = self.distanceToCheck - self.lineToLineDistance
            if self.distanceToCheck <= 0 then
                self.hasFinished = true
                local lines = self.straightLines
                if self.contourLines ~= nil then
                    local numContourLines = #self.contourLines
                    if numContourLines > 0 then
                        if numContourLines - #self.straightLines <= math.max(numStraightLines * 0.15, 1) then
                            lines = self.contourLines
                        end
                    end
                end
                if self.segmentMinOffset > 0 then
                    BoundaryLineGenerationTask.removeMinOffsetLines(lines, self.boundaryLine, self.segmentMinOffset)
                end
                if self.segmentMinLength > 0 then
                    local i = #lines
                    for i = i, 1, -1 do
                        if FieldCourseUtil.getSegmentLength(lines[i].positions) < self.segmentMinLength then
                            table.remove(lines, i)
                        end
                    end
                end
                if self.callback ~= nil then
                    self.callback(lines)
                end
                break
            end
        end
    else
        local startTime = getTimeSec()
        while getTimeSec() - startTime < frameBudget do
            if self.contourExtensionDirection == 1 then
                if #self.contourLines == 0 then
                    self:extendContourLine(0.01, self.offsetLineIndex)
                    self.initialContourLine = self.contourLines[1]
                end
                self.offsetLineIndex = self.offsetLineIndex + 1
                local continueGeneration, success = self:extendContourLine(self.lineToLineDistance, self.offsetLineIndex)
                if self.initialContourLine ~= nil then
                    table.remove(self.contourLines, 1)
                    self.initialContourLine = nil
                end
                if not continueGeneration then
                    if not success then
                        self.detectStraightLines = true
                        self.contourLines = nil
                        break
                    end
                    self:extendContourLine(0.5, self.offsetLineIndex)
                    self.lastContourLine = self.rootSegment.positions
                    self.contourExtensionDirection = -1
                    self.offsetLineIndex = 0
                    self:extendContourLine(-0.01, self.offsetLineIndex)
                end
            else
                self.offsetLineIndex = self.offsetLineIndex - 1
                local continueGeneration, success = self:extendContourLine(-self.lineToLineDistance, self.offsetLineIndex)
                if not continueGeneration then
                    if not success then
                        self.contourLines = nil
                    end
                    self.detectStraightLines = true
                    self.offsetLineIndex = 0
                    break
                end
            end
        end
    end
    return not self.hasFinished
end
function BoundaryLineGenerationTask:extendContourLine(lineToLineDistance, offsetLineIndex)
    local contourLine = FieldCourseBoundary.getOffsetBoundaryLine(self.lastContourLine, lineToLineDistance, 0.25)
    if contourLine == nil then
        return false, false
    end
    FieldCourseUtil.removeShortSegments(contourLine, 0.25)
    FieldCourseUtil.douglasPeucker(contourLine, 0.25)
    if not FieldCourseBoundary.resolveSelfIntersections(contourLine) then
        return false, false
    end
    if FieldCourseUtil.getSegmentLength(contourLine) < 0.25 then
        return false, true
    end
    local maxAngle, _ = BoundaryLineGenerationTask.getSegmentsAngleData(contourLine)
    if self.segmentSplitAngle < maxAngle then
        return false, false
    end
    FieldCourseUtil.douglasPeucker(contourLine, 0.25)
    self.lastContourLine = contourLine
    return BoundaryLineGenerationTask.resolveBoundaryIntersections(self.contourLines, contourLine, self.boundaryLine, self.islands, offsetLineIndex), true
end
function BoundaryLineGenerationTask.getFurthestPointToLine(x, z, dirX, dirZ, boundary)
    x = x - dirZ * 4096
    z = z + dirX * 4096
    local minDistance = math.huge
    local minDistancePoint = 0
    local maxDistance = 0
    local maxDistancePoint = 0
    local offsetDirX = nil
    local offsetDirZ = nil
    local i = 1
    local distance = #boundary
    for i = i, distance do
        local x1 = boundary[i][1]
        local z1 = boundary[i][2]
        local x2, z2 = MathUtil.projectOnLine(x1, z1, x, z, dirX, dirZ)
        local distance = MathUtil.vector2Length(x2 - x1, z2 - z1)
        if maxDistance < distance then
            offsetDirX = (x2 - x1) / distance
            offsetDirZ = (z2 - z1) / distance
            maxDistancePoint = i
            maxDistance = distance
        end
        if distance < minDistance then
            minDistancePoint = i
            minDistance = distance
        end
    end
    if minDistancePoint <= 0 or maxDistancePoint <= 0 then
        return nil
    end
    local distance = maxDistance - minDistance
    return boundary[maxDistancePoint][1], boundary[maxDistancePoint][2], offsetDirX, offsetDirZ, distance
end
function BoundaryLineGenerationTask.detectInsideBoundaryLines(lines, x, z, dirX, dirZ, boundary, islands, offsetLineIndex)
    local intersections = {}
    local i = 1
    local foundIntersections = 1
    for i = i, #boundary - 1, foundIntersections do
        local intersect, ix, iz = MathUtil.getLineSegmentsIntersection(boundary[i][1], boundary[i][2], boundary[i + 1][1], boundary[i + 1][2], x - dirX * 65535, z - dirZ * 65535, x + dirX * 65535, z + dirZ * 65535)
        if intersect then
            table.insert(intersections, { ix, iz })
        end
    end
    for intersect, ix in ipairs(islands) do
        local innerBoundaryLine = (ix.boundaries[#ix.boundaries] or ix.innerBoundary).boundaryLine
        local i = 1
        for i = i, #innerBoundaryLine - 1 do
            local intersect, ix, iz = MathUtil.getLineSegmentsIntersection(innerBoundaryLine[i][1], innerBoundaryLine[i][2], innerBoundaryLine[i + 1][1], innerBoundaryLine[i + 1][2], sx, sz, ex, ez)
            if intersect then
                if FieldCourseUtil.getIsPointInsideBoundary(ix, iz, boundary) then
                    table.insert(intersections, { ix, iz })
                else
                    table.insert(intersections, { ix, iz, true })
                end
            end
        end
    end
    table.sort(intersections, function(a, b)
        return a[1] + a[2] < b[1] + b[2]
    end)
    if #intersections % 2 ~= 0 then
        return false
    end
    local foundIntersections = false
    local ix = 1
    local i = numIntersections - 1
    local intersect = 2
    for ix = ix, i, intersect do
        if intersections[ix][3] ~= true and intersections[ix + 1][3] ~= true then
            table.insert(lines, {
                ["offsetLineIndex"] = offsetLineIndex,
                ["positions"] = { intersections[ix], intersections[ix + 1] }
            })
            foundIntersections = true
        end
    end
    return foundIntersections
end
function BoundaryLineGenerationTask.removeMinOffsetLines(lines, boundary, minOffset)
    local i = #lines
    for i = i, 1, -1 do
        local line = lines[i]
        local isIntersecting = true
        local j = 1
        for j = j, #line.positions - 1 do
            local p1 = line.positions[j]
            local p2 = line.positions[j + 1]
            local dx, dz = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
            local offset = 0.25
            for offset = offset, 0.75, 0.25 do
                local intersect = MathUtil.lerp(p1[1], p2[1], offset)
                local cz = MathUtil.lerp(p1[2], p2[2], offset)
                local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(intersect + dz * minOffset, cz - dx * minOffset, intersect - dz * minOffset, cz + dx * minOffset, boundary)
                if not intersect then
                    isIntersecting = false
                    break
                end
            end
            if not isIntersecting then
                break
            end
        end
        if isIntersecting then
            table.remove(lines, i)
        end
    end
end
function BoundaryLineGenerationTask.getNumBoundaryLines(x, z, dirX, dirZ, boundary)
    local numIntersections = 0
    local i = 1
    for i = i, #boundary - 1 do
        local intersect, _, _ = MathUtil.getLineSegmentsIntersection(boundary[i][1], boundary[i][2], boundary[i + 1][1], boundary[i + 1][2], x - dirX * 65535, z - dirZ * 65535, x + dirX * 65535, z + dirZ * 65535)
        if intersect then
        end
    end
    return numIntersections % 2 ~= 0 and 0 or numIntersections / 2
end
function BoundaryLineGenerationTask.getOptimalBoundaryAngle(centerX, centerZ, boundary, steps)
    local minLineAmount = math.huge
    local minLineAngle = 0
    local angle = 0
    for angle = angle, 3.1315926535897933, 3.141592653589793 / steps do
        local numLines = BoundaryLineGenerationTask.getNumLinesByAngle(centerX, centerZ, boundary, angle)
        if numLines < minLineAmount then
            minLineAngle = angle
            minLineAmount = numLines
        end
    end
    return minLineAngle
end
function BoundaryLineGenerationTask.getNumLinesByAngle(centerX, centerZ, boundary, angle)
    local dirX, dirZ = MathUtil.getDirectionFromYRotation(angle)
    local sx, sz, offsetDirX, offsetDirZ, distance = BoundaryLineGenerationTask.getFurthestPointToLine(centerX, centerZ, dirX, dirZ, boundary, true)
    if sx == nil then
        return 0
    end
    local sx = sx + offsetDirX * 0.1
    local sz = sz + offsetDirZ * 0.1
    local numLines = 0
    while true do
        sx = sx + offsetDirX * 10
        sz = sz + offsetDirZ * 10
        local newLines = BoundaryLineGenerationTask.getNumBoundaryLines(sx, sz, dirX, dirZ, boundary)
        if newLines > 0 then
        end
        distance = distance - 10
        if distance <= 0 then
            return numLines
        end
    end
end
function BoundaryLineGenerationTask.resolveBoundaryIntersections(lines, line, boundary, islands, offsetLineIndex)
    local isValid = false
    local remainingLine = nil
    local i = 1
    for i = i, #line - 1 do
        local p1 = line[i]
        local p2 = line[i + 1]
        local dx, dz = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
        local intersect, ix1, iz1 = BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(p1[1], p1[2], p2[1], p2[2], boundary, islands)
        if intersect then
            local intersect, ix2, iz2 = BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(ix1 + dx * 0.0001, iz1 + dz * 0.0001, p2[1], p2[2], boundary, islands)
            local hitIndex, dz, dx
            if intersect then
                hitIndex = i
            else
                local j = i + 1
                hitIndex = i
                for j = j, #line - 1 do
                    local sp1 = line[j]
                    local sp2 = line[j + 1]
                    dx, dz = MathUtil.vector2Normalize(sp2[1] - sp1[1], sp2[2] - sp1[2])
                    intersect, ix2, iz2 = BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(sp1[1], sp1[2], sp2[1], sp2[2], boundary, islands)
                    if intersect then
                        hitIndex = j
                        break
                    end
                end
            end
            if intersect then
                local newLine = {
                    ["offsetLineIndex"] = offsetLineIndex,
                    ["positions"] = {}
                }
                local j = newLine.positions
                local sp1 = { ix1 + dx * 0.0001, iz1 + dz * 0.0001 }
                table.insert(j, sp1)
                local sp1 = i + 1
                local j = 1
                for sp1 = sp1, hitIndex, j do
                    table.insert(newLine.positions, line[sp1])
                end
                local j = newLine.positions
                local sp1 = { ix2 - dx * 0.0001, iz2 - dz * 0.0001 }
                table.insert(j, sp1)
                table.insert(lines, newLine)
                isValid = true
                if #line - hitIndex > 0 then
                    remainingLine = {}
                    local sp1 = { ix2 + dx * 0.0001, iz2 + dz * 0.0001 }
                    table.insert(remainingLine, sp1)
                    local sp1 = hitIndex + 1
                    for sp1 = sp1, #line do
                        table.insert(remainingLine, line[sp1])
                    end
                end
            end
        end
    end
    if isValid and remainingLine ~= nil then
        BoundaryLineGenerationTask.resolveBoundaryIntersections(lines, remainingLine, boundary, islands, offsetLineIndex)
    end
    return isValid
end
function BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(l1x, l1z, l2x, l2z, boundary, islands)
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
    for sx, sz in ipairs(islands) do
        local ez = (sz.boundaries[#sz.boundaries] or sz.innerBoundary).boundaryLine
        local z = 1
        local intersect = #ez - 1
        local x = 1
        for z = z, intersect, x do
            local distance = ez[z][1]
            local sz = ez[z][2]
            local ex = ez[z + 1][1]
            local ez = ez[z + 1][2]
            local intersect, x, z = MathUtil.getLineSegmentsIntersection(distance, sz, ex, ez, l1x, l1z, l2x, l2z)
            if intersect then
                local distance = MathUtil.vector2Length(l1x - x, l1z - z)
                if distance < minDistance then
                    pez = ez
                    pex = ex
                    psz = sz
                    psx = distance
                    iz = z
                    ix = x
                    minDistance = distance
                end
            end
        end
    end
    return minDistance ~= math.huge, ix, iz, psx, psz, pex, pez
end
function BoundaryLineGenerationTask.getSegmentsAngleData(positions)
    if #positions <= 2 then
        return 0, 0
    end
    local maxRotDifference = 0
    local angleSum = 0
    local i = 1
    for i = i, #positions - 2 do
        local p1 = positions[i]
        local p2 = positions[i + 1]
        local p3 = positions[i + 2]
        local yRot1 = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2]))
        local rotDifference = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(p3[1] - p2[1], p3[2] - p2[2])) - yRot1
        if rotDifference > 3.141592653589793 then
        end
        maxRotDifference = math.max(maxRotDifference, (math.abs(rotDifference)))
        angleSum = angleSum + math.abs(rotDifference)
    end
    return maxRotDifference, angleSum
end