HUDFrameElement = {}
local HUDFrameElement_mt = Class(HUDFrameElement, HUDElement)
function HUDFrameElement.new(posX, posY, width, height, parent, showBar, frameThickness, barThickness)
    -- upvalues: (copy) HUDFrameElement_mt
    local backgroundOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY, width, height)
    backgroundOverlay:setColor(0, 0, 0, 0)
    local self = HUDElement.new(backgroundOverlay, parent, HUDFrameElement_mt)
    self.topLine = nil
    self.leftLine = nil
    self.rightLine = nil
    self.bottomBar = nil
    self.frameWidth = 0
    self.frameHeight = 0
    self.showBar = Utils.getNoNil(showBar, true)
    self.frameThickness = frameThickness or HUDFrameElement.THICKNESS.FRAME
    self.barThickness = barThickness or HUDFrameElement.THICKNESS.BAR
    self:createComponents(posX, posY, width, height)
    return self
end
function HUDFrameElement:createComponents(baseX, baseY, width, height)
    local onePixelY = math.max(1 / g_referenceScreenHeight, g_pixelSizeY)
    local frameWidth, frameHeight = getNormalizedScreenValues(self.frameThickness, self.frameThickness)
    local pixelsY = math.ceil(frameHeight / onePixelY)
    self.frameWidth = lineOverlay * posX
    self.frameHeight = pixelsY * onePixelY
    g_overlayManager:createOverlay(g_plainColorSliceId, baseX, baseY + self:getHeight() - self.frameHeight, width, self.frameHeight):setColor(unpack(HUDFrameElement.COLOR.FRAME))
    self.topLine = HUDElement.new(lineOverlay)
    self:addChild(lineElement)
    local barSize = g_overlayManager:createOverlay(g_plainColorSliceId, baseX, baseY + self.frameHeight, self.frameWidth, height - self.frameHeight * 2)
    barSize:setColor(unpack(HUDFrameElement.COLOR.FRAME))
    local barSize = HUDElement.new(barSize)
    self.leftLine = barSize
    self:addChild(barSize)
    local barSize = g_overlayManager:createOverlay(g_plainColorSliceId, baseX + width - self.frameWidth, baseY + self.frameHeight, self.frameWidth, height - self.frameHeight * 2)
    barSize:setColor(unpack(HUDFrameElement.COLOR.FRAME))
    local barSize = HUDElement.new(barSize)
    self.rightLine = barSize
    self:addChild(barSize)
    local barSize = self.barThickness
    local barColor = HUDFrameElement.COLOR.BAR
    if not self.showBar then
        barSize = self.frameThickness
        barColor = HUDFrameElement.COLOR.FRAME
    end
    local _, barHeight = getNormalizedScreenValues(0, barSize)
    local barOverlay = math.ceil(barHeight / onePixelY)
    local barOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, baseX, baseY, width, barOverlay * onePixelY)
    barOverlay:setColor(unpack(barColor))
    self.bottomBar = HUDElement.new(barOverlay)
    self:addChild(barElement)
end
function HUDFrameElement:setDimension(width, height)
    HUDFrameElement:superClass().setDimension(self, width, height)
    local lineHeight = nil
    if height ~= nil then
        lineHeight = height - self.frameHeight * 2
    end
    self.topLine:setDimension(width, nil)
    self.leftLine:setDimension(nil, lineHeight)
    self.rightLine:setDimension(nil, lineHeight)
    self.bottomBar:setDimension(width, nil)
    local x, y = self:getPosition()
    self.topLine:setPosition(nil, y + self:getHeight() - self.frameHeight)
    self.rightLine:setPosition(x + self:getWidth() - self.frameWidth, nil)
end
function HUDFrameElement:setBottomBarHeight(height)
    self.bottomBar:setDimension(nil, height)
end
function HUDFrameElement:setBottomBarColor(r, g, b, a)
    self.bottomBar:setColor(r, g, b, a)
end
function HUDFrameElement:setLeftLineVisible(visible)
    self.leftLine:setVisible(visible)
end
function HUDFrameElement:setRightLineVisible(visible)
    self.rightLine:setVisible(visible)
end
function HUDFrameElement:setFrameColor(r, g, b, a)
    self.topLine:setColor(r, g, b, a)
    self.leftLine:setColor(r, g, b, a)
    self.rightLine:setColor(r, g, b, a)
    self.bottomBar:setColor(r, g, b, a)
end
HUDFrameElement.THICKNESS = {
    ["FRAME"] = 1,
    ["BAR"] = 4
}
HUDFrameElement.COLOR = {
    ["FRAME"] = {
        1,
        1,
        1,
        0.3
    },
    ["BAR"] = {
        0.0227,
        0.5346,
        0.8519,
        1
    }
}