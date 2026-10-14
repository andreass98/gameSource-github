PlayerCamera = {}
local PlayerCamera_mt = Class(PlayerCamera)
PlayerCamera.FIRST_PERSON_Y_OFFSET = 1.75
PlayerCamera.THIRD_PERSON_BASE_Y_OFFSET = 1.6
PlayerCamera.DEFAULT_ZOOM = 5
PlayerCamera.MINIMUM_ZOOM = 1
PlayerCamera.MAXIMUM_ZOOM = 10
PlayerCamera.TARGET_DISTANCE_OFFSET = 0.75
PlayerCamera.COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.WATER
PlayerCamera.LOWEST_PITCH = -1.3962634015954636
PlayerCamera.HIGHEST_PITCH = 1.4835298641951802
PlayerCamera.ROLL_BOBBING = 0
PlayerCamera.HORIZONTAL_BOBBING = 0
PlayerCamera.VERTICAL_BOBBING = 0
PlayerCamera.MAXIMUM_BOBBING_OSCILLATION = 0
PlayerCamera.BOBBING_OSCILLATION_RANDOMNESS = 0
function PlayerCamera.new(player)
    -- upvalues: (copy) PlayerCamera_mt
    local self = setmetatable({}, PlayerCamera_mt)
    self.player = player
    self.isFirstPerson = true
    self.isSwitchingLocked = false
    self.isCollisionEnabled = true
    self.noClipCollisionMask = PlayerCamera.COLLISION_MASK
    self.lastCollisionDistance = nil
    self.lastDistanceOffset = nil
    self.yawNode = nil
    self.pitchNode = nil
    self.cameraRootNode = nil
    self.offsetY = 0
    self.startPositionX = nil
    self.startPositionY = nil
    self.startPositionZ = nil
    self.startRotationX = nil
    self.startRotationY = nil
    self.startRotationZ = nil
    self.startRotationW = nil
    self.targetPositionX = nil
    self.targetPositionY = nil
    self.targetPositionZ = nil
    self.targetRotationX = nil
    self.targetRotationY = nil
    self.targetRotationZ = nil
    self.targetRotationW = nil
    self.overrideTransitionStartTime = nil
    self.overrideTransitionDuration = nil
    self.lastBobOffsetX = 0
    self.lastBobOffsetY = 0
    self.desiredZoomDistance = PlayerCamera.DEFAULT_ZOOM
    self.currentZoomDistance = self.desiredZoomDistance
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON], self.onFovySettingChanged, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON], self.onFovySettingChanged, self)
    return self
end
function PlayerCamera:initialise()
    self:initialiseCameraNodes()
end
function PlayerCamera:initialiseCameraNodes()
    self.yawNode = createTransformGroup("cameraYawNode")
    self.pitchNode = createTransformGroup("cameraPitchNode")
    self.cameraRootNode = createTransformGroup("cameraRootNode")
    self.firstPersonCamera = createCamera("playerCameraFirstPerson", g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON), 0.15, 6000)
    link(self.cameraRootNode, self.firstPersonCamera)
    local dofInfoFirstPerson = g_depthOfFieldManager:createInfo(0.8, 0.5, 0, 1000, 1400, false)
    g_cameraManager:addCamera(self.firstPersonCamera, nil, false, nil, dofInfoFirstPerson)
    self.thirdPersonCamera = createCamera("playerCameraThirdPerson", g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON), 0.15, 6000)
    link(self.cameraRootNode, self.thirdPersonCamera)
    local dofInfo = g_depthOfFieldManager:createInfo(0.5, 4, 0.3, 30, 200, false)
    g_cameraManager:addCamera(self.thirdPersonCamera, nil, false, nil, dofInfo)
    self.thirdPersonConversationCamera = createCamera("playerCameraThirdPersonConversation", g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON), 0.15, 6000)
    link(self.cameraRootNode, self.thirdPersonConversationCamera)
    local dofInfoConversation = g_depthOfFieldManager:createInfo(0.75, 2, 0.75, 2, 7, false)
    g_cameraManager:addCamera(self.thirdPersonConversationCamera, nil, false, nil, dofInfoConversation)
    link(getRootNode(), self.yawNode)
    link(self.yawNode, self.pitchNode)
    link(self.pitchNode, self.cameraRootNode)
    setRotation(self.cameraRootNode, 0, 3.141592653589793, 0)
    self:zoomSmoothly(0)
    self:setCurrentZoomDistance(self.desiredZoomDistance)
    self:applyZoom(g_currentDt)
end
function PlayerCamera:onPlayerLoad()
    self.player.toggleNoClipCommand.onEnabled:registerListener(function(disableTerrainCollision)
        -- upvalues: (copy) self
        local newCollision = Utils.stringToBoolean(disableTerrainCollision) and 0 or CollisionFlag.TERRAIN
        self.noClipCollisionMask = newCollision
    end)
end
function PlayerCamera:delete()
    if self.firstPersonCamera ~= nil then
        g_cameraManager:removeCamera(self.firstPersonCamera)
    end
    if self.thirdPersonCamera ~= nil then
        g_cameraManager:removeCamera(self.thirdPersonCamera)
    end
    if self.thirdPersonConversationCamera ~= nil then
        g_cameraManager:removeCamera(self.thirdPersonConversationCamera)
    end
    if self.yawNode ~= nil then
        delete(self.yawNode)
        self.yawNode = nil
    end
    g_messageCenter:unsubscribeAll(self)
end
function PlayerCamera:makeCurrent()
    if self.isFirstPerson then
        g_cameraManager:setActiveCamera(self.firstPersonCamera)
        return
    elseif self.isInConversation then
        g_cameraManager:setActiveCamera(self.thirdPersonConversationCamera)
    else
        g_cameraManager:setActiveCamera(self.thirdPersonCamera)
    end
end
function PlayerCamera:toggleThirdPersonMode()
    self:switchToPerspective(not self.isFirstPerson)
end
function PlayerCamera:setIsInConversation(isInConversation)
    if not (self.isFirstPerson or self.isSwitchingLocked) then
        self.isInConversation = isInConversation
        self:makeCurrent()
    end
end
function PlayerCamera:getCurrentCameraNode()
    if self.isFirstPerson then
        return self.firstPersonCamera
    elseif self.isInConversation then
        return self.thirdPersonConversationCamera
    else
        return self.thirdPersonCamera
    end
end
function PlayerCamera:switchToPerspective(isFirstPerson)
    if isFirstPerson then
        self:switchToFirstPersonMode()
    else
        self:switchToThirdPersonMode()
    end
end
function PlayerCamera:switchToThirdPersonMode()
    if self.isFirstPerson and not self.isSwitchingLocked then
        self.isFirstPerson = false
        self:makeCurrent()
        self:setCurrentZoomDistance(self.desiredZoomDistance)
        local pitch, yaw = self:getRotation()
        self:setRotation(pitch, yaw, 0)
        self.player:onPerspectiveSwitched(self.isFirstPerson)
    end
end
function PlayerCamera:lockThirdPersonMode()
    self:switchToThirdPersonMode()
    self:lockSwitching()
end
function PlayerCamera:switchToFirstPersonMode()
    if not (self.isFirstPerson or self.isSwitchingLocked) then
        self.isFirstPerson = true
        self:makeCurrent()
        if self:getHasOverriddenTarget() then
            self:clearTargetOverride()
        end
        self:setRotation(0, self.player:getGraphicalYaw(), 0)
        self:setCurrentZoomDistance(0, true)
        self.lastBobOffsetX = 0
        self.lastBobOffsetY = 0
        self.player:onPerspectiveSwitched(self.isFirstPerson)
    end
end
function PlayerCamera:lockFirstPersonMode()
    self:switchToFirstPersonMode()
    self:lockSwitching()
end
function PlayerCamera:getIsSwitchingLocked()
    return self.isSwitchingLocked
end
function PlayerCamera:lockSwitching()
    self.isSwitchingLocked = true
end
function PlayerCamera:unlockSwitching()
    self.isSwitchingLocked = false
end
function PlayerCamera:getCollisionMask()
    if self:getIsCollisionEnabled() then
        if self.player.toggleNoClipCommand == nil or not self.player.toggleNoClipCommand.value then
            if self.player.mover.currentWaterSubmergeDistance > 0 then
                return CollisionFlag.TERRAIN + CollisionFlag.CAMERA_BLOCKING
            else
                return CollisionFlag.TERRAIN + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.WATER
            end
        else
            return self.noClipCollisionMask
        end
    else
        return 0
    end
end
function PlayerCamera:getIsCollisionEnabled()
    return self.isCollisionEnabled
end
function PlayerCamera:setIsCollisionEnabled(isCollisionEnabled)
    self.isCollisionEnabled = isCollisionEnabled
end
function PlayerCamera:getIsTerrainCorrectionEnabled()
    return bit32.band(CollisionFlag.TERRAIN, self:getCollisionMask()) ~= 0
end
function PlayerCamera:getHasOverriddenTarget()
    return self.targetPositionX ~= nil and self.overrideTransitionDuration ~= nil
end
function PlayerCamera:getBaseOffsetY()
    if self.isFirstPerson then
        return PlayerCamera.FIRST_PERSON_Y_OFFSET
    else
        return PlayerCamera.THIRD_PERSON_BASE_Y_OFFSET
    end
end
function PlayerCamera:getOffsetY()
    return self.offsetY
end
function PlayerCamera:setOffsetY(offsetY)
    self.offsetY = offsetY or 0
end
function PlayerCamera:getCurrentZoomDistance()
    return self.currentZoomDistance
end
function PlayerCamera:setCurrentZoomDistance(zoomDistance, _)
    self.currentZoomDistance = zoomDistance
    setTranslation(self.cameraRootNode, 0, 0, -self.currentZoomDistance)
end
function PlayerCamera:getDesiredZoomDistance()
    return self.isFirstPerson and 0 or self.desiredZoomDistance
end
function PlayerCamera:getFocusRotation()
    local cameraLookX, _, cameraLookZ = localDirectionToWorld(self.yawNode, 0, 0, 1)
    local _, cameraLookY, _ = localDirectionToWorld(self.pitchNode, 0, 0, 1)
    local pitch, yaw, _ = MathUtil.vector3Normalize(cameraLookX, cameraLookY, cameraLookZ)
    local pitch, yaw = MathUtil.directionToPitchYaw(pitch, yaw, _)
    local _, _, roll = getRotation(self.cameraRootNode)
    return pitch, yaw, roll
end
function PlayerCamera:getFocusPosition()
    return getWorldTranslation(self.yawNode)
end
function PlayerCamera:setFocusPosition(x, y, z)
    setWorldTranslation(self.yawNode, x, y, z)
end
function PlayerCamera:setTargetOverrideFromNode(node, transitionDuration)
    if self.isFirstPerson then
        if self:getHasOverriddenTarget() then
            self:clearTargetOverride()
        end
    else
        self.targetPositionX, self.targetPositionY, self.targetPositionZ = getWorldTranslation(node)
        self.targetRotationX, self.targetRotationY, self.targetRotationZ, self.targetRotationW = getWorldQuaternion(node)
        if transitionDuration ~= nil then
            self.overrideTransitionStartTime = g_time
            self.overrideTransitionDuration = transitionDuration
            self.startPositionX, self.startPositionY, self.startPositionZ = self:getCameraPosition()
            self.startRotationX, self.startRotationY, self.startRotationZ, self.startRotationW = getWorldQuaternion(self.cameraRootNode)
            if transitionDuration == 0 then
                self:updateRotationFromTarget()
                self:updatePositionFromTarget()
            end
        end
    end
end
function PlayerCamera:clearTargetOverride()
    self.startPositionX = nil
    self.startPositionY = nil
    self.startPositionZ = nil
    self.startRotationX = nil
    self.startRotationY = nil
    self.startRotationZ = nil
    self.startRotationW = nil
    self.targetPositionX = nil
    self.targetPositionY = nil
    self.targetPositionZ = nil
    self.targetRotationX = nil
    self.targetRotationY = nil
    self.targetRotationZ = nil
    self.targetRotationW = nil
    self.overrideTransitionStartTime = nil
    self.overrideTransitionDuration = nil
    self:setCurrentZoomDistance(self:getCurrentZoomDistance())
end
function PlayerCamera:getCameraPosition()
    return getWorldTranslation(self.cameraRootNode)
end
function PlayerCamera:getRotation()
    local cameraLookX, cameraLookY, cameraLookZ = localDirectionToWorld(self.cameraRootNode, 0, 0, -1)
    local pitch, yaw = MathUtil.directionToPitchYaw(cameraLookX, cameraLookY, cameraLookZ)
    local _, _, roll = getRotation(self.cameraRootNode)
    return pitch, yaw, roll
end
function PlayerCamera:setRotation(pitch, yaw, roll)
    setRotation(self.pitchNode, pitch or 0, 0, 0)
    setRotation(self.yawNode, 0, yaw or 0, 0)
    setRotation(self.cameraRootNode, 0, 3.141592653589793, roll or 0)
end
function PlayerCamera:calculateWorldDirection(directionX, directionZ)
    local worldDirectionX, _, worldDirectionZ = localDirectionToWorld(self.yawNode, directionX, 0, directionZ)
    return worldDirectionX, worldDirectionZ
end
function PlayerCamera:calculateLocalDirection(directionX, directionZ)
    local localDirectionX, _, localDirectionZ = worldDirectionToLocal(self.yawNode, directionX, 0, directionZ)
    return localDirectionX, localDirectionZ
end
function PlayerCamera:zoomSmoothly(offset)
    if not self.isFirstPerson then
        self.desiredZoomDistance = math.clamp(self.desiredZoomDistance + offset, self.MINIMUM_ZOOM, self.MAXIMUM_ZOOM)
    end
end
function PlayerCamera:updateRotation(_)
    if self:getHasOverriddenTarget() then
        self:updateRotationFromTarget()
    else
        local cameraSensitivity = g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
        local cameraPitch, cameraYaw, cameraRoll = self:getRotation()
        self:setRotation(math.clamp(cameraPitch + self.player.inputComponent.cameraRotationX * cameraSensitivity, PlayerCamera.LOWEST_PITCH, PlayerCamera.HIGHEST_PITCH), MathUtil.getValidLimit(cameraYaw + -self.player.inputComponent.cameraRotationY * cameraSensitivity), cameraRoll)
    end
end
function PlayerCamera:updatePosition(dt)
    if self:getHasOverriddenTarget() then
        self:updatePositionFromTarget()
    else
        self:focusOnPlayer()
        self:tryApplyViewBobbing(dt)
        self:applyZoom(dt)
    end
end
function PlayerCamera:focusOnPlayer()
    local currentX, currentY, currentZ = self.player:getGraphicalPosition()
    self:focusOnPosition(currentX, currentY, currentZ)
end
function PlayerCamera:updatePositionFromTarget()
    if self:getHasOverriddenTarget() then
        local alpha = self.overrideTransitionDuration == 0 and 1 or (g_time - self.overrideTransitionStartTime) / self.overrideTransitionDuration
        local currentPositionX, currentPositionY, currentPositionZ
        if alpha >= 1 then
            currentPositionX = self.targetPositionX
            currentPositionY = self.targetPositionY
            currentPositionZ = self.targetPositionZ
        else
            currentPositionX, currentPositionY, currentPositionZ = MathUtil.vector3Lerp(self.startPositionX, self.startPositionY, self.startPositionZ, self.targetPositionX, self.targetPositionY, self.targetPositionZ, alpha)
        end
        setTranslation(self.cameraRootNode, 0, 0, 0)
        setWorldTranslation(self.yawNode, currentPositionX, currentPositionY, currentPositionZ)
    end
end
function PlayerCamera:updateRotationFromTarget()
    if self:getHasOverriddenTarget() then
        local alpha = self.overrideTransitionDuration == 0 and 1 or (g_time - self.overrideTransitionStartTime) / self.overrideTransitionDuration
        local currentRotationX, currentRotationY, currentRotationZ, currentRotationW
        if alpha >= 1 then
            currentRotationX = self.targetRotationX
            currentRotationY = self.targetRotationY
            currentRotationZ = self.targetRotationZ
            currentRotationW = self.targetRotationW
        else
            currentRotationX, currentRotationY, currentRotationZ, currentRotationW = MathUtil.nlerpQuaternionShortestPath(self.startRotationX, self.startRotationY, self.startRotationZ, self.startRotationW, self.targetRotationX, self.targetRotationY, self.targetRotationZ, self.targetRotationW, alpha)
        end
        setWorldQuaternion(self.cameraRootNode, currentRotationX, currentRotationY, currentRotationZ, currentRotationW)
        local pitch, yaw = self:getRotation()
        self:setRotation(pitch, yaw, 0)
    end
end
function PlayerCamera:focusOnPosition(x, y, z)
    local baseOffsetY = self:getBaseOffsetY()
    self:setFocusPosition(x, y + self.offsetY + baseOffsetY, z)
end
function PlayerCamera:tryApplyViewBobbing(_)
    if self.isFirstPerson then
        if g_gameSettings:getValue(GameSettings.SETTING.CAMERA_BOBBING) then
            if self.player.mover.currentSpeed <= 10 then
                local targetBobOffsetX = 0
                local targetBobOffsetY = 0
                local bobRoll = 0
                local randomOffsetX = self.player.mover.currentSpeed
                local isMoving = math.abs(randomOffsetX) >= PlayerMover.SMALL_SPEED_THRESHOLD
                if isMoving and self.player.mover.isGrounded then
                    local roundedSpeed = MathUtil.round(self.player.mover.currentSpeed)
                    local randomOffsetX = math.random(-self.BOBBING_OSCILLATION_RANDOMNESS, self.BOBBING_OSCILLATION_RANDOMNESS)
                    local oscillationX = math.sin(g_time * 0.001 * roundedSpeed)
                    bobRoll = oscillationX * PlayerCamera.ROLL_BOBBING
                    targetBobOffsetX = oscillationX * self.HORIZONTAL_BOBBING
                    targetBobOffsetY = math.sin((oscillationX + randomOffsetX + 0.5) * 3.141592653589793) * self.VERTICAL_BOBBING
                end
                local oscillationX = self.HORIZONTAL_BOBBING * self.MAXIMUM_BOBBING_OSCILLATION
                local oscillationY = self.VERTICAL_BOBBING * self.MAXIMUM_BOBBING_OSCILLATION
                local currentPitch
                if self.lastBobOffsetX < targetBobOffsetX then
                    currentPitch = math.min(self.lastBobOffsetX + oscillationX, targetBobOffsetX)
                else
                    currentPitch = math.max(self.lastBobOffsetX - oscillationX, targetBobOffsetX)
                end
                local currentPitch
                if self.lastBobOffsetY < targetBobOffsetY then
                    currentPitch = math.min(self.lastBobOffsetY + oscillationY, targetBobOffsetY)
                else
                    currentPitch = math.max(self.lastBobOffsetY - oscillationY, targetBobOffsetY)
                end
                setTranslation(self.cameraRootNode, currentPitch, currentPitch, 0)
                local currentPitch, currentYaw = self:getRotation()
                self:setRotation(currentPitch, currentYaw, bobRoll)
                self.lastBobOffsetX = currentPitch
                self.lastBobOffsetY = currentPitch
            end
        else
            setTranslation(self.cameraRootNode, 0, 0, 0)
            return
        end
    else
        setTranslation(self.cameraRootNode, 0, 0, -self.currentZoomDistance)
        return
    end
end
function PlayerCamera:applyZoom(dt)
    if self.isFirstPerson then
        return
    else
        self:applyTerrainHeightCorrection()
        local targetZoomDistance, snapToDistance = self:calculateCollisionZoom()
        if snapToDistance then
            self:setCurrentZoomDistance(targetZoomDistance)
        elseif self.currentZoomDistance ~= targetZoomDistance then
            self:setCurrentZoomDistance(targetZoomDistance + math.pow(0.99579, dt) * (self.currentZoomDistance - targetZoomDistance))
        end
    end
end
function PlayerCamera:applyTerrainHeightCorrection()
    if self:getIsTerrainCorrectionEnabled() then
        for i = 1, 4 do
            local cameraPositionX, cameraPositionY, cameraPositionZ = self:getCameraPosition()
            local _, focusPositionY, _ = self:getFocusPosition()
            local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, cameraPositionX, cameraPositionY, cameraPositionZ)
            local waterHeight = g_currentMission.environmentAreaSystem:getWaterYAtWorldPosition(cameraPositionX, cameraPositionY + 15, cameraPositionZ)
            if waterHeight ~= nil then
                terrainHeight = math.max(waterHeight, terrainHeight)
            end
            local minimumHeight = terrainHeight + 0.2
            if minimumHeight <= cameraPositionY then
                return
            end
            local newPitch = (minimumHeight - focusPositionY) / self:getCurrentZoomDistance()
            local pitchSine = math.clamp(newPitch, -1, 1)
            local newPitch = math.clamp(math.asin(pitchSine), PlayerCamera.LOWEST_PITCH, PlayerCamera.HIGHEST_PITCH)
            local _, currentYaw, currentRoll = self:getRotation()
            self:setRotation(newPitch, currentYaw, currentRoll)
        end
    end
end
function PlayerCamera:calculateCollisionZoom()
    if not self:getIsCollisionEnabled() then
        return self.desiredZoomDistance, false
    end
    local originX, originY, originZ = self:getFocusPosition()
    local directionX, directionY, directionZ = localDirectionToWorld(self.cameraRootNode, 0, 0, 1)
    raycastClosestAsync(originX, originY, originZ, directionX, directionY, directionZ, self.desiredZoomDistance, "distanceRaycastCallback", self, self:getCollisionMask())
    if self.lastCollisionDistance == nil then
        return self.desiredZoomDistance, false
    end
    local currentZoomDistance = self:getCurrentZoomDistance()
    local snapToDistance = self.desiredZoomDistance
    local newZoomDistance = math.min(snapToDistance, self.lastCollisionDistance - self.lastDistanceOffset)
    local snapToDistance = true
    if newZoomDistance >= currentZoomDistance then
        snapToDistance = math.abs(currentZoomDistance - newZoomDistance) <= 0.025
    end
    return newZoomDistance, snapToDistance
end
function PlayerCamera:distanceRaycastCallback(nodeId, _, _, _, distance, nx, ny, nz, _, _, _)
    if nodeId == nil or nodeId == 0 then
        self.lastCollisionDistance = nil
        self.lastDistanceOffset = nil
    else
        self.lastCollisionDistance = distance
        local rayDirectionX, rayDirectionY, rayDirectionZ = localDirectionToWorld(self.cameraRootNode, 0, 0, 1)
        local dotProduct = MathUtil.dotProduct(nx, ny, nz, rayDirectionX, rayDirectionY, rayDirectionZ)
        local absoluteDotProduct = math.abs(dotProduct)
        self.lastDistanceOffset = MathUtil.lerp(0.4, 0.1, absoluteDotProduct * absoluteDotProduct * (3 - 2 * absoluteDotProduct))
    end
end
function PlayerCamera:onFovySettingChanged()
    if self.firstPersonCamera ~= nil then
        setFovY(self.firstPersonCamera, g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON))
    end
    if self.thirdPersonCamera ~= nil then
        setFovY(self.thirdPersonCamera, g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
    end
    if self.thirdPersonConversationCamera ~= nil then
        setFovY(self.thirdPersonConversationCamera, g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
    end
end
function PlayerCamera:debugDraw(x, y, textSize)
    local originX = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Camera", nil, true)
    local originX, originY, originZ = self:getFocusPosition()
    local rotationX = DebugUtil.renderTextLine(x, originX, textSize, string.format("Focus position: %.2fm, %.2fm, %.2fm", originX, originY, originZ))
    local rotationX = DebugUtil.renderTextLine(x, rotationX, textSize, string.format("Current zoom: %.2fm", self.currentZoomDistance))
    local rotationX = DebugUtil.renderTextLine(x, rotationX, textSize, string.format("Current offset: %.2fm", self.lastDistanceOffset or 0))
    local rotationX = DebugUtil.renderTextLine(x, rotationX, textSize, string.format("Collision distance: %.2fm", self.lastCollisionDistance or 0))
    local rotationX, rotationY, rotationZ = self:getRotation()
    y = DebugUtil.renderTextLine(x, rotationX, textSize, string.format("Pitch: %.2f\194\176, Yaw: %.2f\194\176, Roll: %.2f\194\176", math.deg(rotationX), math.deg(rotationY), (math.deg(rotationZ))))
    DebugUtil.drawDebugNode(self.yawNode, "yaw")
    return y
end