HusbandryCancelCreationEvent = {}
local HusbandryCancelCreationEvent_mt = Class(HusbandryCancelCreationEvent, Event)
InitStaticEventClass(HusbandryCancelCreationEvent, "HusbandryCancelCreationEvent")
function HusbandryCancelCreationEvent.emptyNew()
    -- upvalues: (copy) HusbandryCancelCreationEvent_mt
    return Event.new(HusbandryCancelCreationEvent_mt)
end
function HusbandryCancelCreationEvent.new(placeableId)
    local self = HusbandryCancelCreationEvent.emptyNew()
    self.placeableId = placeableId
    return self
end
function HusbandryCancelCreationEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObjectId(streamId)
    self:run(connection)
end
function HusbandryCancelCreationEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObjectId(streamId, self.placeableId)
end
function HusbandryCancelCreationEvent:run(connection)
    assert(not connection:getIsServer(), "HusbandryCancelCreationEvent is a client to server event only")
    if self.placeable ~= nil and self.placeable.createMeadow ~= nil then
        self.placeable:createMeadow(false)
    end
end