TensionBeltsRefreshEvent = {}
local TensionBeltsRefreshEvent_mt = Class(TensionBeltsRefreshEvent, Event)
InitStaticEventClass(TensionBeltsRefreshEvent, "TensionBeltsRefreshEvent")
function TensionBeltsRefreshEvent.emptyNew()
    -- upvalues: (copy) TensionBeltsRefreshEvent_mt
    return Event.new(TensionBeltsRefreshEvent_mt)
end
function TensionBeltsRefreshEvent.new(object)
    local self = TensionBeltsRefreshEvent.emptyNew()
    self.object = object
    return self
end
function TensionBeltsRefreshEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function TensionBeltsRefreshEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function TensionBeltsRefreshEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:refreshTensionBelts()
    end
end