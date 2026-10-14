SetTurnedOnEvent = {}
local SetTurnedOnEvent_mt = Class(SetTurnedOnEvent, Event)
InitStaticEventClass(SetTurnedOnEvent, "SetTurnedOnEvent")
function SetTurnedOnEvent.emptyNew()
    -- upvalues: (copy) SetTurnedOnEvent_mt
    return Event.new(SetTurnedOnEvent_mt)
end
function SetTurnedOnEvent.new(object, isTurnedOn)
    local self = SetTurnedOnEvent.emptyNew()
    self.object = object
    self.isTurnedOn = isTurnedOn
    return self
end
function SetTurnedOnEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.isTurnedOn = streamReadBool(streamId)
    self:run(connection)
end
function SetTurnedOnEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.isTurnedOn)
end
function SetTurnedOnEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setIsTurnedOn(self.isTurnedOn, true)
    end
end
function SetTurnedOnEvent.sendEvent(vehicle, isTurnedOn, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetTurnedOnEvent.new(vehicle, isTurnedOn), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(SetTurnedOnEvent.new(vehicle, isTurnedOn))
    end
end