AIDriveStrategyCombine = {}
local AIDriveStrategyCombine_mt = Class(AIDriveStrategyCombine, AIDriveStrategy)
function AIDriveStrategyCombine.new(reconstructionData, customMt)
    -- upvalues: (copy) AIDriveStrategyCombine_mt
    local self = AIDriveStrategy.new(reconstructionData, customMt or AIDriveStrategyCombine_mt)
    self.combines = {}
    self.notificationFullGrainTankShown = false
    self.notificationGrainTankWarningShown = false
    self.beaconLightsActive = false
    self.slowDownFillLevel = 200
    self.slowDownStartSpeed = 20
    self.forageHarvesterFoundTimer = 0
    self.waitForStrawModeActive = false
    self.waitForStrawModeStartPosition = { 0, 0 }
    self.waitForStrawModeLastPosition = { 0, 0 }
    self.waitForStrawModeReturnToStart = false
    self.waitForStrawModeReturnToStartDistance = 0
    return self
end
function AIDriveStrategyCombine:setAIVehicle(vehicle)
    AIDriveStrategyCombine:superClass().setAIVehicle(self, vehicle)
    for _, childVehicle in pairs(self.vehicle.rootVehicle.childVehicles) do
        if SpecializationUtil.hasSpecialization(Combine, childVehicle.specializations) then
            table.insert(self.combines, childVehicle)
        end
    end
end
function AIDriveStrategyCombine:update(_)
    for _, combine in pairs(self.combines) do
        if combine.spec_pipe ~= nil then
            local capacity = 0
            local dischargeNode = combine:getCurrentDischargeNode()
            if dischargeNode ~= nil then
                capacity = combine:getFillUnitCapacity(dischargeNode.fillUnitIndex)
            end
            if capacity == math.huge then
                local rootVehicle = self.vehicle.rootVehicle
                if rootVehicle.getAIFieldWorkerIsTurning ~= nil and not rootVehicle:getAIFieldWorkerIsTurning() then
                    local trailer = NetworkUtil.getObject(combine.spec_pipe.nearestObjectInTriggers.objectId)
                    if trailer ~= nil then
                        if combine:getDischargeFillType(dischargeNode) == FillType.UNKNOWN then
                            local fillType = trailer:getFillUnitFillType(combine.spec_pipe.nearestObjectInTriggers.fillUnitIndex)
                            if fillType == FillType.UNKNOWN then
                                fillType = trailer:getFillUnitFirstSupportedFillType(trailerFillUnitIndex)
                            end
                            combine:setForcedFillTypeIndex(fillType)
                        else
                            combine:setForcedFillTypeIndex(nil)
                        end
                    end
                end
            end
        end
    end
end
function AIDriveStrategyCombine:getDriveData(_, vX, _, vZ)
    local rootVehicle = self.vehicle.rootVehicle
    local isTurning = false
    if rootVehicle.getAIFieldWorkerIsTurning ~= nil then
        isTurning = rootVehicle:getAIFieldWorkerIsTurning()
    end
    local isCornerCutOutActive = false
    if rootVehicle.getAIFieldWorkerIsCornerCutOutActive ~= nil then
        isCornerCutOutActive = rootVehicle:getAIFieldWorkerIsCornerCutOutActive()
    end
    local allowedToDrive = true
    local waitForStraw = false
    local maxSpeed = math.huge
    for _, combine in pairs(self.combines) do
        if combine.spec_pipe == nil then
            if combine:getFillUnitFillLevel(combine.spec_combine.fillUnitIndex) < 0.1 and (not combine:getIsTurnedOn() and combine:getCanBeTurnedOn()) then
                combine:aiImplementStartLine()
                for dischargeNode, trailer in ipairs(self.vehicle:getAttachedAIImplements()) do
                    trailer.object:aiImplementStartLine()
                end
            end
        else
            local trailerInTrigger = false
            local invalidTrailerInTrigger = false
            local fillLevel = 0
            local capacity = 0
            local dischargeNode = combine:getCurrentDischargeNode()
            if dischargeNode ~= nil then
                fillLevel = combine:getFillUnitFillLevel(dischargeNode.fillUnitIndex)
                capacity = combine:getFillUnitCapacity(dischargeNode.fillUnitIndex)
            end
            local trailerInTrigger = NetworkUtil.getObject(combine.spec_pipe.nearestObjectInTriggers.objectId) ~= nil and true or trailerInTrigger
            local invalidTrailerInTrigger = combine.spec_pipe.nearestObjectInTriggerIgnoreFillLevel and true or invalidTrailerInTrigger
            local turnOnAllowedStates = combine.spec_pipe.turnOnAllowedStates
            if next(turnOnAllowedStates) == nil then
                turnOnAllowedStates = nil
            end
            if capacity == math.huge then
                if combine.spec_pipe.targetState ~= 2 then
                    combine:setPipeState(2)
                end
                if not (isTurning or isCornerCutOutActive) then
                    local targetObject, _ = combine:getDischargeTargetObject(dischargeNode)
                    allowedToDrive = trailerInTrigger and targetObject ~= nil
                    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                        if trailerInTrigger then
                            if trailerInTrigger and targetObject == nil then
                                self.vehicle:addAIDebugText("COMBINE -> Waiting for pipe hitting the trailer")
                            end
                        else
                            self.vehicle:addAIDebugText("COMBINE -> Waiting for trailer enter the trigger")
                        end
                    end
                end
            else
                if 0.8 * capacity < fillLevel then
                    if not self.beaconLightsActive then
                        self.vehicle:setAIMapHotspotBlinking(true)
                        self.vehicle:setBeaconLightsVisibility(true)
                        self.beaconLightsActive = true
                    end
                    if not self.notificationGrainTankWarningShown and self.vehicle:getOwnerFarmId() == g_localPlayer.farmId then
                        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("ai_messageErrorTankIsNearlyFull"), self.vehicle:getCurrentHelper().name))
                        self.notificationGrainTankWarningShown = true
                    end
                else
                    if self.beaconLightsActive then
                        self.vehicle:setAIMapHotspotBlinking(false)
                        self.vehicle:setBeaconLightsVisibility(false)
                        self.beaconLightsActive = false
                    end
                    self.notificationGrainTankWarningShown = false
                end
                local targetObject
                if fillLevel == capacity then
                    targetObject = 2
                    self.wasCompletelyFull = true
                    if not self.notificationFullGrainTankShown and self.vehicle:getOwnerFarmId() == g_localPlayer.farmId then
                        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("ai_messageErrorTankIsFull"), self.vehicle:getCurrentHelper().name))
                        self.notificationFullGrainTankShown = true
                    end
                else
                    self.notificationFullGrainTankShown = false
                    targetObject = currentPipeTargetState
                end
                if trailerInTrigger then
                end
                if not trailerInTrigger and fillLevel < capacity * 0.8 then
                    self.wasCompletelyFull = false
                    if not combine:getIsTurnedOn() and combine:getCanBeTurnedOn() then
                        combine:aiImplementStartLine()
                        for i, implement in ipairs(self.vehicle:getAttachedAIImplements()) do
                            implement.object:aiImplementStartLine()
                        end
                    end
                end
                local targetObject = not trailerInTrigger and (not invalidTrailerInTrigger and fillLevel < capacity) and 1 or targetObject
                if fillLevel < 0.1 then
                    if not combine.spec_pipe.aiFoldedPipeUsesTrailerSpace then
                        if not combine:getIsTurnedOn() and combine:getCanBeTurnedOn() then
                            combine:aiImplementStartLine()
                            for i, implement in ipairs(self.vehicle:getAttachedAIImplements()) do
                                implement.object:aiImplementStartLine()
                            end
                        end
                    end
                    self.wasCompletelyFull = false
                end
                if currentPipeTargetState ~= targetObject then
                    combine:setPipeState(targetObject)
                end
                allowedToDrive = fillLevel < capacity
                if turnOnAllowedStates ~= nil and turnOnAllowedStates[combine.spec_pipe.currentState] ~= true then
                    allowedToDrive = false
                    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                        self.vehicle:addAIDebugText("COMBINE -> Stopping AI because we cannot overload while harvesting")
                    end
                end
                if targetObject == 2 and self.wasCompletelyFull then
                    allowedToDrive = false
                    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                        self.vehicle:addAIDebugText("COMBINE -> Waiting for trailer to unload")
                    end
                end
                local _ = capacity - fillLevel
                if _ < self.slowDownFillLevel then
                    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                        self.vehicle:addAIDebugText(string.format("COMBINE -> Slow down because nearly full: %.2f", 2 + _ / self.slowDownFillLevel * self.slowDownStartSpeed))
                    end
                end
            end
            if isTurning and (trailerInTrigger and (capacity ~= math.huge and combine:getCanDischargeToObject(dischargeNode))) then
                local targetObject = combine.spec_combine
                if targetObject.loadingDelay > 0 then
                    local i = 1
                    for i = i, #targetObject.loadingDelaySlots do
                        local i = targetObject.loadingDelaySlots[i]
                        if i.valid then
                        end
                    end
                end
                if fillLevel > 0 then
                    allowedToDrive = false
                end
                if VehicleDebug.state == VehicleDebug.DEBUG_AI and not allowedToDrive then
                    self.vehicle:addAIDebugText("COMBINE -> Unload to trailer on headland")
                end
            end
            if not trailerInTrigger and (combine.spec_combine.isSwathActive and combine.spec_combine.strawPSenabled) then
                waitForStraw = true
            end
        end
    end
    if isTurning and waitForStraw then
        if not self.waitForStrawModeActive then
            self.waitForStrawModeActive = true
            self.waitForStrawModeStartPosition[1] = vX
            self.waitForStrawModeStartPosition[2] = vZ
        end
        if VehicleDebug.state == VehicleDebug.DEBUG_AI then
            self.vehicle:addAIDebugText("COMBINE -> Waiting for straw to drop")
        end
        local x, _, z = localToWorld(self.vehicle:getAIDirectionNode(), 0, 0, -10)
        return x, z, false, 6, MathUtil.vector2Length(vX - x, vZ - z)
    else
        if self.waitForStrawModeActive then
            self.waitForStrawModeActive = false
            self.waitForStrawModeReturnToStart = true
            self.waitForStrawModeLastPosition[1] = vX
            self.waitForStrawModeLastPosition[2] = vZ
            self.waitForStrawModeReturnToStartDistance = MathUtil.vector2Length(vX - self.waitForStrawModeStartPosition[1], vZ - self.waitForStrawModeStartPosition[2])
        end
        if self.waitForStrawModeReturnToStart then
            local x = MathUtil.vector2Length(vX - self.waitForStrawModeLastPosition[1], vZ - self.waitForStrawModeLastPosition[2])
            local _ = self.waitForStrawModeLastPosition
            local z = self.waitForStrawModeLastPosition
            _[1] = vX
            z[2] = vZ
            self.waitForStrawModeReturnToStartDistance = self.waitForStrawModeReturnToStartDistance - x
            if self.waitForStrawModeReturnToStartDistance >= 0 then
                if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                    self.vehicle:addAIDebugText(string.format("COMBINE -> Returning to turn start position (%.1fm)", self.waitForStrawModeReturnToStartDistance))
                end
                local _ = self.waitForStrawModeStartPosition[1]
                local z = self.waitForStrawModeStartPosition[2]
                return _, z, true, 10, MathUtil.vector2Length(vX - _, vZ - z)
            end
            self.waitForStrawModeReturnToStart = false
        end
        if allowedToDrive then
            return nil, nil, nil, maxSpeed, nil
        else
            return 0, 1, true, 0, math.huge
        end
    end
end
function AIDriveStrategyCombine:updateDriving(dt) end