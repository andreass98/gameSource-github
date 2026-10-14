BezierCurve = {}
local BezierCurve_mt = Class(BezierCurve)
function BezierCurve.new(positionX1, positionY1, positionX2, positionY2)
    -- upvalues: (copy) BezierCurve_mt
    local self = setmetatable({}, BezierCurve_mt)
    self.positionX1 = math.clamp(positionX1, 0, 1)
    self.positionY1 = positionY1
    self.positionX2 = math.clamp(positionX2, 0, 1)
    self.positionY2 = positionY2
    self.cx = 0
    self.bx = 0
    self.ax = 0
    self.cy = 0
    self.by = 0
    self.ay = 0
    self:recalculateCoefficients()
    return self
end
function BezierCurve:recalculateCoefficients()
    self.cx = 3 * self.positionX1
    self.bx = 3 * (self.positionX2 - self.positionX1) - self.cx
    self.ax = 1 - self.cx - self.bx
    self.cy = 3 * self.positionY1
    self.by = 3 * (self.positionY2 - self.positionY1) - self.cy
    self.ay = 1 - self.cy - self.by
end
function BezierCurve:setPositionX1(newValue)
    self.positionX1 = math.clamp(newValue, 0, 1)
    self:recalculateCoefficients()
end
function BezierCurve:setPositionY1(newValue)
    self.positionY1 = math.clamp(newValue, 0, 1)
    self:recalculateCoefficients()
end
function BezierCurve:setPositionX2(newValue)
    self.positionX2 = math.clamp(newValue, 0, 1)
    self:recalculateCoefficients()
end
function BezierCurve:setPositionY2(newValue)
    self.positionY2 = math.clamp(newValue, 0, 1)
    self:recalculateCoefficients()
end
function BezierCurve:sampleX(t)
    return ((self.ax * t + self.bx) * t + self.cx) * t
end
function BezierCurve:sampleY(t)
    return ((self.ay * t + self.by) * t + self.cy) * t
end
function BezierCurve:sampleDerivativeX(t)
    return (3 * self.ax * t + 2 * self.bx) * t + self.cx
end
function BezierCurve:solveX(x, epsilon)
    epsilon = epsilon or 1e-6
    local i = 1
    local startX = 8
    local endX = 1
    for i = i, startX, endX do
        local sampleX = self:sampleX(x) - x
        if math.abs(sampleX) < epsilon then
            return x
        end
        local sampleDerivative = self:sampleDerivativeX(x)
        if math.abs(sampleDerivative) < epsilon then
            break
        end
        x = x - sampleX / sampleDerivative
    end
    local startX = 0
    local endX = 1
    if x < startX then
        return startX
    end
    if endX < x then
        return endX
    end
    while startX < endX do
        local i = self:sampleX(x)
        if math.abs(i - x) < epsilon then
            return x
        end
        if i < x then
            startX = x
        end
        endX = x
        x = (x - startX) * 0.5 + startX
    end
    return x
end
function BezierCurve:solve(x, epsilon)
    return self:sampleY(self:solveX(x, epsilon))
end