AIFieldCourseSegment = {}
local AIFieldCourseSegment_mt = Class(AIFieldCourseSegment)
function AIFieldCourseSegment.new(fieldCourseSettings)
    -- upvalues: (copy) AIFieldCourseSegment_mt
    local self = setmetatable({}, AIFieldCourseSegment_mt)
    self.positions = {}
    self.length = 0
    self.posIndex = 1
    self.isTurn = false
    self.isActualLine = nil
    self.isInitialLine = nil
    self.isCornerCutOut = false
    self.isHeadlandSegment = false
    self.isIslandSegment = false
    self.sideOffset = 0
    self.segmentId = nil
    self.segmentIsReady = false
    self.fieldCourseSettings = fieldCourseSettings
    return self
end
function AIFieldCourseSegment:isValid()
    return #self.positions > 0 and self.posIndex < #self.positions
end
function AIFieldCourseSegment:isReady()
    return self.segmentIsReady
end
function AIFieldCourseSegment:clone()
    local segment = AIFieldCourseSegment.new()
    segment.positions = table.clone(self.positions, 5)
    segment.length = self.length
    segment.segmentIsReady = self.segmentIsReady
    segment.isTurn = self.isTurn
    segment.isActualLine = self.isActualLine
    segment.isInitialLine = self.isInitialLine
    segment.isCornerCutOut = self.isCornerCutOut
    segment.turn = self.turn
    segment.isHeadlandSegment = self.isHeadlandSegment
    segment.isIslandSegment = self.isIslandSegment
    segment.sideOffset = self.sideOffset
    segment.segmentId = self.segmentId
    return segment
end
function AIFieldCourseSegment:reset()
    for i, _ in ipairs(self.positions) do
        self.positions[i] = nil
    end
    self.length = 0
    self.posIndex = 1
    self.isTurn = false
    self.isActualLine = nil
    self.isInitialLine = nil
    self.isCornerCutOut = false
    self.turn = nil
    self.isHeadlandSegment = false
    self.isIslandSegment = false
    self.sideOffset = 0
    self.segmentId = nil
end
function AIFieldCourseSegment:setSegment(segment, direction, lastTurn, nextTurn)
    self.segmentIsReady = false
    if direction == 1 then
        self.positions = table.clone(segment.positions, 5)
    else
        self.positions = {}
        local i = #segment.positions
        for i = i, 1, -1 do
            table.insert(self.positions, table.clone(segment.positions[i], 5))
        end
    end
    if not (self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing) then
        if lastTurn ~= nil then
            FieldCourseUtil.extendSegment(self.positions, -1, -lastTurn.turnData.endOffset)
        end
        if nextTurn ~= nil then
            FieldCourseUtil.extendSegment(self.positions, 1, -nextTurn.turnData.startOffset)
        end
    end
    self.posIndex = 1
    self.isTurn = false
    self.turn = nil
    self.isHeadlandSegment = segment.isHeadlandSegment
    self.isIslandSegment = segment.isIslandSegment
    self.sideOffset = segment.sideOffset or 0
    self.segmentId = segment.segmentId
    self.isActualLine = nil
    if segment.isActualLine ~= nil then
        self.isActualLine = segment.isActualLine
    end
    self.isInitialLine = segment.isInitialLine
    self.isCornerCutOut = Utils.getNoNil(segment.isCornerCutOut, false)
    self.length = FieldCourseUtil.getSegmentLength(self.positions)
    self.segmentIsReady = true
end
function AIFieldCourseSegment:overlapCallback(nodeId, _)
    if nodeId == 0 then
        self.segmentToValidate = nil
        self.segmentIsReady = true
        if self.segmentToValidate.numOverlapChecks > 1 then
            local pos = self.positions[segmentToValidate.posIndex]
            pos[1] = pos[1] + segmentToValidate.dir[1] * segmentToValidate.offset
            pos[2] = pos[2] + segmentToValidate.dir[2] * segmentToValidate.offset
        end
    else
        local bx = segmentToValidate.length - 2
        segmentToValidate.length = math.max(bx, 0)
        if segmentToValidate.length > 0 then
            segmentToValidate.numOverlapChecks = segmentToValidate.numOverlapChecks + 1
            segmentToValidate.offset = segmentToValidate.offset - 2
            local pos = segmentToValidate.length
            local bx = segmentToValidate.s[1] + segmentToValidate.dir[1] * (pos * 0.5)
            local bz = segmentToValidate.s[2] + segmentToValidate.dir[2] * (pos * 0.5)
            local sx = MathUtil.getYRotationFromDirection(segmentToValidate.dir[1], segmentToValidate.dir[2])
            local sy = self.fieldCourseSettings.agentHeight + 0.5
            local by = getTerrainHeightAtWorldPos(g_terrainNode, bx, 0, bz) + sy * 0.5
            overlapBoxAsync(bx, by, bz, 0, self.fieldCourseSettings.implementWidth + 0.5, 0, sx * 0.5, sy * 0.5, pos * 0.5, "overlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
        else
            table.remove(self.positions, segmentToValidate.posIndex)
            table.remove(self.positions, segmentToValidate.posIndex)
            self.segmentToValidate = nil
            self.segmentIsReady = true
        end
    end
    return false
end
function AIFieldCourseSegment:setTurn(turn, addStraighteningSegment)
    self.segmentIsReady = false
    self.positions = {}
    if self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing then
        local originalTurnData = turn.turnData.originalTurnData
        if originalTurnData ~= nil and turn.turnData.startOffset ~= 0 then
            table.insert(self.positions, { originalTurnData.sx, originalTurnData.sz, 1 })
            __set_list(dirX, 1, {turn.turnData.sx, turn.turnData.sz, -math.sign(turn.turnData.startOffset)})
            table.insert(self.positions, dirX)
        end
    end
    local originalTurnData = nil
    local lastZ = nil
    local numPositions = #self.positions
    if numPositions > 0 then
        originalTurnData = self.positions[numPositions][1]
        lastZ = self.positions[numPositions][2]
    end
    turn:iterate(1, function(x, z, direction, shadowPosition)
        -- upvalues: (ref) originalTurnData, (ref) lastZ, (copy) self
        if x ~= originalTurnData or z ~= lastZ then
            if shadowPosition then
                if #self.positions > 0 then
                    local lastPosition = self.positions[#self.positions]
                    if lastPosition.shadowPositions == nil then
                        lastPosition.shadowPositions = {}
                    end
                    table.insert(lastPosition.shadowPositions, { x, z })
                    return
                end
            else
                table.insert(self.positions, { x, z, direction })
                originalTurnData = x
                lastZ = z
            end
        end
    end, 3)
    if self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing then
        if (not self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.toolStraighteningAlwaysActive) and addStraighteningSegment ~= false then
            local lastPos = self.fieldCourseSettings.toolStraighteningSegmentLength
            local z = self.fieldCourseSettings.toolBackOffset
            local segmentLength = lastPos * math.sign(z)
            local lastPos = self.positions[#self.positions]
            local x = lastPos[1] - turn.turnData.eDirX * segmentLength
            local z = lastPos[2] - turn.turnData.eDirZ * segmentLength
            if self.fieldCourseSettings.toolBackOffset < 0 and not FieldCourseUtil.getIsPointInsideBoundary(x, z, turn.turnData.protectedBoundary.boundaryLine) then
                local boxLength = math.abs(segmentLength) + self.fieldCourseSettings.agentFrontOffset
                local bx = lastPos[1] + dirX * (boxLength * 0.5)
                local bz = lastPos[2] + dirZ * (boxLength * 0.5)
                local sx = MathUtil.getYRotationFromDirection(dirX, dirZ)
                local sy = self.fieldCourseSettings.agentHeight + 0.5
                local by = getTerrainHeightAtWorldPos(g_terrainNode, bx, 0, bz) + sy * 0.5
                overlapBoxAsync(bx, by, bz, 0, self.fieldCourseSettings.implementWidth + 0.5, 0, sx * 0.5, sy * 0.5, boxLength * 0.5, "overlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
                self.segmentToValidate = {
                    ["s"] = { lastPos[1], lastPos[2] },
                    ["e"] = { x, z },
                    ["dir"] = { dirX, dirZ },
                    ["length"] = boxLength,
                    ["offset"] = 0,
                    ["numOverlapChecks"] = 1,
                    ["posIndex"] = #self.positions + 1
                }
            end
            local boxLength = math.sign(segmentLength)
            local bz = self.positions
            table.insert(bz, {
                x,
                z,
                -boxLength,
                true
            })
            local bz = self.positions
            table.insert(bz, { lastPos[1], lastPos[2], boxLength })
        end
        local segmentLength = turn.turnData.originalTurnData
        if segmentLength ~= nil and turn.turnData.endOffset ~= 0 then
            local z = {}
            __set_list(z, 1, {segmentLength.ex, segmentLength.ez, -math.sign(turn.turnData.endOffset)})
            table.insert(self.positions, z)
        end
    end
    self.posIndex = 1
    self.isTurn = true
    self.turn = turn
    self.isHeadlandSegment = false
    self.isIslandSegment = false
    self.sideOffset = 0
    if turn.turnData.segment2 ~= nil then
        self.sideOffset = turn.turnData.segment2.sideOffset or 0
    end
    self.isActualLine = nil
    if turn.isActualLine ~= nil then
        self.isActualLine = turn.isActualLine
    end
    self.isInitialLine = turn.isInitialLine
    self.isCornerCutOut = Utils.getNoNil(turn.isCornerCutOut, false)
    self.length = FieldCourseUtil.getSegmentLength(self.positions)
    local dirX = self.segmentToValidate ~= nil
    self.segmentIsReady = dirX
end
function AIFieldCourseSegment:setPositions(positions)
    self.positions = positions
    self.posIndex = 1
    self.isTurn = false
    self.turn = nil
    self.isHeadlandSegment = false
    self.isIslandSegment = false
    self.length = FieldCourseUtil.getSegmentLength(self.positions)
end
function AIFieldCourseSegment:getIsOnActualLine()
    if self.isActualLine ~= nil then
        return self.isActualLine
    end
    if self.isTurn then
        return false
    end
    local pos = self.positions[self.posIndex]
    return pos == nil or pos[3] ~= -1
end
function AIFieldCourseSegment:getDriveData(dt, vX, vY, vZ, vSpeed, steeringOffset, toolReverserDirectionNode)
    local i = self.posIndex
    for i = i, #self.positions - 1 do
        local pos1 = self.positions[i]
        local pos2 = self.positions[i + 1]
        local dirX = pos2[1] - pos1[1]
        local dirZ = pos2[2] - pos1[2]
        local length = MathUtil.vector2Length(dirX, dirZ)
        if length > 0 then
            local dot = MathUtil.getProjectOnLineParameter(vX, vZ, pos1[1], pos1[2], dirX / length, dirZ / length)
            if dot <= length then
                if self.posIndex < i then
                    self.posIndex = i
                end
                local _ = dot + steeringOffset
                local tx, tz = self:getPositionOffset(i, (math.max(_, 0)))
                local direction = pos2[3] or 1
                if direction < 0 and toolReverserDirectionNode ~= nil then
                    local rx, _, rz = getWorldTranslation(toolReverserDirectionNode)
                    tx, tz = self:getPositionOffset(i, (math.max(dot + (MathUtil.vector2Length(rx - vX, rz - vZ) + 2.5), 0)))
                end
                if pos2[4] ~= true or toolReverserDirectionNode == nil then
                    ::l12::
                    local rx, _ = self:getSubSegmentPosition(i, dot)
                    return tx, tz, direction, self:getSegmentPosition(i, dot), self.length, rx, _
                end
                local rx, _, rz = getWorldTranslation(toolReverserDirectionNode)
                if FieldCourseUtil.getDistanceToSegment(pos1[1], pos1[2], pos2[1], pos2[2], rx, rz) >= 0.5 then
                    goto l12
                end
            end
        end
    end
    self.posIndex = self.posIndex + 1
    if self.posIndex > #self.positions - 1 then
        return nil, nil
    else
        return self:getDriveData(dt, vX, vY, vZ, vSpeed, steeringOffset, toolReverserDirectionNode)
    end
end
function AIFieldCourseSegment:skipCurrentSubSegment(maxDistance)
    local distance = 0
    local i = self.posIndex + 1
    for i = i, #self.positions - 1 do
        local pos1 = self.positions[i - 1]
        if pos1 ~= nil then
            distance = distance + MathUtil.vector2Length(self.positions[i][1] - pos1[1], self.positions[i][2] - pos1[2])
        end
        if maxDistance < distance then
            return
        end
        if self.positions[i][3] ~= self.positions[self.posIndex][3] then
            self.posIndex = i
            return
        end
    end
    self.posIndex = #self.positions
end
function AIFieldCourseSegment:getPositionOffset(index, pos)
    local numPositions = #self.positions
    for index = index, numPositions - 1 do
        local pos1 = self.positions[index]
        local pos2 = self.positions[index + 1]
        local dirX = pos2[1] - pos1[1]
        local dirZ = pos2[2] - pos1[2]
        local length = MathUtil.vector2Length(dirX, dirZ)
        if length ~= 0 then
            local dirX = dirX / length
            local dirZ = dirZ / length
            local nextSegmentHasSameDirection = true
            local nextSegment = self.positions[index + 2]
            if nextSegment ~= nil then
                nextSegmentHasSameDirection = (nextSegment[3] or 1) == (pos2[3] or 1)
            end
            if pos < length or (index == numPositions - 1 or not nextSegmentHasSameDirection) then
                if length < pos and pos2.shadowPositions ~= nil then
                    for shadowPosIndex, shadowPos in ipairs(pos2.shadowPositions) do
                        local dirX = shadowPos[1] - pos2[1]
                        local dirZ = shadowPos[2] - pos2[2]
                        local shadowLength = MathUtil.vector2Length(dirX, dirZ)
                        if shadowLength == 0 then
                            return nil
                        end
                        local dirX = dirX / shadowLength
                        local dirZ = dirZ / shadowLength
                        if pos < shadowLength or shadowPosIndex == #pos2.shadowPositions then
                            return pos2[1] + dirX * pos, pos2[2] + dirZ * pos
                        end
                        pos = pos - shadowLength
                        pos2 = shadowPos
                    end
                end
                return pos1[1] + dirX * pos, pos1[2] + dirZ * pos
            end
            pos = pos - length
        end
    end
    return nil
end
function AIFieldCourseSegment:getSegmentPosition(index, dot)
    local position = 0
    local i = 1
    for i = i, #self.positions - 1 do
        local length = MathUtil.vector2Length(self.positions[i + 1][1] - self.positions[i][1], self.positions[i + 1][2] - self.positions[i][2])
        if i == index then
            position = position + math.clamp(dot, 0, length)
            break
        end
        position = position + length
    end
    return position / self.length
end
function AIFieldCourseSegment:getSubSegmentPosition(index, dot)
    local prevLength = 0
    local i = index - 1
    local nextLength = 1
    local x1 = -1
    for i = i, nextLength, x1 do
        if (self.positions[i][3] or 1) ~= (self.positions[index][3] or 1) then
            break
        end
        prevLength = prevLength + MathUtil.vector2Length(self.positions[i + 1][1] - self.positions[i][1], self.positions[i + 1][2] - self.positions[i][2])
    end
    local nextLength = 0
    local x1 = #self.positions - 1
    local i = 1
    for index = index, x1, i do
        if (self.positions[index][3] or 1) ~= direction then
            break
        end
        nextLength = nextLength + MathUtil.vector2Length(self.positions[index + 1][1] - self.positions[index][1], self.positions[index + 1][2] - self.positions[index][2])
    end
    local x1 = self.positions[index][1]
    local i = self.positions[index][2]
    local x1 = self.positions[index + 1][1]
    local z1 = self.positions[index + 1][2]
    local x2 = math.clamp(dot, 0, (MathUtil.vector2Length(x1 - x1, z1 - i)))
    local x2 = prevLength + nextLength
    return (prevLength + x2) / x2, x2
end
function AIFieldCourseSegment:getSignedOffsetToSegment(x, z)
    local minDistance = math.huge
    local signedDistance = 0
    local i = 1
    for i = i, #self.positions - 1 do
        local x1 = self.positions[i][1]
        local z1 = self.positions[i][2]
        local dirX = self.positions[i + 1][1] - x1
        local dirZ = self.positions[i + 1][2] - z1
        local length = MathUtil.vector2Length(dirX, dirZ)
        if length > 0 then
            local dirX = dirX / length
            local dirZ = dirZ / length
            local dot = MathUtil.getProjectOnLineParameter(x, z, x1, z1, dirX, dirZ)
            if dot > 0 and dot <= length then
                local lx = x1 + dirX * dot
                local lz = z1 + dirZ * dot
                local distance = MathUtil.vector2Length(x - lx, z - lz)
                if distance > 0 and distance < minDistance then
                    local odx, odz = MathUtil.vector2Normalize(x - lx, z - lz)
                    local sideDot = MathUtil.dotProduct(dirZ, 0, -dirX, odx, 0, odz)
                    signedDistance = distance * math.sign(sideDot)
                    minDistance = distance
                end
            end
        end
    end
    return signedDistance
end
function AIFieldCourseSegment:getPosition(alpha)
    local distance = 0
    local numPositions = #self.positions
    local i = 1
    for i = i, numPositions - 1 do
        local x1 = self.positions[i][1]
        local z1 = self.positions[i][2]
        local x2 = self.positions[i + 1][1]
        local z2 = self.positions[i + 1][2]
        local length = MathUtil.vector2Length(x2 - x1, z2 - z1)
        if distance + length > alpha * self.length then
            local segmentAlpha = (alpha * self.length - distance) / length
            return MathUtil.lerp(x1, x2, segmentAlpha), MathUtil.lerp(z1, z2, segmentAlpha)
        end
        distance = distance + length
    end
    return self.positions[numPositions][1], self.positions[numPositions][2]
end
function AIFieldCourseSegment:draw(r, g, b, subSegmentIndex, indexToDraw)
    AIFieldCourseUtil.drawPath(self.positions, r, g, b, subSegmentIndex, indexToDraw)
    for _, position in ipairs(self.positions) do
        if position.shadowPositions ~= nil then
            local lastX = position[1]
            local lastZ = position[2]
            for _, shadowPosition in ipairs(position.shadowPositions) do
                local y1 = getTerrainHeightAtWorldPos(g_terrainNode, lastX, 0, lastZ) + 0.25
                local y2 = getTerrainHeightAtWorldPos(g_terrainNode, shadowPosition[1], 0, shadowPosition[2]) + 0.25
                drawDebugLine(lastX, y1, lastZ, 0.15, 0.15, 0.15, shadowPosition[1], y2, shadowPosition[2], 0.15, 0.15, 0.15, false)
                lastX = shadowPosition[1]
                lastZ = shadowPosition[2]
            end
        end
    end
end
function AIFieldCourseSegment:drawToolPreview(implementWidth, toolFrontOffset, toolBackOffset)
    local i = 1
    for i = i, #self.positions do
        local p1 = self.positions[i - 1]
        local p2 = self.positions[i]
        if p1 == nil then
            p1 = self.positions[i]
            p2 = self.positions[i + 1]
        end
        local dx, dz = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
        local p = self.positions[i]
        local direction = self.positions[i][3] or 1
        local x1 = p[1] + dz * (implementWidth * 0.5) + dx * toolFrontOffset * direction
        local z1 = p[2] - dx * halfWidth + dz * toolFrontOffset * direction
        local x2 = p[1] - dz * halfWidth + dx * toolFrontOffset * direction
        local z2 = p[2] + dx * halfWidth + dz * toolFrontOffset * direction
        local x3 = p[1] + dz * halfWidth + dx * toolBackOffset * direction
        local z3 = p[2] - dx * halfWidth + dz * toolBackOffset * direction
        local x4 = p[1] - dz * halfWidth + dx * toolBackOffset * direction
        local z4 = p[2] + dx * halfWidth + dz * toolBackOffset * direction
        local y = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + 0.5
        local y = math.max(y, getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + 0.5)
        local y = math.max(y, getTerrainHeightAtWorldPos(g_terrainNode, x3, 0, z3) + 0.5)
        local y = math.max(y, getTerrainHeightAtWorldPos(g_terrainNode, x4, 0, z4) + 0.5)
        drawDebugTriangle(x1, y, z1, x3, y, z3, x2, y, z2, 0, 1, 0, 0.2, true)
        drawDebugTriangle(x4, y, z4, x2, y, z2, x3, y, z3, 0, 1, 0, 0.2, true)
    end
end