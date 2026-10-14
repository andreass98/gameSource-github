EnvironmentMaskSystem = {}
EnvironmentMaskSystem.VISIBILITY_CONDITION_FLAGS_XML_PATH = "shared/visibilityConditionFlags.xml"
local EnvironmentMaskSystem_mt = Class(EnvironmentMaskSystem)
function EnvironmentMaskSystem.new(mission, customMt)
    -- upvalues: (copy) EnvironmentMaskSystem_mt
    local self = setmetatable({}, customMt or EnvironmentMaskSystem_mt)
    self.mission = mission
    self.weatherMaskModifiers = {}
    self.weatherFlagNameToModifier = {}
    self.viewerSpatialityMaskModifiers = {}
    self.viewerSpatialityFlagNameToModifier = {}
    self.isDebugViewActive = false
    self.minuteOfDay = 0
    self.dayOfYear = 1
    self.weatherMask = 0
    self.viewerSpatialityMask = 0
    local xmlFile = XMLFile.load("visibilityConditionFlagsXml", EnvironmentMaskSystem.VISIBILITY_CONDITION_FLAGS_XML_PATH)
    for _, weatherFlagKey in xmlFile:iterator("visibilityConditionFlags.weatherFlags.flag") do
        self:registerWeatherMaskModifier(xmlFile:getString(weatherFlagKey .. "#name"), xmlFile:getInt(weatherFlagKey .. "#bit"))
    end
    self.setWeatherSun = self:getWeatherModifierUpdateFuncFromFlagName("SUN")
    self.setWeatherRain = self:getWeatherModifierUpdateFuncFromFlagName("RAIN")
    self.setWeatherHail = self:getWeatherModifierUpdateFuncFromFlagName("HAIL")
    self.setWeatherSnow = self:getWeatherModifierUpdateFuncFromFlagName("SNOW")
    self.setWeatherCloudy = self:getWeatherModifierUpdateFuncFromFlagName("CLOUDY")
    self.setIsDay = self:getWeatherModifierUpdateFuncFromFlagName("DAY")
    self.setIsNight = self:getWeatherModifierUpdateFuncFromFlagName("NIGHT")
    self.setIsSpring = self:getWeatherModifierUpdateFuncFromFlagName("SPRING")
    self.setIsSummer = self:getWeatherModifierUpdateFuncFromFlagName("SUMMER")
    self.setIsAutumn = self:getWeatherModifierUpdateFuncFromFlagName("AUTUMN")
    self.setIsWinter = self:getWeatherModifierUpdateFuncFromFlagName("WINTER")
    for _, weatherFlagKey in xmlFile:iterator("visibilityConditionFlags.viewerSpatialityFlags.flag") do
        self:registerViewerSpatialityMaskModifier(xmlFile:getString(weatherFlagKey .. "#name"), xmlFile:getInt(weatherFlagKey .. "#bit"))
    end
    self.setIsInterior = self:getViewerSpatialityModifierUpdateFuncFromFlagName("INTERIOR")
    self.setIsExterior = self:getViewerSpatialityModifierUpdateFuncFromFlagName("EXTERIOR")
    self.setInVehicle = self:getViewerSpatialityModifierUpdateFuncFromFlagName("IN_VEHICLE")
    self.setOutVehicle = self:getViewerSpatialityModifierUpdateFuncFromFlagName("OUT_VEHICLE")
    self.setIndoor = self:getViewerSpatialityModifierUpdateFuncFromFlagName("INDOOR")
    self:onLightsProfileChanged((g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)))
    xmlFile:delete()
    g_messageCenter:subscribe(MessageType.WEATHER_CHANGED, self.onWeatherChanged, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.LIGHTS_PROFILE], self.onLightsProfileChanged, self)
    g_messageCenter:subscribe(MessageType.OWN_PLAYER_ENTERED, self.onPlayerEntered, self)
    g_messageCenter:subscribe(MessageType.OWN_PLAYER_LEFT, self.onPlayerLeft, self)
    addConsoleCommand("gsEnvironmentMaskSystemToggleDebugView", "Toggles the environment mask system debug view", "consoleCommandToggleDebugView", self)
    return self
end
function EnvironmentMaskSystem:delete()
    g_messageCenter:unsubscribeAll(self)
    removeConsoleCommand("gsEnvironmentMaskSystemToggleDebugView")
end
function EnvironmentMaskSystem:update(_)
    setEnvironmentSettings(self.minuteOfDay + 1, self.dayOfYear, self.weatherMask, self.viewerSpatialityMask)
end
function EnvironmentMaskSystem:drawDebug()
    if self.isDebugViewActive then
        setTextColor(1, 1, 1, 1)
        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_CENTER)
        renderText(0.4, 0.72, getCorrectTextSize(0.014), "Environment State")
        renderText(0.6, 0.72, getCorrectTextSize(0.014), "Weather Mask:")
        renderText(0.7, 0.72, getCorrectTextSize(0.014), "Viewer Spatiality Mask:")
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
        local posY = 0.7
        local textSize = getCorrectTextSize(0.012)
        local textOffset = getCorrectTextSize(0.001)
        for _, modifier in ipairs(self.weatherMaskModifiers) do
            local isActive = bit32.band(self.weatherMask, modifier.bitflag) ~= 0
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText(0.6, posY, textSize, modifier.name .. ":  ")
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(0.6, posY, textSize, (tostring(isActive)))
            posY = posY - textSize - textOffset
        end
        local posY = 0.7
        for _, modifier in ipairs(self.viewerSpatialityMaskModifiers) do
            local isActive = bit32.band(self.viewerSpatialityMask, modifier.bitflag) ~= 0
            setTextAlignment(RenderText.ALIGN_RIGHT)
            renderText(0.7, posY, textSize, modifier.name .. ":  ")
            setTextAlignment(RenderText.ALIGN_LEFT)
            renderText(0.7, posY, textSize, (tostring(isActive)))
            posY = posY - textSize - textOffset
        end
        local posY = 0.7
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(0.4, posY - (textSize + textOffset) * 0, textSize, "MinuteOfDay:  ")
        renderText(0.4, posY - (textSize + textOffset) * 1, textSize, "DayOfYear:  ")
        renderText(0.4, posY - (textSize + textOffset) * 2, textSize, "WeatherMask:  ")
        renderText(0.4, posY - (textSize + textOffset) * 3, textSize, "ViewerSpatialityMask:  ")
        local posY = 0.7
        setTextAlignment(RenderText.ALIGN_LEFT)
        local isActive = self.minuteOfDay
        renderText(0.4, posY - (textSize + textOffset) * 0, textSize, (tostring(isActive)))
        local isActive = self.dayOfYear
        renderText(0.4, posY - (textSize + textOffset) * 1, textSize, (tostring(isActive)))
        local isActive = self.weatherMask
        renderText(0.4, posY - (textSize + textOffset) * 2, textSize, (tostring(isActive)))
        local isActive = self.viewerSpatialityMask
        renderText(0.4, posY - (textSize + textOffset) * 3, textSize, (tostring(isActive)))
    end
end
function EnvironmentMaskSystem:setDayTime(dayTime)
    self.minuteOfDay = math.floor(dayTime / 1000 / 60)
end
function EnvironmentMaskSystem:setDayOfYear(dayOfYear, season)
    self.dayOfYear = math.clamp(dayOfYear, 0, 365)
    self.setIsSpring(season == Season.SPRING)
    self.setIsSummer(season == Season.SUMMER)
    self.setIsAutumn(season == Season.AUTUMN)
    self.setIsWinter(season == Season.WINTER)
end
function EnvironmentMaskSystem:onWeatherChanged(weatherObject)
    local typeIndex = weatherObject.weatherType
    self.setWeatherSun(typeIndex == WeatherType.SUN)
    self.setWeatherRain(typeIndex == WeatherType.RAIN)
    self.setWeatherHail(typeIndex == WeatherType.HAIL)
    self.setWeatherSnow(typeIndex == WeatherType.SNOW)
    self.setWeatherCloudy(typeIndex == WeatherType.CLOUDY)
end
function EnvironmentMaskSystem:onLightsProfileChanged(lightsProfile)
    local lightsProfileLow = self:getViewerSpatialityModifierUpdateFuncFromFlagName("LIGHTS_PROFILE_LOW")
    lightsProfileLow(lightsProfile < GS_PROFILE_HIGH)
    local lightsProfileHigh = self:getViewerSpatialityModifierUpdateFuncFromFlagName("LIGHTS_PROFILE_HIGH")
    lightsProfileHigh(GS_PROFILE_HIGH <= lightsProfile)
end
function EnvironmentMaskSystem:setIsSunOn(isSunOn)
    self.setIsDay(isSunOn)
    self.setIsNight(not isSunOn)
end
function EnvironmentMaskSystem:setIsIndoor(isIndoor)
    self.setIndoor(isIndoor)
end
function EnvironmentMaskSystem:onPlayerEntered()
    self.setInVehicle(false)
    self.setOutVehicle(true)
end
function EnvironmentMaskSystem:onPlayerLeft()
    self.setInVehicle(true)
    self.setOutVehicle(false)
end
function EnvironmentMaskSystem:registerWeatherMaskModifier(modifierName, bit)
    local name = string.upper(modifierName)
    local bitflag = 2 ^ bit
    for _, modifier in ipairs(self.weatherMaskModifiers) do
        if modifier.name == name then
            Logging.error("Weather mask modifier name \'%s\' already used", modifierName)
            return false
        end
        if modifier.bitflag == bitflag then
            Logging.error("Weather mask modifier \'%s\' bit \'%d\' already used for modifier \'%s\'", modifierName, bit, modifier.name)
            return false
        end
    end
    local modifier = {
        ["name"] = name,
        ["bitflag"] = bitflag,
        ["updateFunc"] = function(isActive)
            -- upvalues: (copy) self, (copy) modifier
            if isActive then
                self.weatherMask = bit32.bor(self.weatherMask, modifier.bitflag)
            else
                self.weatherMask = bit32.band(self.weatherMask, (bit32.bnot(modifier.bitflag)))
            end
        end
    }
    table.insert(self.weatherMaskModifiers, modifier)
    self.weatherFlagNameToModifier[modifier.name] = modifier
    return modifier.updateFunc
end
function EnvironmentMaskSystem:registerViewerSpatialityMaskModifier(modifierName, bit)
    local name = string.upper(modifierName)
    local bitflag = 2 ^ bit
    for _, modifier in ipairs(self.viewerSpatialityMaskModifiers) do
        if modifier.name == name then
            Logging.error("Given viewer spatiality mask modifier name \'%s\' already used", modifierName)
            return false
        end
        if modifier.bitflag == bitflag then
            Logging.error("Viewer spatiality mask modifier \'%s\' bit \'%d\' already used for modifier \'%s\'", modifierName, bit, modifier.name)
            return false
        end
    end
    local modifier = {
        ["name"] = name,
        ["bitflag"] = bitflag,
        ["updateFunc"] = function(isActive)
            -- upvalues: (copy) self, (copy) modifier
            if isActive then
                self.viewerSpatialityMask = bit32.bor(self.viewerSpatialityMask, modifier.bitflag)
            else
                self.viewerSpatialityMask = bit32.band(self.viewerSpatialityMask, (bit32.bnot(modifier.bitflag)))
            end
        end
    }
    table.insert(self.viewerSpatialityMaskModifiers, modifier)
    self.viewerSpatialityFlagNameToModifier[modifier.name] = modifier
    return modifier.updateFunc
end
function EnvironmentMaskSystem:getWeatherModifierUpdateFuncFromFlagName(flagName)
    local modifier = self.weatherFlagNameToModifier[flagName]
    if modifier ~= nil and modifier.updateFunc ~= nil then
        return modifier.updateFunc
    end
    Logging.error("No weather modifier registered for \'%s\'. Using empty update function", flagName)
    return function() end
end
function EnvironmentMaskSystem:getViewerSpatialityModifierUpdateFuncFromFlagName(flagName)
    local modifier = self.viewerSpatialityFlagNameToModifier[flagName]
    if modifier ~= nil and modifier.updateFunc ~= nil then
        return modifier.updateFunc
    end
    Logging.error("No viewer spatiality modifier registered for \'%s\'. Using empty update function", flagName)
    return function() end
end
function EnvironmentMaskSystem:getWeatherMaskFromFlagName(flagName)
    return self.weatherFlagNameToModifier[string.upper(flagName)]
end
function EnvironmentMaskSystem:getWeatherMaskFromFlagNames(flagNames)
    if flagNames == nil or flagNames == "" then
        return nil
    end
    local mask = 0
    for _, flagName in pairs(string.split(string.upper(flagNames), " ")) do
        local modifier = self.weatherFlagNameToModifier[flagName]
        if modifier == nil then
            Logging.error("Unknown weather flag \'%s\'. Available flags: %s", flagName, table.concatKeys(self.weatherFlagNameToModifier, " "))
        else
            mask = bit32.bor(mask, modifier.bitflag)
        end
    end
    return mask
end
function EnvironmentMaskSystem:consoleCommandToggleDebugView()
    self.isDebugViewActive = not self.isDebugViewActive
    if self.isDebugViewActive then
        g_debugManager:addDrawable(self)
    else
        g_debugManager:removeDrawable(self)
    end
end