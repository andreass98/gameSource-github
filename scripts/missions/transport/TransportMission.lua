TransportMission = {}
local TransportMission_mt = Class(TransportMission, AbstractMission)
InitStaticObjectClass(TransportMission, "TransportMission")
TransportMission.CONTRACT_DURATION = 115200000
TransportMission.CONTRACT_DURATION_VAR = 57600000
TransportMission.REWARD_PER_METER = 0.5
TransportMission.REWARD_PER_OBJECT = 350
TransportMission.NUM_OBJECTS_PER_DRIVE = 5
TransportMission.TEST_HEIGHT = 50
function TransportMission.new(isServer, isClient, customMt)
    -- upvalues: (copy) TransportMission_mt
    local title = g_i18n:getText("contract_transport_title")
    local description = g_i18n:getText("contract_transport_description")
    local self = AbstractMission.new(isServer, isClient, title, description, customMt or TransportMission_mt)
    self.objects = {}
    self.objectsAtTrigger = {}
    self.numFinished = 0
    return self
end
function TransportMission:delete()
    if self.pickup ~= nil then
        local trigger = g_missionManager.transportTriggers[self.pickup]
        if trigger ~= nil then
            trigger:setMission(nil)
        end
    end
    if self.dropoff ~= nil then
        local trigger = g_missionManager.transportTriggers[self.dropoff]
        if trigger ~= nil then
            trigger:setMission(nil)
        end
    end
    for _, object in pairs(self.objects) do
        object:delete()
    end
    self:destroyHotspots()
    TransportMission:superClass().delete(self)
end
function TransportMission:saveToXMLFile(xmlFile, key)
    TransportMission:superClass().saveToXMLFile(self, xmlFile, key)
    setXMLInt(xmlFile, key .. "#timeLeft", self.timeLeft)
    setXMLString(xmlFile, key .. "#config", self.missionConfig.name)
    setXMLString(xmlFile, key .. "#pickupTrigger", self.pickup)
    setXMLString(xmlFile, key .. "#dropoffTrigger", self.dropoff)
    setXMLString(xmlFile, key .. "#objectFilename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.objectFilename)))
    setXMLInt(xmlFile, key .. "#numObjects", self.numObjects)
    local index = 0
    for _, object in pairs(self.objects) do
        local x, y, z = getWorldTranslation(object.nodeId)
        local rx, ry, rz = getWorldRotation(object.nodeId)
        local objectKey = string.format("%s.object(%d)", key, index)
        setXMLString(xmlFile, objectKey .. "#translation", string.format("%f %f %f", x, y, z))
        setXMLString(xmlFile, objectKey .. "#rotation", string.format("%f %f %f", math.deg(rx), math.deg(ry), (math.deg(rz))))
        index = index + 1
    end
end
function TransportMission:loadFromXMLFile(xmlFile, key)
    if not TransportMission:superClass().loadFromXMLFile(self, xmlFile, key) then
        return false
    end
    self.timeLeft = getXMLInt(xmlFile, key .. "#timeLeft")
    local name = getXMLString(xmlFile, key .. "#config")
    self.missionConfig = g_missionManager:getTransportMissionConfig(name)
    if self.missionConfig == nil then
        return false
    end
    self.pickup = getXMLString(xmlFile, key .. "#pickupTrigger")
    self.dropoff = getXMLString(xmlFile, key .. "#dropoffTrigger")
    self.objectFilename = NetworkUtil.convertFromNetworkFilename(getXMLString(xmlFile, key .. "#objectFilename"))
    self.numObjects = getXMLInt(xmlFile, key .. "#numObjects")
    if self.status == MissionStatus.RUNNING then
        local i = 0
        while true do
            local objectKey = string.format("%s.object(%d)", key, i)
            if not hasXMLProperty(xmlFile, objectKey) then
                break
            end
            local z = getXMLString(xmlFile, objectKey .. "#translation")
            local x, y, z = unpack(string.getVector(z, 3))
            local rz = getXMLString(xmlFile, objectKey .. "#rotation")
            local rx, ry, rz = unpack(string.getVector(rz, 3))
            local object = self:createObject(x, y, z, rx, ry, rz)
            self.objects[object.nodeId] = object
            i = i + 1
        end
    end
    local i = self:getPickupTrigger()
    local objectKey = self:getDropoffTrigger()
    if i == nil or objectKey == nil then
        return false
    end
    i:setMission(self)
    objectKey:setMission(self)
    return true
end
function TransportMission:writeStream(streamId, connection)
    TransportMission:superClass().writeStream(self, streamId, connection)
    streamWriteString(streamId, self.pickup)
    streamWriteString(streamId, self.dropoff)
    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.objectFilename))
    streamWriteUInt8(streamId, self.numObjects)
    streamWriteUInt8(streamId, self.missionConfig.id)
end
function TransportMission:readStream(streamId, connection)
    TransportMission:superClass().readStream(self, streamId, connection)
    self.pickup = streamReadString(streamId)
    self.dropoff = streamReadString(streamId)
    self.objectFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    self.numObjects = streamReadUInt8(streamId)
    self.missionConfig = g_missionManager:getTransportMissionConfigById(streamReadUInt8(streamId))
    g_missionManager.transportTriggers[self.pickup]:setMission(self)
    g_missionManager.transportTriggers[self.dropoff]:setMission(self)
end
function TransportMission:init(_)
    if not TransportMission:superClass().init(self) then
        return false
    end
    local tMission = table.getRandomElement(g_missionManager.transportMissions)
    local pickup = nil
    local dropoff = nil
    for i = 1, #tMission.pickupTriggers + 1 do
        local item = table.getRandomElement(tMission.pickupTriggers)
        local trigger = g_missionManager.transportTriggers[item.index]
        if trigger ~= nil and trigger.mission == nil then
            trigger:setMission(self)
            pickup = item
            break
        end
    end
    if pickup == nil then
        return false
    end
    for i = 1, #tMission.dropoffTriggers + 1 do
        local item = table.getRandomElement(tMission.dropoffTriggers)
        local trigger = g_missionManager.transportTriggers[item.index]
        if trigger ~= nil and trigger.mission == nil then
            trigger:setMission(self)
            dropoff = item
            break
        end
    end
    if dropoff == nil or pickup.index == dropoff.index then
        return false
    end
    self.numObjects = math.random(table.getRandomElement(tMission.objects).min, table.getRandomElement(tMission.objects).max)
    self.pickup = pickup.index
    self.dropoff = dropoff.index
    self.objectFilename = object.filename
    self.missionConfig = tMission
    self.timeLeft = TransportMission.CONTRACT_DURATION + (2 * math.random() - 1) * TransportMission.CONTRACT_DURATION_VAR
    self.reward = self:calculateReward(pickup.rewardScale * dropoff.rewardScale * object.rewardScale)
    return true
end
function TransportMission:calculateReward(multiplier)
    local distance = calcDistanceFrom(g_missionManager.transportTriggers[self.pickup].triggerId, g_missionManager.transportTriggers[self.dropoff].triggerId)
    return (math.ceil(self.numObjects / TransportMission.NUM_OBJECTS_PER_DRIVE) * TransportMission.REWARD_PER_METER * distance + self.numObjects * TransportMission.REWARD_PER_OBJECT) * multiplier
end
function TransportMission:getReward()
    return self.reward * (self.mission.missionInfo.economicDifficulty == EconomicDifficulty.NORMAL and 1 or (self.mission.missionInfo.economicDifficulty == EconomicDifficulty.EASY and 1.2 or 0.8))
end
function TransportMission:start()
    if TransportMission:superClass().start(self) then
        return self:loadObjects() and true or false
    else
        return false
    end
end
function TransportMission:finish(success)
    TransportMission:superClass().finish(self, success)
    if self.mission:getIsServer() then
        self:destroyHotspots()
        if success then
            g_farmManager:getFarmById(self.farmId).stats:updateTransportJobsDone()
        end
    end
    if success then
        self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("contract_transport_finished"))
    else
        self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("contract_transport_failed"))
    end
end
function TransportMission:dismiss()
    TransportMission:superClass().dismiss(self)
    for _, object in pairs(self.objects) do
        object:delete()
    end
    self.objects = {}
end
function TransportMission:update(dt)
    TransportMission:superClass().update(self, dt)
    if not self:hasHotspots() and self.status == MissionStatus.RUNNING then
        self:createHotspots()
        self:updateTriggerVisibility()
    end
end
function TransportMission:hasHotspots()
    return self.pickupHotspot ~= nil and self.dropoffHotspot ~= nil
end
function TransportMission:createHotspots()
    self.pickupHotspot = self:createHotspot(self:getPickupTrigger())
    self.dropoffHotspot = self:createHotspot(self:getDropoffTrigger())
end
function TransportMission:destroyHotspots()
    if self.pickupHotspot ~= nil then
        self.mission:removeMapHotspot(self.pickupHotspot)
        self.pickupHotspot:delete()
        self.pickupHotspot = nil
    end
    if self.dropoffHotspot ~= nil then
        self.mission:removeMapHotspot(self.dropoffHotspot)
        self.dropoffHotspot:delete()
        self.dropoffHotspot = nil
    end
end
function TransportMission:getPickupTrigger()
    return g_missionManager.transportTriggers[self.pickup]
end
function TransportMission:getDropoffTrigger()
    return g_missionManager.transportTriggers[self.dropoff]
end
function TransportMission:createHotspot(trigger)
    local x, _, z = getWorldTranslation(trigger.triggerId)
    local mapHotspot = MissionHotspot.new()
    mapHotspot:setWorldPosition(x, z)
    self.mission:addMapHotspot(mapHotspot)
    return mapHotspot
end
function TransportMission:updateTriggerVisibility()
    g_missionManager.transportTriggers[self.pickup]:onMissionUpdated()
    g_missionManager.transportTriggers[self.dropoff]:onMissionUpdated()
end
function TransportMission:loadObjects()
    local trigger = self:getPickupTrigger()
    local objectConfig = nil
    for _, object in pairs(self.missionConfig.objects) do
        if object.filename == self.objectFilename then
            objectConfig = object
            break
        end
    end
    if objectConfig == nil then
        return false
    end
    local _ = objectConfig.size
    local sizeX, _, sizeZ = unpack(_)
    local _, object, rz = getWorldRotation(trigger.triggerId)
    local tx, ty, tz = getWorldTranslation(trigger.triggerId)
    local dirX, dirZ = MathUtil.getDirectionFromYRotation(object)
    local theta = math.atan2(dirZ, dirX)
    local rcos = math.cos(theta)
    local rsin = math.sin(theta)
    if not self:isTriggerEmpty(trigger, sizeX, sizeZ) then
        return false
    end
    local i = 1
    for i = i, self.numObjects do
        local dx = 0
        if i >= 5 then
            dx = -(sizeX + 0.1)
        elseif i >= 3 then
            dx = xCellOffset
        end
        local dz
        if i % 2 == 0 then
            dz = -(sizeZ / 2 + 0.3)
        else
            dz = rowOffset
        end
        local dz = rsin * dx + rcos * dz
        local object = self:createObject(tx + (rcos * dx - rsin * dz), ty, tz + dz, _, object, rz)
        self.objects[object.nodeId] = object
    end
    return true
end
function TransportMission:isTriggerEmpty(trigger, objectSizeX, objectSizeZ)
    local rx, ry, rz = getWorldRotation(trigger.triggerId)
    local tx, ty, tz = getWorldTranslation(trigger.triggerId)
    self.tempHasCollision = false
    overlapBox(tx, ty, tz, rx, ry, rz, 3 * (objectSizeX + 0.1), TransportMission.TEST_HEIGHT * 0.5, 2 * (objectSizeZ + 0.1), "collisionTestCallback", self, CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.TREE)
    return not self.tempHasCollision
end
function TransportMission:collisionTestCallback(transformId)
    if self.mission.nodeToObject[transformId] ~= nil or (self.mission.players[transformId] ~= nil or self.mission:getNodeObject(transformId) ~= nil) then
        self.tempHasCollision = true
    end
end
function TransportMission:createObject(x, y, z, rx, ry, rz)
    local transportObject = MissionPhysicsObject.new(self.mission:getIsServer(), self.mission:getIsClient())
    if not transportObject:load(self.objectFilename, x, y, z, rx, ry, rz) then
        transportObject:delete()
        return nil
    end
    transportObject:register()
    transportObject.mission = self
    return transportObject
end
function TransportMission:objectEnteredTrigger(trigger, objectId)
    if self.objects[objectId] ~= nil and (trigger == self:getDropoffTrigger() and self.objectsAtTrigger[objectId] ~= true) then
        self.objectsAtTrigger[objectId] = true
        self.numFinished = self.numFinished + 1
    end
end
function TransportMission:objectLeftTrigger(trigger, objectId)
    if self.objects[objectId] ~= nil and (trigger == self:getDropoffTrigger() and self.objectsAtTrigger[objectId] == true) then
        self.objectsAtTrigger[objectId] = false
        self.numFinished = self.numFinished - 1
    end
end
function TransportMission:getTriggerInfo(index, isPickup)
    local list = self.missionConfig.dropoffTriggers
    if isPickup then
        list = self.missionConfig.pickupTriggers
    end
    for _, info in ipairs(list) do
        if info.index == index then
            return info
        end
    end
    return {}
end
function TransportMission:getTriggerTitle(index, isPickup)
    local info = self:getTriggerInfo(index, isPickup)
    return info == nil and "" or g_i18n:convertText(Utils.getNoNil(info.title, ""))
end
function TransportMission:getNPC()
    return g_npcManager:getNPCByIndex(self.missionConfig.npcIndex)
end
function TransportMission:getCompletion()
    return self.numFinished / self.numObjects
end
function TransportMission.loadMapData(xmlFile, key, baseDirectory)
    return true
end
function TransportMission.unloadMapData() end
function TransportMission.canRun()
    if g_missionManager.numTransportTriggers < 2 then
        return false
    else
        return #g_missionManager.transportMissions ~= 0
    end
end