ActionVehicleBlockAIStart = {}
ActionVehicleBlockAIStart.NAME = "vehicleBlockAIStart"
local ActionVehicleBlockAIStart_mt = Class(ActionVehicleBlockAIStart)
function ActionVehicleBlockAIStart.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
    schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if ai start is blocked or not", nil, true)
end
function ActionVehicleBlockAIStart.new(vehicleName, isBlocked, customMt)
    -- upvalues: (copy) ActionVehicleBlockAIStart_mt
    local self = setmetatable({}, customMt or ActionVehicleBlockAIStart_mt)
    self.vehicleName = vehicleName
    self.isBlocked = isBlocked
    return self
end
function ActionVehicleBlockAIStart:run(_, _)
    local vehicle = g_localPlayer:getCurrentVehicle()
    if self.vehicleName ~= nil then
        vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    end
    if vehicle == nil then
        return false
    end
    if vehicle.setIsAIStartAllowed ~= nil then
        vehicle:setIsAIStartAllowed(not self.isBlocked)
    end
    return true
end
function ActionVehicleBlockAIStart.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    local isBlocked = xmlFile:getValue(key .. "#isBlocked")
    if vehicleName == nil or isBlocked == nil then
        return nil
    else
        return ActionVehicleBlockAIStart.new(vehicleName, isBlocked)
    end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockAIStart.NAME, ActionVehicleBlockAIStart)