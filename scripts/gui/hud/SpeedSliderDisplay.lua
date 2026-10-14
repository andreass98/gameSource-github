local data = nil
if SpeedSliderDisplay ~= nil then
    local old = g_currentMission.hud.speedSliderDisplay
    data = {
        ["vehicle"] = old.vehicle,
        ["player"] = old.player,
        ["hud"] = old.hud,
        ["uiScale"] = old.uiScale,
        ["hudAtlasPath"] = old.hudAtlasPath,
        ["controlHudAtlasPath"] = old.controlHudAtlasPath,
        ["sliderState"] = old.sliderState
    }
    old:delete()
end
SpeedSliderDisplay = {}
local old = Class(SpeedSliderDisplay, HUDDisplayElement)
SpeedSliderDisplay.GAMEPAD_SWITCH_TIME = 500
SpeedSliderDisplay.SPEED_NEED_OFFSET = 0.20943951023931956
SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS = {
    0,
    0.2,
    0.4,
    0.6,
    0.8,
    1
}
function SpeedSliderDisplay.new(hud, hudAtlasPath, controlHudAtlasPath)
    -- upvalues: (copy) old
    local backgroundOverlay = SpeedSliderDisplay.createBackground()
    local self = SpeedSliderDisplay:superClass().new(backgroundOverlay, nil, old)
    self.hud = hud
    self.uiScale = 1
    self.hudAtlasPath = hudAtlasPath
    self.controlHudAtlasPath = controlHudAtlasPath
    self.vehicle = nil
    self.player = nil
    self.isRideable = false
    self.sliderPosition = 0
    self.restPosition = 0.25
    self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
    self.sliderState = nil
    self:createComponents()
    g_messageCenter:subscribe(MessageType.GUI_BEFORE_OPEN, self.onGuiOpen, self)
    g_messageCenter:subscribe(MessageType.GUI_DIALOG_OPENED, self.onDialogOpened, self)
    g_messageCenter:subscribe(MessageType.GUIDED_TOUR_DIALOG, self.onTourDialog, self)
    g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)
    return self
end
function SpeedSliderDisplay:delete()
    g_messageCenter:unsubscribeAll(self)
    SpeedSliderDisplay:superClass().delete(self)
end
function SpeedSliderDisplay:createComponents()
    local baseX, baseY = self:getPosition()
    local bgSizeX, bgSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.BACKGROUND))
    Overlay.new(self.hudAtlasPath, baseX, baseY, bgSizeX, bgSizeY):setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.BACKGROUND))
    self.sliderBackgroundElement = HUDElement.new(backgroundOverlay)
    self:addChild(self.sliderBackgroundElement)
    self.positiveBarHudElement = self:createBar(SpeedSliderDisplay.POSITION.POSITIVE_BAR, SpeedSliderDisplay.SIZE.POSITIVE_BAR, SpeedSliderDisplay.COLOR.POSITIVE_BAR)
    self.sliderBackgroundElement:addChild(self.positiveBarHudElement)
    self.negativeBarHudElement = self:createBar(SpeedSliderDisplay.POSITION.NEGATIVE_BAR, SpeedSliderDisplay.SIZE.NEGATIVE_BAR, SpeedSliderDisplay.COLOR.NEGATIVE_BAR)
    self.sliderBackgroundElement:addChild(self.negativeBarHudElement)
    local _, negativeBarSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.NEGATIVE_BAR))
    self.negativeBarPosX = _
    self.negativeBarPosY = negativeBarSizeY
    local _, negativeBarSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.NEGATIVE_BAR))
    self.negativeBarSizeY = negativeBarSizeY
    local _, textSize = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SPEED_TEXT))
    self.textPosX = _
    self.textPosY = textSize
    local _, textSize = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SPEED_TEXT_GAMEPAD))
    self.textPosGamepadX = _
    self.textPosGamepadY = textSize
    local _, textSize = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SPEED_TEXT_GAMEPAD_OFFSET_KMH))
    self.textOffsetXkmh = _
    local _, textSize = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.SPEED_TEXT))
    self.textSize = textSize
    self.sliderUVs = GuiUtils.getUVs(SpeedSliderDisplay.UV.SLIDER)
    self.sliderUVsDisabled = GuiUtils.getUVs(SpeedSliderDisplay.UV.SLIDER_DISABLED)
    local slOffX, slOffY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SLIDER_OFFSET))
    local slSizeX, slSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.SLIDER_SIZE))
    Overlay.new(self.hudAtlasPath, baseX + slOffX, baseY + slOffY, slSizeX, slSizeY):setUVs(self.sliderUVs)
    self:updateSliderTranslations(1)
    self.sliderHudElement = HUDSliderElement.new(sliderOverlay, backgroundOverlay, 1.5, 0, 100, 2, self.sliderMin, self.sliderCenter, self.sliderMax, self.sliderMax)
    self.sliderHudElement:setCallback(self.onSliderPositionChanged, self)
    self.sliderBackgroundElement:addChild(self.sliderHudElement)
    local pljbgPosX, pljbgPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.JUMP_BUTTON))
    local playerJumpIconSizeX, playerJumpIconSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.PLAYER_JUMP_ICON))
    self.playerJumpButtonElement = HUDButtonElement.new(self.hud, baseX + pljbgPosX, baseY + pljbgPosY)
    self.playerJumpButtonElement:setIcon(self.controlHudAtlasPath, playerJumpIconSizeX, playerJumpIconSizeY, GuiUtils.getUVs(SpeedSliderDisplay.UV.JUMP_PLAYER))
    self.playerJumpButtonElement:setAction(InputAction.JUMP)
    self.playerJumpButtonElement:addTouchHandler(self.onJumpEventCallback, self)
    self:addChild(self.playerJumpButtonElement)
    self.horseJumpButtonElement = HUDButtonElement.new(self.hud, baseX + pljbgPosX, baseY + pljbgPosY)
    self.horseJumpButtonElement:setIcon(self.controlHudAtlasPath, playerJumpIconSizeX, playerJumpIconSizeY, GuiUtils.getUVs(SpeedSliderDisplay.UV.JUMP_HORSE))
    self.horseJumpButtonElement:setAction(InputAction.JUMP)
    self.horseJumpButtonElement:addTouchHandler(self.onJumpEventCallback, self)
    self:addChild(self.horseJumpButtonElement)
    local gpbgPosX, gpbgPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND))
    local gpbgSizeX, gpbgSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.GAMEPAD_BACKGROUND))
    Overlay.new(self.hudAtlasPath, baseX + gpbgPosX, baseY + gpbgPosY, gpbgSizeX, gpbgSizeY):setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.GAMEPAD_BACKGROUND))
    self.gamepadBackgroundHudElement = HUDElement.new(gamepadBackgroundOverlay)
    self:addChild(self.gamepadBackgroundHudElement)
    self.sliderHudElement:setAxisPosition(self.sliderCenter)
    self.positionVisible = { baseX, baseY }
    local _, yOffset = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND))
    self.positionInvisible = { baseX, baseY - yOffset }
end
function SpeedSliderDisplay:updateSliderTranslations(uiScale)
    local height = self.sliderBackgroundElement:getHeight()
    local slOffX, slOffY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SLIDER_OFFSET))
    self.sliderPosX = slOffX * uiScale
    self.sliderPosY = slOffY * uiScale
    self.backgroundSizeY = height - slOffY * 2
    local _, slAreaY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.SLIDER_AREA))
    local slAreaY = slAreaY * uiScale
    self.sliderAreaY = slAreaY
    local _, slCenterY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SLIDER_CENTER))
    self.restPosition = slCenterY * uiScale / slAreaY
    self.sliderMin = self.sliderPosY
    self.sliderMax = self.sliderMin + self.sliderAreaY
    self.sliderCenter = self.sliderMin + self.sliderAreaY * self.restPosition
end
function SpeedSliderDisplay:setSliderState(state)
    if self.sliderState ~= state then
        if state then
            self:showSlider()
            return
        end
        self:hideSlider()
    end
end
function SpeedSliderDisplay:hideSlider()
    local startX, startY = self:getPosition()
    local sequence = TweenSequence.new(self)
    sequence:insertTween(MultiValueTween.new(self.setPosition, { startX, startY }, self.positionInvisible, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
    sequence:start()
    self.animation = sequence
    self.sliderState = false
    self.sliderHudElement:setTouchIsActive(false)
    self:updateElementsVisibility()
end
function SpeedSliderDisplay:showSlider()
    local startX, startY = self:getPosition()
    local sequence = TweenSequence.new(self)
    sequence:insertTween(MultiValueTween.new(self.setPosition, { startX, startY }, self.positionVisible, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
    sequence:addCallback(self.onSliderVisibilityChangeFinished, true)
    sequence:start()
    self.animation = sequence
    self.sliderState = true
    self.sliderHudElement:resetSlider()
    self.sliderHudElement:setTouchIsActive(true)
end
function SpeedSliderDisplay:updateElementsVisibility()
    self.gamepadBackgroundHudElement:setVisible(not self.sliderState and self.player == nil and not (self.vehicle ~= nil and self.isRideable))
    self.sliderBackgroundElement:setVisible(self.sliderState)
end
function SpeedSliderDisplay:onSliderVisibilityChangeFinished(visibility)
    if visibility then
        self:updateElementsVisibility()
    end
end
function SpeedSliderDisplay:setVehicle(vehicle)
    self.vehicle = vehicle
    if vehicle ~= nil then
        self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)
        if self.player ~= nil then
            self:setPlayer(nil)
        end
        self.sliderHudElement:resetSlider()
        self.sliderHudElement:clearSnapPositions()
        if self.isRideable then
            local i = 1
            for i = i, #SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS do
                self.sliderHudElement:addSnapPosition(self.sliderPosY + self.sliderAreaY * SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[i])
            end
        end
    end
    if self.isRideable then
        self.sliderBackgroundElement:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.BACKGROUND_HORSE))
        local sizeX, sizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.BACKGROUND_HORSE))
        self.sliderBackgroundElement:setDimension(sizeX * self.uiScale, sizeY * self.uiScale)
    else
        self.sliderBackgroundElement:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.BACKGROUND))
        local sizeX, sizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.BACKGROUND))
        self.sliderBackgroundElement:setDimension(sizeX * self.uiScale, sizeY * self.uiScale)
    end
    self:updateElementsVisibility()
end
function SpeedSliderDisplay:setPlayer(player)
    self.player = player
    if player ~= nil and self.vehicle ~= nil then
        self:setVehicle(nil)
    end
    self:updateVisibilityState()
    self:updateElementsVisibility()
end
function SpeedSliderDisplay:updateButton()
    local isPlayerJumpVisible = false
    if self.player ~= nil then
        isPlayerJumpVisible = not self.sliderState
    end
    self.playerJumpButtonElement:setVisible(isPlayerJumpVisible)
    g_gui:getIsGuiVisible()
end
function SpeedSliderDisplay:createBar(position, size, color)
    local baseX, baseY = self:getPosition()
    local posX, posY = getNormalizedScreenValues(unpack(position))
    local sizeX, sizeY = getNormalizedScreenValues(unpack(size))
    local barOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, baseX + posX, baseY + posY, sizeX, sizeY)
    barOverlay:setColor(unpack(color))
    return HUDElement.new(barOverlay)
end
function SpeedSliderDisplay:onSliderPositionChanged(position)
    self.sliderPosition = math.clamp(position, 0, 1)
    local selfX, selfY = self:getPosition()
    local acc, brake = self:getAccelerateAndBrakeValue()
    self.positiveBarHudElement:setScale(self.uiScale, acc * self.uiScale)
    self.positiveBarHudElement:setColor(unpack(self.cruiseControlIsActive and SpeedSliderDisplay.COLOR.CRUISE_CONTROL or SpeedSliderDisplay.COLOR.POSITIVE_BAR))
    self.negativeBarHudElement:setPosition(selfX + self.negativeBarPosX * self.uiScale, selfY + (self.negativeBarPosY + self.negativeBarSizeY * (1 - brake)) * self.uiScale)
    self.negativeBarHudElement:setScale(self.uiScale, brake * self.uiScale)
    if self.vehicle ~= nil and self.isRideable then
        local gait = 1
        for gait = gait, #SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS do
            if math.abs(position - SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[gait]) < 0.01 then
                self.vehicle:setCurrentGait(gait)
                self.lastGait = gait
                self.lastGaitTime = g_time
                return
            end
        end
    end
end
function SpeedSliderDisplay:getAccelerateAndBrakeValue()
    return math.clamp((self.sliderPosition - self.restPosition) / (1 - self.restPosition), 0, 1), 1 - math.clamp(self.sliderPosition / self.restPosition, 0, 1)
end
function SpeedSliderDisplay:onJumpEventCallback()
    if not g_sleepManager:getIsSleeping() then
        if self.vehicle ~= nil and (self.isRideable and self.vehicle:getIsRideableJumpAllowed()) then
            self.vehicle:jump()
        end
        if self.player ~= nil then
            self.player:onInputJump(nil, 1)
        end
    end
end
function SpeedSliderDisplay:update(dt)
    SpeedSliderDisplay:superClass().update(self, dt)
    self:updateButton()
    if self.sliderHudElement ~= nil then
        self.sliderHudElement:update(dt)
    end
    if self.vehicle ~= nil then
        if self.vehicle.setAccelerationPedalInput ~= nil then
            local acceleration, brake = self:getAccelerateAndBrakeValue()
            self.vehicle:setTargetSpeedAndDirection(math.abs(acceleration + brake), acceleration > 0 and 1 or (brake > 0 and -1 or 0))
        end
        if self.isRideable then
            local acceleration = self.vehicle:getCurrentGait()
            if acceleration ~= self.lastGait and (self.lastGaitTime < g_time - 250 and SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[acceleration] ~= nil) then
                self.sliderHudElement:setAxisPosition(self.sliderPosY + self.sliderAreaY * SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[acceleration])
                self.lastGait = acceleration
            end
        end
    end
end
function SpeedSliderDisplay:getIsSliderActive()
    if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
        return false
    elseif Platform.hasTouchSliders then
        if self.vehicle == nil or not self.vehicle:getIsAIActive() then
            return self.player == nil
        else
            return false
        end
    else
        return false
    end
end
function SpeedSliderDisplay:onInputHelpModeChange(inputHelpMode)
    self.lastInputHelpMode = inputHelpMode
    if inputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
        self.sliderHudElement:setAxisPosition(self.sliderPosY + self.sliderAreaY * self.restPosition)
    end
    self:updateVisibilityState()
end
function SpeedSliderDisplay:onAIVehicleStateChanged(_, vehicle)
    if vehicle == self.vehicle then
        self:updateVisibilityState()
    end
end
function SpeedSliderDisplay:updateVisibilityState()
    local sliderState = self:getIsSliderActive()
    if sliderState ~= self.sliderState then
        self:setSliderState(sliderState, true)
    end
end
function SpeedSliderDisplay:draw()
    SpeedSliderDisplay:superClass().draw(self)
    if self.vehicle ~= nil and not self.isRideable then
        local speed = MathUtil.round(g_i18n:getSpeed(self.vehicle:getLastSpeed()))
        local baseX, baseY = self:getPosition()
        local width = self:getWidth()
        setTextColor(1, 1, 1, 1)
        setTextBold(true)
        local useLongSpeedStr = self.vehicle:getIsAIActive()
        if not useLongSpeedStr then
            useLongSpeedStr = true
            if self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD then
                useLongSpeedStr = not Platform.hasTouchSliders
            end
        end
        local posY, text
        if useLongSpeedStr then
            baseX = self.gamepadBackgroundHudElement:getPosition()
            width = self.gamepadBackgroundHudElement:getWidth()
            posY = baseY + self.textPosGamepadY * self.uiScale
            text = string.format("%02d %s", speed, g_i18n:getSpeedMeasuringUnit())
        else
            posY = baseY + self.textPosY * self.uiScale
            text = string.format("%02d", speed)
        end
        setTextAlignment(RenderText.ALIGN_CENTER)
        renderText(baseX + width * 0.5, posY, self.textSize * self.uiScale, text)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
    end
end
function SpeedSliderDisplay:getIsVehicleThrottleActive()
    if not Platform.hasTouchSliders then
        return false
    end
    return g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_GAMEPAD
end
function SpeedSliderDisplay:onDialogOpened(_, overlappingDialog)
    if not overlappingDialog then
        self.sliderHudElement:resetSlider()
    end
end
function SpeedSliderDisplay:onGuiOpen()
    self.sliderHudElement:resetSlider()
end
function SpeedSliderDisplay:onTourDialog()
    self.sliderHudElement:resetSlider()
end
function SpeedSliderDisplay:setScale(uiScale)
    SpeedSliderDisplay:superClass().setScale(self, uiScale, uiScale)
    local currentVisibility = self:getVisible()
    self:setVisible(true, false)
    self.uiScale = uiScale
    local posX, posY = SpeedSliderDisplay.getBackgroundPosition(uiScale, self:getWidth())
    self:setPosition(posX, posY)
    self.positionVisible = { posX, posY }
    local _, yOffset = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND))
    self.positionInvisible = { posX, posY - yOffset * uiScale }
    self:updateSliderTranslations(uiScale)
    self.sliderHudElement:setRange(self.sliderMin, self.sliderCenter, self.sliderMax, self.sliderMax)
    self:storeOriginalPosition()
    self:setVisible(currentVisibility, false)
    if not self:getIsSliderActive() then
        self:setPosition(self.positionInvisible[1], self.positionInvisible[2])
    end
end
function SpeedSliderDisplay:updateInsets()
    self:setScale(self.uiScale)
end
function SpeedSliderDisplay.getBackgroundPosition(scale, width)
    local offX, offY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.BACKGROUND))
    local _, rightInset, _, _ = getSafeFrameInsets()
    return math.min(1 + offX * scale, 1 - rightInset - width), offY * scale
end
function SpeedSliderDisplay.createBackground()
    local width, height = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.BACKGROUND))
    local posX, posY = SpeedSliderDisplay.getBackgroundPosition(1, width)
    return Overlay.new(nil, posX, posY, width, height)
end
SpeedSliderDisplay.SIZE = {
    ["BACKGROUND"] = { 91, 635 },
    ["BACKGROUND_HORSE"] = { 91, 549 },
    ["POSITIVE_BAR"] = { 67, 400 },
    ["NEGATIVE_BAR"] = { 67, 100 },
    ["PLAYER_JUMP_ICON"] = { 90, 90 },
    ["JUMP_BUTTON"] = { 106, 106 },
    ["JUMP_BUTTON_ICON"] = { 90, 90 },
    ["SLIDER_SIZE"] = { 192, 124 },
    ["SLIDER_AREA"] = { 192, 500 },
    ["GAMEPAD_BACKGROUND"] = { 264, 84 },
    ["SPEED_TEXT"] = { 0, 55 },
    ["GAMEPAD_OFFSET"] = { 0, -557 }
}
SpeedSliderDisplay.POSITION = {
    ["BACKGROUND"] = { -160, 50 },
    ["JUMP_BUTTON"] = { -7, 558 },
    ["SPEED_TEXT"] = { 45, 574 },
    ["SPEED_TEXT_GAMEPAD"] = { 84, 578 },
    ["SPEED_TEXT_GAMEPAD_OFFSET_KMH"] = { 15, 0 },
    ["SNAP1"] = { 8, 224 },
    ["SNAP2"] = { 8, 324 },
    ["SNAP3"] = { 8, 424 },
    ["NEGATIVE_BAR"] = { 12, 24 },
    ["POSITIVE_BAR"] = { 12, 124 },
    ["SLIDER_OFFSET"] = { -49, -41 },
    ["SLIDER_CENTER"] = { 0, 100 },
    ["GAMEPAD_BACKGROUND"] = { -143, 557 }
}
SpeedSliderDisplay.UV = {
    ["BACKGROUND"] = {
        5,
        293,
        91,
        635
    },
    ["BACKGROUND_HORSE"] = {
        5,
        379,
        91,
        549
    },
    ["SLIDER"] = {
        97,
        432,
        192,
        142
    },
    ["SLIDER_DISABLED"] = {
        779,
        0,
        192,
        142
    },
    ["JUMP_HORSE"] = {
        96,
        192,
        96,
        96
    },
    ["JUMP_PLAYER"] = {
        768,
        0,
        96,
        96
    },
    ["GAMEPAD_BACKGROUND"] = {
        288,
        528,
        264,
        84
    }
}
SpeedSliderDisplay.COLOR = {
    ["BACKGROUND"] = {
        1,
        1,
        1,
        0.5
    },
    ["POSITIVE_BAR"] = {
        0,
        0.486274,
        0.8549019,
        0.5
    },
    ["NEGATIVE_BAR"] = {
        1,
        0.1,
        0.1,
        0.5
    },
    ["CRUISE_CONTROL"] = {
        0.0227,
        0.5346,
        0.8519,
        0.9
    }
}
if data ~= nil then
    local speedSliderDisplay = SpeedSliderDisplay.new(data.hud, data.hudAtlasPath, data.controlHudAtlasPath)
    speedSliderDisplay:setScale(data.uiScale)
    speedSliderDisplay:setVehicle(data.vehicle)
    speedSliderDisplay:setPlayer(data.player)
    for k, elem in ipairs(g_currentMission.hud.displayComponents) do
        if elem == g_currentMission.hud.speedSliderDisplay then
            g_currentMission.hud.displayComponents[k] = speedSliderDisplay
            break
        end
    end
    g_currentMission.hud.speedSliderDisplay = speedSliderDisplay
    Logging.info("Reloaded")
end