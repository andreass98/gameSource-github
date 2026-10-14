ContractingStateEvent = {}
local ContractingStateEvent_mt = Class(ContractingStateEvent, Event)
InitStaticEventClass(ContractingStateEvent, "ContractingStateEvent")
function ContractingStateEvent.emptyNew()
    -- upvalues: (copy) ContractingStateEvent_mt
    return Event.new(ContractingStateEvent_mt)
end
function ContractingStateEvent.new(byFarmId, forFarmId, state)
    local self = ContractingStateEvent.emptyNew()
    self.byFarmId = byFarmId
    self.forFarmId = forFarmId
    self.state = state
    return self
end
function ContractingStateEvent:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.byFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteUIntN(streamId, self.forFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteBool(streamId, self.state)
end
function ContractingStateEvent:readStream(streamId, connection)
    self.byFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.forFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.state = streamReadBool(streamId)
    self:run(connection)
end
function ContractingStateEvent:run(connection)
    local byFarm = g_farmManager:getFarmById(self.byFarmId)
    if connection:getIsServer() then
        byFarm:setIsContractingFor(self.forFarmId, self.state, true)
        g_messageCenter:publish(ContractingStateEvent, byFarm.farmId, self.forFarmId, self.state)
    elseif g_currentMission:getHasPlayerPermission("manageContracting", connection, self.forFarmId) then
        byFarm:setIsContractingFor(self.forFarmId, self.state, true)
        g_server:broadcastEvent(self)
        return
    end
end