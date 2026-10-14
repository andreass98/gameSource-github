PlaceableVehicleBuyingStationEvent = {}
PlaceableVehicleBuyingStationEvent.STATE_SUCCESS = 0
PlaceableVehicleBuyingStationEvent.STATE_FAILED_TO_LOAD = 1
PlaceableVehicleBuyingStationEvent.STATE_NO_SPACE = 2
PlaceableVehicleBuyingStationEvent.STATE_NO_PERMISSION = 3
PlaceableVehicleBuyingStationEvent.STATE_NOT_ENOUGH_MONEY = 4
local PlaceableVehicleBuyingStationEvent_mt = Class(PlaceableVehicleBuyingStationEvent, Event)
InitStaticEventClass(PlaceableVehicleBuyingStationEvent, "PlaceableVehicleBuyingStationEvent")
function PlaceableVehicleBuyingStationEvent.emptyNew()
    -- upvalues: (copy) PlaceableVehicleBuyingStationEvent_mt
    return Event.new(PlaceableVehicleBuyingStationEvent_mt)
end
function PlaceableVehicleBuyingStationEvent.new(placeable, farmId, storeItemIndex)
    local self = PlaceableVehicleBuyingStationEvent.emptyNew()
    self.placeable = placeable
    self.farmId = farmId
    self.storeItemIndex = storeItemIndex
    return self
end
function PlaceableVehicleBuyingStationEvent.newServerToClient(errorCode)
    local self = PlaceableVehicleBuyingStationEvent.emptyNew()
    self.errorCode = errorCode
    return self
end
function PlaceableVehicleBuyingStationEvent:readStream(streamId, connection)
    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, 3)
    else
        self.placeable = NetworkUtil.readNodeObject(streamId)
        self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
        self.storeItemIndex = streamReadUIntN(streamId, self.placeable.spec_vehicleBuyingStation.sendNumBits)
    end
    self:run(connection)
end
function PlaceableVehicleBuyingStationEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.placeable)
        streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
        streamWriteUIntN(streamId, self.storeItemIndex, self.placeable.spec_vehicleBuyingStation.sendNumBits)
    else
        streamWriteUIntN(streamId, self.errorCode, 3)
    end
end
function PlaceableVehicleBuyingStationEvent:run(connection)
    if connection:getIsServer() then
        g_messageCenter:publish(PlaceableVehicleBuyingStationEvent, self.errorCode)
        return
    else
        local userId = g_currentMission.userManager:getUserIdByConnection(connection)
        if g_farmManager:getFarmByUserId(userId) == nil or not g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE, connection) then
            connection:sendEvent(PlaceableVehicleBuyingStationEvent.newServerToClient(BuyVehicleEvent.STATE_NO_PERMISSION, self.vehicleBuyData))
        elseif self.placeable ~= nil then
            self.placeable:buyVehicle(self.farmId, self.storeItemIndex, function(errorCode)
                -- upvalues: (copy) connection
                connection:sendEvent(PlaceableVehicleBuyingStationEvent.newServerToClient(errorCode))
            end)
        end
    end
end