FertilizingCultivator = {}
FertilizingCultivator.CLIENT_DM_UPDATE_RADIUS = 50
function FertilizingCultivator.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Cultivator, specializations) and SpecializationUtil.hasSpecialization(Sprayer, specializations)
end
function FertilizingCultivator.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("FertilizingCultivator")
    schema:register(XMLValueType.BOOL, "vehicle.fertilizingCultivator#needsSetIsTurnedOn", "Needs to be turned on to spray", false)
    schema:setXMLSpecializationType()
end
function FertilizingCultivator.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "processCultivatorArea", FertilizingCultivator.processCultivatorArea)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", FertilizingCultivator.setSprayerAITerrainDetailProhibitedRange)
end
function FertilizingCultivator.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FertilizingCultivator)
end
function FertilizingCultivator:onLoad(_)
    self.spec_fertilizingCultivator.needsSetIsTurnedOn = self.xmlFile:getValue("vehicle.fertilizingCultivator#needsSetIsTurnedOn", false)
    self.spec_sprayer.useSpeedLimit = false
    self:clearAITerrainDetailRequiredRange()
    self:updateCultivatorAIRequirements()
end
function FertilizingCultivator:processCultivatorArea(_, workArea, _)
    local specCultivator = self.spec_cultivator
    local specSpray = self.spec_sprayer
    local sprayerParams = specSpray.workAreaParameters
    if (specSpray.isSlurryTanker and g_currentMission.missionInfo.helperSlurrySource == 1 or (specSpray.isManureSpreader and g_currentMission.missionInfo.helperManureSource == 1 or specSpray.isFertilizerSprayer and not g_currentMission.missionInfo.helperBuyFertilizer)) and self:getIsAIActive() then
        if sprayerParams.sprayFillType == nil or sprayerParams.sprayFillType == FillType.UNKNOWN then
            if sprayerParams.lastAIHasSprayed ~= nil then
                self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
                sprayerParams.lastAIHasSprayed = nil
            end
        else
            sprayerParams.lastAIHasSprayed = true
        end
    end
    local rootVehicle, _, zs = getWorldTranslation(workArea.start)
    local xw, _, zw = getWorldTranslation(workArea.width)
    local xh, _, zh = getWorldTranslation(workArea.height)
    FSDensityMapUtil.eraseTireTrack(rootVehicle, zs, xw, zw, xh, zh)
    if not self.isServer and self.currentUpdateDistance > FertilizingCultivator.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local sprayTypeIndex = SprayType.FERTILIZER
    if sprayerParams.sprayFillLevel <= 0 or self.spec_fertilizingCultivator.needsSetIsTurnedOn and not self:getIsTurnedOn() then
        sprayTypeIndex = nil
    end
    local cultivatorChangedArea = 0
    local cultivatorTotalArea = 0
    if specCultivator.isEnabled then
        if specCultivator.useDeepMode then
            local sprayAmount
            sprayAmount, cultivatorTotalArea = FSDensityMapUtil.updateCultivatorArea(rootVehicle, zs, xw, zw, xh, zh, not specCultivator.workAreaParameters.limitToField, specCultivator.workAreaParameters.limitFruitDestructionToField, specCultivator.workAreaParameters.angle, sprayTypeIndex)
            cultivatorChangedArea = sprayAmount + FSDensityMapUtil.updateVineCultivatorArea(rootVehicle, zs, xw, zw, xh, zh)
        else
            local sprayAmount
            sprayAmount, cultivatorTotalArea = FSDensityMapUtil.updateDiscHarrowArea(rootVehicle, zs, xw, zw, xh, zh, not cultivatorParams.limitToField, cultivatorParams.limitFruitDestructionToField, cultivatorParams.angle, sprayTypeIndex)
            cultivatorChangedArea = sprayAmount + FSDensityMapUtil.updateVineCultivatorArea(rootVehicle, zs, xw, zw, xh, zh)
        end
        cultivatorParams.lastChangedArea = cultivatorParams.lastChangedArea + cultivatorChangedArea
        cultivatorParams.lastTotalArea = cultivatorParams.lastTotalArea + cultivatorTotalArea
        cultivatorParams.lastStatsArea = cultivatorParams.lastStatsArea + cultivatorChangedArea
    end
    if specCultivator.isSubsoiler then
        FSDensityMapUtil.updateSubsoilerArea(rootVehicle, zs, xw, zw, xh, zh)
    end
    if sprayTypeIndex ~= nil then
        local sprayChangedArea, sprayTotalArea = FSDensityMapUtil.updateSprayArea(rootVehicle, zs, xw, zw, xh, zh, sprayTypeIndex, specSpray.doubledAmountIsActive and 2 or 1)
        sprayerParams.lastChangedArea = sprayerParams.lastChangedArea + sprayChangedArea
        sprayerParams.lastTotalArea = sprayerParams.lastTotalArea + sprayTotalArea
        sprayerParams.lastStatsArea = 0
        sprayerParams.isActive = true
    end
    local sprayAmount = self:getLastSpeed() > 0.5
    specCultivator.isWorking = sprayAmount
    return cultivatorChangedArea, cultivatorTotalArea
end
function FertilizingCultivator:setSprayerAITerrainDetailProhibitedRange(_, fillType)
    if self.addAITerrainDetailProhibitedRange ~= nil then
        self:clearAITerrainDetailProhibitedRange()
        local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
        if sprayTypeDesc ~= nil then
            local mission = g_currentMission
            local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
            local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
            local sprayLevelMaxValue = mission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
            self:addAIFruitProhibitions(0, sprayTypeDesc.sprayGroundType, sprayTypeDesc.sprayGroundType, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
            self:addAIFruitProhibitions(0, sprayLevelMaxValue, sprayLevelMaxValue, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
        end
    end
end