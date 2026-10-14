GoalVehicleInTipTrigger = {}
GoalVehicleInTipTrigger.NAME = "vehicleInTipTrigger"
local GoalVehicleInTipTrigger_mt = Class(GoalVehicleInTipTrigger)
function GoalVehicleInTipTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end
function GoalVehicleInTipTrigger.new(vehicleName, customMt)
    -- upvalues: (copy) GoalVehicleInTipTrigger_mt
    local self = setmetatable({}, customMt or GoalVehicleInTipTrigger_mt)
    self.vehicleName = vehicleName
    return self
end
function GoalVehicleInTipTrigger:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleInTipTrigger.activate: Vehicle \'%s\' not found", self.vehicleName)
        return
    elseif self.vehicle.getIsPossibleToDischargeToObject == nil then
        Logging.warning("GoalVehicleInTipTrigger.activate: Vehicle \'%s\' does not have discharge feature", self.vehicleName)
    end
end
function GoalVehicleInTipTrigger:deactivate()
    self.vehicle = nil
end
function GoalVehicleInTipTrigger:isAchieved()
    return self.vehicle == nil and true or (self.vehicle:getIsPossibleToDischargeToObject() and true or false)
end
function GoalVehicleInTipTrigger.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName ~= nil then
        return GoalVehicleInTipTrigger.new(vehicleName)
    end
    Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleInTipTrigger.NAME, GoalVehicleInTipTrigger)