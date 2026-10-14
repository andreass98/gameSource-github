TreeTransportMissionHotspot = {}
local TreeTransportMissionHotspot_mt = Class(TreeTransportMissionHotspot, MapHotspot)
function TreeTransportMissionHotspot.new(customMt)
    -- upvalues: (copy) TreeTransportMissionHotspot_mt
    local self = MapHotspot.new(customMt or TreeTransportMissionHotspot_mt)
    self.width, self.height = getNormalizedScreenValues(50, 50)
    self.icon = g_overlayManager:createOverlay("mapHotspots.contractWoodTransport", 0, 0, self.width, self.height)
    self.circle = g_overlayManager:createOverlay("mapHotspots.circle", 0, 0, self.width, self.height)
    self.circle:setColor(0.5089, 0.016, 0.016, 1)
    self.worldRadius = 50
    self.forceNoRotation = true
    return self
end
function TreeTransportMissionHotspot:delete()
    TreeTransportMissionHotspot:superClass().delete(self)
    if self.icon ~= nil then
        self.icon:delete()
        self.icon = nil
    end
    if self.circle ~= nil then
        self.circle:delete()
        self.circle = nil
    end
end
function TreeTransportMissionHotspot:setWorldRadius(worldRadius)
    self.worldRadius = worldRadius
end
function TreeTransportMissionHotspot:postUpdate(_)
    local ingameMap = g_currentMission.hud:getIngameMap()
    local mapWidth, mapHeight = ingameMap.layout:getMapSize()
    if self.circle ~= nil then
        self.circle:setDimension(self.worldRadius / ingameMap.worldSizeX * mapWidth, self.worldRadius / ingameMap.worldSizeZ * mapHeight)
    end
end
function TreeTransportMissionHotspot:getWidth()
    if self.circle == nil then
        return self.lastRenderedIcon == nil and 0 or self.lastRenderedIcon.width
    else
        return self.circle.width
    end
end
function TreeTransportMissionHotspot:getHeight()
    if self.circle == nil then
        return self.lastRenderedIcon == nil and 0 or self.lastRenderedIcon.height
    else
        return self.circle.height
    end
end
function TreeTransportMissionHotspot:getDimension()
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
function TreeTransportMissionHotspot:setScale(scale)
    if self.icon ~= nil then
        self.icon:setScale(scale, scale)
    end
end
function TreeTransportMissionHotspot:getCategory()
    return MapHotspot.CATEGORY_MISSION
end
function TreeTransportMissionHotspot:getIsPersistent()
    return false
end
function TreeTransportMissionHotspot:getRenderLast()
    return false
end
function TreeTransportMissionHotspot:render(x, y, _, _)
    local icon = self.icon
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