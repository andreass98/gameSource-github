AIFieldCourse = {}
source("dataS/scripts/field/course/ai/AIFieldCourseState.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseUtil.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseReconstructionData.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseCornerCutOut.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseFirstSegmentDetection.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseInitialSegment.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseSegment.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseSegmentOrderTask.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseSegmentCollisionCheck.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurn.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnCollisionCheck.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnData.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnSegment.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnSegmentType.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnGenerator.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnGeneratorState.lua")
source("dataS/scripts/field/course/ai/dubinsPath/DubinsPath.lua")
source("dataS/scripts/field/course/ai/reedsSheppPath/ReedsSheppPath.lua")
AIFieldCourse.SEGMENT_INITIALIZATION_BUDGET = 0.00025
AIFieldCourse.SEGMENT_INITIALIZATION_STEP = 10
AIFieldCourse.QUEUE_MIN_LENGTH = 2
local AIFieldCourse_mt = Class(AIFieldCourse)
function AIFieldCourse.new(fieldCourse)
    -- upvalues: (copy) AIFieldCourse_mt
    local self = setmetatable({}, AIFieldCourse_mt)
    self.fieldCourse = fieldCourse
    self.fieldCourseSettings = fieldCourse.fieldCourseSettings
    self.fieldRootBoundary = fieldCourse.courseField.fieldRootBoundary
    self.islands = fieldCourse.courseField.islands
    self.headlandBoundaries = fieldCourse.courseField.headlandBoundaries
    self.implementWidth = self.fieldCourseSettings.implementWidth
    self.segmentAreaValidityFunc = nil
    self.startX = nil
    self.startZ = nil
    self.startYRot = nil
    self.startDirX = nil
    self.startDirZ = nil
    self.lastVehicleX = nil
    self.lastVehicleZ = nil
    self.alternativeTurnSegments = {}
    self.segmentQueue = {}
    self.segmentPosition = 0
    self.segmentLength = 1
    self.subSegmentPosition = 0
    self.subSegmentLength = 1
    self.usedSegments = {}
    self.state = AIFieldCourseState.NONE
    self.lastSegmentLength = -1
    self.segmentInitializeIndex = 1
    self.segmentInitializeTime = 0
    self.segmentInitializeFrames = 0
    self.segmentsToSkip = {}
    self.lastActiveSegmentId = nil
    self.headlandTailAvoidanceIndex = 1
    self.headlandTailAvoidanceMaxIndex = -1
    return self
end
function AIFieldCourse:setStartPosition(x, z, yRot)
    self.startX = x
    self.startZ = z
    self.startYRot = yRot
    self.startDirX, self.startDirZ = MathUtil.getDirectionFromYRotation(yRot)
end
function AIFieldCourse:setInitialSegmentCallback(callback)
    self.initialSegmentCallback = callback
    self.initialSegmentDone = false
end
function AIFieldCourse:setSegmentsToSkip(segmentsToSkip)
    self.segmentsToSkip = segmentsToSkip
end
function AIFieldCourse:setLastActiveSegmentId(lastActiveSegmentId)
    self.lastActiveSegmentId = lastActiveSegmentId
end
function AIFieldCourse:finalize(finalizeCallback, finalizeCallbackTarget)
    if self.fieldCourse.courseField == nil then
        Logging.error("Invalid AIFieldCourse. Missing field data in FieldCourse.")
    else
        self.fieldRootBoundary = self.fieldCourse.courseField.fieldRootBoundary
        self.protectedBoundary = self.fieldCourse.courseField:setProtectedBoundary(self.fieldCourseSettings:getProtectedBoundarySize())
        self.validPathBoundary = self.headlandBoundaries[1] or self.fieldRootBoundary
        self.islands = self.fieldCourse.courseField.islands
        self.segmentOrderTask = AIFieldCourseSegmentOrderTask.new(self)
        if self.overwrittenSegments ~= nil then
            self.segmentOrderTask:setOverwrittenSegments(self.overwrittenSegments)
        end
        self.segmentOrderTask:setSegmentsToSkip(self.segmentsToSkip)
        self.segmentOrderTask:setLastActiveSegmentId(self.lastActiveSegmentId)
        self.segmentOrderTask:setAlternativeTurnSegmentData(self.alternativeTurnSegments)
        self.finalizeCallback = finalizeCallback
        self.finalizeCallbackTarget = finalizeCallbackTarget
        self.state = AIFieldCourseState.INITIALIZATION
    end
end
function AIFieldCourse:setOverwrittenSegments(overwrittenSegments)
    self.overwrittenSegments = overwrittenSegments
end
function AIFieldCourse:setSegmentSwitchedCallback(segmentSwitchedCallback)
    self.segmentSwitchedCallback = segmentSwitchedCallback
end
function AIFieldCourse:onNextSegmentFound(segmentData, direction, isTurn, addStraighting, nextTurn, _)
    if segmentData == nil then
        if self.state ~= AIFieldCourseState.NO_MORE_SEGMENTS_FOUND then
            self:debugPrint("No more new segments found. Finishing segment queue.")
            self.state = AIFieldCourseState.NO_MORE_SEGMENTS_FOUND
        end
        return
    end
    local nextAvailableSegment = nil
    local i = 1
    for i = i, #self.segmentQueue do
        local segment = self.segmentQueue[i]
        if not segment:isValid() and segment:isReady() then
            nextAvailableSegment = segment
            break
        end
    end
    if nextAvailableSegment == nil then
        table.insert(self.segmentQueue, AIFieldCourseSegment.new(self.fieldCourseSettings))
        nextAvailableSegment = self.segmentQueue[#self.segmentQueue]
    end
    if isTurn then
        self.lastTurn = segmentData
        nextAvailableSegment:setTurn(segmentData, addStraighting)
    else
        nextAvailableSegment:setSegment(segmentData, direction, self.lastTurn, nextTurn)
    end
end
function AIFieldCourse:skipCurrentSubSegment(maxDistance)
    local segment = self.segmentQueue[1]
    if segment ~= nil and (segment:isReady() and segment:isValid()) then
        segment:skipCurrentSubSegment(maxDistance)
        self:update(999)
    end
end
function AIFieldCourse:setSegmentAreaValidityFunction(segmentAreaValidityFunc)
    self.segmentAreaValidityFunc = segmentAreaValidityFunc
end
function AIFieldCourse:getIsSegmentAreaValid(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return self.segmentAreaValidityFunc == nil or self.segmentAreaValidityFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end
function AIFieldCourse:getActiveSegment()
    local segment = self.segmentQueue[1]
    if segment == nil or not (segment:isValid() and segment:isReady()) then
        return nil
    else
        return segment
    end
end
function AIFieldCourse:getActiveSegmentData()
    local segment = self.segmentQueue[1]
    if segment == nil or not (segment:isValid() and segment:isReady()) then
        return nil, nil, nil, nil, nil
    else
        return not segment:getIsOnActualLine(), segment.isInitialLine, self.segmentPosition, self.segmentLength, self.subSegmentPosition, self.subSegmentLength
    end
end
function AIFieldCourse:getIsCornerCutOutActive()
    local segment = self.segmentQueue[1]
    if segment == nil or not (segment:isValid() and segment:isReady()) then
        return false
    else
        return segment.isCornerCutOut
    end
end
function AIFieldCourse:getNextSegmentData()
    local segment = self.segmentQueue[2]
    if segment == nil or not (segment:isValid() and segment:isReady()) then
        return nil, nil
    else
        return segment.isInitialLine, segment.sideOffset
    end
end
function AIFieldCourse:getActiveSegmentSideOffset()
    local segment = self.segmentQueue[1]
    return (segment == nil or not (segment:isValid() and segment:isReady())) and 0 or segment.sideOffset
end
function AIFieldCourse:getPositionOffsetToActiveSegment(x, z)
    local segment = self.segmentQueue[1]
    return (segment == nil or not (segment:isValid() and segment:isReady())) and math.huge or segment:getSignedOffsetToSegment(x, z)
end
function AIFieldCourse:update(_, forceSegmentSkip)
    if self.state == AIFieldCourseState.INITIALIZATION then
        local startTime = getTimeSec()
        while self:updateSegmentInitialization() do
            local delta = getTimeSec() - startTime
            if AIFieldCourse.SEGMENT_INITIALIZATION_BUDGET < delta then
                self.segmentInitializeFrames = self.segmentInitializeFrames + 1
                self.segmentInitializeTime = self.segmentInitializeTime + delta
                return
            end
        end
        self.segmentInitializeFrames = self.segmentInitializeFrames + 1
        self.segmentInitializeTime = self.segmentInitializeTime + (getTimeSec() - startTime)
        for index, segment in ipairs(self.fieldCourse.segments) do
            segment.index = index
        end
        local delta = self.fieldCourseSettings.sideOffset
        if delta ~= 0 then
            for segment, segment in ipairs(self.fieldCourse.segments) do
                if segment.isHeadlandSegment or segment.isIslandSegment then
                    if self.fieldCourseSettings.sideOffsetHeadlandAlternate then
                        if segment.headlandIndex % 2 == 0 then
                            segment.sideOffset = -delta
                            segment.sideOffsetToApply = -math.abs(delta)
                            segment.lockedDirection = -math.sign(delta)
                        else
                            segment.sideOffset = delta
                            segment.sideOffsetToApply = math.abs(delta)
                            segment.lockedDirection = math.sign(delta)
                        end
                    elseif delta > 0 then
                        segment.sideOffset = -delta
                        segment.sideOffsetToApply = -delta
                        segment.lockedDirection = -1
                    else
                        segment.sideOffset = delta
                        segment.sideOffsetToApply = delta
                        segment.lockedDirection = 1
                    end
                end
            end
        end
        if self.fieldCourseSettings.skipNumLines > 0 then
            local index = #self.fieldCourse.segments
            local index = -1
            for index = index, 1, index do
                local segment = self.fieldCourse.segments[index]
                if segment.lineGroupIndex ~= nil and (segment.offsetLineIndex - 1) % (self.fieldCourseSettings.skipNumLines + 1) ~= 0 then
                    table.remove(self.fieldCourse.segments, index)
                end
            end
        end
        if not self.fieldCourseSettings.workHeadlands then
            local index = #self.fieldCourse.segments
            local index = -1
            for index = index, 1, index do
                local segment = self.fieldCourse.segments[index]
                if segment.isHeadlandSegment or segment.isIslandSegment then
                    table.remove(self.fieldCourse.segments, index)
                end
            end
        end
        for segment, segment in ipairs(self.fieldCourse.segments) do
            segment.index = segment
        end
        self.state = AIFieldCourseState.HEADLAND_TAIL_AVOIDANCE
        self:debugPrint("Segment initialization took %.1fms / %d frames", self.segmentInitializeTime * 1000, self.segmentInitializeFrames)
    elseif self.state == AIFieldCourseState.HEADLAND_TAIL_AVOIDANCE then
        if not (self.fieldCourseSettings.headlandTailAvoidance and self.fieldCourseSettings.workHeadlands) then
            self.state = AIFieldCourseState.INITIAL_SEGMENT_CREATION
            return
        end
        if not self:updateHeadlandTailAvoidance() then
            for index, index in ipairs(self.fieldCourse.segments) do
                index.index = index
            end
            self.state = AIFieldCourseState.INITIAL_SEGMENT_CREATION
            return
        end
    elseif self.state == AIFieldCourseState.INITIAL_SEGMENT_CREATION then
        if self.initialSegment == nil then
            if #self.fieldCourse.segments == 0 then
                self:debugPrint("No valid segments found. Stopping AI.")
                self.state = AIFieldCourseState.FINISHED
                if self.finalizeCallback ~= nil then
                    self.finalizeCallback(self.finalizeCallbackTarget)
                    self.finalizeCallback = nil
                end
            else
                self:debugPrint("Initial segment detection")
                self.initialSegment = AIFieldCourseInitialSegment.new(self)
                self.initialSegment:setCallback(function(success, isLast, segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
                    -- upvalues: (copy) self
                    if success then
                        self:onNextSegmentFound(segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
                        if isLast then
                            if self.initialSegment.intoFieldSegment == nil then
                                self:debugPrint("No into field segment found. Directly prepare for work.")
                                if not self.initialSegmentDone then
                                    if self.initialSegmentCallback ~= nil then
                                        self.initialSegmentCallback()
                                    end
                                    self.initialSegmentDone = true
                                end
                            end
                            self.state = AIFieldCourseState.REGULAR_SEGMENTS
                            self.initialSegment = nil
                        end
                    else
                        self:debugPrint("Failed to generate initial segment")
                        self.state = AIFieldCourseState.FINISHED
                        self.initialSegment = nil
                    end
                    if self.finalizeCallback ~= nil then
                        self.finalizeCallback(self.finalizeCallbackTarget)
                        self.finalizeCallback = nil
                    end
                end, nil)
                self.initialSegment:generate(self.startX, self.startZ, self.startDirX, self.startDirZ)
            end
        end
    elseif self.state == AIFieldCourseState.REGULAR_SEGMENTS or self.state == AIFieldCourseState.NO_MORE_SEGMENTS_FOUND then
        local startTime = 0
        for index, segment in ipairs(self.segmentQueue) do
            if segment:isValid() or not segment:isReady() then
            end
        end
        if startTime > 0 then
            local delta = self.segmentQueue[1]
            if delta ~= nil and delta:isReady() then
                if delta:isValid() then
                    if self.lastSegmentLength ~= delta.length then
                        self.lastSegmentLength = delta.length
                        if self.segmentSwitchedCallback ~= nil then
                            self.segmentSwitchedCallback(delta)
                        end
                    end
                    if forceSegmentSkip then
                        delta:skipCurrentSubSegment(math.huge)
                    end
                else
                    local segmentId = self.segmentQueue[1].segmentId
                    if segmentId ~= nil then
                        self.usedSegments[segmentId] = true
                    end
                    table.remove(self.segmentQueue, 1)
                    table.insert(self.segmentQueue, delta)
                    delta:reset()
                    if not self.initialSegmentDone then
                        if self.initialSegmentCallback ~= nil then
                            self.initialSegmentCallback()
                        end
                        self.initialSegmentDone = true
                    end
                end
            end
        end
        if startTime < AIFieldCourse.QUEUE_MIN_LENGTH then
            if self.state == AIFieldCourseState.NO_MORE_SEGMENTS_FOUND then
                if startTime == 0 then
                    self.state = AIFieldCourseState.FINISHED
                end
            elseif not self.segmentOrderTask:getSegmentSearchPending() then
                self.segmentOrderTask:next(self.onNextSegmentFound, self)
                return
            end
        end
    end
end
function AIFieldCourse:updateSegmentInitialization()
    local segment = self.fieldCourse.segments[self.segmentInitializeIndex]
    local step = self.fieldCourseSettings.segmentSplitDistance
    if segment == nil then
        return false
    end
    local state = nil
    local i = 1
    local removedSegmentId = #segment.positions - 1
    local segmentIdStillValid = 1
    for i = i, removedSegmentId, segmentIdStillValid do
        local p1 = segment.positions[i]
        local p2 = segment.positions[i + 1]
        local dirX = p2[1] - p1[1]
        local dirZ = p2[2] - p1[2]
        local length = MathUtil.vector2Length(dirX, dirZ)
        local dirX = dirX / length
        local dirZ = dirZ / length
        local startPos = 0
        local v9_ = step
        for step = step, length + step - 0.01, step do
            local offsetLeft = startPos / length
            local startPosClamped = math.min(offsetLeft, 1) * length
            local endPosClamped = math.min(step / length, 1) * length
            local offsetLeft, segmentValidityCheckOffset
            if segment.isHeadlandSegment then
                if segment.headlandIndex == 1 then
                    offsetLeft = math.max(self.implementWidth * 0.5 - 0.15 - 0.25, 0.5)
                    segmentValidityCheckOffset = halfWidth
                elseif segment.headlandIndex == self.fieldCourse.numHeadlands then
                    segmentValidityCheckOffset = math.max(halfWidth - 0.5, 0.5)
                    offsetLeft = halfWidth
                else
                    segmentValidityCheckOffset = halfWidth
                    offsetLeft = segmentValidityCheckOffset
                    segmentValidityCheckOffset = offsetLeft
                end
            else
                segmentValidityCheckOffset = halfWidth
                offsetLeft = segmentValidityCheckOffset
                segmentValidityCheckOffset = offsetLeft
            end
            local segmentValidityCheckOffset = self.fieldCourseSettings.segmentValidityCheckOffset
            if segmentValidityCheckOffset ~= 0 then
                offsetLeft = math.max(offsetLeft - segmentValidityCheckOffset, 0.5)
                segmentValidityCheckOffset = math.max(segmentValidityCheckOffset - segmentValidityCheckOffset, 0.5)
            end
            if self:getIsSegmentAreaValid(p1[1] + dirX * startPos - dirZ * segmentValidityCheckOffset, p1[2] + dirZ * startPos + dirX * segmentValidityCheckOffset, p1[1] + dirX * startPos + dirZ * offsetLeft, p1[2] + dirZ * startPos - dirX * offsetLeft, p1[1] + dirX * step - dirZ * segmentValidityCheckOffset, p1[2] + dirZ * step + dirX * segmentValidityCheckOffset) then
                if state == false then
                    segment.positions[i] = { p1[1] + dirX * startPosClamped, p1[2] + dirZ * startPosClamped }
                    local j = i - 1
                    for j = j, 1, -1 do
                        table.remove(segment.positions, j)
                    end
                    FieldCourseUtil.removeShortSegments(segment.positions, 0.01, false)
                    segment.length = FieldCourseUtil.getSegmentLength(segment.positions)
                    if segment.length <= 0 or #segment.positions < 2 then
                        self.usedSegments[segment.segmentId] = true
                        table.remove(self.fieldCourse.segments, self.segmentInitializeIndex)
                    end
                    return true
                end
            elseif state == true then
                local newSegment = {
                    ["positions"] = {}
                }
                local j = 1
                local j = 1
                for j = j, i, j do
                    table.insert(newSegment.positions, segment.positions[j])
                end
                local j = newSegment.positions
                local j = { p1[1] + dirX * startPosClamped, p1[2] + dirZ * startPosClamped }
                table.insert(j, j)
                local j = -1
                for i = i, 1, j do
                    table.remove(segment.positions, i)
                end
                local j = segment.positions
                table.insert(j, 1, { p1[1] + dirX * endPosClamped, p1[2] + dirZ * endPosClamped })
                FieldCourseUtil.removeShortSegments(segment.positions, 0.01, false)
                segment.length = FieldCourseUtil.getSegmentLength(segment.positions)
                if segment.length <= 0 or #segment.positions < 2 then
                    table.remove(self.fieldCourse.segments, self.segmentInitializeIndex)
                end
                FieldCourseUtil.removeShortSegments(newSegment.positions, 0.01, false)
                newSegment.length = FieldCourseUtil.getSegmentLength(newSegment.positions)
                if newSegment.length > 0 and #newSegment.positions >= 2 then
                    newSegment.lineGroupIndex = segment.lineGroupIndex
                    newSegment.isHeadlandSegment = segment.isHeadlandSegment
                    newSegment.isIslandSegment = segment.isIslandSegment
                    newSegment.islandIndex = segment.islandIndex
                    newSegment.headlandIndex = segment.headlandIndex
                    newSegment.segmentId = segment.segmentId
                    newSegment.offsetLineIndex = segment.offsetLineIndex
                    table.insert(self.fieldCourse.segments, self.segmentInitializeIndex, newSegment)
                    self.segmentInitializeIndex = self.segmentInitializeIndex + 1
                end
                return true
            end
            v9_ = step
            startPos = v9_
            v9_ = startPos
            step = v9_
        end
    end
    if state == false then
        table.remove(self.fieldCourse.segments, self.segmentInitializeIndex)
        local segmentIdStillValid = false
        for dirX, dirZ in ipairs(self.fieldCourse.segments) do
            if dirZ.segmentId == segment.segmentId then
                segmentIdStillValid = true
            end
        end
        if not segmentIdStillValid then
            self.usedSegments[segment.segmentId] = true
        end
    else
        self.segmentInitializeIndex = self.segmentInitializeIndex + 1
    end
    return true
end
function AIFieldCourse:updateHeadlandTailAvoidance()
    if self.headlandTailAvoidanceMaxIndex < 0 then
        for _, segment in ipairs(self.fieldCourse.segments) do
            if segment.isHeadlandSegment then
                self.headlandTailAvoidanceMaxIndex = math.max(segment.headlandIndex, self.headlandTailAvoidanceMaxIndex)
            end
        end
    end
    local cutDistance = self.fieldCourseSettings.implementWidth * (self.headlandTailAvoidanceIndex + 0.5)
    local segment = self.fieldCourseSettings.toolBackOffset
    local agentBackOffset = self.fieldCourseSettings.agentBackOffset + math.max(segment, 0)
    for _, segment in ipairs(self.fieldCourse.segments) do
        if segment.isHeadlandSegment and segment.headlandIndex == self.headlandTailAvoidanceIndex then
            local x1, z1 = AIFieldCourseUtil.getSegmentPosition(true, segment, self.fieldCourseSettings.sideOffset == 0 and 1 or -1, 0)
            local x2, z2 = AIFieldCourseUtil.getSegmentPosition(true, segment, headlandDirection, 1)
            local dx, dz = MathUtil.vector2Normalize(x1 - x2, z1 - z2)
            local boundary = self.fieldRootBoundary.boundaryLine
            local i = 1
            for i = i, #boundary - 1 do
                local intersect, ix, iz = MathUtil.getLineSegmentsIntersection(boundary[i][1], boundary[i][2], boundary[i + 1][1], boundary[i + 1][2], x1, z1, x1 + dx * agentBackOffset, z1 + dz * agentBackOffset)
                if intersect then
                    local segmentCutDistance = agentBackOffset - MathUtil.vector2Length(ix - x1, iz - z1)
                    if AIFieldCourseUtil.cutSegmentByDistance(segment, headlandDirection, segmentCutDistance) then
                        segment.cutDistance = segmentCutDistance
                    else
                        segment.isInvalid = true
                    end
                    break
                end
            end
        end
    end
    local segment = #self.fieldCourse.segments
    for segment = segment, 1, -1 do
        if self.fieldCourse.segments[segment].isInvalid then
            self.usedSegments[self.fieldCourse.segments[segment].segmentId] = true
            table.remove(self.fieldCourse.segments, segment)
        end
    end
    for _, segment in ipairs(self.fieldCourse.segments) do
        if segment.isHeadlandSegment and segment.headlandIndex == self.headlandTailAvoidanceIndex then
            local x1, z1 = AIFieldCourseUtil.getSegmentPosition(false, segment, headlandDirection, 0)
            local x2, z2 = AIFieldCourseUtil.getSegmentPosition(false, segment, headlandDirection, 1)
            local dx, dz = MathUtil.vector2Normalize(x1 - x2, z1 - z2)
            local minX = nil
            local minZ = nil
            local i = self.fieldRootBoundary.boundaryLine
            local ex = 1
            for ex = ex, #i - 1 do
                local iz = i[ex + 1][2]
                local distance, segmentCutDistance, iz = MathUtil.getLineSegmentsIntersection(i[ex][1], i[ex][2], i[ex + 1][1], iz, x1, z1, x1 + dx * cutDistance, z1 + dz * cutDistance)
                if distance then
                    if MathUtil.vector2Length(segmentCutDistance - x1, iz - z1) < math.huge then
                        minZ = iz
                        minX = segmentCutDistance
                    end
                    break
                end
            end
            if minX ~= nil then
                if headlandDirection == 1 then
                    segment.positions[#segment.positions] = { minX, minZ }
                else
                    segment.positions[1] = { minX, minZ }
                end
            end
        end
    end
    for _, segment in ipairs(self.fieldCourse.segments) do
        if segment.isHeadlandSegment then
            segment.lockedDirection = headlandDirection
        end
    end
    self.headlandTailAvoidanceIndex = self.headlandTailAvoidanceIndex + 1
    return self.headlandTailAvoidanceIndex <= self.headlandTailAvoidanceMaxIndex
end
function AIFieldCourse:getDriveData(dt, vX, vY, vZ, vSpeed, steeringOffset, toolReverserDirectionNode)
    if self.state == AIFieldCourseState.FINISHED then
        return nil, nil, true, 0, 0
    end
    self.lastVehicleX = vX
    self.lastVehicleZ = vZ
    local segment = self.segmentQueue[1]
    if segment ~= nil and (segment:isReady() and segment:isValid()) then
        local steeringFactor = self.subSegmentLength * 0.5
        local steeringFactorLength = math.min(steeringFactor, 4)
        local steeringFactor
        if self.subSegmentPosition < 0.5 then
            steeringFactor = math.clamp(self.subSegmentPosition * self.subSegmentLength, 0, steeringFactorLength) / steeringFactorLength
        else
            steeringFactor = math.clamp((1 - self.subSegmentPosition) * self.subSegmentLength, 0, steeringFactorLength) / steeringFactorLength
        end
        local tx, tz, direction, segmentPosition, segmentLength, subSegmentPosition, subSegmentLength = segment:getDriveData(dt, vX, vY, vZ, vSpeed, steeringOffset * (0.35 + steeringFactor * 0.65), toolReverserDirectionNode)
        if tx ~= nil and tz ~= nil then
            if segmentPosition ~= nil then
                self.segmentPosition = segmentPosition
                self.segmentLength = segmentLength
                self.subSegmentPosition = subSegmentPosition
                self.subSegmentLength = subSegmentLength
            end
            local maxSpeed = 25
            if segment.isTurn or direction == -1 then
                maxSpeed = self.subSegmentLength < 15 and 10 or 15
            end
            local distanceToEnd = (1 - self.subSegmentPosition) * self.subSegmentLength
            if distanceToEnd < 3 then
                maxSpeed = math.max(maxSpeed * math.min(distanceToEnd / 3, 1), 4)
            end
            return tx, tz, direction == 1, maxSpeed, 10
        end
    end
    return 0, 0, true, 0, 0
end
function AIFieldCourse:clearAlternativeSegments()
    local i = #self.alternativeTurnSegments
    for i = i, 1, -1 do
        self.alternativeTurnSegments[i] = nil
    end
end
function AIFieldCourse:draw()
    if self.fieldRootBoundary ~= nil then
        self.fieldRootBoundary:draw(0, 0, 1, 0.2)
    end
    if self.protectedBoundary ~= nil then
        self.protectedBoundary:draw(1, 0, 0, 0.2)
    end
    for _, island in ipairs(self.islands) do
        island.rootBoundary:draw(1, 0, 1, 0.2)
        if island.protectedBoundary ~= nil then
            island.protectedBoundary:draw(1, 0, 0, 0.15)
        end
    end
    for _, island in pairs(self.fieldCourse.segments) do
        local r = 0.1
        local g = 0.1
        local b = 0.1
        local a = 0.1
        if self.segmentsToSkip[island.segmentId] then
            r = 0.1
            g = 0
            b = 0
            a = 0.1
        elseif island.isHeadlandSegment then
            r = 0
            g = 0
            b = 0.1
            a = 0.1
        elseif island.isIslandSegment then
            r = 0.1
            g = 0
            b = 0.1
            a = 0.1
        end
        local numPositions = #island.positions
        local i = 1
        for i = i, numPositions - 1 do
            local x1 = island.positions[i][1]
            local z1 = island.positions[i][2]
            local x2 = island.positions[i + 1][1]
            local z2 = island.positions[i + 1][2]
            local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1)
            local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2)
            drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, false)
            drawDebugPoint(x1, y1, z1, r, g, b, a, false)
            if i + 1 == numPositions then
                drawDebugPoint(x2, y2, z2, r, g, b, a, false)
            end
        end
    end
    for _, island in ipairs(self.alternativeTurnSegments) do
        island:draw(0.1, 0.1, 0.1)
    end
    for _, island in ipairs(self.segmentQueue) do
        if island:isReady() then
            if _ == 1 then
                island:draw(0, 1, 0)
            else
                island:draw(1, 1, 0)
            end
        end
    end
end
function AIFieldCourse:addDebugTexts(vehicle)
    vehicle:addAIDebugText(string.format(" Segment Queue (%d):", #self.segmentQueue))
    local i = 1
    local segment = math.min(#self.segmentQueue, 10)
    for i = i, segment do
        local segment = self.segmentQueue[i]
        if segment:isValid() and segment:isReady() then
            vehicle:addAIDebugText(string.format("%s%d: (%s) L:%.1fm Side:%.2fm", i == 1 and "   A" or "     ", i, segment.isTurn and "turn" or "straight", segment.length, segment.sideOffset))
        elseif segment:isValid() and not segment:isReady() then
            vehicle:addAIDebugText(string.format("     %d: Getting Ready", i))
        else
            vehicle:addAIDebugText(string.format("     %d: Invalid", i))
        end
    end
end
function AIFieldCourse.debugPrint(_, text, ...)
    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
        print("AIFieldCourse: " .. string.format(text, ...))
    end
end