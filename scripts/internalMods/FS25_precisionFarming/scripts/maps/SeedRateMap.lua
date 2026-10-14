SeedRateMap = {}
SeedRateMap.MOD_NAME = g_currentModName
local SeedRateMap_mt = Class(SeedRateMap, ValueMap)
function SeedRateMap.new(pfModule, customMt)
    -- upvalues: (copy) SeedRateMap_mt
    local self = ValueMap.new(pfModule, customMt or SeedRateMap_mt)
    self.filename = "precisionFarming_seedRateMap.grle"
    self.name = "seedRateMap"
    self.id = "SEED_RATE_MAP"
    self.label = "ui_mapOverviewSeedRate"
    self.texts = {}
    self.texts.cropNameHeader = g_i18n:getText("ui_cropName", SeedRateMap.MOD_NAME)
    self.texts.cropType1 = g_i18n:getText("ui_soilType_1", SeedRateMap.MOD_NAME)
    self.texts.cropType2 = g_i18n:getText("ui_soilType_2", SeedRateMap.MOD_NAME)
    self.texts.cropType3 = g_i18n:getText("ui_soilType_3", SeedRateMap.MOD_NAME)
    self.texts.cropType4 = g_i18n:getText("ui_soilType_4", SeedRateMap.MOD_NAME)
    self.densityMapModifiersSeedUpdate = {}
    self.densityMapModifiersHarvestMulti = nil
    self.densityMapModifiersClear = nil
    if g_server ~= nil then
        addConsoleCommand("pfSeedRateSet", "Sets the given seed rate on the given field", "debugSetSeedRateLevel", self, "fieldId; seedRate")
    end
    return self
end
function SeedRateMap:initialize()
    SeedRateMap:superClass().initialize(self)
    self.densityMapModifiersSeedUpdate = {}
    self.densityMapModifiersHarvestMulti = nil
    self.densityMapModifiersClear = nil
end
function SeedRateMap:delete()
    if g_server ~= nil then
        removeConsoleCommand("pfSeedRateSet")
    end
    SeedRateMap:superClass().delete(self)
end
function SeedRateMap:loadFromXML(xmlFile, key, _, _, _)
    key = key .. ".seedRateMap"
    self.numChannels = getXMLInt(xmlFile, key .. ".bitVectorMap#numChannels") or 2
    self.maxValue = 2 ^ self.numChannels - 1
    self.sizeX = getXMLInt(xmlFile, key .. ".bitVectorMap#sizeX") or 1024
    self.sizeY = getXMLInt(xmlFile, key .. ".bitVectorMap#sizeY") or 1024
    self.bitVectorMap = self:loadSavedBitVectorMap("SeedRateMap", self.filename, self.numChannels, self.sizeX)
    if g_maxModDescVersion > 64 then
        self:addBitVectorMapToSync(self.bitVectorMap)
    end
    self:addBitVectorMapToSave(self.bitVectorMap, self.filename)
    self:addBitVectorMapToDelete(self.bitVectorMap)
    self.rateValues = {}
    local i = 0
    while true do
        local baseKey = string.format("%s.rateValues.rateValue(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local rateValue = {
            ["value"] = getXMLInt(xmlFile, baseKey .. "#value") or 0,
            ["text"] = g_i18n:convertText(getXMLString(xmlFile, baseKey .. "#text"), SeedRateMap.MOD_NAME),
            ["color"] = string.getVector(getXMLString(xmlFile, baseKey .. "#color"), 3) or { 0, 0, 0 },
            ["colorBlind"] = string.getVector(getXMLString(xmlFile, baseKey .. "#colorBlind"), 3)
        }
        table.insert(self.rateValues, rateValue)
        i = i + 1
    end
    self.defaultSeedRate = MathUtil.round(#self.rateValues * 0.5)
    self.fruitTypes = {}
    self:loadFruitTypeSeedRatesFromXML(xmlFile, key)
    local baseKey = g_currentMission.missionInfo
    local rateValue = Utils.getFilename(baseKey.mapXMLFilename, g_currentMission.baseDirectory)
    local mapXMLFile = loadXMLFile("MapXML", rateValue)
    if mapXMLFile ~= nil then
        self:loadFruitTypeSeedRatesFromXML(mapXMLFile, "map.precisionFarming.seedRateMap")
        delete(mapXMLFile)
    end
    self.coverMap = g_precisionFarming.coverMap
    return true
end
function SeedRateMap:loadFruitTypeSeedRatesFromXML(xmlFile, key)
    local i = 0
    while true do
        local baseKey = string.format("%s.fruitTypes.fruitType(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local fruitTypeName = getXMLString(xmlFile, baseKey .. "#name")
        if fruitTypeName ~= nil then
            local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
            if fruitTypeDesc ~= nil then
                local fruitType = {
                    ["index"] = fruitTypeDesc.index,
                    ["seedRates"] = self:getRateValues(xmlFile, baseKey .. ".seedRates#rates", #self.rateValues),
                    ["seedUsages"] = self:getRateValues(xmlFile, baseKey .. ".seedRates#usages", #self.rateValues)
                }
                if fruitType.seedRates == nil or fruitType.seedUsages == nil then
                    Logging.warning("Invalid seed rates or usages in \'%s\'", baseKey)
                else
                    fruitType.soilTypes = {}
                    local soilTypeIndex = 0
                    while true do
                        local soilKey = string.format("%s.soilTypes.soilType(%d)", baseKey, soilTypeIndex)
                        if not hasXMLProperty(xmlFile, soilKey) then
                            break
                        end
                        local soilType = {
                            ["index"] = getXMLInt(xmlFile, soilKey .. "#index") or 1,
                            ["yields"] = self:getRateValues(xmlFile, soilKey .. "#yields", #self.rateValues)
                        }
                        if soilType.yields == nil then
                            Logging.warning("Invalid yield definitions in \'%s\'", soilKey)
                        else
                            soilType.bestYieldIndex = 1
                            local maxYield = 0
                            local j = 1
                            for j = j, #soilType.yields do
                                if maxYield < soilType.yields[j] then
                                    maxYield = soilType.yields[j]
                                    soilType.bestYieldIndex = j
                                end
                            end
                            fruitType.soilTypes[soilType.index] = soilType
                        end
                        soilTypeIndex = soilTypeIndex + 1
                    end
                    self.fruitTypes[fruitTypeDesc.index] = fruitType
                end
            end
        end
        i = i + 1
    end
end
function SeedRateMap.getRateValues(_, xmlFile, key, numValues)
    local values = getXMLString(xmlFile, key):split(" ")
    if #values ~= numValues then
        return nil
    end
    local i = 1
    for i = i, #values do
        values[i] = tonumber(values[i])
    end
    return values
end
function SeedRateMap:getRateLabelByIndex(index)
    local rate = self.rateValues[index]
    return rate == nil and "unknown" or rate.text
end
function SeedRateMap:update(dt) end
function SeedRateMap:updateSeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitTypeIndex, autoMode, manualSeedRate)
    local soilMap = self.pfModule.soilMap
    if soilMap ~= nil then
        local modifier = self.densityMapModifiersSeedUpdate.modifier
        local maskFilter = self.densityMapModifiersSeedUpdate.maskFilter
        local soilFilter = self.densityMapModifiersSeedUpdate.soilFilter
        if modifier == nil or (maskFilter == nil or soilFilter == nil) then
            self.densityMapModifiersSeedUpdate.modifier = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
            modifier = self.densityMapModifiersSeedUpdate.modifier
            local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
            self.densityMapModifiersSeedUpdate.maskFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
            self.densityMapModifiersSeedUpdate.maskFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
            self.densityMapModifiersSeedUpdate.soilFilter = DensityMapFilter.new(soilMap.bitVectorMap, soilMap.typeFirstChannel, soilMap.typeNumChannels)
            soilFilter = self.densityMapModifiersSeedUpdate.soilFilter
        end
        if type(startWorldX) == "number" then
            modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        elseif type(startWorldX) == "table" then
            startWorldX:applyToModifier(modifier)
        end
        local fieldGroundSystem = self.fruitTypes[fruitTypeIndex]
        if fieldGroundSystem == nil then
            if autoMode then
                modifier:executeSet(self.defaultSeedRate, maskFilter)
            else
                modifier:executeSet(manualSeedRate, maskFilter)
            end
        else
            if not autoMode then
                modifier:executeSet(manualSeedRate, maskFilter)
                return fieldGroundSystem.seedUsages[manualSeedRate], fieldGroundSystem.seedRates[manualSeedRate], manualSeedRate
            end
            local groundTypeMapId = 0
            local groundTypeFirstChannel = 0
            local groundTypeNumChannels = 0
            local seedRateIndexSum = 0
            for soilTypeIndex, soilTypeData in pairs(fieldGroundSystem.soilTypes) do
                if soilTypeData.bestYieldIndex ~= nil then
                    soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, soilTypeIndex - 1)
                    local _, numPixels, _ = modifier:executeSetWithStats(soilTypeData.bestYieldIndex, maskFilter, soilFilter)
                end
            end
            if groundTypeMapId > 0 then
                return groundTypeFirstChannel / groundTypeMapId, groundTypeNumChannels / groundTypeMapId, MathUtil.round(seedRateIndexSum / groundTypeMapId)
            end
        end
    end
    return 0
end
function SeedRateMap:harvestUpdate(_, fruitIndex, densityMapShape, _, _)
    local soilMap = self.pfModule.soilMap
    if soilMap ~= nil and soilMap.bitVectorMap ~= nil then
        local functionData = self.densityMapModifiersHarvestMulti
        if functionData == nil then
            functionData = {
                ["modifier"] = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
            }
            functionData.modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
            functionData.soilFilter = DensityMapFilter.new(soilMap.bitVectorMap, soilMap.typeFirstChannel, soilMap.typeNumChannels)
            functionData.multiModifiersByFruitIndex = {}
            functionData.accumulators = {}
            functionData.numChangedPixels = {}
            functionData.totalNumPixels = {}
            self.densityMapModifiersHarvestMulti = functionData
        end
        local fruitTypeData = self.fruitTypes[fruitIndex]
        if fruitTypeData == nil then
            self.lastSeedRateMultiplier = 1
            return
        end
        local multiModifier = functionData.multiModifiersByFruitIndex[fruitIndex]
        if multiModifier == nil then
            multiModifier = DensityMapMultiModifier.new()
            functionData.multiModifiersByFruitIndex[fruitIndex] = multiModifier
            for soilTypeIndex, soilTypeData in pairs(fruitTypeData.soilTypes) do
                if soilTypeData.bestYieldIndex ~= nil then
                    functionData.soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, soilTypeIndex - 1)
                    multiModifier:addExecuteGet(tostring(soilTypeIndex), functionData.modifier, functionData.soilFilter)
                end
            end
        end
        densityMapShape:applyToModifier(multiModifier)
        local accumulators = functionData.accumulators
        local numChangedPixels = functionData.numChangedPixels
        local totalNumPixels = functionData.totalNumPixels
        multiModifier:resetStats()
        multiModifier:execute(accumulators, numChangedPixels, totalNumPixels)
        local soilTypeIndex = 0
        local soilTypeData = 0
        for indexStr, accumulator in pairs(accumulators) do
            if accumulator > 0 then
                local index = tonumber(indexStr)
                local soilTypeData = fruitTypeData.soilTypes[index]
                local state = MathUtil.round(accumulator / numChangedPixels[indexStr])
                if soilTypeData.yields[state] ~= nil then
                    self.lastSeedRateFound = state
                    self.lastSeedRateTarget = (soilTypeData + 1).bestYieldIndex
                end
            end
        end
        local yield = 1
        if soilTypeData > 0 then
            yield = soilTypeIndex / soilTypeData
        end
        self.lastSeedRateMultiplier = yield
    end
end
function SeedRateMap:addClearToMultiModifier(multiModifier, filter1, filter2)
    local functionData = self.densityMapModifiersClear
    if functionData == nil then
        functionData = {
            ["modifier"] = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
        }
        self.densityMapModifiersClear = functionData
    end
    multiModifier:addExecuteSet(0, functionData.modifier, filter1, filter2)
end
function SeedRateMap:getSeedRateAtWorldPosition(x, z)
    x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
    z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
    return not self.coverMap:getIsUncoveredAtPos(x, z) and 0 or getBitVectorMapPoint(self.bitVectorMap, x, z, 0, self.numChannels)
end
function SeedRateMap:getSeedRateYieldFactor(rawValue, fruitTypeIndex, soilTypeIndex)
    local fruitTypeData = self.fruitTypes[fruitTypeIndex]
    if fruitTypeData == nil then
        return 1, 1
    end
    local soilTypeData = fruitTypeData.soilTypes[soilTypeIndex]
    if soilTypeData == nil or soilTypeData.bestYieldIndex == nil then
        return 1, 1
    end
    local seedRateIndex = nil
    local i = 1
    for i = i, #self.rateValues do
        if self.rateValues[i].value == rawValue then
            seedRateIndex = i
            break
        end
    end
    if seedRateIndex == nil or soilTypeData.yields[seedRateIndex] == nil then
        return 1, 1
    else
        return soilTypeData.yields[seedRateIndex], soilTypeData.yields[soilTypeData.bestYieldIndex]
    end
end
function SeedRateMap:debugSetSeedRateLevel(fieldId, seedRate)
    local field = tonumber(fieldId)
    local field = tonumber(seedRate)
    if field == nil or field == nil then
        Logging.error("SeedRateMap: Invalid parameters. Usage: pfSeedRateSet <fieldId> <seedRate>")
        return
    end
    local field = g_fieldManager:getFieldById((tonumber(field)))
    if field ~= nil and field.getDensityMapPolygon ~= nil then
        local area = field:getDensityMapPolygon()
        local seedRateDesc = nil
        local i = 1
        for i = i, #self.rateValues do
            if self.rateValues[i].value == field then
                seedRateDesc = self.rateValues[i]
                break
            end
        end
        if seedRateDesc ~= nil then
            self:updateSeedArea(area, nil, nil, nil, nil, nil, nil, false, seedRateDesc.value)
            Logging.info("SeedRateMap: Set seed rate of field %d to %d / %s", field, seedRateDesc.value, seedRateDesc.text)
            return
        end
        Logging.error("SeedRateMap: Invalid seed rate value %d", field)
    end
end
function SeedRateMap:updateLastYieldValues()
    self.lastSeedRateMultiplier = nil
    self.lastSeedRateFound = nil
    self.lastSeedRateTarget = nil
    return self.lastSeedRateMultiplier, self.lastSeedRateFound, self.lastSeedRateTarget
end
function SeedRateMap:buildOverlay(overlay, seedRateFilter, isColorBlindMode)
    resetDensityMapVisualizationOverlay(overlay)
    setOverlayColor(overlay, 1, 1, 1, 1)
    local i = 1
    for i = i, #self.rateValues do
        if seedRateFilter[i] then
            local rateValue = self.rateValues[i]
            local r, g, b
            if isColorBlindMode then
                r = rateValue.colorBlind[1]
                g = rateValue.colorBlind[2]
                b = rateValue.colorBlind[3]
            else
                r = rateValue.color[1]
                g = rateValue.color[2]
                b = rateValue.color[3]
            end
            setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, 0, self.numChannels, rateValue.value, r, g, b)
        end
    end
end
function SeedRateMap:getDisplayValues()
    if self.valuesToDisplay == nil then
        self.valuesToDisplay = {}
        local i = 1
        for i = i, #self.rateValues do
            local rateValue = self.rateValues[i]
            local rateValueToDisplay = {
                ["colors"] = {}
            }
            rateValueToDisplay.colors[true] = { rateValue.colorBlind or rateValue.color }
            rateValueToDisplay.colors[false] = { rateValue.color }
            rateValueToDisplay.description = rateValue.text
            table.insert(self.valuesToDisplay, rateValueToDisplay)
        end
    end
    return self.valuesToDisplay
end
function SeedRateMap:getValueFilter()
    if self.valueFilter == nil then
        self.valueFilter = {}
        for i = 1, #self.rateValues do
            table.insert(self.valueFilter, true)
        end
    end
    return self.valueFilter
end
function SeedRateMap:getHelpLinePage()
    return 7
end
function SeedRateMap:getSeedRateByFruitTypeAndIndex(fruitTypeIndex, seedRateIndex)
    if fruitTypeIndex ~= nil then
        local fruitTypeData = self.fruitTypes[fruitTypeIndex]
        if fruitTypeData ~= nil then
            return fruitTypeData.seedRates[seedRateIndex]
        end
    end
    return 0
end
function SeedRateMap:getIsFruitTypeSupported(fruitTypeIndex)
    if fruitTypeIndex == nil then
        return false
    end
    return self.fruitTypes[fruitTypeIndex] ~= nil
end
function SeedRateMap:getOptimalSeedRateByFruitTypeAndSoiltype(fruitTypeIndex, soilTypeIndex)
    if fruitTypeIndex ~= nil then
        local fruitTypeData = self.fruitTypes[fruitTypeIndex]
        if fruitTypeData ~= nil then
            local soilType = fruitTypeData.soilTypes[soilTypeIndex]
            if soilType ~= nil then
                return soilType.bestYieldIndex
            end
        end
    end
    return nil
end
function SeedRateMap:createHelpMenuSeedRateTableRow(contentBox, template, isHeader, cropName, text1, text2, text3, text4)
    local row = template:clone(contentBox)
    if self.rowIndex % 2 == 0 then
        row:getDescendantByName("background"):setVisible(false)
    end
    if isHeader then
        row:getDescendantByName("cropName"):applyProfile("precisionFarmingSeedRateTextHeader", true)
        row:getDescendantByName("soil1"):applyProfile("precisionFarmingSeedRateTextHeader", true)
        row:getDescendantByName("soil2"):applyProfile("precisionFarmingSeedRateTextHeader", true)
        row:getDescendantByName("soil3"):applyProfile("precisionFarmingSeedRateTextHeader", true)
        row:getDescendantByName("soil4"):applyProfile("precisionFarmingSeedRateTextHeader", true)
    end
    row:getDescendantByName("cropName"):setText(cropName)
    row:getDescendantByName("soil1"):setText(text1)
    row:getDescendantByName("soil2"):setText(text2)
    row:getDescendantByName("soil3"):setText(text3)
    row:getDescendantByName("soil4"):setText(text4)
    row:updateAbsolutePosition()
    self.rowIndex = self.rowIndex + 1
end
function SeedRateMap:createHelpMenuSeedRateTable(contentBox, template)
    self.rowIndex = 0
    self:createHelpMenuSeedRateTableRow(contentBox, template, true, self.texts.cropNameHeader, self.texts.cropType1, self.texts.cropType2, self.texts.cropType3, self.texts.cropType4)
    for _, fruitType in pairs(self.fruitTypes) do
        local fillType = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitType.index)
        if fillType ~= nil then
            local bestYieldText = {
                "",
                "",
                "",
                ""
            }
            local j = 1
            for j = j, #fruitType.soilTypes do
                local soilType = fruitType.soilTypes[j]
                if soilType.bestYieldIndex ~= nil then
                    bestYieldText[j] = self:getRateLabelByIndex(soilType.bestYieldIndex)
                end
            end
            self:createHelpMenuSeedRateTableRow(contentBox, template, false, fillType.title, unpack(bestYieldText))
        end
    end
    contentBox:invalidateLayout()
end