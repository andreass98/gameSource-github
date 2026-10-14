AttacherJointsCompControl = {}
function AttacherJointsCompControl.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
end
function AttacherJointsCompControl.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AttacherJointsCompControl")
    schema:addDelayedRegistrationFunc("AttacherJoint", function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. ".dependentComponentJoint#index", "Index of component joint that will be adjusted while something is attached")
        cSchema:register(XMLValueType.FLOAT, cKey .. ".dependentComponentJoint#transSpringFactor", "Factor that will be applied to the spring values on attach", 1)
        cSchema:register(XMLValueType.FLOAT, cKey .. ".dependentComponentJoint#transDampingFactor", "Factor that will be applied to the damping values on attach", "#transSpringFactor")
        cSchema:register(XMLValueType.FLOAT, cKey .. ".dependentComponentJoint#referenceMass", "Reference mass for spring and damping adjustments. At the mass attached to the front, the full factor will be applied to the spring/damping. (to)", 1)
        cSchema:register(XMLValueType.TIME, cKey .. ".dependentComponentJoint#attachInterpolationTime", "Time for the interpolation between the damping values after attach", 1)
        cSchema:register(XMLValueType.TIME, cKey .. ".dependentComponentJoint#detachInterpolationTime", "Time for the interpolation between the damping values after detach", 0.5)
    end)
    schema:setXMLSpecializationType()
end
function AttacherJointsCompControl.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setDependentComponentJointBaseFactors", AttacherJointsCompControl.setDependentComponentJointBaseFactors)
    SpecializationUtil.registerFunction(vehicleType, "addDependentComponentJointData", AttacherJointsCompControl.addDependentComponentJointData)
    SpecializationUtil.registerFunction(vehicleType, "updateDependentComponentJointValues", AttacherJointsCompControl.updateDependentComponentJointValues)
end
function AttacherJointsCompControl.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AttacherJointsCompControl.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointFromXML", AttacherJointsCompControl.loadAttacherJointFromXML)
end
function AttacherJointsCompControl.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AttacherJointsCompControl)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AttacherJointsCompControl)
end
function AttacherJointsCompControl:onPreLoad(_)
    self.spec_attacherJointsCompControl.dependentComponentJointData = {}
    if not self.isServer then
        SpecializationUtil.removeEventListener(self, "onStateChange", AttacherJointsCompControl)
    end
end
function AttacherJointsCompControl:onStateChange(state, _)
    if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
        self:updateDependentComponentJointValues()
    end
end
function AttacherJointsCompControl:setDependentComponentJointBaseFactors(componentJointIndex, transSpringFactor, transDampingFactor, overwrite)
    if self.isServer then
        local data = self:addDependentComponentJointData(componentJointIndex)
        if data ~= nil then
            if overwrite then
                data.baseTransSpringFactor = transSpringFactor or 1
                data.baseTransDampingFactor = transDampingFactor or 1
                return
            end
            data.baseTransSpringFactor = data.baseTransSpringFactor * (transSpringFactor or 1)
            data.baseTransDampingFactor = data.baseTransDampingFactor * (transDampingFactor or 1)
        end
    end
end
function AttacherJointsCompControl:addDependentComponentJointData(componentJointIndex)
    if componentJointIndex == nil then
        return nil
    end
    local componentJoint = self.componentJoints[componentJointIndex]
    if componentJoint == nil then
        Logging.xmlWarning(self.xmlFile, "Unknown component joint index \'%s\' in dependentComponentJoint", componentJointIndex)
        return nil
    end
    local spec = self.spec_attacherJointsCompControl
    local key = "dependentComponentJoint_" .. getName(componentJoint.jointNode)
    if spec.dependentComponentJointData[key] == nil then
        local data = {
            ["interpolatorKey"] = key,
            ["baseTransSpringFactor"] = 1,
            ["baseTransDampingFactor"] = 1,
            ["curTransSpringFactor"] = 1,
            ["curTransDampingFactor"] = 1,
            ["targetTransSpringFactor"] = 1,
            ["targetTransDampingFactor"] = 1,
            ["attachInterpolationTime"] = 1,
            ["detachInterpolationTime"] = 0.5,
            ["interpolatorGet"] = function()
                -- upvalues: (copy) data
                return data.curTransSpringFactor, data.curTransDampingFactor
            end,
            ["interpolatorSet"] = function(springFactor, dampingFactor)
                -- upvalues: (copy) data, (copy) componentJoint
                data.curTransSpringFactor = springFactor
                data.curTransDampingFactor = dampingFactor
                local axis = 1
                for axis = axis, 3 do
                    setJointTranslationLimitSpring(componentJoint.jointIndex, axis - 1, componentJoint.transLimitSpring[axis] * springFactor, componentJoint.transLimitDamping[axis] * dampingFactor)
                end
            end
        }
        spec.dependentComponentJointData[key] = data
    end
    return spec.dependentComponentJointData[key]
end
function AttacherJointsCompControl:updateDependentComponentJointValues(forceUpdate, skipInterpolation)
    local spec = self.spec_attacherJointsCompControl
    for i, data in pairs(spec.dependentComponentJointData) do
        data.targetTransSpringFactor = data.baseTransSpringFactor
        data.targetTransDampingFactor = data.baseTransDampingFactor
    end
    for i, data in ipairs(self:getAttacherJoints()) do
        local mass = 0
        local implement = self:getImplementByJointDescIndex(i)
        if implement ~= nil then
            mass = implement.object:getTotalMass()
        end
        if data.dependentComponentJoint ~= nil then
            local data = data.dependentComponentJoint.data
            local scale = math.min(mass / data.dependentComponentJoint.referenceMass, 1)
            data.targetTransSpringFactor = data.targetTransSpringFactor + ((data.dependentComponentJoint.transSpringFactor - 1) * scale + 1 - 1)
            data.targetTransDampingFactor = data.targetTransDampingFactor + ((data.dependentComponentJoint.transDampingFactor - 1) * scale + 1 - 1)
        end
    end
    for i, data in pairs(spec.dependentComponentJointData) do
        if data.targetTransSpringFactor ~= data.curTransSpringFactor or (data.targetTransDampingFactor ~= data.curTransDampingFactor or forceUpdate) then
            local mass = data.attachInterpolationTime
            if data.targetTransSpringFactor <= data.baseTransSpringFactor + 0.001 and data.targetTransDampingFactor <= data.targetTransDampingFactor + 0.001 then
                mass = data.detachInterpolationTime
            end
            if skipInterpolation then
                data.interpolatorSet(data.targetTransSpringFactor, data.targetTransDampingFactor)
            else
                local implement = ValueInterpolator.new(i, data.interpolatorGet, data.interpolatorSet, { data.targetTransSpringFactor, data.targetTransDampingFactor }, mass)
                if implement ~= nil then
                    implement:setDeleteListenerObject(self)
                end
            end
        end
    end
end
function AttacherJointsCompControl:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end
    if self.isServer then
        self:updateDependentComponentJointValues(true, true)
    end
    return true
end
function AttacherJointsCompControl:loadAttacherJointFromXML(superFunc, attacherJoint, xmlFile, baseName, index)
    if not superFunc(self, attacherJoint, xmlFile, baseName, index) then
        return false
    end
    if self.isServer then
        local componentJointIndex = xmlFile:getValue(baseName .. ".dependentComponentJoint#index")
        if componentJointIndex ~= nil then
            local data = self:addDependentComponentJointData(componentJointIndex)
            if data ~= nil then
                data.attachInterpolationTime = xmlFile:getValue(baseName .. ".dependentComponentJoint#attachInterpolationTime", data.attachInterpolationTime)
                data.detachInterpolationTime = xmlFile:getValue(baseName .. ".dependentComponentJoint#detachInterpolationTime", data.detachInterpolationTime)
                attacherJoint.dependentComponentJoint = {}
                attacherJoint.dependentComponentJoint.data = data
                attacherJoint.dependentComponentJoint.transSpringFactor = xmlFile:getValue(baseName .. ".dependentComponentJoint#transSpringFactor", 1)
                attacherJoint.dependentComponentJoint.transDampingFactor = xmlFile:getValue(baseName .. ".dependentComponentJoint#transDampingFactor", attacherJoint.dependentComponentJoint.transSpringFactor)
                attacherJoint.dependentComponentJoint.referenceMass = xmlFile:getValue(baseName .. ".dependentComponentJoint#referenceMass", 1)
            end
        end
    end
    return true
end
function AttacherJointsCompControl:updateDebugValues(values)
    for jointIndex, attacherJoint in ipairs(self:getAttacherJoints()) do
        local mass = 0
        local implement = self:getImplementByJointDescIndex(jointIndex)
        if implement ~= nil then
            mass = implement.object:getTotalMass()
        end
        if attacherJoint.dependentComponentJoint ~= nil then
            table.insert(values, {
                ["name"] = "Attacher Joint",
                ["value"] = tostring(jointIndex)
            })
            local scale = math.min(mass / attacherJoint.dependentComponentJoint.referenceMass, 1)
            table.insert(values, {
                ["name"] = "Mass",
                ["value"] = string.format("%.2f / %.2f to", mass, attacherJoint.dependentComponentJoint.referenceMass)
            })
            table.insert(values, {
                ["name"] = "Spring Factors",
                ["value"] = string.format("spring %.2f damping %.2f", (attacherJoint.dependentComponentJoint.transSpringFactor - 1) * scale + 1, (attacherJoint.dependentComponentJoint.transDampingFactor - 1) * scale + 1)
            })
        end
    end
    for jointIndex, attacherJoint in pairs(self.spec_attacherJointsCompControl.dependentComponentJointData) do
        table.insert(values, {
            ["name"] = "Component Joint",
            ["value"] = jointIndex
        })
        local scale = {
            ["name"] = "Base Factors",
            ["value"] = string.format("spring %.2f damping %.2f", attacherJoint.baseTransSpringFactor, attacherJoint.baseTransDampingFactor)
        }
        table.insert(values, scale)
        local scale = {
            ["name"] = "Current Factors",
            ["value"] = string.format("spring %.2f damping %.2f", attacherJoint.curTransSpringFactor, attacherJoint.curTransDampingFactor)
        }
        table.insert(values, scale)
    end
end