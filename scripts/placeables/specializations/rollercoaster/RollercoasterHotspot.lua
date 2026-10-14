RollercoasterHotspot = {}
RollercoasterHotspot.MOD_DIRECTORY = g_currentModDirectory
local RollercoasterHotspot_mt = Class(RollercoasterHotspot, PlaceableHotspot)
function RollercoasterHotspot.new(customMt)
    -- upvalues: (copy) RollercoasterHotspot_mt
    local self = PlaceableHotspot.new(customMt or RollercoasterHotspot_mt)
    self.width, self.height = getNormalizedScreenValues(50, 50)
    self.iconConstruction = g_overlayManager:createOverlay("mapHotspots.contractConstruction", 0, 0, self.width, self.height)
    self.iconRollercoaster = g_overlayManager:createOverlay("mapHotspots.rollercoaster", 0, 0, self.width, self.height)
    self.iconSmall:setColor(unpack(PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.EXCLAMATION_MARK]))
    self.activeIcon = self.iconConstruction
    self.activeCategory = MapHotspot.CATEGORY_UNLOADING
    return self
end
function RollercoasterHotspot:delete()
    RollercoasterHotspot:superClass().delete(self)
    if self.iconConstruction ~= nil then
        self.iconConstruction:delete()
        self.iconConstruction = nil
    end
    if self.iconRollercoaster ~= nil then
        self.iconRollercoaster:delete()
        self.iconRollercoaster = nil
    end
end
function RollercoasterHotspot:changeToRollercoaster()
    self.activeIcon = self.iconRollercoaster
    self.activeCategory = MapHotspot.CATEGORY_OTHER
end
function RollercoasterHotspot:setScale(scale)
    if self.iconRollercoaster ~= nil then
        self.iconRollercoaster:setScale(scale, scale)
    end
    if self.iconConstruction ~= nil then
        self.iconConstruction:setScale(scale, scale)
    end
    RollercoasterHotspot:superClass().setScale(self, scale)
end
function RollercoasterHotspot:getCategory()
    return self.activeCategory
end
function RollercoasterHotspot:getIsPersistent()
    return false
end
function RollercoasterHotspot:getRenderLast()
    return false
end
function RollercoasterHotspot:setPlaceableType(placeableType)
    RollercoasterHotspot:superClass().setPlaceableType(self, placeableType)
    if self.iconSmall ~= nil then
        self.iconSmall:setColor(unpack(PlaceableHotspot.COLOR[PlaceableHotspot.TYPE.EXCLAMATION_MARK]))
    end
end
function RollercoasterHotspot:render(x, y, rotation, small)
    local activeIcon = self.activeIcon
    if small then
        activeIcon = self.iconSmall
    end
    if activeIcon ~= nil then
        activeIcon:setPosition(x, y)
        activeIcon:setRotation(rotation or 0, activeIcon.width * 0.5, activeIcon.height * 0.5)
        activeIcon:setColor(nil, nil, nil, self.isBlinking and (self:getCanBlink() and IngameMap.alpha) or 1)
        activeIcon:render()
    end
end