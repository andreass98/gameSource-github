PlaceableRiceFieldFieldEvent = {}
local PlaceableRiceFieldFieldEvent_mt = Class(PlaceableRiceFieldFieldEvent, Event)
InitStaticEventClass(PlaceableRiceFieldFieldEvent, "PlaceableRiceFieldFieldEvent")
function PlaceableRiceFieldFieldEvent.emptyNew()
    -- upvalues: (copy) PlaceableRiceFieldFieldEvent_mt
    return Event.new(PlaceableRiceFieldFieldEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function PlaceableRiceFieldFieldEvent.new(placeableRiceField, field)
    local self = PlaceableRiceFieldFieldEvent.emptyNew()
    self.placeableRiceField = placeableRiceField
    self.field = field
    return self
end
function PlaceableRiceFieldFieldEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
    local height = streamReadFloat32(streamId)
    local field = self.placeableRiceField:createNewField(height)
    local numVertices = streamReadUInt16(streamId)
    field.polygon = Polygon2D.new(numVertices)
    for i = 1, numVertices do
        field.polygon:addPos(streamReadFloat32(streamId), streamReadFloat32(streamId))
    end
    field.waterHeight = streamReadFloat32(streamId)
    self.field = field
    self:run(connection)
end
function PlaceableRiceFieldFieldEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
    streamWriteFloat32(streamId, self.field.height)
    streamWriteUInt16(streamId, self.field.polygon:getNumVertices())
    for _, vertex in ipairs(self.field.polygon:getVertices()) do
        streamWriteFloat32(streamId, vertex)
    end
    streamWriteFloat32(streamId, self.field.waterHeight)
end
function PlaceableRiceFieldFieldEvent:run(connection)
    if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
        self.placeableRiceField:finalizeNewField(self.field, true, function(statusCode)
            -- upvalues: (copy) connection, (copy) self
            connection:sendEvent(PlaceableRiceFieldFieldAnswerEvent.new(self.placeableRiceField, statusCode))
        end)
    end
end