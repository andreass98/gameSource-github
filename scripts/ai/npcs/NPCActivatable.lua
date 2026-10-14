NPCActivatable = {}
local NPCActivatable_mt = Class(NPCActivatable)
function NPCActivatable.new(npc, interactionAngleThreshold)
    -- upvalues: (copy) NPCActivatable_mt
    local self = setmetatable({}, NPCActivatable_mt)
    self.npc = npc
    self.interactionAngleThreshold = interactionAngleThreshold or 1.0471975511965976
    self.activateText = g_i18n:getText("action_startConversation")
    return self
end
function NPCActivatable:getIsActivatable(dirX, _, dirZ)
    if not self.npc:getCanInteract() then
        return false
    end
    if g_localPlayer == nil then
        return false
    end
    local npcDirX, _, npcDirZ = self.npc:getFacingDirection()
    local angle = MathUtil.getVectorAngleDifference(npcDirX, 0, npcDirZ, dirX, 0, dirZ)
    return math.abs(angle) <= self.interactionAngleThreshold
end
function NPCActivatable:getDistance(posX, _, posZ)
    if self.npc.node == 0 then
        return math.huge
    end
    local x, _, z = getWorldTranslation(self.npc.node)
    return MathUtil.vector2Length(posX - x, posZ - z)
end
function NPCActivatable:run()
    self.npc:requestConversation(g_localPlayer)
end