AIDriveStrategyFieldCourse = {}
source("dataS/scripts/vehicles/ai/AICollisionTriggerHandler.lua")
local AIDriveStrategyFieldCourse_mt = Class(AIDriveStrategyFieldCourse, AIDriveStrategy)
function AIDriveStrategyFieldCourse.new(reconstructionData, customMt)
    -- upvalues: (copy) AIDriveStrategyFieldCourse_mt
    local self = AIDriveStrategy.new(reconstructionData, customMt or AIDriveStrategyFieldCourse_mt)
    self.collisionHandler = AICollisionTriggerHandler.new()
    self.isBlocked = false
    self.hasStaticCollision = false
    self.hasStaticCollisionTimer = 0
    self.collisionDistance = math.huge
    self.lastContinueWorkState = false
    self.lastContinueWorkBlockedTime = -math.huge
    self.reconstructionData = reconstructionData
    return self
end
function AIDriveStrategyFieldCourse:delete()
    AIDriveStrategyFieldCourse:superClass().delete(self)
    for _, implement in ipairs(self.vehicle:getAttachedAIImplements()) do
        implement.object:aiImplementEndLine()
        implement.object.rootVehicle:raiseStateChange(VehicleStateChange.AI_END_LINE)
    end
end
function AIDriveStrategyFieldCourse:setAIVehicle(vehicle)
    AIDriveStrategyFieldCourse:superClass().setAIVehicle(self, vehicle)
    self.collisionHandler:init(vehicle, self)
    self.vehicleAISteeringNode = self.vehicle:getAISteeringNode()
    self.vehicleAISteeringNodeReverse = self.vehicle:getAIReverserNode()
    self.reverserDirectionNode = AIVehicleUtil.getAIToolReverserDirectionNode(self.vehicle)
    self.reverserDirectionNodeRefNode = self.reverserDirectionNode
    if self.reverserDirectionNodeRefNode == nil then
        if self.vehicle.getAIToolReverserDirectionNode ~= nil then
            self.reverserDirectionNodeRefNode = self.vehicle:getAIToolReverserDirectionNode()
        end
        if self.reverserDirectionNodeRefNode == nil and self.vehicleAISteeringNodeReverse ~= self.vehicleAISteeringNode then
            self.reverserDirectionNodeRefNode = self.vehicleAISteeringNodeReverse
        end
    end
    self.vehicle.aiDriveDirection = { 0, 1 }
    self.vehicle.aiDriveTarget = { 0, 0 }
    self.lastVehiclePosition = { 0, 0, 0 }
    self.lastTargetPosition = { 0, 0, 1 }
    self.lastMovingDirection = 1
    self.lastSegmentIsTurn = false
    self.nextSegmentTurnSide = nil
    self.lastSegmentTurnSide = nil
    self.vehicle:initializeLoadedAIModeUserSettings()
    self.fieldCourseSettings = self.vehicle:getAIModeFieldCourseSettings()
    if self.fieldCourseSettings == nil then
        local doFieldDetection, vx = FieldCourseSettings.generate(self.vehicle)
        self.fieldCourseSettings = doFieldDetection
        self.implementData = vx
    else
        self.implementData = self.fieldCourseSettings:resetDynamicSettings(self.vehicle)
    end
    self.fieldCourseSettings:print(self.debugPrint, self)
    local doFieldDetection = true
    if self.reconstructionData ~= nil and self.reconstructionData.aiFieldCourseReconstructionData ~= nil then
        doFieldDetection = false
        Logging.devInfo("Using field course data from savegame")
        local vx, _, vz = localToWorld(self.vehicle:getAIDirectionNode(), 0, 0, 0)
        self.fieldDetectionInProgress = true
        if not self.reconstructionData.aiFieldCourseReconstructionData:apply(self, self.onFieldCourseLoadedCallback, vx, vz) then
            self.fieldDetectionInProgress = nil
            doFieldDetection = true
        end
    end
    if doFieldDetection then
        local vx = false
        if AIDriveStrategyFieldCourse.fieldDetectionPosition == nil then
            local _, vz
            _, vz, vx = FieldCourse.findClosestField(nil, nil, nil, nil, self.vehicle:getAIJobFarmId(), self.vehicle, 2, self.fieldCourseSettings)
            self.fieldDetectionX = _
            self.fieldDetectionZ = vz
        else
            self.fieldDetectionX = AIDriveStrategyFieldCourse.fieldDetectionPosition[1]
            self.fieldDetectionZ = AIDriveStrategyFieldCourse.fieldDetectionPosition[2]
        end
        if self.fieldDetectionX == nil or vx ~= false then
            if vx then
                self.fieldNotOwned = true
            end
        else
            self.fieldDetectionInProgress = true
            g_fieldCourseManager:generateFieldCourseAtWorldPos(self.fieldDetectionX, self.fieldDetectionZ, self.fieldCourseSettings, self.onFieldCourseLoadedCallback, self)
        end
    end
    self.collisionHandler:setStaticCollisionCallback(function(hasStaticCollision)
        -- upvalues: (copy) self
        self.hasStaticCollision = hasStaticCollision
    end)
    self.collisionHandler:setIsBlockedCallback(function(isBlocked)
        -- upvalues: (copy) self
        self.isBlocked = isBlocked
        if g_server ~= nil then
            g_server:broadcastEvent(AIVehicleIsBlockedEvent.new(self.vehicle, isBlocked), true, nil, self.vehicle)
        end
    end)
    self.collisionHandler:setCollisionDistanceCallback(function(distance)
        -- upvalues: (copy) self
        self.collisionDistance = distance
    end)
end
function AIDriveStrategyFieldCourse:onFieldCourseLoadedCallback(fieldCourse)
    if self.vehicle.isDeleted or self.vehicle.isDeleting then
        return
    elseif fieldCourse == nil then
        self.vehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
        self:debugPrint("Stopping AIVehicle - Field boundary not detected")
        return
    else
        local aiFieldCourse
        if ClassUtil.getClassObjectByObject(fieldCourse) == FieldCourse then
            aiFieldCourse = AIFieldCourse.new(fieldCourse)
        else
            aiFieldCourse = fieldCourse.fieldCourse
        end
        if fieldCourse.isVineyardCourse then
            self.vehicle:stopCurrentAIJob(AIMessageErrorVineyardNotSupported.new())
            self:debugPrint("Stopping AIVehicle - Vineyard course not supported")
        else
            local aiRootNode = self.vehicle:getAIDirectionNode()
            local dx, _, dz = localToWorld(aiRootNode, 0, 0, 0)
            self.startX = dx
            self.startZ = dz
            local dx, _, dz = localDirectionToWorld(aiRootNode, 0, 0, 1)
            self.startYRot = MathUtil.getYRotationFromDirection(dx, dz)
            local attachedAIImplements = self.vehicle:getAttachedAIImplements()
            aiFieldCourse:setStartPosition(self.startX, self.startZ, self.startYRot)
            self:debugPrint("  Start Position: %.3f %.3f (%.3f\194\176)", self.startX, self.startZ, (math.deg(self.startYRot)))
            self.aiFieldCourse = aiFieldCourse
            aiFieldCourse:setInitialSegmentCallback(function()
                -- upvalues: (copy) self
                self.initialSegmentFinished = true
                if not self.fieldCourseSettings.workInitialSegment then
                    self.vehicle:raiseAIEvent("onAIFieldWorkerPrepareForWork", "onAIImplementPrepareForWork")
                end
            end)
            aiFieldCourse:setSegmentAreaValidityFunction(function(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
                -- upvalues: (copy) attachedAIImplements
                for i, implement in ipairs(attachedAIImplements) do
                    local area, totalArea = AIVehicleUtil.getAIAreaOfVehicle(implement.object, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
                    if totalArea > 0 and area / totalArea > 0 then
                        return true
                    end
                end
                return false
            end)
            if self.fieldCourseSettings.workInitialSegment then
                self.vehicle:raiseAIEvent("onAIFieldWorkerPrepareForWork", "onAIImplementPrepareForWork")
            end
            aiFieldCourse:finalize(function()
                -- upvalues: (ref) aiFieldCourse, (copy) self
                if #aiFieldCourse.fieldCourse.segments == 0 then
                    self.vehicle:stopCurrentAIJob(AIMessageErrorFieldNotReady.new())
                else
                    self.fieldDetectionInProgress = false
                end
            end)
        end
    end
end
function AIDriveStrategyFieldCourse:update(dt)
    self.collisionHandler:update(dt, self.lastMovingDirection)
    if self.aiFieldCourse ~= nil then
        self.aiFieldCourse:update(dt)
        if VehicleDebug.state == VehicleDebug.DEBUG_AI and self.vehicle.isActiveForInputIgnoreSelectionIgnoreAI then
            self.aiFieldCourse:draw()
            self.fieldCourseSettings:draw()
        end
        local aiImplements = self.vehicle:getAttachedAIImplements()
        local segmentIsTurn, segmentIsInitial, segmentPosition, _, _, _ = self.aiFieldCourse:getActiveSegmentData()
        if segmentIsTurn ~= nil then
            local isInitial, sideOffset = self.aiFieldCourse:getNextSegmentData()
            if not isInitial and sideOffset ~= nil then
                local nextSegmentTurnSide = sideOffset > 0
                if nextSegmentTurnSide ~= self.nextSegmentTurnSide then
                    self.vehicle:aiFieldWorkerSideOffsetChanged(nextSegmentTurnSide, segmentIsInitial)
                    self.nextSegmentTurnSide = nextSegmentTurnSide
                end
            end
            if not segmentIsInitial or self.fieldCourseSettings.workInitialSegment then
                if segmentIsTurn == self.lastSegmentIsTurn then
                    if segmentIsTurn then
                        self.vehicle:aiFieldWorkerTurnProgress(segmentPosition, self.lastSegmentTurnSide, self.lastMovingDirection)
                    end
                else
                    if segmentIsTurn then
                        self.lastSegmentTurnSide = self.nextSegmentTurnSide
                        self.vehicle:aiFieldWorkerStartTurn(self.lastSegmentTurnSide, nil)
                    else
                        self.vehicle:aiFieldWorkerEndTurn(self.lastSegmentTurnSide, nil)
                    end
                    self.lastSegmentIsTurn = segmentIsTurn
                end
                for i, implement in ipairs(aiImplements) do
                    local data = self.implementData[i]
                    if self.fieldCourseSettings.toolAlwaysActive then
                        local doAreaCheck = not segmentIsTurn
                        if doAreaCheck then
                            doAreaCheck = self.lastMovingDirection >= 0
                        end
                        data.isLowered = doAreaCheck
                    else
                        local doAreaCheck = false
                        local doAreaCheck
                        if segmentIsTurn or self.lastMovingDirection < 0 then
                            data.isLowered = false
                        else
                            doAreaCheck = g_time - self.lastContinueWorkBlockedTime > 1000
                        end
                        if doAreaCheck then
                            local leftNode, rightNode, backMarker, markersInverted = implement.object:getAIMarkers()
                            local lookAheadDistance = implement.object:getAILookAheadSize()
                            local _, _, areaLength = localToLocal(leftNode, backMarker, 0, 0, 0)
                            local zOffset = -areaLength
                            local xOffsetRight = 0.2
                            local xOffsetLeft = -0.2
                            if markersInverted then
                            end
                            local sX, _, sZ = localToWorld(leftNode, xOffsetLeft, 0, zOffset)
                            local hX, _, hZ = localToWorld(leftNode, xOffsetLeft, 0, zOffset + (lookAheadDistance + areaLength))
                            local wX, _, wZ = localToWorld(rightNode, xOffsetRight, 0, zOffset)
                            local zOffset, xOffsetLeft = AIVehicleUtil.getAIAreaOfVehicle(implement.object, sX, sZ, wX, wZ, hX, hZ)
                            if xOffsetLeft > 0 and zOffset / xOffsetLeft > 0 then
                                data.isLowered = true
                            else
                                data.isLowered = false
                            end
                            if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                                local xOffsetRight, sX, _, sZ, hX, _ = MathUtil.getXZWidthAndHeight(sX, sZ, wX, wZ, hX, hZ)
                                DebugUtil.drawDebugParallelogram(xOffsetRight, sX, _, sZ, hX, _, 0.2, data.isLowered and 0 or 1, data.isLowered and 1 or 0, 0, 1)
                            end
                        end
                    end
                    while data.parentAIImplement ~= nil do
                        if data.isLowered and not data.parentAIImplement.isLowered then
                            data.parentAIImplement.isLowered = true
                        end
                        data = data.parentAIImplement
                    end
                end
            end
        end
        self.vehicle:setAIFieldWorkerIsTurning(segmentIsTurn)
        local isInitial = self.aiFieldCourse:getIsCornerCutOutActive()
        self.vehicle:setAIFieldWorkerIsCornerCutOutActive(isInitial)
        for i, i in ipairs(aiImplements) do
            local implement = self.implementData[i]
            if implement.isLowered then
                if implement.wasLowered ~= true then
                    i.object:aiImplementStartLine()
                    i.object:getRootVehicle():raiseStateChange(VehicleStateChange.AI_START_LINE)
                end
            elseif implement.wasLowered ~= false then
                i.object:aiImplementEndLine()
                i.object:getRootVehicle():raiseStateChange(VehicleStateChange.AI_END_LINE)
            end
            implement.wasLowered = implement.isLowered
        end
        local sideOffset = self.lastVehiclePosition[1]
        local nextSegmentTurnSide = self.lastVehiclePosition[2]
        local vZ = self.lastVehiclePosition[3]
        local i = self.lastTargetPosition[1]
        local i = self.lastTargetPosition[2]
        local implement = self.lastTargetPosition[3]
        local data, doAreaCheck = MathUtil.vector2Normalize(i - sideOffset, implement - vZ)
        local leftNode = 0
        local rightNode = 1
        local backMarker = 0
        if self.lastMovingDirection < 0 then
            leftNode = 1
            rightNode = 0
            backMarker = 0
        end
        drawDebugTriangle(sideOffset + doAreaCheck * 0.25, nextSegmentTurnSide + 4, vZ - data * 0.25, sideOffset - doAreaCheck * 0.25, nextSegmentTurnSide + 4, vZ + data * 0.25, i, i + 4, implement, leftNode, rightNode, backMarker, 0.2, true)
        if self.hasStaticCollision and self.lastContinueWorkState then
            if self.vehicle:getLastSpeed() >= 1 then
                self.hasStaticCollisionTimer = 0
                return
            end
            self.hasStaticCollisionTimer = self.hasStaticCollisionTimer + dt
            if self.hasStaticCollisionTimer > 5000 then
                self.hasStaticCollisionTimer = 0
                self.aiFieldCourse:skipCurrentSubSegment(25)
                self:debugPrint("AIVehicle blocked - skip current sub segment")
                return
            end
        else
            self.hasStaticCollisionTimer = 0
        end
    end
end
function AIDriveStrategyFieldCourse:getDriveData(dt, _, _, _)
    if self.fieldDetectionInProgress == nil then
        if self.fieldNotOwned then
            self.vehicle:stopCurrentAIJob(AIMessageErrorFieldNotOwned.new())
            self:debugPrint("Stopping AIVehicle - Field not owned")
        else
            self.vehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
            self:debugPrint("Stopping AIVehicle - Failed to start field detection")
        end
    else
        local isTurning = false
        if self.aiFieldCourse ~= nil then
            local tZ, moveForwards, maxSpeed, distanceToStop, canContinueWork
            isTurning, tZ, moveForwards, maxSpeed, distanceToStop, canContinueWork = self.aiFieldCourse:getActiveSegmentData()
        end
        local tX = 0
        local tZ = 0
        local moveForwards = true
        local maxSpeed = 0
        local distanceToStop = 0
        local canContinueWork, stopAI, stopReason = self.vehicle:getCanAIFieldWorkerContinueWork(isTurning)
        if canContinueWork then
            self.lastContinueWorkState = true
            if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                if self.aiFieldCourse ~= nil then
                    self.aiFieldCourse:addDebugTexts(self.vehicle)
                end
                self.vehicle:addAIDebugText(string.format(" Has Static Collision: %s", self.hasStaticCollision))
                self.vehicle:addAIDebugText(string.format(" Collision Distance: dynamic: %.1f static: %.1f", self.collisionHandler.dynamicHitPointDistance, self.collisionHandler.staticHitPointDistance))
                self.vehicle:addAIDebugText(string.format(" Is Blocked: %s", self.isBlocked))
                self.vehicle:addAIDebugText(string.format(" Distance To Collision: %s", self.collisionDistance))
                if self.aiFieldCourse ~= nil then
                    local aiImplements = self.vehicle:getAttachedAIImplements()
                    for i, implement in ipairs(aiImplements) do
                        local leftMarker, rightMarker, backMarker, _ = implement.object:getAIMarkers()
                        local lx, _, lz = getWorldTranslation(leftMarker)
                        local rx, _, rz = getWorldTranslation(rightMarker)
                        local leftOffset = self.aiFieldCourse:getPositionOffsetToActiveSegment(lx, lz)
                        local rightOffset = self.aiFieldCourse:getPositionOffsetToActiveSegment(rx, rz)
                        local _, _, maxZOffset = localToLocal(leftMarker, self.vehicleAISteeringNode, 0, 0, 0)
                        local _, _, minZOffset = localToLocal(backMarker, self.vehicleAISteeringNode, 0, 0, 0)
                        self.vehicle:addAIDebugText(string.format("%s", implement.object:getName()))
                        self.vehicle:addAIDebugText(string.format("    Side Drift: %.2fm | Width: %.2fm", (leftOffset + rightOffset) * 0.5 * -1, calcDistanceFrom(leftMarker, rightMarker)))
                        self.vehicle:addAIDebugText(string.format("    zOffset: %.2fm / %.2fm", minZOffset, maxZOffset))
                    end
                    self.vehicle:addAIDebugText(string.format(" Segment Side Offset: %.2f", self.aiFieldCourse:getActiveSegmentSideOffset()))
                end
            end
            if self.isBlocked then
                return tX, tZ, moveForwards, maxSpeed, distanceToStop
            end
            if self.aiFieldCourse ~= nil then
                local rx, _, rz = getWorldTranslation(self.lastMovingDirection > 0 and self.vehicleAISteeringNode or self.vehicleAISteeringNodeReverse)
                tX, tZ, moveForwards, maxSpeed, distanceToStop = self.aiFieldCourse:getDriveData(dt, rx, _, rz, self.vehicle:getLastSpeed(), 4, self.reverserDirectionNodeRefNode)
                if tX ~= nil and (tX ~= 0 or tZ ~= 0) then
                    if not moveForwards and self.reverserDirectionNode ~= nil then
                        local rx, _, rz = getWorldTranslation(self.reverserDirectionNode)
                        local i = MathUtil.vector2Length(tX - rx, tZ - rz)
                        local implement, leftMarker, rightMarker = localDirectionToWorld(self.vehicleAISteeringNodeReverse, 0, 0, 1)
                        local backMarker = MathUtil.vector2Length(implement, rightMarker)
                        local _, lx, _ = localDirectionToWorld(self.reverserDirectionNode, 0, 0, 1)
                        local lz = MathUtil.vector2Length(_, _)
                        if backMarker > 0 and lz > 0 then
                            local _ = _ / lz
                            local _ = _ / lz
                            local rx = MathUtil.getProjectOnLineParameter(tX, tZ, rx, rz, _, _)
                            local _ = math.sqrt(i * i - rx * rx)
                            local rz, leftOffset = MathUtil.vector2Normalize(rx - tX, rz - tZ)
                            local _ = MathUtil.dotProduct(-_, 0, _, rz, 0, leftOffset)
                            local _ = _ * math.sign(_)
                            local rightOffset = MathUtil.getSignedAngleBetweenVectors2D(implement / backMarker, rightMarker / backMarker, _, _)
                            local _ = math.cos(rightOffset) * _ - math.sin(rightOffset) * rx
                            local _ = math.sin(rightOffset) * _ + math.cos(rightOffset) * rx
                            if not (MathUtil.isNan(_) or MathUtil.isNan(_)) then
                                tX, _, tZ = localToWorld(self.vehicleAISteeringNodeReverse, -_, 0, _)
                            end
                        end
                    end
                    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                        local rx, _, rz, i, implement, leftMarker = self.aiFieldCourse:getActiveSegmentData()
                        if rz ~= nil then
                            self.vehicle:addAIDebugText(string.format("Segment Position: %.1f%% of %.1fm", rz * 100, i))
                            if leftMarker ~= i then
                                self.vehicle:addAIDebugText(string.format("Sub Segment Position: %.1f%% of %.1fm", implement * 100, leftMarker))
                            end
                        end
                    end
                    self.lastVehiclePosition[1] = rx
                    self.lastVehiclePosition[2] = _
                    self.lastVehiclePosition[3] = rz
                    self.lastTargetPosition[1] = tX
                    self.lastTargetPosition[2] = _
                    self.lastTargetPosition[3] = tZ
                    local rx = moveForwards and 1 or -1
                    self.lastMovingDirection = rx
                end
            end
            if self.collisionDistance ~= math.huge and moveForwards then
                maxSpeed = math.min(maxSpeed, (math.max(self.collisionDistance * 2, 1)))
            end
            return tX, tZ, moveForwards, maxSpeed, distanceToStop
        else
            self.lastContinueWorkState = false
            self.lastContinueWorkBlockedTime = g_time
            if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                self.vehicle:addAIDebugText("- Wait for turn on (getCanAIFieldWorkerContinueWork)")
            end
            if stopAI then
                self.vehicle:stopCurrentAIJob(stopReason or AIMessageErrorUnknown.new())
                self:debugPrint("Stopping AIVehicle - cannot continue work")
            end
            return tX, tZ, moveForwards, 0, distanceToStop
        end
    end
end
function AIDriveStrategyFieldCourse:fillReconstructionData(data)
    if self.aiFieldCourse ~= nil then
        data.aiFieldCourseReconstructionData = AIFieldCourseReconstructionData.new()
        data.aiFieldCourseReconstructionData:setDataByAIFieldCourse(self.aiFieldCourse)
    end
end
function AIDriveStrategyFieldCourse.saveToXML(data, xmlFile, key)
    if data.aiFieldCourseReconstructionData ~= nil then
        data.aiFieldCourseReconstructionData:saveToXML(xmlFile, key .. ".strategyFieldCourse")
    end
end
function AIDriveStrategyFieldCourse.loadFromXML(data, xmlFile, key)
    data.aiFieldCourseReconstructionData = AIFieldCourseReconstructionData.new()
    if not data.aiFieldCourseReconstructionData:loadFromXML(xmlFile, key .. ".strategyFieldCourse") then
        data.aiFieldCourseReconstructionData = nil
    end
end
function AIDriveStrategyFieldCourse.registerSavegameXMLPaths(schema, basePath)
    AIFieldCourseReconstructionData.registerXMLPaths(schema, basePath .. ".strategyFieldCourse")
end