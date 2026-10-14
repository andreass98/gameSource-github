WeatherInstance = {}
local WeatherInstance_mt = Class(WeatherInstance)
WeatherInstance.HOURTIME = 3600000
WeatherInstance.MINUTETIME = 60000
function WeatherInstance.new(customMt)
    -- upvalues: (copy) WeatherInstance_mt
    local self = setmetatable({}, customMt or WeatherInstance_mt)
    self.objectIndex = nil
    self.variationIndex = nil
    self.startDay = 0
    self.startDayTime = 0
    self.duration = 0
    self.season = Season.SPRING
    return self
end
function WeatherInstance:saveToXMLFile(xmlFile, key, nextInstance)
    local weather = g_currentMission.environment.weather
    local weatherObject = weather:getWeatherObjectByIndex(self.season, self.objectIndex)
    xmlFile:setString(key .. "#typeName", WeatherType.getName(weatherObject.weatherType))
    xmlFile:setString(key .. "#season", Season.getName(self.season))
    xmlFile:setInt(key .. "#variationIndex", self.variationIndex)
    xmlFile:setInt(key .. "#startDay", self.startDay)
    xmlFile:setInt(key .. "#startDayTime", self.startDayTime)
    xmlFile:setInt(key .. "#duration", self.duration)
    if nextInstance ~= nil then
        local currentDay = weather.owner.currentMonotonicDay
        local durationLeft
        if currentDay < nextInstance.startDay then
            durationLeft = 86400000 - weather.owner.dayTime + math.max(0, nextInstance.startDay - (currentDay + 1) - 1) * 24 * 60 * 60 * 1000 + nextInstance.startDayTime
        else
            durationLeft = nextInstance.startDayTime - currentDayTime
        end
        xmlFile:setInt(key .. "#durationLeft", durationLeft)
    end
    if weatherObject.saveInstanceDataToXMLFile ~= nil then
        weatherObject.saveInstanceDataToXMLFile(xmlFile, key, self)
    end
end
function WeatherInstance:loadFromXMLFile(xmlFile, key)
    local seasonName = xmlFile:getString(key .. "#season")
    local weatherTypeName = xmlFile:getString(key .. "#typeName")
    local season = Season.getByName(seasonName) or Season.SUMMER
    local weatherObject = g_currentMission.environment.weather:getWeatherObjectBySeasonAndType(season, (WeatherType.getByName(weatherTypeName)))
    if weatherObject == nil then
        Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. WeatherObject \'%s\' not defined for \'%s\'!", weatherTypeName, key)
        return false
    end
    local variationIndex = xmlFile:getInt(key .. "#variationIndex")
    if weatherObject:getVariationByIndex(variationIndex) == nil then
        Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. WeatherObject variationIndex \'%s\' not defined for weather object \'%s\' for \'%s\'!", weatherTypeName, variationIndex, key)
        return false
    end
    local duration = xmlFile:getInt(key .. "#duration")
    if duration == nil then
        Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Missing duration for \'%s\'!", key)
        return false
    end
    if duration < 60000 then
        Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Duration \'%s\' too low for \'%s\'!", duration, key)
        return false
    end
    local startDay = xmlFile:getInt(key .. "#startDay")
    if startDay == nil then
        Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Missing startDay for \'%s\'!", key)
        return false
    end
    local startDayTime = xmlFile:getInt(key .. "#startDayTime")
    if startDayTime == nil then
        Logging.xmlWarning(xmlFile, "Failed to load forecast weather instance. Missing startDayTime for \'%s\'!", key)
        return false
    end
    local durationLeft = xmlFile:getInt(key .. "#durationLeft")
    if durationLeft ~= nil then
        startDayTime = startDayTime - (duration - durationLeft)
        if startDayTime < 0 then
        end
    end
    self.objectIndex = weatherObject.index
    self.variationIndex = variationIndex
    self.startDay = startDay
    self.startDayTime = startDayTime
    self.duration = duration
    self.season = season
    return (weatherObject.loadInstanceDataFromXMLFile == nil or weatherObject.loadInstanceDataFromXMLFile(xmlFile, key, self)) and true or false
end
function WeatherInstance:readStream(streamId, _)
    self.objectIndex = streamReadUIntN(streamId, Weather.SEND_BITS_OBJECT_INDEX) + 1
    self.variationIndex = streamReadUIntN(streamId, Weather.SEND_BITS_OBJECT_VARIATION_INDEX) + 1
    self.startDay = streamReadInt32(streamId)
    self.startDayTime = streamReadUIntN(streamId, Weather.SEND_BITS_STARTTIME) * 60 * 1000
    self.duration = (streamReadUIntN(streamId, Weather.SEND_BITS_DURATION) + 1) * 60 * 60 * 1000
    self.season = Season.readStream(streamId)
end
function WeatherInstance:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.objectIndex - 1, Weather.SEND_BITS_OBJECT_INDEX)
    streamWriteUIntN(streamId, self.variationIndex - 1, Weather.SEND_BITS_OBJECT_VARIATION_INDEX)
    streamWriteInt32(streamId, self.startDay)
    streamWriteUIntN(streamId, self.startDayTime / 60000, Weather.SEND_BITS_STARTTIME)
    streamWriteUIntN(streamId, self.duration / 3600000 - 1, Weather.SEND_BITS_DURATION)
    Season.writeStream(streamId, self.season)
end
function WeatherInstance.createInstance(objectIndex, variationIndex, startDay, startDayTime, duration, season)
    local weatherObject = g_currentMission.environment.weather:getWeatherObjectByIndex(season, objectIndex)
    local weatherInstance = WeatherInstance.new()
    weatherInstance.objectIndex = objectIndex
    weatherInstance.variationIndex = variationIndex
    weatherInstance.startDay = startDay
    weatherInstance.startDayTime = startDayTime
    weatherInstance.duration = duration
    weatherInstance.season = season
    if weatherObject.initInstanceData ~= nil then
        weatherObject.initInstanceData(weatherObject, weatherInstance)
    end
    return weatherInstance
end