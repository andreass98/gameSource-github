VehicleDetachEvent = {}
local VehicleDetachEvent_mt = Class(VehicleDetachEvent, Event)
InitStaticEventClass(VehicleDetachEvent, "VehicleDetachEvent")
function VehicleDetachEvent.emptyNew()
    -- upvalues: (copy) VehicleDetachEvent_mt
    return Event.new(VehicleDetachEvent_mt)
end
function VehicleDetachEvent.new(vehicle, implement)
    local self = VehicleDetachEvent.emptyNew()
    self.implement = implement
    self.vehicle = vehicle
    return self
end
function VehicleDetachEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.implement = NetworkUtil.readNodeObject(streamId)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        if connection:getIsServer() then
            self.vehicle:detachImplementByObject(self.implement, true)
            return
        end
        self.vehicle:detachImplementByObject(self.implement)
    end
end
function VehicleDetachEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    NetworkUtil.writeNodeObject(streamId, self.implement)
end
function VehicleDetachEvent:run(connection) end