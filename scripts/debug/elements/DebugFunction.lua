DebugFunction = {}
local DebugFunction_mt = Class(DebugFunction)
function DebugFunction.new(updateFunc, drawFunc, initFunc, deleteFunc, customMt)
    -- upvalues: (copy) DebugFunction_mt
    local self = setmetatable({}, customMt or DebugFunction_mt)
    self.updateFunc = updateFunc
    self.drawFunc = drawFunc
    self.deleteFunc = deleteFunc
    if initFunc ~= nil then
        initFunc(self)
    end
    return self
end
function DebugFunction:delete()
    if self.deleteFunc ~= nil then
        self.deleteFunc(self)
    end
end
function DebugFunction:update(dt)
    if self.updateFunc ~= nil then
        self.updateFunc(self, dt)
    end
end
function DebugFunction:getShouldBeDrawn()
    return true
end
function DebugFunction:draw()
    if self.drawFunc ~= nil then
        self.drawFunc(self)
    end
end