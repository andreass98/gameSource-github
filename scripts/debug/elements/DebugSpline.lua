DebugSpline = {}
DebugSpline.EP_SPLINE_TIMES_TABLE = {}
local DebugSpline_mt = Class(DebugSpline, DebugElement)
function DebugSpline.new(customMt)
    -- upvalues: (copy) DebugSpline_mt
    local self = DebugSpline:superClass().new(customMt or DebugSpline_mt)
    self.splineNodeId = nil
    self.splineBvCenter = { 0, 0, 0 }
    self.splineBVRadius = 1
    self.solid = false
    self.displayEPs = false
    self.alignToGround = false
    self.defaultText = nil
    self.userAttributesStr = nil
    self.closestCamSplineTime = 0
    self.closestCamPosX = 0
    self.closestCamPosY = 0
    self.closestCamPosZ = 0
    self:setTextClipDistance(50)
    return self
end
function DebugSpline:delete()
    setVisibility(self.splineNodeId, false)
end
function DebugSpline:getShouldBeUpdated()
    if self.clipDistance ~= nil then
        local camX, camY, camZ = getWorldTranslation(g_cameraManager:getActiveCamera())
        if MathUtil.vector3Length(camX - self.splineBvCenter[1], camY - self.splineBvCenter[2], camZ - self.splineBvCenter[3]) > self.splineBVRadius + self.clipDistance then
            return false
        end
    end
    return true
end
function DebugSpline:update(_)
    if self.splineNodeId ~= nil then
        self.closestCamPosX, self.closestCamPosY, self.closestCamPosZ, self.closestCamSplineTime = DebugSpline.getClosestSplinePosAndTimeToCamera(self.splineNodeId, self.splineLength)
        if self.text == nil then
            local dx, dy, dz = getSplineDirection(self.splineNodeId, self.closestCamSplineTime)
            self.defaultText = string.format("\'%s\' (id=%d) \nl=%.2fm closed=%s numCVs=%d \nt=%.3f p=%.2fm d=%.3f %.3f %.3f%s", getName(self.splineNodeId), self.splineNodeId, self.splineLength, tostring(getIsSplineClosed(self.splineNodeId)), getSplineNumOfCV(self.splineNodeId), self.closestCamSplineTime, self.closestCamSplineTime * self.splineLength, dx, dy, dz, self.userAttributesStr or "")
        end
    end
end
function DebugSpline.getClosestSplinePosAndTimeToCamera(spline, splineLength)
    local camX, camY, camZ = getWorldTranslation(g_cameraManager:getActiveCamera())
    local closestCamPosX, closestCamPosY, closestCamPosZ, closestCamSplineTime = getClosestSplinePosition(spline, camX, camY, camZ, 0.01 / splineLength)
    local splinePos = closestCamSplineTime * splineLength
    if splinePos < 1 or splineLength - 1 < splinePos then
        local offsetSplineTime = math.min(1, splineLength / 3) / splineLength
        closestCamSplineTime = math.clamp(closestCamSplineTime, offsetSplineTime, 1 - offsetSplineTime)
        closestCamPosX, closestCamPosY, closestCamPosZ = getSplinePosition(spline, closestCamSplineTime)
    end
    return closestCamPosX, closestCamPosY, closestCamPosZ, closestCamSplineTime
end
function DebugSpline:getShouldBeDrawn()
    if g_gui == nil or not g_gui:getIsGuiVisible() then
        return (not self.clipDistance or DebugUtil.isPositionInCameraRange(self.closestCamPosX, self.closestCamPosY, self.closestCamPosZ, self.clipDistance)) and true or false
    else
        return false
    end
end
function DebugSpline:draw()
    DebugSpline.renderForNode(self.splineNodeId, self.color, self.text or self.defaultText, self.clipDistance, self.displayEPs, self.closestCamSplineTime, self.closestCamPosX, self.closestCamPosY, self.closestCamPosZ, self.textClipDistance)
end
function DebugSpline.renderForNode(splineNodeId, color, text, clipDistance, displayEPs, closestCamSplineTime, closestCamPosX, closestCamPosY, closestCamPosZ, textClipDistance)
    if closestCamSplineTime == nil then
        closestCamPosX, closestCamPosY, closestCamPosZ, closestCamSplineTime = DebugSpline.getClosestSplinePosAndTimeToCamera(splineNodeId, getSplineLength(splineNodeId))
    end
    if DebugUtil.isPositionInCameraRange(closestCamPosX, closestCamPosY, closestCamPosZ, clipDistance) then
        local r = 1
        local g = 1
        local b = 1
        local a = 1
        if color ~= nil then
            r, g, b, a = color:unpack()
        end
        local x, y, z = getSplinePosition(splineNodeId, 0)
        drawDebugPoint(x, y, z, 0, 1, 0, 1, false)
        local dx, _dy, dz = getSplinePosition(splineNodeId, 1)
        drawDebugPoint(dx, _dy, dz, 1, 0, 0, 1, false)
        if closestCamSplineTime > 0 and closestCamSplineTime < 1 then
            drawDebugPoint(closestCamPosX, closestCamPosY, closestCamPosZ, r, g, b, a, false)
        end
        if text ~= nil and (textClipDistance == nil or DebugUtil.isPositionInCameraRange(closestCamPosX, closestCamPosY, closestCamPosZ, textClipDistance)) then
            local dx, _dy, dz = getSplineDirection(splineNodeId, closestCamSplineTime)
            local offsetFactor = MathUtil.getYRotationFromDirection(dx + 0.001, dz) / 3.141592653589793
            local offset = getTextHeight(0.016, text) * offsetFactor
            Utils.renderTextAtWorldPosition(closestCamPosX, closestCamPosY, closestCamPosZ, text, 0.016, offset, r, g, b)
        end
        if displayEPs then
            local dx = getSplineNumOfCV(splineNodeId)
            local offsetFactor = 1
            local _dy = dx - 2
            local dz = 1
            for offsetFactor = offsetFactor, _dy, dz do
                local offset, epIndex, splineTime = getSplineEP(splineNodeId, offsetFactor)
                drawDebugPoint(offset, epIndex, splineTime, 1, 1, 1, 0.2, false)
                DebugSpline.EP_SPLINE_TIMES_TABLE[offsetFactor] = getTimeAtSplineCV(splineNodeId, offsetFactor)
            end
            local _dy = -1
            local dz = math.huge
            local epIndex = 1
            local offsetFactor = dx - 2
            local offset = 1
            for epIndex = epIndex, offsetFactor, offset do
                if DebugSpline.EP_SPLINE_TIMES_TABLE[epIndex] < closestCamSplineTime then
                    if _dy < epIndex then
                        _dy = epIndex
                    end
                elseif epIndex < dz then
                    dz = epIndex
                end
            end
            if _dy ~= -1 then
                local offsetFactor, offset, epIndex = getSplineEP(splineNodeId, _dy)
                if textClipDistance == nil or DebugUtil.isPositionInCameraRange(offsetFactor, offset, epIndex, textClipDistance) then
                    Utils.renderTextAtWorldPosition(offsetFactor, offset, epIndex, "EP " .. tostring(_dy), 0.012, 0.01, Color.PRESETS.LIGHTGRAY:unpack())
                end
            end
            if dz ~= math.huge then
                local offsetFactor, offset, epIndex = getSplineEP(splineNodeId, dz)
                if textClipDistance == nil or DebugUtil.isPositionInCameraRange(offsetFactor, offset, epIndex, textClipDistance) then
                    Utils.renderTextAtWorldPosition(offsetFactor, offset, epIndex, "EP " .. tostring(dz), 0.012, 0.01, Color.PRESETS.LIGHTGRAY:unpack())
                end
            end
        end
    end
end
function DebugSpline:createWithNode(spline, color, clipDistance, displayEPs)
    self.splineNodeId = spline
    if not getEffectiveVisibility(spline) then
        DebugUtil.setNodeEffectivelyVisible(spline)
    end
    local x, y, z, radius = getShapeWorldBoundingSphere(self.splineNodeId)
    self.splineBvCenter = { x, y, z }
    self.splineBVRadius = radius
    self.splineLength = getSplineLength(self.splineNodeId)
    local userAttributesStr = nil
    local uaIndex = 0
    for uaIndex = uaIndex, getNumOfUserAttributes(spline) - 1 do
        local value, name, uaType = getUserAttributeByIndex(spline, uaIndex)
        if uaType == UserAttributeType.FLOAT then
            value = string.format("%.3f", value)
        elseif uaType == UserAttributeType.INTEGER or uaType == UserAttributeType.NODE_ID then
            value = string.format("%d", value)
        end
        userAttributesStr = (userAttributesStr or "") .. string.format("\n%s=%s (%s)", name, value, EnumUtil.getName(UserAttributeType, uaType))
    end
    self.userAttributesStr = userAttributesStr
    if color ~= nil then
        self:setColor(color)
    end
    self.clipDistance = Utils.getNoNil(clipDistance, self.clipDistance)
    self.displayEPs = Utils.getNoNil(displayEPs, self.displayEPs)
    return self
end