LivestockTrailer = {}
source("dataS/scripts/vehicles/specializations/activatables/LivestockTrailerActivatable.lua")
function LivestockTrailer.initSpecialization()
    g_storeManager:addSpecType("numAnimalsCow", "shopListAttributeIconCow", LivestockTrailer.loadSpecValueNumberAnimalsCow, LivestockTrailer.getSpecValueNumberAnimalsCow, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("numAnimalsPig", "shopListAttributeIconPig", LivestockTrailer.loadSpecValueNumberAnimalsPig, LivestockTrailer.getSpecValueNumberAnimalsPig, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("numAnimalsSheep", "shopListAttributeIconSheep", LivestockTrailer.loadSpecValueNumberAnimalsSheep, LivestockTrailer.getSpecValueNumberAnimalsSheep, StoreSpecies.VEHICLE)
    g_storeManager:addSpecType("numAnimalsHorse", "shopListAttributeIconHorse", LivestockTrailer.loadSpecValueNumberAnimalsHorse, LivestockTrailer.getSpecValueNumberAnimalsHorse, StoreSpecies.VEHICLE)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("LivestockTrailer")
    schema:register(XMLValueType.STRING, "vehicle.livestockTrailer.animal(?)#type", "Animal type name")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.livestockTrailer.animal(?)#node", "Animal node")
    schema:register(XMLValueType.INT, "vehicle.livestockTrailer.animal(?)#numSlots", "Number of slots")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.livestockTrailer.loadTrigger#node", "Load trigger node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.livestockTrailer.spawnPlaces.spawnPlace(?)#node", "Unload spawn places")
    schema:register(XMLValueType.FLOAT, "vehicle.livestockTrailer.spawnPlaces.spawnPlace(?)#width", "Unloading width", 15)
    schema:setXMLSpecializationType()
    local savegameSchema = Vehicle.xmlSchemaSavegame
    savegameSchema:register(XMLValueType.STRING, "vehicles.vehicle(?).livestockTrailer#animalType", "Animal type name")
    AnimalClusterSystem.registerSavegameXMLPaths(savegameSchema, "vehicles.vehicle(?).livestockTrailer")
end
function LivestockTrailer.prerequisitesPresent(specializations)
    return true
end
function LivestockTrailer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentAnimalType", LivestockTrailer.getCurrentAnimalType)
    SpecializationUtil.registerFunction(vehicleType, "getSupportsAnimalType", LivestockTrailer.getSupportsAnimalType)
    SpecializationUtil.registerFunction(vehicleType, "getSupportsAnimalSubType", LivestockTrailer.getSupportsAnimalSubType)
    SpecializationUtil.registerFunction(vehicleType, "setLoadingTrigger", LivestockTrailer.setLoadingTrigger)
    SpecializationUtil.registerFunction(vehicleType, "getLoadingTrigger", LivestockTrailer.getLoadingTrigger)
    SpecializationUtil.registerFunction(vehicleType, "updateAnimals", LivestockTrailer.updateAnimals)
    SpecializationUtil.registerFunction(vehicleType, "updatedClusters", LivestockTrailer.updatedClusters)
    SpecializationUtil.registerFunction(vehicleType, "clearAnimals", LivestockTrailer.clearAnimals)
    SpecializationUtil.registerFunction(vehicleType, "addAnimals", LivestockTrailer.addAnimals)
    SpecializationUtil.registerFunction(vehicleType, "addCluster", LivestockTrailer.addCluster)
    SpecializationUtil.registerFunction(vehicleType, "getClusters", LivestockTrailer.getClusters)
    SpecializationUtil.registerFunction(vehicleType, "getRideablesInTrigger", LivestockTrailer.getRideablesInTrigger)
    SpecializationUtil.registerFunction(vehicleType, "getClusterById", LivestockTrailer.getClusterById)
    SpecializationUtil.registerFunction(vehicleType, "getClusterSystem", LivestockTrailer.getClusterSystem)
    SpecializationUtil.registerFunction(vehicleType, "getNumOfAnimals", LivestockTrailer.getNumOfAnimals)
    SpecializationUtil.registerFunction(vehicleType, "getMaxNumOfAnimals", LivestockTrailer.getMaxNumOfAnimals)
    SpecializationUtil.registerFunction(vehicleType, "getNumOfFreeAnimalSlots", LivestockTrailer.getNumOfFreeAnimalSlots)
    SpecializationUtil.registerFunction(vehicleType, "onAnimalLoaded", LivestockTrailer.onAnimalLoaded)
    SpecializationUtil.registerFunction(vehicleType, "onAnimalLoadTriggerCallback", LivestockTrailer.onAnimalLoadTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "getAnimalUnloadPlaces", LivestockTrailer.getAnimalUnloadPlaces)
    SpecializationUtil.registerFunction(vehicleType, "setAnimalScreenController", LivestockTrailer.setAnimalScreenController)
    SpecializationUtil.registerFunction(vehicleType, "onAnimalRideableDeleted", LivestockTrailer.onAnimalRideableDeleted)
end
function LivestockTrailer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", LivestockTrailer.getAdditionalComponentMass)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSellPrice", LivestockTrailer.getSellPrice)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "dayChanged", LivestockTrailer.dayChanged)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "periodChanged", LivestockTrailer.periodChanged)
end
function LivestockTrailer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", LivestockTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", LivestockTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", LivestockTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", LivestockTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", LivestockTrailer)
end
function LivestockTrailer:onLoad(_)
    local spec = self.spec_livestockTrailer
    spec.animalPlaces = {}
    spec.animalTypeIndexToPlaces = {}
    local i = 0
    while true do
        local key = string.format("vehicle.livestockTrailer.animal(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local place = {
            ["numUsed"] = 0
        }
        local animalTypeStr = self.xmlFile:getValue(key .. "#type")
        local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexByName(animalTypeStr)
        if animalTypeIndex == nil then
            Logging.xmlWarning(self.xmlFile, "Animal type \'%s\' could not be found!", animalTypeStr)
            break
        end
        place.animalTypeIndex = animalTypeIndex
        place.slots = {}
        local parent = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        local numSlots = math.abs((self.xmlFile:getValue(key .. "#numSlots", 0)))
        if getNumOfChildren(parent) < numSlots then
            Logging.xmlWarning(self.xmlFile, "numSlots is greater than available children for \'%s\'", key)
            numSlots = getNumOfChildren(parent)
        end
        local j = 0
        for j = j, numSlots - 1 do
            local slotNode = getChildAt(parent, j)
            table.insert(place.slots, {
                ["linkNode"] = slotNode,
                ["loadedMesh"] = nil,
                ["place"] = place
            })
        end
        table.insert(spec.animalPlaces, place)
        spec.animalTypeIndexToPlaces[place.animalTypeIndex] = place
        i = i + 1
    end
    local key = self.xmlFile:getValue("vehicle.livestockTrailer.loadTrigger#node", nil, self.components, self.i3dMappings)
    if key ~= nil then
        addTrigger(key, "onAnimalLoadTriggerCallback", self)
        spec.triggerNode = key
    end
    spec.rideablesInTrigger = {}
    spec.spawnPlaces = {}
    self.xmlFile:iterate("vehicle.livestockTrailer.spawnPlaces.spawnPlace", function(_, key)
        -- upvalues: (copy) self, (copy) spec
        local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        local width = self.xmlFile:getValue(key .. "#width", 5)
        if node ~= nil then
            table.insert(spec.spawnPlaces, {
                ["node"] = node,
                ["width"] = width
            })
        end
    end)
    if #spec.spawnPlaces > 0 or spec.triggerNode ~= nil then
        spec.activatable = LivestockTrailerActivatable.new(self)
        if g_currentMission ~= nil then
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
        end
    end
    spec.clusterSystem = AnimalClusterSystem.new(self.isServer, self)
    g_messageCenter:subscribe(AnimalClusterUpdateEvent, self.updatedClusters, self)
    spec.loadingTrigger = nil
    spec.animalScreenController = nil
    if g_currentMission ~= nil then
        g_currentMission.husbandrySystem:addLivestockTrailer(self)
    end
end
function LivestockTrailer:onLoadFinished(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local spec = self.spec_livestockTrailer
        spec.clusterSystem:loadFromXMLFile(savegame.xmlFile, savegame.key .. ".livestockTrailer")
        spec.clusterSystem:updateNow()
    end
end
function LivestockTrailer:onDelete()
    self:clearAnimals()
    g_messageCenter:unsubscribe(AnimalClusterUpdateEvent, self)
    if g_currentMission ~= nil then
        g_currentMission.husbandrySystem:removeLivestockTrailer(self)
    end
    local spec = self.spec_livestockTrailer
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
    end
    if spec.activatable ~= nil then
        g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    end
    if spec.rideablesInTrigger ~= nil then
        for _, vehicle in ipairs(spec.rideablesInTrigger) do
            vehicle:removeDeleteListener(self, "onAnimalRideableDeleted")
        end
        table.clear(spec.rideablesInTrigger)
    end
    if spec.loadingTrigger ~= nil then
        spec.loadingTrigger:setLoadingTrailer(nil)
        spec.loadingTrigger = nil
    end
end
function LivestockTrailer:saveToXMLFile(xmlFile, key, usedModNames)
    self.spec_livestockTrailer.clusterSystem:saveToXMLFile(xmlFile, key, usedModNames)
end
function LivestockTrailer:onReadStream(streamId, connection)
    self.spec_livestockTrailer.clusterSystem:readStream(streamId, connection)
end
function LivestockTrailer:onWriteStream(streamId, connection)
    self.spec_livestockTrailer.clusterSystem:writeStream(streamId, connection)
end
function LivestockTrailer:getSupportsAnimalType(animalTypeIndex)
    return self.spec_livestockTrailer.animalTypeIndexToPlaces[animalTypeIndex] ~= nil
end
function LivestockTrailer:getSupportsAnimalSubType(subTypeIndex)
    local animalSystem = g_currentMission.animalSystem
    return self:getSupportsAnimalType(animalSystem:getTypeByIndex(animalSystem:getSubTypeByIndex(subTypeIndex).typeIndex).typeIndex)
end
function LivestockTrailer:getCurrentAnimalType()
    local clusters = self.spec_livestockTrailer.clusterSystem:getClusters()
    if #clusters == 0 then
        return nil
    end
    local animalSystem = g_currentMission.animalSystem
    return animalSystem:getTypeByIndex(animalSystem:getSubTypeByIndex((clusters[1]:getSubTypeIndex())).typeIndex)
end
function LivestockTrailer:setLoadingTrigger(trigger)
    self.spec_livestockTrailer.loadingTrigger = trigger
end
function LivestockTrailer:getLoadingTrigger()
    return self.spec_livestockTrailer.loadingTrigger
end
function LivestockTrailer:setAnimalScreenController(controller)
    self.spec_livestockTrailer.animalScreenController = controller
end
function LivestockTrailer:addAnimals(subTypeIndex, numAnimals, age)
    local cluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
    if cluster:getSupportsMerging() then
        cluster.numAnimals = numAnimals
        cluster.age = age
        self:addCluster(cluster)
    else
        local i = 1
        for i = i, numAnimals do
            if i > 1 then
                cluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
            end
            cluster.numAnimals = 1
            cluster.age = age
            self:addCluster(cluster)
        end
    end
end
function LivestockTrailer:addCluster(cluster)
    local spec = self.spec_livestockTrailer
    spec.clusterSystem:addPendingAddCluster(cluster)
    spec.clusterSystem:updateNow()
end
function LivestockTrailer:getClusters()
    return self.spec_livestockTrailer.clusterSystem:getClusters()
end
function LivestockTrailer:getRideablesInTrigger()
    return self.spec_livestockTrailer.rideablesInTrigger
end
function LivestockTrailer:getClusterById(id)
    return self.spec_livestockTrailer.clusterSystem:getClusterById(id)
end
function LivestockTrailer:getClusterSystem()
    return self.spec_livestockTrailer.clusterSystem
end
function LivestockTrailer:getNumOfAnimals()
    local spec = self.spec_livestockTrailer
    local clusters = spec.clusterSystem:getClusters()
    if #clusters == 0 then
        return 0
    end
    local subTypeIndex = clusters[1]:getSubTypeIndex()
    local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
    return spec.animalTypeIndexToPlaces[subType.typeIndex].usedSlots or 0
end
function LivestockTrailer:getMaxNumOfAnimals(animalType)
    local currentAnimalType = self:getCurrentAnimalType()
    if animalType == nil and currentAnimalType == nil then
        return 0
    end
    if currentAnimalType ~= nil and animalType ~= currentAnimalType then
        return 0
    end
    animalType = animalType or currentAnimalType
    return self:getSupportsAnimalType(animalType.typeIndex) and #self.spec_livestockTrailer.animalTypeIndexToPlaces[animalType.typeIndex].slots or 0
end
function LivestockTrailer:getNumOfFreeAnimalSlots(subTypeIndex)
    local animalSystem = g_currentMission.animalSystem
    local animalType = animalSystem:getTypeByIndex(animalSystem:getSubTypeByIndex(subTypeIndex).typeIndex)
    local used = self:getNumOfAnimals()
    return self:getMaxNumOfAnimals(animalType) - used
end
function LivestockTrailer:updatedClusters(trailer)
    if trailer == self then
        self:updateAnimals()
        self:setMassDirty()
    end
end
function LivestockTrailer:updateAnimals()
    local spec = self.spec_livestockTrailer
    self:clearAnimals()
    local slotIndex = 1
    local clusters = spec.clusterSystem:getClusters()
    local animalType = self:getCurrentAnimalType()
    if animalType ~= nil then
        local place = spec.animalTypeIndexToPlaces[animalType.typeIndex]
        place.usedSlots = 0
        for _, cluster in ipairs(clusters) do
            local slot = cluster:getNumAnimals()
            for i = 1, slot do
                local slot = place.slots[slotIndex]
                slot.meshLoadingInProgress = true
                local visual = g_currentMission.animalSystem:getVisualByAge(cluster:getSubTypeIndex(), cluster:getAge())
                local filename = visual.visualAnimal.filenamePosed
                slot.filename = filename
                slot.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.onAnimalLoaded, self, {
                    ["slot"] = slot,
                    ["visual"] = visual
                })
                slotIndex = slotIndex + 1
                place.usedSlots = place.usedSlots + 1
            end
        end
    end
end
function LivestockTrailer:clearAnimals()
    local spec = self.spec_livestockTrailer
    if spec.animalTypeIndexToPlaces ~= nil then
        for _, place in pairs(spec.animalTypeIndexToPlaces) do
            for _, slot in ipairs(place.slots) do
                if slot.sharedLoadRequestId ~= nil then
                    g_i3DManager:releaseSharedI3DFile(slot.sharedLoadRequestId)
                    slot.sharedLoadRequestId = nil
                end
                if slot.loadedMesh ~= nil then
                    delete(slot.loadedMesh)
                    slot.loadedMesh = nil
                end
            end
        end
    end
end
function LivestockTrailer.onAnimalLoaded(_, i3dNode, _, args)
    if i3dNode ~= 0 then
        local slot = args.slot
        link(slot.linkNode, i3dNode)
        slot.loadedMesh = i3dNode
        slot.meshLoadingInProgress = false
        local variations = args.visual.visualAnimal.variations[1]
        I3DUtil.setShaderParameterRec(i3dNode, "atlasInvSizeAndOffsetUV", 1 / variations.numTilesU, 1 / variations.numTilesV, variations.tileUIndex / variations.numTilesU, variations.tileVIndex / variations.numTilesV)
        I3DUtil.setShaderParameterRec(i3dNode, "dirt", 0, nil, nil, nil)
    end
end
function LivestockTrailer:getAdditionalComponentMass(superFunc, component)
    local additionalMass = superFunc(self, component)
    local clusters = self.spec_livestockTrailer.clusterSystem:getClusters()
    for _, cluster in ipairs(clusters) do
        local subTypeIndex = cluster:getSubTypeIndex()
        local fillTypeIndex = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex).fillTypeIndex
        additionalMass = additionalMass + g_fillTypeManager:getFillTypeByIndex(fillTypeIndex).massPerLiter * cluster:getNumAnimals()
    end
    return additionalMass
end
function LivestockTrailer:getSellPrice(superFunc)
    local sellPrice = superFunc(self)
    local clusters = self.spec_livestockTrailer.clusterSystem:getClusters()
    for _, cluster in ipairs(clusters) do
        sellPrice = sellPrice + cluster:getSellPrice() * cluster:getNumAnimals() * 0.75
    end
    return sellPrice
end
function LivestockTrailer:dayChanged(superFunc)
    superFunc(self)
    local clusters = self.spec_livestockTrailer.clusterSystem:getClusters()
    for _, cluster in ipairs(clusters) do
        cluster:onDayChanged()
    end
end
function LivestockTrailer:periodChanged(superFunc)
    superFunc(self)
    local clusters = self.spec_livestockTrailer.clusterSystem:getClusters()
    for _, cluster in ipairs(clusters) do
        cluster:onPeriodChanged()
    end
end
function LivestockTrailer:onAnimalLoadTriggerCallback(_, otherId, onEnter, onLeave, _)
    if onEnter or onLeave then
        local vehicle = g_currentMission.nodeToObject[otherId]
        if vehicle ~= nil and vehicle.spec_rideable ~= nil then
            local cluster = vehicle:getCluster()
            if cluster ~= nil and self:getSupportsAnimalSubType((cluster:getSubTypeIndex())) then
                if onEnter then
                    table.addElement(self.spec_livestockTrailer.rideablesInTrigger, vehicle)
                    vehicle:addDeleteListener(self, "onAnimalRideableDeleted")
                else
                    table.removeElement(spec.rideablesInTrigger, vehicle)
                    vehicle:removeDeleteListener(self, "onAnimalRideableDeleted")
                end
                if spec.animalScreenController ~= nil then
                    spec.animalScreenController:onAnimalsChanged(self, nil)
                end
            end
        end
    end
end
function LivestockTrailer:onAnimalRideableDeleted(rideable)
    local spec = self.spec_livestockTrailer
    table.removeElement(spec.rideablesInTrigger, rideable)
    if spec.animalScreenController ~= nil then
        spec.animalScreenController:onAnimalsChanged(self, nil)
    end
end
function LivestockTrailer:getAnimalUnloadPlaces()
    local places = {}
    for _, spawnPlace in ipairs(self.spec_livestockTrailer.spawnPlaces) do
        local node = spawnPlace.node
        local x, y, z = getWorldTranslation(node)
        local place = {
            ["startX"] = x,
            ["startY"] = y,
            ["startZ"] = z
        }
        place.rotX, place.rotY, place.rotZ = getWorldRotation(node)
        place.dirX, place.dirY, place.dirZ = localDirectionToWorld(node, 1, 0, 0)
        place.dirPerpX, place.dirPerpY, place.dirPerpZ = localDirectionToWorld(node, 0, 0, 1)
        place.yOffset = 1
        place.maxWidth = math.huge
        place.maxLength = math.huge
        place.maxHeight = math.huge
        place.width = spawnPlace.width
        table.insert(places, place)
    end
    return places
end
function LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, _, _, animalTypeName)
    local i = 0
    local root = xmlFile:getRootName()
    while true do
        local key = string.format("%s.livestockTrailer.animal(%d)", root, i)
        if not xmlFile:hasProperty(key) then
            break
        end
        local typeName = xmlFile:getValue(key .. "#type")
        if typeName ~= nil and string.lower(typeName) == string.lower(animalTypeName) then
            return xmlFile:getValue(key .. "#numSlots", 0)
        end
        i = i + 1
    end
    return nil
end
function LivestockTrailer.loadSpecValueNumberAnimalsCow(xmlFile, customEnvironment, baseDir)
    return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, baseDir, "cow")
end
function LivestockTrailer.loadSpecValueNumberAnimalsPig(xmlFile, customEnvironment, baseDir)
    return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, baseDir, "pig")
end
function LivestockTrailer.loadSpecValueNumberAnimalsSheep(xmlFile, customEnvironment, baseDir)
    return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, baseDir, "sheep")
end
function LivestockTrailer.loadSpecValueNumberAnimalsHorse(xmlFile, customEnvironment, baseDir)
    return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, baseDir, "horse")
end
function LivestockTrailer.getSpecValueNumberAnimals(storeItem, _, specName)
    if storeItem.specs[specName] == nil then
        return nil
    else
        return string.format("%d %s", storeItem.specs[specName], g_i18n:getText("unit_pieces"))
    end
end
function LivestockTrailer.getSpecValueNumberAnimalsCow(storeItem, realItem)
    return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsCow")
end
function LivestockTrailer.getSpecValueNumberAnimalsPig(storeItem, realItem)
    return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsPig")
end
function LivestockTrailer.getSpecValueNumberAnimalsSheep(storeItem, realItem)
    return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsSheep")
end
function LivestockTrailer.getSpecValueNumberAnimalsHorse(storeItem, realItem)
    return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsHorse")
end