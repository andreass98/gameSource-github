Rotator = {}
local Rotator_mt = Class(Rotator)
function Rotator.onCreate(_, id)
    g_currentMission:addUpdateable(Rotator.new(id))
end
function Rotator.new(node)
    -- upvalues: (copy) Rotator_mt
    local axis = Rotator_mt
    local self = setmetatable({}, axis)
    self.axisTable = { 0, 0, 0 }
    self.rotationNode = node
    local axis = getUserAttribute
    local rpm = tonumber(axis(node, "rpm"))
    if rpm == nil then
        self.speed = Utils.getNoNil(tonumber(getUserAttribute(node, "speed")), 0.0012)
    else
        self.speed = rpm * 2 * 3.141592653589793 / 60 / 1000
    end
    local axis = Utils.getNoNil(getUserAttribute(node, "axis"), 3)
    self.axisTable[axis] = 1
    return self
end
function Rotator:delete() end
function Rotator:update(dt)
    rotate(self.rotationNode, self.axisTable[1] * self.speed * dt, self.axisTable[2] * self.speed * dt, self.axisTable[3] * self.speed * dt)
end