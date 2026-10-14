AIVehicleIsBlockedEvent = {}
local AIVehicleIsBlockedEvent_mt = Class(AIVehicleIsBlockedEvent, Event)
InitStaticEventClass(AIVehicleIsBlockedEvent, "AIVehicleIsBlockedEvent")
function AIVehicleIsBlockedEvent.emptyNew()
    -- upvalues: (copy) AIVehicleIsBlockedEvent_mt
    return Event.new(AIVehicleIsBlockedEvent_mt)
end
function AIVehicleIsBlockedEvent.new(object, isBlocked)
    local self = AIVehicleIsBlockedEvent.emptyNew()
    self.object = object
    self.isBlocked = isBlocked
    return self
end
function AIVehicleIsBlockedEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.isBlocked = streamReadBool(streamId)
    self:run(connection)
end
function AIVehicleIsBlockedEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.isBlocked)
end
function AIVehicleIsBlockedEvent:run(_)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.isBlocked then
            self.object:aiBlock()
            return
        end
        self.object:aiContinue()
    end
end