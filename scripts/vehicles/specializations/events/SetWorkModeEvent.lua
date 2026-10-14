SetWorkModeEvent = {}
local SetWorkModeEvent_mt = Class(SetWorkModeEvent, Event)
InitStaticEventClass(SetWorkModeEvent, "SetWorkModeEvent")
function SetWorkModeEvent.emptyNew()
    -- upvalues: (copy) SetWorkModeEvent_mt
    return Event.new(SetWorkModeEvent_mt)
end
function SetWorkModeEvent.new(vehicle, state)
    local self = SetWorkModeEvent.emptyNew()
    self.vehicle = vehicle
    self.state = state
    return self
end
function SetWorkModeEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, WorkMode.WORKMODE_SEND_NUM_BITS)
    self:run(connection)
end
function SetWorkModeEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.state, WorkMode.WORKMODE_SEND_NUM_BITS)
end
function SetWorkModeEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setWorkMode(self.state, true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(SetWorkModeEvent.new(self.vehicle, self.state), nil, connection, self.object)
    end
end
function SetWorkModeEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetWorkModeEvent.new(vehicle, state), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(SetWorkModeEvent.new(vehicle, state))
    end
end