BaleWrapMission = {}
BaleWrapMission.NAME = "baleWrapMission"
local BaleWrapMission_mt = Class(BaleWrapMission, AbstractFieldMission)
InitStaticObjectClass(BaleWrapMission, "BaleWrapMission")
function BaleWrapMission.registerXMLPaths(schema, key)
    BaleWrapMission:superClass().registerXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#rewardPerBale", "Reward per bale")
end
function BaleWrapMission.registerSavegameXMLPaths(schema, key)
    BaleWrapMission:superClass().registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.INT, key .. "#baleTypeIndex", "Bale type")
    schema:register(XMLValueType.INT, key .. "#numOfBales", "Bale count")
    schema:register(XMLValueType.STRING, key .. ".bale(?)#uniqueId", "Spawned bale")
end
function BaleWrapMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) BaleWrapMission_mt
    local title = g_i18n:getText("contract_field_baleWrap_title")
    local description = g_i18n:getText("contract_field_baleWrap_description")
    local self = AbstractFieldMission.new(isServer, isClient, title, description, customMt or BaleWrapMission_mt)
    self.bales = {}
    self.balesToLoadByUniqueId = nil
    return self
end
function BaleWrapMission:init(field, baleTypeIndex, numOfBales)
    self.baleTypeIndex = baleTypeIndex
    self.numOfBales = numOfBales
    return BaleWrapMission:superClass().init(self, field)
end
function BaleWrapMission:setField(field)
    BaleWrapMission:superClass().setField(self, field)
    local fieldId = field:getId()
    if fieldId ~= nil then
        local baleType
        if g_baleManager:getIsRoundBale(self.baleTypeIndex) then
            baleType = g_i18n:getText("fillType_roundBale")
        else
            baleType = g_i18n:getText("fillType_squareBale")
        end
        self.progressTitle = string.format("%s (%s %d) - %s", self.title, g_i18n:getText("contract_details_field"), fieldId, baleType)
    end
end
function BaleWrapMission:writeStream(streamId, connection)
    BaleWrapMission:superClass().writeStream(self, streamId, connection)
    streamWriteUIntN(streamId, self.baleTypeIndex, BaleManager.SEND_NUM_BITS)
    streamWriteUInt16(streamId, self.numOfBales)
end
function BaleWrapMission:readStream(streamId, connection)
    BaleWrapMission:superClass().readStream(self, streamId, connection)
    self.baleTypeIndex = streamReadUIntN(streamId, BaleManager.SEND_NUM_BITS)
    self.numOfBales = streamReadUInt16(streamId)
end
function BaleWrapMission:saveToXMLFile(xmlFile, key)
    BaleWrapMission:superClass().saveToXMLFile(self, xmlFile, key)
    for i, bale in ipairs(self.bales) do
        xmlFile:setValue(string.format("%s.bale(%d)", key, i - 1) .. "#uniqueId", bale:getUniqueId())
    end
    xmlFile:setValue(key .. "#baleTypeIndex", self.baleTypeIndex)
    xmlFile:setValue(key .. "#numOfBales", self.numOfBales)
end
function BaleWrapMission:loadFromXMLFile(xmlFile, key)
    for _, baleKey in xmlFile:iterator(key .. ".bale") do
        local baleUniqueId = xmlFile:getValue(baleKey .. "#uniqueId")
        if self.balesToLoadByUniqueId == nil then
            self.balesToLoadByUniqueId = {}
        end
        table.insert(self.balesToLoadByUniqueId, baleUniqueId)
    end
    self.baleTypeIndex = xmlFile:getValue(key .. "#baleTypeIndex")
    if self.baleTypeIndex == nil then
        return false
    end
    self.numOfBales = xmlFile:getValue(key .. "#numOfBales")
    if self.numOfBales == nil then
        return false
    end
    self.finishedBaleSpawning = true
    return BaleWrapMission:superClass().loadFromXMLFile(self, xmlFile, key)
end
function BaleWrapMission:prepareField()
    BaleWrapMission:superClass().prepareField(self)
    if self.isServer then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)
        local litersToDrop = MathUtil.haToSqm(self.field:getAreaHa()) * (fruitTypeDesc.windrowLiterPerSqm or fruitTypeDesc.literPerSqm)
        local x, z = self.field:getCenterOfFieldWorldPosition()
        local fieldCourseSettings = FieldCourseSettings.new()
        fieldCourseSettings.implementWidth = 8
        fieldCourseSettings.numHeadlands = 2
        local baleFillTypeIndex = fruitTypeDesc.windrowFillType.index
        local baleXMLFilename = g_baleManager:getBaleXMLFilenameByIndex(self.baleTypeIndex)
        local baleCapacity = g_baleManager:getBaleCapacityByBaleIndex(self.baleTypeIndex, baleFillTypeIndex)
        local baleDesc = g_baleManager:getBaleDescByIndex(self.baleTypeIndex)
        local isRoundBale = g_baleManager:getIsRoundBale(self.baleTypeIndex)
        local nextBaleLiters = baleCapacity
        local function spawnBale(sx, sz, ex, ez, length, percentageFromStart)
            -- upvalues: (copy) baleDesc, (copy) isRoundBale, (copy) self, (copy) baleXMLFilename, (copy) baleFillTypeIndex, (copy) baleCapacity
            local spawnDistanceFromStart = length * percentageFromStart
            local dirX, dirZ = MathUtil.vector2Normalize(ex - sx, ez - sz)
            local spawnPosX = sx + dirX * spawnDistanceFromStart
            local spawnPosZ = sz + dirZ * spawnDistanceFromStart
            local rotY = MathUtil.getYRotationFromDirection(dirX, dirZ) + 1.5707963267948966
            local height = baleDesc.diameter
            if not isRoundBale then
                height = baleDesc.height
            end
            local spawnPosY = getTerrainHeightAtWorldPos(g_terrainNode, spawnPosX, 0, spawnPosZ) + height * 0.5
            local baleObject = Bale.new(self.isServer, self.isClient)
            if baleObject:loadFromConfigXML(baleXMLFilename, spawnPosX, spawnPosY, spawnPosZ, 0, rotY, 0) then
                baleObject:setFillType(baleFillTypeIndex)
                baleObject:setFillLevel(baleCapacity)
                baleObject:setOwnerFarmId(self.field:getOwner(), true)
                baleObject:register()
                table.insert(self.bales, baleObject)
            end
        end
        local segmentLiters = 0
        local lastSx = nil
        local lastSz = nil
        local lastEx = nil
        local lastEz = nil
        local lastLength = nil
        FieldCourseIterator.new(x, z, fieldCourseSettings, function(sx, sz, ex, ez, _, _, _, totalCourseLength)
            -- upvalues: (copy) litersToDrop, (ref) segmentLiters, (ref) lastSx, (ref) lastSz, (ref) lastEx, (ref) lastEz, (ref) lastLength, (ref) nextBaleLiters, (copy) baleCapacity, (copy) spawnBale
            local length = MathUtil.vector2Length(ex - sx, ez - sz)
            local totalSegmentLiters = length * (litersToDrop / totalCourseLength)
            segmentLiters = totalSegmentLiters
            lastSx = sx
            lastSz = sz
            lastEx = ex
            lastEz = ez
            lastLength = length
            while segmentLiters > 0 do
                if segmentLiters <= nextBaleLiters then
                    segmentLiters = 0
                else
                    segmentLiters = math.abs(nextBaleLiters - segmentLiters)
                    spawnBale(sx, sz, ex, ez, length, 1 - segmentLiters / totalSegmentLiters)
                end
            end
        end, function()
            -- upvalues: (ref) segmentLiters, (copy) spawnBale, (ref) lastSx, (ref) lastSz, (ref) lastEx, (ref) lastEz, (ref) lastLength, (copy) self
            if segmentLiters > 0 then
                spawnBale(lastSx, lastSz, lastEx, lastEz, lastLength, 1)
            end
            self.finishedBaleSpawning = true
        end)
    end
end
function BaleWrapMission:getFieldPreparingTask()
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
function BaleWrapMission:getIsPrepared()
    if BaleWrapMission:superClass().getIsPrepared(self) then
        return self.finishedBaleSpawning
    else
        return false
    end
end
function BaleWrapMission:finishField()
    if self.isServer then
        for _, bale in ipairs(self.bales) do
            bale:delete()
        end
        self.bales = {}
    end
    BaleWrapMission:superClass().finishField(self)
end
function BaleWrapMission:update(dt)
    if self.isServer and self.balesToLoadByUniqueId ~= nil then
        for _, baleUniqueId in ipairs(self.balesToLoadByUniqueId) do
            local bale = g_currentMission.itemSystem:getItemByUniqueId(baleUniqueId)
            if bale ~= nil then
                table.insert(self.bales, bale)
            end
        end
        self.balesToLoadByUniqueId = nil
        local numLoadedBales = #self.bales
        if numLoadedBales ~= self.numOfBales then
            Logging.error("Could not load all bales from savegame")
            self.numOfBales = numLoadedBales
        end
    end
    BaleWrapMission:superClass().update(self, dt)
end
function BaleWrapMission:getCompletion()
    local wrapStateSum = 0
    local completion = 0
    local allDropped = true
    for _, bale in ipairs(self.bales) do
        if bale:getIsMounted() then
            allDropped = false
        end
    end
    if self.balesToLoadByUniqueId == nil then
        local totalBaleWrapState = 1
        local numBales = #self.bales
        if numBales > 0 then
            totalBaleWrapState = wrapStateSum / numBales
        end
        completion = totalBaleWrapState * 0.99
        if totalBaleWrapState == 1 and allDropped then
        end
    end
    return completion
end
function BaleWrapMission:getRewardPerHa()
    return 1
end
function BaleWrapMission:getReward()
    local data = g_missionManager:getMissionTypeDataByName(BaleWrapMission.NAME)
    return BaleWrapMission:superClass().getReward(self) + data.rewardPerBale * self.numOfBales * (1.3 - 0.1 * g_currentMission.missionInfo.economicDifficulty)
end
function BaleWrapMission:getDetails()
    local details = BaleWrapMission:superClass().getDetails(self)
    local baleType
    if g_baleManager:getIsRoundBale(self.baleTypeIndex) then
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
function BaleWrapMission:getVehicleVariant()
    return g_baleManager:getIsRoundBale(self.baleTypeIndex) and "ROUNDBALE" or "SQUAREBALE"
end
function BaleWrapMission:getVariant()
    return g_baleManager:getIsRoundBale(self.baleTypeIndex) and "ROUNDBALER" or "SQUAREBALER"
end
function BaleWrapMission:getMissionTypeName()
    return BaleWrapMission.NAME
end
function BaleWrapMission:validate(event)
    if BaleWrapMission:superClass().validate(self, event) then
        return (self:getIsFinished() or BaleWrapMission.isAvailableForField(self.field, self)) and true or false
    else
        return false
    end
end
function BaleWrapMission.loadMapData(xmlFile, key, _)
    g_missionManager:getMissionTypeDataByName(BaleWrapMission.NAME).rewardPerBale = xmlFile:getFloat(key .. "#rewardPerBale", 300)
    return true
end
function BaleWrapMission.tryGenerateMission()
    if BaleWrapMission.canRun() then
        local field = g_fieldManager:getFieldForMission()
        if field == nil then
            return
        end
        if field.currentMission ~= nil then
            return
        end
        if not BaleWrapMission.isAvailableForField(field, nil) then
            return
        end
        local spawnRoundbales = math.random() > 0.5
        local fruitTypeDesc
        if spawnRoundbales then
            fruitTypeDesc = g_baleManager:getBaleIndex(FillType.GRASS_WINDROW, true, 1.2, 0, 0, 1.5, "")
        else
            fruitTypeDesc = g_baleManager:getBaleIndex(FillType.GRASS_WINDROW, false, 1.2, 0.9, 1.8, 0, "")
        end
        if fruitTypeDesc == nil then
            return
        end
        local litersPerSqm = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS).literPerSqm
        local fieldSizeSqm = MathUtil.haToSqm(field:getAreaHa())
        local baleCapacity = g_baleManager:getBaleCapacityByBaleIndex(fruitTypeDesc, FillType.GRASS_WINDROW)
        local mission = fieldSizeSqm * litersPerSqm / baleCapacity
        local numOfBales = math.floor(mission)
        if numOfBales == 0 then
            return
        end
        local mission = BaleWrapMission.new
        local mission = mission(true, g_client ~= nil)
        if mission:init(field, fruitTypeDesc, numOfBales) then
            mission:setDefaultEndDate()
            return mission
        end
        mission:delete()
    end
    return nil
end
function BaleWrapMission.isAvailableForField(field, mission)
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
    return fieldState == nil or fieldState.currentSeason ~= Season.WINTER
end
function BaleWrapMission.canRun()
    local data = g_missionManager:getMissionTypeDataByName(BaleWrapMission.NAME)
    return data.numInstances < data.maxNumInstances
end
g_missionManager:registerMissionType(BaleWrapMission, BaleWrapMission.NAME, 2)