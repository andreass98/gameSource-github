ColorPickButtonElement = {}
local ColorPickButtonElement_mt = Class(ColorPickButtonElement, ButtonElement)
ColorPickButtonElement.ICON_SCALE = 0.5
ColorPickButtonElement.BRIGHTNESS_THRESHOLD = 0.2
Gui.registerGuiElement("ColorPickButton", ColorPickButtonElement)
function ColorPickButtonElement.new(target, custom_mt)
    -- upvalues: (copy) ColorPickButtonElement_mt
    local self = ColorPickButtonElement:superClass().new(target, custom_mt or ColorPickButtonElement_mt)
    self.selectionFrameThickness = { 0, 0 }
    self.selectionFrameColor = {
        1,
        1,
        1,
        1
    }
    self.material = ColorPickerDialog.MATERIAL_GLOSSY
    self.glossyIcon = g_overlayManager:createOverlay("gui.glossyBig")
    self.glossyIcon:setScale(ColorPickButtonElement.ICON_SCALE, ColorPickButtonElement.ICON_SCALE)
    self.metallicIcon = g_overlayManager:createOverlay("gui.metallicBig")
    self.metallicIcon:setScale(ColorPickButtonElement.ICON_SCALE, ColorPickButtonElement.ICON_SCALE)
    self.matteIcon = g_overlayManager:createOverlay("gui.matteBig")
    self.matteIcon:setScale(ColorPickButtonElement.ICON_SCALE, ColorPickButtonElement.ICON_SCALE)
    return self
end
function ColorPickButtonElement:loadFromXML(xmlFile, key)
    ColorPickButtonElement:superClass().loadFromXML(self, xmlFile, key)
    self.selectionFrameThickness = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#selectionFrameThickness"), self.selectionFrameThickness)
    self.selectionFrameColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#selectionFrameColor"), self.selectionFrameColor)
end
function ColorPickButtonElement:loadProfile(profile, applyProfile)
    ColorPickButtonElement:superClass().loadProfile(self, profile, applyProfile)
    self.selectionFrameThickness = GuiUtils.getNormalizedScreenValues(profile:getValue("selectionFrameThickness"), self.selectionFrameThickness)
    self.selectionFrameColor = GuiUtils.getColorArray(profile:getValue("selectionFrameColor"), self.selectionFrameColor)
end
function ColorPickButtonElement:copyAttributes(src)
    ColorPickButtonElement:superClass().copyAttributes(self, src)
    self.selectionFrameThickness = table.clone(src.selectionFrameThickness)
    self.selectionFrameColor = table.clone(src.selectionFrameColor)
    self.material = src.material
end
function ColorPickButtonElement:onGuiSetupFinished()
    ColorPickButtonElement:superClass().onGuiSetupFinished(self)
    local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_NORMAL)
    color[1] = 1
    color[2] = 1
    color[3] = 1
    color[4] = 1
    local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_HIGHLIGHTED)
    color[1] = 1
    color[2] = 1
    color[3] = 1
    color[4] = 0.5
    local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_SELECTED)
    color[1] = 1
    color[2] = 1
    color[3] = 1
    color[4] = 1
    local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_FOCUSED)
    color[1] = 1
    color[2] = 1
    color[3] = 1
    color[4] = 1
    local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_DISABLED)
    color[1] = 1
    color[2] = 1
    color[3] = 1
    color[4] = 1
end
function ColorPickButtonElement:delete()
    self.glossyIcon:delete()
    self.metallicIcon:delete()
    self.matteIcon:delete()
    ColorPickButtonElement:superClass().delete(self)
end
function ColorPickButtonElement:draw(clipX1, clipY1, clipX2, clipY2)
    local posX1 = GuiUtils.alignValueToScreenPixels(self.absPosition[1], true)
    local posY1 = GuiUtils.alignValueToScreenPixels(self.absPosition[2], true)
    local width = GuiUtils.alignValueToScreenPixels(self.absSize[1], true)
    local height = GuiUtils.alignValueToScreenPixels(self.absSize[2], false)
    if self:getIsSelected() or self:getIsFocused() then
        GuiOverlay.renderOverlay(self.overlay, posX1 + 7 * g_pixelSizeScaledX, posY1 + 7 * g_pixelSizeScaledY, width - 14 * g_pixelSizeScaledX, height - 14 * g_pixelSizeScaledY, self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)
        local r, g, b, a = unpack(self.selectionFrameColor)
        drawFilledRect(posX1, posY1, width, self.selectionFrameThickness[2], r, g, b, a, clipX1, clipY1, clipX2, clipY2)
        drawFilledRect(posX1, posY1 + height - self.selectionFrameThickness[2], width, self.selectionFrameThickness[2], r, g, b, a, clipX1, clipY1, clipX2, clipY2)
        drawFilledRect(posX1, posY1, self.selectionFrameThickness[1], height, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
        drawFilledRect(posX1 + width - self.selectionFrameThickness[1], posY1, self.selectionFrameThickness[1], height, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
    else
        GuiOverlay.renderOverlay(self.overlay, posX1, posY1, width, height, self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)
    end
    if self.debugEnabled or g_uiDebugEnabled then
        local selectedX = GuiUtils.alignValueToScreenPixels(self.absPosition[1] + self.absSize[1] - g_pixelSizeX, false)
        local selectedY = GuiUtils.alignValueToScreenPixels(self.absPosition[2] + self.absSize[2] - g_pixelSizeY, false)
        drawFilledRect(posX1, posY1, selectedX - posX1, g_pixelSizeY, 0, 1, 0, 0.7)
        drawFilledRect(posX1, selectedY, selectedX - posX1, g_pixelSizeY, 0, 1, 0, 0.7)
        drawFilledRect(posX1, posY1, g_pixelSizeX, selectedY - posY1, 0, 1, 0, 0.7)
        drawFilledRect(posX1 + selectedX - posX1, posY1, g_pixelSizeX, selectedY - posY1, 0, 1, 0, 0.7)
    end
    if self.material == ColorPickerDialog.MATERIAL_GLOSSY then
        self.glossyIcon:render(clipX1, clipY1, clipX2, clipY2, 1)
        return
    elseif self.material == ColorPickerDialog.MATERIAL_METALLIC then
        self.metallicIcon:render(clipX1, clipY1, clipX2, clipY2)
    elseif self.material == ColorPickerDialog.MATERIAL_MATTE then
        self.matteIcon:render(clipX1, clipY1, clipX2, clipY2)
    end
end
function ColorPickButtonElement:setColor(r, g, b, a)
    local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_NORMAL)
    color[1] = r
    color[2] = g
    color[3] = b
    color[4] = a or 1
    local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_HIGHLIGHTED)
    color[1] = r
    color[2] = g
    color[3] = b
    color[4] = a or 0.5
    local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_SELECTED)
    color[1] = r
    color[2] = g
    color[3] = b
    color[4] = a or 1
    local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_FOCUSED)
    color[1] = r
    color[2] = g
    color[3] = b
    color[4] = a or 1
    local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_DISABLED)
    color[1] = r
    color[2] = g
    color[3] = b
    color[4] = a or 1
    if MathUtil.getBrightnessFromColor(r, g, b) >= ColorPickButtonElement.BRIGHTNESS_THRESHOLD then
        self.glossyIcon:setColor(0, 0, 0)
        self.metallicIcon:setColor(0, 0, 0)
        self.matteIcon:setColor(0, 0, 0)
    else
        self.glossyIcon:setColor(1, 1, 1)
        self.metallicIcon:setColor(1, 1, 1)
        self.matteIcon:setColor(1, 1, 1)
    end
end
function ColorPickButtonElement:setMaterial(material)
    self.material = material
end
function ColorPickButtonElement:setIsMatte(isMatte)
    if isMatte then
        self:setMaterial(ColorPickerDialog.MATERIAL_MATTE)
    else
        self:setMaterial(ColorPickerDialog.MATERIAL_GLOSSY)
    end
end
function ColorPickButtonElement:setIsMetallic(isMetallic)
    if isMetallic then
        self:setMaterial(ColorPickerDialog.MATERIAL_METALLIC)
    else
        self:setMaterial(ColorPickerDialog.MATERIAL_GLOSSY)
    end
end
function ColorPickButtonElement:setPosition(x, y)
    ColorPickButtonElement:superClass().setPosition(self, x, y)
    if self.glossyIcon ~= nil then
        self:setIconPositions(self.absPosition[1] + self.absSize[1] - self.glossyIcon.width - 6 * g_pixelSizeX, self.absPosition[2] + 6 * g_pixelSizeY)
    end
end
function ColorPickButtonElement:setIconPositions(iconX, iconY)
    self.glossyIcon:setPosition(iconX, iconY)
    self.metallicIcon:setPosition(iconX, iconY)
    self.matteIcon:setPosition(iconX, iconY)
end
function ColorPickButtonElement.setColors(_, r1, g1, b1, r2, g2, b2)
    log("SET COLORS", r1, g1, b1, r2, g2, b2)
end