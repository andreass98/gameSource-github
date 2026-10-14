BoatyardActivatable = {}
local BoatyardActivatable_mt = Class(BoatyardActivatable)
function BoatyardActivatable.new(boatyard)
    -- upvalues: (copy) BoatyardActivatable_mt
    local self = setmetatable({}, BoatyardActivatable_mt)
    self.boatyard = boatyard
    self.activateText = string.format(g_i18n:getText("action_buyOBJECT"), self.boatyard:getName())
    return self
end
function BoatyardActivatable:getIsActivatable()
    return self.boatyard:getOwnerFarmId() == AccessHandler.EVERYONE
end
function BoatyardActivatable:run()
    if self.boatyard:getOwnerFarmId() == AccessHandler.EVERYONE then
        self.boatyard:buyRequest()
    end
end