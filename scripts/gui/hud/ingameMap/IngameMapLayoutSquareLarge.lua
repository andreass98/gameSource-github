IngameMapLayoutSquareLarge = {}
local IngameMapLayoutSquareLarge_mt = Class(IngameMapLayoutSquareLarge, IngameMapLayout)
function IngameMapLayoutSquareLarge.new()
    -- upvalues: (copy) IngameMapLayoutSquareLarge_mt
    return IngameMapLayoutSquareLarge:superClass().new(IngameMapLayoutSquareLarge_mt)
end
function IngameMapLayoutSquareLarge:delete()
    delete(self.overlayMask)
    self.overlayMask = nil
    self.background:delete()
    IngameMapLayoutSquareLarge:superClass().delete(self)
end
function IngameMapLayoutSquareLarge:createComponents(_)
    self.overlayMask = createOverlayTextureFromFile("dataS/menu/hud/minimap_mask_square.png")
    self.background = g_overlayManager:createOverlay("gui.colorPreset", 0, 0, 0, 0)
    self.background:setColor(0, 0, 0, 0.75)
end
function IngameMapLayoutSquareLarge:storeScaledValues(element, _)
    local posX = g_hudAnchorLeft
    local posY = g_hudAnchorBottom
    local width, height = element:scalePixelValuesToScreenVector(700, 700)
    self.background:setDimension(width, height)
    self.background:setPosition(posX, posY)
    local mapOffsetX, mapOffsetY = element:scalePixelValuesToScreenVector(5, 5)
    self.mapSizeX, self.mapSizeY = element:scalePixelValuesToScreenVector(690, 690)
    self.mapPosX = posX + mapOffsetX
    self.mapPosY = posY + mapOffsetY
    self.coordinateFontSize = element:scalePixelToScreenHeight(14)
    self.coordOffsetX, self.coordOffsetY = element:scalePixelValuesToScreenVector(0, 4)
    self.latencyFontSize = element:scalePixelToScreenHeight(10)
    self.latencyOffsetX, self.latencyOffsetY = element:scalePixelValuesToScreenVector(0, -12)
    self.screenMapPosX = -self.mapSizeX / 2 + self.mapPosX
    self.screenMapPosY = -self.mapSizeY / 2 + self.mapPosY
    self.screenMapSizeX = self.mapSizeX * 2
    self.screenMapSizeY = self.mapSizeY * 2
end
function IngameMapLayoutSquareLarge:drawBefore()
    self.background:render()
    set2DMaskFromTexture(self.overlayMask, true, self.mapPosX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end
function IngameMapLayoutSquareLarge:drawAfter()
    set2DMaskFromTexture(0, true, 0, 0, 0, 0)
end
function IngameMapLayoutSquareLarge:drawCoordinates(text)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextBold(false)
    local x = self.mapPosX + self.mapSizeX / 2
    local y = self.mapPosY + self.coordOffsetY
    setTextColor(0, 0, 0, 1)
    renderText(x + g_pixelSizeX, y - g_pixelSizeY, self.coordinateFontSize, text)
    setTextColor(unpack(IngameMap.COLOR.COORDINATES_TEXT))
    renderText(x, y, self.coordinateFontSize, text)
    setTextAlignment(RenderText.ALIGN_LEFT)
end
function IngameMapLayoutSquareLarge:drawLatency(text, color)
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    local x = self.mapPosX + self.mapSizeX + self.latencyOffsetX
    local y = self.mapPosY + self.latencyOffsetY
    setTextColor(0, 0, 0, 1)
    renderText(x + g_pixelSizeX, y - g_pixelSizeY, self.latencyFontSize, text)
    setTextColor(unpack(color))
    renderText(x, y, self.latencyFontSize, text)
end
function IngameMapLayoutSquareLarge:getMapPosition()
    return -self.mapSizeX / 2 + self.mapPosX, -self.mapSizeY / 2 + self.mapPosY
end
function IngameMapLayoutSquareLarge:getMapSize()
    return self.mapSizeX * 2, self.mapSizeY * 2
end
function IngameMapLayoutSquareLarge:getMapAlpha()
    return 0.7
end
function IngameMapLayoutSquareLarge:getShowsToggleAction()
    return false
end
function IngameMapLayoutSquareLarge:getShowsToggleActionText()
    return true
end
function IngameMapLayoutSquareLarge:getShowSmallIconVariation()
    return true
end
function IngameMapLayoutSquareLarge:getIconZoom()
    return 0.75
end
function IngameMapLayoutSquareLarge:getHeight()
    return self.mapSizeY
end
function IngameMapLayoutSquareLarge:getWidth()
    return self.mapSizeX
end
function IngameMapLayoutSquareLarge:getPosition()
    return self.mapPosX, self.mapPosY
end
function IngameMapLayoutSquareLarge:getMapObjectPosition(objectU, objectV, width, height, rot, _)
    return objectU * self.screenMapSizeX + self.screenMapPosX - width * 0.5, (1 - objectV) * self.screenMapSizeY + self.screenMapPosY - height * 0.5, rot, true
end