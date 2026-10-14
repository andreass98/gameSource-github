ActionVehicleBlockFolding = {}
ActionVehicleBlockFolding.NAME = "vehicleBlockFolding"
local ActionVehicleBlockFolding_mt = Class(ActionVehicleBlockFolding)
function ActionVehicleBlockFolding.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if folding is blocked or not", nil, true)
end
function ActionVehicleBlockFolding.new(vehicleName, isBlocked, customMt)
    -- upvalues: (copy) ActionVehicleBlockFolding_mt
    local self = setmetatable({}, customMt or ActionVehicleBlockFolding_mt)
    self.vehicleName = vehicleName
    self.isBlocked = isBlocked
    return self
end
function ActionVehicleBlockFolding:run(_, _)
    local vehicle = g_localPlayer:getCurrentVehicle()
    if self.vehicleName ~= nil then
        vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    end
    if vehicle == nil then
        return false
    end
    if vehicle.setIsFoldActionAllowed ~= nil then
        vehicle:setIsFoldActionAllowed(not self.isBlocked)
    end
    return true
end
function ActionVehicleBlockFolding.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    local isBlocked = xmlFile:getValue(key .. "#isBlocked")
    if vehicleName == nil or isBlocked == nil then
        return nil
    else
        return ActionVehicleBlockFolding.new(vehicleName, isBlocked)
    end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockFolding.NAME, ActionVehicleBlockFolding)