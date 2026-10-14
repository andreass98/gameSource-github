SunAdmirer = {}
local SunAdmirer_mt = Class(SunAdmirer)
function SunAdmirer.onCreate(_, id)
    g_currentMission:addNonUpdateable(SunAdmirer.new(id))
end
function SunAdmirer.new(id)
    -- upvalues: (copy) SunAdmirer_mt
    local self = setmetatable({}, SunAdmirer_mt)
    self.id = id
    self.switchCollision = Utils.getNoNil(getUserAttribute(id, "switchCollision"), false)
    if self.switchCollision then
        self.collisionMask = getCollisionFilterMask(id)
    end
    self:setVisibility(true)
    g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, self.onWeatherChanged, self)
    return self
end
function SunAdmirer:delete()
    g_messageCenter:unsubscribeAll(self)
end
function SunAdmirer:setVisibility(visible)
    setVisibility(self.id, visible)
    if self.switchCollision then
        setCollisionFilterMask(self.id, visible and self.collisionMask or 0)
    end
end
function SunAdmirer:onWeatherChanged()
    if g_currentMission ~= nil and g_currentMission.environment ~= nil then
        self:setVisibility(g_currentMission.environment.isSunOn and not g_currentMission.environment.weather:getIsRaining())
    end
end