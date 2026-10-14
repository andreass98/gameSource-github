BoundaryDetectionTask = {}
local BoundaryDetectionTask_mt = Class(BoundaryDetectionTask)
function BoundaryDetectionTask.new(x, z)
    -- upvalues: (copy) BoundaryDetectionTask_mt
    local self = setmetatable({}, BoundaryDetectionTask_mt)
    self.startX = x
    self.startZ = z
    self.curX = x
    self.curZ = z
    self.boundaryPositions = {}
    self.terrainDetailId = g_currentMission.terrainDetailId
    self.terrainDetailResolution = g_currentMission.terrainSize / g_currentMission.terrainDetailMapSize
    if getDensityAtWorldPos(self.terrainDetailId, self.curX, 0, self.curZ) == 0 then
        return nil
    else
        return self
    end
end
function BoundaryDetectionTask:update(_, frameBudget)
    local startTime = getTimeSec()
    while getTimeSec() - startTime < frameBudget do
        if #self.boundaryPositions == 0 then
            local isOnField = getDensityAtWorldPos(self.terrainDetailId, self.curX, 0, self.curZ) ~= 0
            if isOnField then
                self.curZ = self.curZ + self.terrainDetailResolution
            else
                table.insert(self.boundaryPositions, { self.curX, self.curZ })
            end
        else
            local isOnField = #self.boundaryPositions
            local dirX, dirZ
            if isOnField >= 2 then
                dirX = self.boundaryPositions[isOnField][1] - self.boundaryPositions[isOnField - 1][1]
                dirZ = self.boundaryPositions[isOnField][2] - self.boundaryPositions[isOnField - 1][2]
            elseif getDensityAtWorldPos(self.terrainDetailId, self.curX + terrainDetailResolution, 0, self.curZ) == 0 then
                dirX = -1
                dirZ = 0
            elseif getDensityAtWorldPos(self.terrainDetailId, self.curX, 0, self.curZ + terrainDetailResolution) == 0 then
                dirX = 0
                dirZ = -1
            else
                dirX = 1
                dirZ = 0
            end
            local frontValue, leftValue = MathUtil.vector2Normalize(dirX, dirZ)
            local dirX = frontValue * terrainDetailResolution
            local dirZ = leftValue * terrainDetailResolution
            local frontValue = getDensityAtWorldPos(self.terrainDetailId, self.curX + dirX, 0, self.curZ + dirZ)
            local leftValue = getDensityAtWorldPos(self.terrainDetailId, self.curX + dirZ, 0, self.curZ - dirX)
            local rightValue = getDensityAtWorldPos(self.terrainDetailId, self.curX - dirZ, 0, self.curZ + dirX)
            if rightValue == 0 or frontValue ~= 0 then
                if rightValue == 0 then
                    self.curX = self.curX - dirZ
                    self.curZ = self.curZ + dirX
                elseif leftValue == 0 then
                    self.curX = self.curX + dirZ
                    self.curZ = self.curZ - dirX
                else
                    self.curX = self.curX - dirX
                    self.curZ = self.curZ - dirZ
                end
            else
                self.curX = self.curX + dirX
                self.curZ = self.curZ + dirZ
            end
            local pDirZ = self.boundaryPositions
            table.insert(pDirZ, { self.curX, self.curZ })
        end
        local isOnField = #self.boundaryPositions
        if isOnField > 10 and MathUtil.vector2Length(self.boundaryPositions[isOnField][1] - self.boundaryPositions[1][1], self.boundaryPositions[isOnField][2] - self.boundaryPositions[1][2]) < self.terrainDetailResolution then
            self:finalize()
            return false
        end
        if isOnField > 15000 then
            local dirX, dirZ = MathUtil.vector2Normalize(self.boundaryPositions[isOnField][1] - self.boundaryPositions[isOnField - 1][1], self.boundaryPositions[isOnField][2] - self.boundaryPositions[isOnField - 1][2])
            local rightValue = isOnField - 1
            for rightValue = rightValue, 2, -1 do
                local pDirZ = self.boundaryPositions[rightValue][1] - self.curX
                if math.abs(pDirZ) < 0.001 then
                    local pDirZ = self.boundaryPositions[rightValue][2] - self.curZ
                    if math.abs(pDirZ) < 0.001 then
                        local pDirX, pDirZ = MathUtil.vector2Normalize(self.boundaryPositions[rightValue][1] - self.boundaryPositions[rightValue - 1][1], self.boundaryPositions[rightValue][2] - self.boundaryPositions[rightValue - 1][2])
                        if math.abs(dirX - pDirX) < 0.001 then
                            if math.abs(dirZ - pDirZ) < 0.001 then
                                Logging.devWarning("BoundaryDetectionTask: Unable to detect field boundary - infinite loop detected")
                                self:finalize()
                                return false
                            end
                        end
                    end
                end
            end
        end
    end
    return true
end
function BoundaryDetectionTask:getMaxZ()
    local maxZ = -math.huge
    for _, position in pairs(self.boundaryPositions) do
        maxZ = math.max(maxZ, position[2])
    end
    return maxZ
end
function BoundaryDetectionTask:finalize()
    local maxValue = -math.huge
    local maxValueIndex = 0
    for i, position in pairs(self.boundaryPositions) do
        local value = position[1] * position[2] * 0.1
        if maxValue < value then
            maxValueIndex = i
            maxValue = value
        end
    end
    local newBoundaryPositions = {}
    for maxValueIndex = maxValueIndex, #self.boundaryPositions do
        table.insert(newBoundaryPositions, self.boundaryPositions[maxValueIndex])
    end
    local i = 1
    for i = i, maxValueIndex - 1 do
        table.insert(newBoundaryPositions, self.boundaryPositions[i])
    end
    local i = { newBoundaryPositions[1][1], newBoundaryPositions[1][2] }
    table.insert(newBoundaryPositions, i)
    self.boundaryPositions = newBoundaryPositions
end