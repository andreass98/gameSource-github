VehicleSaleRemoveEvent = {}
local VehicleSaleRemoveEvent_mt = Class(VehicleSaleRemoveEvent, Event)
InitStaticEventClass(VehicleSaleRemoveEvent, "VehicleSaleRemoveEvent")
function VehicleSaleRemoveEvent.emptyNew()
    -- upvalues: (copy) VehicleSaleRemoveEvent_mt
    return Event.new(VehicleSaleRemoveEvent_mt)
end
function VehicleSaleRemoveEvent.new(saleItemId)
    local self = VehicleSaleRemoveEvent.emptyNew()
    self.saleItemId = saleItemId
    return self
end
function VehicleSaleRemoveEvent:readStream(streamId, connection)
    self.saleItemId = streamReadUInt8(streamId)
    self:run(connection)
end
function VehicleSaleRemoveEvent:writeStream(streamId, _)
    streamWriteUInt8(streamId, self.saleItemId)
end
function VehicleSaleRemoveEvent:run(connection)
    if connection:getIsServer() then
        g_currentMission.vehicleSaleSystem:removeSaleWithId(self.saleItemId)
    end
end