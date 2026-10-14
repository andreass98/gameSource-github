PlaceableHusbandryFood = {}
function PlaceableHusbandryFood.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
end
function PlaceableHusbandryFood.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateFillPlanes", PlaceableHusbandryFood.updateFillPlanes)
    SpecializationUtil.registerFunction(placeableType, "updateFoodPlaces", PlaceableHusbandryFood.updateFoodPlaces)
    SpecializationUtil.registerFunction(placeableType, "addFood", PlaceableHusbandryFood.addFood)
    SpecializationUtil.registerFunction(placeableType, "removeFood", PlaceableHusbandryFood.removeFood)
    SpecializationUtil.registerFunction(placeableType, "getTotalFood", PlaceableHusbandryFood.getTotalFood)
    SpecializationUtil.registerFunction(placeableType, "getAvailableFood", PlaceableHusbandryFood.getAvailableFood)
    SpecializationUtil.registerFunction(placeableType, "getFoodCapacity", PlaceableHusbandryFood.getFoodCapacity)
    SpecializationUtil.registerFunction(placeableType, "getFreeFoodCapacity", PlaceableHusbandryFood.getFreeFoodCapacity)
    SpecializationUtil.registerFunction(placeableType, "getFoodLitersPerHour", PlaceableHusbandryFood.getFoodLitersPerHour)
end
function PlaceableHusbandryFood.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryFood.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateFeeding", PlaceableHusbandryFood.updateFeeding)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getFoodInfos", PlaceableHusbandryFood.getFoodInfos)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableHusbandryFood.collectPickObjects)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getAnimalDescription", PlaceableHusbandryFood.getAnimalDescription)
end
function PlaceableHusbandryFood.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryFood)
    SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableHusbandryFood)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryFood)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryFood)
    SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableHusbandryFood)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryFood)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryFood)
    SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandryFood)
    SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandryFood)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryFood)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsCreated", PlaceableHusbandryFood)
end
function PlaceableHusbandryFood.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    basePath = basePath .. ".husbandry.food"
    schema:register(XMLValueType.INT, basePath .. "#capacity", "Trough capacity", 5000)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".foodPlaces.foodPlace(?)#node", "Foodplace")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".dynamicFoodPlane#node", "Node")
    schema:register(XMLValueType.STRING, basePath .. ".dynamicFoodPlane#defaultFillType", "Fillplane default filltype")
    FillPlaneUtil.registerFillPlaneXMLPaths(schema, basePath .. ".dynamicFoodPlane")
    FillPlane.registerXMLPaths(schema, basePath .. ".foodPlane")
    schema:register(XMLValueType.STRING, basePath .. ".foodPlane#defaultFillType", "Fillplane default filltype")
    UnloadTrigger.registerTriggerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryFood.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    schema:register(XMLValueType.STRING, basePath .. ".fillLevel(?)#fillType", "Fill type")
    schema:register(XMLValueType.FLOAT, basePath .. ".fillLevel(?)#fillLevel", "Fill level")
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryFood.initSpecialization()
    g_storeManager:addSpecType("animalFoodFillTypes", "shopListAttributeIconFillTypes", PlaceableHusbandryFood.loadSpecValueAnimalFoodFillTypes, PlaceableHusbandryFood.getSpecValueAnimalFoodFillTypes, StoreSpecies.PLACEABLE)
end
function PlaceableHusbandryFood:onLoad(_)
    local spec = self.spec_husbandryFood
    spec.animalTypeIndex = nil
    spec.litersPerHour = 0
    spec.fillLevels = {}
    spec.supportedFillTypes = {}
    spec.fillTypes = {}
    spec.lastPositionInfoSent = { 0, 0 }
    spec.lastPositionInfo = { 0, 0 }
    spec.foodPlaces = {}
    spec.info = {
        ["title"] = g_i18n:getText("ui_animalFood"),
        ["text"] = ""
    }
    spec.dirtyFlagPosition = self:getNextDirtyFlag()
    spec.dirtyFlagFillLevel = self:getNextDirtyFlag()
    spec.capacity = self.xmlFile:getValue("placeable.husbandry.food#capacity", 5000)
    spec.FILLLEVEL_NUM_BITS = MathUtil.getNumRequiredBits(spec.capacity)
    spec.feedingTroughs = UnloadTrigger.createTriggers(self.isServer, self.isClient, self.xmlFile, "placeable.husbandry.food", self.components, {
        ["getIsFillTypeAllowed"] = function(_, fillTypeIndex)
            -- upvalues: (copy) spec
            return spec.supportedFillTypes[fillTypeIndex]
        end,
        ["getIsToolTypeAllowed"] = function(_, fillTypeIndex)
            return true
        end,
        ["addFillLevelFromTool"] = function(_, ...)
            -- upvalues: (copy) self
            return self:addFood(...)
        end,
        ["getFreeCapacity"] = function(_, fillTypeIndex)
            -- upvalues: (copy) self
            return self:getFreeFoodCapacity(fillTypeIndex)
        end
    }, nil, self.i3dMappings)
    if #spec.feedingTroughs == 0 then
        Logging.xmlWarning(self.xmlFile, "Missing no unload triggers defined for husbandry food")
        self:setLoadingState(PlaceableLoadingState.ERROR)
    else
        spec.baseNode = self.xmlFile:getValue("placeable.husbandry.food.dynamicFoodPlane#node", nil, self.components, self.i3dMappings)
        if spec.baseNode ~= nil then
            local fillPlane = FillPlaneUtil.createFromXML(self.xmlFile, "placeable.husbandry.food.dynamicFoodPlane", spec.baseNode, spec.capacity)
            local defaultFillTypeName = self.xmlFile:getValue("placeable.husbandry.food.dynamicFoodPlane#defaultFillType")
            local defaultFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(defaultFillTypeName) or FillType.FORAGE
            if fillPlane ~= nil then
                FillPlaneUtil.assignDefaultMaterialsFromTerrain(fillPlane, g_terrainNode)
                FillPlaneUtil.setFillType(fillPlane, defaultFillTypeIndex)
                spec.dynamicFoodPlane = fillPlane
            end
        end
        spec.foodPlane = FillPlane.new()
        if spec.foodPlane:load(self.components, self.xmlFile, "placeable.husbandry.food.foodPlane", self.i3dMappings) then
            local fillPlane = self.xmlFile:getValue("placeable.husbandry.food.foodPlane#defaultFillType")
            local defaultFillTypeName = g_fillTypeManager:getFillTypeIndexByName(fillPlane) or FillType.DRYGRASS_WINDROW
            FillPlaneUtil.assignDefaultMaterialsFromTerrain(spec.foodPlane.node, g_terrainNode)
            FillPlaneUtil.setFillType(spec.foodPlane.node, defaultFillTypeName)
            setShaderParameter(spec.foodPlane.node, "isCustomShape", 1, 0, 0, 0, false)
            spec.foodPlane:setState(0)
        else
            spec.foodPlane:delete()
            spec.foodPlane = nil
        end
        self.xmlFile:iterate("placeable.husbandry.food.foodPlaces.foodPlace", function(_, key)
            -- upvalues: (copy) self, (copy) spec
            local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
            table.insert(spec.foodPlaces, {
                ["node"] = node,
                ["place"] = nil
            })
        end)
    end
end
function PlaceableHusbandryFood:onPostLoad()
    local spec = self.spec_husbandryFood
    spec.animalTypeIndex = self:getAnimalTypeIndex()
    local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(spec.animalTypeIndex)
    local mixtures = g_currentMission.animalFoodSystem:getMixturesByAnimalTypeIndex(spec.animalTypeIndex)
    if animalFood ~= nil then
        for _, foodGroup in pairs(animalFood.groups) do
            for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
                if spec.fillLevels[fillTypeIndex] == nil then
                    spec.fillLevels[fillTypeIndex] = 0
                    spec.supportedFillTypes[fillTypeIndex] = true
                    table.insert(spec.fillTypes, fillTypeIndex)
                end
            end
        end
    end
    if mixtures ~= nil then
        for _, foodGroup in ipairs(mixtures) do
            spec.supportedFillTypes[foodGroup] = true
            table.insert(spec.fillTypes, foodGroup)
        end
    end
end
function PlaceableHusbandryFood:onDelete()
    local spec = self.spec_husbandryFood
    if spec.feedingTroughs ~= nil then
        for _, trigger in ipairs(spec.feedingTroughs) do
            trigger:delete()
        end
        spec.feedingTroughs = nil
    end
    if spec.dynamicFoodPlane ~= nil then
        delete(spec.dynamicFoodPlane)
        spec.dynamicFoodPlane = nil
    end
    if spec.foodPlane ~= nil then
        spec.foodPlane:delete()
        spec.foodPlane = nil
    end
end
function PlaceableHusbandryFood:onFinalizePlacement()
    local spec = self.spec_husbandryFood
    if spec.feedingTroughs ~= nil then
        for _, trigger in ipairs(spec.feedingTroughs) do
            trigger:register(true)
        end
    end
end
function PlaceableHusbandryFood:onPostFinalizePlacement()
    self:updateFillPlanes()
end
function PlaceableHusbandryFood:onReadStream(streamId, connection)
    local spec = self.spec_husbandryFood
    for _, fillTypeIndex in ipairs(spec.fillTypes) do
        if spec.fillLevels[fillTypeIndex] ~= nil then
            spec.fillLevels[fillTypeIndex] = streamReadUIntN(streamId, spec.FILLLEVEL_NUM_BITS)
        end
    end
    if spec.feedingTroughs ~= nil then
        for _, fillTypeIndex in ipairs(spec.feedingTroughs) do
            local feedingTroughId = NetworkUtil.readNodeObjectId(streamId)
            fillTypeIndex:readStream(streamId, connection)
            g_client:finishRegisterObject(fillTypeIndex, feedingTroughId)
        end
    end
end
function PlaceableHusbandryFood:onWriteStream(streamId, connection)
    local spec = self.spec_husbandryFood
    for _, fillTypeIndex in ipairs(spec.fillTypes) do
        if spec.fillLevels[fillTypeIndex] ~= nil then
            streamWriteUIntN(streamId, spec.fillLevels[fillTypeIndex], spec.FILLLEVEL_NUM_BITS)
        end
    end
    if spec.feedingTroughs ~= nil then
        for _, fillTypeIndex in ipairs(spec.feedingTroughs) do
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(fillTypeIndex))
            fillTypeIndex:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, fillTypeIndex)
        end
    end
end
function PlaceableHusbandryFood:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self.spec_husbandryFood.lastPositionInfo[1] = FillVolume.readStreamCompressedPosition(streamId)
            spec.lastPositionInfo[2] = FillVolume.readStreamCompressedPosition(streamId)
        end
        if streamReadBool(streamId) then
            for _, fillTypeIndex in ipairs(spec.fillTypes) do
                if spec.fillLevels[fillTypeIndex] ~= nil then
                    local delta = streamReadUIntN(streamId, spec.FILLLEVEL_NUM_BITS) - spec.fillLevels[fillTypeIndex]
                    if delta > 0 then
                        self:addFood(self:getOwnerFarmId(), delta, fillTypeIndex, nil, nil, nil)
                    else
                        self:removeFood(math.abs(delta), fillTypeIndex)
                    end
                end
            end
        end
    end
end
function PlaceableHusbandryFood:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_husbandryFood
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlagPosition) ~= 0) then
            FillVolume.writeStreamCompressedPosition(streamId, spec.lastPositionInfoSent[1])
            FillVolume.writeStreamCompressedPosition(streamId, spec.lastPositionInfoSent[2])
        end
        if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlagFillLevel) ~= 0) then
            for _, fillTypeIndex in ipairs(spec.fillTypes) do
                if spec.fillLevels[fillTypeIndex] ~= nil then
                    streamWriteUIntN(streamId, spec.fillLevels[fillTypeIndex], spec.FILLLEVEL_NUM_BITS)
                end
            end
        end
    end
end
function PlaceableHusbandryFood:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_husbandryFood
    xmlFile:iterate(key .. ".fillLevel", function(_, fillLevelKey)
        -- upvalues: (copy) xmlFile, (copy) spec, (copy) self
        local fillTypeName = xmlFile:getValue(fillLevelKey .. "#fillType")
        local fillLevel = xmlFile:getValue(fillLevelKey .. "#fillLevel")
        if fillTypeName ~= nil and fillLevel ~= nil then
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
            if fillTypeIndex ~= nil and spec.supportedFillTypes[fillTypeIndex] ~= nil then
                self:addFood(self:getOwnerFarmId(), fillLevel, fillTypeIndex, nil, nil, nil)
            end
        end
    end)
end
function PlaceableHusbandryFood:saveToXMLFile(xmlFile, key, _)
    local index = 0
    for fillTypeIndex, fillLevel in pairs(self.spec_husbandryFood.fillLevels) do
        if fillLevel > 0 then
            local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
            if fillTypeName ~= nil then
                local fillLevelKey = string.format("%s.fillLevel(%d)", key, index)
                xmlFile:setValue(fillLevelKey .. "#fillType", fillTypeName)
                xmlFile:setValue(fillLevelKey .. "#fillLevel", fillLevel)
                index = index + 1
            end
        end
    end
end
function PlaceableHusbandryFood:updateFeeding(superFunc)
    local factor = superFunc(self)
    local spec = self.spec_husbandryFood
    if self.isServer and spec.animalTypeIndex ~= nil then
        local consumedFood = {}
        factor = factor * g_currentMission.animalFoodSystem:consumeFood(spec.animalTypeIndex, spec.litersPerHour * g_currentMission.environment.timeAdjustment, self, consumedFood)
        for fillTypeIndex, delta in pairs(consumedFood) do
            self:removeFood(delta, fillTypeIndex)
        end
    end
    return factor
end
function PlaceableHusbandryFood:getFoodLitersPerHour()
    return self.spec_husbandryFood.litersPerHour
end
function PlaceableHusbandryFood:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_husbandryFood
    local fillLevel = self:getTotalFood()
    spec.info.text = string.format("%d l", fillLevel)
    table.insert(infoTable, spec.info)
end
function PlaceableHusbandryFood:getFoodInfos(superFunc)
    local foodInfos = superFunc(self)
    local spec = self.spec_husbandryFood
    local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(spec.animalTypeIndex)
    if animalFood ~= nil then
        for _, foodGroup in pairs(animalFood.groups) do
            local fillLevel = 0
            local capacity = spec.capacity
            for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
                if spec.fillLevels[fillTypeIndex] ~= nil then
                end
            end
            local info = {
                ["title"] = string.format("%s (%d%%)", foodGroup.title, MathUtil.round(foodGroup.productionWeight * 100)),
                ["value"] = fillLevel,
                ["capacity"] = capacity,
                ["ratio"] = 0
            }
            if capacity > 0 then
                info.ratio = fillLevel / capacity
            end
            table.insert(foodInfos, info)
        end
    end
    return foodInfos
end
function PlaceableHusbandryFood:updateFillPlanes(fillTypeIndex)
    local spec = self.spec_husbandryFood
    if spec.foodPlane ~= nil then
        local fillLevel = self:getTotalFood()
        local capacity = self:getFoodCapacity()
        local state = 0
        if capacity > 0 then
            state = math.clamp(fillLevel / capacity, 0, 1)
        end
        spec.foodPlane:setState(state)
        if state > 0 and fillTypeIndex ~= nil then
            FillPlaneUtil.assignDefaultMaterialsFromTerrain(spec.foodPlane.node, g_terrainNode)
            FillPlaneUtil.setFillType(spec.foodPlane.node, fillTypeIndex)
            setShaderParameter(spec.foodPlane.node, "isCustomShape", 1, 0, 0, 0, false)
        end
    end
end
function PlaceableHusbandryFood:collectPickObjects(superFunc, node)
    local spec = self.spec_husbandryFood
    if spec.feedingTroughs ~= nil then
        for _, trigger in ipairs(spec.feedingTroughs) do
            if node == trigger.exactFillRootNode then
                return
            end
        end
    end
    superFunc(self, node)
end
function PlaceableHusbandryFood:onHusbandryAnimalsCreated(husbandryId)
    if husbandryId ~= nil then
        local spec = self.spec_husbandryFood
        spec.husbandryId = husbandryId
        for _, foodPlace in ipairs(spec.foodPlaces) do
            local feedingPlaceIndex, isAccessible = addFeedingPlace(husbandryId, foodPlace.node, 0, AnimalHusbandryFeedingType.FOOD)
            if isAccessible then
                foodPlace.place = feedingPlaceIndex
            end
        end
    end
end
function PlaceableHusbandryFood:updateFoodPlaces()
    local spec = self.spec_husbandryFood
    if spec.husbandryId ~= nil then
        local fillLevel = self:getTotalFood()
        for _, foodPlace in pairs(spec.foodPlaces) do
            if foodPlace.place ~= nil then
                updateFeedingPlace(spec.husbandryId, foodPlace.place, fillLevel)
            end
        end
    end
end
function PlaceableHusbandryFood:getTotalFood()
    local fillLevel = 0
    for _, level in pairs(self.spec_husbandryFood.fillLevels) do

    end
    return fillLevel
end
function PlaceableHusbandryFood:getAvailableFood(fillTypeIndex)
    return self.spec_husbandryFood.fillLevels[fillTypeIndex]
end
function PlaceableHusbandryFood:getFoodCapacity()
    return self.spec_husbandryFood.capacity
end
function PlaceableHusbandryFood:getFreeFoodCapacity(fillTypeIndex)
    local spec = self.spec_husbandryFood
    return spec.supportedFillTypes[fillTypeIndex] == nil and 0 or spec.capacity - self:getTotalFood()
end
function PlaceableHusbandryFood:addFood(farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
    local spec = self.spec_husbandryFood
    if spec.supportedFillTypes[fillTypeIndex] == nil then
        return 0
    end
    local mixture = g_currentMission.animalFoodSystem:getMixtureByFillType(fillTypeIndex)
    if mixture ~= nil then
        local filled = 0
        local maxDelta = math.min(deltaFillLevel, self:getFreeFoodCapacity(fillTypeIndex))
        for _, ingredient in ipairs(mixture.ingredients) do
            filled = filled + self:addFood(farmId, maxDelta * ingredient.weight, ingredient.fillTypes[1], fillPositionData, toolType, extraAttributes)
        end
        if filled > 0 then
            self:updateFillPlanes(fillTypeIndex)
        end
        return filled
    end
    local filled = self:getFreeFoodCapacity(fillTypeIndex)
    if filled == 0 then
        return 0
    end
    local maxDelta = math.min(filled, deltaFillLevel)
    if spec.dynamicFoodPlane == nil then
        ::l13::
        if self.isServer then
            self:raiseDirtyFlags(spec.dirtyFlagFillLevel)
        end
        spec.fillLevels[fillTypeIndex] = spec.fillLevels[fillTypeIndex] + maxDelta
        self:updateFillPlanes(fillTypeIndex)
        self:updateFoodPlaces()
        return maxDelta
    end
    if fillPositionData == nil then
        local maxDelta, y0, z0 = localToWorld(spec.dynamicFoodPlane, 0, 0, 0)
        local d1x, _, ingredient = localDirectionToWorld(spec.dynamicFoodPlane, 0.1, 0, 0)
        local delta, ingredientFillType, filledDelta = localDirectionToWorld(spec.dynamicFoodPlane, 0, 0, 0.1)
        if not self.isServer and (spec.lastPositionInfo[1] ~= 0 and spec.lastPositionInfo[2] ~= 0) then
            maxDelta, y0, z0 = localToWorld(spec.dynamicFoodPlane, spec.lastPositionInfo[1], 0, spec.lastPositionInfo[2])
        end
        local steps = math.clamp(math.floor(maxDelta / 400), 1, 25)
        for _ = 1, steps do
            fillPlaneAdd(spec.dynamicFoodPlane, maxDelta / steps, maxDelta, y0, z0, d1x, _, ingredient, delta, ingredientFillType, filledDelta)
        end
        goto l13
    end
    local maxDelta, y0, z0 = getWorldTranslation(fillPositionData.node)
    local d1x, _, ingredient = localDirectionToWorld(fillPositionData.node, fillPositionData.width, 0, 0)
    local delta, ingredientFillType, filledDelta = localDirectionToWorld(fillPositionData.node, 0, 0, fillPositionData.length)
    if VehicleDebug.state == VehicleDebug.DEBUG then
        drawDebugLine(maxDelta, y0, z0, 1, 0, 0, maxDelta + d1x, y0 + _, z0 + ingredient, 1, 0, 0)
        drawDebugLine(maxDelta, y0, z0, 0, 0, 1, maxDelta + delta, y0 + ingredientFillType, z0 + filledDelta, 0, 0, 1)
        drawDebugPoint(maxDelta, y0, z0, 1, 1, 1, 1)
        drawDebugPoint(maxDelta + d1x, y0 + _, z0 + ingredient, 1, 0, 0, 1)
        drawDebugPoint(maxDelta + delta, y0 + ingredientFillType, z0 + filledDelta, 0, 0, 1, 1)
    end
    local maxDelta = maxDelta - (d1x + delta) / 2
    local y0 = y0 - (_ + ingredientFillType) / 2
    local z0 = z0 - (ingredient + filledDelta) / 2
    fillPlaneAdd(spec.dynamicFoodPlane, maxDelta, maxDelta, y0, z0, d1x, _, ingredient, delta, ingredientFillType, filledDelta)
    if self.isServer then
        if math.abs(maxDelta - spec.lastPositionInfoSent[1]) > FillVolume.SEND_PRECISION then
            ::l20::
            spec.lastPositionInfoSent[1] = maxDelta
            spec.lastPositionInfoSent[2] = z0
            self:raiseDirtyFlags(spec.dirtyFlagPosition)
            goto l13
        end
    end
    if math.abs(z0 - spec.lastPositionInfoSent[2]) <= FillVolume.SEND_PRECISION then
        goto l13
    end
    goto l20
end
function PlaceableHusbandryFood:removeFood(absDeltaFillLevel, fillTypeIndex)
    local spec = self.spec_husbandryFood
    if spec.supportedFillTypes[fillTypeIndex] == nil then
        return 0
    end
    if absDeltaFillLevel <= 0 then
        return 0
    end
    local y = math.abs(absDeltaFillLevel)
    local z = spec.fillLevels[fillTypeIndex]
    local x = math.min(y, z)
    if spec.dynamicFoodPlane ~= nil then
        local x, y, z = localToWorld(spec.dynamicFoodPlane, 0, 0, 0)
        local d1x, d1y, d1z = localDirectionToWorld(spec.dynamicFoodPlane, 0.1, 0, 0)
        local d2x, d2y, d2z = localDirectionToWorld(spec.dynamicFoodPlane, 0, 0, 0.1)
        local delta = math.floor(x / 400)
        local steps = math.clamp(delta, 1, 25)
        local delta = x / steps
        for _ = 1, steps do
            fillPlaneAdd(spec.dynamicFoodPlane, -delta, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z)
        end
    end
    spec.fillLevels[fillTypeIndex] = spec.fillLevels[fillTypeIndex] - x
    if self.isServer then
        self:raiseDirtyFlags(spec.dirtyFlagFillLevel)
    end
    self:updateFillPlanes()
    self:updateFoodPlaces()
    return x
end
function PlaceableHusbandryFood:onHusbandryAnimalsUpdate(clusters)
    local spec = self.spec_husbandryFood
    spec.litersPerHour = 0
    for _, cluster in ipairs(clusters) do
        local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)
        if subType ~= nil then
            local food = subType.input.food
            if food ~= nil then
                local litersPerDay = food:get((cluster:getAge())) * cluster:getNumAnimals()
                spec.litersPerHour = spec.litersPerHour + litersPerDay / 24
            end
        end
    end
end
function PlaceableHusbandryFood:getAnimalDescription(superFunc, cluster)
    return superFunc(self, cluster) .. " " .. g_i18n:getText("animal_descriptionPercentage")
end
function PlaceableHusbandryFood.loadSpecValueAnimalFoodFillTypes(xmlFile, _, _)
    local data = nil
    if xmlFile:hasProperty("placeable.husbandry.animals") then
        data = data or {}
        data.animalTypeName = xmlFile:getString("placeable.husbandry.animals#type")
    end
    if xmlFile:hasProperty("placeable.husbandry.water") then
        data = data or {}
        data.needsWater = not xmlFile:getValue("placeable.husbandry.water#automaticWaterSupply", false)
    end
    return data
end
function PlaceableHusbandryFood.getSpecValueAnimalFoodFillTypes(storeItem, _)
    local data = storeItem.specs.animalFoodFillTypes
    if data == nil then
        return nil
    end
    local fillTypes = {}
    local animalType = g_currentMission.animalSystem:getTypeByName(data.animalTypeName)
    if animalType == nil then
        return nil
    end
    local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(animalType.typeIndex)
    local mixtures = g_currentMission.animalFoodSystem:getMixturesByAnimalTypeIndex(animalType.typeIndex)
    if animalFood ~= nil then
        for _, foodGroup in pairs(animalFood.groups) do
            for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
                table.addElement(fillTypes, fillTypeIndex)
            end
        end
    end
    if mixtures ~= nil then
        for _, foodGroup in ipairs(mixtures) do
            table.addElement(fillTypes, foodGroup)
        end
    end
    if data.needsWater then
        table.addElement(fillTypes, FillType.WATER)
    end
    return fillTypes
end