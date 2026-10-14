source("dataS/scripts/vehicles/specializations/events/EnterablePassengerEnterRequestEvent.lua")
source("dataS/scripts/vehicles/specializations/events/EnterablePassengerEnterResponseEvent.lua")
source("dataS/scripts/vehicles/specializations/events/EnterablePassengerLeaveEvent.lua")
EnterablePassenger = {}
EnterablePassenger.DEBUG_ACTIVE = false
EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS = 4
function EnterablePassenger.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Enterable, specializations)
end
function EnterablePassenger.initSpecialization()
    Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER = Vehicle.registerInteractionFlag("ENTERABLE_PASSENGER")
    g_vehicleConfigurationManager:addConfigurationType("enterablePassenger", g_i18n:getText("shop_configuration"), "enterable", VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("EnterablePassenger")
    EnterablePassenger.registerXMLPaths("vehicle.enterable.passengerSeats", schema)
    EnterablePassenger.registerXMLPaths("vehicle.enterable.enterablePassengerConfigurations.enterablePassengerConfiguration(?)", schema)
    schema:setXMLSpecializationType()
end
function EnterablePassenger.registerXMLPaths(basePath, schema)
    schema:register(XMLValueType.BOOL, basePath .. "#allowInSingleplayer", "Allow usage of passenger in singleplayer", false)
    schema:register(XMLValueType.BOOL, basePath .. "#allowPassengerOnly", "Allow entering of passenger seat when no one is controlling the vehicle", false)
    schema:register(XMLValueType.BOOL, basePath .. "#allowVehicleControl", "Allow control of vehicle from passenger seat", false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".passengerSeat(?)#node", "Seat reference node to calculate entering distance to")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".passengerSeat(?)#exitPoint", "Player spawn point when leaving the vehicle")
    schema:register(XMLValueType.INT, basePath .. ".passengerSeat(?)#outdoorCameraIndex", "Index of regular outdoor camera if it should be available as well")
    schema:register(XMLValueType.FLOAT, basePath .. ".passengerSeat(?)#nicknameOffset", "Nickname rendering offset", 1.5)
    VehicleCamera.registerCameraXMLPaths(schema, basePath .. ".passengerSeat(?).camera(?)")
    VehicleCharacter.registerCharacterXMLPaths(schema, basePath .. ".passengerSeat(?).characterNode")
end
function EnterablePassenger.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getClosestSeatIndex", EnterablePassenger.getClosestSeatIndex)
    SpecializationUtil.registerFunction(vehicleType, "getIsPassengerSeatAvailable", EnterablePassenger.getIsPassengerSeatAvailable)
    SpecializationUtil.registerFunction(vehicleType, "getIsPassengerSeatIndexAvailable", EnterablePassenger.getIsPassengerSeatIndexAvailable)
    SpecializationUtil.registerFunction(vehicleType, "getFirstAvailablePassengerSeat", EnterablePassenger.getFirstAvailablePassengerSeat)
    SpecializationUtil.registerFunction(vehicleType, "getPlayerNameBySeatIndex", EnterablePassenger.getPlayerNameBySeatIndex)
    SpecializationUtil.registerFunction(vehicleType, "getCanUsePassengerSeats", EnterablePassenger.getCanUsePassengerSeats)
    SpecializationUtil.registerFunction(vehicleType, "enterVehiclePassengerSeat", EnterablePassenger.enterVehiclePassengerSeat)
    SpecializationUtil.registerFunction(vehicleType, "leaveLocalPassengerSeat", EnterablePassenger.leaveLocalPassengerSeat)
    SpecializationUtil.registerFunction(vehicleType, "leavePassengerSeat", EnterablePassenger.leavePassengerSeat)
    SpecializationUtil.registerFunction(vehicleType, "getPassengerSeatIndexByPlayer", EnterablePassenger.getPassengerSeatIndexByPlayer)
    SpecializationUtil.registerFunction(vehicleType, "copyEnterableActiveCameraIndex", EnterablePassenger.copyEnterableActiveCameraIndex)
    SpecializationUtil.registerFunction(vehicleType, "setPassengerActiveCameraIndex", EnterablePassenger.setPassengerActiveCameraIndex)
    SpecializationUtil.registerFunction(vehicleType, "enablePassengerActiveCamera", EnterablePassenger.enablePassengerActiveCamera)
    SpecializationUtil.registerFunction(vehicleType, "setPassengerSeatCharacter", EnterablePassenger.setPassengerSeatCharacter)
    SpecializationUtil.registerFunction(vehicleType, "updatePassengerSeatCharacter", EnterablePassenger.updatePassengerSeatCharacter)
    SpecializationUtil.registerFunction(vehicleType, "onPassengerPlayerStyleChanged", EnterablePassenger.onPassengerPlayerStyleChanged)
end
function EnterablePassenger.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getInteractionHelp", EnterablePassenger.getInteractionHelp)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "interact", EnterablePassenger.interact)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDistanceToNode", EnterablePassenger.getDistanceToNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnterable", EnterablePassenger.getIsEnterable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getExitNode", EnterablePassenger.getExitNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInUse", EnterablePassenger.getIsInUse)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", EnterablePassenger.getDeactivateOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInteractive", EnterablePassenger.getIsInteractive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnteredForInput", EnterablePassenger.getIsEnteredForInput)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", EnterablePassenger.getRequiresPower)
end
function EnterablePassenger.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onDrawUIInfo", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onPreRegisterActionEvents", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", EnterablePassenger)
end
function EnterablePassenger:onLoad(_)
    local spec = self.spec_enterablePassenger
    spec.currentSeatIndex = 1
    spec.passengerEntered = false
    local configIndex = self.configurations.enterablePassenger
    local configKey
    if configIndex == nil then
        configKey = "vehicle.enterable.passengerSeats"
    else
        configKey = string.format("vehicle.enterable.enterablePassengerConfigurations.enterablePassengerConfiguration(%d)", configIndex - 1)
        if not self.xmlFile:hasProperty(configKey) then
            configKey = baseKey
        end
    end
    spec.allowInSingleplayer = self.xmlFile:getValue(configKey .. "#allowInSingleplayer", false)
    spec.allowPassengerOnly = self.xmlFile:getValue(configKey .. "#allowPassengerOnly", false)
    spec.allowVehicleControl = self.xmlFile:getValue(configKey .. "#allowVehicleControl", false)
    spec.passengerSeats = {}
    for _, key in self.xmlFile:iterator(configKey .. ".passengerSeat") do
        local seatEntry = {
            ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings),
            ["exitPoint"] = self.xmlFile:getValue(key .. "#exitPoint", nil, self.components, self.i3dMappings)
        }
        if seatEntry.node == nil then
            Logging.xmlWarning(self.xmlFile, "Missing node for \'%s\'", key)
        else
            seatEntry.cameras = {}
            seatEntry.camIndex = 1
            local outdoorCameraIndex = self.xmlFile:getValue(key .. "#outdoorCameraIndex")
            if outdoorCameraIndex ~= nil then
                local specEnterable = self.spec_enterable
                if specEnterable.cameras ~= nil and specEnterable.cameras[outdoorCameraIndex] ~= nil then
                    table.insert(seatEntry.cameras, specEnterable.cameras[outdoorCameraIndex])
                end
            end
            self.xmlFile:iterate(key .. ".camera", function(index, cameraKey)
                -- upvalues: (copy) self, (copy) seatEntry
                local camera = VehicleCamera.new(self)
                if camera:loadFromXML(self.xmlFile, cameraKey, nil, index) then
                    camera.isPassengerCamera = true
                    table.insert(seatEntry.cameras, camera)
                end
            end)
            seatEntry.nicknameOffset = self.xmlFile:getValue(key .. "#nicknameOffset", 1.5)
            seatEntry.vehicleCharacter = VehicleCharacter.new(self)
            if seatEntry.vehicleCharacter ~= nil and not seatEntry.vehicleCharacter:load(self.xmlFile, key .. ".characterNode") then
                seatEntry.vehicleCharacter = nil
            end
            seatEntry.isUsed = false
            seatEntry.playerStyle = nil
            seatEntry.lastUserId = nil
            seatEntry.userId = nil
            table.insert(spec.passengerSeats, seatEntry)
        end
    end
    local configKey = false
    if #spec.passengerSeats > 0 then
        configKey = g_currentMission.missionDynamicInfo.isMultiplayer or spec.allowInSingleplayer
    end
    spec.available = configKey
    spec.texts = {}
    spec.texts.enterVehicleDriver = string.format("%s (%s)", g_i18n:getText("button_enterVehicle"), g_i18n:getText("passengerSeat_driver"))
    spec.texts.enterVehiclePassenger = string.format("%s (%s)", g_i18n:getText("button_enterVehicle"), g_i18n:getText("passengerSeat_passenger"))
    spec.texts.switchSeatDriver = g_i18n:getText("passengerSeat_switchSeatDriver")
    spec.texts.switchSeatPassenger = g_i18n:getText("passengerSeat_switchSeatPassenger")
    spec.texts.switchNextSeat = g_i18n:getText("passengerSeat_switchNextSeat")
    spec.minEnterDistance = 3
    if spec.available then
        g_messageCenter:subscribe(MessageType.PLAYER_STYLE_CHANGED, self.onPassengerPlayerStyleChanged, self)
    end
end
function EnterablePassenger:onDelete()
    local spec = self.spec_enterablePassenger
    if spec.passengerEntered then
        g_localPlayer:leaveVehicle(self, true)
        self:leavePassengerSeat(true, spec.currentSeatIndex)
    end
    if spec.passengerSeats ~= nil then
        local seatIndex = 1
        for seatIndex = seatIndex, #spec.passengerSeats do
            local passengerSeat = spec.passengerSeats[seatIndex]
            if passengerSeat.isUsed then
                local player = g_currentMission.playerSystem:getPlayerByUserId(passengerSeat.userId)
                if player ~= nil then
                    player:leaveVehicle(self, true)
                end
                self:leavePassengerSeat(false, seatIndex)
            end
            for _, camera in ipairs(passengerSeat.cameras) do
                if camera.isPassengerCamera then
                    camera:delete()
                end
            end
            if passengerSeat.vehicleCharacter ~= nil then
                passengerSeat.vehicleCharacter:delete()
            end
        end
    end
end
function EnterablePassenger:onReadStream(streamId, _)
    local seatIndex = 1
    for seatIndex = seatIndex, #self.spec_enterablePassenger.passengerSeats do
        if streamReadBool(streamId) then
            local userId = User.streamReadUserId(streamId)
            local player = g_playerSystem:getPlayerByUserId(userId)
            if player ~= nil then
                player:onEnterVehicleAsPassenger(self, seatIndex)
            end
        end
    end
end
function EnterablePassenger:onWriteStream(streamId, _)
    local spec = self.spec_enterablePassenger
    local seatIndex = 1
    for seatIndex = seatIndex, #spec.passengerSeats do
        local passengerSeat = spec.passengerSeats[seatIndex]
        if streamWriteBool(streamId, passengerSeat.isUsed) then
            User.streamWriteUserId(streamId, passengerSeat.userId)
        end
    end
end
function EnterablePassenger:onPostUpdate(dt, _, _, _)
    local spec = self.spec_enterablePassenger
    if spec.available and self.isClient then
        local specEnterable = self.spec_enterable
        if specEnterable.activeCamera ~= nil then
            specEnterable.activeCamera:update(dt)
        end
        EnterablePassenger.updateActionEvents(self)
        if spec.passengerEntered then
            self:raiseActive()
        end
        self:updatePassengerSeatCharacter(dt)
    end
end
function EnterablePassenger:onDrawUIInfo()
    local spec = self.spec_enterablePassenger
    if spec.available then
        local visible = not (g_gui:getIsGuiVisible() or g_noHudModeEnabled)
        if visible then
            visible = g_gameSettings:getValue(GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES)
        end
        if self.isClient and visible then
            local seatIndex = 1
            for seatIndex = seatIndex, #spec.passengerSeats do
                local passengerSeat = spec.passengerSeats[seatIndex]
                if passengerSeat.isUsed and (not spec.passengerEntered or seatIndex ~= spec.currentSeatIndex) and calcDistanceFrom(passengerSeat.node, getCamera()) < Enterable.NICKNAME_RENDER_DISTANCE then
                    local x, y, z = getWorldTranslation(passengerSeat.node)
                    Utils.renderTextAtWorldPosition(x, y + passengerSeat.nicknameOffset, z, self:getPlayerNameBySeatIndex(seatIndex), getCorrectTextSize(0.02), 0)
                end
            end
        end
    end
end
function EnterablePassenger:onSetBroken()
    if self.spec_enterablePassenger.passengerEntered then
        g_localPlayer:leaveVehicle()
    end
end
function EnterablePassenger:onEnterVehicle()
    if EnterablePassenger.DEBUG_ACTIVE then
        local seatIndex = 1
        for seatIndex = seatIndex, #self.spec_enterablePassenger.passengerSeats do
            self:setPassengerSeatCharacter(seatIndex, self:getUserPlayerStyle())
        end
    end
    for _, seat in ipairs(self.spec_enterablePassenger.passengerSeats) do
        if seat.lastUserId == self.spec_enterable.controllerUserId then
            seat.lastUserId = nil
        end
    end
end
function EnterablePassenger:onLeaveVehicle()
    if EnterablePassenger.DEBUG_ACTIVE then
        local seatIndex = 1
        for seatIndex = seatIndex, #self.spec_enterablePassenger.passengerSeats do
            self:setPassengerSeatCharacter(seatIndex, nil)
        end
    end
end
function EnterablePassenger:getInteractionHelp(superFunc)
    if self.spec_enterablePassenger.available and self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER then
        return self.spec_enterablePassenger.texts.enterVehiclePassenger
    else
        return superFunc(self)
    end
end
function EnterablePassenger:interact(superFunc, player)
    if self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER then
        player:requestToEnterVehicleAsPassenger(self, (self:getClosestSeatIndex(player.rootNode)))
    else
        superFunc(self, player)
    end
end
function EnterablePassenger:getIsInteractive(superFunc)
    if self.isBroken then
        return false
    elseif self:getIsControlled() then
        return self:getCanUsePassengerSeats()
    else
        return superFunc(self)
    end
end
function EnterablePassenger:getIsEnteredForInput(superFunc)
    if superFunc(self) then
        return true
    end
    local spec = self.spec_enterablePassenger
    return spec.available and (spec.passengerEntered and spec.allowVehicleControl) and true or false
end
function EnterablePassenger:getRequiresPower(superFunc)
    if superFunc(self) then
        return true
    end
    local spec = self.spec_enterablePassenger
    if spec.available and spec.allowVehicleControl then
        local seatIndex = 1
        for seatIndex = seatIndex, #spec.passengerSeats do
            if spec.passengerSeats[seatIndex].isUsed then
                return true
            end
        end
    end
    return false
end
function EnterablePassenger:getDistanceToNode(superFunc, node)
    local superDistance = superFunc(self, node)
    if self:getIsControlled() or self.spec_enterablePassenger.allowPassengerOnly then
        local seatIndex, distance = self:getClosestSeatIndex(node)
        if seatIndex ~= nil and distance < superDistance then
            self.interactionFlag = Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER
            return distance
        end
    end
    return superDistance
end
function EnterablePassenger:getIsEnterable(superFunc)
    if not self.spec_enterablePassenger.available then
        return superFunc(self)
    end
    return not self:getCanUsePassengerSeats() and superFunc(self)
end
function EnterablePassenger:getExitNode(superFunc, player)
    local spec = self.spec_enterablePassenger
    if spec.available then
        local seatIndex = 1
        for seatIndex = seatIndex, #spec.passengerSeats do
            local passengerSeat = spec.passengerSeats[seatIndex]
            if passengerSeat.lastUserId == player.userId then
                return passengerSeat.exitPoint
            end
        end
    end
    return superFunc(self, player)
end
function EnterablePassenger:getIsInUse(superFunc, connection)
    local spec = self.spec_enterablePassenger
    if spec.available then
        local seatIndex = 1
        for seatIndex = seatIndex, #spec.passengerSeats do
            if spec.passengerSeats[seatIndex].isUsed then
                return true
            end
        end
    end
    return superFunc(self, connection)
end
function EnterablePassenger:getDeactivateOnLeave(superFunc, connection)
    local spec = self.spec_enterablePassenger
    if spec.available then
        local seatIndex = 1
        for seatIndex = seatIndex, #spec.passengerSeats do
            if spec.passengerSeats[seatIndex].isUsed then
                return false
            end
        end
    end
    return superFunc(self, connection)
end
function EnterablePassenger:onPreRegisterActionEvents(_, _)
    local spec = self.spec_enterablePassenger
    if spec.available then
        self:clearActionEventsTable(spec.actionEvents)
    end
end
function EnterablePassenger:onRegisterActionEvents(_, _)
    local spec = self.spec_enterablePassenger
    if spec.available then
        if spec.passengerEntered then
            g_localPlayer.inputComponent:registerGlobalPlayerActionEvents(Vehicle.INPUT_CONTEXT_NAME)
            local currentSeat, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ENTER, self, EnterablePassenger.actionEventLeave, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            local currentSeat = spec.passengerSeats[spec.currentSeatIndex]
            if currentSeat ~= nil and #currentSeat.cameras > 0 then
                local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CAMERA_SWITCH, self, EnterablePassenger.actionEventCameraSwitch, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
                g_inputBinding:setActionEventTextVisibility(actionEventId, true)
            end
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CAMERA_ZOOM_IN_OUT, self, Enterable.actionEventCameraZoomInOut, false, true, true, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SWITCH_SEAT, self, EnterablePassenger.actionEventSwitchSeat, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
        elseif self:getIsEntered() and self:getIsActiveForInput(true, true) then
            local actionEventId, _ = self:addActionEvent(spec.actionEvents, InputAction.SWITCH_SEAT, self, EnterablePassenger.actionEventSwitchSeat, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(_, GS_PRIO_HIGH)
        end
        EnterablePassenger.updateActionEvents(self)
    end
end
function EnterablePassenger:actionEventLeave(_, _, _, _, _)
    if self.spec_enterablePassenger.passengerEntered then
        g_localPlayer:leaveVehicle()
    end
end
function EnterablePassenger:actionEventCameraSwitch(_, _, _, _, _)
    if self.spec_enterablePassenger.passengerEntered then
        self:setPassengerActiveCameraIndex()
    end
end
function EnterablePassenger:actionEventSwitchSeat(_, _, _, _, _)
    local spec = self.spec_enterablePassenger
    if spec.passengerEntered then
        local nextSeatIndex = self:getFirstAvailablePassengerSeat(spec.currentSeatIndex)
        if nextSeatIndex ~= nil then
            self:copyEnterableActiveCameraIndex(nextSeatIndex)
            g_localPlayer:requestToEnterVehicleAsPassenger(self, nextSeatIndex)
            return
        end
        if not self:getIsControlled() and g_currentMission.accessHandler:canPlayerAccess(self) then
            self:copyEnterableActiveCameraIndex()
            g_localPlayer:requestToEnterVehicle(self)
            return
        end
    end
    local nextSeatIndex = self:getFirstAvailablePassengerSeat()
    if nextSeatIndex ~= nil then
        self:copyEnterableActiveCameraIndex(nextSeatIndex)
        g_localPlayer:requestToEnterVehicleAsPassenger(self, nextSeatIndex)
    end
end
function EnterablePassenger:updateActionEvents()
    local spec = self.spec_enterablePassenger
    local switchSeatEvent = spec.actionEvents[InputAction.SWITCH_SEAT]
    if switchSeatEvent ~= nil then
        local isActive = false
        if spec.passengerEntered then
            if self:getFirstAvailablePassengerSeat(spec.currentSeatIndex) == nil then
                if not self:getIsControlled() and g_currentMission.accessHandler:canPlayerAccess(self) then
                    g_inputBinding:setActionEventText(switchSeatEvent.actionEventId, spec.texts.switchSeatDriver)
                    isActive = true
                end
            else
                g_inputBinding:setActionEventText(switchSeatEvent.actionEventId, spec.texts.switchNextSeat)
                isActive = true
            end
        end
        if not isActive and self:getFirstAvailablePassengerSeat() ~= nil then
            g_inputBinding:setActionEventText(switchSeatEvent.actionEventId, spec.texts.switchSeatPassenger)
            isActive = true
        end
        g_inputBinding:setActionEventActive(switchSeatEvent.actionEventId, isActive)
    end
end
function EnterablePassenger:getClosestSeatIndex(playerNode)
    local spec = self.spec_enterablePassenger
    local minDistance = math.huge
    local minIndex = nil
    local i = 1
    for i = i, #spec.passengerSeats do
        local passengerSeat = spec.passengerSeats[i]
        if self:getIsPassengerSeatAvailable(passengerSeat) then
            local distance = calcDistanceFrom(playerNode, passengerSeat.node)
            if distance < spec.minEnterDistance and distance < minDistance then
                minIndex = i
                minDistance = distance
            end
        end
    end
    return minIndex, minDistance
end
function EnterablePassenger.getIsPassengerSeatAvailable(_, passengerSeat)
    return not passengerSeat.isUsed
end
function EnterablePassenger:getIsPassengerSeatIndexAvailable(seatIndex)
    local passengerSeat = self.spec_enterablePassenger.passengerSeats[seatIndex]
    if passengerSeat == nil then
        return false
    else
        return self:getIsPassengerSeatAvailable(passengerSeat)
    end
end
function EnterablePassenger:getFirstAvailablePassengerSeat(startIndex)
    local spec = self.spec_enterablePassenger
    local i = startIndex or 1
    for i = i, #spec.passengerSeats do
        if self:getIsPassengerSeatAvailable(spec.passengerSeats[i]) then
            return i
        end
    end
    return nil
end
function EnterablePassenger:getPlayerNameBySeatIndex(seatIndex)
    local passengerSeat = self.spec_enterablePassenger.passengerSeats[seatIndex]
    if passengerSeat ~= nil then
        local user = g_currentMission.userManager:getUserByUserId(passengerSeat.userId)
        if user ~= nil then
            return user:getNickname()
        end
    end
    return ""
end
function EnterablePassenger:getCanUsePassengerSeats()
    if self.isBroken then
        return false
    else
        return self:getIsControlled() and true or not g_currentMission.accessHandler:canPlayerAccess(self)
    end
end
function EnterablePassenger:enterVehiclePassengerSeat(isOwner, seatIndex, playerStyle, userId)
    local spec = self.spec_enterablePassenger
    if isOwner then
        if spec.passengerEntered then
            self:leaveLocalPassengerSeat(true)
        end
        spec.currentSeatIndex = seatIndex
        spec.passengerEntered = true
        self:enablePassengerActiveCamera()
        self:setPassengerSeatCharacter(seatIndex, playerStyle)
        if self.spec_enterable.playerHotspot ~= nil then
            self.spec_enterable.playerHotspot:setOwnerFarmId(g_currentMission:getFarmId())
            g_currentMission:addMapHotspot(self.spec_enterable.playerHotspot)
        end
        if self.isClient then
            g_messageCenter:subscribe(MessageType.INPUT_BINDINGS_CHANGED, self.requestActionEventUpdate, self)
            self:requestActionEventUpdate()
        end
    else
        for index, seat in ipairs(spec.passengerSeats) do
            if seat.isUsed and seat.userId == userId then
                self:leavePassengerSeat(false, index)
                break
            end
        end
        self:setPassengerSeatCharacter(seatIndex, playerStyle)
    end
    local isEmpty = true
    local index = 1
    local currentSeat = #spec.passengerSeats
    for index = index, currentSeat do
        if spec.passengerSeats[index].isUsed then
            isEmpty = false
            break
        end
    end
    if isEmpty and not self:getIsControlled() then
        self:activate()
    end
    local currentSeat = spec.passengerSeats[seatIndex]
    if currentSeat ~= nil then
        currentSeat.isUsed = true
        currentSeat.playerStyle = playerStyle
        currentSeat.userId = userId
        currentSeat.lastUserId = userId
        for otherSeatIndex, otherSeat in ipairs(spec.passengerSeats) do
            if otherSeatIndex ~= seatIndex and otherSeat.lastUserId == userId then
                otherSeat.lastUserId = nil
            end
        end
    end
end
function EnterablePassenger:leaveLocalPassengerSeat(noEventSend)
    local spec = self.spec_enterablePassenger
    if spec.passengerEntered then
        if noEventSend ~= true then
            g_client:getServerConnection():sendEvent(EnterablePassengerLeaveEvent.new(self, g_localPlayer.userId))
        end
        self:leavePassengerSeat(true, spec.currentSeatIndex)
    end
end
function EnterablePassenger:leavePassengerSeat(isOwner, seatIndex)
    local spec = self.spec_enterablePassenger
    if isOwner then
        local specEnterable = self.spec_enterable
        if specEnterable.activeCamera ~= nil and spec.passengerEntered then
            specEnterable.activeCamera:onDeactivate()
            g_soundManager:setIsIndoor(false)
            g_currentMission.ambientSoundSystem:setIsIndoor(false)
            g_currentMission.environment.environmentMaskSystem:setIsIndoor(false)
            g_currentMission.activatableObjectsSystem:deactivate(Vehicle.INPUT_CONTEXT_NAME)
            specEnterable.activeCamera = nil
        end
        self:setMirrorVisible(false)
        self:setPassengerSeatCharacter(seatIndex, nil)
        spec.currentSeatIndex = 1
        spec.passengerEntered = false
        if self.spec_enterable.playerHotspot ~= nil then
            g_currentMission:removeMapHotspot(self.spec_enterable.playerHotspot)
        end
        if self.isClient then
            g_messageCenter:unsubscribe(MessageType.INPUT_BINDINGS_CHANGED, self)
            self:requestActionEventUpdate()
            if g_touchHandler ~= nil then
                g_touchHandler:removeGestureListener(self.touchListenerDoubleTab)
            end
        end
    else
        self:setPassengerSeatCharacter(seatIndex, nil)
    end
    local specEnterable = spec.passengerSeats[seatIndex]
    if specEnterable ~= nil then
        specEnterable.isUsed = false
        specEnterable.playerStyle = nil
        specEnterable.userId = nil
    end
    if not self:getIsControlled() then
        local isEmpty = true
        local i = 1
        for i = i, #spec.passengerSeats do
            if spec.passengerSeats[i].isUsed then
                isEmpty = false
                break
            end
        end
        if isEmpty then
            self:deactivate()
        end
    end
end
function EnterablePassenger:getPassengerSeatIndexByPlayer(userId)
    local spec = self.spec_enterablePassenger
    local i = 1
    for i = i, #spec.passengerSeats do
        if spec.passengerSeats[i].userId == userId then
            return i
        end
    end
    return nil
end
function EnterablePassenger:copyEnterableActiveCameraIndex(seatIndex)
    local specEnterable = self.spec_enterable
    if specEnterable.activeCamera ~= nil then
        if seatIndex == nil then
            if self.spec_enterablePassenger.passengerSeats[self.spec_enterablePassenger.currentSeatIndex] ~= nil then
                local foundCamera = false
                local camIndex = 1
                for camIndex = camIndex, #specEnterable.cameras do
                    if specEnterable.cameras[camIndex] == specEnterable.activeCamera then
                        specEnterable.camIndex = camIndex
                        foundCamera = true
                    end
                end
                if not foundCamera then
                    local camIndex = 1
                    for camIndex = camIndex, #specEnterable.cameras do
                        if specEnterable.cameras[camIndex].isInside == specEnterable.activeCamera.isInside then
                            specEnterable.camIndex = camIndex
                            return
                        end
                    end
                end
            end
        else
            local passengerSeat = spec.passengerSeats[seatIndex]
            if passengerSeat ~= nil then
                local foundCamera = false
                local camIndex = 1
                for camIndex = camIndex, #passengerSeat.cameras do
                    if passengerSeat.cameras[camIndex] == specEnterable.activeCamera then
                        passengerSeat.camIndex = camIndex
                        foundCamera = true
                    end
                end
                if not foundCamera then
                    local camIndex = 1
                    for camIndex = camIndex, #passengerSeat.cameras do
                        if passengerSeat.cameras[camIndex].isInside == specEnterable.activeCamera.isInside then
                            passengerSeat.camIndex = camIndex
                            return
                        end
                    end
                    return
                end
            end
        end
    end
end
function EnterablePassenger:setPassengerActiveCameraIndex(cameraIndex, seatIndex)
    local spec = self.spec_enterablePassenger
    local currentSeat = spec.passengerSeats[seatIndex or spec.currentSeatIndex]
    if currentSeat ~= nil then
        currentSeat.camIndex = cameraIndex or currentSeat.camIndex + 1
        if currentSeat.camIndex > #currentSeat.cameras then
            currentSeat.camIndex = 1
        end
    end
    self:enablePassengerActiveCamera()
end
function EnterablePassenger:enablePassengerActiveCamera()
    local spec = self.spec_enterablePassenger
    local specEnterable = self.spec_enterable
    if specEnterable.activeCamera ~= nil then
        specEnterable.activeCamera:onDeactivate()
    end
    local currentSeat = spec.passengerSeats[spec.currentSeatIndex]
    if currentSeat ~= nil then
        local activeCamera = currentSeat.cameras[currentSeat.camIndex]
        specEnterable.activeCamera = activeCamera
        specEnterable.activeCamera:onActivate()
        self:setMirrorVisible(activeCamera.useMirror)
        g_currentMission.environmentAreaSystem:setReferenceNode(activeCamera.cameraNode)
    end
    self:updatePassengerSeatCharacter(99999)
    self:raiseActive()
end
function EnterablePassenger:setPassengerSeatCharacter(seatIndex, playerStyle)
    local currentSeat = self.spec_enterablePassenger.passengerSeats[seatIndex]
    if currentSeat ~= nil and currentSeat.vehicleCharacter ~= nil then
        currentSeat.vehicleCharacter:unloadCharacter()
        if playerStyle ~= nil then
            currentSeat.vehicleCharacter:loadCharacter(playerStyle, self, EnterablePassenger.vehiclePassengerCharacterLoaded, { currentSeat })
        end
    end
end
function EnterablePassenger:updatePassengerSeatCharacter(dt)
    for _, seat in ipairs(self.spec_enterablePassenger.passengerSeats) do
        if seat.isUsed and seat.vehicleCharacter ~= nil then
            seat.vehicleCharacter:updateVisibility()
            seat.vehicleCharacter:update(dt)
        end
    end
end
function EnterablePassenger:onPassengerPlayerStyleChanged(style, userId)
    local spec = self.spec_enterablePassenger
    local seatIndex = 1
    for seatIndex = seatIndex, #spec.passengerSeats do
        if spec.passengerSeats[seatIndex].userId == userId then
            self:setPassengerSeatCharacter(seatIndex, style)
        end
    end
end
function EnterablePassenger.vehiclePassengerCharacterLoaded(_, loadingState, arguments)
    if loadingState == HumanModelLoadingState.OK then
        local currentSeat = arguments[1]
        if currentSeat ~= nil then
            currentSeat.vehicleCharacter:updateVisibility()
            currentSeat.vehicleCharacter:updateIKChains()
            if EnterablePassenger.DEBUG_ACTIVE then
                currentSeat.vehicleCharacter:setCharacterVisibility(true)
            end
        end
    end
end
function EnterablePassenger.consoleCommandDebugPassengerSeat()
    EnterablePassenger.DEBUG_ACTIVE = not EnterablePassenger.DEBUG_ACTIVE
    local vehicle = g_localPlayer:getCurrentVehicle()
    if vehicle ~= nil and vehicle.spec_enterablePassenger ~= nil then
        if EnterablePassenger.DEBUG_ACTIVE then
            local seatIndex = 1
            for seatIndex = seatIndex, #vehicle.spec_enterablePassenger.passengerSeats do
                vehicle:setPassengerSeatCharacter(seatIndex, vehicle:getUserPlayerStyle())
            end
        else
            local seatIndex = 1
            for seatIndex = seatIndex, #vehicle.spec_enterablePassenger.passengerSeats do
                vehicle:setPassengerSeatCharacter(seatIndex, nil)
            end
        end
    end
    Logging.info("Passenger Seat Debug: %s", (tostring(EnterablePassenger.DEBUG_ACTIVE)))
end
addConsoleCommand("gsVehicleDebugPassengerSeats", "Enables debugging for passenger seat character targets", "consoleCommandDebugPassengerSeat", EnterablePassenger)