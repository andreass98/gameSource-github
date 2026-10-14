HandsPickUpFailedEvent = {}
local HandsPickUpFailedEvent_mt = Class(HandsPickUpFailedEvent, Event)
InitStaticEventClass(HandsPickUpFailedEvent, "HandsPickUpFailedEvent")
function HandsPickUpFailedEvent.emptyNew()
    -- upvalues: (copy) HandsPickUpFailedEvent_mt
    return Event.new(HandsPickUpFailedEvent_mt)
end
function HandsPickUpFailedEvent.new(hands)
    local self = HandsPickUpFailedEvent.emptyNew()
    self.hands = hands
    return self
end
function HandsPickUpFailedEvent:readStream(streamId, connection)
    self.hands = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function HandsPickUpFailedEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.hands)
end
function HandsPickUpFailedEvent:run(connection)
    assert(connection:getIsServer(), "HandsPickUpFailedEvent is a server to client only event")
    if self.hands ~= nil and self.hands:getIsSynchronized() then
        self.hands:pickupFailed()
    end
end