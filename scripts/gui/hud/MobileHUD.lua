source("dataS/scripts/gui/hud/HUDSliderElement.lua")
source("dataS/scripts/gui/hud/ControlBarDisplay.lua")
source("dataS/scripts/gui/hud/SpeedSliderDisplay.lua")
source("dataS/scripts/gui/hud/SteeringSliderDisplay.lua")
source("dataS/scripts/gui/hud/SwitchVehicleDisplay.lua")
source("dataS/scripts/gui/hud/PlayerControlPadDisplay.lua")
source("dataS/scripts/gui/hud/GameInfoDisplayMobile.lua")
source("dataS/scripts/gui/hud/ingameMap/IngameMapMobile.lua")
source("dataS/scripts/gui/hud/SideNotificationMobile.lua")
source("dataS/scripts/gui/hud/HUDPopupMessageMobile.lua")
source("dataS/scripts/gui/hud/HUDButtonElement.lua")
source("dataS/scripts/gui/hud/IntroductionHelpHUDUtil.lua")
source("dataS/scripts/gui/hud/InputGlyphMobileElement.lua")
source("dataS/scripts/gui/hud/POIInfoDisplay.lua")
MobileHUD = {}
local MobileHUD_mt = Class(MobileHUD, HUD)
function MobileHUD.new(isServer, isClient, isConsoleVersion, messageCenter, l10n, inputManager, inputDisplayManager, modManager, fillTypeManager, fruitTypeManager, guiSoundPlayer, currentMission, farmManager, farmlandManager)
    -- upvalues: (copy) MobileHUD_mt
    local self = MobileHUD:superClass().new(isServer, isClient, isConsoleVersion, messageCenter, l10n, inputManager, inputDisplayManager, modManager, fillTypeManager, fruitTypeManager, guiSoundPlayer, currentMission, farmManager, farmlandManager, MobileHUD_mt)
    self.lastMouseInput = {
        ["posX"] = 0,
        ["posY"] = 0,
        ["isDown"] = false,
        ["isUp"] = false,
        ["button"] = 0,
        ["touchIsDown"] = false
    }
    self.messageCenter:subscribe(MessageType.AI_VEHICLE_STATE_CHANGE, self.onAIVehicleStateChanged, self)
    return self
end
function MobileHUD:delete()
    g_touchHandler:removeAllTouchAreas()
    self.messageCenter:unsubscribeAll(self)
    IntroductionHelpHUDUtil.delete()
    MobileHUD:superClass().delete(self)
end
function MobileHUD:createDisplayComponents(uiScale)
    self.buttons = {}
    self.ingameMap = IngameMapMobile.new(self, g_baseHUDFilename, g_controlHUDFilename, self.inputDisplayManager)
    self.ingameMap:setScale(uiScale)
    table.insert(self.displayComponents, self.ingameMap)
    self.gamePausedDisplay = GamePausedDisplay.new()
    self.gamePausedDisplay:setScale(uiScale)
    self.gamePausedDisplay:setVisible(false)
    table.insert(self.displayComponents, self.gamePausedDisplay)
    self.menuBackgroundOverlay = Overlay.new(HUD.MENU_BACKGROUND_PATH, 0.5, 0, 1, g_screenAspectRatio)
    self.menuBackgroundOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_CENTER)
    self.blinkingWarning = nil
    self.blinkingWarningDisplay = HUDTextDisplay.new(0.5, 0.5, HUD.TEXT_SIZE.BLINKING_WARNING, RenderText.ALIGN_CENTER, HUD.COLOR.BLINKING_WARNING, true)
    local blinkTween = TweenSequence.new(self.blinkingWarningDisplay)
    blinkTween:addTween(MultiValueTween.new(self.blinkingWarningDisplay.setTextColorChannels, HUD.COLOR.BLINKING_WARNING_1, HUD.COLOR.BLINKING_WARNING_2, HUD.ANIMATION.BLINKING_WARNING_TIME))
    blinkTween:addTween(MultiValueTween.new(self.blinkingWarningDisplay.setTextColorChannels, HUD.COLOR.BLINKING_WARNING_2, HUD.COLOR.BLINKING_WARNING_1, HUD.ANIMATION.BLINKING_WARNING_TIME))
    blinkTween:setLooping(true)
    self.blinkingWarningDisplay:setAnimation(blinkTween)
    self.blinkingWarningDisplay:setVisible(false)
    table.insert(self.displayComponents, self.blinkingWarningDisplay)
    Overlay.new(g_baseHUDFilename, 0, 0, 1, 1):setUVs(GuiUtils.getUVs(HUD.UV.AREA))
    fadeOverlay:setColor(0, 0, 0, 0)
    self.fadeScreenElement = HUDElement.new(fadeOverlay)
    table.insert(self.displayComponents, self.fadeScreenElement)
    self.popupMessage = HUDPopupMessageMobile.new(g_baseHUDFilename, self.ingameMap)
    self.popupMessage:setScale(uiScale)
    self.popupMessage:storeOriginalPosition()
    table.insert(self.displayComponents, self.popupMessage)
    self.gameInfoDisplay = GameInfoDisplayMobile.new(self, g_baseHUDFilename, g_gameSettings:getValue(GameSettings.SETTING.MONEY_UNIT), g_controlHUDFilename)
    self.gameInfoDisplay:setScale(uiScale)
    self.gameInfoDisplay:setTemperatureVisible(false)
    self.gameInfoDisplay:setVehicle(self.controlledVehicle)
    table.insert(self.displayComponents, self.gameInfoDisplay)
    self.controlBarDisplay = ControlBarDisplay.new(self, g_baseHUDFilename, g_controlHUDFilename)
    self.controlBarDisplay:setVehicle(self.controlledVehicle)
    self.controlBarDisplay:setScale(uiScale)
    self.controlBarDisplay:storeOriginalPosition()
    self.controlBarDisplay:setVisible(true, false)
    table.insert(self.displayComponents, self.controlBarDisplay)
    self.switchVehicleDisplay = SwitchVehicleDisplay.new(self, g_baseHUDFilename, g_controlHUDFilename)
    self.switchVehicleDisplay:setVehicle(self.controlledVehicle)
    self.switchVehicleDisplay:setScale(uiScale)
    self.switchVehicleDisplay:storeOriginalPosition()
    self.switchVehicleDisplay:setVisible(true, false)
    table.insert(self.displayComponents, self.switchVehicleDisplay)
    self.speedSliderDisplay = SpeedSliderDisplay.new(self, g_baseHUDFilename, g_controlHUDFilename)
    self.speedSliderDisplay:setVehicle(self.controlledVehicle)
    self.speedSliderDisplay:setScale(uiScale)
    self.speedSliderDisplay:storeOriginalPosition()
    self.speedSliderDisplay:setVisible(true, false)
    table.insert(self.displayComponents, self.speedSliderDisplay)
    self.steeringSliderDisplay = SteeringSliderDisplay.new(self, g_baseHUDFilename)
    self.steeringSliderDisplay:setVehicle(self.controlledVehicle)
    self.steeringSliderDisplay:setScale(uiScale)
    self.steeringSliderDisplay:storeOriginalPosition()
    self.steeringSliderDisplay:setVisible(true, false)
    table.insert(self.displayComponents, self.steeringSliderDisplay)
    self.playerControlPadDisplay = PlayerControlPadDisplay.new(self, g_baseHUDFilename)
    self.playerControlPadDisplay:setScale(uiScale)
    self.playerControlPadDisplay:storeOriginalPosition()
    self.playerControlPadDisplay:setVisible(true, false)
    table.insert(self.displayComponents, self.playerControlPadDisplay)
    self.achievementMessage = AchievementMessage.new()
    self.achievementMessage:setScale(uiScale)
    self.achievementMessage:setVisible(false, false)
    table.insert(self.displayComponents, self.achievementMessage)
    self.sideNotifications = SideNotificationMobile.new()
    self.sideNotifications:setScale(uiScale)
    self.sideNotifications:storeOriginalPosition()
    self.sideNotifications:setVisible(true, false)
    table.insert(self.displayComponents, self.sideNotifications)
    self.topNotification = TopNotification.new()
    self.topNotification:setScale(uiScale)
    self.topNotification:storeOriginalPosition()
    self.topNotification:setVisible(false, false)
    table.insert(self.displayComponents, self.topNotification)
    self.infoDisplay = InfoDisplay.new()
    self.infoDisplay:setScale(uiScale)
    self.infoDisplay:storeOriginalPosition()
    self.infoDisplay:setVisible(false, false)
    table.insert(self.displayComponents, self.infoDisplay)
    self.poiInfoDisplay = POIInfoDisplay.new()
    self.poiInfoDisplay:setScale(uiScale)
    table.insert(self.displayComponents, self.poiInfoDisplay)
end
function MobileHUD:drawControlledEntityHUD()
    if self.isVisible then
        if self.controlledVehicle == nil then
            if self.controlPlayer and self.player ~= nil then
                self.player:draw()
                self.playerControlPadDisplay:draw()
                self.infoDisplay:draw()
            end
        elseif self.showVehicleInfo then
            self.controlledVehicle:draw()
        end
        self.controlBarDisplay:draw()
        self.switchVehicleDisplay:draw()
        self.speedSliderDisplay:draw()
        self.steeringSliderDisplay:draw()
        self.poiInfoDisplay:draw()
        self.poiInfoDisplay:setText("")
    end
end
function MobileHUD:setPOIInfoText(text)
    self.poiInfoDisplay:setText(text)
end
function MobileHUD:drawInputHelp() end
function MobileHUD:drawVehicleName() end
function MobileHUD:drawInGameMessageAndIcon() end
function MobileHUD:addExtraPrintText(text) end
function MobileHUD:showVehicleName(vehicleName) end
function MobileHUD:showAttachContext(attachVehicleName) end
function MobileHUD:showTipContext(fillTypeName) end
function MobileHUD:showFuelContext(fuelingVehicleName) end
function MobileHUD:showFillDogBowlContext() end
function MobileHUD:onMenuVisibilityChange(isMenuVisible, _)
    self.achievementMessage:onMenuVisibilityChange(isMenuVisible)
end
function MobileHUD:setInputHelpVisible(isVisible) end
function MobileHUD:setControlledVehicle(vehicle)
    self.controlledVehicle = vehicle
    self.controlBarDisplay:setVehicle(vehicle)
    self.switchVehicleDisplay:setVehicle(vehicle)
    self.speedSliderDisplay:setVehicle(vehicle)
    self.steeringSliderDisplay:setVehicle(vehicle)
    if vehicle ~= nil then
        local aiActive = vehicle:getIsAIActive()
        self.controlBarDisplay:onAIVehicleStateChanged(aiActive, vehicle)
        self.speedSliderDisplay:onAIVehicleStateChanged(aiActive, vehicle)
        self.steeringSliderDisplay:onAIVehicleStateChanged(aiActive, vehicle)
    end
    self.controlBarDisplay:onInputHelpModeChange(self.lastInputHelpMode)
    self.switchVehicleDisplay:onInputHelpModeChange(self.lastInputHelpMode)
    self.speedSliderDisplay:onInputHelpModeChange(self.lastInputHelpMode)
    self.steeringSliderDisplay:onInputHelpModeChange(self.lastInputHelpMode)
    self.gameInfoDisplay:setVehicle(vehicle)
end
function MobileHUD:setIsControllingPlayer(isControllingPlayer)
    MobileHUD:superClass().setIsControllingPlayer(self, isControllingPlayer)
    local player = nil
    if isControllingPlayer then
        player = self.player
    end
    self.isControllingPlayer = isControllingPlayer
    self.controlBarDisplay:setPlayer(player)
    self.switchVehicleDisplay:setPlayer(player)
    self.speedSliderDisplay:setPlayer(player)
    self.steeringSliderDisplay:setPlayer(player)
    self.playerControlPadDisplay:setPlayer(player)
    self.ingameMap:setPlayer(player)
end
function MobileHUD:update(dt)
    if not self.fadeAnimation:getFinished() then
        self.fadeAnimation:update(dt)
    end
    self.fadeFollowDelay = self.fadeFollowDelay - dt
    self.infoDisplay:update(dt)
    self.controlBarDisplay:update(dt)
    self.switchVehicleDisplay:update(dt)
    self.speedSliderDisplay:update(dt)
    self.steeringSliderDisplay:update(dt)
    self.playerControlPadDisplay:update(dt)
    self.gameInfoDisplay:update(dt)
    self.achievementMessage:update(dt)
    self.sideNotifications:update(dt)
    self.topNotification:update(dt)
    local inputHelpMode = g_inputBinding:getInputHelpMode()
    if inputHelpMode ~= self.lastInputHelpMode then
        self.controlBarDisplay:onInputHelpModeChange(inputHelpMode)
        self.switchVehicleDisplay:onInputHelpModeChange(inputHelpMode)
        self.speedSliderDisplay:onInputHelpModeChange(inputHelpMode)
        self.steeringSliderDisplay:onInputHelpModeChange(inputHelpMode)
        self.playerControlPadDisplay:onInputHelpModeChange(inputHelpMode)
        self.lastInputHelpMode = inputHelpMode
    end
    local gyroscopeSteeringActive = g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING)
    if self.lastGyroSteeringState ~= gyroscopeSteeringActive then
        self.controlBarDisplay:onGyroscopeSteeringChanged(gyroscopeSteeringActive)
        self.switchVehicleDisplay:onGyroscopeSteeringChanged(gyroscopeSteeringActive)
        self.steeringSliderDisplay:onGyroscopeSteeringChanged(gyroscopeSteeringActive)
    end
    if self.lastMouseInput.touchIsDown then
        self:mouseEvent(self.lastMouseInput.posX, self.lastMouseInput.posY, true, false, self.lastMouseInput.button)
    end
    if not g_gui:getIsGuiVisible() then
        local show = Input.isKeyPressed(Input.KEY_lctrl) and true or false
        if self.debugMouseCursorActive ~= show then
            g_inputBinding:setShowMouseCursor(show, false)
            self.debugMouseCursorActive = show
        end
    end
end
function MobileHUD.addTouchButton(_, overlay, areaOffsetX, areaOffsetY, callback, callbackTarget, triggerType, extraArguments)
    return g_touchHandler:registerTouchAreaOverlay(overlay, areaOffsetX, areaOffsetY, triggerType, callback, callbackTarget, extraArguments)
end
function MobileHUD.removeTouchButton(_, area)
    g_touchHandler:removeTouchArea(area)
end
function MobileHUD.hideTouchButton(_, area)
    g_touchHandler:setTouchAreaVisibility(area, false)
end
function MobileHUD.showTouchButton(_, area)
    g_touchHandler:setTouchAreaVisibility(area, true)
end
function MobileHUD:onAIVehicleStateChanged(state, vehicle)
    self.controlBarDisplay:onAIVehicleStateChanged(state, vehicle)
    self.speedSliderDisplay:onAIVehicleStateChanged(state, vehicle)
    self.steeringSliderDisplay:onAIVehicleStateChanged(state, vehicle)
end
function MobileHUD:setMissionInfo(missionInfo)
    self.missionInfo = missionInfo
    self.gameInfoDisplay:setMissionInfo(missionInfo)
end
function MobileHUD:scrollChatMessages(delta, numMessages) end
function MobileHUD:setChatDisplayVisible(isVisible, animate) end
function MobileHUD:setChatMessagesReference(chatMessages) end
function MobileHUD:addChatMessage(msg, sender, farmId) end
function MobileHUD:setConnectedUsers(users) end
function MobileHUD:setInfoVisible(isVisible) end
function MobileHUD:updateMap(dt)
    self.ingameMap:update(dt)
end
function MobileHUD:registerInput()
    self.ingameMap:registerInput()
end
function MobileHUD.showInGameMessage(_, title, message, _, controlGlyphs, callback, callbackTarget)
    TourDialog.show(title, message, controlGlyphs, callback, callbackTarget)
end