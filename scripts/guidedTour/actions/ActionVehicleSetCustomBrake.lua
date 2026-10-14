ActionVehicleSetCustomBrake = {}
ActionVehicleSetCustomBrake.NAME = "vehicleCustomBrake"
local ActionVehicleSetCustomBrake_mt = Class(ActionVehicleSetCustomBrake)
function ActionVehicleSetCustomBrake.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
    schema:register(XMLValueType.FLOAT, basePath .. "#brakeForce", "Value of the custom brake force", nil, true)
end
function ActionVehicleSetCustomBrake.new(vehicleName, brakeForce, customMt)
    -- upvalues: (copy) ActionVehicleSetCustomBrake_mt
    local self = setmetatable({}, customMt or ActionVehicleSetCustomBrake_mt)
    self.vehicleName = vehicleName
    self.brakeForce = brakeForce
    return self
end
function ActionVehicleSetCustomBrake:run(_, _)
    local vehicle = g_localPlayer:getCurrentVehicle()
    if self.vehicleName ~= nil then
        vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    end
    if vehicle == nil then
        return false
    end
    local brakeForce = self.brakeForce
    if brakeForce ~= nil and vehicle.setCruiseControlState ~= nil then
        vehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
    end
    if vehicle.setCustomBrakeForce ~= nil then
        vehicle:setCustomBrakeForce(brakeForce)
    end
    return true
end
function ActionVehicleSetCustomBrake.createFromXML(xmlFile, key, _, _)
    local brakeForce = xmlFile:getValue(key .. "#brakeForce")
    if brakeForce == nil then
        return nil
    end
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if brakeForce <= 0 then
        brakeForce = nil
    end
    return ActionVehicleSetCustomBrake.new(vehicleName, brakeForce)
end
g_guidedTourManager:registerActionClass(ActionVehicleSetCustomBrake.NAME, ActionVehicleSetCustomBrake)