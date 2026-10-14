GoalVehicleIsUnfolded = {}
GoalVehicleIsUnfolded.NAME = "vehicleIsUnfolded"
local GoalVehicleIsUnfolded_mt = Class(GoalVehicleIsUnfolded)
function GoalVehicleIsUnfolded.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end
function GoalVehicleIsUnfolded.new(vehicleName, customMt)
    -- upvalues: (copy) GoalVehicleIsUnfolded_mt
    local self = setmetatable({}, customMt or GoalVehicleIsUnfolded_mt)
    self.vehicleName = vehicleName
    return self
end
function GoalVehicleIsUnfolded:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleIsUnfolded.activate: Vehicle \'%s\' not found", self.vehicleName)
        return
    elseif self.vehicle.getIsUnfolded == nil then
        self.vehicle = nil
        Logging.warning("GoalVehicleIsUnfolded.activate: Vehicle \'%s\' cannot be unfolded", self.vehicleName)
    end
end
function GoalVehicleIsUnfolded:deactivate()
    self.vehicle = nil
end
function GoalVehicleIsUnfolded:isAchieved()
    return self.vehicle == nil and true or self.vehicle:getIsUnfolded()
end
function GoalVehicleIsUnfolded.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName ~= nil then
        return GoalVehicleIsUnfolded.new(vehicleName)
    end
    Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsUnfolded.NAME, GoalVehicleIsUnfolded)