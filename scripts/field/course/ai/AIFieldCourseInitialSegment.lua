AIFieldCourseInitialSegment = {}
local AIFieldCourseInitialSegment_mt = Class(AIFieldCourseInitialSegment)
function AIFieldCourseInitialSegment.new(aiFieldCourse, _)
    -- upvalues: (copy) AIFieldCourseInitialSegment_mt
    local self = setmetatable({}, AIFieldCourseInitialSegment_mt)
    self.aiFieldCourse = aiFieldCourse
    self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
    self.turnGenerator = AIFieldCourseTurnGenerator.new(aiFieldCourse)
    self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
    local initialTurnRadius = self.fieldCourseSettings.minTurnRadius * self.fieldCourseSettings.initialTurnRadiusFactor
    self.turnGenerator:setMaxOffset(initialTurnRadius * 3)
    self.turnGenerator:setOverwrittenTurnRadius(initialTurnRadius)
    self.furtherSegments = {}
    return self
end
function AIFieldCourseInitialSegment:setCallback(callbackFunc, callbackTarget)
    self.callbackFunc = callbackFunc
    self.callbackTarget = callbackTarget
end
function AIFieldCourseInitialSegment:generate(startX, startZ, startDirX, startDirZ)
    self.startX = startX
    self.startZ = startZ
    self.startDirX = startDirX
    self.startDirZ = startDirZ
    if FieldCourseUtil.getIsPointInsideBoundary(self.startX, self.startZ, self.aiFieldCourse.protectedBoundary.boundaryLine) then
        self:generateFinalSegment(startX, startZ, startDirX, startDirZ)
        return true
    end
    local initialTurnRadius = self.fieldCourseSettings.minTurnRadius * self.fieldCourseSettings.initialTurnRadiusFactor
    local minDistance = math.huge
    local intersect = nil
    local ix = nil
    local iz = nil
    local cx = nil
    local cz = nil
    local side = nil
    local i = 10
    for i = i, 1, -1 do
        local radius = initialTurnRadius * i + 0.01
        local circleX = self.startX - startDirZ * radius
        local circleZ = self.startZ + startDirX * radius
        local _intersect, _ix, _iz = FieldCourseUtil.getSegmentClosestBoundaryCircleIntersection(self.startX + startDirX * 0.5, self.startZ + startDirZ * 0.5, circleX, circleZ, radius, self.aiFieldCourse.protectedBoundary.boundaryLine)
        local distance
        if _intersect then
            distance = MathUtil.vector2Length(_ix - self.startX, _iz - self.startZ) * (1 + (10 - i) * 0.05)
            if distance < minDistance then
                intersect = true
                side = 1
            else
                circleZ = cz
                _iz = iz
                circleX = cx
                _ix = ix
                distance = minDistance
            end
        else
            circleZ = cz
            _iz = iz
            circleX = cx
            _ix = ix
            distance = minDistance
        end
        cx = self.startX + startDirZ * radius
        cz = self.startZ - startDirX * radius
        local distance
        distance, ix, iz = FieldCourseUtil.getSegmentClosestBoundaryCircleIntersection(self.startX + startDirX * 0.5, self.startZ + startDirZ * 0.5, cx, cz, radius, self.aiFieldCourse.protectedBoundary.boundaryLine)
        if distance then
            minDistance = MathUtil.vector2Length(ix - self.startX, iz - self.startZ) * cost
            if minDistance < distance then
                intersect = true
                side = -1
            else
                cz = circleZ
                iz = _iz
                cx = circleX
                ix = _ix
                minDistance = distance
            end
        else
            cz = circleZ
            iz = _iz
            cx = circleX
            ix = _ix
            minDistance = distance
        end
    end
    if not intersect then
        return false
    end
    local circleHitDirX, circleHitDirZ = MathUtil.vector2Normalize(ix - cx, iz - cz)
    local i = -circleHitDirZ * side
    local cost = circleHitDirX * side
    local ix = ix + i * 0.1
    local iz = iz + cost * 0.1
    self.turnGenerator:setIgnoreBoundaryIntersections(true)
    self.turnGenerator:setMaxOffset(initialTurnRadius * 2)
    self.turnGenerator:setCallback(self.onIntoFieldSegmentTurnDataFound, self)
    self.turnGenerator:generatePositionToPosition(self.startX, self.startZ, startDirX, startDirZ, ix, iz, i, cost)
    return true
end
function AIFieldCourseInitialSegment:onIntoFieldSegmentTurnDataFound(turn)
    if turn == nil then
        self:debugPrint("Failed to generate into-field segment")
        self:doCallback(false)
    else
        turn.isInitialLine = true
        self.intoFieldSegment = turn
        local turnData = turn.turnData
        self:generateFinalSegment(turnData.ex, turnData.ez, turnData.eDirX, turnData.eDirZ)
    end
end
function AIFieldCourseInitialSegment:generateFinalSegment(sx, sz, sDirX, sDirZ)
    self.isx = sx
    self.isz = sz
    self.isDirX = sDirX
    self.isDirZ = sDirZ
    self.aiFieldCourse.segmentOrderTask:setStartPosition(sx, sz, sDirX, sDirZ)
    self.aiFieldCourse.segmentOrderTask:next(self.onFirstSegmentFound, self, 1)
end
function AIFieldCourseInitialSegment:onFirstSegmentFound(segmentData, direction, isTurn, addStraighting, _, isLast)
    if segmentData == nil then
        self:debugPrint("Failed to find first segment.")
        self:doCallback(false)
    else
        table.insert(self.furtherSegments, {
            ["segmentData"] = segmentData,
            ["direction"] = direction,
            ["isTurn"] = isTurn,
            ["addStraighting"] = addStraighting
        })
        if isLast then
            local firstSegment = self.furtherSegments[1]
            self.turnGenerator:setIgnoreBoundaryIntersections(true)
            self.turnGenerator:setCallback(self.onSegmentOutsideFieldTurnDataFound, self)
            self.turnGenerator:generatePositionToSegment(self.startX, self.startZ, self.startDirX, self.startDirZ, firstSegment.segmentData, firstSegment.direction)
        end
    end
end
function AIFieldCourseInitialSegment:onSegmentOutsideFieldTurnDataFound(turn)
    if turn == nil then
        self:debugPrint("Failed to generate initial segment with full boundary intersections")
        self:doCallback(false, true)
    else
        AIFieldCourseTurnCollisionCheck.new(turn, self.fieldCourseSettings, self.onSegmentOutsideFieldCollisionCheckFinished, self)
    end
end
function AIFieldCourseInitialSegment:onSegmentOutsideFieldCollisionCheckFinished(success, turn)
    if success then
        self.intoFieldSegment = nil
        self:onSegmentTurnDataFound(turn)
    else
        local firstSegment = self.furtherSegments[1]
        self.turnGenerator:setIgnoreBoundaryIntersections(false)
        self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
        self.turnGenerator:generatePositionToSegment(self.isx, self.isz, self.isDirX, self.isDirZ, firstSegment.segmentData, firstSegment.direction)
    end
end
function AIFieldCourseInitialSegment:onSegmentTurnDataFound(turn)
    if turn == nil then
        if self.isAlternativeSearch then
            self:debugPrint("Failed to generate additional turn segment with protected boundary intersection")
            self:doCallback(false, true)
        else
            self.isAlternativeSearch = true
            local numSegments = not FieldCourseUtil.getIsPointInsideBoundary(self.isx, self.isz, self.aiFieldCourse.fieldRootBoundary.boundaryLine)
            self.turnGenerator:setIgnoreBoundaryIntersections(numSegments)
            self.turnGenerator:setMaxOffset(nil)
            self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
            self.turnGenerator:generatePositionToSegment(self.isx, self.isz, self.isDirX, self.isDirZ, self.furtherSegments[1].segmentData, self.furtherSegments[1].direction)
        end
    else
        firstSegment.segmentData.lastStartOffset = turn.turnData.startOffset
        if self.intoFieldSegment ~= nil then
            turn.isInitialLine = true
            self:doCallback(true, false, self.intoFieldSegment, 1, true, false)
        end
        self:doCallback(true, false, turn, 1, true, true)
        for i, furtherSegment in ipairs(self.furtherSegments) do
            local nextTurn = nil
            if i < #self.furtherSegments then
                local nextSegment = self.furtherSegments[i + 1]
                if nextSegment.isTurn then
                    nextTurn = nextSegment.segmentData
                end
            end
            self:doCallback(true, i == #self.furtherSegments, furtherSegment.segmentData, furtherSegment.direction, furtherSegment.isTurn, furtherSegment.addStraighting, nextTurn)
        end
        return
    end
end
function AIFieldCourseInitialSegment:doCallback(success, isLast, segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
    if self.callbackTarget == nil then
        self.callbackFunc(success, isLast, segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
    else
        self.callbackFunc(self.callbackTarget, success, isLast, segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
    end
end
function AIFieldCourseInitialSegment.debugPrint(_, text, ...)
    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
        print("AIFieldCourseInitialSegment: " .. string.format(text, ...))
    end
end