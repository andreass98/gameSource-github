TrapezoidDecomposition = {}
local TrapezoidDecomposition_mt = Class(TrapezoidDecomposition)
TrapezoidDecomposition.MAX_MERGE_ANGLE = 4.1887902047863905
TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE = 0.6108652381980153
TrapezoidDecomposition.MIN_MERGE_LENGTH_PERCENTAGE = 0.1
TrapezoidDecomposition.OPTIMAL_ANGLE_STEPS = 16
TrapezoidDecomposition.COLORS = {
    { 0.7079, 0.6987, 0.2864 },
    { 0.9628, 0.5908, 0.4254 },
    { 0.078, 0.3129, 0.7987 },
    { 0.0244, 0.6147, 0.5057 },
    { 0.2402, 0.7016, 0.8469 },
    { 0.2624, 0.4573, 0.5326 },
    { 0.22, 0.859, 0.6861 },
    { 0.7581, 0.1639, 0.3565 },
    { 0.0544, 0.6152, 0.1018 },
    { 0.747, 0.2893, 0.3946 }
}
function TrapezoidDecomposition.new(boundary, singleGroupMode)
    -- upvalues: (copy) TrapezoidDecomposition_mt
    local self = setmetatable({}, TrapezoidDecomposition_mt)
    self.boundary = boundary
    self.trapezoidLines = {}
    self.trapezoids = {}
    self.trapezoidGroups = {}
    self.numGroups = {}
    self.singleGroupMode = Utils.getNoNil(singleGroupMode, false)
    self.step = 0
    return self
end
function TrapezoidDecomposition:update(_, frameBudget)
    local startTime = getTimeSec()
    while getTimeSec() - startTime < frameBudget do
        if self.step == 1 then
            self:generateVerticalLines()
        elseif self.step == 2 then
            self:generateTrapezoids()
        elseif self.step == 3 then
            self:assignMergeGroups()
        elseif self.step == 4 then
            self:generateGroups()
        elseif self.step == 5 then
            self:mergeGroupsBySize()
        elseif self.step == 6 then
            self:mergeGroupsByWorkDirection()
        elseif self.step == 7 then
            self:mergeGroupsByCost()
        elseif self.step == 8 then
            self:updateGroups()
            return false
        end
        self.step = self.step + 1
    end
    return true
end
function TrapezoidDecomposition:generateVerticalLines()
    self.trapezoidLines = {}
    local sortedBoundaryPositions = table.clone(self.boundary)
    table.remove(sortedBoundaryPositions, #sortedBoundaryPositions)
    table.sort(sortedBoundaryPositions, function(a, b)
        return a[1] < b[1]
    end)
    local posIndex = 1
    for posIndex = posIndex, #sortedBoundaryPositions do
        local foundBoundaryIntersection = false
        local position = sortedBoundaryPositions[posIndex]
        local closestIntersectionX, closestIntersectionZ = TrapezoidDecomposition.getClosestIntersectionWithBoundary(position, 0, 1, self.boundary)
        if closestIntersectionX ~= nil then
            table.insert(self.trapezoidLines, {
                { position[1], closestIntersectionZ },
                { position[1], position[2] }
            })
            foundBoundaryIntersection = true
        end
        local lastPosition, nextPosition = TrapezoidDecomposition.getClosestIntersectionWithBoundary(position, 0, -1, self.boundary)
        if lastPosition ~= nil then
            table.insert(nextPosition, {
                { position[1], position[2] },
                { position[1], self.trapezoidLines }
            })
            foundBoundaryIntersection = true
        end
        if not foundBoundaryIntersection then
            local lastPosition = sortedBoundaryPositions[posIndex - 1]
            local nextPosition = sortedBoundaryPositions[posIndex + 1]
            if lastPosition ~= nil then
                if math.abs(lastPosition[1] - position[1]) < 0.00001 then
                    if position[2] > lastPosition[2] then
                        table.insert(self.trapezoidLines, {
                            { position[1], position[2] },
                            { position[1], lastPosition[2] }
                        })
                    else
                        table.insert(self.trapezoidLines, {
                            { position[1], lastPosition[2] },
                            { position[1], position[2] }
                        })
                    end
                    foundBoundaryIntersection = true
                end
            end
            if nextPosition ~= nil then
                if math.abs(nextPosition[1] - position[1]) < 0.00001 then
                    if position[2] > nextPosition[2] then
                        table.insert(self.trapezoidLines, {
                            { position[1], position[2] },
                            { position[1], nextPosition[2] }
                        })
                    else
                        table.insert(self.trapezoidLines, {
                            { position[1], nextPosition[2] },
                            { position[1], position[2] }
                        })
                    end
                    foundBoundaryIntersection = true
                end
            end
            if not foundBoundaryIntersection then
                local point = { position[1], position[2] }
                table.insert(self.trapezoidLines, { point, point })
            end
        end
    end
end
function TrapezoidDecomposition:generateTrapezoids()
    self.trapezoids = {}
    local lineIndex = 1
    local doNotMergeUntilIndex = 0
    while true do
        local line1 = self.trapezoidLines[lineIndex]
        if line1 == nil then
            break
        end
        local newLine = nil
        local newLineEndIndex = nil
        local nextIndex = lineIndex + 1
        local newLineIndex = #self.trapezoidLines
        local success = 1
        for nextIndex = nextIndex, newLineIndex, success do
            if doNotMergeUntilIndex < nextIndex then
                local nextLine = self.trapezoidLines[nextIndex]
                if math.abs(nextLine[1][1] - self.trapezoidLines[lineIndex][1][1]) < 0.0001 then
                    newLine = newLine == nil and {
                        { line1[1][1], line1[1][2] },
                        { line1[2][1], line1[2][2] }
                    } or newLine
                    newLine[1][2] = math.max(newLine[1][2], nextLine[1][2])
                    newLine[2][2] = math.min(newLine[2][2], nextLine[2][2])
                    newLineEndIndex = nextIndex
                end
            end
        end
        if newLine == nil then
            lineIndex = (function(rootLine, startIndex, minNeigboringCheckIndex, maxNeigboringCheckIndex)
                -- upvalues: (copy) self
                for startIndex = startIndex, #self.trapezoidLines do
                    local nextLine = self.trapezoidLines[startIndex]
                    if nextLine[1][1] > rootLine[1][1] then
                        local connectionAllowed = true
                        if minNeigboringCheckIndex == nil or maxNeigboringCheckIndex == nil then
                        else
                            for minNeigboringCheckIndex = minNeigboringCheckIndex, maxNeigboringCheckIndex do
                                if not TrapezoidDecomposition.getIsNeighbouringLine(self.trapezoidLines[minNeigboringCheckIndex], nextLine, self.boundary, self.trapezoidLines) then
                                    connectionAllowed = false
                                    break
                                end
                            end
                        end
                        if connectionAllowed and TrapezoidDecomposition.getIsNeighbouringLine(rootLine, nextLine, self.boundary, self.trapezoidLines) then
                            local trapezoid = {
                                ["line1"] = rootLine,
                                ["line2"] = nextLine,
                                ["groupId"] = 0,
                                ["size"] = TrapezoidDecomposition.getTrapezoidSize(rootLine, nextLine)
                            }
                            local sameXPosLineIndex = startIndex + 1
                            while true do
                                local i = self.trapezoidLines[sameXPosLineIndex]
                                if i == nil or nextLine[1][1] < i[1][1] then
                                    break
                                end
                                if TrapezoidDecomposition.getIsNeighbouringLine(rootLine, i, self.boundary, self.trapezoidLines) then
                                    local topVertex = {}
                                    __set_list(topVertex, 1, {trapezoid.line2[1][1], (math.max(trapezoid.line2[1][2], i[1][2]))})
                                    __set_list(bottomVertex, 1, {trapezoid.line2[2][1], (math.min(trapezoid.line2[2][2], i[2][2]))})
                                    trapezoid.line2 = { topVertex, bottomVertex }
                                end
                                sameXPosLineIndex = sameXPosLineIndex + 1
                            end
                            local topVertex = self.trapezoids
                            table.insert(topVertex, trapezoid)
                            return startIndex, true
                        end
                    end
                end
                return startIndex, false
            end)(line1, lineIndex + 1)
        else
            local newLineIndex, success = generateTrapezoidFromLine(newLine, newLineEndIndex + 1, lineIndex, newLineEndIndex)
            if success then
                lineIndex = newLineIndex
            else
                lineIndex = generateTrapezoidFromLine(line1, lineIndex + 1)
                doNotMergeUntilIndex = newLineIndex
            end
        end
    end
    local newLineEndIndex = #self.trapezoids
    local line1 = 1
    local newLine = -1
    for newLineEndIndex = newLineEndIndex, line1, newLine do
        local newLineIndex = self.trapezoids[newLineEndIndex]
        if math.abs(newLineIndex.line1[1][1] - newLineIndex.line2[1][1]) < 1e-7 then
            table.remove(self.trapezoids, newLineEndIndex)
        end
    end
end
function TrapezoidDecomposition.getCanTrapezoidsBeMerged(trapezoid1, trapezoid2)
    local function getAngleFromPoints(p1, p2, p3, p4)
        local x2 = p2[1]
        local z2 = p2[2]
        local dir1X, dir1Z = MathUtil.vector2Normalize(p1[1] - x2, p1[2] - z2)
        local dir2X, dir2Z = MathUtil.vector2Normalize(p3[1] - x2, p3[2] - z2)
        local dir3X = p4[1] - x2
        local dir3Z = p4[2] - z2
        local length3 = MathUtil.vector2Length(dir3X, dir3Z)
        if length3 == 0 then
            return math.huge
        end
        local dir3X = dir3X / length3
        local dir3Z = dir3Z / length3
        local dot1 = MathUtil.dotProduct(dir1X, 0, dir1Z, dir3X, 0, dir3Z)
        local dot2 = MathUtil.dotProduct(dir2X, 0, dir2Z, dir3X, 0, dir3Z)
        return math.acos(dot1) + math.acos(dot2)
    end
    if getAngleFromPoints(trapezoid1.line1[1], trapezoid1.line2[1], trapezoid2.line2[1], trapezoid1.line2[2]) > TrapezoidDecomposition.MAX_MERGE_ANGLE then
        return false
    else
        return getAngleFromPoints(trapezoid2.line2[2], trapezoid1.line2[2], trapezoid1.line1[2], trapezoid1.line2[1]) <= TrapezoidDecomposition.MAX_MERGE_ANGLE
    end
end
local function sortLineFunction(a, b)
    return a[2] > b[2]
end
function TrapezoidDecomposition:generateBoundaryByGroupId(groupId, additionalGroupId)
    -- upvalues: (copy) sortLineFunction
    additionalGroupId = additionalGroupId or -1
    local invalidPoints = {}
    local boundaryPositions = {}
    local trapezoidIndex = 1
    local getNextPoint = #self.trapezoids
    for trapezoidIndex = trapezoidIndex, getNextPoint do
        local trapezoid = self.trapezoids[trapezoidIndex]
        if trapezoid.groupId == groupId or trapezoid.groupId == additionalGroupId then
            (function(trapezoidIndex, line)
                -- upvalues: (copy) self, (copy) groupId, (ref) additionalGroupId, (copy) invalidPoints
                local i = 1
                for i = i, 2 do
                    local isValid = false
                    local trapezoidIndex2 = 1
                    for trapezoidIndex2 = trapezoidIndex2, #self.trapezoids do
                        if trapezoidIndex ~= trapezoidIndex2 then
                            local trapezoid2 = self.trapezoids[trapezoidIndex2]
                            if trapezoid2.groupId == groupId or trapezoid2.groupId == additionalGroupId then
                                local j = 1
                                for j = j, 2 do
                                    local p2 = trapezoid2.line1[j]
                                    if math.abs(line[i][1] - p2[1]) >= 1e-7 then
                                        ::l12::
                                        v39_ = false
                                        goto l14
                                    end
                                    if math.abs(p1[2] - p2[2]) >= 1e-7 then
                                        goto l12
                                    end
                                    local v39_ = true
                                    ::l14::
                                    if v39_ then
                                        isValid = true
                                        break
                                    end
                                    local p2 = trapezoid2.line2[j]
                                    if math.abs(p1[1] - p2[1]) >= 1e-7 then
                                        ::l18::
                                        v42_ = false
                                        goto l20
                                    end
                                    if math.abs(p1[2] - p2[2]) >= 1e-7 then
                                        goto l18
                                    end
                                    local v42_ = true
                                    ::l20::
                                    if v42_ then
                                        isValid = true
                                        break
                                    end
                                end
                                if isValid then
                                    break
                                end
                            end
                        end
                    end
                    if not isValid then
                        table.insert(invalidPoints, p1)
                    end
                end
            end)(trapezoidIndex, trapezoid.line1)
            detectInvalidPoints(trapezoidIndex, trapezoid.line2)
        end
    end
    local trapezoidIndex = 1
    local getNextPoint = #self.trapezoids
    for trapezoidIndex = trapezoidIndex, getNextPoint do
        local trapezoid = self.trapezoids[trapezoidIndex]
        if trapezoid.groupId == groupId or trapezoid.groupId == additionalGroupId then
            local points1 = nil
            for _, invalidPoint in ipairs(invalidPoints) do
                local alpha = trapezoid.line1[1][1] - invalidPoint[1]
                if math.abs(alpha) < 0.0001 then
                    local alpha = MathUtil.inverseLerp(trapezoid.line1[1][2], trapezoid.line1[2][2], invalidPoint[2])
                    if alpha > 0 and alpha < 1 then
                        points1 = points1 == nil and {} or points1
                        table.insert(points1, table.clone(invalidPoint))
                    end
                end
            end
            local points2 = nil
            for invalidPoint, alpha in ipairs(invalidPoints) do
                if math.abs(trapezoid.line2[1][1] - alpha[1]) < 0.0001 then
                    local alpha = MathUtil.inverseLerp(trapezoid.line2[1][2], trapezoid.line2[2][2], alpha[2])
                    if alpha > 0 and alpha < 1 then
                        points2 = points2 == nil and {} or points2
                        table.insert(points2, table.clone(alpha))
                    end
                end
            end
            if points1 == nil then
                trapezoid.points1 = trapezoid.line1
            else
                table.insert(points1, trapezoid.line1[1])
                table.insert(points1, trapezoid.line1[2])
                table.sort(points1, sortLineFunction)
                trapezoid.points1 = points1
            end
            if points2 == nil then
                trapezoid.points2 = table.clone(trapezoid.line2, math.huge)
            else
                table.insert(points2, trapezoid.line2[1])
                table.insert(points2, trapezoid.line2[2])
                table.sort(points2, sortLineFunction)
                trapezoid.points2 = table.clone(points2, math.huge)
            end
        end
    end
    local function getNextPoint(index, p, startPoint, skipAdd)
        -- upvalues: (copy) boundaryPositions, (copy) self, (copy) groupId, (ref) additionalGroupId, (copy) getNextPoint
        local ti = p[1] - startPoint[1]
        if math.abs(ti) < 1e-7 then
            local ti = p[2] - startPoint[2]
            if math.abs(ti) < 1e-7 then
                trapezoid = true
                ::l4::
                if trapezoid and #boundaryPositions > 0 then
                    return
                end
                if not skipAdd then
                    table.insert(boundaryPositions, p)
                end
                p.detected = true
                local ti = 1
                local trapezoid = #self.trapezoids
                for ti = ti, trapezoid do
                    if ti ~= index then
                        local trapezoid = self.trapezoids[ti]
                        if trapezoid.groupId == groupId or trapezoid.groupId == additionalGroupId then
                            local i = 1
                            for i = i, #trapezoid.points1 do
                                local p2 = trapezoid.points1[i]
                                if math.abs(p[1] - p2[1]) >= 1e-7 then
                                    ::l19::
                                    v56_ = false
                                    goto l21
                                end
                                if math.abs(p[2] - p2[2]) >= 1e-7 then
                                    goto l19
                                end
                                local v56_ = true
                                ::l21::
                                if v56_ and not trapezoid.points1[i].detected then
                                    return getNextPoint(ti, trapezoid.points1[i], startPoint, true)
                                end
                            end
                            local i = 1
                            for i = i, #trapezoid.points2 do
                                local p2 = trapezoid.points2[i]
                                if math.abs(p[1] - p2[1]) >= 1e-7 then
                                    ::l27::
                                    v60_ = false
                                    goto l29
                                end
                                if math.abs(p[2] - p2[2]) >= 1e-7 then
                                    goto l27
                                end
                                local v60_ = true
                                ::l29::
                                if v60_ and not trapezoid.points2[i].detected then
                                    return getNextPoint(ti, trapezoid.points2[i], startPoint, true)
                                end
                            end
                        end
                    end
                end
                local trapezoid = self.trapezoids[index]
                local trapezoid = 1
                local ti = 1
                for trapezoid = trapezoid, #trapezoid.points1, ti do
                    local nextPoint = trapezoid.points1[trapezoid + 1]
                    if nextPoint == nil then
                        nextPoint = trapezoid.points2[#trapezoid.points2]
                    end
                    if trapezoid.points1[trapezoid] == p and not nextPoint.detected then
                        return getNextPoint(index, nextPoint, startPoint)
                    end
                end
                local trapezoid = #trapezoid.points2
                local ti = -1
                for trapezoid = trapezoid, 1, ti do
                    local nextPoint = trapezoid.points2[trapezoid - 1]
                    if nextPoint == nil then
                        nextPoint = trapezoid.points1[1]
                    end
                    if trapezoid.points2[trapezoid] == p and not nextPoint.detected then
                        return getNextPoint(index, nextPoint, startPoint)
                    end
                end
                return nil
            end
        end
        local trapezoid = false
        goto l4
    end
    local trapezoid = 1
    local trapezoidIndex = 1
    for trapezoid = trapezoid, #self.trapezoids, trapezoidIndex do
        local points1 = self.trapezoids[trapezoid]
        if points1.groupId == groupId or points1.groupId == additionalGroupId then
            getNextPoint(trapezoid, points1.points1[1], points1.points1[1])
            break
        end
    end
    local trapezoid = 1
    local trapezoidIndex = 1
    for trapezoid = trapezoid, #self.trapezoids, trapezoidIndex do
        local points1 = self.trapezoids[trapezoid]
        if points1.groupId == groupId or points1.groupId == additionalGroupId then
            local i = 1
            for i = i, #points1.points1 do
                points1.points1[i].detected = nil
            end
            local i = 1
            for i = i, #points1.points2 do
                points1.points2[i].detected = nil
            end
        end
    end
    if #boundaryPositions <= 0 then
        return nil
    end
    local trapezoid = table.clone
    local points1 = boundaryPositions[1]
    table.insert(boundaryPositions, trapezoid(points1))
    return boundaryPositions
end
function TrapezoidDecomposition:getSizeByGroupId(groupId)
    local size = 0
    local index = 1
    for index = index, #self.trapezoids do
        local trapezoid = self.trapezoids[index]
        if trapezoid.groupId == groupId then
        end
    end
    return size
end
function TrapezoidDecomposition:getLongestLineByGroupId(groupId)
    local longestLine = 0
    local index = 1
    for index = index, #self.trapezoids do
        local trapezoid = self.trapezoids[index]
        if trapezoid.groupId == groupId then
            local length1 = MathUtil.vector2Length(trapezoid.line1[1][1] - trapezoid.line1[2][1], trapezoid.line1[1][2] - trapezoid.line1[2][2])
            local length2 = MathUtil.vector2Length(trapezoid.line2[1][1] - trapezoid.line2[2][1], trapezoid.line2[1][2] - trapezoid.line2[2][2])
            longestLine = math.max(longestLine, length1, length2)
        end
    end
    return longestLine
end
function TrapezoidDecomposition:assignMergeGroups()
    local nextId = 1
    local index1 = 1
    for index1 = index1, #self.trapezoids do
        local isStandalone = true
        local index2 = index1 + 1
        local trapezoid1 = #self.trapezoids
        for index2 = index2, trapezoid1 do
            local trapezoid1 = self.trapezoids[index1]
            local trapezoid2 = self.trapezoids[index2]
            if (trapezoid1.line2 == trapezoid2.line1 or (function(line1, line2)
                return math.abs(line1[1][1] - line2[1][1]) < 0.0001 and (line1[1][2] > line2[1][2] and line1[1][2] < line2[2][2] or line1[2][2] > line2[1][2] and line1[2][2] < line2[2][2])
            end)(trapezoid1.line2, trapezoid2.line1)) and TrapezoidDecomposition.getCanTrapezoidsBeMerged(trapezoid1, trapezoid2) then
                if trapezoid1.groupId == 0 then
                    trapezoid1.groupId = nextId
                    nextId = nextId + 1
                end
                trapezoid2.groupId = trapezoid1.groupId
                isStandalone = false
            end
        end
        if isStandalone then
            local trapezoid1 = self.trapezoids[index1]
            if trapezoid1.groupId == 0 then
                trapezoid1.groupId = nextId
                nextId = nextId + 1
            end
        end
    end
    self.numGroups = nextId - 1
end
function TrapezoidDecomposition:generateGroups()
    self.trapezoidGroups = {}
    local groupId = 1
    for groupId = groupId, self.numGroups do
        local boundaryPositions = self:generateBoundaryByGroupId(groupId)
        if boundaryPositions ~= nil then
            local simplifiedBoundary = table.clone(boundaryPositions)
            FieldCourseUtil.douglasPeucker(simplifiedBoundary, 0.01)
            local sumX = 0
            local sumZ = 0
            local numPositions = #boundaryPositions
            local i = 1
            for i = i, numPositions do

            end
            local centerX = sumX / numPositions
            local i = BoundaryLineGenerationTask.getOptimalBoundaryAngle(centerX, sumZ / numPositions, simplifiedBoundary, TrapezoidDecomposition.OPTIMAL_ANGLE_STEPS)
            local group = {
                ["positions"] = boundaryPositions,
                ["simplifiedBoundary"] = simplifiedBoundary,
                ["size"] = self:getSizeByGroupId(groupId),
                ["longestLine"] = self:getLongestLineByGroupId(groupId),
                ["center"] = { centerX, centerZ },
                ["yRot"] = i
            }
            group.direction = { MathUtil.getDirectionFromYRotation(group.yRot) }
            self.trapezoidGroups[groupId] = group
        end
    end
end
function TrapezoidDecomposition:mergeGroups(groupId1, groupId2)
    local group1 = self.trapezoidGroups[groupId1]
    local group2 = self.trapezoidGroups[groupId2]
    local color = nil
    local indexToChange = 1
    for indexToChange = indexToChange, #self.trapezoids do
        local trapezoidToChange = self.trapezoids[indexToChange]
        if trapezoidToChange.groupId == groupId2 or trapezoidToChange.groupId == groupId1 then
            if color == nil then
                color = trapezoidToChange.color
            end
            trapezoidToChange.groupId = groupId2
            trapezoidToChange.color = color
        end
    end
    local indexToChange = (group2.center[1] + group1.center[1]) * 0.5
    local trapezoidToChange = (group2.center[2] + group1.center[2]) * 0.5
    group2.center[1] = indexToChange
    group2.center[2] = trapezoidToChange
    if group1.size > group2.size then
        group2.yRot = group1.yRot
        group2.direction = group1.direction
    end
    group2.size = group2.size + group1.size
    local indexToChange = group1.longestLine
    group2.longestLine = math.max(group2.longestLine, indexToChange)
    group2.boundaryDirty = true
    self.trapezoidGroups[groupId1] = nil
end
function TrapezoidDecomposition:mergeGroupsBySize()
    local index1 = 1
    for index1 = index1, #self.trapezoids do
        local index2 = index1 + 1
        for index2 = index2, #self.trapezoids do
            local trapezoid1 = self.trapezoids[index1]
            local trapezoid2 = self.trapezoids[index2]
            if trapezoid1.groupId ~= trapezoid2.groupId and (self.trapezoidGroups[trapezoid1.groupId] ~= nil and self.trapezoidGroups[trapezoid2.groupId] ~= nil) then
                local size2 = trapezoid1.line2[1][1] - trapezoid2.line1[1][1]
                if math.abs(size2) < 0.0001 then
                    if self.singleGroupMode then
                        self:mergeGroups(trapezoid1.groupId, trapezoid2.groupId)
                    else
                        local size1 = self.trapezoidGroups[trapezoid1.groupId].size
                        local size2 = self.trapezoidGroups[trapezoid2.groupId].size
                        if size1 / size2 < 0.2 then
                            self:mergeGroups(trapezoid1.groupId, trapezoid2.groupId)
                        elseif size2 / size1 < 0.2 then
                            self:mergeGroups(trapezoid2.groupId, trapezoid1.groupId)
                        end
                    end
                end
            end
        end
    end
end
function TrapezoidDecomposition:mergeGroupsByWorkDirection()
    local index1 = 1
    for index1 = index1, #self.trapezoids do
        local index2 = index1 + 1
        for index2 = index2, #self.trapezoids do
            local trapezoid1 = self.trapezoids[index1]
            local trapezoid2 = self.trapezoids[index2]
            if trapezoid1.groupId ~= trapezoid2.groupId and (self.trapezoidGroups[trapezoid1.groupId] ~= nil and self.trapezoidGroups[trapezoid2.groupId] ~= nil) then
                if math.abs(trapezoid1.line2[1][1] - trapezoid2.line1[1][1]) < 0.0001 then
                    local diff = math.abs(self.trapezoidGroups[trapezoid1.groupId].yRot - self.trapezoidGroups[trapezoid2.groupId].yRot)
                    if diff < TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE or (6.283185307179586 - TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE < diff or 3.141592653589793 - TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE < diff and diff < 3.141592653589793 + TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE) then
                        self:mergeGroups(trapezoid2.groupId, trapezoid1.groupId)
                    end
                end
            end
        end
    end
end
function TrapezoidDecomposition:mergeGroupsByCost()
    local index1 = 1
    for index1 = index1, #self.trapezoids do
        local index2 = index1 + 1
        for index2 = index2, #self.trapezoids do
            local trapezoid1 = self.trapezoids[index1]
            local trapezoid2 = self.trapezoids[index2]
            if trapezoid1.groupId ~= trapezoid2.groupId then
                local sharedLinePct1 = trapezoid1.line2[1][1] - trapezoid2.line1[1][1]
                if math.abs(sharedLinePct1) < 0.0001 then
                    local sharedLineLength = MathUtil.vector2Length(trapezoid1.line2[1][1] - trapezoid1.line2[2][1], trapezoid1.line2[1][2] - trapezoid1.line2[2][2])
                    if TrapezoidDecomposition.MIN_MERGE_LENGTH_PERCENTAGE < sharedLineLength / self.trapezoidGroups[trapezoid1.groupId].longestLine or TrapezoidDecomposition.MIN_MERGE_LENGTH_PERCENTAGE < sharedLineLength / self.trapezoidGroups[trapezoid2.groupId].longestLine then
                        local group1 = self.trapezoidGroups[trapezoid1.groupId]
                        local group2 = self.trapezoidGroups[trapezoid2.groupId]
                        if group1 ~= nil and group2 ~= nil then
                            local combinedBoundaryPositions = self:generateBoundaryByGroupId(trapezoid1.groupId, trapezoid2.groupId)
                            local boundaryPositions1 = self:generateBoundaryByGroupId(trapezoid1.groupId)
                            local boundaryPositions2 = self:generateBoundaryByGroupId(trapezoid2.groupId)
                            if combinedBoundaryPositions ~= nil and (boundaryPositions1 ~= nil and boundaryPositions2 ~= nil) then
                                local numLinesGroup1 = BoundaryLineGenerationTask.getNumLinesByAngle(group1.center[1], group1.center[2], boundaryPositions1, group1.yRot)
                                local numLinesGroup2 = BoundaryLineGenerationTask.getNumLinesByAngle(group2.center[1], group2.center[2], boundaryPositions2, group2.yRot)
                                local numLinesCombined = BoundaryLineGenerationTask.getNumLinesByAngle(group2.center[1], group2.center[2], combinedBoundaryPositions, group1.yRot)
                                if numLinesGroup1 + numLinesGroup2 - numLinesCombined > math.min(numLinesGroup1, numLinesGroup2) * 0.2 then
                                    self:mergeGroups(trapezoid2.groupId, trapezoid1.groupId)
                                else
                                    local numLinesCombined = BoundaryLineGenerationTask.getNumLinesByAngle(group2.center[1], group2.center[2], combinedBoundaryPositions, group2.yRot)
                                    if numLinesGroup1 + numLinesGroup2 - numLinesCombined > math.min(numLinesGroup1, numLinesGroup2) * 0.2 then
                                        self:mergeGroups(trapezoid1.groupId, trapezoid2.groupId)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
function TrapezoidDecomposition:updateGroups()
    for groupId, group in pairs(self.trapezoidGroups) do
        if group.boundaryDirty then
            group.positions = self:generateBoundaryByGroupId(groupId)
            group.simplifiedBoundary = table.clone(group.positions)
            FieldCourseUtil.douglasPeucker(group.simplifiedBoundary, 0.01)
            group.boundaryDirty = false
        end
        group.yRot = BoundaryLineGenerationTask.getOptimalBoundaryAngle(group.center[1], group.center[2], group.simplifiedBoundary, TrapezoidDecomposition.OPTIMAL_ANGLE_STEPS)
        group.direction[1], group.direction[2] = MathUtil.getDirectionFromYRotation(group.yRot)
    end
end
function TrapezoidDecomposition:getGroups()
    return self.trapezoidGroups
end
function TrapezoidDecomposition:draw()
    local y = 0
    for _, trapezoid in ipairs(self.trapezoids) do
        local color = math.max(y, getTerrainHeightAtWorldPos(g_terrainNode, trapezoid.line1[1][1], 0, trapezoid.line1[1][2]))
        local color = math.max(color, getTerrainHeightAtWorldPos(g_terrainNode, trapezoid.line2[1][1], 0, trapezoid.line2[1][2]))
        local color = math.max(color, getTerrainHeightAtWorldPos(g_terrainNode, trapezoid.line1[2][1], 0, trapezoid.line1[2][2]))
        y = math.max(color, getTerrainHeightAtWorldPos(g_terrainNode, trapezoid.line2[2][1], 0, trapezoid.line2[2][2]))
    end
    local y = y + 0.5
    for _, trapezoid in ipairs(self.trapezoids) do
        local color = TrapezoidDecomposition.COLORS[trapezoid.groupId % #TrapezoidDecomposition.COLORS + 1]
        local vtx1 = trapezoid.line1[1]
        local vtx2 = trapezoid.line2[1]
        local vtx3 = trapezoid.line1[2]
        local vtx4 = trapezoid.line2[2]
        drawDebugTriangle(vtx1[1], y + 0.05, vtx1[2], vtx2[1], y + 0.05, vtx2[2], vtx3[1], y + 0.05, vtx3[2], color[1], color[2], color[3], 0.1, false)
        drawDebugLine(vtx1[1], y + 0.05, vtx1[2], color[1], color[2], color[3], vtx2[1], y + 0.05, vtx2[2], color[1], color[2], color[3], true)
        drawDebugLine(vtx3[1], y + 0.05, vtx3[2], color[1], color[2], color[3], vtx4[1], y + 0.05, vtx4[2], color[1], color[2], color[3], true)
        local vtx1 = trapezoid.line2[1]
        local vtx2 = trapezoid.line2[2]
        local vtx3 = trapezoid.line1[2]
        local vtx4 = trapezoid.line1[1]
        drawDebugTriangle(vtx1[1], y + 0.05, vtx1[2], vtx2[1], y + 0.05, vtx2[2], vtx3[1], y + 0.05, vtx3[2], color[1], color[2], color[3], 0.1, false)
        drawDebugLine(vtx1[1], y + 0.05, vtx1[2], color[1], color[2], color[3], vtx2[1], y + 0.05, vtx2[2], color[1], color[2], color[3], true)
        drawDebugLine(vtx3[1], y + 0.05, vtx3[2], color[1], color[2], color[3], vtx4[1], y + 0.05, vtx4[2], color[1], color[2], color[3], true)
        drawDebugPoint(vtx1[1], y + 0.05, vtx1[2], color[1], color[2], color[3], 1, false)
        drawDebugPoint(vtx2[1], y + 0.05, vtx2[2], color[1], color[2], color[3], 1, false)
        drawDebugPoint(vtx3[1], y + 0.05, vtx3[2], color[1], color[2], color[3], 1, false)
        drawDebugPoint(vtx4[1], y + 0.05, vtx4[2], color[1], color[2], color[3], 1, false)
    end
    for _, trapezoid in pairs(self.trapezoidGroups) do
        local i = 1
        for i = i, #trapezoid.simplifiedBoundary - 1 do
            local x1 = trapezoid.simplifiedBoundary[i][1]
            local z1 = trapezoid.simplifiedBoundary[i][2]
            drawDebugLine(x1, y, z1, _ / 5, 1 - _ / 5, 1, trapezoid.simplifiedBoundary[i + 1][1], y, trapezoid.simplifiedBoundary[i + 1][2], _ / 5, 1 - _ / 5, 1, true)
            Utils.renderTextAtWorldPosition(x1, y, z1, string.format("%d", i), 0.015, 0, 0, 1, 1, 1)
        end
        Utils.renderTextAtWorldPosition(trapezoid.center[1], y, trapezoid.center[2], string.format("group%d", _), 0.015, 0, 0, 1, 1, 1)
        drawDebugLine(vtx3, y, vtx4, 0, 1, 0, vtx3 + trapezoid.direction[1] * 10, y, vtx4 + trapezoid.direction[2] * 10, 0, 1, 0, true)
    end
    local i = 1
    for i = i, #self.boundary - 1 do
        drawDebugLine(self.boundary[i][1], y, self.boundary[i][2], 1, 0, 0, self.boundary[i + 1][1], y, self.boundary[i + 1][2], 1, 0, 0, true)
    end
end
function TrapezoidDecomposition.getClosestIntersectionWithBoundary(position, dirX, dirZ, boundary)
    local minDistance = math.huge
    local minDistanceIntersectionX = nil
    local minDistanceIntersectionZ = nil
    local posIndex = 1
    for posIndex = posIndex, #boundary - 1 do
        local p1 = boundary[posIndex]
        local p2 = boundary[posIndex + 1]
        if position ~= p1 and position ~= p2 then
            local lDirX = p2[1] - p1[1]
            local lDirZ = p2[2] - p1[2]
            local length = MathUtil.vector2Length(lDirX, lDirZ)
            local lDirX = lDirX / length
            local lDirZ = lDirZ / length
            local intersect, t1, t2 = MathUtil.getLineLineIntersection2D(position[1], position[2], dirX, dirZ, p1[1], p1[2], lDirX, lDirZ)
            if intersect and (t1 > 0 and (t2 >= 0 and t2 <= length)) then
                local pX = p1[1] + lDirX * t2
                local pZ = p1[2] + lDirZ * t2
                local distance = MathUtil.vector2Length(position[1] - pX, position[2] - pZ)
                if distance > 0.1 and (FieldCourseUtil.getIsSegmentInsideBoundary(position[1], position[2], pX, pZ, boundary) and distance < minDistance) then
                    minDistanceIntersectionZ = pZ
                    minDistanceIntersectionX = pX
                    minDistance = distance
                end
            end
        end
    end
    return minDistanceIntersectionX, minDistanceIntersectionZ
end
function TrapezoidDecomposition.getIsNeighbouringLine(line1, line2, boundary, otherLines)
    local sx = (line1[1][1] + line1[2][1]) * 0.5
    local sz = (line1[1][2] + line1[2][2]) * 0.5
    local ex = (line2[1][1] + line2[2][1]) * 0.5
    local ez = (line2[1][2] + line2[2][2]) * 0.5
    if not FieldCourseUtil.getIsSegmentInsideBoundary(sx, sz, ex, ez, boundary) then
        return false
    end
    for _, otherLine in ipairs(otherLines) do
        if otherLine ~= line1 and (otherLine ~= line2 and MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, otherLine[1][1], otherLine[1][2], otherLine[2][1], otherLine[2][2])) then
            return false
        end
    end
    return true
end
function TrapezoidDecomposition.getTrapezoidSize(line1, line2)
    return math.abs(line1[1][1] - line2[1][1]) * ((line1[1][2] - line1[2][2] + (line2[1][2] - line2[2][2])) * 0.5)
end