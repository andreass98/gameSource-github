FeedingRobotStateFinished = {}
local FeedingRobotStateFinished_mt = Class(FeedingRobotStateFinished, FeedingRobotState)
function FeedingRobotStateFinished.new(feedingRobot, customMt)
    -- upvalues: (copy) FeedingRobotStateFinished_mt
    return FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateFinished_mt)
end