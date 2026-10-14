GamepadSigninScreen = {}
local GamepadSigninScreen_mt = Class(GamepadSigninScreen, ScreenElement)
function GamepadSigninScreen.register()
    local gamepadSigninScreen = GamepadSigninScreen.new()
    g_gui:loadGui("dataS/gui/GamepadSigninScreen.xml", "GamepadSigninScreen", gamepadSigninScreen)
    return gamepadSigninScreen
end
function GamepadSigninScreen.new(target, custom_mt)
    -- upvalues: (copy) GamepadSigninScreen_mt
    local self = GamepadSigninScreen:superClass().new(target, custom_mt or GamepadSigninScreen_mt)
    self.textSpeed = 600
    self.textTime = 0
    self.textDir = 1
    self.textColor1 = {
        1,
        1,
        1,
        1
    }
    self.textColor2 = {
        1,
        1,
        1,
        0
    }
    self.textColor = {
        1,
        1,
        0.25,
        1
    }
    self.forceShowSigninGui = false
    self.requestCounter = -1
    return self
end
function GamepadSigninScreen.createFromExistingGui(gui, guiName)
    local newGui = GamepadSigninScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function GamepadSigninScreen:onCreate() end
function GamepadSigninScreen:onOpen()
    g_isSignedIn = false
    startMenuMusic()
    if g_currentMission ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then
        g_currentMission:cancelPlayersSynchronizing()
    end
    if g_modNameToDirectory[g_uniqueDlcNamePrefix .. "highlandsFishingPack"] == nil then
        self.backgroundImage:setImageFilename("shared/splash.png")
    else
        self.backgroundImage:setImageFilename("shared/splash_highlandsFishing.png")
    end
    self.requestCounter = 2
end
function GamepadSigninScreen:onClose() end
function GamepadSigninScreen:update(dt)
    GamepadSigninScreen:superClass().update(self, dt)
    if isGamepadSigninPending() then
        self.startText:setText("...")
    else
        self.startText:setText(g_i18n:getText("ui_consolePressStart"))
    end
    self.textTime = self.textTime + self.textDir * dt
    if self.textTime > self.textSpeed then
        self.textTime = self.textSpeed
        self.textDir = -self.textDir
    end
    if self.textTime < 0 then
        self.textTime = 0
        self.textDir = -self.textDir
    end
    local i = 1
    for i = i, 4 do
        self.textColor[i] = (1 - self.textTime / self.textSpeed) * self.textColor1[i] + self.textColor2[i] * (self.textTime / self.textSpeed)
    end
    if self.requestCounter >= 0 then
        self.requestCounter = self.requestCounter - 1
        if self.requestCounter < 0 then
            requestGamepadSignin(Input.BUTTON_2, self.forceShowSigninGui, true)
        end
    end
    self.startText:setTextColor(unpack(self.textColor))
    self.startText:setText2Color(self.startText.text2Color[1], self.startText.text2Color[2], self.startText.text2Color[3], self.startText.textColor[4])
end
function GamepadSigninScreen:onYesNoSigninAccept(yes)
    if yes then
        self.forceShowSigninGui = true
        self:changeScreen(GamepadSigninScreen)
    else
        g_tempDeepLinkingInfo = nil
        self:changeScreen(MainScreen)
    end
end
function GamepadSigninScreen:inputEvent(action, _, eventUsed)
    if action == InputAction.MENU_ACCEPT and self.requestCounter < 0 then
        self:signIn()
        eventUsed = true
    end
    return eventUsed
end
function GamepadSigninScreen:signIn()
    g_achievementManager:resetAchievementsState()
    self.forceShowSigninGui = false
    g_isSignedIn = true
    local resumeGame = g_currentMission ~= nil
    if GS_PLATFORM_XBOX then
        local newUserName = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
        if newUserName ~= g_currentPlayingUserName then
            resumeGame = false
        end
        g_currentPlayingUserName = newUserName
    end
    if g_tempDeepLinkingInfo == nil then
        if resumeGame then
            if g_currentMission.missionDynamicInfo.isMultiplayer then
                g_currentMission:cancelPlayersSynchronizing()
                self:changeScreen(InGameMenu)
                g_inGameMenu:setMasterServerConnectionFailed(MasterServerConnection.FAILED_CONNECTION_LOST)
            else
                g_currentMission.userSigninPaused = false
                g_currentMission:tryUnpauseGame()
                self:changeScreen(nil)
            end
        end
        if g_currentMission ~= nil then
            OnInGameMenuMenu()
        end
        self:changeScreen(MainScreen)
    else
        local newUserName = g_tempDeepLinkingInfo.requestUserName
        if GS_PLATFORM_XBOX and (newUserName ~= "" and g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) ~= newUserName) then
            YesNoDialog.show(self.onYesNoSigninAccept, self, string.format(g_i18n:getText("ui_signinWithUserToAcceptInviteRetry"), newUserName))
            return
        end
        local info = g_tempDeepLinkingInfo
        g_tempDeepLinkingInfo = nil
        if PlatformPrivilegeUtil.checkMultiplayer(acceptedGameInvitePerformConnect, nil, info.platformServerId, 30000) then
            acceptedGameInvitePerformConnect(info.platformServerId)
            return
        end
    end
end