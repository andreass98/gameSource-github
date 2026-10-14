RollercoasterActivatable = {}
local RollercoasterActivatable_mt = Class(RollercoasterActivatable)
function RollercoasterActivatable.new(rollercoaster)
    -- upvalues: (copy) RollercoasterActivatable_mt
    local self = setmetatable({}, RollercoasterActivatable_mt)
    self.rollercoaster = rollercoaster
    self.activateText = g_i18n:getText("action_rideRollercoaster")
    return self
end
function RollercoasterActivatable:getIsActivatable()
    return self.rollercoaster:getCanEnter()
end
function RollercoasterActivatable:run()
    if self.rollercoaster:getCanEnter() and self.rollercoaster:getFreeSeatIndex() ~= nil then
        g_client:getServerConnection():sendEvent(RollercoasterPassengerEnterRequestEvent.new(self.rollercoaster, g_localPlayer))
    end
end