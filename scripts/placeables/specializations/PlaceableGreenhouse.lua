PlaceableGreenhouse = {}
PlaceableGreenhouse.GROWTH_INTERVAL_MIN = 25200000
PlaceableGreenhouse.GROWTH_INTERVAL_MAX = 28800000
PlaceableGreenhouse.WATERING_INTERVAL_MIN = 10800000
PlaceableGreenhouse.WATERING_INTERVAL_MAX = 14400000
PlaceableGreenhouse.WATERING_DURATION = 600000
function PlaceableGreenhouse.getRandomGrowthInterval()
    return math.random(PlaceableGreenhouse.GROWTH_INTERVAL_MIN, PlaceableGreenhouse.GROWTH_INTERVAL_MAX)
end
function PlaceableGreenhouse.getRandomWateringInterval()
    return math.random(PlaceableGreenhouse.WATERING_INTERVAL_MIN, PlaceableGreenhouse.WATERING_INTERVAL_MAX)
end
PlaceableGreenhouse.plantXmlSchema = nil
function PlaceableGreenhouse.prerequisitesPresent(specializations)
    return true
end
function PlaceableGreenhouse.initSpecialization()
    local plantXmlSchema = XMLSchema.new("greenhousePlant")
    plantXmlSchema:register(XMLValueType.STRING, "greenhousePlant.i3dFilename", "i3d file of plant")
    plantXmlSchema:register(XMLValueType.NODE_INDEX, "greenhousePlant.stages.growing(?)#node", "Growing mesh")
    plantXmlSchema:register(XMLValueType.NODE_INDEX, "greenhousePlant.stages.withered#node", "Withered mesh")
    I3DUtil.registerI3dMappingXMLPaths(plantXmlSchema, "greenhousePlant")
    PlaceableGreenhouse.plantXmlSchema = plantXmlSchema
end
function PlaceableGreenhouse.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "loadPlantFromXml", PlaceableGreenhouse.loadPlantFromXml)
    SpecializationUtil.registerFunction(placeableType, "plantI3DLoadedCallback", PlaceableGreenhouse.plantI3DLoadedCallback)
    SpecializationUtil.registerFunction(placeableType, "addPlantPlace", PlaceableGreenhouse.addPlantPlace)
    SpecializationUtil.registerFunction(placeableType, "updatePlantDistribution", PlaceableGreenhouse.updatePlantDistribution)
    SpecializationUtil.registerFunction(placeableType, "setPlantAtPlace", PlaceableGreenhouse.setPlantAtPlace)
    SpecializationUtil.registerFunction(placeableType, "updatePlantsStage", PlaceableGreenhouse.updatePlantsStage)
end
function PlaceableGreenhouse.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableGreenhouse)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableGreenhouse)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableGreenhouse)
    SpecializationUtil.registerEventListener(placeableType, "onOutputFillTypesChanged", PlaceableGreenhouse)
    SpecializationUtil.registerEventListener(placeableType, "onProductionStatusChanged", PlaceableGreenhouse)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableGreenhouse)
end
function PlaceableGreenhouse.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Greenhouse")
    schema:register(XMLValueType.STRING, basePath .. ".greenhouse.plants.plant(?)#fillType", "FillType of plant")
    schema:register(XMLValueType.STRING, basePath .. ".greenhouse.plants.plant(?)#xmlFilename", "xml file of greenhouse plant")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".greenhouse.plantSpaces.space(?)#node", "node where plant is placed")
    schema:register(XMLValueType.BOOL, basePath .. ".greenhouse.plantSpaces.space(?)#useRandomYRot", "node is randomly rotated on the y axis", true)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".greenhouse.plantSpaces.spacesParent(?)#node", "parent node of nodes where plants are placed")
    schema:register(XMLValueType.BOOL, basePath .. ".greenhouse.plantSpaces.spacesParent(?)#useRandomYRot", "node is randomly rotated on the y axis", true)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".greenhouse.sounds", "watering")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".greenhouse.effectNodes")
    schema:setXMLSpecializationType()
end
function PlaceableGreenhouse:onLoad(_)
    local spec = self.spec_greenhouse
    local xmlFile = self.xmlFile
    spec.filltypeIdToPlant = {}
    spec.plantPlaces = {}
    spec.activeFilltypes = {}
    spec.hasWater = true
    spec.plantXMLFiles = {}
    for _, plantKey in xmlFile:iterator("placeable.greenhouse.plants.plant") do
        local fillTypeName = xmlFile:getValue(plantKey .. "#fillType")
        local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
        if fillType == nil then
            Logging.xmlWarning(xmlFile, "Unknown fillType \'%s\' for plant \'%s\'", fillTypeName, plantKey)
        else
            local plantXmlFilename = xmlFile:getValue(plantKey .. "#xmlFilename")
            if plantXmlFilename ~= nil then
                spec.filltypeIdToPlant[fillType] = self:loadPlantFromXml((Utils.getFilename(plantXmlFilename, self.baseDirectory))) or spec.filltypeIdToPlant[fillType]
            end
        end
    end
    for _, plantKey in xmlFile:iterator("placeable.greenhouse.plantSpaces.space") do
        local fillTypeName = self.xmlFile:getValue(plantKey .. "#node", nil, self.components, self.i3dMappings)
        local fillType = self.xmlFile:getValue(plantKey .. "#useRandomYRot", true)
        if fillTypeName ~= nil then
            self:addPlantPlace(fillTypeName, fillType)
        end
    end
    for _, plantKey in xmlFile:iterator("placeable.greenhouse.plantSpaces.spacesParent") do
        local fillTypeName = self.xmlFile:getValue(plantKey .. "#node", nil, self.components, self.i3dMappings)
        local fillType = self.xmlFile:getValue(plantKey .. "#useRandomYRot", true)
        local plantXmlFilename = getNumOfChildren(fillTypeName)
        if plantXmlFilename > 0 then
            local i = 0
            for i = i, plantXmlFilename - 1 do
                self:addPlantPlace(getChildAt(fillTypeName, i), fillType)
            end
        else
            Logging.xmlWarning(xmlFile, "No i3d child nodes for \'%s\'", plantKey)
        end
    end
    if self.isClient then
        spec.samples = {}
        spec.samples.watering = g_soundManager:loadSampleFromXML(xmlFile, "placeable.greenhouse.sounds", "watering", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
        spec.effects = g_effectManager:loadEffect(xmlFile, "placeable.greenhouse.effectNodes", self.components, self, self.i3dMappings)
    end
    spec.growthTimer = Timer.new(PlaceableGreenhouse.getRandomGrowthInterval())
    spec.growthTimer:setFinishCallback(function(timerInstance)
        -- upvalues: (copy) self
        timerInstance:setDuration(PlaceableGreenhouse.getRandomGrowthInterval())
        self:updatePlantsStage()
    end)
    spec.growthTimer:setScaleFunction(function()
        return g_currentMission:getEffectiveTimeScale()
    end)
    spec.wateringTimer = Timer.new(PlaceableGreenhouse.getRandomWateringInterval())
    spec.wateringTimer:setFinishCallback(function(timerInstance)
        -- upvalues: (copy) spec
        if spec.hasWater then
            g_effectManager:startEffects(spec.effects)
            g_soundManager:playSample(spec.samples.watering)
            Timer.createOneshot(PlaceableGreenhouse.WATERING_DURATION, function()
                -- upvalues: (ref) spec
                g_effectManager:stopEffects(spec.effects)
                g_soundManager:stopSample(spec.samples.watering)
            end, function()
                return g_currentMission:getEffectiveTimeScale()
            end)
            timerInstance:start()
        end
    end)
    spec.wateringTimer:setScaleFunction(function()
        return g_currentMission:getEffectiveTimeScale()
    end)
end
function PlaceableGreenhouse:addPlantPlace(node, useRandomYRot)
    if Utils.getNoNil(useRandomYRot, true) then
        setRotation(node, 0, math.random() * 3.141592653589793 * 2, 0)
    end
    table.insert(self.spec_greenhouse.plantPlaces, {
        ["node"] = node,
        ["fillType"] = nil,
        ["stage"] = nil
    })
end
function PlaceableGreenhouse:loadPlantFromXml(xmlFilename)
    local plant = {
        ["i3dFilename"] = "",
        ["i3dNode"] = nil,
        ["stages"] = {
            ["growing"] = {},
            ["first"] = nil,
            ["last"] = nil,
            ["withered"] = nil
        }
    }
    local plantXmlFile = XMLFile.load("plantXml", xmlFilename, PlaceableGreenhouse.plantXmlSchema)
    if plantXmlFile ~= nil then
        self.spec_greenhouse.plantXMLFiles[plantXmlFile] = true
        local i3dFilename = plantXmlFile:getValue("greenhousePlant.i3dFilename")
        if i3dFilename ~= nil then
            plant.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
            local arguments = {
                ["plant"] = plant,
                ["plantXmlFile"] = plantXmlFile,
                ["loadingTask"] = self:createLoadingTask()
            }
            plant.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(plant.i3dFilename, false, false, self.plantI3DLoadedCallback, self, arguments)
        end
    end
    return plant
end
function PlaceableGreenhouse:plantI3DLoadedCallback(i3dNode, _, args)
    local plant = args.plant
    local plantXmlFile = args.plantXmlFile
    if i3dNode ~= 0 then
        local components = I3DUtil.loadI3DComponents(i3dNode)
        local i3dMappings = I3DUtil.loadI3DMapping(plantXmlFile, "greenhousePlant", components)
        plant.i3dNode = i3dNode
        plantXmlFile:iterate("greenhousePlant.stages.growing", function(_, key)
            -- upvalues: (copy) plantXmlFile, (copy) components, (copy) i3dMappings, (copy) plant
            local growingNode = plantXmlFile:getValue(key .. "#node", nil, components, i3dMappings)
            if growingNode ~= nil then
                local childIndex = getChildIndex(growingNode)
                table.insert(plant.stages.growing, childIndex)
            end
        end)
        plant.stages.first = plant.stages.growing[1]
        plant.stages.last = plant.stages.growing[#plant.stages.growing]
        local witheredNode = plantXmlFile:getValue("greenhousePlant.stages.withered#node", nil, components, i3dMappings)
        if witheredNode ~= nil then
            plant.stages.withered = getChildIndex(witheredNode)
        end
    end
    plantXmlFile:delete()
    self.spec_greenhouse.plantXMLFiles[plantXmlFile] = nil
    self:finishLoadingTask(args.loadingTask)
end
function PlaceableGreenhouse:onDelete()
    local spec = self.spec_greenhouse
    if spec.plantXMLFiles ~= nil then
        for plantXMLFile, _ in pairs(spec.plantXMLFiles) do
            plantXMLFile:delete()
            spec.plantXMLFiles[plantXMLFile] = nil
        end
    end
    if spec.growthTimer ~= nil then
        spec.growthTimer:delete()
    end
    if spec.wateringTimer ~= nil then
        spec.wateringTimer:delete()
    end
    if spec.filltypeIdToPlant ~= nil then
        for plantXMLFile, _ in pairs(spec.filltypeIdToPlant) do
            if _.sharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(_.sharedLoadRequestId)
            end
            if _.i3dNode ~= nil then
                delete(_.i3dNode)
                _.i3dNode = nil
            end
        end
    end
    g_effectManager:deleteEffects(spec.effects)
    g_soundManager:deleteSamples(spec.samples)
end
function PlaceableGreenhouse:onFinalizePlacement()
    self.plantDistributionDirty = true
    self.spec_greenhouse.wateringTimer:start()
end
function PlaceableGreenhouse:onUpdate()
    if self.plantDistributionDirty then
        self:updatePlantDistribution()
    end
end
function PlaceableGreenhouse:onOutputFillTypesChanged(outputs, state)
    for _, output in pairs(outputs) do
        if state then
            if self.spec_greenhouse.filltypeIdToPlant[output.type] ~= nil then
                spec.activeFilltypes[fillType] = true
            end
        else
            spec.activeFilltypes[fillType] = nil
        end
    end
    if self:getIsSynchronized() then
        self.plantDistributionDirty = true
    end
    self:raiseActive()
end
function PlaceableGreenhouse:onProductionStatusChanged(_, status)
    local spec = self.spec_greenhouse
    local hasWater = not (status == ProductionPoint.PROD_STATUS.MISSING_INPUTS)
    if spec.hasWater ~= hasWater then
        spec.hasWater = hasWater
        self:updatePlantsStage()
    end
    if hasWater and next(spec.activeFilltypes) ~= nil then
        spec.wateringTimer:startIfNotRunning()
    else
        spec.wateringTimer:stop()
    end
end
function PlaceableGreenhouse:updatePlantDistribution()
    local spec = self.spec_greenhouse
    local numActiveFilltypes = table.size(spec.activeFilltypes)
    local fillTypesList = table.toList(spec.activeFilltypes)
    local i = 1
    for i = i, #spec.plantPlaces do
        self:setPlantAtPlace(fillTypesList[i % numActiveFilltypes + 1], spec.plantPlaces[i])
    end
    self.plantDistributionDirty = false
    self:updatePlantsStage()
end
function PlaceableGreenhouse:setPlantAtPlace(fillType, plantPlace)
    if plantPlace.fillType ~= fillType then
        if plantPlace.fillType ~= nil then
            local i = getNumOfChildren(plantPlace.node) - 1
            for i = i, 0, -1 do
                local plantStage = getChildAt(plantPlace.node, i)
                delete(plantStage)
            end
            plantPlace.fillType = nil
        end
        local plant = self.spec_greenhouse.filltypeIdToPlant[fillType]
        if plant ~= nil then
            local plantClone = clone(getChildAt(plant.i3dNode, 0), false, false, false)
            local n = getNumOfChildren(plantClone) - 1
            local plantStage = -1
            for n = n, 0, plantStage do
                local plantStage = getChildAt(plantClone, n)
                link(plantPlace.node, plantStage, 0)
            end
            plantPlace.fillType = fillType
            plantPlace.stage = nil
            delete(plantClone)
        end
    end
end
function PlaceableGreenhouse:updatePlantsStage()
    local spec = self.spec_greenhouse
    if table.size(spec.activeFilltypes) ~= 0 then
        if spec.hasWater then
            spec.growthTimer:start()
        else
            spec.growthTimer:stop()
        end
        local i = 1
        for i = i, #spec.plantPlaces do
            local plantPlace = spec.plantPlaces[i]
            local newStage
            if spec.hasWater then
                newStage = plantPlace.stage and plantPlace.stage + 1 or spec.filltypeIdToPlant[plantPlace.fillType].stages.first
                if plant.stages.last < newStage then
                    newStage = plant.stages.first
                end
            else
                newStage = plant.stages.withered
            end
            if plantPlace.stage ~= newStage then
                local n = 0
                for n = n, getNumOfChildren(plantPlace.node) - 1 do
                    local plantStage = getChildAt(plantPlace.node, n)
                    setVisibility(plantStage, n == newStage)
                end
                plantPlace.stage = newStage
            end
        end
    end
end