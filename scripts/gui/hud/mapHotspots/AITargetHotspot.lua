AITargetHotspot = {}
local AITargetHotspot_mt = Class(AITargetHotspot, MapHotspot)
function AITargetHotspot.new(customMt)
    -- upvalues: (copy) AITargetHotspot_mt
    local self = MapHotspot.new(customMt or AITargetHotspot_mt)
    if Platform.isMobile then
        self.width, self.height = getNormalizedScreenValues(150, 150)
    else
        self.width, self.height = getNormalizedScreenValues(80, 80)
    end
    self.icon = g_overlayManager:createOverlay("mapHotspots.workerDirection", 0, 0, self.width, self.height)
    return self
end
function AITargetHotspot:getCategory()
    return MapHotspot.CATEGORY_MAP_UTILITY
end
function AITargetHotspot:getIsPersistent()
    return true
end
function AITargetHotspot:getRenderLast()
    return true
end