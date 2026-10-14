ActionVehicleBlockAttacherJoint = {}
ActionVehicleBlockAttacherJoint.NAME = "vehicleBlockAttacherJoint"
local ActionVehicleBlockAttacherJoint_mt = Class(ActionVehicleBlockAttacherJoint)
function ActionVehicleBlockAttacherJoint.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, true)
    schema:register(XMLValueType.INT, basePath .. "#attacherJointIndex", "Index of the attacher joint", nil, true)
    schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if detaching is blocked or not", nil, true)
end
function ActionVehicleBlockAttacherJoint.new(vehicleName, attacherJointIndex, isBlocked, customMt)
    -- upvalues: (copy) ActionVehicleBlockAttacherJoint_mt
    local self = setmetatable({}, customMt or ActionVehicleBlockAttacherJoint_mt)
    self.vehicleName = vehicleName
    self.attacherJointIndex = attacherJointIndex
    self.isBlocked = isBlocked
    return self
end
function ActionVehicleBlockAttacherJoint:run(_, _)
    local vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if vehicle == nil then
        Logging.warning("ActionVehicleBlockAttacherJoint.run: Vehicle \'%s\' not found", self.vehicleName)
        return false
    elseif vehicle.setAttacherJointBlocked == nil then
        Logging.warning("ActionVehicleBlockAttacherJoint.run: Vehicle \'%s\' does not have attacher joints", self.vehicleName)
        return false
    else
        vehicle:setAttacherJointBlocked(self.attacherJointIndex, self.isBlocked)
        return true
    end
end
function ActionVehicleBlockAttacherJoint.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    local attacherJointIndex = xmlFile:getValue(key .. "#attacherJointIndex")
    local isBlocked = xmlFile:getValue(key .. "#isBlocked")
    if vehicleName == nil or (attacherJointIndex == nil or isBlocked == nil) then
        return nil
    else
        return ActionVehicleBlockAttacherJoint.new(vehicleName, attacherJointIndex, isBlocked)
    end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockAttacherJoint.NAME, ActionVehicleBlockAttacherJoint)