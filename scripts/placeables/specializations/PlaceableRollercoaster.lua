PlaceableRollercoaster = {}
PlaceableRollercoaster.SEAT_INDEX_NUM_BITS = 4
PlaceableRollercoaster.SEAT_MAX_NUM = 2 ^ PlaceableRollercoaster.SEAT_INDEX_NUM_BITS - 1
PlaceableRollercoaster.INSTANCE = nil
PlaceableRollercoaster.INPUT_CONTEXT_ROLLERCOASTER = "ROLLERCOASTER"
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterActivatable.lua")
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterHotspot.lua")
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterPassengerEnterRequestEvent.lua")
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterPassengerEnterResponseEvent.lua")
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterStateRideWaiting.lua")
source("dataS/scripts/placeables/specializations/rollercoaster/RollercoasterStateRiding.lua")
function PlaceableRollercoaster.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableConstructible, specializations)
end
function PlaceableRollercoaster.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onSharedAnimationFileLoaded", PlaceableRollercoaster.onSharedAnimationFileLoaded)
    SpecializationUtil.registerFunction(placeableType, "getCanEnter", PlaceableRollercoaster.getCanEnter)
    SpecializationUtil.registerFunction(placeableType, "getFreeSeatIndex", PlaceableRollercoaster.getFreeSeatIndex)
    SpecializationUtil.registerFunction(placeableType, "getCanStart", PlaceableRollercoaster.getCanStart)
    SpecializationUtil.registerFunction(placeableType, "startRide", PlaceableRollercoaster.startRide)
    SpecializationUtil.registerFunction(placeableType, "endRide", PlaceableRollercoaster.endRide)
    SpecializationUtil.registerFunction(placeableType, "getAnimation", PlaceableRollercoaster.getAnimation)
    SpecializationUtil.registerFunction(placeableType, "setAnimationTime", PlaceableRollercoaster.setAnimationTime)
    SpecializationUtil.registerFunction(placeableType, "updateFxModifierValues", PlaceableRollercoaster.updateFxModifierValues)
    SpecializationUtil.registerFunction(placeableType, "tryEnterRide", PlaceableRollercoaster.tryEnterRide)
    SpecializationUtil.registerFunction(placeableType, "enterRide", PlaceableRollercoaster.enterRide)
    SpecializationUtil.registerFunction(placeableType, "exitRide", PlaceableRollercoaster.exitRide)
    SpecializationUtil.registerFunction(placeableType, "onUserRemoved", PlaceableRollercoaster.onUserRemoved)
    SpecializationUtil.registerFunction(placeableType, "registerRidersChangedListener", PlaceableRollercoaster.registerRidersChangedListener)
    SpecializationUtil.registerFunction(placeableType, "unregisterRidersChangedListener", PlaceableRollercoaster.unregisterRidersChangedListener)
    SpecializationUtil.registerFunction(placeableType, "getParentComponent", PlaceableRollercoaster.getParentComponent)
    SpecializationUtil.registerFunction(placeableType, "passengerCharacterLoaded", PlaceableRollercoaster.passengerCharacterLoaded)
    SpecializationUtil.registerFunction(placeableType, "playerTriggerCallback", PlaceableRollercoaster.playerTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "setPlayerTriggerState", PlaceableRollercoaster.setPlayerTriggerState)
    SpecializationUtil.registerFunction(placeableType, "getNumRides", PlaceableRollercoaster.getNumRides)
end
function PlaceableRollercoaster.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getHotspot", PlaceableRollercoaster.getHotspot)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableRollercoaster.finalizeConstruction)
end
function PlaceableRollercoaster.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableRollercoaster)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableRollercoaster)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableRollercoaster)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableRollercoaster)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableRollercoaster)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableRollercoaster)
end
function PlaceableRollercoaster.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Rollercoaster")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.animation.clip#rootNode", "Animation root node")
    schema:register(XMLValueType.STRING, basePath .. ".rollercoaster.animation.clip#name", "Animation clip name")
    schema:register(XMLValueType.STRING, basePath .. ".rollercoaster.animation.clip#filename", "Animation filename")
    schema:register(XMLValueType.FLOAT, basePath .. ".rollercoaster.animation#speedScale", "Animation speed scale")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.movingSounds.sound(?)#node", "")
    schema:register(XMLValueType.STRING, basePath .. ".rollercoaster.movingSounds.sound(?)#filename", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".rollercoaster.movingSounds.sound(?)#innerRadius", "Audio source inner radius")
    schema:register(XMLValueType.FLOAT, basePath .. ".rollercoaster.movingSounds.sound(?)#radius", "Audio source radius")
    schema:register(XMLValueType.FLOAT, basePath .. ".rollercoaster.movingSounds.sound(?)#volume", "Audio source volume")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".rollercoaster.sounds", "driving1")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".rollercoaster.sounds", "driving2")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".rollercoaster.sounds", "driving3")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".rollercoaster.sounds", "driving4")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".rollercoaster.sounds", "driving5")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.playerTrigger#node", "Player trigger for entering the ride")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.exitPoints.exitPoint(?)#node", "Node where players exit the rollercoaster")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.hotspot#linkNode", "Node where hotspot is linked to")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.hotspot#teleportNode", "Node where player is teleported to. Teleporting is only available if this is set")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.carts.cart(?)#node", "Cart node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".rollercoaster.carts.cart(?).seat(?)#node", "Seat reference node to calculate entering distance to")
    VehicleCamera.registerCameraXMLPaths(schema, basePath .. ".rollercoaster.carts.cart(?).seat(?).camera")
    VehicleCharacter.registerCharacterXMLPaths(schema, basePath .. ".rollercoaster.carts.cart(?).seat(?).characterNode")
    schema:setXMLSpecializationType()
end
function PlaceableRollercoaster.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. ".state#index", "")
    schema:register(XMLValueType.FLOAT, basePath .. "#splineTime", "")
    schema:register(XMLValueType.STRING, basePath .. ".player(?)#uniqueUserId", "")
    schema:register(XMLValueType.INT, basePath .. ".player(?)#rideCount", 0)
end
function PlaceableRollercoaster:onLoad(_)
    local spec = self.spec_rollercoaster
    local clipRootNode = self.xmlFile:getValue("placeable.rollercoaster.animation.clip#rootNode", nil, self.components, self.i3dMappings)
    local clipName = self.xmlFile:getValue("placeable.rollercoaster.animation.clip#name")
    local _, baseDirectory = Utils.getModNameAndBaseDirectory(self.xmlFile:getFilename())
    if clipRootNode ~= nil and clipName ~= nil then
        local clipFilename = self.xmlFile:getValue("placeable.rollercoaster.animation.clip#filename")
        spec.animation = {}
        spec.animation.clipRootNode = clipRootNode
        spec.animation.clipName = clipName
        spec.animation.clipTrack = 0
        spec.animation.speedScale = self.xmlFile:getValue("placeable.rollercoaster.animation#speedScale", 1)
        if clipFilename ~= nil then
            local loadingTask = Utils.getFilename(clipFilename, baseDirectory)
            local arguments = {
                ["loadingTask"] = self:createLoadingTask()
            }
            spec.animation.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(loadingTask, false, false, self.onSharedAnimationFileLoaded, self, arguments)
            spec.animation.clipFilename = loadingTask
        end
        setVisibility(clipRootNode, false)
        spec.animationTimeInterpolator = InterpolationTime.new(1.3)
        spec.animationInterpolator = InterpolatorValue.new(0)
    end
    spec.playerTrigger = self.xmlFile:getValue("placeable.rollercoaster.playerTrigger#node", nil, self.components, self.i3dMappings)
    addTrigger(spec.playerTrigger, "playerTriggerCallback", self)
    self:setPlayerTriggerState(false)
    spec.activatable = RollercoasterActivatable.new(self)
    spec.carts = {}
    spec.seats = {}
    for cartIndex, cartKey in self.xmlFile:iterator("placeable.rollercoaster.carts.cart") do
        local cart = {
            ["node"] = self.xmlFile:getValue(cartKey .. "#node", nil, self.components, self.i3dMappings),
            ["slope"] = 0,
            ["angleChange"] = 0
        }
        local soundFilename, innerRadius, radius = localDirectionToWorld(cart.node, 0, 0, 1)
        cart.dirX = soundFilename
        cart.dirY = innerRadius
        cart.dirZ = radius
        for _, seatKey in self.xmlFile:iterator(cartKey .. ".seat") do
            local seatEntry = {
                ["cart"] = cart,
                ["node"] = self.xmlFile:getValue(seatKey .. "#node", nil, self.components, self.i3dMappings)
            }
            if seatEntry.node ~= nil then
                local camera = VehicleCamera.new(self)
                if camera:loadFromXML(self.xmlFile, seatKey .. ".camera", nil, 1) then
                    seatEntry.camera = camera
                end
                seatEntry.vehicleCharacter = VehicleCharacter.new(self)
                if seatEntry.vehicleCharacter ~= nil and not seatEntry.vehicleCharacter:load(self.xmlFile, seatKey .. ".characterNode") then
                    seatEntry.vehicleCharacter = nil
                end
            end
            seatEntry.characterSpineLastRotationX = 0
            seatEntry.characterSpineLastRotationZ = 0
            seatEntry.randomFactor = math.random()
            seatEntry.smoothingFactor = 1 - math.random(10, 40) / 100
            seatEntry.smoothingFactorInv = 1 - seatEntry.smoothingFactor
            table.insert(spec.seats, seatEntry)
        end
        table.insert(spec.carts, cart)
    end
    spec.centerCart = spec.carts[MathUtil.round(#spec.carts / 2)]
    spec.localSeatIndex = nil
    spec.numRiders = 0
    spec.ridersChangedListeners = {}
    spec.exitPoints = {}
    for cartIndex, cartKey in self.xmlFile:iterator("placeable.rollercoaster.exitPoints.exitPoint") do
        local cart = self.xmlFile:getValue(cartKey .. "#node", nil, self.components, self.i3dMappings)
        if cart ~= nil then
            table.insert(spec.exitPoints, cart)
        end
    end
    if #spec.exitPoints < #spec.seats then
        Logging.xmlWarning(self.xmlFile, "Only %d exitPoints defined for %d seats", #spec.exitPoints, #spec.seats)
    end
    spec.rollercoasterHotspot = RollercoasterHotspot.new()
    spec.hotSpotLinkNode = self.xmlFile:getValue("placeable.rollercoaster.hotspot#linkNode", nil, self.components, self.i3dMappings)
    spec.hotSpotTeleportNode = self.xmlFile:getValue("placeable.rollercoaster.hotspot#teleportNode", nil, self.components, self.i3dMappings)
    if self.isClient then
        spec.soundsMoving = {}
        for cartIndex, cartKey in self.xmlFile:iterator("placeable.rollercoaster.movingSounds.sound") do
            local cart = self.xmlFile:getValue(cartKey .. "#node", nil, self.components, self.i3dMappings)
            local soundFilename = Utils.getFilename(self.xmlFile:getValue(cartKey .. "#filename"), baseDirectory)
            local innerRadius = self.xmlFile:getValue(cartKey .. "#innerRadius")
            local radius = self.xmlFile:getValue(cartKey .. "#radius")
            local seatKey = createAudioSource("rollercoaster_" .. tostring(cartIndex), soundFilename, radius, innerRadius, self.xmlFile:getValue(cartKey .. "#volume", 1), 0)
            local seatEntry = getAudioSourceSample(seatKey)
            setSampleGroup(seatEntry, AudioGroup.ENVIRONMENT)
            link(getChildAt(cart, 1), seatKey)
            table.insert(spec.soundsMoving, {
                ["node"] = cart,
                ["movingSound"] = nil
            })
        end
        spec.sounds = {}
        spec.sounds.driving1 = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.rollercoaster.sounds", "driving1", baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
        spec.sounds.driving2 = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.rollercoaster.sounds", "driving2", baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
        spec.sounds.driving3 = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.rollercoaster.sounds", "driving3", baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
        spec.sounds.driving4 = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.rollercoaster.sounds", "driving4", baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
        spec.sounds.driving5 = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.rollercoaster.sounds", "driving5", baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
        spec.speed = 0
        local clipFilename, loadingTask, arguments = getWorldTranslation(spec.centerCart.node)
        spec.posX = clipFilename
        spec.posY = loadingTask
        spec.posZ = arguments
        self.currentUpdateDistance = math.huge
    end
    g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
end
function PlaceableRollercoaster:onSharedAnimationFileLoaded(node, _, args)
    local spec = self.spec_rollercoaster
    if node ~= 0 and node ~= nil then
        if not self.isDeleted then
            local animNode = getChildAt(getChildAt(node, 0), 0)
            if cloneAnimCharacterSet(animNode, spec.animation.clipRootNode) then
                local characterSet = getAnimCharacterSet(spec.animation.clipRootNode)
                local clipIndex = getAnimClipIndex(characterSet, spec.animation.clipName)
                if clipIndex == -1 then
                    Logging.error("Animation clip with name \'%s\' does not exist in \'%s\'", spec.animation.clipName, spec.animation.clipFilename or self.xmlFilename)
                else
                    assignAnimTrackClip(characterSet, spec.animation.clipTrack, clipIndex)
                    setAnimTrackLoopState(characterSet, spec.animation.clipTrack, false)
                    spec.animation.clipDuration = getAnimClipDuration(characterSet, clipIndex)
                    spec.animation.clipIndex = clipIndex
                    spec.animation.clipCharacterSet = characterSet
                    setAnimTrackSpeedScale(characterSet, clipIndex, spec.animation.speedScale)
                end
            end
        end
        delete(node)
    end
    spec.playerRideCounter = {}
    for _, state in pairs(self.spec_constructible.stateMachine) do
        if state.init ~= nil then
            state:init()
        end
    end
    self:finishLoadingTask(args.loadingTask)
end
function PlaceableRollercoaster:onFinalizePlacement(_)
    local spec = self.spec_rollercoaster
    spec.rollercoasterHotspot:setPlaceable(self)
    spec.rollercoasterHotspot:setOwnerFarmId(nil)
    local x, _, z = getWorldTranslation(spec.hotSpotLinkNode)
    spec.rollercoasterHotspot:setWorldPosition(x, z)
    local x, y, z = getWorldTranslation(spec.hotSpotTeleportNode)
    spec.rollercoasterHotspot:setTeleportWorldPosition(x, y, z)
    g_currentMission:addMapHotspot(spec.rollercoasterHotspot)
    if PlaceableRollercoaster.INSTANCE == nil then
        PlaceableRollercoaster.INSTANCE = self
    end
end
function PlaceableRollercoaster:onDelete()
    local spec = self.spec_rollercoaster
    g_messageCenter:unsubscribeAll(self)
    g_currentMission:removeMapHotspot(spec.rollercoasterHotspot)
    spec.rollercoasterHotspot:delete()
    if spec.animation ~= nil and spec.animation.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.animation.sharedLoadRequestId)
        spec.animation.sharedLoadRequestId = nil
    end
    for _, seat in ipairs(spec.seats) do
        if seat.vehicleCharacter ~= nil then
            seat.vehicleCharacter:delete()
        end
        if seat.camera ~= nil then
            seat.camera:delete()
        end
    end
    if spec.soundsMoving ~= nil then
        for _, seat in ipairs(spec.soundsMoving) do
            if seat.movingSound ~= nil then
                g_currentMission.ambientSoundSystem:removeMovingSound(seat.movingSound)
                seat.movingSound = nil
            end
        end
    end
    if spec.sounds ~= nil then
        g_soundManager:deleteSamples(spec.sounds)
    end
    if spec.playerTrigger ~= nil then
        removeTrigger(spec.playerTrigger)
        spec.playerTrigger = nil
    end
    if PlaceableRollercoaster.INSTANCE == self then
        PlaceableRollercoaster.INSTANCE = nil
    end
end
function PlaceableRollercoaster:saveToXMLFile(xmlFile, key, _)
    local i = 0
    for uniqueUserId, rideCount in pairs(self.spec_rollercoaster.playerRideCounter) do
        local counterKey = string.format("%s.player(%d)", key, i)
        xmlFile:setValue(counterKey .. "#uniqueUserId", uniqueUserId)
        xmlFile:setValue(counterKey .. "#rideCount", rideCount)
        i = i + 1
    end
end
function PlaceableRollercoaster:loadFromXMLFile(xmlFile, key)
    for _, counterKey in xmlFile:iterator(key .. ".player") do
        local uniqueUserId = xmlFile:getValue(counterKey .. "#uniqueUserId")
        local rideCount = xmlFile:getValue(counterKey .. "#rideCount")
        if uniqueUserId ~= nil and rideCount ~= nil then
            self.spec_rollercoaster.playerRideCounter[uniqueUserId] = rideCount
        end
    end
end
function PlaceableRollercoaster:onReadStream(streamId, _)
    for seatIndex, seat in ipairs(self.spec_rollercoaster.seats) do
        if streamReadBool(streamId) then
            self:enterRide(seatIndex, (NetworkUtil.readNodeObject(streamId)))
        end
    end
end
function PlaceableRollercoaster:onWriteStream(streamId, _)
    for seatIndex, seat in ipairs(self.spec_rollercoaster.seats) do
        if streamWriteBool(streamId, seat.player ~= nil) then
            NetworkUtil.writeNodeObject(streamId, seat.player)
        end
    end
end
function PlaceableRollercoaster:onUpdate(dt)
    if self.isClient then
        if self.spec_rollercoaster.localSeatIndex ~= nil then
            spec.seats[spec.localSeatIndex].camera:update(dt)
            self:raiseActive()
        end
        for _, seat in ipairs(spec.seats) do
            if seat.player ~= nil and seat.player ~= g_localPlayer then
                local randomDeviation = 1 - seat.randomFactor + math.sin(g_time / 500 + seat.randomFactor) * (seat.randomFactor / 5)
                seat.characterSpineLastRotationX = seat.smoothingFactor * seat.characterSpineLastRotationX + seat.smoothingFactorInv * ((seat.cart.slope + randomDeviation / 2) / 5)
                seat.characterSpineLastRotationZ = seat.smoothingFactor * seat.characterSpineLastRotationZ + seat.smoothingFactorInv * ((seat.cart.angleChange - randomDeviation) / 20)
                setRotation(seat.vehicleCharacter.characterNode, seat.characterSpineLastRotationX, 0, seat.characterSpineLastRotationZ)
                seat.vehicleCharacter:updateVisibility()
                seat.vehicleCharacter:update(dt)
            end
        end
        if spec.numRiders > 0 then
            self:raiseActive()
            self.currentUpdateDistance = calcDistanceFrom(spec.centerCart.node, getCamera())
        end
    end
end
function PlaceableRollercoaster:finalizeConstruction(superFunc)
    superFunc(self)
    local spec = self.spec_rollercoaster
    if spec.soundsMoving ~= nil then
        for _, sound in ipairs(spec.soundsMoving) do
            if sound.node and sound.movingSound == nil then
                sound.movingSound = g_currentMission.ambientSoundSystem:addMovingSound(sound.node)
            end
        end
    end
    spec.rollercoasterHotspot:changeToRollercoaster()
end
function PlaceableRollercoaster:getCanEnter()
    local isInWaitingState = self:getConstructibleStateIndex() == self:getConstructibleStateIndexByName("RIDE_WAITING")
    if isInWaitingState then
        isInWaitingState = false
        if self.spec_rollercoaster.animation.clipCharacterSet ~= nil then
            isInWaitingState = false
            if spec.localSeatIndex == nil then
                isInWaitingState = spec.numRiders < #spec.seats
            end
        end
    end
    return isInWaitingState
end
function PlaceableRollercoaster:getFreeSeatIndex()
    for seatIndex, seat in ipairs(self.spec_rollercoaster.seats) do
        if seat.player == nil then
            return seatIndex
        end
    end
    return nil
end
function PlaceableRollercoaster:getCanStart()
    return self.spec_rollercoaster.numRiders > 0
end
function PlaceableRollercoaster:startRide()
    local spec = self.spec_rollercoaster
    if spec.animation.clipCharacterSet ~= nil then
        local _ = spec.localSeatIndex == nil
        if self.isClient then
            spec.animationInterpolator:setValue(0)
            spec.animationTimeInterpolator:reset()
        end
        setAnimTrackTime(spec.animation.clipCharacterSet, spec.animation.clipTrack, 0, true)
        enableAnimTrack(spec.animation.clipCharacterSet, spec.animation.clipTrack)
        if self.isClient then
            g_soundManager:playSamples(spec.sounds)
        end
    end
end
function PlaceableRollercoaster:endRide()
    local spec = self.spec_rollercoaster
    if self.isClient then
        g_soundManager:stopSamples(spec.sounds)
    end
    for seatIndex, seat in ipairs(spec.seats) do
        if seat.player ~= nil then
            self:exitRide(seatIndex)
        end
    end
end
function PlaceableRollercoaster:tryEnterRide(connection, _)
    local seatIndex = self:getFreeSeatIndex()
    if seatIndex ~= nil then
        local userId = g_currentMission.userManager:getUserIdByConnection(connection)
        g_server:broadcastEvent(RollercoasterPassengerEnterResponseEvent.new(self, userId, seatIndex), true, nil, self, false, nil, true)
    end
end
function PlaceableRollercoaster:enterRide(seatIndex, player)
    local spec = self.spec_rollercoaster
    if player == g_localPlayer then
        spec.localSeatIndex = seatIndex
        spec.seats[seatIndex].camera:onActivate()
    else
        local playerStyle = player.graphicsComponent:getStyle()
        spec.seats[seatIndex].vehicleCharacter:loadCharacter(playerStyle, self, PlaceableRollercoaster.passengerCharacterLoaded, {
            ["seat"] = spec.seats[seatIndex]
        })
    end
    spec.numRiders = spec.numRiders + 1
    for target, func in pairs(spec.ridersChangedListeners) do
        func(spec.numRiders, 1, player)
    end
    if spec.numRiders >= #spec.seats then
        self:setPlayerTriggerState(false)
    end
    spec.seats[seatIndex].player = player
    self:raiseActive()
end
function PlaceableRollercoaster:exitRide(seatIndex)
    local spec = self.spec_rollercoaster
    spec.seats[seatIndex].vehicleCharacter:unloadCharacter()
    local player = spec.seats[seatIndex].player
    if spec.localSeatIndex == seatIndex then
        spec.seats[seatIndex].camera:onDeactivate()
        g_currentMission.hud:setIsVisible(true)
        spec.localSeatIndex = nil
    end
    player:onLeaveRollercoaster()
    spec.numRiders = spec.numRiders - 1
    for target, func in pairs(spec.ridersChangedListeners) do
        func(spec.numRiders, -1, spec.seats[seatIndex].player)
    end
    if self.isServer and player ~= nil then
        local user = g_currentMission.userManager:getUserByUserId(player.userId)
        if user ~= nil then
            local uniqueUserId = user:getUniqueUserId()
            if spec.playerRideCounter[uniqueUserId] == nil then
                spec.playerRideCounter[uniqueUserId] = 0
            end
            spec.playerRideCounter[uniqueUserId] = spec.playerRideCounter[uniqueUserId] + 1
        end
        if player == g_localPlayer then
            g_currentMission:farmStats(g_localPlayer.farmId)
        end
    end
    spec.seats[seatIndex].player = nil
end
function PlaceableRollercoaster:onUserRemoved(user)
    local userId = user:getId()
    for seatIndex, seat in ipairs(self.spec_rollercoaster.seats) do
        if seat.player ~= nil and seat.player.userId == userId then
            self:exitRide(seatIndex)
            return
        end
    end
end
function PlaceableRollercoaster:registerRidersChangedListener(target, func)
    self.spec_rollercoaster.ridersChangedListeners[target] = func
end
function PlaceableRollercoaster:unregisterRidersChangedListener(target)
    self.spec_rollercoaster.ridersChangedListeners[target] = nil
end
function PlaceableRollercoaster:getAnimation()
    return self.spec_rollercoaster.animation
end
function PlaceableRollercoaster:setAnimationTime(animationTime)
    local spec = self.spec_rollercoaster
    setAnimTrackTime(spec.animation.clipCharacterSet, spec.animation.clipTrack, animationTime, true)
end
function PlaceableRollercoaster:updateFxModifierValues(dt)
    local spec = self.spec_rollercoaster
    local x, y, z = getWorldTranslation(spec.centerCart.node)
    local distance = MathUtil.vector3Length(x - spec.posX, y - spec.posY, z - spec.posZ)
    spec.posX = x
    spec.posY = y
    spec.posZ = z
    spec.speed = 0.2 * spec.speed + 0.8 * distance / (dt / 1000)
    for _, cart in ipairs(spec.carts) do
        local dx, dy, dz = localDirectionToWorld(cart.node, 0, 0, 1)
        local angleChange = MathUtil.getVectorAngleDifference(dx, 0, dz, cart.dirX, 0, cart.dirZ)
        local angleChange = MathUtil.isNan(angleChange) and 0 or angleChange
        cart.angleChange = 0.6 * cart.angleChange + 0.4 * (angleChange * 100)
        cart.dirX = dx
        cart.dirY = dy
        cart.dirZ = dz
        local slope, dy, dz = localDirectionToWorld(cart.node, 1, 0, 0)
        local slope = math.acos(dy / MathUtil.vector3Length(slope, dy, dz)) - 1.5707963267948966
        cart.slope = 0.7 * cart.slope + 0.3 * slope
    end
end
function PlaceableRollercoaster.getParentComponent(_, node)
    return getParent(node)
end
function PlaceableRollercoaster.passengerCharacterLoaded(_, success, arguments)
    if success then
        local seat = arguments.seat
        if seat ~= nil then
            seat.vehicleCharacter:updateVisibility()
            seat.vehicleCharacter:updateIKChains()
        end
    end
end
function PlaceableRollercoaster:playerTriggerCallback(_, otherId, onEnter, onLeave, _, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        if onEnter then
            if Platform.isMobile and self.spec_rollercoaster.activatable:getIsActivatable() then
                spec.activatable:run()
                return
            end
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
        end
        if onLeave then
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end
function PlaceableRollercoaster:setPlayerTriggerState(state)
    setVisibility(self.spec_rollercoaster.playerTrigger, state)
end
function PlaceableRollercoaster:getNumRides(uniqueUserId)
    return self.spec_rollercoaster.playerRideCounter[uniqueUserId] or 0
end
function PlaceableRollercoaster:getHotspot(_)
    return self.spec_rollercoaster.rollercoasterHotspot
end
function PlaceableRollercoaster:getSpeedSoundModifier()
    return self.spec_rollercoaster.speed
end
g_soundManager:registerModifierType("ROLLERCOASTER_SPEED", PlaceableRollercoaster.getSpeedSoundModifier)
function PlaceableRollercoaster:getCurveSoundModifier()
    local spec = self.spec_rollercoaster
    if spec.localSeatIndex == nil then
        return math.abs(spec.centerCart.angleChange)
    else
        return math.abs(spec.seats[spec.localSeatIndex].cart.angleChange)
    end
end
g_soundManager:registerModifierType("ROLLERCOASTER_CURVE", PlaceableRollercoaster.getCurveSoundModifier)