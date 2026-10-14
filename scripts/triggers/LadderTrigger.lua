LadderTrigger = {}
local LadderTrigger_mt = Class(LadderTrigger)
function LadderTrigger.onCreate(_, id)
    g_currentMission:addNonUpdateable(LadderTrigger.new(id))
end
function LadderTrigger.new(node)
    -- upvalues: (copy) LadderTrigger_mt
    local self = setmetatable({}, LadderTrigger_mt)
    if g_currentMission:getIsClient() then
        self.triggerId = node
        if not CollisionFlag.getHasMaskFlagSet(node, CollisionFlag.PLAYER) then
            Logging.warning("Missing collision mask bit \'%d\'. Please add this bit to ladder trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.PLAYER), I3DUtil.getNodePath(node))
        end
        addTrigger(node, "triggerCallback", self)
    end
    return self
end
function LadderTrigger:delete()
    if self.triggerId ~= nil then
        removeTrigger(self.triggerId)
    end
end
function LadderTrigger.triggerCallback(_, _, otherId, onEnter, onLeave, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        if onEnter then
            g_localPlayer.mover:setIsOnLadder(true)
            return
        end
        g_localPlayer.mover:setIsOnLadder(false)
    end
end