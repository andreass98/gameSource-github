SellPlaceableEvent = {}
SellPlaceableEvent.STATE_SUCCESS = 0
SellPlaceableEvent.STATE_FAILED = 1
SellPlaceableEvent.STATE_NO_PERMISSION = 2
SellPlaceableEvent.STATE_IN_USE = 3
local SellPlaceableEvent_mt = Class(SellPlaceableEvent, Event)
InitStaticEventClass(SellPlaceableEvent, "SellPlaceableEvent")
function SellPlaceableEvent.emptyNew()
    -- upvalues: (copy) SellPlaceableEvent_mt
    return Event.new(SellPlaceableEvent_mt)
end
function SellPlaceableEvent.new(placeable, forFree, forFullPrice, showSoldPopup, ignorePermissions)
    local self = SellPlaceableEvent.emptyNew()
    self.placeable = placeable
    self.forFree = Utils.getNoNil(forFree, false)
    self.forFullPrice = Utils.getNoNil(forFullPrice, false)
    self.showSoldPopup = Utils.getNoNil(showSoldPopup, true)
    self.ignorePermissions = Utils.getNoNil(ignorePermissions, false)
    return self
end
function SellPlaceableEvent.newServerToClient(state, sellPrice, showSoldPopup)
    local self = SellPlaceableEvent.emptyNew()
    self.state = state
    self.sellPrice = sellPrice
    self.showSoldPopup = Utils.getNoNil(showSoldPopup, true)
    return self
end
function SellPlaceableEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.state = streamReadUIntN(streamId, 2)
        if self.state == SellPlaceableEvent.STATE_SUCCESS then
            self.sellPrice = streamReadInt32(streamId)
            self.showSoldPopup = streamReadBool(streamId)
        end
    else
        self.placeable = NetworkUtil.readNodeObject(streamId)
        self.forFree = streamReadBool(streamId)
        self.forFullPrice = streamReadBool(streamId)
        self.showSoldPopup = streamReadBool(streamId)
        self.ignorePermissions = streamReadBool(streamId)
    end
    self:run(connection)
end
function SellPlaceableEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.placeable)
        streamWriteBool(streamId, self.forFree)
        streamWriteBool(streamId, self.forFullPrice)
        streamWriteBool(streamId, self.showSoldPopup)
        streamWriteBool(streamId, self.ignorePermissions)
    else
        streamWriteUIntN(streamId, self.state, 2)
        if self.state == SellPlaceableEvent.STATE_SUCCESS then
            streamWriteInt32(streamId, self.sellPrice)
            streamWriteBool(streamId, self.showSoldPopup)
        end
    end
end
function SellPlaceableEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(SellPlaceableEvent, self.state, self.sellPrice, self.showSoldPopup)
    else
        local state = SellPlaceableEvent.STATE_FAILED
        local sellPrice = 0
        if self.placeable ~= nil then
            if self.ignorePermissions or g_currentMission:getHasPlayerPermission("sellPlaceable", connection) then
                if self.placeable:canBeSold() then
                    self.placeable:onSell()
                    if not self.forFree then
                        if self.forFullPrice then
                            sellPrice = self.placeable.price
                        else
                            sellPrice = self.placeable:getSellPrice()
                        end
                        g_currentMission:addMoney(sellPrice, self.placeable:getOwnerFarmId(), MoneyType.SHOP_PROPERTY_SELL, true, true)
                    end
                    state = SellPlaceableEvent.STATE_SUCCESS
                    if self.placeable:getSellAction() == Placeable.SELL_AND_SPECTATOR_FARM then
                        self.placeable:setOwnerFarmId(FarmManager.SPECTATOR_FARM_ID)
                    else
                        self.placeable:delete()
                    end
                else
                    state = SellPlaceableEvent.STATE_IN_USE
                end
            else
                state = SellPlaceableEvent.STATE_NO_PERMISSION
            end
        end
        connection:sendEvent(SellPlaceableEvent.newServerToClient(state, sellPrice, self.showSoldPopup))
    end
end