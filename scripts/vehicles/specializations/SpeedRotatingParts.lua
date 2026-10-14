SpeedRotatingParts = {}
SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE = 50
SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY = "vehicle.speedRotatingParts.speedRotatingPart(?)"
function SpeedRotatingParts.prerequisitesPresent(specializations)
    return true
end
function SpeedRotatingParts.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("SpeedRotatingParts")
    schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#node", "Speed rotating part node")
    schema:register(XMLValueType.NODE_INDICES, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#nodes", "Speed rotating part nodes (first node will be used as main repr node and the others just copy the rotation values)")
    schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#shaderNode", "Speed rotating part shader node")
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#useRotation", "Use shader rotation", true)
    schema:register(XMLValueType.VECTOR_2, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#scrollScale", "Shader scroll speed")
    schema:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#shaderComponent", "Shader parameter component to control", "Default based on available shader attributes")
    schema:register(XMLValueType.VECTOR_N, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#shaderComponentSpeeds", "Speed factor for different shader components (usable with \'vtxRotate\' shader variation)")
    schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#scrollLength", "Shader scroll length")
    schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#driveNode", "Drive node to apply x drive", "speedRotatingPart#node")
    schema:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#refComponentIndex", "Reference component index")
    schema:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#wheelIndex", "Reference wheel index")
    schema:register(XMLValueType.NODE_INDICES, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#wheelNodes", "List of reference wheel nodes (repr or drive node). The average speed of the wheels WITH ground contact is used.")
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#hasConfigWheels", "Defined wheels are part of configurations, so no warning is displayed while they are not found.", false)
    schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#dirRefNode", "Direction reference node")
    schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#dirFrameNode", "Direction reference frame")
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#alignDirection", "Align direction", false)
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#applySteeringAngle", "Apply steering angle", false)
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#useWheelReprTranslation", "Apply wheel repr translation", true)
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#updateXDrive", "Update X drive", true)
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#versatileYRot", "Versatile Y rot", false)
    schema:register(XMLValueType.ANGLE, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#minYRot", "Min. Y rotation")
    schema:register(XMLValueType.ANGLE, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#maxYRot", "Max. Y rotation")
    schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#wheelScale", "Wheel scale")
    schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#radius", "Radius", 1)
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#onlyActiveWhenLowered", "Only active if lowered", false)
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#stopIfNotActive", "Stop if not active", false)
    schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#fadeOutTime", "Fade out time", 3)
    schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#activationSpeed", "Min. speed for activation", 1)
    schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#speedReferenceNode", "Speed reference node")
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#hasTireTracks", "Has Tire Tracks", false)
    schema:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackAtlasIndex", "Index on tire track atlas", 0)
    schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackWidth", "Width of tire tracks", 0.5)
    schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackInverted", "Tire track texture inverted", false)
    schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackWheelNode", "Reference wheel for the tire tracks (radius, ground contact, etc)")
    schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#maxUpdateDistance", "Max. distance from current camera to vehicle to update part", SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE)
    schema:setXMLSpecializationType()
end
function SpeedRotatingParts.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadSpeedRotatingPartFromXML", SpeedRotatingParts.loadSpeedRotatingPartFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsSpeedRotatingPartActive", SpeedRotatingParts.getIsSpeedRotatingPartActive)
    SpecializationUtil.registerFunction(vehicleType, "getSpeedRotatingPartDirection", SpeedRotatingParts.getSpeedRotatingPartDirection)
    SpecializationUtil.registerFunction(vehicleType, "updateSpeedRotatingPart", SpeedRotatingParts.updateSpeedRotatingPart)
end
function SpeedRotatingParts.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", SpeedRotatingParts.validateWashableNode)
end
function SpeedRotatingParts.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", SpeedRotatingParts)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SpeedRotatingParts)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SpeedRotatingParts)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", SpeedRotatingParts)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", SpeedRotatingParts)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SpeedRotatingParts)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SpeedRotatingParts)
end
function SpeedRotatingParts:onLoad(_)
    local spec = self.spec_speedRotatingParts
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.speedRotatingParts.speedRotatingPart(0)#index", "vehicle.speedRotatingParts.speedRotatingPart(0)#node")
    local maxUpdateDistance = nil
    spec.individualUpdateDistance = false
    spec.speedRotatingParts = {}
    for _, baseName in self.xmlFile:iterator("vehicle.speedRotatingParts.speedRotatingPart") do
        local speedRotatingPart = {}
        if self:loadSpeedRotatingPartFromXML(speedRotatingPart, self.xmlFile, baseName) then
            table.insert(spec.speedRotatingParts, speedRotatingPart)
            if maxUpdateDistance ~= nil and maxUpdateDistance ~= speedRotatingPart.maxUpdateDistance then
                spec.individualUpdateDistance = true
            end
            maxUpdateDistance = speedRotatingPart.maxUpdateDistance
        elseif speedRotatingPart.tireTrackNodeIndex ~= nil then
            self:removeTireTrackNode(speedRotatingPart.tireTrackNodeIndex)
        end
    end
    spec.maxUpdateDistance = maxUpdateDistance or SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE
    spec.dirtyFlag = self:getNextDirtyFlag()
    if #spec.speedRotatingParts == 0 then
        SpecializationUtil.removeEventListener(self, "onReadStream", SpeedRotatingParts)
        SpecializationUtil.removeEventListener(self, "onWriteStream", SpeedRotatingParts)
        SpecializationUtil.removeEventListener(self, "onReadUpdateStream", SpeedRotatingParts)
        SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", SpeedRotatingParts)
        SpecializationUtil.removeEventListener(self, "onUpdate", SpeedRotatingParts)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", SpeedRotatingParts)
    end
end
function SpeedRotatingParts:onReadStream(streamId, _)
    local spec = self.spec_speedRotatingParts
    local i = 1
    for i = i, #spec.speedRotatingParts do
        local speedRotatingPart = spec.speedRotatingParts[i]
        if speedRotatingPart.versatileYRot then
            speedRotatingPart.steeringAngle = streamReadUIntN(streamId, 9) / 511 * 3.141592653589793 * 2
        end
    end
end
function SpeedRotatingParts:onWriteStream(streamId, _)
    local spec = self.spec_speedRotatingParts
    local i = 1
    for i = i, #spec.speedRotatingParts do
        local speedRotatingPart = spec.speedRotatingParts[i]
        if speedRotatingPart.versatileYRot then
            streamWriteUIntN(streamId, math.clamp(math.floor(speedRotatingPart.steeringAngle % 6.283185307179586 / 6.283185307179586 * 511), 0, 511), 9)
        end
    end
end
function SpeedRotatingParts:onReadUpdateStream(streamId, _, connection)
    if connection.isServer and streamReadBool(streamId) then
        local spec = self.spec_speedRotatingParts
        local i = 1
        for i = i, #spec.speedRotatingParts do
            local speedRotatingPart = spec.speedRotatingParts[i]
            if speedRotatingPart.versatileYRot then
                speedRotatingPart.steeringAngle = streamReadUIntN(streamId, 9) / 511 * 3.141592653589793 * 2
            end
        end
    end
end
function SpeedRotatingParts:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection.isServer then
        local spec = self.spec_speedRotatingParts
        local i = bit32.band(dirtyMask, spec.dirtyFlag) ~= 0
        if streamWriteBool(streamId, i) then
            local i = 1
            for i = i, #spec.speedRotatingParts do
                local speedRotatingPart = spec.speedRotatingParts[i]
                if speedRotatingPart.versatileYRot then
                    streamWriteUIntN(streamId, math.clamp(math.floor(speedRotatingPart.steeringAngle % 6.283185307179586 / 6.283185307179586 * 511), 0, 511), 9)
                end
            end
        end
    end
end
function SpeedRotatingParts:onUpdate(dt, _, _, _)
    local spec = self.spec_speedRotatingParts
    if spec.individualUpdateDistance or self.currentUpdateDistance < spec.maxUpdateDistance then
        local i = 1
        for i = i, #spec.speedRotatingParts do
            local speedRotatingPart = spec.speedRotatingParts[i]
            if (not spec.individualUpdateDistance or self.currentUpdateDistance < speedRotatingPart.maxUpdateDistance) and (speedRotatingPart.isActive or speedRotatingPart.lastSpeed ~= 0 and not speedRotatingPart.stopIfNotActive) then
                self:updateSpeedRotatingPart(speedRotatingPart, dt, speedRotatingPart.isActive)
            end
        end
    end
end
function SpeedRotatingParts:onUpdateTick(_, _, _, _)
    local spec = self.spec_speedRotatingParts
    if spec.individualUpdateDistance or self.currentUpdateDistance < spec.maxUpdateDistance then
        local i = 1
        for i = i, #spec.speedRotatingParts do
            local speedRotatingPart = spec.speedRotatingParts[i]
            if not spec.individualUpdateDistance or self.currentUpdateDistance < speedRotatingPart.maxUpdateDistance then
                speedRotatingPart.isActive = self:getIsSpeedRotatingPartActive(speedRotatingPart)
            end
        end
    end
end
function SpeedRotatingParts:loadSpeedRotatingPartFromXML(speedRotatingPart, xmlFile, key)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#vtxPositionArrayFilename", "Array should be assigned properly inside i3d.")
    speedRotatingPart.reprNodes = xmlFile:getValue(key .. "#nodes", nil, self.components, self.i3dMappings, true)
    speedRotatingPart.repr = xmlFile:getValue(key .. "#node", speedRotatingPart.reprNodes[1], self.components, self.i3dMappings)
    speedRotatingPart.shaderNode = xmlFile:getValue(key .. "#shaderNode", nil, self.components, self.i3dMappings)
    if #speedRotatingPart.reprNodes > 0 and speedRotatingPart.reprNodes[1] == speedRotatingPart.repr then
        table.remove(speedRotatingPart.reprNodes, 1)
    end
    speedRotatingPart.shaderParameterName = "offsetUV"
    speedRotatingPart.shaderParameterPrevName = nil
    speedRotatingPart.shaderParameterComponent = 3
    speedRotatingPart.shaderParameterSpeedScale = 1
    speedRotatingPart.shaderParameterValues = {
        0,
        0,
        0,
        0
    }
    if speedRotatingPart.shaderNode ~= nil then
        speedRotatingPart.useShaderRotation = xmlFile:getValue(key .. "#useRotation", true)
        speedRotatingPart.scrollScale = xmlFile:getValue(key .. "#scrollScale", "1 0", true)
        speedRotatingPart.scrollLength = xmlFile:getValue(key .. "#scrollLength")
        if getHasShaderParameter(speedRotatingPart.shaderNode, "rotationAngle") then
            speedRotatingPart.shaderParameterName = "rotationAngle"
            speedRotatingPart.shaderParameterPrevName = "prevRotationAngle"
            speedRotatingPart.shaderParameterComponent = 1
            speedRotatingPart.shaderParameterSpeedScale = -1
        end
        if getHasShaderParameter(speedRotatingPart.shaderNode, "scrollPos") then
            speedRotatingPart.shaderParameterName = "scrollPos"
            speedRotatingPart.shaderParameterPrevName = "prevScrollPos"
            speedRotatingPart.shaderParameterComponent = 1
            speedRotatingPart.shaderParameterSpeedScale = 1
        end
        speedRotatingPart.shaderParameterComponent = xmlFile:getValue(key .. "#shaderComponent", speedRotatingPart.shaderParameterComponent)
        speedRotatingPart.shaderComponentSpeeds = xmlFile:getValue(key .. "#shaderComponentSpeeds", nil, true)
    end
    if speedRotatingPart.repr == nil and speedRotatingPart.shaderNode == nil then
        local wheel = getXMLString(xmlFile.handle, key .. "#node") or getXMLString(xmlFile.handle, key .. "#shaderNode")
        Logging.xmlWarning(self.xmlFile, "Invalid speedRotationPart node \'%s\' in \'%s\'", tostring(wheel), key)
        return false
    end
    speedRotatingPart.driveNode = xmlFile:getValue(key .. "#driveNode", speedRotatingPart.repr, self.components, self.i3dMappings)
    local componentIndex = xmlFile:getValue(key .. "#refComponentIndex")
    if componentIndex == nil or self.components[componentIndex] == nil then
        speedRotatingPart.componentNode = self:getParentComponent((Utils.getNoNil(speedRotatingPart.driveNode, speedRotatingPart.shaderNode)))
    else
        speedRotatingPart.componentNode = self.components[componentIndex].node
    end
    speedRotatingPart.xDrive = 0
    local node = xmlFile:getValue(key .. "#wheelIndex")
    local wheelNodes = xmlFile:getValue(key .. "#wheelNodes", nil, self.components, self.i3dMappings, true)
    if node ~= nil or #wheelNodes > 0 then
        if self.getWheels == nil then
            Logging.xmlWarning(self.xmlFile, "wheelIndex for speedRotatingPart \'%s\' given, but no wheels loaded/defined", key)
        else
            local wheels = {}
            if node ~= nil then
                local wheel = self:getWheelFromWheelIndex(node)
                if wheel == nil then
                    if not xmlFile:getValue(key .. "#hasConfigWheels", false) then
                        Logging.xmlWarning(self.xmlFile, "Invalid wheel index \'%s\' for speedRotatingPart \'%s\'", node, key)
                    end
                else
                    table.insert(wheels, wheel)
                end
            end
            if #wheelNodes > 0 then
                for _, wheelNode in ipairs(wheelNodes) do
                    local wheel = self:getWheelByWheelNode(wheelNode)
                    if wheel == nil then
                        if not xmlFile:getValue(key .. "#hasConfigWheels", false) then
                            Logging.xmlWarning(self.xmlFile, "Invalid wheel node \'%s\' for speedRotatingPart \'%s\'", getName(wheelNode), key)
                        end
                    else
                        table.insert(wheels, wheel)
                    end
                end
            end
            if #wheels == 0 then
                return false
            end
            for _, wheelNode in ipairs(wheels) do
                wheelNode.syncContactState = true
                if not wheelNode.physics.isSynchronized then
                    Logging.xmlWarning(self.xmlFile, "Referenced wheel \'%s\' for speedRotatingPart \'%s\' is not synchronized in multiplayer", getName(wheelNode.repr), key)
                end
            end
            speedRotatingPart.wheels = wheels
            speedRotatingPart.lastWheelXRot = {}
        end
    end
    speedRotatingPart.hasTireTracks = xmlFile:getValue(key .. "#hasTireTracks", false)
    speedRotatingPart.tireTrackAtlasIndex = xmlFile:getValue(key .. "#tireTrackAtlasIndex", 0)
    speedRotatingPart.tireTrackWidth = xmlFile:getValue(key .. "#tireTrackWidth", 0.5)
    speedRotatingPart.tireTrackInverted = xmlFile:getValue(key .. "#tireTrackInverted", false)
    speedRotatingPart.tireTrackWheelNode = xmlFile:getValue(key .. "#tireTrackWheelNode", nil, self.components, self.i3dMappings)
    if speedRotatingPart.hasTireTracks and Platform.gameplay.wheelTireTracks then
        local wheel
        if speedRotatingPart.wheels == nil then
            if speedRotatingPart.tireTrackWheelNode == nil then
                Logging.xmlWarning(self.xmlFile, "Tire tracks for speedRotationPart \'%s\' defined, but no wheels or tireTrackWheelNode given", key)
                return false
            end
            wheel = self:getWheelByWheelNode(speedRotatingPart.tireTrackWheelNode)
        else
            wheel = speedRotatingPart.wheels[1]
        end
        speedRotatingPart.tireTrackNodeIndex = self:addTireTrackNode(wheel, speedRotatingPart.componentNode, speedRotatingPart.driveNode, speedRotatingPart.tireTrackAtlasIndex, speedRotatingPart.tireTrackWidth, wheel.physics.radius, speedRotatingPart.tireTrackInverted, function()
            -- upvalues: (copy) self, (copy) speedRotatingPart
            return self:getIsSpeedRotatingPartActive(speedRotatingPart)
        end)
    end
    speedRotatingPart.dirRefNode = xmlFile:getValue(key .. "#dirRefNode", nil, self.components, self.i3dMappings)
    speedRotatingPart.dirFrameNode = xmlFile:getValue(key .. "#dirFrameNode", nil, self.components, self.i3dMappings)
    speedRotatingPart.alignDirection = xmlFile:getValue(key .. "#alignDirection", false)
    speedRotatingPart.applySteeringAngle = xmlFile:getValue(key .. "#applySteeringAngle", false)
    speedRotatingPart.useWheelReprTranslation = xmlFile:getValue(key .. "#useWheelReprTranslation", true)
    speedRotatingPart.updateXDrive = xmlFile:getValue(key .. "#updateXDrive", true)
    speedRotatingPart.versatileYRot = xmlFile:getValue(key .. "#versatileYRot", false)
    if speedRotatingPart.versatileYRot and speedRotatingPart.repr == nil then
        Logging.xmlWarning(self.xmlFile, "Versatile speedRotationPart \'%s\' does not support shaderNodes", key)
        return false
    end
    speedRotatingPart.minYRot = xmlFile:getValue(key .. "#minYRot")
    speedRotatingPart.maxYRot = xmlFile:getValue(key .. "#maxYRot")
    speedRotatingPart.steeringAngle = 0
    speedRotatingPart.steeringAngleSent = 0
    speedRotatingPart.speedReferenceNode = xmlFile:getValue(key .. "#speedReferenceNode", nil, self.components, self.i3dMappings)
    if speedRotatingPart.speedReferenceNode ~= nil and speedRotatingPart.speedReferenceNode == speedRotatingPart.driveNode then
        Logging.xmlWarning(self.xmlFile, "Ignoring speedRotationPart \'%s\' because speedReferenceNode is identical with driveNode. Need to be different!", key)
        return false
    end
    speedRotatingPart.wheelScale = xmlFile:getValue(key .. "#wheelScale")
    if speedRotatingPart.wheelScale == nil then
        local wheels = 1
        local wheel = 1
        if speedRotatingPart.wheels ~= nil and speedRotatingPart.speedReferenceNode == nil then
            wheels = speedRotatingPart.wheels[1].physics.radius
            wheel = speedRotatingPart.wheels[1].physics.radius
        end
        speedRotatingPart.wheelScale = wheels / xmlFile:getValue(key .. "#radius", wheel)
    end
    speedRotatingPart.wheelScaleBackup = speedRotatingPart.wheelScale
    speedRotatingPart.onlyActiveWhenLowered = xmlFile:getValue(key .. "#onlyActiveWhenLowered", false)
    speedRotatingPart.stopIfNotActive = xmlFile:getValue(key .. "#stopIfNotActive", false)
    speedRotatingPart.fadeOutTime = xmlFile:getValue(key .. "#fadeOutTime", 3) * 1000
    speedRotatingPart.activationSpeed = xmlFile:getValue(key .. "#activationSpeed", 1)
    speedRotatingPart.lastSpeed = 0
    speedRotatingPart.lastDir = 1
    speedRotatingPart.maxUpdateDistance = xmlFile:getValue(key .. "#maxUpdateDistance", SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE)
    if self.isServer and speedRotatingPart.versatileYRot then
        speedRotatingPart.maxUpdateDistance = math.huge
    end
    return true
end
function SpeedRotatingParts:getIsSpeedRotatingPartActive(speedRotatingPart)
    return not speedRotatingPart.onlyActiveWhenLowered and true or ((self.getIsLowered == nil or self:getIsLowered()) and true or false)
end
function SpeedRotatingParts:getSpeedRotatingPartDirection(speedRotatingPart)
    return 1
end
function SpeedRotatingParts:updateSpeedRotatingPart(speedRotatingPart, dt, isPartActive)
    local speed = speedRotatingPart.lastSpeed
    local dir = speedRotatingPart.lastDir
    if speedRotatingPart.repr ~= nil and (self.isServer or not speedRotatingPart.versatileYRot) then
        local newY, newZ, dx = getRotation(speedRotatingPart.repr)
        speedRotatingPart.steeringAngle = newZ
    end
    local speed
    if not isPartActive then
        local newY = speed - speedRotatingPart.brakeForce
        speed = math.max(newY, 0)
        if speedRotatingPart.wheels ~= nil then
            for dx, dy in pairs(speedRotatingPart.lastWheelXRot) do
                speedRotatingPart.lastWheelXRot[dx] = nil
            end
        end
        ::l43::
        speedRotatingPart.lastSpeed = speed
        speedRotatingPart.lastDir = dir
        if speedRotatingPart.updateXDrive then
            speedRotatingPart.xDrive = (speedRotatingPart.xDrive + speed * dir * self:getSpeedRotatingPartDirection(speedRotatingPart) * speedRotatingPart.wheelScale) % 6.283185307179586
        end
        if speedRotatingPart.versatileYRot then
            if speed > 0.0017 and (self.isServer and self:getLastSpeed(true) > speedRotatingPart.activationSpeed) then
                local _, newY, newZ = localToLocal(speedRotatingPart.repr, speedRotatingPart.componentNode, 0, 0, 0)
                speedRotatingPart.steeringAngle = Utils.getVersatileRotation(speedRotatingPart.repr, speedRotatingPart.componentNode, dt, _, newY, newZ, speedRotatingPart.steeringAngle, speedRotatingPart.minYRot, speedRotatingPart.maxYRot)
                local dx = math.floor(speedRotatingPart.steeringAngle % 6.283185307179586 / 6.283185307179586 * 511)
                if dx ~= speedRotatingPart.steeringAngleSent then
                    speedRotatingPart.steeringAngleSent = dx
                    self:raiseDirtyFlags(self.spec_speedRotatingParts.dirtyFlag)
                end
            end
        else
            if speedRotatingPart.componentNode ~= nil and (speedRotatingPart.dirRefNode ~= nil and not speedRotatingPart.alignDirection) then
                speedRotatingPart.steeringAngle = Utils.getYRotationBetweenNodes(speedRotatingPart.componentNode, speedRotatingPart.dirRefNode)
                local _, newY, newZ = localToLocal(speedRotatingPart.driveNode, speedRotatingPart.wheels[1].driveNode, 0, 0, 0)
                setTranslation(speedRotatingPart.driveNode, 0, newY, 0)
            end
            if speedRotatingPart.dirRefNode ~= nil and speedRotatingPart.alignDirection then
                local _, newY, newZ = localDirectionToWorld(speedRotatingPart.dirFrameNode, 0, 1, 0)
                local dx, dy, dz = localDirectionToWorld(speedRotatingPart.dirRefNode, 0, 0, 1)
                I3DUtil.setWorldDirection(speedRotatingPart.repr, dx, dy, dz, _, newY, newZ, 2)
                if speedRotatingPart.wheels ~= nil and speedRotatingPart.useWheelReprTranslation then
                    local i, wheel, rotDiff = localToLocal(speedRotatingPart.wheels[1].driveNode, getParent(speedRotatingPart.repr), 0, 0, 0)
                    setTranslation(speedRotatingPart.repr, 0, wheel, 0)
                end
            end
        end
        if speedRotatingPart.driveNode ~= nil then
            if speedRotatingPart.repr == speedRotatingPart.driveNode then
                local _ = speedRotatingPart.steeringAngle
                local _ = not speedRotatingPart.applySteeringAngle and 0 or _
                setRotation(speedRotatingPart.repr, speedRotatingPart.xDrive, _, 0)
                for dy, dz in ipairs(speedRotatingPart.reprNodes) do
                    setRotation(dz, speedRotatingPart.xDrive, _, 0)
                end
            else
                if not speedRotatingPart.alignDirection and (speedRotatingPart.versatileYRot or speedRotatingPart.applySteeringAngle) then
                    setRotation(speedRotatingPart.repr, 0, speedRotatingPart.steeringAngle, 0)
                    for dx, dy in ipairs(speedRotatingPart.reprNodes) do
                        setRotation(dy, 0, speedRotatingPart.steeringAngle, 0)
                    end
                end
                setRotation(speedRotatingPart.driveNode, speedRotatingPart.xDrive, 0, 0)
            end
        end
        if speedRotatingPart.shaderNode ~= nil then
            if speedRotatingPart.useShaderRotation then
                if speedRotatingPart.shaderComponentSpeeds == nil then
                    if speedRotatingPart.scrollLength == nil then
                        speedRotatingPart.shaderParameterValues[speedRotatingPart.shaderParameterComponent] = speedRotatingPart.xDrive * speedRotatingPart.shaderParameterSpeedScale
                    else
                        _[speedRotatingPart.shaderParameterComponent] = speedRotatingPart.xDrive * speedRotatingPart.shaderParameterSpeedScale % speedRotatingPart.scrollLength
                    end
                else
                    for dy, dz in ipairs(speedRotatingPart.shaderComponentSpeeds) do
                        if speedRotatingPart.scrollLength == nil then
                            _[dy] = speedRotatingPart.xDrive * speedRotatingPart.shaderParameterSpeedScale * dz
                        else
                            _[dy] = speedRotatingPart.xDrive * speedRotatingPart.shaderParameterSpeedScale * dz % speedRotatingPart.scrollLength
                        end
                    end
                end
                if speedRotatingPart.shaderParameterPrevName == nil then
                    setShaderParameter(speedRotatingPart.shaderNode, speedRotatingPart.shaderParameterName, _[1], _[2], _[3], _[4], false)
                else
                    g_animationManager:setPrevShaderParameter(speedRotatingPart.shaderNode, speedRotatingPart.shaderParameterName, _[1], _[2], _[3], _[4], false, speedRotatingPart.shaderParameterPrevName)
                end
            end
            local _ = speedRotatingPart.xDrive % 3.141592653589793 / 6.283185307179586
            setShaderParameter(speedRotatingPart.shaderNode, "offsetUV", _ * speedRotatingPart.scrollScale[1], _ * speedRotatingPart.scrollScale[2], 0, 0, false)
        end
        return
    end
    if speedRotatingPart.speedReferenceNode ~= nil then
        local _, newY, newZ = getWorldTranslation(speedRotatingPart.speedReferenceNode)
        if speedRotatingPart.lastPosition == nil then
            speedRotatingPart.lastPosition = { _, newY, newZ }
        end
        local dx, dy, dz = worldDirectionToLocal(speedRotatingPart.speedReferenceNode, _ - speedRotatingPart.lastPosition[1], newY - speedRotatingPart.lastPosition[2], newZ - speedRotatingPart.lastPosition[3])
        speed = MathUtil.vector3Length(dx, dy, dz)
        dir = dz > 0.001 and 1 or (dz < -0.001 and -1 or 0)
        speedRotatingPart.lastPosition[1] = _
        speedRotatingPart.lastPosition[2] = newY
        speedRotatingPart.lastPosition[3] = newZ
        ::l16::
        speedRotatingPart.brakeForce = speed * dt / speedRotatingPart.fadeOutTime
        goto l43
    end
    if speedRotatingPart.wheels == nil then
        speed = self.lastSpeedReal * dt
        dir = self.movingDirection
        goto l16
    end
    local _ = 0
    for dy, dz in ipairs(speedRotatingPart.wheels) do
        if dz.physics.contact ~= WheelContactType.NONE then
        end
    end
    local newY = 0
    local newZ = 0
    dir = 0
    for i, wheel in ipairs(speedRotatingPart.wheels) do
        if speedRotatingPart.lastWheelXRot[i] == nil then
            speedRotatingPart.lastWheelXRot[i] = wheel.physics.netInfo.xDrive
        end
        if wheel.physics.contact == WheelContactType.NONE then
            if _ == 0 then
                if math.abs(wheel.physics.netInfo.xDriveSpeed) > 0.01 then
                    goto l28
                end
            end
            if #speedRotatingPart.wheels ~= 1 then
                goto l31
            end
            goto l28
        end
        ::l28::
        local rotDiff = wheel.physics.netInfo.xDrive - speedRotatingPart.lastWheelXRot[i]
        if rotDiff > 3.141592653589793 then
        elseif rotDiff < -3.141592653589793 then
        end
        newY = newY + math.abs(rotDiff)
        if math.sign(rotDiff) ~= 0 then
            dir = math.sign(rotDiff)
        end
        ::l31::
        speedRotatingPart.lastWheelXRot[i] = wheel.physics.netInfo.xDrive
    end
    if newZ > 0 then
        speed = newY / newZ
    else
        speed = 0
    end
    if not speedRotatingPart.versatileYRot then
        local dy, dz, i = getRotation(speedRotatingPart.wheels[1].repr)
        speedRotatingPart.steeringAngle = dz
    end
    goto l16
end
function SpeedRotatingParts:validateWashableNode(superFunc, node)
    for _, speedRotatingPart in pairs(self.spec_speedRotatingParts.speedRotatingParts) do
        if speedRotatingPart.wheels ~= nil then
            local speedRotatingPartsNodes = {}
            if speedRotatingPart.repr ~= nil then
                I3DUtil.getNodesByShaderParam(speedRotatingPart.repr, "scratches_dirt_snow_wetness", speedRotatingPartsNodes)
            end
            for _, repr in ipairs(speedRotatingPart.reprNodes) do
                I3DUtil.getNodesByShaderParam(repr, "scratches_dirt_snow_wetness", speedRotatingPartsNodes)
            end
            if speedRotatingPart.shaderNode ~= nil then
                I3DUtil.getNodesByShaderParam(speedRotatingPart.shaderNode, "scratches_dirt_snow_wetness", speedRotatingPartsNodes)
            end
            if speedRotatingPart.driveNode ~= nil then
                I3DUtil.getNodesByShaderParam(speedRotatingPart.driveNode, "scratches_dirt_snow_wetness", speedRotatingPartsNodes)
            end
            if speedRotatingPartsNodes[node] ~= nil then
                local nodeData = {
                    ["wheel"] = speedRotatingPart.wheels[1]
                }
                nodeData.fieldDirtMultiplier = nodeData.wheel.physics.fieldDirtMultiplier
                nodeData.streetDirtMultiplier = nodeData.wheel.physics.streetDirtMultiplier
                nodeData.waterWetnessFactor = nodeData.wheel.physics.waterWetnessFactor
                nodeData.minDirtPercentage = nodeData.wheel.physics.minDirtPercentage
                nodeData.maxDirtOffset = nodeData.wheel.physics.maxDirtOffset
                nodeData.dirtColorChangeSpeed = nodeData.wheel.physics.dirtColorChangeSpeed
                nodeData.isSnowNode = true
                return false, self.updateWheelDirtAmount, nodeData.wheel, nodeData
            end
        end
    end
    return superFunc(self, node)
end