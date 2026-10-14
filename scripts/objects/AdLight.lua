AdLight = {}
local AdLight_mt = Class(AdLight)
function AdLight.onCreate(_, node)
    local light = AdLight.new()
    if light:loadFromNode(node) then
        g_currentMission:addUpdateable(light)
    else
        light:delete()
    end
end
function AdLight.new(node)
    -- upvalues: (copy) AdLight_mt
    return setmetatable({}, AdLight_mt)
end
function AdLight:loadFromNode(node)
    self.node = node
    if not getHasClassId(node, ClassIds.LIGHT_SOURCE) then
        Logging.warning("Node is not a light source for \'%s\'", I3DUtil.getNodePath(node))
        return false
    end
    self.curve = AnimCurve.new(linearInterpolator3, 2)
    local startColorString = getUserAttribute(node, "startColor")
    local startColor = string.getVector(startColorString, 3)
    if startColor == nil then
        Logging.warning("Invalid or missing \'startColor\' attribute value for \'%s\'", I3DUtil.getNodePath(node))
        return false
    end
    self.curve:addKeyframe({
        startColor[1],
        startColor[2],
        startColor[3],
        ["time"] = 0
    })
    local midColorString = getUserAttribute(node, "midColor")
    local midColor = string.getVector(midColorString, 3)
    if midColor == nil then
        Logging.warning("Invalid or missing \'midColor\' attribute value for \'%s\'", I3DUtil.getNodePath(node))
        return false
    end
    self.curve:addKeyframe({
        midColor[1],
        midColor[2],
        midColor[3],
        ["time"] = 0.5
    })
    local endColorString = getUserAttribute(node, "endColor")
    local endColor = string.getVector(endColorString, 3)
    if endColor == nil then
        Logging.warning("Invalid or missing \'endColor\' attribute value for \'%s\'", I3DUtil.getNodePath(node))
        return false
    end
    self.curve:addKeyframe({
        endColor[1],
        endColor[2],
        endColor[3],
        ["time"] = 1
    })
    self.duration = (tonumber(getUserAttribute(node, "durationSeconds")) or 1) * 1000
    self.time = 0
    return true
end
function AdLight:delete() end
function AdLight:update(_)
    local r, g, b = self.curve:get(g_currentMission.time % self.duration / self.duration)
    setLightColor(self.node, r, g, b)
end