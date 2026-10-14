PlayerNetworkComponent = {}
function PlayerNetworkComponent.new(player, custom_mt)
    local self = setmetatable({}, custom_mt)
    self.player = player
    return self
end
function PlayerNetworkComponent:reset() end
function PlayerNetworkComponent:preUpdate(dt) end
function PlayerNetworkComponent:update(dt) end
function PlayerNetworkComponent:updateTick(dt) end
function PlayerNetworkComponent:writeUpdateStream(streamId, connection, dirtyMask) end
function PlayerNetworkComponent:readUpdateStream(streamId, connection, timestamp) end
function PlayerNetworkComponent.debugDraw(_, _, y, _)
    return y
end