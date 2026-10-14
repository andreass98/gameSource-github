AIFieldCourseTurnGenerator = {}
local AIFieldCourseTurnGenerator_mt = Class(AIFieldCourseTurnGenerator)
function AIFieldCourseTurnGenerator.new(aiFieldCourse, _)
    -- upvalues: (copy) AIFieldCourseTurnGenerator_mt
    local self = setmetatable({}, AIFieldCourseTurnGenerator_mt)
    self.aiFieldCourse = aiFieldCourse
    self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
    self.alternativeTurnSegments = aiFieldCourse.alternativeTurnSegments
    self.state = AIFieldCourseTurnGeneratorState.INITIAL
    self.offsetTurns = {}
    self.ignoreBoundaryIntersections = false
    self.allowProtectedBoundary = false
    self.preferOneDrivingDirection = false
    self.forcedDrivingDirection = 0
    self.maxOffset = nil
    self.overwrittenTurnRadius = nil
    return self
end
function AIFieldCourseTurnGenerator:setCallback(callback, callbackTarget)
    self.callback = callback
    self.callbackTarget = callbackTarget
end
function AIFieldCourseTurnGenerator:setIgnoreBoundaryIntersections(ignoreBoundaryIntersections)
    self.ignoreBoundaryIntersections = ignoreBoundaryIntersections
end
function AIFieldCourseTurnGenerator:setAllowProtectedBoundary(allowProtectedBoundary)
    self.allowProtectedBoundary = allowProtectedBoundary
end
function AIFieldCourseTurnGenerator:setPreferOneDrivingDirection(preferOneDrivingDirection)
    self.preferOneDrivingDirection = preferOneDrivingDirection
end
function AIFieldCourseTurnGenerator:setForcedDrivingDirection(forcedDrivingDirection)
    self.forcedDrivingDirection = forcedDrivingDirection or 0
end
function AIFieldCourseTurnGenerator:setMaxOffset(maxOffset)
    self.maxOffset = maxOffset
end
function AIFieldCourseTurnGenerator:setOverwrittenTurnRadius(overwrittenTurnRadius)
    self.overwrittenTurnRadius = overwrittenTurnRadius
end
function AIFieldCourseTurnGenerator:generateSegmentToSegment(segment1, direction1, segment2, direction2)
    self.segment1 = segment1
    self.direction1 = direction1
    self.segment2 = segment2
    self.direction2 = direction2
    local sx, sz, sDirX, sDirZ = AIFieldCourseUtil.getSegmentPositionAndDirection(false, segment1, direction1)
    local ex, ez, eDirX, eDirZ = AIFieldCourseUtil.getSegmentPositionAndDirection(true, segment2, direction2)
    local turnData = AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, segment1, direction1, segment2, direction2, self.aiFieldCourse, self.overwrittenTurnRadius)
    local startOffset = nil
    if AIFieldCourseTurnGenerator.isPositionOutsideField(sx, sz, turnData, true) then
        startOffset = AIFieldCourseTurnGenerator.getSegmentMinOffset(true, segment1, direction1, turnData, self.fieldCourseSettings.minTurnRadius * 2)
        if startOffset ~= nil then
            turnData = turnData:offset(startOffset, nil)
        end
    end
    if AIFieldCourseTurnGenerator.isPositionOutsideField(ex, ez, turnData, true) then
        local endOffset = AIFieldCourseTurnGenerator.getSegmentMinOffset(false, segment2, direction2, turnData, (math.min(self.fieldCourseSettings.minTurnRadius * 2, segment2.length)))
        if endOffset ~= nil then
            turnData = turnData:offset(startOffset, endOffset)
        end
    end
    self.state = AIFieldCourseTurnGeneratorState.DEFAULT
    self.originalTurnData = turnData
    g_fieldCourseManager:addUpdateable(self)
end
function AIFieldCourseTurnGenerator:generatePositionToSegment(sx, sz, sDirX, sDirZ, segment2, direction2)
    self.segment2 = segment2
    self.direction2 = direction2
    local ex, ez, eDirX, eDirZ = AIFieldCourseUtil.getSegmentPositionAndDirection(true, segment2, direction2)
    local turnData = AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, nil, nil, segment2, direction2, self.aiFieldCourse, self.overwrittenTurnRadius)
    self.state = AIFieldCourseTurnGeneratorState.DEFAULT
    self.originalTurnData = turnData
    g_fieldCourseManager:addUpdateable(self)
end
function AIFieldCourseTurnGenerator:generatePositionToPosition(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ)
    local turnData = AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, nil, nil, nil, nil, self.aiFieldCourse, self.overwrittenTurnRadius)
    self.state = AIFieldCourseTurnGeneratorState.DEFAULT
    self.originalTurnData = turnData
    g_fieldCourseManager:addUpdateable(self)
end
function AIFieldCourseTurnGenerator:onFinished(turn)
    self.state = AIFieldCourseTurnGeneratorState.FINISHED
    g_fieldCourseManager:removeUpdateable(self)
    if self.callback ~= nil then
        if self.callbackTarget ~= nil then
            self.callback(self.callbackTarget, turn)
            return
        end
        self.callback(turn)
    end
end
function AIFieldCourseTurnGenerator:update(_)
    local startTime = getTimeSec()
    while getTimeSec() - startTime < 0.0005 do
        if self.state == AIFieldCourseTurnGeneratorState.DEFAULT then
            local minCostTurn, _ = self:getBestTurnByTurnData(self.originalTurnData)
            if minCostTurn ~= nil then
                self:onFinished(minCostTurn)
                return
            end
            self.defaultStartOffset = self.originalTurnData.startOffset or 3
            self.defaultEndOffset = self.originalTurnData.endOffset or 3
            local i = #self.offsetTurns
            for i = i, 1, -1 do
                self.offsetTurns[i] = nil
            end
            self.startOffsetLimit = self.fieldCourseSettings.minTurnRadius * 6
            self.endOffsetLimit = self.fieldCourseSettings.minTurnRadius * 6
            if not (self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing) then
                self.startOffsetLimit = self.segment1 ~= nil and self.segment1.length - (self.segment1.lastStartOffset or 0) or self.startOffsetLimit
                self.endOffsetLimit = self.segment2 ~= nil and self.segment2.length - (self.segment2.lastEndOffset or 0) or self.endOffsetLimit
            end
            self.startOffset = self.defaultStartOffset
            self.endOffset = self.defaultEndOffset
            self.state = AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT
        elseif self.state == AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT or self.state == AIFieldCourseTurnGeneratorState.SHRINK_SEGMENT then
            if self.state == AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT then
                self.turnData = self.originalTurnData:offset(self.startOffset, self.endOffset)
            else
                self.turnData = self.originalTurnData:offset(-self.startOffset, -self.endOffset)
            end
            local minCostTurn, _ = self:getBestTurnByTurnData(self.turnData)
            if minCostTurn ~= nil then
                table.insert(self.offsetTurns, minCostTurn)
                local directLength = MathUtil.vector2Length(self.turnData.ex - self.turnData.sx, self.turnData.ez - self.turnData.sz)
                if minCostTurn.length * self.turnData.turnRadius < directLength * 1.25 then
                    self:onFinished(AIFieldCourseTurnGenerator.getLowestCostTurn(self.offsetTurns) or minCostTurn)
                    return
                end
            end
            self.startOffset = self.startOffset + 3
            if self.startOffset > self.startOffsetLimit then
                self.startOffset = self.defaultStartOffset
                self.endOffset = self.endOffset + 3
                if self.endOffset > self.endOffsetLimit then
                    local directLength = AIFieldCourseTurnGenerator.getLowestCostTurn(self.offsetTurns)
                    if directLength ~= nil then
                        self:onFinished(directLength)
                        return
                    end
                    if self.state ~= AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT then
                        self:onFinished(nil)
                        return
                    end
                    local i = #self.offsetTurns
                    local i = -1
                    for i = i, 1, i do
                        self.offsetTurns[i] = nil
                    end
                    local i = self.defaultEndOffset
                    self.startOffset = self.defaultStartOffset
                    self.endOffset = i
                    self.state = AIFieldCourseTurnGeneratorState.SHRINK_SEGMENT
                end
            end
        end
    end
end
function AIFieldCourseTurnGenerator.getLowestCostTurn(turns)
    local minCostOffsetTurn = nil
    local minCostOffset = math.huge
    for _, turn in ipairs(turns) do
        if turn.numBoundaryIntersections == 0 then
            local cost = turn:getOverallCost()
            if cost < minCostOffset then
                minCostOffsetTurn = turn
                minCostOffset = cost
            end
        end
    end
    return minCostOffsetTurn
end
function AIFieldCourseTurnGenerator.isPositionOutsideField(sx, sz, turnData, useProtectedBoundary, useRootBoundary)
    local boundary = turnData.validPathBoundary.boundaryLine
    if useProtectedBoundary then
        boundary = turnData.protectedBoundary.boundaryLine
    end
    if useRootBoundary then
        boundary = turnData.fieldRootBoundary.boundaryLine
    end
    if FieldCourseUtil.getDistanceToBoundary(sx, sz, boundary) > 0.01 and not FieldCourseUtil.getIsPointInsideBoundary(sx, sz, boundary) then
        return true
    end
    for _, island in ipairs(turnData.islands) do
        local boundary = island.validPathBoundary
        if useProtectedBoundary then
            boundary = island.protectedBoundary
        end
        if useRootBoundary then
            boundary = island.rootBoundary
        end
        if FieldCourseUtil.getDistanceToBoundary(sx, sz, boundary.boundaryLine) > 0.01 and FieldCourseUtil.getIsPointInsideBoundary(sx, sz, boundary.boundaryLine) then
            return true
        end
    end
    return false
end
function AIFieldCourseTurnGenerator.findCommonTurnRadiusIntersection(callback, turnData)
    if turnData.segment1 == nil or turnData.segment2 == nil then
        return
    end
    local sDistance = turnData.turnRadius * 6
    local sOffset = 0
    local sIndex = 1
    while sDistance > 0 do
        local lastIndex1 = sIndex + 1
        if turnData.segment1Direction > 0 then
            lastIndex1 = #turnData.segment1.positions - sIndex
        end
        local p1 = segment1.positions[lastIndex1]
        local p2 = segment1.positions[lastIndex1 + direction1]
        if p1 == nil or p2 == nil then
            break
        end
        local eIndex = 1
        local eDistance = turnData.turnRadius * 6
        local eOffset = 0
        while eDistance > 0 do
            local lastIndex2 = #turnData.segment2.positions - (eIndex - 1)
            if turnData.segment2Direction > 0 then
                lastIndex2 = eIndex
            end
            local p3 = segment2.positions[lastIndex2]
            local p4 = segment2.positions[lastIndex2 + direction2]
            if p3 == nil or p4 == nil then
                break
            end
            local dirX1 = p1[1] - p2[1]
            local dirZ1 = p1[2] - p2[2]
            local length1 = MathUtil.vector2Length(dirX1, dirZ1)
            local dirX1 = dirX1 / length1
            local dirZ1 = dirZ1 / length1
            local x1 = p2[1] + dirZ1 * turnData.turnRadius
            local z1 = p2[2] - dirX1 * turnData.turnRadius
            local extendedLength1 = 0
            local maxLength1
            if p2 == segment1.positions[1] or p2 == segment1.positions[#segment1.positions] then
                maxLength1 = length1 + 50
                extendedLength1 = 50
            else
                maxLength1 = length1
            end
            if p1 == segment1.positions[1] or p1 == segment1.positions[#segment1.positions] then
            end
            local dirX2 = p4[1] - p3[1]
            local dirZ2 = p4[2] - p3[2]
            local length2 = MathUtil.vector2Length(dirX2, dirZ2)
            local dirX2 = dirX2 / length2
            local dirZ2 = dirZ2 / length2
            local x2 = p3[1] + dirZ2 * turnData.turnRadius
            local z2 = p3[2] - dirX2 * turnData.turnRadius
            local extendedLength2 = 0
            local maxLength2
            if p3 == segment2.positions[1] or p3 == segment2.positions[#segment2.positions] then
                maxLength2 = length2 + 50
                extendedLength2 = 50
            else
                maxLength2 = length2
            end
            if p4 == segment2.positions[1] or p4 == segment2.positions[#segment2.positions] then
            end
            local intersect, t1, t2 = MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
            if intersect and (t1 > 0 and (t1 <= maxLength1 and (t2 > 0 and t2 <= maxLength2))) then
                if extendedLength1 > 0 then
                end
                if extendedLength2 > 0 then
                end
                (function(t1, t2, so, eo)
                    -- upvalues: (copy) turnData, (copy) callback
                    so = t1 + 0.01 + so
                    eo = t2 + 0.01 + eo
                    local tempTurnData = turnData:offset(so, eo)
                    local x1 = tempTurnData.sx
                    local z1 = tempTurnData.sz
                    local x2 = tempTurnData.originalTurnData.sx
                    local z2 = tempTurnData.originalTurnData.sz
                    local x3 = tempTurnData.ex
                    local z3 = tempTurnData.ez
                    local x4 = tempTurnData.originalTurnData.ex
                    local z4 = tempTurnData.originalTurnData.ez
                    if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, turnData.protectedBoundary.boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(x2, z2, turnData.protectedBoundary.boundaryLine) then
                        local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, turnData.protectedBoundary.boundaryLine)
                        if intersect then
                            return
                        end
                    end
                    for _, island in ipairs(turnData.islands) do
                        if not (FieldCourseUtil.getIsPointInsideBoundary(x1, z1, island.protectedBoundary.boundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(x2, z2, island.protectedBoundary.boundaryLine)) then
                            local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, island.protectedBoundary.boundaryLine)
                            if intersect then
                                return
                            end
                        end
                    end
                    if FieldCourseUtil.getIsPointInsideBoundary(x3, z3, turnData.protectedBoundary.boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(x4, z4, turnData.protectedBoundary.boundaryLine) then
                        local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x3, z3, x4, z4, turnData.protectedBoundary.boundaryLine)
                        if intersect then
                            return
                        end
                    end
                    for _, island in ipairs(turnData.islands) do
                        if not (FieldCourseUtil.getIsPointInsideBoundary(x3, z3, island.protectedBoundary.boundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(x4, z4, island.protectedBoundary.boundaryLine)) then
                            local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x3, z3, x4, z4, island.protectedBoundary.boundaryLine)
                            if intersect then
                                return
                            end
                        end
                    end
                    callback(so, eo, turnData.turnRadius)
                end)(t1, t2, sOffset, eOffset)
            end
            local x1 = p2[1] - dirZ1 * turnData.turnRadius
            local z1 = p2[2] + dirX1 * turnData.turnRadius
            local extendedLength1 = 0
            local maxLength1
            if p2 == segment1.positions[1] or p2 == segment1.positions[#segment1.positions] then
                maxLength1 = length1 + 50
                extendedLength1 = 50
            else
                maxLength1 = length1
            end
            if p1 == segment1.positions[1] or p1 == segment1.positions[#segment1.positions] then
            end
            local segDistance, t1, t2 = MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
            if segDistance and (t1 > 0 and (t1 <= maxLength1 and (t2 > 0 and t2 <= maxLength2))) then
                if extendedLength1 > 0 then
                end
                if extendedLength2 > 0 then
                end
                validateHit(t1, t2, sOffset, eOffset)
            end
            local x2 = p3[1] - dirZ2 * turnData.turnRadius
            local z2 = p3[2] + dirX2 * turnData.turnRadius
            local extendedLength2 = 0
            local maxLength2
            if p3 == segment2.positions[1] or p3 == segment2.positions[#segment2.positions] then
                maxLength2 = length2 + 50
                extendedLength2 = 50
            else
                maxLength2 = length2
            end
            if p4 == segment2.positions[1] or p4 == segment2.positions[#segment2.positions] then
            end
            local segDistance, t1, t2 = MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
            if segDistance and (t1 > 0 and (t1 <= maxLength1 and (t2 > 0 and t2 <= maxLength2))) then
                if extendedLength1 > 0 then
                end
                if extendedLength2 > 0 then
                end
                validateHit(t1, t2, sOffset, eOffset)
            end
            local x1 = p2[1] + dirZ1 * turnData.turnRadius
            local z1 = p2[2] - dirX1 * turnData.turnRadius
            local extendedLength1 = 0
            if p2 == segment1.positions[1] or p2 == segment1.positions[#segment1.positions] then
                extendedLength1 = 50
            end
            if p1 == segment1.positions[1] or p1 == segment1.positions[#segment1.positions] then
            end
            local x2 = p3[1] - dirZ2 * turnData.turnRadius
            local z2 = p3[2] + dirX2 * turnData.turnRadius
            local extendedLength2 = 0
            if p3 == segment2.positions[1] or p3 == segment2.positions[#segment2.positions] then
                extendedLength2 = 50
            end
            if p4 == segment2.positions[1] or p4 == segment2.positions[#segment2.positions] then
            end
            local segDistance, t1, t2 = MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
            if segDistance and (t1 > 0 and (t1 <= length1 and (t2 > 0 and t2 <= length2))) then
                if extendedLength1 > 0 then
                end
                if extendedLength2 > 0 then
                end
                validateHit(t1, t2, sOffset, eOffset)
            end
            local segDistance = MathUtil.vector2Length(p4[1] - p3[1], p4[2] - p3[2])
            eDistance = eDistance - segDistance
            eOffset = eOffset + segDistance
            eIndex = eIndex + 1
        end
        local lastIndex2 = MathUtil.vector2Length(p2[1] - p1[1], p2[2] - p1[2])
        sDistance = sDistance - lastIndex2
        sOffset = sOffset + lastIndex2
        sIndex = sIndex + 1
    end
end
function AIFieldCourseTurnGenerator.generateTurnIntersectionPoints(turnData, intersectionPositions, intersectData, ix, iz, psx, psz, pex, pez)
    local boundaryLine = intersectData.boundary
    local numPoints = #boundaryLine
    local startIndex1 = nil
    local startIndex2 = nil
    local i = 1
    local distance1 = #boundaryLine
    local endIndex1 = 1
    for i = i, distance1, endIndex1 do
        local pos = boundaryLine[i]
        if pos[1] == intersectData.psx then
            if pos[2] == intersectData.psz then
                startIndex1 = i
            end
        end
        if pos[1] == intersectData.pex then
            if pos[2] == intersectData.pez then
                startIndex2 = i
            end
        end
        if startIndex1 ~= nil and startIndex2 ~= nil then
            break
        end
    end
    local i = { intersectData.ix, intersectData.iz }
    table.insert(intersectionPositions, i)
    local endIndex1 = startIndex1 - startIndex2
    if math.abs(endIndex1) > 1 then
        if startIndex1 < startIndex2 then
        end
    end
    if startIndex2 < startIndex1 then
        local distance1, endIndex1 = (function(startIndex, direction, lastX, lastZ)
            -- upvalues: (copy) numPoints, (copy) boundaryLine, (copy) turnData, (copy) psx, (copy) psz, (copy) pex, (copy) pez, (copy) ix, (copy) iz
            local distance = 0
            local endIndex = startIndex
            startIndex = endIndex
            for startIndex = startIndex, startIndex + numPoints * direction, direction do
                local pos = boundaryLine[(startIndex - 1) % numPoints + 1]
                if not FieldCourseUtil.getIsPointInsideBoundary(pos[1], pos[2], turnData.protectedBoundary.boundaryLine) then
                    return math.huge, startIndex
                end
                distance = distance + MathUtil.vector2Length(lastX - pos[1], lastZ - pos[2])
                if pos[1] == psx and pos[2] == psz or pos[1] == pex and pos[2] == pez then
                    endIndex = startIndex
                    break
                end
            end
            return distance + MathUtil.vector2Length(lastX - ix, lastZ - iz), endIndex
        end)(startIndex1, 1, intersectData.ix, intersectData.iz)
        local i, pos = getDistanceToTargetPoint(startIndex2, -1, intersectData.ix, intersectData.iz)
        if distance1 < i then
            for startIndex1 = startIndex1, endIndex1 do
                local pos = boundaryLine[(startIndex1 - 1) % numPoints + 1]
                local lastPos = intersectionPositions[#intersectionPositions]
                if pos[1] ~= lastPos[1] or pos[2] ~= lastPos[2] then
                    table.insert(intersectionPositions, { pos[1], pos[2] })
                end
            end
        else
            for startIndex2 = startIndex2, pos, -1 do
                local pos = boundaryLine[(startIndex2 - 1) % numPoints + 1]
                local lastPos = intersectionPositions[#intersectionPositions]
                if pos[1] ~= lastPos[1] or pos[2] ~= lastPos[2] then
                    table.insert(intersectionPositions, { pos[1], pos[2] })
                end
            end
        end
    else
        local distance1, endIndex1 = getDistanceToTargetPoint(startIndex1, -1, intersectData.ix, intersectData.iz)
        local i, pos = getDistanceToTargetPoint(startIndex2, 1, intersectData.ix, intersectData.iz)
        if distance1 < i then
            for startIndex1 = startIndex1, endIndex1, -1 do
                local pos = boundaryLine[(startIndex1 - 1) % numPoints + 1]
                local lastPos = intersectionPositions[#intersectionPositions]
                if pos[1] ~= lastPos[1] or pos[2] ~= lastPos[2] then
                    table.insert(intersectionPositions, { pos[1], pos[2] })
                end
            end
        else
            for startIndex2 = startIndex2, pos do
                local pos = boundaryLine[(startIndex2 - 1) % numPoints + 1]
                local lastPos = intersectionPositions[#intersectionPositions]
                if pos[1] ~= lastPos[1] or pos[2] ~= lastPos[2] then
                    table.insert(intersectionPositions, { pos[1], pos[2] })
                end
            end
        end
    end
    local distance1 = intersectionPositions[#intersectionPositions]
    if ix ~= distance1[1] or iz ~= distance1[2] then
        table.insert(intersectionPositions, { ix, iz })
    end
end
local tempData = {
    ["ix"] = 0,
    ["iz"] = 0,
    ["psx"] = 0,
    ["psz"] = 0,
    ["pex"] = 0,
    ["pez"] = 0,
    ["boundary"] = nil,
    ["isValid"] = false
}
function AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, sx, sz, ex, ez, turnData, intersectData)
    -- upvalues: (copy) tempData
    local dx = ex - sx
    local dz = ez - sz
    local length = MathUtil.vector2Length(dx, dz)
    if length == 0 then
        return true
    end
    local dx = dx / length
    local dz = dz / length
    if #intersectionPositions == 0 and intersectData == nil then
    end
    local intersect, ix, iz, psx, psz, pex, pez = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx + dx * 0.001, sz + dz * 0.001, ex + dx * 0.001, ez + dz * 0.001, turnData.validPathBoundary.boundaryLine)
    if intersect then
        if FieldCourseUtil.getDistanceToSegment(psx, psz, pex, pez, sx + dx * 0.001, sz + dz * 0.001) > 0.001 then
            if intersectData ~= nil and (intersectData.isValid and intersectData.boundary == turnData.validPathBoundary.boundaryLine) then
                if turnData.validPathBoundary == turnData.protectedBoundary then
                    return false
                end
                AIFieldCourseTurnGenerator.generateTurnIntersectionPoints(turnData, intersectionPositions, intersectData, ix, iz, psx, psz, pex, pez)
                tempData.boundary = nil
                tempData.isValid = false
                return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, ix, iz, ex, ez, turnData)
            end
            tempData.ix = ix
            tempData.iz = iz
            tempData.psx = psx
            tempData.psz = psz
            tempData.pex = pex
            tempData.pez = pez
            tempData.boundary = turnData.validPathBoundary.boundaryLine
            tempData.isValid = true
            return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, ix, iz, ex, ez, turnData, tempData)
        end
    else
        local intersect = false
        local ix = 0
        local iz = 0
        local psx = 0
        local psz = 0
        local pex = 0
        local pez = 0
        local sideOffset = math.huge
        local minDistanceIsland = nil
        for _, island in ipairs(turnData.islands) do
            local _intersect, _ix, _iz, _psx, _psz, _pex, _pez = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx + dx * 0.001, sz + dz * 0.001, ex + dx * 0.001, ez + dz * 0.001, island.validPathBoundary.boundaryLine)
            if _intersect and FieldCourseUtil.getDistanceToSegment(_psx, _psz, _pex, _pez, sx + dx * 0.001, sz + dz * 0.001) > 0.001 then
                local distance = MathUtil.vector2Length(_ix - sx, _iz - sz)
                if distance < sideOffset then
                    minDistanceIsland = island
                    pez = _pez
                    pex = _pex
                    psz = _psz
                    psx = _psx
                    iz = _iz
                    ix = _ix
                    intersect = _intersect
                    sideOffset = distance
                end
            end
        end
        if intersect then
            if intersectData ~= nil and (intersectData.isValid and intersectData.boundary == minDistanceIsland.validPathBoundary.boundaryLine) then
                if minDistanceIsland.validPathBoundary == minDistanceIsland.protectedBoundary then
                    return false
                end
                AIFieldCourseTurnGenerator.generateTurnIntersectionPoints(turnData, intersectionPositions, intersectData, ix, iz, psx, psz, pex, pez)
                tempData.boundary = nil
                tempData.isValid = false
                return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, ix, iz, ex, ez, turnData)
            end
            tempData.ix = ix
            tempData.iz = iz
            tempData.psx = psx
            tempData.psz = psz
            tempData.pex = pex
            tempData.pez = pez
            tempData.boundary = minDistanceIsland.validPathBoundary.boundaryLine
            tempData.isValid = true
            return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, ix, iz, ex, ez, turnData, tempData)
        end
    end
    return true
end
function AIFieldCourseTurnGenerator.getSkipToPositionIndex(intersectionPositions, startIndex, curX, curZ, turnData)
    local otherIndex = #intersectionPositions + 1
    for otherIndex = otherIndex, startIndex + 1, -1 do
        local otherPos = intersectionPositions[otherIndex]
        local ex, ez
        if otherPos == nil then
            ex = turnData.ex
            ez = turnData.ez
        else
            ex = otherPos[1]
            ez = otherPos[2]
        end
        local dx = ex - curX
        local dz = ez - curZ
        local length = MathUtil.vector2Length(dx, dz)
        if length > 0 then
            local dx = dx / length
            local dz = dz / length
            local sx = curX + dx * 0.01
            local sz = curZ + dz * 0.01
            local ex = ex - dx * 0.01
            local ez = ez - dz * 0.01
            local intersect, _, _, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx, sz, ex, ez, turnData.validPathBoundary.boundaryLine)
            if not intersect then
                intersect = not FieldCourseUtil.getIsSegmentInsideBoundary(sx, sz, ex, ez, turnData.validPathBoundary.boundaryLine) and true or intersect
                if not intersect then
                    for _, island in ipairs(turnData.islands) do
                        intersect, _, _, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx, sz, ex, ez, island.validPathBoundary.boundaryLine)
                        if intersect then
                            break
                        end
                        if FieldCourseUtil.getIsSegmentInsideBoundary(sx, sz, ex, ez, island.validPathBoundary.boundaryLine) then
                            intersect = true
                            break
                        end
                    end
                end
            end
            if not intersect then
                return otherIndex
            end
        end
    end
end
function AIFieldCourseTurnGenerator:getIntersectionTurn(turnData)
    local intersectionPositions = {}
    local startIsOutsideField = false
    local sx = turnData.sx
    local sz = turnData.sz
    local ex = turnData.ex
    local ez = turnData.ez
    local iz, ix
    if FieldCourseUtil.getIsPointInsideBoundary(sx, sz, turnData.fieldRootBoundary.boundaryLine) then
        iz = sz
        ix = sx
    else
        local intersect, _, _, _, _
        intersect, ix, iz, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx, sz, ex, ez, turnData.validPathBoundary.boundaryLine)
        if intersect then
            table.insert(intersectionPositions, { ix, iz })
        else
            iz = sz
            ix = sx
        end
        startIsOutsideField = true
    end
    if not AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, ix, iz, ex, ez, turnData) then
        return nil
    end
    local intersect = #intersectionPositions
    if intersect < 2 then
        return nil
    end
    local ix = 1
    while ix < #intersectionPositions do
        local _ = intersectionPositions[ix][2]
        local _ = AIFieldCourseTurnGenerator.getSkipToPositionIndex(intersectionPositions, ix, intersectionPositions[ix][1], _, turnData)
        if _ ~= nil then
            local indexToRemove = _ - 1
            for indexToRemove = indexToRemove, ix + 1, -1 do
                table.remove(intersectionPositions, indexToRemove)
            end
            intersect = #intersectionPositions
        end
        ix = ix + 1
    end
    local iz = AIFieldCourseTurnGenerator.getSkipToPositionIndex(intersectionPositions, 0, turnData.sx, turnData.sz, turnData)
    if iz ~= nil then
        for _ = 1, iz - 1 do
            table.remove(intersectionPositions, 1)
        end
        intersect = #intersectionPositions
    end
    if intersect <= 0 then
        return nil
    end
    local _ = intersectionPositions[1]
    local _ = intersectionPositions[2]
    local _, _
    if _ == nil then
        local _ = turnData.ex - _[1]
        local _ = turnData.ez - _[2]
        local indexToRemove = MathUtil.vector2Length(_, _)
        _ = _ / indexToRemove
        _ = _ / indexToRemove
    else
        local _ = _[1] - _[1]
        local _ = _[2] - _[2]
        local indexToRemove = MathUtil.vector2Length(_, _)
        _ = _ / indexToRemove
        _ = _ / indexToRemove
    end
    local indexToRemove = 1
    if self.fieldCourseSettings.allowTurnBackward then
        local oldIgnoreBoundaryIntersections = MathUtil.dotProduct(turnData.sDirX, 0, turnData.sDirZ, _, 0, _)
        if math.acos(oldIgnoreBoundaryIntersections) > 1.5707963267948966 then
            indexToRemove = -1
        end
    end
    local angleDifference = turnData:clone(true, false)
    local oldIgnoreBoundaryIntersections = _[1]
    local turn = _[2]
    angleDifference.ex = oldIgnoreBoundaryIntersections
    angleDifference.ez = turn
    angleDifference.eDirX = _
    angleDifference.eDirZ = _
    local oldIgnoreBoundaryIntersections = self.ignoreBoundaryIntersections
    self.ignoreBoundaryIntersections = self.ignoreBoundaryIntersections or startIsOutsideField
    local turn = self:getLowestCostTurnByData(angleDifference)
    if turn == nil then
        return nil
    end
    self.ignoreBoundaryIntersections = oldIgnoreBoundaryIntersections
    local lastX = _[1]
    local lastZ = _[2]
    local i = 1
    while i < intersect do
        local p3 = intersectionPositions[i + 1]
        local p4 = intersectionPositions[i + 2]
        if p3 == nil or p4 == nil then
            local dx1 = MathUtil.vector2Length(intersectionPositions[i + 1][1] - lastX, intersectionPositions[i + 1][2] - lastZ)
            table.insert(turn.segments, AIFieldCourseTurnSegment.new(dx1 / turnData.turnRadius, AIFieldCourseTurnSegmentType.STRAIGHT, indexToRemove))
            _, _ = MathUtil.vector2Normalize(p2[1] - intersectionPositions[i][1], p2[2] - intersectionPositions[i][2])
        else
            local dx1 = p2[1] - lastX
            local dz1 = p2[2] - lastZ
            local l1 = MathUtil.vector2Length(dx1, dz1)
            local dx1 = dx1 / l1
            local dz1 = dz1 / l1
            local dx2 = p4[1] - p3[1]
            local dz2 = p4[2] - p3[2]
            local l2 = MathUtil.vector2Length(dx2, dz2)
            local dx2 = dx2 / l2
            local dz2 = dz2 / l2
            local searchPath = false
            local ex, ez
            if p2 == p3 then
                local ax1 = lastX + dz1 * turnData.turnRadius
                local az1 = lastZ - dx1 * turnData.turnRadius
                local ax2 = p2[1] + dz1 * turnData.turnRadius
                local az2 = p2[2] - dx1 * turnData.turnRadius
                local bx1 = p3[1] + dz2 * turnData.turnRadius
                local bz1 = p3[2] - dx2 * turnData.turnRadius
                local bx2 = p4[1] + dz2 * turnData.turnRadius
                local bz2 = p4[2] - dx2 * turnData.turnRadius
                local intersect, a, b = MathUtil.getLineSegmentsIntersectionParameter(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
                local isLeft = true
                if not intersect then
                    intersect, a, b = MathUtil.getLineSegmentsIntersectionParameter(lastX - dz1 * turnData.turnRadius, lastZ + dx1 * turnData.turnRadius, p2[1] - dz1 * turnData.turnRadius, p2[2] + dx1 * turnData.turnRadius, p3[1] - dz2 * turnData.turnRadius, p3[2] + dx2 * turnData.turnRadius, p4[1] - dz2 * turnData.turnRadius, p4[2] + dx2 * turnData.turnRadius)
                    isLeft = false
                end
                if intersect then
                    ex = p3[1] + dx2 * b * l2
                    ez = p3[2] + dz2 * b * l2
                    local cx = ax1 + dx1 * a * l1
                    local cz = az1 + dz1 * a * l1
                    local yRot1 = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(cx - (lastX + dx1 * a * l1), cz - (lastZ + dz1 * a * l1)))
                    local yRot2 = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(cx - ex, cz - ez))
                    local s = yRot1 - MathUtil.normalizeRotationForShortestPath(yRot2, yRot1)
                    local angle = math.abs(s)
                    local s = a * l1
                    if s > 0 then
                        table.insert(turn.segments, AIFieldCourseTurnSegment.new(s / turnData.turnRadius, AIFieldCourseTurnSegmentType.STRAIGHT, indexToRemove))
                        table.insert(turn.segments, AIFieldCourseTurnSegment.new(angle, isLeft and AIFieldCourseTurnSegmentType.LEFT or AIFieldCourseTurnSegmentType.RIGHT, indexToRemove))
                    else
                        searchPath = true
                        dz2 = _
                        dx2 = _
                        ez = lastZ
                        ex = lastX
                    end
                else
                    searchPath = true
                    dz2 = _
                    dx2 = _
                    ez = lastZ
                    ex = lastX
                end
            else
                searchPath = true
                dz2 = _
                dx2 = _
                ez = lastZ
                ex = lastX
            end
            if searchPath then
                local ax1 = MathUtil.vector2Length(p2[1] - ex, p2[2] - ez)
                table.insert(turn.segments, AIFieldCourseTurnSegment.new(ax1 / turnData.turnRadius, AIFieldCourseTurnSegmentType.STRAIGHT, indexToRemove))
                local ax1 = turnData:clone(false, false)
                ax1.sx = p2[1]
                ax1.sz = p2[2]
                local az1, ax2 = MathUtil.vector2Normalize(p2[1] - ex, p2[2] - ez)
                ax1.sDirX = az1
                ax1.sDirZ = ax2
                ax1.ex = p3[1]
                ax1.ez = p3[2]
                local az1, ax2 = MathUtil.vector2Normalize(p4[1] - p3[1], p4[2] - p3[2])
                ax1.eDirX = az1
                ax1.eDirZ = ax2
                if self:getLowestCostTurnByData(ax1) == nil then
                    return nil
                end
                for bz1, bx2 in ipairs(az1.segments) do
                    table.insert(turn.segments, bx2)
                end
                turn:updateLength()
                lastX = p3[1]
                lastZ = p3[2]
                _, _ = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
            else
                _ = dz2
                _ = dx2
                lastZ = ez
                lastX = ex
            end
        end
        turn:updateLength()
        i = i + 1
    end
    local p1 = turnData:clone(false, true)
    p1.sx = lastX
    p1.sz = lastZ
    local p2 = _ * indexToRemove
    local p3 = _ * indexToRemove
    p1.sDirX = p2
    p1.sDirZ = p3
    local p2 = self:getLowestCostTurnByData(p1)
    if p2 == nil then
        return nil
    end
    for dz1, l1 in ipairs(p2.segments) do
        table.insert(turn.segments, l1)
    end
    turn.turnData.segment2 = p2.turnData.segment2
    turn.turnData.segment2Direction = p2.turnData.segment2Direction
    turn:updateLength()
    turn:updateCost()
    if intersect == 1 then
        local p3 = self:getLowestCostTurnByData(turnData)
        if p3 ~= nil and (p3.numBoundaryIntersections == 0 and p3:getOverallCost() < turn:getOverallCost()) then
            return p3
        end
    end
    turn.turnData = turnData:clone()
    return turn
end
function AIFieldCourseTurnGenerator:getBestTurnByTurnData(turnData)
    local turn = self:getIntersectionTurn(turnData)
    if turn == nil then
        return self:getLowestCostTurnByData(turnData)
    else
        return turn
    end
end
function AIFieldCourseTurnGenerator:generateTurnsByData(turns, turnData)
    DubinsPath.new(turnData, self.forcedDrivingDirection):generate(function(turn)
        -- upvalues: (copy) turns, (copy) self
        table.insert(turns, turn)
        if dp ~= nil then
            table.insert(self.alternativeTurnSegments, turn)
        end
    end)
    if turnData.canTurnBackward then
        ReedsSheppPath.new(turnData, self.forcedDrivingDirection):generate(function(turn)
            -- upvalues: (copy) turns, (copy) self
            table.insert(turns, turn)
            if dp ~= nil then
                table.insert(self.alternativeTurnSegments, turn)
            end
        end)
    end
end
function AIFieldCourseTurnGenerator:getLowestCostTurnByData(turnData)
    if not self.ignoreBoundaryIntersections and (AIFieldCourseTurnGenerator.isPositionOutsideField(turnData.sx, turnData.sz, turnData, true, self.allowProtectedBoundary) or AIFieldCourseTurnGenerator.isPositionOutsideField(turnData.ex, turnData.ez, turnData, true, self.allowProtectedBoundary)) then
        return nil
    end
    local turns = {}
    self:generateTurnsByData(turns, turnData)
    if self.maxOffset == nil and (not turnData.canTurnBackward and turnData.allowStraightReversing) then
        self:generateTurnsByData(turns, (turnData:offset(0, 2.5)))
    end
    if self.maxOffset ~= nil then
        local offset = 3
        for offset = offset, self.maxOffset, 3 do
            local offsetTurnData, offsetTurnData
            if turnData.canTurnBackward or turnData.allowStraightReversing then
                offsetTurnData = offset
            else
                if turnData.segment1 == nil then
                    offsetTurnData = offset
                else
                    offsetTurnData = math.min(offset, turnData.segment1.length - (turnData.segment1.lastStartOffset or 0))
                end
                if turnData.segment2 == nil then
                    offsetTurnData = offset
                else
                    offsetTurnData = math.min(offset, turnData.segment2.length - (turnData.segment2.lastEndOffset or 0))
                end
            end
            self:generateTurnsByData(turns, (turnData:offset(offsetTurnData, offsetTurnData)))
        end
    end
    AIFieldCourseTurnGenerator.findCommonTurnRadiusIntersection(function(startOffset, endOffset, adjustedTurnRadius)
        -- upvalues: (copy) turnData, (copy) self, (copy) turns
        if turnData.turnRadius >= startOffset and turnData.turnRadius >= endOffset then
            local offsetTurnData = turnData:offset(startOffset, endOffset)
            if not (turnData.canTurnBackward or turnData.allowStraightReversing) then
                if -startOffset > turnData.segment1.length then
                    return
                end
                if turnData.segment2.length < endOffset then
                    return
                end
            end
            offsetTurnData.turnRadius = adjustedTurnRadius
            self:generateTurnsByData(turns, offsetTurnData)
        end
    end, turnData)
    local offsetTurnData = nil
    local minCost = math.huge
    for endOffset, offsetTurnData in ipairs(turns) do
        offsetTurnData:updateCost(self.allowProtectedBoundary, self.preferOneDrivingDirection)
        local cost = offsetTurnData:getOverallCost()
        if cost < minCost and (offsetTurnData.numBoundaryIntersections == 0 or self.ignoreBoundaryIntersections) then
            minCost = cost
        end
    end
    return offsetTurnData, turns
end
function AIFieldCourseTurnGenerator.getSegmentMinOffset(startPosition, segment, segmentDirection, turnData, offsetLimit)
    local numPositions = #segment.positions
    if startPosition then
        local pos1 = segment.positions[1]
        local pos2 = segment.positions[2]
        if segmentDirection > 0 then
            pos1 = segment.positions[numPositions]
            pos2 = segment.positions[numPositions - 1]
        end
        local dx, dz = MathUtil.vector2Normalize(pos1[1] - pos2[1], pos1[2] - pos2[2])
        local intersect, ix, iz = FieldCourseUtil.getSegmentClosestBoundaryIntersection(pos1[1], pos1[2], pos1[1] + dx * offsetLimit, pos1[2] + dz * offsetLimit, turnData.protectedBoundary.boundaryLine)
        if intersect then
            return -(MathUtil.vector2Length(ix - pos1[1], iz - pos1[2]) + 0.1)
        end
    else
        local pos2 = numPositions - 1
        local dx = 1
        if segmentDirection < 0 then
            pos2 = 2
            dx = -1
        else
            numPositions = 1
        end
        local dz = 0
        for numPositions = numPositions, pos2, dx do
            local distanceToIntersection = segment.positions[numPositions]
            local nextPos = segment.positions[numPositions + dx]
            if not AIFieldCourseTurnGenerator.isPositionOutsideField(distanceToIntersection[1], distanceToIntersection[2], turnData, true) then
                break
            end
            if not AIFieldCourseTurnGenerator.isPositionOutsideField(nextPos[1], nextPos[2], turnData, true) then
                local intersect, ix, iz = FieldCourseUtil.getSegmentClosestBoundaryIntersection(distanceToIntersection[1], distanceToIntersection[2], nextPos[1], nextPos[2], turnData.protectedBoundary.boundaryLine)
                if intersect then
                    local dz = dz + MathUtil.vector2Length(ix - distanceToIntersection[1], iz - distanceToIntersection[2])
                    return math.min(dz, offsetLimit)
                end
                break
            end
            dz = dz + MathUtil.vector2Length(nextPos[1] - distanceToIntersection[1], nextPos[2] - distanceToIntersection[2])
        end
    end
    return nil
end