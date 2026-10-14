FerryActivatable = {}
local FerryActivatable_mt = Class(FerryActivatable)
function FerryActivatable.new(ferry)
    -- upvalues: (copy) FerryActivatable_mt
    local self = setmetatable({}, FerryActivatable_mt)
    self.ferry = ferry
    self.trigger = nil
    self.activateText = g_i18n:getText("action_startFerry")
    return self
end
function FerryActivatable:setTrigger(trigger)
    self.trigger = trigger
end
function FerryActivatable:getIsActivatable()
    return self.ferry:getCanActivateDriving() and true or false
end
function FerryActivatable:getDistance(posX, _, posZ)
    local x, _, z = getWorldTranslation(self.trigger)
    return MathUtil.vector2Length(posX - x, posZ - z)
end
function FerryActivatable:run()
    self.ferry:start()
end