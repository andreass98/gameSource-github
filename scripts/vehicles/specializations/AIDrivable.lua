AIDrivable = {}
AIDrivable.STATES = {}
AIDrivable.STATES[AgentState.DRIVING] = "driving"
AIDrivable.STATES[AgentState.BLOCKED] = "blocked"
AIDrivable.STATES[AgentState.PLANNING] = "planning"
AIDrivable.STATES[AgentState.NOT_REACHABLE] = "not_reachable"
AIDrivable.STATES[AgentState.TARGET_REACHED] = "target_reached"
AIDrivable.TRAILER_LIMIT = 4
function AIDrivable.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AIVehicle, specializations) and SpecializationUtil.hasSpecialization(AIJobVehicle, specializations) and SpecializationUtil.hasSpecialization(Drivable, specializations)
end
function AIDrivable.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AI")
    AIDrivable.registerAgentXMLPaths(schema, "vehicle.ai.agent")
    schema:setXMLSpecializationType()
end
function AIDrivable.postInitSpecialization()
    for name, configDesc in pairs(g_vehicleConfigurationManager:getConfigurations()) do
        local configurationKey = configDesc.configurationKey .. "(?)"
        Vehicle.xmlSchema:setXMLSharedRegistration("configAIAgent", configurationKey)
        AIDrivable.registerAgentXMLPaths(schema, configurationKey .. ".aiAgent")
        schema:resetXMLSharedRegistration("configAIAgent", configurationKey)
    end
end
function AIDrivable.registerAgentXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#width", "AI vehicle width")
    schema:register(XMLValueType.FLOAT, basePath .. "#length", "AI vehicle length")
    schema:register(XMLValueType.FLOAT, basePath .. "#lengthOffset", "AI vehicle length offset")
    schema:register(XMLValueType.FLOAT, basePath .. "#height", "AI vehicle height")
    schema:register(XMLValueType.FLOAT, basePath .. "#frontOffset", "AI vehicle front offset")
    schema:register(XMLValueType.VECTOR_N, basePath .. "#frontWheelIndices", "List of wheels (indices) that are used for steering")
    schema:register(XMLValueType.NODE_INDICES, basePath .. "#frontWheelNodes", "List of wheels (nodes) that are used for steering")
    schema:register(XMLValueType.FLOAT, basePath .. "#maxBrakeAcceleration", "AI vehicle max brake acceleration")
    schema:register(XMLValueType.FLOAT, basePath .. "#maxCentripetalAcceleration", "AI vehicle max centripetal acceleration")
    schema:register(XMLValueType.FLOAT, basePath .. "#maxTurningRadius", "Max. turning radius (overwrites value detected from ackermann steering)")
end
function AIDrivable.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onAIDrivablePrepare")
    SpecializationUtil.registerEvent(vehicleType, "onAIDriveableStart")
    SpecializationUtil.registerEvent(vehicleType, "onAIDriveableActive")
    SpecializationUtil.registerEvent(vehicleType, "onAIDriveableEnd")
end
function AIDrivable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "consoleCommandSetTurnRadius", AIDrivable.consoleCommandSetTurnRadius)
    SpecializationUtil.registerFunction(vehicleType, "consoleCommandMove", AIDrivable.consoleCommandMove)
    SpecializationUtil.registerFunction(vehicleType, "consoleCommandClearPath", AIDrivable.consoleCommandClearPath)
    SpecializationUtil.registerFunction(vehicleType, "createAgent", AIDrivable.createAgent)
    SpecializationUtil.registerFunction(vehicleType, "deleteAgent", AIDrivable.deleteAgent)
    SpecializationUtil.registerFunction(vehicleType, "setAITarget", AIDrivable.setAITarget)
    SpecializationUtil.registerFunction(vehicleType, "unsetAITarget", AIDrivable.unsetAITarget)
    SpecializationUtil.registerFunction(vehicleType, "stopAIDriving", AIDrivable.stopAIDriving)
    SpecializationUtil.registerFunction(vehicleType, "reachedAITarget", AIDrivable.reachedAITarget)
    SpecializationUtil.registerFunction(vehicleType, "getAIRootNode", AIDrivable.getAIRootNode)
    SpecializationUtil.registerFunction(vehicleType, "setAIRootNodeDirty", AIDrivable.setAIRootNodeDirty)
    SpecializationUtil.registerFunction(vehicleType, "getAIRootNodeMinZOffset", AIDrivable.getAIRootNodeMinZOffset)
    SpecializationUtil.registerFunction(vehicleType, "getAIRootNodeMaxZOffset", AIDrivable.getAIRootNodeMaxZOffset)
    SpecializationUtil.registerFunction(vehicleType, "getAIRootNodeBoundingBox", AIDrivable.getAIRootNodeBoundingBox)
    SpecializationUtil.registerFunction(vehicleType, "getAIAllowsBackwards", AIDrivable.getAIAllowsBackwards)
    SpecializationUtil.registerFunction(vehicleType, "drawDebugAIAgent", AIDrivable.drawDebugAIAgent)
    SpecializationUtil.registerFunction(vehicleType, "debugGetAgentHasSpaceAt", AIDrivable.debugGetAgentHasSpaceAt)
    SpecializationUtil.registerFunction(vehicleType, "loadAgentInfoFromXML", AIDrivable.loadAgentInfoFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getAIAgentSize", AIDrivable.getAIAgentSize)
    SpecializationUtil.registerFunction(vehicleType, "getAIAgentMaxBrakeAcceleration", AIDrivable.getAIAgentMaxBrakeAcceleration)
    SpecializationUtil.registerFunction(vehicleType, "updateAIAgentAttachments", AIDrivable.updateAIAgentAttachments)
    SpecializationUtil.registerFunction(vehicleType, "addAIAgentAttachment", AIDrivable.addAIAgentAttachment)
    SpecializationUtil.registerFunction(vehicleType, "startNewAIAgentAttachmentChain", AIDrivable.startNewAIAgentAttachmentChain)
    SpecializationUtil.registerFunction(vehicleType, "updateAIAgentAttachmentOffsetData", AIDrivable.updateAIAgentAttachmentOffsetData)
    SpecializationUtil.registerFunction(vehicleType, "updateAIAgentPoseData", AIDrivable.updateAIAgentPoseData)
    SpecializationUtil.registerFunction(vehicleType, "prepareForAIDriving", AIDrivable.prepareForAIDriving)
    SpecializationUtil.registerFunction(vehicleType, "getAITurningRadius", AIDrivable.getAITurningRadius)
end
function AIDrivable.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartAIVehicle", AIDrivable.getCanStartAIVehicle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIJobSupported", AIDrivable.getIsAIJobSupported)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanHaveAIVehicleObstacle", AIDrivable.getCanHaveAIVehicleObstacle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", AIDrivable.getIsAIReadyToDrive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", AIDrivable.getIsAIPreparingToDrive)
end
function AIDrivable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIDrivable)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIDrivable)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIDrivable)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", AIDrivable)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AIDrivable)
    SpecializationUtil.registerEventListener(vehicleType, "onCruiseControlSpeedChanged", AIDrivable)
end
function AIDrivable:onLoad(_)
    local spec = self.spec_aiDrivable
    spec.agentInfo = {}
    spec.agentInfo.isValid = false
    self:loadAgentInfoFromXML(self.xmlFile, spec.agentInfo)
    spec.maxSpeed = math.huge
    spec.isRunning = false
    spec.useManualDriving = false
    spec.lastState = nil
    spec.lastIsBlocked = false
    spec.lastMaxSpeed = 0
    spec.cruiseControlLimit = math.huge
    spec.stuckTime = 0
    spec.agentId = nil
    spec.targetX = nil
    spec.targetY = nil
    spec.targetZ = nil
    spec.targetDirX = nil
    spec.targetDirY = nil
    spec.targetDirZ = nil
    spec.lastNoSpaceAtStart = false
    spec.lastNoSpaceAtTarget = false
    spec.aiRootNodeBoundingBox = {
        0,
        1,
        0,
        1,
        0,
        1
    }
    spec.attachments = {}
    spec.attachmentChains = {}
    spec.attachmentChainIndex = 1
    spec.attachmentsTrailerOffsetData = {}
    spec.attachmentsMaxWidth = 0
    spec.attachmentsMaxHeight = 0
    spec.attachmentsMaxLengthOffsetPos = 0
    spec.attachmentsMaxLengthOffsetNeg = 0
    spec.poseData = {}
    spec.debugVehicle = nil
    spec.debugSizeBox = DebugBox.new()
    spec.debugSizeBox:setColorRGBA(0, 1, 1)
    spec.debugSizeBox:setText("agentSize")
    spec.debugSizeBox:setTextSize(0.012)
    spec.debugFrontMarker = DebugGizmo.new()
    spec.debugDump = nil
end
function AIDrivable:onPostLoad()
    local spec = self.spec_aiDrivable
    local aiRootNode = self:getAIRootNode()
    spec.attacherJointOffsets = {}
    if self.getAttacherJoints ~= nil then
        for _, attacherJoint in ipairs(self:getAttacherJoints()) do
            local node = attacherJoint.jointTransform
            local xDir, yDir, zDir = localDirectionToLocal(node, aiRootNode, 0, 0, 1)
            local xUp, yUp, zUp = localDirectionToLocal(node, aiRootNode, 0, 1, 0)
            local x, y, z = localToLocal(node, aiRootNode, 0, 0, 0)
            table.insert(spec.attacherJointOffsets, {
                ["x"] = x,
                ["y"] = y,
                ["z"] = z,
                ["xDir"] = xDir,
                ["yDir"] = yDir,
                ["zDir"] = zDir,
                ["xUp"] = xUp,
                ["yUp"] = yUp,
                ["zUp"] = zUp
            })
        end
    end
    if spec.agentInfo.isDefined then
        if spec.agentInfo.width == nil or (spec.agentInfo.length == nil or spec.agentInfo.height == nil) then
            spec.agentInfo.width = spec.agentInfo.width or self.size.width
            spec.agentInfo.height = spec.agentInfo.height or self.size.height
            if spec.agentInfo.length == nil then
                spec.agentInfo.length = self.size.length
                local _, _, zOffset = localToLocal(aiRootNode, self.rootNode, 0, 0, 0)
                spec.agentInfo.lengthOffset = -zOffset + self.size.lengthOffset
            end
        end
        if spec.agentInfo.frontWheelIndices ~= nil or spec.agentInfo.frontWheelNodes ~= nil then
            local _ = 0
            local _ = 0
            if spec.agentInfo.frontWheelNodes == nil or #spec.agentInfo.frontWheelNodes <= 0 then
                if spec.agentInfo.frontWheelIndices ~= nil and #spec.agentInfo.frontWheelIndices > 0 then
                    for node, xDir in ipairs(spec.agentInfo.frontWheelIndices) do
                        local yDir = self:getWheelFromWheelIndex(xDir)
                        if yDir == nil then
                            Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%d\' found for ai agent definition.", xDir)
                        else
                            local zDir, xUp, yUp = localToLocal(yDir.repr, aiRootNode, 0, 0, 0)
                        end
                    end
                end
            else
                for node, xDir in ipairs(spec.agentInfo.frontWheelNodes) do
                    local yDir = self:getWheelByWheelNode(xDir)
                    if yDir == nil then
                        Logging.xmlWarning(self.xmlFile, "Node wheel for node \'%s\' found for ai agent definition.", getName(xDir))
                    else
                        local zDir, xUp, yUp = localToLocal(yDir.repr, aiRootNode, 0, 0, 0)
                    end
                end
            end
            if _ > 0 then
                spec.agentInfo.frontOffset = _ / _
            end
        end
    end
    local _ = spec.agentInfo
    local _ = spec.agentInfo.width ~= nil or (spec.agentInfo.length ~= nil or spec.agentInfo.height ~= nil)
    _.isValid = _
    spec.debugSizeBox:setText(string.format("agentSize\nw:%.2f l:%.2f h:%.2f", spec.agentInfo.width or 0, spec.agentInfo.length or 0, spec.agentInfo.height or 0))
    self:setAIRootNodeDirty()
end
function AIDrivable:onUpdate(dt, _, _, _)
    local spec = self.spec_aiDrivable
    if self.isServer and spec.isRunning then
        local isStillBlocked = spec.lastIsBlocked
        if isStillBlocked then
            isStillBlocked = self:getLastSpeed() < 5
        end
        local isCurrentlyBlocked = false
        local aiRootNode = spec.lastMaxSpeed
        if math.abs(aiRootNode) > 0 then
            isCurrentlyBlocked = self:getLastSpeed() < 1
        end
        if isCurrentlyBlocked or isStillBlocked then
            spec.stuckTime = spec.stuckTime + dt
        else
            spec.stuckTime = 0
        end
        local isBlocked = spec.stuckTime > 5000
        local aiRootNode = self:getAIRootNode()
        local x, y, z = getWorldTranslation(aiRootNode)
        spec.distanceToTarget = MathUtil.vector2Length(x - spec.targetX, z - spec.targetZ)
        local tx = spec.maxSpeed
        local _ = spec.cruiseControlLimit
        local maxSpeed = math.min(tx, _)
        if spec.useManualDriving then
            local tx, _, tz = worldToLocal(aiRootNode, spec.targetX, spec.targetY, spec.targetZ)
            AIVehicleUtil.driveToPoint(self, dt, 1, true, true, tx, tz, maxSpeed, false)
            spec.lastMaxSpeed = maxSpeed
            if spec.distanceToTarget < 0.5 then
                self:reachedAITarget()
            end
        else
            local tx, _, tz = localDirectionToWorld(aiRootNode, 0, 0, 1)
            self:updateAIAgentPoseData()
            local curvature, maxSpeedCurvature, status = getVehicleNavigationAgentNextCurvature(spec.agentId, spec.poseData, (math.abs(self.lastSpeedReal * self.movingDirection * 1000)))
            if spec.debugDump ~= nil then
                spec.debugDump:addData(dt, x, y, z, tx, _, tz, lastSpeed, curvature, maxSpeed, status)
            end
            if status == AgentState.DRIVING then
                maxSpeed = math.min(maxSpeedCurvature * 3.6, maxSpeed)
                AIVehicleUtil.driveAlongCurvature(self, dt, curvature, maxSpeed, 1)
                if maxSpeed == 0 then
                    isBlocked = false
                end
            elseif status == AgentState.PLANNING then
                self:stopAIDriving()
                isBlocked = false
                self:brake(1)
            elseif status == AgentState.BLOCKED then
                self:stopAIDriving()
                isBlocked = true
            elseif status == AgentState.TARGET_REACHED then
                isBlocked = false
                self:reachedAITarget()
            elseif status == AgentState.NOT_REACHABLE then
                isBlocked = false
                self:stopCurrentAIJob(AIMessageErrorNotReachable.new())
            end
            spec.lastState = status
            spec.lastMaxSpeed = maxSpeed
        end
        if spec.debugVehicle ~= nil then
            spec.debugVehicle:update(dt)
        end
        if not isBlocked and spec.stuckTime > 5000 then
            spec.stuckTime = 0
        end
        if isBlocked and not spec.lastIsBlocked then
            g_server:broadcastEvent(AIVehicleIsBlockedEvent.new(self, true), true, nil, self)
        elseif not isBlocked and spec.lastIsBlocked then
            g_server:broadcastEvent(AIVehicleIsBlockedEvent.new(self, false), true, nil, self)
        end
        spec.lastIsBlocked = isBlocked
        SpecializationUtil.raiseEvent(self, "onAIDriveableActive")
    end
end
function AIDrivable:createAgent(_)
    if self.isServer then
        local spec = self.spec_aiDrivable
        spec.cruiseControlLimit = math.huge
        self:updateAIAgentAttachments()
        local navigationMapId = g_currentMission.aiSystem:getNavigationMap()
        local agent = spec.agentInfo
        local width, length, lengthOffset, frontOffset, height = self:getAIAgentSize()
        local maxBrakeAcceleration = self:getAIAgentMaxBrakeAcceleration()
        local maxCentripetalAcceleration = agent.maxCentripetalAcceleration
        local minTurningRadius = self:getAITurningRadius(agent.maxTurningRadius or self.maxTurningRadius)
        local allowBackwards = self:getAIAllowsBackwards()
        spec.agentId = createVehicleNavigationAgent(navigationMapId, minTurningRadius, minTurningRadius, allowBackwards, width, height, length, lengthOffset, frontOffset, maxBrakeAcceleration, maxCentripetalAcceleration, spec.attachmentsTrailerOffsetData)
        setName(spec.agentId, string.format("%s - %s", getName(spec.agentId), self.configFileNameClean))
        g_currentMission.aiSystem:addAgent(spec.agentId, self)
        self:setAIVehicleObstacleStateDirty()
        if g_currentMission.aiSystem.debugEnabled then
            if spec.debugVehicle ~= nil then
                spec.debugVehicle:delete()
            end
            spec.debugVehicle = AIDebugVehicle.new(self, { math.random(), math.random(), math.random() })
            if spec.debugDump ~= nil then
                spec.debugDump:delete()
            end
            spec.debugDump = AIDebugDump.new(self, spec.agentId)
            spec.debugDump:startRecording(minTurningRadius, allowBackwards, width, length, lengthOffset, frontOffset, maxBrakeAcceleration, maxCentripetalAcceleration)
        end
        if VehicleDebug.state == VehicleDebug.DEBUG_AI then
            enableVehicleNavigationAgentDebugRendering(spec.agentId, true)
        end
    end
end
function AIDrivable:deleteAgent()
    local spec = self.spec_aiDrivable
    spec.isRunning = false
    self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
    if spec.debugDump ~= nil then
        spec.debugDump:delete()
        spec.debugDump = nil
    end
    if spec.agentId ~= nil then
        if g_currentMission ~= nil and g_currentMission.aiSystem ~= nil then
            g_currentMission.aiSystem:removeAgent(spec.agentId)
        end
        delete(spec.agentId)
        spec.agentId = nil
    end
    self:setAIVehicleObstacleStateDirty()
end
function AIDrivable:setAITarget(task, x, y, z, dirX, dirY, dirZ, maxSpeed, useManualDriving)
    local spec = self.spec_aiDrivable
    local aiRootNode = self:getAIRootNode()
    local cx, cy, cz = getWorldTranslation(aiRootNode)
    local cDirX, cDirY, cDirZ = localDirectionToWorld(aiRootNode, 0, 0, 1)
    spec.useManualDriving = Utils.getNoNil(useManualDriving, false)
    spec.isRunning = true
    spec.task = task
    spec.maxSpeed = maxSpeed or math.huge
    spec.targetX = x
    spec.targetY = y
    spec.targetZ = z
    spec.targetDirX = dirX or 0
    spec.targetDirY = dirY
    spec.targetDirZ = dirZ or 0
    spec.distanceToTarget = MathUtil.vector2Length(cx - x, cz - z)
    spec.lastNoSpaceAtStart = false
    spec.lastNoSpaceAtTarget = false
    if not spec.useManualDriving and self.isServer then
        setVehicleNavigationAgentTarget(spec.agentId, x, y, z, dirX, dirY, dirZ)
    end
    if spec.debugVehicle ~= nil then
        spec.debugVehicle:setTarget(x, y, z, dirX, dirY, dirZ)
    end
    if spec.debugDump ~= nil then
        if useManualDriving then
            spec.debugDump:stopPlanningRecording()
        else
            spec.debugDump:stopPlanningRecording()
            spec.debugDump:startPlanningRecording()
        end
        spec.debugDump:setTarget(x, y, z, dirX, dirY, dirZ, cx, cy, cz, cDirX, cDirY, cDirZ, spec.maxSpeed)
    end
    SpecializationUtil.raiseEvent(self, "onAIDriveableStart")
end
function AIDrivable:reachedAITarget()
    if self.isServer then
        local lastTask = self.spec_aiDrivable.task
        if lastTask ~= nil then
            lastTask:onTargetReached()
        end
    end
end
function AIDrivable:unsetAITarget()
    local spec = self.spec_aiDrivable
    spec.isRunning = false
    spec.task = nil
    spec.useManualDriving = false
    self:stopAIDriving()
    SpecializationUtil.raiseEvent(self, "onAIDriveableEnd")
end
function AIDrivable:stopAIDriving()
    self:brake(1)
    self:stopVehicle()
    self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
end
function AIDrivable:getAIRootNode()
    return self.components[1].node
end
function AIDrivable:setAIRootNodeDirty()
    local spec = self.spec_aiDrivable
    local aiRootNode = self:getAIRootNode()
    local xOffsetPosX, xOffsetPosY, xOffsetPosZ = localToWorld(self.rootNode, self.size.widthOffset + self.size.width * 0.5, 0, 0)
    local xOffsetNegX, xOffsetNegY, xOffsetNegZ = localToWorld(self.rootNode, self.size.widthOffset - self.size.width * 0.5, 0, 0)
    local yOffsetPosX, yOffsetPosY, yOffsetPosZ = localToWorld(self.rootNode, 0, self.size.heightOffset + self.size.height, 0)
    local yOffsetNegX, yOffsetNegY, yOffsetNegZ = localToWorld(self.rootNode, 0, self.size.heightOffset, 0)
    local zOffsetPosX, zOffsetPosY, zOffsetPosZ = localToWorld(self.rootNode, 0, 0, self.size.lengthOffset + self.size.length * 0.5)
    local zOffsetNegX, zOffsetNegY, zOffsetNegZ = localToWorld(self.rootNode, 0, 0, self.size.lengthOffset - self.size.length * 0.5)
    local xOffset1, yOffset1, zOffset1 = worldToLocal(aiRootNode, xOffsetPosX, xOffsetPosY, xOffsetPosZ)
    local xOffset2, yOffset2, zOffset2 = worldToLocal(aiRootNode, xOffsetNegX, xOffsetNegY, xOffsetNegZ)
    local xOffset3, yOffset3, zOffset3 = worldToLocal(aiRootNode, yOffsetPosX, yOffsetPosY, yOffsetPosZ)
    local xOffset4, yOffset4, zOffset4 = worldToLocal(aiRootNode, yOffsetNegX, yOffsetNegY, yOffsetNegZ)
    local xOffset5, yOffset5, zOffset5 = worldToLocal(aiRootNode, zOffsetPosX, zOffsetPosY, zOffsetPosZ)
    local xOffset6, yOffset6, zOffset6 = worldToLocal(aiRootNode, zOffsetNegX, zOffsetNegY, zOffsetNegZ)
    local minXOffset = math.min(xOffset1, xOffset2, xOffset3, xOffset4, xOffset5, xOffset6)
    local maxXOffset = math.max(xOffset1, xOffset2, xOffset3, xOffset4, xOffset5, xOffset6)
    local minYOffset = math.min(yOffset1, yOffset2, yOffset3, yOffset4, yOffset5, yOffset6)
    local maxYOffset = math.max(yOffset1, yOffset2, yOffset3, yOffset4, yOffset5, yOffset6)
    local minZOffset = math.min(zOffset1, zOffset2, zOffset3, zOffset4, zOffset5, zOffset6)
    local maxZOffset = math.max(zOffset1, zOffset2, zOffset3, zOffset4, zOffset5, zOffset6)
    spec.aiRootNodeBoundingBox[1] = minXOffset
    spec.aiRootNodeBoundingBox[2] = maxXOffset
    spec.aiRootNodeBoundingBox[3] = minYOffset
    spec.aiRootNodeBoundingBox[4] = maxYOffset
    spec.aiRootNodeBoundingBox[5] = minZOffset
    spec.aiRootNodeBoundingBox[6] = maxZOffset
end
function AIDrivable:getAIRootNodeMinZOffset()
    return self.spec_aiDrivable.aiRootNodeBoundingBox[5]
end
function AIDrivable:getAIRootNodeMaxZOffset()
    return self.spec_aiDrivable.aiRootNodeBoundingBox[6]
end
function AIDrivable:getAIRootNodeBoundingBox()
    local boundingBox = self.spec_aiDrivable.aiRootNodeBoundingBox
    local aiRootNode = self:getAIRootNode()
    local sizeX = boundingBox[2] - boundingBox[1]
    local sizeY = boundingBox[4] - boundingBox[3]
    local sizeZ = boundingBox[6] - boundingBox[5]
    local vx, vy, vz = localToWorld(aiRootNode, boundingBox[1] + sizeX * 0.5, boundingBox[3] + sizeY * 0.5, boundingBox[5] + sizeZ * 0.5)
    local qx, qy, qz, qw = getWorldQuaternion(aiRootNode)
    return vx, vy, vz, qx, qy, qz, qw, sizeX * 0.5, sizeY * 0.5, sizeZ * 0.5
end
function AIDrivable:getAIAllowsBackwards()
    return false
end
function AIDrivable:onEnterVehicle(isControlling)
    if isControlling and self.isServer then
        addConsoleCommand("gsAISetTurnRadius", "Set Turn radius", "consoleCommandSetTurnRadius", self)
        addConsoleCommand("gsAIMoveVehicle", "Moves vehicles", "consoleCommandMove", self)
        addConsoleCommand("gsAIClearPath", "Clears debug path", "consoleCommandClearPath", self)
    end
end
function AIDrivable.onLeaveVehicle(_, wasEntered)
    if wasEntered then
        removeConsoleCommand("gsAISetTurnRadius")
        removeConsoleCommand("gsAIMoveVehicle")
        removeConsoleCommand("gsAIClearPath")
    end
end
function AIDrivable:onCruiseControlSpeedChanged(speed, _)
    self.spec_aiDrivable.cruiseControlLimit = speed
end
function AIDrivable:getIsAIReadyToDrive(superFunc)
    for _, vehicle in ipairs(self.rootVehicle.childVehicles) do
        if vehicle ~= self and (vehicle.getIsAIReadyToDrive ~= nil and not vehicle:getIsAIReadyToDrive()) then
            return false, vehicle
        end
    end
    return superFunc(self)
end
function AIDrivable:getIsAIPreparingToDrive(superFunc)
    for _, vehicle in ipairs(self.rootVehicle.childVehicles) do
        if vehicle ~= self and (vehicle.getIsAIPreparingToDrive ~= nil and vehicle:getIsAIPreparingToDrive()) then
            return true
        end
    end
    return superFunc(self)
end
function AIDrivable:drawDebugAIAgent()
    local spec = self.spec_aiDrivable
    if spec.agentInfo.isValid then
        local aiRootNode = self:getAIRootNode()
        local yOffset = 0
        local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
        if storeItem ~= nil and storeItem.shopTranslationOffset ~= nil then
            yOffset = storeItem.shopTranslationOffset[2]
        end
        local width, length, lengthOffset, frontOffset, height = self:getAIAgentSize()
        spec.debugSizeBox:createWithNode(aiRootNode, width, height, length, 0, height * 0.5 - yOffset, lengthOffset)
        spec.debugSizeBox:draw()
        local fx, fy, fz = localToWorld(aiRootNode, 0, 0, frontOffset)
        local dirX, dirY, dirZ = localDirectionToWorld(aiRootNode, 0, 0, 1)
        local upX, upY, upZ = localDirectionToWorld(aiRootNode, 0, 1, 0)
        if fy > 0 then
            fy = getTerrainHeightAtWorldPos(g_terrainNode, fx, 0, fz) + 0.15
        end
        spec.debugFrontMarker:createWithWorldPosAndDir(fx, fy, fz, dirX, dirY, dirZ, upX, upY, upZ, "FrontMarker", false, nil, 3)
        spec.debugFrontMarker:draw()
        local x, y, z = getWorldTranslation(aiRootNode)
        if spec.isRunning then
            local _
            if spec.useManualDriving then
                _ = string.format("Distance: %.2f", spec.distanceToTarget)
            else
                _ = AIDrivable.STATES[spec.lastState]
            end
            Utils.renderTextAtWorldPosition(x, y + 4, z, wheel, 0.015, 0, 1, 1, 1, 1)
        end
        if spec.debugVehicle ~= nil then
            spec.debugVehicle:setForcedY(y + 0.1)
            spec.debugVehicle:draw()
        end
        local text, _, sz = localToWorld(aiRootNode, 0, 0.5, 0)
        local sy = getTerrainHeightAtWorldPos(g_terrainNode, text, 0, sz) + 0.15
        local lx, _, lz = localToWorld(aiRootNode, 10, 0.5, 0)
        local rx, _, rz = localToWorld(aiRootNode, -10, 0.5, 0)
        drawDebugLine(text, sy, sz, 1, 0, 0, lx, sy, lz, 1, 0, 0)
        drawDebugLine(text, sy, sz, 0, 1, 0, rx, sy, rz, 0, 1, 0)
        local dirX1, dirZ1 = MathUtil.vector2Normalize(lx - text, lz - sz)
        local currentTurnRadius = self:getTurningRadiusByRotTime(self.rotatedTime)
        local minRadius = self:getAITurningRadius(self.maxTurningRadius)
        local revTime = self:getSteeringRotTimeByCurvature(1 / (currentTurnRadius * (self.rotatedTime >= 0 and 1 or -1)))
        local debugString = string.format("ReferenceRadius: %.3fm\nMinRadius: %.3fm\nCalc Radius: %.3f\nRotatedTime: %.3f\nRevTime: %.3f", currentTurnRadius, self.maxTurningRadius, minRadius, self.rotatedTime, revTime)
        Utils.renderTextAtWorldPosition(text, sy + 5, sz, debugString, getCorrectTextSize(0.012), 0)
        local wheelSpec = self.spec_wheels
        for _, wheel in ipairs(wheelSpec.wheels) do
            if wheel.physics.rotSpeed ~= 0 or self.spec_articulatedAxis ~= nil and self.spec_articulatedAxis.componentJoint ~= nil then
                local wsx, wsy, wsz = localToWorld(wheel.repr, 0, 0, 0)
                local wdx, wdy, wdz = localDirectionToWorld(wheel.driveNode, 1, 0, 0)
                local _ = wsy + wdy * 10
                local _ = wsy + wdy * -10
                drawDebugLine(wsx, sy, wsz, 1, 0, 0, wsx + wdx * 10, sy, wsz + wdz * 10, 1, 0, 0)
                drawDebugLine(wsx, sy, wsz, 0, 1, 0, wsx + wdx * -10, sy, wsz + wdz * -10, 0, 1, 0)
            end
        end
        if wheelSpec.steeringCenterNode ~= nil then
            DebugGizmo.renderAtNode(wheelSpec.steeringCenterNode, "SCN")
        end
        local sign = math.sign(self.rotatedTime)
        DebugGizmo.renderAtPosition(text + sign * dirX1 * currentTurnRadius, sy, sz + sign * dirZ1 * currentTurnRadius, dirX1, 0, dirZ1, 0, 1, 0, "X")
        local wheel = self.rotatedTime
        wheel = math.sign(wheel)
        DebugGizmo.renderAtPosition(text + wheel * dirX1 * minRadius, sy, sz + wheel * dirZ1 * minRadius, dirX1, 0, dirZ1, 0, 1, 0, "M")
    end
end
function AIDrivable:debugGetAgentHasSpaceAt(x, y, z, dirX, dirY, dirZ, group)
    local spec = self.spec_aiDrivable
    local agent = spec.agentInfo
    local addDebugElements = VehicleDebug.state ~= VehicleDebug.DEBUG_AI and g_currentMission.aiSystem
    if addDebugElements then
        addDebugElements = g_currentMission.aiSystem.splinesVisible or g_currentMission.aiSystem.debug.isCostRenderingActive
    end
    local halfWidth = agent.width / 2 + 0.3
    local halfLength = agent.length / 2 + 0.3
    local testPoints = {
        { MathUtil.transform(x, y, z, dirX, dirY, dirZ, 0, 1, 0, halfWidth, 0, -halfLength - agent.lengthOffset) },
        { MathUtil.transform(x, y, z, dirX, dirY, dirZ, 0, 1, 0, -halfWidth, 0, -halfLength - agent.lengthOffset) },
        { MathUtil.transform(x, y, z, dirX, dirY, dirZ, 0, 1, 0, -halfWidth, 0, halfLength - agent.lengthOffset) },
        { MathUtil.transform(x, y, z, dirX, dirY, dirZ, 0, 1, 0, halfWidth, 0, halfLength - agent.lengthOffset) }
    }
    local isBlocked = false
    local polygon = DebugPolygon.new()
    for _, testPoint in ipairs(testPoints) do
        local wx = testPoint[1]
        local wy = testPoint[2]
        local wz = testPoint[3]
        local _, isBlocking = getVehicleNavigationMapCostAtWorldPos(g_currentMission.aiSystem.navigationMap, wx, wy, wz)
        if addDebugElements then
            local pointElem = DebugPoint.new():createWithWorldPos(wx, wy, wz, true, false):setColorRGBA(0, 1, 0, 0.8)
            if isBlocking then
                pointElem:setColorRGBA(1, 0, 0, 1)
            end
            g_debugManager:addElement(pointElem, "AIAgentHasSpace")
            polygon:addPosition(wx, wy, wz)
        end
    end
    if addDebugElements then
        local text = string.format("%s\n%s\nagentId %d\nagentWidth %.3f\nagentLength %.3f\nagentLengthOffset %.3f", group, self.configFileName, spec.agentId, agent.width, agent.length, agent.lengthOffset)
        local textElem = DebugText.new():createWithWorldPos(x, y, z, text, 0.015):setColorRGBA(0, 1, 0, 1)
        if isBlocked then
            textElem:setColorRGBA(1, 0, 0, 1)
        end
        g_debugManager:addElement(textElem, "AIAgentHasSpace")
        polygon:setColor(isBlocked and Color.PRESETS.RED or Color.PRESETS.GREEN):addToManager("AIAgentHasSpace")
    end
    return not isBlocked
end
function AIDrivable:loadAgentInfoFromXML(xmlFile, agent)
    agent.width = xmlFile:getValue("vehicle.ai.agent#width")
    agent.length = xmlFile:getValue("vehicle.ai.agent#length")
    agent.height = xmlFile:getValue("vehicle.ai.agent#height")
    agent.lengthOffset = xmlFile:getValue("vehicle.ai.agent#lengthOffset", 0)
    agent.frontOffset = xmlFile:getValue("vehicle.ai.agent#frontOffset", 3)
    agent.frontWheelIndices = xmlFile:getValue("vehicle.ai.agent#frontWheelIndices", nil, true)
    agent.frontWheelNodes = xmlFile:getValue("vehicle.ai.agent#frontWheelNodes", nil, self.components, self.i3dMappings, true)
    agent.maxBrakeAcceleration = xmlFile:getValue("vehicle.ai.agent#maxBrakeAcceleration", 5)
    agent.maxCentripetalAcceleration = xmlFile:getValue("vehicle.ai.agent#maxCentripetalAcceleration", 1)
    agent.maxTurningRadius = xmlFile:getValue("vehicle.ai.agent#maxTurningRadius")
    agent.isDefined = xmlFile:hasProperty("vehicle.ai.agent")
    for name, id in pairs(self.configurations) do
        local configDesc = g_vehicleConfigurationManager:getConfigurationDescByName(name)
        local key = string.format("%s(%d).aiAgent", configDesc.configurationKey, id - 1)
        if xmlFile:hasProperty(key) then
            agent.width = xmlFile:getValue(key .. "#width", agent.width)
            agent.length = xmlFile:getValue(key .. "#length", agent.length)
            agent.height = xmlFile:getValue(key .. "#height", agent.height)
            agent.lengthOffset = xmlFile:getValue(key .. "#lengthOffset", agent.lengthOffset)
            agent.frontOffset = xmlFile:getValue(key .. "#frontOffset", agent.frontOffset)
            agent.frontWheelIndices = xmlFile:getValue(key .. "#frontWheelIndices", agent.frontWheelIndices, true)
            agent.frontWheelNodes = xmlFile:getValue(key .. "#frontWheelNodes", agent.frontWheelNodes, self.components, self.i3dMappings, true)
            agent.maxBrakeAcceleration = math.min(xmlFile:getValue(key .. "#maxBrakeAcceleration", agent.maxBrakeAcceleration))
            agent.maxCentripetalAcceleration = math.min(xmlFile:getValue(key .. "#maxCentripetalAcceleration", agent.maxCentripetalAcceleration))
            agent.maxTurningRadius = xmlFile:getValue(key .. "#maxTurningRadius", agent.maxTurningRadius)
            agent.isDefined = true
        end
    end
end
function AIDrivable:getAIAgentSize()
    local spec = self.spec_aiDrivable
    local agent = spec.agentInfo
    if not agent.isValid then
        return nil, nil, nil, nil, nil
    end
    local width = math.max(agent.width, spec.attachmentsMaxWidth)
    return width, agent.length + spec.attachmentsMaxLengthOffsetPos - spec.attachmentsMaxLengthOffsetNeg, agent.lengthOffset + spec.attachmentsMaxLengthOffsetPos * 0.5 + spec.attachmentsMaxLengthOffsetNeg * 0.5, agent.frontOffset, math.max(agent.height, spec.attachmentsMaxHeight)
end
function AIDrivable:getAIAgentMaxBrakeAcceleration()
    return self.spec_aiDrivable.agentInfo.maxBrakeAcceleration
end
function AIDrivable:updateAIAgentAttachments()
    local spec = self.spec_aiDrivable
    spec.attachments = {}
    spec.attachmentChains = {}
    spec.attachmentChainIndex = 1
    spec.attachmentsTrailerOffsetData = {}
    spec.attachmentsMaxWidth = 0
    spec.attachmentsMaxHeight = 0
    spec.attachmentsMaxLengthOffsetPos = 0
    spec.attachmentsMaxLengthOffsetNeg = 0
    self:collectAIAgentAttachments(self)
    self:updateAIAgentAttachmentOffsetData()
    self:updateAIAgentPoseData()
end
function AIDrivable:addAIAgentAttachment(attachmentData, level)
    local spec = self.spec_aiDrivable
    spec.attachmentsMaxWidth = math.max(spec.attachmentsMaxWidth, attachmentData.width)
    spec.attachmentsMaxHeight = math.max(spec.attachmentsMaxHeight, attachmentData.height)
    attachmentData.level = level
    if spec.attachmentChains[spec.attachmentChainIndex] == nil then
        spec.attachmentChains[spec.attachmentChainIndex] = {}
    end
    table.insert(spec.attachments, attachmentData)
    table.insert(spec.attachmentChains[spec.attachmentChainIndex], attachmentData)
end
function AIDrivable:startNewAIAgentAttachmentChain()
    local spec = self.spec_aiDrivable
    if spec.attachmentChains[spec.attachmentChainIndex] ~= nil then
        spec.attachmentChainIndex = spec.attachmentChainIndex + 1
    end
end
function AIDrivable:updateAIAgentAttachmentOffsetData()
    local spec = self.spec_aiDrivable
    if spec.agentInfo.isValid then
        local _, agentLength, _, _ = self:getAIAgentSize()
        local numTrailers = 0
        local ci = 1
        for ci = ci, #spec.attachmentChains do
            local chainAttachments = spec.attachmentChains[ci]
            local isDynamicChain = true
            local isStaticChain = true
            local parentSteeringCenterNode = self:getAIRootNode()
            local i = 1
            for i = i, #chainAttachments do
                local agentAttachment = chainAttachments[i]
                if agentAttachment.rotCenterNode == nil or not isDynamicChain then
                    if isStaticChain then
                        if numTrailers > 0 then
                            isDynamicChain = false
                        end
                        if agentAttachment.rotCenterNode == nil then
                            local jointNode = self:getAIRootNode()
                            local attacherVehicleJointNode, _, _ = localToLocal(agentAttachment.rootNode, jointNode, 0, 0, agentAttachment.length * 0.5)
                            local tractorHitchOffset, trailerHitchOffset, centerOffset = localToLocal(agentAttachment.rootNode, jointNode, 0, 0, -agentAttachment.length * 0.5)
                            local hasCollision = -spec.agentInfo.length * 0.5 + spec.agentInfo.lengthOffset
                            local maxZ = spec.agentInfo.length * 0.5 + spec.agentInfo.lengthOffset
                            local zDiffNeg = math.min(0, _ - hasCollision, centerOffset - hasCollision)
                            local zDiffPos = math.max(0, _ - maxZ, centerOffset - maxZ)
                            spec.attachmentsMaxLengthOffsetPos = math.max(spec.attachmentsMaxLengthOffsetPos, zDiffPos)
                            spec.attachmentsMaxLengthOffsetNeg = math.min(spec.attachmentsMaxLengthOffsetNeg, zDiffNeg)
                        end
                    end
                elseif numTrailers < AIDrivable.TRAILER_LIMIT then
                    local jointNode = agentAttachment.jointNode or agentAttachment.jointNodeDynamic
                    local attacherVehicleJointNode = agentAttachment.attacherVehicleJointNode or jointNode
                    if attacherVehicleJointNode ~= nil and jointNode ~= nil then
                        local _, _, tractorHitchOffset = localToLocal(attacherVehicleJointNode, parentSteeringCenterNode, 0, 0, 0)
                        local trailerHitchOffset
                        if agentAttachment.jointNodeToHitchOffset == nil then
                            trailerHitchOffset = agentAttachment.trailerHitchOffset
                        else
                            trailerHitchOffset = agentAttachment.jointNodeToHitchOffset[jointNode]
                        end
                        if trailerHitchOffset ~= nil then
                            table.insert(spec.attachmentsTrailerOffsetData, tractorHitchOffset)
                            table.insert(spec.attachmentsTrailerOffsetData, trailerHitchOffset)
                            table.insert(spec.attachmentsTrailerOffsetData, agentAttachment.lengthOffset + agentLength * 0.5 - agentAttachment.length * 0.5)
                            table.insert(spec.attachmentsTrailerOffsetData, agentAttachment.hasCollision and 1 or 0)
                            parentSteeringCenterNode = agentAttachment.rotCenterNode
                        end
                    end
                    isStaticChain = false
                end
            end
        end
    end
end
function AIDrivable:updateAIAgentPoseData()
    local spec = self.spec_aiDrivable
    local aiRootNode = self:getAIRootNode()
    local numTrailers = spec.poseData
    local currentIndex = spec.poseData
    numTrailers[1], currentIndex[2], spec.poseData[3] = getWorldTranslation(aiRootNode)
    local numTrailers = spec.poseData
    local currentIndex = spec.poseData
    numTrailers[4], currentIndex[5], spec.poseData[6] = localDirectionToWorld(aiRootNode, 0, 0, 1)
    local numTrailers = 0
    local currentIndex = 6
    local ci = 1
    for ci = ci, #spec.attachmentChains do
        local chainAttachments = spec.attachmentChains[ci]
        local isDynamicChain = true
        local i = 1
        for i = i, #chainAttachments do
            local agentAttachment = chainAttachments[i]
            if agentAttachment.rotCenterNode == nil or not isDynamicChain then
                if numTrailers > 0 then
                    isDynamicChain = false
                end
            elseif numTrailers < AIDrivable.TRAILER_LIMIT then
                spec.poseData[currentIndex + 1], spec.poseData[currentIndex + 2], spec.poseData[currentIndex + 3] = getWorldTranslation(agentAttachment.rotCenterNode)
                spec.poseData[currentIndex + 4], spec.poseData[currentIndex + 5], spec.poseData[currentIndex + 6] = localDirectionToWorld(agentAttachment.rotCenterNode, 0, 0, 1)
                currentIndex = currentIndex + 6
            end
        end
    end
    while currentIndex < #spec.poseData do
        table.remove(spec.poseData, #spec.poseData)
    end
end
function AIDrivable:prepareForAIDriving()
    self:raiseAIEvent("onAIDrivablePrepare", "onAIImplementPrepareForTransport")
end
function AIDrivable.getAITurningRadius(_, minRadius)
    return minRadius
end
function AIDrivable:getCanStartAIVehicle(superFunc)
    if self.spec_aiDrivable.agentInfo.isValid then
        return superFunc(self)
    else
        return false
    end
end
function AIDrivable:getIsAIJobSupported(superFunc, jobName)
    if self.spec_aiDrivable.agentInfo.isValid then
        return superFunc(self, jobName)
    else
        return false
    end
end
function AIDrivable:getCanHaveAIVehicleObstacle(superFunc)
    if self.spec_aiDrivable.agentId == nil then
        return superFunc(self)
    else
        return false
    end
end
function AIDrivable:consoleCommandClearPath()
    local spec = self.spec_aiDrivable
    if spec.debugVehicle ~= nil then
        spec.debugVehicle:clear()
    end
    return string.format("Cleared AI paths of %s", self:getName())
end
function AIDrivable:consoleCommandSetTurnRadius(turnRadius)
    local rotatedTime = self:getSteeringRotTimeByCurvature(1 / (tonumber(turnRadius) or 10))
    local axisSide
    if rotatedTime > 0 then
        axisSide = rotatedTime / -self.maxRotTime
    else
        axisSide = rotatedTime / self.minRotTime
    end
    local axisSide = self:getSteeringDirection() * axisSide
    self.spec_drivable.axisSide = axisSide
end
function AIDrivable:consoleCommandMove(distance)
    local vehicles = {}
    local attachedVehicles = self:getChildVehicles()
    for _, vehicle in ipairs(attachedVehicles) do
        vehicle:removeFromPhysics()
        table.insert(vehicles, vehicle)
    end
    local aiRootNode = self:getAIRootNode()
    local dirX, dirY, _ = localDirectionToWorld(aiRootNode, 1, 0, 0)
    local currentTurnRadius = self:getTurningRadiusByRotTime(self.rotatedTime)
    local gizmo = DebugGizmo.new()
    local x, y, z = localToWorld(aiRootNode, currentTurnRadius, 0.05, 0)
    gizmo:createWithWorldPosAndDir(x, y, z, 0, 0, 1, 0, 1, 0, "", false, nil)
    g_debugManager:addElement(gizmo)
    self.rotatedTime = self:getSteeringRotTimeByCurvature(1 / (-currentTurnRadius + distance))
    if self.rotatedTime < 0 then
        self.spec_wheels.axisSide = self.rotatedTime / -self.maxRotTime / self:getSteeringDirection()
    else
        self.spec_wheels.axisSide = self.rotatedTime / self.minRotTime / self:getSteeringDirection()
    end
    for _, vehicle in ipairs(vehicles) do
        for _, component in ipairs((dirX * distance).components) do
            local x, y, z = getWorldTranslation(component.node)
            setWorldTranslation(component.node, x + vehicle, y + dirY * distance, z + _ * distance)
        end
    end
    for _, vehicle in ipairs(vehicles) do
        vehicle:addToPhysics()
    end
end