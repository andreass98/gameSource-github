ConstructionBrushSculpt = {}
local ConstructionBrushSculpt_mt = Class(ConstructionBrushSculpt, ConstructionBrush)
ConstructionBrushSculpt.MODE = {
    ["SHIFT"] = 1,
    ["LEVEL"] = 2,
    ["SOFTEN"] = 3,
    ["SLOPE"] = 4
}
ConstructionBrushSculpt.CURSOR_SIZES = {
    2,
    4,
    8,
    16,
    32
}
ConstructionBrushSculpt.CURSOR_STRENGTHS = {
    0.25,
    0.5,
    1,
    2,
    4
}
function ConstructionBrushSculpt.new(subclass_mt, cursor)
    -- upvalues: (copy) ConstructionBrushSculpt_mt
    local self = ConstructionBrushSculpt:superClass().new(subclass_mt or ConstructionBrushSculpt_mt, cursor)
    self.supportsPrimaryButton = true
    self.supportsPrimaryDragging = true
    self.supportsSecondaryButton = true
    self.supportsSecondaryDragging = true
    self.supportsTertiaryButton = true
    self.supportsPrimaryAxis = true
    self.supportsSecondaryAxis = true
    self.requiredPermission = Farm.PERMISSION.LANDSCAPING
    self.maxBrushRadius = ConstructionBrushSculpt.CURSOR_SIZES[#ConstructionBrushSculpt.CURSOR_SIZES] / 2
    self.maxBrushStrength = ConstructionBrushSculpt.CURSOR_STRENGTHS[#ConstructionBrushSculpt.CURSOR_STRENGTHS]
    self.smoothingDistance = 1
    return self
end
function ConstructionBrushSculpt:delete()
    ConstructionBrushSculpt:superClass().delete(self)
end
function ConstructionBrushSculpt:activate()
    ConstructionBrushSculpt:superClass().activate(self)
    self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE
    self.cursor:setRotationEnabled(false)
    self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
    self.cursor:setTerrainOnly(true)
    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SCULPTING)
    self.cursor:setCursorTerrainOffset(true)
    self.pendingSculptCallbacks = 0
    self:setBrushSize(2)
    self:setBrushStrength(1)
end
function ConstructionBrushSculpt:deactivate()
    self.cursor:setTerrainOnly(false)
    g_messageCenter:unsubscribe(LandscapingSculptEvent, self)
    ConstructionBrushSculpt:superClass().deactivate(self)
end
function ConstructionBrushSculpt:copyState(from)
    self:setBrushSize(from.cursorSizeIndex)
    self:setBrushStrength(from.cursorStrengthIndex)
    self.brushShape = from.brushShape
    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
    else
        self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
    end
end
function ConstructionBrushSculpt:setParameters(mode)
    self.mode = mode
end
function ConstructionBrushSculpt:setBrushSize(index)
    self.cursorSizeIndex = math.clamp(index, 2, #ConstructionBrushSculpt.CURSOR_SIZES)
    local size = ConstructionBrushSculpt.CURSOR_SIZES[self.cursorSizeIndex]
    self.brushRadius = size / 2
    self.cursor:setShapeSize(size)
end
function ConstructionBrushSculpt:setBrushStrength(index)
    self.cursorStrengthIndex = math.clamp(index, 1, #ConstructionBrushSculpt.CURSOR_STRENGTHS)
    self.brushStrength = ConstructionBrushSculpt.CURSOR_STRENGTHS[self.cursorStrengthIndex]
    local alpha = math.sqrt(self.brushStrength / ConstructionBrushSculpt.CURSOR_STRENGTHS[#ConstructionBrushSculpt.CURSOR_STRENGTHS]) * 0.8
    self.cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SCULPTING, alpha)
end
function ConstructionBrushSculpt:toggleBrushShape()
    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
        self.cursor:setShape(GuiTopDownCursor.SHAPES.SQUARE)
    else
        self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE
        self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
    end
end
function ConstructionBrushSculpt:update(dt)
    ConstructionBrushSculpt:superClass().update(self, dt)
    if self.showNoTargetHeightError then
        self.cursor:setErrorMessage(g_i18n:getText("ui_construction_noTargetHeightSet"))
        return
    elseif g_currentMission:getMoney() < Landscaping.SCULPT_BASE_COST_PER_M3 then
        self.cursor:setErrorMessage(g_i18n:getText("ui_construction_notEnoughMoney"))
        return
    elseif self.slopeAngle == nil then
        local x, y, z = self.cursor:getHitTerrainPosition()
        if x ~= nil then
            local err = self:verifyAccess(x, y, z)
            if err ~= nil then
                local message = g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[err])
                self.cursor:setErrorMessage(message)
            end
        end
    else
        self.cursor:setMessage(string.format("%d%%", self.slopeAngle * 100))
    end
end
function ConstructionBrushSculpt:onSculptCallback(_, _, _)
    self.pendingSculptCallbacks = self.pendingSculptCallbacks - 1
    if self.pendingSculptCallbacks == 0 then
        g_messageCenter:unsubscribe(LandscapingSculptEvent, self)
    end
end
function ConstructionBrushSculpt:shift(x, y, z, direction)
    local requestLandscaping = LandscapingSculptEvent.new(false, direction > 0 and Landscaping.OPERATION.RAISE or Landscaping.OPERATION.LOWER, x, y, z, nil, nil, nil, nil, nil, nil, self.brushRadius, self.brushStrength, self.brushShape, self.smoothingDistance)
    g_client:getServerConnection():sendEvent(requestLandscaping)
end
function ConstructionBrushSculpt:flatten(x, y, z)
    if self.flattenHeight == nil then
        self.flattenHeight = y
    end
    local requestLandscaping = LandscapingSculptEvent.new(false, Landscaping.OPERATION.FLATTEN, x, self.flattenHeight, z, nil, nil, nil, nil, nil, nil, self.brushRadius, self.brushStrength, self.brushShape, self.smoothingDistance)
    g_client:getServerConnection():sendEvent(requestLandscaping)
end
function ConstructionBrushSculpt:smooth(x, y, z)
    local requestLandscaping = LandscapingSculptEvent.new(false, Landscaping.OPERATION.SMOOTH, x, y, z, nil, nil, nil, nil, nil, nil, self.brushRadius, self.brushStrength * 2, self.brushShape, self.smoothingDistance)
    g_client:getServerConnection():sendEvent(requestLandscaping)
end
function ConstructionBrushSculpt:slope(x, y, z)
    if self.slopeTargetX == nil then
        self.showNoTargetHeightError = true
    else
        self.showNoTargetHeightError = false
        if self.slopeSourceX == nil then
            local x2 = self.slopeTargetX
            local y2 = self.slopeTargetY
            local z2 = self.slopeTargetZ
            if MathUtil.vector3Length(x2 - x, y2 - y, z2 - z) < 0.01 then
                return
            end
            self.slopeSourceX = x
            self.slopeSourceY = y
            self.slopeSourceZ = z
            local vx1, vy1, vz1 = MathUtil.vector3Normalize(x2 - x, y2 - y, z2 - z)
            local vz2 = MathUtil.vector2Length(x - x2, z - z2)
            local slope = (y - y2) / math.max(vz2, 1e-6)
            local vy2 = math.abs(slope)
            self.slopeAngle = math.clamp(vy2, 0, 1)
            local vx2, vy2, vz2 = MathUtil.vector3Normalize(-vz1, 0, vx1)
            local nx, ny, nz = MathUtil.crossProduct(vx2, vy2, vz2, vx1, vy1, vz1)
            self.slopeNX = nx
            self.slopeNY = ny
            self.slopeNZ = nz
            self.slopeD = -(nx * x + ny * y + nz * z)
            self.slopeMinY = math.min(y, y2)
            self.slopeMaxY = math.max(y, y2)
        end
        local x2 = LandscapingSculptEvent.new(false, Landscaping.OPERATION.SLOPE, x, y, z, self.slopeNX, self.slopeNY, self.slopeNZ, self.slopeD, self.slopeMinY, self.slopeMaxY, self.brushRadius, 5, self.brushShape, self.smoothingDistance)
        g_client:getServerConnection():sendEvent(x2)
    end
end
function ConstructionBrushSculpt:slopeSetTarget(x, y, z)
    self.slopeTargetX = x
    self.slopeTargetY = y
    self.slopeTargetZ = z
    self.slopeAngle = nil
    self.showNoTargetHeightError = false
end
function ConstructionBrushSculpt:onButtonPrimary(_, _, isUp)
    self:setActiveSound(ConstructionSound.ID.NONE)
    if isUp then
        self.flattenHeight = nil
        self.slopeSourceX = nil
        self.slopeSourceY = nil
        self.slopeSourceZ = nil
        self.showNoTargetHeightError = false
        self.slopeAngle = nil
        return
    else
        local x, y, z = self.cursor:getHitTerrainPosition()
        if x == nil then
            return
        elseif self:verifyAccess(x, y, z) == nil then
            if self.pendingSculptCallbacks == 0 then
                g_messageCenter:subscribe(LandscapingSculptEvent, self.onSculptCallback, self)
            end
            self.pendingSculptCallbacks = self.pendingSculptCallbacks + 1
            if self.mode == ConstructionBrushSculpt.MODE.SHIFT then
                self:shift(x, y, z, 1)
            elseif self.mode == ConstructionBrushSculpt.MODE.LEVEL then
                self:flatten(x, y, z)
            elseif self.mode == ConstructionBrushSculpt.MODE.SOFTEN then
                self:smooth(x, y, z)
            elseif self.mode == ConstructionBrushSculpt.MODE.SLOPE then
                self:slope(x, y, z)
            end
            self:setActiveSound(ConstructionSound.ID.SCULPT, 1 - self.brushRadius / self.maxBrushRadius * 0.75 - self.brushStrength / self.maxBrushStrength * 0.25)
        end
    end
end
function ConstructionBrushSculpt:onButtonSecondary(_, _, isUp)
    self:setActiveSound(ConstructionSound.ID.NONE)
    if isUp then
        return
    else
        local x, y, z = self.cursor:getHitTerrainPosition()
        if x == nil then
            return
        elseif self:verifyAccess(x, y, z) == nil then
            if self.mode == ConstructionBrushSculpt.MODE.SHIFT then
                self:shift(x, y, z, -1)
                self:setActiveSound(ConstructionSound.ID.SCULPT, 1 - self.brushRadius / self.maxBrushRadius * 0.75 - self.brushStrength / self.maxBrushStrength * 0.25)
            elseif self.mode == ConstructionBrushSculpt.MODE.SLOPE then
                self:slopeSetTarget(x, y, z)
            end
        else
            return
        end
    end
end
function ConstructionBrushSculpt:onButtonTertiary()
    self:toggleBrushShape()
end
function ConstructionBrushSculpt:onAxisPrimary(inputValue)
    self:setBrushSize(self.cursorSizeIndex + inputValue)
end
function ConstructionBrushSculpt:onAxisSecondary(inputValue)
    self:setBrushStrength(self.cursorStrengthIndex + inputValue)
end
function ConstructionBrushSculpt:getButtonPrimaryText()
    return self.mode == ConstructionBrushSculpt.MODE.SHIFT and "$l10n_input_CONSTRUCTION_SHIFT_UP" or (self.mode == ConstructionBrushSculpt.MODE.LEVEL and "$l10n_input_CONSTRUCTION_LEVEL" or (self.mode == ConstructionBrushSculpt.MODE.SOFTEN and "$l10n_input_CONSTRUCTION_SOFTEN" or (self.mode == ConstructionBrushSculpt.MODE.SLOPE and "$l10n_input_CONSTRUCTION_SLOPE" or nil)))
end
function ConstructionBrushSculpt:getButtonSecondaryText()
    if self.mode == ConstructionBrushSculpt.MODE.SHIFT then
        return "$l10n_input_CONSTRUCTION_SHIFT_DOWN"
    elseif self.mode == ConstructionBrushSculpt.MODE.LEVEL then
        return nil
    elseif self.mode == ConstructionBrushSculpt.MODE.SOFTEN then
        return nil
    else
        return self.mode == ConstructionBrushSculpt.MODE.SLOPE and "$l10n_input_CONSTRUCTION_SLOPE_START" or nil
    end
end
function ConstructionBrushSculpt:getAxisPrimaryText()
    return "$l10n_input_CONSTRUCTION_BRUSH_SIZE"
end
function ConstructionBrushSculpt:getAxisSecondaryText()
    return "$l10n_input_CONSTRUCTION_BRUSH_STRENGTH"
end
function ConstructionBrushSculpt:getButtonTertiaryText()
    return "$l10n_input_CONSTRUCTION_BRUSH_SHAPE"
end