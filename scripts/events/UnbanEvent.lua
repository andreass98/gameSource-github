UnbanEvent = {}
local UnbanEvent_mt = Class(UnbanEvent, Event)
InitStaticEventClass(UnbanEvent, "UnbanEvent")
function UnbanEvent.emptyNew()
    -- upvalues: (copy) UnbanEvent_mt
    return Event.new(UnbanEvent_mt)
end
function UnbanEvent.new(uniqueUserId)
    local self = UnbanEvent.emptyNew()
    self.uniqueUserId = uniqueUserId
    return self
end
function UnbanEvent:readStream(streamId, connection)
    assert(g_currentMission:getIsServer(), "UnbanEvent is a client to server only event")
    self.uniqueUserId = streamReadString(streamId)
    self:run(connection)
end
function UnbanEvent:writeStream(streamId, _)
    streamWriteString(streamId, self.uniqueUserId)
end
function UnbanEvent:run(connection)
    if connection:getIsServer() then
        printError("Error: UnbanEvent is a client to server only event")
        return
    elseif g_currentMission.userManager:getIsConnectionMasterUser(connection) then
        local i = 0
        for i = i, getNumOfBlockedUsers() - 1 do
            local uniqueUserId, platformUserId, platformId, _ = getBlockedUser(i)
            if uniqueUserId == self.uniqueUserId then
                setIsUserBlocked(uniqueUserId, platformUserId, platformId, false, "")
                g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
                return
            end
        end
    else
        print("Connection is not a master user")
    end
end