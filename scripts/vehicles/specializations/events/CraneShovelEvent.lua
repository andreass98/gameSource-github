CraneShovelEvent = {}
local CraneShovelEvent_mt = Class(CraneShovelEvent, Event)
InitStaticEventClass(CraneShovelEvent, "CraneShovelEvent")
function CraneShovelEvent.emptyNew()
    -- upvalues: (copy) CraneShovelEvent_mt
    return Event.new(CraneShovelEvent_mt)
end
function CraneShovelEvent.new(object, state)
    local self = CraneShovelEvent.emptyNew()
    self.object = object
    self.state = state
    return self
end
function CraneShovelEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self:run(connection)
end
function CraneShovelEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
end
function CraneShovelEvent:run(_)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setCraneShovelState(self.state, nil, true)
    end
end
function CraneShovelEvent.sendEvent(object, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(CraneShovelEvent.new(object, state), nil, nil, object)
            return
        end
        g_client:getServerConnection():sendEvent(CraneShovelEvent.new(object, state))
    end
end