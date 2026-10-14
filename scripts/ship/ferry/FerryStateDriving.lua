FerryStateDriving = {}
local FerryStateDriving_mt = Class(FerryStateDriving, FerryState)
function FerryStateDriving.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#drivingDirection", "Driving direction of the vessel", 1, false)
end
function FerryStateDriving.new(ferry, customMt)
    -- upvalues: (copy) FerryStateDriving_mt
    local self = FerryState.new(ferry, customMt or FerryStateDriving_mt)
    self.drivingDirection = 1
    return self
end
function FerryStateDriving:load(xmlFile, key)
    if not FerryStateDriving:superClass().load(self, xmlFile, key) then
        return false
    end
    self.drivingDirection = xmlFile:getValue(key .. "#drivingDirection", 1)
    return true
end
function FerryStateDriving:isDone()
    if FerryStateDriving:superClass().isDone(self) then
        local direction = self.drivingDirection
        local time = self.ferry:getSplineTime()
        if direction == 1 and time == 1 then
            return true
        elseif direction == -1 and time == 0 then
            return true
        elseif direction == 0 then
            return false
        else
            return false
        end
    else
        return false
    end
end
function FerryStateDriving:update(dt)
    FerryStateDriving:superClass().update(self, dt)
    if self.ferry.isServer then
        local ferry = self.ferry
        local splineTimePerMs = ferry:getSplineTimeDeltaPerMs()
        ferry:addSplineTimeDelta(self.drivingDirection * splineTimePerMs * dt)
    end
end
function FerryStateDriving:activate()
    FerryStateDriving:superClass().activate(self)
    self.ferry:startMotor()
end
function FerryStateDriving:deactivate()
    FerryStateDriving:superClass().deactivate(self)
    self.ferry:stopMotor()
end