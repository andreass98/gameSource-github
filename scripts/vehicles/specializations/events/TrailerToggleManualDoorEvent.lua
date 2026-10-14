TrailerToggleManualDoorEvent = {}
local TrailerToggleManualDoorEvent_mt = Class(TrailerToggleManualDoorEvent, Event)
InitStaticEventClass(TrailerToggleManualDoorEvent, "TrailerToggleManualDoorEvent")
function TrailerToggleManualDoorEvent.emptyNew()
    -- upvalues: (copy) TrailerToggleManualDoorEvent_mt
    return Event.new(TrailerToggleManualDoorEvent_mt)
end
function TrailerToggleManualDoorEvent.new(object, tipSideIndex, state)
    local self = TrailerToggleManualDoorEvent.emptyNew()
    self.object = object
    self.tipSideIndex = tipSideIndex
    self.state = state
    return self
end
function TrailerToggleManualDoorEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self.tipSideIndex = streamReadUIntN(streamId, Trailer.TIP_SIDE_NUM_BITS)
    self:run(connection)
end
function TrailerToggleManualDoorEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
    streamWriteUIntN(streamId, self.tipSideIndex, Trailer.TIP_SIDE_NUM_BITS)
end
function TrailerToggleManualDoorEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setTrailerDoorState(self.tipSideIndex, self.state, true)
    end
end
function TrailerToggleManualDoorEvent.sendEvent(vehicle, tipSideIndex, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TrailerToggleManualDoorEvent.new(vehicle, tipSideIndex, state), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(TrailerToggleManualDoorEvent.new(vehicle, tipSideIndex, state))
    end
end