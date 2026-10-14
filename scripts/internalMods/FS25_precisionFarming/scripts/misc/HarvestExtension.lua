HarvestExtension = {}
HarvestExtension.YIELD_DEBUG = false
HarvestExtension.MOD_NAME = g_currentModName
local HarvestExtension_mt = Class(HarvestExtension)
function HarvestExtension.new(pfModule, customMt)
    -- upvalues: (copy) HarvestExtension_mt
    local self = setmetatable({}, customMt or HarvestExtension_mt)
    self.pfModule = pfModule
    self.debugValues = {
        ["nActualValue"] = 0,
        ["nTargetValue"] = 0,
        ["nFactor"] = 0,
        ["regularNFactor"] = 0,
        ["nRegularValue"] = 0,
        ["yieldPotential"] = 0,
        ["ignoreOverfertilization"] = false,
        ["pHActualValue"] = 0,
        ["pHTargetValue"] = 0,
        ["pHRegularValue"] = 0,
        ["pHFactor"] = 0,
        ["regularPHFactor"] = 0,
        ["plowFactor"] = 0,
        ["weedFactor"] = 0,
        ["stubbleFactor"] = 0,
        ["rollerFactor"] = 0,
        ["yieldFactor"] = 0,
        ["yieldFactorRegular"] = 0,
        ["seedRateYieldFactor"] = 0,
        ["lastSeedRateFound"] = 0,
        ["lastSeedRateTarget"] = 0
    }
    self.densityMapParallelogram = DensityMapParallelogram.new()
    g_messageCenter:subscribe(MessageType.UNLOADING_STATIONS_CHANGED, self.onUnloadingStationsChanged, self)
    if g_server ~= nil then
        addConsoleCommand("pfShowYieldDebug", "Displayes precision farming yield debug", "toggleYieldDebug", self)
    end
    return self
end
function HarvestExtension:delete()
    g_messageCenter:unsubscribeAll(self)
    if g_server ~= nil then
        removeConsoleCommand("pfShowYieldDebug")
    end
end
function HarvestExtension:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
    return true
end
function HarvestExtension:toggleYieldDebug()
    HarvestExtension.YIELD_DEBUG = not HarvestExtension.YIELD_DEBUG
end
function HarvestExtension:update(dt) end
function HarvestExtension:draw()
    if HarvestExtension.YIELD_DEBUG then
        local debugValues = self.debugValues
        local nitrogenMap = self.pfModule.nitrogenMap
        local pHMap = self.pfModule.pHMap
        local seedRateMap = self.pfModule.seedRateMap
        renderText(0.01, 0.42, 0.015, string.format("Nitrogen: Actual: %d | Target: %d | Regular: %d => Factor: %d%% | Regular Factor: %d%%", nitrogenMap:getNitrogenValueFromInternalValue(debugValues.nActualValue), nitrogenMap:getNitrogenValueFromInternalValue(debugValues.nTargetValue), nitrogenMap:getNitrogenValueFromInternalValue(debugValues.nRegularValue), debugValues.nFactor * 100, debugValues.regularNFactor * 100))
        renderText(0.01, 0.4, 0.015, string.format("Nitrogen: Yield Potential: %d%% | ignoreOverfertilization: %s", debugValues.yieldPotential * 100, debugValues.ignoreOverfertilization))
        renderText(0.01, 0.38, 0.015, string.format("Seed Rate: Yield: %d%% | Optimal Rate: %s | Found Rate: %s", debugValues.seedRateYieldFactor * 100, seedRateMap:getRateLabelByIndex(debugValues.lastSeedRateTarget), seedRateMap:getRateLabelByIndex(debugValues.lastSeedRateFound)))
        renderText(0.01, 0.36, 0.015, string.format("pH: Actual: %.3f | Target: %.3f | Regular: %.3f => Factor: %d%% | Regular Factor: %d%%", pHMap:getPhValueFromInternalValue(debugValues.pHActualValue), pHMap:getPhValueFromInternalValue(debugValues.pHTargetValue), pHMap:getPhValueFromInternalValue(debugValues.pHRegularValue), debugValues.pHFactor * 100, debugValues.regularPHFactor * 100))
        renderText(0.01, 0.34, 0.015, string.format("Plow Factor: %d%% | Weed Factor: %d%% | Stubble Factor: %d%% | Roller Factor: %d%%", debugValues.plowFactor * 100, debugValues.weedFactor * 100, debugValues.stubbleFactor * 100, debugValues.rollerFactor * 100))
        renderText(0.01, 0.32, 0.015, string.format("Yield: %d%% | Regular Yield: %d%%", debugValues.yieldFactor / 2 * 100, debugValues.yieldFactorRegular / 2 * 100))
        nitrogenMap:drawYieldDebug(debugValues.nActualValue, debugValues.nTargetValue)
        pHMap:drawYieldDebug(debugValues.pHActualValue, debugValues.pHTargetValue)
    end
end
function HarvestExtension:onUnloadingStationsChanged()
    self.unloadingStations = g_currentMission.storageSystem:getUnloadingStations()
end
function HarvestExtension.getYieldFromArea(_, combine, cutter, inputFruitType, realArea)
    local pixelToSqm = g_currentMission:getFruitPixelsToSqm()
    local literPerSqm = 1
    if inputFruitType ~= FruitType.UNKNOWN then
        literPerSqm = g_fruitTypeManager:getFruitTypeByIndex(inputFruitType).literPerSqm
    end
    local yield = realArea * pixelToSqm * literPerSqm * combine.spec_combine.threshingScale
    if cutter:getLastTouchedFarmlandFarmId() ~= AccessHandler.EVERYONE then
        local damage = combine:getVehicleDamage()
        if damage > 0 then
        end
    end
    return yield
end
function HarvestExtension:getBestPriceForFillType(fillType)
    if self.unloadingStations == nil then
        self.unloadingStations = g_currentMission.storageSystem:getUnloadingStations()
    end
    local maxPrice = 0
    for _, unloadingStation in pairs(self.unloadingStations) do
        if unloadingStation.getEffectiveFillTypePrice ~= nil and (unloadingStation:getIsFillTypeAllowed(fillType.index) and (unloadingStation.getAppearsOnStats == nil or unloadingStation:getAppearsOnStats())) then
            maxPrice = math.max(maxPrice, unloadingStation:getEffectiveFillTypePrice(fillType.index, ToolType.UNDEFINED))
        end
    end
    return maxPrice == 0 and (fillType.pricePerLiter or 0) or maxPrice
end
function HarvestExtension:updateLatestFactors(pfModule, vehicle, requiresPHFactorUpdate, requiresNFactorUpdate)
    local nFactor = vehicle.lastNFactor or 0
    local regularNFactor = vehicle.lastRegularNFactor or 0
    local yieldPotential
    if requiresNFactorUpdate then
        local nActualValue, nTargetValue, nRegularValue, lastIgnoreOverfertilization
        nActualValue, nTargetValue, yieldPotential, nRegularValue, lastIgnoreOverfertilization = pfModule.nitrogenMap:updateLastNitrogenValues()
        if nActualValue > -1 and nTargetValue > -1 then
            nFactor = pfModule.nitrogenMap:getYieldFactorByLevelDifference(nActualValue - nTargetValue, lastIgnoreOverfertilization)
            vehicle.lastNFactor = nFactor
            vehicle.lastYieldPotential = yieldPotential
            regularNFactor = pfModule.nitrogenMap:getYieldFactorByLevelDifference(nRegularValue - nTargetValue, lastIgnoreOverfertilization)
            vehicle.lastRegularNFactor = regularNFactor
            vehicle.lastNActualValue = nActualValue
            vehicle.lastNTargetValue = nTargetValue
            vehicle.lastIgnoreOverfertilization = lastIgnoreOverfertilization
            if HarvestExtension.YIELD_DEBUG then
                local debugValues = self.debugValues
                debugValues.nActualValue = nActualValue
                debugValues.nTargetValue = nTargetValue
                debugValues.yieldPotential = yieldPotential
                debugValues.nRegularValue = nRegularValue
                debugValues.ignoreOverfertilization = lastIgnoreOverfertilization
                debugValues.nFactor = nFactor
                debugValues.regularNFactor = regularNFactor
            end
        else
            yieldPotential = vehicle.lastYieldPotential or 1
        end
    else
        yieldPotential = currentYieldPotential
    end
    local nActualValue = vehicle.lastPHFactor or 0
    local nTargetValue = vehicle.lastRegularPHFactor or 0
    if requiresPHFactorUpdate then
        local yieldPotential, nRegularValue, lastIgnoreOverfertilization = pfModule.pHMap:updateLastPhValues()
        if yieldPotential > -1 and (nRegularValue > -1 and lastIgnoreOverfertilization > -1) then
            nActualValue = pfModule.pHMap:getYieldFactorByLevelDifference(yieldPotential - nRegularValue)
            vehicle.lastPHFactor = nActualValue
            nTargetValue = pfModule.pHMap:getYieldFactorByLevelDifference(lastIgnoreOverfertilization - nRegularValue)
            vehicle.lastRegularPHFactor = nTargetValue
            vehicle.lastPHActualValue = yieldPotential
            vehicle.lastPHTargetValue = nRegularValue
            if HarvestExtension.YIELD_DEBUG then
                local debugValues = self.debugValues
                debugValues.pHFactor = nActualValue
                debugValues.regularPHFactor = nTargetValue
                debugValues.pHActualValue = yieldPotential
                debugValues.pHTargetValue = nRegularValue
                debugValues.pHRegularValue = lastIgnoreOverfertilization
            end
        end
    end
    local yieldPotential, nRegularValue, lastIgnoreOverfertilization = pfModule.seedRateMap:updateLastYieldValues()
    local debugValues = yieldPotential or (vehicle.lastSeedRateMultiplier or 1)
    if debugValues ~= nil then
        vehicle.lastSeedRateMultiplier = debugValues
        if HarvestExtension.YIELD_DEBUG then
            local debugValues = self.debugValues
            debugValues.seedRateYieldFactor = debugValues
            debugValues.lastSeedRateFound = nRegularValue or debugValues.lastSeedRateFound
            debugValues.lastSeedRateTarget = lastIgnoreOverfertilization or debugValues.lastSeedRateTarget
        end
    end
    return nFactor, math.min(regularNFactor, nFactor), yieldPotential, nActualValue, math.min(nTargetValue, nActualValue)
end
function HarvestExtension:getLastMultipliers(yieldPotential, regularNFactor, nFactor, regularPHFactor, pHFactor)
    if self.lastPlowFactor == nil then
        return 1, 1
    else
        return (1 + self.lastPlowFactor * 0.1 + self.lastWeedFactor * 0.15 + self.lastStubbleFactor * 0.025 + self.lastRollerFactor * 0.025 + regularNFactor * 0.5 + regularPHFactor * 0.2) * yieldPotential, (1 + self.lastPlowFactor * 0.1 + self.lastWeedFactor * 0.15 + self.lastStubbleFactor * 0.025 + self.lastRollerFactor * 0.025 + nFactor * 0.5 + pHFactor * 0.2) * yieldPotential
    end
end
function HarvestExtension:updateWeedFactor(vehicle)
    if self.lastWeedFactor ~= nil then
        if vehicle.smoothedWeedFactor == nil then
            vehicle.smoothedWeedFactor = 0
        end
        vehicle.smoothedWeedFactor = vehicle.smoothedWeedFactor * 0.95 + self.lastWeedFactor * 0.05
        self.lastWeedFactor = vehicle.smoothedWeedFactor
    end
end
function HarvestExtension:preProcessMowerArea(vehicle, workArea, _)
    local specMower = vehicle.spec_mower
    local pfModule = g_precisionFarming
    local nFactor, regularNFactor, currentYieldPotential = getWorldTranslation(workArea.start)
    local nFactor, regularNFactor, currentYieldPotential = getWorldTranslation(workArea.width)
    local nFactor, regularNFactor, currentYieldPotential = getWorldTranslation(workArea.height)
    if specMower.pfFruitTypeConverters == nil then
        specMower.pfFruitTypeConverters = {}
        for fruitTypeIndex, _ in pairs(specMower.fruitTypeConverters) do
            table.insert(specMower.pfFruitTypeConverters, fruitTypeIndex)
        end
    end
    self.densityMapParallelogram:updateFromWorldPositions(nFactor, currentYieldPotential, nFactor, currentYieldPotential, nFactor, currentYieldPotential)
    pfModule.coverMap:preUpdateCoverArea(specMower.pfFruitTypeConverters, self.densityMapParallelogram, pfModule:getIsMaizePlusActive(), false)
    local nFactor, regularNFactor, currentYieldPotential, fruitTypeIndex, _ = self:updateLatestFactors(pfModule, vehicle, false, false)
    self.replaceNFactor = nFactor
    self.replaceRegularNFactor = regularNFactor
    self.replacePHFactor = fruitTypeIndex
    self.replaceRegularPHFactor = _
    self.replaceYieldPotential = currentYieldPotential
    self.checkMultiplier = true
    self.replaceMultiplier = true
end
function HarvestExtension:postProcessMowerArea(vehicle, workArea, _, lastRealArea)
    local specMower = vehicle.spec_mower
    self.checkMultiplier = false
    self.replaceMultiplier = false
    self:updateWeedFactor(vehicle)
    local pfModule = g_precisionFarming
    local farmlandId, mission, fillTypeIndex = getWorldTranslation(workArea.start)
    local farmlandId, mission, fillTypeIndex = getWorldTranslation(workArea.width)
    local farmlandId, mission, fillTypeIndex = getWorldTranslation(workArea.height)
    local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition((farmlandId + farmlandId) * 0.5, (fillTypeIndex + fillTypeIndex) * 0.5)
    local mission = g_missionManager:getMissionAtWorldPosition(farmlandId, fillTypeIndex) or (g_missionManager:getMissionAtWorldPosition(farmlandId, fillTypeIndex) or g_missionManager:getMissionAtWorldPosition(farmlandId, fillTypeIndex))
    local fillTypeIndex = nil
    local dropArea = vehicle:getDropArea(workArea)
    if dropArea == nil then
        if specMower.fillUnitIndex ~= nil then
            fillTypeIndex = vehicle:getFillUnitFillType(specMower.fillUnitIndex)
        end
    else
        fillTypeIndex = dropArea.fillType
    end
    self.densityMapParallelogram:updateFromWorldPositions(farmlandId, fillTypeIndex, farmlandId, fillTypeIndex, farmlandId, fillTypeIndex)
    local phMapUpdated, nMapUpdated = pfModule.coverMap:postUpdateCoverArea(specMower.pfFruitTypeConverters, self.densityMapParallelogram, pfModule:getIsMaizePlusActive(), false)
    self:updateLatestFactors(pfModule, vehicle, phMapUpdated, nMapUpdated)
    self:setLastScoringValues(lastRealArea, farmlandId, vehicle.lastNActualValue, vehicle.lastNTargetValue, vehicle.lastPHActualValue, vehicle.lastPHTargetValue, vehicle.lastIgnoreOverfertilization, fillTypeIndex)
    local regularMultiplier, newMultiplier = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
    if lastRealArea > 0 and mission == nil then
        if fillTypeIndex ~= nil and fillTypeIndex ~= FillType.UNKNOWN then
            if pfModule.yieldMap ~= nil then
                pfModule.yieldMap:setAreaYield(farmlandId, fillTypeIndex, farmlandId, fillTypeIndex, farmlandId, fillTypeIndex, newMultiplier)
            end
            if HarvestExtension.YIELD_DEBUG then
                local debugValues = self.debugValues
                debugValues.yieldFactor = newMultiplier
                debugValues.yieldFactorRegular = regularMultiplier
            end
            local debugValues = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
            if vehicle.updatePFStatistic ~= nil then
                vehicle:updatePFStatistic("yield", workArea.pickedUpLiters)
                vehicle:updatePFStatistic("yieldWeight", workArea.pickedUpLiters * (debugValues.massPerLiter / FillTypeManager.MASS_SCALE))
                vehicle:updatePFStatistic("yieldRegular", workArea.pickedUpLiters / newMultiplier * regularMultiplier)
                vehicle:updatePFStatistic("yieldBestPrice", self:getBestPriceForFillType(debugValues) * workArea.pickedUpLiters)
            end
        end
    end
    self.lastMultiplier = nil
    self.lastPlowFactor = nil
    self.lastWeedFactor = nil
    self.lastStubbleFactor = nil
    self.lastRollerFactor = nil
end
function HarvestExtension:setLastScoringValues(area, farmlandId, nActual, nTarget, pHActual, pHTarget, ignoreOverfertilization, fillTypeIndex) end
function HarvestExtension:overwriteGameFunctions(pfModule)
    local fruitTypes = {}
    local tempTarget = {}
    pfModule:overwriteGameFunction(FSDensityMapUtil, "updateVineCutArea", function(superFunc, fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        -- upvalues: (copy) self, (copy) fruitTypes, (copy) tempTarget, (copy) pfModule
        self.densityMapParallelogram:updateFromWorldPositions(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        fruitTypes[1] = fruitId
        if tempTarget[fruitId] == nil then
            tempTarget[fruitId] = {}
        end
        pfModule.coverMap:preUpdateCoverArea(fruitTypes, self.densityMapParallelogram, false, false)
        local nFactor, regularNFactor, currentYieldPotential, pHFactor, regularPHFactor = self:updateLatestFactors(pfModule, tempTarget[fruitId], false, false)
        self.replaceNFactor = nFactor
        self.replaceRegularNFactor = regularNFactor
        self.replacePHFactor = pHFactor
        self.replaceRegularPHFactor = regularPHFactor
        self.replaceYieldPotential = currentYieldPotential
        self.checkMultiplier = true
        self.replaceMultiplier = true
        if self.replaceVineMultiplierArea == nil then
            self.replaceVineMultiplierArea = {
                0,
                0,
                0,
                0,
                0,
                0
            }
        end
        self.replaceVineMultiplierArea[1] = startWorldX
        self.replaceVineMultiplierArea[2] = startWorldZ
        self.replaceVineMultiplierArea[3] = widthWorldX
        self.replaceVineMultiplierArea[4] = widthWorldZ
        self.replaceVineMultiplierArea[5] = heightWorldX
        self.replaceVineMultiplierArea[6] = heightWorldZ
        return superFunc(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    end)
    pfModule:overwriteGameFunction(VineCutter, "harvestCallback", function(superFunc, vehicle, placeable, area, totalArea, weedFactor, sprayFactor, plowFactor, sectionLength)
        -- upvalues: (copy) self, (copy) tempTarget, (copy) pfModule, (copy) fruitTypes
        superFunc(vehicle, placeable, area, totalArea, weedFactor, sprayFactor, plowFactor, sectionLength)
        self.checkMultiplier = false
        self.replaceMultiplier = false
        if self.replaceVineMultiplierArea ~= nil then
            local spec = vehicle.spec_vineCutter
            local startWorldX = self.replaceVineMultiplierArea[1]
            local startWorldZ = self.replaceVineMultiplierArea[2]
            local widthWorldX = self.replaceVineMultiplierArea[3]
            local widthWorldZ = self.replaceVineMultiplierArea[4]
            local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition((startWorldX + widthWorldX) * 0.5, (startWorldZ + widthWorldZ) * 0.5)
            local fillType = g_fillTypeManager:getFillTypeByIndex(spec.inputFruitTypeIndex)
            if fillType ~= nil then
                if tempTarget[spec.inputFruitTypeIndex] == nil then
                    tempTarget[spec.inputFruitTypeIndex] = {}
                end
                self.densityMapParallelogram:updateFromWorldPositions(startWorldX, startWorldZ, widthWorldX, widthWorldZ, self.replaceVineMultiplierArea[5], self.replaceVineMultiplierArea[6])
                local phMapUpdated, nMapUpdated = pfModule.coverMap:postUpdateCoverArea(fruitTypes, self.densityMapParallelogram, false, false)
                local target = tempTarget[spec.inputFruitTypeIndex]
                self:updateLatestFactors(pfModule, target, phMapUpdated, nMapUpdated)
                self:setLastScoringValues(area, farmlandId, target.lastNActualValue, target.lastNTargetValue, target.lastPHActualValue, target.lastPHTargetValue, target.lastIgnoreOverfertilization, fillType.index)
                local regularMultiplier, newMultiplier = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
                if pfModule.yieldMap ~= nil then
                    pfModule.yieldMap:setAreaYield(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, newMultiplier)
                end
                if HarvestExtension.YIELD_DEBUG then
                    local debugValues = self.debugValues
                    debugValues.yieldFactor = newMultiplier
                    debugValues.yieldFactorRegular = regularMultiplier
                end
                local debugValues = g_fruitTypeManager:getFruitTypeAreaLiters(spec.inputFruitTypeIndex, area * newMultiplier, false)
                local regularLiters = g_fruitTypeManager:getFruitTypeAreaLiters(spec.inputFruitTypeIndex, area * regularMultiplier, false)
                if vehicle.updatePFStatistic ~= nil then
                    vehicle:updatePFStatistic("yield", debugValues)
                    vehicle:updatePFStatistic("yieldWeight", debugValues * (fillType.massPerLiter / FillTypeManager.MASS_SCALE))
                    vehicle:updatePFStatistic("yieldRegular", regularLiters)
                    vehicle:updatePFStatistic("yieldBestPrice", self:getBestPriceForFillType(fillType) * debugValues)
                end
                local maxPrice = spec.currentCombineVehicle
                if maxPrice ~= nil and maxPrice.setLastYieldValues ~= nil then
                    maxPrice:setLastYieldValues(self:getYieldFromArea(maxPrice, vehicle, spec.inputFruitTypeIndex, 10000 / g_currentMission:getFruitPixelsToSqm()) * (fillType.massPerLiter / FillTypeManager.MASS_SCALE), newMultiplier * 0.5 * 100, self.replaceYieldPotential * 100)
                end
            end
        end
        self.lastMultiplier = nil
        self.lastPlowFactor = nil
        self.lastWeedFactor = nil
        self.lastStubbleFactor = nil
        self.lastRollerFactor = nil
    end)
    pfModule:overwriteGameFunction(Cutter, "processCutterArea", function(superFunc, vehicle, workArea, dt)
        -- upvalues: (copy) self, (copy) pfModule
        if not vehicle.isServer and vehicle.currentUpdateDistance > Cutter.CLIENT_DM_UPDATE_RADIUS then
            return superFunc(vehicle, workArea)
        end
        local specCutter = vehicle.spec_cutter
        local combine = specCutter.workAreaParameters.combineVehicle
        if combine == nil then
            return superFunc(vehicle, workArea, dt)
        end
        local xs, _, zs = getWorldTranslation(workArea.start)
        local xw, _, zw = getWorldTranslation(workArea.width)
        local xh, _, zh = getWorldTranslation(workArea.height)
        self.densityMapParallelogram:updateFromWorldPositions(xs, zs, xw, zw, xh, zh)
        local strawChopperActive = false
        local combineSpec = combine.spec_combine
        if combineSpec ~= nil then
            local strawFruitType = combineSpec.lastValidInputFruitType
            if strawFruitType == nil then
                strawFruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(combineSpec.lastCuttersOutputFillType)
            end
            if strawFruitType ~= nil then
                local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(strawFruitType)
            end
        end
        pfModule.coverMap:preUpdateCoverArea(specCutter.workAreaParameters.fruitTypeIndicesToUse, self.densityMapParallelogram, specCutter.allowsForageGrowthState, strawChopperActive)
        local strawFruitType, fruitTypeDesc, currentYieldPotential, pHFactor, regularPHFactor = self:updateLatestFactors(pfModule, vehicle, false, false)
        self.replaceNFactor = strawFruitType
        self.replaceRegularNFactor = fruitTypeDesc
        self.replacePHFactor = pHFactor
        self.replaceRegularPHFactor = regularPHFactor
        self.replaceYieldPotential = currentYieldPotential
        local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition((xs + xw) * 0.5, (zs + zw) * 0.5)
        local mission = g_missionManager:getMissionAtWorldPosition(xs, zs) or (g_missionManager:getMissionAtWorldPosition(xw, zw) or g_missionManager:getMissionAtWorldPosition(xh, zh))
        self.checkMultiplier = true
        self.replaceMultiplier = mission ~= nil
        local lastRealArea, lastArea = superFunc(vehicle, workArea, dt)
        self.checkMultiplier = false
        self.replaceMultiplier = false
        self:updateWeedFactor(vehicle)
        local phMapUpdated, nMapUpdated = pfModule.coverMap:postUpdateCoverArea(specCutter.workAreaParameters.fruitTypeIndicesToUse, self.densityMapParallelogram, specCutter.allowsForageGrowthState, strawChopperActive)
        self:updateLatestFactors(pfModule, vehicle, phMapUpdated, nMapUpdated)
        self:setLastScoringValues(lastRealArea, farmlandId, vehicle.lastNActualValue, vehicle.lastNTargetValue, vehicle.lastPHActualValue, vehicle.lastPHTargetValue, vehicle.lastIgnoreOverfertilization, fillTypeIndex)
        local fillTypeIndex = nil
        local inputFruitType = specCutter.workAreaParameters.lastFruitType
        if inputFruitType ~= nil then
            fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(inputFruitType)
        end
        local regularMultiplier, newMultiplier = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
        if lastRealArea > 0 and mission == nil then
            specCutter.workAreaParameters.lastMultiplierArea = specCutter.workAreaParameters.lastArea * 1.05 * newMultiplier
            if pfModule.yieldMap ~= nil then
                pfModule.yieldMap:setAreaYield(xs, zs, xw, zw, xh, zh, newMultiplier)
            end
            if HarvestExtension.YIELD_DEBUG then
                local debugValues = self.debugValues
                debugValues.yieldFactor = newMultiplier
                debugValues.yieldFactorRegular = regularMultiplier
                debugValues.plowFactor = self.lastPlowFactor
                debugValues.weedFactor = self.lastWeedFactor
                debugValues.stubbleFactor = self.lastStubbleFactor
                debugValues.rollerFactor = self.lastRollerFactor
            end
            local debugValues = 1
            if specCutter.fruitTypeConverters[inputFruitType] ~= nil then
                fillTypeIndex = specCutter.fruitTypeConverters[inputFruitType].fillTypeIndex
                debugValues = specCutter.fruitTypeConverters[inputFruitType].conversionFactor
            end
            local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
            local yield = self:getYieldFromArea(combine, vehicle, inputFruitType, specCutter.workAreaParameters.lastMultiplierArea) * debugValues
            local regularYield = self:getYieldFromArea(combine, vehicle, inputFruitType, specCutter.workAreaParameters.lastArea * regularMultiplier) * debugValues
            if vehicle.updatePFStatistic ~= nil then
                vehicle:updatePFStatistic("yield", yield)
                vehicle:updatePFStatistic("yieldWeight", yield * (fillType.massPerLiter / FillTypeManager.MASS_SCALE))
                vehicle:updatePFStatistic("yieldRegular", regularYield)
                vehicle:updatePFStatistic("yieldBestPrice", self:getBestPriceForFillType(fillType) * yield)
            end
            if combine.setLastYieldValues ~= nil then
                combine:setLastYieldValues(self:getYieldFromArea(combine, vehicle, inputFruitType, 10000 / g_currentMission:getFruitPixelsToSqm() * newMultiplier) * debugValues * (fillType.massPerLiter / FillTypeManager.MASS_SCALE), newMultiplier * 0.5 * 100, currentYieldPotential * 100)
            end
        end
        self.lastMultiplier = nil
        self.lastPlowFactor = nil
        self.lastWeedFactor = nil
        self.lastStubbleFactor = nil
        self.lastRollerFactor = nil
        return lastRealArea, lastArea
    end)
    pfModule:overwriteGameFunction(FSBaseMission, "getHarvestScaleMultiplier", function(superFunc, mission, fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPercentage)
        -- upvalues: (copy) self
        local multiplier = superFunc(mission, fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPercentage)
        if self.checkMultiplier then
            self.lastMultiplier = multiplier
            self.lastPlowFactor = plowFactor
            self.lastWeedFactor = weedFactor
            self.lastStubbleFactor = stubbleFactor
            self.lastRollerFactor = rollerFactor
            local _, newMultiplier = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
            if self.replaceMultiplier then
                return newMultiplier
            end
        end
        return multiplier
    end)
    pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDestroyCommonArea", function(superFunc, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, onlyOnFields, deleteAll, resetDisplacement)
        -- upvalues: (copy) pfModule
        pfModule.nitrogenMap:updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        superFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, onlyOnFields, deleteAll, resetDisplacement)
        pfModule.nitrogenMap:postUpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    end)
    pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDiscHarrowArea", function(superFunc, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex)
        -- upvalues: (copy) pfModule
        pfModule.nitrogenMap:updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        local changedArea, totalArea = superFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex)
        pfModule.nitrogenMap:postUpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        return changedArea, totalArea
    end)
    pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDirectSowingArea", function(superFunc, fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, ridgeSeeding, angle, growthState, blockedSprayTypeIndex)
        -- upvalues: (copy) pfModule
        pfModule.nitrogenMap:updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        local changedArea, totalArea = superFunc(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, ridgeSeeding, angle, growthState, blockedSprayTypeIndex)
        pfModule.nitrogenMap:postUpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        return changedArea, totalArea
    end)
    pfModule:overwriteGameFunction(FSDensityMapUtil, "getWeedFactor", function(superFunc, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
        return superFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex) > 0 and 1 or 0
    end)
end