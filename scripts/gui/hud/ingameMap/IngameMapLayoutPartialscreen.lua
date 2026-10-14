IngameMapLayoutPartialscreen = {}
local IngameMapLayoutPartialscreen_mt = Class(IngameMapLayoutPartialscreen, IngameMapLayout)
function IngameMapLayoutPartialscreen.new()
    -- upvalues: (copy) IngameMapLayoutPartialscreen_mt
    local self = IngameMapLayoutPartialscreen:superClass().new(IngameMapLayoutPartialscreen_mt)
    self.mapCenterX = 0.5
    self.mapCenterY = 0.5
    self.worldSizeFactor = 1
    self.zoomFactor = 1.5
    self.width = 1
    self.height = 1
    self.posX = 0.5
    self.posY = 0.5
    self.centerOffsetXFactor = 0
    self.centerOffsetYFactor = 0
    self.mapExtensionScaleFactor = 0
    self.mapExtensionOffsetX = 0
    self.mapExtensionOffsetZ = 0
    self.worldCenterOffsetX = 0
    self.worldCenterOffsetZ = 0
    return self
end
function IngameMapLayoutPartialscreen:setWorldSize(worldSizeX, worldSizeZ)
    self.worldSizeFactor = worldSizeX / 2048
    self.worldCenterOffsetX = worldSizeX * 0.5
    self.worldCenterOffsetZ = worldSizeZ * 0.5
    self.worldSizeX = worldSizeX
    self.worldSizeZ = worldSizeZ
end
function IngameMapLayoutPartialscreen:getMapSize()
    local width = self.zoomFactor * self.worldSizeFactor
    return width, width * g_screenAspectRatio
end
function IngameMapLayoutPartialscreen:setMapZoomByWidthAndHeight(width, height)
    if height < width then
    end
    self.zoomFactor = height / self.worldSizeFactor
end
function IngameMapLayoutPartialscreen:setPreviewPosition(x, y)
    self.posX = x
    self.posY = y
end
function IngameMapLayoutPartialscreen:setPreviewSize(width, height)
    self.width = width
    self.height = height
end
function IngameMapLayoutPartialscreen:setMapExtensionSettings(mapExtensionScaleFactor, extensionOffsetX, extensionOffsetZ)
    self.mapExtensionScaleFactor = mapExtensionScaleFactor
    self.mapExtensionOffsetX = extensionOffsetX
    self.mapExtensionOffsetZ = extensionOffsetZ
end
function IngameMapLayoutPartialscreen:getMapPosition()
    local width, height = self:getMapSize()
    local posX = self.posX + width * self.centerOffsetXFactor + (self.width - width) * 0.5
    local posY = self.posY + height * self.centerOffsetYFactor + (self.height - height) * 0.5
    local posX = math.clamp(posX, posX - (width - self.width), self.posX)
    return posX, math.clamp(posY, posY - (height - self.height), self.posY)
end
function IngameMapLayoutPartialscreen:setCenterToWorldPosition(worldPosX, worldPosY)
    self.centerOffsetXFactor = 0.5 - localX
    self.centerOffsetYFactor = (localX + self.worldCenterOffsetZ) / self.worldSizeZ * self.mapExtensionScaleFactor + self.mapExtensionOffsetZ - 0.5
end
function IngameMapLayoutPartialscreen:setMapCenter(x, y)
    self.mapCenterX = x
    self.mapCenterY = y
end
function IngameMapLayoutPartialscreen:setMapZoom(zoomFactor)
    self.zoomFactor = zoomFactor
end
function IngameMapLayoutPartialscreen:setMapAlpha(alpha)
    self.mapAlpha = alpha
end
function IngameMapLayoutPartialscreen:getIconZoom()
    return 0.25 + self.zoomFactor * 0.25
end
function IngameMapLayoutPartialscreen:getBlinkPlayerArrow()
    return true
end
function IngameMapLayoutPartialscreen:getMapAlpha()
    return self.mapAlpha or 1
end
function IngameMapLayoutPartialscreen:getMapObjectPosition(objectU, objectV, width, height, rot, _)
    local mapWidth, mapHeight = self:getMapSize()
    local mapX, mapY = self:getMapPosition()
    return objectU * mapWidth + mapX - width * 0.5, (1 - objectV) * mapHeight + mapY - height * 0.5, rot, true
end