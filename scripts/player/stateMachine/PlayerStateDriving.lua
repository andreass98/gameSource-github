PlayerStateDriving = {}
local PlayerStateDriving_mt = Class(PlayerStateDriving, BaseStateMachineState)
source("dataS/scripts/vehicles/VehicleEnterRequestEvent.lua")
source("dataS/scripts/vehicles/VehicleEnterResponseEvent.lua")
source("dataS/scripts/vehicles/VehicleLeaveEvent.lua")
function PlayerStateDriving.new(player, stateMachine)
    -- upvalues: (copy) PlayerStateDriving_mt
    local self = BaseStateMachineState.new(stateMachine, PlayerStateDriving_mt)
    self.player = player
    self.currentVehicle = nil
    self.player:addStateEvent(PlayerStateDriving.onEnterVehicle, self, "onEnterVehicle")
    return self
end
function PlayerStateDriving:calculateIfShouldBeForced()
    return self:getIsInVehicle() and self.stateMachine.currentState ~= self.stateMachine.states.driving
end
function PlayerStateDriving:onEnterVehicle(vehicle)
    local currentVehicle = self.player:getCurrentVehicle()
    if currentVehicle ~= nil then
        self.player:leaveVehicle(currentVehicle, true)
    end
    self.stateMachine:changeState(self, vehicle)
end
function PlayerStateDriving:onStateEntered(_, vehicle)
    if self.player.isOwner then
        local oldContext = g_inputBinding:getContextName()
        if oldContext ~= PlayerInputComponent.INPUT_CONTEXT_NAME then
            g_inputBinding:replaceContextInStack(PlayerInputComponent.INPUT_CONTEXT_NAME, Vehicle.INPUT_CONTEXT_NAME)
        end
        if oldContext == InputBinding.ROOT_CONTEXT_NAME or (oldContext == PlayerInputComponent.INPUT_CONTEXT_NAME or oldContext == PlayerInputComponent.INPUT_CONTEXT_NAME_ANIMAL_RIDING) then
            g_inputBinding:setContext(Vehicle.INPUT_CONTEXT_NAME, true, false)
        end
        local hud = g_currentMission.hud
        hud:setControlledVehicle(vehicle)
        hud:setIsControllingPlayer(false)
        hud:showVehicleName(vehicle:getUppercaseName())
        if mission:getIsRadioPlaying() then
            if not vehicle.supportsRadio and g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
                mission:pauseRadio()
            end
        elseif vehicle.supportsRadio then
            mission:playRadio()
        end
    end
    local oldContext = self.player.playerHotspot
    if oldContext ~= nil then
        oldContext:setVehicle(vehicle)
    end
    self.currentVehicle = vehicle
    self.player:hide()
    vehicle:onPlayerEnterVehicle(self.player.isOwner, self.player.graphicsComponent:getStyle(), self.player.farmId, self.player.userId)
    g_messageCenter:publish(MessageType.VEHICLE_PLAYER_ENTERED, self.currentVehicle, self.player)
end
function PlayerStateDriving:onStateExited(newState, targetX, targetY, targetZ)
    if self.currentVehicle == nil then
        Logging.devInfo("PlayerStateDriving.onStateExited: Failed to exit driving state. Player Controlled: %s - Current Vehicle: %s", self.player:getIsControlled(), self.currentVehicle)
    else
        if targetX == nil or (targetY == nil or targetZ == nil) then
            if newState ~= nil then
                self.player:teleportToExitPoint(self.currentVehicle, true)
            end
        else
            self.player:teleportTo(targetX, targetY, targetZ, nil, true)
        end
        self.currentVehicle = nil
        local playerHotspot = self.player.playerHotspot
        if playerHotspot ~= nil then
            playerHotspot:setVehicle(nil)
        end
        if self.player.isOwner then
            local mission = g_currentMission
            mission.hud:setControlledVehicle(nil)
            if g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
                mission:pauseRadio()
            end
        end
        g_messageCenter:publish(MessageType.VEHICLE_PLAYER_LEFT, self.currentVehicle, self.player)
    end
end
function PlayerStateDriving:getIsInVehicle()
    return self.currentVehicle ~= nil
end
function PlayerStateDriving:getCurrentVehicle()
    return self.currentVehicle
end
function PlayerStateDriving:getCurrentRootNode()
    return self.currentVehicle.rootNode
end
function PlayerStateDriving:getSpeed()
    return MathUtil.kmhToMps(self.currentVehicle:getLastSpeed())
end
function PlayerStateDriving:getPosition()
    return getWorldTranslation(self.currentVehicle.rootNode)
end
function PlayerStateDriving:getYaw()
    return self.currentVehicle:getMapHotspotRotation(false) - 3.141592653589793
end
function PlayerStateDriving:getCurrentFacingDirection()
    local yRot = self.currentVehicle:getMapHotspotRotation(false) - 3.141592653589793
    return MathUtil.getDirectionFromYRotation(yRot)
end
function PlayerStateDriving:getCurrentCameraNode()
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
function PlayerStateDriving:updateWhileInConversation() end