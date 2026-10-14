Player = {}
local Player_mt = Class(Player, Object)
InitStaticObjectClass(Player, "Player")
Player.MAX_HAND_TOOL_CARRY_MASS = 15
Player.HAND_TOOL_COUNT_NUM_BITS = 4
Player.DEBUG_DISPLAY_FLAG = {
    ["NONE"] = 0,
    ["INITIALISATION"] = 1,
    ["HANDTOOLS"] = 2,
    ["NETWORK"] = 4,
    ["GRAPHICS"] = 8,
    ["STATE"] = 16,
    ["MOVEMENT"] = 32,
    ["INPUT"] = 64,
    ["ALL"] = 255
}
Player.START_WITH_SUPERSPEED = StartParams.getIsSet("playerSuperSpeed")
Player.DEBUG_DISPLAY_FLAG.NETWORK_HANDTOOLS = bit32.bor(Player.DEBUG_DISPLAY_FLAG.NETWORK, Player.DEBUG_DISPLAY_FLAG.HANDTOOLS)
Player.DEBUG_DISPLAY_FLAG.NETWORK_GRAPHICS = bit32.bor(Player.DEBUG_DISPLAY_FLAG.NETWORK, Player.DEBUG_DISPLAY_FLAG.GRAPHICS)
Player.DEBUG_DISPLAY_FLAG.NETWORK_MOVEMENT = bit32.bor(Player.DEBUG_DISPLAY_FLAG.NETWORK, Player.DEBUG_DISPLAY_FLAG.MOVEMENT)
Player.DEBUG_DISPLAY_FLAG.NETWORK_INPUT = bit32.bor(Player.DEBUG_DISPLAY_FLAG.NETWORK, Player.DEBUG_DISPLAY_FLAG.INPUT)
Player.currentDebugFlag = Player.DEBUG_DISPLAY_FLAG.NONE
Player.currentDebugVerbosityFlag = Player.DEBUG_DISPLAY_FLAG.NONE
function Player.registerXMLPaths(xmlSchema)
    xmlSchema:register(XMLValueType.STRING, "player.filename", "The file path of the player\'s i3d file", nil, true)
    HumanModel.registerXMLPaths(xmlSchema, "player")
    PlayerStyle.registerXMLPaths(xmlSchema)
    IKUtil.registerIKChainXMLPaths(xmlSchema, "player.ikChains.ikChain(?)")
end
function Player.registerSavegameXMLPaths(savegameXMLSchema, baseKey)
    baseKey = baseKey .. ".player(?)"
    savegameXMLSchema:register(XMLValueType.STRING, baseKey .. "#uniqueUserId", "The unique user id of the player", nil, true)
    savegameXMLSchema:register(XMLValueType.STRING, baseKey .. "#timeLastConnected", "The date and time that the player last connected", nil, false)
    savegameXMLSchema:register(XMLValueType.VECTOR_3, baseKey .. ".spawn#position", "The player\'s spawn position", nil, false)
    savegameXMLSchema:register(XMLValueType.ANGLE, baseKey .. ".spawn#yaw", "The player\'s spawn yaw (y rotation)", nil, false)
    savegameXMLSchema:register(XMLValueType.STRING, baseKey .. ".spawn#vehicleUniqueId", "The unique id of the vehicle in which to spawn", nil, false)
    savegameXMLSchema:register(XMLValueType.STRING, baseKey .. ".handTools.handTool(?)#uniqueId", "The unique id of the hand tool the player owns", nil, true)
    PlayerStyle.registerSavegameXMLPaths(savegameXMLSchema, baseKey .. ".style")
    PlayerStyle.registerSavegameXMLPaths(savegameXMLSchema, "gameSettings.lastPlayerStyle")
end
function Player.saveDataToXMLFile(xmlFile, playerData, baseKey)
    xmlFile:setValue(baseKey .. "#uniqueUserId", playerData.uniqueId)
    xmlFile:setValue(baseKey .. "#timeLastConnected", playerData.lastConnectedDateTime)
    if playerData.spawnPositionX ~= nil then
        xmlFile:setValue(baseKey .. ".spawn#position", playerData.spawnPositionX, playerData.spawnPositionY, playerData.spawnPositionZ)
    end
    if playerData.spawnYaw ~= nil then
        xmlFile:setValue(baseKey .. ".spawn#yaw", playerData.spawnYaw)
    end
    if not string.isNilOrWhitespace(playerData.spawnVehicleUniqueId) then
        xmlFile:setValue(baseKey .. ".spawn#vehicleUniqueId", playerData.spawnVehicleUniqueId)
    end
    if playerData.style:isValid() then
        playerData.style:saveToXMLFile(xmlFile, baseKey .. ".style")
    end
    for i, handToolUniqueId in ipairs(playerData.handToolUniqueIds) do
        xmlFile:setValue(string.format("%s.handTools.handTool(%d)#uniqueId", baseKey, i - 1), handToolUniqueId)
    end
end
function Player.loadDataFromXMLFile(xmlFile, baseKey)
    local uniqueId = xmlFile:getValue(baseKey .. "#uniqueUserId", nil)
    local lastConnectedDateTime = xmlFile:getValue(baseKey .. "#timeLastConnected", getDate("%Y/%m/%d %H:%M"))
    if not string.isNilOrWhitespace(uniqueId) then
        local spawnPositionX
        if xmlFile:hasProperty(baseKey .. ".style") then
            spawnPositionX = PlayerStyle.new()
            spawnPositionX:loadFromXMLFile(xmlFile, baseKey .. ".style")
            if not spawnPositionX:isValid() then
                Logging.xmlWarning(xmlFile, "Player with unique id of %s has an invalid style, using default!", uniqueId)
                spawnPositionX = PlayerStyle.defaultStyle()
            end
        else
            spawnPositionX = PlayerStyle.defaultStyle()
        end
        local spawnPositionX, spawnPositionY, spawnPositionZ = xmlFile:getValue(baseKey .. ".spawn#position", nil)
        local spawnYaw = xmlFile:getValue(baseKey .. ".spawn#yaw", nil)
        local spawnVehicleUniqueId = xmlFile:getValue(baseKey .. ".spawn#vehicleUniqueId", nil)
        local handToolUniqueIds = {}
        for nodeIndex, handToolKey in xmlFile:iterator(baseKey .. ".handTools.handTool") do
            local handToolUniqueId = xmlFile:getValue(handToolKey .. "#uniqueId", nil)
            if string.isNilOrWhitespace(handToolUniqueId) then
                Logging.xmlError(xmlFile, "Player\'s hand tool is missing unique id!")
            else
                table.insert(handToolUniqueIds, handToolUniqueId)
            end
        end
        return {
            ["uniqueId"] = uniqueId,
            ["lastConnectedDateTime"] = lastConnectedDateTime,
            ["spawnPositionX"] = spawnPositionX,
            ["spawnPositionY"] = spawnPositionY,
            ["spawnPositionZ"] = spawnPositionZ,
            ["spawnYaw"] = spawnYaw,
            ["spawnVehicleUniqueId"] = spawnVehicleUniqueId,
            ["handToolUniqueIds"] = handToolUniqueIds,
            ["style"] = spawnPositionX
        }
    end
    Logging.xmlError(xmlFile, "Player is missing unique id!")
end
function Player.createServerInstance(isClient, isOwner, connection, userId, farmId, userManager)
    local self = Player.new(true, isClient)
    self.farmId = farmId
    self.userId = userId
    self:setUniqueUserId(userManager:getUniqueUserIdByUserId(userId))
    self.walkDistance = 0
    self.animUpdateTime = 0
    self.allowPlayerPickUp = Platform.allowPlayerPickUp
    self.debugFlightMode = false
    self.debugFlightCoolDown = 0
    self.requestedFieldData = false
    self:initialise(connection, isOwner)
    local playerData = g_currentMission.playerSystem:getPlayerDataByUniqueId(self.uniqueUserId)
    self:load(playerData)
    local style = nil
    local isDefaultStyle = false
    if playerData ~= nil then
        style = playerData.style
    end
    if style == nil then
        local lastPlayerStyle = g_gameSettings.lastPlayerStyle
        if isOwner and (lastPlayerStyle ~= nil and lastPlayerStyle:isValid()) then
            style = PlayerStyle.defaultStyle()
            style:copyFrom(lastPlayerStyle)
        end
        if style == nil then
            style = PlayerStyle.defaultStyle()
            isDefaultStyle = true
        end
    end
    self:setStyleAsync(style, isDefaultStyle, nil, true)
    self:register(false)
    return self
end
function Player.new(isServer, isClient)
    -- upvalues: (copy) Player_mt
    local self = Object.new(isServer, isClient, Player_mt)
    self.userId = nil
    self.isDefaultStyle = true
    self.filename = nil
    self.connection = nil
    self.networkComponent = nil
    self.positionalInterpolator = nil
    self.spawnVehicle = nil
    self.spawnPositionX = nil
    self.spawnPositionY = nil
    self.spawnPositionZ = nil
    self.spawnYaw = nil
    self.dirtyFlag = self:getNextDirtyFlag()
    self.isOwner = false
    self.isControlled = false
    self.isLocallyControlled = nil
    self.farmId = FarmManager.SPECTATOR_FARM_ID
    self.stateEvents = {}
    self:registerStateEvents()
    self.stateFunctions = {}
    self:registerStateFunctions()
    self.playerHotspot = PlayerHotspot.new()
    self.hands = nil
    self.carriedHandTools = {}
    self.currentHandTool = nil
    self.currentHandToolIndex = 0
    self.lastHandToolIndex = 0
    self.maximumHandToolCarryMass = Player.MAX_HAND_TOOL_CARRY_MASS
    self.inputComponent = nil
    self.camera = nil
    self.targeter = nil
    self.graphicsComponent = HumanGraphicsComponent.new()
    self.graphicsState = PlayerGraphicsState.new()
    self.capsuleController = PlayerCCT.new()
    self.mover = PlayerMover.new(self)
    self.stateMachine = PlayerStateMachine.new(self)
    self.stateMachine:createStateIndexNameMapping()
    self.hudUpdater = PlayerHUDUpdater.new()
    self.debugFunctionId = nil
    self.isFirstPerson = true
    self.isHoldingChainsaw = false
    self.isCutting = false
    self.isVerticalCut = true
    self.toggleFlightModeCommand = nil
    self.toggleSuperSpeedCommand = nil
    self.isStrafeWalkMode = false
    self.forceHandToolFirstPerson = false
    self.isFlashlightActive = false
    return self
end
function Player:initialise(connection, isOwner)
    self.connection = connection
    self.isOwner = isOwner == true
    if self.isOwner or self.isClient then
        g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_LOADED, Player.onStartMission, self)
    end
    if self.isServer then
        g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, Player.playerFarmChanged, self)
    end
    g_messageCenter:subscribe(ContractingStateEvent, Player.onContractingStateChanged, self)
    self.stateMachine.states.onFoot:setIsPassive(not self.isOwner)
    self.rootNode = createTransformGroup("Player Root")
    link(getRootNode(), self.rootNode)
    self.capsuleController:setMass(self.graphicsComponent.model:getMass())
    self.capsuleController:setRootNode(self.rootNode)
    self.capsuleController:rebuild()
    g_currentMission:addNodeObject(self.rootNode, self)
    if self.isOwner then
        self.inputComponent = PlayerInputComponent.new(self)
        self.camera = PlayerCamera.new(self)
        self.targeter = PlayerTargeter.new(self)
        self.inputComponent:registerActionEvents()
        self.camera:initialise()
        HandToolUtil.addHandToolHolderTarget(self.targeter)
    elseif self.isServer then
        self.positionalInterpolator = PlayerPositionalInterpolator.new(self, PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE)
    else
        self.positionalInterpolator = PlayerPositionalInterpolator.new(self, PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE)
    end
    self:addStateEvent(function(...)
        -- upvalues: (copy) self
        for i, handTool in ipairs(self.carriedHandTools) do
            handTool:setCarryingPlayerEnteredVehicle()
        end
    end, nil, "onEnterVehicle")
    self:addStateEvent(function(...)
        -- upvalues: (copy) self
        for i, handTool in ipairs(self.carriedHandTools) do
            handTool:setCarryingPlayerExitedVehicle()
        end
    end, nil, "onLeaveVehicle")
    self.graphicsComponent:initialize()
    self.mover:initialise()
    if self.isServer then
        self.networkComponent = PlayerServerNetworkComponent.new(self)
    elseif isOwner then
        self.networkComponent = PlayerLocalNetworkComponent.new(self)
    else
        self.networkComponent = PlayerRemoteNetworkComponent.new(self)
    end
    self.isStrafeWalkMode = not self.isOwner
    self.forceHandToolFirstPerson = self.isOwner
    self.mover:setPosition(0, -200, 0, true)
    if self.isOwner and g_addTestCommands then
        addConsoleCommand("gsTipToTrigger", "Tips a fillType into a trigger", "consoleCommandTipToTrigger", self, "fillTypeName; amount")
        addConsoleCommand("gsPlayerToggleStrafeWalkMode", "Toggles strafe walk mode", "consoleCommandToggleStrafeWalkMode", self)
        addConsoleCommand("gsPlayerToggleForceHandToolFirstPerson", "Toggle the force handtool mode", "consoleCommandToggleForceHandToolFirstPerson", self)
    end
end
function Player:load(playerData)
    local mission = g_currentMission
    self:createConsoleCommands()
    if self.isServer then
        if playerData ~= nil then
            self.spawnPositionX = playerData.spawnPositionX
            self.spawnPositionY = playerData.spawnPositionY
            self.spawnPositionZ = playerData.spawnPositionZ
            self.spawnYaw = playerData.spawnYaw
            self.spawnVehicle = self:resolveSpawnVehicle(playerData.spawnVehicleUniqueId)
            self.pendingHandToolUniqueIds = {}
            for _, handToolUniqueId in ipairs(playerData.handToolUniqueIds) do
                table.insert(self.pendingHandToolUniqueIds, handToolUniqueId)
            end
        end
        self.pendingStartHandTools = {}
        local handData = HandToolLoadingData.new()
        handData:setFilename("data/handTools/hands.xml")
        handData:setOwnerFarmId(self.farmId)
        handData:setIsSaved(false)
        handData:setCanBeDropped(false)
        self.pendingStartHandTools[handData] = true
        handData.areHands = true
        handData:load(self.onStartHandToolLoaded, self, handData)
        local flashlightData = HandToolLoadingData.new()
        flashlightData:setFilename("data/handTools/brandless/flashlight/flashlight.xml")
        flashlightData:setOwnerFarmId(self.farmId)
        flashlightData:setIsSaved(false)
        flashlightData:setCanBeDropped(false)
        flashlightData:setHolder(self)
        self.pendingStartHandTools[flashlightData] = true
        flashlightData:load(self.onStartHandToolLoaded, self, flashlightData)
        local startHandTools = mission.handToolSystem:getStartingHandTools()
        for _, xmlFilename in ipairs(startHandTools) do
            local data = HandToolLoadingData.new()
            data:setFilename(xmlFilename)
            data:setOwnerFarmId(self.farmId)
            data:setHolder(self)
            data:setIsSaved(false)
            data:setCanBeDropped(false)
            self.pendingStartHandTools[data] = true
            data:load(self.onStartHandToolLoaded, self, data)
        end
        self.mover:teleportToSpawnPoint()
    end
    self.capsuleController:rebuild()
    self.mover:onPlayerLoad()
    if self.isOwner then
        self.inputComponent:onPlayerLoad()
        self.capsuleController:onPlayerLoad(self)
        self.camera:onPlayerLoad()
    else
        self.mover:disablePhysics()
    end
    mission.playerSystem:addPlayer(self)
    if self.isServer and not self.isOwner then
        self:onStartMission()
    end
end
function Player:delete()
    local currentVehicle = self:getCurrentVehicle()
    if currentVehicle ~= nil and not currentVehicle:getIsBeingDeleted() then
        local seatIndex = nil
        if currentVehicle.getPassengerSeatIndexByPlayer ~= nil then
            seatIndex = currentVehicle:getPassengerSeatIndexByPlayer(self.userId)
        end
        if seatIndex == nil then
            currentVehicle:onPlayerLeaveVehicle()
        else
            currentVehicle:leavePassengerSeat(self.isOwner, seatIndex)
        end
    end
    local seatIndex = g_currentMission
    seatIndex.playerSystem:removePlayer(self)
    if self.pendingStartHandTools ~= nil then
        for loadingData in pairs(self.pendingStartHandTools) do
            loadingData:cancelLoading()
        end
    end
    if self.swsObstacle ~= nil then
        seatIndex.shallowWaterSimulation:removeObstacle(self.swsObstacle)
        self.swsObstacle = nil
    end
    if seatIndex.aiSystem ~= nil then
        seatIndex.aiSystem:removeObstacle(self.rootNode)
    end
    g_messageCenter:unsubscribeAll(self)
    if self.hudUpdater ~= nil then
        self.hudUpdater:delete()
        self.hudUpdater = nil
    end
    if self.isOwner then
        self.inputComponent:unregisterActionEvents()
        self.inputComponent:stopListeningForBindingChanges()
        removeConsoleCommand("gsPlayerDebugFlagToggle")
        removeConsoleCommand("gsPlayerDebugFlagVerbosityToggle")
        removeConsoleCommand("gsPlayerFlightToggle")
    end
    if self.playerHotspot ~= nil then
        seatIndex:removeMapHotspot(self.playerHotspot)
        self.playerHotspot:delete()
        self.playerHotspot = nil
    end
    if self.stateMachine ~= nil then
        self.stateMachine:delete()
        self.stateMachine = nil
    end
    if self.hands ~= nil then
        self.hands:delete()
        self.hands = nil
    end
    local i = #self.carriedHandTools
    for i = i, 1, -1 do
        local loadingData = self.carriedHandTools[i]
        if loadingData.isPlayerStartHandTool then
            loadingData:delete()
        else
            loadingData:setHolder(nil, true)
        end
    end
    if self.graphicsComponent ~= nil then
        self.graphicsComponent:delete()
        self.graphicsComponent = nil
    end
    if self.mover ~= nil then
        self.mover:delete()
        self.mover = nil
    end
    if self.capsuleController ~= nil then
        self.capsuleController:delete()
        self.capsuleController = nil
    end
    if self.camera ~= nil then
        self.camera:delete()
        self.camera = nil
    end
    g_currentMission:removeNodeObject(self.rootNode)
    delete(self.rootNode)
    self.isDeleted = true
    Player:superClass().delete(self)
end
function Player:writeStream(streamId, connection)
    Player:superClass().writeStream(self, streamId, connection)
    streamWriteBool(streamId, connection == self.connection)
    local x, y, z = self.capsuleController:getPosition()
    streamWriteFloat32(streamId, x)
    streamWriteFloat32(streamId, y)
    streamWriteFloat32(streamId, z)
    streamWriteBool(streamId, self.isControlled)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    User.streamWriteUserId(streamId, self.userId)
    if streamWriteBool(streamId, not self.isDefaultStyle) then
        self.graphicsComponent:getStyle():writeStream(streamId, connection)
    end
    if streamWriteBool(streamId, self.hands ~= nil) then
        NetworkUtil.writeNodeObject(streamId, self.hands)
    end
end
function Player:readStream(streamId, connection, _)
    Player:superClass().readStream(self, streamId, connection)
    local isOwner = streamReadBool(streamId)
    local x = streamReadFloat32(streamId)
    local y = streamReadFloat32(streamId)
    local z = streamReadFloat32(streamId)
    local isControlled = streamReadBool(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.userId = User.streamReadUserId(streamId)
    self:initialise(connection, isOwner)
    local style
    if streamReadBool(streamId) then
        style = self.graphicsComponent:getStyle()
        style:readStream(streamId, connection)
    else
        style = PlayerStyle.defaultStyle()
    end
    if streamReadBool(streamId) then
        self.pendingHandsId = NetworkUtil.readNodeObjectId(streamId)
    end
    self:load(nil)
    self:setStyleAsync(style, false, nil, true)
    self:teleportTo(x, y, z, true, true)
    if isControlled then
        self:show()
    else
        self:hide()
    end
end
function Player:writeUpdateStream(streamId, connection, dirtyMask)
    if self.networkComponent then
        self.networkComponent:writeUpdateStream(streamId, connection, dirtyMask)
    end
end
function Player:readUpdateStream(streamId, timestamp, connection)
    if self.networkComponent then
        self.networkComponent:readUpdateStream(streamId, connection, timestamp)
    end
end
function Player:onStartHandToolLoaded(handTool, _, loadingData)
    if handTool ~= nil then
        if loadingData.areHands then
            self.hands = handTool
            table.removeElement(self.carriedHandTools, handTool)
            table.insert(self.carriedHandTools, 1, handTool)
            handTool:setHolder(self, true)
            self:setCurrentHandTool(handTool, true)
        end
        handTool.isPlayerStartHandTool = true
    end
    self.pendingStartHandTools[loadingData] = nil
end
function Player:update(dt)
    if self.pendingHandsId ~= nil then
        local hands = NetworkUtil.getObject(self.pendingHandsId)
        if hands ~= nil then
            self.hands = hands
            self.pendingHandsId = nil
        end
    end
    if self.pendingHandToolUniqueIds ~= nil then
        for _, handToolUniqueId in ipairs(self.pendingHandToolUniqueIds) do
            local handTool = g_currentMission.handToolSystem:getHandToolByUniqueId(handToolUniqueId)
            if handTool ~= nil and handTool:getHolder() == nil then
                handTool:setHolder(self, false)
            end
        end
        self.pendingHandToolUniqueIds = nil
    end
    if self.isControlled then
        self:raiseActive()
        if self.isOwner and self.hudUpdater ~= nil then
            local hands, handToolSystem, z = self:getPosition()
            self.hudUpdater:update(dt, hands, handToolSystem, z, self:getYaw())
        end
    end
    self.stateMachine:update(dt)
end
function Player:updateTick(dt)
    if self.stateMachine.currentState.updateTick ~= nil then
        self.stateMachine.currentState:updateTick(dt)
    end
end
function Player:draw()
    if g_noHudModeEnabled then
        return
    elseif not self:getIsInVehicle() then
        local currentHandTool = self:getHeldHandTool(true)
        if currentHandTool ~= nil then
            currentHandTool:draw()
        end
    end
end
function Player:drawUIInfo()
    if self.isClient and (self.isControlled and (self ~= g_localPlayer and (not g_gui:getIsGuiVisible() and (not g_noHudModeEnabled and (g_gameSettings:getValue(GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES) and self.graphicsComponent.isGraphicsRootNodeVisible))))) then
        local x, y, z = getTranslation(self.graphicsComponent.graphicsRootNode)
        local x1, y1, z1 = getWorldTranslation(g_cameraManager:getActiveCamera())
        if MathUtil.vector3LengthSq(x - x1, y - y1, z - z1) <= 10000 then
            Utils.renderTextAtWorldPosition(x, y + self.graphicsComponent.nameTagOffsetY, z, self:getNickname(), getCorrectTextSize(0.02), 0)
        end
    end
end
function Player:getNickname()
    local user = g_currentMission.userManager:getUserByUserId(self.userId)
    return user == nil and "Unknown" or user:getNickname()
end
function Player:createData()
    local playerData = {
        ["uniqueId"] = self.uniqueUserId,
        ["lastConnectedDateTime"] = getDate("%Y/%m/%d %H:%M"),
        ["style"] = self.graphicsComponent:getStyle(),
        ["handToolUniqueIds"] = {}
    }
    if self:getHasSpawnPosition() then
        playerData.spawnPositionX, playerData.spawnPositionY, playerData.spawnPositionZ = self:getSpawnPosition()
    end
    if self:getHasSpawnYaw() then
        playerData.spawnYaw = self:getSpawnYaw()
    end
    for _, handTool in ipairs(self.carriedHandTools) do
        if handTool:getNeedsSaving() then
            table.insert(playerData.handToolUniqueIds, handTool:getUniqueId())
        end
    end
    if not (self:getHasSpawnVehicle() and g_currentMission.accessHandler:canPlayerAccess(self:getSpawnVehicle(), self)) then
        return playerData
    end
    playerData.spawnVehicleUniqueId = self:getSpawnVehicle().uniqueId
    return playerData
end
function Player:saveToXMLFile(xmlFile, baseKey)
    local playerData = self:createData()
    Player.saveDataToXMLFile(xmlFile, playerData, baseKey)
end
function Player:applyCustomWorkStyle(presetName)
    self.graphicsComponent:applyCustomWorkStyle(presetName, self.isOwner)
end
function Player:setStyleAsync(style, isDefaultStyle, callback, noEventSend)
    self.isDefaultStyle = isDefaultStyle
    self.graphicsComponent:setStyleAsync(style, function(loadingState, loadedNewPlayerModel, args)
        -- upvalues: (copy) self, (copy) callback
        self:onStyleChanged(loadingState, loadedNewPlayerModel, args)
        if callback ~= nil then
            callback(loadingState, loadedNewPlayerModel)
        end
    end, nil, nil, false, nil, self.isOwner)
    PlayerSetStyleEvent.sendEvent(self, style, NetworkUtil.getObjectId(self), noEventSend)
end
function Player:onStyleChanged(_, _, _)
    local style = self.graphicsComponent:getStyle()
    if self.isOwner then
        g_gameSettings:setValue(GameSettings.SETTING.LAST_PLAYER_STYLE_MALE, style:getIsMale())
    end
    self.capsuleController:rebuild()
    g_messageCenter:publish(MessageType.PLAYER_STYLE_CHANGED, style, self.userId)
    for i, handTool in ipairs(self.carriedHandTools) do
        handTool:setCarryingPlayerStyleChanged()
    end
    local isFirstPerson = false
    if self.camera ~= nil then
        isFirstPerson = self.camera.isFirstPerson
    end
    local isVisible = self.isControlled
    if isVisible then
        isVisible = not isFirstPerson
    end
    self.graphicsComponent:setModelVisibility(isVisible, true)
end
function Player:getUniqueUserId()
    return self.uniqueUserId
end
function Player:getUniqueId()
    return self.uniqueUserId
end
function Player:setUniqueUserId(uniqueUserId)
    if string.isNilOrWhitespace(self.uniqueUserId) or uniqueUserId == self.uniqueUserId then
        self.uniqueUserId = uniqueUserId
    else
        Logging.error("Cannot change a player\'s unique id after it has been set!")
    end
end
function Player:getFarmId()
    return self.farmId
end
function Player:setFarmId(farmId)
    if self.isServer then
        self.farmId = farmId
        PlayerSetFarmEvent.sendEvent(self, farmId)
    else
        Logging.devError("setFarm only allowed on Server")
    end
end
function Player:toggleFlashlight()
    self:setFlashlightIsActive(not self.isFlashlightActive)
end
function Player:setFlashlightIsActive(isActive, noEventSend)
    local currentHandTool = self.currentHandTool
    if currentHandTool == nil then
        currentHandTool = nil
    elseif not currentHandTool.isFlashlight then
        currentHandTool = flashlight
    end
    local i = #self.carriedHandTools
    local handTool = 1
    for i = i, handTool, -1 do
        local handTool = self.carriedHandTools[i]
        if handTool.isFlashlight then
            if currentHandTool == nil then
                currentHandTool = handTool
            end
            if handTool ~= currentHandTool then
                handTool:setFlashlightIsActive(false, noEventSend)
            end
        end
    end
    self.isFlashlightActive = isActive
    if isActive and self:getHeldHandTool(false) == nil then
        self:setCurrentHandTool(currentHandTool, noEventSend)
    end
    if currentHandTool ~= nil then
        currentHandTool:setFlashlightIsActive(isActive, noEventSend)
    end
end
function Player:onPickupHandTool(handTool)
    if handTool == nil then
        return false
    end
    table.addElement(self.carriedHandTools, handTool)
    handTool:setCarryingPlayer(self)
    return true
end
function Player:onDropHandTool(handTool)
    Logging.devInfo("Player.onDropHandTool: try dropping hand tool %q (%s) from player", handTool.configFileName, handTool.uniqueId)
    if handTool == nil then
        return
    else
        if self.currentHandTool == handTool then
            self:setCurrentHandTool(nil, true)
        end
        self:setFlashlightIsActive(self.isFlashlightActive, true)
        if table.removeElement(self.carriedHandTools, handTool) then
            handTool:setCarryingPlayer(nil)
        else
            Logging.error("Player.onDropHandTool: Could not remove hand tool %q (%s) from player, as it was not carried by the player!", handTool.configFileName, handTool.uniqueId)
            printCallstack()
        end
    end
end
function Player:getCanPickupHandTool(handTool)
    if handTool == nil then
        return false
    elseif g_currentMission.accessHandler:canPlayerAccess(handTool, self, true) then
        return not self:getReachedHandToolLimit(handTool)
    else
        return false
    end
end
function Player:getReachedHandToolLimit(handTool)
    return self:getCarriedHandToolMass() + handTool.mass > self.maximumHandToolCarryMass
end
function Player:getCanPickupHandToolFromMenu(handTool)
    return false
end
function Player:getHolderName()
    return string.format(g_i18n:getText("ui_handToolHolderPlayer"), self:getNickname())
end
function Player:cycleHandTool(direction)
    local numHandTools = #self.carriedHandTools
    local newIndex = self.currentHandToolIndex + math.sign(direction)
    if numHandTools < newIndex then
        numHandTools = self.hands == nil and 0 or 1
    elseif newIndex >= lowerLimit then
        numHandTools = newIndex
    end
    self:switchToHandToolIndex(numHandTools)
end
function Player:toggleHandTool()
    local index = self.lastHandToolIndex
    if self.currentHandToolIndex > 1 then
        index = 1
    elseif self.lastHandToolIndex == 1 then
        index = self.lastHandToolIndex
    end
    local index = index == 0 and self.hands ~= nil and 1 or index
    local numHandTools = #self.carriedHandTools
    if numHandTools < index then
        index = numHandTools
    end
    self:switchToHandToolIndex(index)
end
function Player:switchToHandToolIndex(index)
    if self.currentHandToolIndex == index then
        return
    elseif index < 0 or #self.carriedHandTools < index then
        return
    else
        local newHandTool = self.carriedHandTools[index]
        if index > 0 and newHandTool == nil then
            Logging.error("Cannot switch to hand tool with index of %d! Hand tool count: %d", index, #self.carriedHandTools)
            return
        elseif self.currentHandTool == newHandTool then
            self.lastHandToolIndex = self.currentHandToolIndex
            self.currentHandToolIndex = table.find(self.carriedHandTools, self.currentHandTool) or 0
        elseif not self:setCurrentHandTool(newHandTool) then
            Logging.error("Could not switch to hand tool with given index %d despite it existing!", index)
        end
    end
end
function Player:setCurrentHandTool(handTool, noEventSend)
    if self.currentHandTool == handTool then
        return false
    end
    if handTool ~= nil and not self:getIsCarryingHandTool(handTool) then
        return false
    end
    local lastHandTool = handTool or self.hands
    local lastHandTool = self.currentHandTool
    self.currentHandTool = lastHandTool
    self.lastHandToolIndex = self.currentHandToolIndex
    self.currentHandToolIndex = table.find(self.carriedHandTools, self.currentHandTool) or 0
    if lastHandTool ~= nil and lastHandTool ~= lastHandTool then
        lastHandTool:stopHolding()
    end
    local handToolId = nil
    if lastHandTool ~= nil then
        if lastHandTool ~= lastHandTool then
            lastHandTool:startHolding()
        end
        handToolId = NetworkUtil.getObjectId(lastHandTool)
    end
    if self.isFlashlightActive and lastHandTool == self.hands then
        self:setFlashlightIsActive(false, true)
    end
    PlayerHoldHandToolEvent.sendEvent(self, handToolId, noEventSend)
    return true
end
function Player:getForceHandToolFirstPerson()
    return self.isOwner and self.forceHandToolFirstPerson
end
function Player:getIsHoldingHandTool()
    return self:getHeldHandTool() ~= nil
end
function Player:getHeldHandTool(includeHands)
    local currentHandTool = self.currentHandTool
    if currentHandTool == nil then
        return nil
    elseif currentHandTool == self.hands and not includeHands then
        return nil
    else
        return currentHandTool
    end
end
function Player:getIsCarryingHandTool(handTool)
    return handTool ~= nil and table.find(self.carriedHandTools, handTool) ~= nil
end
function Player:getCarriedHandToolMass()
    local summedWeight = 0
    for _, handTool in ipairs(self.carriedHandTools) do

    end
    return summedWeight
end
function Player:getMapPositionAndLookYaw()
    local currentCameraNode = self:getCurrentCameraNode()
    local cameraDirectionX, _, cameraDirectionZ = localDirectionToWorld(currentCameraNode, 0, 0, -1)
    local cameraYaw = MathUtil.getYRotationFromDirection(cameraDirectionX, cameraDirectionZ)
    local x, _, z = self:getPosition()
    return x, z, cameraYaw
end
function Player:getRunMultiplier()
    local runMultiplier = 1
    local handTool = self:getHeldHandTool(true)
    if handTool ~= nil then
    end
    return runMultiplier
end
function Player:getWalkMultiplier()
    local walkMultiplier = 1
    local handTool = self:getHeldHandTool(true)
    if handTool ~= nil then
    end
    return walkMultiplier
end
function Player:getJumpMultiplier()
    local jumpMultiplier = 1
    local handTool = self:getHeldHandTool(true)
    if handTool ~= nil then
    end
    return jumpMultiplier
end
function Player:requestToEnterVehicle(vehicle, force)
    if self.isDeleted then
        return
    else
        local playerStyle = self.graphicsComponent:getStyle()
        if g_currentMission.accessHandler:canPlayerAccess(vehicle, self) and playerStyle ~= nil then
            g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent.new(vehicle, playerStyle, self.farmId, force))
        end
    end
end
function Player:requestToEnterVehicleAsPassenger(vehicle, seatIndex)
    if self.isDeleted then
        return
    elseif g_currentMission.accessHandler:canPlayerAccess(vehicle) then
        g_client:getServerConnection():sendEvent(EnterablePassengerEnterRequestEvent.new(vehicle, seatIndex))
    end
end
function Player:leaveVehicle(vehicle, noEventSend)
    if self.isDeleted then
        return
    else
        local currentVehicle = vehicle or self:getCurrentVehicle()
        if currentVehicle == nil then
            Logging.devWarning("Player \'%s\' tries to leave vehicle, but is not in a vehicle anymore", self:getNickname())
            return
        else
            local seatIndex = nil
            if currentVehicle.getPassengerSeatIndexByPlayer ~= nil then
                seatIndex = currentVehicle:getPassengerSeatIndexByPlayer(self.userId)
            end
            if seatIndex == nil then
                VehicleLeaveEvent.sendEvent(currentVehicle, self.userId, noEventSend)
                currentVehicle:onPlayerLeaveVehicle()
                self:onLeaveVehicle(currentVehicle)
            else
                EnterablePassengerLeaveEvent.sendEvent(currentVehicle, self.userId, noEventSend)
                currentVehicle:leavePassengerSeat(self.isOwner, seatIndex)
                self:onLeaveVehicleAsPassenger(currentVehicle)
            end
        end
    end
end
function Player:cycleCurrentVehicle(direction)
    local mission = g_currentMission
    if mission.isPlayerFrozen or not (mission.isRunning and mission.isToggleVehicleAllowed) then
        return
    else
        local vehicle = mission.vehicleSystem:getNextEnterableVehicle(self:getCurrentVehicle(), direction)
        if vehicle ~= nil then
            self:requestToEnterVehicle(vehicle)
        end
    end
end
function Player:resolveSpawnVehicle(spawnVehicleUniqueId)
    if string.isNilOrWhitespace(spawnVehicleUniqueId) then
        return nil
    else
        local mission = g_currentMission
        local vehicle = mission.vehicleSystem:getVehicleByUniqueId(spawnVehicleUniqueId)
        if vehicle == nil then
            return nil
        elseif mission.accessHandler:canPlayerAccess(vehicle, self) then
            return vehicle
        else
            return nil
        end
    end
end
function Player:createConsoleCommands()
    if self.isOwner then
        addConsoleCommand("gsPlayerDebugFlagToggle", "Toggles the debug display flag with the given name for the player", "consoleCommandToggleDebugFlag", self)
        addConsoleCommand("gsPlayerDebugFlagVerbosityToggle", "Toggles the debug display verbosity flag with the given name for the player", "consoleCommandToggleVerboseDebugFlag", self)
        self:handleDebugBindings()
        self.toggleFlightModeCommand = ConsoleValueToggle.new("gsPlayerFlightToggle", "Enables flight to be toggled (key J). Use keys Q and E to change altitude", nil, function(_, enabledString)
            return "Player flight " .. enabledString
        end)
        self.toggleSuperSpeedCommand = ConsoleValueToggle.new("gsPlayerSuperSpeedToggle", "Massively increases the movement speed of the player", g_isDevelopmentVersion or Player.START_WITH_SUPERSPEED, function(_, enabledString)
            return "Player super speed " .. enabledString
        end)
        self.toggleNoClipCommand = ConsoleValueToggle.new("gsPlayerNoClipToggle", "Toggles player collision. First argument is a boolean to determine if collision with the terrain should also be disabled. Second argument to determine if player should interact with triggers", nil, function(enabled, _, disableTerrainCollision)
            return enabled and (Utils.stringToBoolean(disableTerrainCollision) and "Player noclip enabled, including terrain" or "Player noclip enabled, excluding terrain. To include terrain, use \"true\" as the first parameter in the command") or "Player noclip disabled"
        end, "[disableTerrainCollision=false]; [ignorePlayerInTriggers=false]")
    end
end
function Player:onStartMission()
    if g_dedicatedServer == nil or self.userId ~= g_currentMission:getServerUserId() then
        self.stateMachine.states.onFoot:onStateEntered()
        if self:getHasSpawnVehicle() then
            self:requestToEnterVehicle(self.spawnVehicle)
        elseif self.isServer and not self.isOwner then
            self.graphicsComponent:setGraphicsRootNodeVisibility(false)
            g_messageCenter:subscribe(MessageType.ON_CLIENT_START_MISSION, self.onClientStartMission, self)
        end
    else
        self:hide()
        return
    end
end
function Player:moveCCTExternal(moveX, moveY, moveZ)
    if self.capsuleController ~= nil then
        self.capsuleController:moveExternal(moveX, moveY, moveZ)
    end
end
function Player:getTouchingNode()
    if self.capsuleController == nil then
        return nil
    else
        return self.capsuleController:getTouchingNode()
    end
end
function Player:onClientStartMission(user)
    if user ~= nil and self.userId == user:getId() then
        self.graphicsComponent:setGraphicsRootNodeVisibility(true)
    end
end
function Player:playerFarmChanged(player)
    if player == self then
        local i = #self.carriedHandTools
        for i = i, 1, -1 do
            local handTool = self.carriedHandTools[i]
            if handTool:getCanBeDropped() then
                handTool:setHolder(nil)
            else
                handTool:setOwnerFarmId(self.farmId, true)
            end
        end
    end
end
function Player:onContractingStateChanged(farmId, contractingFarmId, isContracting)
    if self.farmId == farmId then
        if not isContracting then
            local i = #self.carriedHandTools
            for i = i, 1, -1 do
                local handTool = self.carriedHandTools[i]
                if handTool:getOwnerFarmId() == contractingFarmId and handTool:getCanBeDropped() then
                    handTool:setHolder(nil)
                end
            end
        end
    end
end
function Player:registerStateEvents()
    self:registerStateEventList("onEnterVehicle")
    self:registerStateEventList("onLeaveVehicle")
    self:registerStateEventList("onEnterVehicleAsPassenger")
    self:registerStateEventList("onLeaveVehicleAsPassenger")
    self:registerStateEventList("onEnterRollercoaster")
    self:registerStateEventList("onLeaveRollercoaster")
    self:registerStateEventList("onPerspectiveSwitched")
end
function Player:registerStateEventList(eventName)
    if self.stateEvents[eventName] == nil then
        local listenerList = nil
        local existingMemberType = type(self[eventName])
        if existingMemberType == "function" then
            listenerList = ListenerList.new(true)
            listenerList:registerListener(self[eventName], self)
        elseif existingMemberType == "nil" then
            listenerList = ListenerList.new(true)
        elseif existingMemberType ~= "table" or not self[eventName]:isa(ListenerList) then
            Logging.warning("Cannot overwrite player member %s with an event function, as it is a %s", eventName, existingMemberType)
            return
        end
        self[eventName] = listenerList
        self.stateEvents[eventName] = eventName
    else
        Logging.warning("State event with name %s has already been registered!", eventName)
    end
end
function Player:addStateEvent(eventFunction, eventTarget, eventName)
    if self.stateEvents[eventName] == nil then
        Logging.warning("State event with name %q has not been registered!", eventName)
    else
        self[eventName]:registerListener(eventFunction, eventTarget)
    end
end
function Player:registerStateFunctions()
    self:registerStateFunction("getCurrentRootNode")
    self:registerStateFunction("getSpeed")
    self:registerStateFunction("getPosition")
    self:registerStateFunction("getYaw")
    self:registerStateFunction("getCurrentFacingDirection")
    self:registerStateFunction("getCurrentCameraNode")
    self:registerStateFunction("updateWhileInConversation")
    self:registerStateFunction("getIsInVehicle")
    self:registerStateFunction("getCurrentVehicle")
end
function Player:registerStateFunction(functionName)
    if self[functionName] == nil then
        if self.stateFunctions[functionName] == nil then
            self.stateFunctions[functionName] = functionName
            self[functionName] = function(player, ...)
                -- upvalues: (copy) self, (copy) functionName
                return self:fireStateFunction(functionName, ...)
            end
        else
            Logging.warning("State function with name %q has already been registered!", functionName)
        end
    else
        Logging.warning("Cannot register state function with name %q as the Player class already defines a member with the same name!", functionName)
        return
    end
end
function Player:fireStateFunction(functionName, ...)
    if self.stateFunctions[functionName] == nil then
        Logging.warning("State function with name %q has not been registered!", functionName)
    else
        local currentState = self.stateMachine.currentState
        local stateFunction = currentState[functionName]
        if type(stateFunction) == "function" then
            return stateFunction(currentState, ...)
        end
    end
end
function Player:getHandsKinematicNode()
    if self.hands == nil then
        return false
    end
    local kinematicNode, kinematicRotationNode = self.hands:getKinematicNode()
    return kinematicNode, kinematicRotationNode
end
function Player:getAreHandsHoldingObject()
    if self.hands == nil then
        return false
    else
        return self.hands:getIsHoldingItem()
    end
end
function Player:getLookRay()
    if not self.isOwner then
        return nil, nil, nil, nil, nil, nil
    end
    local directionX, directionY, directionZ = localDirectionToWorld(self.camera.cameraRootNode, 0, 0, -1)
    if self.camera.isFirstPerson then
        local x, y, z = self.camera:getCameraPosition()
        return x, y, z, directionX, directionY, directionZ
    end
    if self.graphicsComponent == nil or (self.graphicsComponent.model == nil or self.graphicsComponent.model.thirdPersonHeadNode == nil) then
        return nil, nil, nil, nil, nil, nil
    end
    local x, y, z = getWorldTranslation(self.graphicsComponent.model.thirdPersonHeadNode)
    return x, y, z, directionX, directionY, directionZ
end
function Player:updateControlledState(isControlled, skipModel, skipMover)
    if isControlled == self.isControlled then
        return
    elseif isControlled then
        self:show(skipModel, skipMover)
    else
        self:hide(skipModel, skipMover)
    end
end
function Player:getIsControlled(ignoreLocal)
    if ignoreLocal or self.isLocallyControlled == nil then
        return self.isControlled
    else
        return self.isLocallyControlled
    end
end
function Player:findSpawnPositionAndYaw()
    local spawnYaw = self:getHasSpawnYaw() and self:getSpawnYaw() or 0
    if self:getHasSpawnPosition() then
        return self.spawnPositionX, self.spawnPositionY, self.spawnPositionZ, spawnYaw
    end
    if AutoLoadParams.enable == true and (AutoLoadParams.x ~= nil and AutoLoadParams.z ~= nil) then
        local y = getTerrainHeightAtWorldPos(g_terrainNode, AutoLoadParams.x, 0, AutoLoadParams.z) + 0.2
        return AutoLoadParams.x, y, AutoLoadParams.z, spawnYaw
    end
    local y = g_farmManager:getSpawnPoint(self.farmId)
    local mission = g_currentMission
    if y == nil or mission ~= nil and (mission:getIsServer() and not mission.missionInfo.isValid) then
        y = g_mission00StartPoint
    end
    if y == nil then
        Logging.error("Player could not find any valid spawn position!")
        return 0, 0, 0, spawnYaw
    end
    local startPositionX, startPositionY, startPositionZ = getWorldTranslation(y)
    local dx, _, dz = localDirectionToWorld(y, 0, 0, 1)
    return startPositionX, startPositionY, startPositionZ, MathUtil.getYRotationFromDirection(dx, dz)
end
function Player.findEmptyAreaAroundPosition(_, x, y, z)
    return x, y, z
end
function Player:getHasSpawnVehicle()
    return self.spawnVehicle ~= nil
end
function Player:getSpawnVehicle()
    return self.spawnVehicle
end
function Player:setSpawnVehicle(vehicle)
    if vehicle == nil or g_currentMission.accessHandler:canPlayerAccess(vehicle, self) then
        self.spawnVehicle = vehicle
    end
end
function Player:getHasSpawnPosition()
    return self.spawnPositionX ~= nil and self.spawnPositionY ~= nil and self.spawnPositionZ ~= nil
end
function Player:getSpawnPosition()
    return self.spawnPositionX, self.spawnPositionY, self.spawnPositionZ
end
function Player:setSpawnPosition(x, y, z)
    self.spawnPositionX = x
    self.spawnPositionY = y
    self.spawnPositionZ = z
end
function Player:getHasSpawnYaw()
    return self.spawnYaw ~= nil
end
function Player:getSpawnYaw()
    return self.spawnYaw
end
function Player:setSpawnYaw(spawnYaw)
    self.spawnYaw = spawnYaw
end
function Player:teleportTo(x, y, z, setNodeTranslation, noEventSend)
    self.mover:teleportTo(x, y, z, setNodeTranslation, noEventSend)
end
function Player:teleportToSpawnPoint(noEventSend)
    self.mover:teleportToSpawnPoint(noEventSend)
end
function Player:teleportToNPC(npc, _)
    self.mover:teleportToNPC(npc)
end
function Player:teleportToExitPoint(vehicle, noEventSend)
    self.mover:teleportToExitPoint(vehicle, noEventSend)
end
function Player:getMovementYaw()
    return self.mover:getMovementYaw()
end
function Player:setMovementYaw(yaw)
    self.mover:setMovementYaw(yaw)
end
function Player:getGraphicalSpeed()
    if self.isOwner then
        return self.mover:getSpeed()
    else
        return self.positionalInterpolator:getInterpolatedSpeed()
    end
end
function Player:getGraphicalVelocity()
    if self.isOwner then
        return self.mover:getVelocity()
    else
        return self.positionalInterpolator:getInterpolatedVelocity()
    end
end
function Player:getGraphicalPosition()
    if self.isOwner then
        return self.mover:getPosition()
    end
    if self.positionalInterpolator.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE then
        return self.positionalInterpolator:getInterpolatedPosition()
    end
    if self.positionalInterpolator.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE then
        return self.mover:getPosition()
    end
    Logging.error("Invalid state for player to get graphical position! Perhaps a missing case for INTERPOLATION_TARGET_ENUM?")
    return 0, 0, 0
end
function Player:getGraphicalYaw()
    if self.isOwner then
        return self:getMovementYaw()
    end
    if self.positionalInterpolator.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE then
        return self.positionalInterpolator:getInterpolatedYaw()
    end
    if self.positionalInterpolator.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE then
        return self:getMovementYaw()
    end
    Logging.error("Invalid state for player to get graphical yaw! Perhaps a missing case for INTERPOLATION_TARGET_ENUM?")
    return 0
end
function Player:setIsHoldingChainsaw(isHoldingChainsaw)
    self.isHoldingChainsaw = isHoldingChainsaw
end
function Player:setChainsawState(isCutting, isVerticalCut)
    self.isCutting = isCutting
    self.isVerticalCut = isVerticalCut
end
function Player:showLocally()
    self:show()
    self.isLocallyControlled = true
    self.isControlled = self.isControlled
end
function Player:hideLocally()
    self:hide()
    self.isLocallyControlled = false
    self.isControlled = self.isControlled
end
function Player:clearLocalHideState()
    self.isLocallyControlled = nil
    if self.isControlled then
        self:show()
    else
        self:hide()
    end
end
function Player:raiseDefaultDirtyFlag()
    if self.isServer or self.isOwner then
        self:raiseDirtyFlags(self.dirtyFlag)
    end
end
function Player:show(skipShowingModel, skipEnablingMover, ignoreLocalCheck)
    if self.isDeleted then
        return
    elseif ignoreLocalCheck or self.isLocallyControlled == nil then
        local mission = g_currentMission
        self:raiseActive()
        if self.isServer then
            self.networkComponent:setShowHideParameters(skipShowingModel, skipEnablingMover)
            self:setOwnerConnection(self.connection)
            self:raiseDefaultDirtyFlag()
        end
        self.isControlled = true
        g_messageCenter:publish(MessageType.OWN_PLAYER_ENTERED)
        if self.isOwner then
            if mission ~= nil then
                mission.environmentAreaSystem:setReferenceNode(self.camera.cameraRootNode)
            end
            self.camera:makeCurrent()
            self.inputComponent:listenForBindingChanges()
            self.inputComponent:addPauseListeners()
            if not skipShowingModel then
                local isFirstPerson = false
                if self.camera ~= nil then
                    isFirstPerson = self.camera.isFirstPerson
                end
                self.graphicsComponent:setModelVisibility(not isFirstPerson, true)
            end
        elseif not skipShowingModel then
            self.graphicsComponent:setModelVisibility(true)
        end
        if mission ~= nil then
            if mission.shallowWaterSimulation ~= nil and self.swsObstacle == nil then
                local isVisible = self.capsuleController:getRadius() * 1.5
                self.swsObstacle = mission.shallowWaterSimulation:addObstacle(self.rootNode, isVisible, self.capsuleController:getTotalHeight(), isVisible, function()
                    -- upvalues: (copy) self
                    local vx, _, vz = self.mover:getVelocity()
                    if vx == 0 and (vz == 0 and self.stateMachine.currentState == self.stateMachine.states.onFoot) then
                        local state = self.stateMachine.currentState.currentState
                        if state == self.stateMachine.currentState.states.falling or state == self.stateMachine.currentState.states.jumping then
                            return math.random(5), math.random(5), 0
                        end
                    end
                    return vx, vz, self.mover:getMovementYaw()
                end, nil, {
                    [2] = self.capsuleController:getHeight() / 2
                })
            end
            if mission.aiSystem ~= nil then
                mission.aiSystem:addObstacle(self.rootNode, nil, nil, nil, 0.8, 2, 0.8, nil, false)
            end
        end
        if self.playerHotspot ~= nil then
            self.playerHotspot:setPlayer(self)
            self.playerHotspot:setOwnerFarmId(self.farmId)
            if mission ~= nil then
                mission:addMapHotspot(self.playerHotspot)
            end
        end
        if self.isServer and (mission ~= nil and (mission.trafficSystem ~= nil and mission.trafficSystem.trafficSystemId ~= 0)) then
            addTrafficSystemPlayer(mission.trafficSystem.trafficSystemId, self.graphicsComponent.graphicsRootNode)
        end
        self:setCurrentHandTool(nil, true)
        for i, handTool in ipairs(self.carriedHandTools) do
            handTool:setCarryingPlayerShown()
        end
        if self.isOwner and not skipEnablingMover then
            self.mover:enablePhysics()
        end
    end
end
function Player:hide(skipHidingModel, skipDisablingMover, ignoreLocalCheck)
    if self.isDeleted then
        return
    elseif ignoreLocalCheck or self.isLocallyControlled == nil then
        if self.isServer then
            self.networkComponent:setShowHideParameters(skipHidingModel, skipDisablingMover)
        end
        if self.isControlled and self.isOwner then
            g_messageCenter:publish(MessageType.OWN_PLAYER_LEFT)
            self.inputComponent:stopListeningForBindingChanges()
        end
        if self:getIsHoldingHandTool() then
            self:setCurrentHandTool(nil, true)
        end
        for i, handTool in ipairs(self.carriedHandTools) do
            handTool:setCarryingPlayerHidden()
        end
        self:setFlashlightIsActive(false, true)
        self.isControlled = false
        local mission = g_currentMission
        if self.swsObstacle ~= nil then
            mission.shallowWaterSimulation:removeObstacle(self.swsObstacle)
            self.swsObstacle = nil
        end
        if mission.aiSystem ~= nil then
            mission.aiSystem:removeObstacle(self.rootNode)
        end
        if not skipHidingModel then
            self.graphicsComponent:hide()
        end
        if not skipDisablingMover then
            self.mover:disablePhysics()
            self:teleportTo(0, -200, 0, true, true)
        end
    end
end
function Player:onPerspectiveSwitched(isFirstPerson)
    if self.graphicsComponent ~= nil then
        local isVisible = self.isControlled
        if isVisible then
            isVisible = not isFirstPerson
        end
        self.graphicsComponent:setModelVisibility(isVisible, true)
    end
    if self:getIsHoldingHandTool() then
        self.currentHandTool:setCarryingPlayerPerspectiveChanged(isFirstPerson)
    end
end
function Player:drawDebug(posX, posY, textSize)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(posX, posY, textSize, "State : ")
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(posX, posY, textSize, self.stateMachine:getCurrentStateName())
    self.graphicsState:drawDebug(posX, posY - textSize - 5 * g_pixelSizeY, textSize)
    local node = self.rootNode
    if self.graphicsComponent ~= nil then
        node = self.graphicsComponent.graphicsRootNode
    end
    local x, y, z = localToWorld(node, 2, 2, 0)
    local sx, sy, sz = project(x, y, z)
    DebugUtil.drawDebugNode(node, "Root", false, 0)
    if sx > -1 and (sx < 2 and (sy > -1 and (sy < 2 and sz <= 1))) then
        local _ = self.graphicsComponent == nil
    end
end
function Player:consoleCommandToggleDebugFlag(flagName)
    local flag = flagName ~= nil and Player.DEBUG_DISPLAY_FLAG[string.upper(flagName)] or nil
    if string.isNilOrWhitespace(flagName) or flag == nil then
        local possibleValues = "Flag name must be one of the following: "
        for flagName, flagValue in pairs(Player.DEBUG_DISPLAY_FLAG) do

        end
        return possibleValues
    else
        if flag == Player.DEBUG_DISPLAY_FLAG.NONE then
            Player.currentDebugFlag = Player.DEBUG_DISPLAY_FLAG.NONE
        else
            Player.currentDebugFlag = bit32.bxor(Player.currentDebugFlag, flag)
        end
        self:handleDebugBindings()
        if bit32.band(flag, Player.currentDebugFlag) == 0 then
            return string.format("Debug flag %q is now disabled", flagName)
        else
            return string.format("Debug flag %q is now enabled", flagName)
        end
    end
end
function Player:consoleCommandToggleVerboseDebugFlag(flagName)
    local flag = flagName ~= nil and Player.DEBUG_DISPLAY_FLAG[flagName] or nil
    if string.isNilOrWhitespace(flagName) or flag == nil then
        local possibleValues = "Flag name must be one of the following: "
        for flagName, flagValue in pairs(Player.DEBUG_DISPLAY_FLAG) do

        end
        return possibleValues
    else
        Player.currentDebugVerbosityFlag = bit32.bxor(Player.currentDebugVerbosityFlag, flag)
        self:handleDebugBindings()
        if bit32.band(flag, Player.currentDebugVerbosityFlag) == 0 then
            return string.format("Debug verbosity flag %q is now disabled", flagName)
        else
            return string.format("Debug verbosity flag %q is now enabled", flagName)
        end
    end
end
function Player:consoleCommandToggleStrafeWalkMode()
    self.isStrafeWalkMode = not self.isStrafeWalkMode
    return string.format("StrafeWalkMode: %s", self.isStrafeWalkMode and "Active" or "Inactive")
end
function Player:consoleCommandToggleForceHandToolFirstPerson()
    self.forceHandToolFirstPerson = not self.forceHandToolFirstPerson
    return string.format("ForceHandToolFirstPerson: %s", self.forceHandToolFirstPerson and "Active" or "Inactive")
end
function Player:consoleCommandTipToTrigger(fillTypeName, amountStr)
    if self.isControlled then
        if fillTypeName == nil then
            Logging.error("No fillType given")
            return "gsTipToTrigger fillTypeName amount"
        else
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
            if fillTypeIndex == nil then
                Logging.error("Unknown fillType %q", fillTypeName)
                return usage
            elseif amountStr == nil then
                Logging.error("No amount given")
                return usage
            else
                local amount = tonumber(amountStr)
                if amount == nil then
                    Logging.error("Given amount %q is not a number", amountStr)
                    return usage
                else
                    local tipTargetObject = nil
                    local notSupported = nil
                    local missingSpace = nil
                    local amountToTip = amount
                    local x, y, z = getWorldTranslation(g_localPlayer.rootNode)
                    raycastAll(x, y + 5, z, 0, -1, 0, 10, "callbackFunc", {
                        ["callbackFunc"] = function(_, hitActorId, _, _, _, _, _, _, _, _, hitShapeId)
                            -- upvalues: (ref) notSupported, (ref) missingSpace, (copy) self, (ref) tipTargetObject, (copy) fillTypeIndex, (ref) amountToTip
                            local object = g_currentMission.nodeToObject[hitActorId]
                            notSupported = false
                            missingSpace = false
                            if object ~= nil and (object ~= self and object.getFillUnitIndexFromNode ~= nil) then
                                tipTargetObject = object
                                local fillUnitIndex = object:getFillUnitIndexFromNode(hitShapeId)
                                if fillUnitIndex ~= nil then
                                    local fillType = fillTypeIndex
                                    if not object:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
                                        Logging.error("Failed to tip. Target does not support this fillType")
                                        local allowFillType
                                        if object.getFillUnitSupportedFillTypes == nil then
                                            allowFillType = object.fillTypes
                                        else
                                            allowFillType = object:getFillUnitSupportedFillTypes(fillUnitIndex)
                                        end
                                        if allowFillType ~= nil then
                                            local farmId = g_fillTypeManager:getFillTypeNamesByIndices(allowFillType)
                                            if #farmId > 0 then
                                                printf("Supported fillTypes: %s", table.concat(farmId, " "))
                                            end
                                        end
                                        notSupported = true
                                        return
                                    end
                                    local allowFillType = object:getFillUnitAllowsFillType(fillUnitIndex, fillType)
                                    local farmId = self.farmId
                                    local freeSpace = object:getFillUnitFreeCapacity(fillUnitIndex, fillType, farmId) > 0
                                    if not freeSpace then
                                        missingSpace = true
                                        Logging.error("Failed to tip. Target has no more space for this fillType")
                                        return
                                    end
                                    if allowFillType then
                                        amountToTip = amountToTip - object:addFillUnitFillLevel(farmId, fillUnitIndex, amountToTip, fillType, ToolType.UNDEFINED, nil)
                                        if amountToTip <= 0 then
                                            return false
                                        end
                                    end
                                end
                            end
                            return true
                        end
                    }, CollisionFlag.FILLABLE)
                    if tipTargetObject == nil then
                        Logging.error("Failed to tip. No target found below current player position")
                        return
                    elseif not (notSupported or missingSpace) then
                        local tippedAmount = amount - amountToTip
                        if tippedAmount ~= 0 then
                            return "Tipped " .. tippedAmount .. "l of " .. fillTypeName
                        end
                        Logging.error("Failed to tip %q. Missing access or no space at target", fillTypeName)
                    end
                end
            end
        end
    else
        Logging.error("Not available within a vehicle, needs to be on foot")
        return
    end
end
function Player:handleDebugBindings()
    if self.debugFunctionId == nil and Player.currentDebugFlag ~= Player.DEBUG_DISPLAY_FLAG.NONE then
        self.debugFunctionId = g_debugManager:addElement(DebugFunction.new(nil, function()
            g_currentMission.playerSystem:debugDrawAllPlayers(0.025, 0.95, 0.014)
        end))
    end
    if self.debugFunctionId ~= nil and Player.currentDebugFlag == Player.DEBUG_DISPLAY_FLAG.NONE then
        g_debugManager:removeElementById(self.debugFunctionId)
        self.debugFunctionId = nil
    end
end
function Player.debugLogVerbose(instance, category, infoMessage, ...)
    if type(category) == "number" then
        if bit32.band(category, Player.currentDebugVerbosityFlag) ~= 0 then
            Player.debugLog(instance, category, infoMessage, ...)
            return
        end
    end
end
function Player.debugLog(instance, category, infoMessage, ...)
    if type(category) == "number" then
        if bit32.band(category, Player.currentDebugFlag) ~= 0 then
            local categoryName = nil
            for name, value in pairs(Player.DEBUG_DISPLAY_FLAG) do
                if value == category then
                    categoryName = name
                    break
                end
            end
            if categoryName == nil then
                categoryName = string.format("0x%X", category)
            end
            if instance == nil then
                Logging.info("Player %s: " .. infoMessage, categoryName, ...)
            else
                Logging.info("Player %d %s: " .. infoMessage, instance.userId or -1, categoryName, ...)
            end
        end
    end
end
function Player:debugDraw(x, y, textSize)
    if self.isOwner then
        local flagTextY = textSize * (table.size(Player.DEBUG_DISPLAY_FLAG) + 1)
        local flagTextY = DebugUtil.renderTextLine(0.9, flagTextY, textSize, "Enabled debug views:", nil, true)
        for flagName, flagValue in pairs(Player.DEBUG_DISPLAY_FLAG) do
            if flagValue ~= 0 then
                if bit32.band(flagValue, Player.currentDebugFlag) == flagValue then
                    flagTextY = DebugUtil.renderTextLine(0.9, flagTextY, textSize, flagName, nil, true)
                end
            end
        end
    end
    if self.userId ~= nil then
        DebugUtil.drawDebugNode(self.rootNode, "Root", false, 0)
        local flagTextY = DebugUtil.renderTextLine(x, y, textSize * 2, string.format("Player %d (farm: %d)", self.userId, self.farmId), nil, true, self.isOwner and Color.PRESETS.DARKGREEN or Color.PRESETS.WHITE)
        local flagTextY = DebugUtil.renderTextLine
        local flagName = string.format
        local flagTextY = flagTextY(x, flagTextY, textSize, flagName("Controlled (server, local): %s, %s", tostring(self.isControlled), (tostring(self.isLocallyControlled))), nil, true)
        if bit32.band(Player.DEBUG_DISPLAY_FLAG.STATE, Player.currentDebugFlag) ~= 0 then
            local flagTextY = DebugUtil.renderTextLine(x, flagTextY, textSize * 2, self.stateMachine.states.onFoot:getCurrentStateName(), nil, true)
            local flagTextY = DebugUtil.renderTextLine(x, flagTextY, textSize * 1.5, "State functions", nil, true)
            for functionName in pairs(self.stateFunctions) do
                flagTextY = DebugUtil.renderTextLine(x, flagTextY, textSize, functionName, nil, true)
            end
            flagTextY = DebugUtil.renderNewLine(flagTextY, textSize)
        end
        if self.stateMachine.currentState == self.stateMachine.states.onFoot then
            if bit32.band(Player.DEBUG_DISPLAY_FLAG.MOVEMENT, Player.currentDebugFlag) ~= 0 then
                local flagTextY = self.mover:debugDraw(x, flagTextY, textSize)
                local flagTextY = self.capsuleController:debugDraw(x, flagTextY, textSize)
                flagTextY = DebugUtil.renderNewLine(flagTextY, textSize)
            end
            if self.inputComponent ~= nil then
                if bit32.band(Player.DEBUG_DISPLAY_FLAG.INPUT, Player.currentDebugFlag) ~= 0 then
                    flagTextY = self.inputComponent:debugDraw(x, flagTextY, textSize)
                end
            end
            if bit32.band(Player.DEBUG_DISPLAY_FLAG.GRAPHICS, Player.currentDebugFlag) ~= 0 then
                if self.isOwner then
                    self.graphicsComponent:debugDrawAnimator(0.75, 0.5, 0.25, 0.3, 0.01)
                    if self.camera ~= nil then
                        flagTextY = self.camera:debugDraw(x, flagTextY, textSize)
                    end
                end
                local flagTextY = self.graphicsComponent
                local flagValue = true
                if self.camera ~= nil then
                    flagValue = not self.camera.isFirstPerson
                end
                local flagTextY = flagTextY:debugDraw(x, flagTextY, textSize, flagValue)
                flagTextY = DebugUtil.renderNewLine(flagTextY, textSize)
            end
            if bit32.band(Player.DEBUG_DISPLAY_FLAG.HANDTOOLS, Player.currentDebugFlag) ~= 0 then
                if self.targeter ~= nil then
                    local flagTextY = self.targeter:debugDraw(x, flagTextY, textSize)
                    flagTextY = DebugUtil.renderNewLine(flagTextY, textSize)
                end
                local flagTextY = DebugUtil.renderTextLine(x, flagTextY, textSize * 1.5, "Tools", nil, true)
                for functionName, flagName in ipairs(self.carriedHandTools) do
                    if flagName == self.currentHandTool then
                        flagTextY = DebugUtil.renderTextLine(x, flagTextY, textSize, string.format("%d: %s", functionName, flagName.typeName), nil, true)
                    else
                        flagTextY = DebugUtil.renderTextLine(x, flagTextY, textSize, string.format("%d: %s", functionName, flagName.typeName))
                    end
                end
                if self:getIsHoldingHandTool() then
                    flagTextY = self.currentHandTool:debugDraw(x, flagTextY, textSize)
                end
                flagTextY = DebugUtil.renderNewLine(flagTextY, textSize)
            end
            if self.networkComponent ~= nil then
                if bit32.band(Player.DEBUG_DISPLAY_FLAG.NETWORK, Player.currentDebugFlag) ~= 0 then
                    local flagTextY = self.networkComponent:debugDraw(x, flagTextY, textSize)
                    flagTextY = DebugUtil.renderNewLine(flagTextY, textSize)
                end
            end
            return flagTextY
        end
    end
end