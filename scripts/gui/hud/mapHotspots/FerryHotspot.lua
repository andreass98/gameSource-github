FerryHotspot = {}
local FerryHotspot_mt = Class(FerryHotspot, MapHotspot)
function FerryHotspot.new(ferry, customMt)
    -- upvalues: (copy) FerryHotspot_mt
    local self = MapHotspot.new(customMt or FerryHotspot_mt)
    self.ferry = ferry
    self.width, self.height = getNormalizedScreenValues(50, 50)
    self.icon = g_overlayManager:createOverlay("mapHotspots.ferry", 0, 0, self.width, self.height)
    self.clickArea = MapHotspot.getClickArea({
        9,
        13,
        82,
        82
    }, { 100, 100 }, 0)
    return self
end
function FerryHotspot:delete()
    FerryHotspot:superClass().delete(self)
    if self.icon ~= nil then
        self.icon:delete()
        self.icon = nil
    end
end
function FerryHotspot:getCategory()
    return MapHotspot.CATEGORY_OTHER
end
function FerryHotspot:getIsPersistent()
    return false
end
function FerryHotspot:getRenderLast()
    return false
end
function FerryHotspot:getName()
    return nil
end
function FerryHotspot:getBeVisited()
    return false
end
function FerryHotspot:getTeleportWorldPosition()
    return nil
end
function FerryHotspot:hasMouseOverlap(x, y)
    return false
end
FerryHotspot.getWorldPosition = MapHotspot.getWorldPosition
FerryHotspot.getWorldRotation = MapHotspot.getWorldRotation
FerryHotspot.setScale = MapHotspot.setScale
FerryHotspot.render = MapHotspot.render