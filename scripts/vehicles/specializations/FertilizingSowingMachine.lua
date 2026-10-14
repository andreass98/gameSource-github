FertilizingSowingMachine = {}
FertilizingSowingMachine.CLIENT_DM_UPDATE_RADIUS = 50
function FertilizingSowingMachine.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations) and SpecializationUtil.hasSpecialization(Sprayer, specializations)
end
function FertilizingSowingMachine.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("FertilizingSowingMachine")
    schema:register(XMLValueType.BOOL, "vehicle.fertilizingSowingMachine#needsSetIsTurnedOn", "Needs to be turned on to spray", false)
    schema:setXMLSpecializationType()
end
function FertilizingSowingMachine.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSowingMachineArea", FertilizingSowingMachine.processSowingMachineArea)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseSprayerAIRequirements", FertilizingSowingMachine.getUseSprayerAIRequirements)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreEffectsVisible", FertilizingSowingMachine.getAreEffectsVisible)
end
function FertilizingSowingMachine.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FertilizingSowingMachine)
end
function FertilizingSowingMachine:onLoad(_)
    self.spec_fertilizingSowingMachine.needsSetIsTurnedOn = self.xmlFile:getValue("vehicle.fertilizingSowingMachine#needsSetIsTurnedOn", false)
    self.spec_sprayer.needsToBeFilledToTurnOn = false
    self.spec_sprayer.useSpeedLimit = false
    self.needWaterInfo = true
end
function FertilizingSowingMachine:processSowingMachineArea(_, workArea, dt)
    local specSowingMachine = self.spec_sowingMachine
    local specSpray = self.spec_sprayer
    local sprayerParams = specSpray.workAreaParameters
    local sowingParams = specSowingMachine.workAreaParameters
    local rootVehicle = self.spec_sowingMachine
    rootVehicle.isWorking = self:getLastSpeed() > 0.5
    if specSowingMachine.waterSeeding and not self.isInWater then
        specSowingMachine.showWaterPlantingRequiredWarning = true
        if self:getIsAIActive() then
            self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
        end
        return 0, 0
    end
    if not specSowingMachine.waterSeeding and self.isInWater then
        specSowingMachine.showWaterPlantingProhibitedWarning = true
        if self:getIsAIActive() then
            self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
        end
        return 0, 0
    end
    if not sowingParams.isActive then
        return 0, 0
    end
    if not (self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds) and sowingParams.seedsVehicle == nil then
        if self:getIsAIActive() then
            self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
        end
        return 0, 0
    end
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
    if not sowingParams.canFruitBePlanted then
        return 0, 0
    end
    local rootVehicle, _, startZ = getWorldTranslation(workArea.start)
    local widthX, _, widthZ = getWorldTranslation(workArea.width)
    local heightX, _, heightZ = getWorldTranslation(workArea.height)
    FSDensityMapUtil.eraseTireTrack(rootVehicle, startZ, widthX, widthZ, heightX, heightZ)
    if not self.isServer and self.currentUpdateDistance > FertilizingSowingMachine.CLIENT_DM_UPDATE_RADIUS then
        return 0, 0
    end
    local sprayTypeIndex = SprayType.FERTILIZER
    if sprayerParams.sprayFillLevel <= 0 or self.spec_fertilizingSowingMachine.needsSetIsTurnedOn and not self:getIsTurnedOn() then
        sprayTypeIndex = nil
    end
    local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(specSowingMachine.workAreaParameters.seedsFruitType)
    if fruitTypeDesc.seedRequiredFieldType ~= nil then
        if FSDensityMapUtil.getFieldTypeAtWorldPos((rootVehicle + widthX + heightX) / 3, (startZ + widthZ + heightZ) / 3) ~= fruitTypeDesc.seedRequiredFieldType then
            if fruitTypeDesc.seedRequiredFieldType == FieldType.RICE then
                specSowingMachine.showFieldTypeWarningRiceRequired = true
            else
                specSowingMachine.showFieldTypeWarningRegularRequired = true
            end
            if self:getIsAIActive() then
                self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
            end
        end
    end
    local cx, cz
    if specSowingMachine.useDirectPlanting then
        cx, cz = FSDensityMapUtil.updateDirectSowingArea(sowingParams.seedsFruitType, rootVehicle, startZ, widthX, widthZ, heightX, heightZ, sowingParams.fieldGroundType, sowingParams.ridgeSeeding, sowingParams.angle, nil, sprayTypeIndex)
    else
        cx, cz = FSDensityMapUtil.updateSowingArea(sowingParams.seedsFruitType, rootVehicle, startZ, widthX, widthZ, heightX, heightZ, sowingParams.fieldGroundType, sowingParams.ridgeSeeding, sowingParams.angle, nil, sprayTypeIndex)
    end
    self.spec_sowingMachine.isProcessing = self.spec_sowingMachine.isWorking
    if sprayTypeIndex ~= nil then
        local cz, rootVehicle = FSDensityMapUtil.updateSprayArea(rootVehicle, startZ, widthX, widthZ, heightX, heightZ, sprayTypeIndex, specSpray.doubledAmountIsActive and 2 or 1)
        sprayerParams.lastChangedArea = sprayerParams.lastChangedArea + cz
        sprayerParams.lastTotalArea = sprayerParams.lastTotalArea + rootVehicle
        sprayerParams.lastStatsArea = 0
        sprayerParams.isActive = true
        sprayerParams.lastSprayTime = g_time
        local farmId = self:getLastTouchedFarmlandFarmId()
        local ha = MathUtil.areaToHa(sprayerParams.lastChangedArea, g_currentMission:getFruitPixelsToSqm())
        g_farmManager:updateFarmStats(farmId, "sprayedHectares", ha)
        g_farmManager:updateFarmStats(farmId, "sprayedTime", dt / 60000)
        g_farmManager:updateFarmStats(farmId, "sprayUsage", sprayerParams.usage)
    end
    sowingParams.lastChangedArea = sowingParams.lastChangedArea + cx
    sowingParams.lastStatsArea = sowingParams.lastStatsArea + cx
    sowingParams.lastTotalArea = sowingParams.lastTotalArea + cz
    self:updateMissionSowingWarning(rootVehicle, startZ)
    return cx, cz
end
function FertilizingSowingMachine:getUseSprayerAIRequirements(superFunc)
    return false
end
function FertilizingSowingMachine:getAreEffectsVisible(superFunc)
    return superFunc(self) and self:getFillUnitFillType(self:getSprayerFillUnitIndex()) ~= FillType.UNKNOWN
end