AIExtension = {}
AIExtension.MOD_NAME = g_currentModName
local AIExtension_mt = Class(AIExtension)
function AIExtension.new(customMt)
    -- upvalues: (copy) AIExtension_mt
    local self = setmetatable({}, customMt or AIExtension_mt)
    self.rtkStations = {}
    self.preciseModeActive = false
    return self
end
function AIExtension:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
    return true
end
function AIExtension:delete()
    self:setPreciseModeActive(false)
end
function AIExtension.overwriteGameFunctions(_, pfModule)
    pfModule:overwriteGameFunction(AIJob, "updateCost", function(superFunc, _self, dt)
        if _self:isa(AIJobFieldWork) then
            local vehicle = _self.vehicleParameter:getVehicle()
            if vehicle ~= nil and vehicle.updatePFStatistic ~= nil then
                local price = _self:getPricePerMs()
                if price > 0 then
                    vehicle:updatePFStatistic("helperCosts", price * dt * EconomyManager.getCostMultiplier())
                end
            end
        end
        return superFunc(_self, dt)
    end)
end
function AIExtension:setPreciseModeActive(state)
    self.preciseModeActive = state
end
function AIExtension:registerRTKStation(station)
    self.rtkStations[station] = station
    self:setPreciseModeActive(true)
end
function AIExtension:unregisterRTKStation(station)
    self.rtkStations[station] = nil
    self:setPreciseModeActive(next(self.rtkStations) ~= nil)
end