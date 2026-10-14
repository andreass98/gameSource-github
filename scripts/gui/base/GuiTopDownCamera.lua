GuiTopDownCamera = {}
local GuiTopDownCamera_mt = Class(GuiTopDownCamera)
GuiTopDownCamera.TERRAIN_BORDER = 40
GuiTopDownCamera.INPUT_MOVE_FACTOR = 0.88
GuiTopDownCamera.MOVE_SPEED = 0.01
GuiTopDownCamera.MOVE_SPEED_FACTOR_NEAR = 1
GuiTopDownCamera.MOVE_SPEED_FACTOR_FAR = 64
GuiTopDownCamera.ROTATION_SPEED = 0.0005
GuiTopDownCamera.ROTATION_MIN_X_NEAR = 10
GuiTopDownCamera.ROTATION_MAX_X_NEAR = 90
GuiTopDownCamera.ROTATION_MIN_X_FAR = 50
GuiTopDownCamera.ROTATION_MAX_X_FAR = 90
GuiTopDownCamera.DISTANCE_MIN_Z = -10
GuiTopDownCamera.DISTANCE_RANGE_Z = -420
GuiTopDownCamera.GROUND_DISTANCE_MIN_Y = 2
GuiTopDownCamera.CAMERA_TERRAIN_OFFSET = 2
GuiTopDownCamera.CAMERA_ZOOM_FACTOR_MIN = 0.05
GuiTopDownCamera.CAMERA_ZOOM_FACTOR = 0.3
GuiTopDownCamera.COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TRIGGER - CollisionFlag.GROUND_TIP_BLOCKING - CollisionFlag.TERRAIN_DISPLACEMENT
function GuiTopDownCamera.new(subclass_mt)
    -- upvalues: (copy) GuiTopDownCamera_mt
    local self = setmetatable({}, subclass_mt or GuiTopDownCamera_mt)
    self.hud = nil
    self.terrainRootNode = nil
    self.terrainSize = 0
    self.previousCamera = nil
    self.camera, self.cameraBaseNode = self:createCameraNodes()
    g_cameraManager:addCamera(self.camera, nil, false)
    self.isActive = false
    self.cameraX = 0
    self.targetCameraX = 0
    self.cameraZ = 0
    self.targetCameraZ = 0
    self.cameraRotY = 0.7853981633974483
    self.targetRotation = self.cameraRotY
    self.isMouseEdgeScrollingActive = true
    self.isMouseMode = false
    self.mousePosX = 0.5
    self.mousePosY = 0.5
    self.tiltFactor = 0.5
    self.targetTiltFactor = 0.5
    self.zoomFactor = 0.3
    self.targetZoomFactor = 0.3
    self.isCatchingCursor = false
    self.lastActionFrame = 0
    self.inputZoom = 0
    self.inputMoveSide = 0
    self.inputMoveForward = 0
    self.inputRotate = 0
    self.inputTilt = 0
    self.eventMoveSide = nil
    self.eventMoveForward = nil
    self.movementDisabledForGamepad = false
    self.edgeScrollingOffset = {
        0,
        0,
        1,
        1
    }
    return self
end
function GuiTopDownCamera:createCameraNodes()
    local camera = createCamera("TopDownCamera", 1.0471975511965976, 1, 10000)
    local cameraBaseNode = createTransformGroup("topDownCameraBaseNode")
    link(cameraBaseNode, camera)
    setRotation(camera, 0, 3.141592653589793, 0)
    setTranslation(camera, 0, 0, -5)
    setRotation(cameraBaseNode, 0, 0, 0)
    setTranslation(cameraBaseNode, 0, 110, 0)
    setFastShadowUpdate(camera, true)
    return camera, cameraBaseNode
end
function GuiTopDownCamera:delete()
    if self.isActive then
        self:deactivate()
    end
    g_cameraManager:removeCamera(self.camera)
    delete(self.cameraBaseNode)
    self.camera = nil
    self.cameraBaseNode = nil
    self:reset()
end
function GuiTopDownCamera:reset()
    self.terrainRootNode = nil
    self.terrainSize = 0
    self.previousCamera = nil
    self.isCatchingCursor = false
end
function GuiTopDownCamera:setTerrainRootNode(terrainRootNode)
    self.terrainRootNode = terrainRootNode
    self.terrainSize = getTerrainSize(self.terrainRootNode)
end
function GuiTopDownCamera:activate()
    g_inputBinding:setShowMouseCursor(true)
    self:onInputModeChanged({ g_inputBinding:getLastInputMode() })
    self:updatePosition()
    self.previousCamera = g_cameraManager:getActiveCamera()
    g_cameraManager:setActiveCamera(self.camera)
    local x, _y, z = g_localPlayer:getPosition()
    self:setCameraPosition(x, z)
    self:registerActionEvents()
    g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
    self.isActive = true
end
function GuiTopDownCamera:deactivate()
    self.isActive = false
    g_messageCenter:unsubscribeAll(self)
    self:removeActionEvents()
    g_inputBinding:setShowMouseCursor(false)
    if self.previousCamera ~= nil then
        g_cameraManager:setActiveCamera(self.previousCamera)
    end
    self.previousCamera = nil
end
function GuiTopDownCamera:getIsActive()
    return self.isActive
end
function GuiTopDownCamera:setCameraPosition(mapX, mapZ)
    self.cameraX = mapX
    self.cameraZ = mapZ
    self.targetCameraX = mapX
    self.targetCameraZ = mapZ
    self:updatePosition()
end
function GuiTopDownCamera:determineMapPosition()
    return self.cameraX, 0, self.cameraZ, self.cameraRotY - 3.141592653589793, 0
end
function GuiTopDownCamera:getPickRay()
    return RaycastUtil.getCameraPickingRay(self.mousePosX, self.mousePosY, self.camera)
end
function GuiTopDownCamera:updatePosition()
    local cameraTargetHeight = 0
    local x = -2
    for x = x, 2, 2 do
        local z = -2
        for z = z, 2, 2 do
            local sampleTerrainHeight = getTerrainHeightAtWorldPos(self.terrainRootNode, self.cameraX + x, 0, self.cameraZ + z)
            cameraTargetHeight = math.max(cameraTargetHeight, sampleTerrainHeight)
        end
    end
    local cameraTargetHeight = cameraTargetHeight + GuiTopDownCamera.CAMERA_TERRAIN_OFFSET
    local rotMin = math.rad(GuiTopDownCamera.ROTATION_MIN_X_NEAR + (GuiTopDownCamera.ROTATION_MIN_X_FAR - GuiTopDownCamera.ROTATION_MIN_X_NEAR) * self.zoomFactor)
    local x = GuiTopDownCamera.ROTATION_MAX_X_NEAR + (GuiTopDownCamera.ROTATION_MAX_X_FAR - GuiTopDownCamera.ROTATION_MAX_X_NEAR) * self.zoomFactor
    local x = rotMin + (math.rad(x) - rotMin) * self.tiltFactor
    local cameraZ = GuiTopDownCamera.DISTANCE_MIN_Z + self.zoomFactor * GuiTopDownCamera.DISTANCE_RANGE_Z
    setTranslation(self.camera, 0, 0, cameraZ)
    setRotation(self.cameraBaseNode, x, self.cameraRotY, 0)
    setTranslation(self.cameraBaseNode, self.cameraX, cameraTargetHeight, self.cameraZ)
    local sampleTerrainHeight, z, cameraZ = getWorldTranslation(self.camera)
    local sampleTerrainHeight = 0
    local x = -2
    for x = x, 2, 2 do
        local z = -2
        for z = z, 2, 2 do
            local y = getTerrainHeightAtWorldPos(self.terrainRootNode, sampleTerrainHeight + x, 0, cameraZ + z)
            local hit, _, hitY, _ = RaycastUtil.raycastClosest(sampleTerrainHeight + x, y + 100, cameraZ + z, 0, -1, 0, 100, GuiTopDownCamera.COLLISION_MASK)
            if not hit then
                hitY = y
            end
            sampleTerrainHeight = math.max(sampleTerrainHeight, hitY)
        end
    end
    if z < sampleTerrainHeight + GuiTopDownCamera.GROUND_DISTANCE_MIN_Y then
        setTranslation(self.cameraBaseNode, self.cameraX, cameraTargetHeight + (sampleTerrainHeight - z + GuiTopDownCamera.GROUND_DISTANCE_MIN_Y), self.cameraZ)
    end
end
function GuiTopDownCamera:applyMovement(dt)
    local xChange = (self.targetCameraX - self.cameraX) / dt * 5
    if xChange < 0.0001 and xChange > -0.0001 then
        self.cameraX = self.targetCameraX
    else
        self.cameraX = self.cameraX + xChange
    end
    local zChange = (self.targetCameraZ - self.cameraZ) / dt * 5
    if zChange < 0.0001 and zChange > -0.0001 then
        self.cameraZ = self.targetCameraZ
    else
        self.cameraZ = self.cameraZ + zChange
    end
    local zoomChange = (self.targetZoomFactor - self.zoomFactor) / dt * 2
    if zoomChange < 0.0001 and zoomChange > -0.0001 then
        self.zoomFactor = self.targetZoomFactor
    else
        self.zoomFactor = math.clamp(self.zoomFactor + zoomChange, 0, 1)
    end
    local tiltChange = (self.targetTiltFactor - self.tiltFactor) / dt * 5
    if tiltChange < 0.0001 and tiltChange > -0.0001 then
        self.tiltFactor = self.targetTiltFactor
    else
        self.tiltFactor = math.clamp(self.tiltFactor + tiltChange, 0, 1)
    end
    local rotateChange = (self.targetRotation - self.cameraRotY) / dt * 5
    if rotateChange < 0.0001 and rotateChange > -0.0001 then
        self.cameraRotY = self.targetRotation
    else
        self.cameraRotY = self.cameraRotY + rotateChange
    end
end
function GuiTopDownCamera:setMouseEdgeScrollingActive(isActive)
    self.isMouseEdgeScrollingActive = isActive
end
function GuiTopDownCamera:setEdgeScrollingOffset(xMin, yMin, xMax, yMax)
    self.edgeScrollingOffset[1] = xMin or self.edgeScrollingOffset[1]
    self.edgeScrollingOffset[2] = yMin or self.edgeScrollingOffset[2]
    self.edgeScrollingOffset[3] = xMax or self.edgeScrollingOffset[3]
    self.edgeScrollingOffset[4] = yMax or self.edgeScrollingOffset[4]
end
function GuiTopDownCamera:getMouseEdgeScrollingMovement()
    local moveX = 0
    local moveZ = 0
    if self.mousePosX >= self.edgeScrollingOffset[3] - 0.015 and self.mousePosX <= self.edgeScrollingOffset[3] then
        moveX = math.min((0.015 - (self.edgeScrollingOffset[3] - self.mousePosX)) / 0.005000000000000001, 1)
    elseif self.mousePosX <= self.edgeScrollingOffset[1] + 0.02 and self.mousePosX >= self.edgeScrollingOffset[1] then
        moveX = -math.min((0.02 - self.edgeScrollingOffset[1] + self.mousePosX) / 0.005000000000000001, 1)
    end
    if self.mousePosY >= self.edgeScrollingOffset[4] - 0.015 and self.mousePosY <= self.edgeScrollingOffset[4] then
        return moveX, math.min((0.015 - (self.edgeScrollingOffset[4] - self.mousePosY)) / 0.005000000000000001, 1)
    else
        if self.mousePosY <= self.edgeScrollingOffset[2] + 0.02 and self.mousePosY >= self.edgeScrollingOffset[2] then
            moveZ = -math.min((0.02 - self.edgeScrollingOffset[2] + self.mousePosY) / 0.005000000000000001, 1)
        end
        return moveX, moveZ
    end
end
function GuiTopDownCamera:setMovementDisabledForGamepad(disabled)
    self.movementDisabledForGamepad = disabled
end
function GuiTopDownCamera:update(dt)
    if self.isActive and (self.isMouseMode or not self.movementDisabledForGamepad) then
        self:updateMovement(dt)
        self:resetInputState()
    end
end
function GuiTopDownCamera:updateMovement(dt)
    local moveZ = self.targetZoomFactor - self.inputZoom * 0.2
    self.targetZoomFactor = math.clamp(moveZ, 0, 1)
    self.targetRotation = self.targetRotation + dt * self.inputRotate * GuiTopDownCamera.ROTATION_SPEED
    local moveZ = self.targetTiltFactor + self.inputTilt * dt * GuiTopDownCamera.ROTATION_SPEED
    self.targetTiltFactor = math.clamp(moveZ, 0, 1)
    local moveX = self.inputMoveSide * dt
    local moveZ = -self.inputMoveForward * dt
    if moveX == 0 and (moveZ == 0 and self.isMouseEdgeScrollingActive) then
        moveX, moveZ = self:getMouseEdgeScrollingMovement()
    end
    local zoomMovementSpeedFactor = GuiTopDownCamera.MOVE_SPEED_FACTOR_NEAR + self.zoomFactor * (GuiTopDownCamera.MOVE_SPEED_FACTOR_FAR - GuiTopDownCamera.MOVE_SPEED_FACTOR_NEAR)
    local moveX = moveX * zoomMovementSpeedFactor
    local moveZ = moveZ * zoomMovementSpeedFactor
    local dirZ = math.sin(self.cameraRotY) * moveZ
    local dirX = dirZ + math.cos(self.cameraRotY) * -moveX
    local moveFactor = math.cos(self.cameraRotY) * moveZ
    local dirZ = moveFactor - math.sin(self.cameraRotY) * -moveX
    local moveFactor = dt * GuiTopDownCamera.MOVE_SPEED
    self.targetCameraX, self.targetCameraZ = g_currentMission.placeableSystem:limitPositionToBoundary(self.targetCameraX + dirX * moveFactor, self.targetCameraZ + dirZ * moveFactor)
    self:applyMovement(dt)
    self:updatePosition()
end
function GuiTopDownCamera:setCursorLocked(locked)
    self.cursorLocked = locked
end
function GuiTopDownCamera:mouseEvent(posX, posY, _, _, _)
    if self.lastActionFrame >= g_time or self.cursorLocked then
        return
    elseif self.isCatchingCursor then
        self.isCatchingCursor = false
        g_inputBinding:setShowMouseCursor(true)
        wrapMousePosition(0.5, 0.5)
        self.mousePosX = 0.5
        self.mousePosY = 0.5
    elseif self.isMouseMode then
        self.mousePosX = posX
        self.mousePosY = posY
    end
end
function GuiTopDownCamera:resetInputState()
    self.inputZoom = 0
    self.inputMoveSide = 0
    self.inputMoveForward = 0
    self.inputTilt = 0
    self.inputRotate = 0
end
function GuiTopDownCamera:registerActionEvents()
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_MOVE_SIDE_PLAYER, self, self.onMoveSide, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    self.eventMoveSide = eventId
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_MOVE_FORWARD_PLAYER, self, self.onMoveForward, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
    g_inputBinding:setActionEventTextVisibility(eventId, false)
    self.eventMoveForward = eventId
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_ZOOM, self, self.onZoom, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_ROTATE, self, self.onRotate, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_TILT, self, self.onTilt, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
end
function GuiTopDownCamera:removeActionEvents()
    g_inputBinding:removeActionEventsByTarget(self)
end
function GuiTopDownCamera:onZoom(_, inputValue, _, isAnalog, isMouse)
    if not (isMouse and self.mouseDisabled) then
        local change = math.max(GuiTopDownCamera.CAMERA_ZOOM_FACTOR * self.zoomFactor, GuiTopDownCamera.CAMERA_ZOOM_FACTOR_MIN) * inputValue
        if isAnalog then
        elseif isMouse then
        end
        self.inputZoom = change
    end
end
function GuiTopDownCamera:onMoveSide(_, inputValue)
    self.inputMoveSide = inputValue * GuiTopDownCamera.INPUT_MOVE_FACTOR / g_currentDt
end
function GuiTopDownCamera:onMoveForward(_, inputValue)
    self.inputMoveForward = inputValue * GuiTopDownCamera.INPUT_MOVE_FACTOR / g_currentDt
end
function GuiTopDownCamera:onRotate(_, inputValue, _, isAnalog, isMouse)
    if not (isMouse and self.mouseDisabled) then
        if isMouse and inputValue ~= 0 then
            self.lastActionFrame = g_time
            if not self.isCatchingCursor then
                g_inputBinding:setShowMouseCursor(false)
                self.isCatchingCursor = true
            end
        end
        if isMouse and isAnalog then
        end
        self.inputRotate = -inputValue * 3 / g_currentDt * 16
    end
end
function GuiTopDownCamera:onTilt(_, inputValue, _, isAnalog, isMouse)
    if not (isMouse and self.mouseDisabled) then
        if isMouse and inputValue ~= 0 then
            self.lastActionFrame = g_time
            if not self.isCatchingCursor then
                g_inputBinding:setShowMouseCursor(false)
                self.isCatchingCursor = true
            end
        end
        if isMouse and isAnalog then
        end
        self.inputTilt = inputValue * 3
    end
end
function GuiTopDownCamera:onInputModeChanged(inputMode)
    self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD
    if not self.isMouseMode then
        self.mousePosX = 0.5
        self.mousePosY = 0.5
    end
end