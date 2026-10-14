VehicleSetIsReconfiguratingEvent = {}
local VehicleSetIsReconfiguratingEvent_mt = Class(VehicleSetIsReconfiguratingEvent, Event)
InitStaticEventClass(VehicleSetIsReconfiguratingEvent, "VehicleSetIsReconfiguratingEvent")
function VehicleSetIsReconfiguratingEvent.emptyNew()
    -- upvalues: (copy) VehicleSetIsReconfiguratingEvent_mt
    return Event.new(VehicleSetIsReconfiguratingEvent_mt)
end
function VehicleSetIsReconfiguratingEvent.new(object)
    local self = VehicleSetIsReconfiguratingEvent.emptyNew()
    self.object = object
    return self
end
function VehicleSetIsReconfiguratingEvent:readStream(streamId, _)
    self.object = NetworkUtil.readNodeObject(streamId)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object.isReconfigurating = true
    end
end
function VehicleSetIsReconfiguratingEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end