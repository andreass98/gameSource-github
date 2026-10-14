TreePlanterLoadPalletEvent = {}
local TreePlanterLoadPalletEvent_mt = Class(TreePlanterLoadPalletEvent, Event)
InitStaticEventClass(TreePlanterLoadPalletEvent, "TreePlanterLoadPalletEvent")
function TreePlanterLoadPalletEvent.emptyNew()
    -- upvalues: (copy) TreePlanterLoadPalletEvent_mt
    return Event.new(TreePlanterLoadPalletEvent_mt)
end
function TreePlanterLoadPalletEvent.new(object, palletObjectId)
    local self = TreePlanterLoadPalletEvent.emptyNew()
    self.object = object
    self.palletObjectId = palletObjectId
    return self
end
function TreePlanterLoadPalletEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.palletObjectId = NetworkUtil.readNodeObjectId(streamId)
    self:run(connection)
end
function TreePlanterLoadPalletEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    NetworkUtil.writeNodeObjectId(streamId, self.palletObjectId)
end
function TreePlanterLoadPalletEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:loadPallet(self.palletObjectId, true)
    end
end
function TreePlanterLoadPalletEvent.sendEvent(object, palletObjectId, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TreePlanterLoadPalletEvent.new(object, palletObjectId), nil, nil, object)
            return
        end
        g_client:getServerConnection():sendEvent(TreePlanterLoadPalletEvent.new(object, palletObjectId))
    end
end