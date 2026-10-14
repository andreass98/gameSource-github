MainScreen = {}
local MainScreen_mt = Class(MainScreen, ScreenElement)
function MainScreen.register()
    local mainScreen = MainScreen.new()
    g_gui:loadGui("dataS/gui/MainScreen.xml", "MainScreen", mainScreen)
    return mainScreen
end
MainScreen.NOTIFICATION_ANIMATION_DURATION = 500
MainScreen.NOTIFICATION_CHECK_DELAY = 500
MainScreen.NOTIFICATION_ANIM_DELAY = 2000
MainScreen.NO_STORE_URL = "noStore"
function MainScreen.new(target, custom_mt)
    -- upvalues: (copy) MainScreen_mt
    local self = ScreenElement.new(target, custom_mt or MainScreen_mt)
    self.firstTimeOpened = true
    self.lastActiveButton = nil
    self.blendDir = 0
    self.blendingAlpha = 1
    self.disableMultiplayer = false
    self.showGamepadModeDialog = true
    self.showHeadTrackingDialog = true
    self.notificationShowAnimation = TweenSequence.NO_SEQUENCE
    self.notificationsHidePosition = { 2, 0 }
    self.doGPUDriveCheck = Platform.checkGPUDriver and not StartParams.getIsSet("restart")
    self.isDeleted = false
    self.checkForModHubLoaded = true
    return self
end
function MainScreen.createFromExistingGui(gui, guiName)
    local newGui = MainScreen.new()
    g_gui.guis[guiName]:delete()
    g_gui.guis[guiName].target:delete()
    g_gui:loadGui(gui.xmlFilename, guiName, newGui)
    return newGui
end
function MainScreen:onCreate()
    self.lastButtonPressed = nil
    self.isBackAllowed = false
    self:setupButtons()
    self:setupNotifications()
    self:updateTheme()
end
function MainScreen:onClickBack(_, _)
    if GS_PLATFORM_ID ~= PlatformId.ANDROID then
        return MainScreen:superClass().onClickBack(self)
    end
    YesNoDialog.show(self.onYesNoQuitGame, self, g_i18n:getText("ui_youWantToQuitGame"))
    return false
end
function MainScreen.onYesNoQuitGame(_, yes)
    if yes then
        requestExit()
    end
end
function MainScreen:setupButtons()
    local buttonSetup = { self.careerButton }
    if Platform.supportsMultiplayer then
        table.insert(buttonSetup, self.multiplayerButton)
    end
    if Platform.supportsMods then
        table.insert(buttonSetup, self.downloadModsButton)
    end
    table.insert(buttonSetup, self.achievementsButton)
    if Platform.hasNativeStore then
        table.insert(buttonSetup, self.storeButton)
    end
    if not Platform.isMobile then
        table.insert(buttonSetup, self.settingsButton)
    end
    table.insert(buttonSetup, self.creditsButton)
    if Platform.canQuitApplication then
        table.insert(buttonSetup, self.quitButton)
    end
    if Platform.needsSignIn then
        table.insert(buttonSetup, self.changeUserButton)
    end
    if Platform.hasMainScreenLanguageSelection then
        table.insert(buttonSetup, self.changeLanguageButton)
    end
    local previousButton = nil
    for index, button in pairs(buttonSetup) do
        button:setVisible(true)
        if previousButton ~= nil then
            FocusManager:linkElements(button, FocusManager.LEFT, previousButton)
        end
        previousButton = button
    end
    FocusManager:linkElements(previousButton, FocusManager.BOTTOM, buttonSetup[1])
    FocusManager:linkElements(buttonSetup[1], FocusManager.TOP, previousButton)
    self.buttonBox:invalidateLayout()
    buttonSetup[#buttonSetup].focusChangeOverride = nil
    self.activeButtons = buttonSetup
end
function MainScreen:onCreateGameVersion(element)
    element:setText(g_gameVersionDisplay .. g_gameVersionDisplayExtra .. " (" .. getEngineRevision() .. "/" .. g_gameRevision .. ")")
    self.versionElement = element
end
function MainScreen.onHighlight(_, element)
    if not Platform.isConsole then
        FocusManager:setFocus(element)
    end
end
function MainScreen:delete()
    self.isDeleted = true
    g_messageCenter:unsubscribeAll(self)
    MainScreen:superClass().delete(self)
end
function MainScreen:onClose()
    MainScreen:superClass().onClose(self)
    g_inputBinding:removeActionEventsByTarget(self)
    g_messageCenter:unsubscribeAll(self)
    GuiOverlay.deleteOverlay(self.notificationImage.overlay)
    GuiOverlay.deleteOverlay(self.notificationImagePrev.overlay)
    GuiOverlay.deleteOverlay(self.notificationImageNext.overlay)
    if GS_IS_NETFLIX_VERSION then
        hideNetflixButton()
    end
end
function MainScreen:onOpen()
    MainScreen:superClass().onOpen(self)
    setPresenceMode(PresenceModes.PRESENCE_IDLE)
    flushWebCache()
    self:resetNotifications()
    if self.firstTimeOpened then
        self.firstTimeOpened = false
        if isGameFullyInstalled() then
            FocusManager:setFocus(self.careerButton)
        else
            error("Fatal error: the game was not fully installed but the game code expects it to be.")
        end
    end
    startMenuMusic()
    if g_isServerStreamingVersion then
        self.notificationElement:setVisible(false)
        self.notificationElement:setDisabled(true)
    end
    FocusManager:lockFocusInput(InputAction.MENU_ACCEPT, 150)
    self:setSoundSuppressed(true)
    if self.lastActiveButton ~= nil then
        FocusManager:unsetFocus(self.lastActiveButton)
        FocusManager:setFocus(self.lastActiveButton)
    end
    self:setSoundSuppressed(false)
    self:updateTheme()
    g_gameStateManager:setGameState(GameState.MENU_MAIN)
    if self.googlePlayButton ~= nil then
        self.googlePlayButton:setVisible(getPlatformId() == PlatformId.ANDROID and not GS_IS_NETFLIX_VERSION)
        if g_buildTypeParam == "CHINA_GAPP" or g_buildTypeParam == "CHINA" then
            self.googlePlayButton:setIconSize(0, 0)
        end
    end
    self.lastSignedInState = nil
    g_messageCenter:publish(MessageType.GUI_MAIN_SCREEN_OPEN)
    g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)
    if GS_IS_NETFLIX_VERSION then
        showNetflixButton()
        netflixCheckUserAuth()
    end
    if isESRBDiscVersion() and not g_gameSettings:getValue(GameSettings.SETTING.ESRB_UPDATE_SHOWN) then
        self:showESRBUpdateinfo()
    end
    if g_modNameToDirectory[g_uniqueDlcNamePrefix .. "highlandsFishingPack"] == nil then
        self.backgroundImage:setImageFilename("shared/splash.png")
    else
        self.backgroundImage:setImageFilename("shared/splash_highlandsFishing.png")
    end
    self.checkForModHubLoaded = true
end
function MainScreen:setupNotifications()
    local _, rightInset_, _, _ = getSafeFrameInsets()
    self.notificationsHidePosition = { -self.notificationElement.position[1] + self.notificationElement.size[1], self.notificationElement.position[2] }
    local anim = TweenSequence.new(self)
    anim:addInterval(MainScreen.NOTIFICATION_ANIM_DELAY)
    local moveIn = MultiValueTween.new(self.notificationElement.setPosition, self.notificationsHidePosition, { self.notificationElement.position[1] - rightInset_, self.notificationElement.position[2] }, MainScreen.NOTIFICATION_ANIMATION_DURATION)
    anim:addTween(moveIn)
    moveIn:setTarget(self.notificationElement)
    anim:addCallback(self.setNotificationButtonsDisabled, false)
    self.notificationShowAnimation = anim
    self:resetNotifications()
end
function MainScreen:setNotificationButtonsDisabled(isDisabled)
    self.notificationButtonLeft:setVisible(#self.notifications >= 2)
    self.notificationButtonRight:setVisible(#self.notifications >= 2)
    if self.notificationButtonLeft:getIsVisible() then
        for _, button in ipairs(self.activeButtons) do
            FocusManager:linkElements(button, FocusManager.RIGHT, self.notificationButtonLeft)
        end
        FocusManager:linkElements(self.notificationButtonLeft, FocusManager.LEFT, self.activeButtons[1])
        FocusManager:linkElements(self.notificationButtonLeft, FocusManager.TOP, self.activeButtons[1])
        FocusManager:linkElements(self.notificationButtonLeft, FocusManager.BOTTOM, self.activeButtons[#self.activeButtons])
        FocusManager:linkElements(self.notificationButtonRight, FocusManager.TOP, self.activeButtons[1])
        FocusManager:linkElements(self.notificationButtonRight, FocusManager.BOTTOM, self.activeButtons[#self.activeButtons])
    else
        for _, button in ipairs(self.activeButtons) do
            FocusManager:linkElements(button, FocusManager.RIGHT, nil)
            FocusManager:linkElements(button, FocusManager.LEFT, nil)
        end
    end
    self.notificationButtonLeft:setDisabled(isDisabled)
    self.notificationButtonRight:setDisabled(isDisabled)
    self.notificationButtonOpen:setDisabled(isDisabled)
end
function MainScreen:resetNotifications()
    if not self.isDeleted then
        self.notificationsReady = false
        self.notificationsCheckTimer = 0
        self.notifications = {}
        self.activeNotification = 0
        self.notificationShowAnimation:reset()
        self:setNotificationButtonsDisabled(true)
        self.notificationElement:setPosition(unpack(self.notificationsHidePosition))
    end
end
function MainScreen.onYesNoUseGamepadMode(_, yes)
    g_gameSettings:setValue("gamepadEnabledSetByUser", true)
    g_gameSettings:setValue("isGamepadEnabled", yes)
    g_gameSettings:save()
end
function MainScreen.onYesNoUseHeadTracking(_, yes)
    g_gameSettings:setValue("headTrackingEnabledSetByUser", true)
    g_gameSettings:setValue("isHeadTrackingEnabled", yes)
    g_gameSettings:save()
end
function MainScreen:onMultiplayerClick(element)
    self.lastActiveButton = element
    resetMultiplayerChecks()
    self:onMultiplayerClickPerform()
end
function MainScreen:onMultiplayerClickPerform()
    if isGameFullyInstalled() then
        if masterServerConnectFront == nil then
            RestartManager:setStartScreen(RestartManager.START_SCREEN_MULTIPLAYER)
            doRestart(false, "")
            return
        elseif PlatformPrivilegeUtil.checkMultiplayer(self.onMultiplayerClickPerform, self) then
            g_startMissionInfo:reset()
            g_startMissionInfo.isMultiplayer = true
            g_gui:setIsMultiplayer(true)
            g_gui:showGui("MultiplayerScreen")
        end
    else
        showGameInstallProgress()
        return
    end
end
function MainScreen:onCareerClick(element)
    self.lastActiveButton = element
    if isGameFullyInstalled() then
        g_startMissionInfo:reset()
        g_startMissionInfo.isMultiplayer = false
        g_gui:setIsMultiplayer(false)
        self:changeScreen(CareerScreen)
    else
        showGameInstallProgress()
    end
end
function MainScreen:onDownloadModsClick(element)
    self.lastActiveButton = element
    resetMultiplayerChecks()
    self:onDownloadModsClickPerform()
end
function MainScreen:onDownloadModsClickPerform()
    if getNetworkError() then
        ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
        return
    elseif PlatformPrivilegeUtil.checkModDownload(self.onDownloadModsClickPerform, self) then
        modDownloadManagerUpdateSync(true)
        g_gui:showGui("ModHubScreen")
    end
end
function MainScreen:onAchievementsClick(element)
    self.lastActiveButton = element
    if Platform.hasOnlineAchievements and getNetworkError() then
        ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
    else
        g_gui:showGui("AchievementsScreen")
    end
end
function MainScreen:onStoreClick(element)
    self.lastActiveButton = element
    if storeHasNativeGUI() and (getNetworkError() ~= nil or not storeShow("")) then
        InfoDialog.show(g_i18n:getText("ui_dlcStoreNotConnected"), MainScreen.onStoreFailedOk, self)
    end
end
function MainScreen:onStoreFailedOk()
    g_gui:showGui("MainScreen")
end
function MainScreen:onSettingsClick(element)
    self.lastActiveButton = element
    g_gui:showGui("SettingsScreen")
end
function MainScreen:onCreditsClick(element)
    self.lastActiveButton = element
    g_gui:showGui("CreditsScreen")
end
function MainScreen:onChangeUserClick()
    g_gamepadSigninScreen.forceShowSigninGui = true
    g_gui:showGui("GamepadSigninScreen")
end
function MainScreen:onChangeLanguageClick() end
function MainScreen:onChangeMobileSettingsClick(element)
    self.lastActiveButton = element
    g_gui:showGui("MobileSettingsScreen")
end
function MainScreen:onQuitClick()
    doExit()
end
function MainScreen:cycleNotification(signedDelta)
    self.activeNotification = self.activeNotification + signedDelta
    if self.activeNotification > #self.notifications then
        self.activeNotification = 1
    elseif self.activeNotification < 1 then
        self.activeNotification = #self.notifications
    end
    self:assignNotificationData()
end
function MainScreen:onClickNextNotification(_)
    self:cycleNotification(1)
end
function MainScreen:onClickPreviousNotification(_)
    self:cycleNotification(-1)
end
function MainScreen:onClickOpenNotification()
    if #self.notifications > 0 then
        if self.notifications[self.activeNotification].url == "openOptionsGraphics" then
            g_gui:showGui("SettingsScreen")
            g_settingsScreen:showDisplaySettings()
            return
        end
        local url = self.notifications[self.activeNotification].url
        if url ~= MainScreen.NO_STORE_URL and url ~= "" then
            if storeHasNativeGUI() then
                if not storeShow(url) then
                    InfoDialog.show(g_i18n:getText("ui_dlcStoreNotConnected"), MainScreen.onStoreFailedOk, self)
                    return
                end
            else
                openWebFile(self.notifications[self.activeNotification].url, "")
            end
        end
    end
end
function MainScreen:onDlcCorruptClick()
    g_gui:showGui("MainScreen")
end
function MainScreen:updateNotifications(dt)
    if self.notificationsReady and (#self.notifications > 0 and not self.notificationShowAnimation:getFinished()) then
        self.notificationShowAnimation:update(dt)
    end
    if not self.notificationsReady then
        self.notificationsCheckTimer = self.notificationsCheckTimer + dt
        if self.notificationsCheckTimer > MainScreen.NOTIFICATION_CHECK_DELAY then
            self.notificationsCheckTimer = 0
            self.notificationsReady = notificationsLoaded()
            if self.notificationsReady then
                local notificationCount = getNumOfNotifications()
                Logging.devInfo("Loaded %d notification(s)", notificationCount)
                local i = 0
                for i = i, notificationCount - 1 do
                    local title, message, url, image, date, category = getNotification(i)
                    if title == "" or message == "" then
                        Logging.devWarning("Recieved invalid notification \'%d\'.\n    Title: %s\n    Message: %s\n    Url: %s\n    Image: %s\n    Date: %s", i, title, message, url, image, date)
                    else
                        table.insert(self.notifications, {
                            ["title"] = title,
                            ["message"] = message,
                            ["url"] = url,
                            ["image"] = image,
                            ["date"] = date,
                            ["category"] = category
                        })
                    end
                end
                if #self.notifications > 0 then
                    self.activeNotification = 1
                    self.indexState:setPageCount(#self.notifications, self.activeNotification)
                    self:assignNotificationData()
                    self.notificationShowAnimation:start()
                    return
                end
                self.indexState:setPageCount(0)
            end
        end
    end
end
function MainScreen:updateAvailableModUpdates()
    if self.checkForModHubLoaded and modDownloadManagerLoaded() then
        g_modHubController:load()
        local _, numUpdates, _ = g_modHubController:getCategoryData(ModHubController.CATEGORY_ID_UPDATE)
        self.iconHasUpdates:setVisible(numUpdates > 0)
        self.checkForModHubLoaded = false
    end
end
function MainScreen:update(dt)
    MainScreen:superClass().update(self, dt)
    self:updateAvailableModUpdates()
    if self.doGPUDriveCheck then
        self.doGPUDriveCheck = false
        if getIsGPUDriverOutdated() then
            YesNoDialog.show(function(yes)
                if yes then
                    openWebFile(Platform.urlUpdateGPUDriver, "")
                end
            end, nil, g_i18n:getText("warning_gpuDriverOutdated"), nil, nil, nil, DialogElement.TYPE_WARNING)
        end
    end
    modDownloadManagerUpdateSync(false)
    if getPlatformId() == PlatformId.ANDROID then
        local openDriverUpdatePage = getIsUserSignedIn()
        if GS_IS_NETFLIX_VERSION then
            if not openDriverUpdatePage then
                g_gui:showGui("NetflixSigninScreen")
            end
        elseif openDriverUpdatePage ~= self.lastSignedInState then
            if openDriverUpdatePage then
                self.googlePlayButton:setText(getUserName())
                self.achievementsButton:setDisabled(false)
            else
                self.googlePlayButton:setText("")
                self.achievementsButton:setDisabled(true)
            end
        end
        self.lastSignedInState = openDriverUpdatePage
    end
    if self.showGamepadModeDialog and (Platform.showGamepadModeDialog and (not g_gameSettings:getValue(GameSettings.SETTING.GAMEPAD_ENABLED_SET_BY_USER) and getNumOfGamepads() > 0)) then
        YesNoDialog.show(self.onYesNoUseGamepadMode, self, g_i18n:getText("ui_activateGamepads"), g_i18n:getText("ui_activateGamepadsTitle"))
        self.showGamepadModeDialog = false
    end
    if self.showHeadTrackingDialog and (Platform.showHeadTrackingDialog and (not g_gameSettings:getValue(GameSettings.SETTING.HEAD_TRACKING_ENABLED_SET_BY_USER) and isHeadTrackingAvailable())) then
        YesNoDialog.show(self.onYesNoUseHeadTracking, self, g_i18n:getText("ui_activateHeadTracking"), g_i18n:getText("ui_activateHeadTrackingTitle"))
        self.showHeadTrackingDialog = false
    end
    if Platform.showGamerTagInMainScreen then
        self.gamerTagElement:setText(g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME))
    end
    if GS_IS_CONSOLE_VERSION then
        self:updateStoreButtons()
    end
    if self.isFirstOpen == nil then
        if isGameFullyInstalled() then
            FocusManager:setFocus(self.careerButton)
        else
            error("Not fully installed. This state is currently not supported")
        end
        FocusManager:setFocus(FocusManager.currentFocusData.initialFocusElement)
        self.isFirstOpen = true
    end
    if not g_isServerStreamingVersion then
        self:updateNotifications(dt)
    end
    if GS_IS_CONSOLE_VERSION then
        if storeHaveDlcsChanged() or (haveModsChanged() or g_forceNeedsDlcsAndModsReload) then
            g_forceNeedsDlcsAndModsReload = false
            reloadDlcsAndMods()
            self:resetNotifications()
            self:updateTheme()
        end
    elseif haveModsChanged() then
        reloadDlcsAndMods()
    end
    if storeAreDlcsCorrupted() then
        InfoDialog.show(g_i18n:getText("ui_dlcsCorruptRedownload"), self.onDlcCorruptClick, self)
    end
end
function MainScreen:updateStoreButtons()
    if getNetworkError() then
        if self.storeButton:getIsActive() then
            self.storeButton:setDisabled(true)
            return
        end
    elseif not self.storeButton:getIsActive() then
        self.storeButton:setDisabled(false)
    end
end
function MainScreen:assignNotificationData()
    if self.activeNotification > 0 and self.activeNotification <= #self.notifications then
        local prevNotification = self.activeNotification - 1
        local prevNotification = prevNotification == 0 and self.activeNotification ~= #self.notifications and #self.notifications or prevNotification
        local nextNotification = self.notificationElementPrev
        local imageFilePrev = prevNotification > 0
        nextNotification:setVisible(imageFilePrev)
        local nextNotification = self.activeNotification + 1
        local nextNotification = #self.notifications < nextNotification and self.activeNotification ~= 1 and 1 or nextNotification
        local showButton = nextNotification <= #self.notifications
        self.notificationElementNext:setVisible(showButton)
        if GS_IS_CONSOLE_VERSION then
            self.notificationMessage:setText(g_i18n:getText("notification_nowAvailable"))
            if prevNotification > 0 then
                self.notificationMessagePrev:setText(g_i18n:getText("notification_nowAvailable"))
            end
            if nextNotification <= #self.notifications then
                self.notificationMessageNext:setText(g_i18n:getText("notification_nowAvailable"))
            end
        else
            self.notificationMessage:setText(self.notifications[self.activeNotification].message)
            if prevNotification > 0 then
                self.notificationMessagePrev:setText(self.notifications[prevNotification].message)
            end
            if nextNotification <= #self.notifications then
                self.notificationMessageNext:setText(self.notifications[nextNotification].message)
            end
        end
        self.notificationTitle:setText(self.notifications[self.activeNotification].title)
        if prevNotification > 0 then
            self.notificationTitlePrev:setText(self.notifications[prevNotification].title)
        end
        if nextNotification <= #self.notifications then
            self.notificationTitleNext:setText(self.notifications[nextNotification].title)
        end
        self.notificationImage:setImageFilename(self.notifications[self.activeNotification].image == "graphicsOptionsImage" and "dataS/menu/notification_dummy.png" or self.notifications[self.activeNotification].image)
        if prevNotification > 0 then
            self.notificationImagePrev:setImageFilename(self.notifications[prevNotification].image == "graphicsOptionsImage" and "dataS/menu/notification_dummy.png" or self.notifications[prevNotification].image)
        end
        if nextNotification <= #self.notifications then
            self.notificationImageNext:setImageFilename(self.notifications[nextNotification].image == "graphicsOptionsImage" and "dataS/menu/notification_dummy.png" or self.notifications[nextNotification].image)
        end
        if self.notifications[self.activeNotification].url == "openOptionsGraphics" then
            self.notificationButtonOpen:setText(g_i18n:getText("button_settings"))
        else
            if storeHasNativeGUI() then
                self.notificationButtonOpen:setText(g_i18n:getText("button_dlcStore"))
            else
                self.notificationButtonOpen:setText(g_i18n:getText("button_visitWebsite"))
            end
            local imageFilePrev = self.notifications[self.activeNotification].url
            local showButton = false
            if imageFilePrev ~= MainScreen.NO_STORE_URL then
                showButton = imageFilePrev ~= ""
            end
            self.notificationButtonOpen:setVisible(showButton)
        end
        self.indexState:setPageIndex(self.activeNotification)
    end
end
function MainScreen.hasAllDLCs(_, list)
    for _, name in ipairs(list) do
        if GS_IS_EPIC_VERSION then
            if g_modManager:getModByName(g_uniqueDlcNamePrefix .. name) == nil then
                return false
            end
        elseif g_modNameToDirectory[g_uniqueDlcNamePrefix .. name] == nil then
            return false
        end
    end
    return true
end
function MainScreen:updateTheme()
    local filename = Platform.gameLogos[g_languageShort]
    if filename == nil then
        filename = Platform.gameLogos.en
    end
    if self.logo ~= nil then
        self.logo:setImageFilename(filename)
    end
end
function MainScreen:onClickGooglePlayButton()
    if g_buildTypeParam == "CHINA_GAPP" or g_buildTypeParam == "CHINA" then
        userSignout()
        g_gui:showGui("ChinaSigninScreen")
    elseif getIsUserSignedIn() then
        userSignout()
    else
        requestUserSignin()
    end
    g_messageCenter:publish(MessageType.USER_PROFILE_CHANGED)
end
function MainScreen:inputEvent(action, value, eventUsed)
    local text = MainScreen:superClass().inputEvent(self, action, value, eventUsed)
    if Platform.isAndroid and action == InputAction.MENU_BACK then
        YesNoDialog.show(self.onYesNoEnd, self, (g_i18n:getText(InGameMenu.L10N_SYMBOL.END_GAME)))
    end
    return text
end
function MainScreen.onYesNoEnd(_, yes)
    if yes then
        doExit()
    end
end
function MainScreen:updateInsets()
    if self.versionElementPosX == nil then
        self.versionElementPosX = self.versionElement.absPosition[1]
    end
    local leftInset, _, _, _ = getSafeFrameInsets()
    self.versionElement.absPosition[1] = self.versionElementPosX + leftInset
end
function MainScreen:showESRBUpdateinfo()
    g_gameSettings:setValue(GameSettings.SETTING.ESRB_UPDATE_SHOWN, true, true)
    ESRBUpdateDialog.show(g_i18n:getText("ui_ESRBUpdateInfo"), self.onESRBUpdateShown, self)
end