CloudUpdater = {}
local CloudUpdater_mt = Class(CloudUpdater)
function CloudUpdater.new(customMt)
    -- upvalues: (copy) CloudUpdater_mt
    local self = setmetatable({}, customMt or CloudUpdater_mt)
    self.presets = {}
    self.lastClouds = CloudSettings.new()
    self.currentClouds = CloudSettings.new()
    self.targetClouds = CloudSettings.new()
    self.windDirX = 1
    self.windDirZ = 0
    self.windVelocity = 1
    self.cirrusCloudSpeedFactor = 1
    self.speedScale = 1
    self.alpha = 1
    self.duration = 1
    self.isDirty = true
    return self
end
function CloudUpdater:load(xmlFile, key, _)
    self.presets = {}
    return self:loadPresets(xmlFile, key)
end
function CloudUpdater:delete()
    self.presets = {}
end
function CloudUpdater:update(scaledDt)
    if self.alpha ~= 1 or self.isDirty then
        self:setAlpha((math.min(self.alpha + scaledDt / self.duration, 1)))
        self.isDirty = false
    end
end
function CloudUpdater:setAlpha(alpha)
    self.alpha = alpha
    local lastClouds = self.lastClouds
    local targetClouds = self.targetClouds
    local combinedNoiseEdge0 = MathUtil.lerp(lastClouds.combinedNoiseEdge0, targetClouds.combinedNoiseEdge0, alpha)
    local combinedNoiseEdge1 = MathUtil.lerp(lastClouds.combinedNoiseEdge1, targetClouds.combinedNoiseEdge1, alpha)
    local noise0Weight = MathUtil.lerp(lastClouds.noise0Weight, targetClouds.noise0Weight, alpha)
    local noise0Edge0 = MathUtil.lerp(lastClouds.noise0Edge0, targetClouds.noise0Edge0, alpha)
    local noise0Edge1 = MathUtil.lerp(lastClouds.noise0Edge1, targetClouds.noise0Edge1, alpha)
    local noise1Weight = MathUtil.lerp(lastClouds.noise1Weight, targetClouds.noise1Weight, alpha)
    local noise1Edge0 = MathUtil.lerp(lastClouds.noise1Edge0, targetClouds.noise1Edge0, alpha)
    local noise1Edge1 = MathUtil.lerp(lastClouds.noise1Edge1, targetClouds.noise1Edge1, alpha)
    local noise2Weight = MathUtil.lerp(lastClouds.noise2Weight, targetClouds.noise2Weight, alpha)
    local noise2Edge0 = MathUtil.lerp(lastClouds.noise2Edge0, targetClouds.noise2Edge0, alpha)
    local noise2Edge1 = MathUtil.lerp(lastClouds.noise2Edge1, targetClouds.noise2Edge1, alpha)
    local erosionWeight = MathUtil.lerp(lastClouds.erosionWeight, targetClouds.erosionWeight, alpha)
    local precipitation = MathUtil.lerp(lastClouds.precipitation, targetClouds.precipitation, alpha)
    local baseShapeTiling = MathUtil.lerp(lastClouds.baseShapeTiling, targetClouds.baseShapeTiling, alpha)
    local erosionTiling = MathUtil.lerp(lastClouds.erosionTiling, targetClouds.erosionTiling, alpha)
    local curlNoiseTiling = MathUtil.lerp(lastClouds.curlNoiseTiling, targetClouds.curlNoiseTiling, alpha)
    local curlNoiseHeightFractionModifier = MathUtil.lerp(lastClouds.curlNoiseHeightFractionModifier, targetClouds.curlNoiseHeightFractionModifier, alpha)
    local curlNoiseModifier = MathUtil.lerp(lastClouds.curlNoiseModifier, targetClouds.curlNoiseModifier, alpha)
    local densityScale = MathUtil.lerp(lastClouds.densityScale, targetClouds.densityScale, alpha)
    local cloudGroundAlbedoR = MathUtil.lerp(lastClouds.groundAlbedo[1], targetClouds.groundAlbedo[1], alpha)
    local cloudGroundAlbedoG = MathUtil.lerp(lastClouds.groundAlbedo[2], targetClouds.groundAlbedo[2], alpha)
    local cloudGroundAlbedoB = MathUtil.lerp(lastClouds.groundAlbedo[3], targetClouds.groundAlbedo[3], alpha)
    if combinedNoiseEdge1 < combinedNoiseEdge0 then
    end
    if noise0Edge1 >= noise0Edge0 then
    end
    if noise1Edge1 >= noise1Edge0 then
    end
    if noise2Edge1 >= noise2Edge0 then
    end
    local weight = noise0Weight + noise1Weight + noise2Weight
    local noise0Weight = noise0Weight / weight
    local noise1Weight = noise1Weight / weight
    local noise2Weight = noise2Weight / weight
    setGlobalCloudCoverage(combinedNoiseEdge0, combinedNoiseEdge1, noise0Weight, noise0Edge1, noise0Edge0, noise1Weight, noise1Edge1, noise1Edge0, noise2Weight, noise2Edge1, noise2Edge0)
    setCloudCurlNoiseProperties(curlNoiseTiling, curlNoiseHeightFractionModifier, curlNoiseModifier)
    local cirrusCoverage = MathUtil.lerp(lastClouds.cirrusCoverage, targetClouds.cirrusCoverage, alpha)
    setCirrusCloudCoverage(cirrusCoverage)
    setCloudType(lastClouds.type, targetClouds.type, alpha, baseShapeTiling, erosionTiling, erosionWeight)
    setCloudPrecipitation(precipitation)
    setCloudGroundAlbedo(cloudGroundAlbedoR, cloudGroundAlbedoG, cloudGroundAlbedoB)
    setCloudDensityScaling(densityScale)
    self.currentClouds.type = MathUtil.lerp(lastClouds.type, targetClouds.type, alpha)
    self.currentClouds.densityScale = densityScale
    self.currentClouds.precipitation = precipitation
    self.currentClouds.baseShapeTiling = baseShapeTiling
    self.currentClouds.erosionTiling = erosionTiling
    self.currentClouds.combinedNoiseEdge0 = combinedNoiseEdge0
    self.currentClouds.combinedNoiseEdge1 = combinedNoiseEdge1
    self.currentClouds.noise0Weight = noise0Weight
    self.currentClouds.noise0Edge0 = noise0Edge1
    self.currentClouds.noise0Edge1 = noise0Edge0
    self.currentClouds.noise1Weight = noise1Weight
    self.currentClouds.noise1Edge0 = noise1Edge1
    self.currentClouds.noise1Edge1 = noise1Edge0
    self.currentClouds.noise2Weight = noise2Weight
    self.currentClouds.noise2Edge0 = noise2Edge1
    self.currentClouds.noise2Edge1 = noise2Edge0
    self.currentClouds.erosionWeight = erosionWeight
    self.currentClouds.cirrusCoverage = cirrusCoverage
    self.currentClouds.groundAlbedo[1] = cloudGroundAlbedoR
    self.currentClouds.groundAlbedo[2] = cloudGroundAlbedoG
    self.currentClouds.groundAlbedo[3] = cloudGroundAlbedoB
    self.currentClouds.envMapCloudProbeIndex = lastClouds.envMapCloudProbeIndex
    self.currentClouds.curlNoiseTiling = curlNoiseTiling
    self.currentClouds.curlNoiseHeightFractionModifier = curlNoiseHeightFractionModifier
    self.currentClouds.curlNoiseModifier = curlNoiseModifier
end
function CloudUpdater:setTargetClouds(clouds, duration)
    self.alpha = 0
    self.duration = math.max(1, duration)
    self.lastClouds = self.targetClouds
    self.targetClouds = clouds
end
function CloudUpdater:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
    self.windDirX = windDirX
    self.windDirZ = windDirZ
    self.windVelocity = windVelocity
    self.cirrusCloudSpeedFactor = cirrusCloudSpeedFactor
    self:updateCloudWind()
end
function CloudUpdater:updateCloudWind()
    local windDirX = self.windDirX
    local windDirZ = self.windDirZ
    local windVelocity = self.windVelocity * self.speedScale
    if self.slowModeEnabled then
    end
    setCloudWind(-windDirX, windDirZ, windVelocity, -windDirX, -windDirZ, windVelocity * self.cirrusCloudSpeedFactor)
end
function CloudUpdater:setTimeScale(scale)
    self.speedScale = scale
    self.isDirty = true
    self:updateCloudWind()
end
function CloudUpdater:setSlowModeEnabled(enabled)
    self.slowModeEnabled = enabled
end
function CloudUpdater:getCurrentValues()
    return self.currentClouds
end
function CloudUpdater:getEnvMapInfo()
    return self.lastClouds.envMapCloudProbeIndex, self.targetClouds.envMapCloudProbeIndex, self.alpha
end
function CloudUpdater:createCloudSettingsFromPreset(presetId)
    local preset = self:getPreset(presetId)
    if preset == nil then
        return nil
    else
        return preset:clone()
    end
end
function CloudUpdater:getPresets()
    return self.presets
end
function CloudUpdater:getPreset(presetId)
    local upperPresetId = string.upper(presetId)
    return self.presets[upperPresetId]
end
function CloudUpdater:loadPresets(xmlFile, key)
    local numPresets = 0
    for _, presetKey in xmlFile:iterator(key .. ".presets.preset") do
        local id = xmlFile:getString(presetKey .. "#id")
        if id == nil then
            Logging.xmlWarning(xmlFile, "Missing cloud preset id for \'%s\'", presetKey)
            break
        end
        local preset = string.upper(id)
        if self.presets[preset] ~= nil then
            Logging.xmlWarning(xmlFile, "Cloud preset id \'%s\' already exists for \'%s\'", preset, presetKey)
            break
        end
        local preset = CloudSettings.new()
        if preset:load(xmlFile, presetKey) then
            preset.id = preset
        end
        self.presets[preset] = preset
    end
    return numPresets > 0
end
function CloudUpdater:savePresets(xmlFile, key, presetId)
    for _, presetKey in xmlFile:iterator(key .. ".presets.preset") do
        local id = string.upper(xmlFile:getString(presetKey .. "#id"))
        if presetId == nil or id == presetId then
            local preset = self.presets[id]
            if preset ~= nil then
                preset:save(xmlFile, presetKey)
            end
        end
    end
end
function CloudUpdater:addDebugValues(data)
    local cloudData = self.currentClouds
    table.insert(data, {
        ["name"] = "CLOUDS",
        ["value"] = ""
    })
    table.insert(data, {
        ["name"] = "Type",
        ["value"] = string.format("%.2f", cloudData.type)
    })
    table.insert(data, {
        ["name"] = "DensityScale",
        ["value"] = string.format("%.2f", cloudData.densityScale)
    })
    table.insert(data, {
        ["name"] = "Precipitation",
        ["value"] = string.format("%.3f", cloudData.precipitation)
    })
    table.insert(data, {
        ["name"] = "BaseShapeTiling",
        ["value"] = string.format("%.3f", cloudData.baseShapeTiling)
    })
    table.insert(data, {
        ["name"] = "ErosionTiling",
        ["value"] = string.format("%.3f", cloudData.erosionTiling)
    })
    table.insert(data, {
        ["name"] = "CombinedNoiseEdge0",
        ["value"] = string.format("%.3f", cloudData.combinedNoiseEdge0)
    })
    table.insert(data, {
        ["name"] = "CombinedNoiseEdge1",
        ["value"] = string.format("%.3f", cloudData.combinedNoiseEdge1)
    })
    table.insert(data, {
        ["name"] = "Noise0Weight",
        ["value"] = string.format("%.3f", cloudData.noise0Weight)
    })
    table.insert(data, {
        ["name"] = "Noise0Edge0",
        ["value"] = string.format("%.3f", cloudData.noise0Edge0)
    })
    table.insert(data, {
        ["name"] = "Noise0Edge1",
        ["value"] = string.format("%.3f", cloudData.noise0Edge1)
    })
    table.insert(data, {
        ["name"] = "Noise1Weight",
        ["value"] = string.format("%.3f", cloudData.noise1Weight)
    })
    table.insert(data, {
        ["name"] = "Noise1Edge0",
        ["value"] = string.format("%.3f", cloudData.noise1Edge0)
    })
    table.insert(data, {
        ["name"] = "Noise1Edge1",
        ["value"] = string.format("%.3f", cloudData.noise1Edge1)
    })
    table.insert(data, {
        ["name"] = "Noise2Weight",
        ["value"] = string.format("%.3f", cloudData.noise2Weight)
    })
    table.insert(data, {
        ["name"] = "Noise2Edge0",
        ["value"] = string.format("%.3f", cloudData.noise2Edge0)
    })
    table.insert(data, {
        ["name"] = "Noise2Edge1",
        ["value"] = string.format("%.3f", cloudData.noise2Edge1)
    })
    table.insert(data, {
        ["name"] = "ErosionWeight",
        ["value"] = string.format("%.3f", cloudData.erosionWeight)
    })
    table.insert(data, {
        ["name"] = "CirrusCoverage",
        ["value"] = string.format("%.3f", cloudData.cirrusCoverage)
    })
    table.insert(data, {
        ["name"] = "EnvMapIndex",
        ["value"] = string.format("%d", cloudData.envMapCloudProbeIndex)
    })
    table.insert(data, {
        ["name"] = "GroundAlbedo",
        ["value"] = string.format("%.3f %.3f %.3f", cloudData.groundAlbedo[1], cloudData.groundAlbedo[2], cloudData.groundAlbedo[3])
    })
end