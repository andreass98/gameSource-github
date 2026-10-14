AsyncAwaiter = {}
local AsyncAwaiter_mt = Class(AsyncAwaiter)
function AsyncAwaiter.new(targetFunction)
    -- upvalues: (copy) AsyncAwaiter_mt
    local self = setmetatable({}, AsyncAwaiter_mt)
    self.targetFunction = targetFunction
    self.dependencies = {}
    self.dependenciesCount = 0
    return self
end
function AsyncAwaiter:getDependenciesCount()
    return self.dependenciesCount
end
function AsyncAwaiter:addDependency(dependency)
    if dependency == nil or self.dependencies[dependency] ~= nil then
        return false
    end
    self.dependencies[dependency] = dependency
    self.dependenciesCount = self.dependenciesCount + 1
    return true
end
function AsyncAwaiter:addDependencies(dependencies)
    for _, dependency in pairs(dependencies) do
        self:addDependency(dependency)
    end
end
function AsyncAwaiter:onDependencyAvailable(dependency)
    if self.dependencies[dependency] == nil then
        return false
    end
    self.dependencies[dependency] = nil
    self.dependenciesCount = self.dependenciesCount - 1
    local shouldExecute = self.dependenciesCount <= 0
    if shouldExecute then
        self.targetFunction()
    end
    return shouldExecute
end
function AsyncAwaiter:cancel()
    self:reset()
end
function AsyncAwaiter:reset()
    table.clear(self.dependencies)
    self.dependenciesCount = 0
    self.targetFunction = nil
end