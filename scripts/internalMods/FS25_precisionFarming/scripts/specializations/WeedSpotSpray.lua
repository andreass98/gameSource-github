WeedSpotSpray = {}
WeedSpotSpray.SPEC_NAME = g_currentModName .. ".weedSpotSpray"
WeedSpotSpray.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".weedSpotSpray"
WeedSpotSpray.NOZZLE_UPDATES_PER_FRAME = 10
function WeedSpotSpray.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Sprayer, specializations) and SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function WeedSpotSpray.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("weedSpotSpray", g_i18n:getText("configuration_weedSpotSpray"), "weedSpotSpray", VehicleConfigurationItem)
end
function WeedSpotSpray.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsSpotSprayEnabled", WeedSpotSpray.getIsSpotSprayEnabled)
    SpecializationUtil.registerFunction(vehicleType, "addWeedSpotSpraySensorNodes", WeedSpotSpray.addWeedSpotSpraySensorNodes)
end
function WeedSpotSpray.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerUsage", WeedSpotSpray.getSprayerUsage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addExtendedSprayerNozzleEffect", WeedSpotSpray.addExtendedSprayerNozzleEffect)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtendedSprayerNozzleEffectState", WeedSpotSpray.updateExtendedSprayerNozzleEffectState)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", WeedSpotSpray.loadWorkAreaFromXML)
end
function WeedSpotSpray.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", WeedSpotSpray)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", WeedSpotSpray)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", WeedSpotSpray)
end
function WeedSpotSpray:onPreLoad(_)
    self[WeedSpotSpray.SPEC_TABLE_NAME].isEnabled = (self.configurations.weedSpotSpray or 1) > 1
end
function WeedSpotSpray:onLoad(_)
    local spec = self[WeedSpotSpray.SPEC_TABLE_NAME]
    spec.lastRegularUsage = 0
    spec.weedDetectionStates = {}
    local replacementData = g_currentMission.weedSystem:getHerbicideReplacements()
    if replacementData.weed ~= nil then
        for sourceState, targetState in pairs(replacementData.weed.replacements) do
            if targetState ~= 0 then
                spec.weedDetectionStates[sourceState] = true
            end
        end
    end
    if spec.isEnabled and g_precisionFarming ~= nil then
        local linkData, _ = g_precisionFarming:getSprayerNodeData(self.configFileName, self.configurations)
        if linkData ~= nil then
            self:addWeedSpotSpraySensorNodes(linkData)
        end
    end
    linkData, _, spec.weedNumChannels = g_currentMission.weedSystem:getDensityMapData()
    spec.weedMapId = linkData
    spec.weedFirstChannel = _
    linkData, _, spec.groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
    spec.groundTypeMapId = linkData
    spec.groundTypeFirstChannel = _
    spec.sprayTypeMapId, _, spec.sprayTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
    spec.sprayTypeFirstChannel = _
end
function WeedSpotSpray:onEndWorkAreaProcessing(_)
    if self:getLastSpeed() > 0.5 then
        local specSprayer = self.spec_sprayer
        if self.isServer and (specSprayer.workAreaParameters.isActive and specSprayer.workAreaParameters.sprayFillType == FillType.HERBICIDE) then
            if specSprayer.workAreaParameters.sprayVehicle ~= nil or self:getIsAIActive() then
                self:updatePFStatistic("usedHerbicide", specSprayer.workAreaParameters.usage)
                self:updatePFStatistic("usedHerbicideRegular", self[WeedSpotSpray.SPEC_TABLE_NAME].lastRegularUsage)
            end
        end
    end
end
function WeedSpotSpray:getIsSpotSprayEnabled()
    return self[WeedSpotSpray.SPEC_TABLE_NAME].isEnabled
end
function WeedSpotSpray:addWeedSpotSpraySensorNodes(linkData)
    for _, sensorNodeData in pairs(linkData.sensorNodes) do
        local linkNode = nil
        if sensorNodeData.nodeName ~= nil and self.i3dMappings[sensorNodeData.nodeName] ~= nil then
            linkNode = self.i3dMappings[sensorNodeData.nodeName].nodeId
        end
        if linkNode ~= nil then
            local sensorNode, hasBracket = g_precisionFarming:getClonedSprayerWeedSensorNode(sensorNodeData.id)
            if sensorNode ~= nil then
                link(linkNode, sensorNode)
                setTranslation(sensorNode, sensorNodeData.translation[1], sensorNodeData.translation[2], sensorNodeData.translation[3])
                setRotation(sensorNode, sensorNodeData.rotation[1], sensorNodeData.rotation[2], sensorNodeData.rotation[3])
                if hasBracket and sensorNodeData.bracketSize ~= 1 then
                    setScale(getChildAt(sensorNode, 0), 1, sensorNodeData.bracketSize, sensorNodeData.bracketSize)
                end
            end
        end
    end
end
function WeedSpotSpray:getSprayerUsage(superFunc, fillType, dt)
    local usage = superFunc(self, fillType, dt)
    self[WeedSpotSpray.SPEC_TABLE_NAME].lastRegularUsage = usage
    if self.getNumExtendedSprayerNozzleEffectsActive ~= nil then
        local _, alpha = self:getNumExtendedSprayerNozzleEffectsActive()
    end
    return usage
end
function WeedSpotSpray:addExtendedSprayerNozzleEffect(superFunc, effectData, effectNode, linkNode, linkNodeData)
    return superFunc(self, effectData, effectNode, linkNode, linkNodeData) and true or false
end
function WeedSpotSpray:updateExtendedSprayerNozzleEffectState(superFunc, effectData, dt, isTurnedOn, lastSpeed)
    local isActive, amountScale = superFunc(self, effectData, dt, isTurnedOn, lastSpeed)
    local spec = self[WeedSpotSpray.SPEC_TABLE_NAME]
    if isActive and (spec.isEnabled and (self.movingDirection < 0 or (lastSpeed or 0) < 0.25)) then
        isActive = false
    end
    if isActive then
        local sprayFillType = self.spec_sprayer.workAreaParameters.sprayFillType
        if sprayFillType == FillType.HERBICIDE then
            if spec.isEnabled then
                local x, y, z = localToWorld(effectData.effectNode, 0, 0, 1)
                local densityBits = getDensityAtWorldPos(spec.weedMapId, x, y, z)
                local groundType = bit32.rshift(densityBits, spec.weedFirstChannel)
                local weedState = bit32.band(groundType, 2 ^ spec.weedNumChannels - 1)
                if not spec.weedDetectionStates[weedState] then
                    return false, amountScale
                end
            else
                local x, y, z = localToWorld(effectData.effectNode, 0, 0, 1)
                local densityBits = getDensityAtWorldPos(spec.groundTypeMapId, x, y, z)
                local groundType = bit32.rshift(densityBits, spec.groundTypeFirstChannel)
                local weedState = bit32.band(groundType, 2 ^ spec.groundTypeNumChannels - 1)
                if FieldGroundType.getTypeByValue(weedState) == FieldGroundType.NONE then
                    return false, amountScale
                end
            end
        elseif sprayFillType == FillType.LIQUIDFERTILIZER then
            local x, y, z = localToWorld(effectData.effectNode, 0, 0, 1.5)
            local densityBits = getDensityAtWorldPos(spec.groundTypeMapId, x, y, z)
            local sprayValue = spec.groundTypeFirstChannel
            local groundType = bit32.rshift(densityBits, sprayValue)
            local weedState = bit32.band(groundType, 2 ^ spec.groundTypeNumChannels - 1)
            if FieldGroundType.getTypeByValue(weedState) == FieldGroundType.NONE then
                isActive = false
            end
            if isActive then
                if spec.sprayTypeMapId ~= spec.groundTypeMapId then
                    densityBits = getDensityAtWorldPos(spec.sprayTypeMapId, x, y, z)
                end
                local sprayType = bit32.rshift(densityBits, spec.sprayTypeFirstChannel)
                local sprayValue = bit32.band(sprayType, 2 ^ spec.sprayTypeNumChannels - 1)
                if FieldSprayType.getTypeByValue(sprayValue) == FieldSprayType.FERTILIZER then
                    isActive = false
                end
            end
        end
    end
    return isActive, amountScale
end
function WeedSpotSpray:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    if not superFunc(self, workArea, xmlFile, key) then
        return false
    end
    if self[WeedSpotSpray.SPEC_TABLE_NAME].isEnabled then
        workArea.disableBackwards = true
    end
    return true
end