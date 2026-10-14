Collectible = {}
local Collectible_mt = Class(Collectible)
function Collectible.onCreate(_, node)
    g_currentMission:addNonUpdateable(Collectible.new(node))
end
function Collectible.new(node)
    -- upvalues: (copy) Collectible_mt
    local self = setmetatable({}, Collectible_mt)
    self.node = node
    self.name = getUserAttribute(node, "name")
    if self.name == nil then
        Logging.error("Collectible has no \'name\' defined")
        return nil
    end
    local triggerIndex = getUserAttribute(node, "triggerIndex")
    if triggerIndex == nil then
        self.triggerNode = node
    else
        self.triggerNode = getChildAt(node, triggerIndex)
        if self.triggerNode == 0 then
            Logging.error("Collectible has wrong \'triggerIndex\' defined, node does not exist.")
            return nil
        end
    end
    if not CollisionFlag.getHasMaskFlagSet(self.triggerNode, CollisionFlag.PLAYER) then
        Logging.warning("Missing collision mask bit \'%d\'. Please add this bit to collectible trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.PLAYER), I3DUtil.getNodePath(self.triggerNode))
    end
    self.activatable = CollectibleActivatable.new(self)
    self.isActive = false
    self.mapHotspotVisible = false
    g_currentMission.collectiblesSystem:addCollectible(self)
    return self
end
function Collectible:delete()
    self:deactivate()
    g_currentMission.collectiblesSystem:removeCollectible(self)
end
function Collectible:triggerCallback(_, otherId, onEnter, onLeave, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and (otherId == g_localPlayer.rootNode and g_localPlayer.farmId ~= FarmManager.SPECTATOR_FARM_ID)) then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
            return
        end
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    end
end
function Collectible:activate()
    if not self.isActive then
        setVisibility(self.node, true)
        addTrigger(self.triggerNode, "triggerCallback", self)
        self.mapHotspot = CollectibleHotspot.new(self)
        self.mapHotspot:setVisible(self.mapHotspotVisible)
        g_currentMission:addMapHotspot(self.mapHotspot)
        self.isActive = true
    end
end
function Collectible:deactivate()
    if self.isActive then
        setVisibility(self.node, false)
        removeTrigger(self.triggerNode)
        delete(self.node)
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
        g_currentMission:removeMapHotspot(self.mapHotspot)
        self.mapHotspot:delete()
        self.mapHotspot = nil
        self.isActive = false
    end
end
function Collectible:setHotspotVisible(visible)
    self.mapHotspotVisible = visible
    if self.mapHotspot ~= nil then
        self.mapHotspot:setVisible(visible)
    end
end