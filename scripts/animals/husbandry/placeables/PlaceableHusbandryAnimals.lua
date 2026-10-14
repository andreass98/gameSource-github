PlaceableHusbandryAnimals = {}
function PlaceableHusbandryAnimals.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandry, specializations)
end
function PlaceableHusbandryAnimals.registerEvents(placeableType)
    SpecializationUtil.registerEvent(placeableType, "onHusbandryAnimalsCreated")
    SpecializationUtil.registerEvent(placeableType, "onHusbandryAnimalsUpdate")
end
function PlaceableHusbandryAnimals.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onExternalNavigationMeshLoaded", PlaceableHusbandryAnimals.onExternalNavigationMeshLoaded)
    SpecializationUtil.registerFunction(placeableType, "createNavigationMeshFromContour", PlaceableHusbandryAnimals.createNavigationMeshFromContour)
    SpecializationUtil.registerFunction(placeableType, "createNavigationMesh", PlaceableHusbandryAnimals.createNavigationMesh)
    SpecializationUtil.registerFunction(placeableType, "setMaxNumAnimals", PlaceableHusbandryAnimals.setMaxNumAnimals)
    SpecializationUtil.registerFunction(placeableType, "createHusbandry", PlaceableHusbandryAnimals.createHusbandry)
    SpecializationUtil.registerFunction(placeableType, "updateVisualAnimals", PlaceableHusbandryAnimals.updateVisualAnimals)
    SpecializationUtil.registerFunction(placeableType, "getNumOfFreeAnimalSlots", PlaceableHusbandryAnimals.getNumOfFreeAnimalSlots)
    SpecializationUtil.registerFunction(placeableType, "getNumOfAnimals", PlaceableHusbandryAnimals.getNumOfAnimals)
    SpecializationUtil.registerFunction(placeableType, "getMaxNumOfAnimals", PlaceableHusbandryAnimals.getMaxNumOfAnimals)
    SpecializationUtil.registerFunction(placeableType, "getNumOfClusters", PlaceableHusbandryAnimals.getNumOfClusters)
    SpecializationUtil.registerFunction(placeableType, "getSupportsAnimalSubType", PlaceableHusbandryAnimals.getSupportsAnimalSubType)
    SpecializationUtil.registerFunction(placeableType, "getClusters", PlaceableHusbandryAnimals.getClusters)
    SpecializationUtil.registerFunction(placeableType, "getCluster", PlaceableHusbandryAnimals.getCluster)
    SpecializationUtil.registerFunction(placeableType, "getClusterById", PlaceableHusbandryAnimals.getClusterById)
    SpecializationUtil.registerFunction(placeableType, "getClusterSystem", PlaceableHusbandryAnimals.getClusterSystem)
    SpecializationUtil.registerFunction(placeableType, "getAnimalTypeIndex", PlaceableHusbandryAnimals.getAnimalTypeIndex)
    SpecializationUtil.registerFunction(placeableType, "renameAnimal", PlaceableHusbandryAnimals.renameAnimal)
    SpecializationUtil.registerFunction(placeableType, "addCluster", PlaceableHusbandryAnimals.addCluster)
    SpecializationUtil.registerFunction(placeableType, "addAnimals", PlaceableHusbandryAnimals.addAnimals)
    SpecializationUtil.registerFunction(placeableType, "updatedClusters", PlaceableHusbandryAnimals.updatedClusters)
    SpecializationUtil.registerFunction(placeableType, "consoleCommandAddAnimals", PlaceableHusbandryAnimals.consoleCommandAddAnimals)
    SpecializationUtil.registerFunction(placeableType, "getAnimalSupportsRiding", PlaceableHusbandryAnimals.getAnimalSupportsRiding)
    SpecializationUtil.registerFunction(placeableType, "getAnimalCanBeRidden", PlaceableHusbandryAnimals.getAnimalCanBeRidden)
    SpecializationUtil.registerFunction(placeableType, "startRiding", PlaceableHusbandryAnimals.startRiding)
    SpecializationUtil.registerFunction(placeableType, "onLoadedRideable", PlaceableHusbandryAnimals.onLoadedRideable)
    SpecializationUtil.registerFunction(placeableType, "getIsInAnimalDeliveryArea", PlaceableHusbandryAnimals.getIsInAnimalDeliveryArea)
    SpecializationUtil.registerFunction(placeableType, "loadDeliveryArea", PlaceableHusbandryAnimals.loadDeliveryArea)
    SpecializationUtil.registerFunction(placeableType, "getOutdoorContourPolygon", PlaceableHusbandryAnimals.getOutdoorContourPolygon)
    SpecializationUtil.registerFunction(placeableType, "createNavigationMeshPlacementCollision", PlaceableHusbandryAnimals.createNavigationMeshPlacementCollision)
    SpecializationUtil.registerFunction(placeableType, "deleteNavigationMeshPlacementCollision", PlaceableHusbandryAnimals.deleteNavigationMeshPlacementCollision)
end
function PlaceableHusbandryAnimals.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedDayChanged", PlaceableHusbandryAnimals.getNeedDayChanged)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryAnimals.updateInfo)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryAnimals.updateOutput)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableHusbandryAnimals.canBeSold)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryAnimals.getConditionInfos)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getAnimalInfos", PlaceableHusbandryAnimals.getAnimalInfos)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getAnimalDescription", PlaceableHusbandryAnimals.getAnimalDescription)
end
function PlaceableHusbandryAnimals.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryAnimals)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryAnimals)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryAnimals)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryAnimals)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryAnimals)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableHusbandryAnimals)
    SpecializationUtil.registerEventListener(placeableType, "onPeriodChanged", PlaceableHusbandryAnimals)
    SpecializationUtil.registerEventListener(placeableType, "onDayChanged", PlaceableHusbandryAnimals)
end
function PlaceableHusbandryAnimals.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    basePath = basePath .. ".husbandry.animals"
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".navigation#rootNode", "Navigation mesh rootnode")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".navigation#node", "Navigation mesh node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".navigation#shape", "Shape to generate navigation mesh from")
    schema:register(XMLValueType.STRING, basePath .. ".navigation#filename", "Filename for an external navigation mesh")
    schema:register(XMLValueType.STRING, basePath .. ".navigation#nodePath", "Nodepath for an external navigation mesh")
    schema:register(XMLValueType.STRING, basePath .. "#type", "Animal type")
    schema:register(XMLValueType.STRING, basePath .. "#filename", "Animal configuration file")
    schema:register(XMLValueType.FLOAT, basePath .. "#placementRaycastDistance", "Placement raycast distance", 2)
    schema:register(XMLValueType.INT, basePath .. "#maxNumAnimals", "Max number of animals", 16)
    schema:register(XMLValueType.INT, basePath .. "#baseMaxNumAnimals", "Base max number of animals without outoor area", 16)
    schema:register(XMLValueType.INT, basePath .. "#sqmPerAnimal", "Square meter need per animal")
    schema:register(XMLValueType.INT, basePath .. "#maxNumVisualAnimals", "Max number of visual animals")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".loadingTrigger#node", "Animal loading trigger")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".deliveryAreas.deliveryArea(?)#startNode", "Animal delivery area start node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".deliveryAreas.deliveryArea(?)#widthNode", "Animal delivery area width node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".deliveryAreas.deliveryArea(?)#heightNode", "Animal delivery area height node")
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryAnimals.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Husbandry")
    AnimalClusterSystem.registerSavegameXMLPaths(schema, basePath .. ".clusters")
    schema:setXMLSpecializationType()
end
function PlaceableHusbandryAnimals.initSpecialization()
    g_storeManager:addSpecType("numberAnimals", "shopListAttributeIconCapacity", PlaceableHusbandryAnimals.loadSpecValueNumberAnimals, PlaceableHusbandryAnimals.getSpecValueNumberAnimals, StoreSpecies.PLACEABLE)
    if g_isDevelopmentVersion then
        addConsoleCommand("gsHusbandryAddAnimals", "Add or remove animals from husbandry where player is currently located", "consoleCommandAddAnimals", PlaceableHusbandryAnimals, "numAnimals; [subTypeIndex]")
        addConsoleCommand("gsHusbandryDebugToggle", "Toggle husbandry debug mode", "consoleCommandToggleDebug", PlaceableHusbandryAnimals)
    end
end
function PlaceableHusbandryAnimals.terminateSpecialization()
    if g_isDevelopmentVersion then
        removeConsoleCommand("gsHusbandryAddAnimals")
        removeConsoleCommand("gsHusbandryDebugToggle")
    end
end
function PlaceableHusbandryAnimals:onLoad(_)
    local spec = self.spec_husbandryAnimals
    local xmlFile = self.xmlFile
    spec.infoHealth = {
        ["title"] = g_i18n:getText("ui_horseHealth"),
        ["text"] = ""
    }
    spec.infoNumAnimals = {
        ["title"] = g_i18n:getText("ui_numAnimals"),
        ["text"] = ""
    }
    spec.updateVisuals = false
    local animalTypeName = xmlFile:getValue("placeable.husbandry.animals#type")
    if animalTypeName == nil then
        Logging.xmlError(xmlFile, "Missing animal type!")
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return
    else
        spec.animalType = g_currentMission.animalSystem:getTypeByName(animalTypeName)
        if spec.animalType == nil then
            Logging.xmlError(xmlFile, "Animal type \'%s\' not found!", animalTypeName)
            self:setLoadingState(PlaceableLoadingState.ERROR)
        else
            spec.animalTypeIndex = spec.animalType.typeIndex
            spec.navigationMeshRootNode = xmlFile:getValue("placeable.husbandry.animals.navigation#rootNode", nil, self.components, self.i3dMappings)
            spec.navigationMesh = xmlFile:getValue("placeable.husbandry.animals.navigation#node", nil, self.components, self.i3dMappings)
            local navigationMeshShape = xmlFile:getValue("placeable.husbandry.animals.navigation#shape", nil, self.components, self.i3dMappings)
            if navigationMeshShape ~= nil then
                local navMeshShapeValid = true
                if not getHasClassId(navigationMeshShape, ClassIds.SHAPE) then
                    Logging.xmlError(xmlFile, "Given navigation shape %q at %q is not of type \'SHAPE\'", getName(navigationMeshShape), "placeable.husbandry.animals.navigation#shape")
                    navMeshShapeValid = false
                end
                if getHasClassId(navigationMeshShape, ClassIds.NAVIGATION_MESH) then
                    Logging.xmlError(xmlFile, "Given navigation shape %q at %q is a navigation mesh instead of a regular shape", getName(navigationMeshShape), "placeable.husbandry.animals.navigation#shape")
                    navMeshShapeValid = false
                end
                if navMeshShapeValid and not getShapeIsCPUMesh(navigationMeshShape) then
                    Logging.xmlError(xmlFile, "Given navigation shape %q at %q is missing the \'CPU Mesh\' flag", getName(navigationMeshShape), "placeable.husbandry.animals.navigation#shape")
                    navMeshShapeValid = false
                end
                if navMeshShapeValid then
                    setIsNonRenderable(navigationMeshShape, true)
                    spec.navigationMeshShape = navigationMeshShape
                end
            end
            local navMeshShapeValid = xmlFile:getValue("placeable.husbandry.animals.navigation#filename", nil)
            if navMeshShapeValid ~= nil then
                local loadingTask = Utils.getFilename(navMeshShapeValid, self.baseDirectory)
                local loadingTask = self:createLoadingTask(spec)
                spec.navigationMeshNodePath = xmlFile:getValue("placeable.husbandry.animals.navigation#nodePath", "0")
                spec.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(loadingTask, true, false, self.onExternalNavigationMeshLoaded, self, {
                    ["loadingTask"] = loadingTask
                })
            end
            spec.outdoorContourPolygon = nil
            spec.placementRaycastDistance = xmlFile:getValue("placeable.husbandry.animals#placementRaycastDistance", 10)
            spec.sqmPerAnimal = self.xmlFile:getValue("placeable.husbandry.animals#sqmPerAnimal", spec.animalType.sqmPerAnimal)
            spec.configMaxNumAnimals = xmlFile:getValue("placeable.husbandry.animals#maxNumAnimals", 16)
            spec.baseMaxNumAnimals = self.xmlFile:getValue("placeable.husbandry.animals#baseMaxNumAnimals", spec.configMaxNumAnimals)
            spec.configMaxNumVisualAnimals = self.xmlFile:getValue("placeable.husbandry.animals#maxNumVisualAnimals")
            spec.clusterHusbandry = AnimalClusterHusbandry.new(self, animalTypeName, 0)
            spec.clusterSystem = AnimalClusterSystem.new(self.isServer, self)
            g_messageCenter:subscribe(AnimalClusterUpdateEvent, self.updatedClusters, self)
            local loadingTask = xmlFile:getValue("placeable.husbandry.animals.loadingTrigger#node", nil, self.components, self.i3dMappings)
            if loadingTask ~= nil then
                spec.animalLoadingTrigger = AnimalLoadingTrigger.new(self.isServer, self.isClient)
                if not spec.animalLoadingTrigger:load(loadingTask, self) then
                    spec.animalLoadingTrigger:delete()
                end
            end
            spec.deliveryAreas = {}
            self.xmlFile:iterate("placeable.husbandry.animals.deliveryAreas.deliveryArea", function(_, key)
                -- upvalues: (copy) self, (copy) spec
                local area = {}
                if self:loadDeliveryArea(self.xmlFile, key, area) then
                    table.insert(spec.deliveryAreas, area)
                end
            end)
            spec.info = {
                ["title"] = g_i18n:getText("statistic_productivity"),
                ["text"] = ""
            }
            if not (self.isServer and g_isDevelopmentVersion) then
                removeConsoleCommand("gsHusbandryAddAnimals")
            end
        end
    end
end
function PlaceableHusbandryAnimals:onDelete()
    local spec = self.spec_husbandryAnimals
    g_messageCenter:unsubscribe(AnimalClusterUpdateEvent, self)
    g_messageCenter:unsubscribe(MessageType.CURRENT_MISSION_START, self)
    self:deleteNavigationMeshPlacementCollision()
    if spec.clusterHusbandry ~= nil then
        g_currentMission.husbandrySystem:removeClusterHusbandry(spec.clusterHusbandry)
        spec.clusterHusbandry:delete()
        spec.clusterHusbandry = nil
    end
    if spec.animalLoadingTrigger ~= nil then
        spec.animalLoadingTrigger:delete()
        spec.animalLoadingTrigger = nil
    end
    if spec.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.sharedLoadRequestId)
    end
end
function PlaceableHusbandryAnimals:onFinalizePlacement()
    self:createNavigationMesh()
    if self.isLoadedFromSavegame then
        g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, PlaceableHusbandryAnimals.onMissionStarted, self)
    end
end
function PlaceableHusbandryAnimals:onReadStream(streamId, connection)
    self.spec_husbandryAnimals.clusterSystem:readStream(streamId, connection)
end
function PlaceableHusbandryAnimals:onWriteStream(streamId, connection)
    self.spec_husbandryAnimals.clusterSystem:writeStream(streamId, connection)
end
function PlaceableHusbandryAnimals:saveToXMLFile(xmlFile, key, usedModNames)
    self.spec_husbandryAnimals.clusterSystem:saveToXMLFile(xmlFile, key .. ".clusters", usedModNames)
end
function PlaceableHusbandryAnimals:loadFromXMLFile(xmlFile, key)
    self.spec_husbandryAnimals.clusterSystem:loadFromXMLFile(xmlFile, key .. ".clusters")
end
function PlaceableHusbandryAnimals:onUpdate(dt)
    local spec = self.spec_husbandryAnimals
    if self.isServer then
        spec.clusterSystem:update(dt)
    end
    if spec.clusterHusbandry ~= nil then
        spec.clusterHusbandry:update(dt)
    end
    if spec.updateVisuals then
        self:updateVisualAnimals()
        spec.updateVisuals = false
    end
    if spec.clusterHusbandry:getNeedsUpdate() then
        self:raiseActive()
    end
end
function PlaceableHusbandryAnimals:onExternalNavigationMeshLoaded(node, _, args)
    if node == 0 or node == nil then
        self:finishLoadingTask(args.loadingTask)
        Logging.error("Missing navigation mesh in external navigation mesh file!")
    else
        if self.spec_husbandryAnimals.navigationMeshRootNode ~= nil then
            spec.navigationMesh = I3DUtil.indexToObject(node, spec.navigationMeshNodePath)
            link(spec.navigationMeshRootNode, spec.navigationMesh)
        end
        delete(node)
        self:finishLoadingTask(loadingTask)
    end
end
function PlaceableHusbandryAnimals:createNavigationMesh()
    return self:createNavigationMeshFromContour()
end
function PlaceableHusbandryAnimals:createNavigationMeshFromContour(contourPositions)
    local spec = self.spec_husbandryAnimals
    spec.outdoorContourPolygon = nil
    local outdoorAreaSqm = 0
    if contourPositions ~= nil and #contourPositions >= 9 then
        local navMeshAgentAttributes = spec.animalType.navMeshAgentAttributes or {}
        spec.outdoorContourPolygon = Polygon2D.new()
        spec.outdoorContourPolygon:setVerticesFromXYZ(contourPositions)
        outdoorAreaSqm = spec.outdoorContourPolygon:getArea()
        if PlaceableHusbandryAnimals.debugEnabled then
            local contourVertIndex = 1
            local i = 1
            for i = i, #contourPositions, 3 do
                DebugPoint.new():createWithWorldPos(contourPositions[i], 0, contourPositions[i + 2], true):setText(string.format("NM contour v%d", contourVertIndex)):addToManager("NM-Contour")
                contourVertIndex = contourVertIndex + 1
            end
        end
        local contourVertIndex = createNavMesh(string.format("PlaceableHusbandryAnimals_generatedNavMesh_%s", self.configFileNameClean or self.rootNode))
        link(spec.navigationMeshRootNode or self.rootNode, contourVertIndex)
        local i
        if spec.navigationMeshShape == nil then
            i = buildNavMeshFromContour(contourVertIndex, contourPositions, g_terrainNode, CollisionFlag.TREE + CollisionFlag.ANIMAL_NAV_MESH_BLOCKING, 0.25, 0.2, navMeshAgentAttributes.height or 1.6, navMeshAgentAttributes.radius or 0.1, navMeshAgentAttributes.maxClimbMeters or 0.9, navMeshAgentAttributes.maxSlope or 0.7853981633974483, 25, 25, 50, 1)
        else
            setShapeBuildNavMeshMask(spec.navigationMeshShape, 254)
            i = buildNavMeshFromShapesAndContour(contourVertIndex, spec.navigationMeshShape, 254, contourPositions, g_terrainNode, collisionMask, 0.25, 0.2, agentHeight, agentRadius, agentMaxClimbMeters, agentMaxSlope, 25, 25, 50, 1)
        end
        if not i then
            Logging.error("buildNavMeshFromShapesAndContour for %q failed", self.configFileName)
            delete(contourVertIndex)
            return false
        end
        if spec.navigationMesh ~= nil then
            delete(spec.navigationMesh)
        end
        spec.navigationMesh = contourVertIndex
        if spec.placementCollisionNode ~= nil then
            delete(spec.placementCollisionNode)
            spec.placementCollisionNode = nil
        end
        self:createNavigationMeshPlacementCollision(contourPositions)
    end
    self:setMaxNumAnimals(outdoorAreaSqm)
    self:createHusbandry()
    return true
end
function PlaceableHusbandryAnimals:setMaxNumAnimals(outdoorAreaSqm)
    local spec = self.spec_husbandryAnimals
    local maxNumAnimals = spec.baseMaxNumAnimals
    if outdoorAreaSqm ~= nil and spec.sqmPerAnimal ~= nil then
        maxNumAnimals = maxNumAnimals + math.floor(outdoorAreaSqm / spec.sqmPerAnimal)
    end
    local profileClass
    if spec.animalTypeIndex == AnimalType.HORSE then
        profileClass = math.min(maxNumAnimals, 16)
        maxNumAnimals = math.min(maxNumAnimals, 16)
        if GS_IS_MOBILE_VERSION then
            profileClass = math.min(profileClass, 8)
            maxNumAnimals = math.min(maxNumAnimals, 8)
        end
    else
        local profileClass = Utils.getPerformanceClassId()
        profileClass = profileClass == GS_PROFILE_VERY_LOW and 8 or ((GS_PLATFORM_XBOX or profileClass == GS_PROFILE_LOW) and 10 or (GS_PROFILE_VERY_HIGH <= profileClass and 25 or (GS_PROFILE_HIGH <= profileClass and 20 or 16)))
        if GS_IS_MOBILE_VERSION then
            profileClass = math.min(profileClass, 8)
        end
    end
    local profileClass = 2 ^ AnimalCluster.NUM_BITS_NUM_ANIMALS - 1
    local configDefinedMaxNumVisualAnimals = math.min(maxNumAnimals, profileClass)
    local configDefinedMaxNumVisualAnimals = spec.configMaxNumVisualAnimals
    if configDefinedMaxNumVisualAnimals == nil then
        configDefinedMaxNumVisualAnimals = profileClass
    else
        if spec.configMaxNumAnimals < configDefinedMaxNumVisualAnimals then
            configDefinedMaxNumVisualAnimals = spec.configMaxNumAnimals
        end
        if configDefinedMaxNumVisualAnimals >= profileClass then
            configDefinedMaxNumVisualAnimals = profileClass
        end
    end
    spec.maxNumVisualAnimals = configDefinedMaxNumVisualAnimals
    spec.maxNumAnimals = configDefinedMaxNumVisualAnimals
    spec.clusterHusbandry:setMaxNumVisualAnimals(configDefinedMaxNumVisualAnimals)
end
function PlaceableHusbandryAnimals:createHusbandry()
    local spec = self.spec_husbandryAnimals
    if spec.navigationMesh == nil then
        if self.isServer then
            Logging.xmlError(self.xmlFile, "Navigation mesh node not defined for animal husbandry!")
            printCallstack()
        end
        return
    elseif getHasClassId(spec.navigationMesh, ClassIds.NAVIGATION_MESH) then
        if getNavMeshSurfaceArea(spec.navigationMesh) == 0 then
            Logging.error("Given nav mesh %q has no surface area", getName(spec.navigationMesh))
            return
        else
            local mission = g_currentMission
            local collisionMaskFilter = CollisionMask.ANIMAL_SINGLEPLAYER
            if mission.missionDynamicInfo.isMultiplayer then
                collisionMaskFilter = CollisionMask.ANIMAL_MULTIPLAYER
            end
            mission.husbandrySystem:removeClusterHusbandry(spec.clusterHusbandry)
            local husbandryId = spec.clusterHusbandry:create(spec.animalType.configFilename, spec.navigationMesh, spec.placementRaycastDistance, collisionMaskFilter)
            if husbandryId == nil or husbandryId == 0 then
                Logging.error("Could not create animal husbandry!")
            else
                if husbandryId ~= nil then
                    mission.husbandrySystem:addClusterHusbandry(spec.clusterHusbandry)
                end
                SpecializationUtil.raiseEvent(self, "onHusbandryAnimalsCreated", husbandryId)
            end
        end
    else
        Logging.error("Given mesh node \'%s\' is not a navigation mesh!", getName(spec.navigationMesh))
        return
    end
end
function PlaceableHusbandryAnimals:getOutdoorContourPolygon()
    return self.spec_husbandryAnimals.outdoorContourPolygon
end
function PlaceableHusbandryAnimals:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_husbandryAnimals
    local health = 0
    local numAnimals = 0
    local clusters = spec.clusterSystem:getClusters()
    local numClusters = #clusters
    if numClusters > 0 then
        for _, cluster in ipairs(clusters) do

        end
        health = health / numClusters
    end
    spec.infoNumAnimals.text = string.format("%d / %d", numAnimals, self:getMaxNumOfAnimals())
    spec.infoHealth.text = string.format("%d %%", health)
    table.insert(infoTable, spec.infoNumAnimals)
    table.insert(infoTable, spec.infoHealth)
end
function PlaceableHusbandryAnimals:getNeedDayChanged(superFunc)
    return true
end
function PlaceableHusbandryAnimals:onMissionStarted(_)
    self:updateVisualAnimals()
end
function PlaceableHusbandryAnimals:updateVisualAnimals()
    local spec = self.spec_husbandryAnimals
    local clusters = spec.clusterSystem:getClusters()
    spec.clusterHusbandry:setClusters(clusters)
    self:raiseActive()
end
function PlaceableHusbandryAnimals:getAnimalTypeIndex()
    return self.spec_husbandryAnimals.animalTypeIndex
end
function PlaceableHusbandryAnimals:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
    if self.isServer then
        local clusters = self.spec_husbandryAnimals.clusterSystem:getClusters()
        for _, cluster in ipairs(clusters) do
            cluster:updateHealth(foodFactor)
        end
        self:raiseActive()
    end
    superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end
function PlaceableHusbandryAnimals:onPeriodChanged()
    if self.isServer then
        local spec = self.spec_husbandryAnimals
        local clusters = spec.clusterSystem:getClusters()
        local totalNumAnimals = self:getNumOfAnimals()
        local mission = self:getMaxNumOfAnimals() - totalNumAnimals
        local freeSlots = math.max(mission, 0)
        for _, cluster in ipairs(clusters) do
            cluster:onPeriodChanged()
            local numNewAnimals = cluster:updateReproduction()
            if numNewAnimals > 0 then
                local newCluster = math.min(freeSlots, numNewAnimals)
                if newCluster > 0 then
                    local newCluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(cluster:getSubTypeIndex())
                    newCluster.numAnimals = newCluster
                    spec.clusterSystem:addPendingAddCluster(newCluster)
                    local subType = animalSystem:getSubTypeByIndex(cluster:getSubTypeIndex())
                    if subType.statsBreedingName ~= nil then
                        g_farmManager:updateFarmStats(self:getOwnerFarmId(), subType.statsBreedingName, newCluster.numAnimals)
                    end
                end
            end
        end
        self:raiseActive()
    end
end
function PlaceableHusbandryAnimals:onDayChanged()
    if self.isServer then
        local clusters = self.spec_husbandryAnimals.clusterSystem:getClusters()
        for _, cluster in ipairs(clusters) do
            cluster:onDayChanged()
        end
    end
end
function PlaceableHusbandryAnimals:getNumOfAnimals()
    local numAnimals = 0
    local clusters = self.spec_husbandryAnimals.clusterSystem:getClusters()
    for _, cluster in ipairs(clusters) do

    end
    return numAnimals
end
function PlaceableHusbandryAnimals:getMaxNumOfAnimals()
    local spec = self.spec_husbandryAnimals
    return spec.maxNumAnimals or spec.baseMaxNumAnimals
end
function PlaceableHusbandryAnimals:getNumOfFreeAnimalSlots()
    local totalNumAnimals = self:getNumOfAnimals()
    return math.max(self:getMaxNumOfAnimals() - totalNumAnimals, 0)
end
function PlaceableHusbandryAnimals:getSupportsAnimalSubType(subTypeIndex)
    local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
    return self.spec_husbandryAnimals.animalTypeIndex == subType.typeIndex
end
function PlaceableHusbandryAnimals:getNumOfClusters()
    return #self.spec_husbandryAnimals.clusterSystem:getClusters()
end
function PlaceableHusbandryAnimals:getClusters()
    return self.spec_husbandryAnimals.clusterSystem:getClusters()
end
function PlaceableHusbandryAnimals:getCluster(index)
    return self.spec_husbandryAnimals.clusterSystem:getCluster(index)
end
function PlaceableHusbandryAnimals:getClusterById(id)
    return self.spec_husbandryAnimals.clusterSystem:getClusterById(id)
end
function PlaceableHusbandryAnimals:addCluster(cluster)
    if cluster ~= nil then
        self.spec_husbandryAnimals.clusterSystem:addPendingAddCluster(cluster)
        self:raiseActive()
    end
end
function PlaceableHusbandryAnimals:addAnimals(subTypeIndex, numAnimals, age)
    local animalSystem = g_currentMission.animalSystem
    local cluster = animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
    if cluster:getSupportsMerging() then
        cluster.numAnimals = numAnimals
        cluster.age = age
        cluster.subTypeIndex = subTypeIndex
        self:addCluster(cluster)
    else
        for i = 1, numAnimals do
            local cluster = animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
            cluster.numAnimals = 1
            cluster.age = age
            self:addCluster(cluster)
        end
    end
end
function PlaceableHusbandryAnimals:getClusterSystem()
    return self.spec_husbandryAnimals.clusterSystem
end
function PlaceableHusbandryAnimals:updatedClusters(husbandry)
    if husbandry == self then
        local spec = self.spec_husbandryAnimals
        local clusters = spec.clusterSystem:getClusters()
        SpecializationUtil.raiseEvent(self, "onHusbandryAnimalsUpdate", clusters)
        g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self)
        spec.updateVisuals = true
        self:raiseActive()
    end
end
function PlaceableHusbandryAnimals:renameAnimal(clusterId, name, noEventSend)
    AnimalNameEvent.sendEvent(self, clusterId, name, noEventSend)
    local cluster = self.spec_husbandryAnimals.clusterSystem:getClusterById(clusterId)
    if cluster ~= nil then
        cluster:setName(name)
    end
end
function PlaceableHusbandryAnimals:getAnimalSupportsRiding(clusterId)
    local cluster = self.spec_husbandryAnimals.clusterSystem:getClusterById(clusterId)
    return cluster ~= nil and cluster:getRidableFilename() ~= nil
end
function PlaceableHusbandryAnimals:getAnimalCanBeRidden(_)
    return g_currentMission.husbandrySystem:getCanAddRideable(self:getOwnerFarmId())
end
function PlaceableHusbandryAnimals:startRiding(clusterId, player)
    if self.isServer then
        local spec = self.spec_husbandryAnimals
        local cluster = spec.clusterSystem:getClusterById(clusterId)
        if cluster ~= nil then
            local x, y, z, rx, ry, rz = spec.clusterHusbandry:getAnimalPosition(clusterId)
            if x ~= nil then
                local farmId = self:getOwnerFarmId()
                local filename = cluster:getRidableFilename()
                cluster:changeNumAnimals(-1)
                spec.clusterSystem:updateNow()
                local data = VehicleLoadingData.new()
                data:setFilename(filename)
                data:setPosition(x, y, z)
                data:setRotation(rx, ry, rz)
                data:setPropertyState(VehiclePropertyState.OWNED)
                data:setOwnerFarmId(farmId)
                data:load(self.onLoadedRideable, self, {
                    ["player"] = player,
                    ["cluster"] = cluster
                })
            end
        end
    else
        g_client:getServerConnection():sendEvent(AnimalRidingEvent.new(self, clusterId, player))
    end
end
function PlaceableHusbandryAnimals:onLoadedRideable(vehicles, vehicleLoadState, arguments)
    if vehicleLoadState == VehicleLoadingState.OK and #vehicles ~= 0 then
        local spec = arguments.cluster:clone()
        spec:changeNumAnimals(1)
        vehicles[1]:setCluster(spec)
        vehicles[1]:setPlayerToEnter(arguments.player)
    else
        cluster:changeNumAnimals(1)
        self.spec_husbandryAnimals.clusterSystem:updateNow()
    end
end
function PlaceableHusbandryAnimals:loadDeliveryArea(xmlFile, key, area)
    local start = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
    if start == nil then
        Logging.xmlWarning(xmlFile, "Delivery area start node not defined for \'%s\'", key)
        return false
    end
    local width = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)
    if width == nil then
        Logging.xmlWarning(xmlFile, "Delivery area width node not defined for \'%s\'", key)
        return false
    end
    local height = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)
    if height == nil then
        Logging.xmlWarning(xmlFile, "Delivery area height node not defined for \'%s\'", key)
        return false
    end
    area.start = start
    area.width = width
    area.height = height
    return true
end
function PlaceableHusbandryAnimals:getIsInAnimalDeliveryArea(x, z)
    local spec = self.spec_husbandryAnimals
    if spec.outdoorContourPolygon ~= nil then
        return spec.outdoorContourPolygon:getIsPosInside(x, z)
    end
    for _, deliveryArea in ipairs(spec.deliveryAreas) do
        local startX, _, startZ = getWorldTranslation(deliveryArea.start)
        local widthX, _, widthZ = getWorldTranslation(deliveryArea.width)
        local heightX, _, heightZ = getWorldTranslation(deliveryArea.height)
        if MathUtil.isPointInParallelogram(x, z, startX, startZ, widthX - startX, widthZ - startZ, heightX - startX, heightZ - startZ) then
            return true
        end
    end
    if #spec.deliveryAreas == 0 then
        local inPolygon, _, pz = getWorldTranslation(self.rootNode)
        if MathUtil.vector2Length(inPolygon - x, pz - z) < 30 then
            return true
        end
    end
    return false
end
function PlaceableHusbandryAnimals.loadSpecValueNumberAnimals(xmlFile, _, _)
    return xmlFile:hasProperty("placeable.husbandry.animals") and {
        ["maxNumAnimals"] = xmlFile:getInt("placeable.husbandry.animals#maxNumAnimals", 16),
        ["animalTypeName"] = xmlFile:getString("placeable.husbandry.animals#type")
    } or nil
end
function PlaceableHusbandryAnimals.getSpecValueNumberAnimals(storeItem, _)
    local data = storeItem.specs.numberAnimals
    if data == nil then
        return nil
    end
    local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexByName(data.animalTypeName)
    return data.maxNumAnimals, animalTypeIndex == AnimalType.COW and "shopListAttributeIconCow" or (animalTypeIndex == AnimalType.SHEEP and "shopListAttributeIconSheep" or (animalTypeIndex == AnimalType.HORSE and "shopListAttributeIconHorse" or (animalTypeIndex == AnimalType.PIG and "shopListAttributeIconPig" or (animalTypeIndex == AnimalType.CHICKEN and "shopListAttributeIconChicken" or nil))))
end
function PlaceableHusbandryAnimals:canBeSold(superFunc)
    if self:getNumOfAnimals() > 0 then
        return false, g_i18n:getText("info_husbandryNotEmpty")
    else
        return superFunc(self)
    end
end
function PlaceableHusbandryAnimals:getConditionInfos(superFunc)
    local infos = superFunc(self)
    local animalTypeIndex = self:getAnimalTypeIndex()
    if animalTypeIndex ~= AnimalType.HORSE and animalTypeIndex ~= AnimalType.PIG then
        local productivity = self:getGlobalProductionFactor() * self:getProductionFactor()
        self.spec_husbandryAnimals.info.value = productivity
        spec.info.ratio = productivity
        spec.info.valueText = string.format("%s %%", g_i18n:formatNumber(productivity * 100, 0))
        table.insert(infos, spec.info)
    end
    return infos
end
function PlaceableHusbandryAnimals:getAnimalInfos(superFunc, cluster)
    local infos = superFunc(self)
    cluster:addInfos(infos)
    return infos
end
function PlaceableHusbandryAnimals:getAnimalDescription(superFunc, cluster)
    return superFunc(self, cluster) .. g_currentMission.animalSystem:getVisualByAge(cluster.subTypeIndex, cluster:getAge()).store.description
end
function PlaceableHusbandryAnimals:createNavigationMeshPlacementCollision(contourPositions3D)
    local spec = self.spec_husbandryAnimals
    local minX = math.huge
    local maxX = -math.huge
    local minZ = math.huge
    local maxZ = -math.huge
    local maxY = -math.huge
    local contour2D = table.create(#contourPositions3D * 2 / 3)
    local i = 1
    for i = i, #contourPositions3D, 3 do
        contour2D[#contour2D + 1] = contourPositions3D[i]
        contour2D[#contour2D + 1] = contourPositions3D[i + 2]
        minX = math.min(contourPositions3D[i], minX)
        maxX = math.max(contourPositions3D[i], maxX)
        minZ = math.min(contourPositions3D[i + 2], minZ)
        maxZ = math.max(contourPositions3D[i + 2], maxZ)
        maxY = math.max(maxY, contourPositions3D[i + 1])
    end
    if createPlaneShapeFrom2DContour("husbandryPlacementCol", contour2D, true) == 0 then
        Logging.error("Unable to create husbandry placement collision shape")
        DebugUtil.printListAsTriples(contourPositions3D)
        return false
    end
    self:deleteNavigationMeshPlacementCollision()
    setIsNonRenderable(placementCol, true)
    removeFromPhysics(placementCol)
    local x, i, z = getWorldTranslation(placementCol)
    link(self.rootNode, placementCol)
    setWorldTranslation(placementCol, x, maxY, z)
    setWorldRotation(placementCol, 0, 0, 0)
    setRigidBodyType(placementCol, RigidBodyType.STATIC)
    setCollisionFilter(placementCol, CollisionFlag.PLACEMENT_BLOCKING, 1)
    addToPhysics(placementCol)
    spec.placementCollisionNode = placementCol
    spec.placementCollisionArea = {
        minX,
        minZ,
        maxX,
        maxZ
    }
    g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
    g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
    return true
end
function PlaceableHusbandryAnimals:deleteNavigationMeshPlacementCollision()
    local spec = self.spec_husbandryAnimals
    if spec.placementCollisionNode ~= nil then
        delete(spec.placementCollisionNode)
        spec.placementCollisionNode = nil
        local minX, minZ, maxX, maxZ = unpack(spec.placementCollisionArea)
        g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
        g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
    end
end
function PlaceableHusbandryAnimals.consoleCommandAddAnimals(_, numAnimals, subTypeIndex)
    local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
    raycastAll(x, y + 100, z, 0, -1, 0, 110, "consoleCommandAddAnimalsRaycastCallback", PlaceableHusbandryAnimals, CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING + CollisionFlag.ANIMAL_POSITIONING + CollisionFlag.GROUND_TIP_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.TRIGGER)
    local husbandryInstance = PlaceableHusbandryAnimals.consoleCommandCurrentHusbandry
    PlaceableHusbandryAnimals.consoleCommandCurrentHusbandry = nil
    if husbandryInstance == nil then
        return "Error: No husbandry found. Enter a husbandry with the player first"
    end
    local spec = husbandryInstance.spec_husbandryAnimals
    numAnimals = tonumber(numAnimals) or 0
    local globalSubTypeIndex = tonumber(subTypeIndex)
    if numAnimals <= 0 then
        if numAnimals >= 0 then
            return "Error: Invalid number of animals\nUsage: gsHusbandryAddAnimals numAnimals [subTypeIndex]\nUse negative number to remove animals"
        end
        for _, cluster in pairs(husbandryInstance:getClusters()) do
            if globalSubTypeIndex == nil or cluster:getSubTypeIndex() == globalSubTypeIndex then
                numAnimals = cluster:changeNumAnimals(numAnimals)
            end
            if numAnimals >= 0 then
                break
            end
        end
        if numAnimals == numAnimals then
            return globalSubTypeIndex == nil and "Error: Husbandry has no animals" or "Error: Husbandry has no animals of subtype " .. globalSubTypeIndex
        end
        return string.format("Removed %d animal(s)", (math.abs(numAnimals - numAnimals)))
    end
    if husbandryInstance:getNumOfFreeAnimalSlots() == 0 then
        return "Error: Husbandry is full"
    end
    local globalSubTypeIndex = math.min(numAnimals, husbandryInstance:getNumOfFreeAnimalSlots())
    subTypeIndex = tonumber(globalSubTypeIndex) or 1
    local globalSubTypeIndex = spec.animalType.subTypes[subTypeIndex]
    if globalSubTypeIndex == nil then
        return "Error: Invalid subtype index\nUsage: gsHusbandryAddAnimals numAnimals [subTypeIndex]\nUse negative number to remove animals"
    end
    local newCluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(globalSubTypeIndex)
    newCluster.numAnimals = globalSubTypeIndex
    spec.clusterSystem:addPendingAddCluster(newCluster)
    husbandryInstance:raiseActive()
    return "Added " .. globalSubTypeIndex .. " animal(s)"
end
function PlaceableHusbandryAnimals.consoleCommandAddAnimalsRaycastCallback(_, actorId, _, _, _, _, _, _, _, _, _, _)
    if actorId ~= 0 then
        local object = g_currentMission:getNodeObject(actorId)
        if object ~= nil and (object:isa(Placeable) and SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, object.specializations)) then
            PlaceableHusbandryAnimals.consoleCommandCurrentHusbandry = object
            return false
        end
    end
    return true
end
function PlaceableHusbandryAnimals.consoleCommandToggleDebug()
    PlaceableHusbandryAnimals.debugEnabled = not PlaceableHusbandryAnimals.debugEnabled
    executeConsoleCommand(string.format("showNavMesh %s", PlaceableHusbandryAnimals.debugEnabled), false)
    if not PlaceableHusbandryAnimals.debugEnabled then
        g_debugManager:removeGroup("NM-Contour")
        g_debugManager:removeGroup("PlaceableHusbandryMeadow")
    end
    return string.format("PlaceableHusbandryAnimals.debugEnabled=%s", PlaceableHusbandryAnimals.debugEnabled)
end