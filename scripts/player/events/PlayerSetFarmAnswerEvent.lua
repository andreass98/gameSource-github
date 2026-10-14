PlayerSetFarmAnswerEvent = {}
local PlayerSetFarmAnswerEvent_mt = Class(PlayerSetFarmAnswerEvent, Event)
InitStaticEventClass(PlayerSetFarmAnswerEvent, "PlayerSetFarmAnswerEvent")
PlayerSetFarmAnswerEvent.STATE = {
    ["OK"] = 1,
    ["PASSWORD_REQUIRED"] = 2
}
PlayerSetFarmAnswerEvent.SEND_NUM_BITS = 2
function PlayerSetFarmAnswerEvent.emptyNew()
    -- upvalues: (copy) PlayerSetFarmAnswerEvent_mt
    return Event.new(PlayerSetFarmAnswerEvent_mt)
end
function PlayerSetFarmAnswerEvent.new(answerState, farmId, password)
    local self = PlayerSetFarmAnswerEvent.emptyNew()
    self.answerState = answerState
    self.farmId = farmId
    self.password = password
    return self
end
function PlayerSetFarmAnswerEvent:writeStream(streamId, _)
    streamWriteUIntN(streamId, self.answerState, PlayerSetFarmAnswerEvent.SEND_NUM_BITS)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    if streamWriteBool(streamId, self.answerState == PlayerSetFarmAnswerEvent.STATE.OK and self.password ~= nil) then
        streamWriteString(streamId, self.password)
    end
end
function PlayerSetFarmAnswerEvent:readStream(streamId, connection)
    self.answerState = streamReadUIntN(streamId, PlayerSetFarmAnswerEvent.SEND_NUM_BITS)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    if streamReadBool(streamId) then
        self.password = streamReadString(streamId)
    end
    self:run(connection)
end
function PlayerSetFarmAnswerEvent:run(connection)
    if connection:getIsServer() then
        if self.answerState == PlayerSetFarmAnswerEvent.STATE.OK then
            g_messageCenter:publish(PlayerSetFarmAnswerEvent, self.answerState, self.farmId, self.password)
        elseif self.answerState == PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED then
            g_messageCenter:publish(PlayerSetFarmAnswerEvent, self.answerState, self.farmId)
        end
    else
        Logging.devWarning("PlayerSetFarmAnswerEvent is a server to client only event")
        return
    end
end