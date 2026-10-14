NavigationMarker = {}
local NavigationMarker_mt = Class(NavigationMarker)
function NavigationMarker.new(customMt)
    -- upvalues: (copy) NavigationMarker_mt
    local self = setmetatable({}, customMt or NavigationMarker_mt)
    self.isVisible = false
    self.worldPosX = 0
    self.worldPosY = 0
    self.worldPosZ = 0
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
    local width, height = getNormalizedScreenValues(50 * uiScale, 50 * uiScale)
    self.width = width
    self.height = height
    self.overlayMarker = g_overlayManager:createOverlay("gui.navigation_circle", 0, 0, width, height)
    self.overlayMarker:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
    self.overlayMarker:setColor(0.4564, 0.0176, 0.0194, 1)
    local arrowWidth, arrowHeight = getNormalizedScreenValues(15 * uiScale, 23 * uiScale)
    self.overlayMarkerArrow = g_overlayManager:createOverlay("gui.navigation_marker", 0, 0, arrowWidth, arrowHeight)
    self.overlayMarkerArrow:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
    local _, textSize = getNormalizedScreenValues(0, size * 0.3)
    self.textSize = textSize
    self.borderX, self.borderY = getNormalizedScreenValues(size * 0.9, size * 0.9)
    self.minDistance = 3
    return self
end
function NavigationMarker:delete()
    self.overlayMarker:delete()
    self.overlayMarkerArrow:delete()
end
function NavigationMarker:setVisibility(isVisible)
    self.isVisible = isVisible
end
function NavigationMarker:setWorldPosition(x, y, z)
    self.worldPosX = x
    self.worldPosY = y
    self.worldPosZ = z
end
function NavigationMarker:render()
    if self.isVisible then
        new2DLayer()
        if g_localPlayer == nil then
            return
        else
            local x, y, z = g_localPlayer:getPosition()
            local distance = MathUtil.vector3Length(self.worldPosX - x, self.worldPosY - y, self.worldPosZ - z)
            if distance >= self.minDistance then
                local fadeFactor = MathUtil.lerp(0, 1, (math.min(1, distance - self.minDistance)))
                local camera = g_cameraManager:getActiveCamera()
                local cx, cy, cz = worldToLocal(camera, self.worldPosX, self.worldPosY, self.worldPosZ)
                local nClip = getNearClip(camera)
                if -nClip < cz then
                    local b = -nClip
                    local c = b / math.sin(getFovY(camera) * 0.5)
                    cx = math.sqrt(-b * b + c * c) * math.sign(cx)
                    local b = -nClip
                    local c = b / math.sin(getFovY(camera) * 0.5 * g_screenAspectRatio)
                    cy = math.sqrt(-b * b + c * c) * math.sign(cy)
                end
                local b = math.min(cz, -nClip)
                local b, c, a = localToWorld(camera, cx, cy, b)
                local sx, sy, _sz = project(b, c, a)
                local isClampedX = false
                local clampedY
                if sx < self.borderX or 1 - self.borderX < sx then
                    clampedY = math.clamp(sx, self.borderX, 1 - self.borderX)
                    isClampedX = true
                else
                    clampedY = sx
                end
                local isClampedY = false
                local alpha
                if sy < self.borderY or 1 - self.borderY < sy then
                    alpha = math.clamp(sy, self.borderY, 1 - self.borderY)
                    isClampedY = true
                else
                    alpha = sy
                end
                local alpha = MathUtil.lerp
                local angle = math.sin(g_time / 400)
                local alpha = alpha(0.4, 1, (math.abs(angle)))
                self.overlayMarker:setColor(nil, nil, nil, alpha * fadeFactor)
                self.overlayMarker:setPosition(clampedY, alpha)
                self.overlayMarker:render()
                if isClampedX or isClampedY then
                    local dx, dy = MathUtil.vector2Normalize(sx - 0.5, sy - 0.5)
                    local angle = -math.atan2(dx, dy) + 1.5707963267948966
                    self.overlayMarkerArrow:setColor(nil, nil, nil, alpha * fadeFactor)
                    self.overlayMarkerArrow:setRotation(angle, self.overlayMarkerArrow.width * 0.5, self.overlayMarkerArrow.height * 0.5)
                    self.overlayMarkerArrow:setPosition(clampedY + dx * self.width * 0.7, alpha + dy * self.height * 0.7)
                    self.overlayMarkerArrow:render()
                end
                setTextColor(1, 1, 1, alpha * fadeFactor)
                setTextBold(true)
                setTextAlignment(RenderText.ALIGN_CENTER)
                setTextLineHeightScale(0.8)
                setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
                setTextWrapWidth(self.width * 0.1, false)
                renderText(clampedY, alpha, self.textSize, g_i18n:formatDistance(distance))
                setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
                setTextBold(false)
                setTextWrapWidth(0)
                setTextAlignment(RenderText.ALIGN_LEFT)
                setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
            end
        end
    else
        return
    end
end