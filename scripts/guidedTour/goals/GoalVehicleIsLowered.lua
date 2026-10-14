GoalVehicleIsLowered = {}
GoalVehicleIsLowered.NAME = "vehicleIsLowered"
local GoalVehicleIsLowered_mt = Class(GoalVehicleIsLowered)
function GoalVehicleIsLowered.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end
function GoalVehicleIsLowered.new(vehicleName, customMt)
    -- upvalues: (copy) GoalVehicleIsLowered_mt
    local self = setmetatable({}, customMt or GoalVehicleIsLowered_mt)
    self.vehicleName = vehicleName
    return self
end
function GoalVehicleIsLowered:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleIsLowered.activate: Vehicle \'%s\' not found", self.vehicleName)
        return
    elseif self.vehicle.getIsLowered == nil then
        self.vehicle = nil
        Logging.warning("GoalVehicleIsLowered.activate: Vehicle \'%s\' cannot be lowered", self.vehicleName)
    end
end
function GoalVehicleIsLowered:deactivate()
    self.vehicle = nil
end
function GoalVehicleIsLowered:isAchieved()
    return self.vehicle == nil and true or self.vehicle:getIsLowered()
end
function GoalVehicleIsLowered.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName ~= nil then
        return GoalVehicleIsLowered.new(vehicleName)
    end
    Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsLowered.NAME, GoalVehicleIsLowered)