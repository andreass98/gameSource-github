GoalVehicleIsAIActive = {}
GoalVehicleIsAIActive.NAME = "vehicleIsAIActive"
local GoalVehicleIsAIActive_mt = Class(GoalVehicleIsAIActive)
function GoalVehicleIsAIActive.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end
function GoalVehicleIsAIActive.new(vehicleName, customMt)
    -- upvalues: (copy) GoalVehicleIsAIActive_mt
    local self = setmetatable({}, customMt or GoalVehicleIsAIActive_mt)
    self.vehicleName = vehicleName
    return self
end
function GoalVehicleIsAIActive:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleIsAIActive.activate: Vehicle \'%s\' not found", self.vehicleName)
        return
    elseif self.vehicle.getIsAIActive == nil then
        self.vehicle = nil
        Logging.warning("GoalVehicleIsAIActive.activate: Vehicle \'%s\' does not support AI", self.vehicleName)
    end
end
function GoalVehicleIsAIActive:deactivate()
    self.vehicle = nil
end
function GoalVehicleIsAIActive:isAchieved()
    return self.vehicle == nil and true or self.vehicle:getIsAIActive()
end
function GoalVehicleIsAIActive.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName ~= nil then
        return GoalVehicleIsAIActive.new(vehicleName)
    end
    Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsAIActive.NAME, GoalVehicleIsAIActive)