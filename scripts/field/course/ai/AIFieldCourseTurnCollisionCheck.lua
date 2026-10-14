AIFieldCourseTurnCollisionCheck = {}
local AIFieldCourseTurnCollisionCheck_mt = Class(AIFieldCourseTurnCollisionCheck)
function AIFieldCourseTurnCollisionCheck.new(turn, fieldCourseSettings, callbackFunc, callbackTarget)
    -- upvalues: (copy) AIFieldCourseTurnCollisionCheck_mt
    local self = setmetatable({}, AIFieldCourseTurnCollisionCheck_mt)
    self.turn = turn
    self.fieldCourseSettings = fieldCourseSettings
    self.callbackFunc = callbackFunc
    self.callbackTarget = callbackTarget
    self.stepLength = (self.fieldCourseSettings.agentFrontOffset + self.fieldCourseSettings.agentBackOffset) * 0.5
    self.segmentIndex = 1
    self.segmentPosition = 0
    self.x = 0
    self.z = 0
    self.phi = 0
    self.lastWx = turn.turnData.sx - turn.turnData.sDirX
    self.lastWz = turn.turnData.sz - turn.turnData.sDirZ
    g_fieldCourseManager:addUpdateable(self)
    return self
end
function AIFieldCourseTurnCollisionCheck:update(_)
    if self.overlapInProgress then
        return
    else
        local segment = self.turn.segments[self.segmentIndex]
        if segment == nil then
            self:doCallback(true)
        else
            local delta = self.stepLength / self.turn.turnData.turnRadius
            self.segmentPosition = self.segmentPosition + delta
            if self.segmentPosition >= segment:getLength() then
                self.segmentIndex = self.segmentIndex + 1
                local nextSegment = self.turn.segments[self.segmentIndex]
                local dirZ = segment:getLength() - (self.segmentPosition - delta)
                local wz = math.min(delta, dirZ)
                local wz, dirX, dirZ = segment:move(self.x, self.z, self.phi, wz, self.turn.turnData.turnRadius)
                self.x = wz
                self.z = dirX
                self.phi = dirZ
                if nextSegment == nil or segment.drivingDirection ~= nextSegment.drivingDirection then
                    self.segmentPosition = 0
                else
                    local wz, dirX, dirZ = nextSegment:move(self.x, self.z, self.phi, self.stepLength / self.turn.turnData.turnRadius - wz, self.turn.turnData.turnRadius)
                    self.x = wz
                    self.z = dirX
                    self.phi = dirZ
                    self.segmentPosition = self.segmentPosition - segment:getLength()
                end
            else
                local nextSegment, wz, dirX = segment:move(self.x, self.z, self.phi, delta, self.turn.turnData.turnRadius)
                self.x = nextSegment
                self.z = wz
                self.phi = dirX
            end
            local nextSegment = self.turn.turnData.sx + self.turn.turnData.sDirX * self.x - self.turn.turnData.sDirZ * self.z
            local wz = self.turn.turnData.sz + self.turn.turnData.sDirZ * self.x + self.turn.turnData.sDirX * self.z
            local dirX, dirZ = MathUtil.vector2Normalize(nextSegment - self.lastWx, wz - self.lastWz)
            local centerZ = (self.fieldCourseSettings.agentFrontOffset - self.fieldCourseSettings.agentBackOffset) * 0.5
            if segment.drivingDirection < 0 then
            end
            local bx = self.lastWx + dirX * centerZ
            local bz = self.lastWz + dirZ * centerZ
            local sizeX = MathUtil.getYRotationFromDirection(dirX, dirZ)
            local sizeY = self.fieldCourseSettings.agentHeight + 0.5
            local by = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, bx, 0, bz) + sizeY * 0.5
            overlapBoxAsync(bx, by, bz, 0, self.fieldCourseSettings.implementWidth + 0.5, 0, sizeX * 0.5, sizeY * 0.5, (self.fieldCourseSettings.agentFrontOffset + self.fieldCourseSettings.agentBackOffset) * 0.5, "overlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
            self.overlapInProgress = true
            self.lastWx = nextSegment
            self.lastWz = wz
        end
    end
end
function AIFieldCourseTurnCollisionCheck:overlapCallback(nodeId, _)
    if nodeId ~= 0 then
        self:doCallback(false)
    end
    self.overlapInProgress = false
    return false
end
function AIFieldCourseTurnCollisionCheck:doCallback(success)
    g_fieldCourseManager:removeUpdateable(self)
    if self.callbackTarget == nil then
        self.callbackFunc(success, self.turn)
    else
        self.callbackFunc(self.callbackTarget, success, self.turn)
    end
end