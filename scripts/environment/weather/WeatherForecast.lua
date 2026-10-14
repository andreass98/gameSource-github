WeatherForecast = {}
WeatherForecast.DAY_LENGTH = 86400000
WeatherForecast.CURVE_TOP_TIME = 0.64788735773
WeatherForecast.CURVE_BOTTOM_TIME = 0.14788735773
WeatherForecast.CLOUD_THRESHOLD = 0.5
local WeatherForecast_mt = Class(WeatherForecast)
function WeatherForecast.new(owner, customMt)
    -- upvalues: (copy) WeatherForecast_mt
    local self = setmetatable({}, customMt or WeatherForecast_mt)
    self.owner = owner
    return self
end
function WeatherForecast:load() end
function WeatherForecast:delete()
    self.owner = nil
end
function WeatherForecast:getCurrentWeather()
    local weatherType = self.owner:getWeatherTypeAtTime(self.owner.owner.currentMonotonicDay, self.owner.owner.dayTime)
    local windX, windZ, windSpeed = self.owner.windUpdater:getCurrentValues()
    local windAngle = math.deg((MathUtil.getYRotationFromDirection(windX, windZ)))
    local windAngle = MathUtil.round(windAngle / 45) * 45
    return {
        ["temperature"] = self.owner:getCurrentTemperature(),
        ["windDirection"] = windAngle,
        ["windSpeed"] = windSpeed,
        ["forecastType"] = weatherType
    }
end
function WeatherForecast:dataForTime(day, time)
    for _, item in ipairs(self.owner.forecastItems) do
        if item.startDay == day and (item.startDayTime <= time and time <= item.startDayTime + item.duration) or item.startDay < day and time <= item.startDayTime + item.duration - WeatherForecast.DAY_LENGTH then
            return self.owner:getForecastInstanceVariation(item), item
        end
    end
    return nil
end
function WeatherForecast:getHourlyForecast(hoursFromNow)
    local time = self.owner.owner.dayTime + hoursFromNow * 60 * 60 * 1000
    local day = self.owner.owner.currentMonotonicDay
    if WeatherForecast.DAY_LENGTH < time then
    end
    local instance, forecastItem = self:dataForTime(day, time)
    if instance == nil then
        return nil
    end
    local startDayTime = time / WeatherForecast.DAY_LENGTH
    local finishDayTime = (time + 3600000) / WeatherForecast.DAY_LENGTH
    local maxTemp = -math.huge
    if startDayTime <= WeatherForecast.CURVE_BOTTOM_TIME and WeatherForecast.CURVE_BOTTOM_TIME <= finishDayTime then
        maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_BOTTOM_TIME, instance.minTemperature, instance.maxTemperature))
    elseif startDayTime <= WeatherForecast.CURVE_TOP_TIME and WeatherForecast.CURVE_TOP_TIME <= finishDayTime then
        maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_TOP_TIME, instance.minTemperature, instance.maxTemperature))
    end
    local object = math.max(maxTemp, self:getTemperatureAtTimeForCurve(startDayTime, instance.minTemperature, instance.maxTemperature))
    local object = math.max(object, self:getTemperatureAtTimeForCurve(finishDayTime, instance.minTemperature, instance.maxTemperature))
    local object = self.owner:getWeatherObjectByIndex(forecastItem.season, forecastItem.objectIndex)
    local variation = object:getVariationByIndex(forecastItem.variationIndex)
    return {
        ["time"] = time,
        ["day"] = day,
        ["temperature"] = object,
        ["windSpeed"] = variation.wind.windVelocity,
        ["windDirection"] = variation.wind.windAngle,
        ["forecastType"] = object.weatherType
    }
end
function WeatherForecast:getDailyForecast(daysFromToday)
    local day = self.owner.owner.currentMonotonicDay + daysFromToday
    local minTemp = math.huge
    local maxTemp = -math.huge
    local forecastType = WeatherType.SUN
    local hasSunInForecast = false
    local windSpeed = 0
    local windDirection = 0
    local uncertaintyFactor = math.pow(1.025, daysFromToday - 1)
    local uncertaintySign = 1
    for _, item in ipairs(self.owner.forecastItems) do
        if item.startDay == day or item.startDay == day - 1 and item.startDayTime + item.duration > WeatherForecast.DAY_LENGTH then
            local instance = self.owner:getForecastInstanceVariation(item)
            table.insert({}, instance)
            local uFactor
            if uncertaintySign == -1 then
                uFactor = 1 / uncertaintyFactor
            else
                uFactor = uncertaintyFactor
            end
            local endDayTime = item.startDayTime + item.duration
            local startDayTime = (item.startDayTime + item.duration * (item.startDay == day and 0 or (WeatherForecast.DAY_LENGTH - item.startDayTime) / item.duration)) / WeatherForecast.DAY_LENGTH % 1
            local finishDayTime = (item.startDayTime + item.duration * (item.startDayTime + item.duration > WeatherForecast.DAY_LENGTH and item.startDay == day - 1 and 1 or (endDayTime <= WeatherForecast.DAY_LENGTH and 1 or 1 - (endDayTime - WeatherForecast.DAY_LENGTH) / item.duration))) / WeatherForecast.DAY_LENGTH
            if startDayTime <= WeatherForecast.CURVE_BOTTOM_TIME and WeatherForecast.CURVE_BOTTOM_TIME <= finishDayTime then
                local variation = self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_BOTTOM_TIME, instance.minTemperature, instance.maxTemperature) / uFactor
                minTemp = math.min(minTemp, variation)
            end
            if startDayTime <= WeatherForecast.CURVE_TOP_TIME and WeatherForecast.CURVE_TOP_TIME <= finishDayTime then
                local variation = self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_TOP_TIME, instance.minTemperature, instance.maxTemperature) * uFactor
                maxTemp = math.max(maxTemp, variation)
            end
            local object = self.owner:getWeatherObjectByIndex(item.season, item.objectIndex)
            local weatherType = object.weatherType
            if weatherType == WeatherType.SUN then
                hasSunInForecast = true
                if forecastType == WeatherType.CLOUDY then
                    forecastType = WeatherType.PARTIALLY_CLOUDY
                end
            elseif weatherType == WeatherType.CLOUDY then
                if hasSunInForecast and forecastType == WeatherType.SUN then
                    forecastType = WeatherType.PARTIALLY_CLOUDY
                end
            elseif weatherType == WeatherType.RAIN then
                forecastType = WeatherType.RAIN
            elseif weatherType == WeatherType.SNOW then
                forecastType = WeatherType.SNOW
            elseif weatherType == WeatherType.TWISTER then
                forecastType = WeatherType.TWISTER
            end
            local variation = object:getVariationByIndex(item.variationIndex)
            if variation.wind ~= nil then
                windSpeed = math.max(windSpeed, variation.wind.windVelocity * uFactor)
            end
            uncertaintySign = -1 * uncertaintySign
        end
    end
    return {
        ["day"] = day,
        ["highTemperature"] = maxTemp,
        ["lowTemperature"] = minTemp,
        ["windSpeed"] = windSpeed,
        ["windDirection"] = MathUtil.round(windDirection / 45) * 45,
        ["forecastType"] = forecastType
    }
end
function WeatherForecast.getTemperatureAtTimeForCurve(_, t, curveMin, curveMax)
    local dh = 0.5 * (curveMax - curveMin)
    return dh * math.sin(6.283185307179586 * t - 2.5) + curveMin + dh
end