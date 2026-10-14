AIAutomaticSteeringStateEvent = {}
local AIAutomaticSteeringStateEvent_mt = Class(AIAutomaticSteeringStateEvent, Event)
InitStaticEventClass(AIAutomaticSteeringStateEvent, "AIAutomaticSteeringStateEvent")
function AIAutomaticSteeringStateEvent.emptyNew()
    -- upvalues: (copy) AIAutomaticSteeringStateEvent_mt
    return Event.new(AIAutomaticSteeringStateEvent_mt)
end
function AIAutomaticSteeringStateEvent.new(vehicle, state, segmentIndex, segmentIsLeft)
    local self = AIAutomaticSteeringStateEvent.emptyNew()
    self.vehicle = vehicle
    self.state = state
    self.segmentIndex = segmentIndex
    self.segmentIsLeft = segmentIsLeft
    return self
end
function AIAutomaticSteeringStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    if streamReadBool(streamId) then
        self.segmentIndex = streamReadUInt16(streamId)
        self.segmentIsLeft = streamReadBool(streamId)
    end
    self:run(connection)
end
function AIAutomaticSteeringStateEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.state)
    if streamWriteBool(streamId, self.segmentIndex ~= nil and self.segmentIndex > 0) then
        streamWriteUInt16(streamId, self.segmentIndex)
        streamWriteBool(streamId, Utils.getNoNil(self.segmentIsLeft, false))
    end
end
function AIAutomaticSteeringStateEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.segmentIndex, self.segmentIsLeft = self.vehicle:setAIAutomaticSteeringEnabled(self.state, self.segmentIndex, self.segmentIsLeft, true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(AIAutomaticSteeringStateEvent.new(self.vehicle, self.state, self.segmentIndex, self.segmentIsLeft), nil, nil, self.vehicle)
    end
end
function AIAutomaticSteeringStateEvent.sendEvent(vehicle, state, segmentIndex, segmentIsLeft, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AIAutomaticSteeringStateEvent.new(vehicle, state, segmentIndex, segmentIsLeft), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(AIAutomaticSteeringStateEvent.new(vehicle, state, segmentIndex, segmentIsLeft))
    end
end