Environment = {}
local Environment_mt = Class(Environment)
Environment.SEASONS_IN_YEAR = 4
Environment.PERIODS_IN_YEAR = 12
Environment.JULIAN_DAYS_NORTH = {
    [Season.SPRING] = 60,
    [Season.SUMMER] = 152,
    [Season.AUTUMN] = 244,
    [Season.WINTER] = 335
}
Environment.JULIAN_DAYS_SOUTH = {
    [Season.SPRING] = 244,
    [Season.SUMMER] = 335,
    [Season.AUTUMN] = 60,
    [Season.WINTER] = 152
}
Environment.DAYTIME_TO_HOURS_MULT = 1.1574074074074074e-8
Environment.INITIAL_DAY = 6
Environment.MAX_DAYS_PER_PERIOD = 28
Environment.PERIOD_DAY_MAPPING = {
    [SeasonPeriod.EARLY_SPRING] = 80,
    [SeasonPeriod.MID_SPRING] = 110,
    [SeasonPeriod.LATE_SPRING] = 140,
    [SeasonPeriod.EARLY_SUMMER] = 170,
    [SeasonPeriod.MID_SUMMER] = 200,
    [SeasonPeriod.LATE_SUMMER] = 230,
    [SeasonPeriod.EARLY_AUTUMN] = 260,
    [SeasonPeriod.MID_AUTUMN] = 290,
    [SeasonPeriod.LATE_AUTUMN] = 320,
    [SeasonPeriod.EARLY_WINTER] = 350,
    [SeasonPeriod.MID_WINTER] = 20,
    [SeasonPeriod.LATE_WINTER] = 50
}
function Environment.onCreateSunLight(_, node)
    if g_currentMission ~= nil and g_currentMission.environment ~= nil then
        if g_currentMission.environment.baseLighting.sunLightId == nil then
            g_currentMission.environment.baseLighting.sunLightId = node
            g_currentMission.environment.baseLighting.sunColor = { getLightColor(node) }
            return
        end
        local sunPath = I3DUtil.getNodePath(g_currentMission.environment.lighting.sunLightId)
        local sunChildIndex = getChildIndex(g_currentMission.environment.lighting.sunLightId)
        local secondSunPath = I3DUtil.getNodePath(node)
        local secondSunChildIndex = getChildIndex(node)
        Logging.error("Environment:onCreateSunLight(): Sun light source was already registered \'%s\'(child %d). Please remove \'%s\' (child %d)", sunPath, sunChildIndex, secondSunPath, secondSunChildIndex)
    end
end
function Environment.onCreateWater(_, id)
    if getHasClassId(id, ClassIds.SHAPE) then
        if not Utils.getNoNil(getUserAttribute(id, "useShapeObjectMask"), false) then
            local newMask = bit32.band(getObjectMask(id), (bit32.bnot(ObjectMask.SHAPE_VIS_MIRROR)))
            setObjectMask(id, newMask)
        end
        if getShapeCastShadowmap(id) then
            Logging.i3dWarning(id, "Environment:onCreateWater(): Water plane has shadow casting active")
        end
        if not getShapeReceiveShadowmap(id) then
            Logging.i3dWarning(id, "Environment:onCreateWater(): Water plane is missing shadow receive")
        end
        local newMask = Utils.getPerformanceClassId()
        if newMask <= GS_PROFILE_MEDIUM or GS_IS_CONSOLE_VERSION then
            setReflectionMapScaling(id, 0, true)
        elseif newMask <= GS_PROFILE_HIGH then
            setReflectionMapObjectMasks(id, ObjectMask.SHAPE_VIS_WATER_REFL, ObjectMask.LIGHT_VIS_WATER_REFL, true)
        else
            setReflectionMapObjectMasks(id, ObjectMask.SHAPE_VIS_WATER_REFL_VERYHIGH, ObjectMask.LIGHT_VIS_WATER_REFL_VERYHIGH, true)
        end
        if getRigidBodyType(id) ~= RigidBodyType.NONE then
            if not CollisionFlag.getHasGroupFlagSet(id, CollisionFlag.WATER) then
                Logging.i3dWarning(id, "Environment:onCreateWater(): Water plane is missing %s", CollisionFlag.getBitAndName(CollisionFlag.WATER))
            end
            if g_currentMission.shallowWaterSimulation ~= nil then
                if not g_currentMission.isLoadingMap then
                    Logging.i3dWarning(id, "Environment:onCreateWater(): Cannot add shallow water simulation planes using onCreate for meshes outside the map itself, use xml config \'placeable.shallowWaterSimulation\' instead")
                    return
                end
                g_currentMission.shallowWaterSimulation:addWaterPlane(id)
                g_currentMission.shallowWaterSimulation:addAreaGeometry(id)
            end
        end
    else
        Logging.i3dError(id, "Environment:onCreateWater(): Given node is not a shape, ignoring")
    end
end
function Environment.new(mission)
    -- upvalues: (copy) Environment_mt
    local self = setmetatable({}, Environment_mt)
    local skyNode = g_i3DManager:loadI3DFile("data/sky/sky.i3d", false, false)
    if skyNode ~= 0 then
        link(getRootNode(), skyNode)
        self.skyNode = skyNode
    end
    self.mission = mission
    self.daylight = Daylight.new()
    self.lighting = Lighting.new()
    self.baseLighting = self.lighting
    self.weather = Weather.new(self)
    self.environmentMaskSystem = EnvironmentMaskSystem.new(self.mission)
    self.currentDay = nil
    self.currentMonotonicDay = nil
    self.dayTime = nil
    self.timeUpdateInterval = 60000
    self.timeUpdateTime = 0
    self.isSunOn = true
    self.debugSeasonalShaderParameter = false
    if self.mission:getIsServer() then
        addConsoleCommand("gsTimeSet", "Sets the day time in hours", "consoleCommandSetDayTime", self, "timeHours; [skipDayOnly]")
        addConsoleCommand("gsEnvironmentReload", "Reloads environment", "consoleCommandReloadEnvironment", self)
        if g_addCheatCommands then
            addConsoleCommand("gsTakeEnvProbes", "Takes env. probes from current camera position", "consoleCommandTakeEnvProbes", self)
        end
    end
    addConsoleCommand("gsSetFixedExposureSettings", "Sets fixed exposure settings", "consoleCommandSetFixedExposureSettings", self, "keyValue; minExposure; maxExposure")
    addConsoleCommand("gsEnvironmentAutoExposureToggle", "Toggles auto exposure", "consoleCommandToggleAutoExposure", self)
    addConsoleCommand("gsEnvironmentExposureFixedLuminance", "Set exposure fixed luminance", "consoleCommandSetExposureFixedLuminance", self, "luminance")
    addConsoleCommand("gsEnvironmentSeasonalShaderSet", "Sets the seasonal shader to a forced value", "consoleCommandSetSeasonalShader", self)
    addConsoleCommand("gsEnvironmentSeasonalShaderDebug", "Shows the current seasonal shader parameter", "consoleCommandSeasonalShaderDebug", self)
    addConsoleCommand("gsEnvironmentFixedVisualsSet", "Sets the visual seasons to a fixed period", "consoleCommandSetFixedVisuals", self, "periodIndex")
    return self
end
function Environment:load(filename)
    self.xmlFilename = filename
    local xmlFile = XMLFile.load("Environment", filename)
    if xmlFile == nil then
        Logging.fatal("Could not load environment \'%s\'", filename)
    end
    self.currentDay = 1
    self.currentMonotonicDay = 1
    self.currentDayInPeriod = 1
    self.currentYear = 1
    self.currentDayInSeason = 1
    self.currentVisualDayInSeason = 1
    self.currentSeason = Season.SPRING
    self.currentPeriod = SeasonPeriod.EARLY_SPRING
    self.daysPerPeriod = 1
    self.timeAdjustment = 1 / self.daysPerPeriod
    self.plannedDaysPerPeriod = 1
    self.currentVisualSeason = Season.SPRING
    self.currentVisualPeriod = SeasonPeriod.EARLY_SPRING
    self.visualPeriodLocked = false
    self.dayLength = 86400000
    self.realHourLength = 3600000
    self.realHourTimer = self.realHourLength
    self.daylight:load(xmlFile, "environment")
    self:updateJulianDay()
    local startHour = xmlFile:getFloat("environment#startHour", 8)
    local dayTime = 0
    if startHour ~= nil then
        dayTime = startHour * 60 * 60 * 1000
    end
    self:setEnvironmentTime(Environment.INITIAL_DAY, Environment.INITIAL_DAY, dayTime, self.daysPerPeriod, false)
    self.dayNightCycle = xmlFile:getBool("environment#dayNightCycle", true)
    self.lighting:load(xmlFile, "environment.lighting", g_currentMission.baseDirectory)
    self.lighting:setSnowHeightThreshold(SnowSystem.MIN_LAYER_HEIGHT)
    self.lighting:apply()
    self.weather:setIsRainAllowed(true)
    self.weather:load(xmlFile, "environment", g_currentMission.baseDirectory)
    self.environmentMaskSystem:setDayOfYear(Environment.PERIOD_DAY_MAPPING[self.currentVisualPeriod], self.currentVisualSeason)
    self.environmentMaskSystem:setIsSunOn(self.isSunOn)
    self.nightTimeScale = xmlFile:getFloat("environment#nightTimeScale", 2)
    self.dirtColorDefault = xmlFile:getVector("environment.dirtColors#default", { 0.2, 0.14, 0.08 }, 3)
    self.dirtColorSnow = xmlFile:getVector("environment.dirtColors#snow", { 0.95, 0.95, 0.95 }, 3)
    xmlFile:delete()
    g_messageCenter:unsubscribeAll(self)
    return self
end
function Environment:delete()
    if self.skyNode ~= nil then
        delete(self.skyNode)
        self.skyNode = nil
    end
    self:resetSceneParameters()
    self.environmentMaskSystem:delete()
    self.environmentMaskSystem = nil
    self.weather:delete()
    self.weather = nil
    self.baseLighting:delete()
    self.baseLighting = nil
    self.daylight:delete()
    self.daylight = nil
    g_messageCenter:unsubscribeAll(self)
    removeConsoleCommand("gsTimeSet")
    removeConsoleCommand("gsEnvironmentReload")
    removeConsoleCommand("gsSetFixedExposureSettings")
    removeConsoleCommand("gsEnvironmentAutoExposureToggle")
    removeConsoleCommand("gsEnvironmentExposureFixedLuminance")
    removeConsoleCommand("gsEnvironmentSeasonalShaderSet")
    removeConsoleCommand("gsEnvironmentSeasonalShaderDebug")
    removeConsoleCommand("gsEnvironmentFixedVisualsSet")
    removeConsoleCommand("gsTakeEnvProbes")
end
function Environment:saveToXMLFile(xmlFile, key)
    setXMLFloat(xmlFile, key .. ".dayTime", self.dayTime / 60000)
    setXMLInt(xmlFile, key .. ".currentDay", self.currentDay)
    setXMLInt(xmlFile, key .. ".currentMonotonicDay", self.currentMonotonicDay)
    setXMLInt(xmlFile, key .. ".realHourTimer", self.realHourTimer)
    setXMLInt(xmlFile, key .. ".daysPerPeriod", self.daysPerPeriod)
    setXMLFloat(xmlFile, key .. ".lighting.toneMapping#slope", getToneMappingCurveSlope())
    setXMLFloat(xmlFile, key .. ".lighting.toneMapping#toe", getToneMappingCurveToe())
    setXMLFloat(xmlFile, key .. ".lighting.toneMapping#shoulder", getToneMappingCurveShoulder())
    setXMLFloat(xmlFile, key .. ".lighting.toneMapping#blackClip", getToneMappingCurveBlackClip())
    setXMLFloat(xmlFile, key .. ".lighting.toneMapping#whiteClip", getToneMappingCurveWhiteClip())
    self.daylight:saveToXMLFile(xmlFile, key .. ".daylight")
    self.weather:saveToXMLFile(xmlFile, key .. ".weather")
end
function Environment:loadFromXMLFile(xmlFile, key)
    local dayTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".dayTime"), 400)
    local currentDay = Utils.getNoNil(getXMLInt(xmlFile, key .. ".currentDay"), self.currentDay)
    local currentMonotonicDay = Utils.getNoNil(getXMLInt(xmlFile, key .. ".currentMonotonicDay"), currentDay)
    self.daysPerPeriod = Utils.getNoNil(getXMLInt(xmlFile, key .. ".daysPerPeriod"), self.daysPerPeriod)
    self.timeAdjustment = 1 / self.daysPerPeriod
    self.plannedDaysPerPeriod = self.mission.missionInfo.plannedDaysPerPeriod
    local fixedPeriod = self.mission.missionInfo.fixedSeasonalVisuals
    if fixedPeriod ~= nil then
        self.currentVisualPeriod = fixedPeriod
        self.currentVisualSeason = SeasonPeriod.getSeason(fixedPeriod)
        self.visualPeriodLocked = true
    end
    self.realHourTimer = Utils.getNoNil(getXMLInt(xmlFile, key .. ".realHourTimer"), 3600000)
    self.daylight:loadFromXMLFile(xmlFile, key .. ".daylight")
    self.weather:loadFromXMLFile(xmlFile, key .. ".weather")
    self:setEnvironmentTime(currentMonotonicDay, currentDay, dayTime * 1000 * 60, self.daysPerPeriod, false)
end
function Environment:update(dt)
    if self.envMapGeneration ~= nil then
        local task = self.envMapGeneration.tasks[1]
        if task ~= nil then
            if task.dayTime ~= nil then
                local newDayTime = math.floor(task.dayTime * 1000 * 60 * 60)
                self:setEnvironmentTime(self.currentDay, self.currentDay, newDayTime, self.daysPerPeriod, false)
                self.lighting:setDayTime(self.dayTime, true)
            end
            if task.cloudData ~= nil then
                self.weather.cloudUpdater:setTargetClouds(task.cloudData, 0)
                self.weather.cloudUpdater:setWindValues(task.windDirX, task.windDirZ, task.windVelocity, task.cirrusCloudSpeedFactor)
                self.weather.cloudUpdater:update(10000)
                if self.weather.skyBoxUpdater ~= nil then
                    local newDayTime = 0
                    local newDay = math.huge
                    if task.cloudData.precipitation > 0.5 then
                        newDayTime = 1
                        newDay = -1000
                    end
                    self.weather.skyBoxUpdater:update(10000, self.dayTime, newDayTime, newDay)
                end
            end
            if task.setDefaultValues then
                setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, 0)
                self.baseLighting:setDaylightTimes(7, 19, 6, 20)
                self.baseLighting.envMapRenderingMode = true
                self.baseLighting:setDayTime(self.dayTime, true)
                self.baseLighting.envMapRenderingMode = false
            end
            local newDayTime = task.filename
            if newDayTime ~= nil then
                renderEnvProbe(task.renderResolution, task.outputResolution, task.ssaoQuality, false, task.numIterations, newDayTime)
            end
            table.remove(self.envMapGeneration.tasks, 1)
            return
        end
        local newDayTime = self.envMapGeneration.currentData
        local newDay = self.weather.cloudUpdater
        newDay.lastClouds = newDayTime.lastClouds
        newDay.targetClouds = newDayTime.targetClouds
        newDay.alpha = newDayTime.alpha
        newDay.duration = newDayTime.duration
        newDay.windDirX = newDayTime.windDirX
        newDay.windDirZ = newDayTime.windDirZ
        newDay.windVelocity = newDayTime.windVelocity
        newDay.cirrusCloudSpeedFactor = newDayTime.cirrusCloudSpeedFactor
        newDay.isDirty = true
        g_currentMission.growthSystem:setGrowthMode(newDayTime.growthMode, true)
        self:setEnvironmentTime(newDayTime.currentMonotonicDay + 12 * self.daysPerPeriod, newDayTime.currentDay + 12 * self.daysPerPeriod, newDayTime.dayTime, self.daysPerPeriod, false)
        self.envMapGeneration = nil
        print("Finished environment map generation")
    end
    self.weather:update(dt)
    self.environmentMaskSystem:update(dt)
    self.dayTime = self.dayTime + dt * self.mission:getEffectiveTimeScale()
    self:updateTimeValues(false)
    self.realHourTimer = self.realHourTimer - dt
    if self.realHourTimer <= 0 then
        g_messageCenter:publish(MessageType.REALHOUR_CHANGED)
        self.realHourTimer = self.realHourLength
    end
    if self.lighting ~= nil then
        local task, newDayTime, newDay = self.weather:getCloudEnvMapInfo()
        self.lighting:setCloudEnvMapInfo(task, newDayTime, newDay)
        self.lighting:setSunHeightAngle(self.daylight:getSunHeightAngle())
        self.lighting:setDaylightTimes(self.daylight:getDaylightTimes())
        self.lighting:setSnowHeight(self.weather.snowHeight)
        self.lighting:setVisualSeason(self.currentVisualSeason)
        self.lighting:setDayTime(self.dayTime, g_sleepManager.isSleeping)
        self.lighting:update(dt)
    end
    self:updateSceneParameters()
    if self.debugSeasonalShaderParameter then
        renderText(0.2, 0.05, 0.015, string.format("Season Shader Parameter (cShared3): %s", self:getSeasonShaderValue()))
        if g_currentMission.snowSystem ~= nil then
            renderText(0.2, 0.035, 0.015, string.format("Snow Shader Parameter (cShared4): %s", g_currentMission.snowSystem:getSnowShaderValue()))
        end
    end
    if g_server ~= nil then
        self.timeUpdateTime = self.timeUpdateTime + dt
        if self.timeUpdateTime > self.timeUpdateInterval then
            EnvironmentTimeEvent.broadcastEvent()
            self.timeUpdateTime = 0
        end
        if Platform.gameplay.hasShortNights and not g_sleepManager:getIsSleeping() then
            local task = self.dayTime / 60000
            local newDayTime = true
            if self.daylight.logicalNightStartMinutes > task then
                newDayTime = task < self.daylight.logicalNightEndMinutes
            end
            if newDayTime ~= self.lastNightState then
                self.mission:setTimeScaleMultiplier(newDayTime and self.nightTimeScale or 1)
            end
            self.lastNightState = newDayTime
        end
    end
end
function Environment:updateTimeValues(isInitialState)
    local timeHoursF = self.dayTime / 3600000 + 0.0001
    local timeHours = math.floor(timeHoursF)
    local hourChanged = (timeHoursF - timeHours) * 60
    local timeMinutes = math.floor(hourChanged)
    self.environmentMaskSystem:setDayTime(self.dayTime)
    local hourChanged = false
    local dayChanged = false
    local periodChanged = false
    local seasonChanged = false
    local yearChanged = false
    local periodLengthChanged = false
    if timeMinutes ~= self.currentMinute then
        while timeMinutes ~= self.currentMinute do
            self.currentMinute = self.currentMinute + 1
            if self.currentMinute >= 60 then
                self.currentMinute = 0
            end
            if not isInitialState then
                g_messageCenter:publish(MessageType.MINUTE_CHANGED, self.currentMinute)
                self.mission:onMinuteChanged(self.currentMinute)
            end
        end
    end
    if timeHours ~= self.currentHour then
        self.currentHour = timeHours
        if self.currentHour == 24 then
            self.currentHour = 0
        end
        hourChanged = true
    end
    if self.dayTime > 86400000 then
        self.dayTime = self.dayTime - 86400000
        self.currentDay = self.currentDay + 1
        self.currentMonotonicDay = self.currentMonotonicDay + 1
        dayChanged = true
    end
    if dayChanged or isInitialState then
        self.currentDayInPeriod = (self.currentDay - 1) % self.daysPerPeriod + 1
        local season = ((self.currentDay - 1) % (self.daysPerPeriod * Environment.PERIODS_IN_YEAR) + 1) / self.daysPerPeriod
        local period = math.ceil(season)
        if period ~= self.currentPeriod then
            self.currentPeriod = period
            if not self.visualPeriodLocked then
                self.currentVisualPeriod = self.currentPeriod
            end
            periodChanged = true
        end
        local season = math.fmod(math.floor((self.currentDay - 1) / self:getDaysPerSeason()), Environment.SEASONS_IN_YEAR) + 1
        if season ~= self.currentSeason then
            self.currentSeason = season
            if not self.visualPeriodLocked then
                self.currentVisualSeason = season
            end
            seasonChanged = true
            if self.daysPerPeriod ~= self.plannedDaysPerPeriod then
                self.daysPerPeriod = self.plannedDaysPerPeriod
                self.timeAdjustment = 1 / self.daysPerPeriod
                self.currentDay = math.floor((self.currentDay - 1) / self.daysPerPeriod * self.daysPerPeriod) + 1
                self.currentDayInPeriod = (self.currentDay - 1) % self.daysPerPeriod + 1
                periodLengthChanged = true
            end
        end
        self.currentDayInSeason = math.fmod(self.currentDay - 1, self.daysPerPeriod * 3) + 1
        if self.visualPeriodLocked then
            self.currentVisualDayInSeason = math.floor((self.currentVisualPeriod - 1) % 1.5 * self.daysPerPeriod + 1)
        else
            self.currentVisualDayInSeason = self.currentDayInSeason
        end
        local oldDaysPerPeriod = math.floor((self.currentDay - 1) / (self.daysPerPeriod * Environment.PERIODS_IN_YEAR)) + 1
        if oldDaysPerPeriod ~= self.currentYear then
            self.currentYear = oldDaysPerPeriod
            yearChanged = true
        end
    end
    if dayChanged or isInitialState then
        self:updateJulianDay()
    end
    if periodChanged or isInitialState then
        self.environmentMaskSystem:setDayOfYear(Environment.PERIOD_DAY_MAPPING[self.currentVisualPeriod], self.currentVisualSeason)
    end
    if hourChanged and not isInitialState then
        g_messageCenter:publish(MessageType.HOUR_CHANGED, self.currentHour)
        self.mission:onHourChanged()
    end
    if dayChanged and not isInitialState then
        g_messageCenter:publish(MessageType.DAY_CHANGED, self.currentDay)
        self.mission:onDayChanged()
        if periodLengthChanged then
            g_messageCenter:publish(MessageType.PERIOD_LENGTH_CHANGED, self.daysPerPeriod, self.timeAdjustment)
        end
        if periodChanged then
            g_messageCenter:publish(MessageType.PERIOD_CHANGED, self.currentPeriod, self.currentVisualPeriod)
        end
        if seasonChanged then
            g_messageCenter:publish(MessageType.SEASON_CHANGED, self.currentSeason)
        end
        if yearChanged then
            g_messageCenter:publish(MessageType.YEAR_CHANGED, self.currentYear)
        end
    end
end
function Environment:updateSceneParameters()
    if self.dayNightCycle and self.lighting.sunLightId ~= nil then
        local dayMinutes = self.dayTime / 60000
        local newIsSunOn = not (self.daylight.logicalNightStartMinutes <= dayMinutes or dayMinutes < self.daylight.logicalNightEndMinutes)
        if self.isSunOn ~= newIsSunOn then
            self.isSunOn = newIsSunOn
            self.environmentMaskSystem:setIsSunOn(newIsSunOn)
            g_messageCenter:publish(MessageType.DAY_NIGHT_CHANGED)
        end
    end
    if self.forcedSeasonShaderValue == nil then
        setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, self:getSeasonShaderValue())
    end
end
function Environment:resetSceneParameters()
    setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, 0)
end
function Environment:getSeasonShaderValue()
    if self.visualPeriodLocked then
        return (self.currentVisualSeason - 2) % 4 + 0.5
    end
    local daysPerSeason = 3 * self.daysPerPeriod
    return (self.currentSeason - 2) % 4 + ((self.currentDay - 1) % daysPerSeason / daysPerSeason + (self.dayTime * Environment.DAYTIME_TO_HOURS_MULT + 0.0001) / daysPerSeason)
end
function Environment:setCustomLighting(lighting)
    if self.lighting ~= nil then
        self.lighting:reset()
    end
    self.lighting = lighting or self.baseLighting
    self.lighting.sunLightId = self.baseLighting.sunLightId
    self.lighting:setSunHeightAngle(self.daylight:getSunHeightAngle())
    self.lighting:setDaylightTimes(self.daylight:getDaylightTimes())
    self.lighting:setDayTime(self.dayTime, true)
    self.lighting:apply()
end
function Environment:setSunVisibility(isVisible)
    if isVisible then
        local r, g, b = unpack(self.baseLighting.sunColor)
        setLightColor(self.baseLighting.sunLightId, r, g, b)
    else
        setLightColor(self.baseLighting.sunLightId, 0, 0, 0)
    end
end
function Environment:getMinuteOfDay()
    return math.floor(self.dayTime / 1000 / 60)
end
function Environment:getDayOfYear()
    return Environment.PERIOD_DAY_MAPPING[self.currentVisualPeriod]
end
function Environment:getDayAndDayTime(dayTime, dayOffset)
    local newDayOffset, newDayTime = math.modf(dayTime / self.dayLength)
    local newDayTimeInteger = math.round(newDayTime * self.dayLength)
    return dayOffset + newDayOffset, newDayTimeInteger
end
function Environment:getDaysPerSeason()
    return self.daysPerPeriod * 3
end
function Environment:getSeasonAtDay(day)
    return math.fmod(math.floor((self.currentDay + (day - self.currentMonotonicDay) - 1) / self:getDaysPerSeason()), Environment.SEASONS_IN_YEAR) + 1
end
function Environment:getDaysPlayed()
    return self.currentMonotonicDay - Environment.INITIAL_DAY
end
function Environment:getVisualSeasonAtDay(day)
    if self.visualPeriodLocked then
        return self.currentVisualSeason
    else
        return self:getSeasonAtDay(day)
    end
end
function Environment:setEnvironmentTime(currentMonotonicDay, currentDay, dayTime, daysPerPeriod, isDelta)
    self.currentDay = currentDay
    self.currentMonotonicDay = currentMonotonicDay
    self.dayTime = dayTime
    self.daysPerPeriod = daysPerPeriod
    if not isDelta then
        while self.dayTime > 86400000 do
            self.dayTime = self.dayTime - 86400000
            self.currentDay = self.currentDay + 1
            self.currentMonotonicDay = self.currentMonotonicDay + 1
        end
        local timeHoursF = self.dayTime / 3600000 + 0.0001
        self.currentHour = math.floor(timeHoursF)
        self.currentMinute = math.floor((timeHoursF - self.currentHour) * 60)
    end
    self:updateTimeValues(true)
end
function Environment:getEnvironmentTime()
    return self.currentHour + self.currentMinute / 100
end
function Environment:getJulianDay()
    local startDays = Environment.JULIAN_DAYS_NORTH
    if self.daylight.latitude < 0 then
        startDays = Environment.JULIAN_DAYS_SOUTH
    end
    return math.fmod(math.floor(startDays[self.currentVisualSeason] + self.currentVisualDayInSeason / (3 * self.daysPerPeriod) * 91), 365)
end
function Environment:getMonotonicHour()
    return self.currentMonotonicDay * 24 + self.dayTime / 3600000
end
function Environment:updateJulianDay()
    if self.daylight ~= nil then
        self.daylight:setJulianDay(self:getJulianDay())
    end
end
function Environment:getPeriodAndAlphaIntoPeriod()
    return self.currentPeriod, (self.currentDayInPeriod - 1 + self.dayTime * Environment.DAYTIME_TO_HOURS_MULT) / self.daysPerPeriod
end
function Environment:getDirtColors()
    return self.dirtColorDefault, self.dirtColorSnow
end
function Environment:getPeriodFromDay(day)
    return math.ceil(((self.currentDay + (day - self.currentMonotonicDay) - 1) % (self.daysPerPeriod * Environment.PERIODS_IN_YEAR) + 1) / self.daysPerPeriod)
end
function Environment:getDayInPeriodFromDay(day)
    return (self.currentDay + (day - self.currentMonotonicDay) - 1) % self.daysPerPeriod + 1
end
function Environment:setFixedPeriod(period)
    if period == nil and self.visualPeriodLocked == true then
        self.visualPeriodLocked = false
        self.currentVisualPeriod = self.currentPeriod
        self.currentVisualSeason = self.currentSeason
        self.currentDayInSeason = math.fmod(self.currentDay - 1, self.daysPerPeriod * 3) + 1
        self.currentVisualDayInSeason = self.currentDayInSeason
        self.mission.missionInfo.fixedSeasonalVisuals = nil
        self:updateJulianDay()
        self.weather:rebuild()
    elseif period ~= nil and (self.visualPeriodLocked == false or self.currentVisualPeriod ~= period) then
        period = math.clamp(period, 1, 12)
        self.visualPeriodLocked = true
        self.currentVisualPeriod = period
        self.currentVisualSeason = SeasonPeriod.getSeason(period)
        self.currentDayInSeason = math.fmod(self.currentDay - 1, self.daysPerPeriod * 3) + 1
        self.currentVisualDayInSeason = math.floor((self.currentVisualPeriod - 1) % 1.5 * self.daysPerPeriod + 1)
        self.mission.missionInfo.fixedSeasonalVisuals = period
        self:updateJulianDay()
        self.weather:rebuild()
    end
end
function Environment:setPlannedDaysPerPeriod(numDays)
    self.plannedDaysPerPeriod = math.clamp(numDays, 1, Environment.MAX_DAYS_PER_PERIOD)
    self.mission.missionInfo.plannedDaysPerPeriod = self.plannedDaysPerPeriod
end
function Environment:consoleCommandSetDayTime(dayTime, skipDayOnly)
    if not self.mission:getIsServer() then
        return "Error: Server only command"
    end
    local newDayTime = tonumber(dayTime)
    if newDayTime == nil then
        return "Error: Invalid arguments. Arguments: dayTime[h] skipDayOnly[true|false]"
    end
    local newDay = newDayTime * 1000 * 60 * 60
    local newDayTime = math.floor(newDay)
    local newDay = self.currentDay
    local newMonotonicDay = self.currentMonotonicDay
    if newDayTime < self.dayTime then
        if skipDayOnly then
        end
    end
    self:setEnvironmentTime(newMonotonicDay, newDay, newDayTime, self.daysPerPeriod, false)
    self.lighting:setDayTime(self.dayTime, true)
    self.weather.cheatedTime = true
    EnvironmentTimeEvent.broadcastEvent()
    return "DayTime = " .. newDayTime .. ", Day = " .. newDay .. "[" .. newMonotonicDay .. "]"
end
function Environment:consoleCommandSetFixedVisuals(period)
    if period == nil then
        self:setFixedPeriod(nil)
    else
        self:setFixedPeriod((tonumber(period)))
    end
end
function Environment:consoleCommandReloadEnvironment()
    g_messageCenter:unsubscribeAll(self)
    self:load(self.xmlFilename)
    self.lighting:setSunHeightAngle(self.daylight:getSunHeightAngle())
    self.lighting:setDaylightTimes(self.daylight:getDaylightTimes())
    self.lighting:updateCurves()
    self.lighting:setDayTime(self.dayTime, true)
    return "reloaded environment"
end
function Environment:consoleCommandSetFixedExposureSettings(keyValue, minExposure, maxExposure)
    local ret = tonumber(keyValue)
    local ret = tonumber(minExposure)
    local ret = tonumber(maxExposure)
    local minLuminance
    if ret == nil then
        ret = nil
        ret = nil
        minLuminance = "Disabled fixed exposure settings"
    elseif ret == nil then
        minLuminance = string.format("Enabled fixed exposure key %.2f", nil)
    else
        if ret == nil then
        end
        local minLuminance = ret / math.pow(2, ret)
        local maxLuminance = ret / math.pow(2, ret)
        minLuminance = string.format("Enabled fixed exposure settings (key %.2f exposure [%.2f %.2f] [%.4f %.4f])", ret, ret, ret, minLuminance, maxLuminance)
    end
    self.baseLighting:setFixedExposureSettings(ret, ret, ret)
    if self.lighting == self.baseLighting then
        self.baseLighting:updateExposureSettings()
    end
    return minLuminance
end
function Environment:consoleCommandToggleAutoExposure(reset)
    if self.setExposureRange_backup ~= nil then
        setExposureRange = self.setExposureRange_backup
        self.setExposureRange_backup = nil
        return "Reenabled auto exposure"
    end
    self.setExposureRange_backup = setExposureRange
    function setExposureRange() end
    if not Utils.stringToBoolean(reset) then
        return string.format("Paused exposure at current settings: middleGrayValue=%.4f  min=%.4f  max=%.4f", getExposureRange())
    end
    resetAutoExposure()
    return string.format("Disabled + reset auto exposure, current settings: middleGrayValue=%.4f  min=%.4f  max=%.4f", getExposureRange())
end
function Environment.consoleCommandSetExposureFixedLuminance(_, luminance)
    luminance = tonumber(luminance)
    if luminance == nil or luminance < 0 then
        setFixedLuminanceForExposure(-1)
        return "Disabled fixed luminance for exposure"
    else
        setFixedLuminanceForExposure(luminance)
        return string.format("Set fixed luminance for exposure to %.3f. Use -1 to reset", luminance)
    end
end
function Environment:consoleCommandSetSeasonalShader(val)
    if val == nil or tonumber(val) == nil then
        self.forcedSeasonShaderValue = nil
        self:updateSceneParameters()
        return "Reset the value to match the environment"
    end
    val = tonumber(val)
    val = math.min(math.max(val, 0), 4)
    self.forcedSeasonShaderValue = val
    setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, val)
    return "Set shader parameter to " .. tostring(val)
end
function Environment:consoleCommandSeasonalShaderDebug()
    self.debugSeasonalShaderParameter = not self.debugSeasonalShaderParameter
end
function Environment:consoleCommandTakeEnvProbes(numIterations, mobile, outputDirectory)
    local renderResolution = tonumber(numIterations)
    if renderResolution == nil then
        return "Arguments: numIterations (required), mobile(optional, default: false), outputDirectory (optional, default: [map xml-path])"
    end
    if mobile == nil then
        mobile = false
    end
    local renderResolution = 512
    local envMapTimes, baseDirectory
    if self.baseLighting.envMapBasePath == nil then
        envMapTimes = { 0 }
        baseDirectory = g_screenshotsDirectory .. "envProbes/"
    else
        envMapTimes = self.baseLighting.envMapTimes
        baseDirectory = self.baseLighting.envMapBasePath
    end
    if outputDirectory == nil then
        outputDirectory = baseDirectory
    end
    if outputDirectory:sub(outputDirectory:len()) ~= "/" then
    end
    createFolder(outputDirectory)
    print("Writing env maps to " .. outputDirectory)
    if #envMapTimes <= 0 then
        return "Error: no envMapTimes defined in Lighting"
    end
    self.envMapGeneration = {}
    self.envMapGeneration.tasks = {}
    for k, cloudData in ipairs(self.weather.envMapCloudProbes) do
        table.insert(self.envMapGeneration.tasks, {
            ["cloudData"] = cloudData,
            ["setDefaultValues"] = true,
            ["windDirX"] = 0,
            ["windDirZ"] = 1,
            ["windVelocity"] = 0,
            ["cirrusCloudSpeedFactor"] = 0
        })
        table.insert(self.envMapGeneration.tasks, {})
        table.insert(self.envMapGeneration.tasks, {})
        table.insert(self.envMapGeneration.tasks, {})
        table.insert(self.envMapGeneration.tasks, {})
        table.insert(self.envMapGeneration.tasks, {})
        table.insert(self.envMapGeneration.tasks, {})
        for _, dayTime in ipairs(envMapTimes) do
            local renderData = {
                ["dayTime"] = dayTime,
                ["renderResolution"] = renderResolution,
                ["outputResolution"] = mobile and 128 or 256,
                ["numIterations"] = renderResolution
            }
            if mobile then
                renderData.cloudData = cloudData
                renderData.windDirX = 0
                renderData.windDirZ = 1
                renderData.windVelocity = 0
                renderData.cirrusCloudSpeedFactor = 0
                renderData.ssaoQuality = 0
            else
                renderData.ssaoQuality = 15
            end
            renderData.filename = outputDirectory .. Lighting.getEnvMapBaseFilename(dayTime, k)
            table.insert(self.envMapGeneration.tasks, renderData)
        end
    end
    local cloudUpdater = self.weather.cloudUpdater
    local currentData = {
        ["lastClouds"] = cloudUpdater.lastClouds:clone(),
        ["targetClouds"] = cloudUpdater.targetClouds:clone(),
        ["alpha"] = cloudUpdater.alpha,
        ["duration"] = cloudUpdater.duration,
        ["windDirX"] = cloudUpdater.windDirX,
        ["windDirZ"] = cloudUpdater.windDirZ,
        ["windVelocity"] = cloudUpdater.windVelocity,
        ["cirrusCloudSpeedFactor"] = cloudUpdater.cirrusCloudSpeedFactor,
        ["growthMode"] = g_currentMission.growthSystem:getGrowthMode(),
        ["dayTime"] = self.dayTime,
        ["currentMonotonicDay"] = self.currentMonotonicDay,
        ["currentDay"] = self.currentDay
    }
    self.envMapGeneration.currentData = currentData
    g_currentMission.growthSystem:setGrowthMode(GrowthMode.DISABLED, true)
    return "Starting env map generation"
end