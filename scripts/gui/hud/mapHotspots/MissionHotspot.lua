MissionHotspot = {}
local MissionHotspot_mt = Class(MissionHotspot, MapHotspot)
function MissionHotspot.new(customMt)
    -- upvalues: (copy) MissionHotspot_mt
    local self = MapHotspot.new(customMt or MissionHotspot_mt)
    self.width, self.height = getNormalizedScreenValues(50, 50)
    self.icon = g_overlayManager:createOverlay("mapHotspots.contract", 0, 0, self.width, self.height)
    return self
end
function MissionHotspot:getCategory()
    return MapHotspot.CATEGORY_MISSION
end
function MissionHotspot:getIsPersistent()
    return true
end
function MissionHotspot:getRenderLast()
    return true
end
function MissionHotspot:render(x, y, _, _)
    local icon = self.icon
    if icon ~= nil then
        icon:setPosition(x, y)
        if self.isBlinking and self:getCanBlink() then
            icon:setColor(nil, nil, nil, IngameMap.alpha)
        end
        icon:render()
    end
end