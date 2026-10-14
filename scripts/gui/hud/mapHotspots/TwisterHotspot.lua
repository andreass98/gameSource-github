TwisterHotspot = {}
local TwisterHotspot_mt = Class(TwisterHotspot, MapHotspot)
function TwisterHotspot.new(customMt)
    -- upvalues: (copy) TwisterHotspot_mt
    local self = MapHotspot.new(customMt or TwisterHotspot_mt)
    self.width, self.height = getNormalizedScreenValues(50, 50)
    self.icon = g_overlayManager:createOverlay("mapHotspots.twister", 0, 0, self.width, self.height)
    self.forceNoRotation = true
    return self
end
function TwisterHotspot:delete()
    TwisterHotspot:superClass().delete(self)
    if self.icon ~= nil then
        self.icon:delete()
        self.icon = nil
    end
end
function TwisterHotspot:getWidth()
    return self.icon == nil and 0 or self.icon.width
end
function TwisterHotspot:getHeight()
    return self.icon == nil and 0 or self.icon.height
end
function TwisterHotspot:getCategory()
    return MapHotspot.CATEGORY_OTHER
end
function TwisterHotspot:getIsPersistent()
    return false
end
function TwisterHotspot:getRenderLast()
    return false
end
function TwisterHotspot:render(x, y, _, _)
    local icon = self.icon
    if icon ~= nil then
        icon:setPosition(x, y)
        icon:setColor(nil, nil, nil, self.isBlinking and (self:getCanBlink() and IngameMap.alpha) or 1)
        icon:render()
    end
end
function TwisterHotspot:hasMouseOverlap(x, y)
    return false
end