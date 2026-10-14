SetCruiseControlSpeedEvent = {}
local SetCruiseControlSpeedEvent_mt = Class(SetCruiseControlSpeedEvent, Event)
InitStaticEventClass(SetCruiseControlSpeedEvent, "SetCruiseControlSpeedEvent")
function SetCruiseControlSpeedEvent.emptyNew()
    -- upvalues: (copy) SetCruiseControlSpeedEvent_mt
    return Event.new(SetCruiseControlSpeedEvent_mt)
end
function SetCruiseControlSpeedEvent.new(vehicle, speed, speedReverse)
    local self = SetCruiseControlSpeedEvent.emptyNew()
    self.speed = speed
    self.speedReverse = speedReverse
    self.vehicle = vehicle
    return self
end
function SetCruiseControlSpeedEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.speed = streamReadUInt8(streamId)
    self.speedReverse = streamReadUInt8(streamId)
    self:run(connection)
end
function SetCruiseControlSpeedEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUInt8(streamId, self.speed)
    streamWriteUInt8(streamId, self.speedReverse)
end
function SetCruiseControlSpeedEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setCruiseControlMaxSpeed(self.speed, self.speedReverse)
    end
end