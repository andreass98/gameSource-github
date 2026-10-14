NPC = {}
NPC.CONVERSATION_INDEX_SEND_NUM_BITS = 8
NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS = 8
NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS = 8
NPC.VOICEOVER_PLAYBACK_DELAY_MS = 500
NPC.VOICEOVER_DURATION_PER_WORD_MS = 350
local NPC_mt = Class(NPC, Object)
InitStaticObjectClass(NPC, "NPC")
g_xmlManager:addCreateSchemaFunction(function()
    NPC.xmlSchema = XMLSchema.new("npc")
end)
g_xmlManager:addInitSchemaFunction(function()
    local schema = NPC.xmlSchema
    schema:register(XMLValueType.STRING, "npc.class", "NPC controller class name", "NPC", false)
    schema:register(XMLValueType.STRING, "npc.filename", "NPC filename", nil, true)
    schema:register(XMLValueType.STRING, "npc.title", "NPC title", nil, true)
    schema:register(XMLValueType.STRING, "npc.imageFilename", "NPC image", nil, true)
    schema:register(XMLValueType.STRING, "npc.conversations.conversation(?)", "NPC conversation files", nil, true)
    schema:register(XMLValueType.STRING, "npc.conversations.conversation(?)#uniqueId", "NPC conversation unique id", nil, true)
    SoundManager.registerSampleXMLPaths(schema, "npc.sounds", "voice")
    SoundManager.registerSampleXMLPaths(schema, "npc.sounds", "phone")
    schema:register(XMLValueType.NODE_INDEX, "npc.interactionTrigger#node", "NPC interaction trigger node", nil, true)
    PlayerStyle.registerSavegameXMLPaths(schema, "npc.playerStyle")
    I3DUtil.registerI3dMappingXMLPaths(schema, "npc")
    local savegameSchema = NPCManager.xmlSchemaSavegame
    savegameSchema:register(XMLValueType.BOOL, "npcs.npc(?)#isActive", "If the npc is active")
    savegameSchema:register(XMLValueType.STRING, "npcs.npc(?)#spotUniqueId", "Id of the current npc spot")
    local playerKey = "npcs.npc(?).player(?)"
    savegameSchema:register(XMLValueType.STRING, playerKey .. "#uniqueUserId")
    savegameSchema:register(XMLValueType.INT, playerKey .. "#numContacts")
    savegameSchema:register(XMLValueType.STRING, playerKey .. ".conversation(?)#uniqueId")
    NPCConversation.registerSavegameXMLPaths(savegameSchema, playerKey .. ".conversation(?)")
    NPCSpot.registerSavegameXMLPaths(savegameSchema, "npcs.spots.spot(?)")
end)
function NPC.new(isServer, isClient, customMt)
    -- upvalues: (copy) NPC_mt
    local self = Object.new(isServer, isClient, customMt or NPC_mt)
    self.name = "Unknown NPC"
    self.title = "Unknown NPC"
    self.filename = nil
    self.imageFilename = nil
    self.finishedMissions = 0
    self.clipDistance = 100
    self.components = {}
    self.i3dMappings = {}
    self.isPlayerInRange = false
    self.spot = nil
    self.isActive = false
    self.x = 0
    self.y = 0
    self.z = 0
    self.rotX = 0
    self.rotY = 0
    self.rotZ = 0
    self.distanceToCamera = 0
    self.conversations = {}
    self.idToConversation = {}
    self.typeToConversations = {}
    self.filenameToConversation = {}
    self.availableConversations = {}
    self.inputData = ConversationInputData.new()
    self.currentConversationPlayerObjectId = nil
    self.isInConversation = false
    self.isInFacialAnimationConversation = false
    self.isPhoneConversation = false
    self.rotationSpeed = 0.006283185307179587
    self.farmData = {}
    self.userData = {}
    self.playerGraphics = HumanGraphicsComponent.new()
    self.playerGraphics.defaultState.isNPC = true
    self.playerGraphics:setIsFacialAnimationEnabled(true)
    self.playerGraphics:setSoundsEnabled(false)
    self.mapHotspot = NPCHotspot.new(self)
    self.dirtyFlag = self:getNextDirtyFlag()
    g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
    g_messageCenter:subscribe(MessageType.APP_SUSPENDED, self.onForceCancelConversation, self)
    return self
end
function NPC:load(xmlFilename)
    self.xmlFile = XMLFile.load("NPC", xmlFilename, NPC.xmlSchema)
    if self.xmlFile == nil then
        return false
    end
    self.xmlFilename = xmlFilename
    local customEnv, baseDirectory = Utils.getModNameAndBaseDirectory(self.xmlFile:getFilename())
    self.baseDirectory = baseDirectory
    local title = self.xmlFile:getValue("npc.title")
    if title == nil then
        Logging.xmlWarning(self.xmlFile, "Missing title for npc!")
        self.xmlFile:delete()
        self.xmlFile = nil
        return false
    end
    self.title = g_i18n:convertText(title, customEnv)
    local imageFilename = self.xmlFile:getValue("npc.imageFilename")
    if imageFilename == nil then
        Logging.xmlWarning(self.xmlFile, "Missing imageFilename for npc!")
        self.xmlFile:delete()
        self.xmlFile = nil
        return false
    end
    self.imageFilename = Utils.getFilename(imageFilename, baseDirectory)
    local i3dFilename = self.xmlFile:getValue("npc.filename")
    if i3dFilename == nil then
        Logging.xmlWarning(self.xmlFile, "Missing i3dFilename for npc!")
        self.xmlFile:delete()
        self.xmlFile = nil
        return false
    end
    self.i3dFilename = Utils.getFilename(i3dFilename, baseDirectory)
    self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, true, self.onI3DFileLoaded, self, nil)
    self.playerGraphics:initialize()
    link(getRootNode(), self.playerGraphics.graphicsRootNode)
    local playerStyle = PlayerStyle.new()
    playerStyle:loadFromXMLFile(self.xmlFile, "npc.playerStyle")
    self.playerStyle = playerStyle
    self.playerGraphics:setStyleAsync(playerStyle, self.loadCharacterFinished, self, {})
    for _, conversationKey in self.xmlFile:iterator("npc.conversations.conversation") do
        local uniqueId = self.xmlFile:getValue(conversationKey .. "#uniqueId")
        if uniqueId == nil then
            Logging.xmlWarning(self.xmlFile, "Missing uniqueId for conversation \'%s\'", conversationKey)
        elseif self.idToConversation[uniqueId] == nil then
            local conversationXMLFilename = self.xmlFile:getValue(conversationKey)
            if conversationXMLFilename == nil then
                Logging.xmlWarning(self.xmlFile, "No config file found for npc conversation \'%s\'", conversationKey)
            else
                local systemConversationXMLFilename = Utils.getFilename(conversationXMLFilename, baseDirectory)
                local conversation = NPCUtil.createConversationFromXML(self, systemConversationXMLFilename, uniqueId)
                if conversation ~= nil then
                    table.insert(self.conversations, conversation)
                    conversation:setIndex(#self.conversations)
                    self.idToConversation[uniqueId] = conversation
                    self.filenameToConversation[conversationXMLFilename] = conversation
                    local typeId = conversation:getType()
                    if self.typeToConversations[typeId] == nil then
                        self.typeToConversations[typeId] = {}
                    end
                    table.insert(self.typeToConversations[typeId], conversation)
                end
            end
        else
            Logging.xmlWarning(self.xmlFile, "UniqueId \'%s\' already used for conversation \'%s\'", uniqueId, conversationKey)
        end
    end
    return true
end
function NPC:writeStream(streamId, connection)
    NPC:superClass().writeStream(self, streamId, connection)
    local currentConversation = streamWriteBool
    if currentConversation(streamId, self.spot ~= nil) then
        streamWriteFloat32(streamId, self.x)
        streamWriteFloat32(streamId, self.y)
        streamWriteFloat32(streamId, self.z)
        streamWriteFloat32(streamId, self.rotX)
        streamWriteFloat32(streamId, self.rotY)
        streamWriteFloat32(streamId, self.rotZ)
    end
    local currentConversation = self.currentConversation
    if streamWriteBool(streamId, currentConversation ~= nil and self.currentConversationPlayerObjectId ~= nil) then
        NetworkUtil.writeNodeObjectId(streamId, self.currentConversationPlayerObjectId)
        streamWriteUIntN(streamId, currentConversation:getIndex(), NPC.CONVERSATION_INDEX_SEND_NUM_BITS)
        streamWriteBool(streamId, self.isInFacialAnimationConversation)
        streamWriteBool(streamId, self.isPhoneConversation)
    end
end
function NPC:readStream(streamId, connection, objectId)
    NPC:superClass().readStream(self, streamId, connection, objectId)
    if streamReadBool(streamId) then
        self.x = streamReadFloat32(streamId)
        self.y = streamReadFloat32(streamId)
        self.z = streamReadFloat32(streamId)
        self.rotX = streamReadFloat32(streamId)
        self.rotY = streamReadFloat32(streamId)
        self.rotZ = streamReadFloat32(streamId)
        self.isActive = true
    end
    if streamReadBool(streamId) then
        self:onConversationStarted(NetworkUtil.readNodeObjectId(streamId), streamReadUIntN(streamId, NPC.CONVERSATION_INDEX_SEND_NUM_BITS), streamReadBool(streamId), (streamReadBool(streamId)))
    end
end
function NPC:writeUpdateStream(streamId, connection, dirtyMask)
    NPC:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if streamWriteBool(streamId, self.spot ~= nil) then
        streamWriteFloat32(streamId, self.x)
        streamWriteFloat32(streamId, self.y)
        streamWriteFloat32(streamId, self.z)
        streamWriteFloat32(streamId, self.rotX)
        streamWriteFloat32(streamId, self.rotY)
        streamWriteFloat32(streamId, self.rotZ)
    end
end
function NPC:readUpdateStream(streamId, timestamp, connection)
    NPC:superClass().readUpdateStream(self, streamId, timestamp, connection)
    self.isActive = streamReadBool(streamId)
    if self.isActive then
        self.x = streamReadFloat32(streamId)
        self.y = streamReadFloat32(streamId)
        self.z = streamReadFloat32(streamId)
        self.rotX = streamReadFloat32(streamId)
        self.rotY = streamReadFloat32(streamId)
        self.rotZ = streamReadFloat32(streamId)
    end
    self:updatePosition()
end
function NPC:loadCharacterFinished(loadingState, _)
    if loadingState == HumanModelLoadingState.OK then
        self.playerGraphics:defaultAllParameters()
        self:updatePosition()
    else
        if loadingState == HumanModelLoadingState.CANCELED then
            Logging.info("Loading player model canceled")
        else
            Logging.error("Loading player model failed")
        end
        self.playerGraphics:delete()
        self.playerGraphics = nil
    end
end
function NPC:onI3DFileLoaded(node, failedReason, _)
    if failedReason == LoadI3DFailedReason.NONE then
        link(getRootNode(), node)
        self.node = node
        setClipDistance(node, self.clipDistance)
        I3DUtil.loadI3DComponents(node, self.components)
        I3DUtil.loadI3DMapping(self.xmlFile, "npc", self.components, self.i3dMappings)
        if g_currentMission:getIsClient() then
            self.samples = {}
            self.samples.voice = g_soundManager:loadSampleFromXML(self.xmlFile, "npc.sounds", "voice", self.baseDirectory, self.components, 1, AudioGroup.CHARACTER, self.i3dMappings, self, false)
            self.samples.phone = g_soundManager:loadSample2DFromXML(self.xmlFile, "npc.sounds", "phone", "", 1, AudioGroup.CHARACTER, false)
        end
        local triggerNode = self.xmlFile:getValue("npc.interactionTrigger#node", nil, self.components, self.i3dMappings)
        self.interactionTriggerNode = triggerNode
        self.interactionTriggerCallbackId = addTrigger(triggerNode, "onInteractionCallback", self, false, self.onInteractionCallback)
        self.activatable = NPCActivatable.new(self)
        self:updatePosition()
    end
    if self.xmlFile ~= nil then
        self.xmlFile:delete()
        self.xmlFile = nil
    end
end
function NPC:saveToSavegameXMLFile(xmlFile, key)
    if self.spot ~= nil then
        xmlFile:setValue(key .. "#spotUniqueId", self.spot:getUniqueId())
    end
    local userIndex = 0
    for uniqueUserId, userData in pairs(self.userData) do
        local userKey = string.format("%s.player(%d)", key, userIndex)
        xmlFile:setValue(userKey .. "#uniqueUserId", uniqueUserId)
        xmlFile:setValue(userKey .. "#numContacts", userData.numContacts or 0)
        local conversationIndex = 0
        for conversationUniqueId, conversationData in pairs(userData.conversations) do
            local conversation = self:getConversationById(conversationUniqueId)
            local conversationKey = string.format("%s.conversation(%d)", userKey, conversationIndex)
            xmlFile:setValue(conversationKey .. "#uniqueId", conversationUniqueId)
            conversation:saveToSavegameXMLFile(xmlFile, conversationKey, conversationData)
            conversationIndex = conversationIndex + 1
        end
        userIndex = userIndex + 1
    end
end
function NPC:loadFromSavegameXMLFile(xmlFile, key)
    self.pendingSpotUniqueId = xmlFile:getValue(key .. "#spotUniqueId") or self.pendingSpotUniqueId
    for _, userKey in xmlFile:iterator(key .. ".player") do
        local uniqueUserId = xmlFile:getValue(userKey .. "#uniqueUserId")
        if g_currentMission.playerSystem:getHasPlayerWithUniqueId(uniqueUserId) ~= nil then
            local userData = {
                ["numContacts"] = xmlFile:getValue(userKey .. "#numContacts", 0),
                ["conversations"] = {}
            }
            for _, conversationKey in xmlFile:iterator(userKey .. ".conversation") do
                local conversationUniqueId = xmlFile:getValue(conversationKey .. "#uniqueId")
                local conversation = self:getConversationById(conversationUniqueId)
                if conversation ~= nil then
                    local conversationData = {}
                    conversation:loadFromSavegameXMLFile(xmlFile, conversationKey, conversationData)
                    if next(conversationData) ~= nil then
                        userData.conversations[conversationUniqueId] = conversationData
                    end
                end
            end
            if next(userData.conversations) ~= nil then
                self.userData[uniqueUserId] = userData
            end
        end
    end
    return true
end
function NPC:delete()
    g_messageCenter:unsubscribeAll(self)
    for _, conversation in ipairs(self.conversations) do
        conversation:delete()
    end
    if self.interactionTriggerCallbackId ~= nil then
        removeTrigger(self.interactionTriggerNode, self.interactionTriggerCallbackId)
    end
    if self.samples ~= nil then
        g_soundManager:deleteSamples(self.samples)
    end
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end
    if self.node ~= nil then
        delete(self.node)
        self.node = nil
    end
    if self.xmlFile ~= nil then
        self.xmlFile:delete()
        self.xmlFile = nil
    end
    if self.mapHotspot ~= nil then
        self.mapHotspot:delete()
    end
    self.inputData:delete()
    if self.playerGraphics ~= nil then
        self.playerGraphics:delete()
        self.playerGraphics = nil
    end
    if self.playerStyle ~= nil then
        self.playerStyle:delete()
        self.playerStyle = nil
    end
    self.isPlayerInRange = false
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end
function NPC:update(dt)
    if self.pendingSpotUniqueId ~= nil then
        local spot = g_npcManager:getSpotByUniqueId(self.pendingSpotUniqueId)
        if spot ~= nil then
            self:setSpot(spot)
            self.forceUpdate = true
        end
        self.pendingSpotUniqueId = nil
    end
    if self.needPositionUpdate then
        local spot = self.playerGraphics
        if spot ~= nil and (self.forceUpdate or (self.distanceToCamera > self.clipDistance or not spot:getIsInCameraFrustum())) then
            self:updatePosition()
            self.needPositionUpdate = false
            self.forceUpdate = false
        end
        self:raiseActive()
    end
    if self.pendingConversationItemIndex ~= nil then
        self:showConversationItem(self.pendingConversationItemIndex, self.pendingConversationDisabledOptionIndices)
        self.pendingConversationItemIndex = nil
        self.pendingConversationDisabledOptionIndices = nil
    end
    if self.playerGraphics ~= nil then
        self.playerGraphics:defaultAllParameters()
        self.playerGraphics:update(dt)
        local spot = self:getInteractingPlayer() or g_localPlayer
        if spot ~= nil and self.node ~= nil then
            local px, _, pz = spot:getPosition()
            local x, _, z = getWorldTranslation(self.node)
            if MathUtil.vector2Length(px - x, pz - z) > 0 then
                local dirX, dirZ = MathUtil.vector2Normalize(px - x, pz - z)
                local currentRotation = self.playerGraphics:getModelYaw()
                local targetRotation = MathUtil.getYRotationFromDirection(dirX, dirZ)
                local difference = MathUtil.normalizeRotationForShortestPath(targetRotation, currentRotation)
                local difference
                if currentRotation < difference then
                    difference = math.min(currentRotation + dt * self.rotationSpeed, difference)
                else
                    difference = math.max(currentRotation - dt * self.rotationSpeed, difference)
                end
                local difference = MathUtil.getAngleDifference(difference, currentRotation)
                self.playerGraphics.defaultState.rotationVelocity = difference
                self.playerGraphics:setModelYaw(difference)
            end
        end
        if NPCManager.DEBUG_ANIMATIONS then
            self.playerGraphics.animation:debugDraw(0.025, 0.95, 0.014)
        end
    end
    local spot = self:getInteractingPlayer()
    if spot ~= nil and (spot == g_localPlayer and (self:getIsInFacialAnimationConversation() and not self:getIsPhoneConversation())) then
        spot:updateWhileInConversation(dt, self)
    end
end
function NPC:getName()
    return self.name
end
function NPC:getImageFilename()
    return self.imageFilename
end
function NPC:getBeVisited()
    return self.spot ~= nil
end
function NPC:getTeleportWorldPosition()
    if self.spot == nil then
        return nil
    end
    if self.spot.node ~= nil then
        return localToWorld(self.spot.node, 0, 0, 4)
    end
    local dirX, dirZ = MathUtil.getDirectionFromYRotation(self.rotY)
    return self.x + dirX * 4, self.y, self.z + dirZ * 4
end
function NPC:getTeleportWorldRotation()
    if self.spot == nil then
        return nil
    end
    local rotY = self.rotY
    if self.spot.node ~= nil then
        _, rotY, _ = getWorldRotation(self.spot.node)
    end
    return rotY + 3.141592653589793
end
function NPC:getMapHotspot()
    return self.mapHotspot
end
function NPC:getTitle()
    return self.title
end
function NPC:getConversationByFilename(filename)
    return self.filenameToConversation[filename]
end
function NPC:getConversationById(uniqueId)
    return self.idToConversation[uniqueId]
end
function NPC:updatePosition()
    if self.isActive then
        addToPhysics(self.node)
        if self.node ~= nil then
            setWorldTranslation(self.node, self.x, self.y, self.z)
            setWorldRotation(self.node, self.rotX, self.rotY, self.rotZ)
        end
        if self.playerGraphics ~= nil then
            self.playerGraphics:setModelPosition(self.x, self.y, self.z)
            self.playerGraphics:setModelRotation(self.rotX, self.rotY, self.rotZ)
        end
    elseif self.node ~= nil then
        removeFromPhysics(self.node)
    end
    self:updateVisibility()
    if self.isServer then
        self:raiseDirtyFlags(self.dirtyFlag)
    end
end
function NPC:setSpot(spot)
    local wasChanged = self.spot ~= spot
    self.spot = spot
    local x = spot ~= nil
    self.isActive = x
    if spot == nil then
        self:removeHotspot()
        goto l19
    end
    local x, y, z = spot:getPosition()
    local rotX, rotY, rotZ = spot:getRotation()
    if not wasChanged then
        if math.abs(x - self.x) > 0.01 then
            ::l12::
            wasChanged = true
            goto l14
        end
        if math.abs(y - self.y) > 0.01 then
            goto l12
        end
        if math.abs(z - self.z) > 0.01 then
            goto l12
        end
        ::l14::
        if not wasChanged then
            if math.abs(rotX - self.rotX) > 0.001 then
                ::l17::
                wasChanged = true
                goto l10
            end
            if math.abs(rotY - self.rotY) > 0.001 then
                goto l17
            end
            if math.abs(rotZ - self.rotZ) > 0.001 then
                goto l17
            end
        end
    end
    ::l10::
    self.x = x
    self.y = y
    self.z = z
    self.rotX = rotX
    self.rotY = rotY
    self.rotZ = rotZ
    self:addHotspots()
    self.mapHotspot:setWorldPosition(self.x, self.z)
    ::l19::
    if wasChanged then
        self:raiseActive()
        self.needPositionUpdate = true
    end
end
function NPC:getSpot()
    return self.spot
end
function NPC:getPosition()
    return self.x, self.y, self.z
end
function NPC:getPositionOffset(offsetX, offsetY, offsetZ)
    if self.node == nil then
        return offsetX, offsetY, offsetZ
    else
        return localToWorld(self.node, offsetX, offsetY, offsetZ)
    end
end
function NPC:getIsActive()
    return self.isActive
end
function NPC:onInteractionCallback(_, otherId, onEnter, onLeave, _)
    local player = g_localPlayer
    if self.isActive and (player ~= nil and otherId == player.rootNode) then
        if onEnter then
            self.isPlayerInRange = true
            g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
            return
        end
        if onLeave then
            self.isPlayerInRange = false
            mission.activatableObjectsSystem:removeActivatable(self.activatable)
        end
    end
end
function NPC:getCanInteract()
    if g_guidedTourManager:getIsTourRunning() and self.nextConversation == nil then
        return false
    end
    if self.isRequestPending then
        return false
    end
    if self.isInConversation then
        return false
    end
    if self.currentConversationPlayerObjectId ~= nil then
        return false
    end
    if not self.isActive then
        return false
    end
    return #self.conversations > 0
end
function NPC:getFacingDirection()
    if self.playerGraphics == nil then
        return 0, 0, 1
    else
        return self.playerGraphics:getModelDirection()
    end
end
function NPC:getIsPlayerInRange()
    return self.isPlayerInRange
end
function NPC:getFarmData(farm)
    self.farmData[farm.farmId] = self.farmData[farm.farmId] or {}
    return self.farmData[farm.farmId]
end
function NPC:getInteractingPlayer()
    if self.currentConversationPlayerObjectId == nil then
        return nil
    else
        return NetworkUtil.getObject(self.currentConversationPlayerObjectId)
    end
end
function NPC:getConversationByIndex(index)
    return self.conversations[index]
end
function NPC:getIsInConversation()
    return self.isInConversation
end
function NPC:getIsInFacialAnimationConversation()
    return self.isInFacialAnimationConversation
end
function NPC:getIsPhoneConversation()
    return self.isPhoneConversation
end
function NPC:getCurrentConversation()
    return self.currentConversation
end
function NPC:getIsFirstContact(player)
    if player == nil then
        return false
    end
    local uniqueUserId = player:getUniqueUserId()
    local userData = self.userData[uniqueUserId]
    if userData == nil then
        return true
    end
    return userData.numContacts == 0
end
function NPC:resetConversationNumTriggeredByType(player, typeId)
    if player == nil then
        return
    else
        local userData = self.userData[player:getUniqueUserId()]
        if userData ~= nil then
            for _, conversation in ipairs(self.typeToConversations[typeId]) do
                local conversationData = userData.conversations[conversation:getUniqueId()]
                if conversationData ~= nil then
                    conversationData.numTriggered = 0
                end
            end
        end
    end
end
function NPC:getWasConversationTriggered(player, uniqueId)
    if player == nil then
        return false
    end
    local userData = self.userData[player:getUniqueUserId()]
    if userData == nil then
        return false
    end
    return userData.conversations[uniqueId] ~= nil
end
function NPC:getConversationNumTriggered(player, uniqueId)
    if player == nil then
        return nil
    end
    local userData = self.userData[player:getUniqueUserId()]
    if userData == nil then
        return 0
    end
    local conversationData = userData.conversations[uniqueId]
    return conversationData == nil and 0 or conversationData.numTriggered
end
function NPC:getRandomConversation(player, typeId, _)
    local conversations = self.conversations
    if typeId ~= nil then
        if NPCConversationType.getName(typeId) == nil then
            Logging.devInfo("NPCConversationType not defined for id \'%s\'", typeId)
            return nil
        end
        if self.typeToConversations[typeId] == nil then
            Logging.devInfo("No conversations defined for type \'%s\'", NPCConversationType.getName(typeId))
            return nil
        end
    end
    return self:getRandomConversationFromList(player, conversations)
end
function NPC:getRandomConversationFromUniqueIds(player, uniqueIds)
    local conversations = {}
    for _, uniqueId in ipairs(uniqueIds) do
        table.insert(conversations, self.idToConversation[uniqueId])
    end
    return self:getRandomConversationFromList(player, conversations)
end
function NPC:getRandomConversationFromList(player, conversations)
    local availableConversations = {}
    local userData = self.userData[player:getUniqueUserId()]
    for _, conversation in ipairs(conversations) do
        conversation:init(player)
        local conversationUserData = nil
        if userData ~= nil then
            conversationUserData = userData.conversations[conversation:getUniqueId()]
        end
        if conversation:getIsAvailable(player, conversationUserData) then
            table.insert(availableConversations, conversation)
        end
    end
    if #availableConversations == 0 then
        Logging.devInfo("No conversations available")
        return nil
    end
    table.sort(availableConversations, function(a, b)
        return a:compare(b)
    end)
    local probabilityBasedConversations = {}
    local lastWeight = availableConversations[1]:getWeight()
    for conversationUserData, availableConversation in ipairs(availableConversations) do
        if lastWeight ~= availableConversation:getWeight() then
            break
        end
        for i = 1, availableConversation:getProbability() do
            table.insert(probabilityBasedConversations, availableConversation)
        end
    end
    return probabilityBasedConversations[math.random(1, #probabilityBasedConversations)]
end
function NPC:setNextConversation(conversation, finishCallback)
    self.nextConversation = conversation
    self.finishCallback = finishCallback
end
function NPC:setFollowUpConversation(conversation)
    assert(g_server ~= nil, "NPC.setFollowUpConversation is a server-only function")
    self.followUpConversation = conversation
end
function NPC:requestConversation(player)
    if player == nil then
        Logging.devInfo("NPC.requestConversation: no player  given")
        return
    elseif self.isServer then
        local playerObjectId = NetworkUtil.getObjectId(player)
        if self.currentConversationPlayerObjectId == nil then
            self.inputData:reset()
            local conversation = self.nextConversation
            if conversation == nil then
                if self:getIsFirstContact(player) then
                    conversation = self:getRandomConversation(player, NPCConversationType.FIRST_CONTACT)
                end
                if conversation == nil then
                    conversation = self:getRandomConversation(player, NPCConversationType.INTRO)
                end
                if conversation == nil then
                    conversation = self:getRandomConversation(player, NPCConversationType.DEFAULT)
                end
            end
            if conversation == nil then
                player.connection:sendEvent(NPCConversationStartFailedEvent.new(self, NPCConversationFailedState.FAILED_REASON_NO_CONVERSATION_AVAILABLE))
            else
                self:startConversation(player, conversation, true, false)
            end
        else
            if playerObjectId ~= self.currentConversationPlayerObjectId then
                player.connection:sendEvent(NPCConversationStartFailedEvent.new(self, NPCConversationFailedState.FAILED_REASON_NPC_BUSY))
            end
            return
        end
    elseif self.isRequestPending then
        Logging.devInfo("NPC.requestConversation: request is already pending")
    else
        self.isRequestPending = true
        g_client:getServerConnection():sendEvent(NPCConversationRequestEvent.new(self, player))
    end
end
function NPC:startConversation(player, conversation, useFacialAnimation, isPhoneConversation)
    local conversationId = g_server ~= nil
    assert(conversationId, "NPC:startConversation is a server only function")
    if player == nil then
        Logging.devInfo("NPC.startConversation: no player  given")
        return
    end
    local conversationItem = Utils.getNoNil(useFacialAnimation, true)
    local conversationItem = Utils.getNoNil(isPhoneConversation, false)
    if conversation == self.nextConversation then
        self.nextConversation = nil
    end
    conversation:loadTexts()
    local conversationItem = conversation:getConversationItemByIndex(1)
    if conversationItem == nil then
        player.connection:sendEvent(NPCConversationStartFailedEvent.new(self, NPCConversationFailedState.FAILED_REASON_NO_CONVERSATION_ITEMS))
        Logging.warning("NPC.startConversation: No text items defined for conversation \'%s\'", conversation.xmlFilename)
        conversation:unloadTexts()
        return
    end
    Logging.devInfo("NPC.startConversation: Talking to NPC \'%s\'. Start Conversation \'%s\'", self:getName(), conversation.xmlFilename)
    local conversationId = conversation:getUniqueId()
    local userData = self.userData[player:getUniqueUserId()] or {
        ["numContacts"] = 0,
        ["conversations"] = {}
    }
    local conversationUserData = userData.conversations[conversationId] or {}
    self.currentConversation = conversation
    self.currentConversationPlayerObjectId = NetworkUtil.getObjectId(player)
    conversation:start(player, conversationUserData)
    conversationItem:activate()
    userData.numContacts = userData.numContacts + 1
    if next(conversationUserData) ~= nil then
        userData.conversations[conversationId] = conversationUserData
        self.userData[player:getUniqueUserId()] = userData
    end
    local conversationIndex = conversation:getIndex()
    local disabledOptionIndices = {}
    if conversationItem.options ~= nil then
        for k, option in ipairs(conversationItem.options) do
            if option.isActive then
                if option.prerequisites ~= nil then
                    for _, optionPrerequisite in ipairs(option.prerequisites) do
                        if not optionPrerequisite:getIsValid(player) then
                            table.insert(disabledOptionIndices, k)
                            break
                        end
                    end
                end
            else
                table.insert(disabledOptionIndices, k)
            end
        end
    end
    g_server:broadcastEvent(NPCConversationStartEvent.new(self, player, conversationIndex, 1, disabledOptionIndices, conversationItem, conversationItem), true)
end
function NPC:onConversationStarted(playerNetworkId, conversationIndex, useFacialAnimation, isPhoneConversation)
    self.isRequestPending = false
    local conversation = self:getConversationByIndex(conversationIndex)
    if conversation == nil then
        Logging.devWarning("NPC.onConversationStarted: Unknown conversation with index \'%s\'", conversationIndex)
    else
        self.currentConversation = conversation
        self.currentConversationPlayerObjectId = playerNetworkId
        if not self.isInConversation then
            self.isInConversation = true
            self:startFacialAnimation(useFacialAnimation, isPhoneConversation)
        end
        Logging.devInfo("NPC.onConversationStarted: Started conversion \'%s\' with player \'%s\'", conversationIndex, playerNetworkId)
        conversation:loadTexts()
    end
end
function NPC:onConversationShowItem(conversationItemIndex, disabledOptionIndices)
    self.isRequestPending = false
    if self.currentConversation == nil then
        Logging.devWarning("NPC.onConversationShowItem: No conversation started")
    else
        self.pendingConversationItemIndex = conversationItemIndex
        self.pendingConversationDisabledOptionIndices = disabledOptionIndices
        self:raiseActive()
    end
end
function NPC:processAnswer(connection, conversationItemIndex, optionIndex)
    local player = g_server ~= nil
    assert(player, "NPC.processAnswer is a server-only function")
    local conversation = self.currentConversation
    if conversation == nil then
        self:resetConversation()
        Logging.warning("NPC.processAnswer: No conversation started")
        return
    else
        local player = self:getInteractingPlayer()
        if player.connection == connection then
            local conversationItem = conversation:getConversationItemByIndex(conversationItemIndex)
            if conversationItem == nil then
                self:resetConversation()
                Logging.devWarning("NPC.processAnswer: Unknown conversation item with index \'%s\'", conversationItemIndex)
                return
            else
                local isPhoneConversation
                if optionIndex == nil or optionIndex == 0 then
                    local options = conversationItem:getOptions()
                    if optionIndex == 0 and (options ~= nil and #options > 0) then
                        Logging.devWarning("NPC.processAnswer: Recieved optionIndex 0 but conversation item has options defined!")
                    end
                    isPhoneConversation = conversationItem:getNextId()
                else
                    local options = conversationItem:getOptionByIndex(optionIndex)
                    if options == nil then
                        self:resetConversation()
                        Logging.warning("NPC.processAnswer: Unknown conversation item option with index \'%s\'", optionIndex)
                        return
                    end
                    conversationItem:activateOption(optionIndex)
                    isPhoneConversation = options.nextId
                end
                local options = self.followUpConversation
                local isPhoneConversation = self:getIsPhoneConversation()
                local isFacialAnimationConversation = self:getIsInFacialAnimationConversation()
                if isPhoneConversation == nil then
                    self:finishConversation(options ~= nil)
                    if options ~= nil then
                        self.followUpConversation = nil
                        self:startConversation(player, options, isFacialAnimationConversation, isPhoneConversation)
                    end
                    return
                else
                    local nextConversationItem = conversation:getConversationItemById(isPhoneConversation)
                    if nextConversationItem == nil then
                        self:resetConversation()
                        Logging.warning("NPC.processAnswer: Unknown conversation item with id \'%s\'", isPhoneConversation)
                    else
                        nextConversationItem:activate()
                        local disabledOptionIndices = {}
                        if nextConversationItem.options ~= nil then
                            for k, option in ipairs(nextConversationItem.options) do
                                if option.isActive then
                                    if option.prerequisites ~= nil then
                                        for _, optionPrerequisite in ipairs(option.prerequisites) do
                                            if not optionPrerequisite:getIsValid(player) then
                                                table.insert(disabledOptionIndices, k)
                                            end
                                        end
                                    end
                                else
                                    table.insert(disabledOptionIndices, k)
                                end
                            end
                        end
                        g_server:broadcastEvent(NPCConversationItemShowEvent.new(self, nextConversationItem:getIndex(), disabledOptionIndices), true)
                    end
                end
            end
        else
            Logging.devWarning("NPC.processAnswer: Recieved answer from invalid user connection")
            return
        end
    end
end
function NPC:onFailedToStartConversation(failedReason)
    self.isRequestPending = false
    Logging.devInfo("Failed to start conversation", failedReason)
end
function NPC:showConversationItem(conversationItemIndex, conversationDisabledOptionIndices)
    local conversation = self.currentConversation
    if conversation == nil then
        self:resetConversation()
        Logging.warning("NPC.showConversationItem: No conversation started")
        return
    end
    local conversationItem = conversation:getConversationItemByIndex(conversationItemIndex)
    if conversationItem == nil then
        self:resetConversation()
        Logging.warning("NPC.showConversationItem: Unknown conversation item with index \'%s\'", conversationItemIndex)
        return
    end
    local player = self:getInteractingPlayer()
    if player == nil then
        Logging.warning("NPC.showConversationItem: Player not available/synched")
        return
    end
    conversationItem:init()
    local text = conversationItem:getText()
    local plainText = text:getPlainText()
    local optionTexts = {}
    local optionTextMapping = {}
    local options = conversationItem:getOptions()
    if options ~= nil then
        for _, index in ipairs(conversationDisabledOptionIndices) do
            ({})[index] = true
        end
        for _, index in ipairs(options) do
            if blockedOptionIndex[_] == nil then
                table.insert(optionTexts, index.text:getPlainText())
                optionTextMapping[#optionTexts] = _
            end
        end
    end
    local blockedOptionIndex = {
        ["conversationItem"] = conversationItem,
        ["conversationIndex"] = conversation:getIndex(),
        ["conversationItemIndex"] = conversationItemIndex,
        ["conversationOptionTextMapping"] = optionTextMapping
    }
    local dialogDuration = 2000
    if conversationItem:getIsActive() then
        local audioFilename = text:getAudioFilename()
        if audioFilename == nil then
            dialogDuration = Utils.getNumOfWords(plainText) * NPC.VOICEOVER_DURATION_PER_WORD_MS + NPC.VOICEOVER_PLAYBACK_DELAY_MS * 2
        else
            local sample = nil
            if self:getIsPhoneConversation() then
                if self.samples.phone ~= nil then
                    g_soundManager:createAudio2d(self.samples.phone, audioFilename)
                    g_soundManager:playSample(self.samples.phone, NPC.VOICEOVER_PLAYBACK_DELAY_MS)
                    dialogDuration = self.samples.phone.duration + NPC.VOICEOVER_PLAYBACK_DELAY_MS * 2
                    sample = self.samples.phone
                end
            elseif self.samples.voice ~= nil then
                g_soundManager:createAudioSource(self.samples.voice, audioFilename)
                g_soundManager:playSample(self.samples.voice, NPC.VOICEOVER_PLAYBACK_DELAY_MS)
                dialogDuration = self.samples.voice.duration + NPC.VOICEOVER_PLAYBACK_DELAY_MS * 2
                sample = self.samples.voice
            end
            if self:getIsInFacialAnimationConversation() and (self.playerGraphics ~= nil and self.playerGraphics.facialAnimation ~= nil) then
                local _ = nil
                if player ~= nil then
                    local index = player:getCurrentVehicle()
                    if index == nil then
                        if player.graphicsComponent.model ~= nil then
                            _ = player.graphicsComponent.model.faceFocusNode
                        end
                    else
                        local enterable = index.spec_enterable
                        if enterable ~= nil then
                            for _, camera in ipairs(enterable.cameras) do
                                if camera.isInside then
                                    _ = camera.cameraNode
                                    break
                                end
                            end
                        end
                    end
                end
                self.playerGraphics.facialAnimation:start(text:getEmotionFilename(), sample, plainText, _)
            end
        end
    else
        plainText = nil
    end
    if #optionTexts > 0 then
        dialogDuration = nil
    end
    if player ~= nil and player == g_localPlayer then
        ConversationDialog.show(self.title, plainText, optionTexts, dialogDuration, self.dialogCallback, self, blockedOptionIndex)
    end
end
function NPC:dialogCallback(canceled, textOptionIndex, args)
    if self.currentConversation == nil or not (self.currentConversation:getCanBeCanceled() and canceled) then
        self.isRequestPending = true
        g_client:getServerConnection():sendEvent(NPCConversationAnswerEvent.new(self, args.conversationItemIndex, args.conversationOptionTextMapping[textOptionIndex]))
    else
        self:cancelConversation()
    end
end
function NPC:onUserRemoved(user)
    if g_server ~= nil and self:getIsInConversation() then
        local player = self:getInteractingPlayer()
        if player ~= nil and player.userId == user:getId() then
            Logging.devInfo("NPC.onUserRemoved conversation user \'%s\' left the game", user:getNickname())
            self:cancelConversation()
        end
    end
end
function NPC:onForceCancelConversation()
    local player = self:getInteractingPlayer()
    if player ~= nil and player == g_localPlayer then
        self:cancelConversation()
    end
end
function NPC:onCanceledConversation()
    self.isRequestPending = false
    Logging.devInfo("onCanceledConversation")
    if self.isInConversation then
        self.isInConversation = false
        ConversationDialog.hide()
        self:stopFacialAnimation()
    end
    self:resetConversation()
end
function NPC:cancelConversation(connection)
    if g_server == nil then
        g_client:getServerConnection():sendEvent(NPCConversationCancelEvent.new(self))
        return
    else
        local player = self:getInteractingPlayer()
        if player == nil then
            return
        elseif connection == nil or connection == player.connection then
            g_server:broadcastEvent(NPCConversationCancelEvent.new(self), true)
        else
            Logging.devWarning("NPC.cancelConversation: Cancel event recieved from invalid user")
        end
    end
end
function NPC:onFinishedConversation(hasFollowUpConversation)
    self.isRequestPending = false
    if self.isInConversation and not hasFollowUpConversation then
        self.isInConversation = false
        ConversationDialog.hide()
        self:stopFacialAnimation()
    end
    self:resetConversation()
end
function NPC:finishConversation(hasFollowUpConversation)
    assert(g_server ~= nil, "NPC:finishConversation is a server-only function")
    g_server:broadcastEvent(NPCConversationFinishedEvent.new(self, hasFollowUpConversation), true)
    if self.finishCallback ~= nil then
        self.finishCallback()
    end
end
function NPC:resetConversation()
    Logging.devInfo("NPC.resetConversation")
    if g_soundManager:getIsSamplePlaying(self.samples.voice) then
        g_soundManager:stopSample(self.samples.voice)
    end
    if g_soundManager:getIsSamplePlaying(self.samples.phone) then
        g_soundManager:stopSample(self.samples.phone)
    end
    if self.playerGraphics ~= nil and self.playerGraphics.facialAnimation ~= nil then
        self.playerGraphics.facialAnimation:stop()
        self.playerGraphics.facialAnimation:reset()
    end
    if self.currentConversation ~= nil then
        self.currentConversation:reset()
    end
    self.currentConversation = nil
    self.currentConversationPlayerObjectId = nil
    self.followUpConversation = nil
    self.currentConversationConnection = nil
end
function NPC:setInputData(name, value)
    self.inputData:setData(name, value)
end
function NPC:getInputData(name)
    return self.inputData:getData(name)
end
function NPC:setDistanceToCamera(distance)
    self.distanceToCamera = distance
    if distance < self.clipDistance then
        self:raiseActive()
    end
    self:updateVisibility()
    if self.playerGraphics ~= nil then
        self.playerGraphics:updateFacialAnimationVisibilityFromCameraDistance(distance)
    end
end
function NPC:updateVisibility()
    local isVisible = self.isActive
    if self.distanceToCamera > self.clipDistance then
        isVisible = false
    end
    if self.playerGraphics ~= nil then
        if isVisible then
            self.playerGraphics:show()
        else
            self.playerGraphics:hide()
        end
    end
    if self.node ~= nil then
        setVisibility(self.node, isVisible)
    end
end
function NPC:addHotspots()
    if self.mapHotspot ~= nil and not self.isHotspotAdded then
        self.isHotspotAdded = true
        g_currentMission:addMapHotspot(self.mapHotspot)
    end
end
function NPC:removeHotspot()
    if self.mapHotspot ~= nil and self.isHotspotAdded then
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.isHotspotAdded = false
    end
end
function NPC:validate()
    for _, conversation in ipairs(self.conversations) do
        conversation:validate()
    end
end
function NPC:startFacialAnimation(useFacialAnimation, isPhoneConversation)
    if useFacialAnimation then
        self.isInFacialAnimationConversation = true
        if not isPhoneConversation then
            local currentPlayer = NetworkUtil.getObject(self.currentConversationPlayerObjectId)
            local player = g_localPlayer
            if currentPlayer ~= nil and (currentPlayer == player and (player.isOwner and player.camera ~= nil)) then
                player.camera:setIsInConversation(true)
                player.camera:setTargetOverrideFromNode(player.graphicsComponent.rightShoulderCameraNode, 250)
            end
        end
    end
    if isPhoneConversation then
        self.isPhoneConversation = true
    end
end
function NPC:stopFacialAnimation()
    if self.isInFacialAnimationConversation then
        self.isInFacialAnimationConversation = false
        if not self:getIsPhoneConversation() then
            local currentPlayer = NetworkUtil.getObject(self.currentConversationPlayerObjectId)
            local player = g_localPlayer
            if currentPlayer ~= nil and (currentPlayer == player and (player.isOwner and player.camera ~= nil)) then
                player.camera:setIsInConversation(false)
                player.camera:clearTargetOverride()
            end
        end
    end
    self.isPhoneConversation = false
end