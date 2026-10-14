WeatherObjectTwister = {}
local WeatherObjectTwister_mt = Class(WeatherObjectTwister, WeatherObject)
function WeatherObjectTwister.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt)
    -- upvalues: (copy) WeatherObjectTwister_mt
    local self = WeatherObject.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt or WeatherObjectTwister_mt)
    self.twisterStartPosX = nil
    self.twisterStartPosZ = nil
    self.twisterMeterPerHour = 150
    return self
end
function WeatherObjectTwister:getIsAvailable()
    local mission = g_currentMission
    if mission.missionInfo.disasterDestructionState == DisasterDestructionState.DISABLED then
        return false
    else
        return mission.environment.weather.twister ~= nil
    end
end
function WeatherObjectTwister:getMinDuration()
    return 3
end
function WeatherObjectTwister:loadVariation(xmlFile, key, cloudPresets, baseDirectory)
    local variation = WeatherObjectTwister:superClass().loadVariation(self, xmlFile, key, cloudPresets, baseDirectory)
    if variation ~= nil then
        variation.metersPerHour = xmlFile:getInt(key .. ".twister#metersPerHour", 150)
    end
    return variation
end
function WeatherObjectTwister:update(scaledDt)
    WeatherObjectTwister:superClass().update(self, scaledDt)
    if self.twisterActivationTime ~= nil then
        self.twisterActivationTime = self.twisterActivationTime - scaledDt
        if self.twisterActivationTime <= 0 then
            if g_server ~= nil then
                g_server:broadcastEvent(TwisterStartEvent.new(self.twisterStartPosX, self.twisterStartPosZ, self.twisterMeterPerHour), true)
            end
            self.twisterActivationTime = nil
        end
    end
end
function WeatherObjectTwister:activate(weatherInstance, blendDuration, isSavegameInit)
    WeatherObjectTwister:superClass().activate(self, weatherInstance, blendDuration)
    if g_server == nil then
        return
    else
        local mission = g_currentMission
        if mission.environment.weather.twister == nil then
            Logging.warning("Try to spawn twister but no twister defined for map")
            return
        elseif mission.missionInfo.disasterDestructionState ~= DisasterDestructionState.DISABLED then
            self.twisterActivationTime = blendDuration
            self.twisterMeterPerHour = weatherInstance.twisterMeterPerHour
            if not isSavegameInit then
                self.twisterStartPosX = weatherInstance.twisterStartPosX
                self.twisterStartPosZ = weatherInstance.twisterStartPosZ
            end
        end
    end
end
function WeatherObjectTwister:deactivate(blendDuration)
    WeatherObjectTwister:superClass().deactivate(self, blendDuration)
    if g_server == nil then
        return
    elseif g_currentMission.environment.weather.twister ~= nil then
        self.twisterActivationTime = nil
        g_server:broadcastEvent(TwisterStopEvent.new(), true)
    end
end
function WeatherObjectTwister.initInstanceData(weatherObject, instance)
    local variation = weatherObject.variations[instance.variationIndex]
    instance.twisterMeterPerHour = variation.metersPerHour
    local durationHours = MathUtil.msToHours(instance.duration - 2 * Weather.CHANGE_DURATION)
    local terrainSizeHalf = g_currentMission.terrainSize * 0.5
    local minX = -terrainSizeHalf
    local minZ = -terrainSizeHalf
    local wind = variation.wind
    local dirX = wind.windDirectionX
    local dirZ = wind.windDirectionZ
    local maxX
    if math.abs(dirX) > 0.0001 then
        if dirX < 0 then
            maxX = terrainSizeHalf
        elseif dirX > 0 then
            maxX = terrainSizeHalf - totalMeters
        else
            maxX = terrainSizeHalf
        end
    else
        maxX = terrainSizeHalf
    end
    if math.abs(dirZ) > 0.0001 then
        if dirZ < 0 then
        elseif dirZ > 0 then
        end
    end
    if maxX >= minX then
    end
    if terrainSizeHalf >= minZ then
    end
    instance.twisterStartPosX = math.round((math.random(maxX, minX)))
    instance.twisterStartPosZ = math.round((math.random(terrainSizeHalf, minZ)))
end
function WeatherObjectTwister.saveInstanceDataToXMLFile(xmlFile, key, instance)
    xmlFile:setInt(key .. ".twister#startPosX", instance.twisterStartPosX or 0)
    xmlFile:setInt(key .. ".twister#startPosZ", instance.twisterStartPosZ or 0)
    xmlFile:setInt(key .. ".twister#meterPerHour", instance.twisterMeterPerHour or 0)
end
function WeatherObjectTwister.loadInstanceDataFromXMLFile(xmlFile, key, instance)
    instance.twisterStartPosX = xmlFile:getInt(key .. ".twister#startPosX", 0)
    instance.twisterStartPosZ = xmlFile:getInt(key .. ".twister#startPosZ", 0)
    instance.twisterMeterPerHour = xmlFile:getInt(key .. ".twister#meterPerHour", 0)
    return true
end