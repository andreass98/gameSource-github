TargetedFunction = {}
local TargetedFunction_mt = Class(TargetedFunction)
function TargetedFunction.new(targetFunction, targetObject, ...)
    -- upvalues: (copy) TargetedFunction_mt
    local self = setmetatable({}, TargetedFunction_mt)
    self.targetFunction = targetFunction
    self.targetObject = targetObject
    self.arguments = table.pack(...)
    return self
end
function TargetedFunction:delete()
    self.targetFunction = nil
    self.targetObject = nil
end
function TargetedFunction.resolveListener(targetFunction, targetObject)
    if type(targetFunction) == "function" then
        return TargetedFunction.new(targetFunction, targetObject)
    else
        return targetFunction
    end
end
function TargetedFunction:unpackCombinedArguments(...)
    return table.unpack(table.getListUnion(self.arguments, table.pack(...)))
end
function TargetedFunction:invoke(...)
    if self.targetObject then
        if self.arguments.n == 0 then
            return self.targetFunction(self.targetObject, ...)
        else
            return self.targetFunction(self.targetObject, self:unpackCombinedArguments(...))
        end
    elseif self.arguments.n == 0 then
        return self.targetFunction(...)
    else
        return self.targetFunction(self:unpackCombinedArguments(...))
    end
end
function TargetedFunction_mt.__call(instance, ...)
    return instance:invoke(...)
end