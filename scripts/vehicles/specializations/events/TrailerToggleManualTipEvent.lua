TrailerToggleManualTipEvent = {}
local TrailerToggleManualTipEvent_mt = Class(TrailerToggleManualTipEvent, Event)
InitStaticEventClass(TrailerToggleManualTipEvent, "TrailerToggleManualTipEvent")
function TrailerToggleManualTipEvent.emptyNew()
    -- upvalues: (copy) TrailerToggleManualTipEvent_mt
    return Event.new(TrailerToggleManualTipEvent_mt)
end
function TrailerToggleManualTipEvent.new(object, state)
    local self = TrailerToggleManualTipEvent.emptyNew()
    self.object = object
    self.state = state
    return self
end
function TrailerToggleManualTipEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self:run(connection)
end
function TrailerToggleManualTipEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
end
function TrailerToggleManualTipEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.state then
            self.object:startTipping(nil, true)
            return
        end
        self.object:stopTipping(true)
    end
end
function TrailerToggleManualTipEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TrailerToggleManualTipEvent.new(vehicle, state), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(TrailerToggleManualTipEvent.new(vehicle, state))
    end
end