AISetModeEvent = {}
local AISetModeEvent_mt = Class(AISetModeEvent, Event)
InitStaticEventClass(AISetModeEvent, "AISetModeEvent")
function AISetModeEvent.emptyNew()
    -- upvalues: (copy) AISetModeEvent_mt
    return Event.new(AISetModeEvent_mt)
end
function AISetModeEvent.new(vehicle, aiMode)
    local self = AISetModeEvent.emptyNew()
    self.vehicle = vehicle
    self.aiMode = aiMode
    return self
end
function AISetModeEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.aiMode = streamReadUIntN(streamId, AIModeSelection.NUM_BITS) + 1
    self:run(connection)
end
function AISetModeEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.aiMode - 1, AIModeSelection.NUM_BITS)
end
function AISetModeEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setAIModeSelection(self.aiMode, true)
    end
    if not connection:getIsServer() then
        g_server:broadcastEvent(AISetModeEvent.new(self.vehicle, self.aiMode), nil, connection, self.vehicle)
    end
end
function AISetModeEvent.sendEvent(vehicle, aiMode, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AISetModeEvent.new(vehicle, aiMode), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(AISetModeEvent.new(vehicle, aiMode))
    end
end