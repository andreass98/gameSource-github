PlowRotationCenterEvent = {}
local PlowRotationCenterEvent_mt = Class(PlowRotationCenterEvent, Event)
InitStaticEventClass(PlowRotationCenterEvent, "PlowRotationCenterEvent")
function PlowRotationCenterEvent.emptyNew()
    -- upvalues: (copy) PlowRotationCenterEvent_mt
    return Event.new(PlowRotationCenterEvent_mt)
end
function PlowRotationCenterEvent.new(object)
    local self = PlowRotationCenterEvent.emptyNew()
    self.object = object
    return self
end
function PlowRotationCenterEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function PlowRotationCenterEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function PlowRotationCenterEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setRotationCenter(true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(PlowRotationCenterEvent.new(self.object), nil, connection, self.object)
    end
end
function PlowRotationCenterEvent.sendEvent(object, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlowRotationCenterEvent.new(object), nil, nil, object)
            return
        end
        g_client:getServerConnection():sendEvent(PlowRotationCenterEvent.new(object))
    end
end