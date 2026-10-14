TreePlanterCreateTreeEvent = {}
local TreePlanterCreateTreeEvent_mt = Class(TreePlanterCreateTreeEvent, Event)
InitStaticEventClass(TreePlanterCreateTreeEvent, "TreePlanterCreateTreeEvent")
function TreePlanterCreateTreeEvent.emptyNew()
    -- upvalues: (copy) TreePlanterCreateTreeEvent_mt
    return Event.new(TreePlanterCreateTreeEvent_mt)
end
function TreePlanterCreateTreeEvent.new(object, _, _)
    local self = TreePlanterCreateTreeEvent.emptyNew()
    self.object = object
    return self
end
function TreePlanterCreateTreeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function TreePlanterCreateTreeEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function TreePlanterCreateTreeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:createTree(true)
    end
end
function TreePlanterCreateTreeEvent.sendEvent(object, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TreePlanterCreateTreeEvent.new(object), nil, nil, object)
            return
        end
        g_client:getServerConnection():sendEvent(TreePlanterCreateTreeEvent.new(object))
    end
end