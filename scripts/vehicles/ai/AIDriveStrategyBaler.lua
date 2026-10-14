AIDriveStrategyBaler = {}
local AIDriveStrategyBaler_mt = Class(AIDriveStrategyBaler, AIDriveStrategy)
function AIDriveStrategyBaler.new(reconstructionData, customMt)
    -- upvalues: (copy) AIDriveStrategyBaler_mt
    local self = AIDriveStrategy.new(reconstructionData, customMt or AIDriveStrategyBaler_mt)
    self.balers = {}
    self.slowDownFillLevel = 200
    self.slowDownStartSpeed = 20
    return self
end
function AIDriveStrategyBaler:setAIVehicle(vehicle)
    AIDriveStrategyBaler:superClass().setAIVehicle(self, vehicle)
    if SpecializationUtil.hasSpecialization(Baler, self.vehicle.specializations) then
        table.insert(self.balers, self.vehicle)
    end
    for _, implement in pairs(self.vehicle:getAttachedAIImplements()) do
        if SpecializationUtil.hasSpecialization(Baler, implement.object.specializations) then
            table.insert(self.balers, implement.object)
        end
    end
end
function AIDriveStrategyBaler:update(dt) end
function AIDriveStrategyBaler:getDriveData(_, _, _, _)
    local allowedToDrive = true
    local maxSpeed = math.huge
    for _, baler in pairs(self.balers) do
        local spec = baler.spec_baler
        if spec.nonStopBaling then
            if spec.platformDropInProgress then
                maxSpeed = spec.platformAIDropSpeed
                if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                    self.vehicle:addAIDebugText(string.format("BALER -> Platform dropping active, reducing speed to %.1f km/h", spec.platformAIDropSpeed))
                end
            end
        else
            local fillLevel = baler:getFillUnitFillLevel(spec.fillUnitIndex)
            local capacity = baler:getFillUnitCapacity(spec.fillUnitIndex)
            local freeFillLevel = capacity - fillLevel
            if freeFillLevel < self.slowDownFillLevel then
                if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                    self.vehicle:addAIDebugText(string.format("BALER -> Slow down because nearly full: %.2f", 2 + freeFillLevel / self.slowDownFillLevel * self.slowDownStartSpeed))
                end
            end
            if fillLevel == capacity or spec.unloadingState ~= Baler.UNLOADING_CLOSED then
                allowedToDrive = false
            end
        end
    end
    if allowedToDrive then
        return nil, nil, nil, maxSpeed, nil
    else
        return 0, 1, true, 0, math.huge
    end
end
function AIDriveStrategyBaler:updateDriving(dt) end