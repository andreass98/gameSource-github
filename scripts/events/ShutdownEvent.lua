ShutdownEvent = {}
local ShutdownEvent_mt = Class(ShutdownEvent, Event)
InitStaticEventClass(ShutdownEvent, "ShutdownEvent")
function ShutdownEvent.emptyNew()
    -- upvalues: (copy) ShutdownEvent_mt
    return Event.new(ShutdownEvent_mt)
end
function ShutdownEvent.new()
    return ShutdownEvent.emptyNew()
end
function ShutdownEvent:readStream(_, connection)
    self:run(connection)
end
function ShutdownEvent:writeStream(streamId, connection) end
function ShutdownEvent.run(_, connection)
    g_currentMission:onShutdownEvent(connection)
end