FSCareerMissionInfo = {}
local FSCareerMissionInfo_mt = Class(FSCareerMissionInfo, MissionInfo)
FSCareerMissionInfo.SavegameRevision = 2
if GS_PLATFORM_PLAYSTATION then
    FSCareerMissionInfo.MaxSavegameSize = 52428800
else
    FSCareerMissionInfo.MaxSavegameSize = 26214400
end
function FSCareerMissionInfo.new(baseDirectory, customEnvironment, savegameIndex, customMt)
    -- upvalues: (copy) FSCareerMissionInfo_mt
    local self = FSCareerMissionInfo:superClass().new(baseDirectory, customEnvironment, customMt or FSCareerMissionInfo_mt)
    self.savegameIndex = savegameIndex
    self.savegameDirectory = self:getSavegameDirectory(self.savegameIndex)
    self.displayName = g_i18n:getText("ui_savegame") .. " " .. self.savegameIndex
    self.xmlKey = "careerSavegame"
    self.tipTypeMappings = {}
    return self
end
function FSCareerMissionInfo:delete()
    if self.xmlFile ~= nil then
        delete(self.xmlFile)
    end
end
function FSCareerMissionInfo:loadDefaults()
    FSCareerMissionInfo:superClass().loadDefaults(self)
    self.supportsSaving = true
    self.isValid = false
    self.initialPlatformId = getPlatformId()
    self.isCrossPlatformSavegame = true
    self.initialLoan = 0
    self.initialMoney = 100000
    self.money = nil
    self.economicDifficulty = EconomicDifficulty.NORMAL
    self.hasInitiallyOwnedFarmlands = true
    self.loadDefaultFarm = true
    self.startWithGuidedTour = true
    self.playTime = 0
    self.isInvalidUser = false
    self.isCorruptFile = false
    self.savegameName = g_i18n:getText("defaultSavegameName")
    self.saveDateFormatted = "--/--/--"
    self.creationDate = getDate("%Y-%m-%d")
    self.saveDate = nil
    self.mapId = nil
    self.stopAndGoBraking = true
    self.trailerFillLimit = false
    self.fruitDestruction = true
    self.automaticMotorStartEnabled = true
    self.isSnowEnabled = Platform.gameplay.supportSnow
    self.growthMode = Platform.gameplay.supportSeasonalGrowth and GrowthMode.SEASONAL or GrowthMode.DAILY
    self.fixedSeasonalVisuals = nil
    self.helperBuyFuel = true
    self.helperBuySeeds = true
    self.helperBuyFertilizer = true
    self.helperSlurrySource = 2
    self.helperManureSource = 2
    self.plowingRequiredEnabled = Utils.getNoNil(Platform.gameplay.defaultPlowingRequiredEnabled, false)
    self.stonesEnabled = true
    self.autoSaveInterval = AutoSaveManager.DEFAULT_INTERVAL
    self.trafficEnabled = true
    self.introductionHelpShownElements = ""
    self.introductionHelpShownHints = ""
    self.introductionHelpActive = false
    self.disasterDestructionState = DisasterDestructionState.ENABLED
    self.slotUsage = 0
    self.plannedDaysPerPeriod = 1
    self.timeScale = Platform.gameplay.defaultTimeScale
    self.timeScaleMultiplier = 1
    self.dirtInterval = 3
    self.weedsEnabled = true
    self.limeRequired = true
    self.fuelUsage = 2
    self.foundHelpIcons = "00000000000000000000"
    self.vehiclesXML = nil
    self.itemsXML = nil
    self.placeablesXML = nil
    self.handToolsXML = nil
    self.aiSystemXML = nil
    self.onCreateObjectsXML = nil
    self.environmentXML = nil
    self.vehicleSaleXML = nil
    self.economyXML = nil
    self.farmlandXML = nil
    self.npcXML = nil
    self.missionsXML = nil
    self.guidedTourXML = nil
    self.fieldsXML = nil
    self.destructibleMapObjectsXML = nil
    self.farmsXML = nil
    self.treeMarkerXML = nil
    self.playersXML = nil
    self.densityMapHeightXML = nil
    self.treePlantXML = nil
    self.navigationSystemXML = nil
    self.densityMapRevision = -1
    self.terrainTextureRevision = -1
    self.terrainLodTextureRevision = -1
    self.splitShapesRevision = -1
    self.tipCollisionRevision = -1
    self.placementCollisionRevision = -1
    self.navigationCollisionRevision = -1
    self.mapDensityMapRevision = 1
    self.mapTerrainTextureRevision = 1
    self.mapTerrainLodTextureRevision = 1
    self.mapSplitShapesRevision = 1
    self.mapTipCollisionRevision = 1
    self.mapPlacementCollisionRevision = 1
    self.mapNavigationCollisionRevision = 1
    self.tipTypeMappings = {}
    self.mods = {}
end
function FSCareerMissionInfo:loadFromXML(xmlFile)
    local key = self.xmlKey
    if getXMLInt(xmlFile, key .. "#revision") ~= FSCareerMissionInfo.SavegameRevision then
        return false
    end
    self.isValid = getXMLBool(xmlFile, key .. "#valid")
    if self.isValid == nil then
        return false
    end
    if self.isValid then
        local mapId = getXMLString(xmlFile, key .. ".settings.mapId")
        if mapId == nil then
            return false
        end
        self.mapTitle = getXMLString(xmlFile, key .. ".settings.mapTitle")
        self:setMapId(mapId)
        self.isInvalidUser = false
        self.savegameName = filterText(Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.savegameName"), self.savegameName), true, true)
        self.creationDate = Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.creationDate"), self.creationDate)
        self.isCrossPlatformSavegame = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.isCrossPlatformSavegame"), false)
        self.initialPlatformId = Utils.getNoNil(PlatformId[getXMLString(xmlFile, key .. ".settings.initialPlatformName")], self.initialPlatformId)
        self.economicDifficulty = EconomicDifficulty.loadFromXMLFile(xmlFile, key .. ".settings.economicDifficulty") or self.economicDifficulty
        self.initialLoan = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.initialLoan"), self.initialLoan)
        self.initialMoney = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.initialMoney"), self.initialMoney)
        self.hasInitiallyOwnedFarmlands = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.hasInitiallyOwnedFarmlands"), self.hasInitiallyOwnedFarmlands)
        self.loadDefaultFarm = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.loadDefaultFarm"), self.loadDefaultFarm)
        self.startWithGuidedTour = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.startWithGuidedTour"), self.startWithGuidedTour)
        self.densityMapRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.densityMapRevision"), self.densityMapRevision)
        self.terrainTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.terrainTextureRevision"), self.terrainTextureRevision)
        self.terrainLodTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.terrainLodTextureRevision"), self.terrainLodTextureRevision)
        self.splitShapesRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.splitShapesRevision"), self.splitShapesRevision)
        self.tipCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.tipCollisionRevision"), self.tipCollisionRevision)
        self.placementCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.placementCollisionRevision"), self.placementCollisionRevision)
        self.navigationCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.navigationCollisionRevision"), self.navigationCollisionRevision)
        self.mapDensityMapRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapDensityMapRevision"), self.mapDensityMapRevision)
        self.mapTerrainTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapTerrainTextureRevision"), self.mapTerrainTextureRevision)
        self.mapTerrainLodTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapTerrainLodTextureRevision"), self.mapTerrainLodTextureRevision)
        self.mapSplitShapesRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapSplitShapesRevision"), self.mapSplitShapesRevision)
        self.mapTipCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapTipCollisionRevision"), self.mapTipCollisionRevision)
        self.mapPlacementCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapPlacementCollisionRevision"), self.mapPlacementCollisionRevision)
        self.mapNavigationCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapNavigationCollisionRevision"), self.mapNavigationCollisionRevision)
        self.stopAndGoBraking = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.stopAndGoBraking"), self.stopAndGoBraking)
        self.trailerFillLimit = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.trailerFillLimit"), self.trailerFillLimit)
        self.fruitDestruction = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.fruitDestruction"), self.fruitDestruction)
        self.plowingRequiredEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.plowingRequiredEnabled"), self.plowingRequiredEnabled)
        self.stonesEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.stonesEnabled"), self.stonesEnabled)
        self.weedsEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.weedsEnabled"), self.weedsEnabled)
        self.limeRequired = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.limeRequired"), self.limeRequired)
        self.automaticMotorStartEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.automaticMotorStartEnabled"), self.automaticMotorStartEnabled)
        self.fuelUsage = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.fuelUsage"), self.fuelUsage)
        self.helperBuyFuel = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.helperBuyFuel"), self.helperBuyFuel)
        self.helperBuySeeds = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.helperBuySeeds"), self.helperBuySeeds)
        self.helperBuyFertilizer = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.helperBuyFertilizer"), self.helperBuyFertilizer)
        self.helperSlurrySource = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.helperSlurrySource"), self.helperSlurrySource)
        self.helperManureSource = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.helperManureSource"), self.helperManureSource)
        self.saveDate = Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.saveDate"), nil)
        self.saveDateFormatted = Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.saveDateFormatted"), self.saveDate)
        self.timeScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".settings.timeScale"), Platform.gameplay.defaultTimeScale)
        self.trafficEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.trafficEnabled"), self.trafficEnabled)
        self.dirtInterval = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.dirtInterval"), self.dirtInterval)
        self.growthMode = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.growthMode"), self.growthMode)
        self.isSnowEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.isSnowEnabled"), self.isSnowEnabled)
        self.fixedSeasonalVisuals = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.fixedSeasonalVisuals"), self.fixedSeasonalVisuals)
        self.plannedDaysPerPeriod = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.plannedDaysPerPeriod"), self.plannedDaysPerPeriod)
        self.autoSaveInterval = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".settings.autoSaveInterval"), self.autoSaveInterval)
        self.foundHelpIcons = Utils.getNoNil(getXMLString(xmlFile, key .. ".map.foundHelpIcons"), self.foundHelpIcons)
        self.playTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".statistics.playTime"), self.playTime)
        local i = getXMLString
        local fileIdKey = key .. ".statistics.money"
        self.money = Utils.getNoNil(tonumber(i(xmlFile, fileIdKey)), self.money)
        self.slotUsage = Utils.getNoNil(getXMLInt(xmlFile, key .. ".slotSystem#slotUsage"), self.slotUsage)
        self.disasterDestructionState = DisasterDestructionState.loadFromXMLFile(xmlFile, key .. ".settings.disasterDestructionState") or self.disasterDestructionState
        self.introductionHelpActive = Utils.getNoNil(getXMLBool(xmlFile, key .. ".introductionHelp#active"), self.introductionHelpActive)
        self.introductionHelpShownElements = Utils.getNoNil(getXMLString(xmlFile, key .. ".introductionHelp.shownElements"), self.introductionHelpShownElements)
        self.introductionHelpShownHints = Utils.getNoNil(getXMLString(xmlFile, key .. ".introductionHelp.shownHints"), self.introductionHelpShownHints)
        self.mapsSplitShapeFileIds = {}
        local i = 1
        local i = 1
        for i = i, Utils.getNoNil(getXMLInt(xmlFile, key .. ".mapsSplitShapeFileIds#count"), 0), i do
            local fileIdKey = string.format("%s.mapsSplitShapeFileIds.id(%d)", key, i - 1)
            local id = Utils.getNoNil(getXMLInt(xmlFile, fileIdKey .. "#id"), -1)
            table.insert(self.mapsSplitShapeFileIds, id)
        end
        local mapModNameParts = nil
        if self.mapId ~= nil then
            mapModNameParts = self.mapId:split(".")
        end
        self.foliageTypes = {}
        local i = 0
        while true do
            local i = string.format("careerSavegame.foliageTypes.foliageType(%d)", i)
            if not hasXMLProperty(xmlFile, i) then
                break
            end
            local fileIdKey = getXMLString(xmlFile, i .. "#name")
            local id = getXMLString(xmlFile, i .. "#filename")
            if fileIdKey ~= nil and id ~= nil then
                local version = NetworkUtil.convertFromNetworkFilename(id)
                table.insert(self.foliageTypes, {
                    ["name"] = fileIdKey,
                    ["filename"] = version
                })
            end
            i = i + 1
        end
        self.mods = {}
        local i = 0
        while true do
            local i = key .. string.format(".mod(%d)", i)
            if not hasXMLProperty(xmlFile, i) then
                break
            end
            local fileIdKey = getXMLString(xmlFile, i .. "#modName")
            local id = getXMLString(xmlFile, i .. "#title")
            local version = getXMLString(xmlFile, i .. "#version")
            local fileHash = getXMLString(xmlFile, i .. "#fileHash")
            local required = Utils.getNoNil(getXMLBool(xmlFile, i .. "#required"), true)
            if fileIdKey ~= nil and id ~= nil then
                table.insert(self.mods, {
                    ["modName"] = fileIdKey,
                    ["title"] = id,
                    ["version"] = version,
                    ["fileHash"] = fileHash,
                    ["required"] = required
                })
            end
            if self.mapTitle == nil and (mapModNameParts ~= nil and (#mapModNameParts == 2 and fileIdKey == mapModNameParts[1])) then
                self.mapTitle = id .. " - " .. mapModNameParts[2]
            end
            i = i + 1
        end
    end
    return true
end
function FSCareerMissionInfo:saveToXMLFile()
    if self.xmlFile ~= nil then
        delete(self.xmlFile)
    end
    local xmlFile = createXMLFile("careerSavegameXML", "", "careerSavegame")
    if xmlFile == 0 then
        Logging.error("Failed to create careerSavegame xml file")
    else
        self.xmlFile = xmlFile
        local key = self.xmlKey
        setXMLInt(xmlFile, key .. "#revision", FSCareerMissionInfo.SavegameRevision)
        setXMLBool(xmlFile, key .. "#valid", self.isValid)
        if self.isValid then
            setXMLString(xmlFile, key .. ".settings.savegameName", self.savegameName)
            setXMLString(xmlFile, key .. ".settings.creationDate", self.creationDate)
            setXMLString(xmlFile, key .. ".settings.mapId", self.mapId)
            setXMLString(xmlFile, key .. ".settings.mapTitle", self.map.title)
            setXMLString(xmlFile, key .. ".settings.saveDateFormatted", self.saveDateFormatted)
            setXMLString(xmlFile, key .. ".settings.saveDate", self.saveDate)
            setXMLInt(xmlFile, key .. ".settings.initialMoney", self.initialMoney)
            setXMLInt(xmlFile, key .. ".settings.initialLoan", self.initialLoan)
            EconomicDifficulty.saveToXMLFile(xmlFile, key .. ".settings.economicDifficulty", self.economicDifficulty)
            setXMLBool(xmlFile, key .. ".settings.hasInitiallyOwnedFarmlands", self.hasInitiallyOwnedFarmlands)
            setXMLBool(xmlFile, key .. ".settings.loadDefaultFarm", self.loadDefaultFarm)
            setXMLBool(xmlFile, key .. ".settings.startWithGuidedTour", self.startWithGuidedTour)
            setXMLBool(xmlFile, key .. ".settings.trafficEnabled", self.trafficEnabled)
            setXMLBool(xmlFile, key .. ".settings.stopAndGoBraking", self.stopAndGoBraking)
            setXMLBool(xmlFile, key .. ".settings.trailerFillLimit", self.trailerFillLimit)
            setXMLBool(xmlFile, key .. ".settings.automaticMotorStartEnabled", self.automaticMotorStartEnabled)
            setXMLInt(xmlFile, key .. ".settings.growthMode", self.growthMode)
            if self.fixedSeasonalVisuals ~= nil then
                setXMLInt(xmlFile, key .. ".settings.fixedSeasonalVisuals", self.fixedSeasonalVisuals)
            end
            setXMLInt(xmlFile, key .. ".settings.plannedDaysPerPeriod", self.plannedDaysPerPeriod)
            setXMLBool(xmlFile, key .. ".settings.fruitDestruction", self.fruitDestruction)
            setXMLBool(xmlFile, key .. ".settings.plowingRequiredEnabled", self.plowingRequiredEnabled)
            setXMLBool(xmlFile, key .. ".settings.stonesEnabled", self.stonesEnabled)
            setXMLBool(xmlFile, key .. ".settings.weedsEnabled", self.weedsEnabled)
            setXMLBool(xmlFile, key .. ".settings.limeRequired", self.limeRequired)
            setXMLBool(xmlFile, key .. ".settings.isSnowEnabled", self.isSnowEnabled)
            setXMLInt(xmlFile, key .. ".settings.fuelUsage", self.fuelUsage)
            setXMLBool(xmlFile, key .. ".settings.helperBuyFuel", self.helperBuyFuel)
            setXMLBool(xmlFile, key .. ".settings.helperBuySeeds", self.helperBuySeeds)
            setXMLBool(xmlFile, key .. ".settings.helperBuyFertilizer", self.helperBuyFertilizer)
            setXMLInt(xmlFile, key .. ".settings.helperSlurrySource", self.helperSlurrySource)
            setXMLInt(xmlFile, key .. ".settings.helperManureSource", self.helperManureSource)
            setXMLInt(xmlFile, key .. ".settings.densityMapRevision", self.densityMapRevision)
            setXMLInt(xmlFile, key .. ".settings.terrainTextureRevision", self.terrainTextureRevision)
            setXMLInt(xmlFile, key .. ".settings.terrainLodTextureRevision", self.terrainLodTextureRevision)
            setXMLInt(xmlFile, key .. ".settings.splitShapesRevision", self.splitShapesRevision)
            setXMLInt(xmlFile, key .. ".settings.tipCollisionRevision", self.tipCollisionRevision)
            setXMLInt(xmlFile, key .. ".settings.placementCollisionRevision", self.placementCollisionRevision)
            setXMLInt(xmlFile, key .. ".settings.navigationCollisionRevision", self.navigationCollisionRevision)
            setXMLInt(xmlFile, key .. ".settings.mapDensityMapRevision", self.mapDensityMapRevision)
            setXMLInt(xmlFile, key .. ".settings.mapTerrainTextureRevision", self.mapTerrainTextureRevision)
            setXMLInt(xmlFile, key .. ".settings.mapTerrainLodTextureRevision", self.mapTerrainLodTextureRevision)
            setXMLInt(xmlFile, key .. ".settings.mapSplitShapesRevision", self.mapSplitShapesRevision)
            setXMLInt(xmlFile, key .. ".settings.mapTipCollisionRevision", self.mapTipCollisionRevision)
            setXMLInt(xmlFile, key .. ".settings.mapPlacementCollisionRevision", self.mapPlacementCollisionRevision)
            setXMLInt(xmlFile, key .. ".settings.mapNavigationCollisionRevision", self.mapNavigationCollisionRevision)
            DisasterDestructionState.saveToXMLFile(xmlFile, key .. ".settings.disasterDestructionState", self.disasterDestructionState)
            setXMLInt(xmlFile, key .. ".settings.dirtInterval", self.dirtInterval)
            setXMLFloat(xmlFile, key .. ".settings.timeScale", self.timeScale)
            setXMLFloat(xmlFile, key .. ".settings.autoSaveInterval", g_autoSaveManager:getInterval())
            setXMLString(xmlFile, key .. ".map.foundHelpIcons", self.foundHelpIcons)
            setXMLBool(xmlFile, key .. ".introductionHelp#active", self.introductionHelpActive)
            setXMLString(xmlFile, key .. ".introductionHelp.shownElements", self.introductionHelpShownElements)
            setXMLString(xmlFile, key .. ".introductionHelp.shownHints", self.introductionHelpShownHints)
            local money = 0
            local maxPlayTime = 0
            for _, farm in ipairs(g_farmManager.farms) do
                if not farm.isSpectator then
                    maxPlayTime = math.max(maxPlayTime, farm.stats:getTotalValue("playTime"))
                end
            end
            local usedModNames = setXMLString
            local mission = key .. ".statistics.money"
            local farm = math.floor(money + 0.0001)
            usedModNames(xmlFile, mission, (tostring(farm)))
            setXMLFloat(xmlFile, key .. ".statistics.playTime", maxPlayTime)
            setXMLInt(xmlFile, key .. ".mapsSplitShapeFileIds#count", #self.mapsSplitShapeFileIds)
            for _, farm in ipairs(self.mapsSplitShapeFileIds) do
                setXMLInt(xmlFile, string.format("%s.mapsSplitShapeFileIds.id(%d)", key, _ - 1) .. "#id", farm)
            end
            local usedModNames = {}
            usedModNames[mapModName] = ClassUtil.getClassModName(self.mapId) or usedModNames[mapModName]
            local mission = g_currentMission
            if mission ~= nil then
                mission.slotSystem:saveToXMLFile(xmlFile, key .. ".slotSystem")
                mission.navigationSystem:saveToXMLFile(self.navigationSystemXML)
                mission.collectiblesSystem:saveToXMLFile(self.savegameDirectory .. "/collectibles.xml")
                local _ = createXMLFile("environmentXMLFile", self.environmentXML, "environment")
                if _ == 0 then
                    Logging.error("Failed to create environment xml file")
                else
                    mission.environment:saveToXMLFile(_, "environment")
                    mission.snowSystem:saveToXMLFile(_, "environment.snow")
                    mission.growthSystem:saveToXMLFile(_, "environment.growth")
                    saveXMLFile(_)
                    delete(_)
                end
                mission.placeableSystem:save(self.placeablesXML, usedModNames)
                mission.vehicleSystem:save(self.vehiclesXML, usedModNames)
                mission.handToolSystem:save(self.handToolsXML, usedModNames)
                mission.itemSystem:save(self.itemsXML, usedModNames)
                mission.aiSystem:save(self.aiSystemXML, usedModNames)
                mission.onCreateObjectSystem:save(self.onCreateObjectsXML, usedModNames)
                local farm = createXMLFile("economyXML", self.economyXML, "economy")
                if farm == 0 then
                    Logging.error("Failed to create economy xml file")
                else
                    mission.economyManager:saveToXMLFile(farm, "economy")
                    saveXMLFile(farm)
                    delete(farm)
                end
                mission.playerSystem:saveToXMLFile(self.playersXML)
                mission.vehicleSaleSystem:saveToXMLFile(self.vehicleSaleXML)
                mission.foliageSystem:saveToXMLFile(xmlFile)
                mission.treeMarkerSystem:saveToXMLFile(self.treeMarkerXML)
                mission.destructibleMapObjectSystem:saveToXMLFile(self.destructibleMapObjectsXML)
                for _, modItem in pairs(mission.missionDynamicInfo.mods) do
                    usedModNames[modItem.modName] = modItem.modName
                end
            end
            g_farmlandManager:saveToXMLFile(self.farmlandXML)
            g_guidedTourManager:saveToXMLFile(self.guidedTourXML)
            g_npcManager:saveToXMLFile(self.npcXML)
            g_fieldManager:saveToXMLFile(self.fieldsXML)
            g_missionManager:saveToXMLFile(self.missionsXML)
            g_farmManager:saveToXMLFile(self.farmsXML)
            g_densityMapHeightManager:saveToXMLFile(self.densityMapHeightXML)
            g_treePlantManager:saveToXMLFile(self.treePlantXML)
            local _ = 0
            for modName, _ in pairs(usedModNames) do
                local modItem = g_modManager:getModByName(modName)
                if modItem ~= nil then
                    local modKey = string.format("%s.mod(%d)", key, _)
                    setXMLString(xmlFile, modKey .. "#modName", modItem.modName)
                    setXMLString(xmlFile, modKey .. "#title", modItem.title)
                    setXMLString(xmlFile, modKey .. "#version", modItem.version)
                    setXMLBool(xmlFile, modKey .. "#required", modName == mapModName)
                    setXMLString(xmlFile, modKey .. "#fileHash", modItem.fileHash or "")
                    if self.isCrossPlatformSavegame then
                        local isCrossPlatformMod = false
                        if modItem.isDLC or modItem.isInternalScriptMod then
                            isCrossPlatformMod = true
                        elseif not modItem.hasScripts then
                            local modId = getModIdByFilename(modItem.modName)
                            isCrossPlatformMod = modId ~= 0 and getModMetaAttributeString(modId, "hash") == modItem.fileHash and true or isCrossPlatformMod
                        end
                        if not isCrossPlatformMod then
                            Logging.info("Found non-crossplay mod. Disabled savegame cross platform availability")
                            self.isCrossPlatformSavegame = false
                        end
                    end
                    _ = _ + 1
                end
            end
            setXMLBool(xmlFile, key .. ".settings.isCrossPlatformSavegame", self.isCrossPlatformSavegame)
            setXMLString(xmlFile, key .. ".settings.initialPlatformName", EnumUtil.getName(PlatformId, self.initialPlatformId))
            saveXMLFile(xmlFile)
        end
    end
end
function FSCareerMissionInfo:loadFromMission(mission)
    self.mapDensityMapRevision = mission.mapDensityMapRevision
    self.mapTerrainTextureRevision = mission.mapTerrainTextureRevision
    self.mapTerrainLodTextureRevision = mission.mapTerrainLodTextureRevision
    self.mapSplitShapesRevision = mission.mapSplitShapesRevision
    self.mapTipCollisionRevision = mission.mapTipCollisionRevision
    self.mapPlacementCollisionRevision = mission.mapPlacementCollisionRevision
    self.mapNavigationCollisionRevision = mission.mapNavigationCollisionRevision
    self.mapsSplitShapeFileIds = {}
    for _, id in ipairs(mission.mapsSplitShapeFileIds) do
        table.insert(self.mapsSplitShapeFileIds, id)
    end
    self.saveDate = getDate("%Y-%m-%d")
    self.saveDateFormatted = g_i18n:getCurrentDate()
end
function FSCareerMissionInfo:setSavegameDirectory(directory)
    self.savegameDirectory = directory
    if directory ~= nil then
        self.vehiclesXML = directory .. "/vehicles.xml"
        self.itemsXML = directory .. "/items.xml"
        self.placeablesXML = directory .. "/placeables.xml"
        self.handToolsXML = directory .. "/handTools.xml"
        self.aiSystemXML = directory .. "/aiSystem.xml"
        self.onCreateObjectsXML = directory .. "/onCreateObjects.xml"
        self.environmentXML = directory .. "/environment.xml"
        self.vehicleSaleXML = directory .. "/sales.xml"
        self.economyXML = directory .. "/economy.xml"
        self.farmlandXML = directory .. "/farmland.xml"
        self.npcXML = directory .. "/npc.xml"
        self.missionsXML = directory .. "/missions.xml"
        self.fieldsXML = directory .. "/fields.xml"
        self.guidedTourXML = directory .. "/guidedTour.xml"
        self.farmsXML = directory .. "/farms.xml"
        self.destructibleMapObjectsXML = directory .. "/destructibleMapObjectSystem.xml"
        self.treeMarkerXML = directory .. "/treeMarker.xml"
        self.playersXML = directory .. "/players.xml"
        self.densityMapHeightXML = directory .. "/densityMapHeight.xml"
        self.treePlantXML = directory .. "/treePlant.xml"
        self.navigationSystemXML = directory .. "/navigationSystem.xml"
    end
end
function FSCareerMissionInfo.getSavegameDirectory(_, index)
    return getUserProfileAppPath() .. "savegame" .. index
end
function FSCareerMissionInfo:getSavegameAutoBackupBasePath()
    return getUserProfileAppPath() .. "savegameBackup"
end
function FSCareerMissionInfo.getSavegameAutoBackupDirectoryBase(_, index)
    return "savegame" .. index .. "_backup"
end
function FSCareerMissionInfo.getSavegameAutoBackupLatestFilename(_, index)
    return "savegame" .. index .. "_backupLatest.txt"
end
function FSCareerMissionInfo:getStateI18NKey()
    return self.hasConflict and not self.isSoftConflict and "savegame_state_conflicted" or (self.uploadState == UploadState.UPLOADED and "savegame_state_uploaded" or (self.uploadState == UploadState.NOT_UPLOADED and "savegame_state_not_uploaded" or (self.uploadState == UploadState.UPLOADING and "savegame_state_uploading" or nil)))
end
function FSCareerMissionInfo:applyStartInfo(startInfo)
    self.initialLoan = startInfo.initialLoan
    self.initialMoney = startInfo.initialMoney
    self.economicDifficulty = startInfo.economicDifficulty
    self.hasInitiallyOwnedFarmlands = startInfo.hasStartFarm
    self.loadDefaultFarm = startInfo.hasStartFarm
    self.startWithGuidedTour = startInfo.startWithGuidedTour
    self:setMapId(startInfo.mapId)
end
function FSCareerMissionInfo:setMapId(mapId)
    self.mapId = mapId
    local map = g_mapManager:getMapById(self.mapId)
    if map == nil then
        return false
    end
    self.map = map
    self.mapTitle = map.title
    self.scriptFilename = map.scriptFilename
    self.scriptClass = map.className
    self.mapXMLFilename = map.mapXMLFilename
    self.defaultVehiclesXMLFilename = map.defaultVehiclesXMLFilename
    self.defaultHandToolsXMLFilename = map.defaultHandToolsXMLFilename
    self.defaultItemsXMLFilename = map.defaultItemsXMLFilename
    self.defaultPlaceablesXMLFilename = map.defaultPlaceablesXMLFilename
    self.customEnvironment = map.customEnvironment
    self.baseDirectory = map.baseDirectory
    return true
end
function FSCareerMissionInfo:getIsDensityMapValid(mission)
    return self.isValid and self.densityMapRevision == g_densityMapRevision and self.mapDensityMapRevision == mission.mapDensityMapRevision
end
function FSCareerMissionInfo:getIsTerrainTextureValid(mission)
    return self.isValid and self.terrainTextureRevision == g_terrainTextureRevision and self.mapTerrainTextureRevision == mission.mapTerrainTextureRevision
end
function FSCareerMissionInfo:getIsTerrainLodTextureValid(mission)
    return self.isValid and self.terrainLodTextureRevision == g_terrainLodTextureRevision and self.mapTerrainLodTextureRevision == mission.mapTerrainLodTextureRevision
end
function FSCareerMissionInfo:getAreSplitShapesValid(mission)
    return self.isValid and self.splitShapesRevision == g_splitShapesRevision and self.mapSplitShapesRevision == mission.mapSplitShapesRevision
end
function FSCareerMissionInfo:getIsTipCollisionValid(mission)
    return self.isValid and self.tipCollisionRevision == g_tipCollisionRevision and self.mapTipCollisionRevision == mission.mapTipCollisionRevision
end
function FSCareerMissionInfo:getIsPlacementCollisionValid(mission)
    return self.isValid and self.placementCollisionRevision == g_placementCollisionRevision and self.mapPlacementCollisionRevision == mission.mapPlacementCollisionRevision
end
function FSCareerMissionInfo:getIsNavigationCollisionValid(mission)
    return self.isValid and self.navigationCollisionRevision == g_navigationCollisionRevision and self.mapNavigationCollisionRevision == mission.mapNavigationCollisionRevision
end
function FSCareerMissionInfo:getIsLoadedFromSavegame()
    return self.isValid
end
function FSCareerMissionInfo:getEffectiveTimeScale()
    return self.timeScale * (self.timeScaleMultiplier or 1)
end