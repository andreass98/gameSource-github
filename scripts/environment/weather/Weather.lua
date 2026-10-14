Weather = {}
Weather.DEBUG_ENABLED = false
Weather.TEMPERATURE_STABLE_CHANGE = 2
Weather.SEND_BITS_NUM_OBJECTS = 8
Weather.SEND_BITS_OBJECT_INDEX = 5
Weather.SEND_BITS_OBJECT_VARIATION_INDEX = 4
Weather.SEND_BITS_WIND_INDEX = 4
Weather.SEND_BITS_TEMPERATURE = 6
Weather.SEND_BITS_DURATION = 6
Weather.SEND_BITS_STARTTIME = 11
Weather.CHANGE_DURATION = 1800000
source("dataS/scripts/environment/weather/DisasterDestructionState.lua")
source("dataS/scripts/environment/weather/WeatherType.lua")
source("dataS/scripts/environment/weather/WeatherForecast.lua")
source("dataS/scripts/environment/weather/Twister.lua")
source("dataS/scripts/environment/weather/TwisterStartEvent.lua")
source("dataS/scripts/environment/weather/TwisterStopEvent.lua")
source("dataS/scripts/environment/weather/TwisterDestructionNotificationEvent.lua")
source("dataS/scripts/environment/weather/CloudSettings.lua")
source("dataS/scripts/environment/weather/CloudUpdater.lua")
source("dataS/scripts/environment/weather/TemperatureUpdater.lua")
source("dataS/scripts/environment/weather/RainSettings.lua")
source("dataS/scripts/environment/weather/RainUpdater.lua")
source("dataS/scripts/environment/weather/WeatherObject.lua")
source("dataS/scripts/environment/weather/WeatherObjectTwister.lua")
source("dataS/scripts/environment/weather/WeatherObjectHail.lua")
source("dataS/scripts/environment/weather/WeatherInstance.lua")
source("dataS/scripts/environment/weather/WindObject.lua")
source("dataS/scripts/environment/weather/WindUpdater.lua")
source("dataS/scripts/environment/weather/WeatherAddObjectEvent.lua")
source("dataS/scripts/environment/weather/WeatherStateEvent.lua")
source("dataS/scripts/environment/weather/FogSettings.lua")
source("dataS/scripts/environment/weather/FogUpdater.lua")
source("dataS/scripts/environment/weather/FogStateEvent.lua")
source("dataS/scripts/environment/weather/SkyBoxUpdater.lua")
local Weather_mt = Class(Weather)
function Weather.new(owner, customMt)
    -- upvalues: (copy) Weather_mt
    local self = setmetatable({}, customMt or Weather_mt)
    self.owner = owner
    self.isRainAllowed = false
    self.typeToWeatherObject = {}
    self.weatherObjects = {}
    self.weightedWeatherObjects = {}
    self.forecastItems = {}
    self.cloudUpdater = CloudUpdater.new()
    self.temperatureUpdater = TemperatureUpdater.new()
    self.fogUpdater = FogUpdater.new()
    self.rainUpdater = RainUpdater.new()
    if getAtmosphereQuality() == AtmosphereQuality.OFF then
        self.skyBoxUpdater = SkyBoxUpdater.new()
    end
    self.windUpdater = WindUpdater.new()
    self.windUpdater:addWindChangedListener(self.cloudUpdater)
    self.windUpdater:addWindChangedListener(self.rainUpdater)
    self.forecast = WeatherForecast.new(self)
    self.timeSinceLastRain = 9999999
    self.snowHeight = 0
    self.groundWetness = 0
    self.groundWetnessDryDuration = 1800000
    self.groundWetnessWetDuration = 300000
    self.temperatureDebugGraph = Graph.new(24, 0.58, 0.5, 0.4, 0.4, 0, 40, true, "\194\176", Graph.STYLE_LINES)
    self.temperatureDebugGraph:setColor(1, 0, 0, 1)
    self.temperatureDebugGraph:setBackgroundColor(0, 0, 0, 0.6)
    self.temperatureDebugGraph:setHorizontalLine(5, true, 1, 1, 1, 0.4)
    self.temperatureDebugGraph:setVerticalLine(6, true, 1, 1, 1, 0.3)
    self.temperatureDebugOverlayCurrent = createImageOverlay("dataS/menu/base/graph_pixel.png")
    setOverlayColor(self.temperatureDebugOverlayCurrent, 0, 1, 0, 1)
    addConsoleCommand("gsWeatherDebug", "Toggles weather debug", "consoleCommandWeatherToggleDebug", self)
    if not g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission:getIsServer() then
        addConsoleCommand("gsWeatherReload", "Reloads weather data", "consoleCommandWeatherReloadData", self)
        addConsoleCommand("gsWeatherSet", "Sets a weather object by type", "consoleCommandWeatherSet", self)
        addConsoleCommand("gsWeatherAdd", "Adds a weather object by type", "consoleCommandWeatherAdd", self)
        addConsoleCommand("gsWeatherTwisterSpawn", "Adds a twister at current position in current direction", "consoleCommandWeatherTwisterSpawn", self)
        addConsoleCommand("gsWeatherSetDebugWind", "Sets wind data", "consoleCommandWeatherSetDebugWind", self)
        addConsoleCommand("gsWeatherSetClouds", "Sets cloud data", "consoleCommandWeatherSetClouds", self)
        addConsoleCommand("gsWeatherToggleRandomWindWaving", "Toggles waving of random wind", "consoleCommandWeatherToggleRandomWindWaving", self)
    end
    return self
end
function Weather:load(xmlFile, key, baseDirectory)
    self.forecastItems = {}
    self.weatherObjects = {}
    self.weightedWeatherObjects = {}
    for _, season in pairs(Season.getAllOrdered()) do
        self.weatherObjects[season] = {}
        self.weightedWeatherObjects[season] = {}
        self.typeToWeatherObject[season] = {}
        self.seasonToFog = {}
    end
    self.rainUpdater:load(xmlFile, key .. ".weather.rain", baseDirectory)
    self.cloudUpdater:load(xmlFile, key .. ".weather.clouds", baseDirectory)
    local envMapCloudPresetIds = {}
    xmlFile:iterate(key .. ".weather.envMap.cloudProbe", function(_, cloudProbeKey)
        -- upvalues: (copy) xmlFile, (copy) envMapCloudPresetIds, (copy) self
        local presetId = xmlFile:getString(cloudProbeKey .. "#presetId")
        if presetId == nil then
            Logging.xmlWarning(xmlFile, "Missing clouds presetId for \'%s\'", cloudProbeKey)
            return false
        end
        if #envMapCloudPresetIds == 3 then
            Logging.xmlWarning(xmlFile, "Only 3 different envmap types are supported for \'%s\'", cloudProbeKey)
            return false
        end
        if self.cloudUpdater:getPreset(presetId) == nil then
            Logging.xmlWarning(xmlFile, "Clouds presetId \'%s\' is not defined for \'%s\'", presetId, cloudProbeKey)
            return false
        end
        table.insert(envMapCloudPresetIds, presetId)
        return true
    end)
    local cloudPresets = self.cloudUpdater:getPresets()
    if #envMapCloudPresetIds == 0 then
        Logging.xmlWarning(xmlFile, "No env map cloud probes defined. Adding first cloud preset")
        local _, _ = next(cloudPresets)
        table.insert(envMapCloudPresetIds, _.id)
    end
    for _, preset in pairs(cloudPresets) do
        if envMapCloudPresetIds[preset.envMapCloudProbeIndex] == nil then
            Logging.xmlWarning(xmlFile, "Invalid envMapCloudProbeIndex for cloud preset \'%s\'. Using 1 instead", preset.id)
            preset.envMapCloudProbeIndex = 1
        end
    end
    self.envMapCloudProbes = {}
    for _, preset in ipairs(envMapCloudPresetIds) do
        local cloudSettings = self.cloudUpdater:createCloudSettingsFromPreset(preset)
        assert(cloudSettings ~= nil)
        table.insert(self.envMapCloudProbes, cloudSettings)
    end
    local _ = 2 ^ Weather.SEND_BITS_OBJECT_INDEX - 1
    for preset, cloudSettings in xmlFile:iterator(key .. ".weather.season") do
        _ = _ - self:loadWeatherObjects(xmlFile, cloudSettings, _)
        local seasonName = xmlFile:getString(cloudSettings .. "#name")
        local season = Season.getByName(seasonName) or Season.SUMMER
        local fog = FogSettings.new()
        if xmlFile:hasProperty(cloudSettings .. ".fog") then
            fog:loadTemplate(xmlFile, cloudSettings .. ".fog")
        end
        self.seasonToFog[season] = fog
    end
    self.firstWeatherType = self.firstWeatherType or WeatherType.SUN or (WeatherType.CLOUDY or WeatherType.RAIN)
    if self.skyBoxUpdater ~= nil and not self.skyBoxUpdater:load(xmlFile, key .. ".skyBox") then
        self.skyBoxUpdater:delete()
        self.skyBoxUpdater = nil
    end
    self:randomizeFog(1)
    if g_server ~= nil then
        self:addStartWeather()
        self:fillWeatherForecast()
        self:init()
    end
    self.forecast:load()
    self.temperatureUpdater:setDayLength(self.owner.dayLength)
    g_messageCenter:unsubscribeAll(self)
    g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
    g_messageCenter:subscribe(MessageType.TIMESCALE_CHANGED, self.onTimeScaleChanged, self)
    g_messageCenter:subscribe(MessageType.PERIOD_LENGTH_CHANGED, self.onPeriodLengthChanged, self)
    g_messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, self.onGameStateChanged, self)
    if Platform.gameplay.supportsTwister then
        local _ = Twister.new
        local _ = g_client ~= nil
        local _ = _(g_server ~= nil, _)
        if _:load(xmlFile, key .. ".weather.twister", baseDirectory) then
            _:register(true)
            self.twister = _
            return
        end
        _:delete()
    end
end
function Weather:loadWeatherObjects(xmlFile, key, maxObjects)
    local seasonName = xmlFile:getString(key .. "#name")
    if seasonName == nil then
        Logging.xmlError(xmlFile, "No season name given in \'%s\'", key)
        return 0
    end
    local season = Season.getByName(seasonName)
    if season == nil then
        Logging.xmlError(xmlFile, "Invalid season name \'%s\' given in \'%s\'", seasonName, key)
        return 0
    end
    local numAdded = 0
    for _, objectKey in xmlFile:iterator(key .. ".object") do
        if maxObjects < #self.weatherObjects[season] then
            Logging.warning("Weather object limit (%d) reached at \'%s\'", maxObjects, objectKey)
            return numAdded
        end
        local typeName = xmlFile:getString(objectKey .. "#typeName")
        local weatherType = WeatherType.getByName(typeName)
        if weatherType == nil then
            Logging.xmlWarning(xmlFile, "Invalid weather type \'%s\' in \'%s\'", typeName, objectKey)
        elseif self.isRainAllowed or weatherType ~= WeatherType.RAIN and weatherType ~= WeatherType.SNOW then
            if self.typeToWeatherObject[season][weatherType] == nil then
                local className = xmlFile:getString(objectKey .. "#class")
                local classObject = ClassUtil.getClassObject(className)
                if classObject == nil then
                    Logging.xmlWarning(xmlFile, "Class \'%s\' not found in \'%s\'", tostring(className), objectKey)
                elseif classObject:isa(WeatherObject) then
                    local instance = classObject.new(weatherType, self.cloudUpdater, self.temperatureUpdater, self.windUpdater, self.rainUpdater)
                    if instance:load(xmlFile, objectKey) then
                        if xmlFile:getBool(objectKey .. "#isFirstWeather") then
                            self.firstWeatherType = weatherType
                        end
                        table.insert(weatherObjects, instance)
                        instance.index = #weatherObjects
                        instance.season = season
                        typeToWeatherObject[weatherType] = instance
                        if instance:getIsAvailable() then
                            for i = 1, instance.weight do
                                table.insert(self.weightedWeatherObjects[season], instance.index)
                            end
                        end
                    end
                else
                    Logging.xmlWarning(xmlFile, "Given class \'%s\' is not a WeatherObject in \'%s\'", tostring(className), objectKey)
                end
            else
                Logging.xmlWarning(xmlFile, "WeatherObject for type \'%s\' already defined in \'%s\'", typeName, objectKey)
            end
        end
    end
    return numAdded
end
function Weather:delete()
    removeConsoleCommand("gsWeatherSet")
    removeConsoleCommand("gsWeatherAdd")
    removeConsoleCommand("gsWeatherDebug")
    removeConsoleCommand("gsWeatherSetWindState")
    removeConsoleCommand("gsWeatherReload")
    removeConsoleCommand("gsWeatherSetDebugWind")
    removeConsoleCommand("gsWeatherSetClouds")
    removeConsoleCommand("gsWeatherToggleRandomWindWaving")
    removeConsoleCommand("gsWeatherTwisterSpawn")
    delete(self.temperatureDebugOverlayCurrent)
    self.temperatureDebugGraph:delete()
    self.windUpdater:removeWindChangedListener(self.cloudUpdater)
    self.windUpdater:removeWindChangedListener(self.rainUpdater)
    self.rainUpdater:delete()
    for _, seasonWeatherObjects in pairs(self.weatherObjects) do
        for _, weatherObject in ipairs(seasonWeatherObjects) do
            weatherObject:delete()
        end
    end
    self.weatherObjects = {}
    if self.skyBoxUpdater ~= nil then
        self.skyBoxUpdater:delete()
    end
    self.forecast:delete()
    g_messageCenter:unsubscribeAll(self)
end
function Weather:saveToXMLFile(xmlFileHandle, key)
    local xmlFile = XMLFile.wrap(xmlFileHandle)
    for k, instance in ipairs(self.forecastItems) do
        instance:saveToXMLFile(xmlFile, (string.format("%s.forecast.instance(%d)", key, k - 1)))
    end
    self.fogUpdater:saveToXMLFile(xmlFile, key .. ".fog")
    xmlFile:setFloat(key .. ".snow#height", self.snowHeight)
    xmlFile:setFloat(key .. ".ground#wetness", self.groundWetness)
    local instance = MathUtil.msToMinutes(self.timeSinceLastRain)
    xmlFile:setInt(key .. "#timeSinceLastRain", (math.round(instance)))
    if self.twister ~= nil then
        self.twister:saveToXMLFile(xmlFile, key .. ".twister")
    end
    xmlFile:delete()
end
function Weather:loadFromXMLFile(xmlFileHandle, key)
    local xmlFile = XMLFile.wrap(xmlFileHandle)
    local currentInstance = self.forecastItems[1]
    self:getWeatherObjectByIndex(currentInstance.season, currentInstance.objectIndex):deactivate(1)
    self.forecastItems = {}
    local lastStartDay = nil
    local lastStartDayTime = nil
    for _, instanceKey in xmlFile:iterator(key .. ".forecast.instance") do
        local instance = WeatherInstance.new()
        if not instance:loadFromXMLFile(xmlFile, instanceKey) or instance.startDay == lastStartDay and instance.startDayTime == lastStartDayTime then
            break
        end
        self:addWeatherForecast(instance)
    end
    local lastInstance = self.forecastItems[#self.forecastItems]
    if lastInstance ~= nil then
        local _ = 86400000 - lastInstance.startDayTime - lastInstance.duration
        if _ > 0 and _ < 10800000 then
            lastInstance.duration = 86400000 - lastInstance.startDayTime
            Logging.info("Found broken weather forecast: Adjusted duration from %d to %d", lastInstance.duration, lastInstance.duration)
        end
    end
    self.fogUpdater:loadFromXMLFile(xmlFile, key .. ".fog")
    self.timeSinceLastRain = MathUtil.minutesToMs(xmlFile:getInt(key .. "#timeSinceLastRain", 0)) or self.timeSinceLastRain
    self.snowHeight = xmlFile:getFloat(key .. ".snow#height", self.snowHeight)
    self.groundWetness = xmlFile:getFloat(key .. ".ground#wetness", self.groundWetness)
    if self.twister ~= nil then
        self.twister:loadFromXMLFile(xmlFile, key .. ".twister")
    end
    xmlFile:delete()
    self:fillWeatherForecast()
    self.cloudUpdater:setTimeScale(g_currentMission:getEffectiveTimeScale())
    self:init(true)
end
function Weather:update(dt)
    local scaledDt = dt * g_currentMission:getEffectiveTimeScale()
    if #self.forecastItems >= 2 then
        local nextInstance = self.forecastItems[2]
        local currentInstance = self.forecastItems[1]
        local currentWeatherObject = self:getWeatherObjectByIndex(currentInstance.season, currentInstance.objectIndex)
        if self.owner.currentMonotonicDay > nextInstance.startDay or self.owner.currentMonotonicDay == nextInstance.startDay and self.owner.dayTime > nextInstance.startDayTime then
            currentWeatherObject:deactivate(self.cheatedTime and 0 or Weather.CHANGE_DURATION)
            local nextWeatherObject = self:getWeatherObjectByIndex(nextInstance.season, nextInstance.objectIndex)
            nextWeatherObject:activate(nextInstance, duration)
            if nextWeatherObject.setWindValues ~= nil then
                local windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor = self.windUpdater:getCurrentValues()
                nextWeatherObject:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
            end
            self:onWeatherChanged(nextWeatherObject)
            table.remove(self.forecastItems, 1)
            if g_server ~= nil then
                self:fillWeatherForecast()
            end
        elseif self.cheatedTime then
            self.cheatedTime = nil
            local duration = self:getRainFallScale()
            local nextWeatherObject = self:getHailFallScale()
            local windDirX = self:getSnowFallScale()
            if duration == 0 and (nextWeatherObject == 0 and windDirX == 0) then
                self.groundWetness = 0
            end
        end
        local duration = not (self:getIsRaining() or self:getIsHailing())
        if duration then
            duration = not self:getIsSnowing()
        end
        if duration then
            self.timeSinceLastRain = self.timeSinceLastRain + scaledDt
        else
            self.timeSinceLastRain = 0
        end
    elseif g_server ~= nil then
        self:fillWeatherForecast()
    end
    for duration, nextWeatherObject in pairs(self.weatherObjects) do
        for cirrusCloudSpeedFactor, weatherObject in ipairs(nextWeatherObject) do
            weatherObject:update(scaledDt)
        end
    end
    self.cloudUpdater:update(scaledDt)
    self.temperatureUpdater:update(scaledDt)
    self.windUpdater:update(scaledDt)
    self.fogUpdater:update(scaledDt)
    self.rainUpdater:update(scaledDt)
    if self.skyBoxUpdater ~= nil then
        self.skyBoxUpdater:update(scaledDt, self.owner.dayTime, self:getRainFallScale(), self:getTimeUntilRain())
    end
    local nextInstance = self.temperatureUpdater:getTemperatureAtTime(self.owner.dayTime)
    local currentInstance = g_currentMission:getEffectiveTimeScale()
    if g_currentMission.missionInfo.isSnowEnabled then
        if self:getIsSnowing() and nextInstance < 3 then
            local currentWeatherObject = 1 - math.max(0, nextInstance) / 4
            local nextWeatherObject = self.snowHeight + 0.0003 * (dt / 1000) * (currentInstance / 100) * self:getSnowFallScale() * currentWeatherObject
            self.snowHeight = math.clamp(nextWeatherObject, 0, 0.5)
        elseif nextInstance >= 5 then
            self.snowHeight = 0
        elseif nextInstance > 2 and self.snowHeight > 0 then
            local currentWeatherObject = self:getIsRaining() and 3 or 1
            self.snowHeight = math.clamp(self.snowHeight - nextInstance * 0.001 * (dt / 1000) * (currentInstance / 100) * currentWeatherObject, 0, 0.5)
        end
    else
        self.snowHeight = 0
    end
    local currentWeatherObject
    if self.timeSinceLastRain == 0 then
        local nextWeatherObject = self:getRainFallScale()
        local windDirX = self:getSnowFallScale()
        local duration = math.max(nextWeatherObject, windDirX, self:getHailFallScale())
        currentWeatherObject = scaledDt / self.groundWetnessWetDuration * duration
    else
        currentWeatherObject = -(scaledDt / self.groundWetnessDryDuration)
    end
    local nextWeatherObject = self.groundWetness + currentWeatherObject
    self.groundWetness = math.clamp(nextWeatherObject, 0, 1)
    g_currentMission.snowSystem:setSnowHeight(self.snowHeight)
    local duration = self:getGroundWetness()
    local cirrusCloudSpeedFactor = duration - 0.15
    local windDirX = math.max(0, cirrusCloudSpeedFactor) / 0.85
    setWetness(duration)
    setTerrainDisplacementWetness(g_terrainNode, windDirX)
end
function Weather:draw()
    if Weather.DEBUG_ENABLED then
        local data = {}
        local currentMin, currentMax = self.temperatureUpdater:getCurrentValues(self.owner.dayTime)
        local current = self.temperatureUpdater:getTemperatureAtTime(self.owner.dayTime)
        table.insert(data, {
            ["name"] = "TEMPERATURE",
            ["value"] = ""
        })
        local windVelocity = {
            ["name"] = "current",
            ["value"] = string.format("%.2f\194\176", current)
        }
        table.insert(data, windVelocity)
        local windVelocity = {
            ["name"] = "currentMin",
            ["value"] = string.format("%.2f\194\176", currentMin)
        }
        table.insert(data, windVelocity)
        local windVelocity = {
            ["name"] = "currentMax",
            ["value"] = string.format("%.2f\194\176", currentMax)
        }
        table.insert(data, windVelocity)
        table.insert(data, {
            ["name"] = "",
            ["value"] = ""
        })
        table.insert(data, {
            ["name"] = "SNOW",
            ["value"] = ""
        })
        local windVelocity = {
            ["name"] = "height",
            ["value"] = string.format("%.5f", self.snowHeight)
        }
        table.insert(data, windVelocity)
        local windVelocity = {
            ["name"] = "shader",
            ["value"] = string.format("%.5f", g_currentMission.snowSystem.snowShaderValue)
        }
        table.insert(data, windVelocity)
        table.insert(data, {
            ["name"] = "",
            ["value"] = ""
        })
        local windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor = self.windUpdater:getCurrentValues()
        table.insert(data, {
            ["name"] = "WIND",
            ["value"] = ""
        })
        table.insert(data, {
            ["name"] = "dirX",
            ["value"] = string.format("%.3f", windDirX)
        })
        table.insert(data, {
            ["name"] = "dirZ",
            ["value"] = string.format("%.3f", windDirZ)
        })
        table.insert(data, {
            ["name"] = "velocity",
            ["value"] = MathUtil.mpsToKmh(windVelocity)
        })
        table.insert(data, {
            ["name"] = "cirrusSpeedFactor",
            ["value"] = cirrusCloudSpeedFactor
        })
        table.insert(data, {
            ["name"] = "cShared0",
            ["value"] = string.format("%.2f", self.windUpdater.sharedShaderParamValueWindSpeed)
        })
        table.insert(data, {
            ["name"] = "cShared1",
            ["value"] = string.format("%.2f", self.windUpdater.sharedShaderParamValueWindDirX)
        })
        table.insert(data, {
            ["name"] = "cShared2",
            ["value"] = string.format("%.2f", self.windUpdater.sharedShaderParamValueWindDirZ)
        })
        table.insert(data, {
            ["name"] = "",
            ["value"] = ""
        })
        table.insert(data, {
            ["name"] = "RAIN",
            ["value"] = ""
        })
        table.insert(data, {
            ["name"] = "timeSince",
            ["value"] = string.format("%.2f", self:getTimeSinceLastRain())
        })
        table.insert(data, {
            ["name"] = "rainFallScale",
            ["value"] = string.format("%.2f", self:getRainFallScale())
        })
        table.insert(data, {
            ["name"] = "snowFallScale",
            ["value"] = string.format("%.2f", self:getSnowFallScale())
        })
        table.insert(data, {
            ["name"] = "groundWetness",
            ["value"] = string.format("%.2f", self:getGroundWetness())
        })
        table.insert(data, {
            ["name"] = "",
            ["value"] = "",
            ["columnOffset"] = 0.12
        })
        self.fogUpdater:addDebugValues(data)
        table.insert(data, {
            ["name"] = "",
            ["value"] = "",
            ["columnOffset"] = 0.12
        })
        self.cloudUpdater:addDebugValues(data)
        table.insert(data, {
            ["name"] = "",
            ["value"] = "",
            ["columnOffset"] = 0.12
        })
        self.rainUpdater:addDebugValues(data)
        table.insert(data, {
            ["name"] = "",
            ["value"] = "",
            ["columnOffset"] = 0.12
        })
        if self.skyBoxUpdater ~= nil then
            self.skyBoxUpdater:addDebugValues(data)
            table.insert(data, {
                ["name"] = "",
                ["value"] = "",
                ["columnOffset"] = 0.12
            })
        end
        for k, instance in ipairs(self.forecastItems) do
            local weatherObject = self:getWeatherObjectByIndex(instance.season, instance.objectIndex)
            local rainPreset = weatherObject.variations[instance.variationIndex].rainPresetId or "nil"
            local text = string.format("Var %d | Active | Duration %d | Season %s | RainPreset %s", instance.variationIndex, instance.duration / 3600000, Season.getName(instance.season), rainPreset)
            if k > 1 then
                if instance.startDay - self.owner.currentMonotonicDay == 0 then
                    text = string.format("Var %d | In %d minutes | Duration %d | Season %s | RainPreset %s", instance.variationIndex, (instance.startDayTime - self.owner.dayTime) / 60000, instance.duration / 3600000, Season.getName(instance.season), rainPreset)
                else
                    text = string.format("Var %d | In %d days | Duration %d | Season %s | RainPreset %s", instance.variationIndex, dayDif, instance.duration / 3600000, Season.getName(instance.season), rainPreset)
                end
            end
            table.insert(data, {
                ["name"] = WeatherType.getName(weatherObject.weatherType),
                ["value"] = text
            })
        end
        DebugUtil.renderTable(0.2, 0.46, 0.011, data)
        local graph = self.temperatureDebugGraph
        local k = 1
        for k = k, 24 do
            graph:setValue(k, (self.temperatureUpdater:getTemperatureAtTime(k * 60 * 60 * 1000)))
        end
        graph:draw()
        renderOverlay(self.temperatureDebugOverlayCurrent, graph.left + self.owner.dayTime / self.owner.dayLength * graph.width, graph.bottom, g_pixelSizeX, graph.height)
        local k, instance, dayDif = getWorldTranslation((g_cameraManager:getActiveCamera()))
        local weatherObject, rainPreset, text = localDirectionToWorld(camera, 0, 0, -1)
        local k = k + 10 * weatherObject
        local instance = instance + 10 * rainPreset
        local dayDif = dayDif + 10 * text
        drawDebugArrow(k, instance + 2, dayDif, windDirX * 3, 0, windDirZ * 3, 0.3, 0.3, 0.3, 1, 1, 1, false)
    end
end
function Weather:sendInitialState(connection)
    connection:sendEvent(WeatherStateEvent.new(self.snowHeight, self.timeSinceLastRain))
    connection:sendEvent(WeatherAddObjectEvent.new(self.forecastItems, true, true))
end
function Weather:setInitialState(snowHeight, timeSinceLastRain)
    self.snowHeight = snowHeight
    self.timeSinceLastRain = timeSinceLastRain
    g_currentMission.snowSystem:setSnowHeight(self.snowHeight)
end
function Weather:setIsRainAllowed(isRainAllowed)
    self.isRainAllowed = isRainAllowed
end
function Weather:init(isSavegameInit)
    local currentInstance = self.forecastItems[1]
    local weatherObject = self:getWeatherObjectByIndex(currentInstance.season, currentInstance.objectIndex)
    weatherObject:activate(currentInstance, 0, isSavegameInit)
    if weatherObject.setWindValues ~= nil then
        local windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor = self.windUpdater:getCurrentValues()
        weatherObject:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
    end
    self:onWeatherChanged(weatherObject)
    g_currentMission.snowSystem:setSnowHeight(self.snowHeight)
end
function Weather.onWeatherChanged(_, weatherObject)
    g_messageCenter:publish(MessageType.WEATHER_CHANGED, weatherObject)
end
function Weather:rebuild()
    if g_currentMission:getIsServer() then
        local currentWeatherObject = self:getWeatherObjectByIndex(self.forecastItems[1].season, self.forecastItems[1].objectIndex)
        currentWeatherObject:deactivate(1)
        currentWeatherObject:update(9999999)
        self.forecastItems = {}
        self:addStartWeather()
        self:fillWeatherForecast(true)
    end
end
function Weather:getRandomWeatherObjectVariation(season, firstWeather)
    local weatherObject = self.typeToWeatherObject[season][self.firstWeatherType]
    if weatherObject == nil or not firstWeather then
        local weatherObjectIndex = self.weightedWeatherObjects[season][math.random(1, #self.weightedWeatherObjects[season])]
        weatherObject = self.weatherObjects[season][weatherObjectIndex]
    end
    local weatherObjectIndex = weatherObject:getRandomVariationIndex()
    return weatherObject.index, weatherObjectIndex
end
function Weather:getWeatherObjectByIndex(season, index)
    return self.weatherObjects[season][index]
end
function Weather:getForecastInstanceVariation(instance)
    return self.weatherObjects[instance.season][instance.objectIndex]:getVariationByIndex(instance.variationIndex)
end
function Weather:updateAvailableWeatherObjects()
    for season, objects in pairs(self.typeToWeatherObject) do
        self.weightedWeatherObjects[season] = {}
        for weatherType, weatherObject in pairs(objects) do
            if weatherObject:getIsAvailable() then
                for i = 1, weatherObject.weight do
                    table.insert(self.weightedWeatherObjects[season], weatherObject.index)
                end
            end
        end
    end
end
function Weather:addStartWeather()
    local startDay = self.owner.currentMonotonicDay
    local endDay, endDayTime = self.owner:getDayAndDayTime(self.owner.dayTime, startDay)
    local season = self.owner:getVisualSeasonAtDay(startDay)
    self:updateAvailableWeatherObjects()
    self:addWeatherForecast((self:createRandomWeatherInstance(season, endDay, endDayTime, true)))
end
function Weather:fillWeatherForecast(isRebuild)
    self:updateAvailableWeatherObjects()
    local newObjects = {}
    local lastItem = self.forecastItems[#self.forecastItems]
    local maxNumOfforecastItemsItems = 2 ^ Weather.SEND_BITS_NUM_OBJECTS - 1
    while (lastItem == nil or lastItem.startDay < self.owner.currentMonotonicDay + 9) and #self.forecastItems < maxNumOfforecastItemsItems do
        local startDay = self.owner.currentMonotonicDay
        local startDayTime = self.owner.dayTime
        if lastItem ~= nil then
            startDay = lastItem.startDay
            startDayTime = lastItem.startDayTime + lastItem.duration
        end
        local endDay, endDayTime = self.owner:getDayAndDayTime(startDayTime, startDay)
        local weatherInstance = self:createRandomWeatherInstance(self.owner:getVisualSeasonAtDay(endDay), endDay, endDayTime, false)
        self:addWeatherForecast(weatherInstance)
        table.insert(newObjects, weatherInstance)
        lastItem = self.forecastItems[#self.forecastItems]
    end
    if #newObjects > 0 then
        if isRebuild then
            newObjects = self.forecastItems
        end
        g_server:broadcastEvent(WeatherAddObjectEvent.new(newObjects, isRebuild or false), false)
    end
end
function Weather:createRandomWeatherInstance(season, startDay, startDayTime, firstWeather)
    local weatherObjectIndex, weatherObjectVariationIndex = self:getRandomWeatherObjectVariation(season, firstWeather)
    local variation = self:getWeatherObjectByIndex(season, weatherObjectIndex):getVariationByIndex(weatherObjectVariationIndex)
    local duration = MathUtil.hoursToMs
    local seasonNextDay = math.random(variation.minHours, variation.maxHours)
    local duration = duration((math.max(seasonNextDay, 1)))
    local isSeasonBoundary = season ~= self.owner:getVisualSeasonAtDay(startDay + 1)
    local wholeDay, timeBeforeMidnight = math.modf(startDayTime)
    if isSeasonBoundary then
        if wholeDay + duration > 86400000 then
            duration = 86400000 - wholeDay
        end
        local timeBeforeMidnight = 86400000 - wholeDay - duration
        if timeBeforeMidnight > 0 and timeBeforeMidnight < 10800000 then
            duration = 86400000 - wholeDay
        end
    end
    return WeatherInstance.createInstance(weatherObjectIndex, weatherObjectVariationIndex, startDay, wholeDay, duration, season)
end
function Weather:addWeatherForecast(weatherInstance)
    table.insert(self.forecastItems, weatherInstance)
end
function Weather:getIsReady()
    return #self.forecastItems > 0
end
function Weather:onTimeScaleChanged()
    self.cloudUpdater:setTimeScale(g_currentMission:getEffectiveTimeScale())
end
function Weather:getForecast()
    return self.forecast
end
function Weather:getRainFallScale()
    return self.rainUpdater:getRainFallScale()
end
function Weather:getSnowFallScale()
    return self.rainUpdater:getSnowFallScale()
end
function Weather:getHailFallScale()
    return self.rainUpdater:getHailFallScale()
end
function Weather:getIsHailing()
    return self:getHailFallScale() > 0.05
end
function Weather:getIsRaining()
    return self:getRainFallScale() > 0.05
end
function Weather:getIsSnowing()
    return self:getSnowFallScale() > 0.05
end
function Weather:getCloudEnvMapInfo()
    local cloudUpdater = self.cloudUpdater
    return cloudUpdater.lastClouds.envMapCloudProbeIndex, cloudUpdater.targetClouds.envMapCloudProbeIndex, cloudUpdater.alpha
end
function Weather:getTimeUntilRain()
    local k = 1
    for k = k, #self.forecastItems do
        local instance = self.forecastItems[k]
        local object = self:getWeatherObjectByIndex(instance.season, instance.objectIndex)
        if instance.startDay == self.owner.currentMonotonicDay and (object.weatherType == WeatherType.RAIN or object.weatherType == WeatherType.SNOW) and self.owner.dayTime < instance.startDayTime then
            return instance.startDayTime - self.owner.dayTime
        end
    end
    return math.huge
end
function Weather:getTimeSinceLastRain()
    return MathUtil.msToMinutes(self.timeSinceLastRain)
end
function Weather:getGroundWetness()
    return self.groundWetness
end
function Weather:getWeatherTypeAtTime(day, dayTime)
    if g_client ~= nil and #self.forecastItems == 0 then
        return WeatherType.SUN
    end
    local instance = self.forecastItems[1]
    for _, object in ipairs(self.forecastItems) do
        if object.startDay >= day and (object.startDay ~= day or object.startDayTime >= dayTime) then
            break
        end
        instance = object
    end
    return self:getWeatherObjectByIndex(instance.season, instance.objectIndex).weatherType
end
function Weather:getCurrentMinMaxTemperatures()
    return self.temperatureUpdater:getCurrentValues()
end
function Weather:getCurrentTemperature()
    return self.temperatureUpdater:getTemperatureAtTime(self.owner.dayTime)
end
function Weather:getCurrentTemperatureTrend()
    local currentVariation = self:getForecastInstanceVariation(self.forecastItems[1])
    local nextVariation = self:getForecastInstanceVariation(self.forecastItems[2])
    local change = (currentVariation.minTemperature + currentVariation.maxTemperature) * 0.5 - (nextVariation.minTemperature + nextVariation.maxTemperature) * 0.5
    local trend = 0
    if math.abs(change) > Weather.TEMPERATURE_STABLE_CHANGE then
        trend = math.sign(change)
    end
    return trend
end
function Weather:getCurrentWeatherType()
    local instance = self.forecastItems[1]
    return self:getWeatherObjectByIndex(instance.season, instance.objectIndex).weatherType
end
function Weather:getNextWeatherType(beforeDay, beforeTime)
    local instance = self.forecastItems[2]
    if beforeDay < instance.startDay or instance.startDay == beforeDay and beforeTime < instance.startDayTime then
        instance = self.forecastItems[1]
    end
    return self:getWeatherObjectByIndex(instance.season, instance.objectIndex).weatherType
end
function Weather:getWeatherObjectBySeasonAndType(season, weatherType)
    local types = self.typeToWeatherObject[season]
    if types == nil then
        return nil
    else
        return types[weatherType]
    end
end
function Weather:randomizeFog(fadeDuration)
    local fog = self.seasonToFog[self.owner.currentSeason]
    local newSeasonFog = nil
    if fog ~= nil then
        newSeasonFog = fog:createFromTemplate()
    end
    self.fogUpdater:setTargetFog(newSeasonFog, fadeDuration)
end
function Weather:onDayChanged(_)
    self:randomizeFog(MathUtil.hoursToMs(1))
end
function Weather:onPeriodLengthChanged()
    self:rebuild()
end
function Weather:onGameStateChanged(newGameState, _)
    if self.rainUpdater ~= nil then
        self.rainUpdater:setVisible(not (newGameState == GameState.MENU_SHOP_CONFIG))
    end
end
function Weather:consoleCommandWeatherTwisterSpawn()
    local currentWeatherInstance = self.forecastItems[1]
    local currentWeatherObject = nil
    if currentWeatherInstance ~= nil then
        currentWeatherObject = self:getWeatherObjectByIndex(currentWeatherInstance.season, currentWeatherInstance.objectIndex)
    end
    self.forecastItems = {}
    local weatherType = WeatherType.getByName("TWISTER")
    if weatherType ~= nil then
        local weatherObject = self.typeToWeatherObject[g_currentMission.environment.currentSeason][weatherType]
        if weatherObject ~= nil then
            local variation = weatherObject:getVariationByIndex(weatherObject:getRandomVariationIndex())
            local duration = MathUtil.hoursToMs(math.random(variation.minHours, variation.maxHours))
            local index = 3
            local currentInstance = self.forecastItems[2]
            if currentInstance == nil then
                index = 2
                if self.forecastItems[1] == nil then
                    index = 1
                end
            end
            local startDay = self.owner.currentMonotonicDay
            local startDayTime = self.owner.dayTime
            if currentInstance ~= nil then
                startDay = currentInstance.startDay
                startDayTime = currentInstance.startDayTime
            end
            local instance, x = self.owner:getDayAndDayTime(startDayTime + duration, startDay)
            local instance = WeatherInstance.createInstance(weatherObject.index, variation.index, instance, x, duration, env.currentSeason)
            local x, _, z = g_localPlayer:getPosition()
            instance.twisterStartPosX = x
            instance.twisterStartPosZ = z
            table.insert(self.forecastItems, index, instance)
            self:fillWeatherForecast()
            if currentWeatherObject ~= nil then
                currentWeatherObject:deactivate(1)
                currentWeatherObject:update(9999999)
            end
            self:init()
            local rotationY = g_localPlayer:getYaw()
            local windDirX, windDirZ = MathUtil.getDirectionFromYRotation(rotationY)
            self.windUpdater.targetDirX = windDirX
            self.windUpdater.targetDirZ = windDirZ
            return "Spawned twister"
        end
    end
    return "Failed to spawn twister"
end
function Weather:consoleCommandWeatherSet(typeName, variationIndex)
    local env = g_currentMission.environment
    local currentWeatherInstance = tonumber(variationIndex)
    local currentWeatherInstance = self.forecastItems[1]
    local currentWeatherObject = nil
    if currentWeatherInstance ~= nil then
        currentWeatherObject = self:getWeatherObjectByIndex(currentWeatherInstance.season, currentWeatherInstance.objectIndex)
    end
    self.forecastItems = {}
    local weatherType = WeatherType.getByName(typeName)
    if weatherType ~= nil then
        local weatherObject = self.typeToWeatherObject[env.currentSeason][weatherType]
        if weatherObject ~= nil then
            local variation = weatherObject:getVariationByIndex(currentWeatherInstance or weatherObject:getRandomVariationIndex())
            if variation == nil then
                variation = weatherObject:getVariationByIndex(weatherObject:getRandomVariationIndex())
            end
            local duration = MathUtil.hoursToMs(math.random(variation.minHours, variation.maxHours))
            local index = 3
            local currentInstance = self.forecastItems[2]
            if currentInstance == nil then
                index = 2
                if self.forecastItems[1] == nil then
                    index = 1
                end
            end
            local startDay = self.owner.currentMonotonicDay
            local startDayTime = self.owner.dayTime
            if currentInstance ~= nil then
                startDay = currentInstance.startDay
                startDayTime = currentInstance.startDayTime
            end
            local instance, startDayTime = self.owner:getDayAndDayTime(startDayTime + duration, startDay)
            local instance = WeatherInstance.createInstance(weatherObject.index, variation.index, instance, startDayTime, duration, env.currentSeason)
            table.insert(self.forecastItems, index, instance)
            self:fillWeatherForecast()
            if currentWeatherObject ~= nil then
                currentWeatherObject:deactivate(1)
                currentWeatherObject:update(9999999)
            end
            self:init()
            return string.format("Set weather to \'%s\'", string.upper(typeName))
        end
    end
    local weatherObject = {}
    for currentInstance, startDay in pairs(self.typeToWeatherObject[env.currentSeason]) do
        table.insert(weatherObject, WeatherType.getName(currentInstance))
    end
    return string.format("Invalid typeName \'%s\': gsWeatherSet <typeName> <variation> | Available typeNames for current season: %s", typeName, table.concat(weatherObject, ", "))
end
function Weather:consoleCommandWeatherAdd(typeName)
    local env = g_currentMission.environment
    local weatherType = WeatherType.getByName(typeName)
    if weatherType ~= nil then
        local weatherObject = self.typeToWeatherObject[env.currentSeason][weatherType]
        if weatherObject ~= nil then
            local variation = weatherObject:getVariationByIndex(weatherObject:getRandomVariationIndex())
            local duration = MathUtil.hoursToMs(math.random(variation.minHours, variation.maxHours))
            local index = 3
            local currentInstance = self.forecastItems[2]
            if currentInstance == nil then
                index = 2
                if self.forecastItems[1] == nil then
                    index = 1
                end
            end
            local startDay = self.owner.currentMonotonicDay
            local startDayTime = self.owner.dayTime
            if currentInstance ~= nil then
                startDay = currentInstance.startDay
                startDayTime = currentInstance.startDayTime
            end
            local instance, timeDif = self.owner:getDayAndDayTime(startDayTime + currentInstance.duration, startDay)
            local instance = WeatherInstance.createInstance(weatherObject.index, variation.index, instance, timeDif, duration, env.currentSeason)
            local timeDif = (instance.startDayTime - self.owner.dayTime) / 60000 + (instance - self.owner.currentMonotonicDay) * 24 * 60
            table.insert(self.forecastItems, index, instance)
            local i = index + 1
            for i = i, #self.forecastItems do
                local forecastItem = self.forecastItems[i]
                forecastItem.startDay, forecastItem.startDayTime = self.owner:getDayAndDayTime(timeDif + duration, instance)
            end
            return string.format("Added state %s. Starts in %d minutes...", typeName, timeDif)
        end
    end
    local weatherObject = {}
    for currentInstance, startDay in pairs(self.typeToWeatherObject[env.currentSeason]) do
        table.insert(weatherObject, WeatherType.getName(currentInstance))
    end
    return string.format("Invalid typeName \'%s\': gsWeatherAdd <typeName> | Available typeNames for current season: %s", typeName, table.concat(weatherObject, ", "))
end
function Weather:consoleCommandWeatherToggleDebug()
    Weather.DEBUG_ENABLED = not Weather.DEBUG_ENABLED
    if Weather.DEBUG_ENABLED then
        g_currentMission:addDrawable(self)
    else
        g_currentMission:removeDrawable(self)
    end
    return "Weather Debug Enabled: " .. tostring(Weather.DEBUG_ENABLED)
end
function Weather:consoleCommandWeatherReloadData()
    local xmlFile = XMLFile.load("weather", self.owner.xmlFilename)
    local forecastItem = self.forecastItems[1]
    if forecastItem ~= nil then
        local currentWeatherObject = self:getWeatherObjectByIndex(forecastItem.season, forecastItem.objectIndex)
        currentWeatherObject:deactivate(1)
        currentWeatherObject:update(9999999)
    end
    for season, objects in ipairs(self.weatherObjects) do
        for _, object in ipairs(objects) do
            object:delete()
        end
    end
    self.weatherObjects = {}
    self.rainUpdater:reset()
    self:load(xmlFile, "environment")
    xmlFile:delete()
    return "Reloaded weather data"
end
function Weather:consoleCommandWeatherSetDebugWind(xDir, zDir, speed, cirrusSpeedFactor, duration)
    if g_client == nil then
        return "Client only command"
    end
    speed = tonumber(speed) or 1
    xDir = tonumber(xDir) or 1
    zDir = tonumber(zDir) or 1
    cirrusSpeedFactor = tonumber(cirrusSpeedFactor) or 1
    duration = tonumber(duration) or 1
    if speed > 0 then
        self.windUpdater:setTargetValues(xDir, zDir, speed, cirrusSpeedFactor, duration)
    end
    return "Set debug wind speed " .. speed .. ". Command: gsWeatherSetDebugWind <xDir> <zDir> <speed> <cirrusSpeedFactor> <duration>"
end
function Weather:consoleCommandWeatherSetClouds(typeFrom, typeTo, cloudDensityScale, cirrusCloudDensityScale)
    local currentInstance = tonumber(typeFrom)
    local currentInstance = tonumber(typeTo)
    local currentInstance = tonumber(cloudDensityScale)
    local currentInstance = tonumber(cirrusCloudDensityScale)
    if currentInstance == nil or currentInstance == nil then
        return "Invalid usage. Command: gsWeatherSetClouds <typeFrom> <typeTo> <cloudDensityScale> <cirrusCloudDensityScale>"
    end
    local currentInstance = self.forecastItems[1]
    local currentWeatherObject = self:getWeatherObjectByIndex(currentInstance.season, currentInstance.objectIndex)
    local variation = currentWeatherObject.variations[currentInstance.variationIndex]
    variation.clouds.cloudTypeFrom = currentInstance
    variation.clouds.cloudTypeTo = currentInstance
    variation.clouds.cloudCoverage = currentInstance or variation.clouds.cloudCoverage
    variation.clouds.cirrusCloudDensityScale = currentInstance or variation.clouds.cirrusCloudDensityScale
    currentWeatherObject:activate(currentInstance, 0.0001)
    if currentWeatherObject.setWindValues ~= nil then
        local windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor = self.windUpdater:getCurrentValues()
        currentWeatherObject:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
    end
    return "Set cloud settings..."
end
function Weather:consoleCommandWeatherToggleRandomWindWaving()
    self.windUpdater.randomWindWaving = not self.windUpdater.randomWindWaving
    return "Random wind waving is now " .. (self.windUpdater.randomWindWaving and "enabled" or "disabled")
end