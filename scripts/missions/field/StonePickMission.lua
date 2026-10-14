StonePickMission = {}
StonePickMission.NAME = "stonePickMission"
local StonePickMission_mt = Class(StonePickMission, AbstractFieldMission)
InitStaticObjectClass(StonePickMission, "StonePickMission")
function StonePickMission.registerXMLPaths(schema, key)
    StonePickMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function StonePickMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) StonePickMission_mt
    local title = g_i18n:getText("contract_field_stonePick_title")
    local description = g_i18n:getText("contract_field_stonePick_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or StonePickMission_mt)
    self.workAreaTypes = {
        [WorkAreaType.STONEPICKER] = true
    }
    self.stoneValue = 3
    self.spawnedPixels = 0
    return self
end
function StonePickMission:init(field)
    return StonePickMission:superClass().init(self, field)
end
function StonePickMission:getFieldPreparingTask()
    if self.isServer then
        self.field:getFieldState().stoneLevel = self.stoneValue
    end
    return StonePickMission:superClass().getFieldPreparingTask(self)
end
function StonePickMission:getFieldFinishTask()
    if self.isServer then
        local fieldState = self.field:getFieldState()
        fieldState.stoneLevel = 0
        fieldState.groundType = FieldGroundType.CULTIVATED
    end
    return StonePickMission:superClass().getFieldFinishTask(self)
end
function StonePickMission:createModifier()
    local mapId, firstChannel, numChannels = g_currentMission.stoneSystem:getDensityMapData()
    local _, maxValue = g_currentMission.stoneSystem:getMinMaxValues()
    self.completionModifier = DensityMapModifier.new(mapId, firstChannel, numChannels, g_terrainNode)
    self.completionModifierUnmasked = DensityMapModifier.new(mapId, firstChannel, numChannels, g_terrainNode)
    self.completionFilter = DensityMapFilter.new(self.completionModifier)
    self.completionFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, maxValue)
    self.completionFilterMasked = DensityMapFilter.new(self.completionModifier)
    self.completionFilterMasked:setValueCompareParams(DensityValueCompareType.GREATER, 0)
    self.completionFilterUnmasked = DensityMapFilter.new(self.completionModifier)
    self.completionFilterUnmasked:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
end
function StonePickMission:getPartitionCompletion(partitionIndex)
    self:setPartitionRegion(partitionIndex)
    if self.completionModifier == nil then
        return 0, 0, 0
    end
    local sumPixels, area, totalArea = self.completionModifier:executeGet(self.completionFilter, self.completionFilterMasked)
    local _, unmaskedArea, _ = self.completionModifierUnmasked:executeGet(self.completionFilterUnmasked)
    return sumPixels, area, totalArea - unmaskedArea
end
function StonePickMission:initializeModifier()
    StonePickMission:superClass().initializeModifier(self)
    if self.completionModifierUnmasked ~= nil then
        self.field:getDensityMapPolygon():applyToModifier(self.completionModifierUnmasked)
    end
end
function StonePickMission:setPartitionRegion(partitionIndex)
    StonePickMission:superClass().setPartitionRegion(self, partitionIndex)
    if #self.completionPartitions ~= 1 then
        if self.completionModifierUnmasked ~= nil then
            local partition = self.completionPartitions[partitionIndex]
            self.completionModifierUnmasked:setPolygonClipRegion(partition.minZ, partition.maxZ)
        end
    end
end
function StonePickMission:getRewardPerHa()
    return g_missionManager:getMissionTypeDataByName(StonePickMission.NAME).rewardPerHa
end
function StonePickMission:getMissionTypeName()
    return StonePickMission.NAME
end
function StonePickMission:validate(event)
    if StonePickMission:superClass().validate(self, event) then
        return (self:getIsFinished() or StonePickMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function StonePickMission.loadMapData(xmlFile, key, _)
    g_missionManager:getMissionTypeDataByName(StonePickMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2200)
    return true
end
function StonePickMission.tryGenerateMission()
    if StonePickMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not StonePickMission.isAvailableForField(field, nil) then
            return
        end
        local mission = StonePickMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function StonePickMission.isAvailableForField(field, mission)
    if mission == nil then
        local fieldState = field:getFieldState()
        if not fieldState.isValid then
            return false
        end
        if fieldState.fruitTypeIndex ~= FruitType.UNKNOWN then
            return false
        end
        if fieldState.groundType ~= FieldGroundType.PLOWED then
            return false
        end
    end
    local fieldState = g_currentMission.environment
    return fieldState == nil or fieldState.currentSeason ~= Season.WINTER
end
function StonePickMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(StonePickMission.NAME)
    return data.numInstances < data.maxNumInstances
end
g_missionManager:registerMissionType(StonePickMission, StonePickMission.NAME, 1)