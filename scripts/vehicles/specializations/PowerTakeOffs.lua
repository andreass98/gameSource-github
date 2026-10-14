PowerTakeOffs = {}
PowerTakeOffs.DEFAULT_MAX_UPDATE_DISTANCE = 40
PowerTakeOffs.xmlSchema = nil
function PowerTakeOffs.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AttacherJoints, specializations) or SpecializationUtil.hasSpecialization(Attachable, specializations)
end
function PowerTakeOffs.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("PowerTakeOffs")
    PowerTakeOffs.registerXMLPaths(schema, "vehicle.powerTakeOffs.powerTakeOffConfigurations.powerTakeOffConfiguration(?)")
    PowerTakeOffs.registerXMLPaths(schema, "vehicle.powerTakeOffs")
    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".powerTakeOffs#indices", "PTOs to update")
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".powerTakeOffs#localIndices", "Local PTOs to update")
    end)
    schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".powerTakeOffs#indices", "PTOs to update")
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".powerTakeOffs#localIndices", "Local PTOs to update")
    end)
    schema:register(XMLValueType.BOOL, "vehicle.powerTakeOffs#ignoreInvalidJointIndices", "Do not display warning if attacher joint index could not be found. Can be useful if attacher joints change due to configurations", false)
    schema:register(XMLValueType.FLOAT, "vehicle.powerTakeOffs#maxUpdateDistance", "Max. distance to vehicle root to update power take offs", PowerTakeOffs.DEFAULT_MAX_UPDATE_DISTANCE)
    Dashboard.addDelayedRegistrationFunc(schema, function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. "#powerTakeOffIndex", "Index of power take off in xml to use")
    end)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.powerTakeOffs.sounds", "turnedOn(?)")
    schema:setXMLSpecializationType()
    local powerTakeOffXMLSchema = XMLSchema.new("powerTakeOff")
    PowerTakeOffs.xmlSchema = powerTakeOffXMLSchema
    powerTakeOffXMLSchema:register(XMLValueType.STRING, "powerTakeOff#filename", "Path to i3d file")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.startNode#node", "Start node")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.linkNode#node", "Link node")
    powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff#size", "Height of pto", 0.19)
    powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff#minLength", "Minimum length of pto", 0.6)
    powerTakeOffXMLSchema:register(XMLValueType.ANGLE, "powerTakeOff#maxAngle", "Max. angle between start and end", 45)
    powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff#zOffset", "Z axis offset of end node", 0)
    powerTakeOffXMLSchema:register(XMLValueType.STRING, "powerTakeOff#colorMaterialName", "Color material name", "powerTakeOff_main_mat")
    powerTakeOffXMLSchema:register(XMLValueType.STRING, "powerTakeOff#decalColorMaterialName", "Decal color material name", "powerTakeOff_decal_mat")
    AnimationManager.registerAnimationNodesXMLPaths(powerTakeOffXMLSchema, "powerTakeOff.animationNodes")
    powerTakeOffXMLSchema:register(XMLValueType.BOOL, "powerTakeOff#isSingleJoint", "Is single joint PTO", false)
    powerTakeOffXMLSchema:register(XMLValueType.BOOL, "powerTakeOff#isDoubleJoint", "Is double joint PTO", false)
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.startJoint#node", "(Single Joint) Start joint node")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint#node", "(Single Joint) End joint node")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.scalePart#node", "(Single|Double Joint) Scale part node")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.scalePart#referenceNode", "(Single|Double Joint) Scale part reference node")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.translationPart#node", "(Single|Double Joint) translation part node")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.translationPart#referenceNode", "(Single|Double Joint) translation part reference node")
    powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff.translationPart#length", "(Single|Double Joint) translation part length", 0.4)
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.translationPart.decal#node", "(Single|Double Joint) translation part decal node")
    powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff.translationPart.decal#size", "(Single|Double Joint) translation part decal size", 0.1)
    powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff.translationPart.decal#offset", "(Single|Double Joint) translation part decal offset", 0.05)
    powerTakeOffXMLSchema:register(XMLValueType.FLOAT, "powerTakeOff.translationPart.decal#minOffset", "(Single|Double Joint) translation part decal minOffset", 0.01)
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.startJoint1#node", "(Double Joint) Start joint 1")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.startJoint2#node", "(Double Joint) Start joint 2")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint1#node", "(Double Joint) End joint 1")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint1#referenceNode", "(Double Joint) End joint 1 reference node")
    powerTakeOffXMLSchema:register(XMLValueType.NODE_INDEX, "powerTakeOff.endJoint2#node", "(Double Joint) End joint 2")
    I3DUtil.registerI3dMappingXMLPaths(powerTakeOffXMLSchema, "powerTakeOff")
end
function PowerTakeOffs.registerXMLPaths(schema, basePath)
    PowerTakeOffs.registerOutputXMLPaths(schema, basePath .. ".output(?)")
    PowerTakeOffs.registerInputXMLPaths(schema, basePath .. ".input(?)")
    PowerTakeOffs.registerLocalXMLPaths(schema, basePath .. ".local(?)")
end
function PowerTakeOffs.registerOutputXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#skipToInputAttacherIndex", "Skip to input attacher joint index")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#outputNode", "Output node")
    schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "Corresponding attacher joint(s) (List of indices)")
    schema:register(XMLValueType.NODE_INDICES, basePath .. "#attacherJointNodes", "Corresponding attacher joint(s) (List of attacherJoint nodes)")
    schema:register(XMLValueType.STRING, basePath .. "#ptoName", "Output name", "DEFAULT_PTO")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
    Dashboard.registerDashboardXMLPaths(schema, basePath, { "state" })
end
function PowerTakeOffs.registerInputXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#inputNode", "Input node")
    schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "Corresponding Input attacher joint(s) (List of indices)")
    schema:register(XMLValueType.NODE_INDICES, basePath .. "#inputAttacherJointNodes", "Corresponding Input attacher joint(s) (List of attacherJoint nodes)")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#detachNode", "Detach node")
    schema:register(XMLValueType.BOOL, basePath .. "#aboveAttacher", "Above attacher", true)
    schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#materialTemplateName", "Name of shared material to apply to the main pto")
    schema:registerAutoCompletionDataSource(basePath .. "#materialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
    schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#decalMaterialTemplateName", "Name of shared material to apply to the decals")
    schema:registerAutoCompletionDataSource(basePath .. "#decalMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
    schema:register(XMLValueType.FLOAT, basePath .. "#length", "Predefined length of the PTO (Otherwise calculated from the distance between startNode and endNode, while loading. Can be useful if the tool is loaded in different states to always get the same length.)")
    schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to pto xml file", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")
    schema:register(XMLValueType.STRING, basePath .. "#ptoName", "Pto name", "DEFAULT_PTO")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end
function PowerTakeOffs.registerLocalXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#startNode", "Start node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#endNode", "End node")
    schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#materialTemplateName", "Name of shared material to apply to the main pto")
    schema:registerAutoCompletionDataSource(basePath .. "#materialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
    schema:register(XMLValueType.VEHICLE_MATERIAL, basePath .. "#decalMaterialTemplateName", "Name of shared material to apply to the decals")
    schema:registerAutoCompletionDataSource(basePath .. "#decalMaterialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
    schema:register(XMLValueType.FLOAT, basePath .. "#length", "Predefined length of the PTO (Otherwise calculated from the distance between startNode and endNode, while loading. Can be useful if the tool is loaded in different states to always get the same length.)")
    schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to pto xml file", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")
end
function PowerTakeOffs.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getPowerTakeOffConfigIndex", PowerTakeOffs.getPowerTakeOffConfigIndex)
    SpecializationUtil.registerFunction(vehicleType, "loadPowerTakeOffsFromXML", PowerTakeOffs.loadPowerTakeOffsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadOutputPowerTakeOff", PowerTakeOffs.loadOutputPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "loadInputPowerTakeOff", PowerTakeOffs.loadInputPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "loadLocalPowerTakeOff", PowerTakeOffs.loadLocalPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "placeLocalPowerTakeOff", PowerTakeOffs.placeLocalPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "updatePowerTakeOff", PowerTakeOffs.updatePowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "updateAttachedPowerTakeOffs", PowerTakeOffs.updateAttachedPowerTakeOffs)
    SpecializationUtil.registerFunction(vehicleType, "updatePowerTakeOffLength", PowerTakeOffs.updatePowerTakeOffLength)
    SpecializationUtil.registerFunction(vehicleType, "getOutputPowerTakeOffsByJointDescIndex", PowerTakeOffs.getOutputPowerTakeOffsByJointDescIndex)
    SpecializationUtil.registerFunction(vehicleType, "getOutputPowerTakeOffs", PowerTakeOffs.getOutputPowerTakeOffs)
    SpecializationUtil.registerFunction(vehicleType, "getInputPowerTakeOffs", PowerTakeOffs.getInputPowerTakeOffs)
    SpecializationUtil.registerFunction(vehicleType, "getInputPowerTakeOffsByJointDescIndexAndName", PowerTakeOffs.getInputPowerTakeOffsByJointDescIndexAndName)
    SpecializationUtil.registerFunction(vehicleType, "getIsPowerTakeOffActive", PowerTakeOffs.getIsPowerTakeOffActive)
    SpecializationUtil.registerFunction(vehicleType, "attachPowerTakeOff", PowerTakeOffs.attachPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "detachPowerTakeOff", PowerTakeOffs.detachPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "checkPowerTakeOffCollision", PowerTakeOffs.checkPowerTakeOffCollision)
    SpecializationUtil.registerFunction(vehicleType, "parkPowerTakeOff", PowerTakeOffs.parkPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "loadPowerTakeOffFromConfigFile", PowerTakeOffs.loadPowerTakeOffFromConfigFile)
    SpecializationUtil.registerFunction(vehicleType, "onPowerTakeOffI3DLoaded", PowerTakeOffs.onPowerTakeOffI3DLoaded)
    SpecializationUtil.registerFunction(vehicleType, "loadSingleJointPowerTakeOff", PowerTakeOffs.loadSingleJointPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "updateSingleJointPowerTakeOff", PowerTakeOffs.updateSingleJointPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "loadDoubleJointPowerTakeOff", PowerTakeOffs.loadDoubleJointPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "updateDoubleJointPowerTakeOff", PowerTakeOffs.updateDoubleJointPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "loadBasicPowerTakeOff", PowerTakeOffs.loadBasicPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "attachTypedPowerTakeOff", PowerTakeOffs.attachTypedPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "detachTypedPowerTakeOff", PowerTakeOffs.detachTypedPowerTakeOff)
    SpecializationUtil.registerFunction(vehicleType, "validatePowerTakeOffAttachment", PowerTakeOffs.validatePowerTakeOffAttachment)
end
function PowerTakeOffs.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", PowerTakeOffs.loadExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", PowerTakeOffs.updateExtraDependentParts)
end
function PowerTakeOffs.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", PowerTakeOffs)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", PowerTakeOffs)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", PowerTakeOffs)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", PowerTakeOffs)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", PowerTakeOffs)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", PowerTakeOffs)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", PowerTakeOffs)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", PowerTakeOffs)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", PowerTakeOffs)
end
function PowerTakeOffs:onPreLoad(_)
    self.spec_powerTakeOffs.configIndex = self:getPowerTakeOffConfigIndex()
end
function PowerTakeOffs:onLoad(_)
    local spec = self.spec_powerTakeOffs
    spec.outputPowerTakeOffs = {}
    spec.inputPowerTakeOffs = {}
    spec.localPowerTakeOffs = {}
    spec.ignoreInvalidJointIndices = self.xmlFile:getValue("vehicle.powerTakeOffs#ignoreInvalidJointIndices", false)
    spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.powerTakeOffs#maxUpdateDistance", PowerTakeOffs.DEFAULT_MAX_UPDATE_DISTANCE)
    spec.delayedPowerTakeOffsMountings = {}
    if self.isClient then
        spec.samples = {}
        spec.samples.turnedOn = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.powerTakeOffs.sounds", "turnedOn", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    else
        SpecializationUtil.removeEventListener(self, "onUpdateInterpolation", PowerTakeOffs)
    end
end
function PowerTakeOffs:onPostLoad(_)
    self:loadPowerTakeOffsFromXML(self.xmlFile, "vehicle.powerTakeOffs")
    local configKey = string.format("vehicle.powerTakeOffs.powerTakeOffConfigurations.powerTakeOffConfiguration(%d)", self.spec_powerTakeOffs.configIndex - 1)
    if self.xmlFile:hasProperty(configKey) then
        self:loadPowerTakeOffsFromXML(self.xmlFile, configKey)
    end
end
function PowerTakeOffs:onDelete()
    local spec = self.spec_powerTakeOffs
    if spec.outputPowerTakeOffs ~= nil then
        for _, output in pairs(spec.outputPowerTakeOffs) do
            if output.xmlFile ~= nil then
                output.xmlFile:delete()
                output.xmlFile = nil
            end
            if output.sharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(output.sharedLoadRequestId)
                output.sharedLoadRequestId = nil
            end
            g_animationManager:deleteAnimations(output.localAnimationNodes)
            if output.rootNode ~= nil then
                delete(output.rootNode)
                delete(output.attachNode)
            end
        end
    end
    if spec.inputPowerTakeOffs ~= nil then
        for _, output in pairs(spec.inputPowerTakeOffs) do
            if output.xmlFile ~= nil then
                output.xmlFile:delete()
                output.xmlFile = nil
            end
            if output.sharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(output.sharedLoadRequestId)
                output.sharedLoadRequestId = nil
            end
            g_animationManager:deleteAnimations(output.animationNodes)
            g_animationManager:deleteAnimations(output.localAnimationNodes)
            if output.rootNode ~= nil then
                delete(output.rootNode)
                delete(output.attachNode)
            end
        end
    end
    if spec.localPowerTakeOffs ~= nil then
        for _, output in pairs(spec.localPowerTakeOffs) do
            if output.xmlFile ~= nil then
                output.xmlFile:delete()
                output.xmlFile = nil
            end
            if output.sharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(output.sharedLoadRequestId)
                output.sharedLoadRequestId = nil
            end
            g_animationManager:deleteAnimations(output.animationNodes)
        end
    end
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples.turnedOn)
    end
end
function PowerTakeOffs:onUpdateInterpolation(dt, _, _, _)
    if self.isClient then
        local spec = self.spec_powerTakeOffs
        if self.currentUpdateDistance < spec.maxUpdateDistance then
            local i = 1
            local impements = #spec.inputPowerTakeOffs
            for i = i, impements do
                local input = spec.inputPowerTakeOffs[i]
                if input.connectedVehicle ~= nil and self.updateLoopIndex == input.connectedVehicle.updateLoopIndex then
                    self:updatePowerTakeOff(input, dt)
                end
            end
            if self.getAttachedImplements ~= nil then
                local impements = self:getAttachedImplements()
                local input = 1
                for input = input, #impements do
                    local object = impements[input].object
                    if object.updateAttachedPowerTakeOffs ~= nil then
                        object:updateAttachedPowerTakeOffs(dt, self)
                    end
                end
            end
            local impements = self.isActive
            if impements then
                impements = self:getIsPowerTakeOffActive()
            end
            if spec.lastIsPowerTakeOffActive ~= impements then
                local input = 1
                for input = input, #spec.inputPowerTakeOffs do
                    local object = spec.inputPowerTakeOffs[input]
                    if impements and object.connectedVehicle ~= nil then
                        g_animationManager:startAnimations(object.animationNodes)
                        g_animationManager:startAnimations(object.localAnimationNodes)
                        g_animationManager:startAnimations(object.connectedOutput.localAnimationNodes)
                        object.connectedOutput.isActive = true
                        if object.connectedVehicle.updateDashboardValueType ~= nil then
                            object.connectedVehicle:updateDashboardValueType("powerTakeOffs.state")
                        end
                    else
                        g_animationManager:stopAnimations(object.animationNodes)
                        g_animationManager:stopAnimations(object.localAnimationNodes)
                        if object.connectedOutput ~= nil then
                            g_animationManager:stopAnimations(object.connectedOutput.localAnimationNodes)
                            object.connectedOutput.isActive = false
                            if object.connectedVehicle.updateDashboardValueType ~= nil then
                                object.connectedVehicle:updateDashboardValueType("powerTakeOffs.state")
                            end
                        end
                    end
                end
                local input = 1
                for input = input, #spec.localPowerTakeOffs do
                    if impements then
                        g_animationManager:startAnimations(spec.localPowerTakeOffs[input].animationNodes)
                    else
                        g_animationManager:stopAnimations(object.animationNodes)
                    end
                end
                if impements then
                    g_soundManager:playSamples(spec.samples.turnedOn)
                else
                    g_soundManager:stopSamples(spec.samples.turnedOn)
                end
                spec.lastIsPowerTakeOffActive = impements
            end
        end
    end
end
function PowerTakeOffs:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    PowerTakeOffs.onUpdateInterpolation(self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end
function PowerTakeOffs:getPowerTakeOffConfigIndex()
    return 1
end
function PowerTakeOffs:loadPowerTakeOffsFromXML(xmlFile, key)
    local spec = self.spec_powerTakeOffs
    if SpecializationUtil.hasSpecialization(AttacherJoints, self.specializations) then
        xmlFile:iterate(key .. ".output", function(_, outputKey)
            -- upvalues: (copy) self, (copy) xmlFile, (copy) spec
            local powerTakeOffOutput = {}
            if self:loadOutputPowerTakeOff(xmlFile, outputKey, powerTakeOffOutput) then
                table.insert(spec.outputPowerTakeOffs, powerTakeOffOutput)
            end
        end)
    end
    if SpecializationUtil.hasSpecialization(Attachable, self.specializations) then
        xmlFile:iterate(key .. ".input", function(_, inputKey)
            -- upvalues: (copy) self, (copy) xmlFile, (copy) spec
            local powerTakeOffInput = {}
            if self:loadInputPowerTakeOff(xmlFile, inputKey, powerTakeOffInput) then
                table.insert(spec.inputPowerTakeOffs, powerTakeOffInput)
            end
        end)
    end
    xmlFile:iterate(key .. ".local", function(_, localKey)
        -- upvalues: (copy) self, (copy) xmlFile, (copy) spec
        local powerTakeOffLocal = {}
        if self:loadLocalPowerTakeOff(xmlFile, localKey, powerTakeOffLocal) then
            table.insert(spec.localPowerTakeOffs, powerTakeOffLocal)
        end
    end)
end
function PowerTakeOffs:loadOutputPowerTakeOff(xmlFile, baseName, powerTakeOffOutput)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#linkNode", baseName .. "#outputNode")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#filename", "pto file is now defined in the pto input node")
    powerTakeOffOutput.skipToInputAttacherIndex = xmlFile:getValue(baseName .. "#skipToInputAttacherIndex")
    local outputNode = xmlFile:getValue(baseName .. "#outputNode", nil, self.components, self.i3dMappings)
    if outputNode == nil and powerTakeOffOutput.skipToInputAttacherIndex == nil then
        Logging.xmlWarning(xmlFile, "Pto output needs to have either a valid \'outputNode\' or a \'skipToInputAttacherIndex\' in \'%s\'", baseName)
        return false
    end
    local attacherJointIndices = {}
    local attacherJointIndicesRaw = xmlFile:getValue(baseName .. "#attacherJointIndices", nil, true)
    if attacherJointIndicesRaw ~= nil then
        for _, attacherJointIndex in ipairs(attacherJointIndicesRaw) do
            if self:getAttacherJointByJointDescIndex(attacherJointIndex) == nil then
                if not self.spec_powerTakeOffs.ignoreInvalidJointIndices then
                    Logging.xmlWarning(self.xmlFile, "The given attacherJointIndex \'%d\' for powerTakeOff can\'t be resolved into a valid attacherJoint in %s", attacherJointIndex, baseName)
                end
            else
                attacherJointIndices[attacherJointIndex] = true
            end
        end
    end
    local attacherJointNodesRaw = xmlFile:getValue(baseName .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
    if attacherJointNodesRaw ~= nil then
        for attacherJointIndex, node in ipairs(attacherJointNodesRaw) do
            local attacherJointIndex = self:getAttacherJointIndexByNode(node)
            if attacherJointIndex ~= nil then
                attacherJointIndices[attacherJointIndex] = true
            end
        end
    end
    if next(attacherJointIndices) == nil then
        return false
    end
    powerTakeOffOutput.outputNode = outputNode
    powerTakeOffOutput.attacherJointIndices = attacherJointIndices
    powerTakeOffOutput.connectedInput = nil
    powerTakeOffOutput.ptoName = xmlFile:getValue(baseName .. "#ptoName", "DEFAULT_PTO")
    powerTakeOffOutput.localAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseName .. ".animationNodes", self.components, self, self.i3dMappings)
    powerTakeOffOutput.objectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, baseName, powerTakeOffOutput.objectChanges, self.components, self)
    ObjectChangeUtil.setObjectChanges(powerTakeOffOutput.objectChanges, false, self, self.setMovingToolDirty)
    powerTakeOffOutput.isActive = false
    if self.registerDashboardValueType ~= nil then
        local state = DashboardValueType.new("powerTakeOffs", "state")
        state:setXMLKey(baseName)
        state:setValue(powerTakeOffOutput, function(_powerTakeOffOutput, dashboard)
            return (dashboard.powerTakeOffOutput or _powerTakeOffOutput).isActive
        end)
        state:setAdditionalFunctions(function(self, xmlFile, key, dashboard, _)
            local powerTakeOffIndex = xmlFile:getValue(key .. "#powerTakeOffIndex")
            if powerTakeOffIndex ~= nil then
                dashboard.powerTakeOffOutput = self.spec_powerTakeOffs.outputPowerTakeOffs[powerTakeOffIndex]
            end
            return true
        end, nil)
        state:setPollUpdate(false)
        self:registerDashboardValueType(state)
    end
    return true
end
function PowerTakeOffs:loadInputPowerTakeOff(xmlFile, baseName, powerTakeOffInput)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#color", baseName .. "#materialTemplateName")
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#decalColor", baseName .. "#decalMaterialTemplateName")
    local inputNode = xmlFile:getValue(baseName .. "#inputNode", nil, self.components, self.i3dMappings)
    if inputNode == nil then
        Logging.xmlWarning(xmlFile, "Pto input needs to have a valid \'inputNode\' in \'%s\'", baseName)
        return false
    end
    local inputAttacherJointIndices = {}
    local inputAttacherJointIndicesRaw = xmlFile:getValue(baseName .. "#inputAttacherJointIndices", nil, true)
    if inputAttacherJointIndicesRaw ~= nil then
        for _, inputAttacherJointIndex in ipairs(inputAttacherJointIndicesRaw) do
            if self:getInputAttacherJointByJointDescIndex(inputAttacherJointIndex) == nil then
                if not self.spec_powerTakeOffs.ignoreInvalidJointIndices then
                    Logging.xmlWarning(self.xmlFile, "The given inputAttacherJointIndex \'%d\' for powerTakeOff can\'t be resolved into a valid attacherJoint in %s", inputAttacherJointIndex, baseName)
                end
            else
                inputAttacherJointIndices[inputAttacherJointIndex] = true
            end
        end
    end
    local inputAttacherJointNodesRaw = xmlFile:getValue(baseName .. "#inputAttacherJointNodes", nil, self.components, self.i3dMappings, true)
    if inputAttacherJointNodesRaw ~= nil then
        for inputAttacherJointIndex, node in ipairs(inputAttacherJointNodesRaw) do
            local inputAttacherJointIndex = self:getInputAttacherJointIndexByNode(node)
            if inputAttacherJointIndex ~= nil then
                inputAttacherJointIndices[inputAttacherJointIndex] = true
            end
        end
    end
    if next(inputAttacherJointIndices) == nil then
        Logging.xmlWarning(xmlFile, "Pto output needs to have valid \'inputAttacherJointIndices\' or \'inputAttacherJointNodes\' in \'%s\'", baseName)
        return false
    end
    powerTakeOffInput.inputNode = inputNode
    if Platform.gameplay.hasDetachedPowerTakeOffs then
        powerTakeOffInput.detachNode = xmlFile:getValue(baseName .. "#detachNode", nil, self.components, self.i3dMappings)
    end
    powerTakeOffInput.inputAttacherJointIndices = inputAttacherJointIndices
    powerTakeOffInput.aboveAttacher = xmlFile:getValue(baseName .. "#aboveAttacher", true)
    powerTakeOffInput.material = xmlFile:getValue(baseName .. "#materialTemplateName", nil, self.customEnvironment)
    powerTakeOffInput.decalMaterial = xmlFile:getValue(baseName .. "#decalMaterialTemplateName", nil, self.customEnvironment)
    powerTakeOffInput.ptoName = xmlFile:getValue(baseName .. "#ptoName", "DEFAULT_PTO")
    powerTakeOffInput.localAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseName .. ".animationNodes", self.components, self, self.i3dMappings)
    powerTakeOffInput.objectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, baseName, powerTakeOffInput.objectChanges, self.components, self)
    ObjectChangeUtil.setObjectChanges(powerTakeOffInput.objectChanges, false, self, self.setMovingToolDirty)
    local filename = xmlFile:getValue(baseName .. "#filename", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")
    if filename ~= nil then
        self:loadPowerTakeOffFromConfigFile(powerTakeOffInput, filename)
    end
    return true
end
function PowerTakeOffs:loadLocalPowerTakeOff(xmlFile, baseName, powerTakeOffLocal)
    powerTakeOffLocal.isLocal = true
    powerTakeOffLocal.inputNode = xmlFile:getValue(baseName .. "#startNode", nil, self.components, self.i3dMappings)
    if powerTakeOffLocal.inputNode == nil then
        Logging.xmlWarning(xmlFile, "Missing startNode for local power take off \'%s\'", baseName)
        return false
    end
    powerTakeOffLocal.endNode = xmlFile:getValue(baseName .. "#endNode", nil, self.components, self.i3dMappings)
    if powerTakeOffLocal.endNode == nil then
        Logging.xmlWarning(xmlFile, "Missing endNode for local power take off \'%s\'", baseName)
        return false
    end
    powerTakeOffLocal.material = xmlFile:getValue(baseName .. "#materialTemplateName", nil, self.customEnvironment)
    powerTakeOffLocal.decalMaterial = xmlFile:getValue(baseName .. "#decalMaterialTemplateName", nil, self.customEnvironment)
    powerTakeOffLocal.predefinedLength = xmlFile:getValue(baseName .. "#length")
    local filename = xmlFile:getValue(baseName .. "#filename", "$data/shared/assets/powerTakeOffs/walterscheidW.xml")
    if filename ~= nil then
        self:loadPowerTakeOffFromConfigFile(powerTakeOffLocal, filename)
    end
    return true
end
function PowerTakeOffs:placeLocalPowerTakeOff(powerTakeOff)
    if powerTakeOff.i3dLoaded then
        if not powerTakeOff.isPlaced then
            link(powerTakeOff.endNode, powerTakeOff.linkNode)
            setTranslation(powerTakeOff.linkNode, 0, 0, powerTakeOff.zOffset)
            setTranslation(powerTakeOff.startNode, 0, 0, -powerTakeOff.zOffset)
            self:updatePowerTakeOffLength(powerTakeOff)
            powerTakeOff.isPlaced = true
        end
        self:updatePowerTakeOff(powerTakeOff, 0)
    end
end
function PowerTakeOffs:updatePowerTakeOff(input, dt)
    if input.i3dLoaded and (input.isLinked or input.isPlaced) and input.updateFunc ~= nil then
        input.updateFunc(self, input, dt)
    end
end
function PowerTakeOffs:updateAttachedPowerTakeOffs(dt, attacherVehicle)
    for _, input in pairs(self.spec_powerTakeOffs.inputPowerTakeOffs) do
        if input.connectedVehicle ~= nil and (input.connectedVehicle == attacherVehicle and self.updateLoopIndex == input.connectedVehicle.updateLoopIndex) then
            self:updatePowerTakeOff(input, dt)
        end
    end
end
function PowerTakeOffs:updatePowerTakeOffLength(input)
    if input.i3dLoaded and input.updateDistanceFunc ~= nil then
        input.updateDistanceFunc(self, input)
    end
end
function PowerTakeOffs:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)
    local retOutputs = {}
    for _, output in pairs(self.spec_powerTakeOffs.outputPowerTakeOffs) do
        if output.attacherJointIndices[jointDescIndex] ~= nil then
            table.insert(retOutputs, output)
        end
    end
    if #retOutputs > 0 then
        for _, output in ipairs(retOutputs) do
            if output.skipToInputAttacherIndex ~= nil then
                local secondAttacherVehicle = self:getAttacherVehicle()
                if secondAttacherVehicle ~= nil then
                    return secondAttacherVehicle:getOutputPowerTakeOffsByJointDescIndex(secondAttacherVehicle:getImplementByObject(self).jointDescIndex)
                end
            end
        end
    end
    return retOutputs
end
function PowerTakeOffs:getOutputPowerTakeOffs()
    return self.spec_powerTakeOffs.outputPowerTakeOffs
end
function PowerTakeOffs:getInputPowerTakeOffsByJointDescIndexAndName(jointDescIndex, ptoName)
    local retInputs = {}
    local spec = self.spec_powerTakeOffs
    for _, input in pairs(spec.inputPowerTakeOffs) do
        if input.inputAttacherJointIndices[jointDescIndex] ~= nil and input.ptoName == ptoName then
            table.insert(retInputs, input)
        end
    end
    if #retInputs == 0 then
        for _, input in pairs(spec.outputPowerTakeOffs) do
            if input.skipToInputAttacherIndex == jointDescIndex then
                for index, _ in pairs(input.attacherJointIndices) do
                    local implement = self:getImplementFromAttacherJointIndex(index)
                    if implement ~= nil then
                        retInputs = implement.object:getInputPowerTakeOffsByJointDescIndexAndName(implement.inputJointDescIndex, ptoName)
                    end
                end
            end
        end
    end
    return retInputs
end
function PowerTakeOffs:getInputPowerTakeOffs()
    return self.spec_powerTakeOffs.inputPowerTakeOffs
end
function PowerTakeOffs:getIsPowerTakeOffActive()
    return false
end
function PowerTakeOffs:attachPowerTakeOff(attachableObject, inputJointDescIndex, jointDescIndex)
    local outputs = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)
    for _, output in ipairs(outputs) do
        if attachableObject.getInputPowerTakeOffsByJointDescIndexAndName ~= nil then
            local inputs = attachableObject:getInputPowerTakeOffsByJointDescIndexAndName(inputJointDescIndex, output.ptoName)
            for _, input in ipairs(inputs) do
                output.connectedInput = input
                output.connectedVehicle = attachableObject
                input.connectedVehicle = self
                input.connectedOutput = output
                table.insert(self.spec_powerTakeOffs.delayedPowerTakeOffsMountings, {
                    ["jointDescIndex"] = jointDescIndex,
                    ["input"] = input,
                    ["output"] = output
                })
            end
        end
    end
    return true
end
function PowerTakeOffs:detachPowerTakeOff(detachingVehicle, implement, jointDescIndex)
    self.spec_powerTakeOffs.delayedPowerTakeOffsMountings = {}
    local outputs = detachingVehicle:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex or implement.jointDescIndex)
    for _, output in ipairs(outputs) do
        if output.connectedInput ~= nil then
            local input = output.connectedInput
            if input.detachFunc ~= nil then
                input.detachFunc(self, input, output)
            end
            if input.connectedOutput ~= nil then
                g_animationManager:stopAnimations(input.connectedOutput.localAnimationNodes)
                input.connectedOutput.isActive = false
                if input.connectedVehicle.updateDashboardValueType ~= nil then
                    input.connectedVehicle:updateDashboardValueType("powerTakeOffs.state")
                end
            end
            input.connectedVehicle = nil
            input.connectedOutput = nil
            output.connectedVehicle = nil
            output.connectedInput = nil
            ObjectChangeUtil.setObjectChanges(input.objectChanges, false, self, self.setMovingToolDirty)
            ObjectChangeUtil.setObjectChanges(output.objectChanges, false, self, self.setMovingToolDirty)
        end
    end
    return true
end
function PowerTakeOffs:checkPowerTakeOffCollision(attacherJointNode, jointDescIndex, isTrailerAttacher)
    if isTrailerAttacher then
        local ptoOutputs = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)
        if ptoOutputs ~= nil and #ptoOutputs > 0 then
            local ptoOutput = ptoOutputs[1]
            local ptoInput = ptoOutput.connectedInput
            if ptoInput ~= nil then
                local _, y, _ = localToLocal(ptoOutput.outputNode, attacherJointNode, 0, 0, 0)
                if ptoInput.aboveAttacher and y < 0 or not ptoInput.aboveAttacher and y > 0 then
                    self:detachPowerTakeOff(self, nil, jointDescIndex)
                end
            end
        end
    end
end
function PowerTakeOffs:parkPowerTakeOff(input)
    if input.detachNode == nil then
        link(input.inputNode, input.linkNode)
        link(input.inputNode, input.startNode)
        setVisibility(input.linkNode, false)
        setVisibility(input.startNode, false)
        input.isLinked = false
    else
        link(input.detachNode, input.linkNode)
        link(input.inputNode, input.startNode)
        self:updatePowerTakeOff(input, 0)
        self:updatePowerTakeOffLength(input)
        input.isLinked = true
    end
    setTranslation(input.linkNode, 0, 0, input.zOffset)
    setTranslation(input.startNode, 0, 0, -input.zOffset)
end
function PowerTakeOffs:onPreAttachImplement(attachableObject, inputJointDescIndex, jointDescIndex, _)
    self:attachPowerTakeOff(attachableObject, inputJointDescIndex, jointDescIndex)
end
function PowerTakeOffs:onPostAttachImplement(_, _, jointDescIndex, _)
    local spec = self.spec_powerTakeOffs
    local i = #spec.delayedPowerTakeOffsMountings
    for i = i, 1, -1 do
        local delayedMounting = spec.delayedPowerTakeOffsMountings[i]
        if delayedMounting.jointDescIndex == jointDescIndex then
            local input = delayedMounting.input
            local output = delayedMounting.output
            if input.attachFunc ~= nil then
                input.attachFunc(self, input, output)
            end
            ObjectChangeUtil.setObjectChanges(input.objectChanges, true, self, self.setMovingToolDirty)
            ObjectChangeUtil.setObjectChanges(output.objectChanges, true, self, self.setMovingToolDirty)
            table.remove(spec.delayedPowerTakeOffsMountings, i)
        end
    end
end
function PowerTakeOffs:onPreDetachImplement(implement)
    self:detachPowerTakeOff(self, implement)
    if self.isClient then
        g_soundManager:stopSamples(self.spec_powerTakeOffs.samples.turnedOn)
    end
end
function PowerTakeOffs:loadPowerTakeOffFromConfigFile(powerTakeOff, xmlFilename)
    local xmlFile = Utils.getFilename(xmlFilename, self.baseDirectory)
    local xmlFile = XMLFile.load("PtoConfig", xmlFile, PowerTakeOffs.xmlSchema)
    if xmlFile == nil then
        Logging.warning("Failed to open powerTakeOff config file \'%s\'", xmlFile)
        return
    else
        local i3dFilename = xmlFile:getValue("powerTakeOff#filename")
        if i3dFilename == nil then
            Logging.xmlWarning(self.xmlFile, "Failed to open powerTakeOff i3d file \'%s\' in \'%s\'", i3dFilename, xmlFile)
            xmlFile:delete()
        else
            local arguments = Utils.getFilename(i3dFilename, self.baseDirectory)
            powerTakeOff.xmlFile = xmlFile
            powerTakeOff.sharedLoadRequestId = self:loadSubSharedI3DFile(arguments, false, false, self.onPowerTakeOffI3DLoaded, self, {
                ["xmlFile"] = xmlFile,
                ["powerTakeOff"] = powerTakeOff
            })
        end
    end
end
function PowerTakeOffs:onPowerTakeOffI3DLoaded(i3dNode, _, args)
    local xmlFile = args.xmlFile
    local powerTakeOff = args.powerTakeOff
    if i3dNode == 0 then
        if not (self.isDeleted or self.isDeleting) then
            Logging.xmlWarning(self.xmlFile, "Failed to find powerTakeOff in file \'%s\'", xmlFile.filename)
        end
    else
        powerTakeOff.components = {}
        powerTakeOff.i3dMappings = {}
        I3DUtil.loadI3DComponents(i3dNode, powerTakeOff.components)
        I3DUtil.loadI3DMapping(xmlFile, "powerTakeOff", powerTakeOff.components, powerTakeOff.i3dMappings)
        powerTakeOff.startNode = xmlFile:getValue("powerTakeOff.startNode#node", nil, powerTakeOff.components, powerTakeOff.i3dMappings)
        if powerTakeOff.startNode == nil then
            Logging.xmlWarning(xmlFile, "Failed to find startNode in powerTakeOff file \'%s\'", xmlFile.filename)
        else
            powerTakeOff.size = xmlFile:getValue("powerTakeOff#size", 0.19)
            powerTakeOff.minLength = xmlFile:getValue("powerTakeOff#minLength", 0.6)
            powerTakeOff.maxAngle = xmlFile:getValue("powerTakeOff#maxAngle", 45)
            powerTakeOff.zOffset = xmlFile:getValue("powerTakeOff#zOffset", 0)
            powerTakeOff.animationNodes = g_animationManager:loadAnimations(xmlFile, "powerTakeOff.animationNodes", powerTakeOff.components, self, powerTakeOff.i3dMappings)
            if powerTakeOff.material ~= nil then
                local materialName = xmlFile:getValue("powerTakeOff#colorMaterialName", "powerTakeOff_main_mat")
                powerTakeOff.material:apply(powerTakeOff.startNode, materialName, true)
            end
            if powerTakeOff.decalMaterial ~= nil then
                local materialName = xmlFile:getValue("powerTakeOff#decalColorMaterialName", "powerTakeOff_decal_mat")
                powerTakeOff.decalMaterial:apply(powerTakeOff.startNode, materialName, true)
            end
            if xmlFile:getValue("powerTakeOff#isSingleJoint") then
                self:loadSingleJointPowerTakeOff(powerTakeOff, xmlFile, powerTakeOff.components, powerTakeOff.i3dMappings)
            elseif xmlFile:getValue("powerTakeOff#isDoubleJoint") then
                self:loadDoubleJointPowerTakeOff(powerTakeOff, xmlFile, powerTakeOff.components, powerTakeOff.i3dMappings)
            else
                self:loadBasicPowerTakeOff(powerTakeOff, xmlFile, powerTakeOff.components, powerTakeOff.i3dMappings)
            end
            link(powerTakeOff.inputNode, powerTakeOff.startNode)
            powerTakeOff.i3dLoaded = true
            if powerTakeOff.isLocal then
                self:placeLocalPowerTakeOff(powerTakeOff)
            else
                self:parkPowerTakeOff(powerTakeOff)
            end
            self:updatePowerTakeOff(powerTakeOff, 0)
        end
        delete(i3dNode)
    end
    xmlFile:delete()
    powerTakeOff.xmlFile = nil
end
function PowerTakeOffs.loadSingleJointPowerTakeOff(_, powerTakeOff, xmlFile, components, i3dMappings)
    powerTakeOff.startJoint = xmlFile:getValue("powerTakeOff.startJoint#node", nil, components, i3dMappings)
    powerTakeOff.scalePart = xmlFile:getValue("powerTakeOff.scalePart#node", nil, components, i3dMappings)
    powerTakeOff.scalePartRef = xmlFile:getValue("powerTakeOff.scalePart#referenceNode", nil, components, i3dMappings)
    local _, _, dis = localToLocal(powerTakeOff.scalePartRef, powerTakeOff.scalePart, 0, 0, 0)
    powerTakeOff.scalePartBaseDistance = dis
    powerTakeOff.translationPart = xmlFile:getValue("powerTakeOff.translationPart#node", nil, components, i3dMappings)
    powerTakeOff.translationPartRef = xmlFile:getValue("powerTakeOff.translationPart#referenceNode", nil, components, i3dMappings)
    powerTakeOff.translationPartLength = xmlFile:getValue("powerTakeOff.translationPart#length", 0.4)
    powerTakeOff.decal = xmlFile:getValue("powerTakeOff.translationPart.decal#node", nil, components, i3dMappings)
    powerTakeOff.decalSize = xmlFile:getValue("powerTakeOff.translationPart.decal#size", 0.1)
    powerTakeOff.decalOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#offset", 0.05)
    powerTakeOff.decalMinOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#minOffset", 0.01)
    powerTakeOff.endJoint = xmlFile:getValue("powerTakeOff.endJoint#node", nil, components, i3dMappings)
    powerTakeOff.linkNode = xmlFile:getValue("powerTakeOff.linkNode#node", nil, components, i3dMappings)
    local _, _, betweenLength = localToLocal(powerTakeOff.translationPart, powerTakeOff.translationPartRef, 0, 0, 0)
    local _, _, ptoLength = localToLocal(powerTakeOff.startNode, powerTakeOff.linkNode, 0, 0, 0)
    powerTakeOff.betweenLength = math.abs(betweenLength)
    powerTakeOff.connectorLength = math.abs(ptoLength) - math.abs(betweenLength)
    setTranslation(powerTakeOff.linkNode, 0, 0, 0)
    setRotation(powerTakeOff.linkNode, 0, 0, 0)
    powerTakeOff.updateFunc = PowerTakeOffs.updateSingleJointPowerTakeOff
    powerTakeOff.updateDistanceFunc = PowerTakeOffs.updateDistanceOfTypedPowerTakeOff
    powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
    powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end
function PowerTakeOffs.updateSingleJointPowerTakeOff(_, powerTakeOff, _)
    local x, y, z = getWorldTranslation(powerTakeOff.linkNode)
    local dx, dy, dz = worldToLocal(powerTakeOff.startNode, x, y, z)
    I3DUtil.setDirection(powerTakeOff.startJoint, dx, dy, dz, 0, 1, 0)
    local dist, dy, dz = worldToLocal(getParent(powerTakeOff.endJoint), x, y, z)
    setTranslation(powerTakeOff.endJoint, 0, 0, MathUtil.vector3Length(dist, dy, dz))
    local dist = calcDistanceFrom(powerTakeOff.scalePart, powerTakeOff.scalePartRef)
    setScale(powerTakeOff.scalePart, 1, 1, dist / powerTakeOff.scalePartBaseDistance)
end
function PowerTakeOffs.loadDoubleJointPowerTakeOff(_, powerTakeOff, xmlFile, components, i3dMappings)
    powerTakeOff.startJoint1 = xmlFile:getValue("powerTakeOff.startJoint1#node", nil, components, i3dMappings)
    powerTakeOff.startJoint2 = xmlFile:getValue("powerTakeOff.startJoint2#node", nil, components, i3dMappings)
    powerTakeOff.scalePart = xmlFile:getValue("powerTakeOff.scalePart#node", nil, components, i3dMappings)
    powerTakeOff.scalePartRef = xmlFile:getValue("powerTakeOff.scalePart#referenceNode", nil, components, i3dMappings)
    local _, _, dis = localToLocal(powerTakeOff.scalePartRef, powerTakeOff.scalePart, 0, 0, 0)
    powerTakeOff.scalePartBaseDistance = dis
    powerTakeOff.translationPart = xmlFile:getValue("powerTakeOff.translationPart#node", nil, components, i3dMappings)
    powerTakeOff.translationPartRef = xmlFile:getValue("powerTakeOff.translationPart#referenceNode", nil, components, i3dMappings)
    powerTakeOff.translationPartLength = xmlFile:getValue("powerTakeOff.translationPart#length", 0.4)
    powerTakeOff.decal = xmlFile:getValue("powerTakeOff.translationPart.decal#node", nil, components, i3dMappings)
    powerTakeOff.decalSize = xmlFile:getValue("powerTakeOff.translationPart.decal#size", 0.1)
    powerTakeOff.decalOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#offset", 0.05)
    powerTakeOff.decalMinOffset = xmlFile:getValue("powerTakeOff.translationPart.decal#minOffset", 0.01)
    powerTakeOff.endJoint1 = xmlFile:getValue("powerTakeOff.endJoint1#node", nil, components, i3dMappings)
    powerTakeOff.endJoint1Ref = xmlFile:getValue("powerTakeOff.endJoint1#referenceNode", nil, components, i3dMappings)
    powerTakeOff.endJoint2 = xmlFile:getValue("powerTakeOff.endJoint2#node", nil, components, i3dMappings)
    powerTakeOff.linkNode = xmlFile:getValue("powerTakeOff.linkNode#node", nil, components, i3dMappings)
    local _, _, betweenLength = localToLocal(powerTakeOff.translationPart, powerTakeOff.translationPartRef, 0, 0, 0)
    local _, _, ptoLength = localToLocal(powerTakeOff.startNode, powerTakeOff.linkNode, 0, 0, 0)
    powerTakeOff.betweenLength = math.abs(betweenLength)
    powerTakeOff.connectorLength = math.abs(ptoLength) - math.abs(betweenLength)
    setTranslation(powerTakeOff.linkNode, 0, 0, 0)
    setRotation(powerTakeOff.linkNode, 0, 0, 0)
    powerTakeOff.updateFunc = PowerTakeOffs.updateDoubleJointPowerTakeOff
    powerTakeOff.updateDistanceFunc = PowerTakeOffs.updateDistanceOfTypedPowerTakeOff
    powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
    powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end
function PowerTakeOffs.updateDoubleJointPowerTakeOff(_, powerTakeOff, _)
    local x, y, z = getWorldTranslation(powerTakeOff.startNode)
    local dx, dy, dz = worldToLocal(getParent(powerTakeOff.endJoint2), x, y, z)
    local dist, dy, dz = MathUtil.vector3Normalize(dx, dy, dz)
    I3DUtil.setDirection(powerTakeOff.endJoint2, dist * 0.5, dy * 0.5, (dz + 1) * 0.5, 0, 1, 0)
    local dist, y, z = getWorldTranslation(powerTakeOff.endJoint1Ref)
    local dist, dy, dz = worldToLocal(getParent(powerTakeOff.startJoint1), dist, y, z)
    local dist, dy, dz = MathUtil.vector3Normalize(dist, dy, dz)
    I3DUtil.setDirection(powerTakeOff.startJoint1, dist * 0.5, dy * 0.5, (dz + 1) * 0.5, 0, 1, 0)
    local dist, y, z = getWorldTranslation(powerTakeOff.endJoint1Ref)
    local dist, dy, dz = worldToLocal(getParent(powerTakeOff.startJoint2), dist, y, z)
    local dist, dy, dz = MathUtil.vector3Normalize(dist, dy, dz)
    I3DUtil.setDirection(powerTakeOff.startJoint2, dist, dy, dz, 0, 1, 0)
    local dist, dy, dz = worldToLocal(getParent(powerTakeOff.endJoint1), dist, y, z)
    setTranslation(powerTakeOff.endJoint1, 0, 0, MathUtil.vector3Length(dist, dy, dz))
    local dist = calcDistanceFrom(powerTakeOff.scalePart, powerTakeOff.scalePartRef)
    setScale(powerTakeOff.scalePart, 1, 1, dist / powerTakeOff.scalePartBaseDistance)
end
function PowerTakeOffs.loadBasicPowerTakeOff(_, powerTakeOff, xmlFile, components, i3dMappings)
    powerTakeOff.startNode = xmlFile:getValue("powerTakeOff.startNode#node", nil, components, i3dMappings)
    powerTakeOff.linkNode = xmlFile:getValue("powerTakeOff.linkNode#node", nil, components, i3dMappings)
    powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
    powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end
function PowerTakeOffs.updateDistanceOfTypedPowerTakeOff(_, powerTakeOff)
    local offset = (powerTakeOff.predefinedLength or calcDistanceFrom(powerTakeOff.linkNode, powerTakeOff.startNode)) - powerTakeOff.connectorLength
    local transPartScale = math.max(offset, 0) / powerTakeOff.betweenLength
    setScale(powerTakeOff.translationPart, 1, 1, transPartScale)
    if powerTakeOff.decal ~= nil then
        local transPartLength = transPartScale * powerTakeOff.translationPartLength
        if powerTakeOff.decalMinOffset * 2 + powerTakeOff.decalSize < transPartLength then
            local x, y, _ = getTranslation(powerTakeOff.decal)
            setTranslation(powerTakeOff.decal, x, y, -(math.min((transPartLength - powerTakeOff.decalSize) / 2, powerTakeOff.decalOffset) + powerTakeOff.decalSize * 0.5) / transPartScale)
            setScale(powerTakeOff.decal, 1, 1, 1 / transPartScale)
            return
        end
        setVisibility(powerTakeOff.decal, false)
    end
end
function PowerTakeOffs:attachTypedPowerTakeOff(powerTakeOff, output)
    if self:validatePowerTakeOffAttachment(powerTakeOff, output) then
        link(output.outputNode, powerTakeOff.linkNode)
        link(powerTakeOff.inputNode, powerTakeOff.startNode)
        setTranslation(powerTakeOff.linkNode, 0, 0, powerTakeOff.zOffset)
        setTranslation(powerTakeOff.startNode, 0, 0, -powerTakeOff.zOffset)
        self:updatePowerTakeOff(powerTakeOff, 0)
        self:updatePowerTakeOffLength(powerTakeOff)
        setVisibility(powerTakeOff.linkNode, true)
        setVisibility(powerTakeOff.startNode, true)
        powerTakeOff.isLinked = true
    end
end
function PowerTakeOffs:detachTypedPowerTakeOff(powerTakeOff, _)
    self:parkPowerTakeOff(powerTakeOff)
end
function PowerTakeOffs.validatePowerTakeOffAttachment(_, powerTakeOff, output)
    if output.outputNode == nil or powerTakeOff.inputNode == nil then
        return false
    end
    local x1, y1, z1 = getWorldTranslation(output.outputNode)
    local x2, y2, z2 = getWorldTranslation(powerTakeOff.inputNode)
    local length = MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2)
    if length < powerTakeOff.minLength then
        return false
    end
    return math.acos(MathUtil.vector2Length(x1 - x2, z1 - z2) / length) <= powerTakeOff.maxAngle
end
function PowerTakeOffs:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
    if not superFunc(self, xmlFile, baseName, entry) then
        return false
    end
    local indices = xmlFile:getValue(baseName .. ".powerTakeOffs#indices", nil, true)
    if indices ~= nil then
        entry.powerTakeOffs = {}
        local i = 1
        for i = i, #indices do
            table.insert(entry.powerTakeOffs, indices[i])
        end
    end
    local localIndices = xmlFile:getValue(baseName .. ".powerTakeOffs#localIndices", nil, true)
    if localIndices ~= nil then
        entry.localPowerTakeOffs = {}
        local i = 1
        local i = 1
        for i = i, #localIndices, i do
            table.insert(entry.localPowerTakeOffs, localIndices[i])
        end
    end
    return true
end
function PowerTakeOffs:updateExtraDependentParts(superFunc, part, dt)
    superFunc(self, part, dt)
    if part.powerTakeOffs ~= nil then
        for i, index in ipairs(part.powerTakeOffs) do
            if self.spec_powerTakeOffs.inputPowerTakeOffs[index] == nil then
                if self.finishedLoading then
                    part.powerTakeOffs[i] = nil
                    Logging.xmlWarning(self.xmlFile, "Unable to find powerTakeOff index \'%d\' for movingPart/movingTool \'%s\'", index, getName(part.node))
                end
            else
                self:updatePowerTakeOff(spec.inputPowerTakeOffs[index], dt)
            end
        end
    end
    if part.localPowerTakeOffs ~= nil then
        for i, index in ipairs(part.localPowerTakeOffs) do
            if self.spec_powerTakeOffs.localPowerTakeOffs[index] == nil then
                if self.finishedLoading then
                    part.localPowerTakeOffs[i] = nil
                    Logging.xmlWarning(self.xmlFile, "Unable to find local powerTakeOff index \'%d\' for movingPart/movingTool \'%s\'", index, getName(part.node))
                end
            else
                self:placeLocalPowerTakeOff(spec.localPowerTakeOffs[index], dt)
            end
        end
    end
end
function PowerTakeOffs.consoleCommandTestConnection(vehicle, attacherJointIndex)
    local spec = vehicle.spec_powerTakeOffs
    if spec ~= nil then
        local lineColor = Color.new(0, 0.5, 1)
        for _, output in pairs(spec.outputPowerTakeOffs) do
            if output.debugLine ~= nil then
                g_debugManager:removeElement(output.debugLine)
                output.debugLine = nil
            end
            if output.debugText ~= nil then
                g_debugManager:removeElement(output.debugText)
                output.debugText = nil
            end
            local i = getNumOfChildren(output.outputNode)
            local node = 1
            local material = -1
            for i = i, node, material do
                delete(getChildAt(output.outputNode, i - 1))
            end
            if output.attacherJointIndices[attacherJointIndex] == nil then
                ObjectChangeUtil.setObjectChanges(output.objectChanges, false, vehicle, vehicle.setMovingToolDirty)
            else
                local node = g_i3DManager:loadI3DFile("data/shared/assets/powerTakeOffs/walterscheidW.i3d", false, false)
                if node ~= 0 then
                    link(output.outputNode, node)
                    setTranslation(node, 0, 0, 0.045)
                    setRotation(node, 0, 3.141592653589793, 0)
                    setVisibility(getChildAt(getChildAt(node, 0), 0), false)
                    local material = VehicleMaterial.new()
                    material.colorScale = {
                        1,
                        0,
                        1,
                        1
                    }
                    material:apply(node)
                end
                ObjectChangeUtil.setObjectChanges(output.objectChanges, true, vehicle, vehicle.setMovingToolDirty)
                local material = vehicle:getAttacherJointByJointDescIndex(attacherJointIndex)
                if material ~= nil then
                    output.debugLine = DebugLine.new():createWithStartAndEndNode(material.jointTransform, output.outputNode, false, true, 100, true)
                    output.debugLine:setColors(lineColor, lineColor)
                    g_debugManager:addElement(output.debugLine, nil, nil, math.huge)
                    output.debugText = DebugText.new():createWithNode(output.outputNode, getName(output.outputNode), 0.01, true)
                    g_debugManager:addElement(output.debugText, nil, nil, math.huge)
                end
            end
        end
    end
end
function PowerTakeOffs.consoleCommandDebug(_)
    if PowerTakeOffs.debugRootNode == nil then
        PowerTakeOffs.debugRootNode = createTransformGroup("powerTakeOffsDebugRoot")
        link(getRootNode(), PowerTakeOffs.debugRootNode)
        local x, y, z = g_localPlayer:getPosition()
        local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
        local ry = MathUtil.getYRotationFromDirection(dirX, dirZ)
        setWorldTranslation(PowerTakeOffs.debugRootNode, x + dirX * 4, y, z + dirZ * 4)
        setWorldRotation(PowerTakeOffs.debugRootNode, 0, ry, 0)
    end
    if PowerTakeOffs.debugPowerTakeOffs ~= nil then
        for dirX, dirZ in ipairs(PowerTakeOffs.debugPowerTakeOffs) do
            g_currentMission:removeUpdateable(dirZ)
            if dirZ.xmlFile ~= nil then
                dirZ.xmlFile:delete()
            end
            if dirZ.sharedLoadRequestId ~= nil then
                g_i3DManager:releaseSharedI3DFile(dirZ.sharedLoadRequestId)
                dirZ.sharedLoadRequestId = nil
            end
            g_animationManager:deleteAnimations(dirZ.animationNodes)
            g_animationManager:deleteAnimations(dirZ.localAnimationNodes)
            delete(dirZ.inputNode)
        end
    end
    PowerTakeOffs.debugPowerTakeOffs = {}
    local x = Files.getFilesRecursive(getAppBasePath() .. "data/shared/assets/powerTakeOffs")
    table.sort(x, function(a, b)
        return a.path < b.path
    end)
    local y = 0
    local z = 0
    local dirX = nil
    local dirZ = nil
    for _, file in ipairs(x) do
        if not file.isDirectory and file.filename:contains(".xml") then
            local linkNode = createTransformGroup("linkNode")
            link(PowerTakeOffs.debugRootNode, linkNode)
            local basePath = string.gsub(file.filename, ".xml", "")
            local basePath = file.path:split(file.filename)[1]
            local z
            if basePath == dirX and basePath == dirZ then
                basePath = dirZ
                basePath = dirX
            else
                y = y + 1
                z = 0
                local wx, wy, wz = localToWorld(PowerTakeOffs.debugRootNode, y * 2, 1, -1)
                local rx, ry, rz = localRotationToWorld(PowerTakeOffs.debugRootNode, -1.5707963267948966, 3.141592653589793, 0)
                g_debugManager:addElement(DebugText3D.new():createWithWorldPos(wx, wy, wz, rx, ry, rz, basePath, 0.15), nil, nil, math.huge)
            end
            local wx = y * 2
            z = z + 1
            setTranslation(linkNode, wx, 1, z)
            setRotation(linkNode, 0, 0, 0)
            local rz = 1
            local rx = 3
            local ry = 1
            dirZ = basePath
            dirX = basePath
            for rz = rz, rx, ry do
                local dummyVehicle = {
                    ["baseDirectory"] = ""
                }
                for k, v in pairs(PowerTakeOffs) do
                    dummyVehicle[k] = v
                end
                function dummyVehicle.onPowerTakeOffI3DLoaded(_, i3dNode, failedReason, args)
                    -- upvalues: (copy) rz, (copy) dummyVehicle
                    local nameMain = args.xmlFile:getValue("powerTakeOff#colorMaterialName", "powerTakeOff_main_mat")
                    local nameDecal = args.xmlFile:getValue("powerTakeOff#decalColorMaterialName", "powerTakeOff_decal_mat")
                    PowerTakeOffs.onPowerTakeOffI3DLoaded(_, i3dNode, failedReason, args)
                    if i3dNode ~= 0 then
                        local powerTakeOff = args.powerTakeOff
                        if rz == 2 then
                            powerTakeOff.material = VehicleMaterial.new()
                            powerTakeOff.material.colorScale = {
                                0,
                                1,
                                1,
                                1
                            }
                            powerTakeOff.material:apply(powerTakeOff.inputNode, nameMain)
                            powerTakeOff.decalMaterial = VehicleMaterial.new()
                            powerTakeOff.decalMaterial.colorScale = {
                                1,
                                0,
                                1,
                                1
                            }
                            powerTakeOff.decalMaterial:apply(powerTakeOff.inputNode, nameDecal)
                        elseif rz == 3 then
                            g_animationManager:startAnimations(powerTakeOff.animationNodes)
                            dummyVehicle.dynamicPowerTakeOff = powerTakeOff
                            dummyVehicle.time = 0
                            function dummyVehicle.update(v, dt)
                                v.time = (v.time + dt) % 2500
                                local alpha = v.time / 2500
                                setTranslation(v.dynamicPowerTakeOff.detachNode, alpha * 0.5, alpha, -1.5)
                                if v.dynamicPowerTakeOff.updateFunc ~= nil then
                                    v.dynamicPowerTakeOff.updateFunc(self, v.dynamicPowerTakeOff, dt)
                                end
                            end
                            g_currentMission:addUpdateable(dummyVehicle, powerTakeOff)
                        end
                        table.insert(PowerTakeOffs.debugPowerTakeOffs, powerTakeOff)
                    end
                end
                function dummyVehicle.loadSubSharedI3DFile(_, filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
                    return g_i3DManager:loadSharedI3DFileAsync(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
                end
                local powerTakeOff = {
                    ["inputNode"] = createTransformGroup("inputNode")
                }
                link(linkNode, powerTakeOff.inputNode)
                setTranslation(powerTakeOff.inputNode, 0, 0, rz * 3)
                setRotation(powerTakeOff.inputNode, 0, 3.141592653589793, 0)
                powerTakeOff.detachNode = createTransformGroup("detachNode")
                link(powerTakeOff.inputNode, powerTakeOff.detachNode)
                setTranslation(powerTakeOff.detachNode, 0, 0, -1.5)
                setRotation(powerTakeOff.detachNode, 0, 0, 0)
                local filename = string.gsub(file.path, getAppBasePath(), "")
                PowerTakeOffs.loadPowerTakeOffFromConfigFile(dummyVehicle, powerTakeOff, filename)
                g_debugManager:addElement(DebugGizmo.new():createWithNode(powerTakeOff.inputNode, "start", nil, nil, 0.25), nil, nil, math.huge)
                g_debugManager:addElement(DebugGizmo.new():createWithNode(powerTakeOff.detachNode, "end", nil, nil, 0.25), nil, nil, math.huge)
            end
        end
    end
end
addConsoleCommand("gsVehicleDebugPowerTakeOffs", "Spawns all power take offs in front of the player", "PowerTakeOffs.consoleCommandDebug", nil)