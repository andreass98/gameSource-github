BalerDropFromPlatformEvent = {}
local BalerDropFromPlatformEvent_mt = Class(BalerDropFromPlatformEvent, Event)
InitStaticEventClass(BalerDropFromPlatformEvent, "BalerDropFromPlatformEvent")
function BalerDropFromPlatformEvent.emptyNew()
    -- upvalues: (copy) BalerDropFromPlatformEvent_mt
    return Event.new(BalerDropFromPlatformEvent_mt)
end
function BalerDropFromPlatformEvent.new(object, waitForNextBale)
    local self = BalerDropFromPlatformEvent.emptyNew()
    self.object = object
    self.waitForNextBale = waitForNextBale
    return self
end
function BalerDropFromPlatformEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.waitForNextBale = streamReadBool(streamId)
    self:run(connection)
end
function BalerDropFromPlatformEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.waitForNextBale)
end
function BalerDropFromPlatformEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:dropBaleFromPlatform(self.waitForNextBale, true)
    end
end
function BalerDropFromPlatformEvent.sendEvent(object, waitForNextBale, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BalerDropFromPlatformEvent.new(object, waitForNextBale), nil, nil, object)
            return
        end
        g_client:getServerConnection():sendEvent(BalerDropFromPlatformEvent.new(object, waitForNextBale))
    end
end