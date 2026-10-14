PlaceableRiceFieldStateEvent = {}
local PlaceableRiceFieldStateEvent_mt = Class(PlaceableRiceFieldStateEvent, Event)
InitStaticEventClass(PlaceableRiceFieldStateEvent, "PlaceableRiceFieldStateEvent")
function PlaceableRiceFieldStateEvent.emptyNew()
    -- upvalues: (copy) PlaceableRiceFieldStateEvent_mt
    return Event.new(PlaceableRiceFieldStateEvent_mt)
end
function PlaceableRiceFieldStateEvent.new(placeableRiceField, fieldIndex)
    local self = PlaceableRiceFieldStateEvent.emptyNew()
    self.placeableRiceField = placeableRiceField
    self.fieldIndex = fieldIndex
    return self
end
function PlaceableRiceFieldStateEvent.newServerToClient(placeableRiceField, fieldIndex, fruitTypeIndex, growthStateIndex)
    local self = PlaceableRiceFieldStateEvent.emptyNew()
    self.placeableRiceField = placeableRiceField
    self.fieldIndex = fieldIndex
    self.fruitTypeIndex = fruitTypeIndex
    self.growthStateIndex = growthStateIndex
    return self
end
function PlaceableRiceFieldStateEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
    self.fieldIndex = streamReadUInt8(streamId)
    if connection:getIsServer() then
        self.fruitTypeIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
        self.growthStateIndex = streamReadUInt8(streamId)
    end
    self:run(connection)
end
function PlaceableRiceFieldStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
    streamWriteUInt8(streamId, self.fieldIndex)
    if not connection:getIsServer() then
        streamWriteUIntN(streamId, self.fruitTypeIndex, FruitTypeManager.SEND_NUM_BITS)
        streamWriteUInt8(streamId, self.growthStateIndex)
    end
end
function PlaceableRiceFieldStateEvent:run(connection)
    if self.placeableRiceField == nil or not self.placeableRiceField:getIsSynchronized() then
        return
    elseif connection:getIsServer() then
        g_messageCenter:publish(PlaceableRiceFieldStateEvent, self.fruitTypeIndex, self.growthStateIndex)
    else
        self.placeableRiceField:getRiceFieldState(self.fieldIndex, function(_, fruitTypeIndex, growthStateIndex)
            -- upvalues: (copy) connection, (copy) self
            connection:sendEvent(PlaceableRiceFieldStateEvent.newServerToClient(self.placeableRiceField, self.fieldIndex, fruitTypeIndex, growthStateIndex))
        end)
    end
end