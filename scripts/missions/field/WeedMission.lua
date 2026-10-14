WeedMission = {}
WeedMission.NAME = "weedMission"
local WeedMission_mt = Class(WeedMission, AbstractFieldMission)
InitStaticObjectClass(WeedMission, "WeedMission")
function WeedMission.registerXMLPaths(schema, key)
    WeedMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function WeedMission.registerSavegameXMLPaths(schema, key)
    WeedMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#totalWeedArea", "Total weed area on start")
end
function WeedMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) WeedMission_mt
    local title = g_i18n:getText("contract_field_weed_title")
    local description = g_i18n:getText("contract_field_weed_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or WeedMission_mt)
    self.workAreaTypes = {
        [WorkAreaType.WEEDER] = true
    }
    self.totalWeedArea = nil
    return self
end
function WeedMission:saveToXMLFile(xmlFile, key)
    WeedMission:superClass().saveToXMLFile(self, xmlFile, key)
    if self.totalWeedArea ~= nil then
        xmlFile:setInt(key .. "#totalWeedArea", self.totalWeedArea)
    end
end
function WeedMission:loadFromXMLFile(xmlFile, key)
    if xmlFile:getInt(key .. "#targetWeedState") == nil then
        self.totalWeedArea = xmlFile:getInt(key .. "#totalWeedArea", self.totalWeedArea)
        if self.totalWeedArea == nil or self.totalWeedArea == 0 then
            return false
        else
            return WeedMission:superClass().loadFromXMLFile(self, xmlFile, key)
        end
    else
        return false
    end
end
function WeedMission:createModifier()
    local weedMapId, weedFirstChannel, weedNumChannels = g_currentMission.weedSystem:getDensityMapData()
    self.completionModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode)
    self.completionFilter = DensityMapFilter.new(self.completionModifier)
    self.completionFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
end
function WeedMission:finishedPreparing()
    WeedMission:superClass().finishedPreparing(self)
    self.field:getDensityMapPolygon():applyToModifier(self.completionModifier)
    local _, area, _ = self.completionModifier:executeGet(self.completionFilter)
    self.totalWeedArea = area
    if self.totalWeedArea == 0 then
        self:finish(MissionFinishState.FAILED)
    end
end
function WeedMission:updateFieldPercentageDone(totalArea)
    local areaDone = 0
    local allCalculated = true
    for _, partition in ipairs(self.completionPartitions) do
        if not partition.wasCalculated then
            allCalculated = false
        end
        if totalArea > 0 then
        end
    end
    if allCalculated then
        self.fieldPercentageDone = 1 - areaDone / self.totalWeedArea
    end
end
function WeedMission:getFieldFinishTask()
    self.field:getFieldState().weedState = 0
    return WeedMission:superClass().getFieldFinishTask(self)
end
function WeedMission:getRewardPerHa()
    return g_missionManager:getMissionTypeDataByName(WeedMission.NAME).rewardPerHa
end
function WeedMission:getMissionTypeName()
    return WeedMission.NAME
end
function WeedMission:validate(event)
    if WeedMission:superClass().validate(self, event) then
        return (self:getIsFinished() or WeedMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function WeedMission.loadMapData(xmlFile, key, _)
    g_missionManager:getMissionTypeDataByName(WeedMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2000)
    return true
end
function WeedMission.tryGenerateMission()
    if WeedMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not WeedMission.isAvailableForField(field, nil) then
            return
        end
        local mission = WeedMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function WeedMission.isAvailableForField(field, mission)
    if mission == nil then
        local fieldState = field:getFieldState()
        if not fieldState.isValid then
            return false
        end
        local fruitTypeIndex = fieldState.fruitTypeIndex
        if fruitTypeIndex == FruitType.UNKNOWN then
            return false
        end
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
        if fruitTypeDesc:getIsCatchCrop() then
            return false
        end
        if fieldState.weedState == 0 then
            return false
        end
        if not fruitTypeDesc:getIsWeedable(fieldState.growthState) then
            return false
        end
        if g_currentMission.weedSystem:getWeededState(fieldState.weedState) ~= 0 then
            return false
        end
    end
    local fieldState = g_currentMission.environment
    return fieldState == nil or fieldState.currentSeason ~= Season.WINTER
end
function WeedMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(WeedMission.NAME)
    if data.numInstances >= data.maxNumInstances then
        return false
    elseif g_currentMission.growthSystem:getIsGrowingInProgress() then
        return false
    elseif g_currentMission.weedSystem:getMapHasWeed() then
        return g_currentMission.missionInfo.weedsEnabled and true or false
    else
        return false
    end
end
g_missionManager:registerMissionType(WeedMission, WeedMission.NAME, 2)