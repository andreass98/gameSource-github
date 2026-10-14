MotorClutchCreakingEvent = {}
local MotorClutchCreakingEvent_mt = Class(MotorClutchCreakingEvent, Event)
InitStaticEventClass(MotorClutchCreakingEvent, "MotorClutchCreakingEvent")
function MotorClutchCreakingEvent.emptyNew()
    -- upvalues: (copy) MotorClutchCreakingEvent_mt
    return Event.new(MotorClutchCreakingEvent_mt)
end
function MotorClutchCreakingEvent.new(vehicle, isEvent, groupTransmission, gearIndex, groupIndex)
    local self = MotorClutchCreakingEvent.emptyNew()
    self.vehicle = vehicle
    self.isEvent = isEvent
    self.groupTransmission = groupTransmission
    self.gearIndex = gearIndex
    self.groupIndex = groupIndex
    return self
end
function MotorClutchCreakingEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isEvent = streamReadBool(streamId)
    self.groupTransmission = streamReadBool(streamId)
    if streamReadBool(streamId) then
        self.gearIndex = streamReadUIntN(streamId, 6)
    end
    if streamReadBool(streamId) then
        self.groupIndex = streamReadUIntN(streamId, 5)
    end
    self:run(connection)
end
function MotorClutchCreakingEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isEvent)
    streamWriteBool(streamId, self.groupTransmission)
    if streamWriteBool(streamId, self.gearIndex ~= nil) then
        streamWriteUIntN(streamId, self.gearIndex, 6)
    end
    if streamWriteBool(streamId, self.groupIndex ~= nil) then
        streamWriteUIntN(streamId, self.groupIndex, 5)
    end
end
function MotorClutchCreakingEvent:run(_)
    local vehicle = self.vehicle
    if vehicle ~= nil and vehicle:getIsSynchronized() then
        SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", self.isEvent, self.groupTransmission, self.gearIndex, self.groupIndex)
    end
end