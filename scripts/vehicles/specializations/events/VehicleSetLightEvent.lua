VehicleSetLightEvent = {}
local VehicleSetLightEvent_mt = Class(VehicleSetLightEvent, Event)
InitStaticEventClass(VehicleSetLightEvent, "VehicleSetLightEvent")
function VehicleSetLightEvent.emptyNew()
    -- upvalues: (copy) VehicleSetLightEvent_mt
    return Event.new(VehicleSetLightEvent_mt)
end
function VehicleSetLightEvent.new(object, lightsTypesMask, numBits)
    local self = VehicleSetLightEvent.emptyNew()
    self.object = object
    self.lightsTypesMask = lightsTypesMask
    self.numBits = numBits
    return self
end
function VehicleSetLightEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.numBits = streamReadUIntN(streamId, 5)
    self.lightsTypesMask = streamReadUIntN(streamId, self.numBits)
    self:run(connection)
end
function VehicleSetLightEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.numBits, 5)
    streamWriteUIntN(streamId, self.lightsTypesMask, self.numBits)
end
function VehicleSetLightEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setLightsTypesMask(self.lightsTypesMask, true, true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(VehicleSetLightEvent.new(self.object, self.lightsTypesMask, self.numBits), nil, connection, self.object)
    end
end