HandToolSetHolderEvent = {}
local HandToolSetHolderEvent_mt = Class(HandToolSetHolderEvent, Event)
InitStaticEventClass(HandToolSetHolderEvent, "HandToolSetHolderEvent")
function HandToolSetHolderEvent.emptyNew()
    -- upvalues: (copy) HandToolSetHolderEvent_mt
    return Event.new(HandToolSetHolderEvent_mt)
end
function HandToolSetHolderEvent.new(handTool, holder)
    local self = HandToolSetHolderEvent.emptyNew()
    self.handTool = handTool
    self.holder = holder
    self.hasHolder = holder ~= nil
    return self
end
function HandToolSetHolderEvent:readStream(streamId, connection)
    self.handTool = NetworkUtil.readNodeObject(streamId)
    self.hasHolder = streamReadBool(streamId)
    if self.hasHolder then
        self.holder = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end
function HandToolSetHolderEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.handTool)
    if streamWriteBool(streamId, self.holder ~= nil) then
        NetworkUtil.writeNodeObject(streamId, self.holder)
    end
end
function HandToolSetHolderEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection)
    end
    if self.handTool ~= nil and self.handTool:getIsSynchronized() and (self.hasHolder and self.holder ~= nil or not self.hasHolder) then
        self.handTool:setHolder(self.holder, true)
    end
    g_messageCenter:publish(HandToolSetHolderEvent)
end
function HandToolSetHolderEvent.sendEvent(handTool, holder, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(HandToolSetHolderEvent.new(handTool, holder))
            return
        end
        g_client:getServerConnection():sendEvent(HandToolSetHolderEvent.new(handTool, holder))
    end
end