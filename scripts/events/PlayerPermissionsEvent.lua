PlayerPermissionsEvent = {}
local PlayerPermissionsEvent_mt = Class(PlayerPermissionsEvent, Event)
InitStaticEventClass(PlayerPermissionsEvent, "PlayerPermissionsEvent")
function PlayerPermissionsEvent.emptyNew()
    -- upvalues: (copy) PlayerPermissionsEvent_mt
    return Event.new(PlayerPermissionsEvent_mt)
end
function PlayerPermissionsEvent.new(userId, permissions, isFarmManager)
    local self = PlayerPermissionsEvent.emptyNew()
    self.userId = userId
    self.permissions = permissions
    self.isFarmManager = isFarmManager
    return self
end
function PlayerPermissionsEvent:writeStream(streamId, _)
    User.streamWriteUserId(streamId, self.userId)
    for _, permission in ipairs(Farm.PERMISSIONS) do
        streamWriteBool(streamId, self.permissions[permission])
    end
    if streamWriteBool(streamId, self.isFarmManager ~= nil) then
        streamWriteBool(streamId, self.isFarmManager)
    end
end
function PlayerPermissionsEvent:readStream(streamId, connection)
    self.userId = User.streamReadUserId(streamId)
    self.permissions = {}
    for _, permission in ipairs(Farm.PERMISSIONS) do
        self.permissions[permission] = streamReadBool(streamId)
    end
    if streamReadBool(streamId) then
        self.isFarmManager = streamReadBool(streamId)
    end
    self:run(connection)
end
function PlayerPermissionsEvent:run(connection)
    if connection:getIsServer() then
        local farm = g_farmManager:getFarmByUserId(self.userId)
        local player = farm.userIdToPlayer[self.userId]
        if player == nil then
            Logging.devWarning("PlayerPermissionsEvent: Could not resolve user id \'%s\' (farm %d) to player data", self.userId, farm.farmId)
            return
        end
        player.permissions = self.permissions
        if self.isFarmManager ~= nil then
            player.isFarmManager = self.isFarmManager
        end
        g_messageCenter:publish(PlayerPermissionsEvent, self.userId)
    else
        local farm = g_farmManager:getFarmByUserId(self.userId)
        if g_currentMission:getHasPlayerPermission("manageRights", connection, farm.farmId) then
            local player = farm.userIdToPlayer[self.userId]
            if player == nil then
                Logging.devWarning("PlayerPermissionsEvent: Could not resolve user id \'%s\' (farm %d) to player data", self.userId, farm.farmId)
            else
                player.permissions = self.permissions
                if self.isFarmManager ~= nil then
                    player.isFarmManager = self.isFarmManager
                end
                g_server:broadcastEvent(self)
                g_messageCenter:publish(PlayerPermissionsEvent, self.userId)
            end
        end
    end
end
function PlayerPermissionsEvent.sendEvent(userId, permissions, isFarmManager, noEventSend)
    if noEventSend == nil or noEventSend == false then
        local event = PlayerPermissionsEvent.new(userId, permissions, isFarmManager)
        if g_server ~= nil then
            local player = g_farmManager:getFarmByUserId(userId).userIdToPlayer[userId]
            g_server:broadcastEvent(event, nil, nil, player)
            return
        end
        g_client:getServerConnection():sendEvent(event)
    end
end