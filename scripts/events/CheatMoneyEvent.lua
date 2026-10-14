CheatMoneyEvent = {}
local CheatMoneyEvent_mt = Class(CheatMoneyEvent, Event)
InitStaticEventClass(CheatMoneyEvent, "CheatMoneyEvent")
function CheatMoneyEvent.emptyNew()
    -- upvalues: (copy) CheatMoneyEvent_mt
    return Event.new(CheatMoneyEvent_mt)
end
function CheatMoneyEvent.new(amount, farmId)
    local self = CheatMoneyEvent.emptyNew()
    self.amount = amount
    self.farmId = farmId
    return self
end
function CheatMoneyEvent:readStream(streamId, connection)
    assert(g_currentMission:getIsServer())
    self.amount = streamReadInt32(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    if g_currentMission:getIsServer() and (not connection:getIsServer() and (g_currentMission.userManager:getIsConnectionMasterUser(connection) and self.farmId ~= FarmManager.SPECTATOR_FARM_ID)) then
        g_currentMission:addMoney(self.amount, self.farmId, MoneyType.OTHER)
    end
end
function CheatMoneyEvent:writeStream(streamId, _)
    streamWriteInt32(streamId, self.amount)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end
function CheatMoneyEvent:run(connection)
    printError("Error: CheatMoneyEvent is a client to server only event")
end