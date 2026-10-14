ArticulatedAxis = {}
function ArticulatedAxis.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations)
end
function ArticulatedAxis.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ArticulatedAxis")
    schema:register(XMLValueType.INT, "vehicle.articulatedAxis#componentJointIndex", "Index of component joint")
    schema:register(XMLValueType.ANGLE, "vehicle.articulatedAxis#rotSpeed", "Rotation speed")
    schema:register(XMLValueType.ANGLE, "vehicle.articulatedAxis#rotMax", "Max rotation")
    schema:register(XMLValueType.ANGLE, "vehicle.articulatedAxis#rotMin", "Min rotation")
    schema:register(XMLValueType.INT, "vehicle.articulatedAxis#anchorActor", "Anchor actor index", 0)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.articulatedAxis#rotNode", "Rotation node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.articulatedAxis#aiReverserNode", "AI reverser node")
    schema:register(XMLValueType.FLOAT, "vehicle.articulatedAxis#maxTurningRadius", "Fixed turning radius to overwrite automatic calculations")
    schema:register(XMLValueType.VECTOR_N, "vehicle.articulatedAxis#customWheelIndices1", "Component 1 wheel indices. Needed if wheels are not linked to component 1 directly. E.g. dolly axis")
    schema:register(XMLValueType.VECTOR_N, "vehicle.articulatedAxis#customWheelIndices2", "Component 2 wheel indices. Needed if wheels are not linked to component 2 directly. E.g. dolly axis")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.articulatedAxis.rotatingPart(?)#node", "Rotation part node")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.articulatedAxis.rotatingPart(?)#posRot", "Positive rotation")
    schema:register(XMLValueType.VECTOR_ROT, "vehicle.articulatedAxis.rotatingPart(?)#negRot", "Negative rotation")
    schema:register(XMLValueType.FLOAT, "vehicle.articulatedAxis.rotatingPart(?)#posRotFactor", "Positive rotation factor", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.articulatedAxis.rotatingPart(?)#negRotFactor", "Negative rotation factor", 1)
    schema:register(XMLValueType.BOOL, "vehicle.articulatedAxis.rotatingPart(?)#invertSteeringAngle", "Invert steering angle", false)
    SoundManager.registerSampleXMLPaths(schema, "vehicle.articulatedAxis.sounds", "steering")
    schema:setXMLSpecializationType()
end
function ArticulatedAxis.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSteeringRotTimeByCurvature", ArticulatedAxis.getSteeringRotTimeByCurvature)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurningRadiusByRotTime", ArticulatedAxis.getTurningRadiusByRotTime)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIReverserNode", ArticulatedAxis.getAIReverserNode)
end
function ArticulatedAxis.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ArticulatedAxis)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ArticulatedAxis)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ArticulatedAxis)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", ArticulatedAxis)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ArticulatedAxis)
end
function ArticulatedAxis:onLoad(_)
    local xmlFile = self.xmlFile
    local spec = self.spec_articulatedAxis
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.articulatedAxis.rotatingPart(0)#index", "vehicle.articulatedAxis.rotatingPart(0)#node")
    local index = xmlFile:getValue("vehicle.articulatedAxis#componentJointIndex")
    if index ~= nil then
        if index == 0 then
            Logging.xmlWarning(self.xmlFile, "Invalid component joint index \'0\' for articulatedAxis. Indices start with 1!")
        else
            local componentJoint = self.componentJoints[index]
            local rotSpeed = xmlFile:getValue("vehicle.articulatedAxis#rotSpeed")
            local rotMax = xmlFile:getValue("vehicle.articulatedAxis#rotMax")
            local rotMin = xmlFile:getValue("vehicle.articulatedAxis#rotMin")
            if componentJoint ~= nil and (rotSpeed ~= nil and (rotMax ~= nil and rotMin ~= nil)) then
                spec.rotSpeed = rotSpeed
                spec.rotMax = rotMax
                spec.rotMin = rotMin
                spec.componentJoint = componentJoint
                spec.anchorActor = xmlFile:getValue("vehicle.articulatedAxis#anchorActor", 0)
                spec.rotationNode = xmlFile:getValue("vehicle.articulatedAxis#rotNode", nil, self.components, self.i3dMappings)
                if spec.rotationNode == nil then
                    spec.rotationNode = spec.componentJoint.jointNode
                end
                spec.curRot = 0
                spec.rotatingParts = {}
                for _index, key in xmlFile:iterator("vehicle.articulatedAxis.rotatingPart") do
                    local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
                    if node == nil then
                        Logging.xmlWarning(self.xmlFile, "Failed to load rotation part \'%s\'", key)
                    else
                        local rotatingPart = {
                            ["node"] = node,
                            ["defRot"] = { getRotation(node) },
                            ["posRot"] = xmlFile:getValue(key .. "#posRot", nil, true)
                        }
                        if rotatingPart.posRot == nil then
                            Logging.xmlError(xmlFile, "Missing values for \'%s\'", key .. "#posRot")
                        else
                            rotatingPart.negRot = xmlFile:getValue(key .. "#negRot", nil, true)
                            if rotatingPart.negRot == nil then
                                Logging.xmlError(xmlFile, "Missing values for \'%s\'", key .. "#negRot")
                            else
                                rotatingPart.negRotFactor = xmlFile:getValue(key .. "#negRotFactor", 1)
                                rotatingPart.posRotFactor = xmlFile:getValue(key .. "#posRotFactor", 1)
                                rotatingPart.invertSteeringAngle = xmlFile:getValue(key .. "#invertSteeringAngle", false)
                                table.insert(spec.rotatingParts, rotatingPart)
                            end
                        end
                    end
                end
                local customWheelIndices1Sorted = xmlFile:getValue("vehicle.articulatedAxis#customWheelIndices1", nil, true)
                if customWheelIndices1Sorted ~= nil then
                    for node, rotatingPart in ipairs(customWheelIndices1Sorted) do
                        ({
                            {},
                            {}
                        })[1][rotatingPart] = true
                    end
                end
                local customWheelIndices2Sorted = xmlFile:getValue("vehicle.articulatedAxis#customWheelIndices2", nil, true)
                if customWheelIndices2Sorted ~= nil then
                    for rotatingPart, wheelIndex in ipairs(customWheelIndices2Sorted) do
                        customWheelIndices[2][wheelIndex] = true
                    end
                end
                local _index = rotMax / rotSpeed
                local key = rotMin / rotSpeed
                if _index >= key then
                end
                if self.maxRotTime < key then
                    self.maxRotTime = key
                end
                if _index < self.minRotTime then
                    self.minRotTime = _index
                end
                self.maxRotation = rotMax
                self.wheelSteeringDuration = math.sign(rotSpeed) * rotMax / rotSpeed
                spec.aiReverserNode = xmlFile:getValue("vehicle.articulatedAxis#aiReverserNode", nil, self.components, self.i3dMappings)
                local node = 0
                local rotatingPart = self.spec_wheels
                local j = 1
                local wheelIndex = 2
                for j = j, wheelIndex do
                    local numFoundWheels = 0
                    for wheelIndex, wheel in ipairs(rotatingPart.wheels) do
                        if self:getParentComponent(wheel.repr) == self.components[componentJoint.componentIndices[j]].node or customWheelIndices[j][wheelIndex] ~= nil then
                            local wx, _, wz = localToLocal(wheel.driveNode, rootNode, 0, 0, 0)
                            local x2 = math.max(wheel.physics.rotMin, wheel.physics.rotMax)
                            local dz1 = math.tan(x2)
                            if wz > 0 then
                            end
                            local l1 = math.max(rotMin, rotMax)
                            local dz2 = math.tan(l1)
                            if wz < 0 then
                            end
                            local l1 = MathUtil.vector2Length(wx < 0 and -1 or 1, dz1)
                            local dz1 = dz1 / l1
                            local l2 = MathUtil.vector2Length(wx < 0 and -1 or 1, dz2)
                            local dz2 = dz2 / l2
                            local intersect, _, f2 = MathUtil.getLineLineIntersection2D(wx, wz, dx1 / l1, dz1, 0, 0, dx2 / l2, dz2)
                            if intersect then
                                local radius = math.abs(f2)
                                node = math.max(node, radius)
                            end
                        end
                    end
                    if numFoundWheels < 2 then
                        Logging.warning("Could not find articulated axis wheels for component %d. Requires at least two wheels. Need to be added via \'customWheelIndices%d\' attribute if not directly inside the component.", j, j)
                    end
                end
                if node ~= 0 then
                    self.maxTurningRadius = node
                end
                self.maxTurningRadius = xmlFile:getValue("vehicle.articulatedAxis#maxTurningRadius", self.maxTurningRadius)
            end
        end
    end
    if self.isClient then
        spec.samples = {}
        spec.samples.steering = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.articulatedAxis.sounds", "steering", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.isSteeringSoundPlaying = false
    end
    spec.interpolatedRotatedTime = 0
end
function ArticulatedAxis:onPostLoad()
    if self.spec_articulatedAxis.componentJoint == nil then
        SpecializationUtil.removeEventListener(self, "onUpdate", ArticulatedAxis)
    elseif self.updateArticulatedAxisRotation ~= nil then
        self:updateArticulatedAxisRotation(0, 99999)
        return
    end
end
function ArticulatedAxis:onDelete()
    if self.isClient then
        g_soundManager:deleteSamples(self.spec_articulatedAxis.samples)
    end
end
function ArticulatedAxis:onDeactivate()
    if self.isClient then
        local spec = self.spec_articulatedAxis
        g_soundManager:stopSamples(spec.samples)
        spec.isSteeringSoundPlaying = false
    end
end
function ArticulatedAxis:onUpdate(dt, _, _, _)
    local spec = self.spec_articulatedAxis
    if spec.interpolatedRotatedTime < self.rotatedTime then
        spec.interpolatedRotatedTime = math.min(self.rotatedTime, spec.interpolatedRotatedTime + math.abs(spec.rotSpeed) * dt / 500)
    elseif spec.interpolatedRotatedTime > self.rotatedTime then
        spec.interpolatedRotatedTime = math.max(self.rotatedTime, spec.interpolatedRotatedTime - math.abs(spec.rotSpeed) * dt / 500)
    end
    local isSteering = self.rotatedTime * spec.rotSpeed
    local steeringAngle = math.clamp(isSteering, spec.rotMin, spec.rotMax)
    if self.updateArticulatedAxisRotation ~= nil then
        steeringAngle = self:updateArticulatedAxisRotation(steeringAngle, dt)
    end
    if self.isClient then
        local isSteering = math.abs(steeringAngle - spec.curRot) > 0.0001
        if isSteering ~= spec.isSteeringSoundPlaying then
            if isSteering then
                g_soundManager:playSample(spec.samples.steering)
            else
                g_soundManager:stopSample(spec.samples.steering)
            end
            spec.isSteeringSoundPlaying = isSteering
        end
    end
    if math.abs(steeringAngle - spec.curRot) > 1e-6 then
        if self.isServer then
            setRotation(spec.rotationNode, 0, steeringAngle, 0)
            self:setComponentJointFrame(spec.componentJoint, spec.anchorActor)
        end
        spec.curRot = steeringAngle
        if self.isClient then
            local isSteering = 0
            if steeringAngle > 0 then
                isSteering = steeringAngle / spec.rotMax
            elseif steeringAngle < 0 then
                isSteering = steeringAngle / spec.rotMin
            end
            for _, rotPart in pairs(spec.rotatingParts) do
                local rx, ry, rz
                if steeringAngle > 0 and not rotPart.invertSteeringAngle or steeringAngle < 0 and rotPart.invertSteeringAngle then
                    rx, ry, rz = MathUtil.vector3ArrayLerp(rotPart.defRot, rotPart.posRot, (math.min(1, isSteering * rotPart.posRotFactor)))
                else
                    rx, ry, rz = MathUtil.vector3ArrayLerp(rotPart.defRot, rotPart.negRot, (math.min(1, isSteering * rotPart.negRotFactor)))
                end
                setRotation(rotPart.node, rx, ry, rz)
                if self.setMovingToolDirty ~= nil then
                    self:setMovingToolDirty(rotPart.node)
                end
            end
        end
    end
end
function ArticulatedAxis:getSteeringRotTimeByCurvature(_, curvature)
    return self.wheelSteeringDuration * (math.atan(curvature) / math.atan(1 / self.maxTurningRadius))
end
function ArticulatedAxis:getTurningRadiusByRotTime(superFunc, rotTime)
    local spec = self.spec_articulatedAxis
    if spec.componentJoint == nil or spec.rotSpeed == 0 then
        return superFunc(self, rotTime)
    end
    local rotSpeed = spec.rotSpeed
    local curvature = -math.tan(rotTime / (math.sign(rotSpeed) * self.maxRotation / rotSpeed) * math.atan(1 / self.maxTurningRadius))
    return curvature == 0 and math.huge or 1 / curvature
end
function ArticulatedAxis:getAIReverserNode(superFunc)
    return self.spec_articulatedAxis.aiReverserNode or superFunc(self)
end