IngameMapLayoutFullscreen = {}
local IngameMapLayoutFullscreen_mt = Class(IngameMapLayoutFullscreen, IngameMapLayout)
function IngameMapLayoutFullscreen.new()
    -- upvalues: (copy) IngameMapLayoutFullscreen_mt
    local self = IngameMapLayoutFullscreen:superClass().new(IngameMapLayoutFullscreen_mt)
    self.mapCenterX = 0.5
    self.mapCenterY = 0.5
    self.zoomFactor = 1
    return self
end
function IngameMapLayoutFullscreen:delete() end
function IngameMapLayoutFullscreen:createComponents(element) end
function IngameMapLayoutFullscreen:storeScaledValues(element, uiScale) end
function IngameMapLayoutFullscreen:drawBefore() end
function IngameMapLayoutFullscreen:drawAfter() end
function IngameMapLayoutFullscreen:getMapSize()
    local height = 2 * self.zoomFactor * self.sizeRatio
    return height / g_screenAspectRatio, height
end
function IngameMapLayoutFullscreen:getMapPosition()
    local width, height = self:getMapSize()
    return self.mapCenterX - width * 0.5, self.mapCenterY - height * 0.5
end
function IngameMapLayoutFullscreen:setMapCenter(x, y)
    self.mapCenterX = x
    self.mapCenterY = y
end
function IngameMapLayoutFullscreen:setMapWidth(width)
    self.sizeRatio = width * g_screenAspectRatio
end
function IngameMapLayoutFullscreen:setMapZoom(zoomFactor)
    self.zoomFactor = zoomFactor
end
function IngameMapLayoutFullscreen:getIconZoom()
    return math.min(0.25 + self.zoomFactor * 0.25, 0.75)
end
function IngameMapLayoutFullscreen:getBlinkPlayerArrow()
    return true
end
function IngameMapLayoutFullscreen:getMapObjectPosition(objectU, objectV, width, height, rot, _)
    local mapWidth, mapHeight = self:getMapSize()
    local mapX, mapY = self:getMapPosition()
    return objectU * mapWidth + mapX - width * 0.5, (1 - objectV) * mapHeight + mapY - height * 0.5, rot, true
end