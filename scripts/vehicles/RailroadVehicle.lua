RailroadVehicle = {}
local RailroadVehicle_mt = Class(RailroadVehicle, Vehicle)
InitStaticObjectClass(RailroadVehicle, "RailroadVehicle")
function RailroadVehicle.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setTrainSystem", RailroadVehicle.setTrainSystem)
    RailroadVehicle:superClass().registerFunctions(vehicleType)
end
function RailroadVehicle.new(isServer, isClient, customMt)
    -- upvalues: (copy) RailroadVehicle_mt
    local self = Vehicle.new(isServer, isClient, customMt or RailroadVehicle_mt)
    self.trainSystem = nil
    return self
end
function RailroadVehicle:setTrainSystem(trainSystem)
    self.trainSystem = trainSystem
    self.synchronizePosition = false
end
function RailroadVehicle:update(...)
    if self.isServer and self.trainSystem == nil then
        self:delete()
    else
        RailroadVehicle:superClass().update(self, ...)
    end
end