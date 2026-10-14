UsageBuffer = {}
local UsageBuffer_mt = Class(UsageBuffer)
function UsageBuffer.new(duration, _, numBits)
    -- upvalues: (copy) UsageBuffer_mt
    local self = setmetatable({}, UsageBuffer_mt)
    self.time = 0
    self.valueSum = 0
    self.numValues = 0
    self.lastValue = 0
    self.lastAddedValue = 0
    self.duration = duration
    self.lastValueSent = 0
    self.numBits = numBits or 8
    self.maxValue = 2 ^ self.numBits - 1
    self.isDirty = false
    return self
end
function UsageBuffer:add(value, skipBuffer, setDirty)
    if g_server ~= nil then
        if value == nil then
            value = self.lastAddedValue
        end
        self.lastAddedValue = value
        if skipBuffer then
            self.lastValue = value
            self.time = 0
            self.valueSum = 0
            self.numValues = 0
            if setDirty then
                self.isDirty = true
                return
            end
        else
            self.valueSum = self.valueSum + value
            self.numValues = self.numValues + 1
        end
    end
end
function UsageBuffer:update(dt)
    if g_server ~= nil then
        self.time = self.time + dt
        if self.time > self.duration then
            if self.numValues > 0 then
                self.lastValue = self.valueSum / self.numValues
            else
                self.lastValue = 0
            end
            if self.lastValueSent ~= self.lastValue then
                self.isDirty = true
            end
            self.time = 0
            self.valueSum = 0
            self.numValues = 0
        end
    end
end
function UsageBuffer:get()
    return self.lastValue
end
function UsageBuffer:getLastAdded()
    return self.lastAddedValue
end
function UsageBuffer:reset()
    self.time = 0
    self.valueSum = 0
    self.numValues = 0
    self.lastValue = 0
    self.lastAddedValue = 0
end
function UsageBuffer:readStream(streamId, _)
    self.lastValue = streamReadUIntN(streamId, self.numBits)
    self.lastAddedValue = self.lastValue
end
function UsageBuffer:writeStream(streamId, _)
    streamWriteUIntN(streamId, math.clamp(self.lastValue, 0, self.maxValue), self.numBits)
end
function UsageBuffer:resetDirtyState()
    self.lastValueSent = self.lastValue
    self.isDirty = false
end
function UsageBuffer:getIsDirty()
    return self.isDirty
end