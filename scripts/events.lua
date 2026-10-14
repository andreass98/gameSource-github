function mouseEvent(posX, posY, isDown, isUp, button)
    if g_currentTest == nil then
        Input.updateMouseButtonState(button, isDown)
        g_inputBinding:mouseEvent(posX, posY, isDown, isUp, button)
        if Platform.hasTouchInput then
            if button == Input.MOUSE_BUTTON_WHEEL_UP or button == Input.MOUSE_BUTTON_WHEEL_DOWN then
                if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
                    g_gui:mouseEvent(posX, posY, isDown, isUp, button)
                end
            else
                touchEvent(posX, posY, isDown, isUp, TouchHandler.MOUSE_TOUCH_ID)
            end
        else
            if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
                g_gui:mouseEvent(posX, posY, isDown, isUp, button)
            end
            if g_currentMission ~= nil and g_currentMission.isLoaded then
                g_currentMission:mouseEvent(posX, posY, isDown, isUp, button)
            end
        end
        g_lastMousePosX = posX
        g_lastMousePosY = posY
    else
        g_currentTest.mouseEvent(posX, posY, isDown, isUp, button)
    end
end
function touchEvent(posX, posY, isDown, isUp, touchId)
    if g_touchHandler ~= nil then
        g_touchHandler:onTouchEvent(posX, posY, isDown, isUp, touchId)
        if g_touchHandler.contextName == nil then
            if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
                g_gui:touchEvent(posX, posY, isDown, isUp, touchId)
            end
            if g_inputBinding ~= nil then
                g_inputBinding:touchEvent(posX, posY, isDown, isUp, touchId)
            end
        end
    end
end
function keyEvent(unicode, sym, modifier, isDown)
    if g_currentTest == nil then
        Input.updateKeyState(sym, isDown)
        g_inputBinding:keyEvent(unicode, sym, modifier, isDown)
        if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
            g_gui:keyEvent(unicode, sym, modifier, isDown)
        end
        if g_currentMission ~= nil and g_currentMission.isLoaded then
            g_currentMission:keyEvent(unicode, sym, modifier, isDown)
        end
    else
        g_currentTest.keyEvent(unicode, sym, modifier, isDown)
    end
end
function onUserSignedOut()
    g_isSignedIn = false
    g_gamepadSigninScreen.forceShowSigninGui = true
    forceEndFrameRepeatMode()
    if g_currentMission == nil then
        g_masterServerConnection:disconnectFromMasterServer()
        g_connectionManager:shutdownAll()
        g_gui:showGui("GamepadSigninScreen")
        return
    elseif g_currentMission.isMissionStarted then
        g_currentMission:pauseGame()
        g_masterServerConnection:disconnectFromMasterServer()
        g_gui:showGui("GamepadSigninScreen")
    else
        OnInGameMenuMenu(true)
    end
end
function finishedUserProfileSync()
    SavegameController.NUM_SAVEGAMES = saveGetMaxNumOfSaveGames()
    if GS_PLATFORM_XBOX then
        loadUserSettings(g_gameSettings)
        g_messageCenter:publish(MessageType.USER_PROFILE_CHANGED)
    elseif GS_IS_NETFLIX_VERSION and getLanguage() ~= g_language then
        doRestart(false, "")
    end
end
function onWaitForPendingGameSession()
    if g_currentMission == nil then
        if g_startupScreen == nil then
            g_skipStartupScreen = true
        else
            g_startupScreen:onStartupEnd()
        end
    end
    InfoDialog.show(g_i18n:getText("ui_waitForPendingGameSession"), nil, nil, nil, g_i18n:getText("button_cancel"))
end
function onMultiplayerInviteSent()
    local mission = g_currentMission
    if mission == nil then
        onMultiplayerInviteStartSavegame()
        return true
    end
    if mission.missionDynamicInfo.isMultiplayer then
        return false
    end
    Logging.info("Switching to multiplayer game")
    g_savegameController:saveSavegame(mission.missionInfo)
    g_savegameController.onSaveCompleteCallback = onMultiplayerInviteSaveCompleteCallback
    g_inGameMenu:startSavingGameDisplay()
    g_multiplayerInviteSentData = {
        ["savegameIndex"] = mission.missionInfo.savegameIndex
    }
    return true
end
function onMultiplayerInviteSaveCompleteCallback(_, errorCode)
    function g_savegameController.onSaveCompleteCallback() end
    g_inGameMenu:notifySaveComplete()
    MessageDialog.hide()
    if errorCode == Savegame.ERROR_OK then
        OnInGameMenuMenu()
        onMultiplayerInviteStartSavegame(g_multiplayerInviteSentData.savegameIndex)
        g_multiplayerInviteSentData = nil
    else
        YesNoDialog.show(function(yes)
            if yes then
                onMultiplayerInviteStartSavegame(nil)
            end
        end, nil, g_i18n:getText("ui_savingFailedContinueWithoutSaving"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
    end
end
function onMultiplayerInviteStartSavegame(savegameIndex)
    g_gui:setIsMultiplayer(true)
    g_gui:showGui("CareerScreen")
    if savegameIndex ~= nil then
        g_careerScreen.selectedIndex = savegameIndex
        local savegame = g_savegameController:getSavegame(g_careerScreen.selectedIndex)
        g_careerScreen.currentSavegame = savegame
        g_careerScreen:onStartAction()
        if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
            return
        end
        if g_gui.currentGuiName == "ModSelectionScreen" then
            g_modSelectionScreen:onClickOk()
        end
    end
end
function onRemovedFromInvite()
    if g_currentMission ~= nil then
        Logging.info("You have been uninvited by the host")
        OnInGameMenuMenu()
        InfoDialog.show(g_i18n:getText("ui_uninvited"))
    end
end
local function onOkSigninAccept()
    g_gamepadSigninScreen.forceShowSigninGui = true
    g_gui:showGui("GamepadSigninScreen")
end
function acceptedGameInvite(platformServerId, requestUserName)
    -- upvalues: (copy) onOkSigninAccept
    g_gui:closeDialogByName("InfoDialog")
    resetMultiplayerChecks()
    if g_currentMission ~= nil then
        g_invitePlatformServerId = platformServerId
        g_inviteRequestUserName = requestUserName
        OnInGameMenuMenu()
        if g_pendingRestartData ~= nil then
            return
        end
        g_invitePlatformServerId = nil
        g_inviteRequestUserName = nil
    end
    if Platform.isXbox and (g_gui.currentGuiName == "GamepadSigninScreen" or not g_isSignedIn) then
        g_tempDeepLinkingInfo = {}
        g_tempDeepLinkingInfo.platformServerId = platformServerId
        g_tempDeepLinkingInfo.requestUserName = requestUserName
        return
    elseif Platform.isXbox and (requestUserName ~= "" and g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) ~= requestUserName) then
        g_tempDeepLinkingInfo = {}
        g_tempDeepLinkingInfo.platformServerId = platformServerId
        g_tempDeepLinkingInfo.requestUserName = requestUserName
        InfoDialog.show(string.format(g_i18n:getText("dialog_signinWithUserToAcceptInvite"), requestUserName), onOkSigninAccept)
    elseif Platform.isXbox or Platform.isPlaystation then
        if PlatformPrivilegeUtil.checkMultiplayer(acceptedGameInvitePerformConnect, nil, platformServerId, 30000) then
            acceptedGameInvitePerformConnect(platformServerId)
            return
        end
    else
        acceptedGameInvitePerformConnect(platformServerId)
    end
end
function acceptedGameInvitePerformConnect(platformServerId)
    connectToServer(platformServerId)
end
function acceptedGameCreate()
    if g_currentMission ~= nil then
        OnInGameMenuMenu()
    end
    g_createGameScreen.usePendingInvites = true
    g_gui:setIsMultiplayer(true)
    g_gui:showGui("CareerScreen")
end
function onDeepLinkingFailed()
    g_deepLinkingInfo = nil
    g_showDeeplinkingFailedMessage = true
end
function onFriendListChanged()
    g_masterServerConnection:reconnectToMasterServer()
end
function onBlockedListChanged()
    if g_messageCenter ~= nil then
        g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
    end
end
local hasWindowFocus = true
function notifyWindowGainedFocus()
    -- upvalues: (ref) hasWindowFocus
    if g_messageCenter ~= nil then
        g_messageCenter:publish(MessageType.APP_WINDOW_FOCUS_CHANGED, true)
    end
end
function notifyWindowLostFocus()
    -- upvalues: (ref) hasWindowFocus
    if g_messageCenter ~= nil then
        g_messageCenter:publish(MessageType.APP_WINDOW_FOCUS_CHANGED, false)
    end
end
function getHasWindowFocus()
    -- upvalues: (ref) hasWindowFocus
    return hasWindowFocus
end
function notifyAppSuspended()
    g_appIsSuspended = true
    if g_messageCenter ~= nil then
        g_messageCenter:publish(MessageType.APP_SUSPENDED)
    end
end
function notifyAppResumed()
    g_appIsSuspended = false
    if g_messageCenter ~= nil then
        g_messageCenter:publish(MessageType.APP_RESUMED)
    end
end
function notifyWindowSizeChanged()
    Logging.info("Window size changed. Restarting application")
    g_messageCenter:publish(MessageType.APP_SUSPENDED)
    if g_currentMission == nil then
        RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
        doRestart(false, "")
    else
        OnInGameMenuMenu()
    end
end
function notifyDebugModeChanged(debugMode)
    if g_messageCenter ~= nil then
        g_messageCenter:publish(MessageType.DEBUG_MODE_CHANGED, debugMode)
    end
end