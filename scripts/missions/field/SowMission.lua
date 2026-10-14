SowMission = {}
SowMission.NAME = "sowMission"
local SowMission_mt = Class(SowMission, AbstractFieldMission)
InitStaticObjectClass(SowMission, "SowMission")
function SowMission.registerXMLPaths(schema, key)
    SowMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function SowMission.registerSavegameXMLPaths(schema, key)
    SowMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. "#fruitType", "Name of the fruit type")
end
function SowMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) SowMission_mt
    local title = g_i18n:getText("contract_field_sow_title")
    local description = g_i18n:getText("contract_field_sow_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or SowMission_mt)
    self.workAreaTypes = {
        [WorkAreaType.SOWINGMACHINE] = true,
        [WorkAreaType.RIDGEMARKER] = true
    }
    self.fruitTypeIndex = nil
    self.fruitTypeTitle = nil
    self.growthState = 1
    return self
end
function SowMission:init(field, fruitTypeIndex)
    self.fruitTypeIndex = fruitTypeIndex
    self.fruitTypeTitle = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitTypeIndex).title
    return SowMission:superClass().init(self, field)
end
function SowMission:saveToXMLFile(xmlFile, key)
    SowMission:superClass().saveToXMLFile(self, xmlFile, key)
    local fruitTypeName = g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex)
    xmlFile:setValue(key .. "#fruitType", fruitTypeName)
end
function SowMission:loadFromXMLFile(xmlFile, key)
    local fruitTypeName = xmlFile:getValue(key .. "#fruitType")
    self.fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(fruitTypeName)
    return SowMission:superClass().loadFromXMLFile(self, xmlFile, key)
end
function SowMission:writeStream(streamId, connection)
    SowMission:superClass().writeStream(self, streamId, connection)
    streamWriteUIntN(streamId, self.fruitTypeIndex or 0, FruitTypeManager.SEND_NUM_BITS)
end
function SowMission:readStream(streamId, connection)
    SowMission:superClass().readStream(self, streamId, connection)
    self.fruitTypeIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
end
function SowMission:getFieldFinishTask()
    local fieldState = self.field:getFieldState()
    fieldState.fruitTypeIndex = self.fruitTypeIndex
    fieldState.growthState = self.growthState
    fieldState.groundType = FieldGroundType.SOWN
    return SowMission:superClass().getFieldFinishTask(self)
end
function SowMission:getVehicleVariant()
    local fruitTypeIndex = self.fruitTypeIndex
    if fruitTypeIndex ~= nil then
        if fruitTypeIndex == FruitType.SUNFLOWER or (fruitTypeIndex == FruitType.MAIZE or (fruitTypeIndex == FruitType.SOYBEAN or (fruitTypeIndex == FruitType.SORGHUM or fruitTypeIndex == FruitType.GREENBEAN))) then
            return "MAIZE"
        end
        if fruitTypeIndex == FruitType.SUGARBEET then
            return "SUGARBEET"
        end
        if fruitTypeIndex == FruitType.POTATO then
            return "POTATO"
        end
        if fruitTypeIndex == FruitType.COTTON then
            return "COTTON"
        end
        if fruitTypeIndex == FruitType.SUGARCANE then
            return "SUGARCANE"
        end
        if fruitTypeIndex == FruitType.CARROT or (fruitTypeIndex == FruitType.PARSNIP or fruitTypeIndex == FruitType.BEETROOT) then
            return "VEGETABLES"
        end
        if fruitTypeIndex == FruitType.ONION then
            return "ONION"
        end
    end
    return "GRAIN"
end
function SowMission:getVariant()
    local fruitTypeIndex = self.fruitTypeIndex
    if fruitTypeIndex ~= nil then
        if fruitTypeIndex == FruitType.BEETROOT then
            return "BEETROOT"
        end
        if fruitTypeIndex == FruitType.CARROT then
            return "CARROT"
        end
        if fruitTypeIndex == FruitType.MAIZE then
            return "MAIZE"
        end
        if fruitTypeIndex == FruitType.COTTON then
            return "COTTON"
        end
        if fruitTypeIndex == FruitType.GREENBEAN then
            return "GREENBEAN"
        end
        if fruitTypeIndex == FruitType.PARSNIP then
            return "PARSNIP"
        end
        if fruitTypeIndex == FruitType.PEA then
            return "PEA"
        end
        if fruitTypeIndex == FruitType.POPLAR then
            return "POPLAR"
        end
        if fruitTypeIndex == FruitType.POTATO then
            return "POTATO"
        end
        if fruitTypeIndex == FruitType.RICE then
            return "RICE"
        end
        if fruitTypeIndex == FruitType.RICELONGGRAIN then
            return "RICELONGGRAIN"
        end
        if fruitTypeIndex == FruitType.SPINACH then
            return "SPINACH"
        end
        if fruitTypeIndex == FruitType.SUGARCANE then
            return "SUGARCANE"
        end
        if fruitTypeIndex == FruitType.SUGARBEET then
            return "SUGARBEET"
        end
        if fruitTypeIndex == FruitType.SUNFLOWER then
            return "SUNFLOWER"
        end
        if fruitTypeIndex == FruitType.ONION then
            return "ONION"
        end
    end
    return "GRAIN"
end
function SowMission:createModifier()
    local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
    if fruitDesc ~= nil and fruitDesc.terrainDataPlaneId ~= nil then
        self.completionModifier = DensityMapModifier.new(fruitDesc.terrainDataPlaneId, fruitDesc.startStateChannel, fruitDesc.numStateChannels, g_terrainNode)
        self.completionFilter = DensityMapFilter.new(self.completionModifier)
        self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.growthState)
    end
end
function SowMission:getPartitionCompletion(partitionIndex)
    self:setPartitionRegion(partitionIndex)
    if self.completionModifier == nil then
        return 0, 0, 0
    end
    local sumPixels, area, totalArea = self.completionModifier:executeGet(self.completionFilter)
    return sumPixels, area, totalArea
end
function SowMission:getRewardPerHa()
    return g_missionManager:getMissionTypeDataByName(SowMission.NAME).rewardPerHa
end
function SowMission:calculateReimbursement()
    SowMission:superClass().calculateReimbursement(self)
    local totalWorth = 0
    for _, vehicle in pairs(self.vehicles) do
        if vehicle.spec_fillUnit ~= nil then
            for fillUnitIndex, _ in pairs(vehicle:getFillUnits()) do
                local fillType = vehicle:getFillUnitFillType(fillUnitIndex)
                if fillType == FillType.SEEDS then
                    totalWorth = totalWorth + vehicle:getFillUnitFillLevel(fillUnitIndex) * g_fillTypeManager:getFillTypeByIndex(fillType).pricePerLiter
                end
            end
        end
    end
    local totalWorth = totalWorth + g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex).seedUsagePerSqm * 10000 * g_currentMission.economyManager:getCostPerLiter(FillType.SEEDS) * self.field.areaHa
    self.reimbursement = self.reimbursement + totalWorth * AbstractMission.REIMBURSEMENT_FACTOR
end
function SowMission:getDetails()
    local details = SowMission:superClass().getDetails(self)
    local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_details_sow_crop"),
        ["value"] = fruitDesc.fillType.title
    })
    return details
end
function SowMission:getMissionTypeName()
    return SowMission.NAME
end
function SowMission:validate(event)
    if not self:getWasStarted() then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
        if fruitTypeDesc == nil or not fruitTypeDesc:getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod) then
            return false
        end
    end
    if SowMission:superClass().validate(self, event) then
        return (self:getIsFinished() or SowMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function SowMission.loadMapData(xmlFile, key, _)
    g_missionManager:getMissionTypeDataByName(SowMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2000)
    return true
end
function SowMission.tryGenerateMission()
    if SowMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not SowMission.isAvailableForField(field, nil) then
            return
        end
        local plannedFruitTypeIndex = field:getPlannedFruitTypeIndex()
        local mission = SowMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field, plannedFruitTypeIndex) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function SowMission.isAvailableForField(field, mission)
    local fieldState = field:getFieldState()
    if not fieldState.isValid then
        return false
    end
    if fieldState.fruitTypeIndex ~= FruitType.UNKNOWN then
        return false
    end
    if mission == nil then
        local plannedFruitTypeIndex = field:getPlannedFruitTypeIndex()
        if plannedFruitTypeIndex == 0 then
            return
        end
        if not g_fruitTypeManager:getFruitTypeByIndex(plannedFruitTypeIndex):getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod) then
            return false
        end
    end
    return true
end
function SowMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(SowMission.NAME)
    return data.numInstances < data.maxNumInstances
end
g_missionManager:registerMissionType(SowMission, SowMission.NAME, 5)