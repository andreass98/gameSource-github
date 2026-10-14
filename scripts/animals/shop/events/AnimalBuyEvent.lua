AnimalBuyEvent = {}
AnimalBuyEvent.BUY_SUCCESS = 0
AnimalBuyEvent.BUY_ERROR_NO_PERMISSION = 1
AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY = 2
AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_SPACE = 3
AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED = 4
AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED = 5
AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST = 6
AnimalBuyEvent.BUY_ERROR_NO_BARN_AVAILABLE = 7
local AnimalBuyEvent_mt = Class(AnimalBuyEvent, Event)
InitStaticEventClass(AnimalBuyEvent, "AnimalBuyEvent")
function AnimalBuyEvent.emptyNew()
    -- upvalues: (copy) AnimalBuyEvent_mt
    return Event.new(AnimalBuyEvent_mt)
end
function AnimalBuyEvent.new(object, subTypeIndex, age, numAnimals, buyPrice, feePrice)
    local self = AnimalBuyEvent.emptyNew()
    self.object = object
    self.subTypeIndex = subTypeIndex
    self.age = age
    self.numAnimals = numAnimals
    self.buyPrice = buyPrice
    self.feePrice = feePrice
    return self
end
function AnimalBuyEvent.newServerToClient(errorCode)
    local self = AnimalBuyEvent.emptyNew()
    self.errorCode = errorCode
    return self
end
function AnimalBuyEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, 3)
    else
        self.object = NetworkUtil.readNodeObject(streamId)
        self.subTypeIndex = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_SUB_TYPE)
        self.age = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_AGE)
        self.numAnimals = streamReadUInt8(streamId)
        self.buyPrice = -streamReadInt32(streamId)
        self.feePrice = -streamReadInt32(streamId)
    end
    self:run(connection)
end
function AnimalBuyEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.object)
        streamWriteUIntN(streamId, self.subTypeIndex, AnimalCluster.NUM_BITS_SUB_TYPE)
        streamWriteUIntN(streamId, self.age, AnimalCluster.NUM_BITS_AGE)
        streamWriteUInt8(streamId, self.numAnimals)
        streamWriteInt32(streamId, (math.abs(self.buyPrice)))
        streamWriteInt32(streamId, (math.abs(self.feePrice)))
    else
        streamWriteUIntN(streamId, self.errorCode, 3)
    end
end
function AnimalBuyEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(AnimalBuyEvent, self.errorCode)
        return
    elseif g_currentMission:getHasPlayerPermission("tradeAnimals", connection) then
        local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
        local farm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
        local errorCode = AnimalBuyEvent.validate(self.object, self.subTypeIndex, self.age, self.numAnimals, self.buyPrice, self.feePrice, farm.farmId)
        if errorCode == nil then
            self.object:addAnimals(self.subTypeIndex, self.numAnimals, self.age)
            g_currentMission:addMoney(self.buyPrice + self.feePrice, farm.farmId, MoneyType.NEW_ANIMALS_COST, true, true)
            connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_SUCCESS))
        else
            connection:sendEvent(AnimalBuyEvent.newServerToClient(errorCode))
        end
    else
        connection:sendEvent(AnimalBuyEvent.newServerToClient(AnimalBuyEvent.BUY_ERROR_NO_PERMISSION))
        return
    end
end
function AnimalBuyEvent.validate(object, subTypeIndex, _, numAnimals, buyPrice, feePrice, farmId)
    if object == nil then
        return AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST
    elseif object:getSupportsAnimalSubType(subTypeIndex) then
        if object:getNumOfFreeAnimalSlots(subTypeIndex) < numAnimals then
            return AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_SPACE
        else
            local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(subTypeIndex)
            if #g_currentMission.husbandrySystem:getPlaceablesByFarm(farmId, animalTypeIndex) == 0 then
                return AnimalBuyEvent.BUY_ERROR_NO_BARN_AVAILABLE
            elseif g_currentMission.husbandrySystem:getNumOfFreeAnimalSlots(farmId, subTypeIndex) < numAnimals then
                return AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED
            elseif g_currentMission:getMoney(farmId) + (buyPrice + feePrice) < 0 then
                return AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY
            else
                return nil
            end
        end
    else
        return AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED
    end
end