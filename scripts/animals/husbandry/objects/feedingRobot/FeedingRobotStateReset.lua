FeedingRobotStateReset = {}
local FeedingRobotStateReset_mt = Class(FeedingRobotStateReset, FeedingRobotState)
function FeedingRobotStateReset.new(feedingRobot, customMt)
    -- upvalues: (copy) FeedingRobotStateReset_mt
    return FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateReset_mt)
end
function FeedingRobotStateReset:isDone()
    return FeedingRobotStateReset:superClass().isDone(self)
end
function FeedingRobotStateReset:activate()
    FeedingRobotStateReset:superClass().activate(self)
end
function FeedingRobotStateReset:deactivate()
    g_animationManager:stopAnimations(self.feedingRobot.robot.mixerAnimationNodes)
    self.feedingRobot:resetRobot()
    self.feedingRobot:setFillScale(0)
    FeedingRobotStateReset:superClass().deactivate(self)
end