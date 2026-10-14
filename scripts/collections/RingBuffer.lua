RingBuffer = {}
local RingBuffer_mt = Class(RingBuffer)
function RingBuffer.new(size, customMt)
    -- upvalues: (copy) RingBuffer_mt
    local self = setmetatable({}, customMt or RingBuffer_mt)
    self.size = size
    self.index = 1
    self.values = table.create(size)
    self.values[1] = 0
    return self
end
function RingBuffer:add(value)
    self.values[self.index] = value
    self:incrementIndex()
end
function RingBuffer:incrementIndex()
    self.index = self.index + 1
    if self.index > self.size then
        self.index = 1
    end
end
function RingBuffer:calculateIndex(localIndex)
    local index = self.index + (localIndex - 1)
    if index <= self.size and index > 0 then
        return index
    else
        return (index - 1) % self.size + 1
    end
end
function RingBuffer:getLocallyIndexed(localIndex)
    return self:getAbsolutelyIndexed((self:calculateIndex(localIndex)))
end
function RingBuffer:getAbsolutelyIndexed(absoluteIndex)
    return self.values[absoluteIndex]
end
function RingBuffer:getAverage()
    local sum = 0
    for _, value in ipairs(self.values) do

    end
    return sum / #self.values
end