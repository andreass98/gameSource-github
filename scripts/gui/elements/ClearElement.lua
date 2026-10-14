ClearElement = {}
local BitmapElement_mt = Class(ClearElement, GuiElement)
Gui.registerGuiElement("Clear", ClearElement)
function ClearElement.new(target, custom_mt)
    -- upvalues: (copy) BitmapElement_mt
    local self = GuiElement.new(target, custom_mt or BitmapElement_mt)
    self.offset = { 0, 0 }
    self.focusedOffset = { 0, 0 }
    self.overlay = {}
    return self
end
function ClearElement:delete()
    GuiOverlay.deleteOverlay(self.overlay)
    ClearElement:superClass().delete(self)
end
function ClearElement:loadFromXML(xmlFile, key)
    ClearElement:superClass().loadFromXML(self, xmlFile, key)
    GuiOverlay.loadOverlay(self, self.overlay, "clear", self.imageSize, nil, xmlFile, key)
    self.offset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#offset"), self.offset)
    self.focusedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#focusedOffset"), self.focusedOffset)
end
function ClearElement:loadProfile(profile, applyProfile)
    ClearElement:superClass().loadProfile(self, profile, applyProfile)
    GuiOverlay.loadOverlay(self, self.overlay, "clear", self.imageSize, profile, nil, nil)
    self.offset = GuiUtils.getNormalizedScreenValues(profile:getValue("offset"), self.offset)
    self.focusedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("focusedOffset"), { self.offset[1], self.offset[2] })
end
function ClearElement:copyAttributes(src)
    ClearElement:superClass().copyAttributes(self, src)
    GuiOverlay.copyOverlay(self.overlay, src.overlay)
    self.offset = table.clone(src.offset)
    self.focusedOffset = table.clone(src.focusedOffset)
end
function ClearElement:getOffset()
    local xOffset = self.offset[1]
    local yOffset = self.offset[2]
    local state = self:getOverlayState()
    if state == GuiOverlay.STATE_FOCUSED or (state == GuiOverlay.STATE_PRESSED or (state == GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_HIGHLIGHTED)) then
        xOffset = self.focusedOffset[1]
        yOffset = self.focusedOffset[2]
    end
    return xOffset, yOffset
end
function ClearElement:setImageRotation(rotation)
    self.overlay.rotation = rotation
end
function ClearElement:draw(clipX1, clipY1, clipX2, clipY2)
    local xOffset, yOffset = self:getOffset()
    clearOverlayArea(self.absPosition[1] + xOffset, self.absPosition[2] + yOffset, self.size[1], self.size[2], self.overlay.rotation, self.size[1] / 2, self.size[2] / 2)
    ClearElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
function ClearElement:canReceiveFocus()
    if not self.visible or #self.elements < 1 then
        return false
    end
    for _, v in ipairs(self.elements) do
        if not v:canReceiveFocus() then
            return false
        end
    end
    return true
end
function ClearElement:getFocusTarget()
    local _, firstElement = next(self.elements)
    return firstElement or self
end