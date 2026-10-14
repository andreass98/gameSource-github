ValueBuffer = {}
local ValueBuffer_mt = Class(ValueBuffer)
function ValueBuffer.new(duration, customMt)
    -- upvalues: (copy) ValueBuffer_mt
    local self = setmetatable({}, customMt or ValueBuffer_mt)
    self.duration = duration
    self.index = 1
    self.values = {}
    self.time = 0
    return self
end
function ValueBuffer:add(value)
    self.values[self.index] = value
    self.index = self.index + 1
    if g_time - self.time > self.duration then
        if #self.values > self.index then
            local i = #self.values
            for i = i, self.index, -1 do
                table.remove(self.values, i)
            end
        end
        self.time = g_time
        self.index = 1
    end
end
function ValueBuffer:get(duration)
    local value = 0
    for _, sValue in ipairs(self.values) do

    end
    return value * ((duration or self.duration) / self.duration)
end
function ValueBuffer:getAverage()
    local value = 0
    for _, sValue in ipairs(self.values) do

    end
    return value / #self.values
end