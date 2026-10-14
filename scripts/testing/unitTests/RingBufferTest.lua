RingBufferTest = {}
function RingBufferTest.test_incrementIndex()
    local buffer = RingBuffer.new(10)
    for i = 1, buffer.size * 3 do
        Assert.isBetween(buffer.index, 1, buffer.size, nil, nil, "Increment function caused index to go out of bounds!")
        buffer:incrementIndex()
    end
end
function RingBufferTest.test_calculateIndex()
    local buffer = RingBuffer.new(10)
    local i = 1
    local expectedIndex = buffer.size * 3
    for i = i, expectedIndex do
        local index = buffer:calculateIndex(i)
        Assert.areEqual(index, (i - 1) % buffer.size + 1, "Index did not increment as expected!")
        Assert.isBetween(index, 1, buffer.size, nil, nil, "Calculated index was out of bounds!")
    end
    local i = 1
    local expectedIndex = buffer.size * 3
    for i = i, expectedIndex do
        local index = buffer:calculateIndex(1)
        Assert.areEqual(index, (i - 1) % buffer.size + 1, "Buffer index did not increment as expected!")
        Assert.isBetween(index, 1, buffer.size, nil, nil, "Calculated index was out of bounds!")
        buffer:incrementIndex()
    end
    local expectedIndex = buffer.size
    local expectedIndex = 0
    local i = -1
    for expectedIndex = expectedIndex, -buffer.size + 1, i do
        local index = buffer:calculateIndex(expectedIndex)
        Assert.areEqual(index, expectedIndex, "Buffer index did not decrement as expected!")
        Assert.isBetween(index, 1, buffer.size, nil, nil, "Calculated index was out of bounds!")
        expectedIndex = expectedIndex - 1
    end
end