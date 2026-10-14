FeedingRobotStateEvent = {}
local FeedingRobotStateEvent_mt = Class(FeedingRobotStateEvent, Event)
InitStaticEventClass(FeedingRobotStateEvent, "FeedingRobotStateEvent")
function FeedingRobotStateEvent.emptyNew()
    -- upvalues: (copy) FeedingRobotStateEvent_mt
    return Event.new(FeedingRobotStateEvent_mt)
end
function FeedingRobotStateEvent.new(feedingRobot, state)
    local self = FeedingRobotStateEvent.emptyNew()
    self.feedingRobot = feedingRobot
    self.state = state
    return self
end
function FeedingRobotStateEvent:readStream(streamId, connection)
    self.feedingRobot = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUInt8(streamId)
    self:run(connection)
end
function FeedingRobotStateEvent:writeStream(streamId, _)
    NetworkUtil.writeNodeObject(streamId, self.feedingRobot)
    streamWriteUInt8(streamId, self.state)
end
function FeedingRobotStateEvent:run(_)
    if self.feedingRobot ~= nil then
        self.feedingRobot:setState(self.state)
    end
end