FarmlandStatistics = {}
source(g_currentModDirectory .. "scripts/gui/FarmlandStatsDialog.lua")
FarmlandStatistics.MOD_NAME = g_currentModName
local FarmlandStatistics_mt = Class(FarmlandStatistics)
function FarmlandStatistics.new(pfModule, customMt)
    -- upvalues: (copy) FarmlandStatistics_mt
    local self = setmetatable({}, customMt or FarmlandStatistics_mt)
    self.statistics = {}
    self.statisticsByFarmland = {}
    self.mapFrame = nil
    self.pfModule = pfModule
    return self
end
function FarmlandStatistics:loadFromXML(_, _, _, _, _)
    g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
    return true
end
function FarmlandStatistics:loadFromItemsXML(xmlFile, key)
    key = key .. ".farmlandStatistics"
    local i = 1
    for i = i, #self.statistics do
        local statKey = string.format("%s.farmlandStatistic(%d)", key, i - 1)
        if not xmlFile:hasProperty(statKey) then
            break
        end
        self.statistics[i]:loadFromItemsXML(xmlFile, statKey)
    end
end
function FarmlandStatistics:saveToXMLFile(xmlFile, key, usedModNames)
    key = key .. ".farmlandStatistics"
    local i = 1
    for i = i, #self.statistics do
        self.statistics[i]:saveToXMLFile(xmlFile, string.format("%s.farmlandStatistic(%d)", key, i - 1), usedModNames)
    end
end
function FarmlandStatistics:delete()
    g_messageCenter:unsubscribeAll(self)
    self.statistics = {}
    self.statisticsByFarmland = {}
end
function FarmlandStatistics:readStatisticFromStream(farmlandId, streamId, connection)
    if streamReadBool(streamId) then
        local totalFieldArea = streamReadFloat32(streamId)
        local farmland = g_farmlandManager.farmlands[farmlandId]
        if farmland ~= nil then
            farmland.totalFieldArea = totalFieldArea
        end
    end
    local totalFieldArea = self.statisticsByFarmland[farmlandId]
    if totalFieldArea ~= nil then
        totalFieldArea:onReadStream(streamId, connection)
    end
    self.selectedFarmlandId = farmlandId
    self:openStatistics(farmlandId, true)
end
function FarmlandStatistics:writeStatisticToStream(farmlandId, streamId, connection)
    local farmland = g_farmlandManager.farmlands[farmlandId]
    local statistic = streamWriteBool
    if statistic(streamId, farmland ~= nil) then
        streamWriteFloat32(streamId, farmland.totalFieldArea or 0)
    end
    local statistic = self.statisticsByFarmland[farmlandId]
    if statistic ~= nil then
        statistic:onWriteStream(streamId, connection)
    end
end
function FarmlandStatistics:setMapFrame(mapFrame)
    self.mapFrame = mapFrame
end
function FarmlandStatistics:collectFarmlandHotspotActions(actions)
    table.insert(actions, {
        ["title"] = g_i18n:getText("ui_economicAnalysis"),
        ["callback"] = self.openStatistics,
        ["callbackTarget"] = self
    })
end
function FarmlandStatistics:openStatistics(farmlandId, noEventSend)
    self.mapFrame:setMapSelectionItem(nil)
    local statistic = self.statisticsByFarmland[farmlandId]
    if statistic ~= nil then
        local fieldNumber, fieldArea = self:getFarmlandFieldInfo(farmlandId)
        if fieldArea >= 0.01 then
            FarmlandStatsDialog.show(farmlandId, fieldNumber, fieldArea, statistic)
        end
    end
    if not noEventSend and (g_server == nil and g_client ~= nil) then
        g_client:getServerConnection():sendEvent(RequestFarmlandStatisticsEvent.new(farmlandId))
    end
end
function FarmlandStatistics:getFarmlandFieldInfo(farmlandId)
    return self.pfModule:getFarmlandFieldInfo(farmlandId)
end
function FarmlandStatistics:updateStatistic(farmlandId, name, value)
    local statistic = self.statisticsByFarmland[farmlandId]
    if statistic ~= nil then
        statistic:updateStatistic(name, value)
    end
end
function FarmlandStatistics:resetStatistic(farmlandId, clearTotal)
    local statistic = self.statisticsByFarmland[farmlandId]
    if statistic ~= nil then
        statistic:reset(clearTotal)
    end
end
function FarmlandStatistics.getFillLevelWeight(_, fillLevel, fillTypeIndex)
    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
    if fillType == nil then
        return fillLevel
    else
        return fillLevel * (fillType.massPerLiter / FillTypeManager.MASS_SCALE)
    end
end
function FarmlandStatistics:getFillLevelPrice(fillLevel, fillTypeIndex)
    if fillTypeIndex == "soilSamples" then
        return fillLevel * (self.pfModule.soilMap.pricePerSample[g_currentMission.missionInfo.economicDifficulty] or 0)
    else
        local price = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        if price == nil then
            return fillLevel
        else
            return fillLevel * price.pricePerLiter
        end
    end
end
function FarmlandStatistics:onFarmlandStateChanged(farmlandId, _, loadFromSavegame)
    if not loadFromSavegame then
        self:resetStatistic(farmlandId, true)
    end
end
function FarmlandStatistics:overwriteGameFunctions(pfModule)
    FarmlandStatsDialog.register()
    pfModule:overwriteGameFunction(FarmlandManager, "loadFarmlandData", function(superFunc, farmlandManager, xmlFile)
        -- upvalues: (copy) self
        if not superFunc(farmlandManager, xmlFile) then
            return false
        end
        local farmlands = g_farmlandManager:getFarmlands()
        if farmlands ~= nil then
            for id, farmland in pairs(farmlands) do
                local statistic = FarmlandStatistic.new(id)
                self.statisticsByFarmland[id] = statistic
                table.insert(self.statistics, statistic)
            end
        end
        return true
    end)
end