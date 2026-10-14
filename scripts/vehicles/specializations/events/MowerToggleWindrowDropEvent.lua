MowerToggleWindrowDropEvent = {}
local MowerToggleWindrowDropEvent_mt = Class(MowerToggleWindrowDropEvent, Event)
InitStaticEventClass(MowerToggleWindrowDropEvent, "MowerToggleWindrowDropEvent")
function MowerToggleWindrowDropEvent.emptyNew()
    -- upvalues: (copy) MowerToggleWindrowDropEvent_mt
    return Event.new(MowerToggleWindrowDropEvent_mt)
end
function MowerToggleWindrowDropEvent.new(object, useMowerWindrowDropAreas)
    local self = MowerToggleWindrowDropEvent.emptyNew()
    self.object = object
    self.useMowerWindrowDropAreas = useMowerWindrowDropAreas
    return self
end
function MowerToggleWindrowDropEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.useMowerWindrowDropAreas = streamReadBool(streamId)
    self:run(connection)
end
function MowerToggleWindrowDropEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.useMowerWindrowDropAreas)
end
function MowerToggleWindrowDropEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setUseMowerWindrowDropAreas(self.useMowerWindrowDropAreas, true)
    end
end
function MowerToggleWindrowDropEvent.sendEvent(vehicle, useMowerWindrowDropAreas, noEventSend)
    if useMowerWindrowDropAreas ~= vehicle.useMowerWindrowDropAreas and (noEventSend == nil or noEventSend == false) then
        if g_server ~= nil then
            g_server:broadcastEvent(MowerToggleWindrowDropEvent.new(vehicle, useMowerWindrowDropAreas), nil, nil, vehicle)
            return
        end
        g_client:getServerConnection():sendEvent(MowerToggleWindrowDropEvent.new(vehicle, useMowerWindrowDropAreas))
    end
end