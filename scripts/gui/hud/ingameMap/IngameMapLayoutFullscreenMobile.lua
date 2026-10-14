IngameMapLayoutFullscreenMobile = {}
local IngameMapLayoutFullscreenMobile_mt = Class(IngameMapLayoutFullscreenMobile, IngameMapLayout)
function IngameMapLayoutFullscreenMobile.new()
    -- upvalues: (copy) IngameMapLayoutFullscreenMobile_mt
    local self = IngameMapLayoutFullscreenMobile:superClass().new(IngameMapLayoutFullscreenMobile_mt)
    self.mapCenterX = 0.5
    self.mapCenterY = 0.5
    self.zoomFactor = 1
    self.width = 1
    self.height = 1
    return self
end
function IngameMapLayoutFullscreenMobile:delete() end
function IngameMapLayoutFullscreenMobile:createComponents(element) end
function IngameMapLayoutFullscreenMobile:storeScaledValues(element, uiScale) end
function IngameMapLayoutFullscreenMobile:drawBefore() end
function IngameMapLayoutFullscreenMobile:drawAfter() end
function IngameMapLayoutFullscreenMobile:getMapSize()
    local height = self.height * self.zoomFactor
    return height / g_screenAspectRatio, height
end
function IngameMapLayoutFullscreenMobile:getMapPosition()
    local width, height = self:getMapSize()
    return self.mapCenterX - width * 0.5, self.mapCenterY - height * 0.5
end
function IngameMapLayoutFullscreenMobile:setMapCenter(x, y)
    self.mapCenterX = x
    self.mapCenterY = y
end
function IngameMapLayoutFullscreenMobile:setMapWidth(width)
    self.width = width
    self.height = width * g_screenAspectRatio
end
function IngameMapLayoutFullscreenMobile:setMapZoom(zoomFactor)
    self.zoomFactor = zoomFactor
end
function IngameMapLayoutFullscreenMobile:getIconZoom()
    return 1
end
function IngameMapLayoutFullscreenMobile:getBlinkPlayerArrow()
    return true
end
function IngameMapLayoutFullscreenMobile:getMapObjectPosition(objectU, objectV, width, height, rot, _)
    local mapWidth, mapHeight = self:getMapSize()
    local mapX, mapY = self:getMapPosition()
    return objectU * mapWidth + mapX - width * 0.5, (1 - objectV) * mapHeight + mapY - height * 0.5, rot, true
end