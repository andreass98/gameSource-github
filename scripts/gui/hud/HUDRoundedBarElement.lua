HUDRoundedBarElement = {}
local HUDRoundedBarElement_mt = Class(HUDRoundedBarElement, HUDElement)
function HUDRoundedBarElement.new(posX, posY, width, height, isHorizontal, customMt)
    -- upvalues: (copy) HUDRoundedBarElement_mt
    local overlay = Overlay.new(nil, posX, posY, width, height)
    local self = HUDElement.new(overlay, nil, customMt or HUDRoundedBarElement_mt)
    self.isHorizontal = isHorizontal or false
    self.xPadding = 0
    self.yPadding = 0
    self.value = 0
    self:createComponents()
    return self
end
function HUDRoundedBarElement:delete()
    if self.overlayFront ~= nil then
        self.overlayFront:delete()
        self.overlayFront = nil
        self.overlayMiddle:delete()
        self.overlayMiddle = nil
        self.overlayBack:delete()
        self.overlayBack = nil
        self.barOverlayFront:delete()
        self.barOverlayFront = nil
        self.barOverlayMiddle:delete()
        self.barOverlayMiddle = nil
        self.barOverlayBack:delete()
        self.barOverlayBack = nil
    end
    HUDRoundedBarElement:superClass().delete(self)
end
function HUDRoundedBarElement:createComponents()
    local sliceIds = HUDRoundedBarElement.SLICE_IDS.HORIZONTAL[self.isHorizontal]
    self.overlayFront = g_overlayManager:createOverlay(sliceIds.FRONT)
    self.overlayFront:setColor(unpack(HUDRoundedBarElement.COLOR.BACKGROUND))
    self.overlayMiddle = g_overlayManager:createOverlay(sliceIds.MIDDLE)
    self.overlayMiddle:setColor(unpack(HUDRoundedBarElement.COLOR.BACKGROUND))
    self.overlayBack = g_overlayManager:createOverlay(sliceIds.BACK)
    self.overlayBack:setColor(unpack(HUDRoundedBarElement.COLOR.BACKGROUND))
    self.barOverlayFront = g_overlayManager:createOverlay(sliceIds.FRONT)
    self.barOverlayMiddle = g_overlayManager:createOverlay(sliceIds.MIDDLE)
    self.barOverlayBack = g_overlayManager:createOverlay(sliceIds.BACK)
    self:updateComponents()
end
function HUDRoundedBarElement:setValue(value, _)
    value = math.clamp(value, 0, 1)
    if math.abs(value - self.value) > 0.005 then
        self.value = value
        self:updateComponents(true)
    end
end
function HUDRoundedBarElement:setBarColor(r, g, b)
    self.barOverlayFront:setColor(r, g, b, 1)
    self.barOverlayMiddle:setColor(r, g, b, 1)
    self.barOverlayBack:setColor(r, g, b, 1)
end
function HUDRoundedBarElement:setBarAlpha(alpha)
    self.barOverlayFront:setColor(nil, nil, nil, alpha)
    self.barOverlayMiddle:setColor(nil, nil, nil, alpha)
    self.barOverlayBack:setColor(nil, nil, nil, alpha)
end
function HUDRoundedBarElement:setPosition(x, y)
    HUDRoundedBarElement:superClass().setPosition(self, x, y)
    self:updateComponents()
end
function HUDRoundedBarElement:setAlpha(alpha)
    self.overlay:setColor(nil, nil, nil, alpha)
    self.barOverlayFront:setColor(nil, nil, nil, alpha)
    self.barOverlayMiddle:setColor(nil, nil, nil, alpha)
    self.barOverlayBack:setColor(nil, nil, nil, alpha)
    local origAlpha = HUDRoundedBarElement.COLOR.BACKGROUND[4]
    self.overlayFront:setColor(nil, nil, nil, alpha * origAlpha)
    self.overlayMiddle:setColor(nil, nil, nil, alpha * origAlpha)
    self.overlayBack:setColor(nil, nil, nil, alpha * origAlpha)
end
function HUDRoundedBarElement:setDimension(width, height)
    self.overlay:setDimension(width, height)
    self:updateComponents()
end
function HUDRoundedBarElement:updateComponents(barOnly)
    local endSizeY = g_overlayManager:getSliceInfoById(HUDRoundedBarElement.SLICE_IDS.HORIZONTAL[self.isHorizontal].BACK).uvs
    local endSizeX, endSizeY = unpack(endSizeY)
    local paddingX = getNormalizedScreenValues
    local endWidth = HUDRoundedBarElement.PADDING[self.isHorizontal]
    local paddingX, paddingY = paddingX(unpack(endWidth))
    if self.isHorizontal then
        if not barOnly then
            local endWidth = endSizeX / endSizeY * self.overlay.height
            self.overlayFront:setDimension(endWidth, height)
            self.overlayFront:setPosition(self.overlay.x, self.overlay.y)
            self.overlayMiddle:setDimension(self.overlay.width - 2 * endWidth, height)
            self.overlayMiddle:setPosition(baseX + endWidth, baseY)
            self.overlayBack:setDimension(endWidth, height)
            self.overlayBack:setPosition(baseX + width - endWidth, baseY)
        end
        local endWidth = width - 2 * paddingX
        local endWidth = height - 2 * paddingY
        local barHeight = math.max(endWidth, 1 * g_pixelSizeY)
        local endWidth = endSizeX / endSizeY * barHeight
        self.barOverlayFront:setDimension(endWidth, barHeight)
        self.barOverlayFront:setPosition(baseX + paddingX, baseY + paddingY)
        self.barOverlayMiddle:setDimension((endWidth - 2 * endWidth) * self.value + 2 * endWidth - 2 * endWidth, barHeight)
        self.barOverlayMiddle:setPosition(baseX + paddingX + endWidth, baseY + paddingY)
        self.barOverlayBack:setDimension(endWidth, barHeight)
        self.barOverlayBack:setPosition(baseX + paddingX + barWidthValued - endWidth, baseY + paddingY)
    else
        if not barOnly then
            local endWidth = endSizeY / endSizeX * width
            self.overlayFront:setDimension(width, endWidth)
            self.overlayFront:setPosition(baseX, baseY)
            self.overlayMiddle:setDimension(width, height - 2 * endWidth)
            self.overlayMiddle:setPosition(baseX, baseY + endWidth)
            self.overlayBack:setDimension(width, endWidth)
            self.overlayBack:setPosition(baseX, baseY + height - endWidth)
        end
        local endWidth = math.max(width - 2 * paddingX, g_pixelSizeX)
        local endWidth = endSizeY / endSizeX * endWidth
        self.barOverlayFront:setDimension(endWidth, endWidth)
        self.barOverlayFront:setPosition(baseX + paddingX, baseY + paddingY)
        self.barOverlayMiddle:setDimension(endWidth, (height - 2 * paddingY - 2 * endWidth) * self.value + 2 * endWidth - 2 * endWidth)
        self.barOverlayMiddle:setPosition(baseX + paddingX, baseY + paddingY + endWidth)
        self.barOverlayBack:setDimension(endWidth, endWidth)
        self.barOverlayBack:setPosition(baseX + paddingX, baseY + paddingY + barWidthValued - endWidth)
    end
end
function HUDRoundedBarElement:draw()
    if self.overlay.visible then
        self.overlayFront:render()
        self.overlayMiddle:render()
        self.overlayBack:render()
        self.barOverlayFront:render()
        self.barOverlayMiddle:render()
        self.barOverlayBack:render()
    end
end
HUDRoundedBarElement.PADDING = {
    [true] = { 3.5, 3 },
    [false] = { 3, 3.5 }
}
HUDRoundedBarElement.SLICE_IDS = {
    ["HORIZONTAL"] = {
        [true] = {
            ["FRONT"] = "gui.whiteBarHorizontalEnd",
            ["MIDDLE"] = "gui.whiteBarHorizontalMid",
            ["BACK"] = "gui.whiteBarHorizontalStart"
        },
        [false] = {
            ["FRONT"] = "gui.whiteBarVerticalEnd",
            ["MIDDLE"] = "gui.whiteBarVerticalMid",
            ["BACK"] = "gui.whiteBarVerticalStart"
        }
    }
}
HUDRoundedBarElement.COLOR = {
    ["BACKGROUND"] = {
        0,
        0,
        0,
        0.54
    }
}