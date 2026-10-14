ObjectPoolTest = {}
function ObjectPoolTest.test_constructor()
    Assert.throwsError(function()
        ObjectPool.new(100)
    end)
    local objectPool = ObjectPool.new()
    Assert.areEqual(objectPool.objectConstructor, ObjectPool.EMPTY_TABLE_CONSTRUCTOR, "Default object pool constructor was not used!")
end
function ObjectPoolTest.test_length()
    local objectPool = ObjectPool.new()
    local i = 1
    for i = i, 20 do
        local createdObject = objectPool:getOrCreateNext()
        Assert.isNotNil(createdObject, "Object created from pool was nil.")
        table.insert({}, createdObject)
    end
    local i = 1
    for i = i, 20 do
        objectPool:returnToPool((table.remove(createdObjects)))
        Assert.areEqual(objectPool:getLength(), i)
    end
end
function ObjectPoolTest.test_duplicates()
    local objectPool = ObjectPool.new()
    local createdObject = objectPool:getOrCreateNext()
    Assert.isNotNil(createdObject, "Object created from pool was nil.")
    local result = objectPool:returnToPool(createdObject)
    Assert.isTrue(result, "Object could not be added to empty pool.")
    local secondCreatedObject = objectPool:returnToPool(createdObject)
    Assert.isFalse(secondCreatedObject, "Duplicate object was accepted.")
    local secondCreatedObject = objectPool:getOrCreateNext()
    Assert.areEqual(secondCreatedObject, createdObject, "Got a different object out of pool than was put in")
    local result = objectPool:returnToPool(secondCreatedObject)
    Assert.isTrue(result, "Object could not be re-added to pool.")
end
function ObjectPoolTest.test_addNil()
    local result = ObjectPool.new():returnToPool(nil)
    Assert.isFalse(result, "Object pool accepted nil value.")
end
function ObjectPoolTest.test_instanceReset()
    local objectPool = ObjectPool.new()
    local value = objectPool:getOrCreateNext()
    value.testValue = true
    objectPool:returnToPool(value)
    local secondValue = objectPool:getOrCreateNext()
    Assert.areEqual(value, secondValue, "Table was not properly pooled, different value was given on second function call!")
    Assert.isNil(value.testValue, "Table was not cleared when pooled!")
end