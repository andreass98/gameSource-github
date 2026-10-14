Dog = {}
source("dataS/scripts/animals/events/DogFetchItemEvent.lua")
source("dataS/scripts/animals/events/DogFollowEvent.lua")
source("dataS/scripts/animals/events/DogPetEvent.lua")
source("dataS/scripts/animals/DogPetActivatable.lua")
local Dog_mt = Class(Dog, Object)
InitStaticObjectClass(Dog, "Dog")
Dog.FETCH_RANGE = 30
g_xmlManager:addCreateSchemaFunction(function()
    Dog.xmlSchema = XMLSchema.new("dog")
    Dog.registerXMLPaths(Dog.xmlSchema)
end)
function Dog.registerXMLPaths(xmlSchema)
    xmlSchema:register(XMLValueType.STRING, "dog.annotation", "Copyright annotation")
    AnimalCompanionManager.registerXMLPaths(xmlSchema, "dog")
end
function Dog.new(isServer, isClient, customMt)
    -- upvalues: (copy) Dog_mt
    local self = Object.new(isServer, isClient, customMt or Dog_mt)
    self.dogInstance = nil
    self.animalId = nil
    self.spawner = nil
    self.xmlFilename = nil
    self.entityFollow = nil
    self.entityThrower = nil
    self.isStaying = false
    self.abandonTimer = 0
    self.abandonTimerDuration = 6000
    self.abandonRange = 100
    self.name = ""
    self.tileIndexU = 0
    self.tileIndexV = 0
    self.spawnX = 0
    self.spawnY = 0
    self.spawnZ = 0
    self.forcedClipDistance = 80
    self.activatable = DogPetActivatable.new(self)
    registerObjectClassName(self, "Dog")
    self.dirtyFlag = self:getNextDirtyFlag()
    return self
end
function Dog:load(spawner, xmlFilename, spawnX, spawnY, spawnZ)
    self.spawner = spawner
    self.animalId = 0
    self.spawnX = spawnX
    self.spawnY = spawnY
    self.spawnZ = spawnZ
    self.xmlFilename = xmlFilename
    self.name = g_currentMission.animalNameSystem:getRandomName()
    local dogInstance = createAnimalCompanionManager(CompanionAnimalType.DOG, self.xmlFilename, "dog", self.spawnX, self.spawnY, self.spawnZ, g_terrainNode, self.isServer, self.isClient, 1, AudioGroup.ENVIRONMENT)
    if dogInstance == 0 then
        return false
    end
    self.dogInstance = dogInstance
    setCompanionWaterDetectionOffset(self.dogInstance, 0.45)
    setCompanionTrigger(self.dogInstance, self.animalId, "playerInteractionTriggerCallback", self)
    setCompanionTextureTile(self.dogInstance, self.animalId, 1, 1)
    setCompanionCollisionMask(self.dogInstance, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT, CollisionFlag.STATIC_OBJECT + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.BUILDING, CollisionFlag.WATER)
    g_soundManager:addIndoorStateChangedListener(self)
    setCompanionUseOutdoorAudioSetup(self.dogInstance, not g_soundManager:getIsIndoor())
    return true
end
function Dog:delete()
    self.isDeleted = true
    if self.dogInstance ~= nil then
        delete(self.dogInstance)
    end
    if self.isServer then
        g_messageCenter:unsubscribeAll(self)
    end
    unregisterObjectClassName(self)
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    g_soundManager:removeIndoorStateChangedListener(self)
    Dog:superClass().delete(self)
end
function Dog:loadFromXMLFile(xmlFile, key, _)
    self:setName(xmlFile:getValue(key .. "#name", ""))
    return true
end
function Dog:saveToXMLFile(xmlFile, key, _)
    xmlFile:setValue(key .. "#name", HTMLUtil.encodeToHTML(self.name))
end
function Dog:readStream(streamId, connection)
    if connection:getIsServer() then
        local spawner = NetworkUtil.readNodeObject(streamId)
        local xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
        local spawnX = streamReadFloat32(streamId)
        local spawnY = streamReadFloat32(streamId)
        local spawnZ = streamReadFloat32(streamId)
        local name = streamReadString(streamId)
        self.tileIndexU = streamReadUIntN(streamId, 3)
        self.tileIndexV = streamReadUIntN(streamId, 3)
        if self.xmlFilename ~= nil then
            self:load(spawner, xmlFilename, spawnX, spawnY, spawnZ)
            if spawner ~= nil then
                spawner.dog = self
            end
        end
        self:setTextureTileIndices(self.tileIndexU, self.tileIndexV)
        self:setName(name)
    end
    Dog:superClass().readStream(self, streamId, connection)
end
function Dog:writeStream(streamId, connection)
    if not connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.spawner)
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.xmlFilename))
        streamWriteFloat32(streamId, self.spawnX)
        streamWriteFloat32(streamId, self.spawnY)
        streamWriteFloat32(streamId, self.spawnZ)
        streamWriteString(streamId, self.name)
        streamWriteUIntN(streamId, self.tileIndexU, 3)
        streamWriteUIntN(streamId, self.tileIndexV, 3)
    end
    Dog:superClass().writeStream(self, streamId, connection)
end
function Dog:writeUpdateStream(streamId, connection, _)
    if not connection:getIsServer() then
        writeAnimalCompanionManagerToStream(self.dogInstance, streamId)
    end
end
function Dog:readUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        readAnimalCompanionManagerFromStream(self.dogInstance, streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)
    end
end
function Dog:update(dt)
    if self.isServer then
        if self.isStaying and self:isAbandoned(dt) then
            self:teleportToSpawn()
        end
        self:raiseActive()
    end
    Dog:superClass().update(self, dt)
end
function Dog:updateTick(dt)
    if self.isServer and (self.dogInstance ~= nil and getAnimalCompanionNeedNetworkUpdate(self.dogInstance)) then
        self:raiseDirtyFlags(self.dirtyFlag)
    end
    Dog:superClass().updateTick(self, dt)
end
function Dog:testScope(x, y, z, coeff, _)
    local distance, clipDistance = getCompanionClosestDistance(self.dogInstance, x, y, z)
    return distance < math.min(clipDistance * coeff, self.forcedClipDistance)
end
function Dog:getUpdatePriority(skipCount, x, y, z, coeff, _, _)
    local distance, clipDistance = getCompanionClosestDistance(self.dogInstance, x, y, z)
    if clipDistance == 0 then
        return 0
    end
    return (1 - distance / math.min(clipDistance * coeff, self.forcedClipDistance)) * 0.8 + 0.5 * skipCount * 0.2
end
function Dog:onGhostRemove()
    self:setVisibility(false)
end
function Dog:onGhostAdd()
    self:setVisibility(true)
end
function Dog:hourChanged()
    if self.isServer then
        if self.dogInstance ~= nil then
            setCompanionDaytime(self.dogInstance, g_currentMission.environment.dayTime)
        end
    end
end
function Dog:setName(name)
    self.name = name or ""
end
function Dog:setVisibility(state)
    if self.dogInstance ~= nil then
        setCompanionsVisibility(self.dogInstance, state)
        setCompanionsPhysicsUpdate(self.dogInstance, state)
    end
end
function Dog:playerInteractionTriggerCallback(_, otherId, onEnter, onLeave, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        if onEnter then
            if g_currentMission.accessHandler:canFarmAccess(g_localPlayer.farmId, self, false) then
                g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
                return
            end
        else
            g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
        end
    end
end
function Dog:followEntity(player)
    self.entityFollow = player.rootNode
    self.entityThrower = nil
    if self.isServer then
        setCompanionBehaviorFollowEntity(self.dogInstance, self.animalId, self.entityFollow)
        self.isStaying = false
    else
        g_client:getServerConnection():sendEvent(DogFollowEvent.new(self, player))
    end
end
function Dog:getDistanceTo(x, y, z)
    local distance, _ = getCompanionClosestDistance(self.dogInstance, x, y, z)
    return distance
end
function Dog:goToSpawn()
    self.entityFollow = nil
    self.entityThrower = nil
    if self.isServer then
        setCompanionBehaviorGotoEntity(self.dogInstance, self.animalId, self.spawner:getSpawnNode())
    else
        g_client:getServerConnection():sendEvent(DogFollowEvent.new(self, nil))
    end
end
function Dog:onFoodBowlFilled(foodBowlNode)
    self.entityFollow = nil
    self.entityThrower = nil
    setCompanionBehaviorFeed(self.dogInstance, self.animalId, foodBowlNode)
end
function Dog:fetchItem(player, ball)
    if self.isServer then
        local x, y, z = getWorldTranslation(ball.nodeId)
        ball.throwPos = { x, y, z }
        setCompanionBehaviorFetch(self.dogInstance, self.animalId, ball.nodeId, player.rootNode)
        self.entityThrower = player.rootNode
    else
        g_client:getServerConnection():sendEvent(DogFetchItemEvent.new(self, player, ball))
    end
end
function Dog:pet()
    if self.isServer then
        setCompanionBehaviorPet(self.dogInstance, self.animalId)
        local total, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "petDogCount", 1)
        if total ~= nil then
            g_achievementManager:tryUnlock("PetDog", total)
        end
    else
        g_client:getServerConnection():sendEvent(DogPetEvent.new(self))
    end
end
function Dog:idleStay()
    self.entityFollow = nil
    self.entityThrower = nil
    setCompanionBehaviorDefault(self.dogInstance, self.animalId)
    self.isStaying = true
end
function Dog:idleWander() end
function Dog:setTextureTileIndices(tileIndexU, tileIndexV)
    if self.dogInstance ~= 0 then
        setCompanionTextureTile(self.dogInstance, self.animalId, tileIndexU, tileIndexV)
    end
end
function Dog:isAbandoned(dt)
    local isEntityInRange = false
    for _, player in pairs(g_currentMission.players) do
        if player.isControlled then
            local entityX, entityY, entityZ = getWorldTranslation(player.rootNode)
            local distance, _ = getCompanionClosestDistance(self.dogInstance, entityX, entityY, entityZ)
            if distance < self.abandonRange then
                isEntityInRange = true
                break
            end
        end
    end
    if not isEntityInRange then
        for _, player in pairs(g_currentMission.vehicleSystem.enterables) do
            if player.spec_enterable ~= nil and player.spec_enterable.isControlled then
                local entityX, entityY, entityZ = getWorldTranslation(player.rootNode)
                local distance, _ = getCompanionClosestDistance(self.dogInstance, entityX, entityY, entityZ)
                if distance < self.abandonRange then
                    isEntityInRange = true
                    break
                end
            end
        end
    end
    if isEntityInRange then
        self.abandonTimer = self.abandonTimerDuration
    else
        self.abandonTimer = self.abandonTimer - dt
        if self.abandonTimer <= 0 then
            return true
        end
    end
    return false
end
function Dog:resetSteeringParms() end
function Dog:teleportToSpawn()
    if self.isServer then
        setCompanionPosition(self.dogInstance, self.animalId, self.spawnX, self.spawnY, self.spawnZ)
        self:idleWander()
        self:resetSteeringParms()
        self.isStaying = false
        self.entityFollow = nil
        self.entityThrower = nil
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ingameNotification_dogInDogHouse"))
    end
end
function Dog:playerFarmChanged(player)
    if self.isServer and (self.entityFollow == player.rootNode or self.entityThrower == player.rootNode) then
        self:idleStay()
    end
end
function Dog:onPlayerLeave(player)
    if self.isServer and (self.entityFollow == player.rootNode or self.entityThrower == player.rootNode) then
        self:idleStay()
    end
end
function Dog:finalizePlacement()
    self:setVisibility(true)
    if self.isServer then
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
        g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, Dog.playerFarmChanged, self)
    end
end
function Dog:onIndoorStateChanged(_)
    setCompanionUseOutdoorAudioSetup(self.dogInstance, not g_soundManager:getIsIndoor())
end
function Dog.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#name", "Name of dog")
end