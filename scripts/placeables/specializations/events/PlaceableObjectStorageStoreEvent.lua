PlaceableObjectStorageStoreEvent = {}
local PlaceableObjectStorageStoreEvent_mt = Class(PlaceableObjectStorageStoreEvent, Event)
InitStaticEventClass(PlaceableObjectStorageStoreEvent, "PlaceableObjectStorageStoreEvent")
function PlaceableObjectStorageStoreEvent.emptyNew()
    -- upvalues: (copy) PlaceableObjectStorageStoreEvent_mt
    return Event.new(PlaceableObjectStorageStoreEvent_mt)
end
function PlaceableObjectStorageStoreEvent.new(placeable)
    local self = PlaceableObjectStorageStoreEvent.emptyNew()
    self.placeable = placeable
    return self
end
function PlaceableObjectStorageStoreEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function PlaceableObjectStorageStoreEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
end
function PlaceableObjectStorageStoreEvent:run(_)
    if self.placeable ~= nil and (self.placeable:getIsSynchronized() and self.placeable.storePendingManualObjects ~= nil) then
        self.placeable:storePendingManualObjects()
    end
end