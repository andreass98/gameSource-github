NPCHotspot = {}
local NPCHotspot_mt = Class(NPCHotspot, MapHotspot)
function NPCHotspot.new(npc, customMt)
    -- upvalues: (copy) NPCHotspot_mt
    local self = MapHotspot.new(customMt or NPCHotspot_mt)
    self.npc = npc
    self.width, self.height = getNormalizedScreenValues(50, 50)
    self.icon = g_overlayManager:createOverlay("mapHotspots.npc", 0, 0, self.width, self.height)
    self.iconSmall = g_overlayManager:createOverlay("mapHotspots.miniMapHotspot", 0, 0, self.width, self.height)
    self.iconSmall:setColor(0.8, 0.76863, 0.03137, 1)
    self.forceNoRotation = true
    self.lastRenderedIcon = self.iconSmall
    self.clickArea = MapHotspot.getClickArea({
        9,
        13,
        82,
        82
    }, { 100, 100 }, 0)
    return self
end
function NPCHotspot:delete()
    NPCHotspot:superClass().delete(self)
    if self.icon ~= nil then
        self.icon:delete()
        self.icon = nil
    end
    if self.iconSmall ~= nil then
        self.iconSmall:delete()
        self.iconSmall = nil
    end
end
function NPCHotspot:getWidth()
    return self.lastRenderedIcon.width
end
function NPCHotspot:getHeight()
    return self.lastRenderedIcon.height
end
function NPCHotspot:getDimension()
    return self.lastRenderedIcon.width, self.lastRenderedIcon.height
end
function NPCHotspot:setScale(scale)
    self.iconSmall:setScale(scale, scale)
    if self.icon ~= nil then
        self.icon:setScale(scale, scale)
    end
    MapHotspot.setScale(self, scale)
end
function NPCHotspot:getCategory()
    return MapHotspot.CATEGORY_OTHER
end
function NPCHotspot:getIsPersistent()
    return false
end
function NPCHotspot:getRenderLast()
    return false
end
function NPCHotspot:getImageFilename()
    if self.npc == nil then
        return nil
    else
        return self.npc:getImageFilename()
    end
end
function NPCHotspot:getName()
    if self.npc == nil then
        return nil
    else
        return self.npc:getTitle()
    end
end
function NPCHotspot:getBeVisited()
    if self.npc == nil then
        return false
    else
        return self.npc:getBeVisited()
    end
end
function NPCHotspot:getNPC()
    return self.npc
end
function NPCHotspot:getTeleportWorldPosition()
    if self.npc == nil then
        return nil
    else
        return self.npc:getTeleportWorldPosition()
    end
end
function NPCHotspot:getWorldPosition()
    if self.npc == nil then
        return nil
    end
    local x, _, z = self.npc:getTeleportWorldPosition()
    return x, z
end
function NPCHotspot:render(x, y, _, small)
    local icon = self.icon
    if small then
        icon = self.iconSmall
    end
    self.lastRenderedIcon = icon
    if icon ~= nil then
        icon:renderCustom(x, y, icon.width, icon.height, nil, nil, nil, self.isBlinking and IngameMap.alpha or 1)
    end
end
NPCHotspot.getWorldRotation = MapHotspot.getWorldRotation