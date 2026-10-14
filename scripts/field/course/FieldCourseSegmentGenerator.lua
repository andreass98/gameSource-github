FieldCourseSegmentGenerator = {}
local FieldCourseSegmentGenerator_mt = Class(FieldCourseSegmentGenerator)
function FieldCourseSegmentGenerator.new(fieldCourseSettings, callback)
    -- upvalues: (copy) FieldCourseSegmentGenerator_mt
    local self = setmetatable({}, FieldCourseSegmentGenerator_mt)
    self.fieldCourseSettings = fieldCourseSettings
    self.callback = callback
    self.state = FieldCourseGenerationState.FIELD_DETECTION
    self.frameBudget = 0.00025
    self.numHeadlandsToCreate = fieldCourseSettings.numHeadlands
    self.headlandOnly = false
    self.skipHeadland = false
    self.isVineyardCourse = false
    self.isUICourse = false
    self.headlandBoundaries = {}
    self.linesByGroup = {}
    self.boundaryByGroup = {}
    self.boundaryLineGenerationTasks = {}
    self.currentOverlapLineIndex = 1
    return self
end
function FieldCourseSegmentGenerator:setStartPosition(x, z)
    self.x = x
    self.z = z
end
function FieldCourseSegmentGenerator:setIsUICourse()
    self.isUICourse = true
end
function FieldCourseSegmentGenerator:setFieldData(courseField)
    self.courseField = courseField
    self.islands = courseField.islands
    self.headlandBoundaries = courseField.headlandBoundaries
    self.fieldRootBoundary = courseField.fieldRootBoundary
    self.state = FieldCourseGenerationState.VINEYARD_DETECTION
end
function FieldCourseSegmentGenerator:setHeadlandSettings(headlandOnly, skipHeadland)
    self.headlandOnly = headlandOnly
    self.skipHeadland = skipHeadland
end
function FieldCourseSegmentGenerator:generate()
    g_fieldCourseManager:addFieldCourseToGenerate(self)
    if self.courseField == nil then
        if self.x == nil or self.z == nil then
            self.state = FieldCourseGenerationState.INVALID
            self:finish()
        else
            self.state = FieldCourseGenerationState.FIELD_DETECTION
            self.courseField = FieldCourseField.generateAtPosition(self.x, self.z, self.fieldCourseSettings, function(courseField, success)
                -- upvalues: (copy) self
                if success then
                    self:setFieldData(courseField)
                else
                    self.state = FieldCourseGenerationState.INVALID
                    self:finish()
                end
            end)
        end
    else
        self.state = FieldCourseGenerationState.VINEYARD_DETECTION
        return
    end
end
function FieldCourseSegmentGenerator:update(dt)
    if self.state == FieldCourseGenerationState.FIELD_DETECTION then
        self.courseField:update(dt, self.frameBudget)
    elseif self.state == FieldCourseGenerationState.VINEYARD_DETECTION then
        if self:doVineyardDetection() then
            self.state = FieldCourseGenerationState.FINISHED
        else
            self.state = FieldCourseGenerationState.HEADLAND_CREATION
        end
    elseif self.state == FieldCourseGenerationState.HEADLAND_CREATION then
        if not self:generateNextHeadland() then
            if #self.headlandBoundaries == 0 then
                self.state = FieldCourseGenerationState.INVALID
            elseif self.headlandOnly then
                self.state = FieldCourseGenerationState.FINISHED
            else
                self.state = FieldCourseGenerationState.SUB_AREA_DETECTION
                self.trapezoidDecomposition = TrapezoidDecomposition.new((self.headlandBoundaries[#self.headlandBoundaries] or self.innerBoundary).boundaryLine, self.fieldCourseSettings.workDirection >= -0.01)
            end
        end
    elseif self.state == FieldCourseGenerationState.SUB_AREA_DETECTION then
        if not self.trapezoidDecomposition:update(dt, self.frameBudget) then
            self.state = FieldCourseGenerationState.SUB_AREA_PATH_CREATION
            local singleGroupMode = self.trapezoidDecomposition:getGroups()
            for groupId, group in pairs(singleGroupMode) do
                local groupId, group
                local task = BoundaryLineGenerationTask.new(group.simplifiedBoundary, group.center[1], group.center[2], group.direction[1], group.direction[2], self.islands, self.fieldCourseSettings, function(lines)
                    -- upvalues: (copy) self, (copy) groupId, (copy) group
                    self.linesByGroup[groupId] = lines
                    self.boundaryByGroup[groupId] = group.simplifiedBoundary
                end)
                table.insert(self.boundaryLineGenerationTasks, task)
            end
            self.trapezoidDecomposition = nil
        end
    elseif self.state == FieldCourseGenerationState.SUB_AREA_PATH_CREATION then
        local i = #self.boundaryLineGenerationTasks
        for i = i, 1, -1 do
            if not self.boundaryLineGenerationTasks[i]:update(dt, self.frameBudget) then
                table.remove(self.boundaryLineGenerationTasks, i)
            end
        end
        if #self.boundaryLineGenerationTasks == 0 then
            if self.isUICourse then
                self.state = FieldCourseGenerationState.FINISHED
            elseif self.fieldCourseSettings.segmentExtendedToBoundary then
                self.state = FieldCourseGenerationState.SEGMENT_TO_BOUNDARY_EXTENSION
            else
                self.state = FieldCourseGenerationState.LINE_OVERLAP_CHECKS
            end
        end
    elseif self.state == FieldCourseGenerationState.LINE_OVERLAP_CHECKS then
        local i = getTimeSec()
        local isValid = false
        while true do
            for task, lines in pairs(self.linesByGroup) do
                local line = lines[self.currentOverlapLineIndex]
                if line ~= nil then
                    local positions = line.positions
                    FieldCourseUtil.shrinkSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, task, positions, -1, self.fieldCourseSettings.implementWidth * 0.5, self.fieldCourseSettings.implementWidth * 0.5, self.fieldCourseSettings.implementWidth * 0.1)
                    FieldCourseUtil.shrinkSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, task, positions, 1, singleGroupMode, singleGroupMode, baseBoundary)
                    FieldCourseUtil.extendSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, task, positions, -1, singleGroupMode, singleGroupMode, baseBoundary)
                    FieldCourseUtil.extendSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, task, positions, 1, singleGroupMode, singleGroupMode, baseBoundary)
                    isValid = true
                end
            end
            if not isValid then
                break
            end
            self.currentOverlapLineIndex = self.currentOverlapLineIndex + 1
            if getTimeSec() - i > self.frameBudget then
                break
            end
        end
        if not isValid then
            self.state = FieldCourseGenerationState.FINISHED
        end
    elseif self.state == FieldCourseGenerationState.SEGMENT_TO_BOUNDARY_EXTENSION then
        for groupId, group in pairs(self.linesByGroup) do
            for line, positions in ipairs(group) do
                FieldCourseSegmentGenerator.extendSegmentToBoundary(positions.positions, self.boundaryByGroup[groupId] or (self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary).boundaryLine, self.islands)
            end
        end
        self.state = FieldCourseGenerationState.FINISHED
    end
    if self:getHasFinished() then
        self:finish()
    end
end
function FieldCourseSegmentGenerator:generateNextHeadland()
    if self.numHeadlandsToCreate <= 0 then
        local baseBoundary = self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary
        self.innerBoundary = baseBoundary:extend(self.fieldCourseSettings.implementWidth * 0.5) or baseBoundary
        for _, island in ipairs(self.islands) do
            local i = #island.boundaries
            local island = -1
            for i = i, 1, island do
                if i > 1 and self.innerBoundary:isInsideOf(island.boundaries[i]) then
                    island.boundaries[i] = nil
                end
            end
            local i = #island.boundaries
            local island = -1
            for i = i, 1, island do
                if island.boundaries[i]:removeCollidingSegments(self.fieldRootBoundary, self.fieldCourseSettings.implementWidth * 0.5) then
                    if not island.boundaries[i]:isValid() then
                        table.remove(island.boundaries, i)
                    end
                    island.hasCutSegments = true
                end
            end
            if (island.boundaries[#island.boundaries] or island.rootBoundary):isColliding(self.innerBoundary) and #island.boundaries > 0 then
                local i = #island.boundaries
                local island = 1
                local i = -1
                for i = i, island, i do
                    if i > 1 and island.boundaries[i]:isColliding(self.innerBoundary) then
                        island.boundaries[i] = nil
                    end
                end
            end
            island.validPathBoundary = island.boundaries[1] or island.rootBoundary
            island.innerBoundary = island.validPathBoundary
        end
        for _, island in ipairs(self.headlandBoundaries) do
            for i, island in ipairs(self.islands) do
                island:cut(island.innerBoundary)
            end
        end
        return false
    end
    local offsetBoundary = (self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary):extend(#self.headlandBoundaries == 0 and self.fieldCourseSettings.implementWidth * 0.5 or self.fieldCourseSettings.implementWidth)
    if offsetBoundary == nil then
        self.numHeadlandsToCreate = 0
    else
        table.insert(self.headlandBoundaries, offsetBoundary)
    end
    if self.numHeadlandsToCreate > 0 then
        for baseIslandBoundary, island in ipairs(self.islands) do
            local i = (island.boundaries[#island.boundaries] or island.rootBoundary):extend(#island.boundaries == 0 and -self.fieldCourseSettings.implementWidth * 0.5 or -self.fieldCourseSettings.implementWidth)
            if i ~= nil then
                for _, otherIsland in ipairs(self.islands) do
                    if otherIsland ~= island then
                        for _, otherBoundary in ipairs(otherIsland.boundaries) do
                            if otherBoundary:isColliding(i) then
                                i = nil
                                break
                            end
                        end
                        if i == nil then
                            break
                        end
                    end
                end
                if i ~= nil and #island.boundaries > 0 and (self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary):isColliding(i) then
                    i = nil
                end
                if i ~= nil then
                    table.insert(island.boundaries, i)
                end
            end
        end
    end
    self.numHeadlandsToCreate = self.numHeadlandsToCreate - 1
    return true
end
function FieldCourseSegmentGenerator:getHasFinished()
    return self.state == FieldCourseGenerationState.FINISHED or self.state == FieldCourseGenerationState.INVALID
end
function FieldCourseSegmentGenerator:finish()
    if self.state == FieldCourseGenerationState.FINISHED then
        if self.fieldCourseSettings.segmentHeadlandReverseLines then
            self:doHeadlandReverseSegmentExtension(-1)
        end
        for groupIndex, lines in pairs(self.linesByGroup) do
            local i = 1
            for i = i, #lines do
                local segment = lines[i]
                segment.lineGroupIndex = groupIndex
                segment.isHeadlandSegment = false
                segment.isIslandSegment = false
                table.insert({}, segment)
            end
        end
        if not self.skipHeadland then
            for groupIndex, lines in ipairs(self.islands) do
                for segment, islandBoundary in ipairs(lines.boundaries) do
                    local i = 1
                    for i = i, #islandBoundary.segments do
                        islandBoundary.segments[i].isHeadlandSegment = false
                        islandBoundary.segments[i].isIslandSegment = true
                        islandBoundary.segments[i].islandIndex = groupIndex
                        islandBoundary.segments[i].headlandIndex = segment
                        table.insert(segments, islandBoundary.segments[i])
                    end
                end
            end
            for groupIndex, lines in ipairs(self.headlandBoundaries) do
                local i = 1
                for i = i, #lines.segments do
                    lines.segments[i].isHeadlandSegment = true
                    lines.segments[i].isIslandSegment = false
                    lines.segments[i].headlandIndex = groupIndex
                    table.insert(segments, lines.segments[i])
                end
            end
        end
        local segmentIndex = #segments
        for segmentIndex = segmentIndex, 1, -1 do
            FieldCourseUtil.extendSegmentPositions(segments[segmentIndex], self.fieldCourseSettings.toolFrontOffset)
        end
        local segmentIndex = #segments
        for segmentIndex = segmentIndex, 1, -1 do
            local groupIndex = segments[segmentIndex]
            groupIndex.length = FieldCourseUtil.getSegmentLength(groupIndex.positions)
            if groupIndex.lineGroupIndex ~= nil and groupIndex.length < FieldCourse.MIN_SEGMENT_LENGTH then
                table.remove(segments, segmentIndex)
            end
        end
    end
    if self.callback ~= nil then
        self.callback(segments, self.courseField, self.isVineyardCourse)
    end
end
function FieldCourseSegmentGenerator:doVineyardDetection()
    if g_currentMission.placeableSystem == nil then
        return false
    end
    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        if placeable.spec_vine ~= nil and placeable.spec_fence ~= nil then
            local anyVineInsideBoundary = false
            for i, segment in pairs(placeable.spec_fence.segments) do
                if FieldCourseUtil.getIsPointInsideBoundary(segment.x1, segment.z1, self.fieldRootBoundary.boundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(segment.x2, segment.z2, self.fieldRootBoundary.boundaryLine) then
                    anyVineInsideBoundary = true
                    break
                end
            end
            if anyVineInsideBoundary then
                local group = {}
                local sideOffset = 0
                if self.fieldCourseSettings.isVineyardRowTool then
                    sideOffset = placeable:getSnapDistance() * 0.5
                end
                for i, segment in pairs(placeable.spec_fence.segments) do
                    if FieldCourseUtil.getIsPointInsideBoundary(segment.x1, segment.z1, boundary) or FieldCourseUtil.getIsPointInsideBoundary(segment.x2, segment.z2, boundary) then
                        local sx, sz = MathUtil.vector2Normalize(segment.x2 - segment.x1, segment.z2 - segment.z1)
                        table.insert(group, {
                            { sx - sx * 2, sz - sz * 2 },
                            { segment.x2 + (segment.z1 - (segment.x1 + sz * sideOffset) * sideOffset) * sideOffset + sx * 2, segment.z2 - sx * sideOffset + sz * 2 }
                        })
                        table.insert(group, {
                            { sx - sx * 2, sz - sz * 2 },
                            { segment.x2 - (segment.z1 + (segment.x1 - sz * sideOffset) * sideOffset) * sideOffset + sx * 2, segment.z2 + sx * sideOffset + sz * 2 }
                        })
                    end
                end
                local segment = #group
                local lines = 1
                local i = -1
                for segment = segment, lines, i do
                    local i = group[segment]
                    if i ~= nil then
                        local segment = i[1][1]
                        local dx = i[1][2]
                        local dz = i[2][1]
                        local sx = i[2][2]
                        local sz = dz - segment
                        local ex = sx - dx
                        local ez = MathUtil.vector2Length(sz, ex)
                        local sz = sz / ez
                        local ex = ex / ez
                        local ex = #group
                        local sx = 1
                        local sz = -1
                        for ex = ex, sx, sz do
                            if ex ~= segment then
                                local ez = group[ex]
                                local x3 = ez[1][1]
                                local z3 = ez[1][2]
                                local dot1 = MathUtil.getProjectOnLineParameter(x3, z3, segment, dx, sz, ex)
                                if MathUtil.vector2Length(segment + sz * dot1 - x3, dx + ex * dot1 - z3) < 0.01 then
                                    local dot2 = MathUtil.getProjectOnLineParameter(ez[2][1], ez[2][2], segment, dx, sz, ex)
                                    if dot1 >= -0.25 and (dot1 <= ez + 0.25 and (dot2 >= -0.25 and dot2 <= ez + 0.25)) then
                                        table.remove(group, ex)
                                    elseif dot1 >= -0.25 and dot1 <= ez + 0.25 then
                                        if ez < dot2 then
                                            i[2][1] = x4
                                            i[2][2] = z4
                                            ez = MathUtil.vector2Length(x4 - segment, z4 - dx)
                                            dz = x4
                                            sx = z4
                                        elseif dot2 < 0 then
                                            i[1][1] = x4
                                            i[1][2] = z4
                                            ez = MathUtil.vector2Length(dz - x4, sx - z4)
                                            segment = x4
                                            dx = z4
                                        end
                                    elseif dot2 >= -0.25 and dot2 <= ez + 0.25 then
                                        if dot1 < 0 then
                                            i[1][1] = x3
                                            i[1][2] = z3
                                            ez = MathUtil.vector2Length(dz - x3, sx - z3)
                                            segment = x3
                                            dx = z3
                                        elseif ez < dot2 then
                                            i[2][1] = x3
                                            i[2][2] = z3
                                            ez = MathUtil.vector2Length(x3 - segment, z3 - dx)
                                            dz = x3
                                            sx = z3
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if #group > 0 then
                    local lines = {}
                    local i = 1
                    local i = #group
                    local segment = 1
                    for i = i, i, segment do
                        table.insert(lines, {
                            ["positions"] = group[i]
                        })
                    end
                    local segment = self.linesByGroup
                    table.insert(segment, lines)
                end
            end
        end
    end
    if #self.linesByGroup <= 0 then
        return false
    end
    self.isVineyardCourse = true
    return true
end
function FieldCourseSegmentGenerator:doHeadlandReverseSegmentExtension(direction)
    local maxDistance = math.sqrt(self.fieldCourseSettings.implementWidth ^ 2 + self.fieldCourseSettings.implementWidth ^ 2)
    for headlandIndex, headlandBoundary in ipairs(self.headlandBoundaries) do
        local i = 1
        for i = i, #headlandBoundary.segments do
            local segment = headlandBoundary.segments[i]
            local prevSegment = headlandBoundary.segments[i - 1]
            if prevSegment == nil then
                prevSegment = headlandBoundary.segments[#headlandBoundary.segments]
            end
            local dirX, dirZ = MathUtil.vector2Normalize(segment.positions[2][1] - segment.positions[1][1], segment.positions[2][2] - segment.positions[1][2])
            local numPositions = #prevSegment.positions
            local nextDirX, nextDirZ = MathUtil.vector2Normalize(prevSegment.positions[numPositions][1] - prevSegment.positions[numPositions - 1][1], prevSegment.positions[numPositions][2] - prevSegment.positions[numPositions - 1][2])
            if math.acos((FieldCourseUtil.vector2Dot(dirX, dirZ, nextDirX, nextDirZ))) > 0.7853981633974483 then
                if direction == nil or direction == 1 then
                    FieldCourseUtil.extendSegmentToBoundary(segment.positions, self.fieldRootBoundary.boundaryLine, true, false, maxDistance)
                else
                    FieldCourseUtil.extendSegmentToBoundary(prevSegment.positions, self.fieldRootBoundary.boundaryLine, false, true, maxDistance)
                end
            end
        end
    end
end
function FieldCourseSegmentGenerator.extendSegmentToBoundary(positions, boundary, islands, maxDistance)
    maxDistance = maxDistance or math.huge
    local function getSegmentClosestBoundariesIntersection(l1x, l1z, l2x, l2z)
        -- upvalues: (copy) boundary, (copy) islands
        local minDistance = math.huge
        local ix = nil
        local iz = nil
        local i = 1
        for i = i, #boundary - 1 do
            local intersect, x, z = MathUtil.getLineSegmentsIntersection(boundary[i][1], boundary[i][2], boundary[i + 1][1], boundary[i + 1][2], l1x, l1z, l2x, l2z)
            if intersect then
                local distance = MathUtil.vector2Length(l1x - x, l1z - z)
                if distance < minDistance then
                    iz = z
                    ix = x
                    minDistance = distance
                end
            end
        end
        for sx, sz in ipairs(islands) do
            local ex = sz.boundaries[#sz.boundaries] or sz.rootBoundary
            if ex ~= nil then
                local x = 1
                local ez = #ex.boundaryLine - 1
                local intersect = 1
                for x = x, ez, intersect do
                    local z = ex.boundaryLine[x][1]
                    local distance = ex.boundaryLine[x][2]
                    local intersect, x, z = MathUtil.getLineSegmentsIntersection(z, distance, ex, ex.boundaryLine[x + 1][1].boundaryLine[x + 1][2], l1x, l1z, l2x, l2z)
                    if intersect then
                        local distance = MathUtil.vector2Length(l1x - x, l1z - z)
                        if distance < minDistance then
                            iz = z
                            ix = x
                            minDistance = distance
                        end
                    end
                end
            end
        end
        return minDistance ~= math.huge, ix, iz
    end
    local p1 = positions[1]
    local p2 = positions[2]
    local dirX = p1[1] - p2[1]
    local dirZ = p1[2] - p2[2]
    local length = MathUtil.vector2Length(dirX, dirZ)
    local dirX = dirX / length
    local dirZ = dirZ / length
    local intersect1, ix1, iz1 = getSegmentClosestBoundariesIntersection(p1[1] - dirX * 0.1, p1[2] - dirZ * 0.1, p1[1] + dirX * 65535, p1[2] + dirZ * 65535)
    if intersect1 and MathUtil.vector2Length(ix1 - p1[1], iz1 - p1[2]) < maxDistance then
        p1[1] = ix1
        p1[2] = iz1
    end
    local p1 = positions[#positions]
    local p2 = positions[#positions - 1]
    local dirX = p1[1] - p2[1]
    local dirZ = p1[2] - p2[2]
    local extensionLength = MathUtil.vector2Length(dirX, dirZ)
    local dirX = dirX / extensionLength
    local dirZ = dirZ / extensionLength
    local extensionLength, ix1, iz1 = getSegmentClosestBoundariesIntersection(p1[1] - dirX * 0.1, p1[2] - dirZ * 0.1, p1[1] + dirX * 65535, p1[2] + dirZ * 65535)
    if extensionLength and MathUtil.vector2Length(ix1 - p1[1], iz1 - p1[2]) < maxDistance then
        p1[1] = ix1
        p1[2] = iz1
    end
end