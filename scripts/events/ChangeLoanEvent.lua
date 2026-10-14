ChangeLoanEvent = {}
local ChangeLoanEvent_mt = Class(ChangeLoanEvent, Event)
InitStaticEventClass(ChangeLoanEvent, "ChangeLoanEvent")
function ChangeLoanEvent.emptyNew()
    -- upvalues: (copy) ChangeLoanEvent_mt
    return Event.new(ChangeLoanEvent_mt)
end
function ChangeLoanEvent.new(loanValue, farmId)
    local self = ChangeLoanEvent.emptyNew()
    self.loanValue = loanValue
    self.farmId = farmId
    return self
end
function ChangeLoanEvent:readStream(streamId, connection)
    self.loanValue = streamReadFloat32(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self:run(connection)
end
function ChangeLoanEvent:writeStream(streamId, _)
    streamWriteFloat32(streamId, self.loanValue)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end
function ChangeLoanEvent:run(connection)
    if connection:getIsServer() then
        local farm = g_farmManager:getFarmById(self.farmId)
        if farm ~= nil then
            farm.loan = self.loanValue
        end
        g_messageCenter:publish(ChangeLoanEvent)
    elseif self.farmId ~= 0 and g_currentMission:getHasPlayerPermission("farmManager", connection, self.farmId) then
        local farm = g_farmManager:getFarmById(self.farmId)
        local curLoan = farm.loan
        local maxLoan = math.max(farm.loanMax, curLoan)
        farm.loan = math.clamp(curLoan + self.loanValue, 0, maxLoan)
        farm:changeBalance(farm.loan - curLoan)
        g_server:broadcastEvent(ChangeLoanEvent.new(farm.loan, farm.farmId), false, nil)
        g_messageCenter:publish(ChangeLoanEvent)
        return
    end
end