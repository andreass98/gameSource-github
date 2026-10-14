IngameMapLayoutCircle = {}
local IngameMapLayoutCircle_mt = Class(IngameMapLayoutCircle, IngameMapLayout)
local HALF_PI = 1.5707963267948966
function IngameMapLayoutCircle.new()
    -- upvalues: (copy) IngameMapLayoutCircle_mt
    local self = IngameMapLayoutCircle:superClass().new(IngameMapLayoutCircle_mt)
    self.screenMapPosX = 0
    self.screenMapPosY = 0
    self.screenMapSizeX = 0
    self.screenMapSizeY = 0
    self.velocityZoomFactor = 1
    self.playerU = 0
    self.playerV = 0
    return self
end
function IngameMapLayoutCircle:delete()
    delete(self.overlayMask)
    self.overlayMask = nil
    self.background:delete()
    self.northArrow:delete()
    self.unreadMessagesBg:delete()
    self.unreadMessages:delete()
    IngameMapLayoutCircle:superClass().delete(self)
end
function IngameMapLayoutCircle:createComponents(_)
    self.overlayMask = createOverlayTextureFromFile("dataS/menu/hud/minimap_mask.png")
    self.background = g_overlayManager:createOverlay("gui.minimapFrame", 0, 0, 0, 0)
    self.background:setColor(0, 0, 0, 0.75)
    self.northArrow = g_overlayManager:createOverlay("gui.tourdialogue_arrow", 0, 0, 0, 0)
    self.northArrow:setColor(0.5, 0.5, 0.5, 0.9)
    self.unreadMessagesBg = g_overlayManager:createOverlay("gui.gearBg", 0, 0, 0, 0)
    self.unreadMessagesBg:setColor(0, 0, 0, 0.75)
    self.unreadMessages = g_overlayManager:createOverlay("gui.newMessage", 0, 0, 0, 0)
end
function IngameMapLayoutCircle:storeScaledValues(element, _)
    local posX = g_hudAnchorLeft
    local posY = g_hudAnchorBottom
    local width, height = element:scalePixelValuesToScreenVector(256, 256)
    self.background:setDimension(width, height)
    self.background:setPosition(posX, posY)
    local arrowWidth, arrowHeight = element:scalePixelValuesToScreenVector(9, 7)
    self.northArrow:setDimension(arrowWidth, arrowHeight)
    local mapOffsetX, mapOffsetY = element:scalePixelValuesToScreenVector(10, 10)
    local bgWidth, bgHeight = element:scalePixelValuesToScreenVector(236, 236)
    self.mapSizeX = bgWidth
    self.mapSizeY = bgHeight
    self.mapPosX = posX + mapOffsetX
    self.mapPosY = posY + mapOffsetY
    self.fontSize = element:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TEXT)
    self.coordinateFontSize = element:scalePixelToScreenHeight(14)
    local bgWidth, bgHeight = element:scalePixelValuesToScreenVector(0, 12)
    self.coordOffsetX = bgWidth
    self.coordOffsetY = bgHeight
    self.latencyFontSize = element:scalePixelToScreenHeight(10)
    local bgWidth, bgHeight = element:scalePixelValuesToScreenVector(0, -12)
    self.latencyOffsetX = bgWidth
    self.latencyOffsetY = bgHeight
    local bgWidth, bgHeight = element:scalePixelValuesToScreenVector(38, 38)
    local bgOffsetX, bgOffsetY = element:scalePixelValuesToScreenVector(0, 218)
    self.unreadMessagesBg:setDimension(bgWidth, bgHeight)
    self.unreadMessagesBg:setPosition(posX + bgOffsetX, posY + bgOffsetY)
    local iconWidth, iconHeight = element:scalePixelValuesToScreenVector(32, 32)
    local iconOffsetX, iconOffsetY = element:scalePixelValuesToScreenVector(3, 221)
    self.unreadMessages:setDimension(iconWidth, iconHeight)
    self.unreadMessages:setPosition(posX + iconOffsetX, posY + iconOffsetY)
end
function IngameMapLayoutCircle:activate()
    self:updateScreenValues()
end
function IngameMapLayoutCircle:postUpdate(_)
    self:updateScreenValues()
end
function IngameMapLayoutCircle:updateScreenValues()
    local width = (1 - 0.25 * self.velocityZoomFactor) * self.worldSizeFactor
    self.screenMapSizeX = width
    self.screenMapSizeY = width * g_screenAspectRatio
    self.screenMapPosX = self.mapPosX + self.mapSizeX / 2 - self.playerU * self.screenMapSizeX
    self.screenMapPosY = self.mapPosY + self.mapSizeY / 2 - self.playerV * self.screenMapSizeY
end
function IngameMapLayoutCircle:drawBefore()
    set2DMaskFromTexture(self.overlayMask, true, self.mapPosX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end
function IngameMapLayoutCircle:drawAfter()
    set2DMaskFromTexture(0, true, 0, 0, 0, 0)
    self.background:render()
    if self.hasMessages then
        self.unreadMessagesBg:render()
        self.unreadMessages:render()
    end
    self:drawNorthArrow(-self.playerRot + 1.5707963267948966)
end
function IngameMapLayoutCircle:drawCoordinates(text)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextBold(false)
    local x = self.mapPosX + self.mapSizeX / 2
    local y = self.mapPosY + self.coordOffsetY
    setTextColor(0, 0, 0, 1)
    renderText(x + g_pixelSizeX, y - g_pixelSizeY, self.coordinateFontSize, text)
    setTextColor(1, 1, 1, 1)
    renderText(x, y, self.coordinateFontSize, text)
    setTextAlignment(RenderText.ALIGN_LEFT)
end
function IngameMapLayoutCircle:drawLatency(text, color)
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_CENTER)
    local x = self.mapPosX + self.mapSizeX / 2 + self.latencyOffsetX
    local y = self.mapPosY + self.mapSizeY + self.latencyOffsetY
    setTextColor(0, 0, 0, 1)
    renderText(x + g_pixelSizeX, y - g_pixelSizeY, self.latencyFontSize, text)
    setTextColor(color[1], color[2], color[3], color[4])
    renderText(x, y, self.latencyFontSize, text)
    setTextAlignment(RenderText.ALIGN_LEFT)
end
function IngameMapLayoutCircle:drawNorthArrow(rotation)
    -- upvalues: (copy) HALF_PI
    local radiusX = self.mapSizeX / 2
    local radiusY = self.mapSizeY / 2
    local pivotX = self.northArrow.width * 0.5
    local cosRot = math.cos(rotation)
    local sinRot = math.sin(rotation)
    self.northArrow:setPosition(self.mapPosX + radiusX + cosRot * radiusX - pivotX, self.mapPosY + radiusY + sinRot * radiusY - 0)
    self.northArrow:setRotation(rotation - 1.5707963267948966, pivotX, 0)
    self.northArrow:render()
end
function IngameMapLayoutCircle:setPlayerPosition(x, z, yRot)
    self.playerU = x * 0.5 + 0.25
    self.playerV = (1 - z) * 0.5 + 0.25
    self.playerRot = yRot + 3.141592653589793
end
function IngameMapLayoutCircle:setPlayerVelocity(speed)
    self.velocityZoomFactor = math.clamp(speed / 50, 0, 1)
end
function IngameMapLayoutCircle:setWorldSize(worldSizeX, _)
    self.worldSizeFactor = worldSizeX / 2048
end
function IngameMapLayoutCircle:setHasUnreadMessages(hasMessages)
    self.hasMessages = hasMessages
end
function IngameMapLayoutCircle:getMapPosition()
    return self.screenMapPosX, self.screenMapPosY
end
function IngameMapLayoutCircle:getMapPivot()
    local mapWidth, mapHeight = self:getMapSize()
    return self.playerU * mapWidth, self.playerV * mapHeight
end
function IngameMapLayoutCircle:getMapRotation()
    return -self.playerRot
end
function IngameMapLayoutCircle:getMapSize()
    return self.screenMapSizeX, self.screenMapSizeY
end
function IngameMapLayoutCircle:getMapAlpha()
    return 0.7
end
function IngameMapLayoutCircle:getShowsToggleAction()
    return false
end
function IngameMapLayoutCircle:getShowSmallIconVariation()
    return true
end
function IngameMapLayoutCircle:getShowsToggleActionText()
    return true
end
function IngameMapLayoutCircle:getIconZoom()
    return 0.5
end
function IngameMapLayoutCircle:getHeight()
    return self.mapSizeY
end
function IngameMapLayoutCircle:getWidth()
    return self.mapSizeX
end
function IngameMapLayoutCircle:getPosition()
    return self.mapPosX, self.mapPosY
end
function IngameMapLayoutCircle:rotateWithMap(x, y, rot, lockToBorder)
    local angle = -self.playerRot
    local s = math.sin(angle)
    local c = math.cos(angle)
    local cx = self.mapPosX + self.mapSizeX / 2
    local cy = self.mapPosY + self.mapSizeY / 2
    x = (x - cx) * g_screenAspectRatio
    y = y - cy
    local xNew = x * c - y * s
    local yNew = x * s + y * c
    if lockToBorder then
        local length = math.sqrt(xNew * xNew + yNew * yNew)
        local factor = math.min(self.mapSizeY / 2 / length, 1)
        xNew = xNew * factor
        yNew = yNew * factor
    end
    return xNew / g_screenAspectRatio + cx, yNew * 1 + cy, rot + angle
end
function IngameMapLayoutCircle:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
    local minX, maxX, minY = self:rotateWithMap(objectU * self.screenMapSizeX + self.screenMapPosX, (1 - objectV) * self.screenMapSizeY + self.screenMapPosY, rot, persistent)
    local objectX = minX - width * 0.5
    local objectY = maxX - height * 0.5
    local minY = self.mapPosY - 2 * height
    if objectX < self.mapPosX - 2 * width or (self.mapPosX + self.mapSizeX + 2 * width < objectX or (objectY < minY or self.mapPosY + self.mapSizeY + 2 * height < objectY)) then
        return 0, 0, 0, false
    else
        return objectX, objectY, minY, true
    end
end