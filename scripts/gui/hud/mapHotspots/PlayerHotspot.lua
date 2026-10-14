PlayerHotspot = {}
local PlayerHotspot_mt = Class(PlayerHotspot, MapHotspot)
function PlayerHotspot.new(customMt)
    -- upvalues: (copy) PlayerHotspot_mt
    local self = MapHotspot.new(customMt or PlayerHotspot_mt)
    if Platform.isMobile then
        self.width, self.height = getNormalizedScreenValues(120, 120)
    else
        self.width, self.height = getNormalizedScreenValues(60, 60)
    end
    self.icon = g_overlayManager:createOverlay("mapHotspots.playerPosition", 0, 0, self.width, self.height)
    self.icon:setColor(unpack(self.color))
    self.vehicle = nil
    self.player = nil
    self.isBlinking = not Platform.isMobile
    if Platform.isMobile then
        self.clickArea = MapHotspot.getClickCircle(0.5)
        return self
    else
        self.clickArea = MapHotspot.getClickArea({
            32,
            40,
            36,
            46
        }, { 100, 100 }, 0)
        return self
    end
end
function PlayerHotspot:delete()
    PlayerHotspot:superClass().delete(self)
    self.vehicle = nil
    self.player = nil
end
function PlayerHotspot:getRenderLast()
    return true
end
function PlayerHotspot:getCategory()
    return MapHotspot.CATEGORY_PLAYER
end
function PlayerHotspot:getWorldPosition()
    local x = nil
    local z = nil
    if self.vehicle == nil or self.vehicle:getIsBeingDeleted() then
        if self.player ~= nil then
            x, _, z = self.player:getPosition()
        end
    else
        x, _, z = getWorldTranslation(self.vehicle.rootNode)
    end
    return x, z
end
function PlayerHotspot:getWorldRotation()
    if self.vehicle == nil or self.vehicle:getIsBeingDeleted() then
        return self.player == nil and 0 or MathUtil.getValidLimit(3.141592653589793 + self.player:getYaw())
    else
        return self.vehicle:getMapHotspotRotation(true)
    end
end
function PlayerHotspot:setVehicle(vehicle)
    self.vehicle = vehicle
end
function PlayerHotspot:getVehicle()
    return self.vehicle
end
function PlayerHotspot:setPlayer(player)
    self.player = player
end
function PlayerHotspot:getPlayer()
    return self.player
end
function PlayerHotspot:setOwnerFarmId(farmId)
    MapHotspot.setOwnerFarmId(self, farmId)
    if g_currentMission.missionDynamicInfo.isMultiplayer then
        local farm = g_farmManager:getFarmById(self.ownerFarmId)
        if farm ~= nil then
            local color = Farm.COLORS[farm.color]
            self:setColor(color[1], color[2], color[3])
            return
        end
        self:setColor(1, 1, 1)
    end
end
function PlayerHotspot:getCanBlink()
    return self.lastScreenLayout:getBlinkPlayerArrow() and (self.player == g_localPlayer or self.vehicle ~= nil)
end
PlayerHotspot.render = MapHotspot.render
PlayerHotspot.setScale = MapHotspot.setScale
PlayerHotspot.getColor = MapHotspot.getColor