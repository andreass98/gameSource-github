AIFieldCourseSegmentCollisionCheck = {}
source("dataS/scripts/field/course/ai/AIFieldCourseSegmentCollisionCheckState.lua")
local AIFieldCourseSegmentCollisionCheck_mt = Class(AIFieldCourseSegmentCollisionCheck)
function AIFieldCourseSegmentCollisionCheck.new(fieldCourseSettings, fieldBoundaryLine, _, _)
    -- upvalues: (copy) AIFieldCourseSegmentCollisionCheck_mt
    local self = setmetatable({}, AIFieldCourseSegmentCollisionCheck_mt)
    self.fieldCourseSettings = fieldCourseSettings
    self.fieldBoundaryLine = fieldBoundaryLine
    self.state = AIFieldCourseSegmentCollisionCheckState.INITIAL
    return self
end
function AIFieldCourseSegmentCollisionCheck:next()
    local numPositions = self.fieldCourseSettings.toolFrontOffset
    local x1 = self.fieldCourseSettings.agentFrontOffset
    local frontOffset = math.max(numPositions, x1) + 0.5
    local x1 = self.fieldCourseSettings.toolBackOffset
    local z1 = -self.fieldCourseSettings.agentBackOffset
    local backOffset = math.min(x1, z1) - 0.5
    local numPositions = #self.segment.positions
    if self.state == AIFieldCourseSegmentCollisionCheckState.START_CHECK or self.state == AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT then
        local x1, z1, bx, bz
        if self.direction > 0 then
            bx, bz = MathUtil.vector2Normalize(segment.positions[2][1] - self.segment.positions[1][1], segment.positions[2][2] - segment.positions[1][2])
        else
            bx, bz = MathUtil.vector2Normalize(segment.positions[numPositions - 1][1] - segment.positions[numPositions][1], segment.positions[numPositions - 1][2] - segment.positions[numPositions][2])
        end
        if self.state == AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT then
            self.startAdjustmentDistance = self.startAdjustmentDistance + 1
            if self.fieldCourseSettings.agentFrontOffset + self.fieldCourseSettings.agentBackOffset + 1 < self.startAdjustmentDistance or self.startAdjustmentDistance + 2 >= self.segmentLength then
                self.state = AIFieldCourseSegmentCollisionCheckState.END_CHECK
                self:next()
                return
            end
        end
        local bx = x1 + bx * (backOffset + agentLength * 0.5)
        local bz = z1 + bz * (backOffset + agentLength * 0.5)
        if segment.sideOffset ~= nil and segment.sideOffset ~= 0 then
        end
        self:overlapCheck(bx, bz, bx, bz, self.fieldCourseSettings.implementWidth + 0.5, self.fieldCourseSettings.agentHeight + 0.5, agentLength, "overlapCallback")
        return
    elseif self.state == AIFieldCourseSegmentCollisionCheckState.END_CHECK or self.state == AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT then
        local x1, z1, bx, bz
        if direction > 0 then
            bx, bz = MathUtil.vector2Normalize(segment.positions[numPositions - 1][1] - segment.positions[numPositions][1], segment.positions[numPositions - 1][2] - segment.positions[numPositions][2])
        else
            bx, bz = MathUtil.vector2Normalize(segment.positions[2][1] - segment.positions[1][1], segment.positions[2][2] - segment.positions[1][2])
        end
        if self.state == AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT then
            self.endAdjustmentDistance = self.endAdjustmentDistance + 1
            if agentLength < self.endAdjustmentDistance or self.endAdjustmentDistance + 2 >= self.segmentLength - self.startAdjustmentDistance then
                self.state = AIFieldCourseSegmentCollisionCheckState.FINISHED
                self:next()
                return
            end
        end
        local bx = x1 - bx * (frontOffset - agentLength * 0.5)
        local bz = z1 - bz * (frontOffset - agentLength * 0.5)
        if segment.sideOffset ~= nil and segment.sideOffset ~= 0 then
        end
        self:overlapCheck(bx, bz, bx, bz, self.fieldCourseSettings.implementWidth + 0.5, self.fieldCourseSettings.agentHeight + 0.5, agentLength, "overlapCallback")
    elseif self.state == AIFieldCourseSegmentCollisionCheckState.FINISHED then
        if self.startAdjustmentDistance ~= 0 then
            FieldCourseUtil.extendSegment(segment.positions, -direction, -self.startAdjustmentDistance)
        end
        if self.endAdjustmentDistance ~= 0 then
            FieldCourseUtil.extendSegment(segment.positions, direction, -self.endAdjustmentDistance)
        end
        self:doCallback()
    end
end
function AIFieldCourseSegmentCollisionCheck:checkSegment(segment, direction, callbackFunc, callbackTarget)
    self.segment = segment
    self.segmentLength = FieldCourseUtil.getSegmentLength(segment.positions)
    self.direction = direction
    self.callbackFunc = callbackFunc
    self.callbackTarget = callbackTarget
    self.startAdjustmentDistance = 0
    self.endAdjustmentDistance = 0
    self.state = AIFieldCourseSegmentCollisionCheckState.START_CHECK
    self:next()
end
function AIFieldCourseSegmentCollisionCheck:overlapCheck(x, z, dirX, dirZ, sizeX, sizeY, sizeZ, callbackName, _)
    local ry = MathUtil.getYRotationFromDirection(dirX, dirZ)
    local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + sizeY * 0.5
    sizeX = sizeX * 0.5
    sizeZ = sizeZ * 0.5
    local p1x = x + dirX * sizeZ + dirZ * sizeX
    local p1z = z + dirZ * sizeZ - dirX * sizeX
    local p2x = x + dirX * sizeZ - dirZ * sizeX
    local p2z = z + dirZ * sizeZ + dirX * sizeX
    if FieldCourseUtil.getIsSegmentInsideBoundary(p1x, p1z, p2x, p2z, self.fieldBoundaryLine) then
        local p3x = x - dirX * sizeZ + dirZ * sizeX
        local p3z = z - dirZ * sizeZ - dirX * sizeX
        local p4x = x - dirX * sizeZ - dirZ * sizeX
        local p4z = z - dirZ * sizeZ + dirX * sizeX
        if FieldCourseUtil.getIsSegmentInsideBoundary(p3x, p3z, p4x, p4z, self.fieldBoundaryLine) and (FieldCourseUtil.getIsSegmentInsideBoundary(p1x, p1z, p3x, p3z, self.fieldBoundaryLine) and FieldCourseUtil.getIsSegmentInsideBoundary(p2x, p2z, p4x, p4z, self.fieldBoundaryLine)) then
            self:overlapCallback(0, -1, true)
            return
        end
    end
    overlapBoxAsync(x, y, z, 0, ry, 0, sizeX, sizeY * 0.5, sizeZ, callbackName, self, CollisionFlag.AI_BLOCKING, false, false, true, true)
end
function AIFieldCourseSegmentCollisionCheck:overlapCallback(nodeId, _, _)
    if g_currentMission ~= nil then
        if self.state == AIFieldCourseSegmentCollisionCheckState.START_CHECK then
            if nodeId == 0 then
                self.state = AIFieldCourseSegmentCollisionCheckState.END_CHECK
            else
                self.state = AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT
            end
        elseif self.state == AIFieldCourseSegmentCollisionCheckState.START_ADJUSTMENT then
            if nodeId == 0 then
                self.state = AIFieldCourseSegmentCollisionCheckState.END_CHECK
            end
        elseif self.state == AIFieldCourseSegmentCollisionCheckState.END_CHECK then
            if nodeId == 0 then
                self.state = AIFieldCourseSegmentCollisionCheckState.FINISHED
            else
                self.state = AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT
            end
        elseif self.state == AIFieldCourseSegmentCollisionCheckState.END_ADJUSTMENT and nodeId == 0 then
            self.state = AIFieldCourseSegmentCollisionCheckState.FINISHED
        end
        self:next()
        return false
    end
end
function AIFieldCourseSegmentCollisionCheck:doCallback()
    if self.callbackTarget == nil then
        self.callbackFunc(self.segment)
    else
        self.callbackFunc(self.callbackTarget, self.segment)
    end
end