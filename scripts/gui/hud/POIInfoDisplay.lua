local data = nil
if POIInfoDisplay ~= nil then
    local old = g_currentMission.hud.poiInfoDisplay
    data = {
        ["text"] = old.text,
        ["uiScale"] = old.uiScale
    }
    old:delete()
end
POIInfoDisplay = {}
local old = Class(POIInfoDisplay, HUDDisplayElement)
function POIInfoDisplay.new()
    -- upvalues: (copy) old
    local backgroundOverlay = POIInfoDisplay.createBackground()
    local self = POIInfoDisplay:superClass().new(backgroundOverlay, nil, old)
    self.text = ""
    self.r, self.g, self.b, self.a = unpack(POIInfoDisplay.COLOR.BACKGROUND)
    self:applyValues(1)
    local posX, posY = self:getPosition()
    local overlay = g_overlayManager:createOverlay(POIInfoDisplay.SLICE_IDS.ICON, posX + self.iconOffsetX, posY + self.iconOffsetY, self.iconSizeX, self.iconSizeY)
    overlay:setColor(1, 1, 1, 1)
    self:addChild(HUDElement.new(overlay))
    return self
end
function POIInfoDisplay:setText(text)
    self.text = text
end
function POIInfoDisplay:draw()
    if self.text ~= "" then
        local posX, posY = self:getPosition()
        local height = self:getHeight()
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
        setTextColor(1, 1, 1, 1)
        local width = getTextWidth(self.textSize, self.text) + self.offsetLeft + self.offsetRight
        drawFilledRectRound(posX, posY, width, height, self.uiScale, self.r, self.g, self.b, self.a)
        renderText(posX + self.offsetLeft, posY + self.offsetBottom, self.textSize, self.text)
        POIInfoDisplay:superClass().draw(self)
    end
end
function POIInfoDisplay:setScale(uiScale)
    POIInfoDisplay:superClass().setScale(self, uiScale, uiScale)
    self.uiScale = uiScale
    local posX, posY = POIInfoDisplay.getBackgroundPosition(uiScale)
    self:setPosition(posX, posY)
    self:applyValues(uiScale)
end
function POIInfoDisplay:applyValues(uiScale)
    local offsetLeft, _ = getNormalizedScreenValues(POIInfoDisplay.POSITION.OFFSET_LEFT, 0)
    self.offsetLeft = offsetLeft * uiScale
    local offsetRight, _ = getNormalizedScreenValues(POIInfoDisplay.POSITION.OFFSET_RIGHT, 0)
    self.offsetRight = offsetRight * uiScale
    local _, offsetBottom = getNormalizedScreenValues(0, POIInfoDisplay.POSITION.OFFSET_BOTTOM)
    self.offsetBottom = offsetBottom * uiScale
    local _, textSize = getNormalizedScreenValues(0, POIInfoDisplay.SIZE.TEXT)
    self.textSize = textSize * uiScale
    local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(POIInfoDisplay.SIZE.ICON))
    self.iconSizeX = iconSizeX * uiScale
    self.iconSizeY = iconSizeY * uiScale
    local iconOffsetX, iconOffsetY = getNormalizedScreenValues(unpack(POIInfoDisplay.POSITION.ICON_OFFSET))
    self.iconOffsetX = iconOffsetX * uiScale
    self.iconOffsetY = iconOffsetY * uiScale
end
function POIInfoDisplay.getBackgroundPosition(uiScale)
    local _, height = getNormalizedScreenValues(unpack(POIInfoDisplay.SIZE.SELF))
    local offsetX, offsetY = getNormalizedScreenValues(unpack(POIInfoDisplay.POSITION.SELF))
    return offsetX * uiScale, 1 + offsetY * uiScale - height * uiScale
end
function POIInfoDisplay.createBackground()
    local posX, posY = POIInfoDisplay.getBackgroundPosition(1)
    local width, height = getNormalizedScreenValues(unpack(POIInfoDisplay.SIZE.SELF))
    return Overlay.new(nil, posX, posY, width, height)
end
POIInfoDisplay.SIZE = {
    ["SELF"] = { 340, 46 },
    ["BOX_MARGIN"] = 20,
    ["TEXT"] = 32,
    ["ICON"] = { 40, 40 }
}
POIInfoDisplay.POSITION = {
    ["ICON_OFFSET"] = { 15, 3 },
    ["SELF"] = { 33, -127 },
    ["OFFSET_LEFT"] = 61,
    ["OFFSET_RIGHT"] = 20,
    ["OFFSET_BOTTOM"] = 13
}
POIInfoDisplay.COLOR = {
    ["BACKGROUND"] = {
        0,
        0,
        0,
        0.4
    }
}
POIInfoDisplay.SLICE_IDS = {
    ["ICON"] = "gui.exclamationCircle"
}
if data ~= nil then
    local poiInfoDisplay = POIInfoDisplay.new()
    poiInfoDisplay:setScale(data.uiScale)
    poiInfoDisplay:setText(data.text)
    for k, elem in ipairs(g_currentMission.hud.displayComponents) do
        if elem == g_currentMission.hud.poiInfoDisplay then
            g_currentMission.hud.displayComponents[k] = poiInfoDisplay
            break
        end
    end
    g_currentMission.hud.poiInfoDisplay = poiInfoDisplay
    Logging.info("Reloaded")
end