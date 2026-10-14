CoverMap = {}
CoverMap.MOD_NAME = g_currentModName
local CoverMap_mt = Class(CoverMap, ValueMap)
source(g_currentModDirectory .. "scripts/densityMapUpdates/CoverMapDensityMapTask.lua")
function CoverMap.new(pfModule, customMt)
    -- upvalues: (copy) CoverMap_mt
    local self = ValueMap.new(pfModule, customMt or CoverMap_mt)
    self.name = "coverMap"
    if g_server ~= nil then
        addConsoleCommand("pfUncoverField", "Uncovers given field", "debugUncoverField", self)
        addConsoleCommand("pfUncoverAll", "Uncovers all fields", "debugUncoverAll", self)
        addConsoleCommand("pfReduceCoverState", "Reduces cover State for given field", "debugReduceCoverStateField", self)
        addConsoleCommand("pfReduceCoverStateAll", "Reduces cover State for all fields", "debugReduceCoverStateAll", self)
    end
    return self
end
function CoverMap:initialize()
    CoverMap:superClass().initialize(self)
    self.densityMapModifiersAnalyse = {}
    self.densityMapModifiersUncover = nil
    self.densityMapModifiersFarmlandState = {}
    self.densityMapModifiersUpdate = nil
    self.densityMapModifiersResetLock = {}
end
function CoverMap:delete()
    if g_server ~= nil then
        removeConsoleCommand("pfUncoverField")
        removeConsoleCommand("pfUncoverAll")
        removeConsoleCommand("pfReduceCoverState")
        removeConsoleCommand("pfReduceCoverStateAll")
    end
    CoverMap:superClass().delete(self)
end
function CoverMap:loadFromXML(xmlFile, key, _, _, _)
    key = key .. ".coverMap"
    self.sizeX = getXMLInt(xmlFile, key .. "#sizeX") or 1024
    self.sizeY = getXMLInt(xmlFile, key .. "#sizeY") or 1024
    self.lockChannel = getXMLInt(xmlFile, key .. "#lockChannel") or 0
    self.firstChannel = getXMLInt(xmlFile, key .. "#firstChannel") or 1
    self.numChannels = getXMLInt(xmlFile, key .. "#numChannels") or 4
    self.maxValue = 2 ^ self.numChannels - 1
    self.maxValue = getXMLInt(xmlFile, key .. "#maxValue") or self.maxValue
    self.sampledValue = self.maxValue + 1
    self.bitVectorMap = self:loadSavedBitVectorMap("coverMap", "precisionFarming_coverMap.grle", self.firstChannel + self.numChannels, self.sizeX)
    self:addBitVectorMapToSync(self.bitVectorMap)
    self:addBitVectorMapToSave(self.bitVectorMap, "precisionFarming_coverMap.grle")
    self:addBitVectorMapToDelete(self.bitVectorMap)
    self.bitVectorMapSoilSampleFarmId = self:loadSavedBitVectorMap("soilSampleFarmIdMap", "precisionFarming_soilSampleFarmIdMap.grle", 4, self.sizeX)
    self:addBitVectorMapToSave(self.bitVectorMapSoilSampleFarmId, "precisionFarming_soilSampleFarmIdMap.grle")
    self:addBitVectorMapToDelete(self.bitVectorMapSoilSampleFarmId)
    self.bitVectorMapTempHarvestLock = self:loadSavedBitVectorMap("bitVectorMapTempHarvestLock", "bitVectorMapTempHarvestLock.grle", 1, self.sizeX)
    self:addBitVectorMapToDelete(self.bitVectorMapTempHarvestLock)
    self.soilMap = g_precisionFarming.soilMap
    self.yieldMap = g_precisionFarming.yieldMap
    self.seedRateMap = g_precisionFarming.seedRateMap
    return true
end
function CoverMap:overwriteGameFunctions(pfModule)
    CoverMap:superClass().overwriteGameFunctions(self, pfModule)
end
function CoverMap:getShowInMenu()
    return false
end
function CoverMap:analyseArea(densityMapShape, state, farmId, _)
    local modifier = self.densityMapModifiersAnalyse.modifier
    local maskFilter = self.densityMapModifiersAnalyse.maskFilter
    local modifierFarmIdMap = self.densityMapModifiersAnalyse.modifierFarmIdMap
    if modifier == nil or (maskFilter == nil or modifierFarmIdMap == nil) then
        self.densityMapModifiersAnalyse.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
        modifier = self.densityMapModifiersAnalyse.modifier
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        self.densityMapModifiersAnalyse.maskFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        self.densityMapModifiersAnalyse.maskFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        self.densityMapModifiersAnalyse.modifierFarmIdMap = DensityMapModifier.new(self.bitVectorMapSoilSampleFarmId, 0, 4, g_terrainNode)
        modifierFarmIdMap = self.densityMapModifiersAnalyse.modifierFarmIdMap
    end
    densityMapShape:applyToModifier(modifier)
    densityMapShape:applyToModifier(modifierFarmIdMap)
    local fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel = modifier:executeSetWithStats(state or self.sampledValue, maskFilter)
    modifierFarmIdMap:executeSet(farmId, maskFilter)
    self.soilMap:onAnalyseArea(densityMapShape, state, farmId)
    return groundTypeMapId, groundTypeFirstChannel
end
function CoverMap.uncoverAnalysedArea(_, farmId)
    local updateTask = CoverMapDensityMapTask.new()
    updateTask:setData(farmId, nil)
    updateTask:enqueue()
end
function CoverMap.uncoverFarmlandArea(_, farmlandId)
    local updateTask = CoverMapDensityMapTask.new()
    updateTask:setData(nil, farmlandId)
    updateTask:enqueue()
end
function CoverMap:onCoverUpdateFinished(farmId, farmlandId, sampledPercentageByFarmlandId) end
function CoverMap:getCoverMultiModifier(farmId, farmlandId)
    local functionData = self.densityMapModifiersUncover
    if functionData == nil then
        functionData = {
            ["modifier"] = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode),
            ["farmlandMaskFilter"] = DensityMapFilter.new(g_farmlandManager.localMap, 0, g_farmlandManager.numberOfBits),
            ["sampledFilter"] = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        }
        functionData.sampledFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.sampledValue)
        functionData.farmFilter = DensityMapFilter.new(self.bitVectorMapSoilSampleFarmId, 0, 4)
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.noFieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.noFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        functionData.coverFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        functionData.coverFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue + 1)
        functionData.sampleStateMaskFilters = {}
        functionData.farmlandModifiers = {}
        self.densityMapModifiersUncover = functionData
    end
    if farmId == nil then
        if farmlandId == nil then
            return nil, nil
        end
        local fieldGroundSystem = functionData.farmlandModifiers[farmlandId]
        if fieldGroundSystem == nil then
            local groundTypeMapId = DensityMapMultiModifier.new()
            local groundTypeFirstChannel = functionData.modifier
            local groundTypeNumChannels = functionData.farmlandMaskFilter
            local farmlandIds = functionData.fieldFilter
            local noFieldFilter = functionData.noFieldFilter
            groundTypeNumChannels:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
            if farmlandId < 0 then
                groundTypeNumChannels = nil
            end
            groundTypeMapId:addExecuteSet(0, groundTypeFirstChannel, noFieldFilter, groundTypeNumChannels)
            self.yieldMap:addClearToMultiModifier(groundTypeMapId, noFieldFilter, groundTypeNumChannels)
            self.seedRateMap:addClearToMultiModifier(groundTypeMapId, noFieldFilter, groundTypeNumChannels)
            self.soilMap:addUncoverToMultiModifier(groundTypeMapId, farmlandIds, groundTypeNumChannels, noFieldFilter, groundTypeNumChannels)
            groundTypeMapId:addExecuteSet(self.maxValue, groundTypeFirstChannel, farmlandIds, groundTypeNumChannels)
            local farmlandIds = { farmlandId }
            self:addSampleStateGetToMultiModifier(groundTypeMapId, functionData, farmlandIds)
            functionData.farmlandModifiers[farmlandId] = {
                ["multiModifier"] = groundTypeMapId,
                ["farmlandIds"] = farmlandIds
            }
        end
        return fieldGroundSystem.multiModifier, fieldGroundSystem.farmlandIds
    end
    local fieldGroundSystem = DensityMapMultiModifier.new()
    local groundTypeMapId = functionData.modifier
    local groundTypeFirstChannel = functionData.farmFilter
    local groundTypeNumChannels = functionData.sampledFilter
    groundTypeFirstChannel:setValueCompareParams(DensityValueCompareType.EQUAL, farmId)
    if farmId < 0 then
        groundTypeFirstChannel = nil
    end
    self.soilMap:addUncoverToMultiModifier(fieldGroundSystem, groundTypeNumChannels, groundTypeFirstChannel)
    fieldGroundSystem:addExecuteSet(self.maxValue, groundTypeMapId, groundTypeNumChannels, groundTypeFirstChannel)
    local farmlandIds = {}
    for _farmlandId, _farmId in pairs(g_farmlandManager.farmlandMapping) do
        if _farmId == farmId then
            table.insert(farmlandIds, _farmlandId)
        end
    end
    self:addSampleStateGetToMultiModifier(fieldGroundSystem, functionData, farmlandIds)
    return fieldGroundSystem, farmlandIds
end
function CoverMap.addSampleStateGetToMultiModifier(_, multiModifier, functionData, farmlandIds)
    for _, farmlandId in ipairs(farmlandIds) do
        local maskFilter = functionData.sampleStateMaskFilters[farmlandId]
        if maskFilter == nil then
            maskFilter = DensityMapFilter.new(g_farmlandManager.localMap, 0, g_farmlandManager.numberOfBits)
            maskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
            functionData.sampleStateMaskFilters[farmlandId] = maskFilter
        end
        local fieldLabel = "field_" .. tostring(farmlandId)
        local sampledLabel = "sampled_" .. tostring(farmlandId)
        multiModifier:addExecuteGet(fieldLabel, functionData.modifier, maskFilter, functionData.fieldFilter)
        multiModifier:addExecuteGet(sampledLabel, functionData.modifier, functionData.coverFilter, maskFilter, functionData.fieldFilter)
    end
end
function CoverMap:getFarmlandSampleState(farmlandId)
    local modifier = self.densityMapModifiersFarmlandState.modifier
    local coverFilter = self.densityMapModifiersFarmlandState.coverFilter
    local maskFilter = self.densityMapModifiersFarmlandState.maskFilter
    local fieldFilter = self.densityMapModifiersFarmlandState.fieldFilter
    if modifier == nil or (coverFilter == nil or (maskFilter == nil or fieldFilter == nil)) then
        self.densityMapModifiersFarmlandState.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        self.densityMapModifiersFarmlandState.modifier:setParallelogramDensityMapCoords(0, 0, 0, self.sizeY, self.sizeX, 0, DensityCoordType.POINT_POINT_POINT)
        self.densityMapModifiersFarmlandState.coverFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        self.densityMapModifiersFarmlandState.coverFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue + 1)
        local farmlandManager = g_farmlandManager
        self.densityMapModifiersFarmlandState.maskFilter = DensityMapFilter.new(farmlandManager.localMap, 0, farmlandManager.numberOfBits)
        self.densityMapModifiersFarmlandState.maskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        self.densityMapModifiersFarmlandState.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        self.densityMapModifiersFarmlandState.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
    end
    maskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
    local farmlandManager, fieldGroundSystem, groundTypeMapId = modifier:executeGet(maskFilter, fieldFilter)
    local groundTypeFirstChannel, groundTypeNumChannels, _ = modifier:executeGet(coverFilter, maskFilter, fieldFilter)
    return fieldGroundSystem <= 0 and 0 or groundTypeNumChannels / fieldGroundSystem
end
function CoverMap:getCoverUpdateDensityMapModifiers(fruitTypes, preUpdate, useMinForageState, _)
    local functionData = self.densityMapModifiersUpdate
    if functionData == nil then
        functionData = {
            ["modifier"] = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode),
            ["lockModifier"] = DensityMapModifier.new(self.bitVectorMapTempHarvestLock, 0, 1, g_terrainNode),
            ["lockFilter"] = DensityMapFilter.new(self.bitVectorMapTempHarvestLock, 0, 1)
        }
        functionData.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
        functionData.lockFilterReduction = DensityMapFilter.new(self.bitVectorMapTempHarvestLock, 0, 1)
        functionData.lockFilterReduction:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
        functionData.coverStateFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        functionData.coverStateFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue)
        functionData.multiModifiersPreUpdateByHash = {}
        functionData.numChangedPixelsPre = {}
        functionData.totalNumPixelsPre = {}
        functionData.multiModifiersPostUpdateByHash = {}
        functionData.numChangedPixelsPost = {}
        functionData.totalNumPixelsPost = {}
        self.densityMapModifiersUpdate = functionData
    end
    local multiModifiersByHash = preUpdate and functionData.multiModifiersPreUpdateByHash or functionData.multiModifiersPostUpdateByHash
    local hash = 0
    for _, fruitIndex in pairs(fruitTypes) do

    end
    local multiModifiers = multiModifiersByHash[hash]
    if multiModifiers == nil then
        multiModifiers = {}
        for _ = 1, 2 do
            local fruitIndex = _ == 2
            if preUpdate then
                local multiModifier = DensityMapMultiModifier.new()
                multiModifier:addExecuteSet(0, functionData.lockModifier)
                for _, fruitIndex in pairs(fruitTypes) do
                    local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
                    if desc ~= nil and desc.terrainDataPlaneId ~= nil then
                        local fruitFilterHarvestState = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        local minHarvestState = desc.minHarvestingGrowthState
                        local maxHarvestState = desc.maxHarvestingGrowthState
                        if fruitIndex and desc.minForageGrowthState ~= 0 then
                            minHarvestState = math.min(minHarvestState, desc.minForageGrowthState)
                        end
                        if minHarvestState == maxHarvestState then
                            fruitFilterHarvestState:setValueCompareParams(DensityValueCompareType.EQUAL, minHarvestState)
                        else
                            fruitFilterHarvestState:setValueCompareParams(DensityValueCompareType.BETWEEN, minHarvestState, maxHarvestState)
                        end
                        fruitFilterHarvestState:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
                        multiModifier:addExecuteSetWithStats(tostring(fruitIndex), 1, functionData.lockModifier, fruitFilterHarvestState)
                        if desc.minPreparingGrowthState ~= nil then
                            local fruitFilterPrepareState = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                            if desc.minPreparingGrowthState == desc.maxPreparingGrowthState then
                                fruitFilterPrepareState:setValueCompareParams(DensityValueCompareType.EQUAL, desc.minPreparingGrowthState)
                            else
                                fruitFilterPrepareState:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)
                            end
                            fruitFilterPrepareState:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
                            multiModifier:addExecuteSetWithStats(tostring(fruitIndex), 1, functionData.lockModifier, fruitFilterPrepareState)
                        end
                    end
                end
                multiModifiers[fruitIndex] = multiModifier
            else
                local multiModifier = DensityMapMultiModifier.new()
                for _, fruitIndex in pairs(fruitTypes) do
                    local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
                    if desc ~= nil and desc.terrainDataPlaneId ~= nil then
                        local fruitFilterHarvestState = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        local minHarvestState = desc.minHarvestingGrowthState
                        local maxHarvestState = desc.maxHarvestingGrowthState
                        if fruitIndex and desc.minForageGrowthState ~= 0 then
                            minHarvestState = math.min(minHarvestState, desc.minForageGrowthState)
                        end
                        if minHarvestState == maxHarvestState then
                            fruitFilterHarvestState:setValueCompareParams(DensityValueCompareType.EQUAL, minHarvestState)
                        else
                            fruitFilterHarvestState:setValueCompareParams(DensityValueCompareType.BETWEEN, minHarvestState, maxHarvestState)
                        end
                        fruitFilterHarvestState:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
                        multiModifier:addExecuteSet(0, functionData.lockModifier, functionData.lockFilter, fruitFilterHarvestState)
                        if desc.minPreparingGrowthState ~= nil then
                            local fruitFilterPrepareState = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                            if desc.minPreparingGrowthState == desc.maxPreparingGrowthState then
                                fruitFilterPrepareState:setValueCompareParams(DensityValueCompareType.EQUAL, desc.minPreparingGrowthState)
                            else
                                fruitFilterPrepareState:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)
                            end
                            fruitFilterPrepareState:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
                            multiModifier:addExecuteSet(0, functionData.lockModifier, functionData.lockFilter, fruitFilterPrepareState)
                        end
                    end
                end
                multiModifier:addExecuteAdd(-1, functionData.modifier, functionData.lockFilter, functionData.coverStateFilter)
                multiModifier:addExecuteGet("pixelsToLock", functionData.modifier, functionData.lockFilter)
                multiModifiers[fruitIndex] = multiModifier
            end
        end
        multiModifiersByHash[hash] = multiModifiers
    end
    if preUpdate then
        return multiModifiers[useMinForageState], functionData.numChangedPixelsPre, functionData.totalNumPixelsPre
    else
        return multiModifiers[useMinForageState], functionData.numChangedPixelsPost, functionData.totalNumPixelsPost
    end
end
function CoverMap:preUpdateCoverArea(fruitTypes, densityMapShape, useMinForageState, strawChopperActive)
    if useMinForageState == nil then
        useMinForageState = false
    end
    local multiModifierPreUpdate, numChangedPixels, totalNumPixels = self:getCoverUpdateDensityMapModifiers(fruitTypes, true, useMinForageState, strawChopperActive)
    if multiModifierPreUpdate ~= nil then
        densityMapShape:applyToModifier(multiModifierPreUpdate)
        multiModifierPreUpdate:resetStats()
        multiModifierPreUpdate:execute(nil, numChangedPixels, totalNumPixels)
        for fruitIndexStr, numPixels in pairs(numChangedPixels) do
            if numPixels > 0 then
                self.lastUsedFruitIndex = tonumber(fruitIndexStr)
            end
        end
    end
end
function CoverMap:postUpdateCoverArea(fruitTypes, densityMapShape, useMinForageState, strawChopperActive)
    if useMinForageState == nil then
        useMinForageState = false
    end
    local multiModifierPostUpdate, numChangedPixels, totalNumPixels = self:getCoverUpdateDensityMapModifiers(fruitTypes, false, useMinForageState, strawChopperActive)
    if multiModifierPostUpdate == nil then
        return false, false
    end
    local functionData = self.densityMapModifiersUpdate
    if functionData == nil then
        return false, false
    end
    local lockModifier = functionData.lockModifier
    densityMapShape:applyToModifier(multiModifierPostUpdate)
    multiModifierPostUpdate:resetStats()
    multiModifierPostUpdate:execute(nil, numChangedPixels, totalNumPixels)
    local phMapUpdated = false
    local nMapUpdated = false
    if (numChangedPixels.pixelsToLock or 0) > 0 and self.lastUsedFruitIndex ~= nil then
        if self.pfModule.nitrogenMap ~= nil then
            nMapUpdated = self.pfModule.nitrogenMap:harvestUpdate(functionData.lockFilterReduction, self.lastUsedFruitIndex, densityMapShape, useMinForageState, strawChopperActive)
        end
        if self.pfModule.pHMap ~= nil then
            phMapUpdated = self.pfModule.pHMap:harvestUpdate(lockFilterReduction, self.lastUsedFruitIndex, densityMapShape, useMinForageState, strawChopperActive)
        end
        if self.pfModule.seedRateMap ~= nil then
            self.pfModule.seedRateMap:harvestUpdate(lockFilterReduction, self.lastUsedFruitIndex, densityMapShape, useMinForageState, strawChopperActive)
        end
    end
    densityMapShape:applyToModifier(lockModifier)
    lockModifier:executeSet(0)
    return phMapUpdated, nMapUpdated
end
function CoverMap:resetCoverLock(densityMapShape)
    local modifier = self.densityMapModifiersResetLock.modifier
    if modifier == nil then
        self.densityMapModifiersResetLock.modifier = DensityMapModifier.new(self.bitVectorMap, self.lockChannel, 1, g_terrainNode)
        modifier = self.densityMapModifiersResetLock.modifier
    end
    densityMapShape:applyToModifier(modifier)
    modifier:executeSet(0)
end
function CoverMap:getNumCoverOverlays()
    return self.maxValue - 1
end
function CoverMap:buildCoverStateOverlay(overlay, index)
    local numOverlays = self:getNumCoverOverlays()
    resetDensityMapVisualizationOverlay(overlay)
    setOverlayColor(overlay, 1, 1, 1, (numOverlays - (index - 1)) / numOverlays)
    setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, self.firstChannel, self.numChannels, index, 0, 0, 0)
end
function CoverMap:getIsUncoveredAtPos(x, z, isWorldPos)
    if isWorldPos == true then
        x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
        z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
    end
    local coverValue = getBitVectorMapPoint(self.bitVectorMap, x, z, self.firstChannel, self.numChannels)
    return coverValue > 1 and coverValue <= self.maxValue
end
function CoverMap:getLevelAtWorldPos(x, z)
    x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
    z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
    return getBitVectorMapPoint(self.bitVectorMap, x, z, self.firstChannel, self.numChannels)
end
function CoverMap:debugReduceCoverStateField(fieldId)
    local field = g_fieldManager:getFieldById((tonumber(fieldId)))
    if field ~= nil and field.getDensityMapPolygon ~= nil then
        local area = field:getDensityMapPolygon()
        self:preUpdateCoverArea({}, area, true, false)
        self:postUpdateCoverArea({}, area, true, false)
        self:resetCoverLock(area)
    end
    self.pfModule:updatePrecisionFarmingOverlays()
end
function CoverMap:debugReduceCoverStateAll()
    local i = 1
    for i = i, #g_fieldManager.fields do
        self:debugReduceCoverStateField(i)
    end
end
function CoverMap:debugUncoverField(fieldId)
    local field = g_fieldManager:getFieldById((tonumber(fieldId)))
    if field ~= nil then
        self:analyseArea(field:getDensityMapPolygon(), nil, g_farmlandManager:getFarmlandOwner(field.farmland.id), field.farmland.id)
        self:uncoverAnalysedArea(-1)
    end
end
function CoverMap:debugUncoverAll()
    local i = 1
    for i = i, #g_fieldManager.fields do
        self:debugUncoverField(i)
    end
end