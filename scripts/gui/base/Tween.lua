Tween = {}
local Tween_mt = Class(Tween)
function Tween.new(setterFunction, startValue, endValue, duration, customMt)
    -- upvalues: (copy) Tween_mt
    local self = setmetatable({}, customMt or Tween_mt)
    self.setter = setterFunction
    self.startValue = startValue
    self.endValue = endValue
    self.duration = duration
    self.elapsedTime = 0
    self.isFinished = duration == 0
    self.functionTarget = nil
    self.curveFunc = Tween.CURVE.LINEAR
    return self
end
function Tween:getDuration()
    return self.duration
end
function Tween:getFinished()
    return self.isFinished
end
function Tween:reset()
    self.elapsedTime = 0
    self.isFinished = self.duration == 0
end
function Tween:setTarget(target)
    self.functionTarget = target
end
function Tween:update(dt)
    if not self.isFinished then
        self.elapsedTime = self.elapsedTime + dt
        local t
        if self.elapsedTime >= self.duration then
            self.isFinished = true
            t = self:tweenValue(1)
        else
            t = self:tweenValue(self.elapsedTime / self.duration)
        end
        self:applyValue(t)
    end
end
function Tween:tweenValue(t)
    return MathUtil.lerp(self.startValue, self.endValue, self.curveFunc(t))
end
function Tween:applyValue(newValue)
    if self.functionTarget == nil then
        self.setter(newValue)
    else
        self.setter(self.functionTarget, newValue)
    end
end
function Tween:setCurve(func)
    self.curveFunc = func or Tween.CURVE.LINEAR
end
Tween.CURVE = {}
function Tween.CURVE.LINEAR(t)
    return t
end
function Tween.CURVE.EASE_IN(t)
    return t * t * t
end
function Tween.CURVE.EASE_OUT(t)
    local invT = t - 1
    return invT * invT * invT + 1
end
function Tween.CURVE.EASE_IN_OUT(t)
    if t < 0.5 then
        return 0.5 * Tween.CURVE.EASE_IN(t * 2)
    else
        return 0.5 * Tween.CURVE.EASE_OUT((t - 0.5) * 2) + 0.5
    end
end
function Tween.CURVE.EASE_OUT_IN(t)
    if t < 0.5 then
        return 0.5 * Tween.CURVE.EASE_OUT(t * 2)
    else
        return 0.5 * Tween.CURVE.EASE_IN((t - 0.5) * 2) + 0.5
    end
end
function Tween.CURVE.EASE_IN_BACK(t)
    return math.pow(t, 2) * (2.70158 * t - 1.70158)
end
function Tween.CURVE.EASE_OUT_BACK(t)
    local invT = t - 1
    return math.pow(invT, 2) * (2.70158 * invT + 1.70158) + 1
end
function Tween.CURVE.EASE_IN_OUT_BACK(t)
    if t < 0.5 then
        return 0.5 * Tween.CURVE.EASE_IN_BACK(t * 2)
    else
        return 0.5 * Tween.CURVE.EASE_OUT_BACK((t - 0.5) * 2) + 0.5
    end
end
function Tween.CURVE.EASE_OUT_IN_BACK(t)
    if t < 0.5 then
        return 0.5 * Tween.CURVE.EASE_OUT_BACK(t * 2)
    else
        return 0.5 * Tween.CURVE.EASE_IN_BACK((t - 0.5) * 2) + 0.5
    end
end