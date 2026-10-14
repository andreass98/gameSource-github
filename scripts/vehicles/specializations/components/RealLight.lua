RealLight = {}
RealLight.SCATTERING_MAX_ANGLE = 60
RealLight.DEFAULT_LIGHT_PROFILE = {}
RealLight.DEFAULT_LIGHT_PROFILE.worklight = {
    ["iesProfile"] = "data/shared/ies/workLight.ies",
    ["intensityScale"] = 1.25
}
RealLight.DEFAULT_LIGHT_PROFILE.highbeam = {
    ["iesProfile"] = "data/shared/ies/highBeam.ies",
    ["intensityScale"] = 2
}
RealLight.DEFAULT_LIGHT_PROFILE.backlight = {
    ["iesProfile"] = "data/shared/ies/backLight.ies",
    ["intensityScale"] = 1
}
RealLight.DEFAULT_LIGHT_PROFILE.brakelight = {
    ["iesProfile"] = "data/shared/ies/backLight.ies",
    ["intensityScale"] = 1
}
RealLight.DEFAULT_LIGHT_PROFILE.frontlight = {
    ["iesProfile"] = "data/shared/ies/frontLight.ies",
    ["intensityScale"] = 1
}
RealLight.DEFAULT_LIGHT_PROFILE.turnlight = {
    ["iesProfile"] = "data/shared/ies/turnLight.ies",
    ["intensityScale"] = 1
}
RealLight.DEFAULT_LIGHT_PROFILE.reverselight = {
    ["iesProfile"] = "data/shared/ies/workLight.ies",
    ["intensityScale"] = 1.25
}
local RealLight_mt = Class(RealLight)
function RealLight.new(vehicle, customMt)
    -- upvalues: (copy) RealLight_mt
    local self = setmetatable({}, customMt or RealLight_mt)
    self.vehicle = vehicle
    self.chargeFunction = nil
    return self
end
function RealLight:loadFromXML(xmlFile, baseKey, components, i3dMappings, loadLightTypes)
    self.node = xmlFile:getValue(baseKey .. "#node", nil, components, i3dMappings)
    if self.node == nil then
        Logging.xmlWarning(xmlFile, "Missing light source node in \'%s\'", baseKey)
        return false
    end
    if not getHasClassId(self.node, ClassIds.LIGHT_SOURCE) then
        Logging.xmlWarning(xmlFile, "Defined node is not a light source \'%s\'", baseKey)
        return false
    end
    self.lightSources = { self.node }
    I3DUtil.iterateRecursively(self.node, function(childNode)
        -- upvalues: (copy) xmlFile, (copy) baseKey, (copy) self
        if not getVisibility(childNode) then
            Logging.xmlWarning(xmlFile, "Real light source \'%s\' is hidden in \'%s\'!", getName(childNode), baseKey)
        end
        if getHasClassId(childNode, ClassIds.LIGHT_SOURCE) then
            table.insert(self.lightSources, childNode)
        end
    end)
    self.defaultColor = self.defaultColor or { getLightColor(self.node) }
    self.intensityScale = xmlFile:getValue(baseKey .. "#intensityScale", 1)
    self.curIntensityScale = self.intensityScale
    setVisibility(self.node, false)
    if loadLightTypes ~= false then
        self.lightTypes = xmlFile:getValue(baseKey .. "#lightTypes", nil, true)
        self.excludedLightTypes = xmlFile:getValue(baseKey .. "#excludedLightTypes", nil, true)
    end
    if self.lightTypes == nil then
        self.lightTypes = {}
    end
    if self.excludedLightTypes == nil then
        self.excludedLightTypes = {}
    end
    local lightsProfile = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
    local xmlIESProfile = xmlFile:getValue(baseKey .. "#iesProfile")
    if xmlIESProfile == nil then
        local iesProfile = getLightIESProfile(self.lightSources[1])
        if iesProfile ~= "" then
            self.xmlIESProfile = iesProfile
        end
    else
        self.xmlIESProfile = Utils.getFilename(xmlIESProfile, self.vehicle.baseDirectory)
    end
    self.useLightScattering = xmlFile:getValue(baseKey .. "#useLightScattering")
    local y = true
    if lightsProfile ~= GS_PROFILE_VERY_HIGH then
        y = lightsProfile == GS_PROFILE_ULTRA
    end
    self:updateIESProfile(y)
    self:updateLightScattering()
    self.hasMergedShadows = false
    local y = baseKey .. "#hasShadows"
    local z = getLightRange(self.node) > 7.5
    self.hasShadows = xmlFile:getValue(y, z)
    if self.hasShadows and #self.lightSources > 1 then
        local iesProfile = xmlFile:getValue(baseKey .. "#shadowLightOffset", nil, true)
        local x = 0
        local y = 0
        local z = 0
        local tx = 0
        local ty = 0
        local tz = 0
        local maxLightRange = 0
        local maxConeAngle = 0
        for i, lightSource in ipairs(self.lightSources) do
            maxLightRange = math.max(maxLightRange, getLightRange(lightSource))
            maxConeAngle = math.max(maxConeAngle, getLightConeAngle(lightSource))
            local _x, _y, _z = localToLocal(lightSource, getParent(self.node), 0, 0, 0)
            local _tx, _ty, _tz = localToLocal(lightSource, getParent(self.node), 0, 0, -20)
        end
        local numLightSources = #self.lightSources
        if numLightSources > 1 then
        end
        self.shadowLightSource = createLightSource(getName(self.node) .. "_shadow", LightType.SPOT, 0.85, 0.85, 1, maxLightRange)
        local _x = RealLight.getMergedConeAngleSize
        local _y = self.lightSources
        setLightConeAngle(self.shadowLightSource, (math.max(maxConeAngle, _x(_y))))
        setLightShadowMap(self.shadowLightSource, true, 512)
        setVisibility(self.shadowLightSource, false)
        link(getParent(self.node), self.shadowLightSource)
        setTranslation(self.shadowLightSource, x, y, z)
        setLightSoftShadowSize(self.shadowLightSource, 0.008)
        setLightSoftShadowDistance(self.shadowLightSource, 15)
        setLightSoftShadowDepthBiasFactor(self.shadowLightSource, 0.02)
        local dx, dy, i = MathUtil.vector3Normalize(tx - x, ty - y, tz - z)
        setDirection(self.shadowLightSource, -dx, -dy, -i, 0, 1, 0)
        if iesProfile ~= nil then
            local lightSource, _x, _y = localToLocal(self.shadowLightSource, getParent(self.shadowLightSource), iesProfile[1], iesProfile[2], -iesProfile[3])
            setTranslation(self.shadowLightSource, lightSource, _x, _y)
        end
        for _z, _tx in ipairs(self.lightSources) do
            setLightShadowMap(_tx, true, 512)
        end
    end
    if xmlFile:getRootName() == "vehicle" then
        self.vehicle:loadAdditionalLightAttributesFromXML(xmlFile, baseKey, self)
    end
    return true
end
function RealLight:merge(otherLight)
    for i, lightType in ipairs(self.lightTypes) do
        table.addElement(otherLight.lightTypes, lightType)
    end
    for i, lightType in ipairs(self.excludedLightTypes) do
        table.addElement(otherLight.excludedLightTypes, lightType)
    end
    return otherLight
end
function RealLight:updateIESProfile(iesEnabled)
    for i, lightSource in ipairs(self.lightSources) do
        local nodeName = string.lower(getName(lightSource))
        for searchString, profile in pairs(RealLight.DEFAULT_LIGHT_PROFILE) do
            if string.contains(nodeName, searchString) then
                if iesEnabled then
                    if self.xmlIESProfile == nil then
                        if getLightIESProfile(lightSource) == "" then
                            setLightIESProfile(lightSource, profile.iesProfile)
                        end
                    else
                        setLightIESProfile(lightSource, self.xmlIESProfile)
                    end
                elseif getLightIESProfile(lightSource) ~= "" then
                    setLightIESProfile(lightSource, "")
                    self.curIntensityScale = self.intensityScale
                end
                self.curIntensityScale = self.intensityScale * profile.intensityScale
                break
            end
        end
    end
end
function RealLight:updateLightScattering()
    local lightsProfile = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
    local isDefaultLightOrHighBeam = false
    for i, lightType in ipairs(self.lightTypes) do
        if lightType == Lights.LIGHT_TYPE_DEFAULT or lightType == Lights.LIGHT_TYPE_HIGHBEAM then
            isDefaultLightOrHighBeam = true
            break
        end
    end
    for i, lightType in ipairs(self.lightSources) do
        local useLightScattering = false
        if self.useLightScattering == true then
            useLightScattering = GS_PROFILE_HIGH <= lightsProfile
        elseif self.useLightScattering == nil then
            if isDefaultLightOrHighBeam then
                useLightScattering = GS_PROFILE_HIGH <= lightsProfile
            elseif #self.lightTypes > 0 then
                useLightScattering = GS_PROFILE_VERY_HIGH <= lightsProfile
            end
            if useLightScattering then
                useLightScattering = getLightRange(lightType) > 7.5
            end
        end
        if useLightScattering then
            setLightUseLightScattering(lightType, true)
            if getLightConeAngle(lightType) > RealLight.SCATTERING_MAX_ANGLE then
                setLightScatteringConeAngle(lightType, RealLight.SCATTERING_MAX_ANGLE)
            end
            setLightScatteringIntensity(lightType, 1)
        elseif getLightUseLightScattering(lightType) then
            setLightUseLightScattering(lightType, false)
        end
    end
end
function RealLight:updateMergedShadows()
    if self.hasShadows then
        if g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE) == GS_PROFILE_ULTRA then
            if #self.lightSources > 1 then
                if not self.mergedShadowLightCreated then
                    mergeLightShadows(table.unpack(self.lightSources))
                    setMergedShadowSettingsLight(self.node, self.shadowLightSource)
                    for _, component in ipairs(self.vehicle.components) do
                        addMergedShadowIgnoreShapes(self.lightSources[1], component.node)
                    end
                    self.mergedShadowLightCreated = true
                end
                for _, component in ipairs(self.lightSources) do
                    setLightShadowMap(component, true, 512)
                    setLightShadowPriority(self.node, 1)
                end
                setMergedShadowActive(self.node, true)
            else
                setLightShadowMap(self.node, true, 512)
                setLightShadowPriority(self.node, 0.5)
                for _, component in ipairs(self.vehicle.components) do
                    addLightShadowIgnoreShapes(self.lightSources[1], component.node)
                end
            end
        elseif #self.lightSources > 1 then
            setMergedShadowActive(self.node, false)
            for _, component in ipairs(self.lightSources) do
                setLightShadowMap(component, false, 512)
            end
        else
            setLightShadowMap(self.node, false, 512)
        end
    else
        return
    end
end
function RealLight:finalize()
    self:updateMergedShadows()
end
function RealLight:onLightsProfileChanged(lightsProfile)
    self:updateIESProfile(lightsProfile == GS_PROFILE_VERY_HIGH or lightsProfile == GS_PROFILE_ULTRA)
    self:updateLightScattering()
    self:updateMergedShadows()
end
function RealLight:setLightTypesMask(lightsTypesMask)
    if not self.vehicle:getIsLightActive(self) then
        self:setState(false, 0)
        return
    end
    local isActive = false
    local chargeScale = 1
    if self.lightTypes == nil then
        isActive = false
    else
        for _, lightType in pairs(self.lightTypes) do
            if bit32.band(lightsTypesMask, 2 ^ lightType) ~= 0 or lightType == -1 and self.vehicle:getIsActiveForLights(true) then
                if isActive then
                    if self.vehicle.spec_lights.maxLightState < lightType then
                        chargeScale = 2
                    end
                else
                    isActive = true
                end
            end
        end
        if isActive and self.excludedLightTypes ~= nil then
            for _, lightType in pairs(self.excludedLightTypes) do
                if bit32.band(lightsTypesMask, 2 ^ lightType) ~= 0 then
                    isActive = false
                    break
                end
            end
        end
    end
    if self.chargeFunction ~= nil then
        chargeScale = self.chargeFunction(self.chargeFunctionTarget)
    end
    self:setState(isActive, chargeScale)
end
function RealLight:setIsBlinking(isBlinking) end
function RealLight:setState(isActive, chargeScale)
    if not chargeScale then
        chargeScale = isActive and 1 or 0
    end
    self:setCharge(chargeScale)
    setVisibility(self.node, isActive)
end
function RealLight:setCharge(alpha)
    alpha = alpha * self.curIntensityScale
    for _, lightSource in ipairs(self.lightSources) do
        setLightColor(lightSource, self.defaultColor[1] * alpha, self.defaultColor[2] * alpha, self.defaultColor[3] * alpha)
    end
end
function RealLight:setChargeFunction(func, funcTarget)
    self.chargeFunction = func
    self.chargeFunctionTarget = funcTarget
end
function RealLight.getAreShadowsMergable(lightSources)
    for _, lightSource1 in ipairs(lightSources) do
        for _, lightSource2 in ipairs(lightSources) do
            if lightSource1 ~= lightSource2 then
                local coneAngle = getLightConeAngle(lightSource2)
                local dx, dz = MathUtil.getDirectionFromYRotation(coneAngle * 0.5)
                local lx, ly, lz = localDirectionToLocal(lightSource2, lightSource1, dx, 0, -dz)
                local angle = lx ^ 2 + ly ^ 2
                local radius = math.sqrt(angle)
                local angle = math.acos(math.abs(lz) / math.sqrt(math.abs(lz) ^ 2 + radius ^ 2))
                if lz > 0 then
                end
                if angle + coneAngle * 0.5 > 3.141592653589793 then
                    return false
                end
                local dx, dz = MathUtil.getDirectionFromYRotation(-coneAngle * 0.5)
                local lx, ly, lz = localDirectionToLocal(lightSource2, lightSource1, dx, 0, -dz)
                local radius = math.sqrt(lx ^ 2 + ly ^ 2)
                local angle = math.acos(math.abs(lz) / math.sqrt(math.abs(lz) ^ 2 + radius ^ 2))
                if lz > 0 then
                end
                if angle + coneAngle * 0.5 > 3.141592653589793 then
                    return false
                end
            end
        end
    end
    return true
end
function RealLight.getMergedConeAngleSize(lightSources)
    local mergedConeAngle = 0
    for _, lightSource1 in ipairs(lightSources) do
        for _, lightSource2 in ipairs(lightSources) do
            if lightSource1 ~= lightSource2 then
                local coneAngle = getLightConeAngle(lightSource2)
                local dx, dz = MathUtil.getDirectionFromYRotation(coneAngle * 0.5)
                local lx, ly, lz = localDirectionToLocal(lightSource2, lightSource1, dx, 0, -dz)
                local angle = lx ^ 2 + ly ^ 2
                local radius = math.sqrt(angle)
                local angle = math.acos(math.abs(lz) / math.sqrt(math.abs(lz) ^ 2 + radius ^ 2))
                if lz > 0 then
                end
                local mergedConeAngle = math.max(mergedConeAngle, angle + coneAngle * 0.5)
                local dx, dz = MathUtil.getDirectionFromYRotation(-coneAngle * 0.5)
                local lx, ly, lz = localDirectionToLocal(lightSource2, lightSource1, dx, 0, -dz)
                local radius = math.sqrt(lx ^ 2 + ly ^ 2)
                local angle = math.acos(math.abs(lz) / math.sqrt(math.abs(lz) ^ 2 + radius ^ 2))
                if lz > 0 then
                end
                mergedConeAngle = math.max(mergedConeAngle, angle + coneAngle * 0.5)
            end
        end
    end
    return mergedConeAngle
end
function RealLight.loadLightsFromXML(lights, xmlFile, baseKey, vehicle, components, i3dMappings, loadLightTypes)
    lights = lights == nil and {} or lights
    for _, key in xmlFile:iterator(baseKey) do
        local light = RealLight.new(vehicle)
        if light:loadFromXML(xmlFile, key, components, i3dMappings, loadLightTypes) then
            local otherLight = vehicle:getRealLightFromNode(light.node)
            if otherLight ~= nil then
                light = light:merge(otherLight)
            end
            table.insert(lights, light)
        end
    end
    return lights
end
function RealLight.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Real light node")
    schema:register(XMLValueType.FLOAT, basePath .. "#intensityScale", "Additional scale of the light source intensity", 1)
    schema:register(XMLValueType.VECTOR_N, basePath .. "#excludedLightTypes", "Excluded light types")
    schema:register(XMLValueType.VECTOR_N, basePath .. "#lightTypes", "Light types")
    schema:register(XMLValueType.BOOL, basePath .. "#hasShadows", "Defines if the light has shadows or not (Only in ULTRA game setting)", "Automatically when range is greater 7.5m")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#shadowLightOffset", "Offset of the shadow light calculation from the center of all light sources (in lighting direction)")
    schema:register(XMLValueType.STRING, basePath .. "#iesProfile", "Path to IES profile file (Only used in very high and above)")
    schema:register(XMLValueType.BOOL, basePath .. "#useLightScattering", "Defines if light scattering is used", "automatically calculated based on lightType and range")
end
function RealLight.consoleCommandDebugIES(_, enabled)
    if RealLight.IES_DEBUG_ENABLED == nil then
        local performanceClass = Utils.getPerformanceClassId()
        RealLight.IES_DEBUG_ENABLED = performanceClass == GS_PROFILE_VERY_HIGH or performanceClass == GS_PROFILE_ULTRA
    end
    if enabled == nil then
        enabled = not RealLight.IES_DEBUG_ENABLED
    end
    RealLight.IES_DEBUG_ENABLED = enabled
    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local performanceClass = g_localPlayer:getCurrentVehicle()
        local i = 1
        for i = i, #performanceClass.childVehicles do
            local childVehicle = performanceClass.childVehicles[i]
            Logging.info("IES Profiles Enabled: \'%s\' on \'%s\'", enabled, performanceClass:getFullName())
            if childVehicle.spec_lights ~= nil then
                for _, profile in pairs(childVehicle.spec_lights.realLights) do
                    for _, lights in pairs(profile) do
                        for _, realLight in ipairs(lights) do
                            realLight:updateIESProfile(enabled)
                        end
                    end
                end
            end
        end
    end
end
addConsoleCommand("gsVehicleDebugLightIESProfiles", "Enables and disables IES profiles on the light source (only the automatically assigned profiles)", "RealLight.consoleCommandDebugIES", nil)