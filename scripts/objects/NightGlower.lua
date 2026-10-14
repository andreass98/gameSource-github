NightGlower = {}
local NightGlower_mt = Class(NightGlower)
function NightGlower.onCreate(_, id)
    g_currentMission:addUpdateable(NightGlower.new(id))
end
function NightGlower.new(id)
    -- upvalues: (copy) NightGlower_mt
    local self = setmetatable({}, NightGlower_mt)
    self.id = id
    self.isSunOn = true
    self.maxGlow = { 1, 6, 3 }
    self.minGlow = { 1, 3, 1 }
    self.timer = 0
    setShaderParameter(self.id, "colorTint", 1, 1, 1, 1, false)
    g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, self.onWeatherChanged, self)
    return self
end
function NightGlower:delete()
    g_messageCenter:unsubscribeAll(self)
end
function NightGlower:update(dt)
    if not self.isSunOn then
        self.timer = (self.timer + dt * 0.001) % 6.283185307179586
        local glowValue = (math.sin(self.timer) + 1) / 2
        local currentGlow = {
            0,
            0,
            0,
            glowValue * self.maxGlow[1] + (1 - glowValue) * self.minGlow[1],
            glowValue * self.maxGlow[2] + (1 - glowValue) * self.minGlow[2],
            glowValue * self.maxGlow[3] + (1 - glowValue) * self.minGlow[3]
        }
        setShaderParameter(self.id, "colorTint", currentGlow[1], currentGlow[2], currentGlow[3], 1, false)
    end
end
function NightGlower:onWeatherChanged()
    self.isSunOn = g_currentMission.environment.isSunOn
    if self.isSunOn then
        setShaderParameter(self.id, "colorTint", 1, 1, 1, 1, false)
    end
end