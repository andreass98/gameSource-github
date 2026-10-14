AIDriveStrategy = {}
local AIDriveStrategy_mt = Class(AIDriveStrategy)
function AIDriveStrategy.new(_, customMt)
    -- upvalues: (copy) AIDriveStrategy_mt
    return setmetatable({}, customMt or AIDriveStrategy_mt)
end
function AIDriveStrategy:delete() end
function AIDriveStrategy:setAIVehicle(vehicle)
    self.vehicle = vehicle
end
function AIDriveStrategy:update(dt) end
function AIDriveStrategy:getDriveData(dt, vX, vY, vZ)
    return nil, nil, nil, nil, nil
end
function AIDriveStrategy:updateDriving(dt) end
function AIDriveStrategy.debugPrint(_, text, ...)
    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
        print(string.format("AI DEBUG: %s", string.format(text, ...)))
    end
end