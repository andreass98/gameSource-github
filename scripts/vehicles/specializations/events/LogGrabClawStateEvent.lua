LogGrabClawStateEvent = {}
local LogGrabClawStateEvent_mt = Class(LogGrabClawStateEvent, Event)
InitStaticEventClass(LogGrabClawStateEvent, "LogGrabClawStateEvent")
function LogGrabClawStateEvent.emptyNew()
    -- upvalues: (copy) LogGrabClawStateEvent_mt
    return Event.new(LogGrabClawStateEvent_mt)
end
function LogGrabClawStateEvent.new(object, state, grabIndex)
    local self = LogGrabClawStateEvent.emptyNew()
    self.object = object
    self.state = state
    self.grabIndex = grabIndex
    return self
end
function LogGrabClawStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self.grabIndex = streamReadUIntN(streamId, LogGrab.GRAB_INDEX_NUM_BITS)
    self:run(connection)
end
function LogGrabClawStateEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
    streamWriteUIntN(streamId, self.grabIndex, LogGrab.GRAB_INDEX_NUM_BITS)
end
function LogGrabClawStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setLogGrabClawState(self.grabIndex, self.state, true)
    end
end
function LogGrabClawStateEvent.sendEvent(vehicle, state, grabIndex, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(LogGrabClawStateEvent.new(vehicle, state, grabIndex), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(LogGrabClawStateEvent.new(vehicle, state, grabIndex))
    end
end