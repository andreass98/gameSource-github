FieldManager = {}
FieldManager.FIELDSTATE_PLOWED = 0
FieldManager.FIELDSTATE_CULTIVATED = 1
FieldManager.FIELDSTATE_GROWING = 2
FieldManager.FIELDSTATE_HARVESTED = 3
FieldManager.FIELDEVENT_PLOWED = 1
FieldManager.FIELDEVENT_CULTIVATED = 2
FieldManager.FIELDEVENT_HARVESTED = 3
FieldManager.FIELDEVENT_GROWN = 4
FieldManager.FIELDEVENT_WEEDED = 5
FieldManager.FIELDEVENT_SPRAYED = 6
FieldManager.FIELDEVENT_SOWN = 7
FieldManager.FIELDEVENT_WITHERED = 8
FieldManager.FIELDEVENT_GROWING = 9
FieldManager.FIELDEVENT_FERTILIZED = 10
FieldManager.FIELDEVENT_LIMED = 11
FieldManager.DEBUG_SHOW_FIELDSTATUS = false
FieldManager.DEBUG_SHOW_NPC_ACTIONS = false
FieldManager.NPC_START_TIME = 21600000
FieldManager.NPC_END_TIME = 79200000
local FieldManager_mt = Class(FieldManager, AbstractManager)
g_xmlManager:addCreateSchemaFunction(function()
    FieldManager.xmlSchema = XMLSchema.new("fields")
    FieldManager.xmlSchemaSavegame = XMLSchema.new("fields_savegame")
end)
g_xmlManager:addInitSchemaFunction(function()
    Mission00.xmlSchema:register(XMLValueType.STRING, "map.fields#filename", "Filename of the field preplanted config")
    local schema = FieldManager.xmlSchema
    schema:register(XMLValueType.STRING, "map.fields.field(?)#className")
    FieldUpdateTask.registerXMLPaths(schema, "map.fields.field(?)")
    local schemaSavegame = FieldManager.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "fields.task(?)#className")
    FieldUpdateTask.registerXMLPaths(schemaSavegame, "fields.task(?)")
    Field.registerXMLPaths(schemaSavegame, "fields.field(?)")
    schemaSavegame:register(XMLValueType.INT, "fields.field(?)#id", "Id of the field", nil, true)
end)
function FieldManager.new(customMt)
    -- upvalues: (copy) FieldManager_mt
    return AbstractManager.new(customMt or FieldManager_mt)
end
function FieldManager:initDataStructures()
    self.fields = {}
    self.farmlandIdFieldMapping = {}
    self.currentFieldPartitionIndex = nil
    self.nextCheckTime = 0
    self.nextUpdateTime = 0
    self.nextFieldCheckIndex = 0
    self.updateTasks = {}
    self.fieldNumUpdateTasks = {}
    self.pendingFieldUpdatesMapping = {}
    self.pendingFieldUpdates = {}
    self.fieldStateUpdateIndex = 0
    self.fieldsDoStateUpdate = {}
    self.debugField = nil
end
function FieldManager:loadMapData(xmlFile, _, baseDirectory)
    FieldManager:superClass().loadMapData(self)
    local mission = g_currentMission
    self.mission = mission
    mission:addUpdateable(self)
    local fieldGroundSystem = mission.fieldGroundSystem
    self.groundTypeSown = FieldGroundType.getValueByType(FieldGroundType.SOWN)
    self.sprayTypeFertilizer = FieldSprayType.getValueByType(FieldSprayType.FERTILIZER)
    self.sprayTypeLime = FieldSprayType.getValueByType(FieldSprayType.LIME)
    self.sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
    self.plowLevelMaxValue = Platform.gameplay.usePlowCounter and fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL) or 0
    self.limeLevelMaxValue = Platform.gameplay.useLimeCounter and fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL) or 0
    self.availableFruitTypeIndices = {}
    for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
        if fruitType.useForFieldMissions and fruitType.allowsSeeding then
            table.insert(self.availableFruitTypeIndices, fruitType.index)
        end
    end
    self.fruitTypesCount = #self.availableFruitTypeIndices
    self.fieldIndexToCheck = 1
    local farmlandInfoLayer = g_farmlandManager:getLocalMap()
    local modifier = DensityMapModifier.new(farmlandInfoLayer, 0, g_farmlandManager.numberOfBits, g_terrainNode)
    local filter = DensityMapFilter.new(modifier)
    for i, field in ipairs(self.fields) do
        local field, i
        g_asyncTaskManager:addSubtask(function()
            -- upvalues: (copy) field, (copy) self, (copy) i, (copy) filter, (copy) modifier
            local isValid = true
            local posX, posZ = field:getCenterOfFieldWorldPosition()
            local farmland = g_farmlandManager:getFarmlandAtWorldPosition(posX, posZ)
            if farmland == nil then
                Logging.error("FieldManager - Failed to find farmland in center of field \'%s\' at %d %d", i, posX, posZ)
                isValid = false
            else
                if self.farmlandIdFieldMapping[farmland.id] ~= nil then
                    Logging.error("FieldManager - There already exists field \'%d\' on farmland \'%s\'", i, farmland.id)
                    isValid = false
                end
                filter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, farmland.id)
                modifier:clearPolygonPoints()
                for _, point in ipairs(field:getPolygonPoints()) do
                    local x, _, z = getWorldTranslation(point)
                    modifier:addPolygonPointWorldCoords(x, z)
                end
                local _, numPixels, _ = modifier:executeGet(filter)
                if numPixels > 0 then
                    local _ = #g_farmlandManager:getFarmlands()
                    local _ = 0
                    for _ = _, _ do
                        if _ ~= farmland.id then
                            filter:setValueCompareParams(DensityValueCompareType.EQUAL, _)
                            local z, numPixelsI, _ = modifier:executeGet(filter)
                            if numPixelsI > 0 then
                                Logging.error("FieldManager - Field \'%d\' with center on farmland \'%d\' touches farmland \'%d\' with \'%d\' pixels", i, farmland.id, _, numPixelsI)
                                isValid = false
                            end
                        end
                    end
                end
            end
            if isValid then
                field:setFarmland(farmland)
                farmland:setField(field)
                self.farmlandIdFieldMapping[farmland.id] = field
            end
        end, string.format("FieldManager:loadMapData - Field \'%d\'", i))
    end
    if not mission.missionInfo.isValid and (g_server ~= nil and not Profiler.IS_INITIALIZED) then
        local _ = {}
        local fruitType = getXMLString(xmlFile, "map.fields#filename")
        if fruitType ~= nil then
            local xmlFilename = Utils.getFilename(fruitType, baseDirectory)
            local i = XMLFile.load("fieldsXML", xmlFilename, FieldManager.xmlSchema)
            if i ~= nil then
                for _, fieldKey in i:iterator("map.fields.field") do
                    local fieldKey
                    g_asyncTaskManager:addSubtask(function()
                        -- upvalues: (copy) i, (copy) fieldKey, (copy) self, (copy) _
                        local field = self:getFieldById((i:getValue(fieldKey .. "#fieldId")))
                        if field ~= nil then
                            local className = i:getString(fieldKey .. "#className", "FieldUpdateTask")
                            local class = ClassUtil.getClassObject(className)
                            if class ~= nil then
                                local updateTask = class.new()
                                if updateTask:loadFromXMLFile(i, fieldKey) then
                                    self:addFieldUpdateTask(updateTask)
                                    _[field] = true
                                end
                            end
                        end
                    end)
                end
                g_asyncTaskManager:addSubtask(function()
                    -- upvalues: (copy) i
                    i:delete()
                end)
            end
        end
        for _, field in pairs(self.fields) do
            local field
            g_asyncTaskManager:addSubtask(function()
                -- upvalues: (copy) field, (copy) _, (copy) self, (copy) mission
                if not field:getHasOwner() and (field.isMissionAllowed and _[field] == nil) then
                    local fruitIndex = table.getRandomElement(self.availableFruitTypeIndices)
                    if field.grassMissionOnly then
                        fruitIndex = FruitType.GRASS
                    end
                    local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
                    if fruitTypeDesc == nil then
                        return
                    end
                    local growthState = fruitTypeDesc:getRandomInitialState(g_currentMission.missionInfo.growthMode)
                    local weedState = 0
                    local groundAngle = field:getAngle()
                    local sprayType = FieldSprayType.NONE
                    local sprayLevel = math.random(0, self.sprayLevelMaxValue)
                    local plowLevel = math.random(0, self.plowLevelMaxValue)
                    local limeLevel = math.random(0, self.limeLevelMaxValue)
                    local task
                    if growthState == nil then
                        fruitIndex = nil
                        task = math.random() < 0.5 and FieldGroundType.CULTIVATED or FieldGroundType.PLOWED
                        if task == FieldGroundType.PLOWED then
                            plowLevel = self.plowLevelMaxValue
                        end
                        if sprayLevel > 0 then
                            sprayType = math.random() < 0.7 and FieldSprayType.LIQUID_MANURE or FieldSprayType.MANURE
                        end
                        if limeLevel > 0 and math.random() < 0.1 then
                            sprayType = FieldSprayType.LIME
                        end
                    else
                        if fruitTypeDesc.plantsWeed then
                            if growthState > 4 then
                                weedState = math.random(3, 9)
                            else
                                weedState = math.random(1, 7)
                            end
                        end
                        task = fruitTypeDesc:getGrowthStateGroundType(growthState) or FieldGroundType.SOWN
                    end
                    if not mission.missionInfo.plowingRequiredEnabled then
                        plowLevel = self.plowLevelMaxValue
                    end
                    local task = FieldUpdateTask.new()
                    task:setField(field)
                    task:setFruit(fruitIndex, growthState)
                    task:setWeedState(weedState)
                    task:setStoneLevel(0)
                    task:setGroundType(task)
                    task:setGroundAngle(groundAngle)
                    task:setSprayType(sprayType)
                    task:setSprayLevel(sprayLevel)
                    task:setLimeLevel(limeLevel)
                    task:setPlowLevel(plowLevel)
                    task:clearHeight()
                    self:addFieldUpdateTask(task)
                end
            end)
        end
    end
    g_asyncTaskManager:addSubtask(function()
        -- upvalues: (copy) mission, (copy) self
        if mission:getIsServer() and g_addCheatCommands then
            addConsoleCommand("gsFieldSetState", "Opens UI to set state for specific field(s)", "consoleCommandSetFieldState", self, "[fieldId]; [fruitName]; [growthState]")
            addConsoleCommand("gsFieldSetGround", "Opens UI to set state for specific field(s)", "consoleCommandSetFieldGround", self, "[fieldId]; [groundTypeName]; [angle]; [groundLayer]; [fertilizerState]; [plowingState]; [weedState]; [limeState]; [stubbleState]; [buyField]; [removeFoliage]")
        end
        if g_addCheatCommands then
            addConsoleCommand("gsFieldToggleStatus", "Shows field status", "consoleCommandToggleDebugFieldStatus", self)
            addConsoleCommand("gsFieldToggleNPCLogging", "Toggle field npc action logging", "consoleCommandToggleDebugFieldNPCLogging", self)
        end
    end)
    g_asyncTaskManager:addSubtask(function()
        -- upvalues: (copy) mission, (copy) self
        if not mission:getIsServer() then
            for _, field in pairs(self.fields) do
                local task = FieldUpdateTask.new()
                task:setField(field)
                task:setGroundType(FieldGroundType.CULTIVATED)
                task:setGroundAngle(field:getAngle())
                self:addFieldUpdateTask(task)
            end
        end
        while true do
            local task = table.remove(self.updateTasks, 1)
            if task == nil then
                break
            end
            g_asyncTaskManager:addSubtask(function()
                -- upvalues: (copy) task, (ref) self
                task:start()
                while not task:getIsFinished() do
                    task:update(1)
                end
                self:onFinishFieldUpdateTask(task)
            end)
        end
    end)
    g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.onFinishedGrowthPeriod, self)
    g_messageCenter:subscribe(MessageType.MISSION_GENERATION_START, self.onMissionGenerationStart, self)
    g_messageCenter:subscribe(MessageType.MISSION_GENERATION_END, self.onMissionGenerationEnd, self)
    self.debugBitVectorMap = DebugBitVectorMap.newSimple(5, 0.5, false, 0.1)
    local fruitType = FieldState.new()
    local xmlFilename = Color.new(1, 1, 1, 0.7)
    self.debugBitVectorMap:createWithCustomFunc(function(_, startWorldX, startWorldZ, widthWorldX, _, _, heightWorldZ)
        -- upvalues: (copy) fruitType, (copy) xmlFilename
        local centerX = (startWorldX + widthWorldX) * 0.5
        local centerZ = (startWorldZ + heightWorldZ) * 0.5
        fruitType:update(centerX, centerZ)
        if fruitType.groundType == 0 then
            return 0
        end
        fruitType:drawDebugAtWorldPosition(centerX, getTerrainHeightAtWorldPos(g_terrainNode, centerX, 0, centerZ), centerZ, 0.008, xmlFilename)
        return 1
    end)
    function self.debugBitVectorMap.getShouldBeDrawn()
        return FieldManager.DEBUG_SHOW_FIELDSTATUS
    end
    g_debugManager:addElement(self.debugBitVectorMap)
end
function FieldManager:unloadMapData()
    if self.mission ~= nil then
        self.mission:removeUpdateable(self)
    end
    for _, field in pairs(self.fields) do
        field:delete()
    end
    self.fields = {}
    self.fieldsToCheck = nil
    self.fieldsToUpdate = nil
    self.fieldGroundSystem = nil
    self.mission = nil
    g_messageCenter:unsubscribeAll(self)
    removeConsoleCommand("gsFieldSetState")
    removeConsoleCommand("gsFieldSetGround")
    removeConsoleCommand("gsFieldToggleStatus")
    removeConsoleCommand("gsFieldToggleNPCLogging")
    FieldManager:superClass().unloadMapData(self)
end
function FieldManager:delete() end
function FieldManager:loadFromXMLFile(xmlFilename)
    local xmlFile = XMLFile.load("fields", xmlFilename, FieldManager.xmlSchemaSavegame)
    if xmlFile ~= nil then
        for _, key in xmlFile:iterator("fields.field") do
            local fieldId = xmlFile:getInt(key .. "#id")
            if fieldId ~= nil then
                local field = self:getFieldById(fieldId)
                if field ~= nil then
                    field:loadFromXMLFile(xmlFile, key)
                end
            end
        end
        self.pendingFieldUpdates = {}
        self.pendingFieldUpdatesMapping = {}
        for _, key in xmlFile:iterator("fields.pendingUpdate") do
            local fieldId = xmlFile:getInt(key .. "#fieldId")
            if fieldId ~= nil then
                local field = self:getFieldById(fieldId)
                if field ~= nil then
                    table.insert(self.pendingFieldUpdates, field)
                    self.pendingFieldUpdatesMapping[field] = true
                end
            end
        end
        for _, key in xmlFile:iterator("fields.task") do
            local fieldId = xmlFile:getString(key .. "#className", "FieldUpdateTask")
            local field = ClassUtil.getClassObject(fieldId)
            if field ~= nil then
                local updateTask = field.new()
                if updateTask:loadFromXMLFile(xmlFile, key) then
                    self:addFieldUpdateTask(updateTask)
                end
            end
        end
        xmlFile:delete()
    end
end
function FieldManager:saveToXMLFile(xmlFilename)
    local xmlFile = XMLFile.create("fields", xmlFilename, "fields", FieldManager.xmlSchemaSavegame)
    for k, field in ipairs(self.fields) do
        local key = string.format("fields.field(%d)", k - 1)
        if field:getId() ~= nil then
            xmlFile:setInt(key .. "#id", field:getId())
            field:saveToXMLFile(xmlFile, key)
        end
    end
    if self.pendingFieldUpdates ~= nil then
        for k, field in ipairs(self.pendingFieldUpdates) do
            local key = field:getId()
            if key ~= nil then
                xmlFile:setInt(string.format("fields.pendingUpdate(%d)", k - 1) .. "#fieldId", key)
            end
        end
    end
    for k, field in ipairs(self.updateTasks) do
        local key = field.needsSaving
        if key or key == nil then
            local id = string.format("fields.task(%d)", k - 1)
            xmlFile:setString(id .. "#className", ClassUtil.getClassNameByObject(field))
            field:saveToXMLFile(xmlFile, id)
        end
    end
    xmlFile:save()
    xmlFile:delete()
end
function FieldManager:update(dt)
    if g_server ~= nil then
        if self.pendingFieldUpdates == nil then
            self:setPendingFieldUpdates()
        end
        local pendingField = table.remove(self.pendingFieldUpdates, 1)
        if pendingField ~= nil then
            self.pendingFieldUpdatesMapping[pendingField] = nil
            pendingField:updateState()
            self:updateField(pendingField)
        end
        if self.currentUpdateTask == nil then
            self.currentUpdateTask = table.remove(self.updateTasks, 1)
            if self.currentUpdateTask ~= nil then
                self.currentUpdateTask:start()
            end
        end
        if self.currentUpdateTask ~= nil then
            self.currentUpdateTask:update(dt)
            if self.currentUpdateTask:getIsFinished() then
                self:onFinishFieldUpdateTask(self.currentUpdateTask)
                self.currentUpdateTask = nil
            end
        end
    end
end
function FieldManager:addField(field)
    table.insert(self.fields, field)
    self.fieldNumUpdateTasks[field] = 0
end
function FieldManager:getFieldById(fieldId)
    return self.farmlandIdFieldMapping[fieldId]
end
function FieldManager:getFields()
    return self.fields
end
function FieldManager.logNPCAction(_, msg, ...)
    if FieldManager.DEBUG_SHOW_NPC_ACTIONS then
        Logging.devInfo(msg, ...)
    end
end
function FieldManager:updateField(field)
    if not field:getHasOwner() and field.isMissionAllowed then
        local fieldState = field:getFieldState()
        self:logNPCAction("FieldManager: Update field \'%s\'", field:getName())
        if fieldState.fruitTypeIndex == FruitType.UNKNOWN then
            if field.plannedFruitTypeIndex == FruitType.UNKNOWN then
                field.plannedFruitTypeIndex = self:generatePlannedFruitForField(field)
                self:logNPCAction("FieldManager: Planned fruit for field \'%s\' is now \'%s\'", field:getName(), g_fruitTypeManager:getFruitTypeNameByIndex(field.plannedFruitTypeIndex))
                if fieldState.limeLevel == 0 and math.random() < 0.2 then
                    self:limeField(field)
                    local task = self:cultivateField(field)
                    task:setSprayType(FieldSprayType.LIME)
                    task:setLimeLevel(self.limeLevelMaxValue)
                    return
                end
                if math.random() < 0.2 then
                    local task = self:cultivateField(field)
                    task:setSprayType(math.random() > 0.7 and FieldSprayType.LIQUID_MANURE, FieldSprayType.MANURE)
                    task:setSprayLevel(1)
                    return
                end
            else
                local limeLevel = self:getFruitIndexForField(field)
                if limeLevel ~= nil then
                    self:sowField(field, limeLevel)
                    field.plannedFruitTypeIndex = FruitType.UNKNOWN
                    return
                end
            end
        else
            local limeLevel = g_fruitTypeManager:getFruitTypeByIndex(fieldState.fruitTypeIndex)
            if limeLevel:getIsCatchCrop() then
                if limeLevel:getIsHarvestable(fieldState.growthState) then
                    self:cultivateField(field)
                    return
                end
            elseif limeLevel:getIsWithered(fieldState.growthState) then
                if limeLevel:getIsWithered(fieldState.lastGrowthState) then
                    if math.random() < 0.5 then
                        self:cultivateField(field)
                    else
                        self:plowField(field)
                    end
                end
                if math.random() < 0.3 then
                    self:harvestField(field)
                    return
                end
            elseif limeLevel:getIsHarvestable(fieldState.growthState) then
                if (limeLevel:getIsHarvestable(fieldState.lastGrowthState) and 0.2 or 0.05) > math.random() then
                    self:harvestField(field)
                    return
                end
            elseif limeLevel:getIsCut(fieldState.growthState) then
                if (limeLevel:getIsCut(fieldState.lastGrowthState) and 0.4 or 0.05) > math.random() then
                    if math.random() < 0.75 then
                        self:cultivateField(field)
                    else
                        self:plowField(field)
                    end
                end
            elseif limeLevel:getIsGrowing(fieldState.growthState) then
                if fieldState.sprayLevel < self.sprayLevelMaxValue and math.random() < 0.3 then
                    self:fertilizeField(field)
                    return
                end
                if fieldState.weedState > 1 and math.random() < 0.2 then
                    if limeLevel:getIsWeedable(fieldState.growthState) then
                        self:weedField(field, false)
                        return
                    end
                    if limeLevel:getIsHoeable(fieldState.growthState) then
                        self:weedField(field, true)
                        return
                    end
                    self:herbicideField(field)
                end
            end
        end
    end
end
function FieldManager:weedField(field, isHoe)
    local fieldState = field:getFieldState()
    local newWeedState = g_currentMission.weedSystem:getWeederReplacements(isHoe).weed.replacements[fieldState.weedState] or 0
    local task = FieldUpdateTask.new()
    task:setField(field)
    task:setWeedState(newWeedState)
    self:addFieldUpdateTask(task)
    self:logNPCAction("FieldManager: Weed field \'%s\' (Hoe: \'%s\')", field:getName(), isHoe)
    return task
end
function FieldManager:herbicideField(field)
    local fieldState = field:getFieldState()
    local weedState = g_currentMission.weedSystem:getHerbicideReplacements().weed.replacements[fieldState.weedState] or 0
    local task = FieldUpdateTask.new()
    task:setField(field)
    task:setWeedState(weedState)
    self:addFieldUpdateTask(task)
    self:logNPCAction("FieldManager: Herbicide field \'%s\'", field:getName())
    return task
end
function FieldManager:plowField(field)
    local task = FieldUpdateTask.new()
    task:setField(field)
    task:setFruit(FruitType.UNKNOWN, 0)
    task:setWeedState(0)
    task:setStoneLevel(0)
    task:setGroundAngle(field:getAngle())
    task:setGroundType(FieldGroundType.PLOWED)
    task:setSprayType(FieldGroundType.NONE)
    task:setPlowLevel(self.plowLevelMaxValue)
    task:clearHeight()
    self:logNPCAction("FieldManager: Plow field \'%s\'", field:getName())
    self:addFieldUpdateTask(task)
    return task
end
function FieldManager:cultivateField(field)
    local task = FieldUpdateTask.new()
    task:setField(field)
    task:setFruit(FruitType.UNKNOWN, 0)
    task:setWeedState(0)
    task:setStoneLevel(0)
    task:setGroundAngle(field:getAngle())
    task:setGroundType(FieldGroundType.CULTIVATED)
    task:setSprayType(FieldGroundType.NONE)
    task:clearHeight()
    self:logNPCAction("FieldManager: Cultivate field \'%s\'", field:getName())
    self:addFieldUpdateTask(task)
    return task
end
function FieldManager:harvestField(field)
    local fieldState = field:getFieldState()
    local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fieldState.fruitTypeIndex)
    local task = FieldUpdateTask.new()
    task:setField(field)
    task:setFruit(fieldState.fruitTypeIndex, fruitTypeDesc.cutState)
    task:setWeedState(0)
    task:setGroundAngle(field:getAngle())
    task:setSprayType(FieldSprayType.NONE)
    task:clearHeight()
    if fruitTypeDesc.consumesLime then
        local limeLevel = math.max(fieldState.limeLevel - 1, 0)
        if limeLevel ~= fieldState.limeLevel then
            task:setLimeLevel(limeLevel)
        end
    end
    if fruitTypeDesc.increasesSoilDensity then
        local limeLevel = math.max(fieldState.plowLevel - 1, 0)
        if limeLevel ~= fieldState.plowLevel then
            task:setPlowLevel(limeLevel)
        end
    end
    self:logNPCAction("FieldManager: Harvest field \'%s\'", field:getName())
    self:addFieldUpdateTask(task)
    return task
end
function FieldManager:sowField(field, fruitTypeIndex)
    local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
    local task = FieldUpdateTask.new()
    task:setField(field)
    task:setFruit(fruitTypeIndex, 1)
    task:setGroundAngle(field:getAngle())
    task:setGroundType(fruitTypeDesc:getDefaultSowingGroundType())
    task:setSprayType(FieldSprayType.NONE)
    task:setStoneLevel(0)
    task:setWeedState(fruitTypeDesc.plantsWeed and 1 or 0)
    task:clearHeight()
    local name = g_fruitTypeManager:getFruitTypeNameByIndex(fruitTypeIndex)
    self:logNPCAction("FieldManager: Sow field \'%s\' with \'%s\'", field:getName(), name)
    self:addFieldUpdateTask(task)
    return task
end
function FieldManager:fertilizeField(field)
    local task = field:getFieldState().sprayLevel + 1
    local newSprayLevel = math.max(task, self.sprayLevelMaxValue)
    local task = FieldUpdateTask.new()
    task:setField(field)
    task:setSprayType(FieldSprayType.FERTILIZER)
    task:setSprayLevel(newSprayLevel)
    self:logNPCAction("FieldManager: Fertilize field \'%s\'", field:getName())
    self:addFieldUpdateTask(task)
    return task
end
function FieldManager:limeField(field)
    local task = FieldUpdateTask.new()
    task:setField(field)
    task:setFruit(FruitType.UNKNOWN, 0)
    task:setWeedState(0)
    task:setStoneLevel(0)
    task:setGroundAngle(field:getAngle())
    task:setGroundType(FieldGroundType.CULTIVATED)
    task:setLimeLevel(self.limeLevelMaxValue)
    task:setSprayType(FieldSprayType.LIME)
    task:clearHeight()
    self:logNPCAction("FieldManager: Lime field \'%s\'", field:getName())
    self:addFieldUpdateTask(task)
    return task
end
function FieldManager:addFieldUpdateTask(updateTask, immediate)
    if immediate then
        updateTask:start(true)
        updateTask:update(1)
        self:onFinishFieldUpdateTask(updateTask)
        return
    elseif g_server == nil and self.mission.isLoaded then
        Logging.error("Trying to add non-immediate field update task on client")
        printCallstack()
    else
        table.insert(self.updateTasks, updateTask)
        if updateTask.getField ~= nil then
            local field = updateTask:getField()
            if field ~= nil then
                self.fieldNumUpdateTasks[field] = self.fieldNumUpdateTasks[field] + 1
            end
        end
    end
end
function FieldManager:onFinishFieldUpdateTask(updateTask)
    if updateTask.getField ~= nil then
        local field = updateTask:getField()
        if field ~= nil then
            self.fieldNumUpdateTasks[field] = math.max(self.fieldNumUpdateTasks[field] - 1, 0)
            field:updateState()
        end
    end
end
function FieldManager:setPendingFieldUpdates()
    table.clear(self.pendingFieldUpdates)
    table.clear(self.pendingFieldUpdatesMapping)
    for _, field in ipairs(self.fields) do
        if not field:getHasOwner() then
            local mission = field.currentMission
            local needUpdate = true
            if mission ~= nil then
                needUpdate = not mission:getWasStarted()
            end
            if needUpdate then
                table.insert(self.pendingFieldUpdates, field)
                self.pendingFieldUpdatesMapping[field] = true
                local i = #self.updateTasks
                for i = i, 1, -1 do
                    local task = self.updateTasks[i]
                    if task:getField() == field then
                        table.remove(self.updateTasks, i)
                        self:onFinishFieldUpdateTask(task)
                        Logging.devInfo("FieldManager: Remove pending update task \'%s\' for field \'%d\'", tostring(task), field:getId())
                    end
                end
            end
        end
    end
    Utils.shuffle(self.pendingFieldUpdates)
    self.currentUpdateTask = nil
end
function FieldManager:getFieldForMission()
    return self.debugField or self.currentMissionField
end
function FieldManager:onFieldMissionStarted()
    self.currentMissionField = self:generateFieldForMission()
end
function FieldManager:onFieldMissionDeleted() end
function FieldManager:generateFieldForMission()
    if g_currentMission.growthSystem:getIsGrowingInProgress() then
        return nil
    end
    local numFields = #self.fields
    if numFields > 0 then
        local start = math.random(1, numFields)
        for start = start, numFields do
            local fieldIndex
            if numFields < start then
                fieldIndex = start - numFields
            else
                fieldIndex = start
            end
            local field = self.fields[fieldIndex]
            if self:getIsFieldReadyForMission(field) then
                return field
            end
        end
    end
    return nil
end
function FieldManager:getIsFieldReadyForMission(field)
    if self.pendingFieldUpdatesMapping[field] == nil then
        if self.fieldNumUpdateTasks[field] > 0 then
            return false
        else
            return field:getIsReadyForMission() and true or false
        end
    else
        return false
    end
end
function FieldManager:generatePlannedFruitForField(field)
    if field.grassMissionOnly then
        return FruitType.GRASS
    else
        return self.availableFruitTypeIndices[math.random(1, self.fruitTypesCount)]
    end
end
function FieldManager.getFruitIndexForField(_, field)
    local fruitTypeIndex = field.plannedFruitTypeIndex
    if fruitTypeIndex == nil or fruitTypeIndex == FruitType.UNKNOWN then
        return nil
    elseif g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex):getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod) then
        return fruitTypeIndex
    else
        return nil
    end
end
function FieldManager:onFinishedGrowthPeriod(_, hasPendingGrowth)
    if not hasPendingGrowth then
        self:setPendingFieldUpdates()
    end
end
function FieldManager:onMissionGenerationStart()
    self.currentMissionField = self:generateFieldForMission()
end
function FieldManager:onMissionGenerationEnd()
    self.currentMissionField = nil
end
function FieldManager.getFieldIdAtPlayerPosition()
    local x, _, z = g_localPlayer:getPosition()
    if x == nil then
        return nil
    else
        local farmland = g_farmlandManager:getFarmlandAtWorldPosition(x, z)
        if farmland == nil then
            return nil
        else
            return farmland:getId()
        end
    end
end
function FieldManager.consoleCommandSetFieldState(_, fieldId, fruitName, growthState)
    if fieldId == nil or fieldId == "nil" then
        fieldId = tostring(FieldManager.getFieldIdAtPlayerPosition())
    end
    growthState = tonumber(growthState)
    FieldStateDialog.show(fieldId, fruitName, growthState)
end
function FieldManager.consoleCommandSetFieldGround(_, fieldId, groundTypeName, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, stubbleState, buyField, removeFoliage)
    if fieldId == nil or fieldId == "nil" then
        fieldId = tostring(FieldManager.getFieldIdAtPlayerPosition())
    end
    local numAngles = Utils.parseConsoleParameter(groundTypeName)
    local numAngles = tonumber(angle)
    if numAngles ~= nil and numAngles ~= 0 then
        local numAngles = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.GROUND_ANGLE) + 1
        if numAngles < numAngles then
            numAngles = numAngles * math.deg(3.141592653589793 / numAngles)
        end
    end
    local numAngles = Utils.parseConsoleParameter(groundLayer)
    if tonumber(numAngles) ~= nil then
        local numAngles = tonumber(numAngles)
        numAngles = FieldSprayType.getName(numAngles + 1)
    end
    local numAngles = tonumber(fertilizerState)
    local numAngles = tonumber(plowingState)
    local numAngles = tonumber(weedState)
    local numAngles = tonumber(limeState)
    local numAngles = tonumber(stubbleState)
    local numAngles = Utils.stringToBoolean(buyField)
    local numAngles = Utils.stringToBoolean(removeFoliage)
    FieldStateDialog.show(fieldId, nil, nil, numAngles, numAngles, numAngles, numAngles, numAngles, numAngles, numAngles, numAngles, numAngles, numAngles)
end
function FieldManager:consoleCommandToggleDebugFieldStatus(size)
    FieldManager.DEBUG_SHOW_FIELDSTATUS = not FieldManager.DEBUG_SHOW_FIELDSTATUS
    return "ToggleFieldStatus: " .. tostring(FieldManager.DEBUG_SHOW_FIELDSTATUS)
end
function FieldManager:consoleCommandToggleDebugFieldNPCLogging(size)
    FieldManager.DEBUG_SHOW_NPC_ACTIONS = not FieldManager.DEBUG_SHOW_NPC_ACTIONS
    return "ToggleFieldNPCLogging: " .. tostring(FieldManager.DEBUG_SHOW_NPC_ACTIONS)
end
g_fieldManager = FieldManager.new()