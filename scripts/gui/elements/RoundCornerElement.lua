RoundCornerElement = {}
local RoundCornerElement_mt = Class(RoundCornerElement, GuiElement)
Gui.registerGuiElement("RoundCorner", RoundCornerElement)
function RoundCornerElement.new(target, custom_mt)
    -- upvalues: (copy) RoundCornerElement_mt
    local self = GuiElement.new(target, custom_mt or RoundCornerElement_mt)
    self.color = {
        1,
        1,
        1,
        1
    }
    self.cornerSize = 1
    return self
end
function RoundCornerElement:loadFromXML(xmlFile, key)
    RoundCornerElement:superClass().loadFromXML(self, xmlFile, key)
    self.color = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#color")) or self.color
    self.colorDisabled = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#colorDisabled")) or self.colorDisabled
    self.colorHighlighted = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#colorHighlighted")) or self.colorHighlighted
    self.colorSelected = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#colorSelected")) or self.colorSelected
    self.colorFocused = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#colorFocused")) or self.colorFocused
    self.colorPressed = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#colorPressed")) or self.colorPressed
    self.cornerSize = getXMLFloat(xmlFile, key .. "#cornerSize") or self.cornerSize
end
function RoundCornerElement:loadProfile(profile, applyProfile)
    RoundCornerElement:superClass().loadProfile(self, profile, applyProfile)
    self.color = GuiUtils.getColorGradientArray(profile:getValue("color")) or self.color
    self.colorDisabled = GuiUtils.getColorGradientArray(profile:getValue("colorDisabled")) or self.colorDisabled
    self.colorFocused = GuiUtils.getColorGradientArray(profile:getValue("colorFocused")) or self.colorFocused
    self.colorSelected = GuiUtils.getColorGradientArray(profile:getValue("colorSelected")) or self.colorSelected
    self.colorHighlighted = GuiUtils.getColorGradientArray(profile:getValue("colorHighlighted")) or self.colorHighlighted
    self.colorPressed = GuiUtils.getColorGradientArray(profile:getValue("colorPressed")) or self.colorPressed
    self.cornerSize = tonumber(profile:getValue("cornerSize", self.cornerSize))
end
function RoundCornerElement:copyAttributes(src)
    RoundCornerElement:superClass().copyAttributes(self, src)
    self.color = table.copyIndex(src.color)
    if src.colorDisabled ~= nil then
        self.colorDisabled = table.copyIndex(src.colorDisabled)
    end
    if src.colorFocused ~= nil then
        self.colorFocused = table.copyIndex(src.colorFocused)
    end
    if src.colorSelected ~= nil then
        self.colorSelected = table.copyIndex(src.colorSelected)
    end
    if src.colorPressed ~= nil then
        self.colorPressed = table.copyIndex(src.colorPressed)
    end
    if src.colorHighlighted ~= nil then
        self.colorHighlighted = table.copyIndex(src.colorHighlighted)
    end
    self.cornerSize = src.cornerSize
end
function RoundCornerElement:getColor()
    local returnColor = nil
    if self:getIsDisabled() then
        returnColor = self.colorDisabled
    elseif self.getIsPressed == nil or not self:getIsPressed() then
        if self:getIsSelected() then
            returnColor = self.colorSelected
        elseif self:getIsFocused() then
            returnColor = self.colorFocused
        elseif self:getIsHighlighted() then
            returnColor = self.colorHighlighted
        end
    else
        returnColor = self.colorPressed
    end
    return returnColor or self.color
end
function RoundCornerElement:draw(clipX1, clipY1, clipX2, clipY2)
    local color = self:getColor()
    drawFilledRectRound(self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self.cornerSize, color[1], color[2], color[3], color[4], clipX1, clipY1, clipX2, clipY2)
    RoundCornerElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end