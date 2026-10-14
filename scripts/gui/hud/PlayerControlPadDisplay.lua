local data = nil
if PlayerControlPadDisplay ~= nil then
    local old = g_currentMission.hud.playerControlPadDisplay
    data = {
        ["player"] = old.player,
        ["hud"] = old.hud,
        ["uiScale"] = old.uiScale,
        ["hudAtlasPath"] = old.hudAtlasPath
    }
    old:delete()
end
PlayerControlPadDisplay = {}
local old = Class(PlayerControlPadDisplay, HUDDisplayElement)
function PlayerControlPadDisplay.new(hud, hudAtlasPath)
    -- upvalues: (copy) old
    local backgroundOverlay = PlayerControlPadDisplay.createBackground()
    local self = PlayerControlPadDisplay:superClass().new(backgroundOverlay, nil, old)
    self.hud = hud
    self.uiScale = 1
    self.hudAtlasPath = hudAtlasPath
    self.player = nil
    self.joystickPosX = 0.5
    self.joystickPosY = 0.5
    self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
    self:createComponents()
    return self
end
function PlayerControlPadDisplay:setPlayer(player)
    self.player = player
    self:updateVisibilityState()
end
function PlayerControlPadDisplay:createComponents()
    local baseX, baseY = self:getPosition()
    local bgSizeX, bgSizeY = getNormalizedScreenValues(unpack(PlayerControlPadDisplay.SIZE.BACKGROUND))
    Overlay.new(self.hudAtlasPath, baseX, baseY, bgSizeX, bgSizeY):setUVs(GuiUtils.getUVs(PlayerControlPadDisplay.UV.BACKGROUND))
    self.backgroundHudElement = HUDElement.new(backgroundOverlay)
    self:addChild(self.backgroundHudElement)
    self.uvs = GuiUtils.getUVs(PlayerControlPadDisplay.UV.JOYSTICK)
    self.uvsDisabled = GuiUtils.getUVs(PlayerControlPadDisplay.UV.JOYSTICK_DISABLED)
    local joySizeX, joySizeY = getNormalizedScreenValues(unpack(PlayerControlPadDisplay.SIZE.JOYSTICK))
    Overlay.new(self.hudAtlasPath, baseX + joySizeX * 0.5, baseY + joySizeY * 0.5, joySizeX, joySizeY):setUVs(self.uvs)
    self.joystickElement = HUDElement.new(joystickOverlay)
    self:addChild(self.joystickElement)
    local joystickOverlayX = Overlay.new(nil, baseX + joySizeX * 0.5, baseY + joySizeY * 0.5, joySizeX, joySizeY)
    local joystickOverlayY = Overlay.new(nil, baseX + joySizeX * 0.5, baseY + joySizeY * 0.5, joySizeX, joySizeY)
    self.joystickXHudElement = HUDSliderElement.new(joystickOverlayX, backgroundOverlay, 1, 1, 20, 1, 0, 0.5, 1, nil)
    self.joystickXHudElement:setCallback(self.onSliderPositionChangedX, self)
    self.joystickXHudElement.radius = bgSizeX / 2
    self:addChild(self.joystickXHudElement)
    self.joystickYHudElement = HUDSliderElement.new(joystickOverlayY, backgroundOverlay, 1, 1, 20, 2, 0, 0.5, 1, nil)
    self.joystickYHudElement:setCallback(self.onSliderPositionChangedY, self)
    self.joystickYHudElement.radius = bgSizeY / 2
    self:addChild(self.joystickYHudElement)
    self:updateSliderTranslations(1)
    self.joystickXHudElement:setAxisPosition(self.joystickXHudElement.centerTrans)
    self.joystickYHudElement:setAxisPosition(self.joystickYHudElement.centerTrans)
end
function PlayerControlPadDisplay:updateSliderTranslations(uiScale)
    local width = self:getWidth()
    local height = self:getHeight()
    local joySizeX, joySizeY = getNormalizedScreenValues(unpack(PlayerControlPadDisplay.SIZE.JOYSTICK))
    local joySizeYHalf = joySizeY * 0.5 * uiScale
    self.joystickXHudElement:setRange(-(joySizeX * 0.5 * uiScale), width * 0.5 - joySizeXHalf, width - joySizeXHalf, nil)
    self.joystickXHudElement.radius = width * 0.5
    self.joystickYHudElement:setRange(-joySizeYHalf, height * 0.5 - joySizeYHalf, height - joySizeYHalf, nil)
    self.joystickYHudElement.radius = height * 0.5
end
function PlayerControlPadDisplay:setVisible(isVisible, animate)
    if not isVisible or g_inputBinding:getInputHelpMode() ~= GS_INPUT_HELP_MODE_GAMEPAD then
        PlayerControlPadDisplay:superClass().setVisible(self, isVisible, animate)
    end
end
function PlayerControlPadDisplay:onSliderPositionChangedX(position)
    self.joystickPosX = position * 2 - 1
    local posX, _ = self:updateJoystickPosition()
    self.joystickElement:setPosition(posX, nil)
    return posX
end
function PlayerControlPadDisplay:onSliderPositionChangedY(position)
    self.joystickPosY = position * 2 - 1
    local _, posY = self:updateJoystickPosition()
    return posY
end
function PlayerControlPadDisplay:updateJoystickPosition()
    local distance = math.sqrt(self.joystickPosX ^ 2 + self.joystickPosY ^ 2)
    if distance <= 1 then
        return nil
    end
    self.joystickPosX = self.joystickPosX / distance
    self.joystickXHudElement:setAxisPosition(self.joystickXHudElement.minTrans + (self.joystickXHudElement.maxTrans - self.joystickXHudElement.minTrans) * (self.joystickPosX / 2 + 0.5), true)
    self.joystickPosY = self.joystickPosY / distance
    local posY = self.joystickYHudElement.minTrans + (self.joystickYHudElement.maxTrans - self.joystickYHudElement.minTrans) * (self.joystickPosY / 2 + 0.5)
    self.joystickYHudElement:setAxisPosition(posY, true)
    return posX, posY
end
function PlayerControlPadDisplay:onInputHelpModeChange(inputHelpMode)
    self.lastInputHelpMode = inputHelpMode
    self:updateVisibilityState()
end
function PlayerControlPadDisplay:updateVisibilityState()
    local animationState = self:getIsPlayerMoveActive()
    if animationState ~= self.animationState then
        self:setVisible(animationState, true)
        self.joystickXHudElement:setTouchIsActive(animationState)
        self.joystickYHudElement:setTouchIsActive(animationState)
    end
end
function PlayerControlPadDisplay:update(dt)
    PlayerControlPadDisplay:superClass().update(self, dt)
    self.joystickElement:setUVs(self.uvs)
    local posX, _ = self.joystickXHudElement:getPosition()
    local _, posY = self.joystickYHudElement:getPosition()
    self.joystickElement:setPosition(posX, posY)
    if self.player ~= nil then
        if self.joystickXHudElement ~= nil and self.joystickYHudElement ~= nil then
            self.joystickXHudElement:update(dt)
            self.joystickYHudElement:update(dt)
        end
        self.player:onInputMoveSide(nil, self.joystickPosX, nil, nil, false)
        self.player:onInputMoveForward(nil, -self.joystickPosY, nil, nil, false)
    end
end
function PlayerControlPadDisplay:onAnimateVisibilityFinished(isVisible)
    PlayerControlPadDisplay:superClass().onAnimateVisibilityFinished(self, isVisible)
    if isVisible then
        self.joystickXHudElement:resetSlider()
        self.joystickYHudElement:resetSlider()
    end
end
function PlayerControlPadDisplay:getIsPlayerMoveActive()
    if g_inputBinding:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD then
        return false
    elseif Platform.hasTouchSliders then
        return self.player ~= nil
    else
        return false
    end
end
function PlayerControlPadDisplay:setScale(uiScale)
    PlayerControlPadDisplay:superClass().setScale(self, uiScale, uiScale)
    local currentVisibility = self:getVisible()
    self:setVisible(true, false)
    self.uiScale = uiScale
    local posX, posY = PlayerControlPadDisplay.getBackgroundPosition(uiScale, self:getWidth())
    self:setPosition(posX, posY)
    self:storeOriginalPosition()
    self:setVisible(currentVisibility, false)
    self:updateVisibilityState()
    self:updateSliderTranslations(uiScale)
end
function PlayerControlPadDisplay.getBackgroundPosition(scale, _)
    local offX, offY = getNormalizedScreenValues(unpack(PlayerControlPadDisplay.POSITION.BACKGROUND))
    return offX * scale, offY * scale
end
function PlayerControlPadDisplay.createBackground()
    local width, height = getNormalizedScreenValues(unpack(PlayerControlPadDisplay.SIZE.BACKGROUND))
    local posX, posY = PlayerControlPadDisplay.getBackgroundPosition(1, width)
    return Overlay.new(nil, posX, posY, width, height)
end
PlayerControlPadDisplay.SIZE = {
    ["BACKGROUND"] = { 264, 264 },
    ["JOYSTICK"] = { 174, 174 }
}
PlayerControlPadDisplay.POSITION = {
    ["BACKGROUND"] = { 100, 50 },
    ["HIDE_OFFSET"] = { 0, -250 }
}
PlayerControlPadDisplay.UV = {
    ["BACKGROUND"] = {
        624,
        432,
        264,
        264
    },
    ["JOYSTICK"] = {
        194,
        670,
        174,
        174
    },
    ["JOYSTICK_DISABLED"] = {
        370,
        670,
        174,
        174
    }
}
PlayerControlPadDisplay.COLOR = {
    ["BACKGROUND"] = {
        1,
        1,
        1,
        0.5
    }
}
if data ~= nil then
    local playerControlPadDisplay = PlayerControlPadDisplay.new(data.hud, data.hudAtlasPath)
    playerControlPadDisplay:setScale(data.uiScale)
    playerControlPadDisplay:setPlayer(data.player)
    for k, elem in ipairs(g_currentMission.hud.displayComponents) do
        if elem == g_currentMission.hud.playerControlPadDisplay then
            g_currentMission.hud.displayComponents[k] = playerControlPadDisplay
            break
        end
    end
    g_currentMission.hud.playerControlPadDisplay = playerControlPadDisplay
    Logging.info("Reloaded")
end