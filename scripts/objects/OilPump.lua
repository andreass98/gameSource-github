OilPump = {}
local OilPump_mt = Class(OilPump)
function OilPump.onCreate(_, id)
    g_currentMission:addUpdateable(OilPump.new(id))
end
function OilPump.new(name)
    -- upvalues: (copy) OilPump_mt
    local self = setmetatable({}, OilPump_mt)
    self.axisTable = { 0, 0, 0 }
    self.me = name
    self.head = getChildAt(self.me, 1)
    self.cylinders = getChildAt(self.me, 2)
    self.innerCylinders = getChildAt(self.cylinders, 0)
    self.speed = 0.0012
    self.zRotationMin = 0
    self.zRotationMax = MathUtil.degToRad(40)
    self.timer = math.random() * 2 * 3.141592653589793
    return self
end
function OilPump:delete() end
function OilPump:update(dt)
    self.timer = self.timer + dt * 0.001
    if self.timer >= 6.283185307179586 then
        self.timer = 0
    end
    local sinValue = (math.sin(self.timer) + 1) / 2
    local zRotation = self.zRotationMax * sinValue
    local fakeValue = 2.105 - 1.977 / math.cos(zRotation - self.zRotationMax / 2)
    local xRotation = MathUtil.degToRad(-fakeValue * 15)
    setRotation(self.head, 0, 0, zRotation)
    setRotation(self.cylinders, 0, 0, xRotation)
    setScale(self.innerCylinders, 1, 1 + 0.5 * sinValue, 1)
end