BaleMission = {}
BaleMission.NAME = "baleMission"
BaleMission.THRESHOLD_LITERS = 1500
local BaleMission_mt = Class(BaleMission, AbstractFieldMission)
InitStaticObjectClass(BaleMission, "BaleMission")
function BaleMission.registerXMLPaths(schema, key)
    BaleMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function BaleMission.registerSavegameXMLPaths(schema, key)
    BaleMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. "#fruitType", "Name of the bale fruit type")
    schema:register(XMLValueType.BOOL, key .. "#needRoundbaler", "If target bale type should be roundbale")
    schema:register(XMLValueType.FLOAT, key .. "#spawnedLiters", "Spawned windrow liters")
    schema:register(XMLValueType.INT, key .. "#swathSegmentIndex", "Current swath segment index")
    schema:register(XMLValueType.BOOL, key .. "#finishedSwathSpawning", "If swath spawning is finished")
    schema:register(XMLValueType.STRING, key .. ".createdBale(?)#uniqueId", "UniqueId of created bale")
end
function BaleMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) BaleMission_mt
    local title = g_i18n:getText("contract_field_bale_title")
    local description = g_i18n:getText("contract_field_bale_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or BaleMission_mt)
    self.workAreaTypes = {
        [WorkAreaType.BALER] = true
    }
    self.finishedSwathSpawning = false
    self.initializedSwathSpawning = false
    self.needRoundbaler = false
    self.spawnedLiters = 0
    self.bales = {}
    self.balesToLoadByUniqueId = {}
    return self
end
function BaleMission:init(field, fruitTypeIndex, needRoundbaler)
    self:setFruitType(fruitTypeIndex)
    self.needRoundbaler = needRoundbaler
    if needRoundbaler then
        self.description = g_i18n:getText("contract_field_bale_descriptionRound")
    end
    return BaleMission:superClass().init(self, field)
end
function BaleMission:setField(field)
    BaleMission:superClass().setField(self, field)
    local fieldId = field:getId()
    if fieldId ~= nil then
        local baleType
        if self.needRoundbaler then
            baleType = g_i18n:getText("fillType_roundBale")
        else
            baleType = g_i18n:getText("fillType_squareBale")
        end
        self.progressTitle = string.format("%s (%s %d) - %s", self.title, g_i18n:getText("contract_details_field"), fieldId, baleType)
    end
end
function BaleMission:getDetails()
    local details = BaleMission:superClass().getDetails(self)
    local baleType
    if self.needRoundbaler then
        baleType = g_i18n:getText("contract_details_bale_type_round")
    else
        baleType = g_i18n:getText("contract_details_bale_type_square")
    end
    table.insert(details, {
        ["title"] = g_i18n:getText("contract_details_bale_type"),
        ["value"] = baleType
    })
    return details
end
function BaleMission:setFruitType(fruitTypeIndex)
    self.fruitTypeIndex = fruitTypeIndex
    self.fruitTypeTitle = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitTypeIndex).title
    self.windrowFillTypeIndex = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(self.fruitTypeIndex)
    if self.fruitTypeIndex == FruitType.GRASS then
        self.windrowFillTypeIndex = FillType.DRYGRASS_WINDROW
    end
end
function BaleMission:saveToXMLFile(xmlFile, key)
    BaleMission:superClass().saveToXMLFile(self, xmlFile, key)
    local fruitTypeName = g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex)
    xmlFile:setValue(key .. "#fruitType", fruitTypeName)
    xmlFile:setValue(key .. "#needRoundbaler", self.needRoundbaler)
    xmlFile:setValue(key .. "#spawnedLiters", self.spawnedLiters)
    if not self.finishedSwathSpawning and self.currentSwathSegmentIndex ~= nil then
        xmlFile:setValue(key .. "#swathSegmentIndex", self.currentSwathSegmentIndex)
    end
    xmlFile:setValue(key .. "#finishedSwathSpawning", self.finishedSwathSpawning)
    for i, bale in ipairs(self.bales) do
        xmlFile:setValue(string.format("%s.createdBale(%d)", key, i - 1) .. "#uniqueId", bale:getUniqueId())
    end
end
function BaleMission:loadFromXMLFile(xmlFile, key)
    local fruitTypeName = xmlFile:getValue(key .. "#fruitType")
    self:setFruitType((g_fruitTypeManager:getFruitTypeIndexByName(fruitTypeName)))
    self.needRoundbaler = xmlFile:getValue(key .. "#needRoundbaler", self.needRoundbaler)
    self.spawnedLiters = xmlFile:getValue(key .. "#spawnedLiters", self.spawnedLiters)
    if self.needRoundbaler then
        self.description = g_i18n:getText("contract_field_bale_descriptionRound")
    end
    for _, createBaleKey in xmlFile:iterator(key .. ".createdBale") do
        local baleUniqueId = xmlFile:getValue(createBaleKey .. "#uniqueId")
        table.insert(self.balesToLoadByUniqueId, baleUniqueId)
    end
    self.currentSwathSegmentIndex = xmlFile:getValue(key .. "#swathSegmentIndex", self.currentSwathSegmentIndex)
    self.finishedSwathSpawning = xmlFile:getValue(key .. "#finishedSwathSpawning", self.finishedSwathSpawning)
    if self.finishedSwathSpawning then
        self.initializedSwathSpawning = true
    end
    return BaleMission:superClass().loadFromXMLFile(self, xmlFile, key)
end
function BaleMission:writeStream(streamId, connection)
    BaleMission:superClass().writeStream(self, streamId, connection)
    streamWriteUIntN(streamId, self.fruitTypeIndex or 0, FruitTypeManager.SEND_NUM_BITS)
    streamWriteBool(streamId, self.needRoundbaler)
end
function BaleMission:readStream(streamId, connection)
    BaleMission:superClass().readStream(self, streamId, connection)
    self:setFruitType((streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)))
    self.needRoundbaler = streamReadBool(streamId)
    if self.needRoundbaler then
        self.description = g_i18n:getText("contract_field_bale_descriptionRound")
    end
end
function BaleMission:getIsPrepared()
    if BaleMission:superClass().getIsPrepared(self) then
        return self.finishedSwathSpawning
    else
        return false
    end
end
function BaleMission:getFieldPreparingTask()
    if self.isServer then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
        local fieldState = self.field:getFieldState()
        fieldState.fruitTypeIndex = self.fruitTypeIndex
        fieldState.growthState = fruitTypeDesc.cutState
        fieldState.weedState = 0
        if fruitTypeDesc.harvestGroundType ~= nil then
            fieldState.groundType = fruitTypeDesc.harvestGroundType
        end
    end
    return BaleMission:superClass().getFieldPreparingTask(self)
end
function BaleMission:getFieldFinishTask()
    local finishTask = BaleMission:superClass().getFieldFinishTask(self)
    if finishTask ~= nil then
        finishTask:clearHeight()
    end
    return finishTask
end
function BaleMission:finishField()
    if self.isServer then
        for _, bale in ipairs(self.bales) do
            bale:delete()
        end
        self.bales = {}
    end
    BaleMission:superClass().finishField(self)
end
function BaleMission:removeAccess()
    if self.isServer then
        for _, vehicle in ipairs(self.vehicles) do
            if vehicle.spec_baler ~= nil then
                vehicle.spec_baler.dropBalesOnDelete = false
            end
        end
    end
    BaleMission:superClass().removeAccess(self)
end
function BaleMission:update(dt)
    if self.isServer and (self.status == MissionStatus.PREPARING and (self.fieldPreparingTask == nil or self.fieldPreparingTask:getIsFinished())) and not self.initializedSwathSpawning then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)
        local fieldSizeHa = self.field:getAreaHa()
        local litersToDrop = MathUtil.haToSqm(fieldSizeHa) * (fruitTypeDesc.windrowLiterPerSqm or fruitTypeDesc.literPerSqm)
        local x, z = self.field:getCenterOfFieldWorldPosition()
        local fieldCourseSettings = FieldCourseSettings.new()
        fieldCourseSettings.implementWidth = fieldSizeHa > 6 and 12 or 9
        fieldCourseSettings.numHeadlands = 2
        local swathSegmentIndex = 0
        FieldCourseIterator.new(x, z, fieldCourseSettings, function(sx, sz, ex, ez, _, _, _, totalCourseLength)
            -- upvalues: (ref) swathSegmentIndex, (copy) self, (copy) litersToDrop
            swathSegmentIndex = swathSegmentIndex + 1
            if self.currentSwathSegmentIndex == nil or swathSegmentIndex > self.currentSwathSegmentIndex then
                local length = MathUtil.vector2Length(ex - sx, ez - sz)
                local fillLevel, _ = DensityMapHeightUtil.tipToGroundAroundLine(self, length * (litersToDrop / totalCourseLength), self.windrowFillTypeIndex, sx, 0, sz, ex, 0, ez, 0.5, 0.5, 0, false, nil, false, true)
                self.spawnedLiters = self.spawnedLiters + fillLevel
                self.currentSwathSegmentIndex = swathSegmentIndex
            end
        end, function()
            -- upvalues: (copy) self
            self.finishedSwathSpawning = true
        end)
        self.initializedSwathSpawning = true
    end
    if self.balesToLoadByUniqueId ~= nil then
        for fieldSizeSqm, litersToDrop in ipairs(self.balesToLoadByUniqueId) do
            local workingWidth = g_currentMission.itemSystem:getItemByUniqueId(litersToDrop)
            if workingWidth ~= nil then
                table.insert(self.bales, workingWidth)
            end
        end
        self.balesToLoadByUniqueId = nil
    end
    BaleMission:superClass().update(self, dt)
end
function BaleMission:addBale(bale)
    if bale ~= nil and bale:getFillType() == self.windrowFillTypeIndex then
        table.insert(self.bales, bale)
        bale:setOwnerFarmId(AccessHandler.NOBODY)
    end
end
function BaleMission:getFieldCompletion()
    BaleMission:superClass().getFieldCompletion(self)
    local sumPixels = 0
    local allCalculated = true
    for _, partitionPercentage in ipairs(self.completionPartitions) do
        if not partitionPercentage.wasCalculated then
            allCalculated = false
        end
    end
    local liters = sumPixels * g_densityMapHeightManager:getMinValidLiterValue(self.windrowFillTypeIndex)
    if allCalculated then
        self.fieldPercentageDone = math.clamp(1 - liters / self.spawnedLiters, 0, 1)
    end
    return self.fieldPercentageDone
end
function BaleMission:createModifier()
    local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(self.windrowFillTypeIndex)
    if heightType ~= nil then
        self.completionModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
        self.completionFilter = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
        self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)
    end
end
function BaleMission:getCompletion()
    return self:getFieldCompletion()
end
function BaleMission:getRewardPerHa()
    return g_missionManager:getMissionTypeDataByName(BaleMission.NAME).rewardPerHa
end
function BaleMission:getMissionTypeName()
    return BaleMission.NAME
end
function BaleMission:validate(event)
    if BaleMission:superClass().validate(self, event) then
        return (self:getIsFinished() or BaleMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function BaleMission:getIsWorkAllowed(farmId, x, z, workAreaType, vehicle)
    if not BaleMission:superClass().getIsWorkAllowed(self, farmId, x, z, workAreaType, vehicle) then
        return false
    end
    if vehicle == nil or vehicle.getIsRoundBaler == nil then
        return true
    end
    return vehicle:getIsRoundBaler() == self.needRoundbaler
end
function BaleMission:getVehicleVariant()
    return self.needRoundbaler and "ROUNDBALER" or "SQUAREBALER"
end
function BaleMission:getVariant()
    return self.needRoundbaler and "ROUNDBALER" or "SQUAREBALER"
end
function BaleMission.loadMapData(xmlFile, key, _)
    g_missionManager:getMissionTypeDataByName(BaleMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 2200)
    return true
end
function BaleMission.tryGenerateMission()
    if BaleMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not BaleMission.isAvailableForField(field, nil) then
            return
        end
        local fieldState = field:getFieldState()
        local needRoundbaler = math.random() > 0.5
        local mission = BaleMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field, fieldState.fruitTypeIndex, needRoundbaler) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function BaleMission.isAvailableForField(field, mission)
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
        if not fruitTypeDesc:getIsHarvestReady(fieldState.growthState) then
            return false
        end
        if not fruitTypeDesc.hasWindrow then
            return false
        end
        local windrowFillTypeIndex = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitTypeDesc.index)
        if windrowFillTypeIndex ~= FillType.STRAW and windrowFillTypeIndex ~= FillType.DRYGRASS_WINDROW then
            return false
        end
    end
    local fieldState = g_currentMission.environment
    return fieldState == nil or fieldState.currentSeason ~= Season.WINTER
end
function BaleMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(BaleMission.NAME)
    return data.numInstances < data.maxNumInstances
end
g_missionManager:registerMissionType(BaleMission, BaleMission.NAME, 3)