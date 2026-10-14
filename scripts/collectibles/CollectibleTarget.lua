CollectibleTarget = {}
local CollectibleTarget_mt = Class(CollectibleTarget)
function CollectibleTarget.onCreate(_, node)
    g_currentMission:addNonUpdateable(CollectibleTarget.new(node))
end
function CollectibleTarget.new(node)
    -- upvalues: (copy) CollectibleTarget_mt
    local self = setmetatable({}, CollectibleTarget_mt)
    self.node = node
    g_currentMission.collectiblesSystem:addCollectibleTarget(self)
    return self
end
function CollectibleTarget:delete()
    g_currentMission.collectiblesSystem:removeCollectibleTarget(self)
end