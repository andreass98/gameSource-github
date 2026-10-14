AIAutomaticSteeringLineEndEvent = {}
local AIAutomaticSteeringLineEndEvent_mt = Class(AIAutomaticSteeringLineEndEvent, Event)
InitStaticEventClass(AIAutomaticSteeringLineEndEvent, "AIAutomaticSteeringLineEndEvent")
function AIAutomaticSteeringLineEndEvent.emptyNew()
    -- upvalues: (copy) AIAutomaticSteeringLineEndEvent_mt
    return Event.new(AIAutomaticSteeringLineEndEvent_mt)
end
function AIAutomaticSteeringLineEndEvent.new(vehicle, _, _, _)
    local self = AIAutomaticSteeringLineEndEvent.emptyNew()
    self.vehicle = vehicle
    return self
end
function AIAutomaticSteeringLineEndEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function AIAutomaticSteeringLineEndEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
end
function AIAutomaticSteeringLineEndEvent:run(_)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        SpecializationUtil.raiseEvent(self.vehicle, "onAIAutomaticSteeringLineEnd")
    end
end