ActionVehicleBlockToggleSeeds = {}
ActionVehicleBlockToggleSeeds.NAME = "vehicleBlockToggleSeeds"
local ActionVehicleBlockToggleSeeds_mt = Class(ActionVehicleBlockToggleSeeds)
function ActionVehicleBlockToggleSeeds.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if toggle seeds is blocked or not", nil, true)
end
function ActionVehicleBlockToggleSeeds.new(vehicleName, isBlocked, customMt)
    -- upvalues: (copy) ActionVehicleBlockToggleSeeds_mt
    local self = setmetatable({}, customMt or ActionVehicleBlockToggleSeeds_mt)
    self.vehicleName = vehicleName
    self.isBlocked = isBlocked
    return self
end
function ActionVehicleBlockToggleSeeds:run(_, _)
    local vehicle = g_localPlayer:getCurrentVehicle()
    if self.vehicleName ~= nil then
        vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    end
    if vehicle == nil then
        return false
    end
    if vehicle.setIsSeedChangeAllowed ~= nil then
        vehicle:setIsSeedChangeAllowed(not self.isBlocked)
    end
    return true
end
function ActionVehicleBlockToggleSeeds.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    local isBlocked = xmlFile:getValue(key .. "#isBlocked")
    if vehicleName == nil or isBlocked == nil then
        return nil
    else
        return ActionVehicleBlockToggleSeeds.new(vehicleName, isBlocked)
    end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockToggleSeeds.NAME, ActionVehicleBlockToggleSeeds)