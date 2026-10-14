ConstructionBrush = {}
local ConstructionBrush_mt = Class(ConstructionBrush)
ConstructionBrush.ERROR = {
    ["LAND_UNOWNED"] = 1,
    ["RESTRICTED_ZONE"] = 2,
    ["PLACEMENT_BLOCKED"] = 3,
    ["STORE_PLACE"] = 4,
    ["SPAWN_PLACE"] = 5,
    ["NO_PERMISSION"] = 6
}
ConstructionBrush.ERROR_MESSAGES = {
    [ConstructionBrush.ERROR.LAND_UNOWNED] = "ui_construction_landIsNotOwned",
    [ConstructionBrush.ERROR.PLACEMENT_BLOCKED] = "ui_construction_areaRestricted",
    [ConstructionBrush.ERROR.RESTRICTED_ZONE] = "ui_construction_areaRestricted",
    [ConstructionBrush.ERROR.STORE_PLACE] = "ui_construction_storeAreaRestricted",
    [ConstructionBrush.ERROR.SPAWN_PLACE] = "ui_construction_spawnAreaRestricted",
    [ConstructionBrush.ERROR.NO_PERMISSION] = "ui_construction_noBuildPermission"
}
ConstructionBrush.CURSOR_SIZES = {
    1,
    2,
    4,
    8,
    16
}
ConstructionBrush.DEBUG_TEXT_ATTR = Vector3.new(0.28, 0.98, 0.015)
function ConstructionBrush.new(customMt, cursor)
    -- upvalues: (copy) ConstructionBrush_mt
    local self = setmetatable({}, customMt or ConstructionBrush_mt)
    self.isActive = false
    self.cursor = cursor
    self.supportsPrimaryButton = false
    self.supportsPrimaryDragging = false
    self.supportsSecondaryButton = false
    self.supportsSecondaryDragging = false
    self.supportsTertiaryButton = false
    self.supportsPrimaryAxis = false
    self.supportsSecondaryAxis = false
    self.primaryAxisIsContinuous = false
    self.secondaryAxisIsContinuous = false
    self.inputTextDirty = true
    self.activeSoundId = ConstructionSound.ID.NONE
    self.activeSoundPitchModifier = nil
    return self
end
function ConstructionBrush:delete()
    if self.isActive then
        self:deactivate()
    end
end
function ConstructionBrush:activate()
    self.isActive = true
    self.currentUserId = g_currentMission.playerUserId
    self.playerFarm = g_farmManager:getFarmById(g_currentMission:getFarmId())
    self.cursor:setCursorTerrainOffset(false)
end
function ConstructionBrush:deactivate()
    self.isActive = false
    self.currentUserId = nil
    self.playerFarm = nil
end
function ConstructionBrush:copyState(from) end
function ConstructionBrush:setParameters(...) end
function ConstructionBrush:setStoreItem(storeItem, configurations, configurationData)
    self.storeItem = storeItem
    self.configurations = configurations
    self.configurationData = configurationData
end
function ConstructionBrush:canCancel()
    return false
end
function ConstructionBrush:verifyAccess(x, y, z)
    if self:hasPlayerPermission() then
        if g_currentMission.accessHandler:canFarmAccessLand(g_localPlayer.farmId, x, z, true) then
            if PlacementUtil.isInsidePlacementPlaces(g_currentMission.storeSpawnPlaces, x, y, z) then
                return ConstructionBrush.ERROR.STORE_PLACE
            elseif PlacementUtil.isInsidePlacementPlaces(g_currentMission.loadSpawnPlaces, x, y, z) then
                return ConstructionBrush.ERROR.SPAWN_PLACE
            elseif PlacementUtil.isInsideRestrictedZone(g_currentMission.restrictedZones, x, y, z) then
                return ConstructionBrush.ERROR.RESTRICTED_ZONE
            else
                return nil
            end
        else
            return ConstructionBrush.ERROR.LAND_UNOWNED
        end
    else
        return ConstructionBrush.ERROR.NO_PERMISSION
    end
end
function ConstructionBrush:hasPlayerPermission()
    return self.requiredPermission == nil and true or (self.playerFarm:getUserPermissions(self.currentUserId)[self.requiredPermission] or g_currentMission.isMasterUser)
end
function ConstructionBrush:update(dt) end
function ConstructionBrush:draw()
    if g_isDevelopmentVersion and (self.storeItem ~= nil and self.storeItem.xmlFilename ~= nil) then
        local storeItemNameCleaned = string.gsub(self.storeItem.xmlFilename, getUserProfileAppPath(), "")
        renderText(ConstructionBrush.DEBUG_TEXT_ATTR.x, ConstructionBrush.DEBUG_TEXT_ATTR.y, ConstructionBrush.DEBUG_TEXT_ATTR.z, storeItemNameCleaned)
    end
end
function ConstructionBrush:cancel() end
function ConstructionBrush:onButtonPrimary() end
function ConstructionBrush:onButtonSecondary() end
function ConstructionBrush:onButtonTertiary() end
function ConstructionBrush:onButtonFourth() end
function ConstructionBrush:onButtonSnapping() end
function ConstructionBrush:onAxisPrimary(inputValue) end
function ConstructionBrush:onAxisSecondary(inputValue) end
function ConstructionBrush:setInputTextDirty()
    self.inputTextDirty = true
end
function ConstructionBrush:getButtonPrimaryText()
    return "PRIMARY"
end
function ConstructionBrush:getButtonSecondaryText()
    return "SECONDARY"
end
function ConstructionBrush:getButtonTertiaryText()
    return "TERTIARY"
end
function ConstructionBrush:getAxisPrimaryText()
    return "PRIMARY AXIS"
end
function ConstructionBrush:getAxisSecondaryText()
    return "SECONDARY AXIS"
end
function ConstructionBrush:getButtonSnappingText()
    return "SNAPPING"
end
function ConstructionBrush:setActiveSound(soundId, pitchModifier)
    self.activeSoundId = soundId
    self.activeSoundPitchModifier = pitchModifier
end
function ConstructionBrush:playSound(soundId, pitchModifier)
    self.activeSoundId = soundId
    self.activeSoundPitchModifier = pitchModifier
end