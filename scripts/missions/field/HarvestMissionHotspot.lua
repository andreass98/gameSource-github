HarvestMissionHotspot = {}
local HarvestMissionHotspot_mt = Class(HarvestMissionHotspot, MapHotspot)
function HarvestMissionHotspot.new(customMt)
    -- upvalues: (copy) HarvestMissionHotspot_mt
    local self = MapHotspot.new(customMt or HarvestMissionHotspot_mt)
    self.width, self.height = getNormalizedScreenValues(50, 50)
    self.circle = g_overlayManager:createOverlay("mapHotspots.circle", 0, 0, self.width, self.height)
    self.circle:setColor(0.5089, 0.016, 0.016, 1)
    self.worldRadius = 50
    self.forceNoRotation = true
    return self
end
function HarvestMissionHotspot:delete()
    HarvestMissionHotspot:superClass().delete(self)
    if self.circle ~= nil then
        self.circle:delete()
        self.circle = nil
    end
end
function HarvestMissionHotspot:setWorldRadius(worldRadius)
    self.worldRadius = worldRadius
end
function HarvestMissionHotspot:postUpdate(_)
    local ingameMap = g_currentMission.hud:getIngameMap()
    local mapWidth, mapHeight = ingameMap.layout:getMapSize()
    if self.circle ~= nil then
        self.circle:setDimension(self.worldRadius / ingameMap.worldSizeX * mapWidth, self.worldRadius / ingameMap.worldSizeZ * mapHeight)
    end
end
function HarvestMissionHotspot:getWidth()
    return self.circle == nil and 0 or self.circle.width
end
function HarvestMissionHotspot:getHeight()
    return self.circle == nil and 0 or self.circle.height
end
function HarvestMissionHotspot:getDimension()
    if self.circle == nil then
        return 0, 0
    else
        return self.circle.width, self.circle.height
    end
end
function HarvestMissionHotspot:setScale(scale) end
function HarvestMissionHotspot:getCategory()
    return MapHotspot.CATEGORY_MISSION
end
function HarvestMissionHotspot:getIsPersistent()
    return false
end
function HarvestMissionHotspot:getRenderLast()
    return false
end
function HarvestMissionHotspot:render(x, y, _, _)
    local circle = self.circle
    if circle ~= nil then
        circle:setPosition(x, y)
        circle:setColor(nil, nil, nil, IngameMap.alpha)
        circle:render()
        x = x + circle.width * 0.5
        y = y + circle.height * 0.5
    end
end