MotorSetTurnedOnEvent = {}
local MotorSetTurnedOnEvent_mt = Class(MotorSetTurnedOnEvent, Event)
InitStaticEventClass(MotorSetTurnedOnEvent, "MotorSetTurnedOnEvent")
function MotorSetTurnedOnEvent.emptyNew()
    -- upvalues: (copy) MotorSetTurnedOnEvent_mt
    return Event.new(MotorSetTurnedOnEvent_mt)
end
function MotorSetTurnedOnEvent.new(vehicle, turnedOn)
    local self = MotorSetTurnedOnEvent.emptyNew()
    self.vehicle = vehicle
    self.turnedOn = turnedOn
    return self
end
function MotorSetTurnedOnEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.turnedOn = streamReadBool(streamId)
    self:run(connection)
end
function MotorSetTurnedOnEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.turnedOn)
end
function MotorSetTurnedOnEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        if self.turnedOn then
            self.vehicle:startMotor(true)
        else
            self.vehicle:stopMotor(true)
        end
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(MotorSetTurnedOnEvent.new(self.vehicle, self.turnedOn), nil, connection, self.vehicle)
    end
end
function MotorSetTurnedOnEvent.sendEvent(vehicle, turnedOn, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(MotorSetTurnedOnEvent.new(vehicle, turnedOn), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(MotorSetTurnedOnEvent.new(vehicle, turnedOn))
    end
end