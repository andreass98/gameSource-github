SetCrabSteeringEvent = {}
local SetCrabSteeringEvent_mt = Class(SetCrabSteeringEvent, Event)
InitStaticEventClass(SetCrabSteeringEvent, "SetCrabSteeringEvent")
function SetCrabSteeringEvent.emptyNew()
    -- upvalues: (copy) SetCrabSteeringEvent_mt
    return Event.new(SetCrabSteeringEvent_mt)
end
function SetCrabSteeringEvent.new(vehicle, state)
    local self = SetCrabSteeringEvent.emptyNew()
    self.vehicle = vehicle
    self.state = state
    return self
end
function SetCrabSteeringEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, CrabSteering.STEERING_SEND_NUM_BITS)
    self:run(connection)
end
function SetCrabSteeringEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.state, CrabSteering.STEERING_SEND_NUM_BITS)
end
function SetCrabSteeringEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setCrabSteering(self.state, true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(SetCrabSteeringEvent.new(self.vehicle, self.state), nil, connection, self.object)
    end
end
function SetCrabSteeringEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetCrabSteeringEvent.new(vehicle, state), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(SetCrabSteeringEvent.new(vehicle, state))
    end
end