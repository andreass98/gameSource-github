CollectibleActivatable = {}
local CollectibleActivatable_mt = Class(CollectibleActivatable)
function CollectibleActivatable.new(collectible)
    -- upvalues: (copy) CollectibleActivatable_mt
    local self = setmetatable({}, CollectibleActivatable_mt)
    self.collectible = collectible
    self.activateText = g_i18n:getText("action_collectibleCollect")
    return self
end
function CollectibleActivatable:run()
    if g_localPlayer.farmId ~= FarmManager.SPECTATOR_FARM_ID then
        g_currentMission.collectiblesSystem:onTriggerCollectible(self.collectible)
    end
end