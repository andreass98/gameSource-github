ObjectPool = {}
local ObjectPool_mt = Class(ObjectPool)
function ObjectPool.EMPTY_TABLE_CONSTRUCTOR()
    return {}
end
function ObjectPool_mt.__len(pool)
    return pool:getLength()
end
function ObjectPool.new(objectConstructor, ...)
    -- upvalues: (copy) ObjectPool_mt
    local self = setmetatable({}, ObjectPool_mt)
    self.objectConstructor = objectConstructor or ObjectPool.EMPTY_TABLE_CONSTRUCTOR
    self.objectConstructorArguments = table.pack(...)
    self.pool = {}
    self.poolSet = {}
    return self
end
function ObjectPool:getLength()
    return #self.pool
end
function ObjectPool:clear()
    table.clear(self.poolSet)
    table.clear(self.pool)
end
function ObjectPool:getOrCreateNext()
    local instance = table.remove(self.pool)
    if instance then
        self.poolSet[instance] = nil
        return instance
    end
    if self.objectConstructor == ObjectPool.EMPTY_TABLE_CONSTRUCTOR then
        return self.objectConstructor()
    end
    return self.objectConstructor(table.unpack(self.objectConstructorArguments, 1, self.objectConstructorArguments.n))
end
function ObjectPool:returnToPool(instance)
    if instance == nil then
        return false
    end
    if self.poolSet[instance] ~= nil then
        return false
    end
    if self.objectConstructor == ObjectPool.EMPTY_TABLE_CONSTRUCTOR then
        table.clear(instance)
    elseif instance.reset ~= nil then
        instance:reset()
    end
    table.insert(self.pool, instance)
    self.poolSet[instance] = instance
    return true
end