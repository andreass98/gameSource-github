UserEvent = {}
UserEvent.SEND_NUM_BITS = 5
local UserEvent_mt = Class(UserEvent, Event)
InitStaticEventClass(UserEvent, "UserEvent")
function UserEvent.emptyNew()
    -- upvalues: (copy) UserEvent_mt
    return Event.new(UserEvent_mt)
end
function UserEvent.new(addedUsers, removedUsers, capacity, disconnectReason)
    local self = UserEvent.emptyNew()
    self.addedUsers = addedUsers
    self.removedUsers = removedUsers
    self.capacity = capacity
    self.disconnectReason = disconnectReason or 1
    return self
end
function UserEvent:readStream(streamId, connection)
    local userId = User.streamReadUserId(streamId)
    g_currentMission.playerUserId = userId
    self.capacity = streamReadInt8(streamId)
    self.addedUsers = {}
    for _ = 1, streamReadUIntN(streamId, UserEvent.SEND_NUM_BITS) do
        local user = User.new()
        user:readStream(streamId, connection)
        table.insert(self.addedUsers, user)
    end
    self.removedUsers = {}
    for _ = 1, numUsers do
        local user = User.streamReadUserId(streamId)
        table.insert(self.removedUsers, user)
    end
    if numUsers > 0 then
        self.disconnectReason = DisconnectReason.readStream(streamId)
    end
    self:run(connection)
end
function UserEvent:writeStream(streamId, connection)
    local userId = g_currentMission.userManager:getUserIdByConnection(connection)
    User.streamWriteUserId(streamId, userId)
    streamWriteInt8(streamId, self.capacity)
    streamWriteUIntN(streamId, #self.addedUsers, UserEvent.SEND_NUM_BITS)
    for _, user in ipairs(self.addedUsers) do
        user:writeStream(streamId, connection)
    end
    streamWriteUIntN(streamId, #self.removedUsers, UserEvent.SEND_NUM_BITS)
    for _, user in ipairs(self.removedUsers) do
        User.streamWriteUserId(streamId, user:getId())
    end
    if numUsers > 0 then
        DisconnectReason.writeStream(streamId, self.disconnectReason)
    end
end
function UserEvent:run(_)
    g_currentMission.missionDynamicInfo.capacity = self.capacity
    for _, user in ipairs(self.addedUsers) do
        if g_currentMission.userManager:getUserByUniqueId(user:getUniqueUserId()) == nil then
            g_currentMission.userManager:addUser(user)
        end
    end
    for _, user in ipairs(self.removedUsers) do
        g_currentMission.userManager:removeUserById(user, self.disconnectReason)
    end
end