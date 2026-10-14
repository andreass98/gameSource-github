WindUpdater = {}
WindUpdater.MAX_SPEED = 42
local WindUpdater_mt = Class(WindUpdater)
function WindUpdater.new(customMt)
    -- upvalues: (copy) WindUpdater_mt
    local self = setmetatable({}, customMt or WindUpdater_mt)
    self.listeners = {}
    self.isDirty = false
    self.alpha = 1
    self.duration = 1
    self.currentDirX = 1
    self.currentDirZ = 0
    self.currentVelocity = 1
    self.currentCirrusSpeedFactor = 1
    self.lastDirX = 1
    self.lastDirZ = 0
    self.lastVelocity = 1
    self.lastCirrusSpeedFactor = 1
    self.targetDirX = 1
    self.targetDirZ = 0
    self.targetVelocity = 1
    self.targetCirrusSpeedFactor = 1
    self.sharedShaderParamValueWindSpeed = self.currentVelocity / WindUpdater.MAX_SPEED
    self.sharedShaderParamValueWindDirX = 1
    self.sharedShaderParamValueWindDirZ = 0
    self.randomWindWaving = true
    return self
end
function WindUpdater:delete()
    self.listeners = {}
end
function WindUpdater:update(scaledDt)
    if self.alpha ~= 1 then
        self.alpha = math.min(self.alpha + scaledDt / self.duration, 1)
        self.currentDirX = MathUtil.lerp(self.lastDirX, self.targetDirX, self.alpha)
        self.currentDirZ = MathUtil.lerp(self.lastDirZ, self.targetDirZ, self.alpha)
        self.currentVelocity = MathUtil.lerp(self.lastVelocity, self.targetVelocity, self.alpha)
        self.currentCirrusSpeedFactor = MathUtil.lerp(self.lastCirrusSpeedFactor, self.targetCirrusSpeedFactor, self.alpha)
        self.isDirty = true
    end
    if self.isDirty then
        local windSpeed = nil
        if not self.randomWindWaving then
            windSpeed = math.clamp(self.currentVelocity / WindUpdater.MAX_SPEED, 0, 1)
        end
        self:setSharedShaderParameterValues(windSpeed, self.currentDirX, self.currentDirZ)
        for _, listener in ipairs(self.listeners) do
            listener:setWindValues(self.currentDirX, self.currentDirZ, self.currentVelocity, self.currentCirrusSpeedFactor)
        end
        self.isDirty = false
    end
    if self.randomWindWaving then
        local windSpeed = g_time / 60000
        local sin = math.sin
        local offset = (sin(windSpeed) + sin(2.2 * windSpeed + 5.52) + sin(2.9 * windSpeed + 0.93)) / 4
        local inputSpeed = math.clamp(self.currentVelocity / WindUpdater.MAX_SPEED, 0, 1)
        self:setSharedShaderParameterValues(math.clamp(inputSpeed * 0.05 * offset + inputSpeed, 0, 1), nil, nil)
    end
end
function WindUpdater:setSharedShaderParameterValues(windSpeed, windDirX, windDirZ)
    self.sharedShaderParamValueWindSpeed = windSpeed or self.sharedShaderParamValueWindSpeed
    self.sharedShaderParamValueWindDirX = windDirX or self.sharedShaderParamValueWindDirX
    self.sharedShaderParamValueWindDirZ = windDirZ or self.sharedShaderParamValueWindDirZ
    setSharedShaderParameter(Shader.PARAM_SHARED_WIND_SPEED, self.sharedShaderParamValueWindSpeed)
    setSharedShaderParameter(Shader.PARAM_SHARED_WIND_DIR_X, self.sharedShaderParamValueWindDirX)
    setSharedShaderParameter(Shader.PARAM_SHARED_WIND_DIR_Z, self.sharedShaderParamValueWindDirZ)
end
function WindUpdater:getCurrentValues()
    return self.currentDirX, self.currentDirZ, self.currentVelocity, self.currentCirrusSpeedFactor
end
function WindUpdater:setTargetValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor, duration)
    self.alpha = 0
    self.duration = math.max(1, duration)
    self.lastDirX = self.currentDirX
    self.lastDirZ = self.currentDirZ
    self.lastVelocity = self.currentVelocity
    self.lastCirrusSpeedFactor = self.currentCirrusSpeedFactor
    self.targetDirX = windDirX
    self.targetDirZ = windDirZ
    self.targetVelocity = windVelocity
    self.targetCirrusSpeedFactor = cirrusCloudSpeedFactor
end
function WindUpdater:addWindChangedListener(listener)
    table.addElement(self.listeners, listener)
end
function WindUpdater:removeWindChangedListener(listener)
    table.removeElement(self.listeners, listener)
end