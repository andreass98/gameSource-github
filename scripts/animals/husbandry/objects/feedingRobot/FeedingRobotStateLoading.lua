FeedingRobotStateLoading = {}
local FeedingRobotStateLoading_mt = Class(FeedingRobotStateLoading, FeedingRobotState)
function FeedingRobotStateLoading.new(feedingRobot, customMt)
    -- upvalues: (copy) FeedingRobotStateLoading_mt
    local self = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateLoading_mt)
    self.feedingRobot = feedingRobot
    return self
end
function FeedingRobotStateLoading:isDone()
    if self.feedingRobot.isLoadingFinished then
        return FeedingRobotStateLoading:superClass().isDone(self)
    else
        return false
    end
end
function FeedingRobotStateLoading:raiseActive()
    return false
end