ShopTrigger = {}
local ShopTrigger_mt = Class(ShopTrigger)
function ShopTrigger.onCreate(_, id)
    g_currentMission:addNonUpdateable(ShopTrigger.new(id))
end
function ShopTrigger.new(node)
    -- upvalues: (copy) ShopTrigger_mt
    local self = setmetatable({}, ShopTrigger_mt)
    if g_currentMission:getIsClient() then
        self.triggerId = node
        if not CollisionFlag.getHasMaskFlagSet(node, CollisionFlag.PLAYER) then
            Logging.warning("Missing collision mask bit \'%d\'. Please add this bit to shop trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.PLAYER), I3DUtil.getNodePath(node))
        end
        addTrigger(node, "triggerCallback", self)
    end
    self.shopSymbol = getChildAt(node, 0)
    self.shopPlayerSpawn = getChildAt(node, 1)
    self.isEnabled = true
    g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.playerFarmChanged, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_TRIGGER_MARKER], self.onTriggerVisibilityChanged, self)
    self:updateIconVisibility()
    self.activatable = ShopTriggerActivatable.new(self)
    return self
end
function ShopTrigger:delete()
    g_messageCenter:unsubscribeAll(self)
    if self.triggerId ~= nil then
        removeTrigger(self.triggerId)
    end
    self.shopSymbol = nil
    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end
function ShopTrigger:openShop()
    if g_guidedTourManager:getIsTourRunning() then
        InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
    else
        g_gui:changeScreen(nil, ShopMenu)
        local x, y, z = getWorldTranslation(self.shopPlayerSpawn)
        local dx, _, dz = localDirectionToWorld(self.shopPlayerSpawn, 0, 0, -1)
        g_localPlayer:teleportTo(x, y, z)
        g_localPlayer:setMovementYaw(MathUtil.getYRotationFromDirection(dx, dz))
    end
end
function ShopTrigger:triggerCallback(_, otherId, onEnter, onLeave, _)
    if self.isEnabled and (g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave)) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        if onEnter then
            if Platform.gameplay.autoActivateTrigger and self.activatable:getIsActivatable() then
                self.activatable:run()
            else
                g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
            end
        end
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    end
end
function ShopTrigger:updateIconVisibility()
    if self.shopSymbol ~= nil then
        local isAvailable = self.isEnabled
        if isAvailable then
            isAvailable = g_currentMission.missionInfo:isa(FSCareerMissionInfo)
        end
        local visibleForFarm = g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
        local settingVisible = g_gameSettings:getValue(GameSettings.SETTING.SHOW_TRIGGER_MARKER)
        if isAvailable then
            if not visibleForFarm then
                settingVisible = visibleForFarm
            end
        else
            settingVisible = isAvailable
        end
        setVisibility(self.shopSymbol, settingVisible)
    end
end
function ShopTrigger:playerFarmChanged(player)
    if player == g_localPlayer then
        self:updateIconVisibility()
    end
end
function ShopTrigger:onTriggerVisibilityChanged()
    self:updateIconVisibility()
end
ShopTriggerActivatable = {}
local ShopTriggerActivatable_mt = Class(ShopTriggerActivatable)
function ShopTriggerActivatable.new(shopTrigger)
    -- upvalues: (copy) ShopTriggerActivatable_mt
    local self = setmetatable({}, ShopTriggerActivatable_mt)
    self.shopTrigger = shopTrigger
    self.activateText = g_i18n:getText("action_activateShop")
    return self
end
function ShopTriggerActivatable:getIsActivatable()
    return self.shopTrigger.isEnabled and not g_localPlayer:getIsInVehicle() and g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
end
function ShopTriggerActivatable:run()
    self.shopTrigger:openShop()
end