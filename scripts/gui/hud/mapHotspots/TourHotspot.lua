TourHotspot = {}
local TourHotspot_mt = Class(TourHotspot, MapHotspot)
function TourHotspot.new(customMt)
    -- upvalues: (copy) TourHotspot_mt
    local self = MapHotspot.new(customMt or TourHotspot_mt)
    if Platform.isMobile then
        local circleFilename, circleUVs = getNormalizedScreenValues(90, 90)
        self.width = circleFilename
        self.height = circleUVs
    else
        local circleFilename, circleUVs = getNormalizedScreenValues(50, 50)
        self.width = circleFilename
        self.height = circleUVs
    end
    local circleFilename = Utils.getFilename("$dataS/menu/hud/hud_elements.png", "")
    local circleUVs = GuiUtils.getUVs({
        48,
        291,
        256,
        256
    }, { 1024, 1024 })
    self.icon = Overlay.new(circleFilename, 0, 0, self.width, self.height)
    self.icon:setUVs(circleUVs)
    self.icon:setColor(0.5089, 0.016, 0.016, 1)
    self.forceNoRotation = true
    return self
end
function TourHotspot:getCategory()
    return MapHotspot.CATEGORY_TOUR
end
function TourHotspot:getIsPersistent()
    return true
end
function TourHotspot:getRenderLast()
    return true
end
function TourHotspot:render(x, y, _, _)
    local icon = self.icon
    if icon ~= nil then
        icon:setPosition(x, y)
        icon:setColor(nil, nil, nil, IngameMap.alpha)
        icon:render()
    end
end