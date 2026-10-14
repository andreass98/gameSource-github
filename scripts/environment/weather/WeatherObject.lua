WeatherObject = {}
local WeatherObject_mt = Class(WeatherObject)
function WeatherObject.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt)
    -- upvalues: (copy) WeatherObject_mt
    local self = setmetatable({}, customMt or WeatherObject_mt)
    self.weatherType = weatherType
    self.temperatureUpdater = temperatureUpdater
    self.cloudUpdater = cloudUpdater
    self.windUpdater = windUpdater
    self.rainUpdater = rainUpdater
    self.variations = {}
    self.weightedVariations = {}
    return self
end
function WeatherObject:getIsAvailable()
    return true
end
function WeatherObject:load(xmlFile, key, baseDirectory)
    self.weight = xmlFile:getInt(key .. "#weight", 1)
    for _, variationKey in xmlFile:iterator(key .. ".variation") do
        if 2 ^ Weather.SEND_BITS_OBJECT_VARIATION_INDEX - 1 < #self.variations then
            Logging.xmlWarning(xmlFile, "Weather object variation limit (%d) readed at \'%s\'", maxVariations, variationKey)
            break
        end
        local variation = self:loadVariation(xmlFile, variationKey, baseDirectory)
        if variation ~= nil then
            table.insert(self.variations, variation)
            variation.index = #self.variations
            for _ = 1, variation.weight do
                table.insert(self.weightedVariations, variation.index)
            end
        end
    end
    return true
end
function WeatherObject:getMinDuration()
    return 1
end
function WeatherObject:loadVariation(xmlFile, key, _, _)
    local variation = {}
    local minDuration = self:getMinDuration()
    variation.weight = xmlFile:getInt(key .. "#weight", 1)
    local maxTemperature = xmlFile:getInt(key .. "#minHours", 5)
    local minCopy = 2 ^ Weather.SEND_BITS_DURATION - 1
    variation.minHours = math.clamp(maxTemperature, 1, minCopy)
    if variation.minHours < minDuration then
        Logging.xmlWarning(xmlFile, "MinHours needs to be greater than %.1f hours for variation \'%s\'!", minDuration, key)
        variation.minHours = minDuration
    end
    local maxTemperature = xmlFile:getInt(key .. "#maxHours", 10)
    local minCopy = 2 ^ Weather.SEND_BITS_DURATION - 1
    variation.maxHours = math.clamp(maxTemperature, 3, minCopy)
    if variation.maxHours < variation.minHours then
        Logging.xmlWarning(xmlFile, "MaxHours needs to be greater than minHours! for variation \'%s\'", key)
        variation.maxHours = variation.minHours
    end
    local minTemperature = xmlFile:getInt(key .. "#minTemperature", 15)
    local maxTemperature = xmlFile:getInt(key .. "#maxTemperature", 25)
    local maxSendTemp = 2 ^ Weather.SEND_BITS_TEMPERATURE
    if maxSendTemp < minTemperature then
        Logging.xmlWarning(xmlFile, "Min temperature is too high. Maximum is %d for variation \'%s\'", maxSendTemp, key)
    elseif maxSendTemp < maxTemperature then
        Logging.xmlWarning(xmlFile, "Max temperature is too high. Maximum is %d for variation \'%s\'", maxSendTemp, key)
        maxTemperature = maxSendTemp
        maxSendTemp = minTemperature
    else
        maxSendTemp = minTemperature
    end
    if maxTemperature >= maxSendTemp then
    end
    variation.minTemperature = maxTemperature
    variation.maxTemperature = maxSendTemp
    local minCopy = key .. ".clouds#presetId"
    local presetId = xmlFile:getString(minCopy)
    local cloudSettings = self.cloudUpdater:createCloudSettingsFromPreset(presetId)
    if cloudSettings == nil then
        Logging.xmlWarning(xmlFile, "Clouds presetId \'%s\' is not defined for \'%s\'", presetId, minCopy)
        return nil
    end
    variation.clouds = cloudSettings
    local rainKey = key .. ".rain#presetId"
    local rainPresetId = xmlFile:getString(rainKey)
    if rainPresetId ~= nil then
        local rainSettings = self.rainUpdater:createRainSettingsFromPreset(rainPresetId)
        if rainSettings == nil then
            Logging.xmlWarning(xmlFile, "Rain presetId \'%s\' is not defined for \'%s\'", rainPresetId, rainKey)
        else
            variation.rain = rainSettings
            variation.rainPresetId = rainPresetId
        end
    end
    variation.wind = WindObject.new()
    variation.wind:load(xmlFile, key .. ".wind")
    return variation
end
function WeatherObject:getRandomVariationIndex()
    return self.weightedVariations[math.random(1, #self.weightedVariations)]
end
function WeatherObject:getVariationByIndex(index)
    if index == nil then
        return nil
    else
        return self.variations[index]
    end
end
function WeatherObject:delete() end
function WeatherObject:update(scaledDt) end
function WeatherObject:activate(weatherInstance, blendDuration, _)
    local variation = self.variations[weatherInstance.variationIndex]
    local wind = variation.wind
    self.rainUpdater:setTargetRain(variation.rain, blendDuration)
    self.cloudUpdater:setTargetClouds(variation.clouds, blendDuration)
    self.temperatureUpdater:setTargetValues(variation.minTemperature, variation.maxTemperature, blendDuration == 0)
    self.windUpdater:setTargetValues(wind.windDirectionX, wind.windDirectionZ, wind.windVelocity, wind.cirrusSpeedFactor, blendDuration)
end
function WeatherObject:deactivate(blendDuration) end