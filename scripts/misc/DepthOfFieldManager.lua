DepthOfFieldManager = {}
DepthOfFieldManager.DEFAULT_VALUES = {
    0.8,
    0.5,
    0.2,
    1000,
    1400,
    false
}
local DepthOfFieldManager_mt = Class(DepthOfFieldManager, AbstractManager)
function DepthOfFieldManager.new(customMt)
    -- upvalues: (copy) DepthOfFieldManager_mt
    local self = AbstractManager.new(customMt or DepthOfFieldManager_mt)
    self.defaultState = table.clone(DepthOfFieldManager.DEFAULT_VALUES)
    self:reset()
    self.areaStack = {
        {
            -1,
            -1,
            -1,
            -1,
            false
        }
    }
    return self
end
function DepthOfFieldManager:delete()
    self:setManipulatedParams(nil, nil, nil, nil, nil, nil)
    setDoFBlurArea(-1, -1, -1, -1)
end
function DepthOfFieldManager:reset()
    self:setManipulatedParams(nil, nil, nil, nil, nil, nil)
end
function DepthOfFieldManager:setManipulatedParams(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd, applyToSky)
    applyToSky = Utils.getNoNil(applyToSky, self.defaultState[6])
    setDoFparams(nearCoCRadius or self.defaultState[1], nearBlurEnd or self.defaultState[2], farCoCRadius or self.defaultState[3], farBlurStart or self.defaultState[4], farBlurEnd or self.defaultState[5], applyToSky)
end
function DepthOfFieldManager:applyInfo(info)
    self:setManipulatedParams(info.nearCoCRadius, info.nearBlurEnd, info.farCoCRadius, info.farBlurStart, info.farBlurEnd, info.applyToSky)
end
function DepthOfFieldManager.createInfo(_, nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd, applyToSky)
    return {
        ["nearCoCRadius"] = nearCoCRadius,
        ["nearBlurEnd"] = nearBlurEnd,
        ["farCoCRadius"] = farCoCRadius,
        ["farBlurStart"] = farBlurStart,
        ["farBlurEnd"] = farBlurEnd,
        ["applyToSky"] = applyToSky
    }
end
function DepthOfFieldManager:pushArea(x, y, width, height)
    table.insert(self.areaStack, 1, {
        x,
        y,
        x + width,
        y + height,
        true
    })
    self:updateArea()
end
function DepthOfFieldManager:popArea()
    if #self.areaStack > 1 then
        table.remove(self.areaStack, 1)
    elseif g_isDevelopmentVersion then
        Logging.devWarning("Try to pop last blur area")
        printCallstack()
    end
    self:updateArea()
end
function DepthOfFieldManager:updateArea()
    if #self.areaStack > 0 then
        local x1 = 1
        local x2 = 0
        local y1 = 1
        local y2 = 0
        local isBlurred = false
        for _, item in ipairs(self.areaStack) do
            if item[5] then
                local x, y, xs, ys = unpack(item)
                x1 = math.min(x1, x)
                y1 = math.min(y1, y)
                x2 = math.max(x2, xs)
                y2 = math.max(y2, ys)
                isBlurred = true
            end
        end
        if not isBlurred then
            x1 = -1
            x2 = -1
            y1 = -1
            y2 = -1
        end
        setDoFBlurArea(x1, y1, x2, y2)
    end
end
function DepthOfFieldManager:consoleCommandFarParams(farCoC, farStart, farEnd)
    farCoC = tonumber(farCoC)
    farStart = tonumber(farStart)
    farEnd = tonumber(farEnd)
    self.defaultState[3] = farCoC or self.defaultState[3]
    self.defaultState[4] = farStart or self.defaultState[4]
    self.defaultState[5] = farEnd or self.defaultState[5]
    self:setManipulatedParams(nil, nil, nil, nil, nil, nil)
    Logging.info("Set far depth of field parameters: farCoC=%.2f, farStart=%d, farEnd=%d", self.defaultState[3], self.defaultState[4], self.defaultState[5])
end
function DepthOfFieldManager:consoleCommandNearParams(enabled, nearCoC, nearEnd)
    enabled = Utils.stringToBoolean(enabled)
    nearCoC = tonumber(nearCoC)
    nearEnd = tonumber(nearEnd)
    setDofQuality(enabled and 2 or 1)
    self.defaultState[1] = nearCoC or self.defaultState[1]
    self.defaultState[2] = nearEnd or self.defaultState[2]
    self:setManipulatedParams(nil, nil, nil, nil, nil, nil)
    Logging.info("Set near depth of field parameters: enabled=%s, nearCoC=%.2f, nearEnd=%.2f", tostring(enabled), self.defaultState[1], self.defaultState[2])
end
g_depthOfFieldManager = DepthOfFieldManager.new()
addConsoleCommand("gsDepthOfFieldSetFarParams", "Set far depth of field parameters", "consoleCommandFarParams", g_depthOfFieldManager, "farCoC; farStart; farEnd")
addConsoleCommand("gsDepthOfFieldSetNearParams", "Set far depth of field parameters", "consoleCommandNearParams", g_depthOfFieldManager, "enabled; nearCoC; nearEnd")