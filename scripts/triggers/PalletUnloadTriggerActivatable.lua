PalletUnloadTriggerActivatable = {}
local PalletUnloadTriggerActivatable_mt = Class(PalletUnloadTriggerActivatable)
function PalletUnloadTriggerActivatable.new(palletUnloadTrigger)
    -- upvalues: (copy) PalletUnloadTriggerActivatable_mt
    local self = setmetatable({}, PalletUnloadTriggerActivatable_mt)
    self.owner = palletUnloadTrigger
    self.activateText = g_i18n:getText("button_unload")
    return self
end
function PalletUnloadTriggerActivatable:getIsActivatable()
    local owner = self.owner
    if not owner.isEnabled then
        return false
    end
    if g_gui.currentGui ~= nil then
        return false
    end
    if not g_currentMission.accessHandler:canPlayerAccess(self.owner) then
        return false
    end
    if #owner.palletsInRange == 0 then
        return false
    end
    if owner.isPlayerInRange then
        return true
    end
    for vehicle, _ in pairs(owner.vehiclesInRange) do
        if vehicle.rootVehicle == g_localPlayer:getCurrentVehicle() then
            return true
        end
    end
    return false
end
function PalletUnloadTriggerActivatable:run()
    self.owner:unloadPallets(g_currentMission:getFarmId())
end
function PalletUnloadTriggerActivatable:getDistance(x, y, z)
    if self.owner.triggerNode == nil then
        return math.huge
    end
    local tx, ty, tz = getWorldTranslation(self.owner.triggerNode)
    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end