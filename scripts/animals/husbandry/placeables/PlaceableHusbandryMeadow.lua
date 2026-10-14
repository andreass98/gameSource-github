PlaceableHusbandryMeadow = {}
PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS = 22
source("dataS/scripts/animals/husbandry/placeables/events/HusbandryMeadowCreateEvent.lua")
source("dataS/scripts/animals/husbandry/placeables/MeadowCreationTask.lua")
function PlaceableHusbandryMeadow.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandryFood, specializations) and SpecializationUtil.hasSpecialization(PlaceableHusbandryFence, specializations) and SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
end
function PlaceableHusbandryMeadow.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "startMeadowGrowthUpdate", PlaceableHusbandryMeadow.startMeadowGrowthUpdate)
    SpecializationUtil.registerFunction(placeableType, "finishMeadowGrowthUpdate", PlaceableHusbandryMeadow.finishMeadowGrowthUpdate)
    SpecializationUtil.registerFunction(placeableType, "getMeadowVisualFillLevels", PlaceableHusbandryMeadow.getMeadowVisualFillLevels)
    SpecializationUtil.registerFunction(placeableType, "createMeadow", PlaceableHusbandryMeadow.createMeadow)
    SpecializationUtil.registerFunction(placeableType, "getCanCreateMeadow", PlaceableHusbandryMeadow.getCanCreateMeadow)
    SpecializationUtil.registerFunction(placeableType, "finishedMeadow", PlaceableHusbandryMeadow.finishedMeadow)
    SpecializationUtil.registerFunction(placeableType, "updateMeadowVisuals", PlaceableHusbandryMeadow.updateMeadowVisuals)
    SpecializationUtil.registerFunction(placeableType, "updateMeadowInfo", PlaceableHusbandryMeadow.updateMeadowInfo)
end
function PlaceableHusbandryMeadow.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryMeadow.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getFoodInfos", PlaceableHusbandryMeadow.getFoodInfos)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getAvailableFood", PlaceableHusbandryMeadow.getAvailableFood)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "removeFood", PlaceableHusbandryMeadow.removeFood)
end
function PlaceableHusbandryMeadow.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onFinishedFeeding", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsCreated", PlaceableHusbandryMeadow)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryFenceCustomizingUserLeft", PlaceableHusbandryMeadow)
end
function PlaceableHusbandryMeadow.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    basePath = basePath .. ".husbandry.meadow"
    schema:register(XMLValueType.STRING, basePath .. ".fruitType(?)#name", "Name of the supported fruitType")
    schema:register(XMLValueType.STRING, basePath .. ".fruitType(?)#eatableStartGrowthState", "Fruit type eatable start growth state name")
    schema:register(XMLValueType.STRING, basePath .. ".fruitType(?)#eatableEndGrowthState", "Fruit type eatable end growth state name")
    schema:register(XMLValueType.STRING, basePath .. ".fruitType(?)#eatenGrowthState", "Fruit type eaten growth state name")
    MeadowCreationTask.registerXMLPaths(schema, basePath .. ".createTask")
    MeadowCreationTask.registerXMLPaths(schema, basePath .. ".clearTask")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".clearTask.polygon.node(?)#node", "Polygon node", nil, false)
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryMeadow.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    MeadowCreationTask.registerXMLPaths(schema, basePath .. ".createTask")
    MeadowCreationTask.registerXMLPaths(schema, basePath .. ".clearTask")
    schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Meadow filltype name")
    schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#fillLevel", "Meadow fillevel")
    schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#capacity", "Meadow capacity")
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryMeadow:onLoad(_)
    local spec = self.spec_husbandryMeadow
    spec.canCreateMeadow = false
    spec.foodInfo = {
        ["title"] = "",
        ["value"] = 0,
        ["capacity"] = 0,
        ["ratio"] = 0,
        ["ignoreCapacity"] = true
    }
    spec.info = {
        ["title"] = g_i18n:getText("animals_husbandryMeadowFood"),
        ["value"] = 0,
        ["capacity"] = 0,
        ["ratio"] = 0
    }
    spec.fillLevels = {}
    spec.dirtyFillLevels = {}
    spec.capacities = {}
    spec.productionWeight = 0
    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.fruitTypeInfos = {}
    spec.fruitTypeEatFilters = {}
    spec.eatFilterMaxValue = 10000
    for _, fruitTypeKey in self.xmlFile:iterator("placeable.husbandry.meadow.fruitType") do
        local name = self.xmlFile:getValue(fruitTypeKey .. "#name")
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(name)
        if fruitTypeDesc ~= nil then
            local windrowFillTypeIndex = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitTypeDesc.index)
            spec.fillLevels[windrowFillTypeIndex] = 0
            spec.capacities[windrowFillTypeIndex] = 0
            local eatableStartGrowthStateName = self.xmlFile:getValue(fruitTypeKey .. "#eatableStartGrowthState")
            if eatableStartGrowthStateName == nil then
                Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableStartGrowthState missing!")
            else
                local eatableStartGrowthState = fruitTypeDesc:getGrowthStateByName(eatableStartGrowthStateName)
                if eatableStartGrowthState == nil then
                    Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableStartGrowthState \'%s\' not defined!", eatableStartGrowthStateName)
                else
                    local eatableEndGrowthStateName = self.xmlFile:getValue(fruitTypeKey .. "#eatableEndGrowthState")
                    if eatableEndGrowthStateName == nil then
                        Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableEndGrowthState missing!")
                    else
                        local eatableEndGrowthState = fruitTypeDesc:getGrowthStateByName(eatableEndGrowthStateName)
                        if eatableEndGrowthState == nil then
                            Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatableEndGrowthState \'%s\' not defined!", eatableEndGrowthStateName)
                        else
                            local eatenGrowthStateName = self.xmlFile:getValue(fruitTypeKey .. "#eatenGrowthState")
                            if eatenGrowthStateName == nil then
                                Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatenGrowthState missing!")
                            else
                                local eatenGrowthState = fruitTypeDesc:getGrowthStateByName(eatenGrowthStateName)
                                if eatenGrowthState == nil then
                                    Logging.xmlWarning(self.xmlFile, "Husbandry meadow fruit type eatenGrowthState \'%s\' not defined!", eatenGrowthStateName)
                                else
                                    table.insert(spec.fruitTypeInfos, {
                                        ["fruitType"] = fruitTypeDesc,
                                        ["eatableStartGrowthState"] = eatableStartGrowthState,
                                        ["eatableEndGrowthState"] = eatableEndGrowthState,
                                        ["eatenGrowthState"] = eatenGrowthState,
                                        ["fillTypeIndex"] = windrowFillTypeIndex
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if self.xmlFile:hasProperty("placeable.husbandry.meadow.createTask") then
        local createTask = MeadowCreationTask.new()
        if createTask:loadFromXMLFile(self.xmlFile, "placeable.husbandry.meadow.createTask") then
            createTask:setName("HusbandryMeadowCreate")
            createTask:setNeedsSaving(false)
            spec.createTask = createTask
        end
        spec.canCreateMeadow = true
    end
    if self.xmlFile:hasProperty("placeable.husbandry.meadow.clearTask") then
        local createTask = {}
        for fruitTypeKey, name in self.xmlFile:iterator("placeable.husbandry.meadow.clearTask.polygon.node") do
            local fruitTypeDesc = self.xmlFile:getValue(name .. "#node", nil, self.components, self.i3dMappings)
            if fruitTypeDesc ~= nil then
                table.insert(createTask, fruitTypeDesc)
            end
        end
        local area = DensityMapPolygon.createFromNodes(createTask)
        if area ~= nil then
            local clearTask = MeadowCreationTask.new()
            clearTask:setArea(area)
            if clearTask:loadFromXMLFile(self.xmlFile, "placeable.husbandry.meadow.clearTask") then
                clearTask:setName("HusbandryMeadowClear")
                clearTask:setNeedsSaving(false)
                spec.clearTask = clearTask
                spec.canCreateMeadow = true
            end
        end
    end
end
function PlaceableHusbandryMeadow:onPostLoad()
    local productionWeight = nil
    local animalTypeIndex = self:getAnimalTypeIndex()
    local animalType = g_currentMission.animalSystem:getTypeByIndex(animalTypeIndex)
    local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(animalTypeIndex)
    if animalFood ~= nil then
        local i = #self.spec_husbandryMeadow.fruitTypeInfos
        for i = i, 1, -1 do
            local found = false
            for _, foodGroup in pairs(animalFood.groups) do
                for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
                    if fillTypeIndex == spec.fruitTypeInfos[i].fillTypeIndex then
                        if productionWeight == nil then
                            productionWeight = foodGroup.productionWeight
                        end
                        productionWeight = math.min(productionWeight, foodGroup.productionWeight)
                        found = true
                    end
                end
                if found then
                    break
                end
            end
            if not found then
                Logging.devWarning("FruitType \'%s\' is not supported by animal type \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(fruitTypeInfo.fillTypeIndex), animalType.groupTitle)
                table.remove(spec.fruitTypes, i)
            end
        end
    end
    if productionWeight ~= nil and productionWeight > 0 then
        spec.productionWeight = productionWeight
        spec.foodInfo.title = string.format("%s (%d%%)", g_i18n:getText("animals_husbandryMeadowFood"), MathUtil.round(spec.productionWeight * 100))
    end
end
function PlaceableHusbandryMeadow:onDelete()
    local spec = self.spec_husbandryMeadow
    if spec.pendingCreateTask ~= nil then
        spec.pendingCreateTask:cancel()
    end
    if spec.pendingClearTask ~= nil then
        spec.pendingClearTask:cancel()
    end
    g_messageCenter:unsubscribe(MessageType.START_GROWTH_PERIOD, self)
    g_messageCenter:unsubscribe(MessageType.FINISHED_GROWTH_PERIOD, self)
end
function PlaceableHusbandryMeadow:onReadStream(streamId, _)
    local spec = self.spec_husbandryMeadow
    for fillTypeIndex, filLLevel in pairs(spec.fillLevels) do
        spec.fillLevels[fillTypeIndex] = streamReadUIntN(streamId, PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS)
        spec.capacities[fillTypeIndex] = streamReadUIntN(streamId, numBits)
    end
    self:updateMeadowInfo()
end
function PlaceableHusbandryMeadow:onWriteStream(streamId, _)
    local spec = self.spec_husbandryMeadow
    for fillTypeIndex, fillLevel in pairs(spec.fillLevels) do
        streamWriteUIntN(streamId, fillLevel, PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS)
        streamWriteUIntN(streamId, spec.capacities[fillTypeIndex], numBits)
    end
end
function PlaceableHusbandryMeadow:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for fillTypeIndex, filLLevel in pairs(self.spec_husbandryMeadow.fillLevels) do
                spec.fillLevels[fillTypeIndex] = streamReadUIntN(streamId, PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS)
                spec.capacities[fillTypeIndex] = streamReadUIntN(streamId, numBits)
            end
            self:updateMeadowInfo()
        end
    end
end
function PlaceableHusbandryMeadow:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_husbandryMeadow
        local numBits = streamWriteBool
        local fillLevel = spec.dirtyFlag
        if numBits(streamId, bit32.band(dirtyMask, fillLevel) ~= 0) then
            for fillTypeIndex, fillLevel in pairs(spec.fillLevels) do
                streamWriteUIntN(streamId, fillLevel, PlaceableHusbandryMeadow.FILLLEVEL_NUM_BITS)
                streamWriteUIntN(streamId, spec.capacities[fillTypeIndex], numBits)
            end
        end
    end
end
function PlaceableHusbandryMeadow:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_husbandryMeadow
    local found = false
    for _, fillLevelKey in xmlFile:iterator(key .. ".fillType") do
        local fillTypeName = xmlFile:getValue(fillLevelKey .. "#name")
        if fillTypeName ~= nil then
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
            if fillTypeIndex ~= nil and spec.fillLevels[fillTypeIndex] ~= nil then
                local fillLevel = xmlFile:getValue(fillLevelKey .. "#fillLevel")
                local capacity = xmlFile:getValue(fillLevelKey .. "#capacity")
                spec.fillLevels[fillTypeIndex] = fillLevel or spec.fillLevels[fillTypeIndex]
                spec.capacities[fillTypeIndex] = capacity or spec.capacities[fillTypeIndex]
                found = true
            end
        end
    end
    spec.isMeadowInfoDirty = not found
    self:updateMeadowInfo()
    local fieldTaskKey = key .. ".createTask"
    if xmlFile:hasProperty(fieldTaskKey) then
        local createTask = MeadowCreationTask.new()
        if createTask:loadFromXMLFile(xmlFile, fieldTaskKey) then
            createTask:setNeedsSaving(false)
            createTask:enqueue()
            spec.pendingCreateTask = createTask
        end
    end
    local createTask = key .. ".clearTask"
    if xmlFile:hasProperty(createTask) then
        local clearTask = MeadowCreationTask.new()
        if clearTask:loadFromXMLFile(xmlFile, createTask) then
            clearTask:setNeedsSaving(false)
            clearTask:enqueue()
            spec.pendingClearTask = clearTask
        end
    end
    if spec.pendingCreateTask == nil and spec.pendingClearTask == nil then
        g_messageCenter:subscribe(MessageType.START_GROWTH_PERIOD, self.startMeadowGrowthUpdate, self)
        g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.finishMeadowGrowthUpdate, self)
    end
end
function PlaceableHusbandryMeadow:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_husbandryMeadow
    local index = 0
    for fillTypeIndex, fillLevel in pairs(spec.fillLevels) do
        local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
        if fillTypeName ~= nil then
            local fillLevelKey = string.format("%s.fillType(%d)", key, index)
            xmlFile:setValue(fillLevelKey .. "#name", fillTypeName)
            xmlFile:setValue(fillLevelKey .. "#fillLevel", fillLevel)
            xmlFile:setValue(fillLevelKey .. "#capacity", spec.capacities[fillTypeIndex] or 0)
            index = index + 1
        end
    end
    if spec.pendingCreateTask ~= nil then
        spec.pendingCreateTask:saveToXMLFile(xmlFile, key .. ".createTask")
    end
    if spec.pendingClearTask ~= nil then
        spec.pendingClearTask:saveToXMLFile(xmlFile, key .. ".clearTask")
    end
end
function PlaceableHusbandryMeadow:onUpdate(_)
    if self.isServer then
        local spec = self.spec_husbandryMeadow
        if spec.pendingCreateTask ~= nil then
            if spec.pendingCreateTask:getIsFinished() then
                spec.pendingCreateTask = nil
                if spec.clearTask == nil then
                    self:finishedMeadow()
                else
                    spec.pendingClearTask = spec.clearTask
                    spec.pendingClearTask:enqueue()
                end
            end
            self:raiseActive()
        end
        if spec.pendingClearTask ~= nil then
            if spec.pendingClearTask:getIsFinished() then
                spec.pendingClearTask = nil
                self:finishedMeadow()
            end
            self:raiseActive()
        end
    end
end
function PlaceableHusbandryMeadow:getCanCreateMeadow()
    return self.spec_husbandryMeadow.canCreateMeadow
end
function PlaceableHusbandryMeadow:createMeadow(doCreateMeadow, noEventSend)
    HusbandryMeadowCreateEvent.sendEvent(self, doCreateMeadow, noEventSend)
    if doCreateMeadow then
        if self.isServer then
            local spec = self.spec_husbandryMeadow
            local polygon = self:getOutdoorContourPolygon()
            local createTask = spec.createTask
            if polygon ~= nil and createTask ~= nil then
                local enlargedPolygon = polygon:getOffsetPolygon(0.5)
                if enlargedPolygon == nil then
                    Logging.warning("PlaceableHusbandryMeadow.createMeadow: Could not shrink polygon for creation task. Please double check order of fence segments and direction")
                else
                    local densityMapPolygon = DensityMapPolygon.new()
                    densityMapPolygon:updateFromPolygon2D(enlargedPolygon)
                    DensityMapFilter.new(g_densityMapHeightManager.tipCollisionMap, 0, 2):setValueCompareParams(DensityValueCompareType.EQUAL, 0)
                    createTask:setArea(densityMapPolygon)
                    if PlaceableHusbandryAnimals and PlaceableHusbandryAnimals.debugEnabled then
                        densityMapPolygon:visualize(120000, "PlaceableHusbandryMeadow")
                    end
                    createTask:enqueue()
                    spec.pendingCreateTask = createTask
                    self:raiseActive()
                end
            end
            self:finishedMeadow()
        end
    else
        self:finishedMeadow()
    end
end
function PlaceableHusbandryMeadow:finishedMeadow()
    if self.isServer then
        local spec = self.spec_husbandryMeadow
        local fillLevels, capacities = self:getMeadowVisualFillLevels()
        if fillLevels ~= nil then
            for fillTypeIndex, fillLevel in pairs(fillLevels) do
                spec.fillLevels[fillTypeIndex] = fillLevel
                spec.capacities[fillTypeIndex] = capacities[fillTypeIndex]
            end
        end
        self:updateMeadowInfo()
        self:raiseDirtyFlags(spec.dirtyFlag)
        g_messageCenter:subscribe(MessageType.START_GROWTH_PERIOD, self.startMeadowGrowthUpdate, self)
        g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.finishMeadowGrowthUpdate, self)
    end
end
function PlaceableHusbandryMeadow:onHusbandryAnimalsCreated()
    local spec = self.spec_husbandryMeadow
    if spec.isMeadowInfoDirty then
        local fillLevels, capacities = self:getMeadowVisualFillLevels()
        if fillLevels ~= nil then
            for fillTypeIndex, fillLevel in pairs(fillLevels) do
                spec.fillLevels[fillTypeIndex] = fillLevel
                spec.capacities[fillTypeIndex] = capacities[fillTypeIndex]
            end
            self:updateMeadowInfo()
        end
    end
end
function PlaceableHusbandryMeadow:onHusbandryFenceCustomizingUserLeft()
    self:createMeadow(true)
end
function PlaceableHusbandryMeadow:startMeadowGrowthUpdate()
    if self.isServer then
        local spec = self.spec_husbandryMeadow
        spec.growthStartFillLevels, spec.growthStartCapacities = self:getMeadowVisualFillLevels()
    end
end
function PlaceableHusbandryMeadow:finishMeadowGrowthUpdate()
    if self.isServer then
        local spec = self.spec_husbandryMeadow
        local growthEndFillLevels, growthEndCapacities = self:getMeadowVisualFillLevels()
        if spec.growthStartFillLevels ~= nil and growthEndFillLevels ~= nil then
            for fillTypeIndex, fillLevel in pairs(growthEndFillLevels) do
                local delta = fillLevel - spec.growthStartFillLevels[fillTypeIndex]
                if fillLevel == growthEndCapacities[fillTypeIndex] then
                    delta = growthEndCapacities[fillTypeIndex]
                end
                spec.fillLevels[fillTypeIndex] = math.clamp(spec.fillLevels[fillTypeIndex] + delta, 0, growthEndCapacities[fillTypeIndex])
            end
            self:updateMeadowInfo()
        end
    end
end
function PlaceableHusbandryMeadow:getMeadowVisualFillLevels()
    local polygon = self:getOutdoorContourPolygon()
    if polygon == nil then
        return nil, nil
    end
    local densityMapPolygon = DensityMapPolygon.new()
    densityMapPolygon:updateFromPolygon2D(polygon)
    local capacities = {}
    local fillLevels = {}
    for _, fruitTypeInfo in ipairs(self.spec_husbandryMeadow.fruitTypeInfos) do
        local fruitType = fruitTypeInfo.fruitType
        local fillTypeIndex = fruitTypeInfo.fillTypeIndex
        if fillLevels[fillTypeIndex] == nil then
            fillLevels[fillTypeIndex] = 0
            capacities[fillTypeIndex] = 0
        end
        local modifier = fruitType:getModifier()
        if modifier ~= nil then
            local filter = DensityMapFilter.new(modifier)
            filter:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, fruitTypeInfo.eatableEndGrowthState)
            densityMapPolygon:applyToModifier(modifier)
            local _, pixels, _ = modifier:executeGet(filter)
            local fruitCapacity = g_fruitTypeManager:getFruitTypeAreaLiters(fruitType.index, pixels, true)
            capacities[fillTypeIndex] = capacities[fillTypeIndex] + fruitCapacity
            local fruitFillLevel = 0
            if fruitCapacity > 0 then
                filter:setValueCompareParams(DensityValueCompareType.BETWEEN, fruitTypeInfo.eatableStartGrowthState, fruitTypeInfo.eatableEndGrowthState)
                local _, eatablePixels, _ = modifier:executeGet(filter)
                fruitFillLevel = g_fruitTypeManager:getFruitTypeAreaLiters(fruitType.index, eatablePixels, true)
            end
            fillLevels[fillTypeIndex] = fillLevels[fillTypeIndex] + fruitFillLevel
        end
    end
    return fillLevels, capacities
end
function PlaceableHusbandryMeadow:onMeadowFinishedGrowthPeriod()
    self:updateMeadowCapacity()
end
function PlaceableHusbandryMeadow:removeFood(superFunc, deltaToRemove, fillTypeIndex)
    local deltaRemoved = superFunc(self, deltaToRemove, fillTypeIndex)
    local deltaRemaining = deltaToRemove - deltaRemoved
    if deltaRemaining > 0 then
        local spec = self.spec_husbandryMeadow
        local fillLevel = spec.fillLevels[fillTypeIndex]
        if fillLevel ~= nil then
            local removed = math.min(fillLevel, deltaRemaining)
            spec.fillLevels[fillTypeIndex] = fillLevel - removed
            spec.dirtyFillLevels[fillTypeIndex] = true
            self:raiseDirtyFlags(spec.dirtyFlag)
            self:updateMeadowInfo()
        end
    end
    return deltaRemoved
end
function PlaceableHusbandryMeadow:updateMeadowInfo()
    local spec = self.spec_husbandryMeadow
    local fillLevel = 0
    local capacity = 0
    for fillTypeIndex, level in pairs(spec.fillLevels) do

    end
    local ratio = 0
    if capacity > 0 then
        ratio = fillLevel / capacity
    end
    local foodInfo = spec.foodInfo
    foodInfo.value = fillLevel
    foodInfo.capacity = capacity
    foodInfo.ratio = ratio
    local info = spec.info
    info.value = fillLevel
    info.capacity = capacity
    info.ratio = ratio
    info.text = string.format("%d l", fillLevel)
end
function PlaceableHusbandryMeadow:onFinishedFeeding()
    if self.isServer then
        self:updateMeadowVisuals()
    end
end
function PlaceableHusbandryMeadow:updateMeadowVisuals()
    local polygon = self:getOutdoorContourPolygon()
    if polygon ~= nil then
        local densityMapPolygon = DensityMapPolygon.new()
        densityMapPolygon:updateFromPolygon2D(polygon)
        local updatedFillTypes = {}
        local spec = self.spec_husbandryMeadow
        for _, fruitTypeInfo in ipairs(spec.fruitTypeInfos) do
            local fruitType = fruitTypeInfo.fruitType
            local fillTypeIndex = fruitTypeInfo.fillTypeIndex
            if spec.dirtyFillLevels[fillTypeIndex] then
                local capacity = spec.capacities[fillTypeIndex]
                if capacity > 0 then
                    local modifier = fruitType:getModifier()
                    densityMapPolygon:applyToModifier(modifier)
                    if modifier ~= nil then
                        local filter = DensityMapFilter.new(modifier)
                        filter:setValueCompareParams(DensityValueCompareType.BETWEEN, fruitTypeInfo.eatableStartGrowthState, fruitTypeInfo.eatableEndGrowthState)
                        local eatFilter = spec.fruitTypeEatFilters[fruitType.index]
                        if eatFilter == nil then
                            eatFilter = PerlinNoiseFilter.new(modifier, 11, 1, 0.5, math.random(0, 10000))
                            spec.fruitTypeEatFilters[fruitTypeIndex] = eatFilter
                        end
                        local maxFilterValue = math.ceil((1 - spec.fillLevels[fillTypeIndex] / capacity) * spec.eatFilterMaxValue)
                        eatFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, maxFilterValue)
                        modifier:executeSet(fruitTypeInfo.eatenGrowthState, filter, eatFilter)
                    end
                end
                updatedFillTypes[fillTypeIndex] = true
            end
        end
        for _, fruitTypeInfo in pairs(updatedFillTypes) do
            spec.dirtyFillLevels[_] = nil
        end
    end
end
function PlaceableHusbandryMeadow:getAvailableFood(superFunc, fillTypeIndex)
    local fillLevel = superFunc(self, fillTypeIndex)
    local meadowFillLevel = self.spec_husbandryMeadow.fillLevels[fillTypeIndex]
    if meadowFillLevel ~= nil then
    end
    return fillLevel
end
function PlaceableHusbandryMeadow:getFoodInfos(superFunc)
    local foodInfos = superFunc(self)
    local spec = self.spec_husbandryMeadow
    if #spec.fruitTypeInfos > 0 then
        table.insert(foodInfos, spec.foodInfo)
    end
    return foodInfos
end
function PlaceableHusbandryMeadow:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_husbandryMeadow
    if #spec.fruitTypeInfos > 0 then
        table.insert(infoTable, spec.info)
    end
end