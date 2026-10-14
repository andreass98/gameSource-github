FellerBuncherReleaseEvent = {}
local FellerBuncherReleaseEvent_mt = Class(FellerBuncherReleaseEvent, Event)
InitStaticEventClass(FellerBuncherReleaseEvent, "FellerBuncherReleaseEvent")
function FellerBuncherReleaseEvent.emptyNew()
    -- upvalues: (copy) FellerBuncherReleaseEvent_mt
    return Event.new(FellerBuncherReleaseEvent_mt)
end
function FellerBuncherReleaseEvent.new(object)
    local self = FellerBuncherReleaseEvent.emptyNew()
    self.object = object
    return self
end
function FellerBuncherReleaseEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function FellerBuncherReleaseEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function FellerBuncherReleaseEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:releaseMountedTrees(true)
    end
end
function FellerBuncherReleaseEvent.sendEvent(vehicle, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(FellerBuncherReleaseEvent.new(vehicle), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(FellerBuncherReleaseEvent.new(vehicle))
    end
end