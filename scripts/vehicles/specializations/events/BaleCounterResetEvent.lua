BaleCounterResetEvent = {}
local BaleCounterResetEvent_mt = Class(BaleCounterResetEvent, Event)
InitStaticEventClass(BaleCounterResetEvent, "BaleCounterResetEvent")
function BaleCounterResetEvent.emptyNew()
    -- upvalues: (copy) BaleCounterResetEvent_mt
    return Event.new(BaleCounterResetEvent_mt)
end
function BaleCounterResetEvent.new(object)
    local self = BaleCounterResetEvent.emptyNew()
    self.object = object
    return self
end
function BaleCounterResetEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function BaleCounterResetEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function BaleCounterResetEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:doBaleCounterReset(true)
    end
end
function BaleCounterResetEvent.sendEvent(vehicle, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BaleCounterResetEvent.new(vehicle), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(BaleCounterResetEvent.new(vehicle))
    end
end