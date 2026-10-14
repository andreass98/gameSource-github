GetBansEvent = {}
local GetBansEvent_mt = Class(GetBansEvent, Event)
InitStaticEventClass(GetBansEvent, "GetBansEvent")
function GetBansEvent.emptyNew()
    -- upvalues: (copy) GetBansEvent_mt
    return Event.new(GetBansEvent_mt)
end
function GetBansEvent.new(bans)
    local self = GetBansEvent.emptyNew()
    self.bans = bans or {}
    return self
end
function GetBansEvent:readStream(streamId, connection)
    local num = streamReadUInt16(streamId)
    self.bans = {}
    for _ = 1, num do
        local ban = {
            ["displayName"] = streamReadString(streamId),
            ["uniqueUserId"] = streamReadString(streamId)
        }
        table.insert(self.bans, ban)
    end
    self:run(connection)
end
function GetBansEvent:writeStream(streamId, _)
    streamWriteUInt16(streamId, #self.bans)
    for i, ban in ipairs(self.bans) do
        streamWriteString(streamId, ban.displayName)
        streamWriteString(streamId, ban.uniqueUserId)
    end
end
function GetBansEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(GetBansEvent, self.bans)
        return
    elseif g_currentMission.userManager:getIsConnectionMasterUser(connection) then
        local bans = {}
        local i = 0
        for i = i, getNumOfBlockedUsers() - 1 do
            local uniqueUserId, _platformUserId, _platformId, displayName = getBlockedUser(i)
            table.insert(bans, {
                ["uniqueUserId"] = uniqueUserId,
                ["displayName"] = displayName
            })
        end
        connection:sendEvent(GetBansEvent.new(bans))
    else
        print("Connection is not a master user")
    end
end