PlaceableRiceFieldFieldAnswerEvent = {}
local PlaceableRiceFieldFieldAnswerEvent_mt = Class(PlaceableRiceFieldFieldAnswerEvent, Event)
InitStaticEventClass(PlaceableRiceFieldFieldAnswerEvent, "PlaceableRiceFieldFieldAnswerEvent")
function PlaceableRiceFieldFieldAnswerEvent.emptyNew()
    -- upvalues: (copy) PlaceableRiceFieldFieldAnswerEvent_mt
    return Event.new(PlaceableRiceFieldFieldAnswerEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function PlaceableRiceFieldFieldAnswerEvent.new(placeableRiceField, statusCode)
    local self = PlaceableRiceFieldFieldAnswerEvent.emptyNew()
    self.placeableRiceField = placeableRiceField
    self.statusCode = statusCode
    return self
end
function PlaceableRiceFieldFieldAnswerEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
    self.statusCode = streamReadUInt8(streamId)
    self:run(connection)
end
function PlaceableRiceFieldFieldAnswerEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
    streamWriteUInt8(streamId, self.statusCode)
end
function PlaceableRiceFieldFieldAnswerEvent:run(_)
    if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
        g_messageCenter:publish(PlaceableRiceFieldFieldAnswerEvent, self.statusCode)
    end
end