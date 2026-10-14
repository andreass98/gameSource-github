UserDataEvent = {}
UserDataEvent.SEND_NUM_BITS = 5
local UserDataEvent_mt = Class(UserDataEvent, Event)
InitStaticEventClass(UserDataEvent, "UserDataEvent")
function UserDataEvent.emptyNew()
    -- upvalues: (copy) UserDataEvent_mt
    return Event.new(UserDataEvent_mt)
end
function UserDataEvent.new(changedUsers)
    local self = UserDataEvent.emptyNew()
    self.changedUsers = changedUsers
    return self
end
function UserDataEvent:readStream(streamId, connection)
    self.changedUsers = {}
    local numUsers = streamReadUIntN(streamId, UserDataEvent.SEND_NUM_BITS)
    for _ = 1, numUsers do
        local userId = User.streamReadUserId(streamId)
        local user = g_currentMission.userManager:getUserByUserId(userId)
        if user == nil then
            Logging.error("UserDataEvent: Could not resolve user id \'%s\'", userId)
            return
        end
        user:readStream(streamId, connection)
        if user:getIsMasterUser() then
            g_currentMission.userManager:addMasterUser(user)
        end
    end
end
function UserDataEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, #self.changedUsers, UserDataEvent.SEND_NUM_BITS)
    for _, user in ipairs(self.changedUsers) do
        User.streamWriteUserId(streamId, user:getId())
        user:writeStream(streamId, connection)
    end
end