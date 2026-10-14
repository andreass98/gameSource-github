AIFieldCourseTurn = {}
local AIFieldCourseTurn_mt = Class(AIFieldCourseTurn)
function AIFieldCourseTurn.new(turnData, segments)
    -- upvalues: (copy) AIFieldCourseTurn_mt
    local self = setmetatable({}, AIFieldCourseTurn_mt)
    self.turnData = turnData
    self.segments = segments
    self.offset = 0
    self.cost = 1
    self.numNextSegmentIntersections = 0
    self.numBoundaryIntersections = 0
    self.length = 0
    self:updateLength()
    return self
end
function AIFieldCourseTurn:updateLength()
    self.length = 0
    for _, segment in ipairs(self.segments) do
        self.length = self.length + segment:getLength()
    end
end
function AIFieldCourseTurn:getPosition(alpha)
    local position = alpha * self.length
    local x = 0
    local z = 0
    local phi = 0
    for _, segment in ipairs(self.segments) do
        local delta = math.min(position, segment:getLength())
        x, z, phi = segment:move(x, z, phi, delta, self.turnData.turnRadius)
        position = position - delta
        if position <= 0 then
            break
        end
    end
    return self.turnData.sx + self.turnData.sDirX * x - self.turnData.sDirZ * z, self.turnData.sz + self.turnData.sDirZ * x + self.turnData.sDirX * z, phi
end
function AIFieldCourseTurn:iterate(distance, func, extraLength)
    if #self.segments ~= 0 then
        distance = distance / self.turnData.turnRadius
        if extraLength ~= nil then
        end
        local remainingLength = self.length
        local segmentIndex = 1
        local remainingSegmentLength = nil
        func(self.turnData.sx, self.turnData.sz, self.segments[1].drivingDirection)
        local x = 0
        local z = 0
        local phi = 0
        while remainingLength > 0 and self.segments[segmentIndex] ~= nil do
            local segment = self.segments[segmentIndex]
            if remainingSegmentLength == nil then
                remainingSegmentLength = segment:getLength()
            end
            local delta = math.min(distance, remainingLength, remainingSegmentLength)
            local wx, wz, startX = segment:move(x, z, phi, delta, self.turnData.turnRadius)
            func(self.turnData.sx + self.turnData.sDirX * wx - self.turnData.sDirZ * wz, self.turnData.sz + self.turnData.sDirZ * wx + self.turnData.sDirX * wz, segment.drivingDirection, false)
            remainingLength = remainingLength - delta
            remainingSegmentLength = math.min(remainingSegmentLength - delta, remainingLength)
            if remainingSegmentLength <= 0 then
                if extraLength == nil or extraLength <= 0 then
                    phi = startX
                    z = wz
                    x = wx
                else
                    phi = startX
                    z = wz
                    x = wx
                    for i = 0, extraLength, distance do
                        wx, wz, startX = segment:move(wx, wz, startX, math.min(distance, extraLength), self.turnData.turnRadius)
                        func(self.turnData.sx + self.turnData.sDirX * wx - self.turnData.sDirZ * wz, self.turnData.sz + self.turnData.sDirZ * wx + self.turnData.sDirX * wz, segment.drivingDirection, true)
                    end
                end
                remainingSegmentLength = nil
                segmentIndex = segmentIndex + 1
            else
                phi = startX
                z = wz
                x = wx
            end
        end
    end
end
function AIFieldCourseTurn:updateCost(allowProtectedBoundary, preferOneDrivingDirection)
    self.cost = 1
    self.numNextSegmentIntersections = 0
    self.numBoundaryIntersections = 0
    local fieldBoundaryLine = self.turnData.startOffset
    local hasDirectionChange = math.abs(fieldBoundaryLine)
    local checkIntersection = self.turnData.endOffset
    local offset = hasDirectionChange + math.abs(checkIntersection)
    if offset > 0 then
        self.cost = self.cost * (1 + offset / 10)
    end
    for _, segment in ipairs(self.segments) do
        if segment.drivingDirection < 0 then
            self.cost = self.cost * 1.1
        end
    end
    local hasDirectionChange = false
    local fieldBoundaryLine = #self.segments - 1
    local checkIntersection = 1
    for _ = 1, fieldBoundaryLine, checkIntersection do
        if self.segments[_].drivingDirection ~= self.segments[_ + 1].drivingDirection then
            hasDirectionChange = true
        end
    end
    if not hasDirectionChange then
        if preferOneDrivingDirection then
            self.cost = self.cost * 0.7
        else
            self.cost = self.cost * 0.9
        end
    end
    local fieldBoundaryLine = self.turnData.protectedBoundary.boundaryLine
    if allowProtectedBoundary then
        fieldBoundaryLine = self.turnData.fieldRootBoundary.boundaryLine
    end
    if not (FieldCourseUtil.getIsPointInsideBoundary(self.turnData.sx, self.turnData.sz, fieldBoundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(self.turnData.ex, self.turnData.ez, fieldBoundaryLine)) then
        self.cost = self.cost * 2
        self.numBoundaryIntersections = self.numBoundaryIntersections + 2
    end
    for _, island in ipairs(self.turnData.islands) do
        local boundary = island.protectedBoundary
        if allowProtectedBoundary then
            boundary = island.rootBoundary
        end
        if FieldCourseUtil.getIsPointInsideBoundary(self.turnData.sx, self.turnData.sz, boundary.boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(self.turnData.ex, self.turnData.ez, boundary.boundaryLine) then
            self.cost = self.cost * 2
            self.numBoundaryIntersections = self.numBoundaryIntersections + 2
        end
    end
    local function checkIntersection(x1, z1, x2, z2)
        -- upvalues: (copy) self, (ref) fieldBoundaryLine, (copy) allowProtectedBoundary
        if self.turnData.segment2 ~= nil then
            local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, self.turnData.segment2.positions)
            if intersect then
                self.cost = self.cost * 1.25
                self.numNextSegmentIntersections = self.numNextSegmentIntersections + 1
            end
        end
        local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, fieldBoundaryLine)
        if intersect then
            self.cost = self.cost * 2
            self.numBoundaryIntersections = self.numBoundaryIntersections + 1
        end
        for _, island in ipairs(self.turnData.islands) do
            local boundary = island.protectedBoundary
            if allowProtectedBoundary then
                boundary = island.rootBoundary
            end
            local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, boundary.boundaryLine)
            if intersect then
                self.cost = self.cost * 2
                self.numBoundaryIntersections = self.numBoundaryIntersections + 1
            end
        end
        return self.numBoundaryIntersections == 0
    end
    local _ = 1
    local segment = nil
    local boundary = 0
    local lz = 0
    local lastX = self.turnData.sx
    local lastZ = self.turnData.sz
    if self.turnData.startOffset < 0 then
        if not checkIntersection(self.turnData.originalTurnData.sx, self.turnData.originalTurnData.sz, self.turnData.sx, self.turnData.sz) then
            return
        end
    elseif self.turnData.startOffset > 0 then
        local x1 = self.turnData.originalTurnData.sx
        local z1 = self.turnData.originalTurnData.sz
        local x2 = self.turnData.sx
        local z2 = self.turnData.sz
        local rootIntersections = FieldCourseUtil.getSegmentNumBoundaryIntersections(x1, z1, x2, z2, fieldBoundaryLine)
        if rootIntersections > 1 then
            self.numBoundaryIntersections = 1
            return
        end
        for _, island in ipairs(self.turnData.islands) do
            local boundary = island.protectedBoundary
            if allowProtectedBoundary then
                boundary = island.rootBoundary
            end
            if rootIntersections + FieldCourseUtil.getSegmentNumBoundaryIntersections(x1, z1, x2, z2, boundary.boundaryLine) > 1 then
                self.numBoundaryIntersections = 1
                return
            end
        end
    end
    ::l30::
    local x1 = self.segments[_]
    while x1 ~= nil and x1.distance <= 1e-6 do
        _ = _ + 1
        x1 = self.segments[_]
    end
    if x1 == nil then
        if self.turnData.endOffset < 0 then
            checkIntersection(self.turnData.originalTurnData.ex, self.turnData.originalTurnData.ez, self.turnData.ex, self.turnData.ez)
        end
        return
    end
    if segment == nil then
        segment = x1.distance
    end
    local z1 = math.min(1, segment)
    if x1.segmentType == AIFieldCourseTurnSegmentType.STRAIGHT then
        z1 = x1.distance
    end
    boundary, lz, phi = x1:move(boundary, lz, 0, z1, self.turnData.turnRadius)
    segment = segment - z1
    if segment <= 0 then
        segment = nil
    end
    local _ = self.turnData.sx + self.turnData.sDirX * boundary - self.turnData.sDirZ * lz
    local island = self.turnData.sz + self.turnData.sDirZ * boundary + self.turnData.sDirX * lz
    if not checkIntersection(lastX, lastZ, _, island) then
        return
    end
    lastX = _
    lastZ = island
    goto l30
end
function AIFieldCourseTurn:getOverallCost()
    local backwardLength = 0
    for _, segment in ipairs(self.segments) do
        if segment.drivingDirection < 0 then
        end
    end
    return (self.length - backwardLength) * self.cost + backwardLength * self.cost * 1.15
end
function AIFieldCourseTurn:draw(r, g, b)
    if self.length > 0 then
        local x = self.turnData.sx
        local z = self.turnData.sz
        local step = self.length / (1 / self.turnData.turnRadius)
        local steps = math.ceil(step)
        local step = self.length / steps
        local _ = step
        for step = step, self.length + 0.01, step do
            local lastY = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.5
            local alpha = step / self.length
            local y, sr, sg = self:getPosition(alpha)
            local y = getTerrainHeightAtWorldPos(g_terrainNode, y, 0, sr) + 0.5
            local sr = r or alpha
            local sg = g or 1 - alpha
            local sb = b or 0
            drawDebugLine(x, lastY, z, sr, sg, sb, y, y, sr, sr, sg, sb, true)
            z = sr
            x = y
        end
    end
end