PlaceableRiceFieldEffectStateEvent = {}
local PlaceableRiceFieldEffectStateEvent_mt = Class(PlaceableRiceFieldEffectStateEvent, Event)
InitStaticEventClass(PlaceableRiceFieldEffectStateEvent, "PlaceableRiceFieldEffectStateEvent")
function PlaceableRiceFieldEffectStateEvent.emptyNew()
    -- upvalues: (copy) PlaceableRiceFieldEffectStateEvent_mt
    return Event.new(PlaceableRiceFieldEffectStateEvent_mt)
end
function PlaceableRiceFieldEffectStateEvent.new(placeableRiceField, fieldIndex, isFilling, isEmptying)
    local self = PlaceableRiceFieldEffectStateEvent.emptyNew()
    self.placeableRiceField = placeableRiceField
    self.fieldIndex = fieldIndex
    self.isFilling = isFilling
    self.isEmptying = isEmptying
    return self
end
function PlaceableRiceFieldEffectStateEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
    self.fieldIndex = streamReadUInt8(streamId)
    self.isFilling = streamReadBool(streamId)
    self.isEmptying = streamReadBool(streamId)
    self:run(connection)
end
function PlaceableRiceFieldEffectStateEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
    streamWriteUInt8(streamId, self.fieldIndex)
    streamWriteBool(streamId, self.isFilling)
    streamWriteBool(streamId, self.isEmptying)
end
function PlaceableRiceFieldEffectStateEvent:run(_)
    if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
        self.placeableRiceField:setEffectVisibility(self.fieldIndex, self.isFilling, self.isEmptying)
    end
end