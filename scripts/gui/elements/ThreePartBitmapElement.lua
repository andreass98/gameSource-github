ThreePartBitmapElement = {}
local ThreePartBitmapElement_mt = Class(ThreePartBitmapElement, BitmapElement)
Gui.registerGuiElement("ThreePartBitmap", ThreePartBitmapElement)
function ThreePartBitmapElement.new(target, custom_mt)
    -- upvalues: (copy) ThreePartBitmapElement_mt
    local self = BitmapElement.new(target, custom_mt or ThreePartBitmapElement_mt)
    self.startOverlay = {}
    self.endOverlay = {}
    self.startSize = { 0, 0 }
    self.endSize = { 0, 0 }
    self.isHorizontal = true
    return self
end
function ThreePartBitmapElement:delete()
    GuiOverlay.deleteOverlay(self.startOverlay)
    GuiOverlay.deleteOverlay(self.endOverlay)
    ThreePartBitmapElement:superClass().delete(self)
end
function ThreePartBitmapElement:loadFromXML(xmlFile, key)
    ThreePartBitmapElement:superClass().loadFromXML(self, xmlFile, key)
    GuiOverlay.loadOverlay(self, self.startOverlay, "startImage", self.imageSize, nil, xmlFile, key)
    GuiOverlay.loadOverlay(self, self.endOverlay, "endImage", self.imageSize, nil, xmlFile, key)
    self.startSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#startImageSize"), self.startSize)
    self.endSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#endImageSize"), self.endSize)
    self.isHorizontal = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isHorizontal"), self.isHorizontal)
    GuiOverlay.createOverlay(self.startOverlay)
    GuiOverlay.createOverlay(self.endOverlay)
    self:setImageColor(nil, unpack(GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_NORMAL)))
end
function ThreePartBitmapElement:loadProfile(profile, applyProfile)
    ThreePartBitmapElement:superClass().loadProfile(self, profile, applyProfile)
    GuiOverlay.loadOverlay(self, self.startOverlay, "startImage", self.imageSize, profile, nil, nil)
    GuiOverlay.loadOverlay(self, self.endOverlay, "endImage", self.imageSize, profile, nil, nil)
    self.startSize = GuiUtils.getNormalizedScreenValues(profile:getValue("startImageSize"), self.startSize)
    self.endSize = GuiUtils.getNormalizedScreenValues(profile:getValue("endImageSize"), self.endSize)
    self.isHorizontal = profile:getBool("isHorizontal", self.isHorizontal)
    if self.startOverlay.filename ~= self.startOverlay.filename then
        GuiOverlay.createOverlay(self.startOverlay)
    end
    if self.endOverlay.filename ~= self.endOverlay.filename then
        GuiOverlay.createOverlay(self.endOverlay)
    end
end
function ThreePartBitmapElement:copyAttributes(src)
    ThreePartBitmapElement:superClass().copyAttributes(self, src)
    self.startSize = table.clone(src.startSize)
    self.endSize = table.clone(src.endSize)
    self.isHorizontal = src.isHorizontal
    GuiOverlay.copyOverlay(self.startOverlay, src.startOverlay)
    GuiOverlay.copyOverlay(self.endOverlay, src.endOverlay)
end
function ThreePartBitmapElement:setImageColor(state, r, g, b, a)
    ThreePartBitmapElement:superClass().setImageColor(self, state, r, g, b, a)
    local color = GuiOverlay.getOverlayColor(self.startOverlay, state)
    color[1] = r or color[1]
    color[2] = g or color[2]
    color[3] = b or color[3]
    color[4] = a or color[4]
    local color = GuiOverlay.getOverlayColor(self.endOverlay, state)
    color[1] = r or color[1]
    color[2] = g or color[2]
    color[3] = b or color[3]
    color[4] = a or color[4]
end
function ThreePartBitmapElement:draw(clipX1, clipY1, clipX2, clipY2)
    local xOffset, yOffset = self:getOffset()
    local state = self:getOverlayState()
    if self.isHorizontal then
        GuiOverlay.renderOverlay(self.startOverlay, self.absPosition[1] + xOffset, self.absPosition[2] + yOffset, self.startSize[1], self.absSize[2], state, clipX1, clipY1, clipX2, clipY2)
        GuiOverlay.renderOverlay(self.overlay, x + self.startSize[1], y, self.absSize[1] - self.startSize[1] - self.endSize[1], self.absSize[2], state, clipX1, clipY1, clipX2, clipY2)
        GuiOverlay.renderOverlay(self.endOverlay, x + self.absSize[1] - self.endSize[1], y, self.endSize[1], self.absSize[2], state, clipX1, clipY1, clipX2, clipY2)
    else
        GuiOverlay.renderOverlay(self.startOverlay, x, y + self.absSize[2] - self.startSize[2], self.absSize[1], self.startSize[2], state, clipX1, clipY1, clipX2, clipY2)
        GuiOverlay.renderOverlay(self.overlay, x, y + self.endSize[2], self.absSize[1], self.absSize[2] - self.startSize[2] - self.endSize[2], state, clipX1, clipY1, clipX2, clipY2)
        GuiOverlay.renderOverlay(self.endOverlay, x, y, self.absSize[1], self.endSize[2], state, clipX1, clipY1, clipX2, clipY2)
    end
    BitmapElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end