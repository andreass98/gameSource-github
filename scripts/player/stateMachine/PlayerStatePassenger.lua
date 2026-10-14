PlayerStatePassenger = {}
local PlayerStatePassenger_mt = Class(PlayerStatePassenger, PlayerStateDriving)
function PlayerStatePassenger.new(player, stateMachine)
    -- upvalues: (copy) PlayerStatePassenger_mt
    local self = BaseStateMachineState.new(stateMachine, PlayerStatePassenger_mt)
    self.player = player
    self.currentVehicle = nil
    self.player:addStateEvent(PlayerStatePassenger.onEnterVehicleAsPassenger, self, "onEnterVehicleAsPassenger")
    return self
end
function PlayerStatePassenger:calculateIfShouldBeForced()
    return self:getIsInVehicle() and self.stateMachine.currentState ~= self.stateMachine.states.passenger
end
function PlayerStatePassenger:onEnterVehicleAsPassenger(vehicle, seatIndex)
    local currentVehicle = self.player:getCurrentVehicle()
    if currentVehicle ~= nil then
        self.player:leaveVehicle(currentVehicle, true)
    end
    self.stateMachine:changeState(self, vehicle, seatIndex)
end
function PlayerStatePassenger:onStateEntered(_, vehicle, seatIndex)
    self.currentVehicle = vehicle
    if self.player.isOwner then
        local oldContext = g_inputBinding:getContextName()
        if oldContext ~= PlayerInputComponent.INPUT_CONTEXT_NAME then
            g_inputBinding:replaceContextInStack(PlayerInputComponent.INPUT_CONTEXT_NAME, Vehicle.INPUT_CONTEXT_NAME)
        end
        if oldContext == InputBinding.ROOT_CONTEXT_NAME or oldContext == PlayerInputComponent.INPUT_CONTEXT_NAME then
            g_inputBinding:setContext(Vehicle.INPUT_CONTEXT_NAME, true, false)
        end
        vehicle:enterVehiclePassengerSeat(self.player.isOwner, seatIndex, self.player.graphicsComponent:getStyle(), self.player.userId)
        local hud = g_currentMission.hud
        hud:setControlledVehicle(vehicle)
        hud:setIsControllingPlayer(false)
        hud:showVehicleName(vehicle:getUppercaseName())
        if g_currentMission:getIsRadioPlaying() then
            if not vehicle.supportsRadio and g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
                mission:pauseRadio()
            end
        elseif vehicle.supportsRadio then
            mission:playRadio()
        end
    else
        vehicle:enterVehiclePassengerSeat(self.player.isOwner, seatIndex, self.player.graphicsComponent:getStyle(), self.player.userId)
    end
    self.player:hide()
    g_messageCenter:publish(MessageType.VEHICLE_PLAYER_ENTERED, self.currentVehicle, self.player)
end
function PlayerStatePassenger:onStateExited(newState, targetX, targetY, targetZ)
    if self.currentVehicle == nil then
        Logging.devInfo("PlayerStatePassenger.onStateExited: Failed to exit passenger state. Player Controlled: %s - Current Vehicle: %s", self.player:getIsControlled(), self.currentVehicle)
    else
        if targetX == nil or (targetY == nil or targetZ == nil) then
            if newState ~= nil then
                self.player:teleportToExitPoint(self.currentVehicle, true)
            end
        else
            self.player:teleportTo(targetX, targetY, targetZ, nil, true)
        end
        self.currentVehicle = nil
        if self.player.isOwner then
            g_currentMission.hud:setControlledVehicle(nil)
            if g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
                g_currentMission:pauseRadio()
            end
        end
        g_messageCenter:publish(MessageType.VEHICLE_PLAYER_LEFT, self.currentVehicle, self.player)
    end
end
function PlayerStatePassenger:getIsInVehicle()
    return self.currentVehicle ~= nil
end
function PlayerStatePassenger:getCurrentVehicle()
    return self.currentVehicle
end
function PlayerStatePassenger:getCurrentRootNode()
    return self.currentVehicle.rootNode
end
function PlayerStatePassenger:getSpeed()
    return MathUtil.kmhToMps(self.currentVehicle:getLastSpeed())
end
function PlayerStatePassenger:getPosition()
    return getWorldTranslation(self.currentVehicle.rootNode)
end
function PlayerStatePassenger:getYaw()
    local vehicleForwardX, _, vehicleForwardZ = localDirectionToWorld(self.currentVehicle.rootNode, 0, 0, 1)
    return MathUtil.getYRotationFromDirection(vehicleForwardX, vehicleForwardZ)
end
function PlayerStatePassenger:getCurrentFacingDirection()
    local vehicleForwardX, _, vehicleForwardZ = localDirectionToWorld(self.currentVehicle.rootNode, 0, 0, 1)
    return vehicleForwardX, vehicleForwardZ
end
function PlayerStatePassenger:getCurrentCameraNode()
    local enterable = self.currentVehicle.spec_enterable
    if enterable == nil then
        Logging.error("Player has somehow entered a vehicle with no enterable spec, and needs the vehicle\'s camera!")
        return nil
    end
    local vehicleCamera = enterable.cameras[enterable.camIndex]
    if vehicleCamera ~= nil and (vehicleCamera.cameraNode ~= nil and vehicleCamera.cameraNode ~= 0) then
        return vehicleCamera.cameraNode
    end
    Logging.error("Player has somehow entered an enterable vehicle with no camera!")
    return nil
end