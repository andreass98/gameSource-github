VineCutter = {}
function VineCutter.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("vineCutter", g_i18n:getText("shop_configuration"), "vineCutter", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("VineCutter")
    schema:register(XMLValueType.STRING, "vehicle.vineCutter#fruitType", "Fruit type")
    schema:register(XMLValueType.STRING, "vehicle.vineCutter.vineCutterConfigurations.vineCutterConfiguration(?)#fruitType", "Fruit type")
    schema:setXMLSpecializationType()
end
function VineCutter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(VineDetector, specializations)
end
function VineCutter.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getCombine", VineCutter.getCombine)
    SpecializationUtil.registerFunction(vehicleType, "harvestCallback", VineCutter.harvestCallback)
end
function VineCutter.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", VineCutter.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartVineDetection", VineCutter.getCanStartVineDetection)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsValidVinePlaceable", VineCutter.getIsValidVinePlaceable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleVinePlaceable", VineCutter.handleVinePlaceable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "clearCurrentVinePlaceable", VineCutter.clearCurrentVinePlaceable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementUseVineSegment", VineCutter.getAIImplementUseVineSegment)
end
function VineCutter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", VineCutter)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", VineCutter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", VineCutter)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", VineCutter)
end
function VineCutter:onLoad(_)
    local spec = self.spec_vineCutter
    local configKey = string.format("vehicle.vineCutter.vineCutterConfigurations.vineCutterConfiguration(%d)", (self.configurations.vineCutter or 1) - 1)
    local fruitTypeName = self.xmlFile:getValue(configKey .. "#fruitType")
    if fruitTypeName == nil then
        fruitTypeName = self.xmlFile:getValue("vehicle.vineCutter#fruitType")
    end
    local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
    if fruitType == nil then
        spec.inputFruitTypeIndex = FruitType.GRAPE
    else
        spec.inputFruitTypeIndex = fruitType.index
    end
    spec.outputFillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.inputFruitTypeIndex)
    spec.showFarmlandNotOwnedWarning = false
    spec.warningYouDontHaveAccessToThisLand = g_i18n:getText("warning_youDontHaveAccessToThisLand")
end
function VineCutter:onPostLoad(_)
    if self.addCutterToCombine ~= nil then
        self:addCutterToCombine(self)
    end
end
function VineCutter:onDraw(_, _, _)
    local spec = self.spec_vineCutter
    if spec.showFarmlandNotOwnedWarning then
        g_currentMission:showBlinkingWarning(spec.warningYouDontHaveAccessToThisLand)
    end
end
function VineCutter:onTurnedOff()
    self:cancelVineDetection()
    local spec = self.spec_vineCutter
    if spec.lastHarvestingPlaceable ~= nil and spec.lastHarvestingNode ~= nil then
        spec.lastHarvestingPlaceable:setShakingFactor(spec.lastHarvestingNode, 0, 0, 0, 0)
    end
    spec.showFarmlandNotOwnedWarning = false
end
function VineCutter:getCanStartVineDetection(superFunc)
    if superFunc(self) then
        if self:getIsTurnedOn() then
            return self.movingDirection >= 0
        else
            return false
        end
    else
        return false
    end
end
function VineCutter:getIsValidVinePlaceable(superFunc, placeable)
    if not superFunc(self, placeable) then
        return false
    end
    return placeable:getVineFruitType() == self.spec_vineCutter.inputFruitTypeIndex
end
function VineCutter:handleVinePlaceable(superFunc, node, placeable, x, y, z, distance)
    local spec = self.spec_vineCutter
    spec.showFarmlandNotOwnedWarning = false
    if not superFunc(self, node, placeable, x, y, z, distance) then
        return false
    end
    local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
    if farmlandId == nil then
        spec.showFarmlandNotOwnedWarning = true
        return false
    end
    if farmlandId == FarmlandManager.NOT_BUYABLE_FARM_ID then
        spec.showFarmlandNotOwnedWarning = true
        return false
    end
    local landOwner = g_farmlandManager:getFarmlandOwner(farmlandId)
    local farmId = self:getOwnerFarmId()
    local accessible = false
    if landOwner ~= 0 then
        accessible = g_currentMission.accessHandler:canFarmAccessOtherId(farmId, landOwner)
    end
    if not accessible then
        spec.showFarmlandNotOwnedWarning = true
        return false
    end
    local alternativeCombine, alternativeCombine, requiredFillType = self:getCombine()
    if alternativeCombine == nil then
        local _ = requiredFillType == nil
    end
    if alternativeCombine == nil then
        if spec.lastHarvestingNode ~= nil then
            spec.lastHarvestingPlaceable:setShakingFactor(spec.lastHarvestingNode, 0, 0, 0, 0)
        end
        return false
    end
    if placeable == nil then
        return false
    end
    local startPosX, startPosY, startPosZ = self:getFirstVineHitPosition()
    local currentPosX, currentPosY, currentPosZ = self:getCurrentVineHitPosition()
    spec.currentCombineVehicle = alternativeCombine
    spec.lastTouchedFarmlandFarmId = landOwner
    placeable:harvestVine(node, startPosX, startPosY, startPosZ, currentPosX, currentPosY, currentPosZ, self.harvestCallback, self)
    placeable:setShakingFactor(node, currentPosX, currentPosY, currentPosZ, 1)
    if spec.lastHarvestingNode ~= nil and spec.lastHarvestingNode ~= node then
        spec.lastHarvestingPlaceable:setShakingFactor(spec.lastHarvestingNode, currentPosX, currentPosY, currentPosZ, 0)
    end
    spec.lastHarvestingNode = node
    spec.lastHarvestingPlaceable = placeable
    return true
end
function VineCutter:clearCurrentVinePlaceable(superFunc)
    superFunc(self)
    local spec = self.spec_vineCutter
    if spec.lastHarvestingPlaceable ~= nil and spec.lastHarvestingNode ~= nil then
        spec.lastHarvestingPlaceable:setShakingFactor(spec.lastHarvestingNode, 0, 0, 0, 0)
    end
    spec.lastHarvestingPlaceable = nil
    spec.lastHarvestingNode = nil
    spec.showFarmlandNotOwnedWarning = false
end
function VineCutter:getAIImplementUseVineSegment(_, placeable, segment, segmentSide)
    if segmentSide >= 0 then
        return placeable:getHasSegmentTargetGrowthState(segment, self.spec_vineCutter.inputFruitTypeIndex, true, false)
    else
        return false
    end
end
function VineCutter:harvestCallback(_, area, _, weedFactor, sprayFactor, plowFactor, sectionLength)
    local spec = self.spec_vineCutter
    local realArea = area * g_currentMission:getHarvestScaleMultiplier(spec.inputFruitTypeIndex, sprayFactor, plowFactor, 1, weedFactor, 1, 1, 0)
    local liters = g_fruitTypeManager:getFruitTypeAreaLiters(spec.inputFruitTypeIndex, realArea, false)
    spec.currentCombineVehicle:addCutterArea(area, liters, spec.inputFruitTypeIndex, spec.outputFillTypeIndex, 0, spec.lastTouchedFarmlandFarmId, 1)
    if spec.inputFruitTypeIndex == FruitType.GRAPE then
        g_farmManager:updateFarmStats(spec.lastTouchedFarmlandFarmId, "harvestedGrapes", sectionLength)
        return
    elseif spec.inputFruitTypeIndex == FruitType.OLIVE then
        g_farmManager:updateFarmStats(spec.lastTouchedFarmlandFarmId, "harvestedOlives", sectionLength)
    else
        local ha = MathUtil.areaToHa(area, g_currentMission:getFruitPixelsToSqm())
        g_farmManager:updateFarmStats(spec.lastTouchedFarmlandFarmId, "threshedHectares", ha)
        g_farmManager:updateFarmStats(spec.lastTouchedFarmlandFarmId, "workedHectares", ha)
    end
end
function VineCutter:doCheckSpeedLimit(superFunc)
    return superFunc(self) or self:getIsTurnedOn()
end
function VineCutter:getCombine()
    if self.verifyCombine ~= nil then
        return self:verifyCombine(self.spec_vineCutter.inputFruitTypeIndex, self.spec_vineCutter.outputFillTypeIndex)
    end
    if self.getAttacherVehicle ~= nil then
        local attacherVehicle = self:getAttacherVehicle()
        if attacherVehicle ~= nil and attacherVehicle.verifyCombine ~= nil then
            return attacherVehicle:verifyCombine(spec.inputFruitTypeIndex, spec.outputFillTypeIndex)
        end
    end
    return nil
end
function VineCutter.getDefaultSpeedLimit()
    return 5
end