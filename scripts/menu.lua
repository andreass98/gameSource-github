function OnLoadingScreen(missionInfo, missionDynamicInfo, loadingScreen)
    local modName = Utils.getModNameAndBaseDirectory(missionInfo.scriptFilename)
    source(missionInfo.scriptFilename, modName)
    if modName == nil or ClassUtil.getClassModName(missionInfo.scriptClass) == modName then
        local missionClass = ClassUtil.getClassObject(missionInfo.scriptClass)
        if missionClass == nil then
            printError("Error: mission class " .. missionInfo.scriptClass .. " could not be found.")
            OnInGameMenuMenu()
        else
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) missionClass, (copy) missionInfo, (copy) missionDynamicInfo
                if g_server ~= nil or g_client ~= nil then
                    g_currentMission = missionClass.new(missionInfo.baseDirectory, nil)
                    g_currentMission.missionInfo = missionInfo
                    g_currentMission.missionDynamicInfo = missionDynamicInfo
                    g_masterServerConnection:setCallbackTarget(g_currentMission)
                end
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) loadingScreen
                if g_server ~= nil or g_client ~= nil then
                    g_currentMission:initialize()
                    g_currentMission:setLoadingScreen(loadingScreen)
                end
            end)
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) missionInfo, (copy) missionDynamicInfo
                if g_server ~= nil or g_client ~= nil then
                    g_currentMission:setMissionInfo(missionInfo, missionDynamicInfo)
                end
            end, "menu - OnLoadingScreen - setMissionInfo")
            g_asyncTaskManager:addTask(function()
                -- upvalues: (copy) missionDynamicInfo
                if g_server ~= nil or g_client ~= nil then
                    if not g_currentMission.cancelLoading then
                        if missionDynamicInfo.isMultiplayer then
                            if missionDynamicInfo.isClient then
                                g_client:setNetworkListener(g_currentMission)
                                g_client:start(missionDynamicInfo.serverAddress, missionDynamicInfo.serverPort, missionDynamicInfo.relayHeader)
                                g_masterServerConnection:disconnectFromMasterServer()
                            else
                                g_server:setNetworkListener(g_currentMission)
                                g_client:setNetworkListener(g_currentMission)
                            end
                        else
                            g_server:setNetworkListener(g_currentMission)
                            g_client:setNetworkListener(g_currentMission)
                            g_server:startLocal()
                        end
                        if g_server ~= nil then
                            g_server:init()
                        end
                        if not (missionDynamicInfo.isMultiplayer and missionDynamicInfo.isClient) then
                            g_client:startLocal()
                        end
                    end
                end
            end)
        end
    else
        printError("Error: mission class " .. missionInfo.scriptClass .. " does not match expected mod name " .. modName)
        OnInGameMenuMenu()
        return
    end
end
function OnInGameMenuMenu(goToSignIn, wasNetworkError, restartArgs)
    print("quit savegame")
    setTextureStreamingPaused(true)
    saveReadSavegameFinish("", nil)
    startFrameRepeatMode()
    setPresenceMode(PresenceModes.PRESENCE_IDLE)
    if g_isDevelopmentVersion then
        local xzCoordinateMax = (g_currentMission ~= nil and g_currentMission.terrainSize or 2048) * 0.6
        I3DUtil.iterateRecursively(getRootNode(), function(node)
            -- upvalues: (copy) xzCoordinateMax
            if getHasClassId(node, ClassIds.SHAPE) and getRigidBodyType(node) == RigidBodyType.DYNAMIC then
                local x, y, z = getWorldTranslation(node)
                if y < -200 then
                    Logging.warning("Object %q far below map at %d %d %d", I3DUtil.getNodePath(node), x, y, z)
                    return
                end
                if xzCoordinateMax < math.abs(x) or xzCoordinateMax < math.abs(z) then
                    Logging.warning("Object %q far out of bounds at %d %d %d", I3DUtil.getNodePath(node), x, y, z)
                    return
                end
            end
        end)
    end
    if g_currentMission ~= nil then
        g_currentMission.cancelLoading = true
    end
    cancelAllStreamedI3DFiles()
    cancelAllStreamedI3DFiles()
    g_asyncTaskManager:flushAllTasks()
    g_asyncTaskManager:flushAllTasks()
    setStreamLowPriorityI3DFiles(true)
    if g_currentMission ~= nil and (g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer) then
        netSetIsEventProcessingEnabled(true)
    end
    g_masterServerConnection:disconnectFromMasterServer()
    g_masterServerConnection:setCallbackTarget(nil)
    if g_client ~= nil then
        g_client:stop()
    end
    if g_server ~= nil then
        g_server:stop()
    end
    local terrainSize = false
    local xzCoordinateMax = false
    if g_currentMission == nil then
        xzCoordinateMax = true
    else
        terrainSize = true
        if g_currentMission.missionInfo ~= nil then
            terrainSize = g_currentMission.missionInfo:isa(FSCareerMissionInfo)
        end
    end
    if g_currentMission ~= nil then
        g_gui:showGui("")
        g_currentMission:delete()
    end
    g_currentMission = nil
    g_server = nil
    g_client = nil
    g_connectionManager:shutdownAll()
    g_i3DManager:clearEntireSharedI3DFileCache(g_isDevelopmentVersion)
    g_mpLoadingScreen:unloadGameRelatedData()
    g_gameStateManager:setGameState(GameState.MENU_MAIN)
    forceEndFrameRepeatMode()
    if wasNetworkError and GS_PLATFORM_PLAYSTATION then
        ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
    else
        if terrainSize then
            local restartScreen = RestartManager.START_SCREEN_MAIN
            if goToSignIn then
                restartScreen = RestartManager.START_SCREEN_GAMEPAD_SIGNIN
            end
            RestartManager:setStartScreen(restartScreen)
            doRestart(false, restartArgs or "")
            return
        end
        if xzCoordinateMax then
            g_gui:showGui("MainScreen")
        else
            g_gameSettings:save()
            if goToSignIn then
                g_gui:showGui("GamepadSigninScreen")
            else
                g_gui:showGui("MainScreen")
            end
        end
    end
    g_inputBinding:setShowMouseCursor(true)
    simulatePhysics(false)
end