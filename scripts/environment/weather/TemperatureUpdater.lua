TemperatureUpdater = {}
local TemperatureUpdater_mt = Class(TemperatureUpdater)
function TemperatureUpdater.new(customMt)
    -- upvalues: (copy) TemperatureUpdater_mt
    local self = setmetatable({}, customMt or TemperatureUpdater_mt)
    self.dayLength = 1
    self.isDirty = false
    self.currentMin = 15
    self.currentMax = 20
    self.targetMin = 15
    self.targetMax = 20
    self.changeDuration = 3600000
    return self
end
function TemperatureUpdater:delete() end
function TemperatureUpdater:update(dt)
    if self.isDirty then
        if self.currentMax < self.targetMax then
            self.currentMax = math.min(self.currentMax + dt / self.changeDuration, self.targetMax)
        else
            self.currentMax = math.max(self.currentMax - change, self.targetMax)
        end
        if self.currentMin < self.targetMin then
            self.currentMin = math.min(self.currentMin + change, self.targetMin)
        else
            self.currentMin = math.max(self.currentMin - change, self.targetMin)
        end
        self.isDirty = self.currentMin ~= self.targetMin or self.currentMax ~= self.targetMax
    end
end
function TemperatureUpdater:setDayLength(dayLength)
    self.dayLength = dayLength
end
function TemperatureUpdater:getCurrentValues()
    return self.currentMin, self.currentMax
end
function TemperatureUpdater:setTargetValues(targetMin, targetMax, immediate)
    self.isDirty = not immediate
    self.targetMin = targetMin
    self.targetMax = targetMax
    if immediate then
        self.currentMin = targetMin
        self.currentMax = targetMax
    end
end
function TemperatureUpdater:getTemperatureAtTime(dayTime)
    local deltaTemperatureHalf = 0.5 * (self.currentMax - self.currentMin)
    return deltaTemperatureHalf * math.sin(6.283185307179586 * (dayTime / self.dayLength) - 2.5) + self.currentMin + deltaTemperatureHalf
end