SaveEvent = {}
local SaveEvent_mt = Class(SaveEvent, Event)
InitStaticEventClass(SaveEvent, "SaveEvent")
function SaveEvent.emptyNew()
    -- upvalues: (copy) SaveEvent_mt
    return Event.new(SaveEvent_mt)
end
function SaveEvent.new()
    return SaveEvent.emptyNew()
end
function SaveEvent.readStream(_, _, connection)
    assert(g_currentMission:getIsServer())
    if g_currentMission:getIsServer() and (not connection:getIsServer() and g_currentMission.userManager:getIsConnectionMasterUser(connection)) then
        g_messageCenter:publish(SaveEvent, false, false)
    end
end
function SaveEvent:writeStream(streamId, connection) end
function SaveEvent:run(connection)
    printError("Error: SaveEvent is a client to server only event")
end