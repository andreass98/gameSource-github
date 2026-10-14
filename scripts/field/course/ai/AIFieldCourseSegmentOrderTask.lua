AIFieldCourseSegmentOrderTask = {}
local AIFieldCourseSegmentOrderTask_mt = Class(AIFieldCourseSegmentOrderTask)
function AIFieldCourseSegmentOrderTask.new(aiFieldCourse)
    -- upvalues: (copy) AIFieldCourseSegmentOrderTask_mt
    local self = setmetatable({}, AIFieldCourseSegmentOrderTask_mt)
    self.aiFieldCourse = aiFieldCourse
    self.fieldCourse = aiFieldCourse.fieldCourse
    self.segments = aiFieldCourse.fieldCourse.segments
    self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
    self.turnGenerator = AIFieldCourseTurnGenerator.new(aiFieldCourse)
    self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
    self.cornerCutOut = AIFieldCourseCornerCutOut.new(aiFieldCourse)
    self.cornerCutOut:setCallback(self.onCutOutSegmentFound, self)
    self.firstSegmentDetection = AIFieldCourseFirstSegmentDetection.new(aiFieldCourse, self)
    self.firstSegmentDetection:setCallback(self.onFoundFirstSegment, self)
    self.segmentCollisionCheck = AIFieldCourseSegmentCollisionCheck.new(self.fieldCourseSettings, self.aiFieldCourse.fieldRootBoundary.boundaryLine)
    self.extendedHeadlandSegments = {}
    self.alternativeTurnSegments = {}
    self.startX = nil
    self.startZ = nil
    self.startDirX = nil
    self.startDirZ = nil
    self.orderedSegments = {}
    self.usedSegments = {}
    self.adjustedSegments = {}
    self.segmentExcludeListPositive = {}
    self.segmentExcludeListNegative = {}
    self.unreachableSegments = {}
    self.excludedSegments = {}
    self.segmentsToSkip = {}
    self.allowedProtectedBoundaryCrossings = {}
    self.segmentBuffer = {}
    self.turnSegmentBuffer = {}
    self.curSegmentIndex = 1
    self.firstRun = true
    self.segment = nil
    self.direction = nil
    return self
end
function AIFieldCourseSegmentOrderTask:setStartPosition(startX, startZ, dirX, dirZ)
    self.startX = startX
    self.startZ = startZ
    self.startDirX = dirX
    self.startDirZ = dirZ
    self.firstSegmentDetection:setStartPosition(startX, startZ, dirX, dirZ)
end
function AIFieldCourseSegmentOrderTask:setAlternativeTurnSegmentData(alternativeTurnSegments)
    self.alternativeTurnSegments = alternativeTurnSegments
end
function AIFieldCourseSegmentOrderTask:setOverwrittenSegments(overwrittenSegments)
    self.overwrittenSegments = overwrittenSegments
    self.segmentBuffer = {}
    for i, loadedSegmentData in ipairs(overwrittenSegments) do
        local segment = AIFieldCourseSegment.new()
        segment:setPositions(loadedSegmentData.positions)
        segment.index = i
        segment.isTurn = loadedSegmentData.isTurn
        segment.isHeadlandSegment = loadedSegmentData.isHeadlandSegment
        segment.isIslandSegment = loadedSegmentData.isIslandSegment
        if segment:isValid() then
            if i == 1 then
                self.usedSegments[({
                    ["segment"] = segment,
                    ["adjustedSegment"] = segment,
                    ["direction"] = 1
                }).segment] = true
                table.insert(self.orderedSegments, data)
                self.segment = data.segment
                self.direction = data.direction
            else
                table.insert(self.segmentBuffer, data)
            end
        end
    end
    self.segments = overwrittenSegments
    self.firstRun = false
end
function AIFieldCourseSegmentOrderTask:setSegmentsToSkip(segmentsToSkip)
    if segmentsToSkip ~= nil then
        self.segmentsToSkip = segmentsToSkip
        self.firstSegmentDetection:setSegmentsToSkip(segmentsToSkip)
    end
end
function AIFieldCourseSegmentOrderTask:setLastActiveSegmentId(lastActiveSegmentId)
    if lastActiveSegmentId ~= nil then
        self.firstSegmentDetection:setLastActiveSegmentId(lastActiveSegmentId)
    end
end
function AIFieldCourseSegmentOrderTask:getSegmentSearchPending()
    return self.pendingSegmentSearch
end
function AIFieldCourseSegmentOrderTask:onFoundSegment(segment, direction, isTurn, addStraighting, nextTurn, isLast)
    if self.callback ~= nil then
        if self.callbackTarget ~= nil then
            self.callback(self.callbackTarget, segment, direction, isTurn, addStraighting, nextTurn, isLast)
            return
        end
        self.callback(segment, direction, isTurn, addStraighting, nextTurn, isLast)
    end
end
function AIFieldCourseSegmentOrderTask:next(callback, callbackTarget, bufferMinSize)
    if self.pendingSegmentSearch then
        Logging.error("AIFieldCourseSegmentOrderTask:next() called while a segment search is still pending")
        printCallstack()
    end
    self.callback = callback
    self.callbackTarget = callbackTarget
    self.pendingSegmentSearch = true
    self.numBufferFillIterations = (bufferMinSize or 5) - #self.segmentBuffer
    self:fillBuffer()
end
function AIFieldCourseSegmentOrderTask:onBufferFillFinished()
    if self.cornerCutOutInProgress then
        return
    end
    if #self.segmentBuffer <= 0 then
        self:onFoundSegment(nil, 1, false, true, nil, true)
        for _, segment in pairs(self.segments) do
            if self.usedSegments[segment] == nil then
                Logging.devInfo("AIFieldCourseSegmentOrderTask: Segment %d could not be reached. (%dm, x %.2f, z %.2f)", segment.index, segment.length, segment.positions[1][1], segment.positions[1][2])
            end
        end
        return
    end
    local segmentData = self.segmentBuffer[1]
    local nextSegmentData = self.segmentBuffer[2]
    self.usedSegments[segmentData.segment] = true
    table.insert(self.orderedSegments, segmentData)
    local nextTurn = nil
    if nextSegmentData ~= nil then
        for _, turnSegmentData in ipairs(self.turnSegmentBuffer) do
            if turnSegmentData.from == segmentData.segment and turnSegmentData.to == nextSegmentData.segment then
                nextTurn = turnSegmentData.turn
                break
            end
        end
    end
    if self.fieldCourseSettings.cornerCutOutSupported and (self.fieldCourseSettings.canTurnBackward and (nextSegmentData ~= nil and self.cornerCutOut:validateSegments(segmentData.adjustedSegment, segmentData.direction, nextSegmentData.adjustedSegment, nextSegmentData.direction))) then
        self.aiFieldCourse:debugPrint("Corner cut out calculations started from segment %d to %d", segmentData.adjustedSegment.index, nextSegmentData.adjustedSegment.index)
        self.cornerCutOutInProgress = true
        self.cornerCutOutAlternativeTurn = nextTurn
        self.cornerCutOutAlternativeTurnDirection = segmentData.direction
        self:onFoundSegment(segmentData.adjustedSegment, segmentData.direction, false, true, nil, false)
        table.remove(self.segmentBuffer, 1)
    else
        self:onFoundSegment(segmentData.adjustedSegment, segmentData.direction, false, true, nextTurn, false)
        if nextTurn ~= nil then
            self:onFoundSegment(nextTurn, segmentData.direction, true, true, nil, true)
        end
        table.remove(self.segmentBuffer, 1)
        self.pendingSegmentSearch = false
    end
end
function AIFieldCourseSegmentOrderTask:fillBuffer()
    local lastSegment = nil
    local lastBufferElement = self.segmentBuffer[#self.segmentBuffer]
    if lastBufferElement ~= nil then
        lastSegment = lastBufferElement.segment
    end
    if lastSegment == nil and self.firstSegmentDetection ~= nil then
        self.firstSegmentDetection:detect()
        return false
    end
    for segment, _ in pairs(self.segmentExcludeListPositive) do
        self.segmentExcludeListPositive[segment] = nil
    end
    for segment, _ in pairs(self.segmentExcludeListNegative) do
        self.segmentExcludeListNegative[segment] = nil
    end
    for segment, _ in pairs(self.excludedSegments) do
        self.segmentExcludeListPositive[segment] = true
        self.segmentExcludeListNegative[segment] = true
    end
    for segment, _ in ipairs(self.segments) do
        if self.segmentsToSkip[_.segmentId] then
            self.segmentExcludeListPositive[_] = true
            self.segmentExcludeListNegative[_] = true
        end
    end
    for segment, _ in pairs(self.unreachableSegments) do
        self.segmentExcludeListPositive[segment] = true
        self.segmentExcludeListNegative[segment] = true
    end
    for segment, _ in ipairs(self.segmentBuffer) do
        self.segmentExcludeListPositive[_.segment] = true
        self.segmentExcludeListNegative[_.segment] = true
    end
    if self:fillNextBufferSlot() then
        return true
    end
    self:onBufferSlotFilled()
    return false
end
function AIFieldCourseSegmentOrderTask:onBufferSlotFilled()
    if self.numBufferFillIterations > 0 then
        self.numBufferFillIterations = self.numBufferFillIterations - 1
        if self.numBufferFillIterations > 0 and not self:fillBuffer() then
            self.numBufferFillIterations = 0
            return
        end
    end
    if self.numBufferFillIterations == 0 then
        self:onBufferFillFinished()
    end
end
function AIFieldCourseSegmentOrderTask:fillNextBufferSlot()
    local lastSegment = nil
    local lastDirection = nil
    local lastBufferElement = self.segmentBuffer[#self.segmentBuffer]
    if lastBufferElement ~= nil then
        lastSegment = lastBufferElement.segment
        lastDirection = lastBufferElement.direction
    end
    local segment, direction = self:findNextValidSegment(lastSegment, lastDirection)
    if segment == nil then
        return false
    end
    self:adjustSegmentLength(segment, direction, function(adjustedSegment)
        -- upvalues: (copy) self, (copy) segment, (ref) lastSegment, (ref) lastDirection, (copy) direction
        self.adjustedSegments[segment] = adjustedSegment
        self.curTurnSegment1 = lastSegment
        self.curTurnSegmentDirection1 = lastDirection
        self.curTurnSegment2 = segment
        self.curTurnSegmentDirection2 = direction
        self.turnGenerator:setAllowProtectedBoundary(false)
        if lastDirection == direction and self.allowedProtectedBoundaryCrossings[self.curTurnSegment1] == self.curTurnSegment2 then
            self.turnGenerator:setAllowProtectedBoundary(true)
        end
        self.turnGenerator:generateSegmentToSegment(self.adjustedSegments[lastSegment], lastDirection, adjustedSegment, direction)
    end)
    return true
end
function AIFieldCourseSegmentOrderTask:onSegmentTurnDataFound(turn)
    if turn == nil then
        local excludeCombination = true
        if self.curTurnSegment1.isHeadlandSegment and (self.curTurnSegment2.isHeadlandSegment and self.curTurnSegmentDirection1 == self.curTurnSegmentDirection2) then
            self.allowedProtectedBoundaryCrossings[self.curTurnSegment1] = self.curTurnSegment2
            excludeCombination = false
        end
        if excludeCombination then
            if self.curTurnSegmentDirection2 > 0 then
                self.segmentExcludeListPositive[self.curTurnSegment2] = true
            else
                self.segmentExcludeListNegative[self.curTurnSegment2] = true
            end
        end
        if not self:fillNextBufferSlot() then
            self:onBufferSlotFilled()
        end
    else
        self.adjustedSegments[self.curTurnSegment1].lastEndOffset = turn.turnData.endOffset
        self.adjustedSegments[self.curTurnSegment2].lastStartOffset = turn.turnData.startOffset
        table.insert(self.segmentBuffer, {
            ["segment"] = self.curTurnSegment2,
            ["adjustedSegment"] = self.adjustedSegments[self.curTurnSegment2],
            ["direction"] = self.curTurnSegmentDirection2
        })
        table.insert(self.turnSegmentBuffer, {
            ["from"] = self.curTurnSegment1,
            ["to"] = self.curTurnSegment2,
            ["turn"] = turn
        })
        self:onBufferSlotFilled()
    end
end
function AIFieldCourseSegmentOrderTask:onCutOutSegmentFound(segment, direction, isTurn, nextTurn, isLast)
    if segment == nil then
        self.aiFieldCourse:debugPrint("Corner cut out failed, use previously calculated segment")
        self.cornerCutOutInProgress = false
        self.pendingSegmentSearch = false
        if self.cornerCutOutAlternativeTurn ~= nil then
            self:onFoundSegment(self.cornerCutOutAlternativeTurn, self.cornerCutOutAlternativeTurnDirection, true, true, nil, true)
            self.cornerCutOutAlternativeTurn = nil
            self.cornerCutOutAlternativeTurnDirection = nil
        end
    else
        segment.isCornerCutOut = true
        self:onFoundSegment(segment, direction, isTurn, not isTurn, nextTurn, isLast)
        if isLast then
            self.cornerCutOutInProgress = false
            self.pendingSegmentSearch = false
        end
    end
end
function AIFieldCourseSegmentOrderTask:onFoundFirstSegment(success, segment, direction)
    if success then
        if segment ~= nil and segment.isHeadlandSegment then
            local headlandForcedDirection = -math.sign(self.fieldCourseSettings.headlandForcedDirection)
            if headlandForcedDirection ~= 0 then
                for _, otherSegment in ipairs(self.segments) do
                    if otherSegment.lockedDirection == nil then
                        if otherSegment.isHeadlandSegment and otherSegment.headlandIndex ~= segment.headlandIndex then
                            if segment.isHeadlandSegment or segment.isIslandSegment then
                                otherSegment.lockedDirection = -headlandForcedDirection
                            end
                        elseif otherSegment.isHeadlandSegment and otherSegment.headlandIndex == segment.headlandIndex then
                            otherSegment.lockedDirection = direction
                        end
                        if otherSegment.isIslandSegment then
                            otherSegment.lockedDirection = headlandForcedDirection
                        end
                    end
                end
            end
        end
        self:adjustSegmentLength(segment, direction, function(adjustedSegment)
            -- upvalues: (copy) self, (copy) segment, (copy) direction
            self.adjustedSegments[segment] = adjustedSegment
            table.insert(self.segmentBuffer, {
                ["segment"] = segment,
                ["adjustedSegment"] = adjustedSegment,
                ["direction"] = direction
            })
            self.firstSegmentDetection = nil
            self:fillBuffer()
        end)
    else
        self.firstSegmentDetection = nil
        self:fillBuffer()
    end
end
function AIFieldCourseSegmentOrderTask:hasFinished()
    return not self.firstRun and self.segment == nil and true or false
end
function AIFieldCourseSegmentOrderTask:findNextValidSegment(lastSegment, lastDirection)
    local segment = nil
    local direction = nil
    while segment == nil do
        segment, direction = self:findNextSegment(lastSegment, lastDirection)
        if segment == nil then
            return segment, direction
        end
        if not self:getIsSegmentValid(segment) then
            self.excludedSegments[segment] = true
            self.segmentExcludeListPositive[segment] = true
            self.segmentExcludeListNegative[segment] = true
            segment = nil
        end
    end
    return segment, direction
end
function AIFieldCourseSegmentOrderTask:getIsSegmentValid(segment)
    local i = 1
    for i = i, #segment.positions - 1 do
        local p1 = segment.positions[i]
        local p2 = segment.positions[i + 1]
        local dirX, dirZ = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
        if self.aiFieldCourse:getIsSegmentAreaValid(p1[1] - dirZ * (self.fieldCourseSettings.implementWidth * 0.5), p1[2] + dirX * halfWidth, p1[1] + dirZ * halfWidth, p1[2] - dirX * halfWidth, p2[1] - dirZ * halfWidth, p2[2] + dirX * halfWidth) then
            return true
        end
    end
    return false
end
function AIFieldCourseSegmentOrderTask:findNextSegment(lastSegment, lastDirection)
    if lastSegment == nil then
        return nil
    end
    if self.fieldCourseSettings.headlandsFirst then
        if lastSegment.isIslandSegment then
            local islandsSegment, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex, lastSegment.islandIndex)
            if islandsSegment ~= nil then
                return islandsSegment, islandSegmentDirection
            end
            local islandSegmentDirection, x = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex + (self.fieldCourseSettings.headlandsFirst and -1 or 1), lastSegment.islandIndex)
            if islandSegmentDirection ~= nil then
                return islandSegmentDirection, x
            end
        end
        local islandsSegment, islandSegmentDirection = self:findNextHeadlandSegment(lastSegment, lastDirection, false)
        if islandsSegment ~= nil then
            local nextHeadlandDirection, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, -1)
            if nextHeadlandDirection ~= nil then
                local x, z = AIFieldCourseUtil.getSegmentPosition(true, nextHeadlandDirection, islandSegmentDirection)
                if AIFieldCourseUtil.getSegmentSideOffset(lastSegment, x, z) > self.fieldCourseSettings.implementWidth * 2.01 then
                    nextHeadlandDirection = nil
                end
            end
            local x, z = self:getCloserSegment(lastSegment, lastDirection, islandsSegment, islandSegmentDirection, nextHeadlandDirection, islandSegmentDirection)
            if x ~= nil then
                return x, z
            end
        end
        local nextHeadlandDirection, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, -1)
        if nextHeadlandDirection ~= nil then
            local x, z = AIFieldCourseUtil.getSegmentPosition(true, nextHeadlandDirection, islandSegmentDirection)
            if AIFieldCourseUtil.getSegmentSideOffset(lastSegment, x, z) > self.fieldCourseSettings.implementWidth * 2.01 then
                nextHeadlandDirection = nil
            end
        end
        local x, z = self:findClosestStraightSegment(lastSegment, lastDirection, lastSegment.lineGroupIndex, false)
        local sideOffset, straightSegmentDirection = self:getCloserSegment(lastSegment, lastDirection, nextHeadlandDirection, islandSegmentDirection, x, z)
        if sideOffset ~= nil and sideOffset == nextHeadlandDirection then
            return sideOffset, straightSegmentDirection
        end
        local sideOffset, straightSegmentDirection = self:findClosestStraightSegment(lastSegment, lastDirection, lastSegment.lineGroupIndex, true)
        if sideOffset ~= nil then
            return sideOffset, straightSegmentDirection
        end
    else
        if lastSegment.isIslandSegment then
            local islandsSegment, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex, lastSegment.islandIndex)
            if islandsSegment ~= nil then
                return islandsSegment, islandSegmentDirection
            end
            local islandSegmentDirection, x = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex + (self.fieldCourseSettings.headlandsFirst and -1 or 1), lastSegment.islandIndex)
            if islandSegmentDirection ~= nil then
                return islandSegmentDirection, x
            end
        end
        local islandsSegment, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, -1)
        if islandsSegment ~= nil then
            local nextHeadlandDirection, islandSegmentDirection = AIFieldCourseUtil.getSegmentPosition(true, islandsSegment, islandSegmentDirection)
            if AIFieldCourseUtil.getSegmentSideOffset(lastSegment, nextHeadlandDirection, islandSegmentDirection) > self.fieldCourseSettings.implementWidth * 2.01 then
                islandsSegment = nil
            end
        end
        local nextHeadlandDirection, islandSegmentDirection = self:findClosestStraightSegment(lastSegment, lastDirection, lastSegment.lineGroupIndex, true)
        local x, z = self:getCloserSegment(lastSegment, lastDirection, islandsSegment, islandSegmentDirection, nextHeadlandDirection, islandSegmentDirection)
        if x ~= nil then
            return x, z
        end
    end
    if lastSegment.lineGroupIndex ~= nil then
        for islandSegmentDirection, x in ipairs(self.segments) do
            if self.usedSegments[x] == nil and (self.segmentExcludeListPositive[x] == nil and self.segmentExcludeListNegative[x] == nil) then
                if lastSegment.lineGroupIndex == x.lineGroupIndex then
                    return x, -lastDirection
                end
                local z, sideOffset = self:findClosestSegment(lastSegment, lastDirection, false, false)
                if z ~= nil then
                    return z, sideOffset
                end
            end
        end
    end
    if not self.fieldCourseSettings.headlandsFirst then
        local islandsSegment, islandSegmentDirection = self:findNextHeadlandSegment(lastSegment, lastDirection, true)
        if islandsSegment ~= nil then
            return islandsSegment, islandSegmentDirection
        end
        local nextHeadlandDirection, islandSegmentDirection = self:findNextHeadlandSegment(lastSegment, lastDirection, false)
        if nextHeadlandDirection ~= nil then
            return nextHeadlandDirection, islandSegmentDirection
        end
    end
    return nil
end
function AIFieldCourseSegmentOrderTask:findNextHeadlandSegment(lastSegment, lastDirection, useIslands)
    if lastSegment.headlandIndex == nil then
        local lastIndex, minSegment = self:findClosestSegment(lastSegment, lastDirection, not useIslands, useIslands)
        if lastIndex ~= nil then
            return lastIndex, minSegment
        end
    else
        local lastIndex = nil
        local minSegment = #self.segments
        local maxSegment = 1
        for i, segment in ipairs(self.segments) do
            if segment == lastSegment then
                lastIndex = i
            end
            if self.usedSegments[segment] == nil and (self.segmentExcludeListPositive[segment] == nil and (self.segmentExcludeListNegative[segment] == nil and (lastSegment.headlandIndex == segment.headlandIndex and lastSegment.islandIndex == segment.islandIndex))) then
                minSegment = math.min(minSegment, i)
                maxSegment = math.max(maxSegment, i)
            end
        end
        if lastIndex ~= nil then
            local nextIndex = lastIndex + lastDirection
            local numNextHeadland = maxSegment - minSegment
            for i = 1, numNextHeadland do
                local segment = self.segments[nextIndex]
                if segment == nil or (lastSegment.headlandIndex ~= segment.headlandIndex or lastSegment.islandIndex ~= segment.islandIndex) then
                    if lastDirection > 0 then
                        nextIndex = minSegment
                    else
                        nextIndex = maxSegment
                    end
                elseif self.usedSegments[segment] == nil and ((lastDirection > 0 and self.segmentExcludeListPositive or self.segmentExcludeListNegative)[segment] == nil and segment.lockedDirection ~= -lastDirection) then
                    return segment, lastDirection
                end
            end
            local numNextHeadland = 0
            for excludeList, segment in ipairs(self.segments) do
                local _ = segment == lastSegment
                if self.usedSegments[segment] == nil and (self.segmentExcludeListPositive[segment] == nil and (self.segmentExcludeListNegative[segment] == nil and (lastSegment.headlandIndex + 1 == segment.headlandIndex and lastSegment.islandIndex == segment.islandIndex))) then
                end
            end
        end
        local nextIndex, numNextHeadland = self:findClosestSegment(lastSegment, lastDirection, not useIslands, useIslands)
        if nextIndex ~= nil then
            return nextIndex, numNextHeadland
        end
    end
    return nil
end
function AIFieldCourseSegmentOrderTask:findClosestStraightSegment(lastSegment, direction, groupIndex, workLessSegmentSideFirst)
    local searchDirection = 0
    if workLessSegmentSideFirst and groupIndex ~= nil then
        local negSegments = 0
        local posSegments = 0
        local foundSegment = false
        for _, segment in pairs(self.segments) do
            if segment == lastSegment then
                foundSegment = true
            elseif self.usedSegments[segment] == nil and (self.segmentExcludeListPositive[segment] == nil and (self.segmentExcludeListNegative[segment] == nil and segment.lineGroupIndex == lastSegment.lineGroupIndex)) then
                if FieldCourseUtil.getAreParallelSegmentsNextToEachOther(lastSegment.positions[1][1], lastSegment.positions[1][2], lastSegment.positions[2][1], lastSegment.positions[2][2], segment.positions[1][1], segment.positions[1][2], segment.positions[2][1], segment.positions[2][2]) then
                    if foundSegment then
                    end
                end
            end
        end
        if negSegments > 0 and negSegments < posSegments then
            searchDirection = -1
        elseif posSegments > 0 and posSegments < negSegments then
            searchDirection = 1
        end
    end
    local negSegments, posSegments = AIFieldCourseUtil.getSegmentPosition(false, lastSegment, direction)
    local foundSegment = math.huge
    local minDistanceSegment = nil
    local minDistanceSegmentDirection = 1
    local allowed = searchDirection <= 0
    for sz1, ex1 in ipairs(self.segments) do
        allowed = searchDirection == 0 or lastSegment ~= ex1 or not allowed
        if not allowed then
            break
        end
        if allowed and self.usedSegments[ex1] == nil and (groupIndex == nil and ex1.lineGroupIndex ~= nil or groupIndex ~= nil and ex1.lineGroupIndex == groupIndex) then
            local ez1
            if self.segmentExcludeListPositive[ex1] == nil and ex1.lockedDirection ~= -1 then
                ez1 = self:getCostDistanceToSegment(ex1, true, negSegments, posSegments)
                if ez1 < foundSegment and ez1 > 0 then
                    minDistanceSegmentDirection = 1
                    minDistanceSegment = ex1
                else
                    ez1 = foundSegment
                end
            else
                ez1 = foundSegment
            end
            if self.segmentExcludeListNegative[ex1] == nil and ex1.lockedDirection ~= 1 then
                foundSegment = self:getCostDistanceToSegment(ex1, false, negSegments, posSegments)
                if foundSegment < ez1 and foundSegment > 0 then
                    minDistanceSegmentDirection = -1
                    minDistanceSegment = ex1
                else
                    foundSegment = ez1
                end
            else
                foundSegment = ez1
            end
        end
    end
    return minDistanceSegment, minDistanceSegmentDirection
end
function AIFieldCourseSegmentOrderTask:getCostDistanceToSegment(targetSegment, startPosition, x, z)
    local x2, z2 = AIFieldCourseUtil.getSegmentPosition(startPosition, targetSegment, 1)
    local distance = MathUtil.vector2Length(x2 - x, z2 - z)
    for _, segment in ipairs(self.segments) do
        if not segment.isHeadlandSegment and (not segment.isIslandSegment and (self.usedSegments[segment] == nil and (self.segmentExcludeListPositive[segment] == nil and (self.segmentExcludeListNegative[segment] == nil and FieldCourseUtil.getSegmentBoundaryIntersection(x, z, x2, z2, segment.positions))))) then
        end
    end
    return distance
end
function AIFieldCourseSegmentOrderTask:findClosestSegment(lastSegment, direction, headlands, islands, groupIndex, maxSideOffset, headlandIndex, islandIndex, excludeBoundaryChecks)
    local x1, z1 = AIFieldCourseUtil.getSegmentPosition(false, lastSegment, direction)
    return self:getClosestSegmentToPosition(x1, z1, headlands, islands, groupIndex, maxSideOffset, headlandIndex, islandIndex, lastSegment, excludeBoundaryChecks, nil, nil)
end
function AIFieldCourseSegmentOrderTask:getClosestSegmentToPosition(x, z, headlands, islands, groupIndex, maxSideOffset, headlandIndex, islandIndex, excludeSegment, excludeBoundaryChecks, prevDirX, prevDirZ)
    local minDistance = math.huge
    local minDistanceSegment = nil
    local minDistanceSegmentDirection = 1
    for _, segment in ipairs(self.segments) do
        if self.usedSegments[segment] == nil and segment ~= excludeSegment then
            if headlands ~= nil then
                segmentIsAllowed = false
                if headlands ~= segment.isHeadlandSegment then
                    goto l7
                end
            end
            local segmentIsAllowed = true
            if islands ~= nil then
                segmentIsAllowed = islands == segment.isIslandSegment
            end
            ::l7::
            if headlandIndex == -1 then
                if segment.islandIndex ~= nil then
                    local island = self.aiFieldCourse.islands[segment.islandIndex]
                    if island ~= nil and island.hasCutSegments then
                        headlandIndex = nil
                    end
                end
                if headlandIndex ~= nil then
                    if segment.headlandIndex == nil then
                        segmentIsAllowed = false
                    else
                        local island = 1
                        if self.fieldCourseSettings.headlandsFirst and segment.islandIndex ~= nil then
                            for _, otherSegment in ipairs(self.segments) do
                                if otherSegment.islandIndex == segment.islandIndex then
                                    island = math.max(island, otherSegment.headlandIndex)
                                end
                            end
                        end
                        while true do
                            local validSegmentsLeft = false
                            local foundSegments = 0
                            for _, otherSegment in ipairs(self.segments) do
                                if otherSegment.islandIndex == segment.islandIndex and otherSegment.headlandIndex == island then
                                    if self.usedSegments[otherSegment] == nil then
                                        validSegmentsLeft = true
                                        break
                                    end
                                end
                            end
                            if validSegmentsLeft then
                                break
                            end
                            if self.fieldCourseSettings.headlandsFirst and segment.islandIndex ~= nil then
                            end
                            if foundSegments == 0 then
                                break
                            end
                        end
                        if segmentIsAllowed then
                            segmentIsAllowed = segment.headlandIndex == island
                        end
                    end
                end
            elseif segmentIsAllowed then
                segmentIsAllowed = true
                if headlandIndex ~= nil then
                    segmentIsAllowed = segment.headlandIndex == headlandIndex
                end
            end
            if segmentIsAllowed then
                segmentIsAllowed = true
                if islandIndex ~= nil then
                    segmentIsAllowed = segment.islandIndex == islandIndex
                end
            end
            if groupIndex ~= nil then
                if segmentIsAllowed then
                    segmentIsAllowed = segment.lineGroupIndex == groupIndex
                end
                if maxSideOffset ~= nil then
                    local island, validSegmentsLeft = AIFieldCourseUtil.getSegmentPosition(true, segment, 1)
                    local foundSegments, z3 = AIFieldCourseUtil.getSegmentPosition(false, segment, 1)
                    local _, otherSegment = MathUtil.vector2Normalize(foundSegments - island, z3 - validSegmentsLeft)
                    local _, otherSegment = MathUtil.projectOnLine(x, z, island, validSegmentsLeft, _, otherSegment)
                    local distance = MathUtil.vector2Length(_ - x, otherSegment - z)
                    if segmentIsAllowed then
                        segmentIsAllowed = distance < maxSideOffset
                    end
                end
            end
            if segmentIsAllowed then
                local _
                if self.segmentExcludeListPositive[segment] == nil and segment.lockedDirection ~= -1 then
                    local island, validSegmentsLeft = AIFieldCourseUtil.getSegmentPosition(true, segment, 1)
                    local foundSegments = MathUtil.vector2Length(island - x, validSegmentsLeft - z)
                    if foundSegments <= minDistance + 0.1 then
                        local _
                        if excludeBoundaryChecks == true then
                            _ = foundSegments
                        else
                            _ = self:getBoundaryCorrectedDistance(x, z, island, validSegmentsLeft)
                        end
                        if maxSideOffset == nil or (_ == nil or _ == nil) then
                            _ = (_ or foundSegments) * self:getSegmentToSegmentFactor(x, z, segment)
                            if prevDirX ~= nil and prevDirZ ~= nil then
                                local otherSegment, _ = AIFieldCourseUtil.getSegmentPosition(true, segment, 1, 1)
                                _ = _ * self:getSegmentDirectionFactor(island, validSegmentsLeft, otherSegment, _, prevDirX, prevDirZ)
                            end
                            if _ < minDistance then
                                minDistanceSegmentDirection = 1
                                minDistanceSegment = segment
                            else
                                _ = minDistance
                            end
                        else
                            _ = minDistance
                        end
                    else
                        _ = minDistance
                    end
                else
                    _ = minDistance
                end
                if self.segmentExcludeListNegative[segment] == nil and segment.lockedDirection ~= 1 then
                    local island, validSegmentsLeft = AIFieldCourseUtil.getSegmentPosition(false, segment, 1)
                    local foundSegments = MathUtil.vector2Length(island - x, validSegmentsLeft - z)
                    if foundSegments <= _ + 0.1 then
                        local z3 = nil
                        if excludeBoundaryChecks ~= true then
                            z3 = self:getBoundaryCorrectedDistance(x, z, island, validSegmentsLeft)
                        end
                        if maxSideOffset == nil or (z3 == nil or z3 == nil) then
                            minDistance = (z3 or foundSegments) * self:getSegmentToSegmentFactor(x, z, segment)
                            if prevDirX ~= nil and prevDirZ ~= nil then
                                local otherSegment, _ = AIFieldCourseUtil.getSegmentPosition(false, segment, 1, 1)
                                minDistance = minDistance * self:getSegmentDirectionFactor(island, validSegmentsLeft, otherSegment, _, prevDirX, prevDirZ)
                            end
                            if minDistance < _ then
                                minDistanceSegmentDirection = -1
                                minDistanceSegment = segment
                            else
                                minDistance = _
                            end
                        else
                            minDistance = _
                        end
                    else
                        minDistance = _
                    end
                else
                    minDistance = _
                end
            end
        end
    end
    return minDistanceSegment, minDistanceSegmentDirection
end
function AIFieldCourseSegmentOrderTask:getSegmentToSegmentFactor(x, z, segment)
    local x2, z2 = AIFieldCourseUtil.getSegmentPosition(true, segment, 1)
    local x3, z3 = AIFieldCourseUtil.getSegmentPosition(false, segment, 1)
    local length = MathUtil.vector2Length(x3 - x2, z3 - z2)
    if length <= 0 then
        return 1
    end
    local x4, z4 = MathUtil.projectOnLine(x, z, x2, z2, dirX / length, dirZ / length)
    return (MathUtil.vector2Length(x4 - x, z4 - z) / self.fieldCourseSettings.implementWidth - 1) * 0.25 + 1
end
function AIFieldCourseSegmentOrderTask.getSegmentDirectionFactor(_, x1, z1, x2, z2, prevDirX, prevDirZ)
    local dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
    local yRot1 = MathUtil.getYRotationFromDirection(dirX, dirZ)
    local rotOffset = MathUtil.getYRotationFromDirection(prevDirX, prevDirZ) - yRot1
    if rotOffset > 3.141592653589793 then
    end
    if rotOffset < -3.141592653589793 then
    end
    return 1 + math.abs(rotOffset) * 0.5
end
function AIFieldCourseSegmentOrderTask:getCloserSegment(lastSegment, lastDirection, segment1, direction1, segment2, direction2)
    if segment1 == nil or segment2 == nil then
        if segment1 == nil then
            if segment2 == nil then
                return nil, nil
            else
                return segment2, direction2
            end
        else
            return segment1, direction1
        end
    else
        local x1, z1 = AIFieldCourseUtil.getSegmentPosition(false, lastSegment, lastDirection)
        local x2, z2 = AIFieldCourseUtil.getSegmentPosition(true, segment1, direction1)
        local x3, z3 = AIFieldCourseUtil.getSegmentPosition(true, segment2, direction2)
        local distance1 = MathUtil.vector2Length(x2 - x1, z2 - z1)
        local distance2 = MathUtil.vector2Length(x3 - x1, z3 - z1)
        for _, segment in ipairs(self.segments) do
            local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, segment.positions)
            if intersect then
            end
            local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x3, z3, segment.positions)
            if intersect then
            end
        end
        if distance1 < distance2 then
            return segment1, direction1
        else
            return segment2, direction2
        end
    end
end
function AIFieldCourseSegmentOrderTask:getBoundaryCorrectedDistance(x1, z1, x2, z2)
    local boundaryLine = self.aiFieldCourse.fieldRootBoundary.boundaryLine
    if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(x2, z2, boundaryLine) then
        local distance = self:getBoundaryCorrectedDistanceByBoundary(boundaryLine, x1, z1, x2, z2)
        if distance ~= nil then
            return distance
        end
    end
    for _, island in ipairs(self.aiFieldCourse.islands) do
        if not (FieldCourseUtil.getIsPointInsideBoundary(x1, z1, island.protectedBoundary.boundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(x2, z2, island.protectedBoundary.boundaryLine)) then
            local distance = self:getBoundaryCorrectedDistanceByBoundary(island.protectedBoundary.boundaryLine, x1, z1, x2, z2)
            if distance ~= nil then
                return distance
            end
        end
    end
    return nil
end
function AIFieldCourseSegmentOrderTask:getBoundaryCorrectedDistanceByBoundary(boundaryLine, x1, z1, x2, z2)
    local i = 1
    for i = i, #boundaryLine - 1 do
        local x3 = boundaryLine[i][1]
        local z3 = boundaryLine[i][2]
        local intersect, _, _ = MathUtil.getLineSegmentsIntersection(x1, z1, x2, z2, x3, z3, boundaryLine[i + 1][1], boundaryLine[i + 1][2])
        if intersect then
            local _, distance = self:getNextDirectConnectBoundaryPosition(boundaryLine, i, x2, z2)
            if distance ~= nil and distance > 0 then
                return distance + MathUtil.vector2Length(x3 - z1, z3 - z1)
            end
        end
    end
    return nil
end
function AIFieldCourseSegmentOrderTask.getNextDirectConnectBoundaryPosition(_, boundaryLine, index, x, z)
    local distancePos = 0
    local distanceNeg = 0
    local i = 1
    for i = i, #boundaryLine do
        if boundaryLine[index + i] == nil then
            break
        end
        local x1 = boundaryLine[index + i][1]
        local z1 = boundaryLine[index + i][2]
        local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x, z, boundaryLine)
        if not intersect then
            local distancePos = distancePos + MathUtil.vector2Length(x1 - x, z1 - z)
            return index + i, distancePos
        end
        distancePos = distancePos + MathUtil.vector2Length(boundaryLine[index + i][1] - boundaryLine[index + i - 1][1], boundaryLine[index + i][2] - boundaryLine[index + i - 1][2])
        if boundaryLine[index - i] == nil then
            break
        end
        local x2 = boundaryLine[index - i][1]
        local z2 = boundaryLine[index - i][2]
        local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x2, z2, x, z, boundaryLine)
        if not intersect then
            local distanceNeg = distanceNeg + MathUtil.vector2Length(x2 - x, z2 - z)
            return index - i, distanceNeg
        end
        distanceNeg = distanceNeg + MathUtil.vector2Length(boundaryLine[index - i][1] - boundaryLine[index - i + 1][1], boundaryLine[index - i][2] - boundaryLine[index - i + 1][2])
    end
    return nil
end
function AIFieldCourseSegmentOrderTask:adjustSegmentLength(segment, direction, callback)
    if (segment.isHeadlandSegment or segment.isIslandSegment) and self.extendedHeadlandSegments[segment] == nil then
        local boundaryLine = self.aiFieldCourse.fieldRootBoundary.boundaryLine
        if segment.islandIndex == nil then
            if segment.headlandIndex > 1 then
                local headlandBoundary = self.aiFieldCourse.headlandBoundaries[segment.headlandIndex - 1]
                if headlandBoundary ~= nil then
                    boundaryLine = headlandBoundary.boundaryLine
                end
            end
        else
            local headlandBoundary = self.aiFieldCourse.islands[segment.islandIndex]
            if headlandBoundary ~= nil then
                if segment.headlandIndex > 1 then
                    local headlandBoundary = headlandBoundary.boundaries[segment.headlandIndex - 1]
                    if headlandBoundary ~= nil then
                        boundaryLine = headlandBoundary.boundaryLine
                    end
                else
                    boundaryLine = headlandBoundary.rootBoundary.boundaryLine
                end
            end
        end
        local headlandBoundary = true
        for otherSegment, _ in pairs(self.extendedHeadlandSegments) do
            if segment.islandIndex == otherSegment.islandIndex and segment.headlandIndex == otherSegment.headlandIndex then
                headlandBoundary = false
                break
            end
        end
        self.extendedHeadlandSegments[segment] = true
        local headlandBoundary = math.sign(self.fieldCourseSettings.toolFrontOffset)
        AIFieldCourseUtil.extendHeadlandSegment(self.segments, segment.index, direction, headlandBoundary, self.fieldCourseSettings.implementWidth, boundaryLine)
        if headlandBoundary then
            AIFieldCourseUtil.extendHeadlandSegment(self.segments, segment.index, -direction, 1, self.fieldCourseSettings.implementWidth, boundaryLine, true, direction)
        end
    end
    local boundaryLine = table.clone(segment, 5)
    if dp ~= nil then
        local headlandBoundary = 1
        local boundaryLine = #boundaryLine.positions - 1
        local headlandBoundary = 1
        for headlandBoundary = headlandBoundary, boundaryLine, headlandBoundary do
            local p1 = boundaryLine.positions[headlandBoundary]
            local p2 = boundaryLine.positions[headlandBoundary + 1]
            if MathUtil.vector2Length(p2[1] - p1[1], p2[2] - p1[2]) == 0 then
                dp(p1[1], p1[2], "Zero Length Segment")
            end
        end
    end
    if self.fieldCourseSettings.sideOffset ~= 0 then
        if boundaryLine.sideOffsetToApply == nil then
            local boundaryLine = self.fieldCourseSettings.sideOffset
            local boundaryLine
            if self.fieldCourseSettings.variableSideOffset == true then
                local headlandBoundary = self:getPreferedOffsetSide(boundaryLine, direction)
                if headlandBoundary == nil then
                else
                    boundaryLine = math.abs(boundaryLine) * headlandBoundary
                end
            end
            FieldCourseBoundary.segmentApplySideOffset(boundaryLine, boundaryLine)
            boundaryLine.sideOffset = boundaryLine * direction
        else
            FieldCourseBoundary.segmentApplySideOffset(boundaryLine, boundaryLine.sideOffsetToApply)
            boundaryLine.sideOffsetToApply = nil
        end
    end
    if self.fieldCourseSettings.toolFullOverlap then
        FieldCourseUtil.extendSegment(boundaryLine.positions, direction, -self.fieldCourseSettings.toolBackOffset)
        FieldCourseUtil.extendSegment(boundaryLine.positions, -direction, self.fieldCourseSettings.toolFrontOffset)
    elseif self.fieldCourseSettings.toolFullOverlapInside and not (boundaryLine.isHeadlandSegment or boundaryLine.isIslandSegment) then
        FieldCourseUtil.extendSegment(boundaryLine.positions, direction, -self.fieldCourseSettings.toolBackOffset)
        FieldCourseUtil.extendSegment(boundaryLine.positions, -direction, self.fieldCourseSettings.toolFrontOffset)
    else
        FieldCourseUtil.extendSegment(boundaryLine.positions, direction, -self.fieldCourseSettings.toolFrontOffset)
        if self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing then
            FieldCourseUtil.extendSegment(boundaryLine.positions, -direction, self.fieldCourseSettings.toolBackOffset)
        end
    end
    self.segmentCollisionCheck:checkSegment(boundaryLine, direction, function(_segment)
        -- upvalues: (copy) callback
        callback(_segment)
    end)
end
function AIFieldCourseSegmentOrderTask:getNeighbouringUsedSegment(segment)
    if segment.lineGroupIndex == nil then
        if segment.headlandIndex ~= nil then
            for originalSegment, adjustedSegment in pairs(self.adjustedSegments) do
                if adjustedSegment.islandIndex == segment.islandIndex and (adjustedSegment.headlandIndex == segment.headlandIndex + 1 or adjustedSegment.headlandIndex == segment.headlandIndex - 1) and AIFieldCourseUtil.getSegmentToSegmentDistance(segment, originalSegment) < self.fieldCourseSettings.implementWidth + 0.01 then
                    return adjustedSegment
                end
            end
        end
    else
        local prevSegment = self.segments[segment.index - 1]
        if prevSegment ~= nil and self.adjustedSegments[prevSegment] ~= nil then
            return self.adjustedSegments[prevSegment]
        end
        local nextSegment = self.segments[segment.index + 1]
        if nextSegment ~= nil and self.adjustedSegments[nextSegment] ~= nil then
            return self.adjustedSegments[nextSegment]
        end
    end
end
function AIFieldCourseSegmentOrderTask:getPreferedOffsetSide(segment, direction)
    if segment.headlandIndex == nil then
        local segmentBoundary, island, z1, x2
        if direction < 0 then
            local z2 = #segment.positions
            segmentBoundary = segment.positions[z2][1]
            island = segment.positions[z2][2]
            z1 = segment.positions[z2 - 1][1]
            x2 = segment.positions[z2 - 1][2]
        else
            segmentBoundary = segment.positions[1][1]
            island = segment.positions[1][2]
            z1 = segment.positions[2][1]
            x2 = segment.positions[2][2]
        end
        local z2, numPositions = MathUtil.vector2Normalize(z1 - segmentBoundary, x2 - island)
        local cz = self:getNeighbouringUsedSegment(segment)
        if cz == nil then
            local maxDistance = self.aiFieldCourse.fieldRootBoundary.boundaryLine
            local intersect1, ix1, iz1 = FieldCourseUtil.getSegmentClosestBoundaryIntersection((segmentBoundary + z1) * 0.5, (island + x2) * 0.5, (segmentBoundary + z1) * 0.5 + numPositions * 100, (island + x2) * 0.5 - z2 * 100, maxDistance)
            local intersect2, ix2, iz2 = FieldCourseUtil.getSegmentClosestBoundaryIntersection(dirZ, cx, dirZ - numPositions * 100, cx + z2 * 100, maxDistance)
            if intersect1 and intersect2 then
                if MathUtil.vector2Length(dirZ - ix1, cx - iz1) > MathUtil.vector2Length(dirZ - ix2, cx - iz2) then
                    direction = -direction or direction
                end
                return direction
            end
            if intersect1 then
                return direction
            end
            if intersect2 then
                return -direction
            end
        else
            local maxDistance = self.fieldCourseSettings.implementWidth * self.fieldCourseSettings.numHeadlands
            local intersect1, ix1, iz1 = FieldCourseUtil.getSegmentBoundaryIntersection(dirZ, cx, dirZ + numPositions * maxDistance, cx - z2 * maxDistance, cz.positions)
            local intersect2, ix2, iz2 = FieldCourseUtil.getSegmentBoundaryIntersection(dirZ, cx, dirZ + numPositions * maxDistance, cx - z2 * maxDistance, cz.positions)
            if intersect1 and intersect2 then
                if MathUtil.vector2Length(dirZ - ix1, cx - iz1) > MathUtil.vector2Length(dirZ - ix2, cx - iz2) then
                    direction = -direction or direction
                end
                return direction
            end
            if intersect1 then
                return direction
            end
            if intersect2 then
                return -direction
            end
        end
    else
        local segmentBoundary = self.aiFieldCourse.fieldRootBoundary.boundaryLine
        if segment.islandIndex ~= nil then
            local island = self.aiFieldCourse.islands[segment.islandIndex]
            if island ~= nil then
                segmentBoundary = island.rootBoundary.boundaryLine
            end
        end
        local island, z1, x2, z2
        if direction < 0 then
            local numPositions = #segment.positions
            island = segment.positions[numPositions][1]
            z1 = segment.positions[numPositions][2]
            x2 = segment.positions[numPositions - 1][1]
            z2 = segment.positions[numPositions - 1][2]
        else
            island = segment.positions[1][1]
            z1 = segment.positions[1][2]
            x2 = segment.positions[2][1]
            z2 = segment.positions[2][2]
        end
        local numPositions, dirZ = MathUtil.vector2Normalize(x2 - island, z2 - z1)
        local cx = (island + x2) * 0.5
        local cz = (z1 + z2) * 0.5
        local maxDistance = self.fieldCourseSettings.implementWidth * self.fieldCourseSettings.numHeadlands
        local intersect1, ix1, iz1 = FieldCourseUtil.getSegmentClosestBoundaryIntersection(cx, cz, cx + dirZ * maxDistance, cz - numPositions * maxDistance, segmentBoundary)
        local intersect2, ix2, iz2 = FieldCourseUtil.getSegmentClosestBoundaryIntersection(cx, cz, cx - dirZ * maxDistance, cz + numPositions * maxDistance, segmentBoundary)
        if intersect1 and intersect2 then
            return MathUtil.vector2Length(cx - ix1, cz - iz1) > MathUtil.vector2Length(cx - ix2, cz - iz2) and direction and direction or -direction
        end
        if intersect1 then
            return -direction
        end
        if intersect2 then
            return direction
        end
    end
    return nil
end