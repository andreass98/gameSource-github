FootballFieldResetActivatable = {}
local FootballFieldResetActivatable_mt = Class(FootballFieldResetActivatable)
function FootballFieldResetActivatable.new(footballField)
    -- upvalues: (copy) FootballFieldResetActivatable_mt
    local self = setmetatable({}, FootballFieldResetActivatable_mt)
    self.footballField = footballField
    self.activateText = g_i18n:getText("action_resetFootballField")
    return self
end
function FootballFieldResetActivatable:getIsActivatable()
    return true
end
function FootballFieldResetActivatable:run()
    self.footballField:reset()
end
function FootballFieldResetActivatable:getDistance(x, y, z)
    if self.footballField.resetTriggerNode == nil then
        return math.huge
    end
    local tx, ty, tz = getWorldTranslation(self.footballField.resetTriggerNode)
    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end