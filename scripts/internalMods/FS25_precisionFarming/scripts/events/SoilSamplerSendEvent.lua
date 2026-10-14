SoilSamplerSendEvent = {}
local SoilSamplerSendEvent_mt = Class(SoilSamplerSendEvent, Event)
InitEventClass(SoilSamplerSendEvent, "SoilSamplerSendEvent")
function SoilSamplerSendEvent.emptyNew()
    -- upvalues: (copy) SoilSamplerSendEvent_mt
    return Event.new(SoilSamplerSendEvent_mt)
end
function SoilSamplerSendEvent.new(object)
    local self = SoilSamplerSendEvent.emptyNew()
    self.object = object
    return self
end
function SoilSamplerSendEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function SoilSamplerSendEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function SoilSamplerSendEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:sendTakenSoilSamples(true)
    end
end
function SoilSamplerSendEvent.sendEvent(object, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SoilSamplerSendEvent.new(object), nil, nil, object)
            return
        end
        g_client:getServerConnection():sendEvent(SoilSamplerSendEvent.new(object))
    end
end