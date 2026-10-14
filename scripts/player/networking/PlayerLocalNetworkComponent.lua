PlayerLocalNetworkComponent = {}
local PlayerLocalNetworkComponent_mt = Class(PlayerLocalNetworkComponent, PlayerNetworkComponent)
PlayerLocalNetworkComponent.NETWORK_HISTORY_MAX_LENGTH = 100
function PlayerLocalNetworkComponent.new(player)
    -- upvalues: (copy) PlayerLocalNetworkComponent_mt
    local self = PlayerNetworkComponent.new(player, PlayerLocalNetworkComponent_mt)
    self.player = player
    self.tickHistory = {}
    self.currentTickIndex = 0
    self.movementX = 0
    self.movementY = 0
    self.movementZ = 0
    self.movementYaw = 0
    return self
end
function PlayerLocalNetworkComponent:reset()
    if self.tickHistory ~= nil then
        table.clear(self.tickHistory)
    end
end
function PlayerLocalNetworkComponent:update(_)
    if self.needNewTick then
        self.currentTickIndex = self.currentTickIndex + 1
        while #self.tickHistory > PlayerLocalNetworkComponent.NETWORK_HISTORY_MAX_LENGTH do
            table.remove(self.tickHistory, 1)
        end
        table.insert(self.tickHistory, {
            ["tickIndex"] = self.currentTickIndex,
            ["movementX"] = 0,
            ["movementY"] = 0,
            ["movementZ"] = 0
        })
        self.needNewTick = false
    end
    self.movementX = self.movementX + self.player.mover.positionDeltaX
    self.movementY = self.movementY + self.player.mover.positionDeltaY
    self.movementZ = self.movementZ + self.player.mover.positionDeltaZ
    self.movementYaw = self.player.mover:getMovementYaw()
    local history = self.tickHistory[#self.tickHistory]
    if history ~= nil then
        history.movementX = history.movementX + self.player.mover.positionDeltaX
        history.movementY = history.movementY + self.player.mover.positionDeltaY
        history.movementZ = history.movementZ + self.player.mover.positionDeltaZ
    end
end
function PlayerLocalNetworkComponent:updateTick(_)
    self.needNewTick = true
end
function PlayerLocalNetworkComponent:writeUpdateStream(streamId, connection, dirtyMask)
    PlayerLocalNetworkComponent:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    streamWriteUInt32(streamId, self.currentTickIndex)
    streamWriteFloat32(streamId, self.movementX)
    streamWriteFloat32(streamId, self.movementY)
    streamWriteFloat32(streamId, self.movementZ)
    NetworkUtil.writeCompressedAngle(streamId, self.movementYaw)
    streamWriteBool(streamId, self.player.camera.isFirstPerson)
    streamWriteBool(streamId, self.player.mover.isCrouching)
    self.movementX = 0
    self.movementY = 0
    self.movementZ = 0
    self.movementYaw = 0
end
function PlayerLocalNetworkComponent:readUpdateStream(streamId, connection, timestamp)
    PlayerLocalNetworkComponent:superClass().readUpdateStream(self, streamId, connection, timestamp)
    local tickIndex = streamReadUInt32(streamId)
    local isControlled = streamReadBool(streamId)
    local skipModel = streamReadBool(streamId)
    local skipMover = streamReadBool(streamId)
    self.player:updateControlledState(isControlled, skipModel, skipMover)
    local receivedPositionX = streamReadFloat32(streamId)
    local receivedPositionY = streamReadFloat32(streamId)
    local receivedPositionZ = streamReadFloat32(streamId)
    self.player.mover:setPosition(receivedPositionX, receivedPositionY, receivedPositionZ)
    local historyToDelete = self.tickHistory[1]
    while historyToDelete ~= nil and historyToDelete.tickIndex <= tickIndex do
        table.remove(self.tickHistory, 1)
        historyToDelete = self.tickHistory[1]
    end
    local totalMovementX = #self.tickHistory / 5
    local numAggregationTicks = math.ceil(totalMovementX)
    local totalMovementX = nil
    local totalMovementY = nil
    local totalMovementZ = nil
    local numSteps = 0
    for _, history in ipairs(self.tickHistory) do
        if totalMovementX == nil then
            totalMovementX = 0
            totalMovementY = 0
            totalMovementZ = 0
        end
        totalMovementX = totalMovementX + history.movementX
        totalMovementY = totalMovementY + history.movementY
        totalMovementZ = totalMovementZ + history.movementZ
        numSteps = numSteps + 1
        if numAggregationTicks <= numSteps then
            self.player.capsuleController:move(totalMovementX, totalMovementY, totalMovementZ)
            numSteps = 0
        end
    end
    if numSteps > 0 then
        self.player.capsuleController:move(totalMovementX, totalMovementY, totalMovementZ)
    end
end