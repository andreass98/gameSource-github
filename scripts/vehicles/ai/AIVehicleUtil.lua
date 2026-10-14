AIVehicleUtil = {}
AIVehicleUtil.VALID_AREA_THRESHOLD = 0.02
AIVehicleUtil.AREA_OVERLAP = 0.26
function AIVehicleUtil:driveToPoint(dt, acceleration, allowedToDrive, moveForwards, tX, tZ, maxSpeed, doNotSteer)
    if self.finishedFirstUpdate then
        if allowedToDrive then
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
            if doNotSteer == nil or not doNotSteer then
                local rotTime = 0
                if hit and math.abs(f2) < 100000 then
                    rotTime = self:getSteeringRotTimeByCurvature(1 / (tX * f2))
                    if self:getReverserDirection() < 0 then
                    end
                end
                local steerDiff
                if rotTime >= 0 then
                    steerDiff = math.min(rotTime, self.maxRotTime)
                else
                    steerDiff = math.max(rotTime, self.minRotTime)
                end
                if self.rotatedTime < steerDiff then
                    local fac = self.rotatedTime + dt * self:getAISteeringSpeed()
                    self.rotatedTime = math.min(fac, steerDiff)
                else
                    local fac = self.rotatedTime - dt * self:getAISteeringSpeed()
                    self.rotatedTime = math.max(fac, steerDiff)
                end
                local steerDiff = steerDiff - self.rotatedTime
                local speedReduction = math.abs(steerDiff)
                local fac = speedReduction / math.max(self.maxRotTime, -self.minRotTime)
                local speedReduction = 1 - math.pow(fac, 0.25)
                if maxSpeed * speedReduction < 1 then
                    acceleration = 0
                    speedReduction = 1 / maxSpeed
                end
                maxSpeed = maxSpeed * speedReduction
            end
        end
        self:getMotor():setSpeedLimit((math.min(maxSpeed, self:getCruiseControlSpeed())))
        if self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_ACTIVE then
            self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
        end
        acceleration = not allowedToDrive and 0 or acceleration
        if not moveForwards then
        end
        WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, acceleration, not allowedToDrive, true)
    end
end
function AIVehicleUtil:driveAlongCurvature(dt, curvature, maxSpeed, acceleration)
    maxSpeed = maxSpeed or math.huge
    self.rotatedTime = -(self:getSteeringRotTimeByCurvature(curvature) * self:getSteeringDirection())
    if self.finishedFirstUpdate then
        if maxSpeed > 0 then
            if self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_ACTIVE then
                self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
            end
        else
            acceleration = 0
        end
        self:getMotor():setSpeedLimit(maxSpeed)
        WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, acceleration, maxSpeed > 0, true)
    end
end
function AIVehicleUtil:driveInDirection(dt, steeringAngleLimit, acceleration, slowAcceleration, slowAngleLimit, allowedToDrive, moveForwards, lx, dot, maxSpeed, slowDownFactor)
    local angle = 0
    if lx ~= nil and dot ~= nil then
        local targetRotTime = math.acos(dot)
        angle = math.deg(targetRotTime)
        if angle < 0 then
        end
        local turnLeft = lx > 0.00001
        if not moveForwards then
        end
        local targetRotTime
        if turnLeft then
            targetRotTime = self.maxRotTime * math.min(angle / steeringAngleLimit, 1)
        else
            targetRotTime = self.minRotTime * math.min(angle / steeringAngleLimit, 1)
        end
        if self.rotatedTime < targetRotTime then
            self.rotatedTime = math.min(self.rotatedTime + dt * self:getAISteeringSpeed(), targetRotTime)
        else
            self.rotatedTime = math.max(self.rotatedTime - dt * self:getAISteeringSpeed(), targetRotTime)
        end
    end
    if self.finishedFirstUpdate then
        if maxSpeed == nil or maxSpeed == 0 then
            if slowAngleLimit > math.abs(angle) then
                slowAcceleration = acceleration
            end
        else
            if slowAngleLimit <= math.abs(angle) then
            end
            self.motor:setSpeedLimit(maxSpeed)
            if self.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
                slowAcceleration = acceleration
            else
                self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
                slowAcceleration = acceleration
            end
        end
        local turnLeft = not allowedToDrive and 0 or slowAcceleration
        if not moveForwards then
        end
        WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, turnLeft, not allowedToDrive, true)
    end
end
function AIVehicleUtil.getDriveDirection(refNode, x, y, z)
    local lx, _, lz = worldToLocal(refNode, x, y, z)
    local length = MathUtil.vector2Length(lx, lz)
    if length > 0.00001 then
        local length = 1 / length
    end
    return lx, lz
end
function AIVehicleUtil.getAverageDriveDirection(refNode, x, y, z, x2, y2, z2)
    local lx, _, lz = worldToLocal(refNode, (x + x2) * 0.5, (y + y2) * 0.5, (z + z2) * 0.5)
    local length = MathUtil.vector2Length(lx, lz)
    if length > 0.00001 then
    end
    return lx, lz, length
end
function AIVehicleUtil.getAttachedImplementsAllowTurnBackward(vehicle)
    if vehicle.getAIAllowTurnBackward ~= nil and not vehicle:getAIAllowTurnBackward() then
        return false
    end
    if vehicle.getAttachedImplements ~= nil then
        for _, implement in pairs(vehicle:getAttachedImplements()) do
            local object = implement.object
            if object ~= nil then
                if object.getAIAllowTurnBackward ~= nil and not object:getAIAllowTurnBackward() then
                    return false
                end
                if not AIVehicleUtil.getAttachedImplementsAllowTurnBackward(object) then
                    return false
                end
            end
        end
    end
    return true
end
function AIVehicleUtil.getAttachedImplementsBlockTurnBackward(vehicle)
    if vehicle.getAIBlockTurnBackward ~= nil and vehicle:getAIBlockTurnBackward() then
        return true
    end
    if vehicle.getAttachedImplements ~= nil then
        for _, implement in pairs(vehicle:getAttachedImplements()) do
            local object = implement.object
            if object ~= nil then
                if object.getAIBlockTurnBackward ~= nil and object:getAIBlockTurnBackward() then
                    return true
                end
                if AIVehicleUtil.getAttachedImplementsBlockTurnBackward(object) then
                    return true
                end
            end
        end
    end
    return false
end
function AIVehicleUtil.getAttachedImplementsMaxTurnRadius(vehicle)
    local maxRadius = -1
    if vehicle.getAttachedImplements ~= nil then
        for _, implement in pairs(vehicle:getAttachedImplements()) do
            local object = implement.object
            if object ~= nil then
                local radius
                if object.getAITurnRadiusLimitation == nil then
                    radius = maxRadius
                else
                    radius = object:getAITurnRadiusLimitation()
                    if radius == nil then
                        radius = maxRadius
                    elseif maxRadius >= radius then
                        radius = maxRadius
                    end
                end
                maxRadius = AIVehicleUtil.getAttachedImplementsMaxTurnRadius(object)
                if radius >= maxRadius then
                    maxRadius = radius
                end
            end
        end
    end
    return maxRadius
end
function AIVehicleUtil.getAIToolReverserDirectionNode(vehicle)
    for _, implement in pairs(vehicle:getAttachedImplements()) do
        if implement.object ~= nil and implement.object.getAIToolReverserDirectionNode ~= nil then
            local reverserNode = implement.object:getAIToolReverserDirectionNode() or AIVehicleUtil.getAIToolReverserDirectionNode(implement.object)
            if reverserNode ~= nil then
                return reverserNode
            end
        end
    end
    return nil
end
function AIVehicleUtil.getMaxToolRadius(implement)
    local _, rotationNode, wheels, rotLimitFactor = implement.object:getAITurnRadiusLimitation()
    local retRadius = AIVehicleUtil.getAttachedImplementsMaxTurnRadius(implement.object.rootVehicle)
    local radius = retRadius == -1 and 0 or retRadius
    if rotationNode then
        local activeInputAttacherJoint = implement.object:getActiveInputAttacherJoint()
        for _, inputAttacherJoint in pairs(implement.object:getInputAttacherJoints()) do
            if rotationNode == inputAttacherJoint.node then
                rotationNode = activeInputAttacherJoint.node
                break
            end
        end
        local rx, _, rz = localToLocal(rotationNode, implement.object.components[1].node, 0, 0, 0)
        for _, wheel in pairs(wheels) do
            local nx, _, nz = localToLocal(wheel.repr, implement.object.components[1].node, 0, 0, 0)
            local rotMax = nil
            if rotationNode == activeInputAttacherJoint.node then
                local jointDesc = implement.object:getAttacherVehicle():getAttacherJointDescFromObject(implement.object)
                rotMax = math.max(jointDesc.upperRotLimit[2], jointDesc.lowerRotLimit[2]) * activeInputAttacherJoint.lowerRotLimitScale[2]
            else
                for _, compJoint in pairs(implement.object.componentJoints) do
                    if rotationNode == compJoint.jointNode then
                        rotMax = math.max(math.max(math.max(rotMax or 0, compJoint.rotLimit[1]) or 0, compJoint.rotLimit[2]) or 0, compJoint.rotLimit[3])
                        break
                    end
                end
            end
            if rotMax == nil then
                Logging.warning("AI rotation node \'%s\' could not be found as component joint or attacher joint on \'%s\'", getName(rotationNode), implement.object.configFileName)
            else
                local rotMax = rotMax * rotLimitFactor
                local attacherVehicle = (nx - rx) * math.cos(rotMax) - (nz - rz) * math.sin(rotMax)
                local jointDesc = x * math.sin(rotMax) + z * math.cos(rotMax)
                local dx = -jointDesc
                local _, dx
                if wheel.steering.steeringAxleScale == 0 or wheel.steering.steeringAxleRotMax == 0 then
                    _ = attacherVehicle
                else
                    dx = dx * math.cos(wheel.steering.steeringAxleRotMax) - attacherVehicle * math.sin(wheel.steering.steeringAxleRotMax)
                    _ = dx * math.sin(wheel.steering.steeringAxleRotMax) + attacherVehicle * math.cos(wheel.steering.steeringAxleRotMax)
                end
                local compJoint, tmpz, _ = MathUtil.getLineLineIntersection2D(0, 0, 1, 0, attacherVehicle, jointDesc, dx, _)
                if compJoint then
                    radius = math.max(radius, (math.abs(tmpz)))
                end
            end
        end
    end
    return radius
end
function AIVehicleUtil.updateInvertLeftRightMarkers(rootAttacherVehicle, vehicle)
    if vehicle.getAIMarkers ~= nil then
        local leftMarker, rightMarker, _ = vehicle:getAIMarkers()
        if leftMarker ~= nil and rightMarker ~= nil then
            local lX, _, _ = localToLocal(leftMarker, rootAttacherVehicle:getAIDirectionNode(), 0, 0, 0)
            local rX, _, _ = localToLocal(rightMarker, rootAttacherVehicle:getAIDirectionNode(), 0, 0, 0)
            if lX < rX then
                vehicle:setAIMarkersInverted()
            end
        end
    end
end
function AIVehicleUtil.getValidityOfTurnDirections(vehicle, turnData)
    local directionNode = vehicle:getAIDirectionNode()
    local attachedAIImplements = vehicle:getAttachedAIImplements()
    local leftAreaPercentage = 0
    local rightAreaPercentage = 0
    local minZ = math.huge
    local maxZ = -math.huge
    for _, implement in pairs(attachedAIImplements) do
        local leftMarker, rightMarker, backMarker = implement.object:getAIMarkers()
        local _, _, zl = localToLocal(leftMarker, directionNode, 0, 0, 0)
        local _, _, zr = localToLocal(rightMarker, directionNode, 0, 0, 0)
        local _, _, zb = localToLocal(backMarker, directionNode, 0, 0, 0)
        minZ = math.min(minZ, zl, zr, zb)
        maxZ = math.max(maxZ, zl, zr, zb)
    end
    local minAreaWidth
    if turnData == nil then
        minAreaWidth = math.huge
        for leftMarker, rightMarker in pairs(attachedAIImplements) do
            local backMarker, _, _ = rightMarker.object:getAIMarkers()
            local zl, _, _ = localToLocal(backMarker, directionNode, 0, 0, 0)
            local zr, _, _ = localToLocal(_, directionNode, 0, 0, 0)
            local rz = math.abs(zl - zr)
            minAreaWidth = math.min(minAreaWidth, rz)
        end
    else
        minAreaWidth = math.abs(turnData.sideOffsetRight - turnData.sideOffsetLeft)
    end
    local minAreaWidth = vehicle.aiDriveDirection[1]
    local dz = vehicle.aiDriveDirection[2]
    local _ = -dz
    for _, _ in pairs(attachedAIImplements) do
        local zl, _, _ = _.object:getAIMarkers()
        local zr, _, _ = localToLocal(zl, directionNode, 0, 0, 0)
        local zb, ry, rz = localToLocal(_, directionNode, 0, 0, 0)
        local width = math.abs(zr - zb)
        local lSX = 5 + (maxZ - minZ)
        local lWX = minAreaWidth * 1.3 + 2
        local length = lSX + math.max(lWX, 5)
        local lSX, lSZ, lWX = localToWorld(directionNode, zr, _, maxZ + 5)
        local lSX, lSZ, lWX = localToWorld(directionNode, zb, ry, maxZ + 5)
        local lWX = lSX - _ * width
        local lWZ = lWX - minAreaWidth * width
        local lHX = lSX - minAreaWidth * length
        local lHZ = lWX - dz * length
        local rWX = lSX + _ * width
        local rWZ = lWX + minAreaWidth * width
        local rHX = lSX - minAreaWidth * length
        local rHZ = lWX - dz * length
        local lArea, lTotal = AIVehicleUtil.getAIAreaOfVehicle(_.object, lSX, lWX, lWX, lWZ, lHX, lHZ)
        local rArea, rTotal = AIVehicleUtil.getAIAreaOfVehicle(_.object, lSX, lWX, rWX, rWZ, rHX, rHZ)
        if lTotal > 0 then
        end
        if rTotal > 0 then
        end
        if VehicleDebug.state == VehicleDebug.DEBUG_AI then
            local lSY = getTerrainHeightAtWorldPos(g_terrainNode, lSX, 0, lWX) + 2
            local lWY = getTerrainHeightAtWorldPos(g_terrainNode, lWX, 0, lWZ) + 2
            local lHY = getTerrainHeightAtWorldPos(g_terrainNode, lHX, 0, lHZ) + 2
            local rSY = getTerrainHeightAtWorldPos(g_terrainNode, lSX, 0, lWX) + 2
            local rWY = getTerrainHeightAtWorldPos(g_terrainNode, rWX, 0, rWZ) + 2
            vehicle:addAIDebugLine({ lSX, lSY, lWX }, { lWX, lWY, lWZ }, { 0.5, 0.5, 0.5 })
            vehicle:addAIDebugLine({ lSX, lSY, lWX }, { lHX, lHY, lHZ }, { 0.5, 0.5, 0.5 })
            vehicle:addAIDebugLine({ lSX, rSY, lWX }, { rWX, rWY, rWZ }, { 0.5, 0.5, 0.5 })
            vehicle:addAIDebugLine({ lSX, rSY, lWX }, { rHX, getTerrainHeightAtWorldPos(g_terrainNode, rHX, 0, rHZ) + 2, rHZ }, { 0.5, 0.5, 0.5 })
        end
    end
    return leftAreaPercentage / #attachedAIImplements, rightAreaPercentage / #attachedAIImplements
end
function AIVehicleUtil.checkImplementListForValidGround(vehicle, lookAheadDist, lookAheadSize)
    local validGroundFound = false
    for _, implement in pairs(vehicle:getAttachedAIImplements()) do
        local leftMarker, rightMarker, _ = implement.object:getAIMarkers()
        local lX, _, lZ = getWorldTranslation(leftMarker)
        local rX, _, rZ = getWorldTranslation(rightMarker)
        local lX = lX + vehicle.aiDriveDirection[1] * lookAheadDist
        local lZ = lZ + vehicle.aiDriveDirection[2] * lookAheadDist
        local rX = rX + vehicle.aiDriveDirection[1] * lookAheadDist
        local rZ = rZ + vehicle.aiDriveDirection[2] * lookAheadDist
        local hX = lX + vehicle.aiDriveDirection[1] * lookAheadSize
        local hZ = lZ + vehicle.aiDriveDirection[2] * lookAheadSize
        local area, areaTotal = AIVehicleUtil.getAIAreaOfVehicle(implement.object, lX, lZ, rX, rZ, hX, hZ)
        if VehicleDebug.state == VehicleDebug.DEBUG_AI then
            vehicle:addAIDebugText(string.format("area=%.1f areaTotal=%.1f", area, areaTotal))
            local lY = getTerrainHeightAtWorldPos(g_terrainNode, lX, 0, lZ) + 2
            vehicle:addAIDebugLine({ lX, lY, lZ }, { rX, getTerrainHeightAtWorldPos(g_terrainNode, rX, 0, rZ) + 2, rZ }, { 1, 0, 0 })
            vehicle:addAIDebugLine({ lX, lY, lZ }, { hX, getTerrainHeightAtWorldPos(g_terrainNode, hX, 0, hZ) + 2, hZ }, { 1, 0, 0 })
        end
        if not validGroundFound then
            validGroundFound = area > 0
        end
    end
    return validGroundFound
end
function AIVehicleUtil.getAreaDimensions(directionX, directionZ, leftNode, rightNode, xOffset, zOffset, areaSize, invertXOffset)
    local xOffsetLeft
    if invertXOffset == nil or invertXOffset then
        xOffsetLeft = -xOffset
    else
        xOffsetLeft = xOffset
    end
    local lX, _, lZ = localToWorld(leftNode, xOffsetLeft, 0, zOffset)
    local rX, _, rZ = localToWorld(rightNode, xOffset, 0, zOffset)
    return lX - 0.5 * directionX, lZ - 0.5 * directionZ, rX - 0.5 * directionX, rZ - 0.5 * directionZ, lX + areaSize * directionX, lZ + areaSize * directionZ
end
function AIVehicleUtil.getIsAreaOwned(vehicle, sX, sZ, wX, wZ, _, _)
    local farmId = vehicle:getAIJobFarmId()
    local centerX = (sX + wX) * 0.5
    local centerZ = (sZ + wZ) * 0.5
    return g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, centerX, centerZ) and true or (g_missionManager:getIsMissionWorkAllowed(farmId, centerX, centerZ, nil, vehicle) and true or false)
end
function AIVehicleUtil.getAIAreaOfVehicle(vehicle, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local useDensityHeightMap = #vehicle:getAIDensityHeightTypeRequirements() > 0
    if useDensityHeightMap then
        local query = vehicle:getAIDensityHeightTypeRequirements()
        return AIVehicleUtil.getAIDensityHeightArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, query)
    else
        local query, isValid = vehicle:getFieldCropsQuery()
        if isValid then
            return AIVehicleUtil.getAIFruitArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, query)
        else
            return 0, 0
        end
    end
end
function AIVehicleUtil.getAIFruitArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, query)
    local x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return query:getParallelogram(x, z, widthX, widthZ, heightX, heightZ, false)
end
function AIVehicleUtil.getAIDensityHeightArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, densityHeightTypeRequirements)
    local _, detailArea, _ = FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    if detailArea == 0 then
        return 0, 0
    end
    local retArea = 0
    local retTotalArea = 0
    for _, densityHeightTypeRequirement in pairs(densityHeightTypeRequirements) do
        if densityHeightTypeRequirement.fillType ~= FillType.UNKNOWN then
            local _, area
            _, area, retTotalArea = DensityMapHeightUtil.getFillLevelAtArea(densityHeightTypeRequirement.fillType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        end
    end
    return retArea, retTotalArea
end