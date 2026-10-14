SetPipeStateEvent = {}
local SetPipeStateEvent_mt = Class(SetPipeStateEvent, Event)
InitStaticEventClass(SetPipeStateEvent, "SetPipeStateEvent")
function SetPipeStateEvent.emptyNew()
    -- upvalues: (copy) SetPipeStateEvent_mt
    return Event.new(SetPipeStateEvent_mt)
end
function SetPipeStateEvent.new(object, pipeState)
    local self = SetPipeStateEvent.emptyNew()
    self.object = object
    self.pipeState = pipeState
    assert(self.pipeState >= 0 and self.pipeState < 8)
    return self
end
function SetPipeStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.pipeState = streamReadUIntN(streamId, 3)
    self:run(connection)
end
function SetPipeStateEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.pipeState, 3)
end
function SetPipeStateEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPipeState(self.pipeState, true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(SetPipeStateEvent.new(self.object, self.pipeState), nil, connection, self.object)
    end
end