PlaceableTrainSystemSellEvent = {}
local PlaceableTrainSystemSellEvent_mt = Class(PlaceableTrainSystemSellEvent, Event)
InitStaticEventClass(PlaceableTrainSystemSellEvent, "PlaceableTrainSystemSellEvent")
function PlaceableTrainSystemSellEvent.emptyNew()
    -- upvalues: (copy) PlaceableTrainSystemSellEvent_mt
    return Event.new(PlaceableTrainSystemSellEvent_mt)
end
function PlaceableTrainSystemSellEvent.new(object)
    local self = PlaceableTrainSystemSellEvent.emptyNew()
    self.object = object
    return self
end
function PlaceableTrainSystemSellEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function PlaceableTrainSystemSellEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.object)
end
function PlaceableTrainSystemSellEvent:run(connection)
    if not connection:getIsServer() and (self.object ~= nil and self.object:getIsSynchronized()) then
        self.object:sellGoods()
    end
end