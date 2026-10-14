MissionStartEvent = {}
local MissionStartEvent_mt = Class(MissionStartEvent, Event)
InitStaticEventClass(MissionStartEvent, "MissionStartEvent")
function MissionStartEvent.emptyNew()
    -- upvalues: (copy) MissionStartEvent_mt
    return Event.new(MissionStartEvent_mt)
end
function MissionStartEvent.new(mission, farmId, spawnVehicles)
    local self = MissionStartEvent.emptyNew()
    self.mission = mission
    self.farmId = farmId
    self.spawnVehicles = spawnVehicles or false
    return self
end
function MissionStartEvent.newServerToClient(startState, spawnVehicles)
    local self = MissionStartEvent.emptyNew()
    self.startState = startState
    self.spawnVehicles = spawnVehicles or false
    return self
end
function MissionStartEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.mission)
        streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
        streamWriteBool(streamId, self.spawnVehicles)
    else
        MissionStartState.writeStream(streamId, self.startState)
        streamWriteBool(streamId, self.spawnVehicles)
    end
end
function MissionStartEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.startState = MissionStartState.readStream(streamId)
        self.spawnVehicles = streamReadBool(streamId)
    else
        self.mission = NetworkUtil.readNodeObject(streamId)
        self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
        self.spawnVehicles = streamReadBool(streamId)
    end
    self:run(connection)
end
function MissionStartEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(MissionStartEvent, self.startState, self.spawnVehicles)
        return
    else
        local mission = g_currentMission
        local senderUserId = mission.userManager:getUserIdByConnection(connection)
        if mission:getHasPlayerPermission("manageContracts", connection, g_farmManager:getFarmByUserId(senderUserId).farmId) then
            local startState = g_missionManager:startMission(self.mission, self.farmId, self.spawnVehicles)
            connection:sendEvent(MissionStartEvent.newServerToClient(startState, self.spawnVehicles))
        else
            connection:sendEvent(MissionStartEvent.newServerToClient(MissionStartState.NO_PERMISSION, self.spawnVehicles))
        end
    end
end