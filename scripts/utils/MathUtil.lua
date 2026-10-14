MathUtil = {}
function MathUtil.isNan(value)
    return not (value == value)
end
function MathUtil.isInt(number)
    return math.round(number) == number
end
function MathUtil.isInf(number)
    return number == -math.huge or number == math.huge
end
function MathUtil.isFinite(number)
    return not (MathUtil.isNan(number) or MathUtil.isInf(number))
end
function MathUtil.getIsValidTransformationValue(...)
    local i = 1
    for i = i, select("#", ...) do
        local number = select(i, ...)
        if number == nil then
            return false
        end
        if tonumber(number) == nil then
            return false
        end
        if number ~= number then
            return false
        end
        if number == math.huge then
            return false
        end
        if number == -math.huge then
            return false
        end
    end
    return true
end
function MathUtil.randomFloat(lowerValue, upperValue)
    return lowerValue + math.random() * (upperValue - lowerValue)
end
function MathUtil.round(value, precision)
    if value == nil then
        return nil
    end
    if not precision then
        return math.floor(value + 0.5)
    end
    local exp = 10 ^ precision
    return math.floor(value * exp + 0.5) / exp
end
function MathUtil.roundToStep(value, step)
    if value == nil then
        return nil
    else
        step = step or 0.5
        if value >= 0 then
            return math.floor(value / step + 0.5) * step
        else
            return math.ceil(value / step - 0.5) * step
        end
    end
end
function MathUtil.degToRad(degValue)
    return degValue == nil and 0 or math.rad(degValue)
end
function MathUtil.lerp(v1, v2, alpha)
    return v1 + (v2 - v1) * alpha
end
function MathUtil.inverseLerp(v1, v2, cv)
    if math.abs(v1 - v2) < 0.0001 then
        return 0
    end
    return math.clamp((cv - v1) / (v2 - v1), 0, 1)
end
function MathUtil.timeLerp(startTime, endTime, currentTime)
    if startTime == endTime then
        return 0
    end
    if endTime < startTime then
        local diff = 24 - startTime
    end
    return (currentTime - startTime) / (endTime - startTime)
end
function MathUtil.getIsOutOfBounds(value, limit1, limit2)
    if limit1 < limit2 then
        return value < limit1 or limit2 < value
    else
        return limit1 < value or value < limit2
    end
end
function MathUtil.getFlooredPercent(value, maxValue)
    local percent = 0
    if maxValue > 0 then
        percent = math.floor(value / maxValue * 100)
        if percent > 99 and value < maxValue then
            return 99
        end
        if percent < 1 then
        end
    end
    return percent
end
function MathUtil.getFlooredBounded(value, minValue, maxValue)
    if value == minValue then
        return minValue
    end
    if value == maxValue then
        return maxValue
    end
    return math.min(math.max(math.floor(value), minValue + 1), maxValue - 1)
end
function MathUtil.getValidLimit(limit)
    while limit < -3.141592653589793 do
        limit = limit + 6.283185307179586
    end
    while limit > 3.141592653589793 do
        limit = limit - 6.283185307179586
    end
    return limit
end
function MathUtil.getAngleDifference(alpha, beta)
    return MathUtil.getValidLimit(alpha - beta)
end
function MathUtil.eulerToDirection(yaw, pitch)
    local xzLength = math.cos(-pitch)
    return xzLength * math.sin(yaw), math.sin(-pitch), xzLength * math.cos(yaw)
end
function MathUtil.directionToPitchYaw(directionX, directionY, directionZ)
    return math.asin(-directionY), math.atan2(directionX, directionZ)
end
function MathUtil.vector2Length(x, y)
    return math.sqrt(x * x + y * y)
end
function MathUtil.vector2LengthSq(x, y)
    return x * x + y * y
end
function MathUtil.vector2Normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    return x / length, y / length
end
function MathUtil.vector2SetLength(x, y, length)
    x, y = MathUtil.vector2Normalize(x, y)
    return x * length, y * length
end
function MathUtil.vector2Lerp(x1, y1, x2, y2, alpha)
    return x1 + (x2 - x1) * alpha, y1 + (y2 - y1) * alpha
end
function MathUtil.vector3Length(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
end
function MathUtil.vector3LengthSq(x, y, z)
    return x * x + y * y + z * z
end
function MathUtil.vector3Normalize(x, y, z)
    local length = MathUtil.vector3Length(x, y, z)
    return x / length, y / length, z / length
end
function MathUtil.vector3SetLength(x, y, z, length)
    x, y, z = MathUtil.vector3Normalize(x, y, z)
    return x * length, y * length, z * length
end
function MathUtil.vector3Clamp(x, y, z, minVal, maxVal)
    local length = MathUtil.vector3Length(x, y, z)
    if length > 0 then
        local length = math.clamp(length, minVal, maxVal)
        x, y, z = MathUtil.vector3SetLength(x, y, z, length)
    end
    return x, y, z
end
function MathUtil.vector3Lerp(x1, y1, z1, x2, y2, z2, alpha)
    return x1 + (x2 - x1) * alpha, y1 + (y2 - y1) * alpha, z1 + (z2 - z1) * alpha
end
MathUtil.lerp3 = MathUtil.vector3Lerp
function MathUtil.inverseVector3Lerp(x1, y1, z1, x2, y2, z2, c1, c2, c3)
    local alpha1 = MathUtil.inverseLerp(x1, x2, c1)
    local alpha2 = MathUtil.inverseLerp(y1, y2, c2)
    local alpha3 = MathUtil.inverseLerp(z1, z2, c3)
    if x1 ~= x2 then
        return alpha1
    end
    if y1 ~= y2 then
        return alpha2
    end
    if z1 == z2 then
        alpha3 = 0
    end
    return alpha3
end
function MathUtil.vector3ArrayLerp(v1, v2, alpha)
    return v1[1] + (v2[1] - v1[1]) * alpha, v1[2] + (v2[2] - v1[2]) * alpha, v1[3] + (v2[3] - v1[3]) * alpha
end
function MathUtil.inverseVector3ArrayLerp(v1, v2, cv)
    local alpha1 = MathUtil.inverseLerp(v1[1], v2[1], cv[1])
    local alpha2 = MathUtil.inverseLerp(v1[2], v2[2], cv[2])
    local alpha3 = MathUtil.inverseLerp(v1[3], v2[3], cv[3])
    if v1[1] ~= v2[1] then
        return alpha1
    end
    if v1[2] ~= v2[2] then
        return alpha2
    end
    if v1[3] == v2[3] then
        alpha3 = 0
    end
    return alpha3
end
function MathUtil.vector3Transformation(x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33)
    return x * m11 + y * m21 + z * m31, x * m12 + y * m22 + z * m32, x * m13 + y * m23 + z * m33
end
function MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, xOffset, yOffset, zOffset)
    local normX, normY, normZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
    return x + normX * xOffset + upX * yOffset + dirX * zOffset, y + normY * xOffset + upY * yOffset + dirY * zOffset, z + normZ * xOffset + upZ * yOffset + dirZ * zOffset
end
function MathUtil.dotProduct(ax, ay, az, bx, by, bz)
    return ax * bx + ay * by + az * bz
end
function MathUtil.crossProduct(ax, ay, az, bx, by, bz)
    return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end
function MathUtil.getVectorAngleDifference(dirX1, dirY1, dirZ1, dirX2, dirY2, dirZ2)
    local length1 = math.sqrt(dirX1 * dirX1 + dirY1 * dirY1 + dirZ1 * dirZ1)
    return math.acos((dirX1 * dirX2 + dirY1 * dirY2 + dirZ1 * dirZ2) / (length1 * math.sqrt(dirX2 * dirX2 + dirY2 * dirY2 + dirZ2 * dirZ2) + 1e-6))
end
function MathUtil.getSignedAngleBetweenVectors2D(dirX1, dirZ1, dirX2, dirZ2)
    return math.acos(dirX1 * dirX2 + dirZ1 * dirZ2) * math.sign(dirZ1 * dirX2 + -dirX1 * dirZ2)
end
function MathUtil.getYRotationFromDirection(dx, dz)
    return math.atan2(dx, dz)
end
function MathUtil.getDirectionFromYRotation(rotY)
    return math.sin(rotY), math.cos(rotY)
end
function MathUtil.getRotationLimitedVector2(x, y, minRot, maxRot)
    local rot = -math.atan2(y, x)
    if rot < minRot or maxRot < rot then
        if rot < minRot then
            maxRot = minRot
        end
        local len = math.sqrt(x * x + y * y)
        x = math.cos(-maxRot) * len
        y = math.sin(-maxRot) * len
    end
    return x, y
end
function MathUtil.quaternionVectorMultiplication(quatX, quatY, quatZ, quatW, vecX, vecY, vecZ)
    local num = quatX * 2
    local num2 = quatY * 2
    local num3 = quatZ * 2
    local num4 = quatX * num
    local num5 = quatY * num2
    local num6 = quatZ * num3
    local num7 = quatX * num2
    local num8 = quatX * num3
    local num9 = quatY * num3
    local num10 = quatW * num
    local num11 = quatW * num2
    local num12 = quatW * num3
    return (1 - (num5 + num6)) * vecX + (num7 - num12) * vecY + (num8 + num11) * vecZ, (num7 + num12) * vecX + (1 - (num4 + num6)) * vecY + (num9 - num10) * vecZ, (num8 - num11) * vecX + (num9 + num10) * vecY + (1 - (num4 + num5)) * vecZ
end
function MathUtil.projectOnLine(px, pz, lineX, lineZ, normlineDirX, normlineDirZ)
    local dot = (px - lineX) * normlineDirX + (pz - lineZ) * normlineDirZ
    return lineX + normlineDirX * dot, lineZ + normlineDirZ * dot
end
function MathUtil.getProjectOnLineParameter(px, pz, lineX, lineZ, normlineDirX, normlineDirZ)
    return (px - lineX) * normlineDirX + (pz - lineZ) * normlineDirZ
end
function MathUtil.quaternionMult(x, y, z, w, x1, y1, z1, w1)
    return y * z1 - z * y1 + w * x1 + x * w1, z * x1 - x * z1 + w * y1 + y * w1, x * y1 - y * x1 + w * z1 + z * w1, w * w1 - x * x1 - y * y1 - z * z1
end
function MathUtil.quaternionNormalized(x, y, z, w)
    local len = math.sqrt(x * x + y * y + z * z + w * w)
    if len > 0 then
    end
    return x * len, y * len, z * len, w * len
end
function MathUtil.slerpQuaternion(x1, y1, z1, w1, x2, y2, z2, w2, t)
    local fAngle = math.acos(x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2)
    if math.abs(fAngle) < 0.01 then
        return x1, y1, z1, w1
    end
    local fInvSin = 1 / math.sin(fAngle)
    local fCoeff0 = math.sin((1 - t) * fAngle) * fInvSin
    local fCoeff1 = math.sin(t * fAngle) * fInvSin
    return x1 * fCoeff0 + x2 * fCoeff1, y1 * fCoeff0 + y2 * fCoeff1, z1 * fCoeff0 + z2 * fCoeff1, w1 * fCoeff0 + w2 * fCoeff1
end
function MathUtil.normalizeRotationForShortestPath(targetRotation, curRotation)
    while curRotation < targetRotation do
        targetRotation = targetRotation - 6.283185307179586
    end
    while targetRotation < curRotation do
        targetRotation = targetRotation + 6.283185307179586
    end
    if targetRotation - curRotation > curRotation + 6.283185307179586 - targetRotation then
    end
    return targetRotation
end
function MathUtil.nlerpQuaternionShortestPath(x1, y1, z1, w1, x2, y2, z2, w2, t)
    local x, y, z, w
    if x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2 < 0 then
        x = x1 + (-x2 - x1) * t
        y = y1 + (-y2 - y1) * t
        z = z1 + (-z2 - z1) * t
        w = w1 + (-w2 - w1) * t
    else
        x = x1 + (x2 - x1) * t
        y = y1 + (y2 - y1) * t
        z = z1 + (z2 - z1) * t
        w = w1 + (w2 - w1) * t
    end
    local len = 1 / math.sqrt(x * x + y * y + z * z + w * w)
    return x * len, y * len, z * len, w * len
end
function MathUtil.slerpQuaternionShortestPath(x1, y1, z1, w1, x2, y2, z2, w2, t)
    local fCos = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
    local fSin = math.clamp(fCos, -1, 1)
    local fAngle = math.acos(fSin)
    if math.abs(fAngle) < 0.01 then
        return x1, y1, z1, w1
    end
    local fInvSin = 1 / math.sin(fAngle)
    local fCoeff0 = math.sin((1 - t) * fAngle) * fInvSin
    local fCoeff1 = math.sin(t * fAngle) * fInvSin
    if fCos >= 0 then
        return x1 * fCoeff0 + x2 * fCoeff1, y1 * fCoeff0 + y2 * fCoeff1, z1 * fCoeff0 + z2 * fCoeff1, w1 * fCoeff0 + w2 * fCoeff1
    end
    local fCoeff0 = -fCoeff0
    local z = z1 * fCoeff0 + z2 * fCoeff1
    local w = w1 * fCoeff0 + w2 * fCoeff1
    local len = 1 / math.sqrt((x1 * fCoeff0 + x2 * fCoeff1) * (x1 * fCoeff0 + x2 * fCoeff1) + (y1 * fCoeff0 + y2 * fCoeff1) * (y1 * fCoeff0 + y2 * fCoeff1) + z * z + w * w)
    return x * len, y * len, z * len, w * len
end
function MathUtil.quaternionMadShortestPath(x, y, z, w, x1, y1, z1, w1, t)
    if x * x1 + y * y1 + z * z1 + w * w1 < 0 then
        return x - x1 * t, y - y1 * t, z - z1 * t, w - w1 * t
    else
        return x + x1 * t, y + y1 * t, z + z1 * t, w + w1 * t
    end
end
function MathUtil.getDistanceToRectangle2D(posX, posZ, sx, sz, dx, dz, length, widthHalf)
    local x = posX - sx
    local z = posZ - sz
    local lx = x * dx + z * dz
    if lx >= 0 and lx <= length then
        return math.max(math.abs(x * -dz + z * dx) - widthHalf, 0)
    elseif widthHalf < lz then
        return math.sqrt((lx - (length >= lx and 0 or length)) * (lx - (length >= lx and 0 or length)) + (lz - widthHalf) * (lz - widthHalf))
    elseif lz < -widthHalf then
        return math.sqrt((lx - tx) * (lx - tx) + (lz + widthHalf) * (lz + widthHalf))
    else
        return math.abs(lx - tx)
    end
end
function MathUtil.getSignedDistanceToLineSegment2D(x, z, sx, sz, dx, dz, length)
    local t = (x - sx) * dx + (z - sz) * dz
    if t >= 0 and t <= length then
        return (sz - z) * dx - (sx - x) * dz, 0
    end
    if t < 0 then
        return math.sqrt((sx - x) * (sx - x) + (sz - z) * (sz - z)), 1
    end
    local ex = sx + length * dx
    local ez = sz + length * dz
    return math.sqrt((ex - x) * (ex - x) + (ez - z) * (ez - z)), 2
end
function MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
    local div = dirX1 * dirZ2 - dirX2 * dirZ1
    if math.abs(div) < 0.00001 then
        return false
    else
        return true, (dirX2 * (z1 - z2) - dirZ2 * (x1 - x2)) / div, (dirX1 * (z1 - z2) - dirZ1 * (x1 - x2)) / div
    end
end
function MathUtil.getLineSegmentsIntersection(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
    local denominator = (bz2 - bz1) * (ax2 - ax1) - (bx2 - bx1) * (az2 - az1)
    if denominator ~= 0 then
        local uA = ((bx2 - bx1) * (az1 - bz1) - (bz2 - bz1) * (ax1 - bx1)) / denominator
        local uB = ((ax2 - ax1) * (az1 - bz1) - (az2 - az1) * (ax1 - bx1)) / denominator
        if uA > 0 and (uA < 1 and (uB > 0 and uB < 1)) then
            return true, ax1 + uA * (ax2 - ax1), az1 + uA * (az2 - az1)
        end
    end
    return false, 0, 0
end
function MathUtil.getLineSegmentsIntersectionParameter(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
    local denominator = (bz2 - bz1) * (ax2 - ax1) - (bx2 - bx1) * (az2 - az1)
    if denominator ~= 0 then
        local uA = ((bx2 - bx1) * (az1 - bz1) - (bz2 - bz1) * (ax1 - bx1)) / denominator
        local uB = ((ax2 - ax1) * (az1 - bz1) - (az2 - az1) * (ax1 - bx1)) / denominator
        if uA > 0 and (uA < 1 and (uB > 0 and uB < 1)) then
            return true, uA, uB
        end
    end
    return false, 0, 0
end
function MathUtil.getAreLineSegmentsIntersecting(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2, allowEndStartSamePos)
    if ax1 == bx1 and (az1 == bz1 and (ax2 == bx2 and az2 == bz2)) or ax2 == bx1 and (az2 == bz1 and (ax1 == bx2 and az1 == bz2)) then
        return true
    else
        local value = (az2 - az1) * (bx1 - ax2) - (ax2 - ax1) * (bz1 - az2)
        local o1 = value > 0 and 1 or (value < 0 and 2 or 0)
        local value = (az2 - az1) * (bx2 - ax2) - (ax2 - ax1) * (bz2 - az2)
        local value = value > 0 and 1 or (value < 0 and 2 or 0)
        local value = (bz2 - bz1) * (ax1 - bx2) - (bx2 - bx1) * (az1 - bz2)
        local value = value > 0 and 1 or (value < 0 and 2 or 0)
        local value = (bz2 - bz1) * (ax2 - bx2) - (bx2 - bx1) * (az2 - bz2)
        local value = value > 0 and 1 or (value < 0 and 2 or 0)
        if o1 == value or value == value then
            local function value(x1, z1, x2, z2, x3, z3)
                -- upvalues: (copy) allowEndStartSamePos
                if allowEndStartSamePos then
                    return x2 < math.max(x1, x3) and math.min(x1, x3) < x2 and z2 < math.max(z1, z3) and math.min(z1, z3) < z2
                else
                    return x2 <= math.max(x1, x3) and math.min(x1, x3) <= x2 and z2 <= math.max(z1, z3) and math.min(z1, z3) <= z2
                end
            end
            if o1 == 0 and value(ax1, az1, bx1, bz1, ax2, az2) then
                return true, true
            elseif value == 0 and value(ax1, az1, bx2, bz2, ax2, az2) then
                return true, true
            elseif value == 0 and value(bx1, bz1, ax1, az1, bx2, bz2) then
                return true, true
            elseif value == 0 and value(bx1, bz1, ax2, az2, bx2, bz2) then
                return true, true
            else
                return false
            end
        elseif allowEndStartSamePos and (ax1 == bx1 and az1 == bz1 or (ax1 == bx2 and az1 == bz2 or (ax2 == bx1 and az2 == bz1 or ax2 == bx2 and az2 == bz2))) then
            return false
        else
            return true, false
        end
    end
end
function MathUtil.getLineBoundingVolumeIntersect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
    return math.min(ax1, ax2) <= math.max(bx1, bx2) and math.max(ax1, ax2) >= math.min(bx1, bx2) and math.min(ay1, ay2) <= math.max(by1, by2) and math.max(ay1, ay2) >= math.min(by1, by2)
end
function MathUtil.hasRectangleLineIntersection2D(x1, z1, dirX1, dirZ1, dirX2, dirZ2, x3, z3, dirX3, dirZ3)
    local dir1Length = MathUtil.vector2Length(dirX1, dirZ1)
    local dir2Length = MathUtil.vector2Length(dirX2, dirZ2)
    local dir3Length = MathUtil.vector2Length(dirX3, dirZ3)
    local dir1Length = dir1Length == 0 and 1 or dir1Length
    local dir2Length = dir2Length == 0 and 1 or dir2Length
    local dir3Length = dir3Length == 0 and 1 or dir3Length
    local dirX1_norm = dirX1 / dir1Length
    local dirZ1_norm = dirZ1 / dir1Length
    local dirX2_norm = dirX2 / dir2Length
    local dirZ2_norm = dirZ2 / dir2Length
    local dirX3_norm = dirX3 / dir3Length
    local dirZ3_norm = dirZ3 / dir3Length
    local intersects, t1, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1, z1, dirX1_norm, dirZ1_norm)
    if intersects and (t1 > 0 and (t1 < dir3Length and (t2 > 0 and t2 < dir1Length))) then
        return true
    end
    local p1, p2, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1, z1, dirX2_norm, dirZ2_norm)
    if p1 and (p2 > 0 and (p2 < dir3Length and (t2 > 0 and t2 < dir2Length))) then
        return true
    end
    local p1, p2, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1 + dirX1, z1 + dirZ1, dirX2_norm, dirZ2_norm)
    if p1 and (p2 > 0 and (p2 < dir3Length and (t2 > 0 and t2 < dir2Length))) then
        return true
    end
    local p1, p2, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1 + dirX2, z1 + dirZ2, dirX1_norm, dirZ1_norm)
    if p1 and (p2 > 0 and (p2 < dir3Length and (t2 > 0 and t2 < dir1Length))) then
        return true
    end
    local p1 = MathUtil.getProjectOnLineParameter(x3, z3, x1, z1, dirX1_norm, dirZ1_norm)
    local p2 = MathUtil.getProjectOnLineParameter(x3, z3, x1, z1, dirX2_norm, dirZ2_norm)
    if p1 > 0 and (p1 < dir1Length and (p2 > 0 and p2 < dir2Length)) then
        local p1 = MathUtil.getProjectOnLineParameter(x3 + dirX3, z3 + dirZ3, x1, z1, dirX1_norm, dirZ1_norm)
        local p2 = MathUtil.getProjectOnLineParameter(x3 + dirX3, z3 + dirZ3, x1, z1, dirX2_norm, dirZ2_norm)
        if p1 > 0 and (p1 < dir1Length and (p2 > 0 and p2 < dir2Length)) then
            return true
        end
    end
    return false
end
function MathUtil.getCircleCircleIntersection(x1, y1, r1, x2, y2, r2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = MathUtil.vector2Length(dx, dy)
    if dist == 0 and (x1 == x2 and y1 == y2) then
        return nil
    end
    if r1 + r2 < dist then
        return nil
    end
    if dist < math.abs(r1 - r2) then
        return nil
    end
    if dist == r1 + r2 then
        return (x1 - x2) / (r1 + r2) * r1 + x2, (y1 - y2) / (r1 + r2) * r1 + y2
    end
    local x = (r1 * r1 - r2 * r2 + dist * dist) / (2 * dist)
    local v2y = y1 + dy * x / dist
    local h = math.sqrt(r1 * r1 - x * x)
    local ry = dx * (h / dist)
    return x1 + dx * x / dist + -dy * (h / dist), v2y + ry, x1 + dx * x / dist - -dy * (h / dist), v2y - ry
end
function MathUtil.hasSphereSphereIntersection(x1, y1, z1, r1, x2, y2, z2, r2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    local rsum = r1 + r2
    return dx * dx + dy * dy + dz * dz <= rsum * rsum
end
function MathUtil.getHasCircleLineIntersection(circleX, circleZ, radius, lineStartX, lineStartZ, lineEndX, lineEndZ)
    local n = math.abs((lineEndX - lineStartX) * (lineStartZ - circleZ) - (lineStartX - circleX) * (lineEndZ - lineStartZ))
    if radius < n / math.sqrt((lineEndX - lineStartX) * (lineEndX - lineStartX) + (lineEndZ - lineStartZ) * (lineEndZ - lineStartZ)) then
        return false
    end
    if d < math.sqrt((circleX - lineStartX) * (circleX - lineStartX) + (circleZ - lineStartZ) * (circleZ - lineStartZ)) - radius then
        return false
    end
    return d >= math.sqrt((circleX - lineEndX) * (circleX - lineEndX) + (circleZ - lineEndZ) * (circleZ - lineEndZ)) - radius
end
function MathUtil.getCircleLineIntersection(circleX, circleZ, radius, lineStartX, lineStartZ, lineEndX, lineEndZ, limitToLineSegment)
    local x1 = lineStartX - circleX
    local z1 = lineStartZ - circleZ
    local x2 = lineEndX - circleX
    local z2 = lineEndZ - circleZ
    local dx = x2 - x1
    local dz = z2 - z1
    local dr = (dx ^ 2 + dz ^ 2) ^ 0.5
    local d = x1 * z2 - x2 * z1
    local dis = radius ^ 2 * dr ^ 2 - d ^ 2
    if dis < 0 then
        return false
    end
    local sign = dz < 0 and 1 or -1
    local fraction1 = d * dz
    local ix1 = circleX + (fraction1 + sign * (dz < 0 and -1 or 1) * dx * dis ^ 0.5) / dr ^ 2
    local iz1 = circleZ + (-d * dx + sign * math.abs(dz) * dis ^ 0.5) / dr ^ 2
    local ix2 = circleX + (d * dz - sign * (dz < 0 and -1 or 1) * dx * dis ^ 0.5) / dr ^ 2
    local iz2 = circleZ + (-d * dx - sign * math.abs(dz) * dis ^ 0.5) / dr ^ 2
    if limitToLineSegment ~= false then
        local fraction1, fraction2
        if math.abs(dx) > math.abs(dz) then
            fraction1 = (ix1 - lineStartX) / dx
            fraction2 = (ix2 - lineStartX) / dx
        else
            fraction1 = (iz1 - lineStartZ) / dz
            fraction2 = (iz2 - lineStartZ) / dz
        end
        if fraction1 < 0 or fraction1 > 1 then
            ix1 = nil
            iz1 = nil
        end
        if fraction2 < 0 or fraction2 > 1 then
            ix2 = nil
            iz2 = nil
        end
    end
    local fraction1 = true
    if ix1 == nil then
        fraction1 = ix2 ~= nil
    end
    return fraction1, ix1, iz1, ix2, iz2
end
function MathUtil.getClosestPointOnLineSegment(startX, startY, startZ, endX, endY, endZ, targetX, targetY, targetZ)
    local dirLineX = endX - startX
    local dirLineY = endY - startY
    local dirLineZ = endZ - startZ
    local lengthSq = MathUtil.vector3LengthSq(dirLineX, dirLineY, dirLineZ)
    local distance = MathUtil.dotProduct(targetX - startX, targetY - startY, targetZ - startZ, dirLineX, dirLineY, dirLineZ) / lengthSq
    if distance < 0 then
        return startX, startY, startZ, 0
    elseif distance > 1 then
        return endX, endY, endZ, 1
    else
        return startX + dirLineX * distance, startY + dirLineY * distance, startZ + dirLineZ * distance, distance
    end
end
function MathUtil.getDistanceToLineSegment2D(startX, startZ, endX, endZ, pointX, pointZ)
    local px = endX - startX
    local py = endZ - startZ
    local u = ((pointX - startX) * px + (pointZ - startZ) * py) / (px * px + py * py)
    local u = u > 1 and 1 or (u < 0 and 0 or u)
    local dx = startX + u * px - pointX
    local dy = startZ + u * py - pointZ
    return math.sqrt(dx * dx + dy * dy)
end
function MathUtil.isPointInParallelogram(x, z, startX, startZ, widthX, widthZ, heightX, heightZ)
    local dirX = x - startX
    local dirZ = z - startZ
    local detA = widthX * heightZ - heightX * widthZ
    local n = -(dirX * widthZ - widthX * dirZ) / detA
    if n >= 0 and n <= 1 then
        local m = (dirX * heightZ - heightX * dirZ) / detA
        if m >= 0 and m <= 1 then
            return true
        end
    end
    return false
end
function MathUtil.getPointPointDistance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end
function MathUtil.getPointPointDistanceSquared(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return dx * dx + dy * dy
end
function MathUtil.areaToHa(area, pixelToSqm)
    return area * pixelToSqm / 10000
end
function MathUtil.haToSqm(area)
    return area * 10000
end
function MathUtil.inchToM(inchValue)
    return inchValue * 0.0254
end
function MathUtil.mToInch(mValue)
    return mValue / 0.0254
end
function MathUtil.msToMinutes(ms)
    return ms / 60000
end
function MathUtil.msToHours(ms)
    return ms / 3600000
end
function MathUtil.msToDays(ms)
    return ms / 86400000
end
function MathUtil.minutesToMs(minutes)
    return minutes * 60 * 1000
end
function MathUtil.hoursToMs(hours)
    return hours * 60 * 60 * 1000
end
function MathUtil.daysToMs(days)
    return days * 24 * 60 * 60 * 1000
end
function MathUtil.mpsToKmh(mps)
    return mps * 3.6
end
function MathUtil.kmhToMps(kmh)
    return kmh / 3.6
end
function MathUtil.rpmToMps(rpm, radius)
    return rpm * radius * 0.00377 / 36
end
function MathUtil.getXZWidthAndHeight(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return startWorldX, startWorldZ, widthWorldX - startWorldX, widthWorldZ - startWorldZ, heightWorldX - startWorldX, heightWorldZ - startWorldZ
end
function MathUtil.getWorldParallelogramOffset(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, offset)
    local heightDirX, heightDirZ = MathUtil.vector2Normalize(widthWorldX - startWorldX, widthWorldZ - startWorldZ)
    local offsetStartDirX, offsetStartDirZ = MathUtil.vector2Normalize(heightWorldX - startWorldX, heightWorldZ - startWorldZ)
    local offsetStartDirX, offsetStartDirZ = MathUtil.vector2Normalize(heightDirX + offsetStartDirX, heightDirZ + offsetStartDirZ)
    local alphaStart = math.acos((MathUtil.dotProduct(heightDirX, 0, heightDirZ, offsetStartDirX, 0, offsetStartDirZ))) * 0.5
    local moveStartLength = offset / math.sin(alphaStart)
    local offsetWidthDirX, offsetWidthDirZ = MathUtil.vector2Normalize(offsetStartDirX - heightDirX, offsetStartDirZ - heightDirZ)
    local newWidthWorldX = MathUtil.dotProduct(offsetStartDirX, 0, offsetStartDirZ, -heightDirX, 0, -heightDirZ)
    local alphaWidth = math.acos(newWidthWorldX) * 0.5
    local moveWidthLength = offset / math.sin(alphaWidth)
    return startWorldX - moveStartLength * offsetStartDirX, startWorldZ - moveStartLength * offsetStartDirZ, widthWorldX - moveWidthLength * offsetWidthDirX, widthWorldZ - moveWidthLength * offsetWidthDirZ, heightWorldX + moveWidthLength * offsetWidthDirX, heightWorldZ + moveWidthLength * offsetWidthDirZ
end
function MathUtil.getWorldParallelogramFromLine(x, z, endX, endZ, width)
    local dirX, dirZ = MathUtil.vector2Normalize(endX - x, endZ - z)
    local normalX = -dirZ
    local widthHalf = width * 0.5
    return x - normalX * widthHalf, z - dirX * widthHalf, x + normalX * widthHalf, z + dirX * widthHalf, endX - normalX * widthHalf, endZ - dirX * widthHalf
end
function MathUtil.getNumOfSetBits(bitmask)
    bitmask = bitmask - bit32.band(bit32.rshift(bitmask, 1), 1431655765)
    bitmask = bit32.band(bitmask, 858993459) + bit32.band(bit32.rshift(bitmask, 2), 858993459)
    bitmask = bit32.band(bitmask + bit32.rshift(bitmask, 4), 252645135) * 16843009
    return bit32.rshift(bitmask, 24)
end
function MathUtil.bitsToMask(...)
    local mask = 0
    local i = 1
    for i = i, select("#", ...) do
        mask = bit32.bor(mask, (math.pow(2, (select(i, ...)))))
    end
    return mask
end
function MathUtil.getBinary(number)
    local bits = {}
    while number > 0 do
        local rest = number % 2
        table.insert(bits, rest)
        number = (number - rest) / 2
    end
    return bits
end
function MathUtil.numberToSetBits(number)
    local bits = MathUtil.getBinary(number)
    local setBits = {}
    for i, bit in ipairs(bits) do
        if bit == 1 then
            table.insert(setBits, i - 1)
        end
    end
    return setBits
end
function MathUtil.numberToSetBitsStr(number, separator)
    local setBits = MathUtil.numberToSetBits(number)
    separator = separator or ", "
    local returnStr = ""
    for i, bit in ipairs(setBits) do
        if i > 1 then
        end
        returnStr = returnStr .. bit
    end
    return returnStr
end
function MathUtil.getNumRequiredBits(integer)
    assert(integer >= 0)
    if integer == 0 then
        return 1
    end
    return math.floor(math.log(integer, 2) + 1)
end
function MathUtil.getBrightnessFromColor(r, g, b)
    return r * 0.2125 + g * 0.7154 + b * 0.0721
end
function MathUtil.getHorizontalRotationFromDeviceGravity(x, y, z)
    if x == 0 and (y == 0 and z == 0) then
        return 0
    end
    local angle = 0
    if x <= 0 then
        local zScale0 = math.atan2(y, x)
        local angle
        if zScale0 < 0 then
            angle = zScale0 + 3.141592653589793
        else
            angle = zScale0 - 3.141592653589793
        end
        local zScale0 = math.clamp(angle, -0.43633222222222223, 0.43633222222222223)
        angle = zScale0 * math.clamp((0.9 - math.abs(z)) / 0.25, 0, 1)
    end
    return angle
end
function MathUtil.getSteeringAngleFromDeviceGravity(x, y, z)
    if x == 0 and (y == 0 and z == 0) then
        return 0
    end
    local angle = -math.asin((math.clamp(y, -1, 1)))
    local angle
    if angle > 0.06981315555555556 then
        angle = math.min(angle, 0.43633222222222223) - 0.06981315555555556
    elseif angle < -0.06981315555555556 then
        angle = math.max(angle, -0.43633222222222223) + 0.06981315555555556
    else
        angle = 0
    end
    return angle / 0.36651906666666667
end
function MathUtil.catmullRom(p0, p1, p2, p3, t)
    return 0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t)
end
function MathUtil.equalEpsilon(a, b, epsilon)
    if a == nil or b == nil then
        return false
    end
    return (epsilon or 0.0001) > math.abs(a - b)
end
function MathUtil.floatRange(startVal, endVal, step)
    if step ~= 0 and (step <= 0 or endVal >= startVal) and (step >= 0 or startVal >= endVal) then
        local currentIndex = 0
        return step > 0 and function()
            -- upvalues: (copy) startVal, (ref) currentIndex, (copy) step, (copy) endVal
            local value = startVal + currentIndex * step
            if endVal < value then
                return nil
            end
            currentIndex = currentIndex + 1
            return value
        end or function()
            -- upvalues: (copy) startVal, (ref) currentIndex, (copy) step, (copy) endVal
            local value = startVal + currentIndex * step
            if value < endVal then
                return nil
            end
            currentIndex = currentIndex + 1
            return value
        end
    end
    printError(string.format("Error: (%f, %f, %f) invalid arguments, range is endless", startVal, endVal, step))
    printCallstack()
    return function()
        return nil
    end
end
function MathUtil.smoothstep(min, max, x)
    local t = math.clamp((x - min) / (max - min), 0, 1)
    return t * t * (3 - 2 * t)
end
function MathUtil.snapValue(value, step)
    if step == 0 then
        return value
    end
    return math.round(value / step) * step
end
function MathUtil.getIndexOfFirstNonZeroFractionDigit(number)
    local fractionDigitIndex = math.abs(number)
    if fractionDigitIndex == 0 then
        return 0
    end
    local fractionDigitIndex = 0
    while fractionDigitIndex < 1 do

    end
    return fractionDigitIndex
end
function MathUtil.vector2Rotate(x, y, angle)
    local cosValue = math.cos(angle)
    local sinValue = math.sin(angle)
    return x * cosValue - y * sinValue, x * sinValue + y * cosValue
end
function MathUtil.getPolygon2DSize(vertices)
    if vertices == nil or #vertices < 3 then
        return nil
    end
    local size = 0
    local node2Index = #vertices
    local node1Index = 1
    for node1Index = node1Index, #vertices do
        local x1, _, z1 = getWorldTranslation(vertices[node1Index])
        local x2, _, z2 = getWorldTranslation(vertices[node2Index])
    end
    return math.abs(size)
end
function MathUtil.getPolygonLabel(vertices, precision)
    precision = precision or 1
    local polygonPoints = {}
    for _, vertex in ipairs(vertices) do
        local x, _, z = getWorldTranslation(vertex)
        table.insert(polygonPoints, { x, z })
    end
    local function getSegDistSq(px, py, a, b)
        local x = a[1]
        local y = a[2]
        local dx = b[1] - x
        local dy = b[2] - y
        if dx ~= 0 or dy ~= 0 then
            local t = ((px - x) * dx + (py - y) * dy) / (dx * dx + dy * dy)
            if t > 1 then
                x = b[1]
                y = b[2]
            elseif t > 0 then
            end
        end
        local dx = px - x
        local dy = py - y
        return dx * dx + dy * dy
    end
    local function pointToPolygonDist(x, y)
        -- upvalues: (copy) polygonPoints, (copy) getSegDistSq
        local inside = false
        local minDistSq = math.huge
        local j = #polygonPoints
        local i = 1
        for i = i, #polygonPoints do
            local a = polygonPoints[i]
            local b = polygonPoints[j]
            if y < a[2] ~= (y < b[2]) and x < (b[1] - a[1]) * (y - a[2]) / (b[2] - a[2]) + a[1] then
            end
            minDistSq = math.min(minDistSq, (getSegDistSq(x, y, a, b)))
        end
        if minDistSq == 0 then
            return 0
        end
        return (inside and 1 or -1) * math.sqrt(minDistSq)
    end
    local function vertex()
        -- upvalues: (copy) polygonPoints, (copy) pointToPolygonDist
        local area = 0
        local x = 0
        local y = 0
        local j = #polygonPoints
        local i = 1
        local x = 1
        for i = i, #polygonPoints, x do
            local a = polygonPoints[i]
            local b = polygonPoints[j]
            local f = a[1] * b[2] - b[1] * a[2]
        end
        if area == 0 then
            local x = polygonPoints[1][0]
            local i = polygonPoints[1][1]
            local a = pointToPolygonDist(x, i)
            return {
                ["x"] = x,
                ["y"] = i,
                ["h"] = 0,
                ["d"] = a,
                ["max"] = a + 0
            }
        else
            local x = x / area
            local i = y / area
            local a = pointToPolygonDist(x, i)
            return {
                ["x"] = x,
                ["y"] = i,
                ["h"] = 0,
                ["d"] = a,
                ["max"] = a + 0
            }
        end
    end
    local x = nil
    local _ = nil
    local z = nil
    local maxY = nil
    for k, p in ipairs(polygonPoints) do
        if k == 1 or p[1] < x then
            x = p[1]
        end
        if k == 1 or p[2] < _ then
            _ = p[2]
        end
        if k == 1 or z < p[1] then
            z = p[1]
        end
        if k == 1 or maxY < p[2] then
            maxY = p[2]
        end
    end
    local width = z - x
    local height = maxY - _
    local cellSize = math.min(width, height)
    local k = cellSize / 2
    if cellSize == 0 then
        return x, _
    end
    local p = {}
    for x = x, z, cellSize do
        for _ = _, maxY, cellSize do
            local x = x + k
            local y = _ + k
            local d = pointToPolygonDist(x, y)
            table.insert(p, {
                ["x"] = x,
                ["y"] = y,
                ["h"] = k,
                ["d"] = d,
                ["max"] = d + k * 1.4142135623730951
            })
        end
    end
    local bestCell = vertex()
    local x = x + width / 2
    local y = _ + height / 2
    local d = pointToPolygonDist(x, y)
    local y = {
        ["x"] = x,
        ["y"] = y,
        ["h"] = 0,
        ["d"] = d,
        ["max"] = d + 0
    }
    if y.d <= bestCell.d then
        y = bestCell
    end
    while #p > 0 do
        table.sort(p, function(a, b)
            return a.max < b.max
        end)
        local x = table.remove(p, 1)
        if x.d > y.d then
            y = x
        end
        if x.max - y.d > precision then
            local k = x.h / 2
            local d = x.x - k
            local x = pointToPolygonDist(d, x.y - k)
            table.insert(p, {
                ["x"] = d,
                ["y"] = y,
                ["h"] = k,
                ["d"] = x,
                ["max"] = x + k * 1.4142135623730951
            })
            local d = x.x + k
            local x = pointToPolygonDist(d, x.y - k)
            table.insert(p, {
                ["x"] = d,
                ["y"] = y,
                ["h"] = k,
                ["d"] = x,
                ["max"] = x + k * 1.4142135623730951
            })
            local d = x.x - k
            local x = pointToPolygonDist(d, x.y + k)
            table.insert(p, {
                ["x"] = d,
                ["y"] = y,
                ["h"] = k,
                ["d"] = x,
                ["max"] = x + k * 1.4142135623730951
            })
            local d = x.x + k
            local x = pointToPolygonDist(d, x.y + k)
            table.insert(p, {
                ["x"] = d,
                ["y"] = y,
                ["h"] = k,
                ["d"] = x,
                ["max"] = x + k * 1.4142135623730951
            })
        end
    end
    return y.x, y.y
end
function MathUtil.symmetricDipCurve(value, alpha, maxValue)
    return 4 * alpha * maxValue * value ^ 2 + -4 * alpha * maxValue * value + maxValue
end
function MathUtil.convertStringToNumber(value)
    local valueString = string.trim(value)
    if valueString == "" then
        return 0
    end
    local number = string.gsub(valueString, "%s+", "")
    local number = string.gsub(number, "_", "")
    local number = string.gsub(number, ",", ".")
    return tonumber(number) or 0
end