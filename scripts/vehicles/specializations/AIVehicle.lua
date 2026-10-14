AIVehicle = {}
function AIVehicle.prerequisitesPresent(specializations)
    return true
end
function AIVehicle.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AIVehicle")
    AIVehicle.registerAgentAttachmentPaths(schema, "vehicle.ai", true)
    schema:setXMLSpecializationType()
end
function AIVehicle.registerAgentAttachmentPaths(schema, basePath, includeSubAttachments)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".agentAttachment(?)#jointNode", "Custom joint node (if not defined the current attacher joint is used)")
    schema:register(XMLValueType.VECTOR_N, basePath .. ".agentAttachment(?)#rotCenterWheelIndices", "The center of these wheel indices define the steering center")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".agentAttachment(?)#rotCenterNode", "Custom node to define the steering center")
    schema:register(XMLValueType.VECTOR_2, basePath .. ".agentAttachment(?)#rotCenterPosition", "Offset from root component that defines the steering center")
    schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#width", "Agent attachable width", 3)
    schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#height", "Agent attachable height", 3)
    schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#heightOffset", "Agent attachable height offset (only for visual debug)", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#length", "Agent attachable length", 3)
    schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#lengthOffset", "Agent attachable length offset from rot center", 0)
    schema:register(XMLValueType.BOOL, basePath .. ".agentAttachment(?)#hasCollision", "Agent attachable is doing collision checks", true)
    schema:register(XMLValueType.BOOL, basePath .. ".agentAttachment(?)#useSize", "Use the vehicle size definition for the agentAttachment size as well (for static tools)", false)
    if includeSubAttachments then
        AIVehicle.registerAgentAttachmentPaths(schema, basePath .. ".agentAttachment(?)", false)
    end
end
function AIVehicle.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onAIFieldCourseSettingsInitialized")
    SpecializationUtil.registerEvent(vehicleType, "onPostAIFieldCourseSettingsInitialized")
end
function AIVehicle.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "collectAIAgentAttachments", AIVehicle.collectAIAgentAttachments)
    SpecializationUtil.registerFunction(vehicleType, "registerAIAgentAttachment", AIVehicle.registerAIAgentAttachment)
    SpecializationUtil.registerFunction(vehicleType, "loadAIAgentAttachmentsFromXML", AIVehicle.loadAIAgentAttachmentsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "validateAIAgentAttachments", AIVehicle.validateAIAgentAttachments)
    SpecializationUtil.registerFunction(vehicleType, "drawAIAgentAttachments", AIVehicle.drawAIAgentAttachments)
    SpecializationUtil.registerFunction(vehicleType, "raiseAIEvent", AIVehicle.raiseAIEvent)
    SpecializationUtil.registerFunction(vehicleType, "safeRaiseAIEvent", AIVehicle.safeRaiseAIEvent)
    SpecializationUtil.registerFunction(vehicleType, "getIsAIReadyToDrive", AIVehicle.getIsAIReadyToDrive)
    SpecializationUtil.registerFunction(vehicleType, "getIsAIPreparingToDrive", AIVehicle.getIsAIPreparingToDrive)
end
function AIVehicle.registerOverwrittenFunctions(vehicleType) end
function AIVehicle.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIVehicle)
end
function AIVehicle:onLoad(_)
    local spec = self.spec_aiVehicle
    spec.agentAttachments = {}
    if self.getInputAttacherJoints ~= nil then
        self:loadAIAgentAttachmentsFromXML(self.xmlFile, "vehicle.ai.agentAttachment", spec.agentAttachments)
    end
    spec.debugSizeBox = DebugBox.new()
    spec.debugSizeBox:setColorRGBA(0, 1, 1)
    spec.debugSizeBox:setText("aiAgentAttachment")
end
function AIVehicle:onPostLoad(_)
    local spec = self.spec_aiVehicle
    if #spec.agentAttachments > 0 then
        local inputAttacherJoints = self:getInputAttacherJoints()
        self:validateAIAgentAttachments(spec.agentAttachments, inputAttacherJoints)
    end
end
function AIVehicle:collectAIAgentAttachments(aiDrivableVehicle)
    local spec = self.spec_aiVehicle
    if #spec.agentAttachments > 0 then
        local inputAttacherJointDesc = self:getActiveInputAttacherJoint()
        if inputAttacherJointDesc ~= nil then
            local jointDesc = self:getAttacherVehicle():getAttacherJointDescFromObject(self)
            local usedExplicitAttachment = false
            local i = 1
            for i = i, #spec.agentAttachments do
                local agentAttachment = spec.agentAttachments[i]
                if agentAttachment.jointNode == inputAttacherJointDesc.node then
                    agentAttachment.attacherVehicleJointNode = jointDesc.jointTransform
                    self:registerAIAgentAttachment(aiDrivableVehicle, agentAttachment)
                    usedExplicitAttachment = true
                end
            end
            if not usedExplicitAttachment then
                local i = 1
                for i = i, #spec.agentAttachments do
                    local agentAttachment = spec.agentAttachments[i]
                    if agentAttachment.isDirectAttachment then
                        agentAttachment.attacherVehicleJointNode = jointDesc.jointTransform
                        agentAttachment.jointNodeDynamic = inputAttacherJointDesc.node
                        self:registerAIAgentAttachment(aiDrivableVehicle, agentAttachment)
                        break
                    end
                end
            end
            local i = 1
            for i = i, #spec.agentAttachments do
                local agentAttachment = spec.agentAttachments[i]
                if not agentAttachment.isDirectAttachment then
                    self:registerAIAgentAttachment(aiDrivableVehicle, agentAttachment)
                end
            end
        end
    end
end
function AIVehicle.registerAIAgentAttachment(_, aiDrivableVehicle, agentAttachment)
    aiDrivableVehicle:addAIAgentAttachment(agentAttachment)
    local i = 1
    for i = i, #agentAttachment.agentAttachments do
        aiDrivableVehicle:addAIAgentAttachment(agentAttachment.agentAttachments[i])
    end
end
function AIVehicle:loadAIAgentAttachmentsFromXML(xmlFile, baseKey, agentAttachments, loadSubAttachments, requiresJointNode)
    xmlFile:iterate(baseKey, function(_, key)
        -- upvalues: (copy) xmlFile, (copy) self, (copy) loadSubAttachments, (copy) requiresJointNode, (copy) agentAttachments
        local agentAttachment = {
            ["jointNode"] = xmlFile:getValue(key .. "#jointNode", nil, self.components, self.i3dMappings),
            ["jointNodeDynamic"] = nil,
            ["rotCenterNode"] = xmlFile:getValue(key .. "#rotCenterNode", nil, self.components, self.i3dMappings),
            ["rotCenterWheelIndices"] = xmlFile:getValue(key .. "#rotCenterWheelIndices", nil, true),
            ["rotCenterPosition"] = xmlFile:getValue(key .. "#rotCenterPosition", nil, true),
            ["useSize"] = xmlFile:getValue(key .. "#useSize", false)
        }
        if agentAttachment.useSize then
            agentAttachment.width = self.size.width
            agentAttachment.height = self.size.height
            agentAttachment.heightOffset = self.size.heightOffset
            agentAttachment.length = self.size.length
            agentAttachment.lengthOffset = self.size.lengthOffset
        else
            agentAttachment.width = 3
            agentAttachment.height = 3
            agentAttachment.heightOffset = 0
            agentAttachment.length = 3
            agentAttachment.lengthOffset = 0
        end
        agentAttachment.width = xmlFile:getValue(key .. "#width", agentAttachment.width)
        agentAttachment.height = xmlFile:getValue(key .. "#height", agentAttachment.height)
        agentAttachment.heightOffset = xmlFile:getValue(key .. "#heightOffset", agentAttachment.heightOffset)
        agentAttachment.length = xmlFile:getValue(key .. "#length", agentAttachment.length)
        agentAttachment.lengthOffset = xmlFile:getValue(key .. "#lengthOffset", agentAttachment.lengthOffset)
        agentAttachment.hasCollision = xmlFile:getValue(key .. "#hasCollision", true)
        agentAttachment.isDirectAttachment = false
        agentAttachment.agentAttachments = {}
        if loadSubAttachments ~= false then
            self:loadAIAgentAttachmentsFromXML(xmlFile, key .. ".agentAttachment", agentAttachment.agentAttachments, false, true)
        end
        if requiresJointNode == true and agentAttachment.jointNode == nil then
            Logging.xmlWarning(xmlFile, "No joint node defined for ai agent sub attachable \'%s\'!", key)
        else
            table.insert(agentAttachments, agentAttachment)
        end
    end)
    if loadSubAttachments == nil and #agentAttachments == 0 then
        Logging.xmlWarning(xmlFile, "Missing ai agent attachment definition for attachable vehicle")
    end
end
function AIVehicle:validateAIAgentAttachments(agentAttachments, inputAttacherJoints)
    local i = 1
    for i = i, #agentAttachments do
        local agentAttachment = agentAttachments[i]
        local j = 1
        local rotCenterNode = #inputAttacherJoints
        local x = 1
        for j = j, rotCenterNode, x do
            if agentAttachment.jointNode == nil or agentAttachment.jointNode == inputAttacherJoints[j].node then
                agentAttachment.isDirectAttachment = true
            end
        end
        if agentAttachment.rotCenterNode == nil then
            if agentAttachment.rotCenterPosition == nil or #agentAttachment.rotCenterPosition ~= 2 then
                if agentAttachment.rotCenterWheelIndices ~= nil and (#agentAttachment.rotCenterWheelIndices > 0 and self.getWheels ~= nil) then
                    local rotCenterNode = self:getWheels()
                    local x = 0
                    local j = 0
                    local z = 0
                    local dirX = 0
                    local dirY = 0
                    local dirZ = 0
                    local numWheels = 0
                    local component = nil
                    local j = 1
                    local rotCenterNode = #agentAttachment.rotCenterWheelIndices
                    for j = j, rotCenterNode do
                        local wheelIndex = agentAttachment.rotCenterWheelIndices[j]
                        local wheel = rotCenterNode[wheelIndex]
                        if wheel == nil then
                            Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%d\' ground in ai agent attachment entry \'vehicle.ai.agentAttachment(%d)\'!", wheelIndex, i - 1)
                        else
                            component = component or wheel.node
                            local wx, wy, wz = localToLocal(wheel.repr, component, 0, -wheel.physics.radius, 0)
                            local dx, dy, dz = localDirectionToLocal(wheel.driveNode, component, 0, 0, 1)
                        end
                    end
                    if numWheels > 0 then
                    end
                    local rotCenterNode, dirY, j = MathUtil.vector3Normalize(dirX, dirY, dirZ)
                    if agentAttachment.useSize then
                        agentAttachment.lengthOffset = self.size.lengthOffset - z
                    end
                    local rotCenterNode = createTransformGroup("aiAgentAttachmentRotCenter" .. i)
                    link(component, rotCenterNode)
                    setTranslation(rotCenterNode, x, j, z)
                    agentAttachment.rotCenterNode = rotCenterNode
                    if numWheels > 0 and MathUtil.vector3Length(rotCenterNode, dirY, j) > 0 then
                        setDirection(rotCenterNode, rotCenterNode, dirY, j, 0, 1, 0)
                    end
                end
            else
                local rotCenterNode = createTransformGroup("aiAgentAttachmentRotCenter" .. i)
                link(self.components[1].node, rotCenterNode)
                setTranslation(rotCenterNode, agentAttachment.rotCenterPosition[1], 0, agentAttachment.rotCenterPosition[2])
                agentAttachment.rotCenterNode = rotCenterNode
            end
        end
        if agentAttachment.rotCenterNode == nil then
            agentAttachment.rootNode = self.rootNode
        end
        if agentAttachment.rotCenterNode ~= nil then
            if agentAttachment.jointNode == nil then
                agentAttachment.jointNodeToHitchOffset = {}
                local j = 1
                for j = j, #inputAttacherJoints do
                    local z, dirX, dirY = localToLocal(inputAttacherJoints[j].node, agentAttachment.rotCenterNode, 0, 0, 0)
                    agentAttachment.jointNodeToHitchOffset[inputAttacherJoints[j].node] = dirY
                end
            else
                local x, j, z = localToLocal(agentAttachment.jointNode, agentAttachment.rotCenterNode, 0, 0, 0)
                agentAttachment.trailerHitchOffset = z
            end
        end
        self:validateAIAgentAttachments(agentAttachment.agentAttachments, inputAttacherJoints)
    end
end
function AIVehicle:drawAIAgentAttachments(agentAttachments)
    local spec = self.spec_aiVehicle
    agentAttachments = agentAttachments or spec.agentAttachments
    local i = 1
    for i = i, #agentAttachments do
        local agentAttachment = agentAttachments[i]
        if agentAttachment.rotCenterNode == nil then
            spec.debugSizeBox:setColorRGBA(0, 0.15, 1)
            spec.debugSizeBox:createWithNode(agentAttachment.rootNode, agentAttachment.width, agentAttachment.height, agentAttachment.length, 0, agentAttachment.height * 0.5 + agentAttachment.heightOffset, agentAttachment.lengthOffset)
            spec.debugSizeBox:draw()
        else
            spec.debugSizeBox:setColorRGBA(0, 1, 0.25)
            spec.debugSizeBox:createWithNode(agentAttachment.rotCenterNode, agentAttachment.width, agentAttachment.height, agentAttachment.length, 0, agentAttachment.height * 0.5 + agentAttachment.heightOffset, agentAttachment.lengthOffset)
            spec.debugSizeBox:draw()
        end
        self:drawAIAgentAttachments(agentAttachment.agentAttachments)
    end
end
function AIVehicle:raiseAIEvent(eventName, implementName, ...)
    local actionController = self.rootVehicle.actionController
    for _, vehicle in ipairs(self.rootVehicle.childVehicles) do
        if vehicle ~= self then
            self:safeRaiseAIEvent(vehicle, implementName, ...)
            if actionController ~= nil then
                actionController:onAIEvent(vehicle, implementName)
            end
        end
    end
    self:safeRaiseAIEvent(self, implementName, ...)
    if actionController ~= nil then
        actionController:onAIEvent(self, implementName)
    end
    self:safeRaiseAIEvent(self, eventName, ...)
    if actionController ~= nil then
        actionController:onAIEvent(self, eventName)
    end
end
function AIVehicle.safeRaiseAIEvent(_, vehicle, eventName, ...)
    if vehicle.eventListeners[eventName] ~= nil then
        SpecializationUtil.raiseEvent(vehicle, eventName, ...)
    end
end
function AIVehicle:getIsAIReadyToDrive()
    return true
end
function AIVehicle:getIsAIPreparingToDrive()
    return false
end