EnterablePassengerEnterResponseEvent = {}
local EnterablePassengerEnterResponseEvent_mt = Class(EnterablePassengerEnterResponseEvent, Event)
InitStaticEventClass(EnterablePassengerEnterResponseEvent, "EnterablePassengerEnterResponseEvent")
function EnterablePassengerEnterResponseEvent.emptyNew()
    -- upvalues: (copy) EnterablePassengerEnterResponseEvent_mt
    return Event.new(EnterablePassengerEnterResponseEvent_mt)
end
function EnterablePassengerEnterResponseEvent.new(id, isOwner, seatIndex, userId)
    local self = EnterablePassengerEnterResponseEvent.emptyNew()
    self.id = id
    self.isOwner = isOwner
    self.seatIndex = seatIndex
    self.userId = userId
    return self
end
function EnterablePassengerEnterResponseEvent:readStream(streamId, connection)
    self.id = NetworkUtil.readNodeObjectId(streamId)
    self.isOwner = streamReadBool(streamId)
    self.seatIndex = streamReadUIntN(streamId, EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS) + 1
    self.userId = User.streamReadUserId(streamId)
    self:run(connection)
end
function EnterablePassengerEnterResponseEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObjectId(streamId, self.id)
    streamWriteBool(streamId, self.isOwner)
    streamWriteUIntN(streamId, math.clamp(self.seatIndex - 1, 0, 2 ^ EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS - 1), EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS)
    User.streamWriteUserId(streamId, self.userId)
end
function EnterablePassengerEnterResponseEvent:run(_)
    local object = NetworkUtil.getObject(self.id)
    if object ~= nil and object:getIsSynchronized() then
        local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByUserId(self.userId)
        local player = nil
        for _, missionPlayer in pairs(g_currentMission.playerSystem.players) do
            if missionPlayer.uniqueUserId == uniqueUserId then
                player = missionPlayer
                break
            end
        end
        player:onEnterVehicleAsPassenger(object, self.seatIndex)
    end
end