Lighting = {}
local Lighting_mt = Class(Lighting)
function Lighting.new(customMt)
    -- upvalues: (copy) Lighting_mt
    local self = setmetatable({}, customMt or Lighting_mt)
    self.updateInterval = 10000
    self.lastUpdateDayTime = 0
    self.lastDaylightFactor = 1
    self.cloudEnvMapIndex1 = 1
    self.cloudEnvMapIndex2 = 1
    self.cloudEnvMapBlendAlpha = 0
    self.dayTime = 0
    self.sunHeightAngle = 0
    self.sunColor = nil
    self.snowHeight = 0
    self.snowHeightThreshold = 0.06
    self.dayStart = 6.55
    self.dayEnd = 18.1
    self.nightEnd = 5
    self.nightStart = 19.81
    self.currentVisualSeason = Season.SPRING
    self.alpha = 1
    self.lastSunRotation = 0
    self.currentSunRotation = 0
    self.targetSunRotation = 0
    self.sunUpdateDuration = 4000
    self.updateSunThreshold = 0.03490658503988659
    self.isInitialSunUpdate = true
    self.lastSunUpdateRotation = 0
    return self
end
function Lighting:delete() end
function Lighting:load(xmlFile, baseKey, baseDirectory)
    local envMapFile = xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotation", 60)
    self.heightAngleLimitRotation = math.rad(envMapFile)
    local envMapFile = xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotationStart", 56)
    self.heightAngleLimitRotationStart = math.rad(envMapFile)
    local envMapFile = xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotationEnd", 80)
    self.heightAngleLimitRotationEnd = math.rad(envMapFile)
    self.sunRotationCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunRotation", true)
    self.moonBrightnessScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".moonBrightnessScale")
    self.moonSizeScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".moonSizeScale")
    self.sunIsPrimaryCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunIsPrimary")
    self.sunBrightnessScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunBrightnessScale")
    self.sunSizeScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunSizeScale")
    self.asymmetryFactorCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".asymmetryFactor")
    self.primaryExtraterrestrialColorCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".primaryExtraterrestrialColor")
    self.secondaryExtraterrestrialColorCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".secondaryExtraterrestrialColor")
    self.primaryDynamicLightingScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".primaryDynamicLightingScale")
    self.lightScatteringRotationCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".lightScatteringRotation", true)
    self.autoExposureCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".autoExposure")
    local cloudShadowsTransmittanceBoostData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".cloudShadowsTransmittanceBoost")
    if #cloudShadowsTransmittanceBoostData > 0 then
        self.cloudShadowsTransmittanceBoostData = cloudShadowsTransmittanceBoostData
    end
    if Platform.usesFixedExposure then
        self.fixedExposureCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".fixedExposure")
    end
    self.colorGradingData = self:loadFileCurveDataFromXML(xmlFile, baseKey .. ".colorGrading", baseDirectory)
    self.bloomMagnitude = xmlFile:getFloat(baseKey .. ".bloom#magnitude") or 0.5
    self.bloomThreshold = xmlFile:getFloat(baseKey .. ".bloom#threshold") or 2
    self.toneMappingCurveSlope = xmlFile:getFloat(baseKey .. ".toneMapping#slope") or 1
    self.toneMappingCurveToe = xmlFile:getFloat(baseKey .. ".toneMapping#toe") or 0.4
    self.toneMappingCurveShoulder = xmlFile:getFloat(baseKey .. ".toneMapping#shoulder") or 0.8
    self.toneMappingCurveBlackClip = xmlFile:getFloat(baseKey .. ".toneMapping#blackClip") or 0
    self.toneMappingCurveWhiteClip = xmlFile:getFloat(baseKey .. ".toneMapping#whiteClip") or 0.04
    self.envMapTimes = {}
    for _, timeProbeKey in xmlFile:iterator(baseKey .. ".envMap.timeProbe") do
        local timeHours = xmlFile:getFloat(timeProbeKey .. "#timeHours")
        if timeHours ~= nil then
            table.insert(self.envMapTimes, timeHours)
        end
    end
    table.sort(self.envMapTimes)
    self.defaultEnvMap = Utils.getFilename("$shared/default_env.png", baseDirectory)
    self.envMapBasePath = xmlFile:getString(baseKey .. ".envMap#basePath")
    if self.envMapBasePath ~= nil then
        self.envMapBasePath = Utils.getFilename(self.envMapBasePath, baseDirectory)
        if not string.endsWith(self.envMapBasePath, "/") then
            self.envMapBasePath = self.envMapBasePath .. "/"
        end
        if #self.envMapTimes > 0 then
            local envMapFile = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[1], 1) .. ".png"
            if not textureFileExists(envMapFile) then
                Logging.xmlError(xmlFile, "EnvMap \'%s\' does not exist!", envMapFile)
                self.envMapBasePath = nil
            end
        end
    end
    self.envMapRenderingMode = false
    self.albedoGroundColors = {
        [Season.SPRING] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.spring#value", { 0, 0, 0 }, 3),
        [Season.SUMMER] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.summer#value", { 0, 0, 0 }, 3),
        [Season.AUTUMN] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.autumn#value", { 0, 0, 0 }, 3),
        [Season.WINTER] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.winter#value", { 0, 0, 0 }, 3),
        ["snow"] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.snow#value", { 0, 0, 0 }, 3)
    }
    self.lastUpdateDayTime = 0
    self.lastDaylightFactor = 1
    return true
end
function Lighting:apply()
    setBloomMagnitude(self.bloomMagnitude)
    setBloomMaskThreshold(self.bloomThreshold)
    setToneMappingCurveSlope(self.toneMappingCurveSlope)
    setToneMappingCurveToe(self.toneMappingCurveToe)
    setToneMappingCurveShoulder(self.toneMappingCurveShoulder)
    setToneMappingCurveBlackClip(self.toneMappingCurveBlackClip)
    setToneMappingCurveWhiteClip(self.toneMappingCurveWhiteClip)
end
function Lighting.loadCurveDataFromXML(_, xmlFile, baseKey, convertRadians)
    local data = {}
    for _, timeKey in xmlFile:iterator(baseKey .. ".key") do
        local time = xmlFile:getFloat(timeKey .. "#time")
        local values = string.split(xmlFile:getString(timeKey .. "#value"), " ")
        for j, value in ipairs(values) do
            local number = tonumber(value)
            if convertRadians then
                number = math.rad(number)
            end
            values[j] = number
        end
        table.insert(data, { time, values })
    end
    return data
end
function Lighting.loadFileCurveDataFromXML(_, xmlFile, baseKey, baseDirectory)
    local data = {}
    for _, timeKey in xmlFile:iterator(baseKey .. ".key") do
        table.insert(data, { xmlFile:getFloat(timeKey .. "#timeHours"), (Utils.getFilename(xmlFile:getString(timeKey .. "#filename"), baseDirectory)) })
    end
    return data
end
function Lighting:reset()
    resetAutoExposure()
end
function Lighting:setCloudEnvMapInfo(cloudEnvMapIndex1, cloudEnvMapIndex2, alpha)
    self.cloudEnvMapIndex1 = cloudEnvMapIndex1
    self.cloudEnvMapIndex2 = cloudEnvMapIndex2
    self.cloudEnvMapBlendAlpha = alpha
end
function Lighting:update(dt, _)
    if self.alpha ~= 1 then
        self.alpha = math.min(self.alpha + dt / self.sunUpdateDuration, 1)
        self.currentSunRotation = MathUtil.lerp(self.lastSunRotation, self.targetSunRotation, self.alpha)
        self.isSunDirty = true
    end
    if self.isSunDirty then
        local dx, dy, dz = mathEulerRotateVector(self.sunHeightAngle, 0, self.currentSunRotation, 0, 0, 1)
        if dy < self.sunHeightLimitStart then
            if dy <= self.sunHeightLimitEnd then
                dy = self.sunHeightLimit
            end
            local limitAlpha = math.sqrt((1 - dy * dy) / (dx * dx + dz * dz))
            dx = dx * limitAlpha
            dz = dz * limitAlpha
        end
        setDirection(self.sunLightId, dx, dy, dz, 0, 1, 0)
        self.isSunDirty = false
    end
end
function Lighting:setDayTime(dayTime, force)
    if not force then
        if math.abs(dayTime - self.lastUpdateDayTime) <= self.updateInterval then
            ::l3::
            return
        end
    end
    local dayMinutes = dayTime / 60000
    self:updateSunLocation(dayTime, dayMinutes)
    self:updateEnvMap(self:getHardcodedFromTime(dayMinutes / 60) * 60, force)
    self:updateEnvAlbedo()
    self:updateAtmosphere(dayMinutes)
    local gradingFile1, gradingFile2, gradingAlpha = self.colorGradingFileCurve:get(dayMinutes)
    setColorGradingSettings(gradingFile1, gradingFile2, gradingAlpha)
    self:updateExposureSettings()
    local dayHours = dayMinutes / 60
    if self.dayStart < dayHours and dayHours < self.dayEnd then
        self.lastDaylightFactor = 1
    elseif self.dayEnd <= dayHours and dayHours < self.nightStart then
        self.lastDaylightFactor = 1 - (dayHours - self.dayEnd) / (self.nightStart - self.dayEnd)
    elseif self.nightStart <= dayHours or dayHours < self.nightEnd then
        self.lastDaylightFactor = 0
    elseif self.nightEnd <= dayHours and dayHours < self.dayStart then
        self.lastDaylightFactor = (dayHours - self.nightEnd) / (self.dayStart - self.nightEnd)
    else
        self.lastDaylightFactor = 0
    end
    self.lastUpdateDayTime = dayTime
    goto l3
end
function Lighting:updateSunHeight()
    _, self.sunHeightLimit, _ = mathEulerRotateVector(self.sunHeightAngle, 0, self.heightAngleLimitRotation, 0, 0, 1)
    _, self.sunHeightLimitStart, _ = mathEulerRotateVector(self.sunHeightAngle, 0, self.heightAngleLimitRotationStart, 0, 0, 1)
    _, self.sunHeightLimitEnd, _ = mathEulerRotateVector(self.sunHeightAngle, 0, self.heightAngleLimitRotationEnd, 0, 0, 1)
end
function Lighting:setSunHeightAngle(sunHeightAngle)
    self.sunHeightAngle = sunHeightAngle
end
function Lighting:updateSunLocation(_, dayMinutes)
    local sunRotation = self.sunRotCurve:get(dayMinutes)
    local x = sunRotation - self.lastSunUpdateRotation
    if math.abs(x) > self.updateSunThreshold then
        self.lastSunRotation = self.currentSunRotation
        self.targetSunRotation = sunRotation
        self.lastSunUpdateRotation = sunRotation
        self.alpha = 0
        self.isSunDirty = true
        if self.isInitialSunUpdate then
            self.isInitialSunUpdate = false
            self.currentSunRotation = sunRotation
            self.alpha = 1
        end
    end
    local x = 0
    local y
    if dayMinutes < 360 then
        y = 4.713 + 1.571 * (dayMinutes / 360)
    elseif dayMinutes < 1080 then
        y = 3.142 + 3.142 * (1 - (dayMinutes - 360) / 720)
    else
        y = 3.142 + 1.571 * ((dayMinutes - 1080) / 360)
    end
    if dayMinutes < 480 then
    elseif dayMinutes > 960 then
    end
    if g_fruitTypeManager ~= nil then
        for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
            if fruitType.alignsToSun and fruitType.terrainDataPlaneId ~= nil then
                setFoliageShaderParameter(fruitType.terrainDataPlaneId, "plantRotate", x, y, 0, 0)
            end
        end
    end
end
function Lighting:updateEnvMap(dayMinutes, force)
    if self.envMapBasePath == nil or #self.envMapTimes == 0 then
        setEnvMap(self.defaultEnvMap, self.defaultEnvMap, self.defaultEnvMap, self.defaultEnvMap, 1, 0, 0, 0, force, true)
        return
    end
    local envMapTime0Cloud0 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[1], 1) .. ".png"
    local blendTime = 0
    local blendCloud = 0
    local envMapTime0Cloud1, envMapTime1Cloud0, envMapTime1Cloud1
    if #self.envMapTimes > 1 then
        local dayHours = dayMinutes / 60
        local timeSecondIndex = 1
        for i, time in ipairs(self.envMapTimes) do
            if dayHours < time then
                timeSecondIndex = i
                break
            end
        end
        local timeFirstIndex = timeSecondIndex - 1
        local timeFirstIndex = timeFirstIndex <= 0 and #self.envMapTimes or timeFirstIndex
        blendTime = MathUtil.timeLerp(self.envMapTimes[timeFirstIndex], self.envMapTimes[timeSecondIndex], dayHours)
        local i = self.cloudEnvMapIndex1
        local time = self.cloudEnvMapIndex2
        blendCloud = self.cloudEnvMapBlendAlpha
        envMapTime0Cloud0 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[timeFirstIndex], i) .. ".png"
        envMapTime0Cloud1 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[timeFirstIndex], time) .. ".png"
        envMapTime1Cloud0 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[timeSecondIndex], i) .. ".png"
        envMapTime1Cloud1 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[timeSecondIndex], time) .. ".png"
    else
        envMapTime1Cloud1 = envMapTime0Cloud0
        envMapTime1Cloud0 = envMapTime1Cloud1
        envMapTime0Cloud1 = envMapTime1Cloud0
        envMapTime1Cloud1 = envMapTime0Cloud1
        envMapTime1Cloud0 = envMapTime1Cloud1
    end
    local dayHours = (1 - blendTime) * (1 - blendCloud)
    local timeSecondIndex = (1 - blendTime) * blendCloud
    local timeFirstIndex = blendTime * (1 - blendCloud)
    local startTime = blendTime * blendCloud
    if self.envMapRenderingMode then
        setEnvMap(envMapTime0Cloud0, envMapTime0Cloud1, envMapTime1Cloud0, envMapTime1Cloud1, 0, 0, 0, 0, true, false)
    else
        setEnvMap(envMapTime0Cloud0, envMapTime0Cloud1, envMapTime1Cloud0, envMapTime1Cloud1, dayHours, timeSecondIndex, timeFirstIndex, startTime, force or false, false)
    end
end
function Lighting:setSnowHeight(snowHeight)
    self.snowHeight = snowHeight
end
function Lighting:setSnowHeightThreshold(threshold)
    self.snowHeightThreshold = threshold
end
function Lighting:setVisualSeason(season)
    self.currentVisualSeason = season
end
function Lighting:updateEnvAlbedo()
    if self.snowHeight >= self.snowHeightThreshold then
        local r, g, b = unpack(self.albedoGroundColors.snow)
        setEnvAlbedoGroundColor(r, g, b)
    else
        local r, g, b = unpack(self.albedoGroundColors[self.currentVisualSeason])
        setEnvAlbedoGroundColor(r, g, b)
    end
end
function Lighting:updateAtmosphere(dayMinutes)
    local primaryScatteringRotation, secondaryScatteringRotation = self.lightScatteringRotCurve:get(dayMinutes)
    local pLscX, pLscY, pLscZ = mathEulerRotateVector(self.sunHeightAngle, 0, primaryScatteringRotation, 0, 0, 1)
    setLightScatteringDirection(self.sunLightId, pLscX, pLscY, pLscZ)
    local sLscX, sLscY, sLscZ = mathEulerRotateVector(self.sunHeightAngle, 0, secondaryScatteringRotation, 0, 0, 1)
    local sdr, sdg, sdb = self.secondaryExtraterrestrialColor:get(dayMinutes)
    setAtmosphereSecondaryLightSource(sLscX, sLscY, sLscZ, sdr, sdg, sdb)
    local asymmetryFactor = self.asymmetryFactorCurve:get(dayMinutes)
    setAtmosphereCornetteShankAsymmetryFactor(asymmetryFactor)
    local sunSizeScale = self.sunSizeScaleCurve:get(dayMinutes)
    setSunSizeScale(sunSizeScale)
    local moonSizeScale = self.moonSizeScaleCurve:get(dayMinutes)
    setMoonSizeScale(moonSizeScale)
    local sunIsPrimary = self.sunIsPrimaryCurve:get(dayMinutes) > 0.5
    setSunIsPrimary(sunIsPrimary)
    local moonBrightnessScale = self.moonBrightnessScaleCurve:get(dayMinutes)
    local sunBrightnessScale = self.sunBrightnessScaleCurve:get(dayMinutes)
    if self.envMapRenderingMode then
        if sunIsPrimary then
        end
    end
    setSunBrightnessScale(sunBrightnessScale)
    if self.cloudShadowsTransmittanceCurve ~= nil then
        local cloudShadowsTransmittanceBoost = self.cloudShadowsTransmittanceCurve:get(dayMinutes)
        setCloudShadowsTransmittanceBoost(cloudShadowsTransmittanceBoost)
    end
    local cloudShadowsTransmittanceBoost, dg, db = self.primaryExtraterrestrialColor:get(dayMinutes)
    local dynamicLightingScale = self.primaryDynamicLightingScale:get(dayMinutes)
    setLightColor(self.sunLightId, cloudShadowsTransmittanceBoost * dynamicLightingScale, dg * dynamicLightingScale, db * dynamicLightingScale)
    setLightScatteringColor(self.sunLightId, cloudShadowsTransmittanceBoost, dg, db)
end
function Lighting:updateExposureSettings()
    local minExposure, keyValue, maxExposure
    if Platform.usesFixedExposure then
        if self.fixedKeyValue == nil or self.fixedMinExposure == nil then
            minExposure = self.fixedExposureCurve:get(self.dayTime / 60000)
            keyValue = 0.18
            maxExposure = minExposure
        else
            keyValue = self.fixedKeyValue
            minExposure = self.fixedMinExposure
            maxExposure = self.fixedMaxExposure
        end
    elseif self.fixedKeyValue == nil then
        keyValue, minExposure, maxExposure = self.autoExposureCurve:get(dayMinutes)
    elseif self.fixedMinExposure == nil then
        _, minExposure, maxExposure = self.autoExposureCurve:get(dayMinutes)
        keyValue = self.fixedKeyValue
    else
        keyValue = self.fixedKeyValue
        minExposure = self.fixedMinExposure
        maxExposure = self.fixedMaxExposure
    end
    setExposureRange(keyValue, minExposure, maxExposure)
end
function Lighting:updateCurves()
    self.lightScatteringRotCurve = self:createCurve(linearInterpolator2, self.lightScatteringRotationCurveData)
    self.asymmetryFactorCurve = self:createCurve(linearInterpolator1, self.asymmetryFactorCurveData)
    self.sunBrightnessScaleCurve = self:createCurve(linearInterpolator1, self.sunBrightnessScaleCurveData)
    self.sunSizeScaleCurve = self:createCurve(linearInterpolator1, self.sunSizeScaleCurveData)
    self.moonBrightnessScaleCurve = self:createCurve(linearInterpolator1, self.moonBrightnessScaleCurveData)
    self.moonSizeScaleCurve = self:createCurve(linearInterpolator1, self.moonSizeScaleCurveData)
    self.sunIsPrimaryCurve = self:createCurve(linearInterpolator1, self.sunIsPrimaryCurveData)
    self.primaryDynamicLightingScale = self:createCurve(linearInterpolator1, self.primaryDynamicLightingScaleCurveData)
    self.primaryExtraterrestrialColor = self:createCurve(linearInterpolator3, self.primaryExtraterrestrialColorCurveData)
    self.secondaryExtraterrestrialColor = self:createCurve(linearInterpolator3, self.secondaryExtraterrestrialColorCurveData)
    self.autoExposureCurve = self:createCurve(linearInterpolator3, self.autoExposureCurveData)
    if Platform.usesFixedExposure then
        self.fixedExposureCurve = self:createCurve(linearInterpolator1, self.fixedExposureCurveData)
    end
    if self.cloudShadowsTransmittanceBoostData ~= nil then
        self.cloudShadowsTransmittanceCurve = self:createCurve(linearInterpolator1, self.cloudShadowsTransmittanceBoostData)
    end
    self.colorGradingFileCurve = self:getColorGradingFileCurve()
    self:updateSunHeight()
    self.sunRotCurve = self:createCurve(linearInterpolator1, self.sunRotationCurveData)
end
function Lighting:createCurve(interpolator, data)
    local curve = AnimCurve.new(interpolator)
    if data == nil then
        printCallstack()
    end
    local i = 1
    for i = i, #data do
        local values = data[i]
        curve:addKeyframe({
            ["time"] = self:getTimeFromHardcoded(values[1]) * 60,
            unpack(values[2])
        })
    end
    return curve
end
function Lighting:getTimeFromHardcoded(hardcoded)
    local nightStart = self.nightStart
    if hardcoded < 6 then
        return self.nightEnd * (hardcoded / 6)
    end
    if hardcoded >= 6 and hardcoded < 7 then
        return (self.dayStart - nightEnd) * (hardcoded - 6) + nightEnd
    end
    if hardcoded >= 7 and hardcoded < 19 then
        return (self.dayEnd - dayStart) * ((hardcoded - 7) / 12) + dayStart
    end
    if hardcoded >= 19 and hardcoded < 20 then
        return (nightStart - dayEnd) * (hardcoded - 19) + dayEnd
    end
    if hardcoded < 20 or hardcoded > 24 then
        return 0
    end
    local alpha = (hardcoded - 20) / 4
    return (24 - nightStart) * alpha + nightStart
end
function Lighting:getHardcodedFromTime(time)
    local nightEnd = self.nightEnd
    if time < nightEnd then
        return 6 * (time / nightEnd)
    elseif nightEnd <= time and time < self.dayStart then
        return 1 * ((time - nightEnd) / (dayStart - nightEnd)) + 6
    elseif dayStart <= time and time < self.dayEnd then
        return 12 * ((time - dayStart) / (dayEnd - dayStart)) + 7
    elseif dayEnd <= time and time < self.nightStart then
        return 1 * ((time - dayEnd) / (nightStart - dayEnd)) + 19
    else
        return 4 * ((time - nightStart) / (24 - nightStart)) + 20
    end
end
function Lighting:getColorGradingFileCurve()
    local curve = AnimCurve.new(Lighting.fileInterpolator)
    for _, data in ipairs(self.colorGradingData) do
        curve:addKeyframe({
            ["time"] = self:getTimeFromHardcoded(data[1]) * 60,
            ["file"] = data[2]
        })
    end
    return curve
end
function Lighting:setDaylightTimes(dayStart, dayEnd, nightEnd, nightStart)
    if self.dayStart ~= dayStart and (self.dayEnd ~= dayEnd and (self.nightEnd ~= nightEnd and self.nightStart ~= nightStart)) then
        self.dayStart = dayStart
        self.dayEnd = dayEnd
        self.nightEnd = nightEnd
        self.nightStart = nightStart
        self:updateCurves()
    end
end
function Lighting:setFixedExposureSettings(keyValue, minExposure, maxExposure)
    if maxExposure == nil then
        maxExposure = minExposure
    end
    self.fixedKeyValue = keyValue
    self.fixedMinExposure = minExposure
    self.fixedMaxExposure = maxExposure
end
function Lighting:getDaylightFactor()
    return self.lastDaylightFactor
end
function Lighting.getEnvMapBaseFilename(dayTimeHours, cloudSetup)
    local hours, minutesPerc = math.modf(dayTimeHours)
    local minutes, seconds = math.modf(minutesPerc * 60)
    return string.format("%d_%d_%d_C%d", hours, minutes, math.floor(seconds * 60), cloudSetup)
end
function Lighting.fileInterpolator(first, second, alpha)
    return first.file, second.file, alpha
end