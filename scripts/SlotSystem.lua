SlotSystem = {}
SlotSystem.TOTAL_VRAM_MEGABYTES = {
    [PlatformId.WIN] = math.huge,
    [PlatformId.MAC] = math.huge,
    [PlatformId.PS5] = 3500,
    [PlatformId.XBOX_SERIES] = 3500,
    [PlatformId.IOS] = 640,
    [PlatformId.ANDROID] = 640,
    [PlatformId.SWITCH] = 640,
    [PlatformId.SWITCH2] = 2000
}
SlotSystem.VRAM_MEGABYTES_PER_SLOT = {
    [PlatformId.WIN] = 1,
    [PlatformId.MAC] = 1,
    [PlatformId.PS5] = 1,
    [PlatformId.XBOX_SERIES] = 1,
    [PlatformId.IOS] = 0.5,
    [PlatformId.ANDROID] = 0.5,
    [PlatformId.SWITCH] = 0.5,
    [PlatformId.SWITCH2] = 1
}
SlotSystem.VISIBILITY_THRESHOLD = 10000
SlotSystem.CRITICAL_FACTOR = 0.9
SlotSystem.TOTAL_NUM_GARAGE_SLOTS = {}
for platformId, vram in pairs(SlotSystem.TOTAL_VRAM_MEGABYTES) do
    SlotSystem.TOTAL_NUM_GARAGE_SLOTS[platformId] = math.floor(vram / SlotSystem.VRAM_MEGABYTES_PER_SLOT[platformId])
end
SlotSystem.LIMITED_OBJECT_BALE = 1
SlotSystem.LIMITED_OBJECT_PALLET = 2
local SlotSystem_mt = SlotSystem
SlotSystem_mt.NUM_OBJECT_LIMITS = {
    [SlotSystem.LIMITED_OBJECT_BALE] = {
        [PlatformId.WIN] = math.huge,
        [PlatformId.MAC] = math.huge,
        [PlatformId.PS5] = 200,
        [PlatformId.XBOX_SERIES] = 200,
        [PlatformId.IOS] = 100,
        [PlatformId.ANDROID] = 100,
        [PlatformId.SWITCH] = 100,
        [PlatformId.SWITCH2] = 100
    },
    [SlotSystem.LIMITED_OBJECT_PALLET] = {
        [PlatformId.WIN] = 300,
        [PlatformId.MAC] = 300,
        [PlatformId.PS5] = 150,
        [PlatformId.XBOX_SERIES] = 150,
        [PlatformId.IOS] = 50,
        [PlatformId.ANDROID] = 50,
        [PlatformId.SWITCH] = 50,
        [PlatformId.SWITCH2] = 50
    }
}
local SlotSystem_mt = Class(SlotSystem)
function SlotSystem.new(mission, isServer, customMt)
    -- upvalues: (copy) SlotSystem_mt
    local self = setmetatable({}, customMt or SlotSystem_mt)
    self.mission = mission
    self.isServer = isServer
    self.slotUsage = 0
    self.slotLimit = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[getPlatformId()]
    self.vramPerSlot = SlotSystem.VRAM_MEGABYTES_PER_SLOT[getPlatformId()] * 1024 * 1024
    if isServer then
        self.objectLimits = {}
        for k, limits in pairs(SlotSystem.NUM_OBJECT_LIMITS) do
            self.objectLimits[k] = {
                ["objects"] = {},
                ["limit"] = limits[getPlatformId()]
            }
        end
    end
    return self
end
function SlotSystem:delete() end
function SlotSystem:loadMapData(_, _)
    self:updateSlotLimit()
    return true
end
function SlotSystem:saveToXMLFile(xmlFile, key)
    setXMLInt(xmlFile, key .. "#slotUsage", self.slotUsage)
end
function SlotSystem.getIsCountableObject(_, object)
    return object:isa(Vehicle) or object:isa(Placeable)
end
function SlotSystem:updateSlotUsage()
    self.slotUsage = math.ceil((self.mission.vertexBufferMemoryUsage + self.mission.indexBufferMemoryUsage + self.mission.textureMemoryUsage) / self.vramPerSlot)
    for storeItem, item in pairs(self.mission.ownedItems) do
        if item.numItems > 0 and not storeItem.ignoreVramUsage then
            local baseSlots = self:getStoreItemSlotUsage(storeItem, true)
            local sharedSlots = self:getStoreItemSlotUsage(storeItem, false) * (item.numItems - 1)
            self.slotUsage = self.slotUsage + baseSlots + sharedSlots
        end
    end
    for storeItem, item in pairs(self.mission.leasedItems) do
        if item.numItems > 0 and not storeItem.ignoreVramUsage then
            self.slotUsage = self.slotUsage + self:getStoreItemSlotUsage(storeItem, true) + self:getStoreItemSlotUsage(storeItem, false) * (item.numItems - 1)
        end
    end
    g_shopMenu:onSlotUsageChanged(self.slotUsage, self.slotLimit)
    g_shopConfigScreen:onSlotUsageChanged(self.slotUsage, self.slotLimit)
    g_messageCenter:publish(MessageType.SLOT_USAGE_CHANGED, self.slotUsage, self.slotLimit)
end
function SlotSystem:updateSlotLimit()
    local slots = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[getPlatformId()]
    for _, user in ipairs(self.mission.userManager:getUsers()) do
        local userSlotLimit = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[user:getPlatformId()]
        if userSlotLimit ~= nil then
            slots = math.min(slots, userSlotLimit)
        end
    end
    self:setSlotLimit(slots)
end
function SlotSystem:setSlotLimit(slotLimit)
    local changed = false
    if slotLimit ~= self.slotLimit then
        local text = g_i18n:getText("ingameNotification_crossPlaySlotLimitInactive")
        local notificationType = FSBaseMission.INGAME_NOTIFICATION_OK
        if slotLimit < math.huge then
            text = string.format(g_i18n:getText("ingameNotification_crossPlayNewSlotLimit"), slotLimit)
            notificationType = FSBaseMission.INGAME_NOTIFICATION_CRITICAL
        end
        self.mission:addIngameNotification(notificationType, text)
        self.slotLimit = slotLimit
        if g_server ~= nil then
            g_server:broadcastEvent(SlotSystemUpdateEvent.new(slotLimit))
        end
        changed = true
    end
    g_shopMenu:onSlotUsageChanged(self.slotUsage, slotLimit)
    g_messageCenter:publish(MessageType.SLOT_USAGE_CHANGED, self.slotUsage, self.slotLimit)
    return changed
end
function SlotSystem:hasEnoughSlots(storeItem)
    if storeItem.ignoreVramUsage then
        return true
    end
    local slotUsage = self:getStoreItemSlotUsage(storeItem, self.mission:getNumOfItems(storeItem) == 0)
    return self.slotLimit >= self.slotUsage + slotUsage
end
function SlotSystem:getAreSlotsVisible()
    return self.slotLimit < SlotSystem.VISIBILITY_THRESHOLD and true or self.slotUsage >= self.slotLimit * SlotSystem.CRITICAL_FACTOR
end
function SlotSystem:getStoreItemSlotUsage(storeItem, includeShared)
    if storeItem == nil or (StoreItemUtil.getIsAnimal(storeItem) or StoreItemUtil.getIsObject(storeItem)) then
        return 0
    end
    local vramUsage
    if includeShared then
        vramUsage = storeItem.perInstanceVramUsage + storeItem.sharedVramUsage * 1.2
    else
        vramUsage = math.max(storeItem.perInstanceVramUsage, storeItem.sharedVramUsage * 0.05)
    end
    return math.max(math.ceil(vramUsage / self.vramPerSlot), 1)
end
function SlotSystem:getCanConnect(_, platformId)
    local platformSlots = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[platformId]
    return platformSlots == nil or self.slotUsage <= platformSlots
end
function SlotSystem:addLimitedObject(objectType, object)
    if self.isServer then
        local objectData = self.objectLimits[objectType]
        if objectData ~= nil then
            table.addElement(objectData.objects, object)
        end
    else
        return
    end
end
function SlotSystem:removeLimitedObject(objectType, object)
    if self.isServer then
        local objectData = self.objectLimits[objectType]
        if objectData ~= nil then
            table.removeElement(objectData.objects, object)
        end
    else
        return
    end
end
function SlotSystem:getCanAddLimitedObjects(objectType, numObjects)
    if not self.isServer then
        return true
    end
    local objectData = self.objectLimits[objectType]
    if objectData == nil then
        return false
    end
    return #objectData.objects + (numObjects or 1) <= objectData.limit
end