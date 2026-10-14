RollingGateAnimation = {}
local RollingGateAnimation_mt = Class(RollingGateAnimation)
function RollingGateAnimation.new(customMt)
    -- upvalues: (copy) RollingGateAnimation_mt
    local self = setmetatable({}, customMt or RollingGateAnimation_mt)
    self.state = 0
    return self
end
function RollingGateAnimation:load(xmlFile, key, rootNodes, i3dMapping)
    self.splineNode = xmlFile:getValue(key .. "#splineNode", nil, rootNodes, i3dMapping)
    if self.splineNode == nil then
        Logging.xmlWarning(xmlFile, "Missing splineNode for rolling gate animation \'%s\'!", key)
        return false
    end
    if not getHasClassId(getGeometry(self.splineNode), ClassIds.SPLINE) then
        Logging.xmlWarning(xmlFile, "Node \'%s\' is not a spline for rolling gate animation \'%s\'!", getName(self.splineNode), key)
        return false
    end
    setVisibility(self.splineNode, false)
    self.referenceFrame = xmlFile:getValue(key .. "#referenceFrame", nil, rootNodes, i3dMapping)
    if self.referenceFrame == nil then
        Logging.xmlWarning(xmlFile, "Missing referenceFrame for rolling gate animation \'%s\'!", key)
        return false
    end
    self.isInverted = xmlFile:getValue(key .. "#isInverted", false)
    self.maxOpeningDistance = xmlFile:getValue(key .. "#maxOpeningDistance")
    self.splineLength = getSplineLength(self.splineNode)
    self.segmentsByLength = {}
    local lastTime = nil
    local minTime = math.huge
    local maxTime = -math.huge
    local segments = {}
    for _, segmentKey in xmlFile:iterator(key .. ".segment") do
        local segment = {
            ["node"] = xmlFile:getValue(segmentKey .. "#node", nil, rootNodes, i3dMapping)
        }
        if segment.node ~= nil then
            segment.length = xmlFile:getValue(segmentKey .. "#length", 0.1)
            segment.lineAlignmentStartNode = xmlFile:getValue(segmentKey .. ".lineAlignment#startNode", nil, rootNodes, i3dMapping)
            segment.lineAlignmentEndNode = xmlFile:getValue(segmentKey .. ".lineAlignment#endNode", nil, rootNodes, i3dMapping)
            local splinePosition = self:getSplineTime(segment.node)
            if (lastTime or splinePosition) < splinePosition and #segments > 0 then
                table.insert(self.segmentsByLength, {
                    ["minTime"] = minTime,
                    ["maxTime"] = maxTime,
                    ["totalLength"] = maxTime - minTime + segments[#segments].length / self.splineLength,
                    ["segments"] = segments
                })
                segments = {}
                minTime = math.huge
                maxTime = -math.huge
            end
            local segmentData = segments[#segments]
            if segmentData ~= nil then
                segmentData.length = calcDistanceFrom(segmentData.node, segment.node)
            end
            table.insert(segments, segment)
            minTime = math.min(minTime, splinePosition)
            maxTime = math.max(maxTime, splinePosition)
        end
    end
    if #segments > 0 then
        table.insert(self.segmentsByLength, {
            ["minTime"] = minTime,
            ["maxTime"] = maxTime,
            ["totalLength"] = maxTime - minTime + segments[#segments].length / self.splineLength,
            ["segments"] = segments
        })
    end
    return true
end
function RollingGateAnimation:setState(state)
    state = math.clamp(state, 0, 1)
    for _, segmentData in ipairs(self.segmentsByLength) do
        local time
        if self.isInverted then
            time = segmentData.maxTime - state * (self.maxOpeningDistance or segmentData.totalLength)
        else
            time = segmentData.maxTime + state * (self.maxOpeningDistance or 1 - segmentData.maxTime)
        end
        for _, segment in pairs(segmentData.segments) do
            local _, _, _, nextTime = getSplinePositionWithDistance(self.splineNode, time, segment.length, false, 0.001)
            local nextTime = nextTime == time and 0 or nextTime
            local wx = math.max(time, 0.001)
            local wx, wy, wz = getSplinePosition(self.splineNode, wx)
            local lx, ly, lz = worldToLocal(getParent(segment.node), wx, wy, wz)
            setTranslation(segment.node, lx, ly, lz)
            if segment.lineAlignmentStartNode == nil or segment.lineAlignmentEndNode == nil then
                local _, ny, nz = getSplinePosition(self.splineNode, nextTime)
                local _ = _ - wx
                local sy = ny - wy
                local sz = nz - wz
                local _ = MathUtil.vector3Length(_, sy, sz)
                if _ > 0.001 then
                    local ey, ez, intersect = worldDirectionToLocal(getParent(segment.node), _, sy / (_ / _), sz / _)
                    local ey, ez, intersect = localDirectionToLocal(self.referenceFrame, getParent(segment.node), 0, 1, 0)
                    setDirection(segment.node, ey, ez, intersect, ey, ez, intersect)
                end
            else
                local _, ny, nz = getTranslation(segment.node)
                local _, sy, sz = localToLocal(segment.lineAlignmentStartNode, getParent(segment.node), 0, 0, 0)
                local _, ey, ez = localToLocal(segment.lineAlignmentEndNode, getParent(segment.node), 0, 0, 0)
                local intersect, iy, iz = MathUtil.getCircleLineIntersection(ny, nz, segment.length, sy, sz, ey, ez, false)
                if not intersect then
                    local normlineDirY, normlineDirZ = MathUtil.vector2Normalize(ey - sy, ez - sz)
                    iy, iz = MathUtil.projectOnLine(ny, nz, sy, sz, normlineDirY, normlineDirZ)
                end
                local normlineDirY = iy - ny
                local normlineDirZ = iz - nz
                local length = MathUtil.vector2Length(normlineDirY, normlineDirZ)
                if length > 0 then
                    local upX, upY, upZ = localDirectionToLocal(self.referenceFrame, getParent(segment.node), 0, 1, 0)
                    setDirection(segment.node, 0, normlineDirY / length, normlineDirZ / length, upX, upY, upZ)
                end
            end
            time = nextTime
        end
    end
    self.state = state
end
function RollingGateAnimation:getClosestSplineTime(startTime, endTime, resolution, x, y, z)
    local minDistance = math.huge
    local minDistanceTime = 0
    for startTime = startTime, endTime, resolution do
        local sx, sy, sz = getSplinePosition(self.splineNode, startTime)
        local distance = MathUtil.vector3Length(x - sx, y - sy, z - sz)
        if distance < minDistance then
            minDistanceTime = startTime
            minDistance = distance
        end
    end
    return minDistanceTime
end
function RollingGateAnimation:getSplineTime(node)
    local x, y, z = getWorldTranslation(node)
    local splineLength = getSplineLength(self.splineNode)
    local minDistanceTime1 = self:getClosestSplineTime(0, splineLength, 0.15 / splineLength, x, y, z)
    local minDistanceTime2 = self:getClosestSplineTime(math.max(minDistanceTime1 - 0.15, 0), math.min(minDistanceTime1 + 0.15, splineLength), 0.01 / splineLength, x, y, z)
    return self:getClosestSplineTime(math.max(minDistanceTime2 - 0.01, 0), math.min(minDistanceTime2 + 0.01, splineLength), 0.001 / splineLength, x, y, z)
end
function RollingGateAnimation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#splineNode", "Spline Node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#referenceFrame", "Reference Frame")
    schema:register(XMLValueType.BOOL, basePath .. "#isInverted", "Gate is inverted", false)
    schema:register(XMLValueType.FLOAT, basePath .. "#maxOpeningDistance", "Gate opening distance in spline time [0-1]", "automatically based on gate length, so it is fully open")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".segment(?)#node", "Node of the segment")
    schema:register(XMLValueType.FLOAT, basePath .. ".segment(?)#length", "Length of the segment")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".segment(?).lineAlignment#startNode", "Start node of the line to align to")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".segment(?).lineAlignment#endNode", "End node of the line to align to")
end