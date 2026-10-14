ActionVehicleDetach = {}
ActionVehicleDetach.NAME = "vehicleDetach"
local ActionVehicleDetach_mt = Class(ActionVehicleDetach)
function ActionVehicleDetach.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end
function ActionVehicleDetach.new(vehicleName, customMt)
    -- upvalues: (copy) ActionVehicleDetach_mt
    local self = setmetatable({}, customMt or ActionVehicleDetach_mt)
    self.vehicleName = vehicleName
    return self
end
function ActionVehicleDetach:run(_, _)
    local vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if vehicle == nil then
        Logging.warning("ActionVehicleDetach.run: Vehicle \'%s\' not found", self.vehicleName)
    end
    if vehicle.getAttacherVehicle == nil then
        return true
    end
    local attacherVehicle = vehicle:getAttacherVehicle()
    if attacherVehicle ~= nil then
        attacherVehicle:detachImplementByObject(vehicle)
    end
    return true
end
function ActionVehicleDetach.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName == nil then
        return nil
    else
        return ActionVehicleDetach.new(vehicleName)
    end
end
g_guidedTourManager:registerActionClass(ActionVehicleDetach.NAME, ActionVehicleDetach)