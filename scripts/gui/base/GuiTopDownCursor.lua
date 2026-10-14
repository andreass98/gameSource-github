GuiTopDownCursor = {}
local GuiTopDownCursor_mt = Class(GuiTopDownCursor)
GuiTopDownCursor.ROTATION_SPEED = 0.002
GuiTopDownCursor.SHAPES_FILENAME = "data/shared/assets/constructionCursorSimple.i3d"
GuiTopDownCursor.RAYCAST_DISTANCE = -2 * GuiTopDownCamera.DISTANCE_RANGE_Z
GuiTopDownCursor.SNAP_STATE_INACTIVE = 0
GuiTopDownCursor.SNAP_STATE_POSITIVE = 1
GuiTopDownCursor.SNAP_STATE_NEGATIVE = 2
GuiTopDownCursor.SNAP_STATE_USED = 3
GuiTopDownCursor.SHAPES = {
    ["NONE"] = 0,
    ["CIRCLE"] = 1,
    ["SQUARE"] = 2
}
GuiTopDownCursor.SHAPES_COLORS = {
    ["SUCCESS"] = 0,
    ["ERROR"] = 1,
    ["SCULPTING"] = 2,
    ["SELECT"] = 3,
    ["PAINTING"] = 4
}
GuiTopDownCursor.RAYCAST_COLLISION_MASK_DEFAULT = bit32.bor(CollisionFlag.TERRAIN, CollisionFlag.TERRAIN_DELTA, CollisionFlag.STATIC_OBJECT, CollisionFlag.BUILDING, CollisionFlag.ROAD)
function GuiTopDownCursor.new(subclass_mt)
    -- upvalues: (copy) GuiTopDownCursor_mt
    local self = setmetatable({}, subclass_mt or GuiTopDownCursor_mt)
    self.isActive = false
    self.ray = {}
    self.cursorShapeHeights = {
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    }
    self.isVisible = true
    self.rotationY = 0
    self.targetRotation = 0
    self.inputRotate = 0
    self.lastActionFrame = 0
    self.isCatchingCursor = false
    self.shapeScale = 1
    self.rotationEnabled = false
    self.lightEnabled = false
    self.selectionMode = false
    self.rayCollisionMask = GuiTopDownCursor.RAYCAST_COLLISION_MASK_DEFAULT
    self:setTerrainOnly(false)
    self.shapesLoaded = false
    self.snapAngle = nil
    self.snapUpdateState = GuiTopDownCursor.SNAP_STATE_INACTIVE
    return self
end
function GuiTopDownCursor:delete()
    if self.isActive then
        self:deactivate()
    end
    if self.cursorOverlay ~= nil then
        self.cursorOverlay:delete()
        self.cursorOverlay = nil
    end
    if self.rootNode ~= nil then
        delete(self.rootNode)
    end
    if self.loadRequestId ~= nil then
        g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
        self.loadRequestId = nil
    end
end
function GuiTopDownCursor:loadShapes()
    if self.loadRequestId == nil then
        self.loadRequestId = g_i3DManager:loadI3DFileAsync(GuiTopDownCursor.SHAPES_FILENAME, false, false, self.onLoadedI3D, self, nil)
    end
end
function GuiTopDownCursor:onLoadedI3D(nodeId, failedReason, _)
    self.loadRequestId = nil
    if failedReason == LoadI3DFailedReason.NONE then
        self.rootNode = createTransformGroup("topDownCursorRootNode")
        link(getRootNode(), self.rootNode)
        self.shapeNode = getChildAt(nodeId, 0)
        link(self.rootNode, self.shapeNode)
        delete(nodeId)
        setScale(self.shapeNode, self.shapeScale, self.shapeScale, self.shapeScale)
        setVisibility(self.rootNode, false)
        setWorldRotation(self.rootNode, 0, self.rotationY, 0)
        self:setShape(GuiTopDownCursor.SHAPES.NONE)
        self:setShapeSize(1)
        self:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SELECT)
        self:setCursorTerrainOffset(false)
        self.shapesLoaded = true
        local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
        local width, height = getNormalizedScreenValues(20 * uiScale, 20 * uiScale)
        self.cursorOverlay = g_overlayManager:createOverlay("gui.whiteCircleFat", 0.5, 0.5, width, height)
        self.cursorOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
        self.cursorOverlay:setColor(1, 1, 1, 0.3)
        setVisibility(self.rootNode, self.isVisible)
    end
end
function GuiTopDownCursor:activate()
    self.isActive = true
    self:onInputModeChanged({ g_inputBinding:getLastInputMode() })
    if not self.shapesLoaded then
        self:loadShapes()
    end
    if self.rootNode ~= nil then
        setVisibility(self.rootNode, self.isVisible)
    end
    self:registerActionEvents()
    g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
end
function GuiTopDownCursor:deactivate()
    if self.rootNode ~= nil then
        setVisibility(self.rootNode, false)
    end
    g_messageCenter:unsubscribeAll(self)
    self:removeActionEvents()
    self.isActive = false
end
function GuiTopDownCursor:setCameraRay(x, y, z, dx, dy, dz)
    local ray = self.ray
    ray.x = x
    ray.y = y
    ray.z = z
    ray.dx = dx
    ray.dy = dy
    ray.dz = dz
end
function GuiTopDownCursor:setShape(shape)
    self.shape = shape
    if self.shapeNode ~= nil then
        local material = setVisibility
        material(self.shapeNode, shape ~= GuiTopDownCursor.SHAPES.NONE)
        local material = getMaterial(self.shapeNode, 0)
        if shape == GuiTopDownCursor.SHAPES.CIRCLE then
            setMaterialCustomShaderVariation(material, "circle", true)
            return
        end
        if shape == GuiTopDownCursor.SHAPES.SQUARE then
            setMaterialCustomShaderVariation(material, "square", true)
        end
    end
end
function GuiTopDownCursor:setVisible(isVisible)
    self.isVisible = isVisible
    if self.rootNode ~= nil then
        setVisibility(self.rootNode, isVisible)
    end
end
function GuiTopDownCursor:setIsWaterDetectionActive(isActive)
    if isActive then
        self.rayCollisionMask = bit32.bor(self.rayCollisionMask, CollisionFlag.WATER)
    else
        self.rayCollisionMask = bit32.band(self.rayCollisionMask, (bit32.bnot(CollisionFlag.WATER)))
    end
end
function GuiTopDownCursor:setTerrainOnly(terrainOnly)
    self.hitTerrainOnly = terrainOnly
    if terrainOnly then
        self.rayCollisionMask = CollisionFlag.TERRAIN
    else
        self.rayCollisionMask = GuiTopDownCursor.RAYCAST_COLLISION_MASK_DEFAULT
    end
end
function GuiTopDownCursor:setSelectionMode(isSelection)
    self.selectionMode = isSelection
    if isSelection then
        self.rayCollisionMask = CollisionMask.ALL - CollisionFlag.TRIGGER - CollisionFlag.FILLABLE - CollisionFlag.TERRAIN_DISPLACEMENT
    else
        self.rayCollisionMask = GuiTopDownCursor.RAYCAST_COLLISION_MASK_DEFAULT
    end
end
function GuiTopDownCursor:setRotationEnabled(isEnabled)
    if self.rotationEnabled ~= isEnabled then
        self.rotationEnabled = isEnabled
        if self.rotateEventId ~= nil then
            g_inputBinding:setActionEventActive(self.rotateEventId, self.rotationEnabled)
        end
    end
end
function GuiTopDownCursor:setRotation(rotY)
    self.targetRotation = rotY
    self.rotationY = rotY
end
function GuiTopDownCursor:setLightEnabled(isEnabled)
    self.lightEnabled = isEnabled
end
function GuiTopDownCursor:setShapeSize(size)
    if self.shapeNode ~= nil then
        setScale(self.shapeNode, size, size, size)
    end
    self.shapeScale = size
end
function GuiTopDownCursor:getMessagePosition()
    if self.isCatchingCursor then
        return self.lockedMousePosX, self.lockedMousePosY
    else
        return self.mousePosX, self.mousePosY
    end
end
function GuiTopDownCursor:setErrorMessage(message)
    local x, y = self:getMessagePosition()
    if x ~= nil then
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
        local textSize = getCorrectTextSize(0.016)
        local x = x + 0.01
        setTextColor(0, 0, 0, 0.75)
        renderText(x, y - 0.0015, textSize, message)
        setTextColor(1, 0.5, 0.5, 1)
        renderText(x, y, textSize, message)
        setTextColor(1, 1, 1, 1)
    end
end
function GuiTopDownCursor:setMessage(message)
    local x, y = self:getMessagePosition()
    if x ~= nil then
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(false)
        local textSize = getCorrectTextSize(0.016)
        local y = y + 0.01
        setTextColor(0, 0, 0, 0.75)
        renderText(x, y - 0.0015, textSize, message)
        setTextColor(1, 1, 1, 1)
        renderText(x, y, textSize, message)
        setTextColor(1, 1, 1, 1)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end
function GuiTopDownCursor:setColor(r, g, b, a)
    if self.shapeNode ~= nil then
        setShaderParameter(self.shapeNode, "colorInside", r, g, b, a, true)
        setShaderParameter(self.shapeNode, "colorOutside", r, g, b, 1, true)
    end
end
function GuiTopDownCursor:setGradientColor(ri, gi, bi, ro, go, bo, a)
    if self.shapeNode ~= nil then
        setShaderParameter(self.shapeNode, "colorInside", ri, gi, bi, a, true)
        setShaderParameter(self.shapeNode, "colorOutside", ro, go, bo, 1, true)
    end
end
function GuiTopDownCursor:setColorMode(mode, alpha)
    alpha = alpha == nil and 0.3 or alpha
    if mode == GuiTopDownCursor.SHAPES_COLORS.SUCCESS then
        self:setColor(0, 1, 0, alpha)
        return
    elseif mode == GuiTopDownCursor.SHAPES_COLORS.ERROR then
        self:setColor(1, 0, 0, alpha)
        return
    elseif mode == GuiTopDownCursor.SHAPES_COLORS.SCULPTING then
        self:setGradientColor(1, 0, 0, 0, 1, 0, alpha)
        return
    elseif mode == GuiTopDownCursor.SHAPES_COLORS.SELECT then
        self:setColor(1, 1, 1, alpha)
    elseif mode == GuiTopDownCursor.SHAPES_COLORS.PAINTING then
        self:setColor(1, 1, 1, 0.25)
    end
end
function GuiTopDownCursor:setCursorTerrainOffset(isLarge)
    if isLarge then
        self.terrainBrushOffset = 0.5
    else
        self.terrainBrushOffset = 0.05
    end
end
function GuiTopDownCursor:setSnapAngle(angle)
    self.snapAngle = angle
    self.snapUpdateState = GuiTopDownCursor.SNAP_STATE_INACTIVE
end
function GuiTopDownCursor:getHitNode()
    if self.currentHitId == g_terrainNode then
        return nil
    else
        return self.currentHitId
    end
end
function GuiTopDownCursor:getHitPlaceable()
    if self.currentHitId == nil or self.currentHitId == g_terrainNode then
        return nil
    else
        local object = g_currentMission:getNodeObject(self.currentHitId)
        if object == nil or not object:isa(Placeable) then
            return nil
        else
            return object
        end
    end
end
function GuiTopDownCursor:getHitObject()
    if self.currentHitId == nil or self.currentHitId == g_terrainNode then
        return nil
    else
        return g_currentMission:getNodeObject(self.currentHitId)
    end
end
function GuiTopDownCursor:getHitTerrainPosition()
    if self.currentHitId == g_terrainNode then
        return self.currentHitX, self.currentHitY, self.currentHitZ
    else
        return nil, nil, nil
    end
end
function GuiTopDownCursor:getRotation()
    return self.rotationY % 6.283185307179586
end
function GuiTopDownCursor:getPosition()
    return self.currentHitX, self.currentHitY, self.currentHitZ
end
function GuiTopDownCursor:update(dt)
    if self.isActive then
        self:updateRaycast()
        self:updateRotation(dt)
    end
end
function GuiTopDownCursor:draw()
    if self.cursorOverlay ~= nil then
        if not self.isMouseMode and self.selectionMode then
            self.cursorOverlay:render()
        end
    end
end
function GuiTopDownCursor:updateRaycast()
    local ray = self.ray
    local cursorShouldBeVisible = false
    if ray.x == nil then
        self.currentHitId = nil
    else
        local id, x, y, z = RaycastUtil.raycastClosest(ray.x, ray.y, ray.z, ray.dx, ray.dy, ray.dz, GuiTopDownCursor.RAYCAST_DISTANCE, self.rayCollisionMask)
        self.currentHitId = id
        self.currentHitX = x
        self.currentHitY = y
        self.currentHitZ = z
        cursorShouldBeVisible = self:setPosition(x, y, z)
    end
    self:setVisible(cursorShouldBeVisible)
end
function GuiTopDownCursor:setPosition(x, y, z)
    local cursorShouldBeVisible = false
    if self.currentHitId ~= nil and x ~= nil then
        if self.rootNode ~= nil then
            setWorldTranslation(self.rootNode, x, y, z)
        end
        if self.shapeNode ~= nil then
            cursorShouldBeVisible = not self.hitTerrainOnly
            if not cursorShouldBeVisible then
                cursorShouldBeVisible = g_terrainNode == self.currentHitId
            end
            if cursorShouldBeVisible and getVisibility(self.shapeNode) then
                self:updateCursorHeights(x, y, z, self.shapeScale)
            end
        end
    end
    return cursorShouldBeVisible
end
function GuiTopDownCursor:updateRotation(dt)
    self.inputRotate = 0
    if self.snapAngle ~= nil then
        if self.snapUpdateState == GuiTopDownCursor.SNAP_STATE_USED then
            return
        end
        if self.snapUpdateState == GuiTopDownCursor.SNAP_STATE_POSITIVE or self.snapUpdateState == GuiTopDownCursor.SNAP_STATE_NEGATIVE then
            self:setRotation(math.rad((MathUtil.snapValue(math.deg(self.rotationY + (self.snapUpdateState == GuiTopDownCursor.SNAP_STATE_POSITIVE and 1 or -1) * self.snapAngle), (math.deg(self.snapAngle))))) % 6.283185307179586)
            self.snapUpdateState = GuiTopDownCursor.SNAP_STATE_USED
            return
        end
    end
    self.targetRotation = self.targetRotation - dt * self.inputRotate * GuiTopDownCursor.ROTATION_SPEED
    local dir = (self.targetRotation - self.rotationY) / dt * 5
    if dir < 0.0001 and dir > -0.0001 then
        self.rotationY = self.targetRotation
    else
        self.rotationY = self.rotationY + dir
    end
    if self.snapAngle ~= nil then
        self.rotationY = math.rad((MathUtil.snapValue(math.deg(self.rotationY), (math.deg(self.snapAngle)))))
    end
end
function GuiTopDownCursor:updateCursorHeights(x, y, z, scale)
    if self.shapeNode ~= nil then
        local i = 1
        for i = i, 8 do
            local j = 1
            for j = j, 8 do
                self.cursorShapeHeights[j] = getTerrainHeightAtWorldPos(g_terrainNode, x + (0.14285714285714285 * (j - 1) - 0.5) * scale, 0, z + (0.14285714285714285 * (i - 1) - 0.5) * scale) + (self.terrainBrushOffset - y)
            end
            setShaderParameter(self.shapeNode, "heights" .. math.ceil(i / 2) .. ((i - 1) % 2 + 1) * 2 - 1, h[1], h[2], h[3], h[4], true)
            setShaderParameter(self.shapeNode, "heights" .. row .. col * 2, h[5], h[6], h[7], h[8], true)
        end
    end
end
function GuiTopDownCursor:registerActionEvents()
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CURSOR_ROTATE, self, self.onRotate, false, false, true, false)
    self.rotateEventId = eventId
    g_inputBinding:setActionEventActive(self.rotateEventId, self.rotationEnabled)
    g_inputBinding:setActionEventTextPriority(self.rotateEventId, GS_PRIO_NORMAL)
end
function GuiTopDownCursor:removeActionEvents()
    self.rotateEventId = nil
    g_inputBinding:removeActionEventsByTarget(self)
end
function GuiTopDownCursor:mouseEvent(posX, posY, _, _, _)
    if self.mouseDisabled then
        return
    elseif self.lastActionFrame >= g_time then
        return
    elseif self.isCatchingCursor then
        self.isCatchingCursor = false
        g_inputBinding:setShowMouseCursor(true, true)
        wrapMousePosition(self.lockedMousePosX, self.lockedMousePosY)
        g_inputBinding.mousePosXLast = self.lockedMousePosX
        g_inputBinding.mousePosYLast = self.lockedMousePosY
        self.mousePosX = self.lockedMousePosX
        self.mousePosY = self.lockedMousePosY
    elseif self.isMouseMode then
        self.mousePosX = posX
        self.mousePosY = posY
    end
end
function GuiTopDownCursor:onRotate(_, inputValue, _, isAnalog, isMouse, _, binding)
    if not (isMouse and self.mouseDisabled) then
        if isMouse then
            self.lastActionFrame = g_time
            if not self.isCatchingCursor then
                self.lockedMousePosX = g_inputBinding.mousePosXLast or 0.5
                self.lockedMousePosY = g_inputBinding.mousePosYLast or 0.5
                g_inputBinding:setShowMouseCursor(false, true)
                self.isCatchingCursor = true
            end
            if isAnalog then
            end
            self.snapUpdateState = GuiTopDownCursor.SNAP_STATE_INACTIVE
        elseif self.snapAngle ~= nil then
            if binding.isUpFlank then
                self.snapUpdateState = GuiTopDownCursor.SNAP_STATE_INACTIVE
            elseif self.snapUpdateState == GuiTopDownCursor.SNAP_STATE_INACTIVE and binding.isDownFlank then
                self.snapUpdateState = inputValue > 0 and GuiTopDownCursor.SNAP_STATE_POSITIVE or GuiTopDownCursor.SNAP_STATE_NEGATIVE
            end
        end
        self.inputRotate = inputValue
    end
end
function GuiTopDownCursor:onInputModeChanged(inputMode)
    self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD
    if not self.isMouseMode then
        self.mousePosX = 0.5
        self.mousePosY = 0.5
    end
end