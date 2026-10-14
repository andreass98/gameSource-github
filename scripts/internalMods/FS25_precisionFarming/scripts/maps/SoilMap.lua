SoilMap = {}
SoilMap.MOD_NAME = g_currentModName
SoilMap.MOD_DIR = g_currentModDirectory
SoilMap.GUI_ELEMENTS = g_currentModDirectory .. "gui/ui_elements.png"
SoilMap.SAMPLING_RADIUS = 35
SoilMap.SAMPLING_PROVIDER_MULTIPLIER = 1.75
source(g_currentModDirectory .. "scripts/gui/SoilSampleYesNoDialog.lua")
source(g_currentModDirectory .. "scripts/densityMapUpdates/SoilMapResetDensityMapTask.lua")
local SoilMap_mt = Class(SoilMap, ValueMap)
function SoilMap.new(pfModule, customMt)
    -- upvalues: (copy) SoilMap_mt
    local self = ValueMap.new(pfModule, customMt or SoilMap_mt)
    self.filename = "precisionFarming_soilMap.grle"
    self.name = "soilMap"
    self.id = "SOIL_MAP"
    self.label = "ui_mapOverviewSoilType"
    self.pendingSoilSamplesPerFarm = {}
    self.moneyChangeType = MoneyType.register("other", "info_samplesAnalysed", SoilMap.MOD_NAME)
    self.densityMapModifiersUncover = {}
    self.densityMapModifiersSellFarmland = nil
    self.mapFrame = nil
    local width, height = getNormalizedScreenValues(85, 85)
    self.samplingCircleElement = g_overlayManager:createOverlay("precisionFarming.circle", 0, 0, width, height)
    self.samplingCircleElement:setColor(0.1, 0.5, 0.1, 0.5)
    self.minimapSamplingState = false
    self.minimapUpdateTimer = 0
    self.minimapLabelName = g_i18n:getText("ui_mapOverviewSoilType", SoilMap.MOD_NAME)
    return self
end
function SoilMap:initialize()
    SoilMap:superClass().initialize(self)
    self.pendingSoilSamplesPerFarm = {}
    self.densityMapModifiersUncover = {}
    self.densityMapModifiersFarmlandStateChange = nil
    self.loadFilename = nil
    self.coverMap = self.pfModule.coverMap
    SoilSampleYesNoDialog.register()
end
function SoilMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
    key = key .. ".soilMap"
    local missionInfo = g_currentMission.missionInfo
    local savegameFilename = nil
    if missionInfo.savegameDirectory ~= nil then
        savegameFilename = missionInfo.savegameDirectory .. "/" .. self.filename
    end
    if savegameFilename == nil or not fileExists(savegameFilename) then
        local mapXMLFilename = Utils.getFilename(missionInfo.mapXMLFilename, g_currentMission.baseDirectory)
        self.mapXMLFile = loadXMLFile("MapXML", mapXMLFilename)
        if self.mapXMLFile ~= nil then
            local customSoilMap = getXMLString(self.mapXMLFile, "map.precisionFarming.soilMap#filename")
            if customSoilMap ~= nil then
                local mapKey = Utils.getFilename(customSoilMap, g_currentMission.baseDirectory)
                if fileExists(mapKey) then
                    self.loadFilename = mapKey
                end
            end
            delete(self.mapXMLFile)
        end
        local customSoilMap = 0
        while true do
            local mapKey = string.format("%s.predefinedMaps.predefinedMap(%d)", key, customSoilMap)
            if not hasXMLProperty(xmlFile, mapKey) then
                break
            end
            local filename = getXMLString(xmlFile, mapKey .. "#filename")
            if filename == nil then
                Logging.xmlWarning(configFileName, "Unknown filename in \'%s\'", key)
            else
                local isDefault = Utils.getFilename(filename, baseDirectory)
                if fileExists(isDefault) then
                    local isDefault = getXMLBool(xmlFile, mapKey .. "#isDefault")
                    if isDefault ~= nil and (isDefault and self.loadFilename == nil) then
                        self.loadFilename = isDefault
                    end
                    local mapIdentifier = getXMLString(xmlFile, mapKey .. "#mapIdentifier")
                    if mapIdentifier ~= nil and (mapFilename:find(mapIdentifier) ~= nil and self.loadFilename == nil) then
                        self.loadFilename = isDefault
                    end
                else
                    Logging.xmlWarning(configFileName, "Soil map \'%s\' could not be found", key)
                end
            end
            customSoilMap = customSoilMap + 1
        end
    else
        self.loadFilename = savegameFilename
    end
    self.numChannels = getXMLInt(xmlFile, key .. ".bitVectorMap#numChannels") or 3
    self.bitVectorMap = createBitVectorMap("SoilMap")
    if self.loadFilename ~= nil then
        if loadBitVectorMapFromFile(self.bitVectorMap, self.loadFilename, self.numChannels) then
            local mapXMLFilename, customSoilMap = getBitVectorMapSize(self.bitVectorMap)
            if mapXMLFilename == 1024 then
                Logging.info("Load soil map \'%s\'", self.loadFilename)
            else
                self.loadFilename = nil
                Logging.xmlWarning(configFileName, "Found soil map with wrong size \'%s\'. Soil map needs to be 1024x1024!", self.loadFilename)
            end
        else
            Logging.xmlWarning(configFileName, "Error while loading soil map \'%s\'", self.loadFilename)
            self.loadFilename = nil
        end
    end
    if self.loadFilename == nil then
        loadBitVectorMapNew(self.bitVectorMap, 1024, 1024, self.numChannels, false)
    end
    self:addBitVectorMapToSync(self.bitVectorMap)
    self:addBitVectorMapToSave(self.bitVectorMap, self.filename)
    self:addBitVectorMapToDelete(self.bitVectorMap)
    local mapXMLFilename, customSoilMap = getBitVectorMapSize(self.bitVectorMap)
    self.sizeX = mapXMLFilename
    self.sizeY = customSoilMap
    self.typeFirstChannel = getXMLInt(xmlFile, key .. ".bitVectorMap#typeFirstChannel") or 0
    self.typeNumChannels = getXMLInt(xmlFile, key .. ".bitVectorMap#typeNumChannels") or 2
    self.coverChannel = getXMLInt(xmlFile, key .. ".bitVectorMap#coverChannel") or 2
    self.sampledColor = string.getVector(getXMLString(xmlFile, key .. ".sampling#sampledColor"), 3) or { 0, 0, 0 }
    self.sampledColorBlind = string.getVector(getXMLString(xmlFile, key .. ".sampling#sampledColorBlind"), 3) or { 0, 0, 0 }
    self.sampledText = g_i18n:convertText(getXMLString(xmlFile, key .. ".sampling#name"), SoilMap.MOD_NAME)
    self.pricePerSample = string.getVector(getXMLString(xmlFile, key .. ".sampling#pricePerSample"), 3) or { 50, 100, 150 }
    self.analyseTimePerSample = (getXMLFloat(xmlFile, key .. ".sampling#analyseTimeSecPerSample") or 5) * 1000
    self.texts = {}
    self.texts.laboratoryIdle = g_i18n:convertText(getXMLString(xmlFile, key .. ".sampling.texts#idleText") or "$l10n_ui_laboratory_idle", SoilMap.MOD_NAME)
    self.texts.laboratoryAnalyse = g_i18n:convertText(getXMLString(xmlFile, key .. ".sampling.texts#analyseText") or "$l10n_ui_laboratory_analyse", SoilMap.MOD_NAME)
    self.texts.fieldInfoSoil = g_i18n:getText("fieldInfo_soil", SoilMap.MOD_NAME)
    self.texts.fieldInfoNoData = g_i18n:getText("fieldInfo_noSoilDataFound", SoilMap.MOD_NAME)
    self.texts.purchaseSoilMaps = g_i18n:getText("ui_purchaseSoilMaps", SoilMap.MOD_NAME)
    self.soilTypes = {}
    local mapXMLFilename = 0
    while true do
        local customSoilMap = string.format("%s.soilTypes.soilType(%d)", key, mapXMLFilename)
        if not hasXMLProperty(xmlFile, customSoilMap) then
            break
        end
        local mapKey = {
            ["name"] = g_i18n:convertText(getXMLString(xmlFile, customSoilMap .. "#name"), SoilMap.MOD_NAME),
            ["yieldPotential"] = getXMLFloat(xmlFile, customSoilMap .. "#yieldPotential") or 1,
            ["color"] = string.getVector(getXMLString(xmlFile, customSoilMap .. "#color"), 3) or { 0, 0, 0 },
            ["colorBlind"] = string.getVector(getXMLString(xmlFile, customSoilMap .. "#colorBlind"), 3) or { 0, 0, 0 }
        }
        table.insert(self.soilTypes, mapKey)
        mapXMLFilename = mapXMLFilename + 1
    end
    self.pHMap = self.pfModule.pHMap
    self.nitrogenMap = self.pfModule.nitrogenMap
    g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
    return true
end
function SoilMap:initTerrain(mission, terrainId, filename)
    SoilMap:superClass().initTerrain(self, mission, terrainId, filename)
    local multiModifier = nil
    if self.pHMap ~= nil and self.pHMap.newBitVectorMap then
        multiModifier = DensityMapMultiModifier.new()
        self.pHMap:addSetInitialState(multiModifier, self.bitVectorMap, self.typeFirstChannel, self.typeNumChannels)
    end
    if self.nitrogenMap ~= nil and self.nitrogenMap.newBitVectorMap then
        if multiModifier == nil then
            multiModifier = DensityMapMultiModifier.new()
        end
        self.nitrogenMap:addSetInitialState(multiModifier, self.bitVectorMap, self.typeFirstChannel, self.typeNumChannels)
    end
    if multiModifier ~= nil then
        local updateTask = SoilMapResetDensityMapTask.new()
        updateTask.multiModifier = multiModifier
        updateTask:enqueue(true)
        Logging.devInfo("Initialized nitrogen and pH Map.")
    end
end
function SoilMap:delete()
    g_messageCenter:unsubscribeAll(self)
    self.samplingCircleElement:delete()
    SoilMap:superClass().delete(self)
end
function SoilMap:loadFromItemsXML(xmlFile, key)
    xmlFile:iterate((key .. ".soilMap") .. ".pendingSoilSamples", function(_, baseKey)
        -- upvalues: (copy) xmlFile, (copy) self
        local farmId = xmlFile:getInt(baseKey .. "#farmId")
        local timer = xmlFile:getFloat(baseKey .. "#timer", self.analyseTimePerSample)
        local toAnalyse = xmlFile:getInt(baseKey .. "#toAnalyse")
        local totalAnalysed = xmlFile:getInt(baseKey .. "#totalAnalysed")
        if farmId ~= nil and (toAnalyse ~= nil and totalAnalysed ~= nil) then
            self.pendingSoilSamplesPerFarm[farmId] = {
                ["toAnalyse"] = toAnalyse,
                ["totalAnalysed"] = totalAnalysed,
                ["timer"] = timer
            }
        end
    end)
end
function SoilMap:saveToXMLFile(xmlFile, key, _)
    key = key .. ".soilMap"
    local i = 0
    for farmId, data in pairs(self.pendingSoilSamplesPerFarm) do
        local baseKey = string.format("%s.pendingSoilSamples(%d)", key, i)
        xmlFile:setInt(baseKey .. "#farmId", farmId)
        xmlFile:setFloat(baseKey .. "#timer", data.timer)
        xmlFile:setInt(baseKey .. "#toAnalyse", data.toAnalyse)
        xmlFile:setInt(baseKey .. "#totalAnalysed", data.totalAnalysed)
        i = i + 1
    end
end
function SoilMap:update(dt)
    for farmId, data in pairs(self.pendingSoilSamplesPerFarm) do
        data.timer = data.timer - dt * g_currentMission:getEffectiveTimeScale()
        if data.timer <= 0 then
            data.toAnalyse = data.toAnalyse - 1
            if data.toAnalyse <= 0 then
                self.coverMap:uncoverAnalysedArea(farmId)
                local price = self:getPricePerSoilSample() * data.totalAnalysed
                g_currentMission:addMoney(-price, farmId, self.moneyChangeType, true, true)
                self.pendingSoilSamplesPerFarm[farmId] = nil
            else
                data.timer = self.analyseTimePerSample
            end
            self:updateLaboratoryText()
        end
    end
    if self.minimapSamplingState then
        self.samplingCircleElement:setColor(0.5, 0.5, 0.1, IngameMap.alpha)
    end
    if self.minimapUpdateTimer > 0 then
        self.minimapUpdateTimer = self.minimapUpdateTimer - dt
        if self.minimapUpdateTimer <= 0 then
            self:setMinimapRequiresUpdate(true)
        end
    end
end
function SoilMap:setMapFrame(mapFrame)
    self.mapFrame = mapFrame
    self:updateLaboratoryText()
end
function SoilMap:updateLaboratoryText()
    if self.mapFrame ~= nil then
        local farmId = g_currentMission:getFarmId()
        if self.pendingSoilSamplesPerFarm[farmId] ~= nil then
            self.mapFrame.laboratoryInfoText:setText(string.format(self.texts.laboratoryAnalyse, self.pendingSoilSamplesPerFarm[farmId].totalAnalysed), true)
            return
        end
        self.mapFrame.laboratoryInfoText:setText(self.texts.laboratoryIdle, true)
    end
end
function SoilMap.sendSoilSamplesByFarm(_, farmId)
    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if SpecializationUtil.hasSpecialization(SoilSampler, vehicle.specializations) and vehicle:getOwnerFarmId() == farmId then
            vehicle:sendTakenSoilSamples()
        end
    end
end
function SoilMap:analyseSoilSamples(farmId, numSamples)
    if self.pendingSoilSamplesPerFarm[farmId] == nil then
        self.pendingSoilSamplesPerFarm[farmId] = {
            ["toAnalyse"] = numSamples,
            ["totalAnalysed"] = numSamples,
            ["timer"] = self.analyseTimePerSample
        }
    else
        self.pendingSoilSamplesPerFarm[farmId].toAnalyse = self.pendingSoilSamplesPerFarm[farmId].toAnalyse + numSamples
        self.pendingSoilSamplesPerFarm[farmId].totalAnalysed = self.pendingSoilSamplesPerFarm[farmId].totalAnalysed + numSamples
        self.pendingSoilSamplesPerFarm[farmId].timer = self.analyseTimePerSample
    end
    self:updateLaboratoryText()
end
function SoilMap:onAnalyseArea(_, _, _)
    self.minimapUpdateTimer = 250
end
function SoilMap:addUncoverToMultiModifier(multiModifier, filter1, filter2, coverFilter1, coverFilter2)
    local modifier = self.densityMapModifiersUncover.modifier
    if modifier == nil then
        self.densityMapModifiersUncover.modifier = DensityMapModifier.new(self.bitVectorMap, self.coverChannel, 1, g_terrainNode)
        modifier = self.densityMapModifiersUncover.modifier
    end
    if coverFilter1 ~= nil then
        multiModifier:addExecuteSet(0, modifier, coverFilter1, coverFilter2)
    end
    multiModifier:addExecuteSet(1, modifier, filter1, filter2)
end
function SoilMap.onFarmlandStateChanged(_, farmlandId, farmId, loadFromSavegame)
    if not loadFromSavegame and farmId == 0 then
        local updateTask = SoilMapResetDensityMapTask.new()
        updateTask:setData(farmlandId)
        updateTask:enqueue()
    end
end
function SoilMap:getFarmlandResetMultiModifier(farmlandId)
    farmlandId = farmlandId or -1
    local functionData = self.densityMapModifiersFarmlandStateChange
    if functionData == nil then
        functionData = {
            ["modifier"] = DensityMapModifier.new(self.bitVectorMap, self.coverChannel, 1, g_terrainNode),
            ["modifierCover"] = DensityMapModifier.new(self.coverMap.bitVectorMap, self.coverMap.firstChannel, self.coverMap.numChannels, g_terrainNode),
            ["farmlandMask"] = DensityMapFilter.new(g_farmlandManager.localMap, 0, g_farmlandManager.numberOfBits),
            ["multiModifiers"] = {}
        }
        self.densityMapModifiersFarmlandStateChange = functionData
    end
    local multiModifier = functionData.multiModifiers[farmlandId]
    if multiModifier == nil then
        local farmlandMask = functionData.farmlandMask
        multiModifier = DensityMapMultiModifier.new()
        if farmlandId >= 0 then
            farmlandMask:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
        else
            farmlandMask = nil
        end
        multiModifier:addExecuteSet(0, functionData.modifier, farmlandMask)
        multiModifier:addExecuteSet(0, functionData.modifierCover, farmlandMask)
        if self.pfModule.pHMap ~= nil then
            self.pfModule.pHMap:addSetInitialState(multiModifier, self.bitVectorMap, self.typeFirstChannel, self.typeNumChannels, farmlandMask)
        end
        if self.pfModule.nitrogenMap ~= nil then
            self.pfModule.nitrogenMap:addSetInitialState(multiModifier, self.bitVectorMap, self.typeFirstChannel, self.typeNumChannels, farmlandMask)
        end
        functionData.multiModifiers[farmlandId] = multiModifier
    end
    return multiModifier
end
function SoilMap:getTypeIndexAtWorldPos(x, z)
    x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
    z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
    return not self.coverMap:getIsUncoveredAtPos(x, z) and 0 or getBitVectorMapPoint(self.bitVectorMap, x, z, self.typeFirstChannel, self.typeNumChannels) + 1
end
function SoilMap:buildOverlay(overlay, valueFilter, isColorBlindMode)
    resetDensityMapVisualizationOverlay(overlay)
    setOverlayColor(overlay, 1, 1, 1, 1)
    if self.coverMap ~= nil then
        local sampledColor = self.sampledColor
        if isColorBlindMode then
            sampledColor = self.sampledColorBlind
        end
        setDensityMapVisualizationOverlayStateColor(overlay, self.coverMap.bitVectorMap, 0, 0, self.coverMap.firstChannel, self.coverMap.numChannels, self.coverMap.sampledValue, sampledColor[1], sampledColor[2], sampledColor[3])
    end
    local sampledColor = bit32.lshift(1, self.coverChannel)
    local i = 1
    for i = i, #self.soilTypes do
        if valueFilter[i] then
            local soilType = self.soilTypes[i]
            local color = soilType.color
            if isColorBlindMode then
                color = soilType.colorBlind
            end
            setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, self.bitVectorMap, sampledColor, self.typeFirstChannel, self.typeNumChannels, i - 1, color[1], color[2], color[3])
        end
    end
end
function SoilMap:getDisplayValues()
    if self.valuesToDisplay == nil then
        self.valuesToDisplay = {}
        local i = 1
        local soilTypeToDisplay = #self.soilTypes
        for i = i, soilTypeToDisplay do
            local soilType = self.soilTypes[i]
            local soilTypeToDisplay = {
                ["colors"] = {}
            }
            soilTypeToDisplay.colors[true] = {
                { soilType.colorBlind[1], soilType.colorBlind[2], soilType.colorBlind[3] }
            }
            soilTypeToDisplay.colors[false] = {
                { soilType.color[1], soilType.color[2], soilType.color[3] }
            }
            soilTypeToDisplay.description = soilType.name
            table.insert(self.valuesToDisplay, soilTypeToDisplay)
        end
        local soilTypeToDisplay = {
            ["colors"] = {}
        }
        soilTypeToDisplay.colors[true] = {
            { self.sampledColorBlind[1], self.sampledColorBlind[2], self.sampledColorBlind[3] }
        }
        soilTypeToDisplay.colors[false] = {
            { self.sampledColor[1], self.sampledColor[2], self.sampledColor[3] }
        }
        soilTypeToDisplay.description = self.sampledText
        local i = self.valuesToDisplay
        table.insert(i, soilTypeToDisplay)
    end
    return self.valuesToDisplay
end
function SoilMap:getSoilTypeByIndex(soilTypeIndex)
    return self.soilTypes[soilTypeIndex]
end
function SoilMap:getYieldPotentialBySoilTypeIndex(soilTypeIndex)
    return self.soilTypes[soilTypeIndex] == nil and 1 or self.soilTypes[soilTypeIndex].yieldPotential
end
function SoilMap:getValueFilter()
    if self.valueFilter == nil or self.valueFilterEnabled == nil then
        self.valueFilter = {}
        self.valueFilterEnabled = {}
        local numSoilTypes = #self.soilTypes
        local i = 1
        for i = i, numSoilTypes + 1 do
            table.insert(self.valueFilter, true)
            table.insert(self.valueFilterEnabled, i <= numSoilTypes)
        end
    end
    return self.valueFilter, self.valueFilterEnabled
end
function SoilMap:getMinimapValueFilter()
    if self.minimapValueFilter == nil then
        self.minimapValueFilter = {}
        for i = 1, #self.soilTypes + 1 do
            table.insert(self.minimapValueFilter, true)
        end
    end
    return self.minimapValueFilter, self.minimapValueFilter
end
function SoilMap:getMinimapAdditionalElement()
    return self.samplingCircleElement
end
function SoilMap:getMinimapZoomFactor()
    return 3
end
function SoilMap:getMinimapUpdateTimeLimit()
    return 5
end
function SoilMap:setMinimapSamplingState(state)
    self.minimapSamplingState = state
    if not state then
        self.samplingCircleElement:setColor(0.1, 0.5, 0.1, 0.5)
    end
end
function SoilMap:collectFieldInfos(fieldInfoDisplayExtension)
    fieldInfoDisplayExtension:addFieldInfo(self.texts.fieldInfoSoil, self, self.updateFieldInfoDisplay, 1)
end
function SoilMap:updateFieldInfoDisplay(_, x, z, _)
    local soilTypeIndex = self:getTypeIndexAtWorldPos(x, z)
    local soilType = self.soilTypes[soilTypeIndex]
    if soilType == nil then
        return self.texts.fieldInfoNoData
    else
        return soilType.name
    end
end
function SoilMap:getHelpLinePage()
    return 2
end
function SoilMap:collectFarmlandHotspotActions(actions)
    table.insert(actions, {
        ["title"] = g_i18n:getText("ui_purchaseSoilMaps"),
        ["callback"] = self.onPurchaseSoilInformationCallback,
        ["callbackTarget"] = self
    })
end
function SoilMap:onPurchaseSoilInformationCallback(farmlandId)
    local _, fieldArea = self.pfModule:getFarmlandFieldInfo(farmlandId)
    if fieldArea > 0 then
        local price = self:getNumSoilSamplesPerHa() * fieldArea
        local numSamples = math.ceil(price)
        local price = self.pricePerSample[g_currentMission.missionInfo.economicDifficulty] or 0
        SoilSampleYesNoDialog.show(self.onSoilSampleDialogCallback, self, farmlandId, fieldArea, numSamples, price * numSamples, price * numSamples * (SoilMap.SAMPLING_PROVIDER_MULTIPLIER - 1))
    end
end
function SoilMap:onSoilSampleDialogCallback(yes, farmlandId)
    if yes then
        if g_server == nil and g_client ~= nil then
            g_client:getServerConnection():sendEvent(PurchaseSoilMapsEvent.new(farmlandId))
            return
        end
        self:purchaseSoilMaps(farmlandId)
    end
end
function SoilMap:getNumSoilSamplesPerHa()
    return 10000 / (3.141592653589793 * SoilMap.SAMPLING_RADIUS ^ 2) * 2
end
function SoilMap:purchaseSoilMaps(farmlandId)
    local farmland = g_farmlandManager.farmlands[farmlandId]
    local fieldArea = farmland ~= nil and (farmland.totalFieldArea or 0) or 0
    if fieldArea > 0 then
        local farmId = self:getNumSoilSamplesPerHa() * fieldArea
        local numSamples = math.ceil(farmId)
        local farmId = g_farmlandManager:getFarmlandOwner(farmlandId)
        local price = self:getPricePerSoilSample() * numSamples * SoilMap.SAMPLING_PROVIDER_MULTIPLIER
        g_currentMission:addMoney(-price, farmId, self.moneyChangeType, true, true)
        if self.pfModule.farmlandStatistics ~= nil then
            self.pfModule.farmlandStatistics:updateStatistic(farmlandId, "numSoilSamples", numSamples)
            self.pfModule.farmlandStatistics:updateStatistic(farmlandId, "soilSampleCosts", price)
        end
        if self.coverMap ~= nil then
            self.coverMap:uncoverFarmlandArea(farmlandId)
        end
    end
end
function SoilMap:getPricePerSoilSample()
    return self.pricePerSample[g_currentMission.missionInfo.economicDifficulty] or 0
end
function SoilMap:overwriteGameFunctions(pfModule)
    SoilMap:superClass().overwriteGameFunctions(self, pfModule)
end