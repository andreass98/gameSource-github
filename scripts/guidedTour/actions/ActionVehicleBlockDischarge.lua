ActionVehicleBlockDischarge = {}
ActionVehicleBlockDischarge.NAME = "vehicleBlockDischarge"
local ActionVehicleBlockDischarge_mt = Class(ActionVehicleBlockDischarge)
function ActionVehicleBlockDischarge.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if discharge is blocked or not", nil, true)
end
function ActionVehicleBlockDischarge.new(vehicleName, isBlocked, customMt)
    -- upvalues: (copy) ActionVehicleBlockDischarge_mt
    local self = setmetatable({}, customMt or ActionVehicleBlockDischarge_mt)
    self.vehicleName = vehicleName
    self.isBlocked = isBlocked
    return self
end
function ActionVehicleBlockDischarge:run(_, _)
    local vehicle = g_localPlayer:getCurrentVehicle()
    if self.vehicleName ~= nil then
        vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    end
    if vehicle == nil then
        return false
    end
    if vehicle.setIsDischargeAllowed ~= nil then
        vehicle:setIsDischargeAllowed(not self.isBlocked)
    end
    return true
end
function ActionVehicleBlockDischarge.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    local isBlocked = xmlFile:getValue(key .. "#isBlocked")
    if vehicleName == nil or isBlocked == nil then
        return nil
    else
        return ActionVehicleBlockDischarge.new(vehicleName, isBlocked)
    end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockDischarge.NAME, ActionVehicleBlockDischarge)