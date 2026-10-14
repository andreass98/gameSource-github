IngameMapLayoutMobile = {}
local IngameMapLayoutMobile_mt = Class(IngameMapLayoutMobile, IngameMapLayoutSquare)
function IngameMapLayoutMobile.new()
    -- upvalues: (copy) IngameMapLayoutMobile_mt
    local self = IngameMapLayoutMobile:superClass().new(IngameMapLayoutMobile_mt)
    self.mapOffsetX = 0
    return self
end
function IngameMapLayoutMobile:storeScaledValues(element, _)
    self.mapPosX = element:scalePixelToScreenVector(IngameMapLayoutMobile.POSITION.MAP)
    self.mapSizeX, self.mapSizeY = element:scalePixelToScreenVector(IngameMapLayoutMobile.SIZE.MAP)
    self.mapPosY = IngameMapMobile.HEIGHT_FACTOR - self.mapSizeY * 0.5
end
function IngameMapLayoutMobile:setPlayerPosition(x, z, yRot)
    self.playerU = x
    self.playerV = 1 - z
    self.playerRot = yRot
end
function IngameMapLayoutMobile:getMapPosition()
    local mapWidth, mapHeight = self:getMapSize()
    local mapPosX = self.mapPosX + self.mapOffsetX
    local mapPosY = self.mapPosY
    return math.max(math.min(mapPosX + self.mapSizeX * 0.5 - self.playerU * mapWidth, mapPosX), mapPosX + self.mapSizeX - mapWidth), math.max(math.min(mapPosY + self.mapSizeY * 0.5 - self.playerV * mapHeight, mapPosY), mapPosY + self.mapSizeY - mapHeight)
end
function IngameMapLayoutMobile:getShowsToggleAction()
    return false
end
function IngameMapLayoutMobile:getShowsToggleActionText()
    return true
end
function IngameMapLayoutMobile:getIconZoom()
    return 1.25
end
function IngameMapLayoutMobile:getMapAlpha()
    return 0.85
end
function IngameMapLayoutMobile:setOffset(x)
    self.mapOffsetX = x
end
function IngameMapLayoutMobile:drawBefore()
    set2DMaskFromTexture(self.overlayMask, true, self.mapPosX + self.mapOffsetX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end
function IngameMapLayoutMobile:setWorldSize(_, _)
    self.worldSizeFactor = 1.1
end
function IngameMapLayoutMobile:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
    local mapWidth, mapHeight = self:getMapSize()
    local mapX, mapY = self:getMapPosition()
    local objectX = mapX + objectU * mapWidth - width * 0.5
    local objectY = mapY + (1 - objectV) * mapHeight - height * 0.5
    local mapPosX = self.mapPosX + self.mapOffsetX
    local mapPosY = self.mapPosY
    if persistent then
        objectX = math.clamp(objectX, mapPosX, mapPosX + self.mapSizeX - width)
        objectY = math.clamp(objectY, mapPosY, mapPosY + self.mapSizeY - height)
    end
    local maxY = mapPosY + self.mapSizeY + height
    if objectX < mapPosX - width or (mapPosX + self.mapSizeX + width < objectX or (objectY < mapPosY - height or maxY < objectY)) then
        return 0, 0, 0, false
    else
        return objectX, objectY, rot, true
    end
end
IngameMapLayoutMobile.SIZE = {
    ["MAP"] = { 464, 470 }
}
IngameMapLayoutMobile.POSITION = {
    ["MAP"] = { 2, 306 }
}