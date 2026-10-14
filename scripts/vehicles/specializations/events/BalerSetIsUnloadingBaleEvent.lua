BalerSetIsUnloadingBaleEvent = {}
local BalerSetIsUnloadingBaleEvent_mt = Class(BalerSetIsUnloadingBaleEvent, Event)
InitStaticEventClass(BalerSetIsUnloadingBaleEvent, "BalerSetIsUnloadingBaleEvent")
function BalerSetIsUnloadingBaleEvent.emptyNew()
    -- upvalues: (copy) BalerSetIsUnloadingBaleEvent_mt
    return Event.new(BalerSetIsUnloadingBaleEvent_mt)
end
function BalerSetIsUnloadingBaleEvent.new(object, isUnloadingBale)
    local self = BalerSetIsUnloadingBaleEvent.emptyNew()
    self.object = object
    self.isUnloadingBale = isUnloadingBale
    return self
end
function BalerSetIsUnloadingBaleEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.isUnloadingBale = streamReadBool(streamId)
    self:run(connection)
end
function BalerSetIsUnloadingBaleEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.isUnloadingBale)
end
function BalerSetIsUnloadingBaleEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setIsUnloadingBale(self.isUnloadingBale, true)
    end
end
function BalerSetIsUnloadingBaleEvent.sendEvent(object, isUnloadingBale, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BalerSetIsUnloadingBaleEvent.new(object, isUnloadingBale), nil, nil, object)
            return
        end
        g_client:getServerConnection():sendEvent(BalerSetIsUnloadingBaleEvent.new(object, isUnloadingBale))
    end
end