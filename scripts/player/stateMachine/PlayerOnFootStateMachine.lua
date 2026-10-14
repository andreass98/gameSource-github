PlayerOnFootStateMachine = {}
local PlayerOnFootStateMachine_mt = Class(PlayerOnFootStateMachine, StateMachine)
PlayerOnFootStateMachine:implementStateInterface()
function PlayerOnFootStateMachine.new(player)
    -- upvalues: (copy) PlayerOnFootStateMachine_mt
    local self = StateMachine.new(PlayerOnFootStateMachine_mt)
    self.player = player
    self.stateMachine = player.stateMachine
    self.states = {
        ["idle"] = PlayerStateIdle.new(player, self),
        ["walking"] = PlayerStateWalk.new(player, self),
        ["swimming"] = PlayerStateSwim.new(player, self),
        ["falling"] = PlayerStateFall.new(player, self),
        ["jumping"] = PlayerStateJump.new(player, self),
        ["crouching"] = PlayerStateCrouch.new(player, self)
    }
    self:initialiseStateTransitions()
    self.currentState = self.states.idle
    self.defaultState = self.states.idle
    self.canUseHandTools = true
    self.player:addStateEvent(PlayerOnFootStateMachine.onLeaveVehicle, self, "onLeaveVehicle")
    self.player:addStateEvent(PlayerOnFootStateMachine.onLeaveVehicle, self, "onLeaveVehicleAsPassenger")
    self.player:addStateEvent(PlayerOnFootStateMachine.onLeaveVehicle, self, "onLeaveRollercoaster")
    return self
end
function PlayerOnFootStateMachine:onLeaveVehicle()
    self.player.stateMachine:changeState(self)
end
function PlayerOnFootStateMachine:onStateEntered(_)
    self.player.networkComponent:reset()
    self.player.graphicsState:setDefault()
    self.player.graphicsComponent:applyState(self.player.graphicsState)
    self.player.mover:setSpeed(0)
    self.player.mover:resetHorizontalVelocity()
    if self.player.isServer then
        self.player:show()
    end
    if self.player.isOwner then
        local oldContext = g_inputBinding:getContextName()
        if oldContext ~= Vehicle.INPUT_CONTEXT_NAME then
            g_inputBinding:replaceContextInStack(Vehicle.INPUT_CONTEXT_NAME, PlayerInputComponent.INPUT_CONTEXT_NAME)
        end
        if oldContext == InputBinding.ROOT_CONTEXT_NAME or (oldContext == Vehicle.INPUT_CONTEXT_NAME or oldContext == PlaceableRollercoaster.INPUT_CONTEXT_ROLLERCOASTER) then
            self.player.inputComponent:makeCurrent()
        end
        local mission = g_currentMission
        mission.activatableObjectsSystem:activate(PlayerInputComponent.INPUT_CONTEXT_NAME)
        mission.hud:setIsControllingPlayer(true)
        self:determineState()
    end
end
function PlayerOnFootStateMachine:onStateExited(_)
    self.player.networkComponent:reset()
    self.player.graphicsState:setDefault()
    self.player.graphicsComponent:applyState(self.player.graphicsState)
    self.player.graphicsComponent:setModelPosition(self.player:getGraphicalPosition())
    if self.player.isOwner then
        self.player.mover:setSpeed(0)
        self.player.mover:resetHorizontalVelocity()
        self.player:setCurrentHandTool(nil, true)
        g_currentMission.activatableObjectsSystem:deactivate(PlayerInputComponent.INPUT_CONTEXT_NAME)
    end
end
function PlayerOnFootStateMachine:getIsInVehicle()
    return false
end
function PlayerOnFootStateMachine:getCurrentVehicle()
    return nil
end
function PlayerOnFootStateMachine:getCurrentRootNode()
    return self.player.rootNode
end
function PlayerOnFootStateMachine:getSpeed()
    return self.player.mover:getSpeed()
end
function PlayerOnFootStateMachine:getMaximumSpeed()
    return self.currentState.calculateMaximumSpeed == nil and 0 or self.currentState:calculateMaximumSpeed()
end
function PlayerOnFootStateMachine:getPosition()
    return self.player.mover:getPosition()
end
function PlayerOnFootStateMachine:getYaw()
    return self.player.mover:getMovementYaw()
end
function PlayerOnFootStateMachine:getCurrentFacingDirection()
    return MathUtil.getDirectionFromYRotation(self:getYaw())
end
function PlayerOnFootStateMachine:getCurrentCameraNode()
    return self.player.camera and self.player.camera:getCurrentCameraNode()
end
function PlayerOnFootStateMachine:updateAsCurrent(dt)
    if self.player.inputComponent ~= nil then
        self.player.inputComponent:update(dt)
    end
    if self.player.targeter ~= nil then
        self.player.targeter:update(dt)
    end
    if self.player.networkComponent ~= nil then
        self.player.networkComponent:preUpdate(dt)
    end
    if self.player.camera ~= nil then
        self.player.camera:updateRotation(dt)
    end
    self.player.capsuleController:update(dt)
    self:update(dt)
    if self.player.inputComponent ~= nil and self.currentState.calculateDesiredHorizontalVelocity then
        local movementX, movementZ = self.currentState:calculateDesiredHorizontalVelocity(self.player.inputComponent.worldDirectionX, self.player.inputComponent.worldDirectionZ)
        self.player.mover:moveHorizontally(movementX, movementZ)
    end
    self.player.mover:update(dt)
    if self.player.camera ~= nil then
        self.player.camera:setOffsetY(self.currentState.cameraOffsetY)
    end
    if self.player.positionalInterpolator ~= nil then
        self.player.positionalInterpolator:update(dt)
    end
    if self.player.isOwner then
        self.player.graphicsState:updateLocal(self.player)
    else
        self.player.graphicsState:updateRemote(self.player)
    end
    self.player.graphicsComponent:applyState(self.player.graphicsState)
    self.player.graphicsComponent:setModelYaw(self.player:getGraphicalYaw())
    self.player.graphicsComponent:setModelPosition(self.player:getGraphicalPosition())
    self.player.graphicsComponent:update(dt)
    if self.player.camera ~= nil then
        self.player.camera:updatePosition(dt)
    end
    if self.player.isOwner then
        local movementX, movementZ, z = self.player:getPosition()
        local dirX, dirZ = self.player:getCurrentFacingDirection()
        local activatableObjectsSystem = g_currentMission.activatableObjectsSystem
        activatableObjectsSystem:setPosition(movementX, movementZ, z)
        activatableObjectsSystem:setDirection(dirX, 0, dirZ)
    end
    if self.player.inputComponent ~= nil then
        self.player.inputComponent:resetState()
    end
    if self.player.networkComponent ~= nil then
        self.player.networkComponent:update(dt)
    end
end
function PlayerOnFootStateMachine:updateTick(dt)
    if self.player.networkComponent then
        self.player.networkComponent:updateTick(dt)
    end
    if self.player.positionalInterpolator ~= nil then
        self.player.positionalInterpolator:updateTick(dt)
    end
end
function PlayerOnFootStateMachine:updateWhileInConversation(_, npc)
    local focusNode = npc.playerGraphics.model.thirdPersonHeadNode
    if npc.playerGraphics.facialAnimation ~= nil then
        focusNode = npc.playerGraphics.facialAnimation.headFocusNode
    end
    if focusNode ~= nil then
        self.player.graphicsComponent:pointRightShoulderCameraNodeAt(focusNode)
    end
    local playerPositionX, _, playerPositionZ = self.player:getPosition()
    local npcPositionX, _, npcPositionZ = npc:getPosition()
    local playerNPCDirectionX, _, playerNPCDirectionZ = MathUtil.vector3Normalize(npcPositionX - playerPositionX, 0, npcPositionZ - playerPositionZ)
    local targetYaw = MathUtil.getYRotationFromDirection(playerNPCDirectionX, playerNPCDirectionZ)
    self.player.mover:setMovementYaw(targetYaw)
    self.player.graphicsComponent:defaultAllParameters()
    self.player.graphicsComponent:setModelYaw(self.player:getGraphicalYaw())
    self.player.graphicsComponent:setModelPosition(self.player:getGraphicalPosition())
    if self.player.camera ~= nil then
        self.player.camera:setTargetOverrideFromNode(self.player.graphicsComponent.rightShoulderCameraNode)
    end
end