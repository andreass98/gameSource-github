PrecisionFarming = {}
PrecisionFarming.MOD_NAME = g_currentModName
PrecisionFarming.BASE_DIRECTORY = g_currentModDirectory
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/AdditionalFieldBuyInfoEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/CropSensorStateEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/ExtendedSowingMachineRateEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/ExtendedSprayerAmountEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/ExtendedSprayerDefaultFruitTypeEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/FarmlandStatisticsEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/FarmlandStatisticsResetEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/PurchaseSoilMapsEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/RequestFarmlandStatisticsEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/RequestFieldBuyInfoEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/ResetYieldMapEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/SoilSamplerStartEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/SoilSamplerSendEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/TramlineMapInitialEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/events/TramlineMapSetEvent.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/densityMapUpdates/PrecisionFarmingDensityMapUpdater.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/ValueMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/SoilMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/YieldMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/PHMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/NitrogenMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/SeedRateMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/TramlineMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/maps/CoverMap.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/gui/PrecisionFarmingGUI.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/gui/InGameMenuMapFrameExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/gui/ShopConfigScreenExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/hud/InGameMapExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/hud/InputHelpDisplayExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/AdditionalFieldBuyInfo.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/AdditionalSpecializations.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/AIExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/CropSensorLinkageData.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/ExtendedWeedControl.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/FieldInfoDisplayExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/HarvestExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/HelplineExtension.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/InfoDisplayBoxPrecisionFarming.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/ManureSensorLinkageData.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/SprayerNodeData.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/Subsidies.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/PrecisionFarmingDebug.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/PrecisionFarmingSettings.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/misc/UsageBuffer.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/environmentalScore/EnvironmentalScore.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/specializations/configurations/VehicleConfigurationDataSprayerNodes.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/statistics/FarmlandStatistics.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/statistics/FarmlandStatistic.lua")
source(PrecisionFarming.BASE_DIRECTORY .. "scripts/statistics/FarmlandStatisticCounter.lua")
local PrecisionFarming_mt = Class(PrecisionFarming)
function PrecisionFarming.new(customMt)
    -- upvalues: (copy) PrecisionFarming_mt
    local self = setmetatable({}, customMt or PrecisionFarming_mt)
    self.overwrittenGameFunctions = {}
    self.valueMaps = {}
    self.visualizationOverlays = {}
    self.precisionFarmingSettings = PrecisionFarmingSettings.new(self)
    self:registerValueMap(SoilMap.new(self))
    self:registerValueMap(PHMap.new(self))
    self:registerValueMap(NitrogenMap.new(self))
    self:registerValueMap(YieldMap.new(self))
    self:registerValueMap(SeedRateMap.new(self))
    self:registerValueMap(TramlineMap.new(self))
    self:registerValueMap(CoverMap.new(self))
    self.inGameMenuMapFrameExtension = InGameMenuMapFrameExtension.new(self)
    self.inputHelpDisplayExtension = InputHelpDisplayExtension.new(self)
    self.shopConfigScreenExtension = ShopConfigScreenExtension.new()
    self.inGameMapExtension = InGameMapExtension.new(self)
    self.aiExtension = AIExtension.new()
    self.fieldInfoDisplayExtension = FieldInfoDisplayExtension.new(self)
    self.harvestExtension = HarvestExtension.new(self)
    self.helplineExtension = HelplineExtension.new(self)
    self.farmlandStatistics = FarmlandStatistics.new(self)
    self.additionalFieldBuyInfo = AdditionalFieldBuyInfo.new(self)
    self.cropSensorLinkageData = CropSensorLinkageData.new(self)
    self.environmentalScore = EnvironmentalScore.new(self)
    self.extendedWeedControl = ExtendedWeedControl.new(self)
    self.manureSensorLinkageData = ManureSensorLinkageData.new(self)
    self.sprayerNodeData = SprayerNodeData.new(self)
    self.subsidies = Subsidies.new(self)
    self.precisionFarmingDebug = PrecisionFarmingDebug.new(self)
    self.densityMapUpdater = PrecisionFarmingDensityMapUpdater.new(self)
    self.firstTimeRun = false
    self.firstTimeRunDelay = 2000
    return self
end
function PrecisionFarming:initialize()
    local i = 1
    for i = i, #self.valueMaps do
        self.valueMaps[i]:initialize(self)
        self.valueMaps[i]:overwriteGameFunctions(self)
    end
    self.inGameMenuMapFrameExtension:initialize(self)
    self.inGameMenuMapFrameExtension:overwriteGameFunctions(self)
    self.inputHelpDisplayExtension:overwriteGameFunctions(self)
    self.shopConfigScreenExtension:overwriteGameFunctions(self)
    self.inGameMapExtension:overwriteGameFunctions(self)
    self.aiExtension:overwriteGameFunctions(self)
    self.fieldInfoDisplayExtension:overwriteGameFunctions(self)
    self.harvestExtension:overwriteGameFunctions(self)
    self.helplineExtension:overwriteGameFunctions(self)
    self.farmlandStatistics:overwriteGameFunctions(self)
    self.additionalFieldBuyInfo:overwriteGameFunctions(self)
    self.cropSensorLinkageData:overwriteGameFunctions(self)
    self.environmentalScore:overwriteGameFunctions(self)
    self.extendedWeedControl:overwriteGameFunctions(self)
    self.manureSensorLinkageData:overwriteGameFunctions(self)
    self.sprayerNodeData:overwriteGameFunctions(self)
    self.subsidies:overwriteGameFunctions(self)
    self.precisionFarmingSettings:overwriteGameFunctions(self)
end
function PrecisionFarming:loadMap(filename)
    if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
        if not Utils.getNoNil(getXMLBool(g_savegameXML, "gameSettings.precisionFarming#initialized"), false) then
            self.firstTimeRun = true
            setXMLBool(g_savegameXML, "gameSettings.precisionFarming#initialized", true)
            g_gameSettings:save()
        end
        self.mapFilename = filename
        self.configFileName = Utils.getFilename("PrecisionFarming.xml", PrecisionFarming.BASE_DIRECTORY)
        local xmlFile = loadXMLFile("ConfigXML", self.configFileName)
        local i = 1
        for i = i, #self.valueMaps do
            self.valueMaps[i]:loadFromXML(xmlFile, "precisionFarming", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        end
        local i = 1
        for i = i, #self.valueMaps do
            self.valueMaps[i]:postLoad(xmlFile, "precisionFarming", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        end
        self.aiExtension:loadFromXML(xmlFile, "precisionFarming.aiExtension", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.fieldInfoDisplayExtension:loadFromXML(xmlFile, "precisionFarming.fieldInfoDisplayExtension", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.harvestExtension:loadFromXML(xmlFile, "precisionFarming.harvestExtension", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.helplineExtension:loadFromXML(xmlFile, "precisionFarming.helplineExtension", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.farmlandStatistics:loadFromXML(xmlFile, "precisionFarming.farmlandStatistics", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.additionalFieldBuyInfo:loadFromXML(xmlFile, "precisionFarming.additionalFieldBuyInfo", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.cropSensorLinkageData:loadFromXML(xmlFile, "precisionFarming.cropSensorLinkageData", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.manureSensorLinkageData:loadFromXML(xmlFile, "precisionFarming.manureSensorLinkageData", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.sprayerNodeData:loadFromXML(xmlFile, "precisionFarming.sprayerNodeData", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.subsidies:loadFromXML(xmlFile, "precisionFarming.subsidies", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.environmentalScore:loadFromXML(xmlFile, "precisionFarming.environmentalScore", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        self.extendedWeedControl:loadFromXML(xmlFile, "precisionFarming.extendedWeedControl", PrecisionFarming.BASE_DIRECTORY, self.configFileName, filename)
        delete(xmlFile)
    end
end
function PrecisionFarming:unloadMapData()
    self.inGameMenuMapFrameExtension:unloadMapData()
    self.shopConfigScreenExtension:unloadMapData()
    self.inGameMapExtension:unloadMapData()
    self.extendedWeedControl:unloadMapData()
end
function PrecisionFarming:initTerrain(mission, terrainId, filename)
    local i = 1
    for i = i, #self.valueMaps do
        self.valueMaps[i]:initTerrain(mission, terrainId, filename)
    end
end
function PrecisionFarming:sendInitialClientState(connection, user, farm)
    local i = 1
    for i = i, #self.valueMaps do
        if self.valueMaps[i].sendInitialClientState ~= nil then
            self.valueMaps[i]:sendInitialClientState(connection, user, farm)
        end
    end
    self.precisionFarmingSettings:sendInitialClientState(connection, user, farm)
end
function PrecisionFarming:deleteMap()
    if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
        local i = #self.visualizationOverlays
        for i = i, 1, -1 do
            resetDensityMapVisualizationOverlay(self.visualizationOverlays[i])
            self.visualizationOverlays[i] = nil
        end
        local i = 1
        for i = i, #self.valueMaps do
            self.valueMaps[i]:delete()
        end
        self.inGameMenuMapFrameExtension:delete()
        self.shopConfigScreenExtension:delete()
        self.inGameMapExtension:delete()
        self.aiExtension:delete()
        self.fieldInfoDisplayExtension:delete()
        self.harvestExtension:delete()
        self.helplineExtension:delete()
        self.farmlandStatistics:delete()
        self.additionalFieldBuyInfo:delete()
        self.cropSensorLinkageData:delete()
        self.manureSensorLinkageData:delete()
        self.sprayerNodeData:delete()
        self.subsidies:delete()
        self.environmentalScore:delete()
        self.precisionFarmingDebug:delete()
        local i = #self.overwrittenGameFunctions
        for i = i, 1, -1 do
            local reference = self.overwrittenGameFunctions[i]
            reference.object[reference.funcName] = reference.oldFunc
            self.overwrittenGameFunctions[i] = nil
        end
    end
end
function PrecisionFarming:loadFromItemsXML(xmlFile, key)
    local i = #self.valueMaps
    for i = i, 1, -1 do
        self.valueMaps[i]:loadFromItemsXML(xmlFile, key)
    end
    self.farmlandStatistics:loadFromItemsXML(xmlFile, key)
    self.additionalFieldBuyInfo:loadFromItemsXML(xmlFile, key)
    self.environmentalScore:loadFromItemsXML(xmlFile, key)
    self.densityMapUpdater:loadFromItemsXML(xmlFile, key)
end
function PrecisionFarming:saveToXMLFile(xmlFile, key, usedModNames)
    local i = 1
    for i = i, #self.valueMaps do
        self.valueMaps[i]:saveToXMLFile(xmlFile, key, usedModNames)
    end
    self.farmlandStatistics:saveToXMLFile(xmlFile, key, usedModNames)
    self.additionalFieldBuyInfo:saveToXMLFile(xmlFile, key, usedModNames)
    self.environmentalScore:saveToXMLFile(xmlFile, key, usedModNames)
    self.densityMapUpdater:saveToXMLFile(xmlFile, key, usedModNames)
end
function PrecisionFarming:addSetting(...)
    self.precisionFarmingSettings:addSetting(...)
end
function PrecisionFarming:registerVisualizationOverlay(overlay)
    table.insert(self.visualizationOverlays, overlay)
end
function PrecisionFarming:update(dt)
    if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
        local i = 1
        for i = i, #self.valueMaps do
            self.valueMaps[i]:update(dt)
        end
        self.inGameMenuMapFrameExtension:update(dt)
        self.shopConfigScreenExtension:update(dt)
        self.inGameMapExtension:update(dt)
        self.additionalFieldBuyInfo:update(dt)
        self.harvestExtension:update(dt)
        self.environmentalScore:update(dt)
        self.densityMapUpdater:update(dt)
        if self.firstTimeRun then
            self.firstTimeRunDelay = math.max(self.firstTimeRunDelay - dt, 0)
            if self.firstTimeRunDelay == 0 and self.helplineExtension:getAllowFirstTimeEvent() then
                self.helplineExtension:onFirstTimeRun()
                self.firstTimeRun = false
            end
        end
    end
end
function PrecisionFarming:draw()
    if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
        self.harvestExtension:draw()
    end
end
function PrecisionFarming:registerValueMap(object)
    table.insert(self.valueMaps, object)
    self[object.name] = object
    object.valueMapIndex = #self.valueMaps
end
function PrecisionFarming:getValueMaps()
    return self.valueMaps
end
function PrecisionFarming:getValueMap(index)
    return self.valueMaps[index]
end
function PrecisionFarming:updatePrecisionFarmingOverlays()
    self.inGameMapExtension:updatePrecisionFarmingOverlays()
    self.inGameMenuMapFrameExtension:updatePrecisionFarmingOverlays()
end
function PrecisionFarming:onValueMapSelectionChanged(valueMap)
    self.yieldMap:onValueMapSelectionChanged(valueMap)
end
function PrecisionFarming:onFarmlandSelectionChanged(farmlandId, fieldNumber, fieldArea)
    self.yieldMap:onFarmlandSelectionChanged(farmlandId, fieldNumber, fieldArea)
end
function PrecisionFarming:setMapFrame(mapFrame)
    if self.additionalFieldBuyInfo ~= nil then
        self.additionalFieldBuyInfo:setMapFrame(mapFrame)
    end
    if self.soilMap ~= nil then
        self.soilMap:setMapFrame(mapFrame)
    end
    if self.farmlandStatistics ~= nil then
        self.farmlandStatistics:setMapFrame(mapFrame)
    end
    if self.yieldMap ~= nil then
        self.yieldMap:setMapFrame(mapFrame)
    end
    if self.tramlineMap ~= nil then
        self.tramlineMap:setMapFrame(mapFrame)
    end
    if self.environmentalScore ~= nil then
        self.environmentalScore:setMapFrame(mapFrame)
    end
end
function PrecisionFarming:onMapFrameOpen(mapFrame)
    if self.environmentalScore ~= nil then
        self.environmentalScore:onMapFrameOpen(mapFrame)
    end
end
function PrecisionFarming:collectFieldInfos(fieldInfoDisplayExtension)
    local i = 1
    for i = i, #self.valueMaps do
        self.valueMaps[i]:collectFieldInfos(fieldInfoDisplayExtension)
    end
end
function PrecisionFarming:collectFarmlandHotspotActions(farmlandHotspotActions)
    local i = 1
    for i = i, #self.valueMaps do
        self.valueMaps[i]:collectFarmlandHotspotActions(farmlandHotspotActions)
    end
    self.farmlandStatistics:collectFarmlandHotspotActions(farmlandHotspotActions)
end
function PrecisionFarming:getIsMaizePlusActive()
    return g_modIsLoaded.FS25_MaizePlus
end
function PrecisionFarming:getCropSensorLinkageData(configFileName)
    return self.cropSensorLinkageData:getCropSensorLinkageData(configFileName)
end
function PrecisionFarming:getClonedCropSensorNode(typeName)
    return self.cropSensorLinkageData:getClonedCropSensorNode(typeName)
end
function PrecisionFarming:getManureSensorLinkageData(configFileName)
    return self.manureSensorLinkageData:getManureSensorLinkageData(configFileName)
end
function PrecisionFarming:getClonedManureSensorNode(typeName)
    return self.manureSensorLinkageData:getClonedManureSensorNode(typeName)
end
function PrecisionFarming:getSprayerNodeData(configFileName, configurations)
    return self.sprayerNodeData:getSprayerNodeData(configFileName, configurations)
end
function PrecisionFarming:getClonedSprayerEffectNode()
    return self.sprayerNodeData:getClonedSprayerEffectNode()
end
function PrecisionFarming:getClonedSprayerWeedSensorNode(sensorTypeId)
    return self.sprayerNodeData:getClonedSprayerWeedSensorNode(sensorTypeId)
end
function PrecisionFarming:getSprayerConfigPrices()
    return self.sprayerNodeData:getConfigPrices()
end
function PrecisionFarming:getSprayerClonedSectionSamples(name, linkNode, modifierTargetObject)
    return self.sprayerNodeData:getClonedSectionSamples(name, linkNode, modifierTargetObject)
end
function PrecisionFarming.getFarmlandFieldInfo(_, farmlandId)
    local farmland = g_farmlandManager.farmlands[farmlandId]
    local fieldArea = farmland ~= nil and (farmland.totalFieldArea or 0) or 0
    local fields = g_fieldManager:getFields()
    if fields ~= nil then
        for _, field in pairs(fields) do
            if field.farmland ~= nil and field.farmland.id == farmlandId then
                return field:getId(), fieldArea
            end
        end
    end
    return 0, fieldArea
end
function PrecisionFarming:overwriteGameFunction(object, funcName, newFunc)
    if object == nil then
        Logging.error("Failed to overwrite \'%s\'", funcName)
        printCallstack()
    else
        local oldFunc = object[funcName]
        if oldFunc ~= nil then
            object[funcName] = function(...)
                -- upvalues: (copy) newFunc, (copy) oldFunc
                return newFunc(oldFunc, ...)
            end
        end
        table.insert(self.overwrittenGameFunctions, {
            ["object"] = object,
            ["funcName"] = funcName,
            ["oldFunc"] = oldFunc
        })
    end
end
g_precisionFarming = PrecisionFarming.new()
addModEventListener(g_precisionFarming)
TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, function(self)
    if self.typeName == "vehicle" and (g_modIsLoaded[PrecisionFarming.MOD_NAME] and g_iconGenerator == nil) then
        g_precisionFarming:initialize()
    end
end)
ItemSystem.save = Utils.prependedFunction(ItemSystem.save, function(_, _, usedModNames)
    if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
        local xmlFile = XMLFile.create("precisionFarmingXML", g_currentMission.missionInfo.savegameDirectory .. "/precisionFarming.xml", "precisionFarming")
        if xmlFile ~= nil then
            g_precisionFarming:saveToXMLFile(xmlFile, "precisionFarming", usedModNames)
            xmlFile:save()
            xmlFile:delete()
        end
    end
end)
ItemSystem.loadItems = Utils.prependedFunction(ItemSystem.loadItems, function(itemsSystem, xmlFilename, ...)
    if g_modIsLoaded[PrecisionFarming.MOD_NAME] and g_currentMission.missionInfo.savegameDirectory ~= nil then
        local xmlFilenamePrecisionFarming = g_currentMission.missionInfo.savegameDirectory .. "/precisionFarming.xml"
        if fileExists(xmlFilenamePrecisionFarming) then
            local xmlFile = XMLFile.load("precisionFarmingXML", xmlFilenamePrecisionFarming)
            if xmlFile ~= nil then
                g_precisionFarming:loadFromItemsXML(xmlFile, "precisionFarming")
                xmlFile:delete()
            end
        end
    end
end)
Gui.unloadMapData = Utils.prependedFunction(Gui.unloadMapData, function(mission, xmlFilename)
    if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
        g_precisionFarming:unloadMapData()
    end
end)
FSBaseMission.initTerrain = Utils.appendedFunction(FSBaseMission.initTerrain, function(mission, terrainId, filename)
    if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
        g_precisionFarming:initTerrain(mission, terrainId, filename)
    end
end)
FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState, function(_, connection, user, farm)
    if g_modIsLoaded[PrecisionFarming.MOD_NAME] then
        g_precisionFarming:sendInitialClientState(connection, user, farm)
    end
end)