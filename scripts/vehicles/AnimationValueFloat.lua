AnimationValueFloat = {}
local AnimationValueFloat_mt = Class(AnimationValueFloat)
AnimationValueFloat.TANGENT_TYPE_LINEAR = 0
AnimationValueFloat.TANGENT_TYPE_SPLINE = 1
AnimationValueFloat.TANGENT_TYPE_STEP = 2
AnimationValueFloat.TANGENT_TYPE_SPLINE01 = 1
AnimationValueFloat.TANGENT_TYPE_SPLINE02 = 3
AnimationValueFloat.TANGENT_TYPE_SPLINE03 = 4
AnimationValueFloat.TANGENT_TYPE_SPLINE04 = 5
function AnimationValueFloat.new(vehicle, animation, part, startName, endName, name, initialUpdate, get, set, extraLoad, customMt)
    -- upvalues: (copy) AnimationValueFloat_mt
    local self = setmetatable({}, customMt or AnimationValueFloat_mt)
    self.vehicle = vehicle
    self.animation = animation
    self.part = part
    self.startName = startName
    self.endName = endName
    self.name = name
    self.initialUpdate = initialUpdate
    self.get = get
    self.set = set
    self.extraLoad = extraLoad
    self.warningInfo = self.name
    self.compareParams = {}
    self.oldCurValues = {}
    self.oldSpeed = {}
    self.curValue = nil
    self.speed = nil
    return self
end
function AnimationValueFloat:load(xmlFile, key)
    if self.startName ~= "" then
        self.startValue = xmlFile:getValue(key .. "#" .. self.startName, nil, true)
        local tangentTypeStr = self.startValue
        if type(tangentTypeStr) == "number" then
            self.startValue = { self.startValue }
        else
            local tangentTypeStr = self.startValue
            if type(tangentTypeStr) == "boolean" then
                local success = {}
                __set_list(success, 1, {self.startValue and 1 or 0})
                self.startValue = success
            else
                local tangentTypeStr = self.startValue
                if type(tangentTypeStr) == "string" then
                    local success = {}
                    __set_list(success, 1, {tonumber(self.startValue) or 0})
                    self.startValue = success
                else
                    local tangentTypeStr = self.startValue
                    if type(tangentTypeStr) == "table" then
                        local i = 1
                        for i = i, #self.startValue do
                            local i = self.startValue[i]
                            if type(i) == "string" then
                                self.startValue[i] = tonumber(self.startValue[i]) or 0
                            end
                        end
                    end
                end
            end
        end
    end
    if self.endName ~= "" then
        self.endValue = xmlFile:getValue(key .. "#" .. self.endName, nil, true)
        local tangentTypeStr = self.endValue
        if type(tangentTypeStr) == "number" then
            self.endValue = { self.endValue }
        else
            local tangentTypeStr = self.endValue
            if type(tangentTypeStr) == "boolean" then
                local success = {}
                __set_list(success, 1, {self.endValue and 1 or 0})
                self.endValue = success
            else
                local tangentTypeStr = self.endValue
                if type(tangentTypeStr) == "string" then
                    local success = {}
                    __set_list(success, 1, {tonumber(self.endValue) or 0})
                    self.endValue = success
                else
                    local tangentTypeStr = self.endValue
                    if type(tangentTypeStr) == "table" then
                        local i = 1
                        for i = i, #self.endValue do
                            local i = self.endValue[i]
                            if type(i) == "string" then
                                self.endValue[i] = tonumber(self.endValue[i]) or 0
                            end
                        end
                    end
                end
            end
        end
    end
    if self.endValue ~= nil or self.endName == "" then
        self.warningInfo = key
        self.xmlFile = xmlFile
        if self:extraLoad(xmlFile, key) then
            local tangentTypeStr = xmlFile:getValue(key .. "#tangentType", "linear")
            local tangentTypeStr = "TANGENT_TYPE_" .. string.upper(tangentTypeStr)
            if AnimationValueFloat[tangentTypeStr] == nil then
                self.tangentType = AnimationValueFloat.TANGENT_TYPE_LINEAR
            else
                self.tangentType = AnimationValueFloat[tangentTypeStr]
            end
            if self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE01 then
                self.tangentType = AnimationValueFloat.TANGENT_TYPE_SPLINE
                self.splineFunction = AnimationValueFloat.splineFunction01
            elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE02 then
                self.tangentType = AnimationValueFloat.TANGENT_TYPE_SPLINE
                self.splineFunction = AnimationValueFloat.splineFunction02
            elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE03 then
                self.tangentType = AnimationValueFloat.TANGENT_TYPE_SPLINE
                self.splineFunction = AnimationValueFloat.splineFunction03
            elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE04 then
                self.tangentType = AnimationValueFloat.TANGENT_TYPE_SPLINE
                self.splineFunction = AnimationValueFloat.splineFunction04
            end
            self.curStartValue = {}
            self.curRealValue = {}
            local i = 1
            local i = #(self.startValue or self.endValue)
            for i = i, i do
                self.curStartValue[i] = 0
                self.curRealValue[i] = 0
            end
            return true
        end
    end
    return false
end
function AnimationValueFloat:addCompareParameters(...)
    local i = 1
    local value = select("#", ...)
    for i = i, value do
        local value = select(i, ...)
        table.insert(self.compareParams, value)
    end
end
function AnimationValueFloat:setWarningInformation(info)
    self.warningInfo = info
end
function AnimationValueFloat:init(index, numParts)
    local j = index + 1
    for j = j, numParts do
        local part2 = self.animation.parts[j]
        if self.part.direction == part2.direction then
            local animationValue2 = nil
            local secondIndex = 1
            for secondIndex = secondIndex, #part2.animationValues do
                local secondAnimValue = part2.animationValues[secondIndex]
                if secondAnimValue.endName == self.endName then
                    local allowed = true
                    local paramIndex = 1
                    for paramIndex = paramIndex, #self.compareParams do
                        local param = self.compareParams[paramIndex]
                        if secondAnimValue[param] ~= self[param] then
                            allowed = false
                        end
                    end
                    if allowed then
                        animationValue2 = secondAnimValue
                    end
                end
            end
            if animationValue2 ~= nil then
                if self.part.startTime + self.part.duration > part2.startTime + 0.001 then
                    Logging.xmlWarning(self.xmlFile, "Overlapping %s parts for \'%s\' in animation \'%s\'", self.name, self.warningInfo, self.animation.name)
                end
                self.nextPart = animationValue2.part
                animationValue2.prevPart = self.part
                if animationValue2.startValue == nil then
                    animationValue2.startValue = { unpack(self.endValue) }
                    return
                end
                break
            end
        end
    end
end
function AnimationValueFloat:postInit()
    if self.endValue ~= nil and self.startValue == nil then
        self.startValue = { self:get() }
    end
end
function AnimationValueFloat:reset()
    self.oldCurValues = self.curValue or self.oldCurValues
    self.oldSpeed = self.speed or self.oldSpeed
    self.curValue = nil
    self.speed = nil
end
function AnimationValueFloat:initValues(targetValue, durationToEnd, fixedTimeUpdate, ...)
    self.curValue = self.curValue or self.oldCurValues
    local numValues = select("#", ...)
    local i = 1
    for i = i, numValues do
        self.curValue[i] = select(i, ...)
    end
    local invDuration = 1 / math.max(durationToEnd, 0.001)
    self.speed = self.speed or self.oldSpeed
    local i = 1
    local i = 1
    for i = i, #self.curValue, i do
        self.speed[i] = (targetValue[i] - self.curValue[i]) * invDuration
        self.curStartValue[i] = self.curValue[i]
        self.curRealValue[i] = self.curValue[i]
    end
    if fixedTimeUpdate == true then
        if self.animation.currentSpeed < 0 then
            local i = 1
            local i = 1
            for i = i, numValues, i do
                self.curStartValue[i] = self.endValue[i]
            end
        else
            local i = 1
            local i = 1
            for i = i, numValues, i do
                self.curStartValue[i] = self.startValue[i]
            end
        end
    end
    self.curTargetValue = targetValue
    return self.initialUpdate
end
function AnimationValueFloat:update(durationToEnd, _, realDt, fixedTimeUpdate)
    if self.startValue ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(self.nextPart, self.prevPart, self.animation, true)) then
        local targetValue = self.endValue
        if self.animation.currentSpeed < 0 then
            targetValue = self.startValue
        end
        local forceUpdate = false
        if self.curValue == nil then
            forceUpdate = self:initValues(targetValue, durationToEnd, fixedTimeUpdate, self:get())
        end
        if AnimatedVehicle.setMovedLimitedValuesN(#self.curValue, self.curValue, targetValue, self.speed, realDt) or forceUpdate then
            if self.tangentType == AnimationValueFloat.TANGENT_TYPE_LINEAR then
                self:set(unpack(self.curValue))
            elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE then
                local i = 1
                for i = i, #self.curValue do
                    local alpha = 0
                    if fixedTimeUpdate == true then
                        if self.part.duration ~= 0 then
                            alpha = 1 - math.clamp((durationToEnd - realDt) / self.part.duration, 0, 1)
                        end
                    else
                        local range = self.curTargetValue[i] - self.curStartValue[i]
                        if range ~= 0 then
                            alpha = (self.curValue[i] - self.curStartValue[i]) / range
                        end
                    end
                    if alpha >= 0 and alpha <= 1 then
                        self.curRealValue[i] = self.splineFunction(alpha) * (self.curTargetValue[i] - self.curStartValue[i]) + self.curStartValue[i]
                    else
                        self.curRealValue[i] = self.curValue[i]
                    end
                end
                local alpha = self.curRealValue
                self:set(unpack(alpha))
            elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_STEP then
                local i = 1
                for i = i, #self.curValue do
                    if (self.curValue[i] - self.curStartValue[i]) / math.max(self.curTargetValue[i] - self.curStartValue[i], 0.00001) >= 1 then
                        self.curRealValue[i] = self.curValue[i]
                    else
                        self.curRealValue[i] = self.curStartValue[i]
                    end
                end
                self:set(unpack(self.curRealValue))
            end
            return true
        end
    end
    return false
end
function AnimationValueFloat.splineFunction01(alpha)
    return (1 - math.cos(3.141592653589793 * alpha)) * 0.5
end
function AnimationValueFloat.splineFunction02(alpha)
    return (1 - math.cos(3.141592653589793 * (alpha + 0.0625) * 0.888888889) / 0.9848077531) * 0.5
end
function AnimationValueFloat.splineFunction03(alpha)
    return (1 - math.cos(3.141592653589793 * (alpha + 0.125) * 0.8) / 0.9510565163) * 0.5
end
function AnimationValueFloat.splineFunction04(alpha)
    return (1 - math.cos(3.141592653589793 * (alpha + 0.25) * 0.66666667) / 0.8660254038) * 0.5
end