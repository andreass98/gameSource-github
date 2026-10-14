FSDensityMapUtil = {}
local old = DensityMapModifier.new
function DensityMapModifier.new(...)
    -- upvalues: (copy) old
    local modifier = old(...)
    modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
    return modifier
end
FSDensityMapUtil.functionCache = {}
function FSDensityMapUtil.clearCache()
    FSDensityMapUtil.functionCache = {}
end
function FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
    local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
    if groundTypeMapId == nil then
        return false, 0, 0
    end
    local densityBits = getDensityAtWorldPos(groundTypeMapId, x, y, z)
    local groundType = bit32.band(bit32.rshift(densityBits, groundTypeFirstChannel), 2 ^ groundTypeNumChannels - 1)
    return groundType ~= 0, densityBits, groundType
end
function FSDensityMapUtil.cutFruitArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, useMinForageState, excludedSprayType, _, limitToField)
    local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
    if desc.terrainDataPlaneId == nil then
        return 0
    end
    local functionData = FSDensityMapUtil.functionCache.cutFruitArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        functionData = {
            ["fruitValueModifiers"] = {},
            ["fruitFilters"] = {},
            ["sownType"] = FieldGroundType.getValueByType(FieldGroundType.SOWN),
            ["groundTypeFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.groundTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
        functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
        functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
        if Platform.gameplay.useRolling then
            local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
            functionData.rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
            functionData.rollerLevelFilter = DensityMapFilter.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels)
            functionData.rollerLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        end
        if Platform.gameplay.usePlowCounter then
            local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
            functionData.plowLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
            functionData.plowLevelFilter = DensityMapFilter.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels)
            functionData.plowLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        end
        if Platform.gameplay.useLimeCounter then
            local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
            functionData.limeLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
        end
        if Platform.gameplay.useStubbleShred then
            local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
            functionData.stubbleShredModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
            functionData.stubbleShredFilter = DensityMapFilter.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels)
            functionData.stubbleShredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
        end
        FSDensityMapUtil.functionCache.cutFruitArea = functionData
    end
    if desc.cutState == 0 then
        return 0
    end
    local fieldGroundSystem = desc.minHarvestingGrowthState
    if useMinForageState then
        fieldGroundSystem = desc.minForageGrowthState
    end
    local sprayLevelMapId = functionData.sprayLevelModifier
    local sprayLevelFirstChannel = functionData.plowLevelModifier
    local sprayLevelNumChannels = functionData.plowLevelFilter
    local groundTypeMapId = functionData.groundTypeModifier
    local groundTypeFirstChannel = functionData.sprayLevelMaxValue
    local groundTypeNumChannels = functionData.fruitValueModifiers[fruitIndex]
    local rollerLevelMapId = functionData.fruitFilters[fruitIndex]
    if groundTypeNumChannels == nil then
        groundTypeNumChannels = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, g_terrainNode)
        groundTypeNumChannels:setReturnValueShift(-1)
        functionData.fruitValueModifiers[fruitIndex] = groundTypeNumChannels
        rollerLevelMapId = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
        functionData.fruitFilters[fruitIndex] = rollerLevelMapId
    end
    rollerLevelMapId:setValueCompareParams(DensityValueCompareType.BETWEEN, fieldGroundSystem, desc.maxHarvestingGrowthState)
    groundTypeNumChannels:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local rollerLevelFirstChannel, rollerLevelNumChannels, _ = groundTypeNumChannels:executeGet(rollerLevelMapId)
    if rollerLevelFirstChannel == 0 then
        return 0
    end
    sprayLevelMapId:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    groundTypeMapId:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local sprayPixelsSum, _, _ = sprayLevelMapId:executeGet(rollerLevelMapId)
    if destroySpray then
        FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, excludedSprayType)
        sprayLevelMapId:executeSet(0, rollerLevelMapId)
    end
    if desc.startSprayLevel > 0 then
        sprayLevelMapId:executeSet(math.min(desc.startSprayLevel, groundTypeFirstChannel), rollerLevelMapId, functionData.groundTypeFilter)
        FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, excludedSprayType)
    end
    local plowTotalDelta = 0
    local rollerTotalDelta = 0
    local limeTotalDelta = 0
    local stubbleTotalDelta = 0
    local weedFactor = 1
    local missionInfo = g_currentMission.missionInfo
    FSDensityMapUtil.removeWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    if missionInfo.weedsEnabled and desc.plantsWeed then
        weedFactor = 1 - FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
        FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    else
        FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    end
    if Platform.gameplay.usePlowCounter then
        sprayLevelFirstChannel:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        if desc.lowSoilDensityRequired then
            local rollerLevelModifier, _
            rollerLevelModifier, plowTotalDelta, _ = sprayLevelFirstChannel:executeGet(rollerLevelMapId, sprayLevelNumChannels)
        end
        if desc.increasesSoilDensity and missionInfo.plowingRequiredEnabled then
            sprayLevelFirstChannel:executeAdd(-1, rollerLevelMapId)
        end
    end
    if desc.needsRolling and Platform.gameplay.useRolling then
        local rollerLevelModifier = functionData.rollerLevelModifier
        rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local _, numPixels
        _, rollerTotalDelta, numPixels = rollerLevelModifier:executeGet(rollerLevelMapId, functionData.rollerLevelFilter)
    end
    if desc.consumesLime and (missionInfo.limeRequired and Platform.gameplay.useLimeCounter) then
        local rollerLevelModifier = functionData.limeLevelModifier
        rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local rollerLevelFilter, _, numPixels
        rollerLevelFilter, _, limeTotalDelta, numPixels = rollerLevelModifier:executeAddWithStats(-1, rollerLevelMapId)
    end
    if Platform.gameplay.useStubbleShred then
        local rollerLevelModifier = functionData.stubbleShredModifier
        rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local rollerLevelFilter, _, numPixels
        rollerLevelFilter, _, stubbleTotalDelta, numPixels = rollerLevelModifier:executeAddWithStats(-1, rollerLevelMapId, functionData.stubbleShredFilter)
    end
    local rollerLevelModifier, rollerLevelFilter, _ = groundTypeMapId:executeGet(rollerLevelMapId)
    if desc.harvestGroundType ~= nil then
        rollerLevelMapId:setValueCompareParams(DensityValueCompareType.BETWEEN, fieldGroundSystem, desc.maxHarvestingGrowthState)
        groundTypeMapId:executeSet(FieldGroundType.getValueByType(desc.harvestGroundType), rollerLevelMapId)
    end
    local groundValue = nil
    if limitToField then
        groundValue = functionData.groundTypeFilter
    end
    local numPixels = 0
    local totalNumPixels = 0
    local scaledPixels = 0
    local maxArea = 0
    local growthState = fieldGroundSystem
    for src, target in pairs(desc.harvestTransitions) do
        if fieldGroundSystem <= src and src <= desc.maxHarvestingGrowthState then
            rollerLevelMapId:setValueCompareParams(DensityValueCompareType.EQUAL, src)
            local _, partialNumPixels
            _, partialNumPixels, totalNumPixels = groundTypeNumChannels:executeSetWithStats(target, rollerLevelMapId, groundValue)
            local yieldScale = desc:getYieldScale(src)
            if maxArea < partialNumPixels then
                growthState = src
                maxArea = partialNumPixels
            end
        end
    end
    local plowFactor = 0
    local limeFactor = 0
    local sprayFactor = 0
    local src = 0
    local target = 0
    local _ = 0
    if numPixels > 0 then
        if desc.lowSoilDensityRequired and missionInfo.plowingRequiredEnabled then
            plowFactor = math.abs(plowTotalDelta) / numPixels
        else
            plowFactor = 1
        end
        if desc.needsRolling and Platform.gameplay.useRolling then
            target = math.abs(rollerTotalDelta) / numPixels
        else
            target = 1
        end
        if desc.growthRequiresLime and (missionInfo.limeRequired and Platform.gameplay.useLimeCounter) then
            limeFactor = math.abs(limeTotalDelta) / numPixels
        else
            limeFactor = 1
        end
        sprayFactor = sprayPixelsSum / (numPixels * groundTypeFirstChannel)
        if Platform.gameplay.useStubbleShred then
            src = math.abs(stubbleTotalDelta) / numPixels
        else
            src = 1
        end
        if desc.beeYieldBonusPercentage ~= 0 then
            _ = g_currentMission.beehiveSystem:getBeehiveInfluenceFactorAt(startWorldX, startWorldZ) * desc.beeYieldBonusPercentage
        end
    end
    return scaledPixels, totalNumPixels, sprayFactor, plowFactor, limeFactor, weedFactor, src, target, _, growthState, maxArea, rollerLevelModifier
end
function FSDensityMapUtil.getFruitArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, allowPreparing, useMinForageState)
    local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
    if desc.terrainDataPlaneId == nil then
        return 0, 0
    end
    local functionData = FSDensityMapUtil.functionCache.getFruitArea
    if functionData == nil then
        FSDensityMapUtil.functionCache.getFruitArea = {
            ["fruitModifiers"] = {},
            ["fruitFilter"] = {}
        }
    end
    local fruitModifier = functionData.fruitModifiers[fruitIndex]
    if fruitModifier == nil then
        fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, g_terrainNode)
        fruitModifier:setReturnValueShift(-1)
        functionData.fruitModifiers[fruitIndex] = fruitModifier
        functionData.fruitFilter[fruitIndex] = DensityMapFilter.new(fruitModifier)
    end
    local terrainRootNode = functionData.fruitFilter[fruitIndex]
    local minState = desc.minHarvestingGrowthState
    if useMinForageState then
        minState = desc.minForageGrowthState
    end
    fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    terrainRootNode:setValueCompareParams(DensityValueCompareType.BETWEEN, minState, desc.maxHarvestingGrowthState)
    local ret, numPixels, totalNumPixels = fruitModifier:executeGet(terrainRootNode)
    if allowPreparing and (desc.minPreparingGrowthState >= 0 and desc.maxPreparingGrowthState >= 0) then
        terrainRootNode:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)
        local ret2, numPixels2, totalNumPixels2 = fruitModifier:executeGet(terrainRootNode)
    end
    local ret2 = 0
    local totalNumPixels2 = desc.maxHarvestingGrowthState
    local numPixels2 = minState
    for minState = minState, totalNumPixels2 do
        terrainRootNode:setValueCompareParams(DensityValueCompareType.EQUAL, minState)
        local _, area = fruitModifier:executeGet(terrainRootNode)
        if ret2 < area then
            numPixels2 = minState
            ret2 = area
        end
    end
    return ret, numPixels, totalNumPixels, numPixels2
end
function FSDensityMapUtil.updateRollerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
    if not Platform.gameplay.useRolling then
        return 0
    end
    angle = angle or 0
    local functionData = FSDensityMapUtil.functionCache.updateRollerArea
    if functionData == nil then
        FSDensityMapUtil.functionCache.updateRollerArea = {
            ["multiModifiers"] = {},
            ["numChangedPixels"] = {}
        }
    end
    local multiModifier = functionData.multiModifiers[angle]
    if multiModifier == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
        local rolledSeedbedType = FieldGroundType.getValueByType(FieldGroundType.ROLLED_SEEDBED)
        local rollerLinesType = FieldGroundType.getValueByType(FieldGroundType.ROLLER_LINES)
        local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
        local firstSowingValue, lastSowingValue = fieldGroundSystem:getSowingRange()
        local rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
        local groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
        local groundTypeAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
        local rollerLevelFilter = DensityMapFilter.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels)
        rollerLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        local sownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        sownFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowingValue, lastSowingValue)
        local sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
        local rollerLinesFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        rollerLinesFilter:setValueCompareParams(DensityValueCompareType.EQUAL, rollerLinesType)
        local rolledSeedbedFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        rolledSeedbedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, rolledSeedbedType)
        local stoneModifier = nil
        local stoneFilter = nil
        local stoneSystem = g_currentMission.stoneSystem
        if stoneSystem:getMapHasStones() then
            local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
            local stoneMinValue = stoneSystem:getMinMaxValues()
            stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
            stoneModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
            stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
            stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stoneMinValue)
        end
        multiModifier = DensityMapMultiModifier.new()
        for stoneMinValue, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil then
                local firstGrowthStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                firstGrowthStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
                if stoneModifier ~= nil then
                    multiModifier:addExecuteAdd(-1, stoneModifier, stoneFilter, sownFilter, firstGrowthStateFilter)
                end
                multiModifier:addExecuteSetWithStats("rolled", 0, rollerLevelModifier, rollerLevelFilter, sownFilter, firstGrowthStateFilter)
                multiModifier:addExecuteSet(rollerLinesType, groundTypeModifier, sownFilter, firstGrowthStateFilter)
                multiModifier:addExecuteSet(angle, groundTypeAngleModifier, rollerLinesFilter, firstGrowthStateFilter)
            end
        end
        if stoneModifier ~= nil then
            multiModifier:addExecuteAdd(-1, stoneModifier, stoneFilter)
        end
        multiModifier:addExecuteSetWithStats("rolled", 0, rollerLevelModifier, rollerLevelFilter, sowableFilter)
        multiModifier:addExecuteSet(rolledSeedbedType, groundTypeModifier, sowableFilter)
        multiModifier:addExecuteSet(angle, groundTypeAngleModifier, rolledSeedbedFilter)
        FSDensityMapUtil.multiModifierAddResetDisplacement(multiModifier)
        functionData.multiModifiers[angle] = multiModifier
    end
    local terrainRootNode = functionData.numChangedPixels
    multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    multiModifier:resetStats()
    multiModifier:execute(nil, terrainRootNode, nil)
    return terrainRootNode.rolled
end
function FSDensityMapUtil.updateGrassRollerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, removeStones)
    local functionData = FSDensityMapUtil.functionCache.updateGrassRollerArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        local sprayType = FieldSprayType.getValueByType(FieldSprayType.FERTILIZER)
        local sprayTypeMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_TYPE)
        local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
        local grassDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)
        local meadowDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)
        functionData = {
            ["grassModifier"] = DensityMapModifier.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels, terrainRootNode),
            ["grassFilter"] = DensityMapFilter.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels)
        }
        functionData.grassFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, grassDesc.cutState)
        functionData.grassFilterFirstStage = DensityMapFilter.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels)
        functionData.grassFilterFirstStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, grassDesc.cutState - 1)
        functionData.grassFilterRolledStage = DensityMapFilter.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels)
        functionData.grassFilterRolledStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, grassDesc.cutState)
        functionData.grassRolledCutState = grassDesc.rolledCutState
        if meadowDesc ~= nil and meadowDesc.terrainDataPlaneId ~= nil then
            functionData.meadowModifier = DensityMapModifier.new(meadowDesc.terrainDataPlaneId, meadowDesc.startStateChannel, meadowDesc.numStateChannels, terrainRootNode)
            functionData.meadowFilter = DensityMapFilter.new(meadowDesc.terrainDataPlaneId, meadowDesc.startStateChannel, meadowDesc.numStateChannels)
            functionData.meadowFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, grassDesc.cutState)
            functionData.meadowFilterFirstStage = DensityMapFilter.new(meadowDesc.terrainDataPlaneId, meadowDesc.startStateChannel, meadowDesc.numStateChannels)
            functionData.meadowFilterFirstStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, meadowDesc.cutState - 1)
            functionData.meadowFilterRolledStage = DensityMapFilter.new(meadowDesc.terrainDataPlaneId, meadowDesc.startStateChannel, meadowDesc.numStateChannels)
            functionData.meadowFilterRolledStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, meadowDesc.cutState)
            functionData.meadowRolledCutState = meadowDesc.rolledCutState
            functionData.noMeadowVisibleFilter = DensityMapFilter.new(meadowDesc.terrainDataPlaneId, meadowDesc.startStateChannel, meadowDesc.numStateChannels)
            functionData.noMeadowVisibleFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        end
        functionData.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
        functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
        functionData.outsideFieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.outsideFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        functionData.noGrassVisibleFilter = DensityMapFilter.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels)
        functionData.noGrassVisibleFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
        functionData.sprayTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, sprayType)
        if sprayType > 0 then
            functionData.sprayTypeFilter2 = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
            functionData.sprayTypeFilter2:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayType - 1)
        end
        functionData.notMaxSprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
        functionData.notMaxSprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)
        functionData.areaMaskedFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
        functionData.areaMaskedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sprayTypeMaxValue)
        functionData.sprayType = sprayType
        functionData.maskValue = sprayTypeMaxValue
        local stoneSystem = g_currentMission.stoneSystem
        if stoneSystem:getMapHasStones() then
            local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
            local stoneMinValue = stoneSystem:getMinMaxValues()
            functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
            functionData.stoneModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
            functionData.stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
            functionData.stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stoneMinValue)
        end
        FSDensityMapUtil.functionCache.updateGrassRollerArea = functionData
    end
    local terrainRootNode = functionData.grassModifier
    local fieldGroundSystem = functionData.grassFilter
    local sprayLevelMapId = functionData.grassFilterFirstStage
    local sprayLevelFirstChannel = functionData.grassFilterRolledStage
    local sprayLevelNumChannels = functionData.grassRolledCutState
    local groundTypeMapId = functionData.meadowModifier
    local groundTypeFirstChannel = functionData.meadowFilter
    local groundTypeNumChannels = functionData.meadowFilterFirstStage
    local sprayTypeMapId = functionData.meadowFilterRolledStage
    local sprayTypeFirstChannel = functionData.meadowRolledCutState
    local sprayTypeNumChannels = functionData.sprayLevelModifier
    local sprayType = functionData.sprayTypeModifier
    local sprayTypeMaxValue = functionData.stoneModifier
    local sprayLevelMaxValue = functionData.stoneFilter
    local grassDesc = functionData.outsideFieldFilter
    local meadowDesc = functionData.noGrassVisibleFilter
    local stoneSystem = functionData.noMeadowVisibleFilter
    local stoneMapId = functionData.sprayTypeFilter
    local stoneFirstChannel = functionData.sprayTypeFilter2
    local stoneNumChannels = functionData.notMaxSprayLevelFilter
    local stoneMinValue = functionData.areaMaskedFilter
    local sprayType = functionData.sprayType
    local maskValue = functionData.maskValue
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    if groundTypeMapId ~= nil then
        groundTypeMapId:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    end
    sprayTypeNumChannels:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    sprayType:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    if removeStones ~= false and sprayTypeMaxValue ~= nil then
        sprayTypeMaxValue:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    end
    sprayType:executeSet(maskValue, fieldGroundSystem, stoneMapId, stoneNumChannels)
    if stoneFirstChannel ~= nil then
        sprayType:executeSet(maskValue, fieldGroundSystem, stoneFirstChannel, stoneNumChannels)
    end
    if groundTypeFirstChannel ~= nil then
        sprayType:executeSet(maskValue, groundTypeFirstChannel, stoneMapId, stoneNumChannels)
        if stoneFirstChannel ~= nil then
            sprayType:executeSet(maskValue, groundTypeFirstChannel, stoneFirstChannel, stoneNumChannels)
        end
    end
    sprayType:executeSet(0, stoneMinValue, grassDesc)
    sprayType:executeSet(0, stoneMinValue, meadowDesc, stoneSystem)
    local _, _, numPixels, totalNumPixels = sprayTypeNumChannels:executeAddWithStats(1, stoneMinValue)
    sprayType:executeSet(sprayType, stoneMinValue)
    terrainRootNode:executeSet(2, sprayLevelMapId)
    if sprayLevelNumChannels ~= 0 then
        terrainRootNode:executeSet(sprayLevelNumChannels, sprayLevelFirstChannel)
    end
    if groundTypeMapId ~= nil then
        groundTypeMapId:executeSet(2, groundTypeNumChannels)
        if sprayTypeFirstChannel ~= 0 then
            groundTypeMapId:executeSet(sprayTypeFirstChannel, sprayTypeMapId)
        end
    end
    if removeStones ~= false and sprayTypeMaxValue ~= nil then
        sprayTypeMaxValue:executeAdd(-1, sprayLevelMaxValue)
    end
    DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return numPixels, totalNumPixels
end
function FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, delta, fieldFilter, customFilter)
    local stoneSystem = g_currentMission.stoneSystem
    if stoneSystem:getMapHasStones() then
        local functionData = FSDensityMapUtil.functionCache.addStoneArea
        if functionData == nil then
            local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
            local _, stoneMaxValue = stoneSystem:getMinMaxValues()
            local stoneMaskValue = stoneSystem:getMaskValue()
            functionData = {
                ["stoneModifier"] = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, g_terrainNode),
                ["stoneFilter"] = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
            }
            functionData.stoneFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, stoneMaskValue, stoneMaxValue - 1)
            functionData.stoneMaxReachedFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
            functionData.stoneMaxReachedFilter:setValueCompareParams(DensityValueCompareType.GREATER, stoneMaxValue)
            functionData.stoneMaxValue = stoneMaxValue
            FSDensityMapUtil.functionCache.addStoneArea = functionData
        end
        local terrainRootNode = functionData.stoneModifier
        local stoneMapId = functionData.stoneFilter
        local stoneFirstChannel = functionData.stoneMaxReachedFilter
        local stoneNumChannels = functionData.stoneMaxValue
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        if fieldFilter == nil then
            terrainRootNode:executeAdd(delta, stoneMapId, customFilter)
        else
            terrainRootNode:executeAdd(delta, stoneMapId, fieldFilter, customFilter)
        end
        terrainRootNode:executeSet(stoneNumChannels, stoneFirstChannel)
    end
end
function FSDensityMapUtil.removeStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local numPixels = 0
    local totalNumPixels = 0
    local stoneSystem = g_currentMission.stoneSystem
    if stoneSystem:getMapHasStones() then
        local functionData = FSDensityMapUtil.functionCache.removeStoneArea
        if functionData == nil then
            local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
            functionData = {
                ["stoneModifier"] = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, g_terrainNode)
            }
            FSDensityMapUtil.functionCache.removeStoneArea = functionData
        end
        local terrainRootNode = functionData.stoneModifier
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local stoneFirstChannel
        stoneFirstChannel, numPixels, totalNumPixels = terrainRootNode:executeSetWithStats(0)
    end
    return numPixels, totalNumPixels
end
function FSDensityMapUtil.getStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local stoneSystem = g_currentMission.stoneSystem
    if stoneSystem:getMapHasStones() then
        local functionData = FSDensityMapUtil.functionCache.getStoneArea
        if functionData == nil then
            local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
            local stoneMinValue, stoneMaxValue = stoneSystem:getMinMaxValues()
            functionData = {
                ["stoneModifier"] = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, g_terrainNode),
                ["stoneFilters"] = {}
            }
            local i = 0
            for i = i, stoneMaxValue - stoneMinValue do
                local stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
                stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stoneMinValue + i)
                table.insert(functionData.stoneFilters, stoneFilter)
            end
            FSDensityMapUtil.functionCache.getStoneArea = functionData
        end
        local terrainRootNode = functionData.stoneModifier
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local stoneNumChannels = #functionData.stoneFilters
        local stoneMapId = 1
        local stoneFirstChannel = -1
        for stoneNumChannels = stoneNumChannels, stoneMapId, stoneFirstChannel do
            local stoneMinValue, stoneMaxValue = terrainRootNode:executeGet(functionData.stoneFilters[stoneNumChannels])
            if stoneMinValue > 0 then
                return stoneNumChannels
            end
        end
        return 0
    end
end
function FSDensityMapUtil.updateStonePickerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
    local stoneSystem = g_currentMission.stoneSystem
    if not stoneSystem:getMapHasStones() then
        return 0, 0, 0
    end
    local functionData = FSDensityMapUtil.functionCache.updateStonePickerArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
        local stoneMinValue, stoneMaxValue = stoneSystem:getMinMaxValues()
        local cultivatedType = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
        local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
        local pickedValue = stoneSystem:getPickedValue()
        functionData = {
            ["stoneModifier"] = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode),
            ["stoneFilter"] = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
        }
        functionData.stoneFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, stoneMinValue, stoneMaxValue)
        functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
        functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
        functionData.groundAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
        functionData.stoneMinValue = stoneMinValue
        functionData.cultivatedType = cultivatedType
        functionData.pickedValue = pickedValue
        functionData.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
        FSDensityMapUtil.functionCache.updateStonePickerArea = functionData
    end
    local terrainRootNode = functionData.stoneModifier
    local fieldGroundSystem = functionData.stoneFilter
    local groundTypeMapId = functionData.sowableFilter
    local groundTypeFirstChannel = functionData.groundTypeModifier
    local groundTypeNumChannels = functionData.groundAngleModifier
    local groundAngleMapId = functionData.stoneMinValue
    local groundAngleFirstChannel = functionData.cultivatedType
    local groundAngleNumChannels = functionData.pickedValue
    local sprayTypeMapId = functionData.sprayTypeModifier
    groundTypeFirstChannel:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    groundTypeNumChannels:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    sprayTypeMapId:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local sprayTypeFirstChannel, sprayTypeNumChannels, stoneMapId = terrainRootNode:executeSetWithStats(groundAngleNumChannels, fieldGroundSystem, groundTypeMapId)
    groundTypeFirstChannel:executeSet(groundAngleFirstChannel, groundTypeMapId)
    groundTypeNumChannels:executeSet(angle or 0, groundTypeMapId)
    sprayTypeMapId:executeSet(0, groundTypeMapId)
    FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundTypeMapId)
    local stoneMinValue = sprayTypeFirstChannel - sprayTypeNumChannels * (groundAngleMapId - 1)
    local stoneFirstChannel = math.max(0, stoneMinValue)
    local stoneFirstChannel = 0
    if sprayTypeNumChannels > 0 then
    end
    return stoneFirstChannel, sprayTypeNumChannels, stoneMapId
end
function FSDensityMapUtil.removeFieldArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, deleteAll)
    local functionData = FSDensityMapUtil.functionCache.removeFieldArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        functionData = {}
        local removeFieldMultiModifier = DensityMapMultiModifier.new()
        removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)))
        removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)))
        removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)))
        removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)))
        if Platform.gameplay.usePlowCounter then
            local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
            removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)))
        end
        if Platform.gameplay.useLimeCounter then
            local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
            removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)))
        end
        for clearPlowLevelModifier, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil and (deleteAll or desc.isCultivationAllowed) then
                local clearFruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
                clearFruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
                removeFieldMultiModifier:addExecuteSet(0, clearFruitModifier)
            end
        end
        local plowLevelNumChannels = 1
        local plowLevelMapId = #g_currentMission.dynamicFoliageLayers
        local plowLevelFirstChannel = 1
        for plowLevelNumChannels = plowLevelNumChannels, plowLevelMapId, plowLevelFirstChannel do
            local clearPlowLevelModifier = g_currentMission.dynamicFoliageLayers[plowLevelNumChannels]
            local desc = getTerrainDetailNumChannels(clearPlowLevelModifier)
            removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(clearPlowLevelModifier, 0, desc, terrainRootNode)))
        end
        functionData.removeFieldMultiModifier = removeFieldMultiModifier
        FSDensityMapUtil.functionCache.removeFieldArea = functionData
    end
    local terrainRootNode = functionData.removeFieldMultiModifier
    terrainRootNode:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    terrainRootNode:execute()
end
function FSDensityMapUtil.removeFieldPolygon(polygonVertices, deleteAll)
    local functionData = FSDensityMapUtil.functionCache.removeFieldArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        functionData = {}
        local removeFieldMultiModifier = DensityMapMultiModifier.new()
        removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)))
        removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)))
        removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)))
        removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)))
        if Platform.gameplay.usePlowCounter then
            local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
            removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)))
        end
        if Platform.gameplay.useLimeCounter then
            local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
            removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)))
        end
        for clearPlowLevelModifier, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil and (deleteAll or desc.isCultivationAllowed) then
                local clearFruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
                clearFruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
                removeFieldMultiModifier:addExecuteSet(0, clearFruitModifier)
            end
        end
        local plowLevelNumChannels = 1
        local plowLevelMapId = #g_currentMission.dynamicFoliageLayers
        local plowLevelFirstChannel = 1
        for plowLevelNumChannels = plowLevelNumChannels, plowLevelMapId, plowLevelFirstChannel do
            local clearPlowLevelModifier = g_currentMission.dynamicFoliageLayers[plowLevelNumChannels]
            local desc = getTerrainDetailNumChannels(clearPlowLevelModifier)
            removeFieldMultiModifier:addExecuteSet(0, (DensityMapModifier.new(clearPlowLevelModifier, 0, desc, terrainRootNode)))
        end
        functionData.removeFieldMultiModifier = removeFieldMultiModifier
        FSDensityMapUtil.functionCache.removeFieldArea = functionData
    end
    local terrainRootNode = functionData.removeFieldMultiModifier
    local groundTypeFirstChannel = 1
    local fieldGroundSystem = #polygonVertices
    local groundTypeMapId = 2
    for groundTypeFirstChannel = groundTypeFirstChannel, fieldGroundSystem, groundTypeMapId do
        terrainRootNode:addPolygonPointWorldCoords(polygonVertices[groundTypeFirstChannel], polygonVertices[groundTypeFirstChannel + 1])
    end
    terrainRootNode:execute()
    terrainRootNode:clearPolygonPoints()
end
function FSDensityMapUtil.updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex, _, disableStones)
    local functionData = FSDensityMapUtil.functionCache.updateCultivatorArea
    local missionInfo = g_currentMission.missionInfo
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local cultivatedType = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
        functionData = {
            ["modifier"] = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
            ["modifierAngle"] = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode),
            ["filterCultivatorArea"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.filterCultivatorArea:setValueCompareParams(DensityValueCompareType.EQUAL, cultivatedType)
        functionData.filterField = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.filterField:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.notCultivatedFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.notCultivatedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, cultivatedType)
        functionData.cultivatedType = cultivatedType
        functionData.noFruitFilter = nil
        for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil then
                functionData.noFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                functionData.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
                functionData.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
                break
            end
        end
        FSDensityMapUtil.functionCache.updateCultivatorArea = functionData
    end
    local terrainRootNode = functionData.modifier
    local fieldGroundSystem = functionData.modifierAngle
    local groundTypeMapId = functionData.filterCultivatorArea
    local groundTypeFirstChannel = functionData.filterField
    local groundTypeNumChannels = functionData.notCultivatedFilter
    local groundAngleMapId = functionData.cultivatedType
    local groundAngleFirstChannel = functionData.noFruitFilter
    local groundAngleNumChannels = Utils.getNoNil(createField, true)
    local groundAngleNumChannels = Utils.getNoNil(limitFruitDestructionToField, true)
    FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundAngleNumChannels, false)
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fieldGroundSystem:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local groundAngleNumChannels, cultivatedType, _ = terrainRootNode:executeGet(groundTypeMapId)
    FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
    if groundAngleNumChannels then
        groundTypeFirstChannel = nil
    end
    if missionInfo.stonesEnabled and disableStones ~= true then
        FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1, groundTypeFirstChannel, groundTypeNumChannels)
    end
    if missionInfo.weedsEnabled then
        FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    end
    local _, desc, _ = terrainRootNode:executeSetWithStats(groundAngleMapId, groundTypeFirstChannel, groundAngleFirstChannel)
    fieldGroundSystem:executeSet(angle or 0, groundTypeMapId)
    local _, desc, _ = terrainRootNode:executeGet(groundTypeMapId)
    local changedArea = desc - cultivatedType
    DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return changedArea, _
end
function FSDensityMapUtil.updateDiscHarrowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex)
    local functionData = Utils.getNoNil(createField, true)
    local functionData = Utils.getNoNil(limitFruitDestructionToField, true)
    angle = angle or 0
    local functionData = FSDensityMapUtil.functionCache.updateDiscHarrowArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local stubbleTillageType = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
        local seedbedType = FieldGroundType.getValueByType(FieldGroundType.SEEDBED)
        local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
        functionData = {
            ["modifier"] = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
            ["modifierAngle"] = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode),
            ["fieldFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.seedbedTypeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.seedbedTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, seedbedType)
        functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillageType)
        functionData.notStubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.notStubbleTillageFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, stubbleTillageType)
        functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
        functionData.sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
        functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)
        functionData.multiModifiers = {}
        functionData.fruitFilter = {}
        functionData.preparingModifier = {}
        functionData.preparingFilter = {}
        functionData.noFruitFilter = nil
        functionData.stubbleTillageType = stubbleTillageType
        functionData.seedbedType = seedbedType
        FSDensityMapUtil.functionCache.updateDiscHarrowArea = functionData
    end
    local terrainRootNode = functionData.multiModifiers
    local fieldGroundSystem = terrainRootNode[functionData]
    if fieldGroundSystem == nil then
        local groundTypeFirstChannel = nil
        local groundTypeNumChannels = nil
        if not functionData then
            groundTypeNumChannels = functionData.fieldFilter
        end
        fieldGroundSystem = DensityMapMultiModifier.new()
        terrainRootNode[functionData] = fieldGroundSystem
        for sprayLevelMapId, sprayLevelFirstChannel in pairs(g_fruitTypeManager:getFruitTypes()) do
            if sprayLevelFirstChannel.terrainDataPlaneId ~= nil then
                if functionData.noFruitFilter == nil then
                    functionData.noFruitFilter = DensityMapFilter.new(sprayLevelFirstChannel.terrainDataPlaneId, sprayLevelFirstChannel.startStateChannel, sprayLevelFirstChannel.numStateChannels)
                    functionData.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
                    functionData.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
                end
                if sprayLevelFirstChannel.isCultivationAllowed then
                    local sprayLevelNumChannels = functionData.fruitFilter[sprayLevelMapId]
                    if sprayLevelNumChannels == nil then
                        sprayLevelNumChannels = DensityMapFilter.new(sprayLevelFirstChannel.terrainDataPlaneId, sprayLevelFirstChannel.startStateChannel, sprayLevelFirstChannel.numStateChannels)
                        sprayLevelNumChannels:setValueCompareParams(DensityValueCompareType.GREATER, 1)
                        functionData.fruitFilter[sprayLevelMapId] = sprayLevelNumChannels
                    end
                    sprayLevelNumChannels:setValueCompareParams(DensityValueCompareType.GREATER, 1)
                    fieldGroundSystem:addExecuteSet(functionData.stubbleTillageType, functionData.modifier, sprayLevelNumChannels, groundTypeNumChannels)
                    sprayLevelNumChannels:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, sprayLevelFirstChannel.numGrowthStates)
                    sprayLevelNumChannels:setTypeIndexCompareMode(DensityTypeCompareType.EQUAL)
                    fieldGroundSystem:addExecuteAdd(1, functionData.sprayLevelModifier, functionData.sprayLevelFilter, sprayLevelNumChannels, groundTypeNumChannels)
                    if sprayLevelFirstChannel.terrainDataPlaneIdHaulm ~= nil then
                        local sprayLevelMaxValue = functionData.preparingModifier[sprayLevelMapId]
                        if sprayLevelMaxValue == nil then
                            sprayLevelMaxValue = DensityMapModifier.new(sprayLevelFirstChannel.terrainDataPlaneIdHaulm, sprayLevelFirstChannel.startStateChannelHaulm, sprayLevelFirstChannel.numStateChannelsHaulm)
                            functionData.preparingModifier[sprayLevelMapId] = sprayLevelMaxValue
                        end
                        local preparingFilter = functionData.preparingFilter[sprayLevelMapId]
                        if preparingFilter == nil then
                            preparingFilter = DensityMapFilter.new(sprayLevelFirstChannel.terrainDataPlaneIdHaulm, sprayLevelFirstChannel.startStateChannelHaulm, sprayLevelFirstChannel.numStateChannelsHaulm)
                            preparingFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                            preparingFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
                            functionData.preparingFilter[sprayLevelMapId] = preparingFilter
                        end
                        fieldGroundSystem:addExecuteSet(0, sprayLevelMaxValue, preparingFilter)
                    end
                    if groundTypeFirstChannel == nil then
                        groundTypeFirstChannel = DensityMapModifier.new(sprayLevelFirstChannel.terrainDataPlaneId, sprayLevelFirstChannel.startStateChannel, sprayLevelFirstChannel.numStateChannels)
                    else
                        groundTypeFirstChannel:resetDensityMapAndChannels(sprayLevelFirstChannel.terrainDataPlaneId, sprayLevelFirstChannel.startStateChannel, sprayLevelFirstChannel.numStateChannels)
                    end
                    groundTypeFirstChannel:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
                    sprayLevelNumChannels:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                    if functionData then
                        fieldGroundSystem:addExecuteSet(0, groundTypeFirstChannel, sprayLevelNumChannels, groundTypeNumChannels)
                    else
                        fieldGroundSystem:addExecuteSet(0, groundTypeFirstChannel, sprayLevelNumChannels)
                    end
                end
            end
        end
        local seedbedType = 1
        for seedbedType = seedbedType, #g_currentMission.dynamicFoliageLayers do
            local sprayLevelMapId = g_currentMission.dynamicFoliageLayers[seedbedType]
            local sprayLevelFirstChannel = getTerrainDetailNumChannels(sprayLevelMapId)
            local sprayLevelNumChannels = functionData.dynamicFoliageModifier[sprayLevelMapId]
            if sprayLevelNumChannels == nil then
                sprayLevelNumChannels = DensityMapModifier.new(sprayLevelMapId, 0, sprayLevelFirstChannel, g_terrainNode)
                functionData.dynamicFoliageModifier[sprayLevelMapId] = sprayLevelNumChannels
            end
            fieldGroundSystem:addExecuteSet(0, sprayLevelNumChannels, groundTypeNumChannels)
        end
        FSDensityMapUtil.multiModifierAddResetDisplacement(fieldGroundSystem)
    end
    local groundTypeMapId = functionData.modifier
    local groundTypeFirstChannel = functionData.modifierAngle
    local groundTypeNumChannels = functionData.fieldFilter
    local groundAngleMapId = functionData.seedbedTypeFilter
    local groundAngleFirstChannel = functionData.stubbleTillageFilter
    local groundAngleNumChannels = functionData.notStubbleTillageFilter
    local stubbleTillageType = functionData.seedbedType
    local seedbedType = functionData.noFruitFilter
    if functionData then
        groundTypeNumChannels = nil
    end
    local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = groundTypeMapId:executeGet(groundAngleMapId)
    local sprayLevelMaxValue, preparingFilter, totalArea = groundTypeMapId:executeGet()
    groundTypeMapId:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    groundTypeFirstChannel:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    groundTypeMapId:executeSet(stubbleTillageType, groundAngleNumChannels, groundTypeNumChannels, seedbedType)
    groundTypeFirstChannel:executeSet(angle, groundAngleMapId)
    groundTypeFirstChannel:executeSet(angle, groundAngleFirstChannel)
    local _, areaBeforeStubbleTillage, _ = groundTypeMapId:executeGet(groundAngleFirstChannel)
    fieldGroundSystem:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fieldGroundSystem:execute()
    local _, areaAfterSeedbed, _ = groundTypeMapId:executeGet(groundAngleMapId)
    local _, areaAfterStubbleTillage, _ = groundTypeMapId:executeGet(groundAngleFirstChannel)
    FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
    DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    if g_currentMission.missionInfo.weedsEnabled then
        FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    else
        FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    end
    return areaAfterSeedbed - sprayLevelFirstChannel + (areaAfterStubbleTillage - areaBeforeStubbleTillage), totalArea
end
function FSDensityMapUtil.updatePlowPackerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
    local functionData = FSDensityMapUtil.functionCache.updatePlowPackerArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local cultivatedType = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
        local plowedType = FieldGroundType.getValueByType(FieldGroundType.PLOWED)
        local seedbedType = FieldGroundType.getValueByType(FieldGroundType.SEEDBED)
        functionData = {
            ["modifier"] = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
            ["modifierAngle"] = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode),
            ["filterCultivatorArea"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.filterCultivatorArea:setValueCompareParams(DensityValueCompareType.EQUAL, cultivatedType)
        functionData.filterPlowArea = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.filterPlowArea:setValueCompareParams(DensityValueCompareType.EQUAL, plowedType)
        functionData.filterSeedbedArea = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.filterSeedbedArea:setValueCompareParams(DensityValueCompareType.EQUAL, seedbedType)
        functionData.seedbedType = seedbedType
        FSDensityMapUtil.functionCache.updatePlowPackerArea = functionData
    end
    local terrainRootNode = functionData.modifier
    local fieldGroundSystem = functionData.modifierAngle
    local groundTypeMapId = functionData.filterCultivatorArea
    local groundTypeFirstChannel = functionData.filterPlowArea
    local groundTypeNumChannels = functionData.filterSeedbedArea
    local groundAngleMapId = functionData.seedbedType
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fieldGroundSystem:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local groundAngleFirstChannel, groundAngleNumChannels, cultivatedType = terrainRootNode:executeGet(groundTypeNumChannels)
    terrainRootNode:executeSet(groundAngleMapId, groundTypeFirstChannel)
    local _, areaAfter, _ = terrainRootNode:executeSetWithStats(groundAngleMapId, groundTypeMapId)
    fieldGroundSystem:executeSet(angle or 0, groundTypeNumChannels)
    local _, areaAfter, _ = terrainRootNode:executeGet(groundTypeNumChannels)
    return areaAfter - groundAngleNumChannels, _
end
function FSDensityMapUtil.updateSubsoilerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced)
    if not Platform.gameplay.usePlowCounter then
        return 0, 0
    end
    local functionData = FSDensityMapUtil.functionCache.updateSubsoilerArea
    if functionData == nil then
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
        local plowLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
        functionData = {
            ["modifier"] = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, g_terrainNode),
            ["fieldFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.notMaxPlowLevelFilter = DensityMapFilter.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels)
        functionData.notMaxPlowLevelFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, plowLevelMaxValue)
        functionData.plowLevelMaxValue = plowLevelMaxValue
        FSDensityMapUtil.functionCache.updateSubsoilerArea = functionData
    end
    local terrainRootNode = functionData.modifier
    local fieldGroundSystem = functionData.fieldFilter
    local groundTypeMapId = functionData.notMaxPlowLevelFilter
    local groundTypeFirstChannel = functionData.plowLevelMaxValue
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    if forced then
        fieldGroundSystem = nil
    end
    if g_currentMission.missionInfo.stonesEnabled then
        FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 2, fieldGroundSystem, groundTypeMapId)
    end
    FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local groundTypeNumChannels, plowLevelMapId, plowLevelFirstChannel = terrainRootNode:executeSetWithStats(groundTypeFirstChannel, fieldGroundSystem)
    return plowLevelMapId, plowLevelFirstChannel
end
function FSDensityMapUtil.updatePlowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, resetPlowLevel, stonesDisabled)
    local functionData = FSDensityMapUtil.functionCache.updatePlowArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local plowedType = FieldGroundType.getValueByType(FieldGroundType.PLOWED)
        functionData = {
            ["groundTypeModifier"] = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
            ["angleModifier"] = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode),
            ["plowStateFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.plowStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, plowedType)
        functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.notPlowedFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.notPlowedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, plowedType)
        functionData.plowedType = plowedType
        if Platform.gameplay.usePlowCounter then
            local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
            functionData.levelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
            functionData.plowLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
        end
        functionData.noFruitFilter = nil
        for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil then
                functionData.noFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                functionData.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
                functionData.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
                break
            end
        end
        FSDensityMapUtil.functionCache.updatePlowArea = functionData
    end
    local terrainRootNode = functionData.groundTypeModifier
    local fieldGroundSystem = functionData.angleModifier
    local groundTypeMapId = functionData.levelModifier
    local groundTypeFirstChannel = functionData.plowStateFilter
    local groundTypeNumChannels = functionData.fieldFilter
    local groundAngleMapId = functionData.notPlowedFilter
    local groundAngleFirstChannel = functionData.plowLevelMaxValue
    local groundAngleNumChannels = functionData.plowedType
    local plowedType = functionData.noFruitFilter
    local plowLevelMapId = Utils.getNoNil(createField, true)
    local plowLevelMapId = Utils.getNoNil(limitFruitDestructionToField, true)
    local plowLevelMapId = Utils.getNoNil(resetPlowLevel, true)
    FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, plowLevelMapId, false)
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fieldGroundSystem:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = terrainRootNode:executeGet(groundTypeFirstChannel)
    if plowLevelMapId then
        groundTypeNumChannels = nil
        FSDensityMapUtil.clearDecoArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    end
    if g_currentMission.missionInfo.stonesEnabled and stonesDisabled ~= true then
        FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1, groundTypeNumChannels, groundAngleMapId)
    end
    local desc, areaAfter, _ = terrainRootNode:executeSetWithStats(groundAngleNumChannels, groundTypeNumChannels, plowedType)
    if plowLevelMapId and groundTypeMapId ~= nil then
        groundTypeMapId:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        groundTypeMapId:executeSet(groundAngleFirstChannel, groundTypeNumChannels)
    end
    fieldGroundSystem:executeSet(angle or 0, groundTypeNumChannels)
    FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true)
    if g_currentMission.missionInfo.weedsEnabled then
        FSDensityMapUtil.setWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundTypeFirstChannel)
    end
    local desc, areaAfter, _ = terrainRootNode:executeGet(groundTypeFirstChannel)
    return areaAfter - plowLevelFirstChannel, _
end
function FSDensityMapUtil.updatePlowShareArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, clearFoliageOffset)
    local functionData = FSDensityMapUtil.functionCache.updatePlowShareArea
    if functionData == nil then
        functionData = {}
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local displacementMapId, displacementFirstChannel, displacementNumChannels = fieldGroundSystem:getDisplacementData()
        functionData.modifier = DensityMapModifier.new(displacementMapId, displacementFirstChannel, displacementNumChannels, terrainRootNode)
        functionData.texture = DPUTexture.new("data/maps/textures/terrain/ground/groundType_plowShare_displacement.png")
        local displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels = fieldGroundSystem:getDisplacementCustomFlagData()
        functionData.modifierCustom = DensityMapModifier.new(displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels, terrainRootNode)
        functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        FSDensityMapUtil.functionCache.updatePlowShareArea = functionData
    end
    local terrainRootNode = functionData.modifier
    local fieldGroundSystem = functionData.modifierCustom
    local groundTypeMapId = functionData.fieldFilter
    local groundTypeFirstChannel = functionData.texture
    if createField then
        groundTypeMapId = nil
    end
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fieldGroundSystem:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    terrainRootNode:executeSet(0, groundTypeMapId)
    fieldGroundSystem:executeSet(1, groundTypeMapId)
    local groundTypeNumChannels, displacementMapId, displacementFirstChannel, displacementNumChannels, displacementCustomFlagMapId, displacementCustomFlagFirstChannel = MathUtil.getWorldParallelogramOffset(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, clearFoliageOffset)
    FSDensityMapUtil.updateDestroyCommonArea(groundTypeNumChannels, displacementMapId, displacementFirstChannel, displacementNumChannels, displacementCustomFlagMapId, displacementCustomFlagFirstChannel, limitFruitDestructionToField, nil, false)
end
function FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, filter1, filter2)
    local functionData = FSDensityMapUtil.functionCache.resetDisplacementArea
    local area = (functionData == nil and {
        ["area"] = DensityMapParallelogram.new()
    } or functionData).area
    area:updateFromWorldPositions(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    FSDensityMapUtil.resetDisplacement(area, filter1, filter2)
end
function FSDensityMapUtil.multiModifierAddResetDisplacement(multiModifier, filter1, filter2)
    local terrainRootNode = g_terrainNode
    local fieldGroundSystem = g_currentMission.fieldGroundSystem
    local displacementMapId, displacementFirstChannel, displacementNumChannels = fieldGroundSystem:getDisplacementData()
    local modifier = DensityMapModifier.new(displacementMapId, displacementFirstChannel, displacementNumChannels, terrainRootNode)
    local resetValue = fieldGroundSystem:getDisplacementResetValue()
    local displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels = fieldGroundSystem:getDisplacementCustomFlagData()
    local modifierCustom = DensityMapModifier.new(displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels, terrainRootNode)
    multiModifier:addExecuteSet(resetValue, modifier, filter1, filter2)
    multiModifier:addExecuteSet(0, modifierCustom, filter1, filter2)
end
function FSDensityMapUtil.resetDisplacement(densityMapArea, filter1, filter2)
    local functionData = FSDensityMapUtil.functionCache.resetDisplacement
    if functionData == nil then
        functionData = {}
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local displacementMapId, displacementFirstChannel, displacementNumChannels = fieldGroundSystem:getDisplacementData()
        functionData.modifier = DensityMapModifier.new(displacementMapId, displacementFirstChannel, displacementNumChannels, terrainRootNode)
        functionData.resetValue = fieldGroundSystem:getDisplacementResetValue()
        local displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels = fieldGroundSystem:getDisplacementCustomFlagData()
        functionData.modifierCustom = DensityMapModifier.new(displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels, terrainRootNode)
        FSDensityMapUtil.functionCache.resetDisplacement = functionData
    end
    local terrainRootNode = functionData.modifier
    local fieldGroundSystem = functionData.modifierCustom
    local displacementMapId = functionData.resetValue
    densityMapArea:applyToModifier(terrainRootNode)
    densityMapArea:applyToModifier(fieldGroundSystem)
    terrainRootNode:executeSet(displacementMapId, filter1, filter2)
    fieldGroundSystem:executeSet(0, filter1, filter2)
end
function FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, onlyOnFields, deleteAll, resetDisplacement)
    local functionData = Utils.getNoNil(onlyOnFields, false)
    local functionData = Utils.getNoNil(deleteAll, false)
    local functionData = Utils.getNoNil(resetDisplacement, true)
    local functionData = FSDensityMapUtil.functionCache.updateDestroyCommonArea
    if functionData == nil then
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
        functionData = {
            ["fieldFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, g_terrainNode)
        functionData.sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
        functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)
        functionData.dynamicFoliageModifier = {}
        functionData.fruitFilter = {}
        functionData.preparingModifier = {}
        functionData.preparingFilter = {}
        functionData.multiModifiers = {}
        FSDensityMapUtil.functionCache.updateDestroyCommonArea = functionData
    end
    local terrainRootNode = functionData.multiModifiers
    if terrainRootNode[functionData] == nil then
        terrainRootNode[functionData] = {}
    end
    if terrainRootNode[functionData][functionData] == nil then
        terrainRootNode[functionData][functionData] = {}
    end
    local fieldGroundSystem = terrainRootNode[functionData][functionData][functionData]
    if fieldGroundSystem == nil then
        local sprayLevelMapId = nil
        fieldGroundSystem = DensityMapMultiModifier.new()
        terrainRootNode[functionData][functionData][functionData] = fieldGroundSystem
        local sprayLevelFirstChannel = nil
        if functionData then
            sprayLevelFirstChannel = functionData.fieldFilter
        end
        for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil then
                local fruitFilter = functionData.fruitFilter[index]
                if fruitFilter == nil then
                    fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                    fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
                    functionData.fruitFilter[index] = fruitFilter
                end
                fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
                fruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.EQUAL)
                fieldGroundSystem:addExecuteAdd(1, functionData.sprayLevelModifier, functionData.sprayLevelFilter, fruitFilter, sprayLevelFirstChannel)
                if desc.terrainDataPlaneIdHaulm ~= nil then
                    local preparingModifier = functionData.preparingModifier[index]
                    if preparingModifier == nil then
                        preparingModifier = DensityMapModifier.new(desc.terrainDataPlaneIdHaulm, desc.startStateChannelHaulm, desc.numStateChannelsHaulm)
                        functionData.preparingModifier[index] = preparingModifier
                    end
                    local preparingFilter = functionData.preparingFilter[index]
                    if preparingFilter == nil then
                        preparingFilter = DensityMapFilter.new(desc.terrainDataPlaneIdHaulm, desc.startStateChannelHaulm, desc.numStateChannelsHaulm)
                        preparingFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                        preparingFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
                        functionData.preparingFilter[index] = preparingFilter
                    end
                    fieldGroundSystem:addExecuteSet(0, preparingModifier, preparingFilter)
                end
                if functionData or desc.isCultivationAllowed then
                    if sprayLevelMapId == nil then
                        sprayLevelMapId = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                    else
                        sprayLevelMapId:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                    end
                    sprayLevelMapId:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
                    fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                    fieldGroundSystem:addExecuteSet(0, sprayLevelMapId, fruitFilter, sprayLevelFirstChannel)
                end
            end
        end
        local i = 1
        for i = i, #g_currentMission.dynamicFoliageLayers do
            local index = g_currentMission.dynamicFoliageLayers[i]
            local desc = getTerrainDetailNumChannels(index)
            local fruitFilter = functionData.dynamicFoliageModifier[index]
            if fruitFilter == nil then
                fruitFilter = DensityMapModifier.new(index, 0, desc, g_terrainNode)
                functionData.dynamicFoliageModifier[index] = fruitFilter
            end
            fieldGroundSystem:addExecuteSet(0, fruitFilter, sprayLevelFirstChannel)
        end
        if functionData then
            FSDensityMapUtil.multiModifierAddResetDisplacement(fieldGroundSystem)
        end
    end
    fieldGroundSystem:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fieldGroundSystem:execute()
    FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end
function FSDensityMapUtil.updateWheelDestructionArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local functionData = FSDensityMapUtil.functionCache.updateWheelDestructionArea
    if functionData == nil then
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        functionData = {
            ["modifier"] = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, g_terrainNode),
            ["multiModifier"] = nil,
            ["filter1"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels),
            ["fieldFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        FSDensityMapUtil.functionCache.updateWheelDestructionArea = functionData
    end
    local terrainRootNode = functionData.modifier
    local fieldGroundSystem = functionData.multiModifier
    local groundTypeMapId = functionData.filter1
    local groundTypeFirstChannel = functionData.fieldFilter
    g_currentMission.growthSystem:setIgnoreDensityChanges(true)
    if fieldGroundSystem == nil then
        fieldGroundSystem = DensityMapMultiModifier.new()
        functionData.multiModifier = fieldGroundSystem
        for sprayTypeNumChannels, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil and desc.minWheelDestructionState ~= nil then
                terrainRootNode:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                groundTypeMapId:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                groundTypeMapId:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minWheelDestructionState, desc.maxWheelDestructionState)
                fieldGroundSystem:addExecuteSet(desc.wheelDestructionState, terrainRootNode, groundTypeMapId, groundTypeFirstChannel)
            end
        end
        local sprayTypeFirstChannel = 1
        for sprayTypeFirstChannel = sprayTypeFirstChannel, #g_currentMission.dynamicFoliageLayers do
            local sprayTypeNumChannels = g_currentMission.dynamicFoliageLayers[sprayTypeFirstChannel]
            terrainRootNode:resetDensityMapAndChannels(sprayTypeNumChannels, 0, (getTerrainDetailNumChannels(sprayTypeNumChannels)))
            fieldGroundSystem:addExecuteSet(0, terrainRootNode)
        end
    end
    fieldGroundSystem:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fieldGroundSystem:execute()
    FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    g_currentMission.growthSystem:setIgnoreDensityChanges(false)
end
function FSDensityMapUtil.setGroundTypeLayerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
    local functionData = FSDensityMapUtil.functionCache.setGroundTypeLayerArea
    if functionData == nil then
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        functionData = {
            ["groundLayerModifier"] = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, g_terrainNode),
            ["sprayTypeFilter"] = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels),
            ["fieldFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        FSDensityMapUtil.functionCache.setGroundTypeLayerArea = functionData
    end
    local terrainRootNode = functionData.groundLayerModifier
    local fieldGroundSystem = functionData.sprayTypeFilter
    local groundTypeMapId = functionData.fieldFilter
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fieldGroundSystem:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, value - 1)
    local groundTypeFirstChannel, groundTypeNumChannels, sprayTypeMapId = terrainRootNode:executeSetWithStats(value, fieldGroundSystem, groundTypeMapId)
    fieldGroundSystem:setValueCompareParams(DensityValueCompareType.GREATER, value)
    local sprayTypeFirstChannel, sprayTypeNumChannels, totalNumPixels2 = terrainRootNode:executeSetWithStats(value, fieldGroundSystem, groundTypeMapId)
    return groundTypeNumChannels + sprayTypeNumChannels, sprayTypeMapId + totalNumPixels2
end
function FSDensityMapUtil.setStubbleShredLevelArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
    if Platform.gameplay.useStubbleShred then
        local functionData = FSDensityMapUtil.functionCache.setStubbleShredArea
        if functionData == nil then
            local fieldGroundSystem = g_currentMission.fieldGroundSystem
            functionData = {}
            local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
            functionData.stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, g_terrainNode)
            local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
            functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
            functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
            FSDensityMapUtil.functionCache.setStubbleShredArea = functionData
        end
        local terrainRootNode = functionData.stubbleShredModifier
        local fieldGroundSystem = functionData.fieldFilter
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = terrainRootNode:executeSetWithStats(value, fieldGroundSystem)
        return stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels
    end
end
function FSDensityMapUtil.updateSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayTypeIndex, sprayAmount)
    local numPixels = 0
    local totalNumPixels = 0
    local desc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
    if desc ~= nil then
        if desc.isLime then
            local numPixels, totalNumPixels = FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.sprayGroundType)
            return numPixels, totalNumPixels
        end
        if desc.isFertilizer then
            local numPixels, totalNumPixels = FSDensityMapUtil.updateFertilizerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.sprayGroundType, sprayAmount)
            return numPixels, totalNumPixels
        end
        if desc.isHerbicide then
            numPixels, totalNumPixels = FSDensityMapUtil.updateHerbicideArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.sprayGroundType)
        end
    end
    return numPixels, totalNumPixels
end
function FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex, customFilter)
    local functionData = FSDensityMapUtil.functionCache.removeSprayArea
    if functionData == nil then
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        functionData = {
            ["modifier"] = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, g_terrainNode),
            ["filter"] = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
        }
        FSDensityMapUtil.functionCache.removeSprayArea = functionData
    end
    local terrainRootNode = functionData.modifier
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    if blockedSprayTypeIndex == nil then
        functionData.filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        terrainRootNode:executeSet(0, fieldGroundSystem, customFilter)
    else
        local sprayTypeMapId = g_sprayTypeManager:getSprayTypeByIndex(blockedSprayTypeIndex)
        if sprayTypeMapId.sprayGroundType > 0 then
            fieldGroundSystem:setValueCompareParams(DensityValueCompareType.GREATER, sprayTypeMapId.sprayGroundType)
            terrainRootNode:executeSet(0, fieldGroundSystem, customFilter)
            if sprayTypeMapId.sprayGroundType > 0 then
                fieldGroundSystem:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayTypeMapId.sprayGroundType - 1)
                terrainRootNode:executeSet(0, fieldGroundSystem, customFilter)
                return
            end
        end
    end
end
function FSDensityMapUtil.updateFertilizerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayType, sprayAmount)
    local functionData = FSDensityMapUtil.functionCache.updateFertilizerArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        local sprayTypeMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_TYPE)
        functionData = {
            ["sprayModifier"] = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
            ["sprayLevelModifier"] = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode),
            ["growingFruitFilters"] = {}
        }
        for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil then
                local growingFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                growingFruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState)
                table.insert(functionData.growingFruitFilters, growingFruitFilter)
            end
        end
        functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
        functionData.sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        functionData.outsideFieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.outsideFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        functionData.maskFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
        functionData.maskFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)
        functionData.maskValue = sprayTypeMaxValue
        FSDensityMapUtil.functionCache.updateFertilizerArea = functionData
    end
    local terrainRootNode = functionData.sprayModifier
    local fieldGroundSystem = functionData.sprayLevelModifier
    local sprayLevelMapId = functionData.sprayTypeFilter
    local sprayLevelFirstChannel = functionData.outsideFieldFilter
    local sprayLevelNumChannels = functionData.growingFruitFilters
    local groundTypeMapId = functionData.maskFilter
    local groundTypeFirstChannel = functionData.maskValue
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fieldGroundSystem:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    sprayLevelMapId:setValueCompareParams(DensityValueCompareType.NOTEQUAL, sprayType)
    terrainRootNode:executeSet(groundTypeFirstChannel, sprayLevelMapId, groundTypeMapId)
    sprayLevelMapId:setValueCompareParams(DensityValueCompareType.EQUAL, groundTypeFirstChannel)
    terrainRootNode:executeSet(0, sprayLevelMapId, sprayLevelFirstChannel)
    local sprayTypeMapId = 1
    local groundTypeNumChannels = #sprayLevelNumChannels
    local sprayLevelMaxValue = 1
    for sprayTypeMapId = sprayTypeMapId, groundTypeNumChannels, sprayLevelMaxValue do
        terrainRootNode:executeSet(0, sprayLevelMapId, sprayLevelNumChannels[sprayTypeMapId])
    end
    local sprayLevelMaxValue = nil
    local sprayTypeMapId = nil
    local sprayTypeMaxValue = 1
    local sprayTypeFirstChannel = math.max(sprayAmount or 1, 1)
    local sprayTypeNumChannels = 1
    for sprayTypeMaxValue = sprayTypeMaxValue, sprayTypeFirstChannel, sprayTypeNumChannels do
        local groundTypeNumChannels, groundTypeNumChannels
        groundTypeNumChannels, groundTypeNumChannels, sprayLevelMaxValue, sprayTypeMapId = fieldGroundSystem:executeAddWithStats(1, sprayLevelMapId, groundTypeMapId)
    end
    terrainRootNode:executeSet(sprayType, sprayLevelMapId)
    return sprayLevelMaxValue, sprayTypeMapId
end
function FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
    local functionData = FSDensityMapUtil.functionCache.updateLimeArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
        local limeLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
        local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
        local modifierSprayType = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
        local modifierLimeLevel = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
        local filterLimeLevel = DensityMapFilter.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels)
        filterLimeLevel:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, limeLevelMaxValue - 1)
        local filterLimeLevelMax = DensityMapFilter.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels)
        filterLimeLevelMax:setValueCompareParams(DensityValueCompareType.EQUAL, limeLevelMaxValue)
        local fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        local groundFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        groundFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
        local chopperTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
        local startChopperValue = FieldChopperType.getValueByType(FieldChopperType.CHOPPER_STRAW)
        local endChopperValue = FieldChopperType.getValueByType(FieldChopperType.CHOPPER_MAIZE)
        chopperTypeFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, startChopperValue, endChopperValue)
        functionData = {
            ["multiModifier"] = DensityMapMultiModifier.new(),
            ["modifierLimeLevel"] = modifierLimeLevel,
            ["filterLimeLevelMax"] = filterLimeLevelMax
        }
        local multiModifier = functionData.multiModifier
        local fruitFilter = nil
        local noFruitFilter = nil
        for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil then
                if fruitFilter == nil then
                    fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                    noFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                    noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
                else
                    fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                    noFruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                end
                fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
                multiModifier:addExecuteSet(groundType, modifierSprayType, fieldFilter, fruitFilter)
                multiModifier:addExecuteSet(limeLevelMaxValue, modifierLimeLevel, fieldFilter, fruitFilter, filterLimeLevel)
                fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, desc.maxHarvestingGrowthState)
                multiModifier:addExecuteSet(groundType, modifierSprayType, fieldFilter, fruitFilter)
                multiModifier:addExecuteSet(limeLevelMaxValue, modifierLimeLevel, fieldFilter, fruitFilter, filterLimeLevel)
                noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
                multiModifier:addExecuteSet(groundType, modifierSprayType, fieldFilter, noFruitFilter)
                multiModifier:addExecuteSet(limeLevelMaxValue, modifierLimeLevel, fieldFilter, noFruitFilter, filterLimeLevel)
            end
        end
        multiModifier:addExecuteSet(groundType, modifierSprayType, groundFilter)
        multiModifier:addExecuteSet(limeLevelMaxValue, modifierLimeLevel, groundFilter, filterLimeLevel)
        multiModifier:addExecuteSet(groundType, modifierSprayType, chopperTypeFilter)
        multiModifier:addExecuteSet(limeLevelMaxValue, modifierLimeLevel, chopperTypeFilter, filterLimeLevel)
        FSDensityMapUtil.functionCache.updateLimeArea = functionData
    end
    local terrainRootNode = functionData.multiModifier
    local fieldGroundSystem = functionData.modifierLimeLevel
    local groundTypeMapId = functionData.filterLimeLevelMax
    fieldGroundSystem:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local groundTypeFirstChannel, groundTypeNumChannels, sprayTypeMapId = fieldGroundSystem:executeGet(groundTypeMapId)
    terrainRootNode:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    terrainRootNode:execute()
    local sprayTypeFirstChannel, sprayTypeNumChannels, limeLevelMapId = fieldGroundSystem:executeGet(groundTypeMapId)
    return sprayTypeNumChannels - groundTypeNumChannels, sprayTypeMapId
end
function FSDensityMapUtil.updateHerbicideArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
    local weedSystem = g_currentMission.weedSystem
    if not weedSystem:getMapHasWeed() then
        return 0, 0
    end
    local functionData = FSDensityMapUtil.functionCache.updateHerbicideArea
    if functionData == nil then
        FSDensityMapUtil.functionCache.updateHerbicideArea = {
            ["numChangedPixels"] = {},
            ["totalNumPixels"] = {},
            ["multiModifiers"] = {}
        }
    end
    local label = "sprayedTotal"
    local multiModifier = groundType and functionData.multiModifiers[groundType] or functionData.defaultMultiModifier
    if multiModifier == nil then
        multiModifier = DensityMapMultiModifier.new()
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
        local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
        local replacementData = weedSystem:getHerbicideReplacements()
        local replacements = replacementData.weed.replacements
        if replacementData.custom ~= nil then
            for _, data in ipairs(replacementData.custom) do
                local desc = data.fruitType
                if desc.terrainDataPlaneId ~= nil then
                    local fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
                    local sourceStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                    for sourceState, targetState in pairs(replacements) do
                        sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
                        multiModifier:addExecuteSetWithStats(label, targetState, fruitModifier, sourceStateFilter)
                    end
                end
            end
        end
        local sprayModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
        local weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
        local groundFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        groundFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
        for fruitModifier, sourceStateFilter in pairs(replacements) do
            local weedFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
            weedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, fruitModifier)
            for targetState, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
                if desc.terrainDataPlaneId ~= nil then
                    local fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                    fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, desc.minHarvestingGrowthState - 1)
                    multiModifier:addExecuteSet(groundType, sprayModifier, fruitFilter, weedFilter)
                    multiModifier:addExecuteSetWithStats(label, sourceStateFilter, weedModifier, fruitFilter, weedFilter)
                    local cutFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                    cutFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.cutState + 1)
                    multiModifier:addExecuteSet(groundType, sprayModifier, cutFruitFilter, weedFilter)
                    multiModifier:addExecuteSetWithStats(label, sourceStateFilter, weedModifier, cutFruitFilter, weedFilter)
                    if desc.wheelDestructionState ~= nil and desc.wheelDestructionState ~= desc.cutState + 1 then
                        local wheelDestructionFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        wheelDestructionFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.wheelDestructionState)
                        multiModifier:addExecuteSet(groundType, sprayModifier, wheelDestructionFruitFilter, weedFilter)
                        multiModifier:addExecuteSetWithStats(label, sourceStateFilter, weedModifier, wheelDestructionFruitFilter, weedFilter)
                    end
                end
            end
            multiModifier:addExecuteSet(groundType, sprayModifier, groundFilter, weedFilter)
            multiModifier:addExecuteSetWithStats(label, sourceStateFilter, weedModifier, groundFilter, weedFilter)
        end
        if groundType then
            functionData.multiModifiers[groundType] = multiModifier
        else
            functionData.defaultMultiModifier = multiModifier
        end
    end
    local terrainRootNode = functionData.numChangedPixels
    local fieldGroundSystem = functionData.totalNumPixels
    multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    multiModifier:resetStats()
    multiModifier:execute(nil, terrainRootNode, fieldGroundSystem)
    return terrainRootNode.sprayedTotal + terrainRootNode.sprayed, fieldGroundSystem.sprayedTotal or 0
end
function FSDensityMapUtil.updateWeederArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, isHoeWeeder)
    local weedSystem = g_currentMission.weedSystem
    local areaBefore = 0
    local areaAfter = 0
    if weedSystem:getMapHasWeed() then
        local functionData = FSDensityMapUtil.functionCache.updateWeederArea
        if functionData == nil then
            FSDensityMapUtil.functionCache.updateWeederArea = {}
        end
        local weederData = functionData[isHoeWeeder]
        if weederData == nil then
            local terrainRootNode = g_terrainNode
            local fieldGroundSystem = g_currentMission.fieldGroundSystem
            local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
            local replacementData = weedSystem:getWeederReplacements(isHoeWeeder)
            local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
            local firstSowableState, lastSowableState = fieldGroundSystem:getSowableRange()
            weederData = {
                ["weedModifier"] = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode),
                ["allWeedFilter"] = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
            }
            weederData.allWeedFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
            weederData.multiModifierGrowing = DensityMapMultiModifier.new()
            weederData.multiModifierSowable = DensityMapMultiModifier.new()
            local fruitStateFilter = nil
            local sourceStateFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
            local sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
            sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableState, lastSowableState)
            for sourceState, targetState in pairs(replacementData.weed.replacements) do
                sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
                for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
                    if desc.terrainDataPlaneId ~= nil then
                        if fruitStateFilter == nil then
                            fruitStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        else
                            fruitStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        end
                        local maxWeederState = desc.maxWeederState
                        if isHoeWeeder then
                            maxWeederState = desc.maxWeederHoeState
                        end
                        fruitStateFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, maxWeederState)
                        weederData.multiModifierGrowing:addExecuteSet(targetState, weederData.weedModifier, sourceStateFilter, fruitStateFilter)
                        fruitStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.cutState)
                        weederData.multiModifierGrowing:addExecuteSet(targetState, weederData.weedModifier, sourceStateFilter, fruitStateFilter)
                    end
                end
                weederData.multiModifierSowable:addExecuteSet(targetState, weederData.weedModifier, sourceStateFilter, sowableFilter)
            end
            if replacementData.custom ~= nil then
                weederData.multiModifierCustom = DensityMapMultiModifier.new()
                local fruitModifier = nil
                for targetState, data in ipairs(replacementData.custom) do
                    local desc = data.fruitType
                    if desc.terrainDataPlaneId ~= nil then
                        if fruitModifier == nil then
                            fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
                        else
                            fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        end
                        sourceStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        for maxWeederState, targetState in pairs(data.replacements) do
                            sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, maxWeederState)
                            weederData.multiModifierCustom:addExecuteSet(targetState, fruitModifier, sourceStateFilter)
                        end
                    end
                end
            end
            FSDensityMapUtil.functionCache.updateWeederArea[isHoeWeeder] = weederData
        end
        local terrainRootNode = weederData.weedModifier
        local fieldGroundSystem = weederData.allWeedFilter
        local weedMapId = weederData.multiModifierGrowing
        local weedFirstChannel = weederData.multiModifierSowable
        local weedNumChannels = weederData.multiModifierCustom
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local replacementData, groundTypeFirstChannel
        replacementData, areaBefore, groundTypeFirstChannel = terrainRootNode:executeGet(fieldGroundSystem)
        weedMapId:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        weedMapId:execute()
        weedFirstChannel:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        weedFirstChannel:execute()
        if weedNumChannels ~= nil then
            weedNumChannels:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
            weedNumChannels:execute()
        end
        local replacementData, groundTypeFirstChannel
        replacementData, areaAfter, groundTypeFirstChannel = terrainRootNode:executeGet(fieldGroundSystem)
    end
    DensityMapHeightUtil.removeFromGroundByArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, FillType.GRASS_WINDROW)
    DensityMapHeightUtil.removeFromGroundByArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, FillType.DRYGRASS_WINDROW)
    return areaBefore - areaAfter
end
function FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local numPixels = 0
    local totalNumPixels = 0
    local weedSystem = g_currentMission.weedSystem
    if weedSystem:getMapHasWeed() then
        local functionData = FSDensityMapUtil.functionCache.removeWeedArea
        if functionData == nil then
            local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
            functionData = {
                ["weedModifier"] = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode)
            }
            FSDensityMapUtil.functionCache.removeWeedArea = functionData
        end
        local terrainRootNode = functionData.weedModifier
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local weedFirstChannel
        weedFirstChannel, numPixels, totalNumPixels = terrainRootNode:executeSetWithStats(0)
    end
    return numPixels, totalNumPixels
end
function FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local weedSystem = g_currentMission.weedSystem
    if weedSystem:getMapHasWeed() then
        local functionData = FSDensityMapUtil.functionCache.setSparseWeedArea
        if functionData == nil then
            local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
            local infoId, _, _ = weedSystem:getInfoLayerData()
            local blockingStateValue, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
            local sparseState = weedSystem:getSparseStartState()
            local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
            functionData = {
                ["weedModifier"] = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode),
                ["fieldFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
            }
            functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
            functionData.notWeedBlockedFilter = DensityMapFilter.new(infoId, blockingStateFirstChannel, blockingStateNumChannels)
            functionData.notWeedBlockedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, blockingStateValue)
            functionData.sparseState = sparseState
            FSDensityMapUtil.functionCache.setSparseWeedArea = functionData
        end
        local terrainRootNode = functionData.weedModifier
        local fieldGroundSystem = functionData.fieldFilter
        local weedMapId = functionData.notWeedBlockedFilter
        local weedFirstChannel = functionData.sparseState
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        terrainRootNode:executeSet(weedFirstChannel, fieldGroundSystem, weedMapId)
    end
end
function FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local weedSystem = g_currentMission.weedSystem
    if weedSystem:getMapHasWeed() then
        local functionData = FSDensityMapUtil.functionCache.setSowingWeedArea
        if functionData == nil then
            local fieldGroundSystem = g_currentMission.fieldGroundSystem
            local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
            local infoId, _, _ = weedSystem:getInfoLayerData()
            local blockingStateValue, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
            local sparseState = weedSystem:getSparseStartState()
            local denseState = weedSystem:getDenseStartState()
            local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
            local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
            local stubbleTillageValue = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
            functionData = {
                ["weedModifier"] = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode),
                ["notBlockedFilter"] = DensityMapFilter.new(infoId, blockingStateFirstChannel, blockingStateNumChannels)
            }
            functionData.notBlockedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, blockingStateValue)
            functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
            functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillageValue)
            functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
            functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
            functionData.sparseState = sparseState
            functionData.denseState = denseState
            FSDensityMapUtil.functionCache.setSowingWeedArea = functionData
        end
        local terrainRootNode = functionData.weedModifier
        local fieldGroundSystem = functionData.stubbleTillageFilter
        local weedMapId = functionData.notBlockedFilter
        local weedFirstChannel = functionData.sowableFilter
        local weedNumChannels = functionData.denseState
        local infoId = functionData.sparseState
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        terrainRootNode:executeSet(infoId, weedFirstChannel, weedMapId)
        terrainRootNode:executeSet(weedNumChannels, fieldGroundSystem, weedMapId)
    end
end
function FSDensityMapUtil.setWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, customFilter1, customFilter2)
    local weedSystem = g_currentMission.weedSystem
    if weedSystem:getMapHasWeed() then
        local functionData = FSDensityMapUtil.functionCache.setWeedBlockingState
        if functionData == nil then
            local infoId, _, _ = weedSystem:getInfoLayerData()
            local blockingValue, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
            functionData = {
                ["weedInfoModifier"] = DensityMapModifier.new(infoId, blockingStateFirstChannel, blockingStateNumChannels, g_terrainNode),
                ["blockingValue"] = blockingValue
            }
            FSDensityMapUtil.functionCache.setWeedBlockingState = functionData
        end
        local terrainRootNode = functionData.weedInfoModifier
        local infoId = functionData.blockingValue
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        terrainRootNode:executeSet(infoId, customFilter1, customFilter2)
    end
end
function FSDensityMapUtil.removeWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local weedSystem = g_currentMission.weedSystem
    if weedSystem:getMapHasWeed() then
        local functionData = FSDensityMapUtil.functionCache.removeWeedBlockingState
        if functionData == nil then
            local infoId, _, _ = weedSystem:getInfoLayerData()
            local _, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
            functionData = {
                ["weedInfoModifier"] = DensityMapModifier.new(infoId, blockingStateFirstChannel, blockingStateNumChannels, g_terrainNode)
            }
            FSDensityMapUtil.functionCache.removeWeedBlockingState = functionData
        end
        local terrainRootNode = functionData.weedInfoModifier
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        terrainRootNode:executeSet(0)
    end
end
function FSDensityMapUtil.updateMulcherArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local functionData = FSDensityMapUtil.functionCache.updateMulcherArea
    if functionData == nil then
        local mission = g_currentMission
        local fieldGroundSystem = mission.fieldGroundSystem
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        functionData = {
            ["multiModifier"] = DensityMapMultiModifier.new()
        }
        local stubbleShredModifier = nil
        if Platform.gameplay.useStubbleShred then
            local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
            stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, g_terrainNode)
        end
        local stubbleShredLevelMapId = nil
        if sprayTypeMapId ~= nil then
            stubbleShredLevelMapId = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
        end
        local stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local fruitFilter = DensityMapFilter.new(stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, groundTypeNumChannels)
        local mulchedStateFilter = DensityMapFilter.new(stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, groundTypeNumChannels)
        local fruitModifier = nil
        for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.isCultivationAllowed and desc.terrainDataPlaneId ~= nil then
                fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.cutState)
                mulchedStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                mulchedStateFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, desc.mulchedState or 0)
                if desc.mulcherChopperType ~= nil and stubbleShredLevelMapId ~= nil then
                    local chopperTypeValue = FieldChopperType.getValueByType(desc.mulcherChopperType)
                    if chopperTypeValue ~= nil then
                        functionData.multiModifier:addExecuteSetWithStats("", chopperTypeValue, stubbleShredLevelMapId, fruitFilter, mulchedStateFilter)
                    end
                end
                if stubbleShredModifier ~= nil then
                    multiModifier:addExecuteAddWithStats("", 1, stubbleShredModifier, fruitFilter, mulchedStateFilter)
                end
                if desc.terrainDataPlaneIdHaulm ~= nil then
                    local chopperTypeValue = DensityMapModifier.new(desc.terrainDataPlaneIdHaulm, desc.startStateChannelHaulm, desc.numStateChannelsHaulm)
                    local preparingFilter = DensityMapFilter.new(desc.terrainDataPlaneIdHaulm, desc.startStateChannelHaulm, desc.numStateChannelsHaulm)
                    preparingFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                    preparingFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
                    multiModifier:addExecuteSet(0, chopperTypeValue, preparingFilter)
                end
                if fruitModifier == nil then
                    fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                else
                    fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                end
                if (desc.mulchedState or 0) == 0 then
                    fruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
                end
                fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                multiModifier:addExecuteSetWithStats("", desc.mulchedState or 0, fruitModifier, fruitFilter, mulchedStateFilter)
            end
        end
        local weedSystem = mission.weedSystem
        if weedSystem ~= nil then
            local weedMapId, weedFirstChannel, _ = weedSystem:getDensityMapData()
            local desc = DensityMapFilter.new(weedMapId, weedFirstChannel, _)
            local chopperTypeValue = DensityMapModifier.new(weedMapId, weedFirstChannel, _, terrainRootNode)
            local preparingFilter = weedSystem:getMulcherReplacements()
            if preparingFilter.weed ~= nil then
                for sourceState, targetState in pairs(preparingFilter.weed.replacements) do
                    desc:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
                    multiModifier:addExecuteSetWithStats("", targetState, chopperTypeValue, desc)
                end
            end
            if preparingFilter.custom ~= nil then
                local fruitModifier = nil
                for sourceState, targetState in ipairs(preparingFilter.custom) do
                    local desc = targetState.fruitType
                    if desc.terrainDataPlaneId ~= nil then
                        if fruitModifier == nil then
                            fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
                        else
                            fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        end
                        if desc == nil then
                            desc = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        else
                            desc:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        end
                        for sourceState, targetState in pairs(targetState.replacements) do
                            desc:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
                            multiModifier:addExecuteSetWithStats("", targetState, fruitModifier, desc)
                        end
                    end
                end
            end
            local desc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)
            if desc ~= nil and desc.terrainDataPlaneId ~= nil then
                local foliageFilter = nil
                local fruitValueModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
                fruitValueModifier:setNewTypeIndexMode(DensityIndexCompareMode.UPDATE)
                local sourceState = mission.foliageSystem
                if sourceState ~= nil then
                    local targetState = sourceState:getDecoFoliages()
                    for _, sourceState in pairs(targetState) do
                        if sourceState.mowable and sourceState.terrainDataPlaneId ~= nil then
                            if foliageFilter == nil then
                                foliageFilter = DensityMapFilter.new(sourceState.terrainDataPlaneId, sourceState.startStateChannel, sourceState.numStateChannels)
                            else
                                foliageFilter:resetDensityMapAndChannels(sourceState.terrainDataPlaneId, sourceState.startStateChannel, sourceState.numStateChannels)
                            end
                            foliageFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                            if desc.regrows and desc.mulchedState ~= nil then
                                multiModifier:addExecuteSetWithStats("", desc.mulchedState, fruitValueModifier, foliageFilter)
                            end
                        end
                    end
                end
            end
        end
        FSDensityMapUtil.functionCache.updateMulcherArea = functionData
    end
    DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local terrainRootNode = functionData.multiModifier
    terrainRootNode:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    terrainRootNode:resetStats()
    local mission, fieldGroundSystem = terrainRootNode:execute()
    return mission, fieldGroundSystem
end
function FSDensityMapUtil.updateMowerArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitToField)
    local desc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)
    if desc ~= nil and desc.terrainDataPlaneId ~= nil then
        local functionData = FSDensityMapUtil.functionCache.updateMowerArea
        if functionData == nil then
            functionData = {}
            local multiModifier = DensityMapMultiModifier.new()
            local foliageFilter = nil
            local fruitValueModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, g_terrainNode)
            fruitValueModifier:setNewTypeIndexMode(DensityIndexCompareMode.UPDATE)
            if g_currentMission.foliageSystem ~= nil then
                local decoFoliages = g_currentMission.foliageSystem:getDecoFoliages()
                for _, decoFoliage in pairs(decoFoliages) do
                    if decoFoliage.mowable and decoFoliage.terrainDataPlaneId ~= nil then
                        if foliageFilter == nil then
                            foliageFilter = DensityMapFilter.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels)
                        else
                            foliageFilter:resetDensityMapAndChannels(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels)
                        end
                        if desc.regrows and desc.firstRegrowthState ~= nil then
                            foliageFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                            multiModifier:addExecuteSet(desc.firstRegrowthState, fruitValueModifier, foliageFilter)
                        end
                    end
                end
            end
            functionData.multiModifier = multiModifier
            FSDensityMapUtil.functionCache.updateMowerArea = functionData
        end
        local terrainRootNode = functionData.multiModifier
        if not limitToField then
            terrainRootNode:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
            terrainRootNode:execute()
        end
    end
    return FSDensityMapUtil.cutFruitArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, false, nil, nil, limitToField)
end
function FSDensityMapUtil.updateFruitHaulmArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local functionData = FSDensityMapUtil.functionCache.updateFruitHaulmArea
    if functionData == nil then
        FSDensityMapUtil.functionCache.updateFruitHaulmArea = {
            ["fruitModifiers"] = {},
            ["fruitFilters"] = {},
            ["dropModifiers"] = {},
            ["dropFilters"] = {}
        }
    end
    local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
    if desc == nil or desc.terrainDataPlaneIdHaulm == nil then
        return 0
    end
    local dropModifier = functionData.dropModifiers[fruitId]
    local dropFilter = functionData.dropFilters[fruitId]
    if dropModifier == nil or dropFilter == nil then
        dropModifier = desc:getHaulmModifier()
        functionData.dropModifiers[fruitId] = dropModifier
        dropFilter = DensityMapFilter.new(desc:getModifier())
        dropFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.dropFilters[fruitId] = dropFilter
    end
    dropModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local _, numChangedPixels = dropModifier:executeSetWithStats(1, dropFilter)
    return numChangedPixels
end
function FSDensityMapUtil.getStubbleFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    if not Platform.gameplay.useStubbleShred then
        return 1
    end
    local functionData = FSDensityMapUtil.functionCache.getStubbleFactor
    if functionData == nil then
        local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
        functionData = {
            ["stubbleShredModifier"] = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, g_terrainNode),
            ["stubbleShredFilter"] = DensityMapFilter.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels)
        }
        functionData.stubbleShredFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        FSDensityMapUtil.functionCache.getStubbleFactor = functionData
    end
    local terrainRootNode = functionData.stubbleShredModifier
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local fieldGroundSystem, stubbleShredLevelMapId, stubbleShredLevelFirstChannel = terrainRootNode:executeGet(functionData.stubbleShredFilter)
    return stubbleShredLevelMapId / stubbleShredLevelFirstChannel
end
function FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, force, excludeType)
    local functionData = FSDensityMapUtil.functionCache.resetSprayArea
    if functionData == nil then
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
        functionData = {
            ["resetModifier"] = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, g_terrainNode),
            ["excludeFilter"] = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels),
            ["sprayLevelFilter"] = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
        }
        functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue)
        FSDensityMapUtil.functionCache.resetSprayArea = functionData
    end
    local terrainRootNode = functionData.resetModifier
    local fieldGroundSystem = functionData.excludeFilter
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local sprayTypeMapId = nil
    if not force then
        sprayTypeMapId = functionData.sprayLevelFilter
    end
    if excludeType == nil then
        terrainRootNode:executeSet(0, sprayTypeMapId)
    else
        fieldGroundSystem:setValueCompareParams(DensityValueCompareType.NOTEQUAL, excludeType)
        terrainRootNode:executeSet(0, fieldGroundSystem, sprayTypeMapId)
    end
end
function FSDensityMapUtil.updateSowingArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, ridgeSeeding, angle, growthState, blockedSprayTypeIndex)
    local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
    if desc.terrainDataPlaneId == nil then
        return 0, 0
    end
    local functionData = FSDensityMapUtil.functionCache.updateSowingArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
        local rollerLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
        local fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.FIELD_TYPE)
        local sownType = FieldGroundType.getValueByType(FieldGroundType.SOWN)
        local directSownType = FieldGroundType.getValueByType(FieldGroundType.DIRECT_SOWN)
        FieldGroundType.getValueByType(FieldGroundType.RIDGE)
        local ridgeTypeSown = FieldGroundType.getValueByType(FieldGroundType.RIDGE_SOWN)
        local stubbleTillagedType = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
        local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
        local firstSowingValue, lastSowingValue = fieldGroundSystem:getSowingRange()
        functionData = {
            ["groundTypeModifier"] = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
            ["groundAngleModifier"] = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode),
            ["fruitModifiers"] = {},
            ["fruitFilters"] = {},
            ["sowableFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
        functionData.sowingFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.sowingFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowingValue, lastSowingValue)
        functionData.ridgeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.ridgeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, FieldGroundType.getValueByType(FieldGroundType.RIDGE))
        functionData.fieldTypeFilter = DensityMapFilter.new(fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels)
        if Platform.gameplay.useRolling then
            functionData.rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
            functionData.rollerLevelMaxValue = rollerLevelMaxValue
        end
        functionData.sownType = sownType
        functionData.directSownType = directSownType
        functionData.ridgeTypeSown = ridgeTypeSown
        functionData.firstSowableValue = firstSowableValue
        functionData.lastSowableValue = lastSowableValue
        functionData.firstSowingValue = firstSowingValue
        functionData.lastSowingValue = lastSowingValue
        functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillagedType)
        functionData.directSownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.directSownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, directSownType)
        functionData.sownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.sownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sownType)
        FSDensityMapUtil.functionCache.updateSowingArea = functionData
    end
    local terrainRootNode = functionData.fruitModifiers[fruitIndex]
    if terrainRootNode == nil then
        terrainRootNode = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, g_terrainNode)
        local groundTypeMapId = DensityMapFilter.new(terrainRootNode)
        functionData.fruitModifiers[fruitIndex] = terrainRootNode
        functionData.fruitFilters[fruitIndex] = groundTypeMapId
    end
    local fieldGroundSystem = functionData.fruitFilters[fruitIndex]
    local groundTypeMapId = functionData.groundTypeModifier
    local groundTypeFirstChannel = functionData.groundAngleModifier
    local groundTypeNumChannels = functionData.sowableFilter
    local groundAngleMapId = functionData.sowingFilter
    local groundAngleFirstChannel = functionData.ridgeFilter
    local groundAngleNumChannels = functionData.rollerLevelModifier
    local rollerLevelMapId = functionData.rollerLevelMaxValue
    local rollerLevelFirstChannel = functionData.stubbleTillageFilter
    local rollerLevelNumChannels = functionData.directSownFilter
    local rollerLevelMaxValue = functionData.sownFilter
    local fieldTypeMapId = functionData.directSownType
    local fieldTypeFirstChannel = functionData.sownType
    local fieldTypeNumChannels = functionData.ridgeTypeSown
    local sownType = nil
    if desc.seedRequiredFieldType ~= nil then
        functionData.fieldTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, FieldType.getValueByType(desc.seedRequiredFieldType))
    end
    growthState = growthState or 1
    fieldGroundType = fieldGroundType or fieldTypeFirstChannel
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    groundTypeMapId:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    groundTypeFirstChannel:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    if Platform.gameplay.useRolling then
        groundAngleNumChannels:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        groundAngleNumChannels:executeSet(not desc.needsRolling and 0 or rollerLevelMapId, groundTypeNumChannels)
    end
    fieldGroundSystem:setValueCompareParams(DensityValueCompareType.NOTEQUAL, growthState)
    local directSownType, ridgeType, ridgeTypeSown = terrainRootNode:executeSetWithStats(growthState, fieldGroundSystem, groundTypeNumChannels, sownType)
    if g_currentMission.missionInfo.weedsEnabled and desc.plantsWeed then
        FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    else
        FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    end
    FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex, groundTypeNumChannels)
    FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local stubbleTillagedType = 0
    if fieldGroundType ~= fieldTypeNumChannels then
        local firstSowableValue, lastSowableValue, firstSowingValue = groundTypeMapId:executeSetWithStats(fieldTypeMapId, groundTypeNumChannels, rollerLevelFirstChannel)
        local lastSowingValue, directArea, totalSownArea = groundTypeMapId:executeGet(rollerLevelNumChannels)
        if totalSownArea > 0 and directArea / totalSownArea > 0.5 then
            groundTypeMapId:executeSet(fieldTypeMapId, rollerLevelMaxValue)
        end
    end
    fieldGroundSystem:setValueCompareParams(DensityValueCompareType.EQUAL, growthState)
    if ridgeSeeding then
        local firstSowableValue, lastSowableValue, firstSowingValue = groundTypeMapId:executeSetWithStats(fieldTypeNumChannels, groundAngleFirstChannel, fieldGroundSystem)
    end
    local firstSowableValue, lastSowableValue, firstSowingValue = groundTypeMapId:executeSetWithStats(fieldGroundType, groundTypeNumChannels, fieldGroundSystem)
    local stubbleTillagedType = stubbleTillagedType + firstSowingValue
    groundTypeFirstChannel:executeSet(angle or 0, groundAngleMapId, fieldGroundSystem)
    return ridgeType, stubbleTillagedType
end
function FSDensityMapUtil.updateDirectSowingArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, ridgeSeeding, angle, growthState, blockedSprayTypeIndex)
    local fruitTypeManager = g_fruitTypeManager
    local desc = fruitTypeManager:getFruitTypeByIndex(fruitIndex)
    if desc.terrainDataPlaneId == nil then
        return 0, 0
    end
    growthState = growthState or 1
    local functionData = FSDensityMapUtil.functionCache.updateDirectSowingArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        local sownType = FieldGroundType.getValueByType(FieldGroundType.SOWN)
        local directSownType = FieldGroundType.getValueByType(FieldGroundType.DIRECT_SOWN)
        local ridgeTypeSown = FieldGroundType.getValueByType(FieldGroundType.RIDGE_SOWN)
        local stubbleTillagedType = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
        local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
        local firstSowingValue, lastSowingValue = fieldGroundSystem:getSowingRange()
        local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
        local rollerLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
        local fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.FIELD_TYPE)
        functionData = {
            ["multiModifiers"] = {},
            ["fruitModifiers"] = {},
            ["fruitFilters"] = {},
            ["preparingModifier"] = {},
            ["preparingFilter"] = {},
            ["sprayLevelModifier"] = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode),
            ["sprayLevelFilter"] = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
        }
        functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)
        functionData.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
        functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
        functionData.groundAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
        functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.groundTypeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
        functionData.sowingFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.sowingFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowingValue, lastSowingValue)
        functionData.ridgeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.ridgeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, FieldGroundType.getValueByType(FieldGroundType.RIDGE))
        functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillagedType)
        functionData.directSownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.directSownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, directSownType)
        functionData.sownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.sownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sownType)
        functionData.fieldTypeFilter = DensityMapFilter.new(fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels)
        if Platform.gameplay.useRolling then
            functionData.rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
            functionData.rollerLevelMaxValue = rollerLevelMaxValue
        end
        functionData.sownType = sownType
        functionData.directSownType = directSownType
        functionData.ridgeTypeSown = ridgeTypeSown
        FSDensityMapUtil.functionCache.updateDirectSowingArea = functionData
    end
    local terrainRootNode = functionData.sowableFilter
    local fieldGroundSystem = functionData.sowingFilter
    local groundTypeMapId = functionData.ridgeFilter
    local groundTypeFirstChannel = functionData.fieldFilter
    local groundTypeNumChannels = functionData.groundTypeFilter
    local groundAngleMapId = functionData.ridgeTypeSown
    local groundAngleFirstChannel = functionData.directSownType
    local groundAngleNumChannels = functionData.stubbleTillageFilter
    local sprayLevelMapId = functionData.directSownFilter
    local sprayLevelFirstChannel = functionData.sownFilter
    local sprayLevelNumChannels = functionData.sprayLevelModifier
    local sprayLevelMaxValue = functionData.sprayLevelFilter
    local sprayTypeMapId = functionData.sprayTypeModifier
    local sprayTypeFirstChannel = functionData.groundTypeModifier
    local sprayTypeNumChannels = functionData.groundAngleModifier
    local sownType = functionData.multiModifiers[fruitIndex]
    local directSownType = functionData.fruitModifiers[fruitIndex]
    local ridgeTypeSown = g_terrainNode
    local stubbleTillagedType = functionData.rollerLevelModifier
    local firstSowableValue = functionData.rollerLevelMaxValue
    local lastSowableValue = nil
    if desc.seedRequiredFieldType ~= nil then
        functionData.fieldTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, FieldType.getValueByType(desc.seedRequiredFieldType))
    end
    if sownType == nil then
        functionData.multiModifiers[fruitIndex] = {}
        directSownType = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, ridgeTypeSown)
        functionData.fruitModifiers[fruitIndex] = directSownType
    end
    local firstSowingValue = sownType[growthState]
    if firstSowingValue == nil then
        local lastSowingValue = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
        firstSowingValue = DensityMapMultiModifier.new()
        sownType[growthState] = firstSowingValue
        for rollerLevelMaxValue, fieldTypeMapId in pairs(fruitTypeManager:getFruitTypes()) do
            if fieldTypeMapId.terrainDataPlaneId ~= nil and fieldTypeMapId.isCultivationAllowed then
                local fieldTypeFirstChannel = functionData.fruitFilters[rollerLevelMaxValue]
                if fieldTypeFirstChannel == nil then
                    fieldTypeFirstChannel = DensityMapFilter.new(fieldTypeMapId.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                    functionData.fruitFilters[rollerLevelMaxValue] = fieldTypeFirstChannel
                end
                if fieldTypeMapId.cutState > 1 then
                    fieldTypeFirstChannel:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, fieldTypeMapId.cutState - 1)
                    firstSowingValue:addExecuteAdd(1, sprayLevelNumChannels, sprayLevelMaxValue, groundTypeFirstChannel, fieldTypeFirstChannel)
                    firstSowingValue:addExecuteSet(1, sprayTypeMapId, groundTypeFirstChannel, fieldTypeFirstChannel)
                end
                if fieldTypeMapId.allowsSeeding then
                    if rollerLevelMaxValue == fruitIndex then
                        fieldTypeFirstChannel:setValueCompareParams(DensityValueCompareType.BETWEEN, growthState + 1, (math.max(fieldTypeMapId.maxHarvestingGrowthState, fieldTypeMapId.cutState)))
                        firstSowingValue:addExecuteSet(lastSowingValue, sprayTypeFirstChannel, groundTypeFirstChannel, fieldTypeFirstChannel)
                    else
                        fieldTypeFirstChannel:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                        firstSowingValue:addExecuteSet(lastSowingValue, sprayTypeFirstChannel, groundTypeFirstChannel, fieldTypeFirstChannel)
                    end
                    if fieldTypeMapId.mulchedState ~= nil and (fieldTypeMapId.mulchedState > 0 and fieldTypeMapId.mulchedState ~= growthState) then
                        fieldTypeFirstChannel:setValueCompareParams(DensityValueCompareType.EQUAL, fieldTypeMapId.mulchedState)
                        firstSowingValue:addExecuteSet(lastSowingValue, sprayTypeFirstChannel, groundTypeFirstChannel, fieldTypeFirstChannel)
                    end
                end
                if fieldTypeMapId.terrainDataPlaneIdHaulm ~= nil then
                    local fieldTypeNumChannels = functionData.preparingModifier[rollerLevelMaxValue]
                    if fieldTypeNumChannels == nil then
                        fieldTypeNumChannels = DensityMapModifier.new(fieldTypeMapId.terrainDataPlaneIdHaulm, fieldTypeMapId.startStateChannelHaulm, fieldTypeMapId.numStateChannelsHaulm)
                        functionData.preparingModifier[rollerLevelMaxValue] = fieldTypeNumChannels
                    end
                    local preparingFilter = functionData.preparingFilter[rollerLevelMaxValue]
                    if preparingFilter == nil then
                        preparingFilter = DensityMapFilter.new(fieldTypeMapId.terrainDataPlaneIdHaulm, fieldTypeMapId.startStateChannelHaulm, fieldTypeMapId.numStateChannelsHaulm)
                        preparingFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                        preparingFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
                        functionData.preparingFilter[rollerLevelMaxValue] = preparingFilter
                    end
                    firstSowingValue:addExecuteSet(0, fieldTypeNumChannels, preparingFilter)
                end
                local fieldTypeNumChannels = functionData.fruitModifiers[rollerLevelMaxValue]
                if fieldTypeNumChannels == nil then
                    fieldTypeNumChannels = DensityMapModifier.new(fieldTypeMapId.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, ridgeTypeSown)
                    functionData.fruitModifiers[rollerLevelMaxValue] = fieldTypeNumChannels
                end
                if rollerLevelMaxValue == fruitIndex then
                    fieldTypeFirstChannel:setValueCompareParams(DensityValueCompareType.BETWEEN, growthState + 1, (math.max(fieldTypeMapId.maxHarvestingGrowthState, fieldTypeMapId.cutState)))
                else
                    fieldTypeFirstChannel:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, (math.max(fieldTypeMapId.maxHarvestingGrowthState, fieldTypeMapId.cutState)))
                end
                firstSowingValue:addExecuteSet(0, fieldTypeNumChannels, fieldTypeFirstChannel, groundTypeFirstChannel)
            end
        end
        local rollerLevelMapId = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY)
        groundTypeNumChannels:setValueCompareParams(DensityValueCompareType.EQUAL, rollerLevelMapId)
        firstSowingValue:addExecuteSet(lastSowingValue, sprayTypeFirstChannel, groundTypeNumChannels)
        local rollerLevelFirstChannel = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY_OTHER)
        groundTypeNumChannels:setValueCompareParams(DensityValueCompareType.EQUAL, rollerLevelFirstChannel)
        firstSowingValue:addExecuteSet(lastSowingValue, sprayTypeFirstChannel, groundTypeNumChannels)
        local rollerLevelNumChannels = FieldGroundType.getValueByType(FieldGroundType.GRASS)
        groundTypeNumChannels:setValueCompareParams(DensityValueCompareType.EQUAL, rollerLevelNumChannels)
        firstSowingValue:addExecuteSet(lastSowingValue, sprayTypeFirstChannel, groundTypeNumChannels)
        local rollerLevelMaxValue = FieldGroundType.getValueByType(FieldGroundType.GRASS_CUT)
        groundTypeNumChannels:setValueCompareParams(DensityValueCompareType.EQUAL, rollerLevelMaxValue)
        firstSowingValue:addExecuteSet(lastSowingValue, sprayTypeFirstChannel, groundTypeNumChannels)
        FSDensityMapUtil.multiModifierAddResetDisplacement(firstSowingValue)
    end
    directSownType:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    sprayTypeFirstChannel:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    sprayTypeNumChannels:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    firstSowingValue:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    firstSowingValue:execute()
    if g_currentMission.missionInfo.weedsEnabled and desc.plantsWeed then
        FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    else
        FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    end
    if Platform.gameplay.useRolling then
        stubbleTillagedType:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        stubbleTillagedType:executeSet(not desc.needsRolling and 0 or firstSowableValue, terrainRootNode)
    end
    local lastSowingValue, rollerLevelMapId, rollerLevelFirstChannel = directSownType:executeSetWithStats(growthState, terrainRootNode, lastSowableValue)
    if fieldGroundType ~= groundAngleMapId then
        sprayTypeFirstChannel:executeSet(groundAngleFirstChannel, terrainRootNode, groundAngleNumChannels)
        local rollerLevelNumChannels, rollerLevelMaxValue, fieldTypeMapId = sprayTypeFirstChannel:executeGet(sprayLevelMapId)
        if fieldTypeMapId > 0 and rollerLevelMaxValue / fieldTypeMapId > 0.5 then
            sprayTypeFirstChannel:executeSet(groundAngleFirstChannel, sprayLevelFirstChannel)
        end
    end
    if ridgeSeeding then
        sprayTypeFirstChannel:executeSet(groundAngleMapId, groundTypeMapId)
    end
    sprayTypeFirstChannel:executeSet(fieldGroundType, terrainRootNode, lastSowableValue)
    sprayTypeNumChannels:executeSet(angle or 0, fieldGroundSystem)
    FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
    DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return rollerLevelMapId, rollerLevelFirstChannel
end
function FSDensityMapUtil.updateRidgeFormerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
    local functionData = FSDensityMapUtil.functionCache.updateRidgeFormerArea
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
        local ridgeType = FieldGroundType.getValueByType(FieldGroundType.RIDGE)
        local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
        functionData = {
            ["groundTypeModifier"] = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
            ["groundAngleModifier"] = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
        }
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        functionData.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
        functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
        functionData.ridgeType = ridgeType
        functionData.ridgeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        functionData.ridgeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, ridgeType)
        FSDensityMapUtil.functionCache.updateRidgeFormerArea = functionData
    end
    local terrainRootNode = functionData.groundTypeModifier
    local fieldGroundSystem = functionData.groundAngleModifier
    local groundTypeMapId = functionData.sprayTypeModifier
    local groundTypeFirstChannel = functionData.sowableFilter
    local groundTypeNumChannels = functionData.ridgeFilter
    local groundAngleMapId = functionData.ridgeType
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fieldGroundSystem:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    groundTypeMapId:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    groundTypeMapId:executeSet(0, groundTypeFirstChannel)
    local groundAngleFirstChannel, groundAngleNumChannels, ridgeType = terrainRootNode:executeSetWithStats(groundAngleMapId, groundTypeFirstChannel)
    fieldGroundSystem:executeSet(angle or 0, groundTypeNumChannels)
    return groundAngleFirstChannel, groundAngleNumChannels
end
function FSDensityMapUtil.updateFruitPreparerArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, startDropWorldX, startDropWorldZ, widthDropWorldX, widthDropWorldZ, heightDropWorldX, heightDropWorldZ, limitToFruit)
    local functionData = FSDensityMapUtil.functionCache.updateFruitPreparerArea
    if functionData == nil then
        FSDensityMapUtil.functionCache.updateFruitPreparerArea = {
            ["fruitModifiers"] = {},
            ["fruitFilters"] = {},
            ["dropModifiers"] = {},
            ["dropFilters"] = {}
        }
    end
    local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
    local fruitModifier = functionData.fruitModifiers[fruitId]
    if fruitModifier == nil then
        local terrainRootNode = g_terrainNode
        fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
        functionData.fruitModifiers[fruitId] = fruitModifier
        functionData.fruitFilters[fruitId] = {}
        local fruitFilter = DensityMapFilter.new(fruitModifier)
        fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)
        functionData.fruitFilters[fruitId][true] = fruitFilter
        local dropModifier = DensityMapFilter.new(fruitModifier)
        dropModifier:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, 15)
        functionData.fruitFilters[fruitId][false] = dropModifier
        if desc.terrainDataPlaneIdHaulm ~= nil then
            local dropModifier = DensityMapModifier.new(desc.terrainDataPlaneIdHaulm, 0, 1, terrainRootNode)
            functionData.dropModifiers[fruitId] = dropModifier
        end
    end
    local terrainRootNode = functionData.fruitFilters[fruitId][true]
    fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local fruitFilter = nil
    if desc.terrainDataPlaneIdHaulm ~= nil then
        functionData.dropModifiers[fruitId]:setParallelogramWorldCoords(startDropWorldX, startDropWorldZ, widthDropWorldX, widthDropWorldZ, heightDropWorldX, heightDropWorldZ, DensityCoordType.POINT_POINT_POINT)
    end
    if fruitFilter ~= nil then
        fruitFilter:executeSet(1, functionData.fruitFilters[fruitId][limitToFruit == nil and true or limitToFruit])
    end
    local dropModifier, numChangedPixels = fruitModifier:executeSetWithStats(desc.preparedGrowthState, terrainRootNode)
    return numChangedPixels
end
function FSDensityMapUtil.clearDecoArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local functionData = FSDensityMapUtil.functionCache.clearDecoArea
    if functionData == nil then
        local decoFoliages = nil
        if g_currentMission.foliageSystem ~= nil then
            decoFoliages = g_currentMission.foliageSystem:getDecoFoliages()
        end
        if decoFoliages ~= nil and #decoFoliages > 0 then
            functionData = {
                ["decoModifiers"] = {},
                ["decoFilters"] = {},
                ["decoFoliages"] = decoFoliages
            }
            for index, decoFoliage in pairs(decoFoliages) do
                if decoFoliage.terrainDataPlaneId ~= nil then
                    local decoModifier = DensityMapModifier.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, g_terrainNode)
                    decoModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
                    local decoFilter = DensityMapFilter.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels)
                    decoFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
                    functionData.decoModifiers[index] = decoModifier
                    functionData.decoFilters[index] = decoFilter
                end
            end
            FSDensityMapUtil.functionCache.clearDecoArea = functionData
        end
    end
    if functionData == nil then
        return 0, 0, false
    end
    local decoFoliages = 0
    local terrainRootNode = 0
    local nonMowableCut = false
    for decoFoliage, decoModifier in pairs(functionData.decoFoliages) do
        if decoModifier.terrainDataPlaneId ~= nil then
            local decoFilter = functionData.decoModifiers[decoFoliage]
            local decoFilter = functionData.decoFilters[decoFoliage]
            if decoFilter ~= nil and decoFilter ~= nil then
                decoFilter:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
                local _, _area, _totalArea = decoFilter:executeSetWithStats(0, decoFilter)
                if _area > 0 and not decoModifier.mowable then
                    nonMowableCut = true
                end
            end
        end
    end
    return decoFoliages, terrainRootNode, nonMowableCut
end
function FSDensityMapUtil.createVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, customState, ignoreExistingFruits)
    local functionData = FSDensityMapUtil.functionCache.createVineArea
    if functionData == nil then
        functionData = {
            ["fruitData"] = {}
        }
        local stoneSystem = g_currentMission.stoneSystem
        if stoneSystem:getMapHasStones() then
            local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
            functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, g_terrainNode)
        end
        if Platform.gameplay.useLimeCounter then
            local terrainRootNode = g_currentMission.fieldGroundSystem
            local stoneFirstChannel, stoneNumChannels, limeLevelNumChannels = terrainRootNode:getDensityMapData(FieldDensityMap.LIME_LEVEL)
            if stoneFirstChannel ~= nil then
                functionData.limeLevelModifier = DensityMapModifier.new(stoneFirstChannel, stoneNumChannels, limeLevelNumChannels, g_terrainNode)
                functionData.limeLevelMaxValue = terrainRootNode:getMaxValue(FieldDensityMap.LIME_LEVEL)
            end
        end
        FSDensityMapUtil.functionCache.createVineArea = functionData
    end
    local stoneSystem = functionData.fruitData[fruitId]
    if stoneSystem == nil then
        local terrainRootNode = g_terrainNode
        local stoneMapId = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
        local stoneNumChannels, limeLevelNumChannels, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local grassType = FieldGroundType.getValueByType(FieldGroundType.GRASS)
        if stoneMapId.terrainDataPlaneId == nil then
            return 0
        end
        stoneSystem = {
            ["fruitModifier"] = DensityMapModifier.new(stoneMapId.terrainDataPlaneId, stoneMapId.startStateChannel, stoneMapId.numStateChannels, terrainRootNode)
        }
        stoneSystem.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
        stoneSystem.fruitFilter = DensityMapFilter.new(stoneMapId.terrainDataPlaneId, stoneMapId.startStateChannel, stoneMapId.numStateChannels)
        stoneSystem.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        stoneSystem.groundModifier = DensityMapModifier.new(stoneNumChannels, limeLevelNumChannels, groundTypeNumChannels, terrainRootNode)
        stoneSystem.groundModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
        stoneSystem.grassType = grassType
        functionData.fruitData[fruitId] = stoneSystem
    end
    local terrainRootNode = stoneSystem.fruitModifier
    local stoneMapId = stoneSystem.fruitFilter
    local stoneFirstChannel = stoneSystem.groundModifier
    local stoneNumChannels = stoneSystem.grassType
    local limeLevelNumChannels = functionData.stoneModifier
    local groundTypeNumChannels = functionData.limeLevelModifier
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    stoneFirstChannel:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false, false)
    if limeLevelNumChannels ~= nil then
        limeLevelNumChannels:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        limeLevelNumChannels:executeSet(0)
    end
    if groundTypeNumChannels ~= nil then
        groundTypeNumChannels:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        groundTypeNumChannels:executeSet(functionData.limeLevelMaxValue)
    end
    if ignoreExistingFruits then
        stoneMapId = nil
    end
    local grassType, area = terrainRootNode:executeSetWithStats(customState or 1, stoneMapId)
    stoneFirstChannel:executeSet(stoneNumChannels)
    return area
end
function FSDensityMapUtil.destroyVineArea(_, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local functionData = FSDensityMapUtil.functionCache.destroyVineArea
    if functionData == nil then
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        functionData = {
            ["groundModifier"] = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, g_terrainNode)
        }
        functionData.groundModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
        FSDensityMapUtil.functionCache.destroyVineArea = functionData
    end
    local terrainRootNode = functionData.groundModifier
    FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false, true)
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    terrainRootNode:executeSet(0)
end
function FSDensityMapUtil.updateVineAreaValues(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, values)
    local functionData = FSDensityMapUtil.functionCache.updateVineAreaValues
    if functionData == nil then
        FSDensityMapUtil.functionCache.updateVineAreaValues = {
            ["fruitData"] = {}
        }
    end
    local fruitData = functionData.fruitData[fruitId]
    if fruitData == nil then
        fruitData = {}
        local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
        if desc.terrainDataPlaneId == nil then
            local i = 0
            for i = i, desc.numStateChannels ^ 2 - 1 do
                values[i] = 0
            end
            return 0
        end
        fruitData.modifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, g_terrainNode)
        fruitData.modifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
        fruitData.filters = {}
        local i = 0
        for i = i, desc.numStateChannels ^ 2 - 1 do
            fruitData.filters[i] = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
            fruitData.filters[i]:setValueCompareParams(DensityValueCompareType.EQUAL, i)
        end
        functionData.fruitData[fruitId] = fruitData
    end
    fruitData.modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local terrainRootNode = 0
    for i, _ in pairs(values) do
        local _, area, tArea = fruitData.modifier:executeGet(fruitData.filters[i])
        values[i] = area
        terrainRootNode = math.max(terrainRootNode, tArea)
    end
    return terrainRootNode
end
function FSDensityMapUtil.setVineAreaValue(_, fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
    local functionData = FSDensityMapUtil.functionCache.setVineAreaValue
    if functionData == nil then
        FSDensityMapUtil.functionCache.setVineAreaValue = {
            ["fruitData"] = {}
        }
    end
    local fruitData = functionData.fruitData[fruitId]
    if fruitData == nil then
        fruitData = {}
        local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
        fruitData.modifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, g_terrainNode)
        functionData.fruitData[fruitId] = fruitData
    end
    fruitData.modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    fruitData.modifier:executeSet(value)
end
function FSDensityMapUtil.updateVineCutArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local functionData = FSDensityMapUtil.functionCache.updateVineCutArea
    local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        functionData = {
            ["fruitData"] = {},
            ["sprayLevelMaxValue"] = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL),
            ["sprayLevelModifier"] = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
        }
        if Platform.gameplay.usePlowCounter then
            local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
            functionData.plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
        end
        functionData.sprayLevelFilters = {}
        local plowLevelNumChannels = 1
        local plowLevelMapId = functionData.sprayLevelMaxValue
        local plowLevelFirstChannel = 1
        for plowLevelNumChannels = plowLevelNumChannels, plowLevelMapId, plowLevelFirstChannel do
            local plowLevelModifier = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
            plowLevelModifier:setValueCompareParams(DensityValueCompareType.EQUAL, plowLevelNumChannels)
            functionData.sprayLevelFilters[plowLevelNumChannels] = plowLevelModifier
        end
        FSDensityMapUtil.functionCache.updateVineCutArea = functionData
    end
    local terrainRootNode = functionData.fruitData[fruitId]
    if terrainRootNode == nil then
        terrainRootNode = {}
        if desc.terrainDataPlaneId == nil then
            return 0
        end
        terrainRootNode.fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, g_terrainNode)
        terrainRootNode.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
        terrainRootNode.transitionFilters = {}
        for plowLevelMapId, plowLevelFirstChannel in pairs(desc.harvestTransitions) do
            local plowLevelNumChannels = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
            plowLevelNumChannels:setValueCompareParams(DensityValueCompareType.EQUAL, plowLevelMapId)
            terrainRootNode.transitionFilters[plowLevelFirstChannel] = plowLevelNumChannels
        end
        terrainRootNode.harvestFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
        terrainRootNode.harvestFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState)
        if desc.harvestWeedState ~= -1 then
            terrainRootNode.weedFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
            terrainRootNode.weedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.harvestWeedState)
        end
        functionData.fruitData[fruitId] = terrainRootNode
    end
    local fieldGroundSystem = terrainRootNode.fruitModifier
    local sprayLevelMapId = terrainRootNode.transitionFilters
    local sprayLevelFirstChannel = terrainRootNode.weedFilter
    local sprayLevelNumChannels = terrainRootNode.harvestFilter
    local plowLevelMapId = functionData.sprayLevelModifier
    local plowLevelFirstChannel = functionData.sprayLevelMaxValue
    local plowLevelNumChannels = functionData.plowLevelModifier
    local plowLevelModifier = functionData.sprayLevelFilters
    fieldGroundSystem:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    plowLevelMapId:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local sprayLevel = 0
    for i, filter in pairs(plowLevelModifier) do
        local _, sprayLevelArea, _ = plowLevelMapId:executeGet(filter)
        if sprayLevelArea > 0 and sprayLevel < i then
            sprayLevel = i
        end
    end
    FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, nil)
    plowLevelMapId:executeSet(0, sprayLevelNumChannels)
    if desc.startSprayLevel > 0 then
        plowLevelMapId:executeSet(math.min(desc.startSprayLevel, plowLevelFirstChannel), sprayLevelNumChannels)
        FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, nil)
    end
    local weedArea = 0
    if sprayLevelFirstChannel ~= nil then
        local plowArea, i
        plowArea, weedArea, i = fieldGroundSystem:executeGet(sprayLevelFirstChannel)
    end
    local plowArea = 0
    local plowLevel = 0
    if plowLevelNumChannels ~= nil then
        plowLevelNumChannels:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local filter, _
        plowLevel, filter, _ = plowLevelNumChannels:executeAddWithStats(-1, sprayLevelNumChannels)
    end
    local i = 0
    local filter = nil
    for target, filter in pairs(sprayLevelMapId) do
        _, _, filter = fieldGroundSystem:executeSetWithStats(target, filter)
    end
    if plowLevel > 0 then
        plowArea = i
    end
    return i, filter, 1 - (weedArea < filter and 0 or weedArea) / filter, sprayLevel / plowLevelFirstChannel, plowArea / filter
end
function FSDensityMapUtil.updateVinePrepareArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local functionData = FSDensityMapUtil.functionCache.updateVinePrepareArea
    if functionData == nil then
        FSDensityMapUtil.functionCache.updateVinePrepareArea = {
            ["fruitData"] = {}
        }
    end
    local fruitData = functionData.fruitData[fruitId]
    if fruitData == nil then
        local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
        if desc.terrainDataPlaneId == nil then
            return 0
        end
        if desc.witheredState == nil then
            return 0
        end
        fruitData = {
            ["fruitModifier"] = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, g_terrainNode)
        }
        fruitData.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
        fruitData.fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
        fruitData.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.witheredState)
        functionData.fruitData[fruitId] = fruitData
    end
    local terrainRootNode = fruitData.fruitModifier
    local desc = fruitData.fruitFilter
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local _, area, totalArea = terrainRootNode:executeSetWithStats(1, desc)
    return area, totalArea
end
function FSDensityMapUtil.resetVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, resetState)
    local functionData = FSDensityMapUtil.functionCache.resetVineArea
    if functionData == nil then
        FSDensityMapUtil.functionCache.resetVineArea = {
            ["fruitData"] = {}
        }
    end
    local fruitData = functionData.fruitData[fruitId]
    if fruitData == nil then
        fruitData = {}
        local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
        if desc.terrainDataPlaneId == nil then
            return 0
        end
        fruitData.fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, g_terrainNode)
        fruitData.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
        fruitData.fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
        fruitData.fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.fruitData[fruitId] = fruitData
    end
    local terrainRootNode = fruitData.fruitModifier
    local desc = fruitData.fruitFilter
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local _, area, totalArea = terrainRootNode:executeSetWithStats(resetState, desc)
    return area, totalArea
end
function FSDensityMapUtil.updateVineCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, changeGroundType)
    local functionData = FSDensityMapUtil.functionCache.updateVineCultivatorArea
    changeGroundType = changeGroundType == nil and true or changeGroundType
    if functionData == nil then
        local terrainRootNode = g_terrainNode
        local fieldGroundSystem = g_currentMission.fieldGroundSystem
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local cultivatedType = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
        local groundModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
        functionData = {
            ["fruitData"] = {},
            ["groundModifier"] = groundModifier,
            ["groundFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.groundFilter:setValueCompareParams(DensityValueCompareType.EQUAL, cultivatedType)
        local multiModifiers = {
            [true] = DensityMapMultiModifier.new(),
            [false] = DensityMapMultiModifier.new()
        }
        local fruitFilter = nil
        local plowLevelModifier = nil
        if Platform.gameplay.usePlowCounter then
            local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
            plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
        end
        for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil and desc.cultivationStates ~= nil then
                if fruitFilter == nil then
                    fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                else
                    fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                end
                for _, state in ipairs(desc.cultivationStates) do
                    fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, state)
                    multiModifiers[true]:addExecuteSet(cultivatedType, groundModifier, fruitFilter)
                    if plowLevelModifier ~= nil then
                        multiModifiers[true]:addExecuteAdd(1, plowLevelModifier, fruitFilter)
                        multiModifiers[false]:addExecuteAdd(1, plowLevelModifier, fruitFilter)
                    end
                end
            end
        end
        functionData.multiModifiers = multiModifiers
        FSDensityMapUtil.functionCache.updateVineCultivatorArea = functionData
    end
    local terrainRootNode = functionData.multiModifiers
    local fieldGroundSystem = functionData.groundModifier
    local groundTypeMapId = functionData.groundFilter
    fieldGroundSystem:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local groundTypeFirstChannel, groundTypeNumChannels, cultivatedType = fieldGroundSystem:executeGet(groundTypeMapId)
    terrainRootNode[changeGroundType]:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    terrainRootNode[changeGroundType]:execute()
    local groundModifier, multiModifiers, fruitFilter = fieldGroundSystem:executeGet(groundTypeMapId)
    FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return multiModifiers - groundTypeNumChannels
end
function FSDensityMapUtil.updateDisasterArea(densityMapArea, perlinPercentage)
    local functionData = FSDensityMapUtil.functionCache.updateDisasterArea
    if functionData == nil then
        local groundTypeMapId, _, _ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        functionData = {
            ["perlinFilters"] = {},
            ["multiModifiers"] = {},
            ["perlinFilter"] = PerlinNoiseFilter.new(groundTypeMapId, 11, 1, 0.5, math.random(0, 10000))
        }
        FSDensityMapUtil.functionCache.updateDisasterArea = functionData
    end
    local fieldGroundSystem = functionData.multiModifiers[perlinPercentage]
    if fieldGroundSystem == nil then
        local groundTypeMapId = functionData.perlinFilter
        groundTypeMapId:setValueCompareParams(DensityValueCompareType.GREATER, perlinPercentage)
        fieldGroundSystem = DensityMapMultiModifier.new()
        local _ = nil
        local _ = nil
        for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.terrainDataPlaneId ~= nil and desc.minDisasterDestructionState ~= nil then
                if _ == nil then
                    _ = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                else
                    _:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                end
                _:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minDisasterDestructionState, desc.maxDisasterDestructionState)
                if _ == nil then
                    _ = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                else
                    _:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                end
                if desc.disasterDestructionState == 0 then
                    _:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
                else
                    _:setNewTypeIndexMode(DensityIndexCompareMode.KEEP)
                end
                fieldGroundSystem:addExecuteSet(desc.disasterDestructionState, _, _, groundTypeMapId)
            end
        end
        local weedMapId, weedFirstChannel, index = g_currentMission.weedSystem:getDensityMapData()
        fieldGroundSystem:addExecuteSet(0, DensityMapModifier.new(weedMapId, weedFirstChannel, index, g_terrainNode), groundTypeMapId)
        local groundTypeMapId, firstChannel, numChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        local groundModifier = DensityMapModifier.new(groundTypeMapId, firstChannel, numChannels, g_terrainNode)
        local groundFilter = DensityMapFilter.new(groundTypeMapId, firstChannel, numChannels)
        local groundTypeSown = FieldGroundType.getValueByType(FieldGroundType.SOWN)
        local groundTypeHarvestReady = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY)
        groundFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, groundTypeSown, groundTypeHarvestReady)
        fieldGroundSystem:addExecuteSet(FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY_OTHER), groundModifier, groundTypeMapId, groundFilter)
        functionData.multiModifiers[perlinPercentage] = fieldGroundSystem
    end
    densityMapArea:applyToModifier(fieldGroundSystem)
    fieldGroundSystem:execute()
end
function FSDensityMapUtil.eraseTireTrack(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local tireTrackSystem = g_currentMission.tireTrackSystem
    if tireTrackSystem ~= nil then
        tireTrackSystem:eraseParallelogram(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    end
end
function FSDensityMapUtil.getAreaDensity(id, firstChannel, numChannels, value, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local functionData = FSDensityMapUtil.functionCache.getAreaDensity
    if functionData == nil then
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        functionData = {
            ["filter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels),
            ["densityMapIdToModifier"] = {}
        }
        FSDensityMapUtil.functionCache.getAreaDensity = functionData
    end
    local fieldGroundSystem = functionData.densityMapIdToModifier[id]
    local groundTypeMapId = functionData.filter
    if fieldGroundSystem == nil then
        fieldGroundSystem = DensityMapModifier.new(id, firstChannel, numChannels, g_terrainNode)
        functionData.densityMapIdToModifier[id] = fieldGroundSystem
    end
    fieldGroundSystem:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    groundTypeMapId:setValueCompareParams(DensityValueCompareType.EQUAL, value)
    local groundTypeFirstChannel, groundTypeNumChannels, totalNumPixels = fieldGroundSystem:executeGet(groundTypeMapId)
    return groundTypeFirstChannel, groundTypeNumChannels, totalNumPixels
end
function FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
    local dataPlaneId = g_fruitTypeManager:getDefaultDataPlaneId()
    if dataPlaneId ~= nil then
        local densityTypeIndex = getDensityTypeIndexAtWorldPos(dataPlaneId, x, 0, z)
        local desc = g_fruitTypeManager:getFruitTypeByDensityTypeIndex(densityTypeIndex)
        if desc ~= nil then
            local growthState = desc:getGrowthStateByDensityState((getDensityStatesAtWorldPos(dataPlaneId, x, 0, z)))
            return desc.index, growthState
        end
    end
    return nil
end
function FSDensityMapUtil.getIsFieldAtWorldPos(x, z)
    local isOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, x, 0, z) ~= 0
    return isOnField
end
function FSDensityMapUtil.getFieldTypeAtWorldPos(x, z)
    local fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.FIELD_TYPE)
    local width, height = getBitVectorMapSize(fieldTypeMapId)
    local terrainSize = g_currentMission.terrainSize
    x = math.floor(width * (x + terrainSize * 0.5) / terrainSize)
    z = math.floor(height * (z + terrainSize * 0.5) / terrainSize)
    return getBitVectorMapPoint(fieldTypeMapId, x, z, fieldTypeFirstChannel, fieldTypeNumChannels) + 1
end
function FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local functionData = FSDensityMapUtil.functionCache.getFieldDensity
    if functionData == nil then
        local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
        functionData = {
            ["modifier"] = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, g_terrainNode),
            ["filter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
        }
        functionData.filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        FSDensityMapUtil.functionCache.getFieldDensity = functionData
    end
    local terrainRootNode = functionData.modifier
    terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = terrainRootNode:executeGet(functionData.filter)
    return groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels
end
function FSDensityMapUtil.getBushDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local functionData = FSDensityMapUtil.functionCache.getBushDensity
    if functionData == nil then
        local bushId, _ = getTerrainDataPlaneByName(g_terrainNode, "decoBush")
        if bushId == 0 then
            return 0, 0, 0
        end
        functionData = {
            ["modifier"] = DensityMapModifier.new(bushId, 0, 4, g_terrainNode)
        }
        functionData.modifier:setReturnValueShift(-1)
        local filter = DensityMapFilter.new(bushId, 0, 4)
        filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        functionData.filter = filter
        FSDensityMapUtil.functionCache.getBushDensity = functionData
    end
    local bushId = functionData.modifier
    local _ = functionData.filter
    bushId:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    local terrainRootNode, filter, totalNumPixels = bushId:executeGet(_)
    return terrainRootNode, filter, totalNumPixels
end
function FSDensityMapUtil.convertToDensityMapAngle(angle, maxDensityValue)
    local value = math.floor(angle / 3.141592653589793 * (maxDensityValue + 1) + 0.5)
    while maxDensityValue < value do
        value = value - (maxDensityValue + 1)
    end
    while value < 0 do
        value = value + (maxDensityValue + 1)
    end
    return value
end
function FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
    local weedFactor = 0
    local weedSystem = g_currentMission.weedSystem
    if weedSystem:getMapHasWeed() then
        local functionData = FSDensityMapUtil.functionCache.getWeedFactor
        if functionData == nil then
            local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
            local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
            local factors = weedSystem:getFactors()
            functionData = {
                ["weedModifier"] = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode),
                ["fieldFilter"] = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
            }
            functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
            functionData.fruitFilters = {}
            functionData.weedStateFilters = {}
            for state, factor in pairs(factors) do
                local filter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
                filter:setValueCompareParams(DensityValueCompareType.EQUAL, state)
                functionData.weedStateFilters[filter] = factor
            end
            FSDensityMapUtil.functionCache.getWeedFactor = functionData
        end
        local terrainRootNode = functionData.weedModifier
        local groundTypeMapId = functionData.fieldFilter
        local weedFirstChannel = nil
        if fruitIndex ~= nil then
            weedFirstChannel = functionData.fruitFilters[fruitIndex]
            if weedFirstChannel == nil then
                local weedNumChannels = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
                weedFirstChannel = DensityMapFilter.new(weedNumChannels.terrainDataPlaneId, weedNumChannels.startStateChannel, weedNumChannels.numStateChannels)
                weedFirstChannel:setValueCompareParams(DensityValueCompareType.BETWEEN, weedNumChannels.minForageGrowthState or weedNumChannels.minHarvestingGrowthState, weedNumChannels.maxHarvestingGrowthState)
                functionData.fruitFilters[fruitIndex] = weedFirstChannel
            end
        end
        terrainRootNode:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local weedNumChannels, factors, groundTypeFirstChannel = terrainRootNode:executeGet(groundTypeMapId, weedFirstChannel)
        if factors ~= 0 then
            for filter, factor in pairs(functionData.weedStateFilters) do
                local state, factor, filter = terrainRootNode:executeGet(filter, groundTypeMapId, weedFirstChannel)
            end
        end
    end
    return weedFactor
end
function FSDensityMapUtil.assert(bool, warning)
    if FSDensityMapUtil.DEBUG_ENABLED then
        assert(bool, warning)
    end
end
function FSDensityMapUtil.runBenchmark()
    local size = 128
    local startWorldX = -128
    local startWorldZ = -128
    local widthWorldX = -128
    local heightWorldZ = -128
    local tests = {}
    table.insert(tests, {
        ["name"] = "FSDensityMapUtil.updateRollerArea",
        ["func"] = function()
            -- upvalues: (copy) startWorldX, (copy) startWorldZ, (copy) widthWorldX, (copy) size, (copy) size, (copy) heightWorldZ
            FSDensityMapUtil.updateRollerArea(-128, -128, -128, 128, 128, -128, 0)
        end
    })
    for _, test in ipairs(tests) do
        Logging.info("Benchmark-Start - %s - Size %dx%dm", test.name, 128, 128)
        local durationTotal = 0
        local i = 1
        for i = i, 10 do
            local timeBefore = getTimeSec()
            test.func()
            local duration = (getTimeSec() - timeBefore) * 1000
            Logging.info("    Run %d - Time: %.4fms", i, duration)
        end
        Logging.info("Benchmark-Finished - Avg. Time: %.4fms", durationTotal / 10)
    end
end