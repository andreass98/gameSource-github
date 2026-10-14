Subsidies = {}
Subsidies.MOD_NAME = g_currentModName
local Subsidies_mt = Class(Subsidies)
function Subsidies.new(_, customMt)
    -- upvalues: (copy) Subsidies_mt
    local self = setmetatable({}, customMt or Subsidies_mt)
    self.moneyChangeTypeCoverCrop = MoneyType.register("other", "info_subsidiesCoverCrop", Subsidies.MOD_NAME)
    return self
end
function Subsidies:loadFromXML(xmlFile, key, _, _, _)
    local missionInfo = XMLFile.wrap(xmlFile)
    if g_server ~= nil then
        g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
    end
    self.coverCropBonusFruitTypes = {}
    self.infoTaskResults = {}
    self.pendingInfoTasks = {}
    self.lastBonusByFarm = {}
    self.coverCropBonusByName = {}
    self:loadCoverCropBonusFromXML(missionInfo, key .. ".coverCropBonus")
    local mapXMLFilename = Utils.getFilename(g_currentMission.missionInfo.mapXMLFilename, g_currentMission.baseDirectory)
    local mapXMLFile = XMLFile.load("MapXML", mapXMLFilename)
    if mapXMLFile ~= nil then
        self:loadCoverCropBonusFromXML(mapXMLFile, "map.precisionFarming.subsidies.coverCropBonus")
        mapXMLFile:delete()
    end
    return true
end
function Subsidies:loadCoverCropBonusFromXML(xmlFile, key)
    for _, fruitTypeKey in xmlFile:iterator(key .. ".fruitType") do
        local fruitTypeName = xmlFile:getString(fruitTypeKey .. "#name")
        if fruitTypeName == nil then
            Logging.xmlWarning(xmlFile, "Missing fruit type for cover crop bonus \'%s\'", fruitTypeKey)
        else
            local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
            if fruitType ~= nil then
                local bonusPerHa = xmlFile:getVector(fruitTypeKey .. "#bonusPerHa", nil, 3)
                if bonusPerHa == nil then
                    Logging.xmlWarning(xmlFile, "Missing/Invalid bonusPerHa for cover crop bonus \'%s\'", fruitTypeKey)
                else
                    table.insert(self.coverCropBonusFruitTypes, fruitType)
                    self.coverCropBonusByName[fruitType.name] = {
                        ["fruitType"] = fruitType.index,
                        ["bonusPerHa"] = bonusPerHa
                    }
                end
            end
        end
    end
end
function Subsidies:delete()
    g_messageCenter:unsubscribeAll(self)
end
function Subsidies:overwriteGameFunctions(pfModule) end
function Subsidies:getBonusByLabelAndArea(label, pixels)
    local parts = string.split(label, "|")
    local fruitTypeName = parts[1]
    local data = parts[2]
    local foliageState = tonumber(data)
    local data = self.coverCropBonusByName[fruitTypeName]
    if data ~= nil then
        local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
        if foliageState > 1 and (fruitType.cutState == 0 or foliageState < fruitType.cutState) then
            local ha = MathUtil.areaToHa(pixels, g_currentMission:getFruitPixelsToSqm())
            return data.bonusPerHa[g_currentMission.missionInfo.economicDifficulty] * ha
        end
    end
    return 0
end
function Subsidies:onFieldInfoTaskFinished(ftGrowthStatePixels, _, callbackArgs)
    local farmId = callbackArgs.farmId
    local farmlandId = callbackArgs.farmlandId
    if self.infoTaskResults[farmId] == nil then
        self.infoTaskResults[farmId] = {}
    end
    g_precisionFarming.farmlandStatistics:resetStatistic(farmlandId, false)
    for label, numPixels in pairs(ftGrowthStatePixels) do
        local bonus = self:getBonusByLabelAndArea(label, numPixels)
        if bonus > 0 then
            g_precisionFarming.farmlandStatistics:updateStatistic(farmlandId, "subsidies", bonus)
        end
        if self.infoTaskResults[farmId][label] == nil then
            self.infoTaskResults[farmId][label] = 0
        end
        self.infoTaskResults[farmId][label] = self.infoTaskResults[farmId][label] + numPixels
    end
    table.removeElement(self.pendingInfoTasks, callbackArgs.infoTask)
    if #self.pendingInfoTasks == 0 then
        for label, numPixels in pairs(self.infoTaskResults) do
            for label, pixels in pairs(numPixels) do
                local bonus = self:getBonusByLabelAndArea(label, pixels)
                if self.lastBonusByFarm[label] == nil then
                    self.lastBonusByFarm[label] = 0
                end
                self.lastBonusByFarm[label] = self.lastBonusByFarm[label] + bonus
            end
        end
    end
    for label, numPixels in pairs(self.lastBonusByFarm) do
        if numPixels ~= 0 then
            g_currentMission:addMoney(numPixels, label, self.moneyChangeTypeCoverCrop, true)
            g_currentMission:showMoneyChange(self.moneyChangeTypeCoverCrop, nil, nil, farmId)
        end
    end
end
function Subsidies:onPeriodChanged(currentPeriod)
    if currentPeriod == SeasonPeriod.LATE_WINTER then
        self.lastBonusByFarm = {}
        self.infoTaskResults = {}
        for _, farmland in ipairs(g_farmlandManager.sortedFarmlands) do
            local farmlandId = farmland:getId()
            if farmland.isOwned then
                local field = g_fieldManager:getFieldById(farmlandId)
                if field ~= nil then
                    local area = field:getDensityMapPolygon()
                    local infoTask = FieldGetInfoTask.new()
                    infoTask:setArea(area)
                    infoTask:setFruitTypes(self.coverCropBonusFruitTypes)
                    infoTask:setCallback(self.onFieldInfoTaskFinished, self, {
                        ["infoTask"] = infoTask,
                        ["farmId"] = farmland.farmId,
                        ["farmlandId"] = farmlandId
                    })
                    table.insert(self.pendingInfoTasks, infoTask)
                    infoTask:enqueue()
                end
            end
        end
    end
end