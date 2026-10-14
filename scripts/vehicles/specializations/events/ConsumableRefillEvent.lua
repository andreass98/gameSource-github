ConsumableRefillEvent = {}
local ConsumableRefillEvent_mt = Class(ConsumableRefillEvent, Event)
InitStaticEventClass(ConsumableRefillEvent, "ConsumableRefillEvent")
function ConsumableRefillEvent.emptyNew()
    -- upvalues: (copy) ConsumableRefillEvent_mt
    return Event.new(ConsumableRefillEvent_mt)
end
function ConsumableRefillEvent.new(object, typeIndex, variationIndex)
    local self = ConsumableRefillEvent.emptyNew()
    self.object = object
    self.typeIndex = typeIndex
    self.variationIndex = variationIndex
    return self
end
function ConsumableRefillEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.typeIndex = streamReadUInt8(streamId)
    self.variationIndex = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)
    if not connection:getIsServer() then
        self:run(connection)
    end
end
function ConsumableRefillEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUInt8(streamId, self.typeIndex)
    streamWriteUIntN(streamId, self.variationIndex, ConsumableManager.NUM_VARIATION_BITS)
end
function ConsumableRefillEvent:run(_)
    if self.object ~= nil then
        local type = self.object.spec_consumable.types[self.typeIndex]
        type.consumingVariationIndex = self.variationIndex
        local delta = self.object:addFillUnitFillLevel(self.object:getOwnerFarmId(), type.fillUnitIndex, type.numStorageSlots, self.object:getFillUnitFirstSupportedFillType(type.fillUnitIndex), ToolType.UNDEFINED, nil)
        self.object:updateConsumable(type.typeName, 0)
        local delta = delta + self.object:addFillUnitFillLevel(self.object:getOwnerFarmId(), type.fillUnitIndex, type.numConsumingSlots, self.object:getFillUnitFirstSupportedFillType(type.fillUnitIndex), ToolType.UNDEFINED, nil)
        self.object:updateConsumable(type.typeName, 0)
        local price = g_consumableManager:getConsumableVariationPriceByIndex(self.variationIndex) * delta
        if price > 0 then
            g_farmManager:updateFarmStats(self.object:getActiveFarm(), "expenses", price)
            g_currentMission:addMoney(-price, self.object:getActiveFarm(), MoneyType.PURCHASE_CONSUMABLES, true)
            g_currentMission:showMoneyChange(MoneyType.PURCHASE_CONSUMABLES, nil, false, self.object:getActiveFarm())
        end
    end
end
function ConsumableRefillEvent.sendEvent(vehicle, typeIndex, variationIndex)
    if g_server == nil then
        g_client:getServerConnection():sendEvent(ConsumableRefillEvent.new(vehicle, typeIndex, variationIndex))
    else
        g_server:broadcastEvent(ConsumableRefillEvent.new(vehicle, typeIndex, variationIndex), true, nil, vehicle)
    end
end