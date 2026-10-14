MissionCancelEvent = {}
local MissionCancelEvent_mt = Class(MissionCancelEvent, Event)
InitStaticEventClass(MissionCancelEvent, "MissionCancelEvent")
function MissionCancelEvent.emptyNew()
    -- upvalues: (copy) MissionCancelEvent_mt
    return Event.new(MissionCancelEvent_mt)
end
function MissionCancelEvent.new(mission)
    local self = MissionCancelEvent.emptyNew()
    self.mission = mission
    return self
end
function MissionCancelEvent.newServerToClient(success)
    local self = MissionCancelEvent.emptyNew()
    self.success = success
    return self
end
function MissionCancelEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.mission)
    else
        streamWriteBool(streamId, self.success)
    end
end
function MissionCancelEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.success = streamReadBool(streamId)
    else
        self.mission = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function MissionCancelEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(MissionCancelEvent, self.success)
        return
    else
        local mission = self.mission
        if mission == nil then
            connection:sendEvent(MissionCancelEvent.newServerToClient(false))
        else
            local currentMission = g_currentMission
            local userManager = currentMission.userManager
            local senderUserId = userManager:getUserIdByConnection(connection)
            local senderFarm = g_farmManager:getFarmByUserId(senderUserId)
            local isMasterUser = connection:getIsLocal() or userManager:getIsConnectionMasterUser(connection)
            local success = false
            if currentMission:getHasPlayerPermission("manageContracts", connection, senderFarm.farmId) and (mission.farmId == senderFarm.farmId or isMasterUser) then
                success = g_missionManager:cancelMission(mission)
            end
            connection:sendEvent(MissionCancelEvent.newServerToClient(success))
        end
    end
end