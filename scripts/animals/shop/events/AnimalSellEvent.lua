AnimalSellEvent = {}
AnimalSellEvent.SELL_SUCCESS = 0
AnimalSellEvent.SELL_ERROR_NO_PERMISSION = 1
AnimalSellEvent.SELL_ERROR_INVALID_CLUSTER = 2
AnimalSellEvent.SELL_ERROR_NOT_ENOUGH_ANIMALS = 3
AnimalSellEvent.SELL_ERROR_CANNOT_BE_SOLD = 4
AnimalSellEvent.SELL_ERROR_OBJECT_DOES_NOT_EXIST = 5
local AnimalSellEvent_mt = Class(AnimalSellEvent, Event)
InitStaticEventClass(AnimalSellEvent, "AnimalSellEvent")
function AnimalSellEvent.emptyNew()
    -- upvalues: (copy) AnimalSellEvent_mt
    return Event.new(AnimalSellEvent_mt)
end
function AnimalSellEvent.new(object, clusterId, numAnimals, sellPrice, feePrice)
    local self = AnimalSellEvent.emptyNew()
    self.object = object
    self.clusterId = clusterId
    self.numAnimals = numAnimals
    self.sellPrice = sellPrice
    self.feePrice = feePrice
    return self
end
function AnimalSellEvent.newServerToClient(errorCode)
    local self = AnimalSellEvent.emptyNew()
    self.errorCode = errorCode
    return self
end
function AnimalSellEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, 3)
    else
        self.object = NetworkUtil.readNodeObject(streamId)
        self.clusterId = streamReadInt32(streamId)
        self.numAnimals = streamReadUInt8(streamId)
        self.sellPrice = streamReadInt32(streamId)
        self.feePrice = -streamReadInt32(streamId)
    end
    self:run(connection)
end
function AnimalSellEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.object)
        streamWriteInt32(streamId, self.clusterId)
        streamWriteUInt8(streamId, self.numAnimals)
        streamWriteInt32(streamId, (math.abs(self.sellPrice)))
        streamWriteInt32(streamId, (math.abs(self.feePrice)))
    else
        streamWriteUIntN(streamId, self.errorCode, 3)
    end
end
function AnimalSellEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(AnimalSellEvent, self.errorCode)
        return
    elseif g_currentMission:getHasPlayerPermission("tradeAnimals", connection) then
        local errorCode = AnimalSellEvent.validate(self.object, self.clusterId, self.numAnimals, self.sellPrice, self.feePrice)
        if errorCode == nil then
            local cluster = self.object:getClusterById(self.clusterId)
            local clusterSystem = self.object:getClusterSystem()
            cluster:changeNumAnimals(-self.numAnimals)
            clusterSystem:updateNow()
            local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
            local farm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
            g_currentMission:addMoney(self.sellPrice + self.feePrice, farm.farmId, MoneyType.SOLD_ANIMALS, true, true)
            connection:sendEvent(AnimalSellEvent.newServerToClient(AnimalSellEvent.SELL_SUCCESS))
        else
            connection:sendEvent(AnimalSellEvent.newServerToClient(errorCode))
        end
    else
        connection:sendEvent(AnimalSellEvent.newServerToClient(AnimalSellEvent.SELL_ERROR_NO_PERMISSION))
        return
    end
end
function AnimalSellEvent.validate(object, clusterId, numAnimals, _, _)
    if object == nil then
        return AnimalSellEvent.SELL_ERROR_OBJECT_DOES_NOT_EXIST
    else
        local cluster = object:getClusterById(clusterId)
        if cluster == nil then
            return AnimalSellEvent.SELL_ERROR_INVALID_CLUSTER
        elseif cluster:getNumAnimals() < numAnimals then
            return AnimalSellEvent.SELL_ERROR_NOT_ENOUGH_ANIMALS
        elseif cluster:getCanBeSold() then
            return nil
        else
            return AnimalSellEvent.SELL_ERROR_CANNOT_BE_SOLD
        end
    end
end