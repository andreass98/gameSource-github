InterpolatorSplineTime = {}
local InterpolatorSplineTime_mt = Class(InterpolatorSplineTime)
function InterpolatorSplineTime.new(value, isLooping, customMt)
    -- upvalues: (copy) InterpolatorSplineTime_mt
    local self = setmetatable({}, customMt or InterpolatorSplineTime_mt)
    self.value = value
    self.lastValue = value
    self.targetValue = value
    self.isLooping = isLooping
    if not isLooping then
        self.min = 0
        self.max = 1
    end
    return self
end
function InterpolatorSplineTime:setValue(value)
    self.value = value
    self.lastValue = value
    self.targetValue = value
end
function InterpolatorSplineTime:setTargetValue(value, direction)
    if self.isLooping then
        if direction == 1 then
            if value < self.lastValue then
                self.lastValue = self.lastValue - 1
            end
        elseif self.lastValue < value then
            self.lastValue = self.lastValue + 1
        end
    end
    self.targetValue = self:clampValue(value)
    self.lastValue = self.value
end
function InterpolatorSplineTime:getInterpolatedValue(interpolationAlpha)
    self.value = self.lastValue + interpolationAlpha * (self.targetValue - self.lastValue)
    self.value = self:clampValue(self.value)
    if self.value == self.min or self.value == self.max then
        self:setValue(self.value)
    end
    if self.isLooping then
        return self.value % 1
    else
        return self.value
    end
end
function InterpolatorSplineTime:clampValue(value)
    if self.min ~= nil then
        value = math.max(value, self.min)
    end
    if self.max ~= nil then
        value = math.min(value, self.max)
    end
    return value
end