FellerBuncherCutEvent = {}
local FellerBuncherCutEvent_mt = Class(FellerBuncherCutEvent, Event)
InitStaticEventClass(FellerBuncherCutEvent, "FellerBuncherCutEvent")
function FellerBuncherCutEvent.emptyNew()
    -- upvalues: (copy) FellerBuncherCutEvent_mt
    return Event.new(FellerBuncherCutEvent_mt)
end
function FellerBuncherCutEvent.new(object)
    local self = FellerBuncherCutEvent.emptyNew()
    self.object = object
    return self
end
function FellerBuncherCutEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function FellerBuncherCutEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function FellerBuncherCutEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:cutTree(true)
    end
end
function FellerBuncherCutEvent.sendEvent(vehicle, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(FellerBuncherCutEvent.new(vehicle), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(FellerBuncherCutEvent.new(vehicle))
    end
end