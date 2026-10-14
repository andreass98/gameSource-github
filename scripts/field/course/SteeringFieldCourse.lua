SteeringFieldCourse = {}
SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX = 11
SteeringFieldCourse.MAX_SEGMENT_INDEX = 2 ^ SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX - 1
local SteeringFieldCourse_mt = Class(SteeringFieldCourse)
function SteeringFieldCourse.new(fieldCourse)
    -- upvalues: (copy) SteeringFieldCourse_mt
    local self = setmetatable({}, SteeringFieldCourse_mt)
    self.fieldCourse = fieldCourse
    self.fieldCourseSettings = fieldCourse.fieldCourseSettings
    self.segments = fieldCourse.segments
    self.rootBoundaryLine = fieldCourse.courseField.fieldRootBoundary.boundaryLine
    self.segmentStates = {}
    local i = 1
    for i = i, #self.segments do
        self.segmentStates[i] = false
    end
    self.segmentStatesDirty = false
    self.currentSegment = nil
    self.currentSegmentIndex = -1
    self.currentSegmentIsLeft = false
    self.vehiclePosition = { 0, 0 }
    self.vehicleSteeringEnabled = false
    self.vehicleSteeringEnabledTimer = 0
    return self
end
function SteeringFieldCourse:writeStream(streamId, connection)
    self:writeSegmentStatesToStream(streamId, connection)
    self.fieldCourse:writeStream(streamId, connection)
end
function SteeringFieldCourse.readStream(streamId, connection, callback)
    local segmentStates = {}
    local numSegmentStates = streamReadUIntN(streamId, SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX)
    local i = 1
    for i = i, numSegmentStates do
        segmentStates[i] = streamReadBool(streamId)
    end
    FieldCourse.readStream(streamId, connection, function(fieldCourse)
        -- upvalues: (copy) segmentStates, (copy) callback
        if fieldCourse == nil then
            callback(nil)
        else
            local steeringFieldCourse = SteeringFieldCourse.new(fieldCourse)
            local i = 1
            for i = i, #steeringFieldCourse.segmentStates do
                steeringFieldCourse.segmentStates[i] = segmentStates[i] or false
            end
            callback(steeringFieldCourse)
        end
    end)
end
function SteeringFieldCourse:writeSegmentStatesToStream(streamId, _)
    local numSegments = math.min(#self.segmentStates, SteeringFieldCourse.MAX_SEGMENT_INDEX)
    streamWriteUIntN(streamId, numSegments, SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX)
    local i = 1
    for i = i, numSegments do
        streamWriteBool(streamId, self.segmentStates[i])
    end
end
function SteeringFieldCourse.readSegmentStatesFromStream(steeringFieldCourse, streamId, _)
    local numSegmentStates = streamReadUIntN(streamId, SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX)
    local i = 1
    for i = i, numSegmentStates do
        local state = streamReadBool(streamId)
        if steeringFieldCourse ~= nil then
            steeringFieldCourse.segmentStates[i] = state
        end
    end
end
function SteeringFieldCourse:saveToXML(xmlFile, key)
    self.fieldCourse:saveToXML(xmlFile, key)
    local workedLinesStr = ""
    local i = 1
    for i = i, #self.segmentStates do
        if self.segmentStates[i] then
            workedLinesStr = workedLinesStr .. string.format("%d ", i)
        end
    end
    xmlFile:setValue(key .. ".workedLines#indices", string.trim(workedLinesStr))
end
function SteeringFieldCourse.loadFromXML(xmlFile, key, callback)
    local workedLinesStr = xmlFile:getValue(key .. ".workedLines#indices")
    FieldCourse.loadFromXML(xmlFile, key, function(fieldCourse)
        -- upvalues: (copy) workedLinesStr, (copy) callback
        if fieldCourse == nil then
            callback(nil)
        else
            local steeringFieldCourse = SteeringFieldCourse.new(fieldCourse)
            local indices = string.split(workedLinesStr, " ")
            local i = 1
            for i = i, #indices do
                local index = tonumber(indices[i])
                if steeringFieldCourse.segmentStates[index] ~= nil then
                    steeringFieldCourse.segmentStates[index] = true
                end
            end
            callback(steeringFieldCourse)
        end
    end)
end
function SteeringFieldCourse:getIsPointInsideBoundary(x, z)
    return self.fieldCourse.courseField == nil and true or self.fieldCourse.courseField:getIsPointInsideBoundary(x, z)
end
function SteeringFieldCourse:updateVehicleData(dt, steeringEnabled, vx, vz, vDirX, vDirZ, sideOffsetReversed)
    if steeringEnabled ~= self.vehicleSteeringEnabled then
        self.vehicleSteeringEnabled = steeringEnabled
        self.vehicleSteeringEnabledTimer = 0
    end
    local maxExtension = self.vehiclePosition
    local minDistanceValid = self.vehiclePosition
    maxExtension[1] = vx
    minDistanceValid[2] = vz
    if steeringEnabled then
        self.vehicleSteeringEnabledTimer = self.vehicleSteeringEnabledTimer + dt
        if self.vehicleSteeringEnabledTimer > 2500 and (self.currentSegmentIndex > 0 and not self.segmentStates[self.currentSegmentIndex]) then
            self.segmentStates[self.currentSegmentIndex] = true
            self.segmentStatesDirty = true
        end
        return false
    end
    local maxExtension = self.fieldCourseSettings.implementWidth * self.fieldCourseSettings.numHeadlands
    local minDistanceValid = math.huge
    local minDistanceValidSegmentIndex = -1
    local minDistanceValidIsLeft = false
    for index, segment in ipairs(self.segments) do
        local lx, lz, lDirX, lDirZ, onLineX, onLineZ = FieldCourseUtil.getClosestExtendedPositionAndDirectionOnSegment(vx, vz, segment.positions, maxExtension)
        if lx ~= nil then
            local distance = MathUtil.vector2Length(vx - lx, vz - lz)
            local offsetX = self.fieldCourseSettings.implementWidth * 3
            local dlx = self.fieldCourseSettings.sideOffset
            local angle = offsetX + math.abs(dlx)
            if distance < math.min(angle, 20) then
                local isLeft = nil
                local offsetX = MathUtil.dotProduct(lDirX, 0, lDirZ, vDirX, 0, vDirZ)
                local angle = math.acos(offsetX)
                if angle < 0.8796459430051422 then
                    isLeft = true
                elseif angle > 2.261946710584651 then
                    isLeft = false
                end
                if isLeft ~= nil then
                    local dlx, dlz = MathUtil.vector2Normalize(onLineX - (vx - vDirX), onLineZ - (vz - vDirZ))
                    local isForward = MathUtil.dotProduct(dlx, 0, dlz, vDirX, 0, vDirZ) > 0
                    if sideOffsetReversed then
                    end
                    local factor = isLeft and 1 or -1
                    local offset = factor * self.fieldCourseSettings.sideOffset
                    local factor = MathUtil.vector2Length(vx - (lx + lDirZ * offset), vz - (lz - lDirX * offset))
                    if angle > 1.5707963267948966 then
                    end
                    local factor = 1 + math.max(angle / 0.7853981633974483 - 0.25, 0)
                    if not isForward then
                    end
                    local distance = factor * factor
                    if distance < minDistanceValid then
                        minDistanceValidIsLeft = isLeft
                        minDistanceValidSegmentIndex = index
                        minDistanceValid = distance
                    end
                end
            end
        end
    end
    return self:setCurrentSegmentIndex(minDistanceValidSegmentIndex, minDistanceValidIsLeft)
end
function SteeringFieldCourse:setCurrentSegmentIndex(segmentIndex, isLeft)
    if segmentIndex == self.currentSegmentIndex and isLeft == self.currentSegmentIsLeft then
        return false
    end
    self.currentSegment = self.segments[segmentIndex]
    if self.currentSegment == nil then
        self.currentSegmentIndex = -1
        self.currentSegmentIsLeft = false
    else
        self.currentSegmentIndex = segmentIndex
        if isLeft == nil then
            self.currentSegmentIsLeft = false
        else
            self.currentSegmentIsLeft = isLeft
        end
        if self.fieldCourseSettings.sideOffset ~= 0 then
            if self.currentSegmentIsLeft then
                self.currentSegment = table.clone(self.currentSegment, 3)
                FieldCourseBoundary.segmentApplySideOffset(self.currentSegment, self.fieldCourseSettings.sideOffset)
            else
                self.currentSegment = table.clone(self.currentSegment, 3)
                FieldCourseBoundary.segmentApplySideOffset(self.currentSegment, -self.fieldCourseSettings.sideOffset)
            end
        end
    end
    return true
end
function SteeringFieldCourse:resetCurrentSegment()
    self.vehicleSteeringEnabled = false
    if self.currentSegment == nil then
        return false
    end
    self.currentSegment = nil
    self.currentSegmentIndex = -1
    self.currentSegmentIsLeft = false
    return true
end
function SteeringFieldCourse.getClosestPositionSegment(segment, wx, wz)
    local minDistance = math.huge
    local minDistanceIndex = -1
    local minDistanceHitX = 0
    local minDistanceHitZ = 0
    local i = 1
    for i = i, #segment.positions - 1 do
        local x1 = segment.positions[i][1]
        local z1 = segment.positions[i][2]
        local dirX = segment.positions[i + 1][1] - x1
        local dirZ = segment.positions[i + 1][2] - z1
        local length = MathUtil.vector2Length(dirX, dirZ)
        local dirX = dirX / length
        local dirZ = dirZ / length
        local dot = MathUtil.getProjectOnLineParameter(wx, wz, x1, z1, dirX, dirZ)
        if dot >= 0 and dot <= length then
            local hitX = x1 + dirX * dot
            local hitZ = z1 + dirZ * dot
            local distance = MathUtil.vector2Length(hitX - wx, hitZ - wz)
            if distance < minDistance then
                minDistanceIndex = i
                minDistanceHitZ = hitZ
                minDistanceHitX = hitX
                minDistance = distance
            end
        end
    end
    return minDistanceHitX, minDistanceHitZ, minDistanceIndex
end
function SteeringFieldCourse:getSteeringTarget(aiRootNode, lookAHeadDistance, _)
    if self.currentSegment == nil then
        return 0, 0, nil
    else
        local segment = self.currentSegment
        local numPositions = #segment.positions
        local distanceToEnd = nil
        local wx, y, wz = getWorldTranslation(aiRootNode)
        local ox, _, oz = localToWorld(aiRootNode, 0, 0, lookAHeadDistance)
        local minDistanceHitX, minDistanceHitZ, minDistanceIndex = SteeringFieldCourse.getClosestPositionSegment(segment, wx, wz)
        if minDistanceIndex > 0 then
            if minDistanceIndex == 1 then
                local x1 = segment.positions[1][1]
                local z1 = segment.positions[1][2]
                local segmentLength = MathUtil.vector2Length(segment.positions[2][1] - x1, segment.positions[2][2] - z1)
                distanceToEnd = MathUtil.vector2Length(minDistanceHitX - x1, minDistanceHitZ - z1)
                if numPositions == 2 and segmentLength * 0.5 < distanceToEnd then
                end
            elseif minDistanceIndex == numPositions - 1 then
                distanceToEnd = MathUtil.vector2Length(minDistanceHitX - segment.positions[numPositions][1], minDistanceHitZ - segment.positions[numPositions][2])
            end
            local x1, z1, x2 = SteeringFieldCourse.getClosestPositionSegment(segment, ox, oz)
            if x2 > 0 then
                local z2, segmentLength, tZ = worldToLocal(aiRootNode, x1, y, z1)
                return z2, tZ, distanceToEnd
            end
        end
        local x1 = segment.positions[1][1]
        local z1 = segment.positions[1][2]
        local x2 = segment.positions[2][1]
        local z2 = segment.positions[2][2]
        local segmentLength = segment.positions[numPositions][1]
        local tZ = segment.positions[numPositions][2]
        if MathUtil.vector2Length(x1 - ox, z1 - oz) < MathUtil.vector2Length(segmentLength - ox, tZ - oz) then
            local dirX, dirZ = MathUtil.vector2Normalize(x1 - x2, z1 - z2)
            local dot = MathUtil.getProjectOnLineParameter(ox, oz, x1, z1, dirX, dirZ)
            local tX, _, tZ = worldToLocal(aiRootNode, x1 + dirX * dot, y, z1 + dirZ * dot)
            return tX, tZ, distanceToEnd
        else
            local dirX, dirZ = MathUtil.vector2Normalize(segmentLength - segment.positions[numPositions - 1][1], tZ - segment.positions[numPositions - 1][2])
            local dot = MathUtil.getProjectOnLineParameter(ox, oz, segmentLength, tZ, dirX, dirZ)
            local tX, _, tZ = worldToLocal(aiRootNode, segmentLength + dirX * dot, y, tZ + dirZ * dot)
            return tX, tZ, distanceToEnd
        end
    end
end
function SteeringFieldCourse:draw()
    if self.fieldCourse.courseField ~= nil then
        self.fieldCourse.courseField:draw()
    end
    if self.fieldCourse.fieldCourseSettings ~= nil then
        self.fieldCourse.fieldCourseSettings:draw()
    end
end
function SteeringFieldCourse.registerXMLPaths(schema, path)
    FieldCourseSettings.registerXMLPaths(schema, path .. ".fieldCourseSettings")
    FieldCourseField.registerXMLPaths(schema, path .. ".field")
    schema:register(XMLValueType.STRING, path .. ".workedLines#indices", "List of worked line indices")
end