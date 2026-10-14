PlaceableRiceFieldRemoveFieldEvent = {}
local PlaceableRiceFieldRemoveFieldEvent_mt = Class(PlaceableRiceFieldRemoveFieldEvent, Event)
InitStaticEventClass(PlaceableRiceFieldRemoveFieldEvent, "PlaceableRiceFieldRemoveFieldEvent")
function PlaceableRiceFieldRemoveFieldEvent.emptyNew()
    -- upvalues: (copy) PlaceableRiceFieldRemoveFieldEvent_mt
    return Event.new(PlaceableRiceFieldRemoveFieldEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function PlaceableRiceFieldRemoveFieldEvent.new(placeableRiceField, fieldIndex)
    local self = PlaceableRiceFieldRemoveFieldEvent.emptyNew()
    self.placeableRiceField = placeableRiceField
    self.fieldIndex = fieldIndex
    return self
end
function PlaceableRiceFieldRemoveFieldEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
    self.fieldIndex = streamReadUInt8(streamId)
    self:run(connection)
end
function PlaceableRiceFieldRemoveFieldEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
    streamWriteUInt8(streamId, self.fieldIndex)
end
function PlaceableRiceFieldRemoveFieldEvent:run(connection)
    if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
        self.placeableRiceField:removeFieldByIndex(self.fieldIndex)
        if not connection:getIsServer() then
            g_server:broadcastEvent(self)
        end
    end
end