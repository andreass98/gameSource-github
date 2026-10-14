GoalVehicleIsTurnedOn = {}
GoalVehicleIsTurnedOn.NAME = "vehicleIsTurnedOn"
local GoalVehicleIsTurnedOn_mt = Class(GoalVehicleIsTurnedOn)
function GoalVehicleIsTurnedOn.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end
function GoalVehicleIsTurnedOn.new(vehicleName, customMt)
    -- upvalues: (copy) GoalVehicleIsTurnedOn_mt
    local self = setmetatable({}, customMt or GoalVehicleIsTurnedOn_mt)
    self.vehicleName = vehicleName
    return self
end
function GoalVehicleIsTurnedOn:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleIsTurnedOn.activate: Vehicle \'%s\' not found", self.vehicleName)
        return
    elseif self.vehicle.getIsTurnedOn == nil then
        self.vehicle = nil
        Logging.warning("GoalVehicleIsTurnedOn.activate: Vehicle \'%s\' cannot be turned on", self.vehicleName)
    end
end
function GoalVehicleIsTurnedOn:deactivate()
    self.vehicle = nil
end
function GoalVehicleIsTurnedOn:isAchieved()
    return self.vehicle == nil and true or self.vehicle:getIsTurnedOn()
end
function GoalVehicleIsTurnedOn.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName ~= nil then
        return GoalVehicleIsTurnedOn.new(vehicleName)
    end
    Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsTurnedOn.NAME, GoalVehicleIsTurnedOn)