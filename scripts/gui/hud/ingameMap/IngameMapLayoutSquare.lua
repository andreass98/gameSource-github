IngameMapLayoutSquare = {}
local IngameMapLayoutSquare_mt = Class(IngameMapLayoutSquare, IngameMapLayout)
function IngameMapLayoutSquare.new(customMt)
    -- upvalues: (copy) IngameMapLayoutSquare_mt
    local self = IngameMapLayoutSquare:superClass().new(customMt or IngameMapLayoutSquare_mt)
    self.screenMapPosX = 0
    self.screenMapPosY = 0
    self.screenMapSizeX = 0
    self.screenMapSizeY = 0
    self.velocityZoomFactor = 1
    self.playerU = 0
    self.playerV = 0
    return self
end
function IngameMapLayoutSquare:delete()
    delete(self.overlayMask)
    self.overlayMask = nil
    self.background:delete()
    self.unreadMessagesBg:delete()
    self.unreadMessages:delete()
    IngameMapLayoutSquare:superClass().delete(self)
end
function IngameMapLayoutSquare:createComponents(_)
    self.overlayMask = createOverlayTextureFromFile("dataS/menu/hud/minimap_mask_square.png")
    self.background = g_overlayManager:createOverlay("gui.colorPreset", 0, 0, 0, 0)
    self.background:setColor(0, 0, 0, 0.75)
    self.unreadMessagesBg = g_overlayManager:createOverlay("gui.gearBg", 0, 0, 0, 0)
    self.unreadMessagesBg:setColor(0, 0, 0, 0.75)
    self.unreadMessages = g_overlayManager:createOverlay("gui.newMessage", 0, 0, 0, 0)
end
function IngameMapLayoutSquare:storeScaledValues(element, _)
    local posX = g_hudAnchorLeft
    local posY = g_hudAnchorBottom
    local width, height = element:scalePixelValuesToScreenVector(256, 256)
    self.background:setDimension(width, height)
    self.background:setPosition(posX, posY)
    local mapOffsetX, mapOffsetY = element:scalePixelValuesToScreenVector(5, 5)
    local bgWidth, bgHeight = element:scalePixelValuesToScreenVector(246, 246)
    self.mapSizeX = bgWidth
    self.mapSizeY = bgHeight
    self.mapPosX = posX + mapOffsetX
    self.mapPosY = posY + mapOffsetY
    self.fontSize = element:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TEXT)
    self.coordinateFontSize = element:scalePixelToScreenHeight(14)
    local bgWidth, bgHeight = element:scalePixelValuesToScreenVector(-4, 4)
    self.coordOffsetX = bgWidth
    self.coordOffsetY = bgHeight
    self.latencyFontSize = element:scalePixelToScreenHeight(10)
    local bgWidth, bgHeight = element:scalePixelValuesToScreenVector(0, -12)
    self.latencyOffsetX = bgWidth
    self.latencyOffsetY = bgHeight
    local bgWidth, bgHeight = element:scalePixelValuesToScreenVector(38, 38)
    local bgOffsetX, bgOffsetY = element:scalePixelValuesToScreenVector(0, 262)
    self.unreadMessagesBg:setDimension(bgWidth, bgHeight)
    self.unreadMessagesBg:setPosition(posX + bgOffsetX, posY + bgOffsetY)
    local iconWidth, iconHeight = element:scalePixelValuesToScreenVector(32, 32)
    local iconOffsetX, iconOffsetY = element:scalePixelValuesToScreenVector(3, 259)
    self.unreadMessages:setDimension(iconWidth, iconHeight)
    self.unreadMessages:setPosition(posX + iconOffsetX, posY + iconOffsetY)
end
function IngameMapLayoutSquare:drawBefore()
    self.background:render()
    set2DMaskFromTexture(self.overlayMask, true, self.mapPosX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end
function IngameMapLayoutSquare:drawAfter()
    set2DMaskFromTexture(0, true, 0, 0, 0, 0)
    if self.hasMessages then
        self.unreadMessagesBg:render()
        self.unreadMessages:render()
    end
end
function IngameMapLayoutSquare:drawCoordinates(text)
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
function IngameMapLayoutSquare:drawLatency(text, color)
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    local x = self.mapPosX + self.mapSizeX + self.latencyOffsetX
    local y = self.mapPosY + self.latencyOffsetY
    setTextColor(0, 0, 0, 1)
    renderText(x + g_pixelSizeX, y - g_pixelSizeY, self.latencyFontSize, text)
    setTextColor(unpack(color))
    renderText(x, y, self.latencyFontSize, text)
    setTextAlignment(RenderText.ALIGN_LEFT)
end
function IngameMapLayoutSquare:setPlayerPosition(x, z, yRot)
    self.playerU = x * 0.5 + 0.25
    self.playerV = (1 - z) * 0.5 + 0.25
    self.playerRot = yRot
end
function IngameMapLayoutSquare:setPlayerVelocity(speed)
    self.velocityZoomFactor = math.clamp(speed / 50, 0, 1)
end
function IngameMapLayoutSquare:setWorldSize(worldSizeX, _)
    self.worldSizeFactor = worldSizeX / 2048
end
function IngameMapLayoutSquare:setHasUnreadMessages(hasMessages)
    self.hasMessages = hasMessages
end
function IngameMapLayoutSquare:postUpdate(_)
    self:updateScreenValues()
end
function IngameMapLayoutSquare:activate()
    self:updateScreenValues()
end
function IngameMapLayoutSquare:updateScreenValues()
    local width = (1 - 0.25 * self.velocityZoomFactor) * self.worldSizeFactor
    self.screenMapSizeX = width
    self.screenMapSizeY = width * g_screenAspectRatio
    self.screenMapPosX = self.mapPosX + self.mapSizeX / 2 - self.playerU * self.screenMapSizeX
    self.screenMapPosY = self.mapPosY + self.mapSizeY / 2 - self.playerV * self.screenMapSizeY
end
function IngameMapLayoutSquare:getMapPosition()
    return self.screenMapPosX, self.screenMapPosY
end
function IngameMapLayoutSquare:getMapSize()
    return self.screenMapSizeX, self.screenMapSizeY
end
function IngameMapLayoutSquare:getMapAlpha()
    return 0.7
end
function IngameMapLayoutSquare:getShowsToggleAction()
    return false
end
function IngameMapLayoutSquare:getShowsToggleActionText()
    return true
end
function IngameMapLayoutSquare:getShowSmallIconVariation()
    return true
end
function IngameMapLayoutSquare:getIconZoom()
    return 0.5
end
function IngameMapLayoutSquare:getHeight()
    return self.mapSizeY
end
function IngameMapLayoutSquare:getWidth()
    return self.mapSizeX
end
function IngameMapLayoutSquare:getPosition()
    return self.mapPosX, self.mapPosY
end
function IngameMapLayoutSquare:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
    local mapPosX = self.mapPosX
    local mapPosY = self.mapPosY
    local mapSizeX = self.mapSizeX
    local mapSizeY = self.mapSizeY
    local objectX = objectU * self.screenMapSizeX + self.screenMapPosX - width * 0.5
    local objectY = (1 - objectV) * self.screenMapSizeY + self.screenMapPosY - height * 0.5
    if persistent then
        objectX = math.clamp(objectX, mapPosX - width * 0.5, mapPosX + mapSizeX - width * 0.5)
        objectY = math.clamp(objectY, mapPosY - height * 0.5, mapPosY + mapSizeY - height * 0.5)
    end
    local minY = mapPosY - height
    local maxY = mapPosY + mapSizeY + height
    if objectX < mapPosX - width or (mapPosX + mapSizeX + width < objectX or (objectY < minY or maxY < objectY)) then
        return 0, 0, 0, false
    else
        return objectX, objectY, rot, true
    end
end