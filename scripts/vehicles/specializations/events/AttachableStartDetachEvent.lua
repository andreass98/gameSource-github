AttachableStartDetachEvent = {}
local AttachableStartDetachEvent_mt = Class(AttachableStartDetachEvent, Event)
InitStaticEventClass(AttachableStartDetachEvent, "AttachableStartDetachEvent")
function AttachableStartDetachEvent.emptyNew()
    -- upvalues: (copy) AttachableStartDetachEvent_mt
    return Event.new(AttachableStartDetachEvent_mt)
end
function AttachableStartDetachEvent.new(vehicle, _, _, _)
    local self = AttachableStartDetachEvent.emptyNew()
    self.vehicle = vehicle
    return self
end
function AttachableStartDetachEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function AttachableStartDetachEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
end
function AttachableStartDetachEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:startDetachProcess(true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(AttachableStartDetachEvent.new(self.vehicle), nil, nil, self.vehicle)
    end
end
function AttachableStartDetachEvent.sendEvent(vehicle, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AttachableStartDetachEvent.new(vehicle), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(AttachableStartDetachEvent.new(vehicle))
    end
end