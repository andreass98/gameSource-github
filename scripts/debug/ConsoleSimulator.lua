ConsoleSimulator = {}
ConsoleSimulator.MP_AVAILABILITY = nil
ConsoleSimulator.CROSSPLAY_AVAILABILITY = MultiplayerAvailability and MultiplayerAvailability.AVAILABILITY_UNKNOWN or nil
ConsoleSimulator.NETWORK_ERROR = nil
ConsoleSimulator.ACHIEVEMENTS_AVAILABLE = true
ConsoleSimulator.NEW_DLCS = false
ConsoleSimulator.STORE_DLC_CHANGED = false
ConsoleSimulator.ALLOW_CROSSPLAY = nil
ConsoleSimulator.MOD_AVAILABILITY = MultiplayerAvailability and MultiplayerAvailability.NOT_AVAILABLE or nil
ConsoleSimulator.MAIN_USER_PROFILE = true
ConsoleSimulator.HDR_AVAILABLE = true
function ConsoleSimulator.init()
    local oldKeyEvent = keyEvent
    function keyEvent(unicode, sym, modifier, isDown)
        -- upvalues: (copy) oldKeyEvent
        if isDown then
            if sym == Input.KEY_1 then
                Logging.devInfo("ConsoleSimulator: NETWORK_ERROR - Error")
                ConsoleSimulator.NETWORK_ERROR = "ERROR"
            elseif sym == Input.KEY_2 then
                Logging.devInfo("ConsoleSimulator: NETWORK_ERROR - Nil")
                ConsoleSimulator.NETWORK_ERROR = nil
            elseif sym == Input.KEY_3 then
                Logging.devInfo("ConsoleSimulator: MP_AVAILABILITY - nil")
                ConsoleSimulator.MP_AVAILABILITY = nil
            elseif sym == Input.KEY_4 then
                if MultiplayerAvailability == nil then
                    Logging.devError("Multiplayer not available")
                else
                    Logging.devInfo("ConsoleSimulator: MP_AVAILABILITY - AVAILABILITY_UNKNOWN")
                    ConsoleSimulator.MP_AVAILABILITY = MultiplayerAvailability.AVAILABILITY_UNKNOWN
                end
            elseif sym == Input.KEY_5 then
                if MultiplayerAvailability == nil then
                    Logging.devError("Multiplayer not available")
                else
                    Logging.devInfo("ConsoleSimulator: MP_AVAILABILITY - NOT_AVAILABLE")
                    ConsoleSimulator.MP_AVAILABILITY = MultiplayerAvailability.NOT_AVAILABLE
                end
            elseif sym == Input.KEY_6 then
                if MultiplayerAvailability == nil then
                    Logging.devError("Multiplayer not available")
                else
                    Logging.devInfo("ConsoleSimulator: MP_AVAILABILITY - NO_PRIVILEGES")
                    ConsoleSimulator.MP_AVAILABILITY = MultiplayerAvailability.NO_PRIVILEGES
                end
            elseif sym == Input.KEY_7 then
                Logging.devInfo("ConsoleSimulator: finishedUserProfileSync")
                finishedUserProfileSync()
            elseif sym == Input.KEY_9 then
                Logging.devInfo("ConsoleSimulator: onMasterServerConnectionFailed - conenction lost")
                g_currentMission:onMasterServerConnectionFailed(MasterServerConnection.FAILED_CONNECTION_LOST)
            elseif sym == Input.KEY_0 then
                Logging.devInfo("ConsoleSimulator: NEW_DLCS")
                ConsoleSimulator.NEW_DLCS = true
                ConsoleSimulator.STORE_DLC_CHANGED = true
            elseif sym == Input.KEY_KP_1 then
                ConsoleSimulator.ACHIEVEMENTS_AVAILABLE = not ConsoleSimulator.ACHIEVEMENTS_AVAILABLE
                Logging.devInfo("ConsoleSimulator: ACHIEVEMENTS_AVAILABLE: %s", ConsoleSimulator.ACHIEVEMENTS_AVAILABLE)
            elseif sym == Input.KEY_KP_2 then
                if ConsoleSimulator.ALLOW_CROSSPLAY == nil then
                    ConsoleSimulator.ALLOW_CROSSPLAY = true
                elseif ConsoleSimulator.ALLOW_CROSSPLAY == true then
                    ConsoleSimulator.ALLOW_CROSSPLAY = false
                else
                    ConsoleSimulator.ALLOW_CROSSPLAY = nil
                end
                Logging.devInfo("ConsoleSimulator: ALLOW_CROSSPLAY: %s", ConsoleSimulator.ALLOW_CROSSPLAY)
            elseif sym == Input.KEY_KP_4 then
                if MultiplayerAvailability == nil then
                    Logging.devError("Multiplayer not available")
                else
                    Logging.devInfo("ConsoleSimulator: CROSSPLAY_AVAILABILITY - AVAILABILITY_UNKNOWN")
                    ConsoleSimulator.CROSSPLAY_AVAILABILITY = MultiplayerAvailability.AVAILABILITY_UNKNOWN
                end
            elseif sym == Input.KEY_KP_5 then
                if MultiplayerAvailability == nil then
                    Logging.devError("Multiplayer not available")
                else
                    Logging.devInfo("ConsoleSimulator: CROSSPLAY_AVAILABILITY - NOT_AVAILABLE")
                    ConsoleSimulator.CROSSPLAY_AVAILABILITY = MultiplayerAvailability.NOT_AVAILABLE
                end
            elseif sym == Input.KEY_KP_6 then
                if MultiplayerAvailability == nil then
                    Logging.devError("Multiplayer not available")
                else
                    Logging.devInfo("ConsoleSimulator: CROSSPLAY_AVAILABILITY - NO_PRIVILEGES")
                    ConsoleSimulator.CROSSPLAY_AVAILABILITY = MultiplayerAvailability.NO_PRIVILEGES
                end
            elseif sym == Input.KEY_KP_7 then
                if MultiplayerAvailability == nil then
                    Logging.devError("Multiplayer not available")
                else
                    Logging.devInfo("ConsoleSimulator: CROSSPLAY_AVAILABILITY - NO_PRIVILEGES")
                    ConsoleSimulator.CROSSPLAY_AVAILABILITY = MultiplayerAvailability.AVAILABLE
                end
            elseif sym == Input.KEY_KP_8 then
                Logging.devInfo("ConsoleSimulator: ToggleUser")
                ConsoleSimulator.MAIN_USER_PROFILE = not ConsoleSimulator.MAIN_USER_PROFILE
            elseif sym == Input.KEY_KP_9 then
                Logging.devInfo("ConsoleSimulator: HDR Available")
                ConsoleSimulator.HDR_AVAILABLE = not ConsoleSimulator.HDR_AVAILABLE
            elseif sym == Input.KEY_KP_0 then
                ConsoleSimulator.IS_MODHUB_LOADED = not ConsoleSimulator.IS_MODHUB_LOADED
                Logging.devInfo("ConsoleSimulator: ModHub Loaded - %s", ConsoleSimulator.IS_MODHUB_LOADED)
            end
        end
        oldKeyEvent(unicode, sym, modifier, isDown)
    end
    if getNetworkError ~= nil then
        local oldGetNetworkError = getNetworkError
        function getNetworkError()
            -- upvalues: (copy) oldGetNetworkError
            if ConsoleSimulator.NETWORK_ERROR == nil then
                return oldGetNetworkError()
            else
                return ConsoleSimulator.NETWORK_ERROR
            end
        end
    end
    local oldGetNetworkError = getUserProfileAppPath
    function getUserProfileAppPath()
        -- upvalues: (copy) oldGetNetworkError
        local profilePath = oldGetNetworkError()
        if ConsoleSimulator.MAIN_USER_PROFILE then
            return profilePath
        else
            return string.gsub(profilePath, "FarmingSimulator2025", "FarmingSimulator2025_SecondUser")
        end
    end
    if getMultiplayerAvailability ~= nil then
        local oldGetMultiplayerAvailability = getMultiplayerAvailability
        function getMultiplayerAvailability()
            -- upvalues: (copy) oldGetMultiplayerAvailability
            if ConsoleSimulator.MP_AVAILABILITY == nil then
                return oldGetMultiplayerAvailability()
            else
                return ConsoleSimulator.MP_AVAILABILITY, false
            end
        end
    end
    if getCrossPlayAvailability ~= nil then
        local oldGetMultiplayerAvailability = getCrossPlayAvailability
        function getCrossPlayAvailability(showDialog)
            -- upvalues: (copy) oldGetMultiplayerAvailability
            if ConsoleSimulator.CROSSPLAY_AVAILABILITY == nil then
                return oldGetMultiplayerAvailability(showDialog)
            else
                return ConsoleSimulator.CROSSPLAY_AVAILABILITY, Platform.isXbox and showDialog
            end
        end
    end
    function areAchievementsAvailable()
        return ConsoleSimulator.ACHIEVEMENTS_AVAILABLE
    end
    function modDownloadManagerLoaded()
        return ConsoleSimulator.IS_MODHUB_LOADED
    end
    local oldGetMultiplayerAvailability = startFrameRepeatMode
    function startFrameRepeatMode()
        -- upvalues: (copy) oldGetMultiplayerAvailability
        Logging.devInfo("ConsoleSimulator: startFrameRepeatMode")
        return oldGetMultiplayerAvailability()
    end
    local oldEndFrameRepeatMode = endFrameRepeatMode
    function endFrameRepeatMode()
        -- upvalues: (copy) oldEndFrameRepeatMode
        Logging.devInfo("ConsoleSimulator: endFrameRepeatMode")
        return oldEndFrameRepeatMode()
    end
    local oldForceEndFrameRepeatMode = forceEndFrameRepeatMode
    function forceEndFrameRepeatMode()
        -- upvalues: (copy) oldForceEndFrameRepeatMode
        Logging.devInfo("ConsoleSimulator: forceEndFrameRepeatMode")
        oldForceEndFrameRepeatMode()
    end
    local oldCheckForNewDlcs = checkForNewDlcs
    function checkForNewDlcs()
        -- upvalues: (copy) oldCheckForNewDlcs
        if not ConsoleSimulator.NEW_DLCS then
            return oldCheckForNewDlcs()
        end
        ConsoleSimulator.NEW_DLCS = false
        return true
    end
    local oldStoreHaveDlcsChanged = storeHaveDlcsChanged
    function storeHaveDlcsChanged()
        -- upvalues: (copy) oldStoreHaveDlcsChanged
        if not ConsoleSimulator.STORE_DLC_CHANGED then
            return oldStoreHaveDlcsChanged()
        end
        ConsoleSimulator.STORE_DLC_CHANGED = false
        return true
    end
    function getModDownloadAvailability()
        return ConsoleSimulator.MP_AVAILABILITY or MultiplayerAvailability.AVAILABLE, false
    end
    if openMpFriendInvitation ~= nil then
        local oldOpenMpFriendInvitation = openMpFriendInvitation
        function openMpFriendInvitation(num, capacity)
            -- upvalues: (copy) oldOpenMpFriendInvitation
            Logging.devInfo("ConsoleSimulator: Open friend invitation. Currently online: %d . Capacity: %d", num, capacity)
            oldOpenMpFriendInvitation(num, capacity)
        end
    end
    function getHdrAvailable()
        return ConsoleSimulator.HDR_AVAILABLE
    end
    addConsoleCommand("gsConsoleAcceptInvite", "Console simulator accept invitation", "acceptedGameInvite", ConsoleSimulator)
    printWarning("\n\n  ##################   Warning: Console Simulator active!   ##################\n\n")
end
function ConsoleSimulator.acceptedGameInvite(_, platformServerId, requestUserName)
    acceptedGameInvite(platformServerId or "2", requestUserName or "test -user")
end