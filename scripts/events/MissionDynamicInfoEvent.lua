MissionDynamicInfoEvent = {}
local MissionDynamicInfoEvent_mt = Class(MissionDynamicInfoEvent, Event)
InitStaticEventClass(MissionDynamicInfoEvent, "MissionDynamicInfoEvent")
MissionDynamicInfoEvent.sendCapNumBits = 4
function MissionDynamicInfoEvent.emptyNew()
    -- upvalues: (copy) MissionDynamicInfoEvent_mt
    return Event.new(MissionDynamicInfoEvent_mt)
end
function MissionDynamicInfoEvent.new()
    return MissionDynamicInfoEvent.emptyNew()
end
function MissionDynamicInfoEvent.readStream(_, streamId, connection)
    local serverName = streamReadString(streamId)
    local autoAccept = streamReadBool(streamId)
    local password = streamReadString(streamId)
    local capacity = streamReadUIntN(streamId, MissionDynamicInfoEvent.sendCapNumBits) + 1
    local allowOnlyFriends = false
    if GS_IS_CONSOLE_VERSION then
        allowOnlyFriends = streamReadBool(streamId)
    end
    local allowCrossPlay = streamReadBool(streamId)
    g_currentMission:updateMissionDynamicInfo(serverName, capacity, password, autoAccept, allowOnlyFriends, allowCrossPlay)
    if not connection:getIsServer() then
        g_currentMission:updateMasterServerInfo(connection)
    end
end
function MissionDynamicInfoEvent.writeStream(_, streamId, _)
    streamWriteString(streamId, g_currentMission.missionDynamicInfo.serverName)
    streamWriteBool(streamId, g_currentMission.missionDynamicInfo.autoAccept)
    streamWriteString(streamId, g_currentMission.missionDynamicInfo.password)
    streamWriteUIntN(streamId, g_currentMission.missionDynamicInfo.capacity - 1, MissionDynamicInfoEvent.sendCapNumBits)
    if GS_IS_CONSOLE_VERSION then
        streamWriteBool(streamId, g_currentMission.missionDynamicInfo.allowOnlyFriends)
    end
    streamWriteBool(streamId, g_currentMission.missionDynamicInfo.allowCrossPlay)
end
function MissionDynamicInfoEvent:run(connection) end