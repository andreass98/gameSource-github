GoalVehicleInFillTrigger = {}
GoalVehicleInFillTrigger.NAME = "vehicleInFillRange"
local GoalVehicleInFillTrigger_mt = Class(GoalVehicleInFillTrigger)
function GoalVehicleInFillTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end
function GoalVehicleInFillTrigger.new(vehicleName, customMt)
    -- upvalues: (copy) GoalVehicleInFillTrigger_mt
    local self = setmetatable({}, customMt or GoalVehicleInFillTrigger_mt)
    self.vehicleName = vehicleName
    return self
end
function GoalVehicleInFillTrigger:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleInFillTrigger.activate: Vehicle \'%s\' not found", self.vehicleName)
        return
    elseif self.vehicle.spec_fillUnit == nil or self.vehicle.spec_fillUnit.fillTrigger == nil then
        Logging.warning("GoalVehicleInFillTrigger.activate: Vehicle \'%s\' has no fill trigger", self.vehicleName)
    end
end
function GoalVehicleInFillTrigger:deactivate()
    self.vehicle = nil
end
function GoalVehicleInFillTrigger:isAchieved()
    return self.vehicle == nil and true or (self.vehicle.spec_fillUnit.fillTrigger.activatable:getIsActivatable() and true or false)
end
function GoalVehicleInFillTrigger.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName ~= nil then
        return GoalVehicleInFillTrigger.new(vehicleName)
    end
    Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleInFillTrigger.NAME, GoalVehicleInFillTrigger)