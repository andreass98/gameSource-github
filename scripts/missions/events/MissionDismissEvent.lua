MissionDismissEvent = {}
local MissionDismissEvent_mt = Class(MissionDismissEvent, Event)
InitStaticEventClass(MissionDismissEvent, "MissionDismissEvent")
function MissionDismissEvent.emptyNew()
    -- upvalues: (copy) MissionDismissEvent_mt
    return Event.new(MissionDismissEvent_mt)
end
function MissionDismissEvent.new(mission)
    local self = MissionDismissEvent.emptyNew()
    self.mission = mission
    return self
end
function MissionDismissEvent.newServerToClient(missionObjectId, success)
    local self = MissionDismissEvent.emptyNew()
    self.missionObjectId = missionObjectId
    self.success = success
    return self
end
function MissionDismissEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.mission)
    else
        NetworkUtil.writeNodeObjectId(streamId, self.missionObjectId)
        streamWriteBool(streamId, self.success)
    end
end
function MissionDismissEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.missionObjectId = NetworkUtil.readNodeObjectId(streamId)
        self.success = streamReadBool(streamId)
    else
        self.mission = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function MissionDismissEvent:run(connection)
    if connection:getIsServer() then
        local mission = NetworkUtil.getObject(self.missionObjectId)
        if mission ~= nil then
            g_missionManager:removeMission(mission)
        end
        g_messageCenter:publish(MissionDismissEvent, self.success)
        return
    else
        local mission = self.mission
        if mission ~= nil then
            local currentMission = g_currentMission
            local userManager = currentMission.userManager
            local senderUserId = userManager:getUserIdByConnection(connection)
            local senderFarm = g_farmManager:getFarmByUserId(senderUserId)
            local isMasterUser = connection:getIsLocal() or userManager:getIsConnectionMasterUser(connection)
            local missionObjectId = NetworkUtil.getObjectId(mission)
            local success = false
            if currentMission:getHasPlayerPermission("manageContracts", connection, senderFarm.farmId) and (self.mission.farmId == senderFarm.farmId or isMasterUser) then
                success = g_missionManager:dismissMission(self.mission)
            end
            connection:sendEvent(MissionDismissEvent.newServerToClient(missionObjectId, success))
        end
    end
end