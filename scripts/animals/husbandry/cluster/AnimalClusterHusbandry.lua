AnimalClusterHusbandry = {}
local AnimalClusterHusbandry_mt = Class(AnimalClusterHusbandry)
function AnimalClusterHusbandry.new(placeable, animalTypeName, maxVisualAnimals, customMt)
    -- upvalues: (copy) AnimalClusterHusbandry_mt
    local self = setmetatable({}, customMt or AnimalClusterHusbandry_mt)
    self.placeable = placeable
    self.husbandryId = nil
    self.navigationNode = nil
    self.maxVisualAnimals = maxVisualAnimals
    self.animalTypeName = animalTypeName
    self.animalSystem = g_currentMission.animalSystem
    self.animalIdToCluster = {}
    self.animalIdToVisualAnimalIndex = {}
    self.totalNumAnimalsPerVisualAnimalIndex = {}
    g_soundManager:addIndoorStateChangedListener(self)
    return self
end
function AnimalClusterHusbandry:delete()
    g_soundManager:removeIndoorStateChangedListener(self)
    self:deleteHusbandry()
end
function AnimalClusterHusbandry:deleteHusbandry()
    if self.husbandryId ~= nil then
        for animalId, _ in pairs(self.animalIdToCluster) do
            removeHusbandryAnimal(self.husbandryId, animalId)
        end
        delete(self.husbandryId)
        self.husbandryId = nil
    end
end
function AnimalClusterHusbandry:update(_)
    if self.husbandryId ~= nil then
        setAnimalDaytime(self.husbandryId, g_currentMission.environment.dayTime)
        if self.visualUpdatePending and isHusbandryReady(self.husbandryId) then
            self:updateVisuals()
            self.visualUpdatePending = false
        end
    end
end
function AnimalClusterHusbandry:setMaxNumVisualAnimals(maxNum)
    self.maxVisualAnimals = maxNum
    self.visualUpdatePending = true
end
function AnimalClusterHusbandry:getNeedsUpdate()
    return self.visualUpdatePending
end
function AnimalClusterHusbandry:create(xmlFilename, navigationNode, raycastDistance, collisionMask)
    if self.husbandryId ~= nil then
        self:deleteHusbandry()
    end
    self.navigationNode = navigationNode
    local husbandryId = createAnimalHusbandry(self.animalTypeName, navigationNode, xmlFilename, raycastDistance, CollisionMask.ANIMAL_POSITIONING, collisionMask, AudioGroup.ENVIRONMENT)
    if husbandryId == 0 then
        Logging.error("Failed to create animal husbandry for %q with navigation mesh %q and config %q", self.animalTypeName, I3DUtil.getNodePath(navigationNode), xmlFilename)
        return nil
    end
    self.husbandryId = husbandryId
    self.visualUpdatePending = true
    self:onIndoorStateChanged()
    return self.husbandryId
end
function AnimalClusterHusbandry:getPlaceable()
    return self.placeable
end
function AnimalClusterHusbandry:updateVisuals()
    if self.husbandryId == nil or not isHusbandryReady(self.husbandryId) then
        self.visualUpdatePending = true
        return
    end
    self.totalNumAnimalsPerVisualAnimalIndex = {}
    local clusterToNumAnimals = {}
    local newAnimalMapping = {}
    local newAnimalIdToVisualAnimalIndex = {}
    local groupedClusters = {}
    local totalNumAnimals = 0
    for _, cluster in ipairs(self.nextUpdateClusters or {}) do
        local numAnimals = cluster:getNumAnimals()
        if numAnimals > 0 then
            local visualAnimalIndex = self.animalSystem:getVisualAnimalIndexByAge(cluster:getSubTypeIndex(), (cluster:getAge()));
            ({})[cluster] = visualAnimalIndex
            local index = ({})[visualAnimalIndex]
            if index == nil then
                table.insert(groupedClusters, {
                    ["visualAnimalIndex"] = visualAnimalIndex,
                    ["numAnimals"] = 0,
                    ["clusters"] = {},
                    ["minClusterId"] = math.huge
                })
                visualAnimalIndexToDataIndex[visualAnimalIndex] = #groupedClusters
            end
            local data = groupedClusters[index]
            data.numAnimals = data.numAnimals + numAnimals
            data.minClusterId = math.min(cluster.id, data.minClusterId)
            table.insert(data.clusters, cluster)
            self.totalNumAnimalsPerVisualAnimalIndex[visualAnimalIndex] = (self.totalNumAnimalsPerVisualAnimalIndex[visualAnimalIndex] or 0) + numAnimals
        end
    end
    table.sort(groupedClusters, function(a, b)
        if a.numAnimals == b.numAnimals then
            return a.minClusterId < b.minClusterId
        else
            return a.numAnimals > b.numAnimals
        end
    end)
    for _, cluster in ipairs(groupedClusters) do
        table.sort(cluster.clusters, AnimalClusterHusbandry.sortClusters)
    end
    local freeSlots = #groupedClusters
    local exclusiveSlots = math.min(freeSlots, self.maxVisualAnimals)
    local freeSlots = self.maxVisualAnimals - exclusiveSlots
    for numAnimals, subTypeIndex in ipairs(groupedClusters) do
        local age = 0
        if exclusiveSlots > 0 then
            age = 1
        end
        if freeSlots > 0 then
            local data = math.ceil(self.totalNumAnimalsPerVisualAnimalIndex[subTypeIndex.visualAnimalIndex] / totalNumAnimals * freeSlots)
            local index = math.min(data, freeSlots, subTypeIndex.numAnimals - 1)
            freeSlots = freeSlots - index
        end
        local visualAnimalIndex = 1
        while age > 0 do
            local visualAnimalIndex = #subTypeIndex.clusters < visualAnimalIndex and 1 or visualAnimalIndex
            local index = subTypeIndex.clusters[visualAnimalIndex]
            if clusterToNumAnimals[index] == nil then
                clusterToNumAnimals[index] = 0
            end
            if clusterToNumAnimals[index] < index.numAnimals then
                clusterToNumAnimals[index] = clusterToNumAnimals[index] + 1
                age = age - 1
            end
            visualAnimalIndex = visualAnimalIndex + 1
        end
        if exclusiveSlots == 0 and freeSlots == 0 then
            break
        end
    end
    for numAnimals, subTypeIndex in pairs(self.animalIdToCluster) do
        if clusterToNumAnimals[subTypeIndex] ~= nil then
            local visualAnimalIndex = clusterToVisualAnimalIndex[subTypeIndex]
            if self.animalIdToVisualAnimalIndex[numAnimals] ~= visualAnimalIndex then
                setAnimalSubType(self.husbandryId, numAnimals, visualAnimalIndex - 1)
            end
            clusterToNumAnimals[subTypeIndex] = clusterToNumAnimals[subTypeIndex] - 1
            if clusterToNumAnimals[subTypeIndex] <= 0 then
                clusterToNumAnimals[subTypeIndex] = nil
            end
            newAnimalMapping[numAnimals] = subTypeIndex
            newAnimalIdToVisualAnimalIndex[numAnimals] = visualAnimalIndex
            self.animalIdToCluster[numAnimals] = nil
            self.animalIdToVisualAnimalIndex[numAnimals] = nil
        end
    end
    for numAnimals, subTypeIndex in pairs(clusterToNumAnimals) do
        local visualAnimalIndex = 1
        for index = 1, subTypeIndex, visualAnimalIndex do
            local data = false
            for animalId, typeIndex in pairs(self.animalIdToVisualAnimalIndex) do
                if clusterToVisualAnimalIndex[numAnimals] == typeIndex then
                    self.animalIdToCluster[animalId] = nil
                    newAnimalMapping[animalId] = numAnimals
                    newAnimalIdToVisualAnimalIndex[animalId] = typeIndex
                    clusterToNumAnimals[numAnimals] = clusterToNumAnimals[numAnimals] - 1
                    if clusterToNumAnimals[numAnimals] <= 0 then
                        clusterToNumAnimals[numAnimals] = nil
                    else
                        data = true
                    end
                    break
                end
            end
            if not data then
                break
            end
        end
    end
    for numAnimals, subTypeIndex in pairs(self.animalIdToCluster) do
        removeHusbandryAnimal(self.husbandryId, numAnimals)
    end
    for numAnimals, subTypeIndex in pairs(clusterToNumAnimals) do
        local visualAnimalIndex = 1
        for index = 1, subTypeIndex, visualAnimalIndex do
            local data = clusterToVisualAnimalIndex[numAnimals]
            local visualAnimalIndex = addHusbandryAnimal(self.husbandryId, data - 1)
            if visualAnimalIndex == 0 then
                Logging.error("Unable to add animal with visual index %d for husbandry %d", data - 1, self.husbandryId)
            else
                local subTypeIndex = numAnimals:getSubTypeIndex()
                local age = numAnimals:getAge()
                local animalId = self.animalSystem:getVisualByAge(subTypeIndex, age).visualAnimal.variations
                if #animalId > 1 then
                    local typeIndex = animalId[math.random(1, #animalId)]
                    setAnimalTextureTile(self.husbandryId, visualAnimalIndex, typeIndex.tileUIndex, typeIndex.tileVIndex)
                end
                newAnimalMapping[visualAnimalIndex] = numAnimals
                newAnimalIdToVisualAnimalIndex[visualAnimalIndex] = data
            end
        end
    end
    for numAnimals, subTypeIndex in pairs(newAnimalMapping) do
        local age = 0
        if subTypeIndex.getDirtFactor ~= nil and Platform.gameplay.needHorseCleaning then
            age = subTypeIndex:getDirtFactor()
        end
        local visualAnimalIndex = getAnimalRootNode(self.husbandryId, numAnimals)
        I3DUtil.setShaderParameterRec(visualAnimalIndex, "dirt", age, nil, nil, nil)
        local index, data, visualAnimalIndex, subTypeIndex = getAnimalShaderParameter(self.husbandryId, numAnimals, "atlasInvSizeAndOffsetUV")
        I3DUtil.setShaderParameterRec(visualAnimalIndex, "atlasInvSizeAndOffsetUV", index, data, visualAnimalIndex, subTypeIndex)
    end
    self.animalIdToCluster = newAnimalMapping
    self.animalIdToVisualAnimalIndex = newAnimalIdToVisualAnimalIndex
    self.nextUpdateClusters = nil
end
function AnimalClusterHusbandry:setClusters(clusters)
    self.nextUpdateClusters = clusters
    self.visualUpdatePending = true
end
function AnimalClusterHusbandry:getHusbandryId()
    return self.husbandryId
end
function AnimalClusterHusbandry:getAnimalPosition(clusterId)
    for animalId, cluster in pairs(self.animalIdToCluster) do
        if cluster.id == clusterId then
            local x, y, z = getAnimalPosition(self.husbandryId, animalId)
            local rx, ry, rz = getAnimalRotation(self.husbandryId, animalId)
            return x, y, z, rx, ry, rz
        end
    end
    return nil
end
function AnimalClusterHusbandry:getClusterByAnimalId(animalId)
    return self.animalIdToCluster[animalId]
end
function AnimalClusterHusbandry:onIndoorStateChanged(_)
    if self.husbandryId ~= nil then
        setAnimalUseOutdoorAudioSetup(self.husbandryId, not g_soundManager:getIsIndoor())
    end
end
function AnimalClusterHusbandry.sortClusters(a, b)
    if a:getNumAnimals() == b:getNumAnimals() then
        return a.id < b.id
    else
        return a:getNumAnimals() > b:getNumAnimals()
    end
end