PlayerStateRollercoaster = {}
local PlayerStateRollercoaster_mt = Class(PlayerStateRollercoaster, PlayerStateDriving)
function PlayerStateRollercoaster.new(player, stateMachine)
    -- upvalues: (copy) PlayerStateRollercoaster_mt
    local self = BaseStateMachineState.new(stateMachine, PlayerStateRollercoaster_mt)
    self.player = player
    self.rollercoaster = nil
    self.player:addStateEvent(PlayerStateRollercoaster.onEnterRollercoaster, self, "onEnterRollercoaster")
    return self
end
function PlayerStateRollercoaster:calculateIfShouldBeForced()
    return self:getIsInRollercoaster() and self.stateMachine.currentState ~= self.stateMachine.states.rollercoaster
end
function PlayerStateRollercoaster:onEnterRollercoaster(rollercoaster, seatIndex)
    local currentVehicle = self.player:getCurrentVehicle()
    if currentVehicle ~= nil then
        self.player:leaveVehicle(currentVehicle, true)
    end
    self.stateMachine:changeState(self, rollercoaster, seatIndex)
end
function PlayerStateRollercoaster:onStateEntered(_, rollercoaster, seatIndex)
    self.rollercoaster = rollercoaster
    self.seatIndex = seatIndex
    if self.player.isOwner then
        g_inputBinding:setContext(PlaceableRollercoaster.INPUT_CONTEXT_ROLLERCOASTER, true)
        g_currentMission.hud:setIsControllingPlayer(false)
    end
    rollercoaster:enterRide(seatIndex, self.player)
    self.player:hide()
    local seat = self.rollercoaster.spec_rollercoaster.seats[seatIndex]
    if seat == nil then
        Logging.error("Player seat not defined for seat index \'%s\'!", self.seatIndex)
        return
    else
        local camera = seat.camera
        if camera == nil then
            Logging.error("No rollercoaster camera defined for seat \'%s\'!", self.seatIndex)
        else
            self.cameraNode = camera.cameraNode
        end
    end
end
function PlayerStateRollercoaster:onStateExited(_)
    if self.rollercoaster == nil then
        Logging.devInfo("PlayerStateRollercoaster.onStateExited: Failed to exit rollercoaster state. Player Controlled: %s - rollercoaster: %s", self.player:getIsControlled(), self.rollercoaster)
    else
        local spec = self.rollercoaster.spec_rollercoaster
        local x, y, z = getWorldTranslation(spec.exitPoints[(self.seatIndex - 1) % #spec.exitPoints + 1])
        self.player:teleportTo(x, y, z, true, true)
        self.rollercoaster = nil
        self.seatIndex = nil
        self.cameraNode = nil
    end
end
function PlayerStateRollercoaster:getIsInRollercoaster()
    return self.rollercoaster ~= nil
end
function PlayerStateRollercoaster:getCurrentVehicle()
    return nil
end
function PlayerStateRollercoaster:getCurrentRootNode()
    return self.cameraNode
end
function PlayerStateRollercoaster:getSpeed()
    return 0
end
function PlayerStateRollercoaster:getPosition()
    return getWorldTranslation(self.cameraNode)
end
function PlayerStateRollercoaster:getYaw()
    local cameraForwardX, _, cameraForwardZ = localDirectionToWorld(self.cameraNode, 0, 0, -1)
    return MathUtil.getYRotationFromDirection(cameraForwardX, cameraForwardZ)
end
function PlayerStateRollercoaster:getCurrentFacingDirection()
    local cameraForwardX, _, cameraForwardZ = localDirectionToWorld(self.cameraNode, 0, 0, -1)
    return cameraForwardX, cameraForwardZ
end
function PlayerStateRollercoaster:getCurrentCameraNode()
    return self.cameraNode
end