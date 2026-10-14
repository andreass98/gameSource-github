VehicleSetBeaconLightEvent = {}
local VehicleSetBeaconLightEvent_mt = Class(VehicleSetBeaconLightEvent, Event)
InitStaticEventClass(VehicleSetBeaconLightEvent, "VehicleSetBeaconLightEvent")
function VehicleSetBeaconLightEvent.emptyNew()
    -- upvalues: (copy) VehicleSetBeaconLightEvent_mt
    return Event.new(VehicleSetBeaconLightEvent_mt)
end
function VehicleSetBeaconLightEvent.new(object, active)
    local self = VehicleSetBeaconLightEvent.emptyNew()
    self.active = active
    self.object = object
    return self
end
function VehicleSetBeaconLightEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.active = streamReadBool(streamId)
    self:run(connection)
end
function VehicleSetBeaconLightEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.active)
end
function VehicleSetBeaconLightEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setBeaconLightsVisibility(self.active, true, true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(VehicleSetBeaconLightEvent.new(self.object, self.active), nil, connection, self.object)
    end
end