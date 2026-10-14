Daylight = {}
local Daylight_mt = Class(Daylight)
function Daylight.new(customMt)
    -- upvalues: (copy) Daylight_mt
    local self = setmetatable({}, customMt or Daylight_mt)
    self.latitude = 50
    self.latitudeInRadians = 50
    self.dayStart = 6
    self.dayEnd = 20
    self.nightEnd = 8
    self.nightStart = 18
    self.logicalNightStart = 6
    self.logicalNightEnd = 18
    self.logicalNightStartMinutes = self.logicalNightStart * 60
    self.logicalNightEndMinutes = self.logicalNightEnd * 60
    self:setJulianDay(90)
    return self
end
function Daylight:delete() end
function Daylight:load(xmlFile, baseKey)
    self.latitude = xmlFile:getFloat(baseKey .. ".latitude", 50)
    self.latitudeInRadians = math.rad(self.latitude)
end
function Daylight:saveToXMLFile(xmlFile, key) end
function Daylight:loadFromXMLFile(xmlFile, key) end
function Daylight:setJulianDay(julianDay)
    if self.julianDay ~= julianDay then
        self.julianDay = julianDay
        self.dayStart, self.dayEnd, self.nightEnd, self.nightStart = self:calculateStartEndOfDay()
        self.logicalNightStart = MathUtil.lerp(self.dayEnd, self.nightStart, 0.3)
        self.logicalNightEnd = MathUtil.lerp(self.nightEnd, self.dayStart, 0.8)
        self.logicalNightStartMinutes = self.logicalNightStart * 60
        self.logicalNightEndMinutes = self.logicalNightEnd * 60
        g_messageCenter:publishDelayed(MessageType.DAYLIGHT_CHANGED)
    end
end
function Daylight:getDaylightTimes()
    return self.dayStart, self.dayEnd, self.nightEnd, self.nightStart
end
function Daylight:getLogicalNightTime()
    return self.logicalNightStart, self.logicalNightEnd
end
function Daylight:getSunHeightAngle()
    return self.latitudeInRadians - self:calculateSunDeclination() - 1.5707963267948966
end
function Daylight:calculateStartEndOfDay()
    local sunDeclination = self:calculateSunDeclination()
    local dayStart = self:calculateTime(-12, true, sunDeclination)
    local dayEnd = self:calculateTime(-5, false, sunDeclination)
    local nightStart = self:calculateTime(14, false, sunDeclination)
    local nightEnd = self:calculateTime(5, true, sunDeclination)
    local nightEnd = math.max(nightEnd, 1.01)
    if dayStart == dayEnd then
    end
    local nightStart = math.min(nightStart, 22.99)
    return dayStart, math.min(dayEnd, nightStart - 0.01), nightEnd, nightStart
end
function Daylight:calculateTime(position, isDawn, sunDeclination)
    local latitudeInRadians = self.latitudeInRadians
    local gamma = (math.sin(position * 3.141592653589793 / 180) + math.sin(latitudeInRadians) * math.sin(sunDeclination)) / (math.cos(latitudeInRadians) * math.cos(sunDeclination))
    local denom = gamma < -1 and 0 or (gamma > 1 and 24 or 24 - 7.639437268410976 * math.acos(gamma))
    if isDawn then
        return math.max(12 - denom / 2, 0.01)
    else
        return math.min(12 + denom / 2, 23.99)
    end
end
function Daylight:calculateSunDeclination()
    local theta = 0.216 + 2 * math.atan(0.967 * math.tan(0.0086 * (self.julianDay - 186)))
    return math.asin(0.4 * math.cos(theta))
end