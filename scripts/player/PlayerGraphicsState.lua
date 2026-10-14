PlayerGraphicsState = {}
local PlayerGraphicsState_mt = Class(PlayerGraphicsState, HumanGraphicsComponentState)
function PlayerGraphicsState.new()
    -- upvalues: (copy) PlayerGraphicsState_mt
    return HumanGraphicsComponentState.new(PlayerGraphicsState_mt)
end
function PlayerGraphicsState:updateLocal(player)
    if player.stateMachine.states.onFoot == player.stateMachine.currentState then
        if player.isOwner and g_gui:getIsGuiVisible() then
            self:setDefault()
        else
            local mover = player.mover
            local speed = player:getGraphicalSpeed()
            local maxWalkingSpeed = PlayerStateWalk.MAXIMUM_WALK_SPEED + 0.5
            local graphicalVelocityX, graphicalVelocityY, graphicalVelocityZ = player:getGraphicalVelocity()
            self.movementDirX, self.movementDirZ = player.mover:getLocalMovementDirection(graphicalVelocityX, graphicalVelocityZ)
            self.absSpeed = speed
            self.relativeVelocityX = 0
            self.relativeVelocityY = graphicalVelocityY
            self.relativeVelocityZ = 0
            self.rotationVelocity = 0
            self.distanceToGround = mover.currentGroundDistance
            self.isCloseToGround = mover.isCloseToGround
            self.isIdling = speed < 0.1
            self.isWalking = speed >= 0.1 and speed < maxWalkingSpeed
            self.isRunning = maxWalkingSpeed <= speed
            self.isCrouching = mover.isCrouching
            self.isGrounded = mover.isGrounded and not mover.isSwimming
            self.isInWater = mover.isInWater
            self.isSwimming = mover.isSwimming
            self.isStrafeWalkMode = player.isStrafeWalkMode
            self.isFirstPerson = player.camera.isFirstPerson
            self.isHoldingChainsaw = player.isHoldingChainsaw
        end
    else
        return
    end
end
function PlayerGraphicsState:updateRemote(player)
    local mover = player.mover
    local speed = player:getGraphicalSpeed()
    local maxWalkingSpeed = PlayerStateWalk.MAXIMUM_WALK_SPEED + 2
    local graphicalVelocityX, graphicalVelocityY, graphicalVelocityZ = player:getGraphicalVelocity()
    smoothedSpeed, self.movementDirZ = player.mover:getLocalMovementDirection(graphicalVelocityX, graphicalVelocityZ)
    self.movementDirX = smoothedSpeed
    local smoothedSpeed = self.absSpeed * 0.8 + speed * 0.2
    self.absSpeed = smoothedSpeed
    self.relativeVelocityX = 0
    self.relativeVelocityY = graphicalVelocityY
    self.relativeVelocityZ = 0
    self.rotationVelocity = 0
    self.distanceToGround = mover.currentGroundDistance
    self.isCloseToGround = mover.isCloseToGround
    self.isIdling = smoothedSpeed < 0.1
    self.isWalking = smoothedSpeed >= 0.1 and smoothedSpeed < maxWalkingSpeed
    self.isRunning = maxWalkingSpeed <= smoothedSpeed
    self.isCrouching = mover.isCrouching
    self.isGrounded = mover.isGrounded and not mover.isSwimming
    self.isInWater = mover.isInWater
    self.isSwimming = mover.isSwimming
    self.isStrafeWalkMode = player.isStrafeWalkMode
    self.isFirstPerson = player.isFirstPerson
    self.isHoldingChainsaw = player.isHoldingChainsaw
    self.isCutting = player.isCutting
    self.isVerticalCut = player.isVerticalCut
end