ProductionPointActivatable = {}
local ProductionPointActivatable_mt = Class(ProductionPointActivatable)
function ProductionPointActivatable.new(productionPoint)
    -- upvalues: (copy) ProductionPointActivatable_mt
    local self = setmetatable({}, ProductionPointActivatable_mt)
    self.productionPoint = productionPoint
    self.mission = productionPoint.mission
    self:updateText()
    return self
end
function ProductionPointActivatable:updateText()
    if self.productionPoint.isOwned or not self.productionPoint.useInteractionTriggerForBuying then
        self.activateText = g_i18n:getText("action_manageProductionPoint")
    else
        self.activateText = g_i18n:getText("action_buyProductionPoint")
    end
end
function ProductionPointActivatable:getIsActivatable()
    return self.mission.accessHandler:canFarmAccess(self.mission:getFarmId(), self.productionPoint)
end
function ProductionPointActivatable:run()
    local ownerFarmId = self.productionPoint:getOwnerFarmId()
    if ownerFarmId == AccessHandler.EVERYONE and self.productionPoint.useInteractionTriggerForBuying then
        self.productionPoint:buyRequest()
    elseif ownerFarmId == self.mission:getFarmId() then
        self.productionPoint:openMenu()
    end
end
function ProductionPointActivatable:getDistance(x, y, z)
    if self.productionPoint.interactionTriggerNode == nil or (not self.productionPoint.isOwned or self.productionPoint.useInteractionTriggerForBuying) then
        return math.huge
    end
    local tx, ty, tz = getWorldTranslation(self.productionPoint.interactionTriggerNode)
    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end