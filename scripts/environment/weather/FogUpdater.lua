FogUpdater = {}
local FogUpdater_mt = Class(FogUpdater)
function FogUpdater.new(customMt)
    -- upvalues: (copy) FogUpdater_mt
    local self = setmetatable({}, customMt or FogUpdater_mt)
    self.isDebugEnabled = false
    self.isDirty = false
    self.alpha = 1
    self.visibilityAlpha = 1
    self.duration = 1
    self.lastFog = FogSettings.new()
    self.targetFog = FogSettings.new()
    self.currentFog = FogSettings.new()
    self.fadeDuration = 1800000
    if not g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission:getIsServer() then
        addConsoleCommand("gsWeatherSetFog", "Sets fog values", "consoleCommandWeatherSetFog", self, "enabled;coverageEdge0;coverageEdge1;groundFogLevelDensity;groundFogExtraHeight;groundFogMinVallyDepth;heightFogMaxHeight;heightFogLevelDensity")
    end
    setGroundFogWind(0, 1, 0)
    setGroundFogVolumeNoiseWind(0, 0, 1, 0)
    return self
end
function FogUpdater:delete()
    removeConsoleCommand("gsWeatherSetFog")
end
function FogUpdater:update(scaledDt)
    if not self.isDebugEnabled then
        if self.alpha ~= 1 then
            self.alpha = math.min(self.alpha + scaledDt / self.duration, 1)
            local alpha = self.alpha
            local lastFog = self.lastFog
            local targetFog = self.targetFog
            self.currentFog.groundFogCoverageEdge0 = MathUtil.lerp(lastFog.groundFogCoverageEdge0, targetFog.groundFogCoverageEdge0, alpha)
            currentFog.groundFogCoverageEdge1 = MathUtil.lerp(lastFog.groundFogCoverageEdge1, targetFog.groundFogCoverageEdge1, alpha)
            currentFog.groundFogExtraHeight = MathUtil.lerp(lastFog.groundFogExtraHeight, targetFog.groundFogExtraHeight, alpha)
            currentFog.groundFogGroundLevelDensity = MathUtil.lerp(lastFog.groundFogGroundLevelDensity, targetFog.groundFogGroundLevelDensity, alpha)
            currentFog.groundFogMinValleyDepth = MathUtil.lerp(lastFog.groundFogMinValleyDepth, targetFog.groundFogMinValleyDepth, alpha)
            currentFog.heightFogMaxHeight = MathUtil.lerp(lastFog.heightFogMaxHeight, targetFog.heightFogMaxHeight, alpha)
            currentFog.heightFogGroundLevelDensity = MathUtil.lerp(lastFog.heightFogGroundLevelDensity, targetFog.heightFogGroundLevelDensity, alpha)
            self.isDirty = true
        end
        local alpha = self:getIsFogPossible()
        local currentFog = false
        local lastFog = 1
        if alpha and self.visibilityAlpha < 1 then
            currentFog = true
            lastFog = 1
        elseif not alpha and self.visibilityAlpha > 0 then
            currentFog = true
            lastFog = -1
        end
        if currentFog then
            self.visibilityAlpha = math.clamp(self.visibilityAlpha + lastFog * scaledDt / self.fadeDuration, 0, 1)
            self.isDirty = true
        end
        if self.isDirty then
            local targetFog = self.currentFog
            local coverageEdge0 = MathUtil.lerp(1, targetFog.groundFogCoverageEdge0, self.visibilityAlpha)
            local coverageEdge1 = MathUtil.lerp(1, targetFog.groundFogCoverageEdge1, self.visibilityAlpha)
            setGroundFogGlobalCoverage(coverageEdge0, coverageEdge1)
            setGroundFogHeight(targetFog.groundFogExtraHeight)
            setGroundFogGroundLevelDensity(targetFog.groundFogGroundLevelDensity)
            setGroundFogMinimumValleyDepth(targetFog.groundFogMinValleyDepth)
            setHeightFogGroundLevelDensity(targetFog.heightFogGroundLevelDensity)
            setHeightFogMaxHeight(targetFog.heightFogMaxHeight)
            self.isDirty = false
        end
    end
end
function FogUpdater:getIsFogPossible()
    local currentFog = self.currentFog
    local environment = g_currentMission.environment
    if environment == nil then
        return false
    end
    local weatherType = environment.weather:getCurrentWeatherType()
    if currentFog.groundFogWeatherTypes[weatherType] == nil then
        return false
    end
    return not MathUtil.getIsOutOfBounds(environment.dayTime / 1000 / 60, currentFog.groundFogStartDayTimeMinutes, currentFog.groundFogEndDayTimeMinutes)
end
function FogUpdater:saveToXMLFile(xmlFile, key)
    self.targetFog:saveToXMLFile(xmlFile, key .. ".target")
    self.lastFog:saveToXMLFile(xmlFile, key .. ".last")
    xmlFile:setFloat(key .. "#alpha", self.alpha)
    xmlFile:setFloat(key .. "#visibilityAlpha", self.visibilityAlpha)
    xmlFile:setFloat(key .. "#duration", self.duration)
end
function FogUpdater:loadFromXMLFile(xmlFile, key)
    self.alpha = xmlFile:getFloat(key .. "#alpha") or self.alpha
    self.visibilityAlpha = xmlFile:getFloat(key .. "#visibilityAlpha") or self.visibilityAlpha
    self.duration = xmlFile:getFloat(key .. "#duration") or self.duration
    self.targetFog:loadFromXMLFile(xmlFile, key .. ".target")
    self.lastFog:loadFromXMLFile(xmlFile, key .. ".last")
    if self.alpha == 1 then
        self.currentFog = self.targetFog:clone()
    else
        self.currentFog = self.lastFog:clone()
    end
    self.currentFog.groundFogWeatherTypes = table.clone(self.targetFog.groundFogWeatherTypes)
    self.isDirty = true
end
function FogUpdater:setTargetFog(fog, duration)
    self.alpha = 0
    self.duration = math.max(1, duration)
    self.lastFog = self.targetFog
    if fog == nil then
        fog = self.lastFog:clone()
        fog:disableGroundFog()
    end
    self.targetFog = fog
    self.currentFog.groundFogWeatherTypes = table.clone(fog.groundFogWeatherTypes)
end
function FogUpdater:addDebugValues(data)
    local currentFog = self.currentFog
    table.insert(data, {
        ["name"] = "FOG - Ground",
        ["value"] = ""
    })
    table.insert(data, {
        ["name"] = "Coverage Edge0",
        ["value"] = string.format("%.2f", currentFog.groundFogCoverageEdge0)
    })
    table.insert(data, {
        ["name"] = "Coverage Edge1",
        ["value"] = string.format("%.2f", currentFog.groundFogCoverageEdge1)
    })
    table.insert(data, {
        ["name"] = "Height",
        ["value"] = string.format("%.2f", currentFog.groundFogExtraHeight)
    })
    table.insert(data, {
        ["name"] = "GroundLevelDensity",
        ["value"] = string.format("%.2f", currentFog.groundFogGroundLevelDensity)
    })
    table.insert(data, {
        ["name"] = "MinimumValleyDepth",
        ["value"] = string.format("%.2f", currentFog.groundFogMinValleyDepth)
    })
    table.insert(data, {
        ["name"] = "",
        ["value"] = ""
    })
    table.insert(data, {
        ["name"] = "FOG - Height",
        ["value"] = ""
    })
    table.insert(data, {
        ["name"] = "GroundLevelDensity",
        ["value"] = string.format("%.2f", currentFog.heightFogGroundLevelDensity)
    })
    table.insert(data, {
        ["name"] = "MaxHeight",
        ["value"] = string.format("%.2f", currentFog.heightFogMaxHeight)
    })
end
function FogUpdater:consoleCommandWeatherSetFog(enabled, coverageEdge0, coverageEdge1, groundFogLevelDensity, groundFogExtraHeight, groundFogMinVallyDepth, heightFogMaxHeight, heightFogLevelDensity)
    local isEnabled = string.lower(enabled or "true") == "true"
    self.isDebugEnabled = isEnabled
    coverageEdge0 = tonumber(coverageEdge0) or 0.15
    coverageEdge1 = tonumber(coverageEdge1) or 1
    if coverageEdge1 >= coverageEdge0 then
    end
    groundFogLevelDensity = tonumber(groundFogLevelDensity) or 0.25
    groundFogExtraHeight = tonumber(groundFogExtraHeight) or 20
    groundFogMinVallyDepth = tonumber(groundFogMinVallyDepth) or 1.5
    heightFogMaxHeight = tonumber(heightFogMaxHeight) or 550
    heightFogLevelDensity = tonumber(heightFogLevelDensity) or 0.6
    local stateText
    if isEnabled then
        stateText = "Updated Values"
    else
        stateText = "Reset Values"
        local currentFog = self.currentFog
        coverageEdge1 = currentFog.groundFogCoverageEdge0
        coverageEdge0 = currentFog.groundFogCoverageEdge1
        groundFogLevelDensity = currentFog.groundFogGroundLevelDensity
        groundFogExtraHeight = currentFog.groundFogExtraHeight
        groundFogMinVallyDepth = currentFog.groundFogMinValleyDepth
        heightFogMaxHeight = currentFog.heightFogMaxHeight
        heightFogLevelDensity = currentFog.heightFogGroundLevelDensity
    end
    setGroundFogGlobalCoverage(coverageEdge1, coverageEdge0)
    setGroundFogGroundLevelDensity(groundFogLevelDensity)
    setGroundFogHeight(groundFogExtraHeight)
    setGroundFogMinimumValleyDepth(groundFogMinVallyDepth)
    setHeightFogMaxHeight(heightFogMaxHeight)
    setHeightFogGroundLevelDensity(heightFogLevelDensity)
    return string.format("Fog - %s - GroundFog: Coverage %.3f %.3f | Density %.3f | ExtraHeight %.3f | MinVallyDepth %.3f - HeightFog: MaxHeight %.3f | Density %.3f", stateText, coverageEdge1, coverageEdge0, groundFogLevelDensity, groundFogExtraHeight, groundFogMinVallyDepth, heightFogMaxHeight, heightFogLevelDensity)
end