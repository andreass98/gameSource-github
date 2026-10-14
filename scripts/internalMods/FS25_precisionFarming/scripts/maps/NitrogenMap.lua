NitrogenMap = {}
NitrogenMap.MOD_NAME = g_currentModName
NitrogenMap.NUM_BITS = 6
NitrogenMap.DEBUG_N_OFFSET_MAP = false
local NitrogenMap_mt = Class(NitrogenMap, ValueMap)
function NitrogenMap.new(pfModule, customMt)
    -- upvalues: (copy) NitrogenMap_mt
    local self = ValueMap.new(pfModule, customMt or NitrogenMap_mt)
    self.name = "nitrogenMap"
    self.id = "N_MAP"
    self.label = "ui_mapOverviewNitrogen"
    self.densityMapModifiersInitialize = {}
    self.densityMapModifiersLockedState = {}
    self.densityMapModifiersSpray = nil
    self.densityMapModifiersDestroyFruit = {}
    self.densityMapModifiersStrawChopper = {}
    self.densityMapModifiersCropSensor = nil
    self.densityMapModifiersResetLock = {}
    self.densityMapModifiersFruitCheck = {}
    self.lastActualValue = -1
    self.lastTargetValue = -1
    self.lastYieldPotential = -1
    self.minimapGradientSliceId = "precisionFarming.gradient_red_green"
    self.minimapGradientColorBlindSliceId = "precisionFarming.gradient_color_blind"
    self.minimapLabelName = g_i18n:getText("ui_mapOverviewNitrogen", NitrogenMap.MOD_NAME)
    self.minimapLabelNameMission = g_i18n:getText("ui_growthMapFertilized")
    if g_server ~= nil then
        addConsoleCommand("pfNitrogenSet", "Sets the given nitrogen level on the given field", "debugSetNitrogenLevel", self, "fieldId; nitrogenLevel; [measured]")
    end
    return self
end
function NitrogenMap:initialize()
    NitrogenMap:superClass().initialize(self)
    self.densityMapModifiersInitialize = {}
    self.densityMapModifiersLockedState = {}
    self.densityMapModifiersSpray = nil
    self.densityMapModifiersDestroyFruit = {}
    self.densityMapModifiersStrawChopper = {}
    self.densityMapModifiersCropSensor = nil
    self.densityMapModifiersResetLock = {}
    self.densityMapModifiersFruitCheck = {}
    self.lastActualValue = -1
    self.lastTargetValue = -1
    self.lastYieldPotential = -1
end
function NitrogenMap:delete()
    if g_server ~= nil then
        removeConsoleCommand("pfNitrogenSet")
    end
    NitrogenMap:superClass().delete(self)
end
function NitrogenMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, _)
    key = key .. ".nitrogenMap"
    self.firstChannel = getXMLInt(xmlFile, key .. ".bitVectorMap#firstChannel") or 1
    self.numChannels = getXMLInt(xmlFile, key .. ".bitVectorMap#numChannels") or 4
    self.maxValue = getXMLInt(xmlFile, key .. ".bitVectorMap#maxValue") or 2 ^ self.numChannels - 1
    self.sizeX = 1024
    self.sizeY = 1024
    local i, baseKey = self:loadSavedBitVectorMap("nitrogenMap", "precisionFarming_nitrogenMap.grle", self.numChannels, self.sizeX)
    self.bitVectorMap = i
    self.newBitVectorMap = baseKey
    self:addBitVectorMapToSync(self.bitVectorMap)
    self:addBitVectorMapToSave(self.bitVectorMap, "precisionFarming_nitrogenMap.grle")
    self:addBitVectorMapToDelete(self.bitVectorMap)
    self.noiseFilename = getXMLString(xmlFile, key .. ".noiseMap#filename")
    self.noiseNumChannels = getXMLInt(xmlFile, key .. ".noiseMap#numChannels") or 2
    self.noiseResolution = getXMLInt(xmlFile, key .. ".noiseMap#resolution") or 1024
    self.noiseMaxValue = 2 ^ self.noiseNumChannels - 1
    self.bitVectorMapNoise = createBitVectorMap("nitrogenNoiseMap")
    if self.noiseFilename ~= nil then
        self.noiseFilename = Utils.getFilename(self.noiseFilename, baseDirectory)
        if not loadBitVectorMapFromFile(self.bitVectorMapNoise, self.noiseFilename, self.noiseNumChannels) then
            Logging.xmlWarning(xmlFile, "Error while loading pH noise map \'%s\'", self.noiseFilename)
            self.noiseFilename = nil
        end
    end
    if self.noiseFilename == nil then
        loadBitVectorMapNew(self.bitVectorMapNoise, self.noiseResolution, self.noiseResolution, self.noiseNumChannels, false)
    end
    self:addBitVectorMapToDelete(self.bitVectorMapNoise)
    local i, baseKey = self:loadSavedBitVectorMap("nOffsetMap", "precisionFarming_nOffsetMap.grle", 4, self.noiseResolution)
    self.bitVectorMapNOffset = i
    self.bitVectorMapNOffsetIsNew = baseKey
    self:addBitVectorMapToSave(self.bitVectorMapNOffset, "precisionFarming_nOffsetMap.grle")
    self:addBitVectorMapToDelete(self.bitVectorMapNOffset)
    self.nOffsetIndexToOffset = {}
    self.nOffsetIndexToOffset[1] = -5
    self.nOffsetIndexToOffset[2] = -4
    self.nOffsetIndexToOffset[3] = -3
    self.nOffsetIndexToOffset[4] = -2
    self.nOffsetIndexToOffset[5] = -1
    self.nOffsetIndexToOffset[6] = 0
    self.nOffsetIndexToOffset[7] = 1
    self.nOffsetIndexToOffset[8] = 2
    self.bitVectorMapNStateChange = self:loadSavedBitVectorMap("nLockStateMap", "precisionFarming_nLockStateMap.grle", 2, self.noiseResolution)
    self:addBitVectorMapToSave(self.bitVectorMapNStateChange, "precisionFarming_nLockStateMap.grle")
    self:addBitVectorMapToDelete(self.bitVectorMapNStateChange)
    self.bitVectorMapNInitMask = self:loadSavedBitVectorMap("nInitMaskMap", "nInitMaskMap.grle", 1, self.noiseResolution)
    self:addBitVectorMapToDelete(self.bitVectorMapNInitMask)
    self.bitVectorMapNFruitFilterMask = self:loadSavedBitVectorMap("nFruitFilterMask", "nFruitFilterMask.grle", 1, self.noiseResolution)
    self:addBitVectorMapToDelete(self.bitVectorMapNFruitFilterMask)
    self.bitVectorMapNFruitDestroyMask = self:loadSavedBitVectorMap("nFruitDestroyMask", "nFruitDestroyMask.grle", 2, self.noiseResolution)
    self:addBitVectorMapToDelete(self.bitVectorMapNFruitDestroyMask)
    self.bitVectorMapChoppedStrawMask = self:loadSavedBitVectorMap("choppedStrawMask", "choppedStrawMask.grle", 2, self.noiseResolution)
    self:addBitVectorMapToDelete(self.bitVectorMapChoppedStrawMask)
    self.amountPerState = getXMLFloat(xmlFile, key .. ".nitrogenValues#amountPerState") or 5
    self.nitrogenValues = {}
    self.numVisualValues = 0
    self.maxVisibleValue = 0
    local i = 0
    while true do
        local baseKey = string.format("%s.nitrogenValues.nitrogenValue(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        table.insert(self.nitrogenValues, {
            ["value"] = getXMLInt(xmlFile, baseKey .. "#value") or 0,
            ["realValue"] = getXMLFloat(xmlFile, baseKey .. "#realValue") or 0,
            ["showOnHud"] = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#showOnHud"), true),
            ["color"] = string.getVector(getXMLString(xmlFile, baseKey .. "#color"), 3),
            ["colorBlind"] = string.getVector(getXMLString(xmlFile, baseKey .. "#colorBlind"), 3)
        })
        nitrogenValue.index = #self.nitrogenValues
        nitrogenValue.filterIndex = self.numVisualValues + 1
        if nitrogenValue.showOnHud then
            self.numVisualValues = self.numVisualValues + 1
        end
        self.maxVisibleValue = math.max(self.maxVisibleValue, nitrogenValue.value)
        i = i + 1
    end
    local baseKey = nil
    local l = 1
    local nitrogenValue = #self.nitrogenValues
    local initialValue = 1
    for l = l, nitrogenValue, initialValue do
        local nitrogenValue = self.nitrogenValues[l]
        if nitrogenValue.showOnHud then
            baseKey = nitrogenValue
        elseif baseKey ~= nil then
            nitrogenValue.filterIndex = baseKey.filterIndex
            local nextOnHud = nil
            local j = l + 1
            local numValues = #self.nitrogenValues
            for j = j, numValues do
                local nextNitrogenValue = self.nitrogenValues[j]
                if nextNitrogenValue.showOnHud then
                    nextOnHud = nextNitrogenValue
                    break
                end
            end
            if nextOnHud ~= nil then
                local numValues = nextOnHud.index - baseKey.index
                nitrogenValue.color = { baseKey.color[1] + (nextOnHud.color[1] - baseKey.color[1]) / numValues * (l - baseKey.index), baseKey.color[2] + (nextOnHud.color[2] - baseKey.color[2]) / numValues * (l - baseKey.index), baseKey.color[3] + (nextOnHud.color[3] - baseKey.color[3]) / numValues * (l - baseKey.index) }
                nitrogenValue.colorBlind = { baseKey.colorBlind[1] + (nextOnHud.colorBlind[1] - baseKey.colorBlind[1]) / numValues * (l - baseKey.index), baseKey.colorBlind[2] + (nextOnHud.colorBlind[2] - baseKey.colorBlind[2]) / numValues * (l - baseKey.index), baseKey.colorBlind[3] + (nextOnHud.colorBlind[3] - baseKey.colorBlind[3]) / numValues * (l - baseKey.index) }
            end
        end
    end
    self.initialValues = {}
    local i = 0
    while true do
        if not hasXMLProperty(xmlFile, (string.format("%s.initialValues.initialValue(%d)", key, i))) then
            break
        end
        local initialValue = {
            ["soilTypeIndex"] = getXMLInt(xmlFile, nitrogenValue .. "#soilTypeIndex") or 1,
            ["baseRange"] = string.getVector(getXMLString(xmlFile, nitrogenValue .. "#baseValueRange"), self.noiseMaxValue + 1)
        }
        local nextOnHud = 1
        for nextOnHud = nextOnHud, #initialValue.baseRange do
            initialValue.baseRange[nextOnHud] = MathUtil.round(initialValue.baseRange[nextOnHud] / self.amountPerState)
        end
        table.insert(self.initialValues, initialValue)
        i = i + 1
    end
    self.initialSprayLevelBonus = string.getVector(getXMLString(xmlFile, key .. ".initialValues#sprayLevelBonus")) or { 0, 0 }
    local l = 1
    local nitrogenValue = #self.initialSprayLevelBonus
    local initialValue = 1
    for l = l, nitrogenValue, initialValue do
        self.initialSprayLevelBonus[l] = MathUtil.round(self.initialSprayLevelBonus[l] / self.amountPerState)
    end
    self.applicationRates = {}
    self:loadApplicationRatesFromXML(xmlFile, key)
    self.fertilizerUsage = {}
    self.fertilizerUsage.nAmounts = {}
    self:loadFertilizerUsageFromXML(xmlFile, key)
    self.fruitRequirements = {}
    self.fruitTypeIndexToFruitRequirement = {}
    self:loadFruitRequirementsFromXML(configFileName, xmlFile, key)
    self.cropSensorFruitTypes = {}
    self:loadCropSensorFruitTypesFromXML(configFileName, xmlFile, key)
    local nitrogenValue = g_currentMission.missionInfo
    local initialValue = Utils.getFilename(nitrogenValue.mapXMLFilename, g_currentMission.baseDirectory)
    local l = loadXMLFile("MapXML", initialValue)
    if l ~= nil then
        self:loadApplicationRatesFromXML(l, "map.precisionFarming")
        self:loadFertilizerUsageFromXML(l, "map.precisionFarming")
        self:loadFruitRequirementsFromXML(nitrogenValue.mapXMLFilename, l, "map.precisionFarming")
        self:loadCropSensorFruitTypesFromXML(nitrogenValue.mapXMLFilename, l, "map.precisionFarming")
        delete(l)
    end
    for r, j in ipairs(g_fruitTypeManager:getFruitTypes()) do
        if self.fruitTypeIndexToFruitRequirement[j.index] == nil then
            local nextNitrogenValue = {
                ["fruitTypeName"] = j.name,
                ["fruitType"] = j,
                ["bySoilType"] = self.fruitRequirements[1].bySoilType,
                ["averageTargetLevel"] = self.fruitRequirements[1].averageTargetLevel or 0
            }
            table.insert(self.fruitRequirements, nextNitrogenValue)
            self.fruitTypeIndexToFruitRequirement[j.index] = nextNitrogenValue
            Logging.devInfo("Use default Nitrogen requirements for fruitType \'%s\'", j.name)
        end
    end
    self.yieldCurve = AnimCurve.new(linearInterpolator1)
    local i = 0
    while true do
        local nitrogenValue = string.format("%s.yieldMappings.yieldMapping(%d)", key, i)
        if not hasXMLProperty(xmlFile, nitrogenValue) then
            break
        end
        local nextOnHud = (getXMLInt(xmlFile, nitrogenValue .. "#difference") or 0) / self.amountPerState
        local nextNitrogenValue = {
            getXMLFloat(xmlFile, nitrogenValue .. "#yieldFactor") or 1,
            ["time"] = nextOnHud
        }
        self.yieldCurve:addKeyframe(nextNitrogenValue)
        i = i + 1
    end
    self.levelDifferenceColors = {}
    local i = 0
    while true do
        local nitrogenValue = string.format("%s.levelDifferenceColors.levelDifferenceColor(%d)", key, i)
        if not hasXMLProperty(xmlFile, nitrogenValue) then
            break
        end
        local nextOnHud = {
            ["levelDifference"] = (getXMLInt(xmlFile, nitrogenValue .. "#levelDifference") or 0) / self.amountPerState,
            ["color"] = string.getVector(getXMLString(xmlFile, nitrogenValue .. "#color"), 3) or { 0, 0, 0 },
            ["colorBlind"] = string.getVector(getXMLString(xmlFile, nitrogenValue .. "#colorBlind"), 3) or { 0, 0, 0 }
        }
        nextOnHud.color[4] = 1
        nextOnHud.colorBlind[4] = 1
        nextOnHud.additionalText = g_i18n:convertText(getXMLString(xmlFile, nitrogenValue .. "#text"), NitrogenMap.MOD_NAME)
        nextOnHud.showWarning = Utils.getNoNil(getXMLBool(xmlFile, nitrogenValue .. "#showWarning"), false)
        table.insert(self.levelDifferenceColors, nextOnHud)
        i = i + 1
    end
    self.fertilizerColors = {
        [true] = {},
        [false] = {}
    }
    local nitrogenValue = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
    for j, nextNitrogenValue in pairs(MapOverlayGenerator.FRUIT_COLORS_FERTILIZED) do
        local i = #nextNitrogenValue
        for i = i, 1, -1 do
            table.insert(self.fertilizerColors[j], 1, nextNitrogenValue[i])
            if #self.fertilizerColors[j] == nitrogenValue then
                break
            end
        end
    end
    self.fertilizerFillTypes = {}
    for j, nextNitrogenValue in ipairs(self.applicationRates) do
        self.fertilizerFillTypes[nextNitrogenValue.fillTypeIndex] = nextNitrogenValue.fillTypeIndex
    end
    local numValues = (getXMLFloat(xmlFile, key .. ".applicationRates#defaultRate") or 100) / self.amountPerState
    self.stateChangeDefault = math.ceil(numValues)
    self.choppedStrawStateChange = (getXMLInt(xmlFile, key .. ".choppedStraw#increase") or 25) / self.amountPerState
    self.catchCropsStateChange = (getXMLInt(xmlFile, key .. ".catchCrops#increase") or 25) / self.amountPerState
    self.outdatedLabel = g_i18n:convertText(getXMLString(xmlFile, key .. ".texts#outdatedLabel") or "$l10n_ui_precisionFarming_outdatedData", NitrogenMap.MOD_NAME)
    self.minimapGradientLabelName = string.format("%d - %d kg/ha", self:getMinMaxValue())
    self.coverMap = g_precisionFarming.coverMap
    self.soilMap = g_precisionFarming.soilMap
    self.seedRateMap = g_precisionFarming.seedRateMap
    return true
end
function NitrogenMap:loadApplicationRatesFromXML(xmlFile, key)
    local i = 0
    while true do
        local baseKey = string.format("%s.applicationRates.applicationRate(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local fillTypeName = getXMLString(xmlFile, baseKey .. "#fillType")
        if fillTypeName == nil then
            Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen application rate \'%s\'", baseKey)
        else
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
            if fillTypeIndex == nil or fillTypeIndex == FillType.UNKNOWN then
                Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen application rate \'%s\'", baseKey)
            else
                local applicationRate = {
                    ["fillTypeIndex"] = fillTypeIndex,
                    ["autoAdjustToFruit"] = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#autoAdjustToFruit"), false),
                    ["regularRate"] = getXMLFloat(xmlFile, baseKey .. "#regularRate"),
                    ["ratesBySoilType"] = {}
                }
                local j = 0
                while true do
                    local soilKey = string.format("%s.soil(%d)", baseKey, j)
                    if not hasXMLProperty(xmlFile, soilKey) then
                        break
                    end
                    local rateBySoil = {
                        ["soilTypeIndex"] = getXMLInt(xmlFile, soilKey .. "#soilTypeIndex") or 1,
                        ["rate"] = (getXMLInt(xmlFile, soilKey .. "#rate") or 5) / self.amountPerState
                    }
                    table.insert(applicationRate.ratesBySoilType, rateBySoil)
                    j = j + 1
                end
                local applicationRateIndex = #self.applicationRates
                local soilKey = 1
                local rateBySoil = -1
                for applicationRateIndex = applicationRateIndex, soilKey, rateBySoil do
                    if self.applicationRates[applicationRateIndex].fillTypeIndex == applicationRate.fillTypeIndex then
                        table.remove(self.applicationRates, applicationRateIndex)
                    end
                end
                local rateBySoil = self.applicationRates
                table.insert(rateBySoil, applicationRate)
            end
        end
        i = i + 1
    end
end
function NitrogenMap:loadFertilizerUsageFromXML(xmlFile, key)
    local i = 0
    while true do
        local baseKey = string.format("%s.fertilizerUsage.nAmount(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local fillTypeName = getXMLString(xmlFile, baseKey .. "#fillType")
        if fillTypeName == nil then
            Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen fertilizer amount \'%s\'", baseKey)
        else
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
            if fillTypeIndex == nil or fillTypeIndex == FillType.UNKNOWN then
                Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen fertilizer amount \'%s\'", baseKey)
            else
                local nAmount = {
                    ["fillTypeIndex"] = fillTypeIndex,
                    ["amount"] = getXMLFloat(xmlFile, baseKey .. "#amount") or 1
                }
                local usageIndex = #self.fertilizerUsage.nAmounts
                for usageIndex = usageIndex, 1, -1 do
                    if self.fertilizerUsage.nAmounts[usageIndex].fillTypeIndex == nAmount.fillTypeIndex then
                        table.remove(self.fertilizerUsage.nAmounts, usageIndex)
                    end
                end
                table.insert(self.fertilizerUsage.nAmounts, nAmount)
            end
        end
        i = i + 1
    end
end
function NitrogenMap:loadFruitRequirementsFromXML(configFileName, xmlFile, key)
    local i = 0
    while true do
        local baseKey = string.format("%s.fruitRequirements.fruitRequirement(%d)", key, i)
        if not hasXMLProperty(xmlFile, baseKey) then
            break
        end
        local isOverwrittenRequirement = false
        local fruitRequirement = {
            ["fruitTypeName"] = getXMLString(xmlFile, baseKey .. "#fruitTypeName")
        }
        if fruitRequirement.fruitTypeName == nil then
            Logging.xmlWarning(configFileName, "Invalid fruit type for nitrogen fruitRequirement \'%s\'", baseKey)
        else
            local j = 1
            local fruitType = #self.fruitRequirements
            local j = 1
            for j = j, fruitType, j do
                local _fruitRequirement = self.fruitRequirements[j]
                if string.lower(_fruitRequirement.fruitTypeName) == string.lower(fruitRequirement.fruitTypeName) then
                    isOverwrittenRequirement = true
                    fruitRequirement = _fruitRequirement
                end
            end
            fruitRequirement.alwaysAllowFertilization = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#alwaysAllowFertilization"), Utils.getNoNil(fruitRequirement.alwaysAllowFertilization, false))
            fruitRequirement.ignoreOverfertilization = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#ignoreOverfertilization"), false)
            fruitRequirement.availableAsDefaultRate = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#availableAsDefaultRate"), true)
            fruitRequirement.requiresDefaultMode = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#requiresDefaultMode"), false)
            local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitRequirement.fruitTypeName)
            if fruitType ~= nil then
                fruitRequirement.fruitType = fruitType
                fruitRequirement.bySoilType = fruitRequirement.bySoilType or {}
                local j = 0
                while true do
                    local j = string.format("%s.soil(%d)", baseKey, j)
                    if not hasXMLProperty(xmlFile, j) then
                        break
                    end
                    local _fruitRequirement = {
                        ["soilTypeIndex"] = getXMLInt(xmlFile, j .. "#soilTypeIndex") or 1
                    }
                    local isOverwrittenSoilType = false
                    local l = 1
                    local targetLevel = #fruitRequirement.bySoilType
                    for l = l, targetLevel do
                        local _soilSettings = fruitRequirement.bySoilType[l]
                        if _soilSettings.soilTypeIndex == _fruitRequirement.soilTypeIndex then
                            isOverwrittenSoilType = true
                            _fruitRequirement = _soilSettings
                        end
                    end
                    local targetLevel = getXMLInt(xmlFile, j .. "#targetLevel")
                    if targetLevel ~= nil then
                        _, targetLevel = self:getNearestNitrogenValueFromValue(targetLevel)
                    end
                    _fruitRequirement.targetLevel = targetLevel or (_fruitRequirement.targetLevel or 0)
                    local _ = getXMLInt(xmlFile, j .. "#reduction")
                    if _ ~= nil then
                        _ = math.floor(_ / self.amountPerState)
                    end
                    _fruitRequirement.reduction = _ or (_fruitRequirement.reduction or 0)
                    local l = getXMLInt(xmlFile, j .. "#reductionForage")
                    if l ~= nil then
                        l = math.floor(l / self.amountPerState)
                    end
                    _fruitRequirement.reductionForage = l or (_fruitRequirement.reductionForage or _fruitRequirement.reduction)
                    _fruitRequirement.yieldPotential = getXMLFloat(xmlFile, j .. "#yieldPotential") or (_fruitRequirement.yieldPotential or 1)
                    if not isOverwrittenSoilType then
                        table.insert(fruitRequirement.bySoilType, _fruitRequirement)
                    end
                    j = j + 1
                end
                fruitRequirement.averageTargetLevel = 0
                local j = #fruitRequirement.bySoilType
                if j > 0 then
                    local _fruitRequirement = 0
                    for _ = 1, j do

                    end
                    fruitRequirement.averageTargetLevel = _fruitRequirement / j
                end
                if not isOverwrittenRequirement then
                    table.insert(self.fruitRequirements, fruitRequirement)
                    self.fruitTypeIndexToFruitRequirement[fruitType.index] = fruitRequirement
                end
            end
        end
        i = i + 1
    end
end
function NitrogenMap:loadCropSensorFruitTypesFromXML(_, xmlFile, key)
    local fruitTypesStr = getXMLString(xmlFile, key .. ".cropSensor#fruitTypes")
    if fruitTypesStr ~= nil then
        local fruitTypes = fruitTypesStr:split(" ")
        local j = 1
        for j = j, #fruitTypes do
            local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypes[j])
            if fruitType == nil then
                Logging.xmlWarning(xmlFile, "Invalid fruit type \'%s\' for crop sensor \'%s\'", fruitTypes[j], key)
            else
                table.insert(self.cropSensorFruitTypes, fruitType)
            end
        end
    end
end
function NitrogenMap:postLoad(_, _, _, _, _)
    if self.bitVectorMapNOffsetIsNew then
        local startTime = getTimeSec()
        local modifier = DensityMapModifier.new(self.bitVectorMapNOffset, 0, 3)
        local filter = PerlinNoiseFilter.new(self.bitVectorMapNOffset, 5.5, 1, 0.5, math.random(0, 1000))
        local i = 1
        for i = i, 8 do
            filter:setValueCompareParams(DensityValueCompareType.BETWEEN, (i - 1) / 8 * 10000, i / 8 * 10000)
            modifier:executeSet(i - 1, filter)
        end
        Logging.devInfo("Initialized Nitrogen Offset Map in %dms", (getTimeSec() - startTime) * 1000)
    else
        local startTime = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        local modifier = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        modifier:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
        startTime:executeSet(math.floor(self.maxValue * 0.75), modifier)
    end
    return true
end
local function worldCoordsToLocalCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, size, terrainSize)
    return (startWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (startWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (widthWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (widthWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (heightWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (heightWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1
end
function NitrogenMap:addSetInitialState(multiModifier, soilBitVector, soilTypeFirstChannel, soilTypeNumChannels, farmlandMask)
    local functionData = self.densityMapModifiersInitialize
    local modifier = functionData.modifier
    local nFilter = functionData.nFilter
    local soilFilter = functionData.soilFilter
    local noiseFilter = functionData.noiseFilter
    local sprayLevelFilter = functionData.sprayLevelFilter
    local sprayLevelFilterInv = functionData.sprayLevelFilterInv
    local maxSprayLevel = functionData.maxSprayLevel
    if modifier == nil or (nFilter == nil or (soilFilter == nil or (noiseFilter == nil or (sprayLevelFilter == nil or (sprayLevelFilterInv == nil or maxSprayLevel == nil))))) then
        functionData.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
        modifier = functionData.modifier
        functionData.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        functionData.nFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.maxValue)
        functionData.soilFilter = DensityMapFilter.new(soilBitVector, soilTypeFirstChannel, soilTypeNumChannels)
        soilFilter = functionData.soilFilter
        functionData.noiseFilter = DensityMapFilter.new(self.bitVectorMapNoise, 0, self.noiseNumChannels)
        noiseFilter = functionData.noiseFilter
        local sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
        functionData.sprayLevelFilter = DensityMapFilter.new(sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
        sprayLevelFilter = functionData.sprayLevelFilter
        functionData.sprayLevelFilterInv = DensityMapFilter.new(sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
        sprayLevelFilterInv = functionData.sprayLevelFilterInv
        functionData.maxSprayLevel = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
        local maxSprayLevel = functionData.maxSprayLevel
    end
    local sprayLevelNumChannels = 1
    local sprayMapId = #self.initialValues
    local sprayLevelFirstChannel = 1
    for sprayLevelNumChannels = sprayLevelNumChannels, sprayMapId, sprayLevelFirstChannel do
        local initialValue = self.initialValues[sprayLevelNumChannels]
        soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, initialValue.soilTypeIndex - 1)
        if farmlandMask == nil then
            multiModifier:addExecuteSet(self.maxValue, modifier, soilFilter)
        else
            multiModifier:addExecuteSet(self.maxValue, modifier, farmlandMask, soilFilter)
        end
        local j = 1
        for j = j, self.noiseMaxValue + 1 do
            noiseFilter:setValueCompareParams(DensityValueCompareType.EQUAL, j - 1)
            multiModifier:addExecuteSet(initialValue.baseRange[j], modifier, nFilter, noiseFilter)
        end
    end
    if farmlandMask == nil then
        sprayLevelFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
        sprayLevelFilterInv:setSupersamplingMode(DensityFilterSupersamplingMode.ALL)
        sprayLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
        multiModifier:addExecuteAdd(self.initialSprayLevelBonus[1] or 0, modifier, sprayLevelFilter)
        sprayLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 2)
        sprayLevelFilterInv:setValueCompareParams(DensityValueCompareType.NOTEQUAL, 1)
        multiModifier:addExecuteAdd(self.initialSprayLevelBonus[2] or 0, modifier, sprayLevelFilter, sprayLevelFilterInv)
    end
end
function NitrogenMap:harvestUpdate(filter, fruitIndex, densityMapShape, useMinForageState, strawChopperActive)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
        local functionData = self.densityMapModifiersHarvestMulti
        if functionData == nil then
            functionData = {
                ["modifier"] = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode),
                ["soilFilter"] = DensityMapFilter.new(soilMap.bitVectorMap, soilMap.typeFirstChannel, soilMap.typeNumChannels),
                ["modifierOffsetMeasured"] = DensityMapModifier.new(self.bitVectorMapNOffset, 3, 1, g_terrainNode),
                ["multiModifiersByFruitType"] = {}
            }
            local i = 1
            local multiModifier = 1
            for i = i, #self.fruitRequirements, multiModifier do
                local fruitRequirement = self.fruitRequirements[i]
                functionData.multiModifiersByFruitType[fruitRequirement.fruitType.index] = {}
                local f = 1
                for f = f, 2 do
                    local useForageStates = f == 2
                    functionData.multiModifiersByFruitType[fruitRequirement.fruitType.index][useForageStates] = {}
                    local strawChopper = 1
                    for strawChopper = strawChopper, 2 do
                        local _strawChopperActive = strawChopper == 2
                        local multiModifier = DensityMapMultiModifier.new()
                        self:addCropSensorUpdateToMultiModifier(multiModifier, filter, false)
                        local j = 1
                        local soilSettings = #fruitRequirement.bySoilType
                        for j = j, soilSettings do
                            local soilSettings = fruitRequirement.bySoilType[j]
                            functionData.soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, soilSettings.soilTypeIndex - 1)
                            if useForageStates then
                                multiModifier:addExecuteGet(tostring(j), functionData.modifier, filter, functionData.soilFilter)
                                if soilSettings.reductionForage > 1 then
                                    multiModifier:addExecuteAdd(-soilSettings.reductionForage, functionData.modifier, filter, functionData.soilFilter)
                                end
                            else
                                multiModifier:addExecuteGet(tostring(j), functionData.modifier, filter, functionData.soilFilter)
                                if soilSettings.reduction > 1 then
                                    multiModifier:addExecuteAdd(-soilSettings.reduction, functionData.modifier, filter, functionData.soilFilter)
                                end
                            end
                            if _strawChopperActive then
                                multiModifier:addExecuteAdd(self.choppedStrawStateChange, functionData.modifier, filter, functionData.soilFilter)
                            end
                        end
                        functionData.multiModifiersByFruitType[fruitRequirement.fruitType.index][useForageStates][_strawChopperActive] = multiModifier
                    end
                end
            end
            functionData.accumulators = {}
            functionData.numChangedPixels = {}
            functionData.totalNumPixels = {}
            self.densityMapModifiersHarvestMulti = functionData
        end
        local multiModifiers = functionData.multiModifiersByFruitType[fruitIndex]
        if multiModifiers == nil then
            return false
        end
        local multiModifiers = multiModifiers[useMinForageState]
        if multiModifiers == nil then
            return false
        end
        local multiModifier = multiModifiers[strawChopperActive]
        if multiModifier == nil then
            return false
        end
        densityMapShape:applyToModifier(multiModifier)
        local i = functionData.accumulators
        local fruitRequirement = functionData.numChangedPixels
        local totalNumPixels = functionData.totalNumPixels
        multiModifier:resetStats()
        multiModifier:execute(i, fruitRequirement, totalNumPixels)
        local nMapChanged = false
        local f = self.fruitTypeIndexToFruitRequirement[fruitIndex]
        if f ~= nil then
            for strawChopper, _strawChopperActive in pairs(i) do
                if _strawChopperActive > 0 then
                    local multiModifier = tonumber(strawChopper)
                    local soilSettings = f.bySoilType[multiModifier]
                    self.lastActualValue = _strawChopperActive / fruitRequirement[strawChopper]
                    self.lastTargetValue = soilSettings.targetLevel
                    self.lastYieldPotential = soilSettings.yieldPotential
                    self.lastIgnoreOverfertilization = f.ignoreOverfertilization
                    self.lastRegularNValue = f.averageTargetLevel
                    nMapChanged = true
                end
            end
        end
        if nMapChanged then
            self:setMinimapRequiresUpdate(true)
        end
        return nMapChanged
    end
end
function NitrogenMap:getSprayFunctionData()
    local functionData = self.densityMapModifiersSpray
    if functionData == nil then
        functionData = {
            ["nModifier"] = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
        }
        functionData.nModifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
        functionData.modifierLock = DensityMapModifier.new(self.bitVectorMapNStateChange, 1, 1, g_terrainNode)
        functionData.modifierLock:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
        functionData.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        functionData.nFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
        functionData.nFilterMax = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        functionData.nFilterMax:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
        functionData.lockFilter = DensityMapFilter.new(self.bitVectorMapNStateChange, 1, 1)
        functionData.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
        functionData.sprayTypeFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ALL)
        self.densityMapModifiersSpray = functionData
    end
    return functionData
end
function NitrogenMap:preUpdateNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, _)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
        local functionData = self:getSprayFunctionData()
        local nModifier = functionData.nModifier
        local nFilter = functionData.nFilter
        local nFilterMax = functionData.nFilterMax
        local lockFilter = functionData.lockFilter
        local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
        if sprayTypeDesc ~= nil then
            densityMapShape:applyToModifier(functionData.modifierLock)
            functionData.sprayTypeFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
            sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sprayTypeDesc.sprayGroundType)
            modifierLock:executeSet(0)
            modifierLock:executeSet(1, sprayTypeFilter)
        end
    end
end
function NitrogenMap:addNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, delta, ignoreLock)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
        local functionData = self:getSprayFunctionData()
        local lockFilter = functionData.lockFilter
        if ignoreLock then
            lockFilter = nil
        end
        if g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil then
            densityMapShape:applyToModifier(functionData.nModifier)
            densityMapShape:applyToModifier(functionData.modifierLock)
            local _, numChangedPixels, _ = nModifier:executeAddWithStats(delta, lockFilter)
            nModifier:executeSet(self.maxVisibleValue, functionData.nFilterMax)
            modifierLock:executeSet(1, lockFilter)
            if numChangedPixels > 0 then
                self:setMinimapRequiresUpdate(true)
            end
            return numChangedPixels
        end
    end
    return 0
end
function NitrogenMap:updateNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock)
    local functionData = self.maxValue
    local coverMap = math.min(targetLevel, functionData)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
        local functionData = self:getSprayFunctionData()
        local lockFilter = functionData.lockFilter
        if ignoreLock then
            lockFilter = nil
        end
        if g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil then
            densityMapShape:applyToModifier(functionData.nModifier)
            densityMapShape:applyToModifier(functionData.modifierLock)
            functionData.nFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, coverMap - 1)
            local _, numChangedPixels, _ = nModifier:executeSetWithStats(coverMap, nFilter, lockFilter)
            modifierLock:executeSet(1, lockFilter)
            if numChangedPixels > 0 then
                self:setMinimapRequiresUpdate(true)
            end
            return numChangedPixels
        end
    end
    return 0
end
function NitrogenMap:setNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock, measured)
    local nModifier = self.maxValue
    local coverMap = math.clamp(targetLevel, 0, nModifier)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
        local functionData = self:getSprayFunctionData()
        local lockFilter = functionData.lockFilter
        if ignoreLock then
            lockFilter = nil
        end
        local modifierMeasured = self:getCropSensorFunctionData().modifierMeasured
        if g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil then
            densityMapShape:applyToModifier(functionData.nModifier)
            densityMapShape:applyToModifier(functionData.modifierLock)
            densityMapShape:applyToModifier(modifierMeasured)
            local _, numChangedPixels, _ = nModifier:executeSetWithStats(coverMap, lockFilter)
            modifierLock:executeSet(1, lockFilter)
            modifierMeasured:executeSet(Utils.getNoNil(measured, false) and 1 or 0, lockFilter)
            if numChangedPixels > 0 then
                self:setMinimapRequiresUpdate(true)
            end
            return numChangedPixels
        end
    end
    return 0
end
function NitrogenMap:updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    -- upvalues: (copy) worldCoordsToLocalCoords
    local soilMap = self.soilMap
    if soilMap ~= nil and soilMap.bitVectorMap ~= nil then
        local modifier = self.densityMapModifiersDestroyFruit.modifier
        local fruitFilter = self.densityMapModifiersDestroyFruit.fruitFilter
        local modifierLock = self.densityMapModifiersDestroyFruit.modifierLock
        local fruitIndices = self.densityMapModifiersDestroyFruit.fruitIndices
        if modifier == nil or (self.densityMapModifiersDestroyFruit.nFilter == nil or (fruitFilter == nil or (modifierLock == nil or (self.densityMapModifiersDestroyFruit.lockFilter == nil or fruitIndices == nil)))) then
            self.densityMapModifiersDestroyFruit.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
            local modifier = self.densityMapModifiersDestroyFruit.modifier
            modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
            self.densityMapModifiersDestroyFruit.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
            self.densityMapModifiersDestroyFruit.nFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, self.maxValue - 1)
            self.densityMapModifiersDestroyFruit.fruitFilter = DensityMapFilter.new(modifier)
            fruitFilter = self.densityMapModifiersDestroyFruit.fruitFilter
            self.densityMapModifiersDestroyFruit.modifierLock = DensityMapModifier.new(self.bitVectorMapNFruitDestroyMask, 0, 2, g_terrainNode)
            self.densityMapModifiersDestroyFruit.modifierLock:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
            self.densityMapModifiersDestroyFruit.lockFilter = DensityMapFilter.new(self.bitVectorMapNFruitDestroyMask, 0, 2)
            self.densityMapModifiersDestroyFruit.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
            self.densityMapModifiersDestroyFruit.fruitIndices = {}
            local i = 1
            for i = i, 15 do
                self.densityMapModifiersDestroyFruit.fruitIndices[i] = {
                    ["index"] = 0,
                    ["terrainDataPlaneId"] = 0,
                    ["active"] = false
                }
            end
        end
        local i, index, desc, _
        startWorldX, startWorldZ, i, index, desc, _ = worldCoordsToLocalCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.sizeX, g_currentMission.terrainSize)
        modifierLock:setParallelogramDensityMapCoords(startWorldX, startWorldZ, i, index, desc, _, DensityCoordType.POINT_POINT_POINT)
        fruitIndices[1].active = false
        fruitIndices[2].active = false
        fruitIndices[3].active = false
        fruitIndices[4].active = false
        fruitIndices[5].active = false
        fruitIndices[6].active = false
        fruitIndices[7].active = false
        fruitIndices[8].active = false
        fruitIndices[9].active = false
        fruitIndices[10].active = false
        fruitIndices[11].active = false
        fruitIndices[12].active = false
        fruitIndices[13].active = false
        fruitIndices[14].active = false
        fruitIndices[15].active = false
        modifierLock:executeSet(0)
        for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
            if desc.weed == nil and desc.terrainDataPlaneId ~= nil then
                fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
                local _, numPixels = modifierLock:executeSetWithStats(1, fruitFilter)
                if numPixels > 0 then
                    local i = 1
                    for i = i, 15 do
                        if not fruitIndices[i].active then
                            fruitIndices[i].index = index
                            fruitIndices[i].terrainDataPlaneId = desc.terrainDataPlaneId
                            fruitIndices[i].active = true
                            break
                        end
                    end
                end
            end
        end
    end
    return 0
end
function NitrogenMap:postUpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    -- upvalues: (copy) worldCoordsToLocalCoords
    local soilMap = self.soilMap
    if soilMap ~= nil and soilMap.bitVectorMap ~= nil then
        local modifier = self.densityMapModifiersDestroyFruit.modifier
        local nFilter = self.densityMapModifiersDestroyFruit.nFilter
        local lockFilter = self.densityMapModifiersDestroyFruit.lockFilter
        local i, desc
        startWorldX, startWorldZ, i, desc, heightWorldX, heightWorldZ = worldCoordsToLocalCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.sizeX, g_currentMission.terrainSize)
        modifier:setParallelogramDensityMapCoords(startWorldX, startWorldZ, i, desc, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        local i = 1
        for i = i, 15 do
            if not self.densityMapModifiersDestroyFruit.fruitIndices[i].active then
                break
            end
            local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndices[i].index)
            self.densityMapModifiersDestroyFruit.fruitFilter:resetDensityMapAndChannels(fruitIndices[i].terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
            fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
            self.densityMapModifiersDestroyFruit.modifierLock:executeSet(2, fruitFilter)
        end
        nFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.maxValue - self.catchCropsStateChange)
        modifier:executeSet(self.maxValue, lockFilter, nFilter)
        nFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, self.maxValue - self.catchCropsStateChange)
        modifier:executeAdd(self.catchCropsStateChange, lockFilter, nFilter)
    end
    return 0
end
function NitrogenMap:preUpdateStrawChopperArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, strawGroundType)
    local nFilter = self.densityMapModifiersStrawChopper.nFilter
    local maskModifier = self.densityMapModifiersStrawChopper.maskModifier
    local sprayTypeFilter = self.densityMapModifiersStrawChopper.sprayTypeFilter
    if self.densityMapModifiersStrawChopper.modifier == nil or (nFilter == nil or (maskModifier == nil or (self.densityMapModifiersStrawChopper.maskFilter == nil or sprayTypeFilter == nil))) then
        self.densityMapModifiersStrawChopper.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
        self.densityMapModifiersStrawChopper.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        nFilter = self.densityMapModifiersStrawChopper.nFilter
        self.densityMapModifiersStrawChopper.maskModifier = DensityMapModifier.new(self.bitVectorMapChoppedStrawMask, 0, 1, g_terrainNode)
        maskModifier = self.densityMapModifiersStrawChopper.maskModifier
        self.densityMapModifiersStrawChopper.maskFilter = DensityMapFilter.new(self.bitVectorMapChoppedStrawMask, 0, 1)
        self.densityMapModifiersStrawChopper.maskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
        local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
        self.densityMapModifiersStrawChopper.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
        self.densityMapModifiersStrawChopper.sprayTypeFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, strawGroundType)
    end
    maskModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    maskModifier:executeSet(1)
    sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, strawGroundType)
    maskModifier:executeSet(0, sprayTypeFilter)
    nFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue - self.choppedStrawStateChange)
    maskModifier:executeSet(0, nFilter)
end
function NitrogenMap:postUpdateStrawChopperArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, strawGroundType)
    local modifier = self.densityMapModifiersStrawChopper.modifier
    local sprayTypeFilter = self.densityMapModifiersStrawChopper.sprayTypeFilter
    sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, strawGroundType)
    modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
    modifier:executeAdd(self.choppedStrawStateChange, self.densityMapModifiersStrawChopper.maskFilter, sprayTypeFilter)
end
function NitrogenMap:updateCropSensorArea(densityMapShape)
    local functionData = self:getCropSensorFunctionData()
    local multiModifier = functionData.multiModifier
    if multiModifier == nil then
        multiModifier = DensityMapMultiModifier.new()
        functionData.multiModifier = multiModifier
        self:addCropSensorUpdateToMultiModifier(multiModifier, nil, true)
    end
    densityMapShape:applyToModifier(multiModifier)
    multiModifier:resetStats()
    local changeArea, _ = multiModifier:execute()
    if changeArea > 0 then
        self:setMinimapRequiresUpdate(true)
    end
end
function NitrogenMap:getCropSensorFunctionData()
    local functionData = self.densityMapModifiersCropSensorMulti
    if functionData == nil then
        functionData = {
            ["modifierMeasured"] = DensityMapModifier.new(self.bitVectorMapNOffset, 3, 1, g_terrainNode),
            ["measuredFilter"] = DensityMapFilter.new(self.bitVectorMapNOffset, 3, 1)
        }
        functionData.measuredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        functionData.nModifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
        functionData.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
        functionData.nFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
        functionData.offsetFilter = DensityMapFilter.new(self.bitVectorMapNOffset, 0, 3)
        functionData.tempFruitModifier = DensityMapModifier.new(self.bitVectorMapNFruitFilterMask, 0, 1, g_terrainNode)
        functionData.tempFruitModifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
        functionData.tempFruitFilter = DensityMapFilter.new(self.bitVectorMapNFruitFilterMask, 0, 1)
        functionData.tempFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
        functionData.fruitFilter = DensityMapFilter.new(self.bitVectorMapNFruitFilterMask, 0, 1)
        functionData.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
        functionData.multiModifiers = {}
        self.densityMapModifiersCropSensorMulti = functionData
    end
    return functionData
end
function NitrogenMap:addCropSensorUpdateToMultiModifier(multiModifier, changeFilter, setMeasured)
    local functionData = self:getCropSensorFunctionData()
    multiModifier:addExecuteSet(0, functionData.tempFruitModifier)
    if changeFilter == nil then
        local fruitTypeIndex = 1
        for fruitTypeIndex = fruitTypeIndex, #self.cropSensorFruitTypes do
            local fruitType = self.cropSensorFruitTypes[fruitTypeIndex]
            if fruitType.terrainDataPlaneId ~= nil then
                functionData.fruitFilter:resetDensityMapAndChannels(fruitType.terrainDataPlaneId, fruitType.startStateChannel, fruitType.numStateChannels)
                functionData.fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, fruitType.minHarvestingGrowthState)
                multiModifier:addExecuteSet(1, functionData.tempFruitModifier, functionData.fruitFilter)
            end
        end
    else
        multiModifier:addExecuteSet(1, functionData.tempFruitModifier, changeFilter)
    end
    functionData.measuredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
    multiModifier:addExecuteSet(0, functionData.tempFruitModifier, functionData.measuredFilter)
    local fruitTypeIndex = 1
    for fruitTypeIndex = fruitTypeIndex, #self.nOffsetIndexToOffset do
        local fruitType = self.nOffsetIndexToOffset[fruitTypeIndex]
        functionData.offsetFilter:setValueCompareParams(DensityValueCompareType.EQUAL, fruitTypeIndex - 1)
        functionData.nFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, math.max(1 - fruitType, 1), self.maxValue - fruitType)
        multiModifier:addExecuteAddWithStats("", fruitType, functionData.nModifier, functionData.nFilter, functionData.offsetFilter, functionData.tempFruitFilter)
    end
    if setMeasured then
        functionData.measuredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
        multiModifier:addExecuteSet(1, functionData.modifierMeasured, functionData.measuredFilter, functionData.tempFruitFilter)
    end
end
function NitrogenMap:getLevelAtWorldPos(x, z)
    x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
    z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
    return not self.coverMap:getIsUncoveredAtPos(x, z) and 0 or getBitVectorMapPoint(self.bitVectorMap, x, z, self.firstChannel, self.numChannels)
end
function NitrogenMap:getIsLockedAtWorldPos(wx, wz, sprayTypeIndex)
    local coverMap = self.coverMap
    local soilMap = self.soilMap
    if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
        local modifierLock = self.densityMapModifiersLockedState.modifierLock
        local sprayTypeFilter = self.densityMapModifiersLockedState.sprayTypeFilter
        local coverMaskFilter = self.densityMapModifiersLockedState.coverMaskFilter
        if modifierLock == nil or (sprayTypeFilter == nil or coverMaskFilter == nil) then
            self.densityMapModifiersLockedState.modifierLock = DensityMapModifier.new(self.bitVectorMapNStateChange, 1, 1, g_terrainNode)
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
function NitrogenMap:getNextValidDetectionPoint(wx, wz, dirX, dirZ, maxDistance, sprayTypeIndex)
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
function NitrogenMap:getTargetLevelAtWorldPos(x, z, size, forcedFruitType, fillType, nLevel, defaultNitrogenRequirementIndex)
    local soilMap = self.soilMap
    if soilMap ~= nil and soilMap.bitVectorMap ~= nil then
        size = size or 1
        local modifierFruit = self.densityMapModifiersFruitCheck.modifierFruit
        if modifierFruit == nil then
            local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
            self.densityMapModifiersFruitCheck.modifierFruit = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
            modifierFruit = self.densityMapModifiersFruitCheck.modifierFruit
        end
        local fieldGroundSystem = (x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * soilMap.sizeX
        local sprayTypeMapId = (z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * soilMap.sizeY
        if self.coverMap:getIsUncoveredAtPos(fieldGroundSystem, sprayTypeMapId) then
            local sprayTypeFirstChannel = getBitVectorMapPoint(soilMap.bitVectorMap, fieldGroundSystem, sprayTypeMapId, soilMap.typeFirstChannel, soilMap.typeNumChannels) + 1
            if fillType ~= nil and fillType ~= FillType.UNKNOWN then
                local i = 1
                for i = i, #self.applicationRates do
                    local applicationRate = self.applicationRates[i]
                    if applicationRate.fillTypeIndex == fillType and not applicationRate.autoAdjustToFruit then
                        local j = 1
                        for j = j, #applicationRate.ratesBySoilType do
                            local rateBySoilType = applicationRate.ratesBySoilType[j]
                            if rateBySoilType.soilTypeIndex == sprayTypeFirstChannel then
                                return (nLevel or 0) + rateBySoilType.rate, sprayTypeFirstChannel, FruitType.UNKNOWN
                            end
                        end
                    end
                end
            end
            local sprayTypeNumChannels = size * 0.5
            modifierFruit:setParallelogramWorldCoords(x + sprayTypeNumChannels, z + sprayTypeNumChannels, x - sprayTypeNumChannels, z + sprayTypeNumChannels, x + sprayTypeNumChannels, z - sprayTypeNumChannels, DensityCoordType.POINT_POINT_POINT)
            if forcedFruitType == nil then
                for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
                    if desc.weed == nil and desc.terrainDataPlaneId ~= nil then
                        modifierFruit:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        local acc, numPixels, _ = modifierFruit:executeGet()
                        if numPixels > 0 then
                            local allowCutState = acc / numPixels
                            local state = math.floor(allowCutState)
                            local allowCutState = false
                            local i = 1
                            for i = i, #self.fruitRequirements do
                                if self.fruitRequirements[i].fruitType.index == index then
                                    allowCutState = self.fruitRequirements[i].alwaysAllowFertilization
                                end
                            end
                            if state >= 0 and state ~= desc.cutState or allowCutState then
                                forcedFruitType = index
                                break
                            end
                        end
                    end
                end
            end
            local fruitRequirement = nil
            if forcedFruitType == nil then
                fruitRequirement = self.fruitRequirements[defaultNitrogenRequirementIndex or 1] or self.fruitRequirements[1]
            else
                local index = 1
                for index = index, #self.fruitRequirements do
                    if self.fruitRequirements[index].fruitType.index == forcedFruitType then
                        fruitRequirement = self.fruitRequirements[index]
                        break
                    end
                end
            end
            if fruitRequirement ~= nil then
                local index = 1
                for index = index, #fruitRequirement.bySoilType do
                    local desc = fruitRequirement.bySoilType[index]
                    if desc.soilTypeIndex == sprayTypeFirstChannel then
                        return desc.targetLevel, sprayTypeFirstChannel, forcedFruitType
                    end
                end
            end
            return 0, sprayTypeFirstChannel, FruitType.UNKNOWN
        end
    end
    return 0, 0, FruitType.UNKNOWN
end
function NitrogenMap:getNitrogenApplicationRate(currentLevel, fruitTypeIndex, soilTypeIndex, sprayTypeIndex)
    local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
    if sprayTypeDesc == nil then
        return 0, false
    else
        local i = 1
        local targetLevel = #self.applicationRates
        for i = i, targetLevel do
            local applicationRate = self.applicationRates[i]
            if applicationRate.fillTypeIndex == sprayTypeDesc.fillType.index and not applicationRate.autoAdjustToFruit then
                local j = 1
                for j = j, #applicationRate.ratesBySoilType do
                    local rateBySoilType = applicationRate.ratesBySoilType[j]
                    if rateBySoilType.soilTypeIndex == soilTypeIndex then
                        return rateBySoilType.rate, false
                    end
                end
            end
        end
        local targetLevel = self:getNitrogenTargetLevel(fruitTypeIndex, soilTypeIndex)
        if targetLevel == nil then
            return 0, false
        else
            return targetLevel - currentLevel, true
        end
    end
end
function NitrogenMap:getNitrogenTargetLevel(fruitTypeIndex, soilTypeIndex)
    local fruitRequirement = nil
    local i = 1
    for i = i, #self.fruitRequirements do
        if self.fruitRequirements[i].fruitType.index == fruitTypeIndex then
            fruitRequirement = self.fruitRequirements[i]
            break
        end
    end
    if fruitRequirement ~= nil then
        local i = 1
        for i = i, #fruitRequirement.bySoilType do
            local soilSettings = fruitRequirement.bySoilType[i]
            if soilSettings.soilTypeIndex == soilTypeIndex then
                return soilSettings.targetLevel, nil
            end
        end
    end
    return nil, nil
end
function NitrogenMap:getNOffsetDataAtWorldPos(x, z)
    x = (x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX
    z = (z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY
    if not self.coverMap:getIsUncoveredAtPos(x, z) then
        return false, -1
    end
    local isLocked = getBitVectorMapPoint(self.bitVectorMapNOffset, x, z, 3, 1) == 1
    local offsetValue = getBitVectorMapPoint(self.bitVectorMapNOffset, x, z, 0, 3)
    return isLocked, self.nOffsetIndexToOffset[offsetValue + 1] * self.amountPerState
end
function NitrogenMap:getFertilizerUsage(workingWidth, lastSpeed, statesChanged, fillTypeIndex, dt, _, nApplyAutoModeFruitType, actualNitrogen, nitrogenUsageLevelOffset)
    local requiredLitersPerHa, _, nitrogenProportion = self:getFertilizerUsageByStateChange(statesChanged, fillTypeIndex, nitrogenUsageLevelOffset or 0)
    local regularUsage = 0
    if requiredLitersPerHa > 0 then
        if nApplyAutoModeFruitType == nil or nApplyAutoModeFruitType == FruitType.UNKNOWN then
            local i = 1
            for i = i, #self.applicationRates do
                local fruitRequirement = self.applicationRates[i]
                if fruitRequirement.fillTypeIndex == fillTypeIndex then
                    local _, internalActualNitrogen, requiredLitersPerHaReg = self:getFertilizerUsageByNitrogenAmount(fruitRequirement.regularRate, fillTypeIndex)
                    regularUsage = _ * (lastSpeed / 3600) / (10000 / workingWidth) * dt
                end
            end
        else
            local i = 1
            for i = i, #self.fruitRequirements do
                local fruitRequirement = self.fruitRequirements[i]
                if fruitRequirement.fruitType.index == nApplyAutoModeFruitType then
                    local _, internalActualNitrogen = self:getNearestNitrogenValueFromValue(actualNitrogen)
                    local requiredLitersPerHaReg, _, _ = self:getFertilizerUsageByStateChange(math.max(fruitRequirement.averageTargetLevel - internalActualNitrogen, 0), fillTypeIndex)
                    regularUsage = requiredLitersPerHaReg * (lastSpeed / 3600) / (10000 / workingWidth) * dt
                end
            end
        end
    end
    return requiredLitersPerHa * (lastSpeed / 3600) / (10000 / workingWidth) * dt, requiredLitersPerHa, regularUsage, nitrogenProportion
end
function NitrogenMap:getFertilizerUsageByStateChange(statesChanged, fillTypeIndex, nitrogenUsageLevelOffset)
    return self:getFertilizerUsageByNitrogenAmount(statesChanged * self.amountPerState, fillTypeIndex, (nitrogenUsageLevelOffset or 0) * self.amountPerState)
end
function NitrogenMap:getFertilizerUsageByNitrogenAmount(nitrogenAmount, fillTypeIndex, nAmountOffset)
    local requiredLitersPerHa = 0
    local requiredMassPerHa = 0
    local nitrogenProportion = 0
    local i = 1
    for i = i, #self.fertilizerUsage.nAmounts do
        local nAmount = self.fertilizerUsage.nAmounts[i]
        if nAmount.fillTypeIndex == fillTypeIndex then
            local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
            if fillTypeIndex == FillType.LIQUIDMANURE then
                local nOffsetPct = 1
                if nitrogenAmount > 0 and nAmountOffset ~= nil then
                    nOffsetPct = (nitrogenAmount + nAmountOffset) / nitrogenAmount
                end
                requiredMassPerHa = nitrogenAmount / (nAmount.amount * nOffsetPct) * (fillTypeDesc.massPerLiter / FillTypeManager.MASS_SCALE)
                nitrogenProportion = nAmount.amount * nOffsetPct
            elseif fillTypeDesc ~= nil then
                requiredMassPerHa = nitrogenAmount / (massPerLiter * 1000) / nAmount.amount * massPerLiter
                nitrogenProportion = nAmount.amount
            end
        end
    end
    return requiredLitersPerHa, requiredMassPerHa, nitrogenProportion
end
function NitrogenMap:getNextFruitRequirementIndex(index)
    index = index + 1
    index = #self.fruitRequirements < index and 1 or index
    if self.fruitRequirements[index] == nil or self.fruitRequirements[index].availableAsDefaultRate then
        return index
    else
        return self:getNextFruitRequirementIndex(index)
    end
end
function NitrogenMap:getFruitTypeIndexByFruitRequirementIndex(index)
    if self.fruitRequirements[index] == nil then
        return nil
    else
        return self.fruitRequirements[index].fruitType.index
    end
end
function NitrogenMap:getFruitTypeRequirementRequiresDefaultMode(index)
    local i = 1
    for i = i, #self.fruitRequirements do
        local fruitRequirement = self.fruitRequirements[i]
        if fruitRequirement.fruitType.index == index and fruitRequirement.requiresDefaultMode then
            return true
        end
    end
    return false
end
function NitrogenMap:getNitrogenAmountFromFillType(fillTypeIndex)
    local i = 1
    for i = i, #self.fertilizerUsage.nAmounts do
        local nAmount = self.fertilizerUsage.nAmounts[i]
        if nAmount.fillTypeIndex == fillTypeIndex then
            return nAmount.amount
        end
    end
    return 0
end
function NitrogenMap:getNitrogenFromChangedStates(statesChanged)
    return statesChanged * self.amountPerState
end
function NitrogenMap:getFillTypeIsFertilizer(fillType)
    return self.fertilizerFillTypes[fillType] ~= nil
end
function NitrogenMap:getDefaultNitrogenStateChange()
    return self.stateChangeDefault
end
function NitrogenMap:getMinMaxValue()
    if self.nitrogenValues == nil or #self.nitrogenValues <= 0 then
        return 0, 1, 0
    else
        return self.nitrogenValues[1].realValue, self.nitrogenValues[#self.nitrogenValues].realValue, #self.nitrogenValues
    end
end
function NitrogenMap:getNitrogenValueFromInternalValue(internal)
    local i = 1
    for i = i, #self.nitrogenValues do
        local nitrogenValue = self.nitrogenValues[i]
        if nitrogenValue.value == math.floor(internal) then
            return nitrogenValue.realValue
        end
    end
    return 0
end
function NitrogenMap:getNearestNitrogenValueFromValue(value)
    local minDifference = 1000
    local minValue = 0
    local minInternal = 0
    local i = 1
    for i = i, #self.nitrogenValues do
        local nValue = self.nitrogenValues[i].realValue
        local difference = math.abs(value - nValue)
        if difference < minDifference then
            minInternal = self.nitrogenValues[i].value
            minValue = nValue
            minDifference = difference
        end
    end
    return minValue, minInternal
end
function NitrogenMap:updateLastNitrogenValues()
    self.lastActualValue = -1
    self.lastTargetValue = -1
    self.lastYieldPotential = -1
    self.lastIgnoreOverfertilization = nil
    self.lastRegularNValue = -1
    return self.lastActualValue, self.lastTargetValue, self.lastYieldPotential, self.lastRegularNValue, self.lastIgnoreOverfertilization
end
function NitrogenMap:getYieldFactorByLevelDifference(difference, ignoreOverfertilization)
    return self.yieldCurve:get(difference > 0 and ignoreOverfertilization == true and 0 or difference)
end
function NitrogenMap:buildOverlay(overlay, filter, isColorBlindMode, isMinimap)
    resetDensityMapVisualizationOverlay(overlay)
    setOverlayColor(overlay, 1, 1, 1, 1)
    if isMinimap and self.minimapMissionState then
        if self.pfModule.inGameMenuMapFrameExtension.inGameMenuMapFrame ~= nil then
            local coverMask, sprayLevelFirstChannel, sprayLevelNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
            if g_currentMission.mapOverlayGenerator ~= nil then
                local color = bit32.lshift(1, sprayLevelNumChannels) - 1
                local level = 1
                for level = level, color do
                    local color = nitrogenValue[math.min(level, #self.fertilizerColors[isColorBlindMode])]
                    setDensityMapVisualizationOverlayStateColor(overlay, coverMask, 0, 0, sprayLevelFirstChannel, sprayLevelNumChannels, level, color[1], color[2], color[3])
                end
            end
        end
    else
        local coverMap = self.coverMap
        if coverMap ~= nil then
            local coverMask = bit32.lshift(2 ^ (coverMap.numChannels - 1) - 1, 1)
            local i = 1
            for i = i, #self.nitrogenValues do
                local nitrogenValue = self.nitrogenValues[i]
                if filter[nitrogenValue.filterIndex] then
                    local color = nitrogenValue.color
                    if isColorBlindMode then
                        color = nitrogenValue.colorBlind
                    end
                    if color ~= nil then
                        setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, coverMap.bitVectorMap, coverMask, self.firstChannel, self.numChannels, nitrogenValue.value, color[1], color[2], color[3])
                    end
                end
            end
        end
    end
    if NitrogenMap.DEBUG_N_OFFSET_MAP then
        resetDensityMapVisualizationOverlay(overlay)
        setOverlayColor(overlay, 1, 1, 1, 1)
        setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 0, 1, 0, 0)
        setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 1, 0.8, 0.2, 0)
        setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 2, 0.6, 0.4, 0)
        setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 3, 0.4, 0.6, 0)
        setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 4, 0.2, 0.8, 0)
        setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 5, 0, 1, 0)
        setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 6, 0, 0.5, 0.5)
        setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 7, 0, 0, 1)
    end
end
function NitrogenMap:getDisplayValues()
    if self.valuesToDisplay == nil then
        self.valuesToDisplay = {}
        local i = 1
        local nValueToDisplay = #self.nitrogenValues
        for i = i, nValueToDisplay do
            local nitrogenValue = self.nitrogenValues[i]
            if nitrogenValue.showOnHud then
                local nValueToDisplay = {
                    ["colors"] = {}
                }
                nValueToDisplay.colors[true] = { nitrogenValue.colorBlind }
                nValueToDisplay.colors[false] = { nitrogenValue.color }
                nValueToDisplay.description = string.format("%d kg/ha", nitrogenValue.realValue)
                table.insert(self.valuesToDisplay, nValueToDisplay)
            end
        end
        local nValueToDisplay = {
            ["colors"] = {}
        }
        nValueToDisplay.colors[true] = {
            { 0, 0, 0 }
        }
        nValueToDisplay.colors[false] = {
            { 0, 0, 0 }
        }
        nValueToDisplay.description = self.outdatedLabel
        local i = self.valuesToDisplay
        table.insert(i, nValueToDisplay)
    end
    return self.valuesToDisplay
end
function NitrogenMap:getValueFilter()
    if self.valueFilter == nil or self.valueFilterEnabled == nil then
        self.valueFilter = {}
        self.valueFilterEnabled = {}
        local i = 1
        for i = i, self.numVisualValues + 1 do
            table.insert(self.valueFilter, true)
            table.insert(self.valueFilterEnabled, i <= self.numVisualValues)
        end
    end
    return self.valueFilter, self.valueFilterEnabled
end
function NitrogenMap:getMinimapZoomFactor()
    return 3
end
function NitrogenMap:collectFieldInfos(fieldInfoDisplayExtension)
    fieldInfoDisplayExtension:addFieldInfo(g_i18n:getText("fieldInfo_nValue", NitrogenMap.MOD_NAME), self, self.updateFieldInfoDisplay, 3, self.getFieldInfoYieldChange)
end
function NitrogenMap:getAllowCoverage()
    return true
end
function NitrogenMap:getHelpLinePage()
    return 5
end
function NitrogenMap:updateFieldInfoDisplay(fieldInfo, x, z, isColorBlindMode)
    fieldInfo.yieldPotential = nil
    fieldInfo.yieldPotentialToHa = nil
    fieldInfo.yieldPotentialFactor = nil
    fieldInfo.yieldPotentialFactorBest = nil
    local nLevel = self:getLevelAtWorldPos(x, z)
    local soilTypeIndex = self.soilMap:getTypeIndexAtWorldPos(x, z)
    local fruitTypeIndex, _ = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
    if fruitTypeIndex ~= nil then
        local fruitRequirement = self.fruitTypeIndexToFruitRequirement[fruitTypeIndex]
        if fruitRequirement ~= nil then
            local fruitDesc = fruitRequirement.fruitType
            if fruitDesc ~= nil and (fruitDesc.terrainDataPlaneId ~= nil and fruitDesc.terrainDataPlaneId ~= 0) then
                local soilSettings = nil
                for _, _soilSettings in ipairs(fruitRequirement.bySoilType) do
                    if _soilSettings.soilTypeIndex == soilTypeIndex then
                        soilSettings = _soilSettings
                        break
                    end
                end
                if soilSettings ~= nil then
                    local actualLevelReal = self:getNitrogenValueFromInternalValue(nLevel)
                    local targetLevelReal = self:getNitrogenValueFromInternalValue(soilSettings.targetLevel)
                    local color = nil
                    local _ = nil
                    local _soilSettings = nil
                    local levelDifference = soilSettings.targetLevel - nLevel
                    if fruitRequirement.ignoreOverfertilization then
                        levelDifference = math.max(levelDifference, 0)
                    end
                    local levelDifference = targetLevelReal == 0 and 0 or levelDifference
                    local seedRateYieldFactorCurrent = math.abs(levelDifference)
                    local li = 1
                    local seedRateYieldFactorCurrent = #self.levelDifferenceColors
                    local seedRateYieldFactorBest = 1
                    for li = li, seedRateYieldFactorCurrent, seedRateYieldFactorBest do
                        local levelDifferenceColor = self.levelDifferenceColors[li]
                        if levelDifferenceColor.levelDifference <= seedRateYieldFactorCurrent then
                            if isColorBlindMode then
                                color = levelDifferenceColor.colorBlind
                            else
                                color = levelDifferenceColor.color
                            end
                            _ = levelDifferenceColor.additionalText
                            _soilSettings = levelDifferenceColor.showWarning
                        end
                    end
                    local seedRateYieldFactorCurrent = 1
                    local seedRateYieldFactorBest = 1
                    local li = self.seedRateMap
                    if li ~= nil then
                        local levelDifferenceColor = li:getSeedRateAtWorldPosition(x, z)
                        if levelDifferenceColor ~= nil then
                            seedRateYieldFactorCurrent, seedRateYieldFactorBest = li:getSeedRateYieldFactor(levelDifferenceColor, fruitTypeIndex, soilTypeIndex)
                        end
                    end
                    fieldInfo.yieldPotentialFactor = seedRateYieldFactorCurrent
                    fieldInfo.yieldPotentialFactorBest = seedRateYieldFactorBest
                    fieldInfo.yieldPotential = soilSettings.yieldPotential
                    fieldInfo.nFactor = self:getYieldFactorByLevelDifference(nLevel - soilSettings.targetLevel, fruitRequirement.ignoreOverfertilization)
                    local levelDifferenceColor = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitDesc.index)
                    if levelDifferenceColor ~= nil then
                        fieldInfo.yieldPotentialToHa = soilSettings.yieldPotential * fruitDesc.literPerSqm * 10000 * (levelDifferenceColor.massPerLiter / FillTypeManager.MASS_SCALE) * 2
                    end
                    return string.format("%d / %d kg/ha", actualLevelReal, targetLevelReal), color, _, _soilSettings
                end
            end
        end
    end
    if nLevel == 0 then
        return nil
    else
        return string.format("%d kg/ha", self:getNitrogenValueFromInternalValue(nLevel))
    end
end
function NitrogenMap.getFieldInfoYieldChange(_, fieldInfo)
    return fieldInfo.nFactor or 0, 0.5, fieldInfo.yieldPotential, fieldInfo.yieldPotentialToHa, fieldInfo.yieldPotentialFactor, fieldInfo.yieldPotentialFactorBest
end
function NitrogenMap:drawYieldDebug(nActualValue, nTargetValue)
    if self.debugGraph == nil then
        self.debugGraph = Graph.new(#self.yieldCurve.keyframes, 0.2, 0.05, 0.2, 0.15, 0, 100, false, "%", Graph.STYLE_LINES)
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
        local x = self.debugGraph.left + MathUtil.inverseLerp(minTime, maxTime, nActualValue - nTargetValue) * self.debugGraph.width
        setOverlayColor(self.debugGraph.overlayHLine, 1, 0, 0, 1)
        renderOverlay(self.debugGraph.overlayHLine, x, self.debugGraph.bottom, g_pixelSizeX, self.debugGraph.height)
        setOverlayColor(self.debugGraph.overlayHLine, 1, 1, 1, 1)
    end
end
function NitrogenMap:debugSetNitrogenLevel(fieldId, nitrogenLevel, measured)
    local field = tonumber(fieldId)
    local field = tonumber(nitrogenLevel)
    measured = measured == "true"
    if field == nil or field == nil then
        Logging.error("NitrogenMap: Invalid parameters. Usage: pfNitrogenSetLevel <fieldId> <nitrogenLevel> [measured:true|false]")
    else
        local field = g_fieldManager:getFieldById((tonumber(field)))
        if field ~= nil and field.getDensityMapPolygon ~= nil then
            local area = field:getDensityMapPolygon()
            local _, targetLevel = self:getNearestNitrogenValueFromValue(field)
            self:setNitrogenLevelAtArea(area, SprayType.FERTILIZER, targetLevel, true, measured)
            Logging.info("NitrogenMap: Set nitrogen level of field %d to %d kg/ha", field, field)
        end
    end
end
function NitrogenMap:overwriteGameFunctions(pfModule)
    NitrogenMap:superClass().overwriteGameFunctions(self, pfModule)
    pfModule:overwriteGameFunction(FertilizingSowingMachine, "processSowingMachineArea", function(superFunc, vehicle, superFunc2, workArea, dt)
        if not vehicle.isServer and vehicle.currentUpdateDistance > SowingMachine.CLIENT_DM_UPDATE_RADIUS then
            return superFunc(vehicle, superFunc2, workArea, dt)
        end
        local sowingParams = vehicle.spec_sowingMachine.workAreaParameters
        if not sowingParams.isActive then
            return superFunc(vehicle, superFunc2, workArea, dt)
        end
        if not sowingParams.canFruitBePlanted then
            return superFunc(vehicle, superFunc2, workArea, dt)
        end
        if vehicle.spec_sprayer.workAreaParameters.sprayFillLevel <= 0 or vehicle.spec_fertilizingSowingMachine.needsSetIsTurnedOn and not vehicle:getIsTurnedOn() then
            return superFunc(vehicle, superFunc2, workArea, dt)
        end
        if vehicle.preProcessExtUnderRootFertilizerArea ~= nil then
            vehicle:preProcessExtUnderRootFertilizerArea(workArea, dt)
        end
        return superFunc(vehicle, superFunc2, workArea, dt)
    end)
    pfModule:overwriteGameFunction(FertilizingCultivator, "processCultivatorArea", function(superFunc, vehicle, superFunc2, workArea, dt)
        if not vehicle.isServer and vehicle.currentUpdateDistance > Cultivator.CLIENT_DM_UPDATE_RADIUS then
            return superFunc(vehicle, superFunc2, workArea, dt)
        end
        if vehicle.spec_sprayer.workAreaParameters.sprayFillLevel <= 0 or vehicle.spec_fertilizingCultivator.needsSetIsTurnedOn and not vehicle:getIsTurnedOn() then
            return superFunc(vehicle, superFunc2, workArea, dt)
        end
        if vehicle.preProcessExtUnderRootFertilizerArea ~= nil then
            vehicle:preProcessExtUnderRootFertilizerArea(workArea, dt)
        end
        return superFunc(vehicle, superFunc2, workArea, dt)
    end)
    pfModule:overwriteGameFunction(FSDensityMapUtil, "updateFertilizerArea", function(superFunc, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayType, sprayAmount)
        local functionData = FSDensityMapUtil.functionCache.updateFertilizerArea
        if functionData ~= nil then
            local sprayLevelMaxValue = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
            functionData.maskFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue)
        end
        return superFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayType, sprayAmount)
    end)
end