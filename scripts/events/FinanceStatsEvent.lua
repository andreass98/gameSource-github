FinanceStatsEvent = {}
local FinanceStatsEvent_mt = Class(FinanceStatsEvent, Event)
InitStaticEventClass(FinanceStatsEvent, "FinanceStatsEvent")
function FinanceStatsEvent.emptyNew()
    -- upvalues: (copy) FinanceStatsEvent_mt
    return Event.new(FinanceStatsEvent_mt)
end
function FinanceStatsEvent.new(historyIndex, farmId)
    local self = FinanceStatsEvent.emptyNew()
    self.historyIndex = historyIndex
    self.farmId = farmId
    assert(historyIndex >= 0 and historyIndex <= 255)
    return self
end
function FinanceStatsEvent:readStream(streamId, connection)
    self.historyIndex = streamReadUInt8(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            local financesHistoryVersionCounter = streamReadUIntN(streamId, 7)
            if streamReadBool(streamId) then
                for _, statName in ipairs(FinanceStats.statNames) do
                    ({})[statName] = streamReadFloat32(streamId)
                end
            end
            local farm = g_farmManager:getFarmById(self.farmId)
            if farm ~= nil then
                local stats = farm.stats
                stats.financesHistoryVersionCounter = financesHistoryVersionCounter
                local finances
                if self.historyIndex == 0 then
                    finances = stats.finances
                else
                    local _ = #stats.financesHistory
                    if _ < self.historyIndex then
                        for _ = 1, self.historyIndex - _ do
                            table.insert(stats.financesHistory, 1, FinanceStats.new())
                        end
                    end
                    finances = stats.financesHistory[_ - self.historyIndex + 1]
                end
                for _, money in pairs(readData) do
                    finances[_] = money
                end
                return
            end
        end
    else
        connection:sendEvent(self)
    end
end
function FinanceStatsEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.historyIndex)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    if not connection:getIsServer() then
        local farm = g_farmManager:getFarmById(self.farmId)
        local stats = streamWriteBool
        local finances = farm ~= nil
        if stats(streamId, finances) then
            local stats = farm.stats
            streamWriteUIntN(streamId, stats.financesHistoryVersionCounter, 7)
            local finances = nil
            if self.historyIndex == 0 then
                finances = stats.finances
            else
                local numHistoryEntries = #stats.financesHistory
                if self.historyIndex <= numHistoryEntries then
                    finances = stats.financesHistory[numHistoryEntries - self.historyIndex + 1]
                end
            end
            local numHistoryEntries = streamWriteBool
            if numHistoryEntries(streamId, finances ~= nil and self.farmId ~= FarmManager.SPECTATOR_FARM_ID) then
                for _, statName in ipairs(FinanceStats.statNames) do
                    local money = Utils.getNoNil(finances[statName], 0)
                    streamWriteFloat32(streamId, money)
                end
            end
        end
    end
end
function FinanceStatsEvent:run(connection)
    printError("Error: FinanceStatsEvent is not allowed to be executed on a local client")
end