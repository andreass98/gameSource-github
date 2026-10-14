GoalVehicleIsControlled = {}
GoalVehicleIsControlled.NAME = "vehicleIsControlled"
local GoalVehicleIsControlled_mt = Class(GoalVehicleIsControlled)
function GoalVehicleIsControlled.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
    schema:register(XMLValueType.BOOL, basePath .. "#isControlled", "If vehicle should be controlled", true, false)
end
function GoalVehicleIsControlled.new(vehicleName, isControlled, customMt)
    -- upvalues: (copy) GoalVehicleIsControlled_mt
    local self = setmetatable({}, customMt or GoalVehicleIsControlled_mt)
    self.vehicleName = vehicleName
    self.isControlled = isControlled
    return self
end
function GoalVehicleIsControlled:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleIsControlled.activate: Vehicle \'%s\' not found", self.vehicleName)
    end
end
function GoalVehicleIsControlled:deactivate()
    self.vehicle = nil
end
function GoalVehicleIsControlled:isAchieved()
    if self.vehicle == nil then
        return true
    elseif self.isControlled then
        return g_localPlayer:getCurrentVehicle() == self.vehicle
    else
        return g_localPlayer:getCurrentVehicle() ~= self.vehicle
    end
end
function GoalVehicleIsControlled.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    local isControlled = xmlFile:getValue(key .. "#isControlled", true)
    if vehicleName ~= nil then
        return GoalVehicleIsControlled.new(vehicleName, isControlled)
    end
    Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsControlled.NAME, GoalVehicleIsControlled)