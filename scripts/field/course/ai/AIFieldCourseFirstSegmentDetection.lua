AIFieldCourseFirstSegmentDetection = {}
local AIFieldCourseFirstSegmentDetection_mt = Class(AIFieldCourseFirstSegmentDetection)
function AIFieldCourseFirstSegmentDetection.new(aiFieldCourse, segmentOrderTask)
    -- upvalues: (copy) AIFieldCourseFirstSegmentDetection_mt
    local self = setmetatable({}, AIFieldCourseFirstSegmentDetection_mt)
    self.aiFieldCourse = aiFieldCourse
    self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
    self.segmentOrderTask = segmentOrderTask
    self.segments = segmentOrderTask.segments
    self.segmentsToSkip = {}
    self.lastActiveSegmentId = nil
    return self
end
function AIFieldCourseFirstSegmentDetection:setStartPosition(startX, startZ, dirX, dirZ)
    self.startX = startX
    self.startZ = startZ
    self.startDirX = dirX
    self.startDirZ = dirZ
end
function AIFieldCourseFirstSegmentDetection:setSegmentsToSkip(segmentsToSkip)
    self.segmentsToSkip = segmentsToSkip
end
function AIFieldCourseFirstSegmentDetection:setLastActiveSegmentId(lastActiveSegmentId)
    self.lastActiveSegmentId = lastActiveSegmentId
end
function AIFieldCourseFirstSegmentDetection:setCallback(callbackFunc, callbackTarget)
    self.callbackFunc = callbackFunc
    self.callbackTarget = callbackTarget
end
function AIFieldCourseFirstSegmentDetection:detect()
    if self.lastActiveSegmentId ~= nil then
        local hasSegment = false
        for _, segment in ipairs(self.segments) do
            if self.segmentsToSkip[segment.segmentId] == nil and (self.lastActiveSegmentId == nil or self.lastActiveSegmentId == segment.segmentId) then
                hasSegment = true
                break
            end
        end
        if not hasSegment then
            self.lastActiveSegmentId = false
        end
    end
    local hasSegment = 0
    local numHeadlandSegments = 0
    for segment, segment in ipairs(self.segments) do
        if self.segmentsToSkip[segment.segmentId] == nil and (self.lastActiveSegmentId == nil or self.lastActiveSegmentId == segment.segmentId) then
            if segment.lineGroupIndex ~= nil then
            end
            if segment.isHeadlandSegment then
            end
        end
    end
    if self.fieldCourseSettings.headlandsFirst then
        if numHeadlandSegments > 0 then
            ::l22::
            local numHeadlands = 0
            local numHeadlands
            if true then
                for _, segment in ipairs(self.segments) do
                    if self.segmentsToSkip[segment.segmentId] == nil and (self.lastActiveSegmentId == nil or self.lastActiveSegmentId == segment.segmentId) and segment.isHeadlandSegment then
                        numHeadlands = math.max(numHeadlands, segment.headlandIndex)
                    end
                end
                if numHeadlands > 0 then
                    local segment = 1
                    local segment = 1
                    for segment = segment, numHeadlands, segment do
                        self:splitClosestSegment(self.startX, self.startZ, self.startDirX, self.startDirZ, true, segment)
                    end
                end
            else
                self:splitClosestSegment(self.startX, self.startZ, self.startDirX, self.startDirZ, false, nil)
            end
            self.potentialSegments = {}
            for _, segment in ipairs(self.segments) do
                if self.segmentsToSkip[segment.segmentId] == nil and (self.lastActiveSegmentId == nil or self.lastActiveSegmentId == segment.segmentId) then
                    if headlandsFirst then
                        if segment.isHeadlandSegment then
                            if segment.lockedDirection == nil or segment.lockedDirection == 1 then
                                table.insert(self.potentialSegments, {
                                    ["segment"] = segment,
                                    ["direction"] = 1,
                                    ["score"] = self:getSegmentScore(segment, 1) * (1 - (segment.headlandIndex - 1) / numHeadlands)
                                })
                            end
                            if segment.lockedDirection == nil or segment.lockedDirection == -1 then
                                table.insert(self.potentialSegments, {
                                    ["segment"] = segment,
                                    ["direction"] = -1,
                                    ["score"] = self:getSegmentScore(segment, -1) * scoreScale
                                })
                            end
                        end
                    elseif segment.lineGroupIndex ~= nil then
                        if segment.lockedDirection == nil or segment.lockedDirection == 1 then
                            table.insert(self.potentialSegments, {
                                ["segment"] = segment,
                                ["direction"] = 1,
                                ["score"] = self:getSegmentScore(segment, 1)
                            })
                        end
                        if segment.lockedDirection == nil or segment.lockedDirection == -1 then
                            table.insert(self.potentialSegments, {
                                ["segment"] = segment,
                                ["direction"] = -1,
                                ["score"] = self:getSegmentScore(segment, -1)
                            })
                        end
                    end
                end
            end
            table.sort(self.potentialSegments, function(a, b)
                return a.score > b.score
            end)
            g_fieldCourseManager:addUpdateable(self)
            return
        end
    end
    local headlandsFirst = not self.fieldCourseSettings.headlandsFirst
    if headlandsFirst then
        headlandsFirst = hasSegment == 0
    end
    goto l22
end
function AIFieldCourseFirstSegmentDetection:debugScoring()
    for i, segmentData in ipairs(self.potentialSegments) do
        local x, z = AIFieldCourseUtil.getSegmentPosition(segmentData.direction == 1, segmentData.segment, 1)
        dp(x, z, string.format("seg%d d%d s%.4f", segmentData.segment.index, segmentData.direction, segmentData.score), i * 0.1)
    end
end
function AIFieldCourseFirstSegmentDetection:update(_)
    if #self.potentialSegments > 0 then
        if not self.overlapInProgress then
            local sizeY = self.fieldCourseSettings.agentHeight + 0.5
            local sizeZ = self.fieldCourseSettings.toolBackOffset + self.fieldCourseSettings.agentBackOffset
            local segmentData = self.potentialSegments[1]
            local sx, sz = AIFieldCourseUtil.extendHeadlandSegment(self.segments, segmentData.segment.index, -segmentData.direction, 1, self.fieldCourseSettings.implementWidth, self.aiFieldCourse.fieldRootBoundary.boundaryLine, false)
            local x1 = AIFieldCourseUtil.getSegmentPosition
            local z1 = segmentData.direction == 1
            local x1, z1 = x1(z1, segmentData.segment, 1)
            if sx == nil then
                sx = x1
                sz = z1
            end
            local x2, z2 = AIFieldCourseUtil.getSegmentPosition(segmentData.direction == 1, segmentData.segment, 1, 1)
            local dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
            local bx = sx - dirX * (sizeZ * 0.5)
            local bz = sz - dirZ * (sizeZ * 0.5)
            local by = MathUtil.getYRotationFromDirection(dirX, dirZ)
            local by = getTerrainHeightAtWorldPos(g_terrainNode, bx, 0, bz) + sizeY * 0.5
            overlapBoxAsync(bx, by, bz, 0, by, 0, (self.fieldCourseSettings.implementWidth + 0.5) * 0.5, sizeY * 0.5, sizeZ * 0.5, "overlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
            self.overlapInProgress = true
            return
        end
    else
        g_fieldCourseManager:removeUpdateable(self)
        self:doCallback(false, nil, 1)
    end
end
function AIFieldCourseFirstSegmentDetection:overlapCallback(nodeId, _)
    if nodeId == 0 then
        g_fieldCourseManager:removeUpdateable(self)
        local segmentData = self.potentialSegments[1]
        self:doCallback(true, segmentData.segment, segmentData.direction)
    else
        table.remove(self.potentialSegments, 1)
    end
    self.overlapInProgress = false
    return false
end
function AIFieldCourseFirstSegmentDetection:getSegmentScore(segment, direction)
    local sx, sz = AIFieldCourseUtil.getSegmentPosition(direction == 1, segment, 1)
    local ox, oz = AIFieldCourseUtil.getSegmentPosition(direction == 1, segment, 1, 1)
    local dx, dz = MathUtil.vector2Normalize(ox - sx, oz - sz)
    local dot = MathUtil.dotProduct(self.startDirX, 0, self.startDirZ, dx, 0, dz)
    local distance = MathUtil.vector2Length(sx - self.startX, sz - self.startZ)
    return (dot + 1) * 0.5 * (1 - math.min(distance / 100, 0.99))
end
function AIFieldCourseFirstSegmentDetection:doCallback(success, segment, segmentDirection)
    if self.callbackTarget == nil then
        self.callbackFunc(success, segment, segmentDirection)
    else
        self.callbackFunc(self.callbackTarget, success, segment, segmentDirection)
    end
end
function AIFieldCourseFirstSegmentDetection.debugPrint(_, text, ...)
    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
        print("AIFieldCourseFirstSegmentDetection: " .. string.format(text, ...))
    end
end
function AIFieldCourseFirstSegmentDetection:splitClosestSegment(x1, z1, dirX, dirZ, headlandSegment, headlandIndex)
    if dirX ~= nil and dirZ ~= nil then
        if self.fieldCourseSettings.toolFullOverlap then
            local toolFrontOffset = self.fieldCourseSettings.toolFrontOffset
        else
            local toolFrontOffset = self.fieldCourseSettings.toolBackOffset
        end
    end
    local toolFrontOffset = math.huge
    for _, segment in ipairs(self.segments) do
        local x2
        if headlandSegment then
            x2 = segment.isHeadlandSegment or segment.isIslandSegment
            if x2 then
                x2 = true
                if headlandIndex ~= nil then
                    x2 = segment.headlandIndex == headlandIndex
                end
            end
        else
            x2 = segment.lineGroupIndex ~= nil
        end
        if x2 then
            local x2, z2 = AIFieldCourseUtil.getSegmentPosition(true, segment, 1)
            local x3, z3 = AIFieldCourseUtil.getSegmentPosition(false, segment, 1)
            local startDistance = MathUtil.vector2Length(x2 - x1, z2 - z1)
            if startDistance >= toolFrontOffset then
                startDistance = toolFrontOffset
            end
            toolFrontOffset = MathUtil.vector2Length(x3 - x1, z3 - z1)
            if toolFrontOffset >= startDistance then
                toolFrontOffset = startDistance
            end
        end
    end
    if toolFrontOffset ~= math.huge then
        local minSideOffset = math.huge
        local minSideOffsetSegmentIndex = nil
        local minSideOffsetSegmentPosIndex = nil
        for x2, z2 in ipairs(self.segments) do
            local z3
            if headlandSegment then
                z3 = z2.isHeadlandSegment or z2.isIslandSegment
                if z3 then
                    z3 = true
                    if headlandIndex ~= nil then
                        z3 = z2.headlandIndex == headlandIndex
                    end
                end
            else
                z3 = z2.lineGroupIndex ~= nil
            end
            if z3 then
                local z3, startDistance = AIFieldCourseUtil.getSegmentSideOffset(z2, x1, z1, false)
                if z3 < toolFrontOffset and z3 < minSideOffset then
                    minSideOffsetSegmentPosIndex = startDistance
                    minSideOffsetSegmentIndex = x2
                    minSideOffset = z3
                end
            end
        end
        if minSideOffsetSegmentIndex ~= nil then
            local _ = self.segments[minSideOffsetSegmentIndex]
            local segment = _.positions[minSideOffsetSegmentPosIndex][1]
            local isAllowed = _.positions[minSideOffsetSegmentPosIndex][2]
            local x3 = _.positions[minSideOffsetSegmentPosIndex + 1][1] - segment
            local z3 = _.positions[minSideOffsetSegmentPosIndex + 1][2] - isAllowed
            local startDistance = MathUtil.vector2Length(x3, z3)
            local x3 = x3 / startDistance
            local z3 = z3 / startDistance
            local nextLength = startDistance - 0.1
            local splitX = math.clamp(MathUtil.getProjectOnLineParameter(x1, z1, segment, isAllowed, x3, z3), 0.1, nextLength)
            local splitX = segment + x3 * splitX
            local splitZ = isAllowed + z3 * splitX
            local nextLength = 2
            for minSideOffsetSegmentPosIndex = minSideOffsetSegmentPosIndex, nextLength, -1 do
                splitX = splitX + MathUtil.vector2Length(_.positions[minSideOffsetSegmentPosIndex][1] - _.positions[minSideOffsetSegmentPosIndex - 1][1], _.positions[minSideOffsetSegmentPosIndex][2] - _.positions[minSideOffsetSegmentPosIndex - 1][2])
            end
            local nextLength = startDistance - splitX
            local px1 = minSideOffsetSegmentPosIndex + 1
            local i = 1
            for px1 = px1, #_.positions - 1, i do
                nextLength = nextLength + MathUtil.vector2Length(_.positions[px1][1] - _.positions[px1 + 1][1], _.positions[px1][2] - _.positions[px1 + 1][2])
            end
            local i = self.fieldCourseSettings.implementWidth
            local minDistanceToSegmentEnd = math.max(i, 5)
            if splitX < minDistanceToSegmentEnd or nextLength < minDistanceToSegmentEnd then
                return
            end
            local i = table.clone(_, math.huge)
            local px2 = #_.positions
            local px1 = minSideOffsetSegmentPosIndex + 2
            local pz1 = -1
            for px2 = px2, px1, pz1 do
                table.remove(_.positions, px2)
            end
            local px1 = _.positions[minSideOffsetSegmentPosIndex + 1]
            local pz1 = _.positions[minSideOffsetSegmentPosIndex + 1]
            px1[1] = splitX
            pz1[2] = splitZ
            local px2 = minSideOffsetSegmentPosIndex - 1
            local px1 = 1
            local pz1 = -1
            for px2 = px2, px1, pz1 do
                table.remove(i.positions, px2)
            end
            local px1 = i.positions[1]
            local pz1 = i.positions[1]
            px1[1] = splitX
            pz1[2] = splitZ
            local px1 = i.positions[#i.positions][1]
            local pz1 = i.positions[#i.positions][2]
            local px2 = self.segments[minSideOffsetSegmentIndex + 1]
            local pz2 = self.segments[minSideOffsetSegmentIndex - 1]
            if px2 == nil then
                table.insert(self.segments, i)
            elseif pz2 == nil then
                table.insert(self.segments, 1, i)
            else
                local pz2, nz2 = AIFieldCourseUtil.getSegmentPosition(true, px2, 1)
                local nx3, nz3 = AIFieldCourseUtil.getSegmentPosition(false, px2, 1)
                local px2 = MathUtil.vector2Length(px1 - pz2, pz1 - nz2)
                local nextDistance = math.min(px2, MathUtil.vector2Length(px1 - nx3, pz1 - nz3))
                local px2, pz2 = AIFieldCourseUtil.getSegmentPosition(true, pz2, 1)
                local px3, pz3 = AIFieldCourseUtil.getSegmentPosition(false, pz2, 1)
                if nextDistance < math.min(MathUtil.vector2Length(px1 - px2, pz1 - pz2), MathUtil.vector2Length(px1 - px3, pz1 - pz3)) then
                    table.insert(self.segments, minSideOffsetSegmentIndex + 1, i)
                else
                    table.insert(self.segments, minSideOffsetSegmentIndex, i)
                end
            end
            for nz3, nextDistance in ipairs(self.segments) do
                nextDistance.index = nz3
            end
        end
    end
    return false
end