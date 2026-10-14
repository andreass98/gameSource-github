SetCruiseControlStateEvent = {}
local SetCruiseControlStateEvent_mt = Class(SetCruiseControlStateEvent, Event)
InitStaticEventClass(SetCruiseControlStateEvent, "SetCruiseControlStateEvent")
function SetCruiseControlStateEvent.emptyNew()
    -- upvalues: (copy) SetCruiseControlStateEvent_mt
    return Event.new(SetCruiseControlStateEvent_mt)
end
function SetCruiseControlStateEvent.new(vehicle, state)
    local self = SetCruiseControlStateEvent.emptyNew()
    self.state = state
    self.vehicle = vehicle
    return self
end
function SetCruiseControlStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, 2)
    self:run(connection)
end
function SetCruiseControlStateEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.state, 2)
end
function SetCruiseControlStateEvent:run(_)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setCruiseControlState(self.state, true)
    end
end