function AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, segment1, segment1Direction, segment2, segment2Direction, aiFieldCourse, turnRadius)
    local self = {
        ["startOffset"] = 0,
        ["endOffset"] = 0,
        ["sx"] = sx,
        ["sz"] = sz,
        ["sDirX"] = sDirX,
        ["sDirZ"] = sDirZ,
        ["ex"] = ex,
        ["ez"] = ez,
        ["eDirX"] = eDirX,
        ["eDirZ"] = eDirZ,
        ["segment1"] = segment1,
        ["segment2"] = segment2,
        ["segment1Direction"] = segment1Direction,
        ["segment2Direction"] = segment2Direction,
        ["fieldRootBoundary"] = aiFieldCourse.fieldRootBoundary,
        ["validPathBoundary"] = aiFieldCourse.validPathBoundary,
        ["protectedBoundary"] = aiFieldCourse.protectedBoundary,
        ["islands"] = aiFieldCourse.islands
    }
    local fieldCourseSettings = aiFieldCourse.fieldCourseSettings
    self.turnRadius = turnRadius or fieldCourseSettings.minTurnRadius
    self.canTurnBackward = fieldCourseSettings.canTurnBackward
    self.allowStraightReversing = fieldCourseSettings.allowStraightReversing
    self.implementWidth = fieldCourseSettings.implementWidth
    self.toolFrontOffset = fieldCourseSettings.toolFrontOffset
    self.toolBackOffset = fieldCourseSettings.toolBackOffset
    function self.clone(parentData, useStartSegment, useEndSegment)
        -- upvalues: (copy) self
        if useStartSegment == false or useEndSegment == false then
            local turnData = parentData:rawClone()
            turnData.originalTurnData = parentData.originalTurnData
            if not useStartSegment then
                turnData.segment1 = nil
                turnData.segment1Direction = 1
            end
            if not useEndSegment then
                turnData.segment2 = nil
                turnData.segment2Direction = 1
            end
            return turnData
        end
        local turnData = {}
        setmetatable(turnData, {
            ["__index"] = self
        })
        turnData.originalTurnData = parentData.originalTurnData
        turnData.startOffset = parentData.startOffset
        turnData.endOffset = parentData.endOffset
        turnData.sx = parentData.sx
        turnData.sz = parentData.sz
        turnData.sDirX = parentData.sDirX
        turnData.sDirZ = parentData.sDirZ
        turnData.ex = parentData.ex
        turnData.ez = parentData.ez
        turnData.eDirX = parentData.eDirX
        turnData.eDirZ = parentData.eDirZ
        return turnData
    end
    function self.rawClone(parentData)
        -- upvalues: (copy) sx, (copy) sz, (copy) sDirX, (copy) sDirZ, (copy) ex, (copy) ez, (copy) eDirX, (copy) eDirZ, (copy) segment1, (copy) segment1Direction, (copy) segment2, (copy) segment2Direction, (copy) aiFieldCourse, (copy) turnRadius
        local turnData = AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, segment1, segment1Direction, segment2, segment2Direction, aiFieldCourse, turnRadius)
        turnData.startOffset = parentData.startOffset
        turnData.endOffset = parentData.endOffset
        turnData.sx = parentData.sx
        turnData.sz = parentData.sz
        turnData.sDirX = parentData.sDirX
        turnData.sDirZ = parentData.sDirZ
        turnData.ex = parentData.ex
        turnData.ez = parentData.ez
        turnData.eDirX = parentData.eDirX
        turnData.eDirZ = parentData.eDirZ
        turnData.segment1 = parentData.segment1
        turnData.segment2 = parentData.segment2
        turnData.segment1Direction = parentData.segment1Direction
        turnData.segment2Direction = parentData.segment2Direction
        turnData.fieldRootBoundary = parentData.fieldRootBoundary
        turnData.validPathBoundary = parentData.validPathBoundary
        turnData.protectedBoundary = parentData.protectedBoundary
        turnData.islands = parentData.islands
        turnData.turnRadius = parentData.turnRadius
        turnData.canTurnBackward = parentData.canTurnBackward
        turnData.allowStraightReversing = parentData.allowStraightReversing
        turnData.implementWidth = parentData.implementWidth
        turnData.toolFrontOffset = parentData.toolFrontOffset
        turnData.toolBackOffset = parentData.toolBackOffset
        return turnData
    end
    function self.offset(_, startOffset, endOffset, limitToOneSegment)
        -- upvalues: (copy) self
        local turnData = {}
        setmetatable(turnData, {
            ["__index"] = self
        })
        turnData.originalTurnData = self
        turnData.startOffset = startOffset or (turnData.startOffset or 0)
        turnData.endOffset = endOffset or (turnData.endOffset or 0)
        if turnData.segment1 ~= nil then
            turnData.sx, turnData.sz, turnData.sDirX, turnData.sDirZ = AIFieldCourseUtil.getSegmentPositionAndDirection(false, turnData.segment1, turnData.segment1Direction, turnData.startOffset, limitToOneSegment)
        end
        if turnData.segment2 ~= nil then
            turnData.ex, turnData.ez, turnData.eDirX, turnData.eDirZ = AIFieldCourseUtil.getSegmentPositionAndDirection(true, turnData.segment2, turnData.segment2Direction, turnData.endOffset, limitToOneSegment)
        end
        return turnData
    end
    return self
end