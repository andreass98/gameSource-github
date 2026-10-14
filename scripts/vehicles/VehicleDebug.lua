VehicleDebug = {}
VehicleDebug.DEBUG_COLORS = {
    Color.new(1, 0, 0, 1),
    Color.new(0, 1, 0, 1),
    Color.new(0, 0, 1, 1),
    Color.new(1, 1, 0, 1),
    Color.new(1, 0, 1, 1),
    Color.new(0, 1, 1, 1),
    Color.new(1, 1, 1, 1)
}
VehicleDebug.COLOR = {}
VehicleDebug.COLOR.ACTIVE = Color.new(0.5, 1, 0.5, 1)
VehicleDebug.COLOR.INACTIVE = Color.new(1, 0.1, 0.1, 1)
VehicleDebug.COLOR.GREY = Color.new(0.2, 0.2, 0.2, 1)
VehicleDebug.NONE = 0
VehicleDebug.DEBUG = 1
VehicleDebug.DEBUG_PHYSICS = 2
VehicleDebug.DEBUG_TUNING = 3
VehicleDebug.DEBUG_TRANSMISSION = 4
VehicleDebug.DEBUG_ATTRIBUTES = 5
VehicleDebug.DEBUG_ATTACHER_JOINTS = 6
VehicleDebug.DEBUG_AI = 7
VehicleDebug.DEBUG_SOUNDS = 8
VehicleDebug.DEBUG_ANIMATIONS = 9
VehicleDebug.STATE_NAMES = {}
VehicleDebug.STATE_NAMES[VehicleDebug.NONE] = "None"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG] = "Values"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_PHYSICS] = "Physics"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_TUNING] = "Tuning"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_TRANSMISSION] = "Transmission"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_ATTRIBUTES] = "Attributes"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_ATTACHER_JOINTS] = "Attacher Joints"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_AI] = "AI"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_SOUNDS] = "Sounds"
VehicleDebug.STATE_NAMES[VehicleDebug.DEBUG_ANIMATIONS] = "Animations"
VehicleDebug.NUM_STATES = 9
VehicleDebug.state = 0
VehicleDebug.selectedAnimation = 0
if g_isDevelopmentVersion then
    VehicleDebug.state = 0
end
function VehicleDebug.consoleCommandVehicleDebug(_, stateStr)
    local newState = VehicleDebug.DEBUG
    if stateStr ~= nil then
        local n = tonumber(stateStr)
        if n == nil then
            for stateIndex, stateName in pairs(VehicleDebug.STATE_NAMES) do
                if string.startsWith(string.lower(stateName), string.lower(stateStr)) then
                    newState = stateIndex
                end
            end
        else
            newState = n
        end
    end
    VehicleDebug.setState(newState)
    return string.format("VehicleDebug set to \'%s\'", VehicleDebug.STATE_NAMES[VehicleDebug.state])
end
function VehicleDebug.setState(state)
    if VehicleDebug.state == 0 then
        VehicleDebug.debugActionEvents = {}
        local i = 1
        for i = i, VehicleDebug.NUM_STATES do
            local _, actionEventId = g_inputBinding:registerActionEvent(InputAction["DEBUG_VEHICLE_" .. i], VehicleDebug, VehicleDebug.debugActionCallback, false, true, false, true, i)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            table.insert(VehicleDebug.debugActionEvents, actionEventId)
        end
    elseif state == 0 then
        local i = 1
        for i = i, #VehicleDebug.debugActionEvents do
            g_inputBinding:removeActionEvent(VehicleDebug.debugActionEvents[i])
        end
    end
    if state == VehicleDebug.DEBUG_ATTACHER_JOINTS then
        if VehicleDebug.attacherJointUpperEventId == nil and VehicleDebug.attacherJointLowerEventId == nil then
            local _, upperEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_FRONTLOADER_ARM, VehicleDebug, VehicleDebug.moveUpperRotation, false, false, true, true)
            g_inputBinding:setActionEventTextVisibility(upperEventId, false)
            VehicleDebug.attacherJointUpperEventId = upperEventId
            local i, _ = g_inputBinding:registerActionEvent(InputAction.AXIS_FRONTLOADER_TOOL, VehicleDebug, VehicleDebug.moveLowerRotation, false, false, true, true)
            g_inputBinding:setActionEventTextVisibility(_, false)
            VehicleDebug.attacherJointLowerEventId = _
        end
    else
        g_inputBinding:removeActionEvent(VehicleDebug.attacherJointUpperEventId)
        g_inputBinding:removeActionEvent(VehicleDebug.attacherJointLowerEventId)
        VehicleDebug.attacherJointUpperEventId = nil
        VehicleDebug.attacherJointLowerEventId = nil
    end
    if state == VehicleDebug.DEBUG_AI and g_currentMission ~= nil then
        for _, actionEventId in pairs(g_currentMission.vehicleSystem.vehicles) do
            if actionEventId.spec_aiDrivable ~= nil and (actionEventId:getIsActiveForInput(true, true) and actionEventId.spec_aiDrivable.agentId ~= nil) then
                enableVehicleNavigationAgentDebugRendering(actionEventId.spec_aiDrivable.agentId, true)
            end
        end
    end
    local _ = false
    if state == VehicleDebug.DEBUG_TUNING then
        WheelPhysics.COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN_DISPLACEMENT
        _ = true
    elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING and WheelPhysics.COLLISION_MASK ~= CollisionMask.ALL then
        WheelPhysics.COLLISION_MASK = CollisionMask.ALL
        _ = true
    end
    if _ then
        for actionEventId, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
            if vehicle.getWheels ~= nil then
                for i, wheel in ipairs(vehicle:getWheels()) do
                    wheel.physics:updateBase()
                end
            end
        end
    end
    local upperEventId = false
    if VehicleDebug.state == state then
        VehicleDebug.state = 0
    else
        VehicleDebug.state = state
        upperEventId = true
    end
    if g_currentMission ~= nil then
        for vehicle, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
            vehicle:updateSelectableObjects()
            vehicle:updateActionEvents()
            vehicle:setSelectedVehicle(vehicle)
        end
    end
    return upperEventId
end
function VehicleDebug:delete()
    if self.isServer then
        local motorSpec = self.spec_motorized
        if motorSpec ~= nil then
            local motor = motorSpec.motor
            if motor ~= nil then
                if motor.debugCurveOverlay ~= nil then
                    delete(motor.debugCurveOverlay)
                end
                if motor.debugTorqueGraph ~= nil then
                    motor.debugTorqueGraph:delete()
                end
                if motor.debugPowerGraph ~= nil then
                    motor.debugPowerGraph:delete()
                end
                if motor.debugGraphs ~= nil then
                    for _, graph in ipairs(motor.debugGraphs) do
                        graph:delete()
                    end
                end
                if motor.debugLoadGraph ~= nil then
                    motor.debugLoadGraph:delete()
                end
                if motor.debugLoadGraphSmooth ~= nil then
                    motor.debugLoadGraphSmooth:delete()
                end
                if motor.debugLoadGraphSound ~= nil then
                    motor.debugLoadGraphSound:delete()
                end
                if motor.debugRPMGraphSmooth ~= nil then
                    motor.debugRPMGraphSmooth:delete()
                end
                if motor.debugRPMGraphSound ~= nil then
                    motor.debugRPMGraphSound:delete()
                end
                if motor.debugRPMGraph ~= nil then
                    motor.debugRPMGraph:delete()
                end
                if motor.debugAccelerationGraph ~= nil then
                    motor.debugAccelerationGraph:delete()
                end
            end
        end
    end
end
function VehicleDebug.debugActionCallback(_, _, _, callbackState, _)
    if VehicleDebug.state ~= callbackState then
        VehicleDebug.setState(callbackState)
        log(string.format("VehicleDebug set to \'%s\'", VehicleDebug.STATE_NAMES[VehicleDebug.state]))
    end
end
function VehicleDebug.updateDebug(vehicle, dt)
    if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
        VehicleDebug.drawDebugAttributeRendering(vehicle)
    elseif VehicleDebug.state == VehicleDebug.DEBUG_ATTACHER_JOINTS then
        VehicleDebug.drawDebugAttacherJoints(vehicle)
    elseif VehicleDebug.state == VehicleDebug.DEBUG_AI then
        VehicleDebug.drawDebugAIRendering(vehicle)
    elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING then
        VehicleDebug.updateTuningDebugRendering(vehicle, dt)
    end
    if VehicleDebug.state == VehicleDebug.DEBUG and (vehicle:getIsActiveForInput() or vehicle.rootVehicle ~= g_localPlayer:getCurrentVehicle()) then
        VehicleDebug.drawDebugValues(vehicle)
    end
end
function VehicleDebug.drawDebug(vehicle)
    if vehicle.getIsEntered ~= nil and vehicle:getIsEntered() then
        local v = vehicle:getSelectedVehicle()
        if v ~= nil then
            vehicle = v
        end
        if VehicleDebug.state == VehicleDebug.DEBUG_PHYSICS then
            VehicleDebug.drawDebugRendering(vehicle)
        elseif VehicleDebug.state == VehicleDebug.DEBUG_SOUNDS then
            VehicleDebug.drawSoundDebugValues(vehicle)
        elseif VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS then
            VehicleDebug.drawAnimationDebug(vehicle)
        elseif VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
            VehicleDebug.drawTransmissionDebug(vehicle)
        elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING then
            VehicleDebug.drawTuningDebug(vehicle)
        end
        if VehicleDebug.state > 0 then
            setTextAlignment(RenderText.ALIGN_CENTER)
            local i = 1
            for i = i, VehicleDebug.NUM_STATES do
                if VehicleDebug.state == i then
                    setTextColor(0, 1, 0, 1)
                    renderText(1 / (VehicleDebug.NUM_STATES + 1) * i, 0.01, 0.03, string.format("%s", VehicleDebug.STATE_NAMES[i]))
                else
                    setTextColor(1, 1, 0, 1)
                    renderText(x, 0.01, 0.015, string.format("SHIFT + %d: \'%s\'", i, VehicleDebug.STATE_NAMES[i]))
                end
            end
            setTextColor(1, 1, 1, 1)
            setTextAlignment(RenderText.ALIGN_LEFT)
        end
    end
end
function VehicleDebug.registerActionEvents(vehicle)
    if vehicle.getIsEntered ~= nil and (vehicle:getIsEntered() and VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS) then
        vehicle:addActionEvent(vehicle.actionEvents, InputAction.DEBUG_PLAYER_ENABLE, vehicle, function()
            VehicleDebug.selectedAnimation = VehicleDebug.selectedAnimation + 1
        end, false, true, false, true, nil)
    end
    if VehicleDebug.state > 0 then
        if VehicleDebug.debugActionEvents ~= nil then
            local i = 1
            for i = i, #VehicleDebug.debugActionEvents do
                g_inputBinding:removeActionEvent(VehicleDebug.debugActionEvents[i])
            end
        end
        VehicleDebug.debugActionEvents = {}
        local i = 1
        for i = i, 9 do
            local _, actionEventId = g_inputBinding:registerActionEvent(InputAction["DEBUG_VEHICLE_" .. i], VehicleDebug, VehicleDebug.debugActionCallback, false, true, false, true, i)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            table.insert(VehicleDebug.debugActionEvents, actionEventId)
        end
    end
end
function VehicleDebug:drawBaseDebugRendering(x, y)
    local vx, _, vz = getWorldTranslation(self.components[1].node)
    local fieldOwned = g_farmlandManager:getIsOwnedByFarmAtWorldPosition(g_currentMission:getFarmId(), vx, vz)
    local str1 = ""
    local str2 = ""
    local str3 = ""
    local str4 = ""
    local motorSpec = self.spec_motorized
    local diffSpeed = nil
    if motorSpec ~= nil then
        local motor = motorSpec.motor
        local torque = motor:getMotorAvailableTorque()
        local neededPtoTorque = motor:getMotorExternalTorque()
        local motorPower = motor:getMotorRotSpeed() * (torque - neededPtoTorque) * 1000
        local str2 = str2 .. string.format("%1.2frpm\n", motor:getNonClampedMotorRpm())
        local str2 = str2 .. string.format("%1.2frpm\n", motor:getClutchRotSpeed() * 30 / 3.141592653589793)
        local str2 = str2 .. string.format("%1.2fhp %1.2fkW\n", motorPower / 735.49875, motorPower / 1000)
        local str2 = str2 .. string.format("%d %d (%d, %1.2f)\n", motor.gear, motor.targetGear * motor.currentDirection, motor.activeGearGroupIndex or 0, motor:getGearRatio())
        str2 = str2 .. string.format("%1.2fkN %1.2fkN\n", torque, motor:getMotorAppliedTorque())
        local ptoPower = motor:getNonClampedMotorRpm() * 3.141592653589793 / 30 * neededPtoTorque
        local ptoLoad = neededPtoTorque / motor:getPeakTorque()
        local str3 = str3 .. "pto load:\n"
        local str4 = str4 .. string.format("%.2f%% %.2fhp %.2fkW %1.2fkN\n", ptoLoad * 100, ptoPower * 1.359621, ptoPower, neededPtoTorque)
        local str3 = str3 .. "motor load:\n"
        local str4 = str4 .. string.format("%.2f%%\n", motorSpec.smoothedLoadPercentage * 100)
        local str3 = str3 .. "motor rpm for sounds:\n"
        local str4 = str4 .. string.format("%drpm\n", motor:getLastMotorRpm())
        str3 = str3 .. "brakeForce:\n"
        str4 = str4 .. string.format("%.2f (max. %.2f)\n", (self.spec_wheels or {
            ["brakePedal"] = 0
        }).brakePedal, self:getBrakeForce() * 0.5)
        local fuelFillUnitIndex = self:getConsumerFillUnitIndex(FillType.DIESEL) or (self:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) or self:getConsumerFillUnitIndex(FillType.METHANE))
        if fuelFillUnitIndex ~= nil then
            local fillLevel = self:getFillUnitFillLevel(fuelFillUnitIndex)
            local fillType = self:getFillUnitFillType(fuelFillUnitIndex)
            local unit = fillType == FillType.ELECTRICCHARGE and "kw" or (fillType == FillType.METHANE and "kg" or "l")
            str3 = str3 .. string.format("%s:\n", g_fillTypeManager:getFillTypeNameByIndex(fillType))
            str4 = str4 .. string.format("%.2f%s/h (%.2f%s)\n", motorSpec.lastFuelUsage, unit, fillLevel, unit)
        end
        local fillLevel = self:getConsumerFillUnitIndex(FillType.DEF)
        if fillLevel ~= nil then
            local fillType = self:getFillUnitFillLevel(fillLevel)
            str4 = str4 .. string.format("%.2fl/h (%.2fl)\n", motorSpec.lastDefUsage, fillType)
        end
        local fillType = self:getConsumerFillUnitIndex(FillType.AIR)
        if fillType ~= nil then
            local unit = self:getFillUnitFillLevel(fillType)
            str4 = str4 .. string.format("%.2fl/sec (%.2fl)\n", motorSpec.lastAirUsage, unit)
        end
        diffSpeed = motor.differentialRotSpeed * 3.6
    end
    local str1 = str1 .. "vel acc[m/s2]:\n"
    local str2 = str2 .. string.format("%1.4f\n", self.lastSpeedAcceleration * 1000 * 1000)
    local str1, str2
    if diffSpeed == nil then
        str2 = str2 .. string.format("%1.3f\n", self:getLastSpeed())
    else
        local str2 = str2 .. string.format("%1.3f\n", self:getLastSpeed())
        local motor = self.lastSpeedReal * 3600
        local torque = 0
        if diffSpeed > 0.01 and motor > 0.01 then
            torque = (diffSpeed / motor - 1) * 100
        end
        str2 = str2 .. string.format("%1.3f (slip: %d%%)\n", diffSpeed, torque)
    end
    local str1 = str1 .. "field owned:\n"
    local str2 = str2 .. tostring(fieldOwned) .. "\n"
    local str1 = str1 .. "mass:\n"
    local str2 = str2 .. string.format("%1.1fkg\n", self:getTotalMass(true) * 1000)
    local str1 = str1 .. "mass incl. attach:\n"
    local str2 = str2 .. string.format("%1.1fkg\n", self:getTotalMass() * 1000)
    if self.spec_attachable ~= nil then
        local motor = 0
        if self.spec_wheels ~= nil then
            motor = self.spec_wheels.brakePedal
        end
        local torque = self:getBrakeForce() / 10
        str2 = str2 .. string.format("%1.2f / %1.2f\n", torque * motor, torque)
    end
    local motor = getCorrectTextSize(0.02)
    Utils.renderMultiColumnText(x, y, motor, { str1, str2 }, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
    Utils.renderMultiColumnText(x + 0.22, y, motor, { str3, str4 }, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
    return getTextHeight(motor, str1), getTextHeight(motor, str3)
end
function VehicleDebug:drawWheelInfoRendering(x, y)
    if self.isServer then
        local specWheels = self.spec_wheels
        if specWheels ~= nil and #specWheels.wheels > 0 then
            local debugTable = WheelDebug.getDebugValueHeader()
            for i, wheel in ipairs(specWheels.wheels) do
                wheel.debug:fillDebugValues(debugTable)
                if #specWheels.wheels > 4 and DebugUtil.isNodeInCameraRange(wheel.repr, 30) then
                    local wx, wy, wz = getWorldTranslation(wheel.repr)
                    Utils.renderTextAtWorldPosition(wx, wy, wz, string.format("%d\n%s", i, getName(wheel.driveNode or wheel.linkNode)), getCorrectTextSize(0.008))
                end
            end
            local textSize = getCorrectTextSize(0.02)
            Utils.renderMultiColumnText(x, y, textSize, debugTable, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
            return getTextHeight(textSize, debugTable[1])
        end
    end
    return 0
end
function VehicleDebug:drawAxleInfoRendering(x, y)
    if self.isServer then
        local specWheels = self.spec_wheels
        if specWheels ~= nil and #specWheels.axles > 0 then
            local debugTable = WheelAxle.getDebugValueHeader()
            for _, axle in ipairs(specWheels.axles) do
                axle:fillDebugValues(debugTable)
            end
            local _, numLines = string.gsub(debugTable[1], "\n", "")
            if numLines > 1 then
                local textSize = getCorrectTextSize(0.02)
                Utils.renderMultiColumnText(x, y, textSize, debugTable, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
                return getTextHeight(textSize, debugTable[1])
            end
        end
    end
    return 0
end
function VehicleDebug:drawWheelSlipGraphs()
    if self.isServer then
        local specWheels = self.spec_wheels
        if specWheels ~= nil then
            for i, wheel in ipairs(specWheels.wheels) do
                wheel.debug:drawSlipGraphs()
            end
        end
    end
end
function VehicleDebug:drawDifferentialInfoRendering(x, y)
    local motorSpec = self.spec_motorized
    if motorSpec ~= nil and motorSpec.differentials ~= nil then
        local function getSpeedsOfDifferential(diff)
            -- upvalues: (copy) self, (ref) getSpeedsOfDifferential, (copy) motorSpec
            local speed1
            if diff.diffIndex1IsWheel then
                local wheel = self.spec_wheels.wheels[diff.diffIndex1]
                speed1 = 0
                if wheel.physics.wheelShapeCreated then
                    speed1 = getWheelShapeAxleSpeed(wheel.node, wheel.physics.wheelShape) * wheel.physics.radius
                end
            else
                local wheel, s2 = getSpeedsOfDifferential(motorSpec.differentials[diff.diffIndex1 + 1])
                speed1 = (wheel + s2) / 2
            end
            local speed2
            if diff.diffIndex2IsWheel then
                local wheel = specWheels.wheels[diff.diffIndex2]
                speed2 = 0
                if wheel.physics.wheelShapeCreated then
                    return speed1, getWheelShapeAxleSpeed(wheel.node, wheel.physics.wheelShape) * wheel.physics.radius
                end
            else
                local wheel, s2 = getSpeedsOfDifferential(motorSpec.differentials[diff.diffIndex2 + 1])
                speed2 = (wheel + s2) / 2
            end
            return speed1, speed2
        end
        local diffStrs = {
            "\n",
            "torqueRatio\n",
            "maxSpeedRatio\n",
            "actualSpeedRatio\n"
        }
        for i, diff in pairs(motorSpec.differentials) do
            diffStrs[1] = diffStrs[1] .. string.format("%d:\n", i)
            diffStrs[2] = diffStrs[2] .. string.format("%2.2f\n", diff.torqueRatio)
            diffStrs[3] = diffStrs[3] .. string.format("%2.2f\n", diff.maxSpeedRatio)
            local speed1, speed2 = getSpeedsOfDifferential(diff)
            local ratio = math.max(math.abs(speed1), (math.abs(speed2))) / math.max(math.min(math.abs(speed1), (math.abs(speed2))), 0.001)
            diffStrs[4] = diffStrs[4] .. string.format("%2.2f\n", ratio)
        end
        Utils.renderMultiColumnText(x, y, getCorrectTextSize(0.02), diffStrs, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
    end
end
function VehicleDebug:drawMotorGraphs(x, y, sizeX, sizeY, horizontal)
    if self.isServer then
        local motorSpec = self.spec_motorized
        if motorSpec ~= nil then
            local motor = motorSpec.motor
            local curveOverlay = motor.debugCurveOverlay
            if curveOverlay == nil then
                curveOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
                setOverlayColor(curveOverlay, 0, 1, 0, 0.2)
                motor.debugCurveOverlay = curveOverlay
            end
            local torqueCurve = motor:getTorqueCurve()
            local numTorqueValues = #torqueCurve.keyframes
            local maxRpm = motor:getMinRpm()
            local torqueGraph = torqueCurve.keyframes[1].time
            local minRpm = math.min(maxRpm, torqueGraph)
            local torqueGraph = motor:getMaxRpm()
            local powerGraph = torqueCurve.keyframes[numTorqueValues].time
            local maxRpm = math.max(torqueGraph, powerGraph)
            local torqueGraph = motor.debugTorqueGraph
            local powerGraph = motor.debugPowerGraph
            if torqueGraph == nil then
                local numValues = numTorqueValues * 32
                torqueGraph = Graph.new(numValues, x, y, sizeX, sizeY, 0, 0.0001, true, "kN", Graph.STYLE_LINES)
                torqueGraph:setColor(1, 1, 1, 1)
                motor.debugTorqueGraph = torqueGraph
                powerGraph = Graph.new(numValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
                powerGraph:setColor(1, 0, 0, 1)
                motor.debugPowerGraph = powerGraph
                torqueGraph.maxValue = 0.01
                powerGraph.maxValue = 0.01
                local s = 1
                for s = s, numValues do
                    local rpm = (s - 1) / (numValues - 1) * (torqueCurve.keyframes[numTorqueValues].time - torqueCurve.keyframes[1].time) + torqueCurve.keyframes[1].time
                    local torque = motor:getTorqueCurveValue(rpm)
                    local hpPower = torque * 1000 * rpm * 3.141592653589793 / 30 / 735.49875
                    local posX = (rpm - minRpm) / (maxRpm - minRpm)
                    torqueGraph:setValue(s, torque)
                    torqueGraph.maxValue = math.max(torqueGraph.maxValue, torque)
                    torqueGraph:setXPosition(s, posX)
                    powerGraph:setValue(s, hpPower)
                    powerGraph.maxValue = math.max(powerGraph.maxValue, hpPower)
                    powerGraph:setXPosition(s, posX)
                end
            else
                torqueGraph.left = x
                torqueGraph.bottom = y
                torqueGraph.width = sizeX
                torqueGraph.height = sizeY
                powerGraph.left = x
                powerGraph.bottom = y
                powerGraph.width = sizeX
                powerGraph.height = sizeY
            end
            torqueGraph:draw()
            powerGraph:draw()
            local numValues = renderOverlay
            local power = (motor:getNonClampedMotorRpm() - minRpm) / (maxRpm - minRpm)
            numValues(curveOverlay, x, y, sizeX * math.clamp(power, 0, 1), sizeY)
            if horizontal then
            end
            local numValues = motor:getMaximumForwardSpeed()
            local debugGraphs = motor.debugGraphs
            if debugGraphs == nil then
                local s = 1
                local rpm = motor.forwardGears
                if motor.currentDirection < 0 then
                end
                local s = motor.minForwardGearRatio == nil and rpm ~= nil and #rpm or s
                debugGraphs = {}
                motor.debugGraphs = debugGraphs
                local hpPower = 1
                for hpPower = hpPower, s do
                    local posX = Graph.new(20, x, y, sizeX, sizeY, 0, 0.0001, true, "kN", Graph.STYLE_LINES)
                    posX:setColor(1, 1, 1, 1)
                    table.insert(debugGraphs, posX)
                    local effPowerGraph = Graph.new(20, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
                    effPowerGraph:setColor(1, 0, 0, 1)
                    table.insert(debugGraphs, effPowerGraph)
                    local effGearRatioGraph = Graph.new(20, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
                    effGearRatioGraph:setColor(0.35, 1, 0.85, 1)
                    table.insert(debugGraphs, effGearRatioGraph)
                    local effRpmGraph = Graph.new(20, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)
                    effRpmGraph:setColor(0.18, 0.18, 1, 1)
                    table.insert(debugGraphs, effRpmGraph)
                    posX.maxValue = 0.01
                    effPowerGraph.maxValue = 0.01
                    effGearRatioGraph.maxValue = 0.01
                    effRpmGraph.maxValue = 0.01
                    local s = 1
                    for s = s, 20 do
                        local speed = (s - 1) / 19 * numValues
                        local gearRatio
                        if s == 1 then
                            local gearRpm
                            gearRpm, gearRatio = motor:getBestGear(1, speed * 30 / 3.141592653589793, 0, math.huge, 0)
                        else
                            gearRatio = rpm[hpPower].ratio
                        end
                        local gearRpm = speed * 30 / 3.141592653589793 * gearRatio
                        local torque = torqueCurve:get(gearRpm)
                        if minRpm <= gearRpm and gearRpm <= maxRpm then
                            posX:setValue(s, torque)
                            posX.maxValue = math.max(posX.maxValue, torque)
                            effPowerGraph:setValue(s, torque * 1000 * gearRpm * 3.141592653589793 / 30 / 735.49875)
                            effPowerGraph.maxValue = math.max(effPowerGraph.maxValue, hpPower)
                            effGearRatioGraph:setValue(s, gearRatio)
                            effGearRatioGraph.maxValue = math.max(effGearRatioGraph.maxValue, gearRatio)
                            effRpmGraph:setValue(s, gearRpm)
                            effRpmGraph.maxValue = math.max(effRpmGraph.maxValue, gearRpm)
                        end
                    end
                end
            else
                local rpm = 1
                for rpm = rpm, #debugGraphs do
                    local torque = debugGraphs[rpm]
                    torque.left = x
                    torque.bottom = y
                    torque.width = sizeX
                    torque.height = sizeY
                end
            end
            for torque, power in pairs(debugGraphs) do
                power:draw()
            end
            local numVelocityValues = renderOverlay
            local posX = self.lastSpeedReal * 1000 / numValues
            numVelocityValues(curveOverlay, x, y, sizeX * math.clamp(posX, 0, 1), sizeY)
            if horizontal then
            end
            VehicleDebug.drawMotorLoadGraph(self, x, y, sizeX, sizeY)
        end
    end
end
function VehicleDebug:drawMotorLoadGraph(x, y, sizeX, sizeY)
    if self.isServer then
        local motorSpec = self.spec_motorized
        if motorSpec ~= nil then
            local motor = motorSpec.motor
            local loadGraph = motor.debugLoadGraph
            local loadGraphSmooth = motor.debugLoadGraphSmooth
            local loadGraphSound = motor.debugLoadGraphSound
            if loadGraph == nil then
                loadGraph = Graph.new(500, x, y, sizeX, sizeY, 0, 100, true, "%", Graph.STYLE_LINES, 0.1, "time")
                loadGraph:setColor(1, 1, 1, 0.3)
                motor.debugLoadGraph = loadGraph
                loadGraphSmooth = Graph.new(500, x, y, sizeX, sizeY, 0, 100, false, "", Graph.STYLE_LINES)
                loadGraphSmooth:setColor(0, 1, 0, 1)
                motor.debugLoadGraphSmooth = loadGraphSmooth
                loadGraphSound = Graph.new(500, x, y, sizeX, sizeY, 0, 100, false, "", Graph.STYLE_LINES)
                loadGraphSound:setColor(0, 1, 1, 1)
                motor.debugLoadGraphSound = loadGraphSound
            else
                loadGraph.left = x
                loadGraph.bottom = y
                loadGraph.width = sizeX
                loadGraph.height = sizeY
                loadGraphSmooth.left = x
                loadGraphSmooth.bottom = y
                loadGraphSmooth.width = sizeX
                loadGraphSmooth.height = sizeY
                loadGraphSound.left = x
                loadGraphSound.bottom = y
                loadGraphSound.width = sizeX
                loadGraphSound.height = sizeY
            end
            if loadGraph ~= nil and (loadGraphSmooth ~= nil and loadGraphSound ~= nil) then
                local i = motor:getMotorAvailableTorque()
                loadGraph:addValue(motor:getMotorAppliedTorque() / math.max(i, 0.0001) * 100, nil, true)
                loadGraphSmooth:addValue(motorSpec.smoothedLoadPercentage * 100, nil, true)
                local i = 1
                for i = i, #motorSpec.motorSamples do
                    local sample = motorSpec.motorSamples[i]
                    if sample.isGlsFile then
                        loadGraphSound:addValue(getSampleLoopSynthesisLoadFactor(sample.soundSample) * 100, nil, true)
                        break
                    end
                end
            end
            loadGraph:draw()
            loadGraphSmooth:draw()
            loadGraphSound:draw()
        end
    end
end
function VehicleDebug:drawMotorRPMGraph(x, y, sizeX, sizeY)
    if self.isServer then
        local motorSpec = self.spec_motorized
        if motorSpec ~= nil then
            local motor = motorSpec.motor
            local rpmGraph = motor.debugRPMGraph
            local rpmGraphSmooth = motor.debugRPMGraphSmooth
            local rpmGraphSound = motor.debugRPMGraphSound
            if rpmGraph == nil then
                rpmGraph = Graph.new(500, x, y, sizeX, sizeY, motor:getMinRpm(), motor:getMaxRpm(), true, " RPM", Graph.STYLE_LINES, 0.1, "")
                rpmGraph:setColor(1, 1, 1, 0.3)
                motor.debugRPMGraph = rpmGraph
                rpmGraphSmooth = Graph.new(500, x, y, sizeX, sizeY, motor:getMinRpm(), motor:getMaxRpm(), false, "", Graph.STYLE_LINES)
                rpmGraphSmooth:setColor(0, 1, 0, 1)
                motor.debugRPMGraphSmooth = rpmGraphSmooth
                local i = motor:getMinRpm()
                local maxSoundRpm = motor:getMaxRpm()
                local i = 1
                local i = #motorSpec.motorSamples
                local sample = 1
                for i = i, i, sample do
                    local sample = motorSpec.motorSamples[i]
                    if sample.isGlsFile then
                        i = getSampleLoopSynthesisMinRPM(sample.soundSample)
                        maxSoundRpm = getSampleLoopSynthesisMaxRPM(sample.soundSample)
                        break
                    end
                end
                rpmGraphSound = Graph.new(500, x, y, sizeX, sizeY, i, maxSoundRpm, false, "", Graph.STYLE_LINES)
                rpmGraphSound:setColor(0, 1, 1, 1)
                motor.debugRPMGraphSound = rpmGraphSound
            else
                rpmGraph.left = x
                rpmGraph.bottom = y
                rpmGraph.width = sizeX
                rpmGraph.height = sizeY
                rpmGraphSmooth.left = x
                rpmGraphSmooth.bottom = y
                rpmGraphSmooth.width = sizeX
                rpmGraphSmooth.height = sizeY
                rpmGraphSound.left = x
                rpmGraphSound.bottom = y
                rpmGraphSound.width = sizeX
                rpmGraphSound.height = sizeY
            end
            if rpmGraph ~= nil and (rpmGraphSmooth ~= nil and rpmGraphSound ~= nil) then
                rpmGraph:addValue(motor:getLastRealMotorRpm(), nil, true)
                rpmGraphSmooth:addValue(motor:getLastModulatedMotorRpm(), nil, true)
                local i = 1
                for i = i, #motorSpec.motorSamples do
                    local sample = motorSpec.motorSamples[i]
                    if sample.isGlsFile then
                        rpmGraphSound:addValue(getSampleLoopSynthesisRPM(sample.soundSample, false), nil, true)
                        break
                    end
                end
            end
            rpmGraph:draw()
            rpmGraphSmooth:draw()
            rpmGraphSound:draw()
        end
    end
end
function VehicleDebug:drawMotorAccelerationGraph(x, y, sizeX, sizeY)
    if self.isServer then
        local motorSpec = self.spec_motorized
        if motorSpec ~= nil then
            local motor = motorSpec.motor
            local accGraph = motor.debugAccelerationGraph
            if accGraph == nil then
                accGraph = Graph.new(250, x, y, sizeX, sizeY, 0, 1, true, " Load Factor", Graph.STYLE_LINES, 0.1, "")
                accGraph:setColor(1, 1, 1, 0.3)
                motor.debugAccelerationGraph = accGraph
                motor.debugAccelerationGraphAddValue = true
            else
                accGraph.left = x
                accGraph.bottom = y
                accGraph.width = sizeX
                accGraph.height = sizeY
            end
            if accGraph ~= nil then
                if motor.debugAccelerationGraphAddValue then
                    accGraph:addValue(motor.constantAccelerationCharge, nil, true)
                end
                motor.debugAccelerationGraphAddValue = not motor.debugAccelerationGraphAddValue
            end
            accGraph:draw()
        end
    end
end
function VehicleDebug:drawDebugRendering()
    local textHeight1, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.65)
    local y = 0.64 - textHeight1 - 0.005
    local height = VehicleDebug.drawWheelInfoRendering(self, 0.015, y)
    VehicleDebug.drawDifferentialInfoRendering(self, 0.015, y - (height + getCorrectTextSize(0.02)))
    VehicleDebug.drawAxleInfoRendering(self, 0.29500000000000004, y - (height + getCorrectTextSize(0.02)))
    VehicleDebug.drawWheelSlipGraphs(self)
    VehicleDebug.drawMotorGraphs(self, 0.65, 0.44, 0.25, 0.2, false)
end
function VehicleDebug:drawTuningDebug()
    local textHeight1, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.9)
    local y = 0.89 - textHeight1 - 0.005
    local height = VehicleDebug.drawWheelInfoRendering(self, 0.015, y)
    VehicleDebug.drawDifferentialInfoRendering(self, 0.015, y - (height + getCorrectTextSize(0.02)))
    VehicleDebug.drawAxleInfoRendering(self, 0.29500000000000004, y - (height + getCorrectTextSize(0.02)))
end
function VehicleDebug:drawTransmissionDebug()
    local textHeight1, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.65)
    VehicleDebug.drawMotorGraphs(self, 0.01, 0.73, 0.25, 0.2, true)
    local str1 = ""
    local str2 = ""
    local motorSpec = self.spec_motorized
    if motorSpec ~= nil then
        local motor = motorSpec.motor
        local gears = motor.startGearValues.slope
        local width = motor.startGearValues.slope
        Utils.renderMultiColumnText(0.015, 0.65 - textHeight1, getCorrectTextSize(0.018), { ((((((((((((((((((str1 .. "\ngear start values:\n") .. "peakPower:\n") .. "maxForce:\n") .. "mass:\n") .. "slope angle:\n") .. "slope percentage:\n") .. "dirDiffXZ:\n") .. "dirDiffY:\n") .. "dirFac:\n") .. "massFac:\n") .. "speedLimit:\n") .. "auto shift allowed:\n") .. "gear/group change allowed:\n") .. "gear group shift timer:\n") .. "clutch slipping simer:\n") .. "motor can run:\n") .. "stall timer:\n") .. "turbo scale:\n") .. "blowOffValveState:\n", ((((((((((((((((((str2 .. "\n\n") .. string.format("%d/%dkW\n", motor.startGearValues.availablePower, motor.peakMotorPower)) .. string.format("%.2fkN\n", motor.startGearValues.maxForce)) .. string.format("%.2fto\n", motor.startGearValues.mass)) .. string.format("%.2f\194\176\n", (math.deg(gears)))) .. string.format("%.2f%%\n", math.atan(width) * 100)) .. string.format("%.2f\n", motor.startGearValues.massDirectionDifferenceXZ)) .. string.format("%.2f\n", motor.startGearValues.massDirectionDifferenceY)) .. string.format("%.2f\n", motor.startGearValues.massDirectionFactor)) .. string.format("%.2f\n", motor.startGearValues.massFactor)) .. string.format("%.1f / %.1f \n", motor.speedLimit, self:getSpeedLimit(true))) .. string.format("%s\n", self:getIsAutomaticShiftingAllowed())) .. string.format("%s/%s\n", motor:getIsGearChangeAllowed(), motor:getIsGearGroupChangeAllowed())) .. string.format("%.1f/%.1f sec\n", motor.gearGroupUpShiftTimer / 1000, motor.gearGroupUpShiftTime / 1000)) .. string.format("%d ms\n", motor.clutchSlippingTimer)) .. string.format("%s\n", motor:getCanMotorRun())) .. string.format("%.2f\n", motor.stallTimer)) .. string.format("%d%%\n", motor.lastTurboScale * 100)) .. string.format("%d%%\n", motor.blowOffValveState * 100) }, 0.008, { RenderText.ALIGN_RIGHT, RenderText.ALIGN_LEFT })
        if motor.forwardGears or motor.backwardGears then
            local gears = motor.forwardGears
            if motor.currentDirection < 0 then
            end
            local width = #gears * 0.035 + 0.05
            drawOutlineRect(0.222, 0.15, width, 0.35, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
            drawFilledRect(0.222, 0.15, width, 0.35, 0, 0, 0, 0.4)
            local gearAreaWidth = width - 0.05
            drawFilledRect(0.272, 0.15, g_pixelSizeX, 0.35, 0, 0, 0, 1)
            drawFilledRect(0.272, 0.46499999999999997, gearAreaWidth, g_pixelSizeY, 0, 0, 0, 1)
            drawFilledRect(0.272, 0.255, gearAreaWidth, g_pixelSizeY, 0, 0, 0, 1)
            local groupRatioReal = motor:getGearRatioMultiplier()
            local groupRatio = math.abs((motor:getGearRatioMultiplier()))
            local maxDiffSpeed = 1
            local i = 1
            for i = i, numGears do
                maxDiffSpeed = math.max(maxDiffSpeed, motor.maxRpm * 3.141592653589793 / (30 * gears[i].ratio * groupRatio) * 3.6)
            end
            local i = nil
            local lastMaxPower = nil
            local i = 1
            local maxFactorGroup = 1
            for i = i, numGears, maxFactorGroup do
                local gear = gears[i]
                local minGearSpeed = motor.minRpm * 3.141592653589793 / (30 * gear.ratio * groupRatio) * 3.6
                local gearX = 0.272 + gearAreaWidth / #gears * ((i or gear.lastDiffSpeedAfterChange) - 1)
                local posY = 0.255 + g_pixelSizeY + minGearSpeed / maxDiffSpeed * 0.21
                local factor = drawFilledRect
                factor(gearX, posY, gearWidth, (motor.maxRpm * 3.141592653589793 / (30 * gear.ratio * groupRatio) * 3.6 - minGearSpeed) / maxDiffSpeed * 0.21, (motor.gear == i or not gear.lastHasPower) and 0.05 or 1, (motor.gear == i or gear.lastHasPower) and 1 or 0.05, 0.05, 0.85)
                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(gearX + gearWidth * 0.5, posY + 0.00375, 0.015, string.format("%.2f", gear.ratio * groupRatio))
                local factor = motor:getStartInGearFactor(gear.ratio * groupRatio)
                if factor < motor.startGearThreshold then
                    setTextColor(0, 1, 0, 1)
                else
                    setTextColor(1, 0, 0, 1)
                end
                renderText(gearX + gearWidth * 0.5, 0.255 + g_pixelSizeY + 0.21 - 0.015, 0.015, string.format("%.2f", factor))
                if groupRatioReal ~= groupRatio then
                    local factor = motor:getStartInGearFactor(gear.ratio * groupRatioReal)
                    if factor < motor.startGearThreshold then
                        setTextColor(0, 1, 0, 1)
                    else
                        setTextColor(1, 0, 0, 1)
                    end
                    renderText(gearX + gearWidth * 0.5, 0.255 + g_pixelSizeY + 0.21 - 0.03, 0.012, string.format("%.2f", factor))
                end
                setTextColor(1, 1, 1, 1)
                renderText(gearX + gearWidth * 0.5, 0.1575, 0.0125, string.format("%.2f %.2f", gear.lastPowerFactor or 0, gear.lastRpmFactor or 0))
                renderText(gearX + gearWidth * 0.5, 0.1785, 0.0125, string.format("%.2f %.2f", gear.lastGearChangeFactor or 0, gear.lastRpmPreferenceFactor or 0))
                if gear.nextPowerValid then
                    setTextColor(0, 1, 0, 1)
                else
                    setTextColor(1, 0, 0, 1)
                end
                renderText(gearX + gearWidth * 0.5, 0.1995, 0.015, string.format("%d", gear.lastNextPower or -1))
                if gear.nextRpmValid then
                    setTextColor(0, 1, 0, 1)
                else
                    setTextColor(1, 0, 0, 1)
                end
                renderText(gearX + gearWidth * 0.5, 0.2205, 0.015, string.format("%d", gear.lastNextRpm or -1))
                setTextColor(1, 1, 1, 1)
                renderText(gearX + gearWidth * 0.5, 0.2415, 0.015, string.format("%.2f", gear.lastTradeoff or 0))
            end
            setTextAlignment(RenderText.ALIGN_CENTER)
            renderText(0.247, 0.255 + g_pixelSizeY + 0.21 - 0.015, 0.015, "startFactor")
            local bestGear, maxFactorGroup = motor:getBestStartGear(motor.currentGears)
            renderText(0.247, 0.255 + g_pixelSizeY + 0.21 - 0.03, 0.015, string.format("best\ngroup %d\ngear %d", maxFactorGroup, bestGear))
            renderText(0.247, 0.1575, 0.01, "pwr/rpm")
            renderText(0.247, 0.1785, 0.01, "gearC/rpmPref")
            renderText(0.247, 0.1995, 0.01, string.format("nextPwr (%d)", lastMaxPower or -1))
            renderText(0.247, 0.2205, 0.01, "nextRpm")
            renderText(0.247, 0.2415, 0.01, "tradeoff")
            local gear = motor.differentialRotSpeed * 3.6
            local i = math.abs(gear)
            local gear = 0.255 + i / maxDiffSpeed * (0.21 - g_pixelSizeY) + g_pixelSizeY
            setTextBold(true)
            setTextAlignment(RenderText.ALIGN_CENTER)
            renderText(0.247, gear - 0.005, 0.015, string.format("%.2f", i))
            setTextBold(false)
            if i ~= nil then
                setTextAlignment(RenderText.ALIGN_LEFT)
                renderText(0.277, 0.4774999999999999, 0.01, string.format("Speed after change: %.2fkm/h (%.1f sec)", i * 3.6, motor.gearChangeTime / 1000))
            end
            drawFilledRect(0.272, gear, gearAreaWidth, g_pixelSizeY, 0, 1, 0, 0.5)
        end
    end
end
function VehicleDebug.drawDebugAttributeRendering(vehicle)
    if vehicle.debugSizeOffsetNode == nil then
        vehicle.debugSizeOffsetNode = createTransformGroup("debugSizeOffsetNode")
        link(vehicle.rootNode, vehicle.debugSizeOffsetNode)
        local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        if storeItem ~= nil then
            local shopTransOffset = storeItem.shopTranslationOffset
            if shopTransOffset ~= nil then
                setTranslation(vehicle.debugSizeOffsetNode, -shopTransOffset[1], -shopTransOffset[2], -shopTransOffset[3])
            end
            local rotOffset = storeItem.shopRotationOffset
            if rotOffset ~= nil then
                setRotation(vehicle.debugSizeOffsetNode, -rotOffset[1], -rotOffset[2], -rotOffset[3])
            end
        end
    end
    local storeItem = vehicle.size.widthOffset
    local shopTransOffset = vehicle.size.heightOffset + vehicle.size.height / 2
    local rotOffset = vehicle.size.lengthOffset
    DebugBox.renderAtNodeWithOffset(vehicle.debugSizeOffsetNode, storeItem, shopTransOffset, rotOffset, vehicle.size.width, vehicle.size.height, vehicle.size.length, Color.PRESETS.BLUE, true, "size")
    if vehicle.spec_attacherJoints ~= nil then
        for _, implement in pairs(vehicle.spec_attacherJoints.attachedImplements) do
            if implement.object ~= nil then
                local attacherJoint = implement.object:getActiveInputAttacherJoint()
                if #attacherJoint.heightNodes > 0 then
                    local i = 1
                    for i = i, #attacherJoint.heightNodes do
                        local heightNode = attacherJoint.heightNodes[i]
                        local hx, hy, hz = getWorldTranslation(heightNode.node)
                        local ht = getTerrainHeightAtWorldPos(g_terrainNode, hx, hy, hz)
                        DebugGizmo.renderAtNode(heightNode.node, string.format("HeightNode: %.3f", hy - ht))
                    end
                end
            end
        end
        for _, implement in pairs(vehicle:getAttacherJoints()) do
            local attacherJoint = implement.subTypes ~= nil and string.format(" (%s)", table.concat(implement.subTypes, ", ")) or ""
            DebugGizmo.renderAtNode(implement.jointTransform, getName(implement.jointTransform) .. attacherJoint, false, 0.3)
            if implement.bottomArm ~= nil and implement.bottomArm.referenceDistance ~= nil then
                for heightNode, hx in pairs(AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY) do
                    local hy = VehicleDebug.DEBUG_COLORS[heightNode + 1]
                    if hx < implement.bottomArm.minWidth or implement.bottomArm.maxWidth < hx then
                        hy = VehicleDebug.COLOR.GREY
                    end
                    local hz, ht, b = hy:unpack()
                    local x1, y1, z1 = localToWorld(implement.bottomArm.translationNode, hx * 0.5, 0, implement.bottomArm.referenceDistance * implement.bottomArm.zScale)
                    local x2, y2, z2 = localToWorld(implement.bottomArm.translationNode, -hx * 0.5, 0, implement.bottomArm.referenceDistance * implement.bottomArm.zScale)
                    drawDebugLine(x1, y1 - 0.1, z1, hz, ht, b, x1, y1 + 0.1, z1, hz, ht, b, true)
                    drawDebugLine(x2, y2 - 0.1, z2, hz, ht, b, x2, y2 + 0.1, z2, hz, ht, b, true)
                    local radius = AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[heightNode] * 0.5
                    DebugSphere.renderAtPosition(x1, y1, z1, radius, hy, 10, true, false, nil)
                    DebugSphere.renderAtPosition(x2, y2, z2, radius, hy, 10, true, false, nil)
                end
            end
            if implement.transNode ~= nil and getVisibility(implement.transNode) then
                local x, y, i = getWorldTranslation(implement.transNode)
                local heightNode, hx, hy = localDirectionToWorld(implement.jointTransform, 0, 1, 0)
                local hz, ht, b = localDirectionToWorld(implement.jointTransform, 0, 0, 1)
                DebugBox.renderAtPosition(x - b * 0.05, y + ht * 0.05, i + hz * 0.05, heightNode, hx, hy, hz, ht, b, 0.2, implement.transNodeHeight, 0.3, Color.PRESETS.GREEN, true, nil, false)
            end
        end
    end
    if vehicle.spec_attachable ~= nil then
        local attacherVehicle = vehicle:getAttacherVehicle()
        local activeInputAttacherJoint = vehicle:getActiveInputAttacherJoint()
        for attacherJoint, x in pairs(vehicle:getInputAttacherJoints()) do
            if x.jointType == AttacherJoints.JOINTTYPE_IMPLEMENT and x.bottomArm ~= nil then
                for hx, hy in ipairs(x.bottomArm.widths) do
                    local hz = AttacherJoints.getClosestLowerLinkCategoryIndex(hy)
                    local ht, b, x1 = VehicleDebug.DEBUG_COLORS[hz + 1]:unpack()
                    local y1, z1, x2 = localToWorld(x.node, 0, 0, hy * 0.5)
                    local y2, z2, radius = localToWorld(x.node, 0, 0, -hy * 0.5)
                    drawDebugLine(y1, z1 - 0.1, x2, ht, b, x1, y1, z1 + 0.1, x2, ht, b, x1, true)
                    drawDebugLine(y2, z2 - 0.1, radius, ht, b, x1, y2, z2 + 0.1, radius, ht, b, x1, true)
                    local radius = AttacherJoints.LOWER_LINK_BALL_SIZE_BY_CATEGORY[hz] * 0.5
                    DebugSphere.renderAtPosition(y1, z1, x2, radius, VehicleDebug.DEBUG_COLORS[hz + 1], 10, true, false, nil)
                    DebugSphere.renderAtPosition(y2, z2, radius, radius, VehicleDebug.DEBUG_COLORS[hz + 1], 10, true, false, nil)
                end
            end
            if activeInputAttacherJoint == nil or x == activeInputAttacherJoint then
                local y, i, heightNode = getWorldTranslation(x.node)
                drawDebugPoint(y, i, heightNode, 1, 0, 0, 1)
                local hx = {
                    ["raycastCallback"] = function(self, transformId, _, _, _, distance)
                        -- upvalues: (copy) attacherVehicle, (copy) vehicle
                        if attacherVehicle ~= nil and attacherVehicle.vehicleNodes[transformId] ~= nil then
                            return true
                        end
                        if vehicle.vehicleNodes[transformId] ~= nil then
                            return true
                        end
                        self.groundDistance = distance
                        return false
                    end,
                    ["groundDistance"] = 0
                }
                raycastAll(y, i, heightNode, 0, -1, 0, 4, "raycastCallback", hx, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING)
                drawDebugLine(y, i, heightNode, 0, 1, 0, y, i - hx.groundDistance, heightNode, 0, 1, 0)
                drawDebugPoint(y, i - hx.groundDistance, heightNode, 1, 0, 0, 1)
                Utils.renderTextAtWorldPosition(y, i + 0.1, heightNode, string.format("%.4f", hx.groundDistance), getCorrectTextSize(0.02), 0)
            end
        end
    end
    if vehicle.spec_wheels ~= nil then
        for _, implement in ipairs(vehicle:getWheels()) do
            implement.destruction:drawAreas()
        end
    end
    if vehicle.spec_workArea ~= nil then
        local activeInputAttacherJoint = 0
        for attacherJoint, x in pairs(vehicle.spec_workArea.workAreas) do
            local y = ({})[x.type]
            if y == nil then
                activeInputAttacherJoint = activeInputAttacherJoint + 1
                attacherVehicle[x.type] = VehicleDebug.DEBUG_COLORS[activeInputAttacherJoint]
            end
            local i, heightNode, hx = getWorldTranslation(x.start)
            local heightNode = heightNode < 0 and -100 or getTerrainHeightAtWorldPos(g_terrainNode, i, 0, hx) + 0.1
            local hy, hz, ht = getWorldTranslation(x.width)
            local hz = hz < 0 and -100 or getTerrainHeightAtWorldPos(g_terrainNode, hy, 0, ht) + 0.1
            local b, x1, y1 = getWorldTranslation(x.height)
            local x1 = x1 < 0 and -100 or getTerrainHeightAtWorldPos(g_terrainNode, b, 0, y1) + 0.1
            DebugPlane.renderWithPositions(i, heightNode, hx, hy, hz, ht, b, x1, y1, y, false)
            local z1, x2, y2 = getWorldTranslation(x.start)
            local z2, radius, radius = getWorldTranslation(x.width)
            local x3, _, z3 = getWorldTranslation(x.height)
            local x = x3 + (z2 - x3) * 0.5
            local z = z3 + (radius - z3) * 0.5
            local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
            local y = y < 0 and -100 or y
            local textColor = vehicle:getIsWorkAreaActive(x) and VehicleDebug.COLOR.ACTIVE or VehicleDebug.COLOR.INACTIVE
            local width = Utils.renderTextAtWorldPosition
            local dir2Z = g_workAreaTypeManager
            local cz = x.type
            width(x, y, z, tostring(dir2Z:getWorkAreaTypeNameByIndex(cz)), getCorrectTextSize(0.015), -getCorrectTextSize(0.015) * 0.5, textColor)
            if vehicle.spec_ridgeMarker ~= nil and (#vehicle.spec_ridgeMarker.ridgeMarkers > 0 and x.type == WorkAreaType.SOWINGMACHINE) then
                local width = calcDistanceFrom(x.start, x.width)
                local length = calcDistanceFrom(x.start, x.height)
                local dir1X, dir1Z = MathUtil.vector2Normalize(z1 - z2, y2 - radius)
                local dir2X, dir2Z = MathUtil.vector2Normalize(x3 - z1, z3 - y2)
                local cx = (z1 + z2) * 0.5
                local cz = (y2 + radius) * 0.5
                drawDebugLine(cx + dir1X * width, y, cz + dir1Z * width, 0, 1, 1, cx + dir1X * width + dir2X * length, y, cz + dir1Z * width + dir2Z * length, 0, 1, 1, true)
                drawDebugLine(cx - dir1X * width, y, cz - dir1Z * width, 0, 1, 1, cx - dir1X * width + dir2X * length, y, cz - dir1Z * width + dir2Z * length, 0, 1, 1, true)
            end
        end
    end
    if vehicle.getTipOcclusionAreas ~= nil then
        for _, implement in pairs(vehicle:getTipOcclusionAreas()) do
            DebugPlane.renderWithNodes(implement.start, implement.width, implement.height, Color.PRESETS.YELLOW, true)
        end
    end
    if vehicle.spec_foliageBending ~= nil then
        for implement, attacherJoint in ipairs(vehicle.spec_foliageBending.bendingNodes) do
            if attacherJoint.isActive then
                DebugUtil.drawDebugRectangle(attacherJoint.node, attacherJoint.minX, attacherJoint.maxX, attacherJoint.minZ, attacherJoint.maxZ, attacherJoint.yOffset, 1, 0, 0)
                DebugUtil.drawDebugRectangle(attacherJoint.node, attacherJoint.minX - 0.25, attacherJoint.maxX + 0.25, attacherJoint.minZ - 0.25, attacherJoint.maxZ + 0.25, attacherJoint.yOffset, 0, 1, 0)
            end
        end
    end
    if vehicle.spec_licensePlates ~= nil then
        for implement, attacherJoint in ipairs(vehicle.spec_licensePlates.licensePlates) do
            DebugGizmo.renderAtNode(attacherJoint.node)
            local x = attacherJoint.placementArea[1]
            local y = attacherJoint.placementArea[2]
            local i = attacherJoint.placementArea[3]
            local heightNode = attacherJoint.placementArea[4];
            (function(licensePlate, d1, d2, d3, leftRight)
                if math.abs(d1) ~= math.huge then
                    local r1 = 1
                    local g1 = 0
                    local b1 = 0
                    if d2 == math.huge then
                        r1 = 0
                        g1 = 1
                        b1 = 0
                        d2 = 0.25
                    end
                    local r2 = 1
                    local g2 = 0
                    local b2 = 0
                    if d3 == math.huge then
                        r2 = 0
                        g2 = 1
                        b2 = 0
                        d3 = 0.25
                    end
                    local x1, y1, z1, x2, y2, z2
                    if leftRight then
                        x1, y1, z1 = localToWorld(licensePlate.node, d1, d2, 0)
                        x2, y2, z2 = localToWorld(licensePlate.node, d1, -d3, 0)
                    else
                        x1, y1, z1 = localToWorld(licensePlate.node, d2, d1, 0)
                        x2, y2, z2 = localToWorld(licensePlate.node, -d3, d1, 0)
                    end
                    drawDebugLine(x1, y1, z1, r1, g1, b1, x2, y2, z2, r2, g2, b2)
                end
            end)(attacherJoint, y, x, i, true)
            attacherVehicle(attacherJoint, -heightNode, x, i, true)
            attacherVehicle(attacherJoint, x, y, heightNode, false)
            attacherVehicle(attacherJoint, -i, y, heightNode, false)
        end
    end
    if vehicle.spec_fillUnit ~= nil then
        local attacherVehicle = vehicle:getFillUnits()
        for _ = 1, #attacherVehicle do
            local implement = attacherVehicle[_]
            local attacherJoint = implement.autoAimTarget
            if attacherJoint.node ~= nil and (attacherJoint.startZ ~= nil and attacherJoint.endZ ~= nil) then
                local x = implement.capacity * attacherJoint.startPercentage
                local y = math.clamp((implement.fillLevel - x) / (implement.capacity - x), 0, 1)
                if attacherJoint.invert then
                end
                local heightNode, hx, hy = localToWorld(getParent(attacherJoint.node), attacherJoint.baseTrans[1], attacherJoint.baseTrans[2], attacherJoint.startZ)
                local hz, ht, b = localToWorld(getParent(attacherJoint.node), attacherJoint.baseTrans[1], attacherJoint.baseTrans[2], attacherJoint.endZ)
                drawDebugLine(heightNode, hx, hy, 0, 1, 0, hz, ht, b, 0, 1, 0, true)
                drawDebugLine(heightNode, hx, hy, 1, 0, 0, heightNode, hx + 0.2, hy, 1, 0, 0, true)
                drawDebugLine(hz, ht, b, 1, 0, 0, hz, ht + 0.2, b, 1, 0, 0, true)
                local x1, y1, z1 = localToWorld(getParent(attacherJoint.node), attacherJoint.baseTrans[1], attacherJoint.baseTrans[2], (attacherJoint.endZ - attacherJoint.startZ) * y + attacherJoint.startZ)
                drawDebugLine(x1, y1, z1, 0, 0, 1, x1, y1 - 0.5, z1, 0, 0, 1, true)
                local x2, y2, z2 = localToWorld(getParent(attacherJoint.node), attacherJoint.baseTrans[1] - 0.5, attacherJoint.baseTrans[2], attacherJoint.startZ + 0.75)
                local radius, radius, x3 = localToWorld(getParent(attacherJoint.node), attacherJoint.baseTrans[1] + 0.5, attacherJoint.baseTrans[2], attacherJoint.startZ + 0.75)
                drawDebugLine(x2, y2, z2, 0, 1, 1, radius, radius, x3, 0, 1, 1, true)
                local _, z3, x = localToWorld(getParent(attacherJoint.node), attacherJoint.baseTrans[1] - 0.5, attacherJoint.baseTrans[2], attacherJoint.endZ - 0.75)
                local _, z3, x = localToWorld(getParent(attacherJoint.node), attacherJoint.baseTrans[1] + 0.5, attacherJoint.baseTrans[2], attacherJoint.endZ - 0.75)
                drawDebugLine(_, z3, x, 0, 1, 1, _, z3, x, 0, 1, 1, true)
            end
        end
    end
    if vehicle.spec_dischargeable ~= nil then
        local attacherVehicle = vehicle.spec_dischargeable.dischargeNodes
        for _ = 1, #attacherVehicle do
            local attacherJoint = attacherVehicle[_].info
            local x, y, i = localToWorld(attacherJoint.node, -attacherJoint.width, 0, attacherJoint.zOffset)
            local heightNode, hx, hy = localToWorld(attacherJoint.node, attacherJoint.width, 0, attacherJoint.zOffset)
            drawDebugLine(x, y, i, 1, 0, 1, heightNode, hx, hy, 1, 0, 1)
        end
    end
    if vehicle:getIsActiveForInput() and vehicle.spec_enterable ~= nil then
        local attacherVehicle = vehicle.spec_enterable
        local activeInputAttacherJoint = attacherVehicle.cameras[attacherVehicle.camIndex]
        if activeInputAttacherJoint ~= nil then
            local name = getName(activeInputAttacherJoint.cameraPositionNode)
            local _, implement, attacherJoint = getTranslation(activeInputAttacherJoint.cameraPositionNode)
            local x = activeInputAttacherJoint.cameraPositionNode
            if activeInputAttacherJoint.rotateNode ~= nil then
                x = activeInputAttacherJoint.rotateNode
            end
            local y, i, heightNode = getRotation(x)
            if activeInputAttacherJoint.hasExtraRotationNode then
            end
            local hx = string.format("camera \'%s\': translation: %.2f %.2f %.2f  rotation: %.2f %.2f %.2f", name, _, implement, attacherJoint, math.deg(y), math.deg(i), (math.deg(heightNode)))
            setTextAlignment(RenderText.ALIGN_CENTER)
            setTextColor(0, 0, 0, 1)
            renderText(0.5 + g_pixelSizeX, 0.95 - g_pixelSizeY, 0.02, hx)
            renderText(0.5 + g_pixelSizeX, 0.98 - g_pixelSizeY, 0.05, "______________________________________________________________________")
            setTextColor(1, 1, 1, 1)
            renderText(0.5, 0.95, 0.02, hx)
            renderText(0.5, 0.98, 0.05, "______________________________________________________________________")
            setTextAlignment(RenderText.ALIGN_LEFT)
        end
        for attacherJoint, x in ipairs(attacherVehicle.cameras) do
            if x.isInside then
                local y, i, heightNode = getWorldTranslation(x.cameraPositionNode)
                local hx, hy, hz = localDirectionToWorld(x.cameraPositionNode, 0, 0, 1)
                local ht, b, x1 = localDirectionToWorld(x.cameraPositionNode, 0, 1, 0)
                DebugGizmo.renderAtPosition(y, i, heightNode, hx, hy, hz, ht, b, x1, "", false, 0.7)
            end
        end
    end
    for _, implement in pairs(vehicle.components) do
        local attacherJoint, x, y = getCenterOfMass(implement.node)
        local i, heightNode, hx = localToWorld(implement.node, attacherJoint, x, y)
        local i, heightNode, hx = localDirectionToWorld(implement.node, 0, 0, 1)
        local hy, hz, ht = localDirectionToWorld(implement.node, 0, 1, 0)
        DebugGizmo.renderAtPosition(i, heightNode, hx, i, heightNode, hx, hy, hz, ht, "CoM comp" .. _, false, 0.7)
    end
    if vehicle.spec_ikChains ~= nil then
        IKUtil.debugDrawChains(vehicle.spec_ikChains.chains, true)
    end
    if vehicle.spec_powerTakeOffs ~= nil then
        local name = 1
        for name = name, #vehicle.spec_powerTakeOffs.outputPowerTakeOffs do
            local _ = vehicle.spec_powerTakeOffs.outputPowerTakeOffs[name]
            if _.outputNode ~= nil then
                local attacherJoint, x, y = getWorldTranslation(_.outputNode)
                local i, heightNode, hx = localDirectionToWorld(_.outputNode, 0, 0, 1)
                local hy, hz, ht = localDirectionToWorld(_.outputNode, 0, 1, 0)
                drawDebugLine(attacherJoint, x, y, 0, 1, 0, attacherJoint + hy * 0.25, x + hz * 0.25, y + ht * 0.25, 0, 1, 0)
                drawDebugLine(attacherJoint, x, y, 0, 0, 1, attacherJoint + i * 0.25, x + heightNode * 0.25, y + hx * 0.25, 0, 0, 1)
                if _.connectedInput ~= nil then
                    local b, x1, y1 = localToWorld(_.outputNode, 0, 0, -0.05)
                    local z1, x2, y2 = localDirectionToWorld(_.outputNode, 0, 1, 0)
                    local z2, radius, radius = localDirectionToWorld(_.outputNode, 0, 0, -1)
                    DebugBox.renderAtPosition(b, x1, y1, z1, x2, y2, z2, radius, radius, _.connectedInput.size, _.connectedInput.size, 0.1, Color.PRESETS.YELLOW, true, nil, false)
                end
            end
        end
    end
    if vehicle.spec_connectionHoses ~= nil then
        local name = 1
        for name = name, #vehicle.spec_connectionHoses.targetNodes do
            local _ = vehicle.spec_connectionHoses.targetNodes[name]
            local attacherJoint, x, y = getWorldTranslation(_.node)
            local i, heightNode, hx = localDirectionToWorld(_.node, 0, 0, -1)
            local hy, hz, ht = localDirectionToWorld(_.node, 0, 1, 0)
            drawDebugLine(attacherJoint, x, y, 0, 1, 0, attacherJoint + hy * 0.1, x + hz * 0.1, y + ht * 0.1, 0, 1, 0)
            drawDebugLine(attacherJoint, x, y, 0, 0, 1, attacherJoint + i * 0.1, x + heightNode * 0.1, y + hx * 0.1, 0, 0, 1)
        end
    end
    if vehicle.spec_mountable ~= nil then
        if vehicle.spec_mountable.dynamicMountJointTransY ~= nil then
            DebugUtil.drawDebugRectangle(vehicle.rootNode, -vehicle.size.width * 0.5, vehicle.size.width * 0.5, -vehicle.size.length * 0.5, vehicle.size.length * 0.5, vehicle.spec_mountable.dynamicMountJointTransY, 0, 1, 0, 0.2, true)
        end
        if vehicle.spec_mountable.additionalMountDistance ~= 0 then
            DebugUtil.drawDebugRectangle(vehicle.rootNode, -vehicle.size.width * 0.5, vehicle.size.width * 0.5, -vehicle.size.length * 0.5, vehicle.size.length * 0.5, vehicle.spec_mountable.additionalMountDistance, 1, 1, 0, 0.2, true)
        end
    end
end
function VehicleDebug.drawDebugAIRendering(vehicle)
    local function formatNumber(value)
        if math.abs(value) < 0.001 then
            return "0.0"
        elseif math.abs(value) < 0.01 then
            return string.format("%.3f", value)
        elseif math.abs(value) < 0.1 then
            return string.format("%.2f", value)
        else
            return string.format("%.1f", value)
        end
    end
    if vehicle.getAIMarkers ~= nil then
        if vehicle:getCanImplementBeUsedForAI() then
            local leftMarker, rightMarker, backMarker = vehicle:getAIMarkers();
            (function(node, text, yOffset)
                local x, y, z = getWorldTranslation(node)
                local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
                local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
                DebugGizmo.renderAtPosition(x, (y < 0 and -100 or getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)) + (yOffset or 0), z, dirX, dirY, dirZ, upX, upY, upZ, text, false, 0.5)
            end)(leftMarker, string.format("%s (x%sm z%sm)", getName(leftMarker), (function(node, useZOffset, useZOffsetFront)
                -- upvalues: (copy) vehicle, (copy) formatNumber
                local min
                if vehicle.rootVehicle.getAIRootNode == nil then
                    min = vehicle.rootNode
                else
                    min = vehicle.rootVehicle:getAIRootNode()
                end
                local min = -math.huge
                local max = math.huge
                if vehicle.spec_workArea ~= nil then
                    local nodeOffset, _, nodeOffsetZ = localToLocal(node, min, 0, 0, 0)
                    for _, workArea in pairs(vehicle.spec_workArea.workAreas) do
                        if useZOffset == true then
                            local _, _, offset = localToLocal(workArea.height, min, 0, 0, 0)
                            local offset = nodeOffsetZ - offset
                            if offset > 0 then
                                max = math.min(max, offset)
                            else
                                min = math.max(min, offset)
                            end
                        elseif useZOffsetFront == true then
                            local _, _, offset = localToLocal(workArea.start, min, 0, 0, 0)
                            local offset = nodeOffsetZ - offset
                            if offset > 0 then
                                max = math.min(max, offset)
                            else
                                min = math.max(min, offset)
                            end
                            local _, _, offset2 = localToLocal(workArea.width, min, 0, 0, 0)
                            local offset2 = nodeOffsetZ - offset2
                            if offset2 > 0 then
                                max = math.min(max, offset2)
                            else
                                min = math.max(min, offset2)
                            end
                        else
                            local _, _, offset = localToLocal(workArea.start, min, 0, 0, 0)
                            local _ = nodeOffset - _
                            if _ > 0 then
                                max = math.min(max, _)
                            else
                                min = math.max(min, _)
                            end
                            local _, _, offset2 = localToLocal(workArea.width, min, 0, 0, 0)
                            local _ = nodeOffset - _
                            if _ > 0 then
                                max = math.min(max, _)
                            else
                                min = math.max(min, _)
                            end
                            local offset3, _, _ = localToLocal(workArea.height, min, 0, 0, 0)
                            local offset3 = nodeOffset - offset3
                            if offset3 > 0 then
                                max = math.min(max, offset3)
                            else
                                min = math.max(min, offset3)
                            end
                        end
                    end
                end
                if math.abs(min) < math.abs(max) then
                    return formatNumber(min)
                else
                    return formatNumber(max)
                end
            end)(leftMarker), (function(node, useZOffset, useZOffsetFront)
                -- upvalues: (copy) vehicle, (copy) formatNumber
                local min
                if vehicle.rootVehicle.getAIRootNode == nil then
                    min = vehicle.rootNode
                else
                    min = vehicle.rootVehicle:getAIRootNode()
                end
                local min = -math.huge
                local max = math.huge
                if vehicle.spec_workArea ~= nil then
                    local nodeOffset, _, nodeOffsetZ = localToLocal(node, min, 0, 0, 0)
                    for _, workArea in pairs(vehicle.spec_workArea.workAreas) do
                        if useZOffset == true then
                            local _, _, offset = localToLocal(workArea.height, min, 0, 0, 0)
                            local offset = nodeOffsetZ - offset
                            if offset > 0 then
                                max = math.min(max, offset)
                            else
                                min = math.max(min, offset)
                            end
                        elseif useZOffsetFront == true then
                            local _, _, offset = localToLocal(workArea.start, min, 0, 0, 0)
                            local offset = nodeOffsetZ - offset
                            if offset > 0 then
                                max = math.min(max, offset)
                            else
                                min = math.max(min, offset)
                            end
                            local _, _, offset2 = localToLocal(workArea.width, min, 0, 0, 0)
                            local offset2 = nodeOffsetZ - offset2
                            if offset2 > 0 then
                                max = math.min(max, offset2)
                            else
                                min = math.max(min, offset2)
                            end
                        else
                            local _, _, offset = localToLocal(workArea.start, min, 0, 0, 0)
                            local _ = nodeOffset - _
                            if _ > 0 then
                                max = math.min(max, _)
                            else
                                min = math.max(min, _)
                            end
                            local _, _, offset2 = localToLocal(workArea.width, min, 0, 0, 0)
                            local _ = nodeOffset - _
                            if _ > 0 then
                                max = math.min(max, _)
                            else
                                min = math.max(min, _)
                            end
                            local offset3, _, _ = localToLocal(workArea.height, min, 0, 0, 0)
                            local offset3 = nodeOffset - offset3
                            if offset3 > 0 then
                                max = math.min(max, offset3)
                            else
                                min = math.max(min, offset3)
                            end
                        end
                    end
                end
                if math.abs(min) < math.abs(max) then
                    return formatNumber(min)
                else
                    return formatNumber(max)
                end
            end)(leftMarker, false, true)))
            drawDebugNode(rightMarker, string.format("%s (x%sm z%sm)", getName(rightMarker), getClosestOffset(rightMarker), getClosestOffset(rightMarker, false, true)))
            drawDebugNode(backMarker, string.format("%s (z%sm)", getName(backMarker), getClosestOffset(backMarker, true)))
            local reverserNode = vehicle:getAIToolReverserDirectionNode()
            if reverserNode ~= nil then
                local sideOffset = nil
                if vehicle.rootVehicle.getAIRootNode ~= nil then
                    local aiRootNode = vehicle.rootVehicle:getAIRootNode()
                    sideOffset, _, _ = localToLocal(reverserNode, aiRootNode, 0, 0, 0)
                end
                local aiRootNode = ""
                if reverserNode ~= backMarker then
                    aiRootNode = " " .. getName(reverserNode)
                end
                drawDebugNode(reverserNode, string.format("reverser%s (x%sm)", aiRootNode, formatNumber(sideOffset or 0)), 0.3)
            end
        end
        if not vehicle:getIsAIActive() then
            local leftMarker = vehicle:getAIImplementCollisionTrigger()
            if leftMarker ~= nil and leftMarker.node ~= nil then
                local rightMarker, backMarker, reverserNode = getWorldTranslation(leftMarker.node)
                local sideOffset = getTerrainHeightAtWorldPos(g_terrainNode, rightMarker, 0, reverserNode)
                DebugUtil.drawDebugCube(leftMarker.node, leftMarker.width, leftMarker.height, leftMarker.length, 0, 0, 1, 0, -(backMarker - (backMarker < 0 and -100 or sideOffset) - leftMarker.height * 0.5), leftMarker.length * 0.5)
            end
        end
        local leftMarker = true
        for sideOffset, _ in ipairs(vehicle.rootVehicle.childVehicles) do
            if _ ~= vehicle and (_.getCanImplementBeUsedForAI ~= nil and _:getCanImplementBeUsedForAI()) then
                leftMarker = false
                break
            end
        end
        if (leftMarker or vehicle:getIsSelected()) and (vehicle.spec_aiImplement ~= nil and vehicle.spec_aiImplement.debugArea ~= nil) then
            g_debugManager:addFrameElement(vehicle.spec_aiImplement.debugArea)
        end
    end
    if vehicle.drawDebugAIAgent ~= nil then
        vehicle:drawDebugAIAgent()
    end
    if vehicle.drawAIAgentAttachments ~= nil then
        vehicle:drawAIAgentAttachments()
    end
    if Platform.gameplay.automaticVehicleControl then
        local leftMarker = vehicle.rootVehicle
        if leftMarker.getIsControlled ~= nil and (leftMarker:getIsControlled() and leftMarker.actionController ~= nil) then
            leftMarker.actionController:drawDebugRendering()
        end
    end
end
function VehicleDebug.drawDebugValues(vehicle)
    local information = {}
    for k, v in ipairs(vehicle.specializations) do
        if v.updateDebugValues ~= nil then
            local values = {}
            v.updateDebugValues(vehicle, values)
            if #values > 0 then
                table.insert(information, {
                    ["title"] = vehicle.specializationNames[k],
                    ["content"] = values
                })
            end
        end
    end
    local d = DebugInfoTable.new()
    d:createWithNodeToCamera(vehicle.rootNode, information, 4, 0.05)
    g_debugManager:addFrameElement(d)
end
function VehicleDebug.drawSoundDebugValues(vehicle)
    local textSize = 0.015
    local function drawBar(x, y, w, h, value, fixedValue, text, r, g, b, a, textSizeFactor)
        -- upvalues: (copy) textSize
        drawOutlineRect(x, y, w, h, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
        drawFilledRect(x + g_pixelSizeX, y + g_pixelSizeY, w - g_pixelSizeX * 2, h - g_pixelSizeY * 2, 0, 0, 0, 0.4)
        drawFilledRect(x + g_pixelSizeX, y + g_pixelSizeY, w * value - g_pixelSizeX * 2, h - g_pixelSizeY * 2, r, g, b, a)
        if fixedValue ~= -1 then
            drawFilledRect(x + w * fixedValue, y, g_pixelSizeX, h, 1, 0, 0, 1)
        end
        setTextAlignment(RenderText.ALIGN_CENTER)
        renderText(x + w * 0.5, y + h - 0.0075 - g_pixelSizeY * 4, 0.012 * (textSizeFactor or 1), text)
    end
    setTextColor(1, 1, 1, 1)
    local i = 1
    local lineY = 0.9
    for _, sample in pairs(g_soundManager.orderedSamples) do
        local isSurfaceSound = false
        for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
            if surfaceSound.name == sample.sampleName then
                isSurfaceSound = true
            end
        end
        if sample.modifierTargetObject == vehicle and not isSurfaceSound then
            local showSample = sample.isGlsFile
            if not showSample then
                for surfaceSound, type in pairs(g_soundManager.modifierTypeIndexToDesc) do
                    for _, attribute in pairs({ "volume", "pitch", "lowpassGain" }) do
                        local _, _, available = g_soundManager:getSampleModifierValue(sample, attribute, surfaceSound)
                        showSample = showSample or available
                        if showSample then
                            break
                        end
                    end
                end
            end
            if showSample then
                lineY = lineY - 0.06
                drawOutlineRect(0.15, lineY, 0.1 + g_pixelSizeX, 0.06 + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                drawOutlineRect(0.15, lineY, 0.7, lineHeight + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                local modPitch = g_soundManager:getIsSamplePlaying(sample) and 1 or 0
                drawFilledRect(0.15, lineY, xSectionWidth, 0.06, 0, modPitch, 0, 0.4)
                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(0.15 + xSectionWidth * 0.5, lineY + 0.06 - 0.012 - 0.0075, 0.018, sample.sampleName)
                if sample.isGlsFile then
                    renderText(x + xSectionWidth * 0.5, lineY + 0.06 - 0.024 - 0.0075, 0.012, string.format("loopSyn: rpm=%d load=%d%%", getSampleLoopSynthesisRPM(sample.soundSample, false), getSampleLoopSynthesisLoadFactor(sample.soundSample) * 100))
                end
                setTextAlignment(RenderText.ALIGN_RIGHT)
                renderText(x + xSectionWidth + xSectionWidth * 0.6, lineY + 0.06 - 0.015 - 0.0075, 0.015, "volume:")
                renderText(x + xSectionWidth + xSectionWidth * 0.6, lineY + 0.06 - 0.03 - 0.0075, 0.015, "pitch:")
                renderText(x + xSectionWidth + xSectionWidth * 0.6, lineY + 0.06 - 0.045 - 0.0075, 0.015, "lowpassGain:")
                sample.debugMaxVolume = math.max(sample.debugMaxVolume or 1, sample.current.volume * g_soundManager:getModifierFactor(sample, "volume"), sample.current.volume)
                drawBar(x + xSectionWidth + xSectionWidth * 0.7, lineY + 0.06 - 0.015 - 0.0075, xSectionWidth, 0.015, sample.current.volume * modVolume / sample.debugMaxVolume, sample.current.volume / sample.debugMaxVolume, string.format("%.2f", sample.current.volume * modVolume), 0, 0.5, 0, 0.4);
                (function(x, y, w, h, sample, attribute)
                    -- upvalues: (copy) drawBar
                    local modifiers = {}
                    for typeIndex, type in pairs(g_soundManager.modifierTypeIndexToDesc) do
                        local changeValue, t, available = g_soundManager:getSampleModifierValue(sample, attribute, typeIndex)
                        if available then
                            table.insert(modifiers, {
                                ["changeValue"] = changeValue,
                                ["t"] = t,
                                ["name"] = type.name
                            })
                        end
                    end
                    if sample.maxValuePerModifier == nil then
                        sample.maxValuePerModifier = {}
                        for typeIndex, type in pairs(g_soundManager.modifierTypeIndexToDesc) do
                            sample.maxValuePerModifier[type.name] = 0
                        end
                    end
                    local numModifiers = #modifiers
                    if numModifiers > 0 then
                        local type = 1
                        for type = type, numModifiers do
                            local changeValue = modifiers[type]
                            sample.maxValuePerModifier[changeValue.name] = math.max(sample.maxValuePerModifier[changeValue.name], changeValue.changeValue, 1)
                            drawBar(x + w / numModifiers * (type - 1), y, widthPerModifier * (type < numModifiers and 0.95 or 1), h, changeValue.changeValue / sample.maxValuePerModifier[changeValue.name], -1, string.format("%s raw:%.2f mod:%.2f", changeValue.name, changeValue.t, changeValue.changeValue), 0, 0.5, 0, 0.3, 0.7)
                        end
                    end
                end)(barX + xSectionWidth + xSectionWidth * 0.1, _, 1 - (barX + xSectionWidth + xSectionWidth * 0.1) - 0.15 - xSectionWidth * 0.1, type, sample, "volume")
                local modPitch = g_soundManager:getModifierFactor(sample, "pitch")
                sample.debugMaxPitch = math.max(sample.debugMaxPitch or 1, sample.current.pitch * modPitch, sample.current.pitch)
                drawBar(x + xSectionWidth + xSectionWidth * 0.7, lineY + 0.06 - 0.03 - 0.0075, xSectionWidth, 0.015, sample.current.pitch * modPitch / sample.debugMaxPitch, sample.current.pitch / sample.debugMaxPitch, string.format("%.2f", sample.current.pitch * modPitch), 0.5, 0.5, 0, 0.4)
                drawModifiers(barX + xSectionWidth + xSectionWidth * 0.1, _, 1 - (barX + xSectionWidth + xSectionWidth * 0.1) - 0.15, type, sample, "pitch")
                local modLowPassGain = g_soundManager:getModifierFactor(sample, "lowpassGain")
                sample.debugMaxLowPass = math.max(sample.debugMaxLowPass or 1, sample.current.lowpassGain * modLowPassGain, sample.current.lowpassGain)
                drawBar(x + xSectionWidth + xSectionWidth * 0.7, lineY + 0.06 - 0.045 - 0.0075, xSectionWidth, 0.015, sample.current.lowpassGain * modLowPassGain / sample.debugMaxLowPass, sample.current.lowpassGain / sample.debugMaxLowPass, string.format("%.2f", sample.current.lowpassGain * modLowPassGain), 0, 0.5, 0.5, 0.4)
                drawModifiers(barX + xSectionWidth + xSectionWidth * 0.1, _, 1 - (barX + xSectionWidth + xSectionWidth * 0.1) - 0.15, type, sample, "lowpassGain")
            end
        end
    end
    local wheelsSpec = vehicle.spec_wheels
    if wheelsSpec then
        local wx, wy, _ = getWorldTranslation(vehicle.rootNode)
        Utils.renderTextAtWorldPosition(wx, wy, _, string.format("surfaceSound: %s", wheelsSpec.currentSurfaceSound and wheelsSpec.currentSurfaceSound.sampleName or "none"), 0.01)
    end
    setTextAlignment(RenderText.ALIGN_LEFT)
    VehicleDebug.drawMotorLoadGraph(vehicle, 0.2, 0.05, 0.25, 0.2)
    VehicleDebug.drawMotorRPMGraph(vehicle, 0.55, 0.05, 0.25, 0.2)
    VehicleDebug.drawMotorAccelerationGraph(vehicle, 0.2, 0.28, 0.25, 0.1)
end
function VehicleDebug.drawAnimationDebug(vehicle)
    if vehicle.playAnimation ~= nil then
        local timeLineOffset = 0.1 + g_pixelSizeX
        local numAnims = 0
        local spec = vehicle.spec_animatedVehicle
        for _, animation in pairs(spec.animations) do
            if #animation.parts > 0 then
            end
        end
        setTextColor(1, 1, 1, 1)
        local i = 1
        local lineY = 0.9
        for name, animation in pairs(spec.animations) do
            if #animation.parts > 0 then
                local lineY = lineY - 0.05
                drawOutlineRect(0.15, lineY, 0.7, 0.05 + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                drawFilledRect(0.15, lineY, 0.7, 0.05, 0, 0, 0, 0.4)
                drawFilledRect(0.15 + timeLineOffset - g_pixelSizeX, lineY, g_pixelSizeX, 0.05, 0, 0, 0, 1)
                local widthPerMs = (0.7 - timeLineOffset - g_pixelSizeX * 2) / animation.duration
                local divider = animation.duration < 2000 and 500 or 1000
                local divider = animation.duration < 1000 and 100 or divider
                local j = 1
                local k = animation.duration / divider
                local animPartIndex = math.floor(k)
                local headTextSize = 1
                for j = j, animPartIndex, headTextSize do
                    if j * divider ~= animation.duration then
                        setTextAlignment(RenderText.ALIGN_CENTER)
                        renderText(x + timeLineOffset + widthPerMs * j * divider, lineY + 0.025 - 0.005, 0.01, string.format("%.1f", j * divider / 1000))
                        drawFilledRect(x + timeLineOffset + widthPerMs * j * divider, lineY, g_pixelSizeX, 0.015, 0, 0, 0, 1)
                    end
                end
                local headTextSize = VehicleDebug.selectedAnimation % numAnims + 1 == i
                setTextBold(headTextSize)
                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(x + timeLineOffset * 0.5, lineY + 0.025 - 0.0075, 0.015, name)
                setTextBold(false)
                if selected == i then
                    if animation.lineHeightByPart == nil then
                        animation.lineHeightByPart = {}
                    else
                        for k, _ in pairs(animation.lineHeightByPart) do
                            animation.lineHeightByPart[k] = nil
                        end
                    end
                    local animPartIndex = 1
                    local headTextSize = #animation.parts
                    local j = 1
                    for animPartIndex = animPartIndex, headTextSize, j do
                        local _ = animation.parts[animPartIndex].animationValues[1]
                        local index = _.node or _.componentJoint
                        if index ~= nil and animation.lineHeightByPart[index] == nil then
                            lineY = lineY - 0.0125
                            drawOutlineRect(0.15, lineY, 0.7, 0.0125 + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                            drawFilledRect(0.15, lineY, 0.7, 0.0125, 0, 0, 0, 0.2)
                            drawFilledRect(x + timeLineOffset - g_pixelSizeX, lineY, g_pixelSizeX, 0.0125, 0, 0, 0, 1)
                            local partName = "unknown"
                            if _.node == nil then
                                if _.componentJoint ~= nil then
                                    partName = string.format("compJoint \'%d\'", _.componentJoint.index)
                                end
                            else
                                partName = string.format("node \'%s\'", getName(_.node))
                            end
                            setTextAlignment(RenderText.ALIGN_CENTER)
                            renderText(x + timeLineOffset * 0.5, lineY + 0.00625 - 0.005 + g_pixelSizeY * 2, 0.01, partName)
                            animation.lineHeightByPart[index] = lineY
                        end
                    end
                    if #animation.samples > 0 then
                        lineY = lineY - 0.018750000000000003
                        drawOutlineRect(0.15, lineY, 0.7, 0.018750000000000003 + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                        drawFilledRect(0.15, lineY, 0.7, 0.018750000000000003, 0, 0, 0, 0.2)
                        setTextAlignment(RenderText.ALIGN_CENTER)
                        renderText(0.5, lineY + 0.009375000000000001 - 0.0075 + g_pixelSizeY * 2, 0.015, "Sounds:")
                    end
                    local headTextSize = {}
                    local k = 1
                    local j = #animation.samples
                    local animPartIndex = 1
                    for k = k, j, animPartIndex do
                        local _ = animation.samples[k]
                        if headTextSize[_.filename] == nil then
                            headTextSize[_.filename] = {}
                        end
                        table.insert(headTextSize[_.filename], {
                            ["sample"] = _,
                            ["startTime"] = _.startTime,
                            ["endTime"] = _.endTime,
                            ["loops"] = _.loops,
                            ["direction"] = _.direction
                        })
                    end
                    for _, index in pairs(headTextSize) do
                        lineY = lineY - 0.0125
                        drawOutlineRect(0.15, lineY, 0.7, lineHeightPart + g_pixelSizeY, g_pixelSizeX, g_pixelSizeY, 0, 0, 0, 1)
                        drawFilledRect(0.15, lineY, 0.7, 0.0125, 0, 0, 0, 0.2)
                        drawFilledRect(x + timeLineOffset - g_pixelSizeX, lineY, g_pixelSizeX, 0.0125, 0, 0, 0, 1)
                        local partName = "unknown"
                        local timesIndex = 1
                        for timesIndex = timesIndex, #index do
                            local timeData = index[timesIndex]
                            partName = timeData.sample.templateName or timeData.sample.sampleName
                            local r = 0
                            local g = 0
                            if g_soundManager:getIsSamplePlaying(timeData.sample) then
                                g = 1
                                if timeData.loops == 1 then
                                    r = 1
                                end
                            end
                            local rx = 0
                            local ry = lineY + 0.0012500000000000002 + g_pixelSizeY
                            local rwidth = 0
                            local rheight = 0.010000000000000002 - g_pixelSizeY
                            if timeData.startTime == nil or timeData.endTime ~= nil then
                                if timeData.startTime == nil or (timeData.endTime == nil or timeData.loops ~= 0) then
                                    if timeData.startTime ~= nil and (timeData.endTime ~= nil and timeData.loops == 1) then
                                        local rx = math.max(x + timeLineOffset, x + timeLineOffset + widthPerMs * timeData.startTime - widthPerMs * 25)
                                        local rwidth = widthPerMs * 50
                                        local rwidth = rwidth + math.min(0.85 - (rx + rwidth), 0)
                                        drawFilledRect(rx, ry, rwidth, rheight, r, g, 0, 0.9)
                                        rx = math.max(minX, x + timeLineOffset + widthPerMs * timeData.endTime - widthPerMs * 25)
                                        local rwidth = widthPerMs * 50
                                        rwidth = rwidth + math.min(0.85 - (rx + rwidth), 0)
                                    end
                                else
                                    rx = x + timeLineOffset + widthPerMs * timeData.startTime + widthPerMs * 5
                                    rwidth = widthPerMs * (timeData.endTime - timeData.startTime) - widthPerMs * 10
                                end
                            else
                                rx = math.max(minX, x + timeLineOffset + widthPerMs * timeData.startTime - widthPerMs * 25)
                                local rwidth = widthPerMs * 50
                                rwidth = rwidth + math.min(0.85 - (rx + rwidth), 0)
                            end
                            drawFilledRect(rx, ry, rwidth, rheight, r, g, 0, 0.9)
                        end
                        setTextAlignment(RenderText.ALIGN_CENTER)
                        renderText(x + timeLineOffset * 0.5, lineY + 0.00625 - 0.005 + g_pixelSizeY * 2, 0.01, partName)
                    end
                    local k = 1
                    local j = #animation.parts
                    local animPartIndex = 1
                    for k = k, j, animPartIndex do
                        local _ = animation.parts[k]
                        local index = _.animationValues[1]
                        local partName = index.node or index.componentJoint
                        if partName ~= nil then
                            drawFilledRect(x + timeLineOffset + widthPerMs * _.startTime, animation.lineHeightByPart[partName] + 0.0012500000000000002 + g_pixelSizeY, widthPerMs * _.duration, 0.010000000000000002 - g_pixelSizeY, 0, 0, 0, 0.9)
                        end
                    end
                end
                drawFilledRect(x + timeLineOffset + widthPerMs * animation.currentTime, lineY, g_pixelSizeX, lineY - lineY + 0.034999999999999996, 0, 1, 0, 1)
                setTextAlignment(RenderText.ALIGN_CENTER)
                renderText(x + timeLineOffset + widthPerMs * animation.currentTime, lineY + (lineY - lineY) + 0.045000000000000005 - 0.005, 0.01, string.format("%.2f", animation.currentTime / 1000))
                i = i + 1
            end
        end
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end
function VehicleDebug.updateTuningDebugRendering(vehicle, _)
    if vehicle.propertyState == VehiclePropertyState.SHOP_CONFIG then
        local visualWheelIndex = 0
        local wheels = vehicle:getWheels()
        local i = 1
        for i = i, #wheels do
            local wheel = wheels[i]
            local x, y, z = getWorldTranslation(wheels[i].driveNodeDirectionNode)
            local offset
            if y < 50 then
                offset = y + 100
            else
                offset = y - getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
            end
            drawDebugLine(x, y - wheel.physics.radius, z, 0, 1, 0, x, y, z, 0, 1, 0, false)
            Utils.renderTextAtWorldPosition(x, y - wheel.physics.radius * 0.5, z, string.format("%.3f", offset), getCorrectTextSize(0.012), 0, 0, 1, 0, 1)
            for _, visualWheel in ipairs(wheel.visualWheels) do
                for _, visualWheelPart in ipairs(visualWheel.visualParts) do
                    if visualWheelPart:isa(WheelVisualPartTire) then
                        local ox, oy, oz = localToLocal(visualWheelPart.node, wheel.node, 0, 0, 0)
                        local wx, wy, wz = localToWorld(visualWheelPart.node, 0, 0, 0)
                        local cx, cy, cz = localToWorld(wheel.node, 0, oy, oz)
                        drawDebugLine(wx, wy, wz, 1, 0, 0, cx, cy, cz, 1, 0, 0, false)
                        Utils.renderTextAtWorldPosition(wx, wy, wz, string.format("%.3f", math.abs(ox) * 2), getCorrectTextSize(0.012), 0, 1, 0, 0, 1)
                        local widthOffset = visualWheel.width * 0.5 * (wheel.isLeft and 1 or -1)
                        local ox, oy, oz = localToLocal(visualWheelPart.node, wheel.node, widthOffset, 0, 0)
                        local wx, wy, wz = localToWorld(visualWheelPart.node, widthOffset, 0, 0)
                        drawDebugLine(wx, wy - 0.1, wz, 0, 1, 1, wx, wy + 0.1, wz, 0, 1, 1, false)
                        Utils.renderTextAtWorldPosition(wx, wy, wz, string.format("%.3f", math.abs(ox) * 2), getCorrectTextSize(0.012), 0, 0, 1, 1, 1)
                    end
                end
                renderText(0.25, 0.1 + 0.02 * visualWheelIndex, 0.018, string.format("%d - %s (%s)", i, visualWheel.externalXMLFilename, visualWheel.externalConfigId))
                visualWheelIndex = visualWheelIndex + 1
            end
        end
    end
end
function VehicleDebug.consoleCommandAnalyze(unusedSelf)
    if g_currentMission == nil or (g_localPlayer:getCurrentVehicle() == nil or not g_localPlayer:getCurrentVehicle().isServer) then
        return "Failed to analyze vehicle. Invalid controlled vehicle"
    end
    local self = g_localPlayer:getCurrentVehicle():getSelectedVehicle()
    if self == nil then
        self = g_localPlayer:getCurrentVehicle()
    end
    print("Analyzing vehicle \'" .. self.configFileName .. "\'. Make sure vehicle is standing on a flat plane parallel to xz-plane")
    if self.spec_attacherJoints ~= nil then
        for i, attacherJoint in ipairs(self.spec_attacherJoints.attacherJoints) do
            local trx, try, trz = getRotation(attacherJoint.jointTransform)
            local rx = setRotation
            local ry = attacherJoint.jointTransform
            local rx2 = attacherJoint.jointOrigRot
            rx(ry, unpack(rx2))
            if attacherJoint.rotationNode ~= nil or attacherJoint.rotationNode2 ~= nil then
                local rx = nil
                local ry = nil
                local rz = nil
                if attacherJoint.rotationNode ~= nil then
                    rx, ry, rz = getRotation(attacherJoint.rotationNode)
                end
                local rx2 = nil
                local ry2 = nil
                local rz2 = nil
                if attacherJoint.rotationNode2 ~= nil then
                    rx2, ry2, rz2 = getRotation(attacherJoint.rotationNode2)
                end
                if attacherJoint.rotationNode ~= nil then
                    setRotation(attacherJoint.rotationNode, unpack(attacherJoint.lowerRotation))
                end
                if attacherJoint.rotationNode2 ~= nil then
                    setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.lowerRotation2))
                end
                local x, y, z = getWorldTranslation(attacherJoint.jointTransform);
                ({
                    ["raycastCallback"] = function(self, transformId, _, _, _, distance, _, _, _)
                        if self.vehicle.vehicleNodes[transformId] ~= nil then
                            return true
                        end
                        if self.vehicle.aiTrafficCollisionTrigger == transformId then
                            return true
                        end
                        if transformId ~= g_terrainNode then
                            printWarning("Warning: Vehicle is not standing on ground! " .. getName(transformId))
                        end
                        self.groundDistance = distance
                        return false
                    end
                }).groundDistance = 0
                groundRaycastResult.vehicle = self
                raycastAll(x, y, z, 0, -1, 0, 4, "raycastCallback", groundRaycastResult, 4294967295)
                local dy = groundRaycastResult.groundDistance - attacherJoint.lowerDistanceToGround
                if math.abs(dy) > 0.01 then
                    print(string.format(" Issue found: Attacher joint %d has invalid lowerDistanceToGround. True value is: %.3f (Value in xml: %.3f)", i, MathUtil.round(groundRaycastResult.groundDistance, 3), attacherJoint.lowerDistanceToGround))
                end
                if attacherJoint.rotationNode ~= nil and attacherJoint.rotationNode2 ~= nil then
                    local _, dy, _ = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0)
                    local dxy = math.clamp(dy, -1, 1)
                    local angle = math.deg((math.acos(dxy)))
                    local _, dxy, _ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)
                    if dxy < 0 then
                    end
                    if math.abs(angle - math.deg(attacherJoint.lowerRotationOffset)) > 0.05 then
                        print(string.format(" Issue found: Attacher joint %d has invalid lowerRotationOffset. True value is: %.2f\194\176 (Value in xml: %.2f\194\176)", i, angle, (math.deg(attacherJoint.lowerRotationOffset))))
                    end
                end
                if attacherJoint.rotationNode ~= nil then
                    setRotation(attacherJoint.rotationNode, unpack(attacherJoint.upperRotation))
                end
                if attacherJoint.rotationNode2 ~= nil then
                    setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.upperRotation2))
                end
                local _, dy, _ = getWorldTranslation(attacherJoint.jointTransform)
                groundRaycastResult.groundDistance = 0
                raycastAll(_, dy, _, 0, -1, 0, 4, "raycastCallback", groundRaycastResult, 4294967295)
                local dy = groundRaycastResult.groundDistance - attacherJoint.upperDistanceToGround
                if math.abs(dy) > 0.01 then
                    print(string.format(" Issue found: Attacher joint %d has invalid upperDistanceToGround. True value is: %.3f (Value in xml: %.3f)", i, MathUtil.round(groundRaycastResult.groundDistance, 3), attacherJoint.upperDistanceToGround))
                end
                if attacherJoint.rotationNode ~= nil and attacherJoint.rotationNode2 ~= nil then
                    local _, dy, _ = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0)
                    local dxy = math.clamp(dy, -1, 1)
                    local angle = math.deg((math.acos(dxy)))
                    local _, dxy, _ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)
                    if dxy < 0 then
                    end
                    if math.abs(angle - math.deg(attacherJoint.upperRotationOffset)) > 0.05 then
                        print(string.format(" Issue found: Attacher joint %d has invalid upperRotationOffset. True value is: %.2f\194\176 (Value in xml: %.2f\194\176)", i, angle, (math.deg(attacherJoint.upperRotationOffset))))
                    end
                end
                if attacherJoint.rotationNode ~= nil then
                    setRotation(attacherJoint.rotationNode, rx, ry, rz)
                end
                if attacherJoint.rotationNode2 ~= nil then
                    setRotation(attacherJoint.rotationNode2, rx2, ry2, rz2)
                end
            end
            setRotation(attacherJoint.jointTransform, trx, try, trz)
            if attacherJoint.transNode ~= nil then
                local rx, ry, rz = getTranslation(attacherJoint.transNode)
                local rx2, ry2, rz2 = localToLocal(attacherJoint.rootNode, getParent(attacherJoint.transNode), 0, attacherJoint.transNodeMinY, 0)
                setTranslation(attacherJoint.transNode, rx, ry2, rz)
                groundRaycastResult.groundDistance = 0
                groundRaycastResult.vehicle = self
                local x, y, z = getWorldTranslation(attacherJoint.transNode)
                raycastAll(x, y, z, 0, -1, 0, 4, "raycastCallback", groundRaycastResult, 4294967295)
                if math.abs(groundRaycastResult.groundDistance - attacherJoint.lowerDistanceToGround) > 0.02 then
                    print(string.format(" Issue found: Attacher joint %d has invalid lowerDistanceToGround. True value is: %.3f (Value in xml: %.3f)", i, MathUtil.round(groundRaycastResult.groundDistance, 3), attacherJoint.lowerDistanceToGround))
                end
                local _, dy, _ = localToLocal(attacherJoint.rootNode, getParent(attacherJoint.transNode), 0, attacherJoint.transNodeMaxY, 0)
                setTranslation(attacherJoint.transNode, rx, dy, rz)
                groundRaycastResult.groundDistance = 0
                local _, dy, _ = getWorldTranslation(attacherJoint.transNode)
                raycastAll(_, dy, _, 0, -1, 0, 4, "raycastCallback", groundRaycastResult, 4294967295)
                if math.abs(groundRaycastResult.groundDistance - attacherJoint.upperDistanceToGround) > 0.02 then
                    print(string.format(" Issue found: Attacher joint %d has invalid upperDistanceToGround. True value is: %.3f (Value in xml: %.3f)", i, MathUtil.round(groundRaycastResult.groundDistance, 3), attacherJoint.upperDistanceToGround))
                end
                setTranslation(attacherJoint.transNode, rx, ry, rz)
            end
        end
    end
    if self.spec_wheels ~= nil then
        for i, attacherJoint in ipairs(self.spec_wheels.wheels) do
            if attacherJoint.physics.wheelShapeCreated then
                local trx, try, trz = getCenterOfMass(attacherJoint.node)
                local rx = attacherJoint.physics.positionY + attacherJoint.physics.deltaY - attacherJoint.physics.radius * attacherJoint.physics.forcePointRatio
                if try < rx then
                    print(string.format(" Issue found: Wheel %d has force point higher than center of mass. %.2f > %.2f. This can lead to undesired driving behavior (inward-leaning).", i, rx, try))
                end
                local ry = getWheelShapeContactForce(attacherJoint.node, attacherJoint.physics.wheelShape)
                if ry ~= nil then
                    local rz, rx2, ry2 = getWheelShapeContactNormal(attacherJoint.node, attacherJoint.physics.wheelShape)
                    local rz2, x, y = localDirectionToWorld(attacherJoint.node, 0, -1, 0)
                    local ry = -ry * MathUtil.dotProduct(rz2, x, y, rz, rx2, ry2)
                    local ry = (ry + math.max(rx2 * 9.81, 0) * attacherJoint:getMass()) / 9.81
                    if math.abs(ry - attacherJoint.physics.restLoad) > 0.2 then
                        print(string.format(" Issue found: Wheel %d has wrong restLoad. %.2f vs. %.2f in XML. Verify that this leads to the desired behavior.", i, ry, attacherJoint.physics.restLoad))
                    end
                end
            end
        end
    end
    return "Analyzed vehicle"
end
function VehicleDebug.moveUpperRotation(_, _, inputValue, _, _)
    if VehicleDebug.currentAttacherJointVehicle ~= nil and inputValue ~= 0 then
        local vehicle = VehicleDebug.currentAttacherJointVehicle
        if vehicle.getAttacherVehicle ~= nil then
            local attacherVehicle = vehicle:getAttacherVehicle()
            if attacherVehicle ~= nil then
                local implement = attacherVehicle:getImplementByObject(vehicle)
                if implement ~= nil then
                    local jointDesc = attacherVehicle.spec_attacherJoints.attacherJoints[implement.jointDescIndex]
                    if jointDesc.rotationNode ~= nil then
                        jointDesc.upperRotation[1] = jointDesc.upperRotation[1] + math.rad(inputValue * 0.002 * 16)
                        jointDesc.moveAlpha = jointDesc.moveAlpha - 0.001
                        print("upperRotation: " .. math.deg(jointDesc.upperRotation[1]))
                    end
                end
            end
        end
    end
end
function VehicleDebug.moveLowerRotation(_, _, inputValue, _, _)
    if VehicleDebug.currentAttacherJointVehicle ~= nil and inputValue ~= 0 then
        local vehicle = VehicleDebug.currentAttacherJointVehicle
        if vehicle.getAttacherVehicle ~= nil then
            local attacherVehicle = vehicle:getAttacherVehicle()
            if attacherVehicle ~= nil then
                local implement = attacherVehicle:getImplementByObject(vehicle)
                if implement ~= nil then
                    local jointDesc = attacherVehicle.spec_attacherJoints.attacherJoints[implement.jointDescIndex]
                    if jointDesc.rotationNode ~= nil then
                        jointDesc.lowerRotation[1] = jointDesc.lowerRotation[1] + math.rad(inputValue * 0.002 * 16)
                        jointDesc.moveAlpha = jointDesc.moveAlpha - 0.001
                        print("lowerRotation: " .. math.deg(jointDesc.lowerRotation[1]))
                    end
                end
            end
        end
    end
end
function VehicleDebug.consoleCommandExportScenegraph(_, animationName, animationTime, additionalName)
    local function exportVehicleScenegraph(vehicle)
        -- upvalues: (copy) additionalName
        local startTime = getTimeSec()
        local filename = string.format(getUserProfileAppPath() .. "scenegraph_%s%s.xml", vehicle.configFileNameClean, (tostring(additionalName or "")))
        local xmlFile = XMLFile.create("scenegraph", filename, "scenegraph", nil)
        local function exportScenegraph(node, indexPath, key, index, component)
            -- upvalues: (copy) xmlFile, (copy) vehicle, (copy) exportScenegraph
            key = key .. string.format("(%d)", index)
            xmlFile:setString(key .. "#name", getName(node))
            xmlFile:setString(key .. "#indexPath", indexPath)
            local x, y, z = getTranslation(node)
            xmlFile:setString(key .. "#translation", x .. " " .. y .. " " .. z)
            local rx, ry, rz = getRotation(node)
            xmlFile:setString(key .. "#rotation", math.deg(rx) .. " " .. math.deg(ry) .. " " .. math.deg(rz))
            if component ~= nil then
                xmlFile:setFloat(key .. "#mass", vehicle:getComponentMass(component))
            end
            local numChildren = getNumOfChildren(node)
            if numChildren > 0 then
                local indexNode = 0
                local indexShape = 0
                local indexLight = 0
                local indexTransform = 0
                local i = 1
                for i = i, numChildren do
                    local child = getChildAt(node, i - 1)
                    local childPath
                    if indexPath == nil then
                        childPath = "" .. i - 1
                    else
                        childPath = indexPath .. "|" .. i - 1
                    end
                    local keyIndex = i - 1
                    local keyName = ".Node"
                    local indexShape
                    if getHasClassId(child, ClassIds.SHAPE) then
                        keyName = ".Shape"
                    elseif getHasClassId(child, ClassIds.LIGHT_SOURCE) then
                        keyName = ".Light"
                    elseif getHasClassId(child, ClassIds.TRANSFORM_GROUP) then
                        keyName = ".TransformGroup"
                    end
                    exportScenegraph(child, childPath, key .. keyName, indexShape, nil)
                end
            end
        end
        for i, component in ipairs(vehicle.components) do
            exportScenegraph(component.node, tostring(i - 1) .. ">", "scenegraph.Shape", i - 1, component)
        end
        xmlFile:save()
        xmlFile:delete()
        local endTime = getTimeSec()
        Logging.info("Exported \'%s\' in %.1fms", filename, (endTime - startTime) * 1000)
    end
    if animationName == nil or animationTime == nil then
        if g_currentMission ~= nil and g_localPlayer ~= nil then
            local vehicle = g_localPlayer:getCurrentVehicle()
            if vehicle == nil then
                Logging.error("Please enter vehicle first!")
            else
                local i = 1
                for i = i, #vehicle.childVehicles do
                    exportVehicleScenegraph(vehicle.childVehicles[i])
                end
            end
        end
    else
        animationTime = tonumber(animationTime)
        if VehicleDebug.defaultUpdateAnimationFunc == nil then
            VehicleDebug.defaultUpdateAnimationFunc = AnimatedVehicle.updateAnimation
        end
        function AnimatedVehicle:updateAnimation(anim, dtToUse, stopAnim, fixedTimeUpdate, playSounds, ...)
            -- upvalues: (copy) animationName, (ref) animationTime, (copy) exportVehicleScenegraph
            VehicleDebug.defaultUpdateAnimationFunc(self, anim, dtToUse, stopAnim, fixedTimeUpdate, playSounds, ...)
            if anim.name == animationName and (anim.currentSpeed > 0 and animationTime < anim.currentTime or anim.currentSpeed < 0 and anim.currentTime < animationTime) then
                exportVehicleScenegraph(self)
                AnimatedVehicle.updateAnimation = VehicleDebug.defaultUpdateAnimationFunc
                VehicleDebug.defaultUpdateAnimationFunc = nil
            end
        end
    end
end
function VehicleDebug.drawDebugAttacherJoints(vehicle)
    VehicleDebug.currentAttacherJointVehicle = vehicle
end
function VehicleDebug.consoleCommandMergeGroupDebug()
    local function visualizeMergeGroupsRec(node)
        -- upvalues: (copy) visualizeMergeGroupsRec
        if getHasClassId(node, ClassIds.SHAPE) then
            local _, isSkinnedSingleWeight = getShapeIsSkinned(node)
            if isSkinnedSingleWeight then
                if getHasShaderParameter(node, "colorScale") then
                    local material = VehicleMaterial.new()
                    material:setTemplateName("plasticPainted")
                    material:setColor(0, math.random(), math.random())
                    material:apply(node)
                end
            elseif getHasShaderParameter(node, "colorScale") then
                local material = VehicleMaterial.new()
                material:setTemplateName("plasticPainted")
                material:setColor(1, 0, 0)
                material:apply(node)
            end
        end
        local i = 0
        local isSkinnedSingleWeight = getNumOfChildren(node) - 1
        local material = 1
        for i = i, isSkinnedSingleWeight, material do
            visualizeMergeGroupsRec(getChildAt(node, i))
        end
    end
    if g_gui.currentGuiName == "ShopConfigScreen" then
        for _, loadedVehicle in pairs(g_shopConfigScreen.previewVehicles) do
            for _, component in ipairs(loadedVehicle.components) do
                visualizeMergeGroupsRec(component.node)
            end
        end
    end
    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        for _ = 1, #vehicle.childVehicles do
            for _, _ in ipairs(vehicle.childVehicles[_].components) do
                visualizeMergeGroupsRec(_.node)
            end
        end
    end
end
function VehicleDebug.consoleCommandCastShadow()
    local function visualizeCastShadowRec(node)
        -- upvalues: (copy) visualizeCastShadowRec
        if getHasClassId(node, ClassIds.SHAPE) then
            local materialId = getMaterial(node, 0)
            if materialId ~= 0 and string.contains(getMaterialCustomShaderFilename(materialId), "vehicleShader.xml") then
                local material = VehicleMaterial.new()
                material:setTemplateName("plasticPainted")
                material:setColor(0, 0, 0)
                if getShapeCastShadowmap(node) then
                    material:setColor(1, 1, 1)
                end
                material.diffuseMap = "data/shared/white_diffuse.dds"
                material:apply(node)
            end
        end
        local i = 0
        local material = getNumOfChildren(node) - 1
        for i = i, material do
            visualizeCastShadowRec(getChildAt(node, i))
        end
    end
    if g_gui.currentGuiName == "ShopConfigScreen" then
        for _, loadedVehicle in pairs(g_shopConfigScreen.previewVehicles) do
            for _, component in ipairs(loadedVehicle.components) do
                visualizeCastShadowRec(component.node)
            end
        end
    end
    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        for _ = 1, #vehicle.childVehicles do
            for _, _ in ipairs(vehicle.childVehicles[_].components) do
                visualizeCastShadowRec(_.node)
            end
        end
    end
end
function VehicleDebug.consoleCommandDecalLayer()
    local function visualizeDecalLayer(node)
        -- upvalues: (copy) visualizeDecalLayer
        if getHasClassId(node, ClassIds.SHAPE) then
            local decalLayer = getShapeDecalLayer(node)
            local material = VehicleMaterial.new()
            material:setTemplateName("plasticPainted")
            material:setColor(1, 1, 1)
            if decalLayer == 1 then
                material:setColor(1, 0, 0)
            elseif decalLayer == 2 then
                material:setColor(0, 1, 0)
            elseif decalLayer > 2 then
                material:setColor(0, 0, 1)
            end
            material.diffuseMap = "data/shared/white_diffuse.dds"
            material:apply(node)
        end
        local i = 0
        local material = getNumOfChildren(node) - 1
        for i = i, material do
            visualizeDecalLayer(getChildAt(node, i))
        end
    end
    if g_gui.currentGuiName == "ShopConfigScreen" then
        for _, loadedVehicle in pairs(g_shopConfigScreen.previewVehicles) do
            for _, component in ipairs(loadedVehicle.components) do
                visualizeDecalLayer(component.node)
            end
        end
    end
    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        for _ = 1, #vehicle.childVehicles do
            for _, _ in ipairs(vehicle.childVehicles[_].components) do
                visualizeDecalLayer(_.node)
            end
        end
    end
end
function VehicleDebug.consoleCommandDebugMaterial(_, materialTemplateName)
    if g_vehicleMaterialManager:getMaterialTemplateByName(materialTemplateName) == nil then
        Logging.error("Material template \'%s\' not found", materialTemplateName)
    else
        local targetMaterial = VehicleMaterial.new()
        targetMaterial:setTemplateName(materialTemplateName)
        local function visualizeMaterialRec(node)
            -- upvalues: (copy) targetMaterial, (copy) visualizeMaterialRec
            if getHasClassId(node, ClassIds.SHAPE) then
                local numMaterial = getNumOfMaterials(node)
                local i = 1
                for i = i, numMaterial do
                    if targetMaterial:getIsApplied(node, getMaterial(node, i - 1), false) then
                        local material = VehicleMaterial.new()
                        material:setTemplateName("plasticPainted")
                        material:setColor(0, 1, 0)
                        material:applyToMaterial(node, i - 1)
                    else
                        local material = VehicleMaterial.new()
                        material:setTemplateName("plasticPainted")
                        material:setColor(1, 0, 0)
                        material:applyToMaterial(node, i - 1)
                    end
                end
            end
            local i = 0
            for i = i, getNumOfChildren(node) - 1 do
                visualizeMaterialRec(getChildAt(node, i))
            end
        end
        if g_gui.currentGuiName == "ShopConfigScreen" then
            for _, loadedVehicle in pairs(g_shopConfigScreen.previewVehicles) do
                for _, component in ipairs(loadedVehicle.components) do
                    visualizeMaterialRec(component.node)
                end
            end
        end
        if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
            local vehicle = g_localPlayer:getCurrentVehicle()
            for _ = 1, #vehicle.childVehicles do
                for _, _ in ipairs(vehicle.childVehicles[_].components) do
                    visualizeMaterialRec(_.node)
                end
            end
        end
    end
end
function VehicleDebug.consoleCommandAttacherJointConnections(_, attacherJointIndex)
    attacherJointIndex = tonumber(attacherJointIndex) or 1
    if VehicleDebug.DEBUG_ATTACHER_JOINT_INDEX == attacherJointIndex then
        Logging.info("Disconnect from attacher joint \'%s\'", attacherJointIndex)
        VehicleDebug.DEBUG_ATTACHER_JOINT_INDEX = nil
    else
        Logging.info("Connect to attacher joint \'%s\'", attacherJointIndex)
        VehicleDebug.DEBUG_ATTACHER_JOINT_INDEX = attacherJointIndex
    end
    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        local i = 1
        for i = i, #vehicle.childVehicles do
            local childVehicle = vehicle.childVehicles[i]
            if childVehicle.getAttacherJoints ~= nil then
                local str = ""
                for index, attacherJointDesc in ipairs(childVehicle:getAttacherJoints()) do
                    str = str .. string.format("%d-%s  ", index, getName(attacherJointDesc.jointTransform))
                    ObjectChangeUtil.setObjectChanges(attacherJointDesc.changeObjects, false, childVehicle, childVehicle.setMovingToolDirty)
                end
                if str ~= "" then
                    Logging.info(childVehicle:getFullName() .. ": " .. str)
                end
            end
            if childVehicle.jointIndexDebugText ~= nil then
                g_debugManager:removeElement(childVehicle.jointIndexDebugText)
                childVehicle.jointIndexDebugText = nil
            end
            if childVehicle.steeringBarLeftDebugText ~= nil then
                g_debugManager:removeElement(childVehicle.steeringBarLeftDebugText)
                childVehicle.steeringBarLeftDebugText = nil
            end
            if childVehicle.steeringBarRightDebugText ~= nil then
                g_debugManager:removeElement(childVehicle.steeringBarRightDebugText)
                childVehicle.steeringBarRightDebugText = nil
            end
            local str = childVehicle:getAttacherJointByJointDescIndex(attacherJointIndex)
            if str ~= nil then
                childVehicle.jointIndexDebugText = DebugGizmo.new():createWithNode(str.jointTransform, "j" .. tostring(attacherJointIndex), nil, nil, 0.1, true)
                g_debugManager:addElement(childVehicle.jointIndexDebugText, nil, nil, math.huge)
                if str.steeringBarLeftNode ~= nil then
                    childVehicle.steeringBarLeftDebugText = DebugGizmo.new():createWithNode(str.steeringBarLeftNode, "sl", nil, nil, 0.1, true)
                    g_debugManager:addElement(childVehicle.steeringBarLeftDebugText, nil, nil, math.huge)
                end
                if str.steeringBarRightNode ~= nil then
                    childVehicle.steeringBarRightDebugText = DebugGizmo.new():createWithNode(str.steeringBarRightNode, "sr", nil, nil, 0.1, true)
                    g_debugManager:addElement(childVehicle.steeringBarRightDebugText, nil, nil, math.huge)
                end
                ObjectChangeUtil.setObjectChanges(str.changeObjects, true, childVehicle, childVehicle.setMovingToolDirty)
                local j = 1
                for j = j, #str.visualNodes do
                    setVisibility(str.visualNodes[j], true)
                end
                local j = 1
                for j = j, #str.hideVisuals do
                    setVisibility(str.hideVisuals[j], false)
                end
            end
            ConnectionHoses.consoleCommandTestSockets(childVehicle, attacherJointIndex)
            PowerTakeOffs.consoleCommandTestConnection(childVehicle, attacherJointIndex)
        end
    end
end
function VehicleDebug.consoleCommandToolConnections(_, toolConnectionIndex)
    toolConnectionIndex = tonumber(toolConnectionIndex) or 1
    if VehicleDebug.DEBUG_TOOL_CONNECTION_INDEX == toolConnectionIndex then
        Logging.info("Disconnect from tool connection \'%s\'", toolConnectionIndex)
        VehicleDebug.DEBUG_TOOL_CONNECTION_INDEX = nil
    else
        Logging.info("Connect to tool connection \'%s\'", toolConnectionIndex)
        VehicleDebug.DEBUG_TOOL_CONNECTION_INDEX = toolConnectionIndex
    end
    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        local i = 1
        for i = i, #vehicle.childVehicles do
            ConnectionHoses.consoleCommandTestToolConnection(vehicle.childVehicles[i], VehicleDebug.DEBUG_TOOL_CONNECTION_INDEX)
        end
    end
end
function VehicleDebug.consoleCommandWheelDisplacement()
    if WheelPhysics.COLLISION_MASK == CollisionMask.ALL then
        WheelPhysics.COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN_DISPLACEMENT
        Logging.info("Disabled wheel interaction with displacement collision")
    else
        WheelPhysics.COLLISION_MASK = CollisionMask.ALL
        Logging.info("Enabled wheel interaction with displacement collision")
    end
    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.getWheels ~= nil then
            for i, wheel in ipairs(vehicle:getWheels()) do
                wheel.physics:updateBase()
            end
        end
    end
end
VehicleDebug.cylinderedUpdateDebugState = false
function VehicleDebug.consoleCommandCylinderedUpdate()
    VehicleDebug.cylinderedUpdateDebugState = not VehicleDebug.cylinderedUpdateDebugState
    print("Cylindered Update Debug: " .. tostring(VehicleDebug.cylinderedUpdateDebugState))
end
VehicleDebug.wetnessDebugState = false
function VehicleDebug.consoleCommandWetnessDebug()
    VehicleDebug.wetnessDebugState = not VehicleDebug.wetnessDebugState
    local visualizeWetness = print
    local _ = VehicleDebug.wetnessDebugState
    visualizeWetness("Wetness Debug: " .. tostring(_))
    local function visualizeWetness(vehicle)
        local debugMaterial = g_debugManager:getDebugMat()
        local debugMaterial = setMaterialCustomShaderVariation(debugMaterial, "wetnessDebug", false)
        local debugMaterial = setMaterialDiffuseMapFromFile(debugMaterial, "data/shared/default_diffuse.dds", true, true, false)
        local function visualizeWetnessRec(vehicle, node)
            -- upvalues: (ref) debugMaterial, (copy) visualizeWetnessRec
            if vehicle.spec_washable == nil or vehicle.spec_washable.wetnessIgnoreNodes[node] ~= true then
                if getHasClassId(node, ClassIds.SHAPE) then
                    local i = 1
                    local material = getNumOfMaterials(node)
                    for i = i, material do
                        local material = getMaterial(node, i - 1)
                        local shaderFilename = getMaterialCustomShaderFilename(material)
                        if string.contains(shaderFilename, "vehicleShader.xml") then
                            setMaterial(node, debugMaterial, i - 1)
                            setShaderParameter(node, "alpha", 1, 0, 0, 0, false, i - 1)
                        end
                    end
                end
                local material = 0
                local i = 1
                for material = material, getNumOfChildren(node) - 1, i do
                    visualizeWetnessRec(vehicle, getChildAt(node, material))
                end
            end
        end
        for _, component in ipairs(vehicle.components) do
            visualizeWetnessRec(vehicle, component.node)
        end
    end
    if VehicleDebug.wetnessDebugState then
        if g_gui.currentGuiName == "ShopConfigScreen" then
            for _, loadedVehicle in pairs(g_shopConfigScreen.previewVehicles) do
                visualizeWetness(loadedVehicle)
            end
        elseif g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
            local vehicle = g_localPlayer:getCurrentVehicle()
            for _ = 1, #vehicle.childVehicles do
                visualizeWetness(vehicle.childVehicles[_])
            end
        end
        VehicleDebug.vehicleOnFinishedLoading = Vehicle.onFinishedLoading
        function Vehicle:onFinishedLoading(...)
            -- upvalues: (copy) visualizeWetness
            visualizeWetness(self)
            VehicleDebug.vehicleOnFinishedLoading(self, ...)
        end
    else
        if VehicleDebug.vehicleOnFinishedLoading ~= nil then
            Vehicle.onFinishedLoading = VehicleDebug.vehicleOnFinishedLoading
            VehicleDebug.vehicleOnFinishedLoading = nil
        end
        executeConsoleCommand("gsVehicleReload")
    end
end
VehicleDebug.wheelEffectDebugState = false
function VehicleDebug.consoleCommandWheelEffectsDebug()
    VehicleDebug.wheelEffectDebugState = not VehicleDebug.wheelEffectDebugState
    print("Wheel Effects Debug: " .. (VehicleDebug.wheelEffectDebugState and "Enabled" or "Disabled"))
end
function VehicleDebug.consoleCommandAutomaticMotorStart()
    local mission = g_currentMission
    if mission.missionInfo.automaticMotorStartEnabled then
        mission:setAutomaticMotorStartEnabled(false, true)
        print("Automatic Motor Start: Disabled")
        if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
            local vehicle = g_localPlayer:getCurrentVehicle()
            for _, v in ipairs(vehicle.childVehicles) do
                if v.setMotorState ~= nil then
                    v:setMotorState(MotorState.OFF)
                end
            end
            return
        end
    else
        mission:setAutomaticMotorStartEnabled(true, true)
        print("Automatic Motor Start: Enabled")
    end
end
function VehicleDebug.consoleCommandCameraReset()
    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local vehicle = g_localPlayer:getCurrentVehicle()
        for _, v in ipairs(vehicle.childVehicles) do
            if v.getActiveCamera ~= nil then
                local camera = v:getActiveCamera()
                if camera ~= nil then
                    camera:resetCamera()
                end
            end
        end
    end
end
addConsoleCommand("gsVehicleAnalyze", "Analyze vehicle", "VehicleDebug.consoleCommandAnalyze", nil)
addConsoleCommand("gsVehicleDebug", "Toggles the vehicle debug values rendering", "VehicleDebug.consoleCommandVehicleDebug", nil)
addConsoleCommand("gsVehicleExportScenegraph", "Exports the vehicle scenegraph to a xml file", "VehicleDebug.consoleCommandExportScenegraph", nil)
addConsoleCommand("gsVehicleDebugMergeGroups", "Visualizes all merge groups", "VehicleDebug.consoleCommandMergeGroupDebug", nil)
addConsoleCommand("gsVehicleDebugCastShadow", "Visualizes all shapes that cast shadows", "VehicleDebug.consoleCommandCastShadow", nil)
addConsoleCommand("gsVehicleDebugDecalLayer", "Visualizes all shapes with decal layer", "VehicleDebug.consoleCommandDecalLayer", nil)
addConsoleCommand("gsVehicleDebugMaterial", "Visualizes all shapes that got the given material template assigned", "VehicleDebug.consoleCommandDebugMaterial", nil, "materialTemplateName")
addConsoleCommand("gsVehicleDebugAttacherJointConnections", "Visualization of the connection hoses and power take offs per attacher joint", "VehicleDebug.consoleCommandAttacherJointConnections", nil, "jointIndex")
addConsoleCommand("gsVehicleDebugToolConnections", "Visualization of the tool connection hoses", "VehicleDebug.consoleCommandToolConnections", nil, "toolConnectionIndex")
addConsoleCommand("gsVehicleDebugToggleWheelDisplacement", "Toggles the interaction of the wheels with the displacement", "VehicleDebug.consoleCommandWheelDisplacement", nil)
addConsoleCommand("gsVehicleDebugCylinderedUpdateDebug", "Shows the name of each movingPart or movingTool that is updated", "VehicleDebug.consoleCommandCylinderedUpdate", nil)
addConsoleCommand("gsVehicleDebugWetness", "Visualizes the wetness masking of the vehicle", "VehicleDebug.consoleCommandWetnessDebug", nil)
addConsoleCommand("gsVehicleDebugWheelEffects", "Enabled the wheel effects all the time", "VehicleDebug.consoleCommandWheelEffectsDebug", nil)
addConsoleCommand("gsVehicleDebugMotorStart", "Enabled or disable automatic motor start setting via console command", "VehicleDebug.consoleCommandAutomaticMotorStart", nil)
addConsoleCommand("gsVehicleDebugCameraReset", "Resets the vehicle camera to default state", "VehicleDebug.consoleCommandCameraReset", nil)
if StartParams.getIsSet("vehicleDebugMode") then
    VehicleDebug.consoleCommandVehicleDebug(nil, StartParams.getValue("vehicleDebugMode"))
end