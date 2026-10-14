VehicleRemoveEvent = {}
local VehicleRemoveEvent_mt = Class(VehicleRemoveEvent, Event)
InitStaticEventClass(VehicleRemoveEvent, "VehicleRemoveEvent")
function VehicleRemoveEvent.emptyNew()
    -- upvalues: (copy) VehicleRemoveEvent_mt
    return Event.new(VehicleRemoveEvent_mt)
end
function VehicleRemoveEvent.new(vehicle)
    local self = VehicleRemoveEvent.emptyNew()
    self.vehicle = vehicle
    assert(g_server ~= nil, "Client->Server event")
    return self
end
function VehicleRemoveEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function VehicleRemoveEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
end
function VehicleRemoveEvent:run(_)
    self.vehicle:delete()
end