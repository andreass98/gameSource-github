MultiValueTween = {}
local MultiValueTween_mt = Class(MultiValueTween, Tween)
function MultiValueTween.new(setterFunction, startValues, endValues, duration, customMt)
    -- upvalues: (copy) MultiValueTween_mt
    local self = Tween.new(setterFunction, startValues, endValues, duration, customMt or MultiValueTween_mt)
    self.values = { unpack(startValues) }
    return self
end
function MultiValueTween:setTarget(target)
    local hadTarget = self.functionTarget ~= nil
    MultiValueTween:superClass().setTarget(self, target)
    if target == nil or hadTarget then
        if target == nil and hadTarget then
            table.remove(self.values, 1)
        else
            self.values[1] = target
        end
    else
        table.insert(self.values, 1, target)
        return
    end
end
function MultiValueTween:tweenValue(t)
    local i = 1
    for i = i, #self.startValue do
        self.values[i + (self.functionTarget == nil and 0 or 1)] = MathUtil.lerp(self.startValue[i], self.endValue[i], self.curveFunc(t))
    end
    return self.values
end
function MultiValueTween:applyValue()
    self.setter(unpack(self.values))
end