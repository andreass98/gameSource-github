GoalVehicleAttachedTo = {}
GoalVehicleAttachedTo.NAME = "vehicleAttachedTo"
local GoalVehicleAttachedTo_mt = Class(GoalVehicleAttachedTo)
function GoalVehicleAttachedTo.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
    schema:register(XMLValueType.STRING, basePath .. "#attachment", "Identifier of the attachment", nil, true)
end
function GoalVehicleAttachedTo.new(vehicleName, attachmentName, customMt)
    -- upvalues: (copy) GoalVehicleAttachedTo_mt
    local self = setmetatable({}, customMt or GoalVehicleAttachedTo_mt)
    self.vehicleName = vehicleName
    self.attachmentName = attachmentName
    return self
end
function GoalVehicleAttachedTo:activate(_, _)
    self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if self.vehicle == nil then
        Logging.warning("GoalVehicleAttachedTo.activate: Vehicle \'%s\' not found", self.vehicleName)
    else
        self.attachment = g_guidedTourManager:getVehicleByName(self.attachmentName)
        if self.attachment == nil then
            Logging.warning("GoalVehicleAttachedTo.activate: Attachment \'%s\' not found", self.attachmentName)
        end
    end
end
function GoalVehicleAttachedTo:deactivate()
    self.vehicle = nil
    self.attachment = nil
end
function GoalVehicleAttachedTo:isAchieved()
    if self.vehicle == nil or self.attachment == nil then
        return true
    end
    return self.attachment.rootVehicle == self.vehicle
end
function GoalVehicleAttachedTo.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName == nil then
        Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
        return nil
    end
    local attachmentName = xmlFile:getValue(key .. "#attachment")
    if attachmentName ~= nil then
        return GoalVehicleAttachedTo.new(vehicleName, attachmentName)
    end
    Logging.xmlWarning(xmlFile, "Missing \'attachment\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleAttachedTo.NAME, GoalVehicleAttachedTo)