FertilizeMission = {}
FertilizeMission.NAME = "fertilizeMission"
local FertilizeMission_mt = Class(FertilizeMission, AbstractFieldMission)
InitStaticObjectClass(FertilizeMission, "FertilizeMission")
function FertilizeMission.registerXMLPaths(schema, key)
    FertilizeMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function FertilizeMission.registerSavegameXMLPaths(schema, key)
    FertilizeMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#targetSprayLevel", "Target spray level")
end
function FertilizeMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) FertilizeMission_mt
    local title = g_i18n:getText("contract_field_fertilize_title")
    local description = g_i18n:getText("contract_field_fertilize_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or FertilizeMission_mt)
    self.workAreaTypes = {
        [WorkAreaType.SPRAYER] = true
    }
    self.validFertilizerFillTypes = {}
    self.validFertilizerFillTypes[FillType.FERTILIZER] = true
    self.validFertilizerFillTypes[FillType.LIQUIDFERTILIZER] = true
    self.validFertilizerFillTypes[FillType.LIQUIDMANURE] = true
    self.validFertilizerFillTypes[FillType.MANURE] = true
    self.filLTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(FillType.FERTILIZER)
    self.targetSprayLevel = nil
    return self
end
function FertilizeMission:init(field, targetSprayLevel)
    self.targetSprayLevel = targetSprayLevel
    return FertilizeMission:superClass().init(self, field)
end
function FertilizeMission:saveToXMLFile(xmlFile, key)
    FertilizeMission:superClass().saveToXMLFile(self, xmlFile, key)
    xmlFile:setValue(key .. "#targetSprayLevel", self.targetSprayLevel)
end
function FertilizeMission:loadFromXMLFile(xmlFile, key)
    if not FertilizeMission:superClass().loadFromXMLFile(self, xmlFile, key) then
        return false
    end
    self.targetSprayLevel = xmlFile:getValue(key .. "#targetSprayLevel")
    return true
end
function FertilizeMission:createModifier()
    local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
    self.completionModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, g_terrainNode)
    self.completionFilter = DensityMapFilter.new(self.completionModifier)
    self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.targetSprayLevel)
end
function FertilizeMission:getFieldFinishTask()
    self.field:getFieldState().sprayLevel = self.targetSprayLevel
    return FertilizeMission:superClass().getFieldFinishTask(self)
end
function FertilizeMission:getRewardPerHa()
    return g_missionManager:getMissionTypeDataByName(FertilizeMission.NAME).rewardPerHa
end
function FertilizeMission:calculateReimbursement()
    FertilizeMission:superClass().calculateReimbursement(self)
    local totalWorth = 0
    for _, vehicle in pairs(self.vehicles) do
        if vehicle.spec_fillUnit ~= nil then
            for fillUnitIndex, _ in pairs(vehicle:getFillUnits()) do
                local fillType = vehicle:getFillUnitFillType(fillUnitIndex)
                if self.validFertilizerFillTypes[fillType] ~= nil then
                    totalWorth = totalWorth + vehicle:getFillUnitFillLevel(fillUnitIndex) * g_fillTypeManager:getFillTypeByIndex(fillType).pricePerLiter
                end
            end
        end
    end
    self.reimbursement = self.reimbursement + totalWorth * AbstractMission.REIMBURSEMENT_FACTOR
end
function FertilizeMission:getMissionTypeName()
    return FertilizeMission.NAME
end
function FertilizeMission:validate(event)
    if FertilizeMission:superClass().validate(self, event) then
        return (self:getIsFinished() or FertilizeMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function FertilizeMission.loadMapData(xmlFile, key, _)
    g_missionManager:getMissionTypeDataByName(FertilizeMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 1500)
    return true
end
function FertilizeMission.tryGenerateMission()
    if FertilizeMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not FertilizeMission.isAvailableForField(field, nil) then
            return
        end
        local targetSprayLevel = field:getFieldState().sprayLevel + 1
        local mission = FertilizeMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field, targetSprayLevel) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function FertilizeMission.isAvailableForField(field, mission)
    if mission == nil then
        local fieldState = field:getFieldState()
        if not fieldState.isValid then
            return false
        end
        if fieldState.sprayType ~= FieldSprayType.NONE then
            return false
        end
        local fruitTypeIndex = fieldState.fruitTypeIndex
        if fruitTypeIndex == FruitType.UNKNOWN then
            return false
        end
        if g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL) <= fieldState.sprayLevel then
            return false
        end
        local growthState = fieldState.growthState
        if growthState ~= nil and growthState <= 1 then
            return false
        end
        local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
        if fruitType:getIsCatchCrop() then
            return false
        end
        if fruitType:getIsHarvestable(growthState) then
            return false
        end
    end
    local fieldState = g_currentMission.environment
    return fieldState == nil or fieldState.currentSeason ~= Season.WINTER
end
function FertilizeMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(FertilizeMission.NAME)
    if data.numInstances >= data.maxNumInstances then
        return false
    else
        return not g_currentMission.growthSystem:getIsGrowingInProgress()
    end
end
g_missionManager:registerMissionType(FertilizeMission, FertilizeMission.NAME, 3)