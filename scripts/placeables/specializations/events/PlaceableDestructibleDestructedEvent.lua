PlaceableDestructibleDestructedEvent = {}
local PlaceableDestructibleDestructedEvent_mt = Class(PlaceableDestructibleDestructedEvent, Event)
InitStaticEventClass(PlaceableDestructibleDestructedEvent, "PlaceableDestructibleDestructedEvent")
function PlaceableDestructibleDestructedEvent.emptyNew()
    -- upvalues: (copy) PlaceableDestructibleDestructedEvent_mt
    return Event.new(PlaceableDestructibleDestructedEvent_mt)
end
function PlaceableDestructibleDestructedEvent.new(placeable)
    local self = PlaceableDestructibleDestructedEvent.emptyNew()
    self.placeable = placeable
    return self
end
function PlaceableDestructibleDestructedEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function PlaceableDestructibleDestructedEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
end
function PlaceableDestructibleDestructedEvent:run(_)
    local placeable = self.placeable
    if placeable ~= nil and placeable:getIsSynchronized() then
        placeable:destructed()
    end
end