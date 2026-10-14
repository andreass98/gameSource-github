HUDSliderElement = {}
local HUDSliderElement_mt = Class(HUDSliderElement, HUDElement)
function HUDSliderElement.new(overlay, backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, touchAreaPressedGain, transAxis, minTrans, centerTrans, maxTrans, lockTrans)
    -- upvalues: (copy) HUDSliderElement_mt
    local self = HUDSliderElement:superClass().new(overlay, nil, HUDSliderElement_mt)
    self.position = { overlay.x, overlay.y }
    self.size = { overlay.width, overlay.height }
    self.transAxis = transAxis
    self.minTrans = minTrans
    self.centerTrans = centerTrans
    self.maxTrans = maxTrans
    self.lockTrans = lockTrans
    self.speed = 0.0002
    self.backgroundOverlay = backgroundOverlay
    self.overlay = overlay
    self.moveToCenterPosition = false
    self.moveToCenterSpeedFactor = 1
    self.snapPositions = {}
    self.touchAreaDown = g_touchHandler:registerTouchAreaOverlay(backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, TouchHandler.TRIGGER_DOWN, self.onSliderDown, self)
    self.touchAreaAlways = g_touchHandler:registerTouchAreaOverlay(backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, TouchHandler.TRIGGER_ALWAYS, self.onSliderAlways, self)
    self.touchAreaUp = g_touchHandler:registerTouchAreaOverlay(backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, TouchHandler.TRIGGER_UP, self.onSliderUp, self)
    g_touchHandler:setAreaPressedSizeGain(self.touchAreaDown, touchAreaPressedGain)
    g_touchHandler:setAreaPressedSizeGain(self.touchAreaAlways, touchAreaPressedGain)
    g_touchHandler:setAreaPressedSizeGain(self.touchAreaUp, touchAreaPressedGain)
    return self
end
function HUDSliderElement:delete()
    if self.overlay ~= nil and not entityExists(self.overlay.overlayId) then
        self.overlay = nil
    end
    g_touchHandler:removeTouchArea(self.touchAreaDown)
    g_touchHandler:removeTouchArea(self.touchAreaAlways)
    g_touchHandler:removeTouchArea(self.touchAreaUp)
    HUDSliderElement:superClass().delete(self)
end
function HUDSliderElement:setTouchIsActive(state)
    g_touchHandler:setTouchAreaVisibility(self.touchAreaDown, state)
    g_touchHandler:setTouchAreaVisibility(self.touchAreaAlways, state)
    g_touchHandler:setTouchAreaVisibility(self.touchAreaUp, state)
end
function HUDSliderElement:setCallback(callback, callbackTarget)
    self.callback = callback
    self.callbackTarget = callbackTarget
end
function HUDSliderElement:addSnapPosition(position)
    table.insert(self.snapPositions, position)
end
function HUDSliderElement:clearSnapPositions()
    local i = 1
    for i = i, #self.snapPositions do
        self.snapPositions[i] = nil
    end
end
function HUDSliderElement:resetSlider()
    self.moveToCenterPosition = false
    self:setAxisPosition(self.centerTrans)
end
function HUDSliderElement:onSliderDown(posX, posY, _)
    self:setAxisPosition(self:getAxisPosition(posX, posY) - self:getAxisPosition(self.parent:getPosition()) - self:getAxisPosition(unpack(self.size)) / 2)
    self.startOverlayPos = self:getAxisPosition(self:getPosition()) - self:getAxisPosition(self.parent:getPosition())
    self.lastTouchPosition = self:getAxisPosition(posX, posY)
    self.moveToCenterPosition = false
end
function HUDSliderElement:onSliderAlways(posX, posY, _)
    local touchOffset = self:getAxisPosition(posX, posY) - self.lastTouchPosition
    self:setAxisPosition(self.startOverlayPos + touchOffset)
end
function HUDSliderElement:onSliderUp(_, _, _)
    if #self.snapPositions == 0 and (self.lockTrans == nil or self:getAxisPosition(self:getPosition()) ~= self.lockTrans + self:getAxisPosition(self.parent:getPosition())) then
        self.moveToCenterPosition = true
    end
end
function HUDSliderElement:getAxisPosition(posX, posY)
    if self.transAxis == 1 then
        return posX
    else
        return self.transAxis ~= 2 and 0 or posY
    end
end
function HUDSliderElement:setAxisPosition(pos, noCallback)
    if #self.snapPositions > 0 then
        local closestSnap = -1
        local minDistance = math.huge
        local i = 1
        for i = i, #self.snapPositions do
            local diff = math.abs(pos - self.snapPositions[i])
            if diff < minDistance then
                closestSnap = i
                minDistance = diff
            end
        end
    end
    local closestSnap = math.clamp(pos, self.minTrans, self.maxTrans)
    if self.callback ~= nil and noCallback ~= true then
        closestSnap = self.callback(self.callbackTarget, (closestSnap - self.minTrans) / (self.maxTrans - self.minTrans)) or closestSnap
    end
    pos = self:getAxisPosition(self.parent:getPosition()) + closestSnap
    if self.transAxis == 1 then
        self:setPosition(pos, nil)
    elseif self.transAxis == 2 then
        self:setPosition(nil, pos)
    end
end
function HUDSliderElement:setMoveToCenterSpeedFactor(moveToCenterSpeedFactor)
    self.moveToCenterSpeedFactor = moveToCenterSpeedFactor
end
function HUDSliderElement:update(dt)
    if self.moveToCenterPosition then
        local curPosition = self:getAxisPosition(self:getPosition()) - self:getAxisPosition(self.parent:getPosition())
        if curPosition == self.centerTrans then
            self.moveToCenterPosition = false
            return
        end
        local speedFactor = math.pow(1 + math.abs(self.centerTrans - curPosition), 3) * self.moveToCenterSpeedFactor
        local direction = math.sign(self.centerTrans - curPosition)
        self:setAxisPosition(((direction == 1 and math.min or math.max)(curPosition + direction * dt * self.speed * speedFactor, self.centerTrans)))
    end
end
function HUDSliderElement:setScale(scaleWidth, scaleHeight)
    HUDSliderElement:superClass().setScale(self, scaleWidth, scaleHeight)
    self.size[1] = self.overlay.width
    self.size[2] = self.overlay.height
end
function HUDSliderElement:setRange(minTrans, centerTrans, maxTrans, lockTrans)
    self.minTrans = minTrans
    self.centerTrans = centerTrans
    self.maxTrans = maxTrans
    self.lockTrans = lockTrans
end