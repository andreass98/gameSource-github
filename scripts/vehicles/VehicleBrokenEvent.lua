VehicleBrokenEvent = {}
local VehicleBrokenEvent_mt = Class(VehicleBrokenEvent, Event)
InitStaticEventClass(VehicleBrokenEvent, "VehicleBrokenEvent")
function VehicleBrokenEvent.emptyNew()
    -- upvalues: (copy) VehicleBrokenEvent_mt
    return Event.new(VehicleBrokenEvent_mt)
end
function VehicleBrokenEvent.new(object)
    local self = VehicleBrokenEvent.emptyNew()
    self.object = object
    return self
end
function VehicleBrokenEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function VehicleBrokenEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function VehicleBrokenEvent:run(_)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setBroken()
    end
end