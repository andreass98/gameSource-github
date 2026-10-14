Windmill = {}
Windmill.RPM_TO_RADPMS = 0.00010471975511965977
local Windmill_mt = Class(Windmill)
function Windmill.onCreate(_, node)
    Windmill.new(node)
end
function Windmill.new(node, _)
    -- upvalues: (copy) Windmill_mt
    local bladeIndex = Windmill_mt
    local self = setmetatable({}, bladeIndex)
    local bladeIndexStr = getUserAttribute(node, "bladeIndex")
    local bladeIndex = tonumber(bladeIndexStr)
    if bladeIndex ~= nil and getNumOfChildren(node) - 1 >= bladeIndex then
        self.bladeNode = getChildAt(node, bladeIndex)
        self.minRequiredWindSpeed = tonumber(getUserAttribute(node, "minRequiredWindSpeed")) or 1
        self.windSpeedRpmRatio = tonumber(getUserAttribute(node, "windSpeedRpmRatio")) or 0.3
        self.maxRpm = tonumber(getUserAttribute(node, "maxRpm")) or 15
        local wobbleMaxDeg = tonumber(getUserAttribute(node, "wobbleMaxDeg")) or 1
        self.wobbleMaxRad = math.rad(wobbleMaxDeg)
        local windUpdater = g_currentMission.environment.weather.windUpdater
        windUpdater:addWindChangedListener(self)
        self:setWindValues(windUpdater:getCurrentValues())
        g_currentMission:addUpdateable(self)
        return self
    end
    Logging.error("Invalid value \'%s\' for bladeIndex userAttribute for Windmill onCreate for %s", bladeIndexStr, I3DUtil.getNodePath(node))
end
function Windmill:update(dt)
    if self.rotSpeed ~= 0 then
        local wobble = self.wobbleAmount * math.sin(g_time / 500)
        local _, _, z = getRotation(self.bladeNode)
        setRotation(self.bladeNode, wobble, -wobble, (z + self.rotSpeed * dt) % 6.283185307179586)
    end
end
function Windmill:setWindValues(_, _, currentVelocityMps, _)
    if currentVelocityMps < self.minRequiredWindSpeed then
        self.rotSpeed = 0
    else
        local rpm = math.clamp(currentVelocityMps * self.windSpeedRpmRatio, -self.maxRpm, self.maxRpm)
        self.rotSpeed = Windmill.RPM_TO_RADPMS * rpm
        self.wobbleAmount = math.abs(rpm / self.maxRpm) * self.wobbleMaxRad
    end
end