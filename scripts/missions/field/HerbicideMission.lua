HerbicideMission = {}
HerbicideMission.NAME = "herbicideMission"
local HerbicideMission_mt = Class(HerbicideMission, AbstractFieldMission)
InitStaticObjectClass(HerbicideMission, "HerbicideMission")
function HerbicideMission.registerXMLPaths(schema, key)
    HerbicideMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function HerbicideMission.registerSavegameXMLPaths(schema, key)
    HerbicideMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#targetWeedState", "Target weed state")
end
function HerbicideMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) HerbicideMission_mt
    local title = g_i18n:getText("contract_field_herbicide_title")
    local description = g_i18n:getText("contract_field_herbicide_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or HerbicideMission_mt)
    self.workAreaTypes = {
        [WorkAreaType.SPRAYER] = true
    }
    self.fillTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(FillType.HERBICIDE)
    return self
end
function HerbicideMission:init(field, targetWeedState)
    self.targetWeedState = targetWeedState
    return HerbicideMission:superClass().init(self, field)
end
function HerbicideMission:saveToXMLFile(xmlFile, key)
    HerbicideMission:superClass().saveToXMLFile(self, xmlFile, key)
    xmlFile:setValue(key .. "#targetWeedState", self.targetWeedState)
end
function HerbicideMission:loadFromXMLFile(xmlFile, key)
    self.targetWeedState = xmlFile:getValue(key .. "#targetWeedState", self.targetWeedState)
    return HerbicideMission:superClass().loadFromXMLFile(self, xmlFile, key)
end
function HerbicideMission:createModifier()
    local weedMapId, weedFirstChannel, weedNumChannels = g_currentMission.weedSystem:getDensityMapData()
    local modifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode)
    local filter = DensityMapFilter.new(modifier)
    filter:setValueCompareParams(DensityValueCompareType.EQUAL, self.targetWeedState)
    self.completionModifier = DensityMapMultiModifier.new()
    self.completionModifier:addExecuteGet("targetState", modifier, filter)
    filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
    self.completionModifier:addExecuteGet("totalArea", modifier, filter)
    self.matchingPixels = {}
end
function HerbicideMission:getPartitionCompletion(partitionIndex)
    self:setPartitionRegion(partitionIndex)
    if self.completionModifier == nil then
        return 0, 0, 0
    end
    self.completionModifier:resetStats()
    self.completionModifier:execute(nil, self.matchingPixels, nil)
    return 0, self.matchingPixels.targetState, self.matchingPixels.totalArea
end
function HerbicideMission:getFieldFinishTask()
    self.field:getFieldState().weedState = self.targetWeedState
    return HerbicideMission:superClass().getFieldFinishTask(self)
end
function HerbicideMission:calculateReimbursement()
    HerbicideMission:superClass().calculateReimbursement(self)
    local totalWorth = 0
    for _, vehicle in pairs(self.vehicles) do
        if vehicle.spec_fillUnit ~= nil then
            for fillUnitIndex, _ in pairs(vehicle:getFillUnits()) do
                local fillType = vehicle:getFillUnitFillType(fillUnitIndex)
                if fillType == FillType.HERBICIDE then
                    totalWorth = totalWorth + vehicle:getFillUnitFillLevel(fillUnitIndex) * g_fillTypeManager:getFillTypeByIndex(fillType).pricePerLiter
                end
            end
        end
    end
    self.reimbursement = self.reimbursement + totalWorth * AbstractMission.REIMBURSEMENT_FACTOR
end
function HerbicideMission:getRewardPerHa()
    return g_missionManager:getMissionTypeDataByName(HerbicideMission.NAME).rewardPerHa
end
function HerbicideMission:getMissionTypeName()
    return HerbicideMission.NAME
end
function HerbicideMission:validate(event)
    if HerbicideMission:superClass().validate(self, event) then
        return (self:getIsFinished() or HerbicideMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function HerbicideMission.loadMapData(xmlFile, key, _)
    g_missionManager:getMissionTypeDataByName(HerbicideMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 1500)
    return true
end
function HerbicideMission.tryGenerateMission()
    if HerbicideMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not HerbicideMission.isAvailableForField(field, nil) then
            return
        end
        local weedState = field:getFieldState().weedState
        local replacement = g_currentMission.weedSystem:getHerbicideReplacements().weed.replacements[weedState]
        local mission = HerbicideMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field, replacement) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function HerbicideMission.isAvailableForField(field, mission)
    if mission == nil then
        local fieldState = field:getFieldState()
        if not fieldState.isValid then
            return false
        end
        local fruitTypeIndex = fieldState.fruitTypeIndex
        if fruitTypeIndex == FruitType.UNKNOWN then
            return false
        end
        if fruitTypeIndex == FruitType.GRASS or fruitTypeIndex == FruitType.MEADOW then
            return false
        end
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
        if fruitTypeDesc:getIsCatchCrop() then
            return false
        end
        if fieldState.weedState == 0 then
            return false
        end
        local growthState = fieldState.growthState
        if fruitTypeDesc:getIsHarvestable(growthState) then
            return false
        end
        if fruitTypeDesc:getIsWeedable(growthState) then
            return false
        end
        if fruitTypeDesc:getIsHoeable(growthState) then
            return false
        end
        local replacement = g_currentMission.weedSystem:getHerbicideReplacements().weed.replacements[fieldState.weedState]
        if replacement == nil or replacement == 0 then
            return false
        end
    end
    local fieldState = g_currentMission.environment
    return fieldState == nil or fieldState.currentSeason ~= Season.WINTER
end
function HerbicideMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(HerbicideMission.NAME)
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
g_missionManager:registerMissionType(HerbicideMission, HerbicideMission.NAME, 2)