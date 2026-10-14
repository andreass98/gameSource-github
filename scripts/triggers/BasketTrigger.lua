BasketTrigger = {}
BasketTrigger.threePointDistanceThreshold = 6
local BasketTrigger_mt = Class(BasketTrigger)
function BasketTrigger.onCreate(_, id)
    local trigger = BasketTrigger.new()
    if trigger:load(id) then
        g_currentMission:addNonUpdateable(trigger)
    else
        trigger:delete()
    end
end
function BasketTrigger.new(customMt)
    -- upvalues: (copy) BasketTrigger_mt
    local self = setmetatable({}, customMt or BasketTrigger_mt)
    self.triggerId = 0
    self.nodeId = 0
    return self
end
function BasketTrigger:load(nodeId)
    self.nodeId = nodeId
    self.triggerId = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "triggerIndex"))
    if self.triggerId == nil then
        self.triggerId = nodeId
    end
    addTrigger(self.triggerId, "triggerCallback", self)
    self.triggerObjects = {}
    self.isEnabled = true
    return true
end
function BasketTrigger:delete()
    removeTrigger(self.triggerId)
end
function BasketTrigger:triggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    if self.isEnabled then
        if onEnter then
            if g_currentMission:getNodeObject(otherActorId).thrownFromPosition ~= nil then
                self.triggerObjects[otherActorId] = true
                return
            end
        elseif onLeave and self.triggerObjects[otherActorId] then
            self.triggerObjects[otherActorId] = false
        end
    end
end