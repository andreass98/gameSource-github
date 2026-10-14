FootballFieldResetBallEvent = {}
local FootballFieldResetBallEvent_mt = Class(FootballFieldResetBallEvent, Event)
InitStaticEventClass(FootballFieldResetBallEvent, "FootballFieldResetBallEvent")
function FootballFieldResetBallEvent.emptyNew()
    -- upvalues: (copy) FootballFieldResetBallEvent_mt
    return Event.new(FootballFieldResetBallEvent_mt)
end
function FootballFieldResetBallEvent.new(footballField)
    local self = FootballFieldResetBallEvent.emptyNew()
    self.footballField = footballField
    return self
end
function FootballFieldResetBallEvent:readStream(streamId, connection)
    self.footballField = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end
function FootballFieldResetBallEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.footballField)
end
function FootballFieldResetBallEvent:run(_)
    if self.footballField ~= nil then
        self.footballField:onResetBall()
    end
end