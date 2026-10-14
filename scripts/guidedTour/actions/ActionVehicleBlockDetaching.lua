ActionVehicleBlockDetaching = {}
ActionVehicleBlockDetaching.NAME = "vehicleBlockDetaching"
local ActionVehicleBlockDetaching_mt = Class(ActionVehicleBlockDetaching)
function ActionVehicleBlockDetaching.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if detaching is blocked or not", nil, true)
end
function ActionVehicleBlockDetaching.new(vehicleName, isBlocked, customMt)
    -- upvalues: (copy) ActionVehicleBlockDetaching_mt
    local self = setmetatable({}, customMt or ActionVehicleBlockDetaching_mt)
    self.vehicleName = vehicleName
    self.isBlocked = isBlocked
    return self
end
function ActionVehicleBlockDetaching:run(_, _)
    local vehicle = g_localPlayer:getCurrentVehicle()
    if self.vehicleName ~= nil then
        vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    end
    if vehicle == nil then
        return false
    end
    if vehicle.setIsDetachingBlocked ~= nil then
        vehicle:setIsDetachingBlocked(self.isBlocked)
    end
    return true
end
function ActionVehicleBlockDetaching.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    local isBlocked = xmlFile:getValue(key .. "#isBlocked")
    if vehicleName == nil or isBlocked == nil then
        return nil
    else
        return ActionVehicleBlockDetaching.new(vehicleName, isBlocked)
    end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockDetaching.NAME, ActionVehicleBlockDetaching)