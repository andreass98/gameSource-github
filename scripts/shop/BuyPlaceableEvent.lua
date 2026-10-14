BuyPlaceableEvent = {}
local BuyPlaceableEvent_mt = Class(BuyPlaceableEvent, Event)
BuyPlaceableEvent.STATE_SUCCESS = 0
BuyPlaceableEvent.STATE_FAILED_TO_LOAD = 1
BuyPlaceableEvent.STATE_NO_SPACE = 2
BuyPlaceableEvent.STATE_NO_PERMISSION = 3
BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY = 4
BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED = 5
InitStaticEventClass(BuyPlaceableEvent, "BuyPlaceableEvent")
function BuyPlaceableEvent.emptyNew()
    -- upvalues: (copy) BuyPlaceableEvent_mt
    return Event.new(BuyPlaceableEvent_mt)
end
function BuyPlaceableEvent.new(placeableBuyData)
    local self = BuyPlaceableEvent.emptyNew()
    self.placeableBuyData = placeableBuyData
    return self
end
function BuyPlaceableEvent.newServerToClient(errorCode, placeableBuyData, objectId)
    local self = BuyPlaceableEvent.emptyNew()
    self.errorCode = errorCode
    self.placeableBuyData = placeableBuyData
    self.objectId = objectId
    return self
end
function BuyPlaceableEvent:readStream(streamId, connection)
    if self.placeableBuyData == nil then
        self.placeableBuyData = BuyPlaceableData.new()
    end
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, 3)
        self.placeableBuyData:readStream(streamId, connection)
        if self.errorCode == BuyPlaceableEvent.STATE_SUCCESS then
            self.objectId = NetworkUtil.readNodeObjectId(streamId)
        end
    else
        self.placeableBuyData:readStream(streamId, connection)
        self.placeableBuyData:updatePrice()
    end
    self:run(connection)
end
function BuyPlaceableEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        self.placeableBuyData:writeStream(streamId, connection)
    else
        streamWriteUIntN(streamId, self.errorCode, 3)
        self.placeableBuyData:writeStream(streamId, connection)
        if self.errorCode == BuyPlaceableEvent.STATE_SUCCESS then
            NetworkUtil.writeNodeObjectId(streamId, self.objectId)
        end
    end
end
function BuyPlaceableEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(BuyPlaceableEvent, self.errorCode, self.price, self.objectId)
        return
    elseif g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_PLACEABLE, connection) then
        if self.placeableBuyData:isValid() then
            if buyData.isFreeOfCharge or g_currentMission:getMoney(buyData.ownerFarmId) >= buyData.price + buyData.displacementCosts then
                buyData:buy(self.onPlaceableBoughtCallback, self, {
                    ["connection"] = connection
                })
            else
                connection:sendEvent(BuyPlaceableEvent.newServerToClient(BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY, buyData))
            end
        else
            connection:sendEvent(BuyPlaceableEvent.newServerToClient(BuyPlaceableEvent.STATE_FAILED_TO_LOAD, buyData))
            return
        end
    else
        connection:sendEvent(BuyPlaceableEvent.newServerToClient(BuyPlaceableEvent.STATE_NO_PERMISSION, buyData))
        return
    end
end
function BuyPlaceableEvent:onPlaceableBoughtCallback(placeable, loadingState, arguments)
    local objectId = nil
    local errorCode = BuyPlaceableEvent.STATE_FAILED_TO_LOAD
    if loadingState == PlaceableLoadingState.OK then
        errorCode = BuyPlaceableEvent.STATE_SUCCESS
        objectId = NetworkUtil.getObjectId(placeable)
    elseif loadingState == PlaceableLoadingState.NO_SPACE then
        errorCode = BuyPlaceableEvent.STATE_NO_SPACE
    elseif loadingState == PlaceableLoadingState.DEFORMATION_FAILED then
        errorCode = BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED
    end
    arguments.connection:sendEvent(BuyPlaceableEvent.newServerToClient(errorCode, self.placeableBuyData, objectId))
end