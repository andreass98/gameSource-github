CollectibleHotspot = {}
local CollectibleHotspot_mt = Class(CollectibleHotspot, MapHotspot)
function CollectibleHotspot.new(collectible)
    -- upvalues: (copy) CollectibleHotspot_mt
    local self = MapHotspot.new(CollectibleHotspot_mt)
    _, self.height = getNormalizedScreenValues(40, 40)
    self.width = _
    self.icon = g_overlayManager:createOverlay("mapHotspots.other", 0, 0, self.width, self.height)
    self.color[1] = 0.8
    self.color[2] = 0.5
    self.color[3] = 0
    self.worldX, _, self.worldZ = getWorldTranslation(collectible.node)
    return self
end
function CollectibleHotspot:getCategory()
    return MapHotspot.CATEGORY_OTHER
end
function CollectibleHotspot:hasMouseOverlap(x, y)
    return false
end