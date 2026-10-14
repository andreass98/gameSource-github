print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
local animalCounter = 0
local visibleAnimals = {}
local subTypes = {}
subTypes[1] = {
    ["visuals"] = {
        {
            ["minAge"] = 0,
            ["animalTypeIndex"] = 1
        },
        {
            ["minAge"] = 5,
            ["animalTypeIndex"] = 2
        },
        {
            ["minAge"] = 10,
            ["animalTypeIndex"] = 3
        }
    }
}
subTypes[2] = {
    ["visuals"] = {
        {
            ["minAge"] = 0,
            ["animalTypeIndex"] = 4
        },
        {
            ["minAge"] = 5,
            ["animalTypeIndex"] = 5
        },
        {
            ["minAge"] = 10,
            ["animalTypeIndex"] = 6
        }
    }
}
subTypes[3] = {
    ["visuals"] = {
        {
            ["minAge"] = 0,
            ["animalTypeIndex"] = 7
        },
        {
            ["minAge"] = 5,
            ["animalTypeIndex"] = 8
        },
        {
            ["minAge"] = 10,
            ["animalTypeIndex"] = 9
        }
    }
}
_G.g_currentMission = {
    ["animalNameSystem"] = {
        ["getRandomName"] = function(_)
            return "AnimalName" .. math.random(1, 123123)
        end
    },
    ["animalSystem"] = {
        ["getSubTypeByIndex"] = function(_, index)
            -- upvalues: (copy) subTypes
            return subTypes[index]
        end,
        ["getAnimalTypeIndexByAge"] = function(_, subTypeIndex, age)
            -- upvalues: (copy) subTypes
            local animalTypeIndex = nil
            for _, visual in ipairs(subTypes[subTypeIndex].visuals) do
                if visual.minAge <= age then
                    animalTypeIndex = visual.animalTypeIndex
                end
            end
            return animalTypeIndex
        end
    }
}
function createAnimalHusbandry(...)
    log("create husbandry", ...)
    return 1
end
function addHusbandryAnimal(_, animalTypeIndex)
    -- upvalues: (ref) animalCounter, (copy) visibleAnimals
    animalCounter = animalCounter + 1
    table.insert(visibleAnimals, {
        ["animalId"] = animalCounter,
        ["animalTypeIndex"] = animalTypeIndex + 1
    })
    log("Added animal", animalCounter, animalTypeIndex + 1)
    return animalCounter
end
function removeHusbandryAnimal(_, animalId)
    -- upvalues: (copy) visibleAnimals
    local i = 1
    for i = i, #visibleAnimals do
        if visibleAnimals[i].animalId == animalId then
            table.remove(visibleAnimals, i)
            log("remove animal", animalId)
            return
        end
    end
    printCallstack()
end
TestAnimalCluster = {}
TestAnimalCluster.CURRENT_SELECTION_INDEX = 1
function TestAnimalCluster.init()
    _G.g_server = {
        ["broadcastEvent"] = function() end
    }
    local self = TestAnimalCluster
    self.clusterSystem = AnimalClusterSystem.new(true, self)
    self.clusterSystem:addClustersUpdatedListener(function()
        -- upvalues: (copy) self
        local clusters = self.clusterSystem:getClusters()
        self.animalClusterHusbandry:setClusters(clusters)
    end)
    self.animalClusterHusbandry = AnimalClusterHusbandry.new("horse", 12)
    self.animalClusterHusbandry:create("testXML", 1, 1, 255)
end
function TestAnimalCluster.update(dt)
    TestAnimalCluster.clusterSystem:update(dt)
end
function TestAnimalCluster.draw()
    -- upvalues: (copy) visibleAnimals
    local self = TestAnimalCluster
    local numAnimals = 0
    local clusters = self.clusterSystem:getClusters()
    local sortedClusters = {}
    for i, cluster in ipairs(clusters) do
        table.insert(sortedClusters, cluster)
        local animalTypeIndex = g_currentMission.animalSystem:getVisualAnimalIndexByAge(cluster.subTypeIndex, cluster:getAge())
        local animalIds = {}
        for animalId, c in pairs(self.animalClusterHusbandry.animalIdToCluster) do
            if cluster == c then
                table.insert(animalIds, animalId)
            end
        end
        local animalIdStr = table.concat(animalIds, ", ")
        renderText(0.5, 0.8 - (i - 1) * 0.013, 0.012, string.format("Cluster: %02d  |  Animals: %03d  |  Age: %02d  |  Health: %03d  |  Reproduction: %03d  |  Hash: %s | TypeIndex: %d | AnimalIds: %s", cluster.id, cluster.numAnimals, cluster.age, cluster.health, cluster.reproduction, cluster:getHash(), animalTypeIndex, animalIdStr))
    end
    if #clusters > 0 then
        renderText(0.495, 0.8 - (TestAnimalCluster.CURRENT_SELECTION_INDEX - 1) * 0.013, 0.012, ">")
    end
    renderText(0.5, 0.9, 0.012, string.format("Total Num Animals: %d", numAnimals))
    renderText(0.02, 0.9, 0.012, string.format("Total Num Visible Animals: %d", #visibleAnimals))
    for i, cluster in ipairs(visibleAnimals) do
        local animalTypeIndex = self.animalClusterHusbandry.animalIdToCluster[cluster.animalId]
        local animalIds = "-"
        if animalTypeIndex ~= nil then
            animalIds = string.format("%02d", animalTypeIndex.id)
        end
        renderText(0.02, 0.8 - (i - 1) * 0.013, 0.012, string.format("AnimalId: %02d  |  TypeIndex: %d | Cluster: %s", cluster.animalId, cluster.animalTypeIndex, animalIds))
    end
    local i = 1
    for cluster, animalTypeIndex in pairs(self.animalClusterHusbandry.totalNumAnimalsPerAnimalTypeIndex) do
        renderText(0.2, 0.8 - (i - 1) * 0.013, 0.012, string.format("TypeIndex: %d | Num: %d", cluster, animalTypeIndex))
        i = i + 1
    end
    table.sort(sortedClusters, AnimalClusterHusbandry.sortClusters)
    for cluster, animalTypeIndex in ipairs(sortedClusters) do
        local animalIds = g_currentMission.animalSystem:getVisualAnimalIndexByAge(animalTypeIndex.subTypeIndex, animalTypeIndex:getAge())
        renderText(0.35, 0.8 - (cluster - 1) * 0.013, 0.012, string.format("Cluster: %03d | Num: %d | TypeIndex: %d", animalTypeIndex.id, animalTypeIndex:getNumAnimals(), animalIds))
    end
end
function TestAnimalCluster.mouseEvent(posX, posY, isDown, isUp, button) end
function TestAnimalCluster.keyEvent(_, sym, modifier, isDown)
    if not isDown then
        local self = TestAnimalCluster
        local clusters = self.clusterSystem:getClusters()
        local currentCluster = TestAnimalCluster
        local cluster = math.min(TestAnimalCluster.CURRENT_SELECTION_INDEX, #clusters)
        currentCluster.CURRENT_SELECTION_INDEX = math.max(cluster, 1)
        local currentCluster = clusters[TestAnimalCluster.CURRENT_SELECTION_INDEX]
        local allModifier = bit32.band(modifier, Input.MOD_LSHIFT) > 0
        if sym == Input.KEY_m then
            if allModifier or #clusters == 0 then
                local cluster = self.clusterSystem:createCluster()
                cluster.numAnimals = 1
                cluster.subTypeIndex = math.random(1, 3)
                self.clusterSystem:addPendingAddCluster(cluster)
            elseif currentCluster ~= nil then
                currentCluster.numAnimals = currentCluster.numAnimals + 1
                self.animalClusterHusbandry:setClusters(clusters)
            end
        elseif sym == Input.KEY_n then
            if currentCluster ~= nil then
                self.clusterSystem:addPendingRemoveCluster(currentCluster)
            end
        elseif sym == Input.KEY_q then
            if allModifier then
                for i, cluster in ipairs(clusters) do
                    cluster:changeAge(1)
                end
            elseif currentCluster ~= nil then
                currentCluster:changeAge(1)
            end
            self.animalClusterHusbandry:setClusters(clusters)
        elseif sym == Input.KEY_w then
            if allModifier then
                for i, cluster in ipairs(clusters) do
                    cluster:changeHealth(1)
                end
            elseif currentCluster ~= nil then
                currentCluster:changeHealth(1)
            end
            self.animalClusterHusbandry:setClusters(clusters)
        elseif sym == Input.KEY_e then
            if allModifier then
                for i, cluster in ipairs(clusters) do
                    cluster:changeHealth(-1)
                end
            elseif currentCluster ~= nil then
                currentCluster:changeHealth(-1)
            end
            self.animalClusterHusbandry:setClusters(clusters)
        elseif sym == Input.KEY_s then
            if allModifier then
                for i, cluster in ipairs(clusters) do
                    cluster:changeReproduction(1)
                end
            elseif currentCluster ~= nil then
                currentCluster:changeReproduction(1)
            end
            self.animalClusterHusbandry:setClusters(clusters)
        elseif sym == Input.KEY_d then
            if allModifier then
                for i, cluster in ipairs(clusters) do
                    cluster:changeReproduction(-1)
                end
            elseif currentCluster ~= nil then
                currentCluster:changeReproduction(-1)
            end
            self.animalClusterHusbandry:setClusters(clusters)
        elseif sym == Input.KEY_up then
            TestAnimalCluster.CURRENT_SELECTION_INDEX = TestAnimalCluster.CURRENT_SELECTION_INDEX - 1
        elseif sym == Input.KEY_down then
            TestAnimalCluster.CURRENT_SELECTION_INDEX = TestAnimalCluster.CURRENT_SELECTION_INDEX + 1
        end
        local cluster = TestAnimalCluster
        local i = TestAnimalCluster.CURRENT_SELECTION_INDEX
        local cluster = #clusters
        cluster.CURRENT_SELECTION_INDEX = math.max(math.min(i, cluster), 1)
        self.clusterSystem:setDirty()
    end
end