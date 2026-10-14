UpdateSplitShapesEvent = {}
local UpdateSplitShapesEvent_mt = Class(UpdateSplitShapesEvent, Event)
InitStaticEventClass(UpdateSplitShapesEvent, "UpdateSplitShapesEvent")
function UpdateSplitShapesEvent.emptyNew()
    -- upvalues: (copy) UpdateSplitShapesEvent_mt
    return Event.new(UpdateSplitShapesEvent_mt)
end
function UpdateSplitShapesEvent.new()
    return UpdateSplitShapesEvent.emptyNew()
end
function UpdateSplitShapesEvent.readStream(_, streamId, connection)
    if connection:getIsServer() then
        readSplitShapesServerEventFromStream(streamId)
    end
end
function UpdateSplitShapesEvent.writeStream(_, streamId, connection)
    if not connection:getIsServer() then
        writeSplitShapesServerEventToStream(streamId, streamId)
    end
end
function UpdateSplitShapesEvent:run(connection)
    printError("Error: UpdateSplitShapesEvent is not allowed to be executed on a local client")
end