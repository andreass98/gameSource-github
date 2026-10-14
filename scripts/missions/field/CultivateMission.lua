CultivateMission = {}
CultivateMission.NAME = "cultivateMission"
local CultivateMission_mt = Class(CultivateMission, AbstractFieldMission)
InitStaticObjectClass(CultivateMission, "CultivateMission")
function CultivateMission.registerXMLPaths(schema, key)
    CultivateMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function CultivateMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) CultivateMission_mt
    local title = g_i18n:getText("contract_field_cultivate_title")
    local description = g_i18n:getText("contract_field_cultivate_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or CultivateMission_mt)
    self.workAreaTypes = {
        [WorkAreaType.CULTIVATOR] = true
    }
    return self
end
function CultivateMission:createModifier()
    local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
    local stubbleTillageValue = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
    local seedbedValue = FieldGroundType.getValueByType(FieldGroundType.SEEDBED)
    self.completionModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, g_terrainNode)
    self.completionFilter = DensityMapFilter.new(self.completionModifier)
    self.completionFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, stubbleTillageValue, seedbedValue)
end
function CultivateMission:getFieldFinishTask()
    local fieldState = self.field:getFieldState()
    fieldState.fruitTypeIndex = FruitType.UNKNOWN
    fieldState.groundType = FieldGroundType.CULTIVATED
    return CultivateMission:superClass().getFieldFinishTask(self)
end
function CultivateMission:getRewardPerHa()
    return g_missionManager:getMissionTypeDataByName(CultivateMission.NAME).rewardPerHa
end
function CultivateMission:getMissionTypeName()
    return CultivateMission.NAME
end
function CultivateMission:validate(event)
    if CultivateMission:superClass().validate(self, event) then
        return (self:getIsFinished() or CultivateMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function CultivateMission.loadMapData(xmlFile, key, _)
    g_missionManager:getMissionTypeDataByName(CultivateMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2300)
    return true
end
function CultivateMission.tryGenerateMission()
    if CultivateMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not CultivateMission.isAvailableForField(field, nil) then
            return
        end
        local mission = CultivateMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function CultivateMission.isAvailableForField(field, mission)
    if mission == nil then
        local fieldState = field:getFieldState()
        if not fieldState.isValid then
            return false
        end
        if field.grassMissionOnly then
            return false
        end
        local fruitTypeIndex = fieldState.fruitTypeIndex
        if fruitTypeIndex == FruitType.UNKNOWN then
            return false
        end
        local growthState = fieldState.growthState
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
        if fruitTypeDesc:getIsCatchCrop() and growthState <= 1 then
            return false
        end
        if not (fruitTypeDesc:getIsCut(growthState) or fruitTypeDesc:getIsWithered(growthState)) then
            return false
        end
    end
    return true
end
function CultivateMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(CultivateMission.NAME)
    return data.numInstances < data.maxNumInstances
end
g_missionManager:registerMissionType(CultivateMission, CultivateMission.NAME, 3)