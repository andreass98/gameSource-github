PlaceableWeatherStation = {}
function PlaceableWeatherStation.prerequisitesPresent(specializations)
    return true
end
function PlaceableWeatherStation.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWeatherStation)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWeatherStation)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableWeatherStation)
end
function PlaceableWeatherStation.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("WeatherStation")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".weatherStation.sounds", "idle")
    schema:setXMLSpecializationType()
end
function PlaceableWeatherStation:onLoad(_)
    if self.isClient then
        self.spec_weatherStation.sample = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.weatherStation.sounds", "idle", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
    end
end
function PlaceableWeatherStation:onDelete()
    g_currentMission.placeableSystem:removeWeatherStation(self)
    if self.isClient then
        g_soundManager:deleteSample(self.spec_weatherStation.sample)
    end
end
function PlaceableWeatherStation:onFinalizePlacement()
    g_currentMission.placeableSystem:addWeatherStation(self)
    if self.isClient then
        local spec = self.spec_weatherStation
        if spec.sample ~= nil then
            g_soundManager:playSample(spec.sample)
        end
    end
end