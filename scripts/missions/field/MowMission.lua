MowMission = {}
MowMission.NAME = "mowMission"
local MowMission_mt = Class(MowMission, AbstractFieldMission)
InitStaticObjectClass(MowMission, "MowMission")
function MowMission.registerXMLPaths(schema, key)
    MowMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function MowMission.registerSavegameXMLPaths(schema, key)
    MowMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. "#fruitType", "Name of the fruit type")
end
function MowMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) MowMission_mt
    local title = g_i18n:getText("contract_field_mow_title")
    local description = g_i18n:getText("contract_field_mow_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or MowMission_mt)
    self.workAreaTypes = {
        [WorkAreaType.MOWER] = true
    }
    self.fruitTypeIndex = nil
    return self
end
function MowMission:init(field, fruitTypeIndex)
    self.fruitTypeIndex = fruitTypeIndex
    self.fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
    return MowMission:superClass().init(self, field)
end
function MowMission:onSavegameLoaded()
    if self.field == nil then
        Logging.error("Field is not set for mow mission")
        g_missionManager:markMissionForDeletion(self)
        return
    elseif self.field:getFieldState().fruitTypeIndex == self.fruitTypeIndex then
        MowMission:superClass().onSavegameLoaded(self)
    else
        local fruitType = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
        if fruitType == nil then
            Logging.error("FruitType \'%s\' is not defined for mow mission", self.fruitTypeIndex)
        else
            Logging.error("FruitType \'%s\' is not present on field \'%s\' for mow mission", fruitType.name, self.field:getName())
        end
        g_missionManager:markMissionForDeletion(self)
    end
end
function MowMission:saveToXMLFile(xmlFile, key)
    MowMission:superClass().saveToXMLFile(self, xmlFile, key)
    xmlFile:setValue(key .. "#fruitType", g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex))
end
function MowMission:loadFromXMLFile(xmlFile, key)
    if not MowMission:superClass().loadFromXMLFile(self, xmlFile, key) then
        return false
    end
    local fruitTypeName = xmlFile:getValue(key .. "#fruitType")
    local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
    if fruitType == nil then
        Logging.xmlError(xmlFile, "FruitType \'%s\' not defined", fruitTypeName)
        return false
    end
    self.fruitTypeIndex = fruitType.index
    self.fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(self.fruitTypeIndex)
    return true
end
function MowMission:createModifier()
    local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
    if fruitDesc ~= nil and fruitDesc.terrainDataPlaneId ~= nil then
        self.completionModifier = DensityMapModifier.new(fruitDesc.terrainDataPlaneId, fruitDesc.startStateChannel, fruitDesc.numStateChannels, g_terrainNode)
        self.completionFilter = DensityMapFilter.new(self.completionModifier)
        self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, fruitDesc.cutState)
    end
end
function MowMission:getFieldFinishTask()
    local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
    if fruitTypeDesc ~= nil then
        local fieldState = self.field:getFieldState()
        fieldState.fruitTypeIndex = self.fruitTypeIndex
        fieldState.growthState = fruitTypeDesc.cutState
    end
    local fieldState = MowMission:superClass().getFieldFinishTask(self)
    if fieldState ~= nil then
        fieldState:clearHeight()
    end
    return fieldState
end
function MowMission:getRewardPerHa()
    return g_missionManager:getMissionTypeDataByName(MowMission.NAME).rewardPerHa
end
function MowMission:getMissionTypeName()
    return MowMission.NAME
end
function MowMission:validate(event)
    if MowMission:superClass().validate(self, event) then
        return (self:getIsFinished() or MowMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function MowMission.loadMapData(xmlFile, key, _)
    local data = g_missionManager:getMissionTypeDataByName(MowMission.NAME)
    data.rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2500)
    data.fruitTypeIndices = {}
    if FruitType.GRASS ~= nil then
        data.fruitTypeIndices[FruitType.GRASS] = true
    end
    return true
end
function MowMission.tryGenerateMission()
    if MowMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not MowMission.isAvailableForField(field, nil) then
            return
        end
        local fruitTypeIndex = field:getFieldState().fruitTypeIndex
        local mission = MowMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field, fruitTypeIndex) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function MowMission.isAvailableForField(field, mission)
    if mission == nil then
        local fieldState = field:getFieldState()
        if not fieldState.isValid then
            return false
        end
        local data = g_missionManager:getMissionTypeDataByName(MowMission.NAME)
        local fruitTypeIndex = fieldState.fruitTypeIndex
        if data.fruitTypeIndices[fruitTypeIndex] == nil then
            return false
        end
        if not g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex):getIsHarvestable(fieldState.growthState) then
            return false
        end
    end
    local fieldState = g_currentMission.environment
    if fieldState ~= nil then
        if fieldState.currentSeason == Season.WINTER then
            return false
        end
        if fieldState.currentPeriod == SeasonPeriod.EARLY_SPRING or fieldState.currentPeriod == SeasonPeriod.MID_SPRING then
            return false
        end
    end
    return true
end
function MowMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(MowMission.NAME)
    return data.numInstances < data.maxNumInstances
end
g_missionManager:registerMissionType(MowMission, MowMission.NAME, 3)