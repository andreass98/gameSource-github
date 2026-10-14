HusbandrySystem = {}
HusbandrySystem.GAME_LIMIT = 15
local HusbandrySystem_mt = Class(HusbandrySystem)
function HusbandrySystem.new(isServer, mission, customMt)
    -- upvalues: (copy) HusbandrySystem_mt
    local self = setmetatable({}, customMt or HusbandrySystem_mt)
    self.isServer = isServer
    self.mission = mission
    self.manureHeaps = {}
    self.placeables = {}
    self.clusterHusbandries = {}
    self.rideables = {}
    self.maxNumRidables = 4
    self.husbandrys = {}
    self.livestockTrailers = {}
    return self
end
function HusbandrySystem:delete() end
function HusbandrySystem:addPlaceable(placeable)
    local success = table.addElement(self.placeables, placeable)
    if success then
        g_messageCenter:publish(MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE)
    end
    return success
end
function HusbandrySystem:removePlaceable(placeable)
    local success = table.removeElement(self.placeables, placeable)
    if success and success then
        g_messageCenter:publish(MessageType.HUSBANDRY_SYSTEM_REMOVED_PLACEABLE)
    end
    return success
end
function HusbandrySystem:addClusterHusbandry(clusterHusbandry)
    return table.addElement(self.clusterHusbandries, clusterHusbandry)
end
function HusbandrySystem:removeClusterHusbandry(clusterHusbandry)
    return table.removeElement(self.clusterHusbandries, clusterHusbandry)
end
function HusbandrySystem:getPlaceablesByFarm(farmId, animalTypeIndex)
    local placeables = farmId or g_localPlayer.farmId
    local placeables = {}
    for _, placeable in ipairs(self.placeables) do
        if placeables == placeable:getOwnerFarmId() and (animalTypeIndex == nil or placeable:getAnimalTypeIndex() == animalTypeIndex) then
            table.insert(placeables, placeable)
        end
    end
    return placeables
end
function HusbandrySystem:getClusterHusbandryById(husbandryId)
    for _, clusterHusbandry in ipairs(self.clusterHusbandries) do
        if clusterHusbandry:getHusbandryId() == husbandryId then
            return clusterHusbandry
        end
    end
    return nil
end
function HusbandrySystem:getLimitReached()
    return #self.placeables >= HusbandrySystem.GAME_LIMIT
end
function HusbandrySystem:addManureHeap(manureHeap)
    return table.addElement(self.manureHeaps, manureHeap)
end
function HusbandrySystem:removeManureHeap(manureHeap)
    return table.removeElement(self.manureHeaps, manureHeap)
end
function HusbandrySystem:addRideable(rideable)
    table.addElement(self.rideables, rideable)
end
function HusbandrySystem:removeRideable(rideable)
    table.removeElement(self.rideables, rideable)
end
function HusbandrySystem:getNumRideablesPerFarm(farmId)
    local num = 0
    for _, rideable in ipairs(self.rideables) do
        if rideable:getOwnerFarmId() == farmId then
        end
    end
    return num
end
function HusbandrySystem:getCanAddRideable(farmId)
    return self:getNumRideablesPerFarm(farmId) < self.maxNumRidables
end
function HusbandrySystem:getFirstAvailableHusbandry(rideable)
    local farmId = rideable:getOwnerFarmId()
    local cluster = rideable:getCluster()
    local typeIndex = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(cluster:getSubTypeIndex())
    for _, placeable in ipairs(self.placeables) do
        if placeable:getOwnerFarmId() == farmId and (placeable:getAnimalTypeIndex() == typeIndex and placeable:getNumOfFreeAnimalSlots() > 0) then
            return placeable
        end
    end
    return nil
end
function HusbandrySystem:getHusbandryInRideableRange(rideable)
    local farmId = rideable:getOwnerFarmId()
    local cluster = rideable:getCluster()
    local typeIndex = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(cluster:getSubTypeIndex())
    local placeableInRange = nil
    local isInRange = false
    local x, _, z = getWorldTranslation(rideable.rootNode)
    for _, placeable in ipairs(self.placeables) do
        if placeable:getOwnerFarmId() == farmId and placeable:getIsInAnimalDeliveryArea(x, z) then
            isInRange = true
            if placeable:getAnimalTypeIndex() == typeIndex and placeable:getNumOfFreeAnimalSlots() > 0 then
                placeableInRange = placeable
            end
        end
    end
    return isInRange, placeableInRange
end
function HusbandrySystem:addLivestockTrailer(trailer)
    table.addElement(self.livestockTrailers, trailer)
end
function HusbandrySystem:removeLivestockTrailer(trailer)
    table.removeElement(self.livestockTrailers, trailer)
end
function HusbandrySystem:getNumOfFreeAnimalSlots(farmId, subTypeIndex)
    local usedSlots = 0
    local totalSlots = 0
    local animalSystem = g_currentMission.animalSystem
    local typeIndex = animalSystem:getTypeIndexBySubTypeIndex(subTypeIndex)
    for _, placeable in ipairs(self.placeables) do
        if placeable:getOwnerFarmId() == farmId and placeable:getAnimalTypeIndex() == typeIndex then
            totalSlots = totalSlots + placeable:getMaxNumOfAnimals()
            usedSlots = usedSlots + placeable:getNumOfAnimals()
        end
    end
    for _, placeable in ipairs(self.livestockTrailers) do
        if placeable:getOwnerFarmId() == farmId then
            local animalType = placeable:getCurrentAnimalType()
            if animalType ~= nil and animalType.typeIndex == typeIndex then
                usedSlots = usedSlots + placeable:getNumOfAnimals()
            end
        end
    end
    for _, placeable in ipairs(self.rideables) do
        if placeable:getOwnerFarmId() == farmId then
            local animalType = placeable:getCluster()
            if animalType ~= nil and animalSystem:getTypeIndexBySubTypeIndex((animalType:getSubTypeIndex())) == typeIndex then
            end
        end
    end
    return totalSlots - usedSlots
end