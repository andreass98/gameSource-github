Timer = {}
local Timer_mt = Class(Timer)
function Timer.new(duration)
    -- upvalues: (copy) Timer_mt
    local self = setmetatable({}, Timer_mt)
    self.duration = duration
    self.callback = nil
    self.isRunning = false
    self.timeLeft = duration
    return self
end
function Timer:delete()
    self:reset()
end
function Timer:reset()
    g_currentMission:removeUpdateable(self)
    self.isRunning = false
end
function Timer:start(noReset)
    if self.duration == nil then
        Logging.error("Timer duration not set")
        printCallstack()
    else
        self.isRunning = true
        if noReset == nil or not noReset then
            self.timeLeft = self.duration
        end
        g_currentMission:addUpdateable(self)
    end
end
function Timer:startIfNotRunning()
    if not self.isRunning then
        self:start()
    end
end
function Timer:stop()
    g_currentMission:removeUpdateable(self)
    self.isRunning = false
end
function Timer:finish()
    g_currentMission:removeUpdateable(self)
    self.timeLeft = 0
    self.isRunning = false
    if self.callback ~= nil then
        self.callback(self)
    end
end
function Timer:getIsRunning()
    return self.isRunning
end
function Timer:setFinishCallback(callback)
    self.callback = callback
    return self
end
function Timer:getTimePassed()
    return self.duration - self.timeLeft
end
function Timer:getTimeLeft()
    return self.timeLeft
end
function Timer:setTimeLeft(timeLeftMs)
    self.timeLeft = timeLeftMs
end
function Timer:update(dt)
    if self.isRunning then
        local scale = 1
        if self.scaleFunc ~= nil then
            scale = self.scaleFunc()
        end
        self.timeLeft = self.timeLeft - dt * scale
        if self.timeLeft <= 0 then
            self:finish()
        end
    end
end
function Timer:setScaleFunction(scaleFunc)
    self.scaleFunc = scaleFunc
end
function Timer.createOneshot(duration, callback, scaleFunc)
    local timer = Timer.new(duration)
    timer:setFinishCallback(function()
        -- upvalues: (copy) timer, (copy) callback
        timer:delete()
        return callback()
    end)
    timer:setScaleFunction(scaleFunc)
    timer:start()
    return timer
end
function Timer:getDuration()
    return self.duration
end
function Timer:setDuration(duration)
    self.duration = duration
    return self
end
function Timer:writeUpdateStream(streamId)
    streamWriteInt32(streamId, self.timeLeft)
end
function Timer:readUpdateStream(streamId)
    self.timeLeft = streamReadInt32(streamId)
end