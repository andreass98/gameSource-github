PalletFillerStateEvent = {}
local PalletFillerStateEvent_mt = Class(PalletFillerStateEvent, Event)
InitStaticEventClass(PalletFillerStateEvent, "PalletFillerStateEvent")
function PalletFillerStateEvent.emptyNew()
    -- upvalues: (copy) PalletFillerStateEvent_mt
    return Event.new(PalletFillerStateEvent_mt)
end
function PalletFillerStateEvent.new(object, state)
    local self = PalletFillerStateEvent.emptyNew()
    self.object = object
    self.state = state
    return self
end
function PalletFillerStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = PalletFillerState.readStream(streamId)
    self:run(connection)
end
function PalletFillerStateEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    PalletFillerState.writeStream(streamId, self.state)
end
function PalletFillerStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPalletFillerState(self.state, false, true)
    end
end
function PalletFillerStateEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PalletFillerStateEvent.new(vehicle, state), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(PalletFillerStateEvent.new(vehicle, state))
    end
end