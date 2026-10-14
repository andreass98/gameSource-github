LightingStatic = {}
local LightingStatic_mt = Class(LightingStatic, Lighting)
function LightingStatic.new(customMt)
    -- upvalues: (copy) LightingStatic_mt
    return Lighting.new(customMt or LightingStatic_mt)
end
function LightingStatic:load(xmlFile, baseKey, baseDirectory)
    self.sunHeightAngle = -0.8726646259971648
    self.heightAngleLimitRotation = math.rad(xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotation") or 60)
    self.heightAngleLimitRotationStart = math.rad(xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotationStart") or 56)
    self.heightAngleLimitRotationEnd = math.rad(xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotationEnd") or 80)
    self.moonBrightnessScale = xmlFile:getFloat(baseKey .. ".moonBrightnessScale#value")
    self.moonSizeScale = xmlFile:getFloat(baseKey .. ".moonSizeScale#value")
    self.sunIsPrimary = xmlFile:getInt(baseKey .. ".sunIsPrimary#value")
    self.sunBrightnessScale = xmlFile:getFloat(baseKey .. ".sunBrightnessScale#value")
    self.sunSizeScale = xmlFile:getFloat(baseKey .. ".sunSizeScale#value")
    self.asymmetryFactor = xmlFile:getFloat(baseKey .. ".asymmetryFactor#value")
    self.primaryExtraterrestrialColor = xmlFile:getVector(baseKey .. ".primaryExtraterrestrialColor#value", nil, 3)
    self.secondaryExtraterrestrialColor = xmlFile:getVector(baseKey .. ".secondaryExtraterrestrialColor#value", nil, 3)
    self.primaryDynamicLightingScale = xmlFile:getFloat(baseKey .. ".primaryDynamicLightingScale#value")
    self.lightScatteringRotation = xmlFile:getRadiansVector(baseKey .. ".lightScatteringRotation#value", nil, 2)
    self.autoExposure = xmlFile:getVector(baseKey .. ".autoExposure#value", nil, 3)
    self.cloudGroundAlbedo = xmlFile:getVector(baseKey .. ".cloudGroundAlbedo#value", nil, 3)
    if Platform.usesFixedExposure then
        self.fixedExposure = xmlFile:getFloat(baseKey .. ".fixedExposure#value")
    end
    self.colorGrading = Utils.getFilename(xmlFile:getString(baseKey .. ".colorGrading#filename"), baseDirectory)
    local basePath = Utils.getFilename(xmlFile:getString(baseKey .. ".envMap#basePath"), baseDirectory)
    if not string.endsWith(basePath, "/") then
    end
    self.envMap = basePath .. Lighting.getEnvMapBaseFilename(0, 1) .. (GS_IS_MOBILE_VERSION and "_uncompressed" or "") .. ".png"
    self.albedoGroundColor = xmlFile:getVector(baseKey .. ".envAlbedoGroundColor#value", nil, 3) or { 0, 0, 0 }
    self.bloomMagnitude = xmlFile:getFloat(baseKey .. ".bloom#magnitude") or 0.5
    self.bloomThreshold = xmlFile:getFloat(baseKey .. ".bloom#threshold") or 2
    self.toneMappingCurveSlope = xmlFile:getFloat(baseKey .. ".toneMapping#slope") or 1
    self.toneMappingCurveToe = xmlFile:getFloat(baseKey .. ".toneMapping#toe") or 0.4
    self.toneMappingCurveShoulder = xmlFile:getFloat(baseKey .. ".toneMapping#shoulder") or 0.8
    self.toneMappingCurveBlackClip = xmlFile:getFloat(baseKey .. ".toneMapping#blackClip") or 0
    self.toneMappingCurveWhiteClip = xmlFile:getFloat(baseKey .. ".toneMapping#whiteClip") or 0.04
    return true
end
function LightingStatic:update(dt, force) end
function LightingStatic:setDayTime(_, force)
    if force then
        setEnvMap(self.envMap, self.envMap, self.envMap, self.envMap, 1, 0, 0, 0, force, true)
        setColorGradingSettings(self.colorGrading, self.colorGrading, 0)
        setEnvAlbedoGroundColor(unpack(self.albedoGroundColor))
        self:updateAtmosphere()
        self:updateExposureSettings()
    end
end
function LightingStatic:updateAtmosphere()
    local pLscX, pLscY, pLscZ = mathEulerRotateVector(self.sunHeightAngle, 0, self.lightScatteringRotation[1], 0, 0, 1)
    setLightScatteringDirection(self.sunLightId, pLscX, pLscY, pLscZ)
    local sLscX, sLscY, sLscZ = mathEulerRotateVector(self.sunHeightAngle, 0, self.lightScatteringRotation[2], 0, 0, 1)
    setAtmosphereSecondaryLightSource(sLscX, sLscY, sLscZ, self.secondaryExtraterrestrialColor[1], self.secondaryExtraterrestrialColor[2], self.secondaryExtraterrestrialColor[3])
    setAtmosphereCornetteShankAsymmetryFactor(self.asymmetryFactor)
    setSunSizeScale(self.sunSizeScale)
    setMoonSizeScale(self.moonSizeScale)
    local moonBrightnessScale = setSunIsPrimary
    local sunBrightnessScale = self.sunIsPrimary == 1
    moonBrightnessScale(sunBrightnessScale)
    local moonBrightnessScale = self.moonBrightnessScale
    local sunBrightnessScale = self.sunBrightnessScale
    if self.envMapRenderingMode then
        if self.sunIsPrimary == 1 then
        end
    end
    setSunBrightnessScale(sunBrightnessScale)
    local dr = self.primaryExtraterrestrialColor[1]
    local dg = self.primaryExtraterrestrialColor[2]
    local db = self.primaryExtraterrestrialColor[3]
    local dynamicLightingScale = self.primaryDynamicLightingScale
    setLightColor(self.sunLightId, dr * dynamicLightingScale, dg * dynamicLightingScale, db * dynamicLightingScale)
    setLightScatteringColor(self.sunLightId, dr, dg, db)
    setCloudGroundAlbedo(self.cloudGroundAlbedo[1], self.cloudGroundAlbedo[2], self.cloudGroundAlbedo[3])
end
function LightingStatic:updateExposureSettings()
    local minExposure, keyValue, maxExposure
    if Platform.usesFixedExposure then
        if self.fixedKeyValue == nil or self.fixedMinExposure == nil then
            keyValue = 0.18
            maxExposure = self.fixedExposure[1]
        else
            keyValue = self.fixedKeyValue
            minExposure = self.fixedMinExposure
            maxExposure = self.fixedMaxExposure
        end
    elseif self.fixedKeyValue == nil then
        keyValue = self.autoExposure[1]
        minExposure = self.autoExposure[2]
        maxExposure = self.autoExposure[3]
    elseif self.fixedMinExposure == nil then
        minExposure = self.autoExposure[2]
        maxExposure = self.autoExposure[3]
        keyValue = self.fixedKeyValue
    else
        keyValue = self.fixedKeyValue
        minExposure = self.fixedMinExposure
        maxExposure = self.fixedMaxExposure
    end
    setExposureRange(keyValue, minExposure, maxExposure)
end
function LightingStatic:updateCurves() end
function LightingStatic:setFixedExposureSettings(keyValue, minExposure, maxExposure)
    LightingStatic:superClass().setFixedExposureSettings(self, keyValue, minExposure, maxExposure)
    self:update(1, true)
end