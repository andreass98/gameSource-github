ConnectionRequestAnswerEvent = {}
local ConnectionRequestAnswerEvent_mt = Class(ConnectionRequestAnswerEvent, Event)
InitStaticEventClass(ConnectionRequestAnswerEvent, "ConnectionRequestAnswerEvent")
ConnectionRequestAnswerEvent.ANSWER_OK = 0
ConnectionRequestAnswerEvent.ANSWER_DENIED = 1
ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD = 2
ConnectionRequestAnswerEvent.ANSWER_FULL = 3
ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED = 4
ConnectionRequestAnswerEvent.ALREADY_IN_USE = 5
ConnectionRequestAnswerEvent.SLOT_LIMIT_REACHED = 6
ConnectionRequestAnswerEvent.MATCH_IN_PROGRESS = 7
function ConnectionRequestAnswerEvent.emptyNew()
    -- upvalues: (copy) ConnectionRequestAnswerEvent_mt
    return Event.new(ConnectionRequestAnswerEvent_mt)
end
function ConnectionRequestAnswerEvent.new(answer, economicDifficulty, timeScale, isDedicatedServer, userId, playerName, knownPlayer)
    local self = ConnectionRequestAnswerEvent.emptyNew()
    self.answer = answer
    self.economicDifficulty = economicDifficulty
    self.timeScale = timeScale
    self.isDedicatedServer = isDedicatedServer
    self.userId = userId
    self.playerName = playerName
    self.knownPlayer = knownPlayer
    return self
end
function ConnectionRequestAnswerEvent:readStream(streamId, connection)
    self.answer = streamReadUIntN(streamId, 4)
    if self.answer == ConnectionRequestAnswerEvent.ANSWER_OK then
        self.economicDifficulty = EconomicDifficulty.readStream(streamId)
        self.timeScale = streamReadFloat32(streamId)
        self.isDedicatedServer = streamReadBool(streamId)
        self.userId = User.streamReadUserId(streamId)
        self.playerName = streamReadString(streamId)
        self.knownPlayer = streamReadBool(streamId)
        g_currentMission.foliageSystem:streamReadModFoliageTypes(streamId, connection)
    end
    self:run(connection)
end
function ConnectionRequestAnswerEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.answer, 4)
    if self.answer == ConnectionRequestAnswerEvent.ANSWER_OK then
        EconomicDifficulty.writeStream(streamId, self.economicDifficulty)
        streamWriteFloat32(streamId, self.timeScale)
        streamWriteBool(streamId, self.isDedicatedServer)
        User.streamWriteUserId(streamId, self.userId)
        streamWriteString(streamId, self.playerName)
        streamWriteBool(streamId, self.knownPlayer)
        g_currentMission.foliageSystem:streamWriteModFoliageTypes(streamId, connection)
    end
end
function ConnectionRequestAnswerEvent:run(connection)
    g_currentMission:onConnectionRequestAnswer(connection, self.answer, self.economicDifficulty, self.timeScale, self.isDedicatedServer, self.userId, self.playerName, self.knownPlayer)
end