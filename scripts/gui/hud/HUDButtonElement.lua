HUDButtonElement = {}
local HUDButtonElement_mt = Class(HUDButtonElement, HUDElement)
function HUDButtonElement.new(hud, posX, posY, parent, customMt)
    -- upvalues: (copy) HUDButtonElement_mt
    local uvsNormal = GuiUtils.getUVs(HUDButtonElement.UV.BUTTON_NORMAL)
    local sizeX, sizeY = getNormalizedScreenValues(unpack(HUDButtonElement.SIZE.BUTTON))
    Overlay.new(g_baseHUDFilename, posX, posY, sizeX, sizeY):setUVs(uvsNormal)
    local self = HUDElement.new(overlay, parent, customMt or HUDButtonElement_mt)
    self.hud = hud
    self.uvsNormal = uvsNormal
    self.uvsPressed = GuiUtils.getUVs(HUDButtonElement.UV.BUTTON_PRESSED)
    self.uvsDisabled = GuiUtils.getUVs(HUDButtonElement.UV.BUTTON_DISABLED)
    self.iconElement = nil
    self.touchAreas = {}
    self.isActive = true
    self.isPressed = false
    self.isDisabled = false
    return self
end
function HUDButtonElement:delete()
    self:removeTouchHandler()
    HUDButtonElement:superClass().delete(self)
end
function HUDButtonElement:setIconSlice(sliceId, sizeX, sizeY, offsetX, offsetY, color)
    local slice = g_overlayManager:getSliceInfoById(sliceId)
    self:setIcon(slice.filename, sizeX, sizeY, slice.uvs, offsetX, offsetY, color)
end
function HUDButtonElement:setIcon(filename, sizeX, sizeY, uvs, offsetX, offsetY, color)
    local posX, posY = self:getPosition()
    local width = self:getWidth()
    local height = self:getHeight()
    local iconPosX, iconPosX
    if self.iconElement == nil then
        iconPosX = sizeX or width
        iconPosX = sizeY or height
    else
        iconPosX = sizeX or self.iconElement:getWidth()
        iconPosX = sizeY or self.iconElement:getHeight()
    end
    local iconPosX = posX + (offsetX or (width - iconPosX) * 0.5)
    local iconOverlay
    if self.iconElement == nil then
        iconOverlay = Overlay.new(filename, iconPosX, posY + (offsetY or (height - iconPosX) * 0.5), iconPosX, iconPosX)
        self.iconElement = HUDElement.new(iconOverlay)
    elseif filename ~= nil then
        self.iconElement.overlay:setImage(filename)
    end
    if uvs ~= nil then
        iconOverlay:setUVs(uvs)
    end
    if color ~= nil then
        iconOverlay:setColor(unpack(color))
    end
    self:addChild(self.iconElement)
end
function HUDButtonElement:setIsPressed(isPressed)
    if self.isPressed ~= isPressed then
        self.isPressed = isPressed
        self:updateUVs()
    end
end
function HUDButtonElement:setDisabled(isDisabled)
    if self.isDisabled ~= isDisabled then
        self.isDisabled = isDisabled
        self:updateUVs()
        self:updateButtonState()
    end
end
function HUDButtonElement:updateUVs()
    if self.isDisabled then
        self:setUVs(self.uvsDisabled)
        return
    elseif self.isPressed then
        self:setUVs(self.uvsPressed)
    else
        self:setUVs(self.uvsNormal)
    end
end
function HUDButtonElement:addTouchHandler(callback, target)
    table.insert(self.touchAreas, self.hud:addTouchButton(self.overlay, 0.2, 0.2, function(_, x, y, isCancel)
        -- upvalues: (copy) callback, (copy) target
        if not isCancel then
            callback(target, x, y)
        end
    end, self, TouchHandler.TRIGGER_UP, { self }))
    table.insert(self.touchAreas, self.hud:addTouchButton(self.overlay, 0.2, 0.2, function(_)
        -- upvalues: (copy) self
        self:setIsPressed(true)
    end, self, TouchHandler.TRIGGER_DOWN))
    table.insert(self.touchAreas, self.hud:addTouchButton(self.overlay, 0.2, 0.2, function(_)
        -- upvalues: (copy) self
        self:setIsPressed(false)
    end, self, TouchHandler.TRIGGER_UP))
end
function HUDButtonElement:removeTouchHandler()
    for _, area in ipairs(self.touchAreas) do
        g_currentMission.hud:removeTouchButton(area)
    end
    self.touchAreas = {}
end
function HUDButtonElement:setAction(inputAction)
    if self.glyphElement ~= nil then
        self.glyphElement:delete()
        self.glyphElement = nil
    end
    if inputAction ~= nil then
        local baseX, baseY = self:getPosition()
        local offsetX, offsetY = getNormalizedScreenValues(unpack(HUDButtonElement.POSITION.INPUT_GLYPH_OFFSET))
        self.glyphElement = InputGlyphMobileElement.new(g_inputDisplayManager)
        self.glyphElement:setAction(inputAction)
        self.glyphElement:setButtonGlyphColor(HUDButtonElement.COLOR.INPUT_GLYPH)
        self.glyphElement:setPosition(baseX + offsetX, baseY + offsetY)
        self:addChild(self.glyphElement)
    end
end
function HUDButtonElement:setIsActive(isActive)
    self.isActive = isActive
    self:updateButtonState()
end
function HUDButtonElement:updateButtonState()
    local isActive = self.isActive and not self.isDisabled
    if isActive then
        isActive = self:getVisible()
    end
    for _, area in ipairs(self.touchAreas) do
        g_touchHandler:setTouchAreaVisibility(area, isActive)
    end
    if self.glyphElement ~= nil then
        self.glyphElement:setVisible(isActive)
    end
end
function HUDButtonElement:setVisible(isVisible)
    HUDButtonElement:superClass().setVisible(self, isVisible)
    self:updateButtonState()
end
HUDButtonElement.POSITION = {
    ["INPUT_GLYPH_OFFSET"] = { 123, 81 },
    ["INPUT_GLYPH_ICON_OFFSET"] = { -2, -1 }
}
HUDButtonElement.SIZE = {
    ["BUTTON"] = { 106, 106 },
    ["INPUT_GLYPH_BG_LEFT"] = { 46, 96 },
    ["INPUT_GLYPH_BG_MIDDLE"] = { 34, 96 },
    ["INPUT_GLYPH_BG_RIGHT"] = { 46, 96 },
    ["INPUT_GLYPH_ICON"] = { 48, 48 }
}
HUDButtonElement.UV = {
    ["BUTTON_NORMAL"] = {
        132,
        908,
        106,
        106
    },
    ["BUTTON_PRESSED"] = {
        238,
        908,
        106,
        106
    },
    ["BUTTON_DISABLED"] = {
        344,
        908,
        106,
        106
    },
    ["GLYPH_BG_LEFT"] = {
        288,
        432,
        46,
        96
    },
    ["GLYPH_BG_MIDDLE"] = {
        334,
        432,
        38,
        96
    },
    ["GLYPH_BG_RIGHT"] = {
        372,
        432,
        46,
        96
    }
}
HUDButtonElement.COLOR = {
    ["INPUT_GLYPH"] = {
        0,
        0,
        0,
        1
    }
}