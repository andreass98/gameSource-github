SkyBoxUpdater = {}
SkyBoxUpdater.RAIN_FADE_IN = 7200000
local SkyBoxUpdater_mt = Class(SkyBoxUpdater)
function SkyBoxUpdater.new(customMt)
    -- upvalues: (copy) SkyBoxUpdater_mt
    local self = setmetatable({}, customMt or SkyBoxUpdater_mt)
    self.x = 1
    self.y = 0
    self.z = 0
    self.w = 0
    self.rainScale = 0
    self.loadRequestId = nil
    return self
end
function SkyBoxUpdater:load(xmlFile, key)
    local i3dFilename = xmlFile:getString(key .. "#filename")
    if i3dFilename == nil then
        Logging.devWarning("Missing filename for skybox updater in \'%s\'", key)
        return false
    end
    self.loadRequestId = g_i3DManager:loadI3DFileAsync(i3dFilename, false, false, SkyBoxUpdater.skyNodeLoaded, self, nil)
    self.skyCurve = AnimCurve.new(linearInterpolator4)
    self.skyCurve:loadCurveFromXML(xmlFile:getHandle(), key .. ".curve", loadInterpolator4Curve)
    return true
end
function SkyBoxUpdater:skyNodeLoaded(i3dNode, _, _)
    if i3dNode ~= nil and i3dNode ~= 0 then
        self.skyNode = i3dNode
        link(getRootNode(), self.skyNode)
        self.skyId = getChildAt(self.skyNode, 0)
    end
    self.loadRequestId = nil
end
function SkyBoxUpdater:delete()
    if self.loadRequestId ~= nil then
        g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
        self.loadRequestId = nil
    end
    if self.skyNode ~= nil then
        delete(self.skyNode)
    end
end
function SkyBoxUpdater:update(dt, dayTime, rainScale, timeUntilRain)
    local alpha = rainScale > 0 and 1 or 0
    if alpha < self.rainScale then
        alpha = alpha + math.pow(0.999, dt) * (self.rainScale - alpha)
    end
    if timeUntilRain < SkyBoxUpdater.RAIN_FADE_IN then
        alpha = math.min((1 - timeUntilRain / SkyBoxUpdater.RAIN_FADE_IN) ^ 0.5, 1)
    end
    local alpha = dayTime / 60000
    local x, y, z, w = self.skyCurve:get(alpha)
    self.dayScale = 1 - z
    self:setPartScale(x * (1 - alpha), y * (1 - alpha), z * (1 - alpha), w * (1 - alpha))
    self:setRainScale(alpha, self.dayScale)
end
function SkyBoxUpdater:setPartScale(x, y, z, w)
    if self.skyId ~= nil then
        setShaderParameter(self.skyId, "partScale", x, y, z, w)
    end
    self.x = x
    self.y = y
    self.z = z
    self.w = w
end
function SkyBoxUpdater:setRainScale(scale, dayScale)
    if self.skyId ~= nil then
        setShaderParameter(self.skyId, "rainScale", scale * dayScale, scale * (1 - dayScale), 0, 0)
    end
    self.rainScale = scale
end
function SkyBoxUpdater:addDebugValues(data)
    table.insert(data, {
        ["name"] = "SKYBOX",
        ["value"] = ""
    })
    table.insert(data, {
        ["name"] = "partScale",
        ["value"] = string.format("%.2f %.2f %.2f %.2f", self.x, self.y, self.z, self.w)
    })
    table.insert(data, {
        ["name"] = "rainScale",
        ["value"] = string.format("%.2f", self.rainScale)
    })
    table.insert(data, {
        ["name"] = "dayScale",
        ["value"] = string.format("%.2f", self.dayScale)
    })
end