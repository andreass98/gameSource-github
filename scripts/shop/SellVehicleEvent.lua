SellVehicleEvent = {}
local SellVehicleEvent_mt = Class(SellVehicleEvent, Event)
SellVehicleEvent.SELL_SUCCESS = 0
SellVehicleEvent.SELL_VEHICLE_IN_USE = 1
SellVehicleEvent.SELL_NO_PERMISSION = 2
SellVehicleEvent.SELL_LAST_VEHICLE = 3
InitStaticEventClass(SellVehicleEvent, "SellVehicleEvent")
function SellVehicleEvent.emptyNew()
    -- upvalues: (copy) SellVehicleEvent_mt
    return Event.new(SellVehicleEvent_mt)
end
function SellVehicleEvent.new(vehicle, multiplier, isDirectSell)
    local self = SellVehicleEvent.emptyNew()
    self.vehicle = vehicle
    self.multiplier = Utils.getNoNil(multiplier, 1)
    self.isDirectSell = Utils.getNoNil(isDirectSell, false)
    self.isOwned = true
    return self
end
function SellVehicleEvent.newServerToClient(errorCode, sellPrice, isDirectSell, isOwned, ownerFarmId)
    local self = SellVehicleEvent.emptyNew()
    self.errorCode = errorCode
    self.sellPrice = sellPrice
    self.isDirectSell = isDirectSell
    self.isOwned = isOwned
    self.ownerFarmId = ownerFarmId
    return self
end
function SellVehicleEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, 2)
        if self.errorCode == SellVehicleEvent.SELL_SUCCESS then
            self.sellPrice = streamReadInt32(streamId)
        end
        self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    else
        self.vehicle = NetworkUtil.readNodeObject(streamId)
        self.multiplier = streamReadFloat32(streamId)
    end
    self.isDirectSell = streamReadBool(streamId)
    self.isOwned = streamReadBool(streamId)
    self:run(connection)
end
function SellVehicleEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.vehicle)
        streamWriteFloat32(streamId, self.multiplier)
    else
        streamWriteUIntN(streamId, self.errorCode, 2)
        if self.errorCode == SellVehicleEvent.SELL_SUCCESS then
            self.sellPrice = streamWriteInt32(streamId, self.sellPrice)
        end
        streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    end
    streamWriteBool(streamId, self.isDirectSell)
    streamWriteBool(streamId, self.isOwned)
end
function SellVehicleEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publishDelayedAfterFrames(SellVehicleEvent, 2, self.isDirectSell, self.errorCode, self.sellPrice, self.isOwned, self.ownerFarmId)
    else
        local errorCode = SellVehicleEvent.SELL_SUCCESS
        local sellPrice = 0
        local isOwned = self.vehicle.propertyState == VehiclePropertyState.OWNED
        if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE, connection, self.vehicle:getOwnerFarmId()) then
            if self.vehicle:getIsInUse(connection) then
                errorCode = SellVehicleEvent.SELL_VEHICLE_IN_USE
            else
                if self.vehicle.propertyState == VehiclePropertyState.OWNED then
                    sellPrice = math.min(math.floor(self.vehicle:getSellPrice() * self.multiplier), self.vehicle:getPrice())
                end
                if isOwned then
                    g_currentMission.vehicleSaleSystem:onVehicleWillSell(self.vehicle)
                end
                self.vehicle:delete()
                g_currentMission:addMoney(sellPrice, self.vehicle:getOwnerFarmId(), MoneyType.SHOP_VEHICLE_SELL, true)
            end
        else
            errorCode = SellVehicleEvent.SELL_NO_PERMISSION
        end
        connection:sendEvent(SellVehicleEvent.newServerToClient(errorCode, sellPrice, self.isDirectSell, isOwned, self.vehicle:getOwnerFarmId()))
    end
end