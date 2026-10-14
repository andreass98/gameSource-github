WindObject = {}
WindObject.LAST_ANGLE = math.random(-3.141592653589793, 3.141592653589793)
local WindObject_mt = Class(WindObject)
function WindObject.new(customMt)
    -- upvalues: (copy) WindObject_mt
    local self = setmetatable({}, customMt or WindObject_mt)
    self.windDirectionX = 1
    self.windDirectionZ = 1
    self.windVelocity = 1
    self.cirrusSpeedFactor = 1
    return self
end
function WindObject:load(xmlFile, key)
    local windAngle = xmlFile:getFloat(key .. "#angle")
    if windAngle == nil then
        windAngle = WindObject.LAST_ANGLE + math.random(-15, 15)
    end
    WindObject.LAST_ANGLE = windAngle
    local xDir, zDir = MathUtil.getDirectionFromYRotation((math.rad(windAngle)))
    self.windDirectionX = xDir
    self.windDirectionZ = zDir
    self.windAngle = windAngle
    self.windVelocity = MathUtil.kmhToMps(xmlFile:getFloat(key .. "#speed") or 30)
    self.cirrusSpeedFactor = xmlFile:getFloat(key .. "#cirrusSpeedFactor") or 1
end
function WindObject:delete() end
function WindObject:getValues()
    return self.windDirectionX, self.windDirectionZ, self.windVelocity, self.cirrusSpeedFactor
end