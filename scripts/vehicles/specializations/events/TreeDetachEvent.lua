TreeDetachEvent = {}
local TreeDetachEvent_mt = Class(TreeDetachEvent, Event)
InitStaticEventClass(TreeDetachEvent, "TreeDetachEvent")
function TreeDetachEvent.emptyNew()
    -- upvalues: (copy) TreeDetachEvent_mt
    return Event.new(TreeDetachEvent_mt)
end
function TreeDetachEvent.new(object, ropeIndex)
    local self = TreeDetachEvent.emptyNew()
    self.object = object
    self.ropeIndex = ropeIndex
    return self
end
function TreeDetachEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    if streamReadBool(streamId) then
        self.ropeIndex = streamReadUIntN(streamId, 4)
    end
    self:run(connection)
end
function TreeDetachEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    if streamWriteBool(streamId, self.ropeIndex ~= nil) then
        streamWriteUIntN(streamId, self.ropeIndex, 4)
    end
end
function TreeDetachEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.object.detachTreeFromCarriage ~= nil then
            self.object:detachTreeFromCarriage(self.ropeIndex, true)
            return
        end
        if self.object.detachTreeFromWinch ~= nil then
            self.object:detachTreeFromWinch(self.ropeIndex, true)
        end
    end
end
function TreeDetachEvent.sendEvent(vehicle, ropeIndex, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TreeDetachEvent.new(vehicle, ropeIndex), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(TreeDetachEvent.new(vehicle, ropeIndex))
    end
end