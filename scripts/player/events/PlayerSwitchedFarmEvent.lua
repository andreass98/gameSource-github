PlayerSwitchedFarmEvent = {}
local PlayerSwitchedFarmEvent_mt = Class(PlayerSwitchedFarmEvent, Event)
InitStaticEventClass(PlayerSwitchedFarmEvent, "PlayerSwitchedFarmEvent")
PlayerSwitchedFarmEvent.NO_FARM = 126
function PlayerSwitchedFarmEvent.emptyNew()
    -- upvalues: (copy) PlayerSwitchedFarmEvent_mt
    return Event.new(PlayerSwitchedFarmEvent_mt)
end
function PlayerSwitchedFarmEvent.new(oldFarmId, farmId, userId)
    local self = PlayerSwitchedFarmEvent.emptyNew()
    self.farmId = farmId
    self.oldFarmId = oldFarmId
    self.userId = userId
    return self
end
function PlayerSwitchedFarmEvent:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteUIntN(streamId, self.oldFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    User.streamWriteUserId(streamId, self.userId)
end
function PlayerSwitchedFarmEvent:readStream(streamId, connection)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.oldFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.userId = User.streamReadUserId(streamId)
    self:run(connection)
end
function PlayerSwitchedFarmEvent:run(connection)
    if connection:getIsServer() then
        if self.oldFarmId ~= FarmManager.INVALID_FARM_ID then
            local oldFarm = g_farmManager:getFarmById(self.oldFarmId)
            if oldFarm ~= nil then
                oldFarm:removeUser(self.userId)
            end
        end
        if self.farmId ~= FarmManager.INVALID_FARM_ID then
            local oldFarm = g_farmManager:getFarmById(self.farmId)
            if oldFarm ~= nil then
                oldFarm:addUser(self.userId)
            end
        end
        local oldFarm = g_currentMission.playerSystem:getPlayerByUserId(self.userId)
        g_messageCenter:publish(MessageType.PLAYER_FARM_CHANGED, oldFarm)
    else
        g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(self.oldFarmId, self.farmId, self.userId), true)
    end
end