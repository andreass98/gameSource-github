TedderMission = {}
TedderMission.NAME = "tedderMission"
local TedderMission_mt = Class(TedderMission, AbstractFieldMission)
InitStaticObjectClass(TedderMission, "TedderMission")
function TedderMission.registerXMLPaths(schema, key)
    TedderMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerHa", "Reward per ha")
end
function TedderMission.registerSavegameXMLPaths(schema, key)
    TedderMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#spawnedLiters", "Spawned grass liters")
    schema:register(XMLValueType.INT, key .. "#grassSegmentIndex", "Current grass segment index")
    schema:register(XMLValueType.BOOL, key .. "#finishedGrassSpawning", "If grass spawning is finished")
end
function TedderMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) TedderMission_mt
    local title = g_i18n:getText("contract_field_tedder_title")
    local description = g_i18n:getText("contract_field_tedder_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or TedderMission_mt)
    self.workAreaTypes = {
        [WorkAreaType.TEDDER] = true
    }
    self.finishedGrassSpawning = false
    self.initializedGrassSpawning = false
    self.currentGrassSegmentIndex = nil
    self.spawnedLiters = 0
    return self
end
function TedderMission:saveToXMLFile(xmlFile, key)
    TedderMission:superClass().saveToXMLFile(self, xmlFile, key)
    xmlFile:setValue(key .. "#spawnedLiters", self.spawnedLiters)
    if not self.finishedGrassSpawning and self.currentGrassSegmentIndex ~= nil then
        xmlFile:setValue(key .. "#grassSegmentIndex", self.currentGrassSegmentIndex)
    end
    xmlFile:setValue(key .. "#finishedGrassSpawning", self.finishedGrassSpawning)
end
function TedderMission:loadFromXMLFile(xmlFile, key)
    self.spawnedLiters = xmlFile:getValue(key .. "#spawnedLiters", self.spawnedLiters)
    self.currentGrassSegmentIndex = xmlFile:getValue(key .. "#grassSegmentIndex", self.currentGrassSegmentIndex)
    self.finishedGrassSpawning = xmlFile:getValue(key .. "#finishedGrassSpawning", self.finishedGrassSpawning)
    if self.finishedGrassSpawning then
        self.initializedGrassSpawning = true
    end
    return TedderMission:superClass().loadFromXMLFile(self, xmlFile, key)
end
function TedderMission:getFieldPreparingTask()
    local fruitType = FruitType.GRASS
    local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
    local fieldPreparingTask = FieldUpdateTask.new()
    fieldPreparingTask:setArea(self.field:getDensityMapPolygon())
    fieldPreparingTask:setField(self.field)
    fieldPreparingTask:setFruit(fruitType, fruitTypeDesc.cutState)
    if fruitTypeDesc.harvestGroundType ~= nil then
        fieldPreparingTask:setGroundType(fruitTypeDesc.harvestGroundType)
    end
    return fieldPreparingTask
end
function TedderMission:getIsPrepared()
    if TedderMission:superClass().getIsPrepared(self) then
        return self.finishedGrassSpawning
    else
        return false
    end
end
function TedderMission:getFieldFinishTask()
    local finishTask = TedderMission:superClass().getFieldFinishTask(self)
    if finishTask ~= nil then
        finishTask:clearHeight()
    end
    return finishTask
end
function TedderMission:update(dt)
    if self.isServer and (self.status == MissionStatus.PREPARING and (self.fieldPreparingTask == nil or self.fieldPreparingTask:getIsFinished())) and not self.initializedGrassSpawning then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)
        local litersPerSqm = fruitTypeDesc.windrowLiterPerSqm or fruitTypeDesc.literPerSqm
        local minLitersPerSqm = g_densityMapHeightManager:getMinValidLiterValuePerSqm(FillType.GRASS_WINDROW)
        local litersPerSqm = math.max(litersPerSqm, minLitersPerSqm)
        local dropWidth = 3
        local x, z = self.field:getCenterOfFieldWorldPosition()
        local fieldCourseSettings = FieldCourseSettings.new()
        fieldCourseSettings.implementWidth = 4
        fieldCourseSettings.numHeadlands = 1
        local heightModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
        local typeModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
        local typeId = g_densityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(FillType.GRASS_WINDROW)
        local grassSegmentIndex = 0
        FieldCourseIterator.new(x, z, fieldCourseSettings, function(sx, sz, ex, ez, _, headlandIndex, _, _)
            -- upvalues: (ref) grassSegmentIndex, (copy) self, (copy) typeModifier, (copy) heightModifier, (copy) typeId, (ref) litersPerSqm, (copy) dropWidth
            grassSegmentIndex = grassSegmentIndex + 1
            if headlandIndex == nil and (self.currentGrassSegmentIndex == nil or grassSegmentIndex > self.currentGrassSegmentIndex) then
                local dirX, dirZ = MathUtil.vector2Normalize(ex - sx, ez - sz)
                local asx, _, asz = MathUtil.transform(sx, 0, sz, dirX, 0, dirZ, 0, 1, 0, -1.5, 0, 0)
                local awx, _, awz = MathUtil.transform(sx, 0, sz, dirX, 0, dirZ, 0, 1, 0, 1.5, 0, 0)
                local ahx, _, ahz = MathUtil.transform(ex, 0, ez, dirX, 0, dirZ, 0, 1, 0, -1.5, 0, 0)
                typeModifier:setParallelogramWorldCoords(asx, asz, awx, awz, ahx, ahz, DensityCoordType.POINT_POINT_POINT)
                heightModifier:setParallelogramWorldCoords(asx, asz, awx, awz, ahx, ahz, DensityCoordType.POINT_POINT_POINT)
                local _, _, totalNumPixels = typeModifier:executeSetWithStats(typeId)
                local ha = MathUtil.areaToHa(totalNumPixels, g_currentMission:getFruitPixelsToSqm())
                local sqm = MathUtil.haToSqm(ha)
                heightModifier:executeSet((math.ceil(litersPerSqm / sqm)))
                self.spawnedLiters = self.spawnedLiters + litersPerSqm * sqm
                self.currentGrassSegmentIndex = grassSegmentIndex
            end
        end, function()
            -- upvalues: (copy) self
            self.finishedGrassSpawning = true
        end)
        self.initializedGrassSpawning = true
    end
    TedderMission:superClass().update(self, dt)
end
function TedderMission:createModifier()
    local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(FillType.GRASS_WINDROW)
    if heightType ~= nil then
        self.completionModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
        self.completionFilter = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
        self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)
    end
end
function TedderMission:getFieldCompletion()
    TedderMission:superClass().getFieldCompletion(self)
    local sumPixels = 0
    for _, partitionPercentage in ipairs(self.completionPartitions) do
        if not partitionPercentage.wasCalculated then
            return 0
        end
    end
    self.fieldPercentageDone = math.clamp(1 - sumPixels * g_densityMapHeightManager:getMinValidLiterValue(FillType.GRASS_WINDROW) / self.spawnedLiters, 0, 1)
    return self.fieldPercentageDone
end
function TedderMission:getRewardPerHa()
    return g_missionManager:getMissionTypeDataByName(TedderMission.NAME).rewardPerHa
end
function TedderMission:getMissionTypeName()
    return TedderMission.NAME
end
function TedderMission:validate(event)
    if TedderMission:superClass().validate(self, event) then
        return (self:getIsFinished() or TedderMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function TedderMission.loadMapData(xmlFile, key, _)
    g_missionManager:getMissionTypeDataByName(TedderMission.NAME).rewardPerHa = xmlFile:getFloat(key .. "#rewardPerHa", 1500)
    return true
end
function TedderMission.tryGenerateMission()
    if TedderMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not TedderMission.isAvailableForField(field, nil) then
            return
        end
        local mission = TedderMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function TedderMission.isAvailableForField(field, mission)
    if mission == nil then
        local fieldState = field:getFieldState()
        if not fieldState.isValid then
            return false
        end
        local fruitTypeIndex = fieldState.fruitTypeIndex
        if fruitTypeIndex ~= FruitType.GRASS then
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
function TedderMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(TedderMission.NAME)
    return data.numInstances < data.maxNumInstances
end
g_missionManager:registerMissionType(TedderMission, TedderMission.NAME, 2)