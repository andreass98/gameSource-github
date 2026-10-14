DailySound = {}
local DailySound_mt = Class(DailySound)
function DailySound.onCreate(_, id)
    g_currentMission:addNonUpdateable(DailySound.new(id))
end
function DailySound.new(id, customMt)
    -- upvalues: (copy) DailySound_mt
    local self = setmetatable({}, customMt or DailySound_mt)
    self.soundId = id
    self.startTime = Utils.getNoNil(getUserAttribute(id, "startTime"), 0)
    self.endTime = Utils.getNoNil(getUserAttribute(id, "endTime"), 24)
    setVisibility(id, false)
    self.isActive = false
    self.oldIsActive = false
    self.timerId = addTimer(1000, "dailySoundTimerCallback", self)
    return self
end
function DailySound:delete()
    removeTimer(self.timerId)
end
function DailySound:dailySoundTimerCallback()
    if g_currentMission ~= nil then
        if self.startTime > self.endTime then
            self.isActive = g_currentMission.environment.dayTime > self.startTime * 60 * 60 * 1000 or g_currentMission.environment.dayTime < self.endTime * 60 * 60 * 1000
        else
            self.isActive = g_currentMission.environment.dayTime > self.startTime * 60 * 60 * 1000 and g_currentMission.environment.dayTime < self.endTime * 60 * 60 * 1000
        end
        if self.isActive ~= self.oldIsActive then
            setVisibility(self.soundId, self.isActive)
            self.oldIsActive = self.isActive
        end
    end
    return true
end