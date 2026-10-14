AttacherJointControl = {}
AttacherJointControl.ALPHA_NUM_BITS = 8
AttacherJointControl.ALPHA_MAX_VALUE = 2 ^ AttacherJointControl.ALPHA_NUM_BITS - 1
function AttacherJointControl.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Attachable, specializations)
end
function AttacherJointControl.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AttacherJointControl")
    schema:register(XMLValueType.ANGLE, "vehicle.attacherJointControl#maxTiltAngle", "Max tilt angle", 25)
    schema:register(XMLValueType.BOOL, "vehicle.attacherJointControl#supportsDamping", "Supports damping of Y axis", false)
    schema:register(XMLValueType.FLOAT, "vehicle.attacherJointControl#dampingOffset", "Distance from attacher joint to damping reference point (m)", 2)
    schema:register(XMLValueType.STRING, "vehicle.attacherJointControl.control(?)#controlFunction", "Control script function (controlAttacherJointHeight or controlAttacherJointTilt)")
    schema:register(XMLValueType.STRING, "vehicle.attacherJointControl.control(?)#controlAxis", "Name of input action")
    schema:register(XMLValueType.STRING, "vehicle.attacherJointControl.control(?)#iconName", "Name of icon")
    schema:registerAutoCompletionDataSource("vehicle.attacherJointControl.control(?)#iconName", "$dataS/axisIcons.xml", "axisIcons.icon#name")
    schema:register(XMLValueType.BOOL, "vehicle.attacherJointControl.control(?)#invertControlAxis", "Invert control axis", false)
    schema:register(XMLValueType.FLOAT, "vehicle.attacherJointControl.control(?)#mouseSpeedFactor", "Mouse speed factor", 1)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.attacherJointControl.sounds", "hydraulic")
    schema:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#isControllable", "Is controllable", false)
    schema:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#isControllable", "Is controllable", false)
    schema:setXMLSpecializationType()
end
function AttacherJointControl.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "controlAttacherJoint", AttacherJointControl.controlAttacherJoint)
    SpecializationUtil.registerFunction(vehicleType, "controlAttacherJointHeight", AttacherJointControl.controlAttacherJointHeight)
    SpecializationUtil.registerFunction(vehicleType, "controlAttacherJointTilt", AttacherJointControl.controlAttacherJointTilt)
    SpecializationUtil.registerFunction(vehicleType, "getControlAttacherJointDirection", AttacherJointControl.getControlAttacherJointDirection)
    SpecializationUtil.registerFunction(vehicleType, "getIsAttacherJointControlDampingAllowed", AttacherJointControl.getIsAttacherJointControlDampingAllowed)
end
function AttacherJointControl.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", AttacherJointControl.loadInputAttacherJoint)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerLoweringActionEvent", AttacherJointControl.registerLoweringActionEvent)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getLoweringActionEventState", AttacherJointControl.getLoweringActionEventState)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", AttacherJointControl.getCanBeSelected)
end
function AttacherJointControl.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AttacherJointControl)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AttacherJointControl)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AttacherJointControl)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AttacherJointControl)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", AttacherJointControl)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", AttacherJointControl)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AttacherJointControl)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AttacherJointControl)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", AttacherJointControl)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", AttacherJointControl)
end
function AttacherJointControl:onLoad(_)
    local spec = self.spec_attacherJointControl
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attacherJointControl.control1", "vehicle.attacherJointControl.control with #controlFunction \'controlAttacherJointHeight\'")
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attacherJointControl.control2", "vehicle.attacherJointControl.control with #controlFunction \'controlAttacherJointTilt\'")
    spec.maxTiltAngle = self.xmlFile:getValue("vehicle.attacherJointControl#maxTiltAngle", 25)
    spec.heightTargetAlpha = -1
    spec.supportsDamping = self.xmlFile:getValue("vehicle.attacherJointControl#supportsDamping", false)
    spec.dampingOffset = self.xmlFile:getValue("vehicle.attacherJointControl#dampingOffset", 2)
    spec.nextHeightDampingUpdateTime = 0
    spec.controls = {}
    spec.nameToControl = {}
    local i = 0
    while true do
        local key = string.format("%s.control(%d)", "vehicle.attacherJointControl", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local control = {}
        local controlFunc = self.xmlFile:getValue(key .. "#controlFunction")
        if controlFunc == nil or self[controlFunc] == nil then
            Logging.xmlWarning(self.xmlFile, "Unknown control function \'%s\' for attacher joint control \'%s\'", tostring(controlFunc), key)
            break
        end
        control.func = self[controlFunc]
        if control.func == self.controlAttacherJointHeight then
            spec.heightController = control
        end
        if control.func == self.controlAttacherJointTilt then
            spec.tiltController = control
        end
        local actionBindingName = self.xmlFile:getValue(key .. "#controlAxis")
        if actionBindingName == nil or InputAction[actionBindingName] == nil then
            Logging.xmlWarning(self.xmlFile, "Unknown control axis \'%s\' for attacher joint control \'%s\'", tostring(actionBindingName), key)
            break
        end
        control.controlAction = InputAction[actionBindingName]
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#controlAxisIcon", key .. "#iconName")
        local iconName = self.xmlFile:getValue(key .. "#iconName", "")
        if InputHelpElement.AXIS_ICON[iconName] == nil then
        end
        control.axisActionIcon = iconName
        control.invertAxis = self.xmlFile:getValue(key .. "#invertControlAxis", false)
        control.mouseSpeedFactor = self.xmlFile:getValue(key .. "#mouseSpeedFactor", 1)
        control.moveAlpha = 0
        control.moveAlphaSent = 0
        control.moveAlphaLastManual = 0
        spec.nameToControl[actionBindingName] = control
        table.insert(spec.controls, control)
        i = i + 1
    end
    if self.isClient then
        spec.lastMoveTime = 0
        spec.samples = {}
        spec.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJointControl.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    spec.jointDesc = nil
    spec.dirtyFlagClient = self:getNextDirtyFlag()
    spec.dirtyFlagServer = self:getNextDirtyFlag()
    if #spec.controls == 0 then
        SpecializationUtil.removeEventListener(self, "onReadStream", AttacherJointControl)
        SpecializationUtil.removeEventListener(self, "onWriteStream", AttacherJointControl)
        SpecializationUtil.removeEventListener(self, "onReadUpdateStream", AttacherJointControl)
        SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", AttacherJointControl)
        SpecializationUtil.removeEventListener(self, "onUpdate", AttacherJointControl)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", AttacherJointControl)
        SpecializationUtil.removeEventListener(self, "onPostAttach", AttacherJointControl)
        SpecializationUtil.removeEventListener(self, "onPreDetach", AttacherJointControl)
    end
end
function AttacherJointControl:onDelete()
    local spec = self.spec_attacherJointControl
    if self.isClient and spec.samples ~= nil then
        g_soundManager:deleteSample(spec.samples.hydraulic)
    end
end
function AttacherJointControl:onReadStream(streamId, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        for _, control in ipairs(self.spec_attacherJointControl.controls) do
            self:controlAttacherJoint(control, streamReadUIntN(streamId, AttacherJointControl.ALPHA_NUM_BITS) / AttacherJointControl.ALPHA_MAX_VALUE, false, true)
        end
    end
end
function AttacherJointControl:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_attacherJointControl
        if streamWriteBool(streamId, spec.jointDesc ~= nil) then
            for _, control in ipairs(spec.controls) do
                streamWriteUIntN(streamId, control.moveAlpha * AttacherJointControl.ALPHA_MAX_VALUE, AttacherJointControl.ALPHA_NUM_BITS)
            end
        end
    end
end
function AttacherJointControl:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for _, control in ipairs(self.spec_attacherJointControl.controls) do
                self:controlAttacherJoint(control, streamReadUIntN(streamId, AttacherJointControl.ALPHA_NUM_BITS) / AttacherJointControl.ALPHA_MAX_VALUE, false, true)
            end
        end
    elseif streamReadBool(streamId) then
        for _, control in ipairs(spec.controls) do
            self:controlAttacherJoint(control, streamReadUIntN(streamId, AttacherJointControl.ALPHA_NUM_BITS) / AttacherJointControl.ALPHA_MAX_VALUE, false, true)
        end
        return
    end
end
function AttacherJointControl:onWriteUpdateStream(streamId, connection, dirtyMask)
    if connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spec_attacherJointControl.dirtyFlagClient) ~= 0) then
            for _, control in ipairs(spec.controls) do
                streamWriteUIntN(streamId, control.moveAlpha * AttacherJointControl.ALPHA_MAX_VALUE, AttacherJointControl.ALPHA_NUM_BITS)
            end
            return
        end
    elseif streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlagServer) ~= 0) then
        for _, control in ipairs(spec.controls) do
            streamWriteUIntN(streamId, control.moveAlpha * AttacherJointControl.ALPHA_MAX_VALUE, AttacherJointControl.ALPHA_NUM_BITS)
        end
    end
end
function AttacherJointControl:onUpdate(dt, _, _, _)
    local spec = self.spec_attacherJointControl
    local control = spec.heightController
    if control ~= nil and spec.jointDesc ~= nil then
        if spec.heightTargetAlpha ~= -1 then
            local diff = spec.heightTargetAlpha - control.moveAlpha + 0.0001
            local moveStep = dt / (diff / (spec.jointDesc.upperAlpha - spec.jointDesc.lowerAlpha) * spec.jointDesc.moveTime) * diff
            if diff > 0 then
            end
            local newAlpha = control.moveAlpha + moveStep
            self:controlAttacherJoint(control, newAlpha, spec.nextHeightDampingUpdateTime < g_time, true)
            if math.abs(spec.heightTargetAlpha - newAlpha) < 0.01 then
                spec.heightTargetAlpha = -1
            end
        end
        if self.isServer and (spec.supportsDamping and spec.nextHeightDampingUpdateTime < g_time) then
            local diff = self:getActiveInputAttacherJoint()
            local moveTime = 0
            if self:getIsAttacherJointControlDampingAllowed() then
                local moveStep, newAlpha, wZ = getWorldTranslation(diff.node)
                local dirX, _, dirZ = localDirectionToWorld(diff.node, spec.dampingOffset, 0, 0)
                local posX, posY, posZ = worldToLocal(self.components[1].node, moveStep + dirX, newAlpha, wZ + dirZ)
                local _, vy, _ = getVelocityAtLocalPos(self.components[1].node, posX, posY, posZ)
                if math.abs(vy) > 0.15 then
                    moveTime = vy * 0.5
                end
            else
                moveTime = control.moveAlphaLastManual - control.moveAlpha
            end
            local moveTime = moveTime + (control.moveAlphaLastManual - control.moveAlpha) * 0.001 * dt
            if math.abs(moveTime) > 0.0001 then
                spec.heightTargetAlpha = math.clamp(control.moveAlpha + moveTime, 0, 1)
                if spec.heightTargetAlpha <= 0 and spec.tiltController ~= nil then
                    self:controlAttacherJoint(spec.tiltController, math.clamp(spec.tiltController.moveAlpha - moveTime * 0.1, 0, 1), true)
                end
            end
        end
    end
    if spec.lastMoveTime + 100 > g_time then
        if not g_soundManager:getIsSamplePlaying(spec.samples.hydraulic) then
            g_soundManager:playSample(spec.samples.hydraulic)
            return
        end
    elseif g_soundManager:getIsSamplePlaying(spec.samples.hydraulic) then
        g_soundManager:stopSample(spec.samples.hydraulic)
    end
end
function AttacherJointControl:controlAttacherJoint(control, moveAlpha, automaticControl, noEventSend)
    local spec = self.spec_attacherJointControl
    local jointDesc = spec.jointDesc
    if self.isServer and jointDesc ~= nil then
        moveAlpha = control.func(self, moveAlpha)
        self:getAttacherVehicle():updateAttacherJointRotation(jointDesc, self)
        if jointDesc.jointIndex ~= 0 then
            setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
        end
    end
    spec.lastMoveTime = g_time
    if not automaticControl then
        spec.nextHeightDampingUpdateTime = g_time + 100
        control.moveAlphaLastManual = control.moveAlpha
    end
    control.moveAlpha = math.min(math.max(moveAlpha, 0), 1)
    if noEventSend == nil or not noEventSend then
        if math.abs(control.moveAlphaSent - moveAlpha) > 1 / AttacherJointControl.ALPHA_MAX_VALUE then
            control.moveAlphaSent = moveAlpha
            if self.isServer then
                self:raiseDirtyFlags(spec.dirtyFlagServer)
            else
                self:raiseDirtyFlags(spec.dirtyFlagClient)
            end
        end
    else
        control.moveAlphaSent = moveAlpha
    end
end
function AttacherJointControl:controlAttacherJointHeight(moveAlpha)
    local spec = self.spec_attacherJointControl
    local jointDesc = spec.jointDesc
    if moveAlpha == nil then
        moveAlpha = jointDesc.moveAlpha
    end
    moveAlpha = math.clamp(moveAlpha, jointDesc.upperAlpha, jointDesc.lowerAlpha)
    self:updateAttacherJointRotationNodes(jointDesc, moveAlpha)
    jointDesc.moveAlpha = moveAlpha
    self:updateAttacherJointRotation(jointDesc, self)
    spec.lastHeightAlpha = moveAlpha
    return moveAlpha
end
function AttacherJointControl:controlAttacherJointTilt(moveAlpha)
    local spec = self.spec_attacherJointControl
    local angle = math.clamp(moveAlpha == nil and 0.5 or moveAlpha, 0, 1)
    local angle = spec.maxTiltAngle * -(angle - 0.5)
    spec.jointDesc.upperRotationOffset = spec.jointDesc.upperRotationOffsetBackup + angle
    spec.jointDesc.lowerRotationOffset = spec.jointDesc.lowerRotationOffsetBackup + angle
    return angle
end
function AttacherJointControl:getControlAttacherJointDirection()
    local spec = self.spec_attacherJointControl
    if spec.heightTargetAlpha ~= -1 then
        return spec.heightTargetAlpha == spec.jointDesc.upperAlpha
    end
    local lastAlpha = spec.heightController.moveAlpha
    return math.abs(lastAlpha - spec.jointDesc.upperAlpha) < math.abs(lastAlpha - spec.jointDesc.lowerAlpha)
end
function AttacherJointControl:getIsAttacherJointControlDampingAllowed()
    if self:getAttacherVehicle():getLastSpeed() < 0.5 then
        return false
    else
        return self.movingDirection > 0
    end
end
function AttacherJointControl:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, i)
    if not superFunc(self, xmlFile, key, inputAttacherJoint, i) then
        return false
    end
    inputAttacherJoint.isControllable = xmlFile:getValue(key .. "#isControllable", false)
    return true
end
function AttacherJointControl:registerLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
    if self.spec_attacherJointControl.heightController then
        local _, actionEventId = self:addPoweredActionEvent(actionEventsTable, InputAction.LOWER_IMPLEMENT, self, AttacherJointControl.actionEventAttacherJointControlSetPoint, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
        if inputAction == InputAction.LOWER_IMPLEMENT then
            return
        end
    end
    superFunc(self, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end
function AttacherJointControl:getLoweringActionEventState(superFunc)
    local spec = self.spec_attacherJointControl
    if not spec.heightController then
        return superFunc(self)
    end
    local showText = spec.jointDesc ~= nil
    local text = nil
    if showText then
        if self:getControlAttacherJointDirection() then
            return showText, string.format(g_i18n:getText("action_lowerOBJECT"), self.typeDesc)
        end
        text = string.format(g_i18n:getText("action_liftOBJECT"), self.typeDesc)
    end
    return showText, text
end
function AttacherJointControl:getCanBeSelected(superFunc)
    return true
end
function AttacherJointControl:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_attacherJointControl
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection and spec.jointDesc ~= nil then
            for _, control in ipairs(spec.controls) do
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, control.controlAction, self, AttacherJointControl.actionEventAttacherJointControl, false, false, true, true, nil, control.axisActionIcon)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            end
        end
    end
end
function AttacherJointControl:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
    local inputAttacherJoints = self:getInputAttacherJoints()
    if inputAttacherJoints[inputJointDescIndex] ~= nil and inputAttacherJoints[inputJointDescIndex].isControllable then
        local jointDesc = attacherVehicle:getAttacherJoints()[jointDescIndex]
        if jointDesc.upperAlpha == jointDesc.lowerAlpha then
            return
        end
        if jointDesc.allowsLoweringBackup == nil then
            jointDesc.allowsLoweringBackup = jointDesc.allowsLowering
        end
        jointDesc.allowsLowering = false
        jointDesc.upperRotationOffsetBackup = jointDesc.upperRotationOffset
        jointDesc.lowerRotationOffsetBackup = jointDesc.lowerRotationOffset
        self.spec_attacherJointControl.jointDesc = jointDesc
        for _, control in ipairs(spec.controls) do
            control.moveAlpha = control.func(self)
        end
        if loadFromSavegame then
            if spec.heightController ~= nil then
                self:controlAttacherJoint(spec.heightController, spec.jointDesc.upperAlpha, false)
            end
        else
            spec.heightTargetAlpha = spec.jointDesc.upperAlpha
        end
        self:requestActionEventUpdate()
    end
end
function AttacherJointControl:onPreDetach(_, _)
    local spec = self.spec_attacherJointControl
    if spec.jointDesc ~= nil then
        spec.jointDesc.allowsLowering = spec.jointDesc.allowsLoweringBackup
        spec.jointDesc.upperRotationOffset = spec.jointDesc.upperRotationOffsetBackup
        spec.jointDesc.lowerRotationOffset = spec.jointDesc.lowerRotationOffsetBackup
        spec.jointDesc = nil
    end
end
function AttacherJointControl:actionEventAttacherJointControl(actionName, inputValue, _, _)
    if math.abs(inputValue) > 0 then
        local spec = self.spec_attacherJointControl
        local control = spec.nameToControl[actionName]
        local changedAlpha = inputValue * control.mouseSpeedFactor * 0.025
        if control.invertAxis then
        end
        self:controlAttacherJoint(control, control.moveAlpha + changedAlpha, false)
        spec.heightTargetAlpha = -1
    end
end
function AttacherJointControl:actionEventAttacherJointControlSetPoint(_, _, _, _)
    local spec = self.spec_attacherJointControl
    if spec.jointDesc ~= nil then
        if self:getControlAttacherJointDirection() then
            spec.heightTargetAlpha = spec.jointDesc.lowerAlpha
        else
            spec.heightTargetAlpha = spec.jointDesc.upperAlpha
        end
        spec.nextHeightDampingUpdateTime = g_time + spec.jointDesc.moveTime
    end
end