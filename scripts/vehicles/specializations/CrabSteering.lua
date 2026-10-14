source("dataS/scripts/vehicles/specializations/events/SetCrabSteeringEvent.lua")
CrabSteering = {}
source("dataS/scripts/gui/hud/extensions/CrabSteeringHUDExtension.lua")
CrabSteering.STEERING_SEND_NUM_BITS = 3
function CrabSteering.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations) and SpecializationUtil.hasSpecialization(Wheels, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end
function CrabSteering.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("CrabSteering")
    schema:register(XMLValueType.FLOAT, "vehicle.crabSteering#distFromCompJointToCenterOfBackWheels", "Distance from component joint to center of back wheels")
    schema:register(XMLValueType.FLOAT, "vehicle.crabSteering#aiSteeringModeIndex", "AI steering mode index", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.crabSteering#toggleSpeedFactor", "Toggle speed factor", 1)
    CrabSteering.registerSteeringModeXMLPaths(schema, "vehicle.crabSteering.steeringMode(?)")
    CrabSteering.registerSteeringModeXMLPaths(schema, "vehicle.crabSteering.crabSteeringConfiguration(?).steeringMode(?)")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.crabSteering.dashboards", { "state" })
    Dashboard.addDelayedRegistrationFunc(schema, function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. "#states", "Crab steering states which activate the dashboard")
    end)
    schema:register(XMLValueType.INT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).wheels#crabSteeringIndex", "Crab steering configuration index")
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).crabSteering#state", "Current steering mode", 1)
end
function CrabSteering.registerSteeringModeXMLPaths(schema, basePath)
    schema:addDelayedRegistrationPath(basePath, "CrabSteering:steeringMode")
    schema:register(XMLValueType.L10N_STRING, basePath .. "#name", "Steering mode name")
    schema:register(XMLValueType.STRING, basePath .. "#inputBindingName", "Input action name")
    schema:register(XMLValueType.INT, basePath .. ".wheel(?)#index", "Wheel Index")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wheel(?)#node", "Wheel Node")
    schema:register(XMLValueType.ANGLE, basePath .. ".wheel(?)#offset", "Rotation offset", 0)
    schema:register(XMLValueType.BOOL, basePath .. ".wheel(?)#locked", "Steering is locked", false)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".steeringCenter#node", "Custom steering center node")
    schema:register(XMLValueType.FLOAT, basePath .. ".steeringCenter#turningRadius", "Turning radius to use with custom steering node")
    schema:register(XMLValueType.FLOAT, basePath .. ".aiAutomaticSteering#lookAheadDistance", "Distance for aiming onto the wayline when this steering mode is active")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".steeringNode(?)#node", "Steering node")
    schema:register(XMLValueType.ANGLE, basePath .. ".steeringNode(?)#offset", "Rotation offset", 0)
    schema:register(XMLValueType.BOOL, basePath .. ".steeringNode(?)#locked", "Steering is locked", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".steeringNode(?)#rotScale", "Scale of rotation")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Node to adjust when the steering mode is active")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".node(?)#rotation", "Rotation when steering mode is active")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".node(?)#translation", "Translation when steering mode is active")
    schema:register(XMLValueType.ANGLE, basePath .. ".articulatedAxis#offset", "Articulated axis offset angle", 0)
    schema:register(XMLValueType.BOOL, basePath .. ".articulatedAxis#locked", "Articulated axis is locked", false)
    schema:register(XMLValueType.VECTOR_N, basePath .. ".articulatedAxis#wheelIndices", "Wheel indices")
    schema:register(XMLValueType.STRING, basePath .. ".animation(?)#name", "Change animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".animation(?)#speed", "Animation speed", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".animation(?)#stopTime", "Animation stop time")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".steeringWheel#node", "Steering wheel node")
    schema:register(XMLValueType.ANGLE, basePath .. ".steeringWheel#indoorRotation", "Steering wheel indoor rotation", 0)
    schema:register(XMLValueType.ANGLE, basePath .. ".steeringWheel#outdoorRotation", "Steering wheel outdoor rotation", 0)
end
function CrabSteering.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadCrabSteeringModeFromXML", CrabSteering.loadCrabSteeringModeFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getCanToggleCrabSteering", CrabSteering.getCanToggleCrabSteering)
    SpecializationUtil.registerFunction(vehicleType, "getCrabSteeringModeAvailable", CrabSteering.getCrabSteeringModeAvailable)
    SpecializationUtil.registerFunction(vehicleType, "getNumCrabSteeringModesAvailable", CrabSteering.getNumCrabSteeringModesAvailable)
    SpecializationUtil.registerFunction(vehicleType, "setCrabSteering", CrabSteering.setCrabSteering)
    SpecializationUtil.registerFunction(vehicleType, "getCrabSteeringMode", CrabSteering.getCrabSteeringMode)
    SpecializationUtil.registerFunction(vehicleType, "setNextCrabSteeringMode", CrabSteering.setNextCrabSteeringMode)
    SpecializationUtil.registerFunction(vehicleType, "updateArticulatedAxisRotation", CrabSteering.updateArticulatedAxisRotation)
end
function CrabSteering.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWheelFromXML", CrabSteering.loadWheelFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateSteeringAngle", CrabSteering.updateSteeringAngle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", CrabSteering.getCanBeSelected)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWheelsFromXML", CrabSteering.loadWheelsFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateSteeringWheel", CrabSteering.updateSteeringWheel)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "startFieldWorker", CrabSteering.startFieldWorker)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIAutomaticSteeringLookAheadDistance", CrabSteering.getAIAutomaticSteeringLookAheadDistance)
end
function CrabSteering.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", CrabSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", CrabSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", CrabSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", CrabSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CrabSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CrabSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", CrabSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", CrabSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", CrabSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", CrabSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CrabSteering)
end
function CrabSteering:onLoad(_)
    local spec = self.spec_crabSteering
    spec.state = 1
    spec.stateMax = -1
    spec.configurationIndex = spec.configurationIndex or 1
    spec.distFromCompJointToCenterOfBackWheels = self.xmlFile:getValue("vehicle.crabSteering#distFromCompJointToCenterOfBackWheels")
    spec.aiSteeringModeIndex = self.xmlFile:getValue("vehicle.crabSteering#aiSteeringModeIndex", 1)
    spec.toggleSpeedFactor = self.xmlFile:getValue("vehicle.crabSteering#toggleSpeedFactor", 1)
    spec.currentArticulatedAxisOffset = 0
    spec.articulatedAxisOffsetChanged = false
    spec.articulatedAxisLastAngle = 0
    spec.articulatedAxisChangingTime = 0
    local configKey = string.format("vehicle.crabSteering.crabSteeringConfiguration(%d)", spec.configurationIndex - 1)
    local baseKey = not self.xmlFile:hasProperty(configKey) and "vehicle.crabSteering" or configKey
    spec.steeringModes = {}
    for _, key in self.xmlFile:iterator(baseKey .. ".steeringMode") do
        local mode = {}
        if self:loadCrabSteeringModeFromXML(self.xmlFile, key, mode) then
            table.insert(spec.steeringModes, mode)
            mode.index = #spec.steeringModes
        end
    end
    spec.stateMax = #spec.steeringModes
    if spec.stateMax > 2 ^ CrabSteering.STEERING_SEND_NUM_BITS - 1 then
        Logging.xmlError(self.xmlFile, "CrabSteering only supports %d steering modes!", 2 ^ CrabSteering.STEERING_SEND_NUM_BITS - 1)
    end
    spec.hasSteeringModes = spec.stateMax > 0
    if spec.hasSteeringModes then
        self.customSteeringAngleFunction = true
        spec.hudExtension = CrabSteeringHUDExtension.new(self)
        self:setCrabSteering(1, true)
    else
        SpecializationUtil.removeEventListener(self, "onReadStream", CrabSteering)
        SpecializationUtil.removeEventListener(self, "onWriteStream", CrabSteering)
        SpecializationUtil.removeEventListener(self, "onReadUpdateStream", CrabSteering)
        SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", CrabSteering)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", CrabSteering)
        SpecializationUtil.removeEventListener(self, "onDraw", CrabSteering)
        SpecializationUtil.removeEventListener(self, "onAIImplementStart", CrabSteering)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", CrabSteering)
    end
end
function CrabSteering:onPostLoad(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local spec = self.spec_crabSteering
        if spec.hasSteeringModes and savegame.xmlFile:hasProperty(savegame.key .. ".crabSteering") then
            local state = savegame.xmlFile:getValue(savegame.key .. ".crabSteering#state", 1)
            self:setCrabSteering(math.clamp(state, 1, spec.stateMax), true)
            AnimatedVehicle.updateAnimations(self, 99999999, true)
            self:forceUpdateWheelPhysics(99999999)
        end
    end
end
function CrabSteering:onDelete()
    local spec = self.spec_crabSteering
    if spec.hudExtension ~= nil then
        spec.hudExtension:delete()
    end
end
function CrabSteering:onRegisterDashboardValueTypes()
    local spec = self.spec_crabSteering
    local state = DashboardValueType.new("crabSteering", "state")
    state:setValue(spec, function(_, dashboard)
        -- upvalues: (copy) spec
        if dashboard.crabSteeringStates == nil then
            return spec.state
        end
        local isStateActive = false
        for _, state in pairs(dashboard.crabSteeringStates) do
            if spec.state == state then
                isStateActive = true
            end
        end
        return isStateActive
    end)
    state:setAdditionalFunctions(function(_, xmlFile, key, dashboard, _)
        dashboard.crabSteeringStates = xmlFile:getValue(key .. "#states", nil, true)
        return true
    end)
    state:setPollUpdate(false)
    self:registerDashboardValueType(state)
end
function CrabSteering:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_crabSteering
    if spec.hasSteeringModes then
        xmlFile:setValue(key .. "#state", spec.state)
    end
end
function CrabSteering:onReadStream(streamId, _)
    self:setCrabSteering(streamReadUIntN(streamId, CrabSteering.STEERING_SEND_NUM_BITS), true)
    AnimatedVehicle.updateAnimations(self, 99999999, true)
    self:forceUpdateWheelPhysics(99999999)
end
function CrabSteering:onWriteStream(streamId, _)
    streamWriteUIntN(streamId, self.spec_crabSteering.state, CrabSteering.STEERING_SEND_NUM_BITS)
end
function CrabSteering:onReadUpdateStream(streamId, _, _)
    local specArticulatedAxis = self.spec_articulatedAxis
    if specArticulatedAxis ~= nil and specArticulatedAxis.componentJoint ~= nil then
        specArticulatedAxis.curRot = streamReadFloat32(streamId)
    end
end
function CrabSteering:onWriteUpdateStream(streamId, _, _)
    local specArticulatedAxis = self.spec_articulatedAxis
    if specArticulatedAxis ~= nil and specArticulatedAxis.componentJoint ~= nil then
        streamWriteFloat32(streamId, specArticulatedAxis.curRot)
    end
end
function CrabSteering:onUpdateTick(_, _, _, _)
    if self.isServer then
        local spec = self.spec_crabSteering
        if not self:getCrabSteeringModeAvailable(spec.steeringModes[spec.state]) then
            self:setNextCrabSteeringMode(1)
        end
    end
end
function CrabSteering:onDraw()
    local spec = self.spec_crabSteering
    if spec.hudExtension ~= nil then
        g_currentMission.hud:addHelpExtension(spec.hudExtension)
    end
end
function CrabSteering:loadCrabSteeringModeFromXML(_, key, mode)
    mode.name = self.xmlFile:getValue(key .. "#name", "", self.customEnvironment, false)
    local inputBindingName = self.xmlFile:getValue(key .. "#inputBindingName")
    if inputBindingName ~= nil then
        if InputAction[inputBindingName] == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid inputBindingname \'%s\' for \'%s\'", tostring(inputBindingName), key)
        else
            mode.inputAction = InputAction[inputBindingName]
        end
    end
    mode.steeringCenterNode = self.xmlFile:getValue(key .. ".steeringCenter#node", nil, self.components, self.i3dMappings)
    mode.turningRadius = self.xmlFile:getValue(key .. ".steeringCenter#turningRadius")
    mode.automaticSteeringLookAheadDistance = self.xmlFile:getValue(key .. ".aiAutomaticSteering#lookAheadDistance")
    mode.wheels = {}
    for _, wheelKey in self.xmlFile:iterator(key .. ".wheel") do
        local wheelEntry = {
            ["wheelIndex"] = self.xmlFile:getValue(wheelKey .. "#index"),
            ["wheelNode"] = self.xmlFile:getValue(wheelKey .. "#node", nil, self.components, self.i3dMappings)
        }
        if wheelEntry.wheelNode == nil then
            ::l8::
            wheelEntry.offset = self.xmlFile:getValue(wheelKey .. "#offset", 0)
            wheelEntry.locked = self.xmlFile:getValue(wheelKey .. "#locked", false)
            if wheelEntry.wheelIndex == nil then
                ::l15::
                table.insert(mode.wheels, wheelEntry)
            else
                wheelEntry.wheel = self:getWheelFromWheelIndex(wheelEntry.wheelIndex)
                if wheelEntry.wheel ~= nil then
                    goto l15
                end
                Logging.xmlError(self.xmlFile, "Invalid wheel \'%s\' for \'%s\'", tostring(wheelEntry.wheelIndex), wheelKey)
            end
        else
            local wheel = self:getWheelByWheelNode(wheelEntry.wheelNode)
            if wheel == nil then
                Logging.xmlError(self.xmlFile, "Invalid wheel node \'%s\' for \'%s\'", self.xmlFile:getString(wheelKey .. "#node"), wheelKey)
            else
                if wheel.physics.rotSpeed ~= 0 then
                    wheelEntry.wheelIndex = wheel.wheelIndex
                    wheelEntry.wheel = wheel
                    goto l8
                end
                Logging.xmlError(self.xmlFile, "Invalid wheel node \'%s\' for \'%s\'. Wheel needs to have a rotSpeed defined!", self.xmlFile:getString(wheelKey .. "#node"), wheelKey)
            end
        end
    end
    mode.steeringNodes = {}
    for _, wheelKey in self.xmlFile:iterator(key .. ".steeringNode") do
        local wheelEntry = {
            ["node"] = self.xmlFile:getValue(wheelKey .. "#node", nil, self.components, self.i3dMappings)
        }
        if wheelEntry.node ~= nil then
            local wheel = self:getSteeringNodeByNode(wheelEntry.node)
            if wheel == nil then
                Logging.xmlError(self.xmlFile, "Invalid steering node \'%s\' for \'%s\'", getName(wheelEntry.node), wheelKey)
            else
                wheelEntry.steeringNode = wheel
                wheelEntry.offset = self.xmlFile:getValue(wheelKey .. "#offset", 0)
                wheelEntry.locked = self.xmlFile:getValue(wheelKey .. "#locked", false)
                wheelEntry.rotScale = self.xmlFile:getValue(wheelKey .. "#rotScale")
                table.insert(mode.steeringNodes, wheelEntry)
            end
        end
    end
    mode.nodes = {}
    for _, wheelKey in self.xmlFile:iterator(key .. ".node") do
        local wheelEntry = {
            ["node"] = self.xmlFile:getValue(wheelKey .. "#node", nil, self.components, self.i3dMappings)
        }
        if wheelEntry.node ~= nil then
            wheelEntry.rotation = self.xmlFile:getValue(wheelKey .. "#rotation", nil, true)
            wheelEntry.translation = self.xmlFile:getValue(wheelKey .. "#translation", nil, true)
            table.insert(mode.nodes, wheelEntry)
        end
    end
    local specArticulatedAxis = self.spec_articulatedAxis
    if specArticulatedAxis ~= nil and specArticulatedAxis.componentJoint ~= nil then
        mode.articulatedAxis = {}
        mode.articulatedAxis.rotSpeedBackUp = specArticulatedAxis.rotSpeed
        mode.articulatedAxis.offset = self.xmlFile:getValue(key .. ".articulatedAxis#offset", 0)
        mode.articulatedAxis.locked = self.xmlFile:getValue(key .. ".articulatedAxis#locked", false)
        mode.articulatedAxis.wheelIndices = self.xmlFile:getValue(key .. ".articulatedAxis#wheelIndices", nil, true)
    end
    mode.animations = {}
    for wheelKey, wheelEntry in self.xmlFile:iterator(key .. ".animation") do
        local wheel = {
            ["animName"] = self.xmlFile:getValue(wheelEntry .. "#name"),
            ["animSpeed"] = self.xmlFile:getValue(wheelEntry .. "#speed", 1),
            ["stopTime"] = self.xmlFile:getValue(wheelEntry .. "#stopTime")
        }
        if wheel.animName == nil or not self:getAnimationExists(wheel.animName) then
            Logging.xmlWarning(self.xmlFile, "Invalid animation \'%s\' for \'%s\'", tostring(wheel.animName), wheelEntry)
        else
            table.insert(mode.animations, wheel)
        end
    end
    local node = self.xmlFile:getValue(key .. ".steeringWheel#node", nil, self.components, self.i3dMappings)
    if node ~= nil then
        mode.steeringWheel = {}
        mode.steeringWheel.node = node
        local _, _, wheelKey = getRotation(mode.steeringWheel.node)
        mode.steeringWheel.lastRotation = _
        mode.steeringWheel.indoorRotation = self.xmlFile:getValue(key .. ".steeringWheel#indoorRotation", 0)
        mode.steeringWheel.outdoorRotation = self.xmlFile:getValue(key .. ".steeringWheel#outdoorRotation", 0)
    end
    return true
end
function CrabSteering:getCanToggleCrabSteering()
    return true, nil
end
function CrabSteering:getCrabSteeringModeAvailable(mode)
    return true
end
function CrabSteering:getNumCrabSteeringModesAvailable()
    local numModes = 0
    for k, mode in ipairs(self.spec_crabSteering.steeringModes) do
        if self:getCrabSteeringModeAvailable(mode) then
        end
    end
    return numModes
end
function CrabSteering:setCrabSteering(state, noEventSend)
    local spec = self.spec_crabSteering
    if noEventSend == nil or noEventSend == false then
        if g_server == nil then
            g_client:getServerConnection():sendEvent(SetCrabSteeringEvent.new(self, state))
        else
            g_server:broadcastEvent(SetCrabSteeringEvent.new(self, state), nil, nil, self)
        end
    end
    if state ~= spec.state then
        local currentMode = spec.steeringModes[spec.state]
        if currentMode.animations ~= nil then
            for _, anim in pairs(currentMode.animations) do
                local curTime = self:getAnimationTime(anim.animName)
                if anim.stopTime == nil then
                    self:playAnimation(anim.animName, -anim.animSpeed, curTime, noEventSend)
                end
            end
        end
        local newMode = spec.steeringModes[state]
        if newMode.animations ~= nil then
            for anim, curTime in pairs(newMode.animations) do
                local curTime = self:getAnimationTime(curTime.animName)
                if curTime.stopTime == nil then
                    self:playAnimation(curTime.animName, curTime.animSpeed, curTime, noEventSend)
                else
                    self:setAnimationStopTime(curTime.animName, curTime.stopTime)
                    self:playAnimation(curTime.animName, curTime.stopTime < curTime and -1 or 1, curTime, noEventSend)
                end
            end
        end
        for anim, curTime in pairs(newMode.steeringNodes) do
            local curTime = curTime.steeringNode
            curTime.offsetTarget = curTime.offset
            local inverted = curTime.offsetTarget - curTime.offset
            curTime.offsetTargetSpeed = math.abs(inverted) / (1 / spec.toggleSpeedFactor * 1000)
            if curTime.locked then
                curTime.rotScaleTarget = 0
            else
                curTime.rotScaleTarget = curTime.rotScale or curTime.rotScaleOrig
            end
            if newMode.steeringCenterNode == nil then
                curTime.rotMin = curTime.rotMinOrig
                curTime.rotMax = curTime.rotMaxOrig
                curTime.rotSpeed = curTime.rotSpeedOrig
                curTime.rotSpeedNeg = curTime.rotSpeedNegOrig
            else
                self.spec_wheels.steeringCenterNode = newMode.steeringCenterNode
                self:setAIRootNodeDirty()
                local speed, rotMax, inverted = Wheels.getAckermannSteeringAngles(curTime.node, newMode.steeringCenterNode, newMode.turningRadius or self.spec_wheels.maxTurningRadius)
                curTime.rotMin = speed
                curTime.rotMax = rotMax
                curTime.rotSpeed = rotMax / self.wheelSteeringDuration
                curTime.rotSpeedNeg = -speed / self.wheelSteeringDuration
                if inverted then
                    curTime.rotSpeed = -curTime.rotSpeedNeg
                    curTime.rotSpeedNeg = -curTime.rotSpeed
                end
            end
            local inverted = curTime.rotScaleTarget - curTime.rotScale
            curTime.rotScaleTargetSpeed = math.abs(inverted) / (1 / spec.toggleSpeedFactor * 1000)
        end
        for anim, curTime in pairs(newMode.wheels) do
            curTime.wheel.steeringOffset = curTime.wheel.steeringOffset or 0
            curTime.steeringOffsetSpeed = math.abs(curTime.wheel.offset - curTime.wheel.wheel.steeringOffset) / (1 / spec.toggleSpeedFactor * 1000)
        end
        for anim, curTime in ipairs(newMode.nodes) do
            if curTime.rotation ~= nil then
                setRotation(curTime.node, curTime.rotation[1], curTime.rotation[2], curTime.rotation[3])
            end
            if curTime.translation ~= nil then
                setTranslation(curTime.node, curTime.translation[1], curTime.translation[2], curTime.translation[3])
            end
            if self.setMovingToolDirty ~= nil then
                self:setMovingToolDirty(curTime.node)
            end
        end
    end
    spec.state = state
    if self.isClient and self.updateDashboardValueType ~= nil then
        self:updateDashboardValueType("crabSteering.state")
    end
end
function CrabSteering:getCrabSteeringMode()
    local spec = self.spec_crabSteering
    if spec.steeringModes == nil then
        return nil
    else
        return spec.steeringModes[spec.state]
    end
end
function CrabSteering:setNextCrabSteeringMode(direction)
    local spec = self.spec_crabSteering
    local state = spec.state
    local valid = false
    for i = 1, spec.stateMax do
        state = state + direction
        if spec.stateMax < state then
            state = 1
        elseif state < 1 then
            state = spec.stateMax
        end
        if self:getCrabSteeringModeAvailable(spec.steeringModes[state]) then
            valid = true
            break
        end
    end
    if valid then
        if state ~= spec.state then
            self:setCrabSteering(state)
        end
    end
end
function CrabSteering:loadWheelFromXML(superFunc, wheel)
    if not superFunc(self, wheel) then
        return false
    end
    wheel.steeringOffset = 0
    wheel.forceSteeringAngleUpdate = true
    return true
end
function CrabSteering:updateSteeringAngle(superFunc, wheel, dt, steeringAngle)
    local spec = self.spec_crabSteering
    if spec.stateMax == 0 then
        return superFunc(self, wheel, dt, steeringAngle)
    end
    local currentMode = spec.steeringModes[spec.state]
    local i = 1
    for i = i, #currentMode.wheels do
        local wheelProperties = currentMode.wheels[i]
        if wheelProperties.wheelIndex == wheel.wheelIndex then
            if wheel.rotSpeedBackUp == nil then
                wheel.rotSpeedBackUp = wheel.physics.rotSpeed
            end
            if wheel.rotSpeedBackUp ~= 0 then
                local rotScale = 0
                if self.lastSpeed ~= 0 then
                    rotScale = math.min(1 / (self.lastSpeed * self.spec_drivable.speedRotScale + self.spec_drivable.speedRotScaleOffset), 1)
                end
                if wheel.steeringOffset ~= wheelProperties.offset then
                    local direction = math.sign(wheelProperties.offset - wheel.steeringOffset)
                    wheel.steeringOffset = (direction > 0 and math.min or math.max)(wheel.steeringOffset + dt * wheelProperties.wheel.steeringOffsetSpeed * direction, wheelProperties.offset)
                end
                if wheelProperties.locked then
                    if wheel.physics.steeringAngle > wheel.steeringOffset or wheel.steeringOffset < steeringAngle then
                        local limit = math.min(wheel.physics.steeringAngle, steeringAngle) - dt * 0.001 * self.autoRotateBackSpeed * rotScale * spec.toggleSpeedFactor
                        steeringAngle = math.max(wheel.steeringOffset, limit)
                    elseif wheel.physics.steeringAngle < wheel.steeringOffset or steeringAngle < wheel.steeringOffset then
                        local limit = math.max(wheel.physics.steeringAngle, steeringAngle) + delta
                        steeringAngle = math.min(wheel.steeringOffset, limit)
                    end
                    if steeringAngle == wheel.steeringOffset then
                        wheel.physics.rotSpeed = 0
                    elseif wheel.physics.rotSpeed < 0 then
                        wheel.physics.rotSpeed = math.min(0, wheel.physics.rotSpeed + delta)
                    elseif wheel.physics.rotSpeed > 0 then
                        wheel.physics.rotSpeed = math.max(0, wheel.physics.rotSpeed - delta)
                    end
                else
                    local direction
                    if self.rotatedTime > 0 then
                        direction = (wheel.physics.rotMax - wheel.steeringOffset) / self.wheelSteeringDuration
                        if wheel.rotSpeedBackUp < 0 then
                            direction = (wheel.physics.rotMin - wheel.steeringOffset) / self.wheelSteeringDuration
                        end
                    else
                        direction = -(wheel.physics.rotMin - wheel.steeringOffset) / self.wheelSteeringDuration
                        if wheel.rotSpeedBackUp < 0 then
                            direction = -(wheel.physics.rotMax - wheel.steeringOffset) / self.wheelSteeringDuration
                        end
                    end
                    if wheel.physics.rotSpeed < wheel.rotSpeedBackUp then
                        wheel.physics.rotSpeed = math.min(wheel.rotSpeedBackUp, wheel.physics.rotSpeed + delta)
                    elseif wheel.physics.rotSpeed > wheel.rotSpeedBackUp then
                        wheel.physics.rotSpeed = math.max(wheel.rotSpeedBackUp, wheel.physics.rotSpeed - delta)
                    end
                    local change = wheel.physics.rotSpeed / wheel.rotSpeedBackUp
                    steeringAngle = wheel.steeringOffset + self.rotatedTime * change * direction
                end
                local limit = wheel.physics.rotMin
                return math.clamp(steeringAngle, limit, wheel.physics.rotMax)
            end
            break
        end
    end
    return steeringAngle
end
function CrabSteering:updateArticulatedAxisRotation(steeringAngle, dt)
    local spec = self.spec_crabSteering
    local specArticulatedAxis = self.spec_articulatedAxis
    local specDriveable = self.spec_drivable
    if spec.stateMax == 0 then
        return steeringAngle
    end
    if not self.isServer then
        return specArticulatedAxis.curRot
    end
    local currentMode = spec.steeringModes[spec.state]
    if currentMode.articulatedAxis == nil then
        return steeringAngle
    end
    local delta = 1 / (self.lastSpeed * specDriveable.speedRotScale + specDriveable.speedRotScaleOffset)
    local rotScale = math.min(delta, 1)
    local delta = dt * 0.001 * self.autoRotateBackSpeed * rotScale * spec.toggleSpeedFactor
    if spec.currentArticulatedAxisOffset < currentMode.articulatedAxis.offset then
        spec.currentArticulatedAxisOffset = math.min(currentMode.articulatedAxis.offset, spec.currentArticulatedAxisOffset + delta)
    elseif spec.currentArticulatedAxisOffset > currentMode.articulatedAxis.offset then
        spec.currentArticulatedAxisOffset = math.max(currentMode.articulatedAxis.offset, spec.currentArticulatedAxisOffset - delta)
    end
    if currentMode.articulatedAxis.locked then
        if specArticulatedAxis.rotSpeed > 0 then
            specArticulatedAxis.rotSpeed = math.max(0, specArticulatedAxis.rotSpeed - delta)
        elseif specArticulatedAxis.rotSpeed < 0 then
            specArticulatedAxis.rotSpeed = math.min(0, specArticulatedAxis.rotSpeed + delta)
        end
    elseif specArticulatedAxis.rotSpeed > currentMode.articulatedAxis.rotSpeedBackUp then
        specArticulatedAxis.rotSpeed = math.max(currentMode.articulatedAxis.rotSpeedBackUp, specArticulatedAxis.rotSpeed - delta)
    elseif specArticulatedAxis.rotSpeed < currentMode.articulatedAxis.rotSpeedBackUp then
        specArticulatedAxis.rotSpeed = math.min(currentMode.articulatedAxis.rotSpeedBackUp, specArticulatedAxis.rotSpeed + delta)
    end
    local rotSpeed
    if self.rotatedTime * currentMode.articulatedAxis.rotSpeedBackUp > 0 then
        rotSpeed = (specArticulatedAxis.rotMax - spec.currentArticulatedAxisOffset) / self.wheelSteeringDuration
    else
        rotSpeed = (specArticulatedAxis.rotMin - spec.currentArticulatedAxisOffset) / self.wheelSteeringDuration
    end
    local curRot = specArticulatedAxis.rotSpeed
    local wheels = math.abs(curRot)
    local alpha = currentMode.articulatedAxis.rotSpeedBackUp
    local rotSpeed = rotSpeed * (wheels / math.abs(alpha))
    local wheels = spec.currentArticulatedAxisOffset
    local count = self.rotatedTime
    steeringAngle = wheels + math.abs(count) * rotSpeed
    if currentMode.articulatedAxis.wheelIndices == nil or (spec.distFromCompJointToCenterOfBackWheels == nil or self.movingDirection < 0) then
        local wheels = spec.articulatedAxisChangingTime
        if spec.articulatedAxisOffsetChanged then
            wheels = 2500
            spec.articulatedAxisOffsetChanged = false
        end
        if wheels > 0 then
            local curRot = wheels / 2500
            spec.articulatedAxisChangingTime = wheels - dt
        end
    else
        local wheels = self:getWheels()
        local count = currentMode.articulatedAxis.rotSpeedBackUp
        local curRot = math.sign(count) * specArticulatedAxis.curRot
        local alpha = 0
        local count = 0
        for _, wheelIndex in pairs(currentMode.articulatedAxis.wheelIndices) do

        end
        if count > 0 then
        end
        local alpha = alpha - curRot
        local v = 0
        local count = 0
        for wheelIndex, wheelIndex in pairs(currentMode.articulatedAxis.wheelIndices) do
            local wheel = wheels[wheelIndex]
            local axleSpeed = getWheelShapeAxleSpeed(wheel.node, wheel.physics.wheelShape)
            if wheel.physics.hasGroundContact then
                local longSlip, _ = getWheelShapeSlip(wheel.node, wheel.physics.wheelShape)
                v = v + (1 - math.min(1, longSlip)) * axleSpeed * wheel.physics.radius
            end
        end
        if count > 0 then
        end
        local h = v * 0.001 * dt
        local g = math.sin(alpha) * h
        local axleSpeed = spec.distFromCompJointToCenterOfBackWheels - math.cos(alpha) * h
        local wheelIndex = math.atan2(g, axleSpeed)
        local axleSpeed = currentMode.articulatedAxis.rotSpeedBackUp
        steeringAngle = math.sign(axleSpeed) * (curRot + wheelIndex)
        spec.articulatedAxisOffsetChanged = true
        spec.articulatedAxisLastAngle = steeringAngle
    end
    local curRot = specArticulatedAxis.rotMin
    local count = specArticulatedAxis.rotMax
    local alpha = math.min(count, steeringAngle)
    return math.max(curRot, alpha)
end
function CrabSteering:getCanBeSelected(superFunc)
    return self.spec_crabSteering.hasSteeringModes or superFunc(self)
end
function CrabSteering:loadWheelsFromXML(superFunc, xmlFile, key, wheelConfigurationI)
    superFunc(self, xmlFile, key, wheelConfigurationI)
    self.spec_crabSteering.configurationIndex = WheelXMLObject.getValueStatic(self.spec_wheels.wheelConfigurationId, self.spec_wheels.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#crabSteeringIndex")
end
function CrabSteering:updateSteeringWheel(superFunc, steeringWheel, dt, direction)
    if self.spec_crabSteering.hasSteeringModes then
        local spec = self.spec_crabSteering
        local currentMode = spec.steeringModes[spec.state]
        if currentMode.steeringWheel ~= nil then
            steeringWheel = currentMode.steeringWheel
        end
    end
    superFunc(self, steeringWheel, dt, direction)
end
function CrabSteering:startFieldWorker(superFunc)
    self:setCrabSteering(self.spec_crabSteering.aiSteeringModeIndex)
    return superFunc(self)
end
function CrabSteering:getAIAutomaticSteeringLookAheadDistance(superFunc)
    if self.spec_crabSteering.hasSteeringModes then
        local spec = self.spec_crabSteering
        local currentMode = spec.steeringModes[spec.state]
        if currentMode.automaticSteeringLookAheadDistance ~= nil then
            return currentMode.automaticSteeringLookAheadDistance
        end
    end
    return superFunc(self)
end
function CrabSteering:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_crabSteering
        if spec.hasSteeringModes then
            self:clearActionEventsTable(spec.actionEvents)
            if isActiveForInputIgnoreSelection then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_CRABSTEERING, self, CrabSteering.actionEventToggleCrabSteeringModes, false, true, false, true, 1)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
                for _, mode in pairs(spec.steeringModes) do
                    if mode.inputAction ~= nil then
                        local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, mode.inputAction, self, CrabSteering.actionEventSetCrabSteeringMode, false, true, false, true, nil)
                        g_inputBinding:setActionEventTextVisibility(actionEventId, false)
                        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
                    end
                end
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_CRABSTEERING_BACK, self, CrabSteering.actionEventToggleCrabSteeringModes, false, true, false, true, -1)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            end
        end
    end
end
function CrabSteering:actionEventToggleCrabSteeringModes(_, _, callbackState, _)
    local isAllowed, warning = self:getCanToggleCrabSteering()
    if isAllowed then
        self:setNextCrabSteeringMode(callbackState)
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
    end
end
function CrabSteering:actionEventSetCrabSteeringMode(actionName, _, _, _)
    local isAllowed, warning = self:getCanToggleCrabSteering()
    if isAllowed then
        local spec = self.spec_crabSteering
        local state = spec.state
        for i, mode in pairs(spec.steeringModes) do
            if mode.inputAction == InputAction[actionName] then
                state = i
                break
            end
        end
        if state ~= spec.state and self:getCrabSteeringModeAvailable(spec.steeringModes[state]) then
            self:setCrabSteering(state)
            return
        end
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
    end
end