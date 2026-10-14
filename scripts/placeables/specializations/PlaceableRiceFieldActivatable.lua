PlaceableRiceFieldActivatable = {}
local PlaceableRiceFieldActivatable_mt = Class(PlaceableRiceFieldActivatable)
function PlaceableRiceFieldActivatable.new(riceFieldPlaceable)
    -- upvalues: (copy) PlaceableRiceFieldActivatable_mt
    local self = setmetatable({}, PlaceableRiceFieldActivatable_mt)
    self.riceFieldPlaceable = riceFieldPlaceable
    self.fieldIndex = nil
    self.activateText = g_i18n:getText("action_interact")
    return self
end
function PlaceableRiceFieldActivatable:getIsActivatable()
    if self.fieldIndex == nil then
        return false
    end
    local field = self.riceFieldPlaceable:getFieldByIndex(self.fieldIndex)
    if field == nil then
        return false
    end
    local x, _, z = getWorldTranslation(field.playerTriggerNode)
    return g_currentMission.accessHandler:canFarmAccessLand(g_localPlayer.farmId, x, z)
end
function PlaceableRiceFieldActivatable:setRiceFieldIndex(fieldIndex)
    self.fieldIndex = fieldIndex
end
function PlaceableRiceFieldActivatable:getDistance(posX, _, posZ)
    if self.fieldIndex ~= nil then
        local field = self.riceFieldPlaceable:getFieldByIndex(self.fieldIndex)
        if field.playerTriggerNode ~= nil then
            local x, _, z = getWorldTranslation(field.playerTriggerNode)
            return MathUtil.vector2Length(posX - x, posZ - z)
        end
    end
    return math.huge
end
function PlaceableRiceFieldActivatable:run()
    RiceFieldDialog.show(function(_, args)
        -- upvalues: (copy) self
        if args.isAccepted then
            self.riceFieldPlaceable:setWaterHeightTarget(self.fieldIndex, self.riceFieldPlaceable.spec_riceField.waterMaxLevel * args.fillLevelPercentage)
        end
    end, self.riceFieldPlaceable, g_i18n:getText("ui_riceManageField"), self.fieldIndex)
end