HoeMission = {}
HoeMission.NAME = "hoeMission"
local HoeMission_mt = Class(HoeMission, AbstractFieldMission)
InitStaticObjectClass(HoeMission, "HoeMission")
function HoeMission.registerXMLPaths(schema, key)
    HoeMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function HoeMission.registerSavegameXMLPaths(schema, key)
    HoeMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#totalWeedArea", "Total weed area on start")
end
function HoeMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) HoeMission_mt
    local title = g_i18n:getText("contract_field_hoe_title")
    local description = g_i18n:getText("contract_field_hoe_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or HoeMission_mt)
    self.workAreaTypes = {
        [WorkAreaType.WEEDER] = true
    }
    self.totalWeedArea = nil
    return self
end
function HoeMission:saveToXMLFile(xmlFile, key)
    HoeMission:superClass().saveToXMLFile(self, xmlFile, key)
    if self.totalWeedArea ~= nil then
        xmlFile:setInt(key .. "#totalWeedArea", self.totalWeedArea)
    end
end
function HoeMission:loadFromXMLFile(xmlFile, key)
    if xmlFile:getInt(key .. "#targetWeedState") == nil then
        self.totalWeedArea = xmlFile:getInt(key .. "#totalWeedArea", self.totalWeedArea)
        if self.totalWeedArea == nil or self.totalWeedArea == 0 then
            return false
        else
            return HoeMission:superClass().loadFromXMLFile(self, xmlFile, key)
        end
    else
        return false
    end
end
function HoeMission:createModifier()
    local weedMapId, weedFirstChannel, weedNumChannels = g_currentMission.weedSystem:getDensityMapData()
    self.completionModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode)
    self.completionFilter = DensityMapFilter.new(self.completionModifier)
    self.completionFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
end
function HoeMission:finishedPreparing()
    HoeMission:superClass().finishedPreparing(self)
    self.field:getDensityMapPolygon():applyToModifier(self.completionModifier)
    local _, area, _ = self.completionModifier:executeGet(self.completionFilter)
    self.totalWeedArea = area
    if self.totalWeedArea == 0 then
        self:finish(MissionFinishState.FAILED)
    end
end
function HoeMission:updateFieldPercentageDone(totalArea)
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
function HoeMission:getFieldFinishTask()
    self.field:getFieldState().weedState = 0
    return HoeMission:superClass().getFieldFinishTask(self)
end
function HoeMission:getRewardPerHa()
    return g_missionManager:getMissionTypeDataByName(HoeMission.NAME).rewardPerHa
end
function HoeMission:getMissionTypeName()
    return HoeMission.NAME
end
function HoeMission:validate(event)
    if HoeMission:superClass().validate(self, event) then
        return (self:getIsFinished() or HoeMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function HoeMission.loadMapData(xmlFile, key, _)
    g_missionManager:getMissionTypeDataByName(HoeMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 1500)
    return true
end
function HoeMission.tryGenerateMission()
    if HoeMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not HoeMission.isAvailableForField(field, nil) then
            return
        end
        local mission = HoeMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function HoeMission.isAvailableForField(field, mission)
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
        if not fruitTypeDesc:getIsHoeable(fieldState.growthState) then
            return false
        end
        if g_currentMission.weedSystem:getHoedState(fieldState.weedState) ~= 0 then
            return false
        end
    end
    local fieldState = g_currentMission.environment
    return fieldState == nil or fieldState.currentSeason ~= Season.WINTER
end
function HoeMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(HoeMission.NAME)
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
g_missionManager:registerMissionType(HoeMission, HoeMission.NAME, 2)