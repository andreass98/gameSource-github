ValueDelay = {}
local ValueDelay_mt = Class(ValueDelay)
function ValueDelay.new(duration, direction, customMt)
    -- upvalues: (copy) ValueDelay_mt
    local self = setmetatable({}, customMt or ValueDelay_mt)
    self.duration = duration
    self.direction = direction
    self.values = {}
    for _ = 1, math.floor(duration / 16.666666666666668) + 1 do
        table.insert(self.values, {
            ["value"] = 0,
            ["time"] = -1
        })
    end
    self.insertIndex = 0
    self.maxFrames = #self.values
    self.isReseted = true
    return self
end
function ValueDelay:add(value, _)
    self.isReseted = false
    if self.maxFrames == 0 then
        return value
    end
    self.insertIndex = self.insertIndex + 1
    if self.insertIndex > self.maxFrames then
        self.insertIndex = 1
    end
    local valueData = self.values[self.insertIndex]
    valueData.value = value
    valueData.time = g_time
    local minTime = math.huge
    local minSlot = 0
    local minValue = 0
    local slotValid = false
    local i = 1
    local returnValue = self.maxFrames - 1
    for i = i, returnValue do
        local readIndex = self.insertIndex - i
        if readIndex <= 0 then
        end
        local slotTime = self.values[readIndex].time
        if slotTime == -1 then
            break
        end
        local difference = self.duration - (valueData.time - slotTime)
        if difference < minTime and difference > 0 then
            minValue = self.values[readIndex].value
            minSlot = readIndex
            minTime = difference
        elseif difference < 0 then
            slotValid = true
            break
        end
        if i == self.maxFrames - 1 then
            slotValid = true
        end
    end
    local returnValue = 0
    if minSlot == 0 then
        minValue = returnValue
    elseif not slotValid then
        minValue = returnValue
    end
    if self.direction ~= nil then
        if self.direction == -1 then
            if minValue < value then
                return value
            end
        elseif value < minValue then
            return value
        end
    end
    return minValue
end
function ValueDelay:reset()
    if not self.isReseted then
        local i = 1
        for i = i, self.maxFrames do
            self.values[i].value = 0
            self.values[i].time = -1
        end
        self.isReseted = true
    end
end