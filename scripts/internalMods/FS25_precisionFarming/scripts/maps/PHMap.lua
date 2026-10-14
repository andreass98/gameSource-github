PHMap = {}
PHMap.MOD_NAME = g_currentModName
PHMap.NUM_BITS = 5
local PHMap_mt = Class(PHMap, ValueMap)
function PHMap.new(pfModule, customMt)
    -- upvalues: (copy) PHMap_mt
    local self = ValueMap.new(pfModule, customMt or PHMap_mt)
    self.name = "pHMap"
    self.id = "PH_MAP"
    self.label = "ui_mapOverviewPH"
    self.densityMapModifiersInitialize = {}
    self.densityMapModifiersHarvestMulti = nil
    self.densityMapModifiersLockedState = {}
    self.densityMapModifiersSpray = nil
    self.densityMapModifiersResetLock = {}
    self.lastActualValue = -1
    self.lastTargetValue = -1
    self.lastRegularValue = -1
    self.minimapGradientSliceId = "precisionFarming.gradient_ph"
    self.minimapGradientColorBlindSliceId = "precisionFarming.gradient_color_blind"
    self.minimapLabelName = g_i18n:getText("ui_mapOverviewPH", PHMap.MOD_NAME)
    self.realisticSpreadPatternEnabled = true
    self.realisticSpreadOutputEnabled = true
    pfModule:addSetting("realisticSpreadPattern", g_i18n:getText("settingTitle_realisticSpreadPattern"), g_i18n:getText("settingDescription_realisticSpreadPattern"), self.onRealisticSpreadPatternSettingChanged, self, self.realisticSpreadPatternEnabled, true, nil, true)
    pfModule:addSetting("realisticSpreadOutput", g_i18n:getText("settingTitle_realisticSpreadOutput"), g_i18n:getText("settingDescription_realisticSpreadOutput"), self.onRealisticSpreadOutputSettingChanged, self, self.realisticSpreadOutputEnabled, true, nil, true)
    if g_server ~= nil then
        addConsoleCommand("pfPHSet", "Sets the given pH level on the given field", "debugSetPHLevel", self)
    end
    return self
end
function PHMap:initialize()
    PHMap:superClass().initialize(self)
    self.densityMapModifiersInitialize = {}
    self.densityMapModifiersHarvestMulti = nil
    self.densityMapModifiersLockedState = {}
    self.densityMapModifiersSpray = nil
    self.densityMapModifiersResetLock = {}
    self.lastActualValue = -1
    self.lastTargetValue = -1
    self.lastRegularValue = -1
end
function PHMap:delete()
    if g_server ~= nil then
        removeConsoleCommand("pfPHSet")
    end
    PHMap:superClass().delete(self)
end
function PHMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, _)
    key = key .. ".pHMap"
    self.firstChannel = getXMLInt(xmlFile, key .. ".bitVectorMap#firstChannel") or 1
    self.numChannels = getXMLInt(xmlFile, key .. ".bitVectorMap#numChannels") or 4
    self.maxValue = getXMLInt(xmlFile, key .. ".bitVectorMap#maxValue") or 2 ^ self.numChannels - 1
    self.sizeX = 1024
    self.sizeY = 1024
    local i, baseKey = self:loadSavedBitVectorMap("phMap", "precisionFarming_phMap.grle", self.numChannels, self.sizeX)
    self.bitVectorMap = i
    self.newBitVectorMap = baseKey
    self:addBitVectorMapToSync(self.bitVectorMap)
    self:addBitVectorMapToSave(self.bitVectorMap, "precisionFarming_phMap.grle")
    self:addBitVectorMapToDelete(self.bitVectorMap)
    self.noiseFilename = getXMLString(xmlFile, key .. ".noiseMap#filename")
    self.noiseNumChannels = getXMLInt(xmlFile, key .. ".noiseMap#numChannels") or 2
    self.noiseResolution = getXMLInt(xmlFile, key .. ".noiseMap#resolution") or 1024
    self.noiseMaxValue = 2 ^ self.noiseNumChannels - 1
    self.bitVectorMapNoise = createBitVectorMap("pHNoiseMap")
    if self.noiseFilename ~= nil then
        self.noiseFilename = Utils.getFilename(self.noiseFilename, baseDirectory)
        if not loadBitVectorMapFromFile(self.bitVectorMapNoise, self.noiseFilename, self.noiseNumChannels) then
            Logging.xmlWarning(configFileName, "Error while loading pH noise map \'%s\'", self.noiseFilename)
            self.noiseFilename = nil
        end
    end
    if self.noiseFilename == nil then
        loadBitVectorMapNew(self.bitVectorMapNoise, self.noiseResolution, self.noiseResolution, self.noiseNumChannels, false)
    end
    self:addBitVectorMapToDelete(self.bitVectorMapNoise)
    self.bitVectorMapPHStateChange = self:loadSavedBitVectorMap("pHLockStateMap", "precisionFarming_pHLockStateMap.grle", 2, self.noiseResolution)
    self:addBitVectorMapToSave(self.bitVectorMapPHStateChange, "precisionFarming_pHLockStateMap.grle")
    self:addBitVectorMapToDelete(self.bitVectorMapPHStateChange)
    self.bitVectorMapPHInitMask = self:loadSavedBitVectorMap("pHInitMaskMap", "pHInitMaskMap.grle", 1, self.noiseResolution)
    self:addBitVectorMapToDelete(self.bitVectorMapPHInitMask)
    self.outdatedLabel = g_i18n:convertText(getXMLString(xmlFile, key .. ".texts#outdatedLabel") or "$l10n_ui_precisionFarming_outdatedData", PHMap.MOD_NAME)
    self.pHValues = {}
    self.pHValuesToDisplay = {}
    self.maxVisibleValue = 0
    local i = 0
    while true do
        local baseKey = string.format("%s.pHValues.pHValue(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local pHValue = {
            ["value"] = getXMLInt(xmlFile, baseKey .. "#value") or 0,
            ["realValue"] = getXMLFloat(xmlFile, baseKey .. "#realValue") or 0,
            ["color"] = string.getVector(getXMLString(xmlFile, baseKey .. "#color"), 3),
            ["colorBlind"] = string.getVector(getXMLString(xmlFile, baseKey .. "#colorBlind"), 3),
            ["showOnHud"] = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#showOnHud"), true)
        }
        local index = self.pHValues
        table.insert(index, pHValue)
        if pHValue.showOnHud then
            table.insert(self.pHValuesToDisplay, pHValue)
            pHValue.filterIndex = #self.pHValuesToDisplay
            local j = #self.pHValues
            local j = 1
            for j = j, j, -1 do
                if self.pHValues[j].filterIndex == nil then
                    self.pHValues[j].filterIndex = pHValue.filterIndex
                    break
                end
            end
        end
        self.maxVisibleValue = pHValue.value
        i = i + 1
    end
    local j = 1
    local baseKey = #self.pHValues
    local pHValue = 1
    for j = j, baseKey, pHValue do
        if self.pHValues[j].filterIndex == nil then
            self.pHValues[j].filterIndex = #self.pHValuesToDisplay
        end
    end
    for index, j in ipairs(self.pHValues) do
        if j.color == nil or j.colorBlind == nil then
            local lastColor = nil
            local lastColorBlind = nil
            local i = index - 1
            local nextColor = 1
            local nextColorBlind = -1
            for i = i, nextColor, nextColorBlind do
                if i > 0 and self.pHValues[i].color ~= nil then
                    lastColor = self.pHValues[i].color
                    lastColorBlind = self.pHValues[i].colorBlind
                    break
                end
            end
            local nextColor = nil
            local nextColorBlind = nil
            local i = index + 1
            local i = #self.pHValues
            for i = i, i do
                if self.pHValues[i].color ~= nil then
                    nextColor = self.pHValues[i].color
                    nextColorBlind = self.pHValues[i].colorBlind
                    break
                end
            end
            if lastColor ~= nil and nextColor ~= nil then
                j.color = { (lastColor[1] + nextColor[1]) * 0.5, (lastColor[2] + nextColor[2]) * 0.5, (lastColor[3] + nextColor[3]) * 0.5 }
            end
            if lastColorBlind ~= nil and nextColorBlind ~= nil then
                j.colorBlind = { (lastColorBlind[1] + nextColorBlind[1]) * 0.5, (lastColorBlind[2] + nextColorBlind[2]) * 0.5, (lastColorBlind[3] + nextColorBlind[3]) * 0.5 }
            end
        end
    end
    self.pHValuePerState = getXMLFloat(xmlFile, key .. ".pHValues#pHValuePerState") or 0.125
    self.valueTransformations = {}
    local i = 0
    while true do
        local baseKey = string.format("%s.valueTransformations.valueTransformation(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local pHValue = {
            ["soilTypeIndex"] = getXMLInt(xmlFile, baseKey .. "#soilTypeIndex") or 1,
            ["baseRange"] = string.getVector(getXMLString(xmlFile, baseKey .. ".baseValue#range"), self.noiseMaxValue + 1)
        }
        if pHValue.baseRange == nil then
            Logging.xmlWarning(configFileName, "Invalid base pH range for \'%s\'", baseKey)
        else
            local j = 1
            local j = #pHValue.baseRange
            local index = 1
            for j = j, j, index do
                local lastColor, lastColorBlind = self:getNearestPhValueFromValue(pHValue.baseRange[j])
                pHValue.baseRange[j] = lastColorBlind
            end
            local index, j = self:getNearestPhValueFromValue(getXMLFloat(xmlFile, baseKey .. ".optimalValue#value") or 6.5)
            pHValue.optimalValue = j
            pHValue.regularOffset = (getXMLFloat(xmlFile, baseKey .. ".regularOffset#value") or self.pHValuePerState) / self.pHValuePerState
            pHValue.decreasePerHarvest = {}
            local index = 0
            while true do
                local j = string.format("%s.decreasePerHarvest(%d)", baseKey, index)
                if not hasXMLProperty(xmlFile, j) then
                    break
                end
                local lastColor = {
                    ["range"] = string.getVector(getXMLString(xmlFile, j .. "#range"), 2)
                }
                if lastColor.range ~= nil then
                    local nextColorBlind = 1
                    for nextColorBlind = nextColorBlind, #lastColor.range do
                        local i, internalIndex = self:getNearestPhValueFromValue(lastColor.range[nextColorBlind])
                        lastColor.range[nextColorBlind] = internalIndex
                    end
                end
                lastColor.decreaseValue = MathUtil.round((getXMLFloat(xmlFile, j .. "#value") or self.pHValuePerState) / self.pHValuePerState)
                local nextColor = pHValue.decreasePerHarvest
                table.insert(nextColor, lastColor)
                index = index + 1
            end
            local lastColor = self.valueTransformations
            table.insert(lastColor, pHValue)
        end
        i = i + 1
    end
    self.regularLimeUsage = getXMLFloat(xmlFile, key .. ".valueTransformations#regularUsage") or 3000
    self.yieldCurve = AnimCurve.new(linearInterpolator1)
    local i = 0
    while true do
        local baseKey = string.format("%s.yieldMappings.yieldMapping(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local pHValue = getXMLInt(xmlFile, baseKey .. "#levelDifference") or 0
        local lastColor = {
            getXMLFloat(xmlFile, baseKey .. "#yieldFactor") or 1,
            ["time"] = pHValue
        }
        self.yieldCurve:addKeyframe(lastColor)
        i = i + 1
    end
    self.levelDifferenceColors = {}
    local i = 0
    while true do
        local baseKey = string.format("%s.levelDifferenceColors.levelDifferenceColor(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local pHValue = {
            ["levelDifference"] = getXMLInt(xmlFile, baseKey .. "#levelDifference") or 0,
            ["color"] = string.getVector(getXMLString(xmlFile, baseKey .. "#color"), 3) or { 0, 0, 0 },
            ["colorBlind"] = string.getVector(getXMLString(xmlFile, baseKey .. "#colorBlind"), 3) or { 0, 0, 0 }
        }
        pHValue.color[4] = 1
        pHValue.colorBlind[4] = 1
        pHValue.additionalText = g_i18n:convertText(getXMLString(xmlFile, baseKey .. "#text"), PHMap.MOD_NAME)
        pHValue.showWarning = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#showWarning"), false)
        table.insert(self.levelDifferenceColors, pHValue)
        i = i + 1
    end
    self.limeUsage = {}
    self.limeUsage.usagePerState = getXMLFloat(xmlFile, key .. ".limeUsage#usagePerState") or 730
    local pHValue = self.regularLimeUsage / self.limeUsage.usagePerState
    self.stateChangeDefault = math.ceil(pHValue)
    self.minimapGradientLabelName = string.format("pH %.2f - %.2f", self:getMinMaxValue())
    self.coverMap = g_precisionFarming.coverMap
    self.soilMap = g_precisionFarming.soilMap
    return true
end
function PHMap:addSetInitialState(multiModifier, soilBitVector, soilTypeFirstChannel, soilTypeNumChannels, farmlandMask)
    local functionData = self.densityMapModifiersInitialize
    local modifier = functionData.modifier
    local pHFilter = functionData.pHFilter
    local soilFilter = functionData.soilFilter
    local noiseFilter = functionData.noiseFilter
    local pHInitModifier = functionData.pHInitModifier
    if modifier == nil or (pHFilter == nil or (soilFilter == nil or (noiseFilter == nil or (pHInitModifier == nil or functionData.pHInitMaskFilter == nil)))) then
        functionData.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
        modifier = functionData.modifier
        functionData.pHFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        functionData.pHFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.maxValue)
        pHFilter = functionData.pHFilter
        functionData.soilFilter = DensityMapFilter.new(soilBitVector, soilTypeFirstChannel, soilTypeNumChannels)
        soilFilter = functionData.soilFilter
        functionData.noiseFilter = DensityMapFilter.new(self.bitVectorMapNoise, 0, self.noiseNumChannels)
        noiseFilter = functionData.noiseFilter
        functionData.pHInitModifier = DensityMapModifier.new(self.bitVectorMapPHInitMask, 0, 1, g_terrainNode)
        local pHInitModifier = functionData.pHInitModifier
        functionData.pHInitMaskFilter = DensityMapFilter.new(self.bitVectorMapPHInitMask, 0, 1)
        functionData.pHInitMaskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
    end
    local i = 1
    for i = i, #self.valueTransformations do
        local valueTransformation = self.valueTransformations[i]
        soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, valueTransformation.soilTypeIndex - 1)
        if farmlandMask == nil then
            multiModifier:addExecuteSet(self.maxValue, modifier, soilFilter)
        else
            multiModifier:addExecuteSet(self.maxValue, modifier, soilFilter, farmlandMask)
        end
        local j = 1
        for j = j, self.noiseMaxValue + 1 do
            noiseFilter:setValueCompareParams(DensityValueCompareType.EQUAL, j - 1)
            multiModifier:addExecuteSet(valueTransformation.baseRange[j], modifier, pHFilter, noiseFilter)
        end
    end
end
function PHMap:harvestUpdate(filter, _, densityMapShape, _, _)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
        local functionData = self.densityMapModifiersHarvestMulti
        if functionData == nil then
            functionData = {
                ["modifier"] = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
            }
            functionData.modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
            functionData.soilFilter = DensityMapFilter.new(soilMap.bitVectorMap, soilMap.typeFirstChannel, soilMap.typeNumChannels)
            functionData.phFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
            functionData.phFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue)
            functionData.modifierTempLock = DensityMapModifier.new(self.bitVectorMapPHStateChange, 0, 1, g_terrainNode)
            functionData.modifierTempLock:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
            functionData.tempLockFilter = DensityMapFilter.new(self.bitVectorMapPHStateChange, 0, 1)
            functionData.tempLockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
            functionData.multiModifier = DensityMapMultiModifier.new()
            local i = 1
            for i = i, #self.valueTransformations do
                local valueTransformation = self.valueTransformations[i]
                functionData.soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, valueTransformation.soilTypeIndex - 1)
                local j = 1
                for j = j, #valueTransformation.decreasePerHarvest do
                    local decreasePerHarvest = valueTransformation.decreasePerHarvest[j]
                    if decreasePerHarvest.range == nil then
                        functionData.phFilter:setValueCompareParams(DensityValueCompareType.GREATER, 1)
                        functionData.multiModifier:addExecuteAddWithStats(tostring(i), -decreasePerHarvest.decreaseValue, functionData.modifier, filter, functionData.soilFilter, functionData.phFilter)
                    else
                        functionData.phFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, math.max(decreasePerHarvest.range[1] - 1), decreasePerHarvest.range[2] + 1)
                        functionData.multiModifier:addExecuteAddWithStats(tostring(i), -decreasePerHarvest.decreaseValue, functionData.modifier, filter, functionData.soilFilter, functionData.phFilter)
                    end
                end
            end
            functionData.accumulators = {}
            functionData.numChangedPixels = {}
            functionData.totalNumPixels = {}
            self.densityMapModifiersHarvestMulti = functionData
        end
        local multiModifier = functionData.multiModifier
        densityMapShape:applyToModifier(multiModifier)
        local accumulators = functionData.accumulators
        local i = functionData.numChangedPixels
        local valueTransformation = functionData.totalNumPixels
        multiModifier:resetStats()
        multiModifier:execute(accumulators, i, valueTransformation)
        local pHMapChanged = false
        for indexStr, accumulator in pairs(accumulators) do
            if accumulator > 0 then
                local index = tonumber(indexStr)
                local valueTransformation = self.valueTransformations[index]
                self.lastActualValue = accumulator / i[indexStr]
                self.lastTargetValue = valueTransformation.optimalValue
                self.lastRegularValue = valueTransformation.optimalValue - valueTransformation.decreasePerHarvest[1].decreaseValue * 1.5 * valueTransformation.regularOffset
                pHMapChanged = true
            end
        end
        if pHMapChanged then
            self:setMinimapRequiresUpdate(true)
        end
        return pHMapChanged
    end
end
function PHMap:getSprayFunctionData()
    local functionData = self.densityMapModifiersSpray
    if functionData == nil then
        functionData = {}
        local soilMap = self.soilMap
        functionData.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
        functionData.soilFilter = DensityMapFilter.new(soilMap.bitVectorMap, soilMap.typeFirstChannel, soilMap.typeNumChannels)
        functionData.phFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        functionData.phFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
        functionData.phFilterMax = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        functionData.phFilterMax:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
        functionData.modifierLock = DensityMapModifier.new(self.bitVectorMapPHStateChange, 1, 1, g_terrainNode)
        functionData.lockFilter = DensityMapFilter.new(self.bitVectorMapPHStateChange, 1, 1)
        functionData.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
        self.densityMapModifiersSpray = functionData
    end
    return functionData
end
function PHMap:preUpdatePHLevelAtArea(densityMapShape, sprayTypeIndex, _)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
        local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
        if sprayTypeDesc ~= nil then
            local functionData = self:getSprayFunctionData()
            local modifierLock = functionData.modifierLock
            local sprayTypeFilter = functionData.sprayTypeFilter
            densityMapShape:applyToModifier(modifierLock)
            sprayTypeFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
            sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sprayTypeDesc.sprayGroundType)
            modifierLock:executeSet(0)
            modifierLock:executeSet(1, sprayTypeFilter)
        end
    end
end
function PHMap:addPHLevelAtArea(densityMapShape, sprayTypeIndex, delta, ignoreLock)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and (soilMap.bitVectorMap ~= nil and g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil))) then
        local functionData = self:getSprayFunctionData()
        local modifier = functionData.modifier
        local modifierLock = functionData.modifierLock
        local lockFilter = functionData.lockFilter
        densityMapShape:applyToModifier(modifier)
        densityMapShape:applyToModifier(modifierLock)
        if ignoreLock then
            lockFilter = nil
        end
        local _, numChangedPixels, _ = modifier:executeAddWithStats(delta, lockFilter)
        modifier:executeSet(self.maxVisibleValue, functionData.phFilterMax)
        modifierLock:executeSet(1, lockFilter)
        if numChangedPixels > 0 then
            self:setMinimapRequiresUpdate(true)
        end
        return numChangedPixels
    end
end
function PHMap:updatePHLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock)
    local coverMap = math.min(targetLevel, self.maxValue)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and (soilMap.bitVectorMap ~= nil and g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil))) then
        local functionData = self:getSprayFunctionData()
        local modifier = functionData.modifier
        local modifierLock = functionData.modifierLock
        local phFilter = functionData.phFilter
        local lockFilter = functionData.lockFilter
        densityMapShape:applyToModifier(modifier)
        densityMapShape:applyToModifier(modifierLock)
        if ignoreLock then
            lockFilter = nil
        end
        phFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, coverMap - 1)
        local _, numChangedPixels, _ = modifier:executeSetWithStats(coverMap, phFilter, lockFilter)
        modifierLock:executeSet(1, lockFilter)
        if numChangedPixels > 0 then
            self:setMinimapRequiresUpdate(true)
        end
        return numChangedPixels
    end
end
function PHMap:setPHLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock)
    local functionData = self.maxValue
    local coverMap = math.clamp(targetLevel, 0, functionData)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and (soilMap.bitVectorMap ~= nil and g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil))) then
        local functionData = self:getSprayFunctionData()
        local modifier = functionData.modifier
        local modifierLock = functionData.modifierLock
        local phFilter = functionData.phFilter
        local lockFilter = functionData.lockFilter
        densityMapShape:applyToModifier(modifier)
        densityMapShape:applyToModifier(modifierLock)
        if ignoreLock then
            lockFilter = nil
        end
        local _, numChangedPixels, _ = modifier:executeSetWithStats(coverMap, lockFilter)
        modifierLock:executeSet(1, lockFilter)
        if numChangedPixels > 0 then
            self:setMinimapRequiresUpdate(true)
        end
        return numChangedPixels
    end
end
function PHMap:getLevelAtWorldPos(x, z)
    x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
    z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
    return not self.coverMap:getIsUncoveredAtPos(x, z) and 0 or getBitVectorMapPoint(self.bitVectorMap, x, z, self.firstChannel, self.numChannels)
end
function PHMap:getIsLockedAtWorldPos(wx, wz, sprayTypeIndex)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
        local modifierLock = self.densityMapModifiersLockedState.modifierLock
        local sprayTypeFilter = self.densityMapModifiersLockedState.sprayTypeFilter
        local coverMaskFilter = self.densityMapModifiersLockedState.coverMaskFilter
        if modifierLock == nil or (sprayTypeFilter == nil or coverMaskFilter == nil) then
            self.densityMapModifiersLockedState.modifierLock = DensityMapModifier.new(self.bitVectorMapPHStateChange, 1, 1, g_terrainNode)
            self.densityMapModifiersLockedState.modifierLock:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
            local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
            self.densityMapModifiersLockedState.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
            self.densityMapModifiersLockedState.sprayTypeFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ALL)
            self.densityMapModifiersLockedState.coverMaskFilter = DensityMapFilter.new(coverMap.bitVectorMap, coverMap.firstChannel, coverMap.numChannels)
            self.densityMapModifiersLockedState.coverMaskFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
        end
        local fieldGroundSystem = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
        if fieldGroundSystem ~= nil then
            modifierLock:setParallelogramWorldCoords(wx, wz, wx + 0.001, wz, wx, wz + 0.001, DensityCoordType.POINT_POINT_POINT)
            sprayTypeFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, fieldGroundSystem.sprayGroundType)
            local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = modifierLock:executeGet(coverMaskFilter, sprayTypeFilter)
            return sprayTypeFirstChannel == 0
        end
    end
    return false
end
function PHMap:getNextValidDetectionPoint(wx, wz, dirX, dirZ, maxDistance, sprayTypeIndex)
    local distance, foundUncovered = ValueMap.roundToPixelCenter(wx, wz, g_currentMission.terrainSize, self.sizeX)
    local distance
    if math.abs(dirX) > math.abs(dirZ) then
        dirX = math.sign(dirX)
        distance = 0
    else
        dirX = 0
        distance = math.sign(dirZ)
    end
    local distance = g_currentMission.terrainSize / self.sizeX
    local foundUncovered = false
    for i = 1, math.ceil(maxDistance / distance) do
        if self.coverMap:getIsUncoveredAtPos(distance, foundUncovered, true) then
            foundUncovered = true
            if not self:getIsLockedAtWorldPos(distance, foundUncovered, sprayTypeIndex) then
                return distance, foundUncovered, true
            end
        end
        distance = distance + dirX * distance
        foundUncovered = foundUncovered + distance * distance
    end
    return nil, nil, foundUncovered
end
function PHMap:getLimeUsage(workingWidth, lastSpeed, statesChanged, dt)
    local literPerHectar = self:getLimeUsageByStateChange(statesChanged)
    return literPerHectar * (lastSpeed / 3600) / (10000 / workingWidth) * dt, literPerHectar, self.regularLimeUsage * (lastSpeed / 3600) / (10000 / workingWidth) * dt
end
function PHMap:getLimeUsageByStateChange(statesChanged)
    return self.limeUsage.usagePerState * statesChanged
end
function PHMap:getDefaultLimeStateChange()
    return self.stateChangeDefault
end
function PHMap:getPhValueFromChangedStates(statesChanged)
    return statesChanged * self.pHValuePerState
end
function PHMap:getPhValueFromInternalValue(internal)
    local i = 1
    for i = i, #self.pHValues do
        local pHValue = self.pHValues[i]
        if pHValue.value == math.floor(internal) then
            return pHValue.realValue
        end
    end
    return 0
end
function PHMap:getNearestPhValueFromValue(value)
    local minDifference = 100
    local minValue = 0
    local minValueInternal = 0
    if value > 0 then
        local i = 1
        for i = i, #self.pHValues do
            local pHValue = self.pHValues[i].realValue
            local difference = math.abs(value - pHValue)
            if difference < minDifference then
                minValueInternal = self.pHValues[i].value
                minValue = pHValue
                minDifference = difference
            end
        end
    end
    return minValue, minValueInternal
end
function PHMap:getOptimalPHValueForSoilTypeIndex(soilTypeIndex)
    local i = 1
    for i = i, #self.valueTransformations do
        local valueTransformation = self.valueTransformations[i]
        if valueTransformation.soilTypeIndex == soilTypeIndex then
            return valueTransformation.optimalValue
        end
    end
    return 0
end
function PHMap:getMinMaxValue()
    if #self.pHValues > 0 then
        return self.pHValues[1].realValue, self.pHValues[#self.pHValues].realValue, #self.pHValues
    else
        return 0, 1, 0
    end
end
function PHMap:updateLastPhValues()
    self.lastActualValue = -1
    self.lastTargetValue = -1
    self.lastRegularValue = -1
    return self.lastActualValue, self.lastTargetValue, self.lastRegularValue
end
function PHMap:getYieldFactorByLevelDifference(difference)
    return self.yieldCurve:get(difference)
end
function PHMap:buildOverlay(overlay, filter, isColorBlindMode, _)
    resetDensityMapVisualizationOverlay(overlay)
    setOverlayColor(overlay, 1, 1, 1, 1)
    local coverMap = self.coverMap
    if coverMap ~= nil then
        local coverMask = bit32.lshift(2 ^ (coverMap.numChannels - 1) - 1, 1)
        local i = 1
        for i = i, #self.pHValues do
            local pHValue = self.pHValues[i]
            if pHValue.color ~= nil and filter[pHValue.filterIndex] then
                local color = pHValue.color
                if isColorBlindMode then
                    color = pHValue.colorBlind or pHValue.color
                end
                setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, coverMap.bitVectorMap, coverMask, self.firstChannel, self.numChannels, pHValue.value, color[1], color[2], color[3])
            end
        end
    end
end
function PHMap:getDisplayValues()
    if self.valuesToDisplay == nil then
        self.valuesToDisplay = {}
        local i = 1
        local yieldValueToDisplay = #self.pHValuesToDisplay
        for i = i, yieldValueToDisplay do
            local pHValue = self.pHValuesToDisplay[i]
            local yieldValueToDisplay = {
                ["colors"] = {}
            }
            yieldValueToDisplay.colors[true] = { pHValue.colorBlind or pHValue.color }
            yieldValueToDisplay.colors[false] = { pHValue.color }
            yieldValueToDisplay.description = string.format("%.2f", pHValue.realValue)
            table.insert(self.valuesToDisplay, yieldValueToDisplay)
        end
        local yieldValueToDisplay = {
            ["colors"] = {}
        }
        yieldValueToDisplay.colors[true] = {
            { 0, 0, 0 }
        }
        yieldValueToDisplay.colors[false] = {
            { 0, 0, 0 }
        }
        yieldValueToDisplay.description = self.outdatedLabel
        local i = self.valuesToDisplay
        table.insert(i, yieldValueToDisplay)
    end
    return self.valuesToDisplay
end
function PHMap:getValueFilter()
    if self.valueFilter == nil or self.valueFilterEnabled == nil then
        self.valueFilter = {}
        self.valueFilterEnabled = {}
        local numValues = #self.pHValuesToDisplay
        local i = 1
        for i = i, numValues + 1 do
            table.insert(self.valueFilter, true)
            table.insert(self.valueFilterEnabled, i <= numValues)
        end
    end
    return self.valueFilter, self.valueFilterEnabled
end
function PHMap:getMinimapZoomFactor()
    return 3
end
function PHMap:collectFieldInfos(fieldInfoDisplayExtension)
    fieldInfoDisplayExtension:addFieldInfo(g_i18n:getText("fieldInfo_phValue", PHMap.MOD_NAME), self, self.updateFieldInfoDisplay, 2, self.getFieldInfoYieldChange)
end
function PHMap:getAllowCoverage()
    return true
end
function PHMap:getHelpLinePage()
    return 4
end
function PHMap:updateFieldInfoDisplay(fieldInfo, x, z, isColorBlindMode)
    local phLevel = self:getLevelAtWorldPos(x, z)
    local soilTypeIndex = self.soilMap:getTypeIndexAtWorldPos(x, z)
    local i = 1
    for i = i, #self.valueTransformations do
        local valueTransformation = self.valueTransformations[i]
        if valueTransformation.soilTypeIndex == soilTypeIndex then
            local color = nil
            local additionalText = nil
            local showWarning = nil
            local levelDifference = math.abs(valueTransformation.optimalValue - phLevel)
            local j = 1
            for j = j, #self.levelDifferenceColors do
                local levelDifferenceColor = self.levelDifferenceColors[j]
                if levelDifferenceColor.levelDifference <= levelDifference then
                    if isColorBlindMode then
                        color = levelDifferenceColor.colorBlind
                    else
                        color = levelDifferenceColor.color
                    end
                    additionalText = levelDifferenceColor.additionalText
                    showWarning = levelDifferenceColor.showWarning
                end
            end
            fieldInfo.pHFactor = self:getYieldFactorByLevelDifference(phLevel - valueTransformation.optimalValue)
            return string.format("%.3f / %.3f", self:getPhValueFromInternalValue(phLevel), self:getPhValueFromInternalValue(valueTransformation.optimalValue)), color, additionalText, showWarning
        end
    end
    return nil
end
function PHMap.getFieldInfoYieldChange(_, fieldInfo)
    return fieldInfo.pHFactor or 0, 0.2
end
function PHMap:drawYieldDebug(pHActualValue, pHTargetValue)
    if self.debugGraph == nil then
        self.debugGraph = Graph.new(#self.yieldCurve.keyframes, 0.45, 0.05, 0.2, 0.15, 0, 100, false, "%", Graph.STYLE_LINES)
        self.debugGraph:setHorizontalLine(10, true, 1, 1, 1, 1)
        self.debugGraph:setVerticalLine(0.1, false, 1, 1, 1, 1)
        self.debugGraph:setColor(0, 1, 0, 1)
    end
    local minTime = math.huge
    local maxTime = -math.huge
    local i = 1
    local x = #self.yieldCurve.keyframes
    for i = i, x do
        local keyframe = self.yieldCurve.keyframes[i]
        local value = self.yieldCurve:get(keyframe.time)
        self.debugGraph:setValue(i, value * 100)
        minTime = math.min(keyframe.time, minTime)
        maxTime = math.max(keyframe.time, maxTime)
    end
    self.debugGraph:draw()
    if minTime ~= math.huge then
        local x = self.debugGraph.left + MathUtil.inverseLerp(minTime, maxTime, pHActualValue - pHTargetValue) * self.debugGraph.width
        setOverlayColor(self.debugGraph.overlayHLine, 1, 0, 0, 1)
        renderOverlay(self.debugGraph.overlayHLine, x, self.debugGraph.bottom, g_pixelSizeX, self.debugGraph.height)
        setOverlayColor(self.debugGraph.overlayHLine, 1, 1, 1, 1)
    end
end
function PHMap:debugSetPHLevel(fieldId, pHLevel)
    local field = tonumber(fieldId)
    local field = tonumber(pHLevel)
    if field == nil or field == nil then
        Logging.error("PHMap: Invalid parameters. Usage: pfPHSetLevel <fieldId> <pHLevel>")
    else
        local field = g_fieldManager:getFieldById((tonumber(field)))
        if field ~= nil and field.getDensityMapPolygon ~= nil then
            local area = field:getDensityMapPolygon()
            local _, targetLevel = self:getNearestPhValueFromValue(field)
            self:setPHLevelAtArea(area, SprayType.LIME, targetLevel, true)
            Logging.info("PHMap: Set pH level of field %d to %.1f", field, field)
        end
    end
end
function PHMap:onRealisticSpreadPatternSettingChanged(value)
    self.realisticSpreadPatternEnabled = value
end
function PHMap:onRealisticSpreadOutputSettingChanged(value)
    self.realisticSpreadOutputEnabled = value
end
function PHMap:overwriteGameFunctions(pfModule)
    PHMap:superClass().overwriteGameFunctions(self, pfModule)
end