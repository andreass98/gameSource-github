GoalVehicleInAttachRange = {}
GoalVehicleInAttachRange.NAME = "vehicleInAttachRange"
local GoalVehicleInAttachRange_mt = Class(GoalVehicleInAttachRange)
function GoalVehicleInAttachRange.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
    schema:register(XMLValueType.INT, basePath .. "#attacherJointIndex", "Index of the vehicle attacher joint", nil, true)
    schema:register(XMLValueType.STRING, basePath .. "#attachment", "Identifier of the attachment", nil, true)
    schema:register(XMLValueType.INT, basePath .. "#inputAttacherJointIndex", "Index of the attachment input attacher joint index", nil, true)
end
function GoalVehicleInAttachRange.new(vehicleName, attacherJointIndex, attachmentName, inputAttacherJointIndex, customMt)
    -- upvalues: (copy) GoalVehicleInAttachRange_mt
    local self = setmetatable({}, customMt or GoalVehicleInAttachRange_mt)
    self.vehicleName = vehicleName
    self.attacherJointIndex = attacherJointIndex
    self.attachmentName = attachmentName
    self.inputAttacherJointIndex = inputAttacherJointIndex
    return self
end
function GoalVehicleInAttachRange:activate(_, _)
    local vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
    if vehicle == nil then
        Logging.warning("GoalVehicleInAttachRange.activate: Vehicle \'%s\' not found", self.vehicleName)
        return
    elseif vehicle.getAttacherJointByJointDescIndex == nil then
        Logging.warning("GoalVehicleInAttachRange.activate: Vehicle \'%s\' has not attacher joints", self.vehicleName)
        return
    elseif vehicle:getAttacherJointByJointDescIndex(self.attacherJointIndex) == nil then
        Logging.warning("GoalVehicleInAttachRange.activate: Attacher joint \'%d\' not defined for vehicle \'%s\'", self.attacherJointIndex, self.vehicleName)
        return
    else
        local attachment = g_guidedTourManager:getVehicleByName(self.attachmentName)
        if attachment == nil then
            Logging.warning("GoalVehicleInAttachRange.activate: Attachment \'%s\' not found", self.attachmentName)
            return
        elseif vehicle:getAttacherJointByJointDescIndex(self.inputAttacherJointIndex) == nil then
            Logging.warning("GoalVehicleInAttachRange.activate: Input attacher joint \'%d\' not defined for vehicle \'%s\'", self.inputAttacherJointIndex, self.attachmentName)
        else
            self.vehicle = vehicle
            self.attachment = attachment
        end
    end
end
function GoalVehicleInAttachRange:deactivate()
    g_currentMission.navigationSystem:stop()
    self.vehicle = nil
    self.attachment = nil
end
function GoalVehicleInAttachRange:isAchieved()
    if self.vehicle == nil then
        return true
    else
        local node = self.attachment:getInputAttacherJointByJointDescIndex(self.inputAttacherJointIndex).node
        local x, y, z = getWorldTranslation(node)
        local dirX, _, dirZ = localDirectionToWorld(node, 1, 0, 0)
        g_currentMission.navigationSystem:navigateTo(x, y, z, dirX, 0, dirZ)
        local attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex = self.vehicle:getAttachableInfo()
        if attacherVehicle == self.vehicle then
            if attacherVehicleJointDescIndex == self.attacherJointIndex then
                if attachable == self.attachment then
                    return attachableJointDescIndex == self.inputAttacherJointIndex
                else
                    return false
                end
            else
                return false
            end
        else
            return false
        end
    end
end
function GoalVehicleInAttachRange.createFromXML(xmlFile, key, _, _)
    local vehicleName = xmlFile:getValue(key .. "#vehicle")
    if vehicleName == nil then
        Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
        return nil
    end
    local attacherJointIndex = xmlFile:getValue(key .. "#attacherJointIndex")
    if attacherJointIndex == nil then
        Logging.xmlWarning(xmlFile, "Missing \'attacherJointIndex\' for \'%s\'", key)
        return nil
    end
    local attachmentName = xmlFile:getValue(key .. "#attachment")
    if attachmentName == nil then
        Logging.xmlWarning(xmlFile, "Missing \'attachment\' for \'%s\'", key)
        return nil
    end
    local inputAttacherJointIndex = xmlFile:getValue(key .. "#inputAttacherJointIndex")
    if inputAttacherJointIndex ~= nil then
        return GoalVehicleInAttachRange.new(vehicleName, attacherJointIndex, attachmentName, inputAttacherJointIndex)
    end
    Logging.xmlWarning(xmlFile, "Missing \'inputAttacherJointIndex\' for \'%s\'", key)
    return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleInAttachRange.NAME, GoalVehicleInAttachRange)