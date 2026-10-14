AIPlaceableMarkerHotspot = {}
AIPlaceableMarkerHotspot.SLICE_ID = "mapHotspots.missionBorder"
local AIPlaceableMarkerHotspot_mt = Class(AIPlaceableMarkerHotspot, MapHotspot)
function AIPlaceableMarkerHotspot.new(customMt)
    -- upvalues: (copy) AIPlaceableMarkerHotspot_mt
    local self = MapHotspot.new(customMt or AIPlaceableMarkerHotspot_mt)
    if Platform.isMobile then
        self.width, self.height = getNormalizedScreenValues(90, 90)
    else
        self.width, self.height = getNormalizedScreenValues(50, 50)
    end
    self.icon = g_overlayManager:createOverlay(AIPlaceableMarkerHotspot.SLICE_ID, 0, 0, self.width, self.height)
    self.isBlinking = not Platform.isMobile
    return self
end
function AIPlaceableMarkerHotspot:getCategory()
    return MapHotspot.CATEGORY_MAP_UTILITY
end
function AIPlaceableMarkerHotspot:getIsPersistent()
    return true
end
function AIPlaceableMarkerHotspot:getRenderLast()
    return true
end