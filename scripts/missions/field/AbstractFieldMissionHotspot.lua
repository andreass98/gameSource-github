AbstractFieldMissionHotspot = {}
local AbstractFieldMissionHotspot_mt = Class(AbstractFieldMissionHotspot, MapHotspot)
function AbstractFieldMissionHotspot.new(customMt)
    -- upvalues: (copy) AbstractFieldMissionHotspot_mt
    local self = MapHotspot.new(customMt or AbstractFieldMissionHotspot_mt)
    self.width, self.height = getNormalizedScreenValues(50, 50)
    self.circle = g_overlayManager:createOverlay("mapHotspots.circle", 0, 0, self.width, self.height)
    self.circle:setColor(0.5089, 0.016, 0.016, 1)
    self.worldRadius = 50
    self.forceNoRotation = true
    return self
end
function AbstractFieldMissionHotspot:delete()
    AbstractFieldMissionHotspot:superClass().delete(self)
    if self.circle ~= nil then
        self.circle:delete()
        self.circle = nil
    end
end
function AbstractFieldMissionHotspot:setField(field)
    self.field = field
    local x, z = field:getIndicatorPosition()
    self:setWorldPosition(x, z)
end
function AbstractFieldMissionHotspot:setWorldRadius(worldRadius)
    self.worldRadius = worldRadius
end
function AbstractFieldMissionHotspot:postUpdate(_)
    local ingameMap = g_currentMission.hud:getIngameMap()
    local mapWidth, mapHeight = ingameMap.layout:getMapSize()
    if self.circle ~= nil then
        self.circle:setDimension(self.worldRadius / ingameMap.worldSizeX * mapWidth, self.worldRadius / ingameMap.worldSizeZ * mapHeight)
    end
end
function AbstractFieldMissionHotspot:getWidth()
    return self.circle == nil and 0 or self.circle.width
end
function AbstractFieldMissionHotspot:getHeight()
    return self.circle == nil and 0 or self.circle.height
end
function AbstractFieldMissionHotspot:getDimension()
    if self.circle == nil then
        return 0, 0
    else
        return self.circle.width, self.circle.height
    end
end
function AbstractFieldMissionHotspot:setScale(scale) end
function AbstractFieldMissionHotspot:getCategory()
    return MapHotspot.CATEGORY_MISSION
end
function AbstractFieldMissionHotspot:getIsPersistent()
    return false
end
function AbstractFieldMissionHotspot:getRenderLast()
    return false
end
function AbstractFieldMissionHotspot:render(x, y, _, _)
    local circle = self.circle
    if circle ~= nil then
        circle:setPosition(x, y)
        circle:setColor(nil, nil, nil, IngameMap.alpha)
        circle:render()
        x = x + circle.width * 0.5
        y = y + circle.height * 0.5
    end
end