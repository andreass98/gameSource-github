local data = nil
if SwitchVehicleDisplay ~= nil then
    local old = g_currentMission.hud.switchVehicleDisplay
    data = {
        ["vehicle"] = old.vehicle,
        ["player"] = old.player,
        ["hud"] = old.hud,
        ["uiScale"] = old.uiScale,
        ["hudAtlasPath"] = old.hudAtlasPath,
        ["controlHudAtlasPath"] = old.controlHudAtlasPath,
        ["lastGyroscopeSteeringState"] = old.lastGyroscopeSteeringState
    }
    old:delete()
end
SwitchVehicleDisplay = {}
SwitchVehicleDisplay.MOVE_ANIMATION_DURATION = 500
SwitchVehicleDisplay.STATE_TOUCH = 0
SwitchVehicleDisplay.STATE_CONTROLLER = 1
local old = Class(SwitchVehicleDisplay, HUDDisplayElement)
function SwitchVehicleDisplay.new(hud, hudAtlasPath, controlHudAtlasPath)
    -- upvalues: (copy) old
    local backgroundOverlay = SwitchVehicleDisplay.createBackground()
    local self = SwitchVehicleDisplay:superClass().new(backgroundOverlay, nil, old)
    self.hud = hud
    self.uiScale = 1
    self.hudAtlasPath = hudAtlasPath
    self.controlHudAtlasPath = controlHudAtlasPath
    self.vehicle = nil
    self.player = nil
    self.touchButtons = {}
    self.hudElements = {}
    self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
    self.lastGyroscopeSteeringState = false
    self.vehicleControls = {}
    self:createComponents()
    return self
end
function SwitchVehicleDisplay:delete()
    for _, button in pairs(self.touchButtons) do
        self.hud:removeTouchButton(button)
    end
    SwitchVehicleDisplay:superClass().delete(self)
end
function SwitchVehicleDisplay:setVehicle(vehicle)
    self.vehicle = vehicle
    self:updatePositionState()
end
function SwitchVehicleDisplay:setPlayer(player)
    self.player = player
    self:updatePositionState()
end
function SwitchVehicleDisplay:createBackgroundElements(posX, posY)
    local sizeXLeft, sizeY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.BG_LEFT))
    local sizeXMiddle, _ = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.BG_MIDDLE))
    local sizeXRight, _ = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.BG_RIGHT))
    local uvsMiddle = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_MIDDLE)
    local uvsRight = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_RIGHT)
    self.uvsLeft = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_LEFT)
    self.uvsMiddle = uvsMiddle
    self.uvsRight = uvsRight
    self.uvsLeftDisabled = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_LEFT_DISABLED)
    self.uvsMiddleDisabled = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_MIDDLE_DISABLED)
    self.uvsRightDisabled = GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_RIGHT_DISABLED)
    local overlayLeft = Overlay.new(self.hudAtlasPath, posX, posY, sizeXLeft, sizeY)
    overlayLeft:setUVs(uvsLeft)
    self.leftElement = HUDElement.new(overlayLeft)
    self:addChild(self.leftElement)
    local posXMiddle = posX + sizeXLeft
    local overlayMiddle = Overlay.new(self.hudAtlasPath, posXMiddle, posY, sizeXMiddle, sizeY)
    overlayMiddle:setUVs(uvsMiddle)
    local middleElement = HUDElement.new(overlayMiddle)
    self.middleElement = middleElement
    self:addChild(middleElement)
    local overlayRight = Overlay.new(self.hudAtlasPath, posXMiddle + sizeXMiddle, posY, sizeXRight, sizeY)
    overlayRight:setUVs(uvsRight)
    local rightElement = HUDElement.new(overlayRight)
    self.rightElement = rightElement
    self:addChild(rightElement)
    local width, _ = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.BACKGROUND))
    local sizeXPressed, _ = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.BG_PRESSED))
    local overlayLeftPressed = Overlay.new(self.hudAtlasPath, posX, posY, sizeXPressed, sizeY)
    overlayLeftPressed:setUVs((GuiUtils.getUVs(SwitchVehicleDisplay.UV.BG_PRESSED)))
    local leftPressedElement = HUDElement.new(overlayLeftPressed)
    leftPressedElement:setVisible(false)
    self:addChild(leftPressedElement)
    local overlayRightPressed = Overlay.new(self.hudAtlasPath, posX + width - sizeXPressed, posY, sizeXPressed, sizeY)
    overlayRightPressed:setUVs(uvsPressed)
    overlayRightPressed:setInvertX(true)
    local rightPressedElement = HUDElement.new(overlayRightPressed)
    rightPressedElement:setVisible(false)
    self:addChild(rightPressedElement)
    function self.pressButtonLeftCallback()
        -- upvalues: (copy) self, (copy) leftPressedElement
        if self.isActive then
            leftPressedElement:setVisible(true)
            self.leftElement:setVisible(false)
            self.middleElement:setVisible(false)
            self.rightElement:setVisible(false)
        end
    end
    function self.pressButtonRightCallback()
        -- upvalues: (copy) self, (copy) rightPressedElement
        if self.isActive then
            rightPressedElement:setVisible(true)
            self.leftElement:setVisible(false)
            self.middleElement:setVisible(false)
            self.rightElement:setVisible(false)
        end
    end
    function self.releaseButtonCallback()
        -- upvalues: (copy) self, (copy) leftPressedElement, (copy) rightPressedElement
        if self.isActive then
            leftPressedElement:setVisible(false)
            rightPressedElement:setVisible(false)
            self.leftElement:setVisible(true)
            self.middleElement:setVisible(true)
            self.rightElement:setVisible(true)
        end
    end
end
function SwitchVehicleDisplay:createComponents()
    local posX, posY = self:getPosition()
    self:createBackgroundElements(posX, posY)
    local iconOffsetX, iconOffsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.ICON))
    local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.ICON))
    Overlay.new(self.controlHudAtlasPath, posX + iconOffsetX, posY + iconOffsetY, iconSizeX, iconSizeY):setUVs(GuiUtils.getUVs(SwitchVehicleDisplay.UV.ICON))
    self:addChild(HUDElement.new(iconOverlay))
    local glyphSwitchVehicleBackOffsetX, glyphSwitchVehicleBackOffsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.GLYPH_SWITCH_VEHICLE_BACK))
    InputGlyphMobileElement.new(g_inputDisplayManager):setAction(InputAction.SWITCH_VEHICLE_BACK)
    glyphElementBack:setIsLeftAligned(true)
    glyphElementBack:setPosition(posX + glyphSwitchVehicleBackOffsetX, posY + glyphSwitchVehicleBackOffsetY)
    glyphElementBack:setButtonGlyphColor(HUDButtonElement.COLOR.INPUT_GLYPH)
    self.glyphElementBack = glyphElementBack
    self:addChild(glyphElementBack)
    local glyphSwitchVehicleOffsetX, glyphSwitchVehicleOffsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.GLYPH_SWITCH_VEHICLE))
    InputGlyphMobileElement.new(g_inputDisplayManager):setAction(InputAction.SWITCH_VEHICLE)
    glyphElement:setPosition(posX + glyphSwitchVehicleOffsetX, posY + glyphSwitchVehicleOffsetY)
    glyphElement:setButtonGlyphColor(HUDButtonElement.COLOR.INPUT_GLYPH)
    self.glyphElement = glyphElement
    self:addChild(glyphElement)
    local arrowLeftSizeX, arrowLeftSizeY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.ARROW_LEFT))
    local arrowLeftOffsetX, arrowLeftOffsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.ARROW_LEFT))
    Overlay.new(self.controlHudAtlasPath, posX + arrowLeftOffsetX, posY + arrowLeftOffsetY, arrowLeftSizeX, arrowLeftSizeY):setUVs(GuiUtils.getUVs(SwitchVehicleDisplay.UV.ARROW_LEFT))
    self.switchLeftOverlay = arrowLeftOverlay
    self:addChild(HUDElement.new(arrowLeftOverlay))
    local touchOffsetX = { 0.1, 0.4 }
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowLeftOverlay, touchOffsetX, 0.5, self.onSwitchLeft, self, TouchHandler.TRIGGER_UP))
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowLeftOverlay, touchOffsetX, 0.5, self.pressButtonLeftCallback, self, TouchHandler.TRIGGER_DOWN))
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowLeftOverlay, touchOffsetX, 0.5, self.releaseButtonCallback, self, TouchHandler.TRIGGER_UP))
    local arrowRightSizeX, arrowRightSizeY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.ARROW_RIGHT))
    local arrowRightOffsetX, arrowRightOffsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.ARROW_RIGHT))
    Overlay.new(self.controlHudAtlasPath, posX + arrowRightOffsetX, posY + arrowRightOffsetY, arrowRightSizeX, arrowRightSizeY):setUVs(GuiUtils.getUVs(SwitchVehicleDisplay.UV.ARROW_RIGHT))
    self.switchRightOverlay = arrowRightOverlay
    self:addChild(HUDElement.new(arrowRightOverlay))
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowRightOverlay, { touchOffsetX[2], touchOffsetX[1] }, 0.5, self.onSwitchRight, self, TouchHandler.TRIGGER_UP))
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowRightOverlay, offsetX, 0.5, self.pressButtonRightCallback, self, TouchHandler.TRIGGER_DOWN))
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowRightOverlay, offsetX, 0.5, self.releaseButtonCallback, self, TouchHandler.TRIGGER_UP))
    local offsetX, offsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.GAMEPAD_OFFSET))
    self.positionTouch = { posX + offsetX, posY + offsetY }
    self.positionGamepad = { posX, posY }
end
function SwitchVehicleDisplay:onSwitchLeft(_, _, isCancel)
    if g_sleepManager:getIsSleeping() then
        return
    elseif self.isActive then
        if not isCancel then
            g_localPlayer:cycleCurrentVehicle(-1)
        end
    end
end
function SwitchVehicleDisplay:onSwitchRight(_, _, isCancel)
    if g_sleepManager:getIsSleeping() then
        return
    elseif self.isActive then
        if not isCancel then
            g_localPlayer:cycleCurrentVehicle(1)
        end
    end
end
function SwitchVehicleDisplay:update(dt)
    SwitchVehicleDisplay:superClass().update(self, dt)
    self:updateButton()
end
function SwitchVehicleDisplay:updateButton()
    local vehicle = not g_gui:getIsGuiVisible()
    if vehicle then
        vehicle = isButtonActive
    end
    self.isActive = vehicle
    if self.isActive then
        self.isActive = g_currentMission:getNextVehicle(1) ~= nil
    end
    if self.isActive ~= self.isActive then
        self.glyphElement:setVisible(self.isActive)
        self.glyphElementBack:setVisible(self.isActive)
        if self.isActive then
            self.leftElement:setUVs(self.uvsLeft)
            self.middleElement:setUVs(self.uvsMiddle)
            self.rightElement:setUVs(self.uvsRight)
            return
        end
        self.leftElement:setUVs(self.uvsLeftDisabled)
        self.middleElement:setUVs(self.uvsMiddleDisabled)
        self.rightElement:setUVs(self.uvsRightDisabled)
    end
end
function SwitchVehicleDisplay:updatePositionState(force)
    local isControllerInput = self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD and ((Platform.hasTouchSliders and true or false) and self.lastGyroscopeSteeringState)
    if isControllerInput then
        isControllerInput = self.vehicle ~= nil
    end
    if isControllerInput then
        self:setPositionState(SwitchVehicleDisplay.STATE_CONTROLLER, force)
    else
        self:setPositionState(SwitchVehicleDisplay.STATE_TOUCH, force)
    end
end
function SwitchVehicleDisplay:onInputHelpModeChange(inputHelpMode, force)
    self.lastInputHelpMode = inputHelpMode
    self:updatePositionState(force)
end
function SwitchVehicleDisplay:onGyroscopeSteeringChanged(state)
    self.lastGyroscopeSteeringState = state
    self:updatePositionState()
end
function SwitchVehicleDisplay:setPositionState(state, force)
    if Platform.hasTouchSliders then
        if state ~= self.lastPositionState then
            local startX, startY = self:getPosition()
            local targetX = self.positionGamepad[1]
            local targetY = self.positionGamepad[2]
            local speed = SwitchVehicleDisplay.MOVE_ANIMATION_DURATION
            if state == SwitchVehicleDisplay.STATE_TOUCH then
                targetX = self.positionTouch[1]
                targetY = self.positionTouch[2]
                speed = SwitchVehicleDisplay.MOVE_ANIMATION_DURATION / 5
            end
            local sequence = TweenSequence.new(self)
            sequence:insertTween(MultiValueTween.new(self.setPosition, { startX, startY }, { targetX, targetY }, force and 0.01 or speed), 0)
            sequence:start()
            self.animation = sequence
            self.lastPositionState = state
        end
    end
end
function SwitchVehicleDisplay:setScale(uiScale)
    SwitchVehicleDisplay:superClass().setScale(self, uiScale, uiScale)
    local currentVisibility = self:getVisible()
    self:setVisible(true, false)
    self.uiScale = uiScale
    local posX, posY = SwitchVehicleDisplay.getBackgroundPosition(uiScale, self:getWidth())
    self:setPosition(posX, posY)
    local offsetX, offsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.GAMEPAD_OFFSET))
    self.positionTouch = { posX + offsetX * uiScale, posY + offsetY * uiScale }
    self.positionGamepad = { posX, posY }
    self:storeOriginalPosition()
    self:setVisible(currentVisibility, false)
    if self.lastPositionState == SwitchVehicleDisplay.STATE_TOUCH then
        self:setPosition(self.positionTouch[1], self.positionTouch[2])
    end
end
function SwitchVehicleDisplay.getBackgroundPosition(scale, _)
    local offX, offY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.BACKGROUND))
    return offX * scale, offY * scale
end
function SwitchVehicleDisplay.createBackground()
    local width, height = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.BACKGROUND))
    local posX, posY = SwitchVehicleDisplay.getBackgroundPosition(1, width)
    return Overlay.new(nil, posX, posY, width, height)
end
SwitchVehicleDisplay.SIZE = {
    ["BACKGROUND"] = { 224, 106 },
    ["BG_PRESSED"] = { 224, 106 },
    ["BG_LEFT"] = { 25, 106 },
    ["BG_MIDDLE"] = { 174, 106 },
    ["BG_RIGHT"] = { 25, 106 },
    ["ICON"] = { 96, 96 },
    ["ARROW_LEFT"] = { 76, 76 },
    ["ARROW_RIGHT"] = { 76, 76 },
    ["BUTTON_SIZE"] = { 115, 120 }
}
SwitchVehicleDisplay.POSITION = {
    ["BACKGROUND"] = { 50, 50 },
    ["GAMEPAD_OFFSET"] = { 515, 0 },
    ["ICON"] = { 60, 5 },
    ["GLYPH_SWITCH_VEHICLE"] = { 237, 81 },
    ["GLYPH_SWITCH_VEHICLE_BACK"] = { -17, 81 },
    ["ARROW_LEFT"] = { 0, 15 },
    ["ARROW_RIGHT"] = { 142, 15 }
}
SwitchVehicleDisplay.UV = {
    ["ICON"] = {
        96,
        96,
        96,
        96
    },
    ["ARROW_LEFT"] = {
        0,
        96,
        96,
        96
    },
    ["ARROW_RIGHT"] = {
        96,
        96,
        -96,
        96
    },
    ["BG_LEFT"] = {
        132,
        908,
        25,
        106
    },
    ["BG_MIDDLE"] = {
        157,
        908,
        56,
        106
    },
    ["BG_RIGHT"] = {
        213,
        908,
        25,
        106
    },
    ["BG_PRESSED"] = {
        578,
        908,
        224,
        106
    },
    ["BG_LEFT_DISABLED"] = {
        344,
        908,
        25,
        106
    },
    ["BG_MIDDLE_DISABLED"] = {
        369,
        908,
        56,
        106
    },
    ["BG_RIGHT_DISABLED"] = {
        425,
        908,
        25,
        106
    }
}
if data ~= nil then
    local switchVehicleDisplay = SwitchVehicleDisplay.new(data.hud, data.hudAtlasPath, data.controlHudAtlasPath)
    switchVehicleDisplay:setScale(data.uiScale)
    switchVehicleDisplay:setVehicle(data.vehicle)
    switchVehicleDisplay:setPlayer(data.player)
    switchVehicleDisplay.lastGyroscopeSteeringState = data.lastGyroscopeSteeringState
    for k, elem in ipairs(g_currentMission.hud.displayComponents) do
        if elem == g_currentMission.hud.switchVehicleDisplay then
            g_currentMission.hud.displayComponents[k] = switchVehicleDisplay
            break
        end
    end
    g_currentMission.hud.switchVehicleDisplay = switchVehicleDisplay
    Logging.info("Reloaded")
end