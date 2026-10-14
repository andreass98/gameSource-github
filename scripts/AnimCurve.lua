AnimCurve = {}
function linearInterpolator1(first, second, alpha)
    return second[1] + alpha * (first[1] - second[1])
end
function linearInterpolator2(first, second, alpha)
    local oneMinusAlpha = 1 - alpha
    return first[1] * alpha + second[1] * oneMinusAlpha, first[2] * alpha + second[2] * oneMinusAlpha
end
function linearInterpolator3(first, second, alpha)
    local oneMinusAlpha = 1 - alpha
    return first[1] * alpha + second[1] * oneMinusAlpha, first[2] * alpha + second[2] * oneMinusAlpha, first[3] * alpha + second[3] * oneMinusAlpha
end
function linearInterpolator4(first, second, alpha)
    local oneMinusAlpha = 1 - alpha
    return first[1] * alpha + second[1] * oneMinusAlpha, first[2] * alpha + second[2] * oneMinusAlpha, first[3] * alpha + second[3] * oneMinusAlpha, first[4] * alpha + second[4] * oneMinusAlpha
end
function linearInterpolatorN(first, second, alpha, curValues)
    local i = 1
    for i = i, #first do
        if first[i] ~= nil and second[i] ~= nil then
            curValues[i] = first[i] * alpha + second[i] * (1 - alpha)
        end
    end
    return unpack(curValues)
end
function linearInterpolatorTransRot(first, second, alpha)
    local oneMinusAlpha = 1 - alpha
    return first.x * alpha + second.x * oneMinusAlpha, first.y * alpha + second.y * oneMinusAlpha, first.z * alpha + second.z * oneMinusAlpha, first.rx * alpha + second.rx * oneMinusAlpha, first.ry * alpha + second.ry * oneMinusAlpha, first.rz * alpha + second.rz * oneMinusAlpha
end
function linearInterpolatorTransRotScale(first, second, alpha)
    local oneMinusAlpha = 1 - alpha
    return first.x * alpha + second.x * oneMinusAlpha, first.y * alpha + second.y * oneMinusAlpha, first.z * alpha + second.z * oneMinusAlpha, first.rx * alpha + second.rx * oneMinusAlpha, first.ry * alpha + second.ry * oneMinusAlpha, first.rz * alpha + second.rz * oneMinusAlpha, first.sx * alpha + second.sx * oneMinusAlpha, first.sy * alpha + second.sy * oneMinusAlpha, first.sz * alpha + second.sz * oneMinusAlpha
end
function catmullRomInterpolator1(p1, p2, p0, p3, t)
    t = 1 - t
    local t2 = t * t
    local p0v
    if p0 == nil then
        p0v = 2 * p1.v - p2.v
    else
        p0v = p0.v
    end
    local p3v
    if p3 == nil then
        p3v = 2 * p2.v - p1.v
    else
        p3v = p3.v
    end
    return 0.5 * (2 * p1.v + (-p0v + p2.v) * t + (2 * p0v - 5 * p1.v + 4 * p2.v - p3v) * t2 + (-p0v + 3 * p1.v - 3 * p2.v + p3v) * (t2 * t))
end
function catmullRomInterpolator3(p1, p2, p0, p3, t)
    t = 1 - t
    local t2 = t * t
    local t3 = t2 * t
    local p0x, p0y, p0z
    if p0 == nil then
        p0x = 2 * p1.x - p2.x
        p0y = 2 * p1.y - p2.y
        p0z = 2 * p1.z - p2.z
    else
        p0x = p0.x
        p0y = p0.y
        p0z = p0.z
    end
    local p3x, p3y, p3z
    if p3 == nil then
        p3x = 2 * p2.x - p1.x
        p3y = 2 * p2.y - p1.y
        p3z = 2 * p2.z - p1.z
    else
        p3x = p3.x
        p3y = p3.y
        p3z = p3.z
    end
    return 0.5 * (2 * p1.x + (-p0x + p2.x) * t + (2 * p0x - 5 * p1.x + 4 * p2.x - p3x) * t2 + (-p0x + 3 * p1.x - 3 * p2.x + p3x) * t3), 0.5 * (2 * p1.y + (-p0y + p2.y) * t + (2 * p0y - 5 * p1.y + 4 * p2.y - p3y) * t2 + (-p0y + 3 * p1.y - 3 * p2.y + p3y) * t3), 0.5 * (2 * p1.z + (-p0z + p2.z) * t + (2 * p0z - 5 * p1.z + 4 * p2.z - p3z) * t2 + (-p0z + 3 * p1.z - 3 * p2.z + p3z) * t3)
end
function quaternionInterpolator(p1, p2, t)
    return MathUtil.nlerpQuaternionShortestPath(p2.x, p2.y, p2.z, p2.w, p1.x, p1.y, p1.z, p1.w, t)
end
function quaternionInterpolator2(p1, p2, p0, p3, t)
    t = 1 - t
    local w0 = (1 - t) * 0.6
    local w3 = t * 0.6
    if p0 == nil then
        w0 = 0
        p0 = p1
    end
    if p3 == nil then
        w3 = 0
        p3 = p2
    end
    local x, y, z, w = MathUtil.quaternionMadShortestPath(p0.x * w0, p0.y * w0, p0.z * w0, p0.w * w0, p1.x, p1.y, p1.z, p1.w, 1 - t + w3)
    local x, y, z, w = MathUtil.quaternionMadShortestPath(x, y, z, w, p2.x, p2.y, p2.z, p2.w, t + w0)
    local x, y, z, w = MathUtil.quaternionMadShortestPath(x, y, z, w, p3.x, p3.y, p3.z, p3.w, w3)
    return MathUtil.quaternionNormalized(x, y, z, w)
end
local AnimCurve_mt = Class(AnimCurve)
function AnimCurve.new(interpolator, interpolatorDegree)
    -- upvalues: (copy) AnimCurve_mt
    local self = setmetatable({}, AnimCurve_mt)
    self.keyframes = {}
    self.interpolator = interpolator
    self.interpolatorDegree = interpolatorDegree or 2
    self.currentTime = 0
    self.maxTime = 0
    self.numKeyframes = 0
    return self
end
function AnimCurve:delete() end
function AnimCurve:reset()
    table.clear(self.keyframes)
    self.numKeyframes = 0
    self.currentTime = 0
    self.maxTime = 0
end
function AnimCurve:addKeyframe(keyframe, xmlFile, key)
    local numKeys = self.numKeyframes
    if numKeys > 0 and keyframe.time < self.keyframes[numKeys].time then
        if xmlFile == nil then
            printError("Error: keyframes not strictly monotonic increasing")
        else
            if type(xmlFile) == "number" then
                xmlFile = g_xmlManager:getFileByHandle(xmlFile)
            end
            if xmlFile == nil then
                Logging.error("keyframes not strictly monotonic increasing at %s (%.3f)", key, keyframe.time)
            else
                Logging.xmlError(xmlFile, "keyframes not strictly monotonic increasing at %s (%.3f)", key, keyframe.time)
            end
        end
    end
    if self.interpolator == linearInterpolatorN and numKeys == 0 then
        self.curValues = table.create(#keyframe)
    end
    table.insert(self.keyframes, keyframe)
    self.maxTime = keyframe.time
    self.numKeyframes = numKeys + 1
end
function AnimCurve:removeKeyframe(index)
    if index == nil or index >= 1 and #self.keyframes >= index then
        local i = #self.keyframes - 1
        for i = i, index, -1 do
            self.keyframes[i + 1].time = self.keyframes[i].time
        end
        table.remove(self.keyframes, index)
        self.maxTime = self.keyframes[#self.keyframes] and self.keyframes[#self.keyframes].time or 0
        self.numKeyframes = self.numKeyframes - 1
    end
end
function AnimCurve:getMaximum()
    local numKeys = #self.keyframes
    if numKeys == 0 then
        return 0, 0
    end
    if numKeys == 1 then
        return self:getFromKeyframes(self.keyframes[1], self.keyframes[1], 1, 1, 0), self.keyframes[1].time
    end
    local maxValue = self:getFromKeyframes(self.keyframes[1], self.keyframes[2], 1, 2, 0)
    local maxTime = self.keyframes[1].time
    local i = 1
    for i = i, numKeys - 1 do
        local value = self:getFromKeyframes(self.keyframes[i], self.keyframes[i + 1], i, i + 1, 1)
        if maxValue < value then
            maxTime = self.keyframes[i + 1].time
            maxValue = value
        end
    end
    return maxValue, maxTime
end
function AnimCurve:get(time)
    local numKeys = self.numKeyframes
    if numKeys == 0 then
        return
    end
    local first = nil
    local second = nil
    local firstI = nil
    local secondI = nil
    if numKeys >= 2 and self.keyframes[1].time <= time then
        if time < self.maxTime then
            local i = 2
            for i = i, numKeys do
                if time <= self.keyframes[i].time then
                    first = self.keyframes[i - 1]
                    firstI = i - 1
                    secondI = i
                    break
                end
                secondI = i
            end
        else
            secondI = numKeys
            firstI = secondI
            second = self.keyframes[numKeys]
            secondI, firstI = firstI, secondI
        end
    else
        second = self.keyframes[1]
    end
    local time0 = first.time
    local time1 = second.time
    local i
    if time0 < time1 then
        i = (time1 - time) / (time1 - time0)
    else
        i = 0
    end
    if self.segmentTimes ~= nil and firstI < numKeys then
        local timesOffset = (firstI - 1) * (self.numTimesPerKeyframe + 1) + 1
        local segmentT = time - first.time
        local segmentLow, segmentHi = self:getInterval(segmentT, self.segmentTimes, timesOffset, self.numTimesPerKeyframe + 1)
        local l = self.segmentTimes[segmentHi + timesOffset] - self.segmentTimes[segmentLow + timesOffset]
        if l > 0 then
            segmentLow = segmentLow + (segmentT - self.segmentTimes[segmentLow + timesOffset]) / l
        end
        i = 1 - segmentLow / self.numTimesPerKeyframe
    end
    return self:getFromKeyframes(first, second, firstI, secondI, i)
end
function AnimCurve:getFromKeyframes(first, second, firstI, secondI, alpha)
    if self.interpolatorDegree == 2 then
        if self.interpolator == linearInterpolatorN then
            return self.interpolator(first, second, alpha, self.curValues)
        else
            return self.interpolator(first, second, alpha)
        end
    elseif self.interpolatorDegree == 3 then
        local beforeFirst = nil
        if firstI > 1 then
            beforeFirst = self.keyframes[firstI - 1]
        end
        local afterSecond = nil
        if secondI < #self.keyframes then
            afterSecond = self.keyframes[secondI + 1]
        end
        if self.interpolator == linearInterpolatorN then
            return self.interpolator(first, second, beforeFirst, self.curValues)
        else
            return self.interpolator(first, second, beforeFirst, afterSecond, alpha)
        end
    else
        return nil
    end
end
function AnimCurve.getInterval(_, time, times, timesOffset, numTimes)
    local low = 0
    while numTimes - low > 1 do
        local kk = math.floor((numTimes + low) / 2)
        if time < times[kk + timesOffset] then
            numTimes = kk
        end
        low = kk
    end
    return low, numTimes
end
function AnimCurve:loadCurveFromXML(xmlFile, baseKey, loadFunc)
    local i = 0
    while true do
        local key = string.format("%s.key(%d)", baseKey, i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local keyFrame = loadFunc(xmlFile, key)
        if keyFrame ~= nil then
            self:addKeyframe(keyFrame)
        end
        i = i + 1
    end
end
function loadInterpolator1Curve(xmlFile, key)
    local time = getXMLFloat(xmlFile, key .. "#time")
    local value = getXMLFloat(xmlFile, key .. "#value")
    return value ~= nil and {
        value,
        ["time"] = time
    } or nil
end
function loadInterpolator2Curve(xmlFile, key)
    local time = getXMLFloat(xmlFile, key .. "#time")
    local values = string.getVector(getXMLString(xmlFile, key .. "#values"), 2)
    if values == nil then
        return nil
    end
    values.time = time
    return values
end
function loadInterpolator3Curve(xmlFile, key)
    local time = getXMLFloat(xmlFile, key .. "#time")
    local values = string.getVector(getXMLString(xmlFile, key .. "#values"), 3)
    if values == nil then
        return nil
    end
    values.time = time
    return values
end
function loadInterpolator4Curve(xmlFile, key)
    local time = getXMLFloat(xmlFile, key .. "#time")
    local values = string.getVector(getXMLString(xmlFile, key .. "#values"), 4)
    if values == nil then
        return nil
    end
    values.time = time
    return values
end
function getLoadNamedInterpolatorCurve(names)
    return function(xmlFile, key)
        -- upvalues: (copy) names
        local time = getXMLString(xmlFile, key .. "#time")
        local values = {}
        for _, name in ipairs(names) do
            local value = getXMLString(xmlFile, key .. "#" .. name)
            if value == nil then
                return nil
            end
            table.insert(values, (tonumber(value)))
        end
        values.time = tonumber(time)
        return values
    end
end