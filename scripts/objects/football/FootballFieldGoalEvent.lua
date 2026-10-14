FootballFieldGoalEvent = {}
local FootballFieldGoalEvent_mt = Class(FootballFieldGoalEvent, Event)
InitStaticEventClass(FootballFieldGoalEvent, "FootballFieldGoalEvent")
function FootballFieldGoalEvent.emptyNew()
    -- upvalues: (copy) FootballFieldGoalEvent_mt
    return Event.new(FootballFieldGoalEvent_mt)
end
function FootballFieldGoalEvent.new(footballField, isBlueGoal, scoreBlue, scoreRed)
    local self = FootballFieldGoalEvent.emptyNew()
    self.footballField = footballField
    self.isBlueGoal = isBlueGoal
    self.scoreBlue = scoreBlue > 99 and 0 or scoreBlue
    self.scoreRed = scoreRed > 99 and 0 or scoreRed
    return self
end
function FootballFieldGoalEvent:readStream(streamId, connection)
    self.footballField = NetworkUtil.readNodeObject(streamId)
    self.isBlueGoal = streamReadBool(streamId)
    self.scoreBlue = streamReadUIntN(streamId, 7)
    self.scoreRed = streamReadUIntN(streamId, 7)
    self:run(connection)
end
function FootballFieldGoalEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.footballField)
    streamWriteBool(streamId, self.isBlueGoal)
    streamWriteUIntN(streamId, self.scoreBlue, 7)
    streamWriteUIntN(streamId, self.scoreRed, 7)
end
function FootballFieldGoalEvent:run(_)
    if self.footballField ~= nil then
        self.footballField:onGoal(self.isBlueGoal, self.scoreBlue, self.scoreRed)
    end
end