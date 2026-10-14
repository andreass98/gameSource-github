ActionVehicleBlockLeaving = {}
ActionVehicleBlockLeaving.NAME = "vehicleBlockLeaving"
local ActionVehicleBlockLeaving_mt = Class(ActionVehicleBlockLeaving)
function ActionVehicleBlockLeaving.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if leaving is blocked or not", nil, true)
end
function ActionVehicleBlockLeaving.new(vehicleName, isBlocked, customMt)
    -- upvalues: (copy) ActionVehicleBlockLeaving_mt
    local self = setmetatable({}, customMt or ActionVehicleBlockLeaving_mt)
    self.vehicleName = vehicleName
    self.isBlocked = isBlocked
    return self
end
function ActionVehicleBlockLeaving:run(_, _)
    local vehicle = g_localPlayer:getCurrentVehicle()
    if self.vehicleName ~= nil then
        vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    end
    if vehicle == nil then
        return false
    end
    if vehicle.setIsLeavingAllowed ~= nil then
        vehicle:setIsLeavingAllowed(not self.isBlocked)
    end
    return true
end
function ActionVehicleBlockLeaving.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    local isBlocked = xmlFile:getValue(key .. "#isBlocked")
    if vehicleName == nil or isBlocked == nil then
        return nil
    else
        return ActionVehicleBlockLeaving.new(vehicleName, isBlocked)
    end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockLeaving.NAME, ActionVehicleBlockLeaving)