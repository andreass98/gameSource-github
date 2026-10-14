FactoryActivatable = {}
local FactoryActivatable_mt = Class(FactoryActivatable)
function FactoryActivatable.new(factory)
    -- upvalues: (copy) FactoryActivatable_mt
    local self = setmetatable({}, FactoryActivatable_mt)
    self.factory = factory
    self.activateText = string.format(g_i18n:getText("action_buyOBJECT"), self.factory:getName())
    return self
end
function FactoryActivatable:getIsActivatable()
    return self.factory:getOwnerFarmId() == AccessHandler.EVERYONE
end
function FactoryActivatable:run()
    if self.factory:getOwnerFarmId() == AccessHandler.EVERYONE then
        self.factory:buyRequest()
    end
end