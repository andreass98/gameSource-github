FeedingRobotStateStarting = {}
local FeedingRobotStateStarting_mt = Class(FeedingRobotStateStarting, FeedingRobotState)
function FeedingRobotStateStarting.new(feedingRobot, customMt)
    -- upvalues: (copy) FeedingRobotStateStarting_mt
    return FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateStarting_mt)
end