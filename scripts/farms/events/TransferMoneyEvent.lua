TransferMoneyEvent = {}
local TransferMoneyEvent_mt = Class(TransferMoneyEvent, Event)
InitStaticEventClass(TransferMoneyEvent, "TransferMoneyEvent")
function TransferMoneyEvent.emptyNew()
    -- upvalues: (copy) TransferMoneyEvent_mt
    return Event.new(TransferMoneyEvent_mt)
end
function TransferMoneyEvent.new(amount, destinationFarmId)
    local self = TransferMoneyEvent.emptyNew()
    self.amount = amount
    self.destinationFarmId = destinationFarmId
    return self
end
function TransferMoneyEvent:writeStream(streamId, _)
    streamWriteInt32(streamId, self.amount)
    streamWriteUIntN(streamId, self.destinationFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end
function TransferMoneyEvent:readStream(streamId, connection)
    self.amount = streamReadInt32(streamId)
    self.destinationFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self:run(connection)
end
function TransferMoneyEvent:run(connection)
    if connection:getIsServer() then
        printError("Error: TransferMoneyEvent is a client to server only event")
    else
        local senderUserId = g_currentMission.userManager:getUserIdByConnection(connection)
        local senderFarm = g_farmManager:getFarmByUserId(senderUserId)
        if g_currentMission:getHasPlayerPermission("transferMoney", connection, senderFarm.farmId) then
            if math.round(senderFarm.money) >= self.amount then
                g_currentMission:addMoney(-self.amount, senderFarm.farmId, MoneyType.TRANSFER, true, true)
                g_currentMission:addMoney(self.amount, self.destinationFarmId, MoneyType.TRANSFER, true, true)
                return
            end
        end
    end
end