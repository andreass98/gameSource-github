AIFieldCourseTurnSegment = {}
local AIFieldCourseTurnSegment_mt = Class(AIFieldCourseTurnSegment)
function AIFieldCourseTurnSegment.new(distance, segmentType, drivingDirection)
    -- upvalues: (copy) AIFieldCourseTurnSegment_mt
    local self = setmetatable({}, AIFieldCourseTurnSegment_mt)
    self.distance = math.abs(distance)
    self.segmentType = segmentType
    self.drivingDirection = drivingDirection
    if distance < 0 then
        self:inverseDirection()
    end
    return self
end
function AIFieldCourseTurnSegment:inverseSteering()
    if self.segmentType == AIFieldCourseTurnSegmentType.LEFT then
        self.segmentType = AIFieldCourseTurnSegmentType.RIGHT
    elseif self.segmentType == AIFieldCourseTurnSegmentType.RIGHT then
        self.segmentType = AIFieldCourseTurnSegmentType.LEFT
    end
end
function AIFieldCourseTurnSegment:inverseDirection()
    self.drivingDirection = -self.drivingDirection
end
function AIFieldCourseTurnSegment:getLength()
    return self.distance
end
function AIFieldCourseTurnSegment:move(x, z, phi, delta, turnRadius)
    delta = delta * self.drivingDirection
    if self.segmentType == AIFieldCourseTurnSegmentType.LEFT then
        return x - math.sin(phi - delta) * turnRadius + math.sin(phi) * turnRadius, z + math.cos(phi - delta) * turnRadius - math.cos(phi) * turnRadius, phi - delta
    elseif self.segmentType == AIFieldCourseTurnSegmentType.RIGHT then
        return x + math.sin(phi + delta) * turnRadius - math.sin(phi) * turnRadius, z - math.cos(phi + delta) * turnRadius + math.cos(phi) * turnRadius, phi + delta
    elseif self.segmentType == AIFieldCourseTurnSegmentType.STRAIGHT then
        return x + delta * math.cos(phi) * turnRadius, z + delta * math.sin(phi) * turnRadius, phi
    else
        return x, z, phi
    end
end