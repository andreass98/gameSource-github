FarmStats = {}
local FarmStats_mt = Class(FarmStats)
FarmStats.STAT_NAMES = {
    "fuelUsage",
    "seedUsage",
    "sprayUsage",
    "traveledDistance",
    "workedHectares",
    "cultivatedHectares",
    "plowedHectares",
    "sownHectares",
    "sprayedHectares",
    "threshedHectares",
    "weededHectares",
    "harvestedGrapes",
    "harvestedOlives",
    "workedTime",
    "cultivatedTime",
    "plowedTime",
    "sownTime",
    "sprayedTime",
    "threshedTime",
    "weededTime",
    "baleCount",
    "breedCowsCount",
    "breedPigsCount",
    "breedSheepCount",
    "breedChickenCount",
    "breedHorsesCount",
    "breedGoatsCount",
    "breedWaterBuffaloCount",
    "revenue",
    "expenses",
    "playTime",
    "workersHired",
    "storedBales",
    "storedPallets",
    "missionCount",
    "plantedTreeCount",
    "cutTreeCount",
    "woodTonsSold",
    "treeTypesCut",
    "windTurbineCount",
    "petDogCount",
    "tractorDistance",
    "carDistance",
    "truckDistance",
    "horseDistance",
    "horseJumpCount",
    "repairVehicleCount",
    "repaintVehicleCount",
    "soldCottonBales",
    "wrappedBales"
}
FarmStats.HERO_STAT_NAMES = {
    "playTime",
    "moneyEarned",
    "traveledDistance",
    "completedMissions",
    "threshedHectares"
}
function FarmStats.new()
    -- upvalues: (copy) FarmStats_mt
    local self = setmetatable({}, FarmStats_mt)
    self.statistics = {}
    for _, statName in pairs(FarmStats.STAT_NAMES) do
        self.statistics[statName] = {
            ["session"] = 0,
            ["total"] = 0
        }
    end
    self.statistics.treeTypesCut = "000000"
    self.finances = FinanceStats.new()
    self.financesHistory = {}
    self.heroStats = {}
    for _, statName in pairs(FarmStats.HERO_STAT_NAMES) do
        self.heroStats[statName] = {
            ["id"] = nil,
            ["value"] = nil,
            ["accumValue"] = 0
        }
    end
    self.heroStatsLoaded = false
    self.moneyEarnedHeroAccum = 0
    self.nextHeroAccumUpdate = 0
    if g_currentMission:getIsServer() then
        g_currentMission:addUpdateable(self)
    end
    self.financesVersionCounter = 0
    self.financesHistoryVersionCounter = 0
    self.financesHistoryVersionCounterLocal = 0
    self.updatePlayTime = true
    return self
end
function FarmStats:delete()
    g_currentMission:removeUpdateable(self)
end
function FarmStats:saveToXMLFile(xmlFile, key)
    xmlFile:setFloat(key .. ".statistics.traveledDistance", self.statistics.traveledDistance.total)
    xmlFile:setFloat(key .. ".statistics.fuelUsage", self.statistics.fuelUsage.total)
    xmlFile:setFloat(key .. ".statistics.seedUsage", self.statistics.seedUsage.total)
    xmlFile:setFloat(key .. ".statistics.sprayUsage", self.statistics.sprayUsage.total)
    xmlFile:setFloat(key .. ".statistics.workedHectares", self.statistics.workedHectares.total)
    xmlFile:setFloat(key .. ".statistics.cultivatedHectares", self.statistics.cultivatedHectares.total)
    xmlFile:setFloat(key .. ".statistics.sownHectares", self.statistics.sownHectares.total)
    xmlFile:setFloat(key .. ".statistics.sprayedHectares", self.statistics.sprayedHectares.total)
    xmlFile:setFloat(key .. ".statistics.threshedHectares", self.statistics.threshedHectares.total)
    xmlFile:setFloat(key .. ".statistics.plowedHectares", self.statistics.plowedHectares.total)
    xmlFile:setFloat(key .. ".statistics.harvestedGrapes", self.statistics.harvestedGrapes.total)
    xmlFile:setFloat(key .. ".statistics.harvestedOlives", self.statistics.harvestedOlives.total)
    xmlFile:setFloat(key .. ".statistics.workedTime", self.statistics.workedTime.total)
    xmlFile:setFloat(key .. ".statistics.cultivatedTime", self.statistics.cultivatedTime.total)
    xmlFile:setFloat(key .. ".statistics.sownTime", self.statistics.sownTime.total)
    xmlFile:setFloat(key .. ".statistics.sprayedTime", self.statistics.sprayedTime.total)
    xmlFile:setFloat(key .. ".statistics.threshedTime", self.statistics.threshedTime.total)
    xmlFile:setFloat(key .. ".statistics.plowedTime", self.statistics.plowedTime.total)
    xmlFile:setInt(key .. ".statistics.baleCount", self.statistics.baleCount.total)
    xmlFile:setInt(key .. ".statistics.breedCowsCount", self.statistics.breedCowsCount.total)
    xmlFile:setInt(key .. ".statistics.breedSheepCount", self.statistics.breedSheepCount.total)
    xmlFile:setInt(key .. ".statistics.breedPigsCount", self.statistics.breedPigsCount.total)
    xmlFile:setInt(key .. ".statistics.breedChickenCount", self.statistics.breedChickenCount.total)
    xmlFile:setInt(key .. ".statistics.breedHorsesCount", self.statistics.breedHorsesCount.total)
    xmlFile:setInt(key .. ".statistics.breedGoatsCount", self.statistics.breedGoatsCount.total)
    xmlFile:setInt(key .. ".statistics.breedWaterBuffaloCount", self.statistics.breedWaterBuffaloCount.total)
    xmlFile:setInt(key .. ".statistics.missionCount", self.statistics.missionCount.total)
    xmlFile:setFloat(key .. ".statistics.revenue", self.statistics.revenue.total)
    xmlFile:setFloat(key .. ".statistics.expenses", self.statistics.expenses.total)
    xmlFile:setFloat(key .. ".statistics.playTime", self.statistics.playTime.total)
    xmlFile:setInt(key .. ".statistics.plantedTreeCount", self.statistics.plantedTreeCount.total)
    xmlFile:setInt(key .. ".statistics.cutTreeCount", self.statistics.cutTreeCount.total)
    xmlFile:setFloat(key .. ".statistics.woodTonsSold", self.statistics.woodTonsSold.total)
    xmlFile:setString(key .. ".statistics.treeTypesCut", self.statistics.treeTypesCut)
    xmlFile:setInt(key .. ".statistics.petDogCount", self.statistics.petDogCount.total)
    xmlFile:setInt(key .. ".statistics.repairVehicleCount", self.statistics.repairVehicleCount.total)
    xmlFile:setInt(key .. ".statistics.repaintVehicleCount", self.statistics.repaintVehicleCount.total)
    xmlFile:setInt(key .. ".statistics.horseJumpCount", self.statistics.horseJumpCount.total)
    xmlFile:setInt(key .. ".statistics.soldCottonBales", self.statistics.soldCottonBales.total)
    xmlFile:setInt(key .. ".statistics.wrappedBales", self.statistics.wrappedBales.total)
    xmlFile:setFloat(key .. ".statistics.tractorDistance", self.statistics.tractorDistance.total)
    xmlFile:setFloat(key .. ".statistics.carDistance", self.statistics.carDistance.total)
    xmlFile:setFloat(key .. ".statistics.truckDistance", self.statistics.truckDistance.total)
    xmlFile:setFloat(key .. ".statistics.horseDistance", self.statistics.horseDistance.total)
    local toSave = { self.finances }
    local numHistoricItems = #self.financesHistory
    if numHistoricItems > 3 then
        table.insert(toSave, self.financesHistory[numHistoricItems - 3])
    end
    if numHistoricItems > 2 then
        table.insert(toSave, self.financesHistory[numHistoricItems - 2])
    end
    if numHistoricItems > 1 then
        table.insert(toSave, self.financesHistory[numHistoricItems - 1])
    end
    if numHistoricItems > 0 then
        table.insert(toSave, self.financesHistory[numHistoricItems - 0])
    end
    xmlFile:setSortedTable(key .. ".finances.stats", toSave, function(statsKey, finances, day)
        -- upvalues: (copy) xmlFile
        xmlFile:setInt(statsKey .. "#day", day - 1)
        finances:saveToXMLFile(xmlFile, statsKey)
    end)
end
function FarmStats:loadFromXMLFile(xmlFile, rootKey)
    local key = rootKey .. ".statistics"
    self.statistics.traveledDistance.total = xmlFile:getFloat(key .. ".traveledDistance", 0)
    self.statistics.fuelUsage.total = xmlFile:getFloat(key .. ".fuelUsage", 0)
    self.statistics.seedUsage.total = xmlFile:getFloat(key .. ".seedUsage", 0)
    self.statistics.sprayUsage.total = xmlFile:getFloat(key .. ".sprayUsage", 0)
    self.statistics.workedHectares.total = xmlFile:getFloat(key .. ".workedHectares", 0)
    self.statistics.cultivatedHectares.total = xmlFile:getFloat(key .. ".cultivatedHectares", 0)
    self.statistics.sownHectares.total = xmlFile:getFloat(key .. ".sownHectares", 0)
    self.statistics.sprayedHectares.total = xmlFile:getFloat(key .. ".sprayedHectares", 0)
    self.statistics.threshedHectares.total = xmlFile:getFloat(key .. ".threshedHectares", 0)
    self.statistics.weededHectares.total = xmlFile:getFloat(key .. ".weededHectares", 0)
    self.statistics.plowedHectares.total = xmlFile:getFloat(key .. ".plowedHectares", 0)
    self.statistics.harvestedGrapes.total = xmlFile:getFloat(key .. ".harvestedGrapes", 0)
    self.statistics.harvestedOlives.total = xmlFile:getFloat(key .. ".harvestedOlives", 0)
    self.statistics.workedTime.total = xmlFile:getFloat(key .. ".workedTime", 0)
    self.statistics.cultivatedTime.total = xmlFile:getFloat(key .. ".cultivatedTime", 0)
    self.statistics.sownTime.total = xmlFile:getFloat(key .. ".sownTime", 0)
    self.statistics.sprayedTime.total = xmlFile:getFloat(key .. ".sprayedTime", 0)
    self.statistics.threshedTime.total = xmlFile:getFloat(key .. ".threshedTime", 0)
    self.statistics.weededTime.total = xmlFile:getFloat(key .. ".weededTime", 0)
    self.statistics.plowedTime.total = xmlFile:getFloat(key .. ".plowedTime", 0)
    self.statistics.baleCount.total = xmlFile:getInt(key .. ".baleCount", 0)
    self.statistics.breedCowsCount.total = xmlFile:getInt(key .. ".breedCowsCount", 0)
    self.statistics.breedSheepCount.total = xmlFile:getInt(key .. ".breedSheepCount", 0)
    self.statistics.breedPigsCount.total = xmlFile:getInt(key .. ".breedPigsCount", 0)
    self.statistics.breedChickenCount.total = xmlFile:getInt(key .. ".breedChickenCount", 0)
    self.statistics.breedHorsesCount.total = xmlFile:getInt(key .. ".breedHorsesCount", 0)
    self.statistics.breedGoatsCount.total = xmlFile:getInt(key .. ".breedGoatsCount", 0)
    self.statistics.breedWaterBuffaloCount.total = xmlFile:getInt(key .. ".breedWaterBuffaloCount", 0)
    self.statistics.missionCount.total = xmlFile:getInt(key .. ".missionCount", 0)
    self.statistics.plantedTreeCount.total = xmlFile:getInt(key .. ".plantedTreeCount", 0)
    self.statistics.cutTreeCount.total = xmlFile:getInt(key .. ".cutTreeCount", 0)
    self.statistics.woodTonsSold.total = xmlFile:getFloat(key .. ".woodTonsSold", 0)
    self.statistics.treeTypesCut = xmlFile:getString(key .. ".treeTypesCut", "000000")
    self.statistics.revenue.total = xmlFile:getFloat(key .. ".revenue", 0)
    self.statistics.expenses.total = xmlFile:getFloat(key .. ".expenses", 0)
    self.statistics.playTime.total = xmlFile:getFloat(key .. ".playTime", 0)
    self.statistics.petDogCount.total = xmlFile:getInt(key .. ".petDogCount", 0)
    self.statistics.repaintVehicleCount.total = xmlFile:getInt(key .. ".repaintVehicleCount", 0)
    self.statistics.repairVehicleCount.total = xmlFile:getInt(key .. ".repairVehicleCount", 0)
    self.statistics.tractorDistance.total = xmlFile:getFloat(key .. ".tractorDistance", 0)
    self.statistics.carDistance.total = xmlFile:getFloat(key .. ".carDistance", 0)
    self.statistics.truckDistance.total = xmlFile:getFloat(key .. ".truckDistance", 0)
    self.statistics.horseDistance.total = xmlFile:getFloat(key .. ".horseDistance", 0)
    self.statistics.horseJumpCount.total = xmlFile:getInt(key .. ".horseJumpCount", 0)
    self.statistics.soldCottonBales.total = xmlFile:getInt(key .. ".soldCottonBales", 0)
    self.statistics.wrappedBales.total = xmlFile:getInt(key .. ".wrappedBales", 0)
    xmlFile:iterate(rootKey .. ".finances.stats", function(day, financeKey)
        -- upvalues: (copy) xmlFile, (copy) self
        local finances = FinanceStats.new()
        finances:loadFromXMLFile(xmlFile, financeKey)
        if day == 1 then
            self.finances = finances
        else
            table.insert(self.financesHistory, finances)
        end
    end)
end
function FarmStats:update(dt)
    if GS_PLATFORM_XBOX then
        if not self.heroStatsLoaded and areStatsAvailable() then
            self.heroStatsLoaded = true
            for heroStatName, heroStat in pairs(self.heroStats) do
                heroStat.id = statsGetIndex(heroStatName)
                heroStat.value = statsGet(heroStat.id)
                if heroStat.accumValue ~= 0 then
                    heroStat.value = heroStat.value + heroStat.accumValue
                    statsSet(heroStat.id, heroStat.value)
                    heroStat.accumValue = 0
                end
            end
        end
        if g_time >= self.nextHeroAccumUpdate and self.moneyEarnedHeroAccum > 0 then
            self:addValueToHeroStat("moneyEarned", self.moneyEarnedHeroAccum)
            self.moneyEarnedHeroAccum = 0
            self.nextHeroAccumUpdate = g_time + 10000
        end
    end
    self:updateStats("playTime", dt / 60000, self.updatePlayTime)
end
function FarmStats:addValueToHeroStat(name, value)
    if self.heroStatsLoaded then
        self.heroStats[name].value = self.heroStats[name].value + value
        statsSet(heroStat.id, heroStat.value)
    else
        heroStat.accumValue = heroStat.accumValue + value
    end
end
function FarmStats:changeFinanceStats(amount, statType)
    if statType ~= nil and self.finances[statType] ~= nil then
        self.finances[statType] = self.finances[statType] + amount
        if g_currentMission:getIsServer() then
            self.financesVersionCounter = self.financesVersionCounter + 1
            if self.financesVersionCounter > 999999 then
                self.financesVersionCounter = 0
            end
        end
    end
end
function FarmStats:archiveFinances()
    if g_currentMission:getIsServer() then
        table.insert(self.financesHistory, self.finances)
        self.finances = FinanceStats.new()
        self.financesVersionCounter = self.financesVersionCounter + 1
        if self.financesVersionCounter > 999999 then
            self.financesVersionCounter = 0
        end
        self.financesHistoryVersionCounter = self.financesHistoryVersionCounter + 1
        if self.financesHistoryVersionCounter > 127 then
            self.financesHistoryVersionCounter = 0
        end
    end
end
function FarmStats:getCompletedMissions()
    return self:getTotalValue("missionCount")
end
function FarmStats:getCompletedMissionsSession()
    return self:getSessionValue("missionCount")
end
function FarmStats:updateStats(statName, delta, ignoreHeroStats)
    local total = nil
    local session = nil
    if delta == nil then
        printCallstack()
    end
    if self.statistics[statName] == nil then
        printError("Error: Invalid statistic \'" .. statName .. "\'")
    else
        self.statistics[statName].session = self.statistics[statName].session + delta
        session = self.statistics[statName].session
        if self.statistics[statName].total ~= nil then
            self.statistics[statName].total = self.statistics[statName].total + delta
            total = self.statistics[statName].total
        end
    end
    if ignoreHeroStats == nil or not ignoreHeroStats then
        self:addHeroStat(statName, delta)
    end
    return total, session
end
function FarmStats:addHeroStat(statName, delta)
    if self.heroStats[statName] == nil then
        if statName == "missionCount" then
            self:addValueToHeroStat("completedMissions", delta)
        end
        return
    elseif statName == "moneyEarned" then
        self.moneyEarnedHeroAccum = self.moneyEarnedHeroAccum + delta
    else
        self:addValueToHeroStat(statName, delta)
    end
end
function FarmStats:getTotalValue(statName)
    if self.statistics[statName] == nil then
        return nil
    else
        return self.statistics[statName].total
    end
end
function FarmStats:getSessionValue(statName)
    if self.statistics[statName] == nil then
        return nil
    else
        return self.statistics[statName].session
    end
end
function FarmStats:updateTreeTypesCut(splitTypeName)
    for i, treeName in ipairs({
        "oak",
        "birch",
        "maple",
        { "spruce", "pine" },
        "poplar",
        "ash"
    }) do
        local treeMatch = false
        if type(treeName) == "table" then
            for _, subTreeName in pairs(treeName) do
                if splitTypeName == subTreeName then
                    treeMatch = true
                end
            end
        elseif splitTypeName == treeName then
            treeMatch = true
        end
        if treeMatch then
            local stats = self.statistics
            stats.treeTypesCut = string.sub(stats.treeTypesCut, 1, i - 1) .. "1" .. string.sub(stats.treeTypesCut, i + 1, (string.len(stats.treeTypesCut)))
        end
    end
end
function FarmStats:updateMissionDone()
    self:updateStats("missionCount", 1)
    self:updateJobAchievements()
end
function FarmStats:updateJobAchievements()
    local missionCount = self:getTotalValue("missionCount")
    g_achievementManager:tryUnlock("MissionFirst", missionCount)
    g_achievementManager:tryUnlock("Mission", missionCount)
end
function FarmStats:getStatisticData()
    if not (g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission.missionDynamicInfo.isClient) then
        self:addStatistic("workedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("workedHectares")), g_i18n:getArea(self:getTotalValue("workedHectares")), "%.2f")
        self:addStatistic("cultivatedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("cultivatedHectares")), g_i18n:getArea(self:getTotalValue("cultivatedHectares")), "%.2f")
        self:addStatistic("plowedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("plowedHectares")), g_i18n:getArea(self:getTotalValue("plowedHectares")), "%.2f")
        self:addStatistic("sownHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("sownHectares")), g_i18n:getArea(self:getTotalValue("sownHectares")), "%.2f")
        self:addStatistic("sprayedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("sprayedHectares")), g_i18n:getArea(self:getTotalValue("sprayedHectares")), "%.2f")
        self:addStatistic("threshedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("threshedHectares")), g_i18n:getArea(self:getTotalValue("threshedHectares")), "%.2f")
        self:addStatistic("harvestedOlives", "m", g_i18n:getArea(self:getSessionValue("harvestedOlives")), g_i18n:getArea(self:getTotalValue("harvestedOlives")), "%.1f")
        self:addStatistic("harvestedGrapes", "m", g_i18n:getArea(self:getSessionValue("harvestedGrapes")), g_i18n:getArea(self:getTotalValue("harvestedGrapes")), "%.1f")
        if not GS_IS_MOBILE_VERSION then
            self:addStatistic("workedTime", nil, Utils.formatTime(self:getSessionValue("workedTime")), Utils.formatTime(self:getTotalValue("workedTime")), "%s")
            self:addStatistic("cultivatedTime", nil, Utils.formatTime(self:getSessionValue("cultivatedTime")), Utils.formatTime(self:getTotalValue("cultivatedTime")), "%s")
            self:addStatistic("plowedTime", nil, Utils.formatTime(self:getSessionValue("plowedTime")), Utils.formatTime(self:getTotalValue("plowedTime")), "%s")
            self:addStatistic("sownTime", nil, Utils.formatTime(self:getSessionValue("sownTime")), Utils.formatTime(self:getTotalValue("sownTime")), "%s")
            self:addStatistic("sprayedTime", nil, Utils.formatTime(self:getSessionValue("sprayedTime")), Utils.formatTime(self:getTotalValue("sprayedTime")), "%s")
            self:addStatistic("threshedTime", nil, Utils.formatTime(self:getSessionValue("threshedTime")), Utils.formatTime(self:getTotalValue("threshedTime")), "%s")
        end
        self:addStatistic("traveledDistance", g_i18n:getMeasuringUnit(), g_i18n:getDistance(self:getSessionValue("traveledDistance")), g_i18n:getDistance(self:getTotalValue("traveledDistance")), "%.2f")
        self:addStatistic("fuelUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("fuelUsage")), g_i18n:getFluid(self:getTotalValue("fuelUsage")), "%.2f")
        self:addStatistic("seedUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("seedUsage")), g_i18n:getFluid(self:getTotalValue("seedUsage")), "%.2f")
        self:addStatistic("sprayUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("sprayUsage")), g_i18n:getFluid(self:getTotalValue("sprayUsage")), "%.2f")
        self:addStatistic("baleCount", nil, self:getSessionValue("baleCount"), self:getTotalValue("baleCount"), "%d")
        self:addStatistic("plantedTreeCount", nil, self:getSessionValue("plantedTreeCount"), self:getTotalValue("plantedTreeCount"), "%d")
        self:addStatistic("cutTreeCount", nil, self:getSessionValue("cutTreeCount"), self:getTotalValue("cutTreeCount"), "%d")
        if not GS_IS_MOBILE_VERSION then
            self:addStatistic("missionCount", nil, self:getSessionValue("missionCount"), self:getTotalValue("missionCount"), "%d")
        end
        self:addStatistic("playTime", nil, Utils.formatTime(self:getSessionValue("playTime")), Utils.formatTime(self:getTotalValue("playTime")), "%s")
        local year = g_currentMission.environment.currentYear
        if g_currentMission.environment.currentPeriod >= SeasonPeriod.MID_WINTER then
        end
        self:addStatistic("yearsPlayed", nil, nil, year, "%s")
        self:addStatistic("workersHired", nil, self:getSessionValue("workersHired"), nil, "%s")
        self:addStatistic("storedBales", nil, self:getSessionValue("storedBales"), nil, "%s")
        self:addStatistic("storedPallets", nil, self:getSessionValue("storedPallets"), nil, "%s")
        if g_currentMission.collectiblesSystem:getIsActive() then
            self:addStatistic("collectibles", nil, nil, g_currentMission.collectiblesSystem:getTotalCollected() .. " / " .. g_currentMission.collectiblesSystem:getTotalCollectable(), "%s")
        end
    end
    return Utils.getNoNil(self.statisticData, {})
end
function FarmStats:addStatistic(name, unit, valueSession, valueTotal, stringFormat, customEnv)
    if self.statisticData == nil then
        self.statisticData = {}
        self.statisticDataRev = {}
    end
    local formattedName = g_i18n:getText("statistic_" .. name, customEnv or g_currentMission.missionInfo.customEnvironment)
    if unit ~= nil then
    end
    local newDataSet = self.statisticDataRev[name]
    if newDataSet == nil then
        newDataSet = {}
        self.statisticDataRev[name] = newDataSet
        table.insert(self.statisticData, newDataSet)
    end
    newDataSet.name = formattedName
    newDataSet.valueSession = string.format(stringFormat, Utils.getNoNil(valueSession, ""))
    newDataSet.valueTotal = string.format(stringFormat, Utils.getNoNil(valueTotal, ""))
end
function FarmStats:merge(other)
    for _, statName in ipairs(FarmStats.STAT_NAMES) do
        if statName == "treeTypesCut" then
            local cut = self.statistics.treeTypesCut
            local i = 1
            for i = i, string.len(cut) do
                if string.sub(other.statistics.treeTypesCut, i, i) == "1" then
                    cut = string.sub(cut, 1, i - 1) .. "1" .. string.sub(cut, i + 1, (string.len(cut)))
                end
            end
            self.statistics.treeTypesCut = cut
        else
            self.statistics[statName].total = self.statistics[statName].total + other.statistics[statName].total
        end
    end
    self.finances:merge(other.finances)
    return self
end