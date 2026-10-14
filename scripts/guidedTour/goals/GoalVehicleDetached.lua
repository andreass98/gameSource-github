GoalVehicleDetached = {}
GoalVehicleDetached.NAME = "vehicleDetached"
local GoalVehicleDetached_mt = Class(GoalVehicleDetached)
function GoalVehicleDetached.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end
function GoalVehicleDetached.new(vehicleName, customMt)
    -- upvalues: (copy) GoalVehicleDetached_mt
    local self = setmetatable({}, customMt or GoalVehicleDetached_mt)
    self.vehicleName = vehicleName
    return self
end
function GoalVehicleDetached:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleDetached.activate: Vehicle \'%s\' not found", self.vehicleName)
    end
end
function GoalVehicleDetached:deactivate()
    self.vehicle = nil
end
function GoalVehicleDetached:isAchieved()
    if self.vehicle == nil then
        return true
    end
    return self.vehicle:getAttacherVehicle() ~= nil
end
function GoalVehicleDetached.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName ~= nil then
        return GoalVehicleDetached.new(vehicleName)
    end
    Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleDetached.NAME, GoalVehicleDetached)