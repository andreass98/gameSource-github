ReedsSheppPath = {}
local ReedsSheppPath_mt = Class(ReedsSheppPath)
function ReedsSheppPath.new(turnData, forcedDirection)
    -- upvalues: (copy) ReedsSheppPath_mt
    local self = setmetatable({}, ReedsSheppPath_mt)
    self.turnData = turnData
    self.forcedDirection = forcedDirection or 0
    self.sAngle = MathUtil.getYRotationFromDirection(turnData.sDirX, turnData.sDirZ)
    self.eAngle = MathUtil.getYRotationFromDirection(turnData.eDirX, turnData.eDirZ)
    self.helperTransformGroup = createTransformGroup("helper")
    link(getRootNode(), self.helperTransformGroup)
    setTranslation(self.helperTransformGroup, turnData.sx, 0, turnData.sz)
    setDirection(self.helperTransformGroup, turnData.sDirX, 0, turnData.sDirZ, 0, 1, 0)
    local z, _, x = worldToLocal(self.helperTransformGroup, turnData.ex, 0, turnData.ez)
    local dx, _, dz = worldDirectionToLocal(self.helperTransformGroup, turnData.eDirX, 0, turnData.eDirZ)
    self.phi = MathUtil.getYRotationFromDirection(dx, dz)
    self.z = z / turnData.turnRadius
    self.x = x / turnData.turnRadius
    delete(self.helperTransformGroup)
    return self
end
function ReedsSheppPath:generate(callback)
    if self.forcedDirection == 0 then
        for _, func in pairs(ReedsSheppPath.PATH_FUNCTIONS) do
            local segments = func(self.x, self.z, self.phi)
            if segments ~= nil then
                callback(AIFieldCourseTurn.new(self.turnData, segments))
            end
            local segments = func(-self.x, self.z, -self.phi)
            if segments ~= nil then
                callback(AIFieldCourseTurn.new(self.turnData, self:inverseDirection(segments)))
            end
            local segments = func(self.x, -self.z, -self.phi)
            if segments ~= nil then
                callback(AIFieldCourseTurn.new(self.turnData, self:inverseSteering(segments)))
            end
            local segments = func(-self.x, -self.z, self.phi)
            if segments ~= nil then
                callback(AIFieldCourseTurn.new(self.turnData, self:inverse(segments)))
            end
        end
    else
        for _, func in pairs(ReedsSheppPath.FORWARD_FUNCTIONS) do
            if self.forcedDirection == 1 then
                local segments = func(self.x, self.z, self.phi)
                if segments ~= nil then
                    callback(AIFieldCourseTurn.new(self.turnData, segments))
                end
            else
                local segments = func(-self.x, -self.z, self.phi)
                if segments ~= nil then
                    callback(AIFieldCourseTurn.new(self.turnData, self:inverse(segments)))
                end
            end
        end
    end
end
function ReedsSheppPath.inverseSteering(_, segments)
    for _, segment in ipairs(segments) do
        segment:inverseSteering()
    end
    return segments
end
function ReedsSheppPath.inverseDirection(_, segments)
    for _, segment in ipairs(segments) do
        segment:inverseDirection()
    end
    return segments
end
function ReedsSheppPath.inverse(_, segments)
    for _, segment in ipairs(segments) do
        segment:inverseSteering()
        segment:inverseDirection()
    end
    return segments
end
ReedsSheppPath.PATH_FUNCTIONS = {}
ReedsSheppPath.PATH_FUNCTIONS[1] = function(x, z, phi)
    local segments = {}
    local dx = x - math.sin(phi)
    local dz = z - 1 + math.cos(phi)
    local length = MathUtil.vector2Length(dx, dz)
    local dz = (phi - MathUtil.getYRotationFromDirection(dz, dx)) % 6.283185307179586
    if dz < -3.141592653589793 then
    elseif dz > 3.141592653589793 then
    end
    table.insert(segments, AIFieldCourseTurnSegment.new(yRot, AIFieldCourseTurnSegmentType.LEFT, 1))
    table.insert(segments, AIFieldCourseTurnSegment.new(length, AIFieldCourseTurnSegmentType.STRAIGHT, 1))
    table.insert(segments, AIFieldCourseTurnSegment.new(dz, AIFieldCourseTurnSegmentType.LEFT, 1))
    return segments
end
ReedsSheppPath.PATH_FUNCTIONS[2] = function(x, z, phi)
    local r = phi % 6.283185307179586
    if r < -3.141592653589793 then
    elseif r > 3.141592653589793 then
    end
    local dx = x + math.sin(r)
    local length = MathUtil.vector2Length(dx, z - 1 - math.cos(r))
    local yRot = MathUtil.getYRotationFromDirection(dz, dx)
    local r = length * length
    if r < 4 then
        return nil
    end
    local dx = math.sqrt(r - 4)
    local yRot = (yRot + math.atan2(2, dx)) % 6.283185307179586
    if yRot < -3.141592653589793 then
    elseif yRot > 3.141592653589793 then
    end
    local r = (yRot - r) % 6.283185307179586
    if r < -3.141592653589793 then
    elseif r > 3.141592653589793 then
    end
    local r = {}
    table.insert(r, AIFieldCourseTurnSegment.new(yRot, AIFieldCourseTurnSegmentType.LEFT, 1))
    table.insert(r, AIFieldCourseTurnSegment.new(dx, AIFieldCourseTurnSegmentType.STRAIGHT, 1))
    table.insert(r, AIFieldCourseTurnSegment.new(r, AIFieldCourseTurnSegmentType.RIGHT, 1))
    return r
end
ReedsSheppPath.PATH_FUNCTIONS[3] = function(x, y, phi)
    local dx = x - math.sin(phi)
    local length = MathUtil.vector2Length(dx, y - 1 + math.cos(phi))
    local yRot = MathUtil.getYRotationFromDirection(dz, dx)
    if length > 4 then
        return nil
    end
    local dx = math.acos(length / 4)
    local length = (yRot + 1.5707963267948966 + dx) % 6.283185307179586
    if length < -3.141592653589793 then
    elseif length > 3.141592653589793 then
    end
    local yRot = (3.141592653589793 - 2 * dx) % 6.283185307179586
    if yRot < -3.141592653589793 then
    elseif yRot > 3.141592653589793 then
    end
    local r = (phi - length - yRot) % 6.283185307179586
    if r < -3.141592653589793 then
    elseif r > 3.141592653589793 then
    end
    local r = {}
    table.insert(r, AIFieldCourseTurnSegment.new(length, AIFieldCourseTurnSegmentType.LEFT, 1))
    table.insert(r, AIFieldCourseTurnSegment.new(yRot, AIFieldCourseTurnSegmentType.RIGHT, -1))
    table.insert(r, AIFieldCourseTurnSegment.new(r, AIFieldCourseTurnSegmentType.LEFT, 1))
    return r
end
ReedsSheppPath.PATH_FUNCTIONS[4] = function(x, y, phi)
    local dx = x - math.sin(phi)
    local length = MathUtil.vector2Length(dx, y - 1 + math.cos(phi))
    local yRot = MathUtil.getYRotationFromDirection(dz, dx)
    if length > 4 then
        return nil
    end
    local dx = math.acos(length / 4)
    local length = (yRot + 1.5707963267948966 + dx) % 6.283185307179586
    if length < -3.141592653589793 then
    elseif length > 3.141592653589793 then
    end
    local yRot = (3.141592653589793 - 2 * dx) % 6.283185307179586
    if yRot < -3.141592653589793 then
    elseif yRot > 3.141592653589793 then
    end
    local r = (length + yRot - phi) % 6.283185307179586
    if r < -3.141592653589793 then
    elseif r > 3.141592653589793 then
    end
    local r = {}
    table.insert(r, AIFieldCourseTurnSegment.new(length, AIFieldCourseTurnSegmentType.LEFT, 1))
    table.insert(r, AIFieldCourseTurnSegment.new(yRot, AIFieldCourseTurnSegmentType.RIGHT, -1))
    table.insert(r, AIFieldCourseTurnSegment.new(r, AIFieldCourseTurnSegmentType.LEFT, -1))
    return r
end
ReedsSheppPath.PATH_FUNCTIONS[5] = function(x, y, phi)
    local dx = x - math.sin(phi)
    local length = MathUtil.vector2Length(dx, y - 1 + math.cos(phi))
    local yRot = MathUtil.getYRotationFromDirection(dz, dx)
    if length <= 0 or length > 4 then
        return nil
    end
    local dx = math.acos(1 - length * length / 8)
    local yRot = 2 * math.sin(dx) / length
    local length = math.clamp(yRot, -1, 1)
    local yRot = (yRot + 1.5707963267948966 - math.asin(length)) % 6.283185307179586
    if yRot < -3.141592653589793 then
    elseif yRot > 3.141592653589793 then
    end
    local r = (yRot - dx - phi) % 6.283185307179586
    if r < -3.141592653589793 then
    elseif r > 3.141592653589793 then
    end
    local r = {}
    table.insert(r, AIFieldCourseTurnSegment.new(yRot, AIFieldCourseTurnSegmentType.LEFT, 1))
    table.insert(r, AIFieldCourseTurnSegment.new(dx, AIFieldCourseTurnSegmentType.RIGHT, 1))
    table.insert(r, AIFieldCourseTurnSegment.new(r, AIFieldCourseTurnSegmentType.LEFT, -1))
    return r
end
ReedsSheppPath.PATH_FUNCTIONS[6] = function(x, y, phi)
    local dx = x + math.sin(phi)
    local dz = y - 1 - math.cos(phi)
    local length = MathUtil.vector2Length(dx, dz)
    local yRot = MathUtil.getYRotationFromDirection(dz, dx)
    if length > 4 then
        return nil
    end
    local r, r, r
    if length <= 2 then
        local r = (length + 2) / 4
        local yRot = math.acos(r)
        r = (yRot + 1.5707963267948966 + yRot) % 6.283185307179586
        if r < -3.141592653589793 then
        elseif r > 3.141592653589793 then
        end
        r = yRot % 6.283185307179586
        if r < -3.141592653589793 then
        elseif r > 3.141592653589793 then
        end
        r = (phi - r + 2 * r) % 6.283185307179586
        if r < -3.141592653589793 then
        elseif r > 3.141592653589793 then
        end
    else
        local r = (length - 2) / 4
        local yRot = math.acos(r)
        r = (yRot + 1.5707963267948966 - yRot) % 6.283185307179586
        if r < -3.141592653589793 then
        elseif r > 3.141592653589793 then
        end
        r = (3.141592653589793 - yRot) % 6.283185307179586
        if r < -3.141592653589793 then
        elseif r > 3.141592653589793 then
        end
        r = (phi - r + 2 * r) % 6.283185307179586
        if r < -3.141592653589793 then
        elseif r > 3.141592653589793 then
        end
    end
    local yRot = {}
    table.insert(yRot, AIFieldCourseTurnSegment.new(r, AIFieldCourseTurnSegmentType.LEFT, 1))
    table.insert(yRot, AIFieldCourseTurnSegment.new(r, AIFieldCourseTurnSegmentType.RIGHT, 1))
    table.insert(yRot, AIFieldCourseTurnSegment.new(r, AIFieldCourseTurnSegmentType.LEFT, -1))
    table.insert(yRot, AIFieldCourseTurnSegment.new(r, AIFieldCourseTurnSegmentType.RIGHT, -1))
    return yRot
end
ReedsSheppPath.PATH_FUNCTIONS[7] = function(x, y, phi)
    local dx = x + math.sin(phi)
    local dz = y - 1 - math.cos(phi)
    local length = MathUtil.vector2Length(dx, dz)
    local yRot = MathUtil.getYRotationFromDirection(dz, dx)
    local dx = (20 - length * length) / 16
    if length <= 0 or (length > 6 or (dx < 0 or dx > 1)) then
        return nil
    end
    local dz = math.acos(dx)
    local r = 2 * math.sin(dz) / length
    local yRot = math.clamp(r, -1, 1)
    local length = math.asin(yRot)
    local r = (yRot + 1.5707963267948966 + length) % 6.283185307179586
    if r < -3.141592653589793 then
    elseif r > 3.141592653589793 then
    end
    local r = (r - phi) % 6.283185307179586
    if r < -3.141592653589793 then
    elseif r > 3.141592653589793 then
    end
    local r = {}
    table.insert(r, AIFieldCourseTurnSegment.new(r, AIFieldCourseTurnSegmentType.LEFT, 1))
    table.insert(r, AIFieldCourseTurnSegment.new(dz, AIFieldCourseTurnSegmentType.RIGHT, -1))
    table.insert(r, AIFieldCourseTurnSegment.new(dz, AIFieldCourseTurnSegmentType.LEFT, -1))
    table.insert(r, AIFieldCourseTurnSegment.new(r, AIFieldCourseTurnSegmentType.RIGHT, 1))
    return r
end
ReedsSheppPath.FORWARD_FUNCTIONS = {}
table.insert(ReedsSheppPath.FORWARD_FUNCTIONS, ReedsSheppPath.PATH_FUNCTIONS[1])
table.insert(ReedsSheppPath.FORWARD_FUNCTIONS, ReedsSheppPath.PATH_FUNCTIONS[2])