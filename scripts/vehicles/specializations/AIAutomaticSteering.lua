AIAutomaticSteering = {}
AIAutomaticSteering.LINE_END_SOUND_DISTANCE = 10
AIAutomaticSteering.CRUISE_CONTROL_DISABLE_DISTANCE = 1
AIAutomaticSteering.RESET_COURSE_TIME = 20000
AIAutomaticSteering.HEADING_LETTERS = {}
AIAutomaticSteering.HEADING_LETTERS[1] = "N"
AIAutomaticSteering.HEADING_LETTERS[2] = "NE"
AIAutomaticSteering.HEADING_LETTERS[3] = "E"
AIAutomaticSteering.HEADING_LETTERS[4] = "SE"
AIAutomaticSteering.HEADING_LETTERS[5] = "S"
AIAutomaticSteering.HEADING_LETTERS[6] = "SW"
AIAutomaticSteering.HEADING_LETTERS[7] = "W"
AIAutomaticSteering.HEADING_LETTERS[8] = "NW"
AIAutomaticSteering.STATE = {}
AIAutomaticSteering.STATE.DISABLED = 1
AIAutomaticSteering.STATE.AVAILABLE = 2
AIAutomaticSteering.STATE.ACTIVE = 3
Enum(AIAutomaticSteering.STATE)
source("dataS/scripts/vehicles/specializations/events/AIAutomaticSteeringCourseEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIAutomaticSteeringLineEndEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIAutomaticSteeringRequestEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIAutomaticSteeringStateEvent.lua")
function AIAutomaticSteering.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations)
end
function AIAutomaticSteering.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AIAutomaticSteering")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.ai.automaticSteering.sounds", "engage")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.ai.automaticSteering.sounds", "disengage")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.ai.automaticSteering.sounds", "lineEnd")
    Dashboard.registerDashboardXMLPaths(schema, "vehicle.ai.automaticSteering.dashboards", {
        "steeringEngaged",
        "steeringState",
        "heading",
        "headingLetter"
    })
    schema:register(XMLValueType.FLOAT, "vehicle.ai.automaticSteering#lookAheadDistance", "Distance for aiming onto the wayline", "half of the vehicle length")
    schema:setXMLSpecializationType()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    SteeringFieldCourse.registerXMLPaths(schemaSavegame, "vehicles.vehicle(?).aiAutomaticSteering.steeringFieldCourse")
    SteeringFieldCourse.registerXMLPaths(schemaSavegame, "vehicles.vehicle(?).aiAutomaticSteering.lastActiveSteeringFieldCourse")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiAutomaticSteering#isOnField", "Is on field")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiAutomaticSteering#courseWasActive", "Current course was also the last active one")
end
function AIAutomaticSteering.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onAIAutomaticSteeringLineEnd")
end
function AIAutomaticSteering.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherToolWorkingWidth", AIAutomaticSteering.getAttacherToolWorkingWidth)
    SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticSteeringAllowed", AIAutomaticSteering.getIsAutomaticSteeringAllowed)
    SpecializationUtil.registerFunction(vehicleType, "setAIAutomaticSteeringEnabled", AIAutomaticSteering.setAIAutomaticSteeringEnabled)
    SpecializationUtil.registerFunction(vehicleType, "setAIAutomaticSteeringCourse", AIAutomaticSteering.setAIAutomaticSteeringCourse)
    SpecializationUtil.registerFunction(vehicleType, "generateSteeringFieldCourse", AIAutomaticSteering.generateSteeringFieldCourse)
    SpecializationUtil.registerFunction(vehicleType, "getIsAIAutomaticSteeringAllowed", AIAutomaticSteering.getIsAIAutomaticSteeringAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getAIAutomaticSteeringState", AIAutomaticSteering.getAIAutomaticSteeringState)
    SpecializationUtil.registerFunction(vehicleType, "getAIAutomaticSteeringLookAheadDistance", AIAutomaticSteering.getAIAutomaticSteeringLookAheadDistance)
    SpecializationUtil.registerFunction(vehicleType, "getIsSideOffsetReversed", AIAutomaticSteering.getIsSideOffsetReversed)
end
function AIAutomaticSteering.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSteeringInput", AIAutomaticSteering.setSteeringInput)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateVehiclePhysics", AIAutomaticSteering.updateVehiclePhysics)
end
function AIAutomaticSteering.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onAIModeChanged", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onAIModeSettingsChanged", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onAIAutomaticSteeringLineEnd", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onActivate", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AIAutomaticSteering)
end
function AIAutomaticSteering:onLoad(_)
    local spec = self.spec_aiAutomaticSteering
    spec.lastIsOnField = false
    spec.forceFieldCourseUpdate = false
    spec.resetCourseTimer = 0
    spec.steeringFieldCourse = nil
    spec.lastActiveSteeringFieldCourse = nil
    spec.fieldCourseDetectionInProgress = false
    spec.fieldCourseDetectionPendingData = nil
    spec.lastDistanceToEnd = 0
    spec.steeringEnabled = false
    spec.steeringLastEnableTime = -math.huge
    spec.steeringLockedMovingDirection = 0
    spec.steeringValue = 0
    spec.lookAheadDistance = self.xmlFile:getValue("vehicle.ai.automaticSteering#lookAheadDistance")
    spec.lastSteeringInputValue = 0
    if self.isClient then
        spec.samples = {}
        spec.samples.engage = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ai.automaticSteering.sounds", "engage", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.disengage = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ai.automaticSteering.sounds", "disengage", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.lineEnd = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ai.automaticSteering.sounds", "lineEnd", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    self:registerVehicleSetting(GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL, true)
    spec.dirtyFlag = self:getNextDirtyFlag()
end
function AIAutomaticSteering:onPostLoad(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local spec = self.spec_aiAutomaticSteering
        local courseWasActive = savegame.xmlFile:getValue(savegame.key .. ".aiAutomaticSteering#courseWasActive", false)
        spec.lastIsOnField = savegame.xmlFile:getValue(savegame.key .. ".aiAutomaticSteering#isOnField", spec.lastIsOnField)
        SteeringFieldCourse.loadFromXML(savegame.xmlFile, savegame.key .. ".aiAutomaticSteering.lastActiveSteeringFieldCourse", function(steeringFieldCourse)
            -- upvalues: (copy) spec
            if steeringFieldCourse ~= nil then
                spec.lastActiveSteeringFieldCourse = steeringFieldCourse
            end
        end)
        SteeringFieldCourse.loadFromXML(savegame.xmlFile, savegame.key .. ".aiAutomaticSteering.steeringFieldCourse", function(steeringFieldCourse)
            -- upvalues: (copy) self, (copy) spec, (copy) courseWasActive
            if steeringFieldCourse ~= nil then
                self:setAIAutomaticSteeringCourse(steeringFieldCourse, true)
                spec.forceFieldCourseUpdate = false
                if courseWasActive then
                    spec.lastActiveSteeringFieldCourse = steeringFieldCourse
                end
            end
        end)
    end
end
function AIAutomaticSteering:onRegisterDashboardValueTypes()
    local spec = self.spec_aiAutomaticSteering
    local steeringEngaged = DashboardValueType.new("ai.automaticSteering", "steeringEngaged")
    steeringEngaged:setValue(spec, "steeringEnabled")
    steeringEngaged:setPollUpdate(false)
    self:registerDashboardValueType(steeringEngaged)
    local steeringState = DashboardValueType.new("ai.automaticSteering", "steeringState")
    steeringState:setValue(spec, function()
        -- upvalues: (copy) self
        return self:getAIAutomaticSteeringState() - 1
    end)
    steeringState:setPollUpdate(false)
    self:registerDashboardValueType(steeringState)
    local heading = DashboardValueType.new("ai.automaticSteering", "heading")
    heading:setValue(spec, function()
        -- upvalues: (copy) self
        local dx, _, dz = localDirectionToWorld(self.rootNode, 0, 0, 1)
        local yRot = MathUtil.getYRotationFromDirection(dx, dz)
        if yRot < 0 then
        end
        return 360 - math.deg(yRot)
    end)
    self:registerDashboardValueType(heading)
    local headingLetter = DashboardValueType.new("ai.automaticSteering", "headingLetter")
    headingLetter:setValue(spec, function()
        -- upvalues: (copy) self
        local dx, _, dz = localDirectionToWorld(self.rootNode, 0, 0, -1)
        local yRot = MathUtil.getYRotationFromDirection(dx, dz)
        if yRot < 0 then
        end
        local yRot = 360 - math.deg(yRot)
        if yRot >= 337.5 or yRot < 22.5 then
            return AIAutomaticSteering.HEADING_LETTERS[1]
        end
        if yRot >= 22.5 and yRot < 67.5 then
            return AIAutomaticSteering.HEADING_LETTERS[2]
        end
        if yRot >= 67.5 and yRot < 112.5 then
            return AIAutomaticSteering.HEADING_LETTERS[3]
        end
        if yRot >= 112.5 and yRot < 157.5 then
            return AIAutomaticSteering.HEADING_LETTERS[4]
        end
        if yRot >= 157.5 and yRot < 202.5 then
            return AIAutomaticSteering.HEADING_LETTERS[5]
        end
        if yRot >= 202.5 and yRot < 247.5 then
            return AIAutomaticSteering.HEADING_LETTERS[6]
        end
        if yRot >= 247.5 and yRot < 292.5 then
            return AIAutomaticSteering.HEADING_LETTERS[7]
        end
        if yRot >= 292.5 and yRot < 337.5 then
            return AIAutomaticSteering.HEADING_LETTERS[8]
        end
    end)
    self:registerDashboardValueType(headingLetter)
end
function AIAutomaticSteering:onDelete()
    local spec = self.spec_aiAutomaticSteering
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples)
    end
end
function AIAutomaticSteering:saveToXMLFile(xmlFile, key, _)
    local spec = self.spec_aiAutomaticSteering
    xmlFile:setValue(key .. "#courseWasActive", spec.lastActiveSteeringFieldCourse == spec.steeringFieldCourse)
    if spec.lastActiveSteeringFieldCourse ~= nil and spec.lastActiveSteeringFieldCourse ~= spec.steeringFieldCourse then
        spec.lastActiveSteeringFieldCourse:saveToXML(xmlFile, key .. ".lastActiveSteeringFieldCourse")
    end
    if spec.steeringFieldCourse ~= nil then
        spec.steeringFieldCourse:saveToXML(xmlFile, key .. ".steeringFieldCourse")
    end
    xmlFile:setValue(key .. "#isOnField", spec.lastIsOnField)
end
function AIAutomaticSteering:onReadStream(streamId, connection)
    if streamReadBool(streamId) then
        SteeringFieldCourse.readStream(streamId, connection, function(steeringFieldCourse)
            -- upvalues: (copy) self
            self:setAIAutomaticSteeringCourse(steeringFieldCourse, true)
            self.spec_aiAutomaticSteering.lastIsOnField = true
            self.spec_aiAutomaticSteering.forceFieldCourseUpdate = false
        end)
    end
end
function AIAutomaticSteering:onWriteStream(streamId, connection)
    local spec = self.spec_aiAutomaticSteering
    if streamWriteBool(streamId, spec.steeringFieldCourse ~= nil) then
        spec.steeringFieldCourse:writeStream(streamId, connection)
    end
end
function AIAutomaticSteering:onReadUpdateStream(streamId, _, connection)
    if connection:getIsServer() and streamReadBool(streamId) then
        SteeringFieldCourse.readSegmentStatesFromStream(self.spec_aiAutomaticSteering.steeringFieldCourse, streamId, connection)
    end
end
function AIAutomaticSteering:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bit32.band(dirtyMask, self.spec_aiAutomaticSteering.dirtyFlag) ~= 0) then
            spec.steeringFieldCourse:writeSegmentStatesToStream(streamId, connection)
        end
    end
end
function AIAutomaticSteering:onUpdate(dt, _, isActiveForInputIgnoreSelection, _)
    local spec = self.spec_aiAutomaticSteering
    if self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST and spec.steeringFieldCourse ~= nil then
        if isActiveForInputIgnoreSelection and VehicleDebug.state == VehicleDebug.DEBUG_AI then
            spec.steeringFieldCourse:draw()
        end
        if self.isServer or isActiveForInputIgnoreSelection then
            local lastSpeed = self:getLastSpeed()
            local aiRootNode = self:getAIRootNode()
            local reverserDirection = self:getReverserDirection()
            local sideOffsetReversed = self:getIsSideOffsetReversed()
            local lookAheadDistance = self:getAIAutomaticSteeringLookAheadDistance()
            local x
            if self.movingDirection < 0 and lastSpeed > 0.25 then
                x = math.min(lookAheadDistance, -4)
            else
                x = math.max(lookAheadDistance, 4)
            end
            local lookAheadDistance = x * reverserDirection
            local z = math.sign(lookAheadDistance)
            local lookAheadDistance = lookAheadDistance + z * math.pow(math.min(lastSpeed / 30, 1), 2) * 5
            local x, _, z = localToWorld(aiRootNode, 0, 0, lookAheadDistance)
            local dirX, _, dirZ = localDirectionToWorld(aiRootNode, 0, 0, 1)
            local tX, tZ = MathUtil.vector2Normalize(dirX, dirZ)
            if spec.steeringFieldCourse:updateVehicleData(dt, spec.steeringEnabled, x, z, tX, tZ, sideOffsetReversed) then
                AIAutomaticSteering.updateActionEvents(self)
            end
            if self.isServer then
                if spec.steeringFieldCourse.currentSegment ~= nil and spec.steeringEnabled then
                    local tX, tZ, distanceToEnd = spec.steeringFieldCourse:getSteeringTarget(aiRootNode, lookAheadDistance, sideOffsetReversed)
                    if tX ~= 0 and tZ ~= 0 then
                        local tX_2 = tX * 0.5
                        local tZ_2 = tZ * 0.5
                        local d1Z = -tX_2
                        local d1X
                        if tX > 0 then
                            d1X = -tZ_2
                            d1Z = tX_2
                        else
                            d1X = tZ_2
                        end
                        local hit, _, f2 = MathUtil.getLineLineIntersection2D(tX_2, tZ_2, d1X, d1Z, 0, 0, tX, 0)
                        local rotTime = 0
                        if hit and math.abs(f2) < 100000 then
                            rotTime = self:getSteeringRotTimeByCurvature(1 / (tX * f2))
                            if reverserDirection < 0 then
                            end
                        end
                        local radius
                        if rotTime >= 0 then
                            radius = math.min(rotTime, self.maxRotTime)
                        else
                            radius = math.max(rotTime, self.minRotTime)
                        end
                        if spec.steeringValue < radius then
                            spec.steeringValue = math.min(spec.steeringValue + dt * self:getAISteeringSpeed(), radius)
                        else
                            spec.steeringValue = math.max(spec.steeringValue - dt * self:getAISteeringSpeed(), radius)
                        end
                        if distanceToEnd == nil then
                            spec.lastDistanceToEnd = 0
                        elseif distanceToEnd ~= spec.lastDistanceToEnd then
                            if spec.lastDistanceToEnd > AIAutomaticSteering.LINE_END_SOUND_DISTANCE and distanceToEnd <= AIAutomaticSteering.LINE_END_SOUND_DISTANCE then
                                SpecializationUtil.raiseEvent(self, "onAIAutomaticSteeringLineEnd")
                                g_server:broadcastEvent(AIAutomaticSteeringLineEndEvent.new(self), nil, nil, self)
                            end
                            if self.isServer and (spec.lastDistanceToEnd > AIAutomaticSteering.CRUISE_CONTROL_DISABLE_DISTANCE and (distanceToEnd <= AIAutomaticSteering.CRUISE_CONTROL_DISABLE_DISTANCE and (self:getVehicleSettingState(GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL) and self.setCruiseControlState ~= nil))) then
                                self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
                            end
                            spec.lastDistanceToEnd = distanceToEnd
                        end
                    end
                end
                if spec.steeringFieldCourse.segmentStatesDirty then
                    self:raiseDirtyFlags(spec.dirtyFlag)
                    spec.steeringFieldCourse.segmentStatesDirty = false
                end
            end
        end
    end
end
function AIAutomaticSteering:onUpdateTick(dt, _, isActiveForInputIgnoreSelection, _)
    local spec = self.spec_aiAutomaticSteering
    if not isActiveForInputIgnoreSelection or self:getAIModeSelection() ~= AIModeSelection.MODE.STEERING_ASSIST then
        ::l2::
        if self.isServer and (self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST and (spec.steeringFieldCourse ~= nil and (spec.steeringEnabled and g_time - spec.steeringLastEnableTime > 2500))) then
            local x = self:getLastSpeed()
            if spec.steeringLockedMovingDirection == 0 then
                if x > 2.5 then
                    spec.steeringLockedMovingDirection = self.movingDirection * self:getReverserDirection()
                    return
                end
            elseif x > 1 and self.movingDirection * self:getReverserDirection() ~= spec.steeringLockedMovingDirection then
                self:setAIAutomaticSteeringEnabled(false)
            end
        end
        return
    end
    local x, _, z = localToWorld(self.rootNode, 0, 0, self.size.length * 0.5 + self.size.lengthOffset)
    local isOnField, farmId = g_fieldCourseManager:roundToTerrainDetailPixel(x, z)
    local isOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, isOnField, 0, farmId) ~= 0
    if not isOnField then
        local farmId, hasAccess, workingWidth = localToWorld(self.rootNode, 0, 0, -self.size.length * 0.5 + self.size.lengthOffset + 1)
        isOnField, farmId = g_fieldCourseManager:roundToTerrainDetailPixel(farmId, workingWidth)
        isOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, isOnField, 0, farmId) ~= 0
    end
    local farmId = self:getActiveFarm()
    if not (g_currentMission.accessHandler:canFarmAccessLand(farmId, isOnField, farmId) or g_missionManager:getIsMissionWorkAllowed(farmId, isOnField, farmId, nil, self)) then
        isOnField = false
    end
    if isOnField == spec.lastIsOnField and not spec.forceFieldCourseUpdate then
        ::l17::
        if not isOnField and (not spec.steeringEnabled and spec.resetCourseTimer > 0) then
            spec.resetCourseTimer = spec.resetCourseTimer - dt
            if spec.resetCourseTimer <= 0 then
                self:setAIAutomaticSteeringCourse(nil)
            end
        end
        goto l2
    end
    spec.lastIsOnField = isOnField
    if not isOnField then
        spec.resetCourseTimer = AIAutomaticSteering.RESET_COURSE_TIME
        goto l27
    end
    spec.resetCourseTimer = 0
    local workingWidth = self:getAttacherToolWorkingWidth()
    local generateCourse = true
    if spec.steeringFieldCourse ~= nil and (not spec.forceFieldCourseUpdate and spec.steeringFieldCourse:getIsPointInsideBoundary(isOnField, farmId)) then
        if workingWidth == 0 then
            ::l25::
            generateCourse = false
            goto l21
        end
        if math.abs(workingWidth - spec.steeringFieldCourse.fieldCourseSettings.implementWidth) < 0.05 then
            goto l25
        end
    end
    ::l21::
    if generateCourse then
        self:initializeLoadedAIModeUserSettings()
        local fieldCourseSettings = self:getAIModeFieldCourseSettings()
        if fieldCourseSettings == nil then
            fieldCourseSettings, _ = FieldCourseSettings.generate(self.rootVehicle)
        end
        if VehicleDebug.state == VehicleDebug.DEBUG_AI then
            fieldCourseSettings:print()
        end
        g_client:getServerConnection():sendEvent(AIAutomaticSteeringRequestEvent.new(self, isOnField, farmId, fieldCourseSettings))
    end
    ::l27::
    spec.forceFieldCourseUpdate = false
    goto l17
end
function AIAutomaticSteering:onStateChange(state, data)
    if state == VehicleStateChange.ATTACH and not data.loadFromSavegame or state == VehicleStateChange.DETACH then
        local spec = self.spec_aiAutomaticSteering
        spec.forceFieldCourseUpdate = true
        spec.lastActiveSteeringFieldCourse = nil
        if self.isServer and (self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST and not self:getIsAutomaticSteeringAllowed()) then
            self:setAIModeSelection(AIModeSelection.MODE.WORKER)
        end
    end
end
function AIAutomaticSteering:onAIModeChanged(aiMode)
    if aiMode == AIModeSelection.MODE.STEERING_ASSIST then
        if self.isActiveForInputIgnoreSelectionIgnoreAI then
            self.spec_aiAutomaticSteering.forceFieldCourseUpdate = true
        end
    else
        self:setAIAutomaticSteeringCourse(nil, true)
    end
end
function AIAutomaticSteering:onAIModeSettingsChanged(aiMode)
    if self.isActiveForInputIgnoreSelectionIgnoreAI and aiMode == AIModeSelection.MODE.STEERING_ASSIST then
        self:setAIAutomaticSteeringCourse(nil)
        self.spec_aiAutomaticSteering.forceFieldCourseUpdate = true
    end
end
function AIAutomaticSteering:onAIAutomaticSteeringLineEnd()
    g_soundManager:playSample(self.spec_aiAutomaticSteering.samples.lineEnd)
end
function AIAutomaticSteering:onActivate()
    if self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST and self:getIsActiveForInput(true, true) then
        local spec = self.spec_aiAutomaticSteering
        if spec.steeringFieldCourse ~= nil then
            g_fieldCourseManager:setActiveSteeringFieldCourse(spec.steeringFieldCourse, self)
        end
    end
end
function AIAutomaticSteering:onLeaveVehicle(_)
    if self.isServer and not (self.isDeleted or self.isDeleting) then
        if self.spec_aiAutomaticSteering.steeringFieldCourse ~= nil then
            g_fieldCourseManager:setActiveSteeringFieldCourse(nil, self)
        end
        self:setAIAutomaticSteeringEnabled(false)
    end
end
function AIAutomaticSteering:getAttacherToolWorkingWidth()
    local workingWidth = 0
    for _, vehicle in pairs(self.rootVehicle.childVehicles) do
        if vehicle.getAIMarkers ~= nil then
            vehicle:updateAIMarkerWidth()
            local _, _, _, _, aiMarkerWidth = vehicle:getAIMarkers()
            if aiMarkerWidth ~= nil then
                workingWidth = math.max(workingWidth, aiMarkerWidth)
            end
        end
        if vehicle.getAIWorkAreaWidth ~= nil then
            workingWidth = math.max(workingWidth, vehicle:getAIWorkAreaWidth())
        end
    end
    return workingWidth
end
function AIAutomaticSteering:getIsAutomaticSteeringAllowed()
    if self.rootVehicle.getImplementAllowAutomaticSteering ~= nil and self.rootVehicle:getImplementAllowAutomaticSteering() then
        return true
    end
    for _, vehicle in pairs(self.rootVehicle.childVehicles) do
        if vehicle.getImplementAllowAutomaticSteering ~= nil and vehicle:getImplementAllowAutomaticSteering() then
            return true
        end
    end
    return false
end
function AIAutomaticSteering:setAIAutomaticSteeringEnabled(isEnabled, segmentIndex, segmentIsLeft, noEventSend)
    local spec = self.spec_aiAutomaticSteering
    if isEnabled == nil then
        isEnabled = not spec.steeringEnabled
    end
    if isEnabled ~= spec.steeringEnabled then
        spec.steeringEnabled = isEnabled
        if isEnabled then
            spec.steeringValue = self.rotatedTime
            spec.steeringLastEnableTime = g_time
            spec.steeringLockedMovingDirection = 0
            spec.lastDistanceToEnd = 0
            if self.isServer then
                spec.lastActiveSteeringFieldCourse = spec.steeringFieldCourse
            end
        end
        if self.isClient then
            if isEnabled then
                g_soundManager:playSample(spec.samples.engage)
            else
                g_soundManager:playSample(spec.samples.disengage)
            end
            AIAutomaticSteering.updateActionEvents(self)
            if self.updateDashboardValueType ~= nil then
                self:updateDashboardValueType("ai.automaticSteering.steeringEngaged")
                self:updateDashboardValueType("ai.automaticSteering.steeringState")
            end
        end
    end
    if spec.steeringFieldCourse ~= nil then
        if self.isServer then
            segmentIndex = spec.steeringFieldCourse.currentSegmentIndex
            segmentIsLeft = spec.steeringFieldCourse.currentSegmentIsLeft
        elseif segmentIndex ~= nil then
            spec.steeringFieldCourse:setCurrentSegmentIndex(segmentIndex, segmentIsLeft)
        end
    end
    AIAutomaticSteeringStateEvent.sendEvent(self, isEnabled, segmentIndex, segmentIsLeft, noEventSend)
    return segmentIndex, segmentIsLeft
end
function AIAutomaticSteering:setAIAutomaticSteeringCourse(steeringFieldCourse, noEventSend)
    local spec = self.spec_aiAutomaticSteering
    spec.steeringFieldCourse = steeringFieldCourse
    if steeringFieldCourse == nil and spec.steeringEnabled then
        self:setAIAutomaticSteeringEnabled(false, nil, nil, true)
    end
    if self.isActiveForInputIgnoreSelectionIgnoreAI then
        g_fieldCourseManager:setActiveSteeringFieldCourse(steeringFieldCourse, self)
    end
    if self.isClient then
        AIAutomaticSteering.updateActionEvents(self)
        if self.updateDashboardValueType ~= nil then
            self:updateDashboardValueType("ai.automaticSteering.steeringState")
        end
    end
    if noEventSend ~= true then
        if g_server ~= nil then
            g_server:broadcastEvent(AIAutomaticSteeringCourseEvent.new(self, steeringFieldCourse), nil, nil, self)
            return
        end
        g_client:getServerConnection():sendEvent(AIAutomaticSteeringCourseEvent.new(self, steeringFieldCourse))
    end
end
function AIAutomaticSteering:generateSteeringFieldCourse(x, z, fieldCourseSettings)
    local spec = self.spec_aiAutomaticSteering
    if spec.lastActiveSteeringFieldCourse == nil or not (spec.lastActiveSteeringFieldCourse:getIsPointInsideBoundary(x, z) and fieldCourseSettings:isIdentical(spec.lastActiveSteeringFieldCourse.fieldCourseSettings)) then
        if spec.fieldCourseDetectionInProgress then
            spec.fieldCourseDetectionPendingData = {
                ["x"] = x,
                ["z"] = z,
                ["fieldCourseSettings"] = fieldCourseSettings
            }
        else
            spec.fieldCourseDetectionInProgress = true
            g_fieldCourseManager:generateFieldCourseAtWorldPos(x, z, fieldCourseSettings, function(_, course)
                -- upvalues: (copy) spec, (copy) self
                spec.fieldCourseDetectionInProgress = false
                if course == nil then
                    Logging.devInfo("Failed to generate field course for AISteering")
                    self:setAIAutomaticSteeringCourse(nil)
                else
                    self:setAIAutomaticSteeringCourse((SteeringFieldCourse.new(course)))
                end
                if spec.fieldCourseDetectionPendingData ~= nil then
                    local steeringFieldCourse = spec.fieldCourseDetectionPendingData
                    spec.fieldCourseDetectionPendingData = nil
                    self:generateSteeringFieldCourse(steeringFieldCourse.x, steeringFieldCourse.z, steeringFieldCourse.fieldCourseSettings)
                end
            end)
        end
    else
        self:setAIAutomaticSteeringCourse(spec.lastActiveSteeringFieldCourse)
        return
    end
end
function AIAutomaticSteering:getIsAIAutomaticSteeringAllowed()
    local spec = self.spec_aiAutomaticSteering
    if spec.steeringFieldCourse == nil then
        return false, g_i18n:getText("ai_automaticSteeringWarningNoCourse")
    elseif spec.steeringFieldCourse.currentSegment == nil then
        return false, g_i18n:getText("ai_automaticSteeringWarningNoSegment")
    else
        return true
    end
end
function AIAutomaticSteering:getAIAutomaticSteeringState()
    local spec = self.spec_aiAutomaticSteering
    if spec.steeringFieldCourse == nil then
        return AIAutomaticSteering.STATE.DISABLED
    elseif spec.steeringEnabled then
        return AIAutomaticSteering.STATE.ACTIVE
    else
        return AIAutomaticSteering.STATE.AVAILABLE
    end
end
function AIAutomaticSteering:getAIAutomaticSteeringLookAheadDistance()
    local spec = self.spec_aiAutomaticSteering
    if spec.lookAheadDistance == nil then
        return self.movingDirection >= 0 and self:getAIRootNodeMaxZOffset() or self:getAIRootNodeMinZOffset()
    else
        return spec.lookAheadDistance
    end
end
function AIAutomaticSteering:getIsSideOffsetReversed()
    for _, vehicle in pairs(self.rootVehicle.childVehicles) do
        if vehicle.spec_plow ~= nil then
            return vehicle.spec_plow.rotationMax
        end
    end
    return false
end
function AIAutomaticSteering:setSteeringInput(superFunc, inputValue, isAnalog, deviceCategory)
    local spec = self.spec_aiAutomaticSteering
    if spec.steeringEnabled then
        if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
            self:setAIAutomaticSteeringEnabled(false)
        elseif g_time - spec.steeringLastEnableTime > 2500 then
            if math.abs(inputValue - spec.lastSteeringInputValue) > 0.1 then
                self:setAIAutomaticSteeringEnabled(false)
            end
        else
            spec.lastSteeringInputValue = inputValue
        end
    else
        spec.lastSteeringInputValue = inputValue
    end
    return superFunc(self, inputValue, isAnalog, deviceCategory)
end
function AIAutomaticSteering:updateVehiclePhysics(superFunc, axisForward, axisSide, doHandbrake, dt)
    local spec = self.spec_aiAutomaticSteering
    if not spec.steeringEnabled then
        return superFunc(self, axisForward, axisSide, doHandbrake, dt)
    end
    if spec.steeringValue < 0 then
        axisSide = -spec.steeringValue / self.maxRotTime
    else
        axisSide = spec.steeringValue / self.minRotTime
    end
    local acceleration = superFunc(self, axisForward, axisSide, doHandbrake, dt)
    self.rotatedTime = spec.steeringValue
    self.spec_drivable.axisSide = axisSide
    return acceleration
end
function AIAutomaticSteering:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_aiAutomaticSteering
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_AI_STEERING, self, AIAutomaticSteering.actionEventSteering, false, true, false, true, nil)
            if actionEventId ~= nil then
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                g_inputBinding:setActionEventText(actionEventId, string.format(g_i18n:getText("ai_modeSelect"), g_i18n:getText("ai_modeSteeringAssist")))
                AIAutomaticSteering.updateActionEvents(self)
            end
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_AI_STEERING_LINES, self, AIAutomaticSteering.actionEventSteeringLines, false, true, false, true, nil)
            if actionEventId ~= nil then
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            end
        end
    end
end
function AIAutomaticSteering:actionEventSteering(_, _, _, _)
    self:setAIAutomaticSteeringEnabled()
end
function AIAutomaticSteering:updateActionEvents()
    local spec = self.spec_aiAutomaticSteering
    local actionEvent = spec.actionEvents[InputAction.TOGGLE_AI_STEERING]
    if actionEvent ~= nil then
        local isActive = false
        if spec.steeringFieldCourse ~= nil then
            isActive = spec.steeringFieldCourse.currentSegment ~= nil
        end
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, isActive)
    end
end
function AIAutomaticSteering:actionEventSteeringLines()
    local value = g_gameSettings:getValue(GameSettings.SETTING.STEERING_ASSIST_LINES)
    g_gameSettings:setValue(GameSettings.SETTING.STEERING_ASSIST_LINES, not value, true)
end