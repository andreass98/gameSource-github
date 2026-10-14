SplineUtil = {}
function SplineUtil.getValidSplineTime(t)
    return t % 1
end
function SplineUtil.getSplineTimeAtWorldPos(spline, t, posX, posZ, checkDistance, maxSteps)
    local currentCheckDistance = checkDistance / getSplineLength(spline)
    local stepCounter = 0
    while true do
        local t1 = SplineUtil.getValidSplineTime(t + currentCheckDistance)
        local t2 = SplineUtil.getValidSplineTime(t - currentCheckDistance)
        local fX, _, fZ = getSplinePosition(spline, t1)
        local bX, _, bZ = getSplinePosition(spline, t2)
        local fDistance = MathUtil.vector2LengthSq(posX - fX, posZ - fZ)
        local bDistance = MathUtil.vector2LengthSq(posX - bX, posZ - bZ)
        currentCheckDistance = currentCheckDistance * 0.5
        if fDistance < bDistance then
            t = SplineUtil.getValidSplineTime(t + currentCheckDistance)
        else
            t = SplineUtil.getValidSplineTime(t - currentCheckDistance)
        end
        if maxSteps < stepCounter then
            return t, stepCounter
        end
        stepCounter = stepCounter + 1
    end
end
function SplineUtil.getSlopeAngle(spline, splineTime)
    local dx, dy, dz = getSplineDirection(spline, splineTime)
    return math.acos(dy / MathUtil.vector3Length(dx, dy, dz)) - 1.5707963267948966
end
function SplineUtil.getCenterPosition(splineNode, samples)
    if splineNode == nil then
        return nil
    end
    if not I3DUtil.getIsSpline(splineNode) then
        return nil
    end
    local splineLength = getSplineLength(splineNode)
    if splineLength == nil or splineLength <= 0 then
        return nil
    end
    samples = samples or 100
    local xSum = 0
    local ySum = 0
    local zSum = 0
    local t = 0
    local i = 0
    local y = 1
    for i = i, samples, y do
        local x, y, z = getSplinePosition(splineNode, t)
        t = math.clamp(t + 1 / samples, 0, 1)
    end
    if not getIsSplineClosed(splineNode) then
        local x, y, i = getSplinePosition(splineNode, 0)
    end
    return xSum / samples, ySum / samples, zSum / samples
end
function SplineUtil.convertToLinearSplineXZ(cubicSpline, thresholdAngleDeg, stepSizeInMeter)
    if not I3DUtil.getIsSpline(cubicSpline) then
        return nil
    end
    stepSizeInMeter = stepSizeInMeter or 0.5
    local thresholdRad = math.rad(thresholdAngleDeg or 5)
    local splineLength = getSplineLength(cubicSpline)
    local lastDirX = nil
    local lastDirZ = nil
    local t = 0
    while true do
        local x, y, z = getSplinePosition(cubicSpline, t)
        local dirX, _, dirZ = getSplineDirection(cubicSpline, t)
        if lastDirX == nil then
            lastDirZ = dirZ
            lastDirX = dirX
        end
        local delta = MathUtil.getVectorAngleDifference(dirX, 0, dirZ, lastDirX, 0, lastDirZ)
        if t == 0 or (t == 1 or thresholdRad < delta) then
            table.insert({}, { x, y, z })
        else
            dirZ = lastDirZ
            dirX = lastDirX
        end
        if t >= 1 then
            return positions
        end
        t = math.clamp(t + stepSizeInMeter / splineLength, 0, 1)
        lastDirZ = dirZ
        lastDirX = dirX
    end
end
function SplineUtil.getClosestEditPoint(splineNode, posX, posY, posZ)
    if splineNode == nil or not I3DUtil.getIsSpline(splineNode) then
        return nil
    else
        local numCV = getSplineNumOfCV(splineNode)
        if numCV < 1 then
            return nil
        else
            local closestIndex = -1
            local closestDistanceSq = math.huge
            local closestX = nil
            local closestY = nil
            local closestZ = nil
            local index = 0
            for index = index, numCV - 1 do
                local x, y, z = getSplineEP(splineNode, index)
                local distanceSq = MathUtil.vector3LengthSq(posX - x, posY - y, posZ - z)
                if distanceSq < closestDistanceSq then
                    closestZ = z
                    closestY = y
                    closestX = x
                    closestIndex = index
                    closestDistanceSq = distanceSq
                end
            end
            if closestIndex == -1 then
                return nil
            else
                return closestIndex, math.sqrt(closestDistanceSq), closestX, closestY, closestZ
            end
        end
    end
end
function SplineUtil.getClosestEditPointsOnCurve(splineNode, posX, posY, posZ, eps)
    if splineNode == nil or not I3DUtil.getIsSpline(splineNode) then
        return nil
    end
    local splineLength = getSplineLength(splineNode)
    if splineLength == nil or splineLength <= 0 then
        return nil
    end
    local x, y, z, splineTime = getClosestSplinePosition(splineNode, posX, posY, posZ, eps or 0.01 / splineLength)
    local prevIndex = nil
    local nextIndex = nil
    local index = 0
    for index = index, getSplineNumOfCV(splineNode) - 1 do
        if getTimeAtSplineCV(splineNode, index) < splineTime then
            prevIndex = index
        elseif nextIndex == nil then
            nextIndex = index
        end
    end
    return x, y, z, splineTime, prevIndex, nextIndex
end