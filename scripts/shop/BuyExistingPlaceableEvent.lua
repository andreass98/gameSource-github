BuyExistingPlaceableEvent = {}
local BuyExistingPlaceableEvent_mt = Class(BuyExistingPlaceableEvent, Event)
BuyExistingPlaceableEvent.STATE_SUCCESS = 0
BuyExistingPlaceableEvent.STATE_NO_PERMISSION = 1
BuyExistingPlaceableEvent.STATE_NOT_ENOUGH_MONEY = 2
BuyExistingPlaceableEvent.STATE_NUM_BITS = 2
BuyExistingPlaceableEvent.DIALOG_MESSAGES = {
    [BuyExistingPlaceableEvent.STATE_SUCCESS] = {
        ["dialogType"] = DialogElement.TYPE_INFO,
        ["text"] = "shop_messageBoughtPlaceable"
    },
    [BuyExistingPlaceableEvent.STATE_NO_PERMISSION] = {
        ["dialogType"] = DialogElement.TYPE_WARNING,
        ["text"] = "shop_messageNoPermissionGeneral"
    },
    [BuyExistingPlaceableEvent.STATE_NOT_ENOUGH_MONEY] = {
        ["dialogType"] = DialogElement.TYPE_WARNING,
        ["text"] = "shop_messageNotEnoughMoneyToBuy"
    }
}
InitStaticEventClass(BuyExistingPlaceableEvent, "BuyExistingPlaceableEvent")
function BuyExistingPlaceableEvent.emptyNew()
    -- upvalues: (copy) BuyExistingPlaceableEvent_mt
    return Event.new(BuyExistingPlaceableEvent_mt)
end
function BuyExistingPlaceableEvent.new(placeable, ownerFarmId)
    local self = BuyExistingPlaceableEvent.emptyNew()
    self.placeable = placeable
    self.ownerFarmId = ownerFarmId
    return self
end
function BuyExistingPlaceableEvent.newServerToClient(statusCode, price)
    local self = BuyExistingPlaceableEvent.emptyNew()
    self.statusCode = statusCode
    self.price = price
    return self
end
function BuyExistingPlaceableEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.statusCode = streamReadUIntN(streamId, BuyExistingPlaceableEvent.STATE_NUM_BITS)
        self.price = streamReadInt32(streamId)
    else
        self.placeable = NetworkUtil.readNodeObject(streamId)
        self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    end
    self:run(connection)
end
function BuyExistingPlaceableEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.placeable)
        streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    else
        streamWriteUIntN(streamId, self.statusCode, BuyExistingPlaceableEvent.STATE_NUM_BITS)
        streamWriteInt32(streamId, self.price)
    end
end
function BuyExistingPlaceableEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(BuyExistingPlaceableEvent, self.statusCode, self.price)
    else
        local statusCode = BuyExistingPlaceableEvent.STATE_SUCCESS
        local price = 0
        if g_currentMission:getHasPlayerPermission("buyPlaceable", connection) then
            local dataStoreItem = g_storeManager:getItemByXMLFilename(self.placeable.configFileName)
            if dataStoreItem ~= nil then
                price = g_currentMission.economyManager:getBuyPrice(dataStoreItem)
                if self.placeable.buysFarmland then
                    local farmlandId = self.placeable:getFarmlandId()
                    local farmland = g_farmlandManager:getFarmlandById(farmlandId)
                    if farmland ~= nil and g_farmlandManager:getFarmlandOwner(farmlandId) ~= self.ownerFarmId then
                    end
                end
                if price <= g_currentMission:getMoney(self.ownerFarmId) then
                    g_currentMission:addMoney(-price, self.ownerFarmId, MoneyType.SHOP_PROPERTY_BUY, true, true)
                    self.placeable:setOwnerFarmId(self.ownerFarmId)
                else
                    statusCode = BuyExistingPlaceableEvent.STATE_NOT_ENOUGH_MONEY
                end
            end
        else
            statusCode = BuyExistingPlaceableEvent.STATE_NO_PERMISSION
        end
        connection:sendEvent(BuyExistingPlaceableEvent.newServerToClient(statusCode, price))
    end
end