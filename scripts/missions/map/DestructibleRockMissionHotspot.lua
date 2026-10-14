DestructibleRockMissionHotspot = {}
local DestructibleRockMissionHotspot_mt = Class(DestructibleRockMissionHotspot, MapHotspot)
function DestructibleRockMissionHotspot.new(customMt)
    -- upvalues: (copy) DestructibleRockMissionHotspot_mt
    local self = MapHotspot.new(customMt or DestructibleRockMissionHotspot_mt)
    self.width, self.height = getNormalizedScreenValues(50, 50)
    self.icon = g_overlayManager:createOverlay("mapHotspots.contractStone", 0, 0, self.width, self.height)
    self.circle = g_overlayManager:createOverlay("mapHotspots.circle", 0, 0, self.width, self.height)
    self.circle:setColor(0.5089, 0.016, 0.016, 1)
    self.iconSmall = g_overlayManager:createOverlay("mapHotspots.miniMapHotspot", 0, 0, self.width, self.height)
    self.iconSmall:setColor(0.00303, 0.20155, 0.01599, 1)
    self.worldRadius = 50
    self.forceNoRotation = true
    return self
end
function DestructibleRockMissionHotspot:delete()
    DestructibleRockMissionHotspot:superClass().delete(self)
    if self.icon ~= nil then
        self.icon:delete()
        self.icon = nil
    end
    if self.circle ~= nil then
        self.circle:delete()
        self.circle = nil
    end
    if self.iconSmall ~= nil then
        self.iconSmall:delete()
        self.iconSmall = nil
    end
end
function DestructibleRockMissionHotspot:setWorldRadius(worldRadius)
    self.worldRadius = worldRadius
end
function DestructibleRockMissionHotspot:postUpdate(_)
    local ingameMap = g_currentMission.hud:getIngameMap()
    local mapWidth, mapHeight = ingameMap.layout:getMapSize()
    if self.circle ~= nil then
        self.circle:setDimension(self.worldRadius / ingameMap.worldSizeX * mapWidth, self.worldRadius / ingameMap.worldSizeZ * mapHeight)
    end
end
function DestructibleRockMissionHotspot:getWidth()
    if self.circle == nil then
        return self.lastRenderedIcon == nil and 0 or self.lastRenderedIcon.width
    else
        return self.circle.width
    end
end
function DestructibleRockMissionHotspot:getHeight()
    if self.circle == nil then
        return self.lastRenderedIcon == nil and 0 or self.lastRenderedIcon.height
    else
        return self.circle.height
    end
end
function DestructibleRockMissionHotspot:getDimension()
    if self.circle == nil then
        if self.lastRenderedIcon == nil then
            return 0, 0
        else
            return self.lastRenderedIcon.width, self.lastRenderedIcon.height
        end
    else
        return self.circle.width, self.circle.height
    end
end
function DestructibleRockMissionHotspot:setScale(scale)
    if self.icon ~= nil then
        self.icon:setScale(scale, scale)
    end
    if self.iconSmall ~= nil then
        self.iconSmall:setScale(scale, scale)
    end
    if self.circle ~= nil then
        self.circle:setScale(scale + 0.5, scale + 0.5)
    end
end
function DestructibleRockMissionHotspot:getCategory()
    return MapHotspot.CATEGORY_MISSION
end
function DestructibleRockMissionHotspot:getIsPersistent()
    return false
end
function DestructibleRockMissionHotspot:getRenderLast()
    return false
end
function DestructibleRockMissionHotspot:render(x, y, _, small)
    local icon = self.icon
    if small then
        icon = self.iconSmall
    end
    self.lastRenderedIcon = icon
    local circle = self.circle
    if circle ~= nil then
        circle:setPosition(x, y)
        circle:setColor(nil, nil, nil, IngameMap.alpha)
        circle:render()
        x = x + circle.width * 0.5
        y = y + circle.height * 0.5
        if icon ~= nil then
        end
    end
    if icon ~= nil then
        icon:setPosition(x, y)
        icon:setColor(nil, nil, nil, self.isBlinking and (self:getCanBlink() and IngameMap.alpha) or 1)
        icon:render()
    end
end