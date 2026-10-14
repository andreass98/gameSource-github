RollercoasterPassengerEnterResponseEvent = {}
local RollercoasterPassengerEnterResponseEvent_mt = Class(RollercoasterPassengerEnterResponseEvent, Event)
InitStaticEventClass(RollercoasterPassengerEnterResponseEvent, "RollercoasterPassengerEnterResponseEvent")
function RollercoasterPassengerEnterResponseEvent.emptyNew()
    -- upvalues: (copy) RollercoasterPassengerEnterResponseEvent_mt
    return Event.new(RollercoasterPassengerEnterResponseEvent_mt)
end
function RollercoasterPassengerEnterResponseEvent.new(rollercoaster, userId, seatIndex)
    local self = RollercoasterPassengerEnterResponseEvent.emptyNew()
    self.rollercoaster = rollercoaster
    self.userId = userId
    self.seatIndex = seatIndex
    return self
end
function RollercoasterPassengerEnterResponseEvent:readStream(streamId, connection)
    self.rollercoaster = NetworkUtil.readNodeObject(streamId)
    self.userId = User.streamReadUserId(streamId)
    self.seatIndex = streamReadUIntN(streamId, PlaceableRollercoaster.SEAT_INDEX_NUM_BITS) + 1
    self:run(connection)
end
function RollercoasterPassengerEnterResponseEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.rollercoaster)
    User.streamWriteUserId(streamId, self.userId)
    streamWriteUIntN(streamId, self.seatIndex - 1, PlaceableRollercoaster.SEAT_INDEX_NUM_BITS)
end
function RollercoasterPassengerEnterResponseEvent:run(_)
    if self.rollercoaster ~= nil and self.rollercoaster:getIsSynchronized() then
        local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByUserId(self.userId)
        local player = nil
        for _, missionPlayer in pairs(g_currentMission.playerSystem.players) do
            if missionPlayer.uniqueUserId == uniqueUserId then
                player = missionPlayer
                break
            end
        end
        player:onEnterRollercoaster(self.rollercoaster, self.seatIndex)
    end
end