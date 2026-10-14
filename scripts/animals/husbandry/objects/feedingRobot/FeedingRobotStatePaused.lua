FeedingRobotStatePaused = {}
local FeedingRobotStatePaused_mt = Class(FeedingRobotStatePaused, FeedingRobotState)
function FeedingRobotStatePaused.new(feedingRobot, customMt)
    -- upvalues: (copy) FeedingRobotStatePaused_mt
    local self = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStatePaused_mt)
    self.feedingRobot = feedingRobot
    return self
end
function FeedingRobotStatePaused:isDone()
    if self.feedingRobot.requestedStart then
        return FeedingRobotStatePaused:superClass().isDone(self)
    else
        return false
    end
end
function FeedingRobotStatePaused:deactivate()
    self.feedingRobot.requestedStart = false
    FeedingRobotStatePaused:superClass().deactivate(self)
end
function FeedingRobotStatePaused:raiseActive()
    return false
end