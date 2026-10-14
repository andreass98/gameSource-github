FrontloaderAttacher = {}
function FrontloaderAttacher.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
end
function FrontloaderAttacher.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FrontloaderAttacher)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", FrontloaderAttacher)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", FrontloaderAttacher)
end
function FrontloaderAttacher.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("frontloader", g_i18n:getText("configuration_frontloaderAttacher"), nil, VehicleConfigurationItem)
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("FrontloaderAttacher")
    schema:register(XMLValueType.BOOL, "vehicle.frontloaderConfigurations.frontloaderConfiguration(?).attacherJoint#frontAxisLimitJoint", "Front axis joint will be limited while attached", true)
    schema:register(XMLValueType.INT, "vehicle.frontloaderConfigurations.frontloaderConfiguration(?).attacherJoint#frontAxisJoint", "Front axis joint index", 1)
    schema:setXMLSpecializationType()
end
function FrontloaderAttacher:onLoad(_)
    if self.configurations.frontloader ~= nil then
        local key = string.format("vehicle.frontloaderConfigurations.frontloaderConfiguration(%d)", self.configurations.frontloader - 1)
        if self.xmlFile:hasProperty(key .. ".attacherJoint") and self.xmlFile:getValue(key .. ".attacherJoint#frontAxisLimitJoint", true) then
            local frontAxisJoint = self.xmlFile:getValue(key .. ".attacherJoint#frontAxisJoint", 1)
            if self.componentJoints[frontAxisJoint] == nil then
                Logging.xmlWarning(self.xmlFile, "Invalid front-axis joint \'%s\' for frontloader attacher.", frontAxisJoint)
            else
                self.spec_frontloaderAttacher.frontAxisJoint = frontAxisJoint
            end
        end
    end
    if not self.isServer or self.spec_frontloaderAttacher.frontAxisJoint == nil then
        SpecializationUtil.removeEventListener(self, "onPreDetachImplement", FrontloaderAttacher)
        SpecializationUtil.removeEventListener(self, "onPreAttachImplement", FrontloaderAttacher)
    end
end
function FrontloaderAttacher:onPreDetachImplement(implement)
    local spec = self.spec_frontloaderAttacher
    if spec.frontAxisJoint ~= nil then
        local attacherJoint = nil
        local attacherJoints = self:getAttacherJoints()
        if attacherJoints ~= nil then
            attacherJoint = attacherJoints[implement.jointDescIndex]
        end
        if attacherJoint ~= nil and attacherJoint.jointType == AttacherJoints.JOINTTYPE_ATTACHABLEFRONTLOADER then
            local i = 1
            for i = i, 3 do
                self:setComponentJointRotLimit(self.componentJoints[spec.frontAxisJoint], i, -spec.rotLimit[i], spec.rotLimit[i])
            end
        end
    end
end
function FrontloaderAttacher:onPreAttachImplement(_, _, jointDescIndex, _)
    local spec = self.spec_frontloaderAttacher
    if spec.frontAxisJoint ~= nil then
        local attacherJoint = nil
        local attacherJoints = self:getAttacherJoints()
        if attacherJoints ~= nil then
            attacherJoint = attacherJoints[jointDescIndex]
        end
        if attacherJoint ~= nil and attacherJoint.jointType == AttacherJoints.JOINTTYPE_ATTACHABLEFRONTLOADER then
            local i = self.componentJoints[spec.frontAxisJoint].rotLimit
            spec.rotLimit = { unpack(i) }
            local i = 1
            for i = i, 3 do
                self:setComponentJointRotLimit(self.componentJoints[spec.frontAxisJoint], i, 0, 0)
            end
        end
    end
end