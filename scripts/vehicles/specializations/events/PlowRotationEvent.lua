PlowRotationEvent = {}
local PlowRotationEvent_mt = Class(PlowRotationEvent, Event)
InitStaticEventClass(PlowRotationEvent, "PlowRotationEvent")
function PlowRotationEvent.emptyNew()
    -- upvalues: (copy) PlowRotationEvent_mt
    return Event.new(PlowRotationEvent_mt)
end
function PlowRotationEvent.new(object, rotationMax)
    local self = PlowRotationEvent.emptyNew()
    self.object = object
    self.rotationMax = rotationMax
    return self
end
function PlowRotationEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.rotationMax = streamReadBool(streamId)
    self:run(connection)
end
function PlowRotationEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.rotationMax)
end
function PlowRotationEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setRotationMax(self.rotationMax, true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(PlowRotationEvent.new(self.object, self.rotationMax), nil, connection, self.object)
    end
end
function PlowRotationEvent.sendEvent(object, rotationMax, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlowRotationEvent.new(object, rotationMax), nil, nil, object)
            return
        end
        g_client:getServerConnection():sendEvent(PlowRotationEvent.new(object, rotationMax))
    end
end