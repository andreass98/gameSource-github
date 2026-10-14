source("dataS/scripts/events/VehicleRemoveEvent.lua")
source("dataS/scripts/events/OnCreateLoadedObjectEvent.lua")
BaseMission = {}
local BaseMission_mt = Class(BaseMission)
BaseMission.STATE_INTRO = 0
BaseMission.STATE_READY = 1
BaseMission.STATE_RUNNING = 2
BaseMission.STATE_FINISHED = 3
BaseMission.STATE_FAILED = 5
BaseMission.STATE_CONTINUED = 6
BaseMission.INPUT_CONTEXT_VEHICLE = "VEHICLE"
BaseMission.INPUT_CONTEXT_PAUSE = "PAUSE"
BaseMission.INPUT_CONTEXT_SYNCHRONIZING = "MP_SYNC"
function BaseMission.new(baseDirectory, customMt)
    -- upvalues: (copy) BaseMission_mt
    local self = setmetatable({}, customMt or BaseMission_mt)
    self.baseDirectory = baseDirectory
    self.server = g_server
    self.client = g_client
    self.hud = nil
    self.playerSystem = PlayerSystem.new()
    self.placeableSystem = PlaceableSystem.new(self)
    self.vehicleSystem = VehicleSystem.new(self)
    self.itemSystem = ItemSystem.new(self)
    self.handToolSystem = HandToolSystem.new()
    self.onCreateObjectSystem = OnCreateObjectSystem.new(self)
    self.beehiveSystem = BeehiveSystem.new(self)
    if Platform.hasShallowWaterSimulation then
        self.shallowWaterSimulation = ShallowWaterSimulation.new()
        self.shallowWaterSimulation:load()
    end
    self.cancelLoading = false
    self.vertexBufferMemoryUsage = 0
    self.indexBufferMemoryUsage = 0
    self.textureMemoryUsage = 0
    self.waitForDLCVerification = false
    self.waitForCorruptDlcs = false
    self.finishedFirstUpdate = false
    self.players = {}
    self.connectionsToPlayer = {}
    self.updateables = {}
    self.sortedUpdateables = {}
    self.nonUpdateables = {}
    self.drawables = {}
    self.triggerMarkers = {}
    self.triggerMarkersAreVisible = true
    self.helpTriggers = {}
    self.helpTriggersAreVisible = true
    self.dynamicallyLoadedObjects = {}
    self.isPlayerFrozen = false
    self.environment = nil
    self.state = BaseMission.STATE_INTRO
    self.isRunning = false
    self.isLoaded = false
    self.numLoadingTasks = 0
    self.isMissionStarted = false
    self.isToggleVehicleAllowed = true
    self.ownedItems = {}
    self.leasedItems = {}
    self.loadSpawnPlaces = {}
    self.storeSpawnPlaces = {}
    self.restrictedZones = {}
    self.usedLoadPlaces = {}
    self.usedStorePlaces = {}
    self.nodeToObject = {}
    self.maps = {}
    self.surfaceSounds = {}
    self.cuttingSounds = {}
    self.preSimulateTime = 4000
    self.maxNumHirables = Platform.gameplay.maxNumHirables
    self.time = 0
    self.activatableObjectsSystem = ActivatableObjectsSystem.new(self)
    self.pauseListeners = {}
    self.paused = false
    self.pressStartPaused = false
    self.manualPaused = false
    self.suspendPaused = false
    self.lastNonPauseGameState = GameState.PLAY
    self.isLoadingMap = false
    self.numLoadingMaps = 0
    self.loadingMapBaseDirectory = ""
    self.objectsToClassName = {}
    self.lastInteractionTime = -1
    self.isExitingGame = false
    return self
end
function BaseMission:initialize()
    self:subscribeSettingsChangeMessages()
    self:subscribeGuiOpenCloseMessages()
    g_messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, self.onGameStateChange, self)
    self.hud = self:createHUD()
    self.placementManager = PlacementManager.new()
end
function BaseMission:createHUD()
    if not Platform.isMobile then
        return HUD.new()
    end
    return MobileHUD.new(g_server ~= nil, g_client ~= nil, GS_IS_CONSOLE_VERSION, g_messageCenter, g_i18n, g_inputBinding, g_inputDisplayManager, g_modManager, g_fillTypeManager, g_fruitTypeManager, g_gui.guiSoundPlayer, self, g_farmManager, g_farmlandManager)
end
function BaseMission:delete()
    g_messageCenter:unsubscribeAll(self)
    PlatformNodeRemover.reset()
    self.isExitingGame = true
    self.isRunning = false
    g_cameraManager:setDefaultCamera()
    self:setMapTargetHotspot(nil)
    if self:getIsClient() and (g_localPlayer ~= nil and g_localPlayer:getIsInVehicle()) then
        g_localPlayer:leaveVehicle(nil, true)
    end
    for k, v in pairs(self.nonUpdateables) do
        v:delete()
        self.nonUpdateables[k] = nil
    end
    if g_server ~= nil then
        g_server:delete()
        g_server = nil
    end
    if g_client ~= nil then
        g_client:delete()
        g_client = nil
    end
    if self.placementManager ~= nil then
        self.placementManager:delete()
    end
    if g_localPlayer ~= nil then
        g_localPlayer:delete()
    end
    if self.trafficSystem ~= nil then
        self.trafficSystem:setEnabled(false)
        self.trafficSystem:reset()
    end
    if self.pedestrianSystem ~= nil then
        self.pedestrianSystem:delete()
        self.pedestrianSystem = nil
    end
    if self.shallowWaterSimulation ~= nil then
        self.shallowWaterSimulation:delete()
        self.shallowWaterSimulation = nil
    end
    g_terrainDeformationQueue:cancelAllJobs()
    self.leasedItems = {}
    self.ownedItems = {}
    self.placeableSystem:delete()
    self.vehicleSystem:delete()
    self.itemSystem:delete()
    self.onCreateObjectSystem:delete()
    self.handToolSystem:delete()
    self.beehiveSystem:delete()
    for k, v in pairs(self.dynamicallyLoadedObjects) do
        delete(v)
    end
    if self.environment ~= nil then
        g_inGameMenu:setEnvironment(nil)
        self.environment:delete()
        self.environment = nil
    end
    for k, v in pairs(self.updateables) do
        if v.delete ~= nil then
            v:delete()
        end
        table.removeElement(self.sortedUpdateables, v)
        self.updateables[k] = nil
    end
    for k, v in ipairs_reverse(g_modEventListeners) do
        if v.deleteMap ~= nil then
            v:deleteMap()
        end
    end
    if self.hud ~= nil then
        g_messageCenter:unsubscribeAll(self.hud)
        self.hud:delete()
        self.hud = nil
    end
    g_terrainNode = nil
    g_terrainSize = nil
    g_terrainSizeHalf = nil
    for k, v in pairs(self.maps) do
        delete(v)
    end
    for k, v in pairs(self.surfaceSounds) do
        g_soundManager:deleteSample(v.sample)
    end
    self.surfaceSounds = {}
    for k, v in pairs(self.cuttingSounds) do
        g_soundManager:deleteSample(v)
    end
    self.cuttingSounds = {}
    removeConsoleCommand("gsRender360Screenshot")
    removeConsoleCommand("gsShaderParamsSet")
    g_inputBinding:clearAllContexts()
    g_gui:setCurrentMission(nil)
    g_gui:setClient(nil)
end
function BaseMission:load()
    self:startLoadingTask()
    if self:getIsServer() and g_addTestCommands then
        addConsoleCommand("gsRender360Screenshot", "Renders 360 screenshots from current camera position", "consoleCommandRender360Screenshot", self)
        addConsoleCommand("gsShaderParamsSet", "Sets shader parameters for given nodeName and shader parameter name", "consoleCommandSetShaderParameter", self, "nodeName; shaderParameterName; x; y; z; w; shared")
    end
    self:finishLoadingTask()
end
function BaseMission:startLoadingTask()
    self.numLoadingTasks = self.numLoadingTasks + 1
    if self.numLoadingTasks == 1 then
        setStreamLowPriorityI3DFiles(false)
        if self.missionDynamicInfo.isMultiplayer then
            netSetIsEventProcessingEnabled(false)
        end
    end
end
function BaseMission:finishLoadingTask()
    self.numLoadingTasks = self.numLoadingTasks - 1
    if self.numLoadingTasks <= 0 then
        if not self.isLoaded then
            self:onFinishedLoading()
        end
        setStreamLowPriorityI3DFiles(true)
        if self.missionDynamicInfo.isMultiplayer then
            netSetIsEventProcessingEnabled(true)
        end
    end
end
function BaseMission:onFinishedLoading()
    self.isLoaded = true
    g_gui:setCurrentMission(self)
    g_gui:setClient(g_client)
end
function BaseMission:canStartMission()
    if not self.vehicleSystem:canStartMission() then
        return false
    end
    if not self.placeableSystem:canStartMission() then
        return false
    end
    if not self.handToolSystem:canStartMission() then
        return false
    end
    if self:getIsServer() then
        return true
    end
    return g_localPlayer ~= nil
end
function BaseMission:onStartMission()
    Logging.info("Entered Gameplay")
    setTextureStreamingPaused(false)
    self:fadeScreen(-1, 1500, nil)
    self.isMissionStarted = true
    self:setShowTriggerMarker(g_gameSettings:getValue(GameSettings.SETTING.SHOW_TRIGGER_MARKER))
    self:setShowHelpTrigger(g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_TRIGGER))
    if Profiler.IS_INITIALIZED then
        g_guidedTourManager:abortTour()
    end
end
function BaseMission:onObjectCreated(object)
    if object:isa(Player) then
        self.players[object.rootNode] = object
        if object.isOwner then
            g_inGameMenu:setPlayer(object)
            self.hud:setPlayer(object)
        end
        if self:getIsServer() then
            self.connectionsToPlayer[object.connection] = object
        end
        g_messageCenter:publish(MessageType.PLAYER_CREATED, object)
    elseif object:isa(Farm) then
        g_farmManager:onFarmObjectCreated(object)
    end
end
function BaseMission:onObjectDeleted(object)
    if object:isa(Player) then
        if g_localPlayer == object then
            g_localPlayer = nil
        end
        self.players[object.rootNode] = nil
        if self:getIsServer() then
            self.connectionsToPlayer[object.connection] = nil
            return
        end
    elseif object:isa(Farm) then
        g_farmManager:onFarmObjectDeleted(object)
    end
end
function BaseMission:loadMap(filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
    addPhysics = addPhysics == nil and true or addPhysics
    local modMapName, baseDirectory = Utils.getModNameAndBaseDirectory(filename)
    if self.numLoadingMaps == 0 then
        self.loadingMapModName = modMapName
        self.loadingMapBaseDirectory = baseDirectory
        self.loadedMapBaseDirectory = baseDirectory
        resetModOnCreateFunctions()
        for modName, loaded in pairs(g_modIsLoaded) do
            if loaded and not g_modManager:isModMap(modName) then
                _G[modName].g_onCreateUtil.activateOnCreateFunctions()
            end
        end
        if modMapName ~= nil then
            _G[modMapName].g_onCreateUtil.activateOnCreateFunctions()
        end
        self.isLoadingMap = true
    elseif self.loadingMapBaseDirectory ~= baseDirectory then
        printWarning("Warning: Asynchronous map loading from different mods. onCreate functions will not work correctly")
    end
    self.numLoadingMaps = self.numLoadingMaps + 1
    if asyncCallbackFunction == nil then
        Logging.error("Loading the map in sync is not allowed anymore! Please call loadMap with a async callback.")
        printCallstack()
    else
        g_i3DManager:loadI3DFileAsync(filename, true, addPhysics, self.loadMapFinished, self, {
            ["filename"] = filename,
            ["asyncCallbackFunction"] = asyncCallbackFunction,
            ["asyncCallbackObject"] = asyncCallbackObject,
            ["asyncCallbackArguments"] = asyncCallbackArguments
        })
    end
end
function BaseMission:loadMapFinished(node, _, arguments, callAsyncCallback)
    g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.MAP)
    local asyncCallbackFunction = arguments.asyncCallbackFunction
    if node ~= 0 then
        self:findDynamicObjects(node)
        PlatformNodeRemover.removeNodes()
    end
    if Profiler.IS_INITIALIZED then
        Profiler.setMapRootNode(node)
    end
    self.numLoadingMaps = self.numLoadingMaps - 1
    if self.numLoadingMaps == 0 then
        self.isLoadingMap = false
        resetModOnCreateFunctions()
        self.loadingMapModName = nil
        self.loadingMapBaseDirectory = ""
    end
    if node ~= 0 and not self.cancelLoading then
        table.insert(self.maps, node)
        link(getRootNode(), node)
    end
    for _, v in pairs(g_modEventListeners) do
        if v.loadMap ~= nil then
            v:loadMap(arguments.filename)
        end
    end
    if not self.cancelLoading then
        self:setShowFieldInfo(g_gameSettings:getValue(GameSettings.SETTING.SHOW_FIELD_INFO))
    end
    if (callAsyncCallback == nil or callAsyncCallback) and asyncCallbackFunction ~= nil then
        asyncCallbackFunction(arguments.asyncCallbackObject, node, arguments.asyncCallbackArguments)
    end
end
function BaseMission:loadEnvironment(xmlFile)
    local filename = Utils.getFilename(getXMLString(xmlFile, "map.environment#filename"), self.baseDirectory)
    self.environment = Environment.new(self)
    self.environment:load(filename)
    if self.missionInfo.environmentXMLLoad ~= nil and self:getIsServer() then
        local envXmlFile = loadXMLFile("environmentXML", self.missionInfo.environmentXMLLoad)
        self.environment:loadFromXMLFile(envXmlFile, "environment")
        delete(envXmlFile)
    end
    g_inGameMenu:setEnvironment(self.environment)
end
function BaseMission:findDynamicObjects(node)
    local i = 1
    local c = getNumOfChildren(node)
    for i = i, c do
        local c = getChildAt(node, i - 1)
        if RigidBodyType.DYNAMIC == getRigidBodyType(c) then
            if (not getHasClassId(c, ClassIds.SHAPE) or getSplitType(c) == 0) and self.missionDynamicInfo.isMultiplayer then
                local mpCreatePhysicsObject = Utils.getNoNil(getUserAttribute(c, "mpCreatePhysicsObject"), false)
                local mpRemoveRigidBody = Utils.getNoNil(getUserAttribute(c, "mpRemoveRigidBody"), true)
                if mpCreatePhysicsObject then
                    local object = PhysicsObject.new(self:getIsServer(), self:getIsClient())
                    self.onCreateObjectSystem:add(object)
                    object:loadOnCreate(c)
                    object:register(true)
                elseif mpRemoveRigidBody then
                    setRigidBodyType(c, RigidBodyType.NONE)
                end
            end
        else
            self:findDynamicObjects(c)
        end
    end
end
function BaseMission:loadMapSounds(xmlFilename, baseDirectory)
    if self:getIsClient() then
        local xmlFile = loadXMLFile("mapSoundXML", xmlFilename)
        if xmlFile ~= 0 then
            self.surfaceSounds = {}
            local i = 0
            while true do
                local key = string.format("sound.surface.material(%d)", i)
                if not hasXMLProperty(xmlFile, key) then
                    break
                end
                local entry = {}
                local audioGroup = AudioGroup.ENVIRONMENT
                entry.type = Utils.getNoNil(getXMLString(xmlFile, key .. "#type"), "wheel")
                if string.startsWith(entry.type, "wheel") then
                    audioGroup = AudioGroup.VEHICLE
                end
                entry.materialId = getXMLInt(xmlFile, key .. "#materialId")
                entry.name = getXMLString(xmlFile, key .. "#name")
                local loopCount = getXMLInt(xmlFile, key .. "#loopCount") or 0
                entry.sample = g_soundManager:loadSampleFromXML(xmlFile, "sound.surface", string.format("material(%d)", i), baseDirectory, getRootNode(), loopCount, audioGroup, nil, nil)
                if entry.sample ~= nil then
                    table.insert(self.surfaceSounds, entry)
                end
                i = i + 1
            end
            self.cuttingSounds = {}
            local key = 0
            while true do
                local entry = string.format("sound.cutting.sample(%d)", key)
                if not hasXMLProperty(xmlFile, entry) then
                    break
                end
                local audioGroup = getXMLString(xmlFile, entry .. "#name")
                local loopCount = g_soundManager:loadSampleFromXML(xmlFile, "sound.cutting", string.format("sample(%d)", key), baseDirectory, getRootNode(), 1, AudioGroup.ENVIRONMENT, nil, nil)
                if audioGroup == nil then
                    printWarning("Warning: a cutting sound does not have a name")
                else
                    self.cuttingSounds[audioGroup] = loopCount
                end
                key = key + 1
            end
            delete(xmlFile)
        end
    else
        return
    end
end
function BaseMission:loadObjectAtPlace(xmlFilename, places, usedPlaces, rotationOffset, ownerFarmId)
    local size = StoreItemUtil.getSizeValues(xmlFilename, "object", rotationOffset)
    local x, y, z, place, width, _ = PlacementUtil.getPlace(places, size, usedPlaces, true, true, false, true)
    if x == nil then
        return nil, true, false
    end
    local object = nil
    local yRot = MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ) + rotationOffset
    local xmlFile = loadXMLFile("tempObjectXML", xmlFilename)
    local className = Utils.getNoNil(getXMLString(xmlFile, "object.className"), "")
    local filename = getXMLString(xmlFile, "object.filename")
    local class = ClassUtil.getClassObject(className)
    if class == nil then
        printWarning("Warning: Class \'" .. tostring(className) .. "\' not found!")
    elseif filename == nil then
        printWarning("Warning: File \'" .. tostring(filename) .. "\' not found!")
    else
        object = class.new(self:getIsServer(), self:getIsClient())
        object:setOwnerFarmId(ownerFarmId, true)
        if object:load(Utils.getFilename(filename, self.baseDirectory), x, y, z, 0, yRot, 0, xmlFilename) then
            object:register()
            object:setFillLevel(object.capacity, false)
        else
            object:delete()
        end
    end
    delete(xmlFile)
    if object == nil then
        return nil, false, false
    end
    PlacementUtil.markPlaceUsed(usedPlaces, place, width)
    return object, false, false
end
function BaseMission:addOwnedItem(item)
    BaseMission.addItemToList(self.ownedItems, item)
end
function BaseMission:removeOwnedItem(item)
    BaseMission.removeItemFromList(self.ownedItems, item)
end
function BaseMission:getNumOwnedItems(storeItem, farmId)
    return BaseMission.getNumListItems(self.ownedItems, storeItem, farmId)
end
function BaseMission:addLeasedItem(item)
    BaseMission.addItemToList(self.leasedItems, item)
end
function BaseMission:removeLeasedItem(item)
    BaseMission.removeItemFromList(self.leasedItems, item)
end
function BaseMission:getNumLeasedItems(storeItem, farmId)
    return BaseMission.getNumListItems(self.leasedItems, storeItem, farmId)
end
function BaseMission.getNumListItems(list, storeItem, farmId)
    local numItems = 0
    if storeItem.bundleInfo == nil then
        if list[storeItem] ~= nil then
            if farmId == nil then
                return list[storeItem].numItems
            end
            local numItems = 0
            for _, item in pairs(list[storeItem].items) do
                if item:getOwnerFarmId() == farmId then
                end
            end
            return numItems
        end
    else
        numItems = math.huge
        for item, bundleItem in pairs(storeItem.bundleInfo.bundleItems) do
            numItems = math.min(numItems, BaseMission.getNumListItems(list, bundleItem.item, farmId))
        end
    end
    return numItems
end
function BaseMission.addItemToList(list, item)
    if list ~= nil and item ~= nil then
        local storeItem = g_storeManager:getItemByXMLFilename(item.configFileName)
        if storeItem ~= nil then
            if list[storeItem] == nil then
                list[storeItem] = {
                    ["storeItem"] = storeItem,
                    ["numItems"] = 0,
                    ["items"] = {}
                }
            end
            if list[storeItem].items[item] == nil then
                list[storeItem].numItems = list[storeItem].numItems + 1
                list[storeItem].items[item] = item
            end
        end
    end
end
function BaseMission.removeItemFromList(list, item)
    if list ~= nil and item ~= nil then
        local storeItem = g_storeManager:getItemByXMLFilename(item.configFileName)
        if storeItem ~= nil and (list[storeItem] ~= nil and list[storeItem].items[item] ~= nil) then
            list[storeItem].numItems = list[storeItem].numItems - 1
            list[storeItem].items[item] = nil
            if list[storeItem].numItems == 0 then
                list[storeItem] = nil
            end
        end
    end
end
function BaseMission:addUpdateable(updateable, key)
    assert(updateable.isa == nil or not updateable:isa(Object), "No network objects allowed in addUpdateable")
    if updateable.update == nil then
        Logging.error("Given updateable has no update function")
        printCallstack()
    else
        local oldUpdateable = self.updateables[key or updateable]
        if oldUpdateable ~= nil then
            table.removeElement(self.sortedUpdateables, oldUpdateable)
        end
        self.updateables[key or updateable] = updateable
        table.addElement(self.sortedUpdateables, updateable)
    end
end
function BaseMission:removeUpdateable(updateableOrKey)
    if self.updateables[updateableOrKey] ~= nil then
        table.removeElement(self.sortedUpdateables, self.updateables[updateableOrKey])
    end
    self.updateables[updateableOrKey] = nil
end
function BaseMission:getHasUpdateable(updateable)
    return self.updateables[updateable] ~= nil
end
function BaseMission:getHasDrawable(drawable)
    return self.drawables[drawable] ~= nil
end
function BaseMission:addDrawable(drawable, key)
    self.drawables[key or drawable] = drawable
end
function BaseMission:removeDrawable(drawable)
    self.drawables[drawable] = nil
end
function BaseMission:addNonUpdateable(nonUpdateable)
    assert(nonUpdateable.isa == nil or not nonUpdateable:isa(Object), "No network objects allowed in addNonUpdateable")
    self.nonUpdateables[nonUpdateable] = nonUpdateable
end
function BaseMission:removeNonUpdateable(nonUpdateable)
    self.nonUpdateables[nonUpdateable] = nil
end
function BaseMission:addNodeObject(node, object)
    if self.nodeToObject[node] == nil then
        self.nodeToObject[node] = object
    else
        Logging.error("Node \'%s\' already has a node-object mapping \'%s\'", getName(node), (tostring(object)))
        printCallstack()
    end
end
function BaseMission:removeNodeObject(node)
    self.nodeToObject[node] = nil
end
function BaseMission:getNodeObject(node)
    return self.nodeToObject[node]
end
function BaseMission:pauseGame()
    if not self.paused then
        self:doPauseGame()
        if self:getIsServer() then
            GamePauseEvent.sendEvent()
        end
    end
end
function BaseMission:tryUnpauseGame()
    if not self:canUnpauseGame() then
        return false
    end
    self:doUnpauseGame()
    if self:getIsServer() then
        GamePauseEvent.sendEvent()
    end
    return true
end
function BaseMission:canUnpauseGame()
    return self.paused and not (self.manualPaused or self.suspendPaused) and not self.pressStartPaused
end
function BaseMission:setManualPause(doPause)
    if (self:getIsServer() or self.isMasterUser) and doPause ~= self.manualPaused then
        self.manualPaused = doPause
        if self:getIsServer() then
            if doPause then
                self:pauseGame()
            else
                self:tryUnpauseGame()
            end
        end
        g_client:getServerConnection():sendEvent(GamePauseRequestEvent.new(doPause))
    end
end
function BaseMission:doPauseGame()
    self.paused = true
    self.isRunning = false
    simulatePhysics(false)
    simulateParticleSystems(false)
    self:resetGameState()
    if self.hud ~= nil and not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU) then
        self.hud:setInputHelpVisible(true)
    end
    for target, callbackFunc in pairs(self.pauseListeners) do
        callbackFunc(target, self.paused)
    end
    g_messageCenter:publish(MessageType.PAUSE, true)
    if self.trafficSystem ~= nil then
        self.trafficSystem:setEnabled(false)
    end
    if self.pedestrianSystem ~= nil then
        self.pedestrianSystem:setEnabled(false)
    end
end
function BaseMission:doUnpauseGame()
    self.paused = false
    self.isRunning = true
    simulatePhysics(true)
    simulateParticleSystems(true)
    if self.hud ~= nil and not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU) then
        self.hud:setInputHelpVisible(g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU))
    end
    local lastNonPauseGameState = self.lastNonPauseGameState
    if lastNonPauseGameState == GameState.MENU_INGAME and g_gui.currentGuiName ~= "InGameMenu" then
        lastNonPauseGameState = GameState.PLAY
    end
    g_gameStateManager:setGameState(lastNonPauseGameState)
    for target, callbackFunc in pairs(self.pauseListeners) do
        callbackFunc(target, self.paused)
    end
    g_messageCenter:publish(MessageType.PAUSE, false)
    if self.trafficSystem ~= nil then
        self.trafficSystem:setEnabled(self.missionInfo.trafficEnabled)
    end
    if self.pedestrianSystem ~= nil then
        self.pedestrianSystem:setEnabled(true)
    end
end
function BaseMission:addPauseListeners(target, callbackFunc)
    self.pauseListeners[target] = callbackFunc
end
function BaseMission:removePauseListeners(target)
    self.pauseListeners[target] = nil
end
function BaseMission:resetGameState()
    if self.pressStartPaused then
        g_gameStateManager:setGameState(GameState.LOADING)
        return
    elseif self.paused then
        g_gameStateManager:setGameState(GameState.PAUSED)
    else
        g_gameStateManager:setGameState(GameState.PLAY)
    end
end
function BaseMission:toggleVehicle(delta)
    if self.isToggleVehicleAllowed then
        local vehicle = self.vehicleSystem:getNextEnterableVehicle(g_localPlayer:getCurrentVehicle(), delta)
        if vehicle ~= nil then
            g_localPlayer:requestToEnterVehicle(vehicle)
        end
    end
end
function BaseMission:getIsClient()
    return g_client ~= nil
end
function BaseMission:getIsServer()
    return g_server ~= nil
end
function BaseMission.mouseEvent(_, posX, posY, isDown, isUp, button)
    for _, v in pairs(g_modEventListeners) do
        if v.mouseEvent ~= nil then
            v:mouseEvent(posX, posY, isDown, isUp, button)
        end
    end
end
function BaseMission.keyEvent(_, unicode, sym, modifier, isDown)
    for _, v in pairs(g_modEventListeners) do
        if v.keyEvent ~= nil then
            v:keyEvent(unicode, sym, modifier, isDown)
        end
    end
end
function BaseMission:preUpdate(_)
    if not self.waitForCorruptDlcs then
        if self.waitForDLCVerification and (verifyDlcs() and (g_gui:getIsGuiVisible() and g_gui.currentGuiName == "InfoDialog")) then
            g_gui:showGui("")
            self.waitForDLCVerification = false
        end
        if storeAreDlcsCorrupted() then
            self.waitForCorruptDlcs = true
            local infoDialog = g_gui:showGui("InfoDialog")
            infoDialog.target:setText(g_i18n:getText("dialog_dlcsCorruptQuit"))
            infoDialog.target:setButtonText(g_i18n:getText("button_quit"))
            infoDialog.target:setCallbacks(self.dlcProblemOnQuitOk, self, true)
            return
        end
        if not self.waitForDLCVerification and storeHaveDlcsChanged() then
            g_forceNeedsDlcsAndModsReload = true
            if not verifyDlcs() then
                self.waitForDLCVerification = true
                local infoDialog = g_gui:showGui("InfoDialog")
                infoDialog.target:setText(g_i18n:getText("dialog_reinsertDlcMedia"))
                infoDialog.target:setButtonText(g_i18n:getText("button_quit"))
                infoDialog.target:setCallbacks(self.dlcProblemOnQuitOk, self, true)
                return
            end
            if checkForNewDlcs() then
                self.hud:showInGameMessage(g_i18n:getText("message_newDlcsRestartTitle"), g_i18n:getText("message_newDlcsRestartText"), -1)
            end
        end
    end
end
function BaseMission:dlcProblemOnQuitOk()
    OnInGameMenuMenu()
end
function BaseMission:update(dt)
    if self.waitForDLCVerification or self.waitForCorruptDlcs then
        return
    else
        if self:getIsServer() then
            g_server:update(dt, self.isRunning)
        end
        if self:getIsClient() then
            g_client:update(dt, self.isRunning)
        end
        if self.gameStarted and g_appIsSuspended ~= self.suspendPaused then
            self.suspendPaused = g_appIsSuspended
            if g_appIsSuspended then
                self:pauseGame()
            else
                self:tryUnpauseGame()
            end
        end
        self.activatableObjectsSystem:update(dt)
        g_achievementManager:update(dt)
        self.hud:update(dt)
        if self.isRunning then
            for k in pairs(self.usedStorePlaces) do
                self.usedStorePlaces[k] = nil
            end
            for k in pairs(self.usedLoadPlaces) do
                self.usedLoadPlaces[k] = nil
            end
            self.time = self.time + dt
            if self:getIsClient() then
                if not g_gui:getIsGuiVisible() then
                    self.hud:updateBlinkingWarning(dt)
                    if self.currentMapTargetHotspot ~= nil then
                        local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
                        local k, hotspotZ = self.currentMapTargetHotspot:getWorldPosition()
                        if MathUtil.vector2Length(x - k, z - hotspotZ) < 10 then
                            self:setMapTargetHotspot(nil)
                        end
                    end
                end
                self.interactiveVehicleInRange = self:getInteractiveVehicleInRange()
            end
            if self.environment ~= nil then
                self.environment:update(dt)
            end
            local z = #self.sortedUpdateables
            local x = 1
            for z = z, x, -1 do
                local k = self.sortedUpdateables[z]
                if k ~= nil then
                    k:update(dt)
                end
            end
            self.vehicleSystem:update(dt)
            for k, hotspotZ in pairs(g_modEventListeners) do
                if hotspotZ.update ~= nil then
                    hotspotZ:update(dt)
                end
            end
            g_terrainDeformationQueue:update(dt)
            g_sleepManager:update(dt)
            g_baleManager:update(dt)
            g_fieldCourseManager:update(dt)
            self.beehiveSystem:update(dt)
            self.finishedFirstUpdate = true
            if g_touchHandler ~= nil then
                g_touchHandler:update(dt)
            end
            if g_inAppPurchaseController ~= nil and g_inAppPurchaseController:getIsAvailable() then
                g_inAppPurchaseController:update(dt)
            end
            self.vehicleSystem:deleteMarkedVehicles()
            self.placeableSystem:deleteMarkedPlaceables()
            self.handToolSystem:deleteMarkedHandTools()
            if self.shallowWaterSimulation ~= nil then
                self.shallowWaterSimulation:update(dt)
            end
        end
    end
end
function BaseMission:postUpdate(dt) end
function BaseMission:draw()
    local isNotFading = not self.hud:getIsFading()
    g_sleepManager:draw()
    local drawHud = not g_gui:getIsMenuVisible()
    if drawHud and (g_gui:getIsDialogVisible() and not Platform.ui.drawHudOnDialog) then
        drawHud = false
    end
    if self:getIsClient() and (self.isRunning and (drawHud and isNotFading)) then
        self.hud:drawControlledEntityHUD()
        self.vehicleSystem:draw()
        self.playerSystem:draw()
        g_soundManager:draw()
    end
    if not g_gui:getIsGuiVisible() and isNotFading then
        new2DLayer()
        if self.isRunning or self.paused then
            self.hud:drawInputHelp()
        end
        if self.isRunning then
            for _, v in pairs(g_modEventListeners) do
                if v.draw ~= nil then
                    v:draw()
                end
            end
            for _, v in pairs(self.drawables) do
                v:draw()
            end
            self.hud:drawTopNotification()
            self.hud:drawBlinkingWarning()
        end
    end
    if self.paused and not (self.isMissionStarted or g_gui:getIsGuiVisible()) then
        self.hud:drawGamePaused(true)
    end
    self.hud:drawFading()
    if g_touchHandler ~= nil then
        g_touchHandler:draw()
    end
end
function BaseMission:setTrafficSystem(trafficSystem)
    if trafficSystem == nil or self.trafficSystem == nil then
        self.trafficSystem = trafficSystem
        return true
    else
        Logging.error("BaseMission: Traffic system already set")
        return false
    end
end
function BaseMission:getTrafficSystem()
    return self.trafficSystem
end
function BaseMission:setPedestrianSystem(pedestrianSystem)
    if pedestrianSystem == nil or self.pedestrianSystem == nil then
        self.pedestrianSystem = pedestrianSystem
        return true
    else
        Logging.error("BaseMission: Pedestrian system already set")
        return false
    end
end
function BaseMission:getPedestrianSystem()
    return self.pedestrianSystem
end
function BaseMission:getTrailerInTipRange(vehicle, minDistance)
    Logging.warning("BaseMission.getTrailerInTipRange() is deprecated")
    return false
end
function BaseMission:getIsTrailerInTipRange()
    Logging.warning("BaseMission.getIsTrailerInTipRange() is deprecated")
    return false
end
function BaseMission:getInteractiveVehicleInRange()
    if g_localPlayer == nil or g_localPlayer:getAreHandsHoldingObject() then
        return nil
    end
    local nearestVehicle = nil
    local nearestDistance = math.huge
    for _, vehicle in pairs(self.vehicleSystem.interactiveVehicles) do
        if vehicle.getIsInteractive ~= nil and vehicle:getIsInteractive() then
            local vehicleDistance = vehicle:getDistanceToNode(g_localPlayer.rootNode)
            if vehicleDistance < nearestDistance then
                nearestVehicle = vehicle
                nearestDistance = vehicleDistance
            end
        end
    end
    return nearestVehicle
end
function BaseMission:setMissionInfo(missionInfo, missionDynamicInfo)
    self.missionInfo = missionInfo
    self.missionDynamicInfo = missionDynamicInfo
    self:setMoneyUnit(g_gameSettings:getValue(GameSettings.SETTING.MONEY_UNIT))
    self:setUseMiles(g_gameSettings:getValue(GameSettings.SETTING.USE_MILES))
    self:setUseFahrenheit(g_gameSettings:getValue(GameSettings.SETTING.USE_FAHRENHEIT))
    self:setUseAcre(g_gameSettings:getValue(GameSettings.SETTING.USE_ACRE))
    self.hud:setMissionInfo(missionInfo)
    g_inGameMenu:setMissionInfo(missionInfo, missionDynamicInfo, self.baseDirectory)
end
function BaseMission.onCreateTriggerMarker(_, id)
    g_currentMission:addTriggerMarker(id)
end
function BaseMission:addTriggerMarker(id)
    setVisibility(id, self.triggerMarkersAreVisible)
    table.addElement(self.triggerMarkers, id)
end
function BaseMission:removeTriggerMarker(id)
    table.removeElement(self.triggerMarkers, id)
    setVisibility(id, false)
end
function BaseMission:setShowTriggerMarker(areVisible)
    self.triggerMarkersAreVisible = areVisible
    for _, node in ipairs(self.triggerMarkers) do
        setVisibility(node, areVisible)
    end
end
function BaseMission:addHelpTrigger(id)
    setVisibility(id, self.helpTriggersAreVisible)
    table.addElement(self.helpTriggers, id)
end
function BaseMission:removeHelpTrigger(id)
    table.removeElement(self.helpTriggers, id)
end
function BaseMission:setShowHelpTrigger(areVisible)
    self.helpTriggersAreVisible = areVisible
    self:updateHelpTriggerVisibility()
end
function BaseMission:updateHelpTriggerVisibility()
    local visible = self:getCanShowHelpTriggers()
    for _, node in ipairs(self.helpTriggers) do
        setVisibility(node, visible)
        if visible then
            addToPhysics(node)
        else
            removeFromPhysics(node)
        end
    end
end
function BaseMission:getCanShowHelpTriggers()
    return self.helpTriggersAreVisible
end
function BaseMission:setShowFieldInfo(isVisible)
    self.hud:setInfoVisible(isVisible)
end
function BaseMission:addHelpButtonText()
    Logging.error("BaseMission:addHelpButtonText() is deprecated, use InputBinding:setActionEventText() instead")
    printCallstack()
end
function BaseMission:addHelpAxis()
    Logging.error("BaseMission:addHelpAxis() is deprecated")
    printCallstack()
end
function BaseMission:addExtraPrintText(text)
    self.hud:addExtraPrintText(text)
end
function BaseMission:addGameNotification(title, text, info, iconFilename, duration)
    return self.hud:addTopNotification(title, text, info, iconFilename, duration)
end
function BaseMission:showBlinkingWarning(text, durationMs, identifier)
    self.hud:showBlinkingWarning(text, durationMs, identifier)
end
function BaseMission:setMoneyUnit(unit) end
function BaseMission:setUseMiles(useMiles) end
function BaseMission:setUseAcre(useAcrea) end
function BaseMission:setUseFahrenheit(useFahrenheit) end
function BaseMission:fadeScreen(direction, duration, callbackFunc, callbackTarget, arguments)
    self.hud:fadeScreen(direction, duration, callbackFunc, callbackTarget, arguments)
end
function BaseMission:getNumOfItems(storeItem, farmId)
    local numItems = 0
    if self.ownedItems[storeItem] ~= nil then
        if farmId == nil then
        elseif self.ownedItems[storeItem].numItems > 0 then
            for _, item in pairs(self.ownedItems[storeItem].items) do
                if item:getOwnerFarmId() == farmId then
                end
            end
        end
    end
    if self.leasedItems[storeItem] ~= nil then
        if farmId == nil then
            return numItems + self.leasedItems[storeItem].numItems
        end
        if self.leasedItems[storeItem].numItems > 0 then
            for _, item in pairs(self.leasedItems[storeItem].items) do
                if item:getOwnerFarmId() == farmId then
                end
            end
        end
    end
    return numItems
end
function BaseMission:spawnCollisionTestCallback(transformId)
    if self.nodeToObject[transformId] ~= nil then
        self.spawnCollisionsFound = true
    end
end
function BaseMission:setMapTargetHotspot(mapHotspot)
    if self.currentMapTargetHotspot ~= nil then
        self.currentMapTargetHotspot:setBlinking(false)
        self.currentMapTargetHotspot:setPersistent(false)
        g_currentMission.economyManager:updateGreatDemandsPDASpots()
    end
    if mapHotspot ~= nil then
        mapHotspot:setBlinking(true)
        mapHotspot:setPersistent(Platform.ingameMap.taggedHotspotsArePersistent)
    end
    self.currentMapTargetHotspot = mapHotspot
end
function BaseMission.onCreateLoadSpawnPlace(_, node)
    local place = PlacementUtil.loadPlaceFromNode(node)
    table.insert(g_currentMission.loadSpawnPlaces, place)
end
function BaseMission.onCreateStoreSpawnPlace(_, node)
    local place = PlacementUtil.loadPlaceFromNode(node)
    table.insert(g_currentMission.storeSpawnPlaces, place)
end
function BaseMission.onCreateRestrictedZone(_, node)
    local restrictedZone = PlacementUtil.createRestrictedZone(node)
    table.insert(g_currentMission.restrictedZones, restrictedZone)
end
function BaseMission:getResetPlaces()
    if #self.loadSpawnPlaces > 0 then
        return self.loadSpawnPlaces
    else
        return self.storeSpawnPlaces
    end
end
function BaseMission.consoleCommandRender360Screenshot(_, resolution, subDir)
    local screenShotFolder = g_screenshotsDirectory
    local screenShotFolder
    if subDir == nil then
        screenShotFolder = screenShotFolder .. "fsScreen_" .. getDate("%Y_%m_%d_%H_%M_%S") .. "/"
    end
    createFolder(screenShotFolder)
    resolution = tonumber(resolution) or 512
    render360Screenshot(screenShotFolder .. "fsScreen360", resolution, "hdr_raw", 1, 0, 0, 0, 0, 5, true, 5)
end
function BaseMission.consoleCommandSetShaderParameter(_, nodeName, shaderParameterName, x, y, z, w, shared)
    if nodeName == nil then
        return "Error: no nodeName given\nUsage: gsShaderParamsSet nodeName shaderParameterName [x] [y] [z] [w] [shared]\nNodeName is case insensitive"
    end
    if shaderParameterName == nil then
        return "Error: no shaderParameterName given\nUsage: gsShaderParamsSet nodeName shaderParameterName [x] [y] [z] [w] [shared]\nNodeName is case insensitive"
    end
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)
    w = tonumber(w)
    shared = Utils.stringToBoolean(shared)
    local nodeNameUpper = string.upper(nodeName)
    local numTarversedNodes = 0
    local numAffectedNodes = 0
    I3DUtil.iterateRecursively(getRootNode(), function(node)
        -- upvalues: (ref) numTarversedNodes, (copy) nodeNameUpper, (copy) shaderParameterName, (ref) x, (ref) y, (ref) z, (ref) w, (ref) shared, (ref) numAffectedNodes
        if string.upper(getName(node)) == nodeNameUpper and getHasClassId(node, ClassIds.SHAPE) then
            if not getHasShaderParameter(node, shaderParameterName) then
                return true
            end
            local oldX, oldY, oldZ, oldW = getShaderParameter(node, shaderParameterName)
            setShaderParameter(node, shaderParameterName, x or oldX, y or oldY, z or oldZ, w or oldW, shared)
            Logging.info("set shader parameter \'%s\' for node \'%s\' to x=%.3f y=%.3f z=%.3f w=%.3f shared=%s", shaderParameterName, I3DUtil.getNodePath(node), x or oldX, y or oldY, z or oldZ, w or oldW, shared)
        end
    end)
    return string.format("Finished traversal of %d nodes, %d nodes affected", numTarversedNodes, numAffectedNodes)
end
function BaseMission:setLastInteractionTime(_)
    self.lastInteractionTime = g_time
end
function BaseMission:subscribeSettingsChangeMessages()
    local messageCenter = g_messageCenter
    messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.setMoneyUnit, self)
    messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_MILES], self.setUseMiles, self)
    messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_ACRE], self.setUseAcre, self)
    messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.setUseFahrenheit, self)
    messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_TRIGGER_MARKER], self.setShowTriggerMarker, self)
    messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_HELP_TRIGGER], self.setShowHelpTrigger, self)
    messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_FIELD_INFO], self.setShowFieldInfo, self)
end
function BaseMission:subscribeGuiOpenCloseMessages()
    g_messageCenter:subscribe(MessageType.GUI_BEFORE_OPEN, self.onBeforeMenuOpen, self)
    g_messageCenter:subscribe(MessageType.GUI_AFTER_CLOSE, self.onAfterMenuClose, self)
end
function BaseMission:onBeforeMenuOpen() end
function BaseMission:onAfterMenuClose() end
function BaseMission:onGameStateChange(newGameState, _)
    if newGameState ~= GameState.PAUSED then
        self.lastNonPauseGameState = newGameState
    end
end