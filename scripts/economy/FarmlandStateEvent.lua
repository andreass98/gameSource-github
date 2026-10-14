FarmlandStateEvent = {}
local FarmlandStateEvent_mt = Class(FarmlandStateEvent, Event)
InitStaticEventClass(FarmlandStateEvent, "FarmlandStateEvent")
function FarmlandStateEvent.emptyNew()
    -- upvalues: (copy) FarmlandStateEvent_mt
    return Event.new(FarmlandStateEvent_mt)
end
function FarmlandStateEvent.new(id, farmId, price)
    local self = FarmlandStateEvent.emptyNew()
    self.id = id
    self.farmId = farmId
    self.price = price
    return self
end
function FarmlandStateEvent:readStream(streamId, connection)
    self.id = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.price = streamReadInt32(streamId)
    self:run(connection)
end
function FarmlandStateEvent:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.id, g_farmlandManager.numberOfBits)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteInt32(streamId, self.price)
end
function FarmlandStateEvent:run(connection)
    local farmland = g_farmlandManager:getFarmlandById(self.id)
    if farmland ~= nil then
        local currentOwner = g_farmlandManager:getFarmlandOwner(self.id)
        if connection:getIsServer() then
            g_farmlandManager:setLandOwnership(self.id, self.farmId)
            if currentOwner ~= FarmlandManager.NO_OWNER_FARM_ID then
                g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, currentOwner)
            end
            if self.farmId ~= FarmlandManager.NO_OWNER_FARM_ID then
                g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, self.farmId)
            end
        else
            if g_missionManager:getIsMissionRunningOnFarmland(farmland) then
                return
            end
            if self.farmId == FarmlandManager.NO_OWNER_FARM_ID or currentOwner == FarmlandManager.NO_OWNER_FARM_ID then
                local player = g_currentMission:getPlayerByConnection(connection)
                local farmAllowed = player ~= nil and g_currentMission:getHasPlayerPermission("farmManager", connection, player.farmId)
                if farmAllowed then
                    farmAllowed = true
                    if player.farmId ~= self.farmId then
                        farmAllowed = currentOwner == player.farmId
                    end
                end
                if player ~= nil and (player.farmId > 0 and farmAllowed) then
                    if self.price > 0 then
                        local farmId = player.farmId
                        local money = g_currentMission:getMoney(farmId)
                        if self.farmId == FarmlandManager.NO_OWNER_FARM_ID then
                            g_currentMission:addMoney(self.price, farmId, MoneyType.FIELD_SELL, true, true)
                        else
                            if money < self.price then
                                return
                            end
                            g_currentMission:addMoney(-self.price, farmId, MoneyType.FIELD_BUY, true, true)
                        end
                    end
                    g_server:broadcastEvent(self, true)
                    return
                end
            end
        end
    end
end