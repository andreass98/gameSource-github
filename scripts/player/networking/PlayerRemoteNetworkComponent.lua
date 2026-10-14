PlayerRemoteNetworkComponent = {}
local PlayerRemoteNetworkComponent_mt = Class(PlayerRemoteNetworkComponent, PlayerNetworkComponent)
function PlayerRemoteNetworkComponent.new(player)
    -- upvalues: (copy) PlayerRemoteNetworkComponent_mt
    local self = PlayerNetworkComponent.new(player, PlayerRemoteNetworkComponent_mt)
    self.player = player
    return self
end
function PlayerRemoteNetworkComponent:readUpdateStream(streamId, connection, timestamp)
    PlayerRemoteNetworkComponent:superClass().readUpdateStream(self, streamId, connection, timestamp)
    local isControlled = streamReadBool(streamId)
    local skipModel = streamReadBool(streamId)
    local skipMover = streamReadBool(streamId)
    self.player:updateControlledState(isControlled, skipModel, skipMover)
    local receivedPositionX = streamReadFloat32(streamId)
    local receivedPositionY = streamReadFloat32(streamId)
    local receivedPositionZ = streamReadFloat32(streamId)
    local receivedYaw = NetworkUtil.readCompressedAngle(streamId)
    local isGrounded = streamReadBool(streamId)
    local isFirstPerson = streamReadBool(streamId)
    local isCrouching = streamReadBool(streamId)
    local isVisible = streamReadBool(streamId)
    self.player.graphicsComponent:setGraphicsRootNodeVisibility(isVisible)
    local interpolator = self.player.positionalInterpolator
    interpolator:setTargetPosition(receivedPositionX, receivedPositionY, receivedPositionZ)
    interpolator:setTargetYaw(receivedYaw)
    interpolator:startNetworkNewPhase()
    self.player.mover.isGrounded = isGrounded
    self.player.mover:setIsCrouching(isCrouching)
    self.player.isFirstPerson = isFirstPerson
end