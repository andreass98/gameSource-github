EnterablePassengerEnterRequestEvent = {}
local EnterablePassengerEnterRequestEvent_mt = Class(EnterablePassengerEnterRequestEvent, Event)
InitStaticEventClass(EnterablePassengerEnterRequestEvent, "EnterablePassengerEnterRequestEvent")
function EnterablePassengerEnterRequestEvent.emptyNew()
    -- upvalues: (copy) EnterablePassengerEnterRequestEvent_mt
    return Event.new(EnterablePassengerEnterRequestEvent_mt)
end
function EnterablePassengerEnterRequestEvent.new(object, seatIndex)
    local self = EnterablePassengerEnterRequestEvent.emptyNew()
    self.object = object
    self.objectId = NetworkUtil.getObjectId(self.object)
    self.seatIndex = seatIndex
    return self
end
function EnterablePassengerEnterRequestEvent:readStream(streamId, connection)
    self.objectId = NetworkUtil.readNodeObjectId(streamId)
    self.seatIndex = streamReadUIntN(streamId, EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS) + 1
    self.object = NetworkUtil.getObject(self.objectId)
    self:run(connection)
end
function EnterablePassengerEnterRequestEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObjectId(streamId, self.objectId)
    streamWriteUIntN(streamId, math.clamp(self.seatIndex - 1, 0, 2 ^ EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS - 1), EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS)
end
function EnterablePassengerEnterRequestEvent:run(connection)
    if self.object ~= nil and (self.object:getIsSynchronized() and self.object:getIsPassengerSeatIndexAvailable(self.seatIndex)) then
        local userId = g_currentMission.userManager:getUserIdByConnection(connection)
        g_server:broadcastEvent(EnterablePassengerEnterResponseEvent.new(self.objectId, false, self.seatIndex, userId), true, connection)
        connection:sendEvent(EnterablePassengerEnterResponseEvent.new(self.objectId, true, self.seatIndex, userId))
    end
end